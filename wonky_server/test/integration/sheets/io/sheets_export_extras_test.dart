@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/exports/sheets_export_service.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_sheets_core/model.dart' as core;

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet exported by the server', (
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

    Future<DriveItem> item() async => (await DriveItem.db.findFirstRow(
      anna.session,
      where: (t) => t.uuid.equals(UuidValue.fromString(ss)),
    ))!;

    test('when exporting JSON through drive.export then values come back '
        'inline', () async {
      final r = await mcp.call('drive.export', {'uuid': ss, 'format': 'json'});

      expect(r['file_name'], 'Sales.json');
      final json = jsonDecode(r['content'] as String) as Map;
      final sheet = (json['sheets'] as List).single as Map;
      expect(sheet['name'], 'Data');
      expect((sheet['values'] as List)[1], ['North', 'Apples', 120, 10]);
    });

    test('when exporting a PDF then the bundled TTF fonts are embedded and '
        'the dark theme paints the pages', () async {
      final light = await SheetsExportService.exportBytes(
        anna.session,
        await item(),
        core.SheetsExportFormat.pdf,
      );
      final dark = await SheetsExportService.exportBytes(
        anna.session,
        await item(),
        core.SheetsExportFormat.pdf,
        darkTheme: true,
      );

      final text = latin1.decode(light.bytes);
      expect(text, contains('/FontFile2'));
      expect(text, contains('OpenSans'));
      expect(dark.bytes, isNot(equals(light.bytes)));
      expect(dark.pageCount, light.pageCount);
    });

    test('when importing JSON as a new spreadsheet then its sheets are '
        'created', () async {
      final r = await mcp.call('drive.import', {
        'name': 'From JSON',
        'kind': 'spreadsheet',
        'format': 'json',
        'text': jsonEncode({
          'sheets': [
            {
              'name': 'Team',
              'values': [
                ['Name', 'Age'],
                ['Ann', 31],
              ],
              'formulas': [
                [null, null],
                [null, null],
                [null, '=B2+1'],
              ],
            },
          ],
        }),
      });

      final uuid = (r['item'] as Map)['uuid'] as String;
      expect(await SheetsFixtures.read(mcp, uuid, 'Team!B2:B3'), [
        ['31'],
        ['32'],
      ]);
    });
  });
}
