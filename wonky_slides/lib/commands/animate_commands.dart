import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;

import '../features/builds/animate_canvas_layer.dart';
import '../features/canvas/canvas_interactions.dart';
import '../features/builds/animate_view.dart';
import '../features/builds/build_labels.dart';
import '../features/builds/build_recipes.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/settings/slides_user_defaults.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart';

/// The key scope of the Animate tab's Order list (06 §5.4, §15):
/// `Mod+Alt+↑/↓` reorders, Delete removes (on the canvas these chords
/// align objects).
const animatePaneScope = KeyScope('slidesAnimatePane');

/// The key scope of a running canvas preview (Esc stops it, 06 §5.5).
const animatePreviewScope = KeyScope('slidesAnimatePreview');

/// The Animate commands of SL-30 (Slides 06 §5, §8, §15): builds (add,
/// edit, remove, reorder, triggers, the animation painter, motion paths
/// and transform targets, *Build all steps*), transitions (set, remove,
/// apply to all, advance), Magic Move (*Magic Move slide*, Magic Move ID,
/// matches), previews and the canvas overlays. Every mutating command is
/// one `slides.rows` undo step through SL-24's `BuildEdits`; field edits
/// with the same `coalesceKey` within the undo window are one step (slider
/// drags, 06 §15).
List<Command<CommandArgs>> animateCommands(ShellServices s) {
  CanvasInteractions.register(AnimateCanvasLayer.new);
  return [
    // ---------------------------------------------------------- builds
    SlidesCommand(
      'slides.animate.addBuild',
      label: (l) => l.cmdAnimateAddBuild,
      icon: LucideIcons.sparkles,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: JsonSchema.object(
        properties: {
          'elementIds': const JsonSchema.array(JsonSchema.string()),
          'kind': const JsonSchema.string(
            enumValues: [
              'buildIn',
              'buildOut',
              'emphasis',
              'motion',
              'in',
              'action',
              'out',
            ],
            description:
                'Build kind (in/action/out are the context menu aliases).',
          ),
          'effect': JsonSchema.string(
            description:
                'Effect id of the catalog (06 §3): '
                '${{for (final e in EffectCatalog.all)
                  if (e.available) e.id}.join(', ')}. '
                'Omitted = the default effect of the kind.',
          ),
          'params': const JsonSchema.object(additionalProperties: true),
          'delivery': const JsonSchema.object(
            additionalProperties: true,
            description: 'optionsJson.delivery (06 §2.2).',
          ),
          'afterBuild': const JsonSchema.object(additionalProperties: true),
          'trigger': _triggerSchema,
          'delayMs': const JsonSchema.integer(minimum: 0, maximum: 60000),
          'durationMs': const JsonSchema.integer(minimum: 0, maximum: 20000),
          'easing': const JsonSchema.string(),
          'at': const JsonSchema.object(
            properties: {
              'afterBuildId': JsonSchema.string(),
              'beforeBuildId': JsonSchema.string(),
              'index': JsonSchema.integer(minimum: 0),
            },
          ),
          'alt': const JsonSchema.boolean(
            description: 'Inverts the default triggers (Alt-click).',
          ),
        },
      ),
      enabled: (ed, a) => _elements(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectObject,
      run: (ctx, ed, a) {
        final slideId = _slide(ed)!;
        final els = _elements(ed, a);
        final view = AnimateView.of(ed);
        final tab = BuildKindTab.fromName(a.string('kind')) ?? view.kindTab;
        var effect = a.string('effect');
        final quick = effect == null;
        effect ??= _defaultEffect(ed, tab, els);
        final kind = _kindOf(tab, effect);
        final spec = EffectCatalog.byId(kind, effect);
        if (spec == null || !spec.available) {
          return CommandResult.failed('Unknown ${kind.name} effect "$effect"');
        }
        final l = slidesL10nOf(ed.services);
        for (final id in els) {
          final k = ed.model.element(id)!.kind;
          if (!spec.target.accepts(k)) {
            return CommandResult.failed(BuildLabels.targetReason(l, spec));
          }
        }
        final at = a.values['at'];
        String? after, before;
        int? index;
        if (at is Map) {
          after = at['afterBuildId'] as String?;
          before = at['beforeBuildId'] as String?;
          index = (at['index'] as num?)?.toInt();
        }
        final builds = ed.model.buildsOf(slideId);
        if (index != null) {
          if (index <= 0) {
            before = builds.isEmpty ? null : builds.first.id;
          } else {
            after = builds[(index - 1).clamp(0, builds.length - 1)].id;
          }
        }
        final op = BuildEdits.add(
          ed.model,
          slideId,
          els,
          kind: kind,
          effect: effect,
          params: _map(a.values['params']),
          delivery: _delivery(a.values['delivery']),
          afterBuild: _afterBuild(a.values['afterBuild']),
          trigger: SlideBuildTrigger.fromName(a.string('trigger')),
          alt: a.boolean('alt') ?? false,
          delayMs: a.integer('delayMs') ?? 0,
          durationMs: a.integer('durationMs'),
          easing: a.string('easing'),
          afterBuildId: before == null ? after : null,
        );
        final plan = ed.apply(ctx, op);
        final ids = (plan.result['buildIds'] as List?)?.cast<String>() ?? [];
        if (before != null && ids.isNotEmpty) {
          ed.apply(ctx, MoveBuilds(ids, beforeId: before));
        }
        view.selectBuilds(ids, selectElements: false);
        if (!ctx.source.isAgent) {
          if (quick) {
            ed.openInspector(InspectorTab.animate, animateTab: 'build');
          }
          _autoPreview(view, slideId, ids);
        }
        return ok({'buildIds': ids});
      },
    ),
    SlidesCommand(
      'slides.animate.updateBuild',
      label: (l) => l.cmdAnimateUpdateBuild,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'buildIds': JsonSchema.array(JsonSchema.string()),
          'patch': JsonSchema.object(
            properties: {
              'kind': JsonSchema.string(
                enumValues: ['buildIn', 'buildOut', 'emphasis', 'motion'],
              ),
              'effect': JsonSchema.string(),
              'trigger': _triggerSchema,
              'delayMs': JsonSchema.integer(minimum: 0, maximum: 60000),
              'durationMs': JsonSchema.integer(minimum: 0, maximum: 20000),
              'easing': JsonSchema.string(),
              'options': JsonSchema.object(
                additionalProperties: true,
                description: 'JSON merge patch over optionsJson (06 §2.2).',
              ),
            },
          ),
          'coalesceKey': JsonSchema.string(
            description: 'Edits with the same key within 1 s are one step.',
          ),
        },
        required: ['patch'],
      ),
      enabled: (ed, a) => _builds(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectBuild,
      run: (ctx, ed, a) {
        final ids = _builds(ed, a);
        final patch = _map(a.values['patch']) ?? const {};
        final kind = SlideBuildKind.fromName(patch['kind']);
        final effect = patch['effect'] as String?;
        if (effect != null) {
          final l = slidesL10nOf(ed.services);
          for (final id in ids) {
            final b = ed.model.build(id)!;
            final spec = EffectCatalog.byId(kind ?? b.kind, effect);
            if (spec == null || !spec.available) {
              return CommandResult.failed('Unknown effect "$effect"');
            }
            final el = ed.model.element(b.elementId ?? '');
            if (el != null && !spec.target.accepts(el.kind)) {
              return CommandResult.failed(BuildLabels.targetReason(l, spec));
            }
          }
        }
        final op = BuildEdits.update(
          ed.model,
          ids,
          kind: kind,
          effect: effect,
          trigger: SlideBuildTrigger.fromName(patch['trigger']),
          delayMs: (patch['delayMs'] as num?)?.toInt(),
          durationMs: (patch['durationMs'] as num?)?.toInt(),
          easing: patch['easing'] as String?,
          options: _map(patch['options']),
        );
        if (op.updates.isEmpty) return ok({'buildIds': ids});
        final key = a.string('coalesceKey');
        if (key == null) {
          ed.apply(ctx, op);
        } else {
          _applyCoalesced(ctx, ed, op, 'slides.animate:$key');
        }
        final view = AnimateView.of(ed);
        if (!ctx.source.isAgent && effect != null) {
          _autoPreview(view, _slideOfBuild(ed, ids.first), ids);
        }
        return ok({'buildIds': ids});
      },
    ),
    SlidesCommand(
      'slides.animate.deleteBuilds',
      label: (l) => l.cmdAnimateDeleteBuilds,
      icon: LucideIcons.trash2,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argBindings: const [
        ArgsKeyBinding(KeyBinding('Delete'), {}, scope: animatePaneScope),
        ArgsKeyBinding(KeyBinding('Backspace'), {}, scope: animatePaneScope),
      ],
      argsSchema: const JsonSchema.object(
        properties: {'buildIds': JsonSchema.array(JsonSchema.string())},
      ),
      undoLabelOf: (l, a) => l.undoRemoveAnimation,
      enabled: (ed, a) => _buildsOrOfElements(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectBuild,
      run: (ctx, ed, a) {
        final ids = _buildsOrOfElements(ed, a);
        ed.apply(ctx, DeleteBuilds(ids));
        return ok({'buildIds': ids});
      },
    ),
    SlidesCommand(
      'slides.animate.removeAll',
      label: (l) => l.cmdAnimateRemoveAll,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'slideIds': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) =>
          _slidesOf(ed, a).any((id) => ed.model.buildsOf(id).isNotEmpty),
      reason: (l, ed) => l.reasonNoBuilds,
      run: (ctx, ed, a) {
        final op = BuildEdits.removeAll(ed.model, _slidesOf(ed, a));
        ed.apply(ctx, op);
        return ok({'buildIds': op.buildIds});
      },
    ),
    SlidesCommand(
      'slides.animate.moveBuilds',
      label: (l) => l.cmdAnimateMoveBuilds,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argBindings: const [
        ArgsKeyBinding(KeyBinding('ArrowUp', mod: true, alt: true), {
          'by': -1,
        }, scope: animatePaneScope),
        ArgsKeyBinding(KeyBinding('ArrowDown', mod: true, alt: true), {
          'by': 1,
        }, scope: animatePaneScope),
      ],
      argsSchema: const JsonSchema.object(
        properties: {
          'buildIds': JsonSchema.array(JsonSchema.string()),
          'to': JsonSchema.object(
            properties: {
              'index': JsonSchema.integer(minimum: 0),
              'beforeBuildId': JsonSchema.string(),
              'afterBuildId': JsonSchema.string(),
            },
          ),
          'by': JsonSchema.integer(
            minimum: -1,
            maximum: 1,
            description: 'Moves one place up (−1) or down (1).',
          ),
          'trigger': _triggerSchema,
        },
      ),
      enabled: (ed, a) => _builds(ed, a).isNotEmpty && _moveOf(ed, a) != null,
      reason: (l, ed) => AnimateView.of(ed).selectedBuildIds.isEmpty
          ? l.reasonSelectBuild
          : l.reasonCantMoveFurther,
      run: (ctx, ed, a) {
        final op = _moveOf(ed, a)!;
        ed.apply(ctx, op);
        return ok({'buildIds': op.buildIds});
      },
    ),
    SlidesCommand(
      'slides.animate.setTrigger',
      label: (l) => l.cmdAnimateSetTrigger,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'buildIds': JsonSchema.array(JsonSchema.string()),
          'trigger': _triggerSchema,
        },
        required: ['trigger'],
      ),
      checked: (ed, a) {
        final t = a.string('trigger');
        final ids = _builds(ed, a);
        if (t == null || ids.isEmpty) return null;
        return ids.every((id) => ed.model.build(id)?.trigger.name == t);
      },
      enabled: (ed, a) => _builds(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectBuild,
      run: (ctx, ed, a) {
        final t = SlideBuildTrigger.fromName(a.string('trigger'));
        if (t == null || t == SlideBuildTrigger.onElementClick) {
          return const CommandResult.failed('Unsupported trigger');
        }
        final ids = _builds(ed, a);
        ed.apply(ctx, BuildEdits.update(ed.model, ids, trigger: t));
        return ok({'buildIds': ids});
      },
    ),
    SlidesCommand(
      'slides.animate.copyBuilds',
      label: (l) => l.cmdAnimateCopyBuilds,
      icon: LucideIcons.paintbrush,
      categoryOf: SlidesCategory.animations,
      argsSchema: const JsonSchema.object(
        properties: {'elementId': JsonSchema.string()},
      ),
      enabled: (ed, a) {
        final id = _copySource(ed, a);
        return id != null && !BuildEdits.copy(ed.model, id).isEmpty;
      },
      reason: (l, ed) => l.reasonObjectNoBuilds,
      run: (ctx, ed, a) {
        final copied = BuildEdits.copy(ed.model, _copySource(ed, a)!);
        AnimateView.of(ed).copied = copied;
        return ok({'count': copied.builds.length});
      },
    ),
    SlidesCommand(
      'slides.animate.pasteBuilds',
      label: (l) => l.cmdAnimatePasteBuilds,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'elementIds': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) =>
          AnimateView.of(ed).copied != null && _elements(ed, a).isNotEmpty,
      reason: (l, ed) => AnimateView.of(ed).copied == null
          ? l.reasonNoBuildsCopied
          : l.reasonSelectObject,
      undoLabelOf: (l, a) => l.cmdAnimatePasteBuilds,
      run: (ctx, ed, a) {
        final op = BuildEdits.paste(
          ed.model,
          AnimateView.of(ed).copied!,
          _elements(ed, a),
        );
        if (op == null) {
          return CommandResult.failed(
            slidesL10nOf(ed.services).errorNothingToPaste,
          );
        }
        final plan = ed.apply(ctx, op);
        final ids = (plan.result['buildIds'] as List?)?.cast<String>() ?? [];
        AnimateView.of(ed).selectBuilds(ids, selectElements: false);
        return ok({'buildIds': ids});
      },
    ),
    SlidesCommand(
      'slides.animate.setMotionPath',
      label: (l) => l.cmdAnimateSetMotionPath,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'buildId': JsonSchema.string(),
          'path': JsonSchema.string(
            description:
                'SVG path data in su relative to the element center at the '
                'start of the build.',
          ),
          'preset': JsonSchema.string(
            enumValues: ['line', 'arc', 'curve', 'circle', 'zigzag', 'custom'],
          ),
          'orientToPath': JsonSchema.boolean(),
        },
      ),
      enabled: (ed, a) => _effectBuild(ed, a, 'path') != null,
      reason: (l, ed) => l.reasonSelectBuild,
      run: (ctx, ed, a) {
        final b = _effectBuild(ed, a, 'path')!;
        final preset = a.string('preset');
        var path = a.string('path');
        if (path == null && preset != null) {
          path = MotionPaths.preset(preset, ed.model.element(b.elementId!));
        }
        final params = <String, Object?>{
          'path': ?path,
          'preset': ?(preset ?? (path == null ? null : 'custom')),
          'orientToPath': ?a.boolean('orientToPath'),
        };
        if (params.isEmpty) {
          return const CommandResult.failed('path or preset is required');
        }
        ed.apply(
          ctx,
          BuildEdits.update(ed.model, [b.id], options: {'params': params}),
        );
        return ok({'buildId': b.id});
      },
    ),
    SlidesCommand(
      'slides.animate.setTransformTarget',
      label: (l) => l.cmdAnimateSetTransformTarget,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'buildId': JsonSchema.string(),
          'to': JsonSchema.object(
            properties: {
              'x': JsonSchema.number(),
              'y': JsonSchema.number(),
              'w': JsonSchema.number(),
              'h': JsonSchema.number(),
              'rotation': JsonSchema.number(),
              'opacity': JsonSchema.number(minimum: 0, maximum: 1),
            },
          ),
        },
        required: ['to'],
      ),
      enabled: (ed, a) => _effectBuild(ed, a, 'moveTo') != null,
      reason: (l, ed) => l.reasonSelectBuild,
      run: (ctx, ed, a) {
        final b = _effectBuild(ed, a, 'moveTo')!;
        final to = _map(a.values['to']) ?? const {};
        ed.apply(
          ctx,
          BuildEdits.update(
            ed.model,
            [b.id],
            options: {
              'params': {'to': to},
            },
          ),
        );
        return ok({'buildId': b.id});
      },
    ),
    SlidesCommand(
      'slides.animate.buildAllSteps',
      label: (l) => l.cmdAnimateBuildAllSteps,
      icon: LucideIcons.listOrdered,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'elementId': JsonSchema.string()},
      ),
      enabled: (ed, a) {
        final id = _single(ed, a);
        return id != null && BuildRecipes.allSteps(ed.model, id) != null;
      },
      reason: (l, ed) => l.reasonSelectCodeOrChart,
      run: (ctx, ed, a) {
        final id = _single(ed, a)!;
        final specs = BuildRecipes.allSteps(ed.model, id)!;
        final plan = ed.apply(
          ctx,
          AddBuilds(ed.model.element(id)!.slideId!, specs),
        );
        final ids = (plan.result['buildIds'] as List?)?.cast<String>() ?? [];
        AnimateView.of(ed).selectBuilds(ids, selectElements: false);
        return ok({'buildIds': ids});
      },
    ),
    SlidesCommand(
      'slides.animate.selectBuilds',
      label: (l) => l.cmdAnimateSelectBuilds,
      categoryOf: SlidesCategory.animations,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'buildIds': JsonSchema.array(JsonSchema.string()),
          'selectElements': JsonSchema.boolean(),
        },
        required: ['buildIds'],
      ),
      run: (ctx, ed, a) {
        final ids = a.strings('buildIds');
        if (ids.any((id) => ed.model.build(id) == null)) {
          return const CommandResult.failed('Unknown build');
        }
        AnimateView.of(ed).selectBuilds(
          ids,
          selectElements: a.boolean('selectElements') ?? true,
        );
        return ok();
      },
    ),

    // --------------------------------------------------------- previews
    SlidesCommand(
      'slides.animate.preview',
      label: (l) => l.cmdAnimatePreview,
      icon: LucideIcons.play,
      categoryOf: SlidesCategory.animations,
      defaultBindings: const [
        KeyBinding('P', mod: true, alt: true, shift: true),
      ],
      argsSchema: const JsonSchema.object(
        properties: {
          'slideId': JsonSchema.string(),
          'fromBuildId': JsonSchema.string(
            description: 'Plays from the start of this build\'s step.',
          ),
          'buildIds': JsonSchema.array(
            JsonSchema.string(),
            description: 'Plays only these builds.',
          ),
          'includeTransition': JsonSchema.boolean(),
        },
      ),
      enabled: (ed, a) => _previewSlide(ed, a) != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final view = AnimateView.of(ed);
        final slideId = _previewSlide(ed, a)!;
        if (slideId != ed.currentSlideId) ed.setCurrentSlide(slideId);
        final only = a.strings('buildIds');
        final from = a.string('fromBuildId');
        if (only.isNotEmpty) {
          view.preview.playBuilds(slideId, only);
        } else if (from != null) {
          final steps = view.timelineOf(slideId).stepsOfBuild(from);
          final row = view.orderOf(slideId).rowOf(from);
          view.preview.playSlide(
            slideId,
            fromStep: steps.isEmpty ? (row?.step ?? 0) : steps.first,
          );
        } else {
          view.preview.playSlide(
            slideId,
            includeTransition:
                a.boolean('includeTransition') ??
                view.option(AnimateView.optionIncludeTransition),
          );
        }
        return ok({
          'slideId': slideId,
          'steps': view.preview.timeline?.stepCount,
        });
      },
    ),
    SlidesCommand(
      'slides.animate.stopPreview',
      label: (l) => l.cmdAnimateStopPreview,
      icon: LucideIcons.square,
      categoryOf: SlidesCategory.animations,
      argBindings: const [
        ArgsKeyBinding(KeyBinding('Escape'), {}, scope: animatePreviewScope),
      ],
      enabled: (ed, a) => AnimateView.maybeOf(ed)?.preview.active ?? false,
      reason: (l, ed) => l.reasonNotPreviewing,
      run: (ctx, ed, a) {
        AnimateView.of(ed).preview.stop();
        return ok();
      },
    ),
    SlidesCommand(
      'slides.animate.toggleOrderOverlay',
      label: (l) => l.cmdAnimateToggleOrderOverlay,
      icon: LucideIcons.listOrdered,
      categoryOf: SlidesCategory.animations,
      checked: (ed, a) => AnimateView.maybeOf(ed)?.orderOverlay ?? false,
      run: (ctx, ed, a) {
        AnimateView.of(ed).toggleOrderOverlay();
        return ok();
      },
    ),
    SlidesCommand(
      'slides.animate.togglePreviewOption',
      label: (l) => l.cmdAnimateTogglePreviewOption,
      categoryOf: SlidesCategory.animations,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'option': JsonSchema.string(
            enumValues: [
              AnimateView.optionAutoPreview,
              AnimateView.optionIncludeTransition,
              AnimateView.optionFullMotion,
            ],
          ),
        },
        required: ['option'],
      ),
      checked: (ed, a) {
        final o = a.string('option');
        return o == null ? null : AnimateView.of(ed).option(o);
      },
      run: (ctx, ed, a) {
        final ok_ = AnimateView.of(ed).toggleOption(a.requireString('option'));
        return ok_ ? ok() : const CommandResult.failed('Unknown option');
      },
    ),

    // ------------------------------------------------------ transitions
    SlidesCommand(
      'slides.transition.set',
      label: (l) => l.cmdTransitionSet,
      icon: LucideIcons.squareStack,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: JsonSchema.object(
        properties: {
          'slideIds': const JsonSchema.array(JsonSchema.string()),
          'transition': JsonSchema.object(
            additionalProperties: true,
            description:
                'JSON merge patch over the current transition (06 §7.1); '
                'type: ${[for (final t in TransitionInfo.all) t.id].join(', ')}.',
          ),
        },
      ),
      enabled: (ed, a) => _transitionSlides(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final patch = _map(a.values['transition']);
        if (patch == null) {
          if (ctx.source.isAgent) {
            return const CommandResult.failed('transition is required');
          }
          ed.openInspector(InspectorTab.animate, animateTab: 'transition');
          return ok();
        }
        final type = patch['type'];
        if (type is String && TransitionInfo.of(type) == null) {
          return CommandResult.failed('Unknown transition "$type"');
        }
        final ids = _transitionSlides(ed, a);
        try {
          ed.apply(ctx, BuildEdits.setTransition(ed.model, ids, patch));
        } on FormatException catch (e) {
          return CommandResult.failed(e.message);
        }
        final view = AnimateView.of(ed);
        if (!ctx.source.isAgent &&
            type is String &&
            view.option(AnimateView.optionAutoPreview) &&
            ids.contains(ed.currentSlideId)) {
          view.preview.playTransition(ed.currentSlideId!);
        }
        return ok({'slideIds': ids});
      },
    ),
    SlidesCommand(
      'slides.transition.remove',
      label: (l) => l.cmdTransitionRemove,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'slideIds': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) => _transitionSlides(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonNoSlides,
      undoLabelOf: (l, a) => l.cmdTransitionSet,
      run: (ctx, ed, a) {
        final ids = _transitionSlides(ed, a);
        ed.apply(ctx, BuildEdits.removeTransition(ids));
        return ok({'slideIds': ids});
      },
    ),
    SlidesCommand(
      'slides.transition.applyToAll',
      label: (l) => l.cmdTransitionApplyToAll,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'transition': JsonSchema.object(
            additionalProperties: true,
            description: 'Default: the current slide\'s transition.',
          ),
        },
      ),
      enabled: (ed, a) => _slide(ed) != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        TransitionSpec? spec;
        final raw = _map(a.values['transition']);
        if (raw != null) {
          final current = TransitionSpec.effective(
            ed.model.slide(_slide(ed)!)?.transitionJson,
            ed.model.deck?.defaultsJson,
          );
          final v = TransitionSpec.patch(current, raw);
          if (!v.isValid) return CommandResult.failed('${v.errors.first}');
          spec = v.value;
        }
        ed.apply(
          ctx,
          BuildEdits.applyTransitionToAll(
            ed.model,
            transition: spec,
            fromSlideId: _slide(ed),
          ),
        );
        return ok();
      },
    ),
    SlidesCommand(
      'slides.transition.setAdvance',
      label: (l) => l.cmdTransitionSetAdvance,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'slideIds': JsonSchema.array(JsonSchema.string()),
          'advance': JsonSchema.object(
            properties: {
              'mode': JsonSchema.string(enumValues: ['onClick', 'auto']),
              'afterMs': JsonSchema.integer(minimum: 0, maximum: 3600000),
              'autoBuilds': JsonSchema.boolean(),
              'buildDelayMs': JsonSchema.integer(minimum: 0, maximum: 60000),
            },
          ),
        },
        required: ['advance'],
      ),
      enabled: (ed, a) => _transitionSlides(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final advance = _map(a.values['advance']) ?? const {};
        final ids = _transitionSlides(ed, a);
        try {
          ed.apply(ctx, BuildEdits.setAdvance(ed.model, ids, advance));
        } on FormatException catch (e) {
          return CommandResult.failed(e.message);
        }
        return ok({'slideIds': ids});
      },
    ),
    SlidesCommand(
      'slides.transition.preview',
      label: (l) => l.cmdTransitionPreview,
      icon: LucideIcons.play,
      categoryOf: SlidesCategory.animations,
      argsSchema: const JsonSchema.object(
        properties: {'slideId': JsonSchema.string()},
      ),
      enabled: (ed, a) => _previewSlide(ed, a) != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final slideId = _previewSlide(ed, a)!;
        if (slideId != ed.currentSlideId) ed.setCurrentSlide(slideId);
        AnimateView.of(ed).preview.playTransition(slideId);
        return ok();
      },
    ),

    // ------------------------------------------------------- Magic Move
    SlidesCommand(
      'slides.slide.duplicateForMagicMove',
      label: (l) => l.cmdSlideDuplicateForMagicMove,
      icon: LucideIcons.wandSparkles,
      categoryOf: SlidesCategory.slides,
      mutates: true,
      defaultBindings: const [
        KeyBinding('D', mod: true, alt: true, shift: true),
      ],
      argsSchema: const JsonSchema.object(
        properties: {'slideId': JsonSchema.string()},
      ),
      undoLabelOf: (l, a) => l.undoAddMagicMoveSlide,
      enabled: (ed, a) => _magicSource(ed, a) != null,
      reason: (l, ed) => l.reasonNoSlides,
      run: (ctx, ed, a) {
        final source = _magicSource(ed, a)!;
        final plan = ed.apply(ctx, DuplicateSlides([source]));
        final ids = (plan.result['slideIds'] as List?)?.cast<String>() ?? [];
        if (ids.isEmpty) return const CommandResult.failed('Not duplicated');
        final current = TransitionSpec.effective(
          ed.model.slide(ids.first)?.transitionJson,
          ed.model.deck?.defaultsJson,
        );
        ed.apply(
          ctx,
          BuildEdits.setTransition(ed.model, ids, {
            ...TransitionSpec.of('magicMove').toJson(),
            if (current.advance.auto) 'advance': current.advance.toJson(),
          }),
        );
        ed.setCurrentSlide(ids.first);
        return ok({'slideId': ids.first});
      },
    ),
    SlidesCommand(
      'slides.element.setMatchKey',
      label: (l) => l.cmdElementSetMatchKey,
      icon: LucideIcons.link,
      categoryOf: SlidesCategory.animations,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'elementId': JsonSchema.string(),
          'matchKey': JsonSchema.string(minLength: 1, maxLength: 64),
        },
      ),
      enabled: (ed, a) => _single(ed, a, anySurface: true) != null,
      reason: (l, ed) => l.reasonSelectOneObject,
      run: (ctx, ed, a) {
        final id = _single(ed, a, anySurface: true)!;
        final key = a.string('matchKey')?.trim();
        if (key == null) {
          if (ctx.source.isAgent) {
            return const CommandResult.failed('matchKey is required');
          }
          ed.openInspector(InspectorTab.format, section: 'arrange');
          return ok();
        }
        ed.apply(ctx, SetElementProps([id], matchKey: key));
        return ok({'elementId': id});
      },
    ),
    SlidesCommand(
      'slides.magicMove.toggleMatches',
      label: (l) => l.cmdMagicMoveToggleMatches,
      icon: LucideIcons.wandSparkles,
      categoryOf: SlidesCategory.animations,
      checked: (ed, a) => AnimateView.maybeOf(ed)?.showMatches ?? false,
      run: (ctx, ed, a) {
        AnimateView.of(ed).toggleMatches();
        return ok();
      },
    ),
  ];
}

