import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqlite_async/sqlite_async.dart';
import 'package:wonky_app/wonky_app.dart' show LocalDatabases;
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

import 'rev_domain_rows.dart';

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

/// Rows read from the store with the revision of the server state they
/// belong to (read in one transaction).
final class RevStoredRows {
  /// Creates the record.
  const RevStoredRows(this.revision, this.rows);

  /// `rev_local_file.revision` at the read.
  final int revision;

  /// (table, full row).
  final List<(String, Map<String, Object?>)> rows;
}

/// One bootstrap page for [RevLocalStore.applyPages].
final class RevPageWrite {
  /// Creates the record.
  const RevPageWrite({
    required this.revision,
    required this.coverage,
    required this.rows,
    this.replay = const [],
  });

  /// The page revision `Rp`.
  final int revision;

  /// Its coverage keys.
  final List<String> coverage;

  /// Its rows (table, full row).
  final List<(String, Map<String, Object?>)> rows;

  /// Buffered changes newer than the page, for its keys.
  final List<RowChange> replay;
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
/// Domain rows live in generic tables ([RevDomainRows]: structure rows one
/// per record, cells one record per sheet row, a compact binary row
/// encoding), so the cache needs no DDL per schema table and survives
/// schema changes by a simple reset.
final class RevLocalStore {
  RevLocalStore._(this.db, this.schema, this.app)
    : _rows = RevDomainRows(schema);

  final RevDomainRows _rows;

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
    await store._pragmas();
    await store._checkSchema();
    return store;
  }

  /// Per-connection settings (06 §2.1): a 64 MB page cache for the writer
  /// (bulk page writes into a cache of a million cells), temp tables in
  /// memory and fewer WAL checkpoints during bulk loads.
  ///
  /// The web has a single worker connection, set directly: there
  /// `withAllConnections` holds the write lock but hands the block the
  /// unlocked database, so any statement in it waits for that lock forever
  /// (sqlite_async 0.14) and the cache never opens.
  Future<void> _pragmas() async {
    if (kIsWeb) {
      try {
        await db.execute('PRAGMA cache_size = -65536');
        await db.execute('PRAGMA temp_store = MEMORY');
      } on Object {
        // The defaults work.
      }
      return;
    }
    try {
      await db.withAllConnections((writer, readers) async {
        await writer.execute('PRAGMA cache_size = -65536');
        await writer.execute('PRAGMA temp_store = MEMORY');
        await writer.execute('PRAGMA wal_autocheckpoint = 20000');
        for (final r in readers) {
          await r.getAll('PRAGMA cache_size = -16384');
        }
      });
    } on Object {
      // Not every platform's pool allows it (web); the defaults work.
    }
  }

