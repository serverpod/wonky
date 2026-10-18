import 'dart:typed_data';

import 'package:sqlite_async/sqlite_async.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

import 'rev_row_codec.dart';

/// A row as the cache returns it: (table, full row incl. `id`).
typedef RevCachedRow = (String, Map<String, Object?>);

/// The domain rows of the local cache (RevLog spec 17 As built 1, 24).
///
/// - Rows of structure tables live in `rev_row` (one record per row, keyed
///   by an integer file id, the table's index in the schema and the row id).
/// - Rows of `cellsByRow` tables (Sheets cells) live in `rev_cells`, **one
///   record per sheet row**: every cell of that row in one blob. Viewport
///   and streaming reads touch one record per sheet row instead of one per
///   cell, and a bootstrap page writes 500 records instead of 13,000.
/// - `rev_cell_id` finds a cell's record from its id (updates and deletes
///   of the applied form carry no sheet/row key): a 52-bit hash of the id
///   to the record's rowid, verified against the decoded ids.
///
/// Row data is the compact binary encoding of [RevRowWriter].
final class RevDomainRows {
  /// The rows of [schema].
  RevDomainRows(this.schema)
    : _tblIndex = {
        for (var i = 0; i < schema.tables.length; i++) schema.tables[i].name: i,
      },
      _cells = [
        for (final t in schema.tables)
          t.coverage == RevCoverage.cellsByRow && t.parents.length >= 2
              ? (t.parents[0].column, t.parents[1].column)
              : null,
      ];

  /// The schema (table indexes; a new schema resets the cache).
  final RevSchema schema;
  final Map<String, int> _tblIndex;

  /// Per table index: (scope column, row-key column) of a cell table.
  final List<(String, String)?> _cells;

  final Map<String, int> _fids = {};

  /// Id entries not written yet, per file: record rowid → its cell ids. A
  /// bootstrap writes its records without them and [indexPending] adds
  /// them, sorted, once the file is complete: random-key inserts into the
  /// id index dirty most of its pages on every page (a 1M-cell download
  /// rewrote the index into the WAL 77 times). Until then nothing looks
  /// cells up by id: domain writes wait for the end of the bootstrap, and
  /// a page's replayed changes find their cells in the page.
  final Map<int, Map<int, List<int>>> _unindexed = {};

  /// The DDL of the tables (cache migration 2).
  static Future<void> createTables(SqliteWriteContext tx) async {
    await tx.execute(
      'CREATE TABLE rev_fid (fid INTEGER PRIMARY KEY, '
      'file_uuid TEXT NOT NULL UNIQUE)',
    );
    await tx.execute('''
      CREATE TABLE rev_row (
        fid INTEGER NOT NULL,
        tbl INTEGER NOT NULL,
        id TEXT NOT NULL,
        data BLOB NOT NULL,
        PRIMARY KEY (fid, tbl, id)
      ) WITHOUT ROWID''');
    await tx.execute('''
      CREATE TABLE rev_cells (
        rid INTEGER PRIMARY KEY,
        fid INTEGER NOT NULL,
        tbl INTEGER NOT NULL,
        scope TEXT NOT NULL,
        row_key TEXT NOT NULL,
        data BLOB NOT NULL
      )''');
    await tx.execute(
      'CREATE UNIQUE INDEX rev_cells_key ON rev_cells '
      '(fid, scope, row_key, tbl)',
    );
    await tx.execute('''
      CREATE TABLE rev_cell_id (
        fid INTEGER NOT NULL,
        h INTEGER NOT NULL,
        rid INTEGER NOT NULL,
        PRIMARY KEY (fid, h, rid)
      ) WITHOUT ROWID''');
  }

  /// Whether [table] is a cell table (grouped per sheet row).
  bool isCellTable(String table) {
    final i = _tblIndex[table];
    return i != null && _cells[i] != null;
  }

  // ----------------------------------------------------------------- files

  /// The integer id of [fileUuid], or null when it has no rows yet.
  Future<int?> fidOf(SqliteReadContext ctx, String fileUuid) async {
    final known = _fids[fileUuid];
    if (known != null) return known;
    final r = await ctx.getOptional(
      'SELECT fid FROM rev_fid WHERE file_uuid = ?',
      [fileUuid],
    );
    final fid = r?['fid'] as int?;
    if (fid != null) _fids[fileUuid] = fid;
    return fid;
  }

