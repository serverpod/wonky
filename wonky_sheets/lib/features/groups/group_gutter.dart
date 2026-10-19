import 'dart:math' as math;

import 'package:flutter/foundation.dart' show Listenable;
import 'package:flutter/rendering.dart';
import 'package:wonky_sheets_core/model.dart';

import '../grid/paint/grid_layer.dart';
import '../grid/paint/text_layout_cache.dart';
import '../grid/viewport/grid_geometry.dart';
import 'group_controller.dart';

/// One clickable control of the outline gutter.
sealed class GutterControl {
  const GutterControl(this.rect);

  final Rect rect;
}

/// The +/− button of a group.
final class GutterToggle extends GutterControl {
  const GutterToggle(super.rect, this.span, this.dimension);

  final GroupSpan span;
  final Dimension dimension;
}

/// A level button ("1", "2", …) in the gutter corner.
final class GutterLevel extends GutterControl {
  const GutterLevel(super.rect, this.level, this.dimension);

  final int level;
  final Dimension dimension;
}

/// A bracket line of a group.
final class _Bracket {
  const _Bracket(this.from, this.to, this.across, this.collapsed);

  /// Start / end along the axis (screen px) and the position across it.
  final double from;
  final double to;
  final double across;
  final bool collapsed;
}

/// The outline gutter of one frame (07 §16.3): brackets from a group's first
/// to its last row/column, the +/− button on the row/column after the group,
/// and level buttons in the corner.
class GutterLayout {
  GutterLayout._(this.controls, this._brackets);

  final List<GutterControl> controls;
  final Map<Dimension, List<_Bracket>> _brackets;

  static const double level = kGroupGutterLevel;

  static GutterLayout compute(GridGeometry g, GroupController groups) {
    final controls = <GutterControl>[];
    final brackets = <Dimension, List<_Bracket>>{};
    final sheet = g.sheet;
    final b = math.min(12.0, level - 3);
    for (final d in Dimension.values) {
      final rows = d == Dimension.rows;
      final gutter = rows ? g.rowGutter : g.colGutter;
      if (gutter <= 0) continue;
      final spans = groups.spans(sheet.id, d);
      final levels = groups.levels(sheet.id, d);
      final axis = rows ? sheet.rows : sheet.columns;
      // Level buttons: in the header strip of the other axis.
      for (var l = 1; l <= levels + 1; l++) {
        final c = (l - 1) * level + level / 2;
        final Offset center = rows
            ? Offset(c, g.colGutter + (g.colHeaderHeight - g.colGutter) / 2)
            : Offset(g.rowGutter + (g.rowHeaderWidth - g.rowGutter) / 2, c);
        controls.add(
          GutterLevel(
            Rect.fromCenter(center: center, width: b, height: b),
            l,
            d,
          ),
        );
      }
      final list = brackets[d] = [];
      for (final s in spans) {
        final across = (s.depth - 1) * level + level / 2;
        final start = rows ? g.rowY(s.start) : g.colX(s.start);
        final endEdge = rows ? g.rowY(s.end + 1) : g.colX(s.end + 1);
        list.add(_Bracket(start, endEdge, across, s.collapsed));
        // The button sits on the row/column after the group.
        final after = s.end + 1;
        final double pos;
        if (after < axis.length) {
          final a0 = rows ? g.rowY(after) : g.colX(after);
          final size = axis.sizeAt(after) * g.zoom;
          pos = a0 + (size > 0 ? size / 2 : level / 2);
        } else {
          pos = endEdge + level / 2;
        }
        final center = rows ? Offset(across, pos) : Offset(pos, across);
        controls.add(
          GutterToggle(
            Rect.fromCenter(center: center, width: b, height: b),
            s,
            d,
          ),
        );
      }
    }
    return GutterLayout._(controls, brackets);
  }

  GutterControl? controlAt(Offset p) {
    for (final c in controls) {
      if (c.rect.inflate(2).contains(p)) return c;
    }
    return null;
  }
}

/// Paints the outline gutters (03 §3 "Group gutter").
class GroupGutterLayer extends GridLayer {
  const GroupGutterLayer(this.groups);

  final GroupController groups;

  @override
  int get zOrder => GridZ.headers + 50;

  @override
  Listenable? get repaint => groups;

