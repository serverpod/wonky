import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';

import '../support/rows.dart';

void main() {
  group('Given a plan that moved a slide (groupId + sortKey, coupled)', () {
    final move = RowChange.update(
      'slide',
      's1',
      {'groupId': null, 'sortKey': 'a0', 'title': 'Intro'},
      {'groupId': 'g1', 'sortKey': 'b0', 'title': 'Hello'},
    );
    const coupled = TableCoupledColumns({
      'slide': [
        {'groupId', 'sortKey'},
      ],
    });

    test('when nobody changed it then undo restores every column', () {
      final rows = MemoryRows({
        'slide': {
          's1': {
            'id': 's1',
            'groupId': 'g1',
            'sortKey': 'b0',
            'title': 'Hello',
          },
        },
      });

      final undo = UndoInverter.invertChanges([move], rows, coupled: coupled);

      expect(undo.single.columnsAfter, {
        'groupId': null,
        'sortKey': 'a0',
        'title': 'Intro',
      });
    });

    test('when someone else changed the sort key then the whole coupled '
        'group is skipped and the title is still undone', () {
      final rows = MemoryRows({
        'slide': {
          's1': {
            'id': 's1',
            'groupId': 'g1',
            'sortKey': 'c0',
            'title': 'Hello',
          },
        },
      });
      final skipped = <String>[];

      final undo = UndoInverter.invertChanges(
        [move],
        rows,
        coupled: coupled,
        skipped: (_, _, column) => skipped.add(column),
      );

      expect(skipped, unorderedEquals(['groupId', 'sortKey']));
      expect(undo.single.columnsAfter, {'title': 'Intro'});
    });

    test('when the same happens without the coupling rule then only the '
        'changed column is skipped', () {
      final rows = MemoryRows({
        'slide': {
          's1': {
            'id': 's1',
            'groupId': 'g1',
            'sortKey': 'c0',
            'title': 'Hello',
          },
        },
      });

      final undo = UndoInverter.invertChanges([move], rows);

      expect(undo.single.columnsAfter, {'groupId': null, 'title': 'Intro'});
    });

    test(
      'when the slide was deleted meanwhile then every column is skipped',
      () {
        final skipped = <String>[];

        final undo = UndoInverter.invertChanges(
          [move],
          MemoryRows(),
          skipped: (_, _, column) => skipped.add(column),
        );

        expect(undo, isEmpty);
        expect(skipped, ['groupId', 'sortKey', 'title']);
      },
    );
  });

  group('Given a plan that inserted and deleted rows', () {
    final insert = RowChange.insert('element', 'e1', {'x': 1.0, 'y': 2.0});
    final delete = RowChange.delete('element', 'e2', {'x': 5.0, 'y': 6.0});
    final plan = MutationPlan(
      label: 'Paste',
      summary: JsonChangeSummary(),
      changes: [insert, delete],
    );

    test('when undone then the insert is deleted and the deleted row is '
        'revived with its id, in reverse order', () {
      final rows = MemoryRows({
        'element': {'e1': insert.columnsAfter},
      });

      final undo = UndoInverter.invert(plan, rows);

      expect(undo.map((c) => (c.op, c.rowId)), [
        (RowOp.insert, 'e2'),
        (RowOp.delete, 'e1'),
      ]);
      expect(undo.first.columnsAfter, {'x': 5.0, 'y': 6.0, 'id': 'e2'});
    });

    test('when someone revived the deleted row with other values then undo '
        'restores the plan\'s columns as an update', () {
      final rows = MemoryRows({
        'element': {
          'e2': {'id': 'e2', 'x': 9, 'y': 6},
        },
      });

      final undo = UndoInverter.invertChanges([delete], rows);

      expect(undo.single.op, RowOp.update);
      expect(undo.single.columnsAfter, {'x': 5.0});
    });
  });

  group('Given a table whose inserts undo column by column', () {
    const columnwise = TableColumnwiseInserts({
      'cell': {'sheetId', 'rowId', 'columnId'},
    });
    final insert = RowChange.insert('cell', 'c1', {
      'sheetId': 's',
      'rowId': 'r',
      'columnId': 'k',
      'content': 'Anna',
      'bold': true,
    });

    test('when someone changed its content then the content is skipped and '
        'the other inserted columns are cleared', () {
      final rows = MemoryRows({
        'cell': {
          'c1': {...insert.columnsAfter, 'content': 'Bo'},
        },
      });
      final skipped = <String>[];

      final undo = UndoInverter.invertChanges(
        [insert],
        rows,
        columnwise: columnwise,
        skipped: (_, _, column) => skipped.add(column),
      );

      expect(skipped, ['content']);
      expect(undo.single.columnsAfter, {'bold': null});
    });

    test('when nobody changed it then the undo deletes the row', () {
      final rows = MemoryRows({
        'cell': {'c1': insert.columnsAfter},
      });

      final undo = UndoInverter.invertChanges(
        [insert],
        rows,
        columnwise: columnwise,
      );

      expect(undo.single.op, RowOp.delete);
    });
  });
}