  /// The integer id of [fileUuid] (created when new).
  Future<int> fidFor(SqliteWriteContext tx, String fileUuid) async {
    final known = await fidOf(tx, fileUuid);
    if (known != null) return known;
    await tx.execute('INSERT OR IGNORE INTO rev_fid (file_uuid) VALUES (?)', [
      fileUuid,
    ]);
    return (await fidOf(tx, fileUuid))!;
  }

  /// Removes every row of [fileUuid].
  Future<void> deleteFile(SqliteWriteContext tx, String fileUuid) async {
    final fid = await fidOf(tx, fileUuid);
    if (fid == null) return;
    _unindexed.remove(fid);
    for (final t in const ['rev_row', 'rev_cells', 'rev_cell_id']) {
      await tx.execute('DELETE FROM $t WHERE fid = ?', [fid]);
    }
  }

  /// Removes every row of every file.
  Future<void> deleteAll(SqliteWriteContext tx) async {
    _unindexed.clear();
    for (final t in const ['rev_row', 'rev_cells', 'rev_cell_id']) {
      await tx.execute('DELETE FROM $t');
    }
  }

  /// Writes the id entries a bootstrap of [fileUuid] left out (the file is
  /// complete now).
  Future<void> indexPending(SqliteWriteContext tx, String fileUuid) async {
    final fid = await fidOf(tx, fileUuid);
    final pending = fid == null ? null : _unindexed.remove(fid);
    if (pending != null) await insertIds(tx, fid!, pending);
  }

  /// Bytes of row data (Settings).
  static Future<int> bytes(SqliteReadContext ctx) async {
    final r = await ctx.getOptional(
      'SELECT (SELECT coalesce(sum(length(data)), 0) FROM rev_row) + '
      '(SELECT coalesce(sum(length(data)), 0) FROM rev_cells) AS n',
    );
    return (r?['n'] as int?) ?? 0;
  }

  // ------------------------------------------------------------- encoding

  /// The record key of a cell id: 52 bits of the id (the random tail of a
  /// UUID), exact on the web too.
  static int idHash(String id) {
    if (id.length == 36 && id.codeUnitAt(23) == 0x2d) {
      var h = 0;
      for (var i = 22; i < 36; i++) {
        if (i == 23) continue;
        final n = _nibble(id.codeUnitAt(i));
        if (n < 0) return _fallbackHash(id);
        h = h * 16 + n;
      }
      return h;
    }
    return _fallbackHash(id);
  }

  static int _fallbackHash(String id) {
    var h = 7;
    for (var i = 0; i < id.length; i++) {
      h = (h * 31 + id.codeUnitAt(i)) % 35184372088831;
    }
    return h;
  }

  static int _nibble(int c) {
    if (c >= 0x30 && c <= 0x39) return c - 0x30;
    if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
    if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
    return -1;
  }

  final RevRowWriter _w = RevRowWriter();

  Uint8List _encodeRow(RevTable table, Map<String, Object?> row) {
    _w.clear();
    _w.row(table, row);
    return _w.takeBytes();
  }

  Map<String, Object?> _decodeRow(RevTable table, String id, Uint8List data) {
    final row = <String, Object?>{RowChange.idColumn: id};
    RevRowReader(data).row(table, row);
    return row;
  }

  Uint8List _encodeGroup(int tbl, Iterable<Map<String, Object?>> cells) {
    final table = schema.tables[tbl];
    final (scopeCol, keyCol) = _cells[tbl]!;
    _w
      ..clear()
      ..varint(cells.length);
    for (final c in cells) {
      _w
        ..value(c[RowChange.idColumn]!)
        ..row(table, c, skip1: scopeCol, skip2: keyCol);
    }
    return _w.takeBytes();
  }

  /// The cells of a group record, by id.
  Map<String, Map<String, Object?>> _decodeGroup(
    int tbl,
    String scope,
    String key,
    Uint8List data,
  ) {
    final table = schema.tables[tbl];
    final (scopeCol, keyCol) = _cells[tbl]!;
    final r = RevRowReader(data);
    final out = <String, Map<String, Object?>>{};
    for (var n = r.varint(); n > 0; n--) {
      final id = r.value()! as String;
      final row = <String, Object?>{
        RowChange.idColumn: id,
        scopeCol: scope,
        keyCol: key,
      };
      r.row(table, row);
      out[id] = row;
    }
    return out;
  }

  // ---------------------------------------------------------------- reads

