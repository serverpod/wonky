import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show InlineMarkdown;

import '../../l10n/write_l10n.dart';
import '../editor/model/table_model.dart';

/// Opens the table editor (`write.dialog.tableEditor`, Write 04 §18.4) on
/// [table]; returns the edited table on Done (null on Cancel / unchanged).
Future<TableModel?> showTableEditor(
  BuildContext context,
  TableModel table, {
  int row = 0,
  int column = 0,
}) => showShadDialog<TableModel>(
  context: context,
  barrierDismissible: false,
  builder: (_) => TableEditorDialog(table: table, row: row, column: column),
);

/// Custom table size (`write.dialog.tableSize`, Write 05 §12.3).
Future<({int rows, int cols})?> showTableSizeDialog(BuildContext context) =>
    showShadDialog<({int rows, int cols})>(
      context: context,
      builder: (_) => const TableSizeDialog(),
    );

class TableSizeDialog extends StatefulWidget {
  const TableSizeDialog({super.key});

  @override
  State<TableSizeDialog> createState() => _TableSizeDialogState();
}

class _TableSizeDialogState extends State<TableSizeDialog> {
  num _rows = 3;
  num _cols = 3;

  void _insert() =>
      Navigator.of(context).pop((rows: _rows.toInt(), cols: _cols.toInt()));

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.tableSize'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.tableEditorInsertTitle),
      constraints: const BoxConstraints(maxWidth: 380),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('write.dialog.tableSize.insert'),
          onPressed: _insert,
          child: Text(l.commonInsert),
        ),
      ],
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.enter): _insert},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            ExcludeSemantics(
              child: Text(l.tableEditorRows, style: theme.textTheme.small),
            ),
            const SizedBox(height: 4),
            WonkyNumberStepper(
              key: const ValueKey<String>('write.dialog.tableSize.rows'),
              semanticLabel: l.tableEditorRows,
              value: _rows,
              min: 2,
              max: 2000,
              onChanged: (v) => setState(() => _rows = v),
            ),
            const SizedBox(height: 4),
            Text(
              l.tableEditorIncludingHeader,
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 12),
            ExcludeSemantics(
              child: Text(l.tableEditorColumns, style: theme.textTheme.small),
            ),
            const SizedBox(height: 4),
            WonkyNumberStepper(
              key: const ValueKey<String>('write.dialog.tableSize.cols'),
              semanticLabel: l.tableEditorColumns,
              value: _cols,
              min: 1,
              max: 64,
              onChanged: (v) => setState(() => _cols = v),
            ),
          ],
        ),
      ),
    );
  }
}

/// The table editor: a grid of single-line cells editing the inline
/// Markdown source, a toolbar with row/column operations and alignment, and
/// a draft-local undo stack. Done commits once (one undo step).
class TableEditorDialog extends StatefulWidget {
  const TableEditorDialog({
    super.key,
    required this.table,
    this.row = 0,
    this.column = 0,
  });

  final TableModel table;
  final int row;
  final int column;

  @override
  State<TableEditorDialog> createState() => _TableEditorDialogState();
}

class _TableEditorDialogState extends State<TableEditorDialog> {
  late TableModel _draft = widget.table;
  final List<TableModel> _undo = [];
  final List<TableModel> _redo = [];
  late int _row = widget.row.clamp(0, widget.table.rowCount - 1);
  late int _col = widget.column.clamp(0, widget.table.columnCount - 1);
  final Map<(int, int), TextEditingController> _text = {};
  final Map<(int, int), FocusNode> _focus = {};

  /// The cell whose keystrokes extend the current undo step; reset by every
  /// structural change, undo and redo (the next edit starts a new step).
  (int, int)? _typingIn;
  final _hScroll = ScrollController();
  final _vScroll = ScrollController();

