import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:flutter/widgets.dart' show Directionality, Offset, View;
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/clipboard.dart' show SlidesClipboardCodec;
import 'package:wonky_slides_core/model.dart' hide SlidesText;
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart' show ElementCols;
import 'package:wonky_slides_core/session.dart' show SlidesRowsUndoEntry;
import 'package:wonky_slides_core/snapping.dart';
import 'package:wonky_slides_core/themes.dart' show SuRect;
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_sync_models/ids.dart' show Base62Uuid;

import '../features/canvas/slide_canvas_controller.dart';
import '../features/editor_screen/deck_editor_controller.dart';
import '../features/selection/slide_elements.dart';
import '../features/text_editing/text_editing_host.dart' show textEditingOf;
import '../l10n/slides_l10n.dart';
import 'object_commands.dart' show activatableIcon;
import 'slides_command.dart';
import '../features/elements/element_activation.dart';

/// The canvas commands of SL-12 (Slides 03 §2–§5, §8, §11; 04 §4.2, §4.7):
/// selection (`slides.select.*`), transforms written by canvas gestures
/// (`slides.element.move` / `resize` / `nudge` / `adjust` /
/// `setLineEnds`), arrange (`slides.arrange.align` / `distribute` /
/// `centerOnSlide` / `matchSize` / `rotate` / `flip` / `order`), lock and
/// hide, Edit › Delete / Duplicate of objects, user guides and *Zoom to
/// selection*. Every mutating command is one undo step; nudges within
/// 1,000 ms coalesce into one (03 §4.4).
List<Command<CommandArgs>> canvasCommands(ShellServices s) => [
  // ---- Selection (03 §3)
  SlidesCommand(
    'slides.select.elements',
    label: (l) => l.cmdSelectElements,
    categoryOf: SlidesCategory.canvas,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'ids': JsonSchema.array(JsonSchema.string()),
        'enteredGroupId': JsonSchema.string(),
      },
      required: ['ids'],
    ),
    run: (ctx, ed, a) {
      final ids = (a.values['ids'] as List? ?? const []).whereType<String>();
      selectionOf(ed).select(ids, enteredGroup: a.string('enteredGroupId'));
      return ok({'selected': ed.selectedElementIds});
    },
  ),
  for (final (id, label, dir, key) in <(String, SlidesText, int, KeyBinding)>[
    ('slides.select.next', (l) => l.cmdSelectNext, 1, const KeyBinding('Tab')),
    (
      'slides.select.previous',
      (l) => l.cmdSelectPrevious,
      -1,
      const KeyBinding('Tab', shift: true),
    ),
  ])
    SlidesCommand(
      id,
      label: label,
      categoryOf: SlidesCategory.canvas,
      keyScope: SlidesKeyScopes.canvas,
      defaultBindings: [key],
      enabled: (ed, a) => !ed.textEditing,
      run: (ctx, ed, a) {
        final next = selectionOf(ed).cycle(dir);
        _reveal(ed);
        return ok({'selected': ?next});
      },
    ),
  SlidesCommand(
    'slides.select.escape',
    label: (l) => l.cmdSelectEscape,
    icon: LucideIcons.squareDashedMousePointer,
    categoryOf: SlidesCategory.canvas,
    keyScope: SlidesKeyScopes.canvas,
    defaultBindings: const [KeyBinding('Escape')],
    run: (ctx, ed, a) {
      // Esc while dragging cancels the gesture (nothing is written).
      final canvas = SlideCanvasController.of(ed);
      if (canvas != null && canvas.hasGesture) {
        canvas.cancelGesture();
        return ok();
      }
      // Esc returns an armed insert tool / the format painter to Select.
      if (ed.armedTool != null) {
        ed.armTool(null);
        return ok();
      }
      selectionOf(ed).escape();
      return ok();
    },
  ),
  SlidesCommand(
    'slides.select.enterGroup',
    label: (l) => l.cmdSelectEnterGroup,
    categoryOf: SlidesCategory.canvas,
    argsSchema: const JsonSchema.object(
      properties: {
        'groupId': JsonSchema.string(),
        'childId': JsonSchema.string(),
      },
    ),
    enabled: (ed, a) => _groupArg(ed, a) != null,
    reason: (l, ed) => l.reasonSelectGroup,
    run: (ctx, ed, a) {
      final g = _groupArg(ed, a)!;
      selectionOf(ed).enterGroup(g, childId: a.string('childId'));
      return ok();
    },
  ),
  SlidesCommand(
    'slides.element.activate',
    label: (l) => l.cmdElementActivate,
    icon: LucideIcons.textCursorInput,
    categoryOf: SlidesCategory.canvas,
    keyScope: SlidesKeyScopes.canvas,
    defaultBindings: const [KeyBinding('Enter')],
    argsSchema: const JsonSchema.object(
      properties: {
        'x': JsonSchema.number(description: 'Click point (su), for the caret.'),
        'y': JsonSchema.number(),
      },
    ),
    // Element groups are entered (SL-12); text boxes, shapes and text
    // placeholders start text editing with the caret at the click point,
    // or at the end with Enter (SL-13); SL-15 adds crop and table cells
    // (03 §3.4).
    enabled: (ed, a) =>
        _groupArg(ed, a) != null ||
        textEditingOf(ed).editableSelection != null ||
        activatableIcon(ed) != null ||
        ElementActivations.of(ed, a) != null,
    reason: (l, ed) => ed.selectedElementIds.isEmpty
        ? l.reasonSelectObject
        : l.reasonNotOnCanvas,
    run: (ctx, ed, a) async {
      final g = _groupArg(ed, a);
      // Images (crop) and tables (cells), SL-15.
      final kind = g == null ? ElementActivations.of(ed, a) : null;
      if (kind != null) return kind.run(ctx, ed, a);
      if (g == null && activatableIcon(ed) != null) {
        // Icons: the picker replaces the glyph (03 §6.7, SL-14).
        return ed.services.dispatcher.invoke(
          'slides.icon.replace',
          source: ctx.source,
          context: ctx.buildContext,
        );
      }
      if (g == null) {
        final text = textEditingOf(ed);
        final id = text.editableSelection;
        if (id == null) return const CommandResult.failed('Nothing to edit');
        final x = _num(a, 'x'), y = _num(a, 'y');
        final started = await text.begin(
          id,
          at: x == null || y == null ? null : Offset(x, y),
        );
        return started ? ok({'editing': id}) : const CommandResult.cancelled();
      }
      final first = selectionOf(ed).elements?[g]?.children
          .where(SlideElements.selectable)
          .map((e) => e.id)
          .firstOrNull;
      selectionOf(ed).enterGroup(g, childId: first);
      return ok();
    },
  ),

  // ---- Transforms written by canvas gestures (03 §4)
  SlidesCommand(
    'slides.element.move',
    label: (l) => l.cmdElementMove,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'ids': JsonSchema.array(JsonSchema.string()),
        'dx': JsonSchema.number(),
        'dy': JsonSchema.number(),
        'duplicate': JsonSchema.boolean(
          description: 'Alt-drag: move copies, keep the originals.',
        ),
      },
      required: ['dx', 'dy'],
    ),
    enabled: (ed, a) => _ids(ed, a).isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final ids = _ids(ed, a);
      final dx = _num(a, 'dx') ?? 0, dy = _num(a, 'dy') ?? 0;
      if (a.boolean('duplicate') ?? false) {
        return _duplicate(ctx, ed, ids, dx: dx, dy: dy);
      }
      _apply(
        ctx,
        ed,
        UpdateFrames(_moveUpdates(ed, ids, dx, dy), label: 'Move'),
      );
      _announceMove(ed, ids);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.element.resize',
    label: (l) => l.cmdElementResize,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'frames': JsonSchema.array(
          JsonSchema.object(
            properties: {
              'id': JsonSchema.string(),
              'x': JsonSchema.number(),
              'y': JsonSchema.number(),
              'width': JsonSchema.number(),
              'height': JsonSchema.number(),
              'rotation': JsonSchema.number(),
              'flipH': JsonSchema.boolean(),
              'flipV': JsonSchema.boolean(),
              'wrap': JsonSchema.boolean(
                description: 'Text boxes: switch an auto-width box to wrap.',
              ),
            },
            required: ['id'],
          ),
          description:
              'Stored frames (su; children of element groups in the group '
              'child space). Only the given values are written.',
        ),
        'label': JsonSchema.string(enumValues: ['resize', 'rotate']),
      },
      required: ['frames'],
    ),
    undoLabelOf: (l, a) =>
        a.string('label') == 'rotate' ? l.undoRotate : l.cmdElementResize,
    run: (ctx, ed, a) {
      final updates = <FrameUpdate>[
        for (final f in (a.values['frames'] as List? ?? const []))
          if (f is Map && f['id'] is String)
            FrameUpdate(
              f['id'] as String,
              x: (f['x'] as num?)?.toDouble(),
              y: (f['y'] as num?)?.toDouble(),
              width: (f['width'] as num?)?.toDouble(),
              height: (f['height'] as num?)?.toDouble(),
              rotation: (f['rotation'] as num?)?.toDouble(),
              flipH: f['flipH'] as bool?,
              flipV: f['flipV'] as bool?,
            ),
      ];
      if (updates.isEmpty) return const CommandResult.failed('No frames');
      _apply(
        ctx,
        ed,
        UpdateFrames(
          updates,
          label: a.string('label') == 'rotate' ? 'Rotate' : 'Resize',
        ),
      );
      // Auto-width text boxes resized by hand switch to wrapping (03 §4.2).
      final wrap = [
        for (final f in (a.values['frames'] as List? ?? const []))
          if (f is Map && f['id'] is String && f['wrap'] == true)
            f['id'] as String,
      ];
      if (wrap.isNotEmpty) {
        _apply(ctx, ed, SetTextBoxStyle(wrap, {'wrap': true}));
      }
      return ok();
    },
  ),
  SlidesCommand(
    'slides.element.nudge',
    label: (l) => l.cmdElementNudge,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    showInPalette: false,
    keyScope: SlidesKeyScopes.canvas,
    argsSchema: const JsonSchema.object(
      properties: {'dx': JsonSchema.number(), 'dy': JsonSchema.number()},
      required: ['dx', 'dy'],
    ),
    argBindings: [
      for (final (key, dx, dy) in [
        ('ArrowLeft', -1, 0),
        ('ArrowRight', 1, 0),
        ('ArrowUp', 0, -1),
        ('ArrowDown', 0, 1),
      ]) ...[
        ArgsKeyBinding(KeyBinding(key), {'dx': dx, 'dy': dy}),
        ArgsKeyBinding(KeyBinding(key, shift: true), {
          'dx': dx * 10,
          'dy': dy * 10,
        }),
      ],
    ],
    enabled: (ed, a) => _ids(ed, a).isNotEmpty && !ed.textEditing,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final ids = _ids(ed, a);
      final op = UpdateFrames(
        _moveUpdates(ed, ids, _num(a, 'dx') ?? 0, _num(a, 'dy') ?? 0),
        label: 'Nudge',
      );
      final plan = ed.session.execute(op);
      _recordCoalesced(
        ctx,
        ed,
        plan.changes,
        key: 'slides.nudge:${ids.join(',')}',
        label: slidesL10nOf(ed.services).cmdElementNudge,
      );
      _reveal(ed);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.element.adjust',
    label: (l) => l.cmdElementAdjust,
    categoryOf: SlidesCategory.format,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'id': JsonSchema.string(),
        'key': JsonSchema.string(description: 'Adjust key (`radius`, …).'),
        'value': JsonSchema.number(),
      },
      required: ['id', 'key', 'value'],
    ),
    run: (ctx, ed, a) {
      final e = ed.model.element(a.requireString('id'));
      if (e == null) return const CommandResult.failed('No such object');
      if (e.locked) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).errorObjectLocked,
        );
      }
      final data = _decode(e.str(ElementCols.dataJson));
      final adjust = {
        ...?(data['adjust'] as Map?)?.cast<String, Object?>(),
        a.requireString('key'): _num(a, 'value'),
      };
      _apply(
        ctx,
        ed,
        SetElementData(e.id, jsonEncode({...data, 'adjust': adjust})),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.element.setLineEnds',
    label: (l) => l.cmdElementSetLineEnds,
    categoryOf: SlidesCategory.format,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'id': JsonSchema.string(),
        'start': _endpointSchema,
        'end': _endpointSchema,
      },
      required: ['id', 'start', 'end'],
    ),
    run: (ctx, ed, a) => _setLineEnds(ctx, ed, a),
  ),

  // ---- Arrange (03 §4.3, §5.5, §8.3)
  SlidesCommand(
    'slides.arrange.align',
    label: (l) => l.cmdArrangeAlign,
    icon: LucideIcons.alignCenterHorizontal,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    keyScope: SlidesKeyScopes.canvas,
    argsSchema: const JsonSchema.object(
      properties: {
        'edge': JsonSchema.string(
          enumValues: [
            'left',
            'center',
            'centerH',
            'right',
            'top',
            'middle',
            'bottom',
          ],
        ),
      },
      required: ['edge'],
    ),
    argBindings: [
      for (final (key, edge) in [
        ('ArrowLeft', 'left'),
        ('ArrowRight', 'right'),
        ('ArrowUp', 'top'),
        ('ArrowDown', 'bottom'),
      ])
        ArgsKeyBinding(KeyBinding(key, mod: true, alt: true), {'edge': edge}),
    ],
    enabled: (ed, a) => _transformable(ed),
    reason: _transformReason,
    run: (ctx, ed, a) {
      final mode = switch (a.string('edge')) {
        'left' => AlignMode.left,
        'center' || 'centerH' => AlignMode.centerH,
        'right' => AlignMode.right,
        'top' => AlignMode.top,
        'middle' || 'middleV' => AlignMode.middleV,
        'bottom' => AlignMode.bottom,
        _ => null,
      };
      if (mode == null) return const CommandResult.failed('Unknown edge');
      final ids = ed.selectedElementIds;
      final parent = _commonParent(ed, ids);
      if (ids.length == 1 && parent != null) {
        // A single child aligns to its group's box (child space).
        _alignToRect(
          ctx,
          ed,
          ids.single,
          mode,
          SlideElements.childBoundsOf(parent),
        );
        return ok();
      }
      _apply(
        ctx,
        ed,
        AlignDistribute(
          ids,
          mode,
          reference: ids.length == 1
              ? AlignReference.slide
              : AlignReference.selection,
        ),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.arrange.distribute',
    label: (l) => l.cmdArrangeDistribute,
    icon: LucideIcons.alignHorizontalDistributeCenter,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'axis': JsonSchema.string(enumValues: ['horizontal', 'vertical']),
      },
      required: ['axis'],
    ),
    enabled: (ed, a) =>
        _transformable(ed) &&
        ed.selectedElementIds.length >= 3 &&
        _commonParentOk(ed),
    reason: (l, ed) => !_transformable(ed)
        ? _transformReason(l, ed)
        : l.reasonSelectThreeObjects,
    run: (ctx, ed, a) {
      _apply(
        ctx,
        ed,
        AlignDistribute(
          ed.selectedElementIds,
          a.string('axis') == 'vertical'
              ? AlignMode.distributeV
              : AlignMode.distributeH,
        ),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.arrange.centerOnSlide',
    label: (l) => l.cmdArrangeCenterOnSlide,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'axis': JsonSchema.string(
          enumValues: ['horizontal', 'vertical', 'both'],
        ),
      },
    ),
    enabled: (ed, a) => _transformable(ed),
    reason: _transformReason,
    run: (ctx, ed, a) {
      final ids = ed.selectedElementIds;
      final box = _selectionBounds(ed, ids);
      final slide = selectionOf(ed).slide?.bounds;
      if (box == null || slide == null) return ok();
      final axis = a.string('axis') ?? 'both';
      final dx = axis == 'vertical'
          ? 0.0
          : slide.x + slide.width / 2 - (box.x + box.width / 2);
      final dy = axis == 'horizontal'
          ? 0.0
          : slide.y + slide.height / 2 - (box.y + box.height / 2);
      _apply(
        ctx,
        ed,
        UpdateFrames(_moveUpdates(ed, ids, dx, dy), label: 'Align'),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.arrange.matchSize',
    label: (l) => l.cmdArrangeMatchSize,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'dimension': JsonSchema.string(enumValues: ['width', 'height', 'both']),
      },
    ),
    enabled: (ed, a) =>
        _transformable(ed) &&
        ed.selectedElementIds.length >= 2 &&
        _commonParentOk(ed),
    reason: (l, ed) => !_transformable(ed)
        ? _transformReason(l, ed)
        : l.reasonSelectTwoObjects,
    run: (ctx, ed, a) {
      final els = selectionOf(ed).elements;
      final ids = ed.selectedElementIds;
      final key = els?[ids.first];
      if (els == null || key == null) return ok();
      final d = a.string('dimension') ?? 'both';
      final kf = _storedRect(key);
      _apply(
        ctx,
        ed,
        UpdateFrames([
          for (final id in ids.skip(1))
            if (els[id] case final e?)
              FrameUpdate(
                id,
                width: d == 'height' ? _storedRect(e).width : kf.width,
                height: d == 'width' ? _storedRect(e).height : kf.height,
              ),
        ], label: 'Match size'),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.arrange.rotate',
    label: (l) => l.cmdArrangeRotate,
    icon: LucideIcons.rotateCw,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'degrees': JsonSchema.number()},
      required: ['degrees'],
    ),
    undoLabelOf: (l, a) => l.undoRotate,
    enabled: (ed, a) => _transformable(ed),
    reason: _transformReason,
    run: (ctx, ed, a) {
      final deg = _num(a, 'degrees') ?? 90;
      final els = selectionOf(ed).elements;
      _apply(
        ctx,
        ed,
        UpdateFrames([
          for (final id in ed.selectedElementIds)
            if (els?[id] case final e?)
              FrameUpdate(
                id,
                rotation: normalizeRotation((e.record.rotation ?? 0) + deg),
              ),
        ], label: 'Rotate'),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.arrange.flip',
    label: (l) => l.cmdArrangeFlip,
    icon: LucideIcons.flipHorizontal2,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'axis': JsonSchema.string(enumValues: ['horizontal', 'vertical']),
      },
      required: ['axis'],
    ),
    undoLabelOf: (l, a) => l.undoFlip,
    enabled: (ed, a) => _transformable(ed),
    reason: _transformReason,
    run: (ctx, ed, a) {
      final v = a.string('axis') == 'vertical' || a.string('axis') == 'v';
      _apply(
        ctx,
        ed,
        UpdateFrames([
          for (final id in ed.selectedElementIds)
            if (ed.model.element(id) case final e?)
              FrameUpdate(
                id,
                flipH: v ? null : !e.flipH,
                flipV: v ? !e.flipV : null,
              ),
        ], label: 'Flip'),
      );
      return ok();
    },
  ),
  SlidesCommand(
    'slides.arrange.order',
    label: (l) => l.cmdArrangeOrder,
    icon: LucideIcons.bringToFront,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    keyScope: SlidesKeyScopes.canvas,
    argsSchema: const JsonSchema.object(
      properties: {
        'op': JsonSchema.string(
          enumValues: [
            'front',
            'forward',
            'backward',
            'back',
            'bringToFront',
            'bringForward',
            'sendBackward',
            'sendToBack',
          ],
        ),
      },
      required: ['op'],
    ),
    argBindings: const [
      ArgsKeyBinding(KeyBinding('ArrowUp', mod: true, alt: true, shift: true), {
        'op': 'front',
      }),
      ArgsKeyBinding(KeyBinding('ArrowUp', mod: true, shift: true), {
        'op': 'forward',
      }),
      ArgsKeyBinding(KeyBinding('ArrowDown', mod: true, shift: true), {
        'op': 'backward',
      }),
      ArgsKeyBinding(
        KeyBinding('ArrowDown', mod: true, alt: true, shift: true),
        {'op': 'back'},
      ),
    ],
    enabled: (ed, a) => ed.selectedElementIds.isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    run: (ctx, ed, a) {
      final op = switch (a.string('op')) {
        'front' || 'bringToFront' => ZOrderOp.toFront,
        'forward' || 'bringForward' => ZOrderOp.forward,
        'backward' || 'sendBackward' => ZOrderOp.backward,
        'back' || 'sendToBack' => ZOrderOp.toBack,
        _ => null,
      };
      if (op == null) return const CommandResult.failed('Unknown order');
      _apply(ctx, ed, ReorderZ(ed.selectedElementIds, op));
      return ok();
    },
  ),

  // ---- Lock and hide (03 §8.2)
  SlidesCommand(
    'slides.element.toggleLock',
    label: (l) => l.cmdElementToggleLock,
    icon: LucideIcons.lock,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    keyScope: SlidesKeyScopes.canvas,
    defaultBindings: const [KeyBinding('L', mod: true, alt: true, shift: true)],
    dynamicLabel: (l, ed) =>
        _allLocked(ed) ? l.cmdElementUnlock : l.cmdElementLock,
    enabled: (ed, a) => ed.selectedElementIds.isNotEmpty,
    reason: (l, ed) => l.reasonSelectObject,
    checked: (ed, a) => ed.selectedElementIds.isEmpty ? null : _allLocked(ed),
    run: (ctx, ed, a) {
      _apply(
        ctx,
        ed,
        SetElementProps(ed.selectedElementIds, locked: !_allLocked(ed)),
      );
      return ok();
    },
  ),
  for (final (id, label, lock) in <(String, SlidesText, bool)>[
    ('slides.element.lock', (l) => l.cmdElementLock, true),
    ('slides.element.unlock', (l) => l.cmdElementUnlock, false),
  ])
    SlidesCommand(
      id,
      label: label,
      icon: lock ? LucideIcons.lock : LucideIcons.lockOpen,
      categoryOf: SlidesCategory.arrange,
      mutates: true,
      // `ids`: the Layers panel's lock toggles (SL-34).
      argsSchema: const JsonSchema.object(
        properties: {'ids': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) => _ids(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectObject,
      run: (ctx, ed, a) {
        _apply(ctx, ed, SetElementProps(_ids(ed, a), locked: lock));
        return ok();
      },
    ),
  SlidesCommand(
    'slides.element.unlockAll',
    label: (l) => l.cmdElementUnlockAll,
    icon: LucideIcons.lockOpen,
    categoryOf: SlidesCategory.arrange,
    mutates: true,
    enabled: (ed, a) => _lockedOnSlide(ed).isNotEmpty,
    reason: (l, ed) => l.reasonNoLockedObjects,
    run: (ctx, ed, a) {
      _apply(ctx, ed, SetElementProps(_lockedOnSlide(ed), locked: false));
      return ok();
    },
  ),
  for (final (id, label, hide) in <(String, SlidesText, bool)>[
    ('slides.element.hide', (l) => l.cmdElementHide, true),
    ('slides.element.show', (l) => l.cmdElementShow, false),
  ])
    SlidesCommand(
      id,
      label: label,
      icon: hide ? LucideIcons.eyeOff : LucideIcons.eye,
      categoryOf: SlidesCategory.arrange,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'ids': JsonSchema.array(JsonSchema.string())},
      ),
      enabled: (ed, a) => _ids(ed, a).isNotEmpty,
      reason: (l, ed) => l.reasonSelectObject,
      run: (ctx, ed, a) {
        final ids = _ids(ed, a);
        _apply(ctx, ed, SetElementProps(ids, hidden: hide));
        if (hide) {
          selectionOf(ed).select([
            for (final x in ed.selectedElementIds)
              if (!ids.contains(x)) x,
          ]);
        }
        return ok();
      },
    ),

  // ---- Edit › Delete / Duplicate (03 §11)
  SlidesCommand(
    'slides.edit.delete',
    label: (l) => l.cmdEditDelete,
    icon: LucideIcons.trash2,
    categoryOf: SlidesCategory.edit,
    mutates: true,
    keyScope: SlidesKeyScopes.canvas,
    defaultBindings: const [KeyBinding('Backspace'), KeyBinding('Delete')],
    enabled: (ed, a) => ed.selectedElementIds.isNotEmpty
        ? !_anyLocked(ed)
        : _slideCommandEnabled(ed, 'slides.slide.delete'),
    reason: (l, ed) => ed.selectedElementIds.isNotEmpty
        ? l.reasonObjectLocked
        : l.reasonSelectObject,
    run: (ctx, ed, a) async {
      final ids = ed.selectedElementIds;
      if (ids.isEmpty) {
        return ed.invokeCommand('slides.slide.delete', const {}, ctx.source);
      }
      _apply(ctx, ed, DeleteElements(ids));
      selectionOf(ed).clear();
      return ok();
    },
  ),
  SlidesCommand(
    'slides.edit.duplicate',
    label: (l) => l.cmdEditDuplicate,
    icon: LucideIcons.copyPlus,
    categoryOf: SlidesCategory.edit,
    mutates: true,
    keyScope: SlidesKeyScopes.canvas,
    defaultBindings: const [KeyBinding('D', mod: true)],
    enabled: (ed, a) => ed.selectedElementIds.isNotEmpty
        ? _topLevel(ed)
        : _slideCommandEnabled(ed, 'slides.slide.duplicate'),
    reason: (l, ed) => ed.selectedElementIds.isNotEmpty
        ? l.reasonInsideGroup
        : l.reasonSelectObject,
    run: (ctx, ed, a) async {
      final ids = ed.selectedElementIds;
      if (ids.isEmpty) {
        return ed.invokeCommand('slides.slide.duplicate', const {}, ctx.source);
      }
      return _duplicate(ctx, ed, ids);
    },
  ),

  // ---- User guides (03 §5.6)
  SlidesCommand(
    'slides.guides.add',
    label: (l) => l.cmdGuidesAdd,
    categoryOf: SlidesCategory.view,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {
        'axis': JsonSchema.string(
          enumValues: ['vertical', 'horizontal', 'v', 'h'],
        ),
        'at': JsonSchema.number(
          description: 'Position in su (default: the slide center).',
        ),
      },
      required: ['axis'],
    ),
    run: (ctx, ed, a) {
      final axis = GuideAxis.fromCode(a.string('axis'));
      if (axis == null) return const CommandResult.failed('Unknown axis');
      final guides = _guides(ed);
      if (guides.length >= UserGuides.maxGuides) {
        return CommandResult.failed(
          slidesL10nOf(ed.services).errorTooManyGuides,
        );
      }
      final size = ed.model.deck;
      final at =
          _num(a, 'at') ??
          (axis == GuideAxis.vertical
              ? (size?.width ?? 1920) / 2
              : (size?.height ?? 1080) / 2);
      _writeGuides(ctx, ed, [...guides, UserGuide(axis, at)]);
      if (!ed.guides) ed.toggleView('guides');
      return ok({'index': guides.length});
    },
  ),
  SlidesCommand(
    'slides.guides.move',
    label: (l) => l.cmdGuidesMove,
    categoryOf: SlidesCategory.view,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'index': JsonSchema.integer(minimum: 0),
        'at': JsonSchema.number(),
      },
      required: ['index', 'at'],
    ),
    run: (ctx, ed, a) {
      final guides = [..._guides(ed)];
      final i = a.integer('index') ?? -1;
      if (i < 0 || i >= guides.length) {
        return const CommandResult.failed('No such guide');
      }
      guides[i] = UserGuide(guides[i].axis, _num(a, 'at') ?? guides[i].at);
      _writeGuides(ctx, ed, guides);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.guides.delete',
    label: (l) => l.cmdGuidesDelete,
    categoryOf: SlidesCategory.view,
    mutates: true,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {'index': JsonSchema.integer(minimum: 0)},
      required: ['index'],
    ),
    run: (ctx, ed, a) {
      final guides = [..._guides(ed)];
      final i = a.integer('index') ?? -1;
      if (i < 0 || i >= guides.length) {
        return const CommandResult.failed('No such guide');
      }
      guides.removeAt(i);
      _writeGuides(ctx, ed, guides);
      return ok();
    },
  ),
  SlidesCommand(
    'slides.guides.clear',
    label: (l) => l.cmdGuidesClear,
    categoryOf: SlidesCategory.view,
    mutates: true,
    enabled: (ed, a) => _guides(ed).isNotEmpty,
    reason: (l, ed) => l.reasonNoGuides,
    run: (ctx, ed, a) {
      _writeGuides(ctx, ed, const []);
      return ok();
    },
  ),

  // ---- Zoom to selection (03 §2.2)
  SlidesCommand(
    'slides.view.zoomToSelection',
    label: (l) => l.cmdViewZoomToSelection,
    icon: LucideIcons.focus,
    categoryOf: SlidesCategory.view,
    enabled: (ed, a) => SlideCanvasController.of(ed) != null,
    reason: (l, ed) => l.reasonNotAvailableYet,
    run: (ctx, ed, a) {
      final c = SlideCanvasController.of(ed);
      if (c == null) return ok();
      final box = _selectionBounds(ed, ed.selectedElementIds);
      if (box != null) {
        c.viewport.zoomToRect(box);
      } else if (c.slide case final s?) {
        c.viewport.zoomToRect(s.bounds);
      }
      return ok();
    },
  ),
];

