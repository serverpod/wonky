import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

/// The protection-relevant writes of an operation (07 §10.3 `WriteIntent`s).
///
/// Row/column structure operations are described by the operation itself
/// (so that boundary repairs of unrelated rule ranges don't count as rule
/// writes); everything else is derived from the planned row changes, which
/// covers every write path (typing, paste, fill, sort, find-replace,
/// formats, rules, sheet properties, objects) with one implementation.
abstract final class WriteIntents {
  /// Intents of [op]; [plan] plans it without applying (called only for
  /// operations that are not structural).
  static OperationWrites of(
    SheetsOperation op,
    WorkbookModel model,
    MutationPlan Function() plan,
  ) {
    List<WriteIntent> intents;
    switch (op) {
      case InsertDimension():
        return _insert(op, model);
      case DeleteDimension(:final sheetId, :final dimension, :final ids):
        intents = _structural(
          model,
          sheetId,
          dimension,
          ids,
          StructuralOp.delete,
        );
      case MoveDimension(:final sheetId, :final dimension, :final ids):
        intents = _structural(
          model,
          sheetId,
          dimension,
          ids,
          StructuralOp.move,
        );
      case ShiftCells(:final range, :final direction):
        intents = _shift(model, range, direction);
      // Resize, hide and outline groups are allowed (Sheets parity).
      case SetDimensionHidden() || ResizeDimension() || GroupOperation():
        intents = const [];
      default:
        intents = fromChanges(plan().changes, model);
    }
    return (intents: intents, inserts: const <InsertBetween>[]);
  }

  static OperationWrites _insert(InsertDimension op, WorkbookModel model) {
    final s = model.sheet(op.sheetId);
    if (s == null) return (intents: const [], inserts: const []);
    final length = op.dimension == Dimension.rows
        ? s.rows.length
        : s.columns.length;
    // Inserting changes a protection only when it lands inside it: the
    // line before and the line at the insertion point are both protected
    // (whole-sheet protections always are).
    if (op.at <= 0 || op.at >= length) {
      return (
        intents: [
          if (s.protections.values.any((p) => p.rangeJson == null))
            Structural(s.id, op.dimension, [
              op.at.clamp(0, length - 1),
            ], StructuralOp.insert),
        ],
        inserts: const [],
      );
    }
    return (
      intents: const [],
      inserts: [InsertBetween(s.id, op.dimension, op.at - 1, op.at)],
    );
  }

  static List<WriteIntent> _structural(
    WorkbookModel model,
    String sheetId,
    Dimension dim,
    List<String> ids,
    StructuralOp op,
  ) {
    final s = model.sheet(sheetId);
    if (s == null) return const [];
    final axis = dim == Dimension.rows ? s.rows : s.columns;
    final indices = [
      for (final id in ids)
        if (axis.indexOf(id) case final int i when i >= 0) i,
    ];
    return [if (indices.isNotEmpty) Structural(s.id, dim, indices, op)];
  }

  static List<WriteIntent> _shift(
    WorkbookModel model,
    ResolvedRange range,
    ShiftDirection dir,
  ) {
    final s = model.sheet(range.sheetId);
    final grid = s?.gridRect;
    if (s == null || grid == null) return const [];
    final r = range.rect;
    // Every cell that moves (or is overwritten) to the end of the grid.
    final rect = switch (dir) {
      ShiftDirection.right ||
      ShiftDirection.left => GridRect(r.top, r.left, r.bottom, grid.right),
      ShiftDirection.down ||
      ShiftDirection.up => GridRect(r.top, r.left, grid.bottom, r.right),
    };
    return [
      CellWrites(s.id, [rect]),
    ];
  }

  /// Intents of planned [changes] against the current [model].
  static List<WriteIntent> fromChanges(
    List<RowChange> changes,
    WorkbookModel model,
  ) {
    final cells = <String, Map<int, List<int>>>{};
    final lines = <String, List<GridRect>>{};
    final out = <WriteIntent>[];
    final sheetOps = <String>{};
    final objects = <String>{};
    for (final c in changes) {
      switch (c.table) {
        case SheetsTables.cell:
          final (sid, rowId, colId) = _cellIds(c, model);
          if (sid == null) continue;
          final s = model.sheet(sid);
          if (s == null) continue;
          final row = s.rows.indexOf(rowId!);
          final col = s.columns.indexOf(colId!);
          if (row < 0 || col < 0) continue;
          (cells.putIfAbsent(sid, () => {})[row] ??= []).add(col);
        case SheetsTables.sheetRow || SheetsTables.sheetColumn:
          if (c.op != RowOp.update ||
              !c.touchedColumns.contains(Cols.formatJson)) {
            continue;
          }
          final sid = _sheetOf(c, model);
          final s = sid == null ? null : model.sheet(sid);
          final grid = s?.gridRect;
          if (s == null || grid == null) continue;
          final rows = c.table == SheetsTables.sheetRow;
          final i = rows ? s.rows.indexOf(c.rowId) : s.columns.indexOf(c.rowId);
          if (i < 0) continue;
          lines
              .putIfAbsent(s.id, () => [])
              .add(
                rows
                    ? GridRect(i, grid.left, i, grid.right)
                    : GridRect(grid.top, i, grid.bottom, i),
              );
        case SheetsTables.sheet:
          if (c.op == RowOp.insert) continue;
          final touched = c.touchedColumns.difference({
            SheetCols.printSettingsJson,
          });
          if (touched.isEmpty) continue;
          sheetOps.add(c.rowId);
        case SheetsTables.mergedRange ||
            SheetsTables.conditionalFormatRule ||
            SheetsTables.dataValidationRule ||
            SheetsTables.banding:
          final sid = _sheetOf(c, model);
          final s = sid == null ? null : model.sheet(sid);
          if (s == null) continue;
          final rects = _changedRects(c, model, s);
          if (rects.isEmpty) continue;
          out.add(RuleWrite(s.id, _kind(c.table), rects));
        case SheetsTables.basicFilter:
          final sid = _sheetOf(c, model);
          final s = sid == null ? null : model.sheet(sid);
          if (s == null) continue;
          final rects = _changedRects(c, model, s, symmetric: false);
          final range = RectSet.bounds(rects) ?? s.gridRect;
          if (range == null) continue;
          out.add(FilterWrite(s.id, range));
        case SheetsTables.embeddedObject || SheetsTables.pivotTable:
          final sid = _sheetOf(c, model);
          if (sid != null) objects.add(sid);
      }
    }
    for (final MapEntry(key: sid, value: byRow) in cells.entries) {
      out.add(CellWrites(sid, _runs(byRow)));
    }
    for (final MapEntry(key: sid, value: rects) in lines.entries) {
      out.add(CellWrites(sid, rects));
    }
    for (final sid in sheetOps) {
      out.add(SheetOp(sid, 'sheet'));
    }
    for (final sid in objects) {
      out.add(ObjectWrite(sid));
    }
    return out;
  }

