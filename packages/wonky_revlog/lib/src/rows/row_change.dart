import 'dart:convert';

import 'package:collection/collection.dart';

/// Operation on a synced row.
enum RowOp { insert, update, delete }

/// One synced-row change of a `MutationPlan` (Sheets 02 §7, Slides 02 §12,
/// suite 12 §2).
///
/// - insert: [columnsAfter] holds every column of the new row (incl. `id`),
///   [columnsBefore] is empty.
/// - update: both maps hold only the touched columns (the writer names exactly
///   these columns in `columnValues`).
/// - delete: [columnsBefore] holds every column of the deleted row (so undo can
///   revive it with the same id), [columnsAfter] is empty.
///
/// Column maps hold UUIDs as canonical strings, enums by name, `DateTime`s
/// (UTC) and plain `double`/`int`/`bool`/`String` values
/// (`SyncedTableSpec.toColumns`).
final class RowChange {
  /// Creates a change.
  RowChange({
    required this.table,
    required this.rowId,
    required this.op,
    Map<String, Object?>? columnsBefore,
    Map<String, Object?>? columnsAfter,
  }) : columnsBefore = Map.unmodifiable(columnsBefore ?? const {}),
       columnsAfter = Map.unmodifiable(columnsAfter ?? const {});

  /// An insert of a full row.
  factory RowChange.insert(
    String table,
    String rowId,
    Map<String, Object?> columns,
  ) => RowChange(
    table: table,
    rowId: rowId,
    op: RowOp.insert,
    columnsAfter: {...columns, idColumn: rowId},
  );

  /// An update naming only the touched columns.
  factory RowChange.update(
    String table,
    String rowId,
    Map<String, Object?> before,
    Map<String, Object?> after,
  ) => RowChange(
    table: table,
    rowId: rowId,
    op: RowOp.update,
    columnsBefore: before,
    columnsAfter: after,
  );

  /// A delete with the full previous row.
  factory RowChange.delete(
    String table,
    String rowId,
    Map<String, Object?> fullRow,
  ) => RowChange(
    table: table,
    rowId: rowId,
    op: RowOp.delete,
    columnsBefore: {...fullRow, idColumn: rowId},
  );

  /// The id column of every synced table.
  static const idColumn = 'id';

  /// Table name.
  final String table;

  /// Row id (canonical UUID string).
  final String rowId;

  /// Operation.
  final RowOp op;

  /// Column values before the change (see class doc).
  final Map<String, Object?> columnsBefore;

  /// Column values after the change (see class doc).
  final Map<String, Object?> columnsAfter;

  /// Alias of [columnsBefore] (Sheets 13 §4.1 naming).
  Map<String, Object?> get before => columnsBefore;

  /// Alias of [columnsAfter] (Sheets 13 §4.1 naming).
  Map<String, Object?> get after => columnsAfter;

  /// Names of the touched columns (for `columnValues`).
  Set<String> get touchedColumns => switch (op) {
    RowOp.insert => columnsAfter.keys.toSet(),
    RowOp.update => columnsAfter.keys.toSet(),
    RowOp.delete => columnsBefore.keys.toSet(),
  };

  /// The inverse change (undo): insert ↔ delete, update swaps before/after.
  RowChange inverse() => switch (op) {
    RowOp.insert => RowChange(
      table: table,
      rowId: rowId,
      op: RowOp.delete,
      columnsBefore: columnsAfter,
    ),
    RowOp.delete => RowChange(
      table: table,
      rowId: rowId,
      op: RowOp.insert,
      columnsAfter: columnsBefore,
    ),
    RowOp.update => RowChange(
      table: table,
      rowId: rowId,
      op: RowOp.update,
      columnsBefore: columnsAfter,
      columnsAfter: columnsBefore,
    ),
  };

  /// JSON (DateTimes as `{"$date": ISO}` maps).
  Map<String, Object?> toJson() => {
    'table': table,
    'rowId': rowId,
    'op': op.name,
    'before': _jsonColumns(columnsBefore),
    'after': _jsonColumns(columnsAfter),
  };

  /// From [toJson] output (DateTimes restored).
  static RowChange fromJson(Map<String, Object?> m) => RowChange(
    table: m['table']! as String,
    rowId: m['rowId']! as String,
    op: RowOp.values.byName(m['op']! as String),
    columnsBefore: _fromJsonColumns(m['before']),
    columnsAfter: _fromJsonColumns(m['after']),
  );

  static Map<String, Object?> _jsonColumns(Map<String, Object?> c) => {
    for (final e in c.entries)
      e.key: e.value is DateTime
          ? {'\$date': (e.value! as DateTime).toUtc().toIso8601String()}
          : e.value,
  };

  static Map<String, Object?> _fromJsonColumns(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final e in raw.entries)
        e.key
            as String: e.value is Map && (e.value as Map).containsKey('\$date')
            ? DateTime.parse((e.value as Map)['\$date'] as String)
            : e.value,
    };
  }

  static const _eq = DeepCollectionEquality();

  @override
  bool operator ==(Object other) =>
      other is RowChange &&
      other.table == table &&
      other.rowId == rowId &&
      other.op == op &&
      _eq.equals(other.columnsBefore, columnsBefore) &&
      _eq.equals(other.columnsAfter, columnsAfter);

  @override
  int get hashCode => Object.hash(table, rowId, op, _eq.hash(columnsAfter));

  @override
  String toString() =>
      'RowChange(${op.name} $table $rowId ${jsonEncode(toJson()['after'])})';
}

/// Reads current column values of synced rows (implemented by the in-memory
/// models and by writers over their database).
abstract interface class CurrentRowReader {
  /// Current columns of the row, or null when it does not exist.
  Map<String, Object?>? currentColumns(String table, String rowId);
}
