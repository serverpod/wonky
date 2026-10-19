import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matcher for an expected formula result: a number (relative tolerance 1e-12), an error
/// literal (`'#NUM!'`), a text, or a boolean.
Matcher _result(Object want) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, n.abs() * 1e-12 + 1e-15),
  ),
  final String s when s.startsWith('#') => isA<FError>().having(
    (v) => v.kind.literal,
    'error',
    s,
  ),
  final String s => isA<FText>().having((v) => v.v, 'text', s),
  final bool b => isA<FBool>().having((v) => v.v, 'bool', b),
  _ => throw ArgumentError(want),
};

void _vectors(FormulaTestBench t, List<(String, Object)> cases) {
  for (final (f, want) in cases) {
    test('when evaluating $f then it returns $want', () {
      final v = t.eval(f);

      expect(v, _result(want));
    });
  }
}

void main() {
  final t = FormulaTestBench();

  // Reference values: Microsoft Excel function documentation (BIN2DEC … OCT2HEX) and the
  // Google Sheets function help pages.
  group('Given binary conversions', () {
    _vectors(t, const [
      ('=BIN2DEC(1100100)', 100),
      ('=BIN2DEC("101")', 5),
      ('=BIN2DEC(1111111111)', -1),
      ('=BIN2DEC("1000000000")', -512),
      ('=BIN2DEC("")', 0),
      ('=BIN2DEC(12)', '#NUM!'),
      ('=BIN2DEC("10000000000")', '#NUM!'),
      ('=BIN2DEC(TRUE)', '#VALUE!'),
      ('=BIN2HEX(11111011, 4)', '00FB'),
      ('=BIN2HEX(1110)', 'E'),
      ('=BIN2HEX(1111111111)', 'FFFFFFFFFF'),
      ('=BIN2HEX(11111011, 1)', '#NUM!'),
      ('=BIN2HEX(1, 11)', '#NUM!'),
      ('=BIN2OCT(1001, 3)', '011'),
      ('=BIN2OCT(1100100)', '144'),
      ('=BIN2OCT(1111111111)', '7777777777'),
      ('=BIN2OCT(2)', '#NUM!'),
    ]);
  });

  group('Given decimal conversions', () {
    _vectors(t, const [
      ('=DEC2BIN(9, 4)', '1001'),
      ('=DEC2BIN(-100)', '1110011100'),
      ('=DEC2BIN(511)', '111111111'),
      ('=DEC2BIN(9.9)', '1001'),
      ('=DEC2BIN(-512)', '1000000000'),
      ('=DEC2BIN(512)', '#NUM!'),
      ('=DEC2BIN(-513)', '#NUM!'),
      ('=DEC2BIN(9, 0)', '#NUM!'),
      ('=DEC2BIN("abc")', '#VALUE!'),
      ('=DEC2HEX(100, 4)', '0064'),
      ('=DEC2HEX(-54)', 'FFFFFFFFCA'),
      ('=DEC2HEX(28)', '1C'),
      ('=DEC2HEX(-549755813888)', '8000000000'),
      ('=DEC2HEX(549755813888)', '#NUM!'),
      ('=DEC2HEX(64, 1)', '#NUM!'),
      ('=DEC2OCT(58, 3)', '072'),
      ('=DEC2OCT(-100)', '7777777634'),
      ('=DEC2OCT(536870911)', '3777777777'),
      ('=DEC2OCT(536870912)', '#NUM!'),
    ]);
  });

  group('Given hexadecimal conversions', () {
    _vectors(t, const [
      ('=HEX2BIN("F", 8)', '00001111'),
      ('=HEX2BIN("B7")', '10110111'),
      ('=HEX2BIN("FFFFFFFFFF")', '1111111111'),
      ('=HEX2BIN("FFFFFFFE00")', '1000000000'),
      ('=HEX2BIN("200")', '#NUM!'),
      ('=HEX2DEC("A5")', 165),
      ('=HEX2DEC("a5")', 165),
      ('=HEX2DEC("FFFFFFFF5B")', -165),
      ('=HEX2DEC("3DA408B9")', 1034160313),
      ('=HEX2DEC("G1")', '#NUM!'),
      ('=HEX2OCT("F", 3)', '017'),
      ('=HEX2OCT("3B4E")', '35516'),
      ('=HEX2OCT("FFFFFFFF00")', '7777777400'),
      ('=HEX2OCT("20000000")', '#NUM!'),
    ]);
  });

  group('Given octal conversions', () {
    _vectors(t, const [
      ('=OCT2BIN(3, 3)', '011'),
      ('=OCT2BIN(7777777000)', '1000000000'),
      ('=OCT2BIN(777)', '111111111'),
      ('=OCT2BIN(1000)', '#NUM!'),
      ('=OCT2DEC(54)', 44),
      ('=OCT2DEC(7777777533)', -165),
      ('=OCT2DEC(0)', 0),
      ('=OCT2DEC(8)', '#NUM!'),
      ('=OCT2HEX(100, 4)', '0040'),
      ('=OCT2HEX(7777777533)', 'FFFFFFFF5B'),
      ('=OCT2HEX(4000000000)', 'FFE0000000'),
      ('=OCT2HEX(9)', '#NUM!'),
    ]);
  });

  group('Given bitwise functions', () {
    _vectors(t, const [
      ('=BITAND(13, 25)', 9),
      ('=BITAND(1, 5)', 1),
      ('=BITAND(140737488355333, 140737488355331)', 140737488355329),
      ('=BITAND(-1, 2)', '#NUM!'),
      ('=BITAND(1.5, 1)', '#NUM!'),
      ('=BITAND(281474976710656, 1)', '#NUM!'),
      ('=BITOR(23, 10)', 31),
      ('=BITOR(0, 0)', 0),
      ('=BITOR(140737488355328, 1)', 140737488355329),
      ('=BITOR(-1, 1)', '#NUM!'),
      ('=BITXOR(5, 3)', 6),
      ('=BITXOR(10, 10)', 0),
      ('=BITXOR(140737488355329, 1)', 140737488355328),
      ('=BITXOR(1, 281474976710656)', '#NUM!'),
      ('=BITLSHIFT(4, 2)', 16),
      ('=BITLSHIFT(4, -1)', 2),
      ('=BITLSHIFT(1, 47)', 140737488355328),
      ('=BITLSHIFT(1, 54)', '#NUM!'),
      ('=BITLSHIFT(-1, 1)', '#NUM!'),
      ('=BITRSHIFT(13, 2)', 3),
      ('=BITRSHIFT(13, -2)', 52),
      ('=BITRSHIFT(140737488355328, 47)', 1),
      ('=BITRSHIFT(1, 60)', '#NUM!'),
    ]);
  });

  group('Given DELTA and GESTEP', () {
    _vectors(t, const [
      ('=DELTA(5, 4)', 0),
      ('=DELTA(5, 5)', 1),
      ('=DELTA(0)', 1),
      ('=DELTA(0.5)', 0),
      ('=DELTA("a", 1)', '#VALUE!'),
      ('=GESTEP(5, 4)', 1),
      ('=GESTEP(5, 5)', 1),
      ('=GESTEP(-4, -5)', 1),
      ('=GESTEP(-1)', 0),
      ('=GESTEP("x")', '#VALUE!'),
    ]);
  });

  // Reference values: Excel ERF/ERFC documentation and high-precision values of erf/erfc.
  group('Given error functions', () {
    _vectors(t, const [
      ('=ERF(0.745)', 0.707928920095738),
      ('=ERF(1)', 0.842700792949715),
      ('=ERF(0)', 0),
      ('=ERF(-1)', -0.842700792949715),
      ('=ERF(0.3)', 0.328626759459127),
      ('=ERF(0, 1.5)', 0.966105146475311),
      ('=ERF(1, 2)', 0.152621472069238),
      ('=ERF(-2, -1)', 0.152621472069238),
      ('=ERF(10)', 1),
      ('=ERF("x")', '#VALUE!'),
      ('=ERF.PRECISE(0.745)', 0.707928920095738),
      ('=ERF.PRECISE(1)', 0.842700792949715),
      ('=ERF.PRECISE("a")', '#VALUE!'),
      ('=ERFC(1)', 0.157299207050285),
      ('=ERFC(0)', 1),
      ('=ERFC(-1)', 1.84270079294971),
      ('=ERFC(0.5)', 0.479500122186953),
      ('=ERFC(2)', 0.00467773498104727),
      ('=ERFC(3)', 2.20904969985854e-5),
      ('=ERFC(30)', 0),
      ('=ERFC("a")', '#VALUE!'),
      ('=ERFC.PRECISE(1)', 0.157299207050285),
    ]);
  });

  group('Given the Bessel functions', () {
    _vectors(t, const [
      ('=BESSELI(1.5, 1)', '#NAME?'),
      ('=BESSELJ(1.9, 2)', '#NAME?'),
      ('=BESSELK(1.5, 1)', '#NAME?'),
      ('=BESSELY(2.5, 1)', '#NAME?'),
    ]);

    test(
      'when evaluating BESSELJ then the error explains it is unsupported',
      () {
        final v = t.eval('=BESSELJ(1.9, 2)');

        expect(
          v,
          isA<FError>().having(
            (e) => e.message,
            'message',
            contains('not in Google Sheets'),
          ),
        );
      },
    );
  });

  group('Given the engineering registry', () {
    test('when looking up ERFC.PRECISE then it resolves to ERFC', () {
      final spec = FunctionRegistry.standard.lookup('ERFC.PRECISE');

      expect(spec?.name, 'ERFC');
    });

    test('when looking up DEC2HEX then it is in the engineering category', () {
      final spec = FunctionRegistry.standard.lookup('DEC2HEX');

      expect(spec?.category, FunctionCategory.engineering);
    });
  });
}
