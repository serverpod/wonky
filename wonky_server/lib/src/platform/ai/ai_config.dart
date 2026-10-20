import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../config/wonky_config.dart';
import '../config/wonky_config_file.dart';
import 'ai_models.dart';
import 'llm/ai_client.dart';
import 'llm/dartantic_ai_client.dart';

/// The two models of a provider.
class AiProviderModels {
  const AiProviderModels(this.model, this.fastModel);

  /// Best and Balanced.
  final String model;

  /// Fast and inline completions.
  final String fastModel;
}

/// Settings of the AI features from the `wonky: ai:` section of
/// `config/<runMode>.yaml` (suite 10 §1):
///
/// ```yaml
/// wonky:
///   features:
///     ai: true                      # server-wide switch (also feature flag)
///   ai:
///     enabled: true
///     provider: anthropic           # openai | anthropic | gemini (optional)
///     allowUserKeys: true           # users may add their own key when the
///                                   # server has none
///     models:                       # optional; defaults in AiModels
///       anthropic: {model: claude-opus-5-5, fastModel: claude-haiku-5-5}
///       openai: {model: gpt-5, fastModel: gpt-5-mini}
///       gemini: {model: gemini-3.1-pro-preview, fastModel: gemini-3.8-flash}
///     dailyTokenBudget: 2000000     # per user, all models
///     maxConcurrentRequests: 2      # per user
///     requestTimeoutMinutes: 10
///     maxToolRounds: 30             # model requests per assistant run
///     historyTokenBudget: 100000    # thread history per request (estimate)
///     maxRunTokens: 600000          # budget tokens per assistant run
/// ```
///
/// Server API keys are Serverpod passwords (`config/passwords.yaml` or
/// `SERVERPOD_PASSWORD_<name>`): `anthropicApiKey`, `openaiApiKey`,
/// `geminiApiKey`. The server uses `provider` when its key is set, else the
/// first provider with a key (Anthropic, OpenAI, Gemini). Without any key,
/// users can add their own (Settings › AI providers, `AiKeys`).
/// Environment overrides: `WONKY_AI_ENABLED`, `WONKY_AI_PROVIDER`,
/// `WONKY_AI_ALLOW_USER_KEYS`, `WONKY_AI_DAILY_TOKEN_BUDGET`, ….
class AiConfig {
  AiConfig({
    this.enabled = true,
    Map<AiProvider, String> serverKeys = const {},
    this.provider,
    this.allowUserKeys = true,
    Map<AiProvider, AiProviderModels> models = const {},
    this.dailyTokenBudget = 2000000,
    this.maxConcurrentRequests = 2,
    this.requestTimeout = const Duration(minutes: 10),
    this.maxToolRounds = 30,
    this.historyTokenBudget = 100000,
    this.maxRunTokens = 600000,
  }) : serverKeys = {
         for (final e in serverKeys.entries)
           if (e.value.trim().isNotEmpty) e.key: e.value.trim(),
       },
       models = Map.unmodifiable(models);

  /// Password names of the server keys.
  static const passwordNames = {
    AiProvider.anthropic: 'anthropicApiKey',
    AiProvider.openai: 'openaiApiKey',
    AiProvider.gemini: 'geminiApiKey',
  };

  /// Order in which a provider with a server key is picked when
  /// [provider] is unset (or has no key).
  static const preference = [
    AiProvider.anthropic,
    AiProvider.openai,
    AiProvider.gemini,
  ];

  /// `features.ai` and `ai.enabled`.
  final bool enabled;

  /// Non-empty server keys by provider.
  final Map<AiProvider, String> serverKeys;

  /// The configured provider (`ai.provider`).
  final AiProvider? provider;

  /// Whether users may add their own key when the server has none.
  final bool allowUserKeys;

  /// Model overrides per provider.
  final Map<AiProvider, AiProviderModels> models;
  final int dailyTokenBudget;
  final int maxConcurrentRequests;
  final Duration requestTimeout;

  /// Model requests per assistant run before it stops.
  final int maxToolRounds;

  /// Estimated tokens of thread history sent with each request: older tool
  /// results are elided, then the oldest exchanges left out
  /// (`AssistantHistory.fit`, CQ-31).
  final int historyTokenBudget;

  /// Budget tokens one assistant run may use before it stops (input and
  /// output of all its rounds).
  final int maxRunTokens;

  /// The provider the server's own key is used with (null = no server key).
  AiProvider? get serverProvider {
    final p = provider;
    if (p != null && serverKeys.containsKey(p)) return p;
    for (final x in preference) {
      if (serverKeys.containsKey(x)) return x;
    }
    return null;
  }

  /// Whether the server has a key of its own.
  bool get configured => serverProvider != null;

