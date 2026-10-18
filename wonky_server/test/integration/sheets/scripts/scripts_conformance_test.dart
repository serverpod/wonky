@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart' hide Dimension;
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_server_writes.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput, TriggerKind;
import 'package:wonky_sheets_script/native.dart';
import 'package:wonky_sheets_script/testing.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'script_support.dart';

/// The API conformance corpus (09 §21.1) against a workbook stored in and
/// loaded from the database (the headless workbook of server executions).
void main() {
  withWonkyServerpod('Given the conformance fixture stored on the server', (
    sessionBuilder,
    endpoints,
  ) {
    late List<(String, Map<String, Object?>)> rows;
    late String spreadsheetId;
    late ScriptProgram program;
    final runner = IsolateScriptRunner();

    setUpAll(() async {
      enableScripting();
      program = compileScript(conformanceProgramSource());
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final mcp = await McpHarness.forUser(anna);
      final ss = await SheetsFixtures.create(
        mcp,
        name: 'Fixture',
        sheets: {
          'Sheet1': [
            [1, 2, 3],
            [4, 5, 6],
            ['a', 'b', 'c'],
          ],
        },
      );
      final session = anna.session;
      final item = (await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(uuidOf(ss)),
      ))!;
      final space = item.contentRef!;
      final loaded = (await HeadlessWorkbookProvider.open(
        session,
        space,
      )).model;
      final model = WorkbookModel.fromRows(
        loaded.spreadsheetId,
        loaded.allRows(),
      );
      final access = ModelWorkbookAccess(
        model: model,
        userId: anna.authUserId.uuid,
      );
      final s1 = model.sheetByName('Sheet1')!;
      access.apply(
        DeleteDimension(s1.id, Dimension.rows, s1.rows.ids.sublist(20)),
      );
      access.apply(
        DeleteDimension(s1.id, Dimension.columns, s1.columns.ids.sublist(8)),
      );
      access.apply(const AddSheet(name: 'Sheet2', rows: 10, columns: 5));
      access.apply(
        GenericRowWrite(SheetsTables.scriptProject, const Uuid().v7(), {
          'spreadsheetId': space.uuid,
          'name': 'Fixture script',
          'settingsJson': '{}',
          'createdAt': clock.now().toUtc(),
        }),
      );
      await SheetsServerWrites.apply(
        session,
        actor: anna.actor,
        fileUuid: space,
        changes: access.changes,
        label: 'Fixture',
      );
      access.dispose();
      HeadlessWorkbookProvider.clear();
      final stored = (await HeadlessWorkbookProvider.open(
        session,
        space,
      )).model;
      rows = stored.allRows().toList();
      spreadsheetId = stored.spreadsheetId;
    });
    tearDownAll(() async {
      await runner.close();
      await disableScripting();
    });

    for (var i = 0; i < conformanceCorpus.length; i++) {
      final c = conformanceCorpus[i];
      test('when running "${c.name}" then it conforms', () async {
        final bench = ScriptTestBench(
          WorkbookModel.fromRows(spreadsheetId, rows),
          runner: runner,
        );
        try {
          final r = await bench.run(
            program,
            conformanceFunctionName(i),
            kind: c.kind,
            role: c.role,
            scopes: c.scopes,
            isServer: c.isServer,
          );
          expect(
            checkConformance(
              c,
              status: r.status.name,
              result: r.result,
              errorType: r.error?.type,
              errorMessage: r.error?.message,
              logs: [for (final l in r.logs) l.message],
              valueOf: bench.value,
            ),
            isEmpty,
          );
        } finally {
          bench.dispose();
        }
      });
    }
  });
}
