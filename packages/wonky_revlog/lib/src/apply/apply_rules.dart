import '../codec/change_set.dart';
import '../rows/row_change.dart';
import '../schema/rev_schema.dart';

/// Rows an op is applied to (RevLog spec 03 §4).
abstract interface class RevRowStore {
  /// The full row (incl. `id`), or null when missing.
  Map<String, Object?>? row(String table, String id);

  /// Stores the full row.
  void put(String table, String id, Map<String, Object?> row);

  /// Removes the row (no cascade).
  void remove(String table, String id);

  /// Ids of rows of [childTable] whose [column] equals [parentId].
  Iterable<String> childIds(String childTable, String column, String parentId);
}

/// Why a change was dropped.
enum DropReason { rowMissing, parentMissing }

/// A submitted change that was not applied.
final class DroppedChange {
  /// Creates the record.
  const DroppedChange(this.change, this.reason);

  /// The submitted change.
  final RowChange change;

  /// Why.
  final DropReason reason;
}

/// A field whose value at apply time differed from the change's `before`
/// (03 §4.5). Attribution (who wrote it) is a server post-step.
final class FieldConflict {
  /// Creates the record.
  const FieldConflict(
    this.table,
    this.rowId,
    this.column,
    this.before,
    this.theirs,
  );

  /// Table.
  final String table;

  /// Row id.
  final String rowId;

  /// Column.
  final String column;

  /// What the author saw.
  final Object? before;

  /// The value that was overwritten.
  final Object? theirs;
}

/// Result of [applyChangeSet].
final class ApplyResult {
  /// Creates a result.
  ApplyResult({
    required this.applied,
    required this.dropped,
    required this.candidates,
    required this.cascaded,
    required this.equalsSubmitted,
  });

  /// The applied form (03 §4.7), `before` values = the stored values.
  final List<RowChange> applied;

  /// Dropped changes.
  final List<DroppedChange> dropped;

  /// Conflict candidates.
  final List<FieldConflict> candidates;

  /// Descendants deleted by cascade that the op didn't list (also in
  /// [applied]).
  final List<RowChange> cascaded;

  /// Whether [applied] equals the submitted changes (ignoring `before`).
  final bool equalsSubmitted;
}

/// Value equality used for conflicts and echo suppression: numbers by value,
/// date-times to the millisecond, enums by name.
bool revSameValue(Object? a, Object? b) => _norm(a) == _norm(b);

Object? _norm(Object? v) => switch (v) {
  num() => v.toDouble(),
  DateTime() => v.toUtc().millisecondsSinceEpoch,
  Enum() => v.name,
  _ => v,
};

/// Applies [cs] to [store] with the rules of RevLog spec 03 §4: ops in order,
/// last writer wins per column, inserts into existing rows merge their
/// non-null columns, changes to missing rows or under missing parents are
/// dropped, deletes cascade to descendants the op didn't list.
ApplyResult applyChangeSet(
  RevSchema schema,
  RevRowStore store,
  ChangeSet cs, {
  bool cascade = true,
}) => applyChanges(schema, store, cs.changes, cascade: cascade);

