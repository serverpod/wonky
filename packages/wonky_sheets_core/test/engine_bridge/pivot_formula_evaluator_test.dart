import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';
import 'package:wonky_sheets_core/src/content/cell_content.dart';
import 'package:wonky_sheets_core/src/engine_bridge/pivot_formula_evaluator.dart';
import 'package:wonky_sheets_core/src/pivot/pivot.dart';

import '../pivot/support/pivot_fixtures.dart';

void main() {
  group('Given a pivot with calculated fields evaluated by the engine', () {
    late FormulaTestBench t;
    late EnginePivotFormulaEvaluator formulas;
    setUp(() {
      t = FormulaTestBench();
      formulas = EnginePivotFormulaEvaluator(t.engine, sheetId: t.sheet1.id);
    });

    List<List<CellValue>> pivot(PivotValueSpec value) => PivotLayout.build(
      const PivotEngine().compute(
        PivotSpec(rows: [field(region)], values: [value]),
        salesTable(),
        PivotContext(formulas: formulas),
      ),
    ).toValues();

    final price =
        '=${PivotFormula.tokenOf(revenue)}/${PivotFormula.tokenOf(units)}';

    test(
      'when summarized by SUM then the formula runs per row and is summed',
      () {
        expect(
          pivot(PivotValueSpec(formula: price)),
          table([
            ['Region', 'Calculated Field 1'],
            ['East', 20],
            ['North', 10],
            ['West', 20],
            ['Grand Total', 50],
          ]),
        );
      },
    );

    test('when summarized by Custom then fields are arrays of the group', () {
      final custom =
          '=SUM(${PivotFormula.tokenOf(revenue)})'
          '/COUNTA(${PivotFormula.tokenOf(region)})';
      expect(
        pivot(
          PivotValueSpec(
            formula: custom,
            summarizeBy: PivotSummarize.custom,
            name: 'Revenue per row',
          ),
        ),
        table([
          ['Region', 'Revenue per row'],
          ['East', 85],
          ['North', 10],
          ['West', 40],
          ['Grand Total', 52],
        ]),
      );
    });

    test(
      'when the formula references a cell then the workbook value is used',
      () {
        t.set('A1', 2);
        final stored = FormulaCodec.toStored(
          '=A1',
          CodecContext(workbook: t.workbook, hostSheetId: t.sheet1.id),
        );
        final formula =
            '=${PivotFormula.tokenOf(units)}*${stored.substring(1)}';
        expect(
          pivot(PivotValueSpec(formula: formula, name: 'Double units')),
          table([
            ['Region', 'Double units'],
            ['East', 34],
            ['North', 2],
            ['West', 16],
            ['Grand Total', 52],
          ]),
        );
      },
    );
  });
}
