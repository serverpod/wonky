import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDropdownMenu;

import '../support/fake_collab.dart';
import '../support/screen_pump.dart';

Finder _key(String k) => find.byKey(ValueKey<String>(k));

void main() {
  late CommandTestHarness h;
  late FakeSharingRepository repo;
  late DriveItemView item;
  final dan = TestUsers.summary(
    id: 4,
    displayName: 'Dan Moss',
    email: 'dan@example.test',
  );

  SharingInfo sharing({
    AccessRole myRole = AccessRole.owner,
    bool canShare = true,
    List<AccessRequestView> requests = const [],
  }) => SharingInfo(
    itemUuid: item.uuid,
    itemName: item.name,
    itemKind: DriveItemKind.document,
    owner: TestUsers.anna,
    myRole: myRole,
    canShare: canShare,
    permissions: [
      PermissionView(
        user: TestUsers.bob,
        role: AccessRole.editor,
        grantedAt: DateTime.utc(2026, 10, 1),
      ),
      PermissionView(
        invitedEmail: 'carol@example.test',
        role: AccessRole.viewer,
        grantedAt: DateTime.utc(2026, 10, 1),
      ),
      PermissionView(
        user: dan,
        role: AccessRole.commenter,
        inheritedFromUuid: UuidValue.fromString(
          '0199f000-0000-7000-8000-0000000000f0',
        ),
        inheritedFromName: 'Team',
        grantedAt: DateTime.utc(2026, 10, 1),
      ),
    ],
    settings: ItemSharingSettings(
      editorsCanShare: true,
      nonEditorsCanExport: true,
      viewersSeeComments: true,
    ),
    pendingRequests: requests,
  );

  setUp(() {
    final drive = FakeDriveRepository();
    item = drive.seed(name: 'Plan');
    repo = FakeSharingRepository(sharing());
    h = CommandTestHarness(drive: drive, sharing: repo);
  });
  tearDown(() => h.dispose());

  Future<void> pumpDialog(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
  }) => pumpScreen(
    tester,
    h,
    ShareDialog(services: h.services, item: item),
    brightness: brightness,
  );

  /// The role menu of user [id]'s row (its entries live in the menu's
  /// overlay, not under the button).
  Finder personMenu(int id) => find.ancestor(
    of: _key('dialog.share.person.$id'),
    matching: find.byType(WonkyDropdownMenu),
  );

  /// Opens [select] and picks the option [label].
  Future<void> choose(WidgetTester tester, Finder select, String label) async {
    await tester.tap(select);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: select, matching: find.text(label)).last,
    );
    await tester.pumpAndSettle();
  }

  for (final b in Brightness.values) {
    testWidgets('Given a shared file in ${b.name} mode when the owner opens '
        'the dialog then everyone with access is listed with their role', (
      tester,
    ) async {
      await pumpDialog(tester, brightness: b);

      expect(find.text('Share “Plan”'), findsOneWidget);
      expect(find.text('Anna Berg (you)'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      expect(find.text('Bob Stone'), findsOneWidget);
      expect(_key('dialog.share.person.2'), findsOneWidget);
      expect(find.text('carol@example.test'), findsOneWidget);
      expect(find.text('Pending invite'), findsOneWidget);
      expect(
        find.text('dan@example.test · From folder “Team”'),
        findsOneWidget,
      );
      expect(
        _key('dialog.share.person.4'),
        findsNothing,
        reason: 'inherited access is changed on the folder',
      );
      expect(find.text('Restricted'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }

  testWidgets(
    'Given the share dialog when checking tap targets then every tappable '
    'control has a label',
    (tester) async {
      await pumpDialog(tester);

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    },
  );

  group('Given the owner in the share dialog', () {
    testWidgets('when adding an email with the commenter role then it is '
        'shared and listed as an invite', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'erin@example.test,');
      await tester.pumpAndSettle();
      expect(find.text('erin@example.test'), findsOneWidget);
      await choose(tester, _key('dialog.share.role'), 'Commenter');
      await tester.tap(_key('dialog.share.send'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['share:commenter:erin@example.test:notify=true']);
      expect(find.text('erin@example.test'), findsOneWidget);
      expect(find.text('Pending invite'), findsNWidgets(2));
      expect(_key('dialog.share.send'), findsNothing);
    });

    testWidgets('when typing a name then matching people are suggested and '
        'picking one adds them as a recipient', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'bob');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob Stone · bob@example.test'));
      await tester.pumpAndSettle();

      expect(find.text('bob@example.test'), findsNWidgets(2));
      expect(_key('dialog.share.send'), findsOneWidget);
    });

    testWidgets('when an invalid address is entered then no recipient is '
        'added', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'not-an-email ');
      await tester.pumpAndSettle();

      expect(_key('dialog.share.send'), findsNothing);
    });

    testWidgets('when changing a person\'s role then the new role is saved '
        'and shown', (tester) async {
      await pumpDialog(tester);

      await tester.tap(_key('dialog.share.person.2'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: personMenu(2), matching: find.text('Commenter')),
      );
      await tester.pumpAndSettle();

      expect(repo.calls, ['updateRole:2:commenter']);
      expect(
        find.descendant(
          of: _key('dialog.share.person.2'),
          matching: find.text('Commenter'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('when removing access and confirming then the person is no '
        'longer listed', (tester) async {
      await pumpDialog(tester);

      await tester.tap(_key('dialog.share.person.2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove access'));
      await tester.pumpAndSettle();
      await tester.tap(_key('dialog.confirm.confirm'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['remove:2']);
      expect(find.text('Bob Stone'), findsNothing);
    });

    testWidgets('when removing access is cancelled then nothing changes', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.tap(_key('dialog.share.person.2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove access'));
      await tester.pumpAndSettle();
      await tester.tap(_key('dialog.confirm.cancel'));
      await tester.pumpAndSettle();

      expect(repo.calls, isEmpty);
      expect(find.text('Bob Stone'), findsOneWidget);
    });

    testWidgets('when turning on link sharing then anyone with the link can '
        'view and the link role can be changed', (tester) async {
      await pumpDialog(tester);

      await choose(
        tester,
        _key('dialog.share.linkMode'),
        'Anyone with the link',
      );
      expect(repo.calls, ['setLink:viewer']);
      expect(
        find.text('Anyone signed in who has the link can open it'),
        findsOneWidget,
      );
      await choose(tester, _key('dialog.share.linkRole'), 'Editor');

      expect(repo.calls, ['setLink:viewer', 'setLink:editor']);
      expect(repo.info.link?.role, AccessRole.editor);
    });

    testWidgets('when changing a sharing setting then it is saved', (
      tester,
    ) async {
      await pumpDialog(tester);

      await tester.tap(_key('dialog.share.settings'));
      await tester.pumpAndSettle();
      expect(find.text('Sharing settings'), findsWidgets);
      await tester.tap(find.text('Editors can change permissions and share'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['settings:false,true,true']);
      expect(repo.info.settings.editorsCanShare, isFalse);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('when copying the link then the file\'s address is on the '
        'clipboard', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpDialog(tester);

      await tester.tap(_key('dialog.share.copyLink'));
      await tester.pumpAndSettle();

      expect(copied, contains(item.uuid.uuid));
    });
  });

  testWidgets('Given a pending access request when the owner approves it '
      'then the request is handled and disappears', (tester) async {
    repo.info = sharing(
      requests: [
        AccessRequestView(
          id: 5,
          itemUuid: item.uuid,
          requester: dan,
          requestedRole: AccessRole.editor,
          message: 'Please',
          createdAt: DateTime.utc(2026, 10, 1),
        ),
      ],
    );
    await pumpDialog(tester);
    expect(find.text('Dan Moss requests Editor access'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(repo.calls, ['handleRequest:5:true']);
    expect(find.text('Dan Moss requests Editor access'), findsNothing);
  });

  for (final b in Brightness.values) {
    testWidgets('Given a viewer in ${b.name} mode when the dialog opens then '
        'sharing controls are not offered', (tester) async {
      repo.info = sharing(myRole: AccessRole.viewer, canShare: false);

      await pumpDialog(tester, brightness: b);

      expect(
        find.text('Only the owner and editors can share this file.'),
        findsOneWidget,
      );
      expect(_key('dialog.share.input'), findsNothing);
      expect(_key('dialog.share.settings'), findsNothing);
      expect(_key('dialog.share.person.2'), findsNothing);
      expect(find.text('Editor'), findsOneWidget);
      await tester.tap(_key('dialog.share.linkMode'));
      await tester.pumpAndSettle();
      expect(find.text('Anyone with the link'), findsNothing);
      expect(repo.calls, isEmpty);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });
  }

  group('Given the owner in the share dialog and a server that rejects '
      'changes', () {
    /// Pumps the dialog under the services' navigator, so toasts show.
    Future<void> pumpWithToasts(WidgetTester tester) async {
      await pumpScreen(
        tester,
        h,
        Navigator(
          key: h.services.navigatorKey,
          onGenerateRoute: (_) => PageRouteBuilder<void>(
            pageBuilder: (context, _, _) =>
                ShareDialog(services: h.services, item: item),
          ),
        ),
      );
      repo.failWith = WonkyException(
        code: WonkyErrorCode.forbidden,
        message: 'You no longer have access',
      );
    }

    /// Lets the toasts time out.
    Future<void> settleToasts(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    }

    testWidgets('when sharing fails then only the error toast shows and '
        'the recipients stay', (tester) async {
      await pumpWithToasts(tester);

      await tester.enterText(_key('dialog.share.input'), 'erin@example.test,');
      await tester.pumpAndSettle();
      await tester.tap(_key('dialog.share.send'));
      await tester.pumpAndSettle();

      expect(find.text('The sharing change could not be saved'), findsOne);
      expect(find.text('Shared with 1 person'), findsNothing);
      expect(find.text('erin@example.test'), findsOneWidget);
      expect(_key('dialog.share.send'), findsOneWidget);
      expect(repo.calls, isEmpty);
      await settleToasts(tester);
    });

    testWidgets('when turning on link sharing fails then the link stays '
        'restricted', (tester) async {
      await pumpWithToasts(tester);

      await choose(
        tester,
        _key('dialog.share.linkMode'),
        'Anyone with the link',
      );

      expect(find.text('The sharing change could not be saved'), findsOne);
      expect(
        find.descendant(
          of: _key('dialog.share.linkMode'),
          matching: find.text('Restricted'),
        ),
        findsOneWidget,
      );
      expect(_key('dialog.share.linkRole'), findsNothing);
      await settleToasts(tester);
    });
  });

  testWidgets('Given sharing info that fails to load when the dialog opens '
      'then the error is shown', (tester) async {
    repo.loadError = WonkyException(
      code: WonkyErrorCode.forbidden,
      message: 'You no longer have access',
    );

    await pumpDialog(tester);

    expect(find.text('You no longer have access'), findsOneWidget);
    expect(find.text('People with access'), findsNothing);
  });
}
