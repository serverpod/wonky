import 'package:super_editor/super_editor.dart';

import '../mapping/wonky_schema.dart';
import '../model/code_languages.dart';
import '../model/embeds.dart';
import '../reactions/mention_atomicity_reaction.dart';

/// Request handlers implementing Wonky's Enter / Backspace / Delete semantics
/// per block type (Write 04 §6, §15.2–15.3, §19.3). They intercept the
/// generic requests, so keyboard, IME and macOS selector paths behave alike.
List<EditRequestHandler> blockEditingHandlers({
  required String Function() newEmbedId,
  required bool Function() markdownShortcuts,
}) {
  return [
    (editor, request) {
      if (request is! InsertNewlineAtCaretRequest) return null;
      return _newlineCommand(
        editor,
        request.newNodeId,
        newEmbedId,
        markdownShortcuts(),
      );
    },
    (editor, request) {
      if (request is! InsertSoftNewlineAtCaretRequest) return null;
      final selection = editor.composer.selection;
      if (selection == null || !selection.isCollapsed) return null;
      final node = editor.document.getNodeById(selection.extent.nodeId);
      if (isCodeBlockNode(node)) {
        return _CodeNewlineCommand(
          node!.id,
          (selection.extent.nodePosition as TextNodePosition).offset,
        );
      }
      if (node is BlockNode) {
        return _ParagraphBesideEmbedCommand(
          node.id,
          before: true,
          newNodeId: Editor.createNodeId(),
        );
      }
      return null;
    },
    (editor, request) {
      if (request is DeleteUpstreamRequest) {
        return _backspaceCommand(editor);
      }
      if (request is DeleteUpstreamAtBeginningOfNodeRequest &&
          request.node is TextNode) {
        return _backspaceAtStartCommand(editor, request.node as TextNode);
      }
      return null;
    },
    (editor, request) {
      if (request is! DeleteDownstreamRequest) return null;
      return _deleteCommand(editor);
    },
  ];
}

EditCommand? _newlineCommand(
  Editor editor,
  String newNodeId,
  String Function() newEmbedId,
  bool markdown,
) {
  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final document = editor.document;
  final node = document.getNodeById(selection.extent.nodeId);
  final position = selection.extent.nodePosition;

  if (node is BlockNode) {
    return _ParagraphBesideEmbedCommand(
      node.id,
      before: false,
      newNodeId: newNodeId,
    );
  }
  if (node is! TextNode || position is! TextNodePosition) return null;
  final offset = position.offset;
  final text = node.text.toPlainText();

  if (isCodeBlockNode(node)) {
    if (offset == text.length && text.endsWith('\n\n')) {
      return _ExitCodeBlockCommand(node.id, newNodeId);
    }
    return _CodeNewlineCommand(node.id, offset);
  }

  if (node is ParagraphNode) {
    final blockType = node.getMetadataValue(NodeMetadata.blockType);
    if (blockType == paragraphAttribution &&
        markdown &&
        offset == text.length) {
      final fence = RegExp(r'^```([\w+#.\-]*)$').firstMatch(text);
      if (fence != null) {
        return _ConvertToCodeBlockCommand(
          node.id,
          CodeLanguages.normalize(fence.group(1) ?? ''),
        );
      }
      if (RegExp(r'^(---|—-|\*\*\*|___)$').hasMatch(text)) {
        return _ConvertToDividerCommand(node.id, newEmbedId());
      }
    }
    if (blockType == blockquoteAttribution) {
      if (text.isEmpty) {
        return _ChangeBlockTypeWrapper(node.id, paragraphAttribution);
      }
      return _SplitKeepingTypeCommand(node.id, offset, newNodeId);
    }
    if (headingLevelOf(blockType) != null && offset == 0 && text.isNotEmpty) {
      return _ParagraphAboveCommand(node.id, newNodeId);
    }
    return null;
  }

  // A list or task item inside a quote: new items stay in the quote; Enter
  // on an empty top-level item leaves the list but not the quote (§14).
  if (isQuotedListNode(node)) {
    final indent = _indentOf(node);
    if (text.isEmpty) {
      return indent > 0
          ? _SetIndentCommand(node.id, indent - 1)
          : _ToParagraphCommand(node.id, quote: true);
    }
    return _SplitQuotedItemCommand(node.id, offset, newNodeId);
  }
  if (node is ListItemNode && text.isEmpty && node.indent > 0) {
    return _SetIndentCommand(node.id, node.indent - 1);
  }
  if (node is TaskNode && text.isEmpty) {
    return node.indent > 0
        ? _SetIndentCommand(node.id, node.indent - 1)
        : _ToParagraphCommand(node.id);
  }
  return null;
}

