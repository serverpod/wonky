part of 'ui_sheets_tools.dart';

/// `ui.sheets.screenshot_range` (Sheets 12 §5): renders a range like the grid,
/// with its objects, into a PNG.
abstract final class _UiSheetsScreenshot {
  static const _maxPx = 4000.0;

  static Future<UiToolResult> screenshotRange(
    UiToolContext c,
    Map<String, Object?> a,
  ) async {
    final ed = UiSheetsToolHandlers._editor(c);
    final rr = UiSheetsToolHandlers._parse(ed, a['range']! as String);
    final rect = UiSheetsToolHandlers._clip(ed, rr);
    final sheet = ed.model.sheet(rr.sheetId)!;
    final headers = a['include_headers'] == true;
    final scale = ((a['scale'] as num?) ?? 1).toDouble();
    final ctx = c.context;
    final live = ctx != null && ctx.mounted;
    final image = await renderRange(
      ed,
      sheet,
      rect,
      scale: scale,
      includeHeaders: headers,
      chartTokens: live ? chartUiTokensOf(ctx) : null,
      dark: live
          ? chartDarkOf(ctx)
          : WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark,
      tokens: switch (c.context) {
        final BuildContext ctx when ctx.mounted => GridPaintTokens.ofContext(
          ctx,
        ),
        _ => GridPaintTokens.of(
          WidgetsBinding.instance.platformDispatcher.platformBrightness,
        ),
      },
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final w = image.width;
    final h = image.height;
    image.dispose();
    if (bytes == null) {
      throw const UiToolException('failed', 'Could not encode the image.');
    }
    UiSheetsToolHandlers._flash(
      c,
      ed,
      rr,
      duration: const Duration(seconds: 2),
    );
    return UiToolResult(
      {'range': UiSheetsToolHandlers._rangeA1(ed, rr), 'width': w, 'height': h},
      text: 'Screenshot of ${UiSheetsToolHandlers._rangeA1(ed, rr)} ($w×$h)',
      imageBase64: base64Encode(bytes.buffer.asUint8List()),
    );
  }

  /// Paints [rect] of [sheet] offscreen with the grid's content layers
  /// (cells, formats, conditional formatting, borders) and the objects over
  /// it (charts through the chart painter, loaded images), independent of
  /// the scroll position; with [includeHeaders], row and column headers too.
  static Future<ui.Image> renderRange(
    SheetEditorController ed,
    SheetModel sheet,
    GridRect rect, {
    required GridPaintTokens tokens,
    double scale = 1,
    bool includeHeaders = false,
    ChartUiTokens? chartTokens,
    bool dark = false,
  }) async {
    final rows = sheet.rows;
    final cols = sheet.columns;
    final w = cols.offsetOf(rect.right + 1) - cols.offsetOf(rect.left);
    final h = rows.offsetOf(rect.bottom + 1) - rows.offsetOf(rect.top);
    if (w <= 0 || h <= 0) {
      throw const UiToolException('invalid_range', 'The range has no size.');
    }
    final frozenRows = sheet.record?.frozenRows ?? 0;
    final frozenCols = sheet.record?.frozenColumns ?? 0;
    // Scroll so that the range starts at the main pane's origin (or keep
    // 0 when it starts inside the frozen panes, which then show it).
    final scrollX = rect.left < frozenCols
        ? 0.0
        : cols.offsetOf(rect.left) - cols.offsetOf(frozenCols);
    final scrollY = rect.top < frozenRows
        ? 0.0
        : rows.offsetOf(rect.top) - rows.offsetOf(frozenRows);
    final probe = GridGeometry(
      sheet: sheet,
      size: const Size(1, 1),
      zoom: 1,
      scrollX: scrollX,
      scrollY: scrollY,
      devicePixelRatio: scale,
    );
    final cropLeft = rect.left < frozenCols
        ? probe.rowHeaderWidth + cols.offsetOf(rect.left)
        : probe.rowHeaderWidth + probe.frozenWidth;
    final cropTop = rect.top < frozenRows
        ? probe.colHeaderHeight + rows.offsetOf(rect.top)
        : probe.colHeaderHeight + probe.frozenHeight;
    final full = Size(cropLeft + w + 1, cropTop + h + 1);
    final g = GridGeometry(
      sheet: sheet,
      size: full,
      zoom: 1,
      scrollX: scrollX,
      scrollY: scrollY,
      devicePixelRatio: scale,
    );
    final hw = includeHeaders ? g.rowHeaderWidth : 0.0;
    final hh = includeHeaders ? g.colHeaderHeight : 0.0;
    final outW = w + hw;
    final outH = h + hh;
    final fit = math.min(1.0, _maxPx / math.max(outW * scale, outH * scale));
    final pr = scale * fit;
    if (pr < 0.1) {
      throw const UiToolException(
        'limit_exceeded',
        'The range is too large for a screenshot (max 4,000 × 4,000 px).',
      );
    }
    final layers = <GridLayer>[
      ...coreContentLayers(),
      ...ed.layers.content,
      if (includeHeaders) const HeaderLayer(),
    ]..sort((x, y) => x.zOrder.compareTo(y.zOrder));
    final ctx = GridPaintContext(controller: ed, geometry: g, tokens: tokens);

    // The whole frame, then the cropped pieces.
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec);
    canvas.clipRect(Offset.zero & full);
    for (final l in layers) {
      l.paint(ctx, canvas);
    }
    _paintObjects(
      ed,
      sheet,
      canvas,
      g,
      scrollX: scrollX,
      scrollY: scrollY,
      chartTokens:
          chartTokens ??
          ChartUiTokens(
            card: tokens.sheetBackground.toARGB32(),
            foreground: tokens.autoText.toARGB32(),
            border: tokens.gridLine.toARGB32(),
          ),
      dark: dark,
    );
    final frame = rec.endRecording();

    final out = ui.PictureRecorder();
    final oc = Canvas(out);
    oc.scale(pr);
    void piece(Rect src, Offset dst) {
      oc.save();
      oc.translate(dst.dx - src.left, dst.dy - src.top);
      oc.clipRect(src);
      oc.drawPicture(frame);
      oc.restore();
    }

    final cells = Rect.fromLTWH(cropLeft, cropTop, w, h);
    if (includeHeaders) {
      piece(Rect.fromLTWH(0, 0, hw, hh), Offset.zero);
      piece(Rect.fromLTWH(cropLeft, 0, w, hh), Offset(hw, 0));
      piece(Rect.fromLTWH(0, cropTop, hw, h), Offset(0, hh));
    }
    piece(cells, Offset(hw, hh));
    final picture = out.endRecording();
    final image = await picture.toImage(
      math.max(1, (outW * pr).ceil()),
      math.max(1, (outH * pr).ceil()),
    );
    picture.dispose();
    frame.dispose();
    return image;
  }

