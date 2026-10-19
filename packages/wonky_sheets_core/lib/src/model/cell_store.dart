import 'axis_index.dart';
import 'records.dart';

/// Sparse cell storage of one sheet (02 §6), keyed by row and column ids so
/// structural changes (insert/delete/move rows) never re-key cells.
final class CellStore {
  final Map<String, CellRecord> _byId = {};
  final Map<String, Map<String, CellRecord>> _rows = {};
  final Map<String, Map<String, CellRecord>> _cols = {};
  int _contentCount = 0;

  // Cells whose content is a formula, in the same relative order as [all].
  final Map<String, CellRecord> _formulas = {};

  // Cells with content per row and per column id (used extent).
  final Map<String, int> _rowContent = {};
  final Map<String, int> _colContent = {};

  // Content version per column id (dense column caches), unique across the store.
  final Map<String, int> _colVersions = {};
  int _versions = 0;

  // Used extent cache: the ids of the last row and column with content, valid for the
  // axis generations it was computed at. Rows/columns that gained their first content
  // cell since are folded in on the next read; losing the last content cell of the
  // extreme row or column invalidates it.
  bool _extentValid = false;
  int _extentRowsGen = -1;
  int _extentColsGen = -1;
  String? _lastRowId;
  String? _lastColId;
  final Set<String> _grownRows = {};
  final Set<String> _grownCols = {};

  /// Number of cell rows (content or format-only).
  int get count => _byId.length;

  /// Number of cells with content.
  int get contentCount => _contentCount;

  /// Cell at (rowId, colId) or null.
  CellRecord? at(String rowId, String colId) => _rows[rowId]?[colId];

  /// Cell by id or null.
  CellRecord? byId(String id) => _byId[id];

  /// All cells (unordered).
  Iterable<CellRecord> get all => _byId.values;

  /// The cells whose content is a formula (`=…`), in the order of [all].
  Iterable<CellRecord> get formulaCells => _formulas.values;

  /// Number of formula cells.
  int get formulaCount => _formulas.length;

  static bool _isFormula(CellRecord c) => c.content?.startsWith('=') ?? false;

  /// Cells of a row (unordered).
  Iterable<CellRecord> inRow(String rowId) => _rows[rowId]?.values ?? const [];

  /// Cells of a column (unordered).
  Iterable<CellRecord> inColumn(String colId) =>
      _cols[colId]?.values ?? const [];

  /// Number of cells in a row.
  int rowCount(String rowId) => _rows[rowId]?.length ?? 0;

  /// Number of cells in a column.
  int columnCount(String colId) => _cols[colId]?.length ?? 0;

  /// Changes whenever a cell of column [colId] is put or removed (0 for a column that
  /// never held a cell). Versions are unique across the store, so a cache keyed on the
  /// version is never confused by a column that was emptied and refilled.
  int columnVersion(String colId) => _colVersions[colId] ?? 0;

  /// The cells of column [colId] (unordered; empty when none).
  Iterable<CellRecord> columnCells(String colId) =>
      _cols[colId]?.values ?? const [];

  /// Row ids that hold at least one cell.
  Iterable<String> get rowIds => _rows.keys;

  /// Column ids that hold at least one cell.
  Iterable<String> get columnIds => _cols.keys;

  /// Inserts or replaces a cell. A blank record (all fields null) is removed.
  void put(CellRecord cell) {
    final old = _byId[cell.id];
    // Content replaced in place: the row and column keep their content counts.
    final keep =
        old != null &&
        old.content != null &&
        cell.content != null &&
        old.rowId == cell.rowId &&
        old.columnId == cell.columnId;
    if (old != null) _detach(old, keepCounts: keep);
    if (cell.isBlankRow) return;
    _byId[cell.id] = cell;
    (_rows[cell.rowId] ??= {})[cell.columnId] = cell;
    (_cols[cell.columnId] ??= {})[cell.rowId] = cell;
    _colVersions[cell.columnId] = ++_versions;
    if (_isFormula(cell)) _formulas[cell.id] = cell;
    if (cell.content != null) {
      _contentCount++;
      if (keep) return;
      if (_increment(_rowContent, cell.rowId) == 1 && _extentValid) {
        _grownRows.add(cell.rowId);
      }
      if (_increment(_colContent, cell.columnId) == 1 && _extentValid) {
        _grownCols.add(cell.columnId);
      }
    }
  }

  static int _increment(Map<String, int> counts, String id) =>
      counts[id] = (counts[id] ?? 0) + 1;

  /// Decrements; true when [id] has no content cell left.
  static bool _decrement(Map<String, int> counts, String id) {
    final n = (counts[id] ?? 0) - 1;
    if (n > 0) {
      counts[id] = n;
      return false;
    }
    counts.remove(id);
    return true;
  }

  /// Removes a cell by id; returns the removed record.
  CellRecord? remove(String id) {
    final old = _byId[id];
    if (old != null) _detach(old);
    return old;
  }