EditCommand? _backspaceCommand(Editor editor) {
  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final node = editor.document.getNodeById(selection.extent.nodeId);
  final position = selection.extent.nodePosition;
  if (node is! TextNode || position is! TextNodePosition) return null;
  final offset = position.offset;
  if (offset == 0) {
    return _backspaceAtStartCommand(editor, node);
  }
  // A mention is deleted as a whole.
  final mention = MentionAtomicityReaction.mentionAdjacentTo(
    node,
    offset,
    upstream: true,
  );
  if (mention != null && mention.end == offset - 1) {
    return _DeleteTextRangeCommand(node.id, mention.start, mention.end + 1);
  }
  // In code, Backspace in leading whitespace deletes back to the previous
  // indent stop.
  if (isCodeBlockNode(node)) {
    final text = node.text.toPlainText();
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;
    final leading = text.substring(lineStart, offset);
    if (leading.length >= 2 && leading.trim().isEmpty) {
      final remove = leading.length % 2 == 0 ? 2 : 1;
      return _DeleteTextRangeCommand(node.id, offset - remove, offset);
    }
  }
  return null;
}

EditCommand? _backspaceAtStartCommand(Editor editor, TextNode node) {
  final document = editor.document;
  if (isCodeBlockNode(node)) {
    return _CodeToParagraphsCommand(node.id);
  }
  if (node is ParagraphNode) {
    final blockType = node.getMetadataValue(NodeMetadata.blockType);
    if (blockType != paragraphAttribution) {
      return _ChangeBlockTypeWrapper(node.id, paragraphAttribution);
    }
    final previous = document.getNodeBefore(node);
    if (previous == null) {
      return const _NoOpCommand();
    }
    if (previous is BlockNode) {
      return _SelectEmbedCommand(
        previous.id,
        deleteNodeId: node.text.isEmpty ? node.id : null,
      );
    }
    // Merge into the previous text block; its type wins.
    return previous is TextNode
        ? _MergeTextNodesCommand(previous.id, node.id)
        : null;
  }
  if (node is ListItemNode || node is TaskNode) {
    // Inside a quote, a top-level item becomes a quote line (§14).
    final indent = _indentOf(node);
    return indent > 0
        ? _SetIndentCommand(node.id, indent - 1)
        : _ToParagraphCommand(node.id, quote: isQuotedListNode(node));
  }
  return null;
}

int _indentOf(DocumentNode node) => switch (node) {
  ListItemNode(:final indent) || TaskNode(:final indent) => indent,
  _ => 0,
};

EditCommand? _deleteCommand(Editor editor) {
  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final document = editor.document;
  final node = document.getNodeById(selection.extent.nodeId);
  final position = selection.extent.nodePosition;
  if (node is! TextNode || position is! TextNodePosition) return null;
  final offset = position.offset;
  if (offset == node.text.length) {
    final next = document.getNodeAfter(node);
    if (next is BlockNode) {
      return _SelectEmbedCommand(next.id);
    }
    if (next is TextNode) {
      return _MergeTextNodesCommand(node.id, next.id);
    }
    return null;
  }
  final mention = MentionAtomicityReaction.mentionAdjacentTo(
    node,
    offset,
    upstream: false,
  );
  if (mention != null && mention.start == offset) {
    return _DeleteTextRangeCommand(node.id, mention.start, mention.end + 1);
  }
  return null;
}

void _placeCaret(
  CommandExecutor executor,
  String nodeId,
  NodePosition position,
) {
  executor.executeCommand(
    ChangeSelectionCommand(
      DocumentSelection.collapsed(
        position: DocumentPosition(nodeId: nodeId, nodePosition: position),
      ),
      SelectionChangeType.placeCaret,
      SelectionReason.userInteraction,
    ),
  );
}

class _NoOpCommand extends EditCommand {
  const _NoOpCommand();

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.nonHistorical;

