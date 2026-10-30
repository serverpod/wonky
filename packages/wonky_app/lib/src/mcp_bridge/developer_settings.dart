import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../commands/shell_commands/general_commands.dart' show mcpUrl;
import '../data/api.dart';
import '../l10n/wonky_app_localizations.dart';
import '../settings/settings_screen.dart';
import '../shell/dialogs.dart';
import '../shell/form_dialog.dart';
import '../shell/shell_services.dart';
import 'mcp_bridge_client.dart';
import 'mcp_bridge_scope.dart';

/// The human label of a token [scope] (suite 09 §2); unknown scopes show
/// their id.
String mcpScopeLabel(WonkyAppLocalizations l, String scope) => switch (scope) {
  McpScope.driveRead => l.mcpScopeDriveRead,
  McpScope.driveWrite => l.mcpScopeDriveWrite,
  McpScope.writeRead => l.mcpScopeWriteRead,
  McpScope.writeEdit => l.mcpScopeWriteEdit,
  McpScope.sheetsRead => l.mcpScopeSheetsRead,
  McpScope.sheetsEdit => l.mcpScopeSheetsEdit,
  McpScope.slidesRead => l.mcpScopeSlidesRead,
  McpScope.slidesEdit => l.mcpScopeSlidesEdit,
  McpScope.scriptsRun => l.mcpScopeScriptsRun,
  McpScope.uiControl => l.mcpScopeUiControl,
  McpScope.board => l.mcpScopeBoard,
  _ => scope,
};

/// Default scopes of new tokens. (v2) The `slides:*` scopes are offered but
/// off by default until the `slides.*` tools exist (Slides SL-40).
const mcpDefaultScopes = [
  McpScope.driveRead,
  McpScope.driveWrite,
  McpScope.writeRead,
  McpScope.writeEdit,
  McpScope.sheetsRead,
  McpScope.sheetsEdit,
  McpScope.uiControl,
];

/// The connection snippets for MCP clients.
abstract final class McpConnectionSnippets {
  /// `.mcp.json` / Claude Desktop config with the Streamable HTTP server.
  static String json(String url, String token) =>
      const JsonEncoder.withIndent('  ').convert({
        'mcpServers': {
          'wonky': {
            'type': 'http',
            'url': url,
            'headers': {'Authorization': 'Bearer $token'},
          },
        },
      });

  /// `claude mcp add` command line.
  static String claudeCode(String url, String token) =>
      'claude mcp add --transport http wonky $url '
      '--header "Authorization: Bearer $token"';

  /// Config for stdio-only clients through `wonky_mcp_stdio`.
  static String stdio(
    String url,
    String token,
  ) => const JsonEncoder.withIndent('  ').convert({
    'mcpServers': {
      'wonky': {
        'command': 'dart',
        'args': [
          'run',
          '/path/to/wonky/packages/wonky_mcp_stdio/bin/wonky_mcp_stdio.dart',
          '--url',
          url,
          '--token',
          token,
        ],
      },
    },
  });
}

/// Settings › Developer / MCP (suite 04 §4): personal access tokens
/// (create with name, scopes and expiry, copy once, list, revoke), the
/// connection configuration for Claude Code / Claude Desktop, and the UI
/// bridge toggle with its live status.
class McpDeveloperSettings extends StatefulWidget {
  const McpDeveloperSettings({super.key, required this.services});

  final ShellServices services;

  @override
  State<McpDeveloperSettings> createState() => _McpDeveloperSettingsState();
}

