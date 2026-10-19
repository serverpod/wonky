import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/ops.dart';

import '../../platform/mcp/tool_support.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_read_handlers.dart';
import 'slides_writes.dart';

/// MCP tools for builds and transitions (Slides 11 §3).
abstract final class SlidesBuildHandlers {
  static SlideBuildKind _kind(String v, String pointer) {
    final k = SlideBuildKind.values.asNameMap()[SlidesInput.camelEnum(v)];
    if (k == null) {
      throw SlidesMcp.invalid('Unknown kind "$v".', pointer: pointer);
    }
    return k;
  }

  static SlideBuildTrigger? _trigger(Object? v) => v is String
      ? SlideBuildTrigger.values.asNameMap()[SlidesInput.camelEnum(v)]
      : null;

  /// The options JSON (`params`, `delivery`, `afterBuild`) of an MCP build.
  static Map<String, Object?> _options(Map<String, Object?> b) {
    final delivery = (b['delivery'] as Map?)?.cast<String, Object?>();
    return {
      if (b['params'] is Map) 'params': b['params'],
      if (delivery != null)
        'delivery': {
          for (final e in SlidesInput.camel(delivery).entries)
            e.key:
                e.value is String && (e.key == 'by' || e.key == 'partTrigger')
                ? SlidesInput.camelEnum(e.value! as String)
                : e.value,
        },
      if (b['after_build'] is Map)
        'afterBuild': SlidesInput.camel(b['after_build']! as Map),
    };
  }

