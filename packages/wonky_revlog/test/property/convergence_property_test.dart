@Tags(['property'])
library;

import 'dart:io';
import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/client.dart';
import 'package:wonky_revlog/testing.dart';

import '../support/test_schema.dart';

/// Convergence fuzzer (RevLog spec 09 §2.3, generic schema): 3 replicas with
/// random edits, lossy fan-out, partial delivery, disconnects, offline
/// periods and delayed durability converge to the server state.
void main() {
  final seeds = int.tryParse(Platform.environment['REVLOG_SEEDS'] ?? '') ?? 16;
  for (var s = 0; s < seeds; s++) {
    final seed = 7919 * (s + 1);
    test(
      'Given 3 replicas (seed $seed) when they edit concurrently then all converge',
      () {
        final r = Random(seed);
        final server = FakeRevServer(testSchema, fileUuid: docId);
        final replicas = [
          for (var i = 0; i < 3; i++)
            RevTestReplica(server, 'u$i', random: Random(seed + i)),
        ];
        // Replica 0 creates the file; everyone connects.
        final a = replicas[0];
        a.connect();
        a.pump();
        a.edit(creation(rows: 3), label: 'Create');
        server.processAll();
        a.pump();
        for (final x in replicas.skip(1)) {
          x.connect();
          x.pump();
        }

        for (var step = 0; step < 300; step++) {
          final x = replicas[r.nextInt(replicas.length)];
          switch (r.nextInt(12)) {
            case 0 || 1 || 2 || 3 || 4:
              final changes = randomEdit(r, x.model, x.model.store);
              if (changes.isNotEmpty) x.edit(changes);
            case 5 || 6:
              for (final l in server.links) {
                if (r.nextBool()) {
                  server.processNext(l, random: r, dropRate: 0.1);
                }
              }
            case 7 || 8:
              x.pump(max: 1 + r.nextInt(4));
            case 9:
              if (x.link == null) {
                x.connect();
              } else if (r.nextInt(4) == 0) {
                x.disconnect();
              }
            case 10:
              x.pong();
            case 11:
              x.autoDurable = !x.autoDurable;
              if (x.autoDurable) x.flushDurable();
          }
        }

        // Settle: everyone online, durable, all delivered.
        for (var round = 0; round < 50; round++) {
          for (final x in replicas) {
            if (x.link == null) x.connect();
            x.autoDurable = true;
            x.flushDurable();
          }
          server.processAll();
          for (final x in replicas) {
            x.pump();
            x.pong();
            x.pump();
          }
          if (replicas.every(
            (x) =>
                x.core.isSynchronized && x.core.serverRevision == server.head,
          )) {
            break;
          }
        }
        for (final x in replicas) {
          expect(
            x.core.isSynchronized,
            isTrue,
            reason:
                "${x.userId} outbox: inflight=${x.core.inflight} outbox=${x.core.outbox} rev=${x.core.serverRevision} head=${server.head} link=${x.link != null} connected=${x.core.connected} rejections=${x.rejections} committed=${server.log.any((o) => o.clientOpId == x.core.inflight?.clientOpId)} toServer=${x.link?.toServer.length} toClient=${x.link?.toClient.length} durableDebug=${x.core.debugState}",
          );
          expect(
            x.core.serverRevision,
            server.head,
            reason: '${x.userId} revision',
          );
          expect(
            _rows(x.serverCache.rows),
            _rows(server.state.rows),
            reason: '${x.userId} cache',
          );
          expect(
            _rows(x.model.store.rows),
            _rows(server.state.rows),
            reason: '${x.userId} model',
          );
          expect(x.overlay.shadowSize, 0);
        }
      },
    );
  }
}

Map<String, Map<String, Map<String, Object?>>> _rows(
  Map<String, Map<String, Map<String, Object?>>> rows,
) => {
  for (final t in rows.entries)
    if (t.value.isNotEmpty)
      t.key: {
        for (final r in t.value.entries)
          r.key: {
            for (final c in r.value.entries)
              if (c.key != RowChange.idColumn) c.key: c.value,
          },
      },
};
