import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/src/drive/template_gallery.dart' show TemplateStrip;
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

  group('Given the left menu (T-12)', () {
    const footerHidden = [
      'home.footer.appSettings',
      'home.footer.contribute',
      'home.footer.suggest',
    ];

    for (final (name, app, scope) in [
      ('Wonky Drive', WonkyAppKind.drive, const HomeScope.all()),
      (
        'the Write home',
        WonkyAppKind.write,
        const HomeScope.kind(DriveItemKind.document),
      ),
    ]) {
      testWidgets('when it opens on a phone in $name then Settings, '
          'Contribute & build and Suggest an improvement are hidden, Report '
          'a bug stays and every row is a 48 px touch target', (tester) async {
        h = harness(app, scope);
        seed();
        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.myDrive(),
          ),
          size: const Size(390, 844),
        );
        await tester.tap(key('shell.topBar.menu'));
        await tester.pumpAndSettle();

        expect(key('home.drawer'), findsOneWidget);
        for (final k in footerHidden) {
          expect(key(k), findsNothing, reason: k);
        }
        expect(key('home.footer.reportBug'), findsOneWidget);
        expect(key('home.storage'), findsOneWidget);
        final rows = [
          for (final item in h.services.config.homeNav.items)
            'drive.nav.${item.destination.name}',
          for (final a in WonkyAppKind.values) 'home.app.${a.name}',
          'home.footer.reportBug',
        ];
        for (final k in rows) {
          expect(
            tester.getSize(key(k)).height,
            greaterThanOrEqualTo(SidebarNavButton.mobileHeight),
            reason: k,
          );
        }
        expect(tester.takeException(), isNull);

        // Report a bug still opens the report dialog.
        await tester.ensureVisible(key('home.footer.reportBug'));
        await tester.tap(key('home.footer.reportBug'));
        await tester.pumpAndSettle();
        expect(key('dialog.board.report'), findsOneWidget);
        await tester.tap(find.text('Cancel').last);
        await tester.pumpAndSettle();
        await settleTooltips(tester);
      });

      testWidgets('when it shows on a desktop in $name then every entry and '
          'the 36 px rows are unchanged', (tester) async {
        h = harness(app, scope);
        seed();
        await pumpScreen(
          tester,
          h,
          DriveHomeScreen(
            services: h.services,
            location: const DriveLocation.myDrive(),
          ),
        );

        expect(key('home.sidebar'), findsOneWidget);
        for (final k in [...footerHidden, 'home.footer.reportBug']) {
          expect(key(k), findsOneWidget, reason: k);
        }
        final first = h.services.config.homeNav.items.first.destination.name;
        expect(tester.getSize(key('drive.nav.$first')).height, 36);
        expect(tester.getSize(key('home.app.drive')).height, 32);
        await settleTooltips(tester);
      });
    }
  });

  group('Given an app home (T-12)', () {
    const writeHome = HomeScope.kind(DriveItemKind.document);

    testWidgets('when it shows on a phone then there is no "Start a new '
        'document" strip and no grid/list toggle, and a desktop shows both', (
      tester,
    ) async {
      h = harness(WonkyAppKind.write, writeHome);
      seed();
      Widget home() => DriveHomeScreen(
        services: h.services,
        location: const DriveLocation.myDrive(),
      );
      await pumpScreen(tester, h, home(), size: const Size(390, 844));

      expect(find.byType(TemplateStrip), findsNothing);
      expect(key('drive.layout'), findsNothing);
      expect(find.text('Plan'), findsOneWidget);
      await settleTooltips(tester);

      await pumpScreen(tester, h, home());
      expect(find.byType(TemplateStrip), findsOneWidget);
      expect(key('drive.layout'), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when grid was chosen on a desktop then a phone still lists '
        'the files, and the grid returns on a wide window', (tester) async {
      h = harness(WonkyAppKind.write, writeHome);
      final plan = h.drive.seed(name: 'Plan');
      final item = 'drive.item.${plan.uuid.uuid}';
      final card = 'drive.card.${plan.uuid.uuid}';
      Widget home() => DriveHomeScreen(
        services: h.services,
        location: const DriveLocation.myDrive(),
      );
      await pumpScreen(tester, h, home());
      await tester.tap(key('drive.layout'));
      await tester.pumpAndSettle();
      expect(key(card), findsOneWidget);

      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(key(item), findsOneWidget);
      expect(key(card), findsNothing);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      expect(key(card), findsOneWidget);
      await settleTooltips(tester);
    });
  });
}