// ---------------------------------------------------------------- helpers

double? _num(JsonArgs a, String key) => (a.values[key] as num?)?.toDouble();

const _endpointSchema = JsonSchema.object(
  properties: {
    'x': JsonSchema.number(description: 'Slide x (su).'),
    'y': JsonSchema.number(description: 'Slide y (su).'),
    'elementId': JsonSchema.string(description: 'Glued element.'),
    'site': JsonSchema.string(description: 'Connection site.'),
  },
  required: ['x', 'y'],
);

/// Executes [op] as part of the command's undo step.
SlidesPlan _apply(
  CommandContext ctx,
  DeckEditorController ed,
  SlidesOperation op,
) => ed.apply(ctx, op);

/// `ids` from the args, else the selection.
List<String> _ids(DeckEditorController ed, JsonArgs a) {
  final raw = a.values['ids'];
  if (raw is List) return raw.whereType<String>().toList();
  return ed.selectedElementIds;
}

/// The group a group command acts on (`groupId`, else the single selected
/// element group).
String? _groupArg(DeckEditorController ed, JsonArgs a) {
  final explicit = a.string('groupId');
  final id =
      explicit ??
      (ed.selectedElementIds.length == 1 ? ed.selectedElementIds.single : null);
  if (id == null) return null;
  final e = ed.model.element(id);
  return e != null && e.kind == ElementKind.group && e.ownerId == ed.surfaceId
      ? id
      : null;
}

