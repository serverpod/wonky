import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_sheets_core/formula.dart' show CellPos, GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart'
    show paintChartScene;

import '../features/ai/agent_highlight_layer.dart';
import '../features/ai/sheets_a1.dart';
import '../features/ai/sheets_ai_controller.dart';
import '../features/cell_editor/cell_editor_controller.dart';
import '../features/explore/explore_panel.dart' show explorePanelId;
import '../features/grid/paint/grid_layer.dart';
import '../features/grid/paint/layers/content_layers.dart';
import '../features/grid/paint/layers/overlay_layers.dart' show HeaderLayer;
import '../features/grid/selection/grid_selection.dart';
import '../features/grid/viewport/grid_geometry.dart';
import '../features/charts/controller/chart_controller.dart'
    show chartDarkOf, chartUiTokensOf;
import '../features/charts/chart_insert.dart' show chartEditorPanelId;
import '../features/charts/editor/chart_editor_mcp.dart';
import '../features/images/image_object_view.dart' show boxFitOf;
import '../features/images/image_service.dart';
import '../features/objects/objects_controller.dart';
import '../features/sheet_editor/sheet_editor_controller.dart';
import '../features/sheet_editor/sheets_document_controller.dart';
import '../features/status/selection_stats.dart';
import '../theme/sheets_tokens.dart';

part 'ui_sheets_screenshot.dart';

/// Wonky Sheets' UI-bridge tools (`ui.sheets.*`, Sheets 12 §5), executed in
/// the live window on the open spreadsheet. Writes go through commands
/// (source `mcp`), so they land on the user's undo stack; ranges an agent
/// works on are flashed with its name (agent presence highlight).
abstract final class UiSheetsToolHandlers {
  static Map<String, UiToolHandler> all(ShellServices services) => {
    'ui.sheets.get_selection': getSelection,
    'ui.sheets.select_range': selectRange,
    'ui.sheets.get_visible_range': getVisibleRange,
    'ui.sheets.activate_sheet': activateSheet,
    'ui.sheets.scroll_to': scrollTo,
    'ui.sheets.open_panel': openPanel,
    'ui.sheets.close_panel': closePanel,
    'ui.sheets.describe_panel': describePanel,
    'ui.sheets.set_panel_field': setPanelField,
    'ui.sheets.press_panel_button': pressPanelButton,
    'ui.sheets.start_cell_edit': startCellEdit,
    'ui.sheets.type_in_cell': typeInCell,
    'ui.sheets.screenshot_range': _UiSheetsScreenshot.screenshotRange,
    'ui.sheets.highlight_range': highlightRange,
    'ui.sheets.wait_for_recalc': waitForRecalc,
  };

  /// Panel names of `ui.sheets.open_panel` → (command, panel id).
  static const panels = <String, (String?, String)>{
    'chartEditor': ('sheets.chart.edit', 'sheets.panel.chartEditor'),
    'conditionalFormatting': (
      'sheets.cf.openPanel',
      'sheets.panel.conditionalFormatting',
    ),
    'dataValidation': ('sheets.dv.openPanel', 'sheets.panel.dataValidation'),
    'pivotEditor': ('sheets.pivot.openEditor', 'sheets.panel.pivotEditor'),
    'namedRanges': ('sheets.namedRanges.openPanel', 'sheets.panel.namedRanges'),
    'protectedRanges': ('sheets.protect.openPanel', 'sheets.panel.protected'),
    'comments': ('sheets.comments.openPanel', ShellPanels.comments),
    'history': (null, ShellPanels.history),
    'assistant': (null, ShellPanels.assistant),
    'explore': (null, explorePanelId),
    'executions': ('sheets.script.openExecutions', 'sheets.panel.executions'),
    'scriptSidebar': (null, 'sheets.panel.scriptSidebar'),
    'slicer': ('sheets.slicer.add', 'sheets.panel.slicer'),
  };

