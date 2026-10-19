import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:wonky_app/wonky_app.dart' show ConnectionKeeper;
import 'package:wonky_client/wonky_client.dart' as api;
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/client.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_ui/wonky_ui.dart'
    show SyncLogEntry, SyncState, SyncStatus;

import '../store/rev_local_store.dart';
import '../transport/rev_page_decoder.dart';
import '../transport/rev_transport.dart';

/// The model side of a [RevFileSync] (the app binding: workbook, deck).
abstract interface class RevModelPort {
  /// The model's current rows.
  CurrentRowReader get reader;

  /// Applies [changes] to the model as one batch from the server or a
  /// rebuild ([remote] true) or as loaded rows ([remote] false: pages,
  /// store loads).
  void apply(List<RowChange> changes, {required bool remote});

  /// Empties the model (a re-bootstrap of an open file).
  void reset();
}

/// How the app loads a file's cells (06 §5.2): it sees the structure, is
/// asked for the next block of cell rows until it has none, and hears
/// about readiness.
abstract interface class RevBootstrapPlan {
  /// The structure (every non-cell row) is applied to the model.
  void structureLoaded(List<(String, Map<String, Object?>)> structure);

  /// The next cell rows to load as (scope, row keys): viewport first, then
  /// the grid's requests, then the rest; null when every row is loaded.
  ///
  /// Called again while earlier blocks are still loading (06 §5.2: several
  /// pages in flight). Rows handed out before and not yet [cellsLoaded]
  /// should be skipped; rows that are repeated anyway are not requested
  /// twice, but then the loader waits for their page before asking again.
  (String, List<String>)? nextCells();

  /// The cells of [rowKeys] of [scope] are applied.
  void cellsLoaded(String scope, List<String> rowKeys);

  /// The model is usable (structure + first cells applied).
  void ready();

  /// Every row is loaded.
  void complete();
}

/// The outcome of an acked op (06 §6).
final class RevOutcome {
  /// Creates the record.
  const RevOutcome(this.revision, this.json, {required this.offline});

  /// The op's revision.
  final int revision;

  /// `{dropped, conflicts, cascaded, truncated}` (04 §2.2).
  final Map<String, Object?> json;

  /// The op was made offline.
  final bool offline;
}

/// A rejected group (06 §4.6).
final class RevGroupRejection {
  /// Creates the record.
  const RevGroupRejection(this.groupId, this.rejection, this.ops);

  /// The group (or the single op's id).
  final String groupId;

  /// Why.
  final RevRejection rejection;

  /// The removed ops.
  final List<ChangeSet> ops;
}

/// The RevLog connection of one open file (RevLog spec 06 §3–§5): the
/// [RevSyncCore] state machine with the store, the transport, the overlay
/// of unacknowledged changes over server state, and bootstrap pages.
final class RevFileSync implements RevSyncHost {
  /// Creates the connection of [fileUuid]; call [open].
  RevFileSync({
    required this.store,
    required this.transport,
    required this.keeper,
    required this.schema,
    required this.fileUuid,
    required this.tabId,
    required this.port,
    this.plan,
    this.keyPrefix = 'revlog',
    this.headless = false,
  }) : codec = RevCodec(schema, lenient: true),
       overlay = RevOverlay(schema);

  final RevLocalStore store;
  final RevTransport transport;
  final ConnectionKeeper keeper;
  final RevSchema schema;
  final String fileUuid;
  final String tabId;
  final RevModelPort port;
  final RevBootstrapPlan? plan;
  final String keyPrefix;

  /// Background sync of a closed file (06 §7.3): no model rows are loaded
  /// and no pages are fetched; acks and remote ops only update the
  /// outbox, and a needed bootstrap just invalidates the cache.
  final bool headless;
  final RevCodec codec;
  final RevOverlay overlay;

  late final RevSyncCore core;

  /// The role the server reported.
  final ValueNotifier<api.AccessRole?> role = ValueNotifier(null);

  /// The sync indicator.
  final ValueNotifier<SyncStatus> status = ValueNotifier(
    const SyncStatus(state: SyncState.connecting),
  );

  /// Session-level failures (no access, deleted, update required).
  final ValueNotifier<api.RevRejected?> fatal = ValueNotifier(null);

  final _history = StreamController<RevOpMeta>.broadcast();
  final _outcomes = StreamController<RevOutcome>.broadcast();
  final _rejections = StreamController<RevGroupRejection>.broadcast();
  final List<SyncLogEntry> _log = [];

