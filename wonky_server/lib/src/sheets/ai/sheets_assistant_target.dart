import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart'
    show McpScope, McpToolDefinition, Role, SheetsTools, UiSheetsTools;

import '../../platform/ai/assistant_target.dart';
import '../../platform/ai/assistant_tools.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/ai/prompts/sheets_prompts.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/tool_executor.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/sharing/access_service.dart';
import '../headless/headless_workbook.dart';
import '../headless/headless_workbook_provider.dart';
import '../mcp/sheets_changes.dart';
import '../mcp/sheets_shadow.dart';
import 'sheets_ai_preview_service.dart';
import 'sheets_context_builder.dart';

/// The assistant bound to a spreadsheet (Sheets 12 §6): `sheets.*` tools
/// generated from the MCP registry with `spreadsheet` bound to the open
/// file, the Sheets system prompt, [SheetsContextBuilder] context, the
/// destructive guard (§6.13), Suggest-mode shadows (§6.3) and one undo
/// step per run (§6.2).
class SheetsAssistantTarget extends AssistantTarget {
  SheetsAssistantTarget(this.item, this.role);

  @override
  final DriveItem item;

  @override
  final Role role;

  UuidValue get space => item.contentRef!;

  static Future<SheetsAssistantTarget> resolve(
    Session session,
    Actor actor,
    DriveItem item,
  ) async {
    final role = await AccessService.requireRole(
      session,
      actor,
      item,
      Role.viewer,
    );
    return SheetsAssistantTarget(item, role);
  }

  /// Sheets 12 §6.2: every §3 tool except protection changes (editor
  /// lists), plus comments and the version list. Sharing, deletion of
  /// files, `changes.revert` and token management are never exposed.
  static final List<String> allowlist = [
    for (final t in SheetsTools.all)
      if (t.name != 'sheets.protect_range' &&
          t.name != 'sheets.unprotect' &&
          t.name != 'sheets.validate_formula')
        t.name,
    'comments.list',
    'comments.create',
    'comments.reply',
    'versions.list',
  ];

  @override
  Set<String> get scopes => {
    McpScope.sheetsRead,
    if (role >= Role.editor) McpScope.sheetsEdit,
    if (role >= Role.commenter) McpScope.writeEdit,
    McpScope.writeRead,
  };

  @override
  String get system => SheetsPrompts.assistant;

  @override
  AiApplyMode applyMode(AiApplyMode requested) => requested;

  @override
  AssistantToolset toolset(ToolExecutor executor) {
    final defs = <McpToolDefinition>[];
    for (final name in allowlist) {
      if (AssistantToolset.denied.contains(name)) continue;
      final t = executor[name];
      if (t == null) continue;
      final readOnly = t.definition.annotations.readOnly;
      final isComment = name.startsWith('comments.');
      if (!readOnly &&
          role < Role.editor &&
          !(isComment && role >= Role.commenter)) {
        continue;
      }
      defs.add(t.definition);
    }
    return AssistantToolset.of(defs);
  }

  /// `ui.sheets.*` tools the assistant may run in the requesting window
  /// (Sheets 12 §6.2).
  static final Set<String> windowTools = {
    UiSheetsTools.getSelection.name,
    UiSheetsTools.selectRange.name,
    UiSheetsTools.highlightRange.name,
  };

  @override
  List<McpToolDefinition> uiTools(AssistantContextHints hints) {
    final offered = hints.uiTools?.toSet() ?? const <String>{};
    return [
      for (final d in UiSheetsTools.all)
        if (windowTools.contains(d.name) && offered.contains(d.name)) d,
    ];
  }

  @override
  Future<(List<TextPart>, AssistantThread)> userTurn(
    Session session, {
    required AssistantThread thread,
    required bool first,
    required String message,
    required AssistantContextHints hints,
    required AiApplyMode applyMode,
    required Actor actor,
    required ToolExecutor executor,
  }) async {
    final wb = await HeadlessWorkbookProvider.open(session, space);
    final ctx = SheetsContextBuilder.build(
      wb,
      title: item.name,
      activeSheet: hints.sheetsActiveSheet,
    );
    final blocks = <TextPart>[];
    if (first) {
      blocks.add(TextPart(ctx.snapshot));
    } else if (thread.contextRevision != ctx.fingerprint) {
      blocks.add(TextPart(SheetsContextBuilder.update(ctx)));
    }
    blocks.add(
      TextPart(
        '$message\n\n${volatile(wb, hints: hints, applyMode: applyMode)}',
      ),
    );
    return (
      blocks,
      thread.copyWith(
        contextRevision: ctx.fingerprint,
        contextMarkdown: ctx.summary,
      ),
    );
  }