bool _anyLocked(DeckEditorController ed) =>
    ed.selectedElementIds.any((id) => ed.model.element(id)?.locked ?? false);

bool _allLocked(DeckEditorController ed) =>
    ed.selectedElementIds.isNotEmpty &&
    ed.selectedElementIds.every((id) => ed.model.element(id)?.locked ?? false);

/// Whether the selection can be moved/aligned (objects selected, none
/// locked).
bool _transformable(DeckEditorController ed) =>
    ed.selectedElementIds.isNotEmpty && !_anyLocked(ed);

String? _transformReason(SlidesLocalizations l, DeckEditorController ed) =>
    ed.selectedElementIds.isEmpty ? l.reasonSelectObject : l.reasonObjectLocked;

/// Whether every selected element is at the top level.
bool _topLevel(DeckEditorController ed) =>
    ed.selectedElementIds.every((id) => ed.model.element(id)?.parentId == null);

/// The common element group of [ids], or null (top level or mixed).
ResolvedElement? _commonParent(DeckEditorController ed, List<String> ids) {
  final els = selectionOf(ed).elements;
  if (els == null || ids.isEmpty) return null;
  final parents = {for (final id in ids) els.parentOf(id)?.id};
  return parents.length == 1 && parents.single != null
      ? els[parents.single!]
      : null;
}

