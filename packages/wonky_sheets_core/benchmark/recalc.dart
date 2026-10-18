/// Recalculation benchmarks (05 §21): full recalc of many formulas, an edit at the head of
/// a long chain, and the scaling series that catches quadratic drains.
///
/// `dart run benchmark/recalc.dart [rows]` (default 100,000 rows: 200k formulas).
library;

import 'package:wonky_sheets_core/wonky_sheets_core.dart';

import 'support/bench.dart';

/// Column A numbers, column B `=A{r}+1`, column C the chain `=C{r-1}+1`.
BenchWorkbook _sheet(int n) {
  final w = BenchWorkbook(rows: n, cols: 3);
  w.load([
    for (var r = 0; r < n; r++) ...[
      w.cell(r, 0, BenchWorkbook.literal(r)),
      w.cell(r, 1, '=${w.ref(r, 0)}+1'),
      w.cell(r, 2, r == 0 ? '=1' : '=${w.ref(r - 1, 2)}+1'),
    ],
  ]);
  return w;
}

void main(List<String> args) {
  final n = args.isEmpty ? 100000 : int.parse(args.first);
  section('Recalculation (${2 * n} formulas)');

  final w = _sheet(n);
  bench(
    'load + first full recalc, ${2 * n} formulas',
    () => w.engine.settle(),
    runs: 1,
    warmup: 0,
    budget: '1M formulas < 20 s',
  );
  bench(
    'full recalc (invalidateAll + settle), ${2 * n} formulas',
    w.engine.settle,
    setUp: w.engine.invalidateAll,
    runs: 3,
    budget: '1M formulas < 20 s',
  );
  bench(
    'full recalc in 16 ms slices, ${2 * n} formulas',
    () {
      while (w.engine.pendingCount > 0) {
        w.engine.drain(const Duration(milliseconds: 16));
      }
    },
    setUp: w.engine.invalidateAll,
    runs: 3,
  );

  var head = 0;
  bench(
    'edit the head of a $n-cell chain → settle',
    () {
      w.type(0, 2, '${++head}');
      w.engine.settle();
    },
    runs: 3,
    budget: '100k dependents < 1 s',
  );
  if (w.value(n - 1, 2) != FNumber(head + n - 1.0)) {
    throw StateError('wrong chain result ${w.value(n - 1, 2)}');
  }

  section('Scaling (2× the formulas should take about 2× the time)');
  for (final size in [10000, 20000, 40000, 80000]) {
    final s = _sheet(size);
    s.engine.settle();
    bench(
      'full recalc, ${2 * size} formulas',
      s.engine.settle,
      setUp: s.engine.invalidateAll,
      runs: 3,
    );
  }
}