  void _detach(CellRecord c, {bool keepCounts = false}) {
    _byId.remove(c.id);
    final r = _rows[c.rowId];
    if (r != null) {
      r.remove(c.columnId);
      if (r.isEmpty) _rows.remove(c.rowId);
    }
    final col = _cols[c.columnId];
    if (col != null) {
      col.remove(c.rowId);
      if (col.isEmpty) _cols.remove(c.columnId);
    }
    _colVersions[c.columnId] = ++_versions;
    _formulas.remove(c.id);
    if (c.content != null) {
      _contentCount--;
      if (keepCounts) return;
      if (_decrement(_rowContent, c.rowId)) {
        _grownRows.remove(c.rowId);
        if (c.rowId == _lastRowId) _extentValid = false;
      }
      if (_decrement(_colContent, c.columnId)) {
        _grownCols.remove(c.columnId);
        if (c.columnId == _lastColId) _extentValid = false;
      }
    }
  }

  /// Removes every cell of a row; returns them.
  List<CellRecord> removeRow(String rowId) {
    final cells = List.of(_rows[rowId]?.values ?? const <CellRecord>[]);
    for (final c in cells) {
      _detach(c);
    }
    return cells;
  }

  /// Removes every cell of a column; returns them.
  List<CellRecord> removeColumn(String colId) {
    final cells = List.of(_cols[colId]?.values ?? const <CellRecord>[]);
    for (final c in cells) {
      _detach(c);
    }
    return cells;
  }

  /// Removes all cells.
  void clear() {
    _byId.clear();
    _rows.clear();
    _cols.clear();
    _formulas.clear();
    _contentCount = 0;
    _rowContent.clear();
    _colContent.clear();
    _colVersions.updateAll((_, _) => ++_versions);
    _extentValid = false;
  }

  /// Cells inside the index rectangle, in row-major index order.
  ///
  /// Iterates whichever is smaller: the rows of the rectangle or the stored
  /// cells, so whole-column ranges cost O(non-empty cells).
  Iterable<(int row, int col, CellRecord cell)> cellsIn(
    AxisIndex rows,
    AxisIndex cols,
    int top,
    int left,
    int bottom,
    int right, {
    bool contentOnly = false,
  }) sync* {
    if (_byId.isEmpty) return;
    final rTop = top < 0 ? 0 : top;
    final rBottom = bottom >= rows.length ? rows.length - 1 : bottom;
    final cLeft = left < 0 ? 0 : left;
    final cRight = right >= cols.length ? cols.length - 1 : right;
    if (rBottom < rTop || cRight < cLeft) return;
    final rowSpan = rBottom - rTop + 1;
    if (rowSpan <= _rows.length) {
      for (var r = rTop; r <= rBottom; r++) {
        final rowCells = _rows[rows.idAt(r)];
        if (rowCells == null) continue;
        yield* _rowCells(r, rowCells, cols, cLeft, cRight, contentOnly);
      }
    } else {
      final hits = <(int, String)>[];
      for (final rowId in _rows.keys) {
        final r = rows.indexOf(rowId);
        if (r >= rTop && r <= rBottom) hits.add((r, rowId));
      }
      hits.sort((a, b) => a.$1.compareTo(b.$1));
      for (final (r, rowId) in hits) {
        yield* _rowCells(r, _rows[rowId]!, cols, cLeft, cRight, contentOnly);
      }
    }
  }

  Iterable<(int, int, CellRecord)> _rowCells(
    int r,
    Map<String, CellRecord> rowCells,
    AxisIndex cols,
    int cLeft,
    int cRight,
    bool contentOnly,
  ) sync* {
    final colSpan = cRight - cLeft + 1;
    if (colSpan <= rowCells.length) {
      for (var c = cLeft; c <= cRight; c++) {
        final cell = rowCells[cols.idAt(c)];
        if (cell == null || (contentOnly && cell.content == null)) continue;
        yield (r, c, cell);
      }
    } else {
      final hits = <(int, CellRecord)>[];
      for (final cell in rowCells.values) {
        if (contentOnly && cell.content == null) continue;
        final c = cols.indexOf(cell.columnId);
        if (c >= cLeft && c <= cRight) hits.add((c, cell));
      }
      hits.sort((a, b) => a.$1.compareTo(b.$1));
      for (final (c, cell) in hits) {
        yield (r, c, cell);
      }
    }
  }

