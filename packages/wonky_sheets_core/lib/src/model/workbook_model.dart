import 'dart:async';

import 'package:wonky_sync_models/ids.dart';

import '../addressing/a1.dart';
import '../addressing/grid_geometry.dart';
import '../format/attributes.dart';
import '../format/theme.dart';
import '../mutations/row_change.dart';
import 'events.dart';
import 'grid_range.dart';
import 'records.dart';
import 'schema.dart';
import 'sheet_model.dart';

/// Thrown for unresolvable A1 ranges (MCP `invalid_range`).
final class InvalidRangeException implements Exception {
  /// Creates the exception.
  const InvalidRangeException(this.message);

  /// Human-readable reason.
  final String message;

  @override
  String toString() => 'InvalidRangeException: $message';
}

/// Read interface of a workbook (13 §4.2), implemented by [WorkbookModel] and
/// by read-only snapshot/version models.
abstract interface class WorkbookReader implements CurrentRowReader {
  /// The spreadsheet row (defaults when not loaded yet).
  SpreadsheetRecord get spreadsheet;

  /// Sheets with a `Sheet` row, ordered by `(sortKey, id)` (hidden included).
  List<SheetModel> get sheets;

  /// Sheet by id.
  SheetModel? sheet(String sheetId);

  /// Sheet by name (case-insensitive).
  SheetModel? sheetByName(String name);

  /// Named ranges and named functions.
  Iterable<NamedRangeRecord> get namedRanges;

  /// Named range/function by name (case-insensitive; smaller id wins on duplicates).
  NamedRangeRecord? namedRange(String name);

  /// Resolves an id-based range.
  ResolvedRange? resolve(GridRange r);

  /// Parses an A1 range (`Sheet1!A1:B2`, `'Q3 plan'!B:B`, `A1`, a named range).
  ResolvedRange parseA1(String a1, {String? contextSheetId});

  /// The spreadsheet theme.
  SpreadsheetTheme get theme;

  /// Any synced record by table and id.
  SyncRecord? record(String table, String id);
}

/// A previewed alternating-colors contribution at a cell of a sheet:
/// `(fillColor, headerBold)`, or null to use the stored bandings.
typedef BandingPreview =
    (String?, bool)? Function(SheetModel sheet, int row, int col);

/// The in-memory workbook (02 §6): built from synced rows, patched by local
/// plans and remote merges, and read by the grid, the formula engine, MCP
/// tools, exporters and version history.
final class WorkbookModel implements WorkbookReader {
  /// Creates an empty model for spreadsheet [spreadsheetId].
  WorkbookModel({required this.spreadsheetId});

  /// Builds a model from full rows `(table, columns)` (snapshot or DB load).
  factory WorkbookModel.fromRows(
    String spreadsheetId,
    Iterable<(String table, Map<String, Object?> columns)> rows,
  ) {
    final m = WorkbookModel(spreadsheetId: spreadsheetId);
    m.applyChanges([
      for (final (t, c) in rows) RowChange.insert(t, c[Cols.id].toString(), c),
    ], silent: true);
    return m;
  }

  /// The spreadsheet (space) id.
  final String spreadsheetId;

  SpreadsheetRecord? _spreadsheet;
  final Map<String, SheetModel> _sheets = {};
  List<SheetModel>? _orderedSheets;
  final Map<String, NamedRangeRecord> _named = {};
  Map<String, NamedRangeRecord>? _namedByLower;
  final Map<String, Map<String, GenericRecord>> _other = {};

  // Owner lookups for child rows (by id → sheet id).
  final Map<String, String> _ruleOwner = {};

  final StreamController<WorkbookChangeBatch> _controller =
      StreamController.broadcast(sync: true);
  final List<void Function(WorkbookChangeBatch)> _listeners = [];

  /// Batches of change events, emitted synchronously after each ingestion.
  Stream<WorkbookChangeBatch> get changes => _controller.stream;

  /// Adds a synchronous listener.
  void addListener(void Function(WorkbookChangeBatch batch) listener) =>
      _listeners.add(listener);

  /// Removes a listener.
  void removeListener(void Function(WorkbookChangeBatch batch) listener) =>
      _listeners.remove(listener);

