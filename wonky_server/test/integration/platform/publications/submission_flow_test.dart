@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/publications/publication_webhooks.dart';
import 'package:wonky_server/src/write/content/write_content.dart';
import 'package:wonky_server/src/write/ot/document_store.dart';

import '../../../support/publications/publication_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a publication with a moderator', (
    sessionBuilder,
    endpoints,
  ) {
    final h = PublicationHarness();
    late TestUser owner;
    late TestUser mod;
    late TestUser anna;
    late TestPublication pub;

    setUp(() async {
      h.install();
      owner = await TestUsers.create(sessionBuilder, name: 'Owner');
      mod = await TestUsers.create(sessionBuilder, name: 'Mod');
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      pub = await h.create(endpoints, owner, moderators: [mod]);
    });
    tearDown(h.uninstall);

    test('when a contributor resolves the link then consent is needed and '
        'the unverified card shows the webhook host', () async {
      final card = await endpoints.publication.resolve(
        anna.endpointSession,
        pub.publicId,
      );

      expect(card.name, 'Serverpod blog');
      expect(card.consentNeeded, isTrue);
      expect(card.verified, isFalse);
      expect(card.shownHost, 'blog.example.com');
      expect(card.openSubmissions, isEmpty);
    });

    test('when starting without agreeing then it is refused', () async {
      await expectLater(
        endpoints.publication.startSubmission(
          anna.endpointSession,
          pub.publicId,
          null,
          false,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when starting a story then a document in the contributor\'s drive '
        'has a draft submission and the card lists it', () async {
      final uuid = await h.start(endpoints, anna, pub, ref: 'cfp-2026');

      final item = await endpoints.drive.get(anna.endpointSession, uuid);
      final view = await endpoints.submission.get(anna.endpointSession, uuid);
      final card = await endpoints.publication.resolve(
        anna.endpointSession,
        pub.publicId,
      );
      expect(item.role, AccessRole.owner);
      expect(view!.status, SubmissionStatus.draft);
      expect(view.consentNeeded, isFalse);
      expect(card.consentNeeded, isFalse);
      expect(card.openSubmissions.single.itemUuid, uuid);
      expect(h.blog.received, isEmpty);
    });

    group('and a submitted story', () {
      late UuidValue doc;
      late SubmissionView submitted;

      setUp(() async {
        final tpl = await TestDrive.document(
          endpoints,
          owner,
          name: 'Template',
          markdown: '# Faster CI\n\nWe made it **three** times faster.',
        );
        await endpoints.publication.update(
          owner.endpointSession,
          pub.publicId,
          PublicationHarness.input(templateItemUuid: tpl.uuid),
        );
        doc = await h.start(endpoints, anna, pub, ref: 'cfp-2026');
        submitted = await endpoints.submission.submit(
          anna.endpointSession,
          doc,
          PublicationHarness.values(title: 'Faster CI'),
          false,
        );
      });

      test('then the blog received one signed submission.submitted with the '
          'Markdown and fields', () {
        final hook = h.blog.ofType('submission.submitted').single;
        final json = hook.json;
        final submission = json['submission']! as Map;

        expect(pub.signed(hook), isTrue);
        expect(hook.headers['webhook-id'], startsWith('msg_'));
        expect(json['publicationId'], pub.publicId);
        expect(submission['ref'], 'cfp-2026');
        expect(submission['status'], 'inReview');
        expect(submission['documentUrl'], endsWith('/write/d/${doc.uuid}'));
        expect(json['sequence'], 1);
        expect((json['fields']! as Map)['title'], 'Faster CI');
        expect(json['markdown'], contains('three'));
        expect((json['submittedBy']! as Map)['name'], 'Anna');
      });

      test('then the submission is in review with a named version', () {
        expect(submitted.status, SubmissionStatus.inReview);
        expect(submitted.delivery, isNull);
        expect(submitted.revisions.single.versionId, isNotNull);
      });

      test('then the moderator has comment access', () async {
        final item = await endpoints.drive.get(mod.endpointSession, doc);
        final sharing = await endpoints.sharing.getSharing(
          anna.endpointSession,
          doc,
        );

        expect(item.role, AccessRole.commenter);
        expect(
          sharing.permissions
              .singleWhere((p) => p.user?.id == mod.id)
              .viaPublication,
          'Serverpod blog',
        );
      });

      test(
        'when submitting again without changes then the sequence grows',
        () async {
          await endpoints.submission.submit(
            anna.endpointSession,
            doc,
            PublicationHarness.values(title: 'Faster CI'),
            false,
          );

          final hooks = h.blog.ofType('submission.submitted');
          expect([for (final hk in hooks) hk.json['sequence']], [1, 2]);
        },
      );

      test('when withdrawing then the blog is told and the moderator loses '
          'access', () async {
        final view = await endpoints.submission.withdraw(
          anna.endpointSession,
          doc,
        );
        await h.deliverScheduled(sessionBuilder);

        expect(view.status, SubmissionStatus.withdrawn);
        expect(
          h.blog.ofType('submission.withdrawn').single.json['reason'],
          'author',
        );
        await expectLater(
          endpoints.drive.get(mod.endpointSession, doc),
          throwsA(isA<WonkyException>()),
        );
      });

      test(
        'when the document is trashed then the submission is withdrawn',
        () async {
          await endpoints.drive.trash(anna.endpointSession, [doc]);
          await h.deliverScheduled(sessionBuilder);

          expect(
            h.blog.ofType('submission.withdrawn').single.json['reason'],
            'trashed',
          );
        },
      );

      test('when a commenter tries to submit then it is refused', () async {
        await expectLater(
          endpoints.submission.submit(
            mod.endpointSession,
            doc,
            PublicationHarness.values(),
            false,
          ),
          throwsA(isA<WonkyException>()),
        );
      });

      test('when disconnecting while in review then it is refused', () async {
        await expectLater(
          endpoints.submission.disconnect(anna.endpointSession, doc),
          throwsA(isA<WonkyException>()),
        );
      });
    });

    group('and a blog that is down', () {
      late UuidValue doc;

      setUp(() async {
        doc = await h.start(endpoints, anna, pub);
        h.blog.status = 503;
      });

      test('when submitting then the delivery is pending', () async {
        final view = await endpoints.submission.submit(
          anna.endpointSession,
          doc,
          PublicationHarness.values(),
          false,
        );

        expect(view.status, SubmissionStatus.inReview);
        expect(view.delivery, SubmissionDeliveryState.pending);
      });

      test('when every retry fails then the status goes back to draft and '
          'the submitter is notified', () async {
        await endpoints.submission.submit(
          anna.endpointSession,
          doc,
          PublicationHarness.values(),
          false,
        );
        final session = sessionBuilder.build();
        final d = await PublicationDelivery.db.findFirstRow(
          session,
          where: (t) => t.type.equals('submission.submitted'),
          orderBy: (t) => t.createdAt.desc(),
        );
        for (var i = 0; i < PublicationWebhooks.retryDelays.length; i++) {
          await PublicationDelivery.db.updateRow(
            session,
            (await PublicationDelivery.db.findById(
              session,
              d!.id!,
            ))!.copyWith(leaseUntil: null),
            columns: (t) => [t.leaseUntil],
          );
          await PublicationWebhooks.attempt(session, d.id!);
        }

        final view = await endpoints.submission.get(anna.endpointSession, doc);
        final notes = await UserNotification.db.find(
          session,
          where: (t) =>
              t.userId.equals(anna.id) &
              t.kind.equals(NotificationKind.submission),
        );
        expect(view!.status, SubmissionStatus.draft);
        expect(view.delivery, SubmissionDeliveryState.failed);
        expect(notes, hasLength(1));
      });

      test('when the blog comes back then the sweep delivers it', () async {
        await endpoints.submission.submit(
          anna.endpointSession,
          doc,
          PublicationHarness.values(),
          false,
        );
        h.blog.status = 200;
        final session = sessionBuilder.build();
        await PublicationDelivery.db.updateWhere(
          session,
          columnValues: (t) => [t.nextAttemptAt(DateTime.utc(2000))],
          where: (t) => t.deliveredAt.equals(null),
        );

        await PublicationWebhooks.sweep(session);

        final view = await endpoints.submission.get(anna.endpointSession, doc);
        expect(view!.delivery, isNull);
        expect(view.status, SubmissionStatus.inReview);
      });
    });

    group('and a template document', () {
      test(
        'when starting a story then it starts with the template text',
        () async {
          final tpl = await TestDrive.document(
            endpoints,
            owner,
            name: 'Template',
            markdown: '# Your title\n\nWrite here.',
          );
          await endpoints.publication.update(
            owner.endpointSession,
            pub.publicId,
            PublicationHarness.input(templateItemUuid: tpl.uuid),
          );

          final doc = await h.start(endpoints, anna, pub);

          final session = sessionBuilder.build();
          final item = await DriveItem.db.findFirstRow(
            session,
            where: (t) => t.uuid.equals(doc),
          );
          final content = await DocumentStore.head(
            session,
            (await DocumentStore.byItem(session, item!.id!))!,
          );
          expect(WriteContent.toMarkdown(content), contains('Write here.'));
          expect(item.ownerId, anna.id);
        },
      );
    });
  });
}