  static SheetEditorController _editor(UiToolContext c) {
    final d = c.services.activeDocument.value;
    final ed = d is SheetsDocumentController ? d.editor : null;
    if (ed == null) {
      throw const UiToolException(
        'no_document',
        'No Wonky Sheets spreadsheet is open (or it is still loading) in '
            'this window. Open one with ui.navigate {"open_item_uuid": …}.',
      );
    }
    return ed;
  }

  static ResolvedRange _parse(SheetEditorController ed, String a1) {
    try {
      return ed.model.parseA1(a1, contextSheetId: ed.activeSheetId);
    } on InvalidRangeException catch (e) {
      throw UiToolException('invalid_range', e.message);
    }
  }

  static String _agent(UiToolContext c) => c.agentName ?? 'MCP agent';

  /// Flashes [rr] with the agent's name (presence highlight).
  static void _flash(
    UiToolContext c,
    SheetEditorController ed,
    ResolvedRange rr, {
    Duration duration = const Duration(seconds: 5),
    Color color = AgentHighlightLayer.agentColor,
  }) {
    SheetsAiController.of(ed).highlights.flash(
      AgentHighlight(
        sheetId: rr.sheetId,
        rect: _clip(ed, rr),
        label: _agent(c),
        color: color,
      ),
      duration: duration,
    );
  }

  /// Whole rows/columns clipped to the used range (at least A1).
  static GridRect _clip(SheetEditorController ed, ResolvedRange rr) {
    if (!rr.wholeRows && !rr.wholeColumns) return rr.rect;
    final used = ed.model.sheet(rr.sheetId)?.usedRect();
    if (used == null) {
      return GridRect(rr.rect.top, rr.rect.left, rr.rect.top, rr.rect.left);
    }
    return rr.rect.intersection(used) ?? used;
  }

  static String _rangeA1(SheetEditorController ed, ResolvedRange rr) =>
      qualifiedA1(
        ed.sheetName(rr.sheetId),
        rectA1(rr.rect, wholeRows: rr.wholeRows, wholeColumns: rr.wholeColumns),
      );

  // ---------------------------------------------------------------- state

  /// The selection JSON of [ed].
  static Map<String, Object?> selectionOf(SheetEditorController ed) {
    final sel = ed.selection.resolved;
    final sheet = ed.activeSheet;
    final values = <List<String>>[];
    final rect = sel.activeRange.rect;
    final grid = sheet?.gridRect;
    final shown = grid == null ? null : rect.intersection(grid);
    var cells = 0;
    if (sheet != null && shown != null) {
      for (var r = shown.top; r <= shown.bottom && cells < 100; r++) {
        final row = <String>[];
        for (var c = shown.left; c <= shown.right && cells < 100; c++) {
          row.add(ed.cells.displayAt(sheet.id, r, c)?.text ?? '');
          cells++;
        }
        values.add(row);
      }
    }
    final multi = selectionIsMulti(ed);
    final stats = multi ? SelectionStats.of(ed, cap: 200000) : null;
    final object = ObjectsController.maybeOf(ed)?.selectedId;
    return {
      'sheet': sheet?.name,
      'sheet_id': ed.activeSheetId,
      'active_cell': CellPos(sel.activeRow, sel.activeCol).a1,
      'ranges': [
        for (final x in sel.ranges)
          rectA1(
            x.rect,
            wholeRows: x.kind == SelectionKind.rows,
            wholeColumns: x.kind == SelectionKind.columns,
          ),
      ],
      'editing': ed.editor.isEditing,
      if (ed.editor.isEditing) 'editor_text': ed.editor.text.text,
      'object_selected': ?(object == null ? null : {'object_id': object}),
      'values_preview': values,
      'values_truncated': rect.cellCount > cells,
      if (stats != null && stats.count > 0) ...{
        'sum': stats.sum,
        'average': stats.average,
        'count': stats.count,
        'count_numbers': stats.countNumbers,
        'min': stats.min,
        'max': stats.max,
      },
      'can_edit': ed.canEdit,
    };
  }

