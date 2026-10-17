import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/accessibility/accessibility_checker.dart';
import 'package:wonky_slides/features/accessibility/accessibility_panel.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';

/// The Accessibility panel (Slides 03 §17.4; SL-34).
void main() {
  late String good, bad, image, small;

  DeckBuilder fixture() {
    final b = DeckBuilder(title: 'Checks');
    good = b.slide(title: 'Welcome', body: 'Hello everyone');
    bad = b.slide(title: 'Numbers', body: 'Growth');
    image = b.element(bad, ElementKind.image, x: 1200, y: 600);
    small = b.element(
      bad,
      ElementKind.text,
      x: 100,
      y: 900,
      columns: {
        SlidesCols.text: jsonEncode([
          {
            'insert': 'Footnote',
            'attributes': {'size': 12},
          },
          {'insert': '\n'},
        ]),
      },
    );
    return b;
  }

  Future<DeckScreenRig> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1440, 900),
    DeckBuilder? b,
  }) async {
    final r = await pumpDeckScreen(
      tester,
      fixture: b ?? fixture(),
      brightness: brightness,
      size: size,
    );
    await r.run('slides.tools.accessibilityCheck');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return r;
  }

  A11yIssue issue(A11yRule rule, String slide, String element) =>
      A11yIssue(rule: rule, slideId: slide, elementId: element);

  for (final brightness in Brightness.values) {
    testWidgets('Given a deck with issues (${brightness.name}) when the check '
        'runs from Tools then the panel lists them by slide with a summary', (
      tester,
    ) async {
      final r = await open(tester, brightness: brightness);

      expect(find.byKey(AccessibilityPanelKeys.panel), findsOneWidget);
      expect(find.byKey(AccessibilityPanelKeys.slide(bad)), findsOneWidget);
      expect(find.byKey(AccessibilityPanelKeys.slide(good)), findsNothing);
      expect(
        find.byKey(
          AccessibilityPanelKeys.issue(
            issue(A11yRule.missingAltText, bad, image),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Text smaller than 18 (12)'), findsOneWidget);
      expect(find.textContaining('1 error'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the panel when an issue is fixed then it disappears on '
      'the next check, in one undo step', (tester) async {
    final r = await open(tester);
    final alt = issue(A11yRule.missingAltText, bad, image);

    await tester.tap(find.byKey(AccessibilityPanelKeys.decorative(alt)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(r.editor.model.element(image)!.decorative, isTrue);
    expect(find.byKey(AccessibilityPanelKeys.issue(alt)), findsNothing);
    expect(r.h.undoLabels, hasLength(1));

    final tiny = issue(A11yRule.smallText, bad, small);
    await tester.tap(find.byKey(AccessibilityPanelKeys.fix(tiny)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(AccessibilityPanelKeys.issue(tiny)), findsNothing);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the panel when Go to is clicked then the slide shows '
      'with the element selected', (tester) async {
    final r = await open(tester);
    final alt = issue(A11yRule.missingAltText, bad, image);

    await tester.tap(find.byKey(AccessibilityPanelKeys.goTo(alt)));
    await tester.pump();

    expect(r.editor.currentSlideId, bad);
    expect(r.editor.selectedElementIds, [image]);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a deck without issues when it is checked then the '
      'panel says so', (tester) async {
    final b = DeckBuilder(title: 'Clean');
    b.slide(title: 'One', body: 'Fine');
    b.slide(title: 'Two', body: 'Also fine');
    final r = await open(tester, b: b);

    expect(find.byKey(AccessibilityPanelKeys.empty), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets(
    'Given a 640 px (the narrowest editor) window when the panel opens then nothing '
    'overflows',
    (tester) async {
      final r = await open(tester, size: const Size(640, 780));

      expect(find.byKey(AccessibilityPanelKeys.panel), findsOneWidget);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    },
  );
}
