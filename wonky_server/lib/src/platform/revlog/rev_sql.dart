import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

/// Set-based reads and writes of a file's domain rows, generated from the
/// [RevSchema] (RevLog spec 05 §3.3).
///
/// Domain tables have the schema's columns plus `id`, `fileId` and
/// `revision` (02 §2.1). Values in memory follow the column-map
/// conventions (lower-case UUID strings, enum names, UTC `DateTime`,
/// `double`); writes send them as one binary array per column (`unnest`),
/// prefetches read one row of typed arrays per table, and the cascade and
/// headless reads take rows as JSON (`json_strip_nulls(row_to_json(t))`).
final class RevSql {
  /// Creates the SQL layer of [schema]. [perSheetTables] are never read or
  /// deleted by `fileId` (Sheets `cell`, 02 §2.2).
  RevSql(this.schema, {this.perSheetTables = const {}});

  /// The schema.
  final RevSchema schema;

  /// Tables without a `fileId` index.
  final Set<String> perSheetTables;

  /// Rows per statement (05 §3.3 runs).
  static const runSize = 1000;

  // --------------------------------------------------------------- types

  /// The Postgres type of a column of [type] (as Serverpod creates it).
  static String pgType(RevColumnType type) => switch (type) {
    RevColumnType.uuid => 'uuid',
    RevColumnType.string ||
    RevColumnType.json ||
    RevColumnType.enumName => 'text',
    RevColumnType.int => 'bigint',
    RevColumnType.double => 'double precision',
    RevColumnType.bool => 'boolean',
    RevColumnType.dateTime => 'timestamp without time zone',
  };

  /// `"name"`.
  static String q(String name) => '"${name.replaceAll('"', '""')}"';

  /// The select expression of a row `t` as JSON text without its null
  /// columns (most cell columns are null; [rowFromJson] reads absent
  /// columns as null).
  static const rowJson = 'json_strip_nulls(row_to_json(t))::text';

  /// An in-memory value from a `row_to_json` value.
  static Object? fromJson(RevColumn c, Object? v) {
    if (v == null) return null;
    return switch (c.type) {
      RevColumnType.dateTime => _parseTimestamp(v as String),
      RevColumnType.double => (v as num).toDouble(),
      RevColumnType.int => (v as num).toInt(),
      RevColumnType.uuid => (v as String).toLowerCase(),
      _ => v,
    };
  }

  static final _zone = RegExp(r'[+-]\d\d(:?\d\d)?$');

  static DateTime _parseTimestamp(String s) {
    final hasZone = s.endsWith('Z') || _zone.hasMatch(s);
    return DateTime.parse(hasZone ? s : '${s}Z').toUtc();
  }

  /// The in-memory row (with `id`) of a `row_to_json` object of [table];
  /// `fileId` and `revision` are left out.
  Map<String, Object?> rowFromJson(RevTable table, Map<String, Object?> j) => {
    RowChange.idColumn: (j['id']! as String).toLowerCase(),
    for (final c in table.columns) c.name: fromJson(c, j[c.name]),
  };

  /// DDL of [table] as the generated migrations create it, without foreign
  /// keys (tests of the platform module with a test schema).
  String createTableDdl(RevTable table) {
    final cols = [
      '"id" uuid PRIMARY KEY',
      '"fileId" bigint NOT NULL',
      '"revision" bigint NOT NULL DEFAULT 0',
      for (final c in table.columns)
        '${q(c.name)} ${pgType(c.type)}${c.nullable ? '' : ' NOT NULL'}',
    ];
    return [
      'CREATE TABLE ${q(table.name)} (${cols.join(', ')});',
      if (!perSheetTables.contains(table.name))
        'CREATE INDEX ${q('${table.name}_file_idx')} ON ${q(table.name)} '
            '("fileId", "id");',
      for (final (i, idx) in table.indexes.indexed)
        'CREATE INDEX ${q('${table.name}_rev_idx_$i')} ON ${q(table.name)} '
            '(${idx.map(q).join(', ')});',
    ].join('\n');
  }

