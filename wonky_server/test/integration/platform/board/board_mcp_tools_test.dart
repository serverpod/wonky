@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import '../../../support/board/board_harness.dart';

void main() {
  withWonkyServerpod('Given the board through MCP', (
    sessionBuilder,
    endpoints,
  ) {
    late BoardHarness h;
    late TestUser anna;
    late TestUser admin;
    late McpHarness mcp;
    setUp(() async {
      h = BoardHarness.install();
      h.ai.jev = false;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      admin = await BoardHarness.admin(sessionBuilder);
      mcp = await McpHarness.forUser(anna);
    });
    tearDown(() => h.uninstall());

    test('when an agent posts then it is listed and readable', () async {
      final word = BoardHarness.word();
      final created = await mcp.call('board.create_post', {
        'kind': 'bug',
        'title': 'Undo forgets $word in Sheets',
        'body': 'Steps: type, undo.',
        'app': 'sheets',
      });
      final number = created['number'] as int;
      expect(created['moderation'], 'visible');

      final list = await mcp.call('board.list_posts', {'query': word});
      expect(
        (list['posts'] as List).map((p) => (p as Map)['number']),
        [number],
      );
      final post = await mcp.call('board.get_post', {'number': number});
      expect(post['title'], 'Undo forgets $word in Sheets');
      expect(post['my_vote'], 1);
    });

    test('when voting and commenting then the post reflects it', () async {
      final p = await BoardHarness.post(
        endpoints,
        admin,
        kind: BoardPostKind.idea,
      );
      final v = await mcp.call('board.vote', {'number': p.number, 'value': -1});
      expect(v['my_vote'], -1);
      await mcp.call('board.comment', {
        'post_number': p.number,
        'body': '**No**',
      });
      final post = await mcp.call('board.get_post', {'number': p.number});
      expect((post['comments'] as List).single, containsPair('body', '**No**'));
    });

    test(
      'when claiming a task then get_task returns the prompt, the claim code '
      'and the PR lines only for the claimant',
      () async {
        final p = await BoardHarness.post(endpoints, anna);
        final task = await BoardHarness.publishedTask(endpoints, admin, [
          p.number,
        ]);

        final claimed = await mcp.call('board.claim_task', {
          'number': task.number,
        });
        final code = claimed['claim_code'] as String;
        expect(code, matches(BoardHarness.claimCode));

        final got = await mcp.call('board.get_task', {'number': task.number});
        expect(got['prompt'], contains('Wonky task T-${task.number}'));
        expect(
          got['pr_description_lines'],
          'Wonky-Task: T-${task.number}\nWonky-Claim: $code',
        );
        expect(
          got['prompt'],
          contains('```\n${got['pr_description_lines']}\n```'),
          reason: 'the prompt has the claimant\'s PR lines',
        );

        final other = await McpHarness.forUser(admin);
        final seen = await other.call('board.get_task', {
          'number': task.number,
        });
        expect(seen.containsKey('claim_code'), isFalse);
        expect(seen['claimed_by'], 'Anna');
        expect(seen['prompt'], isNot(contains(code)));
        expect(
          seen['prompt'],
          contains('Wonky-Claim: <your claim code from the task page>'),
        );

        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final stranger = await McpHarness.forUser(bo);
        final hidden = await stranger.call('board.get_task', {
          'number': task.number,
        });
        expect(hidden.containsKey('prompt'), isFalse);
        expect(hidden['claimed_by'], 'Anna');

        await mcp.call('board.release_task', {'number': task.number});
        final tasks = await mcp.call('board.list_tasks', {});
        final row = (tasks['tasks'] as List)
            .cast<Map<Object?, Object?>>()
            .firstWhere(
              (t) => t['number'] == task.number,
            );
        expect(row['status'], 'published');
      },
    );

    test('when commenting on a task then it is refused: the tool takes a '
        'post only', () async {
      final p = await BoardHarness.post(endpoints, anna);
      final task = await BoardHarness.publishedTask(endpoints, admin, [
        p.number,
      ]);

      expect(
        await mcp.error('board.comment', {
          'task_number': task.number,
          'body': 'Taking this',
        }),
        isNotEmpty,
      );
      final rows = await endpoints.board.listTaskComments(
        admin.endpointSession,
        task.number,
      );
      expect(rows.where((r) => r.systemEvent == null), isEmpty);
    });

    test(
      'when a token lacks the board scope then the tools are refused',
      () async {
        final limited = await McpHarness.forUser(anna, scopes: ['drive:read']);
        final e = await limited.error('board.list_posts', {});
        expect(e, isNotEmpty);
      },
    );
  });
}
