import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart' show ShadInput, ShadShadowDecoration;
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

  final teamUuid = UuidValue.fromString('0199f000-0000-7000-8000-0000000000f0');

  /// The item's sharing; [organization] is the caller's, [orgRole] the
  /// item's own "Anyone at example.test" grant, [linkRole] its link.
  SharingInfo sharing({
    AccessRole myRole = AccessRole.owner,
    bool canShare = true,
    List<AccessRequestView> requests = const [],
    DriveItemKind kind = DriveItemKind.document,
    String? organization,
    AccessRole? orgRole,
    AccessRole? linkRole,
    OrgAccessView? inheritedOrgAccess,
  }) => SharingInfo(
    itemUuid: item.uuid,
    itemName: item.name,
    itemKind: kind,
    owner: TestUsers.anna,
    myRole: myRole,
    canShare: canShare,
    link: linkRole == null ? null : ShareLinkView(token: 'tok', role: linkRole),
    organization: organization,
    orgAccess: orgRole == null
        ? null
        : OrgAccessView(domain: 'example.test', role: orgRole),
    inheritedOrgAccess: inheritedOrgAccess,
    generalAccess: linkRole != null
        ? GeneralAccess.link
        : orgRole != null
        ? GeneralAccess.organization
        : GeneralAccess.restricted,
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
        inheritedFromUuid: teamUuid,
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
    testWidgets('when the dialog is open then Copy link and Done are its '
        'footer and there is no X in the corner (suite 02 §4.20)', (
      tester,
    ) async {
      await pumpDialog(tester);
      expect(_key('dialog.share.copyLink'), findsOneWidget);
      expect(_key('dialog.share.done'), findsOneWidget);
      expect(_key('dialog.close'), findsNothing);

      await tester.tap(_key('dialog.share.settings'));
      await tester.pumpAndSettle();
      expect(_key('dialog.share.settingsDone'), findsOneWidget);
      expect(_key('dialog.close'), findsNothing);
      await tester.tap(_key('dialog.share.settingsDone'));
      await tester.pumpAndSettle();
      expect(_key('dialog.share.done'), findsOneWidget);
    });

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

    testWidgets('when adding someone then Send an email is on and the '
        'message goes with the share (specs/06 §4)', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'erin@example.test,');
      await tester.pumpAndSettle();
      expect(find.text('Send an email'), findsOneWidget);
      expect(
        find.text('People without an account get an invitation to sign up.'),
        findsOneWidget,
      );
      expect(find.text('Send'), findsOneWidget);
      await tester.enterText(_key('dialog.share.message'), 'Take a look');
      await tester.tap(_key('dialog.share.send'));
      await tester.pumpAndSettle();

      expect(repo.calls, [
        'share:editor:erin@example.test:notify=true:message=Take a look',
      ]);
    });

    testWidgets('when Send an email is turned off then the message field '
        'goes away and the share sends no email', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'erin@example.test,');
      await tester.pumpAndSettle();
      await tester.enterText(_key('dialog.share.message'), 'Not sent');
      await tester.tap(find.text('Send an email'));
      await tester.pumpAndSettle();
      expect(_key('dialog.share.message'), findsNothing);
      expect(
        find.text('They get access without an email or a notification.'),
        findsOneWidget,
      );
      await tester.tap(_key('dialog.share.send'));
      await tester.pumpAndSettle();

      expect(repo.calls, ['share:editor:erin@example.test:notify=false']);
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
      expect(repo.calls, ['setGeneralAccess:link:viewer']);
      expect(
        find.text('Anyone with the link can view, also without signing in'),
        findsOneWidget,
      );
      await choose(tester, _key('dialog.share.linkRole'), 'Editor');

      expect(repo.calls, [
        'setGeneralAccess:link:viewer',
        'setGeneralAccess:link:editor',
      ]);
      expect(repo.info.link?.role, AccessRole.editor);
      expect(
        find.text('Anyone with the link can view, and edit when signed in'),
        findsOneWidget,
      );
    });

    testWidgets('when sharing an uploaded file by link then the hint says '
        'visitors sign in', (tester) async {
      repo.info = sharing(
        kind: DriveItemKind.file,
        linkRole: AccessRole.viewer,
      );

      await pumpDialog(tester);

      expect(
        find.text('Anyone signed in who has the link can view'),
        findsOneWidget,
      );
    });

    testWidgets('when the add-people field shows then it has one border and '
        'is as tall as the role select', (tester) async {
      await pumpDialog(tester);

      final field = _key('dialog.share.field');
      expect(
        tester.getSize(field).height,
        tester.getSize(_key('dialog.share.role')).height,
      );
      expect(
        tester.getTopLeft(field).dy,
        tester.getTopLeft(_key('dialog.share.role')).dy,
      );
      bool drawsEdge(Container c) {
        final d = c.decoration;
        if (d is! ShadShadowDecoration) return false;
        final box = d.decoration;
        return d.shadows.isNotEmpty ||
            (box is BoxDecoration && box.border != null);
      }

      final edges = tester
          .widgetList<Container>(
            find.descendant(of: field, matching: find.byType(Container)),
          )
          .where(drawsEdge);
      expect(edges, hasLength(1), reason: 'only the field box has a border');
      expect(
        tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(ShadInput),
                matching: find.byType(Container),
              ),
            )
            .where(drawsEdge),
        isEmpty,
        reason: 'the input inside has no border or shadow of its own',
      );
    });

    testWidgets('when a name search finds no one then the field hints at '
        'the full email of people outside the organization', (tester) async {
      repo.info = sharing(organization: 'example.test');
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'zed');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter the full email to add someone outside example.test'),
        findsOneWidget,
      );
      await tester.enterText(_key('dialog.share.input'), 'zed@example.test');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(_key('dialog.share.searchHint'), findsNothing);
    });

    testWidgets('when a name search finds no one without an organization '
        'then the field asks for the full email', (tester) async {
      await pumpDialog(tester);

      await tester.enterText(_key('dialog.share.input'), 'zed');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter the full email address to add someone'),
        findsOneWidget,
      );
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

  group('Given the owner in an organization in the share dialog', () {
    setUp(() => repo.info = sharing(organization: 'example.test'));

    testWidgets('when opening general access then anyone at the '
        'organization is offered', (tester) async {
      await pumpDialog(tester);

      await tester.tap(_key('dialog.share.linkMode'));
      await tester.pumpAndSettle();

      expect(find.text('Anyone at example.test'), findsOneWidget);
      expect(find.text('Anyone with the link'), findsOneWidget);
    });

    testWidgets('when choosing anyone at the organization then it can view '
        'and the hint says so', (tester) async {
      await pumpDialog(tester);

      await choose(
        tester,
        _key('dialog.share.linkMode'),
        'Anyone at example.test',
      );

      expect(repo.calls, ['setGeneralAccess:organization:viewer']);
      expect(repo.info.orgAccess?.role, AccessRole.viewer);
      expect(find.text('Anyone at example.test can view'), findsOneWidget);
      expect(_key('dialog.share.orgRole'), findsOneWidget);
      expect(_key('dialog.share.linkRole'), findsNothing);
    });

    testWidgets('when changing the organization role then it is saved', (
      tester,
    ) async {
      repo.info = sharing(
        organization: 'example.test',
        orgRole: AccessRole.viewer,
      );
      await pumpDialog(tester);

      await choose(tester, _key('dialog.share.orgRole'), 'Commenter');

      expect(repo.calls, ['setGeneralAccess:organization:commenter']);
      expect(find.text('Anyone at example.test can comment'), findsOneWidget);
    });

    testWidgets('when choosing restricted then the organization loses its '
        'access', (tester) async {
      repo.info = sharing(
        organization: 'example.test',
        orgRole: AccessRole.editor,
      );
      await pumpDialog(tester);

      await choose(tester, _key('dialog.share.linkMode'), 'Restricted');

      expect(repo.calls, ['setGeneralAccess:restricted:null']);
      expect(repo.info.orgAccess, isNull);
      expect(find.text('Only people with access can open'), findsOneWidget);
      expect(_key('dialog.share.orgRole'), findsNothing);
    });

    testWidgets('when a folder above is shared with the organization then '
        'that access is named', (tester) async {
      repo.info = sharing(
        organization: 'example.test',
        inheritedOrgAccess: OrgAccessView(
          domain: 'example.test',
          role: AccessRole.editor,
          inheritedFromUuid: teamUuid,
          inheritedFromName: 'Team',
        ),
      );

      await pumpDialog(tester);

      expect(
        find.text('Anyone at example.test can also edit through “Team”'),
        findsOneWidget,
      );
      expect(find.text('Only people with access can open'), findsOneWidget);
    });
  });

  testWidgets('Given an owner without an organization when opening general '
      'access then only restricted and the link are offered', (tester) async {
    await pumpDialog(tester);

    await tester.tap(_key('dialog.share.linkMode'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Anyone at'), findsNothing);
    expect(find.text('Anyone with the link'), findsOneWidget);
  });

  testWidgets('Given an editor outside the organization of an item shared '
      'with it when the dialog opens then the organization access shows', (
    tester,
  ) async {
    repo.info = sharing(myRole: AccessRole.editor, orgRole: AccessRole.viewer);

    await pumpDialog(tester);

    expect(
      find.descendant(
        of: _key('dialog.share.linkMode'),
        matching: find.text('Anyone at example.test'),
      ),
      findsOneWidget,
    );
    expect(find.text('Anyone at example.test can view'), findsOneWidget);
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

    testWidgets('when sharing with the organization fails then access stays '
        'restricted', (tester) async {
      repo.info = sharing(organization: 'example.test');
      await pumpWithToasts(tester);

      await choose(
        tester,
        _key('dialog.share.linkMode'),
        'Anyone at example.test',
      );

      expect(find.text('The sharing change could not be saved'), findsOne);
      expect(
        find.descendant(
          of: _key('dialog.share.linkMode'),
          matching: find.text('Restricted'),
        ),
        findsOneWidget,
      );
      expect(_key('dialog.share.orgRole'), findsNothing);
      expect(find.text('Only people with access can open'), findsOneWidget);
      await settleToasts(tester);
    });

    testWidgets('when changing the organization role fails then the select '
        'shows the saved role again', (tester) async {
      repo.info = sharing(
        organization: 'example.test',
        orgRole: AccessRole.viewer,
      );
      await pumpWithToasts(tester);

      await choose(tester, _key('dialog.share.orgRole'), 'Editor');

      expect(find.text('The sharing change could not be saved'), findsOne);
      expect(
        find.descendant(
          of: _key('dialog.share.orgRole'),
          matching: find.text('Viewer'),
        ),
        findsOneWidget,
      );
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
