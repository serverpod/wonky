import 'package:super_editor/super_editor.dart';

import 'slides_delta_mapper.dart';

/// Enter at the end of a paragraph keeps its paragraph formatting (theme
/// text style, alignment, spacing, direction — 02 §4.1 block attributes),
/// like Google Slides and PowerPoint: super_editor starts a plain
/// paragraph there, so an empty node inserted without Slides block
/// attributes takes those of the node before it.
class SlidesParagraphInheritReaction extends EditReaction {
  const SlidesParagraphInheritReaction();

  @override
  void modifyContent(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final document = editorContext.document;
    final requests = <EditRequest>[];
    for (final e in changeList) {
      if (e is! DocumentEdit) continue;
      final change = e.change;
      if (change is! NodeInsertedEvent) continue;
      final node = document.getNodeById(change.nodeId);
      if (node is! TextNode || node.text.isNotEmpty) continue;
      if (node.getMetadataValue(slidesBlockMetadataKey) != null) continue;
      final before = document.getNodeBefore(node);
      final inherited = before?.getMetadataValue(slidesBlockMetadataKey);
      if (inherited is! Map || inherited.isEmpty) continue;
      requests.add(
        ChangeNodeMetadataRequest(
          nodeId: node.id,
          metadata: {
            slidesBlockMetadataKey: Map<String, Object?>.of(
              inherited.cast<String, Object?>(),
            ),
          },
        ),
      );
    }
    if (requests.isNotEmpty) requestDispatcher.execute(requests);
  }
}

/// The editor of a Slides text body: super_editor's default request
/// handlers and reactions plus the Slides reactions. No editor-side
/// history (undo is the shell's `slides.rows` stack, 03 §15).
Editor createSlidesTextEditor({
  required MutableDocument document,
  required MutableDocumentComposer composer,
}) => Editor(
  editables: {Editor.documentKey: document, Editor.composerKey: composer},
  requestHandlers: List.from(defaultRequestHandlers),
  reactionPipeline: [
    // super_editor builds the list with an untyped List.unmodifiable.
    ...defaultEditorReactions.cast<EditReaction>(),
    const SlidesParagraphInheritReaction(),
  ],
);
