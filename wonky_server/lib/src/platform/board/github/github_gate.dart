import 'package:serverpod/serverpod.dart';

import '../../common/models.dart';
import '../../common/time.dart';
import '../../notifications/notification_service.dart';
import '../board_comments.dart';
import '../board_common.dart';
import '../board_config.dart';
import '../board_notify.dart';
import '../board_tasks.dart';
import '../board_views.dart';
import 'board_github.dart';
import 'github_review.dart';
import 'github_webhook.dart';

/// The `Wonky-Task` and `Wonky-Claim` lines of a PR description.
class GateLines {
  const GateLines({required this.tasks, required this.claims});

  /// Task numbers, one per `Wonky-Task` line.
  final List<int> tasks;

  /// Normalized claim codes (`XXXX-XXXX`), one per `Wonky-Claim` line.
  final List<String> claims;
}

/// The outcome of the gate for one PR.
class GateDecision {
  const GateDecision._({
    required this.state,
    required this.reason,
    required this.title,
    required this.problem,
    this.task,
    this.linkedPr,
  });

  factory GateDecision.fail(
    String reason,
    String title,
    String problem, {
    BoardTask? task,
    int? linkedPr,
  }) => GateDecision._(
    state: GithubGate.failed,
    reason: reason,
    title: title,
    problem: problem,
    task: task,
    linkedPr: linkedPr,
  );

  /// `passed`, `failed` or `exempt`.
  final String state;

  /// A short code (`missingTask`, `claimInvalid`, …; null on success).
  final String? reason;

  /// The check run title.
  final String title;

  /// One or two sentences (Markdown) for the comment and the check.
  final String problem;

  /// The task named in the description (when found and visible).
  final BoardTask? task;

  /// The other open PR the task is linked to.
  final int? linkedPr;

  bool get passed => state != GithubGate.failed;
}

/// The gate check "Wonky task" (specs/16 §13.4): a PR must name exactly
/// one claimed task and the claimant's code; maintainers are exempt.
abstract final class GithubGate {
  static const checkName = 'Wonky task';
  static const marker = '<!-- wonky-task-gate -->';
  static const missingLabel = 'wonky-task-missing';

  static const passed = 'passed';
  static const failed = 'failed';
  static const exempt = 'exempt';

  static const _openStatuses = {
    BoardTaskStatus.published,
    BoardTaskStatus.claimed,
    BoardTaskStatus.inReview,
  };

  // -------------------------------------------------------------- parsing

  static final _taskLine = RegExp(
    r'^wonky-task\s*:\s*(?:t\s*-?\s*)?#?\s*(\d+)\s*\.?$',
    caseSensitive: false,
  );
  static final _claimLine = RegExp(
    r'^wonky-claim\s*:\s*([0-9a-z]{4})\s*-?\s*([0-9a-z]{4})\s*\.?$',
    caseSensitive: false,
  );

