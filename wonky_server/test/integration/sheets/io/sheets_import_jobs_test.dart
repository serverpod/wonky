@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/imports/sheets_import_jobs.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

Future<UuidValue> _upload(TestUser user, String fileName, String text) async {
  final file = await FileService.storeServerFile(
    user.session,
    ownerId: user.id,
    kind: StoredFileKind.importSource,
    fileName: fileName,
    mimeType: 'text/csv',
    bytes: Uint8List.fromList(utf8.encode(text)),
  );
  return file.fileUuid;
}

String _rows(int n) => [
  'Id,Name',
  for (var i = 1; i <= n; i++) '$i,Item $i',
].join('\n');

void main() {
  withWonkyServerpod('Given a spreadsheet and a server import job', (
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
        name: 'Budget',
        sheets: {
          'Data': [
            ['Existing'],
          ],
        },
      );
    });
    tearDown(() {
      SheetsImportJobs.beforeChunk = null;
      SheetsImportJobs.chunkSize = 5000;
      SheetsImportJobs.leaseDuration = const Duration(minutes: 2);
      HeadlessWorkbookProvider.clear();
    });

    Future<List<SheetsImportProgress>> watch(UuidValue job) =>
        endpoints.sheetsImport.watchImport(anna.endpointSession, job).toList();

    test(
      'when importing a CSV as new sheets then the job reports progress, '
      'the sheet exists, and reverting its change removes it again',
      () async {
        final upload = await _upload(anna, 'orders.csv', _rows(3));

        final job = await endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'insertSheets'}),
          null,
        );
        final events = await watch(job);

        final last = events.last;
        expect(last.status, SheetsImportStatus.done, reason: '${last.error}');
        expect(last.done, last.total);
        expect(last.changeId, isNotNull);
        expect(last.sheetIds, hasLength(1));
        final report = jsonDecode(last.reportJson!) as Map;
        expect((report['sheets'] as List).single['name'], 'orders');
        expect(await SheetsFixtures.read(mcp, ss, 'orders!A1:B2'), [
          ['Id', 'Name'],
          ['1', 'Item 1'],
        ]);
        expect(await FileService.byUuid(anna.session, upload), isNull);

        await endpoints.sheets.revertChange(
          anna.endpointSession,
          last.changeId!,
        );
        HeadlessWorkbookProvider.clear();
        final err = await mcp.error('sheets.get_values', {
          'spreadsheet': ss,
          'ranges': ['orders!A1'],
        });
        expect(err['code'], isNotNull);
      },
    );

    test(
      'when appending to the current sheet then the rows follow its last row',
      () async {
        final upload = await _upload(anna, 'more.csv', 'Next\nAfter');

        final job = await endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'append'}),
          null,
        );
        final last = (await watch(job)).last;

        expect(last.status, SheetsImportStatus.done, reason: '${last.error}');
        expect(await SheetsFixtures.read(mcp, ss, 'Data!A1:A3'), [
          ['Existing'],
          ['Next'],
          ['After'],
        ]);
      },
    );

    test(
      'when the job is cancelled while writing then the written chunks are '
      'reverted and it ends cancelled',
      () async {
        SheetsImportJobs.chunkSize = 20;
        final upload = await _upload(anna, 'big.csv', _rows(60));
        late UuidValue job;
        SheetsImportJobs.beforeChunk = (chunk, chunks) async {
          if (chunk == 2) {
            await endpoints.sheetsImport.cancelImport(
              anna.endpointSession,
              job,
            );
          }
        };

        job = await endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'replaceSheet'}),
          null,
        );
        final last = (await watch(job)).last;

        expect(last.status, SheetsImportStatus.cancelled);
        HeadlessWorkbookProvider.clear();
        expect(await SheetsFixtures.read(mcp, ss, 'Data!A1'), [
          ['Existing'],
        ]);
      },
    );

    test(
      'when a big import is written in chunks then its ops share one record '
      'and reverting it undoes every chunk',
      () async {
        SheetsImportJobs.chunkSize = 20;
        final upload = await _upload(anna, 'big.csv', _rows(60));

        final job = await endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'replaceSheet'}),
          null,
        );
        final last = (await watch(job)).last;

        expect(last.status, SheetsImportStatus.done, reason: '${last.error}');
        final record = (await ServerChangeRecord.db.findFirstRow(
          anna.session,
          where: (t) => t.changeId.equals(last.changeId!),
        ))!;
        final ops = await RevOp.db.find(
          anna.session,
          where: (t) => t.recordId.equals(record.recordId!),
        );
        expect(ops.length, greaterThan(3));
        expect(record.cellsAffected, greaterThanOrEqualTo(120));
        expect(await SheetsFixtures.read(mcp, ss, 'Data!A61'), [
          ['60'],
        ]);

        await endpoints.sheets.revertChange(
          anna.endpointSession,
          last.changeId!,
        );
        expect(await SheetsFixtures.read(mcp, ss, 'Data!A1'), [
          ['Existing'],
        ]);
      },
    );

    test(
      'when a phase takes longer than the lease then the lease is renewed '
      'and the job is not marked interrupted (CQ-9)',
      () async {
        SheetsImportJobs.leaseDuration = const Duration(milliseconds: 600);
        SheetsImportJobs.beforeChunk = (chunk, chunks) async {
          if (chunk == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 1500));
          }
        };
        final upload = await _upload(anna, 'slow.csv', _rows(3));

        final job = await endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'insertSheets'}),
          null,
        );
        final events = await watch(job);

        expect(events.last.status, SheetsImportStatus.done);
        expect(
          events.map((e) => e.status),
          isNot(contains(SheetsImportStatus.failed)),
        );
      },
    );

    test('when the location is "create new" then it is rejected', () async {
      final upload = await _upload(anna, 'x.csv', 'a');

      expect(
        () => endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'createNew'}),
          null,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when another user without access imports then it is refused',
      () async {
        final ben = await TestUsers.create(sessionBuilder, name: 'Ben');
        final upload = await _upload(ben, 'x.csv', 'a');

        expect(
          () => endpoints.sheetsImport.importInto(
            ben.endpointSession,
            UuidValue.fromString(ss),
            upload,
            jsonEncode({'location': 'append'}),
            null,
          ),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      'when another user watches the job then it is not found',
      () async {
        final ben = await TestUsers.create(sessionBuilder, name: 'Ben');
        final upload = await _upload(anna, 'y.csv', 'a');
        final job = await endpoints.sheetsImport.importInto(
          anna.endpointSession,
          UuidValue.fromString(ss),
          upload,
          jsonEncode({'location': 'append'}),
          null,
        );

        expect(
          () => endpoints.sheetsImport.importProgress(ben.endpointSession, job),
          throwsA(isA<WonkyException>()),
        );
        await watch(job);
      },
    );
  });
}