  // --------------------------------------------------------------- reads

  /// Full rows of [ids] per table, by id alone (no file filter, so foreign
  /// ids are detected). Locks the rows with [forUpdate].
  ///
  /// One statement for every table (a round trip per table costs more than
  /// the rows of a small op), in runs of ≤ 10,000 ids per table. Each
  /// table's rows come back as one row of typed arrays (`array_agg` per
  /// column, null when every value is null): no JSON per row.
  Future<Map<(String, String), RevStoredRow>> fetchByIds(
    Session session,
    Map<String, Set<String>> ids, {
    Transaction? transaction,
    bool forUpdate = false,
  }) async {
    final out = <(String, String), RevStoredRow>{};
    final lists = {
      for (final MapEntry(key: name, value: set) in ids.entries)
        if (set.isNotEmpty) name: set.toList(),
    };
    const run = runSize * 10;
    for (var i = 0; lists.values.any((l) => l.length > i); i += run) {
      final parts = <String>[];
      final params = <String, Object?>{};
      final tables = <RevTable>[];
      for (final MapEntry(key: name, value: list) in lists.entries) {
        if (list.length <= i) continue;
        final p = 'ids${tables.length}';
        params[p] = list.sublist(i, (i + run).clamp(0, list.length));
        parts.add(
          '(SELECT ${columnArrays(schema.table(name), fileAndRevision: true)} '
          'FROM (SELECT * FROM ${q(name)} WHERE id = ANY(@$p::uuid[])'
          '${forUpdate ? ' FOR UPDATE' : ''}) t) c${tables.length}',
        );
        tables.add(schema.table(name));
      }
      final rows = await session.db.unsafeQuery(
        'SELECT * FROM ${parts.join(', ')}',
        parameters: QueryParameters.named(params),
        transaction: transaction,
      );
      final row = rows.first;
      var at = 0;
      for (final table in tables) {
        final width = 3 + table.columns.length;
        for (final s in storedRows(table, row.sublist(at, at + width))) {
          out[(table.name, s.row[RowChange.idColumn]! as String)] = s;
        }
        at += width;
      }
    }
    return out;
  }

  /// The aggregate select list of [table] over rows `t`: (`fileId`,
  /// `revision` with [fileAndRevision],) the ids, then one array per
  /// column, null when every value is null. Read with [storedRows].
  static String columnArrays(RevTable table, {bool fileAndRevision = false}) {
    // UUIDs as text: Postgres formats them faster than the driver.
    String agg(RevColumn c) {
      final column = q(c.name);
      final v = c.type == RevColumnType.uuid ? 't.$column::text' : 't.$column';
      return 'CASE WHEN count(t.$column) = 0 THEN NULL ELSE array_agg($v) END';
    }

    return [
      if (fileAndRevision) ...[
        'array_agg(t."fileId")',
        'array_agg(t."revision")',
      ],
      'array_agg(t.id::text)',
      for (final c in table.columns) agg(c),
    ].join(', ');
  }

  /// The rows of a [columnArrays] result (with `fileId` and `revision`):
  /// in-memory rows with every column (null when null), `fileId` and
  /// `revision` aside.
  static List<RevStoredRow> storedRows(RevTable table, List<Object?> r) {
    final ids = r[2] as List?;
    if (ids == null) return const [];
    final files = r[0]! as List;
    final revisions = r[1]! as List;
    final columns = [
      for (var k = 0; k < table.columns.length; k++) r[3 + k] as List?,
    ];
    return [
      for (var i = 0; i < ids.length; i++)
        RevStoredRow(files[i]! as int, (revisions[i] as int?) ?? 0, {
          RowChange.idColumn: ids[i]! as String,
          for (final (k, c) in table.columns.indexed)
            c.name: switch (columns[k]?[i]) {
              final DateTime d => d.toUtc(),
              final v => v,
            },
        }),
    ];
  }