/// Whether the selection shares one parent (the planner aligns stored
/// frames, which must be in one space).
bool _commonParentOk(DeckEditorController ed) {
  final els = selectionOf(ed).elements;
  if (els == null) return false;
  return {
        for (final id in ed.selectedElementIds) els.parentOf(id)?.id,
      }.length ==
      1;
}

bool _slideCommandEnabled(DeckEditorController ed, String id) {
  return ed.services.dispatcher.stateOf(id, const {}).enabled;
}

/// Locked elements of the current slide (any depth).
List<String> _lockedOnSlide(DeckEditorController ed) {
  final els = selectionOf(ed).elements;
  if (els == null) return const [];
  return [
    for (final e in els.all)
      if (e.locked) e.id,
  ];
}

/// The stored frame of [e] (its resolved frame for inherited placeholder
/// frames).
SuRect _storedRect(ResolvedElement e) => e.record.frame ?? e.frame;

/// The slide-space bounds of [ids].
SuRect? _selectionBounds(DeckEditorController ed, List<String> ids) {
  final c = SlideCanvasController.of(ed);
  final els = selectionOf(ed).elements;
  if (els == null) return null;
  ElementFrame? frame(String id) {
    final e = els[id];
    return c?.frameOf(id) ?? (e == null ? null : SlideElements.frameOf(e));
  }

  return FrameTransforms.boundsOf([for (final id in ids) ?frame(id)]);
}

