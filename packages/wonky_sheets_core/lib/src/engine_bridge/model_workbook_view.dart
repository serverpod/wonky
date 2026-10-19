import '../addressing/grid_geometry.dart';
import '../format/attributes.dart';
import '../formula/model/workbook_view.dart';
import '../model/axis_index.dart';
import '../model/grid_range.dart';
import '../model/records.dart';
import '../model/schema.dart';
import '../model/sheet_model.dart';
import '../model/workbook_model.dart';
import 'model_cell_source.dart';

/// Computed cell values layered under empty cells — pivot table output
/// (07 §7.6). The engine reads them as literal inputs, so formulas, the
/// grid and the clipboard see them like spilled values. The owner calls
/// `FormulaEngine.rectChanged` for the rectangles whose values changed.
abstract interface class ComputedOverlaySource {
  /// The overlay input at ([row], [col]) of [sheetId], or null. Only asked
  /// for cells without content.
  EngineCellInput? inputAt(String sheetId, int row, int col);

  /// The number format of the overlay cell, or null (Automatic).
  String? numberFormatAt(String sheetId, int row, int col);

  /// The overlay rectangles of [sheetId] (used extent, range scans).
  Iterable<GridRect> rectsOf(String sheetId);
}

/// Adapts a [WorkbookModel] to the formula engine's [WorkbookView] (05 §2.1),
/// used by the client `RecalcHost`, the server `HeadlessWorkbook` and the
/// planner's formula hooks.
///
/// Views are cached per sheet; `CellInput` instances are cached per immutable
/// [CellRecord], so the engine sees a new input exactly when content changes.
final class ModelWorkbookView implements WorkbookView {
  /// Creates the adapter.
  ModelWorkbookView(this.model);

  /// The model.
  final WorkbookModel model;

  /// Computed overlays (pivot output) shown in empty cells, or null.
  ComputedOverlaySource? overlays;

  final Expando<_SheetView> _views = Expando();

  @override
  String get spreadsheetId => model.spreadsheetId;

  @override
  List<SheetView> get sheets => [
    for (final s in model.sheets)
      if (s.record!.kind == SheetKind.grid) _view(s),
  ];

  _SheetView _view(SheetModel s) => _views[s] ??= _SheetView(s, model, this);

  @override
  SheetView? sheetById(String id) {
    final s = model.sheet(id);
    return s == null || s.record!.kind != SheetKind.grid ? null : _view(s);
  }

  @override
  SheetView? sheetByName(String name) {
    final s = model.sheetByName(name);
    return s == null || s.record!.kind != SheetKind.grid ? null : _view(s);
  }

  @override
  Iterable<NamedRangeView> get namedRanges =>
      model.namedRanges.map((r) => _namedViews[r] ??= _NamedView(r));

  /// Views per (immutable) record, so their decoded ranges are reused.
  final Expando<_NamedView> _namedViews = Expando();

  @override
  CalcSettings get settings {
    final sp = model.spreadsheet;
    return CalcSettings(
      locale: sp.locale,
      timeZone: sp.timeZone,
      recalcMode: sp.recalcMode,
      iterativeCalc: sp.iterativeCalc,
      maxIterations: sp.maxIterations,
      convergenceThreshold: sp.convergenceThreshold,
      displayLanguage: sp.displayLanguage,
    );
  }
}

/// The engine input of a cell record (cached per record instance).
CellInput? cellInputOf(CellRecord? c) {
  if (c == null || c.content == null) return null;
  final cached = c.engineInput;
  if (cached is CellInput) return cached;
  final input = CellInput.fromContent(c.content);
  if (input != null) c.engineInput = input;
  return input;
}

/// The content inputs of one column by row index (dense range reads, 05 §11.2), valid
/// for the row order and the column content they were built from.
final class _DenseColumn {
  _DenseColumn(this.rowsGeneration, this.version, this.inputs);
  final int rowsGeneration;
  final int version;

  /// Inputs by row index, up to the last row with content.
  final List<CellInput?> inputs;
}

final class _AxisView implements AxisView {
  _AxisView(this.axis, this.isRows);
  final AxisIndex axis;
  final bool isRows;

  @override
  int get length => axis.length;

  @override
  String idAt(int index) => axis.idAt(index);

