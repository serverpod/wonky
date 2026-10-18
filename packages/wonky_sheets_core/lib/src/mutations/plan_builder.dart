import 'dart:math';

import 'package:wonky_sync_models/ids.dart';

import '../addressing/grid_geometry.dart';
import '../engine_bridge/formula_hooks.dart';
import '../formula/model/workbook_view.dart' show CellSource;
import '../format/attributes.dart';
import '../model/grid_range.dart';
import '../model/schema.dart';
import '../model/workbook_model.dart';
import 'row_change.dart';

/// Thrown when an operation is refused (UI dialog / MCP error).
final class PlanException implements Exception {
  /// Creates the exception.
  const PlanException(this.code, this.message, {this.details = const {}});

  /// Machine code (`invalid_range`, `invalid_argument`, `duplicate_name`,
  /// `cell_limit_exceeded`, `merge_conflict`, `not_found`, `unsupported`,
  /// `formula_parse_error`, `protected_range`, …).
  final String code;

  /// Human-readable message (Sheets wording where specified).
  final String message;

  /// Extra details.
  final Map<String, Object?> details;

  @override
  String toString() => 'PlanException($code): $message';
}

/// Inputs every plan needs besides the operation and the model.
final class PlanContext {
  /// Creates a context.
  PlanContext({
    required this.userId,
    required this.now,
    IdGenerator? ids,
    this.formulas,
    this.values,
    this.locale,
    this.random,
    this.maxCells = 1000000,
    this.isOwner = false,
    this.customLists = const [],
    this.overlays,
  }) : ids = ids ?? const UuidV7IdGenerator();

  /// Acting user (UUID string).
  final String userId;

  /// Time stamp for `createdAt` of new rows (inject for determinism).
  final DateTime now;

  /// Generator of new entity ids.
  final IdGenerator ids;

  /// Formula codec/rewriter (required by operations that touch formulas).
  final FormulaHooks? formulas;

  /// Computed values (sort, paste values, dedupe, find).
  final CellSource? values;

  /// Input/display locale (defaults to the spreadsheet locale).
  final String? locale;

  /// Randomness (randomize range); defaults to `Random.secure()`.
  final Random? random;

  /// `sheets.maxCellsPerSpreadsheet` (grid size limit).
  final int maxCells;

  /// Whether the user owns the spreadsheet (protections).
  final bool isOwner;

  /// User custom fill lists.
  final List<List<String>> customLists;

  /// Spill and pivot output rectangles of a sheet (from the engine's overlay
  /// index). Sort, randomize and remove duplicates refuse ranges that
  /// intersect them (07 §2.3); without it no overlay check is made.
  final Iterable<GridRect> Function(String sheetId)? overlays;
}

/// Accumulates row writes against an overlay of the model so later steps of
/// one operation see earlier ones. [build] diffs the overlay against the model
/// and emits one [RowChange] per touched row (insert, update naming only
/// changed columns, or delete), parents first for inserts and children first
/// for deletes.
final class PlanBuilder {
  /// Creates a builder.
  PlanBuilder(this.model, this.ctx);

  /// The model the plan is computed against.
  final WorkbookModel model;

  /// The context.
  final PlanContext ctx;

  final Map<String, Map<String, Map<String, Object?>?>> _overlay = {};
  final List<(String table, String id)> _touchOrder = [];

  /// The change summary (kinds, sheets, ranges).
  final ChangeSummary summary = ChangeSummary();

  /// Warnings for the caller.
  final List<String> warnings = [];

  /// Operation results.
  final Map<String, Object?> result = {};

  /// The spreadsheet locale or the context override.
  String get locale => ctx.locale ?? model.spreadsheet.locale;

  /// Required formula hooks.
  FormulaHooks get formulas {
    final f = ctx.formulas;
    if (f == null) {
      throw const PlanException(
        'unsupported',
        'This operation needs the formula engine',
      );
    }
    return f;
  }

  // ---------------------------------------------------------------------------
  // Reading through the overlay.

  /// Current full columns of a row (overlay-aware), or null if missing/deleted.
  Map<String, Object?>? current(String table, String id) {
    final t = _overlay[table];
    if (t != null && t.containsKey(id)) {
      final v = t[id];
      return v == null ? null : Map.of(v);
    }
    return model.currentColumns(table, id);
  }

  /// Whether [table]/[id] was touched by this plan.
  bool touched(String table, String id) =>
      _overlay[table]?.containsKey(id) ?? false;

  /// Current value of one column.
  Object? currentValue(String table, String id, String column) =>
      current(table, id)?[column];

