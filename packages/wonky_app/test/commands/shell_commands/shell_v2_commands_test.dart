import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show CommandStatus, MenuRoot;

/// The shell commands of D-10 (suite 08 §5 v2): `shell.nav.openInDrive`,
/// `shell.settings.openApp`, `shell.storage.open`, `shell.help.reportBug`
/// (an alias of `shell.board.report`),
/// `shell.account.switchApp {app}` and `shell.file.new` across apps.
void main() {
  late CommandTestHarness h;

  CommandTestHarness harness({
    WonkyAppKind app = WonkyAppKind.write,
    HomeScope? scope,
  }) {
    final harness = CommandTestHarness(
      config: TestAppConfig(app: app, scope: scope),
    );
    harness.services.router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/storage', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/settings/app', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/settings/app/:section',
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );
    return harness;
  }

  String routerPath() =>
      h.services.router.routeInformationProvider.value.uri.toString();

  tearDown(() => h.dispose());

  group('Given an app home', () {
    setUp(
      () => h = harness(scope: const HomeScope.kind(DriveItemKind.document)),
    );

    test('when opening a folder in Drive then Drive shows that folder in the '
        'same tab', () async {
      final folder = h.drive.seed(name: 'Team', kind: DriveItemKind.folder);

      final r = await h.invoke('shell.nav.openInDrive', {
        'folderUuid': folder.uuid.uuid,
      });

      expect(r.isOk, isTrue);
      expect(h.crossApp.opened, [
        (WonkyAppKind.drive, '/f/${folder.uuid.uuid}'),
      ]);
    });

    test('when opening the current folder in Drive then its folder is '
        'used', () async {
      final folder = h.drive.seed(name: 'Team', kind: DriveItemKind.folder);
      h.services.currentFolder.value = folder;

      await h.invoke('shell.nav.openInDrive');

      expect(h.crossApp.opened.single.$2, '/f/${folder.uuid.uuid}');
    });

    test('when creating a spreadsheet then Sheets\' /new route creates it in '
        'the current folder', () async {
      final folder = h.drive.seed(name: 'Team', kind: DriveItemKind.folder);
      h.services.currentFolder.value = folder;

      final r = await h.invoke('shell.file.new', {'kind': 'spreadsheet'});

      expect(r.isOk, isTrue);
      expect(h.crossApp.opened, [
        (WonkyAppKind.sheets, '/new?folder=${folder.uuid.uuid}'),
      ]);
      expect(h.drive.calls, isEmpty, reason: 'Sheets creates it, not us');
    });

    test('when opening the app settings then /settings/app shows', () async {
      await h.invoke('shell.settings.openApp');
      expect(routerPath(), '/settings/app');

      await h.invoke('shell.settings.openApp', {'section': 'editing'});
      expect(routerPath(), '/settings/app/editing');
    });

    test('when managing storage then Drive\'s Storage page opens', () async {
      await h.invoke('shell.storage.open');
      expect(h.crossApp.opened, [(WonkyAppKind.drive, '/storage')]);
    });

    test('when switching to Slides then Slides\' home opens', () async {
      await h.invoke('shell.account.switchApp', {'app': 'slides'});
      expect(h.crossApp.opened, [(WonkyAppKind.slides, '/')]);
    });

    test('when switching to the current app then its home shows', () async {
      await h.invoke('shell.account.switchApp', {'app': 'write'});
      expect(h.crossApp.opened, isEmpty);
      expect(routerPath(), '/');
    });

    test('when reporting a bug without a window then nothing opens', () async {
      final r = await h.invoke('shell.help.reportBug');
      expect(r.status, CommandStatus.cancelled);
      expect(h.crossApp.external, isEmpty);
    });
  });

  group('Given Wonky Drive', () {
    setUp(
      () => h = harness(app: WonkyAppKind.drive, scope: const HomeScope.all()),
    );

    test(
      'when creating a presentation then Slides\' /new route opens',
      () async {
        await h.invoke('shell.file.new', {'kind': 'presentation'});
        expect(h.crossApp.opened, [(WonkyAppKind.slides, '/new')]);
      },
    );

    test('when creating without a kind then a document is created in '
        'Write', () async {
      await h.invoke('shell.file.new');
      expect(h.crossApp.opened, [(WonkyAppKind.write, '/new')]);
    });

    test(
      'when managing storage then the Storage page shows in place',
      () async {
        await h.invoke('shell.storage.open');
        expect(h.crossApp.opened, isEmpty);
        expect(routerPath(), '/storage');
      },
    );

    test('then Open in Wonky Drive is disabled', () {
      expect(
        h.services.dispatcher.stateOf('shell.nav.openInDrive').enabled,
        isFalse,
      );
    });
  });

  group('Given the shared Help menu', () {
    setUp(() => h = harness());

    test('then Report a bug and Suggest an improvement open the report '
        'dialog on their kind, What\'s new is gone, and the old ids stay '
        'registered', () async {
      final l = await WonkyAppLocalizations.delegate.load(const Locale('en'));
      final help = MenuRoot([ShellMenus(l).help]);
      final ids = [for (final c in help.commands) c.commandId];
      final report = [
        for (final c in help.commands)
          if (c.commandId == 'shell.board.report') (c.label, c.args['kind']),
      ];

      expect(report, [
        ('Report a bug', 'bug'),
        ('Suggest an improvement', 'idea'),
      ]);
      expect(
        ids,
        containsAllInOrder([
          'shell.board.report',
          'shell.board.report',
          'shell.board.open',
          'shell.help.about',
        ]),
      );
      expect(ids, isNot(contains('shell.help.whatsNew')));
      final report0 = h.services.registry.byId('shell.board.report')!;
      expect(report0.iconFor(const {'kind': 'idea'}), LucideIcons.leaf);
      expect(report0.iconFor(const {'kind': 'bug'}), LucideIcons.bug);
      expect(ids, isNot(contains('shell.help.reportBug')));
      expect(ids, isNot(contains('shell.help.feedback')));
      expect(h.services.registry.byId('shell.help.reportBug'), isNotNull);
      expect(h.services.registry.byId('shell.help.feedback'), isNotNull);
      expect(l.cmdBoardReport, 'Bugs & improvements…');
      expect(l.cmdBoardOpen, 'Browse Bugs & improvements');
    });
  });

  group('Given a new-item request', () {
    setUp(() => h = harness());

    test('when it has a folder and a template then the /new path carries '
        'both', () {
      final f = UuidValue.fromString('0190a0e0-0000-7000-8000-000000000001');
      final t = UuidValue.fromString('0190a0e0-0000-7000-8000-000000000002');
      final path = NewItemRequest(folderUuid: f, templateUuid: t).path;

      expect(path, '/new?folder=${f.uuid}&template=${t.uuid}');
      final back = NewItemRequest.fromQuery(Uri.parse(path).queryParameters);
      expect(back.folderUuid, f);
      expect(back.templateUuid, t);
      expect(const NewItemRequest().path, '/new');
    });
  });
}
