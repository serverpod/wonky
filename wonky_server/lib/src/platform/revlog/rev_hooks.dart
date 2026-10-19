import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';

import '../cluster/cluster.dart';
import '../common/lru_map.dart';
import '../common/models.dart';
import 'rev_binding.dart';
import 'rev_views.dart';

/// A durable post-commit hook (RevLog spec 05 §6): runs at least once for
/// every op it [wants], in revision order, after the op is committed.
abstract class RevHook {
  /// Stable id (key in `rev_hook_state.cursorsJson`).
  String get id;

  /// Cheap filter.
  bool wants(RevOpRecord op) => true;

  /// Runs on [ops] (revision order, ≤ [RevHooks.batchSize]).
  Future<void> run(RevHookContext ctx, List<RevOpRecord> ops);

  /// Throttle: a hook that ran less than this ago waits (trailing run).
  Duration get minInterval => Duration.zero;
}

/// A committed op as hooks see it.
final class RevOpRecord {
  RevOpRecord._(this.op, this._codec);

  /// The `rev_op` row.
  final RevOp op;
  final RevCodec _codec;
  List<RowChange>? _applied;

  /// Revision.
  int get revision => op.revision;

  /// The applied form (with `before`); empty when pruned.
  List<RowChange> get applied {
    final payload = op.payload;
    if (payload == null) return const [];
    return _applied ??= RevViews.decodeStored(_codec, payload);
  }

  /// The summary JSON, decoded.
  Map<String, Object?> get summary {
    final s = op.summaryJson;
    if (s == null || s.isEmpty) return const {};
    return (jsonDecode(s) as Map).cast<String, Object?>();
  }
}

/// What a hook run gets.
final class RevHookContext {
  RevHookContext._(this.session, this.binding, this.file, this.item);

  /// A session of the drain (closed after it).
  final Session session;

  /// The binding.
  final RevBinding binding;

  /// The file.
  final RevFile file;

  /// The drive item (null when it was deleted meanwhile).
  final DriveItem? item;
}

/// The hook runner (RevLog spec 05 §6.1).
abstract final class RevHooks {
  /// Ops per drain round.
  static const batchSize = 200;

  /// Debounce of [kick] per file (`hookDebounceMs`). Variable for tests.
  static Duration debounce = const Duration(seconds: 1);

  /// Lease of a drain, renewed per round (`hookLeaseSeconds`).
  static Duration lease = const Duration(seconds: 60);

  /// Max retry backoff (`hookRetryMaxSeconds`).
  static Duration maxBackoff = const Duration(minutes: 10);

  static final Map<int, Timer> _timers = {};
  static final Map<int, Future<void>> _running = {};

  /// Last run per (file, hook) for `minInterval` (bounded, CQ-32).
  static final LruMap<(int, String), DateTime> _lastRun = LruMap(50000);

  /// Registered bindings by file kind (drains started by jobs).
  static final Map<RevFileKind, RevBinding> bindings = {};

  /// Schedules a drain of [fileId] after [debounce].
  static void kick(Serverpod pod, RevBinding binding, int fileId) {
    if (binding.hooks.isEmpty) return;
    _timers[fileId]?.cancel();
    _timers[fileId] = Timer(debounce, () {
      _timers.remove(fileId);
      unawaited(drainNow(pod, binding, fileId));
    });
  }

  /// Drains [fileId] now (tests, jobs) on [session], or on a new session
  /// of [pod]. Concurrent calls share one drain.
  static Future<void> drainNow(
    Serverpod pod,
    RevBinding binding,
    int fileId, {
    Session? session,
  }) {
    final running = _running[fileId];
    if (running != null) return running;
    final future = _drain(pod, binding, fileId, session).whenComplete(() {
      // A block body: `remove` returns this future, and whenComplete
      // would wait for it (a drain waiting for itself).
      unawaited(_running.remove(fileId));
    });
    _running[fileId] = future;
    return future;
  }

  /// Cancels scheduled drains and waits for running ones (tests).
  static Future<void> idle() async {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    await Future.wait(_running.values.toList());
  }

