@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/ai_models.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/ai/write_quick_actions.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

AssistantContextHints _hints({int? start, int? length, String? text}) =>
    AssistantContextHints(
      applyMode: AiApplyMode.edit,
      includeComments: false,
      selectionStart: start,
      selectionLength: length,
      selectionText: text,
    );

void main() {
  late FakeAiModelClient fake;

  setUp(() {
    fake = FakeAiModelClient();
    AiConfig.current = AiConfig(
      serverKeys: {AiProvider.anthropic: 'test-key'},
      dailyTokenBudget: 1000000,
    );
    AiConfig.clientOverride = fake;
  });
  tearDown(() => AiConfig.clientOverride = null);

  withWonkyServerpod('Given a document and a Write quick action', (
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
        name: 'Plan',
        markdown:
            '# Plan\n\nThe budjet is ten euros. We should utilize it '
            'wisely.\n\n## Risks\n\nNone known.\n',
      );
    });

    Future<List<AssistantEvent>> quick(
      AssistantQuickAction action, {
      int? threadId,
      AssistantContextHints? hints,
    }) => endpoints.assistant
        .quickAction(
          anna.endpointSession,
          threadId,
          doc.uuid,
          action,
          hints ?? _hints(),
        )
        .toList();

    /// Hints selecting the first [text] of the document.
    Future<AssistantContextHints> selecting(String text) async {
      final s = await endpoints.document.getSnapshot(
        anna.endpointSession,
        doc.contentRef!,
        null,
      );
      final plain = DeltaUtils.text(
        Delta.fromJson(jsonDecode(s.deltaJson) as List),
      );
      return _hints(
        start: plain.indexOf(text),
        length: text.length,
        text: text,
      );
    }

    Future<List<SuggestionInfo>> suggestions() async {
      final s = await endpoints.document.getSnapshot(
        anna.endpointSession,
        doc.contentRef!,
        null,
      );
      return SuggestionIndex.list(
        Delta.fromJson(jsonDecode(s.deltaJson) as List),
      );
    }

    test(
      'when summarizing then one fast low-effort request streams the summary '
      'and the prompt is not shown in the thread',
      () async {
        fake.enqueue(
          (AiScript()..text('A plan.\n\n- Budget: ten euros')).response,
        );

        final events = await quick(AssistantQuickAction.summarize);

        expect(fake.requests, hasLength(1));
        final r = fake.requests.single;
        expect(r.model, AiModels.haiku);
        expect(r.effort, AiEffort.low);
        expect(r.tools, isEmpty);
        expect(r.messages.single.text, contains('ten euros'));
        expect(events.first.type, AssistantEventType.started);
        expect(
          events.where((e) => e.type == AssistantEventType.textDelta),
          isNotEmpty,
        );
        expect(events.last.type, AssistantEventType.done);
        expect(events.last.text, 'A plan.\n\n- Budget: ten euros');
        final thread = await endpoints.assistant.getThread(
          anna.endpointSession,
          events.first.threadId!,
        );
        expect(thread.messages.map((m) => m.role), ['assistant']);
      },
    );

    test(
      'when text is selected then Summarize sends only the selection',
      () async {
        fake.enqueue((AiScript()..text('No risks are known.')).response);

        await quick(
          AssistantQuickAction.summarize,
          hints: await selecting('None known.'),
        );

        final sent = fake.requests.single.messages.single.text;
        expect(sent, contains('None known.'));
        expect(sent, contains('<selection'));
        expect(sent, isNot(contains('budjet')));
      },
    );

    test(
      'when text is selected then Proofread checks only the paragraphs it '
      'touches and suggests only corrections inside it',
      () async {
        fake.enqueue(
          (AiScript()..toolUse('p', 'report_issues', {
                'issues': [
                  {
                    'quote': 'None known',
                    'occurrence': 1,
                    'replacement': 'None are known',
                    'category': 'grammar',
                    'explanation': 'Complete sentence',
                  },
                ],
              }))
              .response,
        );

        await quick(
          AssistantQuickAction.proofread,
          hints: await selecting('None known.'),
        );

        expect(fake.requests, hasLength(1));
        final sent = fake.requests.single.messages.single.text;
        expect(sent, contains('None known.'));
        expect(sent, isNot(contains('budjet')));
        final s = await suggestions();
        expect(s, isNotEmpty);
      },
    );

    test(
      'when the selected text is gone then the whole document is proofread',
      () async {
        fake.enqueue(
          (AiScript()..toolUse('p', 'report_issues', {'issues': []})).response,
        );

        await quick(
          AssistantQuickAction.proofread,
          hints: _hints(start: 3, length: 9, text: 'not there'),
        );

        expect(fake.requests.single.messages.single.text, contains('budjet'));
      },
    );

    test(
      'when proofreading then small corrections become suggestions and '
      'rewrites are dropped',
      () async {
        fake.enqueue(
          (AiScript()..toolUse('p', 'report_issues', {
                'issues': [
                  {
                    'quote': 'budjet',
                    'occurrence': 1,
                    'replacement': 'budget',
                    'category': 'spelling',
                    'explanation': 'Typo',
                  },
                  {
                    'quote': 'We should utilize it wisely.',
                    'occurrence': 1,
                    'replacement':
                        'We must spend every single cent of it with great '
                        'care and attention to detail.',
                    'category': 'style',
                    'explanation': 'Wordy',
                  },
                ],
              }))
              .response,
        );

        final events = await quick(AssistantQuickAction.proofread);

        expect(fake.requests, hasLength(1));
        expect(fake.requests.single.model, AiModels.haiku);
        final finished = events
            .where((e) => e.type == AssistantEventType.toolFinished)
            .toList();
        expect(finished, hasLength(1));
        expect(finished.single.toolError, isFalse);
        expect(finished.single.toolSummary, '“budjet” → “budget”');
        expect(events.last.text, startsWith('Suggested 1 correction.'));
        final s = await suggestions();
        expect(s, isNotEmpty);
        expect(s.every((x) => x.via == 'ai'), isTrue);
      },
    );

    test(
      'when addressing comments then fixes become suggestions, the thread '
      'gets a short reply and the rest is listed for the user',
      () async {
        final mcp = await McpHarness.forUser(anna);
        final fixMe = await mcp.call('comments.create', {
          'uuid': doc.uuid.uuid,
          'anchor': {'quote': 'ten euros'},
          'body': 'Make it twelve.',
        });
        await mcp.call('comments.create', {
          'uuid': doc.uuid.uuid,
          'anchor': {'quote': 'None known.'},
          'body': 'Should we ask legal?',
        });
        fake.enqueue(
          (AiScript()..toolUse('c', WriteQuickActions.commentsTool, {
                'fixes': [
                  {
                    'thread_uuid': fixMe['thread_uuid'],
                    'edits': [
                      {
                        'quote': 'ten euros',
                        'occurrence': 1,
                        'replacement': 'twelve euros',
                      },
                    ],
                    'reply': 'Suggested raising the budget to twelve euros.',
                  },
                ],
              }))
              .response,
        );

        final events = await quick(AssistantQuickAction.addressComments);

        expect(fake.requests.single.messages.single.text, contains('twelve'));
        expect(await suggestions(), isNotEmpty);
        final list = await mcp.call('comments.list', {'uuid': doc.uuid.uuid});
        final thread = (list['threads'] as List)
            .cast<Map<String, Object?>>()
            .firstWhere(
              (t) => t['thread_uuid'] == fixMe['thread_uuid'],
            );
        expect(thread['status'], 'open');
        final replies = thread['comments'] as List;
        expect(replies, hasLength(2));
        expect(
          (replies.last as Map)['body'],
          startsWith('Suggested raising the budget to twelve euros.'),
        );
        final text = events.last.text!;
        expect(text, contains('Suggested changes for 1 of 2 open comments'));
        expect(text, contains('Should we ask legal?'));
      },
    );

    test(
      'when applying style without a style guide then the panel is told to '
      'choose one',
      () async {
        final events = await quick(AssistantQuickAction.applyStyle);

        final error = events.firstWhere(
          (e) => e.type == AssistantEventType.error,
        );
        expect(error.errorCode, 'no_style');
        expect(fake.requests, isEmpty);
      },
    );

    test(
      "when applying style then the document's guide is sent and its edits "
      'become suggestions',
      () async {
        await endpoints.styleGuide.setDocumentStyle(
          anna.endpointSession,
          doc.uuid,
          'builtin:plain-language',
        );
        fake.enqueue(
          (AiScript()..toolUse('s', WriteQuickActions.editsTool, {
                'edits': [
                  {
                    'quote': 'We should utilize it wisely.',
                    'occurrence': 1,
                    'replacement': 'Use it wisely.',
                    'reason': 'Everyday words',
                  },
                ],
              }))
              .response,
        );

        final events = await quick(AssistantQuickAction.applyStyle);

        final user = fake.requests.single.messages.single.text;
        expect(user, contains('<style_guide name="Plain language">'));
        expect(events.last.text, contains('Suggested 1 edit'));
        expect(await suggestions(), isNotEmpty);
      },
    );

    test(
      'when the user chats after a quick action then the thread replays '
      'as a valid conversation',
      () async {
        fake
          ..enqueue((AiScript()..text('A plan.')).response)
          ..enqueue((AiScript()..text('It is short.')).response);
        final first = await quick(AssistantQuickAction.summarize);

        final events = await endpoints.assistant
            .chat(
              anna.endpointSession,
              first.first.threadId,
              doc.uuid,
              'Is it long?',
              _hints(),
            )
            .toList();

        expect(events.last.text, 'It is short.');
        final sent = fake.requests.last.messages;
        expect(sent.map((m) => m.role), [
          ChatMessageRole.user,
          ChatMessageRole.model,
          ChatMessageRole.user,
        ]);
        // The hidden quick-action turn carries the document snapshot.
        expect(sent.first.text, contains('<document '));
        expect(sent[1].text, 'A plan.');
      },
    );

    test(
      'when the chat edits with Edit requested then the edit is still a '
      'suggestion',
      () async {
        fake
          ..enqueue(
            (AiScript()..toolUse('e', 'write_replace_text', {
                  'find': 'None known.',
                  'replace': 'Two known.',
                  'occurrence': 1,
                }))
                .response,
          )
          ..enqueue((AiScript()..text('Suggested.')).response);

        await endpoints.assistant
            .chat(anna.endpointSession, null, doc.uuid, 'Fix risks', _hints())
            .toList();

        expect(await suggestions(), isNotEmpty);
        expect(
          fake.requests.first.messages.last.text,
          contains('Your edits become tracked suggestions.'),
        );
      },
    );
  });
}
