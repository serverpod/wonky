@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/mcp_harness.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// The Markdown flavor of documents (Write 11 §3, §10).
void main() {
  withWonkyServerpod('Given Wonky Markdown documents', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
    });

    Future<String?> flavorOf(DriveItemView item) async =>
        (await endpoints.document.getInfo(
          anna.endpointSession,
          item.contentRef!,
        )).meta.markdownFlavor;

    Future<Delta> contentOf(DriveItemView item) async {
      final s = await endpoints.document.getSnapshot(
        anna.endpointSession,
        item.contentRef!,
        null,
      );
      return Delta.fromJson(jsonDecode(s.deltaJson) as List);
    }

    test('when creating a blank document then it is GitHub Markdown', () async {
      final doc = await TestDrive.document(endpoints, anna);

      expect(await flavorOf(doc), 'gfm');
    });

    test('when creating a document from Markdown with directives then it is '
        'Wonky Markdown and the directives are elements', () async {
      final doc = await TestDrive.document(
        endpoints,
        anna,
        markdown: ':::tip\nUse the CLI.\n:::\n',
      );

      expect(await flavorOf(doc), 'wonky');
      final line = WonkyDocument(await contentOf(doc)).lines.first;
      expect(Boxes.of(line.attributes).single.variant, CalloutVariant.tip);
    });

    test('when changing the flavor then it is stored and validated', () async {
      final doc = await TestDrive.document(endpoints, anna);

      await endpoints.document.updateMeta(
        anna.endpointSession,
        doc.contentRef!,
        DocumentMetaPatch(field: 'markdownFlavor', valueJson: '"wonky"'),
        const Uuid().v7obj(),
      );

      expect(await flavorOf(doc), 'wonky');
      await expectLater(
        endpoints.document.updateMeta(
          anna.endpointSession,
          doc.contentRef!,
          DocumentMetaPatch(field: 'markdownFlavor', valueJson: '"html"'),
          const Uuid().v7obj(),
        ),
        throwsA(anything),
      );
    });

    test('when copying a Wonky document then the copy is Wonky', () async {
      final doc = await TestDrive.document(
        endpoints,
        anna,
        markdown: ':chip[Dart]\n',
      );

      final copy = await endpoints.drive.copy(
        anna.endpointSession,
        doc.uuid,
        'Copy',
        null,
        false,
        false,
      );

      expect(await flavorOf(copy), 'wonky');
    });

    test('when an agent inserts directives in a Wonky document then they '
        'become elements and read back as directives', () async {
      final doc = await TestDrive.document(
        endpoints,
        anna,
        markdown: 'Intro\n',
      );
      await mcp.call('write.set_markdown_flavor', {
        'document_uuid': docOf(doc),
        'flavor': 'wonky',
      });

      await mcp.call('write.insert_markdown', {
        'document_uuid': docOf(doc),
        'at': {'type': 'end'},
        'markdown': ':::warning[Heads up]\nCareful.\n:::\n',
      });
      final read = await mcp.call('write.get_document', {
        'document_uuid': docOf(doc),
      });

      expect(read['markdown_flavor'], 'wonky');
      expect(read['content'], contains(':::warning[Heads up]'));
      expect(read['content'], contains('Careful.'));
    });

    test('when switching back to GitHub then elements are converted, unless '
        'convert is false, and reverting restores the flavor', () async {
      final doc = await TestDrive.document(
        endpoints,
        anna,
        markdown: ':::note\nA note.\n:::\n\n:button[Go](https://example.com)\n',
      );

      final refused = await mcp.error('write.set_markdown_flavor', {
        'document_uuid': docOf(doc),
        'flavor': 'gfm',
        'convert': false,
      });
      expect(refused['code'], 'validation_failed');

      final r = await mcp.call('write.set_markdown_flavor', {
        'document_uuid': docOf(doc),
        'flavor': 'gfm',
      });
      expect(await flavorOf(doc), 'gfm');
      expect(WonkyToGfm.inventory(await contentOf(doc)).isEmpty, isTrue);
      expect(
        const MarkdownCodec().exportMarkdown(await contentOf(doc)),
        contains('> **Note**'),
      );

      await mcp.call('changes.revert', {'change_id': r['change_id']});

      expect(await flavorOf(doc), 'wonky');
    });
  });
}
