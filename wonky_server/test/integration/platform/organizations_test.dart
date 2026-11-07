@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/organizations/organization_config.dart';
import 'package:wonky_server/src/platform/organizations/organization_service.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

var _domainCounter = 0;

/// A fresh company domain per call (the test database is not rolled back,
/// so organizations of other tests must not mix in).
String _freshDomain() =>
    'acme${clock.now().microsecondsSinceEpoch}x${_domainCounter++}.dev';

/// Organizations and sharing with them (specs/04 §6, specs/06 §2.3).
void main() {
  setUp(() {
    OrganizationConfig.reset();
    OrganizationService.forget();
  });
  tearDown(OrganizationConfig.reset);

  withWonkyServerpod('Given users of one organization', (
    sessionBuilder,
    endpoints,
  ) {
    late String domain;
    late TestUser anna;
    late TestUser bo;
    late TestUser outsider;
    late TestUser gmail;
    setUp(() async {
      domain = _freshDomain();
      anna = await TestUsers.create(
        sessionBuilder,
        name: 'Anna Berg',
        email: 'anna@$domain',
      );
      bo = await TestUsers.create(
        sessionBuilder,
        name: 'Bo Chen',
        email: 'bo.chen@$domain',
      );
      outsider = await TestUsers.create(
        sessionBuilder,
        name: 'Bo Outside',
        email: 'bo@${_freshDomain()}',
      );
      gmail = await TestUsers.create(
        sessionBuilder,
        name: 'Bo Gmail',
        email: 'bo.${clock.now().microsecondsSinceEpoch}@gmail.com',
      );
    });

    test('when asking for their organization then it is the domain', () async {
      final session = anna.session;

      expect(await OrganizationService.orgKeyOf(session, anna.id), domain);
      expect(
        await OrganizationService.sameOrganization(session, anna.id, bo.id),
        isTrue,
      );
      expect(
        await OrganizationService.sameOrganization(
          session,
          anna.id,
          outsider.id,
        ),
        isFalse,
      );
      expect(await OrganizationService.orgOf(session, gmail.id), isNull);
    });

    test('when reading the profile then the organization is there', () async {
      final me = await endpoints.user.getMe(anna.endpointSession);
      final other = await endpoints.user.getMe(gmail.endpointSession);

      expect(me.organization, domain);
      expect(other.organization, isNull);
    });

    test('when a document is shared with the organization then members open '
        'it with that role and others do not', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Plan');

      final info = await endpoints.sharing.setGeneralAccess(
        anna.endpointSession,
        doc.uuid,
        GeneralAccess.organization,
        AccessRole.commenter,
      );

      expect(info.generalAccess, GeneralAccess.organization);
      expect(info.organization, domain);
      expect(info.orgAccess?.domain, domain);
      expect(info.orgAccess?.role, AccessRole.commenter);
      expect(info.permissions, isEmpty);
      final view = await endpoints.drive.get(bo.endpointSession, doc.uuid);
      expect(view.role, AccessRole.commenter);
      for (final stranger in [outsider, gmail]) {
        await expectLater(
          endpoints.drive.get(stranger.endpointSession, doc.uuid),
          throwsA(isA<WonkyException>()),
        );
      }
    });

    test('when members open an organization item then it is in shared with '
        'me and search afterwards, not before', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Roadmap');
      await endpoints.sharing.setGeneralAccess(
        anna.endpointSession,
        doc.uuid,
        GeneralAccess.organization,
        AccessRole.viewer,
      );
      Future<List<UuidValue>> shared() async => [
        for (final i in (await endpoints.drive.list(
          bo.endpointSession,
          null,
          DriveListFilter(view: DriveView.sharedWithMe),
          DriveSort(),
          null,
          50,
        )).items)
          i.uuid,
      ];
      Future<List<UuidValue>> found() async => [
        for (final i in (await endpoints.drive.search(
          bo.endpointSession,
          'Roadmap',
          DriveSearchFilters(),
          null,
          50,
        )).items)
          i.uuid,
      ];

      expect(await shared(), isNot(contains(doc.uuid)));
      expect(await found(), isNot(contains(doc.uuid)));

      await endpoints.drive.markOpened(bo.endpointSession, doc.uuid);

      expect(await shared(), contains(doc.uuid));
      expect(await found(), contains(doc.uuid));
    });

    test('when a folder is shared with the organization then its items are '
        'inherited, and unsharing removes them', () async {
      final folder = await TestDrive.folder(endpoints, anna, name: 'Team');
      final child = await TestDrive.document(
        endpoints,
        anna,
        name: 'Inside',
        parentUuid: folder.uuid,
      );
      await endpoints.sharing.setGeneralAccess(
        anna.endpointSession,
        folder.uuid,
        GeneralAccess.organization,
        AccessRole.editor,
      );

      final view = await endpoints.drive.get(bo.endpointSession, child.uuid);
      expect(view.role, AccessRole.editor);
      final childInfo = await endpoints.sharing.getSharing(
        anna.endpointSession,
        child.uuid,
      );
      expect(childInfo.generalAccess, GeneralAccess.restricted);
      expect(childInfo.inheritedOrgAccess?.domain, domain);
      expect(childInfo.inheritedOrgAccess?.inheritedFromUuid, folder.uuid);
      final listed = await endpoints.drive.list(
        bo.endpointSession,
        folder.uuid,
        DriveListFilter(view: DriveView.folder),
        DriveSort(),
        null,
        50,
      );
      expect(listed.items.map((i) => i.uuid), [child.uuid]);

      await endpoints.sharing.setGeneralAccess(
        anna.endpointSession,
        folder.uuid,
        GeneralAccess.restricted,
        null,
      );

      await expectLater(
        endpoints.drive.get(bo.endpointSession, child.uuid),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when switching to link sharing then the organization grant goes',
      () async {
        final doc = await TestDrive.document(endpoints, anna);
        await endpoints.sharing.setGeneralAccess(
          anna.endpointSession,
          doc.uuid,
          GeneralAccess.organization,
          AccessRole.editor,
        );

        final info = await endpoints.sharing.setLink(
          anna.endpointSession,
          doc.uuid,
          AccessRole.viewer,
        );

        expect(info.generalAccess, GeneralAccess.link);
        expect(info.orgAccess, isNull);
        expect(info.link?.role, AccessRole.viewer);
        final view = await endpoints.drive.get(bo.endpointSession, doc.uuid);
        expect(view.role, AccessRole.viewer);
      },
    );

    test('when a user without an organization shares with one then it is '
        'refused', () async {
      final doc = await TestDrive.document(endpoints, gmail);

      final info = await endpoints.sharing.getSharing(
        gmail.endpointSession,
        doc.uuid,
      );
      expect(info.organization, isNull);
      await expectLater(
        endpoints.sharing.setGeneralAccess(
          gmail.endpointSession,
          doc.uuid,
          GeneralAccess.organization,
          AccessRole.viewer,
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.invalidArgument,
          ),
        ),
      );
    });

    test(
      'when an editor sets a role above their own then it is refused',
      () async {
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.commenter);

        await expectLater(
          endpoints.sharing.setGeneralAccess(
            bo.endpointSession,
            doc.uuid,
            GeneralAccess.organization,
            AccessRole.editor,
          ),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test('when an organization item is copied with its sharing then the copy '
        'keeps the organization grant', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Source');
      await endpoints.sharing.setGeneralAccess(
        anna.endpointSession,
        doc.uuid,
        GeneralAccess.organization,
        AccessRole.viewer,
      );

      final copy = await endpoints.drive.copy(
        anna.endpointSession,
        doc.uuid,
        'Copy',
        null,
        false,
        true,
      );

      final view = await endpoints.drive.get(bo.endpointSession, copy.uuid);
      expect(view.role, AccessRole.viewer);
    });
  });

  withWonkyServerpod('Given an alias group of two domains', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when sharing with the organization then both domains get access',
      () async {
        final dev = _freshDomain();
        final com = dev.replaceAll('.dev', '.com');
        OrganizationConfig.current = OrganizationConfig(
          aliases: [
            [dev, com],
          ],
        );
        final anna = await TestUsers.create(
          sessionBuilder,
          name: 'Anna',
          email: 'anna@$com',
        );
        final bo = await TestUsers.create(
          sessionBuilder,
          name: 'Bo',
          email: 'bo@$dev',
        );
        final doc = await TestDrive.document(endpoints, anna);

        final info = await endpoints.sharing.setGeneralAccess(
          anna.endpointSession,
          doc.uuid,
          GeneralAccess.organization,
          AccessRole.viewer,
        );

        expect(info.orgAccess?.domain, dev);
        final view = await endpoints.drive.get(bo.endpointSession, doc.uuid);
        expect(view.role, AccessRole.viewer);
      },
    );

    test(
      'when the domain later becomes public then the grant stops working',
      () async {
        final domain = _freshDomain();
        final anna = await TestUsers.create(
          sessionBuilder,
          name: 'Anna',
          email: 'anna@$domain',
        );
        final bo = await TestUsers.create(
          sessionBuilder,
          name: 'Bo',
          email: 'bo@$domain',
        );
        final doc = await TestDrive.document(endpoints, anna);
        await endpoints.sharing.setGeneralAccess(
          anna.endpointSession,
          doc.uuid,
          GeneralAccess.organization,
          AccessRole.viewer,
        );

        OrganizationConfig.current = OrganizationConfig(
          publicDomains: {domain},
        );

        await expectLater(
          endpoints.drive.get(bo.endpointSession, doc.uuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );
  });

  withWonkyServerpod('Given the share dialog people search', (
    sessionBuilder,
    endpoints,
  ) {
    late String domain;
    late TestUser anna;
    late TestUser carla;
    late TestUser stranger;
    late TestUser gmailUser;
    late TestUser related;
    setUp(() async {
      domain = _freshDomain();
      anna = await TestUsers.create(
        sessionBuilder,
        name: 'Anna Berg',
        email: 'anna@$domain',
      );
      carla = await TestUsers.create(
        sessionBuilder,
        name: 'Carla Diaz',
        email: 'cd@$domain',
      );
      stranger = await TestUsers.create(
        sessionBuilder,
        name: 'Carla Stranger',
        email: 'carla@${_freshDomain()}',
      );
      gmailUser = await TestUsers.create(
        sessionBuilder,
        name: 'Carla Gmail',
        email: 'carla.${clock.now().microsecondsSinceEpoch}@gmail.com',
      );
      related = await TestUsers.create(sessionBuilder, name: 'Carla Related');
      final doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, related, AccessRole.viewer);
    });

    Future<List<int>> search(TestUser who, String q) async => [
      for (final u in await endpoints.user.searchUsers(
        who.endpointSession,
        q,
        20,
      ))
        u.id,
    ];

    test('when searching by a name prefix then organization members and '
        'related people are found, nobody else', () async {
      final ids = await search(anna, 'carl');

      expect(ids, containsAll([carla.id, related.id]));
      expect(ids, isNot(contains(stranger.id)));
      expect(ids, isNot(contains(gmailUser.id)));
    });

    test('when searching by the last name then the member is found', () async {
      expect(await search(anna, 'dia'), [carla.id]);
    });

    test(
      'when searching by an email prefix then the member is found',
      () async {
        expect(await search(anna, 'cd@'), [carla.id]);
      },
    );

    test('when searching inside a member name then nothing is found', () async {
      expect(await search(anna, 'arla d'), isEmpty);
    });

    test('when searching by an exact email then anyone is found', () async {
      expect(await search(anna, stranger.email), [stranger.id]);
      expect(await search(anna, gmailUser.email), [gmailUser.id]);
    });

    test('when a public-domain user searches then no organization members '
        'appear', () async {
      expect(await search(gmailUser, 'carl'), isEmpty);
      expect(await search(gmailUser, 'anna'), isEmpty);
    });

    test('when an outsider searches then the members stay hidden', () async {
      expect(await search(stranger, 'anna'), isEmpty);
    });

    test('when looking up summaries by id then members are revealed only to '
        'their organization', () async {
      final mine = await endpoints.user.getUsers(anna.endpointSession, [
        carla.id,
        stranger.id,
      ]);
      final theirs = await endpoints.user.getUsers(
        stranger.endpointSession,
        [carla.id],
      );

      expect(mine.map((u) => u.id), [carla.id]);
      expect(theirs, isEmpty);
    });
  });
}
