@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/board/board_comments.dart';
import 'package:wonky_server/src/platform/board/board_common.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/board_sweep.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/streams.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import '../../../support/board/board_harness.dart';

void main() {
  withWonkyServerpod('Given a post with comments', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    late TestUser bo;
    late TestUser cy;
    late TestUser admin;
    late BoardPostView post;
    setUp(() async {
      h = BoardHarness.install();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      cy = await TestUsers.create(sessionBuilder, name: 'Cy');
      admin = await BoardHarness.admin(sessionBuilder);
      post = await BoardHarness.post(endpoints, anna);
    });
    tearDown(() => h.uninstall());

    Future<BoardCommentView> comment(
      TestUser who,
      String body, {
      UuidValue? uuid,
    }) => endpoints.board.addComment(
      who.endpointSession,
      uuid ?? const Uuid().v4obj(),
      post.number,
      null,
      body,
    );

    Future<List<UserNotification>> notes(TestUser who) =>
        UserNotification.db.find(
          sessionBuilder.build(),
          where: (t) =>
              t.userId.equals(who.id) &
              t.kind.equals(NotificationKind.boardReply),
        );

    test(
      'when commenting with the same uuid twice then one comment exists',
      () async {
        final uuid = const Uuid().v4obj();
        await comment(bo, 'Same here', uuid: uuid);
        await comment(bo, 'Same here', uuid: uuid);

        final list = await endpoints.board.listComments(
          TestUsers.unauthenticated(sessionBuilder),
          post.number,
        );
        final view = await endpoints.board.getPost(
          anna.endpointSession,
          post.number,
        );

        expect(list, hasLength(1));
        expect(view.commentCount, 1);
      },
    );

    test('when commenting then the author and earlier commenters are '
        'notified, never the commenter', () async {
      await comment(bo, 'First');

      await comment(cy, 'Second **bold**');

      final annaNotes = await notes(anna);
      final boNotes = await notes(bo);
      final cyNotes = await notes(cy);
      expect(annaNotes, hasLength(2));
      expect(boNotes, hasLength(1));
      expect(cyNotes, isEmpty);
      expect(
        jsonDecode(boNotes.single.payload),
        allOf(
          containsPair('postNumber', post.number),
          containsPair('title', post.title),
          containsPair('excerpt', 'Second bold'),
        ),
      );
    });

    test('when a comment scores in the hold band then it is held for others '
        'and visible to its author', () async {
      h.ai.commentScores = const BoardModerationScores(offensive: 0.9);

      final c = await comment(bo, 'Rude words');
      final forOthers = await endpoints.board.listComments(
        cy.endpointSession,
        post.number,
      );
      final forAuthor = await endpoints.board.listComments(
        bo.endpointSession,
        post.number,
      );

      expect(c.moderation, BoardModeration.held);
      expect(forOthers, isEmpty);
      expect(forAuthor.single.moderationReason, contains('offensive'));
      expect(await notes(anna), isEmpty);
    });

    test('when a comment scores in the review band then it is visible and in '
        'the admin check list', () async {
      h.ai.commentScores = const BoardModerationScores(personalData: 0.5);

      await comment(bo, 'Mail me');
      final queue = await endpoints.board.reviewQueue(
        admin.endpointSession,
        BoardReviewSection.check,
      );

      expect(
        queue.map((i) => i.comment?.body),
        contains('Mail me'),
      );
    });

    test('when the comment check fails then the comment is visible', () async {
      h.ai.commentError = BoardAiException('down');

      final c = await comment(bo, 'Hello');

      expect(c.moderation, BoardModeration.visible);
    });

    Future<BoardComment> row(UuidValue uuid) async =>
        (await BoardComment.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.uuid.equals(uuid),
        ))!;

    test('when Jev is unavailable then the comment is published unchecked '
        'and listed for admins to check', () async {
      h.ai
        ..jev = false
        ..jevOverBudget = true;

      final c = await comment(bo, 'Unchecked words');
      final queue = await endpoints.board.reviewQueue(
        admin.endpointSession,
        BoardReviewSection.check,
      );

      expect(c.moderation, BoardModeration.visible);
      expect(BoardComments.isUnchecked(await row(c.uuid)), isTrue);
      expect(
        queue.map((i) => i.comment?.body),
        contains('Unchecked words'),
      );
    });

    test('when Jev has no key then the comment is visible and not '
        'marked for checking', () async {
      h.ai.jev = false;

      final c = await comment(bo, 'No AI here');

      final after = await row(c.uuid);
      expect(
        (after.moderation, after.needsCheck, after.moderationReason),
        (BoardModeration.visible, false, null),
      );
    });

    test('when Jev is back then the sweep checks unchecked comments and '
        'holds the ones in the hold band', () async {
      h.ai.commentError = BoardAiException('budget');
      final rude = await comment(bo, 'Rude words');
      h.ai.commentError = null;
      h.ai.commentScores = const BoardModerationScores(offensive: 0.9);

      await BoardSweep.run(sessionBuilder.build());

      final forOthers = await endpoints.board.listComments(
        cy.endpointSession,
        post.number,
      );
      final after = await row(rude.uuid);
      expect(forOthers, isEmpty);
      expect(after.moderation, BoardModeration.held);
      expect(BoardComments.isUnchecked(after), isFalse);
    });

    test('when Jev is back and the comment is clean then the sweep clears '
        'its check', () async {
      h.ai
        ..jev = false
        ..jevOverBudget = true;
      final c = await comment(bo, 'Nice idea');
      h.ai.jev = true;

      final checked = await BoardComments.recheckUnchecked(
        sessionBuilder.build(),
      );

      final after = await row(c.uuid);
      expect(checked, 1);
      expect(
        (after.moderation, after.needsCheck, after.moderationReason),
        (BoardModeration.visible, false, null),
      );
    });

    test('when an unchecked comment is edited while Jev is back then the '
        'edit is checked and the mark is gone', () async {
      h.ai
        ..jev = false
        ..jevOverBudget = true;
      final c = await comment(bo, 'Typo');
      h.ai.jev = true;

      await endpoints.board.editComment(bo.endpointSession, c.uuid, 'Fixed');

      final after = await row(c.uuid);
      expect((after.needsCheck, after.moderationReason), (false, null));
    });

    test('when the author edits, deletes and restores a comment then the '
        'count follows', () async {
      final c = await comment(bo, 'Typo');
      await endpoints.board.editComment(bo.endpointSession, c.uuid, 'Fixed');
      await endpoints.board.deleteComment(bo.endpointSession, c.uuid);
      final deleted = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      final restored = await endpoints.board.restoreComment(
        bo.endpointSession,
        c.uuid,
      );

      expect(deleted.commentCount, 0);
      expect(restored.body, 'Fixed');
      expect(restored.deleted, isFalse);
    });

    test('when someone else edits a comment then it is refused', () async {
      final c = await comment(bo, 'Mine');

      await expectLater(
        endpoints.board.editComment(cy.endpointSession, c.uuid, 'Yours'),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when three users flag a post then it is held with a check and the '
        'author is told', () async {
      for (final u in [bo, cy, admin]) {
        await endpoints.board.flag(
          u.endpointSession,
          post.number,
          null,
          BoardFlagReason.spam,
          null,
        );
      }

      final asAuthor = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      final asAdmin = await endpoints.board.getPost(
        admin.endpointSession,
        post.number,
      );
      expect(asAuthor.moderation, BoardModeration.held);
      expect(asAdmin.flags, hasLength(3));
      expect(asAdmin.needsCheck, isTrue);
    });

    test(
      'when one user flags three times then the post stays visible',
      () async {
        for (var i = 0; i < 3; i++) {
          await endpoints.board.flag(
            bo.endpointSession,
            post.number,
            null,
            BoardFlagReason.other,
            'again',
          );
        }

        final view = await endpoints.board.getPost(
          anna.endpointSession,
          post.number,
        );
        expect(view.moderation, BoardModeration.visible);
      },
    );

    test('when a flag is undone then it no longer counts', () async {
      BoardConfig.current = BoardConfig(flagsToHold: 2);
      await endpoints.board.flag(
        bo.endpointSession,
        post.number,
        null,
        BoardFlagReason.spam,
        null,
      );
      await endpoints.board.unflag(bo.endpointSession, post.number, null);

      await endpoints.board.flag(
        cy.endpointSession,
        post.number,
        null,
        BoardFlagReason.spam,
        null,
      );

      final view = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      expect(view.moderation, BoardModeration.visible);
    });

    test(
      'when flagged comments reach the threshold then the comment is held',
      () async {
        BoardConfig.current = BoardConfig(flagsToHold: 2);
        final c = await comment(bo, 'Buy cheap stuff');

        for (final u in [anna, cy]) {
          await endpoints.board.flag(
            u.endpointSession,
            null,
            c.uuid,
            BoardFlagReason.spam,
            null,
          );
        }
        final queue = await endpoints.board.reviewQueue(
          admin.endpointSession,
          BoardReviewSection.held,
        );

        expect(
          queue.map((i) => i.comment?.uuid),
          contains(c.uuid),
        );
        expect(
          (await endpoints.board.getPost(
            anna.endpointSession,
            post.number,
          )).commentCount,
          0,
        );
      },
    );

    test('when watching a post then a vote arrives as an event', () async {
      final queue = await subscribed(
        endpoints.board.watchPost(
          TestUsers.unauthenticated(sessionBuilder),
          post.number,
        ),
        () => BoardLive.post(sessionBuilder.build(), post.number),
      );

      await endpoints.board.vote(cy.endpointSession, post.number, 1);

      final event = await queue.next;
      expect(
        (event.kind, event.number),
        (
          BoardEventKind.postChanged,
          post.number,
        ),
      );
      await queue.cancel(immediate: true);
    });

    test(
      'when watching a held post as someone else then it is refused',
      () async {
        await endpoints.board.moderatePost(
          admin.endpointSession,
          post.number,
          BoardModerationAction.hold,
          null,
        );

        await expectLater(
          endpoints.board.watchPost(bo.endpointSession, post.number).first,
          throwsA(isA<WonkyException>()),
        );
      },
    );
  });
}
