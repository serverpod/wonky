import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wonky_sheets_core/formula.dart'
    show GridRect, ColumnLetters, FormulaHighlighter, FormulaReferenceSpan;

import '../../../sheet_editor/sheet_editor_controller.dart';
import '../../selection/grid_selection.dart';
import '../../viewport/grid_geometry.dart';
import '../grid_layer.dart';
import '../text_layout_cache.dart';

/// Draws a dashed rectangle outline (marching ants, previews).
void drawDashedRect(
  Canvas canvas,
  Rect rect,
  Paint paint, {
  double dash = 6,
  double gap = 4,
  double phase = 0,
}) {
  final path = Path()..addRect(rect);
  for (final metric in path.computeMetrics()) {
    var d = -phase % (dash + gap);
    while (d < metric.length) {
      final start = math.max(0.0, d);
      final end = math.min(metric.length, d + dash);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), paint);
      }
      d += dash + gap;
    }
  }
}

/// Layer 9: colored boxes of the references in the edited formula (03 §8.7).
class ReferenceBoxLayer extends GridLayer {
  const ReferenceBoxLayer();

  @override
  int get zOrder => GridZ.referenceBoxes;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final editor = ctx.controller.editor;
    final session = editor.session;
    if (session == null || !editor.isFormula) return;
    final sheet = ctx.sheet;
    final editingHere = session.sheetId == sheet.id;
    final List<FormulaReferenceSpan> refs;
    try {
      refs = FormulaHighlighter.references(
        editor.text.text,
        locale: ctx.controller.formulaLocale,
      );
    } catch (_) {
      return;
    }
    final rowsN = sheet.rows.length;
    final colsN = sheet.columns.length;
    for (final ref in refs) {
      final area = ref.area;
      final String? refSheet = area.sheet;
      final onThisSheet = refSheet == null
          ? editingHere
          : refSheet.toLowerCase() == sheet.name.toLowerCase();
      if (!onThisSheet) continue;
      final GridRect rect;
      try {
        rect = area.toRect(rowsN, colsN);
      } catch (_) {
        continue;
      }
      if (rect.top < 0 || rect.left < 0) continue;
      final clipped = rect.intersection(GridRect(0, 0, rowsN - 1, colsN - 1));
      if (clipped == null) continue;
      final color = ctx.tokens.reference(ref.colorIndex);
      ctx.forEachPane(canvas, (pane) {
        final r = pane.rangeRect(clipped);
        canvas.drawRect(r, Paint()..color = color.withValues(alpha: 0.1));
        canvas.drawRect(
          r.deflate(1),
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        if (!clipped.isSingleCell) {
          final hp = Paint()..color = color;
          for (final o in [
            r.topLeft,
            r.topRight,
            r.bottomLeft,
            r.bottomRight,
          ]) {
            canvas.drawRect(
              Rect.fromCenter(center: o, width: 5, height: 5),
              hp,
            );
          }
        }
      });
    }
  }
}

/// Layer 10: local selection, active cell, fill handle, marching ants.
class SelectionLayer extends GridLayer {
  const SelectionLayer();

