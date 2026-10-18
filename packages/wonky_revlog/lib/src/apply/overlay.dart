import '../codec/change_set.dart';
import '../rows/row_change.dart';
import '../rows/row_patch.dart';
import '../schema/rev_schema.dart';
import 'apply_rules.dart';

/// Keeps a client model equal to `applyAll(outbox, server state)` (RevLog
/// spec 03 §7).
///
/// The overlay remembers the **server** version of every row the outbox
/// touches (the shadow; for all other rows the model equals the server).
/// When a remote op or an ack's applied form arrives, the touched rows are
/// rebuilt as "server rows after the op, with the outbox replayed by the
/// apply rules", and the difference to the model is returned as a patch.
final class RevOverlay {
  /// Creates an overlay for [schema].
  RevOverlay(this.schema);

  /// The schema.
  final RevSchema schema;

  /// (table, id) → server row (null = absent on the server).
  final Map<(String, String), Map<String, Object?>?> _shadow = {};

  /// The keys of every outbox op seen (by identity) and, per key, the ops
  /// touching it: an index of the outbox, kept in step by [_sync], so a
  /// rebuild or a prune costs the size of the changed ops, not of the
  /// whole outbox (an import of 1M cells is 200 ops).
  final Map<ChangeSet, Set<(String, String)>> _opKeys = Map.identity();
  final Map<(String, String), List<ChangeSet>> _keyOps = {};

  /// Keys to check at the next [prune]: shadowed since ([captureLocal],
  /// [seed]) or no longer touched by any op ([_sync]).
  final Set<(String, String)> _added = {};

  /// Brings the index to [outbox].
  void _sync(List<ChangeSet> outbox) {
    if (_opKeys.length != outbox.length || !outbox.every(_opKeys.containsKey)) {
      final live = Set<ChangeSet>.identity()..addAll(outbox);
      for (final op in _opKeys.keys.toList()) {
        if (live.contains(op)) continue;
        for (final k in _opKeys.remove(op)!) {
          final ops = _keyOps[k]!..remove(op);
          if (ops.isEmpty) {
            _keyOps.remove(k);
            _added.add(k);
          }
        }
      }
      for (final op in outbox) {
        if (_opKeys.containsKey(op)) continue;
        final keys = {for (final c in op.changes) (c.table, c.rowId)};
        _opKeys[op] = keys;
        for (final k in keys) {
          (_keyOps[k] ??= []).add(op);
        }
      }
    }
  }

  /// Number of shadowed rows (tests, diagnostics).
  int get shadowSize => _shadow.length;

  /// Whether the outbox touches (table, id).
  bool isShadowed(String table, String id) => _shadow.containsKey((table, id));

  /// The server version of a shadowed row.
  Map<String, Object?>? serverRow(String table, String id) =>
      _shadow[(table, id)];

  /// Call **before** applying local [changes] to the model: remembers the
  /// server version of rows the outbox didn't touch yet.
  void captureLocal(Iterable<RowChange> changes, CurrentRowReader model) {
    for (final c in changes) {
      final key = (c.table, c.rowId);
      if (_shadow.containsKey(key)) continue;
      final cur = model.currentColumns(c.table, c.rowId);
      _shadow[key] = cur == null ? null : {...cur, RowChange.idColumn: c.rowId};
      _added.add(key);
    }
  }

  /// Seeds the shadow from stored server rows (session restore: the model is
  /// built from the store and then the outbox is applied).
  void seed(String table, String id, Map<String, Object?>? serverRow) {
    _shadow[(table, id)] = serverRow == null ? null : Map.of(serverRow);
    _added.add((table, id));
  }

  /// A remote op (applied form) arrived; returns the model patch. [outbox]:
  /// this client's unacknowledged ops, oldest first.
  List<RowChange> remote(
    List<RowChange> applied,
    List<ChangeSet> outbox,
    CurrentRowReader model,
  ) => _rebuild(applied, outbox, model);

  /// This client's op was acknowledged with [applied] (the applied form, or
  /// the submitted changes). [remaining]: the outbox without the op. Returns
  /// the model patch (empty when the server applied exactly what was sent).
  List<RowChange> acked(
    ChangeSet op,
    List<RowChange> applied,
    List<ChangeSet> remaining,
    CurrentRowReader model,
  ) {
    // Rows the op touched but the server dropped are rebuilt too.
    final keys = <(String, String)>{
      for (final c in applied) (c.table, c.rowId),
      for (final c in op.changes) (c.table, c.rowId),
    };
    final patch = _rebuildKeys(keys, applied, remaining, model);
    prune(remaining);
    return patch;
  }

  /// A rejected op left the outbox: rebuilds its rows from the server
  /// versions plus [remaining].
  List<RowChange> rejected(
    List<ChangeSet> rejectedOps,
    List<ChangeSet> remaining,
    CurrentRowReader model,
  ) {
    final keys = <(String, String)>{
      for (final op in rejectedOps)
        for (final c in op.changes) (c.table, c.rowId),
    };
    final patch = _rebuildKeys(keys, const [], remaining, model);
    prune(remaining);
    return patch;
  }

  /// Rebuilds the model rows of [keys] from their server versions (seeded)
  /// plus [outbox]: after bootstrap pages replaced server rows the outbox
  /// touches (RevLog spec 06 §5.3).
  List<RowChange> rebuild(
    Set<(String, String)> keys,
    List<ChangeSet> outbox,
    CurrentRowReader model,
  ) => _rebuildKeys(keys, const [], outbox, model);

