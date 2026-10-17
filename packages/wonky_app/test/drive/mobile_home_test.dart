import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

import '../board/report/support/report_fakes.dart' show FakeReportBoard;
import '../support/screen_pump.dart';

/// Wonky Drive and the app homes on a phone (suite 02 §6.1, 05 §3): the
/// left menu is a drawer and the file list shows the files (name and ⋮),
/// in light and dark, without overflow; one tap opens a file.
void main() {
  late CommandTestHarness h;

  const phone = Size(360, 740);

  CommandTestHarness harness(WonkyAppKind app, HomeScope scope) {
    final harness = CommandTestHarness(
      config: TestAppConfig(app: app, scope: scope),
      board: FakeReportBoard(),
    );
    harness.services.router = GoRouter(
      routes: [
        for (final p in const [
          '/',
          '/my-drive',
          '/my-files',
          '/shared',
          '/starred',
          '/recent',
          '/offline',
          '/trash',
          '/storage',
          '/templates',
          '/f/:uuid',
          '/d/:uuid',
          '/s/:uuid',
          '/p/:uuid',
        ])
          GoRoute(path: p, builder: (_, _) => const SizedBox()),
      ],
    );
    return harness;
  }

  /// One item of every kind and a folder with a document.
  void seed() {
    h.drive.seed(name: 'Plan');
    h.drive.seed(name: 'Budget', kind: DriveItemKind.spreadsheet);
    h.drive.seed(name: 'Pitch', kind: DriveItemKind.presentation);
    final docs = h.drive.seed(name: 'Docs', kind: DriveItemKind.folder);
    h.drive.seed(name: 'Notes', parentUuid: docs.uuid);
  }

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  String routerPath() =>
      h.services.router.routeInformationProvider.value.uri.toString();

  tearDown(() => h.dispose());

  for (final (name, app, scope, shown, hidden) in [
    (
      'Wonky Drive',
      WonkyAppKind.drive,
      const HomeScope.all(),
      ['Plan', 'Budget', 'Pitch', 'Docs'],
      <String>[],
    ),
    (
      'the Write home',
      WonkyAppKind.write,
      const HomeScope.kind(DriveItemKind.document),
      ['Plan', 'Docs'],
      ['Budget', 'Pitch'],
    ),
    (
      'the Sheets home',
      WonkyAppKind.sheets,
      const HomeScope.kind(DriveItemKind.spreadsheet),
      ['Budget'],
      ['Plan', 'Pitch', 'Docs'],
    ),
    (
      'the Slides home',
      WonkyAppKind.slides,
      const HomeScope.kind(DriveItemKind.presentation),
      ['Pitch'],
      ['Plan', 'Budget', 'Docs'],
    ),
  ]) {
    for (final b in Brightness.values) {
      testWidgets('Given $name on a 360 px phone in ${b.name} when My files '
          'shows then the file list lists its files without overflow', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        h = harness(app, scope);
        seed();
        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.myDrive(),
          ),
          size: phone,
          brightness: b,
        );

        // The left menu is behind the menu button.
        expect(key('home.sidebar'), findsNothing);
        expect(key('shell.topBar.menu'), findsOneWidget);
        for (final n in shown) {
          expect(find.text(n), findsOneWidget, reason: n);
        }
        for (final n in hidden) {
          expect(find.text(n), findsNothing, reason: n);
        }
        for (final n in shown) {
          final r = tester.getRect(find.text(n));
          expect(r.left, greaterThanOrEqualTo(0), reason: n);
          expect(r.right, lessThanOrEqualTo(phone.width), reason: n);
        }
        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
        semantics.dispose();
        await settleTooltips(tester);
      });
    }
  }

  testWidgets('Given the Write home on a phone when a document is tapped '
      'once then it opens', (tester) async {
    h = harness(
      WonkyAppKind.write,
      const HomeScope.kind(DriveItemKind.document),
    );
    final plan = h.drive.seed(name: 'Plan');
    await pumpScreen(
      tester,
      h,
      DriveHomeScreen(
        services: h.services,
        location: const DriveLocation.myDrive(),
      ),
      size: phone,
    );

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    expect(routerPath(), '/d/${plan.uuid.uuid}');
    await settleTooltips(tester);
  });

  testWidgets('Given the Write home on a desktop when a document is clicked '
      'once then it is only selected (the desktop is unchanged)', (
    tester,
  ) async {
    h = harness(
      WonkyAppKind.write,
      const HomeScope.kind(DriveItemKind.document),
    );
    seed();
    await pumpScreen(
      tester,
      h,
      DriveHomeScreen(
        services: h.services,
        location: const DriveLocation.myDrive(),
      ),
    );

    await tester.tap(find.text('Plan'));
    await tester.pump(const Duration(seconds: 1));

    expect(routerPath(), '/');
    await settleTooltips(tester);
  });
}