  RevStoredRow _stored(RevTable table, String json) {
    final j = jsonDecode(json) as Map<String, Object?>;
    return RevStoredRow(
      (j['fileId']! as num).toInt(),
      (j['revision'] as num?)?.toInt() ?? 0,
      rowFromJson(table, j),
    );
  }

  /// Rows of child tables whose parent is in [deleted] (parent table → ids
  /// with their full rows), excluding [known] keys: the descendants a delete
  /// takes along that the op did not list (05 §3.2 step 6).
  ///
  /// Per-sheet tables (cells) are read through an index that starts with
  /// the parent column, or grouped by the deleted parent's own column
  /// (cells of deleted rows: `"sheetId" = @s AND "rowId" = ANY(@rows)`).
  Future<List<(String, RevStoredRow)>> children(
    Session session,
    int fileId,
    Map<String, Map<String, Map<String, Object?>>> deleted,
    Set<(String, String)> known, {
    Transaction? transaction,
  }) async {
    final out = <(String, RevStoredRow)>[];
    for (final child in schema.tables) {
      for (final p in child.parents) {
        final parents = deleted[p.table];
        if (parents == null || parents.isEmpty) continue;
        for (final (sql, params) in _childQueries(child, p, fileId, parents)) {
          final rows = await session.db.unsafeQuery(
            sql,
            parameters: QueryParameters.named(params),
            transaction: transaction,
          );
          for (final r in rows) {
            final s = _stored(child, r[0]! as String);
            final key = (child.name, s.row[RowChange.idColumn]! as String);
            if (s.fileId != fileId || !known.add(key)) continue;
            out.add((child.name, s));
          }
        }
      }
    }
    return out;
  }

  Iterable<(String, Map<String, Object?>)> _childQueries(
    RevTable child,
    RevParent p,
    int fileId,
    Map<String, Map<String, Object?>> parents,
  ) sync* {
    final select = 'SELECT ${RevSql.rowJson} FROM ${q(child.name)} t';
    final ids = parents.keys.toList();
    if (!perSheetTables.contains(child.name)) {
      yield (
        '$select WHERE t."fileId" = @f AND t.${q(p.column)} = ANY(@ids::uuid[])',
        {'f': fileId, 'ids': ids},
      );
      return;
    }
    if (child.indexes.any((i) => i.isNotEmpty && i.first == p.column)) {
      yield (
        '$select WHERE t.${q(p.column)} = ANY(@ids::uuid[])',
        {'ids': ids},
      );
      return;
    }
    // An index (q, p) where q is a parent column the deleted parent carries.
    for (final idx in child.indexes) {
      if (idx.length < 2 || idx[1] != p.column) continue;
      final by = <String, List<String>>{};
      for (final MapEntry(key: id, value: row) in parents.entries) {
        final scope = row[idx.first];
        if (scope is! String) continue;
        by.putIfAbsent(scope, () => []).add(id);
      }
      for (final MapEntry(key: scope, value: list) in by.entries) {
        // One probe of the (q, p) index per parent: with `p = ANY(…)`
        // Postgres may scan the whole scope through another index when its
        // statistics don't know the scope is big (as cell pages, 05 §7.2).
        yield (
          'SELECT ${RevSql.rowJson} FROM unnest(@ids::uuid[]) r(id), '
              'LATERAL (SELECT * FROM ${q(child.name)} c '
              'WHERE c.${q(idx.first)} = @s::uuid '
              'AND c.${q(p.column)} = r.id OFFSET 0) t',
          {'s': scope, 'ids': list},
        );
      }
      return;
    }
    throw StateError(
      'No index to cascade ${child.name}.${p.column}; add one to the schema.',
    );
  }

