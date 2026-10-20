import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/l10n/drive_l10n.dart';

import '../../support/analytics_fakes.dart';

final l = driveL10nEnglish;

/// The Analytics page (specs/19 §3): admins only, the period and the
/// *Include admins* switch through `drive.analytics.show`, charts with
/// hover tooltips and table views, light/dark, 360 px and the
/// pseudo-locale.
void main() {
  Finder key(String k) => find.byKey(ValueKey<String>(k));

  /// Scrolls the page (not the left menu or a table) until [f] shows.
  Future<void> scrollTo(WidgetTester tester, Finder f, [double by = 200]) =>
      tester.scrollUntilVisible(
        f,
        by,
        scrollable: find
            .descendant(
              of: key('analytics.page'),
              matching: find.byType(Scrollable),
            )
            .first,
      );

  group('Given an admin', () {
    late AnalyticsTestbed t;

    setUp(() => t = AnalyticsTestbed());
    tearDown(() => t.dispose());

    testWidgets('when the Drive home opens then the left menu has '
        'Analytics', (tester) async {
      await t.pump(tester, location: '/');

      expect(key('drive.nav.analytics'), findsOneWidget);
    });

    testWidgets('when Analytics opens then it shows the headline numbers '
        'and the charts', (tester) async {
      await t.pump(tester, location: '/analytics');

      expect(t.analytics.overviewRequests, [(30, false)]);
      expect(find.text(l.analyticsTitle), findsWidgets);
      final o = fakeOverview(30);
      expect(
        find.descendant(
          of: key('analytics.kpi.today.value'),
          matching: find.text('${o.activeToday}'),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      for (final id in [
        'active',
        'apps',
        'signups',
        'content',
        'collaboration',
        'ai',
        'mcp',
        'retention',
      ]) {
        await scrollTo(tester, key('analytics.card.$id'), 200);
        expect(key('analytics.card.$id'), findsOneWidget, reason: id);
      }
    });

    testWidgets('when choosing 90 days then the route and the request '
        'follow', (tester) async {
      await t.pump(tester, location: '/analytics');

      await tester.tap(key('analytics.period.90'));
      await tester.pumpAndSettle();

      expect(t.location, '/analytics?days=90');
      expect(t.analytics.overviewRequests.last, (90, false));
    });

    testWidgets('when turning on Include admins then admins are '
        'counted', (tester) async {
      await t.pump(tester, location: '/analytics');

      await tester.tap(key('analytics.includeAdmins'));
      await tester.pumpAndSettle();

      expect(t.location, '/analytics?admins=1');
      expect(t.analytics.overviewRequests.last, (30, true));
    });

    testWidgets('when hovering the active users chart then a tooltip shows '
        'the day and the values', (tester) async {
      await t.pump(tester, location: '/analytics');
      final chart = key('analytics.chart.active.daily');
      final box = tester.getRect(chart);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: box.bottomRight - const Offset(8, 60));
      await mouse.moveTo(box.bottomRight - const Offset(7, 60));
      await tester.pump();

      expect(key('analytics.tooltip'), findsOneWidget);
      final today = fakeOverview(30).series.last;
      expect(
        find.descendant(
          of: key('analytics.tooltip'),
          matching: find.text('${today.active}'),
        ),
        findsOneWidget,
      );
      await mouse.removePointer();
    });

    testWidgets('when showing a chart as a table then the newest day comes '
        'first', (tester) async {
      await t.pump(tester, location: '/analytics');

      await tester.tap(key('analytics.card.active.table'));
      await tester.pumpAndSettle();

      expect(find.text(l.analyticsColDay), findsOneWidget);
      expect(find.text('Tue, Oct 20'), findsOneWidget);
    });

    testWidgets('when switching to Monthly then the chart shows monthly '
        'active users', (tester) async {
      await t.pump(tester, location: '/analytics');

      await tester.tap(key('analytics.active.view.monthly'));
      await tester.pumpAndSettle();

      expect(key('analytics.chart.active.monthly'), findsOneWidget);
    });

    for (final (name, brightness, size) in [
      ('dark', Brightness.dark, const Size(1280, 900)),
      ('360 px', Brightness.light, const Size(360, 800)),
    ]) {
      testWidgets('when shown $name then it lays out without '
          'errors', (tester) async {
        await t.pump(
          tester,
          location: '/analytics?days=365',
          brightness: brightness,
          size: size,
        );

        expect(key('analytics.card.active'), findsOneWidget);
        await scrollTo(tester, key('analytics.card.retention'), 300);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('when shown in the pseudo-locale then it lays out without '
        'errors', (tester) async {
      await t.pump(
        tester,
        location: '/analytics',
        locale: const Locale('en', 'XA'),
      );

      expect(key('analytics.card.active'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Given a person who is not an admin', () {
    late AnalyticsTestbed t;

    setUp(() {
      t = AnalyticsTestbed(admin: false);
      t.analytics.failWith = WonkyException(
        code: WonkyErrorCode.forbidden,
        message: 'Usage analytics are for admins.',
      );
    });
    tearDown(() => t.dispose());

    testWidgets('when the Drive home opens then the left menu has no '
        'Analytics', (tester) async {
      await t.pump(tester, location: '/');

      expect(key('drive.nav.analytics'), findsNothing);
      expect(key('drive.nav.storage'), findsOneWidget);
    });

    testWidgets('when /analytics is opened then it says analytics are for '
        'admins', (tester) async {
      await t.pump(tester, location: '/analytics');

      expect(key('analytics.forbidden'), findsOneWidget);
      expect(find.text(l.analyticsForbiddenTitle), findsOneWidget);
    });
  });
}
