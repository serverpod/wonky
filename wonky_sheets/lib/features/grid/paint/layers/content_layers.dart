import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart' hide BorderStyle;
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../../../../theme/sheets_tokens.dart';
import '../../../conditional_format/cf_paint.dart';
import '../../../formatting/cell_fonts.dart';
import '../../../formatting/rich_text_paint.dart';
import '../../viewport/grid_geometry.dart';
import '../auto_text.dart';
import '../grid_layer.dart';
import '../text_layout_cache.dart';
import '../../../in_cell/in_cell_paint.dart';

/// Points → logical px of cell fonts (10 pt ≈ 13.3 px at 100 %).
const double kPointToPx = 4 / 3;

/// Horizontal / vertical text padding at 100 % (03 §2.6).
const double kCellPadH = 3;
const double kCellPadV = 2;

/// How far left/right of the window text may overflow from (03 §2.6).
const int kOverflowMargin = 50;

Color _hex(String? hex, Color fallback) => hexToColor(hex) ?? fallback;

/// Layer 1: the sheet background.
class BackgroundLayer extends GridLayer {
  const BackgroundLayer();

  @override
  int get zOrder => GridZ.background;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    canvas.drawRect(
      ctx.geometry.cellsRect,
      Paint()..color = ctx.tokens.sheetBackground,
    );
  }
}

/// Layer 3: gridlines (skipped when the sheet hides them).
class GridlineLayer extends GridLayer {
  const GridlineLayer();

  @override
  int get zOrder => GridZ.gridlines;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    if (!(ctx.sheet.record?.showGridlines ?? true)) return;
    final g = ctx.geometry;
    final hair = g.hairline;
    final paint = Paint()..color = ctx.tokens.gridLine;
    ctx.forEachPane(canvas, (pane) {
      if (pane.isEmpty) return;
      final rows = ctx.sheet.rows;
      final cols = ctx.sheet.columns;
      final left = pane.rect.left;
      final right = math.min(pane.rect.right, pane.x(pane.colEnd + 1));
      final top = pane.rect.top;
      final bottom = math.min(
        pane.rect.bottom,
        pane.yDisplay(pane.displayRowEnd + 1),
      );
      // Rows in display order (a sorted filter view, 07 §4.4).
      for (final r in pane.rows) {
        if (rows.sizeAt(r) <= 0) continue;
        final y = pane.bottomOf(r) - hair;
        canvas.drawRect(Rect.fromLTRB(left, y, right, y + hair), paint);
      }
      for (var c = pane.colStart; c <= pane.colEnd; c++) {
        if (cols.sizeAt(c) <= 0) continue;
        final x = pane.x(c + 1) - hair;
        canvas.drawRect(Rect.fromLTRB(x, top, x + hair, bottom), paint);
      }
    });
  }
}

/// Layer 4: cell fills, merged areas and cell content (text with
/// overflow/wrap/clip, `####`, checkboxes, dropdown chips, links).
class CellContentLayer extends GridLayer {
  const CellContentLayer();

