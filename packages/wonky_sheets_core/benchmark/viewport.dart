/// Viewport-priority benchmark (05 §10.2): the cost of one background-recalc slice while
/// many formulas are dirty and the viewport shows a few of them.
///
/// `dart run benchmark/viewport.dart [rows]` (default 200,000).
library;

import 'package:wonky_sheets_core/wonky_sheets_core.dart';

import 'support/bench.dart';

void main(List<String> args) {
  final n = args.isEmpty ? 200000 : int.parse(args.first);
  section('Viewport priority ($n dirty formulas)');

  final w = BenchWorkbook(rows: n, cols: 2);
  w.load([
    for (var r = 0; r < n; r++) ...[
      w.cell(r, 0, BenchWorkbook.literal(r)),
      w.cell(r, 1, '=${w.ref(r, 0)}*2'),
    ],
  ]);
  w.engine.settle();
  final mid = n ~/ 2;
  w.engine.setViewport(w.sheetId, GridRect(mid, 0, mid + 49, 1));

  bench(
    'first slice: the 50 visible formulas of $n dirty',
    () => w.engine.drain(Duration.zero),
    setUp: w.engine.invalidateAll,
    runs: 9,
    budget: 'no frame > 20 ms',
  );
  if (w.engine.peekValueAt(w.sheetId, mid, 1)?.stale ?? true) {
    throw StateError('the viewport was not evaluated first');
  }

  // Later slices: the viewport is clean, the rest is still dirty.
  w.engine.invalidateAll();
  w.engine.drain(Duration.zero);
  bench(
    'later slice with ~$n dirty (viewport clean)',
    () => w.engine.drain(Duration.zero),
    runs: 20,
    budget: 'no frame > 20 ms',
  );
}
