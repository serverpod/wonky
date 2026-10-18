import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/generated/protocol.dart';
import 'package:wonky_server/src/write/ai/inline_ai_service.dart';

/// Inline AI input caps (CQ-31): client text is bounded before it reaches a
/// prompt.
void main() {
  InlineAiRequest request({String? context, String? instruction}) =>
      InlineAiRequest(
        itemUuid: const Uuid().v4obj(),
        action: 'improve',
        contextBefore: context,
        instruction: instruction,
      );

  group('Given an inline AI request', () {
    test('when every field is within the cap then it passes', () {
      expect(
        () => InlineAiService.checkInputSizes(
          request(context: 'a' * InlineAiService.maxFieldChars),
        ),
        returnsNormally,
      );
    });

    test('when a field is over the cap then it is refused as too large', () {
      expect(
        () => InlineAiService.checkInputSizes(
          request(instruction: 'a' * (InlineAiService.maxFieldChars + 1)),
        ),
        throwsA(
          isA<WonkyException>()
              .having((e) => e.code, 'code', WonkyErrorCode.tooLarge)
              .having((e) => e.message, 'message', contains('instruction')),
        ),
      );
    });
  });
}
