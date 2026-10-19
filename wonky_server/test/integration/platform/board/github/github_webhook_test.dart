@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/github/board_github.dart';
import 'package:wonky_server/src/platform/board/github/github_webhook.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/web/routes/github_webhook_route.dart';

import '../../../../support/wonky_serverpod.dart';
import '../../../../support/board/github_harness.dart';

void main() {
  group('Given the webhook signature check', () {
    final body = utf8.encode('{"zen":"Keep it logically awesome."}');

    test('when the HMAC matches then it is valid', () {
      expect(
        GithubWebhook.verifySignature(
          body: body,
          signatureHeader: GithubHarness.signature(body),
          secret: GithubHarness.secret,
        ),
        isTrue,
      );
    });

    test('when it was made with another secret then it is invalid', () {
      expect(
        GithubWebhook.verifySignature(
          body: body,
          signatureHeader: GithubHarness.signature(body, 'other'),
          secret: GithubHarness.secret,
        ),
        isFalse,
      );
    });

    test('when the body was changed then it is invalid', () {
      expect(
        GithubWebhook.verifySignature(
          body: utf8.encode('{"zen":"changed"}'),
          signatureHeader: GithubHarness.signature(body),
          secret: GithubHarness.secret,
        ),
        isFalse,
      );
    });

    test('when it is missing or uses SHA-1 then it is invalid', () {
      for (final header in [null, '', 'sha1=abc', 'sha256=']) {
        expect(
          GithubWebhook.verifySignature(
            body: body,
            signatureHeader: header,
            secret: GithubHarness.secret,
          ),
          isFalse,
          reason: '$header',
        );
      }
    });
  });

  withWonkyServerpod('Given the GitHub webhook', (sessionBuilder, endpoints) {
    late GithubHarness h;
    late Session session;
    setUp(() {
      h = GithubHarness.install();
      session = sessionBuilder.build();
    });
    tearDown(() => h.uninstall());

    Future<BoardGithubDelivery?> delivery(String id) =>
        BoardGithubDelivery.db.findFirstRow(
          session,
          where: (t) => t.deliveryId.equals(id),
        );

    Map<String, dynamic> payload() => GithubHarness.pullRequest(
      number: GithubHarness.prNumber(),
      body: 'No lines.',
    );

    test('when a signed delivery arrives then it answers 202, stores a '
        'compact payload and schedules the handler', () async {
      final id = 'd-${GithubHarness.sha()}';

      final status = await h.send(
        session,
        'pull_request',
        payload(),
        deliveryId: id,
      );

      final row = await delivery(id);
      expect(status, 202);
      expect(h.deliveries, [id]);
      expect(row?.event, 'pull_request');
      final stored = jsonDecode(row!.payload!) as Map;
      expect(stored.keys, containsAll(['event', 'action', 'repo', 'pr']));
      expect(row.payload, isNot(contains('node_id')));
      expect(h.api.calls, isEmpty);
    });

    test('when the signature is wrong then it answers 401 and stores '
        'nothing', () async {
      final id = 'd-${GithubHarness.sha()}';

      final status = await h.send(
        session,
        'pull_request',
        payload(),
        deliveryId: id,
        signature: 'sha256=${'0' * 64}',
      );

      expect(status, 401);
      expect(await delivery(id), isNull);
      expect(h.deliveries, isEmpty);
    });

    test('when no webhook secret is set then it answers 401', () async {
      GithubWebhook.secretSource = () => null;

      expect(await h.send(session, 'pull_request', payload()), 401);
    });

    test(
      'when the same delivery arrives twice then it is handled once',
      () async {
        final id = 'd-${GithubHarness.sha()}';
        final p = payload();

        final first = await h.send(session, 'pull_request', p, deliveryId: id);
        final second = await h.send(session, 'pull_request', p, deliveryId: id);

        expect([first, second], [202, 202]);
        expect(h.deliveries, [id]);
      },
    );

    test('when a delivery is handled twice then GitHub sees one run', () async {
      final id = 'd-${GithubHarness.sha()}';
      await h.send(session, 'pull_request', payload(), deliveryId: id);

      await BoardGithub.handleDelivery(session, id);
      await BoardGithub.handleDelivery(session, id);

      final row = await delivery(id);
      expect(h.api.runsNamed('Wonky task'), hasLength(1));
      expect(row?.processedAt, isNotNull);
      expect(row?.payload, isNull);
    });

    test('when the integration is disabled then it answers 202 and ignores '
        'the delivery', () async {
      BoardConfig.current = GithubHarness.config(enabled: false);
      final id = 'd-${GithubHarness.sha()}';

      final status = await h.send(
        session,
        'pull_request',
        payload(),
        deliveryId: id,
        signature: 'sha256=bad',
      );

      expect(status, 202);
      expect(await delivery(id), isNull);
      expect(h.deliveries, isEmpty);
    });

    test('when an event of another repository arrives then it is '
        'ignored', () async {
      final p = payload();
      (p['repository'] as Map)['full_name'] = 'someone/else';

      await h.deliver(session, 'pull_request', p);

      expect(h.api.calls, isEmpty);
    });

    test('when an event the App does not handle arrives then it answers 202 '
        'and stores nothing', () async {
      final id = 'd-${GithubHarness.sha()}';

      final status = await h.send(session, 'ping', {
        'zen': 'Design for failure.',
      }, deliveryId: id);

      expect(status, 202);
      expect(await delivery(id), isNull);
    });

    test('when the GitHub headers are missing then it answers 400', () async {
      final body = utf8.encode('{}');

      final status = await GithubWebhook.receive(
        session,
        headers: {'X-Hub-Signature-256': GithubHarness.signature(body)},
        body: body,
      );

      expect(status, 400);
    });

    test('when handling fails then the delivery is retried, then '
        'dropped', () async {
      final id = 'd-${GithubHarness.sha()}';
      await h.send(session, 'check_run', {
        ...GithubHarness.checkRunRerequested(
          name: 'Wonky task',
          headSha: GithubHarness.sha(),
          prNumbers: [GithubHarness.prNumber()],
        ),
      }, deliveryId: id);

      for (var i = 0; i < BoardGithub.maxAttempts; i++) {
        await BoardGithub.handleDelivery(session, id);
      }

      final row = await delivery(id);
      expect(row?.attempts, BoardGithub.maxAttempts);
      expect(row?.processedAt, isNotNull);
      expect(h.deliveries, hasLength(BoardGithub.maxAttempts));
    });

    test('when a delivery was never handled then the sweep schedules it '
        'again, and drops it after the last attempt', () async {
      final id = 'd-${GithubHarness.sha()}';
      final lost = await BoardGithubDelivery.db.insertRow(
        session,
        BoardGithubDelivery(
          deliveryId: id,
          event: 'pull_request',
          payload: '{}',
          receivedAt: clock.now().toUtc().subtract(
            const Duration(hours: 1),
          ),
        ),
      );

      final first = await BoardGithub.rescheduleLost(session);
      await BoardGithubDelivery.db.updateRow(
        session,
        lost.copyWith(attempts: BoardGithub.maxAttempts),
        columns: (t) => [t.attempts],
      );
      await BoardGithub.rescheduleLost(session);

      expect(first, greaterThanOrEqualTo(1));
      expect(h.deliveries.where((d) => d == id), hasLength(1));
      expect((await delivery(id))?.processedAt, isNotNull);
    });

    group('when deliveries are older than 7 days', () {
      test('then the sweep purges them', () async {
        final id = 'd-${GithubHarness.sha()}';
        await BoardGithubDelivery.db.insertRow(
          session,
          BoardGithubDelivery(
            deliveryId: id,
            event: 'pull_request',
            receivedAt: clock.now().toUtc().subtract(
              const Duration(days: 8),
            ),
          ),
        );

        await BoardGithub.sweep(session);

        expect(await delivery(id), isNull);
      });
    });

    group('when a delivery is posted to /api/github/webhook', () {
      late Uri url;
      final client = HttpClient();
      setUpAll(() async {
        final pod = sessionBuilder.build().serverpod;
        pod.webServer.addRoute(GithubWebhookRoute(), '/api/github/webhook');
        if (!pod.webServer.running) await pod.webServer.start();
        url = Uri.parse(
          'http://localhost:${pod.webServer.port}/api/github/webhook',
        );
      });
      tearDownAll(() => client.close(force: true));

      Future<int> post(List<int> body, String signature) async {
        final req = await client.postUrl(url);
        req.headers
          ..set('X-GitHub-Event', 'pull_request')
          ..set('X-GitHub-Delivery', 'd-${GithubHarness.sha()}')
          ..set('X-Hub-Signature-256', signature)
          ..contentType = ContentType.json;
        req.add(body);
        final res = await req.close();
        await res.drain<void>();
        return res.statusCode;
      }

      test('then a signed one is accepted and an unsigned one is '
          'refused', () async {
        final body = utf8.encode(jsonEncode(payload()));

        final ok = await post(body, GithubHarness.signature(body));
        final bad = await post(body, 'sha256=${'f' * 64}');

        expect(ok, 202);
        expect(bad, 401);
        expect(h.deliveries, hasLength(1));
      });

      test('then an unsigned one over the size cap is refused from its '
          'headers (401, not 413: the body is never read)', () async {
        final req = await client.postUrl(url);
        req.headers
          ..set('X-GitHub-Event', 'pull_request')
          ..set('X-GitHub-Delivery', 'd-${GithubHarness.sha()}')
          ..contentType = ContentType.json;
        req.add(List<int>.filled(GithubWebhook.maxBodyBytes + 1, 0x20));
        final res = await req.close();
        await res.drain<void>();

        expect(res.statusCode, 401);
      });
    });

    group('when only the headers are checked', () {
      Map<String, String> headers({
        String? signature = 'sha256=abc',
        String? length,
      }) => {
        'X-GitHub-Event': 'pull_request',
        'X-GitHub-Delivery': 'd-1',
        'X-Hub-Signature-256': ?signature,
        'Content-Length': ?length,
      };

      test('then complete headers pass', () {
        expect(GithubWebhook.precheck(session, headers()), isNull);
      });

      test('then a missing signature answers 401', () {
        expect(GithubWebhook.precheck(session, headers(signature: null)), 401);
      });

      test('then a declared size over the cap answers 413', () {
        expect(
          GithubWebhook.precheck(
            session,
            headers(length: '${GithubWebhook.maxBodyBytes + 1}'),
          ),
          413,
        );
      });

      test('then a disabled integration answers 202', () {
        BoardConfig.current = GithubHarness.config(enabled: false);

        expect(GithubWebhook.precheck(session, headers()), 202);
      });
    });
  });
}
