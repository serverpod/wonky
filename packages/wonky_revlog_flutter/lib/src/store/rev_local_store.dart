import 'dart:convert';

import 'package:sqlite_async/sqlite_async.dart';
import 'package:wonky_app/wonky_app.dart' show LocalDatabases;
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

/// The cached state of one file (`rev_local_file`, RevLog spec 02 §3).
final class RevLocalFile {
  /// Creates the record.
  const RevLocalFile({
    required this.fileUuid,
    required this.revision,
    this.itemJson,
    this.role,
    this.complete = false,
    this.pinned = false,
    this.lastOpenedAt,
    this.createdLocally = false,
    this.orphaned = false,
  });

  final String fileUuid;

  /// Server state stored = state at this revision (only increases).
  final int revision;
  final String? itemJson;
  final String? role;

  /// Every row loaded (available offline).
  final bool complete;
  final bool pinned;
  final DateTime? lastOpenedAt;

  /// Waiting for the queued drive create.
  final bool createdLocally;

  /// The queued create failed permanently.
  final bool orphaned;
}

/// An outbox row of the store.
final class RevStoredOp {
  /// Creates the record.
  const RevStoredOp(this.tabId, this.op, {required this.inflight});

  /// The creating tab.
  final String tabId;

  /// The op.
  final ChangeSet op;

  /// May have been sent.
  final bool inflight;
}

/// Metadata of a committed op kept locally (`rev_local_op`, 06 §3.3).
final class RevOpMeta {
  /// Creates the record.
  const RevOpMeta({
    required this.revision,
    required this.actorKind,
    required this.label,
    required this.committedAt,
    this.authorUuid,
    this.sessionId,
    this.groupId,
    this.groupLast = true,
    this.recordId,
    this.summary,
    this.detail,
    this.offline = false,
  });

  final int revision;
  final String? authorUuid;
  final String? sessionId;
  final String actorKind;
  final String label;
  final String? groupId;
  final bool groupLast;
  final String? recordId;
  final Map<String, Object?>? summary;
  final Map<String, Object?>? detail;
  final bool offline;
  final DateTime committedAt;
}

/// The local RevLog cache of one user and app (RevLog spec 02 §3, 06 §2).
///
/// Domain rows live in one generic table `rev_row` (table, id, JSON row,
/// plus the sheet/row key of cells for viewport and coverage reads), so the
/// cache needs no DDL per schema table and survives schema changes by a
/// simple reset.
final class RevLocalStore {
  RevLocalStore._(this.db, this.schema, this.app);

  /// The database.
  final SqliteDatabase db;

  /// The schema (decides the coverage of rows).
  final RevSchema schema;

  /// `sheets` | `slides`.
  final String app;

  /// The cache file of [app] and [userUuid].
  static String fileNameFor(String app, String userUuid) =>
      '${app}_cache_$userUuid.db';

  /// Opens the cache of [userUuid] (creating or resetting it).
  static Future<RevLocalStore> open({
    required RevSchema schema,
    required String userUuid,
    required String app,
    String? directory,
  }) async {
    final db = await LocalDatabases.open(
      fileNameFor(app, userUuid),
      migrations: migrations,
      directory: directory,
    );
    final store = RevLocalStore._(db, schema, app);
    await store._checkSchema();
    return store;
  }

