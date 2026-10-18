@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/activity/activity_service.dart';
import 'package:wonky_server/src/platform/comments/comment_service.dart';
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/guarded.dart';
import 'package:wonky_server/src/platform/common/json.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// The server write and job rules (code-quality CQ-21, specs/13 §3):
/// stale reads never overwrite concurrent changes (T1), check-then-act
/// decisions are made by the conditional write itself (T3), and background
/// work catches every failure (T2).
void main() {
  withWonkyServerpod('Given background work', (sessionBuilder, endpoints) {
    test('when the body throws an Error then runGuarded returns null and '
        'does not throw', () async {
      final result = await runGuarded<int>(
        sessionBuilder.build(),
        'test.job',
        () async => throw StateError('broken'),
      );

      expect(result, isNull);
    });

    test('when the body succeeds then runGuarded returns its result', () async {
      final result = await runGuarded<int>(
        sessionBuilder.build(),
        'test.job',
        () async => 3,
        describe: describeCount,
      );

      expect(result, 3);
    });
  });

  withWonkyServerpod('Given a comment thread', (sessionBuilder, endpoints) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    late CommentThreadView thread;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
      thread = await endpoints.comment.createThread(
        anna.endpointSession,
        const Uuid().v7obj(),
        doc.uuid,
        CommentAnchorKind.textRange,
        '{"v":1}',
        'quoted',
        'Look',
        [],
        null,
      );
    });

    Future<(CommentThread, DriveItem)> rows() async {
      final session = sessionBuilder.build();
      final row = (await CommentThread.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(thread.uuid),
      ))!;
      final item = (await DriveItem.db.findById(session, row.itemId))!;
      return (row, item);
    }

    test(
      'when two people react at once then both reactions are kept',
      () async {
        final id = thread.comments.first.id;

        await Future.wait([
          endpoints.comment.react(anna.endpointSession, id, '👍'),
          endpoints.comment.react(bo.endpointSession, id, '👍'),
        ]);
        final after = await endpoints.comment.getThread(
          anna.endpointSession,
          thread.uuid,
        );

        expect(
          after.comments.first.reactions['👍'],
          unorderedEquals([
            anna.id,
            bo.id,
          ]),
        );
      },
    );

    test('when a thread is orphaned from a stale read after it was resolved '
        'then it stays resolved', () async {
      final (stale, item) = await rows();
      await endpoints.comment.resolve(bo.endpointSession, thread.uuid);

      await CommentService.orphan(sessionBuilder.build(), stale, item);
      final (now, _) = await rows();

      expect(now.status, CommentStatus.resolved);
      expect(now.resolvedById, bo.id);
    });

    test('when someone replies while the thread is being resolved then the '
        'reply does not reopen it', () async {
      await endpoints.comment.resolve(bo.endpointSession, thread.uuid);

      await endpoints.comment.reply(
        anna.endpointSession,
        thread.uuid,
        'Thanks',
        [],
      );
      final (now, _) = await rows();

      expect(now.status, CommentStatus.resolved);
    });

    test('when the anchor moves then the status is left alone', () async {
      await endpoints.comment.resolve(bo.endpointSession, thread.uuid);

      await endpoints.comment.updateAnchor(
        anna.endpointSession,
        thread.uuid,
        '{"v":2}',
      );
      final (now, _) = await rows();

      expect(now.status, CommentStatus.resolved);
      expect(now.anchorJson, '{"v":2}');
    });
  });

  withWonkyServerpod('Given an access request', (sessionBuilder, endpoints) {
    test(
      'when two editors answer it at once then exactly one answer wins',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final cy = await TestUsers.create(sessionBuilder, name: 'Cy');
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        await endpoints.sharing.requestAccess(
          cy.endpointSession,
          doc.uuid,
          AccessRole.viewer,
          null,
        );
        final request = (await AccessRequest.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.requesterId.equals(cy.id),
        ))!;

        final results = await Future.wait([
          endpoints.sharing
              .handleAccessRequest(
                anna.endpointSession,
                request.id!,
                true,
                null,
              )
              .then<Object?>((r) => r, onError: (Object e) => e),
          endpoints.sharing
              .handleAccessRequest(bo.endpointSession, request.id!, false, null)
              .then<Object?>((r) => r, onError: (Object e) => e),
        ]);

        expect(results.whereType<SharingInfo>(), hasLength(1));
        expect(results.whereType<WonkyException>(), hasLength(1));
      },
    );
  });

  withWonkyServerpod('Given an ownership transfer', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when the new owner answers twice at once then it is handled once',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        await endpoints.sharing.transferOwnership(
          anna.endpointSession,
          doc.uuid,
          bo.id,
        );
        final transfer = (await OwnershipTransfer.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.toUserId.equals(bo.id),
        ))!;

        final results = await Future.wait([
          for (final accept in [true, false])
            endpoints.sharing
                .respondToOwnershipTransfer(
                  bo.endpointSession,
                  transfer.id!,
                  accept,
                )
                .then<Object?>((r) => r, onError: (Object e) => e),
        ]);
        final handled = (await OwnershipTransfer.db.findById(
          sessionBuilder.build(),
          transfer.id!,
        ))!;
        final item = (await DriveItem.db.findFirstRow(
          sessionBuilder.build(),
          where: (t) => t.uuid.equals(doc.uuid),
        ))!;

        expect(results.whereType<DriveItemView>(), hasLength(1));
        expect(results.whereType<WonkyException>(), hasLength(1));
        expect(item.ownerId, handled.accepted == true ? bo.id : anna.id);
      },
    );
  });

  withWonkyServerpod('Given edits recorded at once', (
    sessionBuilder,
    endpoints,
  ) {
    test('when ten edits of one user are logged concurrently then the event '
        'counts all of them', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final doc = await TestDrive.document(endpoints, anna);
      final session = sessionBuilder.build();
      final item = (await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(doc.uuid),
      ))!;
      final actor = Actor(
        userId: anna.id,
        authUserId: anna.authUserId,
        kind: ActorKind.user,
      );

      await Future.wait([
        for (var i = 0; i < 10; i++)
          ActivityService.logEdit(
            sessionBuilder.build(),
            item.id!,
            actor,
            counters: {'insertedChars': 1},
          ),
      ]);
      final events = await ActivityEvent.db.find(
        session,
        where: (t) =>
            t.itemId.equals(item.id!) & t.type.equals(ActivityType.edited),
      );
      final total = events.fold<num>(
        0,
        (sum, e) => sum + (decodeObject(e.summary)['insertedChars'] as num),
      );

      expect(total, 10);
    });
  });
}