  @override
  void paint(GridPaintContext ctx, Canvas canvas) {
    final g = ctx.geometry;
    if (g.rowGutter <= 0 && g.colGutter <= 0) return;
    final t = ctx.tokens;
    final hooks = ctx.controller.gridHooks;
    final hc = hooks.headerColors?.call(ctx.sheetId, t);
    final bg = Paint()..color = hc?.bg ?? t.headerBg;
    final fg = hc?.fg ?? t.headerFg;
    final line = Paint()..color = hc?.border ?? t.headerBorder;
    final layout = GutterLayout.compute(g, groups);
    final stroke = Paint()
      ..color = fg.withValues(alpha: 0.7)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    if (g.rowGutter > 0) {
      final strip = Rect.fromLTRB(0, 0, g.rowGutter, g.size.height);
      canvas.drawRect(strip, bg);
      canvas.drawRect(
        Rect.fromLTRB(g.rowGutter - 1, 0, g.rowGutter, g.size.height),
        line,
      );
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(0, g.colHeaderHeight, g.rowGutter, g.size.height),
      );
      for (final br in layout._brackets[Dimension.rows] ?? const <_Bracket>[]) {
        if (br.collapsed || br.to - br.from < 2) continue;
        canvas.drawLine(
          Offset(br.across, br.from + 2),
          Offset(br.across, br.to - 1),
          stroke,
        );
        canvas.drawLine(
          Offset(br.across, br.to - 1),
          Offset(br.across + 4, br.to - 1),
          stroke,
        );
      }
      canvas.restore();
    }
    if (g.colGutter > 0) {
      final strip = Rect.fromLTRB(0, 0, g.size.width, g.colGutter);
      canvas.drawRect(strip, bg);
      canvas.drawRect(
        Rect.fromLTRB(0, g.colGutter - 1, g.size.width, g.colGutter),
        line,
      );
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(g.rowHeaderWidth, 0, g.size.width, g.colGutter),
      );
      for (final br
          in layout._brackets[Dimension.columns] ?? const <_Bracket>[]) {
        if (br.collapsed || br.to - br.from < 2) continue;
        canvas.drawLine(
          Offset(br.from + 2, br.across),
          Offset(br.to - 1, br.across),
          stroke,
        );
        canvas.drawLine(
          Offset(br.to - 1, br.across),
          Offset(br.to - 1, br.across + 4),
          stroke,
        );
      }
      canvas.restore();
    }
    final box = Paint()..color = hc?.bg ?? t.headerBg;
    for (final c in layout.controls) {
      final inHeader = switch (c) {
        GutterToggle(:final dimension) =>
          dimension == Dimension.rows
              ? c.rect.center.dy >= g.colHeaderHeight
              : c.rect.center.dx >= g.rowHeaderWidth,
        GutterLevel() => true,
      };
      if (!inHeader) continue;
      final r = RRect.fromRectAndRadius(c.rect, const Radius.circular(2));
      canvas.drawRRect(r, box);
      canvas.drawRRect(r, stroke);
      switch (c) {
        case GutterToggle(:final span):
          final m = c.rect.center;
          final h = c.rect.width * 0.28;
          canvas.drawLine(m.translate(-h, 0), m.translate(h, 0), stroke);
          if (span.collapsed) {
            canvas.drawLine(m.translate(0, -h), m.translate(0, h), stroke);
          }
        case GutterLevel(:final level):
          final p = ctx.text.layout(
            '$level',
            GridTextStyle(
              fontFamily: 'Inter',
              fontSize: 9,
              color: fg,
              align: TextAlign.center,
            ),
          );
          canvas.drawParagraph(
            p,
            Offset(
              c.rect.center.dx - p.maxIntrinsicWidth / 2,
              c.rect.center.dy - p.height / 2,
            ),
          );
      }
    }
  }
}

/// Clicks in the outline gutter (07 §16.2): +/− toggles a group, level
/// buttons collapse to a level; other clicks in the gutter are swallowed.
class GroupGutterHitHandler extends GridHitHandler {
  GroupGutterHitHandler(this.groups, this.invoke);

  final GroupController groups;
  final void Function(String id, Map<String, Object?> args) invoke;

  bool _inGutter(GridGeometry g, Offset p) =>
      (g.rowGutter > 0 && p.dx < g.rowGutter) ||
      (g.colGutter > 0 && p.dy < g.colGutter);

  @override
  bool onPointerDown(GridGeometry g, Offset local, PointerDownEvent event) {
    if (g.rowGutter <= 0 && g.colGutter <= 0) return false;
    final c = GutterLayout.compute(g, groups).controlAt(local);
    switch (c) {
      case GutterToggle(:final span):
        invoke('sheets.group.toggle', {'groupId': span.id});
        return true;
      case GutterLevel(:final level, :final dimension):
        invoke('sheets.group.collapseToLevel', {
          'dimension': dimension.name,
          'level': level,
        });
        return true;
      case null:
        return _inGutter(g, local);
    }
  }

  @override
  MouseCursor? cursorAt(GridGeometry g, Offset local) {
    if (g.rowGutter <= 0 && g.colGutter <= 0) return null;
    if (GutterLayout.compute(g, groups).controlAt(local) != null) {
      return SystemMouseCursors.click;
    }
    return _inGutter(g, local) ? SystemMouseCursors.basic : null;
  }
}
