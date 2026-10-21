@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_doc_client.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

Future<Delta> _content(
  TestEndpoints endpoints,
  TestUser user,
  DriveItemView item,
) async {
  final s = await endpoints.document.getSnapshot(
    user.endpointSession,
    item.contentRef!,
    null,
  );
  return Delta.fromJson(jsonDecode(s.deltaJson) as List);
}

Future<String> _markdown(
  TestEndpoints endpoints,
  TestUser user,
  DriveItemView item,
) async => const MarkdownCodec().exportMarkdown(
  await _content(endpoints, user, item),
);

void main() {
  withWonkyServerpod('Given a document read through write.*', (
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
        name: 'Plan',
        markdown: '# Plan\n\nThe old plan.\n\n## Budget\n\nTen euros.\n',
      );
    });

    test(
      'when reading as markdown then the content and revision are returned',
      () async {
        final r = await mcp.call('write.get_document', {
          'document_uuid': docOf(doc),
        });

        expect(r['content'], contains('## Budget'));
        expect(r['title'], 'Plan');
        expect(r['revision'], isA<int>());
        expect(r['truncated'], isFalse);
      },
    );

    test(
      'when reading one section then only that section is returned',
      () async {
        final r = await mcp.call('write.get_document', {
          'document_uuid': docOf(doc),
          'range': {'type': 'heading_section', 'heading': 'Budget'},
        });

        expect(r['content'], contains('Ten euros.'));
        expect(r['content'], isNot(contains('old plan')));
      },
    );

    test(
      'when reading with include_blocks then blocks carry offsets',
      () async {
        final r = await mcp.call('write.get_document', {
          'document_uuid': docOf(doc),
          'include_blocks': true,
        });

        final blocks = (r['blocks'] as List).cast<Map<String, dynamic>>();
        expect(blocks.first['type'], 'heading');
        expect(blocks.first['delta_start'], 0);
      },
    );

    test(
      'when reading the outline then headings with sections are listed',
      () async {
        final r = await mcp.call('write.get_outline', {
          'document_uuid': docOf(doc),
        });

        final headings = (r['headings'] as List).cast<Map<String, dynamic>>();
        expect(headings.map((h) => h['text']), ['Plan', 'Budget']);
        expect(headings[1]['level'], 2);
      },
    );

    test('when searching then matches carry occurrences', () async {
      final r = await mcp.call('write.search', {
        'document_uuid': docOf(doc),
        'query': 'plan',
      });

      expect(r['total'], 2);
      final m = (r['matches'] as List).last as Map;
      expect(m['heading_path'], ['Plan']);
    });

    test('when asking for stats then words are counted', () async {
      final r = await mcp.call('write.get_stats', {
        'document_uuid': docOf(doc),
      });

      expect(r['words'], greaterThan(4));
      expect(r['headings'], 2);
      expect(r['pending_suggestions'], 0);
    });

    test(
      'when reading the page setup then the paper size is resolved',
      () async {
        final r = await mcp.call('write.get_page_setup', {
          'document_uuid': docOf(doc),
        });

        expect((r['paper_size_pt'] as Map)['width'], greaterThan(0));
      },
    );
  });

  withWonkyServerpod('Given a document edited through write.*', (
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
        name: 'Notes',
        markdown: 'Alpha beta.\n\nGamma delta.\n',
      );
    });

    test(
      'when inserting markdown after a quote then one op with a change id is applied',
      () async {
        final before =
            (await mcp.call('write.get_document', {
                  'document_uuid': docOf(doc),
                }))['revision']
                as int;

        final r = await mcp.call('write.insert_markdown', {
          'document_uuid': docOf(doc),
          'markdown': '## New\n\nInserted **text**.',
          'at': {'type': 'after_quote', 'quote': 'Alpha beta.'},
        });

        expect(r['revision'], before + 1);
        expect(r['change_id'], isA<String>());
        final md = await _markdown(endpoints, anna, doc);
        expect(md, contains('## New'));
        expect(md, contains('Inserted **text**.'));
        expect(md.indexOf('## New'), lessThan(md.indexOf('Gamma')));
      },
    );

    test('when replacing text then the occurrence is replaced', () async {
      await mcp.call('write.replace_text', {
        'document_uuid': docOf(doc),
        'find': 'delta',
        'replace': 'omega',
        'occurrence': 1,
      });

      expect(await _markdown(endpoints, anna, doc), contains('Gamma omega.'));
    });

    test('when replacing a quote range then only the range changes', () async {
      final r = await mcp.call('write.replace_range', {
        'document_uuid': docOf(doc),
        'range': {'type': 'quote', 'quote': 'beta'},
        'markdown': '*bravo*',
      });

      expect(await _markdown(endpoints, anna, doc), contains('Alpha *bravo*.'));
      expect(r['applied_range'], isNotNull);
    });

    test('when deleting a block then its line is removed', () async {
      await mcp.call('write.delete_range', {
        'document_uuid': docOf(doc),
        'range': {'type': 'block', 'block_index': 1},
      });

      final md = await _markdown(endpoints, anna, doc);
      expect(md, isNot(contains('Gamma')));
      expect(md, contains('Alpha'));
    });

    test('when formatting a quote bold then the word is bold', () async {
      await mcp.call('write.apply_format', {
        'document_uuid': docOf(doc),
        'range': {'type': 'quote', 'quote': 'Gamma'},
        'set': {'bold': true},
      });

      expect(await _markdown(endpoints, anna, doc), contains('**Gamma**'));
    });

    test(
      'when setting the block type to heading then the line is a heading',
      () async {
        await mcp.call('write.set_block_type', {
          'document_uuid': docOf(doc),
          'range': {'type': 'quote', 'quote': 'Gamma'},
          'type': 'heading',
          'level': 2,
        });

        expect(
          await _markdown(endpoints, anna, doc),
          contains('## Gamma delta.'),
        );
      },
    );

    test(
      'when making a quote line a bullet then it is a list item inside the '
      'quote, and quoted false takes it out',
      () async {
        Future<void> set(Map<String, Object?> args) =>
            mcp.call('write.set_block_type', {
              'document_uuid': docOf(doc),
              'range': {'type': 'quote', 'quote': 'Gamma'},
              ...args,
            });

        await set({'type': 'quote'});
        await set({'type': 'bullet'});
        expect(
          await _markdown(endpoints, anna, doc),
          contains('> - Gamma delta.'),
        );

        await set({'type': 'bullet', 'quoted': false});
        final markdown = await _markdown(endpoints, anna, doc);
        expect(markdown, contains('- Gamma delta.'));
        expect(markdown, isNot(contains('> - Gamma')));
      },
    );

    test(
      'when inserting and updating a table then the table changes',
      () async {
        final r = await mcp.call('write.insert_table', {
          'document_uuid': docOf(doc),
          'at': {'type': 'end'},
          'rows': [
            ['Name', 'Qty'],
            ['Pens', '3'],
          ],
        });
        await mcp.call('write.update_table', {
          'document_uuid': docOf(doc),
          'table': {'table_id': r['table_id']},
          'operations': [
            {'op': 'set_cell', 'row': 1, 'col': 1, 'markdown': '4'},
          ],
        });

        final md = await _markdown(endpoints, anna, doc);
        expect(md, contains('| Pens | 4 |'));
      },
    );

    test('when setting markdown then untouched anchors survive', () async {
      final c = await mcp.call('comments.create', {
        'uuid': docOf(doc),
        'anchor': {'quote': 'Alpha'},
        'body': 'Check this',
      });

      await mcp.call('write.set_markdown', {
        'document_uuid': docOf(doc),
        'markdown': 'Alpha beta.\n\nGamma epsilon.\n',
      });

      final anchors = CommentAnchors.anchors(
        await _content(endpoints, anna, doc),
      );
      expect(anchors[c['thread_uuid']]?.quote, 'Alpha');
      expect(await _markdown(endpoints, anna, doc), contains('Gamma epsilon.'));
    });

    test(
      'when a stale expected_revision is passed then revision_mismatch is returned',
      () async {
        await mcp.call('write.replace_text', {
          'document_uuid': docOf(doc),
          'find': 'Alpha',
          'replace': 'Al',
          'occurrence': 1,
        });

        final e = await mcp.error('write.insert_markdown', {
          'document_uuid': docOf(doc),
          'markdown': 'x',
          'at': {'type': 'start'},
          'expected_revision': 0,
        });

        expect(e['code'], 'revision_mismatch');
        expect((e['details'] as Map)['current_revision'], isA<int>());
      },
    );

    test(
      'when a quote is ambiguous then quote_ambiguous lists the matches',
      () async {
        await mcp.call('write.insert_markdown', {
          'document_uuid': docOf(doc),
          'markdown': 'Alpha again.',
          'at': {'type': 'end'},
        });

        final e = await mcp.error('write.replace_range', {
          'document_uuid': docOf(doc),
          'range': {'type': 'quote', 'quote': 'Alpha'},
          'markdown': 'A',
        });

        expect(e['code'], 'quote_ambiguous');
        expect((e['details'] as Map)['count'], 2);
      },
    );

    test('when a quote is missing then quote_not_found is returned', () async {
      final e = await mcp.error('write.delete_range', {
        'document_uuid': docOf(doc),
        'range': {'type': 'quote', 'quote': 'nowhere'},
      });

      expect(e['code'], 'quote_not_found');
    });

    test(
      'when arguments violate the schema then invalid_args has a pointer',
      () async {
        final e = await mcp.error('write.replace_text', {
          'document_uuid': docOf(doc),
          'find': 'a',
          'replace': 'b',
        });

        expect(e['code'], 'invalid_args');
        expect(e['details'], isNotEmpty);
      },
    );

    test(
      'when reverting a change after a later edit then only that change is undone',
      () async {
        final first = await mcp.call('write.replace_text', {
          'document_uuid': docOf(doc),
          'find': 'Alpha',
          'replace': 'ALPHA',
          'occurrence': 1,
        });
        await mcp.call('write.replace_text', {
          'document_uuid': docOf(doc),
          'find': 'Gamma',
          'replace': 'GAMMA',
          'occurrence': 1,
        });

        final r = await mcp.call('changes.revert', {
          'change_id': first['change_id'],
        });

        final md = await _markdown(endpoints, anna, doc);
        expect(md, contains('Alpha beta.'));
        expect(md, contains('GAMMA delta.'));
        expect(r['change_id'], isNot(first['change_id']));
        final again = await mcp.error('changes.revert', {
          'change_id': first['change_id'],
        });
        expect(again['code'], 'conflict');
      },
    );

    test('when another user reverts my change then it is not found', () async {
      final r = await mcp.call('write.replace_text', {
        'document_uuid': docOf(doc),
        'find': 'Alpha',
        'replace': 'A',
        'occurrence': 1,
      });
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
      final boMcp = await McpHarness.forUser(bo);

      final e = await boMcp.error('changes.revert', {
        'change_id': r['change_id'],
      });

      expect(e['code'], 'not_found');
    });

    test(
      'when updating the page setup and reverting then the setup is restored',
      () async {
        final r = await mcp.call('write.update_page_setup', {
          'document_uuid': docOf(doc),
          // New documents are Pageless (T-1).
          'patch': {'layout': 'pages'},
        });
        var setup = await mcp.call('write.get_page_setup', {
          'document_uuid': docOf(doc),
        });
        expect((setup['page_setup'] as Map)['layout'], 'pages');

        await mcp.call('changes.revert', {'change_id': r['change_id']});

        setup = await mcp.call('write.get_page_setup', {
          'document_uuid': docOf(doc),
        });
        expect((setup['page_setup'] as Map)['layout'], 'pageless');
      },
    );

    test(
      'when inserting an image from base64 then it is stored as a wonky file',
      () async {
        const png =
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
        final r = await mcp.call('write.insert_image', {
          'document_uuid': docOf(doc),
          'at': {'type': 'end'},
          'source': {'base64': png, 'mime': 'image/png'},
          'alt': 'A dot',
        });

        expect(r['file_uuid'], isA<String>());
        final md = await _markdown(endpoints, anna, doc);
        expect(md, contains('![A dot](wonky-file://${r['file_uuid']})'));
      },
    );

    test(
      'when applying a theme then the document uses it and revert clears it',
      () async {
        final themes = await mcp.call('write.list_themes', {});
        final theme = ((themes['themes'] as List).last as Map)['uuid'];

        final r = await mcp.call('write.apply_theme', {
          'document_uuid': docOf(doc),
          'theme_uuid': theme,
        });

        final info = await endpoints.document.getInfo(
          anna.endpointSession,
          doc.contentRef!,
        );
        expect(info.meta.themeId?.uuid, theme);
        await mcp.call('changes.revert', {'change_id': r['change_id']});
        final after = await endpoints.document.getInfo(
          anna.endpointSession,
          doc.contentRef!,
        );
        expect(after.meta.themeId?.uuid, isNot(theme));
      },
    );

    test(
      'when an editor is connected then the MCP edit arrives as a remote op',
      () async {
        final client = await TestDocClient.connect(
          endpoints,
          anna,
          doc.contentRef!,
        );

        await mcp.call('write.insert_markdown', {
          'document_uuid': docOf(doc),
          'markdown': 'Live',
          'at': {'type': 'start'},
          'as': 'inline',
        });
        final joined = await client.next<DocParticipantJoined>();
        final op = await client.next<DocRemoteOp>();

        expect(joined.participant.actorKind, ActorKind.mcp);
        expect(op.actorKind, ActorKind.mcp);
        expect(
          DeltaUtils.text(
            WonkyOt.apply(
              client.document,
              Delta.fromJson(jsonDecode(op.deltaJson) as List),
            ),
          ),
          startsWith('LiveAlpha'),
        );
        await client.close();
      },
    );

    test(
      'when a concurrent edit moved the quote then the quote still targets the right text',
      () async {
        final client = await TestDocClient.connect(
          endpoints,
          anna,
          doc.contentRef!,
        );
        client.edit(Delta()..insert('Intro. '));
        await client.processUntilSynchronized();

        await mcp.call('write.replace_text', {
          'document_uuid': docOf(doc),
          'find': 'Gamma',
          'replace': 'Zeta',
          'occurrence': 1,
        });

        final md = await _markdown(endpoints, anna, doc);
        expect(md, contains('Intro. Alpha beta.'));
        expect(md, contains('Zeta delta.'));
        await client.close();
      },
    );
  });

  withWonkyServerpod('Given suggestions made through write.*', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser carl;
    late McpHarness owner;
    late McpHarness commenter;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      carl = await TestUsers.create(sessionBuilder, name: 'Carl');
      doc = await TestDrive.document(
        endpoints,
        anna,
        name: 'Draft',
        markdown: 'The quick fox.\n',
      );
      await TestDrive.share(endpoints, doc, anna, carl, AccessRole.commenter);
      owner = await McpHarness.forUser(anna);
      commenter = await McpHarness.forUser(carl);
    });

    test(
      'when a commenter edits with mode edit then it is forbidden',
      () async {
        final e = await commenter.error('write.replace_text', {
          'document_uuid': docOf(doc),
          'find': 'quick',
          'replace': 'slow',
          'occurrence': 1,
          'mode': 'edit',
        });

        expect(e['code'], 'forbidden');
      },
    );

    test('when a commenter edits then a suggestion is created', () async {
      final r = await commenter.call('write.replace_text', {
        'document_uuid': docOf(doc),
        'find': 'quick',
        'replace': 'slow',
        'occurrence': 1,
      });

      expect(r['mode'], 'suggest');
      expect(r['suggestion_id'], isA<String>());
      final list = await owner.call('write.list_suggestions', {
        'document_uuid': docOf(doc),
      });
      final s = (list['suggestions'] as List).single as Map;
      expect(s['author'], containsPair('name', 'Carl'));
      expect(s['via'], 'mcp');
    });

    test(
      'when the owner accepts all suggestions then the text changes',
      () async {
        await commenter.call('write.suggest_edit', {
          'document_uuid': docOf(doc),
          'range': {'type': 'quote', 'quote': 'fox'},
          'markdown': 'dog',
        });

        final r = await owner.call('write.accept_suggestion', {
          'document_uuid': docOf(doc),
          'suggestion_ids': 'all',
        });

        expect(r['accepted'], hasLength(1));
        expect(
          await _markdown(endpoints, anna, doc),
          contains('The quick dog.'),
        );
      },
    );

    test('when a commenter accepts then it is forbidden', () async {
      final s = await commenter.call('write.suggest_edit', {
        'document_uuid': docOf(doc),
        'range': {'type': 'quote', 'quote': 'fox'},
        'markdown': 'cat',
      });

      final e = await commenter.error('write.accept_suggestion', {
        'document_uuid': docOf(doc),
        'suggestion_ids': [s['suggestion_id']],
      });

      expect(e['code'], 'forbidden');
    });

    test(
      'when the author withdraws a suggestion then the original stays',
      () async {
        final s = await commenter.call('write.suggest_edit', {
          'document_uuid': docOf(doc),
          'range': {'type': 'quote', 'quote': 'quick'},
          'markdown': 'lazy',
        });

        await commenter.call('write.reject_suggestion', {
          'document_uuid': docOf(doc),
          'suggestion_ids': [s['suggestion_id']],
        });

        expect(
          await _markdown(endpoints, anna, doc),
          contains('The quick fox.'),
        );
      },
    );
  });
}
