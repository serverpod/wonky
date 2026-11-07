@Tags(['integration'])
library;

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/assistant_history.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/dartantic_ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/common/time.dart';

import '../../../support/ai/gemini_sse.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

AssistantContextHints _hints() => AssistantContextHints(
  applyMode: AiApplyMode.suggest,
  includeComments: false,
);

/// Chats failed after the first or second message with Gemini (the
/// provider in practice): Gemini 3 sends a thought signature with every
/// tool call, the loop stored it as JSON, and dartantic's Gemini mapper
/// casts it `as List<int>` when the call is replayed. The cast threw for
/// the JSON list, synchronously and outside the provider-error mapping, so
/// the second round of every tool-using run failed with "Something went
/// wrong", and every later message of that thread failed at once.
void main() {
  withWonkyServerpod('Given a document and the assistant on Gemini', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView doc;
    late FakeGeminiApi gemini;

    setUp(() async {
      gemini = FakeGeminiApi();
      AiConfig.current = AiConfig(
        serverKeys: {AiProvider.gemini: 'test-key'},
        dailyTokenBudget: 1000000,
      );
      AiConfig.clientOverride = DartanticAiClient(
        provider: AiProvider.gemini,
        apiKey: 'test-key',
        httpClient: gemini.client,
      );
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      doc = await TestDrive.document(
        endpoints,
        anna,
        name: 'Plan',
        markdown: '# Plan\n\nThe old plan is fine.\n',
      );
    });
    tearDown(() => AiConfig.clientOverride = null);

    Future<List<AssistantEvent>> chat(String message, {int? threadId}) =>
        endpoints.assistant
            .chat(anna.endpointSession, threadId, doc.uuid, message, _hints())
            .toList();

    test(
      'when the model calls a tool and the user sends another message then '
      'both runs finish without an error',
      () async {
        gemini
          ..call('write_get_outline', {})
          ..text('The plan has one heading.')
          ..text('Still one heading.');

        final first = await chat('What are the headings?');
        final second = await chat(
          'And now?',
          threadId: first.first.threadId,
        );

        expect(
          first.where((e) => e.type == AssistantEventType.error),
          isEmpty,
        );
        expect(first.last.text, 'The plan has one heading.');
        expect(
          second.where((e) => e.type == AssistantEventType.error),
          isEmpty,
        );
        expect(second.last.text, 'Still one heading.');
        // The replayed call carries its signature back to Gemini.
        final replayed = gemini
            .contents(2)
            .firstWhere(
              (c) => c['role'] == 'model',
            );
        expect(
          ((replayed['parts']! as List).single as Map)['thoughtSignature'],
          isNotNull,
        );
      },
    );

    test(
      'when Gemini answers with an error then the panel shows a useful '
      'message instead of "Something went wrong"',
      () async {
        final events = await chat('Hello?');

        final error = events.firstWhere(
          (e) => e.type == AssistantEventType.error,
        );
        expect(error.errorCode, isNot('internal'));
        expect(error.error, isNot(contains('Something went wrong')));
      },
    );
  });

  withWonkyServerpod('Given a thread whose last run was interrupted', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView doc;
    late FakeAiModelClient fake;

    setUp(() async {
      fake = FakeAiModelClient();
      AiConfig.current = AiConfig(
        serverKeys: {AiProvider.anthropic: 'test-key'},
        dailyTokenBudget: 1000000,
      );
      AiConfig.clientOverride = fake;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      doc = await TestDrive.document(
        endpoints,
        anna,
        name: 'Plan',
        markdown: '# Plan\n\nText.\n',
      );
    });
    tearDown(() => AiConfig.clientOverride = null);

    test(
      'when the user sends a message then the unanswered tool call gets an '
      '"interrupted" result and the run works',
      () async {
        fake.enqueue((AiScript()..text('Hi.')).response);
        final first = await endpoints.assistant
            .chat(anna.endpointSession, null, doc.uuid, 'Hi', _hints())
            .toList();
        final threadId = first.first.threadId!;
        // A run that stored its tool call and then died (server restart).
        final session = sessionBuilder.build();
        await AssistantMessage.db.insertRow(
          session,
          AssistantMessage(
            threadId: threadId,
            role: 'assistant',
            contentJson: AssistantHistory.encode(
              ChatMessage(
                role: ChatMessageRole.model,
                parts: const [
                  ToolPart.call(
                    callId: 'lost',
                    toolName: 'write_get_outline',
                    arguments: {},
                  ),
                ],
              ),
            ),
            displayText: '',
            visible: false,
            createdAt: nowUtc(),
          ),
        );
        fake.enqueue((AiScript()..text('Fine.')).response);

        final events = await endpoints.assistant
            .chat(anna.endpointSession, threadId, doc.uuid, 'Again', _hints())
            .toList();

        expect(events.last.type, AssistantEventType.done);
        expect(events.last.text, 'Fine.');
        final sent = fake.requests.last.messages;
        final results = sent.expand((m) => m.toolResults).toList();
        expect(results.single.callId, 'lost');
        expect(results.single.result, AssistantHistory.interruptedResult);
      },
    );
  });
}