  /// Paints the charts and images of [sheet] into the offscreen grid frame
  /// of [g] (objects are widgets on screen, 08 §9).
  static void _paintObjects(
    SheetEditorController ed,
    SheetModel sheet,
    Canvas canvas,
    GridGeometry g, {
    required double scrollX,
    required double scrollY,
    required ChartUiTokens chartTokens,
    required bool dark,
  }) {
    final objects = ObjectsController.maybeOf(ed);
    if (objects == null) return;
    final frozenX = sheet.columns.offsetOf(sheet.record?.frozenColumns ?? 0);
    final frozenY = sheet.rows.offsetOf(sheet.record?.frozenRows ?? 0);
    for (final o in objects.objectsOn(sheet.id)) {
      final r = objects.rectOf(o, ghost: false);
      if (r == null || r.width <= 0 || r.height <= 0) continue;
      final x = g.rowHeaderWidth + r.left - (r.left >= frozenX ? scrollX : 0);
      final y = g.colHeaderHeight + r.top - (r.top >= frozenY ? scrollY : 0);
      final box = Rect.fromLTWH(x, y, r.width, r.height);
      canvas.save();
      canvas.clipRect(box);
      try {
        switch (o.kind) {
          case EmbeddedObjectKind.chart:
            final scene = objects
                .chartOf(o)
                .sceneFor(r.width, r.height, dark: dark, tokens: chartTokens);
            canvas.translate(x, y);
            paintChartScene(canvas, scene);
          case EmbeddedObjectKind.image:
            final spec = ImageSpec.fromJson(o.specJson);
            final src = spec.fileUuid.isNotEmpty
                ? spec.fileUuid
                : (spec.sourceUrl ?? '');
            final img = src.isEmpty
                ? null
                : SheetsImageService.of(ed).decoded(src);
            if (img != null) {
              paintImage(
                canvas: canvas,
                rect: box,
                image: img,
                fit: boxFitOf(spec.fit),
                filterQuality: FilterQuality.medium,
              );
            } else {
              canvas.drawRect(
                box,
                Paint()
                  ..color = Color(chartTokens.border).withValues(alpha: 0.4),
              );
            }
          default:
            break;
        }
      } on Object catch (e) {
        debugPrint('Screenshot: painting object ${o.id} failed: $e');
      }
      canvas.restore();
    }
  }
}
