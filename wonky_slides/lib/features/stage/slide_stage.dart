import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart'
    show Chart3DBackends;
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/themes.dart';

import '../motion/render/frame_diff.dart';
import '../motion/render/motion_node_paint.dart';
import 'scene_painter.dart';
import 'slide_image_cache.dart';

/// Renders one slide scene at a target size with a [SlideFrame] (06
/// §12.1): shared by the editor canvas, thumbnails (via pictures),
/// presenting and previews.
///
/// The background is one layer; every top-level scene node (an element, a
/// master/layout decoration) gets its own `RepaintBoundary`, so a change to
/// one element — or an animating element — repaints only that layer.
/// Element visual states of [frame] (visibility, opacity, transform, blur)
/// are applied per element. The slide renders as designed in the deck's
/// appearance, independent of the app theme (03 §2.1).
class SlideStage extends StatelessWidget {
  const SlideStage({
    super.key,
    required this.scene,
    this.frame = SlideFrame.edit,
    this.images,
    this.scale,
    this.clipToSlide = true,
    this.offSlideOpacity,
    this.drawPrompts = false,
    this.placeholderBorder = const Color(0x8094a3b8),
    this.semanticLabel,
    this.live,
  });

  /// The scene to draw.
  final SlideScene scene;

  /// Element visual states (the edit frame by default; the timeline's
  /// frames when presenting, 06 §9).
  final SlideFrame frame;

  /// Decoded images (null = images are not drawn).
  final SlideImageCache? images;

  /// Logical pixels per su; null fits the slide into the constraints.
  final double? scale;

  /// Whether content is clipped to the slide (presenting, thumbnails).
  final bool clipToSlide;

  /// When not clipping: the opacity of content outside the slide (the
  /// editor's pasteboard draws it at 40 %, 03 §2.1); null = full.
  final double? offSlideOpacity;

  /// Whether prompts of empty placeholders are drawn (editor only).
  final bool drawPrompts;

  /// Dashed outline color of empty placeholders.
  final Color placeholderBorder;

  /// Semantics label of the slide image.
  final String? semanticLabel;

  /// Live transforms of top-level element layers (a drag's preview on
  /// the editor canvas, 03 §2.4): those layers are moved as composited
  /// layers instead of being repainted. Null = none.
  final SlideLiveTransforms? live;

  /// Stage builds so far (perf tests, CQ-38).
  @visibleForTesting
  static int debugBuilds = 0;

  /// Element-layer paints so far (perf tests, CQ-38).
  @visibleForTesting
  static int debugNodePaints = 0;

  /// The scale that fits [scene] into [size].
  static double fitScale(SlideScene scene, Size size) {
    if (scene.width <= 0 || scene.height <= 0) return 1;
    final s = size.width / scene.width;
    final t = size.height / scene.height;
    if (!s.isFinite && !t.isFinite) return 1;
    if (!s.isFinite) return t;
    if (!t.isFinite) return s;
    return s < t ? s : t;
  }

  @override
  Widget build(BuildContext context) {
    if (scale != null) return _stage(context, scale!);
    return LayoutBuilder(
      builder: (context, c) =>
          _stage(context, fitScale(scene, Size(c.maxWidth, c.maxHeight))),
    );
  }

