import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;

import '../formatting/sheets_user_defaults.dart';
import '../../theme/sheets_tokens.dart';
import '../cell_editor/cell_editor_controller.dart';
import '../cell_editor/cell_editor_overlay.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'package:wonky_sheets_core/model.dart' show CellWidgetKind;

import 'a11y/grid_semantics.dart';
import 'grid_touch.dart';
import 'paint/layers/content_layers.dart';
import 'paint/layers/overlay_layers.dart';
import 'selection/grid_selection.dart';
import 'viewport/grid_geometry.dart';
import 'viewport/grid_pass.dart';
import 'viewport/grid_scroll_controller.dart';

/// Opens the context menu of a grid region at a global position.
typedef GridContextMenuCallback =
    void Function(GridMenuKind kind, Offset globalPosition);

/// Which context menu (04 §9).
enum GridMenuKind { cell, rowHeader, columnHeader, corner }

enum _Drag {
  none,
  select,
  rows,
  cols,
  fill,
  move,
  resizeCol,
  resizeRow,
  freezeRows,
  freezeCols,
  point,
  paint,
  moveCols,
  moveRows,
}

/// The grid (03 §2.2): headers, frozen panes, the two paint passes, the cell
/// editor overlay, scrollbars and all pointer/keyboard interaction.
class GridArea extends StatefulWidget {
  const GridArea({
    super.key,
    required this.controller,
    required this.services,
    this.onContextMenu,
  });

  final SheetEditorController controller;
  final ShellServices services;
  final GridContextMenuCallback? onContextMenu;

  @override
  State<GridArea> createState() => _GridAreaState();
}

class _GridAreaState extends State<GridArea> with TickerProviderStateMixin {
  SheetEditorController get c => widget.controller;

  late final Ticker _ants;
  _Drag _drag = _Drag.none;
  Offset? _lastPointer;
  Timer? _autoScroll;

  /// The pointer cursor: its own listenable, so a cursor change rebuilds
  /// only the [MouseRegion], never the passes (S-07).
  final ValueNotifier<MouseCursor> _cursor = ValueNotifier(
    SystemMouseCursors.cell,
  );
  int _resizeIndex = -1;
  double _resizeStart = 0;
  double _resizeOrigin = 0;
  GridRect? _dragSource;
  (int, int)? _dragAnchor;
  DateTime? _lastDown;
  Offset? _lastDownPos;
  (int, int)? _headerAnchor;

  @override
  void initState() {
    super.initState();
    _ants = createTicker((elapsed) {
      // Settings › Sheets › Reduce grid animations: still dashes.
      if (SheetsUserDefaults.of(c.services).reduceAnimations) return;
      c.antsPhase.value = (elapsed.inMilliseconds / 33).floorToDouble();
    });
    c.clipMark.addListener(_syncAnts);
    c.paintFormat.addListener(_syncAnts);
    c.drag.addListener(c.overlaySignal.fire);
    c.gridFocus.addListener(_redirectFocus);
    _announcer = SelectionAnnouncer(c, view: () => View.maybeOf(context));
    HardwareKeyboard.instance.addHandler(_onModifierKey);
  }

  late final SelectionAnnouncer _announcer;

  /// While the grid has focus and the user can edit, the (invisible) cell
  /// editor field holds the primary focus so that typed text — including
  /// IME compositions — goes straight into it (03 §8.3 "ready" state).
  void _redirectFocus() {
    if (c.gridFocus.hasPrimaryFocus && c.canEdit && !c.editor.isEditing) {
      c.editor.cellFocus.requestFocus();
    }
  }

  /// Grid-scope shortcuts apply only while no cell is being edited.
  KeyEventResult _gridKeys(FocusNode node, KeyEvent e) {
    if (c.editor.isEditing) return KeyEventResult.ignored;
    return widget.services.keymap.handle(e, KeyScope.grid, context: context);
  }

  void _syncAnts() {
    final need = c.clipMark.value != null || c.paintFormat.value != null;
    if (need && !_ants.isActive) {
      _ants.start();
    } else if (!need && _ants.isActive) {
      _ants.stop();
    }
    c.overlaySignal.fire();
  }

  @override
  void dispose() {
    c.clipMark.removeListener(_syncAnts);
    c.paintFormat.removeListener(_syncAnts);
    c.drag.removeListener(c.overlaySignal.fire);
    c.gridFocus.removeListener(_redirectFocus);
    _announcer.dispose();
    HardwareKeyboard.instance.removeHandler(_onModifierKey);
    _ants.dispose();
    _autoScroll?.cancel();
    _touch.dispose();
    _fling?.dispose();
    _cursor.dispose();
    super.dispose();
  }

  GridGeometry? get _g => c.geometry;

  bool get _mod {
    final kb = HardwareKeyboard.instance;
    return defaultTargetPlatformIsMac ? kb.isMetaPressed : kb.isControlPressed;
  }

  static bool get defaultTargetPlatformIsMac => const {
    TargetPlatform.macOS,
    TargetPlatform.iOS,
  }.contains(defaultTargetPlatform);

  bool get _shift => HardwareKeyboard.instance.isShiftPressed;
  bool get _alt => HardwareKeyboard.instance.isAltPressed;

  // ---------------------------------------------------------------------------
  // Hit testing.

  ({bool colHeader, bool rowHeader, bool corner})? _region(Offset p) {
    final g = _g;
    if (g == null) return null;
    final inCols = p.dy < g.colHeaderHeight;
    final inRows = p.dx < g.rowHeaderWidth;
    return (
      colHeader: inCols && !inRows,
      rowHeader: inRows && !inCols,
      corner: inCols && inRows,
    );
  }

