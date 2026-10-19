import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show UuidV7Generator;
import 'package:wonky_ui/wonky_ui.dart'
    show SyncLogEntry, SyncState, SyncStatus;
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        DeltaDiff,
        DeltaUtils,
        WonkyAttr,
        WonkyDeltaNormalizer,
        WonkyOt,
        documentHash;

import 'package:wonky_app/wonky_app.dart';
import 'sync_persistence.dart';
import 'sync_transport.dart';

/// The client OT state (Write 03 §3, ot.js).
enum SyncOtState {
  /// Nothing pending: the local document equals the server document.
  synchronized,

  /// One op is in flight, waiting for its `Ack`.
  awaitingAck,

  /// One op is in flight and later local changes wait in the buffer.
  awaitingAckWithBuffer,
}

/// Where a change handed to [SyncDocumentHost.applyRemoteChange] comes from.
enum RemoteChangeOrigin {
  /// A collaborator's (or server-side) op, transformed against local
  /// pending changes.
  remote,

  /// The server normalized one of our ops differently (e.g. stamped
  /// suggestion times): the difference.
  fixup,

  /// The local document was re-synchronized from a server snapshot.
  resync,
}

/// Metadata of a change applied to the local document.
@immutable
class RemoteChangeInfo {
  const RemoteChangeInfo({
    required this.origin,
    required this.revision,
    this.authorId,
    this.authorUuid,
    this.authorSessionId,
    this.actorKind = ActorKind.user,
    this.kind = DocumentOpKind.content,
    this.onBehalfOfSessionId,
    this.groupId,
  });

  final RemoteChangeOrigin origin;

  /// The server revision after the change.
  final int revision;
  final int? authorId;
  final UuidValue? authorUuid;
  final String? authorSessionId;
  final ActorKind actorKind;
  final DocumentOpKind kind;
  final String? onBehalfOfSessionId;
  final String? groupId;
}

/// The local document the sync controller keeps in step with the server
/// (the editor in the app, a plain Delta in tests).
abstract interface class SyncDocumentHost {
  /// The current local document (server document plus pending changes).
  Delta get localDocument;

  /// Applies a change that did not originate locally. It is already
  /// transformed against every pending local change.
  void applyRemoteChange(Delta change, RemoteChangeInfo info);

  /// Replaces the document after the first `Init`.
  void resetDocument(Delta document);
}

/// Events of a [DocumentSyncController] (besides content changes, which go
/// to the [SyncDocumentHost]).
@immutable
sealed class SyncEvent {
  const SyncEvent();
}

/// The document is loaded: from the first `Init`, or from the local cache
/// before connecting ([fromCache], stale-while-revalidate).
class SyncLoaded extends SyncEvent {
  const SyncLoaded({required this.revision, this.fromCache = false});
  final int revision;
  final bool fromCache;
}

/// A (re)connection was established (`Init` received).
class SyncConnected extends SyncEvent {
  const SyncConnected({required this.sessionId, required this.reconnect});
  final String sessionId;
  final bool reconnect;
}

/// The connection was lost (remote cursors should disappear).
class SyncDisconnected extends SyncEvent {
  const SyncDisconnected([this.error]);
  final Object? error;
}

/// The user's effective role changed (`Init` or `RoleChanged`).
class SyncRoleChanged extends SyncEvent {
  const SyncRoleChanged(this.role, {required this.initial});
  final AccessRole role;

  /// From `Init` (not a live change).
  final bool initial;
}

/// A metadata field changed (theme, page setup, language, front matter,
/// theme version).
class SyncMetaChanged extends SyncEvent {
  const SyncMetaChanged(this.field, this.valueJson, {this.authorId});
  final String field;
  final String valueJson;
  final int? authorId;
}

/// The participants of the document stream changed.
class SyncParticipantsChanged extends SyncEvent {
  const SyncParticipantsChanged(this.participants);

  /// Other sessions (this connection excluded), by session id.
  final Map<String, Participant> participants;
}

/// A collaborator's selection, already in local document offsets.
class SyncRemoteCursor extends SyncEvent {
  const SyncRemoteCursor({
    required this.sessionId,
    required this.userId,
    required this.anchor,
    required this.head,
    required this.focused,
  });

  final String sessionId;
  final int userId;
  final int anchor;
  final int head;
  final bool focused;
}

/// Why the client re-synchronized from a snapshot.
enum ResyncReason {
  /// The server rejected an op (`OpRejected`).
  rejected,

  /// The integrity check failed (Write 03 §3.2).
  integrity,

  /// The local changes were based on a revision the server no longer keeps.
  rebaseTooOld,

  /// A server change didn't fit the local document (should never happen).
  inconsistent,
}

/// The local document was replaced by the server's.
class SyncResynced extends SyncEvent {
  const SyncResynced({
    required this.reason,
    required this.lostLocalChanges,
    this.code,
    this.message,
    this.recoveryDocument,
  });

  final ResyncReason reason;

  /// Whether unsent or unacknowledged local changes were discarded.
  final bool lostLocalChanges;
  final DocRejectCode? code;
  final String? message;

  /// The local document before the resync (offer "Save my changes as a
  /// copy" when [lostLocalChanges]).
  final Delta? recoveryDocument;
}

/// The server closed the session for good (access revoked, document gone).
class SyncAccessLost extends SyncEvent {
  const SyncAccessLost(this.error);
  final Object error;
}

/// A chunk of the buffer: local changes composed per [DocumentSyncController
/// .chunkWindow] (suite 12 §1.2: one op per 2 s of editing while offline).
class _Chunk {
  _Chunk(this.id, this.delta, this.kind, this.groupId, this.createdAt);

  final UuidValue id;
  Delta delta;
  final DocumentOpKind kind;
  final String? groupId;
  final DateTime createdAt;
}

class _Pending {
  _Pending(this.id, this.delta, this.kind, this.groupId, [DateTime? createdAt])
    : createdAt = createdAt ?? clock.now();

  final UuidValue id;
  Delta delta;
  final DocumentOpKind kind;
  final String? groupId;

  /// Connection session ids this op was sent on.
  final Set<String> sentOn = {};

  final DateTime createdAt;

