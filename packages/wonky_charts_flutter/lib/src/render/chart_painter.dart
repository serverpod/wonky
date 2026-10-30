import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/rendering.dart';
import 'package:wonky_charts/wonky_charts.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../three_d/chart3d_gpu.dart';

/// Font used for chart text when the spec names none (or one that isn't
/// bundled): Inter, shipped with `wonky_ui`.
const String kChartDefaultFont = WonkyFonts.inter;

const List<String> _fallbackFonts = [WonkyFonts.inter, WonkyFonts.geist];

/// Families the app can render (bundled fonts); others fall back to
/// [kChartDefaultFont] so layout and paint use the same metrics.
const Set<String> _bundled = {
  WonkyFonts.inter,
  WonkyFonts.geist,
  WonkyFonts.geistMono,
};

/// The bundled Flutter family chart text of family [f] is drawn with
/// (unknown families fall back to [kChartDefaultFont]).
String chartDefaultFamily(String? f) => _family(f);

String _family(String? f) {
  if (f == null || f.isEmpty) return kChartDefaultFont;
  if (_bundled.contains(f)) return f;
  return switch (f.toLowerCase()) {
    'inter' => WonkyFonts.inter,
    'geist' => WonkyFonts.geist,
    'geist mono' || 'geistmono' => WonkyFonts.geistMono,
    _ => kChartDefaultFont,
  };
}

/// The Flutter text style of a scene text style; [familyOf] maps the
/// spec's family to a registered Flutter family (default:
/// [chartDefaultFamily]).
TextStyle chartTextStyle(
  TextStyleSpec s, {
  String Function(String? family)? familyOf,
}) => TextStyle(
  fontFamily: (familyOf ?? _family)(s.family),
  fontFamilyFallback: _fallbackFonts,
  fontSize: s.size,
  fontWeight: s.bold ? FontWeight.w600 : FontWeight.w400,
  fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
  color: Color(s.color),
  height: 1.0,
);

/// `TextPainter`-backed [TextMeasurer] (08 §6.2) with an LRU cache of laid
/// out painters, shared by layout and painting so both agree on metrics.
///
/// [familyOf] maps a spec family to the Flutter family the text is measured
/// and drawn with (Slides maps deck fonts registered at runtime; default:
/// the bundled UI fonts, [chartDefaultFamily]). Pass the same measurer to
/// [paintChartScene] as to the layout.
class FlutterTextMeasurer implements TextMeasurer {
  FlutterTextMeasurer({this.capacity = 2000, this.familyOf});

  /// Shared instance of the editor.
  static final FlutterTextMeasurer instance = FlutterTextMeasurer();

  final int capacity;

  /// Spec family → Flutter family (null = [chartDefaultFamily]).
  final String Function(String? family)? familyOf;

  /// Drops the cached painters (fonts were registered).
  void clear() {
    for (final tp in _cache.values) {
      tp.dispose();
    }
    _cache.clear();
  }

  final LinkedHashMap<(String, TextStyleSpec), TextPainter> _cache =
      LinkedHashMap();

  /// A laid-out painter for one line of [text].
  TextPainter painter(String text, TextStyleSpec style) {
    final key = (text, style);
    final hit = _cache.remove(key);
    if (hit != null) {
      _cache[key] = hit;
      return hit;
    }
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: chartTextStyle(style, familyOf: familyOf),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    _cache[key] = tp;
    if (_cache.length > capacity) {
      final old = _cache.keys.first;
      _cache.remove(old)?.dispose();
    }
    return tp;
  }

  @override
  TextMetrics measure(String text, TextStyleSpec style) {
    final tp = painter(text, style);
    final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    return TextMetrics(tp.width, tp.height, ascent);
  }
}

/// What [paintChartScene] paints with: text metrics and, for 3D charts, an
/// optional GPU backend.
class _Paint {
  _Paint(this.text, this.scene, this.gpu, this.gpuKey, this.pixelRatio);

