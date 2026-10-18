@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet created through MCP', (
    sessionBuilder,
    endpoints,
  ) {
    late McpHarness mcp;
    late String ss;

    setUp(() async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(mcp, name: 'Budget');
    });
    tearDown(HeadlessWorkbookProvider.clear);

    Future<List<Object?>> read(String range, {String render = 'formatted'}) =>
        SheetsFixtures.read(mcp, ss, range, render: render);

    test(
      'when writing values with formulas then they read back formatted, '
      'unformatted and as A1 formulas',
      () async {
        final w = await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Sheet1!A1',
          'values': [
            ['Item', 'Price', 'Qty', 'Total'],
            ['Apples', 1.5, 4, '=B2*C2'],
            ['Pears', '2.25', 2, '=B3*C3'],
            ['Sum', null, null, '=SUM(D2:D3)'],
          ],
        });
        expect(w['change_id'], isA<String>());
        expect(w['cells_affected'], 14);
        expect(w['updated_range'], 'Sheet1!A1:D4');

        final values = await read('Sheet1!A1:D4');
        expect(values[1], ['Apples', '1.5', '4', '6']);
        expect(values[3], ['Sum', null, null, '10.5']);
        expect(await read('D2:D4', render: 'formula'), [
          ['=B2*C2'],
          ['=B3*C3'],
          ['=SUM(D2:D3)'],
        ]);
        expect(await read('B2:D3', render: 'unformatted'), [
          [1.5, 4, 6],
          [2.25, 2, 4.5],
        ]);
      },
    );

    test('when writing with input raw then strings stay text', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'A1',
        'values': [
          ['=1+1', '42'],
        ],
        'input': 'raw',
      });
      expect(await read('A1:B1', render: 'unformatted'), [
        ['=1+1', '42'],
      ]);
    });

    test(
      'when user-entered values look like dates and percents then they are '
      'parsed like typing',
      () async {
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': [
            ['2026-03-01', '12%', "'007"],
          ],
        });
        expect(await read('A1:C1', render: 'unformatted'), [
          ['2026-03-01', 0.12, '007'],
        ]);
        expect(await read('A1:C1'), [
          [isNotEmpty, '12%', '007'],
        ]);
      },
    );

    test('when the values do not match a full range then it fails', () async {
      final e = await mcp.error('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'A1:B2',
        'values': [
          ['a'],
        ],
      });
      expect(e['code'], 'invalid_args');
    });

    test('when a formula does not parse then nothing is written', () async {
      final e = await mcp.error('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'A1',
        'values': [
          ['ok', '=SUM(A1'],
        ],
      });
      expect(e['code'], 'formula_parse_error');
      expect(await read('A1'), isEmpty);
    });

    test('when a range names an unknown sheet then invalid_range', () async {
      final e = await mcp.error('sheets.get_values', {
        'spreadsheet': ss,
        'ranges': ['Nope!A1'],
      });
      expect(e['code'], 'invalid_range');
      expect((e['details'] as Map)['sheets'], ['Sheet1']);
    });

    test('when writing more than 50,000 cells then limit_exceeded', () async {
      final e = await mcp.error('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'A1',
        'values': List.generate(501, (_) => List.filled(100, 1)),
      });
      expect(e['code'], 'limit_exceeded');
    });

    test(
      'when values extend past the grid then the grid grows',
      () async {
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Z1',
          'values': [
            ['z', 'aa', 'ab'],
          ],
        });
        expect(await read('Z1:AB1'), [
          ['z', 'aa', 'ab'],
        ]);
        final info = await mcp.call('sheets.get_spreadsheet', {
          'spreadsheet': ss,
        });
        final sheet = (info['sheets'] as List).first as Map;
        expect((sheet['grid'] as Map)['columns'], 28);
      },
    );

    test('when batch writing two ranges then one change covers both', () async {
      final w = await mcp.call('sheets.batch_set_values', {
        'spreadsheet': ss,
        'data': [
          {
            'range': 'A1',
            'values': [
              ['a'],
            ],
          },
          {
            'range': 'C3',
            'values': [
              [3, '=C3*2'],
            ],
          },
        ],
      });
      expect(w['cells_affected'], 3);
      expect(await read('C3:D3'), [
        ['3', '6'],
      ]);
      await mcp.call('changes.revert', {'change_id': w['change_id']});
      expect(await read('A1:D3'), isEmpty);
    });

    test('when appending rows then they land after the table', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'B2',
        'values': [
          ['Name', 'Score'],
          ['Ann', 3],
        ],
      });
      final r = await mcp.call('sheets.append_rows', {
        'spreadsheet': ss,
        'range': 'Sheet1',
        'values': [
          ['Bo', 5],
          ['Cy', 7],
        ],
      });
      expect(r['table_range'], 'Sheet1!B2:C3');
      expect(r['updated_range'], 'Sheet1!B4:C5');
      expect(await read('B2:C5'), [
        ['Name', 'Score'],
        ['Ann', '3'],
        ['Bo', '5'],
        ['Cy', '7'],
      ]);
    });

    test('when clearing contents then formats stay', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'A1',
        'values': [
          [1, 2],
        ],
      });
      await mcp.call('sheets.format_range', {
        'spreadsheet': ss,
        'ranges': ['A1:B1'],
        'format': {'bold': true},
      });
      await mcp.call('sheets.clear_range', {
        'spreadsheet': ss,
        'ranges': ['A1:B1'],
      });
      expect(await read('A1:B1'), isEmpty);
      final cell = await mcp.call('sheets.get_cell', {
        'spreadsheet': ss,
        'cell': 'A1',
      });
      expect((cell['format'] as Map)['bold'], isTrue);
    });

    test(
      'when reading a large range page by page then every row comes back '
      'exactly once',
      () async {
        final rows = List.generate(
          300,
          (r) => List.generate(10, (c) => r * 10 + c),
        );
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': rows,
        });
        final seen = <Object?>[];
        String? cursor;
        var pages = 0;
        do {
          final r = await mcp.call('sheets.get_values', {
            'spreadsheet': ss,
            'ranges': ['A:J'],
            'render': 'unformatted',
            'max_cells': 700,
            'cursor': ?cursor,
          });
          final range = (r['ranges'] as List).first as Map;
          seen.addAll(range['values'] as List);
          cursor = r['next_cursor'] as String?;
          pages++;
        } while (cursor != null);
        expect(pages, 5);
        expect(seen, rows);
      },
    );

    test('when reading by columns then the values are transposed', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'A1',
        'values': [
          [1, 2],
          [3, 4],
        ],
      });
      final r = await mcp.call('sheets.get_values', {
        'spreadsheet': ss,
        'ranges': ['A1:B2'],
        'major_dimension': 'columns',
      });
      expect((r['ranges'] as List).first['values'], [
        ['1', '3'],
        ['2', '4'],
      ]);
    });

    test(
      'when reverting a set_values then the cells are empty again',
      () async {
        final w = await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'A1',
          'values': [
            ['x', 1],
          ],
        });
        final r = await mcp.call('changes.revert', {
          'change_id': w['change_id'],
        });
        expect(r['reverted_cells'], 2);
        expect(await read('A1:B1'), isEmpty);
        final again = await mcp.error('changes.revert', {
          'change_id': w['change_id'],
        });
        expect(again['code'], 'conflict');
      },
    );

    test('when importing CSV then values and formulas are converted', () async {
      final r = await mcp.call('sheets.import_csv', {
        'spreadsheet': ss,
        'csv_text': 'Name;Amount\nAnn;12\nBo;=B2*2\n',
        'target': {'mode': 'new_sheet', 'sheet_name': 'Imported'},
      });
      expect(r['rows'], 3);
      expect((r['sheet'] as Map)['name'], 'Imported');
      expect(await read('Imported!A1:B3'), [
        ['Name', 'Amount'],
        ['Ann', '12'],
        ['Bo', '24'],
      ]);
      final b64 = await mcp.call('sheets.import_csv', {
        'spreadsheet': ss,
        'content_base64': base64Encode(utf8.encode('x,y\n1,2\n')),
        'target': {'mode': 'append', 'sheet': 'Imported'},
      });
      expect(b64['updated_range'], 'Imported!A4:B5');
    });
  });
}
