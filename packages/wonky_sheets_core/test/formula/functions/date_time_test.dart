import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matcher for an expected formula result: a number (tolerance 1e-9), an error literal
/// (`'#NUM!'`), a text, or a boolean.
Matcher _result(Object want) => switch (want) {
  final num n => isA<FNumber>().having((v) => v.v, 'value', closeTo(n, 1e-9)),
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

/// Seconds as a fraction of a day.
double _t(int h, int m, num s) => (h * 3600 + m * 60 + s) / 86400;

void main() {
  // Reference values: Microsoft Excel function documentation examples, Google Sheets function
  // help pages; serials computed from the 1899-12-30 epoch (05 §6.5).
  final t = FormulaTestBench(now: DateTime.utc(2026, 10, 12, 14, 30, 15));

  group('Given DATE', () {
    _vectors(t, const [
      ('=DATE(1969, 7, 20)', 25404),
      ('=DATE(108, 1, 2)', 39449),
      ('=DATE(2008, 1, 35)', 39482),
      ('=DATE(2008, 14, 2)', 39846),
      ('=DATE(2008, -3, 2)', 39327),
      ('=DATE(2024, 13, 1)', 45658),
      ('=DATE("2024", 1, 1)', 45292),
      ('=DATE(2024.9, 1.9, 1.9)', 45292),
      ('=DATE(1900, 1, -100)', -99),
      ('=DATE(9999, 12, 31)', 2958465),
      ('=DATE(9999, 12, 32)', '#NUM!'),
      ('=DATE(-1, 1, 1)', '#NUM!'),
      ('=DATE(10000, 1, 1)', '#NUM!'),
      ('=DATE("x", 1, 1)', '#VALUE!'),
    ]);
  });

  group('Given DATEDIF', () {
    _vectors(t, const [
      ('=DATEDIF("2001-01-01", "2003-01-01", "Y")', 2),
      ('=DATEDIF("2001-06-01", "2002-08-15", "D")', 440),
      ('=DATEDIF("2001-06-01", "2002-08-15", "YD")', 75),
      ('=DATEDIF("2001-06-01", "2002-08-15", "MD")', 14),
      ('=DATEDIF("2001-06-01", "2002-08-15", "M")', 14),
      ('=DATEDIF("2001-06-01", "2002-08-15", "YM")', 2),
      ('=DATEDIF("2001-06-01", "2002-08-15", "y")', 1),
      ('=DATEDIF("2024-01-31", "2024-02-29", "M")', 0),
      ('=DATEDIF("2011-01-31", "2011-03-01", "MD")', 1),
      ('=DATEDIF("2023-12-25", "2024-01-05", "YD")', 11),
      ('=DATEDIF("2024-01-01", "2024-01-01", "D")', 0),
      ('=DATEDIF("2003-01-01", "2001-01-01", "Y")', '#NUM!'),
      ('=DATEDIF("2001-01-01", "2003-01-01", "W")', '#NUM!'),
    ]);
  });

  group('Given DATEVALUE', () {
    _vectors(t, const [
      ('=DATEVALUE("1969-7-20")', 25404),
      ('=DATEVALUE("7/20/1969")', 25404),
      ('=DATEVALUE("20 July 1969")', 25404),
      ('=DATEVALUE("2024-03-01 14:30")', 45352),
      ('=DATEVALUE(25404.5)', 25404),
      ('=DATEVALUE("10:00")', '#VALUE!'),
      ('=DATEVALUE("hello")', '#VALUE!'),
      ('=DATEVALUE("2024-02-30")', '#VALUE!'),
    ]);
  });

  group('Given DATEVALUE in a day-month-year locale', () {
    final de = FormulaTestBench(settings: const CalcSettings(locale: 'de_DE'));
    _vectors(de, const [('=DATEVALUE("12.10.2026")', 46307)]);
  });

  group('Given YEAR, MONTH and DAY', () {
    _vectors(t, const [
      ('=YEAR(DATE(1969, 7, 20))', 1969),
      ('=MONTH(DATE(1969, 7, 20))', 7),
      ('=DAY(DATE(1969, 7, 20))', 20),
      ('=YEAR("2024-03-01")', 2024),
      ('=MONTH("15-Mar-2021")', 3),
      ('=DAY(45351.99)', 29),
      ('=YEAR(-1)', 1899),
      ('=MONTH(0)', 12),
      ('=DAY(0)', 30),
      ('=YEAR(-1000000)', '#NUM!'),
      ('=MONTH(2958466)', '#NUM!'),
      ('=DAY("abc")', '#VALUE!'),
    ]);
  });

  group('Given DAYS', () {
    _vectors(t, const [
      ('=DAYS("15-MAR-2021", "1-FEB-2021")', 42),
      ('=DAYS(DATE(2021, 12, 31), DATE(2021, 1, 1))', 364),
      ('=DAYS(1, 10)', -9),
      ('=DAYS(10.9, 1.1)', 9),
      ('=DAYS("x", 1)', '#VALUE!'),
    ]);
  });

  group('Given DAYS360', () {
    _vectors(t, const [
      ('=DAYS360("1-Jan-11", "31-Dec-11")', 360),
      ('=DAYS360("30-Jan-11", "1-Feb-11")', 1),
      ('=DAYS360("2011-01-30", "2011-12-31")', 330),
      ('=DAYS360("2011-01-29", "2011-03-31")', 62),
      ('=DAYS360("2011-01-29", "2011-03-31", TRUE)', 61),
      ('=DAYS360("2011-02-28", "2011-03-31")', 30),
      ('=DAYS360("2011-02-28", "2011-03-31", TRUE)', 32),
      ('=DAYS360("2011-12-30", "2011-01-01")', -359),
      ('=DAYS360("x", 1)', '#VALUE!'),
    ]);
  });

  group('Given EDATE and EOMONTH', () {
    _vectors(t, const [
      ('=EDATE("15-Jan-11", 1)', 40589),
      ('=EDATE("15-Jan-11", -1)', 40527),
      ('=EDATE("15-Jan-11", 2)', 40617),
      ('=EDATE("2024-01-31", 1)', 45351),
      ('=EDATE(DATE(2024, 1, 31), 1.9)', 45351),
      ('=EDATE(DATE(9999, 12, 1), 1)', '#NUM!'),
      ('=EDATE("x", 1)', '#VALUE!'),
      ('=EOMONTH("1-Jan-11", 1)', 40602),
      ('=EOMONTH("1-Jan-11", -3)', 40482),
      ('=EOMONTH("2024-02-10", 0)', 45351),
      ('=EOMONTH("2024-03-15 18:00", 0)', 45382),
      ('=EOMONTH(DATE(9999, 12, 1), 1)', '#NUM!'),
      ('=EOMONTH("x", 1)', '#VALUE!'),
    ]);
  });

  group('Given EPOCHTODATE', () {
    _vectors(t, [
      ('=EPOCHTODATE(1655906710)', 44734 + _t(14, 5, 10)),
      ('=EPOCHTODATE(1655906568893, 2)', 44734 + _t(14, 2, 48.893)),
      ('=EPOCHTODATE(1655906568893123, 3)', 44734 + _t(14, 2, 48.893)),
      ('=EPOCHTODATE(0)', 25569),
      ('=EPOCHTODATE(1.9999, 1)', 25569 + _t(0, 0, 1.999)),
      ('=EPOCHTODATE(-1)', '#NUM!'),
      ('=EPOCHTODATE(1, 4)', '#NUM!'),
      ('=EPOCHTODATE(1e15)', '#NUM!'),
    ]);
  });

  group('Given HOUR, MINUTE and SECOND', () {
    _vectors(t, const [
      ('=HOUR(0.75)', 18),
      ('=HOUR("7/18/2011 7:45")', 7),
      ('=HOUR("4/21/2012")', 0),
      ('=HOUR(-0.25)', 18),
      ('=HOUR(0.99999999)', 0),
      ('=MINUTE("12:45:00 PM")', 45),
      ('=MINUTE(TIME(10, 59, 59) + 0.6/86400)', 0),
      ('=SECOND("4:48:18 PM")', 18),
      ('=SECOND("4:48 PM")', 0),
      ('=SECOND(1.6/86400)', 2),
      ('=HOUR("abc")', '#VALUE!'),
      ('=MINUTE(-1000000)', '#NUM!'),
      ('=SECOND("x")', '#VALUE!'),
    ]);
  });

  group('Given ISOWEEKNUM', () {
    _vectors(t, const [
      ('=ISOWEEKNUM("3/9/2012")', 10),
      ('=ISOWEEKNUM(DATE(2021, 1, 1))', 53),
      ('=ISOWEEKNUM(DATE(2024, 12, 30))', 1),
      ('=ISOWEEKNUM(DATE(2026, 1, 1))', 1),
      ('=ISOWEEKNUM("x")', '#VALUE!'),
    ]);
  });

  group('Given NETWORKDAYS with holidays in A2:A6', () {
    final n = FormulaTestBench();
    n.setColumn('A2', [
      '2012-10-01',
      '2013-03-01',
      '2012-11-22',
      '2012-12-04',
      '2013-01-21',
    ]);
    _vectors(n, const [
      ('=NETWORKDAYS(A2, A3)', 110),
      ('=NETWORKDAYS(A2, A3, A4)', 109),
      ('=NETWORKDAYS(A2, A3, A4:A6)', 107),
      ('=NETWORKDAYS(A3, A2, A4:A6)', -107),
      ('=NETWORKDAYS(A2, A3, A4:A10)', 107),
      ('=NETWORKDAYS(A2, A3, DATE(2012, 10, 6))', 110),
      ('=NETWORKDAYS(A2, A3, {"2012-11-22", "2012-11-22"})', 109),
      ('=NETWORKDAYS(DATE(2012, 10, 6), DATE(2012, 10, 6))', 0),
      ('=NETWORKDAYS(A2, A3, {"x"})', '#VALUE!'),
      ('=NETWORKDAYS("x", A3)', '#VALUE!'),
    ]);
  });

  group('Given NETWORKDAYS.INTL', () {
    _vectors(t, const [
      ('=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 1, 31))', 22),
      ('=NETWORKDAYS.INTL(DATE(2006, 1, 31), DATE(2006, 1, 1))', -22),
      (
        '=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 2, 1), 7, {"2006/1/2", "2006/1/16"})',
        22,
      ),
      (
        '=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 2, 1), "0010001", {"2006/1/2", "2006/1/16"})',
        20,
      ),
      ('=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 1, 31), 11)', 26),
      ('=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 1, 31), "0000000")', 31),
      ('=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 1, 31), 8)', '#NUM!'),
      (
        '=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 1, 31), "1111111")',
        '#VALUE!',
      ),
      (
        '=NETWORKDAYS.INTL(DATE(2006, 1, 1), DATE(2006, 1, 31), "001")',
        '#VALUE!',
      ),
    ]);
  });

  group('Given TIME', () {
    _vectors(t, [
      ('=TIME(12, 0, 0)', 0.5),
      ('=TIME(16, 48, 10)', 0.700115740740741),
      ('=TIME(25, 0, 0)', 1 / 24),
      ('=TIME(1, -30, 0)', _t(0, 30, 0)),
      ('=TIME(0, 0, 90)', _t(0, 1, 30)),
      ('=TIME(1.9, 0, 0)', 1 / 24),
      ('=TIME(0, -1, 0)', '#NUM!'),
      ('=TIME("x", 0, 0)', '#VALUE!'),
    ]);
  });

  group('Given TIMEVALUE', () {
    _vectors(t, [
      ('=TIMEVALUE("2:24 AM")', 0.1),
      ('=TIMEVALUE("22-Aug-2011 6:35 AM")', _t(6, 35, 0)),
      ('=TIMEVALUE("14:15:30")', _t(14, 15, 30)),
      ('=TIMEVALUE("2024-01-01")', 0),
      ('=TIMEVALUE(45000.25)', 0.25),
      ('=TIMEVALUE("x")', '#VALUE!'),
    ]);
  });

  group('Given WEEKDAY', () {
    _vectors(t, const [
      ('=WEEKDAY("2008-02-14")', 5),
      ('=WEEKDAY("2008-02-14", 2)', 4),
      ('=WEEKDAY("2008-02-14", 3)', 3),
      ('=WEEKDAY("2008-02-14", 11)', 4),
      ('=WEEKDAY("2008-02-14", 16)', 6),
      ('=WEEKDAY("2008-02-14", 17)', 5),
      ('=WEEKDAY(0)', 7),
      ('=WEEKDAY(-1)', 6),
      ('=WEEKDAY("2008-02-14", 4)', '#NUM!'),
      ('=WEEKDAY("2008-02-14", 18)', '#NUM!'),
      ('=WEEKDAY("x")', '#VALUE!'),
    ]);
  });

  group('Given WEEKNUM', () {
    _vectors(t, const [
      ('=WEEKNUM("2012-03-09")', 10),
      ('=WEEKNUM("2012-03-09", 2)', 11),
      ('=WEEKNUM("2012-03-09", 11)', 11),
      ('=WEEKNUM(DATE(2022, 1, 1))', 1),
      ('=WEEKNUM(DATE(2022, 1, 2))', 2),
      ('=WEEKNUM(DATE(2022, 1, 2), 2)', 1),
      ('=WEEKNUM(DATE(2021, 1, 1), 21)', 53),
      ('=WEEKNUM(DATE(2022, 12, 31), 17)', 53),
      ('=WEEKNUM("2012-03-09", 3)', '#NUM!'),
      ('=WEEKNUM("x")', '#VALUE!'),
    ]);
  });

  group('Given WORKDAY', () {
    _vectors(t, const [
      ('=WORKDAY(DATE(2008, 10, 1), 151)', 39933),
      (
        '=WORKDAY(DATE(2008, 10, 1), 151, {"2008-11-26", "2008-12-04", "2009-01-21"})',
        39938,
      ),
      ('=WORKDAY(DATE(2009, 4, 30), -151)', 39722),
      (
        '=WORKDAY(DATE(2009, 5, 5), -151, {"2008-11-26", "2008-12-04", "2009-01-21"})',
        39722,
      ),
      ('=WORKDAY(DATE(2024, 1, 6), 0)', 45297),
      ('=WORKDAY(DATE(2024, 1, 6), 1)', 45299),
      ('=WORKDAY(DATE(2024, 1, 5), 1, DATE(2024, 1, 8))', 45300),
      ('=WORKDAY(DATE(9999, 12, 31), 1)', '#NUM!'),
      ('=WORKDAY("x", 1)', '#VALUE!'),
    ]);
  });

  group('Given WORKDAY.INTL', () {
    _vectors(t, const [
      ('=WORKDAY.INTL(DATE(2012, 1, 1), 90, 11)', 41013),
      ('=WORKDAY.INTL(DATE(2012, 1, 1), 30, 17)', 40944),
      ('=WORKDAY.INTL(DATE(2008, 10, 1), 151, 1)', 39933),
      ('=WORKDAY.INTL(DATE(2024, 1, 5), 1, "0000110")', 45298),
      ('=WORKDAY.INTL(DATE(2012, 1, 1), 30, 0)', '#NUM!'),
      ('=WORKDAY.INTL(DATE(2012, 1, 1), 30, "1111111")', '#VALUE!'),
    ]);
  });

  group('Given YEARFRAC', () {
    _vectors(t, const [
      ('=YEARFRAC("2012-01-01", "2012-07-30")', 209 / 360),
      ('=YEARFRAC("2012-01-01", "2012-07-30", 1)', 211 / 366),
      ('=YEARFRAC("2012-01-01", "2012-07-30", 2)', 211 / 360),
      ('=YEARFRAC("2012-01-01", "2012-07-30", 3)', 211 / 365),
      ('=YEARFRAC("2012-01-01", "2012-07-30", 4)', 209 / 360),
      ('=YEARFRAC("2012-07-30", "2012-01-01")', 209 / 360),
      ('=YEARFRAC(DATE(2000, 1, 1), DATE(2003, 1, 1), 1)', 1096 / 365.25),
      ('=YEARFRAC(DATE(2011, 2, 28), DATE(2012, 2, 29))', 1),
      ('=YEARFRAC(DATE(2011, 3, 1), DATE(2012, 2, 29), 1)', 365 / 366),
      ('=YEARFRAC(DATE(2024, 1, 1), DATE(2024, 1, 1), 1)', 0),
      ('=YEARFRAC("2012-01-01", "2012-07-30", 5)', '#NUM!'),
      ('=YEARFRAC("x", "2012-07-30")', '#VALUE!'),
    ]);
  });

  group('Given NOW and TODAY with a fixed clock in UTC', () {
    _vectors(t, [
      ('=NOW()', 46307 + _t(14, 30, 15)),
      ('=TODAY()', 46307),
      ('=NOW() - TODAY()', _t(14, 30, 15)),
    ]);
  });

  group('Given date arguments as arrays', () {
    test(
      'when evaluating YEAR over an array then it is lifted element-wise',
      () {
        final v = t.eval('=YEAR({"2024-01-01", "2025-06-01"})');

        expect((v as FArray).toRows(), [
          [const FNumber(2024), const FNumber(2025)],
        ]);
      },
    );

    test(
      'when evaluating NETWORKDAYS over an array of end dates then it is lifted',
      () {
        final v = t.eval(
          '=NETWORKDAYS(DATE(2006, 1, 1), {"2006-01-06"; "2006-01-31"})',
        );

        expect((v as FArray).toRows(), [
          [const FNumber(5)],
          [const FNumber(22)],
        ]);
      },
    );
  });

  group('Given results with automatic formats', () {
    const hints = <(String, FormatHint)>[
      ('=DATE(2024, 1, 1)', FormatHint.date),
      ('=DATEVALUE("2024-01-01")', FormatHint.date),
      ('=EDATE("2024-01-31", 1)', FormatHint.date),
      ('=EOMONTH("2024-01-31", 1)', FormatHint.date),
      ('=WORKDAY(DATE(2024, 1, 5), 1)', FormatHint.date),
      ('=WORKDAY.INTL(DATE(2024, 1, 5), 1, 7)', FormatHint.date),
      ('=TODAY()', FormatHint.date),
      ('=NOW()', FormatHint.dateTime),
      ('=EPOCHTODATE(0)', FormatHint.dateTime),
      ('=TIME(1, 2, 3)', FormatHint.time),
      ('=TIMEVALUE("1:02:03")', FormatHint.time),
      ('=YEAR(DATE(2024, 1, 1))', FormatHint.none),
      ('=DAYS(2, 1)', FormatHint.none),
    ];
    for (final (f, want) in hints) {
      test('when evaluating $f then the format hint is ${want.code}', () {
        final v = t.eval(f);

        expect((v as FNumber).hint.code, want.code);
      });
    }
  });
}
