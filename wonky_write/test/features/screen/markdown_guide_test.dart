import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;

import 'support/screen_harness.dart';
import 'support/screen_pump.dart';
import 'support/shad_fonts.dart';

const _dialog = ValueKey<String>('write.dialog.markdownGuide');
const _wonkyTab = ValueKey<String>('write.dialog.markdownGuide.tab.wonky');
const _markdownTab = ValueKey<String>(
  'write.dialog.markdownGuide.tab.markdown',
);

/// Pumps an empty screen for [h]; returns a context below the navigator.
Future<BuildContext> _pump(
  WidgetTester tester,
  ScreenHarness h, {
  Brightness brightness = Brightness.light,
}) async {
  late BuildContext context;
  await pumpScreen(
    tester,
    h,
    Builder(
      builder: (c) {
        context = c;
        return const SizedBox.expand();
      },
    ),
    brightness: brightness,
  );
  return context;
}

/// Opens Help › Markdown guide as the menu does.
void _openGuide(ScreenHarness h, BuildContext context) => unawaited(
  h.services.dispatcher.invoke(
    'write.help.markdownGuide',
    source: InvocationSource.menu,
    context: context,
  ),
);

Finder _inDialog(String text) =>
    find.descendant(of: find.byKey(_dialog), matching: find.text(text));

void main() {
  setUpAll(loadShadFonts);

  testWidgets('Given a GitHub Markdown document when the Markdown guide '
      'opens then it lists the Markdown shortcuts without tabs, and Got it '
      'is the only way out (no X)', (tester) async {
    final h = await ScreenHarness.open(tester);
    final context = await _pump(tester, h);

    _openGuide(h, context);
    await tester.pumpAndSettle();

    expect(find.byKey(_dialog), findsOneWidget);
    expect(_inDialog('Bulleted list'), findsOneWidget);
    expect(find.byKey(_wonkyTab), findsNothing);
    expect(_inDialog(':::card'), findsNothing);
    expect(find.byKey(const ValueKey('dialog.close')), findsNothing);
    expect(_inDialog('Got it'), findsOneWidget);
    await h.dispose(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Given a Wonky Markdown document (${brightness.name}) when '
        'the Markdown guide opens then a second tab lists the extensions', (
      tester,
    ) async {
      final h = await ScreenHarness.open(tester);
      await tester.runAsync(
        () => h.services.dispatcher.invoke(
          'write.doc.setMarkdownFlavor',
          args: {'flavor': 'wonky'},
          source: InvocationSource.ui,
        ),
      );
      expect(h.doc.isWonky, isTrue);
      final context = await _pump(tester, h, brightness: brightness);

      _openGuide(h, context);
      await tester.pumpAndSettle();

      expect(find.byKey(_markdownTab), findsOneWidget);
      expect(_inDialog('Bulleted list'), findsOneWidget);
      await tester.tap(find.byKey(_wonkyTab));
      await tester.pumpAndSettle();

      for (final syntax in [
        ':::info … :::',
        ':::details',
        ':::card',
        ':::grid {columns=2 bullets=check}',
        ':button[Label](https://…)',
        ':link[Label](https://…)',
        ':chip[Label]{icon=tag}',
        '## (1) Heading',
      ]) {
        expect(_inDialog(syntax), findsOneWidget, reason: syntax);
      }
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await h.dispose(tester);
    });
  }
}