  static Future<UiToolResult> getSelection(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final s = selectionOf(_editor(c));
    final ranges = (s['ranges']! as List).join(', ');
    return UiToolResult(
      s,
      text: '${s['sheet']}!$ranges (active ${s['active_cell']})',
    );
  }

  static Future<UiToolResult> selectRange(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    final texts = [for (final r in a['ranges']! as List) '$r'];
    final sheetArg = a['sheet'] as String?;
    if (sheetArg != null) {
      final sh = _sheetByNameOrId(ed, sheetArg);
      if (sh.id != ed.activeSheetId) ed.activateSheet(sh.id);
    }
    final parsed = [for (final t in texts) _parse(ed, t)];
    final sheetId = parsed.first.sheetId;
    if (parsed.any((p) => p.sheetId != sheetId)) {
      throw const UiToolException(
        'invalid_range',
        'All ranges must be on one sheet.',
      );
    }
    if (ed.editor.isEditing) ed.editor.commitSync(move: CommitMove.none);
    if (sheetId != ed.activeSheetId) ed.activateSheet(sheetId);
    ed.selection.setRanges([
      for (final p in parsed)
        (
          p.wholeSheet
              ? SelectionKind.all
              : p.wholeRows
              ? SelectionKind.rows
              : p.wholeColumns
              ? SelectionKind.columns
              : SelectionKind.cells,
          p.rect,
        ),
    ]);
    final activeText = a['active_cell'] as String?;
    if (activeText != null) {
      final act = _parse(ed, activeText);
      final sel = ed.selection.resolved;
      var idx = sel.ranges.indexWhere(
        (r) => r.rect.contains(act.rect.top, act.rect.left),
      );
      if (idx < 0) {
        throw const UiToolException(
          'invalid_args',
          'active_cell must lie inside one of the ranges.',
        );
      }
      ed.selection.setActiveInSelection(idx, act.rect.top, act.rect.left);
    }
    final r = ed.selection.resolved;
    ed.revealCell(r.activeRow, r.activeCol);
    for (final p in parsed) {
      _flash(c, ed, p);
    }
    await uiSettle();
    return UiToolResult(selectionOf(ed), text: 'Selected ${texts.join(', ')}');
  }

  static SheetModel _sheetByNameOrId(SheetEditorController ed, String s) {
    final byId = ed.model.sheet(s);
    if (byId != null) return byId;
    for (final sh in ed.model.sheets) {
      if (sh.name.toLowerCase() == s.toLowerCase()) return sh;
    }
    throw UiToolException(
      'not_found',
      'No sheet "$s". Sheets: ${[for (final x in ed.model.sheets) x.name].join(', ')}.',
    );
  }

  static Future<UiToolResult> getVisibleRange(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    await uiSettle();
    final g = ed.geometry;
    final sheet = ed.activeSheet;
    String? range;
    if (g != null && !g.main.isEmpty) {
      final (r0, r1) = g.visibleRows;
      final (c0, c1) = g.visibleCols;
      range = GridRect(
        g.frozenRows > 0 ? 0 : r0,
        g.frozenCols > 0 ? 0 : c0,
        r1,
        c1,
      ).a1;
    }
    return UiToolResult({
      'sheet': sheet?.name,
      'range': range,
      'frozen': {
        'rows': sheet?.record?.frozenRows ?? 0,
        'columns': sheet?.record?.frozenColumns ?? 0,
      },
      'zoom': (ed.scroll.zoom * 100).round(),
    }, text: '${sheet?.name}!$range');
  }

  static Future<UiToolResult> activateSheet(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    final sh = _sheetByNameOrId(ed, a['sheet']! as String);
    if (sh.record?.hidden ?? false) {
      throw UiToolException(
        'disabled',
        'Sheet "${sh.name}" is hidden. Unhide it with ui.invoke_command '
            '{"command_id": "sheets.sheet.unhide", "args": {"sheetId": '
            '"${sh.id}"}}.',
      );
    }
    ed.activateSheet(sh.id);
    await uiSettle();
    return UiToolResult({
      'sheet': sh.name,
      'sheet_id': sh.id,
    }, text: 'Activated ${sh.name}');
  }

