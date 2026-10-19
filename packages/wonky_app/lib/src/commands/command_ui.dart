import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../menus/menu_resolver.dart';
import 'command_dispatcher.dart' show CommandState;
import '../shell/shell_services.dart';
import '../storage/quota_error_presenter.dart';

/// Invoking a command from a control, with failures shown as toasts (CQ-53:
/// one policy for the apps' toolbars, panels and menus).
extension InvokeWithToasts on ShellServices {
  /// Invokes [id] and never throws. For people (not agents, which get the
  /// result): a failed result's message, a disabled command's reason and
  /// errors are shown as toasts (out-of-storage errors open their own
  /// dialog instead, D-11); the command counts as recently used.
  Future<CommandResult> invokeWithToasts(
    String id, {
    Map<String, Object?> args = const {},
    InvocationSource source = InvocationSource.ui,
    BuildContext? context,
  }) async {
    final quiet = source.isAgent;
    final c = context != null && context.mounted ? context : null;
    String title() => (c == null ? null : registry.byId(id)?.title(c)) ?? id;
    if (!quiet) noteRecentCommand(id);
    try {
      final r = await dispatcher.invoke(
        id,
        args: args,
        source: source,
        context: c,
      );
      if (r.status == CommandStatus.failed && r.message != null && !quiet) {
        toasts.error(title(), description: r.message);
      }
      return r;
    } on CommandDisabled catch (e) {
      if (e.reason != null && !quiet) toasts.show(e.reason!);
      return CommandResult.failed(e.message);
    } on CommandException catch (e) {
      if (!quiet) toasts.error(e.message);
      return CommandResult.failed(e.message);
    } catch (e) {
      if (!quiet && !QuotaErrorPresenter.isQuotaExceeded(e)) {
        toasts.error(
          l10n?.commandFailed(title()) ?? title(),
          description: '$e',
        );
      }
      return CommandResult.failed('$e');
    }
  }
}

/// Binds an app's chrome controls to commands: every toolbar, header,
/// status bar, panel and menu control invokes a command id (suite 08 §1.1),
/// none calls business logic. Enabled state, reasons, checked state and
/// shortcuts come from the registry; failures become toasts
/// ([InvokeWithToasts]). Apps subclass it for their localizations
/// (`CommandUi` in Sheets, `SlidesCommandUi` in Slides).
class ShellCommandUi {
  ShellCommandUi(this.context, this.s, {required this.toolbarKeyPrefix});

  final BuildContext context;
  final ShellServices s;

  /// The prefix of toolbar item ids (`sheets.toolbar`).
  final String toolbarKeyPrefix;

  CommandState state(String id, [Map<String, Object?> args = const {}]) =>
      s.dispatcher.stateOf(id, args);

  String title(String id) => s.registry.byId(id)?.title(context) ?? id;

  List<String>? shortcut(String id, [Map<String, Object?> args = const {}]) =>
      s.keymap.labelsFor(id, args);

  /// Invokes [id]; failures become toasts.
  void run(
    String id, [
    Map<String, Object?> args = const {},
    InvocationSource source = InvocationSource.toolbar,
  ]) => unawaited(
    s.invokeWithToasts(id, args: args, source: source, context: context),
  );

  String _key(String id, String? keyName) =>
      '$toolbarKeyPrefix.${keyName ?? id.split('.').skip(1).join('.')}';

  /// A toolbar button bound to [id].
  ToolbarItem button(
    String id, {
    IconData? icon,
    int priority = 3,
    Map<String, Object?> args = const {},
    String? label,
    String? keyName,
    VoidCallback? onLongPress,
  }) {
    final st = state(id, args);
    return ToolbarButton(
      id: _key(id, keyName),
      priority: priority,
      icon: icon ?? s.registry.byId(id)?.icon ?? LucideIcons.circle,
      label: label ?? title(id),
      shortcut: shortcut(id, args),
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onPressed: () => run(id, args),
      onLongPress: onLongPress,
      onSecondaryTap: onLongPress,
    );
  }

  /// A toggle bound to [id] (checked state from the command).
  ToolbarItem toggle(
    String id, {
    IconData? icon,
    int priority = 3,
    Map<String, Object?> args = const {},
    String? label,
    String? keyName,
  }) {
    final st = state(id, args);
    return ToolbarToggleButton(
      id: _key(id, keyName),
      priority: priority,
      icon: icon ?? s.registry.byId(id)?.icon ?? LucideIcons.circle,
      label: label ?? title(id),
      value: st.checked ?? false,
      shortcut: shortcut(id, args),
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onChanged: (_) => run(id, args),
    );
  }

  /// A dropdown whose entries are menu specs (resolved against the
  /// registry like the menubar).
  ToolbarItem dropdown(
    String keyName, {
    required String label,
    required List<MenuSpec> Function() items,
    IconData? icon,
    int priority = 3,
    bool? enabled,
    String? tooltip,
    double? minWidth,
    MenuCustomItems custom = const MenuCustomItems(),
  }) => ToolbarDropdownButton(
    id: '$toolbarKeyPrefix.$keyName',
    priority: priority,
    label: label,
    icon: icon,
    tooltip: tooltip,
    minWidth: minWidth,
    enabled: enabled ?? true,
    entries: () => MenuResolver(s, custom: custom).entries(context, items()),
  );

  /// A menu entry bound to [id] (key `menu.<keyName ?? id>`).
  WonkyMenuEntry item(
    String id, {
    Map<String, Object?> args = const {},
    String? label,
    IconData? icon,
    bool radio = false,
    String? keyName,
    InvocationSource source = InvocationSource.menu,
  }) {
    final st = state(id, args);
    final text = label ?? title(id);
    final k = ValueKey<String>('menu.${keyName ?? id}');
    final sc = shortcut(id, args);
    void go() => run(id, args, source);
    if (st.checked != null) {
      return radio
          ? WonkyMenuRadioItem(
              key: k,
              label: text,
              selected: st.checked!,
              shortcut: sc,
              enabled: st.enabled,
              disabledReason: st.disabledReason,
              onSelected: go,
            )
          : WonkyMenuCheckItem(
              key: k,
              label: text,
              checked: st.checked!,
              shortcut: sc,
              enabled: st.enabled,
              disabledReason: st.disabledReason,
              onSelected: go,
            );
    }
    return WonkyMenuItem(
      key: k,
      label: text,
      icon: icon ?? s.registry.byId(id)?.icon,
      shortcut: sc,
      enabled: st.enabled,
      disabledReason: st.disabledReason,
      onSelected: go,
    );
  }
}