  /// Every structure row (not cells) of [fid], parents' tables first.
  Future<List<RevCachedRow>> structure(SqliteReadContext ctx, int fid) async {
    final out = <RevCachedRow>[];
    int? afterTbl;
    String? afterId;
    while (true) {
      final rows = await ctx.getAll(
        'SELECT tbl, id, data FROM rev_row WHERE fid = ?'
        '${afterTbl == null ? '' : ' AND (tbl, id) > (?, ?)'} '
        'ORDER BY tbl, id LIMIT 20000',
        [fid, ?afterTbl, ?afterId],
      );
      for (final r in rows) {
        final tbl = r['tbl'] as int;
        final id = r['id'] as String;
        final table = schema.tables[tbl];
        out.add((table.name, _decodeRow(table, id, r['data'] as Uint8List)));
      }
      if (rows.length < 20000) return out;
      afterTbl = rows.last['tbl'] as int;
      afterId = rows.last['id'] as String;
    }
  }

  /// The cells of [rowKeys] of [scope].
  Future<List<RevCachedRow>> scoped(
    SqliteReadContext ctx,
    int fid,
    String scope,
    List<String> rowKeys,
  ) async {
    final out = <RevCachedRow>[];
    for (var i = 0; i < rowKeys.length; i += 500) {
      final chunk = rowKeys.sublist(i, (i + 500).clamp(0, rowKeys.length));
      final rows = await ctx.getAll(
        'SELECT tbl, row_key, data FROM rev_cells WHERE fid = ? AND scope = ? '
        'AND row_key IN (${_marks(chunk.length)})',
        [fid, scope, ...chunk],
      );
      for (final r in rows) {
        final tbl = r['tbl'] as int;
        final name = schema.tables[tbl].name;
        for (final row in _decodeGroup(
          tbl,
          scope,
          r['row_key'] as String,
          r['data'] as Uint8List,
        ).values) {
          out.add((name, row));
        }
      }
    }
    return out;
  }

  /// Every cell of [fid] (keyset pages along the record key index).
  Future<List<RevCachedRow>> allCells(SqliteReadContext ctx, int fid) async {
    final out = <RevCachedRow>[];
    (String, String, int)? after;
    while (true) {
      final rows = await ctx.getAll(
        'SELECT tbl, scope, row_key, data FROM rev_cells WHERE fid = ?'
        '${after == null ? '' : ' AND (scope, row_key, tbl) > (?, ?, ?)'} '
        'ORDER BY scope, row_key, tbl LIMIT 2000',
        [
          fid,
          if (after != null) ...[after.$1, after.$2, after.$3],
        ],
      );
      for (final r in rows) {
        final tbl = r['tbl'] as int;
        final name = schema.tables[tbl].name;
        for (final row in _decodeGroup(
          tbl,
          r['scope'] as String,
          r['row_key'] as String,
          r['data'] as Uint8List,
        ).values) {
          out.add((name, row));
        }
      }
      if (rows.length < 2000) return out;
      final last = rows.last;
      after = (
        last['scope'] as String,
        last['row_key'] as String,
        last['tbl'] as int,
      );
    }
  }

  /// The row ([table], [id]) of [fid], or null.
  Future<Map<String, Object?>?> row(
    SqliteReadContext ctx,
    int fid,
    String table,
    String id,
  ) async {
    final tbl = _tblIndex[table];
    if (tbl == null) return null;
    if (_cells[tbl] == null) {
      final r = await ctx.getOptional(
        'SELECT data FROM rev_row WHERE fid = ? AND tbl = ? AND id = ?',
        [fid, tbl, id],
      );
      return r == null
          ? null
          : _decodeRow(schema.tables[tbl], id, r['data'] as Uint8List);
    }
    for (final r in await ctx.getAll(
      'SELECT c.tbl, c.scope, c.row_key, c.data FROM rev_cell_id k '
      'JOIN rev_cells c ON c.rid = k.rid WHERE k.fid = ? AND k.h = ?',
      [fid, idHash(id)],
    )) {
      if (r['tbl'] != tbl) continue;
      final cells = _decodeGroup(
        tbl,
        r['scope'] as String,
        r['row_key'] as String,
        r['data'] as Uint8List,
      );
      if (cells[id] case final row?) return row;
    }
    return null;
  }

  static String _marks(int n) => List.filled(n, '?').join(', ');

  // --------------------------------------------------------------- writes

  /// Applies [applied] (an op's applied form, or replayed buffered changes)
  /// to the rows of [fid], in order.
  Future<void> replay(
    SqliteWriteContext tx,
    int fid,
    List<RowChange> applied,
  ) async {
    if (applied.isEmpty) return;
    final work = _Work(this, tx, fid);
    await work.load(applied);
    applied.forEach(work.apply);
    await work.flush();
  }

