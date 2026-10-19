import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/assistant_history.dart';
import 'package:wonky_server/src/platform/ai/llm/ai_client.dart';

ChatMessage _user(String text) =>
    ChatMessage(role: ChatMessageRole.user, parts: [TextPart(text)]);

ChatMessage _call(String id) => ChatMessage(
  role: ChatMessageRole.model,
  parts: [ToolPart.call(callId: id, toolName: 'read', arguments: const {})],
);

ChatMessage _result(String id, String text) => ChatMessage(
  role: ChatMessageRole.user,
  parts: [ToolPart.result(callId: id, toolName: 'read', result: text)],
);

ChatMessage _answer(String text) =>
    ChatMessage(role: ChatMessageRole.model, parts: [TextPart(text)]);

/// `AssistantHistory.fit` (CQ-31): the history sent per request is bounded.
void main() {
  final big = 'x' * 2000;
  List<ChatMessage> thread(int exchanges) => [
    for (var i = 0; i < exchanges; i++) ...[
      _user('question $i'),
      _call('c$i'),
      _result('c$i', big),
      _answer('answer $i'),
    ],
  ];
  String? resultOf(ChatMessage m) =>
      m.toolResults.isEmpty ? null : m.toolResults.single.result as String?;

  group('Given a thread of four exchanges with large tool results', () {
    test('when it fits the budget then only results of the older exchanges '
        'are elided', () {
      final fitted = AssistantHistory.fit(thread(4), budgetTokens: 1 << 30);

      final results = [
        for (final m in fitted)
          if (resultOf(m) != null) resultOf(m)!,
      ];
      expect(fitted, hasLength(16));
      expect(results.take(2), everyElement(startsWith('[Earlier result')));
      expect(results.skip(2), everyElement(big));
    });

    test('when it is over the budget then the oldest middle exchanges are '
        'left out, keeping the first and the last', () {
      final fitted = AssistantHistory.fit(thread(4), budgetTokens: 1200);

      final questions = [
        for (final m in fitted)
          if (m.role == ChatMessageRole.user && m.toolResults.isEmpty)
            (m.parts.single as TextPart).text,
      ];
      expect(questions.first, 'question 0');
      expect(questions.last, 'question 3');
      expect(questions.length, lessThan(4));
      // Every call keeps its result.
      final calls = {
        for (final m in fitted) ...m.toolCalls.map((c) => c.callId),
      };
      final results = {
        for (final m in fitted) ...m.toolResults.map((r) => r.callId),
      };
      expect(results, calls);
    });

    test('when the result is short then it is kept as is', () {
      final fitted = AssistantHistory.fit([
        _user('q0'),
        _call('c0'),
        _result('c0', 'small'),
        _user('q1'),
        _user('q2'),
      ], budgetTokens: 1 << 30);

      expect(resultOf(fitted[2]), 'small');
    });
  });
}
