import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter/widgets.dart' show Brightness;
import 'package:flutter/rendering.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;

import '../../theme/sheets_tokens.dart';
import '../grid/paint/grid_layer.dart';
import '../grid/viewport/grid_geometry.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'filter_controller.dart';

/// Colors of the filter chrome (07 §3.5, 04 §14 `filterRangeOutline`).
abstract final class FilterColors {
  static Color outline(GridPaintTokens t) => t.brightness == Brightness.dark
      ? const Color(0xff4ade80)
      : const Color(0xff16a34a);

  static Color active(GridPaintTokens t) => t.brightness == Brightness.dark
      ? const Color(0xff60a5fa)
      : const Color(0xff1a73e8);

  /// Row numbers of filtered sheets.
  static Color rowNumber(GridPaintTokens t) => t.brightness == Brightness.dark
      ? const Color(0xff86efac)
      : const Color(0xff15803d);

  /// Dark headers of an active filter view (07 §4.2: `foreground` at 85 %
  /// with `background` text — readable in both themes).
  static GridHeaderColors viewHeaders(GridPaintTokens t) =>
      t.brightness == Brightness.dark
      ? (
          bg: const Color(0xffd4d4d8),
          fg: const Color(0xff18181b),
          selectedBg: const Color(0xffa1a1aa),
          fullBg: const Color(0xff93c5fd),
          border: const Color(0xffa1a1aa),
        )
      : (
          bg: const Color(0xff3f3f46),
          fg: const Color(0xfffafafa),
          selectedBg: const Color(0xff52525b),
          fullBg: const Color(0xff1e40af),
          border: const Color(0xff52525b),
        );
}

/// The filter button inside header cell [cell] (03 §3: drawn in the cells of
/// the filter's header row).
Rect filterButtonRect(Rect cell, double zoom) {
  final s = math.max(8.0, math.min(16 * zoom, cell.height - 4));
  return Rect.fromLTWH(cell.right - s - 3 * zoom, cell.center.dy - s / 2, s, s);
}

/// Funnel glyph inside [r].
Path funnelPath(Rect r) {
  final w = r.width;
  final h = r.height;
  final l = r.left + w * 0.18;
  final rr = r.right - w * 0.18;
  final top = r.top + h * 0.22;
  final mid = r.top + h * 0.55;
  final stemL = r.left + w * 0.43;
  final stemR = r.right - w * 0.43;
  return Path()
    ..moveTo(l, top)
    ..lineTo(rr, top)
    ..lineTo(stemR, mid)
    ..lineTo(stemR, r.bottom - h * 0.16)
    ..lineTo(stemL, r.bottom - h * 0.26)
    ..lineTo(stemL, mid)
    ..close();
}

/// Filter buttons in the header row of the shown filter (decorations).
class FilterButtonLayer extends GridLayer {
  const FilterButtonLayer(this.filters);

  final FilterController filters;

  @override
  int get zOrder => GridZ.decorations + 10;

  @override
  Listenable? get repaint => filters;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final f = filters.effective(ctx.sheetId);
    if (f == null) return;
    final g = ctx.geometry;
    final t = ctx.tokens;
    final header = f.range.top;
    if (ctx.sheet.rows.sizeAt(header) <= 0) return;
    final sorted = {for (final (c, asc) in f.sort) c: asc};
    ctx.forEachPane(canvas, (pane) {
      if (!pane.showsRow(header)) return;
      final from = math.max(f.range.left, pane.colStart);
      final to = math.min(f.range.right, pane.colEnd);
      for (var c = from; c <= to; c++) {
        if (ctx.sheet.columns.sizeAt(c) <= 0) continue;
        final colId = ctx.sheet.columns.idAt(c);
        final cell = pane.cellRect(header, c);
        final b = filterButtonRect(cell, g.zoom);
        final criteria = filters.criteriaOf(f, colId);
        final on = criteria != null && !criteria.isEmpty;
        final asc = sorted[colId];
        _button(canvas, b, t, on: on, sortAscending: asc);
      }
    });
  }

  static void _button(
    Canvas canvas,
    Rect b,
    GridPaintTokens t, {
    required bool on,
    bool? sortAscending,
  }) {
    final rr = RRect.fromRectAndRadius(b, const Radius.circular(3));
    final accent = FilterColors.active(t);
    canvas.drawRRect(
      rr,
      Paint()..color = on ? accent : t.sheetBackground.withValues(alpha: 0.9),
    );
    if (!on) {
      canvas.drawRRect(
        rr.deflate(0.5),
        Paint()
          ..color = t.headerBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    final fg = on ? const Color(0xffffffff) : t.headerFg;
    final icon = sortAscending == null ? b : b.translate(-b.width * 0.12, 0);
    final path = funnelPath(icon.deflate(b.width * 0.06));
    if (on) {
      canvas.drawPath(path, Paint()..color = fg);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..color = fg
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, b.width / 14)
          ..strokeJoin = StrokeJoin.round,
      );
    }
    if (sortAscending != null) {
      // Small arrow at the right edge.
      final x = b.right - b.width * 0.2;
      final top = b.top + b.height * 0.2;
      final bottom = b.bottom - b.height * 0.2;
      final p = Paint()
        ..color = fg
        ..strokeWidth = math.max(1, b.width / 14)
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), p);
      final tip = sortAscending ? top : bottom;
      final dir = sortAscending ? 1 : -1;
      canvas.drawLine(
        Offset(x, tip),
        Offset(x - b.width * 0.1, tip + dir * b.height * 0.15),
        p,
      );
      canvas.drawLine(
        Offset(x, tip),
        Offset(x + b.width * 0.1, tip + dir * b.height * 0.15),
        p,
      );
    }
  }
}