  /// [cellsIn] with a callback: same cells in the same order, without the generator and
  /// record allocations (range reads of the formula engine).
  void forEachIn(
    AxisIndex rows,
    AxisIndex cols,
    int top,
    int left,
    int bottom,
    int right,
    void Function(int row, int col, CellRecord cell) visit, {
    bool contentOnly = false,
  }) {
    if (_byId.isEmpty) return;
    final rTop = top < 0 ? 0 : top;
    final rBottom = bottom >= rows.length ? rows.length - 1 : bottom;
    final cLeft = left < 0 ? 0 : left;
    final cRight = right >= cols.length ? cols.length - 1 : right;
    if (rBottom < rTop || cRight < cLeft) return;
    final rowSpan = rBottom - rTop + 1;
    if (rowSpan <= _rows.length) {
      for (var r = rTop; r <= rBottom; r++) {
        final rowCells = _rows[rows.idAt(r)];
        if (rowCells == null) continue;
        _forEachInRow(r, rowCells, cols, cLeft, cRight, contentOnly, visit);
      }
    } else {
      final hits = <(int, String)>[];
      for (final rowId in _rows.keys) {
        final r = rows.indexOf(rowId);
        if (r >= rTop && r <= rBottom) hits.add((r, rowId));
      }
      hits.sort((a, b) => a.$1.compareTo(b.$1));
      for (final (r, rowId) in hits) {
        _forEachInRow(
          r,
          _rows[rowId]!,
          cols,
          cLeft,
          cRight,
          contentOnly,
          visit,
        );
      }
    }
  }

  static void _forEachInRow(
    int r,
    Map<String, CellRecord> rowCells,
    AxisIndex cols,
    int cLeft,
    int cRight,
    bool contentOnly,
    void Function(int row, int col, CellRecord cell) visit,
  ) {
    final colSpan = cRight - cLeft + 1;
    if (colSpan <= rowCells.length) {
      for (var c = cLeft; c <= cRight; c++) {
        final cell = rowCells[cols.idAt(c)];
        if (cell == null || (contentOnly && cell.content == null)) continue;
        visit(r, c, cell);
      }
    } else if (rowCells.length == 1) {
      final cell = rowCells.values.first;
      if (contentOnly && cell.content == null) return;
      final c = cols.indexOf(cell.columnId);
      if (c >= cLeft && c <= cRight) visit(r, c, cell);
    } else {
      final hits = <(int, CellRecord)>[];
      for (final cell in rowCells.values) {
        if (contentOnly && cell.content == null) continue;
        final c = cols.indexOf(cell.columnId);
        if (c >= cLeft && c <= cRight) hits.add((c, cell));
      }
      hits.sort((a, b) => a.$1.compareTo(b.$1));
      for (final (c, cell) in hits) {
        visit(r, c, cell);
      }
    }
  }

  /// The bounding rectangle `(bottomRow, rightCol)` of cells with content
  /// (or any cell when [includeFormatOnly]), as indices; null when empty.
  ///
  /// The content extent is maintained incrementally: O(1) after edits that don't empty the
  /// last row or column, O(rows and columns with content) after structural changes.
  (int lastRow, int lastCol)? usedExtent(
    AxisIndex rows,
    AxisIndex cols, {
    bool includeFormatOnly = false,
  }) {
    if (!includeFormatOnly) return _contentExtent(rows, cols);
    var lastRow = -1;
    var lastCol = -1;
    for (final id in _rows.keys) {
      final r = rows.indexOf(id);
      if (r > lastRow) lastRow = r;
    }
    for (final id in _cols.keys) {
      final c = cols.indexOf(id);
      if (c > lastCol) lastCol = c;
    }
    if (lastRow < 0 || lastCol < 0) return null;
    return (lastRow, lastCol);
  }

  AxisIndex? _extentRows;
  AxisIndex? _extentCols;

  (int, int)? _contentExtent(AxisIndex rows, AxisIndex cols) {
    final rowsGen = rows.generation, colsGen = cols.generation;
    if (!_extentValid ||
        !identical(rows, _extentRows) ||
        !identical(cols, _extentCols) ||
        rowsGen != _extentRowsGen ||
        colsGen != _extentColsGen) {
      _lastRowId = _last(_rowContent.keys, rows);
      _lastColId = _last(_colContent.keys, cols);
      _extentRows = rows;
      _extentCols = cols;
      _extentRowsGen = rowsGen;
      _extentColsGen = colsGen;
      _extentValid = true;
    } else {
      if (_grownRows.isNotEmpty) {
        _lastRowId = _last(_grownRows, rows, _lastRowId);
      }
      if (_grownCols.isNotEmpty) {
        _lastColId = _last(_grownCols, cols, _lastColId);
      }
    }
    _grownRows.clear();
    _grownCols.clear();
    final r = _lastRowId == null ? -1 : rows.indexOf(_lastRowId!);
    final c = _lastColId == null ? -1 : cols.indexOf(_lastColId!);
    if (r < 0 || c < 0) return null;
    return (r, c);
  }

  /// The id among [ids] (and [current]) with the largest index on [axis] (ids missing
  /// from the axis never win); null when none is on the axis.
  static String? _last(
    Iterable<String> ids,
    AxisIndex axis, [
    String? current,
  ]) {
    var best = current;
    var bestIndex = current == null ? -1 : axis.indexOf(current);
    for (final id in ids) {
      final i = axis.indexOf(id);
      if (i > bestIndex) {
        bestIndex = i;
        best = id;
      }
    }
    return bestIndex < 0 ? null : best;
  }
}