  (int, int)? _cellAt(Offset p) {
    final g = _g;
    if (g == null) return null;
    final pane = g.paneAt(p) ?? g.main;
    final clamped = Offset(
      p.dx.clamp(pane.rect.left, math.max(pane.rect.left, pane.rect.right - 1)),
      p.dy.clamp(pane.rect.top, math.max(pane.rect.top, pane.rect.bottom - 1)),
    );
    if (g.paneAt(p) == null) {
      return (g.rowAtY(clamped.dy), g.columnAtX(clamped.dx));
    }
    return pane.cellAt(clamped);
  }

  /// Column whose right boundary is within 4 px of x.
  int? _colBoundary(double x) {
    final g = _g!;
    final col = g.columnAtX(x);
    final right = g.colX(col + 1);
    final left = g.colX(col);
    if ((x - right).abs() <= 4) return col;
    if ((x - left).abs() <= 4 && col > 0) {
      var prev = col - 1;
      while (prev > 0 && g.sheet.columns.sizeAt(prev) <= 0) {
        prev--;
      }
      return prev;
    }
    return null;
  }

  int? _rowBoundary(double y) {
    final g = _g!;
    final row = g.rowAtY(y);
    // Edges on screen (display order in a sorted filter view, 07 §4.4).
    final d = g.displayRow(row);
    final bottom = g.rowY(g.modelRow(d + 1));
    final top = g.rowY(row);
    if ((y - bottom).abs() <= 3) return row;
    if ((y - top).abs() <= 3 && d > 0) {
      var prev = d - 1;
      while (prev > 0 && g.sheet.rows.sizeAt(g.modelRow(prev)) <= 0) {
        prev--;
      }
      return g.modelRow(prev);
    }
    return null;
  }

  bool _onFillHandle(Offset p) {
    final g = _g;
    if (g == null || !c.canEdit || c.editor.isEditing) return false;
    final sel = c.selection.resolved;
    if (sel.ranges.length != 1) return false;
    if (c.rowsPermuted(sel.ranges.first.rect)) return false;
    final r = g.rangeRect(_clipRect(sel.ranges.first.rect));
    return (p - r.bottomRight).distance <= 6;
  }

  bool _onSelectionBorder(Offset p) {
    final g = _g;
    if (g == null || !c.canEdit || c.editor.isEditing) return false;
    final sel = c.selection.resolved;
    if (sel.ranges.length != 1) return false;
    if (sel.activeRange.kind != SelectionKind.cells) return false;
    if (c.rowsPermuted(sel.ranges.first.rect)) return false;
    final r = g.rangeRect(sel.ranges.first.rect);
    final outer = r.inflate(3);
    final inner = r.deflate(3);
    return outer.contains(p) && !inner.contains(p);
  }

  GridRect _clipRect(GridRect r) {
    final s = c.activeSheet!;
    return r.intersection(
          GridRect(0, 0, s.rows.length - 1, s.columns.length - 1),
        ) ??
        r;
  }

  bool _onFreezeBar(Offset p, {required bool rows}) {
    final g = _g;
    if (g == null) return false;
    if (rows) {
      return p.dx < g.rowHeaderWidth &&
          p.dy >= g.colHeaderHeight - HeaderLayer.freezeBar - 2 &&
          p.dy <= g.colHeaderHeight + 1;
    }
    return p.dy < g.colHeaderHeight &&
        p.dx >= g.rowHeaderWidth - HeaderLayer.freezeBar - 2 &&
        p.dx <= g.rowHeaderWidth + 1;
  }

  // ---------------------------------------------------------------------------
  // Pointer.

  bool _isDoubleClick(Offset p, {double slop = 6}) {
    final now = DateTime.now();
    final last = _lastDown;
    final lastPos = _lastDownPos;
    _lastDown = now;
    _lastDownPos = p;
    return last != null &&
        lastPos != null &&
        now.difference(last) < const Duration(milliseconds: 400) &&
        (p - lastPos).distance < slop;
  }

