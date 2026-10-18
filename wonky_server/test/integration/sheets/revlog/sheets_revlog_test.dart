@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_rev_binding.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_revlog.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart' hide ActorKind;

import '../../../support/sheets_rev_device.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// Spreadsheets on RevLog end to end (RevLog spec 09 §3): creation through
/// the drive, collaborating devices, protected ranges on the server, the
/// headless workbook, hooks and purge.
void main() {
  withWonkyServerpod('Given a spreadsheet', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser ben;
    late DriveItemView item;
    late UuidValue file;
    final devices = <SheetsRevDevice>[];

    setUpAll(() {
      SheetsRevlog.register();
      RevHooks.debounce = const Duration(hours: 1);
    });
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      item = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Budget',
        null,
      );
      file = item.contentRef!;
      await TestDrive.share(endpoints, item, anna, ben, AccessRole.editor);
    });
    tearDown(() async {
      for (final d in devices) {
        await d.close();
      }
      devices.clear();
      await RevHooks.idle();
    });

    Future<SheetsRevDevice> device(TestUser u) async {
      final d = await SheetsRevDevice.open(u, file);
      devices.add(d);
      return d;
    }

    test(
      'when created then it has one sheet of 1000 rows at revision 1',
      () async {
        final a = await device(anna);
        expect(a.title, 'Budget');
        expect(a.rowCount, 1000);
        expect(a.revision, 1);
      },
    );

    test('when one device types then the other sees it', () async {
      final a = await device(anna);
      final b = await device(ben);
      final ack = await a.setCell(0, 0, '42');
      expect(ack.revision, 2);
      await b.sync();
      expect(b.cell(0, 0), 'n:42');
      final wb = await HeadlessWorkbookProvider.open(
        sessionBuilder.build(),
        file,
      );
      expect(wb.model.cellAt(wb.model.sheets.first.id, 0, 0)?.content, 'n:42');
    });

    test(
      'when a protected range is written by another editor then the server rejects it',
      () async {
        final a = await device(anna);
        final sheet = a.model.sheets.first.id;
        await a.apply(
          AddProtection(sheet, range: const GridRect(0, 0, 4, 1)),
        );
        final b = await device(ben);
        await expectLater(
          b.setCell(1, 1, 'x'),
          throwsA(
            isA<RevDeviceRejected>().having(
              (e) => e.rejected.code,
              'code',
              RevRejectCode.protectedRange,
            ),
          ),
        );
        final details = jsonDecode(b.rejections.single.detailsJson!) as Map;
        expect(details['protections'], hasLength(1));
        // Outside the range is fine.
        expect((await b.setCell(10, 3, 'ok')).revision, greaterThan(2));
      },
    );

    test(
      'when the drive item is renamed then the title follows, and back',
      () async {
        await endpoints.drive.rename(anna.endpointSession, item.uuid, 'Plan');
        final a = await device(anna);
        expect(a.title, 'Plan');
        await a.rename('Forecast');
        final session = sessionBuilder.build();
        final fileRow = await RevFile.db.findFirstRow(
          session,
          where: (t) => t.fileUuid.equals(file),
        );
        await RevHooks.drainNow(
          session.serverpod,
          SheetsRevBinding.instance,
          fileRow!.id!,
          session: session,
        );
        final fresh = await endpoints.drive.get(
          anna.endpointSession,
          item.uuid,
        );
        expect(fresh.name, 'Forecast');
      },
    );

    test('when it is deleted forever then its rows and log are gone', () async {
      final a = await device(anna);
      await a.setCell(0, 0, 'gone');
      await a.close();
      devices.clear();
      final session = sessionBuilder.build();
      final fileRow = (await RevFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(file),
      ))!;
      await endpoints.drive.trash(anna.endpointSession, [item.uuid]);
      await endpoints.drive.deletePermanently(anna.endpointSession, [
        item.uuid,
      ]);
      expect(await RevFile.db.findById(session, fileRow.id!), isNull);
      expect(
        await Spreadsheet.db.findById(session, file),
        isNull,
      );
    });
  });
}
