import 'dart:async';
import 'dart:ui' show FlutterView, SemanticsRole;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_sheets_core/formula.dart' show ColumnLetters, GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../../../l10n/sheets_l10n.dart';
import '../../sheet_editor/sheet_editor_controller.dart';

/// Screen-reader text of one cell (03 §18): "B4, 42", "B4, 42, formula
/// =SUM(B1:B3)", "B4, empty", "B4, checkbox checked", "B4, link, …",
/// "B4, has note", "B4, error, divide by zero".
String describeCell(
  SheetEditorController ed,
  SheetsLocalizations l,
  int row,
  int col, {
  bool withAddress = true,
}) {
  final sid = ed.activeSheetId;
  final a1 = withAddress ? GridRect.cell(row, col).a1 : '';
  String join(String text) => withAddress ? text : _stripAddress(text, a1);
  if (!ed.session.rowLoading.isRowLoaded(
    sid,
    ed.activeSheet?.rows.tryIdAt(row) ?? '',
  )) {
    return join(l.a11yCellValue(a1, l.a11yLoadingRow));
  }
  final d = ed.cells.displayAt(sid, row, col);
  final parts = <String>[];
  final value = d?.value;
  if (value is ErrorValue) {
    return join(l.a11yCellError(a1, value.message ?? value.kind.literal));
  }
  final text = d?.formatted.plainText ?? '';
  final widget = d?.widget;
  if (widget?.kind == CellWidgetKind.checkbox) {
    parts.add(
      widget!.checked ? l.a11yCheckboxChecked : l.a11yCheckboxUnchecked,
    );
  } else if (text.isNotEmpty) {
    parts.add(text);
  }
  if (d?.content is FormulaContent) {
    parts.add(l.a11yCellFormula(ed.editableText(row, col)));
  }
  final link = d?.linkUrl;
  if (link != null) parts.add(l.a11yLink(link));
  if ((d?.record?.note ?? '').isNotEmpty) parts.add(l.a11yHasNote);
  if (parts.isEmpty) return join(l.a11yCellEmpty(a1));
  return join(l.a11yCellValue(a1, parts.join(', ')));
}

String _stripAddress(String text, String a1) =>
    a1.isEmpty && text.startsWith(', ') ? text.substring(2) : text;

/// What the selection announcer says (03 §18): the active cell, or "A1 to
/// C5 selected, 15 cells", or "B4 to C5 merged".
String describeSelection(SheetEditorController ed, SheetsLocalizations l) {
  final sel = ed.selection.resolved;
  final rect = sel.activeRange.rect;
  final sheet = ed.activeSheet;
  final merge = sheet?.mergeAt(sel.activeRow, sel.activeCol);
  if (merge != null && merge == rect) {
    final from = GridRect.cell(merge.top, merge.left).a1;
    final to = GridRect.cell(merge.bottom, merge.right).a1;
    return '${l.a11yMerged(from, to)}. '
        '${describeCell(ed, l, merge.top, merge.left)}';
  }
  if (sel.ranges.length == 1 && rect.rowCount * rect.colCount > 1) {
    return l.a11yRangeSelected(
      GridRect.cell(rect.top, rect.left).a1,
      GridRect.cell(rect.bottom, rect.right).a1,
      rect.rowCount * rect.colCount,
    );
  }
  return describeCell(ed, l, sel.activeRow, sel.activeCol);
}

/// Announces the active cell to screen readers (03 §18
/// `SelectionAnnouncer`): 100 ms after the selection settles, and "Editing
/// B4" when editing starts. Silent while no assistive technology is on.
class SelectionAnnouncer {
  SelectionAnnouncer(this.ed, {required this.view, this.debounce = _delay}) {
    ed.selection.addListener(_onSelection);
    ed.editor.addListener(_onEditor);
  }

  static const _delay = Duration(milliseconds: 100);

  final SheetEditorController ed;
  final FlutterView? Function() view;
  final Duration debounce;
  Timer? _timer;
  bool _wasEditing = false;

  /// The last text announced (tests).
  String? last;

  /// Whether announcements are sent (an assistive technology is on);
  /// tests force it.
  bool Function() enabled = () => SemanticsBinding.instance.semanticsEnabled;

  void _onSelection() {
    _timer?.cancel();
    _timer = Timer(debounce, () => _say(describeSelection(ed, ed.l10n)));
  }

  void _onEditor() {
    final editing = ed.editor.isEditing;
    if (editing && !_wasEditing) {
      _say(ed.l10n.a11yEditing(ed.activeA1));
    }
    _wasEditing = editing;
  }

  void _say(String text) {
    if (!enabled()) return;
    last = text;
    final v = view();
    if (v != null) {
      unawaited(SemanticsService.sendAnnouncement(v, text, TextDirection.ltr));
    }
  }

  void dispose() {
    _timer?.cancel();
    ed.selection.removeListener(_onSelection);
    ed.editor.removeListener(_onEditor);
  }
}

/// The grid as a semantics table (03 §18 `GridSemantics`): a row of column
/// headers, then one row node per visible row with a cell node per visible
/// cell (row number first), capped at [maxCells]. Built only while
/// semantics are on; rebuilt on scroll, content and selection changes.
class GridSemantics extends LeafRenderObjectWidget {
  const GridSemantics({
    super.key,
    required this.controller,
    required this.l10n,
  });

  final SheetEditorController controller;
  final SheetsLocalizations l10n;

  /// Visible cells exposed at most.
  static const maxCells = 2500;

