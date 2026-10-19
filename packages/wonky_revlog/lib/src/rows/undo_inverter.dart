import 'mutation_plan.dart';
import 'row_change.dart';

/// Receives the `(table, rowId, column)` triples undo skipped.
typedef SkippedColumn =
    void Function(String table, String rowId, String column);

/// Columns that must be skipped together by undo (Slides 02 P4): when any
/// column of a group was changed by someone else, undo skips the whole
/// group so coupled values (`groupId` + `sortKey`, a frame) never tear.
abstract interface class CoupledColumns {
  /// The group of [column] in [table] (including [column]), or null when the
  /// column is not coupled.
  Set<String>? groupOf(String table, String column);
}

/// [CoupledColumns] from a fixed table → groups map.
final class TableCoupledColumns implements CoupledColumns {
  /// Creates the rule from [groups] (table → column groups).
  const TableCoupledColumns(this.groups);

  /// Column groups per table.
  final Map<String, List<Set<String>>> groups;

  @override
  Set<String>? groupOf(String table, String column) {
    for (final g in groups[table] ?? const <Set<String>>[]) {
      if (g.contains(column)) return g;
    }
    return null;
  }
}

/// Tables whose inserts are undone column by column (a table hook of
/// [UndoInverter]; Sheets' cells, Sheets 02 §7 / 10 §10 #16): undoing an
/// insert someone else changed since (any non-identity column) doesn't
/// delete the row; the columns still holding what the insert wrote are
/// cleared, the others are skipped.
abstract interface class ColumnwiseInserts {
  /// The identity columns of [table] (never cleared by undo; `id` is always
  /// one), or null when the table's inserts undo as a whole-row delete.
  Set<String>? identityColumns(String table);
}

/// [ColumnwiseInserts] from a fixed table → identity columns map.
final class TableColumnwiseInserts implements ColumnwiseInserts {
  /// Creates the rule from [tables] (table → identity columns).
  const TableColumnwiseInserts(this.tables);

  /// Identity columns per column-wise table.
  final Map<String, Set<String>> tables;

  @override
  Set<String>? identityColumns(String table) => tables[table];
}

/// Builds the undo of a plan against the current state with the suite skip
/// rule (08 §3.3, Sheets 02 §7, Slides 02 §12.2): a column whose current
/// value differs from what the plan wrote (someone else changed it since) is
/// skipped. Deleted rows are revived with their ids.
///
/// Table hooks: [CoupledColumns] skip column groups as a unit;
/// [ColumnwiseInserts] undo inserts column by column.
abstract final class UndoInverter {
  /// The changes that undo [plan] given [current]. [skipped] receives the
  /// skipped columns.
  static List<RowChange> invert(
    MutationPlan<ChangeSummary> plan,
    CurrentRowReader current, {
    CoupledColumns? coupled,
    ColumnwiseInserts? columnwise,
    SkippedColumn? skipped,
  }) => invertChanges(
    plan.changes,
    current,
    coupled: coupled,
    columnwise: columnwise,
    skipped: skipped,
  );

  /// [invert] for a raw change list.
  static List<RowChange> invertChanges(
    List<RowChange> changes,
    CurrentRowReader current, {
    CoupledColumns? coupled,
    ColumnwiseInserts? columnwise,
    SkippedColumn? skipped,
  }) {
    const id = RowChange.idColumn;
    final out = <RowChange>[];
    for (final c in changes.reversed) {
      final now = current.currentColumns(c.table, c.rowId);
      switch (c.op) {
        case RowOp.insert:
          // Undo an insert = delete, unless the row is gone already.
          if (now == null) continue;
          final identity = columnwise?.identityColumns(c.table);
          if (identity != null) {
            final keys = {...c.columnsAfter.keys, ...now.keys}
              ..remove(id)
              ..removeAll(identity);
            final changed = _withGroups(
              {
                for (final k in keys)
                  if (!_eq(now[k], c.columnsAfter[k])) k,
              },
              keys,
              c.table,
              coupled,
            );
            if (changed.isNotEmpty) {
              for (final k in changed) {
                skipped?.call(c.table, c.rowId, k);
              }
              final before = <String, Object?>{};
              final after = <String, Object?>{};
              for (final k in keys) {
                if (changed.contains(k) || now[k] == null) continue;
                before[k] = now[k];
                after[k] = null;
              }
              if (after.isNotEmpty) {
                out.add(RowChange.update(c.table, c.rowId, before, after));
              }
              continue;
            }
          }
          out.add(RowChange.delete(c.table, c.rowId, now));
        case RowOp.delete:
          if (now != null) {
            // Revived by someone else: restore the columns we can.
            final before = <String, Object?>{};
            final after = <String, Object?>{};
            c.columnsBefore.forEach((k, v) {
              if (k == id) return;
              if (!_eq(now[k], v)) {
                before[k] = now[k];
                after[k] = v;
              }
            });
            if (after.isNotEmpty) {
              out.add(RowChange.update(c.table, c.rowId, before, after));
            }
          } else {
            out.add(RowChange.insert(c.table, c.rowId, c.columnsBefore));
          }
        case RowOp.update:
          if (now == null) {
            for (final k in c.columnsAfter.keys) {
              skipped?.call(c.table, c.rowId, k);
            }
            continue;
          }
          final skip = _withGroups(
            {
              for (final e in c.columnsAfter.entries)
                if (!_eq(now[e.key], e.value)) e.key,
            },
            c.columnsAfter.keys,
            c.table,
            coupled,
          );
          final before = <String, Object?>{};
          final after = <String, Object?>{};
          c.columnsAfter.forEach((k, v) {
            if (skip.contains(k)) {
              skipped?.call(c.table, c.rowId, k);
            } else {
              before[k] = v;
              after[k] = c.columnsBefore[k];
            }
          });
          if (after.isNotEmpty) {
            out.add(RowChange.update(c.table, c.rowId, before, after));
          }
      }
    }
    return out;
  }

  /// [columns] plus the other members of their coupled groups that are in
  /// [scope].
  static Set<String> _withGroups(
    Set<String> columns,
    Iterable<String> scope,
    String table,
    CoupledColumns? coupled,
  ) {
    if (coupled == null || columns.isEmpty) return columns;
    final inScope = scope.toSet();
    final out = {...columns};
    for (final k in columns) {
      final group = coupled.groupOf(table, k);
      if (group == null) continue;
      for (final g in group) {
        if (inScope.contains(g)) out.add(g);
      }
    }
    return out;
  }

  static bool _eq(Object? a, Object? b) {
    if (a is num && b is num) return a.toDouble() == b.toDouble();
    if (a is DateTime && b is DateTime) return a.isAtSameMomentAs(b);
    return a == b;
  }
}
