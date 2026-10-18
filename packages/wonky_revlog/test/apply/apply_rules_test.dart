import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../support/test_schema.dart';

void main() {
  late MapRowStore store;
  late List<String> rows;

  ChangeSet op(List<RowChange> changes) =>
      ChangeSet(clientOpId: newId(), baseRevision: 0, changes: changes);

  setUp(() {
    store = MapRowStore();
    rows = [newId(), newId()];
    applyChanges(testSchema, store, creation(rowIds: rows));
  });

  group('Given a doc with two rows', () {
    test(
      'when a cell is inserted under an existing row then it is stored with defaults',
      () {
        final id = cellId(sheetId, rows[0], 0);
        final r = applyChangeSet(
          testSchema,
          store,
          op([
            RowChange.insert('cell', id, {
              'sheetId': sheetId,
              'rowId': rows[0],
              'col': 0,
              'content': 'a',
            }),
          ]),
        );
        expect(r.dropped, isEmpty);
        expect(store.row('cell', id)!['content'], 'a');
        expect(store.row('cell', id)!.containsKey('bold'), isTrue);
        expect(r.equalsSubmitted, isFalse, reason: 'defaults were filled in');
      },
    );

    test(
      'when a cell is inserted under a deleted row then it is dropped as parentMissing',
      () {
        applyChanges(testSchema, store, [
          RowChange.delete('row', rows[1], store.row('row', rows[1])!),
        ]);
        final r = applyChangeSet(
          testSchema,
          store,
          op([
            RowChange.insert('cell', cellId(sheetId, rows[1], 0), {
              'sheetId': sheetId,
              'rowId': rows[1],
              'col': 0,
              'content': 'x',
              'bold': null,
              'at': null,
            }),
          ]),
        );
        expect(r.dropped.single.reason, DropReason.parentMissing);
        expect(r.applied, isEmpty);
      },
    );

    test('when a missing row is updated then it is dropped as rowMissing', () {
      final r = applyChangeSet(
        testSchema,
        store,
        op([
          RowChange.update('row', newId(), {'height': null}, {'height': 3.0}),
        ]),
      );
      expect(r.dropped.single.reason, DropReason.rowMissing);
    });

    test(
      'when two inserts of the same cell meet then the second merges its non-null columns as an update',
      () {
        final id = cellId(sheetId, rows[0], 1);
        applyChanges(testSchema, store, [
          RowChange.insert('cell', id, {
            'sheetId': sheetId,
            'rowId': rows[0],
            'col': 1,
            'content': 'v',
            'bold': null,
            'at': null,
          }),
        ]);
        final r = applyChangeSet(
          testSchema,
          store,
          op([
            RowChange.insert('cell', id, {
              'sheetId': sheetId,
              'rowId': rows[0],
              'col': 1,
              'content': null,
              'bold': true,
              'at': null,
            }),
          ]),
        );
        expect(store.row('cell', id)!['content'], 'v');
        expect(store.row('cell', id)!['bold'], true);
        expect(r.applied.single.op, RowOp.update);
        expect(r.applied.single.columnsAfter, {'bold': true});
        expect(r.applied.single.columnsBefore, {'bold': null});
        expect(r.equalsSubmitted, isFalse);
      },
    );

    test(
      'when an update meets a newer value then it is written and reported as a candidate',
      () {
        final r = applyChangeSet(
          testSchema,
          store,
          op([
            RowChange.update(
              'sheet',
              sheetId,
              {'name': 'Old'},
              {'name': 'New'},
            ),
          ]),
        );
        expect(store.row('sheet', sheetId)!['name'], 'New');
        expect(r.candidates.single.theirs, 'Sheet1');
        expect(r.equalsSubmitted, isTrue);
      },
    );

    test(
      'when a row with an unlisted cell is deleted then the cell is cascaded and reported',
      () {
        final id = cellId(sheetId, rows[0], 2);
        applyChanges(testSchema, store, [
          RowChange.insert('cell', id, {
            'sheetId': sheetId,
            'rowId': rows[0],
            'col': 2,
            'content': 'c',
            'bold': null,
            'at': null,
          }),
        ]);
        final r = applyChangeSet(
          testSchema,
          store,
          op([RowChange.delete('row', rows[0], store.row('row', rows[0])!)]),
        );
        expect(store.row('cell', id), isNull);
        expect(r.cascaded.single.rowId, id);
        expect(r.applied.map((c) => c.rowId), [id, rows[0]]);
      },
    );

    test('when replaying an applied form then the state is reproduced', () {
      final copy = store.copy();
      final r = applyChangeSet(
        testSchema,
        store,
        op([
          RowChange.insert('cell', cellId(sheetId, rows[0], 3), {
            'sheetId': sheetId,
            'rowId': rows[0],
            'col': 3,
            'content': 'z',
            'bold': null,
            'at': null,
          }),
          RowChange.update('sheet', sheetId, {'name': 'Sheet1'}, {'name': 'X'}),
          RowChange.delete('row', rows[1], store.row('row', rows[1])!),
        ]),
      );
      replayApplied(copy, r.applied);
      expect(copy.rows, store.rows);
    });
  });

  group('Given validation', () {
    test('when a client writes an immutable column then it is rejected', () {
      final id = cellId(sheetId, rows[0], 0);
      expect(
        () => validateChangeSet(
          testSchema,
          op([
            RowChange.update(
              'cell',
              id,
              {'rowId': rows[0]},
              {'rowId': rows[1]},
            ),
          ]),
          fromClient: true,
          isCreation: false,
          fileUuid: docId,
        ),
        throwsA(
          isA<RevRejection>().having(
            (e) => e.reason,
            'reason',
            RevRejectReason.invalidChange,
          ),
        ),
      );
    });

    test(
      'when the root row is inserted outside the creation op then it is rejected',
      () {
        expect(
          () => validateChangeSet(
            testSchema,
            op([
              RowChange.insert('doc', docId, {'title': 'x'}),
            ]),
            fromClient: true,
            isCreation: false,
            fileUuid: docId,
          ),
          throwsA(isA<RevRejection>()),
        );
      },
    );

    test('when a client claims the system actor then it is rejected', () {
      final cs = ChangeSet(
        clientOpId: newId(),
        baseRevision: 0,
        actorKind: 'system',
        changes: [
          RowChange.update('sheet', sheetId, {'name': 'a'}, {'name': 'b'}),
        ],
      );
      expect(
        () => validateChangeSet(
          testSchema,
          cs,
          fromClient: true,
          isCreation: false,
          fileUuid: docId,
        ),
        throwsA(isA<RevRejection>()),
      );
    });

    test(
      'when a JSON column is not JSON or an enum is unknown then it is rejected',
      () {
        expect(
          () => validateChangeSet(
            testSchema,
            op([
              RowChange.insert('rule', newId(), {
                'sheetId': sheetId,
                'ruleJson': '{',
                'kind': 'a',
              }),
            ]),
            fromClient: true,
            isCreation: false,
            fileUuid: docId,
          ),
          throwsA(isA<RevRejection>()),
        );
        expect(
          () => validateChangeSet(
            testSchema,
            op([
              RowChange.insert('rule', newId(), {
                'sheetId': sheetId,
                'ruleJson': '{}',
                'kind': 'zz',
              }),
            ]),
            fromClient: true,
            isCreation: false,
            fileUuid: docId,
          ),
          throwsA(isA<RevRejection>()),
        );
      },
    );
  });
}
