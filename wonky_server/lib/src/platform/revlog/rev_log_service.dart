import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/client.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart' show RevSchema, RevTable;

import '../common/actor.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../sharing/access_service.dart';
import 'headless_file_cache.dart';
import 'rev_binding.dart';
import 'rev_bus.dart';
import 'rev_file_state.dart';
import 'rev_hooks.dart';
import 'rev_sql.dart';
import 'rev_views.dart';

/// A committed op (RevLog spec 05 §3.1).
final class RevCommit {
  /// Creates the record.
  const RevCommit({
    required this.revision,
    required this.duplicate,
    required this.applied,
    required this.appliedEqualsSubmitted,
    required this.outcomeJson,
    required this.view,
  });

  /// The op's revision.
  final int revision;

  /// The op was committed before (idempotent resend).
  final bool duplicate;

  /// The applied form with `before` (null for a pruned duplicate).
  final List<RowChange>? applied;

  /// The applied form equals the submitted changes.
  final bool appliedEqualsSubmitted;

  /// Outcome JSON (04 §2.2), null when empty or pruned.
  final String? outcomeJson;

  /// The view other connections receive (null for duplicates).
  final RevOpView? view;
}

/// Who submits an op.
final class RevSubmitter {
  /// Creates the record.
  const RevSubmitter({
    required this.userId,
    required this.authUuid,
    this.sessionId,
    this.onBehalfOfSessionId,
  });

  /// A system change (title mirror, script builds).
  static const system = RevSubmitter(userId: null, authUuid: null);

  /// The submitter of [actor].
  factory RevSubmitter.of(Actor actor, {String? sessionId}) => RevSubmitter(
    userId: actor.userId,
    authUuid: actor.authUserId,
    sessionId: sessionId ?? actor.sessionId,
  );

  /// user_profile id.
  final int? userId;

  /// Auth user uuid.
  final UuidValue? authUuid;

  /// Committing connection or `server:<runId>`.
  final String? sessionId;

  /// MCP/assistant: the editor session it acted for.
  final String? onBehalfOfSessionId;
}

/// Result of [RevLogService.submitServerChange] (05 §8.1).
final class RevServerChangeResult {
  /// Creates the record.
  const RevServerChangeResult({
    required this.groupId,
    required this.fromRevision,
    required this.toRevision,
    required this.recordId,
    required this.commits,
  });

  /// The group of the op(s).
  final String groupId;

  /// First and last committed revision (equal for one op; 0 when empty).
  final int fromRevision;
  final int toRevision;

  /// The record id (when recorded or joined).
  final UuidValue? recordId;

  /// The commits.
  final List<RevCommit> commits;
}

/// The RevLog sequencer (RevLog spec 05 §3, §8).
abstract final class RevLogService {
  /// Limits (01 §4).
  static RevLimits limits = RevLimits.defaults;

  /// Max entries per outcome list (04 §2.2).
  static const outcomeCap = 500;

  /// Tests: called inside the transaction after the write, before commit.
  static Future<void> Function()? debugBeforeCommit;

  // ------------------------------------------------------------ decoding

  /// Decodes a client submit, checking sizes and the schema hash before any
  /// lock (05 §3.2 step 0).
  static ChangeSet decodeSubmit(RevBinding binding, RevSubmit m) {
    final gz = m.payloadGz;
    if (m.payload == null && gz == null) {
      throw RevRejection(RevRejectReason.invalidChange, 'empty payload');
    }
    final wireBytes = m.payload?.length ?? gz!.lengthInBytes;
    if (wireBytes > limits.maxMessageBytes) {
      throw RevRejection(RevRejectReason.tooLarge, 'message too large');
    }
    final RevPayload payload;
    try {
      final text = RevCodec.unpack(
        text: m.payload,
        gz: gz?.buffer.asUint8List(gz.offsetInBytes, gz.lengthInBytes),
      );
      if (text.length > limits.maxOpBytes) {
        throw RevRejection(RevRejectReason.tooLarge, 'op too large');
      }
      final json = (jsonDecode(text) as Map).cast<String, Object?>();
      final hash = json['s'];
      if (!acceptedHashes(binding).contains(hash)) {
        throw RevRejection(
          RevRejectReason.schemaMismatch,
          'The app is out of date: please reload.',
        );
      }
      payload = binding.codec.decode(json);
    } on RevRejection {
      rethrow;
    } on Object catch (e) {
      throw RevRejection(RevRejectReason.invalidChange, 'bad payload: $e');
    }
    return ChangeSet(
      clientOpId: m.clientOpId.uuid,
      baseRevision: m.baseRevision,
      changes: payload.changes,
      label: m.label,
      actorKind: m.actorKind.name,
      summary: payload.summary,
      detail: payload.detail,
      groupId: m.groupId,
      groupIndex: m.groupIndex,
      groupLast: m.groupLast,
      offline: m.offline,
      createdAt: m.createdAt,
    );
  }

