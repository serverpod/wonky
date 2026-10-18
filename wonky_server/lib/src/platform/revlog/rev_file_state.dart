import 'dart:async';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'rev_binding.dart';
import 'rev_bus.dart';
import 'rev_views.dart';

/// Per-instance state of one RevLog file (RevLog spec 05 §2): the lock that
/// serializes this instance's writers, the last revision known here and a
/// ring of recent op views (catch-up and gap fills without a query). The
/// `rev_file` row lock stays authoritative across instances; the state
/// catches up from `rev_op` when it is behind.
final class RevFileState {
  RevFileState._(
    this.fileUuid,
    this.fileId,
    this.binding,
    this.revision, {
    this.itemId,
  });

  /// A state not registered in [RevFileStates]: the initial ops of a file
  /// committed inside its creation transaction (RevLog spec 05 §8.3).
  RevFileState.detached(
    this.fileUuid,
    this.fileId,
    this.binding, {
    this.itemId,
  }) : revision = 0;

  /// The file.
  final UuidValue fileUuid;

  /// `rev_file.id`.
  final int fileId;

  /// The drive item (`rev_file.itemId`, fixed for the file), when known.
  final int? itemId;

  /// The app binding.
  final RevBinding binding;

  /// Last revision known to this instance.
  int revision;

  /// Recent ops (revision order).
  final RevOpRing recent = RevOpRing();

  int _leases = 0;
  Timer? _disposeTimer;
  void Function()? _detachBus;

  void _dispose() {
    _disposeTimer?.cancel();
    _detachBus?.call();
    _detachBus = null;
  }

  Future<void> _tail = Future.value();

  /// Listeners for ops this instance learns of (connections, headless
  /// models); called in revision order.
  final List<void Function(RevOpView op)> _listeners = [];

  /// Whether the file was purged (connections close, nothing is cached).
  bool purged = false;

  /// Runs [action] exclusively for this file on this instance.
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

  /// Registers [listener] for ops after [revision]. Returns a remover.
  void Function() listen(void Function(RevOpView op) listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  /// Records a committed op (in revision order) and tells the listeners.
  void advance(RevOpView op) {
    if (op.revision != revision + 1) return;
    revision = op.revision;
    recent.add(op);
    for (final l in List.of(_listeners)) {
      try {
        l(op);
      } on Object {
        // A listener's failure never breaks the chain.
      }
    }
  }

  int _catchingUpTo = 0;
  Future<void>? _catchingUp;

  /// Makes sure the state is at [minRevision] or later when the database
  /// has it (another instance committed ops). Coalesces concurrent calls.
  Future<void> ensureAtLeast(Session session, int minRevision) {
    if (minRevision <= revision) return Future.value();
    final pending = _catchingUp;
    if (pending != null && minRevision <= _catchingUpTo) return pending;
    _catchingUpTo = minRevision;
    late final Future<void> future;
    future = lock(() => catchUp(session)).whenComplete(() {
      if (identical(_catchingUp, future)) _catchingUp = null;
    });
    _catchingUp = future;
    return future;
  }

  /// Reads the ops after [revision] up to the head from `rev_op` (call
  /// under [lock]).
  Future<void> catchUp(Session session, {Transaction? transaction}) async {
    final file = await RevFile.db.findById(
      session,
      fileId,
      transaction: transaction,
    );
    if (file == null) {
      purged = true;
      RevFileStates.evict(fileUuid);
      return;
    }
    while (revision < file.headRevision) {
      final views = await RevViews.read(
        session,
        binding.codec,
        fileId,
        revision + 1,
        file.headRevision,
        transaction: transaction,
      );
      if (views.isEmpty) break;
      for (final v in views) {
        if (v.revision == revision + 1) {
          advance(v);
        } else if (v.revision > revision + 1) {
          // Pruned ops (no payload): nothing to replay, jump.
          revision = v.revision - 1;
          advance(v);
        }
      }
    }
    if (revision < file.headRevision) revision = file.headRevision;
  }
}

/// Recent op views kept in memory: ≤ [maxOps] ops and ≤ [maxBytes] of
/// payload (bigger payloads are fetched from `rev_op` when needed).
final class RevOpRing {
  /// Max ops kept.
  static const maxOps = 1000;

