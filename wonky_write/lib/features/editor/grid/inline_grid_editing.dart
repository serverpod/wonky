import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show GridEmbed, InlineMarkdown;

import '../applier/delta_applier.dart';
import '../commands/write_editor_commands.dart';
import '../controller/write_editor_controller.dart';
import '../model/document_queries.dart';
import '../model/field_clicks.dart';

/// The grid item being edited in place.
@immutable
class GridItemRef {
  const GridItemRef(this.gridId, this.index);

  /// The grid's node id (= its embed id).
  final String gridId;
  final int index;

  @override
  bool operator ==(Object other) =>
      other is GridItemRef && other.gridId == gridId && other.index == index;

  @override
  int get hashCode => Object.hash(gridId, index);
}

/// In-place editing of grid items (Write 11 §7.4), like table cells (Write
/// 04 §18.4): clicking an item turns it into a text field that edits its
/// inline Markdown source; the document caret never enters the grid.
///
/// - Enter adds an item after the current one; Backspace in an empty item
///   removes it (the last item removes the grid).
/// - Tab / Shift+Tab and ↑ / ↓ move to the next / previous item and leave the
///   grid at its ends; ← → at the text edges move too.
/// - Mod+B / I / E / Shift+X / K wrap the selection like in table cells.
/// - Esc leaves the item and selects the grid; Mod+Enter puts the caret after
///   it.
///
/// Every commit replaces the `grid` embed (one undo step): when leaving an
/// item, when the field loses focus and after [idleCommit] without typing.
class InlineGridEditing extends ChangeNotifier {
  InlineGridEditing({
    required this.controller,
    required this.commands,
    this.onUndo,
    this.onRedo,
    this.idleCommit = const Duration(milliseconds: 1500),
  }) {
    focusNode = FocusNode(debugLabel: 'write-grid-item', onKeyEvent: _onKey);
    focusNode.addListener(_onFocusChanged);
    controller.addListener(_onDocumentChanged);
  }

  final WriteEditorController controller;
  final WriteEditorCommands commands;

  VoidCallback? onUndo;
  VoidCallback? onRedo;

  final Duration idleCommit;

  /// The focus node the field is parented to (outside the editor).
  FocusNode? focusParent;

  /// The field's text (the item's inline Markdown source).
  final TextEditingController text = TextEditingController();

  /// The field's undo history.
  final UndoHistoryController undo = UndoHistoryController();

  late final FocusNode focusNode;

  /// Keeps the field's state while the grid component rebuilds.
  final GlobalKey fieldKey = GlobalKey(debugLabel: 'write-grid-item-field');

  /// The caret where an item was clicked; double and triple clicks.
  final FieldClicks clicks = FieldClicks();

  /// Selects the word at the field's caret (a double click).
  void selectWordAtCaret() {
    if (_active == null) return;
    clicks.select(
      text,
      FieldClicks.wordAt(text.text, text.selection.baseOffset),
    );
  }

  /// Selects the field's text (a triple click).
  void selectAllText() {
    if (_active == null) return;
    clicks.select(
      text,
      TextSelection(baseOffset: 0, extentOffset: text.text.length),
    );
  }

  /// After [clicks] clicks in a row at one place: a word for two, the text
  /// for three or more.
  void selectForClicks(int clicks) {
    if (clicks == 2) selectWordAtCaret();
    if (clicks >= 3) selectAllText();
  }

  GridItemRef? _active;
  String _base = '';
  Timer? _idle;
  bool _committing = false;
  bool _disposed = false;

  /// The item being edited, or `null`.
  GridItemRef? get active => _active;

  bool get isEditing => _active != null;

  bool get isDirty => _active != null && text.text != _base;

  /// Whether the items of [gridId] can be edited now.
  bool canEdit(String gridId) =>
      commands.canEdit && !commands.isSuggesting && _grid(gridId) != null;

  GridEmbed? _grid(String gridId) => commands.gridOf(nodeId: gridId);

  /// Starts editing item [index] of [gridId].
  bool activate(String gridId, int index, {int? caret}) {
    final grid = _grid(gridId);
    if (grid == null || !canEdit(gridId)) return false;
    if (index < 0 || index >= grid.items.length) return false;
    final next = GridItemRef(gridId, index);
    if (_active != null && _active != next) commit();
    final source = _grid(gridId)!.items[index];
    final changed = _active != next;
    _active = next;
    if (changed) {
      _base = source;
      text.value = TextEditingValue(
        text: source,
        selection: TextSelection.collapsed(
          offset: (caret ?? source.length).clamp(0, source.length),
        ),
      );
      undo.value = UndoHistoryValue.empty;
    }
    _selectGridOnceFocused();
    notifyListeners();
    _focusField();
    return true;
  }

  bool _selectionPending = false;

  /// Presence: the local selection becomes the grid embed, once the field
  /// has the focus. Selecting it while the document editor still has the
  /// focus (the field is built a frame later) let the editor take the text
  /// input back after the field had it: typing went to the editor, which
  /// moved its caret before or after the grid.
  void _selectGridOnceFocused() {
    if (!focusNode.hasFocus) {
      _selectionPending = true;
      return;
    }
    _selectionPending = false;
    final item = _active;
    final block = item == null ? null : controller.mirror.blockOf(item.gridId);
    if (block == null) return;
    final s = controller.selection;
    if (s == null || s.start != block.start || s.end != block.start + 1) {
      controller.select(
        DeltaSelection(block.start, block.start + 1),
        userInteraction: false,
      );
    }
  }

