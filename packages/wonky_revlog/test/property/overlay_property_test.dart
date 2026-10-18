@Tags(['property'])
library;

import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/testing.dart';

import '../support/test_schema.dart';

/// Overlay (RevLog spec 09 §2.6): for a random server state, outbox and
/// remote op, the model patched by `RevOverlay.remote` equals a rebuild from
/// the new server state plus the outbox; a remote op the model already
/// reflects patches nothing.
void main() {
  for (var seed = 0; seed < 40; seed++) {
    test(
      'Given a random outbox (seed $seed) when a remote op arrives then the patched model equals server state plus outbox',
      () {
        final r = Random(seed);
        final server = MapRowStore();
        applyChanges(testSchema, server, creation(rows: 4));
        // Some shared history.
        for (var i = 0; i < 10; i++) {
          applyChanges(
            testSchema,
            server,
            randomEdit(r, MapModel(server), server),
          );
        }
        final model = MapModel(server.copy());
        final overlay = RevOverlay(testSchema);

        // Local edits (the outbox), applied to the model as the client does.
        final outbox = <ChangeSet>[];
        for (var i = 0, n = r.nextInt(4); i < n; i++) {
          final changes = randomEdit(r, model, model.store);
          if (changes.isEmpty) continue;
          overlay.captureLocal(changes, model);
          model.apply(_applied(model.store, changes));
          outbox.add(
            ChangeSet(clientOpId: newId(), baseRevision: 0, changes: changes),
          );
        }

        // Another client's op, sequenced by the server.
        final remoteEdit = randomEdit(r, MapModel(server), server);
        final result = applyChanges(testSchema, server, remoteEdit);
        final applied = [
          for (final c in result.applied)
            c.op == RowOp.update
                ? RowChange.update(c.table, c.rowId, const {}, c.columnsAfter)
                : c,
        ];

        model.apply(overlay.remote(applied, outbox, model));

        final expected = server.copy();
        for (final op in outbox) {
          applyChanges(testSchema, expected, op.changes, cascade: false);
        }
        expect(_rows(model.store), _rows(expected), reason: 'seed $seed');

        // Echo: with an empty outbox, a re-delivered op patches nothing.
        if (outbox.isEmpty) {
          expect(overlay.remote(applied, const [], model), isEmpty);
        }
      },
    );
  }
}

/// The model-level effect of [changes] on [store] (full rows for inserts,
/// rows missing on the store dropped), like the client's apply.
List<RowChange> _applied(MapRowStore store, List<RowChange> changes) {
  final copy = store.copy();
  return applyChanges(testSchema, copy, changes, cascade: false).applied;
}

/// Rows without empty tables, for comparison.
Map<String, Map<String, Map<String, Object?>>> _rows(MapRowStore s) => {
  for (final e in s.rows.entries)
    if (e.value.isNotEmpty) e.key: e.value,
};
