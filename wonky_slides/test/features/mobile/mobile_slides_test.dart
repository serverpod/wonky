import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart' show ShadIconButton, ShadTheme;
import 'package:wonky_slides/features/navigator/mobile_slide_strip.dart';
import 'package:wonky_slides/features/navigator/nav_thumbnail.dart';
import 'package:wonky_slides/features/notes/notes_pane.dart';
import 'package:wonky_slides/features/present/present_overlays.dart';
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyMenubar, WonkyToolbar;

import '../../support/deck_screen.dart';
import '../present/present_rig.dart';

/// The mobile layout of Slides (suite 02 §6.1, Slides 04 §16.1, 10 §1.4):
/// read-only deck with the compact slide selector, and the full-window
/// presenter mode with its top bar.
void main() {
  const phone = Size(390, 844);

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  group('Given a narrow window', () {
    testWidgets('when an owner opens a deck then it is read-only: no menubar, '
        'toolbar, navigator or notes, and editing commands are off', (
      tester,
    ) async {
      final r = await pumpDeckScreen(tester, size: phone);

      expect(key('editor.mobile'), findsOneWidget);
      expect(key('editor.mobile.readOnly'), findsOneWidget);
      expect(find.byType(WonkyMenubar), findsNothing);
      expect(find.byType(WonkyToolbar), findsNothing);
      expect(key('slides.toolbar.zoom'), findsNothing);
      expect(key('slides.navigator'), findsNothing);
      expect(find.byType(NotesPane), findsNothing);
      expect(key('slides.canvas'), findsOneWidget);
      expect(r.editor.readOnlyView, isTrue);
      expect(r.editor.canEdit, isFalse);
      expect(
        r.services.dispatcher.stateOf('slides.edit.delete').enabled,
        isFalse,
      );
      expect(
        r.services.dispatcher.stateOf('slides.mode.editing').enabled,
        isFalse,
      );
      expect(r.doc.mode, 'viewing');
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });

    testWidgets('when the deck shows then the compact slide selector lists '
        'every slide in small thumbnails and a tap shows that slide', (
      tester,
    ) async {
      final r = await pumpDeckScreen(tester, size: phone);
      final ids = [for (final e in r.editor.order.entries) e.id];

      expect(key('slides.mobile.strip'), findsOneWidget);
      for (final id in ids) {
        expect(key('slides.mobile.slide.$id'), findsOneWidget);
      }
      // The smaller variant: 72 px thumbnails (the navigator's are ≥ 112).
      final thumbs = tester.widgetList<NavThumbnail>(find.byType(NavThumbnail));
      expect(thumbs, hasLength(ids.length));
      expect(
        thumbs.every((t) => t.width == MobileSlideStrip.thumbWidth),
        isTrue,
      );
      expect(
        tester.getSize(key('slides.mobile.slide.${ids.first}')).width,
        MobileSlideStrip.thumbWidth,
      );

      await tester.tap(key('slides.mobile.slide.${ids[2]}'));
      await tester.pump();
      expect(r.editor.currentSlideId, ids[2]);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });

    testWidgets('when Present is tapped then present mode opens at the '
        'current slide (never the presenter view)', (tester) async {
      final r = await pumpDeckScreen(tester, size: phone);
      final second = r.editor.order.entries[1].id;
      await r.run('slides.nav.goToSlide', {'slideId': second});
      await tester.pump();

      await tester.tap(key('slides.mobile.present'));
      await tester.pump();

      final location = r.services.router.routeInformationProvider.value.uri
          .toString();
      expect(location, '/p/${r.session.itemUuid.uuid}/present?slide=$second');
      await settleTooltips(tester);
      await r.close(tester);
    });

    for (final b in Brightness.values) {
      testWidgets('when the deck shows in ${b.name} at 360 px then nothing '
          'overflows', (tester) async {
        final r = await pumpDeckScreen(
          tester,
          size: const Size(360, 640),
          brightness: b,
        );
        expect(key('slides.mobile.strip'), findsOneWidget);
        expect(key('slides.mobile.present'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await settleTooltips(tester);
        await r.close(tester);
      });
    }
  });

  testWidgets('Given a deck read-only on a phone when the window becomes '
      'wide then the desktop editor and editing return', (tester) async {
    final r = await pumpDeckScreen(tester, size: phone);
    expect(r.editor.canEdit, isFalse);

    tester.view.physicalSize = const Size(1440, 900);
    await tester.pump();
    await tester.pump();

    expect(key('editor.mobile'), findsNothing);
    expect(key('slides.navigator'), findsOneWidget);
    expect(key('slides.toolbar.newSlide'), findsOneWidget);
    expect(r.editor.readOnlyView, isFalse);
    expect(r.editor.canEdit, isTrue);
    await settleTooltips(tester);
    await r.close(tester);
  });

  group('Given present mode on a phone', () {
    testWidgets('when it opens then it fills the window with the presenter '
        'bar: close, back and forward', (tester) async {
      final r = await pumpPresent(tester, size: phone);

      expect(key('slides.present.mobile'), findsOneWidget);
      expect(key('presenter.bar'), findsOneWidget);
      expect(key('presenter.close'), findsOneWidget);
      expect(key('presenter.previous'), findsOneWidget);
      expect(key('presenter.next'), findsOneWidget);
      expect(find.text('1 of 4'), findsOneWidget);
      expect(find.text('Q3 review'), findsOneWidget);
      // The stage fills the rest of the window.
      final bar = tester.getRect(key('presenter.bar'));
      final stage = tester.getRect(key('slides.present.stage'));
      expect(bar.top, 0);
      expect(bar.width, phone.width);
      expect(stage.top, bar.bottom);
      expect(stage.bottom, phone.height);
      // The desktop toolbar is not shown.
      expect(find.byType(PresentToolbar), findsNothing);
      await settleTooltips(tester);
      await r.close(tester);
    });

    testWidgets('when forward and back are tapped then the slides change, '
        'and back is off on the first slide', (tester) async {
      final r = await pumpPresent(tester, size: phone);
      final ids = r.ids;
      expect(r.shown, ids[0]);
      expect(
        tester.widget<ShadIconButton>(key('presenter.previous')).enabled,
        isFalse,
      );

      await tester.tap(key('presenter.next'));
      await r.settle(tester);
      expect(r.shown, ids[1]);
      expect(find.text('2 of 4'), findsOneWidget);

      r.clock[0] += 200; // Past the 120 ms burst filter.
      await tester.tap(key('presenter.previous'));
      await r.settle(tester);
      expect(r.shown, ids[0]);
      await settleTooltips(tester);
      await r.close(tester);
    });

    testWidgets('when close is tapped then present mode ends and the deck '
        'shows again, still read-only', (tester) async {
      final r = await pumpPresent(tester, size: phone);
      await tester.tap(key('presenter.next'));
      await r.settle(tester);
      final shown = r.shown;

      await tester.tap(key('presenter.close'));
      await r.settle(tester);

      expect(r.controller.ended, isTrue);
      expect(r.location, r.deckPath);
      expect(r.editor.currentSlideId, shown);
      expect(r.editor.readOnlyView, isTrue);
      expect(r.editor.canEdit, isFalse);
      await settleTooltips(tester);
      await r.close(tester);
    });

    for (final b in Brightness.values) {
      testWidgets('when it shows in ${b.name} then the bar and the letterbox '
          'use the app theme and text has enough contrast', (tester) async {
        final semantics = tester.ensureSemantics();
        final r = await pumpPresent(tester, size: phone, brightness: b);

        final context = tester.element(key('presenter.bar'));
        final theme = ShadTheme.of(context);
        expect(theme.brightness, b);
        final bar = tester.widget<Container>(key('presenter.bar'));
        expect(
          (bar.decoration! as BoxDecoration).color,
          theme.colorScheme.background,
        );
        final box = tester.widget<ColoredBox>(
          find
              .descendant(
                of: key('slides.present.stage'),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(box.color, theme.colorScheme.background);
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
        await settleTooltips(tester);
        await r.close(tester);
      });
    }
  });
}
