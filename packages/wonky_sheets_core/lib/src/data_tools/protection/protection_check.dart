import 'package:wonky_revlog/rows.dart';

import '../../formula/codec/ref_token.dart';
import '../../model/axis_index.dart';
import '../../model/events.dart';
import '../../model/records.dart';
import '../../model/schema.dart';
import '../../model/workbook_model.dart';
import 'protection_guard.dart';
import 'write_intents.dart';

/// Combines protection checks into one [GuardResult] (Sheets 07 §10.3,
/// RevLog spec 05 §3.5). Used by the client write gate (operation-based)
/// and by the server sequencer (applied changes).
abstract final class ProtectionCheck {
  /// Client gate: the writes of an operation (`WriteIntents.of`).
  static GuardResult ofWrites(
    WorkbookModel model,
    OperationWrites writes,
    String userId, {
    required bool isOwner,
  }) {
    final guard = ProtectionGuard(model);
    final acc = _Acc();
    for (final intent in writes.intents) {
      acc.add(guard.check(intent, userId, isOwner: isOwner));
    }
    for (final ins in writes.inserts) {
      acc.addInsert(guard, ins, userId, isOwner);
    }
    return acc.result();
  }

  /// Server check of an op's applied form against [model], the model at the
  /// previous revision (RevLog spec 05 §3.5). Matches the client gate
  /// ([ofWrites]) for the same operation:
  ///
  /// * row/column structure is derived from the changes: inserted lines →
  ///   the "insert between" check, deleted lines → structural delete,
  ///   `sortKey` updates → move; resizing and hiding are allowed;
  /// * what a delete takes along (cells of deleted lines, everything of a
  ///   deleted sheet) is covered by the structural or sheet check;
  /// * boundary repairs that only repoint references at lines or sheets
  ///   deleted by the same op are exempt ([BoundaryRepair]);
  /// * updating or deleting a protection needs `canManage`, unless it is a
  ///   repair or cascade of a delete; creating one is allowed.
  static GuardResult ofApplied(
    WorkbookModel model,
    List<RowChange> applied,
    String userId, {
    required bool isOwner,
  }) {
    final guard = ProtectionGuard(model);
    final acc = _Acc();
    final changes = [for (final c in applied) _withBefore(c, model)];
    final deleted = BoundaryRepair.deletedIds(changes);
    final deletedSheets = {
      for (final c in changes)
        if (c.op == RowOp.delete && c.table == SheetsTables.sheet) c.rowId,
    };
    final structural = <String, Map<Dimension, Map<StructuralOp, List<int>>>>{};
    final inserts = <InsertBetween>[];
    final rest = <RowChange>[];
    for (final c in changes) {
      final sheetId = c.table == SheetsTables.sheet ? null : _sheetOf(c, model);
      if (sheetId != null && deletedSheets.contains(sheetId)) continue;
      switch (c.table) {
        case SheetsTables.protectedRange:
          if (c.op == RowOp.insert) continue;
          if (deleted.isNotEmpty &&
              (BoundaryRepair.isRepair(c, deleted) ||
                  _emptiedBy(model, c, deleted))) {
            continue;
          }
          final rec = model.record(SheetsTables.protectedRange, c.rowId);
          if (rec is ProtectedRangeRecord &&
              !ProtectionGuard.canManage(rec, userId, isOwner: isOwner)) {
            acc.block(ProtectionHit(rec.id, null, warningOnly: false));
          }
          continue;
        case SheetsTables.sheetRow || SheetsTables.sheetColumn:
          final dim = c.table == SheetsTables.sheetRow
              ? Dimension.rows
              : Dimension.columns;
          final s = sheetId == null ? null : model.sheet(sheetId);
          if (s == null) continue;
          final axis = s.axis(dim);
          switch (c.op) {
            case RowOp.insert:
              final key = c.columnsAfter[Cols.sortKey] as String?;
              if (key == null || axis.length == 0) continue;
              final at = _insertionIndex(axis, key, c.rowId);
              if (at <= 0 || at >= axis.length) {
                if (s.protections.values.any((p) => p.rangeJson == null)) {
                  _addLine(
                    structural,
                    s.id,
                    dim,
                    StructuralOp.insert,
                    at.clamp(0, axis.length - 1),
                  );
                }
              } else {
                inserts.add(InsertBetween(s.id, dim, at - 1, at));
              }
            case RowOp.delete:
              final i = axis.indexOf(c.rowId);
              if (i >= 0) {
                _addLine(structural, s.id, dim, StructuralOp.delete, i);
              }
            case RowOp.update:
              if (c.touchedColumns.contains(Cols.sortKey)) {
                final i = axis.indexOf(c.rowId);
                if (i >= 0) {
                  _addLine(structural, s.id, dim, StructuralOp.move, i);
                }
              }
              // Line formats are cell writes; height/hidden are allowed.
              if (c.touchedColumns.contains(Cols.formatJson)) rest.add(c);
          }
          continue;
        case SheetsTables.cell when c.op == RowOp.delete:
          final row = c.columnsBefore[CellCols.rowId];
          final col = c.columnsBefore[CellCols.columnId];
          if (deleted.contains(row) || deleted.contains(col)) continue;
      }
      if (deleted.isNotEmpty && BoundaryRepair.isRepair(c, deleted)) continue;
      rest.add(c);
    }
    for (final MapEntry(key: sheetId, value: byDim) in structural.entries) {
      for (final MapEntry(key: dim, value: byOp) in byDim.entries) {
        for (final MapEntry(key: op, value: indices) in byOp.entries) {
          acc.add(
            guard.check(
              Structural(sheetId, dim, indices, op),
              userId,
              isOwner: isOwner,
            ),
          );
        }
      }
    }
    for (final ins in inserts) {
      acc.addInsert(guard, ins, userId, isOwner);
    }
    for (final intent in WriteIntents.fromChanges(rest, model)) {
      acc.add(guard.check(intent, userId, isOwner: isOwner));
    }
    return acc.result();
  }

