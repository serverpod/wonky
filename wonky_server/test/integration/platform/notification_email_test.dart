@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/notifications/email/email_sender.dart';
import 'package:wonky_server/src/platform/notifications/notification_service.dart';

import '../../support/fake_email_sender.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<CommentThreadView> _comment(
  TestEndpoints endpoints,
  TestUser author,
  DriveItemView item, {
  String body = 'Have a look',
  List<int> mentions = const [],
  int? assigneeId,
}) => endpoints.comment.createThread(
  author.endpointSession,
  const Uuid().v7obj(),
  item.uuid,
  CommentAnchorKind.textRange,
  '{"v":1}',
  'quoted',
  body,
  mentions,
  assigneeId,
);

Future<void> _settings(
  TestEndpoints endpoints,
  TestUser user,
  Map<String, Object?> settings,
) => endpoints.user.updatePreferences(
  user.endpointSession,
  UserPreferencesPatch(notificationSettings: jsonEncode(settings)),
);

void main() {
  withWonkyServerpod('Given notification email settings', (
    sessionBuilder,
    endpoints,
  ) {
    late FakeEmailSender mail;
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    late Future<void> Function(Session, int) originalScheduler;

    setUp(() async {
      mail = FakeEmailSender();
      NotificationService.emailSender = mail;
      originalScheduler = NotificationService.scheduleImmediateEmail;
      // Run the future call inline (specs/15 §6: call the job directly).
      NotificationService.scheduleImmediateEmail = (session, id) =>
          NotificationService.sendImmediate(session, id);
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna, name: 'Plan');
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.commenter);
      mail.sent.clear(); // The share notification is in-app by default.
    });

    tearDown(() {
      NotificationService.emailSender = null;
      NotificationService.scheduleImmediateEmail = originalScheduler;
    });

    test('when Bo is mentioned with mentions set to email then Bo gets one '
        'email right away', () async {
      await _settings(endpoints, bo, {'mentions': 'email'});

      await _comment(endpoints, anna, doc, mentions: [bo.id], body: 'Bo?');

      final emails = mail.to(bo.email);
      expect(emails, hasLength(1));
      expect(emails.single.subject, 'Anna mentioned you in “Plan”');
      expect(emails.single.category, 'mention');
      expect(emails.single.text, contains('/write/d/${doc.uuid.uuid}'));
      expect(emails.single.html, contains('Bo?'));
    });

    test(
      'when a mention was emailed then the digest does not repeat it',
      () async {
        await _settings(endpoints, bo, {'mentions': 'email'});
        await _comment(endpoints, anna, doc, mentions: [bo.id]);

        final digests = await NotificationService.sendDigests(
          sessionBuilder.build(),
        );

        expect(digests, 0);
        expect(mail.to(bo.email), hasLength(1));
      },
    );

    test('when Bo is assigned then the email says so', () async {
      await _settings(endpoints, bo, {'mentions': 'email'});

      await _comment(
        endpoints,
        anna,
        doc,
        mentions: [bo.id],
        assigneeId: bo.id,
      );

      expect(
        mail.to(bo.email).single.subject,
        'Anna assigned you a comment in “Plan”',
      );
    });

    test('when mentions are in-app only then no email is sent', () async {
      await _comment(endpoints, anna, doc, mentions: [bo.id]);

      await NotificationService.sendDigests(sessionBuilder.build());

      expect(mail.sent, isEmpty);
    });

    test('when mentions are off then no notification is created', () async {
      await _settings(endpoints, bo, {'mentions': 'off'});

      await _comment(endpoints, anna, doc, mentions: [bo.id]);

      final page = await endpoints.notification.list(
        bo.endpointSession,
        null,
        30,
        false,
      );
      expect(
        page.items.where((n) => n.kind == NotificationKind.mention),
        isEmpty,
      );
    });

    group('and replies set to email', () {
      setUp(() => _settings(endpoints, anna, {'replies': 'email'}));

      test('when Bo replies then nothing is sent until the digest runs, which '
          'sends one digest', () async {
        final thread = await _comment(endpoints, anna, doc);
        await endpoints.comment.reply(
          bo.endpointSession,
          thread.uuid,
          'First reply',
          [],
        );
        await endpoints.comment.reply(
          bo.endpointSession,
          thread.uuid,
          'Second reply',
          [],
        );
        expect(mail.sent, isEmpty);

        final digests = await NotificationService.sendDigests(
          sessionBuilder.build(),
        );

        expect(digests, 1);
        final email = mail.to(anna.email).single;
        expect(email.category, 'digest');
        expect(email.subject, '2 new notifications in Wonky Work');
        expect(email.text, contains('Bo replied to a comment in “Plan”'));
        expect(email.text, contains('Second reply'));
      });

      test(
        'when the digest ran once then the next run sends nothing',
        () async {
          final thread = await _comment(endpoints, anna, doc);
          await endpoints.comment.reply(
            bo.endpointSession,
            thread.uuid,
            'R',
            [],
          );
          await NotificationService.sendDigests(sessionBuilder.build());

          final second = await NotificationService.sendDigests(
            sessionBuilder.build(),
          );

          expect(second, 0);
          expect(mail.to(anna.email), hasLength(1));
        },
      );

      test('when Anna read the notification in the app then it is not '
          'emailed', () async {
        final thread = await _comment(endpoints, anna, doc);
        await endpoints.comment.reply(bo.endpointSession, thread.uuid, 'R', []);
        await endpoints.notification.markAllRead(anna.endpointSession);

        final digests = await NotificationService.sendDigests(
          sessionBuilder.build(),
        );

        expect(digests, 0);
      });

      test(
        'when the provider fails then the digest retries next time',
        () async {
          final thread = await _comment(endpoints, anna, doc);
          await endpoints.comment.reply(
            bo.endpointSession,
            thread.uuid,
            'R',
            [],
          );
          mail.failWith = const EmailDeliveryException('down', statusCode: 503);
          expect(
            await NotificationService.sendDigests(sessionBuilder.build()),
            0,
          );

          mail.failWith = null;
          final retried = await NotificationService.sendDigests(
            sessionBuilder.build(),
          );

          expect(retried, 1);
        },
      );

      test('when the digest is turned off then each reply is emailed right '
          'away', () async {
        await _settings(endpoints, anna, {'replies': 'email', 'digest': false});
        final thread = await _comment(endpoints, anna, doc);

        await endpoints.comment.reply(bo.endpointSession, thread.uuid, 'R', []);

        expect(
          mail.to(anna.email).single.subject,
          'Bo replied to a comment in “Plan”',
        );
      });
    });

    test(
      'when an immediate email fails then the digest sends it later',
      () async {
        await _settings(endpoints, bo, {'mentions': 'email'});
        mail.failWith = const EmailDeliveryException('down');
        await _comment(endpoints, anna, doc, mentions: [bo.id]);
        mail.failWith = null;

        final digests = await NotificationService.sendDigests(
          sessionBuilder.build(),
        );

        expect(digests, 1);
        expect(
          mail.to(bo.email).single.subject,
          'Anna mentioned you in “Plan”',
        );
      },
    );

    test('when access requests are set to email then a request is in the '
        'digest', () async {
      final cleo = await TestUsers.create(sessionBuilder, name: 'Cleo');
      await _settings(endpoints, anna, {'accessRequests': 'email'});

      await endpoints.sharing.requestAccess(
        cleo.endpointSession,
        doc.uuid,
        AccessRole.editor,
        'Please',
      );
      await NotificationService.sendDigests(sessionBuilder.build());

      expect(
        mail.to(anna.email).single.subject,
        'Cleo requests editor access to “Plan”',
      );
    });

    test('when only the legacy shares key is set to email then access '
        'requests follow it', () async {
      final cleo = await TestUsers.create(sessionBuilder, name: 'Cleo');
      await _settings(endpoints, anna, {'shares': 'email'});

      await endpoints.sharing.requestAccess(
        cleo.endpointSession,
        doc.uuid,
        AccessRole.viewer,
        null,
      );
      await NotificationService.sendDigests(sessionBuilder.build());

      expect(mail.to(anna.email), hasLength(1));
    });

    group('(CQ-28)', () {
      final digestBatch = NotificationService.digestBatch;
      tearDown(() => NotificationService.digestBatch = digestBatch);

      test('when another user has many in-app notifications then the digest '
          'still reaches Bo', () async {
        await _settings(endpoints, bo, {'replies': 'email'});
        final thread = await _comment(endpoints, bo, doc);
        // Bo replies three times in Anna's thread (in-app for Anna, who
        // sorts first), Anna once in Bo's (email for Bo).
        final mine = await _comment(endpoints, anna, doc);
        for (var i = 0; i < 3; i++) {
          await endpoints.comment.reply(
            bo.endpointSession,
            mine.uuid,
            'R$i',
            [],
          );
        }
        await endpoints.comment.reply(
          anna.endpointSession,
          thread.uuid,
          'Hi',
          [],
        );
        NotificationService.digestBatch = 1;

        await NotificationService.sendDigests(sessionBuilder.build());

        expect(mail.to(bo.email), hasLength(1));
        expect(mail.to(anna.email), isEmpty);
      });

      test('when the immediate email and the digest run at once then the '
          'mention is emailed once', () async {
        await _settings(endpoints, bo, {'mentions': 'email'});
        final scheduled = <int>[];
        NotificationService.scheduleImmediateEmail = (_, id) async =>
            scheduled.add(id);
        await _comment(endpoints, anna, doc, mentions: [bo.id]);

        await Future.wait([
          NotificationService.sendImmediate(
            sessionBuilder.build(),
            scheduled.single,
          ),
          NotificationService.sendDigests(sessionBuilder.build()),
        ]);

        expect(mail.to(bo.email), hasLength(1));
      });

      test('when old notifications are purged then read ones go after 90 '
          'days and unread ones after a year', () async {
        final session = sessionBuilder.build();
        final now = clock.now().toUtc();
        UserNotification row(int days, {bool read = false}) => UserNotification(
          userId: bo.id,
          kind: NotificationKind.reply,
          payload: '{}',
          createdAt: now.subtract(Duration(days: days)),
          readAt: read ? now : null,
        );
        final rows = await UserNotification.db.insert(session, [
          row(100, read: true),
          row(100),
          row(400),
          row(10, read: true),
        ]);

        await NotificationService.purgeOld(session, now: now);
        final left = await UserNotification.db.find(
          session,
          where: (t) => t.id.inSet(<int>{for (final r in rows) r.id!}),
          orderBy: (t) => t.id,
        );

        expect(left.map((r) => r.id), [rows[1].id, rows[3].id]);
      });
    });
  });
}