class _McpDeveloperSettingsState extends State<McpDeveloperSettings> {
  List<AccessTokenView>? _tokens;
  Object? _loadError;
  CreatedAccessToken? _created;
  int _snippet = 0;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final list = await s.repositories.users.listTokens();
      if (mounted) {
        setState(() {
          _tokens = list;
          _loadError = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _create() async {
    final l = WonkyAppLocalizations.of(context);
    final r = await showWonkyFormDialog(
      context,
      WonkyDialogSpec(
        title: l.tokenCreate,
        description: l.tokenCreateHint,
        dialogKey: 'dialog.createToken',
        width: 480,
        fields: [
          TextFieldSpec(
            id: 'name',
            label: l.tokenName,
            initial: 'Claude Code',
            maxLength: 100,
            validator: (v) => v.trim().isEmpty ? l.tokenNameRequired : null,
          ),
          for (final scope in McpScope.all)
            if (scope != McpScope.scriptsRun)
              CheckboxFieldSpec(
                id: 'scope:$scope',
                label: mcpScopeLabel(l, scope),
                initial: mcpDefaultScopes.contains(scope),
              ),
          SelectFieldSpec(
            id: 'expiry',
            label: l.tokenExpires,
            options: {
              '30': l.tokenExpiresInDays(30),
              '90': l.tokenExpiresInDays(90),
              '365': l.tokenExpiresInYear,
              'never': l.tokenNever,
            },
            initial: '90',
          ),
        ],
        buttons: [
          DialogButtonSpec(
            id: 'cancel',
            label: l.actionCancel,
            validates: false,
          ),
          DialogButtonSpec(id: 'create', label: l.actionCreate, primary: true),
        ],
      ),
    );
    if (r == null || r.buttonId != 'create' || !mounted) return;
    final scopes = [
      for (final scope in McpScope.all)
        if (r.flag('scope:$scope')) scope,
    ];
    if (scopes.isEmpty) {
      s.toasts.error(l.tokenScopesRequired);
      return;
    }
    final expiry = r.text('expiry');
    final expiresAt = expiry == 'never'
        ? null
        : DateTime.now().toUtc().add(Duration(days: int.parse(expiry)));
    try {
      final created = await s.repositories.users.createToken(
        name: r.text('name').trim(),
        scopes: scopes,
        expiresAt: expiresAt,
      );
      setState(() => _created = created);
      await _reload();
    } catch (e) {
      s.toasts.error(l.errorGeneric, description: errorMessage(e));
    }
  }

  Future<void> _revoke(AccessTokenView t) async {
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.tokenRevokeTitle(t.name),
      description: l.tokenRevokeBody,
      confirmLabel: l.tokenRevoke,
      destructive: true,
    );
    if (!ok) return;
    try {
      await s.repositories.users.revokeToken(t.id);
      if (_created?.token.id == t.id) _created = null;
      await _reload();
    } catch (e) {
      s.toasts.error(l.errorGeneric, description: errorMessage(e));
    }
  }

  void _copy(String text, String toast) {
    Clipboard.setData(ClipboardData(text: text));
    s.toasts.show(toast);
  }

  String _date(DateTime? d) =>
      d == null ? '—' : intl.DateFormat.yMMMd().format(d.toLocal());

  Widget _tokenRow(BuildContext context, AccessTokenView t) {
    final theme = ShadTheme.of(context);
    final l = WonkyAppLocalizations.of(context);
    final revoked = t.revokedAt != null;
    final expired =
        t.expiresAt != null && t.expiresAt!.isBefore(DateTime.now().toUtc());
    final status = revoked
        ? l.tokenRevoked
        : expired
        ? l.tokenExpired
        : null;
    return Padding(
      key: ValueKey<String>('settings.mcp.token.${t.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == null
                      ? t.name
                      : l.tokenNameWithStatus(t.name, status),
                  style: theme.textTheme.small.copyWith(
                    color: status == null
                        ? theme.colorScheme.foreground
                        : theme.colorScheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${t.prefix}… · ${t.scopes.join(', ')}',
                  style: theme.textTheme.muted.copyWith(
                    fontFamily: WonkyFonts.geistMono,
                    fontSize: 12,
                  ),
                ),
                Text(
                  l.tokenDates(
                    _date(t.createdAt),
                    t.expiresAt == null
                        ? l.tokenNeverLower
                        : _date(t.expiresAt),
                    t.lastUsedAt == null
                        ? l.tokenNeverLower
                        : _date(t.lastUsedAt),
                  ),
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          if (!revoked)
            ShadButton.ghost(
              key: ValueKey<String>('settings.mcp.revoke.${t.id}'),
              size: ShadButtonSize.sm,
              onPressed: () => _revoke(t),
              child: Text(l.tokenRevoke),
            ),
        ],
      ),
    );
  }

  Widget _code(BuildContext context, String text, {Key? key}) {
    final theme = ShadTheme.of(context);
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: WonkyFonts.geistMono,
          fontSize: 12,
          color: theme.colorScheme.foreground,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final url = mcpUrl(s);
    final created = _created;
    final token = created?.secret ?? r'${WONKY_TOKEN}';
    final snippets = [
      ('Claude Code', McpConnectionSnippets.claudeCode(url, token)),
      (
        'JSON (.mcp.json, Claude Desktop)',
        McpConnectionSnippets.json(url, token),
      ),
      ('stdio (wonky_mcp_stdio)', McpConnectionSnippets.stdio(url, token)),
    ];
    final bridge = mcpBridgeOf(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          title: l.tokensTitle,
          description: l.tokensHint,
          children: [
            if (created != null)
              ShadAlert(
                key: const ValueKey<String>('settings.mcp.newToken'),
                icon: const Icon(LucideIcons.keyRound),
                title: Text(l.tokenCopyOnce),
                description: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          created.secret,
                          style: TextStyle(
                            fontFamily: WonkyFonts.geistMono,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                      ),
                      ShadButton.outline(
                        key: const ValueKey<String>('settings.mcp.copyToken'),
                        size: ShadButtonSize.sm,
                        onPressed: () =>
                            _copy(created.secret, l.toastTokenCopied),
                        child: Text(l.actionCopy),
                      ),
                    ],
                  ),
                ),
              ),
            if (_loadError != null)
              Text(errorMessage(_loadError!), style: theme.textTheme.muted)
            else if (_tokens == null)
              const Align(alignment: Alignment.centerLeft, child: ShadSpinner())
            else if (_tokens!.isEmpty)
              Text(l.tokensEmpty, style: theme.textTheme.muted)
            else
              Column(
                children: [for (final t in _tokens!) _tokenRow(context, t)],
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton(
                key: const ValueKey<String>('settings.mcp.createToken'),
                onPressed: _create,
                leading: const Icon(LucideIcons.plus, size: 16),
                child: Text(l.tokenCreate),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: l.mcpTitle,
          description:
              '${l.mcpHint} ${l.mcpEndpoint(url)}'
              '${created == null ? ' ${l.mcpReplaceToken(r'${WONKY_TOKEN}')}' : ''}',
          children: [
            Wrap(
              spacing: 6,
              children: [
                for (var i = 0; i < snippets.length; i++)
                  (i == _snippet ? ShadButton.secondary : ShadButton.ghost)(
                    key: ValueKey<String>('settings.mcp.snippet.$i'),
                    size: ShadButtonSize.sm,
                    onPressed: () => setState(() => _snippet = i),
                    child: Text(snippets[i].$1),
                  ),
              ],
            ),
            _code(
              context,
              snippets[_snippet].$2,
              key: const ValueKey<String>('settings.mcp.snippet'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.outline(
                key: const ValueKey<String>('settings.mcp.copySnippet'),
                onPressed: () =>
                    _copy(snippets[_snippet].$2, l.toastMcpConfigCopied),
                leading: const Icon(LucideIcons.copy, size: 16),
                child: Text(l.cmdCopyMcpConfig),
              ),
            ),
          ],
        ),
        SettingsGroup(
          title: l.mcpWindowControl,
          description: l.mcpWindowControlHint,
          children: [
            ListenableBuilder(
              listenable: s.mcp,
              builder: (context, _) => SettingsRow(
                label: l.mcpAllowControl,
                control: ShadSwitch(
                  key: const ValueKey<String>('settings.mcp.bridge'),
                  value: s.mcp.enabled,
                  onChanged: (_) =>
                      s.dispatcher.invoke('shell.mcp.toggleUiBridge'),
                ),
              ),
            ),
            if (bridge != null)
              ListenableBuilder(
                listenable: Listenable.merge([bridge.state, bridge.sessionId]),
                builder: (context, _) => SettingsRow(
                  label: l.mcpBridgeStatus,
                  control: Text(
                    switch (bridge.state.value) {
                      McpBridgeState.off => l.mcpBridgeOff,
                      McpBridgeState.connecting => l.mcpBridgeConnecting,
                      McpBridgeState.connected => l.mcpBridgeConnected(
                        bridge.sessionId.value ?? '',
                      ),
                    },
                    key: const ValueKey<String>('settings.mcp.bridgeStatus'),
                    style: theme.textTheme.small,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