  /// The op as last sent and its base revision: the server rebases exactly
  /// this (Write 03 §2 step 4), which may differ from transforming it
  /// through the same ops one by one.
  Delta? sent;
  int sentBase = 0;
}

sealed class _Ordered {
  _Ordered(this.revision);
  final int revision;
}

class _RemoteOp extends _Ordered {
  _RemoteOp(
    super.revision,
    this.delta, {
    this.clientOpId,
    this.authorId,
    this.authorUuid,
    this.authorSessionId,
    this.actorKind = ActorKind.user,
    this.kind = DocumentOpKind.content,
    this.onBehalfOfSessionId,
    this.groupId,
  });

  final Delta delta;
  final UuidValue? clientOpId;
  final int? authorId;
  final UuidValue? authorUuid;
  final String? authorSessionId;
  final ActorKind actorKind;
  final DocumentOpKind kind;
  final String? onBehalfOfSessionId;
  final String? groupId;

  RemoteChangeInfo info(Delta forLocal) => RemoteChangeInfo(
    origin: RemoteChangeOrigin.remote,
    revision: revision,
    authorId: authorId,
    authorUuid: authorUuid,
    authorSessionId: authorSessionId,
    actorKind: actorKind,
    kind: kind,
    onBehalfOfSessionId: onBehalfOfSessionId,
    groupId: groupId,
  );
}

class _Ack extends _Ordered {
  _Ack(super.revision, this.clientOpId, [this.finalDelta]);
  final UuidValue clientOpId;

  /// The op as committed by the server, when known.
  Delta? finalDelta;
}

class _Connection {
  _Connection(this.input);
  final StreamController<DocClientMessage> input;
  String? sessionId;
  bool initialized = false;
  bool lost = false;

  void send(DocClientMessage m) {
    if (!input.isClosed && !lost) input.add(m);
  }
}

typedef _Tagged = ({_Connection conn, DocServerMessage message});

/// The client side of Write's server-authoritative OT (Write 03 §3): the
/// ot.js state machine (Synchronized / AwaitingAck / AwaitingAckWithBuffer)
/// over `document.connect`.
///
/// - Local changes are submitted with [submitLocal]; at most one op is in
///   flight, later changes are composed into buffer chunks of at most
///   [chunkWindow] of editing (also while offline). With a [persistence]
///   the outbox is durable: it is stored before an op is sent, restored
///   with [restore] after a reload and resent with the same `clientOpId`.
/// - Server messages are processed strictly in revision order: remote ops
///   and acks that arrive early are held back and the gap is requested with
///   `RequestOps`; duplicates are ignored.
/// - Remote ops are transformed against the in-flight op and the buffer and
///   handed to the [SyncDocumentHost].
/// - After a reconnect the missed ops arrive in `Init`; the in-flight op is
///   recognized there by its `clientOpId` (committed) or resent with the
///   same `clientOpId` (idempotent), then the buffer follows.
/// - When the server normalizes an op differently (suggestion timestamps,
///   fix-ups), the difference is applied as a [RemoteChangeOrigin.fixup].
/// - `OpRejected` and integrity-check mismatches re-synchronize from a
///   snapshot ([SyncResynced]).
class DocumentSyncController {
  DocumentSyncController({
    required this.transport,
    required this.host,
    required this.keeper,
    this.key = 'document',
    this.hashEvery = 200,
    this.pingEvery = const Duration(seconds: 30),
    this.gapRetry = const Duration(seconds: 3),
    this.recentOpsKept = 500,
    this.persistence,
    this.chunkWindow = const Duration(seconds: 2),
    UuidV7Generator? ids,
  }) : _ids = ids ?? UuidV7Generator.instance {
    persistence?.attach(_capture);
  }

  /// Durable outbox and server document (null = in memory only).
  final SyncPersistence? persistence;

  /// Local changes are composed into one buffered op per [chunkWindow].
  final Duration chunkWindow;

  final DocumentSyncTransport transport;
  final SyncDocumentHost host;
  final ConnectionKeeper keeper;

  /// Key of the connection in the [keeper].
  final String key;

  /// Integrity check interval in revisions (Write 03 §3.2); 0 disables it.
  final int hashEvery;
  final Duration pingEvery;

  /// How long to wait before requesting a missing revision range again.
  final Duration gapRetry;

  /// Server ops remembered for transforming remote cursors.
  final int recentOpsKept;
  final UuidV7Generator _ids;

  static const _normalizer = WonkyDeltaNormalizer();

  // Server state.
  Delta _server = Delta()..insert('\n');
  int _revision = 0;
  bool _loaded = false;
  AccessRole? _role;
  DocumentMetaView? _meta;
  Map<String, Participant> _participants = const {};

  // Pending local changes.
  _Pending? _inflight;
  final List<_Chunk> _chunks = [];
  int _pendingChanges = 0;
  bool _restored = false;

  // Ordering.
  final SplayTreeMap<int, _Ordered> _queue = SplayTreeMap();
  final ListQueue<(int, Delta)> _recent = ListQueue();
  final Map<String, DocRemoteCursor> _futureCursors = {};
  bool _draining = false;
  bool _catchingUp = false;
  _Ack? _blockedAck;
  int _finalFetchFailures = 0;
  int? _gapFrom;
  DateTime? _gapAt;
  bool _resyncing = false;
  int _nextHashAt = 0;

  /// Ordered processing pauses while an ack waits for the committed op,
  /// while catching up after a long disconnect and while re-synchronizing.
  bool get _blocked => _blockedAck != null || _catchingUp || _resyncing;

  // Connection.
  _Connection? _conn;
  bool _everConnected = false;
  bool _started = false;
  bool _disposed = false;
  Object? _fatal;
  String? _error;
  Timer? _ping;
  Timer? _gapTimer;
  Timer? _internalRetry;
  int _internalFailures = 0;
  final List<SyncLogEntry> _log = [];

  final _events = StreamController<SyncEvent>.broadcast(sync: true);
  final ValueNotifier<SyncStatus> _status = ValueNotifier(
    const SyncStatus(state: SyncState.connecting),
  );
  final List<Completer<void>> _syncWaiters = [];