  /// A primary or secondary press (mouse, stylus; a touch tap or long
  /// press through [_touch]).
  void _press(PointerDownEvent e, {bool touch = false}) {
    final p = e.localPosition;
    final region = _region(p);
    final g = _g;
    if (region == null || g == null || c.activeSheet == null) return;
    _lastPointer = p;
    final secondary = e.buttons == kSecondaryMouseButton;
    final editor = c.editor;
    if (!editor.isEditing || !editor.pointEligible) {
      c.gridFocus.requestFocus();
    }
    if (secondary) {
      _onSecondary(e, region);
      return;
    }
    for (final h in c.gridHooks.hitHandlers) {
      if (h.onPointerDown(g, p, e)) return;
    }
    final dbl = _isDoubleClick(p, slop: touch ? kDoubleTapSlop : 6);

    if (region.corner) {
      if (_onFreezeBar(p, rows: true)) {
        _drag = _Drag.freezeRows;
      } else if (_onFreezeBar(p, rows: false)) {
        _drag = _Drag.freezeCols;
      } else {
        _commitIfEditing();
        unawaited(c.invokeCommand('sheets.select.all'));
      }
      return;
    }
    if (region.colHeader) {
      final b = _colBoundary(p.dx);
      if (b != null && _unhideAt(columns: true, index: b, p: p)) return;
      if (b != null) {
        if (dbl && c.canEdit) {
          unawaited(_autoFit(columns: true, index: b));
          return;
        }
        if (c.canEdit) {
          _drag = _Drag.resizeCol;
          _resizeIndex = b;
          _resizeStart = p.dx;
          _resizeOrigin = g.sheet.columns.naturalSizeAt(b);
          c.drag.value = ResizeDragFeedback(
            columns: true,
            index: b,
            size: _resizeOrigin,
          );
        }
        return;
      }
      final col = g.columnAtX(p.dx);
      if (editor.isEditing && editor.pointEligible) {
        editor.pointAt(
          GridRect(0, col, g.sheet.rows.length - 1, col),
          wholeColumns: true,
        );
        return;
      }
      _commitIfEditing();
      final selCols = c.selection.resolved;
      if (!_shift &&
          !_mod &&
          c.canEdit &&
          selCols.ranges.length == 1 &&
          selCols.activeRange.kind == SelectionKind.columns &&
          selCols.columnFullySelected(col)) {
        // Press on a selected column header: drag to move (03 §3).
        _drag = _Drag.moveCols;
        _dragSource = selCols.activeRange.rect;
        return;
      }
      if (_shift) {
        final a = _headerAnchor ?? (0, c.selection.resolved.anchorCol);
        c.selection.selectColumns(a.$2, col);
      } else {
        c.selection.selectColumns(col, col, add: _mod);
        _headerAnchor = (0, col);
      }
      _drag = _Drag.cols;
      return;
    }
    if (region.rowHeader) {
      final b = _rowBoundary(p.dy);
      if (b != null && _unhideAt(columns: false, index: b, p: p)) return;
      if (b != null) {
        if (dbl && c.canEdit) {
          unawaited(_autoFit(columns: false, index: b));
          return;
        }
        if (c.canEdit) {
          _drag = _Drag.resizeRow;
          _resizeIndex = b;
          _resizeStart = p.dy;
          _resizeOrigin = g.sheet.rows.naturalSizeAt(b);
          c.drag.value = ResizeDragFeedback(
            columns: false,
            index: b,
            size: _resizeOrigin,
          );
        }
        return;
      }
      final row = g.rowAtY(p.dy);
      if (editor.isEditing && editor.pointEligible) {
        editor.pointAt(
          GridRect(row, 0, row, g.sheet.columns.length - 1),
          wholeRows: true,
        );
        return;
      }
      _commitIfEditing();
      final selRows = c.selection.resolved;
      if (!_shift &&
          !_mod &&
          c.canEdit &&
          selRows.ranges.length == 1 &&
          selRows.activeRange.kind == SelectionKind.rows &&
          !c.rowsPermuted(selRows.activeRange.rect) &&
          selRows.rowFullySelected(row)) {
        _drag = _Drag.moveRows;
        _dragSource = selRows.activeRange.rect;
        return;
      }
      if (_shift) {
        final a = _headerAnchor ?? (c.selection.resolved.anchorRow, 0);
        c.selection.selectRows(a.$1, row);
      } else {
        c.selection.selectRows(row, row, add: _mod);
        _headerAnchor = (row, 0);
      }
      _drag = _Drag.rows;
      return;
    }

    // Cells.
    final cell = _cellAt(p);
    if (cell == null) return;
    final (row, col) = cell;
    if (editor.isEditing) {
      if (editor.pointEligible) {
        final anchor = editor.session?.pointAnchor;
        if (_shift && anchor != null && editor.isPointing) {
          editor.pointAt(GridRect.normalized(anchor.$1, anchor.$2, row, col));
          editor.session?.pointAnchor = anchor;
          _dragAnchor = anchor;
        } else {
          editor.pointAt(GridRect.cell(row, col), add: _mod);
          _dragAnchor = (row, col);
        }
        _drag = _Drag.point;
        return;
      }
      final t = editor.target;
      if (t != null &&
          t == (row, col) &&
          editor.session!.sheetId == c.activeSheetId) {
        return;
      }
      editor.commitSync();
    }
    if (c.paintFormat.value != null) {
      c.selection.selectCell(row, col);
      _drag = _Drag.paint;
      return;
    }
    if (_onFillHandle(p)) {
      if (dbl) {
        unawaited(c.invokeCommand('sheets.fill.autoFillDown'));
        return;
      }
      _drag = _Drag.fill;
      _dragSource = _clipRect(c.selection.resolved.activeRange.rect);
      return;
    }
    if (_onSelectionBorder(p)) {
      _drag = _Drag.move;
      _dragSource = c.selection.resolved.activeRange.rect;
      _dragAnchor = (row, col);
      return;
    }
    if (dbl && c.cellDoubleClickHandlers.any((h) => h(row, col))) return;
    if (dbl && c.canEdit) {
      final sel = c.selection.resolved;
      if (sel.activeRow == row && sel.activeCol == col ||
          (c.activeSheet!
                  .mergeAt(row, col)
                  ?.contains(sel.activeRow, sel.activeCol) ??
              false)) {
        unawaited(c.invokeCommand('sheets.cell.edit'));
        return;
      }
    }
    // Checkbox clicks (on the box) are handled by the in-cell hit handler
    // (`features/in_cell`, 03 §14.1).
    if (_shift) {
      c.selection.extendTo(row, col);
    } else {
      c.selection.selectCell(row, col, add: _mod);
    }
    c.tabStartCol = null;
    _drag = _Drag.select;
  }

  /// A click on the hidden-run arrows after header [index] unhides the run
  /// (03 §3).
  bool _unhideAt({
    required bool columns,
    required int index,
    required Offset p,
  }) {
    final g = _g!;
    final axis = columns ? g.sheet.columns : g.sheet.rows;
    if (!c.canEdit ||
        index + 1 >= axis.length ||
        !axis.isUserHidden(index + 1)) {
      return false;
    }
    final edge = columns ? g.colX(index + 1) : g.rowY(index + 1);
    final pos = columns ? p.dx : p.dy;
    if (pos > edge + 1 || pos < edge - 7) return false;
    final ids = <String>[];
    for (var i = index + 1; i < axis.length && axis.isUserHidden(i); i++) {
      ids.add(axis.idAt(i));
    }
    unawaited(
      c.invokeCommand(columns ? 'sheets.cols.unhide' : 'sheets.rows.unhide', {
        'ids': ids,
      }),
    );
    return true;
  }