  Widget _stage(BuildContext context, double s) {
    debugBuilds++;
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final options = ScenePaintOptions(
      frame: frame,
      images: images,
      drawPrompts: drawPrompts,
      placeholderBorder: placeholderBorder,
      devicePixelRatio: dpr,
      imagePixelsPerSu: s * dpr,
      gpuCharts: true,
      chartGpu: Chart3DBackends.active,
    );
    final size = Size(scene.width * s, scene.height * s);
    final stack = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _BackgroundPainter(scene.background, s, options),
            ),
          ),
        ),
        for (final (i, node) in scene.nodes.indexed)
          Positioned.fill(
            key: ValueKey(node.elementId ?? 'decoration:$i'),
            child: _live(
              node,
              s,
              RepaintBoundary(
                child: CustomPaint(
                  painter: _NodePainter(
                    node,
                    s,
                    options,
                    slide: Rect.fromLTWH(0, 0, scene.width, scene.height),
                    offSlideOpacity: clipToSlide ? null : offSlideOpacity,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox.fromSize(
        size: size,
        child: clipToSlide ? ClipRect(child: stack) : stack,
      ),
    );
  }

  Widget _live(SceneNode node, double s, Widget layer) {
    final l = live;
    final id = node.elementId;
    if (l == null || id == null || !l.ids.contains(id)) return layer;
    return ListenableBuilder(
      listenable: l,
      builder: (context, child) {
        final m = l.of(id);
        if (m == null) return child!;
        // Slide space → layer pixels: S · m · S⁻¹.
        final t = Matrix4.diagonal3Values(s, s, 1)
          ..multiply(m)
          ..scaleByDouble(1 / s, 1 / s, 1, 1);
        return Transform(transform: t, child: child);
      },
      child: layer,
    );
  }
}

/// Live transforms of top-level element layers (slide space, applied in
/// the element's parent space like [ElementVisualState.transform]) that a
/// [SlideStage] composites without repainting the layers: the editor
/// canvas's drag preview (03 §2.4). [ids] is fixed per stage build; the
/// matrices change per pointer move and notify.
class SlideLiveTransforms extends ChangeNotifier {
  Map<String, Matrix4> _matrices = const {};
  Set<String> _ids = const {};

  /// The elements moved live.
  Set<String> get ids => _ids;

  /// The live transform of [id], or null.
  Matrix4? of(String id) => _matrices[id];

  /// Sets the live transforms; notifies when one changed.
  void set(Map<String, Matrix4> matrices) {
    if (_same(_matrices, matrices)) return;
    _matrices = matrices;
    _ids = matrices.keys.toSet();
    notifyListeners();
  }

  static bool _same(Map<String, Matrix4> a, Map<String, Matrix4> b) {
    if (a.length != b.length) return false;
    for (final MapEntry(:key, :value) in a.entries) {
      final o = b[key];
      if (o == null ||
          !FrameDiff.same(
            ElementVisualState(transform: value),
            ElementVisualState(transform: o),
          )) {
        return false;
      }
    }
    return true;
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.background, this.scale, this.options)
    : super(repaint: options.images);

  final ResolvedBackground background;
  final double scale;
  final ScenePaintOptions options;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    SlideScenePainter.paintBackground(
      canvas,
      background,
      Rect.fromLTWH(0, 0, size.width / scale, size.height / scale),
      options,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      !identical(old.background, background) || old.scale != scale;
}

class _NodePainter extends CustomPainter {
  _NodePainter(
    this.node,
    this.scale,
    this.options, {
    required this.slide,
    this.offSlideOpacity,
  }) : super(repaint: _hasImages(node) ? options.images : null);

  final SceneNode node;
  final double scale;
  final ScenePaintOptions options;
  final Rect slide;
  final double? offSlideOpacity;

  @override
  void paint(Canvas canvas, Size size) {
    SlideStage.debugNodePaints++;
    canvas.save();
    canvas.scale(scale);
    final off = offSlideOpacity;
    if (off == null || off >= 1) {
      SlideScenePainter.paintNode(canvas, node, options);
      canvas.restore();
      return;
    }
    // Outside the slide at reduced opacity, inside at full (03 §2.1). An
    // element that lies on one side of the slide edge paints once; only
    // one crossing it (or moved by the frame) paints twice (CQ-43).
    final moved = FrameDiff.idsOf(
      node,
    ).any((id) => options.frame.elements.containsKey(id));
    final bounds = moved ? null : visualBounds(node);
    if (bounds != null && _contains(slide, bounds)) {
      SlideScenePainter.paintNode(canvas, node, options);
    } else if (bounds != null && !slide.overlaps(bounds)) {
      canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, off));
      SlideScenePainter.paintNode(canvas, node, options);
      canvas.restore();
    } else {
      final outside = Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(slide.inflate(1e5))
        ..addRect(slide);
      canvas.save();
      canvas.clipPath(outside);
      canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, off));
      SlideScenePainter.paintNode(canvas, node, options);
      canvas.restore();
      canvas.restore();
      canvas.save();
      canvas.clipRect(slide);
      SlideScenePainter.paintNode(canvas, node, options);
      canvas.restore();
    }
    canvas.restore();
  }

  static bool _contains(Rect outer, Rect inner) =>
      inner.left >= outer.left &&
      inner.top >= outer.top &&
      inner.right <= outer.right &&
      inner.bottom <= outer.bottom;

  @override
  bool shouldRepaint(_NodePainter old) =>
      !identical(old.node, node) ||
      old.scale != scale ||
      // Only elements whose frame state changed repaint (06 §12.1).
      !FrameDiff.sameFor(node, old.options.frame, options.frame) ||
      old.options.drawPrompts != options.drawPrompts ||
      !identical(old.options.chartGpu, options.chartGpu) ||
      old.options.placeholderBorder != options.placeholderBorder ||
      !identical(old.options.images, options.images) ||
      old.offSlideOpacity != offSlideOpacity;

  @override
  bool? hitTest(Offset position) => false;
}