  /// Every row of the file: plain tables by `fileId` (keyset, [pageSize] rows
  /// per query), per-sheet tables by [scopes] (column → values, e.g.
  /// `sheetId` → the file's sheets). Used by headless loads (05 §9).
  Stream<(String, Map<String, Object?>)> allRows(
    Session session,
    int fileId, {
    required Future<Map<String, List<String>>> Function() scopes,
    Transaction? transaction,
    int pageSize = 10000,
  }) async* {
    for (final table in schema.tables) {
      if (perSheetTables.contains(table.name)) continue;
      yield* _keyset(
        session,
        table,
        'WHERE t."fileId" = @f',
        {'f': fileId},
        transaction,
        pageSize,
      );
    }
    if (perSheetTables.isEmpty) return;
    final byColumn = await scopes();
    for (final name in perSheetTables) {
      final table = schema.table(name);
      for (final MapEntry(key: column, value: values) in byColumn.entries) {
        // Keyset along an index (column, k): each page is an index range.
        // Ordering a scope by id alone sorts the whole scope per page.
        final k = table.indexes
            .where((i) => i.length >= 2 && i.first == column)
            .firstOrNull?[1];
        for (final v in values) {
          yield* k == null
              ? _keyset(
                  session,
                  table,
                  'WHERE t.${q(column)} = @s::uuid',
                  {'s': v},
                  transaction,
                  pageSize,
                )
              : _scopeKeyset(
                  session,
                  table,
                  column,
                  v,
                  k,
                  transaction,
                  pageSize,
                );
        }
      }
    }
  }