  @override
  int get zOrder => GridZ.selection;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final c = ctx.controller;
    final sel = ctx.selection;
    if (sel.sheetId != ctx.sheetId) return;
    // The read-only mobile layout has no cell selection (suite 02 §6.1, T-1).
    if (c.readOnlyView) return;
    final tokens = ctx.tokens;
    final fill = Paint()..color = tokens.selectionFill;
    final border = Paint()
      ..color = tokens.selectionBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final active = Paint()
      ..color = tokens.selectionBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final editing = c.editor.isEditing;
    final activeRect =
        c.activeSheet?.mergeAt(sel.activeRow, sel.activeCol) ??
        GridRect.cell(sel.activeRow, sel.activeCol);
    final spill = _spillOf(ctx, sel.activeRow, sel.activeCol);
    ctx.forEachPane(canvas, (pane) {
      if (spill != null) {
        canvas.drawRect(
          pane.rangeRect(spill).deflate(0.5),
          Paint()
            ..color = tokens.spillFrame
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
      final groups = <int>{};
      final activeGroup = sel.activeRange.group;
      for (var i = 0; i < sel.ranges.length; i++) {
        final range = sel.ranges[i];
        // A display range (sorted filter view, 07 §4.4) is one rectangle on
        // screen however many model ranges it covers.
        final shown = range.displayRect;
        if (shown != null && !groups.add(range.group)) continue;
        final rect = _clip(ctx, range.rect);
        final r = shown != null
            ? pane.displayRangeRect(_clip(ctx, shown))
            : pane.rangeRect(rect);
        final isActiveRange = shown != null
            ? range.group == activeGroup
            : i == sel.activeRangeIndex;
        final multi =
            (shown != null ? shown.cellCount : rect.cellCount) > 1 &&
            (shown != null || rect != activeRect);
        if (multi || sel.ranges.length > 1) {
          final path = Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(r);
          if (isActiveRange) path.addRect(pane.rangeRect(activeRect));
          canvas.drawPath(path, fill);
          canvas.drawRect(r.deflate(0.5), border);
        }
      }
      // Active cell frame.
      final ar = pane.rangeRect(activeRect);
      canvas.drawRect(ar.deflate(1), active);
      // Fill handle.
      if (sel.ranges.length == 1 &&
          c.canEdit &&
          !editing &&
          !c.rowsPermuted(sel.ranges.first.rect)) {
        final rr = pane.rangeRect(_clip(ctx, sel.ranges.first.rect));
        final h = Rect.fromCenter(center: rr.bottomRight, width: 7, height: 7);
        canvas.drawRect(h, Paint()..color = tokens.sheetBackground);
        canvas.drawRect(h.deflate(1), Paint()..color = tokens.fillHandle);
      }
      // Copy/cut marching ants and paint-format source.
      final mark = c.clipMark.value;
      if (mark != null && mark.sheetId == ctx.sheetId) {
        final shown = mark.displayRect;
        drawDashedRect(
          canvas,
          (shown != null
                  ? pane.displayRangeRect(shown)
                  : pane.rangeRect(mark.rect))
              .deflate(1),
          Paint()
            ..color = tokens.selectionBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
          phase: c.antsPhase.value,
        );
      }
      final pf = c.paintFormat.value;
      if (pf != null && pf.sheetId == ctx.sheetId) {
        drawDashedRect(
          canvas,
          pane.rangeRect(pf.source).deflate(1),
          Paint()
            ..color = tokens.selectionBorder
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
          phase: c.antsPhase.value,
        );
      }
    });
  }

  /// The spill range of the array formula at or covering (row, col)
  /// (03 §14.8), or null.
  GridRect? _spillOf(GridPaintContext ctx, int row, int col) {
    final engine = ctx.controller.engine;
    final sid = ctx.sheetId;
    try {
      final rec = ctx.sheet.cellAt(row, col);
      if (rec?.content?.startsWith('=') ?? false) {
        return engine.peekValueAt(sid, row, col)?.spill?.rect;
      }
      final host = engine.overlayAt(sid, row, col);
      if (host == null) return null;
      return engine.peekValueAt(sid, host.hostRow, host.hostCol)?.spill?.rect;
    } catch (_) {
      return null;
    }
  }

  /// Whole rows/columns are clipped to the grid.
  GridRect _clip(GridPaintContext ctx, GridRect r) =>
      r.intersection(
        GridRect(0, 0, ctx.sheet.rows.length - 1, ctx.sheet.columns.length - 1),
      ) ??
      r;
}

/// Layer 11: drag feedback (fill preview, move outline, resize guide).
class DragFeedbackLayer extends GridLayer {
  const DragFeedbackLayer();

  @override
  int get zOrder => GridZ.dragFeedback;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final fb = ctx.controller.drag.value;
    if (fb == null) return;
    final tokens = ctx.tokens;
    final g = ctx.geometry;
    switch (fb) {
      case FillDragFeedback(:final target):
        ctx.forEachPane(canvas, (pane) {
          drawDashedRect(
            canvas,
            pane.rangeRect(target).deflate(1),
            Paint()
              ..color = tokens.headerFg
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
            dash: 4,
            gap: 3,
          );
        });
      case MoveDragFeedback(:final target):
        ctx.forEachPane(canvas, (pane) {
          canvas.drawRect(
            pane.rangeRect(target).deflate(1.5),
            Paint()
              ..color = tokens.headerFg
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        });
      case ResizeDragFeedback(:final columns, :final index, :final size):
        final paint = Paint()..color = tokens.selectionBorder;
        if (columns) {
          final x = g.colX(index) + size * g.zoom;
          canvas.drawRect(Rect.fromLTWH(x - 1, 0, 2, g.size.height), paint);
        } else {
          final y = g.rowY(index) + size * g.zoom;
          canvas.drawRect(Rect.fromLTWH(0, y - 1, g.size.width, 2), paint);
        }
      case HeaderMoveDragFeedback(:final columns, :final before):
        final paint = Paint()..color = tokens.selectionBorder;
        if (columns) {
          final x = g.colX(before);
          canvas.drawRect(Rect.fromLTWH(x - 1.5, 0, 3, g.size.height), paint);
        } else {
          final y = g.rowY(before);
          canvas.drawRect(Rect.fromLTWH(0, y - 1.5, g.size.width, 3), paint);
        }
      case FreezeDragFeedback(:final rows, :final count):
        final paint = Paint()
          ..color = tokens.frozenDivider.withValues(alpha: 0.8);
        if (rows) {
          final y = g.colHeaderHeight + g.sheet.rows.offsetOf(count) * g.zoom;
          canvas.drawRect(Rect.fromLTWH(0, y - 2, g.size.width, 4), paint);
        } else {
          final x = g.rowHeaderWidth + g.sheet.columns.offsetOf(count) * g.zoom;
          canvas.drawRect(Rect.fromLTWH(x - 2, 0, 4, g.size.height), paint);
        }
    }
  }
}

/// Layer 12: frozen dividers.
class FrozenDividerLayer extends GridLayer {
  const FrozenDividerLayer();

