import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

import 'function_vectors.dart';

void main() {
  // Reference values: Microsoft Excel ROMAN and ARABIC documentation.
  final t = FormulaTestBench();

  group('Given ROMAN', () {
    formulaVectors(t, const [
      ('=ROMAN(499, 0)', 'CDXCIX'),
      ('=ROMAN(499, 1)', 'LDVLIV'),
      ('=ROMAN(499, 2)', 'XDIX'),
      ('=ROMAN(499, 3)', 'VDIV'),
      ('=ROMAN(499, 4)', 'ID'),
      ('=ROMAN(499, TRUE)', 'CDXCIX'),
      ('=ROMAN(499, FALSE)', 'ID'),
      ('=ROMAN(1999)', 'MCMXCIX'),
      ('=ROMAN(3999)', 'MMMCMXCIX'),
      ('=ROMAN(3.9)', 'III'),
      ('=ROMAN(0)', ''),
      ('=ROMAN(4000)', '#VALUE!'),
      ('=ROMAN(-1)', '#VALUE!'),
      ('=ROMAN(1, 5)', '#VALUE!'),
    ]);
  });

  group('Given ARABIC', () {
    formulaVectors(t, const [
      ('=ARABIC("LVII")', 57),
      ('=ARABIC("mcmxii")', 1912),
      ('=ARABIC("-MMXI")', -2011),
      ('=ARABIC(" XIV ")', 14),
      ('=ARABIC("")', 0),
      ('=ARABIC("ABC")', '#VALUE!'),
      ('=ARABIC(ROMAN(1234))', 1234),
    ]);
  });
}
