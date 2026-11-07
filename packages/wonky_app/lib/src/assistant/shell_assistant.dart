import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;

import '../commands/shell_commands/general_commands.dart' show ShellPanels;
import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';
import 'assistant_adapter.dart';
import 'assistant_api.dart';
import 'assistant_controller.dart';
import 'style_guides/style_guide_library.dart';

/// The localized explanation of an unavailable [status] (the server's
/// English `message` only for reasons the app doesn't know).
String assistantStatusMessage(
  WonkyAppLocalizations l,
  AssistantStatus status,
) => switch (status.reason) {
  'notConfigured' => l.aiNotConfigured,
  'disabled' => l.aiDisabled,
  'optedOut' => l.aiOptedOut,
  _ => status.message ?? l.aiNotConfigured,
};

/// The display name of [provider].
String aiProviderName(WonkyAppLocalizations l, AiProvider provider) =>
    switch (provider) {
      AiProvider.openai => l.aiProviderOpenai,
      AiProvider.anthropic => l.aiProviderAnthropic,
      AiProvider.gemini => l.aiProviderGemini,
    };

/// The privacy notice of [status]: names the provider content goes to.
String assistantPrivacyNotice(
  WonkyAppLocalizations l,
  AssistantStatus? status,
) {
  final p = status?.provider;
  return p == null
      ? l.assistantPrivacyNotice
      : l.assistantPrivacyNoticeProvider(aiProviderName(l, p));
}

/// Opens Settings › AI providers (where users add their own key) through
/// the `shell.settings.open` command.
void openAiProviderSettings(ShellServices services, BuildContext context) =>
    services.dispatcher.invoke(
      'shell.settings.open',
      args: const {'section': ShellAssistant.aiProvidersSection},
      source: InvocationSource.menu,
      context: context,
    );

/// The installed assistant (suite 10 §3): the shared [AssistantHook] the
/// `shell.ai.*` commands and the ✨ buttons use. Apps create one
/// [AssistantController] per open file with [controllerFor].
class ShellAssistant extends AssistantHook {
  ShellAssistant(this.services, this.api);

  final ShellServices services;
  final AssistantApi api;

  /// Availability, quality and usage (null until loaded).
  final ValueNotifier<AssistantStatus?> status = ValueNotifier(null);

  final Map<String, AssistantController> _controllers = {};

  static const applyModeKey = 'ai.applyMode';

  /// The installed assistant of [services].
  static ShellAssistant? of(ShellServices services) {
    final a = services.assistant;
    return a is ShellAssistant ? a : null;
  }

  /// Installs the assistant (after sign-in) and loads its status.
  static ShellAssistant install(ShellServices services, {AssistantApi? api}) {
    final existing = of(services);
    if (existing != null) return existing;
    final client = services.client;
    final a = ShellAssistant(
      services,
      api ??
          (client == null
              ? const _UnavailableApi()
              : ServerAssistantApi(client)),
    );
    services.assistant = a;
    // Style guide changes are undoable (suite 10 §7).
    services.undo.registerHandler(StyleGuideUndoHandler(services));
    unawaited(a.refreshStatus());
    services.registry.notifyStateChanged();
    return a;
  }

  /// Removes the assistant (sign-out).
  static void uninstall(ShellServices services) {
    final a = of(services);
    if (a == null) return;
    for (final c in a._controllers.values.toList()) {
      c.dispose();
    }
    a._controllers.clear();
    services.assistant = null;
  }

  /// The panel is offered unless AI is switched off on the server; when
  /// the key is missing it explains that AI isn't configured.
  @override
  bool get available => status.value?.reason != 'disabled';

  /// Whether requests can be sent now.
  bool get usable => status.value?.available ?? false;

  Future<void> refreshStatus() async {
    try {
      status.value = await api.getStatus();
    } on Object {
      // Offline: keep the last status.
    }
    services.registry.notifyStateChanged();
  }

  Future<void> setQuality(AiQuality quality) async {
    status.value = await api.setQuality(quality);
  }

  /// Settings › AI providers: saves the user's own key.
  Future<void> setProviderKey(AiProvider provider, String apiKey) async {
    status.value = await api.setProviderKey(provider, apiKey);
    services.registry.notifyStateChanged();
  }

  /// Settings › AI providers › Remove key.
  Future<void> removeProviderKey() async {
    status.value = await api.removeProviderKey();
    services.registry.notifyStateChanged();
  }

  /// Settings › AI providers › organization key › Share key.
  Future<void> setOrgProviderKey(AiProvider provider, String apiKey) async {
    status.value = await api.setOrgProviderKey(provider, apiKey);
    services.registry.notifyStateChanged();
  }

  /// Settings › AI providers › organization key › Remove key.
  Future<void> removeOrgProviderKey() async {
    status.value = await api.removeOrgProviderKey();
    services.registry.notifyStateChanged();
  }

