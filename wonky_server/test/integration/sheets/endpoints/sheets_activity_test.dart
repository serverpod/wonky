@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_rev_binding.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_revlog.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_rev_device.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// The activity dashboard and the cell history read the RevLog op log
/// (Sheets 10 §5–7, RevLog spec 02 §1).
void main() {
  withWonkyServerpod('Given a spreadsheet edited by a person and an agent', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late DriveItemView item;
    late UuidValue file;

    setUpAll(() {
      SheetsRevlog.register();
      RevHooks.debounce = const Duration(hours: 1);
    });
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      item = await endpoints.drive.createSpreadsheet(
        anna.endpointSession,
        null,
        'Budget',
        null,
      );
      file = item.contentRef!;
      final device = await SheetsRevDevice.open(anna, file);
      try {
        await device.setCell(0, 0, '1');
        await device.setCell(0, 1, '2');
      } finally {
        await device.close();
      }
      await mcp.call('sheets.set_values', {
        'spreadsheet': item.uuid.uuid,
        'range': 'Sheet1!A2',
        'values': [
          ['x'],
        ],
      });
      await mcp.call('sheets.set_values', {
        'spreadsheet': item.uuid.uuid,
        'range': 'Sheet1!A2',
        'values': [
          ['y'],
        ],
      });
    });
    tearDown(() async {
      await RevHooks.idle();
      HeadlessWorkbookProvider.clear();
    });

    test('when the activity is summarized then it counts the edits per kind '
        'and per sheet, without the creation op', () async {
      final a = await endpoints.sheets.activitySummary(
        anna.endpointSession,
        file,
        7,
      );

      expect(a.mcpEdits, 2);
      expect(a.contributors.single.user?.id, anna.id);
      expect(a.contributors.single.edits, 4);
      expect(a.editsPerSheet.values.single, 4);
    });

    test('when the hooks ran then the cell history lists the older values, '
        'newest first, with their revision and actor', () async {
      final f = await RevFile.db.findFirstRow(
        anna.session,
        where: (t) => t.fileUuid.equals(file),
      );
      await RevHooks.drainNow(
        anna.session.serverpod,
        SheetsRevBinding.instance,
        f!.id!,
        session: anna.session,
      );
      final model = (await HeadlessWorkbookProvider.open(
        anna.session,
        file,
      )).model;
      final sheet = model.sheets.first;

      final page = await endpoints.sheets.cellHistory(
        anna.endpointSession,
        file,
        UuidValue.fromString(sheet.id),
        UuidValue.fromString(sheet.rows.idAt(1)),
        UuidValue.fromString(sheet.columns.idAt(0)),
        null,
      );

      expect(page.entries, hasLength(2));
      expect(page.entries.first.actorKind, ActorKind.mcp);
      expect(
        page.entries.first.revision,
        greaterThan(page.entries.last.revision),
      );
      expect(page.entries.first.user?.id, anna.id);
    });
  });
}
