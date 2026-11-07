import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/src/auth/screens/sign_in_screen.dart';
import 'package:wonky_app/src/routing/router.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import '../support/screen_pump.dart';

/// An app whose editor route is the shell's [EditorScaffold].
class _EditorConfig extends TestAppConfig {
  const _EditorConfig({super.app, super.guestViewing});

  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) =>
      EditorScaffold(
        services: ShellScope.of(context),
        itemUuid: uuid,
        body: (context, item) => const SizedBox.expand(),
        historyPanel: false,
        showStatusBar: false,
      );

  @override
  List<RouteBase> editorRoutes(ShellServices services) => [
    GoRoute(
      path: 'print',
      builder: (c, st) => const SizedBox(key: ValueKey<String>('print')),
    ),
  ];
}

/// Signed-out viewing of link-shared items (specs/06 §2.4): in apps that
/// allow it, exactly the editor route opens without sign-in; Drive and
/// every other route still redirect to sign-in.
void main() {
  late CommandTestHarness h;
  late FakeDriveRepository drive;
  late FakePublicItemRepository public;

  Future<void> pumpRouter(
    WidgetTester tester, {
    required String initial,
    WonkyAppConfig config = const _EditorConfig(guestViewing: true),
  }) async {
    h = CommandTestHarness(
      config: config,
      drive: drive,
      auth: FakeAuthRepository(signedIn: false),
      publicItems: public,
    );
    h.services.router = buildShellRouter(h.services);
    await pumpScreen(tester, h, Router.withConfig(config: h.services.router));
    h.services.router.go(initial);
    await _settle(tester);
  }

  String location() => h.services.router.state.uri.toString();

  setUp(() {
    drive = FakeDriveRepository();
    public = FakePublicItemRepository(drive);
  });
  tearDown(() => h.dispose());

  testWidgets('Given a link-shared document when a guest opens /d/<uuid> '
      'then the editor shows view-only with Sign in', (tester) async {
    final doc = drive.seed(name: 'Public plan');
    public.share(doc.uuid);

    await pumpRouter(tester, initial: '/d/${doc.uuid.uuid}');

    expect(location(), '/d/${doc.uuid.uuid}');
    expect(find.byType(SignInScreen), findsNothing);
    expect(find.byType(EditorScaffold), findsOneWidget);
    expect(find.text('Public plan'), findsWidgets);
    expect(byKey('editor.signIn'), findsOneWidget);
    expect(byKey('editor.share'), findsNothing);
    expect(find.byType(AccountMenuButton), findsNothing);
    await _unmount(tester);
  });

  testWidgets('Given a guest on a shared document when Sign in is pressed '
      'then sign-in opens with next back to the document', (tester) async {
    final doc = drive.seed(name: 'Public plan');
    public.share(doc.uuid);
    await pumpRouter(tester, initial: '/d/${doc.uuid.uuid}');

    await tester.tap(byKey('editor.signIn'));
    await _settle(tester);

    expect(location(), '/signin?next=%2Fd%2F${doc.uuid.uuid}');
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Given a document that is not link-shared when a guest opens it '
      'then "Sign in to open this" shows and signs in back to it', (
    tester,
  ) async {
    final doc = drive.seed(name: 'Private');

    await pumpRouter(tester, initial: '/d/${doc.uuid.uuid}');

    expect(location(), '/d/${doc.uuid.uuid}');
    expect(byKey('shell.noAccess'), findsOneWidget);
    expect(find.text('Sign in to open this'), findsWidgets);
    expect(find.text('Private'), findsNothing);

    await tester.tap(byKey('shell.noAccess.signIn'));
    await _settle(tester);

    expect(location(), '/signin?next=%2Fd%2F${doc.uuid.uuid}');
  });

  testWidgets('Given a spreadsheet uuid when a guest opens it in Write then '
      'it is not opened', (tester) async {
    final sheet = drive.seed(name: 'Budget', kind: DriveItemKind.spreadsheet);
    public.share(sheet.uuid);

    await pumpRouter(tester, initial: '/d/${sheet.uuid.uuid}');

    expect(byKey('shell.noAccess'), findsOneWidget);
    expect(find.text('Budget'), findsNothing);
  });

  for (final path in const ['/', '/recent', '/settings/account']) {
    testWidgets('Given guest viewing when $path opens signed out then it '
        'still redirects to sign-in', (tester) async {
      await pumpRouter(tester, initial: path);

      expect(location(), startsWith('/signin'));
      expect(find.byType(SignInScreen), findsOneWidget);
    });
  }

  testWidgets('Given guest viewing when a child of the editor route opens '
      'signed out then it redirects to sign-in', (tester) async {
    final doc = drive.seed(name: 'Public plan');
    public.share(doc.uuid);

    await pumpRouter(tester, initial: '/d/${doc.uuid.uuid}/print');

    expect(location(), '/signin?next=%2Fd%2F${doc.uuid.uuid}%2Fprint');
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('Given Drive (no guest viewing) when a guest opens a file '
      'then it redirects to sign-in', (tester) async {
    final file = drive.seed(name: 'photo.png', kind: DriveItemKind.file);
    public.share(file.uuid);

    await pumpRouter(
      tester,
      config: const _EditorConfig(app: WonkyAppKind.drive),
      initial: '/file/${file.uuid.uuid}',
    );

    expect(location(), startsWith('/signin?next='));
    expect(find.byType(SignInScreen), findsOneWidget);
    expect(public.calls, isEmpty);
  });

  testWidgets('Given a guest on a shared document then commands that need '
      'an account are disabled', (tester) async {
    final doc = drive.seed(name: 'Public plan');
    public.share(doc.uuid);
    await pumpRouter(tester, initial: '/d/${doc.uuid.uuid}');

    for (final id in const [
      'shell.sharing.open',
      'shell.comments.togglePanel',
      'shell.versions.open',
      'shell.file.new',
      'shell.drive.makeCopy',
    ]) {
      final state = h.services.dispatcher.stateOf(id);
      expect(state.enabled, isFalse, reason: id);
      expect(state.disabledReason, 'Sign in to use this', reason: id);
    }
    expect(
      h.services.dispatcher.stateOf('shell.account.signIn').enabled,
      isTrue,
    );
    expect(
      h.services.dispatcher.stateOf('shell.help.shortcuts').enabled,
      isTrue,
    );
    await _unmount(tester);
  });
}

Finder byKey(String key) => find.byKey(ValueKey<String>(key));

/// Pumps the route change and the item load (the editor's loading shimmer
/// never settles: no document controller in these tests).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 500));
}

/// Unmounts the screen and runs out pending timers (tooltips, shimmer).
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}
