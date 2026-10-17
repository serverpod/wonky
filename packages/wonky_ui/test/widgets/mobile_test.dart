import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart';

/// The mobile layout check and the presenter bar (suite 02 §6.1).
void main() {
  Finder key(String k) => find.byKey(ValueKey<String>(k));

  group('Given WonkyLayout.isMobile', () {
    Future<bool> mobileAt(
      WidgetTester tester,
      Size size, {
      bool? override,
    }) async {
      late bool mobile;
      final probe = Builder(
        builder: (context) {
          mobile = WonkyLayout.isMobile(context);
          return const SizedBox();
        },
      );
      await pumpWonky(
        tester,
        override == null
            ? probe
            : WonkyLayout.override(mobile: override, child: probe),
        size: size,
      );
      return mobile;
    }

    testWidgets('when the window is narrower than 640 px then it is mobile', (
      tester,
    ) async {
      expect(await mobileAt(tester, const Size(360, 740)), isTrue);
      expect(await mobileAt(tester, const Size(639, 900)), isTrue);
    });

    testWidgets('when the window is 640 px or wider then it is not (also '
        'short desktop windows)', (tester) async {
      expect(await mobileAt(tester, const Size(640, 900)), isFalse);
      expect(await mobileAt(tester, const Size(1280, 500)), isFalse);
    });

    testWidgets('when overridden then the override wins', (tester) async {
      expect(
        await mobileAt(tester, const Size(1280, 800), override: true),
        isTrue,
      );
      expect(
        await mobileAt(tester, const Size(360, 740), override: false),
        isFalse,
      );
    });
  });

  group('Given the presenter bar', () {
    Future<List<String>> pump(
      WidgetTester tester, {
      Brightness brightness = Brightness.light,
      bool canGoBack = true,
    }) async {
      final calls = <String>[];
      await pumpWonky(
        tester,
        Align(
          alignment: Alignment.topCenter,
          child: WonkyPresenterBar(
            title: 'Quarterly review with a long title that ellipsizes',
            current: 3,
            total: 12,
            onClose: () => calls.add('close'),
            onPrevious: canGoBack ? () => calls.add('previous') : null,
            onNext: () => calls.add('next'),
          ),
        ),
        brightness: brightness,
        size: const Size(360, 740),
      );
      return calls;
    }

    testWidgets('when its buttons are tapped then close, back and forward '
        'are called', (tester) async {
      final calls = await pump(tester);
      expect(find.text('3 of 12'), findsOneWidget);

      await tester.tap(key('presenter.close'));
      await tester.tap(key('presenter.previous'));
      await tester.tap(key('presenter.next'));
      expect(calls, ['close', 'previous', 'next']);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
    });

    testWidgets('when back is not possible then its button is disabled', (
      tester,
    ) async {
      final calls = await pump(tester, canGoBack: false);
      await tester.tap(key('presenter.previous'), warnIfMissed: false);
      expect(calls, isEmpty);
      expect(
        tester.widget<ShadIconButton>(key('presenter.previous')).enabled,
        isFalse,
      );
    });

    for (final b in Brightness.values) {
      testWidgets('when shown in ${b.name} then it uses the theme background '
          'and is accessible', (tester) async {
        final semantics = tester.ensureSemantics();
        await pump(tester, brightness: b);
        final theme = ShadTheme.of(tester.element(key('presenter.bar')));
        expect(theme.brightness, b);
        final bar = tester.widget<Container>(key('presenter.bar'));
        expect(
          (bar.decoration! as BoxDecoration).color,
          theme.colorScheme.background,
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        semantics.dispose();
        await settleTooltips(tester);
      });
    }
  });
}
