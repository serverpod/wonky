import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matches numbers (relative [rel]), `#…` error literals and `List<List<Object>>` arrays.
Matcher _value(Object want, {double rel = 1e-9}) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, math.max(n.abs() * rel, 1e-12)),
  ),
  final String s => isA<FError>().having((e) => e.kind.literal, 'error', s),
  final List<List<Object>> rows => isA<FArray>().having(
    (a) => a.toRows(),
    'rows',
    [
      for (final r in rows) [for (final c in r) _value(c, rel: rel)],
    ],
  ),
  _ => throw ArgumentError('unsupported expectation $want'),
};

void main() {
  group('Given paired-data regression functions', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [3, 2, 4, 5, 6]);
    t.setColumn('B1', [9, 7, 12, 15, 17]);
    t.setColumn('C1', [2, 'x', 9, 1]);
    t.setColumn('D1', [6, 5, 11, 7]);
    const cases = <(String, Object)>[
      // Excel docs: CORREL(A2:A6, B2:B6) = 0.997054486.
      ('=CORREL(A1:A5, B1:B5)', 0.9970544855015815),
      ('=CORREL(C1:C4, D1:D4)', 0.9538209664765319),
      ('=CORREL({1, 1}, {1, 2})', '#DIV/0!'),
      ('=CORREL({1, 2}, {1, 2, 3})', '#N/A'),
      ('=PEARSON(A1:A5, B1:B5)', 0.9970544855015815),
      ('=PEARSON({1, 2, 3}, {3, 2, 1})', -1),
      ('=PEARSON({"a", "b"}, {1, 2})', '#DIV/0!'),
      // Excel docs: RSQ / SLOPE / STEYX of {2,3,9,1,8,7,5} vs {6,5,11,7,5,4,4} = 0.05795,
      // 0.305556, 3.305719; INTERCEPT({2,3,9,1,8}, {6,5,11,7,5}) = 0.0483871.
      (
        '=RSQ({2, 3, 9, 1, 8, 7, 5}, {6, 5, 11, 7, 5, 4, 4})',
        0.05795019157088122,
      ),
      ('=RSQ({1, 2, 3}, {2, 4, 6})', 1),
      ('=RSQ({1, 2}, {3, 3})', '#DIV/0!'),
      (
        '=SLOPE({2, 3, 9, 1, 8, 7, 5}, {6, 5, 11, 7, 5, 4, 4})',
        0.3055555555555556,
      ),
      ('=SLOPE({1, 2, 3}, {1, 2, 3})', 1),
      ('=SLOPE({1, 2}, {3, 3})', '#DIV/0!'),
      ('=INTERCEPT({2, 3, 9, 1, 8}, {6, 5, 11, 7, 5})', 0.04838709677419306),
      ('=INTERCEPT({3, 5, 7}, {1, 2, 3})', 1),
      ('=INTERCEPT({1}, {1})', '#DIV/0!'),
      (
        '=STEYX({2, 3, 9, 1, 8, 7, 5}, {6, 5, 11, 7, 5, 4, 4})',
        3.305718950210041,
      ),
      ('=STEYX({3, 5, 7}, {1, 2, 3})', 0),
      ('=STEYX({1, 2}, {1, 2})', '#DIV/0!'),
      // Excel docs: FORECAST(30, {6,7,9,15,21}, {20,28,31,38,40}) = 10.607253.
      (
        '=FORECAST(30, {6, 7, 9, 15, 21}, {20, 28, 31, 38, 40})',
        10.607253086419755,
      ),
      ('=FORECAST.LINEAR(4, {3, 5, 7}, {1, 2, 3})', 9),
      ('=FORECAST(1, {1, 2}, {3, 3})', '#DIV/0!'),
      // Excel docs: COVARIANCE.P(A2:A6, B2:B6) = 5.2; COVARIANCE.S({2,4,8}, {5,11,12}) = 9.666667.
      ('=COVARIANCE.P(A1:A5, B1:B5)', 5.2),
      ('=COVAR({1, 2}, {1, 2})', 0.25),
      ('=COVARIANCE.P({"a"}, {"b"})', '#DIV/0!'),
      ('=COVARIANCE.S({2, 4, 8}, {5, 11, 12})', 9.666666666666666),
      ('=COVARIANCE.S(A1:A5, B1:B5)', 6.5),
      ('=COVARIANCE.S({1}, {2})', '#DIV/0!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given FREQUENCY', () {
    final t = FormulaTestBench();
    const cases = <(String, Object)>[
      // Excel docs: FREQUENCY(scores, {70, 79, 89}) = {1; 2; 4; 2}.
      (
        '=FREQUENCY({79, 85, 78, 85, 50, 81, 95, 88, 97}, {70, 79, 89})',
        [
          [1],
          [2],
          [4],
          [2],
        ],
      ),
      (
        '=FREQUENCY({1, 2, 3, 4, 5}, {4, 2})',
        [
          [2],
          [2],
          [1],
        ],
      ),
      ('=FREQUENCY({1, 2, 3}, {"a", "b"})', 3),
      ('=FREQUENCY({1, 1/0}, {1, 2})', '#DIV/0!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given the LINEST family', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [1, 2, 3, 4, 5]);
    t.setColumn('B1', [2, 1, 4, 3, 6]);
    t.setColumn('C1', [9, 8, 19, 18, 29]); // 1 + 2·A + 3·B
    t.setColumn('D1', [1, 3, 2, 5, 4]);
    t.setColumn('E1', [33100, 47300, 69000, 102000, 150000, 220000]);
    t.setColumn('F1', [11, 12, 13, 14, 15, 16]);
    const cases = <(String, Object)>[
      // Excel docs: LINEST({1,9,5,7}, {0,4,2,3}) = {2, 1}.
      (
        '=LINEST({1; 9; 5; 7}, {0; 4; 2; 3})',
        [
          [2, 1],
        ],
      ),
      (
        '=LINEST(C1:C5, A1:B5)',
        [
          [3, 2, 1],
        ],
      ),
      (
        '=LINEST({2, 4, 6}, {1, 2, 3}, FALSE)',
        [
          [2, 0],
        ],
      ),
      // y = {1,3,2,5,4} on x = 1..5: hand-computed statistics (Sxx = 10, Sxy = 8, Syy = 10).
      (
        '=LINEST(D1:D5, A1:A5, TRUE, TRUE)',
        [
          [0.8, 0.6],
          [0.34641016151377546, 1.1489125293076057],
          [0.64, 1.0954451150103321],
          [5.333333333333333, 3],
          [6.4, 3.6],
        ],
      ),
      (
        '=LINEST(D1:D5, , TRUE, TRUE)',
        [
          [0.8, 0.6],
          [0.34641016151377546, 1.1489125293076057],
          [0.64, 1.0954451150103321],
          [5.333333333333333, 3],
          [6.4, 3.6],
        ],
      ),
      // Collinear second variable gets a zero coefficient (Excel behavior).
      (
        '=LINEST({3; 5; 7; 9}, {1, 2; 2, 4; 3, 6; 4, 8})',
        [
          [0, 2, 1],
        ],
      ),
      ('=LINEST({1; 2; 3}, {1; 2})', '#REF!'),
      ('=LINEST({1; "a"; 3})', '#VALUE!'),
      // Excel docs: LOGEST(sales, months) = {1.463275628, 495.3047702}.
      (
        '=LOGEST(E1:E6, F1:F6)',
        [
          [1.4632756281161756, 495.3047701587292],
        ],
      ),
      (
        '=LOGEST({2, 4, 8}, {1, 2, 3}, FALSE)',
        [
          [2, 1],
        ],
      ),
      ('=LOGEST({1, -1})', '#NUM!'),
      // Excel docs: TREND/GROWTH predictions.
      (
        '=TREND({1; 9; 5; 7}, {0; 4; 2; 3}, {5; 8})',
        [
          [11],
          [17],
        ],
      ),
      (
        '=TREND({1, 2, 3})',
        [
          [1, 2, 3],
        ],
      ),
      (
        '=TREND(C1:C5, A1:B5, {6, 1; 0, 0})',
        [
          [16],
          [1],
        ],
      ),
      ('=TREND(C1:C5, A1:B5, {6, 1, 2})', '#REF!'),
      (
        '=GROWTH(E1:E6, F1:F6, {17; 18})',
        [
          [320196.7183634738],
          [468536.05418404966],
        ],
      ),
      ('=GROWTH({2, 4, 8}, {1, 2, 3}, {4}, FALSE)', 16),
      ('=GROWTH({0, 1})', '#NUM!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });
}
