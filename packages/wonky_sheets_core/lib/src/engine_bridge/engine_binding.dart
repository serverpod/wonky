import '../addressing/grid_geometry.dart';
import '../formula/recalc/engine_types.dart';
import '../formula/recalc/formula_engine.dart';
import '../model/events.dart';
import '../model/schema.dart';
import '../model/workbook_model.dart';
import 'model_workbook_view.dart';

/// Forwards [WorkbookModel] change batches to a [FormulaEngine] (05 §7.1
/// change ingestion): content changes, axis inserts/deletes/moves (diffed
/// against the previous id order), sheet list, names and calc settings.
///
/// Used by the client `RecalcHost` and the server `HeadlessWorkbook`.
final class ModelEngineBinding {
  /// Binds [engine] (built over [view]) to [model]; call [dispose] to detach.
  ModelEngineBinding(this.model, this.engine, this.view) {
    _snapshotAll();
    model.addListener(_onBatch);
  }

  /// Creates a view, an engine (with [engineFactory]) and the binding.
  static ModelEngineBinding create(
    WorkbookModel model, {
    FormulaEngine Function(ModelWorkbookView view)? engineFactory,
  }) {
    final view = ModelWorkbookView(model);
    final engine = engineFactory?.call(view) ?? FormulaEngine(workbook: view);
    return ModelEngineBinding(model, engine, view);
  }

  final WorkbookModel model;
  final FormulaEngine engine;
  final ModelWorkbookView view;

  final Map<(String, Dimension), List<String>> _order = {};

  void _snapshotAll() {
    for (final s in model.sheets) {
      _order[(s.id, Dimension.rows)] = List.of(s.rows.ids);
      _order[(s.id, Dimension.columns)] = List.of(s.columns.ids);
    }
  }

  /// Stops listening.
  void dispose() => model.removeListener(_onBatch);

  void _onBatch(WorkbookChangeBatch batch) {
    // Sheets and axis order first: content positions and the engine's range
    // index must reflect the new structure before content changes are ingested
    // (a batch may insert rows and fill them, or undo a delete with its cells).
    for (final e in batch.events) {
      if (e is SheetsChanged) _sheets(e);
    }
    for (final e in batch.events) {
      if (e is StructureChanged && e.order) _axis(e.sheetId, e.dimension);
    }
    for (final e in batch.events) {
      switch (e) {
        case SpreadsheetChanged(:final columns):
          if (columns.any(_calcColumns.contains)) {
            engine.settingsChanged(view.settings);
          }
        case SheetsChanged():
          break;
        case StructureChanged(:final sheetId, :final dimension):
          if (e.sizes && dimension == Dimension.rows) {
            engine.filterVisibilityChanged(sheetId);
          }
          if (e.sizes && dimension == Dimension.columns) {
            engine.axisChanged(
              sheetId,
              GridDimension.columns,
              const AxisChange.resized(),
            );
          }
        case CellsChanged(:final sheetId):
          final s = model.sheet(sheetId);
          if (s == null || e.contentKeys.isEmpty) break;
          final positions = <CellPos>[];
          for (final k in e.contentKeys) {
            final r = s.rows.indexOf(k.rowId);
            final c = s.columns.indexOf(k.colId);
            if (r >= 0 && c >= 0) positions.add(CellPos(r, c));
          }
          if (positions.isNotEmpty) engine.cellsChanged(sheetId, positions);
        case NamesChanged(:final names):
          engine.namesChanged(names);
        case RulesChanged():
        case OtherRowsChanged():
          break;
      }
    }
  }

  void _sheets(SheetsChanged e) {
    engine.sheetsChanged();
    for (final id in e.sheetIds) {
      final s = model.sheet(id);
      if (s == null) {
        _order.remove((id, Dimension.rows));
        _order.remove((id, Dimension.columns));
      } else {
        _order.putIfAbsent((id, Dimension.rows), () => List.of(s.rows.ids));
        _order.putIfAbsent((
          id,
          Dimension.columns,
        ), () => List.of(s.columns.ids));
      }
    }
  }

  static const _calcColumns = {
    SpreadsheetCols.locale,
    SpreadsheetCols.timeZone,
    SpreadsheetCols.recalcMode,
    SpreadsheetCols.iterativeCalc,
    SpreadsheetCols.maxIterations,
    SpreadsheetCols.convergenceThreshold,
  };

  /// Diffs the axis order against the previous snapshot and reports deletes,
  /// inserts and moves to the engine. A batch may combine all three (remote
  /// changes, undo), and deletes or inserts need not be contiguous: every
  /// contiguous run is reported on its own so that the engine dirties ranges
  /// spanning each deletion/insertion point.
  ///
  /// Only the window between the common prefix and the common suffix of the
  /// two orders is diffed (ids are unique, so everything outside it survived in
  /// place): a small edit in a long axis costs no hashing of the whole axis.
  void _axis(String sheetId, Dimension d) {
    final s = model.sheet(sheetId);
    if (s == null) return;
    final now = List.of(s.axis(d).ids);
    final before = _order[(sheetId, d)] ?? const <String>[];
    _order[(sheetId, d)] = now;
    final gd = d == Dimension.rows ? GridDimension.rows : GridDimension.columns;
    var lo = 0;
    final common = before.length < now.length ? before.length : now.length;
    while (lo < common && before[lo] == now[lo]) {
      lo++;
    }
    var beforeEnd = before.length, nowEnd = now.length;
    while (beforeEnd > lo &&
        nowEnd > lo &&
        before[beforeEnd - 1] == now[nowEnd - 1]) {
      beforeEnd--;
      nowEnd--;
    }
    final nowIndex = {for (var i = lo; i < nowEnd; i++) now[i]: i};
    final beforeSet = {for (var i = lo; i < beforeEnd; i++) before[i]};

    // Deletes: runs of consecutive deleted ids in the old order. The reported
    // index is where the gap is in the new order (after the last surviving
    // predecessor; the common prefix survived in place).
    var i = lo;
    while (i < beforeEnd) {
      if (nowIndex.containsKey(before[i])) {
        i++;
        continue;
      }
      final start = i;
      while (i < beforeEnd && !nowIndex.containsKey(before[i])) {
        i++;
      }
      var gap = lo;
      for (var k = start - 1; k >= lo; k--) {
        final p = nowIndex[before[k]];
        if (p != null) {
          gap = p + 1;
          break;
        }
      }
      engine.axisChanged(
        sheetId,
        gd,
        AxisChange.deleted(gap, i - start, before.sublist(start, i)),
      );
    }

    // Inserts: runs of consecutive new ids in the new order.
    i = lo;
    while (i < nowEnd) {
      if (beforeSet.contains(now[i])) {
        i++;
        continue;
      }
      final start = i;
      while (i < nowEnd && !beforeSet.contains(now[i])) {
        i++;
      }
      engine.axisChanged(sheetId, gd, AxisChange.inserted(start, i - start));
    }

    // Moves: surviving ids whose relative order changed.
    final survivedBefore = [
      for (var k = lo; k < beforeEnd; k++)
        if (nowIndex.containsKey(before[k])) before[k],
    ];
    final survivedNow = [
      for (var k = lo; k < nowEnd; k++)
        if (beforeSet.contains(now[k])) now[k],
    ];
    final moved = <String>[
      for (var k = 0; k < survivedNow.length; k++)
        if (survivedBefore[k] != survivedNow[k]) survivedNow[k],
    ];
    if (moved.isNotEmpty) {
      engine.axisChanged(sheetId, gd, AxisChange.moved(moved));
    }
  }
}