  static Future<UiToolResult> scrollTo(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    final rr = _parse(ed, a['cell']! as String);
    if (rr.sheetId != ed.activeSheetId) ed.activateSheet(rr.sheetId);
    final row = rr.rect.top;
    final col = rr.rect.left;
    await uiSettle();
    final g = ed.geometry;
    final align = a['align'] as String?;
    if (g != null && align != null) {
      final geom = g;
      final sheet = ed.activeSheet!;
      final x =
          (sheet.columns.offsetOf(col) -
              sheet.columns.offsetOf(geom.frozenCols)) *
          geom.zoom;
      final y =
          (sheet.rows.offsetOf(row) - sheet.rows.offsetOf(geom.frozenRows)) *
          geom.zoom;
      final dx = align == 'center' ? geom.main.rect.width / 2 : 0.0;
      final dy = align == 'center' ? geom.main.rect.height / 2 : 0.0;
      ed.scroll.jumpTo(
        math.max(0, math.min(geom.maxScrollX, x - dx)),
        math.max(0, math.min(geom.maxScrollY, y - dy)),
      );
    } else {
      ed.revealCell(row, col);
    }
    _flash(c, ed, rr, duration: const Duration(seconds: 2));
    await uiSettle();
    return UiToolResult({
      'cell': _rangeA1(ed, rr),
    }, text: 'Scrolled to ${a['cell']}');
  }

  static Future<UiToolResult> openPanel(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    final name = a['panel']! as String;
    final entry = panels[name];
    if (entry == null) {
      throw UiToolException('invalid_args', 'Unknown panel "$name".');
    }
    final (command, panelId) = entry;
    final target = (a['target'] as Map?)?.cast<String, Object?>() ?? const {};
    final s = c.services;
    var opened = false;
    if (command != null && s.registry.byId(command) != null) {
      final args = <String, Object?>{
        if (target['chart_id'] != null) 'objectId': target['chart_id'],
        if (target['pivot_id'] != null) 'pivotId': target['pivot_id'],
        if (target['rule_id'] != null) 'ruleId': target['rule_id'],
      };
      final state = s.dispatcher.stateOf(command, args);
      if (state.enabled) {
        final r = await s.dispatcher.invoke(
          command,
          args: args,
          source: InvocationSource.mcp,
          context: c.context,
        );
        opened = r.isOk;
      }
    }
    if (!opened) {
      s.panels.open(panelId);
      await uiSettle();
      opened = s.panels.isOpen(panelId);
    }
    if (!opened) {
      throw UiToolException(
        'unsupported',
        'The $name panel is not available in this spreadsheet.',
      );
    }
    await uiSettle();
    ed.overlaySignal.fire();
    return UiToolResult({
      'panel': name,
      'panel_id': s.panels.activePanelId,
    }, text: 'Opened $name');
  }

  static Future<UiToolResult> closePanel(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    _editor(c);
    final s = c.services;
    final name = a['panel'] as String?;
    final id = name == null ? s.panels.activePanelId : panels[name]?.$2;
    if (id != null) s.panels.close(id);
    await uiSettle();
    return UiToolResult({'closed': id}, text: 'Closed ${name ?? id ?? '—'}');
  }

  /// The open panel (or `panel`, when it is the open one) for the
  /// describe/set/press tools.
  static PanelDescriber _panel(UiToolContext c, Map<String, Object?> a) {
    _editor(c);
    final name = a['panel'] as String?;
    final id = name == null ? null : (panels[name]?.$2 ?? name);
    final p = PanelDescriber.of(c.services, panelId: id);
    if (p == null) {
      throw UiToolException(
        'not_found',
        id == null
            ? 'No side panel is open. Open one with ui.sheets.open_panel.'
            : 'The panel "$name" is not open. Open it with '
                  'ui.sheets.open_panel.',
      );
    }
    return p;
  }

