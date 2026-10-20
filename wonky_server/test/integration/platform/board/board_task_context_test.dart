@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart' show Uuid;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/board_markdown.dart';
import 'package:wonky_server/src/platform/board/board_tasks.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/board/board_harness.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

Matcher _code(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// What a task prompt is written from and links to (specs/16 §9.3, §10.1):
/// the comments the admin selected and the issues' Markdown version.
void main() {
  withWonkyServerpod('Given an issue with comments', (
    sessionBuilder,
    endpoints,
  ) {
    late BoardHarness h;
    late TestUser anna;
    late TestUser bo;
    late TestUser admin;
    late BoardPostView post;
    late BoardPostView other;
    late List<BoardCommentView> comments;
    final origin = Uri.parse('https://wonky.work');
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      h.ai.gemini = true;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      admin = await BoardHarness.admin(sessionBuilder);
      post = await BoardHarness.post(
        endpoints,
        anna,
        title: 'Paste into merged cells drops styles',
        body: '## What happened\nThe bold is gone.',
      );
      other = await BoardHarness.post(endpoints, anna);
      comments = [
        for (final (who, body) in [
          (anna, 'It happens with **italic** too.'),
          (bo, 'Off topic: I like the new theme.'),
          (bo, 'Only in Chrome for me.'),
        ])
          await endpoints.board.addComment(
            who.endpointSession,
            const Uuid().v4obj(),
            post.number,
            null,
            body,
          ),
      ];
    });
    tearDown(() => h.uninstall());

    Future<List<String>> promptCommentsOf(BoardTaskView task) async {
      await BoardTasks.writePrompt(sessionBuilder.build(), task.number);
      return [
        for (final c in h.ai.promptComments![post.number]!) c.body,
      ];
    }

    test('when the admin leaves a comment out then the prompt is written '
        'from the selected comments only', () async {
      final task = await endpoints.board.createTask(
        admin.endpointSession,
        [post.number],
        'Keep styles when pasting',
        BoardArea.sheets,
        BoardSize.small,
        excludedComments: [comments[1].uuid],
      );

      expect(await promptCommentsOf(task), [
        'It happens with **italic** too.',
        'Only in Chrome for me.',
      ]);
    });

    test('when the admin selects every comment then all of them are '
        'included', () async {
      final task = await endpoints.board.createTask(
        admin.endpointSession,
        [post.number],
        'Keep styles when pasting',
        BoardArea.sheets,
        BoardSize.small,
      );

      expect(await promptCommentsOf(task), hasLength(3));
    });

    test('when a left-out comment belongs to another issue then it is '
        'refused', () async {
      final foreign = await endpoints.board.addComment(
        bo.endpointSession,
        const Uuid().v4obj(),
        other.number,
        null,
        'A comment elsewhere',
      );

      await expectLater(
        endpoints.board.createTask(
          admin.endpointSession,
          [post.number],
          'Keep styles when pasting',
          BoardArea.sheets,
          BoardSize.small,
          excludedComments: [foreign.uuid],
        ),
        _code(WonkyErrorCode.invalidArgument),
      );
    });

    test('when tasks are merged then the comments left out stay out', () async {
      final a = await endpoints.board.createTask(
        admin.endpointSession,
        [post.number],
        'Keep styles when pasting',
        BoardArea.sheets,
        BoardSize.small,
        excludedComments: [comments[2].uuid],
      );
      final b = await endpoints.board.createTask(
        admin.endpointSession,
        [other.number],
        'Other thing',
        BoardArea.sheets,
        BoardSize.small,
      );
      await BoardTasks.writePrompt(sessionBuilder.build(), a.number);
      await BoardTasks.writePrompt(sessionBuilder.build(), b.number);

      final merged = await endpoints.board.mergeTasks(
        admin.endpointSession,
        [a.number, b.number],
        'Both',
        BoardArea.sheets,
        BoardSize.small,
      );

      expect(await promptCommentsOf(merged), [
        'It happens with **italic** too.',
        'Off topic: I like the new theme.',
      ]);
    });

    test(
      'when the prompt is shown then it links the issues as Markdown',
      () async {
        final task = await endpoints.board.createTask(
          admin.endpointSession,
          [post.number],
          'Keep styles when pasting',
          BoardArea.sheets,
          BoardSize.small,
        );

        expect(task.prompt, contains('/improvements/p/${post.number}.md '));
      },
    );

    group('when reading the issue as Markdown', () {
      test('then it has the title, facts, body and comments', () async {
        final md = await BoardMarkdown.post(
          sessionBuilder.build(),
          post.number,
          webOrigin: origin,
        );

        expect(
          md,
          startsWith(
            '# #${post.number} Paste into merged cells drops styles\n',
          ),
        );
        expect(md, contains('- Kind: Bug\n'));
        expect(md, contains('- Status: open\n'));
        expect(md, contains('- Votes: 1\n'));
        expect(
          md,
          contains('- Page: https://wonky.work/improvements/p/${post.number}'),
        );
        expect(md, contains('## What happened\nThe bold is gone.'));
        expect(md, contains('## Comments (3)'));
        expect(md, contains('### Anna'));
        expect(md, contains('It happens with **italic** too.'));
        expect(md, contains('Only in Chrome for me.'));
      });

      test('then removed comments are left out', () async {
        await endpoints.board.moderateComment(
          admin.endpointSession,
          comments[1].uuid,
          BoardModerationAction.remove,
          'spam',
        );

        final md = await BoardMarkdown.post(
          sessionBuilder.build(),
          post.number,
          webOrigin: origin,
        );

        expect(md, contains('## Comments (2)'));
        expect(md, isNot(contains('Off topic')));
      });

      test('then a held or missing issue has none', () async {
        await endpoints.board.moderatePost(
          admin.endpointSession,
          post.number,
          BoardModerationAction.hold,
          null,
        );
        final session = sessionBuilder.build();

        expect(
          await BoardMarkdown.post(session, post.number, webOrigin: origin),
          isNull,
        );
        expect(
          await BoardMarkdown.post(session, 999999, webOrigin: origin),
          isNull,
        );
      });
    });
  });
}
