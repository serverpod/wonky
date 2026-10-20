import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_drive/features/analytics/analytics_controller.dart';

/// The pure helpers of the Analytics page (specs/19 §3): routes and the
/// bucketing of the bar charts.
void main() {
  group('Given the analytics route', () {
    for (final (days, admins, path) in [
      (30, false, '/analytics'),
      (90, false, '/analytics?days=90'),
      (30, true, '/analytics?admins=1'),
      (7, true, '/analytics?days=7&admins=1'),
    ]) {
      test('when building $days days, admins $admins then it is $path', () {
        expect(analyticsPath(days: days, admins: admins), path);
      });
    }

    for (final (raw, days) in [
      (null, 30),
      ('365', 365),
      ('14', 30),
      ('x', 30),
    ]) {
      test('when parsing "$raw" then the period is $days days', () {
        expect(parseAnalyticsDays(raw), days);
      });
    }
  });

  group('Given 10 daily values', () {
    final values = [for (var i = 1; i <= 10; i++) i];
    final days = [for (var i = 0; i < 10; i++) DateTime.utc(2026, 10, 11 + i)];

    test('when bucketing by 1 then nothing changes', () {
      expect(bucketSums(values, 1), [for (final v in values) v.toDouble()]);
    });

    test('when bucketing by 7 then the last bucket ends today and the '
        'first is the short one', () {
      expect(bucketSums(values, 7), [1 + 2 + 3.0, 4 + 5 + 6 + 7 + 8 + 9 + 10]);
      expect(bucketStarts(days, 7), [days[0], days[3]]);
    });
  });

  test('when choosing bar sizes then up to 90 days are daily and 365 '
      'weekly', () {
    expect([for (final d in analyticsPeriods) bucketSizeOf(d)], [1, 1, 1, 7]);
  });
}