const _triggerSchema = JsonSchema.string(
  enumValues: ['onClick', 'withPrevious', 'afterPrevious'],
);

/// The slide whose builds the commands edit (not in masters mode: builds
/// on layouts and masters are P2, 06 §2.4).
String? _slide(DeckEditorController ed) =>
    ed.editsMasters ? null : ed.currentSlideId;

/// The elements a build command targets: [a]'s `elementIds` or the
/// selection — top-level elements of the current slide.
List<String> _elements(DeckEditorController ed, JsonArgs a) {
  final slideId = _slide(ed);
  if (slideId == null) return const [];
  final given = a.strings('elementIds');
  final ids = given.isNotEmpty ? given : ed.selectedElementIds;
  return [
    for (final id in ids)
      if (ed.model.element(id) case final e?
          when e.slideId == slideId && e.parentId == null)
        id,
  ];
}

/// The builds a command edits: `buildIds`, else the Build tab's builds
/// (selected rows, or the edited builds of the selected elements).
List<String> _builds(DeckEditorController ed, JsonArgs a) {
  final given = a.strings('buildIds');
  if (given.isNotEmpty) {
    return [
      for (final id in given)
        if (ed.model.build(id) != null) id,
    ];
  }
  if (_slide(ed) == null) return const [];
  final view = AnimateView.maybeOf(ed);
  if (view == null) return const [];
  return [for (final b in view.editedBuilds()) b.id];
}