  /// Current cell columns at (sheetId, rowId, colId), or null.
  Map<String, Object?>? currentCell(
    String sheetId,
    String rowId,
    String colId,
  ) => current(SheetsTables.cell, SheetsIds.cellId(sheetId, rowId, colId));

  /// Current cell content.
  String? currentContent(String sheetId, String rowId, String colId) =>
      currentCell(sheetId, rowId, colId)?[CellCols.content] as String?;

  /// Current cell format (explicit cell attributes only).
  CellFormat currentCellFormat(String sheetId, String rowId, String colId) {
    final c = currentCell(sheetId, rowId, colId);
    if (c == null) return CellFormat.empty;
    return CellFormat.fromMap(c);
  }

  /// All touched rows of [table] with their final columns (null = deleted).
  Map<String, Map<String, Object?>?> touchedRows(String table) =>
      _overlay[table] ?? const {};

  // ---------------------------------------------------------------------------
  // Writing.

  void _touch(String table, String id) {
    final t = _overlay.putIfAbsent(table, () => {});
    if (!t.containsKey(id)) {
      _touchOrder.add((table, id));
      final cur = model.currentColumns(table, id);
      t[id] = cur;
    }
  }

  /// Inserts a new row (or revives/replaces an existing one) with [columns].
  void insert(String table, String id, Map<String, Object?> columns) {
    _touch(table, id);
    _overlay[table]![id] = {Cols.createdAt: ctx.now, ...columns, Cols.id: id};
  }

  /// Updates columns of an existing row (no-op if the row is missing).
  void update(String table, String id, Map<String, Object?> columns) {
    if (columns.isEmpty) return;
    final cur = current(table, id);
    if (cur == null) return;
    _touch(table, id);
    _overlay[table]![id] = {...cur, ...columns};
  }

  /// Deletes a row (no-op if missing).
  void delete(String table, String id) {
    if (current(table, id) == null) return;
    _touch(table, id);
    _overlay[table]![id] = null;
  }

  /// Writes cell columns at (sheetId, rowId, colId), creating the cell row with
  /// its deterministic id when needed. A cell whose fields all become null is
  /// deleted.
  void writeCell(
    String sheetId,
    String rowId,
    String colId,
    Map<String, Object?> columns,
  ) {
    if (columns.isEmpty) return;
    final id = SheetsIds.cellId(sheetId, rowId, colId);
    writeCellOf(
      id,
      sheetId,
      rowId,
      colId,
      columns,
      current(SheetsTables.cell, id),
    );
  }

  /// [writeCell] for a caller that has the cell's [id] and its [cur]rent
  /// columns already (bulk writes hash each cell id once).
  void writeCellOf(
    String id,
    String sheetId,
    String rowId,
    String colId,
    Map<String, Object?> columns,
    Map<String, Object?>? cur,
  ) {
    if (columns.isEmpty) return;
    if (cur == null) {
      if (columns.values.every((v) => v == null)) return;
      insert(SheetsTables.cell, id, {
        Cols.sheetId: sheetId,
        CellCols.rowId: rowId,
        CellCols.columnId: colId,
        ...columns,
      });
    } else {
      update(SheetsTables.cell, id, columns);
    }
  }

  /// Writes a cell at current indices of [sheetId].
  void writeCellAt(
    String sheetId,
    int row,
    int col,
    Map<String, Object?> columns,
  ) {
    final s = model.sheet(sheetId)!;
    writeCell(sheetId, s.rows.idAt(row), s.columns.idAt(col), columns);
  }

  /// Deletes the cell row at (sheetId, rowId, colId) if it exists.
  void deleteCell(String sheetId, String rowId, String colId) =>
      delete(SheetsTables.cell, SheetsIds.cellId(sheetId, rowId, colId));

  /// Records a range in the summary.
  void addRange(GridRange r) => summary.addRange(r.toJson());

  /// Records a resolved range in the summary.
  void addResolvedRange(ResolvedRange r) {
    final s = model.sheet(r.sheetId);
    if (s == null) return;
    summary.sheets.add(r.sheetId);
    addRange(
      s.gridRange(r.rect, wholeRows: r.wholeRows, wholeColumns: r.wholeColumns),
    );
  }

  /// Adds change kinds.
  void kinds(Iterable<String> k) => summary.kinds.addAll(k);

  // ---------------------------------------------------------------------------
  // Building.