  // ---------------------------------------------------------------------------
  // Public state.

  /// Events (load, role, meta, participants, cursors, resyncs …).
  Stream<SyncEvent> get events => _events.stream;

  /// Saved / Saving… / Offline / Error for the `SyncStatusIndicator`.
  ValueListenable<SyncStatus> get status => _status;

  /// Whether the first `Init` arrived.
  bool get isLoaded => _loaded;

  /// The last server revision applied locally.
  int get revision => _revision;

  /// The document at [revision] as the server has it.
  Delta get serverDocument => _server;

  /// The user's role as last reported by the server.
  AccessRole? get role => _role;

  /// Document metadata (theme, page setup, language, front matter).
  DocumentMetaView? get meta => _meta;

  /// Other sessions on the document stream.
  Map<String, Participant> get participants => _participants;

  /// This connection's session id (`DocInit.sessionId`).
  String? get sessionId => _conn?.sessionId;

  /// Whether a connection is established and initialized.
  bool get isConnected =>
      (_conn?.initialized ?? false) && !(_conn?.lost ?? true);

  SyncOtState get otState => _inflight == null
      ? SyncOtState.synchronized
      : (_chunks.isEmpty
            ? SyncOtState.awaitingAck
            : SyncOtState.awaitingAckWithBuffer);

  /// Whether local changes wait for the server.
  bool get hasPendingChanges =>
      _inflight != null || _chunks.isNotEmpty || _blockedAck != null;

  /// Number of buffered chunks (tests: offline composition).
  @visibleForTesting
  int get bufferedChunks => _chunks.length;

  /// Whether the document was restored from the local cache.
  bool get isRestored => _restored;

  // ---------------------------------------------------------------------------
  // Lifecycle.

  /// Loads the locally stored state (before [start]): the document renders
  /// immediately and stays editable offline; [start] then connects with
  /// `knownRevision` = the stored revision and resubmits the outbox.
  void restore(SyncLocalState state) {
    if (_loaded || _disposed) return;
    _server = DeltaUtils.canonical(state.serverDocument);
    _revision = state.revision;
    _meta = state.meta;
    _role = state.role;
    _inflight = null;
    _chunks.clear();
    for (final r in state.outbox) {
      if (_inflight == null && _chunks.isEmpty && r.inflight) {
        // It may have been sent before the reload: never predict its
        // committed form (Write 03 §3.3), fetch it.
        _inflight = _Pending(
          r.clientOpId,
          r.delta,
          r.kind,
          r.groupId,
          r.createdAt,
        )..sentOn.add(_restoredMarker);
      } else {
        _chunks.add(
          _Chunk(r.clientOpId, r.delta, r.kind, r.groupId, r.createdAt),
        );
      }
    }
    _pendingChanges = state.outbox.length;
    _nextHashAt = hashEvery <= 0
        ? _far
        : (_revision ~/ hashEvery + 1) * hashEvery;
    _loaded = true;
    _restored = true;
    final pending = _pendingDelta();
    host.resetDocument(
      pending == null ? _server : WonkyOt.apply(_server, pending),
    );
    _logEvent('Opened from this device (revision $_revision)');
    _events.add(SyncLoaded(revision: _revision, fromCache: true));
    final role = _role;
    if (role != null) _events.add(SyncRoleChanged(role, initial: true));
    _updateStatus();
  }

  static const _restoredMarker = '<restored>';

  /// Connects (and keeps reconnecting until [dispose]).
  void start() {
    if (_started) return;
    _started = true;
    keeper.connectivity.addListener(_onConnectivity);
    keeper.keep<_Tagged>(
      key,
      _open,
      (t) => _onMessage(t.conn, t.message),
      onError: _onStreamError,
    );
    _updateStatus();
  }

  /// Reconnects now (sync status "Retry").
  void retry() {
    if (_disposed) return;
    if (_fatal != null) return;
    _error = null;
    keeper.reconnectNow(key);
    _updateStatus();
  }

  /// Completes when all local changes are acknowledged (tests, close).
  Future<void> whenSynchronized() {
    if (!hasPendingChanges && !_resyncing) return Future.value();
    final c = Completer<void>();
    _syncWaiters.add(c);
    return c.future;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _ping?.cancel();
    _gapTimer?.cancel();
    _internalRetry?.cancel();
    keeper.connectivity.removeListener(_onConnectivity);
    await keeper.stop(key);
    final c = _conn;
    _conn = null;
    if (c != null) await c.input.close();
    try {
      await persistence?.close();
    } on Object catch (e) {
      debugPrint('Closing the local document store failed: $e');
    }
    for (final w in _syncWaiters) {
      if (!w.isCompleted) w.complete();
    }
    _syncWaiters.clear();
    await _events.close();
    _status.dispose();
  }

  // ---------------------------------------------------------------------------
  // Local changes and cursor.

  /// Submits a local change (against the current local document).
  void submitLocal(
    Delta change, {
    DocumentOpKind kind = DocumentOpKind.content,
    String? groupId,
  }) {
    if (_disposed || DeltaUtils.isNoop(change)) return;
    _pendingChanges++;
    if (_inflight == null &&
        _chunks.isEmpty &&
        _blockedAck == null &&
        _canSend) {
      _inflight = _Pending(_ids.next(), change, kind, groupId);
      persistence?.markDirty();
      _sendInflight();
    } else {
      final now = clock.now();
      final last = _chunks.isEmpty ? null : _chunks.last;
      if (last != null &&
          last.kind == kind &&
          last.groupId == groupId &&
          now.difference(last.createdAt) < chunkWindow) {
        last.delta = WonkyOt.compose(last.delta, change);
      } else {
        _chunks.add(_Chunk(_ids.next(), change, kind, groupId, now));
      }
      persistence?.markDirty();
    }
    _updateStatus();
  }

