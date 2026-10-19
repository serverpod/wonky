import 'dart:convert';

import 'package:wonky_sync_models/ids.dart';

import '../../addressing/grid_geometry.dart';
import '../../data_tools/protection/protection_guard.dart';
import '../../data_tools/sort/sort_strategy.dart';
import '../../engine_bridge/stored_formula.dart';
import '../../model/grid_range.dart';
import '../../model/records.dart';
import '../../model/schema.dart';
import '../../model/sheet_model.dart';
import '../plan_builder.dart';
import 'helpers.dart';
import 'move.dart';

/// Physical strategy of a row permutation (07 §2.2).
enum RowMoveStrategy { rowReorder, contentMove }

/// Chooses the strategy for permuting the rows of [rect] (07 §2.2, see
/// [SortStrategy.choose]): row-entity reorder when the rows have no cells
/// outside the rect's columns and no merge spans several rows; otherwise
/// content move.
RowMoveStrategy chooseRowMoveStrategy(SheetModel s, GridRect rect) =>
    switch (SortStrategy.choose(s, rect)) {
      SortStrategyKind.rowReorder => RowMoveStrategy.rowReorder,
      SortStrategyKind.contentMove => RowMoveStrategy.contentMove,
    };

/// Refuses permutations over vertical merges (07 §2.4).
void checkNoVerticalMerges(SheetModel s, GridRect rect) {
  if (SortStrategy.hasVerticalMerge(s, rect)) {
    throw const PlanException(
      'merge_conflict',
      SortRefusal.verticalMergeMessage,
    );
  }
}

/// The refusals shared by sort, randomize and remove duplicates (07 §2.4):
/// vertical merges, spill/pivot output ([PlanContext.overlays]) and cells
/// the user can't edit (warning-only protections are allowed; the UI asks).
void checkRowMoveAllowed(PlanBuilder b, SheetModel s, GridRect rect) {
  checkNoVerticalMerges(s, rect);
  final overlays = b.ctx.overlays?.call(s.id);
  if (overlays != null && overlays.any((o) => o.intersects(rect))) {
    throw const PlanException('overlay_conflict', SortRefusal.overlayMessage);
  }
  checkNotProtected(b, s, [rect]);
}

/// Throws `protected_range` when writing [rects] of [s] is blocked for the
/// acting user (07 §10.3).
void checkNotProtected(PlanBuilder b, SheetModel s, List<GridRect> rects) {
  if (s.protections.isEmpty) return;
  final g = ProtectionGuard(
    b.model,
  ).check(CellWrites(s.id, rects), b.ctx.userId, isOwner: b.ctx.isOwner);
  if (g.isBlocked) {
    throw PlanException(
      'protected_range',
      GuardResult.blockedMessage,
      details: {'protectionIds': g.protectionIds.toList()},
    );
  }
}

/// Applies a row permutation to the data rows [rect] of [s]: after the
/// operation, position `rect.top + i` holds the record that was at
/// `rect.top + permutation[i]`. Rows past [keepCount] (dedupe) are cleared
/// (contents of the range columns). Formulas in moved rows get copy
/// semantics (07 §2.5); references from outside keep pointing at positions.
RowMoveStrategy applyRowPermutation(
  PlanBuilder b,
  SheetModel s,
  GridRect rect,
  List<int> permutation, {
  int? keepCount,
  RowMoveStrategy? strategy,
}) {
  final out = RowMoveOutcome();
  for (final _ in applyRowPermutationSteps(
    b,
    s,
    rect,
    permutation,
    out,
    keepCount: keepCount,
    strategy: strategy,
  )) {}
  return out.strategy!;
}

/// The strategy [applyRowPermutationSteps] used.
final class RowMoveOutcome {
  RowMoveStrategy? strategy;
}

/// Rows/cells handled between two progress reports of
/// [applyRowPermutationSteps].
const int rowMoveStepSize = 2048;

