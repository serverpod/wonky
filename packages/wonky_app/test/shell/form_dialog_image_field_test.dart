import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

/// The image field of the form dialog (the submit dialog's cover image,
/// specs/18 §4.2).
void main() {
  late Future<DialogResult?> result;

  Future<McpDescribableDialog> open(
    WidgetTester tester,
    Future<ImageFieldPick?> Function() pick,
  ) async {
    await tester.pumpWidget(
      ShadApp(
        home: Builder(
          builder: (context) => Center(
            child: ShadButton(
              onPressed: () => result = showWonkyFormDialog(
                context,
                WonkyDialogSpec(
                  title: 'Submit',
                  dialogKey: 'dialog.test',
                  fields: [
                    ImageFieldSpec(
                      id: 'cover',
                      label: 'Cover image',
                      pick: pick,
                      uploadLabel: 'Upload image',
                      replaceLabel: 'Replace',
                      removeLabel: 'Remove',
                      emptyLabel: 'No cover',
                      uploadingLabel: 'Uploading…',
                      errorLabel: 'Upload failed',
                    ),
                  ],
                  buttons: const [
                    DialogButtonSpec(id: 'cancel', label: 'Cancel'),
                    DialogButtonSpec(id: 'ok', label: 'OK', primary: true),
                  ],
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
    return tester.state<State>(find.byType(WonkyFormDialog))
        as McpDescribableDialog;
  }

  testWidgets('Given an image field then MCP sees it as an image and can set '
      'and clear its value', (tester) async {
    final dialog = await open(tester, () async => null);

    final field = (dialog.describe()['fields']! as List).single as Map;
    expect(field['type'], 'image');
    expect(field['value'], '');
    expect(dialog.setField('cover', 'file-1'), isTrue);
    await tester.pump();
    expect(find.text('Replace'), findsOneWidget);
    expect(dialog.setField('cover', 3), isFalse);

    dialog.press('ok');
    await tester.pumpAndSettle();
    expect((await result)!.text('cover'), 'file-1');
  });

  testWidgets('Given an upload that fails then the error shows and the value '
      'stays empty', (tester) async {
    final dialog = await open(tester, () async => throw StateError('offline'));

    await tester.tap(_key('dialog.test.cover.upload'));
    await tester.pumpAndSettle();

    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.text('Upload image'), findsOneWidget);
    dialog.press('ok');
    await tester.pumpAndSettle();
    expect((await result)!.text('cover'), '');
  });
}
