import 'package:wonky_app/testing.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/features/analytics/analytics_api.dart';
import 'package:wonky_drive/features/analytics/analytics_controller.dart';

import 'storage_fakes.dart';

/// The last day of the fake analytics (UTC).
final analyticsToday = DateTime.utc(2026, 10, 20);

/// A deterministic overview of [days] days: activity that grows towards
/// today, every measure non-zero somewhere.
AnalyticsOverview fakeOverview(int days, {bool includeAdmins = false}) {
  final series = [
    for (var i = 0; i < days; i++)
      () {
        final day = analyticsToday.subtract(Duration(days: days - 1 - i));
        final base = 10 + i % 7 + i ~/ 3;
        return AnalyticsDay(
          day: day,
          active: base,
          editors: base ~/ 2,
          weekly: base * 3,
          monthly: base * 6,
          drive: base ~/ 2,
          write: base ~/ 3,
          sheets: base ~/ 4,
          slides: base ~/ 5,
          mcp: i % 3,
          signups: i % 4,
          accounts: 100 + i,
          documents: i % 5,
          spreadsheets: i % 3,
          presentations: i % 2,
          files: i % 4,
          folders: 0,
          comments: i % 6,
          shares: i % 3,
          aiRequests: 2 * (i % 5),
          aiTokens: 1500 * (i % 5),
          mcpCalls: 7 * (i % 3),
        );
      }(),
  ];
  return AnalyticsOverview(
    days: days,
    includeAdmins: includeAdmins,
    generatedAt: analyticsToday.add(const Duration(hours: 9)),
    trackingSince: analyticsToday.subtract(const Duration(days: 400)),
    accounts: 100 + days - 1,
    newAccounts: days,
    activeToday: series.last.active,
    weekly: series.last.weekly,
    monthly: series.last.monthly,
    stickiness: 0.27,
    series: series,
    itemTotals: [
      AnalyticsCount(key: 'document', count: 420, amount: 12 * mb),
      AnalyticsCount(key: 'spreadsheet', count: 180, amount: 30 * mb),
      AnalyticsCount(key: 'presentation', count: 40, amount: 8 * mb),
      AnalyticsCount(key: 'file', count: 95, amount: 200 * mb),
    ],
    storageBytes: 250 * mb,
    signInMethods: [
      AnalyticsCount(key: 'email', count: 70),
      AnalyticsCount(key: 'google', count: 52),
    ],
    aiFeatures: [
      AnalyticsCount(key: 'chat', count: 120, amount: 400000),
      AnalyticsCount(key: 'proofread', count: 30, amount: 90000),
    ],
    aiModels: [
      AnalyticsCount(key: 'gemini-3.1-pro', count: 100, amount: 380000),
      AnalyticsCount(key: 'gemini-3.8-flash', count: 50, amount: 110000),
    ],
    aiRetentionDays: 90,
    sharedItems: 64,
    coEditedItems: 12,
    commenters: 9,
    cohorts: [
      for (var w = 0; w < 12; w++)
        AnalyticsCohort(
          week: analyticsToday.subtract(Duration(days: 7 * (11 - w) + 1)),
          size: 10 + w,
          active: [for (var k = 0; k < 12 - w; k++) (10 + w) * (12 - k) ~/ 13],
        ),
    ],
  );
}

/// [AnalyticsApi] over [fakeOverview]; records the requests and fails with
/// [failWith].
class FakeAnalyticsApi implements AnalyticsApi {
  final List<(int, bool)> overviewRequests = [];
  Object? failWith;

  @override
  Future<AnalyticsOverview> overview(
    int days, {
    required bool includeAdmins,
  }) async {
    overviewRequests.add((days, includeAdmins));
    final e = failWith;
    if (e != null) throw e;
    return fakeOverview(days, includeAdmins: includeAdmins);
  }
}

/// The Storage testbed (Drive frame, router, harness) with a
/// [FakeAnalyticsApi] and a board whose caller is an admin or not.
class AnalyticsTestbed extends StorageTestbed {
  AnalyticsTestbed({bool admin = true})
    : this._(FakeBoardRepository(isAdmin: admin));

  AnalyticsTestbed._(this.board) : super(board: board) {
    AnalyticsHost.of(services).api = analytics;
  }

  final FakeBoardRepository board;
  final FakeAnalyticsApi analytics = FakeAnalyticsApi();
}
