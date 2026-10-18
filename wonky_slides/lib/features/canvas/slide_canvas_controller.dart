import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/snapping.dart';

import '../elements/code/code_blocks.dart';
import '../editor_screen/deck_editor_controller.dart';
import '../selection/selection_controller.dart';
import '../selection/slide_elements.dart';
import '../selection/transform_session.dart';
import '../stage/slide_renderer.dart';
import 'canvas_controller.dart';
import 'canvas_tools.dart' show ToolPreview;
import '../uploads/slides_image_service.dart';
import 'canvas_interactions.dart';

/// The selection controller of an editor (created on first use; shared by
/// the canvas and the commands, so commands work without a canvas, e.g. in
/// headless command tests).
SelectionController selectionOf(DeckEditorController editor) =>
    _selections[editor] ??= SelectionController(editor);

final Expando<SelectionController> _selections = Expando('slidesSelection');
final Expando<SlideCanvasController> _canvases = Expando('slidesCanvas');

/// What a canvas handle does (03 §3.1, §4).
enum CanvasHandleKind { resize, rotate, adjust, lineStart, lineEnd }

/// A handle of the selection chrome, in viewport px.
class CanvasHandle {
  const CanvasHandle(
    this.kind,
    this.position, {
    this.resize,
    this.adjustKey,
    this.elementId,
    this.rotation = 0,
  });

  final CanvasHandleKind kind;

  /// Center in viewport px.
  final Offset position;

  /// The resize handle, for [CanvasHandleKind.resize].
  final ResizeHandle? resize;

  /// The adjust key, for [CanvasHandleKind.adjust].
  final String? adjustKey;

  /// The element of adjust and line-end handles.
  final String? elementId;

  /// Rotation of the box (degrees), for resize cursors.
  final double rotation;
}

/// A live preview of a shape adjust drag (outline only; written on drop).
class AdjustPreview {
  const AdjustPreview(this.elementId, this.key, this.value, this.frame);

  final String elementId;
  final String key;
  final double value;

  /// The element's slide-space frame.
  final ElementFrame frame;
}

/// A live preview of a line endpoint drag (written on drop).
class LineEndPreview {
  const LineEndPreview(
    this.elementId,
    this.end,
    this.fixed,
    this.moving, {
    this.site,
    this.guides = const [],
  });

  final String elementId;

  /// `start` or `end`: the endpoint being dragged.
  final String end;

  /// The other endpoint (slide space).
  final Offset fixed;

  /// The dragged endpoint (slide space, snapped).
  final Offset moving;

  /// The connection site it glues to, or null.
  final SnapSite? site;
  final List<SnapGuide> guides;
}

/// A live user-guide drag (03 §5.6): a new guide from a ruler ([index]
/// null) or guide [index] being moved; [remove] when released off the
/// slide.
class GuidePreview {
  const GuidePreview(this.axis, this.at, {this.index, this.remove = false});

  final GuideAxis axis;

  /// Position in su.
  final double at;
  final int? index;
  final bool remove;
}

/// Everything the canvas of one open deck needs (03 §1.1): the shared
/// [renderer] (scenes, images, fonts, thumbnails — the navigator and
/// present mode use it too), the viewport ([CanvasController]), the
/// selection ([SelectionController]) and the live gesture previews
/// (transform, marquee, adjust, line endpoints) the overlay paints.
///
/// One per open deck: the editor screen [attach]es it when the deck is
/// ready and disposes it on close; commands find it with [of].
class SlideCanvasController extends ChangeNotifier {
  SlideCanvasController._(this.editor, this.renderer, this._ownsRenderer)
    : viewport = CanvasController(editor),
      selection = selectionOf(editor) {
    viewport.addListener(notifyListeners);
    selection.addListener(notifyListeners);
  }

  /// Creates the canvas controller of [editor] (with its own renderer over
  /// the session's image resolver unless [renderer] is given) and
  /// registers it for [of].
  factory SlideCanvasController.attach(
    DeckEditorController editor, {
    SlideRenderer? renderer,
  }) {
    final c = SlideCanvasController._(
      editor,
      renderer ??
          SlideRenderer(
            model: editor.model,
            images: SlidesImageService.of(editor),
          ),
      renderer == null,
    );
    _canvases[editor] = c;
    return c;
  }