  void _commitIfEditing() {
    if (c.editor.isEditing) c.editor.commitSync();
  }

  void _onSecondary(
    PointerDownEvent e,
    ({bool colHeader, bool rowHeader, bool corner}) region,
  ) {
    final g = _g!;
    final p = e.localPosition;
    _commitIfEditing();
    GridMenuKind kind;
    final sel = c.selection.resolved;
    if (region.corner) {
      kind = GridMenuKind.corner;
    } else if (region.colHeader) {
      final col = g.columnAtX(p.dx);
      if (!sel.columnFullySelected(col)) c.selection.selectColumns(col, col);
      kind = GridMenuKind.columnHeader;
    } else if (region.rowHeader) {
      final row = g.rowAtY(p.dy);
      if (!sel.rowFullySelected(row)) c.selection.selectRows(row, row);
      kind = GridMenuKind.rowHeader;
    } else {
      final cell = _cellAt(p);
      if (cell != null && !sel.contains(cell.$1, cell.$2)) {
        c.selection.selectCell(cell.$1, cell.$2);
      }
      kind = GridMenuKind.cell;
    }
    widget.onContextMenu?.call(kind, e.position);
  }

  void _onDown(PointerDownEvent e) {
    _stopFling();
    // The read-only mobile layout (suite 02 §6.1, T-1) has no cell
    // selection: every pointer (also a mouse in a narrow window) pans the
    // grid like a finger, and taps and long presses do nothing.
    final readOnlyView = c.readOnlyView;
    _touch.longPressEnabled = !readOnlyView;
    if (readOnlyView) {
      if (e.kind == PointerDeviceKind.touch || e.buttons == kPrimaryButton) {
        _touch.down(e);
      }
      return;
    }
    if (e.kind == PointerDeviceKind.touch) {
      _touch.down(e);
      return;
    }
    _press(e);
  }

  void _onMove(PointerMoveEvent e) {
    if (_touch.tracks(e.pointer)) {
      _touch.move(e);
      return;
    }
    _dragTo(e);
  }

  void _onUp(PointerUpEvent e) {
    if (_touch.tracks(e.pointer)) {
      _touch.up(e);
      return;
    }
    _release();
  }

  /// The OS or browser took the pointer (focus lost, system gesture): the
  /// drag in progress is aborted, not committed (S-08).
  void _onCancel(PointerCancelEvent e) {
    if (_touch.tracks(e.pointer)) {
      _touch.cancel(e);
      return;
    }
    _cancelDrag();
  }

  void _dragTo(PointerMoveEvent e) {
    if (_drag == _Drag.none) return;
    _lastPointer = e.localPosition;
    _applyDrag(e.localPosition);
    _ensureAutoScroll();
  }

  /// Ends the drag in progress without invoking its command: no fill,
  /// move, resize, freeze or paint format is written.
  void _cancelDrag() {
    final drag = _drag;
    _drag = _Drag.none;
    if (drag == _Drag.move) _setCursor(SystemMouseCursors.cell);
    _autoScroll?.cancel();
    _autoScroll = null;
    c.drag.value = null;
    _dragSource = null;
  }

  // ---------------------------------------------------------------------------
  // Touch (S-01): a tap selects, one finger scrolls with momentum, a long
  // press then drag selects a range (or fills, moves, resizes), two fingers
  // pinch-zoom (50–200 %).

  late final GridTouchTracker _touch = GridTouchTracker(
    onTap: (down, up) {
      if (c.readOnlyView) return;
      _press(down, touch: true);
      _release();
    },
    onLongPress: (down) {
      if (!c.readOnlyView) _press(down, touch: true);
    },
    onDragMove: _dragTo,
    onDragEnd: (_) => _release(),
    onDragCancel: _cancelDrag,
    onPan: (delta) => c.scroll.scrollBy(-delta.dx, -delta.dy),
    onFling: _startFling,
    onPinchStart: () => _pinchZoom = c.scroll.zoom,
    onPinchUpdate: (scale, focal, focalDelta) {
      c.scroll.scrollBy(-focalDelta.dx, -focalDelta.dy);
      final z = (_pinchZoom * scale).clamp(
        GridScrollController.minZoom,
        GridScrollController.maxZoom,
      );
      if ((z * 20).round() / 20 != c.scroll.zoom) _zoomAround(z, focal);
    },
  );

  double _pinchZoom = 1;
  Ticker? _fling;
  ClampingScrollSimulation? _flingX;
  ClampingScrollSimulation? _flingY;
  Offset _flingLast = Offset.zero;

  /// Scrolls on after a touch pan with the finger's [velocity].
  void _startFling(Velocity velocity) {
    _stopFling();
    final v = -velocity.pixelsPerSecond;
    if (v.distance < kMinFlingVelocity) return;
    final sx = ClampingScrollSimulation(position: 0, velocity: v.dx);
    final sy = ClampingScrollSimulation(position: 0, velocity: v.dy);
    _flingX = sx;
    _flingY = sy;
    _flingLast = Offset.zero;
    final ticker = _fling ??= createTicker(_onFlingTick);
    ticker.start();
  }

  void _onFlingTick(Duration elapsed) {
    final sx = _flingX;
    final sy = _flingY;
    if (sx == null || sy == null) return;
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final at = Offset(sx.x(t), sy.x(t));
    final delta = at - _flingLast;
    _flingLast = at;
    final before = Offset(c.scroll.x, c.scroll.y);
    c.scroll.scrollBy(delta.dx, delta.dy);
    final moved = Offset(c.scroll.x, c.scroll.y) != before;
    // Done, or stopped by the edges of the sheet.
    if ((sx.isDone(t) && sy.isDone(t)) || (!moved && delta.distance > 0.5)) {
      _stopFling();
    }
  }

