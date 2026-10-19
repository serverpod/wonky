import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart' as jwt;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pointycastle/asn1.dart' as asn1;
import 'package:pointycastle/export.dart' as pc;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/github/github_app_auth.dart';
import 'package:wonky_server/src/platform/board/github/github_client.dart';

/// A 1024-bit RSA key pair from a fixed seed (fast; GitHub uses 2048).
pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey> _keyPair() {
  final random = pc.FortunaRandom()
    ..seed(pc.KeyParameter(Uint8List.fromList(List.generate(32, (i) => i))));
  final generator = pc.RSAKeyGenerator()
    ..init(
      pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.from(65537), 1024, 64),
        random,
      ),
    );
  final pair = generator.generateKeyPair();
  return pc.AsymmetricKeyPair(pair.publicKey, pair.privateKey);
}

/// [key] as a PKCS#1 PEM (`BEGIN RSA PRIVATE KEY`), as GitHub downloads it.
String _pkcs1Pem(pc.RSAPrivateKey key) {
  final p = key.p!;
  final q = key.q!;
  final d = key.privateExponent!;
  final seq = asn1.ASN1Sequence(
    elements: [
      asn1.ASN1Integer(BigInt.zero),
      asn1.ASN1Integer(key.modulus),
      asn1.ASN1Integer(key.publicExponent),
      asn1.ASN1Integer(d),
      asn1.ASN1Integer(p),
      asn1.ASN1Integer(q),
      asn1.ASN1Integer(d % (p - BigInt.one)),
      asn1.ASN1Integer(d % (q - BigInt.one)),
      asn1.ASN1Integer(q.modInverse(p)),
    ],
  );
  final b64 = base64.encode(seq.encode());
  final lines = [
    for (var i = 0; i < b64.length; i += 64)
      b64.substring(i, min(i + 64, b64.length)),
  ];
  return '-----BEGIN RSA PRIVATE KEY-----\n${lines.join('\n')}\n'
      '-----END RSA PRIVATE KEY-----\n';
}

