import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/schema.dart';

import '../common/models.dart';
import 'rev_binding.dart';
import 'rev_sql.dart';

/// Bootstrap pages (RevLog spec 05 §7, 04 §3): each page is read in one
/// repeatable-read transaction, so it is one snapshot at `revision`.
///
/// A table's rows are read column by column: one statement returns one
/// row of typed arrays (`array_agg` per column; ids and UUID columns as
/// 16-byte `uuid_send` values; a column without values as null), which go
/// straight into the columnar body of format version 2 ([RevPageBuilder])
/// without row maps. Clients that don't ask for a format get version 1
/// (gzip NDJSON).
abstract final class RevPages {
  /// Max rows of a structure/rows page (`structurePageRows`).
  static int structurePageRows = 20000;

  /// Max sheet rows of a cell page (`pageRows`).
  static int pageRows = 1000;

  /// Tables with more rows than this go to `rows` pages.
  static int excludeAbove = 50000;

  /// Max compressed body.
  static const maxBodyBytes = 4 << 20;

  /// Serves [request] for [file].
  static Future<RevPage> page(
    Session session,
    RevBinding binding,
    RevFile file,
    RevPageRequest request,
  ) => session.db.transaction(
    (tx) async => switch (request.kind) {
      RevPageKind.structure => _structure(session, tx, binding, file, request),
      RevPageKind.rows => _rows(session, tx, binding, file, request),
      RevPageKind.cells => _cells(session, tx, binding, file, request),
    },
    settings: TransactionSettings(
      isolationLevel: IsolationLevel.repeatableRead,
    ),
  );

  static Future<int> _head(Session s, Transaction tx, int fileId) async {
    final r = await s.db.unsafeQuery(
      'SELECT "headRevision" FROM rev_file WHERE id = @f',
      parameters: QueryParameters.named({'f': fileId}),
      transaction: tx,
    );
    return r.first[0]! as int;
  }

  /// Non-cell tables in rank order.
  static List<String> _plainTables(RevBinding b) => [
    for (final t in b.schema.tables)
      if (!b.perSheetTables.contains(t.name)) t.name,
  ]..sort((x, y) => b.schema.rank(x).compareTo(b.schema.rank(y)));

  /// The aggregate select list of [table] over the rows `t`: the ids, then
  /// one array per column (null when every value is null).
  static String _columns(RevTable table) {
    String agg(String column, String expr) =>
        'CASE WHEN count(t.$column) = 0 THEN NULL ELSE array_agg($expr) END';
    return [
      'array_agg(uuid_send(t.id)) FILTER (WHERE t.id IS NOT NULL)',
      for (final c in table.columns)
        agg(
          RevSql.q(c.name),
          c.type == RevColumnType.uuid
              ? 'uuid_send(t.${RevSql.q(c.name)})'
              : 't.${RevSql.q(c.name)}',
        ),
    ].join(', ');
  }

  /// Reads the result of a [_columns] select.
  static _Cols _read(RevTable table, List<Object?> r) => _Cols(
    table.name,
    [...?(r[0] as List?)?.cast<Object>()],
    {
      for (final (i, c) in table.columns.indexed)
        if (r[i + 1] case final List<Object?> values) c.name: values,
    },
  );

  static Future<RevPage> _structure(
    Session session,
    Transaction tx,
    RevBinding binding,
    RevFile file,
    RevPageRequest request,
  ) async {
    final head = await _head(session, tx, file.id!);
    final stats = RevStats.parse(file.stats);
    final tables = _plainTables(binding);
    final excluded = {
      for (final t in tables)
        if ((stats.tables[t] ?? 0) > excludeAbove) t,
    };
    final cursor = request.cursor == null
        ? (t: 0, after: null)
        : _cursor(request.cursor!);
    final max = request.maxRows.clamp(1, structurePageRows);
    final cols = <_Cols>[];
    var count = 0;
    final coverage = <String>[];
    String? next;
    for (var ti = cursor.t; ti < tables.length; ti++) {
      final name = tables[ti];
      if (excluded.contains(name)) continue;
      final after = ti == cursor.t ? cursor.after : null;
      final left = max - count;
      final (got, more, last) = await _keyset(
        session,
        tx,
        binding.schema.table(name),
        file.id!,
        after,
        left,
      );
      cols.add(got);
      count += got.ids.length;
      coverage.add('tbl:$name:${after ?? '-'}:${more ? last : '+'}');
      if (more) {
        next = jsonEncode({'t': ti, 'after': last});
        break;
      }
    }
    return _page(
      binding,
      request,
      head,
      cols,
      coverage,
      next,
      request.cursor == null ? excluded.toList() : const [],
    );
  }

  static ({int t, String? after}) _cursor(String json) {
    final m = (jsonDecode(json) as Map).cast<String, Object?>();
    return (t: (m['t']! as num).toInt(), after: m['after'] as String?);
  }

