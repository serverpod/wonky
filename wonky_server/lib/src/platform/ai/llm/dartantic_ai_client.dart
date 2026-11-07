import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' as ai;
import 'package:http/http.dart' as http;

import '../../common/models.dart' show AiProvider;
import 'ai_client.dart';

/// The production [AiModelClient]: OpenAI (Chat Completions), Anthropic
/// (Messages) or Gemini through `package:dartantic_ai` (suite 10 §1). One
/// instance per provider + API key; every [send] creates a dartantic chat
/// model with the request's tools and streams one turn. Tools are never
/// executed by dartantic: the assistant loop runs them through the MCP
/// `ToolExecutor` (permissions, confirmations, undo grouping).
class DartanticAiClient implements AiModelClient {
  DartanticAiClient({
    required this.provider,
    required this._apiKey,
    this.requestTimeout = const Duration(minutes: 10),
    this.idleTimeout = const Duration(minutes: 3),
    this.httpClient,
  });

  @override
  final AiProvider provider;
  final String _apiKey;

  /// Wall-clock limit of one request (suite 10 §1: 10 min).
  final Duration requestTimeout;

  /// Longest silence between two stream chunks.
  final Duration idleTimeout;

  /// The HTTP client of Gemini requests (tests); null = dartantic's own.
  final http.Client? httpClient;

  /// Metadata key of Gemini thought signatures (dartantic's
  /// `GoogleThinkingMetadata.signaturesKey`, not exported).
  static const googleSignaturesKey = '_google_thought_signatures';

  static List<ai.Tool> _tools(List<AiToolSpec> specs) => [
    for (final t in specs)
      ai.Tool<Map<String, dynamic>>(
        name: t.name,
        description: t.description,
        inputSchema: ai.Schema.fromMap(t.inputSchema),
        onCall: (_) =>
            throw StateError('Assistant tools run in the assistant loop.'),
      ),
  ];

  static ai.ReasoningEffort _openAiEffort(String effort) => switch (effort) {
    AiEffort.low => ai.ReasoningEffort.low,
    AiEffort.high => ai.ReasoningEffort.high,
    _ => ai.ReasoningEffort.medium,
  };

  ai.ChatModel<ai.ChatModelOptions> _model(AiRequest r) {
    final tools = r.tools.isEmpty ? null : _tools(r.tools);
    switch (provider) {
      case AiProvider.openai:
        return ai.OpenAIProvider(apiKey: _apiKey).createChatModel(
          name: r.model,
          tools: tools,
          options: ai.OpenAIChatOptions(
            maxTokens: r.maxTokens,
            reasoningEffort: _openAiEffort(r.effort),
            streamOptions: const ai.StreamOptions(includeUsage: true),
            promptCacheKey: r.cacheKey,
            safetyIdentifier: r.userId,
          ),
        );
      case AiProvider.anthropic:
        return ai.AnthropicProvider(apiKey: _apiKey).createChatModel(
          name: r.model,
          tools: tools,
          options: ai.AnthropicChatOptions(
            maxTokens: r.maxTokens,
            userId: r.userId,
          ),
        );
      case AiProvider.gemini:
        return ai.GoogleChatModel(
          name: r.model,
          apiKey: _apiKey,
          baseUrl: ai.GoogleProvider.defaultBaseUrl,
          client: httpClient,
          tools: tools,
          defaultOptions: ai.GoogleChatModelOptions(
            maxOutputTokens: r.maxTokens,
            // Gemini 3 thinks at `high` by default, which makes the fast
            // tier slow. Every Gemini 3 model accepts `low`; medium and
            // high keep the model's default (Pro has no `medium`).
            thinkingLevel: r.effort == AiEffort.low
                ? ai.GoogleThinkingLevel.low
                : null,
          ),
        );
    }
  }

  @override
  Future<AiResponse> send(
    AiRequest request, {
    AiCancelToken? cancel,
    void Function(String delta)? onText,
    void Function(String delta)? onThinking,
  }) async {
    if (cancel?.isCancelled ?? false) throw const AiCancelledException();
    final ai.ChatModel<ai.ChatModelOptions> model;
    try {
      model = _model(request);
    } on Object catch (e) {
      throw AiApiException(0, 'api_error', '$e');
    }
    final acc = AiStreamAccumulator(onText: onText, onThinking: onThinking);
    final messages = [
      if (request.system.isNotEmpty) ai.ChatMessage.system(request.system),
      for (final m in request.messages)
        if (replayable(m) case final r when r.parts.isNotEmpty) r,
    ];
    // dartantic builds the provider request synchronously in `sendStream`
    // (Gemini: message mapping), so its errors are caught here too.
    final StreamIterator<ai.ChatResult<ai.ChatMessage>> it;
    try {
      it = StreamIterator(model.sendStream(messages).timeout(idleTimeout));
    } on Object catch (e) {
      model.dispose();
      throw AiApiException(0, 'request', 'Building the request failed: $e');
    }
    var timedOut = false;
    final deadline = Timer(requestTimeout, () {
      timedOut = true;
      unawaited(it.cancel());
    });
    unawaited(cancel?.whenCancelled.then((_) => it.cancel()));
    try {
      while (await it.moveNext()) {
        acc.add(it.current);
        if (cancel?.isCancelled ?? false) break;
      }
    } on AiCancelledException {
      rethrow;
    } on Object catch (e) {
      if (cancel?.isCancelled ?? false) throw const AiCancelledException();
      throw AiApiException.from(e);
    } finally {
      deadline.cancel();
      unawaited(it.cancel());
      model.dispose();
    }
    if (cancel?.isCancelled ?? false) throw const AiCancelledException();
    if (timedOut) {
      throw AiApiException(0, 'timeout', 'The model did not finish in time.');
    }
    return acc.build();
  }

