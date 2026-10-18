@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/role_matrix.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a document shared with an editor', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna, name: 'Shared');
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
    });

    test('when the editor reads the item then the role is editor', () async {
      final view = await endpoints.drive.get(bo.endpointSession, doc.uuid);

      expect(view.role, AccessRole.editor);
      expect(view.shared, isTrue);
    });

    test('when listing shared with me then the item is there', () async {
      final page = await endpoints.drive.list(
        bo.endpointSession,
        null,
        DriveListFilter(view: DriveView.sharedWithMe),
        DriveSort(),
        null,
        50,
      );

      expect(page.items.map((i) => i.uuid), [doc.uuid]);
    });

    test('when reading the sharing info then the editor is listed', () async {
      final info = await endpoints.sharing.getSharing(
        anna.endpointSession,
        doc.uuid,
      );

      expect(info.owner.id, anna.id);
      expect(info.permissions.map((p) => (p.user?.id, p.role)), [
        (bo.id, AccessRole.editor),
      ]);
      expect(info.canShare, isTrue);
    });

    test('when downgrading to viewer then edits are refused', () async {
      await endpoints.sharing.updateRole(
        anna.endpointSession,
        doc.uuid,
        bo.id,
        AccessRole.viewer,
      );

      await expectLater(
        endpoints.drive.rename(bo.endpointSession, doc.uuid, 'Nope'),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when removing the editor then the item is not found for them',
      () async {
        await endpoints.sharing.remove(anna.endpointSession, doc.uuid, bo.id);

        await expectLater(
          endpoints.drive.get(bo.endpointSession, doc.uuid),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.notFound,
            ),
          ),
        );
      },
    );

    test(
      'when the owner disables "editors can share" then the editor cannot share',
      () async {
        await endpoints.sharing.updateSettings(
          anna.endpointSession,
          doc.uuid,
          ItemSharingSettings(
            editorsCanShare: false,
            nonEditorsCanExport: true,
            viewersSeeComments: false,
          ),
        );
        final carl = await TestUsers.create(sessionBuilder, name: 'Carl');

        await expectLater(
          TestDrive.share(endpoints, doc, bo, carl, AccessRole.viewer),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      'when the shared person was notified then a notification exists',
      () async {
        final carl = await TestUsers.create(sessionBuilder, name: 'Carl');
        await endpoints.sharing.share(
          anna.endpointSession,
          doc.uuid,
          [carl.email],
          AccessRole.commenter,
          true,
          'Have a look',
          null,
        );

        final page = await endpoints.notification.list(
          carl.endpointSession,
          null,
          20,
          false,
        );

        expect(page.items.map((n) => n.kind), [NotificationKind.shared]);
        expect(page.unreadCount, 1);
      },
    );
  });

  withWonkyServerpod('Given a shared folder', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView folder;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      folder = await TestDrive.folder(endpoints, anna, name: 'Team');
      await TestDrive.share(endpoints, folder, anna, bo, AccessRole.commenter);
    });

    test(
      'when a document is created inside then the grantee inherits the role',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          parentUuid: folder.uuid,
        );

        final view = await endpoints.drive.get(bo.endpointSession, doc.uuid);

        expect(view.role, AccessRole.commenter);
      },
    );

    test(
      'when a document is moved out then the inherited role is removed',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          parentUuid: folder.uuid,
        );

        await endpoints.drive.move(anna.endpointSession, [doc.uuid], null);

        await expectLater(
          endpoints.drive.get(bo.endpointSession, doc.uuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      'when the sharing info of a child is read then the grant shows its source',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          parentUuid: folder.uuid,
        );

        final info = await endpoints.sharing.getSharing(
          anna.endpointSession,
          doc.uuid,
        );

        expect(info.permissions.single.inheritedFromUuid, folder.uuid);
      },
    );
  });

  withWonkyServerpod('Given link sharing', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna);
    });

    test(
      'when the link is restricted then other users have no access',
      () async {
        await expectLater(
          endpoints.drive.get(bo.endpointSession, doc.uuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      'when the link gives viewer access then resolving the invite grants viewer',
      () async {
        final info = await endpoints.sharing.setLink(
          anna.endpointSession,
          doc.uuid,
          AccessRole.viewer,
        );

        final resolved = await endpoints.sharing.resolveInvite(
          bo.endpointSession,
          info.link!.token,
        );
        final shared = await endpoints.drive.list(
          bo.endpointSession,
          null,
          DriveListFilter(view: DriveView.sharedWithMe),
          DriveSort(),
          null,
          10,
        );

        expect(resolved.role, AccessRole.viewer);
        expect(shared.items.map((i) => i.uuid), [doc.uuid]);
      },
    );

    test('when rotating the link then the old token stops working', () async {
      final info = await endpoints.sharing.setLink(
        anna.endpointSession,
        doc.uuid,
        AccessRole.viewer,
      );
      final rotated = await endpoints.sharing.rotateLink(
        anna.endpointSession,
        doc.uuid,
      );

      expect(rotated.link!.token, isNot(info.link!.token));
      await expectLater(
        endpoints.sharing.resolveInvite(bo.endpointSession, info.link!.token),
        throwsA(isA<WonkyException>()),
      );
    });
  });

  withWonkyServerpod('Given an ownership transfer', (
    sessionBuilder,
    endpoints,
  ) {
    test('when the new owner accepts then roles swap', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);

      final info = await endpoints.sharing.transferOwnership(
        anna.endpointSession,
        doc.uuid,
        bo.id,
      );
      await endpoints.sharing.respondToOwnershipTransfer(
        bo.endpointSession,
        info.pendingTransfer!.id,
        true,
      );

      final forBo = await endpoints.drive.get(bo.endpointSession, doc.uuid);
      final forAnna = await endpoints.drive.get(anna.endpointSession, doc.uuid);
      expect(forBo.role, AccessRole.owner);
      expect(forAnna.role, AccessRole.editor);
    });
  });

  withWonkyServerpod('Given an access request', (sessionBuilder, endpoints) {
    test(
      'when the owner approves it then the requester gets the role',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final doc = await TestDrive.document(endpoints, anna);
        await endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.commenter,
          'Please',
        );

        final info = await endpoints.sharing.getSharing(
          anna.endpointSession,
          doc.uuid,
        );
        await endpoints.sharing.handleAccessRequest(
          anna.endpointSession,
          info.pendingRequests.single.id,
          true,
          null,
        );

        final view = await endpoints.drive.get(bo.endpointSession, doc.uuid);
        expect(view.role, AccessRole.commenter);
      },
    );
  });

  withWonkyServerpod('Given the sharing permission matrix', (
    sessionBuilder,
    endpoints,
  ) {
    forEachRole(
      'Given a document and getSharing',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      act: (caller, c) => endpoints.sharing.getSharing(caller, c.item.uuid),
    );
    forEachRole(
      'Given a document and sharing it with someone',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      act: (caller, c) async {
        final carl = await TestUsers.create(sessionBuilder, name: 'Carl');
        await endpoints.sharing.share(
          caller,
          c.item.uuid,
          [carl.email],
          AccessRole.viewer,
          false,
          null,
          null,
        );
      },
    );
    forEachRole(
      'Given a document and changing settings',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner},
      act: (caller, c) => endpoints.sharing.updateSettings(
        caller,
        c.item.uuid,
        ItemSharingSettings(
          editorsCanShare: true,
          nonEditorsCanExport: false,
          viewersSeeComments: true,
        ),
      ),
    );
    forEachRole(
      'Given a document and turning on link sharing',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      act: (caller, c) =>
          endpoints.sharing.setLink(caller, c.item.uuid, AccessRole.viewer),
    );
  });
}
