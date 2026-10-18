import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show InlineMarkdown;

import '../applier/delta_applier.dart';
import '../commands/write_editor_commands.dart';
import '../controller/write_editor_controller.dart';
import '../model/document_queries.dart';
import '../model/table_model.dart';
import '../styles/editor_theme.dart';

/// The cell being edited in place.
@immutable
class TableCellRef {
  const TableCellRef(this.tableId, this.row, this.column);

  /// The table's node id (= its embed id).
  final String tableId;
  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is TableCellRef &&
      other.tableId == tableId &&
      other.row == row &&
      other.column == column;

  @override
  int get hashCode => Object.hash(tableId, row, column);

  @override
  String toString() => 'TableCellRef($tableId, $row, $column)';
}

/// In-place table cell editing (Write 04 §18.4, super_editor patch SE-4).
///
/// The document caret never enters a table: a table embed stays one block
/// node. Clicking a cell (or Enter / F2 on a selected table, or
/// `write.table.editCell`) turns that cell into a text field that edits the
/// cell's **inline Markdown source**; other cells keep their rendering.
///
/// - Tab / Shift+Tab move to the next / previous cell; Tab in the last cell
///   appends a row. Enter moves down and appends a row from the last row;
///   Shift+Enter moves up. ↑ ↓ move between rows, ← → at the text edges move
///   between cells, and leave the table at its edges.
/// - Mod+B / I / E and Mod+Shift+X wrap the field selection in `**`, `*`,
///   `` ` `` and `~~`; Mod+K wraps it as a link.
/// - Esc leaves the cell and selects the table; Mod+Enter leaves it and puts
///   the caret after the table.
///
/// Every commit replaces the `table` embed (`write.table.replace` semantics,
/// one undo step "Edit cell"): when leaving a cell, when the field loses
/// focus, and after [idleCommit] without typing (so collaborators see the
/// edit). Undo/redo in a clean field run the document's undo/redo.
///
/// The field's focus node is parented **outside** the `SuperEditor` (see
/// [focusParent]), so the editor's keyboard handlers and IME connection never
/// see the cell's keys.
class InlineTableEditing extends ChangeNotifier
    implements InlineTableEditingHandle {
  InlineTableEditing({
    required this.controller,
    required this.commands,
    this.onUndo,
    this.onRedo,
    this.idleCommit = const Duration(milliseconds: 1500),
  }) {
    focusNode = FocusNode(debugLabel: 'write-table-cell', onKeyEvent: _onKey);
    focusNode.addListener(_onFocusChanged);
    controller.addListener(_onDocumentChanged);
  }

  final WriteEditorController controller;
  final WriteEditorCommands commands;

  /// Document undo/redo (the shell's undo stack).
  VoidCallback? onUndo;
  VoidCallback? onRedo;

  /// Commit after this long without typing.
  final Duration idleCommit;

  /// The focus node the cell field is parented to (outside the editor).
  FocusNode? focusParent;

  /// The field's text (the cell's inline Markdown source).
  final TextEditingController text = TextEditingController();

  /// The field's undo history (draft-local undo).
  final UndoHistoryController undo = UndoHistoryController();

  /// Focus of the field.
  late final FocusNode focusNode;

  /// Keeps the field's state while the table component rebuilds.
  final GlobalKey fieldKey = GlobalKey(debugLabel: 'write-table-cell-field');

  TableCellRef? _active;
  String _base = '';
  Timer? _idle;
  bool _committing = false;
  bool _disposed = false;

  /// The cell being edited, or `null`.
  TableCellRef? get active => _active;

  @override
  bool get isEditing => _active != null;

  /// Whether the field differs from the cell's content.
  bool get isDirty => _active != null && text.text != _base;

  /// Whether cells of [tableId] can be edited in place now.
  bool canEdit(String tableId) => commands.canEditTable(nodeId: tableId);

  /// Starts editing cell ([row], [column]) of [tableId]. [caret] places the
  /// caret (default: end of the text); [selectAll] selects the whole cell.
  @override
  bool activate(
    String tableId,
    int row,
    int column, {
    int? caret,
    bool selectAll = false,
  }) {
    final table = commands.tableOf(nodeId: tableId);
    if (table == null || !canEdit(tableId)) return false;
    if (row < 0 || row >= table.rowCount) return false;
    if (column < 0 || column >= table.columnCount) return false;
    final next = TableCellRef(tableId, row, column);
    if (_active != null && _active != next) commit();
    final source = table.rows[row][column];
    final changedCell = _active != next;
    _active = next;
    if (changedCell) {
      _base = source;
      text.value = TextEditingValue(
        text: source,
        selection: selectAll
            ? TextSelection(baseOffset: 0, extentOffset: source.length)
            : TextSelection.collapsed(
                offset: (caret ?? source.length).clamp(0, source.length),
              ),
      );
      undo.value = UndoHistoryValue.empty;
    }
    // Presence: the local selection is the table embed (Write 04 §18.4).
    final block = controller.mirror.blockOf(tableId);
    if (block != null) {
      final s = controller.selection;
      if (s == null || s.start != block.start || s.end != block.start + 1) {
        controller.select(
          DeltaSelection(block.start, block.start + 1),
          userInteraction: false,
        );
      }
    }
    notifyListeners();
    _focusField();
    return true;
  }

  void _focusField() {
    if (focusNode.context != null) {
      focusNode.requestFocus();
      return;
    }
    // The field mounts with the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && _active != null) focusNode.requestFocus();
    });
  }

  /// Writes the field into the table (one undo step). Returns whether the
  /// document changed.
  bool commit({String? label}) {
    label ??= controller.strings().undoEditCell;
    _idle?.cancel();
    final cell = _active;
    if (cell == null || !isDirty || _committing) return false;
    _committing = true;
    try {
      final source = InlineMarkdown.canonicalCell(
        text.text.replaceAll(RegExp(r'[\r\n]+'), ' '),
      );
      final ok = commands.editTable(
        (table) => table.setCell(cell.row, cell.column, source),
        nodeId: cell.tableId,
        label: label,
      );
      _base = text.text;
      return ok;
    } finally {
      _committing = false;
    }
  }

  /// Stops editing. With [focusEditor] the document editor gets the focus
  /// back, and [caretAfter] / [caretBefore] place the caret around the table;
  /// otherwise the table stays selected.
  @override
  void deactivate({
    bool save = true,
    bool focusEditor = false,
    bool caretAfter = false,
    bool caretBefore = false,
  }) {
    final cell = _active;
    if (cell == null) return;
    if (save) commit();
    _idle?.cancel();
    _active = null;
    _base = '';
    notifyListeners();
    final block = controller.mirror.blockOf(cell.tableId);
    if (block != null && (caretAfter || caretBefore)) {
      final offset = caretAfter
          ? (block.start + block.length).clamp(0, controller.length - 1)
          : (block.start - 1).clamp(0, controller.length - 1);
      controller.select(DeltaSelection.collapsed(offset));
    }
    if (focusEditor) controller.focusNode.requestFocus();
  }

  /// Called by the field on every change.
  void onChanged(String value) {
    _idle?.cancel();
    if (isDirty) _idle = Timer(idleCommit, commit);
  }

  void _onFocusChanged() {
    if (!focusNode.hasFocus && _active != null) {
      // Focus left the cell (click elsewhere, a dialog, the menubar).
      deactivate();
    }
  }

  void _onDocumentChanged() {
    final cell = _active;
    if (cell == null || _committing) return;
    final table = commands.tableOf(nodeId: cell.tableId);
    if (table == null ||
        cell.row >= table.rowCount ||
        cell.column >= table.columnCount) {
      // Removed by a collaborator (or undo): nothing to edit any more.
      final wasDirty = isDirty;
      _active = null;
      _base = '';
      _idle?.cancel();
      notifyListeners();
      if (wasDirty) {
        controller.notify(
          EditorNotice(
            EditorNoticeKind.message,
            table == null
                ? controller.strings().editorTableDeleted
                : controller.strings().editorCellRemoved,
          ),
        );
      }
      return;
    }
    final source = table.rows[cell.row][cell.column];
    if (source == _base) return;
    if (isDirty) {
      // Keep the draft; it wins when committed (last writer wins).
      _base = source;
      return;
    }
    _base = source;
    final caret = text.selection.baseOffset.clamp(0, source.length);
    text.value = TextEditingValue(
      text: source,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation.

  TableModel? get _table {
    final cell = _active;
    return cell == null ? null : commands.tableOf(nodeId: cell.tableId);
  }

  /// Moves to the next (or previous) cell in reading order. Past the last
  /// cell a row is appended ([appendRow]).
  void moveHorizontally(int step, {bool appendRow = true}) {
    final cell = _active;
    final table = _table;
    if (cell == null || table == null) return;
    var index = cell.row * table.columnCount + cell.column + step;
    final count = table.rowCount * table.columnCount;
    if (index < 0) {
      deactivate(focusEditor: true, caretBefore: true);
      return;
    }
    if (index >= count) {
      if (!appendRow) {
        deactivate(focusEditor: true, caretAfter: true);
        return;
      }
      commit();
      _appendRow(cell.tableId);
      index = count;
    }
    activate(
      cell.tableId,
      index ~/ table.columnCount,
      index % table.columnCount,
      caret: step > 0 ? 0 : null,
      selectAll: appendRow,
    );
  }

  /// Moves to the cell above/below; below the last row Enter appends a row.
  void moveVertically(int step, {bool appendRow = false}) {
    final cell = _active;
    final table = _table;
    if (cell == null || table == null) return;
    final row = cell.row + step;
    if (row < 0) {
      deactivate(focusEditor: true, caretBefore: true);
      return;
    }
    if (row >= table.rowCount) {
      if (!appendRow) {
        deactivate(focusEditor: true, caretAfter: true);
        return;
      }
      commit();
      _appendRow(cell.tableId);
    }
    activate(cell.tableId, row, cell.column);
  }

  void _appendRow(String tableId) {
    commands.editTable(
      (table) => table.insertRow(table.rowCount),
      nodeId: tableId,
      label: controller.strings().undoInsertRow,
    );
  }

  // ---------------------------------------------------------------------------
  // Keys.

  static bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_active == null) return KeyEventResult.ignored;
    final keyboard = HardwareKeyboard.instance;
    final mod = _isApple ? keyboard.isMetaPressed : keyboard.isControlPressed;
    final shift = keyboard.isShiftPressed;
    final alt = keyboard.isAltPressed;
    final key = event.logicalKey;
    final selection = text.selection;
    final length = text.text.length;

    if (key == LogicalKeyboardKey.escape) {
      deactivate(focusEditor: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      moveHorizontally(shift ? -1 : 1, appendRow: !shift);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (mod) {
        deactivate(focusEditor: true, caretAfter: true);
      } else {
        moveVertically(shift ? -1 : 1, appendRow: !shift);
      }
      return KeyEventResult.handled;
    }
    if (!mod && !alt && !shift) {
      if (key == LogicalKeyboardKey.arrowUp) {
        moveVertically(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        moveVertically(1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft &&
          selection.isCollapsed &&
          selection.baseOffset <= 0) {
        moveHorizontally(-1, appendRow: false);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight &&
          selection.isCollapsed &&
          selection.baseOffset >= length) {
        moveHorizontally(1, appendRow: false);
        return KeyEventResult.handled;
      }
    }
    if (mod && !alt) {
      if (key == LogicalKeyboardKey.keyZ) {
        final history = undo.value;
        if (shift ? history.canRedo : history.canUndo) {
          return KeyEventResult.ignored; // the field's own undo
        }
        commit();
        (shift ? onRedo : onUndo)?.call();
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.keyY && !_isApple) {
        if (undo.value.canRedo) return KeyEventResult.ignored;
        commit();
        onRedo?.call();
        return KeyEventResult.handled;
      }
      if (!shift && key == LogicalKeyboardKey.keyB) return _wrap('**', '**');
      if (!shift && key == LogicalKeyboardKey.keyI) return _wrap('*', '*');
      if (!shift && key == LogicalKeyboardKey.keyE) return _wrap('`', '`');
      if (shift && key == LogicalKeyboardKey.keyX) return _wrap('~~', '~~');
      if (!shift && key == LogicalKeyboardKey.keyK) return _wrap('[', ']()');
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _wrap(String before, String after) {
    final value = text.value;
    final selection = value.selection;
    if (!selection.isValid) return KeyEventResult.handled;
    final start = selection.start;
    final end = selection.end;
    final inner = value.text.substring(start, end);
    final replaced = value.text.replaceRange(start, end, '$before$inner$after');
    final caret = after == ']()'
        ? start + before.length + inner.length + 2
        : start + before.length + inner.length + after.length;
    text.value = TextEditingValue(
      text: replaced,
      selection: inner.isEmpty || after == ']()'
          ? TextSelection.collapsed(
              offset: inner.isEmpty ? start + before.length : caret,
            )
          : TextSelection(
              baseOffset: start + before.length,
              extentOffset: start + before.length + inner.length,
            ),
    );
    onChanged(text.text);
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    _disposed = true;
    _idle?.cancel();
    if (_active != null) commit();
    controller.removeListener(_onDocumentChanged);
    focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    text.dispose();
    undo.dispose();
    super.dispose();
  }
}

/// The `SE-4` cell builder: the active cell becomes a text field, the others
/// keep their rendering and start editing on tap.
TableCellContentBuilder inlineTableCellBuilder(
  InlineTableEditing editing,
  EditorTheme theme,
) {
  return (context, cell) => _InlineCell(
    key: ValueKey(
      'write.editor.tableCell.${cell.tableNodeId}.${cell.rowIndex}.${cell.columnIndex}',
    ),
    editing: editing,
    theme: theme,
    cell: cell,
  );
}

class _InlineCell extends StatelessWidget {
  const _InlineCell({
    super.key,
    required this.editing,
    required this.theme,
    required this.cell,
  });

  final InlineTableEditing editing;
  final EditorTheme theme;
  final TableCellBuildContext cell;

  bool get _isActive =>
      editing.active ==
      TableCellRef(cell.tableNodeId, cell.rowIndex, cell.columnIndex);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: editing,
      builder: (context, _) {
        if (_isActive) return _field(context);
        if (!editing.canEdit(cell.tableNodeId)) return cell.defaultContent;
        return MouseRegion(
          cursor: SystemMouseCursors.text,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => editing.activate(
              cell.tableNodeId,
              cell.rowIndex,
              cell.columnIndex,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48),
              child: cell.defaultContent,
            ),
          ),
        );
      },
    );
  }

  Widget _field(BuildContext context) {
    final style = cell.cell.textStyleBuilder(const {});
    return Focus(
      parentNode: editing.focusParent,
      canRequestFocus: false,
      skipTraversal: true,
      child: TextField(
        key: editing.fieldKey,
        controller: editing.text,
        focusNode: editing.focusNode,
        undoController: editing.undo,
        style: style,
        textAlign: cell.cell.textAlign,
        maxLines: null,
        cursorColor: theme.caretColor,
        cursorWidth: 2,
        decoration: const InputDecoration.collapsed(hintText: ''),
        inputFormatters: [
          FilteringTextInputFormatter.deny(
            RegExp(r'[\r\n]+'),
            replacementString: ' ',
          ),
        ],
        onChanged: editing.onChanged,
      ),
    );
  }
}
