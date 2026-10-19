import 'dart:convert';

import 'package:uuid/uuid.dart';

/// Value type of a [RevColumn] (RevLog spec 02 §4).
enum RevColumnType { uuid, string, int, double, bool, dateTime, enumName, json }

/// How bootstrap pages cover a table (RevLog spec 06 §5.3).
enum RevCoverage {
  /// Keyset ranges of ids (`tbl:<table>:<from>:<to>`).
  structure,

  /// Sheets cells: every cell of a sheet row (`row:<sheetId>:<rowId>`).
  cellsByRow,
}

/// Marker default: the insert time (UTC), filled in by whoever applies the
/// insert first (the server).
const Object revDefaultNow = _RevDefaultNow();

final class _RevDefaultNow {
  const _RevDefaultNow();

  @override
  String toString() => "now";
}

/// One column of a [RevTable].
final class RevColumn {
  /// Creates a column.
  const RevColumn(
    this.name,
    this.type, {
    this.nullable = false,
    this.defaultValue,
    this.enumValues,
    this.maxLength,
    this.clientWritable = true,
    this.immutable = false,
  });

  /// Column name (Dart field name, as in the column maps).
  final String name;

  /// Value type.
  final RevColumnType type;

  /// Whether null is allowed.
  final bool nullable;

  /// Value used on insert when the column is missing (03 §4.2).
  final Object? defaultValue;

  /// Allowed names of an [RevColumnType.enumName] column.
  final List<String>? enumValues;

  /// Maximum length of string/json values (characters).
  final int? maxLength;

  /// False for columns only the server writes.
  final bool clientWritable;

  /// True for columns that may only be set on insert (cell keys, …).
  final bool immutable;

  Map<String, Object?> _canonical() => {
    'n': name,
    't': type.name,
    if (nullable) 'null': true,
    if (enumValues != null) 'e': enumValues,
    if (immutable) 'imm': true,
    if (!clientWritable) 'srv': true,
  };
}

/// A foreign key to a parent table: deleting the parent deletes the child
/// (the sequencer cascades explicitly, RD-3).
final class RevParent {
  /// Creates a parent link.
  const RevParent(this.column, this.table, {this.optional = false});

  /// The child's column holding the parent id.
  final String column;

  /// The parent table.
  final String table;

  /// Whether the column may be null (Slides element owners).
  final bool optional;
}

/// A plain (non-cascading) reference, documented for repairs and readers.
final class RevPlainRef {
  /// Creates a plain reference.
  const RevPlainRef(this.column, this.table);

  /// The column holding the referenced id.
  final String column;

  /// The referenced table (or a description such as `sheet_row|sheet_column`).
  final String table;
}

/// One table of a [RevSchema].
final class RevTable {
  /// Creates a table.
  const RevTable(
    this.name,
    this.columns, {
    this.parents = const [],
    this.plainRefs = const [],
    this.indexes = const [],
    this.rank = 0,
    this.deterministicIds = false,
    this.clientWritable = true,
    this.isRoot = false,
    this.coverage = RevCoverage.structure,
  });

  /// Table name.
  final String name;

  /// Columns except `id` (always a uuid primary key).
  final List<RevColumn> columns;

  /// Cascading parents.
  final List<RevParent> parents;

  /// Plain references.
  final List<RevPlainRef> plainRefs;

  /// Client cache indexes (column lists).
  final List<List<String>> indexes;

  /// Dependency order: parents have a lower rank.
  final int rank;

  /// Ids derived from other columns (UUIDv5), so two clients may insert the
  /// same row.
  final bool deterministicIds;

  /// False for tables only the server writes (Sheets `script_build`).
  final bool clientWritable;

  /// The root table (`spreadsheet` / `deck`); its row id is the file uuid.
  final bool isRoot;

  /// Bootstrap coverage of this table.
  final RevCoverage coverage;

  /// Columns by name (built on first use; tables are const).
  static final Expando<Map<String, RevColumn>> _byName = Expando();

  /// The column named [name], or null. Codecs and SQL call this per value.
  RevColumn? column(String name) =>
      (_byName[this] ??= {for (final c in columns) c.name: c})[name];

  /// Parent link of [column], or null.
  RevParent? parentOf(String column) {
    for (final p in parents) {
      if (p.column == column) return p;
    }
    return null;
  }

  /// Column names, without `id`.
  Iterable<String> get columnNames => columns.map((c) => c.name);

  Map<String, Object?> _canonical() => {
    'n': name,
    'c': [for (final c in columns) c._canonical()],
    'p': [
      for (final p in parents) [p.column, p.table, if (p.optional) 1],
    ],
    if (!clientWritable) 'srv': true,
    if (isRoot) 'root': true,
  };
}

/// Column groups written together (P4 coupled columns), per table.
typedef RevCoupledColumns = Map<String, List<Set<String>>>;

/// Tables whose inserts are column-wise (identity columns per table).
typedef RevColumnwiseInserts = Map<String, Set<String>>;

/// The tables of one app (Sheets or Slides): the single description used by
/// codecs, server SQL and the client cache (RevLog spec 02 §4).
final class RevSchema {
  /// Creates a schema; [tables] in dependency order.
  RevSchema(
    this.app,
    List<RevTable> tables, {
    this.coupled = const {},
    this.columnwise = const {},
    this.compatibleWith = const {},
  }) : tables = List.unmodifiable(tables),
       _byName = {for (final t in tables) t.name: t};

  /// `sheets` or `slides`.
  final String app;

  /// Tables in dependency order.
  final List<RevTable> tables;

  /// Coupled column groups (undo skip rule).
  final RevCoupledColumns coupled;

  /// Column-wise insert tables (undo).
  final RevColumnwiseInserts columnwise;

  /// Older schema hashes whose payloads this schema accepts (additive changes
  /// only, 02 §4.3).
  final Set<String> compatibleWith;

  final Map<String, RevTable> _byName;

  /// The table named [name]; throws [ArgumentError] when unknown.
  RevTable table(String name) =>
      _byName[name] ?? (throw ArgumentError.value(name, 'table', 'unknown'));

  /// The table named [name], or null.
  RevTable? tryTable(String name) => _byName[name];

  /// Dependency rank of [table] (unknown tables last).
  int rank(String table) => _byName[table]?.rank ?? 1 << 20;

  /// The root table.
  RevTable get root => tables.firstWhere((t) => t.isRoot);

  /// Child links: (child table, parent link) for every table whose parent is
  /// [table].
  Iterable<(RevTable, RevParent)> childrenOf(String table) sync* {
    for (final t in tables) {
      for (final p in t.parents) {
        if (p.table == table) yield (t, p);
      }
    }
  }

  late final String hash = _hash();

  String _hash() {
    final json = jsonEncode({
      'app': app,
      't': [for (final t in tables) t._canonical()],
    });
    return const Uuid().v5(_namespace, json);
  }

  static const _namespace = '6e8f3a2c-1d4b-5c7e-9f20-3a1b2c4d5e6f';
}