  final FlutterTextMeasurer text;
  final ChartScene scene;
  final Chart3DGpuRenderer? gpu;
  final Object? gpuKey;
  final double pixelRatio;
}

/// Paints a [ChartScene] (08 §6.3 painting contract) on a Flutter canvas.
/// Coordinates are scene px; scale the canvas for zoom. The geometry of a 3D
/// chart is drawn by [gpu] when given (identified by [gpuKey], rendered at
/// [pixelRatio] physical px per scene px), else by its software rendering.
void paintChartScene(
  Canvas canvas,
  ChartScene scene, {
  FlutterTextMeasurer? text,
  Chart3DGpuRenderer? gpu,
  Object? gpuKey,
  double pixelRatio = 1,
}) {
  final t = text ?? FlutterTextMeasurer.instance;
  if (RenderGeometry.fillVisible(scene.background)) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, scene.width, scene.height),
      Paint()..color = Color(scene.background),
    );
  }
  _paintList(
    canvas,
    scene.primitives,
    _Paint(t, scene, gpuKey == null ? null : gpu, gpuKey, pixelRatio),
  );
}

void _paintList(Canvas canvas, List<ScenePrimitive> list, _Paint t) {
  for (final p in list) {
    _paint(canvas, p, t);
  }
}

Rect _rect(ChartRect r) => Rect.fromLTWH(r.left, r.top, r.width, r.height);

Paint _fill(int argb) => Paint()
  ..color = Color(argb)
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

Paint _stroke(SStroke s) => Paint()
  ..color = Color(s.color)
  ..style = PaintingStyle.stroke
  ..strokeWidth = s.width
  ..strokeMiterLimit = RenderGeometry.miterLimit
  ..strokeCap = switch (s.cap) {
    SStrokeCap.butt => StrokeCap.butt,
    SStrokeCap.round => StrokeCap.round,
    SStrokeCap.square => StrokeCap.square,
  }
  ..strokeJoin = switch (s.join) {
    SStrokeJoin.miter => StrokeJoin.miter,
    SStrokeJoin.round => StrokeJoin.round,
    SStrokeJoin.bevel => StrokeJoin.bevel,
  }
  ..isAntiAlias = true;