  /// Sends the local selection (local document offsets); the caller
  /// throttles (10/s).
  void sendCursor(int anchor, int head, {bool focused = true}) {
    final conn = _conn;
    if (conn == null || !conn.initialized || !_loaded) return;
    var a = anchor;
    var h = head;
    final serverLength = DeltaUtils.documentLength(_server);
    final pending = _pendingDelta();
    if (pending != null) {
      // Pending local changes that don't fit the server document: no
      // cursor until they are resolved.
      if (DeltaUtils.baseLength(pending) > serverLength) return;
      final inverse = _positionInverse(pending);
      a = WonkyOt.transformPosition(inverse, a, pushOnInsert: false);
      h = WonkyOt.transformPosition(inverse, h, pushOnInsert: false);
    }
    final max = serverLength - 1;
    conn.send(
      DocCursorUpdate(
        revision: _revision,
        anchor: a.clamp(0, max),
        head: h.clamp(0, max),
        focused: focused,
      ),
    );
  }

  /// The inverse of [change] for transforming positions: positions only
  /// depend on the lengths of inserts, deletes and retains, so deleted text
  /// is stood in for by spaces instead of being read from the server
  /// document (`WonkyOt.invert` walked and copied all of it for every
  /// cursor update, CQ-49).
  static Delta _positionInverse(Delta change) {
    final inverse = Delta();
    for (final op in change.operations) {
      final length = op.length!;
      if (op.isInsert) {
        inverse.delete(length);
      } else if (op.isDelete) {
        inverse.insert(' ' * length);
      } else {
        inverse.retain(length);
      }
    }
    return inverse;
  }

  /// Runs the integrity check now (Write 03 §3.2, debug "on demand").
  void checkIntegrity() {
    final conn = _conn;
    if (conn == null || !conn.initialized) return;
    conn.send(DocHashCheck(revision: _revision, sha256: documentHash(_server)));
  }

  /// The pending local changes (in-flight op composed with the buffer).
  @visibleForTesting
  Delta? get pendingDelta => _pendingDelta();

  Delta? _pendingDelta() {
    final i = _inflight?.delta ?? _blockedAckDelta;
    final b = _bufferDelta;
    if (i == null) return b;
    if (b == null) return i;
    return WonkyOt.compose(i, b);
  }

  /// The buffer chunks composed (null when empty).
  Delta? get _bufferDelta {
    if (_chunks.isEmpty) return null;
    var d = _chunks.first.delta;
    for (final c in _chunks.skip(1)) {
      d = WonkyOt.compose(d, c.delta);
    }
    return d;
  }

  /// Transforms the buffer chunks over [change] (a server change applied
  /// after the in-flight op) and returns [change] expressed past them.
  Delta _transformChunks(Delta change) {
    var f = change;
    for (final c in _chunks) {
      final cd = c.delta;
      c.delta = WonkyOt.transform(f, cd, aWinsTies: true);
      f = WonkyOt.transform(cd, f, aWinsTies: false);
    }
    _chunks.removeWhere((c) => DeltaUtils.isNoop(c.delta));
    return f;
  }

  Delta? get _blockedAckDelta => _blockedAck == null ? null : _inflight?.delta;

  bool get _canSend =>
      !_disposed &&
      _loaded &&
      !_resyncing &&
      (_conn?.initialized ?? false) &&
      !(_conn?.lost ?? true);

  bool _awaitingDurable = false;

  void _sendInflight() {
    final store = persistence;
    if (store == null) {
      _sendInflightNow();
      return;
    }
    // The outbox is written before the op leaves the device.
    if (_awaitingDurable) return;
    _awaitingDurable = true;
    store.whenDurable().whenComplete(() {
      _awaitingDurable = false;
      if (!_disposed) _sendInflightNow();
    });
  }

  void _sendInflightNow() {
    final p = _inflight;
    final conn = _conn;
    if (p == null || conn == null || !_canSend) return;
    if (conn.sessionId != null && p.sentOn.contains(conn.sessionId)) return;
    p.sentOn.add(conn.sessionId!);
    p.sent = p.delta;
    p.sentBase = _revision;
    conn.send(
      DocSubmitOp(
        clientOpId: p.id,
        baseRevision: _revision,
        deltaJson: jsonEncode(p.delta.toJson()),
        kind: p.kind,
        groupId: p.groupId,
      ),
    );
  }

  void _flush() {
    if (_inflight != null || _blocked || !_canSend) return;
    if (_chunks.isEmpty) return;
    // The leading chunks of the same kind and group become one op.
    final first = _chunks.removeAt(0);
    var delta = first.delta;
    while (_chunks.isNotEmpty &&
        _chunks.first.kind == first.kind &&
        _chunks.first.groupId == first.groupId) {
      delta = WonkyOt.compose(delta, _chunks.removeAt(0).delta);
    }
    persistence?.markDirty();
    if (DeltaUtils.isNoop(delta)) {
      _flush();
      return;
    }
    _inflight = _Pending(
      _ids.next(),
      delta,
      first.kind,
      first.groupId,
      first.createdAt,
    );
    _sendInflight();
  }

  // ---------------------------------------------------------------------------
  // Connection.

  Stream<_Tagged> _open() {
    final old = _conn;
    if (old != null) {
      old.lost = true;
      unawaited(old.input.close());
    }
    final conn = _Connection(StreamController<DocClientMessage>());
    _conn = conn;
    _updateStatus();
    final source = transport.connect(
      _loaded ? _revision : 0,
      conn.input.stream,
    );
    StreamSubscription<DocServerMessage>? sub;
    late final StreamController<_Tagged> out;
    out = StreamController<_Tagged>(
      onListen: () {
        sub = source.listen(
          (m) => out.add((conn: conn, message: m)),
          onError: (Object e, StackTrace st) {
            _lost(conn, e);
            if (!out.isClosed) out.addError(e, st);
          },
          onDone: () {
            _lost(conn, null);
            if (!out.isClosed) unawaited(out.close());
          },
        );
      },
      onCancel: () async {
        _lost(conn, null);
        await sub?.cancel();
      },
    );
    return out.stream;
  }

  void _lost(_Connection conn, Object? error) {
    if (conn.lost) return;
    conn.lost = true;
    unawaited(conn.input.close());
    if (_conn != conn) return;
    _ping?.cancel();
    _gapFrom = null;
    _futureCursors.clear();
    if (conn.initialized) {
      _logEvent('Disconnected${error == null ? '' : ': $error'}');
    }
    if (!_disposed) {
      _events.add(SyncDisconnected(error));
      _updateStatus();
    }
  }

