import 'dart:convert';

import 'package:wonky_sync_models/ids.dart';

import '../../addressing/grid_geometry.dart';
import '../../engine_bridge/stored_formula.dart';
import '../../format/attributes.dart';
import '../../model/grid_range.dart';
import '../../model/records.dart';
import '../../model/schema.dart';
import '../../model/sheet_model.dart';
import '../operations.dart';
import '../plan_builder.dart';
import '../row_change.dart';
import 'helpers.dart';

String _tableOf(Dimension d) =>
    d == Dimension.rows ? SheetsTables.sheetRow : SheetsTables.sheetColumn;

String _noun(Dimension d, int n) => d == Dimension.rows
    ? (n == 1 ? 'row' : 'rows')
    : (n == 1 ? 'column' : 'columns');

/// [InsertDimension] (03 §13.1).
MutationPlan planInsertDimension(PlanBuilder b, InsertDimension op) {
  final s = b.sheetOf(op.sheetId);
  final axis = s.axis(op.dimension);
  if (op.count <= 0) {
    throw const PlanException('invalid_argument', 'Count must be positive');
  }
  if (op.at < 0 || op.at > axis.length) {
    throw const PlanException(
      'invalid_range',
      'Insert position is outside the grid',
    );
  }
  final rows = s.rows.length + (op.dimension == Dimension.rows ? op.count : 0);
  final cols =
      s.columns.length + (op.dimension == Dimension.columns ? op.count : 0);
  b.checkCellLimit(b.gridCellsWith(s.id, rows, cols));
  final prevKey = op.at > 0 ? axis.sortKeyAt(op.at - 1) : null;
  var nextKey = op.at < axis.length ? axis.sortKeyAt(op.at) : null;
  if (prevKey != null && nextKey != null && prevKey == nextKey) {
    // Concurrent identical keys: place after the tie group.
    var j = op.at;
    while (j < axis.length && axis.sortKeyAt(j) == prevKey) {
      j++;
    }
    nextKey = j < axis.length ? axis.sortKeyAt(j) : null;
  }
  final keys = FractionalIndex.nBetween(prevKey, nextKey, op.count);
  // Anchor for inherited formatting.
  int? anchor;
  switch (op.inheritFrom) {
    case InheritFrom.before:
      anchor = op.at > 0 ? op.at - 1 : (op.at < axis.length ? op.at : null);
    case InheritFrom.after:
      anchor = op.at < axis.length ? op.at : (op.at > 0 ? op.at - 1 : null);
    case InheritFrom.none:
      anchor = null;
  }
  final table = _tableOf(op.dimension);
  final anchorId = anchor == null ? null : axis.idAt(anchor);
  final anchorRec = anchorId == null ? null : b.current(table, anchorId);
  final sizeCol = op.dimension == Dimension.rows
      ? DimCols.height
      : DimCols.width;
  final newIds = <String>[];
  for (final k in keys) {
    final id = b.ctx.ids.newId();
    newIds.add(id);
    b.insert(table, id, {
      Cols.sheetId: s.id,
      Cols.sortKey: k,
      Cols.hidden: false,
      sizeCol: anchorRec?[sizeCol],
      Cols.formatJson: anchorRec?[Cols.formatJson],
    });
  }
  // Copy format-only cells of the anchor (≤ 10,000).
  if (anchorId != null) {
    final anchorCells = op.dimension == Dimension.rows
        ? s.cells.inRow(anchorId).toList()
        : s.cells.inColumn(anchorId).toList();
    var copied = 0;
    for (final cell in anchorCells) {
      if (cell.format.isEmpty) continue;
      final fmt = cell.format.without([FormatAttr.linkUrl]);
      if (fmt.isEmpty) continue;
      for (final id in newIds) {
        if (copied >= 10000) break;
        final rowId = op.dimension == Dimension.rows ? id : cell.rowId;
        final colId = op.dimension == Dimension.rows ? cell.columnId : id;
        b.writeCell(s.id, rowId, colId, fmt.toMap());
        copied++;
      }
    }
  }
  b.summary.sheets.add(s.id);
  b.result['ids'] = newIds;
  final label = 'Insert ${op.count} ${_noun(op.dimension, op.count)}';
  return b.build(label, kinds: [ChangeKinds.structure]);
}

