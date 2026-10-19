import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_sheets/features/ai/agent_highlight_layer.dart';
import 'package:wonky_sheets/features/ai/external_agent_writes.dart';
import 'package:wonky_sheets/features/ai/server_change_undo.dart';
import 'package:wonky_sheets/features/ai/sheets_ai_controller.dart';
import 'package:wonky_sheets/features/explore/explore_chart_thumbnail.dart';
import 'package:wonky_sheets/features/explore/explore_panel.dart';
import 'package:wonky_sheets/features/grid/grid_area.dart';
import 'package:wonky_sheets/features/objects/objects_controller.dart';
import 'package:wonky_sheets/mcp/ui_sheets_tools.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_ui/wonky_ui.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';
import 'support/fake_sheets_ai_api.dart';

void main() {
  late SheetsHarness s;
  late SheetsAiController ai;

  setUp(() {
    s = SheetsHarness.open();
    SheetsAiApis.install(s.services, FakeSheetsAiApi());
    ai = SheetsAiController.of(s.editor);
  });

  tearDown(() async {
    ShellAssistant.uninstall(s.services);
    ObjectsController.maybeOf(s.editor)?.dispose();
    await s.dispose();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  }

  AgentWrite log({
    required ActorKind kind,
    required String user,
    String session = 'server:mcp',
    GridRect rect = const GridRect(0, 0, 1, 1),
  }) => AgentWrite(
    id: const Uuid().v7(),
    userUuid: user,
    actorKind: kind,
    sessionId: session,
    summaryJson: jsonEncode({
      'sheets': [s.sheetId],
      'ranges': [s.sheet.gridRange(rect).toJson()],
      'kinds': ['values'],
    }),
    at: clock.now().toUtc(),
  );

  group('Given =AI() cells', () {
    late FakeSheetsAiApi api;

    setUp(() async {
      api = FakeSheetsAiApi();
      SheetsAiApis.install(s.services, api);
      ShellAssistant.install(s.services, api: FakeAssistantApi());
      await ShellAssistant.of(s.services)!.refreshStatus();
    });

    String shown(String a1) {
      final rr = s.model.parseA1(a1, contextSheetId: s.sheetId);
      return s.editor.engine
          .valueAt(rr.sheetId, rr.rect.top, rr.rect.left)
          .debugText;
    }

    test('when a prompt is entered then it shows #LOADING until the batch '
        'answers, cached values are reused, Refresh recomputes', () async {
      await s.type('A1', 'great product');
      await s.type('B1', '=AI("summarize", A1)');
      await s.type('B2', '=AI("count words", A1)');
      expect(shown('B1'), '#N/A');
      expect(shown('B2'), '#N/A');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(shown('B1'), '"SUMMARIZE"');
      expect(shown('B2'), '"COUNT WORDS"');
      expect(api.aiCellCalls, hasLength(1));
      final first = api.aiCellCalls.single.$1;
      expect(first.map((r) => r.prompt), ['summarize', 'count words']);
      expect(jsonDecode(first.first.valuesJson), [
        [
          ['great product'],
        ],
      ]);
      expect(api.aiCellCalls.single.$2, isFalse);

      api.aiCellValue = (r) => '42';
      final r = await s.run('sheets.ai.refreshAiCells');
      expect(r.isOk, isTrue, reason: '${r.message}');
      // The engine asks again when the cells are read.
      shown('B1');
      shown('B2');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(api.aiCellCalls.last.$2, isTrue);
      expect(shown('B1'), '42');
    });

    test('when a viewer gets no cached value then the cell keeps loading '
        'and is not asked again', () async {
      api.aiCellValue = (r) => null;
      final provider = ai.aiCells;
      await s.type('A1', '=AI("x")');
      shown('A1');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(shown('A1'), '#N/A');
      final sent = provider.sentBatches;
      await s.type('A2', '=1+1');
      shown('A1');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(provider.sentBatches, sent);
      expect(sent, 1);
    });
  });

  test('Given messy data when Clean up data with AI runs then the checks '
      'go to the assistant in Suggest mode', () async {
    final chatApi = FakeAssistantApi();
    ShellAssistant.install(s.services, api: chatApi);
    await ShellAssistant.of(s.services)!.refreshStatus();
    await s.type('A1', 'Name');
    await s.type('A2', ' Anna ');
    await s.type('A3', 'Bo');
    await s.type('A4', 'Cy ');
    final r = await s.run('sheets.ai.cleanupSuggestions');
    expect(r.isOk, isTrue, reason: '${r.message}');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(ai.chat!.applyMode, AiApplyMode.suggest);
    expect(chatApi.sent.single, contains('whitespace'));
    expect(chatApi.sentHints.single.applyMode, AiApplyMode.suggest);
  });

  group('Given headless agent writes in the synced change log', () {
    const other = '0199e3a0-0000-7000-8000-00000000000b';

    test('when they arrive then MCP writes are flashed with the agent tag '
        'and own assistant runs and client edits are not', () async {
      final layer = AgentHighlightLayer();
      final rows = [
        log(kind: ActorKind.mcp, user: other),
        log(
          kind: ActorKind.ai,
          user: s.session.userId,
          session: 'server:ai',
          rect: const GridRect(5, 5, 6, 6),
        ),
        log(
          kind: ActorKind.user,
          user: other,
          session: 'client-1',
          rect: const GridRect(8, 0, 8, 0),
        ),
        log(
          kind: ActorKind.ai,
          user: other,
          session: 'server:ai',
          rect: const GridRect(3, 3, 3, 3),
        ),
      ];
      final w = ExternalAgentWrites(
        s.editor,
        layer,
        source: (_) async => rows,
        labels: AgentLabels(
          mcp: 'MCP agent',
          of: (n) => "$n's agent",
          aiOf: (n) => 'AI · $n',
          someone: 'Someone',
        ),
      );
      await w.poll();
      expect(layer.active.map((h) => (h.label, h.rect)), [
        ('MCP agent', const GridRect(0, 0, 1, 1)),
        ('AI · Someone', const GridRect(3, 3, 3, 3)),
      ]);
      // Rows already seen are not flashed again.
      layer.clear();
      await w.poll();
      expect(layer.active, isEmpty);
      w.dispose();
      layer.dispose();
    });
  });

  testWidgets('Given the assistant asks for the window selection when the '
      'run relays ui.sheets.* tools then this window answers and flashes', (
    tester,
  ) async {
    final chatApi = FakeAssistantApi();
    ShellAssistant.install(s.services, api: chatApi);
    await tester.runAsync(() => ShellAssistant.of(s.services)!.refreshStatus());
    await pumpSheets(tester, s);
    await s.type('A1', '7');
    await s.select('A1:B2');
    chatApi.chatScripts.add([
      AssistantEvent(
        type: AssistantEventType.started,
        runId: 'r1',
        threadId: 1,
      ),
      AssistantEvent(
        type: AssistantEventType.uiToolCall,
        runId: 'r1',
        toolUseId: 't1',
        toolName: 'ui.sheets.get_selection',
        argsJson: '{}',
      ),
      AssistantEvent(
        type: AssistantEventType.uiToolCall,
        runId: 'r1',
        toolUseId: 't2',
        toolName: 'ui.sheets.highlight_range',
        argsJson: jsonEncode({'range': 'A1'}),
      ),
      AssistantEvent(
        type: AssistantEventType.uiToolCall,
        runId: 'r1',
        toolUseId: 't3',
        toolName: 'ui.sheets.type_in_cell',
        argsJson: jsonEncode({'cell': 'A1', 'text': 'x'}),
      ),
      AssistantEvent(type: AssistantEventType.done, runId: 'r1'),
    ]);
    final hints = ai.adapter.hints(
      applyMode: AiApplyMode.edit,
      chips: const {},
    );
    expect(hints.uiTools, contains('ui.sheets.highlight_range'));
    await tester.runAsync(() async {
      await ai.chat!.send('What did I select?');
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await settle(tester);
    final byId = {for (final r in chatApi.uiResults) r.requestId: r};
    expect(byId['t1']!.ok, isTrue);
    expect(jsonDecode(byId['t1']!.resultJson!)['ranges'], ['A1:B2']);
    expect(byId['t2']!.ok, isTrue);
    expect(ai.highlights.active.last.label, 'AI');
    // Only the three window tools run for the assistant.
    expect(byId['t3']!.ok, isFalse);
    expect(byId['t3']!.errorCode, 'unsupported');
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';

    testWidgets('Given data ($mode) when Explore shows chart suggestions then '
        'they are thumbnails under a panel title', (tester) async {
      await s.type('A1', 'Region');
      await s.type('B1', 'Revenue');
      await s.type('A2', 'North');
      await s.type('B2', '10');
      await s.type('A3', 'South');
      await s.type('B3', '20');
      await s.select('A1:B3');
      await pumpSheets(
        tester,
        s,
        dark: dark,
        size: const Size(300, 900),
        child: ExplorePanel(ai: ai),
      );
      await tester.pump(const Duration(milliseconds: 700));
      await settle(tester);
      expect(find.byKey(const ValueKey('sheets.explore.title')), findsOne);
      expect(find.byType(ExploreChartThumbnail), findsWidgets);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  }

  testWidgets('Given the Explore panel is open when an agent describes it, '
      'types a question and presses Ask then the question is asked', (
    tester,
  ) async {
    final tools = UiSheetsToolHandlers.all(s.services);
    UiToolContext ctx() => UiToolContext(
      services: s.services,
      boundaryKey: GlobalKey(),
      events: UiEventLog(),
    );
    Future<UiToolResult> call(String name, Map<String, Object?> a) async {
      Object? error;
      final r = await tester.runAsync(() async {
        try {
          return await tools[name]!(ctx(), a);
        } catch (e) {
          error = e;
          return null;
        }
      });
      await tester.pump();
      if (error != null) throw error!;
      return r!;
    }

    final chatApi = FakeAssistantApi();
    ShellAssistant.install(s.services, api: chatApi);
    await tester.runAsync(() => ShellAssistant.of(s.services)!.refreshStatus());
    await s.type('A1', '1');
    await s.type('A2', '2');
    await s.select('A1:A2');
    s.services.panels.open(explorePanelId);
    await pumpSheets(
      tester,
      s,
      size: const Size(1200, 800),
      child: WonkySplitView(
        controller: s.services.panels,
        panels: [explorePanelSpec(s.services, s.editor)],
        child: GridArea(controller: s.editor, services: s.services),
      ),
    );
    await settle(tester);
    final d = await call('ui.sheets.describe_panel', {});
    expect(d.result['panel'], explorePanelId);
    final fields = (d.result['fields']! as List).cast<Map<String, Object?>>();
    expect(fields.map((f) => f['id']), contains('sheets.explore.question'));
    final buttons = (d.result['buttons']! as List).cast<Map<String, Object?>>();
    expect(buttons.map((b) => b['id']), contains('sheets.explore.ask'));

    await call('ui.sheets.set_panel_field', {
      'field_id': 'sheets.explore.question',
      'value': 'Which region sells most?',
    });
    final after = await call('ui.sheets.describe_panel', {'panel': 'explore'});
    final q = (after.result['fields']! as List)
        .cast<Map<String, Object?>>()
        .firstWhere((f) => f['id'] == 'sheets.explore.question');
    expect(q['value'], 'Which region sells most?');

    await call('ui.sheets.press_panel_button', {
      'button_id': 'sheets.explore.ask',
    });
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    expect(chatApi.sent.single, 'Which region sells most?');
    // Ask opened the assistant (not part of this test's split view).
    s.services.panels.open(explorePanelId);
    await tester.pump();
    await expectLater(
      call('ui.sheets.press_panel_button', {'button_id': 'nope'}),
      throwsA(
        isA<UiToolException>().having((e) => e.code, 'code', 'invalid_args'),
      ),
    );
    await expectLater(
      call('ui.sheets.describe_panel', {'panel': 'chartEditor'}),
      throwsA(
        isA<UiToolException>().having((e) => e.code, 'code', 'not_found'),
      ),
    );
    expect(tester.takeException(), isNull);
    await finish(tester);
  });

  testWidgets('Given a chart over the cells when a range screenshot is taken '
      'then the chart is painted into it', (tester) async {
    await pumpSheets(tester, s);
    await s.type('A1', 'Region');
    await s.type('B1', 'Revenue');
    await s.type('A2', 'North');
    await s.type('B2', '10');
    await s.select('A1:B2');
    final tools = UiSheetsToolHandlers.all(s.services);
    Future<String> shot() async {
      final r = await tester.runAsync(
        () => tools['ui.sheets.screenshot_range']!(
          UiToolContext(
            services: s.services,
            boundaryKey: GlobalKey(),
            events: UiEventLog(),
          ),
          {'range': 'A1:L25'},
        ),
      );
      await tester.pump();
      return r!.imageBase64!;
    }

    final before = await shot();
    final r = await s.run('sheets.chart.insert', {
      'ranges': ['A1:B2'],
    });
    expect(r.isOk, isTrue, reason: '${r.message}');
    await tester.pump();
    final objects = ObjectsController.of(s.editor);
    expect(objects.objectsOn(s.sheetId), hasLength(1));
    final after = await shot();
    expect(after, isNot(before));
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