  /// Releases the stream.
  Future<void> dispose() => _controller.close();

  int _version = 0;

  /// Incremented after every applied batch.
  int get version => _version;

  // ---------------------------------------------------------------------------
  // Reading.

  @override
  SpreadsheetRecord get spreadsheet =>
      _spreadsheet ??
      SpreadsheetRecord(id: spreadsheetId, createdAt: kEpochUtc);

  /// Whether the spreadsheet row has been loaded.
  bool get hasSpreadsheetRow => _spreadsheet != null;

  @override
  List<SheetModel> get sheets => _orderedSheets ??= () {
    final list = [
      for (final s in _sheets.values)
        if (s.record != null) s,
    ];
    list.sort(
      (a, b) => FractionalIndex.compare(
        a.record!.sortKey,
        a.id,
        b.record!.sortKey,
        b.id,
      ),
    );
    return List<SheetModel>.unmodifiable(list);
  }();

  /// Visible (non-hidden) sheets in order.
  List<SheetModel> get visibleSheets => [
    for (final s in sheets)
      if (!s.record!.hidden) s,
  ];

  @override
  SheetModel? sheet(String sheetId) {
    final s = _sheets[sheetId];
    return s?.record == null ? null : s;
  }

  /// Sheet by id even when its `Sheet` row has not arrived yet.
  SheetModel? rawSheet(String sheetId) => _sheets[sheetId];

  @override
  SheetModel? sheetByName(String name) {
    final lower = name.toLowerCase();
    SheetModel? best;
    for (final s in sheets) {
      if (s.name.toLowerCase() == lower) {
        if (best == null || s.id.compareTo(best.id) < 0) best = s;
      }
    }
    return best;
  }

  @override
  Iterable<NamedRangeRecord> get namedRanges => _named.values;

  @override
  NamedRangeRecord? namedRange(String name) {
    final map = _namedByLower ??= () {
      final m = <String, NamedRangeRecord>{};
      for (final n in _named.values) {
        final k = n.name.toLowerCase();
        final e = m[k];
        if (e == null || n.id.compareTo(e.id) < 0) m[k] = n;
      }
      return m;
    }();
    return map[name.toLowerCase()];
  }

  @override
  SpreadsheetTheme get theme =>
      previewTheme ?? SpreadsheetTheme.parse(spreadsheet.themeJson);

  /// A theme previewed by the theme panel (06 §13.3): rendering uses it
  /// instead of `themeJson` while set. Never persisted.
  SpreadsheetTheme? previewTheme;

  /// Alternating colors previewed by the banding panel (06 §14.2): when set
  /// and it returns non-null for a cell, that contribution replaces the
  /// stored bandings' one. Never persisted.
  BandingPreview? bandingPreview;

  /// Records of a generic table.
  Iterable<GenericRecord> otherRecords(String table) =>
      _other[table]?.values ?? const [];

  @override
  SyncRecord? record(String table, String id) {
    switch (table) {
      case SheetsTables.spreadsheet:
        return _spreadsheet?.id == id ? _spreadsheet : null;
      case SheetsTables.sheet:
        return _sheets[id]?.record;
      case SheetsTables.namedRange:
        return _named[id];
      case SheetsTables.cell:
        for (final s in _sheets.values) {
          final c = s.cells.byId(id);
          if (c != null) return c;
        }
        return null;
      case SheetsTables.sheetRow:
      case SheetsTables.sheetColumn:
      case SheetsTables.mergedRange:
      case SheetsTables.dimensionGroup:
      case SheetsTables.protectedRange:
      case SheetsTables.conditionalFormatRule:
      case SheetsTables.dataValidationRule:
      case SheetsTables.basicFilter:
      case SheetsTables.filterView:
      case SheetsTables.banding:
      case SheetsTables.embeddedObject:
      case SheetsTables.pivotTable:
        final owner = _ruleOwner['$table:$id'];
        final s = owner == null ? null : _sheets[owner];
        if (s == null) return null;
        return _childMap(s, table)?[id] ??
            (table == SheetsTables.basicFilter && s.basicFilter?.id == id
                ? s.basicFilter
                : null);
      default:
        return _other[table]?[id];
    }
  }

