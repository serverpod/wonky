import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matches a number within 1e-9 relative tolerance, or an error literal (`#…`).
Matcher _value(Object want) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, math.max(n.abs() * 1e-9, 1e-12)),
  ),
  final String s => isA<FError>().having((e) => e.kind.literal, 'error', s),
  _ => throw ArgumentError('unsupported expectation $want'),
};

/// A1:A5 = 1..5 with a nested SUBTOTAL in A6, C1:C5 = 1, 2, #DIV/0!, 4, 5, B1:B3 mixed values;
/// row 2 is hidden by the filter and row 4 by the user.
FormulaTestBench _bench() {
  final t = FormulaTestBench();
  t.setColumn('A1', [1, 2, 3, 4, 5, '=SUBTOTAL(9, A1:A5)']);
  t.setColumn('B1', ['x', true, 2]);
  t.setColumn('C1', [1, 2, '=1/0', 4, 5]);
  final s = t.sheet1;
  s.filterHiddenRows.add(s.rows.idAt(1));
  s.rows.hidden.add(s.rows.idAt(3));
  t.engine.filterVisibilityChanged(s.id);
  return t;
}

void main() {
  group('Given SUBTOTAL over rows hidden by a filter and by the user', () {
    final t = _bench();
    const cases = <(String, Object)>[
      ('=SUBTOTAL(9, A1:A6)', 13),
      ('=SUBTOTAL(109, A1:A6)', 9),
      ('=SUBTOTAL(1, A1:A5)', 3.25),
      ('=SUBTOTAL(101, A1:A5)', 3),
      ('=SUBTOTAL(2, A1:A5)', 4),
      ('=SUBTOTAL(102, A1:A5, B1:B3)', 4),
      ('=SUBTOTAL(3, B1:B3)', 2),
      ('=SUBTOTAL(4, A1:A5)', 5),
      ('=SUBTOTAL(5, A1:A5)', 1),
      ('=SUBTOTAL(105, A3:A5)', 3),
      ('=SUBTOTAL(6, A1:A5)', 60),
      ('=SUBTOTAL(7, A1:A5)', 1.707825127659933),
      ('=SUBTOTAL(8, A1:A5)', 1.479019945774904),
      ('=SUBTOTAL(10, A1:A5)', 2.9166666666666665),
      ('=SUBTOTAL(11, A1:A5)', 2.1875),
      ('=SUBTOTAL(9, A1:A5, C1:C2)', 14),
      ('=SUBTOTAL(9, C1:C5)', '#DIV/0!'),
      ('=SUBTOTAL(2, C1:C5)', 3),
      ('=SUBTOTAL(12, A1:A5)', '#VALUE!'),
      ('=SUBTOTAL(9, {1, 2, 3})', 6),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }

    test(
      'when reading the stored nested SUBTOTAL then it skips the filtered row',
      () {
        expect(t.value('A6'), _value(13));
      },
    );
  });

  group('Given AGGREGATE with error and visibility options', () {
    final t = _bench();
    const cases = <(String, Object)>[
      ('=AGGREGATE(9, 6, C1:C5)', 12),
      ('=AGGREGATE(9, 4, C1:C5)', '#DIV/0!'),
      ('=AGGREGATE(9, 7, C1:C5)', 6),
      ('=AGGREGATE(9, 5, A1:A5)', 9),
      ('=AGGREGATE(9, 4, A1:A6)', 28),
      ('=AGGREGATE(9, 0, A1:A6)', 15),
      ('=AGGREGATE(1, 6, C1:C5)', 3),
      ('=AGGREGATE(2, 4, C1:C5)', 4),
      ('=AGGREGATE(3, 4, C1:C5)', 5),
      ('=AGGREGATE(4, 6, C1:C5)', 5),
      ('=AGGREGATE(5, 6, C1:C5)', 1),
      ('=AGGREGATE(6, 6, C1:C5)', 40),
      ('=AGGREGATE(7, 6, {1, 2, 3})', 1),
      ('=AGGREGATE(8, 6, {1, 3})', 1),
      ('=AGGREGATE(10, 6, {1, 2, 3})', 1),
      ('=AGGREGATE(11, 6, {1, 3})', 1),
      ('=AGGREGATE(12, 6, C1:C5)', 3),
      ('=AGGREGATE(13, 6, {1, 2, 2})', 2),
      ('=AGGREGATE(14, 6, C1:C5, 2)', 4),
      ('=AGGREGATE(14, 6, A1:A5/(A1:A5>2), 3)', 3),
      ('=AGGREGATE(15, 6, C1:C5, 1)', 1),
      ('=AGGREGATE(16, 6, C1:C5, 0.5)', 3),
      ('=AGGREGATE(17, 6, C1:C5, 1)', 1.75),
      ('=AGGREGATE(18, 6, C1:C5, 0.5)', 3),
      ('=AGGREGATE(19, 6, C1:C5, 2)', 3),
      ('=AGGREGATE(15, 4, C1:C5, 1)', '#DIV/0!'),
      ('=AGGREGATE(14, 6, A1:A5)', '#VALUE!'),
      ('=AGGREGATE(20, 0, A1:A5)', '#VALUE!'),
      ('=AGGREGATE(9, 8, A1:A5)', '#VALUE!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });
}
