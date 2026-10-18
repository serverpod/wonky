import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart'
    show Chart3DBackends, Chart3DGpuRenderer, paintChartScene;
import 'package:wonky_slides_core/motion.dart';
import 'package:wonky_slides_core/scene.dart';
import 'package:wonky_slides_core/themes.dart';

import '../elements/chart/chart_text.dart';
import '../elements/code/code_scene_painter.dart';
import '../motion/render/motion_node_paint.dart';
import '../motion/render/motion_text_painter.dart';
import 'flutter_text_layout_engine.dart';
import 'slide_image_cache.dart';

/// How scene nodes are painted (06 §12.1): the timeline frame, decoded
/// images, and the editor-only prompt chrome.
class ScenePaintOptions {
  const ScenePaintOptions({
    this.frame = SlideFrame.edit,
    this.images,
    this.drawPrompts = false,
    this.placeholderBorder = const Color(0x8094a3b8),
    this.promptOpacity = 0.45,
    this.devicePixelRatio = 1,
    this.gpuCharts = false,
    this.chartGpu,
    this.imagePixelsPerSu,
  });

  /// Element visual states (the edit frame by default).
  final SlideFrame frame;

  /// Decoded images; null draws no images.
  final SlideImageCache? images;

  /// Whether [PromptNode]s are drawn (editor canvas only, 03 §2.4).
  final bool drawPrompts;

  /// Dashed outline of empty placeholders (app token `placeholderBorder`).
  final Color placeholderBorder;

  /// Opacity of prompt text.
  final double promptOpacity;

  /// Device pixels per logical pixel (chart GPU resolution).
  final double devicePixelRatio;

  /// Whether 3D charts may use the GPU backend (live stages; never
  /// pictures: thumbnails, exports). The first 3D chart starts it (08 §10.1).
  final bool gpuCharts;

  /// The ready GPU backend of 3D charts (`Chart3DBackends.active` when the
  /// stage was built), or null: software rendering.
  final Chart3DGpuRenderer? chartGpu;

  /// Device pixels per slide unit at the top of the scene (the stage's
  /// scale times the device pixel ratio), for sizing image decodes: images
  /// decode at about the size they are drawn at (CQ-43). Null decodes them
  /// at full size.
  final double? imagePixelsPerSu;
}

/// Paints [SlideScene]s and their nodes on a canvas in slide units (the
/// caller scales the canvas).
abstract final class SlideScenePainter {
  static final Expando<Path> _paths = Expando('scenePath');
  static final Expando<Path> _dashed = Expando('sceneDashedPath');
  static final Expando<ui.Paragraph> _runParagraphs = Expando('runParagraph');

  /// Paints the whole [scene] scaled by [scale] (su → logical px),
  /// clipped to the slide when [clip].
  static void paintScene(
    Canvas canvas,
    SlideScene scene, {
    double scale = 1,
    bool clip = true,
    ScenePaintOptions options = const ScenePaintOptions(),
  }) {
    canvas.save();
    if (scale != 1) canvas.scale(scale);
    final bounds = Rect.fromLTWH(0, 0, scene.width, scene.height);
    if (clip) canvas.clipRect(bounds);
    paintBackground(canvas, scene.background, bounds, options);
    for (final n in scene.nodes) {
      paintNode(canvas, n, options);
    }
    canvas.restore();
  }

  /// Paints a slide background into [bounds] (fill, then overlay).
  static void paintBackground(
    Canvas canvas,
    ResolvedBackground background,
    Rect bounds,
    ScenePaintOptions options,
  ) {
    final path = Path()..addRect(bounds);
    _fillPath(canvas, path, background.fill, bounds, options);
    final overlay = background.overlay;
    if (overlay != null) _fillPath(canvas, path, overlay, bounds, options);
  }

