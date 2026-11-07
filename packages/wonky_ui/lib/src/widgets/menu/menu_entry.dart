import 'package:flutter/widgets.dart';

/// A declarative menu entry rendered by [WonkyDropdownMenu], `WonkyMenubar`,
/// context menus and toolbar overflow menus (suite 02 §4.2).
///
/// `wonky_app` builds these from the command registry (`CommandMenuItem`), so
/// titles, icons, shortcuts and enabled/checked state come from commands.
sealed class WonkyMenuEntry {
  const WonkyMenuEntry({this.key});

  /// Stable key (`<area>.<element>`), used by tests and the MCP bridge.
  final Key? key;
}

/// An actionable item.
class WonkyMenuItem extends WonkyMenuEntry {
  const WonkyMenuItem({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    this.shortcut,
    this.enabled = true,
    this.disabledReason,
    this.onSelected,
    this.destructive = false,
    this.semanticLabel,
    this.trailing,
  });

  final String label;
  final IconData? icon;

  /// A small widget shown at the end instead of a shortcut (e.g. a font
  /// preview "Aa").
  final Widget? trailing;

  /// A 16 px widget shown instead of [icon] (e.g. a product icon).
  final Widget? leading;

  /// Key caps of the shortcut (`['⌘', 'B']`), rendered with `ShadKbd`.
  final List<String>? shortcut;
  final bool enabled;

  /// Tooltip shown on a disabled item ("You have view access").
  final String? disabledReason;
  final VoidCallback? onSelected;
  final bool destructive;
  final String? semanticLabel;
}

/// An item with a ✓ when [checked]. With an [icon] (a panel toggle that
/// keeps its panel's icon, suite 03 §3.2) the icon takes the leading slot
/// and the ✓ moves to the end.
class WonkyMenuCheckItem extends WonkyMenuItem {
  const WonkyMenuCheckItem({
    super.key,
    required super.label,
    required this.checked,
    super.icon,
    super.shortcut,
    super.enabled,
    super.disabledReason,
    super.onSelected,
    super.semanticLabel,
  });

  final bool checked;
}

/// An item with a ● when [selected] (one of a group).
class WonkyMenuRadioItem extends WonkyMenuItem {
  const WonkyMenuRadioItem({
    super.key,
    required super.label,
    required this.selected,
    super.shortcut,
    super.enabled,
    super.disabledReason,
    super.onSelected,
    super.semanticLabel,
    super.trailing,
  });

  final bool selected;
}

/// A nested menu.
class WonkyMenuSubmenu extends WonkyMenuEntry {
  const WonkyMenuSubmenu({
    super.key,
    required this.label,
    required this.children,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final IconData? icon;
  final List<WonkyMenuEntry> children;
  final bool enabled;
}

/// A separator line.
class WonkyMenuSeparator extends WonkyMenuEntry {
  const WonkyMenuSeparator({super.key});
}

/// A non-interactive section header.
class WonkyMenuLabel extends WonkyMenuEntry {
  const WonkyMenuLabel(this.text, {super.key});

  final String text;
}

/// Arbitrary content (color grid, table-size grid…). Call [close] from the
/// builder to dismiss the menu.
class WonkyMenuCustom extends WonkyMenuEntry {
  const WonkyMenuCustom({super.key, required this.builder, this.label});

  /// Accessible name / overflow label.
  final String? label;
  final Widget Function(BuildContext context, VoidCallback close) builder;
}

/// Helpers over entry lists.
extension WonkyMenuEntries on List<WonkyMenuEntry> {
  /// Removes leading/trailing/double separators (after filtering items out).
  List<WonkyMenuEntry> tidy() {
    final out = <WonkyMenuEntry>[];
    for (final e in this) {
      if (e is WonkyMenuSeparator &&
          (out.isEmpty || out.last is WonkyMenuSeparator)) {
        continue;
      }
      out.add(e);
    }
    while (out.isNotEmpty && out.last is WonkyMenuSeparator) {
      out.removeLast();
    }
    return out;
  }

  /// Whether any entry needs a leading slot (icon, check or radio).
  bool get hasLeading => any(
    (e) =>
        (e is WonkyMenuItem && (e.icon != null || e.leading != null)) ||
        e is WonkyMenuCheckItem ||
        e is WonkyMenuRadioItem ||
        (e is WonkyMenuSubmenu && e.icon != null),
  );
}
