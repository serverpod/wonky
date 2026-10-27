import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart'
    show McpScope, McpToolDefinition, Role;

import 'package:wonky_write_core/wonky_write_core.dart' show MarkdownFlavor;

import '../../sheets/ai/sheets_assistant_target.dart';
import '../../slides/ai/slides_assistant_target.dart';
import '../../write/ai/write_context_builder.dart';
import '../../write/ai/write_prompts.dart';
import '../../write/mcp/headless_editor.dart';
import '../common/actor.dart';
import '../common/models.dart';
import '../mcp/tool_executor.dart';
import '../mcp/tool_support.dart';
import '../sharing/access_service.dart';
import 'assistant_service.dart';
import 'assistant_tools.dart';
import 'llm/ai_client.dart';

/// What a chip of the panel shows about a tool call (persisted in
/// `toolCallsJson`, Write 09 §5, Sheets 12 §6.3).
class AssistantToolActivity {
  AssistantToolActivity({
    required this.toolUseId,
    required this.toolName,
    required this.summary,
    this.error = false,
    this.changeId,
    this.rangeStart,
    this.rangeLength,
    this.revision,
    this.range,
    this.objectId,
  });

  final String toolUseId;
  final String toolName;
  String summary;
  bool error;
  String? changeId;
  int? rangeStart;
  int? rangeLength;
  int? revision;

  /// Sheets: the A1 range written/read and the created object (Show).
  String? range;
  String? objectId;

  Map<String, Object?> toJson() => {
    'toolUseId': toolUseId,
    'toolName': toolName,
    'summary': summary,
    if (error) 'error': true,
    'changeId': ?changeId,
    'rangeStart': ?rangeStart,
    'rangeLength': ?rangeLength,
    'revision': ?revision,
    'range': ?range,
    'objectId': ?objectId,
  };
}

/// The file an assistant run works on and everything that differs between
/// apps (suite 10 §2): the tools bound to the file, the frozen system
/// prompt, the context of each user turn, tool contexts and the end of a
/// run (undo grouping, previews).
abstract class AssistantTarget {
  DriveItem get item;
  Role get role;

  /// The token scopes of the run's tool calls.
  Set<String> get scopes;

  /// The frozen system prompt.
  String get system;

  /// The effective apply mode (viewers/commenters may be forced to
  /// suggest).
  AiApplyMode applyMode(AiApplyMode requested);

  /// The tools of the file.
  AssistantToolset toolset(ToolExecutor executor);

  /// `ui.*` tools the requesting window runs for the assistant (Sheets 12
  /// §6.2), from the window's [AssistantContextHints.uiTools]. They are
  /// relayed to that window through the chat stream (`uiToolCall`).
  List<McpToolDefinition> uiTools(AssistantContextHints hints) => const [];

  /// The user turn: context blocks (the cached snapshot on the first turn,
  /// a "changed" element later) and the message with the volatile context
  /// at its end. Updates the thread's context fields.
  Future<(List<TextPart>, AssistantThread)> userTurn(
    Session session, {
    required AssistantThread thread,
    required bool first,
    required String message,
    required AssistantContextHints hints,
    required AiApplyMode applyMode,
    required Actor actor,
    required ToolExecutor executor,
  });

  /// The tool context of one call; [guarded] turns the destructive guard
  /// on (off after the user allowed the call).
  ToolContext toolContext(
    Session session,
    Actor actor, {
    required String runId,
    required AssistantContextHints hints,
    required bool guarded,
  });

  /// "Reading the document" — the chip text while a tool runs.
  String startLabel(String tool);

  /// The tool result text given to the model.
  String resultText(String tool, ToolResult result);

  /// Fills a chip from a tool's structured result.
  void annotate(AssistantToolActivity activity, Map<Object?, Object?> result);

  /// Before the first model call of a run.
  Future<void> beginRun(
    Session session,
    Actor actor, {
    required String runId,
    required AiApplyMode applyMode,
  }) async {}

  /// After the run: [done] (the last event) may be annotated, e.g. with
  /// the run's single undo step or its preview; [emit] sends extra events
  /// before it.
  Future<void> endRun(
    Session session,
    Actor actor, {
    required String runId,
    required List<String> changeIds,
    required String title,
    required AssistantEvent done,
    required void Function(AssistantEvent) emit,
  }) async {}

  /// A tool result as JSON text (uuids and dates as strings).
  static String jsonText(ToolResult r) =>
      jsonEncode(_jsonSafe(r.structured ?? r.text));

  static Object? _jsonSafe(Object? v) => switch (v) {
    null || String() || num() || bool() => v,
    Map() => <String, Object?>{
      for (final e in v.entries) '${e.key}': _jsonSafe(e.value),
    },
    Iterable() => [for (final e in v) _jsonSafe(e)],
    UuidValue() => v.uuid,
    DateTime() => v.toUtc().toIso8601String(),
    _ => '$v',
  };

  /// Resolves the target of [itemUuid] (a drive item uuid, or a document
  /// uuid for Write).
  static Future<AssistantTarget> resolve(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final item = await AccessService.findItem(session, itemUuid);
    if (item != null && item.kind == DriveItemKind.spreadsheet) {
      return SheetsAssistantTarget.resolve(session, actor, item);
    }
    if (item != null && item.kind == DriveItemKind.presentation) {
      return SlidesAssistantTarget.resolve(session, actor, item);
    }
    return WriteAssistantTarget(
      await HeadlessDocumentEditor.resolve(session, actor, itemUuid),
    );
  }
}