  /// [m] as dartantic's provider mappers expect it after a JSON round trip
  /// (stored history, [AiStreamAccumulator]'s JSON-safe metadata): Gemini
  /// thought signatures are cast `as List<int>` when a tool call is
  /// replayed, which throws for the `List<dynamic>` that JSON decoding
  /// yields. Without this, every request after a Gemini tool call failed
  /// (the second round of a run, and every later message of the thread).
  /// Thinking-only parts are dropped: they are never replayed and an empty
  /// Gemini turn is rejected.
  static ai.ChatMessage replayable(ai.ChatMessage m) {
    final sigs = m.metadata[googleSignaturesKey];
    final hasThinking = m.parts.any((p) => p is ai.ThinkingPart);
    if (sigs is! Map && !hasThinking) return m;
    return m.copyWith(
      parts: hasThinking
          ? [
              for (final p in m.parts)
                if (p is! ai.ThinkingPart) p,
            ]
          : null,
      metadata: sigs is Map
          ? {
              ...m.metadata,
              googleSignaturesKey: <String, dynamic>{
                for (final e in sigs.entries)
                  if (e.value is List)
                    '${e.key}': <int>[
                      for (final b in e.value as List) (b as num).toInt(),
                    ],
              },
            }
          : null,
    );
  }
}

/// Builds one [AiResponse] from dartantic stream chunks: text and thinking
/// deltas are reported and concatenated, tool calls merged by id, metadata
/// (e.g. Gemini thought signatures) merged, usage counts kept at their
/// maximum (providers report cumulative counts).
class AiStreamAccumulator {
  AiStreamAccumulator({this.onText, this.onThinking});

  final void Function(String delta)? onText;
  final void Function(String delta)? onThinking;

  final StringBuffer _text = StringBuffer();
  final StringBuffer _thinking = StringBuffer();
  final List<ai.ToolPart> _calls = [];
  final Map<String, Object?> _metadata = {};
  ai.FinishReason _finish = ai.FinishReason.unspecified;
  AiTokenUsage _usage = const AiTokenUsage();
  String? _model;

  void add(ai.ChatResult<ai.ChatMessage> r) {
    final chunk = r.output.parts.isEmpty && r.messages.isNotEmpty
        ? r.messages.first
        : r.output;
    final hasCalls = chunk.parts.any(
      (p) => p is ai.ToolPart && p.kind == ai.ToolPartKind.call,
    );
    for (final p in chunk.parts) {
      switch (p) {
        case ai.TextPart(:final text):
          if (text.isEmpty) continue;
          // Some providers repeat the whole text in the final chunk that
          // carries the tool calls.
          if (hasCalls && _text.isNotEmpty && text == _text.toString()) {
            continue;
          }
          _text.write(text);
          onText?.call(text);
        case ai.ThinkingPart(:final text):
          if (text.isEmpty) continue;
          _thinking.write(text);
          onThinking?.call(text);
        case ai.ToolPart(kind: ai.ToolPartKind.call):
          final i = _calls.indexWhere(
            (c) => c.callId.isNotEmpty && c.callId == p.callId,
          );
          if (i < 0) {
            _calls.add(p);
          } else {
            final old = _calls[i];
            _calls[i] = ai.ToolPart.call(
              callId: p.callId,
              toolName: p.toolName.isNotEmpty ? p.toolName : old.toolName,
              arguments: (p.arguments?.isNotEmpty ?? false)
                  ? p.arguments!
                  : old.arguments ?? const {},
            );
          }
        default:
          break;
      }
    }
    _metadata.addAll(chunk.metadata);
    if (r.finishReason != ai.FinishReason.unspecified) {
      _finish = r.finishReason;
    }
    final u = r.usage;
    if (u != null) {
      _usage = _usage.merge(
        AiTokenUsage(
          inputTokens: u.promptTokens ?? 0,
          outputTokens: u.responseTokens ?? 0,
        ),
      );
    }
    final m = r.metadata['model'];
    if (m is String && m.isNotEmpty) _model = m;
  }

  AiResponse build() {
    final parts = <ai.StandardPart>[
      if (_text.isNotEmpty) ai.TextPart(_text.toString()),
      if (_thinking.isNotEmpty) ai.ThinkingPart(_thinking.toString()),
      ..._calls,
    ];
    final stop = switch (_finish) {
      ai.FinishReason.length => AiStopReason.maxTokens,
      ai.FinishReason.contentFilter ||
      ai.FinishReason.recitation => AiStopReason.refusal,
      _ => _calls.isNotEmpty ? AiStopReason.toolUse : AiStopReason.endTurn,
    };
    return AiResponse(
      message: ai.ChatMessage(
        role: ai.ChatMessageRole.model,
        parts: parts,
        metadata: _jsonSafe(_metadata) as Map<String, Object?>,
      ),
      stopReason: stop,
      usage: _usage,
      model: _model,
    );
  }

  /// Metadata is persisted with the message (JSON).
  static Object? _jsonSafe(Object? v) => switch (v) {
    null || String() || num() || bool() => v,
    Map() => <String, Object?>{
      for (final e in v.entries)
        if (_jsonSafe(e.value) != _drop) '${e.key}': _jsonSafe(e.value),
    },
    Iterable() => [for (final e in v) _jsonSafe(e)],
    DateTime() => v.toUtc().toIso8601String(),
    _ => _drop,
  };

  static const _drop = Object();
}
