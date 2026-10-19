@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/mcp/tool_executor.dart';
import 'package:wonky_server/src/platform/mcp/tool_support.dart';
import 'package:wonky_server/src/platform/mcp/wonky_mcp_server.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a document with comments through MCP', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      doc = await TestDrive.document(
        endpoints,
        anna,
        markdown: 'Budget is ten euros.\n',
      );
    });

    test(
      'when commenting on a quote then the thread is anchored and listed',
      () async {
        final c = await mcp.call('comments.create', {
          'uuid': doc.uuid.uuid,
          'anchor': {'quote': 'ten euros'},
          'body': 'Too low?',
        });

        final list = await mcp.call('comments.list', {'uuid': doc.uuid.uuid});
        final t = (list['threads'] as List).single as Map;
        expect(t['thread_uuid'], c['thread_uuid']);
        expect((t['anchor'] as Map)['quote'], 'ten euros');
        expect(
          (t['comments'] as List).single,
          containsPair('body', 'Too low?'),
        );
        expect(c['change_id'], isA<String>());
      },
    );

    test(
      'when replying, resolving and reopening then the status follows',
      () async {
        final c = await mcp.call('comments.create', {
          'uuid': doc.uuid.uuid,
          'anchor': {'document': true},
          'body': 'General note',
        });
        final id = c['thread_uuid'];

        await mcp.call('comments.reply', {'thread_uuid': id, 'body': 'Agreed'});
        final resolved = await mcp.call('comments.resolve', {
          'thread_uuid': id,
        });
        final reopened = await mcp.call('comments.reopen', {'thread_uuid': id});

        expect((resolved['thread'] as Map)['status'], 'resolved');
        expect((reopened['thread'] as Map)['status'], 'open');
        expect((reopened['thread'] as Map)['comments'], hasLength(2));
      },
    );

    test('when deleting a thread then it and its anchor are removed', () async {
      final c = await mcp.call('comments.create', {
        'uuid': doc.uuid.uuid,
        'anchor': {'quote': 'Budget'},
        'body': 'x',
      });

      final r = await mcp.call('comments.delete', {
        'thread_uuid': c['thread_uuid'],
      });

      final list = await mcp.call('comments.list', {
        'uuid': doc.uuid.uuid,
        'status': 'all',
      });
      expect(list['threads'], isEmpty);
      expect(r['change_id'], isA<String>());
    });

    test('when the anchor quote is missing then nothing is created', () async {
      final e = await mcp.error('comments.create', {
        'uuid': doc.uuid.uuid,
        'anchor': {'quote': 'missing'},
        'body': 'x',
      });

      final list = await mcp.call('comments.list', {'uuid': doc.uuid.uuid});
      expect(e['code'], 'quote_not_found');
      expect(list['threads'], isEmpty);
    });
  });

  withWonkyServerpod('Given versions through MCP', (sessionBuilder, endpoints) {
    test(
      'when naming, reading and restoring a version then the content returns',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final mcp = await McpHarness.forUser(anna);
        final doc = await TestDrive.document(
          endpoints,
          anna,
          markdown: 'First draft.',
        );
        final v = await mcp.call('versions.name_current', {
          'uuid': doc.uuid.uuid,
          'name': 'Draft 1',
        });
        await mcp.call('write.set_markdown', {
          'document_uuid': doc.uuid.uuid,
          'markdown': 'Second draft.',
        });
        final versionId = (v['version'] as Map)['version_id'];

        final list = await mcp.call('versions.list', {'uuid': doc.uuid.uuid});
        final read = await mcp.call('versions.get', {
          'uuid': doc.uuid.uuid,
          'version_id': versionId,
        });
        final restored = await mcp.call('versions.restore', {
          'uuid': doc.uuid.uuid,
          'version_id': versionId,
        });
        final now = await mcp.call('write.get_document', {
          'document_uuid': doc.uuid.uuid,
        });

        expect(
          (list['versions'] as List).map((x) => (x as Map)['name']),
          contains('Draft 1'),
        );
        expect(read['content'], contains('First draft.'));
        expect(now['content'], contains('First draft.'));
        expect(restored['change_id'], isA<String>());
        await mcp.call('changes.revert', {'change_id': restored['change_id']});
        final reverted = await mcp.call('write.get_document', {
          'document_uuid': doc.uuid.uuid,
        });
        expect(reverted['content'], contains('Second draft.'));
      },
    );
  });

  withWonkyServerpod('Given the tool executor', (sessionBuilder, endpoints) {
    test(
      'when a token exceeds its rate limit then rate_limited is returned',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final mcp = await McpHarness.forUser(anna);
        final executor = ToolExecutor(
          WonkyMcpServer.executor.tools,
          rateLimiter: McpRateLimiter(limit: 2),
        );

        await executor.call(mcp.ctx, 'drive.list_folder', {});
        await executor.call(mcp.ctx, 'drive.list_folder', {});
        final third = await executor.call(mcp.ctx, 'drive.list_folder', {});

        expect(third.error?.code, McpErrorCode.rateLimited);
      },
    );

    test('when listing the catalog then the sheets tools are offered', () {
      final names = [
        for (final t in WonkyMcpServer.executor.tools) t.definition.name,
      ];

      expect(names, containsAll(['sheets.set_values', 'sheets.get_values']));
      expect(names, contains('drive.create_spreadsheet'));
      expect(
        names,
        containsAll(['write.insert_markdown', 'ui.invoke_command']),
      );
    });
  });
}
