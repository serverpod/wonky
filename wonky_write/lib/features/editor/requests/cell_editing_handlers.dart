import 'package:flutter/services.dart' show TextPosition;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellAttr, CellIds, GridEmbed;

import '../mapping/wonky_schema.dart';

/// Request handlers for Enter, Shift+Enter, Backspace, Delete and deleting
/// selections in table cells and grid items (Write 12 §3.4). They run
/// before [blockEditingHandlers], so keyboard, IME and macOS selector paths
/// behave alike, and they never merge or split cells: the table keeps its
/// shape.
List<EditRequestHandler> cellEditingHandlers() => [
  (editor, request) {
    if (request is! AppendCellRequest) return null;
    final group = CellGroupNodes.of(
      editor.document,
      editor.document.getNodeById(request.nodeId),
    );
    if (group == null) return null;
    return group.isTable
        ? _AppendRowCommand(group, caretColumn: 0)
        : _AppendItemCommand(group);
  },
  (editor, request) {
    if (request is! InsertNewlineAtCaretRequest) return null;
    return _newline(_ctxOf(editor), request.newNodeId);
  },
  (editor, request) {
    if (request is! InsertSoftNewlineAtCaretRequest) return null;
    return _softNewline(_ctxOf(editor));
  },
  (editor, request) {
    if (request is DeleteUpstreamRequest ||
        request is DeleteUpstreamAtBeginningOfNodeRequest) {
      return _backspace(_ctxOf(editor));
    }
    return null;
  },
  (editor, request) {
    if (request is! DeleteDownstreamRequest) return null;
    return _delete(_ctxOf(editor));
  },
  (editor, request) {
    final DocumentRange? range = switch (request) {
      DeleteSelectionRequest() => editor.composer.selection,
      DeleteContentRequest(:final documentRange) => documentRange,
      _ => null,
    };
    if (range == null || range.isCollapsed) return null;
    return _deleteRange(editor.document, range);
  },
];

/// The document and composer the key handlers read.
typedef _Ctx = ({Document document, DocumentComposer composer});

_Ctx _ctxOf(Editor editor) =>
    (document: editor.document, composer: editor.composer);

/// Appends a row to the table, or an item to the grid, of cell or item node
/// [nodeId] and puts the caret in its first cell (Tab in the last cell,
/// Write 12 §3.4).
class AppendCellRequest implements EditRequest {
  const AppendCellRequest(this.nodeId);

  final String nodeId;
}

// -----------------------------------------------------------------------------
// The table or grid of a node in the super_editor document.

/// The nodes of the table or grid that contains a cell or item node.
class CellGroupNodes {
  CellGroupNodes._(this.nodes, this.rows);

  /// Every node of the group, in document order.
  final List<DocumentNode> nodes;

  /// A table's rows (each a list of its cell nodes); a grid's items as one
  /// row.
  final List<List<DocumentNode>> rows;

  bool get isTable => cellOf(nodes.first) != null;

  /// The (row, column) of [nodeId].
  (int, int)? positionOf(String nodeId) {
    for (var r = 0; r < rows.length; r++) {
      final c = rows[r].indexWhere((n) => n.id == nodeId);
      if (c >= 0) return (r, c);
    }
    return null;
  }

  /// The group of [node], or `null` when it is not a cell or item.
  static CellGroupNodes? of(Document document, DocumentNode? node) {
    if (node == null) return null;
    final key = _keyOf(node);
    if (key == null) return null;
    final nodes = <DocumentNode>[node];
    var before = document.getNodeBeforeById(node.id);
    while (before != null && _keyOf(before) == key) {
      nodes.insert(0, before);
      before = document.getNodeBeforeById(before.id);
    }
    var after = document.getNodeAfterById(node.id);
    while (after != null && _keyOf(after) == key) {
      nodes.add(after);
      after = document.getNodeAfterById(after.id);
    }
    final rows = <List<DocumentNode>>[];
    if (cellOf(node) == null) {
      rows.add(nodes);
    } else {
      String? row;
      for (final n in nodes) {
        final r = cellOf(n)!.row;
        if (r != row) rows.add([]);
        rows.last.add(n);
        row = r;
      }
    }
    return CellGroupNodes._(nodes, rows);
  }

  static String? _keyOf(DocumentNode node) {
    final cell = cellOf(node);
    if (cell != null) return 't:${cell.table}';
    final item = gridItemOf(node);
    return item == null ? null : 'g:${item.id}';
  }
}

// -----------------------------------------------------------------------------
// Keys.

/// The text node and caret offset of a collapsed selection in a cell or item.
(TextNode, int, CellGroupNodes)? _caretInCell(_Ctx editor) {
  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final node = editor.document.getNodeById(selection.extent.nodeId);
  final position = selection.extent.nodePosition;
  if (node is! TextNode || position is! TextNodePosition) return null;
  final group = CellGroupNodes.of(editor.document, node);
  if (group == null) return null;
  return (node, position.offset, group);
}

