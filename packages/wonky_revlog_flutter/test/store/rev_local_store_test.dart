import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show LocalDatabases, SqliteMigrations;
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

  cellRecords();
}

/// Cells grouped per sheet row, found by id for updates and deletes
/// (RevLog spec 17 As built 24).
void cellRecords() {
  late Directory dir;
  late RevLocalStore store;
  final rows = [newId(), newId(), newId()];

  RevOpMeta meta(int revision) => RevOpMeta(
    revision: revision,
    actorKind: 'user',
    label: 'Edit',
    committedAt: clock.now().toUtc(),
  );

  RowChange put(String row, int col, String content) => RowChange.insert(
    'cell',
    cellId(row, col),
    {'sheetId': sheetId, 'rowId': row, 'col': col, 'content': content},
  );

  Future<Map<String, String?>> cells() async => {
    for (final (_, r) in await store.loadRows(docId))
      if (r['rowId'] != null)
        '${rows.indexOf(r['rowId']! as String)}/${r['col']}':
            r['content'] as String?,
  };

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('wonky_revlog_cells_');
    store = await RevLocalStore.open(
      schema: testSchema,
      userUuid: anna,
      app: 'test',
      directory: dir.path,
    );
    await store.touchFile(docId, opened: true);
    await store.applyServerOp(docId, 1, [
      ...creation(rows),
      put(rows[0], 0, 'a'),
      put(rows[0], 1, 'b'),
      put(rows[1], 0, 'c'),
    ], meta(1));
  });

  tearDown(() async {
    await store.close();
    try {
      await dir.delete(recursive: true);
    } catch (_) {}
  });

  group('Given cells of several sheet rows', () {
    test('when cells are updated, inserted and deleted by id, then reads by '
        'row, by id and of everything agree', () async {
      await store.applyServerOp(docId, 2, [
        RowChange.update('cell', cellId(rows[0], 1), {}, {'content': 'B'}),
        put(rows[2], 4, 'new'),
        RowChange.delete('cell', cellId(rows[1], 0), {}),
        RowChange.update('cell', cellId(rows[2], 4), {}, {'content': 'NEW'}),
      ], meta(2));

      expect(await cells(), {'0/0': 'a', '0/1': 'B', '2/4': 'NEW'});
      expect(
        (await store.row(docId, 'cell', cellId(rows[0], 1)))!['content'],
        'B',
      );
      expect(await store.row(docId, 'cell', cellId(rows[1], 0)), isNull);
      final scoped = await store.loadScopedAt(docId, sheetId, [rows[0]]);
      expect(scoped.revision, 2);
      expect([
        for (final (_, r) in scoped.rows) r['col'],
      ], unorderedEquals([0, 1]));
      expect(await store.loadScoped(docId, sheetId, [rows[1]]), isEmpty);
      final structure = await store.loadStructure(docId);
      expect({for (final (t, _) in structure.rows) t}, {'doc', 'sheet', 'row'});
    });

    test('when an update targets a cell that is not stored, then nothing is '
        'written', () async {
      await store.applyServerOp(docId, 2, [
        RowChange.update('cell', cellId(rows[2], 9), {}, {'content': 'x'}),
      ], meta(2));
      expect(await cells(), {'0/0': 'a', '0/1': 'b', '1/0': 'c'});
    });

    test('when two cells share their id hash, then each is found by its own '
        'id', () async {
      // Ids equal in the hashed tail, in different sheet rows.
      const a = '0190f0b0-aaaa-7000-8000-00000000abcd';
      const b = '0190f0b0-bbbb-7000-8000-00000000abcd';
      await store.applyServerOp(docId, 2, [
        RowChange.insert('cell', a, {
          'sheetId': sheetId,
          'rowId': rows[1],
          'col': 7,
          'content': 'A',
        }),
        RowChange.insert('cell', b, {
          'sheetId': sheetId,
          'rowId': rows[2],
          'col': 7,
          'content': 'B',
        }),
      ], meta(2));
      await store.applyServerOp(docId, 3, [
        RowChange.update('cell', b, {}, {'content': 'B2'}),
        RowChange.delete('cell', a, {}),
      ], meta(3));
      expect(await store.row(docId, 'cell', a), isNull);
      expect((await store.row(docId, 'cell', b))!['content'], 'B2');
      expect((await cells())['2/7'], 'B2');
    });

    test(
      'when a page replaces sheet rows, then cells absent from it are '
      'gone everywhere and rows covered at a newer revision are kept',
      () async {
        await store.applyPage(
          docId,
          revision: 5,
          coverage: ['row:$sheetId:${rows[0]}', 'row:$sheetId:${rows[1]}'],
          rows: [
            (
              'cell',
              {...put(rows[0], 2, 'p').columnsAfter, 'id': cellId(rows[0], 2)},
            ),
            (
              'cell',
              {...put(rows[1], 0, 'C').columnsAfter, 'id': cellId(rows[1], 0)},
            ),
          ],
          replay: const [],
        );
        expect(await cells(), {'0/2': 'p', '1/0': 'C'});
        expect(await store.row(docId, 'cell', cellId(rows[0], 0)), isNull);
        // An older page for row 0 is skipped; uncovered rows are merged.
        await store.applyPage(
          docId,
          revision: 4,
          coverage: ['row:$sheetId:${rows[0]}'],
          rows: [
            (
              'cell',
              {
                ...put(rows[0], 0, 'old').columnsAfter,
                'id': cellId(rows[0], 0),
              },
            ),
            (
              'cell',
              {...put(rows[2], 0, 'z').columnsAfter, 'id': cellId(rows[2], 0)},
            ),
          ],
          replay: const [],
        );
        expect(await cells(), {'0/2': 'p', '1/0': 'C', '2/0': 'z'});
        expect((await store.coverage(docId))['row:$sheetId:${rows[0]}'], 5);
      },
    );

    test('when the file is evicted, then its rows are gone and the usage '
        'drops to zero', () async {
      expect(await store.usageBytes(), greaterThan(0));
      await store.evict(docId);
      expect(await store.loadRows(docId), isEmpty);
      expect(await store.usageBytes(), 0);
    });
  });

  group('Given a cache of the first layout (JSON rows)', () {
    test(
      'when opened, then server state is reset and the outbox is kept',
      () async {
        // An outbox row as the store writes it.
        final pending = ChangeSet(
          clientOpId: newId(),
          baseRevision: 7,
          changes: [put(rows[0], 0, 'mine')],
        );
        await store.replaceOutbox(docId, 'tab', [pending]);
        final outboxRow = (await store.db.getAll(
          'SELECT payload, schema_hash FROM rev_outbox',
        )).single;
        // A cache at layout 1: JSON rows, a complete file, that outbox row.
        final old = await Directory.systemTemp.createTemp('wonky_revlog_v1_');
        addTearDown(() async {
          try {
            await old.delete(recursive: true);
          } catch (_) {}
        });
        final db = await LocalDatabases.open(
          RevLocalStore.fileNameFor('test', anna),
          migrations: SqliteMigrations()
            ..add(RevLocalStore.migrations.migrations.first),
          directory: old.path,
        );
        await db.execute(
          "INSERT INTO rev_meta (key, value) VALUES ('schemaHash', ?)",
          [testSchema.hash],
        );
        await db.execute(
          'INSERT INTO rev_local_file (file_uuid, revision, complete) '
          'VALUES (?, 7, 1)',
          [docId],
        );
        await db.execute(
          'INSERT INTO rev_row (file_uuid, tbl, id, data) VALUES (?, ?, ?, ?)',
          [docId, 'doc', docId, '{"title":"Doc"}'],
        );
        await db.execute(
          'INSERT INTO rev_outbox (file_uuid, seq, tab_id, client_op_id, '
          'payload, schema_hash, inflight, created_at) '
          'VALUES (?, 1, ?, ?, ?, ?, 0, 0)',
          [
            docId,
            'tab',
            pending.clientOpId,
            outboxRow['payload'],
            outboxRow['schema_hash'],
          ],
        );
        await db.close();

        final migrated = await RevLocalStore.open(
          schema: testSchema,
          userUuid: anna,
          app: 'test',
          directory: old.path,
        );
        addTearDown(migrated.close);
        final file = (await migrated.loadFile(docId))!;
        expect(file.revision, 0);
        expect(file.complete, isFalse);
        expect(await migrated.loadRows(docId), isEmpty);
        final kept = await migrated.outbox(docId);
        expect([for (final s in kept) s.op.clientOpId], [pending.clientOpId]);
        expect(kept.single.op.changes.single.columnsAfter['content'], 'mine');
      },
    );
  });
}

/// A model with no rows.
final class _Empty implements CurrentRowReader {
  @override
  Map<String, Object?>? currentColumns(String table, String rowId) => null;
}
