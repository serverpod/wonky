@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/export/server_fonts.dart';
import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../../support/mcp_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a user driving the drive through MCP', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
    });

    test(
      'when creating a document with markdown then it has the content',
      () async {
        final r = await mcp.call('drive.create_document', {
          'name': 'Agenda',
          'markdown': '# Agenda\n\n- Coffee',
        });

        final item = r['item'] as Map;
        expect(item['name'], 'Agenda');
        expect(item['kind'], 'document');
        expect(item['url'], endsWith('/write/d/${item['uuid']}'));
        final doc = await mcp.call('write.get_document', {
          'document_uuid': item['uuid'],
        });
        expect(doc['content'], contains('- Coffee'));
      },
    );

    test(
      'when creating a folder and moving a document into it then it is listed there',
      () async {
        final folder =
            (await mcp.call('drive.create_folder', {
                  'name': 'Projects',
                }))['item']
                as Map;
        final doc =
            (await mcp.call('drive.create_document', {
                  'name': 'Spec',
                }))['item']
                as Map;

        await mcp.call('drive.move', {
          'uuids': [doc['uuid']],
          'folder_uuid': folder['uuid'],
        });
        final listing = await mcp.call('drive.list_folder', {
          'folder_uuid': folder['uuid'],
        });

        expect((listing['items'] as List).map((i) => (i as Map)['name']), [
          'Spec',
        ]);
      },
    );

    test(
      'when renaming, starring and copying then each result reflects it',
      () async {
        final doc =
            (await mcp.call('drive.create_document', {
                  'name': 'Old',
                }))['item']
                as Map;

        final renamed = await mcp.call('drive.rename', {
          'uuid': doc['uuid'],
          'name': 'New',
        });
        final starred = await mcp.call('drive.star', {'uuid': doc['uuid']});
        final copy = await mcp.call('drive.copy', {'uuid': doc['uuid']});

        expect((renamed['item'] as Map)['name'], 'New');
        expect((starred['item'] as Map)['starred'], isTrue);
        expect((copy['item'] as Map)['name'], 'Copy of New');
      },
    );

    test('when trashing and restoring then the item comes back', () async {
      final doc =
          (await mcp.call('drive.create_document', {
                'name': 'Temp',
              }))['item']
              as Map;

      await mcp.call('drive.trash', {
        'uuids': [doc['uuid']],
      });
      final trashed = await mcp.call('drive.get_item', {'uuid': doc['uuid']});
      await mcp.call('drive.restore', {
        'uuids': [doc['uuid']],
      });
      final restored = await mcp.call('drive.get_item', {'uuid': doc['uuid']});

      expect((trashed['item'] as Map)['trashed'], isTrue);
      expect((restored['item'] as Map)['trashed'], isFalse);
    });

    test(
      'when sharing and unsharing then the person gains and loses access',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final doc = await TestDrive.document(endpoints, anna, name: 'Shared');

        final shared = await mcp.call('drive.share', {
          'uuid': doc.uuid.uuid,
          'email': bo.email,
          'role': 'commenter',
          'notify': false,
        });
        final boView = await endpoints.drive.get(bo.endpointSession, doc.uuid);
        await mcp.call('drive.unshare', {
          'uuid': doc.uuid.uuid,
          'email': bo.email,
        });

        expect((shared['permission'] as Map)['role'], 'commenter');
        expect(boView.role, AccessRole.commenter);
        await expectLater(
          endpoints.drive.get(bo.endpointSession, doc.uuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test('when setting link sharing then the link role is returned', () async {
      final doc = await TestDrive.document(endpoints, anna);

      final r = await mcp.call('drive.set_link_sharing', {
        'uuid': doc.uuid.uuid,
        'mode': 'viewer',
      });

      expect((r['link'] as Map)['role'], 'viewer');
      expect((r['link'] as Map)['url'], contains('/invite/'));
    });

    test('when searching by name then the document is found', () async {
      await mcp.call('drive.create_document', {
        'name': 'Quarterly zebra report',
      });

      final r = await mcp.call('drive.search', {'query': 'zebra'});

      expect(
        (r['items'] as List).map((i) => (i as Map)['name']),
        contains('Quarterly zebra report'),
      );
    });

    test(
      'when exporting as markdown and html then the content is inline',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          markdown: '# Title\n\nBody **bold**.',
        );

        final md = await mcp.call('drive.export', {
          'uuid': doc.uuid.uuid,
          'format': 'md',
        });
        final html = await mcp.call('drive.export', {
          'uuid': doc.uuid.uuid,
          'format': 'html',
        });

        expect(md['content'], contains('Body **bold**.'));
        expect(md['download_url'], isA<String>());
        expect(html['content'], contains('<strong>bold</strong>'));
      },
    );

    test(
      'when importing markdown and html then documents are created',
      () async {
        final md = await mcp.call('drive.import', {
          'name': 'From md',
          'kind': 'document',
          'format': 'md',
          'text': '# Hello\n\nWorld',
        });
        final html = await mcp.call('drive.import', {
          'name': 'From html',
          'kind': 'document',
          'format': 'html',
          'content_base64': base64Encode(
            utf8.encode('<h1>Hi</h1><p>There <b>you</b></p>'),
          ),
        });

        final doc = await mcp.call('write.get_document', {
          'document_uuid': (html['item'] as Map)['uuid'],
        });
        expect((md['item'] as Map)['name'], 'From md');
        expect(doc['content'], contains('There **you**'));
      },
    );

    test(
      'when importing a DOCX file then its content becomes a document',
      () async {
        final source = const core.MarkdownCodec()
            .importMarkdown('# Report\n\nSome **bold** text.')
            .delta;
        final docx = await const core.DocxExporter().export(
          core.ExportInput(
            document: source,
            meta: const core.DocMeta(title: 'Report'),
            theme: core.BuiltinThemes.wonkyDefault.theme,
            pageSetup: const core.PageSetup(),
            images: core.MapImageResolver(const {}),
            fonts: FileSystemFontProvider.instance,
            now: DateTime.utc(2026),
          ),
          const core.OfficeExportOptions(),
        );

        final imported = await mcp.call('drive.import', {
          'name': 'From docx',
          'kind': 'document',
          'format': 'docx',
          'content_base64': base64Encode(docx.bytes),
        });
        final doc = await mcp.call('write.get_document', {
          'document_uuid': (imported['item'] as Map)['uuid'],
        });

        expect(doc['content'], contains('Some **bold** text.'));
      },
    );

    test(
      'when importing a spreadsheet from markdown then it is unsupported',
      () async {
        final e = await mcp.error('drive.import', {
          'name': 'Sheet',
          'kind': 'spreadsheet',
          'format': 'md',
          'text': 'a,b',
        });

        expect(e['code'], 'unsupported');
      },
    );
  });

  withWonkyServerpod('Given tokens with limited scopes', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when a drive:read token creates a document then it is forbidden',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final mcp = await McpHarness.forUser(
          anna,
          scopes: [McpScope.driveRead],
        );

        final e = await mcp.error('drive.create_document', {'name': 'X'});

        expect(e['code'], 'forbidden');
        expect((e['details'] as Map)['required_scopes'], [McpScope.driveWrite]);
      },
    );

    test('when a write:read token edits then it is forbidden', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final doc = await TestDrive.document(endpoints, anna, markdown: 'Hi');
      final mcp = await McpHarness.forUser(
        anna,
        scopes: [McpScope.writeRead],
      );

      final read = await mcp.call('write.get_document', {
        'document_uuid': doc.uuid.uuid,
      });
      final e = await mcp.error('write.insert_markdown', {
        'document_uuid': doc.uuid.uuid,
        'markdown': 'x',
        'at': {'type': 'end'},
      });

      expect(read['content'], contains('Hi'));
      expect(e['code'], 'forbidden');
    });

    test('when calling an unknown tool then not_found is returned', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final mcp = await McpHarness.forUser(anna);

      final e = await mcp.error('drive.nope');

      expect(e['code'], 'not_found');
    });

    test(
      'when creating a spreadsheet with only sheets scopes then it is '
      'forbidden',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final mcp = await McpHarness.forUser(
          anna,
          scopes: const [McpScope.sheetsRead, McpScope.sheetsEdit],
        );

        final e = await mcp.error('drive.create_spreadsheet', {'name': 'S'});

        expect(e['code'], 'forbidden');
      },
    );
  });
}
