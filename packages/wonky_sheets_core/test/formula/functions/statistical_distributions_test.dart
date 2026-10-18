import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matches a number within [rel] relative tolerance, or an error literal (`#…`).
Matcher _value(Object want, {double rel = 1e-9}) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, math.max(n.abs() * rel, 1e-15)),
  ),
  final String s => isA<FError>().having((e) => e.kind.literal, 'error', s),
  _ => throw ArgumentError('unsupported expectation $want'),
};

/// Reference values: Excel/Google Sheets documentation examples, recomputed to full precision
/// from closed forms (erfc, finite sums for integer parameters, exact rational pmfs).
const _distributions = <(String, Object)>[
  // Normal family (Excel docs: NORM.DIST(42,40,1.5,TRUE) = 0.9087888, FALSE = 0.10934).
  ('=NORM.DIST(42, 40, 1.5, TRUE)', 0.9087887802741321),
  ('=NORMDIST(42, 40, 1.5, FALSE)', 0.10934004978399577),
  ('=NORM.DIST(42, 40, 0, TRUE)', '#NUM!'),
  ('=NORM.DIST(40, 40, 1, TRUE)', 0.5),
  ('=NORM.S.DIST(1.333333, TRUE)', 0.9087887256040951),
  ('=NORM.S.DIST(1.333333, FALSE)', 0.16401014756936722),
  ('=NORMSDIST(1.333333)', 0.9087887256040951),
  ('=NORM.S.DIST(-40)', 0),
  ('=NORM.S.DIST("x")', '#VALUE!'),
  ('=LOGNORM.DIST(4, 3.5, 1.2, TRUE)', 0.0390835557068005),
  ('=LOGNORM.DIST(4, 3.5, 1.2, FALSE)', 0.01761759668181923),
  ('=LOGNORMDIST(4, 3.5, 1.2)', 0.0390835557068005),
  ('=LOGNORM.DIST(0, 3.5, 1.2, TRUE)', '#NUM!'),
  ('=LOGNORMDIST(4, 3.5, -1)', '#NUM!'),
  ('=GAUSS(2)', 0.4772498680518208),
  ('=GAUSS(0)', 0),
  ('=GAUSS(-2)', -0.4772498680518208),
  ('=PHI(0.75)', 0.30113743215480443),
  ('=PHI(0)', 0.3989422804014327),
  ('=PHI("a")', '#VALUE!'),
  // Student t (Excel docs: T.DIST(60,1,TRUE) = 0.99469533, T.DIST(8,3,FALSE) = 0.00073691,
  // T.DIST.2T(1.959999998,60) = 0.054645, T.DIST.RT(…) = 0.027322).
  ('=T.DIST(60, 1, TRUE)', 0.9946953263673768),
  ('=T.DIST(8, 3, FALSE)', 0.0007369065209469266),
  ('=T.DIST(-1, 2, TRUE)', 0.21132486540518708),
  ('=T.DIST(1, 0, TRUE)', '#NUM!'),
  ('=T.DIST.2T(1.959999998, 60)', 0.05464492997592052),
  ('=T.DIST.2T(0, 5)', 1),
  ('=T.DIST.2T(-1, 5)', '#NUM!'),
  ('=T.DIST.RT(1.959999998, 60)', 0.02732246498796026),
  ('=T.DIST.RT(-1, 2)', 0.7886751345948129),
  ('=T.DIST.RT(1, 0.5)', '#NUM!'),
  ('=TDIST(1.959999998, 60, 2)', 0.05464492997592052),
  ('=TDIST(1.959999998, 60, 1)', 0.02732246498796026),
  ('=TDIST(1, 60, 3)', '#NUM!'),
  // Chi-squared (Excel docs: CHISQ.DIST(0.5,1,TRUE) = 0.52049988, CHISQ.DIST(2,3,FALSE) =
  // 0.20755375, CHISQ.DIST.RT(18.307,10) = 0.0500006).
  ('=CHISQ.DIST(0.5, 1, TRUE)', 0.5204998778130465),
  ('=CHISQ.DIST(2, 3, FALSE)', 0.2075537487102974),
  ('=CHISQ.DIST(3, 4, TRUE)', 0.44217459962892547),
  ('=CHISQ.DIST(-1, 4, TRUE)', '#NUM!'),
  ('=CHISQ.DIST.RT(18.307, 10)', 0.05000058909139812),
  ('=CHIDIST(18.307, 10)', 0.05000058909139812),
  ('=CHISQ.DIST.RT(0, 3)', 1),
  ('=CHISQ.DIST.RT(1, 0)', '#NUM!'),
  // F (Excel docs: F.DIST(15.2069,6,4,TRUE) = 0.99, FALSE = 0.0012238, F.DIST.RT = 0.01).
  ('=F.DIST(15.2069, 6, 4, TRUE)', 0.9900000430027627),
  ('=F.DIST(15.2069, 6, 4, FALSE)', 0.0012237917087831722),
  ('=F.DIST(0, 6, 4, TRUE)', 0),
  ('=F.DIST(-1, 6, 4, TRUE)', '#NUM!'),
  ('=F.DIST.RT(15.2069, 6, 4)', 0.009999956997237325),
  ('=FDIST(15.2069, 6, 4)', 0.009999956997237325),
  ('=F.DIST.RT(1, 0, 4)', '#NUM!'),
  // Beta (Excel docs: BETA.DIST(2,8,10,TRUE,1,3) = 0.6854706, FALSE = 1.4837646).
  ('=BETA.DIST(2, 8, 10, TRUE, 1, 3)', 0.6854705810546875),
  ('=BETA.DIST(2, 8, 10, FALSE, 1, 3)', 1.4837646484375058),
  ('=BETA.DIST(0.4, 2, 1, TRUE)', 0.16),
  ('=BETA.DIST(4, 8, 10, TRUE, 1, 3)', '#NUM!'),
  ('=BETADIST(2, 8, 10, 1, 3)', 0.6854705810546875),
  ('=BETADIST(0.5, 1, 1)', 0.5),
  ('=BETADIST(0.5, 0, 1)', '#NUM!'),
  // Gamma (Excel docs: GAMMA.DIST(10.00001131,9,2,FALSE) = 0.032639, TRUE = 0.068094).
  ('=GAMMA.DIST(10.00001131, 9, 2, TRUE)', 0.06809400386978748),
  ('=GAMMADIST(10.00001131, 9, 2, FALSE)', 0.032639130418294),
  ('=GAMMA.DIST(0, 1, 2, TRUE)', 0),
  ('=GAMMA.DIST(1, 0, 2, TRUE)', '#NUM!'),
  // Excel docs: GAMMA(2.5) = 1.329340388, GAMMA(-3.75) = 0.267866129, GAMMA(0) = #NUM!.
  ('=GAMMA(2.5)', 1.329340388179137),
  ('=GAMMA(-3.75)', 0.2678661288614166),
  ('=GAMMA(0.5)', 1.7724538509055159),
  ('=GAMMA(5)', 24),
  ('=GAMMA(0)', '#NUM!'),
  ('=GAMMA(-2)', '#NUM!'),
  // Excel docs: GAMMALN(4) = 1.791759469.
  ('=GAMMALN(4)', 1.791759469228055),
  ('=GAMMALN(0.5)', 0.5723649429247004),
  ('=GAMMALN.PRECISE(100)', 359.1342053695754),
  ('=GAMMALN(0)', '#NUM!'),
  // Discrete (Excel docs: BINOM.DIST(6,10,0.5,FALSE) = 0.2050781, NEGBINOM.DIST(10,5,0.25,…)
  // = 0.3135141 / 0.0550487, POISSON.DIST(2,5,…) = 0.124652 / 0.084224,
  // HYPGEOM.DIST(1,4,8,20,…) = 0.4654 / 0.3633).
  ('=BINOM.DIST(6, 10, 0.5, FALSE)', 0.205078125),
  ('=BINOM.DIST(6, 10, 0.5, TRUE)', 0.828125),
  ('=BINOMDIST(3, 8, 0.35, TRUE)', 0.7063994361328125),
  ('=BINOM.DIST(6.9, 10, 0.5, FALSE)', 0.205078125),
  ('=BINOM.DIST(0, 10, 0, FALSE)', 1),
  ('=BINOM.DIST(11, 10, 0.5, FALSE)', '#NUM!'),
  ('=BINOM.DIST(1, 10, 1.5, FALSE)', '#NUM!'),
  ('=NEGBINOM.DIST(10, 5, 0.25, FALSE)', 0.05504866037517786),
  ('=NEGBINOM.DIST(10, 5, 0.25, TRUE)', 0.3135140584781766),
  ('=NEGBINOMDIST(10, 5, 0.25)', 0.05504866037517786),
  ('=NEGBINOM.DIST(0, 1, 1, FALSE)', 1),
  ('=NEGBINOM.DIST(10, 0, 0.25, FALSE)', '#NUM!'),
  ('=POISSON.DIST(2, 5, TRUE)', 0.12465201948308113),
  ('=POISSON.DIST(2, 5, FALSE)', 0.08422433748856833),
  ('=POISSON(2, 5, TRUE)', 0.12465201948308113),
  ('=POISSON.DIST(0, 0, TRUE)', 1),
  ('=POISSON.DIST(-1, 5, TRUE)', '#NUM!'),
  ('=HYPGEOM.DIST(1, 4, 8, 20, TRUE)', 0.46542827657378744),
  ('=HYPGEOM.DIST(1, 4, 8, 20, FALSE)', 0.3632610939112487),
  ('=HYPGEOMDIST(1, 4, 8, 20)', 0.3632610939112487),
  ('=HYPGEOMDIST(4, 4, 4, 4)', 1),
  ('=HYPGEOM.DIST(5, 4, 8, 20, FALSE)', '#NUM!'),
  ('=HYPGEOMDIST(1, 30, 8, 20)', '#NUM!'),
  // Exponential & Weibull (Excel docs: EXPON.DIST(0.2,10,TRUE) = 0.86466472, FALSE =
  // 1.35335283; WEIBULL.DIST(105,20,100,TRUE) = 0.929581, FALSE = 0.035589).
  ('=EXPON.DIST(0.2, 10, TRUE)', 0.8646647167633873),
  ('=EXPONDIST(0.2, 10, FALSE)', 1.353352832366127),
  ('=EXPON.DIST(0, 10, TRUE)', 0),
  ('=EXPON.DIST(0.2, 0, TRUE)', '#NUM!'),
  ('=WEIBULL.DIST(105, 20, 100, TRUE)', 0.9295813900692769),
  ('=WEIBULL(105, 20, 100, FALSE)', 0.03558886402450434),
  ('=WEIBULL.DIST(0, 1, 1, TRUE)', 0),
  ('=WEIBULL.DIST(1, 0, 1, TRUE)', '#NUM!'),
  // Confidence intervals (Excel docs: CONFIDENCE.NORM(0.05,2.5,50) = 0.692952,
  // CONFIDENCE.T(0.05,1,50) = 0.284196855).
  ('=CONFIDENCE.NORM(0.05, 2.5, 50)', 0.6929519121748389),
  ('=CONFIDENCE(0.05, 2.5, 50)', 0.6929519121748389),
  ('=CONFIDENCE.NORM(1, 2.5, 50)', '#NUM!'),
  ('=CONFIDENCE.NORM(0.05, 2.5, 0.5)', '#NUM!'),
  ('=CONFIDENCE.T(0.05, 2.5, 1)', '#DIV/0!'),
  ('=CONFIDENCE.T(0.05, 0, 50)', '#NUM!'),
];