/// Frame updates moving [ids] by a slide-space delta: children of element
/// groups move by the delta mapped into their group's child space.
List<FrameUpdate> _moveUpdates(
  DeckEditorController ed,
  List<String> ids,
  double dx,
  double dy,
) {
  final els = selectionOf(ed).elements;
  return [
    for (final id in ids)
      if (els?[id] case final e?) _moveOne(els!, e, dx, dy),
  ];
}

FrameUpdate _moveOne(
  SlideElements els,
  ResolvedElement e,
  double dx,
  double dy,
) {
  var (rdx, rdy) = (dx, dy);
  final parent = els.parentOf(e.id);
  if (parent != null) {
    (rdx, rdy) = FrameTransforms.deltaToChild(
      dx,
      dy,
      SlideElements.frameOf(parent),
      SlideElements.childBoundsOf(parent),
    );
  }
  final r = _storedRect(e);
  return FrameUpdate(e.id, x: r.x + rdx, y: r.y + rdy);
}

/// Aligns element [id] to [ref] (its group's child space).
void _alignToRect(
  CommandContext ctx,
  DeckEditorController ed,
  String id,
  AlignMode mode,
  SuRect ref,
) {
  final e = ed.model.element(id);
  final r = e?.frame;
  if (e == null || r == null) return;
  final box = ElementFrame.of(r, rotation: e.rotation ?? 0).bounds;
  final (dx, dy) = switch (mode) {
    AlignMode.left => (ref.x - box.x, 0.0),
    AlignMode.centerH => (ref.x + ref.width / 2 - (box.x + box.width / 2), 0.0),
    AlignMode.right => (ref.right - box.right, 0.0),
    AlignMode.top => (0.0, ref.y - box.y),
    AlignMode.middleV => (
      0.0,
      ref.y + ref.height / 2 - (box.y + box.height / 2),
    ),
    AlignMode.bottom => (0.0, ref.bottom - box.bottom),
    _ => (0.0, 0.0),
  };
  _apply(
    ctx,
    ed,
    UpdateFrames([FrameUpdate(id, x: r.x + dx, y: r.y + dy)], label: 'Align'),
  );
}