  @override
  int get zOrder => GridZ.frozenDividers;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final g = ctx.geometry;
    final paint = Paint()..color = ctx.tokens.frozenDivider;
    if (g.frozenRows > 0) {
      final y = g.colHeaderHeight + g.frozenHeight;
      canvas.drawRect(Rect.fromLTWH(0, y - 1, g.size.width, 2), paint);
    }
    if (g.frozenCols > 0) {
      final x = g.rowHeaderWidth + g.frozenWidth;
      canvas.drawRect(Rect.fromLTWH(x - 1, 0, 2, g.size.height), paint);
    }
  }
}

/// Column/row headers, the corner and the freeze bar handles (03 §3–4).
class HeaderLayer extends GridLayer {
  const HeaderLayer();

  @override
  int get zOrder => GridZ.headers;

  /// Thickness of the freeze bars in the corner.
  static const freezeBar = 4.0;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final g = ctx.geometry;
    if (!g.showHeaders) return;
    final tokens = ctx.tokens;
    final sel = ctx.selection;
    final hair = g.hairline;
    final hooks = ctx.controller.gridHooks;
    final hc =
        hooks.headerColors?.call(ctx.sheetId, tokens) ??
        (
          bg: tokens.headerBg,
          fg: tokens.headerFg,
          selectedBg: tokens.headerSelectedBg,
          fullBg: tokens.headerFullBg,
          border: tokens.headerBorder,
        );
    final rowColor = hooks.rowNumberColor;
    final bg = Paint()..color = hc.bg;
    final line = Paint()..color = hc.border;
    final colStrip = Rect.fromLTRB(
      g.rowHeaderWidth,
      0,
      g.size.width,
      g.colHeaderHeight,
    );
    final rowStrip = Rect.fromLTRB(
      0,
      g.colHeaderHeight,
      g.rowHeaderWidth,
      g.size.height,
    );
    canvas.drawRect(colStrip, bg);
    canvas.drawRect(rowStrip, bg);
    GridTextStyle styleFor(bool bold, [Color? color]) => GridTextStyle(
      fontFamily: 'Inter',
      fontSize: 11 * g.zoom,
      color: color ?? hc.fg,
      bold: bold,
      align: TextAlign.center,
    );
    // No selected headers in the read-only mobile layout (T-1).
    final sameSheet =
        sel.sheetId == ctx.sheetId && !ctx.controller.readOnlyView;

