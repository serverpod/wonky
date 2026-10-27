import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/common/models.dart';
import 'cell_upgrader.dart';
import 'document_store.dart';
import 'edit_bookkeeping.dart';

/// A recently applied op kept in memory.
class CachedOp {
  CachedOp(this.revision, this.delta);
  final int revision;
  final Delta delta;
}

/// In-memory state of one document on this server instance (Write 03 §2):
/// head content, recent ops (last 1,000) and overlay counts. Shared by all
/// connections of the document on this instance; disposed 60 s after the
/// last one leaves, or 60 s after its last headless use (MCP, AI, restores)
/// when no connection retains it. The database row lock stays
/// authoritative across instances, so the state catches up from the op log
/// when it is behind.
class DocumentState {
  DocumentState._(
    this.documentUuid,
    this.documentId,
    this.content,
    this.revision,
  ) : overlays = OverlayIndex()..reset(content);

  final UuidValue documentUuid;
  final int documentId;
  Delta content;
  int revision;
  final OverlayIndex overlays;
  final List<CachedOp> recent = [];
  int connections = 0;
  Timer? _disposeTimer;

  /// Activity, version and drive bookkeeping of committed ops, batched and
  /// written a few seconds later (Write 03 §2 step 8).
  late final PendingEdits edits = PendingEdits(runSideEffect);

  Future<void> _tail = Future.value();

  /// Post-commit side effects (activity, versions, drive bookkeeping,
  /// overlay lifecycle, snapshots), run one after the other outside [lock]
  /// so the next op of the document doesn't wait for them (Write 03 §2).
  Future<void> _effects = Future.value();

  static const maxRecent = 1000;

  /// Upgrades of legacy table and grid embeds ([CellUpgrader]), run one
  /// after the other outside [lock] and outside the side effects (an
  /// upgrade commits an op, which queues side effects of its own).
  Future<void> _upgrades = Future.value();

  /// The legacy embeds of this document cannot be upgraded (the upgrade was
  /// rejected): no further attempts while the state is cached.
  bool upgradeBlocked = false;

  /// Queues [work] after the earlier upgrades of this document. The
  /// returned future completes when [work] is done; its errors are passed
  /// on to it but never break the queue.
  Future<void> runUpgrade(Future<void> Function() work) {
    final done = _upgrades.then((_) => work());
    _upgrades = done.catchError((Object _) {});
    return done;
  }

  /// Queues [work] after the side effects of earlier ops of this document.
  /// The returned future completes when [work] is done; its errors are
  /// passed on to it but never break the queue.
  Future<void> runSideEffect(Future<void> Function() work) {
    final done = _effects.then((_) => work());
    _effects = done.catchError((Object _) {});
    return done;
  }

  /// Writes the pending edit bookkeeping now and completes when every
  /// upgrade and side effect queued so far has run (the side effects
  /// queued by those upgrades included).
  Future<void> settle() async {
    unawaited(edits.flush());
    await _upgrades;
    await _effects;
  }

  /// Runs [action] exclusively for this document on this instance.
  Future<T> lock<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  void remember(int revision, Delta delta) {
    recent.add(CachedOp(revision, delta));
    if (recent.length > maxRecent) {
      recent.removeRange(0, recent.length - maxRecent);
    }
  }

  /// Cached ops after [fromRevision] up to the head, or null when not all
  /// of them are cached.
  List<Delta>? opsSince(int fromRevision) {
    if (fromRevision >= revision) return const [];
    if (recent.isEmpty || recent.first.revision > fromRevision + 1) return null;
    return [
      for (final op in recent)
        if (op.revision > fromRevision) op.delta,
    ];
  }

  /// The revision a pending [ensureAtLeast] catches up to.
  int _catchingUpTo = 0;
  Future<void>? _catchingUp;

  /// Makes sure the state is at [minRevision] or later when the database
  /// has it: another instance committed ops that this instance only saw on
  /// the bus (or not at all). Coalesces concurrent calls.
  Future<void> ensureAtLeast(Session session, int minRevision) {
    if (minRevision <= revision) return Future.value();
    final pending = _catchingUp;
    if (pending != null && minRevision <= _catchingUpTo) return pending;
    _catchingUpTo = minRevision;
    late final Future<void> future;
    future =
        lock(() async {
          if (minRevision <= revision) return;
          final fresh = await Document.db.findById(session, documentId);
          if (fresh == null) {
            // Deleted (purged): don't keep it cached.
            DocumentCache.evict(documentUuid, deleted: true);
            return;
          }
          await catchUp(session, fresh.headRevision);
        }).whenComplete(() {
          if (identical(_catchingUp, future)) _catchingUp = null;
        });
    _catchingUp = future;
    return future;
  }

