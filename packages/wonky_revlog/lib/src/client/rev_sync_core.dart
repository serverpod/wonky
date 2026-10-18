import 'dart:collection';

import '../apply/validation.dart';
import '../codec/change_set.dart';
import '../codec/rev_codec.dart';
import '../rows/row_change.dart';
import 'chunker.dart';

/// A committed op as delivered to a client (remote op, catch-up op).
final class RevOpIn {
  /// Creates the record.
  RevOpIn({
    required this.revision,
    required this.clientOpId,
    required this.applied,
    this.authorUuid,
    this.sessionId,
    this.actorKind = 'user',
    this.label = '',
    this.summary,
    this.detail,
    this.offline = false,
    this.groupId,
    this.groupIndex = 0,
    this.groupLast = true,
    this.recordId,
    this.onBehalfOfSessionId,
    this.outcome,
    DateTime? committedAt,
  }) : committedAt = committedAt ?? DateTime.now().toUtc();

  /// Revision.
  final int revision;

  /// The author's client op id.
  final String clientOpId;

  /// Applied form (no `before`).
  final List<RowChange> applied;

  /// Author (auth user uuid).
  final String? authorUuid;

  /// Author's connection session id.
  final String? sessionId;

  /// Actor kind.
  final String actorKind;

  /// Label.
  final String label;

  /// Summary JSON.
  final Map<String, Object?>? summary;

  /// Detail JSON.
  final Map<String, Object?>? detail;

  /// Made offline.
  final bool offline;

  /// Chunk group.
  final String? groupId;

  /// Position in the group.
  final int groupIndex;

  /// Last op of the group.
  final bool groupLast;

  /// Server change record.
  final String? recordId;

  /// Live session an agent acted for.
  final String? onBehalfOfSessionId;

  /// Outcome JSON (lost-ack recovery).
  final Map<String, Object?>? outcome;

  /// Commit time.
  final DateTime committedAt;
}

/// The server's acknowledgement of this client's op.
final class RevAckIn {
  /// Creates the record.
  RevAckIn({
    required this.clientOpId,
    required this.revision,
    this.applied,
    this.outcome,
    this.duplicate = false,
    this.pruned = false,
  });

  /// The op.
  final String clientOpId;

  /// Its revision.
  final int revision;

  /// Applied form when it differs from what was sent.
  final List<RowChange>? applied;

  /// Outcome JSON.
  final Map<String, Object?>? outcome;

  /// A resend of an already committed op.
  final bool duplicate;

  /// The duplicate's payload was pruned (> 30 days): re-bootstrap.
  final bool pruned;
}

/// Callbacks of [RevSyncCore] (implemented by the I/O wrapper).
abstract interface class RevSyncHost {
  /// Persist the outbox (this tab's ops, oldest first); then call
  /// [RevSyncCore.markDurable].
  void persistOutbox(List<ChangeSet> outbox);

  /// Send an op (RevSubmit).
  void sendOp(ChangeSet op);

  /// Request ops in (from-1, to] (RevRequestOps / ops()).
  void requestOps(int from, int to);

  /// Apply a remote op (model via overlay, store, history), in order.
  void applyRemote(RevOpIn op);

  /// Apply this client's acked op ([applied] = the applied form, or the
  /// submitted changes when unchanged).
  void applyAck(ChangeSet op, RevAckIn ack, List<RowChange> applied);

  /// Ops removed from the outbox by a rejection (the op and the rest of its
  /// group).
  void applyRejected(List<ChangeSet> ops, RevRejection rejection);

  /// The server needs a (re-)bootstrap at [revision].
  void bootstrap(int revision);
}

/// Per-file sync state machine of RevLog (spec 06 §4), without I/O: one op in
/// flight, buffered chunks, revision-ordered processing, gap fill, acks,
/// rejections, reconnects.
final class RevSyncCore {
  /// Creates the core at server revision [serverRevision].
  RevSyncCore({
    required this.host,
    required this.codec,
    required this.newId,
    this.serverRevision = 0,
    this.limits = RevLimits.defaults,
    this.chunkWindow = const Duration(seconds: 2),
    DateTime Function()? now,
    List<ChangeSet> restoredOutbox = const [],
  }) : _now = now ?? (() => DateTime.now().toUtc()) {
    if (restoredOutbox.isNotEmpty) {
      inflight = restoredOutbox.first;
      _buffer.addAll(restoredOutbox.skip(1));
      _durable.addAll(restoredOutbox.map((o) => o.clientOpId));
      _maybeSent.add(restoredOutbox.first.clientOpId);
    }
  }

  /// Host callbacks.
  final RevSyncHost host;

