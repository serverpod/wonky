@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/board_sweep.dart';
import 'package:wonky_server/src/platform/board/github/github_client.dart';
import 'package:wonky_server/src/platform/board/github/github_gate.dart';
import 'package:wonky_server/src/platform/board/github/github_review.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../../support/test_users.dart';
import '../../../../support/wonky_serverpod.dart';
import '../../../../support/board/board_harness.dart';
import '../../../../support/board/fake_github_api.dart';
import '../../../../support/board/github_harness.dart';

void main() {
  withWonkyServerpod('Given a published task claimed by Bo', (
    sessionBuilder,
    endpoints,
  ) {
    late GithubHarness h;
    late Session session;
    late TestUser anna;
    late TestUser bo;
    late TestUser admin;
    late int task;
    late String code;
    late int pr;

    setUp(() async {
      h = GithubHarness.install();
      session = sessionBuilder.build();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      admin = await BoardHarness.admin(sessionBuilder);
      (number: task, code: code) = await GithubHarness.claimedTask(
        endpoints,
        admin: admin,
        author: anna,
        claimant: bo,
      );
      pr = GithubHarness.prNumber();
    });
    tearDown(() => h.uninstall());

    Future<BoardPullRequest> row([int? number]) async =>
        (await BoardPullRequest.db.findFirstRow(
          session,
          where: (t) => t.prNumber.equals(number ?? pr),
        ))!;

    Future<BoardTask> taskRow([int? number]) async =>
        (await BoardTask.db.findById(session, number ?? task))!;

    Future<void> open(
      String body, {
      String action = 'opened',
      String author = 'bo-dev',
      String? headSha,
      int? number,
    }) => h.deliver(
      session,
      'pull_request',
      GithubHarness.pullRequest(
        number: number ?? pr,
        action: action,
        body: body,
        author: author,
        headSha: headSha,
      ),
    );

    FakeCheckRun gate() => h.api.runsNamed(GithubGate.checkName).last;

    group('when a maintainer opens a PR', () {
      setUp(() => h.api.members.add('maintainer-ann'));

      test('without task lines then the check passes as exempt, with no '
          'comment and no label', () async {
        await open('Refactor.', author: 'maintainer-ann');

        expect(gate().conclusion, 'success');
        expect(gate().title, 'Maintainer PR');
        expect(h.api.commentsOn(pr), isEmpty);
        expect(h.api.labels[pr], isNull);
        expect((await row()).gateState, GithubGate.exempt);
        expect((await taskRow()).prNumber, isNull);
      });

      test('with a Wonky-Task line and no claim code then the task is '
          'linked', () async {
        await open('Wonky-Task: T-$task', author: 'maintainer-ann');

        final t = await taskRow();
        expect(gate().conclusion, 'success');
        expect(t.status, BoardTaskStatus.inReview);
        expect(t.prNumber, pr);
        expect(t.prAuthorLogin, 'maintainer-ann');
        expect((await row()).taskId, task);
        expect(h.reviews.single.prNumber, pr);
      });
    });

    group('when a contributor opens a PR', () {
      test('with valid Markdown-wrapped lines then the check passes and the '
          'task is linked', () async {
        final sha = GithubHarness.sha();
        final before = clock.now().toUtc();
        await open(
          'Done.\n\n**Wonky-Task:** `T-$task`\n'
          '- Wonky-Claim: `${code.toLowerCase()}`',
          headSha: sha,
        );

        final t = await taskRow();
        expect(gate().conclusion, 'success');
        expect(gate().headSha, sha);
        expect(gate().detailsUrl, endsWith('/improvements/t/$task'));
        expect(t.status, BoardTaskStatus.inReview);
        expect(t.prNumber, pr);
        expect(t.pullRequestUrl, 'https://github.com/serverpod/wonky/pull/$pr');
        expect(t.prAuthorLogin, 'bo-dev');
        expect(t.claimedById, bo.id);
        expect(h.api.commentsOn(pr).single, contains('Linked to [T-$task'));
        expect(h.api.labels[pr], isNull);
        final r = await row();
        expect(r.gateState, GithubGate.passed);
        expect(r.gateFirstFailedAt, isNull);
        expect(r.authorLogin, 'bo-dev');
        expect(r.headSha, sha);

        final profile = await BoardUserProfile.db.findFirstRow(
          session,
          where: (p) => p.userId.equals(bo.id),
        );
        expect(profile?.githubLogin, 'bo-dev');
        final activity = await BoardComment.db.find(
          session,
          where: (c) =>
              c.taskId.equals(task) & c.systemEvent.equals('prLinked'),
        );
        expect(activity.single.body, t.pullRequestUrl);
        final notes = await UserNotification.db.find(
          session,
          where: (n) =>
              n.userId.equals(bo.id) &
              n.kind.equals(NotificationKind.boardClaim),
        );
        expect(notes, hasLength(1));
        expect(h.reviews.single.sha, sha);
        expect(
          h.reviews.single.at.difference(before),
          greaterThanOrEqualTo(GithubReview.debounce),
        );
      });

      test('with the task linked then the claim no longer expires', () async {
        await open(GithubHarness.body(task, code));

        final later = clock.now().toUtc().add(const Duration(days: 5));
        final view = await withClock(
          Clock.fixed(later),
          () => endpoints.board.getTask(bo.endpointSession, task),
        );
        expect(view.status, BoardTaskStatus.inReview);
        expect(view.claimedBy?.id, bo.id);
      });

      test('without a Wonky-Task line then the check fails with a comment '
          'and the label', () async {
        await open('Fixes the paste.');

        final r = await row();
        expect(gate().conclusion, 'failure');
        expect(r.gateState, GithubGate.failed);
        expect(r.gateReason, 'missingTask');
        expect(r.gateFirstFailedAt, isNotNull);
        final comment = h.api.commentsOn(pr).single;
        expect(comment, startsWith(GithubGate.marker));
        expect(comment, contains('/improvements/tasks'));
        expect(comment, contains('CONTRIBUTING.md'));
        expect(comment, contains('Wonky-Claim: <your claim code>'));
        expect(h.api.labels[pr], {GithubGate.missingLabel});
        expect(h.reviews, isEmpty);
      });

      test('with two Wonky-Task lines then the check fails', () async {
        await open(
          'Wonky-Task: T-$task\nWonky-Task: T-${task + 1}\n'
          'Wonky-Claim: $code',
        );

        expect(gate().conclusion, 'failure');
        expect((await row()).gateReason, 'multipleTasks');
        expect((await taskRow()).prNumber, isNull);
      });

      test('naming a task that does not exist then the check fails and '
          'links Up for grabs', () async {
        await open(GithubHarness.body(999999999, code));

        expect((await row()).gateReason, 'taskNotFound');
        expect(h.api.commentsOn(pr).single, contains('/improvements/tasks'));
      });

      test('naming a draft task then it reads as not found', () async {
        final post = await BoardHarness.post(endpoints, anna);
        final draft = await endpoints.board.createTask(
          admin.endpointSession,
          [post.number],
          'A draft',
          BoardArea.sheets,
          BoardSize.small,
        );

        await open(GithubHarness.body(draft.number, code));

        expect((await row()).gateReason, 'taskNotFound');
        expect(h.api.commentsOn(pr).single, isNot(contains('A draft')));
      });

      test('naming a cancelled task then the check fails', () async {
        await endpoints.board.setTaskStatus(
          admin.endpointSession,
          task,
          BoardTaskStatus.cancelled,
        );

        await open(GithubHarness.body(task, code));

        expect((await row()).gateReason, 'taskNotOpen');
        expect(h.api.commentsOn(pr).single, contains('was cancelled'));
      });

      test('naming a task linked to another open PR then the check fails '
          'and links that PR', () async {
        final first = GithubHarness.prNumber();
        await open(GithubHarness.body(task, code), number: first);

        await open(GithubHarness.body(task, code));

        expect((await row()).gateReason, 'linkedElsewhere');
        expect(
          h.api.commentsOn(pr).single,
          contains('https://github.com/serverpod/wonky/pull/$first'),
        );
        expect((await taskRow()).prNumber, first);
      });

      test('without a Wonky-Claim line then the check fails', () async {
        await open('Wonky-Task: T-$task');

        expect((await row()).gateReason, 'missingClaim');
      });

      test('with a wrong claim code then the check fails and the code is '
          'never echoed', () async {
        await open(GithubHarness.body(task, 'AAAA-BBBB'));

        expect((await row()).gateReason, 'claimInvalid');
        expect((await taskRow()).status, BoardTaskStatus.claimed);
        expect(h.api.commentsOn(pr).single, isNot(contains(code)));
        expect(gate().summary, isNot(contains(code)));
      });

      test('after the claim expired then the check fails', () async {
        final later = clock.now().toUtc().add(const Duration(hours: 49));

        await withClock(
          Clock.fixed(later),
          () => open(GithubHarness.body(task, code)),
        );

        expect((await row()).gateReason, 'notClaimed');
        expect((await taskRow()).prNumber, isNull);
      });
    });

    group('when a failing PR is fixed by editing the description', () {
      setUp(() => open('Fixes the paste.'));

      test('then the same comment is updated in place and the label is '
          'removed', () async {
        final commentId = (await row()).gateCommentId;

        await open(GithubHarness.body(task, code), action: 'edited');

        expect(gate().conclusion, 'success');
        expect((await row()).gateCommentId, commentId);
        expect(h.api.commentsOn(pr).single, contains('Linked to [T-$task'));
        expect(h.api.labels[pr], isEmpty);
        expect((await row()).gateFirstFailedAt, isNull);
      });
    });

    group('when a linked PR loses its lines', () {
      setUp(() => open(GithubHarness.body(task, code)));

      test('then the check fails again and the task stays linked', () async {
        await open('Oops.', action: 'edited');

        expect(gate().conclusion, 'failure');
        expect((await taskRow()).prNumber, pr);
        expect((await taskRow()).status, BoardTaskStatus.inReview);
      });

      test('then pushing a new commit with the lines back passes without a '
          'second link', () async {
        await open('Oops.', action: 'edited');
        await open(GithubHarness.body(task, code), action: 'synchronize');

        final activity = await BoardComment.db.find(
          session,
          where: (c) =>
              c.taskId.equals(task) & c.systemEvent.equals('prLinked'),
        );
        expect(gate().conclusion, 'success');
        expect(activity, hasLength(1));
      });
    });

    group('when the gate check is re-run on a fork PR', () {
      test('then the PR is found by its head commit and the gate runs on '
          'its current description', () async {
        final sha = GithubHarness.sha();
        await open('Fixes it.', headSha: sha);
        h.api.pulls[pr] = GithubPullRequest(
          number: pr,
          title: 'Fix',
          body: GithubHarness.body(task, code),
          headSha: sha,
          state: 'open',
          authorLogin: 'bo-dev',
        );

        await h.deliver(
          session,
          'check_run',
          GithubHarness.checkRunRerequested(
            name: GithubGate.checkName,
            headSha: sha,
          ),
        );

        expect(gate().conclusion, 'success');
        expect((await taskRow()).prNumber, pr);
      });
    });

    group('when the gate keeps failing', () {
      late DateTime start;
      setUp(() async {
        start = clock.now().toUtc();
        await withClock(Clock.fixed(start), () => open('No task.'));
      });

      test('for six days then the sweep leaves the PR open', () async {
        await withClock(
          Clock.fixed(start.add(const Duration(days: 6))),
          () => BoardSweep.run(session),
        );

        expect(h.api.closed, isNot(contains(pr)));
        expect((await row()).state, 'open');
      });

      test('for seven days then the sweep closes it with a comment', () async {
        await withClock(
          Clock.fixed(start.add(const Duration(days: 7, minutes: 1))),
          () => BoardSweep.run(session),
        );

        expect(h.api.closed, contains(pr));
        expect((await row()).state, 'closed');
        expect(h.api.commentsOn(pr), hasLength(2));
        expect(h.api.commentsOn(pr).last, contains('closed because'));
      });

      test('then a passing run in between resets the clock', () async {
        await withClock(
          Clock.fixed(start.add(const Duration(hours: 20))),
          () => open(GithubHarness.body(task, code), action: 'edited'),
        );
        await withClock(
          Clock.fixed(start.add(const Duration(days: 4))),
          () => open('Removed.', action: 'edited'),
        );

        await withClock(
          Clock.fixed(start.add(const Duration(days: 7, minutes: 1))),
          () => BoardSweep.run(session),
        );

        expect(h.api.closed, isNot(contains(pr)));
      });
    });
  });
}
