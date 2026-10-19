import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart'
    show WonkyColors, WonkyDialogCloseButton;

import '../../data/api.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/overlays/shell_overlays.dart';
import '../../assistant/ai_settings_section.dart';
import '../../mcp_bridge/developer_settings.dart';
import '../../shell/shell_services.dart';
import '../settings_screen.dart';
import 'package:flutter/foundation.dart';

export 'offline_section.dart';

/// Settings › Language & region.
class LanguageSection extends StatefulWidget {
  const LanguageSection({super.key, required this.services});

  final ShellServices services;

  @override
  State<LanguageSection> createState() => _LanguageSectionState();
}

class _LanguageSectionState extends State<LanguageSection> {
  late final _tz = TextEditingController(
    text: widget.services.currentUser.value?.timeZone ?? '',
  );

  @override
  void dispose() {
    _tz.dispose();
    super.dispose();
  }

  Future<void> _save({String? locale, String? tz}) async {
    final s = widget.services;
    final l = WonkyAppLocalizations.of(context);
    try {
      s.currentUser.value = await s.repositories.users.updateProfile(
        locale: locale,
        timeZone: tz,
      );
      s.toasts.show(l.settingsSaved);
    } catch (e) {
      s.toasts.error(l.errorGeneric, description: errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final me = widget.services.currentUser.value;
    return SettingsGroup(
      title: l.settingsLanguage,
      description: l.settingsLanguageHint,
      children: [
        SettingsRow(
          label: l.settingsUiLanguage,
          control: ShadSelect<String>(
            initialValue: me?.locale ?? 'en',
            // Languages are listed by their own name (endonym), never
            // translated.
            options: const [ShadOption(value: 'en', child: Text('English'))],
            selectedOptionBuilder: (context, v) => const Text('English'),
            onChanged: (v) => _save(locale: v),
          ),
        ),
        SettingsRow(
          label: l.settingsTimeZone,
          description: l.settingsTimeZoneHint,
          control: SizedBox(
            width: 220,
            child: ShadInput(
              controller: _tz,
              placeholder: Text(DateTime.now().timeZoneName),
              onSubmitted: (v) => _save(tz: v.trim().isEmpty ? null : v.trim()),
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings › Notifications.
class NotificationsSection extends StatelessWidget {
  const NotificationsSection({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final p = services.prefs;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) {
        // Access requests used to follow the `shares` setting (07 §4).
        String v(String k) =>
            (p.notificationSettings[k] ??
                    (k == 'accessRequests'
                        ? p.notificationSettings['shares']
                        : null))
                as String? ??
            'inApp';
        Widget choice(String k) => ShadSelect<String>(
          key: ValueKey<String>('settings.notifications.$k'),
          initialValue: v(k),
          options: [
            ShadOption(value: 'inApp', child: Text(l.notifyInApp)),
            ShadOption(value: 'email', child: Text(l.notifyEmail)),
            ShadOption(value: 'off', child: Text(l.notifyOff)),
          ],
          selectedOptionBuilder: (context, x) => Text(switch (x) {
            'email' => l.notifyEmail,
            'off' => l.notifyOff,
            _ => l.notifyInApp,
          }),
          onChanged: (x) => p.setNotificationSetting(k, x),
        );
        return SettingsGroup(
          title: l.settingsNotifications,
          children: [
            SettingsRow(label: l.notifyMentions, control: choice('mentions')),
            SettingsRow(label: l.notifyReplies, control: choice('replies')),
            SettingsRow(label: l.notifyShares, control: choice('shares')),
            SettingsRow(
              label: l.notifyAccessRequests,
              control: choice('accessRequests'),
            ),
            SettingsRow(
              label: l.notifySuggestions,
              control: choice('suggestions'),
            ),
            SettingsRow(
              label: l.notifyBoard,
              description: l.notifyBoardHint,
              control: choice('board'),
            ),
            SettingsRow(
              label: l.notifyDigest,
              description: l.notifyDigestHint,
              control: ShadSwitch(
                key: const ValueKey<String>('settings.notifications.digest'),
                value: p.notificationSettings['digest'] != false,
                onChanged: (v) => p.setNotificationSetting('digest', v),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Settings › AI.
class AiSection extends StatelessWidget {
  const AiSection({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) => AiSettingsSection(services: services);
}

/// Settings › Developer / MCP: the server's status (Redis), then tokens,
/// connection snippet, UI-bridge toggle (implemented by the MCP bridge,
/// `mcp_bridge/developer_settings.dart`).
class DeveloperSection extends StatelessWidget {
  const DeveloperSection({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ServerStatusGroup(services: services),
      const SizedBox(height: 24),
      McpDeveloperSettings(services: services),
    ],
  );
}

/// Whether the backend is connected to Redis (`ProtocolInfo.redisEnabled` /
/// `redisConnected`, refreshed when shown and on *Reload*).
class ServerStatusGroup extends StatefulWidget {
  const ServerStatusGroup({super.key, required this.services});

  final ShellServices services;

  @override
  State<ServerStatusGroup> createState() => _ServerStatusGroupState();
}

class _ServerStatusGroupState extends State<ServerStatusGroup> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final s = widget.services;
      s.serverInfo.value = await s.repositories.meta.getInfo();
    } catch (_) {
      // Offline: keep the last known status.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return ValueListenableBuilder<ProtocolInfo?>(
      valueListenable: widget.services.serverInfo,
      builder: (context, info, _) {
        final (label, color) = switch (info) {
          null => ('—', theme.colorScheme.mutedForeground),
          ProtocolInfo(redisEnabled: false) => (
            l.redisNotConfigured,
            theme.colorScheme.mutedForeground,
          ),
          ProtocolInfo(redisConnected: true) => (
            l.redisConnected,
            theme.colorScheme.success,
          ),
          _ => (l.redisNotReachable, theme.colorScheme.destructive),
        };
        return SettingsGroup(
          title: l.settingsServerTitle,
          children: [
            SettingsRow(
              label: l.settingsRedis,
              description: l.settingsRedisHint,
              control: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    key: const ValueKey<String>('settings.server.redis'),
                  ),
                  const SizedBox(width: 8),
                  ShadIconButton.ghost(
                    key: const ValueKey<String>('settings.server.reload'),
                    width: 28,
                    height: 28,
                    iconSize: 14,
                    semanticLabel: l.actionReload,
                    enabled: !_loading,
                    icon: const Icon(LucideIcons.refreshCw),
                    onPressed: _refresh,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Settings › About: versions and licenses.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key, required this.services});

  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return ValueListenableBuilder<ProtocolInfo?>(
      valueListenable: services.serverInfo,
      builder: (context, info, _) => SettingsGroup(
        title: '${services.config.appName} · ${l.wonkyWork}',
        children: [
          SettingsRow(
            label: l.aboutAppVersion,
            control: const Text(clientVersion),
          ),
          SettingsRow(
            label: l.aboutServerVersion,
            control: Text(info?.serverVersion ?? '—'),
          ),
          SettingsRow(
            label: l.aboutProtocol,
            control: Text(
              info == null
                  ? '—'
                  : '${info.minClientVersion} · ${_shortHashes(info.revSchemaHash)}',
            ),
          ),
          SettingsRow(
            label: l.aboutRunMode,
            control: Text(info?.runMode ?? '—'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                onPressed: () => showShadDialog<void>(
                  context: context,
                  builder: (context) => ShadDialog(
                    closeIcon: const WonkyDialogCloseButton(),
                    title: Text(l.aboutLicenses),
                    child: SizedBox(
                      width: 520,
                      height: 400,
                      child: FutureBuilder<List<LicenseEntry>>(
                        future: LicenseRegistry.licenses.toList(),
                        builder: (context, snap) => ListView(
                          children: [
                            for (final e in snap.data ?? const <LicenseEntry>[])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  e.packages.join(', '),
                                  style: ShadTheme.of(context).textTheme.small,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                child: Text(l.aboutLicenses),
              ),
              // Bugs & improvements from About (specs/16 §4.1).
              ShadButton.outline(
                key: const ValueKey<String>('settings.about.board'),
                leading: const Icon(LucideIcons.bug, size: 16),
                onPressed: () => services.dispatcher.invoke(
                  'shell.board.report',
                  context: context,
                ),
                child: Text(l.boardReportName),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `sheets:<hash>,slides:<hash>` (`ProtocolInfo.revSchemaHash`) shortened to
/// the first 8 characters of each hash.
String _shortHashes(String hashes) => hashes
    .split(',')
    .map((h) {
      final i = h.indexOf(':');
      final hash = h.substring(i + 1);
      return '${h.substring(0, i + 1)}${hash.substring(0, hash.length.clamp(0, 8))}';
    })
    .join(' ');