/// The assistant on a Wonky Write document (Write 09 §5).
class WriteAssistantTarget extends AssistantTarget {
  WriteAssistantTarget(this.target);

  final WriteTarget target;

  @override
  DriveItem get item => target.item;

  @override
  Role get role => target.role;

  @override
  Set<String> get scopes => {McpScope.writeRead, McpScope.writeEdit};

  @override
  String get system => WritePrompts.forFlavor(
    WritePrompts.assistant,
    MarkdownFlavor.parse(target.document.markdownFlavor),
  );

  @override
  AiApplyMode applyMode(AiApplyMode requested) =>
      role < Role.editor ? AiApplyMode.suggest : requested;

  @override
  AssistantToolset toolset(ToolExecutor executor) => AssistantToolset.write(
    executor,
    canDecideSuggestions: role >= Role.editor,
  );

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
    final ctx = await WriteContextBuilder.load(session, target);
    final selection = WriteContextBuilder.selection(
      ctx,
      start: hints.selectionStart,
      length: hints.selectionLength,
      text: hints.selectionText,
    );
    final blocks = <TextPart>[];
    if (first) {
      blocks.add(
        TextPart(
          WriteContextBuilder.snapshot(
            ctx,
            focusOffset: selection?.start ?? hints.selectionStart,
          ),
        ),
      );
    } else if (thread.contextRevision != ctx.revision) {
      final update = WriteContextBuilder.update(
        previousMarkdown: thread.contextMarkdown,
        previousRevision: thread.contextRevision,
        now: ctx,
      );
      if (update != null) blocks.add(TextPart(update));
    }
    String? comments;
    if (hints.includeComments) {
      final out = await executor.call(
        ToolContext(
          session: session,
          actor: actor.copyWith(kind: ActorKind.ai),
          scopes: {McpScope.writeRead},
        ),
        'comments.list',
        {'uuid': target.item.uuid.uuid, 'status': 'open'},
      );
      comments = out.result?.text;
    }
    final caret = hints.selectionStart;
    blocks.add(
      TextPart(
        '$message\n\n${WriteContextBuilder.volatile(
          c: ctx,
          applyMode: applyMode,
          role: target.role.name,
          selection: selection,
          caretHeadingPath: hints.caretHeadingPath ?? (caret == null ? null : WriteContextBuilder.headingPath(ctx, caret)),
          localTime: hints.localTime,
          comments: comments,
        )}',
      ),
    );
    return (
      blocks,
      thread.copyWith(
        contextRevision: ctx.revision,
        contextMarkdown: ctx.markdown,
      ),
    );
  }

  @override
  ToolContext toolContext(
    Session session,
    Actor actor, {
    required String runId,
    required AssistantContextHints hints,
    required bool guarded,
  }) {
    return ToolContext(
      session: session,
      actor: actor.copyWith(kind: ActorKind.ai),
      scopes: scopes,
      clientName: 'Assistant',
      groupId: runId,
      onBehalfOfSessionId: hints.documentSessionId,
      changeGuard: guarded
          ? (head, change, _) {
              final v = AssistantService.guardViolation(head, change);
              if (v != null) throw v;
            }
          : null,
    );
  }

  @override
  String startLabel(String tool) => switch (tool) {
    'write.get_document' => 'Reading the document',
    'write.get_outline' => 'Reading the outline',
    'write.get_stats' => 'Counting words',
    'write.search' => 'Searching the document',
    'write.get_page_setup' => 'Reading the page setup',
    'write.insert_markdown' => 'Adding text',
    'write.replace_text' => 'Replacing text',
    'write.replace_range' => 'Rewriting text',
    'write.delete_range' => 'Deleting text',
    'write.apply_format' => 'Formatting text',
    'write.set_block_type' => 'Changing block types',
    'write.insert_table' => 'Inserting a table',
    'write.update_table' => 'Editing a table',
    'write.list_suggestions' => 'Reading suggestions',
    'write.suggest_edit' => 'Suggesting an edit',
    'write.accept_suggestion' => 'Accepting suggestions',
    'write.reject_suggestion' => 'Rejecting suggestions',
    'comments.list' => 'Reading comments',
    'comments.create' => 'Adding a comment',
    'comments.reply' => 'Replying to a comment',
    'versions.list' => 'Reading the version history',
    'versions.get' => 'Reading a version',
    'write.list_themes' => 'Looking at themes',
    'write.apply_theme' => 'Applying a theme',
    'write.update_page_setup' => 'Changing the page setup',
    _ => 'Working',
  };

  @override
  String resultText(String tool, ToolResult result) =>
      tool == 'write.get_document'
      ? result.text
      : AssistantTarget.jsonText(result);

  @override
  void annotate(AssistantToolActivity a, Map<Object?, Object?> r) {
    final s = r['summary'];
    if (s is String && s.isNotEmpty) a.summary = s;
    final change = r['change_id'];
    if (change is String) a.changeId = change;
    final rev = r['revision'];
    if (rev is int) a.revision = rev;
    final range = r['applied_range'];
    if (range is Map) {
      a.rangeStart = (range['start'] as num?)?.toInt();
      a.rangeLength = (range['length'] as num?)?.toInt();
    }
  }
}
