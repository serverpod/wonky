@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_sheets_core/model.dart' as core;

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

Future<UuidValue> _upload(
  TestUser user,
  String fileName,
  List<int> bytes,
) async {
  final file = await FileService.storeServerFile(
    user.session,
    ownerId: user.id,
    kind: StoredFileKind.importSource,
    fileName: fileName,
    mimeType: 'application/octet-stream',
    bytes: Uint8List.fromList(bytes),
  );
  return file.fileUuid;
}

/// An XLSX with two sheets written by the core exporter.
Uint8List _xlsx() {
  final doc = core.CsvImporter.importText(
    'Item,Price\nApples,1.5\nPears,2\nTotal,=SUM(B2:B3)\n',
    const core.CsvImportOptions(sheetName: 'Prices'),
  );
  final other = core.CsvImporter.importText(
    'a,b\n1,2\n',
    const core.CsvImportOptions(sheetName: 'Other'),
  );
  doc.sheets.add(other.sheets.single);
  return core.XlsxExporter.export(
    doc,
    core.XlsxExportOptions(modified: DateTime.utc(2026)),
  );
}

void main() {
  withWonkyServerpod('Given a user importing files as spreadsheets', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
    });
    tearDown(HeadlessWorkbookProvider.clear);

    test(
      'when importing a semicolon CSV through drive.import then a spreadsheet '
      'with converted values exists and its item uuid is its space',
      () async {
        final upload = await _upload(
          anna,
          'orders-2026.csv',
          utf8.encode('Order;Amount\n1001;12.5\n1002;=B2*2\n'),
        );

        final report = await endpoints.drive.import(
          anna.endpointSession,
          upload,
          DriveItemKind.spreadsheet,
          DriveImportOptions(),
        );

        expect(report.item.name, 'orders-2026');
        expect(report.item.kind, DriveItemKind.spreadsheet);
        expect(report.item.contentRef, report.item.uuid);
        final values = await SheetsFixtures.read(
          mcp,
          report.item.uuid.uuid,
          'A1:B3',
        );
        expect(values, [
          ['Order', 'Amount'],
          ['1001', '12.5'],
          ['1002', '25'],
        ]);
      },
    );

    test(
      'when importing an XLSX with a sheet selection then only that sheet is '
      'imported with its formula',
      () async {
        final upload = await _upload(anna, 'prices.xlsx', _xlsx());

        final report = await endpoints.drive.import(
          anna.endpointSession,
          upload,
          DriveItemKind.spreadsheet,
          DriveImportOptions(
            optionsJson: jsonEncode({
              'sheets': ['Prices'],
            }),
          ),
        );

        final ss = report.item.uuid.uuid;
        expect(await SheetsFixtures.read(mcp, ss, 'Prices!A4:B4'), [
          ['Total', '3.5'],
        ]);
        expect(
          await SheetsFixtures.read(mcp, ss, 'Prices!B4', render: 'formula'),
          [
            ['=SUM(B2:B3)'],
          ],
        );
        final err = await mcp.error('sheets.get_values', {
          'spreadsheet': ss,
          'ranges': ['Other!A1'],
        });
        expect(err['code'], isNotNull);
      },
    );

    test('when importing a legacy .xls then it is rejected', () async {
      final upload = await _upload(anna, 'old.xls', [0xd0, 0xcf, 0x11, 0xe0]);

      expect(
        () => endpoints.drive.import(
          anna.endpointSession,
          upload,
          DriveItemKind.spreadsheet,
          DriveImportOptions(),
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when importing CSV text through MCP drive.import then the item is '
      'created with the given name',
      () async {
        final r = await mcp.call('drive.import', {
          'name': 'Team',
          'kind': 'spreadsheet',
          'format': 'csv',
          'text': 'Name,Age\nAnn,31\n',
          'options': {'convert': false},
        });

        final item = r['item'] as Map;
        expect(item['name'], 'Team');
        expect(
          await SheetsFixtures.read(
            mcp,
            item['uuid'] as String,
            'B2',
            render: 'unformatted',
          ),
          [
            ['31'],
          ],
        );
      },
    );
  });

  withWonkyServerpod('Given a spreadsheet exported through drive.export', (
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

    test('when exporting CSV then the values come back inline', () async {
      final r = await mcp.call('drive.export', {'uuid': ss, 'format': 'csv'});

      expect(r['file_name'], 'Sales - Data.csv');
      expect(
        r['content'],
        startsWith('Region,Product,Revenue,Units\r\nNorth,Apples,120,10\r\n'),
      );
    });

    test(
      'when exporting XLSX, ODS, PDF and HTML then download urls are returned',
      () async {
        for (final f in ['xlsx', 'ods', 'pdf', 'html']) {
          final r = await mcp.call('drive.export', {'uuid': ss, 'format': f});
          expect(r['download_url'], isA<String>(), reason: f);
          expect(r['size_bytes'] as int, greaterThan(100), reason: f);
          if (f == 'pdf') expect(r['page_count'], 1);
        }
      },
    );
  });
}
