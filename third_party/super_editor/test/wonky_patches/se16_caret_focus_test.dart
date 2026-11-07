import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

// WONKY PATCH SE-16: with a focus node, the caret shows only while the
// editor has focus.
void main() {
  group('SuperEditor caret and focus (SE-16)', () {
    testWidgetsOnMac(
        'the caret hides while the editor is unfocused and comes back with focus',
        (tester) async {
      final focusNode = FocusNode();
      final other = FocusNode();
      addTearDown(focusNode.dispose);
      addTearDown(other.dispose);
      final editor = createDefaultDocumentEditor(
        document: MutableDocument(nodes: [
          ParagraphNode(id: '1', text: AttributedText('Hello world')),
        ]),
        composer: MutableDocumentComposer(),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Focus(focusNode: other, child: const SizedBox(height: 10)),
                Expanded(
                  child: SuperEditor(
                    editor: editor,
                    focusNode: focusNode,
                    // Like Wonky Write: the selection outlives the focus.
                    selectionPolicies: const SuperEditorSelectionPolicies(
                      clearSelectionWhenEditorLosesFocus: false,
                      clearSelectionWhenImeConnectionCloses: false,
                    ),
                    documentOverlayBuilders: [
                      ...defaultSuperEditorDocumentOverlayBuilders.where(
                        (builder) => builder is! DefaultCaretOverlayBuilder,
                      ),
                      DefaultCaretOverlayBuilder(focusNode: focusNode),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.placeCaretInParagraph('1', 5);
      expect(focusNode.hasFocus, isTrue);
      expect(find.byKey(DocumentKeys.caret), findsOneWidget);

      // A menu or a toolbar takes the focus; the selection stays.
      other.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
      expect(editor.composer.selection, isNotNull);
      expect(find.byKey(DocumentKeys.caret), findsNothing);

      focusNode.requestFocus();
      await tester.pump();
      await tester.pump();
      expect(find.byKey(DocumentKeys.caret), findsOneWidget);
    });
  });
}
