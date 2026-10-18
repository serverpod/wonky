import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_revlog/codec.dart' show ChangeSet;
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';

import '../support/harness.dart';

void main() {
  late Directory dir;
  late RevLocalStore store;
  final rows = [newId(), newId()];

  Future<RevLocalStore> open([RevSchema? schema]) => RevLocalStore.open(
    schema: schema ?? testSchema,
    userUuid: anna,
    app: 'test',
    directory: dir.path,
  );

  RevOpMeta meta(int revision, {DateTime? at}) => RevOpMeta(
    revision: revision,
    actorKind: 'user',
    label: 'Edit $revision',
    authorUuid: bo,
    summary: {'n': revision},
    committedAt: at ?? clock.now().toUtc(),
  );

  ChangeSet op(List<RowChange> changes) =>
      ChangeSet(clientOpId: newId(), baseRevision: 1, changes: changes);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('wonky_revlog_store_');
    store = await open();
    await store.touchFile(docId, opened: true);
  });

  tearDown(() async {
    await store.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  group('Given server ops', () {
    test('when applied out of order, then older revisions are ignored and '
        'the rows and op metadata follow the newest', () async {
      expect(
        await store.applyServerOp(docId, 1, creation(rows), meta(1)),
        isTrue,
      );
      final set = setCell(_Empty(), rows[0], 0, 'x');
      expect(await store.applyServerOp(docId, 2, set, meta(2)), isTrue);
      expect(await store.applyServerOp(docId, 2, set, meta(2)), isFalse);
      expect(
        await store.applyServerOp(docId, 1, creation(rows), meta(1)),
        isFalse,
      );

      expect((await store.loadFile(docId))!.revision, 2);
      expect(
        (await store.row(docId, 'cell', cellId(rows[0], 0)))!['content'],
        'x',
      );
      final ops = await store.recentOps(docId, DateTime.utc(2000));
      expect([for (final o in ops) o.revision], [1, 2]);
      expect(ops.last.summary, {'n': 2});
      expect(ops.last.authorUuid, bo);
      expect(await store.loadScoped(docId, sheetId, [rows[0]]), hasLength(1));
    });

    test(
      'when op metadata is older than 30 days, then pruning removes it',
      () async {
        final old = clock.now().toUtc().subtract(const Duration(days: 40));
        await store.applyServerOp(docId, 1, creation(rows), meta(1, at: old));
        await store.applyServerOp(docId, 2, const [], meta(2));
        await store.pruneOps(docId);
        final ops = await store.recentOps(docId, DateTime.utc(2000));
        expect([for (final o in ops) o.revision], [2]);
      },
    );
  });

  group('Given outboxes of two tabs', () {
    test('when one tab adopts the other\'s outbox, then every op is kept in '
        'order under the adopting tab, and an ack removes its op', () async {
      final a = op(creation(rows));
      final b = op(setCell(_Empty(), rows[0], 0, 'b'));
      await store.replaceOutbox(docId, 'tab-a', [a]);
      await store.replaceOutbox(docId, 'tab-b', [b]);
      expect(await store.filesWithOutbox(), [docId]);
      expect(await store.adopt(docId, {'tab-b'}, 'tab-a'), 1);
      final stored = await store.outbox(docId);
      expect([for (final s in stored) s.tabId], ['tab-a', 'tab-a']);
      expect(
        [for (final s in stored) s.op.clientOpId],
        [a.clientOpId, b.clientOpId],
      );

      await store.applyServerOp(
        docId,
        1,
        a.changes,
        meta(1),
        ackedClientOpId: a.clientOpId,
      );
      expect(
        [for (final s in await store.outbox(docId)) s.op.clientOpId],
        [b.clientOpId],
      );
    });
  });

  group('Given an outbox written incrementally', () {
    test('when the oldest op is acked, the newest is composed and an op is '
        'appended, then the stored outbox matches every time', () async {
      final a = op(creation(rows));
      final b = op(setCell(_Empty(), rows[0], 0, 'b'));
      final c = op(setCell(_Empty(), rows[0], 1, 'c'));
      Future<List<String>> ids() async => [
        for (final s in await store.outbox(docId)) s.op.clientOpId,
      ];

      await store.replaceOutbox(docId, 'tab', [a, b]);
      expect(await ids(), [a.clientOpId, b.clientOpId]);
      // Ack of a; b composed with a new change (same id, new object).
      final b2 = ChangeSet(
        clientOpId: b.clientOpId,
        baseRevision: 1,
        changes: [...b.changes, ...setCell(_Empty(), rows[1], 0, 'b2')],
      );
      await store.replaceOutbox(docId, 'tab', [b2]);
      final stored = await store.outbox(docId);
      expect([for (final s in stored) s.op.clientOpId], [b.clientOpId]);
      expect(stored.single.op.changes, hasLength(b2.changes.length));
      await store.replaceOutbox(docId, 'tab', [b2, c]);
      expect(await ids(), [b.clientOpId, c.clientOpId]);
      // Rows removed behind the cache's back (an ack stored with the
      // server op) are not resurrected; the next write rewrites.
      await store.applyServerOp(
        docId,
        1,
        b2.changes,
        meta(1),
        ackedClientOpId: b.clientOpId,
      );
      await store.replaceOutbox(docId, 'tab', [b2, c]);
      expect(await ids(), [b.clientOpId, c.clientOpId]);
      await store.replaceOutbox(docId, 'tab', const []);
      expect(await ids(), isEmpty);
    });
  });

  group('Given a cache of an older schema', () {
    test('when reopened with a new schema, then server state is reloaded and '
        'the outbox survives', () async {
      await store.applyServerOp(docId, 1, creation(rows), meta(1));
      await store.markComplete(docId, complete: true);
      final pending = op(setCell(_Empty(), rows[1], 2, 'mine'));
      await store.replaceOutbox(docId, 'tab', [pending]);
      await store.close();

      final next = RevSchema('test', [
        for (final t in testSchema.tables)
          if (t.name == 'sheet')
            RevTable(
              t.name,
              [
                ...t.columns,
                const RevColumn('color', RevColumnType.string, nullable: true),
              ],
              parents: t.parents,
              rank: t.rank,
            )
          else
            t,
      ]);
      expect(next.hash, isNot(testSchema.hash));
      store = await open(next);
      final file = (await store.loadFile(docId))!;
      expect(file.revision, 0);
      expect(file.complete, isFalse);
      expect(await store.loadRows(docId), isEmpty);
      final stored = await store.outbox(docId);
      expect(stored.single.op.clientOpId, pending.clientOpId);
      expect(stored.single.op.changes.single.columnsAfter['content'], 'mine');
    });
  });

  group('Given a bootstrap page', () {
    test('when applied, then its rows and coverage are stored, and replayed '
        'newer changes win over the page', () async {
      final page = [
        for (final c in creation(rows).where((c) => c.table != 'cell'))
          (c.table, {...c.columnsAfter, RowChange.idColumn: c.rowId}),
      ];
      await store.applyPage(
        docId,
        revision: 3,
        coverage: [
          for (final t in ['doc', 'sheet', 'row']) 'tbl:$t:-:+',
        ],
        rows: page,
        replay: [
          RowChange.update('sheet', sheetId, const {}, {'name': 'Renamed'}),
        ],
      );
      expect(await store.loadRows(docId), hasLength(page.length));
      expect((await store.row(docId, 'sheet', sheetId))!['name'], 'Renamed');
      expect((await store.coverage(docId))['tbl:row:-:+'], 3);
    });
  });
}

/// A model with no rows.
final class _Empty implements CurrentRowReader {
  @override
  Map<String, Object?>? currentColumns(String table, String rowId) => null;
}