/// [DeleteDimension] with boundary repair (03 §13.2, 05 §5.4).
MutationPlan planDeleteDimension(PlanBuilder b, DeleteDimension op) {
  final s = b.sheetOf(op.sheetId);
  final axis = s.axis(op.dimension);
  final ids = {
    for (final id in op.ids)
      if (axis.contains(id)) id,
  };
  if (ids.isEmpty) return b.build('Delete ${_noun(op.dimension, 0)}');
  if (ids.length >= axis.length) {
    throw PlanException(
      'invalid_argument',
      op.dimension == Dimension.rows
          ? 'A sheet must have at least one row'
          : 'A sheet must have at least one column',
    );
  }
  final table = _tableOf(op.dimension);
  // Cells of the deleted rows/columns (explicitly, so undo restores them).
  for (final id in ids) {
    final cells = op.dimension == Dimension.rows
        ? s.cells.inRow(id)
        : s.cells.inColumn(id);
    for (final c in cells.toList()) {
      b.delete(SheetsTables.cell, c.id);
    }
    b.delete(table, id);
    b.summary.addDeleted(op.dimension == Dimension.rows ? 'rows' : 'cols', id);
  }
  final deletedRows = op.dimension == Dimension.rows ? ids : <String>{};
  final deletedCols = op.dimension == Dimension.columns ? ids : <String>{};
  repairAfterDelete(b, s, deletedRows, deletedCols);
  b.summary.sheets.add(s.id);
  return b.build(
    'Delete ${ids.length} ${_noun(op.dimension, ids.length)}',
    kinds: [ChangeKinds.structure],
  );
}