/// [applyChangeSet] over a plain change list.
ApplyResult applyChanges(
  RevSchema schema,
  RevRowStore store,
  List<RowChange> changes, {
  bool cascade = true,
}) {
  final applied = <RowChange>[];
  final dropped = <DroppedChange>[];
  final candidates = <FieldConflict>[];
  final cascaded = <RowChange>[];
  var merged = false;

  bool parentsExist(RevTable table, Map<String, Object?> values) {
    for (final p in table.parents) {
      final v = values[p.column];
      if (v == null) continue;
      if (store.row(p.table, v.toString()) == null) return false;
    }
    return true;
  }

  void deleteTree(String tableName, String id) {
    // Children first (recursively), then the row itself.
    for (final (child, link) in schema.childrenOf(tableName)) {
      for (final childId
          in store.childIds(child.name, link.column, id).toList()) {
        deleteTree(child.name, childId);
      }
    }
    final row = store.row(tableName, id);
    if (row == null) return;
    store.remove(tableName, id);
    final del = RowChange.delete(tableName, id, row);
    applied.add(del);
    cascaded.add(del);
  }

  for (final ch in changes) {
    final table = schema.table(ch.table);
    final current = store.row(ch.table, ch.rowId);
    switch (ch.op) {
      case RowOp.insert:
        final after = {...ch.columnsAfter}..remove(RowChange.idColumn);
        if (current == null) {
          final full = <String, Object?>{RowChange.idColumn: ch.rowId};
          for (final c in table.columns) {
            full[c.name] = after.containsKey(c.name)
                ? after[c.name]
                : identical(c.defaultValue, revDefaultNow)
                ? DateTime.now().toUtc()
                : c.defaultValue;
          }
          if (!parentsExist(table, full)) {
            dropped.add(DroppedChange(ch, DropReason.parentMissing));
            continue;
          }
          store.put(ch.table, ch.rowId, full);
          applied.add(RowChange.insert(ch.table, ch.rowId, full));
        } else {
          // Insert into an existing row: write its non-null columns (OS-4).
          merged = true;
          final before = <String, Object?>{};
          final next = <String, Object?>{};
          for (final e in after.entries) {
            if (e.value == null) continue;
            final cur = current[e.key];
            if (revSameValue(cur, e.value)) continue;
            if (cur != null) {
              candidates.add(
                FieldConflict(ch.table, ch.rowId, e.key, null, cur),
              );
            }
            before[e.key] = cur;
            next[e.key] = e.value;
          }
          if (next.isEmpty) continue;
          final updated = {...current, ...next};
          if (!parentsExist(table, updated)) {
            dropped.add(DroppedChange(ch, DropReason.parentMissing));
            continue;
          }
          store.put(ch.table, ch.rowId, updated);
          applied.add(RowChange.update(ch.table, ch.rowId, before, next));
        }
      case RowOp.update:
        if (current == null) {
          dropped.add(DroppedChange(ch, DropReason.rowMissing));
          continue;
        }
        final next = {...ch.columnsAfter}..remove(RowChange.idColumn);
        // Only the parents this update changes are checked: the others are
        // unchanged (a deleted parent would have removed the row), and a
        // server prefetches just the parents the op names (05 §3.2).
        final changedParents = {
          for (final e in next.entries)
            if (table.parentOf(e.key) != null) e.key: e.value,
        };
        if (changedParents.isNotEmpty && !parentsExist(table, changedParents)) {
          dropped.add(DroppedChange(ch, DropReason.parentMissing));
          continue;
        }
        final before = <String, Object?>{};
        for (final e in next.entries) {
          final cur = current[e.key];
          before[e.key] = cur;
          if (ch.columnsBefore.containsKey(e.key) &&
              !revSameValue(cur, ch.columnsBefore[e.key])) {
            candidates.add(
              FieldConflict(
                ch.table,
                ch.rowId,
                e.key,
                ch.columnsBefore[e.key],
                cur,
              ),
            );
          }
        }
        store.put(ch.table, ch.rowId, {...current, ...next});
        applied.add(RowChange.update(ch.table, ch.rowId, before, next));
      case RowOp.delete:
        if (current == null) {
          merged = true; // a no-op delete: applied differs from submitted
          continue;
        }
        if (cascade) {
          for (final (child, link) in schema.childrenOf(ch.table)) {
            for (final childId
                in store.childIds(child.name, link.column, ch.rowId).toList()) {
              deleteTree(child.name, childId);
            }
          }
        }
        store.remove(ch.table, ch.rowId);
        applied.add(RowChange.delete(ch.table, ch.rowId, current));
    }
  }
  final equal =
      !merged &&
      dropped.isEmpty &&
      cascaded.isEmpty &&
      applied.length == changes.length &&
      _sameIgnoringBefore(applied, changes);
  return ApplyResult(
    applied: applied,
    dropped: dropped,
    candidates: candidates,
    cascaded: cascaded,
    equalsSubmitted: equal,
  );
}

bool _sameIgnoringBefore(List<RowChange> a, List<RowChange> b) {
  for (var i = 0; i < a.length; i++) {
    final x = a[i], y = b[i];
    if (x.table != y.table || x.rowId != y.rowId || x.op != y.op) return false;
    if (x.op == RowOp.delete) continue;
    final ya = {...y.columnsAfter}..remove(RowChange.idColumn);
    final xa = {...x.columnsAfter}..remove(RowChange.idColumn);
    if (xa.length != ya.length) return false;
    for (final e in ya.entries) {
      if (!xa.containsKey(e.key) || !revSameValue(xa[e.key], e.value)) {
        return false;
      }
    }
  }
  return true;
}

/// Replays an applied form literally (no rules): inserts store full rows,
/// updates set columns, deletes remove (03 §4.7).
void replayApplied(RevRowStore store, List<RowChange> applied) {
  for (final ch in applied) {
    switch (ch.op) {
      case RowOp.insert:
        store.put(ch.table, ch.rowId, {
          ...ch.columnsAfter,
          RowChange.idColumn: ch.rowId,
        });
      case RowOp.update:
        final cur = store.row(ch.table, ch.rowId);
        if (cur == null) continue;
        store.put(ch.table, ch.rowId, {...cur, ...ch.columnsAfter});
      case RowOp.delete:
        store.remove(ch.table, ch.rowId);
    }
  }
}

/// An in-memory [RevRowStore] (tests, fake server, client overlays).
final class MapRowStore implements RevRowStore {
  /// Creates an empty store, or one over [rows] (table → id → row).
  MapRowStore([Map<String, Map<String, Map<String, Object?>>>? rows])
    : rows = rows ?? {};

  /// table → id → full row.
  final Map<String, Map<String, Map<String, Object?>>> rows;

  @override
  Map<String, Object?>? row(String table, String id) => rows[table]?[id];

  @override
  void put(String table, String id, Map<String, Object?> row) =>
      (rows[table] ??= {})[id] = Map.of(row);

  @override
  void remove(String table, String id) => rows[table]?.remove(id);

  @override
  Iterable<String> childIds(
    String childTable,
    String column,
    String parentId,
  ) => (rows[childTable] ?? const {}).entries
      .where((e) => e.value[column]?.toString() == parentId)
      .map((e) => e.key);

  /// A deep copy.
  MapRowStore copy() => MapRowStore({
    for (final t in rows.entries)
      t.key: {for (final r in t.value.entries) r.key: Map.of(r.value)},
  });

  /// Number of rows.
  int get length => rows.values.fold(0, (n, t) => n + t.length);
}