  /// Writes the rows of a bootstrap page: [stale] are the page's coverage
  /// keys it replaces (`tbl:<table>:<from>:<to>`, `row:<scope>:<key>`);
  /// rows under one of the page's other coverage keys are older than what
  /// is stored and skipped. Then [replay] (buffered changes newer than the
  /// page) is applied. The page's cell records get their id entries when
  /// the file is complete ([indexPending]).
  Future<void> writePage(
    SqliteWriteContext tx,
    int fid, {
    required List<String> coverage,
    required Set<String> stale,
    required List<RevCachedRow> rows,
    List<RowChange> replay = const [],
    int? maxRid,
  }) async {
    // Structure ranges of the page: (table index, from, to, stale).
    final ranges = <(int, String, String, bool)>[];
    final cellKeys = <String, Map<String, bool>>{};
    final staleRows = <String, List<String>>{};
    for (final key in coverage) {
      final parts = key.split(':');
      if (parts.first == 'tbl' && parts.length == 4) {
        final tbl = _tblIndex[parts[1]];
        if (tbl == null) continue;
        final isStale = stale.contains(key);
        ranges.add((tbl, parts[2], parts[3], isStale));
        if (isStale) {
          final from = parts[2], to = parts[3];
          await tx.execute(
            'DELETE FROM rev_row WHERE fid = ? AND tbl = ?'
            '${from == '-' ? '' : ' AND id > ?'}'
            '${to == '+' ? '' : ' AND id <= ?'}',
            [fid, tbl, if (from != '-') from, if (to != '+') to],
          );
        }
      } else if (parts.first == 'row' && parts.length == 3) {
        final isStale = stale.contains(key);
        (cellKeys[parts[1]] ??= {})[parts[2]] = isStale;
        if (isStale) (staleRows[parts[1]] ??= []).add(parts[2]);
      }
    }
    // Replaced sheet rows: their old records and id entries go.
    for (final MapEntry(key: scope, value: keys) in staleRows.entries) {
      await _dropGroups(tx, fid, scope, keys);
    }

    final structure = <List<Object?>>[];
    final groups = <(int, String, String), List<Map<String, Object?>>>{};
    final merge = <RowChange>[];
    for (final (table, row) in rows) {
      final tbl = _tblIndex[table];
      if (tbl == null) continue;
      final id = row[RowChange.idColumn]! as String;
      final cell = _cells[tbl];
      if (cell == null) {
        var write = true;
        for (final (t, from, to, isStale) in ranges) {
          if (t == tbl &&
              (from == '-' || id.compareTo(from) > 0) &&
              (to == '+' || id.compareTo(to) <= 0)) {
            write = isStale;
            break;
          }
        }
        if (write) {
          structure.add([fid, tbl, id, _encodeRow(schema.tables[tbl], row)]);
        }
        continue;
      }
      final scope = row[cell.$1] as String?;
      final key = row[cell.$2] as String?;
      if (scope == null || key == null) continue;
      switch (cellKeys[scope]?[key]) {
        case true:
          (groups[(tbl, scope, key)] ??= []).add(row);
        case false:
          break; // covered at a newer revision already
        case null:
          // Not covered by this page: merged like an insert.
          merge.add(RowChange.loaded(table, row));
      }
    }
    if (structure.isNotEmpty) {
      await tx.executeBatch(
        'INSERT OR REPLACE INTO rev_row (fid, tbl, id, data) '
        'VALUES (?, ?, ?, ?)',
        structure,
      );
    }
    final written = <_Group>[];
    if (groups.isNotEmpty) {
      var rid = maxRid ?? await _maxRid(tx);
      final records = <List<Object?>>[];
      final pending = _unindexed[fid] ??= {};
      for (final MapEntry(key: (tbl, scope, key), value: cells)
          in groups.entries) {
        rid++;
        records.add([rid, fid, tbl, scope, key, _encodeGroup(tbl, cells)]);
        final byId = {
          for (final c in cells) c[RowChange.idColumn]! as String: c,
        };
        pending[rid] = [for (final id in byId.keys) idHash(id)];
        written.add(_Group(tbl, scope, key, rid, byId));
      }
      await tx.executeBatch(
        'INSERT INTO rev_cells (rid, fid, tbl, scope, row_key, data) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        records,
      );
    }
    final changes = [...merge, ...replay];
    if (changes.isEmpty) return;
    // The page's records are known here (no lookups by id for them).
    final work = _Work(this, tx, fid);
    written.forEach(work._addGroup);
    await work.load(changes);
    changes.forEach(work.apply);
    await work.flush();
  }