  /// Schema hashes the server accepts (02 §4.3).
  static Set<String> acceptedHashes(RevBinding binding) => {
    binding.schema.hash,
    ...binding.schema.compatibleWith,
  };

  /// The reject code of [r].
  static RevRejectCode codeOf(RevRejection r) =>
      RevRejectCode.values.byName(r.reason.name);

  // -------------------------------------------------------------- submit

  /// Commits [cs] to the file of [state] (05 §3.2). Throws [RevRejection].
  static Future<RevCommit> submit(
    Session session, {
    required RevBinding binding,
    required RevFileState state,
    required ChangeSet cs,
    required RevSubmitter submitter,
    required Role connectionRole,
    UuidValue? recordId,
    bool serverChange = false,
    RevModelAccess? models,
  }) async {
    final fileId = state.fileId;
    final clientOpId = UuidValue.fromString(cs.clientOpId);

    // 1. Idempotency fast path.
    final dup = await _duplicate(session, binding, fileId, clientOpId);
    if (dup != null) return dup;

    // 2. Access, on every submit.
    // The item id is fixed per file: a registered state knows it (one round
    // trip less per op); purging is checked again under the lock (3.1).
    var itemId = state.itemId;
    if (itemId == null || state.purged) {
      final file = await RevFile.db.findById(session, fileId);
      if (file == null || file.purging) {
        throw RevRejection(
          RevRejectReason.notFound,
          'The file does not exist.',
        );
      }
      itemId = file.itemId;
    }
    final item = await DriveItem.db.findById(session, itemId);
    if (item == null) {
      throw RevRejection(RevRejectReason.notFound, 'The file does not exist.');
    }
    var role = connectionRole;
    if (submitter.userId != null) {
      final acl = await AccessService.effectiveRole(
        session,
        submitter.userId!,
        item,
      );
      if (acl == null) {
        throw RevRejection(RevRejectReason.forbidden, 'No access.');
      }
      if (acl < role) role = acl;
    }
    if (role < Role.editor && cs.actorKind != 'system') {
      throw RevRejection(
        RevRejectReason.forbiddenForRole,
        'You can only view this file.',
      );
    }
    if (item.trashedAt != null) {
      throw RevRejection(
        RevRejectReason.fileReadOnly,
        'The file is in the trash.',
      );
    }

    // 3. Under the file lock, one transaction. The headless model (05 §9)
    // is loaded only if the binding's checks need it (protections).
    final ownModels = models == null
        ? HeadlessModelAccess(session, binding, state.fileUuid)
        : null;
    final RevCommit commit;
    try {
      commit = await state.lock(
        () => session.db.transaction(
          (tx) => _commit(
            session,
            tx,
            binding: binding,
            state: state,
            cs: cs,
            clientOpId: clientOpId,
            submitter: submitter,
            role: role,
            item: item,
            recordId: recordId,
            serverChange: serverChange,
            models: models ?? ownModels,
          ),
        ),
      );
    } finally {
      ownModels?.release();
    }
    if (commit.duplicate || commit.view == null) return commit;
    // 4. After the commit, still in order: ring, bus.
    await state.lock(() async {
      state.advance(commit.view!);
      try {
        await RevBus.postOp(session, state.fileUuid, commit.view!);
      } on Object catch (e) {
        session.log(
          'Posting op ${commit.revision} of ${state.fileUuid.uuid} failed: $e',
          level: LogLevel.warning,
        );
      }
    });
    // 5. Hooks (debounced).
    RevHooks.kick(session.serverpod, binding, fileId);
    return commit;
  }