  void _onStreamError(Object error) {
    if (_disposed) return;
    if (_isAccessError(error)) {
      _fatal = error;
      _logEvent('Access lost: $error', isError: true);
      unawaited(keeper.stop(key));
      _events.add(SyncAccessLost(error));
      _updateStatus();
    }
  }

  static bool _isAccessError(Object e) =>
      e is WonkyException &&
      (e.code == WonkyErrorCode.forbidden || e.code == WonkyErrorCode.notFound);

  void _onConnectivity() => _updateStatus();

  void _onMessage(_Connection conn, DocServerMessage m) {
    if (_disposed || conn != _conn || conn.lost) return;
    switch (m) {
      case DocInit():
        _onInit(conn, m);
      case DocAck():
        _onAck(m);
      case DocRemoteOp():
        _onRemoteOp(
          _RemoteOp(
            m.revision,
            _decode(m.deltaJson),
            authorId: m.authorId,
            authorUuid: m.authorUuid,
            authorSessionId: m.authorSessionId,
            actorKind: m.actorKind,
            kind: m.kind,
            onBehalfOfSessionId: m.onBehalfOfSessionId,
            groupId: m.groupId,
          ),
        );
      case DocRemoteCursor():
        _onRemoteCursor(m);
      case DocParticipantJoined():
        if (m.participant.sessionId == conn.sessionId) return;
        _participants = {
          ..._participants,
          m.participant.sessionId: m.participant,
        };
        _events.add(SyncParticipantsChanged(_participants));
      case DocParticipantLeft():
        if (!_participants.containsKey(m.sessionId)) return;
        _participants = {..._participants}..remove(m.sessionId);
        _events.add(SyncParticipantsChanged(_participants));
      case DocMetaChanged():
        _onMeta(m);
      case DocRoleChanged():
        _role = m.role;
        persistence?.markDirty();
        _logEvent('Role changed to ${m.role.name}');
        _events.add(SyncRoleChanged(m.role, initial: false));
        _updateStatus();
      case DocOpRejected():
        _onRejected(m);
      case DocHashResult():
        if (!m.matches && m.revision <= _revision) {
          _logEvent(
            'Integrity check failed at revision ${m.revision}',
            isError: true,
          );
          unawaited(_resync(ResyncReason.integrity));
        }
      case DocPong():
        break;
    }
  }

  static Delta _decode(String json) => Delta.fromJson(jsonDecode(json) as List);

  void _onInit(_Connection conn, DocInit m) {
    conn.sessionId = m.sessionId;
    conn.initialized = true;
    final reconnect = _everConnected;
    _everConnected = true;
    _gapFrom = null;
    _participants = {
      for (final p in m.participants)
        if (p.sessionId != m.sessionId) p.sessionId: p,
    };
    final roleChanged = _role != m.role;
    _role = m.role;
    _meta = m.meta;
    _logEvent(reconnect ? 'Reconnected' : 'Connected');

    if (!_loaded) {
      final snapshot = m.snapshotJson;
      if (snapshot != null) {
        _server = DeltaUtils.canonical(_decode(snapshot));
      } else {
        for (final op in m.ops ?? const <DocumentOpView>[]) {
          _server = WonkyOt.apply(_server, _decode(op.deltaJson));
        }
      }
      _revision = m.revision;
      _nextHashAt = hashEvery <= 0
          ? _far
          : (_revision ~/ hashEvery + 1) * hashEvery;
      _loaded = true;
      persistence?.serverReset(_server, _revision);
      persistence?.markDirty();
      host.resetDocument(_server);
      _events.add(SyncLoaded(revision: _revision));
      _events.add(SyncRoleChanged(m.role, initial: true));
    } else {
      if (roleChanged) _events.add(SyncRoleChanged(m.role, initial: false));
      persistence?.markDirty();
      final snapshot = m.snapshotJson;
      if (m.revision < _revision) {
        // The local copy is ahead of the server (restored server data):
        // it belongs to another history, start over from the server's.
        _logEvent(
          'The server is at revision ${m.revision}, this device had '
          '$_revision',
          isError: true,
        );
        unawaited(_resync(ResyncReason.inconsistent));
      } else if (snapshot != null) {
        unawaited(_catchUp(_decode(snapshot), m.revision));
      } else {
        for (final op in m.ops ?? const <DocumentOpView>[]) {
          _onRemoteOp(_fromView(op));
        }
      }
    }
    _events.add(SyncParticipantsChanged(_participants));
    _events.add(SyncConnected(sessionId: m.sessionId, reconnect: reconnect));
    _resendAfterInit();
    _ping?.cancel();
    if (pingEvery > Duration.zero) {
      _ping = Timer.periodic(pingEvery, (_) {
        _conn?.send(DocPing(t: clock.now().millisecondsSinceEpoch));
      });
    }
    _updateStatus();
  }

  _RemoteOp _fromView(DocumentOpView v) => _RemoteOp(
    v.revision,
    _decode(v.deltaJson),
    clientOpId: v.clientOpId,
    authorId: v.authorId,
    authorUuid: v.authorUuid,
    authorSessionId: v.sessionId,
    actorKind: v.actorKind,
    kind: v.kind,
  );

  void _resendAfterInit() {
    if (_blocked) return;
    if (_inflight != null) {
      _sendInflight();
    } else {
      _flush();
    }
  }

  /// Reconnected too far behind for an op list: fetch the missed ops; when
  /// that's impossible, fall back to the snapshot.
  Future<void> _catchUp(Delta snapshot, int head) async {
    if (!hasPendingChanges && _queue.isEmpty) {
      _replaceWith(snapshot, head, ResyncReason.rebaseTooOld, lost: false);
      return;
    }
    _catchingUp = true;
    try {
      var from = _revision + 1;
      while (from <= head) {
        final views = await transport.getOps(from, head);
        if (views.isEmpty || views.first.revision != from) {
          throw StateError('Ops from $from are no longer available');
        }
        for (final v in views) {
          _onRemoteOp(_fromView(v));
        }
        from = views.last.revision + 1;
      }
      _catchingUp = false;
      _drain();
      _resendAfterInit();
    } catch (e) {
      _catchingUp = false;
      _logEvent('Could not catch up: $e', isError: true);
      _replaceWith(snapshot, head, ResyncReason.rebaseTooOld, lost: true);
    }
  }

