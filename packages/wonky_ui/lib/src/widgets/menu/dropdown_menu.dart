import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import 'menu_entry.dart';
import 'menu_items.dart';
import 'menu_placement.dart';
import 'open_menu.dart';

/// Builds the trigger of a [WonkyDropdownMenu].
typedef WonkyDropdownTriggerBuilder =
    Widget Function(BuildContext context, ShadContextMenuController controller);

/// A dropdown menu anchored below its trigger (toolbar dropdowns, ⋮ menus,
/// account menu) — a thin wrapper over `ShadContextMenu` with a controller
/// and an anchor (suite 02 §4.2).
///
/// [entries] is evaluated each time the menu builds so enabled/checked
/// states are always current.
class WonkyDropdownMenu extends StatefulWidget {
  const WonkyDropdownMenu({
    super.key,
    required this.entries,
    required this.builder,
    this.controller,
    this.anchor,
    this.constraints,
    this.onOpenChanged,
  });

  final List<WonkyMenuEntry> Function() entries;
  final WonkyDropdownTriggerBuilder builder;
  final ShadContextMenuController? controller;

  /// Defaults to below the trigger, start-aligned. A `ShadAnchor` is kept on
  /// screen: the menu opens on the other side of the trigger when it does
  /// not fit and shifts sideways at the window edges
  /// ([WonkyMenuPlacement.onScreen]); menus taller than the room beside the
  /// trigger scroll.
  final ShadAnchorBase? anchor;
  final BoxConstraints? constraints;
  final ValueChanged<bool>? onOpenChanged;

  @override
  State<WonkyDropdownMenu> createState() => _WonkyDropdownMenuState();
}

class _WonkyDropdownMenuState extends State<WonkyDropdownMenu> {
  ShadContextMenuController? _own;
  bool _wasOpen = false;

  /// The entries the open menu shows. shad keeps a closing menu on screen
  /// while it animates out, so it goes on showing them instead of an empty
  /// (slim) menu.
  List<WonkyMenuEntry> _entries = const [];

  /// The open menu's height limit, kept while it animates out: the trigger
  /// may be leaving too (a closing drawer) and cannot be measured then.
  double? _openMaxHeight;

  ShadContextMenuController get _controller =>
      widget.controller ?? (_own ??= ShadContextMenuController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(WonkyDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?.removeListener(_onChanged);
      _controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    OpenMenu.release(this);
    _controller.removeListener(_onChanged);
    _own?.dispose();
    super.dispose();
  }

  static const _defaultAnchor = ShadAnchor(
    childAlignment: AlignmentDirectional.bottomStart,
    overlayAlignment: AlignmentDirectional.topStart,
    offset: Offset(0, 4),
  );

  /// The room beside the trigger: the menu opens below or above it, so it
  /// may be as tall as the larger side.
  double? _maxHeight(ShadAnchorBase anchor) {
    final rect = WonkyMenuPlacement.rectOf(context);
    if (rect == null) return null;
    final gap = switch (anchor) {
      ShadAnchor(:final offset) ||
      ShadAnchorAuto(:final offset) => offset.dy.abs(),
      ShadGlobalAnchor() => 0.0,
    };
    return WonkyMenuPlacement.itemsMaxHeightBeside(context, rect, gap: gap);
  }

  void _onChanged() {
    final open = _controller.isOpen;
    if (open != _wasOpen) {
      _wasOpen = open;
      if (open) {
        OpenMenu.claim(this, _controller.hide);
      } else {
        OpenMenu.release(this);
      }
      widget.onOpenChanged?.call(open);
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final anchor = widget.anchor ?? _defaultAnchor;
    return ShadContextMenu(
      controller: _controller,
      // A manual anchor never moves the menu back onto the screen.
      anchor: anchor is ShadAnchor
          ? WonkyMenuPlacement.onScreen(anchor)
          : anchor,
      constraints: widget.constraints ?? const BoxConstraints(minWidth: 200),
      itemsBuilder: (_) => buildWonkyMenuItems(
        context,
        _controller.isOpen ? _entries = widget.entries() : _entries,
        onClose: _controller.hide,
        requestFocus: true,
        maxHeight: () => _controller.isOpen
            ? _openMaxHeight = _maxHeight(anchor)
            : _openMaxHeight,
      ),
      onTapOutside: (_) => _controller.hide(),
      child: Builder(
        builder: (context) => widget.builder(context, _controller),
      ),
    );
  }
}

/// Wraps [child] so right-click / long-press opens a context menu built from
/// [entries] (suite 02 §3 `ShadContextMenuRegion`).
class WonkyContextMenuRegion extends StatelessWidget {
  const WonkyContextMenuRegion({
    super.key,
    required this.entries,
    required this.child,
    this.enabled = true,
    this.onOpen,
  });

  final List<WonkyMenuEntry> Function() entries;
  final Widget child;
  final bool enabled;

  /// Called before the menu opens (e.g. to select the row under the pointer).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return _LazyContextMenuRegion(
      entries: entries,
      onOpen: onOpen,
      child: child,
    );
  }
}

class _LazyContextMenuRegion extends StatefulWidget {
  const _LazyContextMenuRegion({
    required this.entries,
    required this.child,
    this.onOpen,
  });

  final List<WonkyMenuEntry> Function() entries;
  final Widget child;
  final VoidCallback? onOpen;

  @override
  State<_LazyContextMenuRegion> createState() => _LazyContextMenuRegionState();
}

class _LazyContextMenuRegionState extends State<_LazyContextMenuRegion> {
  final _controller = ShadContextMenuController();

  /// The entries of the open menu, kept while it animates out (see
  /// [_WonkyDropdownMenuState._entries]).
  List<WonkyMenuEntry> _entries = const [];

  /// Where the last pointer went down: the menu opens there (shad flips it
  /// above the pointer when it does not fit below and keeps it on screen
  /// horizontally), so it may be as tall as the larger side.
  Offset? _pointer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (_controller.isOpen) {
      OpenMenu.claim(this, _controller.hide);
    } else {
      OpenMenu.release(this);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    OpenMenu.release(this);
    _controller.dispose();
    super.dispose();
  }

  double? _maxHeight() {
    final at = _pointer;
    if (at == null || !mounted) return null;
    return WonkyMenuPlacement.itemsMaxHeight(
      MediaQuery.sizeOf(context).height,
      below: at.dy,
      above: at.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ShadContextMenuRegion(
      controller: _controller,
      constraints: const BoxConstraints(minWidth: 220),
      itemsBuilder: (_) => buildWonkyMenuItems(
        context,
        _controller.isOpen ? _entries = widget.entries() : _entries,
        onClose: _controller.hide,
        maxHeight: _maxHeight,
      ),
      child: Listener(
        // Also over empty space, where shad's detector opens the menu too.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) {
          _pointer = e.position;
          if (e.buttons == 2) widget.onOpen?.call();
        },
        child: widget.child,
      ),
    );
  }
}