  /// Reads the lines from a PR [body]: case-insensitive, tolerant of
  /// whitespace and Markdown around the values (bold, code, quotes, list
  /// markers, links); lines inside HTML comments (the PR template's
  /// hints) are ignored.
  static GateLines parse(String body) {
    final text = body
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '');
    final tasks = <int>[];
    final claims = <String>[];
    for (final raw in text.split('\n')) {
      final line = raw
          .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
          .replaceAll(RegExp(r'[*_`~>|]'), '')
          .replaceFirst(RegExp(r'^\s*(?:[-+]\s+|\d+\.\s+|#+\s*)?'), '')
          .trim();
      final t = _taskLine.firstMatch(line);
      if (t != null) {
        tasks.add(int.parse(t[1]!));
        continue;
      }
      final c = _claimLine.firstMatch(line);
      if (c != null) claims.add(normalizeCode('${c[1]}${c[2]}'));
    }
    return GateLines(tasks: tasks, claims: claims);
  }

  /// `XXXX-XXXX` in uppercase Crockford base32 (I and L read as 1, O as 0).
  static String normalizeCode(String code) {
    final c = code
        .toUpperCase()
        .replaceAll(RegExp('[^0-9A-Z]'), '')
        .replaceAll(RegExp('[IL]'), '1')
        .replaceAll('O', '0');
    return c.length == 8 ? '${c.substring(0, 4)}-${c.substring(4)}' : c;
  }

  // --------------------------------------------------------------- links

  static Uri get _origin => NotificationService.webOrigin();

  static String taskUrl(int n) =>
      _origin.replace(path: '/improvements/t/$n').toString();

  static String get upForGrabsUrl =>
      _origin.replace(path: '/improvements/tasks').toString();

  static String get boardUrl =>
      _origin.replace(path: '/improvements').toString();

  static String get contributingUrl =>
      'https://github.com/${BoardConfig.current.repository}/blob/main/'
      'CONTRIBUTING.md';

  static String prUrl(int n) =>
      'https://github.com/${BoardConfig.current.repository}/pull/$n';

  /// [title] safe inside Markdown link text.
  static String linkText(String title) =>
      title.replaceAll(RegExp(r'[\[\]<>]'), '');

  // ------------------------------------------------------------- decision

  /// Decides the gate for [pr] (reads only; [maintainer] is the org
  /// membership of the author, asked before).
  static Future<GateDecision> decide(
    Session session,
    GithubPrEvent pr, {
    required bool maintainer,
    Transaction? transaction,
  }) async {
    final lines = parse(pr.body);
    final now = nowUtc();
    if (maintainer) {
      if (lines.tasks.length != 1) {
        return const GateDecision._(
          state: exempt,
          reason: null,
          title: 'Maintainer PR',
          problem: 'Maintainer pull request: no task needed.',
        );
      }
      final task = await _task(session, lines.tasks.single, transaction);
      final linkable =
          task != null &&
          _openStatuses.contains(task.status) &&
          await _otherOpenPr(session, task, pr.number, transaction) == null;
      return GateDecision._(
        state: exempt,
        reason: null,
        title: linkable ? 'Maintainer PR, T-${task.id}' : 'Maintainer PR',
        problem: linkable
            ? 'Maintainer pull request for '
                  '[T-${task.id}: ${linkText(task.title)}](${taskUrl(task.id!)}).'
            : 'Maintainer pull request: no task needed. '
                  'T-${lines.tasks.single} was not linked: it is not open or '
                  'already has a pull request.',
        task: linkable ? task : null,
      );
    }

    if (lines.tasks.isEmpty) {
      return GateDecision.fail(
        'missingTask',
        'No Wonky-Task line',
        'The description has no `Wonky-Task:` line, so this pull request '
            "isn't linked to a task.",
      );
    }
    if (lines.tasks.length > 1) {
      return GateDecision.fail(
        'multipleTasks',
        'More than one Wonky-Task line',
        'The description has more than one `Wonky-Task:` line. A pull '
            'request implements exactly one task.',
      );
    }
    final n = lines.tasks.single;
    final task = await _task(session, n, transaction);
    if (task == null || task.status == BoardTaskStatus.draft) {
      return GateDecision.fail(
        'taskNotFound',
        'T-$n not found',
        "T-$n doesn't exist. Pick a task on "
            '[Up for grabs]($upForGrabsUrl).',
      );
    }
    if (!_openStatuses.contains(task.status)) {
      final what = switch (task.status) {
        BoardTaskStatus.cancelled => 'was cancelled',
        BoardTaskStatus.done => 'is already done',
        _ => 'has already shipped',
      };
      return GateDecision.fail(
        'taskNotOpen',
        'T-$n is not open',
        '[T-$n](${taskUrl(n)}) $what and takes no pull requests. Pick '
            'another task on [Up for grabs]($upForGrabsUrl).',
        task: task,
      );
    }
    final other = await _otherOpenPr(session, task, pr.number, transaction);
    if (other != null) {
      return GateDecision.fail(
        'linkedElsewhere',
        'T-$n has another pull request',
        '[T-$n](${taskUrl(n)}) is already linked to pull request '
            '[#$other](${prUrl(other)}).',
        task: task,
        linkedPr: other,
      );
    }
    if (lines.claims.isEmpty) {
      return GateDecision.fail(
        'missingClaim',
        'No Wonky-Claim line',
        'The description has no `Wonky-Claim:` line. It proves that you '
            'hold the claim on [T-$n](${taskUrl(n)}).',
        task: task,
      );
    }
    if (lines.claims.length > 1) {
      return GateDecision.fail(
        'multipleClaims',
        'More than one Wonky-Claim line',
        'The description has more than one `Wonky-Claim:` line. Keep only '
            'the code of your claim on [T-$n](${taskUrl(n)}).',
        task: task,
      );
    }
    final linkedHere =
        task.status == BoardTaskStatus.inReview && task.prNumber == pr.number;
    final claimed =
        task.status == BoardTaskStatus.claimed &&
        BoardViews.claimValid(task, now);
    if (!linkedHere && !claimed) {
      return GateDecision.fail(
        'notClaimed',
        'T-$n is not claimed',
        "[T-$n](${taskUrl(n)}) isn't claimed right now (a claim lasts "
            '${BoardConfig.current.claimHours} hours). Claim it on its page, '
            'then put the new claim code in the description.',
        task: task,
      );
    }
    final code = task.claimCode;
    if (code == null) {
      // Linked to this PR by an admin without a claim: nothing to prove.
      if (linkedHere) {
        return _success(task);
      }
      return GateDecision.fail(
        'claimInvalid',
        'Claim code does not match',
        "The claim code doesn't match the current claim on "
            '[T-$n](${taskUrl(n)}).',
        task: task,
      );
    }
    if (!GithubWebhook.constantTimeEquals(lines.claims.single, code)) {
      return GateDecision.fail(
        'claimInvalid',
        'Claim code does not match',
        "The claim code doesn't match the current claim on "
            '[T-$n](${taskUrl(n)}). Copy it from the task page (it changes '
            'with every new claim).',
        task: task,
      );
    }
    return _success(task);
  }

  static GateDecision _success(BoardTask task) => GateDecision._(
    state: passed,
    reason: null,
    title: 'Linked to T-${task.id}',
    problem:
        'Linked to [T-${task.id}: ${linkText(task.title)}]'
        '(${taskUrl(task.id!)}).',
    task: task,
  );

  static Future<BoardTask?> _task(
    Session session,
    int number,
    Transaction? transaction,
  ) => BoardTask.db.findById(
    session,
    number,
    transaction: transaction,
    lockMode: transaction == null ? null : LockMode.forUpdate,
  );

  /// The other open PR [task] is linked to, if any. A PR the App has not
  /// seen (linked by an admin) counts as open.
  static Future<int?> _otherOpenPr(
    Session session,
    BoardTask task,
    int prNumber,
    Transaction? transaction,
  ) async {
    final other = task.prNumber;
    if (other == null || other == prNumber) return null;
    if (task.status != BoardTaskStatus.inReview) return null;
    final row = await BoardPullRequest.db.findFirstRow(
      session,
      where: (t) => t.prNumber.equals(other),
      transaction: transaction,
    );
    return row == null || row.state == 'open' ? other : null;
  }

  // ------------------------------------------------------------------ run

  /// Runs the gate for [pr] and applies it: the task link, the check run,
  /// the bot comment, the label and the PR row; then the review.
  static Future<void> run(Session session, GithubPrEvent pr) async {
    if (pr.state != 'open') return;
    final api = BoardGithub.api;
    final config = BoardConfig.current.github;
    final maintainer =
        pr.author.isNotEmpty &&
        await api.isOrgMember(config.maintainerOrg, pr.author);
    final now = nowUtc();

    var row = await _row(session, pr);
    final previousState = row.gateState;

    // Decide and link under the task's row lock, so a release or a second
    // PR can't slip in between.
    final (decision, linked) = await session.db.transaction((tx) async {
      final d = await decide(
        session,
        pr,
        maintainer: maintainer,
        transaction: tx,
      );
      final task = d.task;
      if (!d.passed || task == null) return (d, null);
      final linked = await _link(session, task, pr, tx);
      return (d, linked);
    });

    if (linked != null && linked.isNew) {
      await _afterLink(
        session,
        linked.task,
        pr,
        byClaimant: decision.state == passed,
      );
    }

    final task = linked?.task ?? decision.task;
    await api.createCheckRun(
      name: checkName,
      headSha: pr.headSha,
      status: 'completed',
      conclusion: decision.passed ? 'success' : 'failure',
      title: decision.title,
      summary: decision.passed
          ? decision.problem
          : '${decision.problem}\n\n${_howTo(task?.id)}',
      detailsUrl: task == null || task.status == BoardTaskStatus.draft
          ? null
          : taskUrl(task.id!),
    );

    final firstFailed = decision.passed ? null : row.gateFirstFailedAt ?? now;
    int? commentId = row.gateCommentId;
    if (!decision.passed) {
      commentId = await upsertComment(
        session,
        pr.number,
        commentId,
        marker,
        failureComment(decision, firstFailed!),
      );
      await api.addLabels(pr.number, const [missingLabel]);
    } else {
      final linkedHere = linked != null;
      // Contributors get a one-line confirmation; maintainers only when a
      // comment exists already (it failed before).
      if (commentId != null || (linkedHere && decision.state == passed)) {
        commentId = await upsertComment(
          session,
          pr.number,
          commentId,
          marker,
          '$marker\n**Wonky task:** ${decision.problem}',
        );
      }
      if (previousState == failed) {
        await api.removeLabel(pr.number, missingLabel);
      }
    }

    row = await BoardPullRequest.db.updateRow(
      session,
      row.copyWith(
        authorLogin: pr.author,
        headSha: pr.headSha,
        state: 'open',
        gateState: decision.state,
        gateReason: decision.reason,
        gateFirstFailedAt: firstFailed,
        gateCommentId: commentId,
        taskId: linked?.task.id ?? row.taskId,
        updatedAt: now,
      ),
    );

    if (decision.passed && row.taskId != null && !pr.draft) {
      await GithubReview.schedule(
        session,
        row,
        pr.headSha,
        prBody: pr.body,
      );
    }
  }

  /// The PR row (created on first sight).
  static Future<BoardPullRequest> _row(
    Session session,
    GithubPrEvent pr,
  ) async {
    final existing = await BoardPullRequest.db.findFirstRow(
      session,
      where: (t) => t.prNumber.equals(pr.number),
    );
    if (existing != null) return existing;
    final now = nowUtc();
    return BoardPullRequest.db.insertRow(
      session,
      BoardPullRequest(
        prNumber: pr.number,
        authorLogin: pr.author,
        headSha: pr.headSha,
        state: 'open',
        gateState: 'pending',
        reviewCount: 0,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  /// Links [task] to [pr] (inReview, PR fields; the claim stops
  /// expiring). Already linked: the task unchanged, `isNew` false.
  static Future<({BoardTask task, bool isNew})> _link(
    Session session,
    BoardTask task,
    GithubPrEvent pr,
    Transaction tx,
  ) async {
    if (task.status == BoardTaskStatus.inReview && task.prNumber == pr.number) {
      if (task.prAuthorLogin == pr.author) return (task: task, isNew: false);
      final updated = await BoardTask.db.updateRow(
        session,
        task.copyWith(prAuthorLogin: pr.author),
        transaction: tx,
      );
      return (task: updated, isNew: false);
    }
    final url = prUrl(pr.number);
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: BoardTaskStatus.inReview,
        prNumber: pr.number,
        pullRequestUrl: url,
        prAuthorLogin: pr.author,
      ),
      transaction: tx,
    );
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'prLinked',
      actorId: task.claimedById,
      body: url,
      transaction: tx,
    );
    return (task: updated, isNew: true);
  }

  /// After a new link: posts in step, live update and, when the claimant
  /// opened the PR ([byClaimant]; not a maintainer), their GitHub login on
  /// their board profile and a notification.
  static Future<void> _afterLink(
    Session session,
    BoardTask task,
    GithubPrEvent pr, {
    required bool byClaimant,
  }) async {
    await BoardTasks.followTaskStatus(session, task.id!, task.status);
    final claimant = task.claimedById;
    if (claimant != null && byClaimant) {
      await saveGithubLogin(session, claimant, pr.author);
      await BoardNotify.claim(
        session,
        userId: claimant,
        task: task,
        line:
            'Your pull request #${pr.number} is linked to T-${task.id} '
            '${BoardText.quoted(task.title)}. Your claim no longer expires.',
      );
    }
    await BoardLive.task(session, task.id!);
  }

  /// Stores [login] on the board profile of [userId] (specs/16 §8.1).
  static Future<void> saveGithubLogin(
    Session session,
    int userId,
    String login,
  ) async {
    if (login.isEmpty) return;
    final profile = await BoardUserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (profile == null) {
      await BoardUserProfile.db.insertRow(
        session,
        BoardUserProfile(userId: userId, githubLogin: login),
      );
    } else if (profile.githubLogin != login) {
      await BoardUserProfile.db.updateRow(
        session,
        profile.copyWith(githubLogin: login),
        columns: (t) => [t.githubLogin],
      );
    }
  }

  // ------------------------------------------------------------- comments

  /// Updates the bot comment [id] (or the one found by [marker]) with
  /// [body], or creates it. Returns its id.
  static Future<int> upsertComment(
    Session session,
    int prNumber,
    int? id,
    String marker,
    String body,
  ) async {
    final api = BoardGithub.api;
    final existing = id ?? await api.findBotComment(prNumber, marker);
    if (existing != null && await api.updateComment(existing, body)) {
      return existing;
    }
    return api.createComment(prNumber, body);
  }

  static String _howTo(int? taskNumber) {
    final n = taskNumber == null ? '12' : '$taskNumber';
    final pick = taskNumber == null
        ? 'Pick a task on [Up for grabs]($upForGrabsUrl)'
        : 'Open [T-$n](${taskUrl(taskNumber)}) (or pick another task on '
              '[Up for grabs]($upForGrabsUrl))';
    return '''
Every pull request to this repository implements one claimed task from [Bugs & improvements]($boardUrl). To link this one:

1. $pick and press **Claim this task**. A claim lasts ${BoardConfig.current.claimHours} hours and shows your claim code.
2. Put these two lines in the description of this pull request, with your values:

   ```
   Wonky-Task: T-$n
   Wonky-Claim: <your claim code>
   ```

3. Save the description. This check runs again by itself.''';
  }

  /// The failure comment.
  static String failureComment(GateDecision d, DateTime firstFailedAt) {
    final days = BoardConfig.current.github.autoCloseDays;
    final close = firstFailedAt.add(Duration(days: days));
    String two(int v) => v.toString().padLeft(2, '0');
    final date = '${close.year}-${two(close.month)}-${two(close.day)}';
    return '''
$marker
**Wonky task:** ${d.problem}

${_howTo(d.task?.status == BoardTaskStatus.draft ? null : d.task?.id)}

Pull requests without a valid task are closed after $days days (this one on $date). See [CONTRIBUTING.md]($contributingUrl).''';
  }

  // ------------------------------------------------------------ auto-close

  /// Sweep (G1): closes open PRs whose gate has failed continuously for
  /// `board.github.autoCloseDays`, with a closing comment. Returns the
  /// count.
  static Future<int> autoClose(Session session) async {
    final config = BoardConfig.current.github;
    final now = nowUtc();
    final rows = await BoardPullRequest.db.find(
      session,
      where: (t) =>
          t.state.equals('open') &
          t.gateState.equals(failed) &
          (t.gateFirstFailedAt <=
              now.subtract(Duration(days: config.autoCloseDays))),
      limit: 50,
    );
    var count = 0;
    for (final row in rows) {
      try {
        await BoardGithub.withPrLock(session, row.prNumber, () async {
          final api = BoardGithub.api;
          await api.createComment(
            row.prNumber,
            '**Wonky task:** closed because this pull request has not been '
            'linked to a claimed task for ${config.autoCloseDays} days. '
            'Claim a task on [Up for grabs]($upForGrabsUrl), add the '
            '`Wonky-Task` and `Wonky-Claim` lines to the description and '
            'reopen it: the check runs again. See '
            '[CONTRIBUTING.md]($contributingUrl).',
          );
          await api.closePullRequest(row.prNumber);
          await BoardPullRequest.db.updateRow(
            session,
            row.copyWith(state: 'closed', updatedAt: now),
          );
        });
        count++;
      } on Exception catch (e) {
        session.log(
          'board.github: auto-close of #${row.prNumber} failed: $e',
          level: LogLevel.warning,
        );
      }
    }
    return count;
  }
}