/// [_builds], else every build of the selected elements (context menu
/// *Remove animations*).
List<String> _buildsOrOfElements(DeckEditorController ed, JsonArgs a) {
  final ids = _builds(ed, a);
  if (ids.isNotEmpty) return ids;
  final els = _elements(ed, a).toSet();
  final slideId = _slide(ed);
  if (els.isEmpty || slideId == null) return const [];
  return [
    for (final b in ed.model.buildsOf(slideId))
      if (els.contains(b.elementId)) b.id,
  ];
}

String? _single(
  DeckEditorController ed,
  JsonArgs a, {
  bool anySurface = false,
}) {
  final given = a.string('elementId');
  if (given != null) {
    final e = ed.model.element(given);
    if (e == null) return null;
    if (!anySurface && e.slideId == null) return null;
    return given;
  }
  final sel = anySurface
      ? ed.selectedElementIds
      : _elements(ed, const JsonArgs());
  return sel.length == 1 ? sel.single : null;
}

String _slideOfBuild(DeckEditorController ed, String buildId) =>
    ed.model.build(buildId)?.slideId ?? ed.currentSlideId ?? '';

List<String> _slidesOf(DeckEditorController ed, JsonArgs a) {
  final given = a.strings('slideIds');
  if (given.isNotEmpty) {
    return [
      for (final id in given)
        if (ed.model.slide(id) != null) id,
    ];
  }
  return _transitionSlides(ed, const JsonArgs());
}