  static Future<RevCommit?> _duplicate(
    Session session,
    RevBinding binding,
    int fileId,
    UuidValue clientOpId, {
    Transaction? transaction,
  }) async {
    final op = await RevOp.db.findFirstRow(
      session,
      where: (t) => t.fileId.equals(fileId) & t.clientOpId.equals(clientOpId),
      transaction: transaction,
    );
    if (op == null) return null;
    final payload = op.payload;
    return RevCommit(
      revision: op.revision,
      duplicate: true,
      applied: payload == null
          ? null
          : RevViews.decodeStored(binding.codec, payload),
      appliedEqualsSubmitted: op.appliedEqualsSubmitted,
      outcomeJson: op.outcomeJson,
      view: null,
    );
  }

  static Future<RevCommit> _commit(
    Session session,
    Transaction tx, {
    required RevBinding binding,
    required RevFileState state,
    required ChangeSet cs,
    required UuidValue clientOpId,
    required RevSubmitter submitter,
    required Role role,
    required DriveItem item,
    required UuidValue? recordId,
    required bool serverChange,
    required RevModelAccess? models,
  }) async {
    final schema = binding.schema;
    final fileId = state.fileId;
    final sql = RevSql(schema, perSheetTables: binding.perSheetTables);
    final started = clock.now();

    // 3.1 Lock the file row.
    final locked = await session.db.unsafeQuery(
      'SELECT "headRevision", stats, purging FROM rev_file '
      'WHERE id = @f FOR UPDATE',
      parameters: QueryParameters.named({'f': fileId}),
      transaction: tx,
    );
    if (locked.isEmpty || locked.first[2] == true) {
      throw RevRejection(RevRejectReason.notFound, 'The file does not exist.');
    }
    final head = locked.first[0]! as int;
    final statsBefore = RevStats.parse(locked.first[1]! as String);
    if (cs.baseRevision > head) {
      throw RevRejection(
        RevRejectReason.unknownBase,
        'Base revision ${cs.baseRevision} is ahead of the server ($head).',
      );
    }
    // 3.2 Idempotency again (closes the race of concurrent resends).
    final dup = await _duplicate(
      session,
      binding,
      fileId,
      clientOpId,
      transaction: tx,
    );
    if (dup != null) return dup;
    // 3.3 Catch up.
    if (state.revision < head) await state.catchUp(session, transaction: tx);

    validateChangeSet(
      schema,
      cs,
      fromClient: !serverChange,
      isCreation: head == 0,
      fileUuid: state.fileUuid.uuid,
      limits: limits,
    );

    // 3.8 Creation title: the drive item's current name (04 §5).
    var changes = cs.changes;
    var titleAdjusted = false;
    final root = schema.root;
    changes = [
      for (final c in changes)
        if (c.table == root.name &&
            c.op == RowOp.insert &&
            c.columnsAfter[binding.rootTitleColumn] != item.name)
          () {
            titleAdjusted = true;
            return RowChange.insert(c.table, c.rowId, {
              ...c.columnsAfter,
              binding.rootTitleColumn: item.name,
            });
          }()
        else
          c,
    ];

    // 3.4 Prefetch: touched rows and the parents inserts/moves need.
    final ids = <String, Set<String>>{};
    for (final c in changes) {
      (ids[c.table] ??= {}).add(c.rowId);
      if (c.op == RowOp.delete) continue;
      final t = schema.table(c.table);
      for (final p in t.parents) {
        final v = c.columnsAfter[p.column];
        if (v is String) (ids[p.table] ??= {}).add(v);
      }
    }
    final stored = await sql.fetchByIds(
      session,
      ids,
      transaction: tx,
      forUpdate: true,
    );
    for (final s in stored.values) {
      if (s.fileId != fileId) {
        throw RevRejection(
          RevRejectReason.invalidChange,
          'The op references a row of another file.',
        );
      }
    }
    final store = RevPrefetchStore(schema, {
      for (final e in stored.entries) e.key: e.value.row,
    });
    final existed = {...stored.keys};
    final rowRevision = {
      for (final e in stored.entries) e.key: e.value.revision,
    };

    // 3.5 Apply in memory.
    final effective = cs.copyWith(changes: changes);
    final result = applyChangeSet(schema, store, effective);
    final applied = [...result.applied];
    final cascaded = [...result.cascaded];

    // 3.6 Cascade to stored descendants the op didn't list.
    var deleted = _deletedRows(applied);
    final known = {...existed, ...store.touched};
    final extra = <RowChange>[];
    while (deleted.isNotEmpty) {
      final kids = await sql.children(
        session,
        fileId,
        deleted,
        known,
        transaction: tx,
      );
      final next = <String, Map<String, Map<String, Object?>>>{};
      for (final (table, s) in kids) {
        final id = s.row[RowChange.idColumn]! as String;
        store.add(table, id, s.row);
        existed.add((table, id));
        store.remove(table, id);
        final del = RowChange.delete(table, id, s.row);
        extra.add(del);
        (next[table] ??= {})[id] = s.row;
      }
      deleted = next;
    }
    if (extra.isNotEmpty) {
      extra.sort(
        (a, b) => schema.rank(b.table).compareTo(schema.rank(a.table)),
      );
      final at = applied.indexWhere((c) => c.op == RowOp.delete);
      applied.insertAll(at < 0 ? applied.length : at, extra);
      cascaded.addAll(extra);
    }

    // 3.7 Attribute conflict candidates.
    final conflicts = await _attribute(
      session,
      tx,
      binding,
      fileId,
      result.candidates,
      rowRevision,
      submitter.authUuid,
    );

    // 3.9 Authorize.
    final statsAfter = binding.updateStats(statsBefore, applied);
    final appliedResult = ApplyResult(
      applied: applied,
      dropped: result.dropped,
      candidates: result.candidates,
      cascaded: cascaded,
      equalsSubmitted: result.equalsSubmitted,
    );
    await binding.authorize(
      session,
      tx,
      effective,
      appliedResult,
      RevAuthor(
        userId: submitter.userId,
        authUuid: submitter.authUuid,
        role: role,
        actorKind: cs.actorKind,
      ),
      statsAfter,
      models ?? const _NoModels(),
    );

    // 3.11 Write: deletes children first, then upserts parents first.
    final revision = head + 1;
    final finals = <(String, String)>{...store.touched};
    final deletes = <String, List<String>>{};
    final upserts = <String, List<Map<String, Object?>>>{};
    final inserts = <String, List<Map<String, Object?>>>{};
    for (final k in finals) {
      final row = store.row(k.$1, k.$2);
      if (row == null) {
        if (existed.contains(k)) (deletes[k.$1] ??= []).add(k.$2);
      } else {
        ((existed.contains(k) ? upserts : inserts)[k.$1] ??= []).add(row);
      }
    }
    final ranked = schema.tables.map((t) => t.name).toList()
      ..sort((a, b) => schema.rank(a).compareTo(schema.rank(b)));
    for (final t in ranked.reversed) {
      final list = deletes[t];
      if (list != null) {
        await sql.delete(session, fileId, t, list, transaction: tx);
      }
    }
    try {
      for (final t in ranked) {
        // Rows that did not exist: inserts (first: updated rows may point
        // at them); rows read above: upserts.
        for (final (list, fresh) in [(inserts[t], true), (upserts[t], false)]) {
          if (list == null) continue;
          await sql.upsert(
            session,
            fileId,
            revision,
            t,
            list,
            transaction: tx,
            fresh: fresh,
          );
        }
      }
    } on RevForeignRowException {
      throw RevRejection(
        RevRejectReason.invalidChange,
        'The op references a row of another file.',
      );
    }

    // 3.12 Log.
    final equals = result.equalsSubmitted && extra.isEmpty && !titleAdjusted;
    final outcome = _outcome(result.dropped, conflicts, cascaded);
    final summary =
        cs.summary ??
        (jsonDecode(binding.summarize(applied)) as Map).cast<String, Object?>();
    final now = clock.now().toUtc();
    final op = await RevOp.db.insertRow(
      session,
      RevOp(
        fileId: fileId,
        revision: revision,
        clientOpId: clientOpId,
        baseRevision: cs.baseRevision,
        authorId: submitter.userId,
        authorUuid: submitter.authUuid,
        sessionId: submitter.sessionId,
        onBehalfOfSessionId: submitter.onBehalfOfSessionId,
        actorKind: ActorKind.values.byName(cs.actorKind),
        label: cs.label,
        groupId: cs.groupId,
        groupIndex: cs.groupIndex,
        groupLast: cs.groupLast,
        recordId: recordId,
        offline: cs.offline,
        payload: RevViews.storePayload(binding.codec, applied),
        changeCount: applied.length,
        summaryJson: jsonEncode(summary),
        detailJson: cs.detail == null ? null : jsonEncode(cs.detail),
        outcomeJson: outcome,
        appliedEqualsSubmitted: equals,
        clientCreatedAt: cs.createdAt,
        committedAt: now,
      ),
      transaction: tx,
    );

    // 3.13 Head.
    await session.db.unsafeExecute(
      'UPDATE rev_file SET "headRevision" = @r, stats = @s, '
      '"contentCount" = @c, "schemaHash" = @h, "updatedAt" = @now '
      'WHERE id = @f',
      parameters: QueryParameters.named({
        'r': revision,
        's': statsAfter.encode(),
        'c': binding.contentCount(statsAfter),
        'h': schema.hash,
        'now': now,
        'f': fileId,
      }),
      transaction: tx,
    );
    await debugBeforeCommit?.call();

    final ms = clock.now().difference(started).inMilliseconds;
    session.log(
      'RevLog ${state.fileUuid.uuid} r$revision: ${applied.length} changes '
      'in $ms ms',
      level: ms > 200 ? LogLevel.warning : LogLevel.debug,
    );
    return RevCommit(
      revision: revision,
      duplicate: false,
      applied: applied,
      appliedEqualsSubmitted: equals,
      outcomeJson: outcome,
      view: RevViews.of(op, binding.codec, applied),
    );
  }

