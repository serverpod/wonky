import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

/// Wraps the paragraph starting with "Opted" in a [DocumentGestureOptOut].
class _OptOutBuilder implements ComponentBuilder {
  const _OptOutBuilder();

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) => null;

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! ParagraphComponentViewModel ||
        !componentViewModel.text.toPlainText().startsWith('Opted')) {
      return null;
    }
    final component = const ParagraphComponentBuilder().createComponent(componentContext, componentViewModel);
    return component == null ? null : DocumentGestureOptOut(child: component);
  }
}

// WONKY PATCH SE-14: gestures that start on opted-out content are not the
// editor's.
void main() {
  group('SuperEditor gesture opt-out (SE-14)', () {
    testWidgetsOnMac('a click on opted-out content changes no selection', (tester) async {
      await tester //
          .createDocument()
          .fromMarkdown('First paragraph\n\nOpted out paragraph')
          .withAddedComponents([const _OptOutBuilder()]).pump();
      final document = SuperEditorInspector.findDocument()!;
      final firstId = document.first.id;
      final optedOutId = document.last.id;
      expect(optedOutId, isNot(firstId));

      await tester.placeCaretInParagraph(firstId, 3);
      final before = SuperEditorInspector.findDocumentSelection();

      await tester.tapAt(tester.getCenter(find.text('Opted out paragraph', findRichText: true)));
      await tester.pump(kDoubleTapTimeout);

      expect(SuperEditorInspector.findDocumentSelection(), before);
    });
  });
}
