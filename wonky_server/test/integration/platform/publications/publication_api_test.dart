@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/web/routes/publication_api_route.dart';

import '../../../support/publications/publication_harness.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a submitted story and the publication API', (
    sessionBuilder,
    endpoints,
  ) {
    final h = PublicationHarness();
    final client = HttpClient();
    late Uri base;
    late TestUser owner;
    late TestUser anna;
    late TestPublication pub;
    late UuidValue doc;
    late String submissionId;

    setUpAll(() async {
      final pod = sessionBuilder.build().serverpod;
      pod.webServer.addRoute(PublicationApiRoute(pod: pod), '/api/pub/v1/**');
      if (!pod.webServer.running) await pod.webServer.start();
      base = Uri.parse('http://localhost:${pod.webServer.port}/api/pub/v1/');
    });
    tearDownAll(() => client.close(force: true));

    setUp(() async {
      h.install();
      owner = await TestUsers.create(sessionBuilder, name: 'Owner');
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      pub = await h.create(endpoints, owner);
      doc = await h.start(endpoints, anna, pub);
      final view = await endpoints.submission.submit(
        anna.endpointSession,
        doc,
        PublicationHarness.values(title: 'Faster CI'),
        false,
      );
      submissionId = view.id;
      h.blog.received.clear();
    });
    tearDown(h.uninstall);

    Future<(int, Map<String, Object?>)> call(
      String method,
      String path, {
      Object? body,
      String? key,
    }) async {
      final req = await client.openUrl(method, base.resolve(path));
      final k = key ?? pub.apiKey;
      if (k.isNotEmpty) req.headers.set('authorization', 'Bearer $k');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close();
      final text = await utf8.decodeStream(res);
      final json = text.isEmpty ? <String, Object?>{} : jsonDecode(text);
      return (
        res.statusCode,
        json is Map ? json.cast<String, Object?>() : <String, Object?>{},
      );
    }

    test(
      'when calling without a key or with a wrong one then it is 401',
      () async {
        final (none, _) = await call('GET', 'submissions', key: '');
        final (wrong, body) = await call(
          'GET',
          'submissions',
          key: 'wpk_${'a' * 40}',
        );

        expect(none, 401);
        expect(wrong, 401);
        expect(body['error'], 'unauthorized');
      },
    );

    test('when listing then the submission is there in review', () async {
      final (status, body) = await call('GET', 'submissions');

      final list = body['submissions']! as List;
      expect(status, 200);
      expect((list.single as Map)['id'], submissionId);
      expect((list.single as Map)['status'], 'inReview');
      expect((list.single as Map)['title'], 'Faster CI');
      expect(body['next'], isNull);
    });

    test('when reading the content then it is the webhook body', () async {
      final (status, body) = await call(
        'GET',
        'submissions/$submissionId/content?sequence=1',
      );

      expect(status, 200);
      expect(body['type'], 'submission.submitted');
      expect(body['sequence'], 1);
    });

    test(
      'when requesting changes with a message then the contributor sees '
      'it in a thread under the publication\'s name and is notified',
      () async {
        final (status, body) = await call(
          'POST',
          'submissions/$submissionId/status',
          body: {'status': 'changesRequested', 'message': 'Add an intro.'},
        );

        final view = await endpoints.submission.get(anna.endpointSession, doc);
        final threads = await endpoints.comment.listThreads(
          anna.endpointSession,
          doc,
          CommentFilter.all,
        );
        final notes = await UserNotification.db.find(
          sessionBuilder.build(),
          where: (t) =>
              t.userId.equals(anna.id) &
              t.kind.equals(NotificationKind.submission),
        );
        expect(status, 200);
        expect(body['status'], 'changesRequested');
        expect(view!.status, SubmissionStatus.changesRequested);
        expect(view.lastMessage, contains('Add an intro.'));
        final thread = threads.singleWhere(
          (t) => t.uuid == view.feedbackThreadUuid,
        );
        expect(thread.comments.single.authorLabel, 'Serverpod blog');
        expect(thread.comments.single.body, contains('**Changes requested**'));
        expect(notes, hasLength(1));
      },
    );

    test('when the contributor replies in the thread then the blog gets '
        'comment.created', () async {
      await call(
        'POST',
        'submissions/$submissionId/messages',
        body: {'body': 'Thanks, reading it now.'},
      );
      final view = await endpoints.submission.get(anna.endpointSession, doc);

      await endpoints.comment.reply(
        anna.endpointSession,
        view!.feedbackThreadUuid!,
        'Great, thanks!',
        [],
      );
      await h.deliverScheduled(sessionBuilder);

      final hook = h.blog.ofType('comment.created').single;
      final comment = hook.json['comment']! as Map;
      expect(pub.signed(hook), isTrue);
      expect(comment['body'], 'Great, thanks!');
      expect((comment['author']! as Map)['isModerator'], isFalse);
    });

    test('when publishing without a URL then it is 400, with one 200 and the '
        'URL is shown', () async {
      final (bad, _) = await call(
        'POST',
        'submissions/$submissionId/status',
        body: {'status': 'published'},
      );
      final (ok, body) = await call(
        'POST',
        'submissions/$submissionId/status',
        body: {
          'status': 'published',
          'publicUrl': 'https://blog.example.com/posts/faster-ci',
        },
      );

      final view = await endpoints.submission.get(anna.endpointSession, doc);
      expect(bad, 400);
      expect(ok, 200);
      expect(body['publicUrl'], 'https://blog.example.com/posts/faster-ci');
      expect(view!.publicUrl, 'https://blog.example.com/posts/faster-ci');
    });

    test('when changing a declined story then it is 409', () async {
      await call(
        'POST',
        'submissions/$submissionId/status',
        body: {'status': 'declined'},
      );

      final (status, body) = await call(
        'POST',
        'submissions/$submissionId/status',
        body: {'status': 'changesRequested'},
      );

      expect(status, 409);
      expect(body['error'], 'invalidTransition');
    });

    test('when the story was withdrawn then a status call is 410', () async {
      await endpoints.submission.withdraw(anna.endpointSession, doc);

      final (status, _) = await call(
        'POST',
        'submissions/$submissionId/status',
        body: {'status': 'declined'},
      );

      expect(status, 410);
    });

    test('when another publication\'s key is used then the submission is '
        'not found', () async {
      final other = await h.create(
        endpoints,
        owner,
        input: PublicationHarness.input(name: 'Other blog'),
      );

      final (status, _) = await call(
        'GET',
        'submissions/$submissionId',
        key: other.apiKey,
      );

      expect(status, 404);
    });

    test('when an asset was never submitted then it is 404', () async {
      final (status, _) = await call(
        'GET',
        'assets/ast_${const Uuid().v7()}',
      );

      expect(status, 404);
    });

    test(
      'when the contributor is blocked then submitting is refused',
      () async {
        final (status, _) = await call(
          'POST',
          'blocks',
          body: {'wonkyUserId': anna.authUserId.uuid},
        );

        expect(status, 200);
        await expectLater(
          endpoints.submission.submit(
            anna.endpointSession,
            doc,
            PublicationHarness.values(),
            false,
          ),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test('when the API key is rotated then the old key is refused', () async {
      await endpoints.publication.createApiKey(
        owner.endpointSession,
        pub.publicId,
      );

      final (status, _) = await call('GET', 'submissions');

      expect(status, 401);
    });
  });

  withWonkyServerpod('Given a publication owner', (sessionBuilder, endpoints) {
    final h = PublicationHarness();
    late TestUser owner;
    late TestUser bo;
    late TestPublication pub;

    setUp(() async {
      h.install();
      owner = await TestUsers.create(sessionBuilder, name: 'Owner');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      pub = await h.create(endpoints, owner);
    });
    tearDown(h.uninstall);

    test('when creating with an http webhook then it is refused', () async {
      await expectLater(
        endpoints.publication.create(
          owner.endpointSession,
          PublicationHarness.input(webhookUrl: 'http://blog.example.com/hook'),
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when someone else updates it then it is not found', () async {
      await expectLater(
        endpoints.publication.update(
          bo.endpointSession,
          pub.publicId,
          PublicationHarness.input(),
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.notFound,
          ),
        ),
      );
    });

    test('when the site lists the publication then verify marks it verified '
        'and contributors see the site host', () async {
      h.blog.pages['https://blog.example.com/.well-known/wonky-publications.json'] =
          jsonEncode({
            'publications': [pub.publicId],
          });

      final result = await endpoints.publication.verify(
        owner.endpointSession,
        pub.publicId,
      );
      final card = await endpoints.publication.resolve(
        bo.endpointSession,
        pub.publicId,
      );

      expect(result.ok, isTrue);
      expect(result.settings.verifiedHost, 'blog.example.com');
      expect(card.verified, isTrue);
    });

    test('when the site doesn\'t list it then verify explains why', () async {
      final result = await endpoints.publication.verify(
        owner.endpointSession,
        pub.publicId,
      );

      expect(result.ok, isFalse);
      expect(result.message, contains('404'));
    });

    test(
      'when the secret is rotated then webhooks carry both signatures',
      () async {
        final rotated = await endpoints.publication.rotateSecret(
          owner.endpointSession,
          pub.publicId,
        );

        final test = await endpoints.publication.sendTest(
          owner.endpointSession,
          pub.publicId,
        );

        final hook = h.blog.ofType('publication.ping').last;
        expect(test.ok, isTrue);
        expect(pub.signed(hook), isTrue);
        expect(
          TestPublication(pub.publicId, rotated.secret, '').signed(hook),
          isTrue,
        );
      },
    );

    test('when the blog answers 500 then send test reports it and the '
        'delivery is listed', () async {
      h.blog.status = 500;

      final result = await endpoints.publication.sendTest(
        owner.endpointSession,
        pub.publicId,
      );
      final deliveries = await endpoints.publication.deliveries(
        owner.endpointSession,
        pub.publicId,
      );

      expect(result.ok, isFalse);
      expect(result.message, 'HTTP 500');
      expect(deliveries.first.lastStatus, 500);
    });
  });
}