/// Duplicates top-level [ids] on the current slide (+32 su, or moved by
/// [dx]/[dy] for Alt-drag) and selects the copies (03 §11, §4.1).
CommandResult _duplicate(
  CommandContext ctx,
  DeckEditorController ed,
  List<String> ids, {
  double? dx,
  double? dy,
}) {
  final slideId = ed.surfaceId;
  if (slideId == null) return const CommandResult.failed('No slide');
  final payload = SlidesClipboardCodec.copyElements(ed.model, ids);
  double? atX, atY;
  if (dx != null && dy != null) {
    final els = selectionOf(ed).elements;
    final box = unionRects([
      for (final id in ids)
        if (els?[id] case final e?) _storedRect(e),
    ]);
    if (box != null) {
      atX = box.x + dx;
      atY = box.y + dy;
    }
  }
  final plan = _apply(
    ctx,
    ed,
    PasteElements(
      payload,
      slideId,
      atX: atX,
      atY: atY,
      ownerKind: ed.surfaceKind,
    ),
  );
  final created = (plan.result['elementIds'] as List? ?? const [])
      .whereType<String>()
      .toList();
  selectionOf(ed).select(created);
  return ok({'elementIds': created});
}

/// The user guides of the deck.
List<UserGuide> _guides(DeckEditorController ed) =>
    UserGuides.decode(ed.model.deck?.guidesJson);

