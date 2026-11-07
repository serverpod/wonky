/// A declarative menu tree (suite 02 §4.3).
///
/// The same tree generates the in-window menubar, the macOS `PlatformMenuBar`,
/// the command-palette menu paths ("Format › Text › Bold") and the MCP
/// `ui.get_menu_tree` output. Items reference commands by id; titles, icons,
/// shortcuts and enabled/checked states come from the command registry.
///
/// ```dart
/// final menus = MenuSpec.root([
///   MenuSpec.submenu('file', 'File', [
///     MenuSpec.command('shell.file.open', label: 'Open…'),
///     MenuSpec.separator(),
///     MenuSpec.command('shell.file.print'),
///   ]),
/// ]);
/// ```
sealed class MenuSpec {
  const MenuSpec({this.id});

  /// Stable id used to extend/patch menus (`file`, `file.new`). Commands
  /// default to their command id.
  final String? id;

  /// The top-level tree.
  static MenuRoot root(List<MenuSpec> children) => MenuRoot(children);

  /// A submenu (or top-level menu).
  static MenuSubmenu submenu(
    String id,
    String label,
    List<MenuSpec> children, {
    String? mnemonic,
  }) => MenuSubmenu(id, label, children, mnemonic: mnemonic);

  /// An item that invokes [commandId] with fixed [args].
  static MenuCommand command(
    String commandId, {
    String? label,
    Map<String, Object?> args = const {},
    String? id,
    bool radio = false,
    bool showIcon = false,
  }) => MenuCommand(
    commandId,
    label: label,
    args: args,
    id: id,
    radio: radio,
    showIcon: showIcon,
  );

  /// A separator line.
  static MenuSeparator separator({String? id}) => MenuSeparator(id: id);

  /// A section header (non-interactive).
  static MenuSectionLabel label(String text, {String? id}) =>
      MenuSectionLabel(text, id: id);

  /// A custom item rendered by a builder the app registers under [id]
  /// (color grid, table-size grid, recent files…).
  static MenuCustom custom(String id, {String? label}) =>
      MenuCustom(id, label: label);

  /// The effective id (never null for commands).
  String? get effectiveId => id;

  /// JSON form for MCP (`ui.get_menu_tree`). [resolve] adds runtime state
  /// (title, enabled, checked, shortcut) for command items.
  Map<String, Object?> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  });
}

/// Root of a menu tree: an ordered list of top-level menus.
class MenuRoot {
  const MenuRoot(this.children);

  final List<MenuSpec> children;

  /// Finds the node with [id] anywhere in the tree.
  MenuSpec? find(String id) {
    MenuSpec? search(List<MenuSpec> nodes) {
      for (final n in nodes) {
        if (n.effectiveId == id) return n;
        if (n is MenuSubmenu) {
          final r = search(n.children);
          if (r != null) return r;
        }
      }
      return null;
    }

    return search(children);
  }

  /// All command items, depth-first.
  Iterable<MenuCommand> get commands sync* {
    Iterable<MenuCommand> walk(List<MenuSpec> nodes) sync* {
      for (final n in nodes) {
        if (n is MenuCommand) yield n;
        if (n is MenuSubmenu) yield* walk(n.children);
      }
    }

    yield* walk(children);
  }

  /// The label path to every command item, e.g.
  /// `{'write.format.bold': ['Format', 'Text', 'Bold']}`. Command items
  /// without a label get [titleOf] (or the id) as the last segment. When a
  /// command appears more than once, the first path wins.
  Map<String, List<String>> commandPaths({
    String Function(MenuCommand item)? titleOf,
  }) {
    final out = <String, List<String>>{};
    void walk(List<MenuSpec> nodes, List<String> prefix) {
      for (final n in nodes) {
        switch (n) {
          case MenuCommand():
            out.putIfAbsent(
              n.commandId,
              () => [...prefix, n.label ?? titleOf?.call(n) ?? n.commandId],
            );
          case MenuSubmenu():
            walk(n.children, [...prefix, n.label]);
          case MenuSeparator() || MenuSectionLabel() || MenuCustom():
            break;
        }
      }
    }

    walk(children, const []);
    return out;
  }

  /// Every command item with fixed [MenuCommand.args] (radio options such
  /// as View › App theme › Dark), with its label path. The palette lists
  /// these as separate rows (suite 08 §3).
  List<({MenuCommand item, List<String> path})> parameterizedItems({
    String Function(MenuCommand item)? titleOf,
  }) {
    final out = <({MenuCommand item, List<String> path})>[];
    void walk(List<MenuSpec> nodes, List<String> prefix) {
      for (final n in nodes) {
        switch (n) {
          case MenuCommand(:final args) when args.isNotEmpty:
            out.add((
              item: n,
              path: [...prefix, n.label ?? titleOf?.call(n) ?? n.commandId],
            ));
          case MenuSubmenu():
            walk(n.children, [...prefix, n.label]);
          case MenuCommand() ||
              MenuSeparator() ||
              MenuSectionLabel() ||
              MenuCustom():
            break;
        }
      }
    }

    walk(children, const []);
    return out;
  }

