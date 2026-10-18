/// Range-read benchmarks (05 §21): aggregates over long columns, `SUM(A:A)` over 1M rows,
/// open ranges right after an edit (used extent), and materializing a range.
///
/// `dart run benchmark/range_reads.dart [rows]` (default 1,000,000).
library;

import 'package:wonky_sheets_core/wonky_sheets_core.dart';

import 'support/bench.dart';

void main(List<String> args) {
  final n = args.isEmpty ? 1000000 : int.parse(args.first);
  final part = n < 200000 ? n : 200000;
  section('Range reads ($n numeric rows)');

  final w = BenchWorkbook(rows: n, cols: 4);
  w.load([
    for (var r = 0; r < n; r++) w.cell(r, 0, BenchWorkbook.literal(r % 1000)),
  ]);
  final expected = FNumber(
    [
      for (var r = 0; r < n; r++) r % 1000,
    ].fold<int>(0, (a, b) => a + b).toDouble(),
  );
  final sumAll = w.stored('=SUM(A:A)', col: 3);
  final sumPart = w.stored('=SUM(A1:A$part)', col: 3);
  final rowsPart = w.stored('=ROWS(A1:A$part*1)', col: 3);
  FValue eval(String stored) =>
      w.engine.evaluateStored(stored, sheetId: w.sheetId, col: 3);
  if (eval(sumAll) != expected) throw StateError('wrong SUM ${eval(sumAll)}');

  bench(
    'SUM(A1:A$part)',
    () => eval(sumPart),
    budget: n == 1000000 ? null : 'SUM(A:A) over 1M < 10 ms',
  );
  bench('SUM(A:A) over $n rows', () => eval(sumAll), budget: '< 10 ms');
  var k = 0;
  bench(
    'SUM(A:A) right after a 1-cell edit elsewhere',
    () => eval(sumAll),
    setUp: () => w.type(5, 2, '${++k}'),
  );
  bench(
    'ROWS(A1:A$part*1) (materialize with format hints)',
    () => eval(rowsPart),
  );
  bench('engine.forEachValue over A1:A$part', () {
    var s = 0.0;
    w.engine.forEachValue(
      w.engine.workbook.sheetById(w.sheetId)!,
      GridRect(0, 0, part - 1, 0),
      (r, c, v) => s += (v as FNumber).v,
    );
  });

  section('Used range');
  bench(
    'used rows after a 1-cell edit',
    () => w.engine.usedRows(w.engine.workbook.sheetById(w.sheetId)!),
    setUp: () => w.type(7, 2, '${++k}'),
  );
  bench(
    '1-cell edit (planner + model + engine)',
    () => w.type(9, 2, '${++k}'),
    runs: 9,
  );
}