  /// The canvas controller of [editor], or null when no canvas is attached.
  static SlideCanvasController? of(DeckEditorController editor) =>
      _canvases[editor];

  final DeckEditorController editor;
  final SlideRenderer renderer;
  final bool _ownsRenderer;
  final CanvasController viewport;
  final SelectionController selection;
  bool _disposed = false;

  // ------------------------------------------------------------- gestures

  TransformSession? _transform;
  AdjustPreview? _adjust;
  LineEndPreview? _lineEnd;
  CanvasHandle? _hoverHandle;

  /// The live move/resize/rotate, or null.
  TransformSession? get transform => _transform;
  set transform(TransformSession? t) {
    _transform = t;
    notifyListeners();
  }

  /// The live adjust drag, or null.
  AdjustPreview? get adjust => _adjust;
  set adjust(AdjustPreview? a) {
    _adjust = a;
    notifyListeners();
  }

  /// The live line endpoint drag, or null.
  LineEndPreview? get lineEnd => _lineEnd;
  set lineEnd(LineEndPreview? l) {
    _lineEnd = l;
    notifyListeners();
  }

  /// The handle under the mouse (cursor feedback).
  CanvasHandle? get hoverHandle => _hoverHandle;
  set hoverHandle(CanvasHandle? h) {
    if (identical(h, _hoverHandle)) return;
    _hoverHandle = h;
    notifyListeners();
  }

  GuidePreview? _guide;

  ToolPreview? _toolPreview;
  Offset? _toolHover;

  /// The live gesture of an armed insert/pick tool (SL-14), or null.
  ToolPreview? get toolPreview => _toolPreview;
  set toolPreview(ToolPreview? p) {
    _toolPreview = p;
    notifyListeners();
  }

  /// The slide point under the mouse while a line tool is armed (shows
  /// connection sites, 03 §6.4), or null.
  Offset? get toolHover => _toolHover;
  set toolHover(Offset? p) {
    if (p == _toolHover) return;
    _toolHover = p;
    notifyListeners();
  }

  /// The live user-guide drag (from a ruler, or moving a guide), or null.
  GuidePreview? get guide => _guide;
  set guide(GuidePreview? g) {
    _guide = g;
    notifyListeners();
  }

  bool _cancelled = false;

  /// Whether a live gesture is in progress.
  bool get hasGesture =>
      _transform != null ||
      _adjust != null ||
      _lineEnd != null ||
      _guide != null ||
      _toolPreview != null ||
      selection.marquee != null;

  /// Cancels the live gesture (Esc while dragging): nothing is written and
  /// the canvas ignores the rest of the drag.
  void cancelGesture() {
    _cancelled = true;
    endGesture();
  }

  /// Whether [cancelGesture] was called since the last call (the canvas
  /// polls it on pointer events).
  bool takeCancel() {
    final c = _cancelled;
    _cancelled = false;
    return c;
  }

  /// Clears every live preview (drop, cancel, slide change).
  void endGesture() {
    _transform = null;
    _adjust = null;
    _lineEnd = null;
    _guide = null;
    _toolPreview = null;
    selection.marquee = null;
    notifyListeners();
  }

  // --------------------------------------------------------------- scene

  /// The edit-frame scene of the current slide — or of the layout/master
  /// edited in masters mode (SL-28, `DeckEditorController.surfaceId`) —
  /// with prompts while editing.
  SlideScene? get scene {
    final id = editor.surfaceId;
    if (id == null) return null;
    final code = CodeBlockView.maybeOf(editor);
    return renderer.scene(
      id,
      editing: !editor.viewMode,
      codeStates: code?.stateMap ?? const {},
      codeSteps: code?.stepMap ?? const {},
    );
  }

  /// The resolved current slide (the renderer's resolver).
  ResolvedSlide? get slide {
    final id = editor.surfaceId;
    return id == null ? null : renderer.resolver.resolve(id);
  }

  /// The element index of the current slide.
  SlideElements? get elements {
    final s = slide;
    return s == null ? null : SlideElements.of(s);
  }

  /// A live frame source that wins over the scene's frames (SL-13: the
  /// box being edited follows its text before the write, 03 §6.1).
  ElementFrame? Function(String id)? liveFrameOf;

