@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_server/src/platform/common/models.dart'
    show Cell, DriveItem, ServerChangeRecord;
import 'package:wonky_server/src/sheets/revlog/sheets_server_writes.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/mcp/sheets_bulk_writer.dart';
import 'package:wonky_server/src/sheets/mcp/sheets_mcp_support.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart' hide ActorKind;
import 'package:wonky_sync_models/ids.dart';

import '../../support/mcp_harness.dart';
import '../../support/sheets_fixtures.dart';
import '../../support/sheets_rev_hooks.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Server writes of spreadsheets as RevLog ops (`SheetsBulkWriter` over
/// `SheetsServerWrites`, RevLog spec 05 §8): new, re-inserted and updated
/// rows, and changes that insert and then change or delete a row in one
/// call.
void main() {
  withWonkyServerpod('Given a spreadsheet written by the bulk writer', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late UuidValue space;
    late SheetModel sheet;

    SheetsRevHooks.install();

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      final ss = await SheetsFixtures.create(
        mcp,
        sheets: {
          'Data': [
            ['a', 1],
          ],
        },
      );
      final (item, _) = await SheetsMcp.resolveItem(
        anna.session,
        mcp.ctx,
        ss,
        min: Role.viewer,
      );
      space = item.contentRef!;
      final wb = await HeadlessWorkbookProvider.open(anna.session, space);
      sheet = wb.model.sheetByName('Data')!;
    });
    tearDown(HeadlessWorkbookProvider.clear);

    String cellId(int r, int c) =>
        SheetsIds.cellId(sheet.id, sheet.rows.idAt(r), sheet.columns.idAt(c));

    RowChange newCell(int r, int c, Map<String, Object?> columns) =>
        RowChange.insert(SheetsTables.cell, cellId(r, c), {
          Cols.sheetId: sheet.id,
          CellCols.rowId: sheet.rows.idAt(r),
          CellCols.columnId: sheet.columns.idAt(c),
          Cols.createdAt: clock.now().toUtc(),
          ...columns,
        });

    Future<void> apply(List<RowChange> changes) => SheetsBulkWriter.apply(
      anna.session,
      actor: anna.actor,
      spaceUuid: space,
      changes: changes,
      label: 'Test',
      plans: const [],
    );

    /// Stored cell rows by id (their JSON).
    Future<Map<String, Map<String, Object?>>> cells(List<String> ids) async => {
      for (final r in await Cell.db.find(
        anna.session,
        where: (t) =>
            t.id.inSet({for (final id in ids) UuidValue.fromString(id)}),
      ))
        r.id.uuid: r.toJson(),
    };

    test('when a recorded change failed after some ops were committed then '
        'they get an incomplete record that reverts them', () async {
      final recordId = const Uuid().v7obj();
      final item = (await DriveItem.db.findFirstRow(
        anna.session,
        where: (t) => t.contentRef.equals(space),
      ))!;
      // The first chunk of a change that failed later.
      await SheetsServerWrites.apply(
        anna.session,
        actor: anna.actor,
        fileUuid: space,
        changes: [
          newCell(6, 0, {CellCols.content: 's:partial'}),
        ],
        label: 'Big paste',
        recordId: recordId,
      );

      final none = await SheetsServerWrites.recordPartial(
        anna.session,
        actor: anna.actor,
        item: item,
        label: 'Nothing',
        recordId: const Uuid().v7obj(),
      );
      final changeId = await SheetsServerWrites.recordPartial(
        anna.session,
        actor: anna.actor,
        item: item,
        label: 'Big paste',
        recordId: recordId,
      );
      final record = await ServerChangeRecord.db.findFirstRow(
        anna.session,
        where: (t) => t.changeId.equals(changeId!),
      );
      await SheetsServerWrites.revert(
        anna.session,
        anna.actor,
        item,
        changeId!,
      );

      expect(none, isNull);
      expect(record!.label, 'Big paste (incomplete)');
      expect(await cells([cellId(6, 0)]), isEmpty);
    });

    test('when one change inserts a row and then updates it, then the row '
        'carries both', () async {
      await apply([
        newCell(4, 0, {CellCols.content: 's:x'}),
        RowChange.update(
          SheetsTables.cell,
          cellId(4, 0),
          const {CellCols.bold: null},
          const {CellCols.bold: true},
        ),
      ]);
      final row = (await cells([cellId(4, 0)]))[cellId(4, 0)]!;
      expect(row[CellCols.content], 's:x');
      expect(row[CellCols.bold], isTrue);
    });

    test('when one change inserts a row and then deletes it, then no row is '
        'left', () async {
      final insert = newCell(5, 0, {CellCols.content: 's:gone'});
      await apply([
        insert,
        RowChange.delete(SheetsTables.cell, cellId(5, 0), insert.columnsAfter),
      ]);
      expect(await cells([cellId(5, 0)]), isEmpty);
    });

    test('when many rows are inserted, updated, deleted and inserted again, '
        'then every step is visible with its own values', () async {
      final ids = [
        for (var r = 0; r < 30; r++)
          for (var c = 2; c < 6; c++) (r, c),
      ];
      await apply([
        for (final (r, c) in ids) newCell(r, c, {CellCols.content: 's:$r.$c'}),
      ]);
      await apply([
        for (final (r, c) in ids)
          RowChange.update(
            SheetsTables.cell,
            cellId(r, c),
            {CellCols.content: 's:$r.$c'},
            {CellCols.content: 'n:${r * c}', CellCols.italic: true},
          ),
      ]);
      var rows = await cells([for (final (r, c) in ids) cellId(r, c)]);
      expect(rows, hasLength(ids.length));
      expect(rows[cellId(7, 3)]![CellCols.content], 'n:21');
      expect(rows[cellId(7, 3)]![CellCols.italic], isTrue);

      await apply([
        for (final (r, c) in ids)
          RowChange.delete(SheetsTables.cell, cellId(r, c), const {}),
      ]);
      expect(await cells([for (final (r, c) in ids) cellId(r, c)]), isEmpty);

      // Re-inserting the deleted ids revives them with the new values.
      await apply([
        for (final (r, c) in ids) newCell(r, c, {CellCols.content: 's:back'}),
      ]);
      rows = await cells([for (final (r, c) in ids) cellId(r, c)]);
      expect(rows, hasLength(ids.length));
      expect(rows[cellId(7, 3)]![CellCols.content], 's:back');
      expect(rows[cellId(7, 3)]![CellCols.italic], isNull);
    });
  });
}
