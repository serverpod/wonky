import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey, SemanticsService;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show ShadTheme;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart'
    show ElementVisualState, SlideFrame;
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/snapping.dart';
import 'package:wonky_slides_core/themes.dart' show SuRect;

import '../../l10n/slides_l10n.dart';
import '../editor_screen/deck_editor_controller.dart';
import '../selection/reading_order.dart';
import '../selection/slide_elements.dart';
import '../selection/transform_session.dart';
import '../settings/slides_user_defaults.dart';
import '../stage/slide_renderer.dart';
import '../motion/render/frame_diff.dart';
import '../stage/slide_stage.dart';
import '../text_editing/text_edit_geometry.dart' show sceneWithoutText;
import '../text_editing/text_editing_host.dart';
import '../text_editing/text_editing_layer.dart';
import 'canvas_interactions.dart';
import 'canvas_overlay_painter.dart';
import 'canvas_tools.dart';
import 'ruler_painter.dart';
import 'canvas_tokens.dart';
import 'slide_canvas_controller.dart';

/// Opens a context menu ([menuId] of 04 §11) at a global position.
typedef CanvasContextMenu = void Function(String menuId, Offset globalPosition);

/// The slide canvas of the Normal view (03 §2–§5): the current slide drawn
/// by SL-10's [SlideStage] on the pasteboard (off-slide content at 40 %),
/// the selection overlay, and every pointer gesture — click / Shift+click /
/// Mod+click (deep select), marquee (Alt: touching), double-click into
/// element groups, drag to move (Shift constrains, Alt duplicates, Mod
/// disables snapping), resize by 8 handles (Shift aspect, Alt from center),
/// rotate (Shift 15°), shape adjust handles, line endpoints with gluing,
/// Space/middle-drag panning, wheel scrolling and Mod+wheel / pinch zoom.
///
/// Drags preview live as transforms of the moving elements (no relayout,
/// nothing written) and write **one** command on drop (`slides.element.
/// move` / `resize` / `adjust` / `setLineEnds`), so each gesture is one
/// undo step. The keyboard scope (`slidesCanvas`) and the empty-deck state
/// stay with the editor screen's canvas region.
///
/// API: `SlideCanvas(editor:, controller:)`; the [SlideCanvasController]
/// carries the deck's [SlideRenderer] ([renderer]), the viewport and the
/// selection the element work packages (SL-13…SL-15) build on.
class SlideCanvas extends StatefulWidget {
  const SlideCanvas({
    super.key,
    required this.editor,
    required this.controller,
    this.onContextMenu,
  });

  /// The editor (session, current slide, selection ids, zoom, role).
  final DeckEditorController editor;

  /// The canvas state of the deck.
  final SlideCanvasController controller;

  /// Opens `context.slide` / `context.element` (04 §11).
  final CanvasContextMenu? onContextMenu;

  /// The deck's renderer.
  SlideRenderer get renderer => controller.renderer;

  @override
  State<SlideCanvas> createState() => _SlideCanvasState();
}

enum _Drag {
  none,
  pending,
  move,
  resize,
  rotate,
  marquee,
  adjust,
  lineEnd,
  pan,
  guide,
  tool,
  interaction,
}

class _SlideCanvasState extends State<SlideCanvas> {
  SlideCanvasController get c => widget.controller;
  DeckEditorController get ed => widget.editor;

  _Drag _drag = _Drag.none;
  Offset _downPx = Offset.zero;
  Offset _downSu = Offset.zero;
  Offset _lastPx = Offset.zero;
  int? _pointer;
  CanvasHandle? _handle;
  // Pending click: the element hit at pointer down and whether the press
  // changed the selection (a click on a selected element of a
  // multi-selection selects it alone on release).
  String? _downHit;
  bool _downSelected = false;
  List<String> _marqueeBase = const [];
  Duration? _lastDownAt;
  Offset _lastDownPx = Offset.zero;
  List<String> _announced = const [];
  CanvasToolDrag? _tool;
  CanvasInteraction? _interaction;
  Offset? _hoverSu;

  @override
  void initState() {
    super.initState();
    c.selection.addListener(_announceSelection);
  }

  @override
  void didUpdateWidget(SlideCanvas old) {
    super.didUpdateWidget(old);
    if (!identical(old.controller, widget.controller)) {
      old.controller.selection.removeListener(_announceSelection);
      widget.controller.selection.addListener(_announceSelection);
    }
  }

