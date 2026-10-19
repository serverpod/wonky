import 'dart:async';
import 'dart:convert';

import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_revlog/rows.dart';

import 'package:serverpod/serverpod.dart' show LogLevel;

import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/presence/presence_service.dart';
import '../../platform/users/user_service.dart';
import '../ai/slides_ai_guard.dart';
import '../headless/headless_deck.dart';
import 'slides_mcp_support.dart';

/// A warning of a tool result (11 §2.2).
class SlidesWarning {
  const SlidesWarning(this.code, this.message, {this.elementId, this.pointer});

  final String code;
  final String message;
  final String? elementId;
  final String? pointer;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    'element_id': ?elementId,
    'pointer': ?pointer,
  };
}

/// The outcome of a mutating `slides.*` call.
class SlidesWriteOutcome {
  SlidesWriteOutcome(this.write, this.warnings);

  final HeadlessDeckWrite write;
  final List<SlidesWarning> warnings;

  SlidesPlan get plan => write.plan;

  /// Ids of the rows the call inserted, by kind (11 §2.2 `created`).
  Map<String, List<String>> get created {
    List<String> of(String table) => [
      for (final c in plan.changes)
        if (c.table == table && c.op == RowOp.insert) c.rowId,
    ];
    return {
      'slide_ids': of(SlidesTables.slide),
      'element_ids': of(SlidesTables.slideElement),
      'group_ids': of(SlidesTables.slideGroup),
      'build_ids': of(SlidesTables.slideBuild),
    };
  }

  /// The common result fields of mutating tools (11 §2.2).
  Map<String, Object?> toJson(String summary) => {
    'change_id': write.changeId?.uuid,
    'sync_version': write.syncVersion,
    'summary': summary,
    'created': created,
    'warnings': [for (final w in warnings) w.toJson()],
    // The slides and elements the call changed (the assistant's Show,
    // SL-43); not listed for deletions.
    if (_touched case final Map<String, Object?> t) 'touched': t,
  };

  Map<String, Object?>? get _touched {
    final s = plan.summary;
    final slides = [
      for (final id in s.slides)
        if (!s.deleted['slides']!.contains(id)) id,
    ];
    final elements = [
      for (final id in s.elements)
        if (!s.deleted['elements']!.contains(id)) id,
    ];
    if (slides.isEmpty && elements.isEmpty) return null;
    return {
      'slide_ids': slides.take(50).toList(),
      'element_ids': elements.take(50).toList(),
    };
  }
}

/// The write pipeline of the `slides.*` tools (Slides 11 §2.1): every call
/// plans its operations with the shared planner against the headless deck
/// ([ServerHeadlessDeck.writeSteps]: serialized per deck, maintenance
/// first, soft locks, one RevLog change + `ServerChangeRecord` per call
/// labeled "MCP: tool"), maps planner refusals to tool errors and shows
/// the agent to collaborators on the touched slide.
abstract final class SlidesWrites {
  /// Plans [build]'s operations and commits them as one change.
  /// [confirmIf] names why an assistant run must confirm the call first
  /// (null = no; the central rules are `SlidesAiGuard.reason`).
  static Future<SlidesWriteOutcome> run(
    ToolContext ctx,
    SlidesTarget t, {
    required String tool,
    required FutureOr<void> Function(DeckSteps steps) build,
    String? label,
    bool force = false,
    List<SlidesWarning> warnings = const [],
    String? Function()? confirmIf,
  }) async {
    final prefix = ctx.actor.kind == ActorKind.ai ? 'AI' : 'MCP';
    // Assistant runs: risky writes wait for the user (11 §8.1). Checked
    // after planning, before anything is written; Suggest-mode shadows
    // write nothing and are reviewed anyway.
    Future<void> guarded(DeckSteps s) async {
      await build(s);
      if (!ctx.guardDestructive || t.deck.overlay != null) return;
      final reason =
          confirmIf?.call() ??
          SlidesAiGuard.reason(
            tool,
            s.plan(),
            before: t.model,
            warnings: [for (final w in warnings) w.code],
          );
      if (reason != null) throw SlidesAiGuard.needsConfirmation(reason);
    }

    final HeadlessDeckWrite w;
    try {
      w = await t.deck.writeSteps(
        guarded,
        force: force,
        label: '$prefix: ${label ?? tool.substring(tool.indexOf('.') + 1)}',
        actorKind: ctx.actor.kind.name,
      );
    } on PlanException catch (e) {
      throw SlidesMcp.fromPlan(e);
    } on FormatException catch (e) {
      throw SlidesMcp.invalid(e.message);
    } on WonkyException catch (e) {
      throw SlidesMcp.beingEdited(e) ?? McpToolException.fromWonky(e);
    }
    final all = [
      ...warnings,
      for (final code in w.plan.warnings)
        SlidesWarning(code, _warningText(code)),
    ];
    if (w.changeId != null) {
      try {
        await DeckAgentPresence.show(ctx, t, w.plan);
      } on Object catch (e) {
        ctx.session.log('Agent presence failed: $e', level: LogLevel.warning);
      }
    }
    return SlidesWriteOutcome(w, all);
  }

