import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../shell/shell_services.dart';
import '../storage/quota_error_presenter.dart';

/// Dynamic menu content keyed by `MenuSpec.custom` id: either a widget
/// builder or a function producing entries.
class MenuCustomItems {
  const MenuCustomItems({this.widgets = const {}, this.entries = const {}});

  final Map<String, Widget Function(BuildContext context, VoidCallback close)>
  widgets;
  final Map<String, List<WonkyMenuEntry> Function(BuildContext context)>
  entries;
}

/// Turns `MenuSpec` trees into `WonkyMenuEntry`s using the command registry
/// (title, icon, shortcut, enabled, checked) — the single source for the
/// menubar, context menus, the palette's menu paths and MCP.
class MenuResolver {
  MenuResolver(this.services, {this.custom = const MenuCustomItems()});

  final ShellServices services;
  final MenuCustomItems custom;

  /// Entries for [specs].
  List<WonkyMenuEntry> entries(BuildContext context, List<MenuSpec> specs) {
    final out = <WonkyMenuEntry>[];
    for (final s in specs) {
      switch (s) {
        case MenuSeparator():
          out.add(const WonkyMenuSeparator());
        case MenuSectionLabel(:final text):
          out.add(WonkyMenuLabel(text));
        case MenuCustom(:final id):
          final w = custom.widgets[id];
          final e = custom.entries[id];
          if (w != null) {
            out.add(WonkyMenuCustom(builder: w, label: s.label));
          } else if (e != null) {
            out.addAll(e(context));
          }
        case MenuSubmenu():
          final children = entries(context, s.children).tidy();
          if (children.isEmpty) continue;
          out.add(
            WonkyMenuSubmenu(
              key: ValueKey<String>('menu.${s.effectiveId}'),
              label: s.label,
              children: children,
            ),
          );
        case MenuCommand():
          final e = commandEntry(
            context,
            s.commandId,
            args: s.args,
            label: s.label,
            radio: s.radio,
            key: s.effectiveId,
          );
          if (e != null) out.add(e);
      }
    }
    return out.tidy();
  }

  /// The entry for one command (null when not registered).
  WonkyMenuItem? commandEntry(
    BuildContext context,
    String commandId, {
    Map<String, Object?> args = const {},
    String? label,
    bool radio = false,
    String? key,
    InvocationSource source = InvocationSource.menu,
  }) {
    final command = services.registry.byId(commandId);
    if (command == null) {
      if (kDebugMode) debugPrint('Menu references unknown command $commandId');
      return null;
    }
    final state = services.dispatcher.stateOf(commandId, args);
    if (!state.visible) return null;
    final title = label ?? command.title(context);
    // Drive-scope shortcuts (F2, Del, S…) only apply on the home screen.
    final driveOnly =
        command.keyScope == KeyScope.drive &&
        services.activeDocument.value != null;
    final shortcut = driveOnly
        ? null
        : services.keymap.labelsFor(commandId, args);
    void run() {
      services.noteRecentCommand(commandId);
      services.dispatcher
          .invoke(commandId, args: args, source: source, context: context)
          .catchError((Object e) {
            // `quotaExceeded`: the *Out of storage* dialog instead (D-11).
            if (!QuotaErrorPresenter.isQuotaExceeded(e)) {
              services.toasts.error(
                services.l10n?.commandFailed(title) ?? title,
                description: '$e',
              );
            }
            return const CommandResult.failed('error');
          });
    }

    final k = ValueKey<String>('menu.${key ?? commandId}');
    if (state.checked != null) {
      return radio
          ? WonkyMenuRadioItem(
              key: k,
              label: title,
              selected: state.checked!,
              shortcut: shortcut,
              enabled: state.enabled,
              disabledReason: state.disabledReason,
              onSelected: run,
            )
          : WonkyMenuCheckItem(
              key: k,
              label: title,
              checked: state.checked!,
              shortcut: shortcut,
              enabled: state.enabled,
              disabledReason: state.disabledReason,
              onSelected: run,
            );
    }
    return WonkyMenuItem(
      key: k,
      label: title,
      icon: command.iconFor(args),
      shortcut: shortcut,
      enabled: state.enabled,
      disabledReason: state.disabledReason,
      onSelected: run,
      destructive:
          commandId.endsWith('deleteForever') ||
          commandId.endsWith('emptyTrash'),
    );
  }

  /// Menubar menus for the top-level submenus of [root].
  List<WonkyMenubarMenu> menubar(BuildContext context, MenuRoot root) => [
    for (final m in root.children)
      if (m is MenuSubmenu)
        WonkyMenubarMenu(
          id: m.effectiveId,
          label: m.label,
          mnemonic: m.mnemonic,
          entries: () => entries(context, m.children),
        ),
  ];

  /// MCP `ui.get_menu_tree` JSON with runtime state.
  List<Map<String, Object?>> toJson(BuildContext context, MenuRoot root) =>
      root.toJson(
        resolve: (c) {
          final command = services.registry.byId(c.commandId);
          final state = services.dispatcher.stateOf(c.commandId, c.args);
          return {
            'title': c.label ?? command?.title(context) ?? c.commandId,
            'enabled': state.enabled,
            if (!state.visible) 'hidden': true,
            if (state.checked != null) 'checked': state.checked,
            if (services.keymap.shortcutTextOf(c.commandId) != null)
              'shortcut': services.keymap.shortcutTextOf(c.commandId),
          };
        },
      );
}