/// [applyRowPermutation] as a cooperative job (07 §1.4): yields its
/// progress (0–1) every [rowMoveStepSize] rows or formula cells so a
/// `DataJob` can report it, paint and cancel between steps. The model must
/// not change while the steps run. Sets [out] when done.
Iterable<double> applyRowPermutationSteps(
  PlanBuilder b,
  SheetModel s,
  GridRect rect,
  List<int> permutation,
  RowMoveOutcome out, {
  int? keepCount,
  RowMoveStrategy? strategy,
}) sync* {
  final n = rect.rowCount;
  assert(permutation.length == n, 'permutation length must match rows');
  final keep = keepCount ?? n;
  final st =
      strategy ??
      (keep < n ? RowMoveStrategy.contentMove : chooseRowMoveStrategy(s, rect));
  var identity = true;
  for (var i = 0; i < n; i++) {
    if (permutation[i] != i) identity = false;
  }
  out.strategy = st;
  if (identity && keep == n) return;
  final hooks = b.ctx.formulas;
  if (st == RowMoveStrategy.contentMove) {
    _moveSingleRowMerges(b, s, rect, permutation, keep);
    final snapshot = <int, Map<int, Map<String, Object?>>>{};
    for (final (r, c, _, _, cur) in b.cellsIn(s, rect)) {
      (snapshot[r - rect.top] ??= {})[c - rect.left] = cellData(cur);
    }
    yield 0.2;
    for (var i = 0; i < n; i++) {
      final targetRow = rect.top + i;
      final rowId = s.rows.idAt(targetRow);
      final from = i < keep ? permutation[i] : -1;
      if (from == i) continue;
      final srcCells = from < 0
          ? const <int, Map<String, Object?>>{}
          : (snapshot[from] ?? const {});
      for (var c = rect.left; c <= rect.right; c++) {
        final colId = s.columns.idAt(c);
        final data = srcCells[c - rect.left];
        if (data == null) {
          b.deleteCell(s.id, rowId, colId);
          continue;
        }
        final data2 = Map<String, Object?>.of(data);
        final content = data2[CellCols.content] as String?;
        if (content != null && content.startsWith('=') && hooks != null) {
          data2[CellCols.content] = hooks.translate(
            content,
            fromSheetId: s.id,
            fromRow: rect.top + from,
            fromCol: c,
            toSheetId: s.id,
            toRow: targetRow,
            toCol: c,
          );
        }
        b.writeCell(s.id, rowId, colId, data2);
      }
      if (i % rowMoveStepSize == rowMoveStepSize - 1) yield 0.2 + 0.8 * i / n;
    }
    return;
  }
  // Row reorder: permute the existing sort keys among the rows.
  final oldIds = [for (var i = 0; i < n; i++) s.rows.idAt(rect.top + i)];
  var keys = [for (var i = 0; i < n; i++) s.rows.sortKeyAt(rect.top + i)];
  if (keys.toSet().length != n) {
    // Ties: generate fresh distinct keys inside the block's bounds.
    final before = rect.top > 0 ? s.rows.sortKeyAt(rect.top - 1) : null;
    final after = rect.bottom + 1 < s.rows.length
        ? s.rows.sortKeyAt(rect.bottom + 1)
        : null;
    keys = FractionalIndex.nBetween(
      before == keys.first ? null : before,
      after == keys.last ? null : after,
      n,
    );
  }
  final newIdAt = [for (var i = 0; i < n; i++) oldIds[permutation[i]]];
  for (var i = 0; i < n; i++) {
    b.update(SheetsTables.sheetRow, newIdAt[i], {Cols.sortKey: keys[i]});
    if (i % rowMoveStepSize == rowMoveStepSize - 1) yield 0.3 * i / n;
  }
  yield 0.3;
  final oldIndex = {for (var i = 0; i < n; i++) oldIds[i]: rect.top + i};
  String newRowIdAt(int pos) => pos >= rect.top && pos <= rect.bottom
      ? newIdAt[pos - rect.top]
      : s.rows.idAt(pos);
  int oldIndexOf(String id) => oldIndex[id] ?? s.rows.indexOf(id);
  final newPos = {for (var i = 0; i < n; i++) newIdAt[i]: rect.top + i};

  // Formulas: inside moved rows → translate (copy semantics) then re-pin;
  // elsewhere → re-pin references into the block.
  if (hooks != null) {
    final total = b.model.sheets.fold<int>(0, (a, x) => a + x.cells.count);
    final oldTokens = StoredFormula.idTokens(oldIds);
    var seen = 0;
    for (final sheet in b.model.sheets) {
      for (final cell in sheet.cells.all) {
        if (++seen % rowMoveStepSize == 0 && total > 0) {
          yield 0.3 + 0.65 * seen / total;
        }
        final content = cell.content;
        if (content == null || !content.startsWith('=')) continue;
        var f = content;
        final moved = sheet.id == s.id ? newPos[cell.rowId] : null;
        if (moved != null) {
          final from = oldIndex[cell.rowId]!;
          final c = s.columns.indexOf(cell.columnId);
          if (from != moved) {
            f = hooks.translate(
              f,
              fromSheetId: s.id,
              fromRow: from,
              fromCol: c,
              toSheetId: s.id,
              toRow: moved,
              toCol: c,
            );
          }
        } else if (!StoredFormula.referencesAny(f, oldTokens)) {
          continue;
        }
        final repinned = hooks.repinRows(
          f,
          hostSheetId: sheet.id,
          sheetId: s.id,
          blockTop: rect.top,
          blockBottom: rect.bottom,
          newRowIdAt: newRowIdAt,
          oldIndexOf: oldIndexOf,
        );
        if (repinned != null) f = repinned;
        if (f != content) {
          b.update(SheetsTables.cell, cell.id, {CellCols.content: f});
        }
      }
    }
  }
  // Id ranges with endpoints inside the block keep covering positions.
  GridRange? repin(GridRange g) {
    if (g.sheetId != s.id) return null;
    String? map(String? id) {
      if (id == null) return null;
      final p = oldIndex[id];
      if (p == null) return id;
      return newRowIdAt(p);
    }

    final r1 = map(g.r1);
    final r2 = map(g.r2);
    if (r1 == g.r1 && r2 == g.r2) return null;
    return g.copyWith(
      r1: r1,
      r2: r2,
      r1k: r1 == null ? null : _keyOf(s, r1, newIdAt, keys, rect),
      r2k: r2 == null ? null : _keyOf(s, r2, newIdAt, keys, rect),
    );
  }

  _repinRuleRanges(b, s, repin);
}

