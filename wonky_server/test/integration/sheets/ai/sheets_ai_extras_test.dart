@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/assistant_service.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/mcp/sheets_shadow.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  late FakeAiModelClient fake;

  setUp(() {
    fake = FakeAiModelClient();
    AiConfig.current = AiConfig(
      serverKeys: {AiProvider.anthropic: 'test-key'},
      dailyTokenBudget: 1000000,
    );
    AiConfig.clientOverride = fake;
    AssistantService.uiToolTimeout = const Duration(seconds: 10);
  });
  tearDown(() {
    AiConfig.clientOverride = null;
    HeadlessWorkbookProvider.clear();
    SheetsShadows.clear();
  });

  withWonkyServerpod('Given a spreadsheet and the assistant', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Sales',
        sheets: {'Data': SheetsFixtures.sales},
      );
    });

    Future<List<AssistantEvent>> chat(
      String message,
      AssistantContextHints hints, {
      UiBridgeResponse Function(AssistantEvent e)? window,
    }) {
      final events = <AssistantEvent>[];
      final done = Completer<List<AssistantEvent>>();
      endpoints.assistant
          .chat(
            anna.endpointSession,
            null,
            UuidValue.fromString(ss),
            message,
            hints,
          )
          .listen(
            (e) {
              events.add(e);
              if (e.type == AssistantEventType.uiToolCall && window != null) {
                unawaited(
                  endpoints.assistant.uiToolResult(
                    anna.endpointSession,
                    e.runId!,
                    window(e),
                  ),
                );
              }
            },
            onDone: () => done.complete(events),
            onError: done.completeError,
          );
      return done.future;
    }

    test('when the requesting window offers ui.sheets tools then the model '
        'reads the live selection through it', () async {
      fake
        ..enqueue(
          (AiScript()..toolUse('t1', 'ui_sheets_get_selection', {})).response,
        )
        ..enqueue((AiScript()..text('You selected A1:B2.')).response);
      final events = await chat(
        'What did I select?',
        AssistantContextHints(
          applyMode: AiApplyMode.edit,
          includeComments: false,
          uiTools: ['ui.sheets.get_selection', 'ui.sheets.type_in_cell'],
        ),
        window: (e) => UiBridgeResponse(
          requestId: e.toolUseId!,
          ok: true,
          resultJson: jsonEncode({
            'sheet': 'Data',
            'ranges': ['A1:B2'],
          }),
        ),
      );
      final call = events.singleWhere(
        (e) => e.type == AssistantEventType.uiToolCall,
      );
      expect(call.toolName, 'ui.sheets.get_selection');
      expect(jsonDecode(call.argsJson!), isEmpty);
      final finished = events.singleWhere(
        (e) => e.type == AssistantEventType.toolFinished,
      );
      expect(finished.toolError, isFalse);
      expect(finished.toolSummary, 'Looking at your selection');

      final tools = {for (final t in fake.requests.first.tools) t.name: t};
      expect(tools, contains('ui_sheets_get_selection'));
      // Only the three window tools are ever offered.
      expect(tools, isNot(contains('ui_sheets_type_in_cell')));
      expect(
        (tools['ui_sheets_get_selection']!.inputSchema['properties'] as Map)
            .keys,
        isNot(contains('session_id')),
      );
      final result = fake.requests.last.messages.last.parts
          .whereType<ToolPart>()
          .single;
      expect('${result.result}', contains('A1:B2'));
    });

    test(
      'when the window does not offer them then no ui tools are sent',
      () async {
        fake.enqueue((AiScript()..text('Hi')).response);
        await chat(
          'Hello',
          AssistantContextHints(
            applyMode: AiApplyMode.edit,
            includeComments: false,
          ),
        );
        expect(
          fake.requests.single.tools
              .map((t) => t.name)
              .where(
                (n) => n.startsWith('ui_'),
              ),
          isEmpty,
        );
      },
    );

    test('when a Suggest-mode preview is served by another instance then it '
        'is read from the database and can be applied', () async {
      fake
        ..enqueue(
          (AiScript()..toolUse('t1', 'sheets_set_values', {
                'range': 'Data!F1',
                'values': [
                  ['Total'],
                ],
              }))
              .response,
        )
        ..enqueue((AiScript()..text('Suggested.')).response);
      final events = await chat(
        'Add a total header',
        AssistantContextHints(
          applyMode: AiApplyMode.suggest,
          includeComments: false,
        ),
      );
      final previewId = events.last.previewId!;
      // Another instance has no in-memory shadow.
      SheetsShadows.clear();
      final preview = await endpoints.sheetsAi.getPreview(
        anna.endpointSession,
        previewId,
      );
      expect(preview.calls.single.cells.single.after, 'Total');
      final applied = await endpoints.sheetsAi.applyPreview(
        anna.endpointSession,
        previewId,
        null,
      );
      expect(applied.cellsAffected, 1);
      expect(await SheetsFixtures.read(mcp, ss, 'Data!F1'), [
        ['Total'],
      ]);
      await expectLater(
        endpoints.sheetsAi.getPreview(anna.endpointSession, previewId),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when AI() cells are evaluated then values are cached by prompt and '
      'values, viewers only get cached ones, and refresh recomputes',
      () async {
        final item = UuidValue.fromString(ss);
        SheetsAiCellRequest req(String id, String values) =>
            SheetsAiCellRequest(
              id: id,
              prompt: 'Sentiment',
              valuesJson: values,
            );
        fake
          ..enqueue((AiScript()..text('Positive')).response)
          ..enqueue((AiScript()..text(' 42 ')).response);
        final first = await endpoints.sheetsAi.evaluateAiCells(
          anna.endpointSession,
          item,
          [req('a', '[[["great"]]]'), req('b', '[[["meh"]]]')],
          false,
        );
        expect(first.map((r) => (r.id, r.value, r.cached)), [
          ('a', 'Positive', false),
          ('b', '42', false),
        ]);
        expect(fake.requests, hasLength(2));
        expect(
          (fake.requests.first.messages.single.parts.single as TextPart).text,
          contains('<sheet_data>'),
        );

        final again = await endpoints.sheetsAi.evaluateAiCells(
          anna.endpointSession,
          item,
          [req('a', '[[["great"]]]')],
          false,
        );
        expect(again.single.cached, isTrue);
        expect(again.single.value, 'Positive');
        expect(fake.requests, hasLength(2));

        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        await SheetsFixtures.share(mcp, ss, bo.email, 'viewer');
        final viewer = await endpoints.sheetsAi.evaluateAiCells(
          bo.endpointSession,
          item,
          [req('a', '[[["great"]]]'), req('c', '[[["new"]]]')],
          false,
        );
        expect(viewer.map((r) => (r.id, r.value, r.error)), [
          ('a', 'Positive', null),
          ('c', null, null),
        ]);
        expect(fake.requests, hasLength(2));

        fake.enqueue((AiScript()..text('Negative')).response);
        final refreshed = await endpoints.sheetsAi.evaluateAiCells(
          anna.endpointSession,
          item,
          [req('a', '[[["great"]]]')],
          true,
        );
        expect(refreshed.single.value, 'Negative');
        expect(refreshed.single.cached, isFalse);
      },
    );
  });
}
