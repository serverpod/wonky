import 'package:wonky_revlog/rows.dart';

import '../model/api/deck_model.dart';
import '../model/api/records.dart';
import '../schema/slides_schema.dart';

/// Collects the row changes of one plan over a [DeckModel] (02 §12.1).
///
/// The builder keeps an overlay of the rows the plan touched, so later steps
/// of the same plan read what earlier steps wrote ([row], [rec]), and it
/// coalesces every touch of one row into **one** [RowChange] (the undo
/// inverter compares each change with the current row, so a row may appear
/// only once per plan):
///
/// - updates name exactly the columns whose value changes, plus the columns
///   a step forces together (coupled columns, 02 P4);
/// - an insert followed by updates is one insert; an insert followed by a
///   delete is nothing; a delete followed by an insert is an update;
/// - deletes carry the full row so undo can revive it.
final class PlanBuilder implements CurrentRowReader {
  /// Creates a builder over [base].
  PlanBuilder(this.base);

  /// The model the plan is computed against (never mutated).
  final DeckModel base;

  /// table → id → current columns (null = deleted in this plan).
  final Map<String, Map<String, Map<String, Object?>?>> _overlay = {};

  /// Touched rows in first-touch order (`table|id`).
  final List<(String, String)> _order = [];
  final Set<String> _touched = {};

  /// Columns forced into an update although unchanged (`table|id` → cols).
  final Map<String, Set<String>> _forced = {};

  static String _k(String table, String id) => '$table|$id';

  void _touch(String table, String id) {
    if (_touched.add(_k(table, id))) _order.add((table, id));
  }

  /// The current columns of a row (the plan's view), or null when missing
  /// or deleted by this plan.
  Map<String, Object?>? row(String table, String id) {
    final t = _overlay[table];
    if (t != null && t.containsKey(id)) return t[id];
    return base.currentColumns(table, id);
  }

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) {
    final r = row(table, rowId);
    return r == null ? null : Map.of(r);
  }

  /// The current record of a row (the plan's view), or null.
  SlidesRecord? rec(String table, String id) {
    final t = _overlay[table];
    if (t != null && t.containsKey(id)) {
      final c = t[id];
      return c == null ? null : slidesRecordFromColumns(table, c);
    }
    return base.record(table, id);
  }

  /// Records of [table] in the plan's view (base rows with the plan's
  /// updates and deletes applied, then rows inserted by the plan).
  Iterable<SlidesRecord> records(String table) sync* {
    final t = _overlay[table];
    for (final r in base.records(table)) {
      if (t != null && t.containsKey(r.id)) {
        final c = t[r.id];
        if (c != null) yield slidesRecordFromColumns(table, c);
      } else {
        yield r;
      }
    }
    yield* inserted(table);
  }

  /// Rows of [table] the plan inserted that are not in the base model.
  Iterable<SlidesRecord> inserted(String table) sync* {
    final t = _overlay[table];
    if (t == null) return;
    for (final e in t.entries) {
      final c = e.value;
      if (c != null && base.record(table, e.key) == null) {
        yield slidesRecordFromColumns(table, c);
      }
    }
  }

  /// Whether the row exists in the plan's view.
  bool exists(String table, String id) => row(table, id) != null;

  /// Whether the plan touched the row.
  bool touched(String table, String id) => _touched.contains(_k(table, id));

  /// Inserts a full row ([columns] must hold `id`; missing columns of the
  /// table are null). Inserting an existing row overwrites its columns.
  void insert(String table, Map<String, Object?> columns) {
    final id = columns[SlidesCols.id]! as String;
    final full = <String, Object?>{
      for (final c in SlidesTables.columns[table] ?? const <String>{}) c: null,
      ...columns,
    };
    _touch(table, id);
    (_overlay[table] ??= {})[id] = full;
  }

  /// Sets [after] on an existing row. Columns whose value doesn't change are
  /// dropped, except those in [together] (written as a set, 02 P4). Missing
  /// rows are ignored (returns false).
  bool update(
    String table,
    String id,
    Map<String, Object?> after, {
    Set<String> together = const {},
  }) {
    final cur = row(table, id);
    if (cur == null) return false;
    final changes = {
      for (final e in after.entries)
        if (cur[e.key] != e.value) e.key: e.value,
    };
    final forced = {
      for (final k in together)
        if (after.containsKey(k)) k,
    };
    if (changes.isEmpty) return false;
    _touch(table, id);
    (_overlay[table] ??= {})[id] = {...cur, ...changes};
    if (forced.isNotEmpty) (_forced[_k(table, id)] ??= {}).addAll(forced);
    return true;
  }

  /// [update] on a record.
  bool set(
    SlidesRecord r,
    Map<String, Object?> after, {
    Set<String> together = const {},
  }) => update(r.table, r.id, after, together: together);

  /// Deletes a row (no-op when missing).
  void delete(String table, String id) {
    if (row(table, id) == null) return;
    _touch(table, id);
    (_overlay[table] ??= {})[id] = null;
  }

  /// Deletes a record.
  void remove(SlidesRecord r) => delete(r.table, r.id);

  /// The coalesced changes in first-touch order.
  List<RowChange> build() {
    final out = <RowChange>[];
    for (final (table, id) in _order) {
      final before = base.currentColumns(table, id);
      final after = _overlay[table]![id];
      if (before == null && after == null) continue;
      if (before == null) {
        out.add(RowChange.insert(table, id, after!));
        continue;
      }
      if (after == null) {
        out.add(RowChange.delete(table, id, before));
        continue;
      }
      final forced = _forced[_k(table, id)] ?? const <String>{};
      final cols = {
        for (final k in {...before.keys, ...after.keys})
          if (before[k] != after[k] || forced.contains(k)) k,
      };
      if (!cols.any((k) => before[k] != after[k])) continue;
      out.add(
        RowChange.update(
          table,
          id,
          {for (final k in cols) k: before[k]},
          {for (final k in cols) k: after[k]},
        ),
      );
    }
    return out;
  }
}
