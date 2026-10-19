import 'package:wonky_revlog/rows.dart';

/// An in-memory [CurrentRowReader]: table → id → columns.
class MemoryRows implements CurrentRowReader {
  MemoryRows([Map<String, Map<String, Map<String, Object?>>>? rows])
    : rows = rows ?? {};

  final Map<String, Map<String, Map<String, Object?>>> rows;

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) =>
      rows[table]?[rowId];

  /// Every row as `(table, columns)`.
  Iterable<(String, Map<String, Object?>)> allRows() sync* {
    for (final t in rows.entries) {
      for (final r in t.value.values) {
        yield (t.key, r);
      }
    }
  }

  /// Applies [changes] like an in-memory model.
  void apply(List<RowChange> changes) {
    for (final c in changes) {
      final t = rows.putIfAbsent(c.table, () => {});
      switch (c.op) {
        case RowOp.insert:
          t[c.rowId] = {...c.columnsAfter};
        case RowOp.update:
          t[c.rowId] = {...?t[c.rowId], ...c.columnsAfter};
        case RowOp.delete:
          t.remove(c.rowId);
      }
    }
  }
}
