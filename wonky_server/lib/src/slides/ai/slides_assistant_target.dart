import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart'
    show McpScope, McpToolDefinition, Role, SlidesTools;
import 'package:wonky_slides_core/model.dart' show DeckModel;

import '../../platform/ai/assistant_target.dart';
import '../../platform/ai/assistant_tools.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/tool_executor.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/revlog/server_change_records.dart';
import '../../platform/sharing/access_service.dart';
import '../revlog/slides_revlog.dart';
import 'slides_context_builder.dart';
import 'slides_prompts.dart';
import 'slides_shadow.dart';

/// The assistant bound to a presentation (Slides 11 §6.2–§6.3, suite 10
/// §3.1): the headless `slides.*` tools with `deck` bound to the open
/// presentation and `force` removed, the Slides system prompt,
/// [SlidesContextBuilder] context (deck summary cached; current slide and
/// selection volatile), the confirmations of 11 §8.1 (`guardDestructive`),
/// Suggest-mode shadow decks with an AI changes preview, and one undo step
/// per Edit-mode run (a composite `ServerChangeRecord`).
class SlidesAssistantTarget extends AssistantTarget {
  SlidesAssistantTarget(this.item, this.role);

  @override
  final DriveItem item;

  @override
  final Role role;

  UuidValue get space => item.contentRef!;

  static Future<SlidesAssistantTarget> resolve(
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
    return SlidesAssistantTarget(item, role);
  }

  /// Tools that are never offered (11 §6.3, §8.2): creating presentations
  /// (the panel offers *Generate presentation* instead), exports and
  /// renders (no export by the AI; `render_slide` is unsupported).
  /// Sharing, trash, `changes.revert`, image URLs and `force` are not
  /// `slides.*` tools or are removed from the schemas.
  static const excluded = {
    'drive.create_presentation',
    'slides.export_pdf',
    'slides.render_slide',
    'slides.copy_slides_to_deck',
  };

  /// The tools of 11 §6.3 (`comments.*` and `versions.list` join when they
  /// support presentation anchors; TODO "Wonky Slides — later").
  static final List<String> allowlist = [
    for (final t in SlidesTools.all)
      if (!excluded.contains(t.name)) t.name,
  ];

  @override
  Set<String> get scopes => {
    McpScope.slidesRead,
    if (role >= Role.editor) McpScope.slidesEdit,
    // Linked charts read the spreadsheets the user can open (08 §6).
    McpScope.sheetsRead,
  };

  @override
  String get system => SlidesPrompts.assistant;

  @override
  AiApplyMode applyMode(AiApplyMode requested) => requested;

  @override
  AssistantToolset toolset(ToolExecutor executor) {
    final defs = <McpToolDefinition>[];
    for (final name in allowlist) {
      if (AssistantToolset.denied.contains(name)) continue;
      final t = executor[name];
      if (t == null) continue;
      if (!t.definition.annotations.readOnly && role < Role.editor) continue;
      defs.add(t.definition);
    }
    return AssistantToolset.of(defs, bindMode: false, strip: const {'force'});
  }

