// Tests for WONKY PATCH SE-2 (incremental, composer-free document patches).
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  group('SE-2 ApplyDocumentPatchRequest >', () {
    late MutableDocument document;
    late MutableDocumentComposer composer;
    late Editor editor;
    late List<List<EditEvent>> transactions;

    setUp(() {
      document = MutableDocument(nodes: [
        ParagraphNode(id: 'a', text: AttributedText('Hello')),
        ParagraphNode(id: 'b', text: AttributedText('World')),
      ]);
      composer = MutableDocumentComposer(
        initialSelection: const DocumentSelection.collapsed(
          position: DocumentPosition(
              nodeId: 'b', nodePosition: TextNodePosition(offset: 2)),
        ),
      );
      editor = createDefaultDocumentEditor(
          document: document, composer: composer, isHistoryEnabled: true);
      transactions = [];
      editor.addListener(FunctionalEditListener(transactions.add));
    });

    test('replaces, inserts, moves and deletes nodes with precise events', () {
      editor.execute([
        ApplyDocumentPatchRequest(
          operations: [
            ReplaceNodePatch(
                'a', ParagraphNode(id: 'a', text: AttributedText('Hi'))),
            InsertNodePatch(
                1, ParagraphNode(id: 'c', text: AttributedText('New'))),
            const MoveNodePatch('b', 0),
            const DeleteNodePatch('c'),
          ],
          tag: 'remote',
        ),
      ]);

      expect(document.map((n) => n.id).toList(), ['b', 'a']);
      expect((document.getNodeById('a') as ParagraphNode).text.toPlainText(),
          'Hi');

      final events = transactions.single;
      expect(
          events.first,
          isA<DocumentPatchAppliedEvent>()
              .having((e) => e.tag, 'tag', 'remote'));
      final changes =
          events.whereType<DocumentEdit>().map((e) => e.change).toList();
      expect(changes[0],
          isA<NodeReplacedEvent>().having((e) => e.nodeId, 'nodeId', 'a'));
      expect(changes[1],
          isA<NodeInsertedEvent>().having((e) => e.nodeId, 'nodeId', 'c'));
      expect(changes[2], isA<NodeMovedEvent>().having((e) => e.to, 'to', 0));
      expect(changes[3],
          isA<NodeRemovedEvent>().having((e) => e.nodeId, 'nodeId', 'c'));
    });

    test('keeps the selection untouched unless asked to update it', () {
      editor.execute([
        ApplyDocumentPatchRequest(operations: [
          ReplaceNodePatch(
              'a', ParagraphNode(id: 'a', text: AttributedText('Hey there'))),
        ]),
      ]);

      expect(composer.selection!.extent.nodeId, 'b');
      expect(
          (composer.selection!.extent.nodePosition as TextNodePosition).offset,
          2);
    });

    test('sets the transformed selection and composing region', () {
      const newSelection = DocumentSelection.collapsed(
        position: DocumentPosition(
            nodeId: 'b', nodePosition: TextNodePosition(offset: 5)),
      );
      editor.execute([
        ApplyDocumentPatchRequest(
          operations: [
            ReplaceNodePatch(
                'b', ParagraphNode(id: 'b', text: AttributedText('abcWorld'))),
          ],
          updateSelection: true,
          selectionAfter: newSelection,
          updateComposingRegion: true,
          composingRegionAfter: null,
        ),
      ]);

      expect(composer.selection, newSelection);
      expect(composer.latestSelectionChange!.reason,
          SelectionReason.contentChange);
      expect(composer.composingRegion.value, isNull);
    });

    test('is not recorded in the editor history', () {
      editor.execute([
        ApplyDocumentPatchRequest(operations: [
          ReplaceNodePatch(
              'a', ParagraphNode(id: 'a', text: AttributedText('Changed'))),
        ]),
      ]);

      expect(editor.history, isEmpty);
    });

    test('re-notifies selection listeners for an IME resync', () {
      var notifications = 0;
      composer.selectionNotifier.addListener(() => notifications += 1);

      editor.execute([
        ApplyDocumentPatchRequest(
          operations: [
            ReplaceNodePatch(
                'b', ParagraphNode(id: 'b', text: AttributedText('World!')))
          ],
          resyncIme: true,
        ),
      ]);

      expect(notifications, 1);
    });

    test('does not run reactions unless asked to', () {
      var reactions = 0;
      final reactingEditor = Editor(
        editables: {Editor.documentKey: document, Editor.composerKey: composer},
        requestHandlers: List.from(defaultRequestHandlers),
        reactionPipeline: [
          FunctionalEditReaction(react: (_, __, ___) => reactions += 1)
        ],
      );

      reactingEditor.execute([
        ApplyDocumentPatchRequest(operations: [
          ReplaceNodePatch(
              'a', ParagraphNode(id: 'a', text: AttributedText('x')))
        ]),
      ]);
      expect(reactions, 0);

      reactingEditor.execute([
        ApplyDocumentPatchRequest(
          operations: [
            ReplaceNodePatch(
                'a', ParagraphNode(id: 'a', text: AttributedText('y')))
          ],
          runReactions: true,
        ),
      ]);
      expect(reactions, 1);
    });
  });
}
