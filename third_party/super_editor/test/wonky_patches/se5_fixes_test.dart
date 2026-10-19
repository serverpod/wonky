// Tests for WONKY PATCH SE-5 fixes found by the Write test suites.
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

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
  });
}
