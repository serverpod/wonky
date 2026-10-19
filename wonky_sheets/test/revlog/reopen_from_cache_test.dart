import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets/features/model/loading_formula_source.dart';
import 'package:wonky_sheets/features/model/loading_gate.dart';
import 'package:wonky_sheets/features/revlog/logged_workbook_session.dart';
import 'package:wonky_sheets_core/formula.dart' show FError, FNumber;
import 'package:wonky_sheets_core/model.dart';

import 'support/rev_harness.dart';

final space = UuidValue.fromString('0190a000-0000-7000-8000-0000000000d1');
final anna = UuidValue.fromString('0190a000-0000-7000-8000-0000000000a1');
final bo = UuidValue.fromString('0190a000-0000-7000-8000-0000000000b2');

/// Reopening a spreadsheet from the device cache viewport-first (RevLog
/// spec 06 §5.1, 17 As built 24): ready after the structure and the first
/// rows; the rest streams in from the cache with the loading gates and
/// `#LOADING` working as during a cold open.
void main() {
  const rows = 2100; // above the small-file limit (loads before ready)

  test('Given a spreadsheet in the device cache, when it is reopened, then '
      'it is ready before the far rows load, writes and formulas over them '
      'wait, and everything matches once they are in', () async {
    final hub = sheetsHub();
    final create = creationPlan(space, anna, rows: rows, columns: 3);
    commitPlan(hub, space, anna, create);
    final model = WorkbookModel(spreadsheetId: space.uuid)..applyPlan(create);
    final sheet = model.sheets.single;
    final binding = ModelEngineBinding.create(model);
    commitPlan(
      hub,
      space,
      anna,
      const SheetsMutationPlanner().plan(
        SetCellInputs(
          sheetId: sheet.id,
          row: 0,
          col: 0,
          inputs: [
            [CellInput.user('=SUM(A2:A$rows)'), CellInput.user('=A2*2')],
            for (var r = 1; r < rows; r++)
              [CellInput.user('1'), CellInput.user('row $r')],
          ],
        ),
        model,
        PlanContext(
          userId: anna.uuid,
          now: DateTime.utc(2026, 10, 1),
          formulas: EngineFormulaHooks(model, engine: binding.engine),
        ),
      ),
    );
    binding.dispose();

    // Bo loads it once: his cache is complete.
    final device = await SheetsDevice.start(hub, bo);
    final first = await device.openFile(space);
    await first.rowLoading.whenComplete;
    final expected = canonical(first.model);
    await first.dispose();

    // Reopened: the cells after the first rows wait for the test.
    final release = Completer<void>();
    final s = LoggedWorkbookSession.open(
      device.client,
      itemUuid: space,
      fileUuid: space,
      userId: bo.uuid,
      role: Role.editor,
      maintenanceDelay: const Duration(hours: 1),
    );
    addTearDown(s.dispose);
    s.sync.cachedCellsRead = (scope, keys) => release.future;
    await s.opened;
    await whenReady(s);

    final id = s.model.sheets.single.id;
    final far = s.model.sheets.single.rows.idAt(rows - 1);
    expect(s.rowLoading.complete, isFalse);
    expect(s.rowLoading.isRowLoaded(id, far), isFalse);
    expect(s.model.cellAt(id, 1, 1)?.content, 's:row 1');
    expect(s.model.cellAt(id, rows - 1, 1), isNull);

    Matcher waits() => throwsA(
      isA<PlanException>().having((e) => e.code, 'code', LoadingGate.code),
    );
    expect(
      () => s.execute(DeleteDimension(id, Dimension.rows, [far])),
      waits(),
    );
    final col = s.model.sheets.single.columns.idAt(2);
    expect(
      () => s.execute(DeleteDimension(id, Dimension.columns, [col])),
      waits(),
    );
    expect(
      () => s.execute(
        SetCellInputs(
          sheetId: id,
          row: rows - 1,
          col: 2,
          inputs: [
            [CellInput.user('x')],
          ],
        ),
      ),
      waits(),
    );
    s.execute(
      SetCellInputs(
        sheetId: id,
        row: 1,
        col: 2,
        inputs: [
          [CellInput.user('typed')],
        ],
      ),
    );

    final source = LoadingFormulaSource(
      s.engine.engine,
      s.engine.engine,
      s.model,
      s.rowLoading,
    );
    addTearDown(source.dispose);
    final sum = source.valueAt(id, 0, 0);
    expect(sum is FError && sum.pending, isTrue, reason: 'SUM over far rows');
    expect(source.valueAt(id, 0, 1), const FNumber(2));

    release.complete();
    await s.rowLoading.whenComplete;
    expect(source.valueAt(id, 0, 0), const FNumber(rows - 1.0));
    expect(s.model.cellAt(id, rows - 1, 1)?.content, 's:row ${rows - 1}');
    expect(s.model.cellAt(id, 1, 2)?.content, 's:typed');
    expect(
      canonical(s.model).where((r) => !r.contains('typed')).toList(),
      expected,
    );
    s.execute(DeleteDimension(id, Dimension.rows, [far]));
    expect(s.model.sheets.single.rows.length, rows - 1);
    await s.whenSynced(timeout: const Duration(seconds: 20));
  });
}
