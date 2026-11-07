import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/assistant_history.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/dartantic_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart' show AiProvider;

/// One Gemini `streamGenerateContent?alt=sse` response with [chunks].
http.Response _sse(List<Map<String, Object?>> chunks) => http.Response(
  [for (final c in chunks) 'data: ${jsonEncode(c)}\r\n\r\n'].join(),
  200,
  headers: {'content-type': 'text/event-stream'},
);

Map<String, Object?> _candidate(
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

/// A function call as Gemini 3 sends it: with a thought signature.
Map<String, Object?> _call(String name) => {
  'functionCall': {'name': name, 'args': <String, Object?>{}},
  'thoughtSignature': base64Encode([1, 2, 3, 4]),
};

void main() {
  group('Given a Gemini tool call with a thought signature', () {
    late List<Map<String, Object?>> sent;
    late List<http.Response> replies;
    late DartanticAiClient client;

    setUp(() {
      sent = [];
      replies = [];
      client = DartanticAiClient(
        provider: AiProvider.gemini,
        apiKey: 'test-key-not-used',
        httpClient: MockClient((r) async {
          sent.add((jsonDecode(r.body) as Map).cast<String, Object?>());
          return replies.removeAt(0);
        }),
      );
    });

    AiRequest request(List<ChatMessage> messages) => AiRequest(
      model: 'gemini-3.8-flash',
      messages: messages,
      tools: const [
        AiToolSpec(
          name: 'write_get_outline',
          description: 'Outline',
          inputSchema: {'type': 'object', 'properties': <String, Object?>{}},
        ),
      ],
    );

    final question = ChatMessage(
      role: ChatMessageRole.user,
      parts: const [TextPart('What are the headings?')],
    );

    test(
      'when the tool result is sent in the same run then the request '
      'succeeds and carries the signature',
      () async {
        replies.add(
          _sse([
            _candidate([_call('write_get_outline')]),
          ]),
        );
        final first = await client.send(request([question]));
        final call = first.toolCalls.single;
        replies.add(
          _sse([
            _candidate([
              {'text': 'One heading.'},
            ]),
          ]),
        );

        final second = await client.send(
          request([
            question,
            first.message,
            ChatMessage(
              role: ChatMessageRole.user,
              parts: [
                ToolPart.result(
                  callId: call.callId,
                  toolName: call.toolName,
                  result: '{"headings":[]}',
                ),
              ],
            ),
          ]),
        );

        expect(second.text, 'One heading.');
        final contents = sent.last['contents']! as List;
        final modelTurn = contents[1] as Map;
        final part = (modelTurn['parts'] as List).single as Map;
        expect(part['thoughtSignature'], base64Encode([1, 2, 3, 4]));
      },
    );

    test(
      'when the thread is replayed from storage then the next message '
      'succeeds',
      () async {
        replies.add(
          _sse([
            _candidate([_call('write_get_outline')]),
          ]),
        );
        final first = await client.send(request([question]));
        final call = first.toolCalls.single;
        final names = <String, String>{};
        ChatMessage stored(ChatMessage m, String role) =>
            AssistantHistory.decode(role, AssistantHistory.encode(m), names)!;
        final history = [
          stored(question, 'user'),
          stored(first.message, 'assistant'),
          stored(
            ChatMessage(
              role: ChatMessageRole.user,
              parts: [
                ToolPart.result(
                  callId: call.callId,
                  toolName: call.toolName,
                  result: '{"headings":[]}',
                ),
              ],
            ),
            'user',
          ),
          ChatMessage(
            role: ChatMessageRole.user,
            parts: const [TextPart('And now?')],
          ),
        ];
        replies.add(
          _sse([
            _candidate([
              {'text': 'Still one.'},
            ]),
          ]),
        );

        final next = await client.send(request(history));

        expect(next.text, 'Still one.');
      },
    );

    test(
      'when a text-only answer is replayed from storage then the next '
      'message succeeds',
      () async {
        replies.add(
          _sse([
            _candidate([
              {
                'text': 'Hello.',
                'thoughtSignature': base64Encode([9, 9]),
              },
            ]),
          ]),
        );
        final first = await client.send(request([question]));
        final names = <String, String>{};
        replies.add(
          _sse([
            _candidate([
              {'text': 'Again.'},
            ]),
          ]),
        );

        final next = await client.send(
          request([
            question,
            AssistantHistory.decode(
              'assistant',
              AssistantHistory.encode(first.message),
              names,
            )!,
            ChatMessage(
              role: ChatMessageRole.user,
              parts: const [TextPart('More?')],
            ),
          ]),
        );

        expect(next.text, 'Again.');
      },
    );
  });
}
