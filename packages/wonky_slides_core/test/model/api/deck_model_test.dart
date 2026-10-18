import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_revlog/rows.dart';

void main() {
  group('Given a deck with ungrouped slides and a group', () {
    late DeckBuilder b;
    late String s1, g, s2, s3, s4;
    late DeckModel model;

    setUp(() {
      b = DeckBuilder();
      s1 = b.slide(layoutKey: 'title', title: 'Hello');
      g = b.group('Intro');
      s2 = b.slide(groupId: g);
      s3 = b.slide(groupId: g);
      s4 = b.slide();
      model = b.build();
    });

    test('when reading the slides then they are flattened in presentation '
        'order', () {
      expect(model.slides.map((s) => s.id), [s1, s2, s3, s4]);
      expect(model.slidesInGroup(g).map((s) => s.id), [s2, s3]);
      expect(model.groups.single.title, 'Intro');
    });

    test('when the group row is gone then its slides come last as '
        'orphans', () {
      model.applyChanges([
        RowChange.delete(
          SlidesTables.slideGroup,
          g,
          model.group(g)!.toColumns(),
        ),
      ]);

      expect(model.slides.map((s) => s.id), [s1, s4, s2, s3]);
    });

    test('when reading a slide then its placeholder instances are its '
        'elements', () {
      final title = model.elementsOf(s1);

      expect(title, isNotEmpty);
      expect(title.every((e) => e.placeholderOf != null), isTrue);
      expect(model.defaultTheme?.id, b.themeIds.themeId);
      expect(model.layoutsOf(b.themeIds.masterId), hasLength(16));
    });

    test('when reading current columns then the full row is returned', () {
      final cols = model.currentColumns(SlidesTables.slide, s2)!;

      expect(cols.keys.toSet(), SlidesTables.columns[SlidesTables.slide]);
      expect(cols[SlideCols.groupId], g);
      expect(model.currentColumns(SlidesTables.slide, 'missing'), isNull);
    });
  });

  group('Given a slide with elements and a group element', () {
    late DeckBuilder b;
    late String slide, back, front, grp, child;
    late DeckModel model;

    setUp(() {
      b = DeckBuilder();
      slide = b.slide(layoutKey: 'blank');
      back = b.shape(slide);
      front = b.shape(slide, x: 300);
      grp = '00000000-0000-4000-8000-00000000ffff';
      child = b.shape(slide, parentId: grp);
      b.elementGroup(slide, groupId: grp);
      model = b.build();
    });

    test('when listing elements then siblings are back to front per '
        'parent', () {
      expect(model.elementsOf(slide).map((e) => e.id), [back, front, grp]);
      expect(model.elementsOf(slide, parentId: grp).map((e) => e.id), [child]);
      expect(model.allElementsOf(slide), hasLength(4));
    });

    test('when an element moves then one batch reports the element and its '
        'slide', () {
      final batches = <DeckChangeBatch>[];
      model.changes.listen(batches.add);

      model.applyChanges([
        RowChange.update(
          SlidesTables.slideElement,
          front,
          {'x': 300.0, 'y': 100.0},
          {'x': 320.0, 'y': 110.0},
        ),
      ]);

      expect(batches, hasLength(1));
      final e = batches.single.event<ElementsChanged>()!;
      expect(e.elementIds, {front});
      expect(e.slideIds, {slide});
      expect(batches.single.origin, DeckChangeOrigin.local);
      expect(model.element(front)!.x, 320.0);
    });

    test('when a change writes the current values then no event is '
        'emitted', () {
      final batches = <DeckChangeBatch>[];
      model.addListener(batches.add);

      final batch = model.applyChanges([
        RowChange.update(SlidesTables.slideElement, front, {}, {'x': 300.0}),
      ]);

      expect(batch.isEmpty, isTrue);
      expect(batches, isEmpty);
    });
  });

  group('Given an empty model', () {
    late DeckModel model;
    setUp(() => model = DeckModel(deckId: testDeckId));

    test('when an update names a missing row then it is upserted', () {
      model.applyChanges([
        RowChange.update(SlidesTables.slide, 's1', {}, {'sortKey': 'a0'}),
      ]);

      expect(model.slide('s1')?.sortKey, 'a0');
    });

    test('when a missing row is deleted then nothing happens', () {
      final batch = model.applyChanges([
        RowChange.delete(SlidesTables.slide, 'nope', {'id': 'nope'}),
      ]);

      expect(batch.isEmpty, isTrue);
      expect(model.version, 1);
    });

    test('when there is no deck theme id then the theme with the smallest '
        'id is the default', () {
      model.applyChanges([
        RowChange.insert(SlidesTables.deckTheme, 'b', {'name': 'B'}),
        RowChange.insert(SlidesTables.deckTheme, 'a', {'name': 'A'}),
      ]);

      expect(model.defaultTheme?.name, 'A');
    });
  });

  group('Given a full fixture', () {
    late DeckBuilder b;
    late DeckModel model;
    late String slide, table, row0, col0;

    setUp(() {
      b = DeckBuilder();
      slide = b.slide(layoutKey: 'blank');
      final t = b.table(slide);
      (table, row0, col0) = (t.$1, t.$2.first, t.$3.first);
      b.cell(table, row0, col0, 'A1');
      final shape = b.shape(slide);
      b.build_(slide, shape);
      model = b.build();
    });

    test('when changes touch every kind of row then each event type is '
        'reported once', () {
      final layout = b.layoutId('title');
      final layoutEl = model.elementsOf(layout).first;
      final cell = model.cellsOf(table).single;
      final build = model.buildsOf(slide).single;

      final batch = model.applyChanges([
        RowChange.update(SlidesTables.deck, testDeckId, {}, {'title': 'New'}),
        RowChange.update(SlidesTables.slide, slide, {}, {'skipped': true}),
        RowChange.update(SlidesTables.slideElement, layoutEl.id, {}, {
          'x': 1.0,
        }),
        RowChange.update(SlidesTables.slideTableCell, cell.id, {}, {
          'fill': '#ff0000',
        }),
        RowChange.update(SlidesTables.slideBuild, build.id, {}, {
          'durationMs': 900,
        }),
      ], origin: DeckChangeOrigin.remote);

      expect(batch.isRemote, isTrue);
      expect(batch.event<DeckChanged>()!.columns, {'title'});
      expect(batch.event<SlidesChanged>()!.slideIds, {slide});
      expect(batch.event<OrderChanged>(), isNull);
      expect(batch.event<ThemeChanged>()!.layoutIds, {layout});
      expect(batch.event<ElementsChanged>()!.elementIds, {layoutEl.id, table});
      expect(batch.event<BuildsChanged>()!.slideIds, {slide});
      expect(batch.touchedSlideIds, {slide});
    });

    test('when reading table rows then axes are ordered per dimension', () {
      expect(model.axesOf(table, TableAxisDimension.row), hasLength(2));
      expect(model.axesOf(table, TableAxisDimension.column).first.id, col0);
      expect(model.cellsOf(table).single.rowId, row0);
    });

    test('when dumping then the dump is canonical and equals a rebuilt '
        'model', () {
      final again = DeckModel.fromRows(testDeckId, b.rows.reversed);

      expect(again.dump(), model.dump());
      expect(model.dump().keys.toList(), [...model.dump().keys]..sort());
    });
  });
}