/// Content move: single-row merges inside [rect] travel with their row's
/// content (07 §2.4); merges of cleared rows (dedupe) are removed. Merges
/// that only partially overlap the rect's columns are refused.
void _moveSingleRowMerges(
  PlanBuilder b,
  SheetModel s,
  GridRect rect,
  List<int> permutation,
  int keep,
) {
  final merges = s.mergesIntersecting(rect);
  if (merges.isEmpty) return;
  final dest = List<int>.filled(rect.rowCount, -1);
  for (var i = 0; i < keep; i++) {
    dest[permutation[i]] = i;
  }
  for (final (id, m) in merges) {
    if (m.rowCount > 1) {
      throw const PlanException(
        'merge_conflict',
        SortRefusal.verticalMergeMessage,
      );
    }
    if (m.left < rect.left || m.right > rect.right) {
      throw const PlanException(
        'merge_conflict',
        "Can't sort a range that only partially includes merged cells",
      );
    }
    final from = m.top - rect.top;
    final to = dest[from];
    if (to == from) continue;
    if (to < 0) {
      b.delete(SheetsTables.mergedRange, id);
      continue;
    }
    final row = rect.top + to;
    b.update(SheetsTables.mergedRange, id, {
      Cols.rangeJson: s.gridRange(GridRect(row, m.left, row, m.right)).encode(),
    });
  }
}

String? _keyOf(
  SheetModel s,
  String rowId,
  List<String> newIdAt,
  List<String> keys,
  GridRect rect,
) {
  final i = newIdAt.indexOf(rowId);
  if (i >= 0) return keys[i];
  return s.rows.sortKeyOf(rowId);
}

void _repinRuleRanges(
  PlanBuilder b,
  SheetModel s,
  GridRange? Function(GridRange) repin,
) {
  void single(String table, Iterable<SyncRecord> recs, String column) {
    for (final r in recs) {
      final g = GridRange.tryParse(r.column(column) as String?);
      if (g == null) continue;
      final n = repin(g);
      if (n != null) b.update(table, r.id, {column: n.encode()});
    }
  }

  void multi(String table, Iterable<SyncRecord> recs) {
    for (final r in recs) {
      final list = GridRange.parseList(r.column(Cols.rangesJson) as String?);
      var changed = false;
      final out = [
        for (final g in list)
          if (repin(g) case final GridRange n)
            () {
              changed = true;
              return n;
            }()
          else
            g,
      ];
      if (changed) {
        b.update(table, r.id, {Cols.rangesJson: GridRange.encodeList(out)});
      }
    }
  }

  // Merges are single-row here (vertical ones force a content move) and
  // travel with their row, so they are not re-pinned.
  single(SheetsTables.banding, s.bandings.values, Cols.rangeJson);
  single(SheetsTables.filterView, s.filterViews.values, Cols.rangeJson);
  if (s.basicFilter != null) {
    single(SheetsTables.basicFilter, [s.basicFilter!], Cols.rangeJson);
  }
  single(SheetsTables.protectedRange, s.protections.values, Cols.rangeJson);
  multi(SheetsTables.conditionalFormatRule, s.cfRules.values);
  multi(SheetsTables.dataValidationRule, s.dvRules.values);
  single(SheetsTables.namedRange, b.model.namedRanges, Cols.rangeJson);
  for (final other in b.model.sheets) {
    single(SheetsTables.pivotTable, other.pivots.values, 'sourceRangeJson');
    for (final o in other.objects.values) {
      final spec = PlanBuilderHelpers.decodeMap(o.specJson);
      var changed = false;
      Object? walk(Object? v) {
        if (v is Map) {
          if (v['s'] is String &&
              (v.containsKey('r1') || v.containsKey('c1'))) {
            final g = GridRange.tryParse(v);
            final n = g == null ? null : repin(g);
            if (n != null) {
              changed = true;
              return n.toJson();
            }
            return v;
          }
          return {for (final e in v.entries) e.key: walk(e.value)};
        }
        if (v is List) return [for (final e in v) walk(e)];
        return v;
      }

      final out = walk(spec);
      if (changed) {
        b.update(SheetsTables.embeddedObject, o.id, {
          'specJson': jsonEncode(out),
        });
      }
    }
  }
  // Groups: endpoints at positions.
  for (final g in s.groups.values) {
    if (g.dimension != Dimension.rows) continue;
    final n = repin(GridRange(sheetId: s.id, r1: g.startId, r2: g.endId));
    if (n != null) {
      b.update(SheetsTables.dimensionGroup, g.id, {
        'startId': n.r1,
        'endId': n.r2,
      });
    }
  }
}