  @override
  void dispose() {
    c.selection.removeListener(_announceSelection);
    _live.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ helpers

  static bool get _isMac =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  TransformModifiers get _mods {
    final k = HardwareKeyboard.instance;
    return TransformModifiers(
      shift: k.isShiftPressed,
      alt: k.isAltPressed,
      mod: _isMac ? k.isMetaPressed : k.isControlPressed,
    );
  }

  bool get _spaceHeld => HardwareKeyboard.instance.logicalKeysPressed.contains(
    LogicalKeyboardKey.space,
  );

  SlidesUserDefaults get _prefs => ed.defaults;

  bool get _snapObjects =>
      _prefs.flag(SlidesUserDefaults.keySnapObjects) &&
      _prefs.flag(SlidesUserDefaults.keySmartGuides);

  bool get _snapGuides => _prefs.flag(SlidesUserDefaults.keySnapGuides);

  /// The deck's guides, decoded once per `guidesJson` (the overlay
  /// painter compares the list by identity).
  List<UserGuide> get _userGuides {
    final json = ed.model.deck?.guidesJson;
    if (json != _guidesJson || _guides == null) {
      _guidesJson = json;
      _guides = UserGuides.decode(json);
    }
    return _guides!;
  }

  String? _guidesJson;
  List<UserGuide>? _guides;

  double get _threshold => SnapEngine.thresholdFor(c.viewport.scale);

  Future<void> _run(String id, Map<String, Object?> args) async {
    try {
      final r = await ed.invokeCommand(id, args, InvocationSource.ui, context);
      if (r.status != CommandStatus.ok && r.message != null && mounted) {
        ed.services.toasts.show(r.message!);
      }
    } on CommandException catch (e) {
      if (mounted) ed.services.toasts.show(e.toString());
    }
  }

  /// Element-kind modes (SL-15: crop mode, table cells).
  List<CanvasInteraction> get _modes => CanvasInteractions.of(c);

  CanvasPointer _ptr(PointerEvent e) => CanvasPointer(
    px: e.localPosition,
    su: c.viewport.toSlide(e.localPosition),
    global: e.position,
    modifiers: _mods,
    buttons: e.buttons,
  );

  /// Gives [i] the gesture of pointer [e].
  void _takeBy(CanvasInteraction i, PointerDownEvent e) {
    _pointer = e.pointer;
    _drag = _Drag.interaction;
    _interaction = i;
  }

  // ------------------------------------------------------------ pointer

  void _onDown(PointerDownEvent e) {
    if (_pointer != null) return;
    c.takeCancel();
    // Widgets on the canvas (crop bar, upload badges) handle themselves.
    if (CanvasChrome.hits(context, e.position)) return;
    final px = e.localPosition;
    final su = c.viewport.toSlide(px);
    final primary =
        e.buttons & (kMiddleMouseButton | kSecondaryMouseButton) == 0;
    // Modal modes (image crop mode) take every press first (03 §6.5.4).
    if (primary) {
      for (final i in _modes) {
        if (i.modal && i.active && i.down(_ptr(e))) {
          ed.canvasFocus.requestFocus();
          _takeBy(i, e);
          return;
        }
      }
    }
    // Text editing (03 §6.1): inside the box the editor handles the
    // pointer (a press beside the laid-out text moves the caret there);
    // outside it ends editing and the press goes on as usual.
    final text = textEditingOf(ed);
    if (text.isEditing && e.buttons & kMiddleMouseButton == 0) {
      if (text.hits(su)) {
        if (e.buttons & kSecondaryMouseButton != 0) {
          // The word under the pointer gets the caret (spelling, SL-44).
          text.prepareContextMenu(su);
          widget.onContextMenu?.call('context.text', e.position);
        } else if (!text.hitsText(su)) {
          text.placeCaretAt(su);
        }
        return;
      }
      text.end(select: false);
    }
    ed.canvasFocus.requestFocus();
    _pointer = e.pointer;
    _downPx = _lastPx = px;
    _downSu = su;
    final m = _mods;

    if (e.buttons & kMiddleMouseButton != 0 || _spaceHeld) {
      _drag = _Drag.pan;
      return;
    }
    if (e.buttons & kSecondaryMouseButton != 0) {
      _pointer = null;
      _contextMenu(su, e.position);
      return;
    }

    // Armed shape/line/painter tools (SL-14, `CanvasTools`) draw instead
    // of selecting.
    final tool = ed.canEdit ? CanvasTools.of(ed) : null;
    if (tool != null) {
      _drag = _Drag.tool;
      _tool = CanvasToolDrag(c, tool, su, m);
      return;
    }

    // Rulers: drag out a new guide (03 §5.6).
    final ruler = _rulerAt(px);
    if (ruler != null) {
      _drag = ed.canEdit ? _Drag.guide : _Drag.none;
      if (ed.canEdit) {
        c.guide = GuidePreview(ruler, _guideCoord(ruler, su));
      }
      return;
    }

    // Double-click: enter groups / activate (03 §3.4).
    final now = e.timeStamp;
    final last = _lastDownAt;
    _lastDownAt = now;
    final dbl =
        last != null &&
        now > last &&
        now - last < kDoubleTapTimeout &&
        (px - _lastDownPx).distance < kDoubleTapSlop;
    _lastDownPx = px;
    if (dbl) {
      _lastDownAt = null;
      _drag = _Drag.none;
      _doubleClick(su);
      return;
    }

    final h = c.handleAt(px);
    if (h != null) {
      _handle = h;
      _startHandle(h, su);
      return;
    }

    // Element-kind modes (table cells and borders, SL-15).
    for (final i in _modes) {
      if (!i.modal && i.down(_ptr(e))) {
        _takeBy(i, e);
        return;
      }
    }

    // Existing guides move (or go when dropped off the slide).
    if (ed.guides && ed.canEdit) {
      final guides = _userGuides;
      final i = c.guideAt(px, guides);
      if (i != null) {
        _drag = _Drag.guide;
        c.guide = GuidePreview(guides[i].axis, guides[i].at, index: i);
        return;
      }
    }

    final path = c.hitPath(su);
    final picked = path.isEmpty ? null : c.pick(su, deep: _deep(path, m));
    _downHit = picked?.$1;
    _downSelected = false;
    if (picked != null) {
      final (id, group) = picked;
      final selected = ed.selectedElementIds.contains(id);
      if (m.shift || (m.mod && !_deep(path, m))) {
        c.selection.toggle(id);
        _downSelected = true;
      } else if (!selected) {
        c.selection.select([id], enteredGroup: group);
        _downSelected = true;
      }
      _drag = ed.selectedElementIds.contains(id) ? _Drag.pending : _Drag.none;
    } else {
      if (!m.shift) c.selection.clear();
      _marqueeBase = m.shift ? ed.selectedElementIds : const [];
      _drag = _Drag.pending;
    }
  }

  /// Mod+click on a child inside a group that isn't entered selects it
  /// directly (03 §3.2 deep select).
  bool _deep(List<String> path, TransformModifiers m) =>
      m.mod && path.length > 1 && !path.contains(c.selection.enteredGroupId);

  void _onMove(PointerMoveEvent e) {
    if (e.pointer != _pointer) return;
    if (c.takeCancel()) {
      if (_drag == _Drag.interaction) _interaction?.cancel();
      _drag = _Drag.none;
      _handle = null;
      return;
    }
    if (_drag == _Drag.interaction) {
      _interaction?.move(_ptr(e));
      return;
    }
    final px = e.localPosition;
    final delta = px - _lastPx;
    _lastPx = px;
    final su = c.viewport.toSlide(px);
    switch (_drag) {
      case _Drag.none:
        return;
      case _Drag.pan:
        c.viewport.panBy(delta);
      case _Drag.tool:
        _tool?.update(su, _mods, (px - _downPx).distance);
      case _Drag.guide:
        final g = c.guide;
        if (g == null) return;
        final slide = c.slide?.bounds;
        final at = _guideCoord(g.axis, su);
        final off =
            slide != null &&
            (g.axis == GuideAxis.vertical
                ? su.dx < slide.x || su.dx > slide.right
                : su.dy < slide.y || su.dy > slide.bottom);
        c.guide = GuidePreview(g.axis, at, index: g.index, remove: off);
      case _Drag.pending:
        if ((px - _downPx).distance < 3) return;
        if (_downHit != null) {
          _startMove();
        } else {
          _drag = _Drag.marquee;
        }
        _update(su);
      default:
        _update(su);
        _autoScroll(px);
    }
  }

  void _update(Offset su) {
    final m = _mods;
    switch (_drag) {
      case _Drag.move || _Drag.resize || _Drag.rotate:
        final t = c.transform;
        if (t == null) return;
        t.update(su, m);
        c.transform = t;
      case _Drag.marquee:
        final r = _rectOf(_downSu, su);
        c.selection.marquee = r;
        final hits = c.marqueeHits(r, touching: m.alt);
        c.selection.select({..._marqueeBase, ...hits});
      case _Drag.adjust:
        _updateAdjust(su);
      case _Drag.lineEnd:
        _updateLineEnd(su, m);
      default:
        break;
    }
  }

  static SuRect _rectOf(Offset a, Offset b) => SuRect(
    math.min(a.dx, b.dx),
    math.min(a.dy, b.dy),
    (a.dx - b.dx).abs(),
    (a.dy - b.dy).abs(),
  );

  /// Pans while dragging within 24 px of the viewport edge (zoomed in,
  /// 03 §4.1).
  void _autoScroll(Offset px) {
    if (!c.viewport.scrollable) return;
    final size = c.viewport.viewport;
    var dx = 0.0, dy = 0.0;
    if (px.dx < 24) dx = 12;
    if (px.dx > size.width - 24) dx = -12;
    if (px.dy < 24) dy = 12;
    if (px.dy > size.height - 24) dy = -12;
    if (dx != 0 || dy != 0) c.viewport.panBy(Offset(dx, dy));
  }

  void _onUp(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    final cancelled = c.takeCancel();
    final drag = cancelled ? _Drag.none : _drag;
    _pointer = null;
    _drag = _Drag.none;
    final interaction = _interaction;
    _interaction = null;
    if (interaction != null) {
      if (cancelled) {
        interaction.cancel();
      } else {
        interaction.up(_ptr(e));
      }
      return;
    }
    switch (drag) {
      case _Drag.pending:
        // A click without moving on an element of a multi-selection
        // selects it alone.
        final hit = _downHit;
        if (hit != null &&
            !_downSelected &&
            !_mods.shift &&
            ed.selectedElementIds.length > 1) {
          c.selection.select([hit], enteredGroup: c.selection.enteredGroupId);
        }
      case _Drag.move || _Drag.resize || _Drag.rotate:
        unawaited(_commitTransform());
      case _Drag.adjust:
        unawaited(_commitAdjust());
      case _Drag.lineEnd:
        unawaited(_commitLineEnd());
      case _Drag.guide:
        unawaited(_commitGuide());
      case _Drag.tool:
        final t = _tool;
        if (t != null) unawaited(t.tool.commit(ed, t.finish(), context));
      default:
        break;
    }
    _tool = null;
    if (drag == _Drag.pending) _clickPlaceholder();
    c.endGesture();
    _handle = null;
    _downHit = null;
  }

  void _onCancel(PointerCancelEvent e) {
    if (e.pointer != _pointer) return;
    _interaction?.cancel();
    _interaction = null;
    _pointer = null;
    _drag = _Drag.none;
    _handle = null;
    _tool = null;
    c.endGesture();
  }

  void _onHover(PointerHoverEvent e) {
    final hover = c.viewport.toSlide(e.localPosition);
    if (_hoverSu != hover && _modes.any((i) => i.cursorAt(hover) != null)) {
      setState(() => _hoverSu = hover);
    } else {
      _hoverSu = hover;
    }
    c.toolHover = CanvasTools.of(ed)?.gesture == CanvasToolGesture.line
        ? c.viewport.toSlide(e.localPosition)
        : null;
    c.hoverHandle = c.handleAt(e.localPosition);
    final over = c.hitPath(c.viewport.toSlide(e.localPosition));
    final overSelected =
        over.isNotEmpty && over.any(ed.selectedElementIds.contains);
    if (overSelected != _overSelected) {
      setState(() => _overSelected = overSelected);
    }
  }

  bool _overSelected = false;

  void _onSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(e, (event) {
        final s = event as PointerScrollEvent;
        if (_mods.mod) {
          final factor = math.exp(-s.scrollDelta.dy / 300);
          c.viewport.zoomAt(ed.zoom * factor, s.localPosition);
        } else {
          c.viewport.panBy(-s.scrollDelta);
        }
      });
    } else if (e is PointerScaleEvent) {
      c.viewport.zoomAt(ed.zoom * e.scale, e.localPosition);
    }
  }

  double _pinchZoom = 1;

  void _onPanZoomStart(PointerPanZoomStartEvent e) => _pinchZoom = ed.zoom;

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent e) {
    if ((e.scale - 1).abs() > 0.01) {
      c.viewport.zoomAt(_pinchZoom * e.scale, e.localPosition);
    } else {
      c.viewport.panBy(e.panDelta);
    }
  }

  // ------------------------------------------------------- gesture starts

  void _startMove() {
    if (!c.canTransform) {
      _drag = _Drag.none;
      return;
    }
    final frames = c.selectionFrames();
    _drag = _Drag.move;
    c.transform = TransformSession.move(
      frames,
      _downSu,
      targets: c.snapTargets(
        frames.keys.toSet(),
        objects: _snapObjects,
        guides: _snapGuides,
        userGuides: _userGuides,
      ),
      threshold: _threshold,
    );
  }

  void _startHandle(CanvasHandle h, Offset su) {
    switch (h.kind) {
      case CanvasHandleKind.resize:
        final frames = c.selectionFrames();
        final sel = c.selection.selected;
        final aspect =
            sel.length == 1 &&
            switch (sel.single.record.kind) {
              ElementKind.image ||
              ElementKind.icon ||
              ElementKind.group => true,
              _ => false,
            };
        _drag = _Drag.resize;
        c.transform = TransformSession.resize(
          frames,
          su,
          h.resize!,
          targets: c.snapTargets(
            frames.keys.toSet(),
            objects: _snapObjects,
            guides: _snapGuides,
            userGuides: _userGuides,
          ),
          threshold: _threshold,
          keepAspect: aspect,
          minSize: sel.any((e) => e.record.kind == ElementKind.line) ? 0 : 1,
        );
      case CanvasHandleKind.rotate:
        _drag = _Drag.rotate;
        c.transform = TransformSession.rotate(c.selectionFrames(), su);
      case CanvasHandleKind.adjust:
        _drag = _Drag.adjust;
      case CanvasHandleKind.lineStart || CanvasHandleKind.lineEnd:
        _drag = _Drag.lineEnd;
        _lineTargets = c.snapTargets(
          {h.elementId!},
          objects: _snapObjects,
          guides: _snapGuides,
          userGuides: _userGuides,
          sites: true,
        );
    }
  }

  SnapTargets? _lineTargets;

  void _updateAdjust(Offset su) {
    final h = _handle;
    final id = h?.elementId;
    final key = h?.adjustKey;
    if (id == null || key == null) return;
    final e = c.elements?[id];
    final f = c.frameOf(id);
    if (e == null || f == null) return;
    final gk = e.data?['geometry'];
    final g = ShapeLibrary.of(gk is String ? gk : null);
    if (g == null) return;
    final local = SlideCanvasController.slideToLocal(f, su);
    final raw = e.data?['adjust'];
    final value = g.adjustFromPoint(
      key,
      f.width,
      f.height,
      local.dx,
      local.dy,
      adjust: raw is Map ? raw.cast<String, Object?>() : null,
    );
    c.adjust = AdjustPreview(id, key, value, f);
  }

  void _updateLineEnd(Offset su, TransformModifiers m) {
    final h = _handle;
    final id = h?.elementId;
    final route = id == null ? null : c.scene?.routes[id];
    if (id == null || route == null || route.isEmpty) return;
    final isStart = h!.kind == CanvasHandleKind.lineStart;
    final fixedPt = isStart ? route.last : route.first;
    final t = _lineTargets;
    final snap = t == null || m.mod
        ? SnapPointResult(su.dx, su.dy)
        : SnapEngine.snapPoint(su.dx, su.dy, t, _threshold);
    c.lineEnd = LineEndPreview(
      id,
      isStart ? 'start' : 'end',
      Offset(fixedPt.x, fixedPt.y),
      Offset(snap.x, snap.y),
      site: snap.site,
      guides: snap.guides,
    );
  }

  void _doubleClick(Offset su) {
    final path = c.hitPath(su);
    if (path.isEmpty) return;
    final els = c.elements;
    if (els == null) return;
    // The element at the current selection level.
    final entered = c.selection.enteredGroupId;
    var i = 0;
    if (entered != null) {
      final j = path.indexOf(entered);
      if (j >= 0) i = j + 1;
    }
    if (i >= path.length) return;
    final target = els[path[i]];
    if (target == null) return;
    if (target.record.kind == ElementKind.group && i + 1 < path.length) {
      c.selection.enterGroup(target.id, childId: path[i + 1]);
      return;
    }
    c.selection.select([target.id], enteredGroup: entered);
    final args = {'x': su.dx, 'y': su.dy};
    final st = ed.services.dispatcher.stateOf('slides.element.activate', args);
    if (st.enabled) unawaited(_run('slides.element.activate', args));
  }

  void _contextMenu(Offset su, Offset global) {
    final picked = c.pick(su);
    if (picked != null && !ed.selectedElementIds.contains(picked.$1)) {
      c.selection.select([picked.$1], enteredGroup: picked.$2);
    } else if (picked == null) {
      c.selection.clear();
    }
    String? menu;
    for (final i in _modes) {
      menu = i.contextMenuAt(su);
      if (menu != null) break;
    }
    widget.onContextMenu?.call(
      menu ??
          (ed.selectedElementIds.isEmpty ? 'context.slide' : 'context.element'),
      global,
    );
  }

  // ------------------------------------------------------------- commits

  /// A click (no drag) on an empty text placeholder puts the caret in it
  /// (Google Slides' *Click to add title*, 03 §6.2).
  void _clickPlaceholder() {
    final hit = _downHit;
    if (hit == null || _mods.shift || _mods.mod) return;
    if (!listEquals(ed.selectedElementIds, [hit])) return;
    final e = c.elements?[hit];
    if (e == null ||
        e.placeholderType == null ||
        !(e.placeholderType?.holdsText ?? false) ||
        !SlidesText.isBlank(e.text)) {
      return;
    }
    final text = textEditingOf(ed);
    if (text.canEdit(hit)) unawaited(text.begin(hit));
  }

  Future<void> _commitTransform() async {
    final t = c.transform;
    if (t == null || !t.changed || !ed.canEdit) return;
    switch (t.kind) {
      case TransformKind.move:
        final ids = t.frames.keys.toList();
        final topLevel = ids.every((id) => c.elements?.parentOf(id) == null);
        await _run('slides.element.move', {
          'ids': ids,
          'dx': _r(t.delta.dx),
          'dy': _r(t.delta.dy),
          if (t.duplicate && topLevel) 'duplicate': true,
        });
      case TransformKind.resize || TransformKind.rotate:
        final rotate = t.kind == TransformKind.rotate;
        await _run('slides.element.resize', {
          'frames': [
            for (final MapEntry(:key, :value) in t.liveFrames.entries)
              _rawFrame(key, value, rotate: rotate),
          ],
          'label': rotate ? 'rotate' : 'resize',
        });
    }
  }

  /// The stored frame args of element [id] for slide-space frame [f]
  /// (children of element groups in the group's child space).
  Map<String, Object?> _rawFrame(
    String id,
    ElementFrame f, {
    required bool rotate,
  }) {
    final els = c.elements;
    final parent = els?.parentOf(id);
    final raw = parent == null
        ? f
        : FrameTransforms.toChild(
            f,
            SlideElements.frameOf(parent),
            SlideElements.childBoundsOf(parent),
          );
    return {
      'id': id,
      'x': _r(raw.x),
      'y': _r(raw.y),
      if (!rotate) ...{
        'width': _r(raw.width),
        'height': _r(raw.height),
        'flipH': raw.flipH,
        'flipV': raw.flipV,
      },
      if (rotate) 'rotation': raw.rotation,
      // An auto-width text box resized by hand wraps from now on (03 §4.2).
      if (!rotate && _autoWidth(id)) 'wrap': true,
    };
  }

  bool _autoWidth(String id) {
    final e = c.elements?[id];
    final s = c.slide;
    if (e == null || s == null || e.record.kind != ElementKind.text) {
      return false;
    }
    return SlideTextEditing.boxStyleOf(e, s).wrap == false;
  }

  /// The ruler strip at viewport point [px] and the axis of the guide it
  /// creates (top ruler → horizontal guide), or null.
  GuideAxis? _rulerAt(Offset px) {
    if (!ed.rulers) return null;
    if (px.dy < _rulerSize && px.dx >= _rulerSize) return GuideAxis.horizontal;
    if (px.dx < _rulerSize && px.dy >= _rulerSize) return GuideAxis.vertical;
    return null;
  }

  static const _rulerSize = 20.0;

  /// The guide position of slide point [su] (whole su).
  static double _guideCoord(GuideAxis axis, Offset su) =>
      (axis == GuideAxis.vertical ? su.dx : su.dy).roundToDouble();

  Future<void> _commitGuide() async {
    final g = c.guide;
    if (g == null) return;
    final i = g.index;
    if (i == null) {
      if (!g.remove && !_inRuler(g)) {
        await _run('slides.guides.add', {'axis': g.axis.name, 'at': g.at});
      }
    } else if (g.remove) {
      await _run('slides.guides.delete', {'index': i});
    } else if (g.at != _userGuides[i].at) {
      await _run('slides.guides.move', {'index': i, 'at': g.at});
    }
  }

  /// Whether a new guide was released back over its ruler (cancel).
  bool _inRuler(GuidePreview g) {
    final p = c.viewport.toViewport(
      g.axis == GuideAxis.vertical ? Offset(g.at, 0) : Offset(0, g.at),
    );
    return g.axis == GuideAxis.vertical ? p.dx < _rulerSize : p.dy < _rulerSize;
  }

  /// Gesture values are rounded to 0.01 su (finer than a screen pixel at
  /// 400 %), so stored frames stay tidy.
  static double _r(double v) => (v * 100).roundToDouble() / 100;

  Future<void> _commitAdjust() async {
    final a = c.adjust;
    if (a == null) return;
    await _run('slides.element.adjust', {
      'id': a.elementId,
      'key': a.key,
      'value': a.value,
    });
  }

  Future<void> _commitLineEnd() async {
    final l = c.lineEnd;
    if (l == null) return;
    final id = l.elementId;
    final data = c.elements?[id]?.data;
    // The fixed end keeps its glue.
    Map<String, Object?> fixedEnd() {
      final raw = data?[l.end == 'start' ? 'end' : 'start'];
      final connect = raw is Map ? raw['connect'] : null;
      return {
        'x': l.fixed.dx,
        'y': l.fixed.dy,
        if (connect is Map && connect['elementId'] is String)
          'elementId': LineEndpoint.elementIdOf(connect['elementId'] as String),
        if (connect is Map && connect['site'] != null)
          'site': '${connect['site']}',
      };
    }

    final moving = {
      'x': _r(l.moving.dx),
      'y': _r(l.moving.dy),
      if (l.site != null) 'elementId': l.site!.elementId,
      if (l.site != null) 'site': l.site!.site,
    };
    await _run('slides.element.setLineEnds', {
      'id': id,
      'start': l.end == 'start' ? moving : fixedEnd(),
      'end': l.end == 'end' ? moving : fixedEnd(),
    });
  }

  // ---------------------------------------------------------- semantics

  void _announceSelection() {
    final ids = ed.selectedElementIds;
    if (listEquals(ids, _announced) || !mounted) return;
    _announced = ids;
    if (ids.isEmpty || _drag == _Drag.marquee) return;
    final l = slidesL10n(context);
    final String msg;
    if (ids.length == 1) {
      final s = c.slide;
      final e = c.elements?[ids.single];
      if (s == null || e == null) return;
      final order = ReadingOrder.of(
        c.selection.scope,
        slideHeight: s.bounds.height,
      );
      msg = l.canvasAnnounceSelected(
        _nameOf(l, e),
        order.indexWhere((x) => x.id == e.id) + 1,
        order.length,
      );
    } else {
      msg = l.canvasAnnounceSelectedMany(ids.length);
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      msg,
      Directionality.of(context),
    );
  }

  static String _nameOf(SlidesLocalizations l, ResolvedElement e) {
    final name = e.record.name;
    if (name != null && name.isNotEmpty) return name;
    final text = e.text == null ? '' : SlidesText.plainText(e.text).trim();
    final kind = switch (e.record.kind) {
      ElementKind.text => l.elementKindText,
      ElementKind.shape => l.elementKindShape,
      ElementKind.line => l.elementKindLine,
      ElementKind.image => l.elementKindImage,
      ElementKind.table => l.elementKindTable,
      ElementKind.code => l.elementKindCode,
      ElementKind.chart => l.elementKindChart,
      ElementKind.icon => l.elementKindIcon,
      ElementKind.group => l.elementKindGroup,
    };
    if (text.isNotEmpty) {
      final short = text.length > 60 ? '${text.substring(0, 60)}…' : text;
      return '$kind: $short';
    }
    if (e.placeholderType != null) return '${l.elementKindPlaceholder}: $kind';
    final alt = e.record.altText;
    return alt == null || alt.isEmpty ? kind : '$kind: $alt';
  }

  // -------------------------------------------------------------- build

  MouseCursor get _cursor {
    if (_drag == _Drag.pan || _spaceHeld) {
      return _drag == _Drag.pan
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab;
    }
    if (_drag == _Drag.guide) {
      return c.guide?.axis == GuideAxis.vertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow;
    }
    if (!ed.canEdit) return SystemMouseCursors.basic;
    final at = _hoverSu;
    if (at != null && _drag != _Drag.move) {
      for (final i in _modes) {
        final cursor = i.cursorAt(at);
        if (cursor != null) return cursor;
      }
    }
    final tool = CanvasTools.of(ed);
    if (tool != null) return tool.cursor;
    final h = c.hoverHandle ?? _handle;
    if (h != null) {
      return switch (h.kind) {
        CanvasHandleKind.resize => _resizeCursor(h),
        CanvasHandleKind.rotate => SystemMouseCursors.grab,
        _ => SystemMouseCursors.precise,
      };
    }
    if (_drag == _Drag.move) {
      return c.transform?.duplicate ?? false
          ? SystemMouseCursors.copy
          : SystemMouseCursors.move;
    }
    return _overSelected && c.canTransform
        ? SystemMouseCursors.move
        : SystemMouseCursors.basic;
  }

  static MouseCursor _resizeCursor(CanvasHandle h) {
    final r = h.resize!;
    var deg =
        math.atan2(r.sy.toDouble(), r.sx.toDouble()) * 180 / math.pi +
        h.rotation;
    deg = (deg % 180 + 180) % 180;
    final step = ((deg + 22.5) ~/ 45) % 4;
    return switch (step) {
      0 => SystemMouseCursors.resizeLeftRight,
      1 => SystemMouseCursors.resizeUpLeftDownRight,
      2 => SystemMouseCursors.resizeUpDown,
      _ => SystemMouseCursors.resizeUpRightDownLeft,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tokens = CanvasTokens.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return ListenableBuilder(
          listenable: Listenable.merge([
            ed,
            c,
            textEditingOf(ed).editing,
            widget.renderer,
            widget.renderer.images,
          ]),
          builder: (context, _) => _canvas(context, size, tokens),
        );
      },
    );
  }

  Widget _canvas(BuildContext context, Size size, CanvasTokens tokens) {
    final slide = widget.renderer.slideSize;
    c.viewport.layout(size, slide);
    final scene = c.scene;
    if (scene == null) return const SizedBox.expand();
    final v = c.viewport;
    final s = v.scale;
    final o = v.origin;
    final l = slidesL10n(context);
    final entry = ed.currentEntry;
    final title = entry == null ? '' : _slideTitle(scene);
    final editing = textEditingOf(ed).editing.value;
    return ClipRect(
      child: MouseRegion(
        cursor: _cursor,
        onExit: (_) {
          c.hoverHandle = null;
          c.toolHover = null;
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onDown,
          onPointerMove: _onMove,
          onPointerUp: _onUp,
          onPointerCancel: _onCancel,
          onPointerHover: _onHover,
          onPointerSignal: _onSignal,
          onPointerPanZoomStart: _onPanZoomStart,
          onPointerPanZoomUpdate: _onPanZoomUpdate,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: o.dx,
                top: o.dy,
                width: slide.width * s,
                height: slide.height * s,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: tokens.slideShadow,
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: o.dx,
                top: o.dy,
                child: _stage(
                  _stageScene(scene, editing),
                  s,
                  tokens,
                  ed.editsMasters
                      ? _surfaceLabel(l)
                      : entry == null
                      ? null
                      : l.canvasSlideSemantics(
                          entry.index + 1,
                          title.isEmpty ? l.slideUntitled : title,
                        ),
                ),
              ),
              if (editing != null)
                Positioned(
                  left: o.dx,
                  top: o.dy,
                  width: slide.width * s,
                  height: slide.height * s,
                  child: SlideTextEditingLayer(
                    editor: ed,
                    zoom: s,
                    caretColor: tokens.selection,
                    selectionColor: tokens.selection.withValues(alpha: 0.3),
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const ValueKey<String>('slides.canvas.overlay'),
                    painter: CanvasOverlayPainter(
                      c,
                      tokens: tokens,
                      showGuides: ed.guides,
                      guides: _userGuides,
                      labels: CanvasOverlayLabels(
                        position: l.canvasPosition,
                        dimensions: l.canvasDimensions,
                        angle: l.canvasAngle,
                      ),
                    ),
                  ),
                ),
              ),
              for (final i in _modes) ...i.overlays(context),
              ..._semanticsOf(l),
              ..._scrollbars(tokens),
              if (ed.rulers) ..._rulers(context),
            ],
          ),
        ),
      ),
    );
  }

  final SlideLiveTransforms _live = SlideLiveTransforms();
  SlideStage? _stageWidget;
  List<Object?> _stageInputs = const [];

  /// The slide stage, reused while its inputs are the same: a pointer move
  /// of a drag only updates the live transforms of the moving layers
  /// (composited, not repainted, 03 §2.4); elements that are nested in
  /// groups or cross the slide edge move through the frame (repainted).
  Widget _stage(
    SlideScene scene,
    double s,
    CanvasTokens tokens,
    String? label,
  ) {
    final (frame, live) = _preview(scene);
    _live.set(live);
    final inputs = <Object?>[
      scene,
      s,
      frame,
      live.keys.join(','),
      widget.renderer.images,
      ed.viewMode,
      tokens.placeholderBorder,
      label,
    ];
    final cached = _stageWidget;
    if (cached != null && _sameInputs(inputs, _stageInputs)) return cached;
    _stageInputs = inputs;
    return _stageWidget = SlideStage(
      key: ValueKey<String>('slides.canvas.slide.${scene.slideId}'),
      scene: scene,
      scale: s,
      frame: frame,
      live: live.isEmpty ? null : _live,
      images: widget.renderer.images,
      clipToSlide: false,
      offSlideOpacity: 0.4,
      drawPrompts: !ed.viewMode,
      placeholderBorder: tokens.placeholderBorder,
      semanticLabel: label,
    );
  }

  static bool _sameInputs(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i], y = b[i];
      if (identical(x, y)) continue;
      if (x is SlideScene || x is SlideFrame || x != y) return false;
    }
    return true;
  }

  /// The drag preview split into the frame the stage paints (nested
  /// elements, elements crossing the slide edge) and live transforms of
  /// top-level layers that only move and stay inside the slide.
  (SlideFrame, Map<String, Matrix4>) _preview(SlideScene scene) {
    final frame = c.previewFrame();
    if (frame.elements.isEmpty) return (SlideFrame.edit, const {});
    final top = <String, SceneNode>{
      for (final n in scene.nodes) ?n.elementId: n,
    };
    final slide = Rect.fromLTWH(0, 0, scene.width, scene.height);
    bool inside(Rect r) =>
        r.left >= slide.left &&
        r.top >= slide.top &&
        r.right <= slide.right &&
        r.bottom <= slide.bottom;
    final live = <String, Matrix4>{};
    final rest = <String, ElementVisualState>{};
    for (final MapEntry(:key, :value) in frame.elements.entries) {
      final node = top[key];
      final transformOnly = FrameDiff.same(
        value,
        ElementVisualState(transform: value.transform),
      );
      // Only moves: a resized or rotated cached layer would look soft.
      final m = value.transform.storage;
      final translation =
          (m[0] - 1).abs() < 1e-9 &&
          m[1].abs() < 1e-9 &&
          m[4].abs() < 1e-9 &&
          (m[5] - 1).abs() < 1e-9;
      if (node != null && transformOnly && translation) {
        final b = visualBounds(node);
        if (inside(b) &&
            inside(MatrixUtils.transformRect(value.transform, b))) {
          live[key] = value.transform;
          continue;
        }
      }
      rest[key] = value;
    }
    return (rest.isEmpty ? SlideFrame.edit : SlideFrame(rest), live);
  }

  /// The scene the stage draws: without the text being edited (SL-13)
  /// and as the active canvas modes want it (crop mode, SL-15).
  SlideScene _stageScene(SlideScene scene, String? editing) {
    var out = editing == null
        ? scene
        : sceneWithoutText(
            scene,
            editing,
            partId: textEditingOf(ed).active?.cellPartId,
          );
    for (final i in _modes) {
      out = i.sceneFor(out);
    }
    return out;
  }

  /// "Layout Title and content" / "Master Wonky" (masters mode, SL-28).
  String? _surfaceLabel(SlidesLocalizations l) {
    final s = c.slide;
    if (s == null) return null;
    final layout = s.layout;
    return layout != null
        ? l.mastersLayoutSemantics(layout.name)
        : l.mastersMasterSemantics(s.master?.name ?? '');
  }

  String _slideTitle(SlideScene scene) {
    final s = c.slide;
    if (s == null) return '';
    for (final e in s.elements) {
      if (e.placeholderType?.name == 'title' && e.text != null) {
        return SlidesText.plainText(e.text).trim();
      }
    }
    return '';
  }

  List<Widget> _semanticsWidgets = const [];
  List<Object?> _semanticsInputs = const [];

  /// [_semantics], rebuilt only when the slide, scene, selection or
  /// viewport changed (not per pointer move).
  List<Widget> _semanticsOf(SlidesLocalizations l) {
    final v = c.viewport;
    final inputs = <Object?>[
      c.slide,
      c.scene,
      ed.selectedElementIds.join(','),
      c.selection.enteredGroupId,
      v.scale,
      v.origin,
      l,
    ];
    var same = inputs.length == _semanticsInputs.length;
    for (var i = 0; same && i < inputs.length; i++) {
      final a = inputs[i], b = _semanticsInputs[i];
      same =
          identical(a, b) ||
          (a is! SlideScene && a is! ResolvedSlide && a == b);
    }
    if (same) return _semanticsWidgets;
    _semanticsInputs = inputs;
    return _semanticsWidgets = _semantics(l);
  }

  /// One semantics node per element of the selection scope, in reading
  /// order (03 §17.3); tapping one with a screen reader selects it.
  List<Widget> _semantics(SlidesLocalizations l) {
    final s = c.slide;
    if (s == null) return const [];
    final order = ReadingOrder.of(
      c.selection.scope,
      slideHeight: s.bounds.height,
    );
    final v = c.viewport;
    final sc = c.scene;
    return [
      for (final (i, e) in order.indexed)
        () {
          final r = v.rectToViewport(SlideElements.frameOf(e, sc).bounds);
          final selected = ed.selectedElementIds.contains(e.id);
          return Positioned(
            key: ValueKey<String>('slides.canvas.element.${e.id}'),
            left: r.left,
            top: r.top,
            width: math.max(r.width, 1),
            height: math.max(r.height, 1),
            child: IgnorePointer(
              child: Semantics(
                container: true,
                sortKey: OrdinalSortKey(i.toDouble()),
                selected: selected,
                label: e.locked
                    ? l.canvasElementSemantics(
                        _nameOf(l, e),
                        l.canvasStateLocked,
                      )
                    : _nameOf(l, e),
                onTap: e.locked
                    ? null
                    : () => c.selection.select([
                        e.id,
                      ], enteredGroup: c.selection.enteredGroupId),
                child: const SizedBox.expand(),
              ),
            ),
          );
        }(),
    ];
  }

  /// Rulers (03 §5.6, P1): su scales along the top and left edges with the
  /// selection's extent highlighted; dragging from one creates a guide.
  List<Widget> _rulers(BuildContext context) {
    final theme = ShadTheme.of(context);
    final box = c.selectionBox()?.bounds;
    Widget ruler(Axis axis) => IgnorePointer(
      child: CustomPaint(
        key: ValueKey<String>('slides.canvas.ruler.${axis.name}'),
        painter: RulerPainter(
          axis: axis,
          viewport: c.viewport,
          background: theme.colorScheme.card,
          ink: theme.colorScheme.mutedForeground,
          border: theme.colorScheme.border,
          highlight: theme.colorScheme.primary.withValues(alpha: 0.18),
          extent: box,
        ),
      ),
    );
    return [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: _rulerSize,
        child: ruler(Axis.horizontal),
      ),
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: _rulerSize,
        child: ruler(Axis.vertical),
      ),
    ];
  }

  List<Widget> _scrollbars(CanvasTokens tokens) {
    final v = c.viewport;
    final size = v.viewport;
    final color = tokens.dark
        ? const Color(0x66FFFFFF)
        : const Color(0x55000000);
    return [
      if (v.thumb(Axis.horizontal) case (final start, final extent))
        Positioned(
          left: start * size.width,
          width: math.max(24, extent * size.width),
          bottom: 2,
          height: 4,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      if (v.thumb(Axis.vertical) case (final start, final extent))
        Positioned(
          top: start * size.height,
          height: math.max(24, extent * size.height),
          right: 2,
          width: 4,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
    ];
  }
}
