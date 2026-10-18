import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_slides/features/themes/editor/theme_edit_scope.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/testing.dart' show DeckBuilder;
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_ui/testing.dart';

import '../../../support/deck_screen.dart';

/// The theme editor (Inspector › Theme in masters mode, Slides 05 §8.4;
/// SL-28): each committed control writes one theme JSON column in one undo
/// step; colors show contrast badges; *Derive dark colors*.
void main() {
  Finder key(String k) => find.byKey(ValueKey<String>(k));

  late DeckBuilder b;

  Future<DeckScreenRig> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) async {
    b = DeckBuilder(title: 'Themes');
    b.slide(layoutKey: 'title', title: 'Q3 review');
    final s2 = b.slide(title: 'Mission', body: 'Make it effortless');
    final r = await pumpDeckScreen(
      tester,
      fixture: b,
      brightness: brightness,
      // Tall: every section of the inspector list is built.
      size: const Size(1440, 6000),
      initialSlideId: s2,
    );
    await r.run('slides.theme.edit');
    await tester.pump();
    return r;
  }

  DeckThemeData data(DeckScreenRig r) =>
      SlideResolver.themeDataOf(r.session.model.theme(b.themeIds.themeId));

  String column(DeckScreenRig r, DeckThemeColumn c) =>
      jsonEncode(data(r).columnJson(c));

  for (final brightness in Brightness.values) {
    testWidgets('Given Edit theme in the ${brightness.name} app theme when '
        'the Theme tab shows then every section renders with contrast '
        'badges for the light scheme', (tester) async {
      final r = await open(tester, brightness: brightness);

      for (final id in [
        'themeInfo',
        'colors',
        'fonts',
        'textStyles',
        'themeBackground',
        'objects',
        'tables',
        'code',
        'charts',
      ]) {
        expect(key('slides.inspector.section.$id'), findsOneWidget, reason: id);
      }
      for (final k in ['text1', 'text2', 'accent1', 'link']) {
        expect(key('slides.theme.contrast.$k.light'), findsOneWidget);
      }
      expect(key('slides.theme.color.light.bg1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the Colors section when Dark is chosen and dark colors '
      'are derived then the dark scheme changes in one undo step', (
    tester,
  ) async {
    final r = await open(tester);
    final before = column(r, DeckThemeColumn.colorsJson);

    await tester.tap(key('slides.theme.appearance.dark'));
    await tester.pump();
    expect(key('slides.theme.color.dark.bg1'), findsOneWidget);
    expect(key('slides.theme.contrast.text1.dark'), findsOneWidget);

    await tester.tap(key('slides.theme.deriveDark'));
    await tester.pump();

    expect(column(r, DeckThemeColumn.colorsJson), isNot(before));
    expect(
      data(r).colors.light,
      BuiltInThemes.package('wonky')!.theme.colors.light,
    );
    expect(r.h.undoLabels, hasLength(1));
    await r.h.undo();
    expect(column(r, DeckThemeColumn.colorsJson), before);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the Colors section when a custom color is added and '
      'removed then each is one undo step', (tester) async {
    final r = await open(tester);

    await tester.tap(key('slides.theme.custom.add'));
    await tester.pump();
    expect(data(r).colors.custom, hasLength(1));
    expect(data(r).colors.custom.single.name, 'Custom 1');

    await tester.tap(key('slides.theme.custom1.remove'));
    await tester.pump();
    expect(data(r).colors.custom, isEmpty);
    expect(r.h.undoLabels, hasLength(2));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the Text styles section when the Title style is '
      'expanded and its size raised then textStylesJson changes', (
    tester,
  ) async {
    final r = await open(tester);
    final size0 = data(r).textStyles['title'].size!;

    await tester.tap(key('slides.theme.style.title'));
    await tester.pump();
    final plus = find.descendant(
      of: key('slides.theme.number.style.title.size'),
      matching: find.byIcon(LucideIcons.plus),
    );
    await tester.tap(plus);
    await tester.pump();

    expect(data(r).textStyles['title'].size, size0 + 2);
    expect(r.h.undoLabels, hasLength(1));
    expect(ThemeEditorState.of(r.editor).expanded('title'), isTrue);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the Background section when the dark override is '
      'switched on then backgroundJson gets a dark fill', (tester) async {
    final r = await open(tester);

    await tester.tap(key('slides.theme.background.darkOverride'));
    await tester.pump();

    final bg = data(r).columnJson(DeckThemeColumn.backgroundJson)!;
    expect(bg['fillDark'], isA<Map<Object?, Object?>>());
    expect(r.h.undoLabels, hasLength(1));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the Theme section when the name is changed then the '
      'theme is renamed', (tester) async {
    final r = await open(tester);

    await tester.enterText(key('slides.theme.field.name'), 'Brand');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(r.session.model.theme(b.themeIds.themeId)!.name, 'Brand');
    expect(r.h.undoLabels, hasLength(1));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the Objects section when the line weight is raised '
      'then shapeStyleJson is written', (tester) async {
    final r = await open(tester);
    final before = data(r).columnJson(DeckThemeColumn.shapeStyleJson);

    await tester.tap(
      find.descendant(
        of: key('slides.theme.number.line.width'),
        matching: find.byIcon(LucideIcons.plus),
      ),
    );
    await tester.pump();

    final after = data(r).columnJson(DeckThemeColumn.shapeStyleJson)!;
    expect(jsonEncode(after), isNot(jsonEncode(before)));
    expect(
      ThemeEditScope.getPath(after, ['line', 'stroke', 'width']),
      (ThemeEditScope.getPath(before ?? {}, ['line', 'stroke', 'width'])
                  as num? ??
              4) +
          1,
    );
    await settleTooltips(tester);
    await r.close(tester);
  });
}
