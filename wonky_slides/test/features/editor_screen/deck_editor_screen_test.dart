import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides_core/model.dart'
    show DeckModelIndexes, ElementKind;
import 'package:wonky_slides_core/testing.dart' show DeckBuilder;
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides/features/editor_screen/deck_editor_controller.dart';
import 'package:wonky_slides/features/model/deck_session.dart';
import 'package:wonky_slides/features/sync/slides_data.dart'
    show SlidesDataUnavailableException;
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';

/// The deck editor screen (Slides 04 §2–§3, §14, §16; SL-11).
void main() {
  final l = slidesL10nEnglish;

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  for (final brightness in Brightness.values) {
    testWidgets('Given an open deck in the ${brightness.name} theme when the '
        'editor shows then title row, menubar, toolbar, navigator, canvas, '
        'notes, inspector and status bar render', (tester) async {
      final r = await pumpDeckScreen(tester, brightness: brightness);

      for (final m in [
        'File',
        'Edit',
        'View',
        'Insert',
        'Format',
        'Slide',
        'Arrange',
        'Tools',
        'Extensions',
        'Help',
      ]) {
        expect(find.text(m), findsWidgets, reason: m);
      }
      expect(key('slides.present'), findsOneWidget);
      expect(key('editor.share'), findsOneWidget);
      // The Present split button sits before Share (04 §3).
      expect(
        tester.getTopLeft(key('slides.present')).dx,
        lessThan(tester.getTopLeft(key('editor.share')).dx),
      );
      expect(key('slides.toolbar.newSlide'), findsOneWidget);
      expect(key('slides.navigator'), findsOneWidget);
      expect(key('slides.canvas'), findsOneWidget);
      expect(key('slides.notes'), findsOneWidget);
      expect(key('slides.inspector'), findsOneWidget);
      expect(key('slides.status.position'), findsOneWidget);
      expect(find.text(l.statusSlideOf(1, 4)), findsOneWidget);
      expect(find.text(l.statusSkipped(1)), findsOneWidget);
      // Group header in the navigator.
      expect(find.text('Intro'), findsWidgets);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the editor when a navigator slide is clicked then it '
      'becomes the current slide and PageDown moves on', (tester) async {
    final r = await pumpDeckScreen(tester);
    final second = r.editor.order.entries[1].id;

    await tester.tap(key('slides.navigator.slide.$second'));
    await tester.pump();
    expect(r.editor.currentSlideId, second);
    expect(find.text(l.statusSlideOf(2, 4)), findsOneWidget);
    expect(key('slides.canvas.slide.$second'), findsOneWidget);
    // Speaker notes of the slide (read-only shell).
    expect(find.text('Say hello first'), findsOneWidget);

    r.editor.canvasFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(r.editor.currentEntry!.index, 2);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the editor when the panes are toggled then navigator, '
      'notes and inspector hide and show again', (tester) async {
    final r = await pumpDeckScreen(tester);

    await r.run('slides.view.toggleInspector');
    await r.run('slides.view.toggleNavigator');
    await r.run('slides.view.toggleNotes');
    await tester.pump();
    expect(key('slides.inspector'), findsNothing);
    expect(key('slides.navigator'), findsNothing);
    expect(key('slides.notes.text'), findsNothing);
    expect(key('slides.notes.handle'), findsOneWidget);

    await r.run('slides.view.toggleInspector');
    await r.run('slides.view.toggleNavigator');
    await r.run('slides.view.toggleNotes');
    await tester.pump();
    expect(key('slides.inspector'), findsOneWidget);
    expect(key('slides.navigator'), findsOneWidget);
    expect(key('slides.notes.text'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the editor when the inspector tabs are used then the '
      'Format empty state and the Slide sections show, and the Animate tab '
      'is offered (SL-30)', (tester) async {
    final r = await pumpDeckScreen(tester);
    expect(key('slides.inspector.formatEmpty'), findsOneWidget);
    expect(key('slides.inspector.tab.format'), findsOneWidget);
    expect(key('slides.inspector.tab.animate'), findsOneWidget);
    expect(find.text(l.inspectorSectionSoon), findsNothing);

    await tester.tap(key('slides.inspector.tab.slide'));
    await tester.pump();
    expect(r.editor.inspectorTab, InspectorTab.slide);
    // The Slide tab scrolls (the layout gallery of SL-17 is tall).
    final scrollable = find
        .descendant(
          of: key('slides.inspector'),
          matching: find.byType(Scrollable),
        )
        .first;
    for (final id in ['layout', 'background', 'theme', 'visibility', 'info']) {
      await tester.scrollUntilVisible(
        key('slides.inspector.section.$id'),
        100,
        scrollable: scrollable,
      );
      expect(key('slides.inspector.section.$id'), findsOneWidget, reason: id);
    }
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the editor when Grid and Outline are chosen then each '
      'replaces navigator and canvas (SL-34)', (tester) async {
    final r = await pumpDeckScreen(tester);
    expect(key('slides.status.mode.normal'), findsOneWidget);
    expect(key('slides.status.mode.grid'), findsOneWidget);
    expect(key('slides.status.mode.outline'), findsOneWidget);

    await r.run('slides.view.setMode', {'mode': 'grid'});
    await tester.pump();
    expect(key('slides.view.grid'), findsOneWidget);
    expect(key('slides.navigator'), findsNothing);
    expect(key('slides.canvas'), findsNothing);

    await r.run('slides.view.setMode', {'mode': 'outline'});
    await tester.pump();
    expect(key('slides.view.outline'), findsOneWidget);
    expect(key('slides.canvas'), findsNothing);

    await r.run('slides.view.setMode', {'mode': 'normal'});
    await tester.pump();
    expect(r.editor.mode, DeckViewMode.normal);
    expect(key('slides.canvas'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the canvas when it is right-clicked then the slide '
      'context menu opens with its commands', (tester) async {
    final r = await pumpDeckScreen(tester);

    // An empty spot of the pasteboard (a hit element opens its own menu).
    await tester.tapAt(
      tester.getBottomLeft(key('slides.canvas')) + const Offset(8, -8),
      buttons: kSecondaryButton,
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(key('menu.context.slide.new'), findsOneWidget);
    // Transitions ship with SL-29 + SL-30.
    expect(key('menu.context.slide.transition'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 200));
    await settleTooltips(tester);
    await r.close(tester);
  });

  group('Given the load states (02 §9.1)', () {
    testWidgets('when the deck downloads then "Downloading presentation… '
        '42 %" shows over a skeleton', (tester) async {
      final r = await pumpDeckScreen(
        tester,
        scripted: const DeckLoading(
          progress: 0.42,
          message: 'Downloading presentation…',
        ),
      );

      expect(key('slides.loading'), findsOneWidget);
      expect(find.text('Downloading presentation… 42 %'), findsOneWidget);
      expect(key('slides.canvas'), findsNothing);

      (r.session as ScriptedDeckSession).state = const DeckReady();
      await tester.pump();
      await tester.pump();
      expect(key('slides.canvas'), findsOneWidget);
      expect(key('slides.loading'), findsNothing);
      await settleTooltips(tester);
      await r.close(tester);
    });

    testWidgets('when the deck is not on the device while offline then the '
        'offline state with Back to Slides shows', (tester) async {
      final r = await pumpDeckScreen(
        tester,
        scripted: DeckUnavailable(l.deckNotAvailableOffline, offline: true),
      );

      expect(key('slides.unavailable'), findsOneWidget);
      expect(find.text(l.deckNotAvailableOffline), findsOneWidget);
      expect(key('slides.unavailable.home'), findsOneWidget);
      await settleTooltips(tester);
      await r.close(tester);
    });

    testWidgets('when the presentation storage did not start then the error '
        'offers Try again, which opens the deck', (tester) async {
      var attempts = 0;
      late DeckScreenRig r;
      r = await pumpDeckScreen(
        tester,
        factory: (services, item) async {
          if (attempts++ == 0) {
            throw SlidesDataUnavailableException(l.screenStorageUnavailable);
          }
          return r.session;
        },
      );

      expect(key('slides.openFailed'), findsOneWidget);
      expect(find.text(l.screenStorageUnavailable), findsOneWidget);

      await tester.tap(key('slides.openFailed.retry'));
      for (var i = 0; i < 4; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(key('slides.canvas'), findsOneWidget);
      await settleTooltips(tester);
      await r.close(tester);
    });
  });

  testWidgets('Given a viewer when the deck opens then the toolbar is '
      'reduced, View only shows and mutating commands are disabled with the '
      'reason (04 AC-10)', (tester) async {
    final r = await pumpDeckScreen(tester, role: AccessRole.viewer);

    expect(find.text(l.badgeViewOnly), findsWidgets);
    expect(key('slides.toolbar.newSlide'), findsNothing);
    expect(key('slides.toolbar.zoom'), findsOneWidget);
    expect(key('slides.present'), findsOneWidget);
    expect(r.editor.canEdit, isFalse);
    final st = r.services.dispatcher.stateOf('slides.edit.delete');
    expect(st.enabled, isFalse);
    final mode = r.services.dispatcher.stateOf('slides.mode.editing');
    expect(mode.enabled, isFalse);
    expect(mode.disabledReason, l.reasonViewAccess);
    // Navigation and view state still work.
    await r.run('slides.nav.nextSlide');
    expect(r.editor.currentEntry!.index, 1);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given an editor when Viewing mode is chosen then the toolbar '
      'shows the Viewing badge and Editing returns', (tester) async {
    final r = await pumpDeckScreen(tester);

    await r.run('slides.mode.viewing');
    await tester.pump();
    expect(r.editor.viewMode, isTrue);
    expect(find.text(l.badgeViewing), findsOneWidget);
    expect(r.doc.mode, 'viewing');

    await r.run('slides.mode.editing');
    await tester.pump();
    expect(r.editor.viewMode, isFalse);
    expect(key('slides.toolbar.newSlide'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  for (final (width, label) in [
    (1100.0, 'medium (inspector overlays)'),
    (700.0, 'narrow (navigator drawer)'),
    (640.0, '640 px (the narrowest editor)'),
  ]) {
    for (final brightness in Brightness.values) {
      testWidgets('Given a $label ${brightness.name} window when the editor '
          'shows then nothing overflows (04 AC-12)', (tester) async {
        final r = await pumpDeckScreen(
          tester,
          size: Size(width, 760),
          brightness: brightness,
        );

        expect(key('slides.canvas'), findsOneWidget);
        expect(key('slides.present'), findsOneWidget);
        if (width < 768) {
          // The navigator is a drawer, closed at first.
          expect(key('slides.navigator'), findsNothing);
          await tester.tap(key('slides.navigator.open'));
          await tester.pump();
          expect(key('slides.navigator'), findsOneWidget);
          // The scrim right of the drawer closes it.
          final scrim = tester.getRect(key('slides.navigator.scrim'));
          await tester.tapAt(scrim.centerRight - const Offset(8, 0));
          await tester.pump();
          expect(key('slides.navigator'), findsNothing);
        } else {
          expect(key('slides.navigator'), findsOneWidget);
        }
        // Below 1,200 px the inspector is an overlay, closed at first.
        expect(key('slides.inspector'), findsNothing);
        await r.run('slides.inspector.open', {'tab': 'slide'});
        await tester.pump();
        expect(key('slides.inspector'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await settleTooltips(tester);
        await r.close(tester);
      });
    }
  }

  testWidgets('Given ?slide= when the deck opens then that slide is current', (
    tester,
  ) async {
    final third = sampleDeck().build().indexes.order.entries[2].id;

    final r = await pumpDeckScreen(tester, initialSlideId: third);
    expect(r.editor.currentSlideId, third);
    expect(r.doc.describeState()['currentSlideIndex'], 2);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a deck with code and chart elements (from a template or '
      'MCP) when they are selected then they render, the code (SL-31) and '
      'chart (SL-32) controls are offered and no control of an unbuilt '
      'feature is (SL-23)', (tester) async {
    final b = DeckBuilder(title: 'Hidden features');
    final slide = b.slide(layoutKey: 'blank');
    final code = b.element(slide, ElementKind.code);
    final chart = b.element(slide, ElementKind.chart, x: 600);
    final r = await pumpDeckScreen(tester, fixture: b, initialSlideId: slide);

    // Toolbar and title row: insert code (SL-31), chart (SL-32) and
    // comments (SL-38).
    expect(key('slides.toolbar.insert.code'), findsOneWidget);
    expect(key('slides.toolbar.chart'), findsOneWidget);
    for (final k in ['slides.toolbar.comment', 'editor.comments']) {
      expect(key(k), findsOneWidget, reason: k);
    }
    for (final id in [code, chart]) {
      r.editor.selectElements([id]);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text(l.inspectorSectionSoon), findsNothing);
      expect(
        key('slides.inspector.section.code'),
        id == code ? findsOneWidget : findsNothing,
      );
      expect(
        key('slides.inspector.section.chart'),
        id == chart ? findsOneWidget : findsNothing,
      );
      // (The long Code section pushes Arrange below the fold.)
      if (id == chart) {
        expect(key('slides.inspector.section.arrange'), findsOneWidget);
      }
    }
    await settleTooltips(tester);
    await r.close(tester);
  });
}
