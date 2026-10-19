import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/testing.dart';
import 'package:wonky_ui/wonky_ui.dart';

const _open = ValueKey<String>('test.open');
const _close = ValueKey<String>('dialog.close');

/// Pumps a button that opens a `ShadDialog` with [closeIcon] (in a
/// `PopScope` with [canPop]) and opens it; [onClosed] runs once it is gone.
Future<void> _pumpDialog(
  WidgetTester tester, {
  required Widget closeIcon,
  required void Function() onClosed,
  Brightness brightness = Brightness.light,
  bool canPop = true,
}) async {
  await pumpWonky(
    tester,
    Builder(
      builder: (context) => ShadButton(
        key: _open,
        onPressed: () => unawaited(
          showShadDialog<void>(
            context: context,
            // shad's barrier is unlabelled by default.
            barrierLabel: 'Dismiss',
            builder: (_) => PopScope(
              canPop: canPop,
              child: ShadDialog(
                title: const Text('Rename'),
                closeIcon: closeIcon,
                child: const Text('Body'),
              ),
            ),
          ).then((_) => onClosed()),
        ),
        child: const Text('Open'),
      ),
    ),
    brightness: brightness,
  );
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
}

void main() {
  for (final b in Brightness.values) {
    group('Given a dialog with the Wonky close button (${b.name})', () {
      testWidgets('when it shows then the X is labelled and pressing it '
          'closes the dialog', (tester) async {
        var closed = false;
        await _pumpDialog(
          tester,
          closeIcon: const WonkyDialogCloseButton(),
          onClosed: () => closed = true,
          brightness: b,
        );

        expect(find.bySemanticsLabel('Close'), findsOneWidget);
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await tester.tap(find.byKey(_close));
        await tester.pumpAndSettle();

        expect(closed, isTrue);
        expect(find.text('Body'), findsNothing);
      });
    });
  }

  group('Given a dialog with the Wonky close button', () {
    testWidgets('when the dialog refuses to pop then the X keeps it open', (
      tester,
    ) async {
      var closed = false;
      await _pumpDialog(
        tester,
        closeIcon: const WonkyDialogCloseButton(),
        onClosed: () => closed = true,
        canPop: false,
      );

      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();

      expect(closed, isFalse);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('when it has its own onPressed then the X runs it instead '
        'of closing', (tester) async {
      var pressed = 0;
      var closed = false;
      await _pumpDialog(
        tester,
        closeIcon: WonkyDialogCloseButton(onPressed: () => pressed++),
        onClosed: () => closed = true,
      );

      await tester.tap(find.byKey(_close));
      await tester.pumpAndSettle();

      expect(pressed, 1);
      expect(closed, isFalse);
      expect(find.text('Body'), findsOneWidget);
    });
  });
}
