import 'dart:convert';

import 'llm/ai_client.dart';

/// The stored form of assistant turns (`AssistantMessage.contentJson`).
///
/// Turns are stored as `dartantic_ai` messages (`ChatMessage.toJson()`: a
/// JSON object with `role`, `parts`, `metadata`), so a thread replays with
/// any provider. Threads from before the provider switch hold raw Anthropic
/// content blocks (a JSON array); [decode] converts their text, tool calls
/// and tool results and drops thinking blocks.
abstract final class AssistantHistory {
  static String encode(ChatMessage message) => jsonEncode(message.toJson());

  /// The message of a stored row (null = nothing to replay). [toolNames]
  /// carries tool names from calls to the results of later rows (legacy
  /// results only have the call id).
  static ChatMessage? decode(
    String role,
    String? contentJson,
    Map<String, String> toolNames,
  ) {
    Object? json;
    try {
      json = jsonDecode(contentJson ?? '[]');
    } on FormatException {
      return null;
    }
    if (json is Map) {
      final m = ChatMessage.fromJson(json.cast<String, Object?>());
      for (final c in m.toolCalls) {
        toolNames[c.callId] = c.toolName;
      }
      return m.parts.isEmpty ? null : m;
    }
    if (json is! List || json.isEmpty) return null;
    final parts = <StandardPart>[];
    for (final b in json) {
      if (b is! Map) continue;
      switch (b['type']) {
        case 'text':
          final t = '${b['text'] ?? ''}';
          if (t.isNotEmpty) parts.add(TextPart(t));
        case 'tool_use':
          final id = '${b['id']}';
          final name = '${b['name']}';
          toolNames[id] = name;
          final input = b['input'];
          parts.add(
            ToolPart.call(
              callId: id,
              toolName: name,
              arguments: input is Map ? input.cast<String, Object?>() : {},
            ),
          );
        case 'tool_result':
          final id = '${b['tool_use_id']}';
          final content = b['content'];
          parts.add(
            ToolPart.result(
              callId: id,
              toolName: toolNames[id] ?? 'tool',
              result: content is String ? content : jsonEncode(content),
            ),
          );
      }
    }
    if (parts.isEmpty) return null;
    return ChatMessage(
      role: role == 'assistant' ? ChatMessageRole.model : ChatMessageRole.user,
      parts: parts,
    );
  }

  /// Tool results above this many characters are elided in exchanges older
  /// than the last [keepRecentExchanges].
  static const elideAbove = 400;

  /// Exchanges (a user's message and everything up to the next one) whose
  /// tool results are always sent in full: the current one and the one
  /// before.
  static const keepRecentExchanges = 2;

  /// A rough token estimate of [message] (4 characters per token).
  static int estimateTokens(ChatMessage message) =>
      (encode(message).length / 4).ceil();

  /// The messages to send for a thread (CQ-31): tool results of older
  /// exchanges are elided (a note says how to get them again), and when
  /// the estimate is still above [budgetTokens] whole exchanges are left
  /// out, oldest first — never the first one (it holds the document
  /// snapshot) or the last one (the current question). Tool calls stay
  /// with their results, so the history remains valid for every provider.
  static List<ChatMessage> fit(
    List<ChatMessage> messages, {
    required int budgetTokens,
  }) {
    final starts = <int>[
      for (var i = 0; i < messages.length; i++)
        if (_startsExchange(messages[i])) i,
    ];
    if (starts.isEmpty || starts.first != 0) starts.insert(0, 0);
    final exchanges = <List<ChatMessage>>[
      for (var e = 0; e < starts.length; e++)
        messages.sublist(
          starts[e],
          e + 1 < starts.length ? starts[e + 1] : messages.length,
        ),
    ];
    final firstRecent = exchanges.length - keepRecentExchanges;
    for (var e = 0; e < firstRecent; e++) {
      exchanges[e] = [for (final m in exchanges[e]) _elide(m)];
    }
    int tokens(List<ChatMessage> ms) =>
        ms.fold(0, (s, m) => s + estimateTokens(m));
    var total = exchanges.fold(0, (s, x) => s + tokens(x));
    // Drop the oldest middle exchanges until the history fits.
    while (total > budgetTokens && exchanges.length > 2) {
      total -= tokens(exchanges.removeAt(1));
    }
    return [for (final x in exchanges) ...x];
  }

  /// Whether [m] is a user's own message (not a tool result turn).
  static bool _startsExchange(ChatMessage m) =>
      m.role == ChatMessageRole.user && m.toolResults.isEmpty;

  static ChatMessage _elide(ChatMessage m) {
    if (m.toolResults.isEmpty) return m;
    var changed = false;
    final parts = <StandardPart>[
      for (final p in m.parts)
        if (p is ToolPart && p.kind == ToolPartKind.result)
          () {
            final text = p.result is String
                ? p.result! as String
                : jsonEncode(p.result);
            if (text.length <= elideAbove) return p;
            changed = true;
            return ToolPart.result(
              callId: p.callId,
              toolName: p.toolName,
              result:
                  '[Earlier result of ${p.toolName} left out '
                  '(${text.length} characters). Call the tool again if you '
                  'need it.]',
            );
          }()
        else
          p,
    ];
    return changed ? m.copyWith(parts: parts) : m;
  }
}