  /// Paints one node (and its children) in its parent's coordinates.
  /// [owner] is the animated state of the element the node belongs to
  /// (nodes without an element id inherit it: an element's paths and text
  /// get its parts, colors and line drawing, 06 §12.1).
  static void paintNode(
    Canvas canvas,
    SceneNode node,
    ScenePaintOptions options, {
    ElementVisualState? owner,
  }) {
    final id = node.elementId;
    final state = id == null ? owner : options.frame.elements[id];
    if (state != null && !state.visible) return;
    switch (node) {
      case GroupNode():
        _group(canvas, node, state, options, own: id != null);
      case PathNode():
        if (state != null && MotionNodePaint.handlesPath(state)) {
          MotionNodePaint.paintPath(
            canvas,
            node,
            state,
            fillPath: (c, path, fill, bounds) =>
                _fillPath(c, path, fill, bounds, options),
            strokePath: (n) => n.stroke!.dash.isEmpty
                ? pathOf(n.path)
                : (_dashed[n] ??= _dash(pathOf(n.path), n.stroke!.dash)),
          );
        } else {
          _pathNode(canvas, node, options);
        }
      case ImageNode():
        _image(canvas, node, options);
      case TextNode():
        if (state != null && MotionTextPainter.handles(node, state)) {
          MotionTextPainter.paint(canvas, node, state, paintPlain: paintText);
        } else {
          paintText(canvas, node.layout, node.originX, node.originY);
        }
      case ChartNode():
        _chart(canvas, node, options);
      case CodeNode():
        _code(canvas, node);
      case PromptNode():
        _prompt(canvas, node, options);
    }
  }

  // -------------------------------------------------------------------
  // Groups, effects and visual states

  static void _group(
    Canvas canvas,
    GroupNode g,
    ElementVisualState? inherited,
    ScenePaintOptions options, {
    required bool own,
  }) {
    final scale = _groupScale;
    final state = own ? inherited : null;
    _groupScale *=
        _scaleOf(g.transform.storage) *
        (state == null ? 1 : _scaleOf(state.transform.storage));
    try {
      _paintGroup(canvas, g, inherited, options, own: own);
    } finally {
      _groupScale = scale;
    }
  }

