import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Reference values: Microsoft Excel / Google Sheets documentation examples (rounded value in
/// the comment, full-precision value recomputed independently from the documented formulas),
/// LibreOffice algorithms for DB/DDB/VDB.

/// Matcher for an expected result: number (relative tolerance [rel]), error literal, text.
Matcher _result(Object want, double rel) => switch (want) {
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, rel * (n.abs() < 1 ? 1 : n.abs())),
  ),
  final String e when e.startsWith('#') => isA<FError>().having(
    (v) => v.kind.literal,
    'error',
    e,
  ),
  final String s => isA<FText>().having((v) => v.v, 'text', s),
  final bool b => isA<FBool>().having((v) => v.v, 'bool', b),
  _ => throw ArgumentError(want),
};

void _vectors(
  FormulaTestBench t,
  List<(String, Object)> cases, {
  double rel = 1e-9,
}) {
  for (final (formula, want) in cases) {
    test('when evaluating $formula then it returns $want', () {
      final v = t.eval(formula);

      expect(v, _result(want, rel));
    });
  }
}

void main() {
  group('Given payment functions', () {
    final t = FormulaTestBench();
    _vectors(t, const [
      ('=PMT(0.08/12, 10, 10000)', -1037.03208935916), // Excel: -1037.03
      ('=PMT(0.06/12, 18*12, 0, 50000)', -129.081160867995), // Excel: -129.08
      ('=PMT(0.08/12, 10, 10000, 0, 1)', -1030.1643271779735),
      ('=PMT(0, 10, 1000)', -100),
      ('=PMT(0.05, 0, 1000)', '#NUM!'),
      ('=PMT("abc", 10, 1000)', '#VALUE!'),
      ('=FV(0.06/12, 10, -200, -500, 1)', 2581.40337406014), // Excel: 2581.40
      ('=FV(0.12/12, 12, -1000)', 12682.503013197), // Excel: 12682.50
      ('=FV(0.11/12, 35, -2000, , 1)', 82846.2463719006), // Excel: 82846.25
      ('=FV(0, 10, -100, -1000)', 2000),
      ('=FV("abc", 10, -100)', '#VALUE!'),
      ('=PV(0.08/12, 12*20, 500, , 0)', -59777.1458511878), // Excel: -59777.15
      ('=PV(0.05, 10, 100, 1000, 1)', -1424.695421105165),
      ('=PV(0, 10, 100)', -1000),
      ('=PV(0.05, "x", 100)', '#VALUE!'),
      (
        '=NPER(0.12/12, -100, -1000, 10000, 1)',
        59.6738656742946,
      ), // Excel: 59.6738657
      (
        '=NPER(0.12/12, -100, -1000, 10000)',
        60.0821228537617,
      ), // Excel: 60.0821229
      ('=NPER(0.12/12, -100, -1000)', -9.57859403981316), // Excel: -9.57859404
      ('=NPER(0, -100, 1000)', 10),
      ('=NPER(0, 0, 1000)', '#NUM!'),
      ('=NPER(0.1, -10, 1000)', '#NUM!'),
      ('=IPMT(0.1/12, 1, 3*12, 8000)', -66.6666666666667), // Excel: -66.67
      ('=IPMT(0.1, 3, 3, 8000)', -292.447129909366), // Excel: -292.45
      ('=IPMT(0.1, 1, 3, 8000, 0, 1)', 0),
      ('=IPMT(0.1, 0, 3, 8000)', '#NUM!'),
      ('=PPMT(0.1/12, 1, 2*12, 2000)', -75.6231860083666), // Excel: -75.62
      ('=PPMT(0.08, 10, 10, 200000)', -27598.0534624214), // Excel: -27598.05
      ('=PPMT(0, 1, 10, 1000)', -100),
      ('=PPMT(0.1, 4, 3, 8000)', '#NUM!'),
      (
        '=ISPMT(0.1/12, 1, 3*12, 8000000)',
        -64814.8148148148,
      ), // Excel: -64814.8
      ('=ISPMT(0.1, 1, 3, 8000000)', -533333.333333333), // Excel: -533333
      ('=ISPMT(0.1, 3, 3, 8000)', 0),
      ('=ISPMT(0.1, 1, 0, 8000)', '#DIV/0!'),
      (
        '=CUMIPMT(0.09/12, 30*12, 125000, 13, 24, 0)',
        -11135.2321307508,
      ), // Excel: -11135.23213
      ('=CUMIPMT(0.09/12, 30*12, 125000, 1, 1, 0)', -937.5), // Excel: -937.5
      ('=CUMIPMT(0.09/12, 30*12, 125000, 13, 24, 2)', '#NUM!'),
      ('=CUMIPMT(0.09/12, 30*12, 125000, 24, 13, 0)', '#NUM!'),
      ('=CUMIPMT(0, 30*12, 125000, 1, 12, 0)', '#NUM!'),
      (
        '=CUMPRINC(0.09/12, 30*12, 125000, 13, 24, 0)',
        -934.107123420876,
      ), // Excel: -934.1071234
      (
        '=CUMPRINC(0.09/12, 30*12, 125000, 1, 1, 0)',
        -68.2782711809767,
      ), // Excel: -68.27827118
      ('=CUMPRINC(0.09/12, 30*12, 125000, 1, 360, 0)', -125000),
      ('=CUMPRINC(0.09/12, 30*12, 125000, 1, 361, 0)', '#NUM!'),
    ]);

    test('when evaluating PMT then the result has a currency format hint', () {
      final v = t.eval('=PMT(0.08/12, 10, 10000)');

      expect(
        v,
        isA<FNumber>().having(
          (n) => n.hint,
          'hint',
          FormatHint.currencyDefault,
        ),
      );
    });

    test('when evaluating NPER then the result has no format hint', () {
      final v = t.eval('=NPER(0, -100, 1000)');

      expect(v, isA<FNumber>().having((n) => n.hint, 'hint', FormatHint.none));
    });
  });

  group('Given RATE (iterative)', () {
    final t = FormulaTestBench();
    _vectors(t, rel: 1e-6, const [
      ('=RATE(4*12, -200, 8000)', 0.007701472488201888), // Excel: 0.77%
      ('=RATE(4*12, -200, 8000)*12', 0.0924176698584197), // Excel: 9.24%
      ('=RATE(10, 0, -1000, 2000)', 0.07177346253629313),
      ('=RATE(10, 100, 1000)', '#NUM!'),
      ('=RATE(0, -200, 8000)', '#NUM!'),
    ]);
  });

  group('Given rate conversion and growth functions', () {
    final t = FormulaTestBench();
    t.setColumn('C1', [0.09, 'text', null, 0.11, 0.1]);
    _vectors(t, const [
      ('=EFFECT(0.0525, 4)', 0.0535426673707582), // Excel: 0.053542667
      ('=EFFECT(0.0525, 4.9)', 0.0535426673707582),
      ('=EFFECT(0.1, 1)', 0.1),
      ('=EFFECT(0, 4)', '#NUM!'),
      ('=NOMINAL(0.053543, 4)', 0.052500319868356), // Excel: 0.052500319
      ('=NOMINAL(0.1, 1)', 0.1),
      ('=NOMINAL(-0.1, 4)', '#NUM!'),
      ('=PDURATION(0.025, 2000, 2200)', 3.85986616262266), // Excel: 3.86
      ('=PDURATION(0.025/12, 1000, 1200)', 87.6054764193714), // Excel: 87.6
      ('=PDURATION(0.1, 100, 100)', 0),
      ('=PDURATION(0, 1, 2)', '#NUM!'),
      ('=RRI(96, 10000, 11000)', 0.00099330737629133), // Excel: 0.0009933
      ('=RRI(2, 100, 121)', 0.1),
      ('=RRI(0, 1, 2)', '#NUM!'),
      ('=FVSCHEDULE(1, {0.09, 0.11, 0.1})', 1.33089), // Excel: 1.33089
      ('=FVSCHEDULE(1, C1:C5)', 1.33089),
      ('=FVSCHEDULE(1000, {0})', 1000),
      ('=FVSCHEDULE(1, "abc")', '#VALUE!'),
      ('=DOLLARDE(1.02, 16)', 1.125), // Excel: 1.125
      ('=DOLLARDE(1.1, 32)', 1.3125), // Excel: 1.3125
      ('=DOLLARDE(-1.02, 16)', -1.125),
      ('=DOLLARDE(1.1, 10)', 1.1),
      ('=DOLLARDE(1.02, 0)', '#DIV/0!'),
      ('=DOLLARDE(1.02, -1)', '#NUM!'),
      ('=DOLLARFR(1.125, 16)', 1.02), // Excel: 1.02
      ('=DOLLARFR(1.125, 32)', 1.04), // Excel: 1.04
      ('=DOLLARFR(2, 8)', 2),
      ('=DOLLARFR(1.125, 0)', '#DIV/0!'),
    ]);
  });

  group('Given periodic cash flows in cells', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [-70000, 12000, 'skip', 15000, null, 18000, 21000]);
    t.setColumn('B1', [8000, 9200, 10000, 'text', 12000, 14500]);
    _vectors(t, const [
      (
        '=NPV(0.1, -10000, 3000, 4200, 6800)',
        1188.44341233522,
      ), // Excel: 1188.44
      ('=NPV(0.08, B1:B6) + -40000', 1922.0615549323993), // Excel: 1922.06
      (
        '=NPV(0.08, B1:B6, -9000) + -40000',
        -3749.4650870155965,
      ), // Excel: -3749.47
      ('=NPV(0.1, 110)', 100),
      ('=NPV(-1, 100)', '#DIV/0!'),
      ('=NPV(0.1, "abc")', '#VALUE!'),
      (
        '=MIRR({-120000, 39000, 30000, 21000, 37000, 46000}, 0.1, 0.12)',
        0.126094130365905,
      ), // Excel: 12.61%
      (
        '=MIRR({-120000, 39000, 30000, 21000}, 0.1, 0.12)',
        -0.0480446552499808,
      ), // Excel: -4.80%
      (
        '=MIRR({-120000, 39000, 30000, 21000, 37000, 46000}, 0.1, 0.14)',
        0.134759110828315,
      ), // Excel: 13.48%
      ('=MIRR({100, 200}, 0.1, 0.1)', '#DIV/0!'),
    ]);

    test('when evaluating NPV then the result has a currency format hint', () {
      final v = t.eval('=NPV(0.1, 110)');

      expect(
        v,
        isA<FNumber>().having(
          (n) => n.hint,
          'hint',
          FormatHint.currencyDefault,
        ),
      );
    });
  });

  group('Given internal rate of return functions (iterative)', () {
    final t = FormulaTestBench();
    t.setColumn('A1', [-70000, 12000, 'skip', 15000, null, 18000, 21000]);
    t.setColumn('B1', [-10000, 2750, 4250, 3250, 2750]);
    t.setColumn('C1', [
      '2008-01-01',
      '2008-03-01',
      '2008-10-30',
      '2009-02-15',
      '2009-04-01',
    ]);
    t.setColumn('D1', [
      '2008-01-01',
      '2007-03-01',
      '2008-10-30',
      '2009-02-15',
      '2009-04-01',
    ]);
    _vectors(t, rel: 1e-6, const [
      (
        '=IRR({-70000, 12000, 15000, 18000, 21000})',
        -0.021244848273410947,
      ), // Excel: -2.1%
      (
        '=IRR({-70000, 12000, 15000, 18000, 21000, 26000})',
        0.0866309480365316,
      ), // Excel: 8.7%
      (
        '=IRR({-70000, 12000, 15000}, -0.1)',
        -0.4435069413347405,
      ), // Excel: -44.4%
      ('=IRR(A1:A7)', -0.021244848273410947),
      ('=IRR({1, 2, 3})', '#NUM!'),
      (
        '=IRR({-1000, 1})',
        -0.999,
      ), // Newton leaves the domain, bisection fallback
      (
        '=IRR({-100, 230, -132}, 0.18)',
        0.2,
      ), // two roots: the one near the guess
      ('=XNPV(0.09, B1:B5, C1:C5)', 2086.6476020315354), // Excel: 2086.65
      ('=XNPV(0.1, {100}, {39448})', 100),
      ('=XNPV(0.09, B1:B5, D1:D5)', '#NUM!'),
      ('=XNPV(0.09, B1:B5, C1:C4)', '#NUM!'),
      ('=XIRR(B1:B5, C1:C5)', 0.37336253351883136), // Excel: 0.373362535
      ('=XIRR(B1:B5, C1:C5, 0.5)', 0.37336253351883136),
      ('=XIRR({100, 200}, {39448, 39500})', '#NUM!'),
      ('=XIRR(B1:B5, C1:C4)', '#NUM!'),
    ]);
  });

  group('Given depreciation functions', () {
    final t = FormulaTestBench();
    _vectors(t, const [
      ('=SLN(30000, 7500, 10)', 2250), // Excel: 2250
      ('=SLN(1000, 1000, 5)', 0),
      ('=SLN(1000, 100, 0)', '#DIV/0!'),
      ('=SYD(30000, 7500, 10, 1)', 4090.90909090909), // Excel: 4090.91
      ('=SYD(30000, 7500, 10, 10)', 409.090909090909), // Excel: 409.09
      ('=SYD(30000, 7500, 10, 11)', '#NUM!'),
      ('=DB(1000000, 100000, 6, 1, 7)', 186083.333333333), // Excel: 186083.33
      ('=DB(1000000, 100000, 6, 2, 7)', 259639.416666667), // Excel: 259639.42
      ('=DB(1000000, 100000, 6, 3, 7)', 176814.44275), // Excel: 176814.44
      ('=DB(1000000, 100000, 6, 4, 7)', 120410.63551275), // Excel: 120410.64
      ('=DB(1000000, 100000, 6, 5, 7)', 81999.6427841827), // Excel: 81999.64
      ('=DB(1000000, 100000, 6, 6, 7)', 55841.7567360285), // Excel: 55841.76
      ('=DB(1000000, 100000, 6, 7, 7)', 15845.0984738481), // Excel: 15845.10
      ('=DB(0, 0, 6, 1)', 0),
      ('=DB(1000000, 100000, 6, 1, 13)', '#NUM!'),
      ('=DB(1000000, 100000, 6, 8, 7)', '#NUM!'),
      ('=DDB(2400, 300, 10*365, 1)', 1.31506849315065), // Excel: 1.32
      ('=DDB(2400, 300, 10*12, 1, 2)', 40), // Excel: 40.00
      ('=DDB(2400, 300, 10, 1, 2)', 480), // Excel: 480.00
      ('=DDB(2400, 300, 10, 2, 1.5)', 306), // Excel: 306.00
      ('=DDB(2400, 300, 10, 10)', 22.1225472000002), // Excel: 22.12
      ('=DDB(2400, 300, 10, 11)', '#NUM!'),
      ('=DDB(2400, 300, 10, 1, 0)', '#NUM!'),
      ('=VDB(2400, 300, 10*365, 0, 1)', 1.31506849315065), // Excel: 1.32
      ('=VDB(2400, 300, 10*12, 0, 1)', 40), // Excel: 40.00
      ('=VDB(2400, 300, 10, 0, 1)', 480), // Excel: 480.00
      ('=VDB(2400, 300, 10*12, 6, 18)', 396.306053264752), // Excel: 396.31
      ('=VDB(2400, 300, 10*12, 6, 18, 1.5)', 311.808936658233), // Excel: 311.81
      ('=VDB(2400, 300, 10, 0, 0.875, 1.5)', 315), // Excel: 315.00
      ('=VDB(2400, 300, 10, 1, 3, 2, TRUE)', 691.2),
      ('=VDB(2400, 300, 10, 0, 10)', 2100),
      ('=VDB(2400, 300, 10, 0, 11)', '#NUM!'),
      ('=VDB(2400, 300, 10, 5, 3)', '#NUM!'),
    ]);
  });

  group('Given the financial function registry', () {
    final registry = FunctionRegistry.standard;
    const names = [
      'PMT',
      'FV',
      'PV',
      'NPER',
      'RATE',
      'NPV',
      'IRR',
      'IPMT',
      'PPMT',
      'ISPMT',
      'CUMIPMT', //
      'CUMPRINC',
      'XNPV',
      'XIRR',
      'MIRR',
      'EFFECT',
      'NOMINAL',
      'PDURATION',
      'RRI',
      'FVSCHEDULE',
      'DB',
      'DDB',
      'SLN',
      'SYD',
      'VDB',
      'DOLLARDE',
      'DOLLARFR',
      'ACCRINT',
      'ACCRINTM',
      'AMORLINC',
      'COUPDAYBS',
      'COUPDAYS',
      'COUPDAYSNC',
      'COUPNCD',
      'COUPNUM',
      'COUPPCD',
      'DISC',
      'DURATION',
      'MDURATION',
      'INTRATE',
      'PRICE',
      'PRICEDISC',
      'PRICEMAT',
      'RECEIVED',
      'TBILLEQ',
      'TBILLPRICE', 'TBILLYIELD', 'YIELD', 'YIELDDISC', 'YIELDMAT',
    ];
    for (final name in names) {
      test(
        'when looking up $name then it is an implemented financial function',
        () {
          final spec = registry.lookup(name);

          expect(
            spec,
            isA<FunctionSpec>()
                .having(
                  (s) => s.category,
                  'category',
                  FunctionCategory.financial,
                )
                .having((s) => s.implemented, 'implemented', true)
                .having((s) => s.help.examples, 'examples', isNotEmpty),
          );
        },
      );
    }

    final t = FormulaTestBench();
    _vectors(t, const [
      ('=ODDFPRICE(1, 2, 3)', '#NAME?'),
      ('=ODDFYIELD(1)', '#NAME?'),
      ('=ODDLPRICE(1)', '#NAME?'),
      ('=ODDLYIELD(1)', '#NAME?'),
      ('=AMORDEGRC(2400, 39679, 39813, 300, 1, 0.15, 1)', '#NAME?'),
    ]);

    test(
      'when evaluating an unsupported stub then the message says it is not available',
      () {
        final v = t.eval('=ODDFPRICE(1)');

        expect(
          v,
          isA<FError>().having(
            (e) => e.message,
            'message',
            "ODDFPRICE isn't available in Wonky Sheets.",
          ),
        );
      },
    );
  });
}
