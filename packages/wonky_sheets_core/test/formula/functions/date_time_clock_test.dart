import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Seconds as a fraction of a day.
double _t(int h, int m, num s) => (h * 3600 + m * 60 + s) / 86400;

/// Evaluates [formula] in a workbook whose spreadsheet time zone is [timeZone], with the engine
/// clock fixed at [now] and the bundled IANA time zone database.
FValue _evalIn(String timeZone, DateTime now, String formula) {
  final workbook = MemoryWorkbook(settings: CalcSettings(timeZone: timeZone));
  final sheet = workbook.addSheet('Sheet1', rows: 10, cols: 5);
  final engine = FormulaEngine(
    workbook: workbook,
    clock: FixedEngineClock(now),
    timeZones: const TzDatabaseResolver(),
  );
  return engine.evaluate(formula, sheetId: sheet.id, row: 0, col: 0);
}

void main() {
  // 2026-10-12 14:30:15 UTC = serial 46307 + 14:30:15.
  final now = DateTime.utc(2026, 10, 12, 14, 30, 15);

  group('Given NOW and TODAY in a spreadsheet time zone', () {
    final cases = <(String, String, double)>[
      ('UTC', '=NOW()', 46307 + _t(14, 30, 15)),
      ('America/New_York', '=NOW()', 46307 + _t(10, 30, 15)),
      ('Asia/Tokyo', '=NOW()', 46307 + _t(23, 30, 15)),
      ('Asia/Kolkata', '=NOW()', 46307 + _t(20, 0, 15)),
      ('Pacific/Auckland', '=NOW()', 46308 + _t(3, 30, 15)),
      ('Pacific/Auckland', '=TODAY()', 46308),
      ('America/Los_Angeles', '=TODAY()', 46307),
      ('Pacific/Honolulu', '=HOUR(NOW())', 4),
    ];
    for (final (tz, f, want) in cases) {
      test('when evaluating $f in $tz then it returns $want', () {
        final v = _evalIn(tz, now, f);

        expect(
          v,
          isA<FNumber>().having((n) => n.v, 'value', closeTo(want, 1e-9)),
        );
      });
    }
  });

  group('Given NOW across a daylight saving change in Europe/Berlin', () {
    final cases = <(DateTime, double)>[
      // 2026-03-29 00:30 UTC is 01:30 CET; 01:30 UTC is 03:30 CEST.
      (DateTime.utc(2026, 3, 29, 0, 30), 46110 + _t(1, 30, 0)),
      (DateTime.utc(2026, 3, 29, 1, 30), 46110 + _t(3, 30, 0)),
    ];
    for (final (instant, want) in cases) {
      test('when the clock is $instant then NOW returns $want', () {
        final v = _evalIn('Europe/Berlin', instant, '=NOW()');

        expect(
          v,
          isA<FNumber>().having((n) => n.v, 'value', closeTo(want, 1e-9)),
        );
      });
    }
  });

  group('Given a cell with NOW() and the clock advancing', () {
    final t = FormulaTestBench(now: now);
    t.set('A1', '=NOW()');
    t.set('A2', '=TODAY()');
    final before = t.value('A1');
    t.clock.instant = DateTime.utc(2026, 10, 13, 8, 0, 0);
    t.set('B1', 1);

    test('when another cell changes then NOW is recomputed', () {
      expect(before, const FNumber(46307 + (14 * 3600 + 30 * 60 + 15) / 86400));
      expect(
        t.value('A1'),
        isA<FNumber>().having(
          (n) => n.v,
          'value',
          closeTo(46308 + 8 / 24, 1e-9),
        ),
      );
    });

    test('when another cell changes then TODAY is recomputed', () {
      expect(t.value('A2'), const FNumber(46308));
    });
  });
}