  /// Adds the `rev_cell_id` entries of [ids] (record rowid → cell ids) in
  /// one statement: the entries go to SQLite as one JSON text unpacked by
  /// `json_each` (a statement per entry costs a bind/step/reset round of
  /// FFI calls each: 13,000 per page), sorted by hash so the B-tree is
  /// filled in order.
  static Future<void> insertIds(
    SqliteWriteContext tx,
    int fid,
    Map<int, List<int>> ids,
  ) async {
    if (ids.isEmpty) return;
    final json = StringBuffer('[');
    var first = true;
    for (final MapEntry(key: rid, value: list) in ids.entries) {
      if (list.isEmpty) continue;
      if (!first) json.write(',');
      first = false;
      json
        ..write('[')
        ..write(rid)
        ..write(',[');
      var firstId = true;
      for (final h in list) {
        if (!firstId) json.write(',');
        firstId = false;
        json.write(h);
      }
      json.write(']]');
    }
    json.write(']');
    await tx.execute(
      'INSERT OR IGNORE INTO rev_cell_id (fid, h, rid) '
      'SELECT ?, h.value, json_extract(g.value, \'\$[0]\') '
      'FROM json_each(?) AS g, json_each(g.value, \'\$[1]\') AS h '
      'ORDER BY 2',
      [fid, json.toString()],
    );
  }

  /// Whether the database runs closures on its worker isolate (native;
  /// the web's workers don't, 06 §2.1).
  bool _fastPages = true;

  /// Writes the rows of pages with disjoint coverage in **one** round trip
  /// to the database worker when they are plain new cells (the bulk of a
  /// download): every row a cell under one of the pages' `row:` keys, none
  /// of those keys covered or stored yet. A page write of several
  /// statements waits for the UI isolate between them and falls behind a
  /// download. Returns false (nothing written) for anything else.
  Future<bool> writeNewCells(
    SqliteWriteContext tx,
    String fileUuid,
    int fid,
    Map<String, int> revisionOf,
    List<RevCachedRow> rows,
  ) async {
    if (!_fastPages || rows.isEmpty) return false;
    final keys = <String, Set<String>>{};
    for (final key in revisionOf.keys) {
      final parts = key.split(':');
      if (parts.length != 3 || parts.first != 'row') return false;
      (keys[parts[1]] ??= {}).add(parts[2]);
    }
    final groups = <(int, String, String), List<Map<String, Object?>>>{};
    for (final (table, row) in rows) {
      final tbl = _tblIndex[table];
      final cell = tbl == null ? null : _cells[tbl];
      if (cell == null) return false;
      final scope = row[cell.$1];
      final key = row[cell.$2];
      if (scope is! String || key is! String) return false;
      if (!(keys[scope]?.contains(key) ?? false)) return false;
      (groups[(tbl!, scope, key)] ??= []).add(row);
    }
    final records = <List<Object?>>[];
    final hashes = <List<int>>[];
    for (final MapEntry(key: (tbl, scope, key), value: cells)
        in groups.entries) {
      records.add([tbl, scope, key, _encodeGroup(tbl, cells)]);
      hashes.add([
        for (final c in {for (final c in cells) c[RowChange.idColumn]})
          idHash(c! as String),
      ]);
    }
    final int? first;
    try {
      first = await _newCells(tx, fid, fileUuid, records, revisionOf, {
        for (final e in keys.entries) e.key: e.value.toList(),
      });
    } on UnimplementedError {
      _fastPages = false;
      return false;
    }
    if (first == null) return false;
    final pending = _unindexed[fid] ??= {};
    for (var i = 0; i < hashes.length; i++) {
      pending[first + i] = hashes[i];
    }
    return true;
  }