EditCommand? _newline(_Ctx editor, String newNodeId) {
  final selection = editor.composer.selection;
  if (selection == null) return null;
  if (!selection.isCollapsed) {
    // Enter over a selection in one cell replaces it like typing; across
    // cells the deletion handler clears the cells first.
    final base = editor.document.getNodeById(selection.base.nodeId);
    if (!isCellNode(base) &&
        !isCellNode(editor.document.getNodeById(selection.extent.nodeId))) {
      return null;
    }
    return _CompoundCommand([
      DeleteContentCommand(documentRange: selection, updateSelection: true),
      _DeferredCommand((ctx) => _newline(ctx, newNodeId)),
    ]);
  }
  final caret = _caretInCell(editor);
  if (caret == null) return null;
  final (node, offset, group) = caret;
  if (group.isTable) {
    // The caret goes to the cell below; the last row gets a row after it.
    final (row, col) = group.positionOf(node.id)!;
    if (row + 1 < group.rows.length) {
      final below = group.rows[row + 1];
      final target = below[col < below.length ? col : below.length - 1];
      return _CaretCommand(target.id, const TextNodePosition(offset: 0));
    }
    return _AppendRowCommand(group, caretColumn: col);
  }
  // Grid: Enter on an empty last item leaves the grid; otherwise the text
  // after the caret moves into a new item (Write 12 §3.4).
  final items = group.nodes;
  if (node.text.isEmpty && identical(items.last, node) && items.length > 1) {
    return _LeaveGridCommand(node.id);
  }
  if (items.length >= GridEmbed.maxItems) return const _NoOpCommand();
  return _CompoundCommand([
    SplitParagraphCommand(
      nodeId: node.id,
      splitPosition: TextPosition(offset: offset),
      newNodeId: newNodeId,
      replicateExistingMetadata: true,
    ),
    _CaretCommand(newNodeId, const TextNodePosition(offset: 0)),
  ]);
}

EditCommand? _softNewline(_Ctx editor) {
  final caret = _caretInCell(editor);
  if (caret == null) return null;
  final (node, _, group) = caret;
  if (!group.isTable) return const _NoOpCommand();
  final (row, col) = group.positionOf(node.id)!;
  if (row == 0) return const _NoOpCommand();
  final above = group.rows[row - 1];
  final target = above[col < above.length ? col : above.length - 1];
  return _CaretCommand(
    target.id,
    TextNodePosition(offset: (target as TextNode).text.length),
  );
}

EditCommand? _backspace(_Ctx editor) {
  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final document = editor.document;
  final node = document.getNodeById(selection.extent.nodeId);
  final position = selection.extent.nodePosition;
  if (node is! TextNode ||
      position is! TextNodePosition ||
      position.offset != 0) {
    return null;
  }
  final previous = document.getNodeBeforeById(node.id);
  final group = CellGroupNodes.of(document, node);
  if (group == null) {
    // After a table or grid: an empty line is removed, a line with text
    // stays; the caret goes to the end of the last cell (no merge).
    if (previous is TextNode && isCellNode(previous)) {
      return _CompoundCommand([
        if (node.text.isEmpty) DeleteNodeCommand(nodeId: node.id),
        _CaretCommand(
          previous.id,
          TextNodePosition(offset: previous.text.length),
        ),
      ]);
    }
    return null;
  }
  final inGroup = previous != null && group.nodes.contains(previous);
  if (!group.isTable && node.text.isEmpty) {
    // An empty grid item is removed; the last one becomes a paragraph.
    if (group.nodes.length == 1) return _LeaveGridCommand(node.id);
    final target = inGroup ? previous : document.getNodeAfterById(node.id);
    return _CompoundCommand([
      DeleteNodeCommand(nodeId: node.id),
      if (target is TextNode)
        _CaretCommand(
          target.id,
          TextNodePosition(offset: inGroup ? target.text.length : 0),
        ),
    ]);
  }
  if (inGroup && previous is TextNode) {
    return _CaretCommand(
      previous.id,
      TextNodePosition(offset: previous.text.length),
    );
  }
  // At the start of a table or grid: nothing to merge with.
  return const _NoOpCommand();
}

