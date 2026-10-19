@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart' show UuidValue;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/ai_config.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';
import 'package:wonky_server/src/platform/ai/llm/fake_ai_client.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';

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
  });
  tearDown(() {
    AiConfig.clientOverride = null;
    HeadlessWorkbookProvider.clear();
  });

  withWonkyServerpod('Given a spreadsheet with sales data', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late McpHarness mcp;
    late String ss;
    late UuidValue item;

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      mcp = await McpHarness.forUser(anna);
      ss = await SheetsFixtures.create(
        mcp,
        name: 'Sales',
        sheets: {'Data': SheetsFixtures.sales},
      );
      item = UuidValue.fromString(ss);
    });

    test(
      'when suggesting a formula then it is evaluated at the cell and nothing '
      'is written',
      () async {
        fake.enqueue(
          (AiScript()..toolUse('p', 'propose_formula', {
                'formula': '=SUMIF(A2:A7,"North",C2:C7)',
                'explanation': 'Revenue of the North region.',
                'references': ['A2:A7', 'C2:C7'],
              }))
              .response,
        );
        final s = await endpoints.sheetsAi.suggestFormula(
          anna.endpointSession,
          item,
          'Data!F2',
          'total revenue for North',
        );
        expect(s.formula, '=SUMIF(A2:A7,"North",C2:C7)');
        expect(s.previewValue, '180');
        expect(s.previewType, 'number');
        expect(s.errorMessage, isNull);
        expect(s.usesExternalData, isFalse);
        final req = fake.requests.single;
        expect(req.model, 'claude-haiku-5-5');
        expect(req.tools.single.name, 'propose_formula');
        final prompt = (req.messages.single.parts.single as TextPart).text;
        expect(prompt, contains('Target cell: F2'));
        expect(prompt, contains('row 1 is the header'));
        expect(await SheetsFixtures.read(mcp, ss, 'Data!F2'), isEmpty);
      },
    );

    test(
      'when the first proposal does not parse then the model is asked once '
      'more with the error',
      () async {
        fake
          ..enqueue(
            (AiScript()..toolUse('p', 'propose_formula', {
                  'formula': '=SUM(C2:C7',
                  'explanation': 'x',
                  'references': <String>[],
                }))
                .response,
          )
          ..enqueue(
            (AiScript()..toolUse('q', 'propose_formula', {
                  'formula': '=SUM(C2:C7)',
                  'explanation': 'Total revenue.',
                  'references': ['C2:C7'],
                }))
                .response,
          );
        final s = await endpoints.sheetsAi.suggestFormula(
          anna.endpointSession,
          item,
          'Data!F2',
          'total',
        );
        expect(s.formula, '=SUM(C2:C7)');
        expect(s.previewValue, '590');
        expect(fake.requests, hasLength(2));
      },
    );

    test(
      'when the model answers in text then the formula is extracted',
      () async {
        fake.enqueue(
          (AiScript()..text('Use =AVERAGE(C2:C7) for that.')).response,
        );
        final s = await endpoints.sheetsAi.suggestFormula(
          anna.endpointSession,
          item,
          'Data!F2',
          'average revenue',
        );
        expect(s.formula, '=AVERAGE(C2:C7)');
        expect(s.previewValue, isNotEmpty);
      },
    );

    test('when explaining a formula then the explanation streams', () async {
      await mcp.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': 'Data!F2',
        'values': [
          ['=C2*D2'],
        ],
      });
      fake.enqueue(
        (AiScript()..text('It multiplies revenue by units: 1200.')).response,
      );
      final events = await endpoints.sheetsAi
          .explainFormula(anna.endpointSession, item, 'Data!F2')
          .toList();
      expect(events.last.type, InlineAiEventType.done);
      expect(events.last.markdown, contains('1200'));
      final prompt =
          (fake.requests.single.messages.single.parts.single as TextPart).text;
      expect(prompt, contains('Formula: =C2*D2'));
      expect(prompt, contains('Evaluation trace:'));
      expect(fake.requests.single.tools, isEmpty);
    });

    test(
      'when filling a column with AI then proposals come back and applying '
      'them is one undoable change',
      () async {
        await mcp.call('sheets.set_values', {
          'spreadsheet': ss,
          'range': 'Data!E1',
          'values': [
            ['Code'],
            ['N-APP'],
            ['S-PEA'],
          ],
        });
        fake.enqueue(
          (AiScript()..toolUse('f', 'fill_values', {
                'rows': [
                  {'row': 4, 'value': 'N-PEA', 'confidence': 'high'},
                  {'row': 5, 'value': 'E-APP', 'confidence': 'high'},
                  {'row': 6, 'value': 'S-APP', 'confidence': 'medium'},
                  {'row': 7, 'value': null, 'confidence': 'low'},
                ],
              }))
              .response,
        );
        final p = await endpoints.sheetsAi.fillRange(
          anna.endpointSession,
          item,
          'Data!E1:E7',
          null,
        );
        expect(p.header, 'Code');
        expect(p.examples, 2);
        expect(p.rows.map((r) => r.cell), [
          'Data!E4',
          'Data!E5',
          'Data!E6',
          'Data!E7',
        ]);
        expect(p.rows.first.inputs, contains('A "Region"=North'));
        expect(p.rows.last.value, isNull);
        final applied = await endpoints.sheetsAi.applyFill(
          anna.endpointSession,
          item,
          p.range,
          p.rows,
        );
        expect(applied.cellsAffected, 3);
        expect(applied.label, 'AI: Fill Data!E2:E7');
        expect(await SheetsFixtures.read(mcp, ss, 'Data!E4:E6'), [
          ['N-PEA'],
          ['E-APP'],
          ['S-APP'],
        ]);
        await endpoints.sheets.revertChange(
          anna.endpointSession,
          applied.changeId!,
        );
        HeadlessWorkbookProvider.clear();
        expect(await SheetsFixtures.read(mcp, ss, 'Data!E4:E6'), isEmpty);
      },
    );

    test('when asking for analysis chips then they name the data', () async {
      final chips = await endpoints.sheetsAi.analyzeChips(
        anna.endpointSession,
        item,
        null,
      );
      expect(chips, [
        'Summarize this table',
        'Find anomalies',
        'Create a pivot table of Revenue by Region',
        'Make a chart of Revenue by Region',
      ]);
      expect(fake.requests, isEmpty);
    });

    test('when describing a chart then the alt text comes back', () async {
      final c = await mcp.call('sheets.create_chart', {
        'spreadsheet': ss,
        'data_ranges': ['Data!A1:A7', 'Data!C1:C7'],
        'type': 'column',
      });
      fake.enqueue(
        (AiScript()..text('Column chart of revenue; East is highest (200).'))
            .response,
      );
      final text = await endpoints.sheetsAi.describeChart(
        anna.endpointSession,
        item,
        c['chart_id'] as String,
      );
      expect(text, contains('East'));
      final prompt =
          (fake.requests.single.messages.single.parts.single as TextPart).text;
      expect(prompt, contains('Type: Column'));
    });

    test('when a viewer asks to fill then it is refused', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await SheetsFixtures.share(mcp, ss, bo.email, 'viewer');
      await expectLater(
        endpoints.sheetsAi.fillRange(
          bo.endpointSession,
          item,
          'Data!E1:E7',
          null,
        ),
        throwsA(isA<WonkyException>()),
      );
    });
  });
}