  /// Max payload bytes kept.
  static const maxBytes = 32 << 20;

  final List<RevOpView> _ops = [];
  int _bytes = 0;

  /// The kept ops in revision order.
  List<RevOpView> get ops => List.unmodifiable(_ops);

  /// Adds [op].
  void add(RevOpView op) {
    _ops.add(op);
    _bytes += _size(op);
    while (_ops.length > maxOps || _bytes > maxBytes) {
      _bytes -= _size(_ops.removeAt(0));
    }
  }

  static int _size(RevOpView op) =>
      (op.payload?.length ?? 0) + (op.payloadGz?.lengthInBytes ?? 0);

  /// The ops in [from, to] when all of them are kept, else null.
  List<RevOpView>? range(int from, int to) {
    if (from > to) return const [];
    if (_ops.isEmpty || _ops.first.revision > from || _ops.last.revision < to) {
      return null;
    }
    final start = from - _ops.first.revision;
    return _ops.sublist(start, start + (to - from + 1));
  }
}

/// A user of a [RevFileState] (connection, server change, headless entry).
final class RevFileLease {
  RevFileLease._(this.state);

  /// The state.
  final RevFileState state;
  bool _released = false;

  /// Ends the use; disposes the state 60 s after the last lease.
  void release() {
    if (_released) return;
    _released = true;
    RevFileStates._release(state);
  }
}

/// Registry of the [RevFileState]s of this instance.
abstract final class RevFileStates {
  static final Map<String, RevFileState> _states = {};
  static final Map<String, Future<RevFileState>> _loading = {};

  /// Variable for tests.
  static Duration disposeAfter = const Duration(seconds: 60);

  /// The state of [fileUuid] (loaded on first use), or null when the file
  /// doesn't exist.
  static Future<RevFileState?> of(
    Session session,
    RevBinding binding,
    UuidValue fileUuid,
  ) async {
    final key = fileUuid.uuid;
    final existing = _states[key];
    if (existing != null) return _touch(existing);
    final loading = _loading[key];
    if (loading != null) return _touch(await loading);
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null) return null;
    if (file.kind != binding.kind) return null;
    final future = () async {
      final state = RevFileState._(
        fileUuid,
        file.id!,
        binding,
        file.headRevision,
        itemId: file.itemId,
      );
      state._detachBus = RevBus.attach(session.serverpod, state);
      _states[key] = state;
      _touch(state);
      return state;
    }();
    _loading[key] = future;
    try {
      return await future;
    } finally {
      _loading.removeWhere((k, _) => k == key);
    }
  }

  /// Starts a use of [state] (it stays cached until released).
  static RevFileLease retain(RevFileState state) {
    state._leases++;
    state._disposeTimer?.cancel();
    state._disposeTimer = null;
    return RevFileLease._(state);
  }

  static void _release(RevFileState state) {
    state._leases--;
    _touch(state);
  }

  static RevFileState _touch(RevFileState state) {
    if (state._leases > 0) return state;
    state._disposeTimer?.cancel();
    state._disposeTimer = Timer(disposeAfter, () {
      final key = state.fileUuid.uuid;
      if (state._leases <= 0 && identical(_states[key], state)) {
        _states.remove(key);
        state._dispose();
      }
    });
    return state;
  }

  /// The cached state of [fileUuid], if any (bus delivery).
  static RevFileState? cached(UuidValue fileUuid) => _states[fileUuid.uuid];

  /// Drops the cached state (purge, tests). Holders keep their copy.
  static void evict(UuidValue fileUuid) {
    _states.remove(fileUuid.uuid)?._dispose();
  }

  /// Drops everything (tests).
  static void clear() {
    for (final s in _states.values) {
      s._dispose();
    }
    _states.clear();
  }
}
