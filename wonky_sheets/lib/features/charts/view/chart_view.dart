import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_charts_flutter/wonky_charts_flutter.dart';

import '../../../l10n/sheets_l10n.dart';
import '../../formatting/sheets_user_defaults.dart';
import '../../objects/objects_controller.dart';
import '../controller/chart_controller.dart';

/// When dragging a 3D chart orbits it (08 §23.6).
enum ChartOrbitMode {
  /// Only once the chart object is selected (over cells; a drag on an
  /// unselected chart moves it).
  whenSelected,

  /// Always (chart sheets).
  always,

  /// Never (thumbnails, previews).
  never,
}

/// A chart over the grid or on a chart sheet (08 §6.5, §9.1): the cached
/// scene laid out at the logical size and painted scaled by [zoom]; hover
/// shows the nearest point's value, a click on a legend entry highlights
/// that series.
class ChartObjectView extends StatefulWidget {
  const ChartObjectView({
    super.key,
    required this.controller,
    required this.width,
    required this.height,
    this.zoom = 1,
    this.interactive = true,
    this.orbit = ChartOrbitMode.whenSelected,
  });

  final ChartController controller;

  /// Logical size (100 % zoom).
  final double width;
  final double height;
  final double zoom;
  final bool interactive;
  final ChartOrbitMode orbit;

  @override
  State<ChartObjectView> createState() => _ChartObjectViewState();
}