  /// The cache's migrations (fixed DDL; domain rows are binary, see
  /// [RevDomainRows]). A new layout resets server state (the outbox stays).
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
    )
    ..add(
      // R7: integer file ids, cells grouped per sheet row, binary rows
      // (~700 → ~70 bytes per cell). Server state is reloaded.
      SqliteMigration(2, (tx) async {
        await tx.execute('DROP TABLE rev_row');
        await RevDomainRows.createTables(tx);
        await tx.execute('DELETE FROM rev_coverage');
        await tx.execute(
          'UPDATE rev_local_file SET complete = 0, revision = 0',
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
      await _rows.deleteAll(tx);
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

  /// Marks [fileUuid] complete (every row loaded) at its revision. A
  /// finished bootstrap passes the [revision] its rows are at (pages and
  /// the buffered ops replayed on them), so a reopen catches up from there
  /// (the revision never decreases). A complete file needs no coverage
  /// keys any more (a new bootstrap starts from a reset): they go.
  Future<void> markComplete(
    String fileUuid, {
    required bool complete,
    int? revision,
  }) => db.writeTransaction((tx) async {
    await tx.execute(
      'UPDATE rev_local_file SET complete = ?, '
      'revision = max(revision, ?) WHERE file_uuid = ?',
      [complete ? 1 : 0, revision ?? 0, fileUuid],
    );
    if (complete) {
      await tx.execute('DELETE FROM rev_coverage WHERE file_uuid = ?', [
        fileUuid,
      ]);
      await _rows.indexPending(tx, fileUuid);
    }
  });

  /// Forgets the server state of [fileUuid] (re-bootstrap; the outbox
  /// stays).
  Future<void> resetServerState(String fileUuid) => db.writeTransaction((
    tx,
  ) async {
    await _rows.deleteFile(tx, fileUuid);
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
    _filesWithRow.remove(fileUuid);
    await _rows.deleteFile(tx, fileUuid);
    for (final t in const [
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
    if (domain && applied.isNotEmpty) {
      await _rows.replay(tx, await _rows.fidFor(tx, fileUuid), applied);
    }
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

  /// Files whose `rev_local_file` row this store wrote (page writes skip
  /// inserting it again; eviction and clearing forget them).
  final Set<String> _filesWithRow = {};

  /// Applies a bootstrap page (06 §5.3): for each coverage key not already

  /// covered at a revision ≥ [revision], replaces the covered rows with
  /// [rows] (absent ones are deleted; rows of keys covered at a newer
  /// revision are skipped), then replays [replay] (buffered ops' changes
  /// newer than the page, for the covered keys) and records the coverage.
  /// [coverage] are `tbl:<table>:<from>:<to>` / `row:<s>:<r>`.
  Future<void> applyPage(
    String fileUuid, {
    required int revision,
    required List<String> coverage,
    required List<(String, Map<String, Object?>)> rows,
    required List<RowChange> replay,
  }) => applyPages(fileUuid, [
    RevPageWrite(
      revision: revision,
      coverage: coverage,
      rows: rows,
      replay: replay,
    ),
  ]);

  /// [applyPage] for several pages, in order, in one transaction. Pages
  /// whose coverage keys don't overlap are written together (a few
  /// statements for the whole batch: a page write that waits for the UI
  /// isolate between its statements falls behind a download).
  Future<void> applyPages(String fileUuid, List<RevPageWrite> pages) =>
      db.writeTransaction((tx) async {
        if (!_filesWithRow.contains(fileUuid)) {
          await tx.execute(
            'INSERT OR IGNORE INTO rev_local_file (file_uuid, revision) '
            'VALUES (?, 0)',
            [fileUuid],
          );
          _filesWithRow.add(fileUuid);
        }
        final fid = await _rows.fidFor(tx, fileUuid);
        // Consecutive pages with disjoint coverage form one write.
        var from = 0;
        while (from < pages.length) {
          final keys = <String>{...pages[from].coverage};
          var to = from + 1;
          while (to < pages.length && !pages[to].coverage.any(keys.contains)) {
            keys.addAll(pages[to].coverage);
            to++;
          }
          await _writePages(tx, fileUuid, fid, pages.sublist(from, to));
          from = to;
        }
      });

  /// Writes [pages] with disjoint coverage keys as one page.
  Future<void> _writePages(
    SqliteWriteContext tx,
    String fileUuid,
    int fid,
    List<RevPageWrite> pages,
  ) async {
    // The coverage these pages may replace: keys not covered at a
    // revision ≥ their page's.
    final revisionOf = <String, int>{
      for (final p in pages)
        for (final key in p.coverage) key: p.revision,
    };
    // New cells only (most of a download): one round trip.
    if (pages.every((p) => p.replay.isEmpty) &&
        await _rows.writeNewCells(tx, fileUuid, fid, revisionOf, [
          for (final p in pages) ...p.rows,
        ])) {
      return;
    }

    final keys = revisionOf.keys.toList();
    final have = <String, int>{};
    // The largest record rowid comes with the first chunk (one statement
    // less per batch).
    int? maxRid;
    for (var i = 0; i == 0 || i < keys.length; i += 2000) {
      final chunk = keys.sublist(i, (i + 2000).clamp(0, keys.length));
      for (final r in await tx.getAll(
        'SELECT key, revision FROM rev_coverage WHERE file_uuid = ? AND key '
        'IN (${List.filled(chunk.length, '?').join(', ')})'
        '${i == 0 ? ' UNION ALL SELECT NULL, coalesce(max(rid), 0) '
                  'FROM rev_cells' : ''}',
        [fileUuid, ...chunk],
      )) {
        final key = r['key'] as String?;
        if (key == null) {
          maxRid = r['revision'] as int;
        } else {
          have[key] = r['revision'] as int;
        }
      }
    }
    final stale = {
      for (final MapEntry(key: key, value: revision) in revisionOf.entries)
        if ((have[key] ?? -1) < revision) key,
    };
    await _rows.writePage(
      tx,
      fid,
      coverage: keys,
      stale: stale,
      rows: [for (final p in pages) ...p.rows],
      replay: [for (final p in pages) ...p.replay],
      maxRid: maxRid,
    );
    if (stale.isNotEmpty) {
      await tx.executeBatch(
        'INSERT OR REPLACE INTO rev_coverage (file_uuid, key, revision) '
        'VALUES (?, ?, ?)',
        [
          for (final key in stale) [fileUuid, key, revisionOf[key]],
        ],
      );
    }
  }

  /// The coverage keys of [fileUuid] with their revisions.
  Future<Map<String, int>> coverage(String fileUuid) async => {
    for (final r in await db.getAll(
      'SELECT key, revision FROM rev_coverage WHERE file_uuid = ?',
      [fileUuid],
    ))
      r['key'] as String: r['revision'] as int,
  };

  /// Every row of [fileUuid] except [skip] tables: the structure (parents'
  /// tables first), then the cells.
  Future<List<(String, Map<String, Object?>)>> loadRows(
    String fileUuid, {
    Set<String> skip = const {},
  }) => db.readTransaction((tx) async {
    final fid = await _rows.fidOf(tx, fileUuid);
    if (fid == null) return const [];
    return [
      for (final r in [
        ...await _rows.structure(tx, fid),
        ...await _rows.allCells(tx, fid),
      ])
        if (!skip.contains(r.$1)) r,
    ];
  });

  /// The structure of [fileUuid] (every row of a table that is not a cell
  /// table, parents' tables first) and the revision it is at, read in one
  /// transaction (viewport-first reopen, 06 §5.1).
  Future<RevStoredRows> loadStructure(String fileUuid) =>
      db.readTransaction((tx) async {
        final revision = await _revision(tx, fileUuid);
        final fid = await _rows.fidOf(tx, fileUuid);
        return RevStoredRows(
          revision,
          fid == null ? const [] : await _rows.structure(tx, fid),
        );
      });

  /// The cells (cellsByRow rows) of [scope] (sheet) in [rowKeys].
  Future<List<(String, Map<String, Object?>)>> loadScoped(
    String fileUuid,
    String scope,
    List<String> rowKeys,
  ) async => (await loadScopedAt(fileUuid, scope, rowKeys)).rows;

  /// [loadScoped] with the revision the rows are at (one transaction).
  Future<RevStoredRows> loadScopedAt(
    String fileUuid,
    String scope,
    List<String> rowKeys,
  ) => db.readTransaction((tx) async {
    final revision = await _revision(tx, fileUuid);
    final fid = await _rows.fidOf(tx, fileUuid);
    return RevStoredRows(
      revision,
      fid == null ? const [] : await _rows.scoped(tx, fid, scope, rowKeys),
    );
  });

  Future<int> _revision(SqliteReadContext tx, String fileUuid) async {
    final r = await tx.getOptional(
      'SELECT revision FROM rev_local_file WHERE file_uuid = ?',
      [fileUuid],
    );
    return (r?['revision'] as int?) ?? 0;
  }

  /// The stored row of ([table], [id]) of [fileUuid], or null.
  Future<Map<String, Object?>?> row(
    String fileUuid,
    String table,
    String id,
  ) async {
    final fid = await _rows.fidOf(db, fileUuid);
    return fid == null ? null : _rows.row(db, fid, table, id);
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
  Future<int> usageBytes() => RevDomainRows.bytes(db);

  /// Empties the cache (Settings › Clear), keeping nothing.
  Future<void> clearAll() => db.writeTransaction((tx) async {
    _filesWithRow.clear();
    await _rows.deleteAll(tx);
    for (final t in const [
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