  /// The cache's migrations (fixed DDL; domain data is JSON).
  static final migrations = SqliteMigrations()
    ..add(
      SqliteMigration(1, (tx) async {
        await tx.execute(
          'CREATE TABLE rev_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await tx.execute('''
          CREATE TABLE rev_local_file (
            file_uuid TEXT PRIMARY KEY,
            item_json TEXT,
            role TEXT,
            revision INTEGER NOT NULL,
            complete INTEGER NOT NULL DEFAULT 0,
            pinned INTEGER NOT NULL DEFAULT 0,
            last_opened_at INTEGER,
            size_bytes INTEGER NOT NULL DEFAULT 0,
            created_locally INTEGER NOT NULL DEFAULT 0,
            orphaned INTEGER NOT NULL DEFAULT 0
          )''');
        await tx.execute('''
          CREATE TABLE rev_coverage (
            file_uuid TEXT NOT NULL,
            key TEXT NOT NULL,
            revision INTEGER NOT NULL,
            PRIMARY KEY (file_uuid, key)
          )''');
        await tx.execute('''
          CREATE TABLE rev_local_op (
            file_uuid TEXT NOT NULL,
            revision INTEGER NOT NULL,
            author_uuid TEXT, session_id TEXT, actor_kind TEXT NOT NULL,
            label TEXT NOT NULL, group_id TEXT, group_last INTEGER NOT NULL DEFAULT 1,
            record_id TEXT, summary_json TEXT, detail_json TEXT,
            offline INTEGER NOT NULL DEFAULT 0,
            committed_at INTEGER NOT NULL,
            PRIMARY KEY (file_uuid, revision)
          )''');
        await tx.execute('''
          CREATE TABLE rev_outbox (
            file_uuid TEXT NOT NULL,
            seq INTEGER NOT NULL,
            tab_id TEXT NOT NULL,
            client_op_id TEXT NOT NULL,
            payload TEXT NOT NULL,
            schema_hash TEXT NOT NULL,
            inflight INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (file_uuid, client_op_id)
          )''');
        await tx.execute(
          'CREATE INDEX rev_outbox_seq ON rev_outbox (file_uuid, seq)',
        );
        await tx.execute('''
          CREATE TABLE rev_outcome (
            file_uuid TEXT NOT NULL,
            revision INTEGER NOT NULL,
            outcome_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (file_uuid, revision)
          )''');
        await tx.execute('''
          CREATE TABLE rev_row (
            file_uuid TEXT NOT NULL,
            tbl TEXT NOT NULL,
            id TEXT NOT NULL,
            scope TEXT,
            row_key TEXT,
            data TEXT NOT NULL,
            PRIMARY KEY (file_uuid, tbl, id)
          )''');
        await tx.execute(
          'CREATE INDEX rev_row_scope ON rev_row (file_uuid, scope, row_key)',
        );
      }),
    );

  Future<void> _checkSchema() async {
    final rows = await db.getAll(
      "SELECT value FROM rev_meta WHERE key = 'schemaHash'",
    );
    final stored = rows.isEmpty ? null : rows.first['value'] as String;
    if (stored == schema.hash) return;
    await db.writeTransaction((tx) async {
      // A new schema: server state is reloaded (02 §2.4); the outbox stays
      // and is re-encoded below.
      await tx.execute('DELETE FROM rev_row');
      await tx.execute('DELETE FROM rev_coverage');
      await tx.execute('UPDATE rev_local_file SET complete = 0, revision = 0');
      await tx.execute(
        "INSERT OR REPLACE INTO rev_meta (key, value) VALUES ('schemaHash', ?)",
        [schema.hash],
      );
    });
    await _restampOutbox();
  }

  /// Re-encodes outbox rows of an older schema (02 §2.4): changes to
  /// tables or columns that no longer exist are dropped.
  Future<int> _restampOutbox() async {
    final rows = await db.getAll(
      'SELECT file_uuid, client_op_id, payload FROM rev_outbox '
      'WHERE schema_hash != ?',
      [schema.hash],
    );
    var dropped = 0;
    final codec = RevCodec(schema, lenient: true);
    await db.writeTransaction((tx) async {
      for (final r in rows) {
        final op = _decodeOp(r['payload'] as String, codec);
        if (op == null) {
          dropped++;
          await tx.execute(
            'DELETE FROM rev_outbox WHERE file_uuid = ? AND client_op_id = ?',
            [r['file_uuid'], r['client_op_id']],
          );
          continue;
        }
        await tx.execute(
          'UPDATE rev_outbox SET payload = ?, schema_hash = ? '
          'WHERE file_uuid = ? AND client_op_id = ?',
          [
            _encodeOp(op, codec),
            schema.hash,
            r['file_uuid'],
            r['client_op_id'],
          ],
        );
      }
    });
    return dropped;
  }

  late final RevCodec _codec = RevCodec(schema, lenient: true);

  static String _encodeOp(ChangeSet op, RevCodec codec) => jsonEncode({
    'id': op.clientOpId,
    'base': op.baseRevision,
    'label': op.label,
    'actor': op.actorKind,
    'group': op.groupId,
    'gi': op.groupIndex,
    'gl': op.groupLast,
    'offline': op.offline,
    'at': op.createdAt.millisecondsSinceEpoch,
    'p': codec.encode(op.changes, summary: op.summary, detail: op.detail),
  });

  static ChangeSet? _decodeOp(String json, RevCodec codec) {
    try {
      final m = (jsonDecode(json) as Map).cast<String, Object?>();
      final p = codec.decode((m['p']! as Map).cast<String, Object?>());
      return ChangeSet(
        clientOpId: m['id']! as String,
        baseRevision: (m['base']! as num).toInt(),
        changes: p.changes,
        label: m['label'] as String? ?? '',
        actorKind: m['actor'] as String? ?? 'user',
        summary: p.summary,
        detail: p.detail,
        groupId: m['group'] as String?,
        groupIndex: (m['gi'] as num?)?.toInt() ?? 0,
        groupLast: m['gl'] as bool? ?? true,
        offline: m['offline'] as bool? ?? false,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (m['at']! as num).toInt(),
          isUtc: true,
        ),
      );
    } on Object {
      return null;
    }
  }

  // ---------------------------------------------------------------- files

  /// The cached file [fileUuid], or null.
  Future<RevLocalFile?> loadFile(String fileUuid) async {
    final rows = await db.getAll(
      'SELECT * FROM rev_local_file WHERE file_uuid = ?',
      [fileUuid],
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return RevLocalFile(
      fileUuid: fileUuid,
      revision: r['revision'] as int,
      itemJson: r['item_json'] as String?,
      role: r['role'] as String?,
      complete: r['complete'] == 1,
      pinned: r['pinned'] == 1,
      lastOpenedAt: r['last_opened_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              r['last_opened_at'] as int,
              isUtc: true,
            ),
      createdLocally: r['created_locally'] == 1,
      orphaned: r['orphaned'] == 1,
    );
  }

  /// Creates or updates the file row (revision never decreases).
  Future<void> touchFile(
    String fileUuid, {
    String? itemJson,
    String? role,
    bool? pinned,
    bool? createdLocally,
    bool? orphaned,
    bool opened = false,
  }) => db.writeTransaction((tx) async {
    await tx.execute(
      'INSERT OR IGNORE INTO rev_local_file (file_uuid, revision) VALUES (?, 0)',
      [fileUuid],
    );
    final sets = <String>[];
    final args = <Object?>[];
    void set(String col, Object? v) {
      sets.add('$col = ?');
      args.add(v);
    }

    if (itemJson != null) set('item_json', itemJson);
    if (role != null) set('role', role);
    if (pinned != null) set('pinned', pinned ? 1 : 0);
    if (createdLocally != null) set('created_locally', createdLocally ? 1 : 0);
    if (orphaned != null) set('orphaned', orphaned ? 1 : 0);
    if (opened) set('last_opened_at', DateTime.now().millisecondsSinceEpoch);
    if (sets.isEmpty) return;
    await tx.execute(
      'UPDATE rev_local_file SET ${sets.join(', ')} WHERE file_uuid = ?',
      [...args, fileUuid],
    );
  });

  /// Marks [fileUuid] complete (every row loaded) at its revision.
  Future<void> markComplete(String fileUuid, {required bool complete}) =>
      db.execute('UPDATE rev_local_file SET complete = ? WHERE file_uuid = ?', [
        complete ? 1 : 0,
        fileUuid,
      ]);

  /// Forgets the server state of [fileUuid] (re-bootstrap; the outbox
  /// stays).
  Future<void> resetServerState(String fileUuid) => db.writeTransaction((
    tx,
  ) async {
    await tx.execute('DELETE FROM rev_row WHERE file_uuid = ?', [fileUuid]);
    await tx.execute('DELETE FROM rev_coverage WHERE file_uuid = ?', [
      fileUuid,
    ]);
    await tx.execute(
      'UPDATE rev_local_file SET revision = 0, complete = 0 WHERE file_uuid = ?',
      [fileUuid],
    );
  });

  /// Removes everything of [fileUuid] except its outbox (eviction).
  Future<void> evict(String fileUuid) => db.writeTransaction((tx) async {
    for (final t in const [
      'rev_row',
      'rev_coverage',
      'rev_local_op',
      'rev_outcome',
      'rev_local_file',
    ]) {
      await tx.execute('DELETE FROM $t WHERE file_uuid = ?', [fileUuid]);
    }
  });

  /// Every cached file.
  Future<List<RevLocalFile>> files() async {
    final rows = await db.getAll('SELECT file_uuid FROM rev_local_file');
    return [for (final r in rows) ?await loadFile(r['file_uuid'] as String)];
  }

  // --------------------------------------------------------------- outbox

  /// The outbox rows this store wrote last per (file, tab): the op objects,
  /// oldest first. [replaceOutbox] rewrites only what changed since.
  final Map<(String, String), List<ChangeSet>> _written = {};

  /// Replaces [tabId]'s outbox of [fileUuid] with [ops] (oldest first).
  ///
  /// Incremental: the outbox changes at its ends (acks remove the oldest
  /// ops, edits append or compose into the newest), so ops still stored
  /// from the last call (the same objects, in the same order, before every
  /// new one) are kept as they are and only the rest is deleted or encoded
  /// and inserted. Anything else rewrites the tab's outbox.
  Future<void> replaceOutbox(
    String fileUuid,
    String tabId,
    List<ChangeSet> ops, {
    Set<String> inflight = const {},
  }) {
    final key = (fileUuid, tabId);
    return db.writeTransaction((tx) async {
      final before = _written.remove(key);
      var keep = 0;
      if (before != null && inflight.isEmpty) {
        // The kept ops are a run of [before] that starts [ops].
        final at = ops.isEmpty
            ? -1
            : before.indexWhere((o) => identical(o, ops.first));
        if (at >= 0) {
          while (keep < ops.length &&
              at + keep < before.length &&
              identical(before[at + keep], ops[keep])) {
            keep++;
          }
        }
      }
      if (keep > 0) {
        final kept = [for (final o in ops.take(keep)) o.clientOpId];
        await tx.execute(
          'DELETE FROM rev_outbox WHERE file_uuid = ? AND tab_id = ? AND '
          'client_op_id NOT IN (${List.filled(kept.length, '?').join(', ')})',
          [fileUuid, tabId, ...kept],
        );
        final n = await tx.getOptional(
          'SELECT count(*) AS n FROM rev_outbox WHERE file_uuid = ? AND '
          'tab_id = ?',
          [fileUuid, tabId],
        );
        // Rows changed behind our back (adoption, clearing): rewrite.
        if ((n?['n'] as int?) != keep) keep = 0;
      }
      if (keep == 0) {
        await tx.execute(
          'DELETE FROM rev_outbox WHERE file_uuid = ? AND tab_id = ?',
          [fileUuid, tabId],
        );
      }
      final start = await tx.getOptional(
        'SELECT max(seq) AS s FROM rev_outbox WHERE file_uuid = ?',
        [fileUuid],
      );
      var seq = (start?['s'] as int?) ?? 0;
      final added = ops.skip(keep).toList();
      if (added.isNotEmpty) {
        await tx.executeBatch(
          'INSERT INTO rev_outbox (file_uuid, seq, tab_id, client_op_id, '
          'payload, schema_hash, inflight, created_at) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            for (final op in added)
              [
                fileUuid,
                ++seq,
                tabId,
                op.clientOpId,
                _encodeOp(op, _codec),
                schema.hash,
                inflight.contains(op.clientOpId) ? 1 : 0,
                op.createdAt.millisecondsSinceEpoch,
              ],
          ],
        );
      }
      _written[key] = List.of(ops);
    });
  }

  /// The outbox of [fileUuid] (all tabs), oldest first.
  Future<List<RevStoredOp>> outbox(String fileUuid) async {
    final rows = await db.getAll(
      'SELECT tab_id, payload, inflight FROM rev_outbox WHERE file_uuid = ? '
      'ORDER BY seq',
      [fileUuid],
    );
    return [
      for (final r in rows)
        if (_decodeOp(r['payload'] as String, _codec) case final op?)
          RevStoredOp(r['tab_id'] as String, op, inflight: r['inflight'] == 1),
    ];
  }

  /// Moves the outbox rows of [fromTabs] of [fileUuid] to [tabId]
  /// (adoption of tabs that are gone, 06 §2.6).
  Future<int> adopt(String fileUuid, Set<String> fromTabs, String tabId) async {
    if (fromTabs.isEmpty) return 0;
    var n = 0;
    await db.writeTransaction((tx) async {
      for (final t in fromTabs) {
        final r = await tx.execute(
          'UPDATE rev_outbox SET tab_id = ? WHERE file_uuid = ? AND tab_id = ? '
          'RETURNING client_op_id',
          [tabId, fileUuid, t],
        );
        n += r.length;
      }
    });
    return n;
  }

  /// Files with outbox rows.
  Future<List<String>> filesWithOutbox() async => [
    for (final r in await db.getAll(
      'SELECT DISTINCT file_uuid FROM rev_outbox',
    ))
      r['file_uuid'] as String,
  ];

  /// Number of outbox changes of [fileUuid] (all tabs).
  Future<int> pendingChanges(String fileUuid) async {
    var n = 0;
    for (final op in await outbox(fileUuid)) {
      n += op.op.changes.length;
    }
    return n;
  }

  // ---------------------------------------------------------------- rows

  (String?, String?) _scope(String table, Map<String, Object?> row) {
    final t = schema.tryTable(table);
    if (t?.coverage != RevCoverage.cellsByRow) return (null, null);
    final parents = t!.parents;
    final scope = parents.isEmpty ? null : row[parents.first.column];
    final key = parents.length < 2 ? null : row[parents[1].column];
    return (scope as String?, key as String?);
  }

  static Object? _jsonSafe(Object? v) => switch (v) {
    DateTime() => {r'$date': v.toUtc().millisecondsSinceEpoch},
    _ => v,
  };

  static Object? _fromJsonSafe(Object? v) =>
      v is Map && v.length == 1 && v.containsKey(r'$date')
      ? DateTime.fromMillisecondsSinceEpoch(
          (v[r'$date']! as num).toInt(),
          isUtc: true,
        )
      : v;

  /// The stored JSON of a full row. Null columns are left out (a cell has
  /// ~30 columns, mostly null): an absent column reads back as null.
  static String _encodeRow(Map<String, Object?> row) => jsonEncode({
    for (final e in row.entries)
      if (e.value != null) e.key: _jsonSafe(e.value),
  });

  static Map<String, Object?> _decodeRow(String json) => {
    for (final e in (jsonDecode(json) as Map).entries)
      e.key as String: _fromJsonSafe(e.value),
  };

  Future<void> _putRows(
    SqliteWriteContext tx,
    String fileUuid,
    Iterable<(String, Map<String, Object?>)> rows,
  ) async {
    // One prepared statement for the whole set (a statement per row costs
    // a round trip to the database isolate each).
    final sets = <List<Object?>>[
      for (final (table, row) in rows)
        if (_scope(table, row) case (final scope, final key))
          [
            fileUuid,
            table,
            row[RowChange.idColumn]! as String,
            scope,
            key,
            _encodeRow(row),
          ],
    ];
    if (sets.isEmpty) return;
    await tx.executeBatch(
      'INSERT OR REPLACE INTO rev_row (file_uuid, tbl, id, scope, row_key, data) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      sets,
    );
  }

  /// Applies [applied] (in order) to the stored rows: the rows the updates
  /// need are read in one query per table, the result is written in two
  /// batches.
  Future<void> _replay(
    SqliteWriteContext tx,
    String fileUuid,
    List<RowChange> applied,
  ) async {
    if (applied.isEmpty) return;
    // Final state per touched row: a row map, or null (deleted / absent).
    final rows = <(String, String), Map<String, Object?>?>{};
    final updated = <String, Set<String>>{};
    final inserted = <(String, String)>{};
    for (final c in applied) {
      if (c.op == RowOp.update && !inserted.contains((c.table, c.rowId))) {
        (updated[c.table] ??= {}).add(c.rowId);
      } else if (c.op == RowOp.insert) {
        inserted.add((c.table, c.rowId));
      }
    }
    for (final MapEntry(key: table, value: ids) in updated.entries) {
      final list = ids.toList();
      for (var i = 0; i < list.length; i += 500) {
        final chunk = list.sublist(i, (i + 500).clamp(0, list.length));
        for (final r in await tx.getAll(
          'SELECT id, data FROM rev_row WHERE file_uuid = ? AND tbl = ? '
          'AND id IN (${List.filled(chunk.length, '?').join(', ')})',
          [fileUuid, table, ...chunk],
        )) {
          rows[(table, r['id'] as String)] = _decodeRow(r['data'] as String);
        }
      }
    }
    final touched = <(String, String)>{};
    for (final c in applied) {
      final k = (c.table, c.rowId);
      switch (c.op) {
        case RowOp.insert:
          rows[k] = {...c.columnsAfter, RowChange.idColumn: c.rowId};
        case RowOp.update:
          final cur = rows[k];
          if (cur == null) continue;
          rows[k] = {...cur, ...c.columnsAfter};
        case RowOp.delete:
          rows[k] = null;
      }
      touched.add(k);
    }
    final deletes = [
      for (final k in touched)
        if (rows[k] == null) [fileUuid, k.$1, k.$2],
    ];
    if (deletes.isNotEmpty) {
      await tx.executeBatch(
        'DELETE FROM rev_row WHERE file_uuid = ? AND tbl = ? AND id = ?',
        deletes,
      );
    }
    await _putRows(tx, fileUuid, [
      for (final k in touched)
        if (rows[k] case final row?) (k.$1, row),
    ]);
  }

  /// Applies a committed op (06 §2.2): only when [revision] is beyond the
  /// stored one (monotonic). Records its metadata and removes the acked
  /// outbox row. Returns whether it was applied.
  Future<bool> applyServerOp(
    String fileUuid,
    int revision,
    List<RowChange> applied,
    RevOpMeta meta, {
    String? ackedClientOpId,
    bool domain = true,
  }) => db.writeTransaction((tx) async {
    if (ackedClientOpId != null) {
      await tx.execute(
        'DELETE FROM rev_outbox WHERE file_uuid = ? AND client_op_id = ?',
        [fileUuid, ackedClientOpId],
      );
    }
    final f = await tx.getOptional(
      'SELECT revision FROM rev_local_file WHERE file_uuid = ?',
      [fileUuid],
    );
    if (f == null || (f['revision'] as int) >= revision) return false;
    if (domain) await _replay(tx, fileUuid, applied);
    await tx.execute(
      'UPDATE rev_local_file SET revision = ? WHERE file_uuid = ?',
      [revision, fileUuid],
    );
    await tx.execute(
      'INSERT OR REPLACE INTO rev_local_op (file_uuid, revision, author_uuid, '
      'session_id, actor_kind, label, group_id, group_last, record_id, '
      'summary_json, detail_json, offline, committed_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        fileUuid,
        revision,
        meta.authorUuid,
        meta.sessionId,
        meta.actorKind,
        meta.label,
        meta.groupId,
        meta.groupLast ? 1 : 0,
        meta.recordId,
        meta.summary == null ? null : jsonEncode(meta.summary),
        meta.detail == null ? null : jsonEncode(meta.detail),
        meta.offline ? 1 : 0,
        meta.committedAt.millisecondsSinceEpoch,
      ],
    );
    return true;
  });

  /// Applies a bootstrap page (06 §5.3): for each coverage key not already
  /// covered at a revision ≥ [revision], replaces the covered rows with
  /// [rows] (absent ones are deleted), then replays [replay] (buffered ops'
  /// changes newer than the page, for the covered keys) and records the
  /// coverage. [coverage] are `tbl:<table>:<from>:<to>` / `row:<s>:<r>`.
  Future<void> applyPage(
    String fileUuid, {
    required int revision,
    required List<String> coverage,
    required List<(String, Map<String, Object?>)> rows,
    required List<RowChange> replay,
  }) => db.writeTransaction((tx) async {
    await tx.execute(
      'INSERT OR IGNORE INTO rev_local_file (file_uuid, revision) VALUES (?, 0)',
      [fileUuid],
    );
    // The coverage this page may replace: keys not covered at a revision
    // ≥ the page's (read and written in batches; a cell page has 500).
    final have = <String, int>{};
    for (var i = 0; i < coverage.length; i += 500) {
      final chunk = coverage.sublist(i, (i + 500).clamp(0, coverage.length));
      for (final r in await tx.getAll(
        'SELECT key, revision FROM rev_coverage WHERE file_uuid = ? AND key '
        'IN (${List.filled(chunk.length, '?').join(', ')})',
        [fileUuid, ...chunk],
      )) {
        have[r['key'] as String] = r['revision'] as int;
      }
    }
    final stale = [
      for (final key in coverage)
        if ((have[key] ?? -1) < revision) key,
    ];
    final rowKeys = <List<Object?>>[];
    for (final key in stale) {
      final parts = key.split(':');
      if (parts.first == 'tbl') {
        final table = parts[1];
        final from = parts[2], to = parts[3];
        await tx.execute(
          'DELETE FROM rev_row WHERE file_uuid = ? AND tbl = ?'
          '${from == '-' ? '' : ' AND id > ?'}${to == '+' ? '' : ' AND id <= ?'}',
          [fileUuid, table, if (from != '-') from, if (to != '+') to],
        );
      } else if (parts.first == 'row') {
        rowKeys.add([fileUuid, parts[1], parts[2]]);
      }
    }
    if (rowKeys.isNotEmpty) {
      await tx.executeBatch(
        'DELETE FROM rev_row WHERE file_uuid = ? AND scope = ? AND row_key = ?',
        rowKeys,
      );
    }
    if (stale.isNotEmpty) {
      await tx.executeBatch(
        'INSERT OR REPLACE INTO rev_coverage (file_uuid, key, revision) '
        'VALUES (?, ?, ?)',
        [
          for (final key in stale) [fileUuid, key, revision],
        ],
      );
    }
    await _putRows(tx, fileUuid, rows);
    await _replay(tx, fileUuid, replay);
  });

  /// The coverage keys of [fileUuid] with their revisions.
  Future<Map<String, int>> coverage(String fileUuid) async => {
    for (final r in await db.getAll(
      'SELECT key, revision FROM rev_coverage WHERE file_uuid = ?',
      [fileUuid],
    ))
      r['key'] as String: r['revision'] as int,
  };

  /// Every row of [fileUuid] except [skip] tables, in keyset pages.
  Future<List<(String, Map<String, Object?>)>> loadRows(
    String fileUuid, {
    Set<String> skip = const {},
  }) async {
    final out = <(String, Map<String, Object?>)>[];
    String? afterTbl, afterId;
    while (true) {
      final rows = await db.getAll(
        'SELECT tbl, id, data FROM rev_row WHERE file_uuid = ?'
        '${afterTbl == null ? '' : ' AND (tbl, id) > (?, ?)'} '
        'ORDER BY tbl, id LIMIT 10000',
        [fileUuid, ?afterTbl, ?afterId],
      );
      for (final r in rows) {
        final t = r['tbl'] as String;
        if (skip.contains(t)) continue;
        out.add((t, _decodeRow(r['data'] as String)));
      }
      if (rows.length < 10000) return out;
      afterTbl = rows.last['tbl'] as String;
      afterId = rows.last['id'] as String;
    }
  }

  /// The cells (cellsByRow rows) of [scope] (sheet) in [rowKeys].
  Future<List<(String, Map<String, Object?>)>> loadScoped(
    String fileUuid,
    String scope,
    List<String> rowKeys,
  ) async {
    final out = <(String, Map<String, Object?>)>[];
    for (var i = 0; i < rowKeys.length; i += 500) {
      final chunk = rowKeys.sublist(i, (i + 500).clamp(0, rowKeys.length));
      final rows = await db.getAll(
        'SELECT tbl, data FROM rev_row WHERE file_uuid = ? AND scope = ? '
        'AND row_key IN (${List.filled(chunk.length, '?').join(', ')})',
        [fileUuid, scope, ...chunk],
      );
      for (final r in rows) {
        out.add((r['tbl'] as String, _decodeRow(r['data'] as String)));
      }
    }
    return out;
  }

  /// The stored row of ([table], [id]) of [fileUuid], or null.
  Future<Map<String, Object?>?> row(
    String fileUuid,
    String table,
    String id,
  ) async {
    final r = await db.getOptional(
      'SELECT data FROM rev_row WHERE file_uuid = ? AND tbl = ? AND id = ?',
      [fileUuid, table, id],
    );
    return r == null ? null : _decodeRow(r['data'] as String);
  }

  // ------------------------------------------------------------- history

  /// Op metadata of [fileUuid] committed since [since] (newest last).
  Future<List<RevOpMeta>> recentOps(String fileUuid, DateTime since) async => [
    for (final r in await db.getAll(
      'SELECT * FROM rev_local_op WHERE file_uuid = ? AND committed_at >= ? '
      'ORDER BY revision',
      [fileUuid, since.millisecondsSinceEpoch],
    ))
      RevOpMeta(
        revision: r['revision'] as int,
        authorUuid: r['author_uuid'] as String?,
        sessionId: r['session_id'] as String?,
        actorKind: r['actor_kind'] as String,
        label: r['label'] as String,
        groupId: r['group_id'] as String?,
        groupLast: r['group_last'] == 1,
        recordId: r['record_id'] as String?,
        summary: r['summary_json'] == null
            ? null
            : (jsonDecode(r['summary_json'] as String) as Map)
                  .cast<String, Object?>(),
        detail: r['detail_json'] == null
            ? null
            : (jsonDecode(r['detail_json'] as String) as Map)
                  .cast<String, Object?>(),
        offline: r['offline'] == 1,
        committedAt: DateTime.fromMillisecondsSinceEpoch(
          r['committed_at'] as int,
          isUtc: true,
        ),
      ),
  ];

  /// Keeps 30 days or 20,000 ops per file of op metadata (06 §3.3).
  Future<void> pruneOps(String fileUuid) => db.writeTransaction((tx) async {
    final cutoff = DateTime.now()
        .subtract(const Duration(days: 30))
        .millisecondsSinceEpoch;
    await tx.execute(
      'DELETE FROM rev_local_op WHERE file_uuid = ? AND committed_at < ?',
      [fileUuid, cutoff],
    );
    await tx.execute(
      'DELETE FROM rev_local_op WHERE file_uuid = ? AND revision <= '
      '(SELECT revision FROM rev_local_op WHERE file_uuid = ? '
      'ORDER BY revision DESC LIMIT 1 OFFSET 20000)',
      [fileUuid, fileUuid],
    );
  });

  /// Stores an outcome for the review UI (06 §6).
  Future<void> addOutcome(
    String fileUuid,
    int revision,
    String json,
  ) => db.execute(
    'INSERT OR REPLACE INTO rev_outcome (file_uuid, revision, outcome_json, '
    'created_at) VALUES (?, ?, ?, ?)',
    [fileUuid, revision, json, DateTime.now().millisecondsSinceEpoch],
  );

  /// Cache size for Settings (bytes of row data).
  Future<int> usageBytes() async {
    final r = await db.getOptional(
      'SELECT coalesce(sum(length(data)), 0) AS n FROM rev_row',
    );
    return (r?['n'] as int?) ?? 0;
  }

  /// Empties the cache (Settings › Clear), keeping nothing.
  Future<void> clearAll() => db.writeTransaction((tx) async {
    for (final t in const [
      'rev_row',
      'rev_coverage',
      'rev_local_op',
      'rev_outcome',
      'rev_outbox',
      'rev_local_file',
    ]) {
      await tx.execute('DELETE FROM $t');
    }
  });

  /// Closes the database.
  Future<void> close() => db.close();
}