  @override
  void execute(EditContext context, CommandExecutor executor) {}
}

/// Enter / Shift+Enter in code: `\n` plus the line's leading whitespace (and
/// one more indent unit after `{ ( [ :`).
class _CodeNewlineCommand extends EditCommand {
  _CodeNewlineCommand(this.nodeId, this.offset);

  final String nodeId;
  final int offset;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as TextNode;
    final text = node.text.toPlainText();
    final lineStart = offset == 0 ? 0 : text.lastIndexOf('\n', offset - 1) + 1;
    final line = text.substring(lineStart, offset);
    final indent = RegExp(r'^[ \t]*').firstMatch(line)!.group(0)!;
    final extra = RegExp(r'[{(\[:]\s*$').hasMatch(line) ? '  ' : '';
    final insertion = '\n$indent$extra';
    executor.executeCommand(
      InsertTextCommand(
        documentPosition: DocumentPosition(
          nodeId: nodeId,
          nodePosition: TextNodePosition(offset: offset),
        ),
        textToInsert: insertion,
        attributions: const {},
      ),
    );
    _placeCaret(
      executor,
      nodeId,
      TextNodePosition(offset: offset + insertion.length),
    );
  }
}

/// Triple Enter at the end of a code block: drop the two empty lines and
/// continue in a Normal paragraph below (§15.3).
class _ExitCodeBlockCommand extends EditCommand {
  _ExitCodeBlockCommand(this.nodeId, this.newNodeId);

  final String nodeId;
  final String newNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as TextNode;
    final length = node.text.length;
    executor
      ..executeCommand(
        DeleteContentCommand(
          documentRange: DocumentRange(
            start: DocumentPosition(
              nodeId: nodeId,
              nodePosition: TextNodePosition(offset: length - 2),
            ),
            end: DocumentPosition(
              nodeId: nodeId,
              nodePosition: TextNodePosition(offset: length),
            ),
          ),
        ),
      )
      ..executeCommand(
        InsertNodeAfterNodeCommand(
          existingNodeId: nodeId,
          newNode: ParagraphNode(id: newNodeId, text: AttributedText('')),
        ),
      );
    _placeCaret(executor, newNodeId, const TextNodePosition(offset: 0));
  }
}

class _ConvertToCodeBlockCommand extends EditCommand {
  _ConvertToCodeBlockCommand(this.nodeId, this.language);

  final String nodeId;
  final String language;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as ParagraphNode;
    executor.executeCommand(
      ReplaceNodeCommand(
        existingNodeId: nodeId,
        newNode: ParagraphNode(
          id: nodeId,
          text: AttributedText(''),
          metadata: {
            ...node.metadata,
            NodeMetadata.blockType: codeAttribution,
            WonkyNodeMetadata.codeLanguage: language,
          },
        ),
      ),
    );
    _placeCaret(executor, nodeId, const TextNodePosition(offset: 0));
  }
}

class _ConvertToDividerCommand extends EditCommand {
  _ConvertToDividerCommand(this.nodeId, this.dividerId);

  final String nodeId;
  final String dividerId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as ParagraphNode;
    executor
      ..executeCommand(
        ReplaceNodeCommand(
          existingNodeId: nodeId,
          newNode: node.copyParagraphWith(text: AttributedText('')),
        ),
      )
      ..executeCommand(
        InsertNodeBeforeNodeCommand(
          existingNodeId: nodeId,
          newNode: EmbedNodes.divider(dividerId),
        ),
      );
    _placeCaret(executor, nodeId, const TextNodePosition(offset: 0));
  }
}

class _ChangeBlockTypeWrapper extends EditCommand {
  _ChangeBlockTypeWrapper(this.nodeId, this.blockType);

  final String nodeId;
  final Attribution blockType;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    executor.executeCommand(
      ChangeParagraphBlockTypeCommand(nodeId: nodeId, blockType: blockType),
    );
  }
}

/// Splits a paragraph keeping its block type for the new node (quote lines).
class _SplitKeepingTypeCommand extends EditCommand {
  _SplitKeepingTypeCommand(this.nodeId, this.offset, this.newNodeId);