  /// Brings the state up to [headRevision] from the op log (another
  /// instance committed ops).
  Future<void> catchUp(
    Session session,
    int headRevision, {
    Transaction? transaction,
  }) async {
    if (headRevision <= revision) return;
    final ops = await DocumentOp.db.find(
      session,
      where: (t) =>
          t.documentId.equals(documentId) &
          (t.revision > revision) &
          (t.revision <= headRevision),
      orderBy: (t) => t.revision,
      transaction: transaction,
    );
    if (ops.length != headRevision - revision) {
      final doc = await Document.db.findById(
        session,
        documentId,
        transaction: transaction,
      );
      content = await DocumentStore.head(
        session,
        doc!,
        transaction: transaction,
      );
      revision = doc.headRevision;
      overlays.reset(content);
      recent.clear();
      return;
    }
    for (final op in ops) {
      final delta = DocumentStore.decodeDelta(op.deltaJson);
      overlays.apply(delta, DocumentStore.decodeDelta(op.inverseJson));
      content = WonkyOt.apply(content, delta);
      revision = op.revision;
      remember(op.revision, delta);
    }
  }
}

/// Registry of [DocumentState]s of this instance.
abstract final class DocumentCache {
  static final Map<String, DocumentState> _states = {};
  static final Map<String, Future<DocumentState>> _loading = {};

  /// Variable for tests.
  static Duration disposeAfter = const Duration(seconds: 60);

  /// The state of [doc], loading it on first use. A state that nothing
  /// retains (headless use) is disposed [disposeAfter] after the last call.
  static Future<DocumentState> of(Session session, Document doc) async {
    final key = doc.uuid.uuid;
    final existing = _states[key];
    if (existing != null) return _touch(existing);
    final loading = _loading[key];
    if (loading != null) return _touch(await loading);
    final future = () async {
      final content = await DocumentStore.head(session, doc);
      final state = DocumentState._(
        doc.uuid,
        doc.id!,
        content,
        doc.headRevision,
      );
      final ops = await DocumentOp.db.find(
        session,
        where: (t) =>
            t.documentId.equals(doc.id!) &
            (t.revision > doc.headRevision - 200),
        orderBy: (t) => t.revision,
      );
      for (final op in ops) {
        state.remember(op.revision, DocumentStore.decodeDelta(op.deltaJson));
      }
      _states[key] = state;
      _touch(state);
      // Legacy table and grid embeds are upgraded before the state is
      // handed out (Write 12 §1.5); the upgrade's own submit finds the
      // state registered above. Never throws.
      if (CellUpgrade.hasLegacy(content)) {
        await CellUpgrader.schedule(session, doc, state);
      }
      return state;
    }();
    _loading[key] = future;
    try {
      return await future;
    } finally {
      _loading.removeWhere((k, _) => k == key);
    }
  }

  /// A connection (or a multi-step headless use) starts using [state].
  static void retain(DocumentState state) {
    state.connections++;
    state._disposeTimer?.cancel();
    state._disposeTimer = null;
  }

  /// A user of [state] stopped; disposes it after [disposeAfter] when it
  /// was the last one.
  static void release(DocumentState state) {
    state.connections--;
    _touch(state);
  }

  /// (Re)starts the dispose timer of [state] when nothing retains it.
  static DocumentState _touch(DocumentState state) {
    if (state.connections > 0) return state;
    state._disposeTimer?.cancel();
    state._disposeTimer = Timer(disposeAfter, () {
      final key = state.documentUuid.uuid;
      if (state.connections <= 0 && identical(_states[key], state)) {
        _states.remove(key);
        // Normally empty (connections and server-side callers settle).
        unawaited(state.edits.flush());
      }
    });
    return state;
  }

  /// Whether a state of [documentUuid] is cached on this instance (tests).
  static bool isCached(UuidValue documentUuid) =>
      _states.containsKey(documentUuid.uuid);

  /// Writes the pending edit bookkeeping of [documentUuid] and completes
  /// when its side effects queued so far have run (tests, callers that
  /// read their results).
  static Future<void> settle(UuidValue documentUuid) =>
      _states[documentUuid.uuid]?.settle() ?? Future.value();

  /// Drops the cached state (document deleted or purged, tests).
  /// Connections still holding it keep working on their copy. The pending
  /// edit bookkeeping is written, or dropped when the document was
  /// [deleted].
  static void evict(UuidValue documentUuid, {bool deleted = false}) {
    final state = _states.remove(documentUuid.uuid);
    if (state == null) return;
    state._disposeTimer?.cancel();
    if (deleted) {
      state.edits.cancel();
    } else {
      unawaited(state.edits.flush());
    }
  }

  static void clear() {
    for (final s in _states.values) {
      s._disposeTimer?.cancel();
      s.edits.cancel();
    }
    _states.clear();
  }
}
