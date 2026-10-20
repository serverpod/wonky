import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';

import '../menu/menu_entry.dart';
import '../menu/menu_items.dart';
import '../menu/menu_placement.dart';
import '../menu/open_menu.dart';

/// One top-level menu of a [WonkyMenubar].
class WonkyMenubarMenu {
  const WonkyMenubarMenu({
    required this.id,
    required this.label,
    required this.entries,
    this.mnemonic,
  });

  /// Stable id (`file`, `edit`) — key `menubar.<id>`.
  final String id;
  final String label;

  /// Accelerator letter (Alt+letter on Win/Linux, Ctrl+Alt+letter on macOS);
  /// defaults to the first letter of [label].
  final String? mnemonic;

  /// Evaluated when the menu opens, so states are current.
  final List<WonkyMenuEntry> Function() entries;

  String get effectiveMnemonic =>
      (mnemonic ?? (label.isEmpty ? '' : label[0])).toUpperCase();
}

/// Opens menus of a [WonkyMenubar] programmatically (keyboard accelerators,
/// MCP).
class WonkyMenubarController extends ChangeNotifier {
  final ShadMenubarController _shad = ShadMenubarController();
  List<WonkyMenubarMenu> _menus = const [];
  final Map<int, FocusNode> _focus = {};
  final Map<int, ShadPopoverController> _popovers = {};

  /// The open menu id, or null.
  String? get openMenuId {
    final i = _shad.selectedIndex;
    return i == null || i >= _menus.length ? null : _menus[i].id;
  }

  /// Opens the menu [id] and focuses its trigger. Returns false when absent.
  bool open(String id) {
    final i = _menus.indexWhere((m) => m.id == id);
    if (i < 0) return false;
    _shad.selectedIndex = i;
    _focus[i]?.requestFocus();
    notifyListeners();
    return true;
  }

  /// Opens the menu whose mnemonic is [letter].
  bool openByMnemonic(String letter) {
    final up = letter.toUpperCase();
    for (final m in _menus) {
      if (m.effectiveMnemonic == up) return open(m.id);
    }
    return false;
  }

  /// Closes any open menu.
  void close() {
    _shad.selectedIndex = null;
    notifyListeners();
  }

  FocusNode _focusAt(int i) =>
      _focus.putIfAbsent(i, () => FocusNode(debugLabel: 'menubar-$i'));

  /// The popover of menu [i]. When it closes on its own (Escape, a menu
  /// item) while still selected, the menubar deactivates — otherwise
  /// `ShadMenubar` keeps the index selected and merely hovering another
  /// title would open its menu.
  ///
  /// The menu takes focus while open; when the last menu closes, focus goes
  /// back to where it was (e.g. the document editor) unless something else
  /// (a dialog opened by the chosen item) has taken it meanwhile.
  ShadPopoverController _popoverAt(int i) => _popovers.putIfAbsent(i, () {
    final c = ShadPopoverController();
    c.addListener(() {
      if (c.isOpen) {
        OpenMenu.claim(this, close);
        final f = FocusManager.instance.primaryFocus;
        if (_returnFocus == null && f != null && !_isOwn(f)) _returnFocus = f;
        return;
      }
      if (_shad.selectedIndex == i) close();
      if (_shad.selectedIndex == null) {
        OpenMenu.release(this);
        _restoreFocus();
      }
    });
    return c;
  });

  FocusNode? _returnFocus;

  bool _isOwn(FocusNode f) => _focus.values.contains(f);

  void _restoreFocus() {
    final target = _returnFocus;
    _returnFocus = null;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shad.selectedIndex != null || target.context == null) return;
      final f = FocusManager.instance.primaryFocus;
      final lost = f == null || f is FocusScopeNode || _isOwn(f);
      if (lost) target.requestFocus();
    });
  }

  @override
  void dispose() {
    OpenMenu.release(this);
    _shad.dispose();
    for (final f in _focus.values) {
      f.dispose();
    }
    for (final p in _popovers.values) {
      p.dispose();
    }
    super.dispose();
  }
}

/// A `ShadMenubar` built from declarative menus (suite 02 §4.3). In
/// `wonky_app`, the menus come from a `MenuSpec` tree resolved against the
/// command registry.
class WonkyMenubar extends StatefulWidget {
  const WonkyMenubar({
    super.key,
    required this.menus,
    this.controller,
    this.height = 32,
  });

  final List<WonkyMenubarMenu> menus;
  final WonkyMenubarController? controller;
  final double height;

  @override
  State<WonkyMenubar> createState() => _WonkyMenubarState();
}

class _WonkyMenubarState extends State<WonkyMenubar> {
  WonkyMenubarController? _own;

  WonkyMenubarController get _controller =>
      widget.controller ?? (_own ??= WonkyMenubarController());

  @override
  void initState() {
    super.initState();
    _controller._shad.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(WonkyMenubar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _own)?._shad.removeListener(_rebuild);
      _controller._shad.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    _controller._shad.removeListener(_rebuild);
    _own?.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  static final _anchor = WonkyMenuPlacement.onScreen(
    const ShadAnchor(
      offset: Offset(-4, 8),
      childAlignment: AlignmentDirectional.bottomStart,
      overlayAlignment: AlignmentDirectional.topStart,
    ),
  );

  /// The menus open below the strip; long ones scroll.
  double? _maxHeight() {
    final rect = WonkyMenuPlacement.rectOf(context);
    if (rect == null) return null;
    return WonkyMenuPlacement.itemsMaxHeightBeside(context, rect, gap: 4);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller.._menus = widget.menus;
    final selected = controller._shad.selectedIndex;
    final theme = ShadTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      // The strip's `controlShadow` (a theme token without a per-widget
      // override) is painted outside it; clipped, the menubar is flat. The
      // menus open in overlays and keep their shadows.
      child: ClipRect(
        // (v2) Narrow windows (Slides 04 §16: nothing overflows at 360 px)
        // scroll the strip horizontally instead of overflowing.
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ShadMenubar(
            controller: controller._shad,
            border: ShadBorder.none,
            padding: EdgeInsets.zero,
            backgroundColor: theme.colorScheme.background,
            items: [
              for (var i = 0; i < widget.menus.length; i++)
                ShadMenubarItem(
                  key: ValueKey<String>('menubar.${widget.menus[i].id}'),
                  focusNode: controller._focusAt(i),
                  controller: controller._popoverAt(i),
                  height: widget.height - 4,
                  buttonPadding: const EdgeInsets.symmetric(horizontal: 8),
                  // shad's default anchor, kept on screen (a menu at the
                  // end of a narrow strip ran off the right edge).
                  anchor: _anchor,
                  constraints: const BoxConstraints(minWidth: 240),
                  items: selected == i
                      ? buildWonkyMenuItems(
                          context,
                          widget.menus[i].entries(),
                          onClose: controller.close,
                          // Also when opened with the pointer: the menu takes
                          // the keys (Escape, ↑/↓, type-ahead) instead of a
                          // focused document editor behind it.
                          requestFocus: true,
                          maxHeight: _maxHeight,
                        )
                      : const [SizedBox.shrink()],
                  child: Text(
                    widget.menus[i].label,
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
