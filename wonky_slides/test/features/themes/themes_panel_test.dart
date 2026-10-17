import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_slides/features/layouts/layout_gallery.dart';
import 'package:wonky_slides/features/themes/themes_panel.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/themes.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';

/// The Themes panel, the layout gallery and the page setup and slide
/// number dialogs (Slides 05 §4, §7, §9; 04 §12, §13.1, §13.3; SL-17).
void main() {
  Future<void> openPanel(WidgetTester tester, DeckScreenRig r) async {
    await r.run('slides.panel.themes');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String themeKeyOf(DeckModel m, String themeId) =>
      m.theme(themeId)!.sourceKey!.split(':').last.split('@').first;

  for (final brightness in Brightness.values) {
    testWidgets('Given the editor (${brightness.name}) when the Themes panel '
        'opens then it shows the appearance, the deck\'s theme and the 10 '
        'built-ins, and a click on Paper applies it to every slide in one '
        'step', (tester) async {
      final r = await pumpDeckScreen(tester, brightness: brightness);
      await openPanel(tester, r);

      expect(find.byKey(ThemesPanelKeys.panel), findsOneWidget);
      final m = r.editor.model;
      final wonky = m.deck!.themeId!;
      expect(find.byKey(ThemesPanelKeys.deckTheme(wonky)), findsOneWidget);
      for (final def in BuiltInThemes.all) {
        await tester.scrollUntilVisible(
          find.byKey(ThemesPanelKeys.builtIn(def.key)),
          80,
          scrollable: find
              .descendant(
                of: find.byKey(ThemesPanelKeys.panel),
                matching: find.byType(Scrollable),
              )
              .first,
        );
      }
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(ThemesPanelKeys.builtIn('paper')));
      await tester.pump();
      final id = m.deck!.themeId!;
      expect(themeKeyOf(m, id), 'paper');
      for (final e in r.editor.order.entries) {
        final l = m.indexes.themes.effectiveLayout(e.slide)!;
        expect(m.indexes.themes.themeOfLayout(l)!.id, id);
      }
      expect(r.h.undoLabels, hasLength(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(ThemesPanelKeys.deckTheme(id)), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the Themes panel when Dark is chosen then the deck '
      'appearance switches (one step) and the previews follow', (tester) async {
    final r = await pumpDeckScreen(tester);
    await openPanel(tester, r);

    await tester.tap(
      find.byKey(ThemesPanelKeys.appearance(SlideAppearance.dark)),
    );
    await tester.pump();
    expect(r.editor.model.deck!.appearance, SlideAppearance.dark);
    expect(r.h.undoLabels, hasLength(1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given Apply to: Selected slides when a built-in is clicked '
      'then only the selected slide changes and the default stays', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester);
    final m = r.editor.model;
    final wonky = m.deck!.themeId!;
    final second = r.editor.order.entries[1].id;
    r.editor.selectSlides([second]);
    await openPanel(tester, r);

    await tester.tap(find.byKey(ThemesPanelKeys.scopeSelected));
    await tester.pump();
    final card = find.byKey(ThemesPanelKeys.builtIn('swiss'));
    await tester.scrollUntilVisible(
      card,
      80,
      scrollable: find
          .descendant(
            of: find.byKey(ThemesPanelKeys.panel),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(card);
    await tester.pump();

    expect(m.deck!.themeId, wonky);
    final themes = m.indexes.themes;
    for (final e in r.editor.order.entries) {
      final t = themes.themeOfLayout(themes.effectiveLayout(e.slide)!)!.id;
      expect(t == wonky, e.id != second, reason: e.id);
    }
    await tester.pump(const Duration(milliseconds: 300));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a 640 × 720 window when the Themes panel opens then it '
      'fits without overflow', (tester) async {
    final r = await pumpDeckScreen(tester, size: const Size(640, 720));
    await openPanel(tester, r);
    // The narrow panel slides in over the editor.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(ThemesPanelKeys.panel), findsOneWidget);
    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.byKey(ThemesPanelKeys.panel));
    expect(rect.right, lessThanOrEqualTo(640));
    await settleTooltips(tester);
    await r.close(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Given the Slide tab (${brightness.name}) when a layout '
        'thumbnail is clicked then the current slide takes that layout', (
      tester,
    ) async {
      final r = await pumpDeckScreen(tester, brightness: brightness);
      final m = r.editor.model;
      final second = r.editor.order.entries[1].id;
      r.editor.setCurrentSlide(second);
      await r.run('slides.inspector.open', {
        'tab': 'slide',
        'section': 'layout',
      });
      await tester.pump(const Duration(milliseconds: 300));

      final quote = m.indexes.themes.layoutByKey(m.deck!.themeId!, 'quote')!;
      final cell = find.byKey(LayoutGalleryKeys.cell(quote.id));
      await tester.ensureVisible(cell);
      await tester.pump();
      await tester.tap(cell);
      await tester.pump();

      expect(m.slide(second)!.layoutId, quote.id);
      expect(r.h.undoLabels, hasLength(1));
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 300));
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given Page setup when MCP picks 4:3 with Scale content and '
      'presses Apply then the deck is resized in one step (04 §13.1)', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester);
    final done = r.services.dispatcher.invoke(
      'slides.file.pageSetup',
      source: InvocationSource.menu,
      context: tester.element(find.byKey(const ValueKey('slides.canvas'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('slides.dialog.pageSetup')), findsOne);
    expect(find.byKey(const ValueKey('slides.pageSetup.preview')), findsOne);
    final dialog = r.services.openDialogs.last;
    final desc = dialog.describe();
    expect(
      [for (final f in (desc['fields']! as List).cast<Map>()) f['id']],
      ['preset', 'width', 'height', 'unit', 'scaleContent'],
    );
    // An invalid custom size can't be applied.
    expect(dialog.setField('width', '0.5'), isTrue);
    await tester.pump();
    expect(find.byKey(const ValueKey('slides.pageSetup.error')), findsOne);
    expect(dialog.press('apply'), isFalse);
    expect(dialog.setField('preset', 'standard4x3'), isTrue);
    expect(dialog.setField('scaleContent', 'scale'), isTrue);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(dialog.press('apply'), isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    final result = await done;

    expect(result.isOk, isTrue);
    final deck = r.editor.model.deck!;
    expect([deck.width, deck.height], [1440, 1080]);
    expect(r.h.undoLabels, hasLength(1));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given Page setup at 640 px when it opens then it fits', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester, size: const Size(640, 720));
    final done = r.services.dispatcher.invoke(
      'slides.file.pageSetup',
      source: InvocationSource.menu,
      context: tester.element(find.byKey(const ValueKey('slides.canvas'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('slides.dialog.pageSetup')), findsOne);
    expect(tester.takeException(), isNull);
    r.services.openDialogs.last.press('cancel');
    await tester.pump(const Duration(milliseconds: 300));
    expect((await done).isOk, isFalse);
    expect(r.h.undoLabels, isEmpty);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given Slide numbers and footer when MCP fills it then the deck '
      'shows numbers from 0 with a footer (04 §13.3)', (tester) async {
    final r = await pumpDeckScreen(tester);
    final done = r.services.dispatcher.invoke(
      'slides.deck.openNumbering',
      source: InvocationSource.menu,
      context: tester.element(find.byKey(const ValueKey('slides.canvas'))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final dialog = r.services.openDialogs.last;
    expect(dialog.setField('showSlideNumbers', true), isTrue);
    expect(dialog.setField('firstSlideNumber', '0'), isTrue);
    expect(dialog.setField('footerText', 'Draft'), isTrue);
    await tester.pump();
    expect(dialog.press('apply'), isTrue);
    await tester.pump(const Duration(milliseconds: 300));
    expect((await done).isOk, isTrue);

    final deck = r.editor.model.deck!;
    expect(deck.showSlideNumbers, isTrue);
    expect(deck.firstSlideNumber, 0);
    expect(deck.footerText, 'Draft');
    expect(r.h.undoLabels, hasLength(1));
    await settleTooltips(tester);
    await r.close(tester);
  });
}
