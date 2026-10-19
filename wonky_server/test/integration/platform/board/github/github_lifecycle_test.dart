@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/github/github_gate.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../../support/test_users.dart';
import '../../../../support/wonky_serverpod.dart';
import '../../../../support/board/board_harness.dart';
import '../../../../support/board/github_harness.dart';

void main() {
  withWonkyServerpod('Given a task linked to a PR through the gate', (
    sessionBuilder,
    endpoints,
  ) {
    late GithubHarness h;
    late Session session;
    late TestUser anna;
    late TestUser bo;
    late TestUser cy;
    late TestUser admin;
    late int task;
    late String code;
    late int pr;
    late String body;

    setUp(() async {
      h = GithubHarness.install();
      session = sessionBuilder.build();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      cy = await TestUsers.create(sessionBuilder, name: 'Cy');
      admin = await BoardHarness.admin(sessionBuilder);
      (number: task, code: code) = await GithubHarness.claimedTask(
        endpoints,
        admin: admin,
        author: anna,
        claimant: bo,
      );
      final posts = (await endpoints.board.getTask(
        anna.endpointSession,
        task,
      )).posts;
      await endpoints.board.vote(cy.endpointSession, posts.single.number, 1);
      pr = GithubHarness.prNumber();
      body = GithubHarness.body(task, code);
      await h.deliver(
        session,
        'pull_request',
        GithubHarness.pullRequest(number: pr, body: body, author: 'bo-dev'),
      );
    });
    tearDown(() => h.uninstall());

    Future<BoardTask> taskRow() async =>
        (await BoardTask.db.findById(session, task))!;

    Future<List<BoardPost>> posts() =>
        BoardPost.db.find(session, where: (t) => t.taskId.equals(task));

    Future<List<UserNotification>> notes(TestUser u, NotificationKind k) =>
        UserNotification.db.find(
          session,
          where: (t) => t.userId.equals(u.id) & t.kind.equals(k),
        );

    Future<void> close({bool merged = false, String? mergeSha}) => h.deliver(
      session,
      'pull_request',
      GithubHarness.pullRequest(
        number: pr,
        action: 'closed',
        body: body,
        author: 'bo-dev',
        state: 'closed',
        merged: merged,
        mergeCommitSha: mergeSha,
      ),
    );

    group('when the PR is merged', () {
      late String mergeSha;
      setUp(() async {
        mergeSha = GithubHarness.sha('merge');
        await close(merged: true, mergeSha: mergeSha);
      });

      test('then the task and its posts are done with the merge SHA and '
          'voters are notified', () async {
        final t = await taskRow();
        final row = await BoardPullRequest.db.findFirstRow(
          session,
          where: (r) => r.prNumber.equals(pr),
        );
        expect(t.status, BoardTaskStatus.done);
        expect(t.mergeCommitSha, mergeSha);
        expect(t.doneAt, isNotNull);
        expect(row?.state, 'merged');
        expect(row?.mergeCommitSha, mergeSha);
        expect((await posts()).single.status, BoardPostStatus.done);
        final voter = await notes(cy, NotificationKind.boardStatus);
        expect(voter.last.payload, contains('Built'));
      });

      group('and a deploy succeeds', () {
        test('containing the merge then the task ships and voters are '
            'notified', () async {
          final deploy = GithubHarness.sha('deploy');
          h.api.compares['$mergeSha...$deploy'] = 'ahead';

          await h.deliver(
            session,
            'workflow_run',
            GithubHarness.workflowRun(headSha: deploy),
          );

          final t = await taskRow();
          expect(t.status, BoardTaskStatus.shipped);
          expect(t.shippedDeploySha, deploy);
          expect(t.shippedAt, isNotNull);
          expect((await posts()).single.status, BoardPostStatus.shipped);
          final voter = await notes(cy, NotificationKind.boardStatus);
          expect(voter.last.payload, contains('now live on wonky.work'));
        });

        test('at exactly the merge commit then the task ships', () async {
          h.api.compares['$mergeSha...$mergeSha'] = 'identical';

          await h.deliver(
            session,
            'workflow_run',
            GithubHarness.workflowRun(headSha: mergeSha),
          );

          expect((await taskRow()).status, BoardTaskStatus.shipped);
        });

        test('not containing the merge then the task stays done', () async {
          final deploy = GithubHarness.sha('deploy');
          h.api.compares['$mergeSha...$deploy'] = 'behind';

          await h.deliver(
            session,
            'workflow_run',
            GithubHarness.workflowRun(headSha: deploy),
          );

          expect((await taskRow()).status, BoardTaskStatus.done);
        });

        test('of another workflow then nothing is compared', () async {
          final deploy = GithubHarness.sha('deploy');
          h.api.compares['$mergeSha...$deploy'] = 'ahead';

          await h.deliver(
            session,
            'workflow_run',
            GithubHarness.workflowRun(
              headSha: deploy,
              path: '.github/workflows/tests.yml',
            ),
          );

          expect((await taskRow()).status, BoardTaskStatus.done);
          expect(h.api.calls.where((c) => c.startsWith('compare')), isEmpty);
        });
      });

      test('and the deploy failed then the task stays done', () async {
        final deploy = GithubHarness.sha('deploy');
        h.api.compares['$mergeSha...$deploy'] = 'ahead';

        await h.deliver(
          session,
          'workflow_run',
          GithubHarness.workflowRun(headSha: deploy, conclusion: 'failure'),
        );

        expect((await taskRow()).status, BoardTaskStatus.done);
      });
    });

    group('when the PR is closed without merging', () {
      setUp(() => close());

      test('then the task is published again with the claim and code '
          'cleared, and the claimant is told', () async {
        final t = await taskRow();
        expect(t.status, BoardTaskStatus.published);
        expect(t.claimedById, isNull);
        expect(t.claimCode, isNull);
        expect(t.prNumber, isNull);
        expect(t.pullRequestUrl, isNull);
        expect((await posts()).single.status, BoardPostStatus.planned);
        final activity = await BoardComment.db.find(
          session,
          where: (c) =>
              c.taskId.equals(task) & c.systemEvent.equals('prClosed'),
        );
        expect(activity, hasLength(1));
        final claim = await notes(bo, NotificationKind.boardClaim);
        expect(claim.last.payload, contains('is open again'));
      });

      test('and reopened then the gate re-runs and fails on the old '
          'code', () async {
        await h.deliver(
          session,
          'pull_request',
          GithubHarness.pullRequest(
            number: pr,
            action: 'reopened',
            body: body,
            author: 'bo-dev',
          ),
        );

        final run = h.api.runsNamed(GithubGate.checkName).last;
        expect(run.conclusion, 'failure');
        expect((await taskRow()).prNumber, isNull);
      });

      test('and reopened after claiming again with the new code then the '
          'task is linked again', () async {
        final view = await endpoints.board.claimTask(bo.endpointSession, task);
        await h.deliver(
          session,
          'pull_request',
          GithubHarness.pullRequest(
            number: pr,
            action: 'reopened',
            body: GithubHarness.body(task, view.claimCode!),
            author: 'bo-dev',
          ),
        );

        expect((await taskRow()).status, BoardTaskStatus.inReview);
        expect((await taskRow()).prNumber, pr);
      });
    });
  });
}
