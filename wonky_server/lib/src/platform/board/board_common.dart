import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../cluster/cluster_bus.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/rate_limiter.dart';
import '../common/time.dart';
import 'board_access.dart' show BoardCaller;
import 'board_config.dart';

/// Live channels of the board (specs/16 §7.6).
abstract final class BoardLive {
  static String postChannel(int postId) => 'board:post:$postId';
  static const tasksChannel = 'board:tasks';

  static Future<void> post(
    Session session,
    int postId, [
    BoardEventKind kind = BoardEventKind.postChanged,
  ]) => ClusterBus.post(
    session,
    postChannel(postId),
    BoardSignal(kind: kind, number: postId),
  );

  static Future<void> task(Session session, int taskId) => ClusterBus.post(
    session,
    tasksChannel,
    BoardSignal(kind: BoardEventKind.taskChanged, number: taskId),
  );
}

/// Per-user rate limits of the board (specs/16 §11), across instances
/// through the shared [RateLimiter]. Limits come from
/// `BoardConfig.current.limits` at each call.
enum BoardLimit {
  postsPerHour(Duration(hours: 1), 'posts'),
  postsPerDay(Duration(days: 1), 'posts'),
  commentsPerHour(Duration(hours: 1), 'comments'),
  votesPerHour(Duration(hours: 1), 'votes'),
  flagsPerDay(Duration(days: 1), 'flags'),
  similarPerMinute(Duration(minutes: 1), 'searches');

  const BoardLimit(this.window, this.what);

  final Duration window;
  final String what;

  int limitIn(BoardLimits l) => switch (this) {
    postsPerHour => l.postsPerHour,
    postsPerDay => l.postsPerDay,
    commentsPerHour => l.commentsPerHour,
    votesPerHour => l.votesPerHour,
    flagsPerDay => l.flagsPerDay,
    similarPerMinute => l.similarPerMinute,
  };
}

abstract final class BoardRateLimits {
  static final _limiters = <BoardLimit, RateLimiter>{};

  static RateLimiter _limiter(BoardLimit l) => _limiters[l] ??= RateLimiter(
    name: 'board:${l.name}',
    window: l.window,
  );

  /// Records a call of the signed-in [caller]; throws `limitExceeded` when
  /// over [limit]. Admins have no limits (they moderate and post in bulk).
  static Future<void> check(BoardLimit limit, BoardCaller caller) async {
    if (caller.isAdmin) return;
    final max = limit.limitIn(BoardConfig.current.limits);
    final retry = await _limiter(limit).check(caller.id, limit: max);
    if (retry == null) return;
    final minutes = (retry.inSeconds / 60).ceil().clamp(1, 24 * 60);
    throw Errors.limit(
      'Too many ${limit.what} for now. Try again in '
      '$minutes ${minutes == 1 ? 'minute' : 'minutes'}.',
      detailsJson: jsonEncode({'retryAfterSeconds': retry.inSeconds}),
    );
  }

  /// Clears the in-memory windows (tests).
  static void reset() {
    for (final l in _limiters.values) {
      l.reset();
    }
  }
}

/// Background work of the board, scheduled through [scheduler]: by default
/// a `BoardFutureCall` (tests replace it to record or run inline). The id is
/// a post id, except for [prompt] (a task id).
enum BoardJob { triage, summarize, prompt }

abstract final class BoardJobs {
  static Future<void> Function(
    Session session,
    BoardJob job,
    int id,
    Duration delay,
  )
  scheduler = _viaFutureCall;

  static Future<void> _viaFutureCall(
    Session session,
    BoardJob job,
    int id,
    Duration delay,
  ) async {
    final dispatch = session.serverpod.futureCalls.callWithDelay(delay).board;
    switch (job) {
      case BoardJob.triage:
        await dispatch.triage(id);
      case BoardJob.summarize:
        await dispatch.summarize(id);
      case BoardJob.prompt:
        await dispatch.writePrompt(id);
    }
  }

  /// Schedules [job] for [id]; false (logged) when it could not be
  /// scheduled.
  static Future<bool> schedule(
    Session session,
    BoardJob job,
    int id, {
    Duration delay = Duration.zero,
  }) async {
    try {
      await scheduler(session, job, id, delay);
      return true;
    } on Object catch (e) {
      session.log(
        'board: could not schedule ${job.name} of #$id: $e',
        level: LogLevel.warning,
      );
      return false;
    }
  }
}

/// The audit log of admin actions (specs/16 §9.2).
abstract final class BoardLog {
  static Future<BoardModerationLog> write(
    Session session, {
    required int adminId,
    required String action,
    required BoardTargetKind targetKind,
    required int targetId,
    Map<String, Object?>? before,
    Map<String, Object?>? after,
    String? reason,
    Transaction? transaction,
  }) => BoardModerationLog.db.insertRow(
    session,
    BoardModerationLog(
      adminId: adminId,
      action: action,
      targetKind: targetKind,
      targetId: targetId,
      beforeJson: before == null ? null : jsonEncode(before),
      afterJson: after == null ? null : jsonEncode(after),
      reason: reason,
      createdAt: nowUtc(),
    ),
    transaction: transaction,
  );
}

/// Shared text helpers.
abstract final class BoardText {
  static const maxBodyLength = 10000;
  static const minTitleLength = 8;
  static const maxTitleLength = 120;

  static String title(String title) {
    final t = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length < minTitleLength) {
      throw Errors.invalid(
        'The title needs at least $minTitleLength characters.',
      );
    }
    if (t.length > maxTitleLength) {
      throw Errors.invalid(
        'The title can have at most $maxTitleLength characters.',
      );
    }
    return t;
  }

  static String body(String body, {String what = 'text'}) {
    final b = body.trim();
    if (b.isEmpty) throw Errors.invalid('The $what is empty.');
    if (b.length > maxBodyLength) {
      throw Errors.invalid('The $what is too long (max 10,000 characters).');
    }
    return b;
  }

  /// Plain text of Markdown [markdown], at most [max] characters.
  static String plain(String markdown, {int max = 200}) {
    var t = markdown
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAllMapped(RegExp(r'!?\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
        .replaceAll(RegExp(r'^\s{0,3}#{1,6}\s*', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*[-*+>]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'[*_`~]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (t.length > max) t = '${t.substring(0, max - 1).trimRight()}…';
    return t;
  }

  /// “[title]” for notification lines.
  static String quoted(String title) => '“$title”';
}
