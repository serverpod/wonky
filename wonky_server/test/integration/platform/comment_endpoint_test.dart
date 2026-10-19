@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/comments/comment_service.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/role_matrix.dart';
import '../../support/streams.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<CommentThreadView> _thread(
  TestEndpoints endpoints,
  TestUser author,
  DriveItemView item, {
  String body = 'First',
  List<int> mentions = const [],
  UuidValue? uuid,
}) => endpoints.comment.createThread(
  author.endpointSession,
  uuid ?? const Uuid().v7obj(),
  item.uuid,
  CommentAnchorKind.textRange,
  '{"v":1}',
  'quoted',
  body,
  mentions,
  null,
);

void main() {
  withWonkyServerpod('Given a document with commenters', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.commenter);
    });

    test(
      'when creating a thread then it is listed with its first comment',
      () async {
        await _thread(endpoints, bo, doc, body: 'Looks good');

        final threads = await endpoints.comment.listThreads(
          anna.endpointSession,
          doc.uuid,
          CommentFilter.all,
        );

        expect(threads.single.comments.single.body, 'Looks good');
        expect(threads.single.createdBy?.id, bo.id);
      },
    );

    test(
      'when creating the same thread uuid twice then one thread exists',
      () async {
        final uuid = const Uuid().v7obj();
        await _thread(endpoints, bo, doc, uuid: uuid);
        await _thread(endpoints, bo, doc, uuid: uuid);

        final threads = await endpoints.comment.listThreads(
          bo.endpointSession,
          doc.uuid,
          CommentFilter.all,
        );

        expect(threads, hasLength(1));
      },
    );

    test('when replying then the thread author is notified', () async {
      final thread = await _thread(endpoints, bo, doc);

      await endpoints.comment.reply(
        anna.endpointSession,
        thread.uuid,
        'Thanks',
        const [],
      );
      final notifications = await endpoints.notification.list(
        bo.endpointSession,
        null,
        10,
        false,
      );

      expect(
        notifications.items.map((n) => n.kind),
        contains(NotificationKind.reply),
      );
    });

    test(
      'when mentioning a user with access then they get a mention notification',
      () async {
        await _thread(endpoints, anna, doc, body: 'Hi @Bo', mentions: [bo.id]);

        final notifications = await endpoints.notification.list(
          bo.endpointSession,
          null,
          10,
          false,
        );

        expect(
          notifications.items.map((n) => n.kind),
          contains(NotificationKind.mention),
        );
      },
    );

    test('when resolving and reopening then the status follows', () async {
      final thread = await _thread(endpoints, bo, doc);

      final resolved = await endpoints.comment.resolve(
        anna.endpointSession,
        thread.uuid,
      );
      final reopened = await endpoints.comment.reopen(
        bo.endpointSession,
        thread.uuid,
      );

      expect(resolved.status, CommentStatus.resolved);
      expect(reopened.status, CommentStatus.open);
      expect(
        reopened.comments
            .map((c) => c.systemEvent)
            .whereType<CommentSystemEvent>(),
        [CommentSystemEvent.resolved, CommentSystemEvent.reopened],
      );
    });

    test('when editing a reply of someone else then it is refused', () async {
      final thread = await _thread(endpoints, bo, doc);

      await expectLater(
        endpoints.comment.edit(
          anna.endpointSession,
          thread.comments.first.id,
          'Changed',
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when reacting twice then the reaction toggles off', () async {
      final thread = await _thread(endpoints, bo, doc);
      final id = thread.comments.first.id;

      final on = await endpoints.comment.react(anna.endpointSession, id, '👍');
      final off = await endpoints.comment.react(anna.endpointSession, id, '👍');

      expect(on.reactions['👍'], [anna.id]);
      expect(off.reactions.containsKey('👍'), isFalse);
    });

    test('when the owner deletes a thread then it is gone', () async {
      final thread = await _thread(endpoints, bo, doc);

      await endpoints.comment.deleteThread(anna.endpointSession, thread.uuid);

      expect(
        await endpoints.comment.listThreads(
          anna.endpointSession,
          doc.uuid,
          CommentFilter.all,
        ),
        isEmpty,
      );
    });

    test(
      'when watching and someone replies then a threadUpdated event arrives',
      () async {
        final thread = await _thread(endpoints, bo, doc);
        final probe = const Uuid().v4obj();
        final events = await subscribed(
          endpoints.comment.watch(anna.endpointSession, doc.uuid),
          () => anna.session.messages.postMessage(
            CommentService.channel(doc.uuid),
            CommentSignal(
              kind: CommentEventKind.threadDeleted,
              threadUuid: probe,
            ),
          ),
        );

        await endpoints.comment.reply(
          bo.endpointSession,
          thread.uuid,
          'Live',
          const [],
        );
        final event = await nextWhere(
          events,
          (e) => e.threadUuid == thread.uuid,
        );

        expect(event.kind, CommentEventKind.threadUpdated);
        expect(event.thread!.comments.last.body, 'Live');
        await events.cancel();
      },
    );
  });

  withWonkyServerpod('Given a viewer', (sessionBuilder, endpoints) {
    test(
      'when comments are hidden for viewers then listing is refused, and allowed once enabled',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, vic, AccessRole.viewer);

        await expectLater(
          endpoints.comment.listThreads(
            vic.endpointSession,
            doc.uuid,
            CommentFilter.all,
          ),
          throwsA(isA<WonkyException>()),
        );
        await endpoints.sharing.updateSettings(
          anna.endpointSession,
          doc.uuid,
          ItemSharingSettings(
            editorsCanShare: true,
            nonEditorsCanExport: true,
            viewersSeeComments: true,
          ),
        );
        expect(
          await endpoints.comment.listThreads(
            vic.endpointSession,
            doc.uuid,
            CommentFilter.all,
          ),
          isEmpty,
        );
      },
    );
  });

  withWonkyServerpod('Given the comment permission matrix', (
    sessionBuilder,
    endpoints,
  ) {
    forEachRole(
      'Given a document and creating a thread',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor, AccessRole.commenter},
      act: (caller, c) => endpoints.comment.createThread(
        caller,
        const Uuid().v7obj(),
        c.item.uuid,
        CommentAnchorKind.document,
        '{"v":1}',
        null,
        'Hi',
        const [],
        null,
      ),
    );
  });

  withWonkyServerpod('Given notifications', (sessionBuilder, endpoints) {
    test('when marking all read then the unread count is zero', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final doc = await TestDrive.document(endpoints, anna);
      await endpoints.sharing.share(
        anna.endpointSession,
        doc.uuid,
        [bo.email],
        AccessRole.viewer,
        true,
        null,
        null,
      );

      final before = await endpoints.notification.unreadCount(
        bo.endpointSession,
      );
      await endpoints.notification.markAllRead(bo.endpointSession);
      final after = await endpoints.notification.unreadCount(
        bo.endpointSession,
      );

      expect(before, 1);
      expect(after, 0);
    });
  });
}