/// `slideIds`, else the navigator selection when it holds the current
/// slide (Transition tab edits apply to every selected slide, 06 §5.1),
/// else the current slide.
List<String> _transitionSlides(DeckEditorController ed, JsonArgs a) {
  final given = a.strings('slideIds');
  if (given.isNotEmpty) {
    return [
      for (final id in given)
        if (ed.model.slide(id) != null) id,
    ];
  }
  final cur = _slide(ed);
  if (cur == null) return const [];
  final sel = ed.selectedSlideIds;
  if (sel.length > 1 && sel.contains(cur)) {
    return [
      for (final e in ed.order.entries)
        if (sel.contains(e.id)) e.id,
    ];
  }
  return [cur];
}

String? _previewSlide(DeckEditorController ed, JsonArgs a) {
  final given = a.string('slideId');
  if (given != null) return ed.model.slide(given) == null ? null : given;
  return _slide(ed);
}

String? _magicSource(DeckEditorController ed, JsonArgs a) {
  final given = a.string('slideId');
  if (given != null) return ed.model.slide(given) == null ? null : given;
  return _slide(ed);
}

/// The element *Copy animation* copies from: `elementId`, the selected
/// build's element, or the single selected element.
String? _copySource(DeckEditorController ed, JsonArgs a) {
  final given = a.string('elementId');
  if (given != null) return given;
  final view = AnimateView.maybeOf(ed);
  final sel = view?.selectedBuildIds ?? const <String>[];
  if (sel.isNotEmpty) return ed.model.build(sel.first)?.elementId;
  final els = _elements(ed, const JsonArgs());
  return els.length == 1 ? els.single : null;
}

