import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../common/models.dart';
import 'rev_binding.dart';
import 'rev_sql.dart';

/// Bootstrap pages (RevLog spec 05 §7, 04 §3): each page is read in one
/// repeatable-read transaction, so it is one snapshot at `revision`.
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
    final sql = RevSql(binding.schema, perSheetTables: binding.perSheetTables);
    final rows = <(String, Map<String, Object?>)>[];
    final coverage = <String>[];
    String? next;
    for (var ti = cursor.t; ti < tables.length; ti++) {
      final name = tables[ti];
      if (excluded.contains(name)) continue;
      final after = ti == cursor.t ? cursor.after : null;
      final left = max - rows.length;
      final got = await _keyset(
        session,
        tx,
        sql,
        file.id!,
        name,
        after,
        left + 1,
      );
      final full = got.length <= left;
      final take = full ? got : got.sublist(0, left);
      rows.addAll([for (final r in take) (name, r)]);
      final last = take.isEmpty
          ? after
          : take.last[RowChange.idColumn]! as String;
      coverage.add('tbl:$name:${after ?? '-'}:${full ? '+' : last}');
      if (!full) {
        next = jsonEncode({'t': ti, 'after': last});
        break;
      }
    }
    return _page(
      binding,
      head,
      rows,
      coverage,
      next,
      request.cursor == null ? excluded.toList() : const [],
    );
  }

  static ({int t, String? after}) _cursor(String json) {
    final m = (jsonDecode(json) as Map).cast<String, Object?>();
    return (t: (m['t']! as num).toInt(), after: m['after'] as String?);
  }

  static Future<List<Map<String, Object?>>> _keyset(
    Session session,
    Transaction tx,
    RevSql sql,
    int fileId,
    String name,
    String? after,
    int limit,
  ) async {
    final table = sql.schema.table(name);
    final rows = await session.db.unsafeQuery(
      'SELECT ${RevSql.rowJson} FROM ${RevSql.q(name)} t '
      'WHERE t."fileId" = @f${after == null ? '' : ' AND t.id > @a::uuid'} '
      'ORDER BY t.id LIMIT $limit',
      parameters: QueryParameters.named({'f': fileId, 'a': ?after}),
      transaction: tx,
    );
    return [
      for (final r in rows)
        sql.rowFromJson(
          table,
          (jsonDecode(r[0]! as String) as Map).cast<String, Object?>(),
        ),
    ];
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
    final sql = RevSql(binding.schema, perSheetTables: binding.perSheetTables);
    final got = await _keyset(session, tx, sql, file.id!, name, after, max + 1);
    final full = got.length <= max;
    final take = full ? got : got.sublist(0, max);
    final last = take.isEmpty
        ? after
        : take.last[RowChange.idColumn]! as String;
    return _page(
      binding,
      head,
      [for (final r in take) (name, r)],
      ['tbl:$name:${after ?? '-'}:${full ? '+' : last}'],
      full ? null : jsonEncode({'t': 0, 'after': last}),
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
    // The sheet must belong to the file.
    final owner = await session.db.unsafeQuery(
      'SELECT 1 FROM ${RevSql.q(scope.table)} WHERE id = @s::uuid '
      'AND "fileId" = @f',
      parameters: QueryParameters.named({'s': sheetId.uuid, 'f': file.id}),
      transaction: tx,
    );
    if (owner.isEmpty) throw ArgumentError('unknown sheet');
    final head = await _head(session, tx, file.id!);
    final ids = [
      for (final r in rowIds.take(pageRows)) r.uuid,
    ];
    final sql = RevSql(binding.schema, perSheetTables: binding.perSheetTables);
    final rows = ids.isEmpty
        ? const <List<Object?>>[]
        : await session.db.unsafeQuery(
            'SELECT ${RevSql.rowJson} FROM ${RevSql.q(table.name)} t '
            'WHERE t.${RevSql.q(scope.column)} = @s::uuid '
            'AND t.${RevSql.q(row.column)} = ANY(@rows::uuid[])',
            parameters: QueryParameters.named({
              's': sheetId.uuid,
              'rows': ids,
            }),
            transaction: tx,
          );
    return _page(
      binding,
      head,
      [
        for (final r in rows)
          (
            table.name,
            sql.rowFromJson(
              table,
              (jsonDecode(r[0]! as String) as Map).cast<String, Object?>(),
            ),
          ),
      ],
      [for (final id in ids) 'row:${sheetId.uuid}:$id'],
      null,
      const [],
    );
  }

  static RevPage _page(
    RevBinding binding,
    int revision,
    List<(String, Map<String, Object?>)> rows,
    List<String> coverage,
    String? next,
    List<String> excluded,
  ) {
    final body = RevCodec.gzip(RevPageCodec.encode(binding.schema, rows));
    return RevPage(
      revision: revision,
      body: ByteData.sublistView(body),
      coverage: coverage,
      excludedTables: excluded,
      nextCursor: next,
    );
  }
}
