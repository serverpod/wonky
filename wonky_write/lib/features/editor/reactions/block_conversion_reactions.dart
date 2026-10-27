import 'package:super_editor/super_editor.dart';

import '../components/box_frames.dart' show isDetailsSummaryNode;
import '../mapping/wonky_schema.dart';
import '../model/code_languages.dart';
import '../model/embeds.dart';
import 'reaction_wrappers.dart';
import 'wonky_shortcuts.dart';

/// Markdown block prefixes typed at the start of a block (Write 04 §7.1):
/// `# `…`###### `, `- ` `* ` `+ `, `1. ` `1) `, `> `, `[ ] ` `[x] ` `- [ ] `,
/// ```` ```lang ```` + space, `---` `***` `___` + space.
///
/// The prefix must be exactly the text before the caret, and the caret must be
/// right after the space that was just typed. Never applies in code blocks.
class BlockPrefixConversionReaction extends EditReaction {
  BlockPrefixConversionReaction({required this.newEmbedId, this.isWonky});

  /// Creates ids for new embeds (UUIDv7).
  final String Function() newEmbedId;

  /// Whether the document is in Wonky Markdown: `:::type ` and `(n) `
  /// shortcuts (Write 11 §7.4).
  final bool Function()? isWonky;

  /// Called with the id of a grid the `:::grid ` shortcut inserted.

  static final _step = RegExp(r'^\((\d{1,4})\) $');

  static final _heading = RegExp(r'^(#{1,6}) $');
  static final _bullet = RegExp(r'^[-*+] $');
  static final _ordered = RegExp(r'^\d{1,9}[.)] $');
  static final _quote = RegExp(r'^> $');
  static final _task = RegExp(r'^(- )?\[( |x|X)?\] $');
  static final _codeFence = RegExp(r'^```([\w+#.\-]*) $');
  static final _divider = RegExp(r'^(---|—-|\*\*\*|___) $');

