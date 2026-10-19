@Tags(['integration'])
@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart' as mcp;
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/mcp/mcp_config.dart';
import 'package:wonky_server/src/platform/mcp/mcp_http.dart';
import 'package:wonky_server/src/platform/mcp/mcp_route.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/slides/charts/slides_chart_service.dart';
import 'package:wonky_server/src/platform/revlog/headless_file_cache.dart';
import 'package:wonky_server/src/slides/mcp/slides_writes.dart';

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// Slides 11 §10 AC 1 / J-S10 (headless part) end to end through `/mcp`
/// with the `mcp_dart` client: create from an outline, add slides with a
/// group, set text by placeholder, a code block with three states and
/// steps, a linked chart, builds and a Magic Move transition, a PDF; every
/// call is revertible with `changes.revert`.
void main() {
  withWonkyServerpod('Given the /mcp route', (sessionBuilder, endpoints) {
    late int port;
    late McpHttpHandler handler;

    setUpAll(() async {
      final pod = sessionBuilder.build().serverpod;
      handler = McpHttpHandler(
        config: McpConfig(
          allowedHosts: {'localhost', '127.0.0.1'},
          allowedOrigins: {'http://localhost:8082'},
        ),
      );
      pod.webServer.addRoute(McpRoute(handler: handler, pod: pod), '/mcp');
      if (!pod.webServer.running) await pod.webServer.start();
      port = pod.webServer.port!;
    });
    tearDownAll(() => handler.closeAll());
    tearDown(() {
      DeckAgentPresence.clear();
      HeadlessFileCache.clear();
      HeadlessWorkbookProvider.clear();
      SlidesChartService.reset();
    });

    test('when an agent builds a deck through MCP then a user opening it '
        'sees exactly that and every call reverts', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final harness = await McpHarness.forUser(anna);
      final ss = await SheetsFixtures.create(
        harness,
        name: 'Finance 2026',
        sheets: {'Data': SheetsFixtures.sales},
      );
      final chart = await harness.call('sheets.create_chart', {
        'spreadsheet': ss,
        'data_ranges': ['Data!A1:A7', 'Data!C1:C7'],
        'type': 'column',
        'options': {'title': 'Revenue by region'},
      });

      final client = mcp.McpClient(
        const mcp.Implementation(name: 'js10', version: '1.0.0'),
        options: const mcp.McpClientOptions(protocol: mcp.McpProtocol.stable),
      );
      await client.connect(
        mcp.StreamableHttpClientTransport(
          Uri.parse('http://localhost:$port/mcp'),
          opts: mcp.StreamableHttpClientTransportOptions(
            requestInit: {
              'headers': {'Authorization': 'Bearer ${harness.secret}'},
            },
          ),
        ),
      );
      Future<Map<String, dynamic>> call(
        String name,
        Map<String, dynamic> args,
      ) async {
        final r = await client.callTool(
          mcp.CallToolRequest(name: name, arguments: args),
        );
        if (r.isError == true) {
          fail('$name: ${(r.content.first as mcp.TextContent).text}');
        }
        return r.structuredContent!.cast<String, dynamic>();
      }

      final tools = await client.listTools();
      final prompts = await client.listPrompts();
      final created = await call('drive.create_presentation', {
        'name': 'Launch',
        'outline_markdown': '# Launch\n---\n## Agenda\n- Why\n- How',
      });
      final deck = created['deck_uuid'] as String;
      final changes = <String>[];
      void record(Map<String, dynamic> r) {
        if (r['change_id'] is String) changes.add(r['change_id'] as String);
      }

      record(
        await call('slides.add_slides', {
          'deck': deck,
          'slides': [
            {'layout': 'code', 'title': 'The API'},
            {'layout': 'chart', 'title': 'Numbers'},
          ],
          'group': {
            'new': {'title': 'Demo'},
          },
        }),
      );
      record(
        await call('slides.set_text', {
          'deck': deck,
          'element': {'slide': 2, 'placeholder': 'body'},
          'text': '- Why it matters\n- How it works',
        }),
      );
      final code = await call('slides.add_code_block', {
        'deck': deck,
        'slide': 3,
        'language': 'dart',
        'states': [
          {'code': 'a();'},
          {'code': 'a();\nb();', 'highlight': '2'},
          {'code': 'a();\nb();\nc();', 'highlight': '3'},
        ],
        'builds': 'all_steps',
      });
      record(code);
      final linked = await call('slides.insert_linked_chart', {
        'deck': deck,
        'slide': 4,
        'spreadsheet': ss,
        'chart_id': chart['chart_id'],
      });
      record(linked);
      record(
        await call('slides.set_builds', {
          'deck': deck,
          'slide': 4,
          'builds': [
            {
              'element': linked['element_id'],
              'kind': 'build_in',
              'effect': 'chartGrow',
              'delivery': {'by': 'series', 'part_trigger': 'on_click'},
            },
          ],
        }),
      );
      record(
        await call('slides.set_transition', {
          'deck': deck,
          'slides': [4],
          'transition': {'type': 'magicMove'},
        }),
      );
      final pdf = await call('slides.export_pdf', {'deck': deck});
      final outline = await client.readResource(
        mcp.ReadResourceRequest(uri: 'wonky://deck/$deck'),
      );
      final opened = await harness.call('slides.get_deck', {'deck': deck});

      expect(
        tools.tools.map((t) => t.name),
        containsAll([
          'drive.create_presentation',
          'slides.get_deck',
          'slides.add_slides',
          'slides.add_code_block',
          'slides.insert_linked_chart',
          'slides.export_pdf',
        ]),
      );
      expect(
        prompts.prompts.map((p) => p.name),
        containsAll(['create_presentation', 'review_presentation']),
      );
      expect(opened['slide_count'], 4);
      expect(
        [for (final s in opened['slides'] as List) s['title']],
        ['Launch', 'Agenda', 'The API', 'Numbers'],
      );
      expect((opened['groups'] as List).single, containsPair('title', 'Demo'));
      // codeState 2, highlight step, codeState 3, highlight step.
      expect((opened['slides'] as List)[2]['build_count'], 4);
      expect((opened['slides'] as List)[3]['transition'], 'magicMove');
      expect(pdf['page_count'], 4);
      final text = (outline.contents.single as mcp.TextResourceContents).text;
      expect(text, contains('```dart'));
      expect(text, contains('<!-- chart: "Revenue by region" linked to'));

      for (final id in changes.reversed) {
        final r = await client.callTool(
          mcp.CallToolRequest(
            name: 'changes.revert',
            arguments: {'change_id': id},
          ),
        );
        expect(r.isError, isNot(true), reason: jsonEncode(r.toJson()));
      }
      await client.close();
      final reverted = await harness.call('slides.get_deck', {'deck': deck});
      expect(reverted['slide_count'], 2);
      expect(reverted['groups'], isEmpty);
    });
  });
}