  void _stopFling() {
    _flingX = null;
    _flingY = null;
    final f = _fling;
    if (f != null && f.isActive) f.stop();
  }

  void _applyDrag(Offset p) {
    final g = _g;
    if (g == null) return;
    switch (_drag) {
      case _Drag.none:
        break;
      case _Drag.select || _Drag.paint:
        final cell = _cellAt(p);
        if (cell != null) c.selection.extendTo(cell.$1, cell.$2);
      case _Drag.point:
        final cell = _cellAt(p);
        final a = _dragAnchor;
        if (cell != null && a != null) {
          c.editor.pointAt(GridRect.normalized(a.$1, a.$2, cell.$1, cell.$2));
          c.editor.session?.pointAnchor = a;
        }
      case _Drag.rows:
        final row = g.rowAtY(p.dy);
        final a = _headerAnchor;
        if (a != null) c.selection.selectRows(a.$1, row);
      case _Drag.cols:
        final col = g.columnAtX(p.dx);
        final a = _headerAnchor;
        if (a != null) c.selection.selectColumns(a.$2, col);
      case _Drag.fill:
        final src = _dragSource;
        final cell = _cellAt(p);
        if (src == null || cell == null) return;
        final (row, col) = cell;
        GridRect? target;
        final dDown = row - src.bottom;
        final dUp = src.top - row;
        final dRight = col - src.right;
        final dLeft = src.left - col;
        final vert = math.max(dDown, dUp);
        final horiz = math.max(dRight, dLeft);
        if (vert <= 0 && horiz <= 0) {
          target = null;
        } else if (vert >= horiz) {
          target = dDown > 0
              ? GridRect(src.top, src.left, row, src.right)
              : GridRect(row, src.left, src.bottom, src.right);
        } else {
          target = dRight > 0
              ? GridRect(src.top, src.left, src.bottom, col)
              : GridRect(src.top, col, src.bottom, src.right);
        }
        c.drag.value = target == null ? null : FillDragFeedback(target);
      case _Drag.move:
        final src = _dragSource;
        final a = _dragAnchor;
        final cell = _cellAt(p);
        if (src == null || a == null || cell == null) return;
        final s = c.activeSheet!;
        final dr = (cell.$1 - a.$1).clamp(
          -src.top,
          s.rows.length - 1 - src.bottom,
        );
        final dc = (cell.$2 - a.$2).clamp(
          -src.left,
          s.columns.length - 1 - src.right,
        );
        final copy = _alt || _mod;
        c.drag.value = dr == 0 && dc == 0
            ? null
            : MoveDragFeedback(src.shift(dr, dc), copy: copy);
        // Drag-copy shows the "+" cursor (03 §11).
        _setCursor(
          copy ? SystemMouseCursors.copy : SystemMouseCursors.grabbing,
        );
      case _Drag.moveCols || _Drag.moveRows:
        final columns = _drag == _Drag.moveCols;
        final axis = columns ? g.sheet.columns : g.sheet.rows;
        final at = columns ? g.columnAtX(p.dx) : g.rowAtY(p.dy);
        final start = columns ? g.colX(at) : g.rowY(at);
        final size = axis.sizeAt(at) * g.zoom;
        final pos = columns ? p.dx : p.dy;
        final before = pos > start + size / 2 ? at + 1 : at;
        c.drag.value = HeaderMoveDragFeedback(columns: columns, before: before);
      case _Drag.resizeCol:
        final size = math.max(
          2.0,
          _resizeOrigin + (p.dx - _resizeStart) / g.zoom,
        );
        c.drag.value = ResizeDragFeedback(
          columns: true,
          index: _resizeIndex,
          size: size,
        );
      case _Drag.resizeRow:
        final size = math.max(
          2.0,
          _resizeOrigin + (p.dy - _resizeStart) / g.zoom,
        );
        c.drag.value = ResizeDragFeedback(
          columns: false,
          index: _resizeIndex,
          size: size,
        );
      case _Drag.freezeRows:
        final y = p.dy - g.colHeaderHeight;
        final count = y <= 4 ? 0 : g.rowAtY(p.dy) + 1;
        c.drag.value = FreezeDragFeedback(
          rows: true,
          count: math.min(count, g.sheet.rows.length - 1),
        );
      case _Drag.freezeCols:
        final x = p.dx - g.rowHeaderWidth;
        final count = x <= 4 ? 0 : g.columnAtX(p.dx) + 1;
        c.drag.value = FreezeDragFeedback(
          rows: false,
          count: math.min(count, g.sheet.columns.length - 1),
        );
    }
  }

