import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/editor_screen/slide_labels.dart';
import 'package:wonky_slides/features/navigator/navigator_controller.dart';
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';

Finder key(String k) => find.byKey(ValueKey<String>(k));

/// The order as titles with `[Group: …]` (title slide: "Q3 review").
List<String> shape(DeckModel m) {
  final order = m.indexes.order;
  return [
    for (final t in order.topLevel)
      if (!t.isGroup)
        SlideLabels.title(m, t.id)
      else
        '[${m.group(t.id)!.title}: ${[for (var i = order.range(t.id)!.start; i < order.range(t.id)!.end; i++) SlideLabels.title(m, order.entries[i].id)].join(', ')}]',
  ];
}

/// The slide navigator (Slides 04 §5, SL-16) in the deck editor.
void main() {
  final l = slidesL10nEnglish;

  // sampleDeck(): "Q3 review" · [Intro: Our mission, The problem] · Demo
  String slide(DeckScreenRig r, int i) => r.editor.order.entries[i].id;
  String intro(DeckScreenRig r) => r.editor.order.groups.single.group.id;

  testWidgets('Given the navigator when a group header is clicked then the '
      'group and its slides are selected and the first one becomes current', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester);
    final g = intro(r);
    await tester.tap(key('slides.navigator.group.$g'));
    await tester.pump();
    expect(r.editor.selectedGroupIds, {g});
    expect(r.editor.selectedSlideIds, {slide(r, 1), slide(r, 2)});
    expect(r.editor.currentSlideId, slide(r, 1));
    expect(key('slides.navigator.group.$g.count'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given an expanded group when its chevron is clicked then it '
      'collapses to a header with a stacked preview, without an undo step', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester);
    final g = intro(r);
    final inside = slide(r, 2);
    expect(key('slides.navigator.slide.$inside'), findsOneWidget);
    await tester.tap(key('slides.navigator.group.$g.chevron'));
    await tester.pump();
    expect(key('slides.navigator.slide.$inside'), findsNothing);
    expect(key('slides.navigator.group.$g.preview'), findsOneWidget);
    expect(r.h.undoLabels, isEmpty);
    // A slide of the group shown from elsewhere expands it again.
    await r.run('slides.nav.goToSlide', {'slideId': inside});
    await tester.pump();
    expect(key('slides.navigator.slide.$inside'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the navigator with focus when the keyboard is used then '
      'arrows move the current slide, Ctrl+↓ moves it across the group '
      'boundary and Ctrl+G groups it with an inline rename (04 AC-5)', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester);
    final g = intro(r);
    await tester.tap(key('slides.navigator.slide.${slide(r, 0)}'));
    await tester.pump();
    expect(r.editor.navigatorFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    // The header gets focus without changing the slide.
    expect(r.editor.currentSlideId, slide(r, 0));
    expect(navigatorOf(r.editor).focusKey, 'group:$g');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(r.editor.currentSlideId, slide(r, 1));
    // ← on a slide in a group focuses its header; ← collapses it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(navigatorOf(r.editor).isCollapsed(g), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(navigatorOf(r.editor).isCollapsed(g), isFalse);

    // The title slide: Ctrl+↓ enters the expanded group first (04 §5.7).
    await tester.tap(key('slides.navigator.slide.${slide(r, 0)}'));
    await tester.pump();
    final first = slide(r, 0);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();
    expect(r.session.model.slide(first)!.groupId, g);
    expect(r.h.undoLabels.length, 1);

    // Ctrl+G groups the selection; the rename field opens.
    await tester.tap(key('slides.navigator.slide.${slide(r, 3)}'));
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump();
    await tester.pump();
    final created = r.session.model.groups.where((x) => x.id != g).single.id;
    expect(key('slides.navigator.rename.$created'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: key('slides.navigator.rename.$created'),
        matching: find.byType(EditableText),
      ),
      'Wrap-up',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(r.session.model.group(created)!.title, 'Wrap-up');
    expect(r.h.undoLabels.length, 3);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a slide row when it is dragged into a group then the '
      'indented drop indicator previews it without writing, and the drop is '
      'one undo step (04 §5.10)', (tester) async {
    final r = await pumpDeckScreen(tester);
    final demo = slide(r, 3);
    final mission = slide(r, 1);
    final before = shape(r.session.model);

    final from = tester.getCenter(key('slides.navigator.slide.$demo'));
    final over = tester.getRect(key('slides.navigator.slide.$mission'));
    final gesture = await tester.startGesture(
      from,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, -6));
    await tester.pump();
    // Lower half of "Our mission", well right of the indent: inside Intro.
    await gesture.moveTo(Offset(over.center.dx, over.bottom - 4));
    await tester.pump();
    expect(key('slides.navigator.dropIndicator'), findsOneWidget);
    expect(key('slides.navigator.ghost'), findsOneWidget);
    expect(shape(r.session.model), before);
    expect(r.h.undoLabels, isEmpty);

    await gesture.up();
    await tester.pump();
    expect(shape(r.session.model), [
      'Q3 review',
      '[Intro: Our mission, Demo, The problem]',
    ]);
    expect(r.h.undoLabels.length, 1);
    await r.h.undo();
    expect(shape(r.session.model), before);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a group header when it is dragged inside a group then the '
      'indicator is refused, and Esc cancels a drag', (tester) async {
    final b = sampleDeck();
    b.group('Outro', color: 'red');
    final r = await pumpDeckScreen(tester, fixture: b);
    final outro = r.session.model.groups.firstWhere((g) => g.title == 'Outro');
    final mission = slide(r, 1);

    final from = tester.getCenter(key('slides.navigator.group.${outro.id}'));
    final over = tester.getRect(key('slides.navigator.slide.$mission'));
    final gesture = await tester.startGesture(
      from,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveBy(const Offset(0, -6));
    await tester.pump();
    await gesture.moveTo(Offset(over.center.dx, over.bottom - 4));
    await tester.pump();
    expect(key('slides.navigator.dropRefused'), findsOneWidget);
    expect(find.text(l.reasonGroupsCantNest), findsOneWidget);
    await gesture.up();
    await tester.pump();
    expect(r.h.undoLabels, isEmpty);

    final g2 = await tester.startGesture(
      tester.getCenter(key('slides.navigator.slide.${slide(r, 0)}')),
      kind: PointerDeviceKind.mouse,
    );
    await g2.moveBy(const Offset(0, 30));
    await g2.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(navigatorOf(r.editor).drag, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(navigatorOf(r.editor).drag, isNull);
    await g2.up();
    await tester.pump();
    expect(r.h.undoLabels, isEmpty);
    await settleTooltips(tester);
    await r.close(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Given a skipped group collapsed in ${brightness.name} when '
        'the navigator shows then it renders without errors', (tester) async {
      final r = await pumpDeckScreen(tester, brightness: brightness);
      final g = intro(r);
      await r.run('slides.group.toggleSkip', {
        'groupIds': [g],
      });
      await r.run('slides.group.collapse', {
        'groupIds': [g],
      });
      await tester.pump();
      expect(key('slides.navigator.group.$g.skipped'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given a 640 × 720 window when the drawer navigator, the '
      'inspector, the notes and the grid view open then nothing overflows '
      '(04 AC-12)', (tester) async {
    final r = await pumpDeckScreen(tester, size: const Size(640, 720));
    expect(tester.takeException(), isNull);
    await tester.tap(key('slides.navigator.open'));
    await tester.pump();
    expect(key('slides.navigator'), findsOneWidget);
    // A click in the drawer selects the slide.
    await tester.tap(key('slides.navigator.slide.${slide(r, 3)}'));
    await tester.pump();
    expect(r.editor.currentSlideId, slide(r, 3));
    expect(tester.takeException(), isNull);
    await r.run('slides.inspector.open', {'tab': 'slide'});
    await tester.pump();
    await r.run('slides.view.toggleNotes');
    await tester.pump();
    expect(tester.takeException(), isNull);
    await r.run('slides.view.setMode', {'mode': 'grid'});
    await tester.pump();
    expect(key('slides.view.grid'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });
}