  /// The worker side of [writeNewCells] (static: the closure captures only
  /// its arguments). Returns the first record rowid, or null when a key is
  /// covered or stored already.
  static Future<int?> _newCells(
    SqliteWriteContext tx,
    int fid,
    String fileUuid,
    List<List<Object?>> records,
    Map<String, int> revisionOf,
    Map<String, List<String>> keys,
  ) => tx.computeWithDatabase((db) async {
    String marks(int n) => List.filled(n, '?').join(', ');
    final coverage = revisionOf.keys.toList();
    for (var i = 0; i < coverage.length; i += 2000) {
      final chunk = coverage.sublist(i, (i + 2000).clamp(0, coverage.length));
      final r = db.select(
        'SELECT count(*) AS n FROM rev_coverage WHERE file_uuid = ? AND '
        'key IN (${marks(chunk.length)})',
        [fileUuid, ...chunk],
      );
      if (r.first['n'] != 0) return null;
    }
    for (final MapEntry(key: scope, value: rowKeys) in keys.entries) {
      for (var i = 0; i < rowKeys.length; i += 2000) {
        final chunk = rowKeys.sublist(i, (i + 2000).clamp(0, rowKeys.length));
        final r = db.select(
          'SELECT count(*) AS n FROM rev_cells WHERE fid = ? AND scope = ? '
          'AND row_key IN (${marks(chunk.length)})',
          [fid, scope, ...chunk],
        );
        if (r.first['n'] != 0) return null;
      }
    }
    final max =
        db.select('SELECT coalesce(max(rid), 0) AS m FROM rev_cells').first['m']
            as int;
    final insert = db.prepare(
      'INSERT INTO rev_cells (rid, fid, tbl, scope, row_key, data) '
      'VALUES (?, ?, ?, ?, ?, ?)',
    );
    try {
      var rid = max;
      for (final r in records) {
        insert.execute([++rid, fid, ...r]);
      }
    } finally {
      insert.close();
    }
    final cover = db.prepare(
      'INSERT OR REPLACE INTO rev_coverage (file_uuid, key, revision) '
      'VALUES (?, ?, ?)',
    );
    try {
      for (final MapEntry(key: key, value: revision) in revisionOf.entries) {
        cover.execute([fileUuid, key, revision]);
      }
    } finally {
      cover.close();
    }
    return max + 1;
  });

  Future<int> _maxRid(SqliteWriteContext tx) async {
    final r = await tx.getOptional(
      'SELECT coalesce(max(rid), 0) AS m FROM rev_cells',
    );
    return (r?['m'] as int?) ?? 0;
  }

  /// Deletes the records of [keys] of [scope] with their id entries.
  Future<void> _dropGroups(
    SqliteWriteContext tx,
    int fid,
    String scope,
    List<String> keys,
  ) async {
    for (var i = 0; i < keys.length; i += 2000) {
      final chunk = keys.sublist(i, (i + 2000).clamp(0, keys.length));
      final old = await tx.getAll(
        'SELECT rid, tbl, row_key, data FROM rev_cells WHERE fid = ? AND '
        'scope = ? AND row_key IN (${_marks(chunk.length)})',
        [fid, scope, ...chunk],
      );
      if (old.isEmpty) continue;
      final ids = <List<Object?>>[];
      for (final r in old) {
        final rid = r['rid'] as int;
        _unindexed[fid]?.remove(rid);

        for (final id in _decodeGroup(
          r['tbl'] as int,
          scope,
          r['row_key'] as String,
          r['data'] as Uint8List,
        ).keys) {
          ids.add([fid, idHash(id), rid]);
        }
      }
      await tx.executeBatch(
        'DELETE FROM rev_cell_id WHERE fid = ? AND h = ? AND rid = ?',
        ids,
      );
      await tx.executeBatch('DELETE FROM rev_cells WHERE rid = ?', [
        for (final r in old) [r['rid']],
      ]);
    }
  }
}

/// The cells of one sheet row of one cell table (a `rev_cells` record).
final class _Group {
  _Group(this.tbl, this.scope, this.key, this.rid, this.cells)
    : stored = {...cells.keys};

  final int tbl;
  final String scope;
  final String key;

  /// The record's rowid (null: not stored yet).
  int? rid;

  /// id → full row.
  final Map<String, Map<String, Object?>> cells;

  /// Ids with a `rev_cell_id` entry for [rid].
  final Set<String> stored;
  bool dirty = false;
}

/// One batch of row changes against the stored rows: reads what the
/// changes need in a few queries, applies them in memory, writes back.
final class _Work {
  _Work(this.rows, this.tx, this.fid);

  final RevDomainRows rows;
  final SqliteWriteContext tx;
  final int fid;

  /// (table index, id) → structure row (null: absent / deleted).
  final Map<(int, String), Map<String, Object?>?> _structure = {};
  final Set<(int, String)> _structureTouched = {};

  final Map<(int, String, String), _Group> _byKey = {};
  final Map<(int, String), _Group> _byId = {};
  final Set<_Group> _dirty = Set.identity();

  RevSchema get _schema => rows.schema;

  void _addGroup(_Group g) {
    _byKey[(g.tbl, g.scope, g.key)] = g;
    for (final id in g.cells.keys) {
      _byId[(g.tbl, id)] = g;
    }
  }

