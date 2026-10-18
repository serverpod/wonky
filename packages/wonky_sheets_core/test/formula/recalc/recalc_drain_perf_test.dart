import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// A bench with [n] formulas `=A{r}+1` in column B over numbers in column A.
FormulaTestBench _chain(int n) {
  final b = FormulaTestBench(rows: n, cols: 2);
  final s = b.sheet1;
  for (var r = 0; r < n; r++) {
    s.setInput(r, 0, b.inputFor(s, r, 0, r));
    s.setInput(r, 1, b.inputFor(s, r, 1, '=A${r + 1}+1'));
  }
  return b;
}

/// Seconds a full recalculation of the [n] rows of [b] takes (everything dirty, drained in 16 ms slices as
/// the background recalc does).
double _recalcSeconds(FormulaTestBench b, int n) {
  final s = b.sheet1;
  b.engine.rectChanged(s.id, GridRect(0, 0, n - 1, 1));
  final sw = Stopwatch()..start();
  while (b.engine.pendingCount > 0) {
    b.engine.drain(const Duration(milliseconds: 16));
  }
  return sw.elapsedMicroseconds / 1e6;
}

// Regression (sheets-core H1): the drain took `LinkedHashSet.first` of a set with
// tombstones, so a full recalc was quadratic (100k formulas took about 15 s).
void main() {
  test(
    'Given 20k and 80k formulas when recalculating everything then the time grows '
    'about linearly',
    () {
      _recalcSeconds(_chain(20000), 20000); // warm-up (JIT)
      final small = _recalcSeconds(_chain(20000), 20000);
      final large = _recalcSeconds(_chain(80000), 80000);

      // 4x the work: about 3x here; the quadratic drain was over 10x.
      expect(large, lessThan(small * 6 + 0.05));
    },
  );

  test(
    'Given 200k formulas when recalculating everything then it stays well under the '
    'budget',
    () {
      final b = _chain(200000);
      expect(b.value('B200000'), FNumber(200000));

      final seconds = _recalcSeconds(b, 200000);

      expect(seconds, lessThan(10));
      expect(b.value('B200000'), FNumber(200000));
    },
    tags: 'slow',
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