  // ---------------------------------------------------------------------------
  // Ordered processing.

  void _onRemoteOp(_RemoteOp e) {
    if (e.revision <= _revision) return;
    final inflight = _inflight;
    final own =
        inflight != null &&
        ((e.clientOpId != null && e.clientOpId == inflight.id) ||
            (e.authorSessionId != null &&
                inflight.sentOn.contains(e.authorSessionId)));
    if (own) {
      final blocked = _blockedAck;
      if (blocked != null && blocked.revision == e.revision) {
        _resolveBlockedAck(e.delta);
        return;
      }
      final existing = _queue[e.revision];
      if (existing is _Ack) {
        existing.finalDelta ??= e.delta;
      } else {
        _queue[e.revision] = _Ack(e.revision, inflight.id, e.delta);
      }
    } else {
      if (_queue[e.revision] is _Ack) return;
      _queue[e.revision] = e;
    }
    _drain();
  }

  void _onAck(DocAck m) {
    final inflight = _inflight;
    if (inflight == null || inflight.id != m.clientOpId) return;
    _internalFailures = 0;
    if (m.revision <= _revision) return;
    if (_blockedAck?.revision == m.revision) return;
    final existing = _queue[m.revision];
    if (existing is _Ack) return;
    _queue[m.revision] = _Ack(m.revision, m.clientOpId);
    _drain();
  }

  void _drain() {
    if (_draining || _disposed) return;
    _draining = true;
    try {
      while (!_blocked) {
        final next = _queue.remove(_revision + 1);
        if (next == null) break;
        switch (next) {
          case _RemoteOp():
            _applyRemote(next);
          case _Ack():
            _processAck(next);
        }
        _emitDueCursors();
      }
      _queue.removeWhere((rev, _) => rev <= _revision);
    } finally {
      _draining = false;
    }
    _requestGapIfNeeded();
    _maybeCheckIntegrity();
    _completeWaitersIfSynced();
    _updateStatus();
  }

  void _requestGapIfNeeded() {
    _gapTimer?.cancel();
    if (_blocked || _queue.isEmpty) {
      _gapFrom = null;
      return;
    }
    final from = _revision + 1;
    final to = _queue.firstKey()! - 1;
    if (to < from) return;
    final now = clock.now();
    if (_gapFrom != from ||
        _gapAt == null ||
        now.difference(_gapAt!) >= gapRetry) {
      _gapFrom = from;
      _gapAt = now;
      _conn?.send(DocRequestOps(fromRevision: from, toRevision: to));
    }
    _gapTimer = Timer(gapRetry, () {
      if (!_disposed) _requestGapIfNeeded();
    });
  }

  void _applyRemote(_RemoteOp e) {
    final r = e.delta;
    try {
      // `_server` is canonical: only the ops around the change are redone.
      _server = WonkyOt.applyToCanonical(_server, r);
    } on Object catch (err) {
      _logEvent('Remote op ${e.revision} does not fit: $err', isError: true);
      unawaited(_resync(ResyncReason.inconsistent));
      return;
    }
    _remember(e.revision, r);
    var forLocal = r;
    final inflight = _inflight;
    if (inflight != null) {
      final i = inflight.delta;
      inflight.delta = WonkyOt.transform(r, i, aWinsTies: true);
      forLocal = WonkyOt.transform(i, r, aWinsTies: false);
    }
    forLocal = _transformChunks(forLocal);
    _revision = e.revision;
    persistence?.serverOp(e.revision, r);
    persistence?.markDirty();
    if (!DeltaUtils.isNoop(forLocal)) {
      host.applyRemoteChange(forLocal, e.info(forLocal));
    }
  }

  void _processAck(_Ack e) {
    final inflight = _inflight;
    if (inflight == null || inflight.id != e.clientOpId) {
      // Cannot happen (acks are matched on arrival); keep the revision order.
      _logEvent('Unexpected ack for revision ${e.revision}', isError: true);
      unawaited(_resync(ResyncReason.inconsistent));
      return;
    }
    final known = e.finalDelta;
    if (known != null) {
      _completeAck(e.revision, known);
      return;
    }
    final predicted = _predictFinal(inflight, e.revision);
    if (predicted != null) {
      _completeAck(e.revision, predicted);
      return;
    }
    // The server rewrote the op (suggestion timestamps): fetch it.
    _blockedAck = e;
    _finalFetchFailures = 0;
    unawaited(_fetchFinal(e));
  }

  /// The op the server committed for [p] at [revision], when it can be
  /// computed locally: the server rebases the op as sent against the
  /// composition of the ops since its base, then normalizes it. Both are
  /// deterministic except for suggestion timestamps (server time) — and
  /// when the op was sent more than once it is unknown which copy was
  /// committed.
  Delta? _predictFinal(_Pending p, int revision) {
    final sent = p.sent;
    if (sent == null || p.sentOn.length != 1) return null;
    var op = sent;
    if (p.sentBase < revision - 1) {
      final since = [
        for (final (rev, delta) in _recent)
          if (rev > p.sentBase && rev < revision) delta,
      ];
      if (since.length != revision - 1 - p.sentBase) return null;
      op = WonkyOt.rebaseOnServer(sent, since);
    }
    for (final o in op.operations) {
      final attrs = o.attributes;
      if (attrs == null) continue;
      for (final entry in attrs.entries) {
        if (WonkyAttr.isSuggestion(entry.key) && entry.value != null) {
          return null;
        }
      }
    }
    try {
      // Only the lines the op touches (CQ-49): same result as
      // `normalizeChange(_server, op).change`.
      return _normalizer.normalizedChange(_server, op);
    } on Object {
      return null;
    }
  }

