@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import '../../../support/board/board_harness.dart';

Matcher _code(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

void main() {
  withWonkyServerpod('Given posts and voters', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    late TestUser bo;
    late TestUser cy;
    late TestUser admin;
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      cy = await TestUsers.create(sessionBuilder, name: 'Cy');
      admin = await BoardHarness.admin(sessionBuilder);
    });
    tearDown(() => h.uninstall());

    test('when voting twice then the vote is counted once', () async {
      final post = await BoardHarness.post(endpoints, anna);

      await endpoints.board.vote(bo.endpointSession, post.number, 1);
      final result = await endpoints.board.vote(
        bo.endpointSession,
        post.number,
        1,
      );

      expect((result.score, result.voteCount, result.myVote), (2, 2, 1));
    });

    test('when removing a vote with 0 then the score drops', () async {
      final post = await BoardHarness.post(endpoints, anna);
      await endpoints.board.vote(bo.endpointSession, post.number, 1);

      final result = await endpoints.board.vote(
        bo.endpointSession,
        post.number,
        0,
      );

      expect((result.score, result.myVote), (1, 0));
    });

    test('when down-voting an idea then the score goes down', () async {
      final idea = await BoardHarness.post(
        endpoints,
        anna,
        kind: BoardPostKind.idea,
      );

      final result = await endpoints.board.vote(
        bo.endpointSession,
        idea.number,
        -1,
      );

      expect((result.score, result.voteCount), (0, 2));
    });

    test('when down-voting a bug then it is refused', () async {
      final bug = await BoardHarness.post(endpoints, anna);

      await expectLater(
        endpoints.board.vote(bo.endpointSession, bug.number, -1),
        _code(WonkyErrorCode.invalidArgument),
      );
    });

    test('when voting 2 then it is refused', () async {
      final bug = await BoardHarness.post(endpoints, anna);

      await expectLater(
        endpoints.board.vote(bo.endpointSession, bug.number, 2),
        _code(WonkyErrorCode.invalidArgument),
      );
    });

    test('when a post is declined then voting is closed and reopening opens '
        'it again', () async {
      final post = await BoardHarness.post(endpoints, anna);
      await endpoints.board.decline(
        admin.endpointSession,
        post.number,
        'Works as intended',
      );

      await expectLater(
        endpoints.board.vote(bo.endpointSession, post.number, 1),
        _code(WonkyErrorCode.conflict),
      );
      await endpoints.board.reopen(admin.endpointSession, post.number);
      await expectLater(
        endpoints.board.vote(bo.endpointSession, post.number, 1),
        completes,
      );
    });

    test('when a voter is blocked then their vote leaves the score, and '
        'unblocking restores it', () async {
      final post = await BoardHarness.post(endpoints, anna);
      await endpoints.board.vote(bo.endpointSession, post.number, 1);

      await endpoints.board.blockUser(admin.endpointSession, bo.id, 'x', null);
      final blocked = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      await endpoints.board.unblockUser(admin.endpointSession, bo.id);
      final unblocked = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );

      expect(blocked.score, 1);
      expect(unblocked.score, 2);
    });

    group('and two posts to merge', () {
      late BoardPostView source;
      late BoardPostView target;
      setUp(() async {
        source = await BoardHarness.post(endpoints, anna);
        target = await BoardHarness.post(endpoints, bo);
        // Bo voted on both (keeps the target vote), Cy only on the source.
        await endpoints.board.vote(bo.endpointSession, source.number, 1);
        await endpoints.board.vote(cy.endpointSession, source.number, 1);
      });

      test('when merging then the source is a duplicate and its votes move '
          'to the target without double counting', () async {
        final merged = await endpoints.board.merge(
          admin.endpointSession,
          source.number,
          target.number,
        );
        final src = await endpoints.board.getPost(
          anna.endpointSession,
          source.number,
        );

        expect(merged.number, target.number);
        expect(merged.score, 3); // Bo, Anna (moved), Cy (moved)
        expect(merged.mergedFrom, [source.number]);
        expect(src.status, BoardPostStatus.duplicate);
        expect(src.duplicateOfNumber, target.number);
        expect(src.score, 0);
      });

      test(
        'when merging then the source author and voters are notified',
        () async {
          await endpoints.board.merge(
            admin.endpointSession,
            source.number,
            target.number,
          );
          final notes = await UserNotification.db.find(
            sessionBuilder.build(),
            where: (t) =>
                t.userId.equals(cy.id) &
                t.kind.equals(NotificationKind.boardStatus),
          );

          final payload = jsonDecode(notes.single.payload) as Map;
          expect(payload['postNumber'], source.number);
          expect(payload['line'], contains('#${target.number}'));
        },
      );

      test('when unmerging then the votes move back and the scores are as '
          'before', () async {
        await endpoints.board.merge(
          admin.endpointSession,
          source.number,
          target.number,
        );

        final src = await endpoints.board.unmerge(
          admin.endpointSession,
          source.number,
        );
        final tgt = await endpoints.board.getPost(
          bo.endpointSession,
          target.number,
        );

        expect(src.status, BoardPostStatus.open);
        expect(src.score, 3);
        expect(tgt.score, 1);
        expect(tgt.mergedFrom, isEmpty);
      });

      test('when merging twice then the second merge is refused', () async {
        await endpoints.board.merge(
          admin.endpointSession,
          source.number,
          target.number,
        );

        await expectLater(
          endpoints.board.merge(
            admin.endpointSession,
            source.number,
            target.number,
          ),
          _code(WonkyErrorCode.conflict),
        );
      });
    });

    test('when an admin moderates then a log row is written', () async {
      final post = await BoardHarness.post(endpoints, anna);

      await endpoints.board.moderatePost(
        admin.endpointSession,
        post.number,
        BoardModerationAction.hold,
        'Check this',
      );
      final logs = await BoardModerationLog.db.find(
        sessionBuilder.build(),
        where: (t) =>
            t.targetKind.equals(BoardTargetKind.post) &
            t.targetId.equals(post.number),
      );

      expect(logs.single.action, 'hold');
      expect(logs.single.adminId, admin.id);
      expect(logs.single.reason, 'Check this');
    });

    test('when an admin removes a post then the author is notified with the '
        'reason and restore brings it back', () async {
      final post = await BoardHarness.post(endpoints, anna);

      await endpoints.board.moderatePost(
        admin.endpointSession,
        post.number,
        BoardModerationAction.remove,
        'Spam',
      );
      final notes = await UserNotification.db.find(
        sessionBuilder.build(),
        where: (t) => t.userId.equals(anna.id),
      );
      final restored = await endpoints.board.moderatePost(
        admin.endpointSession,
        post.number,
        BoardModerationAction.restore,
        null,
      );

      expect(notes.single.kind, NotificationKind.boardStatus);
      expect(jsonDecode(notes.single.payload)['line'], contains('Spam'));
      expect(restored.moderation, BoardModeration.visible);
    });

    test('when setting labels then they are confirmed (not AI)', () async {
      final post = await BoardHarness.post(endpoints, anna);

      final view = await endpoints.board.setLabels(
        admin.endpointSession,
        post.number,
        BoardPostKind.idea,
        BoardArea.write,
        BoardSize.medium,
      );

      expect(
        (view.kind, view.area, view.size, view.aiLabels),
        (
          BoardPostKind.idea,
          BoardArea.write,
          BoardSize.medium,
          false,
        ),
      );
    });

    test('when an admin edits and approves a held post then it is visible '
        'and marked as edited by a moderator', () async {
      final post = await BoardHarness.post(endpoints, anna);
      await endpoints.board.moderatePost(
        admin.endpointSession,
        post.number,
        BoardModerationAction.hold,
        null,
      );

      final view = await endpoints.board.adminEditPost(
        admin.endpointSession,
        post.number,
        post.title,
        'Without the phone number.',
      );

      expect(view.moderation, BoardModeration.visible);
      expect(view.editedByModerator, isTrue);
    });
  });
}