  /// Repaints the canvas chrome (live frames changed).
  void refresh() => notifyListeners();

  /// The slide-space frame of element [id] (derived frames included).
  ElementFrame? frameOf(String id) {
    final live = liveFrameOf?.call(id);
    if (live != null) return live;
    final e = elements?[id];
    return e == null ? null : SlideElements.frameOf(e, scene);
  }

  /// The edit frame with the live transform previews of a drag: each
  /// moving element gets the matrix from its start to its live frame,
  /// expressed in its parent node's space.
  SlideFrame previewFrame() {
    final t = _transform;
    final sc = scene;
    if (t == null || sc == null || !t.changed) return SlideFrame.edit;
    final els = elements;
    final ids = t.liveFrames.keys.toSet();
    final parents = _parentMatrices(sc, ids, {
      for (final id in ids) ...?els?.ancestorsOf(id),
    });
    final states = <String, ElementVisualState>{};
    for (final MapEntry(:key, :value) in t.liveFrames.entries) {
      final from = t.frames[key];
      if (from == null) continue;
      var m = TransformSession.frameMatrix(from, value);
      final parent = parents[key];
      if (parent != null) {
        final inv = Matrix4.zero()..copyInverse(parent);
        m = inv.multiplied(m).multiplied(parent);
      }
      states[key] = ElementVisualState(transform: m);
    }
    return SlideFrame(states);
  }

  /// The composed transforms of the group nodes enclosing the nodes of
  /// [ids] (absent at the top level), in one walk of the scene that only
  /// enters the element groups in [ancestors].
  static Map<String, Matrix4> _parentMatrices(
    SlideScene scene,
    Set<String> ids,
    Set<String> ancestors,
  ) {
    final out = <String, Matrix4>{};
    var found = 0;
    void walk(List<SceneNode> nodes, Matrix4? acc) {
      for (final n in nodes) {
        if (found == ids.length) return;
        final id = n.elementId;
        if (id != null && ids.contains(id) && !out.containsKey(id)) {
          found++;
          if (acc != null) out[id] = acc;
          continue;
        }
        // Only element groups that contain a moving element are entered.
        if (n is GroupNode && ancestors.contains(id)) {
          walk(
            n.children,
            acc == null ? n.transform : acc.multiplied(n.transform),
          );
        }
      }
    }

    walk(scene.nodes, null);
    return out;
  }

  // ----------------------------------------------------------- hit tests

  /// The element path under slide point [p] (outermost first): the
  /// topmost selectable top-level element, then the hit descendants inside
  /// it. Locked and hidden elements are click-through (03 §3.2, §8.2);
  /// transparent shape areas hit near the stroke only, boxes of text,
  /// images, tables, code and charts anywhere inside.
  List<String> hitPath(Offset p, {double tolerancePx = 4}) {
    final sc = scene, els = elements;
    if (sc == null || els == null) return const [];
    final tol = tolerancePx / math.max(viewport.scale, 1e-3);
    for (final n in sc.nodes.reversed) {
      final id = n.elementId;
      if (id == null) continue;
      final e = els[id];
      if (e == null || !SlideElements.selectable(e)) continue;
      if (!_hits(n, e, p.dx, p.dy, tol, sc)) continue;
      return [id, ..._descend(n, p.dx, p.dy, tol, sc, els, p)];
    }
    return const [];
  }

  bool _hits(
    SceneNode n,
    ResolvedElement e,
    double x,
    double y,
    double tol,
    SlideScene sc,
  ) => SceneHitTest.hits(n, x, y, tolerance: tol) || _boxHit(e, x, y, sc);

  static bool _boxHit(ResolvedElement e, double x, double y, SlideScene sc) {
    final hitsBox = switch (e.record.kind) {
      ElementKind.text ||
      ElementKind.table ||
      ElementKind.image ||
      ElementKind.code ||
      ElementKind.chart ||
      ElementKind.icon => true,
      ElementKind.shape => !SlidesText.isBlank(e.text) || e.prompt != null,
      ElementKind.line || ElementKind.group => false,
    };
    if (!hitsBox && e.placeholderType == null) return false;
    return containsPoint(SlideElements.frameOf(e, sc), x, y);
  }

