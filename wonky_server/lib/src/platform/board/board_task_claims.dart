import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'board_access.dart';
import 'board_comments.dart';
import 'board_common.dart';
import 'board_config.dart';
import 'board_notify.dart';
import 'board_views.dart';

import 'board_tasks.dart';

/// Claims of board tasks (specs/16 §13.7): claim with a code, release,
/// expiry and the expiry warning.
abstract final class BoardTaskClaims {
  static Future<BoardTaskView> claim(Session session, int number) async {
    final c = await BoardAccess.requireWriter(session);
    await BoardAccess.task(session, c, number);
    final config = BoardConfig.current;
    final now = nowUtc();
    final (task, expiredClaimant) = await session.db.transaction((tx) async {
      final task = await BoardTask.db.findById(
        session,
        number,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (task == null) throw Errors.notFound('Task');
      final valid = BoardViews.claimValid(task, now);
      if (valid && task.claimedById == c.id) return (task, null);
      final status = BoardViews.effectiveStatus(task, now);
      if (status == BoardTaskStatus.claimed ||
          status == BoardTaskStatus.inReview) {
        throw Errors.conflict('This task is already claimed.');
      }
      if (status != BoardTaskStatus.published) {
        throw Errors.conflict('Only published tasks can be claimed.');
      }
      final active = await BoardTask.db.count(
        session,
        where: (t) =>
            t.claimedById.equals(c.id) &
            t.status.equals(BoardTaskStatus.claimed) &
            (t.claimExpiresAt > now) &
            t.id.notEquals(task.id!),
        transaction: tx,
      );
      if (active >= config.maxActiveClaimsPerUser) {
        throw Errors.limit(
          'You can hold ${config.maxActiveClaimsPerUser} claims at a time. '
          'Finish or release one first.',
        );
      }
      final expired = task.status == BoardTaskStatus.claimed
          ? task.claimedById
          : null;
      if (task.status == BoardTaskStatus.claimed) {
        await BoardComments.systemRow(
          session,
          taskId: task.id,
          event: 'expired',
          actorId: task.claimedById,
          transaction: tx,
        );
      }
      final updated = await BoardTask.db.updateRow(
        session,
        task.copyWith(
          status: BoardTaskStatus.claimed,
          claimedById: c.id,
          claimedAt: now,
          claimExpiresAt: now.add(config.claimDuration),
          claimWarnedAt: null,
          claimCode: BoardTasks.newClaimCode(),
        ),
        transaction: tx,
        columns: (t) => [
          t.status,
          t.claimedById,
          t.claimedAt,
          t.claimExpiresAt,
          t.claimWarnedAt,
          t.claimCode,
        ],
      );
      await BoardComments.systemRow(
        session,
        taskId: task.id,
        event: 'claimed',
        actorId: c.id,
        transaction: tx,
      );
      return (updated, expired);
    });
    if (expiredClaimant != null && expiredClaimant != c.id) {
      await BoardNotify.claim(
        session,
        userId: expiredClaimant,
        task: task,
        line: _expiredLine(task),
      );
    }
    return BoardTasks.changed(session, c, task);
  }

  static String _expiredLine(BoardTask t) =>
      'Your claim on T-${t.id} ${BoardText.quoted(t.title)} expired. The '
      'task is up for grabs again.';

  static Future<BoardTaskView> release(Session session, int number) async {
    final c = await BoardAccess.requireWriter(session);
    final task = await BoardAccess.task(session, c, number);
    final now = nowUtc();
    final valid = BoardViews.claimValid(task, now);
    if (!valid) {
      if (task.status == BoardTaskStatus.claimed &&
          (c.isAdmin || c.isAuthor(task.claimedById))) {
        // Expired: shows as published already; clean up.
        return _expire(session, task, notify: false, viewer: c);
      }
      throw Errors.conflict('This task is not claimed.');
    }
    final claimant = c.isAuthor(task.claimedById);
    if (!claimant && !c.isAdmin) throw Errors.forbidden();
    // Conditional on the claim read above: a concurrent claim, PR link or
    // expiry is not overwritten with this stale row.
    final rows = await BoardTask.db.updateWhere(
      session,
      columnValues: (t) => [
        t.status(BoardTaskStatus.published),
        t.claimedById(null),
        t.claimedAt(null),
        t.claimExpiresAt(null),
        t.claimWarnedAt(null),
        t.claimCode(null),
        t.pullRequestUrl(null),
        t.prNumber(null),
        t.prAuthorLogin(null),
      ],
      where: (t) => _sameClaim(t, task),
    );
    if (rows.isEmpty) {
      throw Errors.conflict('This task changed meanwhile. Reload it.');
    }
    final updated = rows.single;
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'released',
      actorId: c.id,
    );
    if (!claimant) {
      await BoardLog.write(
        session,
        adminId: c.id,
        action: 'releaseClaim',
        targetKind: BoardTargetKind.task,
        targetId: task.id!,
        before: BoardTasks.snapshot(task),
        after: BoardTasks.snapshot(updated),
      );
      await BoardNotify.claim(
        session,
        userId: task.claimedById!,
        task: task,
        line:
            'An admin released your claim on T-${task.id} '
            '${BoardText.quoted(task.title)}.',
        actor: c.actor,
      );
    }
    await BoardTasks.syncPosts(session, task.id!, BoardTaskStatus.published);
    return BoardTasks.changed(session, c, updated);
  }