void main() {
  final pair = _keyPair();
  final pem = _pkcs1Pem(pair.privateKey);
  final now = DateTime.utc(2026, 10, 15, 12);
  const installationToken = 'ghs_SECRETinstallationTOKEN123';

  group('Given the App JWT', () {
    test('when signed then it is RS256 with iss, iat 60 s back and exp '
        'within 10 minutes', () {
      final token = GithubAppJwt.fromPem(4242, pem).sign(now);

      final parts = token.split('.');
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      final verified = jwt.JWT.verify(
        token,
        jwt.RSAPublicKey.raw(pair.publicKey),
        checkExpiresIn: false,
      );
      final payload = verified.payload as Map;
      final iat = payload['iat'] as int;
      final exp = payload['exp'] as int;
      final nowSeconds = now.millisecondsSinceEpoch ~/ 1000;
      expect(header['alg'], 'RS256');
      expect(payload['iss'], '4242');
      expect(iat, nowSeconds - 60);
      expect(exp, greaterThan(nowSeconds));
      expect(exp - iat, lessThanOrEqualTo(600));
    });

    test('when the PEM has literal \\n sequences then it still parses', () {
      final oneLine = pem.replaceAll('\n', r'\n');

      expect(() => GithubAppJwt.fromPem(1, oneLine).sign(now), returnsNormally);
    });

    test('when the key is invalid then the error does not echo it', () {
      const bad = '-----BEGIN RSA PRIVATE KEY-----\nTOPSECRETKEYDATA\n';

      expect(
        () => GithubAppJwt.fromPem(1, bad),
        throwsA(
          isA<FormatException>().having(
            (e) => '$e',
            'text',
            isNot(contains('TOPSECRETKEYDATA')),
          ),
        ),
      );
      expect('${GithubAppJwt.fromPem(1, pem)}', isNot(contains('BEGIN')));
    });
  });

  group('Given the GitHub client', () {
    late List<http.Request> requests;
    late List<Duration> sleeps;
    late List<String> logs;
    late http.Response Function(http.Request) api;

    GithubClient client() => GithubClient(
      credentials: () => GithubAppCredentials(
        repository: 'serverpod/wonky',
        jwt: GithubAppJwt.fromPem(4242, pem),
      ),
      httpClient: MockClient((r) async {
        requests.add(r);
        if (r.url.path == '/repos/serverpod/wonky/installation') {
          return http.Response(jsonEncode({'id': 77}), 200);
        }
        if (r.url.path == '/app/installations/77/access_tokens') {
          return http.Response(
            jsonEncode({
              'token': installationToken,
              'expires_at': '2026-10-15T13:00:00Z',
            }),
            201,
          );
        }
        return api(r);
      }),
      sleep: (d) async => sleeps.add(d),
      log: logs.add,
    );

    setUp(() {
      requests = [];
      sleeps = [];
      logs = [];
      api = (_) => http.Response('', 204);
    });

    test('when calling then the JWT gets an installation token which '
        'authorizes the call', () async {
      final c = client();

      final member = await withClock(
        Clock.fixed(now),
        () => c.isOrgMember('serverpod', 'octocat'),
      );

      expect(member, isTrue);
      expect(requests.map((r) => '${r.method} ${r.url.path}'), [
        'GET /repos/serverpod/wonky/installation',
        'POST /app/installations/77/access_tokens',
        'GET /orgs/serverpod/members/octocat',
      ]);
      expect(requests[0].headers['Authorization'], startsWith('Bearer ey'));
      expect(requests[2].headers['Authorization'], 'Bearer $installationToken');
      expect(requests[2].headers['X-GitHub-Api-Version'], '2022-11-28');
    });

    test('when the user is not a member then membership is false', () async {
      api = (_) => http.Response('{"message":"Not Found"}', 404);

      expect(
        await withClock(
          Clock.fixed(now),
          () => client().isOrgMember('serverpod', 'stranger'),
        ),
        isFalse,
      );
    });

    test('when calling again within 50 minutes then the token is reused, '
        'after that it is renewed', () async {
      final c = client();
      Future<void> call(Duration after) => withClock(
        Clock.fixed(now.add(after)),
        () => c.isOrgMember('serverpod', 'octocat'),
      );

      await call(Duration.zero);
      await call(const Duration(minutes: 49));
      await call(const Duration(minutes: 51));

      expect(
        requests.where((r) => r.url.path.endsWith('/access_tokens')),
        hasLength(2),
      );
    });

    test(
      'when rate limited with a reset time then it waits and retries',
      () async {
        var calls = 0;
        final reset = now.add(const Duration(seconds: 20));
        api = (_) => ++calls == 1
            ? http.Response(
                '{"message":"API rate limit exceeded"}',
                403,
                headers: {
                  'x-ratelimit-remaining': '0',
                  'x-ratelimit-reset':
                      '${reset.millisecondsSinceEpoch ~/ 1000}',
                },
              )
            : http.Response('', 204);

        await withClock(
          Clock.fixed(now),
          () => client().isOrgMember('serverpod', 'octocat'),
        );

        expect(sleeps, [const Duration(seconds: 21)]);
        expect(calls, 2);
        expect(logs.single, contains('rate limited'));
      },
    );

    test('when told to retry after longer than it waits then it throws a '
        'rate limit error', () async {
      api = (_) => http.Response('{}', 429, headers: {'retry-after': '3600'});

      await expectLater(
        withClock(
          Clock.fixed(now),
          () => client().isOrgMember('serverpod', 'octocat'),
        ),
        throwsA(isA<GithubRateLimitException>()),
      );
      expect(sleeps, isEmpty);
    });

    test('when a call fails then neither the token nor the JWT appears in '
        'the exception or the logs', () async {
      api = (r) => http.Response(
        jsonEncode({'message': 'Validation Failed', 'echo': r.headers}),
        422,
      );

      Object? error;
      try {
        await withClock(
          Clock.fixed(now),
          () => client().createComment(1, 'hi'),
        );
      } on Object catch (e) {
        error = e;
      }

      expect(error, isA<GithubApiException>());
      final text = '$error ${logs.join(' ')}';
      expect(text, contains('Validation Failed'));
      expect(text, isNot(contains(installationToken)));
      expect(text, isNot(contains('Bearer')));
      expect(text, isNot(contains('PRIVATE KEY')));
    });

    test('when the token was revoked then a 401 renews it once', () async {
      var calls = 0;
      api = (_) => ++calls == 1
          ? http.Response('{"message":"Bad credentials"}', 401)
          : http.Response('', 204);

      await withClock(
        Clock.fixed(now),
        () => client().isOrgMember('serverpod', 'octocat'),
      );

      expect(
        requests.where((r) => r.url.path.endsWith('/access_tokens')),
        hasLength(2),
      );
    });

    test('when comparing commits then the status is returned', () async {
      api = (r) => http.Response(jsonEncode({'status': 'ahead'}), 200);

      final status = await withClock(
        Clock.fixed(now),
        () => client().compareStatus('abc', 'def'),
      );

      expect(status, 'ahead');
      expect(
        requests.last.url.path,
        '/repos/serverpod/wonky/compare/abc...def',
      );
    });

    test('when asking for the diff then the diff media type is used', () async {
      api = (r) => http.Response('diff --git a/x b/x\n', 200);

      final diff = await withClock(
        Clock.fixed(now),
        () => client().getPullRequestDiff(5),
      );

      expect(diff, startsWith('diff --git'));
      expect(requests.last.headers['Accept'], 'application/vnd.github.diff');
    });
  });
}
