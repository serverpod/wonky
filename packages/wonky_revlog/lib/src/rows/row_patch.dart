import 'row_change.dart';

/// Orders tables for patches (parents first), e.g. `SyncTableSet.rank`.
typedef TableRank = int Function(String table);

/// Builds the [RowChange]s that bring an in-memory model in line with rows
/// read from the replica (Sheets 02 §6 change ingestion, Slides 02 §11).
///
/// Rows still queued for the writer (`pending`, oldest first) are overlaid
/// on the replica rows, so a remote patch never undoes an optimistic local
/// edit that isn't stored yet. Rows whose model columns already equal the
/// replica (the echo of the device's own writes) produce no change.
///
/// Patches list deletes first (children before parents), then upserts
/// (parents first) as full-row inserts.
abstract final class RowPatch {
  /// Changes for the rows [changed] (table → row ids) given their current
  /// replica values [rows] (table → id → columns; missing = not visible).
  static List<RowChange> build(
    CurrentRowReader model,
    Map<String, Iterable<String>> changed,
    Map<String, Map<String, Map<String, Object?>>> rows,
    List<RowChange> pending, {
    required TableRank rank,
  }) {
    final targets = <String, Map<String, Map<String, Object?>?>>{};
    for (final e in changed.entries) {
      final byId = rows[e.key] ?? const {};
      final t = targets.putIfAbsent(e.key, () => {});
      for (final id in e.value) {
        t[id] = byId[id];
      }
    }
    _overlay(targets, pending);
    return _diff(model, targets, rank);
  }

  /// Changes that turn [model] (whose rows are [modelRows]) into exactly
  /// [all] (every model row of the space, as read from the replica) plus
  /// [pending].
  static List<RowChange> reconcile(
    CurrentRowReader model,
    Iterable<(String, Map<String, Object?>)> modelRows,
    List<(String, Map<String, Object?>)> all,
    List<RowChange> pending, {
    required TableRank rank,
  }) {
    const id = RowChange.idColumn;
    final targets = <String, Map<String, Map<String, Object?>?>>{};
    for (final (table, columns) in all) {
      targets.putIfAbsent(table, () => {})['${columns[id]}'] = columns;
    }
    for (final (table, columns) in modelRows) {
      targets
          .putIfAbsent(table, () => {})
          .putIfAbsent('${columns[id]}', () => null);
    }
    _overlay(targets, pending);
    return _diff(model, targets, rank);
  }

  static void _overlay(
    Map<String, Map<String, Map<String, Object?>?>> targets,
    List<RowChange> pending,
  ) {
    for (final c in pending) {
      final t = targets[c.table];
      if (t == null || !t.containsKey(c.rowId)) continue;
      final row = t[c.rowId];
      t[c.rowId] = switch (c.op) {
        RowOp.insert => {...c.columnsAfter, RowChange.idColumn: c.rowId},
        RowOp.update => row == null ? null : {...row, ...c.columnsAfter},
        RowOp.delete => null,
      };
    }
  }

  static List<RowChange> _diff(
    CurrentRowReader model,
    Map<String, Map<String, Map<String, Object?>?>> targets,
    TableRank rank,
  ) {
    final tables = targets.keys.toList()
      ..sort((a, b) => rank(a).compareTo(rank(b)));
    final deletes = <RowChange>[];
    final upserts = <RowChange>[];
    for (final table in tables) {
      for (final e in targets[table]!.entries) {
        final current = model.currentColumns(table, e.key);
        final next = e.value;
        if (next == null) {
          if (current != null) {
            deletes.add(
              RowChange(table: table, rowId: e.key, op: RowOp.delete),
            );
          }
        } else if (current == null || !sameColumns(current, next)) {
          upserts.add(RowChange.insert(table, e.key, next));
        }
      }
    }
    return [...deletes.reversed, ...upserts];
  }

  /// Whether every column of [next] has the same value in [current]
  /// (numbers by value, times to the millisecond, enums by name).
  static bool sameColumns(
    Map<String, Object?> current,
    Map<String, Object?> next,
  ) {
    for (final e in next.entries) {
      if (_norm(current[e.key]) != _norm(e.value)) return false;
    }
    return true;
  }

  static Object? _norm(Object? v) => switch (v) {
    num() => v.toDouble(),
    DateTime() => v.toUtc().millisecondsSinceEpoch,
    Enum() => v.name,
    _ => v,
  };
}