void _writeGuides(
  CommandContext ctx,
  DeckEditorController ed,
  List<UserGuide> guides,
) =>
    _apply(ctx, ed, SetDeckProps(guidesJson: Patch(UserGuides.encode(guides))));

Map<String, Object?> _decode(String? json) {
  if (json == null || json.isEmpty) return {};
  try {
    final v = jsonDecode(json);
    return v is Map ? v.cast<String, Object?>() : {};
  } on FormatException {
    return {};
  }
}

/// Writes a line's endpoints (slide space) as its frame (the endpoints'
/// bounding box, rotation and flips cleared) and `dataJson.start/end`
/// (normalized positions, glue to connection sites, 02 §6.3; edited route
/// waypoints are cleared, SL-44) — one step.
CommandResult _setLineEnds(
  CommandContext ctx,
  DeckEditorController ed,
  JsonArgs a,
) {
  final id = a.requireString('id');
  final rec = ed.model.element(id);
  if (rec == null || rec.kind != ElementKind.line) {
    return const CommandResult.failed('Not a line');
  }
  if (rec.locked) {
    return CommandResult.failed(slidesL10nOf(ed.services).errorObjectLocked);
  }
  final s = a.values['start'], e = a.values['end'];
  if (s is! Map || e is! Map) {
    return const CommandResult.failed('start and end are required');
  }
  final els = selectionOf(ed).elements;
  final parent = els?.parentOf(id);
  (double, double) point(Map<Object?, Object?> p) {
    final x = (p['x'] as num).toDouble(), y = (p['y'] as num).toDouble();
    if (parent == null) return (x, y);
    final f = FrameTransforms.toChild(
      ElementFrame(x, y, 0, 0),
      SlideElements.frameOf(parent),
      SlideElements.childBoundsOf(parent),
    );
    return (f.x, f.y);
  }

  final (sx, sy) = point(s);
  final (ex, ey) = point(e);
  final x = sx < ex ? sx : ex, y = sy < ey ? sy : ey;
  final w = (sx - ex).abs(), h = (sy - ey).abs();
  Map<String, Object?> end(Map<Object?, Object?> p, double px, double py) {
    final el = p['elementId'];
    return {
      'x': w == 0 ? 0 : _round((px - x) / w),
      'y': h == 0 ? 0 : _round((py - y) / h),
      'connect': el is String && el.isNotEmpty
          ? {'elementId': Base62Uuid.encode(el), 'site': p['site'] ?? 'center'}
          : null,
    };
  }

  final data = _decode(rec.str(ElementCols.dataJson));
  _apply(
    ctx,
    ed,
    UpdateFrames([
      FrameUpdate(
        id,
        x: x,
        y: y,
        width: w,
        height: h,
        rotation: 0,
        flipH: false,
        flipV: false,
      ),
    ], label: 'Move line end'),
  );
  _apply(
    ctx,
    ed,
    SetElementData(
      id,
      jsonEncode({
        'v': 1,
        ...data,
        'start': end(s, sx, sy),
        'end': end(e, ex, ey),
        // Moving an end re-routes the connector automatically: route
        // handle edits (waypoints, SL-44) are relative to the old ends.
        if (data['waypoints'] is List && (data['waypoints'] as List).isNotEmpty)
          'waypoints': const <Object?>[],
      }),
    ),
  );
  return ok();
}