  /// The end of a press: commits the drag in progress.
  void _release() {
    final drag = _drag;
    _drag = _Drag.none;
    if (drag == _Drag.move) _setCursor(SystemMouseCursors.cell);
    _autoScroll?.cancel();
    _autoScroll = null;
    final fb = c.drag.value;
    c.drag.value = null;
    final s = c.activeSheet;
    if (s == null) return;
    switch (drag) {
      case _Drag.fill:
        if (fb is FillDragFeedback && _dragSource != null) {
          unawaited(
            c.invokeCommand('sheets.fill.series', {
              'source': _dragSource!.a1,
              'target': fb.target.a1,
              'mode': _alt ? 'copy' : 'auto',
            }),
          );
        }
      case _Drag.move:
        if (fb is MoveDragFeedback && _dragSource != null) {
          unawaited(
            c.invokeCommand('sheets.cells.moveRange', {
              'source': _dragSource!.a1,
              'destTopLeft': GridRect.cell(fb.target.top, fb.target.left).a1,
              if (fb.copy) 'copy': true,
            }),
          );
        }
      case _Drag.moveCols || _Drag.moveRows:
        final src = _dragSource;
        if (fb is HeaderMoveDragFeedback && src != null) {
          final columns = fb.columns;
          final lo = columns ? src.left : src.top;
          final hi = columns ? src.right : src.bottom;
          final axis = columns ? s.columns : s.rows;
          if (fb.before < lo || fb.before > hi + 1) {
            unawaited(
              c.invokeCommand(
                columns ? 'sheets.cols.move' : 'sheets.rows.move',
                {
                  'ids': [for (var i = lo; i <= hi; i++) axis.idAt(i)],
                  'before': fb.before < axis.length
                      ? axis.idAt(fb.before)
                      : null,
                },
              ),
            );
          }
        }
      case _Drag.resizeCol:
        if (fb is ResizeDragFeedback) _resize(columns: true, fb: fb);
      case _Drag.resizeRow:
        if (fb is ResizeDragFeedback) _resize(columns: false, fb: fb);
      case _Drag.freezeRows:
        if (fb is FreezeDragFeedback) {
          unawaited(
            c.invokeCommand('sheets.view.freezeRows', {'count': fb.count}),
          );
        }
      case _Drag.freezeCols:
        if (fb is FreezeDragFeedback) {
          unawaited(
            c.invokeCommand('sheets.view.freezeColumns', {'count': fb.count}),
          );
        }
      case _Drag.paint:
        final pf = c.paintFormat.value;
        if (pf != null) {
          unawaited(
            c.invokeCommand('sheets.format.applyPaintFormat', {
              'source': pf.source.a1,
              'target': c.selection.resolved.activeRange.rect.a1,
            }),
          );
        }
      default:
        break;
    }
    _dragSource = null;
  }

  void _resize({required bool columns, required ResizeDragFeedback fb}) {
    final s = c.activeSheet!;
    final sel = c.selection.resolved;
    final axis = columns ? s.columns : s.rows;
    // All fully selected rows/cols get the size when the dragged header is
    // part of the selection (03 §3).
    final full = columns
        ? sel.columnFullySelected(fb.index)
        : sel.rowFullySelected(fb.index);
    final ids = <String>[];
    if (full) {
      for (final r in sel.ranges) {
        if (columns ? !r.wholeColumns : !r.wholeRows) continue;
        final lo = columns ? r.rect.left : r.rect.top;
        final hi = columns ? r.rect.right : r.rect.bottom;
        for (var i = lo; i <= hi; i++) {
          ids.add(axis.idAt(i));
        }
      }
    } else {
      ids.add(axis.idAt(fb.index));
    }
    unawaited(
      c.invokeCommand(columns ? 'sheets.cols.resize' : 'sheets.rows.resize', {
        'ids': ids,
        'size': fb.size.roundToDouble(),
      }),
    );
  }

  Future<void> _autoFit({required bool columns, required int index}) async {
    final s = c.activeSheet!;
    final axis = columns ? s.columns : s.rows;
    await c.invokeCommand(
      columns ? 'sheets.cols.autoFit' : 'sheets.rows.autoFit',
      {
        'ids': [axis.idAt(index)],
      },
    );
  }