  static String _warningText(String code) => switch (code) {
    'clamped' => 'Some values were clamped to their limits.',
    _ => code,
  };

  /// A change result for [o] with [summary] plus [extra] fields.
  static ToolResult result(
    SlidesWriteOutcome o,
    String summary, [
    Map<String, Object?> extra = const {},
  ]) => ToolResult({...o.toJson(summary), ...extra}, text: summary);
}

/// Shows an MCP/AI agent writing without a window as a participant of the
/// deck for a few seconds after each write (Slides 11 §1.3, 09 §1.1): its
/// Slides presence cursor names the touched slide and elements, so open
/// editors show the agent's selection there. One participant per deck,
/// user and agent; later writes move it.
abstract final class DeckAgentPresence {
  static const ttl = Duration(seconds: 5);

  static final Map<String, ({String sessionId, Timer bye})> _live = {};

  /// Whether an agent of [actor] is shown on [item] (tests).
  static bool isShown(DriveItem item, Actor actor) =>
      _live.containsKey(_key(item, actor));

  static String _key(DriveItem item, Actor actor) =>
      '${item.uuid.uuid}|${actor.userId}|${actor.kind.name}';

  /// Shows (or moves) the agent after its write [plan].
  static Future<void> show(
    ToolContext ctx,
    SlidesTarget t,
    SlidesPlan plan,
  ) async {
    final actor = ctx.actor;
    if (actor.kind != ActorKind.mcp && actor.kind != ActorKind.ai) return;
    final slides = plan.summary.slides;
    final slideId = slides.isEmpty ? null : slides.first;
    final model = t.model;
    final selection = [
      for (final id in plan.summary.elements)
        if (slideId != null && model.element(id)?.slideId == slideId) id,
    ].take(50).toList();
    final cursor = jsonEncode({
      'app': 'slides',
      'route': 'editor',
      'viewMode': 'normal',
      'slideId': slideId,
      'selection': selection,
      'navSelection': {
        'slides': [?slideId],
        'groups': <String>[],
      },
      'editing': null,
      'pointer': null,
    });
    final key = _key(t.item, actor);
    final existing = _live.remove(key);
    existing?.bye.cancel();
    String name;
    try {
      final summary = await UserService.summary(ctx.session, actor.userId);
      name = '${summary?.displayName ?? 'User'} · ${ctx.agentLabel}';
    } on Exception {
      name = ctx.agentLabel;
    }
    final id = await PresenceService.injectAgent(
      ctx.session,
      t.item.uuid,
      actor: actor,
      displayName: name,
      ttl: null,
      sessionId: existing?.sessionId,
      cursorJson: cursor,
    );
    final pod = ctx.session.serverpod;
    final itemUuid = t.item.uuid;
    _live[key] = (
      sessionId: id,
      bye: Timer(ttl, () {
        _live.remove(key);
        PresenceService.removeAgent(pod, itemUuid, id);
      }),
    );
  }

  /// Forgets every shown agent (tests).
  static void clear() {
    for (final e in _live.values) {
      e.bye.cancel();
    }
    _live.clear();
  }
}
