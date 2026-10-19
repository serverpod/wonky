import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/model/loading_gate.dart';
import 'package:wonky_sheets/features/model/memory_workbook_session.dart';
import 'package:wonky_sheets/features/model/row_loading.dart';
import 'package:wonky_sheets_core/model.dart';

/// Deletes while a spreadsheet streams in (RevLog spec 06 §5.5): the
/// planners list the deleted cells from the model, so they need them
/// loaded.
void main() {
  group('Given a sheet whose first five rows are loaded', () {
    late MemoryWorkbookSession s;
    late SheetModel sheet;
    late RowLoadTracker loading;

    setUp(() {
      s = MemoryWorkbookSession.blank();
      addTearDown(s.dispose);
      sheet = s.model.sheets.single;
      loading = RowLoadTracker();
      addTearDown(loading.dispose);
      loading
        ..track(sheet.id, sheet.rows.ids)
        ..markLoaded(sheet.id, sheet.rows.ids.take(5));
    });

    void gate(SheetsOperation op) =>
        LoadingGate.checkRanges(op, s.model, loading);

    Matcher refused() => throwsA(
      isA<PlanException>().having((e) => e.code, 'code', LoadingGate.code),
    );

    test('when a loaded row is deleted, then it is allowed', () {
      expect(
        () => gate(
          DeleteDimension(sheet.id, Dimension.rows, [sheet.rows.idAt(2)]),
        ),
        returnsNormally,
      );
    });

    test('when a row that is still loading is deleted, then it waits', () {
      expect(
        () => gate(
          DeleteDimension(sheet.id, Dimension.rows, [sheet.rows.idAt(20)]),
        ),
        refused(),
      );
    });

    test('when a column or the sheet is deleted, then it waits for the '
        'whole sheet', () {
      expect(
        () => gate(
          DeleteDimension(sheet.id, Dimension.columns, [sheet.columns.idAt(0)]),
        ),
        refused(),
      );
      expect(() => gate(DeleteSheet(sheet.id)), refused());
    });

    test('when every row is loaded, then deletes are allowed', () {
      loading.finish();
      expect(() => gate(DeleteSheet(sheet.id)), returnsNormally);
    });
  });
}