  static const Set<String> _cellValueColumns = {
    CellCols.content,
    CellCols.note,
    CellCols.numberFormat,
    CellCols.fontFamily,
    CellCols.fontSize,
    CellCols.bold,
    CellCols.italic,
    CellCols.underline,
    CellCols.strikethrough,
    CellCols.textColor,
    CellCols.fillColor,
    CellCols.hAlign,
    CellCols.vAlign,
    CellCols.wrap,
    CellCols.rotation,
    CellCols.borderTop,
    CellCols.borderRight,
    CellCols.borderBottom,
    CellCols.borderLeft,
    CellCols.linkUrl,
  };

  static bool _cellIsBlank(Map<String, Object?> c) =>
      _cellValueColumns.every((k) => c[k] == null);

  static bool _eq(Object? a, Object? b) {
    if (a is num && b is num) return a.toDouble() == b.toDouble();
    if (a is DateTime && b is DateTime) return a.isAtSameMomentAs(b);
    if (a is Enum) a = a.name;
    if (b is Enum) b = b.name;
    return a == b;
  }

  /// Finalizes the plan.
  MutationPlan build(String label, {Iterable<String> kinds = const []}) {
    summary.kinds.addAll(kinds);
    final deletes = <RowChange>[];
    final upserts = <RowChange>[];
    final details = <Map<String, Object?>>[];
    var detailOverflow = false;
    for (final (table, id) in _touchOrder) {
      final original = model.currentColumns(table, id);
      var fin = _overlay[table]![id];
      if (fin != null && table == SheetsTables.cell && _cellIsBlank(fin)) {
        fin = null;
      }
      if (original == null && fin == null) continue;
      if (original == null) {
        upserts.add(RowChange.insert(table, id, fin!));
        _structureSummary(table, id, revived: true);
      } else if (fin == null) {
        deletes.add(RowChange.delete(table, id, original));
        _structureSummary(table, id, revived: false);
      } else {
        final before = <String, Object?>{};
        final after = <String, Object?>{};
        fin.forEach((k, v) {
          if (k == Cols.id) return;
          if (!_eq(original[k], v)) {
            before[k] = original[k];
            after[k] = v is Enum ? v.name : v;
          }
        });
        if (after.isEmpty) continue;
        upserts.add(RowChange.update(table, id, before, after));
      }
      if (table == SheetsTables.cell) {
        final b = original?[CellCols.content] as String?;
        final a = fin?[CellCols.content] as String?;
        if (b != a) {
          if (details.length < MutationPlan.maxDetailCells) {
            final src = fin ?? original!;
            details.add({
              's': src[Cols.sheetId],
              'r': src[CellCols.rowId],
              'c': src[CellCols.columnId],
              'b': b,
              'a': a,
            });
          } else {
            detailOverflow = true;
          }
        }
        final src = fin ?? original!;
        summary.sheets.add(src[Cols.sheetId].toString());
      }
    }
    // Stable sorts: parents first for inserts/updates, children first for
    // deletes.
    final up = _byRank(upserts);
    final del = _byRank(deletes, descending: true);
    return MutationPlan(
      label: label,
      summary: summary,
      changes: [...del, ...up],
      detail: detailOverflow || details.isEmpty ? null : {'cells': details},
      warnings: List.of(warnings),
      result: Map.of(result),
    );
  }

  void _structureSummary(String table, String id, {required bool revived}) {
    final kind = switch (table) {
      SheetsTables.sheetRow => 'rows',
      SheetsTables.sheetColumn => 'cols',
      SheetsTables.sheet => 'sheets',
      _ => null,
    };
    if (kind == null) return;
    if (revived) {
      // New or revived entities are reported only when they existed before
      // (revivals); plain inserts are not listed.
      return;
    }
    summary.addDeleted(kind, id);
  }

  /// [changes] ordered by table rank, stable (a bucket per rank: a 1M-cell
  /// plan is one pass, not a comparison sort).
  static List<RowChange> _byRank(
    List<RowChange> changes, {
    bool descending = false,
  }) {
    if (changes.length < 2) return changes;
    final buckets = <int, List<RowChange>>{};
    String? lastTable;
    List<RowChange>? last;
    for (final c in changes) {
      if (!identical(c.table, lastTable) && c.table != lastTable) {
        lastTable = c.table;
        last = buckets[SheetsTables.rank(c.table)] ??= [];
      }
      last!.add(c);
    }
    if (buckets.length == 1) return last!;
    final ranks = buckets.keys.toList()
      ..sort((a, b) => descending ? b.compareTo(a) : a.compareTo(b));

    return [for (final r in ranks) ...buckets[r]!];
  }
}