  bool get _dirty => _draft != widget.table;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCell());
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _hScroll.dispose();
    _vScroll.dispose();
    super.dispose();
  }

  TextEditingController _controller(int r, int c) =>
      _text.putIfAbsent((r, c), () {
        final t = TextEditingController(text: _draft.rows[r][c]);
        t.addListener(() {
          if (r < _draft.rowCount &&
              c < _draft.columnCount &&
              _draft.rows[r][c] != t.text) {
            final next = _draft.setCell(r, c, t.text);
            if (_typingIn != (r, c)) {
              _pushUndo();
              _typingIn = (r, c);
            }
            setState(() => _draft = next);
          }
        });
        return t;
      });

  FocusNode _node(int r, int c) => _focus.putIfAbsent((r, c), () {
    final f = FocusNode(debugLabel: 'cell $r,$c');
    f.addListener(() {
      if (f.hasFocus) {
        setState(() {
          _row = r;
          _col = c;
        });
      }
    });
    return f;
  });

  void _pushUndo() {
    _undo.add(_draft);
    if (_undo.length > 200) _undo.removeAt(0);
    _redo.clear();
  }

  /// Rebuilds the cell controllers after a structural change.
  void _structural(TableModel next, {int? row, int? col}) {
    if (next == _draft) return;
    _pushUndo();
    _replaceDraft(next, row: row, col: col);
  }

  void _replaceDraft(TableModel next, {int? row, int? col}) {
    for (final c in _text.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    _text.clear();
    _focus.clear();
    _typingIn = null;
    setState(() {
      _draft = next;
      _row = (row ?? _row).clamp(0, next.rowCount - 1);
      _col = (col ?? _col).clamp(0, next.columnCount - 1);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusCell());
  }

  void _undoDraft() {
    if (_undo.isEmpty) return;
    _redo.add(_draft);
    _replaceDraft(_undo.removeLast());
  }

  void _redoDraft() {
    if (_redo.isEmpty) return;
    _undo.add(_draft);
    _replaceDraft(_redo.removeLast());
  }

  void _focusCell() {
    if (!mounted) return;
    final node = _node(_row, _col);
    node.requestFocus();
    final t = _controller(_row, _col);
    t.selection = TextSelection(baseOffset: 0, extentOffset: t.text.length);
  }

  void _move(int dr, int dc, {bool appendRow = false}) {
    var r = _row;
    var c = _col + dc;
    if (c >= _draft.columnCount) {
      c = 0;
      r++;
    } else if (c < 0) {
      c = _draft.columnCount - 1;
      r--;
    }
    r += dr;
    if (r >= _draft.rowCount) {
      if (appendRow) {
        _structural(_draft.insertRow(_draft.rowCount), row: r, col: c);
        return;
      }
      r = _draft.rowCount - 1;
    }
    if (r < 0) r = 0;
    setState(() {
      _row = r;
      _col = c;
    });
    _focusCell();
  }

  void _wrap(String marker) {
    final t = _controller(_row, _col);
    final s = t.selection;
    if (!s.isValid) return;
    final text = t.text;
    final start = s.start.clamp(0, text.length);
    final end = s.end.clamp(0, text.length);
    final inner = text.substring(start, end);
    t.value = TextEditingValue(
      text: text.replaceRange(start, end, '$marker$inner$marker'),
      selection: TextSelection(
        baseOffset: start + marker.length,
        extentOffset: end + marker.length,
      ),
    );
  }

  Future<void> _cancel() async {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final discard = await showShadDialog<bool>(
      context: context,
      builder: (context) {
        final l = writeL10n(context);
        return ShadDialog.alert(
          key: const ValueKey<String>('write.dialog.discardTable'),
          title: Text(l.tableEditorDiscardTitle),
          actions: [
            ShadButton.outline(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l.tableEditorKeepEditing),
            ),
            ShadButton.destructive(
              key: const ValueKey<String>('write.dialog.discardTable.discard'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l.tableEditorDiscard),
            ),
          ],
        );
      },
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  void _done() {
    if (!_dirty) {
      Navigator.of(context).pop();
      return;
    }
    final cleaned = [
      for (final row in _draft.rows)
        [for (final cell in row) InlineMarkdown.canonicalCell(cell)],
    ];
    Navigator.of(
      context,
    ).pop(TableModel(id: _draft.id, align: _draft.align, rows: cleaned));
  }

  KeyEventResult _keys(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final kb = HardwareKeyboard.instance;
    final mod = kb.isMetaPressed || kb.isControlPressed;
    final shift = kb.isShiftPressed;
    final key = e.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _cancel();
      return KeyEventResult.handled;
    }
    if (mod && key == LogicalKeyboardKey.enter) {
      _done();
      return KeyEventResult.handled;
    }
    if (mod && key == LogicalKeyboardKey.keyZ) {
      shift ? _redoDraft() : _undoDraft();
      return KeyEventResult.handled;
    }
    if (mod && key == LogicalKeyboardKey.keyY) {
      _redoDraft();
      return KeyEventResult.handled;
    }
    if (mod && !shift) {
      final marker = switch (key) {
        LogicalKeyboardKey.keyB => '**',
        LogicalKeyboardKey.keyI => '*',
        LogicalKeyboardKey.keyE => '`',
        _ => null,
      };
      if (marker != null) {
        _wrap(marker);
        return KeyEventResult.handled;
      }
    }
    if (mod && shift && key == LogicalKeyboardKey.keyX) {
      _wrap('~~');
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      _move(0, shift ? -1 : 1, appendRow: !shift);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      _move(shift ? -1 : 1, 0, appendRow: !shift);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final t = _controller(_row, _col);
      final s = t.selection;
      final left = key == LogicalKeyboardKey.arrowLeft;
      if (s.isCollapsed &&
          ((left && s.start == 0) || (!left && s.end == t.text.length))) {
        _move(0, left ? -1 : 1);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final size = MediaQuery.sizeOf(context);
    final narrow = size.width < 768;
    final body = Focus(
      onKeyEvent: _keys,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _toolbar(context),
          const SizedBox(height: 8),
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: cs.border),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: RawScrollbar(
                controller: _vScroll,
                child: SingleChildScrollView(
                  controller: _vScroll,
                  child: RawScrollbar(
                    controller: _hScroll,
                    child: SingleChildScrollView(
                      controller: _hScroll,
                      scrollDirection: Axis.horizontal,
                      child: _grid(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return ShadDialog(
      key: const ValueKey<String>('write.dialog.tableEditor'),
      title: Text(l.tableEditorTitle),
      // The X asks before discarding edits, like Cancel and Esc.
      closeIcon: WonkyDialogCloseButton(onPressed: _cancel),
      constraints: BoxConstraints(
        maxWidth: narrow ? size.width : (size.width * 0.9).clamp(480, 1100),
        maxHeight: narrow ? size.height : size.height * 0.85,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Semantics(
              label: l.tableEditorSizeSemantic(
                _draft.rowCount,
                _draft.columnCount,
              ),
              excludeSemantics: true,
              child: Text(
                l.tableEditorSize(_draft.rowCount, _draft.columnCount),
                key: const ValueKey<String>('write.dialog.tableEditor.size'),
                style: theme.textTheme.muted,
              ),
            ),
          ),
        ),
        ShadButton.outline(
          key: const ValueKey<String>('write.dialog.tableEditor.cancel'),
          onPressed: _cancel,
          child: Text(l.commonCancel),
        ),
        ShadButton(
          key: const ValueKey<String>('write.dialog.tableEditor.done'),
          onPressed: _done,
          child: Text(l.commonDone),
        ),
      ],
      child: body,
    );
  }

  Widget _toolbar(BuildContext context) {
    final l = writeL10n(context);
    Widget button(
      String key,
      IconData icon,
      String label,
      VoidCallback? onPressed,
    ) => ShadTooltip(
      builder: (_) => Text(label),
      child: ShadIconButton.ghost(
        key: ValueKey<String>('write.dialog.tableEditor.$key'),
        width: 30,
        height: 30,
        iconSize: 16,
        semanticLabel: label,
        enabled: onPressed != null,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
    final cs = ShadTheme.of(context).colorScheme;
    Widget sep() => Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: cs.border,
    );
    final align = _draft.align[_col];
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        button(
          'rowAbove',
          LucideIcons.betweenHorizontalEnd,
          l.tableEditorInsertRowAbove,
          _row == 0
              ? null
              : () => _structural(_draft.insertRow(_row), row: _row),
        ),
        button(
          'rowBelow',
          LucideIcons.betweenHorizontalStart,
          l.tableEditorInsertRowBelow,
          () => _structural(_draft.insertRow(_row + 1), row: _row + 1),
        ),
        button(
          'colLeft',
          LucideIcons.betweenVerticalEnd,
          l.tableEditorInsertColumnLeft,
          _draft.columnCount >= 64
              ? null
              : () => _structural(_draft.insertColumn(_col), col: _col),
        ),
        button(
          'colRight',
          LucideIcons.betweenVerticalStart,
          l.tableEditorInsertColumnRight,
          _draft.columnCount >= 64
              ? null
              : () => _structural(_draft.insertColumn(_col + 1), col: _col + 1),
        ),
        sep(),
        button(
          'deleteRow',
          LucideIcons.rows3,
          l.tableEditorDeleteRow,
          _row == 0 || _draft.rowCount <= 1
              ? null
              : () => _structural(_draft.deleteRow(_row), row: _row - 1),
        ),
        button(
          'deleteColumn',
          LucideIcons.columns3,
          l.tableEditorDeleteColumn,
          _draft.columnCount <= 1
              ? null
              : () => _structural(_draft.deleteColumn(_col), col: _col - 1),
        ),
        sep(),
        button(
          'moveUp',
          LucideIcons.arrowUp,
          l.tableEditorMoveRowUp,
          _row <= 1
              ? null
              : () =>
                    _structural(_draft.moveRow(_row, _row - 1), row: _row - 1),
        ),
        button(
          'moveDown',
          LucideIcons.arrowDown,
          l.tableEditorMoveRowDown,
          _row == 0 || _row >= _draft.rowCount - 1
              ? null
              : () =>
                    _structural(_draft.moveRow(_row, _row + 1), row: _row + 1),
        ),
        button(
          'moveLeft',
          LucideIcons.arrowLeft,
          l.tableEditorMoveColumnLeft,
          _col == 0
              ? null
              : () => _structural(
                  _draft.moveColumn(_col, _col - 1),
                  col: _col - 1,
                ),
        ),
        button(
          'moveRight',
          LucideIcons.arrowRight,
          l.tableEditorMoveColumnRight,
          _col >= _draft.columnCount - 1
              ? null
              : () => _structural(
                  _draft.moveColumn(_col, _col + 1),
                  col: _col + 1,
                ),
        ),
        sep(),
        for (final (a, icon, label) in [
          (TableAlign.left, LucideIcons.alignLeft, l.tableEditorAlignLeft),
          (
            TableAlign.center,
            LucideIcons.alignCenter,
            l.tableEditorAlignCenter,
          ),
          (TableAlign.right, LucideIcons.alignRight, l.tableEditorAlignRight),
        ])
          ShadTooltip(
            builder: (_) => Text(label),
            child: ShadToggle(
              key: ValueKey<String>('write.dialog.tableEditor.align.${a.name}'),
              value: align == a,
              width: 30,
              height: 30,
              padding: EdgeInsets.zero,
              semanticLabel: label,
              onChanged: (on) => _structural(
                _draft.setColumnAlignment(_col, on ? a : TableAlign.none),
              ),
              child: Icon(icon, size: 16),
            ),
          ),
        sep(),
        button('bold', LucideIcons.bold, l.cmdFormatBold, () => _wrap('**')),
        button(
          'italic',
          LucideIcons.italic,
          l.cmdFormatItalic,
          () => _wrap('*'),
        ),
        button(
          'strike',
          LucideIcons.strikethrough,
          l.cmdFormatStrikethrough,
          () => _wrap('~~'),
        ),
        button(
          'code',
          LucideIcons.code,
          l.cmdFormatInlineCode,
          () => _wrap('`'),
        ),
        sep(),
        button(
          'undo',
          LucideIcons.undo2,
          l.commonUndo,
          _undo.isEmpty ? null : _undoDraft,
        ),
        button(
          'redo',
          LucideIcons.redo2,
          l.tableEditorRedo,
          _redo.isEmpty ? null : _redoDraft,
        ),
      ],
    );
  }

  Widget _grid(BuildContext context) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final gutter = TextStyle(
      fontSize: 11,
      color: cs.mutedForeground,
      fontFamily: WonkyTheme.monoFamily,
    );
    return Table(
      defaultColumnWidth: const FixedColumnWidth(160),
      columnWidths: const {0: FixedColumnWidth(36)},
      border: TableBorder.symmetric(inside: BorderSide(color: cs.border)),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(color: cs.muted),
          children: [
            const SizedBox(height: 24),
            for (var c = 0; c < _draft.columnCount; c++)
              Semantics(
                button: true,
                label: l.tableEditorSelectColumn(_letter(c)),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _col = c);
                    _focusCell();
                  },
                  child: Center(child: Text(_letter(c), style: gutter)),
                ),
              ),
          ],
        ),
        for (var r = 0; r < _draft.rowCount; r++)
          TableRow(
            decoration: BoxDecoration(
              color: r == 0 ? cs.muted.withValues(alpha: 0.5) : null,
            ),
            children: [
              Semantics(
                button: true,
                label: l.tableEditorSelectRow(r + 1),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() => _row = r);
                    _focusCell();
                  },
                  child: SizedBox(
                    height: 34,
                    child: Center(child: Text('${r + 1}', style: gutter)),
                  ),
                ),
              ),
              for (var c = 0; c < _draft.columnCount; c++) _cell(context, r, c),
            ],
          ),
      ],
    );
  }

  /// The column letter: A … Z, AA ….
  static String _letter(int c) {
    var n = c;
    var s = '';
    do {
      s = String.fromCharCode(65 + n % 26) + s;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return s;
  }

  Widget _cell(BuildContext context, int r, int c) {
    final l = writeL10n(context);
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final selected = r == _row && c == _col;
    final align = switch (_draft.align[c]) {
      TableAlign.center => TextAlign.center,
      TableAlign.right => TextAlign.right,
      _ => TextAlign.left,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(
          color: selected ? cs.ring : const Color(0x00000000),
          width: 2,
        ),
      ),
      child: Semantics(
        label: r == 0
            ? l.tableEditorHeaderCell(_letter(c))
            : l.tableEditorCell(r + 1, _letter(c)),
        textField: true,
        child: EditableText(
          key: ValueKey<String>('write.dialog.tableEditor.cell.$r.$c'),
          controller: _controller(r, c),
          focusNode: _node(r, c),
          maxLines: 1,
          textAlign: align,
          style: theme.textTheme.small.copyWith(
            fontWeight: r == 0 ? FontWeight.w600 : FontWeight.w400,
            color: cs.foreground,
          ),
          cursorColor: cs.foreground,
          backgroundCursorColor: cs.mutedForeground,
          selectionColor: cs.selection,
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'[\n\r]')),
          ],
        ),
      ),
    );
  }
}