Path _path(List<PathCmd> cmds, {bool evenOdd = false}) {
  final path = Path()
    ..fillType = evenOdd ? PathFillType.evenOdd : PathFillType.nonZero;
  for (final c in RenderGeometry.finiteCommands(cmds)) {
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
}

/// [path] cut into dashes of [pattern] (on, off, …).
Path _dashed(Path path, List<double> pattern) {
  final out = Path();
  for (final m in path.computeMetrics()) {
    var d = 0.0;
    var i = 0;
    var on = true;
    while (d < m.length) {
      final len = pattern[i % pattern.length];
      final next = math.min(m.length, d + len);
      if (on && next > d) out.addPath(m.extractPath(d, next), Offset.zero);
      d = next;
      on = !on;
      i++;
      if (len <= 0 && i > pattern.length * 2) break;
    }
  }
  return out;
}

void _strokePath(Canvas canvas, Path path, SStroke? s) {
  if (!RenderGeometry.strokeVisible(s)) return;
  final dash = RenderGeometry.effectiveDash(s!.dash);
  canvas.drawPath(dash == null ? path : _dashed(path, dash), _stroke(s));
}

void _paint(Canvas canvas, ScenePrimitive p, _Paint t) {
  switch (p) {
    case SRect(:final rect, :final fill, :final stroke, :final radius):
      if (!RenderGeometry.rectFinite(rect)) return;
      final r = _rect(RenderGeometry.normalize(rect));
      final rr = RenderGeometry.clampRadius(rect, radius);
      if (RenderGeometry.fillVisible(fill)) {
        if (rr > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, Radius.circular(rr)),
            _fill(fill!),
          );
        } else {
          canvas.drawRect(r, _fill(fill!));
        }
      }
      if (RenderGeometry.strokeVisible(stroke)) {
        final path = Path();
        if (rr > 0) {
          path.addRRect(RRect.fromRectAndRadius(r, Radius.circular(rr)));
        } else {
          path.addRect(r);
        }
        _strokePath(canvas, path, stroke);
      }
    case SPath(
      :final cmds,
      :final fill,
      :final stroke,
      :final evenOdd,
      :final gradient,
    ):
      final path = _path(cmds, evenOdd: evenOdd);
      if (RenderGeometry.fillVisible(fill)) {
        final paint = _fill(fill!);
        if (gradient != null) {
          paint.shader = ui.Gradient.linear(
            Offset(gradient.x0, gradient.y0),
            Offset(gradient.x1, gradient.y1),
            [Color(gradient.color0), Color(gradient.color1)],
          );
        }
        canvas.drawPath(path, paint);
      }
      _strokePath(canvas, path, stroke);
    case SPolyline(:final xy, :final stroke):
      if (!RenderGeometry.strokeVisible(stroke)) return;
      final path = Path();
      for (final run in RenderGeometry.finiteRuns(xy)) {
        if (run.length < 4) continue;
        path.moveTo(run[0], run[1]);
        for (var i = 2; i + 1 < run.length; i += 2) {
          path.lineTo(run[i], run[i + 1]);
        }
      }
      _strokePath(canvas, path, stroke);
    case SMarkers(:final xy, :final shape, :final stroke):
      _markers(canvas, p, xy, shape, stroke);
    case SArc(:final fill, :final stroke):
      final hollowFull = p.isFullCircle && p.innerRadius > 0;
      final path = _path(p.toPath(), evenOdd: hollowFull);
      if (RenderGeometry.fillVisible(fill)) canvas.drawPath(path, _fill(fill!));
      _strokePath(canvas, path, stroke);
    case SText():
      _text(canvas, p, t.text);
    case SClip(:final rect, :final children):
      canvas.save();
      canvas.clipRect(_rect(rect));
      _paintList(canvas, children, t);
      canvas.restore();
    case SGroup(:final tag)
        when tag?.detail == ChartScene.chart3dGroupDetail &&
            t.gpu != null &&
            t.scene.threeD != null &&
            t.gpu!.paint(
              canvas,
              t.scene.threeD!,
              key: t.gpuKey!,
              pixelRatio: t.pixelRatio,
            ):
      // Drawn by the GPU backend.
      return;
    case SGroup(:final children, :final opacity):
      if (opacity <= 0) return;
      if (opacity < 1) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, opacity.clamp(0.0, 1.0)),
        );
        _paintList(canvas, children, t);
        canvas.restore();
      } else {
        _paintList(canvas, children, t);
      }
  }
}

void _markers(
  Canvas canvas,
  SMarkers m,
  Float64List xy,
  MarkerShape shape,
  SStroke? stroke,
) {
  final strokePaint = RenderGeometry.strokeVisible(stroke)
      ? _stroke(stroke!)
      : null;
  final fills = <int, Paint>{};
  for (var k = 0; k < m.length; k++) {
    final x = xy[2 * k], y = xy[2 * k + 1];
    if (!x.isFinite || !y.isFinite) continue;
    final size = m.sizeOf(k);
    if (!(size > 0)) continue;
    final fill = m.fillOf(k);
    final fp = RenderGeometry.fillVisible(fill)
        ? fills.putIfAbsent(fill, () => _fill(fill))
        : null;
    if (shape == MarkerShape.circle) {
      if (fp != null) canvas.drawCircle(Offset(x, y), size / 2, fp);
      if (strokePaint != null) {
        canvas.drawCircle(Offset(x, y), size / 2, strokePaint);
      }
      continue;
    }
    final path = _path(RenderGeometry.markerPath(shape, x, y, size));
    if (fp != null) canvas.drawPath(path, fp);
    if (strokePaint != null) canvas.drawPath(path, strokePaint);
  }
}