  static Map<String, Map<String, Map<String, Object?>>> _deletedRows(
    List<RowChange> applied,
  ) {
    final out = <String, Map<String, Map<String, Object?>>>{};
    for (final c in applied) {
      if (c.op == RowOp.delete) {
        (out[c.table] ??= {})[c.rowId] = c.columnsBefore;
      }
    }
    return out;
  }

  /// Attributes conflict candidates to the op that last wrote each field
  /// when that was another user (03 §4.5): reads ≤ 50 earlier ops per
  /// field, ≤ 500 fields.
  static Future<List<Map<String, Object?>>> _attribute(
    Session session,
    Transaction tx,
    RevBinding binding,
    int fileId,
    List<FieldConflict> candidates,
    Map<(String, String), int> rowRevision,
    UuidValue? author,
  ) async {
    if (candidates.isEmpty) return const [];
    final out = <Map<String, Object?>>[];
    final cache = <int, (UuidValue?, List<RowChange>)?>{};
    Future<(UuidValue?, List<RowChange>)?> opAt(int revision) async {
      if (cache.containsKey(revision)) return cache[revision];
      final op = await RevOp.db.findFirstRow(
        session,
        where: (t) => t.fileId.equals(fileId) & t.revision.equals(revision),
        transaction: tx,
      );
      final payload = op?.payload;
      return cache[revision] = payload == null
          ? null
          : (op!.authorUuid, RevViews.decodeStored(binding.codec, payload));
    }

    for (final c in candidates.take(outcomeCap)) {
      var rev = rowRevision[(c.table, c.rowId)];
      for (var i = 0; rev != null && rev > 0 && i < 50; i++, rev = rev - 1) {
        final op = await opAt(rev);
        if (op == null) break;
        final wrote = op.$2.any(
          (ch) =>
              ch.table == c.table &&
              ch.rowId == c.rowId &&
              ch.columnsAfter.containsKey(c.column),
        );
        if (!wrote) continue;
        if (op.$1 != null && op.$1 != author) {
          out.add({
            't': c.table,
            'id': Base62Uuid.encode(c.rowId),
            'col': c.column,
            'theirs': _jsonValue(c.theirs),
            'byUser': op.$1!.uuid,
            'byRev': rev,
          });
        }
        break;
      }
    }
    return out;
  }

