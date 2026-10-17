import 'package:flutter/gestures.dart' show kSecondaryButton;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_slides_core/testing.dart' show DeckBuilder;
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';

/// Masters mode on the editor screen (Slides 05 §8.1; SL-28): navigator
/// of themes, masters and layouts, the banner with Done, the canvas
/// editing the layout, the Layout/Master and Theme inspector tabs.
void main() {
  final l = slidesL10nEnglish;

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  Finder navScrollable() => find
      .descendant(
        of: key('slides.masters.navigator'),
        matching: find.byType(Scrollable),
      )
      .first;

  late DeckBuilder b;
  late String s1, s2;

  DeckBuilder deck() {
    b = DeckBuilder(title: 'Masters');
    s1 = b.slide(layoutKey: 'title', title: 'Q3 review');
    s2 = b.slide(title: 'Mission', body: 'Make it effortless');
    b.slide(title: 'Plan', body: 'Ship it');
    return b;
  }

  Future<DeckScreenRig> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1440, 900),
  }) async {
    final r = await pumpDeckScreen(
      tester,
      fixture: deck(),
      brightness: brightness,
      size: size,
      initialSlideId: s2,
    );
    await r.run('slides.view.setMode', {'mode': 'masters'});
    await tester.pump();
    return r;
  }

  for (final brightness in Brightness.values) {
    testWidgets('Given a deck in the ${brightness.name} theme when masters '
        'mode opens then the navigator lists the theme, its master and '
        'layouts with usage, and the banner names the edited layout', (
      tester,
    ) async {
      final r = await open(tester, brightness: brightness);
      final titleBody = b.layoutId('titleBody');

      expect(r.editor.mode, DeckViewMode.masters);
      expect(key('slides.view.masters'), findsOneWidget);
      expect(key('slides.masters.navigator'), findsOneWidget);
      expect(key('slides.navigator'), findsNothing);
      expect(key('slides.notes'), findsNothing);
      expect(key('slides.masters.theme.${b.themeIds.themeId}'), findsOneWidget);
      expect(key('slides.masters.row.${b.themeIds.masterId}'), findsOneWidget);
      expect(key('slides.masters.row.$titleBody'), findsOneWidget);
      expect(
        tester.widget<Text>(key('slides.masters.usage.$titleBody')).data,
        '2',
      );
      expect(
        tester.widget<Text>(key('slides.masters.banner.text')).data,
        l.mastersBannerLayout('Title and content', 'Wonky', 2),
      );
      expect(key('slides.masters.placeholderChrome'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given masters mode when another layout row is clicked then '
      'the canvas edits it, and Done returns to Normal view', (tester) async {
    final r = await open(tester);
    final quote = b.layoutId('quote');

    await tester.scrollUntilVisible(
      key('slides.masters.row.$quote'),
      200,
      scrollable: navScrollable(),
    );
    await tester.tap(key('slides.masters.row.$quote'));
    await tester.pump();

    expect(r.editor.surfaceId, quote);
    expect(key('slides.canvas.slide.$quote'), findsOneWidget);
    expect(
      tester.widget<Text>(key('slides.masters.banner.text')).data,
      l.mastersBannerLayout('Quote', 'Wonky', 0),
    );

    await tester.tap(key('slides.masters.done'));
    await tester.pump();
    expect(r.editor.mode, DeckViewMode.normal);
    expect(key('slides.navigator'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the masters navigator has focus when Down and Up are '
      'pressed then the next and previous layout are edited', (tester) async {
    final r = await open(tester);
    final titleBody = b.layoutId('titleBody');
    await tester.tap(key('slides.masters.row.$titleBody'));
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(r.editor.surfaceId, b.layoutId('titleOnly'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(r.editor.surfaceId, b.layoutId('section'));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given masters mode when a layout placeholder is chosen in '
      'the Placeholders section then it is selected on the canvas as a text '
      'element', (tester) async {
    final r = await open(tester);
    await r.run('slides.inspector.open', {'tab': 'slide'});
    await tester.pump();
    final title = r.session.model
        .elementsOf(b.layoutId('titleBody'))
        .firstWhere((e) => e.placeholderType == SlidePlaceholderType.title);

    await tester.tap(key('slides.masters.placeholder.${title.id}'));
    await tester.pump();

    expect(r.editor.selectedElementIds, [title.id]);
    expect(r.editor.selectionKind, DeckSelectionKind.text);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given masters mode when the inspector shows then the Layout '
      'tab has the layout sections and the Theme tab the theme editor', (
    tester,
  ) async {
    final r = await open(tester);
    await r.run('slides.inspector.open', {'tab': 'slide'});
    await tester.pump();

    expect(
      find.descendant(
        of: key('slides.inspector.tab.slide'),
        matching: find.text(l.inspectorLayout),
      ),
      findsOneWidget,
    );
    expect(key('slides.inspector.tab.theme'), findsOneWidget);
    for (final id in ['surface', 'background', 'placeholders']) {
      expect(key('slides.inspector.section.$id'), findsOneWidget, reason: id);
    }
    expect(key('slides.masters.inspector.usage'), findsOneWidget);

    await tester.tap(key('slides.inspector.tab.theme'));
    await tester.pump();
    expect(r.editor.inspectorTab, InspectorTab.theme);
    expect(key('slides.inspector.section.themeInfo'), findsOneWidget);
    expect(key('slides.inspector.section.colors'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the Layout tab when Hide in layout picker is switched '
      'then the layout is hidden in one undo step', (tester) async {
    final r = await open(tester);
    await r.run('slides.inspector.open', {'tab': 'slide'});
    await tester.pump();

    await tester.tap(
      key('slides.masters.inspector.switch.slides.layout.toggleHidden'),
    );
    await tester.pump();

    expect(r.session.model.layout(b.layoutId('titleBody'))!.hidden, isTrue);
    expect(r.h.undoLabels, hasLength(1));
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a layout row when it is right-clicked then the layout '
      'context menu opens with its commands', (tester) async {
    final r = await open(tester);
    final quote = b.layoutId('quote');
    await tester.scrollUntilVisible(
      key('slides.masters.row.$quote'),
      200,
      scrollable: navScrollable(),
    );

    await tester.tap(
      key('slides.masters.row.$quote'),
      buttons: kSecondaryButton,
    );
    await tester.pumpAndSettle();

    expect(r.editor.surfaceId, quote);
    expect(find.text(l.cmdLayoutDuplicate), findsOneWidget);
    expect(find.text(l.cmdLayoutDelete), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await settleTooltips(tester);
    await r.close(tester);
  });

  for (final (width, label) in [(1100.0, 'medium'), (640.0, '640 px')]) {
    for (final brightness in Brightness.values) {
      testWidgets('Given a $label ${brightness.name} window when masters '
          'mode and its inspector show then nothing overflows', (tester) async {
        final r = await open(
          tester,
          size: Size(width, 760),
          brightness: brightness,
        );
        expect(key('slides.masters.navigator'), findsOneWidget);
        for (final tab in ['slide', 'theme']) {
          await r.run('slides.inspector.open', {'tab': tab});
          await tester.pump();
          expect(key('slides.inspector'), findsOneWidget);
          expect(tester.takeException(), isNull, reason: tab);
        }
        await settleTooltips(tester);
        await r.close(tester);
      });
    }
  }

  testWidgets('Given Viewing mode when masters mode is asked for then it '
      'is not offered, and switching to Viewing leaves it', (tester) async {
    final r = await pumpDeckScreen(tester, fixture: deck());
    r.editor.setViewMode(true);
    await tester.pump();
    expect(
      r.services.dispatcher.stateOf('slides.view.setMode', {
        'mode': 'masters',
      }).enabled,
      isFalse,
    );
    r.editor.setMode(DeckViewMode.masters);
    expect(r.editor.mode, DeckViewMode.normal);
    r.editor.setViewMode(false);
    r.editor.setMode(DeckViewMode.masters);
    expect(r.editor.mode, DeckViewMode.masters);
    r.editor.setViewMode(true);
    await tester.pump();
    expect(r.editor.mode, DeckViewMode.normal);
    expect(s1, isNotEmpty);
    await settleTooltips(tester);
    await r.close(tester);
  });
}