  static void _paintGroup(
    Canvas canvas,
    GroupNode g,
    ElementVisualState? inherited,
    ScenePaintOptions options, {
    required bool own,
  }) {
    // Only the element's own group applies its transform, opacity, blur
    // and mask; nested anonymous groups pass the state on.
    final state = own ? inherited : null;
    canvas.save();
    if (state != null && !_isIdentity(state.transform.storage)) {
      canvas.transform(state.transform.storage);
    }
    if (!_isIdentity(g.transform.storage)) {
      canvas.transform(g.transform.storage);
    }
    final clip = g.clip;
    if (clip != null) {
      if (clip.rect case final r?) {
        canvas.clipRect(Rect.fromLTWH(r.x, r.y, r.width, r.height));
      } else if (clip.path case final p?) {
        canvas.clipPath(pathOf(p));
      }
    }
    // Wipe/iris clips and dissolves of the element (06 §12.1).
    final mask = state == null ? null : MotionNodePaint.groupMask(g, state);
    if (mask != null) {
      if (mask.hidesAll) {
        canvas.restore();
        return;
      }
      mask.clip(canvas);
      if (mask.needsLayer) canvas.saveLayer(mask.layerBounds, Paint());
    }
    void children() {
      for (final c in g.children) {
        paintNode(canvas, c, options, owner: inherited);
      }
    }

    for (final s in g.effects.shadows) {
      final sigma = math.max(0.0, s.blur / 2);
      canvas.save();
      canvas.translate(s.dx, s.dy);
      canvas.saveLayer(
        null,
        Paint()
          ..colorFilter = ColorFilter.mode(Color(s.color), BlendMode.srcIn)
          ..imageFilter = sigma > 0
              ? ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma)
              : null,
      );
      if (s.spread > 0) {
        // Spread approximated by painting the silhouette slightly larger.
        final k = 1 + s.spread / 200;
        canvas.scale(k);
      }
      children();
      canvas.restore();
      canvas.restore();
    }
    final opacity = (g.opacity * (state?.opacity ?? 1))
        .clamp(0.0, 1.0)
        .toDouble();
    final blur = math.max(
      g.effects.blurSigma,
      math.min(state?.blurSigma ?? 0, 40.0),
    );
    if (opacity <= 0) {
      if (mask != null && mask.needsLayer) canvas.restore();
      canvas.restore();
      return;
    }
    if (opacity < 1 || blur > 0) {
      canvas.saveLayer(
        null,
        Paint()
          ..color = Color.fromRGBO(0, 0, 0, opacity)
          ..imageFilter = blur > 0
              ? ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur)
              : null,
      );
      children();
      canvas.restore();
    } else {
      children();
    }
    if (mask != null && mask.needsLayer) {
      mask.paintMask(canvas);
      canvas.restore();
    }
    canvas.restore();
  }

  static bool _isIdentity(Float64List m) {
    for (var i = 0; i < 16; i++) {
      final want = i % 5 == 0 ? 1.0 : 0.0;
      if (m[i] != want) return false;
    }
    return true;
  }

  // -------------------------------------------------------------------
  // Paths

  /// The Flutter path of [p] (cached per scene path).
  static Path pathOf(ScenePath p) => _paths[p] ??= () {
    final path = Path()
      ..fillType = p.evenOdd ? PathFillType.evenOdd : PathFillType.nonZero;
    for (final c in p.commands) {
      switch (c) {
        case PMoveTo(:final x, :final y):
          path.moveTo(x, y);
        case PLineTo(:final x, :final y):
          path.lineTo(x, y);
        case PCubicTo(
          :final x1,
          :final y1,
          :final x2,
          :final y2,
          :final x,
          :final y,
        ):
          path.cubicTo(x1, y1, x2, y2, x, y);
        case PClose():
          path.close();
      }
    }
    return path;
  }();

  static void _pathNode(Canvas canvas, PathNode n, ScenePaintOptions o) {
    final path = pathOf(n.path);
    final fill = n.fill;
    if (fill != null) {
      _fillPath(canvas, path, fill, path.getBounds(), o);
    }
    final s = n.stroke;
    if (s != null && s.width > 0 && (s.color >>> 24) != 0) {
      final paint = strokePaint(s);
      final drawn = s.dash.isEmpty
          ? path
          : (_dashed[n] ??= _dash(path, s.dash));
      canvas.drawPath(drawn, paint);
    }
  }

  /// The paint of a scene stroke.
  static Paint strokePaint(NodeStroke s) => Paint()
    ..style = PaintingStyle.stroke
    ..color = Color(s.color)
    ..strokeWidth = s.width
    ..strokeCap = switch (s.cap) {
      SStrokeCap.round => StrokeCap.round,
      SStrokeCap.square => StrokeCap.square,
      SStrokeCap.butt => StrokeCap.butt,
    }
    ..strokeJoin = switch (s.join) {
      SStrokeJoin.round => StrokeJoin.round,
      SStrokeJoin.bevel => StrokeJoin.bevel,
      SStrokeJoin.miter => StrokeJoin.miter,
    }
    ..isAntiAlias = true;

  static Path _dash(Path path, List<double> pattern) {
    final out = Path();
    if (pattern.every((v) => v <= 0)) return path;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      var i = 0;
      var on = true;
      while (d < m.length) {
        final len = math.max(pattern[i % pattern.length], 0.01);
        final next = math.min(m.length, d + len);
        if (on) out.addPath(m.extractPath(d, next), Offset.zero);
        d = next;
        on = !on;
        i++;
      }
    }
    return out;
  }

  static void _fillPath(
    Canvas canvas,
    Path path,
    ResolvedFill fill,
    Rect bounds,
    ScenePaintOptions o,
  ) {
    switch (fill) {
      case ResolvedNoFill():
        return;
      case ResolvedSolidFill(:final color):
        if ((color >>> 24) == 0) return;
        canvas.drawPath(path, Paint()..color = Color(color));
      case ResolvedGradientFill():
        canvas.drawPath(path, Paint()..shader = gradientShader(fill, bounds));
      case ResolvedImageFill(:final fileUuid, :final fit, :final opacity):
        final image = o.images?.imageOf(
          SlideImageRef('${SlideImageRef.fileScheme}$fileUuid'),
        );
        if (image == null) return;
        canvas.save();
        canvas.clipPath(path);
        _drawFitted(canvas, image, bounds, fit, opacity);
        canvas.restore();
    }
  }

  /// The shader of a gradient fill over [bounds] (05 §2.6, 02 §5.2: linear
  /// angle 0 = left → right, clockwise; radial center and radius as
  /// fractions).
  static Shader gradientShader(ResolvedGradientFill g, Rect bounds) {
    final colors = [for (final (_, c) in g.stops) Color(c)];
    final stops = [for (final (p, _) in g.stops) p];
    if (g.kind == 'radial') {
      final c = Offset(
        bounds.left + g.centerX * bounds.width,
        bounds.top + g.centerY * bounds.height,
      );
      final diag = math.sqrt(
        bounds.width * bounds.width + bounds.height * bounds.height,
      );
      return ui.Gradient.radial(c, math.max(1, g.radius * diag), colors, stops);
    }
    final a = g.angle * math.pi / 180;
    final dx = math.cos(a), dy = math.sin(a);
    final half = (bounds.width * dx).abs() / 2 + (bounds.height * dy).abs() / 2;
    final c = bounds.center;
    return ui.Gradient.linear(
      c - Offset(dx, dy) * half,
      c + Offset(dx, dy) * half,
      colors,
      stops,
    );
  }

  static void _drawFitted(
    Canvas canvas,
    ui.Image image,
    Rect dst,
    String fit,
    double opacity,
  ) {
    final iw = image.width.toDouble(), ih = image.height.toDouble();
    final paint = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0, 1).toDouble());
    final src = Rect.fromLTWH(0, 0, iw, ih);
    switch (fit) {
      case 'stretch':
        canvas.drawImageRect(image, src, dst, paint);
      case 'contain' || 'cover':
        final s = fit == 'cover'
            ? math.max(dst.width / iw, dst.height / ih)
            : math.min(dst.width / iw, dst.height / ih);
        final r = Rect.fromCenter(
          center: dst.center,
          width: iw * s,
          height: ih * s,
        );
        canvas.drawImageRect(image, src, r, paint);
      default: // tile
        paint.shader = ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          Float64List.fromList([
            1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, dst.left, dst.top, 0, 1, //
          ]),
        );
        canvas.drawRect(dst, paint);
    }
  }

  // -------------------------------------------------------------------
  // Images

  /// The device-pixel width the whole image of [n] is drawn at (null =
  /// full size): its destination width at the scene's scale and the
  /// enclosing groups' scales, divided by the cropped fraction.
  static double? _drawnWidth(ImageNode n, ScenePaintOptions o) {
    final px = o.imagePixelsPerSu;
    if (px == null) return null;
    final nw = n.image.naturalWidth;
    final frac = nw == null || nw <= 0 ? n.src.width : n.src.width / nw;
    if (frac <= 0) return null;
    return n.dst.width * px * _groupScale / frac;
  }

  /// The scale of the groups being painted (their transforms and visual
  /// states), for [_drawnWidth].
  static double _groupScale = 1;

  static double _scaleOf(Float64List m) => math.max(
    math.sqrt(m[0] * m[0] + m[1] * m[1]),
    math.sqrt(m[4] * m[4] + m[5] * m[5]),
  );

  static void _image(Canvas canvas, ImageNode n, ScenePaintOptions o) {
    final image = o.images?.imageOf(n.image, width: _drawnWidth(n, o));
    if (image == null) return;
    var src = Rect.fromLTWH(n.src.x, n.src.y, n.src.width, n.src.height);
    if (n.image.naturalWidth == null || n.image.naturalHeight == null) {
      // Crop fractions of an image of unknown size (02 §6.4).
      src = Rect.fromLTWH(
        src.left * image.width,
        src.top * image.height,
        src.width * image.width,
        src.height * image.height,
      );
    } else if (n.image.naturalWidth != image.width) {
      // Downscaled upload: map natural pixels onto decoded pixels.
      final k = image.width / n.image.naturalWidth!;
      src = Rect.fromLTWH(
        src.left * k,
        src.top * k,
        src.width * k,
        src.height * k,
      );
    }
    final dst = Rect.fromLTWH(n.dst.x, n.dst.y, n.dst.width, n.dst.height);
    canvas.save();
    if (n.mask case final m?) canvas.clipPath(pathOf(m));
    final paint = Paint()..filterQuality = FilterQuality.medium;
    if (n.colorMatrix case final cm?) {
      paint.colorFilter = ColorFilter.matrix(cm);
    }
    if (n.blurSigma > 0) {
      paint.imageFilter = ui.ImageFilter.blur(
        sigmaX: n.blurSigma,
        sigmaY: n.blurSigma,
      );
    }
    canvas.drawImageRect(image, src, dst, paint);
    canvas.restore();
  }

  // -------------------------------------------------------------------
  // Text

  /// Paints a text layout at ([ox], [oy]): the engine's paragraphs when
  /// laid out by [FlutterTextLayoutEngine], else run by run.
  static void paintText(
    Canvas canvas,
    TextLayoutResult layout,
    double ox,
    double oy,
  ) {
    final paras = FlutterTextLayoutEngine.paragraphsOf(layout);
    if (paras != null) {
      for (final p in paras.paragraphs) {
        canvas.drawParagraph(p.paragraph, Offset(ox + p.dx, oy + p.dy));
      }
      return;
    }
    for (final line in layout.lines) {
      final runs = [?line.bullet, ...line.runs];
      for (final r in runs) {
        final para = _runParagraphs[r] ??= _runParagraph(r);
        canvas.drawParagraph(
          para,
          Offset(
            ox + line.left + r.x,
            oy + line.baseline - para.alphabeticBaseline - r.baselineShift,
          ),
        );
      }
    }
  }

  static ui.Paragraph _runParagraph(TextRunBox r) {
    final b = ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1))
      ..pushStyle(
        ui.TextStyle(
          color: Color(r.color),
          fontFamily: r.fontFamily.isEmpty ? null : r.fontFamily,
          fontSize: r.fontSize,
          fontWeight:
              FontWeight.values[((r.fontWeight ~/ 100) - 1).clamp(0, 8)],
          fontStyle: r.italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: r.letterSpacing,
          decoration: TextDecoration.combine([
            if (r.underline) TextDecoration.underline,
            if (r.strike) TextDecoration.lineThrough,
          ]),
          decorationColor: Color(r.color),
          background: r.highlight == null
              ? null
              : (Paint()..color = Color(r.highlight!)),
        ),
      )
      ..addText(r.text);
    return b.build()..layout(const ui.ParagraphConstraints(width: 1e6));
  }

  static void _prompt(Canvas canvas, PromptNode n, ScenePaintOptions o) {
    if (!o.drawPrompts) return;
    final rect = Rect.fromLTWH(n.box.x, n.box.y, n.box.width, n.box.height);
    final border = _dash(Path()..addRect(rect), const [8, 6]);
    canvas.drawPath(
      border,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = o.placeholderBorder,
    );
    final layout = n.layout;
    if (layout == null) return;
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(0, 0, 0, o.promptOpacity),
    );
    paintText(canvas, layout, n.originX, n.originY);
    canvas.restore();
  }

  // -------------------------------------------------------------------
  // Charts and code

  static void _chart(Canvas canvas, ChartNode n, ScenePaintOptions o) {
    final s = n.scene;
    if (s.width <= 0 || s.height <= 0) return;
    canvas.save();
    canvas.translate(n.dst.x, n.dst.y);
    canvas.clipRect(Rect.fromLTWH(0, 0, n.dst.width, n.dst.height));
    canvas.scale(n.dst.width / s.width, n.dst.height / s.height);
    final threeD = s.threeD != null;
    if (threeD && o.gpuCharts) Chart3DBackends.ensureStarted();
    final gpu = threeD && o.gpuCharts ? o.chartGpu : null;
    // Physical px per chart px: the GPU target matches the screen.
    final m = canvas.getTransform();
    final scale = math.sqrt(m[0] * m[0] + m[1] * m[1]);
    paintChartScene(
      canvas,
      s,
      text: SlidesChartText.measurer,
      gpu: gpu,
      gpuKey: gpu == null ? null : 'slides.chart:${n.elementId}',
      pixelRatio: o.devicePixelRatio * (scale > 0 ? scale : 1),
    );
    canvas.restore();
  }

  /// Code elements (07): the full `CodeScene` painter of SL-31.
  static void _code(Canvas canvas, CodeNode n) =>
      CodeScenePainter.paint(canvas, n.scene, n.dst);

  /// The font families a scene draws text with (font preloading, 05
  /// §3.3).
  static Set<String> fontFamiliesOf(SlideScene scene) {
    final out = <String>{};
    void add(TextLayoutResult? l) {
      if (l == null) return;
      for (final line in l.lines) {
        for (final r in [?line.bullet, ...line.runs]) {
          if (r.fontFamily.isNotEmpty) out.add(r.fontFamily);
        }
      }
    }

    void walk(List<SceneNode> nodes) {
      for (final n in nodes) {
        switch (n) {
          case TextNode(:final layout):
            add(layout);
          case PromptNode(:final layout):
            add(layout);
          case ChartNode(:final scene):
            out.addAll(SlidesChartText.familiesOf(scene));
          case CodeNode(:final scene):
            out.add(scene.fontFamily);
            for (final c in scene.callouts) {
              if (c.fontFamily.isNotEmpty) out.add(c.fontFamily);
            }
          case GroupNode(:final children):
            walk(children);
          default:
            break;
        }
      }
    }

    walk(scene.nodes);
    return out;
  }

  /// The effective color behind slide content (luminance decisions).
  static int backgroundColor(SlideScene scene) =>
      scene.background.effectiveColor(0xffffffff);
}
