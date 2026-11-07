import 'dart:async';

import 'package:dartantic_ai/dartantic_ai.dart' show ChatMessage, ToolPart;

import '../../common/models.dart' show AiProvider;

export 'package:dartantic_ai/dartantic_ai.dart'
    show
        ChatMessage,
        ChatMessageRole,
        StandardPart,
        TextPart,
        ThinkingPart,
        ToolPart,
        ToolPartKind;

/// Effort levels. Sent as `reasoning_effort` to OpenAI; Anthropic and
/// Gemini use their model defaults (dartantic_ai has no effort option for
/// them).
abstract final class AiEffort {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';
}

/// Why a model turn ended, normalized across providers.
abstract final class AiStopReason {
  /// The model finished its answer.
  static const endTurn = 'end_turn';

  /// The model called tools (the loop executes them and continues).
  static const toolUse = 'tool_use';

  /// The output limit cut the answer off.
  static const maxTokens = 'max_tokens';

  /// The provider blocked the answer (content filter, recitation).
  static const refusal = 'refusal';
}

/// A tool as the model sees it (an MCP tool bound to the open document).
class AiToolSpec {
  const AiToolSpec({
    required this.name,
    required this.description,
    required this.inputSchema,
  });

  /// `^[a-zA-Z0-9_-]{1,64}$` (valid for every provider).
  final String name;
  final String description;

  /// JSON schema of the input (an object schema).
  final Map<String, Object?> inputSchema;
}

/// One streamed model turn. Provider-agnostic: the [AiModelClient] maps it
/// to the provider's API (through `dartantic_ai`).
class AiRequest {
  const AiRequest({
    required this.model,
    required this.messages,
    this.system = '',
    this.tools = const [],
    this.effort = AiEffort.medium,
    this.maxTokens = 64000,
    this.userId,
    this.feature = 'chat',
    this.cacheKey,
  });

  /// The provider's model id (from `AiConfig.modelFor`).
  final String model;

  /// The system prompt (frozen per feature; no volatile data).
  final String system;

  /// The conversation, replayed verbatim (append-only).
  final List<ChatMessage> messages;

  /// Tools, in a deterministic order (keeps provider-side prompt caches
  /// warm).
  final List<AiToolSpec> tools;
  final String effort;
  final int maxTokens;

  /// Opaque user id for abuse monitoring (`u<id>`).
  final String? userId;

  /// Usage accounting label (chat, rewrite, proofread, …).
  final String feature;

  /// A stable key for provider-side prompt caching (OpenAI
  /// `prompt_cache_key`), e.g. the thread.
  final String? cacheKey;
}

/// Token usage of one response.
class AiTokenUsage {
  const AiTokenUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cacheReadTokens = 0,
    this.cacheWriteTokens = 0,
  });

  final int inputTokens;
  final int outputTokens;

  /// Not reported through dartantic_ai (always 0 there); kept for the
  /// `AiUsage` table and fakes.
  final int cacheReadTokens;
  final int cacheWriteTokens;

  int get total =>
      inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens;

  /// Merges cumulative counts of a later stream chunk.
  AiTokenUsage merge(AiTokenUsage o) => AiTokenUsage(
    inputTokens: o.inputTokens > inputTokens ? o.inputTokens : inputTokens,
    outputTokens: o.outputTokens > outputTokens ? o.outputTokens : outputTokens,
    cacheReadTokens: o.cacheReadTokens > cacheReadTokens
        ? o.cacheReadTokens
        : cacheReadTokens,
    cacheWriteTokens: o.cacheWriteTokens > cacheWriteTokens
        ? o.cacheWriteTokens
        : cacheWriteTokens,
  );

  @override
  String toString() =>
      'in=$inputTokens out=$outputTokens cacheRead=$cacheReadTokens '
      'cacheWrite=$cacheWriteTokens';
}

/// A complete (streamed) model turn.
class AiResponse {
  AiResponse({
    required this.message,
    required this.stopReason,
    this.usage = const AiTokenUsage(),
    this.model,
  });

  /// The model's message (role `model`): text, tool calls and provider
  /// metadata (e.g. Gemini thought signatures) to replay verbatim.
  final ChatMessage message;

  /// One of [AiStopReason].
  final String stopReason;
  final AiTokenUsage usage;

  /// The model that answered, when the provider reports it.
  final String? model;

  String get text => message.text;

  List<ToolPart> get toolCalls => message.toolCalls;

  /// Whether the message has anything worth replaying.
  bool get hasContent => message.parts.isNotEmpty;
}

/// A failed request (after the SDK's retries).
class AiApiException implements Exception {
  AiApiException(this.statusCode, this.type, this.message);

  /// Maps an exception of a provider SDK (thrown through dartantic_ai) by
  /// its HTTP status and class name.
  factory AiApiException.from(Object e) {
    if (e is AiApiException) return e;
    if (e is TimeoutException) {
      return AiApiException(0, 'timeout', 'The model did not respond in time.');
    }
    final name = e.runtimeType.toString();
    final text = '$e';
    var status = 0;
    final m = RegExp(r'\b([45]\d\d)\b').firstMatch(text);
    if (m != null) status = int.parse(m.group(1)!);
    if (name.contains('Authentication')) status = 401;
    if (name.contains('PermissionDenied')) status = 403;
    if (name.contains('RateLimit')) status = 429;
    final type = name.contains('Timeout')
        ? 'timeout'
        : name.contains('Refusal')
        ? 'refusal'
        : status == 0
        ? 'connection_error'
        : 'api_error';
    return AiApiException(status, type, text);
  }

  /// HTTP status; 0 for connection failures and timeouts.
  final int statusCode;

  /// `api_error`, `connection_error`, `timeout`, `refusal` or `request`
  /// (the request could not be built from the conversation).
  final String type;
  final String message;

  bool get isAuth => statusCode == 401 || statusCode == 403;
  bool get isRateLimit => statusCode == 429;
  bool get isOverloaded => statusCode == 529 || statusCode == 503;

  @override
  String toString() => 'AiApiException($statusCode $type: $message)';
}

/// Cancels a running request (the user pressed Stop).
class AiCancelToken {
  final Completer<void> _done = Completer<void>();

  bool get isCancelled => _done.isCompleted;

  /// Completes when cancelled.
  Future<void> get whenCancelled => _done.future;

  void cancel() {
    if (!_done.isCompleted) _done.complete();
  }
}

/// Thrown when an [AiCancelToken] stops a request.
class AiCancelledException implements Exception {
  const AiCancelledException();

  @override
  String toString() => 'AiCancelledException';
}

/// The model behind the AI features (suite 10 §1), provider-agnostic:
/// `DartanticAiClient` in production, `FakeAiModelClient` in tests.
abstract class AiModelClient {
  /// The provider requests go to.
  AiProvider get provider;

  /// Streams one model turn of [request] and returns it complete,
  /// reporting text and thinking deltas as they arrive. Throws
  /// [AiCancelledException] when [cancel] fires and [AiApiException] when
  /// the request fails.
  Future<AiResponse> send(
    AiRequest request, {
    AiCancelToken? cancel,
    void Function(String delta)? onText,
    void Function(String delta)? onThinking,
  });
}
