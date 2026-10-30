import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import 'menu_entry.dart';
import 'menu_items.dart';
import 'menu_placement.dart';

/// Hosts programmatic menus (context menus) anchored at a global position
/// inside [child]: `WonkyPopupMenuHost.maybeOf(context)?.show(pos, entries)`.
class WonkyPopupMenuHost extends StatefulWidget {
  const WonkyPopupMenuHost({super.key, required this.child});

  final Widget child;

  static WonkyPopupMenuHostState? maybeOf(BuildContext context) =>
      context.findAncestorStateOfType<WonkyPopupMenuHostState>();

  @override
  State<WonkyPopupMenuHost> createState() => WonkyPopupMenuHostState();
}

class WonkyPopupMenuHostState extends State<WonkyPopupMenuHost> {
  final _controller = ShadContextMenuController();
  Offset? _at;

  /// Where the user asked for the menu; [_at] is the anchor handed to shad.
  Offset? _requested;
  List<WonkyMenuEntry> Function()? _entries;

  /// The entries of the open menu, built once when it opens: the menu takes
  /// the keyboard focus, and entries built again after that (the placement
  /// rebuild) lost state of the focused widget — a text editor clears its
  /// selection on blur, so Slides' spelling suggestions vanished.
  List<WonkyMenuEntry>? _built;
  VoidCallback? _onClosed;
  bool _wasOpen = false;

  /// Whether the open menu has been moved to its final position (shad
  /// centres global-anchored overlays on the anchor; a context menu opens
  /// with its top-left corner at the pointer, 03 §10).
  bool _placed = false;
  final _probe = GlobalKey(debugLabel: 'WonkyPopupMenuHost.probe');
  final _items = GlobalKey(debugLabel: 'WonkyPopupMenuHost.items');

  /// Space kept between the menu and the screen edges.
  static const _margin = WonkyMenuPlacement.margin;

  /// shad's vertical menu padding (4 px top and bottom) plus its 1 px border.
  static const _chrome = WonkyMenuPlacement.chrome;

  /// The top of a menu of height [height] asked for at [pointerY] on a screen
  /// of height [screen] (03 §10): below the pointer when it fits, else ending
  /// at the pointer, else shifted up just enough to stay on screen (menus
  /// taller than the screen scroll).
  @visibleForTesting
  static double topFor(double pointerY, double height, double screen) {
    if (pointerY + height <= screen - _margin) return pointerY;
    if (pointerY - height >= _margin) return pointerY - height;
    return math.max(_margin, screen - _margin - height);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_changed);
  }

  void _changed() {
    if (_wasOpen && !_controller.isOpen) {
      // [_built] stays: shad keeps the closing menu on screen while it
      // animates out, and it should not shrink to an empty menu meanwhile.
      final cb = _onClosed;
      _onClosed = null;
      cb?.call();
    }
    _wasOpen = _controller.isOpen;
    if (mounted) setState(() {});
  }

  /// Opens a menu of [entries] at the global [position].
  void show(
    Offset position,
    List<WonkyMenuEntry> Function() entries, {
    VoidCallback? onClosed,
  }) {
    setState(() {
      _at = position;
      _requested = position;
      _placed = false;
      _entries = entries;
      _built = null;
      _onClosed = onClosed;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.show();
    });
  }

  /// After the first layout of the menu: shifts the anchor so that the menu
  /// starts at the pointer (or ends there when there is no room on the
  /// right or below), then reveals it.
  void _place() {
    if (!mounted || _placed) return;
    final box = _probe.currentContext?.findRenderObject() as RenderBox?;
    final at = _at;
    final want = _requested;
    if (box == null || !box.hasSize || at == null || want == null) {
      setState(() => _placed = true);
      return;
    }
    // The probe spans the item column. shad's context menu has only
    // vertical padding plus a 1 px border (an assumed 4 px side padding
    // made menus open a few pixels right of the pointer), and centres the
    // menu on the anchor's x (clamped to the screen), so the anchor goes
    // half a menu width right of the wanted left edge.
    const border = 1.0;
    final width = box.size.width + 2 * border;
    final screen = MediaQuery.sizeOf(context);
    final left = want.dx + width + _margin <= screen.width
        ? want.dx
        : want.dx - width;
    // shad keeps a menu below its anchor when it fits there and flips it
    // above otherwise, but never moves it back onto the screen: a long
    // context menu opened low on the screen ran off the bottom edge.
    final items = _items.currentContext?.findRenderObject() as RenderBox?;
    final height = items != null && items.hasSize
        ? math.min(items.size.height, _maxItemsHeight(screen.height)) + _chrome
        : 0.0;
    final top = topFor(want.dy, height, screen.height);
    setState(() {
      _at = Offset(left + width / 2, top);
      _placed = true;
    });
  }

  double _maxItemsHeight(double screen) =>
      math.max(120, screen - 2 * _margin - _chrome);

  void hide() => _controller.hide();

  bool get isOpen => _controller.isOpen;

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    // The trigger is an empty box beside the child so that the child does
    // not count as "inside" every other context menu.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          width: 0,
          height: 0,
          child: ShadContextMenu(
            controller: _controller,
            anchor: _at == null ? null : ShadGlobalAnchor(_at!),
            constraints: const BoxConstraints(minWidth: 220),
            onTapOutside: (_) => _controller.hide(),
            items: entries != null && (_controller.isOpen || _built != null)
                ? [
                    _PlacementProbe(key: _probe, onLaidOut: _place),
                    Opacity(
                      opacity: _placed ? 1 : 0,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _maxItemsHeight(
                            MediaQuery.sizeOf(context).height,
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            key: _items,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: buildWonkyMenuItems(
                              context,
                              _built ??= entries(),
                              onClose: _controller.hide,
                              requestFocus: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ]
                : const [SizedBox.shrink()],
            child: const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

/// A zero-height, full-width row at the top of the menu whose position tells
/// [WonkyPopupMenuHostState] where shad placed the menu.
class _PlacementProbe extends StatefulWidget {
  const _PlacementProbe({super.key, required this.onLaidOut});

  final VoidCallback onLaidOut;

  @override
  State<_PlacementProbe> createState() => _PlacementProbeState();
}

class _PlacementProbeState extends State<_PlacementProbe> {
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLaidOut());
    return const SizedBox(height: 0, width: double.infinity);
  }
}