  /// The volatile context of a turn: mode, role, sheet, selection, active
  /// cell, visible range and local time.
  String volatile(
    HeadlessWorkbook wb, {
    required AssistantContextHints hints,
    required AiApplyMode applyMode,
  }) {
    final b = StringBuffer('<context>\n');
    b.writeln(
      'Apply mode: ${role < Role.editor
          ? 'read-only (the user cannot edit this spreadsheet)'
          : applyMode == AiApplyMode.suggest
          ? 'suggest (changes are recorded for review, not applied)'
          : 'edit (changes apply directly)'}',
    );
    b.writeln('User role: ${role.name}');
    if (hints.sheetsActiveSheet != null) {
      b.writeln('Active sheet: "${hints.sheetsActiveSheet}"');
    }
    final selection = hints.sheetsSelection ?? const [];
    if (selection.isNotEmpty) {
      b.write(SheetsContextBuilder.selection(wb, selection));
    }
    final active = SheetsContextBuilder.activeCell(wb, hints.sheetsActiveCell);
    if (active != null) b.writeln(active);
    if (hints.sheetsVisibleRange != null) {
      b.writeln('Visible range: ${hints.sheetsVisibleRange}');
    }
    if (hints.localTime != null) b.writeln('Local time: ${hints.localTime}');
    b.write('</context>');
    return b.toString();
  }

  @override
  ToolContext toolContext(
    Session session,
    Actor actor, {
    required String runId,
    required AssistantContextHints hints,
    required bool guarded,
  }) => ToolContext(
    session: session,
    actor: actor.copyWith(kind: ActorKind.ai),
    scopes: scopes,
    clientName: 'Assistant',
    groupId: runId,
    guardDestructive: guarded,
  );

  @override
  String startLabel(String tool) => switch (tool) {
    'sheets.get_spreadsheet' => 'Looking at the spreadsheet',
    'sheets.describe_data' => 'Profiling the data',
    'sheets.get_values' || 'sheets.get_cell' => 'Reading cells',
    'sheets.find' => 'Searching the spreadsheet',
    'sheets.evaluate' => 'Checking a formula',
    'sheets.explain_formula' => 'Reading a formula',
    'sheets.set_values' ||
    'sheets.batch_set_values' ||
    'sheets.append_rows' => 'Writing cells',
    'sheets.clear_range' => 'Clearing cells',
    'sheets.format_range' ||
    'sheets.clear_formats' ||
    'sheets.apply_banding' => 'Formatting cells',
    'sheets.sort_range' => 'Sorting',
    'sheets.find_replace' => 'Replacing text',
    'sheets.create_chart' || 'sheets.update_chart' => 'Building a chart',
    'sheets.create_pivot_table' ||
    'sheets.update_pivot_table' => 'Building a pivot table',
    'sheets.add_sheet' || 'sheets.duplicate_sheet' => 'Adding a sheet',
    'sheets.import_csv' => 'Importing data',
    'comments.list' => 'Reading comments',
    'comments.create' || 'comments.reply' => 'Commenting',
    'versions.list' => 'Reading the version history',
    'ui.sheets.get_selection' => 'Looking at your selection',
    'ui.sheets.select_range' => 'Selecting cells',
    'ui.sheets.highlight_range' => 'Pointing out cells',
    _ when tool.startsWith('sheets.list_') => 'Reading the spreadsheet',
    _ when tool.startsWith('sheets.') => 'Changing the spreadsheet',
    _ => 'Working',
  };

  @override
  String resultText(String tool, ToolResult result) =>
      AssistantTarget.jsonText(result);

  @override
  void annotate(AssistantToolActivity a, Map<Object?, Object?> r) {
    final s = r['summary'];
    if (s is String && s.isNotEmpty) a.summary = s;
    final change = r['change_id'];
    if (change is String) a.changeId = change;
    for (final key in ['updated_range', 'output_range', 'range']) {
      final v = r[key];
      if (v is String) {
        a.range = v;
        break;
      }
    }
    final ranges = r['updated_ranges'];
    if (a.range == null && ranges is List && ranges.isNotEmpty) {
      a.range = '${ranges.first}';
    }
    for (final key in ['chart_id', 'pivot_id', 'rule_id']) {
      final v = r[key];
      if (v is String) {
        a.objectId = v;
        break;
      }
    }
  }

  @override
  Future<void> beginRun(
    Session session,
    Actor actor, {
    required String runId,
    required AiApplyMode applyMode,
  }) async {
    if (applyMode != AiApplyMode.suggest || role < Role.editor) return;
    final wb = await HeadlessWorkbookProvider.open(session, space);
    SheetsShadows.begin(runId, wb, userId: actor.userId);
  }

  @override
  Future<void> endRun(
    Session session,
    Actor actor, {
    required String runId,
    required List<String> changeIds,
    required String title,
    required AssistantEvent done,
    required void Function(AssistantEvent) emit,
  }) async {
    final shadow = SheetsShadows.end(runId);
    if (shadow != null) {
      await SheetsAiPreviews.persistPreview(session, shadow, item.uuid);
      done.previewId = shadow.previewId;
      emit(
        AssistantEvent(
          type: AssistantEventType.previewReady,
          threadId: done.threadId,
          runId: runId,
          previewId: shadow.previewId,
          toolSummary:
              '${shadow.calls.length} suggested change'
              '${shadow.calls.length == 1 ? '' : 's'}',
        ),
      );
      return;
    }
    if (changeIds.isEmpty) return;
    // One undo step for the whole run (Sheets 12 §6.2).
    final composite = await SheetsChanges.composite(
      session,
      actor: actor.copyWith(kind: ActorKind.ai),
      item: item,
      changeIds: changeIds,
      label: 'AI: ${_short(title)}',
    );
    done.changeId = composite?.uuid;
  }

  static String _short(String s) =>
      s.length <= 60 ? s : '${s.substring(0, 57)}…';
}
