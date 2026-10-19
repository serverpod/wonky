@Tags(['integration'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope;
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/slides/charts/slides_chart_service.dart';
import 'package:wonky_server/src/slides/exports/slides_export_service.dart';
import 'package:wonky_server/src/slides/headless/deck_text_claims.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/slides/mcp/slides_writes.dart';

import '../../../support/file_fixtures.dart';
import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_presence.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

const _outline = '''
<!-- group: Intro color=blue -->
# Q3 Review
Board meeting
---
## Highlights
- Revenue up 18 %
  - EMEA +25 %
- 3 new customers
Notes:
Mention the EMEA team.
---
<!-- group: none -->
## The new API
```dart
final user = await client.users.get(id);
```
''';

Matcher _error(String code) =>
    throwsA(isA<McpCallError>().having((e) => e.code, 'code', code));

/// The headless `slides.*` tools through `ToolExecutor` (Slides 11 §3,
/// §10; specs/15 §6 MCP).
void main() {
  withWonkyServerpod('Given the slides tools', (sessionBuilder, endpoints) {
    late TestUser anna;
    late McpHarness mcp;

    setUpAll(() {
      DeckTextClaims.probeWait = const Duration(milliseconds: 300);
    });
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
    });
    tearDown(() {
      DeckAgentPresence.clear();
      DeckTextClaims.clear();
      HeadlessFileCache.clear();
      HeadlessWorkbookProvider.clear();
      SlidesChartService.reset();
      SlidesExportService.clearCache();
    });

    Future<String> create({String? outline, String name = 'Q3'}) async {
      final r = await mcp.call('drive.create_presentation', {
        'name': name,
        'outline_markdown': ?outline,
      });
      return r['deck_uuid'] as String;
    }

    Future<Map<String, dynamic>> deck(String uuid, [McpHarness? who]) =>
        (who ?? mcp).call('slides.get_deck', {
          'deck': uuid,
          'include': ['groups', 'slides', 'layouts'],
        });

    Future<Map<String, dynamic>> slide(
      String uuid,
      Object ref, [
      Map<String, Object?> extra = const {},
    ]) => mcp.call('slides.get_slide', {
      'deck': uuid,
      'slide': ref,
      ...extra,
    });

    Map<String, dynamic> placeholder(Map<String, dynamic> s, String type) =>
        (s['elements'] as List).cast<Map<String, dynamic>>().firstWhere(
          (e) => (e['placeholder'] as Map?)?['type'] == type,
        );

    group('create_presentation', () {
      test('when creating from an outline then slides, groups, notes, '
          'layouts and code are built as one revertible change', () async {
        final r = await mcp.call('drive.create_presentation', {
          'name': 'Q3 Review',
          'theme': 'wonky',
          'outline_markdown': _outline,
        });

        expect((r['item'] as Map)['kind'], 'presentation');
        expect(r['slide_ids'], hasLength(3));
        expect(r['change_id'], isNotNull);
        final d = await deck(r['deck_uuid'] as String);
        final slides = (d['slides'] as List).cast<Map<String, dynamic>>();
        expect(
          [for (final s in slides) s['title']],
          [
            'Q3 Review',
            'Highlights',
            'The new API',
          ],
        );
        expect(
          [for (final s in slides) (s['layout'] as Map)['key']],
          [
            'titleBody',
            'titleBody',
            'code',
          ],
        );
        expect((d['groups'] as List).single, containsPair('title', 'Intro'));
        expect(((d['groups'] as List).single as Map)['slide_ids'], [
          slides[0]['slide_id'],
          slides[1]['slide_id'],
        ]);
        expect(slides[1]['has_notes'], isTrue);
        final s2 = await slide(r['deck_uuid'] as String, 2);
        expect(
          placeholder(s2, 'body')['text'],
          '- Revenue up 18 %\n  - EMEA +25 %\n- 3 new customers',
        );
        expect(s2['notes_markdown'], 'Mention the EMEA team.');
        final s3 = await slide(r['deck_uuid'] as String, 3, {
          'include': ['elements', 'data'],
        });
        final code = (s3['elements'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((e) => e['kind'] == 'code');
        expect((code['data'] as Map)['language'], 'dart');

        final reverted = await mcp.call('changes.revert', {
          'change_id': r['change_id'],
        });

        expect(reverted['deck'], r['deck_uuid']);
        final after = await deck(r['deck_uuid'] as String);
        expect(after['slide_count'], 1);
      });

      test('when a viewer token has no drive:write then creating is '
          'forbidden', () async {
        final readOnly = await McpHarness.forUser(
          anna,
          scopes: [McpScope.slidesRead, McpScope.slidesEdit],
        );

        await expectLater(
          readOnly.call('drive.create_presentation', {'name': 'X'}),
          _error('forbidden'),
        );
      });

      test('when the outline has more than 200 slides then it is refused '
          'with limit_exceeded', () async {
        final uuid = await create();
        final md = List.generate(201, (i) => '## S$i').join('\n---\n');

        await expectLater(
          mcp.call('slides.add_slides_from_markdown', {
            'deck': uuid,
            'markdown': md,
          }),
          _error('limit_exceeded'),
        );
      });
    });

    group('slides and text', () {
      test('when adding slides at a position into a new group then they '
          'land there with their text, notes and group', () async {
        final uuid = await create(outline: '# One\n---\n## Two');

        final r = await mcp.call('slides.add_slides', {
          'deck': uuid,
          'slides': [
            {
              'layout': 'titleBody',
              'title': 'Plan',
              'body': '- a\n- b',
              'notes': 'Say **hi**',
            },
            {'layout': 'section', 'title': 'Break', 'skipped': true},
          ],
          'at': {'position': 2},
          'group': {
            'new': {'title': 'Middle', 'color': 'green'},
          },
        });

        expect(r['positions'], [2, 3]);
        expect((r['created'] as Map)['group_ids'], hasLength(1));
        final d = await deck(uuid);
        final titles = [for (final s in d['slides'] as List) s['title']];
        expect(titles, ['One', 'Plan', 'Break', 'Two']);
        expect((d['slides'] as List)[2]['skipped'], isTrue);
        expect(
          ((d['groups'] as List).single as Map)['title'],
          'Middle',
        );
        expect((await slide(uuid, 2))['notes_markdown'], 'Say **hi**');
      });

      test('when a layout key is unknown then the slide falls back with a '
          'layout_fallback warning', () async {
        final uuid = await create();

        final r = await mcp.call('slides.add_slides', {
          'deck': uuid,
          'slides': [
            {'layout': 'nope', 'title': 'X'},
          ],
        });

        expect(
          r['warnings'],
          contains(containsPair('code', 'layout_fallback')),
        );
      });

      test('when setting text by placeholder then get_slide returns the '
          'same Markdown and append keeps the old text', () async {
        final uuid = await create(outline: '# T\n---\n## Body slide\n- x');
        const md = '**Bold** start\n- one\n  - two\n1. first\n> quoted';

        await mcp.call('slides.set_text', {
          'deck': uuid,
          'element': {'slide': 2, 'placeholder': 'body'},
          'text': md,
        });
        final s = await slide(uuid, 2);
        expect(placeholder(s, 'body')['text'], md);

        await mcp.call('slides.set_text', {
          'deck': uuid,
          'element': {'slide': 2, 'placeholder': 'body'},
          'text': 'tail',
          'mode': 'append',
        });
        final after = await slide(uuid, 2);
        expect(placeholder(after, 'body')['text'], '$md\ntail');
      });

      test('when setting text on a table then invalid_target names the '
          'right tool', () async {
        final uuid = await create();
        final t = await mcp.call('slides.add_elements', {
          'deck': uuid,
          'slide': 1,
          'elements': [
            {
              'kind': 'table',
              'table': {
                'rows': [
                  ['A', 'B'],
                  ['1', '2'],
                ],
              },
            },
          ],
        });

        final e = await mcp.error('slides.set_text', {
          'deck': uuid,
          'element': (t['element_ids'] as List).single,
          'text': 'x',
        });

        expect(e['code'], 'invalid_target');
        expect(e['message'], contains('set_table_cells'));
      });

      test('when formatting a quote and replacing text then the attributes '
          'and the count are reported', () async {
        final uuid = await create(
          outline: '# T\n---\n## Hello world\nworld peace',
        );

        await mcp.call('slides.format_text', {
          'deck': uuid,
          'element': {'slide': 2, 'placeholder': 'body'},
          'range': {'quote': 'peace'},
          'format': {'bold': true, 'color': '#ff0000'},
        });
        final r = await mcp.call('slides.replace_text', {
          'deck': uuid,
          'find': 'world',
          'replace': 'planet',
        });

        expect(r['replaced'], 2);
        final s = await slide(uuid, 2, {'text_format': 'rich'});
        final body = placeholder(s, 'body')['text'] as Map;
        expect(body['markdown'], 'planet **peace**');
        expect(
          body['runs'],
          contains(
            containsPair('attrs', {'bold': true, 'color': '#ff0000'}),
          ),
        );
        expect(
          (placeholder(s, 'title')['text'] as Map)['markdown'],
          'Hello planet',
        );
      });

      test('when moving, duplicating and deleting slides then the order '
          'follows and each call is one change', () async {
        final uuid = await create(outline: '# A\n---\n## B\n---\n## C');

        await mcp.call('slides.move_slides', {
          'deck': uuid,
          'slides': [3],
          'to': {'position': 1},
        });
        final dup = await mcp.call('slides.duplicate_slides', {
          'deck': uuid,
          'slides': [1],
        });
        await mcp.call('slides.delete_slides', {
          'deck': uuid,
          'slides': [3],
        });

        final d = await deck(uuid);
        expect(
          [for (final s in d['slides'] as List) s['title']],
          [
            'C',
            'C',
            'B',
          ],
        );
        expect((dup['created'] as Map)['slide_ids'], hasLength(1));
      });

      test('when updating a slide then layout, background, notes and '
          'transition change', () async {
        final uuid = await create(outline: '# A\n---\n## B\n- x');

        await mcp.call('slides.update_slide', {
          'deck': uuid,
          'slide': 2,
          'layout': 'twoColumns',
          'background': '#112233',
          'notes': 'n',
          'transition': {
            'type': 'push',
            'params': {'direction': 'left'},
          },
        });

        final s = await slide(uuid, 2);
        expect((s['layout'] as Map)['key'], 'twoColumns');
        expect(((s['background'] as Map)['fill'] as Map)['color'], '#112233');
        expect((s['transition'] as Map)['type'], 'push');
        expect(s['notes_markdown'], 'n');
      });
    });

    group('groups', () {
      test('when creating, renaming, moving, duplicating and ungrouping '
          'then the deck follows', () async {
        final uuid = await create(outline: '# A\n---\n## B\n---\n## C');
        final g = await mcp.call('slides.create_group', {
          'deck': uuid,
          'title': 'Part',
          'slides': [2, 3],
        });
        final id = g['group_id'] as String;

        await mcp.call('slides.update_group', {
          'deck': uuid,
          'group_id': id,
          'title': 'Part 1',
          'skipped': true,
        });
        await mcp.call('slides.move_group', {
          'deck': uuid,
          'group_id': id,
          'to': {'position': 1},
        });
        final d1 = await deck(uuid);
        expect(
          [for (final s in d1['slides'] as List) s['title']],
          [
            'B',
            'C',
            'A',
          ],
        );
        expect((d1['groups'] as List).single, containsPair('skipped', true));

        await mcp.call('slides.duplicate_group', {
          'deck': uuid,
          'group_id': id,
        });
        await mcp.call('slides.ungroup', {'deck': uuid, 'group_id': id});
        final d2 = await deck(uuid);
        expect(d2['slide_count'], 5);
        expect(d2['groups'], hasLength(1));

        await mcp.call('slides.delete_group', {
          'deck': uuid,
          'group_id': ((d2['groups'] as List).single as Map)['group_id'],
          'delete_slides': true,
        });
        expect((await deck(uuid))['slide_count'], 3);
      });
    });

    group('elements', () {
      test('when adding text, shapes, icons, lines and tables then each is '
          'created where asked', () async {
        final uuid = await create();

        final r = await mcp.call('slides.add_elements', {
          'deck': uuid,
          'slide': 1,
          'elements': [
            {
              'kind': 'text',
              'text': 'Hello',
              'frame': {'x': 100, 'y': 100, 'w': 400, 'h': 100},
              'name': 'Greeting',
            },
            {
              'kind': 'shape',
              'shape': {'geometry': 'ellipse'},
              'placement': {'preset': 'rightHalf'},
              'style': {'fill': 'theme:accent1', 'opacity': 0.5},
            },
            {
              'kind': 'icon',
              'icon': {'name': 'rocket'},
            },
            {
              'kind': 'line',
              'line': {
                'from': {'x': 0, 'y': 0},
                'to': {
                  'element': {'slide': 1, 'name': 'Greeting'},
                },
                'arrows': {'end': 'triangle'},
              },
            },
          ],
        });

        final ids = (r['element_ids'] as List).cast<String>();
        expect(ids, hasLength(4));
        final text = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': ids[0],
        });
        expect(text['text'], 'Hello');
        expect(text['frame'], {'x': 100, 'y': 100, 'w': 400, 'h': 100});
        final shape = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': ids[1],
        });
        expect((shape['data'] as Map)['geometry'], 'ellipse');
        expect((shape['frame'] as Map)['x'], greaterThan(900));
        final line = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': ids[3],
        });
        expect(
          ((line['data'] as Map)['connects'] as List).single,
          containsPair('element_id', ids[0]),
        );
      });

      test('when updating, duplicating, grouping, aligning and deleting '
          'elements then each change applies', () async {
        final uuid = await create();
        final r = await mcp.call('slides.add_elements', {
          'deck': uuid,
          'slide': 1,
          'elements': [
            {
              'kind': 'text',
              'text': 'A',
              'frame': {'x': 100, 'y': 100, 'w': 200, 'h': 100},
            },
            {
              'kind': 'text',
              'text': 'B',
              'frame': {'x': 500, 'y': 300, 'w': 200, 'h': 100},
            },
          ],
        });
        final ids = (r['element_ids'] as List).cast<String>();

        await mcp.call('slides.update_elements', {
          'deck': uuid,
          'updates': [
            {
              'element': ids[0],
              'frame': {'x': 120},
              'style': {
                'text': {'size': 60, 'align': 'center'},
              },
              'alt_text': 'First',
              'z': 'front',
            },
          ],
        });
        await mcp.call('slides.align_elements', {
          'deck': uuid,
          'elements': ids,
          'op': 'top',
        });
        final dup = await mcp.call('slides.duplicate_elements', {
          'deck': uuid,
          'elements': [ids[1]],
        });
        final g = await mcp.call('slides.group_elements', {
          'deck': uuid,
          'elements': ids,
        });
        await mcp.call('slides.ungroup_elements', {
          'deck': uuid,
          'element': g['group_element_id'],
        });
        await mcp.call('slides.delete_elements', {
          'deck': uuid,
          'elements': (dup['element_ids'] as List),
        });

        final a = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': ids[0],
          'text_format': 'plain',
        });
        expect(a['alt_text'], 'First');
        expect((a['frame'] as Map)['x'], 120);
        expect((a['frame'] as Map)['y'], 100);
        final b = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': ids[1],
        });
        expect((b['frame'] as Map)['y'], 100);
        expect(
          (dup['element_ids'] as List),
          hasLength(1),
        );
      });

      test(
        'when editing a table then rows are inserted and cells set',
        () async {
          final uuid = await create();
          final t = await mcp.call('slides.add_elements', {
            'deck': uuid,
            'slide': 1,
            'elements': [
              {
                'kind': 'table',
                'table': {
                  'rows': [
                    ['Region', 'Growth'],
                    ['EMEA', '25 %'],
                  ],
                },
              },
            ],
          });
          final id = (t['element_ids'] as List).single;

          await mcp.call('slides.set_table_cells', {
            'deck': uuid,
            'element': id,
            'insert_rows': [
              {'at': 2},
            ],
            'cells': [
              {'row': 2, 'column': 0, 'text': '**APAC**'},
              {'row': 2, 'column': 1, 'text': '9 %', 'fill': '#ffeecc'},
            ],
          });

          final e = await mcp.call('slides.get_element', {
            'deck': uuid,
            'element': id,
          });
          expect((e['data'] as Map)['cells'], [
            ['Region', 'Growth'],
            ['EMEA', '25 %'],
            ['**APAC**', '9 %'],
          ]);
        },
      );

      test('when adding an uploaded image then it is copied into the deck '
          'with its size and the storage is returned', () async {
        final uuid = await create();
        final file = await mcp.call('drive.upload_file', {
          'name': 'image.png',
          'content_base64': base64Encode(FileFixtures.bytes('image.png')),
        });

        final r = await mcp.call('slides.add_elements', {
          'deck': uuid,
          'slide': 1,
          'elements': [
            {
              'kind': 'image',
              'image': {'file_uuid': (file['item'] as Map)['uuid']},
              'alt_text': 'A picture',
            },
          ],
        });

        expect(r['storage'], isNotNull);
        final e = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': (r['element_ids'] as List).single,
        });
        expect((e['data'] as Map)['file_uuid'], isNotNull);
        expect((e['data'] as Map)['natural_width'], greaterThan(0));
      });
    });

    group('code and builds', () {
      test('when adding a code block with three states and all steps then '
          'states and one build per step are created', () async {
        final uuid = await create(
          outline: '# T\n---\n<!-- layout: code -->\n## Code',
        );

        final r = await mcp.call('slides.add_code_block', {
          'deck': uuid,
          'slide': 2,
          'language': 'dart',
          'states': [
            {'code': 'var a = 1;', 'highlight': '1'},
            {'code': 'var a = 1;\nvar b = 2;', 'label': 'Add b'},
            {
              'code': 'var a = 1;\nvar b = 2;\nprint(a + b);',
              'highlight': '1-2 | 3',
              'callouts': {'2': 'Prints 3'},
            },
          ],
          'builds': 'all_steps',
        });

        final s = await slide(uuid, 2, {
          'include': ['elements', 'data', 'builds', 'timeline'],
        });
        final code = (s['elements'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((e) => e['element_id'] == r['element_id']);
        expect(((code['data'] as Map)['states'] as List), hasLength(3));
        // 1 highlight step + state 2 + state 3 + 2 highlight steps.
        expect(s['builds'], hasLength(5));
        expect((s['timeline'] as Map)['steps'], 5);

        await mcp.call('slides.set_code_states', {
          'deck': uuid,
          'element': r['element_id'],
          'states': [
            {'code': 'x'},
          ],
          'builds': 'none',
        });
        await mcp.call('slides.update_code_block', {
          'deck': uuid,
          'element': r['element_id'],
          'language': 'python',
          'options': {'line_numbers': true},
        });
        final after = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': r['element_id'],
        });
        expect((after['data'] as Map)['states'], hasLength(1));
        expect((after['data'] as Map)['language'], 'python');
        expect(after['builds'], isEmpty);
      });

      test('when setting builds then unknown effects are refused with the '
          'allowed ids and valid ones compile a timeline', () async {
        final uuid = await create(outline: '# T\n---\n## B\n- a\n- b');

        final bad = await mcp.error('slides.set_builds', {
          'deck': uuid,
          'slide': 2,
          'builds': [
            {
              'element': {'slide': 2, 'placeholder': 'body'},
              'kind': 'build_in',
              'effect': 'explode',
            },
          ],
        });
        expect(bad['code'], 'invalid_args');
        expect(bad['message'], contains('fade'));

        final r = await mcp.call('slides.set_builds', {
          'deck': uuid,
          'slide': 2,
          'builds': [
            {
              'element': {'slide': 2, 'placeholder': 'title'},
              'kind': 'build_in',
              'effect': 'fade',
            },
            {
              'element': {'slide': 2, 'placeholder': 'body'},
              'kind': 'build_in',
              'effect': 'rise',
              'trigger': 'after_previous',
              'delivery': {'by': 'paragraph'},
            },
          ],
        });
        expect((r['created'] as Map)['build_ids'], hasLength(2));
        expect((r['timeline'] as Map)['steps'], greaterThanOrEqualTo(1));

        final buildId = ((r['created'] as Map)['build_ids'] as List).first;
        await mcp.call('slides.update_build', {
          'deck': uuid,
          'build_id': buildId,
          'patch': {'duration_ms': 900, 'trigger': 'with_previous'},
        });
        final s = await slide(uuid, 2, {
          'include': ['builds'],
        });
        expect(
          (s['builds'] as List).first,
          allOf(
            containsPair('duration_ms', 900),
            containsPair('trigger', 'with_previous'),
          ),
        );
        await mcp.call('slides.delete_builds', {'deck': uuid, 'slide': 2});
        expect(
          (await slide(uuid, 2, {
            'include': ['builds'],
          }))['builds'],
          isEmpty,
        );
      });

      test('when setting a Magic Move transition and the default for all '
          'then the slides carry them', () async {
        final uuid = await create(outline: '# A\n---\n## B');

        await mcp.call('slides.set_transition', {
          'deck': uuid,
          'slides': [2],
          'transition': {'type': 'magicMove'},
        });
        expect(
          ((await slide(uuid, 2))['transition'] as Map)['type'],
          'magicMove',
        );
        await mcp.call('slides.set_transition', {
          'deck': uuid,
          'slides': 'all',
          'transition': {'type': 'fade', 'duration_ms': 400},
        });
        expect((await slide(uuid, 2))['transition'], isNull);
      });
    });

    group('linked charts', () {
      late String ss;
      late String chartId;

      setUp(() async {
        ss = await SheetsFixtures.create(
          mcp,
          name: 'Finance 2026',
          sheets: {'Data': SheetsFixtures.sales},
        );
        final c = await mcp.call('sheets.create_chart', {
          'spreadsheet': ss,
          'data_ranges': ['Data!A1:A7', 'Data!C1:C7'],
          'type': 'column',
          'options': {'title': 'Revenue by region'},
        });
        chartId = c['chart_id'] as String;
      });

      test('when listing and inserting a linked chart then it is linked and '
          'refreshing reports it up to date', () async {
        final uuid = await create(
          outline: '# T\n---\n<!-- layout: chart -->\n## Chart',
        );

        final list = await mcp.call('slides.list_sheet_charts', {
          'spreadsheet': ss,
        });
        expect(
          (list['charts'] as List).single,
          containsPair('chart_id', chartId),
        );
        final r = await mcp.call('slides.insert_linked_chart', {
          'deck': uuid,
          'slide': 2,
          'spreadsheet': ss,
          'chart_id': chartId,
        });
        final e = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': r['element_id'],
        });
        expect(
          ((e['data'] as Map)['link'] as Map)['chart_id'],
          chartId,
        );
        expect((e['data'] as Map)['title'], 'Revenue by region');
        expect(e['placeholder'], containsPair('type', 'chart'));

        final refreshed = await mcp.call('slides.refresh_linked_charts', {
          'deck': uuid,
        });
        expect(refreshed['up_to_date'], [r['element_id']]);

        await mcp.call('slides.unlink_chart', {
          'deck': uuid,
          'element': r['element_id'],
        });
        final static = await mcp.call('slides.get_element', {
          'deck': uuid,
          'element': r['element_id'],
        });
        expect((static['data'] as Map)['source'], 'static');
      });

      test('when the token lacks sheets:read then chart tools are '
          'forbidden', () async {
        final uuid = await create();
        final slidesOnly = await McpHarness.forUser(
          anna,
          scopes: [McpScope.slidesRead, McpScope.slidesEdit],
        );

        await expectLater(
          slidesOnly.call('slides.insert_linked_chart', {
            'deck': uuid,
            'slide': 1,
            'spreadsheet': ss,
            'chart_id': chartId,
          }),
          _error('forbidden'),
        );
      });

      test('when the deck has a link but the spreadsheet does not then the '
          'insert warns broader_audience', () async {
        final uuid = await create();
        await mcp.call('drive.set_link_sharing', {
          'uuid': uuid,
          'mode': 'viewer',
        });

        final r = await mcp.call('slides.insert_linked_chart', {
          'deck': uuid,
          'slide': 1,
          'spreadsheet': ss,
          'chart_id': chartId,
        });

        expect(
          r['warnings'],
          contains(containsPair('code', 'broader_audience')),
        );
      });
    });

    group('reads, search, export and permissions', () {
      test(
        'when searching then text, notes and code matches are listed',
        () async {
          final uuid = await create(outline: _outline);

          final r = await mcp.call('slides.search', {
            'deck': uuid,
            'query': 'e(mea|nd)',
            'regex': true,
          });

          expect(
            [for (final m in r['matches'] as List) m['in']],
            containsAll(['text', 'notes']),
          );
          final code = await mcp.call('slides.search', {
            'deck': uuid,
            'query': 'client',
            'in': ['code'],
          });
          expect((code['matches'] as List).single, containsPair('position', 3));
        },
      );

      test('when exporting then a PDF and the outline Markdown are '
          'returned', () async {
        final uuid = await create(outline: _outline);

        final pdf = await mcp.call('slides.export_pdf', {'deck': uuid});
        final md = await mcp.call('drive.export', {
          'uuid': uuid,
          'format': 'md',
        });

        expect(pdf['page_count'], 3);
        expect(pdf['download_url'], isNotEmpty);
        expect(md['content'], contains('## Highlights'));
        expect(md['content'], contains('Notes:'));
      });

      test('when a viewer uses the tools then reads work and edits are '
          'forbidden; strangers get not_found', () async {
        final uuid = await create(outline: '# A');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final cy = await TestUsers.create(sessionBuilder, name: 'Cy');
        await mcp.call('drive.share', {
          'uuid': uuid,
          'email': bo.email,
          'role': 'viewer',
          'notify': false,
        });
        final boMcp = await McpHarness.forUser(bo);
        final cyMcp = await McpHarness.forUser(cy);

        expect((await deck(uuid, boMcp))['role'], 'viewer');
        await expectLater(
          boMcp.call('slides.add_slides', {
            'deck': uuid,
            'slides': [
              {'title': 'X'},
            ],
          }),
          _error('forbidden'),
        );
        await expectLater(
          cyMcp.call('slides.get_deck', {'deck': uuid}),
          _error('not_found'),
        );
      });

      test('when the token has only slides:read then mutating tools are '
          'refused', () async {
        final uuid = await create(outline: '# A');
        final reader = await McpHarness.forUser(
          anna,
          scopes: [McpScope.slidesRead],
        );

        expect(
          (await reader.call('slides.get_deck', {'deck': uuid}))['slide_count'],
          1,
        );
        await expectLater(
          reader.call('slides.delete_slides', {
            'deck': uuid,
            'slides': [1],
          }),
          _error('forbidden'),
        );
      });

      test('when an unknown slide is addressed then not_found points to '
          'the argument', () async {
        final uuid = await create();

        final e = await mcp.error('slides.get_slide', {
          'deck': uuid,
          'slide': 7,
        });

        expect(e['code'], 'not_found');
        expect(e['details'], containsPair('pointer', '/slide'));
      });
    });

    group('soft locks', () {
      test('when another user is editing a body then set_text fails with '
          'being_edited unless forced', () async {
        final uuid = await create(outline: '# A\n---\n## B\nbody');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        await mcp.call('drive.share', {
          'uuid': uuid,
          'email': bo.email,
          'role': 'editor',
          'notify': false,
        });
        final s = await slide(uuid, 2);
        final body = placeholder(s, 'body')['element_id'] as String;
        final item = UuidValue.withValidation(uuid);
        final editor = await TestPresence.join(endpoints, bo, item);
        final watcher = await TestPresence.join(endpoints, anna, item);
        addTearDown(() async {
          await editor.close();
          await watcher.close();
        });
        await editor.send(
          watcher: watcher,
          PresenceUpdate(
            state: PresenceState.active,
            cursorJson: jsonEncode({
              'route': 'editor',
              'slideId': s['slide_id'],
              'editing': {
                'kind': 'text',
                'slideId': s['slide_id'],
                'elementId': body,
                'since': 1,
                'forced': false,
              },
            }),
          ),
        );

        final e = await mcp.error('slides.set_text', {
          'deck': uuid,
          'element': body,
          'text': 'Agent text',
        });
        final forced = await mcp.call('slides.set_text', {
          'deck': uuid,
          'element': body,
          'text': 'Agent text',
          'force': true,
        });

        expect(e['code'], 'being_edited');
        expect(
          (e['details'] as Map)['targets'],
          contains(containsPair('user', 'Bo')),
        );
        expect(forced['change_id'], isNotNull);
      });
    });

    test('when a write is recorded then the change log carries the MCP '
        'actor and label and the agent shows in presence', () async {
      final uuid = await create();

      final r = await mcp.call('slides.add_slides', {
        'deck': uuid,
        'slides': [
          {'title': 'X'},
        ],
      });

      expect(r['sync_version'], isNotNull);
      final record = await ServerChangeRecord.db.findFirstRow(
        anna.session,
        where: (t) => t.changeId.equals(
          UuidValue.withValidation(r['change_id'] as String),
        ),
      );
      expect(record!.label, 'MCP: add_slides (1)');
      final item = await DriveItem.db.findFirstRow(
        anna.session,
        where: (t) => t.uuid.equals(UuidValue.withValidation(uuid)),
      );
      expect(
        DeckAgentPresence.isShown(item!, mcp.ctx.actor),
        isTrue,
      );
    });
  });
}
