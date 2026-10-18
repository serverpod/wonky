import 'package:test/test.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_slides_core/revlog.dart';

/// Current rows for the inverter: table → id → columns.
final class _Rows implements CurrentRowReader {
  _Rows(this.rows);

  final Map<String, Map<String, Map<String, Object?>>> rows;

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) =>
      rows[table]?[rowId];
}

void main() {
  group('Given the Slides schema names', () {
    test('when compared with the RevLog tables then every table and column '
        'matches (the change log is not a table any more)', () {
      expect(
        SlidesTables.dependencyOrder.where(
          (t) => t != SlidesTables.deckChangeLog,
        ),
        slidesSchema.tables.map((t) => t.name).toList(),
      );
      expect(SlidesTables.columns.keys.toSet(), {
        ...SlidesTables.dependencyOrder,
      });
      for (final t in slidesSchema.tables) {
        expect(SlidesTables.columns[t.name], {
          SlidesCols.id,
          for (final c in t.columns) c.name,
        }, reason: t.name);
      }
    });

    test('when ranking tables then parents come first and unknown tables '
        'last', () {
      expect(SlidesTables.rank(SlidesTables.deck), 0);
      expect(
        SlidesTables.rank(SlidesTables.slide),
        lessThan(SlidesTables.rank(SlidesTables.slideElement)),
      );
      expect(SlidesTables.rank('cell'), SlidesTables.dependencyOrder.length);
    });

    test('when reading the undo hooks then every coupled and identity column '
        'exists in its table', () {
      for (final MapEntry(key: table, value: groups)
          in SlidesUndoHooks.coupled.groups.entries) {
        for (final g in groups) {
          expect(
            SlidesTables.columns[table],
            containsAll(g),
            reason: '$table $g',
          );
          expect(g.length, greaterThan(1), reason: '$table $g');
        }
      }
      for (final MapEntry(key: table, value: identity)
          in SlidesUndoHooks.columnwise.tables.entries) {
        expect(SlidesTables.columns[table], containsAll(identity));
      }
    });
  });

  group('Given an undo of slide and element changes with the Slides hooks', () {
    const slide = 's1';
    const element = 'e1';

    test('when someone else moved the slide into another group then the '
        'whole position {groupId, sortKey} is skipped', () {
      final step = [
        RowChange.update(
          SlidesTables.slide,
          slide,
          {SlideCols.groupId: null, SlidesCols.sortKey: 'a0'},
          {SlideCols.groupId: 'g1', SlidesCols.sortKey: 'a1'},
        ),
      ];
      // Another user changed only the key (same group, new position).
      final now = _Rows({
        SlidesTables.slide: {
          slide: {SlideCols.groupId: 'g1', SlidesCols.sortKey: 'a5'},
        },
      });
      final skipped = <String>[];

      final undo = UndoInverter.invertChanges(
        step,
        now,
        coupled: SlidesUndoHooks.coupled,
        skipped: (t, r, c) => skipped.add(c),
      );

      expect(undo, isEmpty);
      expect(skipped, unorderedEquals([SlideCols.groupId, SlidesCols.sortKey]));
    });

    test('when nobody else touched the frame then a resize undoes all four '
        'frame columns, and a concurrent recolor is not part of it', () {
      final step = [
        RowChange.update(
          SlidesTables.slideElement,
          element,
          {'x': 0.0, 'y': 0.0, 'width': 100.0, 'height': 50.0},
          {'x': 10.0, 'y': 10.0, 'width': 200.0, 'height': 80.0},
        ),
      ];
      final now = _Rows({
        SlidesTables.slideElement: {
          element: {
            'x': 10.0,
            'y': 10.0,
            'width': 200.0,
            'height': 80.0,
            'fillJson': '{"v":1,"color":"#ff0000"}',
          },
        },
      });

      final undo = UndoInverter.invertChanges(
        step,
        now,
        coupled: SlidesUndoHooks.coupled,
      );

      expect(undo.single.columnsAfter, {
        'x': 0.0,
        'y': 0.0,
        'width': 100.0,
        'height': 50.0,
      });
    });

    test('when someone else moved the element after an ungroup then the '
        'ungroup (parent and baked frame) is skipped as a unit', () {
      final step = [
        RowChange.update(
          SlidesTables.slideElement,
          element,
          {'parentId': 'grp', 'x': 5.0, 'y': 5.0, 'zKey': 'a0'},
          {'parentId': null, 'x': 105.0, 'y': 205.0, 'zKey': 'b0'},
        ),
      ];
      final now = _Rows({
        SlidesTables.slideElement: {
          element: {'parentId': null, 'x': 300.0, 'y': 205.0, 'zKey': 'b0'},
        },
      });

      final undo = UndoInverter.invertChanges(
        step,
        now,
        coupled: SlidesUndoHooks.coupled,
      );

      expect(undo, isEmpty);
    });

    test('when someone else typed into a table cell this step created then '
        'undo clears only the step\'s own columns (column-wise insert)', () {
      const cell = 'c1';
      final identity = {
        SlidesCols.id: cell,
        SlidesCols.elementId: element,
        TableCellCols.rowId: 'r1',
        TableCellCols.columnId: 'k1',
      };
      final step = [
        RowChange.insert(SlidesTables.slideTableCell, cell, {
          ...identity,
          TableCellCols.fill: '#ffee00',
        }),
      ];
      final now = _Rows({
        SlidesTables.slideTableCell: {
          cell: {
            ...identity,
            TableCellCols.fill: '#ffee00',
            SlidesCols.text: '[{"insert":"Hi\\n"}]',
          },
        },
      });

      final undo = UndoInverter.invertChanges(
        step,
        now,
        columnwise: SlidesUndoHooks.columnwise,
      );

      expect(undo.single.op, RowOp.update);
      expect(undo.single.columnsAfter, {TableCellCols.fill: null});
    });
  });
}