EditCommand? _delete(_Ctx editor) {
  final selection = editor.composer.selection;
  if (selection == null || !selection.isCollapsed) return null;
  final document = editor.document;
  final node = document.getNodeById(selection.extent.nodeId);
  final position = selection.extent.nodePosition;
  if (node is! TextNode ||
      position is! TextNodePosition ||
      position.offset != node.text.length) {
    return null;
  }
  final next = document.getNodeAfterById(node.id);
  final group = CellGroupNodes.of(document, node);
  if (group == null) {
    // Before a table or grid: an empty line is removed; the caret goes to
    // the first cell (no merge).
    if (next is TextNode && isCellNode(next)) {
      return _CompoundCommand([
        if (node.text.isEmpty) DeleteNodeCommand(nodeId: node.id),
        _CaretCommand(next.id, const TextNodePosition(offset: 0)),
      ]);
    }
    return null;
  }
  final inGroup = next != null && group.nodes.contains(next);
  if (!inGroup || next is! TextNode) return const _NoOpCommand();
  if (!group.isTable && next.text.isEmpty) {
    return DeleteNodeCommand(nodeId: next.id);
  }
  return _CaretCommand(next.id, const TextNodePosition(offset: 0));
}

// -----------------------------------------------------------------------------
// Deleting selections.

/// Deleting [range] when it touches table cells or grid items: cells are
/// cleared, never merged or removed, unless their whole table or grid is in
/// the range; the lines outside lose their selected part (Write 12 §3.4).
/// `null` when super_editor's deletion is right (no cell involved, or one
/// node).
EditCommand? _deleteRange(Document document, DocumentRange range) {
  final normalized = range.normalize(document);
  final start = normalized.start;
  final end = normalized.end;
  if (start.nodeId == end.nodeId) return null;
  final nodes = document.getNodesInside(start, end);
  if (!nodes.any(isCellNode)) return null;

  int offsetOf(DocumentPosition p) => p.nodePosition is TextNodePosition
      ? (p.nodePosition as TextNodePosition).offset
      : 0;
  bool fullyCovered(DocumentNode node) {
    if (node.id == start.nodeId) {
      return offsetOf(start) == 0 &&
          (node.id != end.nodeId ||
              node is! TextNode ||
              offsetOf(end) >= node.text.length);
    }
    if (node.id == end.nodeId) {
      return node is! TextNode || offsetOf(end) >= node.text.length;
    }
    return true;
  }

  // Groups whose every node is fully in the range are deleted whole.
  final deletedGroups = <String>{};
  final seen = <String>{};
  for (final node in nodes) {
    final group = CellGroupNodes.of(document, node);
    if (group == null || !seen.add(group.nodes.first.id)) continue;
    if (group.nodes.every((n) => nodes.contains(n) && fullyCovered(n))) {
      deletedGroups.addAll(group.nodes.map((n) => n.id));
    }
  }
  final startIsCell = isCellNode(document.getNodeById(start.nodeId));
  final endIsCell = isCellNode(document.getNodeById(end.nodeId));
  final partialCells = nodes.any(
    (n) => isCellNode(n) && !deletedGroups.contains(n.id),
  );
  if (!partialCells && !startIsCell && !endIsCell) {
    // Whole tables between two ordinary lines: super_editor deletes them
    // and merges the two lines.
    return null;
  }
  return _ClearRangeCommand(
    nodeIds: [for (final n in nodes) n.id],
    start: start,
    end: end,
    deletedNodes: {
      ...deletedGroups,
      for (final n in nodes)
        if (!isCellNode(n) && n.id != start.nodeId && n.id != end.nodeId) n.id,
    },
  );
}

/// Clears the selected text in each node of a range and deletes
/// [deletedNodes]; the caret goes to the range start (or the first node
/// left after it).
class _ClearRangeCommand extends EditCommand {
  _ClearRangeCommand({
    required this.nodeIds,
    required this.start,
    required this.end,
    required this.deletedNodes,
  });

  final List<String> nodeIds;
  final DocumentPosition start;
  final DocumentPosition end;
  final Set<String> deletedNodes;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final document = context.document;
    String? caretNode;
    var caretOffset = 0;
    for (final id in nodeIds) {
      final node = document.getNodeById(id);
      if (node == null) continue;
      if (deletedNodes.contains(id)) continue;
      if (node is! TextNode) continue;
      final from = id == start.nodeId
          ? (start.nodePosition as TextNodePosition).offset
          : 0;
      final to = id == end.nodeId
          ? (end.nodePosition as TextNodePosition).offset
          : node.text.length;
      caretNode ??= id;
      if (caretNode == id) caretOffset = from;
      if (to > from) {
        executor.executeCommand(
          DeleteContentCommand(
            documentRange: DocumentRange(
              start: DocumentPosition(
                nodeId: id,
                nodePosition: TextNodePosition(offset: from),
              ),
              end: DocumentPosition(
                nodeId: id,
                nodePosition: TextNodePosition(offset: to),
              ),
            ),
          ),
        );
      }
    }
    // The node after the range keeps the caret when everything before it
    // goes; a document never ends up empty.
    String? fallback;
    if (caretNode == null) {
      final after = document.getNodeAfterById(nodeIds.last);
      if (after is TextNode && !deletedNodes.contains(after.id)) {
        fallback = after.id;
      } else {
        fallback = Editor.createNodeId();
        executor.executeCommand(
          InsertNodeAfterNodeCommand(
            existingNodeId: nodeIds.last,
            newNode: ParagraphNode(id: fallback, text: AttributedText()),
          ),
        );
      }
    }
    for (final id in nodeIds) {
      if (deletedNodes.contains(id) && document.getNodeById(id) != null) {
        executor.executeCommand(DeleteNodeCommand(nodeId: id));
      }
    }
    _placeCaret(
      executor,
      caretNode ?? fallback!,
      TextNodePosition(offset: caretNode == null ? 0 : caretOffset),
    );
  }
}