/// The (selected) build of [effect] a motion command edits.
SlideBuildRec? _effectBuild(
  DeckEditorController ed,
  JsonArgs a,
  String effect,
) {
  final id = a.string('buildId');
  final ids = id == null ? _builds(ed, a) : [id];
  if (ids.length != 1) return null;
  final b = ed.model.build(ids.single);
  return b != null && b.effect == effect ? b : null;
}

/// The reorder of [a]: `to` (index / before / after) or `by` ±1.
MoveBuilds? _moveOf(DeckEditorController ed, JsonArgs a) {
  final ids = _builds(ed, a);
  if (ids.isEmpty) return null;
  final trigger = SlideBuildTrigger.fromName(a.string('trigger'));
  final to = a.values['to'];
  if (to is Map) {
    return BuildEdits.move(
      ed.model,
      ids,
      index: (to['index'] as num?)?.toInt(),
      beforeBuildId: to['beforeBuildId'] as String?,
      afterBuildId: to['afterBuildId'] as String?,
      trigger: trigger,
    );
  }
  final by = a.integer('by');
  if (by == null || by == 0) return null;
  final slideId = ed.model.build(ids.first)?.slideId;
  if (slideId == null) return null;
  final all = [for (final b in ed.model.buildsOf(slideId)) b.id];
  final moving = ids.toSet();
  if (by < 0) {
    final first = all.indexWhere(moving.contains);
    if (first <= 0) return null;
    return MoveBuilds(ids, beforeId: all[first - 1], trigger: trigger);
  }
  final last = all.lastIndexWhere(moving.contains);
  if (last < 0 || last >= all.length - 1) return null;
  return MoveBuilds(ids, afterId: all[last + 1], trigger: trigger);
}

