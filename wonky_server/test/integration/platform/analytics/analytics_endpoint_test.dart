@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/activity/activity_service.dart';
import 'package:wonky_server/src/platform/analytics/analytics_service.dart';
import 'package:wonky_server/src/platform/analytics/usage_tracker.dart';
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/board/board_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

Matcher _wonky(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

var _window = 0;

/// Usage analytics (specs/19): tracking and the admin overview.
///
/// The test database is shared by test files running in parallel and kept
/// between runs. Every test therefore works in a 500-day window of its own
/// in the far future (no other test writes there) under a fixed clock, and
/// clears that window first: it deletes the window's activity, rollup and
/// counter rows and moves sign-ups, events, comments, shares and AI usage
/// left there by earlier runs to the year 2000. People are created with the
/// real clock (unique emails), then signed up inside the window.
void main() {
  withWonkyServerpod('Given usage analytics', (sessionBuilder, endpoints) {
    late DateTime noon;

    Future<void> clearWindow() async {
      final session = sessionBuilder.build();
      final from = noon.subtract(const Duration(days: 450));
      final to = noon.add(const Duration(days: 30));
      for (final table in [
        'user_activity_day',
        'usage_day_stats',
        'usage_counter_day',
      ]) {
        await session.db.unsafeExecute(
          'DELETE FROM $table WHERE day >= @from AND day < @to',
          parameters: QueryParameters.named({'from': from, 'to': to}),
        );
      }
      for (final (table, column) in [
        ('user_profile', 'createdAt'),
        ('activity_event', 'at'),
        ('comment', 'createdAt'),
        ('drive_item_permission', 'grantedAt'),
        ('ai_usage', 'at'),
      ]) {
        await session.db.unsafeExecute(
          'UPDATE $table SET "$column" = @old '
          'WHERE "$column" >= @from AND "$column" < @to',
          parameters: QueryParameters.named({
            'from': from,
            'to': to,
            'old': DateTime.utc(2000),
          }),
        );
      }
    }

    setUp(() async {
      _window++;
      noon = DateTime.utc(2300, 1, 1, 12).add(Duration(days: 500 * _window));
      UsageTracker.reset();
      await clearWindow();
      await AnalyticsService.clearCache(sessionBuilder.build());
    });

    /// Runs [body] at [noon] plus [days].
    Future<T> at<T>(Future<T> Function() body, {int days = 0}) =>
        withClock(Clock.fixed(noon.add(Duration(days: days))), body);

    /// A person (an admin with [admin]) who signed up at [noon] plus
    /// [days].
    Future<TestUser> person(
      String name, {
      bool admin = false,
      int days = 0,
    }) async {
      final user = admin
          ? await BoardHarness.admin(sessionBuilder, name: name)
          : await TestUsers.create(sessionBuilder, name: name);
      await sessionBuilder.build().db.unsafeExecute(
        'UPDATE user_profile SET "createdAt" = @at WHERE id = @id',
        parameters: QueryParameters.named({
          'at': noon.add(Duration(days: days)),
          'id': user.id,
        }),
      );
      return user;
    }

    Future<AnalyticsOverview> overview(
      TestUser admin, {
      int days = 30,
      bool includeAdmins = false,
    }) async {
      await AnalyticsService.clearCache(sessionBuilder.build());
      return at(
        () => endpoints.analytics.overview(
          admin.endpointSession,
          days,
          includeAdmins,
        ),
      );
    }

    group('when the caller is not an admin', () {
      test('then the overview is forbidden', () async {
        final anna = await person('Anna');

        await expectLater(
          endpoints.analytics.overview(anna.endpointSession, 30, false),
          _wonky(WonkyErrorCode.forbidden),
        );
      });
    });

    test('when an unsupported period is asked then it is invalid', () async {
      final admin = await person('Admin', admin: true);

      await expectLater(
        endpoints.analytics.overview(admin.endpointSession, 14, false),
        _wonky(WonkyErrorCode.invalidArgument),
      );
    });

    test('when two people ping their apps then today has two active users '
        'by app and admins are left out', () async {
      final (anna, bo, admin) = (
        await person('Anna'),
        await person('Bo'),
        await person('Admin', admin: true),
      );
      await at(() async {
        await endpoints.analytics.ping(anna.endpointSession, UsageApp.write);
        await endpoints.analytics.ping(anna.endpointSession, UsageApp.write);
        await endpoints.analytics.ping(bo.endpointSession, UsageApp.sheets);
        await endpoints.analytics.ping(admin.endpointSession, UsageApp.drive);
      });

      final o = await overview(admin);

      expect(o.activeToday, 2);
      expect(o.series.last.write, 1);
      expect(o.series.last.sheets, 1);
      expect(o.series.last.drive, 0);
      expect(o.newAccounts, 2);
      expect(o.series.last.signups, 2);
    });

    test('when admins are included then their activity counts', () async {
      final admin = await person('Admin', admin: true);
      await at(
        () => endpoints.analytics.ping(admin.endpointSession, UsageApp.drive),
      );

      final o = await overview(admin, includeAdmins: true);

      expect(o.activeToday, 1);
      expect(o.series.last.drive, 1);
      expect(o.newAccounts, 1);
    });

    test('when someone creates a document then they are an editor and the '
        'document is counted, the welcome content is not', () async {
      final (anna, admin) = (
        await person('Anna'),
        await person('Admin', admin: true),
      );
      await at(() async {
        await endpoints.user.getMe(anna.endpointSession); // welcome content
        await TestDrive.document(endpoints, anna, name: 'Plan');
      });

      final o = await overview(admin);

      expect(o.series.last.editors, 1);
      expect(o.series.last.write, 1);
      expect(o.series.last.documents, 1);
      expect(o.series.last.spreadsheets, 0);
    });

    test('when someone was active 10 days ago then they count for the month '
        'but not the week', () async {
      final (anna, admin) = (
        await person('Anna', days: -20),
        await person('Admin', admin: true, days: -20),
      );
      await at(
        () => endpoints.analytics.ping(anna.endpointSession, UsageApp.slides),
        days: -10,
      );

      final o = await overview(admin);

      expect(o.activeToday, 0);
      expect(o.weekly, 0);
      expect(o.monthly, 1);
      expect(o.series[o.series.length - 11].active, 1);
      expect(o.series[o.series.length - 11].slides, 1);
    });

    test('when an MCP client calls tools then the calls and the MCP user '
        'are counted', () async {
      final (anna, admin) = (
        await person('Anna'),
        await person('Admin', admin: true),
      );
      final session = sessionBuilder.build();
      await at(() async {
        await UsageTracker.mcpCall(session, anna.id);
        await UsageTracker.mcpCall(session, anna.id);
      });

      final o = await overview(admin);

      expect(o.series.last.mcp, 1);
      expect(o.series.last.mcpCalls, 2);
    });

    test('when an item is shared then the share and the shared item are '
        'counted', () async {
      final (anna, bo, admin) = (
        await person('Anna'),
        await person('Bo'),
        await person('Admin', admin: true),
      );
      await at(() async {
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
      });

      final o = await overview(admin);

      expect(o.series.last.shares, 1);
    });

    test('when an account signs up and is active in its first week then its '
        'cohort shows it in week 0', () async {
      final (anna, admin) = (
        await person('Anna'),
        await person('Admin', admin: true),
      );
      await at(
        () => endpoints.analytics.ping(anna.endpointSession, UsageApp.write),
      );

      final o = await overview(admin);

      final cohort = o.cohorts.last;
      expect(cohort.week, AnalyticsService.weekOf(noon));
      expect(cohort.size, 1);
      expect(cohort.active, [1]);
    });

    test('when a finished day was computed once then later reads come from '
        'the rollup and today stays live', () async {
      final (anna, bo, admin) = (
        await person('Anna', days: -5),
        await person('Bo', days: -5),
        await person('Admin', admin: true, days: -5),
      );
      await at(
        () => endpoints.analytics.ping(anna.endpointSession, UsageApp.write),
        days: -2,
      );
      await overview(admin);
      // A row for the finished day that the rollup must not pick up again.
      final session = sessionBuilder.build();
      await UserActivityDay.db.insertRow(
        session,
        UserActivityDay(
          userId: bo.id,
          day: ActivityService.dayOf(noon.subtract(const Duration(days: 2))),
          app: UsageApp.write,
        ),
      );
      await at(
        () => endpoints.analytics.ping(bo.endpointSession, UsageApp.sheets),
      );

      final o = await overview(admin);

      expect(o.series[o.series.length - 3].active, 1);
      expect(o.activeToday, 1);
      final stored = await UsageDayStats.db.find(
        session,
        where: (t) =>
            t.day.equals(
              ActivityService.dayOf(noon.subtract(const Duration(days: 2))),
            ) &
            t.includeAdmins.equals(false),
      );
      expect(stored.single.write, 1);
    });

    test('when the purge runs then activity older than 400 days is '
        'deleted', () async {
      final anna = await person('Anna');
      final session = sessionBuilder.build();
      await at(
        () => UsageTracker.active(session, anna.id, UsageApp.write),
        days: -401,
      );
      await at(() => UsageTracker.active(session, anna.id, UsageApp.write));

      await at(() => UsageTracker.purge(session));

      final rows = await UserActivityDay.db.find(
        session,
        where: (t) => t.userId.equals(anna.id),
      );
      expect(rows, hasLength(1));
    });

    test('when a script edits an item then nobody becomes active', () async {
      final (anna, admin) = (
        await person('Anna'),
        await person('Admin', admin: true),
      );
      final doc = await at(() => TestDrive.document(endpoints, anna));
      UsageTracker.reset();
      final session = sessionBuilder.build();
      final item = await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(doc.uuid),
      );
      await at(
        () => UsageTracker.edited(
          session,
          Actor(
            userId: anna.id,
            authUserId: anna.authUserId,
            kind: ActorKind.script,
          ),
          item!.id!,
        ),
        days: 1,
      );

      final o = await at(
        () => endpoints.analytics.overview(admin.endpointSession, 7, false),
        days: 1,
      );

      expect(o.series.last.active, 0);
    });
  });
}