  /// [activate] once the current transaction is applied (from a reaction,
  /// before the new grid is in the mirror).
  void activateSoon(String gridId, int index) => scheduleMicrotask(() {
    if (!_disposed) activate(gridId, index);
  });

  void _focusField() {
    if (focusNode.context != null) {
      focusNode.requestFocus();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed && _active != null) focusNode.requestFocus();
    });
  }

  /// Writes the field into the grid (one undo step).
  bool commit() {
    _idle?.cancel();
    final item = _active;
    if (item == null || !isDirty || _committing) return false;
    final grid = _grid(item.gridId);
    if (grid == null || item.index >= grid.items.length) return false;
    _committing = true;
    try {
      final source = InlineMarkdown.canonicalCell(
        text.text.replaceAll(RegExp(r'[\r\n]+'), ' '),
      );
      final items = [...grid.items]..[item.index] = source;
      final ok = commands.replaceGrid(
        grid.copyWith(items: items),
        nodeId: item.gridId,
      );
      _base = text.text;
      return ok;
    } finally {
      _committing = false;
    }
  }

  /// Stops editing; [focusEditor] gives the document editor the focus back
  /// and [caretAfter] / [caretBefore] place the caret around the grid.
  void deactivate({
    bool save = true,
    bool focusEditor = false,
    bool caretAfter = false,
    bool caretBefore = false,
  }) {
    final item = _active;
    if (item == null) return;
    if (save) commit();
    _idle?.cancel();
    clicks.release();
    _active = null;
    _base = '';
    notifyListeners();
    final block = controller.mirror.blockOf(item.gridId);
    if (block != null && (caretAfter || caretBefore)) {
      final offset = caretAfter
          ? (block.start + block.length).clamp(0, controller.length - 1)
          : (block.start - 1).clamp(0, controller.length - 1);
      controller.select(DeltaSelection.collapsed(offset));
    }
    if (focusEditor) controller.focusNode.requestFocus();
  }

  void onChanged(String value) {
    _idle?.cancel();
    if (isDirty) _idle = Timer(idleCommit, commit);
  }

  void _onFocusChanged() {
    if (focusNode.hasFocus && _selectionPending) _selectGridOnceFocused();
    if (!focusNode.hasFocus && _active != null) deactivate();
  }

  void _onDocumentChanged() {
    final item = _active;
    if (item == null || _committing) return;
    final grid = _grid(item.gridId);
    if (grid == null || item.index >= grid.items.length) {
      _active = null;
      _base = '';
      _idle?.cancel();
      notifyListeners();
      return;
    }
    final source = grid.items[item.index];
    if (source == _base) return;
    if (isDirty) {
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

  /// Moves [step] items in reading order, leaving the grid at its ends.
  void move(int step, {bool toStart = false}) {
    final item = _active;
    if (item == null) return;
    final grid = _grid(item.gridId);
    if (grid == null) return;
    final index = item.index + step;
    if (index < 0) {
      deactivate(focusEditor: true, caretBefore: true);
      return;
    }
    if (index >= grid.items.length) {
      deactivate(focusEditor: true, caretAfter: true);
      return;
    }
    activate(item.gridId, index, caret: toStart ? 0 : null);
  }

  /// Enter: a new item after the current one, edited.
  void _newItemAfter() {
    final item = _active;
    if (item == null) return;
    commit();
    final gridId = item.gridId;
    final index = item.index + 1;
    if (!commands.addGridItem(nodeId: gridId, index: index)) return;
    _active = null;
    activate(gridId, index);
  }

  /// Backspace in an empty item: removes it and edits the previous one.
  void _removeEmpty() {
    final item = _active;
    if (item == null) return;
    final gridId = item.gridId;
    final grid = _grid(gridId);
    if (grid == null) return;
    _idle?.cancel();
    _active = null;
    _base = '';
    notifyListeners();
    if (grid.items.length == 1) {
      commands.removeGridItem(0, nodeId: gridId);
      controller.focusNode.requestFocus();
      return;
    }
    commands.removeGridItem(item.index, nodeId: gridId);
    activate(gridId, (item.index - 1).clamp(0, grid.items.length - 2));
  }

  static bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    clicks.release();
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
      move(shift ? -1 : 1, toStart: !shift);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (mod) {
        deactivate(focusEditor: true, caretAfter: true);
      } else {
        _newItemAfter();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace &&
        !mod &&
        length == 0 &&
        event is KeyDownEvent) {
      _removeEmpty();
      return KeyEventResult.handled;
    }
    if (!mod && !alt && !shift) {
      if (key == LogicalKeyboardKey.arrowUp) {
        move(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        move(1, toStart: true);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowLeft &&
          selection.isCollapsed &&
          selection.baseOffset <= 0) {
        move(-1);
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.arrowRight &&
          selection.isCollapsed &&
          selection.baseOffset >= length) {
        move(1, toStart: true);
        return KeyEventResult.handled;
      }
    }
    if (mod && !alt) {
      if (key == LogicalKeyboardKey.keyZ) {
        final history = undo.value;
        if (shift ? history.canRedo : history.canUndo) {
          return KeyEventResult.ignored;
        }
        commit();
        (shift ? onRedo : onUndo)?.call();
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