  Future<void> _fetchFinal(_Ack e) async {
    while (!_disposed && _blockedAck == e) {
      try {
        final views = await transport.getOps(e.revision, e.revision);
        if (_blockedAck != e) return;
        final v = views.where((v) => v.revision == e.revision).firstOrNull;
        if (v != null && v.clientOpId == e.clientOpId) {
          _resolveBlockedAck(_decode(v.deltaJson));
          return;
        }
        throw StateError('Revision ${e.revision} is not our op');
      } catch (err) {
        if (_blockedAck != e) return;
        _finalFetchFailures++;
        if (_finalFetchFailures >= 5) {
          _logEvent('Could not confirm a saved change: $err', isError: true);
          _blockedAck = null;
          unawaited(_resync(ResyncReason.inconsistent));
          return;
        }
        await Future<void>.delayed(
          Duration(milliseconds: 250 * (1 << _finalFetchFailures)),
        );
      }
    }
  }

  void _resolveBlockedAck(Delta finalDelta) {
    final e = _blockedAck;
    if (e == null) return;
    _blockedAck = null;
    _completeAck(e.revision, finalDelta);
    _drain();
    _flush();
  }

  void _completeAck(int revision, Delta finalDelta) {
    final inflight = _inflight!;
    final before = _server;
    try {
      _server = WonkyOt.applyToCanonical(before, finalDelta);
    } on Object catch (err) {
      _logEvent('Acknowledged op does not fit: $err', isError: true);
      unawaited(_resync(ResyncReason.inconsistent));
      return;
    }
    _remember(revision, finalDelta);
    _revision = revision;
    _inflight = null;
    _error = null;
    persistence?.serverOp(revision, finalDelta);
    persistence?.markDirty();
    if (!DeltaUtils.equals(finalDelta, inflight.delta)) {
      final mine = WonkyOt.apply(before, inflight.delta);
      final fix = DeltaDiff.diff(mine, _server);
      if (!DeltaUtils.isNoop(fix)) {
        final forLocal = _transformChunks(fix);
        host.applyRemoteChange(
          forLocal,
          RemoteChangeInfo(
            origin: RemoteChangeOrigin.fixup,
            revision: revision,
            kind: inflight.kind,
          ),
        );
      }
    }
    if (_chunks.isEmpty) _pendingChanges = 0;
    _flush();
  }

  void _remember(int revision, Delta op) {
    _recent.addLast((revision, op));
    while (_recent.length > recentOpsKept) {
      _recent.removeFirst();
    }
  }

  void _maybeCheckIntegrity() {
    if (hashEvery <= 0 || !_loaded || _revision < _nextHashAt) return;
    _nextHashAt = (_revision ~/ hashEvery + 1) * hashEvery;
    checkIntegrity();
  }