  static Object? _jsonValue(Object? v) => switch (v) {
    DateTime() => v.toUtc().millisecondsSinceEpoch,
    Enum() => v.name,
    _ => v,
  };

  static String? _outcome(
    List<DroppedChange> dropped,
    List<Map<String, Object?>> conflicts,
    List<RowChange> cascaded,
  ) {
    if (dropped.isEmpty && conflicts.isEmpty && cascaded.isEmpty) return null;
    var truncated = false;
    List<T> cap<T>(List<T> l) {
      if (l.length <= outcomeCap) return l;
      truncated = true;
      return l.sublist(0, outcomeCap);
    }

    return jsonEncode({
      if (dropped.isNotEmpty)
        'dropped': [
          for (final d in cap(dropped))
            {
              't': d.change.table,
              'id': Base62Uuid.encode(d.change.rowId),
              'op': d.change.op.index,
              'reason': d.reason.name,
            },
        ],
      if (conflicts.isNotEmpty) 'conflicts': cap(conflicts),
      if (cascaded.isNotEmpty)
        'cascaded': [
          for (final c in cap(cascaded))
            {'t': c.table, 'id': Base62Uuid.encode(c.rowId)},
        ],
      'truncated': truncated,
    });
  }

  // ------------------------------------------------------ server changes