/// Repairs every id-based range and formula after rows/columns of [s] are
/// deleted: range endpoints move inward to the nearest surviving id; ranges
/// left empty delete their rule; formulas are rewritten with
/// `FormulaHooks.repairBoundaries`.
void repairAfterDelete(
  PlanBuilder b,
  SheetModel s,
  Set<String> deletedRows,
  Set<String> deletedCols,
) {
  GridRange? repair(GridRange g) =>
      repairGridRange(s, g, deletedRows, deletedCols);

  // Merges.
  for (final m in s.merges.values) {
    final g = GridRange.tryParse(m.rangeJson);
    if (g == null || g.sheetId != s.id) continue;
    final r = repair(g);
    if (r == null) {
      b.delete(SheetsTables.mergedRange, m.id);
    } else if (r != g) {
      final rr = s.resolve(r);
      // A merge reduced to one cell is removed.
      final remaining = _remainingRect(s, r, deletedRows, deletedCols);
      if (rr == null || remaining == null || remaining.isSingleCell) {
        b.delete(SheetsTables.mergedRange, m.id);
      } else {
        b.update(SheetsTables.mergedRange, m.id, {Cols.rangeJson: r.encode()});
      }
    }
  }
  // Single-range rules.
  void single(
    String table,
    Iterable<SyncRecord> records,
    String column, {
    bool deleteWhenEmpty = true,
  }) {
    for (final rec in records.toList()) {
      final json = rec.column(column) as String?;
      final g = GridRange.tryParse(json);
      if (g == null || g.sheetId != s.id) continue;
      final r = repair(g);
      if (r == null) {
        if (deleteWhenEmpty) b.delete(table, rec.id);
      } else if (r != g) {
        b.update(table, rec.id, {column: r.encode()});
      }
    }
  }

  single(SheetsTables.banding, s.bandings.values, Cols.rangeJson);
  single(SheetsTables.filterView, s.filterViews.values, Cols.rangeJson);
  if (s.basicFilter != null) {
    single(SheetsTables.basicFilter, [s.basicFilter!], Cols.rangeJson);
  }
  single(
    SheetsTables.protectedRange,
    s.protections.values.where((p) => p.rangeJson != null),
    Cols.rangeJson,
  );
  // Multi-range rules.
  void multi(String table, Iterable<SyncRecord> records) {
    for (final rec in records.toList()) {
      final ranges = GridRange.parseList(
        rec.column(Cols.rangesJson) as String?,
      );
      var changed = false;
      final out = <GridRange>[];
      for (final g in ranges) {
        if (g.sheetId != s.id) {
          out.add(g);
          continue;
        }
        final r = repair(g);
        if (r != g) changed = true;
        if (r != null) out.add(r);
      }
      if (!changed) continue;
      if (out.isEmpty) {
        b.delete(table, rec.id);
      } else {
        b.update(table, rec.id, {Cols.rangesJson: GridRange.encodeList(out)});
      }
    }
  }

  multi(SheetsTables.conditionalFormatRule, s.cfRules.values);
  multi(SheetsTables.dataValidationRule, s.dvRules.values);
  // Protections' except ranges.
  for (final p in s.protections.values) {
    final except = GridRange.parseList(p.exceptRangesJson);
    if (except.isEmpty) continue;
    final out = [for (final g in except) ?repair(g)];
    if (out.length != except.length || !_sameList(out, except)) {
      b.update(SheetsTables.protectedRange, p.id, {
        'exceptRangesJson': GridRange.encodeList(out),
      });
    }
  }
  // Groups: endpoints move inward; empty groups are deleted.
  for (final g in s.groups.values) {
    final isRows = g.dimension == Dimension.rows;
    final deleted = isRows ? deletedRows : deletedCols;
    if (!deleted.contains(g.startId) && !deleted.contains(g.endId)) continue;
    final axis = isRows ? s.rows : s.columns;
    final a = axis.indexOf(g.startId);
    final z = axis.indexOf(g.endId);
    final survivors = [
      for (var i = a; i <= z && i >= 0; i++)
        if (!deleted.contains(axis.idAt(i))) axis.idAt(i),
    ];
    if (survivors.isEmpty) {
      b.delete(SheetsTables.dimensionGroup, g.id);
    } else {
      b.update(SheetsTables.dimensionGroup, g.id, {
        'startId': survivors.first,
        'endId': survivors.last,
      });
    }
  }
  // Named ranges on this sheet.
  for (final n in b.model.namedRanges) {
    final g = GridRange.tryParse(n.rangeJson);
    if (g == null || g.sheetId != s.id) continue;
    final r = repair(g);
    if (r != g && r != null) {
      b.update(SheetsTables.namedRange, n.id, {Cols.rangeJson: r.encode()});
    }
    // A named range whose rows are all deleted keeps its JSON (shows #REF!).
  }
  // Objects anchored on deleted rows/columns re-anchor; chart data ranges.
  for (final o in s.objects.values) {
    final anchor = PlanBuilderHelpers.decodeMap(o.anchorJson);
    var changedAnchor = false;
    String? reanchor(String? id, Set<String> deleted, bool isRow) {
      if (id == null) return null;
      final canonical = _canonical(id);
      if (!deleted.contains(canonical)) return id;
      final axis = isRow ? s.rows : s.columns;
      final i = axis.indexOf(canonical);
      String? pick;
      for (var j = i + 1; j < axis.length; j++) {
        if (!deleted.contains(axis.idAt(j))) {
          pick = axis.idAt(j);
          break;
        }
      }
      if (pick == null) {
        for (var j = i - 1; j >= 0; j--) {
          if (!deleted.contains(axis.idAt(j))) {
            pick = axis.idAt(j);
            break;
          }
        }
      }
      changedAnchor = true;
      return pick == null ? id : Base62Uuid.encode(pick);
    }

    final newRow = reanchor(anchor['rowId'] as String?, deletedRows, true);
    final newCol = reanchor(anchor['colId'] as String?, deletedCols, false);
    final writes = <String, Object?>{};
    if (changedAnchor) {
      writes['anchorJson'] = jsonEncode({
        ...anchor,
        'rowId': newRow,
        'colId': newCol,
        'dx': 0.0,
        'dy': 0.0,
      });
    }
    final spec = PlanBuilderHelpers.decodeMap(o.specJson);
    final repairedSpec = _repairRangesInJson(spec, s, repair);
    if (repairedSpec != null) writes['specJson'] = jsonEncode(repairedSpec);
    if (writes.isNotEmpty) b.update(SheetsTables.embeddedObject, o.id, writes);
  }
  // Pivots: sources on any sheet referencing this sheet; anchors on this sheet.
  for (final other in b.model.sheets) {
    for (final p in other.pivots.values) {
      final writes = <String, Object?>{};
      final src = GridRange.tryParse(p.sourceRangeJson);
      if (src != null && src.sheetId == s.id) {
        final r = repair(src);
        if (r != null && r != src) writes['sourceRangeJson'] = r.encode();
      }
      if (other.id == s.id && deletedRows.contains(p.anchorRowId)) {
        final i = s.rows.indexOf(p.anchorRowId);
        writes['anchorRowId'] = _nearestSurvivor(s.rows.ids, i, deletedRows);
      }
      if (other.id == s.id && deletedCols.contains(p.anchorColId)) {
        final i = s.columns.indexOf(p.anchorColId);
        writes['anchorColId'] = _nearestSurvivor(s.columns.ids, i, deletedCols);
      }
      if (writes.isNotEmpty) b.update(SheetsTables.pivotTable, p.id, writes);
    }
  }
  // Formulas in every sheet (and rule formulas).
  final allDeleted = {...deletedRows, ...deletedCols};
  final hooks = b.ctx.formulas;
  if (hooks == null) return;
  final deletedTokens = StoredFormula.idTokens(allDeleted);
  for (final other in b.model.sheets) {
    for (final cell in other.cells.formulaCells) {
      final content = cell.content;
      if (content == null || !content.startsWith('=')) continue;
      if (allDeleted.contains(cell.rowId) ||
          allDeleted.contains(cell.columnId)) {
        continue;
      }
      if (!StoredFormula.referencesAny(content, deletedTokens)) continue;
      final repaired = hooks.repairBoundaries(
        content,
        deletedRowIds: deletedRows,
        deletedColIds: deletedCols,
      );
      if (repaired != null && repaired != content) {
        b.update(SheetsTables.cell, cell.id, {CellCols.content: repaired});
      }
    }
    _repairRuleFormulas(
      b,
      other,
      allDeleted,
      (f) => hooks.repairBoundaries(
        f,
        deletedRowIds: deletedRows,
        deletedColIds: deletedCols,
      ),
    );
  }
  for (final n in b.model.namedRanges) {
    final f = n.formula;
    if (f == null || !StoredFormula.referencesAny(f, deletedTokens)) continue;
    final r = hooks.repairBoundaries(
      f,
      deletedRowIds: deletedRows,
      deletedColIds: deletedCols,
    );
    if (r != null && r != f) {
      b.update(SheetsTables.namedRange, n.id, {'formula': r});
    }
  }
}

