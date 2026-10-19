import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import 'row_loading.dart';

/// Keeps writes safe while a spreadsheet streams in (viewport-first
/// loading, Sheets 02 §6): an operation may only touch rows whose cells are
/// in memory, and operations that read whole ranges or sheets (sort, find
/// and replace, shifting cells, …) wait until the rows they read are
/// loaded. Without this, a format applied to a not-yet-loaded cell would be
/// planned as a new cell and overwrite its stored content, and a sort would
/// see only part of the data.
abstract final class LoadingGate {
  /// Machine code of the refusal (`PlanException.code`).
  static const code = 'still_loading';

  /// Message of the refusal.
  static const message = 'Still loading this part of the sheet…';

  /// Throws [PlanException] when [op] (planned as [plan]) must wait for
  /// rows that are not loaded yet.
  static void check(
    SheetsOperation op,
    MutationPlan plan,
    WorkbookModel model,
    WorkbookRowLoading loading,
  ) {
    if (loading.complete) return;
    checkRanges(op, model, loading);
    for (final c in plan.changes) {
      if (c.table != SheetsTables.cell) continue;
      final current = c.op == RowOp.insert
          ? null
          : model.currentColumns(c.table, c.rowId);
      final sheetId =
          c.columnsAfter[Cols.sheetId] ??
          c.columnsBefore[Cols.sheetId] ??
          current?[Cols.sheetId];
      final rowId =
          c.columnsAfter[CellCols.rowId] ??
          c.columnsBefore[CellCols.rowId] ??
          current?[CellCols.rowId];
      if (sheetId == null || rowId == null) continue;
      if (!loading.isRowLoaded('$sheetId', '$rowId')) _refuse();
    }
  }

  /// The part of [check] that needs no plan: the sheets and ranges [op]
  /// names (the editor's write gate, before a cell editor opens).
  static void checkRanges(
    SheetsOperation op,
    WorkbookModel model,
    WorkbookRowLoading loading,
  ) {
    if (loading.complete) return;
    switch (_wholeSheets(op)) {
      case null:
        break;
      case final sheets when sheets.isEmpty:
        _refuse();
      case final sheets:
        for (final s in sheets) {
          if (!loading.isSheetLoaded(s)) _refuse();
        }
    }
    // Deleted rows must be loaded: the planner lists their cells from the
    // model, so unloaded cells would be cascaded instead of listed and undo
    // couldn't restore them (RevLog spec 06 §5.5).
    if (op case DeleteDimension(
      :final sheetId,
      dimension: Dimension.rows,
      :final ids,
    ) when !loading.isSheetLoaded(sheetId)) {
      for (final id in ids) {
        if (!loading.isRowLoaded(sheetId, id)) _refuse();
      }
    }
    for (final (sheetId, rect) in _rects(op)) {
      final sheet = model.sheet(sheetId);
      if (sheet == null || loading.isSheetLoaded(sheetId)) continue;
      final bottom = rect.bottom < sheet.rows.length
          ? rect.bottom
          : sheet.rows.length - 1;
      for (var r = rect.top < 0 ? 0 : rect.top; r <= bottom; r++) {
        if (!loading.isRowLoaded(sheetId, sheet.rows.idAt(r))) _refuse();
      }
    }
  }

  static Never _refuse() => throw const PlanException(code, message);

  /// Sheets [op] reads entirely (empty = every sheet), or null when it only
  /// touches the ranges it names.
  static Set<String>? _wholeSheets(SheetsOperation op) => switch (op) {
    FindReplace(:final onlyCell, :final range, :final sheetIds)
        when onlyCell == null && range == null =>
      {...?sheetIds},
    ShiftCells(:final range) => {range.sheetId},
    DuplicateSheet(:final sheetId) => {sheetId},
    // Deleting a sheet or columns lists every cell of the sheet (06 §5.5).
    DeleteSheet(:final sheetId) => {sheetId},
    DeleteDimension(:final sheetId, dimension: Dimension.columns) => {sheetId},
    _ => null,
  };

  /// The cell rectangles [op] reads or writes.
  static List<(String, GridRect)> _rects(SheetsOperation op) => switch (op) {
    SetCellInputs(:final sheetId, :final row, :final col, :final inputs) => [
      (
        sheetId,
        GridRect(
          row,
          col,
          row + (inputs.isEmpty ? 0 : inputs.length - 1),
          col +
              (inputs.isEmpty || inputs.first.isEmpty
                  ? 0
                  : inputs.first.length - 1),
        ),
      ),
    ],
    SetNote(:final sheetId, :final row, :final col) => [
      (sheetId, GridRect(row, col, row, col)),
    ],
    InsertCheckboxes(:final sheetId, :final ranges) => [
      for (final r in ranges) (sheetId, r),
    ],
    PasteClipboard(:final target) => [(target.sheetId, target.rect)],
    FindReplace(:final onlyCell?) => [
      (
        onlyCell.$1,
        GridRect(onlyCell.$2, onlyCell.$3, onlyCell.$2, onlyCell.$3),
      ),
    ],
    FindReplace(:final range?) ||
    SortRange(:final range) ||
    RandomizeRange(:final range) ||
    RemoveDuplicates(:final range) ||
    SplitTextToColumns(:final range) => [(range.sheetId, range.rect)],
    MoveRange(
      :final source,
      :final destSheetId,
      :final destRow,
      :final destCol,
    ) =>
      [
        (source.sheetId, source.rect),
        (
          destSheetId,
          GridRect(
            destRow,
            destCol,
            destRow + source.rect.bottom - source.rect.top,
            destCol + source.rect.right - source.rect.left,
          ),
        ),
      ],
    FillSeries(:final sheetId, :final source, :final target) => [
      (sheetId, source),
      (sheetId, target),
    ],
    TrimWhitespace(:final ranges) ||
    ClearRanges(:final ranges) ||
    SetLink(:final ranges) ||
    SetFormat(:final ranges) ||
    ToggleFormat(:final ranges) ||
    SetBorders(:final ranges) ||
    ClearFormatting(:final ranges) ||
    AdjustDecimals(:final ranges) ||
    StepFontSize(:final ranges) ||
    MergeCells(:final ranges) => [for (final r in ranges) (r.sheetId, r.rect)],
    _ => const [],
  };
}