  /// Whether slide point ([x], [y]) is inside the rotated frame [f].
  static bool containsPoint(ElementFrame f, double x, double y) {
    final a = -f.rotation * math.pi / 180;
    final dx = x - f.cx, dy = y - f.cy;
    final lx = dx * math.cos(a) - dy * math.sin(a);
    final ly = dx * math.sin(a) + dy * math.cos(a);
    return lx.abs() <= f.width / 2 + 1e-9 && ly.abs() <= f.height / 2 + 1e-9;
  }

  List<String> _descend(
    SceneNode node,
    double x,
    double y,
    double tol,
    SlideScene sc,
    SlideElements els,
    Offset slidePoint,
  ) {
    if (node is! GroupNode) return const [];
    final inv = Matrix4.zero();
    if (inv.copyInverse(node.transform) == 0) return const [];
    final local = MatrixUtils.transformPoint(inv, Offset(x, y));
    final scale = node.transform.getMaxScaleOnAxis();
    final t = scale == 0 ? tol : tol / scale;
    for (final c in node.children.reversed) {
      final id = c.elementId;
      if (id == null || id == node.elementId) {
        final deeper = _descend(c, local.dx, local.dy, t, sc, els, slidePoint);
        if (deeper.isNotEmpty) return deeper;
        continue;
      }
      final e = els[id];
      if (e == null || !SlideElements.selectable(e)) continue;
      // Box hits use slide-space frames: test them with the slide point.
      if (SceneHitTest.hits(c, local.dx, local.dy, tolerance: t) ||
          _boxHit(e, slidePoint.dx, slidePoint.dy, sc)) {
        return [id, ..._descend(c, local.dx, local.dy, t, sc, els, slidePoint)];
      }
    }
    return const [];
  }

  /// The element a click at slide point [p] selects (03 §3.2): the
  /// top-level element, the child inside the entered group, or with
  /// [deep] (Mod+click) the deepest element. Also returns the group to
  /// enter (the hit element's parent). Null when nothing is hit.
  (String, String?)? pick(Offset p, {bool deep = false}) {
    final path = hitPath(p);
    if (path.isEmpty) return null;
    final els = elements!;
    if (deep) return (path.last, els.parentOf(path.last)?.id);
    final g = selection.enteredGroupId;
    if (g != null) {
      final i = path.indexOf(g);
      if (i >= 0 && i + 1 < path.length) return (path[i + 1], g);
    }
    return (path.first, null);
  }

  /// Elements of the selection scope inside marquee [r] (fully, or
  /// touching with [touching]; 03 §3.2).
  List<String> marqueeHits(SuRect r, {bool touching = false}) {
    final sc = scene;
    return [
      for (final e in selection.scope)
        if (SlideElements.selectable(e) &&
            _inMarquee(SlideElements.frameOf(e, sc).bounds, r, touching))
          e.id,
    ];
  }

  static bool _inMarquee(SuRect b, SuRect r, bool touching) => touching
      ? b.x <= r.right && r.x <= b.right && b.y <= r.bottom && r.y <= b.bottom
      : r.containsRect(b);

  // ------------------------------------------------------------ snapping

  /// Snap targets for moving [moving] (03 §5.1): slide edges/centers, user
  /// guides, the other visible elements (incl. master/layout decorations)
  /// and the entered group's other children; [sites] adds connection
  /// sites for line endpoints.
  SnapTargets snapTargets(
    Set<String> moving, {
    required bool objects,
    required bool guides,
    List<UserGuide> userGuides = const [],
    bool sites = false,
  }) {
    final s = slide;
    final sc = scene;
    final bounds = s?.bounds ?? const SuRect(0, 0, 1920, 1080);
    final boxes = <SnapBox>[];
    final siteList = <SnapSite>[];
    if (s != null) {
      final els = SlideElements.of(s);
      final excluded = {
        ...moving,
        for (final id in moving) ...els.ancestorsOf(id),
      };
      final entered = selection.enteredGroupId;
      final candidates = [
        if (!s.hideMasterElements) ...s.masterElements,
        if (!s.hideMasterElements) ...s.layoutElements,
        ...s.elements,
        if (entered != null) ...els.siblings(entered),
      ];
      for (final e in candidates) {
        if (e.hidden || excluded.contains(e.id)) continue;
        boxes.add(SnapBox(e.id, SlideElements.frameOf(e, sc).bounds));
      }
      if (sites) {
        for (final e in els.all) {
          if (e.hidden ||
              moving.contains(e.id) ||
              e.record.kind == ElementKind.line ||
              e.record.kind == ElementKind.group) {
            continue;
          }
          for (final (site, pt) in ConnectorRouter.slideSites(e)) {
            siteList.add(SnapSite(e.id, site.name, pt.x, pt.y));
          }
        }
      }
    }
    return SnapTargets(
      slide: bounds,
      boxes: boxes,
      guides: userGuides,
      sites: siteList,
      objects: objects,
      guidesOn: guides,
    );
  }