// -----------------------------------------------------------------------------
// Commands.

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

/// Moves the caret (no document change).
class _CaretCommand extends EditCommand {
  _CaretCommand(this.nodeId, this.position);

  final String nodeId;
  final NodePosition position;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.nonHistorical;

  @override
  void execute(EditContext context, CommandExecutor executor) =>
      _placeCaret(executor, nodeId, position);
}

class _NoOpCommand extends EditCommand {
  const _NoOpCommand();

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.nonHistorical;

  @override
  void execute(EditContext context, CommandExecutor executor) {}
}

/// Runs [commands] in order.
class _CompoundCommand extends EditCommand {
  _CompoundCommand(this.commands);

  final List<EditCommand> commands;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    for (final c in commands) {
      executor.executeCommand(c);
    }
  }
}

/// A command chosen when it runs (after the commands before it).
class _DeferredCommand extends EditCommand {
  _DeferredCommand(this.build);

  final EditCommand? Function(_Ctx ctx) build;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final command = build((
      document: context.document,
      composer: context.composer,
    ));
    if (command != null) executor.executeCommand(command);
  }
}

/// Appends an empty row to a table (its cells in the table's containers,
/// with the header's alignment) and puts the caret in [caretColumn].
class _AppendRowCommand extends EditCommand {
  _AppendRowCommand(this.group, {required this.caretColumn});

  final CellGroupNodes group;
  final int caretColumn;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final header = group.rows.first;
    final columns = group.rows.fold(0, (n, r) => r.length > n ? r.length : n);
    final first = cellOf(group.nodes.first)!;
    final rowId = CellIds.row();
    final box = group.nodes.first.getMetadataValue(WonkyNodeMetadata.box);
    var after = group.nodes.last.id;
    String? caret;
    for (var c = 0; c < columns; c++) {
      final id = Editor.createNodeId();
      final align = c < header.length ? cellOf(header[c])?.align : null;
      executor.executeCommand(
        InsertNodeAfterNodeCommand(
          existingNodeId: after,
          newNode: ParagraphNode(
            id: id,
            text: AttributedText(),
            metadata: {
              NodeMetadata.blockType: paragraphAttribution,
              WonkyNodeMetadata.cell: CellAttr(
                table: first.table,
                row: rowId,
                align: align,
              ).toJson(),
              if (box is List && box.isNotEmpty) WonkyNodeMetadata.box: box,
            },
          ),
        ),
      );
      if (c == caretColumn.clamp(0, columns - 1)) caret = id;
      after = id;
    }
    if (caret != null) {
      _placeCaret(executor, caret, const TextNodePosition(offset: 0));
    }
  }
}

/// Turns grid item [nodeId] into an ordinary paragraph (keeping its
/// containers).
class _LeaveGridCommand extends EditCommand {
  _LeaveGridCommand(this.nodeId);

  final String nodeId;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    final node = context.document.getNodeById(nodeId);
    if (node is! ParagraphNode) return;
    final metadata = {...node.metadata}..remove(WonkyNodeMetadata.gridItem);
    executor.executeCommand(
      ReplaceNodeCommand(
        existingNodeId: nodeId,
        newNode: ParagraphNode(id: nodeId, text: node.text, metadata: metadata),
      ),
    );
    _placeCaret(executor, nodeId, const TextNodePosition(offset: 0));
  }
}

/// Appends an empty item to a grid and puts the caret in it.
class _AppendItemCommand extends EditCommand {
  _AppendItemCommand(this.group);

  final CellGroupNodes group;

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.undoable;

  @override
  void execute(EditContext context, CommandExecutor executor) {
    if (group.nodes.length >= GridEmbed.maxItems) return;
    final last = group.nodes.last;
    final id = Editor.createNodeId();
    executor.executeCommand(
      InsertNodeAfterNodeCommand(
        existingNodeId: last.id,
        newNode: ParagraphNode(
          id: id,
          text: AttributedText(),
          metadata: {...last.metadata}
            ..remove(WonkyNodeMetadata.lineAttributes),
        ),
      ),
    );
    _placeCaret(executor, id, const TextNodePosition(offset: 0));
  }
}