class _ChartObjectViewState extends State<ChartObjectView>
    with TickerProviderStateMixin {
  /// The tooltip's target and position: its own listenable, so pointer
  /// moves rebuild only the tooltip, never the chart (CQ-47).
  final ValueNotifier<(SceneHit, Offset)?> _hover = ValueNotifier(null);
  Offset? _down;
  bool _overPlot = false;
  int? _orbitPointer;
  final VelocityTracker _velocity = VelocityTracker.withKind(
    PointerDeviceKind.mouse,
  );
  late final AnimationController _transition = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  )..addListener(() => c.transition3D = _transition.value);
  late final ChartOrbitGesture _orbit = ChartOrbitGesture(
    vsync: this,
    onChanged: (a, e) => c.setOrbit(a, e),
    onEnd: _commitOrbit,
  );

  ChartController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    _listen(c);
    Chart3DBackends.gpu.addListener(_changed);
  }

  void _listen(ChartController ctl) {
    ctl.addListener(_changed);
    ctl.transitionRequests.addListener(_startTransition);
  }

  void _unlisten(ChartController ctl) {
    ctl.removeListener(_changed);
    ctl.transitionRequests.removeListener(_startTransition);
  }

  @override
  void didUpdateWidget(ChartObjectView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      _unlisten(old.controller);
      _listen(widget.controller);
    }
  }

  @override
  void dispose() {
    _unlisten(c);
    Chart3DBackends.gpu.removeListener(_changed);
    final p = _orbitPointer;
    if (p != null) ChartPointerClaims.release(p);
    _orbit.dispose();
    _transition.dispose();
    _hover.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _reduceMotion {
    try {
      if (SheetsUserDefaults.of(c.editor.services).reduceAnimations) {
        return true;
      }
    } catch (_) {}
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _startTransition() {
    if (!mounted) return;
    if (_reduceMotion) {
      c.transition3D = 1;
      return;
    }
    _transition.forward(from: 0);
  }

  // ---------------------------------------------------------------------------
  // Orbit (08 §23.6).

  bool _canOrbit(ChartScene scene) {
    if (!widget.interactive || scene.threeD == null) return false;
    return switch (widget.orbit) {
      ChartOrbitMode.never => false,
      ChartOrbitMode.always => true,
      ChartOrbitMode.whenSelected =>
        ObjectsController.maybeOf(c.editor)?.isSelected(c.objectId) ?? false,
    };
  }

  bool _inPlot(ChartScene scene, Offset local) {
    final p = local / widget.zoom;
    final r = scene.plotArea ?? scene.threeD?.viewport;
    return r != null && r.contains(p.dx, p.dy);
  }

  void _orbitDown(PointerDownEvent e, ChartScene scene) {
    if (e.buttons != kPrimaryMouseButton ||
        !_canOrbit(scene) ||
        !_inPlot(scene, e.localPosition)) {
      return;
    }
    ChartPointerClaims.claim(e.pointer);
    _orbitPointer = e.pointer;
    final cam = scene.threeD!.camera;
    _velocity.addPosition(e.timeStamp, e.localPosition);
    _orbit.start(e.localPosition, cam.azimuth, cam.elevation);
  }

  void _commitOrbit(double azimuth, double elevation) {
    if (!mounted) return;
    final az = (ChartThreeD.normalizeAzimuth(azimuth) * 10).round() / 10;
    final el = (elevation * 10).round() / 10;
    if (!c.editor.canEdit || c.spec.isFromNewerVersion) {
      // Viewers look around without changing the chart.
      c.setOrbit(az, el);
      return;
    }
    c.setOrbit(az, el);
    c.endOrbit(committed: true);
    c.editor
        .invokeCommand('sheets.chart.update', {
          'objectId': c.objectId,
          'patch': {
            'threeD': {'azimuth': az, 'elevation': el},
          },
        })
        .then((ok) {
          if (!ok) c.endOrbit();
        });
  }

  ChartScene _scene(BuildContext context) => c.sceneFor(
    widget.width,
    widget.height,
    dark: chartDarkOf(context),
    tokens: chartUiTokensOf(context),
  );

  void _onHover(PointerHoverEvent e, ChartScene scene) {
    final p = e.localPosition / widget.zoom;
    final over = _canOrbit(scene) && _inPlot(scene, e.localPosition);
    if (over != _overPlot) setState(() => _overPlot = over);
    final s3 = scene.threeD;
    final picked = s3?.pick(p.dx, p.dy);
    // The 3D item under the pointer lights up (both backends, 08 §23.6).
    if (s3 != null && !_orbit.active) c.hover3D = picked?.tag;
    final hit = s3 != null
        ? (picked == null ? null : SceneHit(picked.tag, const SGroup([]), 0))
        : scene.hitTest(p.dx, p.dy);
    final next = chartTooltipApplies(hit?.tag) ? hit : null;
    _hover.value = next == null ? null : (next, e.localPosition);
  }

  void _onUp(PointerUpEvent e, ChartScene scene) {
    final orbiting = _orbitPointer == e.pointer;
    if (orbiting) {
      _orbitPointer = null;
      ChartPointerClaims.release(e.pointer);
      final moved = _orbit.moved;
      _orbit.end(_velocity.getVelocity().pixelsPerSecond / widget.zoom);
      if (moved) {
        _down = null;
        return;
      }
    }
    final d = _down;
    _down = null;
    if (d == null || (e.localPosition - d).distance > 3) return;
    final p = e.localPosition / widget.zoom;
    final hit = scene.hitTest(p.dx, p.dy, tolerance: 2);
    if (hit?.tag.role == SceneRole.legendEntry) {
      final key = hit!.tag.seriesKey;
      c.highlight = c.highlight == key ? null : key;
    } else if (c.highlight != null &&
        (hit == null || hit.tag.role == SceneRole.background)) {
      c.highlight = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    c.animate3D = !_reduceMotion;
    final scene = _scene(context);
    if (scene.threeD != null) Chart3DBackends.ensureStarted();
    final w = widget.width * widget.zoom;
    final h = widget.height * widget.zoom;
    // Own layer: the tooltip above repaints alone (CQ-47).
    Widget paint = RepaintBoundary(
      child: CustomPaint(
        size: Size(w, h),
        painter: ChartScenePainter(
          scene,
          scale: widget.zoom,
          gpu: Chart3DBackends.active,
          gpuKey: c,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        ),
        isComplex: true,
        willChange: _orbit.active || _transition.isAnimating,
      ),
    );
    if (!widget.interactive) return paint;
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _down = e.localPosition;
        _orbitDown(e, scene);
      },
      onPointerMove: (e) {
        if (_orbitPointer != e.pointer) return;
        _velocity.addPosition(e.timeStamp, e.localPosition);
        _orbit.update(e.localPosition);
        _hover.value = null;
      },
      onPointerUp: (e) => _onUp(e, scene),
      onPointerCancel: (e) {
        if (_orbitPointer != e.pointer) return;
        _orbitPointer = null;
        ChartPointerClaims.release(e.pointer);
        _orbit.cancel();
        c.endOrbit();
      },
      child: MouseRegion(
        opaque: false,
        cursor: _overPlot
            ? (_orbit.active
                  ? SystemMouseCursors.grabbing
                  : SystemMouseCursors.grab)
            : MouseCursor.defer,
        onHover: (e) => _onHover(e, scene),
        onExit: (_) {
          c.hover3D = null;
          _hover.value = null;
          if (_overPlot) setState(() => _overPlot = false);
        },
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              paint,
              ValueListenableBuilder<(SceneHit, Offset)?>(
                valueListenable: _hover,
                builder: (context, hover, _) => hover == null
                    ? const SizedBox.shrink()
                    : ChartTooltip(
                        cardKey: const ValueKey<String>('sheets.chart.tooltip'),
                        at: hover.$2,
                        bounds: Size(w, h),
                        lines: chartTooltipLines(
                          c.data,
                          c.spec,
                          hover.$1.tag,
                          locale: c.editor.locale,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder of a chart written by a newer app version (08 §1.3).
class NewerVersionChartCard extends StatelessWidget {
  const NewerVersionChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = sheetsL10n(context);
    return Container(
      color: theme.colorScheme.card,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Text(
        l.chartNewerVersion,
        textAlign: TextAlign.center,
        style: theme.textTheme.muted,
      ),
    );
  }
}
