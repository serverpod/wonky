import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';

/// Incremental rendering (CQ-43, 02 §11): resolved elements and scene nodes
/// keep their identity across edits of other elements, and render
/// revisions change only for what a change can affect.
void main() {
  late DeckBuilder b;
  late String s1, s2, a, bShape, table, cellRow, cellCol, decoration;
  late DeckModel m;
  late SlideResolver resolver;
  late SlideSceneBuilder builder;
  final engine = SlideTextLayout();

  setUp(() {
    b = DeckBuilder();
    s1 = b.slide(layoutKey: 'titleBody', title: 'One');
    s2 = b.slide(layoutKey: 'titleBody', title: 'Two');
    a = b.shape(s1, x: 100, text: 'A');
    bShape = b.shape(s1, x: 600, text: 'B');
    final (t, rows, cols) = b.table(s1, rows: 2, cols: 2, y: 600);
    table = t;
    cellRow = rows.first;
    cellCol = cols.first;
    b.cell(t, cellRow, cellCol, 'Cell');
    decoration = b.element(
      b.themeIds.masterId,
      ElementKind.shape,
      ownerKind: ElementOwnerKind.master,
      x: 0,
      y: 1000,
      width: 1920,
      height: 80,
      columns: {
        ElementCols.dataJson: jsonEncode({'v': 1, 'geometry': 'rect'}),
      },
    );
    m = b.build();
    resolver = SlideResolver(m);
    builder = SlideSceneBuilder();
  });

  SlideScene sceneOf(String slideId) {
    final r = resolver.resolve(slideId)!;
    return builder.build(
      r,
      SceneContext(theme: r.theme, textLayout: engine, deck: m),
    );
  }

  void move(String id, double x) => m.applyChanges([
    RowChange.update(
      SlidesTables.slideElement,
      id,
      {ElementCols.x: m.element(id)!.x},
      {ElementCols.x: x},
    ),
  ]);

  void setSlide(String id, String column, Object? value) => m.applyChanges([
    RowChange.update(
      SlidesTables.slide,
      id,
      {column: m.slide(id)!.columns[column]},
      {column: value},
    ),
  ]);

  void setDeck(String column, Object? value) => m.applyChanges([
    RowChange.update(
      SlidesTables.deck,
      m.deck!.id,
      {column: m.deck!.columns[column]},
      {column: value},
    ),
  ]);

  group('Given a resolved slide', () {
    test('when element B moves then A resolves to the identical element and '
        'keeps its scene node', () {
      final r1 = resolver.resolve(s1)!;
      final n1 = sceneOf(s1);

      move(bShape, 700);
      final r2 = resolver.resolve(s1)!;
      final n2 = sceneOf(s1);

      expect(identical(r1, r2), isFalse);
      expect(identical(r1.element(a), r2.element(a)), isTrue);
      expect(identical(r1.element(bShape), r2.element(bShape)), isFalse);
      expect(identical(n1.nodesOf(a).first, n2.nodesOf(a).first), isTrue);
      expect(
        identical(n1.nodesOf(bShape).first, n2.nodesOf(bShape).first),
        isFalse,
      );
    });

    test('when a table cell changes then the table element keeps its '
        'identity but its node is rebuilt', () {
      final r1 = resolver.resolve(s1)!;
      final n1 = sceneOf(s1);
      final cell = m.indexes.table(table).cellAt(0, 0)!;

      m.applyChanges([
        RowChange.update(
          SlidesTables.slideTableCell,
          cell.id,
          {SlidesCols.text: cell.text},
          {SlidesCols.text: deltaOf('Changed')},
        ),
      ]);
      final r2 = resolver.resolve(s1)!;
      final n2 = sceneOf(s1);

      expect(identical(r1.element(table), r2.element(table)), isTrue);
      expect(
        identical(n1.nodesOf(table).first, n2.nodesOf(table).first),
        isFalse,
      );
      expect(identical(n1.nodesOf(a).first, n2.nodesOf(a).first), isTrue);
    });

    test('when two slides draw the same master decoration then it is '
        'resolved once and shares its node', () {
      final one = resolver.resolve(s1)!;
      final two = resolver.resolve(s2)!;
      ResolvedElement deco(ResolvedSlide s) =>
          s.masterElements.firstWhere((e) => e.id == decoration);

      expect(identical(deco(one), deco(two)), isTrue);
      expect(
        identical(
          sceneOf(s1).nodesOf(decoration).first,
          sceneOf(s2).nodesOf(decoration).first,
        ),
        isTrue,
      );
    });

    test('when the same element is built for the canvas and a thumbnail '
        'then both nodes stay cached', () {
      final r = resolver.resolve(s1)!;
      SlideScene build(ScenePurpose p, {bool editing = false}) => builder.build(
        r,
        SceneContext(
          theme: r.theme,
          textLayout: engine,
          deck: m,
          purpose: p,
          editing: editing,
        ),
      );
      final edit = build(ScenePurpose.edit, editing: true);
      final thumb = build(ScenePurpose.thumbnail);
      final before = SlideSceneBuilder.debugNodeBuilds;

      final edit2 = build(ScenePurpose.edit, editing: true);
      final thumb2 = build(ScenePurpose.thumbnail);

      expect(SlideSceneBuilder.debugNodeBuilds, before);
      expect(identical(edit.nodesOf(a).first, edit2.nodesOf(a).first), isTrue);
      expect(
        identical(thumb.nodesOf(a).first, thumb2.nodesOf(a).first),
        isTrue,
      );
    });
  });

  group('Given the render revisions of both slides', () {
    late Map<String, String> before;

    setUp(() {
      before = {
        for (final s in [s1, s2]) s: m.indexes.revision(s),
      };
    });

    List<String> changed() => [
      for (final s in [s1, s2])
        if (m.indexes.revision(s) != before[s]) s,
    ];

    test('when speaker notes or timings change then no slide re-renders, '
        'and the order and model hold the new row', () {
      setSlide(s1, SlideCols.notes, deltaOf('Say hi'));
      setSlide(s1, SlideCols.timingsJson, '{"v":1}');

      expect(changed(), isEmpty);
      expect(m.indexes.order.entry(s1)!.slide.notes, deltaOf('Say hi'));
      expect(m.slides.first.notes, deltaOf('Say hi'));
    });

    test('when the deck is renamed, guides move or present settings change '
        'then no slide re-renders', () {
      setDeck(DeckCols.title, 'Renamed');
      setDeck(DeckCols.guidesJson, '{"v":1,"vertical":[100],"horizontal":[]}');
      setDeck(DeckCols.presentJson, '{"v":1}');

      expect(changed(), isEmpty);
    });

    test('when the footer changes then every slide re-renders', () {
      setDeck(DeckCols.footerText, 'Confidential');

      expect(changed(), [s1, s2]);
    });

    test('when a layout no slide uses changes then no slide re-renders, and '
        'when the used one changes then both do', () {
      final unused = b.layoutId('title');
      final used = b.layoutId('titleBody');
      final el = m.elementsOf(unused).first;
      final usedEl = m.elementsOf(used).first;

      move(el.id, (el.x ?? 0) + 5);
      expect(changed(), isEmpty);

      move(usedEl.id, (usedEl.x ?? 0) + 5);
      expect(changed(), [s1, s2]);
    });

    test('when one slide is skipped then the next one is renumbered', () {
      setSlide(s1, SlidesCols.skipped, true);

      expect(changed(), [s1, s2]);
      expect(m.indexes.order.entry(s2)!.number, 1);
    });
  });
}