  /// Commits server-originated changes (05 §8.1): precomputed [changes], or
  /// [plan]ned on the headless model under the file lock (via
  /// [planOnModel], supplied by the headless cache). Chunked into a group.
  /// Server writers may pass `UuidValue`s, enums or local DateTimes in
  /// columns: values are brought to their in-memory form (uuid strings,
  /// UTC) per column, as a client's changes are by the codec.
  static List<RowChange> _normalized(
    RevSchema schema,
    List<RowChange> changes,
  ) {
    Map<String, Object?> norm(RevTable t, Map<String, Object?> m) => {
      for (final e in m.entries)
        e.key: switch (t.column(e.key)) {
          final c? => RevValues.normalize(c, e.value),
          null => e.value,
        },
    };
    return [
      for (final c in changes)
        if (schema.tryTable(c.table) case final t?)
          RowChange(
            table: c.table,
            rowId: c.rowId,
            op: c.op,
            columnsBefore: norm(t, c.columnsBefore),
            columnsAfter: norm(t, c.columnsAfter),
          )
        else
          c,
    ];
  }

  static Future<RevServerChangeResult> submitServerChange(
    Session session, {
    required RevBinding binding,
    required RevFileState state,
    required RevSubmitter submitter,
    required String actorKind,
    required String label,
    required List<RowChange> changes,
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
    UuidValue? recordId,
    String? groupId,
    String Function(int chunk)? clientOpIdOf,
    Role role = Role.owner,
    RevModelAccess? models,
    void Function(int done, int total)? onProgress,
  }) async {
    if (changes.isEmpty) {
      return RevServerChangeResult(
        groupId: groupId ?? const Uuid().v7(),
        fromRevision: 0,
        toRevision: 0,
        recordId: recordId,
        commits: const [],
      );
    }
    final ordered = parentsFirst(
      binding.schema,
      _normalized(binding.schema, changes),
    );
    final firstId = clientOpIdOf?.call(0) ?? const Uuid().v7();
    final cs = ChangeSet(
      clientOpId: firstId,
      baseRevision: state.revision,
      changes: ordered,
      label: label,
      actorKind: actorKind,
      summary:
          summary ??
          (jsonDecode(binding.summarize(ordered)) as Map)
              .cast<String, Object?>(),
      detail: detail,
      groupId: groupId,
    );
    var chunk = 0;
    final chunks = RevChunker.split(
      cs,
      binding.codec,
      () => clientOpIdOf?.call(++chunk) ?? const Uuid().v7(),
      limits: limits,
    );
    final commits = <RevCommit>[];
    var done = 0;
    for (final c in chunks) {
      final commit = await submit(
        session,
        binding: binding,
        state: state,
        cs: c.copyWith(baseRevision: state.revision),
        submitter: submitter,
        connectionRole: role,
        recordId: recordId,
        serverChange: true,
        models: models,
      );
      commits.add(commit);
      done += c.changes.length;
      onProgress?.call(done, ordered.length);
    }
    return RevServerChangeResult(
      groupId: chunks.first.groupId ?? chunks.first.clientOpId,
      fromRevision: commits.first.revision,
      toRevision: commits.last.revision,
      recordId: recordId,
      commits: commits,
    );
  }

  // ------------------------------------------------------------ creation

