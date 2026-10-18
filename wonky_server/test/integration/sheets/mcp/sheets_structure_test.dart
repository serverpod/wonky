@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet with a data sheet', (
    sessionBuilder,
    endpoints,
  ) {
    late McpHarness mcp;
    late String ss;

    setUp(() async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Sales',
        sheets: {'Data': SheetsFixtures.sales},
      );
    });
    tearDown(HeadlessWorkbookProvider.clear);

    Future<List<Object?>> read(String range, {String render = 'formatted'}) =>
        SheetsFixtures.read(mcp, ss, range, render: render);

    Future<Map<String, dynamic>> info([List<String>? include]) =>
        mcp.call('sheets.get_spreadsheet', {
          'spreadsheet': ss,
          'include': ?include,
        });

    Future<Map<String, dynamic>> sheetInfo(String name) async {
      final sheets = (await info())['sheets'] as List;
      return sheets.cast<Map<String, dynamic>>().firstWhere(
        (s) => s['name'] == name,
      );
    }

    test(
      'when reading the metadata then the sheet and used range show',
      () async {
        final r = await info();
        expect(r['title'], 'Sales');
        expect(r['role'], 'owner');
        final data = (r['sheets'] as List).single as Map;
        expect(data['name'], 'Data');
        expect(data['used_range'], 'A1:D7');
        expect(data['grid'], {'rows': 1000, 'columns': 26});
        expect(r['cell_count'], 28);
      },
    );

    test('when describing the data then columns are profiled', () async {
      final r = await mcp.call('sheets.describe_data', {'spreadsheet': ss});
      expect(r['range'], 'Data!A1:D7');
      expect(r['header_row'], 1);
      expect(r['rows'], 6);
      final cols = (r['columns'] as List).cast<Map<String, dynamic>>();
      expect(cols[0]['header'], 'Region');
      expect(cols[0]['type'], 'text');
      expect(cols[0]['distinct'], 3);
      expect(cols[2]['type'], 'number');
      expect((cols[2]['numeric'] as Map)['sum'], 590);
      expect((cols[2]['numeric'] as Map)['max'], 200);
      expect(r['tables'], [
        {'range': 'Data!A1:D7', 'header_row': 1},
      ]);
    });

    test(
      'when inserting rows inside a formula range then the formula expands',
      () async {
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!F1',
          'values': [
            ['=SUM(C2:C7)'],
          ],
        });
        final r = await mcp.call('sheets.insert_rows', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'at': 3,
          'count': 2,
        });
        expect(r['inserted_range'], '3:4');
        expect(await read('Data!F1', render: 'formula'), [
          ['=SUM(C2:C9)'],
        ]);
        expect(await read('Data!A3:A5'), [
          [null],
          [null],
          ['South'],
        ]);
        await mcp.call('changes.revert', {'change_id': r['change_id']});
        expect(await read('Data!A3'), [
          ['South'],
        ]);
      },
    );

    test('when deleting rows then data moves up', () async {
      final r = await mcp.call('sheets.delete_rows', {
        'spreadsheet': ss,
        'sheet': 'Data',
        'start': 2,
        'count': 2,
      });
      expect(r['deleted'], 2);
      expect(await read('Data!A2:B2'), [
        ['North', 'Pears'],
      ]);
      final undo = await mcp.call('changes.revert', {
        'change_id': r['change_id'],
      });
      expect(undo['skipped'], isEmpty);
      expect(await read('Data!A2:A3'), [
        ['North'],
        ['South'],
      ]);
    });

    test(
      'when inserting and deleting columns by letter then data shifts',
      () async {
        await mcp.call('sheets.insert_columns', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'at': 'B',
        });
        expect(await read('Data!A1:C1'), [
          ['Region', null, 'Product'],
        ]);
        await mcp.call('sheets.delete_columns', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'start': 'B',
        });
        expect(await read('Data!A1:B1'), [
          ['Region', 'Product'],
        ]);
      },
    );

    test('when moving a column then its values move', () async {
      await mcp.call('sheets.move_dimension', {
        'spreadsheet': ss,
        'sheet': 'Data',
        'dimension': 'columns',
        'start': 'D',
        'destination': 'A',
      });
      expect(await read('Data!A1:B1'), [
        ['Units', 'Region'],
      ]);
    });

    test(
      'when hiding, resizing and freezing then the sheet records it',
      () async {
        await mcp.call('sheets.hide_dimension', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'dimension': 'rows',
          'start': 3,
          'hidden': true,
        });
        await mcp.call('sheets.resize_dimension', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'dimension': 'columns',
          'start': 'A',
          'count': 2,
          'size_px': 180,
        });
        await mcp.call('sheets.resize_dimension', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'dimension': 'columns',
          'start': 'C',
          'auto_fit': true,
        });
        final f = await mcp.call('sheets.set_frozen', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'rows': 1,
          'columns': 1,
        });
        expect(f['change_id'], isNotNull);
        final s = await sheetInfo('Data');
        expect(s['frozen'], {'rows': 1, 'columns': 1});
      },
    );

    test(
      'when managing sheets then add, rename, reorder, duplicate and delete work',
      () async {
        final add = await mcp.call('sheets.add_sheet', {
          'spreadsheet': ss,
          'name': 'Notes',
          'values': [
            ['hello', '=LEN(A1)'],
          ],
        });
        expect((add['sheet'] as Map)['name'], 'Notes');
        expect((add['sheet'] as Map)['index'], 2);
        expect(await read('Notes!A1:B1'), [
          ['hello', '5'],
        ]);
        final dup = await mcp.error('sheets.rename_sheet', {
          'spreadsheet': ss,
          'sheet': 'Notes',
          'new_name': 'data',
        });
        expect(dup['code'], 'duplicate_name');
        await mcp.call('sheets.rename_sheet', {
          'spreadsheet': ss,
          'sheet': 'Notes',
          'new_name': 'Memo',
        });
        await mcp.call('sheets.reorder_sheet', {
          'spreadsheet': ss,
          'sheet': 'Memo',
          'index': 1,
        });
        final copy = await mcp.call('sheets.duplicate_sheet', {
          'spreadsheet': ss,
          'sheet': 'Data',
          'new_name': 'Data copy',
        });
        expect((copy['sheet'] as Map)['name'], 'Data copy');
        expect(await read("'Data copy'!A2"), [
          ['North'],
        ]);
        await mcp.call('sheets.set_sheet_properties', {
          'spreadsheet': ss,
          'sheet': 'Data copy',
          'tab_color': '#FF0000',
        });
        final names = [
          for (final s in (await info())['sheets'] as List) (s as Map)['name'],
        ];
        expect(names, ['Memo', 'Data', 'Data copy']);
        expect((await sheetInfo('Data copy'))['tab_color'], '#FF0000');
        await mcp.call('sheets.delete_sheet', {
          'spreadsheet': ss,
          'sheet': 'Memo',
        });
        final after = [
          for (final s in (await info())['sheets'] as List) (s as Map)['name'],
        ];
        expect(after, ['Data', 'Data copy']);
      },
    );

    test('when formatting a range then the attributes are set', () async {
      final r = await mcp.call('sheets.format_range', {
        'spreadsheet': ss,
        'ranges': ['Data!A1:D1', 'Data!C2:C7'],
        'format': {
          'bold': true,
          'fill_color': '#e8f0fe',
          'h_align': 'center',
          'number_format': 'currency',
          'borders': {
            'bottom': {'style': 'medium', 'color': '#000000'},
          },
        },
      });
      expect(r['change_id'], isNotNull);
      final c = await mcp.call('sheets.get_cell', {
        'spreadsheet': ss,
        'cell': 'Data!C2',
      });
      expect((c['format'] as Map)['bold'], isTrue);
      expect((c['format'] as Map)['fillColor'], '#E8F0FE');
      expect((c['format'] as Map)['hAlign'], 'center');
      expect(c['formatted'], r'$120.00');
      final bad = await mcp.error('sheets.format_range', {
        'spreadsheet': ss,
        'ranges': ['A1'],
        'format': {'text_color': 'red'},
      });
      expect(bad['code'], 'invalid_args');
      await mcp.call('sheets.clear_formats', {
        'spreadsheet': ss,
        'ranges': ['Data!C2'],
      });
      expect(await read('Data!C2'), [
        ['120'],
      ]);
    });

    test('when merging then only the top-left value is kept', () async {
      final r = await mcp.call('sheets.merge_cells', {
        'spreadsheet': ss,
        'range': 'Data!A2:B2',
      });
      expect(r['merged'], ['Data!A2:B2']);
      expect(r['warnings'], contains('Only the top-left value was kept'));
      expect((await sheetInfo('Data'))['merges_count'], 1);
      await mcp.call('sheets.unmerge_cells', {
        'spreadsheet': ss,
        'range': 'Data!A2:B2',
      });
      expect((await sheetInfo('Data'))['merges_count'], 0);
    });

    test('when applying banding then a banding id is returned', () async {
      final r = await mcp.call('sheets.apply_banding', {
        'spreadsheet': ss,
        'range': 'Data!A1:D7',
        'style': '#4285F4',
      });
      expect(r['banding_id'], isA<String>());
    });

    test(
      'when sorting by a column descending then rows are reordered',
      () async {
        await mcp.call('sheets.sort_range', {
          'spreadsheet': ss,
          'range': 'Data!A1:D7',
          'specs': [
            {'column': 'C', 'ascending': false},
          ],
          'has_header': true,
        });
        expect(await read('Data!C1:C7'), [
          ['Revenue'],
          ['200'],
          ['120'],
          ['90'],
          ['80'],
          ['60'],
          ['40'],
        ]);
      },
    );

    test(
      'when finding and replacing then matches are listed and changed',
      () async {
        final f = await mcp.call('sheets.find', {
          'spreadsheet': ss,
          'query': 'pears',
        });
        expect(f['total'], 3);
        expect((f['matches'] as List).first, {
          'a1': 'Data!B3',
          'value': 'Pears',
        });
        final r = await mcp.call('sheets.find_replace', {
          'spreadsheet': ss,
          'query': 'Pears',
          'replacement': 'Plums',
          'match_entire_cell': true,
        });
        expect(r['replaced'], 3);
        expect(await read('Data!B3'), [
          ['Plums'],
        ]);
      },
    );

    test(
      'when evaluating formulas then values come back without writing',
      () async {
        final r = await mcp.call('sheets.evaluate', {
          'spreadsheet': ss,
          'formula': '=SUMIF(A:A,"North",C:C)',
          'sheet': 'Data',
        });
        expect(r['value'], 180);
        expect(r['type'], 'number');
        final arr = await mcp.call('sheets.evaluate', {
          'spreadsheet': ss,
          'formula': '=SEQUENCE(2,2)',
        });
        expect(arr['type'], 'array');
        expect(arr['array'], [
          [1, 2],
          [3, 4],
        ]);
        final bad = await mcp.error('sheets.evaluate', {
          'spreadsheet': ss,
          'formula': '=SUM(1,',
        });
        expect(bad['code'], 'formula_parse_error');
        final v = await mcp.call('sheets.validate_formula', {
          'formula': '=FOO(A1)+SUM(B1:B3)',
        });
        expect(v['ok'], isTrue);
        expect(v['unknown_functions'], ['FOO']);
      },
    );

    test('when explaining a formula then a trace is returned', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!F2',
        'values': [
          ['=C2*D2+1'],
        ],
      });
      final r = await mcp.call('sheets.explain_formula', {
        'spreadsheet': ss,
        'cell': 'Data!F2',
      });
      expect(r['formula'], '=C2*D2+1');
      expect(r['value'], '1201');
      expect((r['trace'] as Map)['expression'], isNotEmpty);
    });

    test('when reading a cell history then MCP writes are listed', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!A2',
        'values': [
          ['West'],
        ],
      });
      final h = await mcp.call('sheets.get_cell_history', {
        'spreadsheet': ss,
        'cell': 'Data!A2',
      });
      expect(h['cell'], 'Data!A2');
      expect(h['entries'], isA<List<Object?>>());
    });
  });
}