/// Inverses: closed forms for special parameters plus documented examples (1e-6 relative).
const _inverses = <(String, Object)>[
  // Excel docs: NORM.S.INV(0.908789) = 1.3333347, NORM.INV(0.908789,40,1.5) = 42.000002.
  ('=NORM.S.INV(0.908789)', 1.3333346730441071),
  ('=NORMSINV(0.001)', -3.090232306167813),
  ('=NORM.S.INV(1E-10)', -6.361340902404057),
  ('=NORM.S.INV(0.5)', 0),
  ('=NORM.S.INV(1)', '#NUM!'),
  ('=NORM.INV(0.908789, 40, 1.5)', 42.00000200956616),
  ('=NORMINV(0.5, 3, 2)', 3),
  ('=NORM.INV(0, 40, 1.5)', '#NUM!'),
  ('=NORM.INV(0.5, 40, 0)', '#NUM!'),
  // Excel docs: LOGNORM.INV(0.039084,3.5,1.2) = 4.0000252.
  ('=LOGNORM.INV(0.039084, 3.5, 1.2)', 4.000025218680636),
  ('=LOGINV(0.5, 0, 1)', 1),
  ('=LOGNORM.INV(1.5, 0, 1)', '#NUM!'),
  // Excel docs: T.INV(0.75,2) = 0.8164966; T.INV.2T(0.546449,60) = 0.606533.
  ('=T.INV(0.75, 2)', 0.8164965809277261),
  ('=T.INV(0.1, 1)', -3.077683537175253),
  ('=T.INV(0.5, 7)', 0),
  ('=T.INV(0, 2)', '#NUM!'),
  ('=T.INV.2T(0.5, 1)', 1),
  ('=TINV(0.546449, 60)', 0.606533),
  ('=T.INV.2T(1, 3)', 0),
  ('=T.INV.2T(1.5, 3)', '#NUM!'),
  // Excel docs: CHISQ.INV(0.93,1) = 3.283020287, CHISQ.INV(0.6,2) = 1.832581464,
  // CHISQ.INV.RT(0.050001,10) = 18.30697.
  ('=CHISQ.INV(0.93, 1)', 3.283020286759538),
  ('=CHISQ.INV(0.6, 2)', 1.83258146374831),
  ('=CHISQ.INV(0, 2)', 0),
  ('=CHISQ.INV(1, 2)', '#NUM!'),
  ('=CHISQ.INV.RT(0.05, 2)', 5.991464547107982),
  ('=CHIINV(0.050001, 10)', 18.30697),
  ('=CHISQ.INV.RT(0, 2)', '#NUM!'),
  // Excel docs: F.INV(0.01,6,4) = 0.10930991, F.INV.RT(0.01,6,4) = 15.20686.
  ('=F.INV(0.3, 2, 5)', 0.38337276945463294),
  ('=F.INV(0.01, 6, 4)', 0.10930991),
  ('=F.INV(1, 6, 4)', '#NUM!'),
  ('=F.INV.RT(0.3, 2, 5)', 1.5466114569183653),
  ('=FINV(0.01, 6, 4)', 15.20686),
  ('=F.INV.RT(0, 6, 4)', '#NUM!'),
  // Excel docs: BETA.INV(0.685470581,8,10,1,3) = 2.
  ('=BETA.INV(0.685470581, 8, 10, 1, 3)', 2),
  ('=BETAINV(0.3, 1, 3)', 0.11209599825739935),
  ('=BETA.INV(1, 2, 3)', 1),
  ('=BETA.INV(0, 2, 3)', '#NUM!'),
  // Excel docs: GAMMA.INV(0.068094,9,2) = 10.0000112.
  ('=GAMMA.INV(0.068094, 9, 2)', 10.0000112),
  ('=GAMMAINV(0.5, 1, 3)', 2.0794415416798357),
  ('=GAMMA.INV(0, 9, 2)', 0),
  ('=GAMMA.INV(0.5, 0, 2)', '#NUM!'),
  // Excel docs: BINOM.INV(6,0.5,0.75) = 4.
  ('=BINOM.INV(6, 0.5, 0.75)', 4),
  ('=CRITBINOM(6, 0.5, 0.65625)', 3),
  ('=BINOM.INV(6, 0.5, 0)', 0),
  ('=BINOM.INV(6, 1.5, 0.5)', '#NUM!'),
];