  /// Rows of [table] with [column] = [value] in (k, id) order, along the
  /// index (column, k).
  Stream<(String, Map<String, Object?>)> _scopeKeyset(
    Session session,
    RevTable table,
    String column,
    String value,
    String k,
    Transaction? transaction,
    int pageSize,
  ) async* {
    final type = pgType(table.column(k)!.type);
    Object? afterK;
    String? afterId;
    while (true) {
      final rows = await session.db.unsafeQuery(
        'SELECT ${RevSql.rowJson} FROM ${q(table.name)} t '
        'WHERE t.${q(column)} = @s::uuid'
        '${afterId == null ? '' : ' AND t.${q(k)} >= @k::$type AND '
                  '(t.${q(k)} > @k::$type OR t.id > @after::uuid)'} '
        'ORDER BY t.${q(k)}, t.id LIMIT $pageSize',
        parameters: QueryParameters.named({
          's': value,
          if (afterId != null) ...{'k': afterK, 'after': afterId},
        }),
        transaction: transaction,
      );
      Map<String, Object?>? last;
      for (final r in rows) {
        final j = jsonDecode(r[0]! as String) as Map<String, Object?>;
        last = j;
        yield (table.name, rowFromJson(table, j));
      }
      if (rows.length < pageSize || last == null) return;
      afterK = last[k];
      afterId = last['id']! as String;
    }
  }

  Stream<(String, Map<String, Object?>)> _keyset(
    Session session,
    RevTable table,
    String where,
    Map<String, Object?> params,
    Transaction? transaction,
    int pageSize,
  ) async* {
    String? after;
    while (true) {
      final rows = await session.db.unsafeQuery(
        'SELECT ${RevSql.rowJson} FROM ${q(table.name)} t $where'
        '${after == null ? '' : ' AND t.id > @after::uuid'} '
        'ORDER BY t.id LIMIT $pageSize',
        parameters: QueryParameters.named({...params, 'after': ?after}),
        transaction: transaction,
      );
      for (final r in rows) {
        final row = rowFromJson(
          table,
          jsonDecode(r[0]! as String) as Map<String, Object?>,
        );
        yield (table.name, row);
      }
      if (rows.length < pageSize) return;
      after = rows.isEmpty
          ? null
          : (jsonDecode(rows.last[0]! as String) as Map)['id'] as String;
    }
  }

  // -------------------------------------------------------------- writes

  /// Deletes [ids] of [table] within the file. Returns the row count.
  Future<int> delete(
    Session session,
    int fileId,
    String table,
    List<String> ids, {
    Transaction? transaction,
  }) async {
    var n = 0;
    for (var i = 0; i < ids.length; i += runSize * 10) {
      n += await session.db.unsafeExecute(
        'DELETE FROM ${q(table)} WHERE "fileId" = @f AND id = ANY(@ids::uuid[])',
        parameters: QueryParameters.named({
          'f': fileId,
          'ids': ids.sublist(i, (i + runSize * 10).clamp(0, ids.length)),
        }),
        transaction: transaction,
      );
    }
    return n;
  }

  /// Rows per insert statement: the columns travel as binary arrays.
  static const writeRunSize = 5000;

  /// The array parameter type (`@p:<type>`) of a column of [type].
  static String arrayType(RevColumnType type) => switch (type) {
    RevColumnType.uuid => '_uuid',
    RevColumnType.string ||
    RevColumnType.json ||
    RevColumnType.enumName => '_text',
    RevColumnType.int => '_int8',
    RevColumnType.double => '_float8',
    RevColumnType.bool => '_bool',
    RevColumnType.dateTime => '_timestamp',
  };

  /// An in-memory value as its array element (null stays null).
  static Object? arrayValue(RevColumn c, Object? v) {
    if (v == null) return null;
    return switch (c.type) {
      RevColumnType.dateTime => switch (v) {
        DateTime() => v.toUtc(),
        num() => DateTime.fromMillisecondsSinceEpoch(v.toInt(), isUtc: true),
        _ => DateTime.parse(v.toString()).toUtc(),
      },
      RevColumnType.double => (v as num).toDouble(),
      RevColumnType.int => (v as num).toInt(),
      RevColumnType.bool => v as bool,
      RevColumnType.enumName => v is Enum ? v.name : v.toString(),
      RevColumnType.uuid ||
      RevColumnType.string ||
      RevColumnType.json => v.toString(),
    };
  }

  /// Upserts final row images of [table] (every column) at [revision].
  /// A row id of another file is never overwritten: the affected count is
  /// checked and a mismatch throws [RevForeignRowException].
  ///
  /// The rows travel as one binary array per column (`unnest`; UUIDs as
  /// text, which Postgres parses faster than the driver encodes them); a
  /// column that is null in every row of a run is a typed `NULL` instead.
  /// Rows the op read and locked ([existing]) are updated in place (no
  /// speculative insert, and content updates can be HOT), setting only the
  /// [changed] columns when given; the others are inserted ([fresh]: they
  /// did not exist, a plain insert; else an upsert). An update that misses
  /// rows (deleted by a database cascade earlier in the op) falls back to
  /// the upsert.
  Future<void> upsert(
    Session session,
    int fileId,
    int revision,
    String table,
    List<Map<String, Object?>> rows, {
    Transaction? transaction,
    bool fresh = false,
    bool existing = false,
    Set<String>? changed,
  }) async {
    if (rows.isEmpty) return;
    final t = schema.table(table);
    final cols = existing && changed != null
        ? [
            for (final c in t.columns)
              if (changed.contains(c.name)) c,
          ]
        : t.columns;
    final conflict = fresh || existing
        ? ''
        : ' ON CONFLICT (id) DO UPDATE SET "revision" = '
              'EXCLUDED."revision"${cols.isEmpty ? '' : ', '}'
              '${cols.map((c) => '${q(c.name)} = EXCLUDED.${q(c.name)}').join(', ')} '
              'WHERE t."fileId" = EXCLUDED."fileId"';
    for (var i = 0; i < rows.length; i += writeRunSize) {
      final chunk = rows.sublist(i, (i + writeRunSize).clamp(0, rows.length));
      final params = <String, Object?>{
        'f': fileId,
        'rev': revision,
        'ids': [for (final r in chunk) r[RowChange.idColumn]! as String],
      };
      final arrays = ['CAST(@ids:_text AS uuid[])'];
      final aliases = ['id'];
      final select = <String>[];
      for (final (k, c) in cols.indexed) {
        final values = List<Object?>.filled(chunk.length, null);
        var any = false;
        for (var j = 0; j < chunk.length; j++) {
          final v = arrayValue(c, chunk[j][c.name]);
          if (v != null) {
            values[j] = v;
            any = true;
          }
        }
        if (!any) {
          select.add('NULL::${pgType(c.type)}');
          continue;
        }
        params['c$k'] = values;
        arrays.add(
          c.type == RevColumnType.uuid
              ? 'CAST(@c$k:_text AS uuid[])'
              : '@c$k:${arrayType(c.type)}',
        );
        aliases.add('c$k');
        select.add('u.c$k');
      }
      final from = 'unnest(${arrays.join(', ')}) AS u(${aliases.join(', ')})';
      final n = await session.db.unsafeExecute(
        existing
            ? 'UPDATE ${q(table)} AS t SET "revision" = @rev'
                  '${[for (final (k, c) in cols.indexed) ', ${q(c.name)} = ${select[k]}'].join()} '
                  'FROM $from WHERE t.id = u.id AND t."fileId" = @f'
            : 'INSERT INTO ${q(table)} AS t (id, "fileId", "revision"'
                  '${cols.map((c) => ', ${q(c.name)}').join()}) '
                  'SELECT u.id, @f, @rev${select.map((s) => ', $s').join()} '
                  'FROM $from$conflict',
        parameters: QueryParameters.named(params),
        transaction: transaction,
      );
      if (n != chunk.length) {
        // A row read by the op is gone: a database cascade of a row the op
        // deleted first (Slides group members). Write the run again as an
        // upsert of every column, which also detects foreign ids.
        if (existing) {
          await upsert(
            session,
            fileId,
            revision,
            table,
            chunk,
            transaction: transaction,
          );
          continue;
        }
        throw RevForeignRowException(table);
      }
    }
  }
}

