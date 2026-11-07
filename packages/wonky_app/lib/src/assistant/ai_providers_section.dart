import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';

import '../l10n/wonky_app_localizations.dart';
import '../settings/settings_screen.dart';
import '../shell/dialogs.dart';
import '../shell/shell_services.dart';
import 'shell_assistant.dart';

/// Settings › AI providers (suite 10 §1 "Keys", 04 §4): which provider the
/// AI features use, and — when the server has no key of its own — the
/// user's own OpenAI, Anthropic or Gemini key. The key is sent once, stored
/// on the server and never shown again (only the provider and its last
/// four characters).
class AiProvidersSection extends StatefulWidget {
  const AiProvidersSection({super.key, required this.services});

  final ShellServices services;

  @override
  State<AiProvidersSection> createState() => _AiProvidersSectionState();
}

class _AiProvidersSectionState extends State<AiProvidersSection> {
  final _key = TextEditingController();
  AiProvider _provider = AiProvider.openai;
  bool _busy = false;

  // The organization's shared key (suite 10 §1 "Keys").
  final _orgKey = TextEditingController();
  AiProvider _orgProvider = AiProvider.openai;
  bool _orgBusy = false;

  ShellAssistant? get _assistant => ShellAssistant.of(widget.services);

  @override
  void initState() {
    super.initState();
    final a = _assistant;
    final current = a?.status.value?.userKey?.provider;
    if (current != null) _provider = current;
    final shared = a?.status.value?.orgKey?.provider;
    if (shared != null) _orgProvider = shared;
    if (a != null) unawaited(a.refreshStatus());
  }

  @override
  void dispose() {
    _key.dispose();
    _orgKey.dispose();
    super.dispose();
  }