/// Applies [rewrite] to formulas inside CF/DV/filter JSON of [s] that may
/// reference [ids].
void _repairRuleFormulas(
  PlanBuilder b,
  SheetModel s,
  Set<String> ids,
  String? Function(String) rewrite,
) {
  final tokens = StoredFormula.idTokens(ids);
  void apply(String table, SyncRecord rec, String column) {
    final json = rec.column(column) as String?;
    if (json == null || !StoredFormula.referencesAny(json, tokens)) return;
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return;
    }
    final (out, changed) = StoredFormula.mapJsonFormulas(decoded, rewrite);
    if (changed) b.update(table, rec.id, {column: jsonEncode(out)});
  }

  for (final r in s.cfRules.values) {
    apply(SheetsTables.conditionalFormatRule, r, 'ruleJson');
  }
  for (final r in s.dvRules.values) {
    apply(SheetsTables.dataValidationRule, r, 'criteriaJson');
  }
  if (s.basicFilter != null) {
    apply(SheetsTables.basicFilter, s.basicFilter!, 'criteriaJson');
  }
  for (final r in s.filterViews.values) {
    apply(SheetsTables.filterView, r, 'criteriaJson');
  }
}

String _nearestSurvivor(List<String> ids, int i, Set<String> deleted) {
  for (var j = i + 1; j < ids.length; j++) {
    if (!deleted.contains(ids[j])) return ids[j];
  }
  for (var j = i - 1; j >= 0; j--) {
    if (!deleted.contains(ids[j])) return ids[j];
  }
  return ids[i < 0 ? 0 : i];
}

String _canonical(String id) =>
    id.length == Base62Uuid.length &&
        !id.contains('-') &&
        Base62Uuid.isValid(id)
    ? Base62Uuid.decode(id)
    : id;

