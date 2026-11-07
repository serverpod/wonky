@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/config/wonky_config.dart';
import 'package:wonky_server/src/platform/notifications/email/email_sender.dart';
import 'package:wonky_server/src/platform/notifications/notification_service.dart';
import 'package:wonky_server/src/platform/sharing/share_email_service.dart';

import '../../support/fake_email_sender.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<void> _settings(
  TestEndpoints endpoints,
  TestUser user,
  Map<String, Object?> settings,
) => endpoints.user.updatePreferences(
  user.endpointSession,
  UserPreferencesPatch(notificationSettings: jsonEncode(settings)),
);

Future<SharingInfo> _share(
  TestEndpoints endpoints,
  TestUser owner,
  DriveItemView item,
  List<String> emails, {
  AccessRole role = AccessRole.commenter,
  bool sendEmail = true,
  String? message,
}) => endpoints.sharing.share(
  owner.endpointSession,
  item.uuid,
  emails,
  role,
  sendEmail,
  message,
  null,
);

void main() {
  withWonkyServerpod('Given a share with Send an email (specs/06 §4)', (
    sessionBuilder,
    endpoints,
  ) {
    late FakeEmailSender mail;
    late TestUser anna;
    late TestUser bo;
    late DriveItemView doc;
    late Future<void> Function(Session, int) originalShared;
    late Future<void> Function(Session, int, String?) originalInvite;

    setUp(() async {
      mail = FakeEmailSender();
      NotificationService.emailSender = mail;
      originalShared = ShareEmailService.scheduleShared;
      originalInvite = ShareEmailService.scheduleInvite;
      // Run the future calls inline (specs/15 §6: call the job directly).
      ShareEmailService.scheduleShared = (session, id) =>
          ShareEmailService.sendShared(session, id);
      ShareEmailService.scheduleInvite = (session, id, message) =>
          ShareEmailService.sendInvite(session, id, message);
      ShareEmailService.resetLimits();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      doc = await TestDrive.document(endpoints, anna, name: 'Plan');
    });

    tearDown(() {
      NotificationService.emailSender = null;
      ShareEmailService.scheduleShared = originalShared;
      ShareEmailService.scheduleInvite = originalInvite;
      ShareEmailService.resetLimits();
      WonkyConfig.current = WonkyConfig();
    });

    test('when Anna shares with Bo then Bo gets one email right away with '
        'the role, the message and a link, and a notification', () async {
      await _share(endpoints, anna, doc, [bo.email], message: 'Have a look');

      final email = mail.to(bo.email).single;
      expect(email.category, 'share');
      expect(email.subject, 'Anna shared “Plan” with you');
      expect(email.text, contains('You can view and comment on it.'));
      expect(email.text, contains('> Have a look'));
      expect(email.text, contains('/write/d/${doc.uuid.uuid}'));
      expect(email.html, contains('Have a look'));
      expect(email.html, contains('/write/d/${doc.uuid.uuid}'));
      final page = await endpoints.notification.list(
        bo.endpointSession,
        null,
        30,
        false,
      );
      expect(page.items.single.kind, NotificationKind.shared);
    });

    test('when an email went out then it names no other address than the '
        'recipient’s', () async {
      final cleo = await TestUsers.create(sessionBuilder, name: 'Cleo');

      await _share(endpoints, anna, doc, [
        bo.email,
        cleo.email,
        'dana@example.test',
      ]);

      expect(mail.sent, hasLength(3));
      for (final email in mail.sent) {
        final others = {
          anna.email,
          bo.email,
          cleo.email,
          'dana@example.test',
        }..remove(email.to);
        for (final address in others) {
          expect(email.text, isNot(contains(address)));
          expect(email.html, isNot(contains(address)));
        }
      }
    });

    test('when Bo has shares set to email then the digest does not email '
        'the share again', () async {
      await _settings(endpoints, bo, {'shares': 'email'});
      await _share(endpoints, anna, doc, [bo.email]);

      final digests = await NotificationService.sendDigests(
        sessionBuilder.build(),
      );

      expect(digests, 0);
      expect(mail.to(bo.email), hasLength(1));
    });

    test('when Bo turned shares off then he gets no email and no '
        'notification', () async {
      await _settings(endpoints, bo, {'shares': 'off'});

      final info = await _share(endpoints, anna, doc, [bo.email]);

      expect(mail.sent, isEmpty);
      expect(info.permissions.single.user?.id, bo.id);
      final page = await endpoints.notification.list(
        bo.endpointSession,
        null,
        30,
        false,
      );
      expect(page.items, isEmpty);
    });

    test('when Send an email is off then nobody gets an email or a '
        'notification', () async {
      await _share(endpoints, anna, doc, [
        bo.email,
        'dana@example.test',
      ], sendEmail: false);

      expect(mail.sent, isEmpty);
      final page = await endpoints.notification.list(
        bo.endpointSession,
        null,
        30,
        false,
      );
      expect(page.items, isEmpty);
    });

    test(
      'when Bo already had access then a role change sends no email',
      () async {
        await _share(endpoints, anna, doc, [bo.email], sendEmail: false);

        await _share(endpoints, anna, doc, [bo.email], role: AccessRole.editor);

        expect(mail.sent, isEmpty);
      },
    );

    test('when the provider fails then the digest sends the share later if '
        'Bo has shares set to email', () async {
      await _settings(endpoints, bo, {'shares': 'email'});
      mail.failWith = const EmailDeliveryException('down', statusCode: 503);
      await _share(endpoints, anna, doc, [bo.email]);
      mail.failWith = null;

      final digests = await NotificationService.sendDigests(
        sessionBuilder.build(),
      );

      expect(digests, 1);
      expect(
        mail.to(bo.email).single.subject,
        'Anna shared “Plan” with you (commenter)',
      );
    });

    group('to an address without an account', () {
      test('when Anna shares a document then the address gets an invitation '
          'that signs up and comes back to it', () async {
        await _share(endpoints, anna, doc, [
          'Dana@Example.test',
        ], message: 'Join us');

        final email = mail.to('dana@example.test').single;
        expect(email.category, 'invite');
        expect(email.subject, 'Anna invited you to “Plan” on Wonky Work');
        expect(email.text, contains('this address (dana@example.test)'));
        expect(email.text, contains('> Join us'));
        final link = Uri.parse(
          RegExp(r'Sign up and open it: (\S+)').firstMatch(email.text)![1]!,
        );
        expect(link.path, '/write/signup');
        expect(link.queryParameters['next'], '/d/${doc.uuid.uuid}');
        expect(email.html, contains('Sign up and open'));
      });

      test('when Anna shares a spreadsheet then the invitation signs up in '
          'Wonky Sheets', () async {
        final sheet = await endpoints.drive.createSpreadsheet(
          anna.endpointSession,
          null,
          'Budget',
          null,
        );

        await _share(endpoints, anna, sheet, ['dana@example.test']);

        final link = Uri.parse(
          RegExp(
            r'Sign up and open it: (\S+)',
          ).firstMatch(mail.sent.single.text)![1]!,
        );
        expect(link.path, '/sheets/signup');
        expect(link.queryParameters['next'], '/s/${sheet.uuid.uuid}');
      });

      test('when the address is invited again then no second invitation is '
          'sent', () async {
        await _share(endpoints, anna, doc, ['dana@example.test']);

        await _share(endpoints, anna, doc, [
          'dana@example.test',
        ], role: AccessRole.editor);

        expect(mail.sent, hasLength(1));
      });

      test('when the invite was removed before the email went out then '
          'nothing is sent', () async {
        final scheduled = <int>[];
        ShareEmailService.scheduleInvite = (_, id, _) async =>
            scheduled.add(id);
        await _share(endpoints, anna, doc, ['dana@example.test']);
        await endpoints.sharing.remove(
          anna.endpointSession,
          doc.uuid,
          null,
          invitedEmail: 'dana@example.test',
        );

        final sent = await ShareEmailService.sendInvite(
          sessionBuilder.build(),
          scheduled.single,
          null,
        );

        expect(sent, isFalse);
        expect(mail.sent, isEmpty);
      });
    });

    group('and an allowance of 2 invitations an hour', () {
      setUp(() {
        WonkyConfig.current = WonkyConfig(inviteEmailsPerHour: 2);
      });

      test('when Anna invites 3 new addresses at once then the share is '
          'refused and nothing changes', () async {
        await expectLater(
          _share(endpoints, anna, doc, [
            'a@example.test',
            'b@example.test',
            'c@example.test',
          ]),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.limitExceeded,
            ),
          ),
        );

        final info = await endpoints.sharing.getSharing(
          anna.endpointSession,
          doc.uuid,
        );
        expect(info.permissions, isEmpty);
        expect(mail.sent, isEmpty);
      });

      test('when the allowance is used up then the next invitation is '
          'refused but sharing without an email still works', () async {
        await _share(endpoints, anna, doc, [
          'a@example.test',
          'b@example.test',
        ]);

        await expectLater(
          _share(endpoints, anna, doc, ['c@example.test']),
          throwsA(isA<WonkyException>()),
        );
        await _share(endpoints, anna, doc, [
          'c@example.test',
        ], sendEmail: false);

        expect(mail.sent.map((e) => e.to), [
          'a@example.test',
          'b@example.test',
        ]);
      });

      test('when the allowance is used up then sharing with existing users '
          'still emails them', () async {
        await _share(endpoints, anna, doc, [
          'a@example.test',
          'b@example.test',
        ]);

        await _share(endpoints, anna, doc, [bo.email]);

        expect(mail.to(bo.email), hasLength(1));
      });

      test('when Bo invites then he has his own allowance', () async {
        await _share(endpoints, anna, doc, [
          'a@example.test',
          'b@example.test',
        ]);
        final mine = await TestDrive.document(endpoints, bo, name: 'Mine');

        await _share(endpoints, bo, mine, ['c@example.test']);

        expect(mail.to('c@example.test'), hasLength(1));
      });
    });

    test('when invitation emails are turned off in the config then the '
        'invite is created without an email', () async {
      WonkyConfig.current = WonkyConfig(inviteEmailsPerDay: 0);

      final info = await _share(endpoints, anna, doc, ['dana@example.test']);

      expect(info.permissions.single.invitedEmail, 'dana@example.test');
      expect(mail.sent, isEmpty);
    });

    group('with markup in the name and the message', () {
      setUp(() async {
        await endpoints.user.updateProfile(
          anna.endpointSession,
          displayName: 'Anna <b>Admin</b>',
        );
      });

      test('when Bo gets the email then the HTML escapes both', () async {
        await _share(
          endpoints,
          anna,
          doc,
          [bo.email],
          message: '<script>alert(1)</script>\n<a href="https://evil">x</a>',
        );

        final email = mail.to(bo.email).single;
        expect(email.html, isNot(contains('<script>')));
        expect(email.html, isNot(contains('<b>Admin')));
        expect(email.html, isNot(contains('href="https://evil"')));
        expect(email.html, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
        expect(email.html, contains('Anna &lt;b&gt;Admin&lt;/b&gt;'));
        expect(email.text, contains('> <script>alert(1)</script>'));
      });

      test('when an invitation goes out then the HTML escapes both', () async {
        await _share(endpoints, anna, doc, [
          'dana@example.test',
        ], message: '<img src=x onerror=alert(1)>');

        final email = mail.sent.single;
        expect(email.html, isNot(contains('<img')));
        expect(email.html, contains('&lt;img src=x onerror=alert(1)&gt;'));
      });
    });

    test('when the message is longer than 1000 characters then the share is '
        'refused', () async {
      await expectLater(
        _share(endpoints, anna, doc, [bo.email], message: 'x' * 1001),
        throwsA(isA<WonkyException>()),
      );
      expect(mail.sent, isEmpty);
    });

    test('when the name has a line break then the subject stays on one '
        'line', () async {
      await endpoints.user.updateProfile(
        anna.endpointSession,
        displayName: 'Anna\nBcc: x@example.test',
      );

      await _share(endpoints, anna, doc, [bo.email]);

      expect(mail.sent.single.subject, isNot(contains('\n')));
    });
  });
}