  /// Shares the typed key with the organization, after confirming that
  /// everyone with an email at [org] can then use it.
  Future<void> _saveOrg(String org) async {
    final a = _assistant;
    final key = _orgKey.text.trim();
    if (a == null || key.isEmpty || _orgBusy) return;
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.aiOrgKeyConfirmTitle(org),
      description: l.aiOrgKeyWarning(org),
      confirmLabel: l.aiOrgKeySave,
    );
    if (!ok || !mounted) return;
    setState(() => _orgBusy = true);
    try {
      await a.setOrgProviderKey(_orgProvider, key);
      _orgKey.clear();
      widget.services.toasts.show(l.aiOrgKeySaved(org));
    } on WonkyException catch (e) {
      widget.services.toasts.error(e.message);
    } on Object {
      widget.services.toasts.error(l.aiProvidersSaveFailed);
    } finally {
      if (mounted) setState(() => _orgBusy = false);
    }
  }

  Future<void> _removeOrg(String org) async {
    final a = _assistant;
    if (a == null) return;
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.aiOrgKeyRemoveTitle(org),
      description: l.aiOrgKeyRemoveBody(org),
      confirmLabel: l.aiProvidersRemove,
      destructive: true,
    );
    if (!ok) return;
    try {
      await a.removeOrgProviderKey();
      widget.services.toasts.show(l.aiOrgKeyRemoved);
    } on Object {
      widget.services.toasts.error(l.aiProvidersRemoveFailed);
    }
  }

  /// A provider select and a key field with [save] (the personal key and
  /// the organization's share the layout).
  Widget _keyForm({
    required String keyPrefix,
    required AiProvider provider,
    required ValueChanged<AiProvider> onProvider,
    required TextEditingController controller,
    required bool busy,
    required String saveLabel,
    required VoidCallback save,
  }) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        SettingsRow(
          label: l.aiProvidersProvider,
          control: ShadSelect<AiProvider>(
            key: ValueKey<String>('$keyPrefix.provider'),
            initialValue: provider,
            minWidth: 180,
            options: [
              for (final p in AiProvider.values)
                ShadOption(value: p, child: Text(aiProviderName(l, p))),
            ],
            selectedOptionBuilder: (context, p) => Text(aiProviderName(l, p)),
            onChanged: (p) {
              if (p != null) onProvider(p);
            },
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(l.aiProvidersKey, style: theme.textTheme.small),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: ShadInput(
                    key: ValueKey<String>('$keyPrefix.key'),
                    controller: controller,
                    obscureText: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    placeholder: Text(l.aiProvidersKeyPlaceholder),
                    onSubmitted: (_) => save(),
                  ),
                ),
                ListenableBuilder(
                  listenable: controller,
                  builder: (context, _) => ShadButton(
                    key: ValueKey<String>('$keyPrefix.save'),
                    enabled: !busy && controller.text.trim().isNotEmpty,
                    onPressed: save,
                    child: Text(saveLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// The organization's shared key: the warning, the current key (who
  /// added it) with *Remove key*, and the form to share one.
  Widget _orgGroup(AssistantStatus status, String org) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final current = status.orgKey;
    return SettingsGroup(
      title: l.aiOrgKeyTitle(org),
      description: l.aiOrgKeyHint(org),
      children: [
        ShadAlert(
          key: const ValueKey<String>('settings.aiProviders.orgWarning'),
          icon: const Icon(LucideIcons.triangleAlert),
          description: Text(l.aiOrgKeyWarning(org)),
        ),
        if (current != null)
          SettingsRow(
            label: l.aiOrgKeyCurrent,
            description: l.aiOrgKeyCurrentBy(
              aiProviderName(l, current.provider),
              current.last4,
              current.addedBy ?? '—',
            ),
            control: ShadButton.outline(
              key: const ValueKey<String>('settings.aiProviders.orgRemove'),
              onPressed: () => unawaited(_removeOrg(org)),
              child: Text(l.aiProvidersRemove),
            ),
          ),
        if (status.keySource == 'organization')
          Text(
            l.aiOrgKeyInUse(org),
            key: const ValueKey<String>('settings.aiProviders.orgInUse'),
            style: theme.textTheme.muted,
          ),
        _keyForm(
          keyPrefix: 'settings.aiProviders.org',
          provider: _orgProvider,
          onProvider: (p) => setState(() => _orgProvider = p),
          controller: _orgKey,
          busy: _orgBusy,
          saveLabel: l.aiOrgKeySave,
          save: () => unawaited(_saveOrg(org)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final a = _assistant;
    final key = _key.text.trim();
    if (a == null || key.isEmpty || _busy) return;
    final l = WonkyAppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await a.setProviderKey(_provider, key);
      _key.clear();
      widget.services.toasts.show(l.aiProvidersSaved);
    } on WonkyException catch (e) {
      widget.services.toasts.error(e.message);
    } on Object {
      widget.services.toasts.error(l.aiProvidersSaveFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final a = _assistant;
    if (a == null) return;
    final l = WonkyAppLocalizations.of(context);
    final ok = await confirmDialog(
      context,
      title: l.aiProvidersRemoveTitle,
      description: l.aiProvidersRemoveBody,
      confirmLabel: l.aiProvidersRemove,
      destructive: true,
    );
    if (!ok) return;
    try {
      await a.removeProviderKey();
      widget.services.toasts.show(l.aiProvidersRemoved);
    } on Object {
      widget.services.toasts.error(l.aiProvidersRemoveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = _assistant;
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([?a?.status]),
      builder: (context, _) {
        final status = a?.status.value;
        if (status == null) {
          return SettingsGroup(
            title: l.settingsAiProviders,
            children: [Text(l.aiNotConfigured, style: theme.textTheme.muted)],
          );
        }
        if (status.reason == 'disabled') {
          return SettingsGroup(
            title: l.settingsAiProviders,
            children: [
              Text(
                l.aiDisabled,
                key: const ValueKey<String>('settings.aiProviders.disabled'),
                style: theme.textTheme.muted,
              ),
            ],
          );
        }
        if (status.keySource == 'server' && status.provider != null) {
          return SettingsGroup(
            title: l.aiProvidersServerTitle,
            children: [
              Text(
                l.aiProvidersServerBody(aiProviderName(l, status.provider!)),
                key: const ValueKey<String>('settings.aiProviders.server'),
              ),
            ],
          );
        }
        if (!status.userKeysAllowed) {
          return SettingsGroup(
            title: l.settingsAiProviders,
            children: [
              Text(
                l.aiProvidersNotAllowed,
                key: const ValueKey<String>('settings.aiProviders.notAllowed'),
                style: theme.textTheme.muted,
              ),
            ],
          );
        }
        final current = status.userKey;
        final org = status.organization;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsGroup(
              title: l.aiProvidersKeyTitle,
              description: l.aiProvidersKeyHint,
              children: [
                if (current != null)
                  SettingsRow(
                    label: l.aiProvidersCurrent,
                    description: l.aiProvidersCurrentValue(
                      aiProviderName(l, current.provider),
                      current.last4,
                    ),
                    control: ShadButton.outline(
                      key: const ValueKey<String>(
                        'settings.aiProviders.remove',
                      ),
                      onPressed: () => unawaited(_remove()),
                      child: Text(l.aiProvidersRemove),
                    ),
                  ),
                _keyForm(
                  keyPrefix: 'settings.aiProviders',
                  provider: _provider,
                  onProvider: (p) => setState(() => _provider = p),
                  controller: _key,
                  busy: _busy,
                  saveLabel: l.aiProvidersSave,
                  save: () => unawaited(_save()),
                ),
              ],
            ),
            // Only members of an organization (not public mail providers).
            if (org != null) _orgGroup(status, org),
          ],
        );
      },
    );
  }
}