/// The build kind of [effect] on [tab] (Action: emphasis or motion).
SlideBuildKind _kindOf(BuildKindTab tab, String effect) {
  for (final k in tab.kinds) {
    if (EffectCatalog.byId(k, effect) != null) return k;
  }
  return tab.kinds.first;
}

/// The quick-add effect of [tab] (06 A-06-7): the deck's last quick add of
/// that kind, the *Default build* setting (in), Pulse (action), Fade out
/// (out) — when it applies to every element, else Fade / Fade out.
String _defaultEffect(
  DeckEditorController ed,
  BuildKindTab tab,
  List<String> elementIds,
) {
  bool fits(SlideBuildKind kind, String effect) {
    final spec = EffectCatalog.byId(kind, effect);
    if (spec == null || !spec.available) return false;
    for (final id in elementIds) {
      final e = ed.model.element(id);
      if (e != null && !spec.target.accepts(e.kind)) return false;
    }
    return true;
  }

  final deckDefault = DeckMotionDefaults.decode(
    ed.model.deck?.defaultsJson,
  ).build;
  if (deckDefault != null &&
      tab.contains(deckDefault.kind) &&
      fits(deckDefault.kind, deckDefault.effect)) {
    return deckDefault.effect;
  }
  switch (tab) {
    case BuildKindTab.buildIn:
      final pref = SlidesUserDefaults.of(
        ed.services,
      ).string(SlidesUserDefaults.keyDefaultBuild);
      return fits(SlideBuildKind.buildIn, pref) ? pref : 'fade';
    case BuildKindTab.action:
      return 'pulse';
    case BuildKindTab.buildOut:
      return 'fadeOut';
  }
}