/// The 2 px outline of the filter range while the selection is inside it
/// (07 §3.5).
class FilterRangeLayer extends GridLayer {
  const FilterRangeLayer(this.filters);

  final FilterController filters;

  @override
  int get zOrder => GridZ.selection - 10;

  @override
  Listenable? get repaint => filters;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final f = filters.effective(ctx.sheetId);
    if (f == null) return;
    final sel = ctx.selection;
    if (sel.sheetId != ctx.sheetId ||
        !f.range.contains(sel.activeRow, sel.activeCol)) {
      return;
    }
    final paint = Paint()
      ..color = FilterColors.outline(ctx.tokens)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final clipped =
        f.range.intersection(
          GridRect(
            0,
            0,
            ctx.sheet.rows.length - 1,
            ctx.sheet.columns.length - 1,
          ),
        ) ??
        f.range;
    ctx.forEachPane(canvas, (pane) {
      canvas.drawRect(pane.rangeRect(clipped).deflate(1), paint);
    });
  }
}

/// Clicks on filter buttons open the column popover (07 §3.5).
class FilterButtonHitHandler extends GridHitHandler {
  FilterButtonHitHandler(this.ed, this.filters, this.onOpen);

  final SheetEditorController ed;
  final FilterController filters;
  final void Function(String colId, Rect anchor) onOpen;

  /// The column id and button rect under [p], or null.
  (String, Rect)? buttonAt(GridGeometry g, Offset p) {
    final f = filters.effective(g.sheet.id);
    if (f == null) return null;
    final header = f.range.top;
    if (g.sheet.rows.sizeAt(header) <= 0) return null;
    if (p.dy < g.colHeaderHeight || p.dx < g.rowHeaderWidth) return null;
    final pane = g.paneAt(p);
    if (pane == null || !pane.showsRow(header)) return null;
    final (row, col) = pane.cellAt(p);
    if (row != header || col < f.range.left || col > f.range.right) {
      return null;
    }
    final b = filterButtonRect(pane.cellRect(header, col), g.zoom);
    if (!b.inflate(2).contains(p)) return null;
    return (g.sheet.columns.idAt(col), b);
  }

  @override
  bool onPointerDown(GridGeometry g, Offset local, PointerDownEvent event) {
    final hit = buttonAt(g, local);
    if (hit == null) return false;
    if (ed.editor.isEditing) ed.editor.commitSync();
    onOpen(hit.$1, hit.$2);
    return true;
  }

  @override
  MouseCursor? cursorAt(GridGeometry g, Offset local) =>
      buttonAt(g, local) == null ? null : SystemMouseCursors.click;
}

/// The sticky edit row (07 §3.4): a row the user just edited that no
/// longer matches the filter stays visible on this device, dimmed, with a
/// "Hidden by filter" badge, until the selection leaves it.
class StickyRowLayer extends GridLayer {
  StickyRowLayer(this.filters);

  final FilterController filters;

  @override
  int get zOrder => GridZ.decorations + 5;

  @override
  Listenable? get repaint => filters;

  TextPainter? _badge;
  String? _badgeKey;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final row = filters.stickyHiddenRow(ctx.sheetId);
    final f = filters.effective(ctx.sheetId);
    if (row == null || f == null) return;
    final t = ctx.tokens;
    final rect = GridRect(row, f.range.left, row, f.range.right);
    final dim = Paint()..color = t.sheetBackground.withValues(alpha: 0.55);
    final label = ctx.controller.l10n.filterStickyRowBadge;
    final fontSize = 10.5 * ctx.zoom.clamp(0.8, 1.4);
    final key = '$label|$fontSize|${t.brightness}';
    if (_badgeKey != key) {
      _badgeKey = key;
      _badge = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: fontSize,
            color: t.sheetBackground,
            fontFamily: WonkyFonts.inter,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
    }
    final badge = _badge!;
    final pill = Paint()..color = FilterColors.outline(t);
    ctx.forEachPane(canvas, (pane) {
      if (!pane.showsRow(row)) return;
      final r = pane.rangeRect(rect);
      if (r.isEmpty) return;
      canvas.drawRect(r, dim);
      if (!pane.showsCol(f.range.right)) return;
      final h = math.min(r.height - 2, badge.height + 4);
      if (h <= 6) return;
      final w = badge.width + 10;
      final box = Rect.fromLTWH(r.right - w - 4, r.center.dy - h / 2, w, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(h / 2)),
        pill,
      );
      badge.paint(
        canvas,
        Offset(box.left + 5, box.center.dy - badge.height / 2),
      );
    });
  }
}