  @override
  int indexOf(String id) => axis.indexOf(id);

  @override
  String sortKeyAt(int index) => axis.sortKeyAt(index);

  @override
  int lowerBound(String sortKey, String id) => axis.insertionIndex(sortKey, id);

  @override
  bool isHidden(int index) =>
      axis.isUserHidden(index) || axis.isHiddenBy(HiddenLayers.groups, index);
}

final class _SheetView implements SheetView {
  _SheetView(this.s, this.model, this.owner)
    : rows = _AxisView(s.rows, true),
      columns = _AxisView(s.columns, false);

  final SheetModel s;
  final WorkbookModel model;
  final ModelWorkbookView owner;

  @override
  final AxisView rows;

  @override
  final AxisView columns;

  int _usedVersion = -1;
  int _usedRows = 0;
  int _usedCols = 0;

  @override
  String get id => s.id;

  @override
  String get name => s.name;

  @override
  CellInput? inputAt(int row, int col) {
    final cell = s.cellAt(row, col);
    final input = cellInputOf(cell);
    if (input != null) return input;
    return owner.overlays?.inputAt(s.id, row, col);
  }

  @override
  void forEachInput(
    GridRect rect,
    void Function(int row, int col, CellInput input) visit,
  ) {
    final o = owner.overlays;
    final hits = o == null
        ? const <GridRect>[]
        : [
            for (final r in o.rectsOf(s.id))
              if (r.intersection(rect) case final GridRect i) i,
          ];
    if (hits.isEmpty) {
      if (_forEachDense(rect, visit)) return;
      s.cells.forEachIn(
        s.rows,
        s.columns,
        rect.top,
        rect.left,
        rect.bottom,
        rect.right,
        (r, c, cell) {
          final input = cellInputOf(cell);
          if (input != null) visit(r, c, input);
        },
        contentOnly: true,
      );
      return;
    }
    // Merge content and overlay cells in row-major order.
    final out = <(int, int, CellInput)>[];
    final seen = <int>{};
    for (final (r, c, cell) in s.cellsIn(rect, contentOnly: true)) {
      final input = cellInputOf(cell);
      if (input == null) continue;
      out.add((r, c, input));
      seen.add(r * 0x100000 + c);
    }
    for (final i in hits) {
      for (var r = i.top; r <= i.bottom; r++) {
        for (var c = i.left; c <= i.right; c++) {
          if (seen.contains(r * 0x100000 + c)) continue;
          final input = o!.inputAt(s.id, r, c);
          if (input != null) out.add((r, c, input));
        }
      }
    }
    out.sort((a, b) => a.$1 != b.$1 ? a.$1 - b.$1 : a.$2 - b.$2);
    for (final (r, c, input) in out) {
      visit(r, c, input);
    }
  }

  /// Ranges at least this tall over at most [_denseMaxColumns] columns are read through
  /// dense per-column caches.
  static const int _denseMinRows = 256;
  static const int _denseMaxColumns = 8;

  final Map<String, _DenseColumn> _dense = {};

  /// Visits the inputs of [rect] (row-major, like the sparse path) through dense
  /// per-column caches; false (nothing visited) when [rect] is short, wide or mostly
  /// empty, where the sparse path is cheaper.
  bool _forEachDense(
    GridRect rect,
    void Function(int row, int col, CellInput input) visit,
  ) {
    final top = rect.top < 0 ? 0 : rect.top;
    final left = rect.left < 0 ? 0 : rect.left;
    final bottom = rect.bottom >= s.rows.length
        ? s.rows.length - 1
        : rect.bottom;
    final right = rect.right >= s.columns.length
        ? s.columns.length - 1
        : rect.right;
    final width = right - left + 1;
    final height = bottom - top + 1;
    if (width < 1 || width > _denseMaxColumns || height < _denseMinRows) {
      return false;
    }
    var cells = 0;
    for (var c = left; c <= right; c++) {
      cells += s.cells.columnCount(s.columns.idAt(c));
    }
    // Walking the rows must not cost much more than visiting the cells.
    if (cells < _denseMinRows || height * width > 8 * cells + 4096) {
      return false;
    }
    final columns = [
      for (var c = left; c <= right; c++) _denseColumn(s.columns.idAt(c)),
    ];
    var end = 0;
    for (final l in columns) {
      if (l.length > end) end = l.length;
    }
    final last = bottom < end - 1 ? bottom : end - 1;
    if (width == 1) {
      final inputs = columns.first;
      for (var r = top; r <= last; r++) {
        final input = inputs[r];
        if (input != null) visit(r, left, input);
      }
      return true;
    }
    for (var r = top; r <= last; r++) {
      for (var i = 0; i < width; i++) {
        final inputs = columns[i];
        if (r >= inputs.length) continue;
        final input = inputs[r];
        if (input != null) visit(r, left + i, input);
      }
    }
    return true;
  }

