import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

import 'function_vectors.dart';

void main() {
  final t = FormulaTestBench();
  t.setColumn('A1', [1, 2, 3, 4, 5]);
  t.setColumn('B1', ['x', 'y', 'x', 'z', 'w']);

  group('Given criteria functions over ranges', () {
    formulaVectors(t, const [
      ('=SUMIF(A1:A5, ">2")', 12),
      ('=SUMIF(B1:B5, "x", A1:A5)', 4),
      ('=COUNTIF(B1:B5, "x")', 2),
      ('=COUNTIFS(A1:A5, ">1", B1:B5, "x")', 1),
      ('=SUMIFS(A1:A5, B1:B5, "x")', 4),
      ('=AVERAGEIFS(A1:A5, B1:B5, "x")', 2),
      ('=MAXIFS(A1:A5, B1:B5, "x")', 3),
      ('=MINIFS(A1:A5, B1:B5, "x")', 1),
      ('=COUNTIF(1, 1)', '#VALUE!'),
    ]);
  });

  // Regression: arrays were rejected with "Argument must be a range." (Sheets accepts them).
  group('Given criteria functions over arrays', () {
    formulaVectors(t, const [
      ('=SUMIF({1, 2, 3, 4}, ">2")', 7),
      ('=COUNTIF({"a", "b", "a"}, "a")', 2),
      ('=COUNTIF({1, 2, 3}, "<>2")', 2),
      ('=AVERAGEIF({2, 4, 6}, ">=4")', 5),
      ('=SUMIF({"a", "b", "a"}, "a", {1, 2, 3})', 4),
      ('=COUNTIFS({1, 2, 3}, ">1", {"x", "y", "y"}, "y")', 2),
      ('=SUMIFS({1, 2, 3}, {"x", "y", "y"}, "y")', 5),
      ('=COUNTIFS({1, 2, 3}, ">1", {"x", "y"}, "y")', '#VALUE!'),
    ]);
  });

  // Regression: an array of criteria returned only the first result (no lifting).
  group('Given criteria functions with an array of criteria', () {
    formulaVectors(t, const [
      (
        '=COUNTIF(B1:B5, {"x", "y"})',
        [
          [2, 1],
        ],
      ),
      ('=SUM(COUNTIF(B1:B5, {"x", "y"}))', 3),
      (
        '=ARRAYFORMULA(COUNTIF(B1:B5, B1:B3))',
        [
          [2],
          [1],
          [2],
        ],
      ),
      (
        '=ARRAYFORMULA(SUMIF(B1:B5, B1:B2, A1:A5))',
        [
          [4],
          [2],
        ],
      ),
    ]);
  });

  // Regression (sheets-core H2): the range index built on the second use of a range
  // compared numbers exactly, so identical formulas disagreed with the first (scanning)
  // one when a cell held 0.1+0.2.
  group(
    'Given 400 numbers with one =0.1+0.2 when the same criterion is evaluated '
    'three times then every result matches the scan',
    () {
      for (final (criterion, expected) in const [
        ('0.3', 1),
        ('"=0.3"', 1),
        ('"<=0.3"', 1),
        ('"<0.3"', 0),
        ('">=0.3"', 400),
        ('">0.3"', 399),
        ('"<>0.3"', 399),
      ]) {
        test('COUNTIF(A1:A400, $criterion) = $expected', () {
          final b = FormulaTestBench();
          b.setColumn('A1', [
            for (var i = 1; i <= 400; i++) i == 6 ? '=0.1+0.2' : i * 10,
          ]);
          b.setAll({
            for (var i = 1; i <= 3; i++) 'B$i': '=COUNTIF(A1:A400, $criterion)',
          });

          expect([
            for (var i = 1; i <= 3; i++) b.value('B$i'),
          ], List.filled(3, FNumber(expected.toDouble())));
        });
      }

      test('SUMIF and COUNTIFS agree with the scan as well', () {
        final b = FormulaTestBench();
        b.setColumn('A1', [
          for (var i = 1; i <= 400; i++) i == 6 ? '=0.1+0.2' : i * 10,
        ]);
        b.setAll({
          for (var i = 1; i <= 3; i++) ...{
            'B$i': '=SUMIF(A1:A400, 0.3)',
            'C$i': '=COUNTIFS(A1:A400, 0.3, A1:A400, "<1")',
          },
        });

        expect([
          for (var i = 1; i <= 3; i++) (b.value('B$i'), b.value('C$i')),
        ], List.filled(3, (FNumber(0.1 + 0.2), FNumber(1))));
      });

      test('a number criterion also counts text forms of the number', () {
        final b = FormulaTestBench();
        b.setColumn('A1', [
          for (var i = 1; i <= 400; i++)
            switch (i) {
              7 => "'300",
              8 => "' 300 ",
              _ => i * 10,
            },
        ]);
        b.setAll({
          for (var i = 1; i <= 3; i++) 'B$i': '=COUNTIF(A1:A400, 300)',
        });

        expect([
          for (var i = 1; i <= 3; i++) b.value('B$i'),
        ], List.filled(3, FNumber(3)));
      });
    },
  );
}