  /// [c] with the `before` values of an update (the applied form omits
  /// them) and the full row of a delete, from [model].
  static RowChange _withBefore(RowChange c, WorkbookModel model) {
    if (c.op == RowOp.insert) return c;
    final cur = model.currentColumns(c.table, c.rowId);
    if (cur == null) return c;
    if (c.op == RowOp.delete) {
      return c.columnsBefore.length >= cur.length
          ? c
          : RowChange.delete(c.table, c.rowId, cur);
    }
    if (c.columnsBefore.length == c.columnsAfter.length) return c;
    return RowChange.update(c.table, c.rowId, {
      for (final k in c.columnsAfter.keys) k: cur[k],
    }, c.columnsAfter);
  }

  /// Whether [c] deletes a range protection that the same op leaves without
  /// cells: every row or every column of it is in [deleted].
  static bool _emptiedBy(WorkbookModel m, RowChange c, Set<String> deleted) {
    if (c.op != RowOp.delete) return false;
    final rec = m.record(SheetsTables.protectedRange, c.rowId);
    if (rec is! ProtectedRangeRecord || rec.rangeJson == null) return false;
    final s = m.sheet(rec.sheetId);
    if (s == null) return false;
    final rects = s.ruleRects(RuleKind.protection, rec.id);
    if (rects.isEmpty) return false;
    bool all(AxisIndex axis, int from, int to) {
      for (var i = from; i <= to; i++) {
        if (!deleted.contains(axis.tryIdAt(i))) return false;
      }
      return true;
    }

    return rects.every(
      (r) => all(s.rows, r.top, r.bottom) || all(s.columns, r.left, r.right),
    );
  }

  static String? _sheetOf(RowChange c, WorkbookModel m) =>
      (c.columnsAfter[Cols.sheetId] ??
              c.columnsBefore[Cols.sheetId] ??
              m.currentColumns(c.table, c.rowId)?[Cols.sheetId])
          as String?;

  static void _addLine(
    Map<String, Map<Dimension, Map<StructuralOp, List<int>>>> m,
    String sheetId,
    Dimension dim,
    StructuralOp op,
    int index,
  ) => ((m[sheetId] ??= {})[dim] ??= {}).putIfAbsent(op, () => []).add(index);

  /// Index at which a line with ([key], [id]) lands in [axis], which is
  /// ordered by (sortKey, id).
  static int _insertionIndex(AxisIndex axis, String key, String id) {
    var lo = 0, hi = axis.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      final c = axis.sortKeyAt(mid).compareTo(key);
      if (c < 0 || (c == 0 && axis.idAt(mid).compareTo(id) < 0)) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}

final class _Acc {
  final hits = <ProtectionHit>[];
  var blocked = false;

  void add(GuardResult r) {
    if (r.isAllowed) return;
    hits.addAll(r.hits);
    if (r.isBlocked) blocked = true;
  }

  void block(ProtectionHit h) {
    hits.add(h);
    blocked = true;
  }

