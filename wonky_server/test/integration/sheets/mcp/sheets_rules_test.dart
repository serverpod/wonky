@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet with sales data', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Sales',
        sheets: {'Data': SheetsFixtures.sales},
      );
    });
    tearDown(HeadlessWorkbookProvider.clear);

    test(
      'when adding conditional formats then they are listed in priority '
      'order and can be updated and deleted',
      () async {
        final a = await mcp.call('sheets.add_conditional_format', {
          'spreadsheet': ss,
          'ranges': ['Data!C2:C7'],
          'rule': {
            'type': 'boolean',
            'condition': {
              'type': 'NUMBER_GREATER',
              'values': ['100'],
            },
            'format': {'bold': true, 'fill_color': '#F4CCCC'},
          },
        });
        final b = await mcp.call('sheets.add_conditional_format', {
          'spreadsheet': ss,
          'ranges': ['Data!D2:D7'],
          'rule': {
            'type': 'color_scale',
            'min_point': {'type': 'min', 'color': '#FFFFFF'},
            'max_point': {'type': 'max', 'color': '#57BB8A'},
          },
        });
        final custom = await mcp.call('sheets.add_conditional_format', {
          'spreadsheet': ss,
          'ranges': ['Data!A2:D7'],
          'rule': {
            'type': 'boolean',
            'condition': {
              'type': 'CUSTOM_FORMULA',
              'values': [r'=$C2>100'],
            },
            'format': {'italic': true},
          },
          'index': 2,
        });
        final list = await mcp.call('sheets.list_conditional_formats', {
          'spreadsheet': ss,
        });
        final rules = (list['rules'] as List).cast<Map<String, dynamic>>();
        expect(
          [for (final r in rules) r['rule_id']],
          [
            b['rule_id'],
            a['rule_id'],
            custom['rule_id'],
          ],
        );
        expect(rules[1]['ranges'], ['Data!C2:C7']);
        expect(
          ((rules[1]['rule'] as Map)['condition'] as Map)['type'],
          'numberGreater',
        );
        await mcp.call('sheets.update_conditional_format', {
          'spreadsheet': ss,
          'rule_id': a['rule_id'],
          'ranges': ['Data!C2:C4'],
          'enabled': false,
        });
        final after = await mcp.call('sheets.list_conditional_formats', {
          'spreadsheet': ss,
          'sheet': 'Data',
        });
        final updated = (after['rules'] as List)
            .cast<Map<String, dynamic>>()
            .firstWhere((r) => r['rule_id'] == a['rule_id']);
        expect(updated['ranges'], ['Data!C2:C4']);
        expect(updated['enabled'], isFalse);
        await mcp.call('sheets.delete_conditional_format', {
          'spreadsheet': ss,
          'rule_id': b['rule_id'],
        });
        final last = await mcp.call('sheets.list_conditional_formats', {
          'spreadsheet': ss,
        });
        expect(last['rules'], hasLength(2));
        final bad = await mcp.error('sheets.add_conditional_format', {
          'spreadsheet': ss,
          'ranges': ['Data!C2:C7'],
          'rule': {
            'type': 'boolean',
            'condition': {'type': 'NUMBER_SOMETHING'},
          },
        });
        expect(bad['code'], 'invalid_args');
      },
    );

    test(
      'when validation is set then violating tool writes succeed with '
      'warnings',
      () async {
        await mcp.call('sheets.set_data_validation', {
          'spreadsheet': ss,
          'ranges': ['Data!A2:A20'],
          'criteria': {
            'type': 'list_of_items',
            'values': ['North', 'South', 'East', 'West'],
          },
          'strict': true,
        });
        final w = await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!A8',
          'values': [
            ['Mars'],
            ['West'],
          ],
        });
        expect(w['validation_warnings'], ['Data!A8']);
        final cell = await mcp.call('sheets.get_cell', {
          'spreadsheet': ss,
          'cell': 'Data!A9',
        });
        expect(
          ((cell['data_validation'] as Map)['criteria'] as Map)['type'],
          'oneOfList',
        );
        await mcp.call('sheets.set_data_validation', {
          'spreadsheet': ss,
          'ranges': ['Data!D2:D20'],
          'criteria': {
            'type': 'number_between',
            'values': ['0', '100'],
          },
        });
        await mcp.call('sheets.set_data_validation', {
          'spreadsheet': ss,
          'ranges': ['Data!A2:A20'],
          'criteria': null,
        });
        final none = await mcp.call('sheets.get_cell', {
          'spreadsheet': ss,
          'cell': 'Data!A9',
        });
        expect(none['data_validation'], isNull);
      },
    );

    test(
      'when creating named ranges then formulas can use them and renames '
      'follow',
      () async {
        final c = await mcp.call('sheets.create_named_range', {
          'spreadsheet': ss,
          'name': 'Revenue',
          'range': 'Data!C2:C7',
        });
        expect(c['named_range_id'], isA<String>());
        final dup = await mcp.error('sheets.create_named_range', {
          'spreadsheet': ss,
          'name': 'revenue',
          'range': 'Data!D2:D7',
        });
        expect(dup['code'], 'duplicate_name');
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!F1',
          'values': [
            ['=SUM(Revenue)'],
          ],
        });
        expect(await SheetsFixtures.read(mcp, ss, 'Data!F1'), [
          ['590'],
        ]);
        await mcp.call('sheets.update_named_range', {
          'spreadsheet': ss,
          'name': 'Revenue',
          'new_name': 'Sales',
        });
        expect(
          await SheetsFixtures.read(mcp, ss, 'Data!F1', render: 'formula'),
          [
            ['=SUM(Sales)'],
          ],
        );
        final list = await mcp.call('sheets.list_named_ranges', {
          'spreadsheet': ss,
        });
        expect(list['named_ranges'], [
          {'name': 'Sales', 'range': 'Data!C2:C7'},
        ]);
        expect(
          (await mcp.call('sheets.get_values', {
            'spreadsheet': ss,
            'ranges': ['Sales'],
          }))['ranges'],
          [
            {
              'range': 'Data!C2:C7',
              'values': [
                ['120'],
                ['80'],
                ['60'],
                ['200'],
                ['90'],
                ['40'],
              ],
              'truncated': false,
            },
          ],
        );
        await mcp.call('sheets.delete_named_range', {
          'spreadsheet': ss,
          'name': 'Sales',
        });
        final empty = await mcp.call('sheets.list_named_ranges', {
          'spreadsheet': ss,
        });
        expect(empty['named_ranges'], isEmpty);
      },
    );

    test(
      'when a range is protected then other editors are blocked with '
      'protected_range and listed editors are not',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final cy = await TestUsers.create(sessionBuilder, name: 'Cy');
        await SheetsFixtures.share(mcp, ss, bo.email, 'editor');
        await SheetsFixtures.share(mcp, ss, cy.email, 'editor');
        final p = await mcp.call('sheets.protect_range', {
          'spreadsheet': ss,
          'range': 'Data!A1:D1',
          'description': 'Headers',
          'editors': [cy.email],
        });
        final boMcp = await McpHarness.forUser(bo);
        final blocked = await boMcp.error('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!A1',
          'values': [
            ['Zone'],
          ],
        });
        expect(blocked['code'], 'protected_range');
        expect((blocked['details'] as Map)['ranges'], ['Data!A1']);
        // Writes outside the protection are fine.
        await boMcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!A2',
          'values': [
            ['West'],
          ],
        });
        final cyMcp = await McpHarness.forUser(cy);
        await cyMcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!A1',
          'values': [
            ['Zone'],
          ],
        });
        final list = await boMcp.call('sheets.list_protections', {
          'spreadsheet': ss,
        });
        final prot = (list['protections'] as List).single as Map;
        expect(prot['range'], 'Data!A1:D1');
        expect(prot['editors'], [cy.email]);
        expect(prot['can_edit'], isFalse);
        final denied = await boMcp.error('sheets.unprotect', {
          'spreadsheet': ss,
          'protection_id': p['protection_id'],
        });
        expect(denied['code'], 'forbidden');
        await mcp.call('sheets.unprotect', {
          'spreadsheet': ss,
          'protection_id': p['protection_id'],
        });
        await boMcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!A1',
          'values': [
            ['Area'],
          ],
        });
      },
    );

    test(
      'when a warning-only protection is hit then the write succeeds with '
      'a warning',
      () async {
        await mcp.call('sheets.protect_range', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'warning_only': true,
        });
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        await SheetsFixtures.share(mcp, ss, bo.email, 'editor');
        final boMcp = await McpHarness.forUser(bo);
        final w = await boMcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!B2',
          'values': [
            ['Kiwis'],
          ],
        });
        expect(w['warnings'], [contains('warning')]);
      },
    );

    test('when setting a filter then hidden values hide rows', () async {
      await mcp.call('sheets.set_basic_filter', {
        'spreadsheet': ss,
        'range': 'Data!A1:D7',
        'criteria': {
          'A': {
            'hidden_values': ['South'],
          },
          'C': {
            'condition': {
              'type': 'NUMBER_GREATER',
              'values': ['50'],
            },
          },
        },
      });
      final info = await mcp.call('sheets.get_spreadsheet', {
        'spreadsheet': ss,
      });
      expect(
        ((info['sheets'] as List).single as Map)['has_basic_filter'],
        isTrue,
      );
      final v = await mcp.call('sheets.create_filter_view', {
        'spreadsheet': ss,
        'range': 'Data!A1:D7',
        'name': 'Big deals',
        'sort': {'column': 'C', 'ascending': false},
      });
      expect(v['url'], contains('?fv=${v['filter_view_id']}'));
      final views = await mcp.call('sheets.list_filter_views', {
        'spreadsheet': ss,
      });
      expect(
        [for (final f in views['filter_views'] as List) (f as Map)['name']],
        ['Big deals'],
      );
      await mcp.call('sheets.delete_filter_view', {
        'spreadsheet': ss,
        'filter_view_id': v['filter_view_id'],
      });
      await mcp.call('sheets.clear_filter', {
        'spreadsheet': ss,
        'sheet': 'Data',
      });
      final cleared = await mcp.error('sheets.clear_filter', {
        'spreadsheet': ss,
        'sheet': 'Data',
      });
      expect(cleared['code'], 'not_found');
    });
  });
}
