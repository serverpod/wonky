import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

void main() {
  group('Given a plan builder over a deck with a shape', () {
    late DeckModel model;
    late String shape;
    late PlanBuilder b;

    setUp(() {
      final d = DeckBuilder();
      final s = d.slide(layoutKey: 'blank');
      shape = d.shape(s, x: 10, y: 20);
      model = d.build();
      b = PlanBuilder(model);
    });

    test('when updating a row twice then one update names the changed '
        'columns with the first before and the last after', () {
      b.update(SlidesTables.slideElement, shape, {ElementCols.x: 30.0});
      b.update(SlidesTables.slideElement, shape, {
        ElementCols.x: 40.0,
        ElementCols.y: 20.0,
      });

      final c = b.build().single;
      expect(c.op, RowOp.update);
      expect(c.columnsBefore, {ElementCols.x: 10.0});
      expect(c.columnsAfter, {ElementCols.x: 40.0});
    });

    test('when a forced column is unchanged then it is still written with '
        'the changed one (02 P4)', () {
      b.update(
        SlidesTables.slideElement,
        shape,
        {ElementCols.x: 30.0, ElementCols.y: 20.0},
        together: const {ElementCols.x, ElementCols.y},
      );

      expect(b.build().single.columnsAfter, {
        ElementCols.x: 30.0,
        ElementCols.y: 20.0,
      });
    });

    test('when an update is reverted in the same plan then nothing is '
        'written', () {
      b.update(SlidesTables.slideElement, shape, {ElementCols.x: 30.0});
      b.update(SlidesTables.slideElement, shape, {ElementCols.x: 10.0});

      expect(b.build(), isEmpty);
    });

    test('when inserting then updating a row then one insert holds the final '
        'columns, and an insert then delete is nothing', () {
      b.insert(SlidesTables.slideGroup, {
        SlidesCols.id: 'g1',
        SlidesCols.title: 'A',
      });
      b.update(SlidesTables.slideGroup, 'g1', {SlidesCols.title: 'B'});
      b.insert(SlidesTables.slideGroup, {
        SlidesCols.id: 'g2',
        SlidesCols.title: 'C',
      });
      b.delete(SlidesTables.slideGroup, 'g2');

      final c = b.build().single;
      expect(c.op, RowOp.insert);
      expect(c.columnsAfter[SlidesCols.title], 'B');
      expect(
        c.columnsAfter.keys,
        containsAll(SlidesTables.columns[SlidesTables.slideGroup]!),
      );
    });

    test('when deleting then the full row is the before image and the plan '
        'view no longer has it', () {
      b.delete(SlidesTables.slideElement, shape);

      expect(b.exists(SlidesTables.slideElement, shape), isFalse);
      expect(
        b.build().single.columnsBefore,
        model.currentColumns(SlidesTables.slideElement, shape),
      );
      expect(
        b.records(SlidesTables.slideElement).map((r) => r.id),
        isNot(contains(shape)),
      );
    });
  });

  group('Given key spaces with duplicate and malformed keys', () {
    test('when inserting between two equal keys then the new key lands after '
        'them and before the next distinct key', () {
      final items = OrderKeys.sorted([('a1', 'x'), ('a1', 'y'), ('a2', 'z')]);

      final k = OrderKeys.at(items, 1, 1).single;

      expect(k.compareTo('a1'), greaterThan(0));
      expect(k.compareTo('a2'), lessThan(0));
    });

    test(
      'when the bounds are not ascending then the upper bound is dropped',
      () {
        final keys = OrderKeys.between('a3', 'a1', 2);

        expect(keys, hasLength(2));
        expect(keys.first.compareTo('a3'), greaterThan(0));
        expect(keys.first.compareTo(keys.last), lessThan(0));
      },
    );

    test('when excluded items are skipped then keys go between the remaining '
        'neighbours', () {
      final items = OrderKeys.sorted([
        ('a0', 'p'),
        ('a1', 'moving'),
        ('a2', 'q'),
      ]);

      final k = OrderKeys.at(items, 2, 1, exclude: {'moving'}).single;

      expect(k.compareTo('a0'), greaterThan(0));
      expect(k.compareTo('a2'), lessThan(0));
    });
  });
}
