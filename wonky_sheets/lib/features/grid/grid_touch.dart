import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';

/// What a touch sequence on the grid is doing.
enum GridTouchPhase {
  /// No finger down.
  none,

  /// One finger down, not moved past the slop: a tap or a long press.
  pending,

  /// One finger drags: the grid scrolls (and flings on release).
  pan,

  /// A long press started a grid drag (select a range, fill, move,
  /// resize): moves go to the grid's drag.
  drag,

  /// Two fingers: pinch zoom and two-finger pan.
  pinch,

  /// The gesture is over for the grid (a finger lifted during a pinch);
  /// waits until every finger is up.
  done,
}

/// Turns raw touch pointer events of the grid into gestures (S-01): a tap
/// selects (as a click), one finger scrolls with momentum, a long press
/// then drag runs the grid's pointer drag (range selection, fill, move,
/// resize), two fingers pinch-zoom. Mouse, stylus and trackpad input don't
/// come here, except in the read-only mobile layout (T-1), where every
/// pointer pans and taps and long presses do nothing.
///
/// The grid is one raw `Listener` (no gesture arena), so this tracks the
/// pointers itself.
class GridTouchTracker {
  GridTouchTracker({
    required this.onTap,
    required this.onLongPress,
    required this.onDragMove,
    required this.onDragEnd,
    required this.onDragCancel,
    required this.onPan,
    required this.onFling,
    required this.onPinchStart,
    required this.onPinchUpdate,
    this.longPressTimeout = kLongPressTimeout,
  });

  /// A tap: [down] and [up] of the same finger, within the slop.
  final void Function(PointerDownEvent down, PointerUpEvent up) onTap;

  /// The finger of [down] stayed for [longPressTimeout]: start the grid's
  /// drag at it.
  final void Function(PointerDownEvent down) onLongPress;

  /// A move of the long-pressed finger.
  final void Function(PointerMoveEvent e) onDragMove;

  /// The long-pressed finger lifted: commit the drag.
  final void Function(PointerUpEvent e) onDragEnd;

  /// The long-press drag was cancelled (pointer cancel, a second finger):
  /// abort it without committing.
  final void Function() onDragCancel;

  /// Scroll the content with the finger (local delta of the finger).
  final void Function(Offset delta) onPan;

  /// The panning finger lifted with [velocity] (finger direction).
  final void Function(Velocity velocity) onFling;

  /// Two fingers are down.
  final void Function() onPinchStart;

  /// [scale] relative to the pinch start, around [focal] (local), and the
  /// focal point's move since the last update ([focalDelta]).
  final void Function(double scale, Offset focal, Offset focalDelta)
  onPinchUpdate;

  final Duration longPressTimeout;

  /// Whether a long press starts the grid's drag. Off in the read-only
  /// mobile layout (T-1): there a held finger that moves still pans.
  bool longPressEnabled = true;

  GridTouchPhase _phase = GridTouchPhase.none;
  GridTouchPhase get phase => _phase;

  /// Local positions of the fingers down, by pointer id.
  final Map<int, Offset> _fingers = {};
  PointerDownEvent? _down;
  Timer? _longPress;
  VelocityTracker? _velocity;
  double _pinchStartDistance = 0;
  Offset _lastFocal = Offset.zero;

  /// Whether [pointer] belongs to the touch gesture in progress.
  bool tracks(int pointer) => _fingers.containsKey(pointer);

  void down(PointerDownEvent e) {
    _fingers[e.pointer] = e.localPosition;
    switch (_fingers.length) {
      case 1:
        _phase = GridTouchPhase.pending;
        _down = e;
        _velocity = VelocityTracker.withKind(e.kind)
          ..addPosition(e.timeStamp, e.position);
        _longPress?.cancel();
        _longPress = longPressEnabled
            ? Timer(longPressTimeout, _onLongPressTimer)
            : null;
      case 2:
        _longPress?.cancel();
        if (_phase == GridTouchPhase.drag) onDragCancel();
        if (_phase == GridTouchPhase.done) return;
        _phase = GridTouchPhase.pinch;
        _pinchStartDistance = _distance();
        _lastFocal = _focal();
        onPinchStart();
      default:
      // A third finger is ignored.
    }
  }

  void _onLongPressTimer() {
    _longPress = null;
    final d = _down;
    if (_phase != GridTouchPhase.pending || d == null) return;
    _phase = GridTouchPhase.drag;
    onLongPress(d);
  }

  void move(PointerMoveEvent e) {
    final last = _fingers[e.pointer];
    if (last == null) return;
    _fingers[e.pointer] = e.localPosition;
    switch (_phase) {
      case GridTouchPhase.pending:
        _velocity?.addPosition(e.timeStamp, e.position);
        final from = _down!.localPosition;
        if ((e.localPosition - from).distance <= kTouchSlop) return;
        _longPress?.cancel();
        _phase = GridTouchPhase.pan;
        onPan(e.localPosition - from);
      case GridTouchPhase.pan:
        _velocity?.addPosition(e.timeStamp, e.position);
        onPan(e.localPosition - last);
      case GridTouchPhase.drag:
        onDragMove(e);
      case GridTouchPhase.pinch:
        if (_fingers.length < 2) return;
        final focal = _focal();
        final delta = focal - _lastFocal;
        _lastFocal = focal;
        final scale = _pinchStartDistance <= 0
            ? 1.0
            : _distance() / _pinchStartDistance;
        onPinchUpdate(scale, focal, delta);
      case GridTouchPhase.none || GridTouchPhase.done:
        break;
    }
  }

  void up(PointerUpEvent e) {
    if (_fingers.remove(e.pointer) == null) return;
    switch (_phase) {
      case GridTouchPhase.pending:
        _longPress?.cancel();
        final d = _down;
        if (d != null && d.pointer == e.pointer) onTap(d, e);
      case GridTouchPhase.pan:
        _velocity?.addPosition(e.timeStamp, e.position);
        final v = _velocity?.getVelocity() ?? Velocity.zero;
        onFling(v.clampMagnitude(0, kMaxFlingVelocity));
      case GridTouchPhase.drag:
        onDragEnd(e);
      case GridTouchPhase.pinch:
        // The other finger doesn't start a new gesture.
        _phase = GridTouchPhase.done;
      case GridTouchPhase.none || GridTouchPhase.done:
        break;
    }
    if (_fingers.isEmpty) _reset();
  }

  void cancel(PointerCancelEvent e) {
    if (_fingers.remove(e.pointer) == null) return;
    _longPress?.cancel();
    if (_phase == GridTouchPhase.drag) onDragCancel();
    _phase = _fingers.isEmpty ? GridTouchPhase.none : GridTouchPhase.done;
    if (_fingers.isEmpty) _reset();
  }

  void _reset() {
    _longPress?.cancel();
    _longPress = null;
    _phase = GridTouchPhase.none;
    _down = null;
    _velocity = null;
  }

  void dispose() {
    _longPress?.cancel();
    _longPress = null;
    _fingers.clear();
    _phase = GridTouchPhase.none;
  }

  Offset _focal() {
    final it = _fingers.values.take(2).toList();
    return (it[0] + it[1]) / 2;
  }

  double _distance() {
    final it = _fingers.values.take(2).toList();
    return math.max(1, (it[0] - it[1]).distance);
  }
}
