import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/task_prompt_template.dart';

import '../../../support/board/board_ai_builders.dart';

void main() {
  group('Given the task prompt template (specs/16 §10.1)', () {
    String wrap({String? claimCode}) => TaskPromptTemplate.wrap(
      task: BoardAiBuilders.task(),
      posts: [BoardAiBuilders.post(id: 412)],
      body: '## Goal\nKeep styles.',
      webOrigin: Uri.parse('https://wonky.work'),
      claimCode: claimCode,
    );

    test('when wrapped for the claimant then the PR lines carry their claim '
        'code in a code block', () {
      final prompt = wrap(claimCode: '7Q4F-K2M9');

      expect(prompt, startsWith('# Wonky task T-12: Keep styles'));
      expect(prompt, contains('## Goal\nKeep styles.'));
      expect(prompt, contains('https://wonky.work/improvements/p/412'));
      expect(
        prompt,
        endsWith(
          '## When you are done\n'
          '- Run the checklist in AGENTS.md (analyze, format, tests).\n'
          '- Update the specs if behavior changed.\n'
          '\n'
          'Open a pull request against `main`. Its description contains '
          'these two lines:\n'
          '\n'
          '```\n'
          'Wonky-Task: T-12\n'
          'Wonky-Claim: 7Q4F-K2M9\n'
          '```\n'
          '\n'
          'and a short summary of how each acceptance criterion is met.\n',
        ),
      );
      expect(prompt, isNot(contains(TaskPromptTemplate.claimPlaceholder)));
    });

    test('when wrapped without a claim code (admins) then the placeholder '
        'stands in its place', () {
      final prompt = wrap();

      expect(
        prompt,
        contains(
          '```\nWonky-Task: T-12\n'
          'Wonky-Claim: <your claim code from the task page>\n```',
        ),
      );
    });
  });
}