  @override
  int get zOrder => GridZ.cells;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    ctx.forEachPane(canvas, (pane) {
      if (pane.isEmpty) return;
      _paintPane(ctx, canvas, pane);
    });
  }

  void _paintPane(GridPaintContext ctx, Canvas canvas, GridPane pane) {
    final sheet = ctx.sheet;
    final sid = sheet.id;
    final rows = sheet.rows;
    final cols = sheet.columns;
    final cells = ctx.cells;
    final g = ctx.geometry;
    final hair = g.hairline;
    final window = GridRect(
      pane.rowStart,
      pane.colStart,
      pane.rowEnd,
      pane.colEnd,
    );
    final merges = sheet.merges.isEmpty
        ? const <(String, GridRect)>[]
        : sheet.mergesIntersecting(window);
    bool inMerge(int r, int c) {
      for (final (_, m) in merges) {
        if (m.contains(r, c)) return true;
      }
      return false;
    }

    // Fills.
    for (final r in pane.rows) {
      if (rows.sizeAt(r) <= 0) continue;
      for (var c = pane.colStart; c <= pane.colEnd; c++) {
        if (cols.sizeAt(c) <= 0) continue;
        final d = cells.displayAt(sid, r, c);
        final fill = d?.fillColor;
        if (fill != null) {
          canvas.drawRect(
            pane.cellRect(r, c),
            Paint()..color = _hex(fill, ctx.tokens.sheetBackground),
          );
        }
        // Conditional formatting data bars (06 §15.6) sit on the fill.
        final cf = d?.conditional;
        if (cf?.dataBarFraction != null) {
          CfDecorations.paintDataBar(
            canvas,
            pane.cellRect(r, c),
            cf!,
            g.zoom,
            axisColor: ctx.tokens.headerFg,
          );
        }
      }
    }
    // Merged areas hide their inner gridlines.
    for (final (_, m) in merges) {
      final d = cells.displayAt(sid, m.top, m.left);
      final rect = pane.rangeRect(m);
      canvas.drawRect(
        Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.right - hair,
          rect.bottom - hair,
        ),
        Paint()..color = _hex(d?.fillColor, ctx.tokens.sheetBackground),
      );
    }

    // Content.
    final showFormulas = ctx.controller.showFormulas;
    for (final r in pane.rows) {
      if (rows.sizeAt(r) <= 0) continue;
      final candidates = <int>{
        for (var c = pane.colStart; c <= pane.colEnd; c++) c,
      };
      // Text from outside the window may overflow into it.
      final rowId = rows.idAt(r);
      if (sheet.cells.rowCount(rowId) > 0) {
        final lo = math.max(pane.firstCol, pane.colStart - kOverflowMargin);
        final hi = math.min(pane.lastColLimit, pane.colEnd + kOverflowMargin);
        for (final cell in sheet.cells.inRow(rowId)) {
          if (cell.content == null) continue;
          final c = cols.indexOf(cell.columnId);
          if (c >= lo && c <= hi) candidates.add(c);
        }
      }
      for (final c in candidates) {
        if (cols.sizeAt(c) <= 0) continue;
        final d = cells.displayAt(sid, r, c);
        if (d == null) continue;
        GridRect? merge;
        if (merges.isNotEmpty && inMerge(r, c)) {
          merge = merges.firstWhere((m) => m.$2.contains(r, c)).$2;
          if (merge.top != r || merge.left != c) continue;
        }
        _paintCell(
          ctx,
          canvas,
          pane,
          r,
          c,
          d,
          merge: merge,
          showFormulas: showFormulas,
          inMerge: inMerge,
        );
      }
    }
    // Merges whose anchor row is above the window.
    for (final (_, m) in merges) {
      if (m.top >= pane.rowStart || m.left > pane.colEnd) continue;
      final d = cells.displayAt(sid, m.top, m.left);
      if (d == null) continue;
      _paintCell(
        ctx,
        canvas,
        pane,
        m.top,
        m.left,
        d,
        merge: m,
        showFormulas: showFormulas,
        inMerge: inMerge,
      );
    }
  }

  void _paintCell(
    GridPaintContext ctx,
    Canvas canvas,
    GridPane pane,
    int r,
    int c,
    CellDisplay d, {
    required GridRect? merge,
    required bool showFormulas,
    required bool Function(int, int) inMerge,
  }) {
    final g = ctx.geometry;
    final z = g.zoom;
    final cellRect = merge == null
        ? pane.cellRect(r, c)
        : pane.rangeRect(merge);
    if (cellRect.width <= 0 || cellRect.height <= 0) return;
    final f = d.format;
    final tokens = ctx.tokens;

    // Widgets.
    if (d.widget.kind == CellWidgetKind.checkbox) {
      _checkbox(canvas, cellRect, d, tokens, z);
      return;
    }

    var text = d.text;
    var align = d.hAlign;
    // Conditional formatting icon (06 §15.7) and "show value" off.
    final cfo = d.conditional;
    var iconW = 0.0;
    if (cfo != null && cfo.iconSet != null && cfo.iconIndex != null) {
      final s = math.min(CfDecorations.iconSize * z, cellRect.height - 2);
      if (s > 3) {
        final box = Rect.fromLTWH(
          cellRect.left + kCellPadH * z,
          switch (f.vAlign) {
            VerticalAlign.top => cellRect.top + kCellPadV * z,
            VerticalAlign.middle => cellRect.center.dy - s / 2,
            VerticalAlign.bottom => cellRect.bottom - kCellPadV * z - s,
          },
          s,
          s,
        );
        CfDecorations.paintIcon(canvas, box, cfo.iconSet!, cfo.iconIndex!);
        iconW = s + 2 * z;
      }
    }
    if (cfo != null && !cfo.showValue && !showFormulas) text = '';
    if (showFormulas) {
      final content = d.content;
      if (content is FormulaContent) {
        text = ctx.controller.editableText(r, c);
        align = HorizontalAlign.left;
      } else if (content is NumberContent) {
        text = CellContent.formatNumber(content.number);
      }
    }
    if (text.isEmpty) {
      if (d.widget.kind == CellWidgetKind.dropdownArrow ||
          d.widget.kind == CellWidgetKind.dropdownChip) {
        _dropdownArrow(canvas, cellRect, tokens, z);
      }
      return;
    }
    if (f.rotation == 255) text = text.characters.join('\n');

    // `#LOADING` (custom functions, AI cells, rows still streaming in) is
    // painted as a muted italic "Loading…" (05 §13.6, 09 §8.6).
    final loading =
        !showFormulas &&
        d.value is ErrorValue &&
        (d.value as ErrorValue).kind == CellErrorKind.loading;
    if (loading) text = ctx.controller.l10n.scriptLoadingCell;
    final linkColor = d.linkUrl != null && d.textColor == null
        ? tokens.linkText
        : null;
    final color = loading
        ? tokens.headerFg
        : linkColor ??
              hexToColor(d.textColor) ??
              autoTextOn(tokens, hexToColor(d.fillColor));
    final style = GridTextStyle(
      fontFamily: CellFonts.screenFamily(f.fontFamily),
      fontSize: f.fontSize * kPointToPx * z,
      color: color,
      bold: f.bold && !loading,
      italic: f.italic || loading,
      underline: d.underline,
      strikethrough: f.strikethrough,
      align: switch (align) {
        HorizontalAlign.center => TextAlign.center,
        HorizontalAlign.right => TextAlign.right,
        _ => TextAlign.left,
      },
    );
    // Dropdown chips (03 §14.2, `features/in_cell`).
    if (d.widget.kind == CellWidgetKind.dropdownChip && !showFormulas) {
      paintDropdownChip(ctx, canvas, cellRect, d, text, style);
      return;
    }
    final padH = kCellPadH * z;
    final padV = kCellPadV * z;
    final inner = cellRect.width - 2 * padH - iconW;
    final wrap = f.wrap == WrapStrategy.wrap;
    final rich = d.rich;
    final theme = rich == null ? null : ctx.model.theme;
    var p = rich != null && !showFormulas && f.rotation != 255
        ? richTextLayouts.layout(
            rich,
            style,
            pxPerPoint: kPointToPx * z,
            linkColor: tokens.linkText,
            resolveColor: theme!.resolveColor,
            theme: theme,
            conditional: cfo?.format,
            wrapWidth: wrap ? math.max(1, inner) : null,
            chipText: neutralChipColors(tokens).fg,
          )
        : ctx.text.layout(
            text,
            style,
            wrapWidth: wrap ? math.max(1, inner) : null,
          );
    // Numbers never overflow: `####`.
    if (!wrap && d.numberLike && !showFormulas && p.maxIntrinsicWidth > inner) {
      final hashes = ctx.text.layout('#', style);
      final n = math.max(
        1,
        (inner / math.max(1, hashes.maxIntrinsicWidth)).floor(),
      );
      p = ctx.text.layout('#' * n, style);
    }
    final width = wrap ? inner : p.maxIntrinsicWidth;
    final height = p.height;

    // Horizontal placement and overflow clip.
    var clipLeft = cellRect.left;
    var clipRight = cellRect.right;
    final overflowing =
        !wrap &&
        merge == null &&
        f.wrap == WrapStrategy.overflow &&
        width > inner &&
        f.rotation == 0;
    if (overflowing) {
      final sid = ctx.sheetId;
      final cols = ctx.sheet.columns;
      bool free(int col) =>
          col >= pane.firstCol &&
          col <= pane.lastColLimit &&
          !ctx.cells.hasContent(sid, r, col) &&
          !inMerge(r, col);
      final needRight = align == HorizontalAlign.center
          ? (width - inner) / 2
          : width - inner;
      if (align != HorizontalAlign.right) {
        var x = c + 1;
        while (clipRight < cellRect.right + needRight + padH &&
            x < cols.length &&
            free(x)) {
          clipRight = pane.x(x + 1);
          x++;
        }
      }
      if (align != HorizontalAlign.left) {
        var x = c - 1;
        final needLeft = align == HorizontalAlign.center
            ? needRight
            : width - inner;
        while (clipLeft > cellRect.left - needLeft - padH &&
            x >= 0 &&
            free(x)) {
          clipLeft = pane.x(x);
          x--;
        }
      }
    }
    final double dx = switch (align) {
      HorizontalAlign.center =>
        wrap
            ? cellRect.left + padH + iconW
            : cellRect.center.dx - width / 2 + iconW / 2,
      HorizontalAlign.right =>
        wrap ? cellRect.left + padH + iconW : cellRect.right - padH - width,
      _ => cellRect.left + padH + iconW,
    };
    final double dy = switch (f.vAlign) {
      VerticalAlign.top => cellRect.top + padV,
      VerticalAlign.middle => cellRect.center.dy - height / 2,
      VerticalAlign.bottom => cellRect.bottom - padV - height,
    };
    final rotation = f.rotation;
    final needsClip =
        dx < clipLeft ||
        dx + width > clipRight ||
        dy < cellRect.top ||
        dy + height > cellRect.bottom ||
        (rotation != 0 && rotation != 255);
    if (needsClip) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(clipLeft, cellRect.top, clipRight, cellRect.bottom),
      );
    }
    if (rotation != 0 && rotation != 255) {
      canvas.save();
      canvas.translate(cellRect.center.dx, cellRect.center.dy);
      canvas.rotate(-rotation * math.pi / 180);
      canvas.drawParagraph(p, Offset(-width / 2, -height / 2));
      canvas.restore();
    } else {
      // Smart chip runs (03 §14.3): pills behind, avatars/icons in front.
      paintRichChipsBehind(
        canvas,
        p,
        Offset(dx, dy),
        neutralChipColors(tokens).bg,
      );
      canvas.drawParagraph(p, Offset(dx, dy));
      paintRichChipsFront(canvas, p, Offset(dx, dy));
    }
    if (needsClip) canvas.restore();
    if (d.widget.kind == CellWidgetKind.dropdownArrow ||
        d.widget.kind == CellWidgetKind.dropdownChip) {
      _dropdownArrow(canvas, cellRect, tokens, z);
    }
  }

  static void _checkbox(
    Canvas canvas,
    Rect cell,
    CellDisplay d,
    GridPaintTokens tokens,
    double z,
  ) {
    final s = math.min(14 * z, cell.height - 4);
    if (s <= 2) return;
    final box = Rect.fromCenter(center: cell.center, width: s, height: s);
    final rr = RRect.fromRectAndRadius(box, Radius.circular(2 * z));
    final color = _hex(d.textColor, tokens.selectionBorder);
    if (d.widget.checked) {
      canvas.drawRRect(rr, Paint()..color = color);
      final path = Path()
        ..moveTo(box.left + s * 0.22, box.top + s * 0.52)
        ..lineTo(box.left + s * 0.42, box.top + s * 0.72)
        ..lineTo(box.left + s * 0.78, box.top + s * 0.3);
      canvas.drawPath(
        path,
        Paint()
          ..color = tokens.sheetBackground
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * z,
      );
    } else {
      canvas.drawRRect(
        rr.deflate(0.75),
        Paint()
          ..color = tokens.headerFg
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  static void _dropdownArrow(
    Canvas canvas,
    Rect cell,
    GridPaintTokens tokens,
    double z,
  ) {
    final cx = cell.right - 8 * z;
    final cy = cell.center.dy;
    final path = Path()
      ..moveTo(cx - 3.5 * z, cy - 1.5 * z)
      ..lineTo(cx + 3.5 * z, cy - 1.5 * z)
      ..lineTo(cx, cy + 2.5 * z)
      ..close();
    canvas.drawPath(path, Paint()..color = tokens.headerFg);
  }
}

/// Layer 5: resolved cell borders (06 §8).
class BorderLayer extends GridLayer {
  const BorderLayer();

  @override
  int get zOrder => GridZ.borders;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final sid = ctx.sheetId;
    if (!ctx.cells.sheetHasBorders(sid)) return;
    final rows = ctx.sheet.rows;
    final cols = ctx.sheet.columns;
    ctx.forEachPane(canvas, (pane) {
      if (pane.isEmpty) return;
      for (final r in pane.rows) {
        if (rows.sizeAt(r) <= 0) continue;
        for (var c = pane.colStart; c <= pane.colEnd; c++) {
          if (cols.sizeAt(c) <= 0) continue;
          final e = ctx.cells.edgesAt(sid, r, c);
          final rect = pane.cellRect(r, c);
          if (e.bottom != null) {
            _line(ctx, canvas, e.bottom!, rect.bottomLeft, rect.bottomRight);
          }
          if (e.right != null) {
            _line(ctx, canvas, e.right!, rect.topRight, rect.bottomRight);
          }
          if ((r == pane.firstShownRow || pane.isPermuted(r)) &&
              e.top != null) {
            _line(ctx, canvas, e.top!, rect.topLeft, rect.topRight);
          }
          if (c == pane.colStart && e.left != null) {
            _line(ctx, canvas, e.left!, rect.topLeft, rect.bottomLeft);
          }
        }
      }
    });
  }

  static void _line(
    GridPaintContext ctx,
    Canvas canvas,
    BorderSpec spec,
    Offset a,
    Offset b,
  ) {
    final style = spec.style;
    if (style == null) return;
    final g = ctx.geometry;
    final color = spec.color == 'auto'
        ? ctx.tokens.autoBorder
        : _hex(ctx.model.theme.resolveColor(spec.color), ctx.tokens.autoBorder);
    final w = math.max(
      g.hairline,
      g.snap(style.widthPx * math.min(1.5, g.zoom)),
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = w
      ..style = PaintingStyle.stroke;
    final horizontal = a.dy == b.dy;
    // Centre the stroke on the edge, inside the grid line position.
    final off = horizontal ? Offset(0, -w / 2) : Offset(-w / 2, 0);
    switch (style) {
      case BorderStyle.dashed || BorderStyle.dotted:
        final dash = style == BorderStyle.dashed ? 4.0 : 1.0;
        final gap = style == BorderStyle.dashed ? 3.0 : 2.0;
        final len = (b - a).distance;
        final dir = (b - a) / len;
        for (var t = 0.0; t < len; t += dash + gap) {
          canvas.drawLine(
            a + off + dir * t,
            a + off + dir * math.min(len, t + dash),
            paint,
          );
        }
      case BorderStyle.double:
        final thin = paint..strokeWidth = g.hairline;
        final d = horizontal ? Offset(0, w / 2) : Offset(w / 2, 0);
        canvas.drawLine(a + off - d, b + off - d, thin);
        canvas.drawLine(a + off + d, b + off + d, thin);
      default:
        canvas.drawLine(a + off, b + off, paint);
    }
  }
}

/// Layer 6: note / error triangles (03 §2.4).
class DecorationLayer extends GridLayer {
  const DecorationLayer();

  @override
  int get zOrder => GridZ.decorations;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final sid = ctx.sheetId;
    final rows = ctx.sheet.rows;
    final cols = ctx.sheet.columns;
    final z = ctx.zoom;
    ctx.forEachPane(canvas, (pane) {
      if (pane.isEmpty) return;
      for (final r in pane.rows) {
        if (rows.sizeAt(r) <= 0) continue;
        for (var c = pane.colStart; c <= pane.colEnd; c++) {
          final d = ctx.cells.displayAt(sid, r, c);
          if (d == null) continue;
          final note = d.record?.note != null;
          final value = d.value;
          final error =
              d.isFormula &&
              value is ErrorValue &&
              value.kind != CellErrorKind.loading &&
              (value.kind != CellErrorKind.na || value.message != null);
          if (!note && !error) continue;
          if (cols.sizeAt(c) <= 0) continue;
          final rect = pane.cellRect(r, c);
          final s = 6 * z;
          _triangle(
            canvas,
            rect.topRight,
            s,
            error ? ctx.tokens.errorTriangle : ctx.tokens.noteTriangle,
            right: true,
          );
        }
      }
    });
  }

  static void _triangle(
    Canvas canvas,
    Offset corner,
    double s,
    Color color, {
    required bool right,
  }) {
    final path = right
        ? (Path()
            ..moveTo(corner.dx - s, corner.dy)
            ..lineTo(corner.dx, corner.dy)
            ..lineTo(corner.dx, corner.dy + s)
            ..close())
        : (Path()
            ..moveTo(corner.dx, corner.dy)
            ..lineTo(corner.dx + s, corner.dy)
            ..lineTo(corner.dx, corner.dy + s)
            ..close());
    canvas.drawPath(path, Paint()..color = color);
  }
}

/// The core content layers in paint order.
List<GridLayer> coreContentLayers() => const [
  BackgroundLayer(),
  GridlineLayer(),
  CellContentLayer(),
  BorderLayer(),
  DecorationLayer(),
];

/// A paragraph extension used by layers measuring text.
extension ParagraphWidth on ui.Paragraph {
  double get textWidth => maxIntrinsicWidth;
}
