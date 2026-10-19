import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';

import '../support/rows.dart';

int _rank(String table) => const ['deck', 'slide', 'element'].indexOf(table);

void main() {
  group('Given a model with a slide and an element', () {
    late MemoryRows model;
    setUp(
      () => model = MemoryRows({
        'slide': {
          's1': {'id': 's1', 'title': 'A', 'n': 1},
        },
        'element': {
          'e1': {'id': 'e1', 'slideId': 's1', 'x': 1.0},
        },
      }),
    );

    test('when the replica rows equal the model (an echo) then the patch is '
        'empty', () {
      final patch = RowPatch.build(
        model,
        {
          'slide': ['s1'],
        },
        {
          'slide': {
            's1': {'id': 's1', 'title': 'A', 'n': 1.0},
          },
        },
        const [],
        rank: _rank,
      );

      expect(patch, isEmpty);
    });

    test('when a remote change deletes the slide and its element then the '
        'deletes come children first', () {
      final patch = RowPatch.build(
        model,
        {
          'slide': ['s1'],
          'element': ['e1'],
        },
        const {},
        const [],
        rank: _rank,
      );

      expect(patch.map((c) => (c.op, c.table)), [
        (RowOp.delete, 'element'),
        (RowOp.delete, 'slide'),
      ]);
    });

    test('when a local write is still pending then the remote row is '
        'overlaid with it and the optimistic value stays', () {
      model.apply([
        RowChange.update('slide', 's1', {'title': 'A'}, {'title': 'Mine'}),
      ]);
      final pending = [
        RowChange.update('slide', 's1', {'title': 'A'}, {'title': 'Mine'}),
      ];

      final patch = RowPatch.build(
        model,
        {
          'slide': ['s1'],
        },
        {
          'slide': {
            's1': {'id': 's1', 'title': 'A', 'n': 2},
          },
        },
        pending,
        rank: _rank,
      );

      expect(patch.single.columnsAfter, {'id': 's1', 'title': 'Mine', 'n': 2});
    });

    test('when reconciling with the full space then missing rows are deleted '
        'and new ones inserted', () {
      final patch = RowPatch.reconcile(
        model,
        model.allRows().toList(),
        [
          ('slide', {'id': 's1', 'title': 'A', 'n': 1}),
          ('slide', {'id': 's2', 'title': 'B', 'n': 2}),
        ],
        const [],
        rank: _rank,
      );
      model.apply(patch);

      expect(patch.map((c) => (c.op, c.rowId)), [
        (RowOp.delete, 'e1'),
        (RowOp.insert, 's2'),
      ]);
      expect(model.rows['element'], isEmpty);
    });
  });

  test('Given equal values of different types, when compared then numbers '
      'match by value and times to the millisecond', () {
    final t = DateTime.utc(2026, 1, 1, 0, 0, 0, 5, 9);
    expect(
      RowPatch.sameColumns(
        {'n': 1, 'at': t},
        {'n': 1.0, 'at': DateTime.utc(2026, 1, 1, 0, 0, 0, 5)},
      ),
      isTrue,
    );
    expect(RowPatch.sameColumns({'n': 1}, {'n': 2}), isFalse);
  });
}