  /// Drops shadow entries no op of [outbox] touches any more.
  void prune(List<ChangeSet> outbox) {
    _sync(outbox);
    for (final k in _added) {
      if (!_keyOps.containsKey(k)) _shadow.remove(k);
    }
    _added.clear();
  }

  /// Clears everything (re-bootstrap).
  void clear() {
    _shadow.clear();
    _opKeys.clear();
    _keyOps.clear();
    _added.clear();
  }

  List<RowChange> _rebuild(
    List<RowChange> applied,
    List<ChangeSet> outbox,
    CurrentRowReader model,
  ) {
    final keys = <(String, String)>{
      for (final c in applied) (c.table, c.rowId),
    };
    _addOrphans(keys, applied, outbox, model);
    return _rebuildKeys(keys, applied, outbox, model);
  }

  /// Adds the outbox rows whose parent chain [applied] deletes (e.g. a
  /// local cell under a row another user deleted): the server will drop
  /// them, so they leave the model now rather than at the ack.
  void _addOrphans(
    Set<(String, String)> keys,
    List<RowChange> applied,
    List<ChangeSet> outbox,
    CurrentRowReader model,
  ) {
    final gone = <(String, String)>{
      for (final c in applied)
        if (c.op == RowOp.delete) (c.table, c.rowId),
    };
    if (gone.isEmpty) return;
    final candidates = <(String, String), Map<String, Object?>>{};
    for (final op in outbox) {
      for (final c in op.changes) {
        if (c.op == RowOp.delete) continue;
        final t = schema.tryTable(c.table);
        if (t == null || t.parents.isEmpty) continue;
        final k = (c.table, c.rowId);
        candidates[k] = {
          ...?model.currentColumns(c.table, c.rowId),
          ...?candidates[k],
          ...c.columnsAfter,
        };
      }
    }
    var grew = true;
    while (grew) {
      grew = false;
      for (final MapEntry(key: k, value: cols) in candidates.entries) {
        if (gone.contains(k)) continue;
        final orphan = schema
            .table(k.$1)
            .parents
            .any((p) => gone.contains((p.table, '${cols[p.column]}')));
        if (orphan) {
          gone.add(k);
          keys.add(k);
          grew = true;
        }
      }
    }
  }

  List<RowChange> _rebuildKeys(
    Set<(String, String)> keys,
    List<RowChange> applied,
    List<ChangeSet> outbox,
    CurrentRowReader model,
  ) {
    if (keys.isEmpty) return const [];
    // Server rows of the touched keys before the op.
    final store = _CompositeStore(model);
    for (final k in keys) {
      final base = _shadow.containsKey(k)
          ? _shadow[k]
          : _withId(model.currentColumns(k.$1, k.$2), k.$2);
      store.local[k] = base;
    }
    replayApplied(store, applied);
    for (final k in keys) {
      if (_shadow.containsKey(k)) _shadow[k] = store.local[k];
    }
    // The outbox, replayed by the rules, restricted to the touched keys
    // (only the ops that touch one of them, found through the index).
    _sync(outbox);
    final touching = Set<ChangeSet>.identity();
    for (final k in keys) {
      touching.addAll(_keyOps[k] ?? const []);
    }
    for (final op in outbox) {
      if (!touching.contains(op)) continue;
      final mine = [
        for (final c in op.changes)
          if (keys.contains((c.table, c.rowId))) c,
      ];
      if (mine.isNotEmpty) applyChanges(schema, store, mine, cascade: false);
    }
    // Patch: deletes (children first), then upserts (parents first).
    final deletes = <RowChange>[];
    final upserts = <RowChange>[];
    final ordered = keys.toList()
      ..sort((a, b) => schema.rank(a.$1).compareTo(schema.rank(b.$1)));
    for (final k in ordered) {
      final next = store.local[k];
      final cur = model.currentColumns(k.$1, k.$2);
      if (next == null) {
        if (cur != null) {
          deletes.add(RowChange(table: k.$1, rowId: k.$2, op: RowOp.delete));
        }
      } else if (cur == null ||
          !RowPatch.sameColumns(cur, next) ||
          !RowPatch.sameColumns(next, cur)) {
        final cols = {...next}..remove(RowChange.idColumn);
        upserts.add(RowChange.insert(k.$1, k.$2, cols));
      }
    }
    return [...deletes.reversed, ...upserts];
  }

  static Map<String, Object?>? _withId(Map<String, Object?>? row, String id) =>
      row == null ? null : {...row, RowChange.idColumn: id};
}

/// Rows of the rebuild (local) over the model (for parent checks).
final class _CompositeStore implements RevRowStore {
  _CompositeStore(this.model);

  final CurrentRowReader model;
  final Map<(String, String), Map<String, Object?>?> local = {};

  @override
  Map<String, Object?>? row(String table, String id) {
    final k = (table, id);
    if (local.containsKey(k)) return local[k];
    final cur = model.currentColumns(table, id);
    return cur == null ? null : {...cur, RowChange.idColumn: id};
  }

  @override
  void put(String table, String id, Map<String, Object?> row) =>
      local[(table, id)] = Map.of(row);

  @override
  void remove(String table, String id) => local[(table, id)] = null;

  @override
  Iterable<String> childIds(
    String childTable,
    String column,
    String parentId,
  ) => const [];
}
