import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

import '../../support/planner_fixture.dart';

void main() {
  final f = PlannerFixture();

  group('Given the fixture deck', () {
    late DeckModel m;
    setUp(() => m = f.session().model);

    test('when reading the order then groups expand in place with ranges and '
        'numbers start at the first slide number', () {
      final order = m.indexes.order;

      expect(order.entries.map((e) => e.id), [f.title, f.s2, f.s3, f.g1, f.g2]);
      expect(order.entries.map((e) => e.number), [1, 2, 3, 4, 5]);
      final range = order.range(f.group)!;
      expect((range.start, range.end), (3, 5));
      expect(order.entry(f.g1)!.groupId, f.group);
      expect(order.topLevel.map((t) => t.id), [f.title, f.s2, f.s3, f.group]);
    });

    test('when a slide is skipped then it has no number and the next slides '
        'are renumbered', () {
      m.applyChanges([
        RowChange.update(
          SlidesTables.slide,
          f.s2,
          {SlidesCols.skipped: false},
          {SlidesCols.skipped: true},
        ),
        RowChange.update(
          SlidesTables.deck,
          testDeckId,
          {DeckCols.firstSlideNumber: 1},
          {DeckCols.firstSlideNumber: 0},
        ),
      ]);

      final order = m.indexes.order;
      expect(order.entries.map((e) => e.number), [0, null, 1, 2, 3]);
      expect(order.presentedIds, [f.title, f.s3, f.g1, f.g2]);
    });

    test('when a group disappears then its slides are orphans at the end', () {
      final g = m.group(f.group)!;
      m.applyChanges([
        RowChange.delete(SlidesTables.slideGroup, g.id, g.toColumns()),
      ]);

      final order = m.indexes.order;
      expect(order.entries.map((e) => e.id).skip(3), [f.g1, f.g2]);
      expect(order.entry(f.g1)!.orphan, isTrue);
      expect(order.entry(f.g1)!.groupId, isNull);
    });

    test('when reading the element tree then children are by group, back to '
        'front, with depth and height', () {
      final tree = m.indexes.tree(f.s3);

      expect(tree.childrenOf(f.grp).map((e) => e.id), [f.child1, f.child2]);
      expect(tree.depthOf(f.child1), 1);
      expect(tree.heightOf(f.grp), 1);
      expect(tree.roots.map((e) => e.id), containsAll([f.shape, f.grp]));
      expect(tree.all.length, tree.length);
    });

    test('when a layout id is missing then the slide falls back to the '
        'blank layout of the default theme', () {
      m.applyChanges([
        RowChange.update(
          SlidesTables.slide,
          f.s2,
          {SlideCols.layoutId: f.layout('titleBody')},
          {SlideCols.layoutId: '00000000-0000-4000-8000-00000000aaaa'},
        ),
      ]);

      final l = m.indexes.themes.effectiveLayout(m.slide(f.s2)!)!;
      expect(l.key, 'blank');
      expect(m.indexes.themes.hasValidLayout(m.slide(f.s2)!), isFalse);
    });

    test('when counting usage then layouts and themes report their slides', () {
      final themes = m.indexes.themes;

      expect(themes.slidesUsingLayout(f.layout('blank')), 2);
      expect(themes.slidesUsingTheme(f.themeId), 5);
      expect(themes.slidesUsingTheme(f.theme2), 0);
    });

    test('when reading the table then cells are by position and the merge '
        'covers its range', () {
      final t = m.indexes.table(f.table);

      expect(t.cellAt(0, 0)!.text, deltaOf('A1'));
      expect(t.mergeAt(2, 2)!.origin.id, t.cellAt(1, 1)!.id);
      expect(t.mergeAt(0, 2), isNull);
    });

    test(
      'when elements change then only the touched owner tree is rebuilt',
      () {
        final s2Tree = m.indexes.tree(f.s2);
        final s3Tree = m.indexes.tree(f.s3);
        final rev2 = m.indexes.revision(f.s2);

        m.applyChanges([
          RowChange.update(
            SlidesTables.slideElement,
            f.shape,
            {ElementCols.x: 100.0},
            {ElementCols.x: 5.0},
          ),
        ]);

        expect(identical(m.indexes.tree(f.s2), s2Tree), isTrue);
        expect(identical(m.indexes.tree(f.s3), s3Tree), isFalse);
        expect(m.indexes.revision(f.s2), rev2);
      },
    );

    test(
      'when builds are listed by element then every build of it is found',
      () {
        expect(m.indexes.buildsOfElement(f.shape).map((b) => b.id), [f.build1]);
      },
    );
  });

  test('Given an element whose parent is another slide\'s group when building '
      'the tree then it is top-level and reported', () {
    final m = f.session().model;
    final image = m.element(f.image)!;
    m.applyChanges([
      RowChange.update(
        SlidesTables.slideElement,
        image.id,
        {SlidesCols.parentId: null},
        {SlidesCols.parentId: f.grp},
      ),
    ]);

    final tree = m.indexes.tree(f.s2);
    expect(tree.foreignParent, {image.id});
    expect(tree.roots.map((e) => e.id), contains(image.id));
  });

  test('Given an operation applied through a session when the indexes were '
      'read before then they reflect the change', () {
    final deck = f.session();
    expect(deck.model.indexes.order.length, 5);

    deck.execute(const AddSlides());

    expect(deck.model.indexes.order.length, 6);
  });
}