  static Future<void> _drain(
    Serverpod pod,
    RevBinding binding,
    int fileId,
    Session? given,
  ) async {
    final session = given ?? await pod.createSession(enableLogging: false);
    try {
      while (await _round(session, binding, fileId)) {}
    } on Object catch (e, st) {
      session.log(
        'Hooks of file $fileId failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    } finally {
      await _releaseLease(session, fileId);
      if (given == null) await session.close();
    }
  }

  /// One round; returns whether more ops wait.
  static Future<bool> _round(
    Session session,
    RevBinding binding,
    int fileId,
  ) async {
    final got = await session.db.unsafeExecute(
      'UPDATE rev_hook_state SET "leaseOwner" = @me, '
      '"leaseUntil" = now() + make_interval(secs => @secs) '
      'WHERE "fileId" = @f AND ("leaseUntil" IS NULL OR "leaseUntil" < now() '
      'OR "leaseOwner" = @me)',
      parameters: QueryParameters.named({
        'me': Cluster.instanceId,
        'f': fileId,
        'secs': lease.inSeconds,
      }),
    );
    if (got == 0) return false;
    final leased = await session.db.unsafeQuery(
      'SELECT "cursorsJson" FROM rev_hook_state WHERE "fileId" = @f',
      parameters: QueryParameters.named({'f': fileId}),
    );
    if (leased.isEmpty) return false;
    final file = await RevFile.db.findById(session, fileId);
    if (file == null || file.purging) return false;
    final cursors = (jsonDecode(leased.first[0]! as String) as Map).map(
      (k, v) => MapEntry(k as String, (v as num).toInt()),
    );
    final hooks = binding.hooks;
    // A hook added later starts at the head (no backfill).
    for (final h in hooks) {
      cursors.putIfAbsent(h.id, () => file.headRevision);
    }
    final from = hooks.map((h) => cursors[h.id]!).fold(file.headRevision, min);
    if (from >= file.headRevision) {
      await _save(session, fileId, cursors, null);
      return false;
    }
    final rows = await RevOp.db.find(
      session,
      where: (t) => t.fileId.equals(fileId) & (t.revision > from),
      orderBy: (t) => t.revision,
      limit: batchSize,
    );
    if (rows.isEmpty) return false;
    final ops = [for (final r in rows) RevOpRecord._(r, binding.codec)];
    final item = await DriveItem.db.findById(session, file.itemId);
    final ctx = RevHookContext._(session, binding, file, item);
    String? error;
    var deferred = false;
    for (final hook in hooks) {
      final cursor = cursors[hook.id]!;
      final mine = [
        for (final o in ops)
          if (o.revision > cursor) o,
      ];
      if (mine.isEmpty) continue;
      final last = _lastRun.get((fileId, hook.id));
      if (last != null && clock.now().difference(last) < hook.minInterval) {
        deferred = true;
        continue;
      }
      final wanted = [
        for (final o in mine)
          if (hook.wants(o)) o,
      ];
      try {
        if (wanted.isNotEmpty) {
          await hook.run(ctx, wanted);
          _lastRun.put((fileId, hook.id), clock.now());
        }
        cursors[hook.id] = mine.last.revision;
      } on Object catch (e, st) {
        error = '${hook.id}: $e';
        session.log(
          'Hook ${hook.id} of file ${file.fileUuid.uuid} failed: $e',
          level: LogLevel.error,
          stackTrace: st,
        );
      }
    }
    await _save(session, fileId, cursors, error);
    if (deferred) {
      // Trailing run of throttled hooks.
      final wait = hooks.map((h) => h.minInterval).fold(Duration.zero, _max);
      Timer(wait, () => kick(session.serverpod, binding, fileId));
    }
    if (error != null) return false;
    final lowest = hooks
        .map((h) => cursors[h.id]!)
        .fold(file.headRevision, min);
    return !deferred && lowest < file.headRevision;
  }

  static Duration _max(Duration a, Duration b) => a > b ? a : b;

  static Future<void> _save(
    Session session,
    int fileId,
    Map<String, int> cursors,
    String? error,
  ) async {
    final state = await RevHookState.db.findFirstRow(
      session,
      where: (t) => t.fileId.equals(fileId),
    );
    if (state == null) return;
    final attempts = error == null ? 0 : state.attempts + 1;
    final backoff = error == null
        ? null
        : Duration(
            milliseconds: min(
              maxBackoff.inMilliseconds,
              2000 * (1 << min(attempts, 20)),
            ),
          );
    await session.db.unsafeExecute(
      'UPDATE rev_hook_state SET "cursorsJson" = @c::text, attempts = @a::bigint, '
      '"lastError" = @e::text, "nextAttemptAt" = @n::timestamp, '
      '"updatedAt" = now() '
      'WHERE "fileId" = @f',
      parameters: QueryParameters.named({
        'c': jsonEncode(cursors),
        'a': attempts,
        'e': error,
        'n': backoff == null ? null : clock.now().toUtc().add(backoff),
        'f': fileId,
      }),
    );
  }

  static Future<void> _releaseLease(Session session, int fileId) async {
    try {
      await session.db.unsafeExecute(
        'UPDATE rev_hook_state SET "leaseOwner" = NULL, "leaseUntil" = NULL '
        'WHERE "fileId" = @f AND "leaseOwner" = @me',
        parameters: QueryParameters.named({
          'f': fileId,
          'me': Cluster.instanceId,
        }),
      );
    } on Object {
      // The lease expires on its own.
    }
  }

  /// The initial cursors JSON of a new file's hook state.
  static String initialCursors(RevBinding binding) =>
      jsonEncode({for (final h in binding.hooks) h.id: 0});
}