  Future<DeckModel> _model(Session session) async =>
      SlidesRevlog.model(session, space);

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
    final m = await _model(session);
    final ctx = SlidesContextBuilder.build(m, title: item.name);
    final blocks = <TextPart>[];
    if (first) {
      blocks.add(TextPart(ctx.snapshot));
    } else if (thread.contextRevision != ctx.fingerprint) {
      final update = SlidesContextBuilder.update(
        previous: thread.contextMarkdown,
        now: ctx,
      );
      if (update != null) blocks.add(TextPart(update));
    }
    blocks.add(
      TextPart(
        '$message\n\n${volatile(m, hints: hints, applyMode: applyMode)}',
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

  /// The volatile context of a turn: mode, role, the current slide (all
  /// its elements), the selection and the local time.
  String volatile(
    DeckModel m, {
    required AssistantContextHints hints,
    required AiApplyMode applyMode,
  }) {
    final b = StringBuffer('<context>\n');
    b.writeln(
      'Apply mode: ${role < Role.editor
          ? 'read-only (the user cannot edit this presentation)'
          : applyMode == AiApplyMode.suggest
          ? 'suggest (changes are recorded for review, not applied)'
          : 'edit (changes apply directly)'}',
    );
    b.writeln('User role: ${role.name}');
    final current = hints.slidesCurrentSlide;
    if (current != null && m.slide(current) != null) {
      final position = m.slides.indexWhere((s) => s.id == current) + 1;
      b.writeln('Current slide: $position ($current)');
      b.writeln(SlidesContextBuilder.currentSlide(m, current));
    }
    final slides = [
      for (final id in hints.slidesSelectedSlides ?? const <String>[])
        if (m.slide(id) != null) id,
    ];
    if (slides.length > 1) {
      b.writeln(
        'Selected slides: ${[for (final id in slides) m.slides.indexWhere((s) => s.id == id) + 1].join(', ')}',
      );
    }
    final elements = [
      for (final id in hints.slidesSelectedElements ?? const <String>[])
        if (m.element(id) != null) id,
    ];
    if (elements.isNotEmpty) {
      b.writeln('Selected elements: ${elements.take(50).join(', ')}');
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
    'slides.get_deck' => 'Looking at the presentation',
    'slides.get_slide' || 'slides.get_element' => 'Reading a slide',
    'slides.list_layouts' => 'Looking at layouts',
    'slides.list_themes' => 'Looking at themes',
    'slides.search' => 'Searching the presentation',
    'slides.add_slides' || 'slides.add_slides_from_markdown' => 'Adding slides',
    'slides.update_slide' => 'Changing a slide',
    'slides.set_speaker_notes' => 'Writing speaker notes',
    'slides.move_slides' => 'Moving slides',
    'slides.duplicate_slides' => 'Duplicating slides',
    'slides.delete_slides' => 'Deleting slides',
    'slides.set_text' => 'Writing text',
    'slides.format_text' => 'Formatting text',
    'slides.replace_text' => 'Replacing text',
    'slides.apply_theme' => 'Applying a theme',
    'slides.set_deck_properties' => 'Changing the presentation',
    'slides.add_code_block' ||
    'slides.set_code_states' ||
    'slides.update_code_block' => 'Building a code block',
    'slides.set_builds' ||
    'slides.update_build' ||
    'slides.delete_builds' => 'Animating',
    'slides.set_transition' => 'Setting a transition',
    'slides.list_sheet_charts' => 'Looking for charts',
    'slides.insert_linked_chart' => 'Inserting a chart',
    _ when tool.contains('group') => 'Organizing slides',
    _ when tool.contains('element') => 'Changing objects',
    _ when tool.startsWith('slides.') => 'Changing the presentation',
    _ => 'Working',
  };

  @override
  String resultText(String tool, ToolResult result) =>
      AssistantTarget.jsonText(result);

  /// Show: [AssistantToolActivity.range] carries the first touched or
  /// created slide id, [AssistantToolActivity.objectId] the first element.
  @override
  void annotate(AssistantToolActivity a, Map<Object?, Object?> r) {
    final s = r['summary'];
    if (s is String && s.isNotEmpty) a.summary = s;
    final change = r['change_id'];
    if (change is String) a.changeId = change;
    String? first(Object? map, String key) {
      if (map is! Map) return null;
      final list = map[key];
      return list is List && list.isNotEmpty ? '${list.first}' : null;
    }

    a.range =
        first(r['created'], 'slide_ids') ??
        first(r['touched'], 'slide_ids') ??
        (r['slide_id'] is String ? r['slide_id'] as String : null);
    a.objectId =
        first(r['created'], 'element_ids') ??
        first(r['touched'], 'element_ids') ??
        (r['element_id'] is String ? r['element_id'] as String : null);
  }

  @override
  Future<void> beginRun(
    Session session,
    Actor actor, {
    required String runId,
    required AiApplyMode applyMode,
  }) async {
    if (applyMode != AiApplyMode.suggest || role < Role.editor) return;
    SlidesShadows.begin(
      runId,
      item,
      await _model(session),
      userId: actor.userId,
    );
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
    final shadow = SlidesShadows.end(runId);
    if (shadow != null) {
      if (shadow.calls.isEmpty) return;
      if (!await SlidesAiPreviewStore.save(session, shadow)) {
        emit(
          AssistantEvent(
            type: AssistantEventType.error,
            threadId: done.threadId,
            runId: runId,
            error: 'The suggested changes are too large to preview.',
            errorCode: 'too_large',
          ),
        );
        return;
      }
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
    // One undo step for the whole run (11 §6.3): the ops of the run's
    // records join one record.
    final composite = await ServerChangeRecords.composite(
      session,
      actor: actor.copyWith(kind: ActorKind.ai),
      fileUuid: item.contentRef!,
      changeIds: changeIds,
      label: 'AI: ${_short(title)}',
    );
    done.changeId = composite?.uuid;
  }

  static String _short(String s) =>
      s.length <= 60 ? s : '${s.substring(0, 57)}…';
}