    // Column headers.
    for (final pane in g.panes) {
      if (pane.kind != PaneKind.main && pane.kind != PaneKind.left) continue;
      if (pane.colEnd < pane.colStart) continue;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(pane.rect.left, 0, pane.rect.right, g.colHeaderHeight),
      );
      for (var c = pane.colStart; c <= pane.colEnd; c++) {
        if (ctx.sheet.columns.sizeAt(c) <= 0) continue;
        final x0 = pane.x(c);
        final x1 = pane.x(c + 1);
        final rect = Rect.fromLTRB(x0, g.colGutter, x1, g.colHeaderHeight);
        final full = sameSheet && sel.columnFullySelected(c);
        if (full) {
          canvas.drawRect(rect, Paint()..color = hc.fullBg);
        } else if (sameSheet && sel.columnIntersects(c)) {
          canvas.drawRect(rect, Paint()..color = hc.selectedBg);
        }
        canvas.drawRect(
          Rect.fromLTRB(x1 - hair, g.colGutter, x1, g.colHeaderHeight),
          line,
        );
        final p = ctx.text.layout(ColumnLetters.fromIndex(c), styleFor(full));
        canvas.drawParagraph(
          p,
          Offset(
            rect.center.dx - p.maxIntrinsicWidth / 2,
            rect.center.dy - p.height / 2,
          ),
        );
        _hiddenMarker(ctx, canvas, columns: true, index: c, rect: rect);
      }
      canvas.restore();
    }
    // Row headers.
    for (final pane in g.panes) {
      if (pane.kind != PaneKind.main && pane.kind != PaneKind.top) continue;
      if (pane.rowEnd < pane.rowStart) continue;
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(0, pane.rect.top, g.rowHeaderWidth, pane.rect.bottom),
      );
      // Display order (a sorted filter view shows model numbers, 07 §4.4).
      for (final r in pane.rows) {
        if (ctx.sheet.rows.sizeAt(r) <= 0) continue;
        final y0 = pane.y(r);
        final y1 = pane.bottomOf(r);
        final rect = Rect.fromLTRB(g.rowGutter, y0, g.rowHeaderWidth, y1);
        final full = sameSheet && sel.rowFullySelected(r);
        if (full) {
          canvas.drawRect(rect, Paint()..color = hc.fullBg);
        } else if (sameSheet && sel.rowIntersects(r)) {
          canvas.drawRect(rect, Paint()..color = hc.selectedBg);
        }
        canvas.drawRect(
          Rect.fromLTRB(g.rowGutter, y1 - hair, g.rowHeaderWidth, y1),
          line,
        );
        if (y1 - y0 > 6) {
          final accent = full ? null : rowColor?.call(ctx.sheetId, r, tokens);
          final p = ctx.text.layout(
            '${r + 1}',
            styleFor(full || accent != null, accent),
          );
          canvas.drawParagraph(
            p,
            Offset(
              rect.center.dx - p.maxIntrinsicWidth / 2,
              rect.center.dy - p.height / 2,
            ),
          );
        }
        _hiddenMarker(ctx, canvas, columns: false, index: r, rect: rect);
      }
      canvas.restore();
    }
    // Strip edges.
    canvas.drawRect(
      Rect.fromLTRB(
        0,
        g.colHeaderHeight - hair,
        g.size.width,
        g.colHeaderHeight,
      ),
      line,
    );
    canvas.drawRect(
      Rect.fromLTRB(
        g.rowHeaderWidth - hair,
        0,
        g.rowHeaderWidth,
        g.size.height,
      ),
      line,
    );
    // Corner with freeze bars.
    final corner = Rect.fromLTRB(0, 0, g.rowHeaderWidth, g.colHeaderHeight);
    canvas.drawRect(corner, bg);
    final barPaint = Paint()..color = tokens.frozenDivider;
    canvas.drawRect(
      Rect.fromLTRB(0, corner.bottom - freezeBar, corner.right, corner.bottom),
      barPaint,
    );
    canvas.drawRect(
      Rect.fromLTRB(corner.right - freezeBar, 0, corner.right, corner.bottom),
      barPaint,
    );
  }

  /// Small arrows where hidden rows/columns are (03 §3).
  void _hiddenMarker(
    GridPaintContext ctx,
    Canvas canvas, {
    required bool columns,
    required int index,
    required Rect rect,
  }) {
    final axis = columns ? ctx.sheet.columns : ctx.sheet.rows;
    if (index + 1 >= axis.length || !axis.isUserHidden(index + 1)) return;
    final paint = Paint()
      ..color =
          ctx.controller.gridHooks.headerColors
              ?.call(ctx.sheetId, ctx.tokens)
              ?.fg ??
          ctx.tokens.headerFg;
    if (columns) {
      final x = rect.right;
      final cy = rect.center.dy;
      canvas.drawPath(
        Path()
          ..moveTo(x - 1, cy - 4)
          ..lineTo(x - 5, cy)
          ..lineTo(x - 1, cy + 4)
          ..close(),
        paint,
      );
    } else {
      final y = rect.bottom;
      final cx = rect.center.dx;
      canvas.drawPath(
        Path()
          ..moveTo(cx - 4, y - 1)
          ..lineTo(cx, y - 5)
          ..lineTo(cx + 4, y - 1)
          ..close(),
        paint,
      );
    }
  }
}

/// The core overlay layers.
List<GridLayer> coreOverlayLayers() => const [
  ReferenceBoxLayer(),
  SelectionLayer(),
  DragFeedbackLayer(),
  FrozenDividerLayer(),
  HeaderLayer(),
];

/// Kinds of a selection range drawn in headers (exported for tests).
typedef HeaderSelection = ResolvedSelection;