bool _sameList(List<GridRange> a, List<GridRange> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

GridRect? _remainingRect(
  SheetModel s,
  GridRange r,
  Set<String> deletedRows,
  Set<String> deletedCols,
) {
  final rr = s.resolve(r);
  if (rr == null) return null;
  var rows = 0;
  for (var i = rr.rect.top; i <= rr.rect.bottom; i++) {
    if (!deletedRows.contains(s.rows.idAt(i))) rows++;
  }
  var cols = 0;
  for (var i = rr.rect.left; i <= rr.rect.right; i++) {
    if (!deletedCols.contains(s.columns.idAt(i))) cols++;
  }
  if (rows == 0 || cols == 0) return null;
  return GridRect(0, 0, rows - 1, cols - 1);
}

/// Moves deleted endpoints of [g] inward to the nearest surviving id inside
/// the range (computed on the pre-delete order). Returns [g] unchanged when no
/// endpoint is deleted, null when nothing survives.
GridRange? repairGridRange(
  SheetModel s,
  GridRange g,
  Set<String> deletedRows,
  Set<String> deletedCols,
) {
  final rows = _repairSpan(s.rows.ids, s.rows.indexOf, g.r1, g.r2, deletedRows);
  final cols = _repairSpan(
    s.columns.ids,
    s.columns.indexOf,
    g.c1,
    g.c2,
    deletedCols,
  );
  if (rows == null || cols == null) return null;
  final (r1, r2, rowsChanged) = rows;
  final (c1, c2, colsChanged) = cols;
  if (!rowsChanged && !colsChanged) return g;
  return GridRange(
    sheetId: g.sheetId,
    r1: r1,
    r2: r2,
    c1: c1,
    c2: c2,
    r1k: r1 == null ? null : s.rows.sortKeyOf(r1),
    r2k: r2 == null ? null : s.rows.sortKeyOf(r2),
    c1k: c1 == null ? null : s.columns.sortKeyOf(c1),
    c2k: c2 == null ? null : s.columns.sortKeyOf(c2),
  );
}

(String?, String?, bool)? _repairSpan(
  List<String> ids,
  int Function(String) indexOf,
  String? a,
  String? z,
  Set<String> deleted,
) {
  if (deleted.isEmpty) return (a, z, false);
  final aDel = a != null && deleted.contains(a);
  final zDel = z != null && deleted.contains(z);
  if (!aDel && !zDel) {
    if (a == null && z == null && deleted.length >= ids.length) return null;
    return (a, z, false);
  }
  var i = a == null ? 0 : indexOf(a);
  var j = z == null ? ids.length - 1 : indexOf(z);
  if (i < 0 || j < 0) return null;
  if (i > j) {
    final t = i;
    i = j;
    j = t;
  }
  var na = a;
  var nz = z;
  if (aDel) {
    na = null;
    for (var k = i; k <= j; k++) {
      if (!deleted.contains(ids[k])) {
        na = ids[k];
        break;
      }
    }
    if (na == null) return null;
  }
  if (zDel) {
    nz = null;
    for (var k = j; k >= i; k--) {
      if (!deleted.contains(ids[k])) {
        nz = ids[k];
        break;
      }
    }
    if (nz == null) return null;
  }
  return (na, nz, true);
}

/// Repairs GridRange-shaped maps (`{"s",…}`) nested in [json] (chart specs).
/// Returns the new JSON when something changed, else null.
Map<String, Object?>? _repairRangesInJson(
  Map<String, Object?> json,
  SheetModel s,
  GridRange? Function(GridRange) repair,
) {
  var changed = false;
  Object? walk(Object? v) {
    if (v is Map) {
      if (v['s'] is String &&
          (v.containsKey('r1') ||
              v.containsKey('c1') ||
              v.containsKey('r2') ||
              v.containsKey('c2'))) {
        final g = GridRange.tryParse(v);
        if (g != null && g.sheetId == s.id) {
          final r = repair(g);
          if (r != g) {
            changed = true;
            return r?.toJson() ?? v;
          }
        }
        return v;
      }
      return {for (final e in v.entries) e.key: walk(e.value)};
    }
    if (v is List) return [for (final e in v) walk(e)];
    return v;
  }

  final out = walk(json);
  return changed ? (out as Map).cast<String, Object?>() : null;
}

/// [MoveDimension] (03 §13.4): only sort keys change.
MutationPlan planMoveDimension(PlanBuilder b, MoveDimension op) {
  final s = b.sheetOf(op.sheetId);
  final axis = s.axis(op.dimension);
  final moving = [
    for (final id in axis.ids)
      if (op.ids.contains(id)) id,
  ];
  if (moving.isEmpty) return b.build('Move ${_noun(op.dimension, 0)}');
  final rest = [
    for (final id in axis.ids)
      if (!op.ids.contains(id)) id,
  ];
  final beforeIndex = op.beforeId == null
      ? rest.length
      : rest.indexOf(op.beforeId!);
  if (beforeIndex < 0) {
    throw const PlanException(
      'invalid_argument',
      'Move target is one of the moved entries',
    );
  }
  final prevKey = beforeIndex > 0
      ? axis.sortKeyOf(rest[beforeIndex - 1])
      : null;
  var nextKey = beforeIndex < rest.length
      ? axis.sortKeyOf(rest[beforeIndex])
      : null;
  if (prevKey != null && nextKey != null && prevKey.compareTo(nextKey) >= 0) {
    nextKey = null;
  }
  final keys = FractionalIndex.nBetween(prevKey, nextKey, moving.length);
  final table = _tableOf(op.dimension);
  for (var i = 0; i < moving.length; i++) {
    b.update(table, moving[i], {Cols.sortKey: keys[i]});
  }
  b.summary.sheets.add(s.id);
  return b.build(
    'Move ${moving.length} ${_noun(op.dimension, moving.length)}',
    kinds: [ChangeKinds.structure],
  );
}

/// [SetDimensionHidden] (03 §13.5).
MutationPlan planSetHidden(PlanBuilder b, SetDimensionHidden op) {
  final s = b.sheetOf(op.sheetId);
  final axis = s.axis(op.dimension);
  final table = _tableOf(op.dimension);
  if (op.hidden && op.dimension == Dimension.columns) {
    var visible = 0;
    for (var i = 0; i < axis.length; i++) {
      if (!axis.isUserHidden(i) && !op.ids.contains(axis.idAt(i))) visible++;
    }
    if (visible == 0) {
      throw const PlanException(
        'invalid_argument',
        "You can't hide all columns",
      );
    }
  }
  for (final id in op.ids) {
    if (!axis.contains(id)) continue;
    b.update(table, id, {Cols.hidden: op.hidden});
  }
  b.summary.sheets.add(s.id);
  final n = op.ids.length;
  return b.build(
    '${op.hidden ? 'Hide' : 'Unhide'} ${_noun(op.dimension, n)}',
    kinds: [ChangeKinds.structure],
  );
}

/// [ResizeDimension] (03 §13.6).
MutationPlan planResize(PlanBuilder b, ResizeDimension op) {
  final s = b.sheetOf(op.sheetId);
  final table = _tableOf(op.dimension);
  final col = op.dimension == Dimension.rows ? DimCols.height : DimCols.width;
  final size = op.size?.clamp(2.0, 10000.0);
  for (final id in op.ids) {
    if (!s.axis(op.dimension).contains(id)) continue;
    b.update(table, id, {col: size});
  }
  b.summary.sheets.add(s.id);
  return b.build(
    'Resize ${_noun(op.dimension, op.ids.length)}',
    kinds: [ChangeKinds.structure],
  );
}

/// [SetFrozen].
MutationPlan planSetFrozen(PlanBuilder b, SetFrozen op) {
  final s = b.sheetOf(op.sheetId);
  final writes = <String, Object?>{};
  if (op.rows != null) {
    if (op.rows! < 0 || op.rows! >= s.rows.length) {
      throw const PlanException(
        'invalid_argument',
        'Frozen rows must leave at least one row unfrozen',
      );
    }
    writes[SheetCols.frozenRows] = op.rows;
  }
  if (op.columns != null) {
    if (op.columns! < 0 || op.columns! >= s.columns.length) {
      throw const PlanException(
        'invalid_argument',
        'Frozen columns must leave at least one column unfrozen',
      );
    }
    writes[SheetCols.frozenColumns] = op.columns;
  }
  // Refuse when merges would straddle the new boundary.
  for (final (_, m) in s.mergesIntersecting(
    s.gridRect ?? const GridRect(0, 0, 0, 0),
  )) {
    final fr = op.rows;
    final fc = op.columns;
    if ((fr != null && fr > 0 && m.top < fr && m.bottom >= fr) ||
        (fc != null && fc > 0 && m.left < fc && m.right >= fc)) {
      throw const PlanException(
        'merge_conflict',
        "You can't freeze rows or columns that contain only part of a merged cell",
      );
    }
  }
  b.update(SheetsTables.sheet, s.id, writes);
  b.summary.sheets.add(s.id);
  return b.build('Freeze', kinds: [ChangeKinds.structure]);
}
