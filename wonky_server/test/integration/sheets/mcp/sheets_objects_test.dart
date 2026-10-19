@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/mcp/wonky_mcp_server.dart';
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

    test(
      'when creating a chart then it is listed, readable, renderable as PNG, '
      'updatable and deletable',
      () async {
        final c = await mcp.call('sheets.create_chart', {
          'spreadsheet': ss,
          'data_ranges': ['Data!A1:A7', 'Data!C1:C7'],
          'type': 'column',
          'options': {'title': 'Revenue by region', 'legend': 'none'},
        });
        expect(c['type'], 'column');
        expect(c['anchor'], 'C1');
        final id = c['chart_id'] as String;
        final info = await mcp.call('sheets.get_spreadsheet', {
          'spreadsheet': ss,
        });
        final chart = (info['charts'] as List).single as Map;
        expect(chart['title'], 'Revenue by region');
        expect(chart['data_ranges'], ['Data!A1:A7', 'Data!C1:C7']);

        final g = await mcp.call('sheets.get_chart', {
          'spreadsheet': ss,
          'chart_id': id,
        });
        expect((g['data_summary'] as Map)['points'], 6);
        expect(
          ((g['spec'] as Map)['data'] as Map)['ranges'],
          ['Data!A1:A7', 'Data!C1:C7'],
        );
        expect(g['description'], isNotEmpty);

        final outcome = await WonkyMcpServer.executor.call(
          mcp.ctx,
          'sheets.export_chart_png',
          {'spreadsheet': ss, 'chart_id': id, 'width': 300, 'height': 200},
        );
        final png = base64Decode(outcome.result!.images.single.base64Data);
        expect(png.sublist(1, 4), utf8.encode('PNG'));

        await mcp.call('sheets.update_chart', {
          'spreadsheet': ss,
          'chart_id': id,
          'patch': {'type': 'line'},
          'options': {'title': 'Trend'},
          'anchor_cell': 'Data!H2',
        });
        final after = await mcp.call('sheets.get_chart', {
          'spreadsheet': ss,
          'chart_id': id,
        });
        expect((after['spec'] as Map)['type'], 'line');
        expect(after['anchor'], 'H2');
        expect(after['title'], 'Trend');

        await mcp.call('sheets.delete_chart', {
          'spreadsheet': ss,
          'chart_id': id,
        });
        final gone = await mcp.error('sheets.get_chart', {
          'spreadsheet': ss,
          'chart_id': id,
        });
        expect(gone['code'], 'not_found');
      },
    );

    test('when no type is given then the recommended chart is used', () async {
      final c = await mcp.call('sheets.create_chart', {
        'spreadsheet': ss,
        'data_ranges': ['Data!A1:A7', 'Data!C1:C7'],
        'own_sheet': true,
        'options': {'title': 'Share'},
      });
      expect(c['type'], isNotEmpty);
      expect(c['sheet'], 'Share');
      final bad = await mcp.error('sheets.create_chart', {
        'spreadsheet': ss,
        'data_ranges': ['Data!A1:C7'],
        'type': 'hologram',
      });
      expect(bad['code'], 'unsupported');
    });

    test(
      'when creating a pivot table then it lands on a new sheet with its '
      'computed output range',
      () async {
        final p = await mcp.call('sheets.create_pivot_table', {
          'spreadsheet': ss,
          'source': 'Data!A1:D7',
          'rows': [
            {'source_column': 'Region'},
          ],
          'values': [
            {'source_column': 'Revenue', 'summarize_by': 'sum'},
          ],
        });
        expect(p['sheet'], 'Pivot Table 1');
        expect(p['anchor'], 'A1');
        // Header + 3 regions + grand total, two columns.
        expect(p['output_range'], "'Pivot Table 1'!A1:B5");
        final info = await mcp.call('sheets.get_spreadsheet', {
          'spreadsheet': ss,
        });
        final pivot = (info['pivots'] as List).single as Map;
        expect(pivot['source'], 'Data!A1:D7');

        await mcp.call('sheets.update_pivot_table', {
          'spreadsheet': ss,
          'pivot_id': p['pivot_id'],
          'columns': [
            {'source_column': 'B'},
          ],
        });
        final unknown = await mcp.error('sheets.update_pivot_table', {
          'spreadsheet': ss,
          'pivot_id': p['pivot_id'],
          'rows': [
            {'source_column': 'Country'},
          ],
        });
        expect(unknown['code'], 'invalid_args');
        await mcp.call('sheets.delete_pivot_table', {
          'spreadsheet': ss,
          'pivot_id': p['pivot_id'],
        });
        final none = await mcp.call('sheets.get_spreadsheet', {
          'spreadsheet': ss,
        });
        expect(none['pivots'], isEmpty);
      },
    );
  });
}