  /// Metadata of every op applied (remote and own acked ones).
  Stream<RevOpMeta> get history => _history.stream;

  /// Outcomes of this tab's acked ops.
  Stream<RevOutcome> get outcomes => _outcomes.stream;

  /// Rejected groups.
  Stream<RevGroupRejection> get rejections => _rejections.stream;

  /// Stats of the last RevInit (02 §1.1).
  Map<String, Object?> stats = const {};

  StreamController<api.RevClientMessage>? _input;
  Future<void> _storeChain = Future.value();
  Timer? _tick;
  bool _disposed = false;
  final List<Completer<void>> _syncWaiters = [];

  String get _key => '$keyPrefix:$fileUuid';

  void _log_(String message, {bool isError = false}) {
    _log.add(SyncLogEntry(at: clock.now(), message: message, isError: isError));
    if (_log.length > 50) _log.removeAt(0);
  }

  /// Runs store writes strictly in order.
  Future<void> _store(Future<void> Function() write) {
    // A later page must not join a batch queued before this write.
    _pageBatch = null;
    final next = _storeChain.then((_) => write()).catchError((Object e) {
      _log_('Saving locally failed: $e', isError: true);
      _setStatus(error: '$e');
    });
    _storeChain = next;
    return next;
  }

  /// Completes when every store write so far is done.
  Future<void> whenStored() => _storeChain;

  // ------------------------------------------------------------- opening