void _text(Canvas canvas, SText s, FlutterTextMeasurer t) {
  if (s.text.isEmpty || !s.at.x.isFinite || !s.at.y.isFinite) return;
  final tp = t.painter(s.text, s.style);
  final ascent = tp.computeDistanceToActualBaseline(TextBaseline.alphabetic);
  final (dx, dy) = s.anchor.baselineOrigin(tp.width, tp.height, ascent);
  // Top-left of the text box relative to the anchor point.
  final origin = Offset(dx, dy - ascent);
  if (s.angle == 0) {
    tp.paint(canvas, Offset(s.at.x, s.at.y) + origin);
    return;
  }
  canvas.save();
  canvas.translate(s.at.x, s.at.y);
  canvas.rotate(s.angle);
  tp.paint(canvas, origin);
  canvas.restore();
}

/// Paints a scene laid out at logical size, scaled by [scale] (zoom), so
/// text and lines stay crisp at every zoom level (08 §9.1).
class ChartScenePainter extends CustomPainter {
  ChartScenePainter(
    this.scene, {
    this.scale = 1,
    this.gpu,
    this.gpuKey,
    this.devicePixelRatio = 1,
    this.text,
    super.repaint,
  });

  final ChartScene? scene;
  final double scale;

  /// Text metrics the scene was laid out with (null = the shared
  /// [FlutterTextMeasurer.instance]).
  final FlutterTextMeasurer? text;

  /// GPU backend for the geometry of 3D charts (null = software).
  final Chart3DGpuRenderer? gpu;

  /// Identity of the chart for the GPU backend's buffers.
  final Object? gpuKey;
  final double devicePixelRatio;

  /// Recorded pictures of 2D scenes (08 §12 raster cache): repaints of an
  /// unchanged chart (hover tooltips, selection frames, zoom-independent
  /// repaints) replay the picture instead of walking the scene again, which
  /// matters for charts with many points. Kept while the scene lives.
  static final Expando<ui.Picture> _pictures = Expando('chartScenePicture');

  /// How many times a scene was walked (tests, benchmarks).
  @visibleForTesting
  static int debugSceneWalks = 0;

  @override
  void paint(Canvas canvas, Size size) {
    final s = scene;
    if (s == null) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (scale != 1) canvas.scale(scale);
    if (s.threeD != null) {
      debugSceneWalks++;
      paintChartScene(
        canvas,
        s,
        text: text,
        gpu: gpu,
        gpuKey: gpuKey,
        pixelRatio: devicePixelRatio * scale,
      );
    } else {
      var picture = _pictures[s];
      if (picture == null) {
        debugSceneWalks++;
        final recorder = ui.PictureRecorder();
        paintChartScene(
          Canvas(recorder),
          s,
          text: text,
          pixelRatio: devicePixelRatio * scale,
        );
        picture = _pictures[s] = recorder.endRecording();
      }
      canvas.drawPicture(picture);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(ChartScenePainter old) =>
      !identical(old.scene, scene) ||
      old.scale != scale ||
      old.gpu != gpu ||
      !identical(old.text, text) ||
      old.devicePixelRatio != devicePixelRatio;
}

/// Renders [scene] to PNG bytes at [pixelRatio] (download, copy as image,
/// 08 §13).
Future<Uint8List?> chartSceneToPng(
  ChartScene scene, {
  double pixelRatio = 2,
  FlutterTextMeasurer? text,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.scale(pixelRatio);
  paintChartScene(canvas, scene, text: text);
  final picture = recorder.endRecording();
  final w = math.max(1, (scene.width * pixelRatio).ceil());
  final h = math.max(1, (scene.height * pixelRatio).ceil());
  final image = await picture.toImage(w, h);
  picture.dispose();
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
