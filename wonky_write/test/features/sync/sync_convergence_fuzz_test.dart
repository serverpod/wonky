@Tags(['property'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_write/features/sync/document_sync_controller.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'support/fake_document_server.dart';

class _Replica {
  _Replica(FakeDocumentServer server, int userId, Random random)
    : transport = server.transport(userId: userId),
      keeper = SimpleConnectionKeeper(minDelay: Duration.zero, random: random),
      host = DeltaHost() {
    sync = DocumentSyncController(
      transport: transport,
      host: host,
      keeper: keeper,
      pingEvery: Duration.zero,
      gapRetry: Duration.zero,
    );
  }

  final FakeTransport transport;
  final SimpleConnectionKeeper keeper;
  final DeltaHost host;
  late final DocumentSyncController sync;

  Future<void> dispose() async {
    await sync.dispose();
    keeper.dispose();
  }
}

/// Convergence fuzzer (Write 03 §8): 2–3 replicas make random edits
/// (text, formats, block attributes, comment anchors, suggestions) while the
/// fake server delivers broadcasts in random order, drops some of them
/// (gap fills) and replicas go offline and come back (reconnect +
/// idempotent resubmit). In the end every replica equals the server.
void main() {
  for (final seed in List.generate(12, (i) => 7919 * (i + 1))) {
    test(
      'Given seed $seed when replicas edit concurrently then they converge',
      () async {
        final random = Random(seed);
        final server = FakeDocumentServer(
          initial: DeltaGen(
            Random(seed + 1),
            options: const DeltaGenOptions(maxLines: 5, tables: false),
          ).document(),
          autoDeliver: false,
        );
        final edits = EditGen(Random(seed + 2));
        final replicas = [
          for (var i = 0; i < 2 + random.nextInt(2); i++)
            _Replica(server, i + 1, random),
        ];
        for (final r in replicas) {
          r.sync.start();
        }
        server.deliverAll();
        await pumpEventQueue();

        for (var step = 0; step < 300; step++) {
          final r = replicas[random.nextInt(replicas.length)];
          switch (random.nextInt(12)) {
            case 0 || 1 || 2 || 3:
              if (!r.sync.isLoaded) break;
              final change = _randomChange(random, edits, r);
              if (change != null) r.host.edit(r.sync, change);
            case 4 || 5 || 6 || 7 || 8:
              for (var i = random.nextInt(4); i >= 0; i--) {
                server.deliverRandom(random, dropRate: 0.05);
              }
            case 9:
              final sel = random.nextInt(DeltaUtils.documentLength(r.host.doc));
              r.sync.sendCursor(sel, sel);
            case 10:
              if (random.nextBool()) r.keeper.online = !r.keeper.online;
            default:
              break;
          }
          await pumpEventQueue(times: 2);
          _expectInvariants(server, replicas, 'step $step');
        }

        // Heal the network and let everything settle.
        for (final r in replicas) {
          r.keeper.online = true;
        }
        for (var round = 0; round < 200; round++) {
          server.deliverAll();
          await pumpEventQueue();
          _expectInvariants(server, replicas, 'round $round');
          final settled =
              !server.hasPending &&
              replicas.every(
                (r) =>
                    r.sync.isConnected &&
                    !r.sync.hasPendingChanges &&
                    r.sync.revision == server.revision,
              );
          if (settled) break;
        }

        for (final r in replicas) {
          expect(
            r.sync.revision,
            server.revision,
            reason: 'revision of ${r.transport.userId}',
          );
          expect(
            DeltaUtils.canonical(r.host.doc),
            server.document,
            reason: 'replica ${r.transport.userId}',
          );
          expect(r.sync.serverDocument, server.document);
        }
        expect(
          const WonkyDeltaValidator().validate(server.document).isValid,
          isTrue,
        );
        for (final r in replicas) {
          await r.dispose();
        }
      },
    );
  }
}

/// Every replica's document equals its view of the server document plus
/// its pending changes, and that view equals the server's document at the
/// replica's revision.
void _expectInvariants(
  FakeDocumentServer server,
  List<_Replica> replicas,
  String when,
) {
  for (final x in replicas) {
    if (!x.sync.isLoaded) continue;
    final p = x.sync.pendingDelta;
    final local = p == null
        ? x.sync.serverDocument
        : x.sync.serverDocument.compose(p);
    expect(
      canonicalJson(x.host.doc),
      canonicalJson(local),
      reason: 'local document of replica ${x.transport.userId} at $when',
    );
    expect(
      canonicalJson(x.sync.serverDocument),
      canonicalJson(server.contentAt(x.sync.revision)),
      reason: 'server view of replica ${x.transport.userId} at $when',
    );
  }
}

/// A random local change: mostly generic edits, sometimes a comment anchor
/// or an insertion suggestion (stamped by the server).
Delta? _randomChange(Random random, EditGen edits, _Replica r) {
  final doc = r.host.doc;
  final len = DeltaUtils.documentLength(doc);
  switch (random.nextInt(6)) {
    case 0:
      if (len < 2) return null;
      final start = random.nextInt(len - 1);
      final n = 1 + random.nextInt(min(5, len - 1 - start));
      return CommentAnchors.addAnchor('t${random.nextInt(3)}', start, n);
    case 1:
      final at = random.nextInt(len);
      return Delta()
        ..retain(at)
        ..insert('s', {
          'sug_x${random.nextInt(1000)}': {
            't': 'ins',
            'by': r.transport.userUuid,
            'at': 1,
          },
        });
    default:
      final c = edits.change(doc);
      return DeltaUtils.isNoop(c) ? null : c;
  }
}