  /// Codec (chunk sizing).
  final RevCodec codec;

  /// New UUIDv7 client op ids.
  final String Function() newId;

  /// Limits.
  final RevLimits limits;

  /// Composition window for plain edits.
  final Duration chunkWindow;

  final DateTime Function() _now;

  /// Last revision processed in order.
  int serverRevision;

  /// The op awaiting its ack.
  ChangeSet? inflight;

  final List<ChangeSet> _buffer = [];
  final Set<String> _durable = {};
  final Set<String> _maybeSent = {};
  final SplayTreeMap<int, Object> _queue = SplayTreeMap();
  bool _connected = false;
  bool _initialized = false;
  String? _sentOnThisConnection;
  DateTime? _gapRequestedAt;

  /// Whether the stream is up and initialized.
  bool get connected => _connected && _initialized;

  /// This client's unacknowledged ops, oldest first.
  List<ChangeSet> get outbox => [?inflight, ..._buffer];

  /// Number of unacknowledged changes.
  int get pendingChanges => outbox.fold(0, (n, op) => n + op.changes.length);

  /// Whether nothing is pending.
  bool get isSynchronized => inflight == null && _buffer.isEmpty;

  /// Records local changes: chunks, composes and persists them. Returns the
  /// ops (new or composed) for the caller's bookkeeping.
  List<ChangeSet> submitLocal(
    List<RowChange> changes, {
    String label = '',
    String actorKind = 'user',
    String? groupId,
    Map<String, Object?>? summary,
    Map<String, Object?>? detail,
  }) {
    if (changes.isEmpty) return const [];
    final cs = ChangeSet(
      clientOpId: newId(),
      baseRevision: serverRevision,
      changes: changes,
      label: label,
      actorKind: actorKind,
      summary: summary,
      detail: detail,
      groupId: groupId,
      offline: !connected,
      createdAt: _now(),
    );
    final chunks = RevChunker.split(cs, codec, newId, limits: limits);
    final touched = <ChangeSet>[];
    for (final chunk in chunks) {
      if (inflight == null && _buffer.isEmpty && connected) {
        inflight = chunk;
        touched.add(chunk);
        continue;
      }
      if (_buffer.isNotEmpty) {
        final last = _buffer.last;
        final composed = composeChangeSets(
          last,
          chunk,
          window: chunkWindow,
          limits: limits,
        );
        if (composed != null) {
          _buffer[_buffer.length - 1] = composed;
          _durable.remove(composed.clientOpId);
          touched.add(composed);
          continue;
        }
      }
      _buffer.add(chunk);
      touched.add(chunk);
    }
    if (inflight == null && _buffer.isNotEmpty && connected) {
      inflight = _buffer.removeAt(0);
    }
    host.persistOutbox(outbox);
    return touched;
  }

  /// The host stored the outbox containing [clientOpIds].
  void markDurable(Iterable<String> clientOpIds) {
    _durable.addAll(clientOpIds);
    _sendIfReady();
  }

  /// The stream connected (before RevInit).
  void connectedStream() {
    _connected = true;
    _initialized = false;
    _sentOnThisConnection = null;
  }

  /// The stream dropped.
  void disconnected() {
    _connected = false;
    _initialized = false;
    _sentOnThisConnection = null;
    _queue.clear();
    _gapRequestedAt = null;
  }

  /// RevInit: [revision] head; [ops] the tail (or null with [bootstrap]).
  void init(
    int revision, {
    List<RevOpIn>? ops,
    bool more = false,
    bool bootstrap = false,
  }) {
    _initialized = true;
    if (bootstrap) {
      _queue.clear();
      serverRevision = revision;
      host.bootstrap(revision);
    } else {
      for (final op in ops ?? const <RevOpIn>[]) {
        remoteOp(op);
      }
      if (more && serverRevision < revision) {
        _requestGap(serverRevision + 1, revision);
      }
    }
    if (inflight == null && _buffer.isNotEmpty) inflight = _buffer.removeAt(0);
    _sendIfReady();
  }

  /// A committed op from the server (remote, catch-up or gap fill).
  void remoteOp(RevOpIn op) {
    if (op.revision <= serverRevision) return;
    _queue[op.revision] = op;
    _drain();
  }

  /// An ack of this client's op.
  void ack(RevAckIn ack) {
    if (ack.pruned) {
      _takeAcked(ack.clientOpId);
      host.bootstrap(serverRevision);
      return;
    }
    if (ack.revision <= serverRevision) {
      // Already processed through catch-up (same clientOpId).
      return;
    }
    _queue[ack.revision] = ack;
    _drain();
  }

