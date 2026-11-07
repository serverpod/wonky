import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../branding/product_icon.dart';
import '../bootstrap/app_urls.dart';
import '../drive/drive_format.dart';
import '../l10n/wonky_app_localizations.dart';
import 'shell_services.dart';

/// The product icon of an app.
WonkyProduct productOf(WonkyAppKind app) => switch (app) {
  WonkyAppKind.drive => WonkyProduct.drive,
  WonkyAppKind.write => WonkyProduct.write,
  WonkyAppKind.sheets => WonkyProduct.sheets,
  WonkyAppKind.slides => WonkyProduct.slides,
};

void _invoke(
  ShellServices s,
  BuildContext context,
  String id, [
  Map<String, Object?> args = const {},
]) {
  s.dispatcher.invoke(
    id,
    args: args,
    source: InvocationSource.menu,
    context: context,
  );
}

/// The account avatar menu (suite 03 §3.3): *Settings*, *Open ▸* Drive /
/// Write / Sheets / Slides, Sign out.
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key, required this.services, this.size = 32});

  final ShellServices services;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return ValueListenableBuilder<UserProfileView?>(
      valueListenable: services.currentUser,
      builder: (context, me, _) {
        final summary = me?.summary;
        return WonkyDropdownMenu(
          anchor: const ShadAnchor(
            childAlignment: AlignmentDirectional.bottomEnd,
            overlayAlignment: AlignmentDirectional.topEnd,
            offset: Offset(0, 6),
          ),
          // *Settings*, *Open ▸* the four apps, Sign out (suite 03 §3.3);
          // the name and email are in the avatar's tooltip, not the menu.
          entries: () => [
            WonkyMenuItem(
              key: const ValueKey<String>('account.settings'),
              label: l.cmdSettings,
              icon: LucideIcons.settings,
              onSelected: () =>
                  _invoke(services, context, 'shell.settings.openApp'),
            ),
            WonkyMenuSubmenu(
              key: const ValueKey<String>('account.open'),
              label: l.menuOpenApp,
              icon: LucideIcons.layoutGrid,
              children: [
                for (final k in WonkyAppKind.values)
                  WonkyMenuItem(
                    key: ValueKey<String>('account.open.${k.name}'),
                    label: k.productName,
                    leading: WonkyProductIcon(
                      productOf(k),
                      size: 16,
                      semanticLabel: '',
                    ),
                    onSelected: () => _invoke(
                      services,
                      context,
                      'shell.account.switchApp',
                      {'app': k.name},
                    ),
                  ),
              ],
            ),
            const WonkyMenuSeparator(),
            WonkyMenuItem(
              key: const ValueKey<String>('account.signOut'),
              label: l.cmdSignOut,
              icon: LucideIcons.logOut,
              onSelected: () =>
                  _invoke(services, context, 'shell.account.signOut'),
            ),
          ],
          builder: (context, c) => ShadTooltip(
            builder: (_) => Text(
              summary == null
                  ? l.accountMenu
                  : '${summary.displayName}\n${summary.email}',
            ),
            child: GestureDetector(
              key: const ValueKey<String>('shell.account'),
              onTap: c.toggle,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Semantics(
                  button: true,
                  label: l.accountMenu,
                  child: WonkyAvatar(
                    name: summary?.displayName ?? '?',
                    color: summary == null
                        ? ShadTheme.of(context).colorScheme.muted
                        : parseHexColor(summary.avatarColor),
                    imageUrl: summary?.avatarUrl,
                    size: size,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Light / dark / system cycle (top bar, status bar).
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, required this.services, this.size = 32});

  final ShellServices services;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return ListenableBuilder(
      listenable: services.prefs,
      builder: (context, _) {
        final mode = services.prefs.appTheme;
        final (icon, label) = switch (mode) {
          AppThemeMode.system => (LucideIcons.sunMoon, l.themeSystem),
          AppThemeMode.light => (LucideIcons.sun, l.themeLight),
          AppThemeMode.dark => (LucideIcons.moon, l.themeDark),
        };
        return ShadTooltip(
          builder: (_) => Text(l.themeToggleTooltip(label)),
          child: ShadIconButton.ghost(
            key: const ValueKey<String>('shell.themeToggle'),
            width: size,
            height: size,
            semanticLabel: l.themeToggleTooltip(label),
            icon: Icon(icon, size: 18),
            onPressed: () => _invoke(
              services,
              context,
              'shell.appearance.setTheme',
              {'mode': 'cycle'},
            ),
          ),
        );
      },
    );
  }
}