  void addInsert(
    ProtectionGuard guard,
    InsertBetween ins,
    String userId,
    bool isOwner,
  ) {
    final a = guard.check(ins.line(ins.before), userId, isOwner: isOwner);
    final b = guard.check(ins.line(ins.at), userId, isOwner: isOwner);
    final both = a.protectionIds.intersection(b.protectionIds);
    if (both.isEmpty) return;
    final inside = [
      for (final h in a.hits)
        if (both.contains(h.protectionId)) h,
    ];
    hits.addAll(inside);
    if (inside.any((h) => !h.warningOnly)) blocked = true;
  }

  GuardResult result() {
    if (hits.isEmpty) return GuardResult.allowed;
    final seen = <ProtectionHit>{};
    return GuardResult(blocked ? GuardStatus.blocked : GuardStatus.warnings, [
      for (final h in hits)
        if (seen.add(h)) h,
    ]);
  }
}

/// Recognizes the boundary repairs that deleting rows, columns or sheets
/// writes into formulas and rule ranges (RevLog spec 05 §3.5, Sheets 05
/// §5.4): such a change is exempt from the protection check only when it
/// changes nothing but references that named a line or sheet deleted by the
/// same op, so it can't be used to rewrite protected content.
abstract final class BoundaryRepair {
  /// Rule/range columns a repair may touch.
  static const rangeColumns = {
    'rangeJson',
    'rangesJson',
    'exceptRangesJson',
    'sourceRangeJson',
    'anchorJson',
    'startId',
    'endId',
    'anchorRowId',
    'anchorColId',
    'formula',
  };

  /// Ids of rows, columns and sheets deleted by [applied].
  static Set<String> deletedIds(List<RowChange> applied) => {
    for (final c in applied)
      if (c.op == RowOp.delete &&
          (c.table == SheetsTables.sheetRow ||
              c.table == SheetsTables.sheetColumn ||
              c.table == SheetsTables.sheet))
        c.rowId,
  };

  /// Whether [c] is a boundary repair for lines/sheets in [deleted].
  static bool isRepair(RowChange c, Set<String> deleted) {
    if (c.op != RowOp.update || c.columnsBefore.isEmpty) return false;
    if (c.table == SheetsTables.cell) {
      if (!c.touchedColumns.every((k) => k == CellCols.content)) return false;
      final before = c.columnsBefore[CellCols.content];
      final after = c.columnsAfter[CellCols.content];
      if (before is! String || after is! String) return false;
      if (!before.startsWith('=') || !after.startsWith('=')) return false;
      return isFormulaRepair(before, after, deleted);
    }
    if (!c.touchedColumns.every(rangeColumns.contains)) return false;
    for (final k in c.touchedColumns) {
      final before = c.columnsBefore[k];
      final after = c.columnsAfter[k];
      if (before == after) continue;
      if (before is! String) return false;
      if (after is String && after.startsWith('=') && before.startsWith('=')) {
        if (!isFormulaRepair(before, after, deleted)) return false;
        continue;
      }
      final b = _ids(before);
      if (!b.any(deleted.contains)) return false;
      final dropped = b.difference(after is String ? _ids(after) : const {});
      if (!dropped.every(deleted.contains)) return false;
    }
    return true;
  }

  /// Whether stored formula [after] differs from [before] only in
  /// references that named a deleted id (moved inward or `#REF!`).
  static bool isFormulaRepair(
    String before,
    String after,
    Set<String> deleted,
  ) {
    final b = _refs.allMatches(before).toList();
    final a = _refs.allMatches(after).toList();
    if (b.length != a.length) return false;
    if (before.replaceAll(_refs, '\u0000') !=
        after.replaceAll(_refs, '\u0000')) {
      return false;
    }
    var changed = false;
    for (var i = 0; i < b.length; i++) {
      final x = b[i].group(0)!;
      final y = a[i].group(0)!;
      if (x == y) continue;
      if (!_tokenIds(x).any(deleted.contains)) return false;
      changed = true;
    }
    return changed;
  }

  /// A stored reference (token or token range) or a `#REF!` left by a repair.
  static final _refs = RegExp('⟦[^⟧]*⟧(?::⟦[^⟧]*⟧)?|#REF!');
  static final _token = RegExp('⟦([^⟧]*)⟧');
  static final _uuid = RegExp(
    '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
  );

  static Set<String> _tokenIds(String ref) => {
    for (final m in _token.allMatches(ref))
      if (RefToken.decodeBody(m.group(1)!) case final t?) ...[
        ?t.sheetId,
        ?t.rowId,
        ?t.colId,
      ],
  };

  static Set<String> _ids(String s) => {
    for (final m in _uuid.allMatches(s.toLowerCase())) m.group(0)!,
    ..._tokenIds(s),
  };
}