  /// A validated `BuildSpec` for [b] (11 §3.11): unknown effects are
  /// `invalid_args` with the effects allowed for the element.
  static BuildSpec buildSpec(
    DeckModel m,
    Map<String, Object?> b, {
    required String slideId,
    required String pointer,
    required List<SlidesWarning> warnings,
  }) {
    final elementId = SlidesMcp.elementId(
      m,
      b['element'],
      pointer: '$pointer/element',
    );
    final element = m.element(elementId)!;
    if (element.slideId != slideId) {
      throw SlidesMcp.invalid(
        'Element $elementId is not on this slide.',
        pointer: '$pointer/element',
      );
    }
    final kind = _kind('${b['kind']}', '$pointer/kind');
    final effect = '${b['effect']}';
    if (EffectCatalog.byId(kind, effect) == null) {
      final allowed = [
        for (final e in EffectCatalog.forElement(kind, element.kind)) e.id,
      ];
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Unknown ${b['kind']} effect "$effect" for a ${element.kind.name}. '
        'Allowed: ${allowed.join(', ')}.',
        details: [
          {'pointer': '$pointer/effect', 'message': 'unknown effect'},
          {'allowed': allowed},
        ],
      );
    }
    final v = BuildOptions.fromJson(_options(b), kind: kind, effect: effect);
    if (v.errors.isNotEmpty) {
      throw SlidesMcp.invalid(
        'Invalid build options: ${v.errors.first}',
        pointer: pointer,
      );
    }
    for (final w in v.warnings) {
      warnings.add(
        SlidesWarning('clamped', '$w', elementId: elementId, pointer: pointer),
      );
    }
    final spec = EffectCatalog.byId(kind, effect)!;
    return BuildSpec(
      elementId: elementId,
      kind: kind,
      effect: effect,
      trigger: _trigger(b['trigger']) ?? SlideBuildTrigger.onClick,
      delayMs: (b['delay_ms'] as num?)?.toInt() ?? 0,
      durationMs: (b['duration_ms'] as num?)?.toInt() ?? spec.defaultDurationMs,
      easing: b['easing'] as String? ?? spec.defaultEasing,
      optionsJson: v.value.encode(),
    );
  }

  static Future<ToolResult> setBuilds(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final list = a.list('builds')!;
    final warnings = <SlidesWarning>[];
    late String slideId;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_builds',
      label: 'set_builds (${list.length})',
      warnings: warnings,
      build: (s) {
        final m = s.model;
        slideId = SlidesMcp.slideId(m, a.values['slide']);
        final specs = [
          for (final (i, raw) in list.indexed)
            buildSpec(
              m,
              (raw! as Map).cast<String, Object?>(),
              slideId: slideId,
              pointer: '/builds/$i',
              warnings: warnings,
            ),
        ];
        if ((a.string('mode') ?? 'replace') == 'replace') {
          final old = [for (final b in m.buildsOf(slideId)) b.id];
          if (old.isNotEmpty) s.run(DeleteBuilds(old));
        }
        if (specs.isNotEmpty) s.run(AddBuilds(slideId, specs));
      },
    );
    final timeline = SlidesReadHandlers.timelineJson(t.model, slideId);
    return SlidesWrites.result(
      o,
      'Set ${list.length} build${list.length == 1 ? '' : 's'}: '
      '${timeline['steps']} clicks',
      {'timeline': timeline},
    );
  }

  static Future<ToolResult> updateBuild(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final patch = a.object('patch')!;
    final warnings = <SlidesWarning>[];
    String? slideId;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.update_build',
      warnings: warnings,
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.canonicalId(a.requireString('build_id'));
        final b = id == null ? null : m.build(id);
        if (b == null) {
          throw McpToolException(
            McpErrorCode.notFound,
            'Build ${a.string('build_id')} not found (slides.get_slide with '
            'include builds).',
          );
        }
        slideId = b.slideId;
        final kind = patch['kind'] is String
            ? _kind(patch['kind']! as String, '/patch/kind')
            : null;
        final effect = patch['effect'] as String?;
        if (effect != null &&
            EffectCatalog.byId(kind ?? b.kind, effect) == null) {
          throw SlidesMcp.invalid(
            'Unknown effect "$effect".',
            pointer: '/patch/effect',
          );
        }
        final options = _options(patch);
        s.run(
          BuildEdits.update(
            m,
            [b.id],
            kind: kind,
            effect: effect,
            trigger: _trigger(patch['trigger']),
            delayMs: (patch['delay_ms'] as num?)?.toInt(),
            durationMs: (patch['duration_ms'] as num?)?.toInt(),
            easing: patch['easing'] as String?,
            options: options.isEmpty ? null : options,
          ),
        );
      },
    );
    return SlidesWrites.result(o, 'Updated the build', {
      if (slideId != null)
        'timeline': SlidesReadHandlers.timelineJson(t.model, slideId!),
    });
  }

  static Future<ToolResult> deleteBuilds(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    var n = 0;
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.delete_builds',
      build: (s) {
        final m = s.model;
        final ids = <String>[];
        for (final raw in a.list('build_ids') ?? const []) {
          final id = SlidesMcp.canonicalId('$raw');
          if (id == null || m.build(id) == null) {
            throw McpToolException(
              McpErrorCode.notFound,
              'Build $raw not found.',
            );
          }
          ids.add(id);
        }
        if (a.values['slide'] != null) {
          final slide = SlidesMcp.slideId(m, a.values['slide']);
          ids.addAll([for (final b in m.buildsOf(slide)) b.id]);
        }
        if (ids.isEmpty &&
            a.list('build_ids') == null &&
            a.values['slide'] == null) {
          throw SlidesMcp.invalid('Give build_ids or slide.');
        }
        n = ids.toSet().length;
        if (n > 0) s.run(DeleteBuilds(ids.toSet().toList()));
      },
    );
    return SlidesWrites.result(o, 'Deleted $n build${n == 1 ? '' : 's'}');
  }

  static Future<ToolResult> setTransition(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final slides = a.values['slides'];
    final tr = a.object('transition');
    var summary = '';
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_transition',
      build: (s) {
        final m = s.model;
        TransitionSpec? spec;
        if (tr != null) {
          final v = TransitionSpec.decode(SlidesInput.transitionJson(tr));
          if (!v.isValid) {
            throw SlidesMcp.invalid(
              'Invalid transition: ${v.errors.first}',
              pointer: '/transition',
            );
          }
          spec = v.value;
        }
        if (slides == 'all') {
          s.run(
            BuildEdits.applyTransitionToAll(
              m,
              transition: spec ?? TransitionSpec.none,
            ),
          );
          summary = 'Set the transition of every slide';
          return;
        }
        final ids = SlidesMcp.slideIds(m, (slides as List?)?.cast<Object?>());
        s.run(
          SetSlideProps(
            ids,
            transitionJson: Patch(spec?.encode()),
          ),
        );
        summary =
            'Set the transition of ${ids.length} slide${ids.length == 1 ? '' : 's'}';
      },
    );
    return SlidesWrites.result(o, summary);
  }
}