  @override
  RenderGridSemantics createRenderObject(BuildContext context) =>
      RenderGridSemantics(controller, l10n);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderGridSemantics renderObject,
  ) {
    renderObject
      ..controller = controller
      ..l10n = l10n;
  }
}

class RenderGridSemantics extends RenderBox {
  RenderGridSemantics(this._controller, this.l10n);

  SheetEditorController _controller;
  SheetsLocalizations l10n;
  final Map<String, SemanticsNode> _nodes = {};

  SheetEditorController get controller => _controller;
  set controller(SheetEditorController c) {
    if (identical(c, _controller)) return;
    if (attached) _unlisten();
    _controller = c;
    if (attached) _listen();
    markNeedsSemanticsUpdate();
  }

  List<Listenable> get _sources => [
    _controller.scroll,
    _controller.contentSignal,
    _controller.selection,
  ];

  void _listen() {
    for (final l in _sources) {
      l.addListener(markNeedsSemanticsUpdate);
    }
  }

  void _unlisten() {
    for (final l in _sources) {
      l.removeListener(markNeedsSemanticsUpdate);
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _listen();
  }

  @override
  void detach() {
    _unlisten();
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..explicitChildNodes = true
      ..role = SemanticsRole.table
      ..label = l10n.a11yGridLabel(_controller.activeSheet?.name ?? '')
      ..textDirection = TextDirection.ltr;
  }

  SemanticsNode _node(String key) =>
      _nodes[key] ??= SemanticsNode(key: ValueKey<String>(key));

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    final g = _controller.geometry;
    final sheet = _controller.activeSheet;
    if (g == null || sheet == null) {
      node.updateWith(config: config, childrenInInversePaintOrder: const []);
      return;
    }
    final sel = _controller.selection.resolved;
    final used = <String>{};
    final rows = <SemanticsNode>[];
    var budget = GridSemantics.maxCells;

    // Visible rows and columns (all panes, frozen first).
    final rowIdx = <int>{};
    final colIdx = <int>{};
    for (final p in g.panes) {
      if (p.isEmpty) continue;
      for (final r in p.rows) {
        if (sheet.rows.sizeAt(r) > 0) rowIdx.add(r);
      }
      for (var c = p.colStart; c <= p.colEnd; c++) {
        if (sheet.columns.sizeAt(c) > 0) colIdx.add(c);
      }
    }
    // Screen order (a sorted filter view shows rows in display order).
    final rowList = rowIdx.toList()
      ..sort((a, b) => g.displayRow(a).compareTo(g.displayRow(b)));
    final colList = colIdx.toList()..sort();

    Rect cellRect(int r, int c) => g.paneFor(r, c).cellRect(r, c);

    // Header row.
    final header = <SemanticsNode>[];
    for (final c in colList) {
      final letters = ColumnLetters.fromIndex(c);
      final key = 'h:$c';
      used.add(key);
      final rect = cellRect(rowList.isEmpty ? 0 : rowList.first, c);
      header.add(
        _node(key)
          ..rect = Rect.fromLTWH(rect.left, 0, rect.width, g.colHeaderHeight)
          ..updateWith(
            config: SemanticsConfiguration()
              ..role = SemanticsRole.columnHeader
              ..label = l10n.a11yColumnHeader(letters)
              ..textDirection = TextDirection.ltr,
          ),
      );
    }
    if (header.isNotEmpty) {
      used.add('hr');
      rows.add(
        _node('hr')
          ..rect = Rect.fromLTWH(0, 0, size.width, g.colHeaderHeight)
          ..updateWith(
            config: SemanticsConfiguration()..role = SemanticsRole.row,
            childrenInInversePaintOrder: header,
          ),
      );
    }

    for (final r in rowList) {
      if (budget <= 0) break;
      final rowKey = 'r:${sheet.rows.idAt(r)}';
      used.add(rowKey);
      final cells = <SemanticsNode>[];
      final first = cellRect(r, colList.isEmpty ? 0 : colList.first);
      final numKey = '$rowKey:#';
      used.add(numKey);
      cells.add(
        _node(numKey)
          ..rect = Rect.fromLTWH(0, first.top, g.rowHeaderWidth, first.height)
          ..updateWith(
            config: SemanticsConfiguration()
              ..role = SemanticsRole.cell
              ..label = l10n.a11yRowHeader('${r + 1}')
              ..textDirection = TextDirection.ltr,
          ),
      );
      for (final c in colList) {
        if (budget-- <= 0) break;
        final key = '$rowKey:${sheet.columns.idAt(c)}';
        used.add(key);
        final selected = sel.activeRow == r && sel.activeCol == c;
        cells.add(
          _node(key)
            ..rect = cellRect(r, c)
            ..updateWith(
              config: SemanticsConfiguration()
                ..role = SemanticsRole.cell
                ..label = describeCell(_controller, l10n, r, c)
                ..isSelected = selected
                ..isFocused = selected
                ..textDirection = TextDirection.ltr,
            ),
        );
      }
      final rowRect = Rect.fromLTWH(0, first.top, size.width, first.height);
      rows.add(
        _node(rowKey)
          ..rect = rowRect
          ..updateWith(
            config: SemanticsConfiguration()..role = SemanticsRole.row,
            childrenInInversePaintOrder: cells,
          ),
      );
    }
    _nodes.removeWhere((k, _) => !used.contains(k));
    node.updateWith(config: config, childrenInInversePaintOrder: rows);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _nodes.clear();
  }
}