  final String nodeId;
  final int offset;
  final String newNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as ParagraphNode;
    final first = node.copyParagraphWith(text: node.text.copyText(0, offset));
    final second = ParagraphNode(
      id: newNodeId,
      text: node.text.copyText(offset),
      metadata: {
        NodeMetadata.blockType: node.getMetadataValue(NodeMetadata.blockType),
      },
    );
    executor
      ..executeCommand(
        ReplaceNodeCommand(existingNodeId: nodeId, newNode: first),
      )
      ..executeCommand(
        InsertNodeAfterNodeCommand(existingNodeId: nodeId, newNode: second),
      );
    _placeCaret(executor, newNodeId, const TextNodePosition(offset: 0));
  }
}

/// Splits a list or task item inside a quote: the new item has the same type
/// and indent and stays in the quote (a new task is unchecked).
class _SplitQuotedItemCommand extends EditCommand {
  _SplitQuotedItemCommand(this.nodeId, this.offset, this.newNodeId);

  final String nodeId;
  final int offset;
  final String newNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId)! as TextNode;
    final rest = node.text.copyText(offset);
    final metadata = {WonkyNodeMetadata.quoted: true};
    final (TextNode first, TextNode second) = switch (node) {
      ListItemNode() => (
        node.copyListItemWith(text: node.text.copyText(0, offset)),
        ListItemNode(
          id: newNodeId,
          itemType: node.type,
          indent: node.indent,
          text: rest,
          metadata: metadata,
        ),
      ),
      TaskNode() => (
        node.copyTaskWith(text: node.text.copyText(0, offset)),
        TaskNode(
          id: newNodeId,
          text: rest,
          isComplete: false,
          indent: node.indent,
          metadata: metadata,
        ),
      ),
      _ => throw StateError('Not a list item: $nodeId'),
    };
    executor
      ..executeCommand(
        ReplaceNodeCommand(existingNodeId: nodeId, newNode: first),
      )
      ..executeCommand(
        InsertNodeAfterNodeCommand(existingNodeId: nodeId, newNode: second),
      );
    _placeCaret(executor, newNodeId, const TextNodePosition(offset: 0));
  }
}

/// Enter at the start of a non-empty heading: an empty Normal paragraph above.
class _ParagraphAboveCommand extends EditCommand {
  _ParagraphAboveCommand(this.nodeId, this.newNodeId);

  final String nodeId;
  final String newNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    executor.executeCommand(
      InsertNodeBeforeNodeCommand(
        existingNodeId: nodeId,
        newNode: ParagraphNode(id: newNodeId, text: AttributedText('')),
      ),
    );
    _placeCaret(executor, nodeId, const TextNodePosition(offset: 0));
  }
}

/// Enter (after) / Shift+Enter (before) on a selected embed (§6.1).
class _ParagraphBesideEmbedCommand extends EditCommand {
  _ParagraphBesideEmbedCommand(
    this.nodeId, {
    required this.before,
    required this.newNodeId,
  });

  final String nodeId;
  final bool before;
  final String newNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final paragraph = ParagraphNode(id: newNodeId, text: AttributedText(''));
    executor.executeCommand(
      before
          ? InsertNodeBeforeNodeCommand(
              existingNodeId: nodeId,
              newNode: paragraph,
            )
          : InsertNodeAfterNodeCommand(
              existingNodeId: nodeId,
              newNode: paragraph,
            ),
    );
    _placeCaret(executor, newNodeId, const TextNodePosition(offset: 0));
  }
}

class _SetIndentCommand extends EditCommand {
  _SetIndentCommand(this.nodeId, this.indent);

  final String nodeId;
  final int indent;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node is ListItemNode) {
      executor.executeCommand(
        ReplaceNodeCommand(
          existingNodeId: nodeId,
          newNode: node.copyListItemWith(indent: indent),
        ),
      );
    } else if (node is TaskNode) {
      executor.executeCommand(SetTaskIndentCommand(nodeId, indent));
    }
  }
}

/// Converts a list item or task to a Normal paragraph, or with [quote] to a
/// quote line (keeps line overlays).
class _ToParagraphCommand extends EditCommand {
  _ToParagraphCommand(this.nodeId, {this.quote = false});

