import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matcher for an expected formula result: a number (relative tolerance 1e-12), an error
/// literal (`'#N/A'`), a text, or a boolean.
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

void main() {
  // Reference values: Google Sheets and Excel CONVERT documentation, Excel unit table.
  group('Given CONVERT', () {
    final t = FormulaTestBench();
    const cases = <(String, Object)>[
      ('=CONVERT(5.1, "g", "kg")', 0.0051),
      ('=CONVERT(1, "lbm", "kg")', 0.45359237),
      ('=CONVERT(1, "ozm", "g")', 28.349523125),
      ('=CONVERT(1, "stone", "lbm")', 14),
      ('=CONVERT(CONVERT(100, "ft", "m"), "ft", "m")', 9.290304),
      ('=CONVERT(1, "mi", "km")', 1.609344),
      ('=CONVERT(1, "m", "ft")', 3.28083989501312),
      ('=CONVERT(1, "in", "cm")', 2.54),
      ('=CONVERT(1, "Nmi", "m")', 1852),
      ('=CONVERT(1, "day", "hr")', 24),
      ('=CONVERT(1, "yr", "day")', 365.25),
      ('=CONVERT(90, "mn", "hr")', 1.5),
      ('=CONVERT(1, "ms", "s")', 0.001),
      ('=CONVERT(1, "atm", "Pa")', 101325),
      ('=CONVERT(1, "mmHg", "Pa")', 133.322368421053),
      ('=CONVERT(1, "kPa", "Pa")', 1000),
      ('=CONVERT(1, "kN", "N")', 1000),
      ('=CONVERT(1, "lbf", "N")', 4.4482216152605),
      ('=CONVERT(1, "kcal", "J")', 4186.8),
      ('=CONVERT(1, "kWh", "J")', 3600000),
      ('=CONVERT(1, "BTU", "J")', 1055.05585262),
      ('=CONVERT(1, "HP", "W")', 745.69987158227),
      ('=CONVERT(1, "kW", "W")', 1000),
      ('=CONVERT(1, "T", "ga")', 10000),
      ('=CONVERT(68, "F", "C")', 20),
      ('=CONVERT(32, "C", "F")', 89.6),
      ('=CONVERT(0, "K", "C")', -273.15),
      ('=CONVERT(100, "C", "Rank")', 671.67),
      ('=CONVERT(80, "Reau", "C")', 100),
      ('=CONVERT(1, "mK", "K")', 0.001),
      ('=CONVERT(1, "gal", "l")', 3.785411784),
      ('=CONVERT(1, "m3", "l")', 1000),
      ('=CONVERT(1, "cm3", "ml")', 1),
      ('=CONVERT(1, "ft^3", "in3")', 1728),
      ('=CONVERT(1, "ha", "m2")', 10000),
      ('=CONVERT(1, "km^2", "ha")', 100),
      ('=CONVERT(1, "uk_acre", "m2")', 4046.8564224),
      ('=CONVERT(1, "byte", "bit")', 8),
      ('=CONVERT(1, "kbyte", "byte")', 1000),
      ('=CONVERT(1, "kibyte", "byte")', 1024),
      ('=CONVERT(1, "Gibyte", "Mibyte")', 1024),
      ('=CONVERT(1, "kn", "m/s")', 0.514444444444444),
      ('=CONVERT(1, "mph", "km/h")', 1.609344),
      ('=CONVERT(2.5, "ft", "sec")', '#N/A'),
      ('=CONVERT(1, "xyz", "m")', '#N/A'),
      ('=CONVERT(1, "m", "kg")', '#N/A'),
      ('=CONVERT(1, "LBM", "kg")', '#N/A'),
      ('=CONVERT(1, "kft", "m")', '#N/A'),
      ('=CONVERT(1, "kim", "m")', '#N/A'),
      ('=CONVERT("abc", "m", "ft")', '#VALUE!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        final v = t.eval(f);

        expect(v, _result(want));
      });
    }
  });

  group('Given the TO_ format functions', () {
    final t = FormulaTestBench();
    const hintCases = <(String, double, FormatHint)>[
      ('=TO_DATE(45000)', 45000, FormatHint.date),
      ('=TO_DATE("45000"+0)', 45000, FormatHint.date),
      ('=TO_DOLLARS(1.5)', 1.5, FormatHint.currencyDefault),
      ('=TO_PERCENT(0.25)', 0.25, FormatHint.percent),
      ('=TO_PURE_NUMBER(50%)', 0.5, FormatHint.none),
      ('=TO_PURE_NUMBER(TO_DATE(45000))', 45000, FormatHint.none),
    ];
    for (final (f, want, hint) in hintCases) {
      test('when evaluating $f then it returns $want with hint $hint', () {
        final v = t.eval(f);

        expect(
          v,
          isA<FNumber>()
              .having((n) => n.v, 'value', want)
              .having((n) => n.hint, 'hint', hint),
        );
      });
    }

    const passThrough = <(String, Object)>[
      ('=TO_DATE("abc")', 'abc'),
      ('=TO_DATE(1/0)', '#DIV/0!'),
      ('=TO_DOLLARS(TRUE)', true),
      ('=TO_DOLLARS(1/0)', '#DIV/0!'),
      ('=TO_PERCENT("x")', 'x'),
      ('=TO_PERCENT(1/0)', '#DIV/0!'),
      ('=TO_PURE_NUMBER("abc")', 'abc'),
      ('=TO_PURE_NUMBER(1/0)', '#DIV/0!'),
    ];
    for (final (f, want) in passThrough) {
      test('when evaluating $f then it returns $want', () {
        final v = t.eval(f);

        expect(v, _result(want));
      });
    }
  });

  group('Given TO_TEXT and cells with number formats', () {
    final t = FormulaTestBench();
    t.setAll({
      'A1': 45000,
      'A2': 0.5,
      'A3': 1234.5,
      'A4': '=TO_DOLLARS(5)',
      'A5': 'abc',
      'C1': 10,
      'C2': 20,
      'C3': 30,
    });
    t.sheet1.setNumberFormat(0, 0, 'yyyy-mm-dd');
    t.sheet1.setNumberFormat(1, 0, '0%');
    t.sheet1.setNumberFormat(1, 2, '0.0');

    const cases = <(String, Object)>[
      ('=TO_TEXT(24)', '24'),
      ('=TO_TEXT(1/3)', '0.333333333333333'),
      ('=TO_TEXT(A1)', '2023-03-15'),
      ('=TO_TEXT(A2)', '50%'),
      ('=TO_TEXT(A3)', '1234.5'),
      ('=TO_TEXT(A4)', r'$5.00'),
      ('=TO_TEXT(A5)', 'abc'),
      ('=TO_TEXT(A9)', ''),
      ('=TO_TEXT(TRUE)', 'TRUE'),
      ('=TO_TEXT(TO_DATE(45000))', '3/15/2023'),
      ('=TO_TEXT(TO_PERCENT(0.245))', '24.50%'),
      ('=TO_TEXT(TO_DOLLARS(1234.5))', r'$1,234.50'),
      ('=TO_TEXT(TO_PURE_NUMBER(A1))', '45000'),
      ('=TO_TEXT(1/0)', '#DIV/0!'),
      ('=TO_TEXT(A1:A3)', '#VALUE!'),
    ];
    for (final (f, want) in cases) {
      test('when evaluating $f then it returns $want', () {
        final v = t.eval(f);

        expect(v, _result(want));
      });
    }

    test(
      'when evaluating TO_TEXT of a column in its second row then it formats that cell',
      () {
        final v = t.eval('=TO_TEXT(C1:C3)', at: 'D2');

        expect(v, _result('20.0'));
      },
    );
  });

  group('Given a de_DE spreadsheet', () {
    final t = FormulaTestBench(settings: const CalcSettings(locale: 'de_DE'));

    test(
      'when evaluating TO_TEXT of a decimal then it uses the decimal comma',
      () {
        final v = t.eval('=TO_TEXT(1,5)');

        expect(v, _result('1,5'));
      },
    );

    test(
      'when evaluating TO_TEXT of a date then it uses the German date order',
      () {
        final v = t.eval('=TO_TEXT(TO_DATE(45000))');

        expect(v, _result('15.03.2023'));
      },
    );
  });

  group('Given the parser registry', () {
    test('when looking up TO_TEXT then it is in the parser category', () {
      final spec = FunctionRegistry.standard.lookup('TO_TEXT');

      expect(spec?.category, FunctionCategory.parser);
    });
  });
}