  /// Creates the `rev_file` of [item] with its hook state and commits
  /// [initialChanges] as revision 1… in the same transaction (RevLog spec
  /// 05 §8.3): nobody can connect before it commits, so the ops need no
  /// lock or bus, and a crash leaves either nothing or the whole file. With
  /// no initial changes the client's first op creates the rows
  /// (`initialize: false`). Idempotent per item.
  static Future<RevFile> createFile(
    Session session, {
    required RevBinding binding,
    required DriveItem item,
    required RevSubmitter submitter,
    List<RowChange> initialChanges = const [],
    String label = 'Create',
    String actorKind = 'system',
    Transaction? transaction,
  }) async {
    if (transaction == null) {
      final file = await session.db.transaction(
        (tx) => createFile(
          session,
          binding: binding,
          item: item,
          submitter: submitter,
          initialChanges: initialChanges,
          label: label,
          actorKind: actorKind,
          transaction: tx,
        ),
      );
      if (initialChanges.isNotEmpty) {
        RevHooks.kick(session.serverpod, binding, file.id!);
      }
      return file;
    }
    final tx = transaction;
    final existing = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(item.contentRef ?? item.uuid),
      transaction: tx,
    );
    if (existing != null) return existing;
    final now = clock.now().toUtc();
    var file = await RevFile.db.insertRow(
      session,
      RevFile(
        fileUuid: item.contentRef ?? item.uuid,
        kind: binding.kind,
        itemId: item.id!,
        schemaHash: binding.schema.hash,
        createdAt: now,
        updatedAt: now,
      ),
      transaction: tx,
    );
    await RevHookState.db.insertRow(
      session,
      RevHookState(
        fileId: file.id!,
        cursorsJson: RevHooks.initialCursors(binding),
        updatedAt: now,
      ),
      transaction: tx,
    );
    if (initialChanges.isEmpty) return file;
    final state = RevFileState.detached(file.fileUuid, file.id!, binding);
    final ordered = parentsFirst(binding.schema, initialChanges);
    var chunk = 0;
    final chunks = RevChunker.split(
      ChangeSet(
        clientOpId: const Uuid().v5(file.fileUuid.uuid, 'init:0'),
        baseRevision: 0,
        changes: ordered,
        label: label,
        actorKind: actorKind,
        summary: (jsonDecode(binding.summarize(ordered)) as Map)
            .cast<String, Object?>(),
      ),
      binding.codec,
      () => const Uuid().v5(file.fileUuid.uuid, 'init:${++chunk}'),
      limits: limits,
    );
    for (final c in chunks) {
      final commit = await _commit(
        session,
        tx,
        binding: binding,
        state: state,
        cs: c.copyWith(baseRevision: state.revision),
        clientOpId: UuidValue.fromString(c.clientOpId),
        submitter: submitter,
        role: Role.owner,
        item: item,
        recordId: null,
        serverChange: true,
        models: null,
      );
      state.revision = commit.revision;
    }
    file = (await RevFile.db.findById(session, file.id!, transaction: tx))!;
    return file;
  }

  // --------------------------------------------------------------- purge

  /// Deletes a file's rows and log before its drive item (05 §10.1).
  static Future<void> purgeFile(
    Session session,
    RevBinding binding,
    UuidValue fileUuid,
  ) async {
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null) return;
    await session.db.unsafeExecute(
      'UPDATE rev_file SET purging = true WHERE id = @f',
      parameters: QueryParameters.named({'f': file.id}),
    );
    await RevBus.purged(session, fileUuid);
    RevFileStates.evict(fileUuid);
    final scopes = await binding.perSheetScopes(session, file.id!);
    final tables = binding.schema.tables.toList()
      ..sort(
        (a, b) => binding.schema
            .rank(b.name)
            .compareTo(
              binding.schema.rank(a.name),
            ),
      );
    for (final t in tables) {
      if (binding.perSheetTables.contains(t.name)) {
        for (final MapEntry(key: col, value: values) in scopes.entries) {
          for (final v in values) {
            // Batches of 50,000 rows per statement.
            while (await session.db.unsafeExecute(
                  'DELETE FROM ${RevSql.q(t.name)} WHERE id IN (SELECT id '
                  'FROM ${RevSql.q(t.name)} WHERE ${RevSql.q(col)} = @s::uuid '
                  'LIMIT 50000)',
                  parameters: QueryParameters.named({'s': v}),
                ) >
                0) {}
          }
        }
      } else {
        await session.db.unsafeExecute(
          'DELETE FROM ${RevSql.q(t.name)} WHERE "fileId" = @f',
          parameters: QueryParameters.named({'f': file.id}),
        );
      }
    }
    await RevFile.db.deleteRow(session, file);
  }
}

final class _NoModels implements RevModelAccess {
  const _NoModels();

  @override
  Future<Object> atPrevious() =>
      throw StateError('No headless model access for this submit.');
}

/// Converts [role] to the wire role.
AccessRole revAccessRole(Role role) => role.access;
