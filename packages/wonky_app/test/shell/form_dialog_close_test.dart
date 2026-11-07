import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

/// The X of the form dialogs (`showWonkyFormDialog`: confirm, rename and
/// the apps' settings forms): none next to their buttons (suite 02 §4.20).
void main() {
  Future<void> open(
    WidgetTester tester, {
    required List<DialogButtonSpec> buttons,
    bool alert = false,
  }) async {
    await tester.pumpWidget(
      ShadApp(
        home: Builder(
          builder: (context) => Center(
            child: ShadButton(
              onPressed: () => showWonkyFormDialog(
                context,
                WonkyDialogSpec(
                  title: 'Rename',
                  dialogKey: 'dialog.test',
                  alert: alert,
                  buttons: buttons,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  for (final alert in [false, true]) {
    testWidgets('Given a form dialog${alert ? ' (alert)' : ''} with Cancel '
        'and OK then it has no X in the corner', (tester) async {
      await open(
        tester,
        alert: alert,
        buttons: const [
          DialogButtonSpec(id: 'cancel', label: 'Cancel'),
          DialogButtonSpec(id: 'ok', label: 'OK', primary: true),
        ],
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(_key('dialog.close'), findsNothing);
      expect(find.byIcon(LucideIcons.x), findsNothing);
    });
  }

  testWidgets('Given a form dialog without buttons then the X is its way out', (
    tester,
  ) async {
    await open(tester, buttons: const []);

    expect(_key('dialog.close'), findsOneWidget);
    await tester.tap(_key('dialog.close'));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsNothing);
  });
}
