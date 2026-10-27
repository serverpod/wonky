import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

// WONKY PATCH SE-12: the app can move the caret of a collapsed selection.
void main() {
  group('SuperEditor caret adjustment (SE-12)', () {
    testWidgetsOnMac('a collapsed caret is drawn where adjustCaretRect puts it, again when its listenable notifies',
        (tester) async {
      final shift = ValueNotifier<double>(0);
      addTearDown(shift.dispose);
      final editor = createDefaultDocumentEditor(
        document: MutableDocument(nodes: [
          ParagraphNode(id: '1', text: AttributedText('Hello world')),
        ]),
        composer: MutableDocumentComposer(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SuperEditor(
              editor: editor,
              documentOverlayBuilders: [
                ...defaultSuperEditorDocumentOverlayBuilders.where(
                  (builder) => builder is! DefaultCaretOverlayBuilder,
                ),
                DefaultCaretOverlayBuilder(
                  adjustCaretRect: (position, rect, layout) => rect.translate(shift.value, 0),
                  caretRectListenable: shift,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.placeCaretInParagraph('1', 5);

      final before = SuperEditorInspector.findCaretOffsetInDocument();
      shift.value = -3;
      await tester.pump();

      expect(SuperEditorInspector.findCaretOffsetInDocument().dx, closeTo(before.dx - 3, 0.01));
    });
  });
}
