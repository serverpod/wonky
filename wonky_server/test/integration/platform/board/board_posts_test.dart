@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/board/board_common.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/board_pipeline.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import '../../../support/board/board_harness.dart';
import '../../../support/board/fake_board_ai.dart';

void main() {
  withWonkyServerpod('Given the board with Jev', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    setUp(() async {
      h = BoardHarness.install();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });
    tearDown(() => h.uninstall());

    test('when a clean post is created then it is visible at once with the '
        "AI labels and the author's vote", () async {
      final post = await BoardHarness.post(endpoints, anna);

      expect(post.moderation, BoardModeration.visible);
      expect(post.triageState, BoardTriageState.done);
      expect(
        (post.area, post.size, post.aiLabels),
        (
          BoardArea.sheets,
          BoardSize.small,
          true,
        ),
      );
      expect((post.score, post.voteCount, post.myVote), (1, 1, 1));
    });

    test('when triage holds the post then the author sees it held with the '
        'reason and others do not find it', () async {
      h.ai.onTriage = (p, _) => FakeBoardAi.clean(
        p,
        scores: const BoardModerationScores(security: 0.9),
      );
      final post = await BoardHarness.post(endpoints, anna);
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');

      expect(post.moderation, BoardModeration.held);
      expect(post.moderationReason, contains('security'));
      await expectLater(
        endpoints.board.getPost(bo.endpointSession, post.number),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when triage holds the post then admins see the moderation scores '
        'at or above their review band, best first, and the author does '
        'not', () async {
      h.ai.onTriage = (p, _) => FakeBoardAi.clean(
        p,
        scores: const BoardModerationScores(
          spam: 0.91,
          notActionable: 0.62,
          offensive: 0.3,
        ),
        kindConfidence: 0.94,
      );
      final post = await BoardHarness.post(endpoints, anna);
      final admin = await BoardHarness.admin(sessionBuilder);

      final view = await endpoints.board.getPost(
        admin.endpointSession,
        post.number,
      );

      expect(view.moderation, BoardModeration.held);
      expect(view.reviewScores, {'spam': 0.91, 'not_actionable': 0.62});
      expect(view.reviewScores!.keys, ['spam', 'not_actionable']);
      expect(post.reviewScores, isNull);
    });

    test('when Jev corrects the kind then the reported kind is kept', () async {
      h.ai.onTriage = (p, _) => FakeBoardAi.clean(
        p,
        kind: BoardPostKind.idea,
        kindConfidence: 0.95,
      );

      final post = await BoardHarness.post(endpoints, anna);

      expect(
        (post.kind, post.reportedKind),
        (
          BoardPostKind.idea,
          BoardPostKind.bug,
        ),
      );
    });

    test('when a similar post exists then it is a triage candidate and a '
        'confident duplicate becomes the admin hint', () async {
      final w = BoardHarness.word();
      final first = await BoardHarness.post(
        endpoints,
        anna,
        title: 'Merged cells lose $w formatting',
      );
      h.ai.onTriage = (p, candidates) => FakeBoardAi.clean(
        p,
        duplicates: {for (final c in candidates) c.id!: 0.9},
      );

      final second = await BoardHarness.post(
        endpoints,
        anna,
        title: 'Pasting $w into merged cells',
      );
      final admin = await BoardHarness.admin(sessionBuilder);
      final asAdmin = await endpoints.board.getPost(
        admin.endpointSession,
        second.number,
      );

      expect(h.ai.triageCandidates.last, contains(first.number));
      expect(asAdmin.possibleDuplicateOfNumber, first.number);
      expect(second.possibleDuplicateOfNumber, isNull);
    });

    test('when the inline triage fails then the post is checking and the '
        'background triage is scheduled', () async {
      h.ai.triageError = BoardAiException('timeout');

      final post = await BoardHarness.post(endpoints, anna);

      expect(post.moderation, BoardModeration.checking);
      expect(h.scheduled.single.job, BoardJob.triage);
      expect(h.scheduled.single.delay, Duration.zero);
    });

    test('when the background triage succeeds then the post becomes '
        'visible', () async {
      h.ai.triageError = BoardAiException('timeout');
      final post = await BoardHarness.post(endpoints, anna);
      h.ai.triageError = null;

      await BoardPipeline.backgroundTriage(sessionBuilder.build(), post.number);

      final after = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      expect(after.moderation, BoardModeration.visible);
      expect(after.triageState, BoardTriageState.done);
    });

    test('when an admin removes a post while its background triage runs '
        'then it stays removed', () async {
      final admin = await BoardHarness.admin(sessionBuilder);
      h.ai.triageError = BoardAiException('timeout');
      final post = await BoardHarness.post(endpoints, anna);
      h.ai.triageError = null;
      h.ai.whileTriaging = (_) => endpoints.board.moderatePost(
        admin.endpointSession,
        post.number,
        BoardModerationAction.remove,
        'Spam',
      );

      await BoardPipeline.backgroundTriage(sessionBuilder.build(), post.number);

      final after = await endpoints.board.getPost(
        admin.endpointSession,
        post.number,
      );
      expect(after.moderation, BoardModeration.removed);
      expect(after.moderationReason, 'Spam');
      expect(after.triageState, isNot(BoardTriageState.done));
    });

    test('when the background triage keeps failing then it retries at 1, 5 '
        'and 30 minutes and then publishes unchecked', () async {
      h.ai.triageError = BoardAiException('down');
      final post = await BoardHarness.post(endpoints, anna);
      h.scheduled.clear();

      for (var i = 0; i < 4; i++) {
        await BoardPipeline.backgroundTriage(
          sessionBuilder.build(),
          post.number,
        );
      }

      final after = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      expect(
        [
          for (final s in h.scheduled)
            if (s.job == BoardJob.triage) s.delay,
        ],
        BoardPipeline.retryDelays,
      );
      expect(after.moderation, BoardModeration.visible);
      expect(after.triageState, BoardTriageState.unchecked);
    });

    test('when publishWhenTriageFails is false then a post that keeps '
        'failing is held', () async {
      BoardConfig.current = BoardConfig(publishWhenTriageFails: false);
      h.ai.triageError = BoardAiException('down');
      final post = await BoardHarness.post(endpoints, anna);

      for (var i = 0; i < 4; i++) {
        await BoardPipeline.backgroundTriage(
          sessionBuilder.build(),
          post.number,
        );
      }

      final after = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      expect(after.moderation, BoardModeration.held);
      expect(after.triageState, BoardTriageState.failed);
    });

    test('when Gemini is available then a visible post gets a summary job '
        'and a differing suggested title', () async {
      h.ai.gemini = true;
      h.ai.summary = (title: 'Paste loses bold in merged cells', summary: 'S');
      final post = await BoardHarness.post(endpoints, anna);

      expect(h.scheduled.single.job, BoardJob.summarize);
      await BoardPipeline.summarize(sessionBuilder.build(), post.number);

      final admin = await BoardHarness.admin(sessionBuilder);
      final view = await endpoints.board.getPost(
        admin.endpointSession,
        post.number,
      );
      expect(view.suggestedTitle, 'Paste loses bold in merged cells');
      expect(view.summary, 'S');
    });

    test('when the author edits a visible post into something that holds '
        'then it is held', () async {
      final post = await BoardHarness.post(endpoints, anna);
      h.ai.onTriage = (p, _) => FakeBoardAi.clean(
        p,
        scores: const BoardModerationScores(personalData: 0.95),
      );

      final edited = await endpoints.board.editPost(
        anna.endpointSession,
        post.number,
        'Still broken, call me',
        'My phone is 555 0100.',
      );

      expect(edited.moderation, BoardModeration.held);
      expect(edited.editedAt, isNotNull);
    });

    test('when the author edits a post with a review-band score then it '
        'stays visible', () async {
      final post = await BoardHarness.post(endpoints, anna);
      h.ai.onTriage = (p, _) => FakeBoardAi.clean(
        p,
        scores: const BoardModerationScores(offensive: 0.5),
      );

      final edited = await endpoints.board.editPost(
        anna.endpointSession,
        post.number,
        'This is really annoying',
        'Grr.',
      );

      expect(edited.moderation, BoardModeration.visible);
    });
  });

  withWonkyServerpod('Given the board without AI', (sessionBuilder, endpoints) {
    late BoardHarness h;
    late TestUser anna;
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });
    tearDown(() => h.uninstall());

    test('when a post is created then it is visible and unchecked, with the '
        'body as summary', () async {
      final post = await BoardHarness.post(
        endpoints,
        anna,
        body: '## What happened\nThe **grid** froze.',
      );

      expect(post.moderation, BoardModeration.visible);
      expect(post.triageState, BoardTriageState.unchecked);
      expect(post.summary, 'What happened The grid froze.');
      expect(h.ai.calls, isEmpty);
    });

    test('when Jev is available again then the sweep re-triages unchecked '
        'posts', () async {
      final post = await BoardHarness.post(endpoints, anna);
      h.ai.jev = true;

      await BoardPipeline.retriageUnchecked(sessionBuilder.build());

      final after = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      expect(after.triageState, BoardTriageState.done);
    });

    test('when the author edits a post while the sweep re-triages it then '
        'the edit is kept', () async {
      final post = await BoardHarness.post(endpoints, anna);
      h.ai.jev = true;
      h.ai.whileTriaging = (_) async {
        h.ai.whileTriaging = null;
        await endpoints.board.editPost(
          anna.endpointSession,
          post.number,
          'The grid froze after an edit',
          'Edited while the sweep ran.',
        );
      };

      await BoardPipeline.retriageUnchecked(sessionBuilder.build());

      final after = await endpoints.board.getPost(
        anna.endpointSession,
        post.number,
      );
      expect(
        (after.title, after.body),
        ('The grid froze after an edit', 'Edited while the sweep ran.'),
      );
      expect(after.triageState, BoardTriageState.done);
    });

    final invalid = <(String, BoardPostDraft)>[
      (
        'a short title',
        BoardPostDraft(
          kind: BoardPostKind.bug,
          title: 'Short',
          body: 'Body',
          appHint: 'sheets',
        ),
      ),
      (
        'an empty body',
        BoardPostDraft(
          kind: BoardPostKind.bug,
          title: 'A long enough title',
          body: '  ',
          appHint: 'sheets',
        ),
      ),
      (
        'a body over 10,000 chars',
        BoardPostDraft(
          kind: BoardPostKind.bug,
          title: 'A long enough title',
          body: 'x' * 10001,
          appHint: 'sheets',
        ),
      ),
      (
        'a bad app hint',
        BoardPostDraft(
          kind: BoardPostKind.bug,
          title: 'A long enough title',
          body: 'Body',
          appHint: '../x',
        ),
      ),
    ];
    for (final (name, draft) in invalid) {
      test('when creating a post with $name then it is refused', () async {
        await expectLater(
          endpoints.board.createPost(anna.endpointSession, draft),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.invalidArgument,
            ),
          ),
        );
      });
    }

    group('and a few posts', () {
      late String w;
      late BoardPostView older;
      late BoardPostView newer;
      late BoardPostView idea;
      setUp(() async {
        w = BoardHarness.word();
        older = await BoardHarness.post(
          endpoints,
          anna,
          title: 'Pasting $w into merged cells drops styles',
        );
        newer = await BoardHarness.post(
          endpoints,
          anna,
          title: 'Chart $w legend overlaps',
        );
        idea = await BoardHarness.post(
          endpoints,
          anna,
          kind: BoardPostKind.idea,
          title: 'Dark $w theme for charts',
        );
      });

      BoardListQuery q({
        BoardPostKind? kind,
        BoardSort sort = BoardSort.newest,
        String? query,
        bool mine = false,
        int limit = 50,
        String? cursor,
      }) => BoardListQuery(
        kind: kind,
        statuses: const [],
        areas: const [],
        sizes: const [],
        sort: sort,
        query: query ?? w,
        mine: mine,
        limit: limit,
        cursor: cursor,
      );

      test('when searching then only matching posts are listed', () async {
        final page = await endpoints.board.list(
          TestUsers.unauthenticated(sessionBuilder),
          q(query: '$w merged'),
        );

        expect(page.items.map((i) => i.number), [older.number]);
        expect(page.total, 1);
      });

      test('when filtering by kind then only that kind is listed', () async {
        final page = await endpoints.board.list(
          anna.endpointSession,
          q(kind: BoardPostKind.idea),
        );

        expect(page.items.map((i) => i.number), [idea.number]);
      });

      test(
        'when sorting by top then the most voted post comes first',
        () async {
          final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
          await endpoints.board.vote(bo.endpointSession, older.number, 1);

          final page = await endpoints.board.list(
            anna.endpointSession,
            q(sort: BoardSort.top),
          );

          expect(page.items.first.number, older.number);
        },
      );

      test('when paging then the cursor continues the list', () async {
        final first = await endpoints.board.list(
          anna.endpointSession,
          q(limit: 2),
        );
        final second = await endpoints.board.list(
          anna.endpointSession,
          q(limit: 2, cursor: first.nextCursor),
        );

        expect(first.items.map((i) => i.number), [idea.number, newer.number]);
        expect(second.items.map((i) => i.number), [older.number]);
        expect(second.nextCursor, isNull);
      });

      test('when listing mine then posts I voted on are included', () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        await endpoints.board.vote(bo.endpointSession, newer.number, 1);

        final page = await endpoints.board.list(
          bo.endpointSession,
          q(mine: true),
        );

        expect(page.items.map((i) => i.number), [newer.number]);
        expect(page.items.single.myVote, 1);
      });

      test('when asking for similar posts then FTS ranks the best match '
          'first', () async {
        final similar = await endpoints.board.similar(
          anna.endpointSession,
          'Merged cells $w styles',
          '',
          BoardPostKind.bug,
        );

        expect(similar.first.number, older.number);
        expect(similar.map((s) => s.number), isNot(contains(idea.number)));
      });

      test('when the author deletes a post then others no longer see it and '
          'restoring brings it back', () async {
        await endpoints.board.deletePost(anna.endpointSession, older.number);
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');

        await expectLater(
          endpoints.board.getPost(bo.endpointSession, older.number),
          throwsA(isA<WonkyException>()),
        );
        await endpoints.board.restorePost(anna.endpointSession, older.number);
        final back = await endpoints.board.getPost(
          bo.endpointSession,
          older.number,
        );
        expect(back.deleted, isFalse);
      });
    });
  });

  withWonkyServerpod('Given the board with Jev reranking', (
    sessionBuilder,
    endpoints,
  ) {
    late BoardHarness h;
    late TestUser anna;
    setUp(() async {
      h = BoardHarness.install();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });
    tearDown(() => h.uninstall());

    test('when Jev reranks then low candidates are dropped and the order '
        'follows Jev', () async {
      final w = BoardHarness.word();
      final a = await BoardHarness.post(
        endpoints,
        anna,
        title: 'Formula $w errors everywhere',
      );
      final b = await BoardHarness.post(
        endpoints,
        anna,
        title: 'Formula $w bar too small',
      );
      final c = await BoardHarness.post(
        endpoints,
        anna,
        title: 'Formula $w autocomplete',
      );
      h.ai.rerank = {a.number: 0.2, b.number: 0.9, c.number: 0.4};

      final similar = await endpoints.board.similar(
        anna.endpointSession,
        'Formula $w',
        '',
        null,
      );

      expect(similar.map((s) => s.number), [b.number, c.number]);
    });
  });
}