  List<CellInput?> _denseColumn(String colId) {
    final generation = s.rows.generation;
    final version = s.cells.columnVersion(colId);
    final cached = _dense[colId];
    if (cached != null &&
        cached.rowsGeneration == generation &&
        cached.version == version) {
      return cached.inputs;
    }
    final rows = <int>[];
    final inputs = <CellInput>[];
    var length = 0;
    for (final cell in s.cells.columnCells(colId)) {
      final input = cellInputOf(cell);
      if (input == null) continue;
      final r = s.rows.indexOf(cell.rowId);
      if (r < 0) continue;
      rows.add(r);
      inputs.add(input);
      if (r >= length) length = r + 1;
    }
    final dense = List<CellInput?>.filled(length, null);
    for (var i = 0; i < rows.length; i++) {
      dense[rows[i]] = inputs[i];
    }
    if (cached == null && _dense.length >= 64) _dense.clear();
    _dense[colId] = _DenseColumn(generation, version, dense);
    return dense;
  }

  void _computeUsed() {
    if (_usedVersion == model.version) return;
    final e = s.cells.usedExtent(s.rows, s.columns);
    _usedRows = e == null ? 0 : e.$1 + 1;
    _usedCols = e == null ? 0 : e.$2 + 1;
    _usedVersion = model.version;
  }

  @override
  int get usedRowCount {
    _computeUsed();
    var n = _usedRows;
    for (final r in owner.overlays?.rectsOf(s.id) ?? const <GridRect>[]) {
      if (r.bottom + 1 > n) n = r.bottom + 1;
    }
    return n;
  }

  @override
  int get usedColumnCount {
    _computeUsed();
    var n = _usedCols;
    for (final r in owner.overlays?.rectsOf(s.id) ?? const <GridRect>[]) {
      if (r.right + 1 > n) n = r.right + 1;
    }
    return n;
  }

  @override
  String? numberFormatAt(int row, int col) {
    final f =
        model.explicitFormatChain(s.id, row, col)[FormatAttr.numberFormat]
            as String?;
    if (f != null) return f == 'preset:automatic' ? null : f;
    final o = owner.overlays;
    if (o == null || s.cellAt(row, col)?.content != null) return null;
    return o.numberFormatAt(s.id, row, col);
  }

  @override
  bool isRowFilterHidden(int row) =>
      row >= 0 &&
      row < s.rows.length &&
      (s.rows.isHiddenBy(HiddenLayers.filter, row) ||
          s.rows.isHiddenBy(HiddenLayers.slicer, row));

  @override
  double columnWidthAt(int col) =>
      col >= 0 && col < s.columns.length ? s.columns.naturalSizeAt(col) : 100;
}

final class _NamedView implements NamedRangeView {
  _NamedView(this.r);
  final NamedRangeRecord r;

  @override
  String get id => r.id;

  @override
  String get name => r.name;

  /// Decoded once per view (the record is immutable; the engine keeps its views until
  /// the names change), not per evaluation of every formula using the name.
  @override
  late final IdRange? range = _decode();

  IdRange? _decode() {
    final g = GridRange.tryParse(r.rangeJson);
    if (g == null) return null;
    return IdRange(
      g.sheetId,
      rowStart: g.r1,
      rowEnd: g.r2,
      colStart: g.c1,
      colEnd: g.c2,
      rowStartKey: g.r1k,
      rowEndKey: g.r2k,
      colStartKey: g.c1k,
      colEndKey: g.c2k,
    );
  }

  @override
  String? get formula => r.formula;

  @override
  String? get comment => r.comment;

  @override
  String? get metaJson => r.metaJson;
}
