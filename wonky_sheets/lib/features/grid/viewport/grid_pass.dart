import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../../theme/sheets_tokens.dart';
import '../../sheet_editor/sheet_editor_controller.dart';
import '../paint/grid_layer.dart';

/// One paint pass of the grid (03 §2.2): `content` paints the static layers
/// (cells, borders …), `overlay` the dynamic ones (selection, headers …).
/// No widget per cell: a leaf render object paints the visible window.
class GridPass extends LeafRenderObjectWidget {
  const GridPass({
    super.key,
    required this.controller,
    required this.tokens,
    required this.overlay,
    required this.layers,
    required this.repaint,
  });

  final SheetEditorController controller;
  final GridPaintTokens tokens;
  final bool overlay;
  final List<GridLayer> layers;
  final Listenable repaint;

  @override
  RenderGridPass createRenderObject(BuildContext context) => RenderGridPass(
    controller: controller,
    tokens: tokens,
    overlay: overlay,
    layers: layers,
    repaint: repaint,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderGridPass renderObject) {
    renderObject
      ..controller = controller
      ..tokens = tokens
      ..layers = layers
      ..repaint = repaint
      ..devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
  }
}

class RenderGridPass extends RenderBox {
  RenderGridPass({
    required this._controller,
    required this._tokens,
    required this.overlay,
    required this._layers,
    required this._repaint,
    required double devicePixelRatio,
  }) : _dpr = devicePixelRatio;

  final bool overlay;

  SheetEditorController _controller;
  set controller(SheetEditorController v) {
    if (v == _controller) return;
    _controller = v;
    markNeedsLayout();
    markNeedsPaint();
  }

  GridPaintTokens _tokens;
  set tokens(GridPaintTokens v) {
    if (v == _tokens) return;
    _tokens = v;
    markNeedsPaint();
  }

  List<GridLayer> _layers;
  set layers(List<GridLayer> v) {
    if (listEquals(v, _layers)) return;
    _layers = v;
    markNeedsPaint();
  }

  Listenable _repaint;
  set repaint(Listenable v) {
    if (v == _repaint) return;
    if (attached) {
      _repaint.removeListener(markNeedsPaint);
      v.addListener(markNeedsPaint);
    }
    _repaint = v;
    markNeedsPaint();
  }

  double _dpr;
  set devicePixelRatio(double v) {
    if (v == _dpr) return;
    _dpr = v;
    markNeedsLayout();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void performLayout() {
    // The viewport of the shared geometry (S-06): widgets and both passes
    // read `controller.geometry`; nothing is written during paint.
    if (overlay) _controller.setViewport(size, _dpr);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final g = _controller.geometryFor(size, _dpr);
    if (g == null) return;
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.clipRect(Offset.zero & size);
    final ctx = GridPaintContext(
      controller: _controller,
      geometry: g,
      tokens: _tokens,
    );
    for (final l in _layers) {
      l.paint(ctx, canvas);
    }
    canvas.restore();
  }
}