  final String nodeId;
  final bool quote;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as TextNode;
    final lineAttributes = node.getMetadataValue(
      WonkyNodeMetadata.lineAttributes,
    );
    executor.executeCommand(
      ReplaceNodeCommand(
        existingNodeId: nodeId,
        newNode: ParagraphNode(
          id: nodeId,
          text: node.text,
          metadata: {
            WonkyNodeMetadata.lineAttributes: ?lineAttributes,
            if (quote) NodeMetadata.blockType: blockquoteAttribution,
          },
        ),
      ),
    );
    _placeCaret(executor, nodeId, const TextNodePosition(offset: 0));
  }
}

/// Backspace at the start of a code block: every line becomes a Normal
/// paragraph (one undo step).
class _CodeToParagraphsCommand extends EditCommand {
  _CodeToParagraphsCommand(this.nodeId);

  final String nodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId) as TextNode;
    final text = node.text.toPlainText();
    final paragraphs = <ParagraphNode>[];
    var start = 0;
    while (true) {
      final end = text.indexOf('\n', start);
      final lineEnd = end < 0 ? text.length : end;
      paragraphs.add(
        ParagraphNode(
          id: paragraphs.isEmpty ? nodeId : Editor.createNodeId(),
          text: node.text.copyText(start, lineEnd),
        ),
      );
      if (end < 0) break;
      start = end + 1;
    }
    executor.executeCommand(
      ReplaceNodeCommand(existingNodeId: nodeId, newNode: paragraphs.first),
    );
    var previous = nodeId;
    for (final paragraph in paragraphs.skip(1)) {
      executor.executeCommand(
        InsertNodeAfterNodeCommand(
          existingNodeId: previous,
          newNode: paragraph,
        ),
      );
      previous = paragraph.id;
    }
    _placeCaret(executor, nodeId, const TextNodePosition(offset: 0));
  }
}

/// Selects an embed (block selection); optionally deletes an empty paragraph.
class _SelectEmbedCommand extends EditCommand {
  _SelectEmbedCommand(this.embedId, {this.deleteNodeId});

  final String embedId;
  final String? deleteNodeId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    if (deleteNodeId != null) {
      executor.executeCommand(DeleteNodeCommand(nodeId: deleteNodeId!));
    }
    executor.executeCommand(
      ChangeSelectionCommand(
        DocumentSelection(
          base: DocumentPosition(
            nodeId: embedId,
            nodePosition: const UpstreamDownstreamNodePosition.upstream(),
          ),
          extent: DocumentPosition(
            nodeId: embedId,
            nodePosition: const UpstreamDownstreamNodePosition.downstream(),
          ),
        ),
        SelectionChangeType.expandSelection,
        SelectionReason.userInteraction,
      ),
    );
  }
}

class _DeleteTextRangeCommand extends EditCommand {
  _DeleteTextRangeCommand(this.nodeId, this.start, this.end);

  final String nodeId;
  final int start;
  final int end;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    executor.executeCommand(
      DeleteContentCommand(
        documentRange: DocumentRange(
          start: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: start),
          ),
          end: DocumentPosition(
            nodeId: nodeId,
            nodePosition: TextNodePosition(offset: end),
          ),
        ),
      ),
    );
    _placeCaret(executor, nodeId, TextNodePosition(offset: start));
  }
}

/// Appends the text of [secondId] to [firstId] (whose type wins) and deletes
/// [secondId]; the caret goes to the join point.
class _MergeTextNodesCommand extends EditCommand {
  _MergeTextNodesCommand(this.firstId, this.secondId);

  final String firstId;
  final String secondId;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    final first = document.getNodeById(firstId) as TextNode;
    final second = document.getNodeById(secondId) as TextNode;
    final joinOffset = first.text.length;
    var appended = second.text;
    if (isCodeBlockNode(first) != isCodeBlockNode(second)) {
      // Code text has no inline formatting; soft breaks become lines.
      appended = isCodeBlockNode(first)
          ? AttributedText(second.text.toPlainText())
          : second.text;
    }
    executor
      ..executeCommand(
        ReplaceNodeCommand(
          existingNodeId: firstId,
          newNode: first.copyTextNodeWith(
            text: first.text.copyAndAppend(appended),
          ),
        ),
      )
      ..executeCommand(DeleteNodeCommand(nodeId: secondId));
    _placeCaret(executor, firstId, TextNodePosition(offset: joinOffset));
  }
}