  /// Whether users may add their own keys now.
  bool get userKeysAllowed => enabled && allowUserKeys && !configured;

  /// The model id of [provider] for [size].
  String modelFor(AiProvider provider, AiModelSize size) {
    final o = models[provider];
    final d = AiModels.defaults(provider);
    return switch (size) {
      AiModelSize.large => o?.model ?? d.$1,
      AiModelSize.small => o?.fastModel ?? d.$2,
    };
  }

  static AiConfig? _current;

  /// The configuration of the running server (loaded on first use).
  static AiConfig get current => _current ??= _load();

  /// Replaces the configuration (tests).
  static set current(AiConfig config) {
    _current = config;
    _clients.clear();
  }

  /// A client used instead of the provider clients (tests, fixtures).
  static AiModelClient? clientOverride;

  static final Map<(AiProvider, String), AiModelClient> _clients = {};

  /// The model client for [provider] with [apiKey]: [clientOverride] in
  /// tests, else a (cached) [DartanticAiClient].
  static AiModelClient clientFor(AiProvider provider, String apiKey) {
    final o = clientOverride;
    if (o != null) return o;
    if (_clients.length > 256) _clients.clear();
    return _clients[(provider, apiKey)] ??= DartanticAiClient(
      provider: provider,
      apiKey: apiKey,
      requestTimeout: current.requestTimeout,
    );
  }

  static AiConfig _load() {
    final keys = <AiProvider, String>{};
    final section = WonkyConfigFile.section('ai');
    try {
      final pod = Serverpod.instance;
      for (final e in passwordNames.entries) {
        final k = pod.getPassword(e.value);
        if (k != null) keys[e.key] = k;
      }
    } on StateError {
      // No server (unit tests, tools): no server keys.
    }
    return fromMap(
      section,
      serverKeys: keys,
      featureEnabled: WonkyConfig.current.aiEnabled,
      environment: Platform.environment,
    );
  }

  /// Parses a provider name (`openai`, `anthropic`, `gemini`; `google` and
  /// `claude` are accepted aliases).
  static AiProvider? parseProvider(Object? v) {
    final s = '${v ?? ''}'.trim().toLowerCase();
    return switch (s) {
      'openai' => AiProvider.openai,
      'anthropic' || 'claude' => AiProvider.anthropic,
      'gemini' || 'google' => AiProvider.gemini,
      _ => null,
    };
  }

  /// Builds a configuration from the `wonky: ai:` [map].
  static AiConfig fromMap(
    Map<dynamic, dynamic> map, {
    Map<AiProvider, String> serverKeys = const {},
    bool featureEnabled = true,
    Map<String, String> environment = const {},
  }) {
    Object? read(String key, String env) => environment[env] ?? map[key];
    bool b(String key, String env, bool fallback) {
      final v = read(key, env);
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    int i(String key, String env, int fallback) {
      final v = read(key, env);
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final models = <AiProvider, AiProviderModels>{};
    final m = map['models'];
    if (m is Map) {
      for (final e in m.entries) {
        final p = parseProvider(e.key);
        final v = e.value;
        if (p == null || v is! Map) continue;
        final d = AiModels.defaults(p);
        models[p] = AiProviderModels(
          '${v['model'] ?? d.$1}',
          '${v['fastModel'] ?? d.$2}',
        );
      }
    }

    return AiConfig(
      enabled: featureEnabled && b('enabled', 'WONKY_AI_ENABLED', true),
      serverKeys: serverKeys,
      provider: parseProvider(read('provider', 'WONKY_AI_PROVIDER')),
      allowUserKeys: b('allowUserKeys', 'WONKY_AI_ALLOW_USER_KEYS', true),
      models: models,
      dailyTokenBudget: i(
        'dailyTokenBudget',
        'WONKY_AI_DAILY_TOKEN_BUDGET',
        2000000,
      ),
      maxConcurrentRequests: i(
        'maxConcurrentRequests',
        'WONKY_AI_MAX_CONCURRENT_REQUESTS',
        2,
      ),
      requestTimeout: Duration(
        minutes: i(
          'requestTimeoutMinutes',
          'WONKY_AI_REQUEST_TIMEOUT_MINUTES',
          10,
        ),
      ),
      maxToolRounds: i('maxToolRounds', 'WONKY_AI_MAX_TOOL_ROUNDS', 30),
      historyTokenBudget: i(
        'historyTokenBudget',
        'WONKY_AI_HISTORY_TOKEN_BUDGET',
        100000,
      ),
      maxRunTokens: i('maxRunTokens', 'WONKY_AI_MAX_RUN_TOKENS', 600000),
    );
  }
}
