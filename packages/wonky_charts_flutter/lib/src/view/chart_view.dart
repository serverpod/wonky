import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_charts/wonky_charts.dart';

import '../render/chart_painter.dart';
import '../three_d/chart3d_gpu.dart';
import 'chart_tooltip.dart';

/// A chart laid out at the widget's size and painted (Slides 08 §2.2, the
/// generic part of Sheets' chart view): input is a [ChartSpec], its
/// [ChartData] and a [ChartTheme]; no app controller. Hover shows the
/// nearest point's value ([tooltips]); a click on a legend entry highlights
/// that series ([legendHighlight]). 3D charts draw with the GPU backend
/// when [gpuKey] is given and the backend is ready (software otherwise).
///
/// Used for previews (Slides' insert dialog tiles, 200 × 124 px) and for
/// interactive charts outside a grid (Slides present mode with
/// `interactive.hoverTooltips`).
class ChartView extends StatefulWidget {
  const ChartView({
    super.key,
    required this.spec,
    required this.data,
    required this.theme,
    this.locale = 'en_US',
    this.text,
    this.tooltips = false,
    this.legendHighlight = false,
    this.gpuKey,
    this.view,
    this.reveal,
    this.semanticLabel,
  });

  final ChartSpec spec;
  final ChartData data;
  final ChartTheme theme;

  /// Number and date formats of labels, ticks and tooltips.
  final String locale;

  /// Text metrics (null = [FlutterTextMeasurer.instance]).
  final FlutterTextMeasurer? text;

  /// Whether hovering a data point shows its value.
  final bool tooltips;

  /// Whether a click on a legend entry highlights its series.
  final bool legendHighlight;

  /// Identity of the chart for the 3D GPU backend (null = software).
  final Object? gpuKey;

  /// 3D camera (null = the spec's view).
  final Chart3DView? view;

  /// Build state (null = fully built).
  final ChartReveal? reveal;

  /// Semantics label (e.g. the chart description).
  final String? semanticLabel;

  @override
  State<ChartView> createState() => _ChartViewState();
}

class _ChartViewState extends State<ChartView> {
  String? _highlight;

  /// The tooltip's target and position: its own listenable, so pointer
  /// moves rebuild only the tooltip, never the chart (CQ-47).
  final ValueNotifier<(SceneHit, Offset)?> _hover = ValueNotifier(null);
  ChartScene? _scene;
  Object? _sceneKey;

  @override
  void initState() {
    super.initState();
    Chart3DBackends.gpu.addListener(_changed);
  }

  @override
  void dispose() {
    Chart3DBackends.gpu.removeListener(_changed);
    _hover.dispose();
    final k = widget.gpuKey;
    if (k != null) Chart3DBackends.gpu.value?.release(k);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  ChartScene _layout(Size size) {
    final w = widget;
    // Compared with ==, not by hash (a collision would show a stale scene).
    final key = (
      w.spec,
      w.data,
      w.theme,
      w.locale,
      size,
      _highlight,
      w.view,
      w.reveal,
    );
    final cached = _scene;
    if (cached != null && key == _sceneKey) return cached;
    final v = w.view?.normalized;
    final scene = ChartPipeline.layout(
      w.spec,
      w.data,
      size: ChartSize(size.width, size.height),
      theme: w.theme,
      measurer: w.text ?? FlutterTextMeasurer.instance,
      locale: w.locale,
      options: ChartLayoutOptions(
        highlightSeriesKey: _highlight,
        azimuth3D: v?.azimuth,
        elevation3D: v?.elevation,
        perspective3D: v?.perspective,
      ),
      reveal: w.reveal,
    ).scene;
    _sceneKey = key;
    return _scene = scene;
  }

  void _onHover(PointerHoverEvent e, ChartScene scene) {
    if (!widget.tooltips) return;
    final p = e.localPosition;
    final s3 = scene.threeD;
    SceneHit? hit;
    if (s3 != null) {
      final picked = s3.pick(p.dx, p.dy);
      hit = picked == null ? null : SceneHit(picked.tag, const SGroup([]), 0);
    } else {
      hit = scene.hitTest(p.dx, p.dy);
    }
    final next = chartTooltipApplies(hit?.tag) ? hit : null;
    _hover.value = next == null ? null : (next, p);
  }

  void _onTap(Offset p, ChartScene scene) {
    if (!widget.legendHighlight) return;
    final hit = scene.hitTest(p.dx, p.dy, tolerance: 2);
    if (hit?.tag.role == SceneRole.legendEntry) {
      final key = hit!.tag.seriesKey;
      setState(() => _highlight = _highlight == key ? null : key);
    } else if (_highlight != null &&
        (hit == null || hit.tag.role == SceneRole.background)) {
      setState(() => _highlight = null);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final size = Size(
        c.maxWidth.isFinite ? c.maxWidth : 400,
        c.maxHeight.isFinite ? c.maxHeight : 248,
      );
      final scene = _layout(size);
      if (scene.threeD != null && widget.gpuKey != null) {
        Chart3DBackends.ensureStarted();
      }
      // Own layer: the tooltip above repaints alone (CQ-47).
      Widget paint = RepaintBoundary(
        child: CustomPaint(
          size: size,
          isComplex: true,
          painter: ChartScenePainter(
            scene,
            text: widget.text,
            gpu: widget.gpuKey == null ? null : Chart3DBackends.active,
            gpuKey: widget.gpuKey,
            devicePixelRatio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
          ),
        ),
      );
      if (widget.semanticLabel != null) {
        paint = Semantics(
          image: true,
          label: widget.semanticLabel,
          child: paint,
        );
      }
      if (!widget.tooltips && !widget.legendHighlight) return paint;
      return MouseRegion(
        opaque: false,
        onHover: (e) => _onHover(e, scene),
        onExit: (_) => _hover.value = null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: (d) => _onTap(d.localPosition, scene),
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                paint,
                ValueListenableBuilder<(SceneHit, Offset)?>(
                  valueListenable: _hover,
                  builder: (context, hover, _) => hover == null
                      ? const SizedBox.shrink()
                      : ChartTooltip(
                          at: hover.$2,
                          bounds: size,
                          lines: chartTooltipLines(
                            widget.data,
                            widget.spec,
                            hover.$1.tag,
                            locale: widget.locale,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