  void _completeWaitersIfSynced() {
    if (hasPendingChanges || _resyncing || _syncWaiters.isEmpty) return;
    final waiters = [..._syncWaiters];
    _syncWaiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) w.complete();
    }
  }

  // ---------------------------------------------------------------------------
  // Cursors and metadata.

  void _onRemoteCursor(DocRemoteCursor m) {
    if (m.revision > _revision) {
      _futureCursors[m.sessionId] = m;
      return;
    }
    _futureCursors.remove(m.sessionId);
    _emitCursor(m);
  }

  void _emitDueCursors() {
    if (_futureCursors.isEmpty) return;
    final due = [
      for (final c in _futureCursors.values)
        if (c.revision <= _revision) c,
    ];
    for (final c in due) {
      _futureCursors.remove(c.sessionId);
      _emitCursor(c);
    }
  }

  void _emitCursor(DocRemoteCursor m) {
    var a = m.anchor;
    var h = m.head;
    if (m.revision < _revision) {
      final ops = [
        for (final (rev, op) in _recent)
          if (rev > m.revision) op,
      ];
      if (ops.length == _revision - m.revision) {
        for (final op in ops) {
          a = WonkyOt.transformPosition(op, a);
          h = WonkyOt.transformPosition(op, h);
        }
      }
    }
    for (final p in [_inflight?.delta, ..._chunks.map((c) => c.delta)]) {
      if (p == null) continue;
      a = WonkyOt.transformPosition(p, a, pushOnInsert: false);
      h = WonkyOt.transformPosition(p, h, pushOnInsert: false);
    }
    final pending = _pendingDelta();
    final max =
        DeltaUtils.documentLength(_server) +
        (pending == null ? 0 : DeltaUtils.lengthDelta(pending)) -
        1;
    _events.add(
      SyncRemoteCursor(
        sessionId: m.sessionId,
        userId: m.userId,
        anchor: a.clamp(0, max < 0 ? 0 : max),
        head: h.clamp(0, max < 0 ? 0 : max),
        focused: m.focused,
      ),
    );
  }

  void _onMeta(DocMetaChanged m) {
    _updateMeta(m.field, m.valueJson);
    persistence?.markDirty();
    _events.add(SyncMetaChanged(m.field, m.valueJson, authorId: m.authorId));
  }

  /// Applies a metadata change made locally (optimistic; the `MetaChanged`
  /// echo confirms it).
  void applyLocalMeta(String field, String valueJson) {
    _updateMeta(field, valueJson);
    persistence?.markDirty();
  }

  void _updateMeta(String field, String valueJson) {
    final meta = _meta;
    if (meta != null) {
      Object? value;
      try {
        value = jsonDecode(valueJson);
      } on FormatException {
        value = valueJson;
      }
      _meta = switch (field) {
        'themeId' => meta.copyWith(
          themeId: value is String
              ? UuidValue.fromString(value)
              : (value is Map && value['themeId'] is String
                    ? UuidValue.fromString(value['themeId'] as String)
                    : null),
        ),
        'pageSetup' => meta.copyWith(
          pageSetupJson: value is Map ? jsonEncode(value) : valueJson,
        ),
        'language' => meta.copyWith(language: value is String ? value : null),
        'frontMatter' => meta.copyWith(
          frontMatter: value is String ? value : null,
        ),
        _ => meta,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Rejections and resyncs.

  void _onRejected(DocOpRejected m) {
    if (_inflight?.id != m.clientOpId) return;
    if (m.code == DocRejectCode.internal) {
      // Nothing was committed (or the resend is acknowledged as a
      // duplicate): retry the same op after a backoff, keeping local edits.
      _retryInternal();
      return;
    }
    _error = m.message;
    _logEvent('Change rejected (${m.code.name}): ${m.message}', isError: true);
    if (m.code == DocRejectCode.rebaseTooOld) {
      unawaited(_resync(ResyncReason.rebaseTooOld, code: m.code));
    } else {
      unawaited(
        _resync(ResyncReason.rejected, code: m.code, message: m.message),
      );
    }
  }

  /// Resends the in-flight op after an `internal` rejection, backing off
  /// from 1 s to 30 s; a reconnect resends it anyway.
  void _retryInternal() {
    _internalFailures++;
    final seconds = 1 << (_internalFailures - 1).clamp(0, 5);
    _logEvent(
      'Server error; retrying the change in ${seconds.clamp(1, 30)} s.',
      isError: true,
    );
    _internalRetry?.cancel();
    _internalRetry = Timer(Duration(seconds: seconds.clamp(1, 30)), () {
      final p = _inflight;
      final session = _conn?.sessionId;
      if (_disposed || p == null || session == null) return;
      p.sentOn.remove(session);
      _sendInflight();
    });
  }

  /// Re-synchronizes the local document from the head snapshot. Pending
  /// local changes are discarded.
  Future<void> resync() => _resync(ResyncReason.inconsistent);

  Future<void> _resync(
    ResyncReason reason, {
    DocRejectCode? code,
    String? message,
  }) async {
    if (_resyncing || _disposed) return;
    _resyncing = true;
    _blockedAck = null;
    _updateStatus();
    var attempt = 0;
    while (!_disposed) {
      try {
        final snap = await transport.getSnapshot();
        if (_disposed) return;
        _resyncing = false;
        _replaceWith(
          _decode(snap.deltaJson),
          snap.revision,
          reason,
          lost: true,
          code: code,
          message: message,
        );
        return;
      } catch (e) {
        attempt++;
        _logEvent('Resync failed: $e', isError: true);
        await Future<void>.delayed(
          Duration(milliseconds: 500 * (1 << (attempt.clamp(0, 6)))),
        );
      }
    }
  }

  void _replaceWith(
    Delta snapshot,
    int revision,
    ResyncReason reason, {
    required bool lost,
    DocRejectCode? code,
    String? message,
  }) {
    final hadPending = hasPendingChanges;
    final local = host.localDocument;
    _inflight = null;
    _chunks.clear();
    _pendingChanges = 0;
    _server = DeltaUtils.canonical(snapshot);
    _revision = revision;
    persistence?.serverReset(_server, _revision);
    persistence?.markDirty();
    _recent.clear();
    _queue.removeWhere((rev, _) => rev <= revision);
    _nextHashAt = hashEvery <= 0
        ? _far
        : (_revision ~/ hashEvery + 1) * hashEvery;
    final diff = DeltaDiff.diff(local, _server);
    if (!DeltaUtils.isNoop(diff)) {
      host.applyRemoteChange(
        diff,
        RemoteChangeInfo(origin: RemoteChangeOrigin.resync, revision: revision),
      );
    }
    _logEvent('Re-synchronized at revision $revision (${reason.name})');
    _events.add(
      SyncResynced(
        reason: reason,
        lostLocalChanges: lost && hadPending,
        code: code,
        message: message,
        recoveryDocument: lost && hadPending ? local : null,
      ),
    );
    _drain();
    _flush();
  }

  // ---------------------------------------------------------------------------
  // Persistence.

  SyncCapture _capture() {
    final out = <PendingOpRecord>[];
    final inflight = _inflight;
    if (inflight != null) {
      out.add(
        PendingOpRecord(
          clientOpId: inflight.id,
          seq: 0,
          baseRevision: _revision,
          delta: inflight.delta,
          kind: inflight.kind,
          groupId: inflight.groupId,
          createdAt: inflight.createdAt,
          inflight: true,
        ),
      );
    }
    for (final c in _chunks) {
      out.add(
        PendingOpRecord(
          clientOpId: c.id,
          seq: out.length,
          baseRevision: _revision,
          delta: c.delta,
          kind: c.kind,
          groupId: c.groupId,
          createdAt: c.createdAt,
        ),
      );
    }
    return SyncCapture(
      revision: _revision,
      serverDocument: _server,
      outbox: out,
      meta: _meta,
      role: _role,
    );
  }

  // ---------------------------------------------------------------------------
  // Status.

  void _logEvent(String message, {bool isError = false}) {
    _log.add(SyncLogEntry(at: clock.now(), message: message, isError: isError));
    if (_log.length > 30) _log.removeAt(0);
  }

  void _updateStatus() {
    if (_disposed) return;
    final pending = hasPendingChanges ? _pendingChanges.clamp(1, _far) : 0;
    final log = List<SyncLogEntry>.unmodifiable(_log);
    final SyncStatus next;
    if (_fatal != null) {
      next = SyncStatus(
        state: SyncState.error,
        error: '$_fatal',
        pendingChanges: pending,
        log: log,
      );
    } else if (!keeper.online) {
      next = SyncStatus(
        state: SyncState.offline,
        pendingChanges: pending,
        reconnectAt: keeper.nextAttemptAt,
        log: log,
      );
    } else if (!_loaded) {
      next = SyncStatus(state: SyncState.connecting, log: log);
    } else if (!isConnected) {
      next = SyncStatus(
        state: SyncState.reconnecting,
        pendingChanges: pending,
        reconnectAt: keeper.nextAttemptAt,
        log: log,
      );
    } else if (_error != null) {
      next = SyncStatus(
        state: SyncState.error,
        error: _error,
        pendingChanges: pending,
        log: log,
      );
    } else if (hasPendingChanges || _resyncing) {
      next = SyncStatus(
        state: SyncState.saving,
        pendingChanges: pending,
        log: log,
      );
    } else {
      next = SyncStatus(state: SyncState.saved, log: log);
    }
    if (next != _status.value) _status.value = next;
  }
}

/// A large int that is exact on the VM and the web (`1 << n` with n ≥ 32
/// is 0 on the web).
const _far = 0x1FFFFFFFFFFFFF;