  static String? _panelTitle(UiToolContext c, String id) {
    for (final e in panels.entries) {
      if (e.value.$2 == id) return e.key;
    }
    return null;
  }

  /// `ui.sheets.describe_panel` (12 §5, P1).
  static Future<UiToolResult> describePanel(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    await uiSettle();
    final p = _panel(c, a);
    final d = p.describe(title: _panelTitle(c, p.panelId));
    // The chart editor also describes its fields by spec path (08 §8.4).
    if (p.panelId == chartEditorPanelId) {
      final chart = ChartEditorMcp.describe(_editor(c));
      if (chart != null) d['chart'] = chart;
    }
    final fields = (d['fields']! as List).length;
    final buttons = (d['buttons']! as List).length;
    return UiToolResult(
      d,
      text: 'Panel ${p.panelId}: $fields fields, $buttons buttons',
    );
  }

  /// `ui.sheets.set_panel_field` (12 §5, P1).
  static Future<UiToolResult> setPanelField(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final p = _panel(c, a);
    final id = a['field_id']! as String;
    // Chart editor fields by spec path (`title.text`, `series.<key>.color`,
    // see `chart.fields` of describe_panel; 08 §8.4).
    if (p.panelId == chartEditorPanelId) {
      final ed = _editor(c);
      final fields = ChartEditorMcp.describe(ed)?['fields'] as List?;
      if (fields != null && fields.any((f) => (f as Map)['id'] == id)) {
        final error = await ChartEditorMcp.setField(ed, id, a['value']);
        if (error != null) {
          throw UiToolException('invalid_args', error);
        }
        await uiSettle();
        return UiToolResult({
          'set': id,
          'chart': ChartEditorMcp.describe(ed),
        }, text: 'Set $id');
      }
    }
    final error = p.setField(id, a['value']);
    if (error != null) {
      throw UiToolException(
        'invalid_args',
        error,
        details: {'panel': p.describe()},
      );
    }
    await uiSettle();
    final after = PanelDescriber.of(c.services);
    return UiToolResult({
      'set': id,
      'panel': after?.describe(),
    }, text: 'Set $id');
  }

  /// `ui.sheets.press_panel_button` (12 §5, P1).
  static Future<UiToolResult> pressPanelButton(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final p = _panel(c, a);
    final id = a['button_id']! as String;
    final error = p.press(id);
    if (error != null) {
      throw UiToolException(
        'invalid_args',
        error,
        details: {'panel': p.describe()},
      );
    }
    await uiSettle();
    c.events.add('panel', {'pressed': id, 'panel': p.panelId});
    final after = PanelDescriber.of(c.services);
    return UiToolResult({
      'pressed': id,
      'panel': after?.describe(),
    }, text: 'Pressed $id');
  }

  // ------------------------------------------------------------- editing

  static Future<SheetEditorController> _beginAt(
    UiToolContext c,
    String? cell,
    String? text,
  ) async {
    final ed = _editor(c);
    if (!ed.canEdit) {
      throw const UiToolException(
        'forbidden',
        'The spreadsheet cannot be edited in the current mode or role.',
      );
    }
    if (ed.editor.isEditing) {
      // The user is typing: their text is committed first (as their own
      // edit, like clicking another cell in Sheets), never dropped (CQ-54).
      await ed.editor.commit(move: CommitMove.none);
      if (ed.editor.isEditing) {
        throw const UiToolException(
          'busy',
          'The user is editing a cell and their input was rejected (data '
              'validation); try again when they are done.',
        );
      }
    }
    if (cell != null) {
      final rr = _parse(ed, cell);
      if (rr.sheetId != ed.activeSheetId) ed.activateSheet(rr.sheetId);
      ed.selection.selectCell(rr.rect.top, rr.rect.left);
      _flash(c, ed, rr, duration: const Duration(seconds: 3));
    }
    ed.gridFocus.requestFocus();
    ed.editor.begin(initialText: text, mode: EditMode.edit);
    await uiSettle();
    if (!ed.editor.isEditing) {
      throw const UiToolException(
        'forbidden',
        'The cell cannot be edited (protected or a pivot/spill area).',
      );
    }
    return ed;
  }

