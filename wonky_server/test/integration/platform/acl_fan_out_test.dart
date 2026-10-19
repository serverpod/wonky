@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/drive_events.dart';
import 'package:wonky_server/src/platform/sharing/access_service.dart';
import 'package:wonky_server/src/platform/sharing/acl_events.dart';

import '../../support/streams.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Folder ACL fan-out (CQ-26): batched interested users, one signal per
/// user, big subtrees deferred to a future call, capped bulk lists.
void main() {
  withWonkyServerpod('Given a folder with three documents', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser ben;
    late DriveItemView folder;
    late List<DriveItemView> docs;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      folder = await TestDrive.folder(endpoints, anna, name: 'Team');
      docs = [
        for (final n in ['One', 'Two', 'Three'])
          await TestDrive.document(
            endpoints,
            anna,
            name: n,
            parentUuid: folder.uuid,
          ),
      ];
    });
    tearDown(() {
      AclEvents.inlineNodes = 200;
      AclEvents.schedule = AclEvents.scheduleFutureCall;
    });

    Future<Set<UuidValue>> sharedEvents(Future<void> Function() act) async {
      final probe = const Uuid().v4obj();
      final events = await subscribed(
        endpoints.drive.watch(ben.endpointSession),
        () => ben.session.messages.postMessage(
          DriveEvents.channel(ben.id),
          DriveChangeSignal(kind: DriveChangeKind.updated, itemUuid: probe),
        ),
      );
      await act();
      final seen = <UuidValue>{};
      while (seen.length < 4) {
        final e = await nextWhere(
          events,
          (e) => e.kind == DriveChangeKind.shared && e.item != null,
        );
        seen.add(e.itemUuid);
      }
      await events.cancel();
      return seen;
    }

    test('when the interested users are loaded in a batch then they equal '
        'the per-item answer', () async {
      await TestDrive.share(endpoints, folder, anna, ben, AccessRole.viewer);
      final session = anna.session;
      final nodes = await AccessService.subtree(
        session,
        (await AccessService.findItem(session, folder.uuid))!,
      );

      final batch = await AccessService.interestedUsersOf(session, nodes);

      for (final n in nodes) {
        expect(batch[n.id!], await AccessService.interestedUsers(session, n));
        expect(batch[n.id!], containsAll([anna.id, ben.id]));
      }
    });

    test('when the folder is shared then the grantee\'s watcher sees the '
        'folder and every document', () async {
      final seen = await sharedEvents(
        () => TestDrive.share(endpoints, folder, anna, ben, AccessRole.viewer),
      );

      expect(seen, {folder.uuid, for (final d in docs) d.uuid});
    });

    test('when the subtree is larger than the inline limit then the fan-out '
        'is deferred and runs from the future call', () async {
      AclEvents.inlineNodes = 2;
      final scheduled = <(int, DriveChangeKind)>[];
      AclEvents.schedule = (session, itemId, kind, affected) async =>
          scheduled.add((itemId, kind));

      final seen = await sharedEvents(() async {
        await TestDrive.share(endpoints, folder, anna, ben, AccessRole.viewer);
        expect(scheduled, hasLength(1));
        final (itemId, kind) = scheduled.single;
        expect(
          await AclEvents.fanOutDeferred(anna.session, itemId, kind, {}),
          4,
        );
      });

      expect(seen, {folder.uuid, for (final d in docs) d.uuid});
    });

    test('when more than the bulk limit is trashed at once then it is '
        'refused', () async {
      final uuids = [
        for (var i = 0; i < 501; i++) const Uuid().v4obj(),
      ];

      await expectLater(
        endpoints.drive.trash(anna.endpointSession, uuids),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.limitExceeded,
          ),
        ),
      );
    });

    test('when the breadcrumb of a nested document is read then the '
        'ancestors come nearest first', () async {
      final inner = await TestDrive.folder(
        endpoints,
        anna,
        name: 'Inner',
        parentUuid: folder.uuid,
      );
      final doc = await TestDrive.document(
        endpoints,
        anna,
        name: 'Deep',
        parentUuid: inner.uuid,
      );
      final session = anna.session;

      final chain = await AccessService.ancestors(
        session,
        (await AccessService.findItem(session, doc.uuid))!,
      );

      expect([for (final a in chain) a.name], ['Inner', 'Team']);
    });
  });
}
