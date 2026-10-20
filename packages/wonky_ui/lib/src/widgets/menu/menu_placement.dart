import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

/// Keeps menus (and dropdown-like popovers) inside the window (suite 02
/// §4.2): a menu opens where its anchor says when it fits, opens on the
/// other side of its trigger (above instead of below) when it does not,
/// shifts sideways to stay on screen, and scrolls when it is taller than
/// the room beside its trigger.
abstract final class WonkyMenuPlacement {
  /// Space kept between a menu and the screen edges.
  static const margin = 8.0;

  /// shad's vertical menu padding (4 px top and bottom) plus its 1 px border.
  static const chrome = 10.0;

  /// The least a menu's items may be limited to, so that tiny windows still
  /// show a few items (and scroll).
  static const minItemsHeight = 120.0;

  /// [anchor] as an anchor that keeps the overlay on screen.
  ///
  /// shad's `ShadAnchor` glues the overlay to its trigger and never moves it:
  /// a menu below a trigger at the bottom of the window (the sheet tab menu)
  /// or start-aligned near the right edge ran off the screen. The returned
  /// anchor places the overlay as [anchor] does when it fits, mirrors it to
  /// the other side of the trigger (with the offset mirrored too) when it
  /// does not fit vertically, and shifts it horizontally to stay inside the
  /// window.
  static ShadAnchorAuto onScreen(ShadAnchor anchor) => ShadAnchorAuto(
    targetAnchor: anchor.childAlignment,
    // shad's auto anchor names the side the overlay extends to; the manual
    // anchor names the overlay's point glued to the trigger: the opposite.
    followerAnchor: -anchor.overlayAlignment,
    offset: anchor.offset,
    fallback: ShadAnchorAuto(
      targetAnchor: _flipY(anchor.childAlignment),
      followerAnchor: -_flipY(anchor.overlayAlignment),
      offset: Offset(anchor.offset.dx, -anchor.offset.dy),
    ),
  );

  /// The anchor of a submenu: beside its item's end (as shad's default), and
  /// ending at the item's bottom instead when there is no room below.
  /// [nested] is for a submenu of a submenu (shad lifts those 2 px more).
  static ShadAnchorAuto submenu({bool nested = false}) {
    final dy = nested ? 5.0 : 3.0;
    return ShadAnchorAuto(
      offset: Offset(-8, -dy),
      targetAnchor: Alignment.topRight,
      followerAnchor: Alignment.bottomRight,
      fallback: ShadAnchorAuto(
        offset: Offset(-8, dy),
        targetAnchor: Alignment.bottomRight,
        followerAnchor: Alignment.topRight,
      ),
    );
  }

  /// The tallest a menu's items may be on a screen of height [screen] when
  /// the menu opens downwards from [below] or, when there is more room
  /// there, upwards ending at [above] (global y coordinates). Taller menus
  /// scroll, so that they always fit on one side of their trigger.
  static double itemsMaxHeight(
    double screen, {
    required double below,
    required double above,
  }) => math.max(
    minItemsHeight,
    math.max(screen - below, above) - margin - chrome,
  );

  /// [itemsMaxHeight] for a menu opening beside [anchor] (a trigger's global
  /// rect) with [gap] between the two.
  static double itemsMaxHeightBeside(
    BuildContext context,
    Rect anchor, {
    double gap = 0,
  }) => itemsMaxHeight(
    MediaQuery.sizeOf(context).height,
    below: anchor.bottom + gap,
    above: anchor.top - gap,
  );

  /// The global rect of [context]'s render box, or null before its first
  /// layout.
  static Rect? rectOf(BuildContext context) {
    if (!context.mounted) return null;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static AlignmentGeometry _flipY(AlignmentGeometry a) => switch (a) {
    Alignment(:final x, :final y) => Alignment(x, -y),
    AlignmentDirectional(:final start, :final y) => AlignmentDirectional(
      start,
      -y,
    ),
    _ => a,
  };
}
