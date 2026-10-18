/// Structural-edit benchmarks (05 §21 "edit → repaint"): inserting, deleting and moving
/// rows in a large sheet full of references, through the planner, the model and the engine
/// (as the app does), plus the axis index on its own.
///
/// `dart run benchmark/structural.dart [rows]` (default 200,000).
library;

import 'package:wonky_sheets_core/wonky_sheets_core.dart';
import 'package:wonky_sync_models/ids.dart';

import 'support/bench.dart';

void main(List<String> args) {
  final n = args.isEmpty ? 200000 : int.parse(args.first);
  final sums = n ~/ 10;
  section('Structural edits ($n rows, ${n + sums} formulas)');

  // A numbers, B `=A{r}+1` on every row, C `=SUM(A{r}:A{r+4})` on the first tenth.
  final w = BenchWorkbook(rows: n, cols: 5);
  w.load([
    for (var r = 0; r < n; r++) ...[
      w.cell(r, 0, BenchWorkbook.literal(r)),
      w.cell(r, 1, '=${w.ref(r, 0)}+1'),
      if (r < sums) w.cell(r, 2, '=SUM(${w.range(r, 0, r + 4, 0)})'),
    ],
  ]);
  w.engine.settle();

  bench('insert 1 row (plan + apply + engine) → settle', () {
    w.apply(InsertDimension(w.sheetId, Dimension.rows, 100, 1));
    w.engine.settle();
  }, budget: 'edit → repaint < 16 ms');
  bench('delete 1 row (plan + apply + engine) → settle', () {
    w.apply(DeleteDimension(w.sheetId, Dimension.rows, [w.rowId(100)]));
    w.engine.settle();
  });
  List<String> block(int from, int count) => [
    for (var r = from; r < from + count; r++) w.rowId(r),
  ];
  bench('plan only: delete 1,000 referenced rows', () {
    const SheetsMutationPlanner().plan(
      DeleteDimension(w.sheetId, Dimension.rows, block(1000, 1000)),
      w.model,
      w.context,
    );
  }, runs: 3);
  bench('delete 1,000 referenced rows (plan + apply + engine) → settle', () {
    w.apply(DeleteDimension(w.sheetId, Dimension.rows, block(1000, 1000)));
    w.engine.settle();
  }, runs: 3);
  bench('plan only: cut/paste A2001:A3000 to E2001', () {
    const SheetsMutationPlanner().plan(
      MoveRange(
        w.model.parseA1('A2001:A3000', contextSheetId: w.sheetId),
        w.sheetId,
        2000,
        4,
      ),
      w.model,
      w.context,
    );
  }, runs: 3);

  section('Axis index ($n entries)');
  final axis = AxisIndex();
  final keys = FractionalIndex.nBetween(null, null, n);
  axis.load([for (var i = 0; i < n; i++) ('row$i', keys[i], null, false)]);
  axis.indexOf('row0');
  var k = 0;
  bench('insert 1 id near the top, then indexOf + offsetOf', () {
    final key = FractionalIndex.between(keys[10], keys[11]);
    axis.upsert('new${k++}', key);
    axis.indexOf('row${n - 1}');
    axis.offsetOf(n - 1);
  }, runs: 9);
  bench('remove 1 id near the top, then indexOf + offsetOf', () {
    axis.remove('new${--k}');
    axis.indexOf('row${n - 1}');
    axis.offsetOf(n - 1);
  }, runs: 9);
}
