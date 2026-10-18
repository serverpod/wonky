import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matches a computed value: numbers within [rel] relative tolerance, `#…` error literals,
/// booleans, text, and `List<List<Object>>` arrays.
Matcher _value(Object want, {double rel = 1e-9}) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, math.max(n.abs() * rel, 1e-15)),
  ),
  final String s when s.startsWith('#') => isA<FError>().having(
    (e) => e.kind.literal,
    'error',
    s,
  ),
  final String s => isA<FText>().having((t) => t.v, 'text', s),
  final bool b => isA<FBool>().having((v) => v.v, 'bool', b),
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
  group('Given counting functions', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [1, 'x', true, "'5", null, '=""', '#N/A', 7]);
    const cases = <(String, Object)>[
      ('=COUNT(A1:A8)', 2),
      ('=COUNT(A1:A8, "3", TRUE, "abc")', 4),
      ('=COUNT(1/0, 2)', 1),
      ('=COUNT({1, "2", 3})', 2),
      ('=COUNTA(A1:A8)', 7),
      ('=COUNTA(1, "", "x")', 3),
      ('=COUNTA(B1:B5)', 0),
      ('=COUNTBLANK(A1:A8)', 2),
      ('=COUNTBLANK(B1:C3)', 6),
      ('=COUNTBLANK({1, ""})', 1),
      ('=COUNTUNIQUE(1, 2, 2, "a", "A", "b")', 4),
      ('=COUNTUNIQUE(A1:A5, 1)', 4),
      ('=COUNTUNIQUE(1/0)', '#DIV/0!'),
      ('=COUNTUNIQUEIFS({1; 2; 2; 3}, {"a"; "b"; "b"; "a"}, "b")', 1),
      ('=COUNTUNIQUEIFS({1; 2; 2; 3}, {5; 6; 7; 8}, ">5")', 2),
      ('=COUNTUNIQUEIFS({1; 2}, {1; 2; 3}, ">0")', '#VALUE!'),
      ('=COUNTUNIQUEIFS({1; 2}, {1; 2}, ">5")', 0),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given means and medians', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [10, 7, 9, 27, 2]);
    t.setColumn('B1', ['x', true, 4]);
    const cases = <(String, Object)>[
      // Excel docs: AVERAGE(A2:A6) = 11, AVERAGE(A2:A6, 5) = 10.
      ('=AVERAGE(A1:A5)', 11),
      ('=AVERAGE(A1:A5, 5)', 10),
      ('=AVERAGE(B1:B3)', 4),
      ('=AVERAGE(B1:B2)', '#DIV/0!'),
      ('=AVERAGE("2", TRUE)', 1.5),
      ('=AVERAGEA(B1:B3)', 5 / 3),
      ('=AVERAGEA(10, 7, 9, 2, "0", FALSE)', 14 / 3),
      ('=AVERAGEA(C1:C3)', '#DIV/0!'),
      ('=AVERAGE.WEIGHTED({1, 2, 3}, {4, 5, 6})', 32 / 15),
      ('=AVERAGE.WEIGHTED({1, 2}, {1, 1}, 4, 2)', 2.75),
      ('=AVERAGE.WEIGHTED({1, 2}, {0, 0})', '#DIV/0!'),
      ('=AVERAGE.WEIGHTED({1, 2}, {1, -1})', '#NUM!'),
      ('=AVERAGE.WEIGHTED({1, 2}, {1, 2, 3})', '#VALUE!'),
      // Excel docs: GEOMEAN/HARMEAN(4,5,8,7,11,4,3) = 5.476987 / 5.028376.
      ('=GEOMEAN(4, 5, 8, 7, 11, 4, 3)', 5.476986969656962),
      ('=GEOMEAN(4, 0)', '#NUM!'),
      ('=GEOMEAN(B1:B2)', '#NUM!'),
      ('=HARMEAN(4, 5, 8, 7, 11, 4, 3)', 5.028375962061728),
      ('=HARMEAN(1, -1)', '#NUM!'),
      ('=HARMEAN(2)', 2),
      // Excel docs: TRIMMEAN(A2:A12, 0.2) = 3.777777778.
      ('=TRIMMEAN({4, 5, 6, 7, 2, 3, 4, 5, 1, 2, 3}, 0.2)', 3.7777777777777777),
      ('=TRIMMEAN({1, 2, 3, 100}, 0)', 26.5),
      ('=TRIMMEAN({1, 2, 3}, 1)', '#NUM!'),
      // Excel docs: MEDIAN(1,2,3,4,5) = 3, MEDIAN(1..6) = 3.5.
      ('=MEDIAN(1, 2, 3, 4, 5)', 3),
      ('=MEDIAN(1, 2, 3, 4, 5, 6)', 3.5),
      ('=MEDIAN(A1:A5)', 9),
      ('=MEDIAN(B1:B2)', '#NUM!'),
      // Excel docs: MODE(5.6,4,4,3,2,4) = 4.
      ('=MODE(5.6, 4, 4, 3, 2, 4)', 4),
      ('=MODE.SNGL({1, 2, 2, 1})', 1),
      ('=MODE(1, 2, 3)', '#N/A'),
      (
        '=MODE.MULT({1, 2, 3, 4, 3, 2, 1, 2, 3, 5, 6, 1})',
        [
          [1],
          [2],
          [3],
        ],
      ),
      ('=MODE.MULT({1, 1, 2})', 1),
      ('=MODE.MULT(1, 2)', '#N/A'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given a range whose first number has a currency format', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [10, 20, 30]);
    t.sheet1.setNumberFormat(0, 0, r'"$"#,##0.00');
    for (final f in [
      '=AVERAGE(A1:A3)',
      '=MIN(A1:A3)',
      '=MAX(A1:A3)',
      '=MEDIAN(A1:A3)',
    ]) {
      test(
        'when evaluating $f then the result carries the cell format hint',
        () {
          expect(
            t.eval(f),
            isA<FNumber>().having(
              (n) => n.hint.kind,
              'hint',
              FormatHintKind.fromCell,
            ),
          );
        },
      );
    }
  });

  group('Given extremes and order statistics', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [10, 7, 9, 27, 2]);
    t.setColumn('B1', ['x', true]);
    const cases = <(String, Object)>[
      // Excel docs: MAX(A2:A6) = 27, MAX(A2:A6, 30) = 30, MIN(A2:A6) = 2, MIN(A2:A6,0) = 0.
      ('=MAX(A1:A5)', 27),
      ('=MAX(A1:A5, 30)', 30),
      ('=MAX(B1:B2)', 0),
      ('=MAX(A1:A5, 1/0)', '#DIV/0!'),
      ('=MIN(A1:A5)', 2),
      ('=MIN(A1:A5, 0)', 0),
      ('=MIN(B1:B2)', 0),
      ('=MAXA(B1:B2)', 1),
      ('=MAXA(-1, -2, B1)', 0),
      ('=MAXA(C1:C2)', 0),
      ('=MINA(B1:B2, 5)', 0),
      ('=MINA(2, 3)', 2),
      ('=MINA(1/0)', '#DIV/0!'),
      // Excel docs: LARGE(A2:B6, 3) = 5, LARGE(A2:B6, 7) = 4; SMALL(A2:A10, 4) = 4.
      ('=LARGE({3, 4; 5, 2; 3, 4; 5, 6; 4, 7}, 3)', 5),
      ('=LARGE({3, 4; 5, 2; 3, 4; 5, 6; 4, 7}, 7)', 4),
      ('=LARGE({1, 2}, 3)', '#NUM!'),
      ('=LARGE({1, 2}, 0)', '#NUM!'),
      ('=SMALL({3, 4, 5, 2, 3, 4, 6, 4, 7}, 4)', 4),
      ('=SMALL({1, 6, 4}, 1)', 1),
      ('=SMALL({1, 2}, 5)', '#NUM!'),
      // Excel docs: RANK(A3, A2:A6, 1) = 3 for 3.5 in {7,3.5,3.5,1,2}; RANK(7, …, 1) = 5.
      ('=RANK(3.5, {7, 3.5, 3.5, 1, 2}, 1)', 3),
      ('=RANK(7, {7, 3.5, 3.5, 1, 2}, 1)', 5),
      ('=RANK.EQ(7, {7, 3.5, 3.5, 1, 2})', 1),
      ('=RANK(4, {7, 3.5, 3.5, 1, 2})', '#N/A'),
      // Excel docs: RANK.AVG(94, {89,88,92,101,94,97,95}) = 4.
      ('=RANK.AVG(94, {89, 88, 92, 101, 94, 97, 95})', 4),
      ('=RANK.AVG(3.5, {7, 3.5, 3.5, 1, 2}, 1)', 3.5),
      ('=RANK.AVG(5, {1, 2})', '#N/A'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given percentiles, quartiles and percent ranks', () {
    final t = FormulaTestBench();
    const cases = <(String, Object)>[
      // Excel docs: PERCENTILE({1,3,2,4}, 0.3) = 1.9.
      ('=PERCENTILE({1, 3, 2, 4}, 0.3)', 1.9),
      ('=PERCENTILE.INC({1, 3, 2, 4}, 1)', 4),
      ('=PERCENTILE({1, 2}, 1.5)', '#NUM!'),
      ('=PERCENTILE({"a", "b"}, 0.5)', '#NUM!'),
      // Excel docs: PERCENTILE.EXC({1,2,3,6,6,6,7,8,9}, 0.25) = 2.5; 0 and 0.01 → #NUM!.
      ('=PERCENTILE.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 0.25)', 2.5),
      ('=PERCENTILE.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 0)', '#NUM!'),
      ('=PERCENTILE.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 0.01)', '#NUM!'),
      ('=PERCENTILE.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 0.9)', 9),
      // Excel docs: QUARTILE({1,2,4,7,8,9,10,12}, 1) = 3.5.
      ('=QUARTILE({1, 2, 4, 7, 8, 9, 10, 12}, 1)', 3.5),
      ('=QUARTILE.INC({1, 2, 4, 7, 8, 9, 10, 12}, 4)', 12),
      ('=QUARTILE({1, 2}, 5)', '#NUM!'),
      // Excel docs: QUARTILE.EXC({6,7,15,36,39,40,41,42,43,47,49}, 1) = 15, 3 → 43.
      ('=QUARTILE.EXC({6, 7, 15, 36, 39, 40, 41, 42, 43, 47, 49}, 1)', 15),
      ('=QUARTILE.EXC({6, 7, 15, 36, 39, 40, 41, 42, 43, 47, 49}, 3)', 43),
      ('=QUARTILE.EXC({6, 7, 15}, 0)', '#NUM!'),
      // Excel docs: PERCENTRANK.INC({13,12,11,8,4,3,2,1,1,1}, 2/4/8/5) = .333/.555/.666/.583.
      ('=PERCENTRANK({13, 12, 11, 8, 4, 3, 2, 1, 1, 1}, 2)', 0.333),
      ('=PERCENTRANK.INC({13, 12, 11, 8, 4, 3, 2, 1, 1, 1}, 4)', 0.555),
      ('=PERCENTRANK({13, 12, 11, 8, 4, 3, 2, 1, 1, 1}, 8)', 0.666),
      ('=PERCENTRANK({13, 12, 11, 8, 4, 3, 2, 1, 1, 1}, 5)', 0.583),
      ('=PERCENTRANK({13, 12, 11, 8, 4, 3, 2, 1, 1, 1}, 5, 1)', 0.5),
      ('=PERCENTRANK({1, 2, 3}, 4)', '#N/A'),
      ('=PERCENTRANK({1, 2, 3}, 2, 0)', '#NUM!'),
      // Excel docs: PERCENTRANK.EXC({1,2,3,6,6,6,7,8,9}, 7) = 0.7, 5.43 → 0.381, (5.43, 1) → 0.3.
      ('=PERCENTRANK.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 7)', 0.7),
      ('=PERCENTRANK.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 5.43)', 0.381),
      ('=PERCENTRANK.EXC({1, 2, 3, 6, 6, 6, 7, 8, 9}, 5.43, 1)', 0.3),
      ('=PERCENTRANK.EXC({1, 2, 3}, 0)', '#N/A'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given spread and shape functions', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [
      1345,
      1301,
      1368,
      1322,
      1310,
      1370,
      1318,
      1350,
      1303,
      1299,
    ]);
    t.setColumn('B1', [2, 'x', true]);
    const cases = <(String, Object)>[
      // Excel docs (breaking strength sample): STDEV 27.46392, STDEV.P 26.05456, VAR 754.2667,
      // VAR.P 678.84.
      ('=STDEV(A1:A10)', 27.463915719843495),
      ('=STDEV.S(A1:A10)', 27.463915719843495),
      ('=STDEV(5)', '#DIV/0!'),
      ('=STDEV.P(A1:A10)', 26.054558142482477),
      ('=STDEVP(3)', 0),
      ('=STDEV.P(B2:B3)', '#DIV/0!'),
      ('=STDEVA(B1:B3)', 1),
      ('=STDEVA(1, 2, 3)', 1),
      ('=STDEVA(C1:C3)', '#DIV/0!'),
      ('=STDEVPA(B1:B3)', 0.816496580927726),
      ('=STDEVPA(4, 4)', 0),
      ('=STDEVPA(C1)', '#DIV/0!'),
      ('=VAR(A1:A10)', 754.2666666666667),
      ('=VAR.S(1, 2, 3, 4)', 1.6666666666666667),
      ('=VAR(1)', '#DIV/0!'),
      ('=VAR.P(A1:A10)', 678.84),
      ('=VARP(1, 2, 3, 4)', 1.25),
      ('=VAR.P(C1:C2)', '#DIV/0!'),
      ('=VARA(B1:B3)', 1),
      ('=VARA(2, 4)', 2),
      ('=VARA(1)', '#DIV/0!'),
      ('=VARPA(B1:B3)', 0.6666666666666666),
      ('=VARPA(2, 4)', 1),
      ('=VARPA(C1)', '#DIV/0!'),
      // Excel docs: DEVSQ(4,5,8,7,11,4,3) = 48; AVEDEV(4,5,6,7,5,4,3) = 1.020408163.
      ('=DEVSQ(4, 5, 8, 7, 11, 4, 3)', 48),
      ('=DEVSQ(5)', 0),
      ('=DEVSQ(C1:C2)', '#NUM!'),
      ('=AVEDEV(4, 5, 6, 7, 5, 4, 3)', 1.0204081632653061),
      ('=AVEDEV(2, 2)', 0),
      ('=AVEDEV(C1:C2)', '#NUM!'),
      // Excel docs: KURT(3,4,5,2,3,4,5,6,4,7) = -0.151799637; SKEW = 0.359543; SKEW.P = 0.303193.
      ('=KURT(3, 4, 5, 2, 3, 4, 5, 6, 4, 7)', -0.15179963720841272),
      ('=KURT(1, 2, 3)', '#DIV/0!'),
      ('=KURT(2, 2, 2, 2)', '#DIV/0!'),
      ('=SKEW(3, 4, 5, 2, 3, 4, 5, 6, 4, 7)', 0.3595430714067978),
      ('=SKEW(1, 2)', '#DIV/0!'),
      ('=SKEW(1, 2, 3)', 0),
      ('=SKEW.P(3, 4, 5, 2, 3, 4, 5, 6, 4, 7)', 0.3031933393541443),
      ('=SKEW.P(1, 1)', '#DIV/0!'),
      ('=SKEW.P(1, 2, 3)', 0),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given standardization, Fisher and combinatorics', () {
    final t = FormulaTestBench();
    const cases = <(String, Object)>[
      // Excel docs: STANDARDIZE(42, 40, 1.5) = 1.333333333.
      ('=STANDARDIZE(42, 40, 1.5)', 1.3333333333333333),
      ('=STANDARDIZE(40, 40, 2)', 0),
      ('=STANDARDIZE(1, 2, 0)', '#NUM!'),
      // Excel docs: FISHER(0.75) = 0.972955075; FISHERINV(0.972955) = 0.75.
      ('=FISHER(0.75)', 0.9729550745276566),
      ('=FISHER(0)', 0),
      ('=FISHER(1)', '#NUM!'),
      ('=FISHERINV(0.972955)', 0.7499999673941484),
      ('=FISHERINV(0)', 0),
      ('=FISHERINV("x")', '#VALUE!'),
      // Excel docs: PERMUT(100, 3) = 970200, PERMUT(3, 2) = 6.
      ('=PERMUT(100, 3)', 970200),
      ('=PERMUT(3, 2)', 6),
      ('=PERMUT(3.9, 0)', 1),
      ('=PERMUT(2, 3)', '#NUM!'),
      // Excel docs: PERMUTATIONA(3, 2) = 9, PERMUTATIONA(2, 2) = 4.
      ('=PERMUTATIONA(3, 2)', 9),
      ('=PERMUTATIONA(2, 2)', 4),
      ('=PERMUTATIONA(0, 0)', 1),
      ('=PERMUTATIONA(-1, 2)', '#NUM!'),
      // Excel docs: PROB({0,1,2,3}, {0.2,0.3,0.1,0.4}, 2) = 0.1, (…, 1, 3) = 0.8.
      ('=PROB({0, 1, 2, 3}, {0.2, 0.3, 0.1, 0.4}, 2)', 0.1),
      ('=PROB({0, 1, 2, 3}, {0.2, 0.3, 0.1, 0.4}, 1, 3)', 0.8),
      ('=PROB({0, 1}, {0.2, 0.3}, 1)', '#NUM!'),
      ('=PROB({0, 1}, {0.5, 0.5, 0}, 1)', '#N/A'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });
}
