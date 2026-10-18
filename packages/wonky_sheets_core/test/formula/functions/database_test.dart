import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

import 'function_vectors.dart';

void main() {
  // Reference data and results: the Microsoft Excel database function examples (orchard
  // table: Tree, Height, Age, Yield, Profit).
  final t = FormulaTestBench();
  t.setRows('A1', [
    ['Tree', 'Height', 'Age', 'Yield', 'Profit'],
    ['Apple', 18, 20, 14, 105],
    ['Pear', 12, 12, 10, 96],
    ['Cherry', 13, 14, 9, 105],
    ['Apple', 14, 15, 10, 75],
    ['Pear', 9, 8, 8, 76.8],
    ['Apple', 8, 9, 6, 45],
  ]);
  // Criteria: Apple with Height > 10 and < 16, or Pear.
  t.setRows('H1', [
    ['Tree', 'Height', 'Height'],
    ['Apple', '>10', '<16'],
    ['Pear', null, null],
  ]);
  t.setRows('L1', [
    ['Tree'],
    ['Cherry'],
  ]);

  group('Given the orchard database', () {
    formulaVectors(t, const [
      ('=DCOUNT(A1:E7, "Age", H1:J2)', 1),
      ('=DCOUNTA(A1:E7, "Profit", H1:J2)', 1),
      ('=DMAX(A1:E7, "Profit", H1:J3)', 96),
      ('=DMIN(A1:E7, "Profit", H1:J2)', 75),
      ('=DSUM(A1:E7, "Profit", L1:L2)', 105),
      ('=DSUM(A1:E7, "Profit", H1:J3)', 247.8),
      ('=DPRODUCT(A1:E7, "Yield", H1:J3)', 800),
      ('=DAVERAGE(A1:E7, "Yield", H1:J3)', 28 / 3),
      ('=DAVERAGE(A1:E7, 3, A1:E7)', 13),
      ('=DSTDEV(A1:E7, "Yield", H1:J3)', 1.1547005383792515),
      ('=DSTDEVP(A1:E7, "Yield", H1:J3)', 0.9428090415820634),
      ('=DVAR(A1:E7, "Yield", H1:J3)', 4 / 3),
      ('=DVARP(A1:E7, "Yield", H1:J3)', 8 / 9),
      ('=DGET(A1:E7, "Yield", L1:L2)', 9),
      ('=DGET(A1:E7, "Yield", H1:J3)', '#NUM!'),
      ('=DGET(A1:E7, "Yield", {"Tree"; "Plum"})', '#VALUE!'),
    ]);
  });

  group('Given database field and criteria arguments', () {
    formulaVectors(t, const [
      ('=DSUM(A1:E7, "profit", {"tree"; "apple"})', 225),
      ('=DSUM(A1:E7, 5, {"Tree"; "Apple"})', 225),
      ('=DSUM(A1:E7, "Height", {"Height"; ">=13"})', 45),
      (
        '=DSUM(A1:E7, "Height", {"Tree", "Age"; "Apple", ">10"; "Cherry", ""})',
        45,
      ),
      ('=DCOUNT(A1:E7, , {"Tree"; "Pear"})', 2),
      ('=DCOUNTA(A1:E7, , {"Tree"; "P*"})', 2),
      ('=DSUM(A1:E7, "Weight", L1:L2)', '#VALUE!'),
      ('=DSUM(A1:E7, 6, L1:L2)', '#VALUE!'),
      ('=DSUM(A1:E7, 0, L1:L2)', '#VALUE!'),
      ('=DSUM(A1:E7, , L1:L2)', '#VALUE!'),
      ('=DSUM(A1:E7, "Profit", L1)', '#VALUE!'),
      ('=DSUM(A1:E7, "Profit", {"Color"; "red"})', 0),
      ('=DMAX(A1:E7, "Profit", {"Tree"; "Plum"})', 0),
      ('=DAVERAGE(A1:E7, "Profit", {"Tree"; "Plum"})', '#DIV/0!'),
      ('=DSTDEV(A1:E7, "Profit", L1:L2)', '#DIV/0!'),
      ('=DSUM(A1:E7, "Profit", {"Tree"; ""})', 502.8),
    ]);
  });

  group('Given a database with an error in a matching value', () {
    final bench = FormulaTestBench();
    bench.setRows('A1', [
      ['Name', 'Score'],
      ['a', 1],
      ['b', '=1/0'],
    ]);
    formulaVectors(bench, const [
      ('=DSUM(A1:B3, "Score", {"Name"; "b"})', '#DIV/0!'),
      ('=DSUM(A1:B3, "Score", {"Name"; "a"})', 1),
      ('=DCOUNT(A1:B3, "Score", {"Name"; "<>x"})', 1),
    ]);
  });
}
