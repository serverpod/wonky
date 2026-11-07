import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_ui/testing.dart';

/// A drive that records `markOpened` (a guest must not call it).
class _RecordingDrive extends FakeDriveRepository {
  final opened = <UuidValue>[];

  @override
  Future<DriveItemView> markOpened(UuidValue uuid) {
    opened.add(uuid);
    return super.markOpened(uuid);
  }
}

/// The editor frame of a signed-out viewer (specs/06 §2.4): the item comes
/// from `publicItem.get`, no drive, comments or presence calls, view-only,
/// *Sign in* instead of Share and the account menu.
void main() {
  late _RecordingDrive drive;
  late FakePublicItemRepository public;
  late CommandTestHarness h;

  void signIn(bool signedIn) => h = CommandTestHarness(
    config: const TestAppConfig(guestViewing: true),
    drive: drive,
    auth: FakeAuthRepository(signedIn: signedIn),
    publicItems: public,
  );

  setUp(() {
    drive = _RecordingDrive();
    public = FakePublicItemRepository(drive);
  });
  tearDown(() => h.dispose());

  Future<DriveItemView?> pumpEditor(
    WidgetTester tester,
    String uuid, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1280, 800),
  }) async {
    DriveItemView? loaded;
    final doc = BasicDocumentController(
      itemUuid: UuidValue.fromString(uuid),
      kind: DriveItemKind.document,
      role: Role.viewer,
    );
    addTearDown(doc.dispose);
    await pumpWonky(
      tester,
      EditorScaffold(
        services: h.services,
        itemUuid: uuid,
        controller: doc,
        body: (context, item) => const SizedBox.expand(),
        onItemLoaded: (v) => loaded = v,
      ),
      size: size,
      brightness: brightness,
      extraDelegates: const [WonkyAppLocalizations.delegate],
      wrap: (context, child) =>
          Provider<ShellServices>.value(value: h.services, child: child!),
    );
    await tester.pump();
    await tester.pump();
    return loaded;
  }

  for (final brightness in Brightness.values) {
    testWidgets('Given a link-shared document when a guest opens it in '
        '${brightness.name} then it is view-only without account calls', (
      tester,
    ) async {
      signIn(false);
      final item = drive.seed(name: 'Public plan');
      public.share(item.uuid);
      final uuid = item.uuid.uuid;

      final loaded = await pumpEditor(tester, uuid, brightness: brightness);

      expect(loaded?.role, AccessRole.viewer);
      expect(public.calls, [item.uuid]);
      expect(drive.opened, isEmpty);
      expect(h.services.supervisor.isActive('presence:$uuid'), isFalse);
      expect(h.services.supervisor.isActive('comments:$uuid'), isFalse);
      expect(find.text('Public plan'), findsWidgets);
      expect(find.text('View only'), findsOneWidget);
      expect(find.text('Viewing as a guest'), findsOneWidget);
      expect(find.text('Sign in to comment or edit'), findsOneWidget);
      expect(byKey('editor.signIn'), findsOneWidget);
      for (final key in const [
        'editor.share',
        'editor.star',
        'editor.move',
        'editor.comments',
        'editor.reportBug',
      ]) {
        expect(byKey(key), findsNothing, reason: key);
      }
      expect(find.byType(AccountMenuButton), findsNothing);
      await settleTooltips(tester);
    });
  }

  testWidgets('Given a guest on a phone when the shared document opens then '
      'the compact title row has Sign in', (tester) async {
    signIn(false);
    final item = drive.seed(name: 'Public plan');
    public.share(item.uuid);

    await pumpEditor(tester, item.uuid.uuid, size: const Size(390, 800));

    expect(byKey('editor.mobile'), findsOneWidget);
    expect(byKey('editor.signIn'), findsOneWidget);
    expect(find.byType(AccountMenuButton), findsNothing);
    await settleTooltips(tester);
  });

  testWidgets('Given a document that is not link-shared when a guest opens it '
      'then the signed-out no-access page shows', (tester) async {
    signIn(false);
    final item = drive.seed(name: 'Private');

    await pumpEditor(tester, item.uuid.uuid);

    expect(byKey('shell.noAccess'), findsOneWidget);
    expect(byKey('shell.noAccess.signIn'), findsOneWidget);
    expect(byKey('shell.noAccess.request'), findsNothing);
    expect(find.text('Private'), findsNothing);
    expect(drive.opened, isEmpty);
    await settleTooltips(tester);
  });

  testWidgets('Given a signed-in user when the document opens then it is '
      'marked opened and the account menu shows', (tester) async {
    signIn(true);
    final item = drive.seed(name: 'Mine');

    await pumpEditor(tester, item.uuid.uuid);

    expect(drive.opened, [item.uuid]);
    expect(public.calls, isEmpty);
    expect(byKey('editor.signIn'), findsNothing);
    expect(find.byType(AccountMenuButton), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}

Finder byKey(String key) => find.byKey(ValueKey<String>(key));