  // ------------------------------------------------------------- chrome

  /// The slide-space frames of the selection (live during a drag).
  Map<String, ElementFrame> selectionFrames() {
    final live = _transform?.liveFrames;
    final out = <String, ElementFrame>{};
    for (final id in selection.ids) {
      final f = live?[id] ?? frameOf(id);
      if (f != null) out[id] = f;
    }
    return out;
  }

  /// The selection box: the single element's (rotated) frame, or the
  /// axis-aligned union of a multi-selection. Null when empty.
  ElementFrame? selectionBox() {
    final frames = selectionFrames();
    if (frames.isEmpty) return null;
    if (frames.length == 1) return frames.values.single;
    return ElementFrame.of(FrameTransforms.boundsOf(frames.values)!);
  }

  /// The slide-space route of the selected line or connector [id] (its
  /// selection outline follows the route — lines show endpoint handles
  /// instead of a box, 03 §3), or null for other elements and while the
  /// selection is being transformed (the frame outline follows the drag).
  List<Offset>? selectedLineRoute(String id) {
    if (_transform != null) return null;
    final e = selection.selected.where((x) => x.id == id).firstOrNull;
    if (e == null || e.record.kind != ElementKind.line) return null;
    final route = scene?.routes[id];
    if (route == null || route.length < 2) return null;
    return [for (final p in route) Offset(p.x, p.y)];
  }

  /// Whether the selection is one line/connector (endpoint handles).
  bool get singleLine {
    final sel = selection.selected;
    return sel.length == 1 && sel.single.record.kind == ElementKind.line;
  }

  /// Whether the selection can be transformed on the canvas (editing,
  /// nothing locked).
  bool get canTransform =>
      editor.canEdit &&
      selection.ids.isNotEmpty &&
      !editor.textEditing &&
      selection.selected.every((e) => !e.locked);

  /// The handles of the selection chrome (viewport px): line endpoints for
  /// a single line; else the 8 resize handles (edge handles hidden when
  /// the box is small on screen), the rotation handle and a single shape's
  /// adjust handles. Empty for viewers and locked selections (03 §4.6).
  List<CanvasHandle> handles() {
    if (!canTransform) return const [];
    final v = viewport;
    final sc = scene;
    if (singleLine) {
      final id = selection.ids.single;
      final route = sc?.routes[id];
      final le = _lineEnd;
      if (route == null || route.isEmpty) return const [];
      var s = Offset(route.first.x, route.first.y);
      var e = Offset(route.last.x, route.last.y);
      if (le != null && le.elementId == id) {
        if (le.end == 'start') {
          s = le.moving;
        } else {
          e = le.moving;
        }
      }
      return [
        CanvasHandle(
          CanvasHandleKind.lineStart,
          v.toViewport(s),
          elementId: id,
        ),
        CanvasHandle(CanvasHandleKind.lineEnd, v.toViewport(e), elementId: id),
      ];
    }
    final box = selectionBox();
    if (box == null) return const [];
    final out = <CanvasHandle>[];
    final small = box.width * v.scale < 24 || box.height * v.scale < 24;
    for (final h in ResizeHandle.values) {
      if (small && !h.isCorner) continue;
      final (x, y) = FrameTransforms.handlePoint(box, h);
      out.add(
        CanvasHandle(
          CanvasHandleKind.resize,
          v.toViewport(Offset(x, y)),
          resize: h,
          rotation: box.rotation,
        ),
      );
    }
    out.add(CanvasHandle(CanvasHandleKind.rotate, rotationHandle(box)));
    final sel = selection.selected;
    if (sel.length == 1 && sel.single.record.kind == ElementKind.shape) {
      out.addAll(_adjustHandles(sel.single, box));
    }
    return out;
  }

