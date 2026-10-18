import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart'
    show InvocationSource, UiSheetsTools;
import 'package:wonky_sheets/features/ai/sheets_ai_controller.dart';
import 'package:wonky_sheets/features/cell_editor/cell_editor_controller.dart'
    show EditMode;
import 'package:wonky_sheets/mcp/ui_sheets_tools.dart';

import '../support/grid_pump.dart';
import '../support/sheets_harness.dart';

void main() {
  late SheetsHarness s;
  late Map<String, UiToolHandler> tools;

  UiToolContext ctx() => UiToolContext(
    services: s.services,
    boundaryKey: GlobalKey(),
    events: UiEventLog(),
    agentName: 'Claude Code (MCP)',
  );

  // Tools await a frame (uiSettle), so widget tests run them in real time.
  WidgetTester? current;
  Future<UiToolResult> call(
    String name, [
    Map<String, Object?> a = const {},
  ]) async {
    final t = current;
    if (t == null) return tools[name]!(ctx(), a);
    Object? error;
    final r = await t.runAsync(() async {
      try {
        return await tools[name]!(ctx(), a);
      } catch (e) {
        error = e;
        return null;
      }
    });
    await t.pump();
    if (error != null) throw error!;
    return r!;
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 6));
  }

  setUp(() {
    current = null;
    s = SheetsHarness.open();
    tools = UiSheetsToolHandlers.all(s.services);
  });

  tearDown(() => s.dispose());

  test('every ui.sheets.* definition has a handler and vice versa', () {
    expect(tools.keys.toSet(), {for (final d in UiSheetsTools.all) d.name});
  });

  testWidgets('Given a spreadsheet when ranges are selected through the '
      'bridge then the selection and agent highlight follow', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    await s.type('A1', '1');
    await s.type('A2', '2');
    final r = await call('ui.sheets.select_range', {
      'ranges': ['A1:A3', 'C1'],
      'active_cell': 'A2',
    });
    expect(r.result['ranges'], ['A1:A3', 'C1']);
    expect(r.result['active_cell'], 'A2');
    expect(r.result['sum'], 3);
    final hl = SheetsAiController.of(s.editor).highlights.active;
    expect(hl.first.label, 'Claude Code (MCP)');

    final sel = await call('ui.sheets.get_selection');
    expect(sel.result['values_preview'], [
      ['1'],
      ['2'],
      [''],
    ]);
    expect(sel.result['editing'], isFalse);
    await finish(tester);
  });

  testWidgets('Given a spreadsheet when the visible range is read then it '
      'reports the sheet, range and zoom', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    final r = await call('ui.sheets.get_visible_range');
    expect(r.result['sheet'], 'Sheet1');
    expect(r.result['range'], startsWith('A1:'));
    expect(r.result['zoom'], 100);
    await finish(tester);
  });

  testWidgets('Given two sheets when a sheet is activated by name then the '
      'grid shows it', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    await s.run('sheets.sheet.add', {'name': 'Data'});
    await call('ui.sheets.activate_sheet', {'sheet': 'Sheet1'});
    expect(s.editor.activeSheet!.name, 'Sheet1');
    final r = await call('ui.sheets.activate_sheet', {'sheet': 'data'});
    expect(r.result['sheet'], 'Data');
    expect(s.editor.activeSheet!.name, 'Data');
    await expectLater(
      call('ui.sheets.activate_sheet', {'sheet': 'Nope'}),
      throwsA(isA<UiToolException>()),
    );
    await finish(tester);
  });

  testWidgets('Given a cell when the agent types into it then the input is '
      'committed like typing', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    final r = await call('ui.sheets.type_in_cell', {
      'cell': 'B2',
      'text': '=1+41',
    });
    await tester.pump();
    expect(r.result['display'], '42');
    expect(s.h.undoLabels, isNotEmpty);

    final e = await call('ui.sheets.start_cell_edit', {
      'cell': 'C3',
      'initial_text': 'draft',
    });
    expect(e.result['editor_text'], 'draft');
    final sel = await call('ui.sheets.get_selection');
    expect(sel.result['editing'], isTrue);
    expect(sel.result['editor_text'], 'draft');
    s.editor.editor.cancel();
    await finish(tester);
  });

  testWidgets('Given the user typing in a cell when the agent types into '
      'another then the user\'s text is kept and the agent\'s write is '
      'recorded as the agent\'s', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    s.editor.selection.selectCell(2, 2);
    s.editor.editor.begin(initialText: 'mine', mode: EditMode.edit);
    await tester.pump();

    await call('ui.sheets.type_in_cell', {'cell': 'B2', 'text': 'agent'});
    await tester.pump();

    expect(
      s.editor.cells.displayAt(s.editor.activeSheetId, 2, 2)?.text,
      'mine',
    );
    expect(
      s.editor.cells.displayAt(s.editor.activeSheetId, 1, 1)?.text,
      'agent',
    );
    final sources = [
      for (final h in s.h.services.undo.history()) h.step.source,
    ];
    expect(sources, containsAll([InvocationSource.ui, InvocationSource.mcp]));
    await finish(tester);
  });

  testWidgets('Given formatted cells when a range screenshot is taken then '
      'a PNG of the range is returned', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    await s.type('A1', 'Hello');
    final r = await call('ui.sheets.screenshot_range', {
      'range': 'A1:B2',
      'include_headers': true,
    });
    expect(r.imageBase64, isNotNull);
    final png = base64Decode(r.imageBase64!);
    expect(png.sublist(1, 4), utf8.encode('PNG'));
    expect(r.result['width'], greaterThan(100));
    await finish(tester);
  });

  testWidgets('Given a range when it is highlighted then it is flashed with '
      'the color and duration', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    final r = await call('ui.sheets.highlight_range', {
      'range': 'B2:C3',
      'color': '#ff0000',
      'duration_ms': 2000,
    });
    expect(r.result['range'], 'Sheet1!B2:C3');
    final hl = SheetsAiController.of(s.editor).highlights;
    expect(hl.active.single.color, const Color(0xffff0000));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 2300)),
    );
    expect(hl.active, isEmpty);
    await finish(tester);
  });

  testWidgets('Given the engine when waiting for recalculation then it '
      'reports idle', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    await s.type('A1', '=2*3');
    await tester.pump(const Duration(milliseconds: 200));
    final r = await call('ui.sheets.wait_for_recalc');
    expect(r.result['idle'], isTrue);
    await finish(tester);
  });

  testWidgets('Given the Explore panel name when it is opened then the '
      'panel host shows it', (tester) async {
    current = tester;
    await pumpSheets(tester, s);
    await call('ui.sheets.open_panel', {'panel': 'explore'});
    expect(s.services.panels.isOpen('sheets.panel.explore'), isTrue);
    await call('ui.sheets.close_panel', {'panel': 'explore'});
    expect(s.services.panels.isOpen('sheets.panel.explore'), isFalse);
    await finish(tester);
  });

  test('Given no open spreadsheet when a tool runs then it fails with '
      'no_document', () async {
    s.services.deactivate(s.doc);
    await expectLater(
      call('ui.sheets.get_selection'),
      throwsA(
        isA<UiToolException>().having((e) => e.code, 'code', 'no_document'),
      ),
    );
    s.services.activate(s.doc);
  });
}
