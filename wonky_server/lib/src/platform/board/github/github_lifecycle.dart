import 'package:serverpod/serverpod.dart';

import '../../common/models.dart';
import '../../common/time.dart';
import '../board_comments.dart';
import '../board_common.dart';
import '../board_config.dart';
import '../board_notify.dart';
import '../board_tasks.dart';
import 'board_github.dart';
import 'github_gate.dart';

/// What GitHub events do to linked tasks (specs/16 §13.6): merged → done,
/// closed → released, reopened → the gate re-runs, a successful deploy
/// that contains the merge → shipped.
abstract final class GithubLifecycle {
  /// The linked task of PR [prNumber] (inReview with this PR).
  static Future<BoardTask?> _linkedTask(Session session, int prNumber) =>
      BoardTask.db.findFirstRow(
        session,
        where: (t) =>
            t.prNumber.equals(prNumber) &
            t.status.inSet({BoardTaskStatus.inReview, BoardTaskStatus.done}),
      );

  static Future<void> onClosed(Session session, GithubPrEvent pr) async {
    final now = nowUtc();
    final row = await BoardPullRequest.db.findFirstRow(
      session,
      where: (t) => t.prNumber.equals(pr.number),
    );
    if (row != null) {
      await BoardPullRequest.db.updateRow(
        session,
        row.copyWith(
          state: pr.merged ? 'merged' : 'closed',
          mergeCommitSha: pr.merged ? pr.mergeCommitSha : row.mergeCommitSha,
          reviewPendingSha: null,
          reviewDueAt: null,
          updatedAt: now,
        ),
        columns: (t) => [
          t.state,
          t.mergeCommitSha,
          t.reviewPendingSha,
          t.reviewDueAt,
          t.updatedAt,
        ],
      );
    }
    final task = await _linkedTask(session, pr.number);
    if (task == null) return;
    if (pr.merged) {
      await _merged(session, task, pr);
    } else if (task.status == BoardTaskStatus.inReview) {
      await _released(session, task, pr);
    }
  }

  static Future<void> _merged(
    Session session,
    BoardTask task,
    GithubPrEvent pr,
  ) async {
    if (task.status == BoardTaskStatus.done) {
      // Marked done by an admin before the merge: remember the commit.
      if (task.mergeCommitSha == null && pr.mergeCommitSha != null) {
        await BoardTask.db.updateRow(
          session,
          task.copyWith(mergeCommitSha: pr.mergeCommitSha),
          columns: (t) => [t.mergeCommitSha],
        );
      }
      return;
    }
    final now = nowUtc();
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: BoardTaskStatus.done,
        doneAt: task.doneAt ?? now,
        mergeCommitSha: pr.mergeCommitSha,
      ),
      columns: (t) => [t.status, t.doneAt, t.mergeCommitSha],
    );
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'done',
      actorId: task.claimedById,
      body: GithubGate.prUrl(pr.number),
    );
    final posts = await BoardTasks.followTaskStatus(
      session,
      task.id!,
      BoardTaskStatus.done,
    );
    for (final p in posts) {
      await BoardNotify.postStatus(
        session,
        p,
        'Built: ${BoardText.quoted(p.title)} was built and ships with the '
        'next release.',
      );
    }
    await BoardLive.task(session, updated.id!);
  }

  static Future<void> _released(
    Session session,
    BoardTask task,
    GithubPrEvent pr,
  ) async {
    await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: BoardTaskStatus.published,
        claimedById: null,
        claimedAt: null,
        claimExpiresAt: null,
        claimWarnedAt: null,
        claimCode: null,
        pullRequestUrl: null,
        prNumber: null,
        prAuthorLogin: null,
      ),
      columns: (t) => [
        t.status,
        t.claimedById,
        t.claimedAt,
        t.claimExpiresAt,
        t.claimWarnedAt,
        t.claimCode,
        t.pullRequestUrl,
        t.prNumber,
        t.prAuthorLogin,
      ],
    );
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'prClosed',
      actorId: task.claimedById,
      body: GithubGate.prUrl(pr.number),
    );
    await BoardTasks.followTaskStatus(
      session,
      task.id!,
      BoardTaskStatus.published,
    );
    if (task.claimedById != null) {
      await BoardNotify.claim(
        session,
        userId: task.claimedById!,
        task: task,
        line:
            'Your PR was closed; T-${task.id} ${BoardText.quoted(task.title)} '
            'is open again.',
      );
    }
    await BoardLive.task(session, task.id!);
  }

  /// A reopened PR: the row is open again (the gate runs next; the old
  /// claim code was cleared when the PR closed).
  static Future<void> onReopened(Session session, GithubPrEvent pr) async {
    final row = await BoardPullRequest.db.findFirstRow(
      session,
      where: (t) => t.prNumber.equals(pr.number),
    );
    if (row == null) return;
    await BoardPullRequest.db.updateRow(
      session,
      row.copyWith(
        state: 'open',
        // Counted from the reopening, not from before the close.
        gateFirstFailedAt: null,
        updatedAt: nowUtc(),
      ),
      columns: (t) => [t.state, t.gateFirstFailedAt, t.updatedAt],
    );
  }

  /// Whether a workflow file [path] (`.github/workflows/deploy.yml`) is
  /// the deploy workflow [name].
  static bool isDeployWorkflow(String path, String name) =>
      path == name || path.endsWith('/$name');

  /// `workflow_run` completed: a successful deploy ships every done task
  /// whose merge commit it contains (compare `merge…head`: `ahead` or
  /// `identical`).
  static Future<int> onWorkflowRun(
    Session session,
    Map<dynamic, dynamic> run,
  ) async {
    final config = BoardConfig.current.github;
    if (run['conclusion'] != 'success') return 0;
    if (!isDeployWorkflow('${run['path'] ?? ''}', config.deployWorkflow)) {
      return 0;
    }
    final head = '${run['headSha'] ?? ''}';
    if (head.isEmpty) return 0;
    final tasks = await BoardTask.db.find(
      session,
      where: (t) =>
          t.status.equals(BoardTaskStatus.done) &
          t.mergeCommitSha.notEquals(null) &
          t.shippedAt.equals(null),
      orderBy: (t) => t.id,
      limit: 200,
    );
    var shipped = 0;
    for (final task in tasks) {
      final String status;
      try {
        status = await BoardGithub.api.compareStatus(
          task.mergeCommitSha!,
          head,
        );
      } on Exception catch (e) {
        session.log(
          'board.github: compare for T-${task.id} failed: $e',
          level: LogLevel.warning,
        );
        continue;
      }
      if (status != 'ahead' && status != 'identical') continue;
      await _ship(session, task, head);
      shipped++;
    }
    return shipped;
  }

  static Future<void> _ship(
    Session session,
    BoardTask task,
    String deploySha,
  ) async {
    final now = nowUtc();
    await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: BoardTaskStatus.shipped,
        shippedAt: now,
        shippedDeploySha: deploySha,
      ),
      columns: (t) => [t.status, t.shippedAt, t.shippedDeploySha],
    );
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'shipped',
      body: deploySha,
    );
    final posts = await BoardTasks.followTaskStatus(
      session,
      task.id!,
      BoardTaskStatus.shipped,
    );
    for (final p in posts) {
      await BoardNotify.postStatus(
        session,
        p,
        'Shipped: ${BoardText.quoted(p.title)} is now live on wonky.work.',
      );
    }
    await BoardLive.task(session, task.id!);
  }
}