void main() {
  group('Given probability distribution functions', () {
    final t = FormulaTestBench();
    for (final (f, want) in _distributions) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want));
      });
    }
  });

  group('Given inverse distribution functions', () {
    final t = FormulaTestBench();
    for (final (f, want) in _inverses) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want, rel: 1e-6));
      });
    }
  });

  group('Given hypothesis tests', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [3, 4, 5, 8, 9, 1, 2, 4, 5]);
    t.setColumn('B1', [6, 19, 3, 2, 14, 4, 5, 17, 1]);
    const cases = <(String, Object)>[
      // Excel docs: T.TEST(A2:A10, B2:B10, 2, 1) = 0.196016.
      ('=T.TEST(A1:A9, B1:B9, 2, 1)', 0.196015785),
      ('=TTEST(A1:A9, B1:B9, 1, 1)', 0.0980078925),
      ('=T.TEST({1, 2, 3}, {1, 2, 3}, 2, 2)', 1),
      ('=T.TEST({1, 2, 3, 4}, {3, 4, 5, 6}, 2, 2)', 0.07098765432098775),
      ('=T.TEST({1, 2, 3, 4}, {3, 4, 5, 6}, 2, 3)', 0.07098765432098775),
      ('=T.TEST(A1:A9, B1:B9, 3, 1)', '#NUM!'),
      ('=T.TEST({1}, {2}, 2, 2)', '#DIV/0!'),
      // Excel docs: F.TEST({6,7,9,15,21}, {20,28,31,38,40}) = 0.648318.
      ('=F.TEST({6, 7, 9, 15, 21}, {20, 28, 31, 38, 40})', 0.64831785),
      ('=FTEST({1, 2, 3}, {2, 4, 6})', 0.4),
      ('=F.TEST({1}, {2, 3})', '#DIV/0!'),
      // Excel docs: CHISQ.TEST(A2:B4, A6:B8) = 0.0003082 (df = 2, so p = exp(-χ²/2)).
      (
        '=CHISQ.TEST({58, 35; 11, 25; 10, 23}, {45.35, 47.65; 17.56, 18.44; 16.09, 16.91})',
        0.00030819201700830936,
      ),
      ('=CHITEST({10, 10}, {10, 10})', 1),
      ('=CHISQ.TEST({1, 2}, {1, 2, 3})', '#N/A'),
      ('=CHISQ.TEST({1, 2}, {0, 2})', '#DIV/0!'),
      // Excel docs: Z.TEST(A2:A11, 4) = 0.090574, Z.TEST(A2:A11, 6) = 0.863043.
      ('=Z.TEST({3, 6, 7, 8, 6, 5, 4, 2, 1, 9}, 4)', 0.09057419685136381),
      ('=ZTEST({3, 6, 7, 8, 6, 5, 4, 2, 1, 9}, 6)', 0.8630433891295299),
      ('=Z.TEST({1, 2, 3}, 2, 1)', 0.5),
      ('=Z.TEST({"a", "b"}, 2)', '#N/A'),
      // MARGINOFERROR: Student t half-width, equals CONFIDENCE.T(1 − confidence, STDEV, n).
      ('=MARGINOFERROR({1, 2, 3, 4, 5}, 0.95)', 1.963243161),
      ('=MARGINOFERROR({1, 2}, 1)', '#NUM!'),
      ('=MARGINOFERROR({1}, 0.9)', '#DIV/0!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        expect(t.eval(f), _value(want, rel: 1e-8));
      });
    }
  });
}