  Future<void> load(List<RowChange> changes) async {
    final updated = <int, Set<String>>{};
    final insertedStructure = <(int, String)>{};
    final keysByScope = <String, Set<String>>{};
    final lookups = <int, Set<String>>{};
    final seenCells = <(int, String)>{};
    for (final c in changes) {
      final tbl = rows._tblIndex[c.table];
      if (tbl == null) continue;
      final cell = rows._cells[tbl];
      final k = (tbl, c.rowId);
      if (cell == null) {
        if (c.op == RowOp.insert) {
          insertedStructure.add(k);
        } else if (c.op == RowOp.update && !insertedStructure.contains(k)) {
          (updated[tbl] ??= {}).add(c.rowId);
        }
        continue;
      }
      if (c.op == RowOp.insert) {
        final scope = c.columnsAfter[cell.$1];
        final key = c.columnsAfter[cell.$2];
        if (scope is String && key is String) {
          (keysByScope[scope] ??= {}).add(key);
        }
        seenCells.add(k);
      } else if (seenCells.add(k)) {
        (lookups[tbl] ??= {}).add(c.rowId);
      }
    }
    for (final MapEntry(key: tbl, value: ids) in updated.entries) {
      final list = ids.toList();
      final table = _schema.tables[tbl];
      for (var i = 0; i < list.length; i += 500) {
        final chunk = list.sublist(i, (i + 500).clamp(0, list.length));
        for (final r in await tx.getAll(
          'SELECT id, data FROM rev_row WHERE fid = ? AND tbl = ? '
          'AND id IN (${RevDomainRows._marks(chunk.length)})',
          [fid, tbl, ...chunk],
        )) {
          final id = r['id'] as String;
          _structure[(tbl, id)] = rows._decodeRow(
            table,
            id,
            r['data'] as Uint8List,
          );
        }
      }
    }
    for (final MapEntry(key: scope, value: keys) in keysByScope.entries) {
      final list = keys.toList();
      for (var i = 0; i < list.length; i += 500) {
        final chunk = list.sublist(i, (i + 500).clamp(0, list.length));
        _read(
          await tx.getAll(
            'SELECT rid, tbl, scope, row_key, data FROM rev_cells WHERE '
            'fid = ? AND scope = ? AND row_key IN '
            '(${RevDomainRows._marks(chunk.length)})',
            [fid, scope, ...chunk],
          ),
        );
      }
    }
    for (final MapEntry(key: tbl, value: ids) in lookups.entries) {
      final hashes = {
        for (final id in ids)
          if (!_byId.containsKey((tbl, id))) RevDomainRows.idHash(id),
      }.toList();
      for (var i = 0; i < hashes.length; i += 500) {
        final chunk = hashes.sublist(i, (i + 500).clamp(0, hashes.length));
        _read(
          await tx.getAll(
            'SELECT DISTINCT c.rid, c.tbl, c.scope, c.row_key, c.data '
            'FROM rev_cell_id k JOIN rev_cells c ON c.rid = k.rid '
            'WHERE k.fid = ? AND k.h IN '
            '(${RevDomainRows._marks(chunk.length)})',
            [fid, ...chunk],
          ),
        );
      }
    }
  }

  void _read(List<Map<String, Object?>> records) {
    for (final r in records) {
      final tbl = r['tbl']! as int;
      final scope = r['scope']! as String;
      final key = r['row_key']! as String;
      if (_byKey.containsKey((tbl, scope, key))) continue;
      _addGroup(
        _Group(
          tbl,
          scope,
          key,
          r['rid']! as int,
          rows._decodeGroup(tbl, scope, key, r['data']! as Uint8List),
        ),
      );
    }
  }

