// Tests for WONKY PATCH SE-5 fixes found by the Write test suites.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/src/default_editor/selection_highlight.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_text_layout/super_text_layout.dart';

void main() {
  group('SE-5 fixes >', () {
    test('typing a character over an expanded selection replaces the selection',
        () {
      final document = MutableDocument(
          nodes: [ParagraphNode(id: 'p', text: AttributedText('an old word'))]);
      final composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection(
          base: DocumentPosition(
              nodeId: 'p', nodePosition: TextNodePosition(offset: 3)),
          extent: DocumentPosition(
              nodeId: 'p', nodePosition: TextNodePosition(offset: 6)),
        ),
      );
      final editor =
          createDefaultDocumentEditor(document: document, composer: composer);

      editor.execute([InsertCharacterAtCaretRequest(character: 'n')]);

      expect((document.first as ParagraphNode).text.toPlainText(), 'an n word');
      expect(composer.selection!.extent.nodePosition,
          const TextNodePosition(offset: 4));
    });

    test('changing a list item type keeps its indent and metadata', () {
      final document = MutableDocument(nodes: [
        ListItemNode.unordered(
            id: 'l',
            text: AttributedText('x'),
            indent: 3,
            metadata: const {'custom': 1}),
      ]);
      final editor = createDefaultDocumentEditor(
          document: document, composer: MutableDocumentComposer());

      editor.execute([
        ChangeListItemTypeRequest(nodeId: 'l', newType: ListItemType.ordered)
      ]);

      final item = document.first as ListItemNode;
      expect(item.type, ListItemType.ordered);
      expect(item.indent, 3);
      expect(item.getMetadataValue('custom'), 1);
    });

    testWidgets(
        'the selection of right-to-left text is painted on its characters',
        (tester) async {
      final document = MutableDocument(nodes: [
        ParagraphNode(id: 'p', text: AttributedText('مرحبا بالعالم')),
      ]);
      final composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection(
          base: DocumentPosition(
              nodeId: 'p', nodePosition: TextNodePosition(offset: 0)),
          extent: DocumentPosition(
              nodeId: 'p', nodePosition: TextNodePosition(offset: 5)),
        ),
      );
      final editor =
          createDefaultDocumentEditor(document: document, composer: composer);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SuperEditor(
            editor: editor,
            gestureMode: DocumentGestureMode.mouse,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final paint = find.descendant(
        of: find.byType(NonOverlappingSelectionHighlight),
        matching: find.byType(CustomPaint),
      );
      final painter = tester.widget<CustomPaint>(paint).painter!
          as NonOverlappingSelectionPainter;
      final paintOrigin =
          tester.renderObject<RenderBox>(paint).localToGlobal(Offset.zero);
      final text = tester.renderObject<RenderBox>(
        find.byType(LayoutAwareRichText),
      );
      expect(paintOrigin, text.localToGlobal(Offset.zero));
      // The first word is at the right end of the line.
      final bounds = painter.selectionPath()!.getBounds();
      expect(bounds.right, closeTo(text.size.width, 1));
      expect(bounds.left, greaterThan(text.size.width / 2));
    });
  });
}