void _autoPreview(AnimateView view, String slideId, List<String> buildIds) {
  if (!view.option(AnimateView.optionAutoPreview) || buildIds.isEmpty) return;
  if (view.editor.currentSlideId != slideId) return;
  view.preview.playBuilds(slideId, buildIds);
}

/// Applies [op] as its own undo step coalescing with the previous step of
/// the same [key] (slider drags, steppers: 06 §15 `coalesceKey`). The
/// dispatcher's transaction stays empty and commits nothing.
void _applyCoalesced(
  CommandContext ctx,
  DeckEditorController ed,
  SlidesOperation op,
  String key,
) {
  final plan = ed.session.execute(op);
  if (plan.isEmpty) return;
  final l = slidesL10nOf(ed.services);
  final label = ctx.source.isAgent
      ? (ed.services.l10n?.agentUndoLabel(l.cmdAnimateUpdateBuild) ??
            'AI: ${l.cmdAnimateUpdateBuild}')
      : l.cmdAnimateUpdateBuild;
  final t = ed.services.undo.beginTransaction(
    label,
    source: ctx.source,
    selectionBefore: ctx.selection,
    coalesceKey: key,
  );
  t.record(SlidesRowsUndoEntry(plan.changes, label: plan.label));
  t.commit(selectionAfter: ctx.selection);
}

Map<String, Object?>? _map(Object? v) =>
    v is Map ? {for (final e in v.entries) '${e.key}': e.value} : null;

BuildDelivery? _delivery(Object? v) {
  final m = _map(v);
  if (m == null) return null;
  final r = BuildOptions.fromJson({'delivery': m});
  if (!r.isValid) {
    throw InvalidCommandArgs([
      for (final e in r.errors) JsonSchemaViolation('\$.delivery', e.message),
    ]);
  }
  return r.value.delivery;
}

AfterBuild? _afterBuild(Object? v) {
  final m = _map(v);
  if (m == null) return null;
  final r = BuildOptions.fromJson({'afterBuild': m});
  if (!r.isValid) {
    throw InvalidCommandArgs([
      for (final e in r.errors) JsonSchemaViolation('\$.afterBuild', e.message),
    ]);
  }
  return r.value.afterBuild;
}
