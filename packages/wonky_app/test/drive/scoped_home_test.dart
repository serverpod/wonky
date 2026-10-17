import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/src/board/report/board_report_dialog.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/testing.dart';

import '../board/report/support/report_fakes.dart' show FakeReportBoard;
import '../support/screen_pump.dart';

/// Scope-aware homes and the left menu (D-10; suite 03 §3.3, Drive 04 §2):
/// Wonky Drive (`HomeScope.all`), an app home after D-16's one-line flip
/// (`HomeScope.kind`) and the v1 home (`homeScope` null).
void main() {
  late CommandTestHarness h;

  const writeHome = HomeScope.kind(DriveItemKind.document);

  CommandTestHarness harness({
    WonkyAppKind app = WonkyAppKind.write,
    HomeScope? scope,
    StorageController? storage,
  }) {
    final harness = CommandTestHarness(
      config: TestAppConfig(app: app, scope: scope),
      storage: storage,
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
          '/f/:uuid',
          '/d/:uuid',
          '/templates',
          '/settings/app',
          '/settings/:section',
        ])
          GoRoute(path: p, builder: (_, _) => const SizedBox()),
      ],
    );
    return harness;
  }

  /// My files with a document, a spreadsheet, a presentation, an uploaded
  /// image, a folder with a document (nested), a folder with only a
  /// spreadsheet and an empty folder.
  void seed() {
    h.drive.seed(name: 'Plan');
    h.drive.seed(name: 'Budget', kind: DriveItemKind.spreadsheet);
    h.drive.seed(name: 'Pitch', kind: DriveItemKind.presentation);
    h.drive.seed(
      name: 'photo.png',
      kind: DriveItemKind.file,
      fileCategory: FileCategory.image,
    );
    final docs = h.drive.seed(name: 'Docs', kind: DriveItemKind.folder);
    final inner = h.drive.seed(
      name: 'Inner',
      kind: DriveItemKind.folder,
      parentUuid: docs.uuid,
    );
    h.drive.seed(name: 'Notes', parentUuid: inner.uuid);
    final numbers = h.drive.seed(name: 'Numbers', kind: DriveItemKind.folder);
    h.drive.seed(
      name: 'Q3',
      kind: DriveItemKind.spreadsheet,
      parentUuid: numbers.uuid,
    );
    h.drive.seed(name: 'Empty', kind: DriveItemKind.folder);
  }

  Widget home([DriveLocation location = const DriveLocation.myDrive()]) =>
      DriveHomeScreen(services: h.services, location: location);

  Finder key(String k) => find.byKey(ValueKey<String>(k));

  String routerPath() =>
      h.services.router.routeInformationProvider.value.uri.toString();

  tearDown(() => h.dispose());

  group('Given an app home (Write after the D-16 flip)', () {
    setUp(() {
      h = harness(scope: writeHome);
      seed();
    });

    testWidgets('when My files shows then only documents and the folders '
        'containing documents are listed', (tester) async {
      await pumpScreen(tester, h, home());

      expect(find.text('Plan'), findsOneWidget);
      expect(find.text('Docs'), findsOneWidget);
      for (final hidden in [
        'Budget',
        'Pitch',
        'photo.png',
        'Numbers',
        'Empty',
      ]) {
        expect(find.text(hidden), findsNothing, reason: hidden);
      }
      expect(key('drive.filter.type'), findsNothing);
      expect(find.text('My files'), findsWidgets);
      await settleTooltips(tester);
    });

    testWidgets('when the left menu shows then it has the four apps, the '
        'app-home navigation and the bottom section', (tester) async {
      await pumpScreen(tester, h, home());

      for (final app in WonkyAppKind.values) {
        expect(key('home.app.${app.name}'), findsOneWidget);
        expect(find.text(app.shortName), findsOneWidget);
      }
      // Drive, a divider, then Write, Sheets and Slides from top to bottom.
      final ys = [
        for (final app in WonkyAppKind.values)
          tester.getTopLeft(key('home.app.${app.name}')).dy,
      ];
      expect(ys, [...ys]..sort());
      expect(WonkyAppKind.values.first, WonkyAppKind.drive);
      final divider = tester.getTopLeft(key('home.apps.divider')).dy;
      expect(divider, greaterThan(ys.first));
      expect(divider, lessThan(ys[1]));
      for (final d in [
        'recent',
        'myFiles',
        'shared',
        'starred',
        'offline',
        'trash',
      ]) {
        expect(key('drive.nav.$d'), findsOneWidget, reason: d);
      }
      expect(key('drive.nav.home'), findsNothing);
      expect(key('drive.nav.storage'), findsNothing);
      expect(key('drive.nav.tree'), findsNothing);
      expect(find.text('Write settings'), findsNothing);
      // The app's settings are just "Settings"; Wonky Work settings are
      // reached from there.
      expect(find.text('Test settings'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Wonky Work settings'), findsNothing);
      expect(key('home.footer.workSettings'), findsNothing);
      expect(key('home.footer.contribute'), findsOneWidget);
      expect(key('home.footer.board'), findsNothing);
      expect(key('home.footer.reportBug'), findsOneWidget);
      expect(key('home.footer.suggest'), findsOneWidget);
      // The current app is highlighted and not a button.
      expect(
        tester.getSemantics(key('home.app.write')),
        matchesSemantics(
          label: 'Write',
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      await settleTooltips(tester);
    });

    testWidgets('when tapping another app then it opens in the same tab', (
      tester,
    ) async {
      await pumpScreen(tester, h, home());

      await tester.tap(key('home.app.sheets'));
      await tester.pumpAndSettle();
      await tester.tap(key('home.app.write'));
      await tester.pumpAndSettle();

      expect(h.crossApp.opened, [(WonkyAppKind.sheets, '/')]);
      await settleTooltips(tester);
    });

    testWidgets('when the home shows then it has no + New (the template '
        'strip creates), also with the left menu collapsed', (tester) async {
      await pumpScreen(tester, h, home());

      expect(key('drive.new'), findsNothing);
      expect(key('drive.template.blank'), findsOneWidget);

      await tester.tap(key('shell.topBar.menu'));
      await tester.pumpAndSettle();

      expect(key('home.sidebar'), findsNothing);
      expect(key('drive.new.topBar'), findsNothing);
      await settleTooltips(tester);
    });

    test('when deciding on + New then only Drive and v1 homes have it', () {
      expect(showsSidebarNewButton(writeHome), isFalse);
      expect(showsSidebarNewButton(const HomeScope.all()), isTrue);
      expect(showsSidebarNewButton(null), isTrue);
    });

    testWidgets('when in a folder then Open in Wonky Drive shows that folder '
        'in Drive', (tester) async {
      final docs = h.drive.items.firstWhere((i) => i.name == 'Docs');
      await pumpScreen(tester, h, home(DriveLocation.folder(docs.uuid.uuid)));

      expect(find.text('Inner'), findsOneWidget);
      await tester.tap(key('drive.openInDrive'));
      await tester.pumpAndSettle();

      expect(h.crossApp.opened, [(WonkyAppKind.drive, '/f/${docs.uuid.uuid}')]);
      await settleTooltips(tester);
    });

    testWidgets('when / shows then it is called Recent', (tester) async {
      await pumpScreen(tester, h, home(const DriveLocation.home()));

      expect(find.text('Recent'), findsWidgets);
      expect(key('drive.templates.toggle'), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when tapping a menu destination then its route shows', (
      tester,
    ) async {
      await pumpScreen(tester, h, home(const DriveLocation.home()));

      await tester.tap(key('drive.nav.myFiles'));
      await tester.pumpAndSettle();

      expect(routerPath(), '/my-files');
      await settleTooltips(tester);
    });
  });

  group('Given Wonky Drive', () {
    setUp(() {
      h = harness(app: WonkyAppKind.drive, scope: const HomeScope.all());
      seed();
    });

    testWidgets('when My Drive shows then every kind and every folder is '
        'listed with the type filter', (tester) async {
      await pumpScreen(tester, h, home());

      for (final name in [
        'Plan',
        'Budget',
        'Pitch',
        'photo.png',
        'Docs',
        'Numbers',
        'Empty',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(key('drive.filter.type'), findsOneWidget);
      expect(key('drive.openInDrive'), findsNothing);
      expect(key('drive.templates.toggle'), findsNothing);
      await settleTooltips(tester);
    });

    testWidgets('when the left menu shows then it has Drive\'s navigation '
        'with the folder tree and Storage', (tester) async {
      await pumpScreen(tester, h, home());

      for (final d in [
        'home',
        'myFiles',
        'shared',
        'recent',
        'starred',
        'trash',
        'storage',
      ]) {
        expect(key('drive.nav.$d'), findsOneWidget, reason: d);
      }
      expect(key('drive.nav.offline'), findsNothing);
      expect(key('drive.nav.tree'), findsOneWidget);
      expect(find.text('My Drive'), findsWidgets);
      expect(
        tester.getSemantics(key('home.app.drive')),
        matchesSemantics(
          label: 'Drive',
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      await settleTooltips(tester);
    });

    testWidgets('when the left menu is collapsed then + New shows in the top '
        'bar before the search field', (tester) async {
      await pumpScreen(tester, h, home());
      expect(key('drive.new'), findsOneWidget);
      expect(key('drive.new.topBar'), findsNothing);

      await tester.tap(key('shell.topBar.menu'));
      await tester.pumpAndSettle();

      expect(key('drive.new'), findsNothing);
      expect(key('drive.new.topBar'), findsOneWidget);
      expect(
        tester.getTopLeft(key('drive.new.topBar')).dx,
        lessThan(tester.getTopLeft(key('drive.search')).dx),
      );
      await tester.tap(key('drive.new.topBar'));
      await tester.pumpAndSettle();
      expect(find.text('New folder'), findsOneWidget);
      expect(find.text('Presentation'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      await tester.tap(key('shell.topBar.menu'));
      await tester.pumpAndSettle();
      expect(key('drive.new.topBar'), findsNothing);
      await settleTooltips(tester);
    });

    testWidgets('when + New opens then it offers folders, uploads and every '
        'kind', (tester) async {
      await pumpScreen(tester, h, home());

      await tester.tap(key('drive.new'));
      await tester.pumpAndSettle();

      for (final t in [
        'New folder',
        'File upload',
        'Document',
        'Spreadsheet',
        'Presentation',
      ]) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      await tester.tap(find.text('Presentation'));
      await tester.pumpAndSettle();
      expect(h.crossApp.opened, [(WonkyAppKind.slides, '/new')]);
      await settleTooltips(tester);
    });

    test('when filtering Files ▸ Images then only images are listed', () async {
      final c = DriveController(
        services: h.services,
        location: const DriveLocation.myDrive(),
      );
      addTearDown(c.dispose);
      await c.reload();
      expect(c.typeFilter, DriveTypeFilter.all);
      expect(c.items.length, 7);

      c.setTypeFilter(DriveTypeFilter.files, category: FileCategory.image);
      await c.reload();

      expect(c.items.map((i) => i.name), ['photo.png']);
      c.setTypeFilter(DriveTypeFilter.presentations);
      await c.reload();
      expect(c.items.map((i) => i.name), ['Pitch']);
    });
  });

  group('Given the v1 home (homeScope null, Write until D-16)', () {
    setUp(() {
      h = harness();
      seed();
    });

    testWidgets('when My Drive shows then the v1 list, filter and tree are '
        'kept', (tester) async {
      await pumpScreen(tester, h, home());

      // v1: the primary kind plus every folder, behind the type filter.
      for (final name in ['Plan', 'Docs', 'Numbers', 'Empty']) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      expect(find.text('Budget'), findsNothing);
      expect(key('drive.filter.type'), findsOneWidget);
      expect(key('drive.nav.tree'), findsOneWidget);
      expect(key('drive.nav.home'), findsOneWidget);
      expect(key('drive.nav.offline'), findsOneWidget);
      expect(key('drive.openInDrive'), findsNothing);
      // The new left menu: apps and bottom section.
      expect(key('home.app.drive'), findsOneWidget);
      expect(key('home.footer.reportBug'), findsOneWidget);
      await settleTooltips(tester);
    });
  });

  group('Given the bottom section of the left menu', () {
    testWidgets('when the storage is known then the meter shows used of '
        'quota', (tester) async {
      h = harness(
        scope: writeHome,
        storage: FakeStorage.used((12.3 * 1024 * 1024).round()),
      );
      await pumpScreen(tester, h, home());

      expect(find.text('12.3 MB of 50 MB used'), findsOneWidget);
      await tester.tap(key('home.storage'));
      await tester.pumpAndSettle();
      expect(h.crossApp.opened, [(WonkyAppKind.drive, '/storage')]);
      await settleTooltips(tester);
    });

    for (final (id, icon, label, kind) in [
      (
        'home.footer.reportBug',
        LucideIcons.bug,
        'Report a bug',
        BoardPostKind.bug,
      ),
      (
        'home.footer.suggest',
        LucideIcons.leaf,
        'Suggest an improvement',
        BoardPostKind.idea,
      ),
    ]) {
      testWidgets('when pressing "$label" then the report dialog shows on '
          '${kind.name}', (tester) async {
        h = harness(scope: writeHome);
        await pumpScreen(tester, h, home());

        expect(
          find.descendant(of: key(id), matching: find.byIcon(icon)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: key(id), matching: find.text(label)),
          findsOneWidget,
        );
        await tester.tap(key(id));
        await tester.pumpAndSettle();

        expect(key('dialog.board.report'), findsOneWidget);
        expect(
          tester
              .state<BoardReportDialogState>(find.byType(BoardReportDialog))
              .draft
              .kind,
          kind,
        );
        expect(h.crossApp.external, isEmpty);
        await settleTooltips(tester);
      });
    }

    testWidgets('when opening Settings then the app settings show', (
      tester,
    ) async {
      h = harness(scope: writeHome);
      await pumpScreen(tester, h, home());

      await tester.tap(key('home.footer.appSettings'));
      await tester.pumpAndSettle();
      expect(routerPath(), '/settings/app');
      await settleTooltips(tester);
    });

    testWidgets('when pressing "Contribute & build" (wrench) then the board '
        'opens', (tester) async {
      h = harness(scope: writeHome);
      await pumpScreen(tester, h, home());

      final contribute = key('home.footer.contribute');
      expect(
        find.descendant(
          of: contribute,
          matching: find.text('Contribute & build'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: contribute,
          matching: find.byIcon(LucideIcons.wrench),
        ),
        findsOneWidget,
      );
      await tester.tap(key('home.footer.contribute'));
      await tester.pumpAndSettle();
      expect(routerPath(), '/improvements');
      await settleTooltips(tester);
    });
  });

  group('Given a folder opened from another home', () {
    testWidgets('when the previous home is disposed after the folder loaded '
        'then the current folder stays the opened one', (tester) async {
      // D-18: offline (instant cached reload) the previous home's dispose
      // at the end of the route transition reset `currentFolder`, and the
      // uploads of the folder went to My Drive.
      h = harness(scope: const HomeScope.all(), app: WonkyAppKind.drive);
      final folder = h.drive.seed(name: 'Holiday', kind: DriveItemKind.folder);
      Widget both({required bool previous}) => Stack(
        children: [
          if (previous)
            KeyedSubtree(key: const ValueKey('previous'), child: home()),
          KeyedSubtree(
            key: const ValueKey('folder'),
            child: home(DriveLocation.folder(folder.uuid.uuid)),
          ),
        ],
      );
      await pumpScreen(
        tester,
        h,
        Stack(
          children: [
            KeyedSubtree(key: const ValueKey('previous'), child: home()),
          ],
        ),
      );
      expect(h.services.currentFolder.value, isNull);

      // During the transition both homes are mounted …
      await pumpScreen(tester, h, both(previous: true));
      expect(h.services.currentFolder.value?.uuid, folder.uuid);
      // … then the previous one is disposed.
      await pumpScreen(tester, h, both(previous: false));

      expect(h.services.currentFolder.value?.uuid, folder.uuid);
      await settleTooltips(tester);
    });
  });

  group('Given a narrow window', () {
    testWidgets('when the list shows then it has Name and ⋮ only, and the '
        'wide list keeps every column', (tester) async {
      // Drive 04 §11 (D-18: at 400 px the columns squeezed the names).
      final l = lookupWonkyAppLocalizations(const Locale('en'));
      h = harness(scope: const HomeScope.all(), app: WonkyAppKind.drive);
      seed();
      await pumpScreen(tester, h, home(), size: const Size(400, 800));
      expect(find.text('Plan'), findsOneWidget);
      expect(find.text(l.columnOwner), findsNothing);
      expect(find.text(l.columnSize), findsNothing);
      expect(find.text(l.ownerMe), findsNothing);
      await settleTooltips(tester);

      await pumpScreen(tester, h, home(), size: const Size(1280, 800));
      expect(find.text(l.columnOwner), findsOneWidget);
      expect(find.text(l.columnSize), findsOneWidget);
      await settleTooltips(tester);
    });

    testWidgets('when New ▸ New folder is chosen in the drawer then the '
        'drawer closes and the dialog shows', (tester) async {
      // D-18: the drawer stayed open over the dialog and the upload panel.
      h = harness(scope: const HomeScope.all(), app: WonkyAppKind.drive);
      await pumpScreen(tester, h, home(), size: const Size(400, 800));
      await tester.tap(key('shell.topBar.menu'));
      await tester.pumpAndSettle();
      await tester.tap(key('drive.new'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('New folder').last);
      await tester.pumpAndSettle();

      expect(key('home.drawer'), findsNothing);
      expect(find.text('Folder name'), findsOneWidget);
      await tester.tap(find.text('Cancel').last);
      await tester.pumpAndSettle();
      await settleTooltips(tester);
    });

    testWidgets('when the menu button is pressed then the left menu opens '
        'as a drawer and closes on navigation', (tester) async {
      h = harness(scope: writeHome);
      seed();
      await pumpScreen(tester, h, home(), size: const Size(600, 800));

      expect(key('home.sidebar'), findsNothing);
      await tester.tap(key('shell.topBar.menu'));
      await tester.pumpAndSettle();
      expect(key('home.drawer'), findsOneWidget);
      expect(key('home.sidebar'), findsOneWidget);

      await tester.tap(key('drive.nav.starred'));
      await tester.pumpAndSettle();

      expect(key('home.drawer'), findsNothing);
      expect(routerPath(), '/starred');
      await settleTooltips(tester);
    });

    testWidgets('when "Report a bug" is pressed in the drawer then the '
        'drawer closes and the report dialog shows', (tester) async {
      h = harness(scope: writeHome);
      await pumpScreen(tester, h, home(), size: const Size(600, 800));
      await tester.tap(key('shell.topBar.menu'));
      await tester.pumpAndSettle();

      await tester.tap(key('home.footer.reportBug'));
      await tester.pumpAndSettle();

      expect(key('home.drawer'), findsNothing);
      expect(key('dialog.board.report'), findsOneWidget);
      await settleTooltips(tester);
    });

    for (final b in Brightness.values) {
      testWidgets('when the drawer shows at 360 px in ${b.name} then nothing '
          'overflows and it is accessible', (tester) async {
        final semantics = tester.ensureSemantics();
        h = harness(scope: writeHome);
        seed();
        await pumpScreen(
          tester,
          h,
          home(),
          size: const Size(360, 740),
          brightness: b,
          locale: pseudoLocale,
        );
        await tester.tap(key('shell.topBar.menu'));
        await tester.pumpAndSettle();

        expect(key('home.drawer'), findsOneWidget);
        await expectAccessible(tester);
        await settleTooltips(tester);
        semantics.dispose();
      });
    }
  });

  group('Given the left menu in light and dark', () {
    for (final b in Brightness.values) {
      for (final (name, app, scope) in [
        ('drive', WonkyAppKind.drive, const HomeScope.all()),
        ('write', WonkyAppKind.write, writeHome),
      ]) {
        testWidgets('when the $name home shows in ${b.name} then text has '
            'enough contrast and every tap target is labeled', (tester) async {
          final semantics = tester.ensureSemantics();
          h = harness(
            app: app,
            scope: scope,
            storage: FakeStorage.used(46 * 1024 * 1024),
          );
          seed();
          await pumpScreen(tester, h, home(), brightness: b);

          await expectAccessible(tester);
          semantics.dispose();
          await settleTooltips(tester);
        });
      }
    }
  });
}
