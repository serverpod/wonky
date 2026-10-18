@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/feedback/feedback_endpoint.dart';
import 'package:wonky_server/src/platform/sharing/sharing_service.dart';

import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _throwsCode(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

Future<CommentThreadView> _thread(
  TestEndpoints endpoints,
  TestUser author,
  DriveItemView item, {
  List<int> mentions = const [],
}) => endpoints.comment.createThread(
  author.endpointSession,
  const Uuid().v7obj(),
  item.uuid,
  CommentAnchorKind.textRange,
  '{"v":1}',
  'quoted',
  'Hello',
  mentions,
  null,
);

void main() {
  withWonkyServerpod('Given users who share nothing', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late TestUser stranger;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      stranger = await TestUsers.create(sessionBuilder, name: 'Stranger');
      final doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
    });

    test('when Anna looks up users by id then only she and the people she '
        'shares with are returned', () async {
      final users = await endpoints.user.getUsers(anna.endpointSession, [
        anna.id,
        bo.id,
        stranger.id,
      ]);

      expect(users.map((u) => u.id), unorderedEquals([anna.id, bo.id]));
    });

    test(
      'when the stranger looks up Anna by id then nothing is returned',
      () async {
        final users = await endpoints.user.getUsers(stranger.endpointSession, [
          anna.id,
        ]);

        expect(users, isEmpty);
      },
    );

    test('when Anna mentions the stranger in a comment then the mention is '
        'dropped and the stranger is not revealed', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Plan');

      final thread = await _thread(
        endpoints,
        anna,
        doc,
        mentions: [bo.id, stranger.id],
      );

      expect(thread.comments.single.mentions.map((m) => m.id), [bo.id]);
    });

    test(
      'when a comment mentions too many people then it is refused',
      () async {
        final doc = await TestDrive.document(endpoints, anna, name: 'Plan');

        await expectLater(
          _thread(
            endpoints,
            anna,
            doc,
            mentions: [for (var i = 1; i <= 51; i++) i],
          ),
          _throwsCode(WonkyErrorCode.invalidArgument),
        );
      },
    );

    test(
      'when Anna gives the stranger a role by id then it is refused',
      () async {
        final doc = await TestDrive.document(endpoints, anna, name: 'Secret');

        await expectLater(
          endpoints.sharing.updateRole(
            anna.endpointSession,
            doc.uuid,
            stranger.id,
            AccessRole.editor,
          ),
          _throwsCode(WonkyErrorCode.notFound),
        );
      },
    );

    test('when Anna gives a role by id to a contact without access then it '
        'is refused (share instead)', () async {
      final shared = await TestDrive.document(endpoints, anna, name: 'Shared');
      final contact = await TestUsers.create(sessionBuilder, name: 'Carl');
      await TestDrive.share(
        endpoints,
        shared,
        anna,
        contact,
        AccessRole.viewer,
      );
      final secret = await TestDrive.document(endpoints, anna, name: 'Secret');

      await expectLater(
        endpoints.sharing.updateRole(
          anna.endpointSession,
          secret.uuid,
          contact.id,
          AccessRole.editor,
        ),
        _throwsCode(WonkyErrorCode.invalidArgument),
      );
    });

    test(
      'when Anna offers ownership to the stranger then it is refused',
      () async {
        final doc = await TestDrive.document(endpoints, anna, name: 'Secret');

        await expectLater(
          endpoints.sharing.transferOwnership(
            anna.endpointSession,
            doc.uuid,
            stranger.id,
          ),
          _throwsCode(WonkyErrorCode.notFound),
        );
      },
    );

    test('when Anna offers ownership to Bo, who she shares with, then the '
        'offer is made', () async {
      final doc = await TestDrive.document(endpoints, anna, name: 'Mine');

      final info = await endpoints.sharing.transferOwnership(
        anna.endpointSession,
        doc.uuid,
        bo.id,
      );

      expect(info.pendingTransfer, isNotNull);
    });
  });

  withWonkyServerpod('Given a document someone asks access to', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    setUp(() async {
      SharingService.resetLimits();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna);
    });

    Future<int> requestsNotified() async {
      final page = await endpoints.notification.list(
        anna.endpointSession,
        null,
        50,
        false,
      );
      return page.items
          .where((n) => n.kind == NotificationKind.accessRequest)
          .length;
    }

    test('when Bo asks twice then the owner is notified once', () async {
      for (var i = 0; i < 2; i++) {
        await endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.viewer,
          'Please',
        );
      }

      expect(await requestsNotified(), 1);
    });

    test(
      'when Bo asks for a higher role then the owner is notified again',
      () async {
        await endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.viewer,
          null,
        );
        await endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.editor,
          null,
        );

        expect(await requestsNotified(), 2);
      },
    );

    test('when Bo asks too often then he is rate limited', () async {
      for (var i = 0; i < 5; i++) {
        await endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.viewer,
          null,
        );
      }

      await expectLater(
        endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.viewer,
          null,
        ),
        _throwsCode(WonkyErrorCode.limitExceeded),
      );
    });

    test('when the message is too long then the request is refused', () async {
      await expectLater(
        endpoints.sharing.requestAccess(
          bo.endpointSession,
          doc.uuid,
          AccessRole.viewer,
          'x' * (SharingService.maxRequestMessage + 1),
        ),
        _throwsCode(WonkyErrorCode.invalidArgument),
      );
    });
  });

  withWonkyServerpod('Given a viewer of a document with hidden comments', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna, markdown: 'Text');
      await _thread(endpoints, anna, doc);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
    });

    Future<List<CommentThreadView>> threadsOfCopy(TestUser who) async {
      final copy = await endpoints.drive.copy(
        who.endpointSession,
        doc.uuid,
        'Copy',
        null,
        true,
        false,
      );
      return endpoints.comment.listThreads(
        who.endpointSession,
        copy.uuid,
        CommentFilter.all,
      );
    }

    test(
      'when the viewer copies it with comments then the copy has none',
      () async {
        expect(await threadsOfCopy(bo), isEmpty);
      },
    );

    test('when viewers may see comments then the copy has them', () async {
      await endpoints.sharing.updateSettings(
        anna.endpointSession,
        doc.uuid,
        ItemSharingSettings(
          editorsCanShare: true,
          nonEditorsCanExport: true,
          viewersSeeComments: true,
        ),
      );

      expect(await threadsOfCopy(bo), hasLength(1));
    });
  });

  withWonkyServerpod('Given a viewer copying a file into a folder they can\'t '
      'edit', (sessionBuilder, endpoints) {
    test('when the copy is refused then no bytes are left behind', () async {
      TestFiles.skipPreviews();
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final folder = await TestDrive.folder(endpoints, anna);
      final file = await TestFiles.upload(
        endpoints,
        anna,
        bytes: utf8.encode('data'),
        parentUuid: folder.uuid,
      );
      await TestDrive.share(endpoints, folder, anna, bo, AccessRole.viewer);

      await expectLater(
        endpoints.drive.copy(
          bo.endpointSession,
          file.uuid,
          'Copy',
          folder.uuid,
          false,
          false,
        ),
        _throwsCode(WonkyErrorCode.forbidden),
      );
      final rows = await bo.session.db.unsafeQuery(
        'SELECT count(*) FROM serverpod_cloud_storage WHERE path LIKE @p',
        parameters: QueryParameters.named({
          'p': 'drive/${bo.authUserId.uuid}/%',
        }),
      );
      expect(rows.first.first, 0);
    });
  });

  withWonkyServerpod('Given signed-out feedback', (sessionBuilder, endpoints) {
    test(
      'when one client sends too many reports then it is rate limited',
      () async {
        FeedbackLimits.limiter.reset();
        final anonymous = TestUsers.unauthenticated(sessionBuilder);
        final report = FeedbackSubmission(
          kind: FeedbackKind.errorReport,
          message: 'Boom',
          app: 'write',
          appVersion: '1',
          platform: 'web',
        );
        for (var i = 0; i < FeedbackLimits.anonymousPerHour; i++) {
          await endpoints.feedback.reportError(anonymous, report);
        }

        await expectLater(
          endpoints.feedback.reportError(anonymous, report),
          _throwsCode(WonkyErrorCode.limitExceeded),
        );
        FeedbackLimits.limiter.reset();
      },
    );
  });
}