  static (String?, String?, String?) _cellIds(RowChange c, WorkbookModel m) {
    if (c.op == RowOp.insert) {
      final a = c.columnsAfter;
      return (
        a[Cols.sheetId] as String?,
        a[CellCols.rowId] as String?,
        a[CellCols.columnId] as String?,
      );
    }
    if (c.op == RowOp.delete && c.columnsBefore[Cols.sheetId] != null) {
      final b = c.columnsBefore;
      return (
        b[Cols.sheetId] as String?,
        b[CellCols.rowId] as String?,
        b[CellCols.columnId] as String?,
      );
    }
    final rec = m.record(SheetsTables.cell, c.rowId);
    if (rec is! CellRecord) return (null, null, null);
    return (rec.sheetId, rec.rowId, rec.columnId);
  }

  static String? _sheetOf(RowChange c, WorkbookModel m) =>
      (c.columnsAfter[Cols.sheetId] ??
              c.columnsBefore[Cols.sheetId] ??
              m.currentColumns(c.table, c.rowId)?[Cols.sheetId])
          as String?;

  static RuleKind _kind(String table) => switch (table) {
    SheetsTables.mergedRange => RuleKind.merge,
    SheetsTables.conditionalFormatRule => RuleKind.conditionalFormat,
    SheetsTables.dataValidationRule => RuleKind.dataValidation,
    _ => RuleKind.banding,
  };

  static List<GridRect> _rects(SheetModel s, Map<String, Object?>? cols) {
    if (cols == null) return const [];
    final list = cols[Cols.rangesJson];
    final one = cols[Cols.rangeJson];
    final ranges = [
      if (list is String) ...GridRange.parseList(list),
      if (one is String)
        if (GridRange.tryParse(one) case final GridRange r) r,
    ];
    return [
      for (final r in ranges)
        if (s.resolve(r) case final ResolvedRange rr) rr.rect,
    ];
  }

  static bool _hasRange(Map<String, Object?> cols) =>
      cols.containsKey(Cols.rangesJson) || cols.containsKey(Cols.rangeJson);

  /// The cells whose rule changes: for a range-only update the cells that
  /// enter or leave the rule; otherwise every cell of the rule before and
  /// after.
  static List<GridRect> _changedRects(
    RowChange c,
    WorkbookModel m,
    SheetModel s, {
    bool symmetric = true,
  }) {
    switch (c.op) {
      case RowOp.insert:
        return _rects(s, c.columnsAfter);
      case RowOp.delete:
        return _rects(s, c.columnsBefore);
      case RowOp.update:
        final current = m.currentColumns(c.table, c.rowId);
        final before = _hasRange(c.columnsBefore)
            ? _rects(s, c.columnsBefore)
            : _rects(s, current);
        final after = _hasRange(c.columnsAfter)
            ? _rects(s, c.columnsAfter)
            : before;
        final rangeOnly = c.touchedColumns.every(
          (k) => k == Cols.rangesJson || k == Cols.rangeJson,
        );
        if (!symmetric || !rangeOnly) return [...before, ...after];
        return [..._minus(before, after), ..._minus(after, before)];
    }
  }

  static List<GridRect> _minus(List<GridRect> a, List<GridRect> b) {
    var out = a;
    for (final r in b) {
      out = RectSet.subtractAll(out, r);
    }
    return out;
  }

  /// Row-major runs of consecutive columns.
  static List<GridRect> _runs(Map<int, List<int>> byRow) {
    final out = <GridRect>[];
    for (final MapEntry(key: row, value: cols) in byRow.entries) {
      cols.sort();
      var start = cols.first;
      var prev = start;
      for (final c in cols.skip(1)) {
        if (c == prev || c == prev + 1) {
          prev = c;
          continue;
        }
        out.add(GridRect(row, start, row, prev));
        start = prev = c;
      }
      out.add(GridRect(row, start, row, prev));
    }
    return out;
  }
}

/// An insert of rows/columns between the lines [before] and [at] (07
/// §10.3): it changes a protection only when both lines are in it.
final class InsertBetween {
  const InsertBetween(this.sheetId, this.dimension, this.before, this.at);

  final String sheetId;
  final Dimension dimension;
  final int before;
  final int at;

  Structural line(int index) =>
      Structural(sheetId, dimension, [index], StructuralOp.insert);
}

/// The writes of an operation: guard intents plus inserts between lines.
typedef OperationWrites = ({
  List<WriteIntent> intents,
  List<InsertBetween> inserts,
});