double _round(double v) => (v * 1e6).roundToDouble() / 1e6;

/// Scrolls the selection into view (keyboard nudges and Tab).
void _reveal(DeckEditorController ed) {
  final c = SlideCanvasController.of(ed);
  final box = _selectionBounds(ed, ed.selectedElementIds);
  if (c != null && box != null) c.viewport.reveal(box);
}

/// Announces the moved position for screen readers (03 §17.3).
void _announceMove(DeckEditorController ed, List<String> ids) {
  final box = _selectionBounds(ed, ids);
  final c = ed.services.navigatorContext;
  if (box == null || c == null || !c.mounted) return;
  SemanticsService.sendAnnouncement(
    View.of(c),
    slidesL10nOf(ed.services).canvasAnnounceMoved(box.x.round(), box.y.round()),
    Directionality.of(c),
  );
}

/// [_recordCoalesced] for other command files (outline typing, SL-34).
void recordCoalescedStep(
  CommandContext ctx,
  DeckEditorController ed,
  List<RowChange> changes, {
  required String key,
  required String label,
}) => _recordCoalesced(ctx, ed, changes, key: key, label: label);

/// Records [changes] as one undo step, merged into the previous step with
/// the same [key] within the coalesce window (nudge bursts, 03 §4.4; the
/// Sheets object pattern).
void _recordCoalesced(
  CommandContext ctx,
  DeckEditorController ed,
  List<RowChange> changes, {
  required String key,
  required String label,
}) {
  if (changes.isEmpty) return;
  final doc = ctx.document;
  if (doc == null || ctx.transaction == null) return;
  final undo = ed.services.undo;
  final stack = doc.undoStackKey;
  final steps = undo.undoStepsOf(stack);
  final top = steps.isEmpty ? null : steps.last;
  final now = clock.now();
  if (top != null &&
      top.coalesceKey == key &&
      now.difference(top.updatedAt) <= undo.coalesceWindow &&
      top.entries.length == 1 &&
      top.entries.single is SlidesRowsUndoEntry) {
    final prev = top.entries.single as SlidesRowsUndoEntry;
    undo.replaceLast(
      UndoStep(
        id: top.id,
        label: top.label,
        entries: [
          SlidesRowsUndoEntry(
            mergeRowChanges(prev.changes, changes),
            label: prev.label,
          ),
        ],
        selectionBefore: top.selectionBefore,
        selectionAfter: ctx.selection,
        createdAt: top.createdAt,
        updatedAt: now,
        source: top.source,
        coalesceKey: key,
      ),
      stack: stack,
    );
    return;
  }
  undo.push(
    UndoStep(
      id: ed.services.ids.nextString(),
      label: label,
      entries: [SlidesRowsUndoEntry(changes, label: label)],
      selectionBefore: ctx.selection,
      selectionAfter: ctx.selection,
      source: ctx.source,
      coalesceKey: key,
    ),
    stack: stack,
  );
}

/// [a] then [b] as one list: consecutive updates of the same row merge
/// (earliest before, latest after). Frame-only updates of elements don't
/// depend on each other, so an earlier update of the same row merges too.
List<RowChange> mergeRowChanges(List<RowChange> a, List<RowChange> b) {
  final out = [...a];
  for (final c in b) {
    final i = out.lastIndexWhere(
      (x) => x.table == c.table && x.rowId == c.rowId,
    );
    final mergeable =
        i >= 0 &&
        out[i].op == RowOp.update &&
        c.op == RowOp.update &&
        out.skip(i + 1).every((x) => x.op == RowOp.update);
    if (mergeable) {
      final p = out[i];
      final before = {...p.columnsBefore};
      final after = {...p.columnsAfter};
      c.columnsBefore.forEach((k, v) => before.putIfAbsent(k, () => v));
      after.addAll(c.columnsAfter);
      out[i] = RowChange.update(c.table, c.rowId, before, after);
    } else {
      out.add(c);
    }
  }
  return out;
}
