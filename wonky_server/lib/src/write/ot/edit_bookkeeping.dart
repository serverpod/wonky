import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/activity/activity_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/drive/drive_service.dart';
import '../../platform/drive/drive_user_state.dart';
import '../../platform/storage/content_sizes.dart';
import '../../platform/versions/version_service.dart';
import 'document_store.dart';

/// The edits of one actor since the last flush.
class _Tally {
  _Tally(this.actor);
  Actor actor;
  int inserted = 0;
  int deleted = 0;
}

/// The bookkeeping of a document's edits — activity log, version capture
/// state, "last edited by me", the drive item's modified time, search text
/// and size — batched per document (Write 03 §2 step 8).
///
/// Ops only add to in-memory counters; [flushDelay] after the first
/// unflushed op (and whenever the document settles: a connection closes, a
/// server-side caller waits, the state is disposed) one flush writes them
/// for every actor at once, queued after the document's other side
/// effects. A flush never throws: failures are logged.
class PendingEdits {
  PendingEdits(this._enqueue);

  /// Queues work after the document's earlier side effects
  /// (`DocumentState.runSideEffect`).
  final Future<void> Function(Future<void> Function() work) _enqueue;

  /// How long edits wait before they are written (tests change it).
  static Duration flushDelay = const Duration(seconds: 5);

  /// Throttles of the drive item's modified time and search text, and of
  /// each user's "last edited" state.
  static const modifiedThrottle = Duration(seconds: 10);
  static const searchTextThrottle = Duration(seconds: 30);
  static const userEditThrottle = Duration(minutes: 1);

  DateTime _lastModifiedTouch = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSearchTextUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  final Map<int, DateTime> _lastUserEdit = {};

  final Map<(int, ActorKind), _Tally> _tallies = {};
  Session? _session;
  int? _lastUserId;
  DriveItem? _item;
  int _revision = 0;
  Delta? _after;
  Timer? _timer;

  /// Number of flushes that wrote something (tests).
  int flushes = 0;

  bool get isEmpty => _tallies.isEmpty;

  /// Counts one committed op of [actor] (no database work).
  void add(
    Session session,
    DriveItem item,
    Actor actor, {
    required Delta op,
    required int revision,
    required Delta after,
  }) {
    final tally = _tallies.putIfAbsent(
      (actor.userId, actor.kind),
      () => _Tally(actor),
    )..actor = actor;
    for (final o in op.toList()) {
      if (o.isInsert) tally.inserted += o.length!;
      if (o.isDelete) tally.deleted += o.length!;
    }
    _session = session;
    _lastUserId = actor.userId;
    _item = item;
    if (revision > _revision) {
      _revision = revision;
      _after = after;
    }
    _timer ??= Timer(flushDelay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  /// Queues a write of everything pending; the future completes when it
  /// ran (immediately when nothing is pending).
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_tallies.isEmpty) return Future.value();
    final tallies = [..._tallies.values];
    _tallies.clear();
    final session = _session!;
    final item = _item!;
    final revision = _revision;
    final after = _after!;
    final lastUserId = _lastUserId;
    return _enqueue(
      () => _write(session, item, tallies, revision, after, lastUserId),
    );
  }

  /// Drops pending edits without writing them (the document was deleted).
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _tallies.clear();
  }

  Future<void> _write(
    Session session,
    DriveItem item,
    List<_Tally> tallies,
    int revision,
    Delta after,
    int? lastUserId,
  ) async {
    final now = nowUtc();
    try {
      for (final t in tallies) {
        final userId = t.actor.userId;
        final last = _lastUserEdit[userId];
        if (last == null || now.difference(last) > userEditThrottle) {
          _lastUserEdit[userId] = now;
          await DriveUserStates.recordEdit(session, userId, item);
        }
        await ActivityService.logEdit(
          session,
          item.id!,
          t.actor,
          counters: {'insertedChars': t.inserted, 'deletedChars': t.deleted},
        );
      }
      await VersionService.recordEdits(
        session,
        item,
        {for (final t in tallies) t.actor.userId},
        revision: revision,
      );
      if (now.difference(_lastModifiedTouch) > modifiedThrottle) {
        _lastModifiedTouch = now;
        final updateSearch =
            now.difference(_lastSearchTextUpdate) > searchTextThrottle;
        if (updateSearch) _lastSearchTextUpdate = now;
        await DriveService.touchModified(
          session,
          item,
          lastUserId,
          searchText: updateSearch ? DocumentStore.searchText(after) : null,
          sizeBytes: updateSearch ? DocumentSize.of(after) : null,
        );
      }
      flushes++;
    } on Object catch (e, st) {
      session.log(
        'Edit bookkeeping of item ${item.id} up to r$revision failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    }
  }
}