  /// Returns a copy with [items] inserted after the node [targetId].
  /// Throws [StateError] when the target does not exist.
  MenuRoot insertAfter(String targetId, List<MenuSpec> items) =>
      _patch(targetId, (n) => [n, ...items]);

  /// Returns a copy with [items] inserted before the node [targetId].
  MenuRoot insertBefore(String targetId, List<MenuSpec> items) =>
      _patch(targetId, (n) => [...items, n]);

  /// Returns a copy with the node [targetId] replaced by [items].
  MenuRoot replace(String targetId, List<MenuSpec> items) =>
      _patch(targetId, (_) => items);

  /// Returns a copy without the node [targetId] (no-op when missing).
  MenuRoot remove(String targetId) =>
      find(targetId) == null ? this : _patch(targetId, (_) => const []);

  /// Returns a copy with [items] appended to the submenu [submenuId]
  /// (or as new top-level menus when [submenuId] is null).
  MenuRoot appendTo(String? submenuId, List<MenuSpec> items) {
    if (submenuId == null) return MenuRoot([...children, ...items]);
    final target = find(submenuId);
    if (target is! MenuSubmenu) {
      throw StateError('No submenu "$submenuId"');
    }
    return _patch(
      submenuId,
      (n) => [
        (n as MenuSubmenu).copyWith(children: [...n.children, ...items]),
      ],
    );
  }

  /// Inserts top-level menus before the top-level menu [beforeId] (or at the
  /// end when it does not exist).
  MenuRoot insertMenusBefore(String beforeId, List<MenuSpec> menus) {
    final index = children.indexWhere((c) => c.effectiveId == beforeId);
    if (index < 0) return MenuRoot([...children, ...menus]);
    return MenuRoot([
      ...children.sublist(0, index),
      ...menus,
      ...children.sublist(index),
    ]);
  }

  MenuRoot _patch(String targetId, List<MenuSpec> Function(MenuSpec) f) {
    var found = false;
    List<MenuSpec> walk(List<MenuSpec> nodes) {
      final out = <MenuSpec>[];
      for (final n in nodes) {
        if (!found && n.effectiveId == targetId) {
          found = true;
          out.addAll(f(n));
        } else if (n is MenuSubmenu) {
          out.add(n.copyWith(children: walk(n.children)));
        } else {
          out.add(n);
        }
      }
      return out;
    }

    final result = walk(children);
    if (!found) throw StateError('No menu node "$targetId"');
    return MenuRoot(result);
  }

  /// JSON form for MCP.
  List<Map<String, Object?>> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  }) => [for (final c in children) c.toJson(resolve: resolve)];
}

/// A submenu.
class MenuSubmenu extends MenuSpec {
  const MenuSubmenu(String id, this.label, this.children, {this.mnemonic})
    : super(id: id);

  final String label;
  final List<MenuSpec> children;

  /// Letter for the Alt+letter accelerator (defaults to the first letter).
  final String? mnemonic;

  @override
  String get effectiveId => id!;

  MenuSubmenu copyWith({String? label, List<MenuSpec>? children}) =>
      MenuSubmenu(
        id!,
        label ?? this.label,
        children ?? this.children,
        mnemonic: mnemonic,
      );

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  }) => {
    'type': 'submenu',
    'id': id,
    'label': label,
    'items': [for (final c in children) c.toJson(resolve: resolve)],
  };
}

/// A command item.
class MenuCommand extends MenuSpec {
  const MenuCommand(
    this.commandId, {
    this.label,
    this.args = const {},
    super.id,
    this.radio = false,
    this.showIcon = false,
  });

  final String commandId;

  /// Overrides the command title.
  final String? label;

  /// Fixed arguments.
  final Map<String, Object?> args;

  /// Render as a radio item (● when checked) instead of a check item.
  final bool radio;

  /// Keep the command's icon when it has a checked state (the ✓ moves to
  /// the end): View › Panels shows each panel's rail icon (suite 03 §3.2),
  /// Insert › Code block / Quote / Checklist their block icons. Other
  /// toggles show only the ✓.
  final bool showIcon;

  @override
  String get effectiveId => id ?? commandId;

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  }) => {
    'type': 'command',
    'id': effectiveId,
    'commandId': commandId,
    if (label != null) 'label': label,
    if (args.isNotEmpty) 'args': args,
    if (radio) 'radio': true,
    ...?resolve?.call(this),
  };
}

/// A separator.
class MenuSeparator extends MenuSpec {
  const MenuSeparator({super.id});

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  }) => {'type': 'separator'};
}

/// A section header.
class MenuSectionLabel extends MenuSpec {
  const MenuSectionLabel(this.text, {super.id});

  final String text;

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  }) => {'type': 'label', 'text': text};
}

/// A custom item, rendered by an app-registered builder.
class MenuCustom extends MenuSpec {
  const MenuCustom(String id, {this.label}) : super(id: id);

  final String? label;

  @override
  String get effectiveId => id!;

  @override
  Map<String, Object?> toJson({
    Map<String, Object?> Function(MenuCommand item)? resolve,
  }) => {'type': 'custom', 'id': id, if (label != null) 'label': label};
}