  void apply(RowChange c) {
    final tbl = rows._tblIndex[c.table];
    if (tbl == null) return;
    final cell = rows._cells[tbl];
    final k = (tbl, c.rowId);
    if (cell == null) {
      switch (c.op) {
        case RowOp.insert:
          _structure[k] = {...c.columnsAfter, RowChange.idColumn: c.rowId};
        case RowOp.update:
          final cur = _structure[k];
          if (cur == null) return;
          _structure[k] = {...cur, ...c.columnsAfter};
        case RowOp.delete:
          _structure[k] = null;
      }
      _structureTouched.add(k);
      return;
    }
    switch (c.op) {
      case RowOp.insert:
        final scope = c.columnsAfter[cell.$1];
        final key = c.columnsAfter[cell.$2];
        if (scope is! String || key is! String) return;
        final old = _byId[k];
        final g = _byKey[(tbl, scope, key)] ??= _Group(
          tbl,
          scope,
          key,
          null,
          {},
        );
        if (old != null && !identical(old, g)) {
          old.cells.remove(c.rowId);
          _dirty.add(old);
        }
        g.cells[c.rowId] = {...c.columnsAfter, RowChange.idColumn: c.rowId};
        _byId[k] = g;
        _dirty.add(g);
      case RowOp.update:
        final g = _byId[k];
        final cur = g?.cells[c.rowId];
        if (g == null || cur == null) return;
        g.cells[c.rowId] = {
          ...cur,
          ...c.columnsAfter,
          // Key columns are immutable (03 §4.3).
          cell.$1: cur[cell.$1],
          cell.$2: cur[cell.$2],
        };
        _dirty.add(g);
      case RowOp.delete:
        final g = _byId.remove(k);
        if (g == null) return;
        g.cells.remove(c.rowId);
        _dirty.add(g);
    }
  }

  Future<void> flush() async {
    final deletes = <List<Object?>>[];
    final puts = <List<Object?>>[];
    for (final k in _structureTouched) {
      final row = _structure[k];
      if (row == null) {
        deletes.add([fid, k.$1, k.$2]);
      } else {
        puts.add([fid, k.$1, k.$2, rows._encodeRow(_schema.tables[k.$1], row)]);
      }
    }
    if (deletes.isNotEmpty) {
      await tx.executeBatch(
        'DELETE FROM rev_row WHERE fid = ? AND tbl = ? AND id = ?',
        deletes,
      );
    }
    if (puts.isNotEmpty) {
      await tx.executeBatch(
        'INSERT OR REPLACE INTO rev_row (fid, tbl, id, data) '
        'VALUES (?, ?, ?, ?)',
        puts,
      );
    }
    if (_dirty.isEmpty) return;
    final dropRecords = <List<Object?>>[];
    final inserts = <List<Object?>>[];
    final updates = <List<Object?>>[];
    final dropIds = <List<Object?>>[];
    final addIds = <int, List<int>>{};
    final pending = rows._unindexed[fid];
    int? next;
    for (final g in _dirty) {
      final rid = g.rid;
      if (rid != null && (pending?.containsKey(rid) ?? false)) {
        // A record of a bootstrap in progress: its id entries come later.
        if (g.cells.isEmpty) {
          pending!.remove(rid);
          dropRecords.add([rid]);
        } else {
          pending![rid] = [
            for (final id in g.cells.keys) RevDomainRows.idHash(id),
          ];
          updates.add([rows._encodeGroup(g.tbl, g.cells.values), rid]);
        }
        continue;
      }
      if (g.cells.isEmpty) {
        if (rid != null) {
          dropRecords.add([rid]);

          for (final id in g.stored) {
            dropIds.add([fid, RevDomainRows.idHash(id), rid]);
          }
        }
        continue;
      }
      final data = rows._encodeGroup(g.tbl, g.cells.values);
      if (rid == null) {
        final r = g.rid = (next ??= await rows._maxRid(tx)) + 1;
        next = r;
        inserts.add([r, fid, g.tbl, g.scope, g.key, data]);
        for (final id in g.cells.keys) {
          (addIds[r] ??= []).add(RevDomainRows.idHash(id));
        }
        continue;
      }
      updates.add([data, rid]);
      for (final id in g.stored) {
        if (!g.cells.containsKey(id)) {
          dropIds.add([fid, RevDomainRows.idHash(id), rid]);
        }
      }
      for (final id in g.cells.keys) {
        if (!g.stored.contains(id)) {
          (addIds[rid] ??= []).add(RevDomainRows.idHash(id));
        }
      }
    }
    if (dropIds.isNotEmpty) {
      await tx.executeBatch(
        'DELETE FROM rev_cell_id WHERE fid = ? AND h = ? AND rid = ?',
        dropIds,
      );
    }
    if (dropRecords.isNotEmpty) {
      await tx.executeBatch('DELETE FROM rev_cells WHERE rid = ?', dropRecords);
    }
    if (updates.isNotEmpty) {
      await tx.executeBatch(
        'UPDATE rev_cells SET data = ? WHERE rid = ?',
        updates,
      );
    }
    if (inserts.isNotEmpty) {
      await tx.executeBatch(
        'INSERT INTO rev_cells (rid, fid, tbl, scope, row_key, data) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        inserts,
      );
    }
    await RevDomainRows.insertIds(tx, fid, addIds);
  }
}