/// Records [scene] into a picture at [scale] (thumbnails, snapshot
/// transitions, PNG export); [imagePixelRatio] sizes image decodes
/// (device pixels per picture pixel; 2 keeps hi-DPI thumbnails sharp).
ui.Picture recordScene(
  SlideScene scene, {
  required double scale,
  SlideImageCache? images,
  SlideFrame frame = SlideFrame.edit,
  double imagePixelRatio = 2,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  SlideScenePainter.paintScene(
    canvas,
    scene,
    scale: scale,
    options: ScenePaintOptions(
      frame: frame,
      images: images,
      imagePixelsPerSu: scale * imagePixelRatio,
    ),
  );
  return recorder.endRecording();
}

final Expando<Rect> _visualBounds = Expando('nodeVisualBounds');

/// The painted bounds of top-level scene [node] in slide space (su): its
/// geometry (strokes included) inflated by its shadows, glows and blurs
/// and a margin for glyph overhang. Conservative; used to skip the
/// off-slide layer of elements that don't cross the slide edge.
Rect visualBounds(SceneNode node) => _visualBounds[node] ??=
    MotionNodePaint.childrenBounds([node]).inflate(8 + _effectMargin(node));

double _effectMargin(SceneNode n) {
  switch (n) {
    case GroupNode(:final effects, :final children, :final transform):
      var own = effects.blurSigma * 3;
      for (final s in effects.shadows) {
        own = math.max(
          own,
          s.dx.abs() + s.dy.abs() + s.blur * 3 + s.spread.abs(),
        );
      }
      var inner = 0.0;
      for (final c in children) {
        inner = math.max(inner, _effectMargin(c));
      }
      if (inner > 0) {
        final m = transform.storage;
        final k = math.sqrt(
          math.max(m[0] * m[0] + m[1] * m[1], m[4] * m[4] + m[5] * m[5]),
        );
        inner *= k;
      }
      return own + inner;
    case ImageNode(:final blurSigma):
      return blurSigma * 3;
    default:
      return 0;
  }
}

final Expando<bool> _imageNodes = Expando('nodeHasImages');

/// Whether [node] draws an image (its layer repaints when images decode).
bool _hasImages(SceneNode node) => _imageNodes[node] ??= switch (node) {
  ImageNode() => true,
  PathNode(fill: ResolvedImageFill()) => true,
  GroupNode(:final children) => children.any(_hasImages),
  _ => false,
};