  /// The rotation handle 24 px above the top edge (below when the top is
  /// near the viewport's top, 03 §4.3).
  Offset rotationHandle(ElementFrame box) {
    final v = viewport;
    final (tx, ty) = FrameTransforms.handlePoint(box, ResizeHandle.top);
    final a = box.rotation * math.pi / 180;
    final up = Offset(math.sin(a), -math.cos(a));
    final top = v.toViewport(Offset(tx, ty));
    final above = top + up * 24;
    if (above.dy >= 8) return above;
    final (bx, by) = FrameTransforms.handlePoint(box, ResizeHandle.bottom);
    return v.toViewport(Offset(bx, by)) - up * 24;
  }

  List<CanvasHandle> _adjustHandles(ResolvedElement e, ElementFrame f) {
    final key = e.data?['geometry'];
    final g = ShapeLibrary.of(key is String ? key : null);
    if (g == null || g.adjusts.isEmpty) return const [];
    final raw = e.data?['adjust'];
    final adjust = raw is Map ? raw.cast<String, Object?>() : null;
    final a = _adjust;
    final values = {
      ...?adjust,
      if (a != null && a.elementId == e.id) a.key: a.value,
    };
    return [
      for (final MapEntry(:key, value: (lx, ly))
          in g.handles(f.width, f.height, adjust: values).entries)
        CanvasHandle(
          CanvasHandleKind.adjust,
          viewport.toViewport(localToSlide(f, lx, ly)),
          adjustKey: key,
          elementId: e.id,
        ),
    ];
  }

  /// Element-local point ([lx], [ly]) of frame [f] in slide space (flips
  /// and rotation applied).
  static Offset localToSlide(ElementFrame f, double lx, double ly) {
    var x = lx, y = ly;
    if (f.flipH) x = f.width - x;
    if (f.flipV) y = f.height - y;
    final a = f.rotation * math.pi / 180;
    final dx = x - f.width / 2, dy = y - f.height / 2;
    return Offset(
      f.cx + dx * math.cos(a) - dy * math.sin(a),
      f.cy + dx * math.sin(a) + dy * math.cos(a),
    );
  }

  /// Slide point [p] in frame [f]'s local coordinates (inverse of
  /// [localToSlide]).
  static Offset slideToLocal(ElementFrame f, Offset p) {
    final a = -f.rotation * math.pi / 180;
    final dx = p.dx - f.cx, dy = p.dy - f.cy;
    var x = dx * math.cos(a) - dy * math.sin(a) + f.width / 2;
    var y = dx * math.sin(a) + dy * math.cos(a) + f.height / 2;
    if (f.flipH) x = f.width - x;
    if (f.flipV) y = f.height - y;
    return Offset(x, y);
  }

  /// Index of the user guide within 4 px of viewport point [p], or null.
  int? guideAt(Offset p, List<UserGuide> guides) {
    final v = viewport;
    int? best;
    var bestD = 4.0;
    for (final (i, g) in guides.indexed) {
      final d = g.axis == GuideAxis.vertical
          ? (v.toViewport(Offset(g.at, 0)).dx - p.dx).abs()
          : (v.toViewport(Offset(0, g.at)).dy - p.dy).abs();
      if (d <= bestD) {
        best = i;
        bestD = d;
      }
    }
    return best;
  }

  /// The handle at viewport point [p] (16 px touch targets), or null.
  CanvasHandle? handleAt(Offset p) {
    CanvasHandle? best;
    var bestD = 8.0 * 8.0 * 2;
    for (final h in handles()) {
      final d = (h.position - p).distanceSquared;
      if (d <= bestD) {
        best = h;
        bestD = d;
      }
    }
    return best;
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    CanvasInteractions.disposeOf(this);
    if (_canvases[editor] == this) _canvases[editor] = null;
    viewport.removeListener(notifyListeners);
    selection.removeListener(notifyListeners);
    viewport.dispose();
    if (_ownsRenderer) renderer.dispose();
    super.dispose();
  }
}