  /// Loads the file from the store (server state + this tab's outbox on
  /// top) and connects. Returns whether rows were loaded from the store
  /// (the model is usable offline).
  Future<bool> open() async {
    final local = await store.loadFile(fileUuid);
    final stored = await store.outbox(fileUuid);
    final mine = [
      for (final s in stored)
        if (s.tabId == tabId) s.op,
    ];
    var known = 0;
    var loaded = false;
    var streaming = false;
    if (headless) {
      known = local?.revision ?? 0;
    } else if (local != null && local.complete && local.revision > 0) {
      known = local.revision;
      loaded = true;
      if (plan != null && _cellTable != null) {
        // Viewport-first, like a cold open (06 §5.1): the structure and
        // the viewport's cells, the outbox on top, ready; the rest of the
        // cells stream in from the cache after connecting.
        await _openFromCache(mine);
        streaming = true;
      } else {
        _loadRows(await store.loadRows(fileUuid));
        _applyOutbox(mine);
      }
    } else if (local != null && local.revision > 0) {
      // A partial cache: reload it from the server (the outbox stays).
      await store.resetServerState(fileUuid);
    }
    if (!loaded) _applyOutbox(mine);
    await store.touchFile(fileUuid, opened: true);
    core = RevSyncCore(
      host: this,
      codec: codec,
      newId: () => const Uuid().v7(),
      serverRevision: known,
      restoredOutbox: mine,
    );
    // Restored ops are already durable.
    core.markDurable(mine.map((o) => o.clientOpId));
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_disposed) core.tick();
    });
    keeper.keep<api.RevServerMessage>(
      _key,
      _openStream,
      _onMessage,
      onError: (Object e) => _log_('Connection failed: $e', isError: true),
    );
    keeper.connectivity.addListener(_onConnectivity);
    _setStatus();
    if (streaming) unawaited(_streamFromCache(++_cacheRun));
    return loaded || mine.isNotEmpty;
  }

  /// The table whose rows load per sheet row (Sheets cells), or null.
  late final RevTable? _cellTable = schema.tables
      .where(
        (t) => t.coverage == RevCoverage.cellsByRow && t.parents.length >= 2,
      )
      .firstOrNull;

  /// Applies stored rows to the model as loaded rows.
  void _loadRows(List<(String, Map<String, Object?>)> rows) =>
      port.apply([for (final (t, r) in rows) _insertOf(t, r)], remote: false);

  /// The insert of a loaded full row (it holds its `id` already, as
  /// `RowChange.insert` would add it; nothing changes the map any more).
  static RowChange _insertOf(String table, Map<String, Object?> row) =>
      RowChange.loaded(table, row);

  /// Applies this tab's restored outbox on top of the model (03 §7): the
  /// shadow of each touched row is its server version, i.e. the model's
  /// row before the outbox (null for rows not loaded yet; loading them
  /// seeds the shadow again).
  void _applyOutbox(List<ChangeSet> mine) {
    for (final op in mine) {
      for (final c in op.changes) {
        if (!overlay.isShadowed(c.table, c.rowId)) {
          overlay.seed(
            c.table,
            c.rowId,
            port.reader.currentColumns(c.table, c.rowId),
          );
        }
      }
      port.apply(op.changes, remote: false);
    }
  }

  // ------------------------------------------------- reopen from the cache

  /// Cells are streaming in from the cache (06 §5.1): ops processed
  /// meanwhile are buffered for the rows not loaded yet, as during a
  /// bootstrap.
  bool _streaming = false;
  int _cacheRun = 0;

  /// Sheet rows per store read while streaming from the cache (a read and
  /// its model batch stay short, so the UI and store writes keep flowing).
  static const _cacheChunk = 250;

  /// Tests: awaited after cells were read from the cache while streaming,
  /// before they are applied (ops can arrive in between).
  @visibleForTesting
  Future<void> Function(String scope, List<String> rowKeys)? cachedCellsRead;

  /// Opens a complete cache viewport-first: the structure and the first
  /// block of cells the [plan] asks for, then the outbox on top, then
  /// ready. The rest streams in from [_streamFromCache].
  Future<void> _openFromCache(List<ChangeSet> mine) async {
    final plan = this.plan!;
    _streaming = true;
    final structure = await store.loadStructure(fileUuid);
    _loadRows(structure.rows);
    plan.structureLoaded(structure.rows);
    final first = plan.nextCells();
    if (first != null) {
      final (scope, keys) = first;
      for (var i = 0; i < keys.length; i += _cacheChunk) {
        final chunk = keys.sublist(i, (i + _cacheChunk).clamp(0, keys.length));
        _applyCached(
          await store.loadScopedAt(fileUuid, scope, chunk),
          scope,
          chunk,
          mine,
        );
        plan.cellsLoaded(scope, chunk);
      }
    }
    _applyOutbox(mine);
    plan.ready();
  }

  bool _cacheStopped(int run) =>
      _disposed || run != _cacheRun || _bootstrapping;

  /// Loads the cells the [plan] asks for from the cache until every row
  /// is loaded (06 §5.2 order: the grid's requests, the active sheet, the
  /// other sheets). Stops when a bootstrap from the server takes over.
  Future<void> _streamFromCache(int run) async {
    final plan = this.plan!;
    try {
      while (!_cacheStopped(run)) {
        final next = plan.nextCells();
        if (next == null) {
          _streaming = false;
          _buffer.clear();
          plan.complete();
          _setStatus();
          return;
        }
        final (scope, keys) = next;
        for (var i = 0; i < keys.length; i += _cacheChunk) {
          final chunk = keys.sublist(
            i,
            (i + _cacheChunk).clamp(0, keys.length),
          );
          final rows = await store.loadScopedAt(fileUuid, scope, chunk);
          await cachedCellsRead?.call(scope, chunk);
          if (_cacheStopped(run)) return;
          _applyCached(rows, scope, chunk, core.outbox);
          plan.cellsLoaded(scope, chunk);
        }
      }
    } on Object catch (e) {
      if (_cacheStopped(run)) return;
      _log_('Loading from this device failed: $e', isError: true);
      _setStatus(error: '$e');
    } finally {
      // Done, failed or replaced by a bootstrap from the server (which
      // buffers ops itself and loads the rows again).
      if (run == _cacheRun) _streaming = false;
    }
  }

  /// Applies cells read from the cache for the sheet rows [keys] of
  /// [scope], exactly as a page (06 §5.3): the stored rows are server
  /// state at `stored.revision`; the buffered ops newer than that are
  /// replayed on them; rows the [outbox] touches are rebuilt through the
  /// overlay from that server state.
  void _applyCached(
    RevStoredRows stored,
    String scope,
    List<String> keys,
    List<ChangeSet> outbox,
  ) {
    final table = _cellTable!;
    final scopeCol = table.parents[0].column;
    final keyCol = table.parents[1].column;
    final keySet = keys.toSet();
    // Server state of the loaded rows: stored rows + newer buffered ops.
    final server = MapRowStore();
    final touched = <(String, String)>{};
    for (final (t, r) in stored.rows) {
      final id = r[RowChange.idColumn]! as String;
      server.put(t, id, r);
      touched.add((t, id));
    }
    for (final (rev, changes) in _buffer) {
      if (rev <= stored.revision) continue;
      for (final c in changes) {
        if (c.table != table.name) continue;
        final k = (c.table, c.rowId);
        final belongs = c.op == RowOp.insert
            ? c.columnsAfter[scopeCol] == scope &&
                  keySet.contains(c.columnsAfter[keyCol])
            : touched.contains(k);
        if (!belongs) continue;
        replayApplied(server, [c]);
        touched.add(k);
      }
    }
    final outboxKeys = <(String, String)>{
      for (final op in outbox)
        for (final c in op.changes) (c.table, c.rowId),
    };
    final load = <RowChange>[];
    final seeded = <(String, String)>{};
    for (final k in touched) {
      final row = server.row(k.$1, k.$2);
      if (outboxKeys.contains(k)) {
        overlay.seed(k.$1, k.$2, row);
        seeded.add(k);
      } else if (row != null) {
        load.add(_insertOf(k.$1, row));
      } else if (port.reader.currentColumns(k.$1, k.$2) != null) {
        load.add(RowChange(table: k.$1, rowId: k.$2, op: RowOp.delete));
      }
    }
    port.apply(load, remote: false);
    if (seeded.isNotEmpty) {
      final patch = overlay.rebuild(seeded, outbox, port.reader);
      if (patch.isNotEmpty) port.apply(patch, remote: true);
    }
  }

  Stream<api.RevServerMessage> _openStream() {
    core.disconnected();
    final input = StreamController<api.RevClientMessage>();
    unawaited(_input?.close());
    _input = input;
    core.connectedStream();
    _setStatus();
    return transport.connect(
      api.UuidValue.fromString(fileUuid),
      core.serverRevision,
      tabId,
      input.stream,
    );
  }

  void _onConnectivity() {
    if (!keeper.online) core.disconnected();
    _setStatus();
  }

  // -------------------------------------------------------- local writes

  /// Call before applying [changes] to the model: remembers the server
  /// version of rows the outbox didn't touch yet.
  void beforeLocal(List<RowChange> changes) =>
      overlay.captureLocal(changes, port.reader);

  /// Records local [changes] (already applied to the model).
  List<ChangeSet> submit(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
    String? groupId,
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
  }) {
    final ops = core.submitLocal(
      changes,
      label: label,
      actorKind: actorKind,
      groupId: groupId,
      summary: summary,
      detail: detail,
    );
    _setStatus();
    return ops;
  }

  /// Completes when this tab's outbox is empty (every change acked).
  Future<void> whenSynced({Duration? timeout}) {
    if (core.isSynchronized) return Future.value();
    final c = Completer<void>();
    _syncWaiters.add(c);
    final f = c.future;
    return timeout == null ? f : f.timeout(timeout);
  }

  // --------------------------------------------------- RevSyncHost: I/O

  @override
  void persistOutbox(List<ChangeSet> outbox) {
    final ids = [for (final o in outbox) o.clientOpId];
    unawaited(
      _store(() async {
        await store.replaceOutbox(fileUuid, tabId, outbox);
        if (!_disposed) core.markDurable(ids);
      }),
    );
  }

  @override
  void sendOp(ChangeSet op) {
    final input = _input;
    if (input == null || input.isClosed) return;
    final text = codec.encodeText(
      op.changes,
      summary: op.summary,
      detail: op.detail,
    );
    final packed = RevCodec.pack(text);
    input.add(
      api.RevSubmit(
        clientOpId: api.UuidValue.fromString(op.clientOpId),
        baseRevision: op.baseRevision,
        payload: packed.text,
        payloadGz: packed.gz == null ? null : ByteData.sublistView(packed.gz!),
        label: op.label,
        actorKind: api.ActorKind.values.byName(op.actorKind),
        groupId: op.groupId,
        groupIndex: op.groupIndex,
        groupLast: op.groupLast,
        offline: op.offline,
        createdAt: op.createdAt,
      ),
    );
  }

  @override
  void requestOps(int from, int to) {
    final input = _input;
    if (input == null || input.isClosed) return;
    input.add(api.RevRequestOps(fromRevision: from, toRevision: to));
  }

  // ------------------------------------------------ RevSyncHost: apply

  RevOpMeta _meta(RevOpIn op) => RevOpMeta(
    revision: op.revision,
    authorUuid: op.authorUuid,
    sessionId: op.sessionId,
    actorKind: op.actorKind,
    label: op.label,
    groupId: op.groupId,
    groupLast: op.groupLast,
    recordId: op.recordId,
    summary: op.summary,
    detail: op.detail,
    offline: op.offline,
    committedAt: op.committedAt,
  );

  @override
  void applyRemote(RevOpIn op) {
    final patch = overlay.remote(op.applied, core.outbox, port.reader);
    port.apply(patch, remote: true);
    if (_bootstrapping || _streaming) _buffer.add((op.revision, op.applied));
    final meta = _meta(op);
    unawaited(
      _store(
        () => store.applyServerOp(
          fileUuid,
          op.revision,
          op.applied,
          meta,
          domain: !_bootstrapping || _canWriteDomain,
        ),
      ),
    );
    _history.add(meta);
    _setStatus();
  }

  @override
  void applyAck(ChangeSet op, RevAckIn ack, List<RowChange> applied) {
    final patch = overlay.acked(op, applied, core.outbox, port.reader);
    if (patch.isNotEmpty) port.apply(patch, remote: true);
    if (_bootstrapping || _streaming) _buffer.add((ack.revision, applied));
    final meta = RevOpMeta(
      revision: ack.revision,
      authorUuid: null,
      sessionId: 'tab:$tabId',
      actorKind: op.actorKind,
      label: op.label,
      groupId: op.groupId,
      groupLast: op.groupLast,
      summary: op.summary,
      detail: op.detail,
      offline: op.offline,
      committedAt: clock.now().toUtc(),
    );
    unawaited(
      _store(
        () => store.applyServerOp(
          fileUuid,
          ack.revision,
          applied,
          meta,
          ackedClientOpId: op.clientOpId,
          domain: !_bootstrapping || _canWriteDomain,
        ),
      ),
    );
    _history.add(meta);
    final outcome = ack.outcome;
    if (outcome != null && outcome.isNotEmpty) {
      _outcomes.add(RevOutcome(ack.revision, outcome, offline: op.offline));
      unawaited(
        _store(
          () => store.addOutcome(fileUuid, ack.revision, jsonEncode(outcome)),
        ),
      );
    }
    _setStatus();
  }

  @override
  void applyRejected(List<ChangeSet> ops, RevRejection rejection) {
    final patch = overlay.rejected(ops, core.outbox, port.reader);
    if (patch.isNotEmpty) port.apply(patch, remote: true);
    final group = ops.first.groupId ?? ops.first.clientOpId;
    _log_(
      'Change rejected (${rejection.reason.name}): ${rejection.message}',
      isError: true,
    );
    _rejections.add(RevGroupRejection(group, rejection, ops));
    _setStatus();
  }

  // ---------------------------------------------------------- messages

  RevOpIn _opIn(api.RevOpView v) {
    final payload = RevCodec.unpack(
      text: v.payload,
      gz: v.payloadGz?.buffer.asUint8List(
        v.payloadGz!.offsetInBytes,
        v.payloadGz!.lengthInBytes,
      ),
    );
    return RevOpIn(
      revision: v.revision,
      clientOpId: v.clientOpId.uuid,
      applied: codec.decodeText(payload).changes,
      authorUuid: v.authorUuid?.uuid,
      sessionId: v.authorSessionId,
      actorKind: v.actorKind.name,
      label: v.label,
      summary: _json(v.summaryJson),
      detail: _json(v.detailJson),
      offline: v.offline,
      groupId: v.groupId,
      groupIndex: v.groupIndex,
      groupLast: v.groupLast,
      recordId: v.recordId?.uuid,
      onBehalfOfSessionId: v.onBehalfOfSessionId,
      outcome: _json(v.outcomeJson),
      committedAt: v.committedAt,
    );
  }

  static Map<String, Object?>? _json(String? s) =>
      s == null || s.isEmpty ? null : (jsonDecode(s) as Map).cast();

  void _onMessage(api.RevServerMessage m) {
    if (_disposed) return;
    switch (m) {
      case api.RevInit():
        role.value = m.role;
        stats = _json(m.stats) ?? const {};
        fatal.value = null;
        core.init(
          m.revision,
          ops: m.ops?.map(_opIn).toList(),
          more: m.more,
          bootstrap: m.bootstrap,
        );
        _log_('Connected at revision ${m.revision}.');
      case api.RevAck():
        final applied = m.applied ?? _gunzip(m.appliedGz);
        core.ack(
          RevAckIn(
            clientOpId: m.clientOpId.uuid,
            revision: m.revision,
            applied: applied == null ? null : codec.decodeText(applied).changes,
            outcome: _json(m.outcome),
            duplicate: m.duplicate,
          ),
        );
      case api.RevRemoteOp():
        core.remoteOp(_opIn(m.op));
      case api.RevRejected():
        final id = m.clientOpId;
        final rejection = RevRejection(
          RevRejectReason.values.byName(m.code.name),
          m.message,
          details: _json(m.detailsJson),
        );
        if (id != null) {
          core.rejected(id.uuid, rejection);
        } else {
          fatal.value = m;
          _log_('Session closed: ${m.message}', isError: true);
        }
      case api.RevRoleChanged():
        role.value = m.role;
      case api.RevResync():
        core.bootstrapped(core.serverRevision);
        bootstrap(core.serverRevision);
      case api.RevPong():
        core.headSeen(m.headRevision);
    }
    _setStatus();
  }

  static String? _gunzip(ByteData? gz) => gz == null
      ? null
      : RevCodec.gunzip(
          gz.buffer.asUint8List(gz.offsetInBytes, gz.lengthInBytes),
        );

  // ------------------------------------------------------------ bootstrap

  bool _bootstrapping = false;
  bool _canWriteDomain = false;
  final List<(int, List<RowChange>)> _buffer = [];
  int _bootstrapRun = 0;

  /// Whether pages, or the cells of a reopened cache, are loading.
  bool get bootstrapping => _bootstrapping || _streaming;

  @override
  void bootstrap(int revision) {
    if (headless) {
      // The next open re-bootstraps (06 §7.3 step 3).
      _bootstrapping = true;
      _canWriteDomain = false;
      unawaited(_store(() => store.resetServerState(fileUuid)));
      return;
    }
    final run = ++_bootstrapRun;
    unawaited(_bootstrap(run));
  }

  Future<void> _bootstrap(int run) async {
    _bootstrapping = true;
    _canWriteDomain = false;
    _buffer.clear();
    final reloading = core.serverRevision > 0 && _loadedOnce;
    if (reloading) port.reset();
    try {
      await _store(() => store.resetServerState(fileUuid));
      final file = api.UuidValue.fromString(fileUuid);
      bool stale() => run != _bootstrapRun || _disposed;
      final structure = <RevPageRow>[];
      String? cursor;
      var excluded = <String>[];
      do {
        final (page, rows) = await _fetchPage(
          file,
          api.RevPageRequest(
            kind: api.RevPageKind.structure,
            cursor: cursor,
            maxRows: 20000,
            format: RevPageCodec.version,
          ),
        );
        if (stale()) return;
        if (cursor == null) excluded = page.excludedTables;
        await _applyPage(page, rows);
        structure.addAll(rows);
        cursor = page.nextCursor;
      } while (cursor != null);
      // Tables too large for structure pages: two at a time (06 §5.2),
      // each along its cursor.
      final tables = [...excluded];
      Future<void> rowsWorker() async {
        while (tables.isNotEmpty && !stale()) {
          final table = tables.removeAt(0);
          String? c;
          do {
            final (page, rows) = await _fetchPage(
              file,
              api.RevPageRequest(
                kind: api.RevPageKind.rows,
                table: table,
                cursor: c,
                maxRows: 20000,
                format: RevPageCodec.version,
              ),
            );
            if (stale()) return;
            await _applyPage(page, rows);
            structure.addAll(rows);
            c = page.nextCursor;
          } while (c != null);
        }
      }

      await Future.wait([rowsWorker(), rowsWorker()]);
      if (stale()) return;
      // Cells (cellsByRow tables), in the order the app asks for.
      final plan = this.plan;
      plan?.structureLoaded(structure);
      final cellTable = schema.tables
          .where((t) => t.coverage == RevCoverage.cellsByRow)
          .firstOrNull;
      if (cellTable != null && plan != null) {
        await _loadCells(file, plan, stale);
        if (stale()) return;
      } else {
        plan?.ready();
      }
      _canWriteDomain = true;
      _bootstrapping = false;
      _buffer.clear();
      _loadedOnce = true;
      final revision = core.serverRevision;
      await _store(
        () => store.markComplete(fileUuid, complete: true, revision: revision),
      );
      plan?.complete();
    } on Object catch (e) {
      if (run != _bootstrapRun) return;
      _bootstrapping = false;
      _log_('Loading failed: $e', isError: true);
      _setStatus(error: '$e');
      rethrow;
    }
  }

  bool _loadedOnce = false;

  /// Cell pages requested at once (06 §5.2): fetching and decoding (off
  /// the UI isolate) overlap with applying earlier pages.
  static int maxPagesInFlight = 3;

  /// Sheet rows per cell page.
  static const _pageRows = 500;

  /// Fewest sheet rows per cell page when a block is split over the free
  /// request slots.
  static int minPageRows = 100;

  /// A page with its rows, decoded off the UI isolate.
  Future<(api.RevPage, List<RevPageRow>)> _fetchPage(
    api.UuidValue file,
    api.RevPageRequest request,
  ) async {
    final page = await transport.page(file, request);
    final body = page.body.buffer.asUint8List(
      page.body.offsetInBytes,
      page.body.lengthInBytes,
    );
    return (page, await RevPageDecoder.decode(schema, body));
  }

  /// Loads the cells [plan] asks for with up to [maxPagesInFlight] pages
  /// in flight, applying them in request order. A block is split over the
  /// free slots; rows the plan hands out again while their page is in
  /// flight are not requested twice (the loop waits for that page).
  /// `ready` follows the plan's first block.
  Future<void> _loadCells(
    api.UuidValue file,
    RevBootstrapPlan plan,
    bool Function() stale,
  ) async {
    final inFlight = Queue<_CellFetch>();
    final requested = <String>{};
    var block = 0;
    var ready = false;
    try {
      while (true) {
        while (inFlight.length < maxPagesInFlight) {
          final next = plan.nextCells();
          if (next == null) break;
          final (scope, keys) = next;
          final fresh = [
            for (final k in keys)
              if (requested.add('$scope:$k')) k,
          ];
          if (fresh.isEmpty) break;
          final slots = maxPagesInFlight - inFlight.length;
          final size = ((fresh.length + slots - 1) ~/ slots).clamp(
            minPageRows,
            _pageRows,
          );
          for (var i = 0; i < fresh.length; i += size) {
            final chunk = fresh.sublist(i, (i + size).clamp(0, fresh.length));
            final future = _fetchPage(
              file,
              api.RevPageRequest(
                kind: api.RevPageKind.cells,
                sheetId: api.UuidValue.fromString(scope),
                rowIds: [for (final r in chunk) api.UuidValue.fromString(r)],
                maxRows: chunk.length,
                format: RevPageCodec.version,
              ),
            )..ignore();
            inFlight.add(_CellFetch(scope, chunk, block, future));
          }
          block++;
        }
        if (inFlight.isEmpty) break;
        final f = inFlight.removeFirst();
        final (page, rows) = await f.page;
        if (stale()) return;
        await _applyPage(page, rows);
        plan.cellsLoaded(f.scope, f.rows);
        for (final k in f.rows) {
          requested.remove('${f.scope}:$k');
        }
        if (!ready && !inFlight.any((p) => p.block == 0)) {
          ready = true;
          plan.ready();
        }
      }
      if (!ready) plan.ready();
    } finally {
      for (final f in inFlight) {
        f.page.ignore();
      }
    }
  }

  /// Page rows queued for the store and not written yet, and the page
  /// writes in flight (oldest first).
  int _pendingPageRows = 0;
  static const _maxPendingPageRows = 120000;
  final Queue<Future<void>> _pageWrites = Queue();

  /// Waits while too many page rows wait for the store (memory): for the
  /// oldest page writes, not for the whole chain.
  Future<void> _pageBackpressure() async {
    while (_pendingPageRows > _maxPendingPageRows && _pageWrites.isNotEmpty) {
      await _pageWrites.first;
    }
  }

  /// Pages queued in the last store write, which hasn't started yet: the
  /// next page joins it (one transaction and a few statements for all the
  /// pages that arrived while the store was busy).
  List<RevPageWrite>? _pageBatch;

  void _queuePageWrite(RevPageWrite write) {
    final pending = write.rows.length + write.replay.length;
    _pendingPageRows += pending;
    final open = _pageBatch;
    if (open != null) {
      open.add(write);
      return;
    }
    final batch = [write];
    late final Future<void> done;
    done = _store(() async {
      if (identical(_pageBatch, batch)) _pageBatch = null;
      try {
        await store.applyPages(fileUuid, batch);
      } finally {
        for (final w in batch) {
          _pendingPageRows -= w.rows.length + w.replay.length;
        }
        _pageWrites.remove(done);
      }
    });
    _pageWrites.add(done);
    _pageBatch = batch;
  }

  /// Applies a page and its decoded [rows] to the store and the model;
  /// returns the rows.
  Future<List<(String, Map<String, Object?>)>> _applyPage(
    api.RevPage page,
    List<RevPageRow> rows,
  ) async {
    final rp = page.revision;
    bool covered(RowChange c) {
      final t = schema.tryTable(c.table);
      if (t == null) return false;
      for (final key in page.coverage) {
        final parts = key.split(':');
        if (parts.first == 'tbl' && parts[1] == c.table) {
          final from = parts[2], to = parts[3];
          if ((from == '-' || c.rowId.compareTo(from) > 0) &&
              (to == '+' || c.rowId.compareTo(to) <= 0)) {
            return true;
          }
        } else if (parts.first == 'row' &&
            t.coverage == RevCoverage.cellsByRow) {
          final cols = c.op == RowOp.delete
              ? port.reader.currentColumns(c.table, c.rowId)
              : {
                  ...?port.reader.currentColumns(c.table, c.rowId),
                  ...c.columnsAfter,
                };
          if (cols == null) continue;
          if (cols[t.parents.first.column] == parts[1] &&
              cols[t.parents[1].column] == parts[2]) {
            return true;
          }
        }
      }
      return false;
    }

    final replay = <RowChange>[
      for (final (rev, changes) in _buffer)
        if (rev > rp)
          for (final c in changes)
            if (covered(c)) c,
    ];
    // The store write is queued in order but not awaited: the model (and
    // ready, P6) doesn't wait for SQLite. Pages wait only when the writes
    // fall far behind (memory).
    await _pageBackpressure();

    _queuePageWrite(
      RevPageWrite(
        revision: rp,
        coverage: page.coverage,
        rows: rows,
        replay: replay,
      ),
    );
    // Model: server rows, the newer buffered changes, then the outbox.
    final outboxKeys = <(String, String)>{
      for (final op in core.outbox)
        for (final c in op.changes) (c.table, c.rowId),
    };
    port.apply([
      for (final (t, r) in rows)
        if (!outboxKeys.contains((t, r[RowChange.idColumn]))) _insertOf(t, r),
    ], remote: false);
    if (replay.isNotEmpty) port.apply(replay, remote: true);
    final pageKeys = {
      for (final (t, r) in rows)
        if (outboxKeys.contains((t, r[RowChange.idColumn])))
          (t, r[RowChange.idColumn]! as String),
    };
    if (pageKeys.isNotEmpty) {
      // The server version of those rows: the page's, with the newer
      // buffered changes on top (as the store has them).
      final server = MapRowStore();
      for (final (t, r) in rows) {
        final id = r[RowChange.idColumn]! as String;
        if (pageKeys.contains((t, id))) server.put(t, id, r);
      }
      replayApplied(server, [
        for (final c in replay)
          if (pageKeys.contains((c.table, c.rowId))) c,
      ]);
      for (final (t, id) in pageKeys) {
        overlay.seed(t, id, server.row(t, id));
      }

      final patch = overlay.rebuild(pageKeys, core.outbox, port.reader);
      if (patch.isNotEmpty) port.apply(patch, remote: true);
    }
    return rows;
  }

  // -------------------------------------------------------------- status

  void _setStatus({String? error}) {
    if (_disposed) return;
    final pending = core.pendingChanges;
    final SyncState state;
    if (error != null) {
      state = SyncState.error;
    } else if (!keeper.online) {
      state = SyncState.offline;
    } else if (!core.connected) {
      state = _loadedOnce || core.serverRevision > 0
          ? SyncState.reconnecting
          : SyncState.connecting;
    } else if (pending > 0) {
      state = SyncState.saving;
    } else {
      state = SyncState.saved;
    }
    status.value = SyncStatus(
      state: state,
      pendingChanges: pending,
      reconnectAt: keeper.nextAttemptAt,
      error: error,
      log: List.unmodifiable(_log),
    );
    if (core.isSynchronized && _syncWaiters.isNotEmpty) {
      for (final w in _syncWaiters) {
        if (!w.isCompleted) w.complete();
      }
      _syncWaiters.clear();
    }
  }

  /// Reconnects now (the sync status "Retry").
  void retry() => keeper.reconnectNow(_key);

  /// Closes the connection (flushes the store). Idempotent: a background
  /// sync and the client's close may both dispose it.
  Future<void> dispose() => _disposing ??= _dispose();

  Future<void>? _disposing;

  Future<void> _dispose() async {
    _disposed = true;
    _tick?.cancel();
    keeper.connectivity.removeListener(_onConnectivity);
    await keeper.stop(_key);
    await _input?.close();
    await _storeChain;
    for (final w in _syncWaiters) {
      if (!w.isCompleted) w.completeError(StateError('closed'));
    }
    await _history.close();
    await _outcomes.close();
    await _rejections.close();
    role.dispose();
    status.dispose();
    fatal.dispose();
  }
}

/// A cell page in flight (06 §5.2).
final class _CellFetch {
  _CellFetch(this.scope, this.rows, this.block, this.page);

  final String scope;
  final List<String> rows;

  /// The plan block it belongs to (0 = the first, for ready).
  final int block;
  final Future<(api.RevPage, List<RevPageRow>)> page;
}