  void _ensureAutoScroll() {
    if (_autoScroll != null) return;
    _autoScroll = Timer.periodic(const Duration(milliseconds: 40), (_) {
      final p = _lastPointer;
      final g = _g;
      if (p == null || g == null || _drag == _Drag.none) {
        _autoScroll?.cancel();
        _autoScroll = null;
        return;
      }
      if (_drag == _Drag.resizeCol ||
          _drag == _Drag.resizeRow ||
          _drag == _Drag.freezeCols ||
          _drag == _Drag.freezeRows) {
        return;
      }
      final r = g.main.rect;
      double dx = 0;
      double dy = 0;
      const edge = 24.0;
      if (p.dx > r.right - edge) {
        dx = (p.dx - (r.right - edge)).clamp(0, 80).toDouble();
      }
      if (p.dx < r.left + edge && _drag != _Drag.rows) {
        dx = -((r.left + edge) - p.dx).clamp(0, 80).toDouble();
      }
      if (p.dy > r.bottom - edge) {
        dy = (p.dy - (r.bottom - edge)).clamp(0, 80).toDouble();
      }
      if (p.dy < r.top + edge && _drag != _Drag.cols) {
        dy = -((r.top + edge) - p.dy).clamp(0, 80).toDouble();
      }
      if (dx == 0 && dy == 0) return;
      c.scroll.scrollBy(dx, dy);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (_drag != _Drag.none && _lastPointer != null) {
          _applyDrag(_lastPointer!);
        }
      });
    });
  }

  void _onSignal(PointerSignalEvent e) {
    if (e is PointerScrollEvent) {
      GestureBinding.instance.pointerSignalResolver.register(e, (event) {
        final s = event as PointerScrollEvent;
        if (_mod) {
          final factor = s.scrollDelta.dy < 0 ? 1.05 : 1 / 1.05;
          _zoomAround(c.scroll.zoom * factor, s.localPosition);
          return;
        }
        var dx = s.scrollDelta.dx;
        var dy = s.scrollDelta.dy;
        if (_shift && dx == 0) {
          dx = dy;
          dy = 0;
        }
        c.scroll.scrollBy(dx, dy);
      });
    } else if (e is PointerScaleEvent) {
      _zoomAround(c.scroll.zoom * e.scale, e.localPosition);
    }
  }

  void _zoomAround(double zoom, Offset p) {
    final g = _g;
    final focal = g == null
        ? Offset.zero
        : Offset(
            math.max(0, p.dx - g.main.rect.left),
            math.max(0, p.dy - g.main.rect.top),
          );
    final z = (zoom * 20).round() / 20;
    c.scroll.setZoom(z, focal: focal);
    c.notifyZoom();
  }

  double _lastScale = 1;

  void _onPanZoomStart(PointerPanZoomStartEvent e) => _lastScale = 1;

  void _onPanZoomUpdate(PointerPanZoomUpdateEvent e) {
    if ((e.scale - 1).abs() > 0.01) {
      final f = e.scale / _lastScale;
      _lastScale = e.scale;
      _zoomAround(c.scroll.zoom * f, e.localPosition);
      return;
    }
    c.scroll.scrollBy(-e.panDelta.dx, -e.panDelta.dy);
  }

  void _onHover(PointerHoverEvent e) {
    final p = e.localPosition;
    final region = _region(p);
    if (region == null) return;
    _setHover(
      region.corner || region.colHeader || region.rowHeader ? null : _cellAt(p),
    );
    MouseCursor cursor = SystemMouseCursors.cell;
    if (region.corner) {
      cursor = _onFreezeBar(p, rows: true)
          ? SystemMouseCursors.resizeRow
          : _onFreezeBar(p, rows: false)
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.basic;
    } else if (region.colHeader) {
      cursor = c.canEdit && _colBoundary(p.dx) != null
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.basic;
    } else if (region.rowHeader) {
      cursor = c.canEdit && _rowBoundary(p.dy) != null
          ? SystemMouseCursors.resizeRow
          : SystemMouseCursors.basic;
    } else if (_onFillHandle(p)) {
      cursor = SystemMouseCursors.precise;
    } else if (_onSelectionBorder(p)) {
      cursor = SystemMouseCursors.grab;
    }
    final g = _g;
    if (g != null) {
      for (final h in c.gridHooks.hitHandlers) {
        final hc = h.cursorAt(g, p);
        if (hc != null) {
          cursor = hc;
          break;
        }
      }
    }
    _setCursor(cursor);
  }

  void _setCursor(MouseCursor cursor) {
    if (mounted) _cursor.value = cursor;
  }

  /// Pressing or releasing the copy modifier mid-drag switches move ⇄ copy
  /// without moving the pointer.
  bool _onModifierKey(KeyEvent e) {
    if (_drag == _Drag.move && _lastPointer != null) {
      final k = e.logicalKey;
      if (k == LogicalKeyboardKey.altLeft ||
          k == LogicalKeyboardKey.altRight ||
          k == LogicalKeyboardKey.metaLeft ||
          k == LogicalKeyboardKey.metaRight ||
          k == LogicalKeyboardKey.controlLeft ||
          k == LogicalKeyboardKey.controlRight) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _drag == _Drag.move && _lastPointer != null) {
            _applyDrag(_lastPointer!);
          }
        });
        WidgetsBinding.instance.scheduleFrame();
      }
    }
    return false;
  }

  /// Publishes the hovered cell (hover cards, 03 §14).
  void _setHover((int, int)? cell) {
    final hover = c.gridHooks.hover;
    final next = cell == null
        ? null
        : (sheetId: c.activeSheetId, row: cell.$1, col: cell.$2);
    if (hover.value != next) hover.value = next;
  }

  // ---------------------------------------------------------------------------
  // Keyboard: typing starts editing (03 §7.2).

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final kb = HardwareKeyboard.instance;
    if (kb.isControlPressed || kb.isMetaPressed || kb.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final ch = e.character;
    if (ch == null || ch.isEmpty) return KeyEventResult.ignored;
    final code = ch.codeUnitAt(0);
    if (code < 0x20 || code == 0x7f) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.space && kb.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    if (e.logicalKey == LogicalKeyboardKey.space) {
      final d = c.activeDisplay();
      if (d?.widget.kind == CellWidgetKind.checkbox) {
        return KeyEventResult.ignored;
      }
    }
    if (!c.canEdit) return KeyEventResult.ignored;
    // Ready state: the text input of the focused cell editor field takes
    // the character (and starts the session).
    if (c.editor.cellFocus.hasFocus) return KeyEventResult.ignored;
    if (c.editor.isEditing) {
      c.editor.appendTyped(ch);
    } else {
      c.editor.begin(initialText: ch, mode: EditMode.enter);
    }
    return KeyEventResult.handled;
  }

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final tokens = GridPaintTokens.ofContext(context);
    return ListenableBuilder(
      listenable: c.layers,
      builder: (context, _) {
        final content = [...coreContentLayers(), ...c.layers.content]
          ..sort((a, b) => a.zOrder.compareTo(b.zOrder));
        final overlay = [...coreOverlayLayers(), ...c.layers.overlay]
          ..sort((a, b) => a.zOrder.compareTo(b.zOrder));
        return Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _gridKeys,
          child: Focus(
            focusNode: c.gridFocus,
            autofocus: true,
            onKeyEvent: _onKey,
            child: Semantics(
              label: c.l10n.gridSemanticsLabel(c.activeSheet?.name ?? ''),
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned.fill(
                      child: ValueListenableBuilder<MouseCursor>(
                        valueListenable: _cursor,
                        builder: (context, cursor, child) => MouseRegion(
                          cursor: cursor,
                          onHover: _onHover,
                          onExit: (_) => _setHover(null),
                          child: child,
                        ),
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: _onDown,
                          onPointerMove: _onMove,
                          onPointerUp: _onUp,
                          onPointerCancel: _onCancel,
                          onPointerSignal: _onSignal,
                          onPointerPanZoomStart: _onPanZoomStart,
                          onPointerPanZoomUpdate: _onPanZoomUpdate,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: GridPass(
                                  key: const ValueKey<String>(
                                    'sheets.grid.content',
                                  ),
                                  controller: c,
                                  tokens: tokens,
                                  overlay: false,
                                  layers: content,
                                  repaint: Listenable.merge([
                                    c.contentSignal,
                                    c.scroll,
                                    ...c.layers.repaintsOf(overlay: false),
                                  ]),
                                ),
                              ),
                              Positioned.fill(
                                child: GridPass(
                                  key: const ValueKey<String>(
                                    'sheets.grid.overlay',
                                  ),
                                  controller: c,
                                  tokens: tokens,
                                  overlay: true,
                                  layers: overlay,
                                  repaint: Listenable.merge([
                                    c.overlaySignal,
                                    c.scroll,
                                    c.antsPhase,
                                    ...c.layers.repaintsOf(overlay: true),
                                  ]),
                                ),
                              ),
                              // Visible cells for screen readers (03 §18).
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: GridSemantics(
                                    controller: c,
                                    l10n: c.l10n,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final w in c.layers.widgets) w(context),
                    CellEditorOverlay(controller: c, tokens: tokens),
                    ValueListenableBuilder(
                      valueListenable: c.gridHooks.overlays,
                      builder: (context, overlays, _) => Positioned.fill(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [for (final b in overlays) b(context)],
                        ),
                      ),
                    ),
                    _AddRowsFooter(controller: c),
                    _Scrollbars(controller: c, tokens: tokens),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin scrollbars (03 §5) with draggable thumbs.
class _Scrollbars extends StatelessWidget {
  const _Scrollbars({required this.controller, required this.tokens});

  final SheetEditorController controller;
  final GridPaintTokens tokens;

  @override
  Widget build(BuildContext context) {
    final s = controller.scroll;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final g = controller.geometry;
        if (g == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) (context as Element).markNeedsBuild();
          });
          return const SizedBox.shrink();
        }
        final main = g.main.rect;
        final children = <Widget>[];
        const thickness = 8.0;
        final contentH = g.contentHeight;
        if (contentH > main.height + 1) {
          final frac = (main.height / contentH).clamp(0.05, 1.0);
          final track = main.height - thickness;
          final thumb = math.max(24.0, track * frac);
          final pos = s.maxY <= 0 || !s.maxY.isFinite
              ? 0.0
              : (s.y / s.maxY) * (track - thumb);
          children.add(
            Positioned(
              right: 0,
              top: main.top + pos,
              width: thickness,
              height: thumb,
              child: _Thumb(
                key: const ValueKey<String>('sheets.grid.vscroll'),
                color: tokens.headerFg.withValues(alpha: 0.35),
                onDrag: (d) {
                  if (!s.maxY.isFinite) return;
                  s.scrollBy(0, d.dy / math.max(1, track - thumb) * s.maxY);
                },
              ),
            ),
          );
        }
        final contentW = g.contentWidth;
        if (contentW > main.width + 1) {
          final frac = (main.width / contentW).clamp(0.05, 1.0);
          final track = main.width - thickness;
          final thumb = math.max(24.0, track * frac);
          final pos = s.maxX <= 0 || !s.maxX.isFinite
              ? 0.0
              : (s.x / s.maxX) * (track - thumb);
          children.add(
            Positioned(
              bottom: 0,
              left: main.left + pos,
              height: thickness,
              width: thumb,
              child: _Thumb(
                key: const ValueKey<String>('sheets.grid.hscroll'),
                color: tokens.headerFg.withValues(alpha: 0.35),
                onDrag: (d) {
                  if (!s.maxX.isFinite) return;
                  s.scrollBy(d.dx / math.max(1, track - thumb) * s.maxX, 0);
                },
              ),
            ),
          );
        }
        return Stack(children: children);
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({super.key, required this.color, required this.onDrag});

  final Color color;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.basic,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) => onDrag(d.delta),
      child: Padding(
        padding: const EdgeInsets.all(1.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    ),
  );
}

/// "Add [1000] more rows at bottom" after the last row (03 §5).
class _AddRowsFooter extends StatefulWidget {
  const _AddRowsFooter({required this.controller});

  final SheetEditorController controller;

  @override
  State<_AddRowsFooter> createState() => _AddRowsFooterState();
}

class _AddRowsFooterState extends State<_AddRowsFooter> {
  final _count = TextEditingController(text: '1000');
  final _focus = FocusNode(debugLabel: 'sheets.addRows.count');

  @override
  void dispose() {
    _count.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final n = int.tryParse(_count.text.trim()) ?? 0;
    if (n < 1) return;
    unawaited(
      widget.controller.invokeCommand('sheets.rows.addMore', {'count': n}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: Listenable.merge([c.scroll, c.contentSignal]),
      builder: (context, _) {
        final g = c.geometry;
        if (g == null || !c.canEdit) return const SizedBox.shrink();
        final last = g.sheet.rows.length;
        if (g.main.rowEnd < last - 1) return const SizedBox.shrink();
        final top = g.main.y(last) + 8;
        if (top > g.size.height - 36) return const SizedBox.shrink();
        final theme = ShadTheme.of(context);
        final l = c.l10n;
        return Positioned(
          left: g.rowHeaderWidth + 8,
          top: top,
          child: Row(
            key: const ValueKey<String>('sheets.addRows'),
            mainAxisSize: MainAxisSize.min,
            children: [
              ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: _add,
                child: Text(l.addRowsButton),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                height: 30,
                child: ShadInput(
                  controller: _count,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: 8),
              Text(l.addRowsSuffix, style: theme.textTheme.small),
            ],
          ),
        );
      },
    );
  }
}
