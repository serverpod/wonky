import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/board/ai/jev_client.dart';

const _key = 'ts-test-key-0123456789abcdef';

/// A recorded TypeSafe answer (the shape of the API reference).
const _okBody = {
  'model': 'jev-1.13.0',
  'answers': {
    'spam': {'type': 'noul', 'noul': 0.03},
    'kind': {
      'type': 'choice',
      'choice': 'bug',
      'probabilities': {'bug': 0.94, 'idea': 0.06},
      'confidence': 0.88,
    },
  },
  'usage': {'input_tokens': 412, 'output_tokens': 31},
};

final _request = JevRequest(
  state: {
    'post': {'title': 'Crash', 'body': 'It crashes.'},
  },
  questions: {
    'spam': JevQuestion.noul('Is `post` spam?', yes: 'Spam', no: 'Not spam'),
    'kind': JevQuestion.choice('Bug or idea?', {
      'bug': 'Broken',
      'idea': 'New',
    }),
  },
);

http.Response _json(Object body, int status, {Map<String, String>? headers}) =>
    http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json', ...?headers},
    );

void main() {
  late List<http.Request> requests;
  late List<Duration> sleeps;

  HttpJevClient client(List<http.Response> responses) {
    var i = 0;
    return HttpJevClient(
      apiKey: _key,
      model: 'jev-1.13.0',
      httpClient: MockClient((r) async {
        requests.add(r);
        return responses[i < responses.length ? i++ : responses.length - 1];
      }),
      sleep: (d) async => sleeps.add(d),
    );
  }

  setUp(() {
    requests = [];
    sleeps = [];
  });

  group('Given TypeSafe answers 200', () {
    test('when asking then the request is a bearer-authenticated POST with '
        'the pinned model, the state and the questions', () async {
      await client([_json(_okBody, 200)]).ask(_request);

      final r = requests.single;
      expect(r.method, 'POST');
      expect(r.url.toString(), 'https://api.typesafe.ai/v1/systemone');
      expect(r.headers['Authorization'], 'Bearer $_key');
      expect(r.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(r.body), {
        'model': 'jev-1.13.0',
        'state': {
          'post': {'title': 'Crash', 'body': 'It crashes.'},
        },
        'questions': {
          'spam': {
            'type': 'noul',
            'instructions': 'Is `post` spam?',
            'criteria': {'true': 'Spam', 'false': 'Not spam'},
          },
          'kind': {
            'type': 'choice',
            'instructions': 'Bug or idea?',
            'criteria': {'bug': 'Broken', 'idea': 'New'},
          },
        },
      });
    });

    test('when asking then typed answers, usage and the model id come '
        'back', () async {
      final r = await client([_json(_okBody, 200)]).ask(_request);

      expect(r.model, 'jev-1.13.0');
      expect(r.noul('spam'), 0.03);
      expect(r.answers['kind']?.choice, 'bug');
      expect(r.answers['kind']?.confidence, 0.88);
      expect(r.answers['kind']?.probabilities, {'bug': 0.94, 'idea': 0.06});
      expect(r.inputTokens, 412);
      expect(r.outputTokens, 31);
    });
  });

  group('Given TypeSafe is rate limited', () {
    test('when the 429 carries retry-after then the client waits that long '
        'and retries', () async {
      final r = await client([
        _json(
          {
            'error': {'type': 'rate_limited'},
          },
          429,
          headers: {'retry-after': '2'},
        ),
        _json(_okBody, 200),
      ]).ask(_request);

      expect(requests, hasLength(2));
      expect(sleeps, [const Duration(seconds: 2)]);
      expect(r.noul('spam'), 0.03);
    });

    test('when retry-after is an HTTP date then the client waits until '
        'then', () async {
      await withClock(Clock.fixed(DateTime.utc(2026, 10, 21, 7, 28)), () async {
        await client([
          _json(
            const {},
            429,
            headers: {
              'retry-after': 'Wed, 21 Oct 2026 07:28:03 GMT',
            },
          ),
          _json(_okBody, 200),
        ]).ask(_request);
      });

      expect(sleeps, [const Duration(seconds: 3)]);
    });

    test('when retry-after is longer than the time left then it fails '
        'retryable without waiting', () async {
      final call = client([
        _json(const {}, 429, headers: {'retry-after': '20'}),
      ]).ask(_request, timeout: const Duration(seconds: 3));

      await expectLater(
        call,
        throwsA(
          isA<BoardAiException>().having((e) => e.retryable, 'retryable', true),
        ),
      );
      expect(sleeps, isEmpty);
    });
  });

  group('Given TypeSafe is overloaded', () {
    test('when 529 repeats then the client backs off exponentially and '
        'succeeds', () async {
      final r = await client([
        _json(const {}, 529),
        _json(const {}, 529),
        _json(_okBody, 200),
      ]).ask(_request);

      expect(requests, hasLength(3));
      expect(sleeps, [
        const Duration(milliseconds: 250),
        const Duration(milliseconds: 500),
      ]);
      expect(r.model, 'jev-1.13.0');
    });

    test('when 529 never ends then it gives up after four attempts with a '
        'retryable error', () async {
      await expectLater(
        client([_json(const {}, 529)]).ask(_request),
        throwsA(
          isA<BoardAiException>()
              .having((e) => e.retryable, 'retryable', true)
              .having((e) => e.message, 'message', contains('529')),
        ),
      );
      expect(requests, hasLength(4));
      expect(sleeps, hasLength(3));
    });
  });

  group('Given TypeSafe rejects the request', () {
    for (final (status, type) in [
      (401, 'authentication_error'),
      (422, 'validation_error'),
      (400, 'max_tokens_exceeded'),
    ]) {
      test('when it answers $status then it fails once, not retryable, '
          'with the error type and without the key', () async {
        await expectLater(
          client([
            _json({
              'error': {
                'type': type,
                'message': 'Field questions.spam.instructions: Is `post` spam?',
              },
            }, status),
          ]).ask(_request),
          throwsA(
            isA<BoardAiException>()
                .having((e) => e.retryable, 'retryable', false)
                .having((e) => e.message, 'message', contains('$status'))
                .having((e) => e.message, 'message', contains(type))
                .having((e) => e.message, 'message', isNot(contains(_key)))
                .having(
                  (e) => e.message,
                  'message',
                  isNot(contains('Is `post` spam?')),
                ),
          ),
        );
        expect(requests, hasLength(1));
        expect(sleeps, isEmpty);
      });
    }
  });
}