  /// Cell record by sheet and ids (faster than [record]).
  CellRecord? cell(String sheetId, String rowId, String colId) =>
      _sheets[sheetId]?.cells.at(rowId, colId);

  /// Cell at indices.
  CellRecord? cellAt(String sheetId, int row, int col) =>
      _sheets[sheetId]?.cellAt(row, col);

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) =>
      record(table, rowId)?.toColumns();

  @override
  ResolvedRange? resolve(GridRange r) => sheet(r.sheetId)?.resolve(r);

  @override
  ResolvedRange parseA1(String a1, {String? contextSheetId}) {
    final text = a1.trim();
    if (text.isEmpty) throw const InvalidRangeException('Empty range');
    final area = A1Area.tryParse(text);
    if (area == null) {
      // Named range?
      final named = namedRange(text);
      if (named != null && named.rangeJson != null) {
        final g = GridRange.tryParse(named.rangeJson);
        final rr = g == null ? null : resolve(g);
        if (rr != null) return rr;
        throw InvalidRangeException('Named range "$text" does not resolve');
      }
      // A bare sheet name means the whole sheet.
      final unq = text.startsWith("'") && text.endsWith("'") && text.length >= 2
          ? text.substring(1, text.length - 1).replaceAll("''", "'")
          : text;
      final s = sheetByName(unq);
      if (s != null && s.gridRect != null) {
        return ResolvedRange(
          s.id,
          s.gridRect!,
          wholeRows: true,
          wholeColumns: true,
        );
      }
      throw InvalidRangeException('Unable to parse range: $a1');
    }
    SheetModel? s;
    if (area.sheet != null) {
      s = sheetByName(area.sheet!);
      if (s == null) {
        throw InvalidRangeException('Unknown sheet "${area.sheet}"');
      }
    } else if (contextSheetId != null) {
      s = sheet(contextSheetId);
    } else if (sheets.length == 1) {
      s = sheets.first;
    }
    if (s == null) {
      throw InvalidRangeException('Range "$a1" needs a sheet name');
    }
    final rowsN = s.rows.length;
    final colsN = s.columns.length;
    final rect = area.toRect(rowsN, colsN);
    if (rect.top < 0 ||
        rect.left < 0 ||
        rect.bottom >= rowsN ||
        rect.right >= colsN) {
      throw InvalidRangeException(
        'Range $a1 is outside the grid of "${s.name}"',
      );
    }
    return ResolvedRange(
      s.id,
      rect,
      wholeRows: area.kind == A1Kind.rows,
      wholeColumns: area.kind == A1Kind.columns,
    );
  }

  /// A1 text of a resolved range (`'Q3 plan'!A1:B2`; [includeSheet] adds the prefix).
  String a1Of(ResolvedRange r, {bool includeSheet = true}) {
    final s = sheet(r.sheetId);
    final rect = r.rect;
    A1Area area;
    if (r.wholeSheet) {
      area = A1Area.rect(rect.top, rect.left, rect.bottom, rect.right);
    } else if (r.wholeColumns) {
      area = A1Area.columns(rect.left, rect.right);
    } else if (r.wholeRows) {
      area = A1Area.rows(rect.top, rect.bottom);
    } else if (rect.isSingleCell) {
      area = A1Area.cell(rect.top, rect.left);
    } else {
      area = A1Area.rect(rect.top, rect.left, rect.bottom, rect.right);
    }
    return area.withSheet(includeSheet ? s?.name : null).format();
  }

  /// Effective format of the cell at indices (cell ▸ row ▸ column ▸ sheet;
  /// theme defaults are applied by [EffectiveFormatResolver]).
  CellFormat explicitFormatChain(String sheetId, int row, int col) {
    final s = _sheets[sheetId];
    if (s == null) return CellFormat.empty;
    final rowId = s.rows.tryIdAt(row);
    final colId = s.columns.tryIdAt(col);
    var f = s.record?.format ?? CellFormat.empty;
    if (colId != null) {
      f = f.overlay(s.columnRecords[colId]?.format ?? CellFormat.empty);
    }
    if (rowId != null) {
      f = f.overlay(s.rowRecords[rowId]?.format ?? CellFormat.empty);
    }
    if (rowId != null && colId != null) {
      f = f.overlay(s.cells.at(rowId, colId)?.format ?? CellFormat.empty);
    }
    return f;
  }

  // ---------------------------------------------------------------------------
  // Ingestion.

  /// Applies row changes (local plan, remote merge, load) and emits one batch.
  /// Updates of missing rows are treated as upserts of the given columns;
  /// deletes of missing rows are ignored. With [silent], no event is emitted.
  WorkbookChangeBatch applyChanges(
    Iterable<RowChange> changes, {
    bool silent = false,
  }) {
    final b = _BatchBuilder();
    for (final c in changes) {
      switch (c.op) {
        case RowOp.insert:
          _upsert(c.table, c.rowId, c.columnsAfter, b, replace: true);
        case RowOp.update:
          _upsert(c.table, c.rowId, c.columnsAfter, b, replace: false);
        case RowOp.delete:
          _delete(c.table, c.rowId, b);
      }
    }
    final batch = b.build();
    _version++;
    if (!silent && !batch.isEmpty) {
      for (final l in List.of(_listeners)) {
        l(batch);
      }
      _controller.add(batch);
    }
    return batch;
  }

  /// Applies a plan's changes.
  WorkbookChangeBatch applyPlan(MutationPlan plan) =>
      applyChanges(plan.changes);

  /// Inserts or updates one row with [columns].
  WorkbookChangeBatch upsertRow(
    String table,
    String id,
    Map<String, Object?> columns,
  ) => applyChanges([
    RowChange(table: table, rowId: id, op: RowOp.update, columnsAfter: columns),
  ]);

  /// Deletes one row.
  WorkbookChangeBatch deleteRow(String table, String id) =>
      applyChanges([RowChange(table: table, rowId: id, op: RowOp.delete)]);

  SheetModel _sheetFor(String sheetId) =>
      _sheets.putIfAbsent(sheetId, () => SheetModel(sheetId));

  void _upsert(
    String table,
    String id,
    Map<String, Object?> columns,
    _BatchBuilder b, {
    required bool replace,
  }) {
    SyncRecord merge(SyncRecord? existing) {
      if (existing == null || replace) {
        // Inserts carry their id already: no copy per row of a load.
        return recordFromColumns(
          table,
          columns[Cols.id] == id ? columns : {...columns, Cols.id: id},
        );
      }

      return existing.withColumns(columns);
    }

    switch (table) {
      case SheetsTables.spreadsheet:
        final next = merge(_spreadsheet) as SpreadsheetRecord;
        _spreadsheet = next;
        b.spreadsheet(columns.keys);
      case SheetsTables.sheet:
        final existing = _sheets[id]?.record;
        final next = merge(existing) as SheetRecord;
        final s = _sheetFor(id)..record = next;
        s.rows.defaultSize = next.defaultRowHeight;
        s.columns.defaultSize = next.defaultColumnWidth;
        _orderedSheets = null;
        final orderOrNames =
            existing == null ||
            existing.name != next.name ||
            existing.sortKey != next.sortKey ||
            existing.hidden != next.hidden;
        b.sheet(id, orderOrNames: orderOrNames);
        if (existing?.formatJson != next.formatJson) {
          b.structure(id, Dimension.rows, formats: true);
          b.structure(id, Dimension.columns, formats: true);
        }
      case SheetsTables.sheetRow:
      case SheetsTables.sheetColumn:
        final isRow = table == SheetsTables.sheetRow;
        final ownerId = _ownerOf(table, id, columns);
        if (ownerId == null) return;
        final s = _sheetFor(ownerId);
        final recs = isRow ? s.rowRecords : s.columnRecords;
        final existing = recs[id];
        final next = merge(existing) as DimensionRecord;
        recs[id] = next;
        if (existing == null) {
          s.forgetRemoved(isRow ? Dimension.rows : Dimension.columns, id);
        }
        _ruleOwner['$table:$id'] = ownerId;
        (isRow ? s.rows : s.columns).upsert(
          id,
          next.sortKey,
          size: next.size,
          hidden: next.hidden,
        );
        b.structure(
          ownerId,
          isRow ? Dimension.rows : Dimension.columns,
          order: existing == null || existing.sortKey != next.sortKey,
          sizes:
              existing == null ||
              existing.size != next.size ||
              existing.hidden != next.hidden,
          formats: existing?.formatJson != next.formatJson,
        );
      case SheetsTables.cell:
        final ownerId = _ownerOf(table, id, columns);
        if (ownerId == null) return;
        final s = _sheetFor(ownerId);
        final existing = s.cells.byId(id);
        final next = merge(existing) as CellRecord;
        s.cells.put(next);
        b.cell(ownerId, existing, next);
      case SheetsTables.namedRange:
        final next = merge(_named[id]) as NamedRangeRecord;
        final old = _named[id];
        _named[id] = next;
        _namedByLower = null;
        b.names({next.name.toLowerCase(), ?old?.name.toLowerCase()});
      case SheetsTables.mergedRange:
      case SheetsTables.dimensionGroup:
      case SheetsTables.protectedRange:
      case SheetsTables.conditionalFormatRule:
      case SheetsTables.dataValidationRule:
      case SheetsTables.basicFilter:
      case SheetsTables.filterView:
      case SheetsTables.banding:
      case SheetsTables.embeddedObject:
      case SheetsTables.pivotTable:
        final ownerId = _ownerOf(table, id, columns);
        if (ownerId == null) return;
        final s = _sheetFor(ownerId);
        final prevOwner = _ruleOwner['$table:$id'];
        _ruleOwner['$table:$id'] = ownerId;
        if (table == SheetsTables.basicFilter) {
          final existing = s.basicFilter?.id == id ? s.basicFilter : null;
          s.basicFilter = merge(existing) as FilterRecord;
        } else {
          final map = _childMap(s, table)!;
          var existing = map[id];
          // A row whose sheetId changed (an object moved to a chart sheet,
          // 08 §11) moves to its new owner with all its columns.
          if (existing == null && prevOwner != null && prevOwner != ownerId) {
            final old = _sheets[prevOwner];
            if (old != null) {
              existing = _childMap(old, table)!.remove(id);
              final k = _kindOf(table);
              old.invalidateRules(k);
              b.rules(prevOwner, k, id);
            }
          }
          map[id] = merge(existing);
        }
        final kind = _kindOf(table);
        s.invalidateRules(kind);
        b.rules(ownerId, kind, id);
      default:
        final map = _other.putIfAbsent(table, () => {});
        final existing = map[id];
        map[id] = merge(existing) as GenericRecord;
        b.other(table, id);
    }
  }

  void _delete(String table, String id, _BatchBuilder b) {
    switch (table) {
      case SheetsTables.spreadsheet:
        if (_spreadsheet?.id == id) {
          _spreadsheet = null;
          b.spreadsheet(const ['id']);
        }
      case SheetsTables.sheet:
        final s = _sheets[id];
        if (s == null || s.record == null) return;
        s.record = null;
        _orderedSheets = null;
        b.sheet(id, orderOrNames: true);
      // Children stay in memory (cascade is applied by the engine); they are
      // hidden with the sheet and revived with it by undo.
      case SheetsTables.sheetRow:
      case SheetsTables.sheetColumn:
        final ownerId = _ruleOwner.remove('$table:$id');
        if (ownerId == null) return;
        final s = _sheets[ownerId]!;
        final isRow = table == SheetsTables.sheetRow;
        final gone = (isRow ? s.rowRecords : s.columnRecords).remove(id);
        if (gone != null) {
          s.rememberRemoved(
            isRow ? Dimension.rows : Dimension.columns,
            id,
            gone.sortKey,
          );
        }
        (isRow ? s.rows : s.columns).remove(id);
        // Cascade: cells of the row/column.
        final removed = isRow
            ? s.cells.removeRow(id)
            : s.cells.removeColumn(id);
        for (final c in removed) {
          b.cell(ownerId, c, null);
        }
        b.structure(
          ownerId,
          isRow ? Dimension.rows : Dimension.columns,
          order: true,
          sizes: true,
        );
      case SheetsTables.cell:
        final ownerId = _cellOwner(id);
        if (ownerId == null) return;
        final s = _sheets[ownerId]!;
        final removed = s.cells.remove(id);
        if (removed != null) b.cell(ownerId, removed, null);
      case SheetsTables.namedRange:
        final old = _named.remove(id);
        if (old != null) {
          _namedByLower = null;
          b.names({old.name.toLowerCase()});
        }
      case SheetsTables.mergedRange:
      case SheetsTables.dimensionGroup:
      case SheetsTables.protectedRange:
      case SheetsTables.conditionalFormatRule:
      case SheetsTables.dataValidationRule:
      case SheetsTables.basicFilter:
      case SheetsTables.filterView:
      case SheetsTables.banding:
      case SheetsTables.embeddedObject:
      case SheetsTables.pivotTable:
        final ownerId = _ruleOwner.remove('$table:$id');
        if (ownerId == null) return;
        final s = _sheets[ownerId]!;
        if (table == SheetsTables.basicFilter) {
          if (s.basicFilter?.id == id) s.basicFilter = null;
        } else {
          _childMap(s, table)!.remove(id);
        }
        final kind = _kindOf(table);
        s.invalidateRules(kind);
        b.rules(ownerId, kind, id);
      default:
        if (_other[table]?.remove(id) != null) b.other(table, id);
    }
  }

  String? _ownerOf(String table, String id, Map<String, Object?> columns) {
    final s = columns[Cols.sheetId];
    if (s != null) return s.toString();
    if (table == SheetsTables.cell) return _cellOwner(id);
    return _ruleOwner['$table:$id'];
  }

  /// The sheet holding cell [id] (cells are not in [_ruleOwner]: a 1M-cell
  /// model would keep a million "table:id" keys; a sheet lookup per sheet
  /// is cheaper).
  String? _cellOwner(String id) {
    for (final s in _sheets.values) {
      if (s.cells.byId(id) != null) return s.id;
    }
    return null;
  }

  static Map<String, SyncRecord>? _childMap(SheetModel s, String table) =>
      switch (table) {
        SheetsTables.mergedRange => s.merges,
        SheetsTables.dimensionGroup => s.groups,
        SheetsTables.protectedRange => s.protections,
        SheetsTables.conditionalFormatRule => s.cfRules,
        SheetsTables.dataValidationRule => s.dvRules,
        SheetsTables.filterView => s.filterViews,
        SheetsTables.banding => s.bandings,
        SheetsTables.embeddedObject => s.objects,
        SheetsTables.pivotTable => s.pivots,
        SheetsTables.sheetRow => s.rowRecords,
        SheetsTables.sheetColumn => s.columnRecords,
        _ => null,
      };

  static RuleKind _kindOf(String table) => switch (table) {
    SheetsTables.mergedRange => RuleKind.merge,
    SheetsTables.dimensionGroup => RuleKind.group,
    SheetsTables.protectedRange => RuleKind.protection,
    SheetsTables.conditionalFormatRule => RuleKind.conditionalFormat,
    SheetsTables.dataValidationRule => RuleKind.dataValidation,
    SheetsTables.basicFilter => RuleKind.basicFilter,
    SheetsTables.filterView => RuleKind.filterView,
    SheetsTables.banding => RuleKind.banding,
    SheetsTables.embeddedObject => RuleKind.object,
    SheetsTables.pivotTable => RuleKind.pivot,
    _ => throw ArgumentError(table),
  };

  // ---------------------------------------------------------------------------
  // Export of rows.

  /// Every synced row currently held, in table dependency order:
  /// `(table, columns)`. Rows of deleted sheets are excluded.
  Iterable<(String table, Map<String, Object?> columns)> allRows() sync* {
    if (_spreadsheet != null) {
      yield (SheetsTables.spreadsheet, _spreadsheet!.toColumns());
    }
    final live = sheets;
    for (final s in live) {
      yield (SheetsTables.sheet, s.record!.toColumns());
    }
    for (final s in live) {
      for (final r in s.rowRecords.values) {
        yield (SheetsTables.sheetRow, r.toColumns());
      }
    }
    for (final s in live) {
      for (final r in s.columnRecords.values) {
        yield (SheetsTables.sheetColumn, r.toColumns());
      }
    }
    for (final s in live) {
      for (final c in s.cells.all) {
        if (s.rows.contains(c.rowId) && s.columns.contains(c.columnId)) {
          yield (SheetsTables.cell, c.toColumns());
        }
      }
    }
    for (final s in live) {
      for (final r in s.merges.values) {
        yield (r.table, r.toColumns());
      }
      for (final r in s.groups.values) {
        yield (r.table, r.toColumns());
      }
    }
    for (final n in _named.values) {
      yield (n.table, n.toColumns());
    }
    for (final s in live) {
      for (final map in [s.protections, s.cfRules, s.dvRules]) {
        for (final r in map.values) {
          yield (r.table, r.toColumns());
        }
      }
      if (s.basicFilter != null) {
        yield (s.basicFilter!.table, s.basicFilter!.toColumns());
      }
      for (final map in [s.filterViews, s.bandings, s.objects, s.pivots]) {
        for (final r in map.values) {
          yield (r.table, r.toColumns());
        }
      }
    }
    final otherTables = _other.keys.toList()
      ..sort((a, b) => SheetsTables.rank(a).compareTo(SheetsTables.rank(b)));
    for (final t in otherTables) {
      for (final r in _other[t]!.values) {
        yield (t, r.toColumns());
      }
    }
  }

  /// Total grid size (rows × columns over all sheets): counts toward the cell
  /// limit (02 §3.2).
  int get gridCellCount {
    var n = 0;
    for (final s in sheets) {
      n += s.rows.length * s.columns.length;
    }
    return n;
  }
}