  /// The first [limit] rows of [table] after [after] (by id), whether
  /// more follow, and the last id read.
  static Future<(_Cols, bool, String?)> _keyset(
    Session session,
    Transaction tx,
    RevTable table,
    int fileId,
    String? after,
    int limit,
  ) async {
    final r = await session.db.unsafeQuery(
      'WITH s AS (SELECT * FROM ${RevSql.q(table.name)} '
      'WHERE "fileId" = @f${after == null ? '' : ' AND id > @a::uuid'} '
      'ORDER BY id LIMIT ${limit + 1}), '
      't AS (SELECT * FROM s ORDER BY id LIMIT $limit) '
      'SELECT (SELECT count(*) FROM s) > $limit, '
      '(SELECT id::text FROM t ORDER BY id DESC LIMIT 1), '
      '${_columns(table)} FROM t',
      parameters: QueryParameters.named({'f': fileId, 'a': ?after}),
      transaction: tx,
    );
    final row = r.first;
    return (
      _read(table, row.sublist(2)),
      row[0]! as bool,
      (row[1] as String?) ?? after,
    );
  }

  static Future<RevPage> _rows(
    Session session,
    Transaction tx,
    RevBinding binding,
    RevFile file,
    RevPageRequest request,
  ) async {
    final name = request.table;
    if (name == null ||
        binding.schema.tryTable(name) == null ||
        binding.perSheetTables.contains(name)) {
      throw ArgumentError('bad table');
    }
    final head = await _head(session, tx, file.id!);
    final after = request.cursor == null
        ? null
        : _cursor(request.cursor!).after;
    final max = request.maxRows.clamp(1, structurePageRows);
    final (got, more, last) = await _keyset(
      session,
      tx,
      binding.schema.table(name),
      file.id!,
      after,
      max,
    );
    return _page(
      binding,
      request,
      head,
      [got],
      ['tbl:$name:${after ?? '-'}:${more ? last : '+'}'],
      more ? jsonEncode({'t': 0, 'after': last}) : null,
      const [],
    );
  }

  static Future<RevPage> _cells(
    Session session,
    Transaction tx,
    RevBinding binding,
    RevFile file,
    RevPageRequest request,
  ) async {
    final sheetId = request.sheetId;
    final rowIds = request.rowIds ?? const [];
    if (binding.perSheetTables.isEmpty || sheetId == null) {
      throw ArgumentError('cells pages need a sheet');
    }
    final table = binding.schema.table(binding.perSheetTables.first);
    final scope = table.parents.first;
    final row = table.parents.firstWhere(
      (p) => p.table != scope.table,
      orElse: () => scope,
    );
    final ids = [
      for (final r in rowIds.take(pageRows)) r.uuid,
    ];
    // The sheet must belong to the file (and the head, in the snapshot).
    final owner = await session.db.unsafeQuery(
      'SELECT f."headRevision" FROM rev_file f '
      'JOIN ${RevSql.q(scope.table)} s ON s."fileId" = f.id '
      'WHERE f.id = @f AND s.id = @s::uuid',
      parameters: QueryParameters.named({'s': sheetId.uuid, 'f': file.id}),
      transaction: tx,
    );
    if (owner.isEmpty) throw ArgumentError('unknown sheet');
    // One index probe per sheet row, in request order: with `rowId =
    // ANY(…)` Postgres reads the whole sheet through the (sheetId,
    // columnId) index when its statistics don't know the sheet is big
    // (2.4 s instead of ~50 ms for a page of a 1M-cell sheet).
    final r = await session.db.unsafeQuery(
      'SELECT ${_columns(table)} FROM unnest(@rows::uuid[]) r(id), '
      'LATERAL (SELECT * FROM ${RevSql.q(table.name)} c '
      'WHERE c.${RevSql.q(scope.column)} = @s::uuid '
      'AND c.${RevSql.q(row.column)} = r.id OFFSET 0) t',
      parameters: QueryParameters.named({'s': sheetId.uuid, 'rows': ids}),
      transaction: tx,
    );
    return _page(
      binding,
      request,
      owner.first[0]! as int,
      [_read(table, r.first)],
      [for (final id in ids) 'row:${sheetId.uuid}:$id'],
      null,
      const [],
    );
  }

  static RevPage _page(
    RevBinding binding,
    RevPageRequest request,
    int revision,
    List<_Cols> tables,
    List<String> coverage,
    String? next,
    List<String> excluded,
  ) {
    final schema = binding.schema;
    final b = RevPageBuilder(schema);
    for (final t in tables) {
      if (t.ids.isEmpty) continue;
      b.addTable(t.table, t.ids, t.columns);
    }
    var bytes = b.build();
    if (RevPageCodec.negotiate(request.format) != RevPageCodec.version) {
      // A client from before format negotiation: gzip NDJSON.
      bytes = RevPageCodec.encodeLegacy(
        schema,
        RevPageCodec.decode(schema, bytes),
      );
    }
    return RevPage(
      revision: revision,
      body: ByteData.sublistView(bytes),
      coverage: coverage,
      excludedTables: excluded,
      nextCursor: next,
    );
  }
}

/// A table's rows as columns: [ids] (16-byte values) and the columns that
/// have values, aligned with them.
final class _Cols {
  _Cols(this.table, this.ids, this.columns);

  final String table;
  final List<Object> ids;
  final Map<String, List<Object?>> columns;
}