/// A stored row with its file and the revision that last wrote it.
final class RevStoredRow {
  /// Creates the record.
  const RevStoredRow(this.fileId, this.revision, this.row);

  /// `fileId`.
  final int fileId;

  /// `revision`.
  final int revision;

  /// The in-memory row (with `id`).
  final Map<String, Object?> row;
}

/// An upsert hit a row id of another file (05 §3.3).
final class RevForeignRowException implements Exception {
  /// Creates the exception.
  const RevForeignRowException(this.table);

  /// The table.
  final String table;

  @override
  String toString() => 'A row id of $table belongs to another file.';
}

/// The rows an op is applied to on the server: the prefetched rows of the
/// file plus what the op inserts (05 §3.2 step 5).
final class RevPrefetchStore implements RevRowStore {
  /// Creates the store over [rows] (table, id) → full row.
  RevPrefetchStore(
    this.schema,
    Map<(String, String), Map<String, Object?>> rows,
  ) : _rows = {
        for (final e in rows.entries) e.key: {...e.value},
      };

  /// The schema.
  final RevSchema schema;

  final Map<(String, String), Map<String, Object?>?> _rows;

  /// Keys whose final state the op decides (written or deleted).
  final Set<(String, String)> touched = {};

  @override
  Map<String, Object?>? row(String table, String id) => _rows[(table, id)];

  @override
  void put(String table, String id, Map<String, Object?> row) {
    _rows[(table, id)] = row;
    touched.add((table, id));
  }

  @override
  void remove(String table, String id) {
    _rows[(table, id)] = null;
    touched.add((table, id));
  }

  /// Adds a row read later (cascaded descendants).
  void add(String table, String id, Map<String, Object?> row) =>
      _rows.putIfAbsent((table, id), () => row);

  @override
  Iterable<String> childIds(
    String childTable,
    String column,
    String parentId,
  ) => [
    for (final MapEntry(key: k, value: r) in _rows.entries)
      if (k.$1 == childTable && r != null && r[column] == parentId) k.$2,
  ];
}