  static Future<UiToolResult> startCellEdit(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = await _beginAt(
      c,
      a['cell'] as String?,
      a['initial_text'] as String?,
    );
    return UiToolResult({
      'cell': ed.activeA1,
      'editor_text': ed.editor.text.text,
    }, text: 'Editing ${ed.activeA1}');
  }

  static Future<UiToolResult> typeInCell(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = await _beginAt(c, a['cell']! as String, '');
    final text = a['text']! as String;
    // Through the field's text input, like typing (autocomplete updates).
    final field = ed.editor.text;
    for (final ch in text.characters) {
      final v = field.value;
      final next = v.text + ch;
      field.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    }
    await uiSettle();
    final commit = a['commit'] as String? ?? 'enter';
    final cell = ed.activeA1;
    var ok = true;
    if (commit != 'none') {
      // The agent's write: labelled and gated as an agent's (08 §3.4).
      ok = await ed.editor.commit(
        move: commit == 'tab' ? CommitMove.tab : CommitMove.enter,
        source: InvocationSource.mcp,
      );
    }
    await uiSettle();
    if (!ok) {
      throw UiToolException(
        'rejected',
        'The input was rejected (data validation): ${ed.editor.text.text}',
      );
    }
    final rr = _parse(ed, cell);
    return UiToolResult({
      'cell': cell,
      'committed': commit != 'none',
      'display': ed.cells
          .displayAt(rr.sheetId, rr.rect.top, rr.rect.left)
          ?.text,
      'active_cell': ed.activeA1,
    }, text: 'Typed into $cell');
  }

  // ------------------------------------------------------------- misc

  static Future<UiToolResult> highlightRange(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    final rr = _parse(ed, a['range']! as String);
    if (rr.sheetId != ed.activeSheetId) ed.activateSheet(rr.sheetId);
    final rect = _clip(ed, rr);
    ed.revealCell(rect.top, rect.left);
    final color = _color(a['color'] as String?);
    final ms = (a['duration_ms'] as num?)?.toInt() ?? 3000;
    _flash(
      c,
      ed,
      rr,
      duration: Duration(milliseconds: ms),
      color: color ?? AgentHighlightLayer.agentColor,
    );
    await uiSettle();
    return UiToolResult({
      'range': _rangeA1(ed, rr),
      'duration_ms': ms,
    }, text: 'Highlighted ${_rangeA1(ed, rr)}');
  }

  static Color? _color(String? hex) {
    if (hex == null || hex.length != 7) return null;
    final v = int.tryParse(hex.substring(1), radix: 16);
    return v == null ? null : Color(0xff000000 | v);
  }

  static Future<UiToolResult> waitForRecalc(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = _editor(c);
    final timeout = Duration(
      milliseconds: (a['timeout_ms'] as num?)?.toInt() ?? 10000,
    );
    final sw = Stopwatch()..start();
    var idle = ed.engine.isIdle;
    while (!idle && sw.elapsed < timeout) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      idle = ed.engine.isIdle;
    }
    if (idle) {
      await ed.session.flush().timeout(
        timeout - sw.elapsed > Duration.zero
            ? timeout - sw.elapsed
            : Duration.zero,
        onTimeout: () {},
      );
    }
    return UiToolResult({
      'idle': idle,
      'pending': ed.engine.pendingCount,
      'waited_ms': sw.elapsedMilliseconds,
    }, text: idle ? 'Idle' : 'Still calculating');
  }
}
