import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A fake Gemini API for `DartanticAiClient(httpClient: …)`: replies to
/// `streamGenerateContent?alt=sse` with queued SSE responses and records
/// the request bodies.
class FakeGeminiApi {
  final List<Map<String, Object?>> requests = [];
  final List<http.Response> _replies = [];

  late final http.Client client = MockClient((r) async {
    requests.add((jsonDecode(r.body) as Map).cast<String, Object?>());
    if (_replies.isEmpty) {
      return http.Response('{"error":{"code":500,"message":"no reply"}}', 500);
    }
    return _replies.removeAt(0);
  });

  /// Queues a text answer.
  void text(String text) => _replies.add(
    sse([
      candidate([
        {'text': text},
      ]),
    ]),
  );

  /// Queues a function call with a thought signature (as Gemini 3 sends
  /// it).
  void call(String name, Map<String, Object?> args) => _replies.add(
    sse([
      candidate([
        {
          'functionCall': {'name': name, 'args': args},
          'thoughtSignature': base64Encode([1, 2, 3, 4, 5]),
        },
      ]),
    ]),
  );

  /// The `contents` of request [i].
  List<Map<String, Object?>> contents(int i) => [
    for (final c in requests[i]['contents']! as List)
      (c as Map).cast<String, Object?>(),
  ];

  static http.Response sse(List<Map<String, Object?>> chunks) => http.Response(
    [for (final c in chunks) 'data: ${jsonEncode(c)}\r\n\r\n'].join(),
    200,
    headers: {'content-type': 'text/event-stream'},
  );

  static Map<String, Object?> candidate(
    List<Map<String, Object?>> parts, {
    String finish = 'STOP',
  }) => {
    'candidates': [
      {
        'content': {'role': 'model', 'parts': parts},
        'finishReason': finish,
      },
    ],
    'usageMetadata': {'promptTokenCount': 10, 'candidatesTokenCount': 5},
  };
}
