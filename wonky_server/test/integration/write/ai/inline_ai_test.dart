@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/ai_usage_service.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  late FakeAiModelClient fake;

  setUp(() {
    fake = FakeAiModelClient();
    AiConfig.current = AiConfig(serverKeys: {AiProvider.anthropic: 'test-key'});
    AiConfig.clientOverride = fake;
  });
  tearDown(() => AiConfig.clientOverride = null);

  withWonkyServerpod('Given a document and inline AI', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView doc;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      doc = await TestDrive.document(
        endpoints,
        anna,
        markdown:
            '# Notes\n\nTeh quick brown fox jumpd over the dog.\n\n'
            '## Ideas\n\nWe should ship it.\n',
      );
    });

    test(
      'when a selection is rewritten then the preview streams and the '
      'final Markdown is cleaned',
      () async {
        fake.enqueue(
          (AiScript()..text('```markdown\nThe quick brown fox jumped.\n```'))
              .response,
        );
        final events = await endpoints.assistant
            .inline(
              anna.endpointSession,
              InlineAiRequest(
                itemUuid: doc.uuid,
                action: 'shorter',
                selectedMarkdown: 'Teh quick brown fox jumpd over the dog.',
                contextAfter: '## Ideas',
              ),
            )
            .toList();
        expect(events.first.type, InlineAiEventType.textDelta);
        expect(events.last.type, InlineAiEventType.done);
        expect(events.last.markdown, 'The quick brown fox jumped.');
        final req = fake.requests.single;
        expect(req.effort, 'medium');
        expect(req.tools, isEmpty);
        final text = req.messages.single.text;
        expect(text, contains('<selection>Teh quick'));
        expect(text, contains('shorter'));
      },
    );

    test('when refining then the previous output is a prior turn', () async {
      fake.enqueue((AiScript()..text('Formal text.')).response);
      await endpoints.assistant
          .inline(
            anna.endpointSession,
            InlineAiRequest(
              itemUuid: doc.uuid,
              action: 'improve',
              selectedMarkdown: 'We should ship it.',
              previousOutput: 'Let us ship it.',
              instruction: 'more formal',
            ),
          )
          .toList();
      final messages = fake.requests.single.messages;
      expect(messages.map((m) => m.role), [
        ChatMessageRole.user,
        ChatMessageRole.model,
        ChatMessageRole.user,
      ]);
    });

    test('when the model refuses then nothing can be inserted', () async {
      fake.enqueue((AiScript()..stop(AiStopReason.refusal)).response);
      final events = await endpoints.assistant
          .inline(
            anna.endpointSession,
            InlineAiRequest(
              itemUuid: doc.uuid,
              action: 'improve',
              selectedMarkdown: 'x',
            ),
          )
          .toList();
      expect(events.last.type, InlineAiEventType.refusal);
    });

    test(
      'when continuing then the text before the caret is the context',
      () async {
        fake.enqueue((AiScript()..text(' And then it slept.')).response);
        final events = await endpoints.assistant
            .inline(
              anna.endpointSession,
              InlineAiRequest(
                itemUuid: doc.uuid,
                action: 'continueWriting',
                start: 30,
              ),
            )
            .toList();
        expect(events.last.markdown, ' And then it slept.');
        final text = jsonEncode([
          for (final m in fake.requests.single.messages) m.toJson(),
        ]);
        expect(text, contains('text_before_caret'));
        expect(text, isNot(contains('We should ship')));
      },
    );

    test(
      'when summarizing the document then the whole document is sent',
      () async {
        fake.enqueue((AiScript()..text('- A fox.\n- Shipping.')).response);
        final events = await endpoints.assistant
            .inline(
              anna.endpointSession,
              InlineAiRequest(
                itemUuid: doc.uuid,
                action: 'summarizeDocument',
                summaryLength: 'short',
              ),
            )
            .toList();
        expect(events.last.markdown, '- A fox.\n- Shipping.');
        expect(
          fake.requests.single.messages.single.text,
          contains('We should ship it.'),
        );
      },
    );

    test(
      'when proofreading then issues are validated against the document',
      () async {
        fake.enqueue(
          (AiScript()
                ..toolUse('p', 'report_issues', {
                  'issues': [
                    {
                      'quote': 'Teh',
                      'occurrence': 1,
                      'replacement': 'The',
                      'category': 'spelling',
                      'explanation': 'Typo.',
                    },
                    {
                      'quote': 'not in the text',
                      'occurrence': 1,
                      'replacement': 'x',
                      'category': 'grammar',
                      'explanation': 'Invented.',
                    },
                  ],
                })
                ..stop(AiStopReason.toolUse))
              .response,
        );
        final events = await endpoints.assistant
            .proofread(anna.endpointSession, doc.uuid, null, null)
            .toList();
        final issues = events
            .where((e) => e.type == 'issues')
            .expand((e) => e.issues!)
            .toList();
        expect(issues, hasLength(1));
        expect(issues.single.quote, 'Teh');
        expect(issues.single.replacement, 'The');
        expect(issues.single.occurrence, 1);
        expect(events.last.type, 'done');
        final tool = fake.requests.single.tools.single;
        expect(tool.name, 'report_issues');
      },
    );

    test('when a viewer asks for a rewrite then it is refused', () async {
      final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
      await TestDrive.share(endpoints, doc, anna, vic, AccessRole.viewer);
      await expectLater(
        endpoints.assistant
            .inline(
              vic.endpointSession,
              InlineAiRequest(itemUuid: doc.uuid, action: 'improve'),
            )
            .toList(),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when runs finish, fail or are refused then no concurrency slot '
        'stays taken', () async {
      fake.enqueue((AiScript()..text('Done.')).response);
      fake.enqueue(FakeAiResponse.error(StateError('provider down')));
      InlineAiRequest req(String action) => InlineAiRequest(
        itemUuid: doc.uuid,
        action: action,
        selectedMarkdown: 'We should ship it.',
      );

      await endpoints.assistant
          .inline(anna.endpointSession, req('shorter'))
          .toList();
      await endpoints.assistant
          .inline(anna.endpointSession, req('shorter'))
          .toList()
          .catchError((Object _) => <InlineAiEvent>[]);
      await expectLater(
        endpoints.assistant.inline(anna.endpointSession, req('nope')).toList(),
        throwsA(isA<WonkyException>()),
      );

      expect(AiUsageService.running(anna.id), 0);
    });

    test('when the provider is rate limited then the run ends with a busy '
        'error event and frees its slot', () async {
      fake.enqueue(
        FakeAiResponse.error(AiApiException(429, 'api_error', 'slow down')),
      );

      final events = await endpoints.assistant
          .inline(
            anna.endpointSession,
            InlineAiRequest(
              itemUuid: doc.uuid,
              action: 'shorter',
              selectedMarkdown: 'We should ship it.',
            ),
          )
          .toList();

      expect(events.last.type, InlineAiEventType.error);
      expect(events.last.errorCode, 'rate_limited');
      expect(events.last.error, contains('busy'));
      expect(AiUsageService.running(anna.id), 0);
    });
  });
}