  static Future<BoardTaskView> _expire(
    Session session,
    BoardTask task, {
    required bool notify,
    BoardCaller? viewer,
  }) async {
    // Only while the claim read is still the expired one (not re-claimed,
    // released or linked to a PR meanwhile).
    final rows = await BoardTask.db.updateWhere(
      session,
      columnValues: (t) => [
        t.status(BoardTaskStatus.published),
        t.claimedById(null),
        t.claimedAt(null),
        t.claimExpiresAt(null),
        t.claimWarnedAt(null),
        t.claimCode(null),
      ],
      where: (t) =>
          _sameClaim(t, task) &
          t.status.equals(BoardTaskStatus.claimed) &
          (t.claimExpiresAt <= nowUtc()),
    );
    if (rows.isEmpty) {
      final current = await BoardTask.db.findById(session, task.id!);
      return BoardViews.task(
        session,
        viewer ?? const BoardCaller.signedOut(),
        current ?? task,
      );
    }
    final updated = rows.single;
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'expired',
      actorId: task.claimedById,
    );
    if (notify && task.claimedById != null) {
      await BoardNotify.claim(
        session,
        userId: task.claimedById!,
        task: task,
        line: _expiredLine(task),
      );
    }
    await BoardLive.task(session, task.id!);
    return BoardViews.task(
      session,
      viewer ?? const BoardCaller.signedOut(),
      updated,
    );
  }

  /// The task row [task] was read from, still with the same claim.
  static Expression<Object?> _sameClaim(BoardTaskTable t, BoardTask task) =>
      t.id.equals(task.id!) &
      t.status.equals(task.status) &
      t.claimedById.equals(task.claimedById) &
      t.claimedAt.equals(task.claimedAt);

  /// Sweep: expired claims go back to published (system row and a
  /// `boardClaim` notification). Returns the count.
  static Future<int> expireClaims(Session session) async {
    final now = nowUtc();
    final tasks = await BoardTask.db.find(
      session,
      where: (t) =>
          t.status.equals(BoardTaskStatus.claimed) & (t.claimExpiresAt <= now),
      limit: 500,
    );
    for (final t in tasks) {
      await _expire(session, t, notify: true);
    }
    return tasks.length;
  }

  /// Sweep: one reminder per claim with `claimWarnHours` or less left.
  static Future<int> warnClaims(Session session) async {
    final now = nowUtc();
    final config = BoardConfig.current;
    final tasks = await BoardTask.db.find(
      session,
      where: (t) =>
          t.status.equals(BoardTaskStatus.claimed) &
          (t.claimExpiresAt > now) &
          (t.claimExpiresAt <=
              now.add(Duration(hours: config.claimWarnHours))) &
          t.claimWarnedAt.equals(null),
      limit: 500,
    );
    for (final t in tasks) {
      await BoardTask.db.updateRow(
        session,
        t.copyWith(claimWarnedAt: now),
        columns: (c) => [c.claimWarnedAt],
      );
      final hours = (t.claimExpiresAt!.difference(now).inMinutes / 60).ceil();
      await BoardNotify.claim(
        session,
        userId: t.claimedById!,
        task: t,
        line:
            'Your claim on T-${t.id} ${BoardText.quoted(t.title)} expires in '
            '$hours ${hours == 1 ? 'hour' : 'hours'}. Link your pull request '
            'or release the task.',
      );
    }
    return tasks.length;
  }
}