  /// The server refused op [clientOpId].
  void rejected(String clientOpId, RevRejection rejection) {
    final op = outbox.where((o) => o.clientOpId == clientOpId).firstOrNull;
    if (op == null) return;
    final removed = <ChangeSet>[op];
    if (op.groupId != null) {
      removed.addAll(outbox.where((o) => o != op && o.groupId == op.groupId));
    }
    for (final r in removed) {
      if (inflight?.clientOpId == r.clientOpId) {
        inflight = null;
      } else {
        _buffer.removeWhere((b) => b.clientOpId == r.clientOpId);
      }
      _durable.remove(r.clientOpId);
      _maybeSent.remove(r.clientOpId);
    }
    host.applyRejected(removed, rejection);
    _promote();
    host.persistOutbox(outbox);
  }

  /// The server's head seen in a pong/beat: gap-fill a lost bus message.
  void headSeen(int head) {
    if (head > serverRevision && _queue.isEmpty) {
      _requestGap(serverRevision + 1, head);
    }
  }

  /// Call periodically: re-requests a gap after [retry].
  void tick({Duration retry = const Duration(seconds: 3)}) {
    if (_queue.isEmpty) return;
    final at = _gapRequestedAt;
    if (at != null && _now().difference(at) < retry) return;
    final first = _queue.firstKey()!;
    if (first > serverRevision + 1) _requestGap(serverRevision + 1, first - 1);
  }

  /// Rebases the core after a bootstrap completed at [revision] (all buffered
  /// ops were processed by the bootstrapper).
  void bootstrapped(int revision) {
    if (revision > serverRevision) serverRevision = revision;
    _drain();
  }

  void _drain() {
    while (_queue.isNotEmpty) {
      final first = _queue.firstKey()!;
      if (first <= serverRevision) {
        _queue.remove(first);
        continue;
      }
      if (first != serverRevision + 1) {
        if (_gapRequestedAt == null) _requestGap(serverRevision + 1, first - 1);
        return;
      }
      final item = _queue.remove(first)!;
      serverRevision = first;
      _gapRequestedAt = null;
      switch (item) {
        case RevAckIn():
          _processAck(item);
        case RevOpIn():
          final mine = outbox
              .where((o) => o.clientOpId == item.clientOpId)
              .firstOrNull;
          if (mine != null) {
            // Our own op seen through catch-up: its ack was lost.
            _processAck(
              RevAckIn(
                clientOpId: item.clientOpId,
                revision: item.revision,
                applied: item.applied,
                outcome: item.outcome,
              ),
            );
          } else {
            host.applyRemote(item);
          }
      }
    }
  }

  void _processAck(RevAckIn ack) {
    final op = _takeAcked(ack.clientOpId);
    if (op == null) return;
    host.applyAck(op, ack, ack.applied ?? _withoutBefore(op.changes));
    _promote();
    host.persistOutbox(outbox);
  }

  ChangeSet? _takeAcked(String clientOpId) {
    ChangeSet? op;
    if (inflight?.clientOpId == clientOpId) {
      op = inflight;
      inflight = null;
    } else {
      final i = _buffer.indexWhere((b) => b.clientOpId == clientOpId);
      if (i >= 0) op = _buffer.removeAt(i);
    }
    _durable.remove(clientOpId);
    _maybeSent.remove(clientOpId);
    return op;
  }

  void _promote() {
    if (inflight == null && _buffer.isNotEmpty) {
      inflight = _buffer.removeAt(0);
      _sentOnThisConnection = null;
    }
    _sendIfReady();
  }

  void _sendIfReady() {
    final op = inflight;
    if (op == null || !connected || _sentOnThisConnection == op.clientOpId) {
      return;
    }
    if (!_durable.contains(op.clientOpId)) return;
    _sentOnThisConnection = op.clientOpId;
    _maybeSent.add(op.clientOpId);
    host.sendOp(op);
  }

  void _requestGap(int from, int to) {
    if (to < from) return;
    _gapRequestedAt = _now();
    host.requestOps(from, to);
  }

  static List<RowChange> _withoutBefore(List<RowChange> changes) => [
    for (final c in changes)
      switch (c.op) {
        RowOp.update => RowChange.update(
          c.table,
          c.rowId,
          const {},
          c.columnsAfter,
        ),
        _ => c,
      },
  ];
}

/// Debug view of [RevSyncCore] internals (tests).
extension RevSyncCoreDebug on RevSyncCore {
  /// Durable / sent flags of the in-flight op.
  String get debugState =>
      'durable=${_durable.contains(inflight?.clientOpId)} sentHere=$_sentOnThisConnection '
      'queue=${_queue.keys.toList()} gapAt=$_gapRequestedAt';
}
