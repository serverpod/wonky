import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/github/github_gate.dart';

void main() {
  group('Given a PR description', () {
    const cases = <(String, String, List<int>, List<String>)>[
      (
        'plain lines',
        'Wonky-Task: T-12\nWonky-Claim: 7Q4F-K2M9',
        [12],
        ['7Q4F-K2M9'],
      ),
      (
        'lowercase and extra whitespace',
        '  wonky-task :   t-12  \n wonky-claim:7q4f k2m9 ',
        [12],
        ['7Q4F-K2M9'],
      ),
      (
        'bold keys and code values',
        '**Wonky-Task:** `T-12`\n**Wonky-Claim:** `7Q4F-K2M9`',
        [12],
        ['7Q4F-K2M9'],
      ),
      (
        'list markers, quotes and a link',
        '- Wonky-Task: [T-12](https://wonky.work/improvements/t/12)\n'
            '> Wonky-Claim: __7Q4F-K2M9__',
        [12],
        ['7Q4F-K2M9'],
      ),
      (
        'a fenced code block as in CONTRIBUTING.md',
        '```\nWonky-Task: T-12\nWonky-Claim: 7Q4F-K2M9\n```',
        [12],
        ['7Q4F-K2M9'],
      ),
      (
        'CRLF line endings and no hyphen in the code',
        'Wonky-Task: T12\r\nWonky-Claim: 7Q4FK2M9\r\n',
        [12],
        ['7Q4F-K2M9'],
      ),
      (
        'the empty template lines',
        'Wonky-Task: T-\nWonky-Claim: ',
        [],
        [],
      ),
      (
        'lines inside the template comment only',
        '<!--\nWonky-Task: T-1\nWonky-Claim: AAAA-BBBB\n-->',
        [],
        [],
      ),
      (
        'the lines inside a sentence',
        'I did not add Wonky-Task: T-12 yet',
        [],
        [],
      ),
      (
        'two task lines',
        'Wonky-Task: T-12\nWonky-Task: T-13\nWonky-Claim: 7Q4F-K2M9',
        [12, 13],
        ['7Q4F-K2M9'],
      ),
    ];
    for (final (name, body, tasks, claims) in cases) {
      test('with $name when parsing then tasks are $tasks and claims '
          '$claims', () {
        final lines = GithubGate.parse(body);

        expect(lines.tasks, tasks);
        expect(lines.claims, claims);
      });
    }

    test('when a code uses O, I and L then they read as 0 and 1', () {
      expect(GithubGate.normalizeCode('o1il-abcd'), '0111-ABCD');
    });
  });
}
