import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/session.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_sync_models/ids.dart';

import '../../support/planner_fixture.dart';

/// The default theme *Wonky* is what a *Blank* presentation uses; it draws
/// no shapes or images behind the title slide (report #19, T-17, 05 §6).
void main() {
  final plainBackground = jsonEncode(SlideBackground.themeDefault.toJson());

  group('Given the built-in Wonky theme (05 §6)', () {
    final def = BuiltInThemes.byKey('wonky')!;

    test('when reading it then it is the default theme at version 2', () {
      expect(BuiltInThemes.defaultKey, 'wonky');
      expect(def.version, 2);
      expect(def.sourceKey, 'builtin:wonky@2');
    });

    for (final size in [
      SlideSize.widescreen,
      const SlideSize(SlideSizeKind.standard4x3, 1440, 1080),
    ]) {
      group('when building it for ${size.width}x${size.height}', () {
        final pkg = BuiltInThemes.package('wonky', size: size)!;
        final master = pkg.masters.single;

        test('then the theme background is a plain bg1 fill', () {
          expect(jsonEncode(pkg.theme.background.toJson()), plainBackground);
          expect(pkg.theme.background.fillDark, isNull);
          expect(pkg.theme.background.overlay, isNull);
        });

        test('then the master has no background and only placeholders', () {
          expect(master.background, isNull);
          expect(_decorations(master.elements), isEmpty);
        });

        for (final key in ['title', 'blank', 'titleBody']) {
          test('then the $key layout has no background and only '
              'placeholders', () {
            final l = master.layouts.singleWhere((l) => l.key == key);
            expect(l.background, isNull);
            expect(l.hideMasterElements, isFalse);
            expect(_decorations(l.elements), isEmpty);
          });
        }

        test('then the only decorations are the comparison cards', () {
          expect(
            [
              for (final l in master.layouts)
                for (final e in _decorations(l.elements)) '${l.key}/${e.name}',
            ],
            ['comparison/cardLeft', 'comparison/cardRight'],
          );
        });
      });
    }
  });

  group('Given an empty deck model', () {
    test('when creating a Blank deck then its title slide draws no shape or '
        'image behind the placeholders', () {
      final deck = MemoryDeck(
        model: DeckModel(deckId: testDeckId),
        userId: testUserId,
        planner: const SlidesPlanner(),
        ids: SequentialIdGenerator(10),
      );
      deck.execute(const CreateDeck(deckId: testDeckId, title: 'Blank'));
      final m = deck.model;

      expect(m.themes.single.sourceKey, 'builtin:wonky@2');
      _expectPlain(m, m.slides.single, plainBackground, onlyPlaceholders: true);
    });
  });

  group('Given a deck on another theme', () {
    test('when applying Wonky to every slide, undoing and redoing then the '
        'slides are plain and each state returns', () async {
      final f = PlannerFixture();
      final deck = f.session();
      final swiss =
          deck
                  .execute(const ImportTheme(builtInKey: 'swiss'))
                  .result['themeId']!
              as String;
      deck.execute(ApplyThemeToSlides(swiss, const []));
      final handler = SlidesRowsUndoHandler(() => deck);
      final before = deck.model.dump();

      final imported = deck.execute(const ImportTheme(builtInKey: 'wonky'));
      final wonky = imported.result['themeId']! as String;
      final applied = deck.execute(ApplyThemeToSlides(wonky, const []));
      final after = deck.model.dump();

      expect(deck.model.theme(wonky)!.sourceKey, 'builtin:wonky@2');
      for (final s in deck.model.slides) {
        _expectPlain(deck.model, s, plainBackground, themeId: wonky);
      }

      final undoApply = await handler.undo(
        SlidesRowsUndoEntry(applied.changes, label: applied.label),
      );
      final undoImport = await handler.undo(
        SlidesRowsUndoEntry(imported.changes, label: imported.label),
      );
      expect(deck.model.dump(), before);

      await handler.redo(undoImport);
      await handler.redo(undoApply);
      expect(deck.model.dump(), after);
      for (final s in deck.model.slides) {
        _expectPlain(deck.model, s, plainBackground, themeId: wonky);
      }
    });
  });
}

/// The elements of [elements] that are not placeholders (decorations).
List<ThemeElementSpec> _decorations(List<ThemeElementSpec> elements) => [
  for (final e in elements)
    if (e.placeholderType == null) e,
];

/// [slide] uses a plain Wonky layout: no slide/layout/master background
/// override, a plain theme background and no shape or image element on the
/// layout or the master; with [onlyPlaceholders] the slide has no
/// background and only placeholder instances.
void _expectPlain(
  DeckModel m,
  SlideRec slide,
  String plainBackground, {
  String? themeId,
  bool onlyPlaceholders = false,
}) {
  final themes = m.indexes.themes;
  final layout = themes.effectiveLayout(slide)!;
  final master = themes.masterOf(layout)!;
  final theme = themes.themeOfLayout(layout)!;
  if (themeId != null) expect(theme.id, themeId);
  expect(theme.sourceKey, 'builtin:wonky@2');
  expect(
    theme.themeColumns[DeckThemeCols.backgroundJson],
    plainBackground,
    reason: 'theme background',
  );
  expect(master.backgroundJson, isNull, reason: 'master background');
  if (layout.key != 'comparison') {
    expect(layout.backgroundJson, isNull, reason: '${layout.key} background');
    expect(
      [
        for (final e in m.allElementsOf(layout.id))
          if (e.placeholderType == null) e.name,
      ],
      isEmpty,
      reason: '${layout.key} decorations',
    );
  }
  expect([
    for (final e in m.allElementsOf(master.id))
      if (e.placeholderType == null) e.name,
  ], isEmpty);
  if (onlyPlaceholders) {
    expect(slide.backgroundJson, isNull, reason: 'slide background');
    expect([
      for (final e in m.allElementsOf(slide.id))
        if (e.placeholderOf == null) e.kindName,
    ], isEmpty);
  }
}
