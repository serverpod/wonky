import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_slides_core/maintenance.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_sync_models/ids.dart';

/// `MoveElementsZ` and `SetReadingOrder` (03 §8.1, §17.2; SL-34).
void main() {
  late DeckBuilder b;
  late String slide, back, front, grp, c1, c2, rotated, rc;
  late MemoryDeck deck;

  setUp(() {
    b = DeckBuilder();
    slide = b.slide(layoutKey: 'blank');
    back = b.shape(slide, x: 100, y: 100, width: 200, height: 100);
    grp = '00000000-0000-4000-8000-00000000aa01';
    c1 = b.shape(
      slide,
      x: 1000,
      y: 100,
      width: 100,
      height: 100,
      parentId: grp,
    );
    c2 = b.shape(
      slide,
      x: 1200,
      y: 300,
      width: 100,
      height: 100,
      parentId: grp,
    );
    // A group scaled 2× (child space 300 × 300 drawn at 600 × 600).
    b.elementGroup(
      slide,
      groupId: grp,
      x: 1000,
      y: 100,
      width: 300,
      height: 300,
    );
    front = b.shape(slide, x: 400, y: 600, width: 200, height: 100);
    rotated = '00000000-0000-4000-8000-00000000aa02';
    rc = b.shape(slide, x: 0, y: 0, width: 100, height: 100, parentId: rotated);
    b.element(
      slide,
      ElementKind.group,
      id: rotated,
      x: 200,
      y: 800,
      width: 200,
      height: 200,
      rotation: 90,
      columns: {
        ElementCols.dataJson: jsonEncode({
          'v': 1,
          'childBounds': {'x': 0, 'y': 0, 'w': 100, 'h': 100},
        }),
      },
    );
    deck = MemoryDeck(
      model: b.build(),
      userId: b.userId,
      planner: const SlidesPlanner(),
      ids: SequentialIdGenerator(5000),
    );
  });

  ResolvedSlide resolved() => SlideResolver(deck.model).resolve(slide)!;

  ResolvedElement find(String id) {
    ResolvedElement? walk(List<ResolvedElement> l) {
      for (final e in l) {
        if (e.id == id) return e;
        final c = walk(e.children);
        if (c != null) return c;
      }
      return null;
    }

    return walk(resolved().elements)!;
  }

  List<String> topOrder() => [for (final e in resolved().elements) e.id];

  group('Given a slide with shapes and an element group', () {
    test('when a shape moves below another then only its zKey changes', () {
      final plan = deck.execute(MoveElementsZ([front], belowId: back));

      expect(topOrder().take(2), [front, back]);
      expect(plan.label, 'Reorder');
      expect(plan.changes.single.columnsAfter.keys, [ElementCols.zKey]);
    });

    test('when a shape moves into the group then it stays where it is on '
        'the slide, the group grows to hold it and undo restores it', () async {
      final before = find(front).frame;
      final dump = deck.model.dump();

      final plan = deck.execute(MoveElementsZ([front], intoGroupId: grp));

      final f = find(front);
      expect(f.parentId, grp);
      expect(f.frame.x, closeTo(before.x, 1e-6));
      expect(f.frame.y, closeTo(before.y, 1e-6));
      expect(f.frame.width, closeTo(before.width, 1e-6));
      // The children kept their slide positions; the group covers them.
      expect(find(c1).frame.x, closeTo(1000, 1e-6));
      final g = find(grp).frame;
      expect(g.x, lessThanOrEqualTo(before.x + 1e-6));
      expect(g.bottom, greaterThanOrEqualTo(before.bottom - 1e-6));
      expect(plan.label, 'Move to group');
      expect(DeckMaintenance.detect(deck.model), isEmpty);

      final handler = SlidesRowsUndoHandler(() => deck);
      await handler.undo(SlidesRowsUndoEntry(plan.changes, label: plan.label));
      expect(deck.model.dump(), dump);
    });

    test('when a child moves out in front of a shape then its slide frame '
        'is kept', () {
      final before = find(c2).frame;

      deck.execute(MoveElementsZ([c2], aboveId: back));

      final e = find(c2);
      expect(e.parentId, isNull);
      expect(topOrder().indexOf(c2), topOrder().indexOf(back) + 1);
      expect(e.frame.x, closeTo(before.x, 1e-6));
      expect(e.frame.y, closeTo(before.y, 1e-6));
      expect(e.frame.width, closeTo(before.width, 1e-6));
    });

    test('when the last children leave a group then the group is deleted', () {
      deck.execute(MoveElementsZ([c1, c2], aboveId: front));

      expect(deck.model.element(grp), isNull);
      expect(find(c1).parentId, isNull);
      // Relative order is kept.
      expect(topOrder().indexOf(c2), topOrder().indexOf(c1) + 1);
    });

    test('when a child leaves a rotated group then rotation is baked in and '
        'the slide box is kept', () {
      final before = find(rc);

      deck.execute(MoveElementsZ([rc], aboveId: front));

      final after = find(rc);
      expect(after.rotation, closeTo(before.rotation, 1e-6));
      expect(after.frame.x, closeTo(before.frame.x, 1e-6));
      expect(after.frame.y, closeTo(before.frame.y, 1e-6));
    });

    test('when a shape moves into the rotated group then its slide box is '
        'kept (GroupSpace.toChild inverts toParent)', () {
      final before = find(front);

      deck.execute(MoveElementsZ([front], intoGroupId: rotated));

      final after = find(front);
      expect(after.parentId, rotated);
      expect(after.rotation, closeTo(0, 1e-6));
      expect(after.frame.x, closeTo(before.frame.x, 1e-6));
      expect(after.frame.y, closeTo(before.frame.y, 1e-6));
      expect(after.frame.width, closeTo(before.frame.width, 1e-6));
    });

    test('when a group would move into its own child then it is refused', () {
      final nested = deck.execute(MoveElementsZ([back], intoGroupId: grp));
      expect(nested.isEmpty, isFalse);

      expect(
        () => deck.execute(MoveElementsZ([grp], aboveId: back)),
        throwsA(isA<PlanException>()),
      );
      expect(
        () => deck.execute(MoveElementsZ([front], aboveId: front)),
        throwsA(isA<PlanException>()),
      );
    });
  });

  group('Given placeholders', () {
    test('when a placeholder is moved into a group then it is refused', () {
      final s = b.slide(title: 'Hi');
      const g = '00000000-0000-4000-8000-00000000aa03';
      b.shape(s, parentId: g);
      b.elementGroup(s, groupId: g);
      final m = b.build();
      final d = MemoryDeck(
        model: m,
        userId: b.userId,
        planner: const SlidesPlanner(),
      );
      final title = m
          .elementsOf(s)
          .firstWhere((e) => e.placeholderType == SlidePlaceholderType.title);
      expect(
        () => d.execute(MoveElementsZ([title.id], intoGroupId: g)),
        throwsA(
          isA<PlanException>().having(
            (e) => e.message,
            'message',
            contains('Placeholders'),
          ),
        ),
      );
    });
  });

  group('Given a custom reading order', () {
    test('when it is set then the listed elements get ascending keys and a '
        'reset clears them in one step', () {
      deck.execute(SetReadingOrder(slide, [front, back]));

      final kf = deck.model.element(front)!.readingKey!;
      final kb = deck.model.element(back)!.readingKey!;
      expect(kf.compareTo(kb), lessThan(0));
      expect(deck.model.element(grp)!.readingKey, isNull);

      final reset = deck.execute(SetReadingOrder(slide, const []));
      expect(reset.changes, hasLength(2));
      expect(deck.model.element(front)!.readingKey, isNull);
    });

    test('when the owner is unknown then it is refused', () {
      final other = b.slide(layoutKey: 'blank');
      expect(
        () => deck.execute(SetReadingOrder(other, [front])),
        throwsA(isA<PlanException>()),
      );
    });
  });
}
