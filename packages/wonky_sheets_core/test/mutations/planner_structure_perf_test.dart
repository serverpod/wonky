import 'package:test/test.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';
import 'package:wonky_sync_models/ids.dart';

import '../support/planner_harness.dart';

/// A sheet of [n] rows: numbers in A, `=A{r}+1` in B (stored directly).
PlannerHarness _sheet(int n) {
  final b = WorkbookBuilder()..sheet('Sheet1', rows: n, cols: 3);
  for (var r = 0; r < n; r++) {
    b.value('A${r + 1}', r);
  }
  final h = PlannerHarness(b);
  final s = h.model.sheets.first;
  h.model.applyChanges([
    for (var r = 0; r < n; r++)
      RowChange.insert(
        SheetsTables.cell,
        SheetsIds.cellId(s.id, s.rows.idAt(r), s.columns.idAt(1)),
        {
          Cols.sheetId: s.id,
          CellCols.rowId: s.rows.idAt(r),
          CellCols.columnId: s.columns.idAt(1),
          CellCols.content: h.hooks.toStored(
            '=A${r + 1}+1',
            sheetId: s.id,
            row: r,
            col: 1,
          ),
        },
      ),
  ], silent: true);
  return h;
}

/// Seconds to plan deleting [count] rows (every one referenced by a formula).
double _planSeconds(PlannerHarness h, int count) {
  final s = h.model.sheets.first;
  final op = DeleteDimension(s.id, Dimension.rows, [
    for (var r = 0; r < count; r++) s.rows.idAt(2 * r + 1),
  ]);
  final sw = Stopwatch()..start();
  h.plan(op);
  return sw.elapsedMicroseconds / 1e6;
}

// Regression (sheets-core H5): the delete planner checked every formula of the
// workbook against every deleted id (a token conversion and a substring search
// per pair), so deleting 1,000 rows of a 200k-formula sheet took minutes.
void main() {
  test(
    'Given 4,000 formulas when deleting 800 instead of 50 referenced rows then planning '
    'takes about as long',
    () {
      final h = _sheet(4000);
      _planSeconds(h, 50); // warm-up (JIT)
      final few = _planSeconds(h, 50);
      final many = _planSeconds(h, 800);

      // 16x the ids; the per-id scan was over 10x.
      expect(many, lessThan(few * 6 + 0.05));
    },
  );

  test(
    'Given formulas when rows are deleted then references to them are repaired',
    () {
      final h = _sheet(20);
      final s = h.model.sheets.first;
      for (final (row, text) in [
        (0, '=SUM(A4:A8)'),
        (1, '=A4*2'),
        (2, '="A4"&A10'),
      ]) {
        h.apply(
          SetCellInputs(
            sheetId: s.id,
            row: row,
            col: 2,
            inputs: [
              [CellInput.user(text)],
            ],
          ),
        );
      }

      h.apply(
        DeleteDimension(s.id, Dimension.rows, [s.rows.idAt(3), s.rows.idAt(7)]),
      );

      expect(
        [
          for (final a1 in ['C1', 'C2', 'C3', 'B3', 'B4', 'B18'])
            h.formulaA1(a1),
        ],
        ['=SUM(A4:A6)', '=#REF!*2', '="A4"&A8', '=A3+1', '=A4+1', '=A18+1'],
      );
    },
  );
}