final class _BatchBuilder {
  final Map<String, CellsChanged> _cells = {};
  final Map<(String, Dimension), StructureChanged> _structure = {};
  SheetsChanged? _sheets;
  final Map<(String, RuleKind), RulesChanged> _rules = {};
  NamesChanged? _names;
  SpreadsheetChanged? _spreadsheet;
  final Map<String, OtherRowsChanged> _other = {};

  void cell(String sheetId, CellRecord? before, CellRecord? after) {
    final c = after ?? before!;
    final key = (rowId: c.rowId, colId: c.columnId);
    final e = _cells.putIfAbsent(sheetId, () => CellsChanged(sheetId));
    if (before?.content != after?.content) e.contentKeys.add(key);
    if (before?.format != after?.format) e.formatKeys.add(key);
    if (before?.note != after?.note) e.noteKeys.add(key);
  }

  void structure(
    String sheetId,
    Dimension d, {
    bool order = false,
    bool sizes = false,
    bool formats = false,
  }) {
    final e = _structure.putIfAbsent((
      sheetId,
      d,
    ), () => StructureChanged(sheetId, d));
    e.order |= order;
    e.sizes |= sizes;
    e.formats |= formats;
  }

  void sheet(String id, {bool orderOrNames = false}) {
    final s = _sheets ??= SheetsChanged({});
    s.sheetIds.add(id);
    s.orderOrNames |= orderOrNames;
  }

  void rules(String sheetId, RuleKind kind, String id) {
    _rules
        .putIfAbsent((sheetId, kind), () => RulesChanged(sheetId, kind, {}))
        .ruleIds
        .add(id);
  }

  void names(Set<String> names) =>
      (_names ??= NamesChanged({})).names.addAll(names);

  void spreadsheet(Iterable<String> columns) =>
      (_spreadsheet ??= SpreadsheetChanged({})).columns.addAll(columns);

  void other(String table, String id) =>
      _other.putIfAbsent(table, () => OtherRowsChanged(table, {})).ids.add(id);

  WorkbookChangeBatch build() => WorkbookChangeBatch([
    ?_spreadsheet,
    ?_sheets,
    ..._structure.values,
    ..._cells.values.where((c) => c.allKeys.isNotEmpty),
    ..._rules.values,
    ?_names,
    ..._other.values,
  ]);
}

/// Index rectangle helpers bound to a sheet.
extension SheetModelRects on SheetModel {
  /// A1 text of [rect] on this sheet.
  String a1(GridRect rect) => rect.a1;
}