  /// The settings section id of Settings › AI providers.
  static const aiProvidersSection = 'ai-providers';

  /// The controller of [adapter]'s file (created on first use).
  AssistantController controllerFor(AssistantDocumentAdapter adapter) {
    final key = adapter.itemUuid.uuid;
    final existing = _controllers[key];
    if (existing != null && identical(existing.adapter, adapter)) {
      return existing;
    }
    existing?.dispose();
    final mode = services.prefs.device<String>(applyModeKey);
    final c = AssistantController(
      api: api,
      adapter: adapter,
      status: status,
      initialApplyMode: mode == 'suggest'
          ? AiApplyMode.suggest
          : AiApplyMode.edit,
      onApplyModeChanged: (m) =>
          unawaited(services.prefs.setDevice(applyModeKey, m.name)),
      onStatusStale: () => unawaited(refreshStatus()),
    );
    return _controllers[key] = c;
  }

  /// Disposes the controller of [adapter] (the editor closed).
  void release(AssistantDocumentAdapter adapter) {
    final key = adapter.itemUuid.uuid;
    final c = _controllers[key];
    if (c != null && identical(c.adapter, adapter)) {
      _controllers.remove(key)?.dispose();
    }
  }

  /// The controller of the open file.
  AssistantController? get active {
    final item = services.currentItem.value;
    if (item == null) return null;
    return _controllers[item.uuid.uuid];
  }

  @override
  Future<void> newThread() async => active?.newThread();

  @override
  Future<void> send(String prompt) async {
    final c = active;
    if (c == null) return;
    services.panels.open(panelId);
    await c.send(prompt);
  }

  @override
  Future<void> stop() async => active?.stop();

  /// Opens the panel.
  void openPanel() => services.panels.open(ShellPanels.assistant);
}

/// Used when there is no client (widget tests without a fake).
class _UnavailableApi implements AssistantApi {
  const _UnavailableApi();

  Never _fail() => throw WonkyException(
    code: WonkyErrorCode.unavailable,
    message: "AI isn't configured on this server.",
  );

  @override
  Future<AssistantStatus> getStatus() async => AssistantStatus(
    available: false,
    reason: 'notConfigured',
    message: "AI isn't configured on this server.",
    quality: AiQuality.best,
    tokensUsedToday: 0,
    dailyTokenBudget: 0,
  );

  @override
  Future<AssistantStatus> setQuality(AiQuality quality) => getStatus();

  @override
  Future<AssistantStatus> setProviderKey(AiProvider provider, String apiKey) =>
      _fail();

  @override
  Future<AssistantStatus> removeProviderKey() => getStatus();

  @override
  Future<AssistantStatus> setOrgProviderKey(
    AiProvider provider,
    String apiKey,
  ) => _fail();

  @override
  Future<AssistantStatus> removeOrgProviderKey() => getStatus();

  @override
  Stream<AssistantEvent> chat({
    required int? threadId,
    required UuidValue itemUuid,
    required String message,
    required AssistantContextHints hints,
  }) => Stream.error(_failError);

  static final _failError = WonkyException(
    code: WonkyErrorCode.unavailable,
    message: "AI isn't configured on this server.",
  );

  @override
  Stream<AssistantEvent> quickAction({
    required int? threadId,
    required UuidValue itemUuid,
    required AssistantQuickAction action,
    required AssistantContextHints hints,
  }) => Stream.error(_failError);

  @override
  Future<bool> stop({int? threadId, String? runId}) async => false;

  @override
  Future<bool> confirm(String runId, String confirmationId, bool allow) async =>
      false;

  @override
  Future<bool> uiToolResult(String runId, UiBridgeResponse response) async =>
      false;

  @override
  Future<List<AssistantThreadView>> listThreads(UuidValue itemUuid) async =>
      const [];

  @override
  Future<AssistantThreadDetail> getThread(int threadId) async => _fail();

  @override
  Future<void> deleteThread(int threadId) async {}

  @override
  Future<int> clearHistory() async => 0;

  @override
  Future<void> revertChange(String changeId) async => _fail();

  @override
  Stream<InlineAiEvent> inline(InlineAiRequest request) =>
      Stream.error(_failError);

  @override
  Stream<ProofreadEvent> proofread(
    UuidValue itemUuid, {
    int? start,
    int? length,
  }) => Stream.error(_failError);

  @override
  Future<StyleGuideLibrary> styleGuides({UuidValue? itemUuid}) async => _fail();

  @override
  Future<StyleGuideView> saveStyleGuide(StyleGuideInput input) async => _fail();

  @override
  Future<void> deleteStyleGuide(UuidValue uuid) async => _fail();

  @override
  Future<StyleGuideLibrary> setOrgStyleGuide(String? ref) async => _fail();

  @override
  Future<StyleGuideLibrary> setDocumentStyleGuide(
    UuidValue itemUuid,
    String? ref,
  ) async => _fail();
}
