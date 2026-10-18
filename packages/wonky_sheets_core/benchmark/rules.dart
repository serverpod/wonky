/// Rule benchmarks: conditional-format and data-validation custom formulas evaluated per
/// cell, and formulas using a named range.
///
/// `dart run benchmark/rules.dart [rows]` (default 100,000).
library;

import 'dart:convert';

import 'package:wonky_sheets_core/wonky_sheets_core.dart';

import 'support/bench.dart';

void main(List<String> args) {
  final n = args.isEmpty ? 100000 : int.parse(args.first);
  section('Rule formulas ($n cells)');

  final w = BenchWorkbook(rows: n, cols: 3);
  w.load([
    for (var r = 0; r < n; r++) w.cell(r, 0, BenchWorkbook.literal(r % 1000)),
  ]);
  w.engine.settle();

  // CF: highlight A1:B{n} where $A > 500 (a custom formula relative to the anchor).
  w.apply(
    AddCfRule(
      w.sheetId,
      [GridRect(0, 0, n - 1, 1)],
      jsonEncode({
        'v': 1,
        'type': 'boolean',
        'condition': {
          'type': 'customFormula',
          'values': [
            {'v': w.stored(r'=$A1>500')},
          ],
        },
        'format': {'fillColor': '#FCE8E6'},
      }),
    ),
  );
  late CfEvaluator cf;
  var highlighted = 0;
  bench(
    'CF custom formula over ${2 * n} cells (evaluateRect)',
    () => highlighted = cf
        .evaluateRect(w.sheetId, GridRect(0, 0, n - 1, 1))
        .length,
    setUp: () => cf = CfEvaluator(
      w.model,
      w.engine,
      const FunctionDisplayText(_plain),
      w.hooks,
    ),
    runs: 3,
  );
  if (highlighted != 2 * (n ~/ 1000) * 499 + 2 * _tail(n)) {
    throw StateError('wrong CF result $highlighted');
  }

  // DV: a custom formula `=A1<>B1` compiled once and tested per cell, as the
  // validation sweep and the paste check do.
  final conditions = ConditionEvaluator(hooks: w.hooks);
  final compiled = conditions.compile(
    CustomFormulaCondition(w.stored('=A1>=0')),
    sheetId: w.sheetId,
  );
  var valid = 0;
  bench('DV custom formula over $n cells (compiled condition)', () {
    valid = 0;
    for (var r = 0; r < n; r++) {
      final v = w.engine.valueAt(w.sheetId, r, 0).toCellValue();
      if (compiled.test(v, row: r, col: 0)) valid++;
    }
  }, runs: 3);
  if (valid != n) throw StateError('wrong DV result $valid');

  section('Named ranges');
  final names = BenchWorkbook(rows: n, cols: 2);
  names.load([
    names.cell(0, 0, BenchWorkbook.literal(1)),
    for (var r = 0; r < n; r++) names.cell(r, 1, '=Rate+$r'),
  ]);
  names.apply(
    AddNamedRange(
      'Rate',
      range: names.model.parseA1('A1', contextSheetId: names.sheetId),
    ),
  );
  names.engine.settle();
  bench(
    'full recalc of $n formulas using a named range',
    names.engine.settle,
    setUp: names.engine.invalidateAll,
    runs: 3,
  );
  if (names.value(n - 1, 1) != FNumber(n.toDouble())) {
    throw StateError('wrong named-range result ${names.value(n - 1, 1)}');
  }
}

/// Cells with `r % 1000 > 500` in the last partial thousand.
int _tail(int n) {
  var c = 0;
  for (var r = n - n % 1000; r < n; r++) {
    if (r % 1000 > 500) c++;
  }
  return c;
}

String _plain(CellValue v, String? f) => ValueText.automatic(v);