  @override
  void react(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final insertion = TypedText.lastInsertion(changeList);
    if (insertion == null || !insertion.text.toPlainText().endsWith(' ')) {
      return;
    }
    final document = editorContext.document;
    final composer = editorContext.composer;
    final selection = composer.selection;
    if (selection == null ||
        !selection.isCollapsed ||
        selection.extent.nodeId != insertion.nodeId) {
      return;
    }
    final node = document.getNodeById(insertion.nodeId);
    final caret = selection.extent.nodePosition;
    if (node is! TextNode ||
        caret is! TextNodePosition ||
        isCodeBlockNode(node)) {
      return;
    }
    final prefix = node.text.toPlainText().substring(0, caret.offset);
    final isParagraph =
        node is ParagraphNode &&
        node.getMetadataValue(NodeMetadata.blockType) == paragraphAttribution;
    final isQuote =
        node is ParagraphNode &&
        node.getMetadataValue(NodeMetadata.blockType) == blockquoteAttribution;

    final requests = <EditRequest>[];
    String? insertedGrid;
    final rest = node.text.copyText(prefix.length);
    var deletePrefix = true;
    Match? match;
    if ((match = _heading.firstMatch(prefix)) != null &&
        (isParagraph || node is ListItemNode || node is TaskNode)) {
      final level = match!.group(1)!.length;
      if (node is ParagraphNode) {
        requests.add(
          ChangeParagraphBlockTypeRequest(
            nodeId: node.id,
            blockType: headerAttributions[level - 1],
          ),
        );
      } else {
        deletePrefix = false;
        requests.add(
          ReplaceNodeRequest(
            existingNodeId: node.id,
            newNode: ParagraphNode(
              id: node.id,
              text: rest,
              metadata: {
                ..._carriedMetadata(node),
                NodeMetadata.blockType: headerAttributions[level - 1],
              },
            ),
          ),
        );
      }
    } else if ((_bullet.hasMatch(prefix) || _ordered.hasMatch(prefix)) &&
        (isParagraph || isQuote)) {
      final type = _bullet.hasMatch(prefix)
          ? ListItemType.unordered
          : ListItemType.ordered;
      if (isParagraph) {
        requests.add(
          ConvertParagraphToListItemRequest(nodeId: node.id, type: type),
        );
      } else {
        // In a quote line: a list item inside the quote (§14).
        deletePrefix = false;
        requests.add(
          ReplaceNodeRequest(
            existingNodeId: node.id,
            newNode: ListItemNode(
              id: node.id,
              itemType: type,
              text: rest,
              metadata: _carriedListMetadata(node),
            ),
          ),
        );
      }
    } else if (_quote.hasMatch(prefix) && isParagraph) {
      requests.add(
        ChangeParagraphBlockTypeRequest(
          nodeId: node.id,
          blockType: blockquoteAttribution,
        ),
      );
    } else if (_quote.hasMatch(prefix) &&
        (node is ListItemNode || node is TaskNode) &&
        !isQuotedListNode(node)) {
      // `> ` at the start of a list item: the item moves into a quote.
      requests.add(
        ChangeNodeMetadataRequest(
          nodeId: node.id,
          metadata: {WonkyNodeMetadata.quoted: true},
        ),
      );
    } else if ((match = _task.firstMatch(prefix)) != null &&
        (isParagraph || isQuote || node is ListItemNode)) {
      final checked = (match!.group(2) ?? ' ').toLowerCase() == 'x';
      deletePrefix = false;
      requests.add(
        ReplaceNodeRequest(
          existingNodeId: node.id,
          newNode: TaskNode(
            id: node.id,
            text: rest,
            isComplete: checked,
            indent: node is ListItemNode ? node.indent : 0,
            metadata: _carriedListMetadata(node),
          ),
        ),
      );
    } else if ((match = _codeFence.firstMatch(prefix)) != null && isParagraph) {
      requests
        ..add(
          ChangeParagraphBlockTypeRequest(
            nodeId: node.id,
            blockType: codeAttribution,
          ),
        )
        ..add(
          ChangeNodeMetadataRequest(
            nodeId: node.id,
            metadata: {
              WonkyNodeMetadata.codeLanguage: CodeLanguages.normalize(
                match!.group(1) ?? '',
              ),
            },
          ),
        );
    } else if ((isWonky?.call() ?? false) &&
        isParagraph &&
        WonkyShortcuts.block(prefix.substring(0, prefix.length - 1)) != null &&
        boxOf(node).length < 3) {
      // `:::warning ` … a container or grid (Write 11 §7.4).
      final shortcut = WonkyShortcuts.block(
        prefix.substring(0, prefix.length - 1),
      )!;
      requests.addAll(
        WonkyShortcuts.requestsFor(shortcut, node, document, newEmbedId),
      );
      if (shortcut.grid) {
        final grid = requests.whereType<InsertNodeAtIndexRequest>().first;
        insertedGrid = grid.newNode.id;
      }
    } else if ((match = _step.firstMatch(prefix)) != null &&
        (isWonky?.call() ?? false) &&
        node is ParagraphNode &&
        const [2, 3].contains(
          headingLevelOf(node.getMetadataValue(NodeMetadata.blockType)),
        ) &&
        stepOf(node) == null &&
        !(boxOf(node).isNotEmpty &&
            isDetailsSummaryNode(document, node, boxOf(node).length - 1))) {
      // `(1) ` at the start of an H2/H3: a numbered heading.
      requests.add(
        ChangeNodeMetadataRequest(
          nodeId: node.id,
          metadata: {WonkyNodeMetadata.step: int.parse(match!.group(1)!)},
        ),
      );
    } else if (_divider.hasMatch(prefix) &&
        isParagraph &&
        node.text.length == prefix.length) {
      requests.add(
        InsertNodeAtIndexRequest(
          nodeIndex: document.getNodeIndexById(node.id),
          newNode: EmbedNodes.divider(newEmbedId()),
        ),
      );
    } else {
      return;
    }

    final prefixRange = DocumentRange(
      start: DocumentPosition(
        nodeId: node.id,
        nodePosition: const TextNodePosition(offset: 0),
      ),
      end: DocumentPosition(
        nodeId: node.id,
        nodePosition: TextNodePosition(offset: prefix.length),
      ),
    );
    requestDispatcher.execute([
      if (deletePrefix) DeleteContentRequest(documentRange: prefixRange),
      ...requests,
      ChangeSelectionRequest(
        DocumentSelection.collapsed(
          position: DocumentPosition(
            // A new grid gets the caret in its first item (Write 11 §7.5).
            nodeId: insertedGrid ?? node.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
        ),
        SelectionChangeType.placeCaret,
        SelectionReason.contentChange,
      ),
    ]);
  }

  /// Metadata that survives a node type conversion (line-end overlays).
  static Map<String, dynamic> _carriedMetadata(DocumentNode node) {
    final lineAttributes = node.getMetadataValue(
      WonkyNodeMetadata.lineAttributes,
    );
    return {WonkyNodeMetadata.lineAttributes: ?lineAttributes};
  }

  /// [_carriedMetadata] of a node becoming a list or task item; it stays in
  /// the quote the node is in.
  static Map<String, dynamic> _carriedListMetadata(DocumentNode node) => {
    ..._carriedMetadata(node),
    if (isInQuoteNode(node)) WonkyNodeMetadata.quoted: true,
  };
}
