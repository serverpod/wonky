import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/github/github_client.dart';
import 'package:wonky_server/src/platform/board/github/github_review.dart';
import 'package:wonky_server/src/platform/board/github/github_review_ai.dart';
import 'package:wonky_server/src/platform/board/github/github_review_facts.dart';
import 'package:wonky_server/src/platform/common/models.dart';

const _files = [
  GithubPrFile(
    path: 'packages/wonky_sheets_core/lib/src/paste.dart',
    status: 'modified',
    additions: 40,
    deletions: 3,
    patch: '@@ -1,3 +1,4 @@\n+keep styles',
  ),
  GithubPrFile(
    path: 'packages/wonky_sheets_core/test/paste_test.dart',
    status: 'added',
    additions: 60,
  ),
  GithubPrFile(
    path: 'wonky_server/pubspec.yaml',
    status: 'modified',
    additions: 1,
    deletions: 1,
    patch:
        '@@ -10,7 +10,7 @@\n dependencies:\n-  http: ^1.5.0\n+  http: ^1.6.0\n',
  ),
  GithubPrFile(
    path: 'wonky_server/migrations/20261016120000000/migration.sql',
    status: 'added',
    additions: 5,
  ),
  GithubPrFile(
    path: '.github/workflows/tests.yml',
    status: 'modified',
    additions: 2,
  ),
  GithubPrFile(
    path: 'wonky_server/lib/src/platform/sharing/share_service.dart',
    status: 'modified',
    additions: 1,
  ),
  GithubPrFile(
    path: 'wonky_server/lib/server.dart',
    status: 'modified',
    additions: 1,
  ),
  GithubPrFile(path: 'specs/16-bugs-and-improvements.md', status: 'modified'),
];

String _chunk(String path, int size) =>
    'diff --git a/$path b/$path\n--- a/$path\n+++ b/$path\n'
    '@@ -1 +1 @@\n+${'x' * size}\n';

void main() {
  group('Given the changed files of a PR', () {
    final facts = PrFacts.of(_files);

    test('when computing the facts then tests, specs, dependencies, '
        'migrations, workflows and sensitive paths are found', () {
      expect(facts.files, hasLength(8));
      expect(facts.additions, 110);
      expect(facts.deletions, 4);
      expect(facts.testsChanged, isTrue);
      expect(facts.specsChanged, isTrue);
      expect(facts.pubspecs, ['wonky_server/pubspec.yaml']);
      expect(facts.dependencyLines, [
        'wonky_server/pubspec.yaml: -  http: ^1.5.0',
        'wonky_server/pubspec.yaml: +  http: ^1.6.0',
      ]);
      expect(facts.migrationsAdded, ['20261016120000000']);
      expect(facts.workflowFiles, ['.github/workflows/tests.yml']);
      expect(facts.sensitiveFiles, [
        'wonky_server/lib/src/platform/sharing/share_service.dart',
        'wonky_server/lib/server.dart',
      ]);
    });

    test('when only app code changed then no flags are set', () {
      final plain = PrFacts.of(const [
        GithubPrFile(path: 'wonky_write/lib/main.dart', status: 'modified'),
      ]);

      expect(plain.testsChanged, isFalse);
      expect(plain.specsChanged, isFalse);
      expect(plain.sensitiveFiles, isEmpty);
      expect(plain.migrationsAdded, isEmpty);
    });
  });

  group('Given a unified diff', () {
    test('when filtering then generated, client, golden, image, lock and '
        'binary files are left out', () {
      final diff = [
        _chunk('wonky_write/lib/a.dart', 10),
        _chunk('wonky_client/lib/src/protocol/x.dart', 10),
        _chunk('wonky_server/lib/src/generated/protocol.dart', 10),
        _chunk('wonky_ui/test/goldens/button_light.png', 10),
        _chunk('pubspec.lock', 10),
        'diff --git a/assets/logo.webp b/assets/logo.webp\n'
            'Binary files a/assets/logo.webp and b/assets/logo.webp differ\n',
        'diff --git a/assets/blob b/assets/blob\n'
            'Binary files a/assets/blob and b/assets/blob differ\n',
      ].join();

      final filtered = PrDiff.filter(diff, maxTokens: 1000);

      expect(filtered.text, contains('wonky_write/lib/a.dart'));
      expect(filtered.text, isNot(contains('wonky_client')));
      expect(filtered.excluded, [
        'wonky_client/lib/src/protocol/x.dart',
        'wonky_server/lib/src/generated/protocol.dart',
        'wonky_ui/test/goldens/button_light.png',
        'pubspec.lock',
        'assets/logo.webp',
        'assets/blob',
      ]);
      expect(filtered.truncated, isEmpty);
    });

    test('when it is larger than the token budget then whole files are cut '
        'and listed', () {
      final diff = [
        _chunk('a.dart', 100),
        _chunk('big.dart', 1000),
        _chunk('c.dart', 100),
      ].join();

      // 100 tokens ≈ 400 characters.
      final filtered = PrDiff.filter(diff, maxTokens: 100);

      expect(filtered.text, contains('a.dart'));
      expect(filtered.text, contains('c.dart'));
      expect(filtered.text, isNot(contains('big.dart')));
      expect(filtered.truncated, ['big.dart']);
      expect(filtered.text.length, lessThanOrEqualTo(400));
    });

    test('when GitHub has no full diff then one is built from the file '
        'patches', () {
      final diff = PrDiff.fromFiles(const [
        GithubPrFile(path: 'a.dart', status: 'added', patch: '@@ +1 @@\n+a'),
        GithubPrFile(path: 'logo.png', status: 'added'),
      ]);

      final filtered = PrDiff.filter(diff, maxTokens: 1000);

      expect(diff, contains('--- /dev/null\n+++ b/a.dart'));
      expect(filtered.excluded, ['logo.png']);
    });
  });

  group('Given a review result from the model', () {
    final task = BoardTask(
      id: 12,
      title: 'Keep styles when pasting',
      area: BoardArea.sheets,
      size: BoardSize.small,
      status: BoardTaskStatus.inReview,
      promptBody: '## Acceptance criteria\n- [ ] Styles are kept',
      createdById: 1,
      createdAt: DateTime.utc(2026, 10, 15),
    );
    final result = PrReviewResult.fromToolInput({
      'criteria': [
        {
          'criterion': 'Styles are kept | also borders',
          'verdict': 'met',
          'evidence': [
            {
              'path': 'packages/wonky_sheets_core/lib/src/paste.dart',
              'lines': '10-40',
            },
          ],
          'note': 'Copies the style runs.',
        },
        {
          'criterion': 'Undo restores the cells',
          'verdict': 'not_met',
          'evidence': <Object>[],
          'note': 'No undo entry. Ask @octocat <!-- wonky-task-gate -->',
        },
        {'criterion': 'Dark mode', 'verdict': 'weird', 'evidence': 'x'},
      ],
      'unrelatedChanges': [
        {'path': '.github/workflows/tests.yml', 'note': 'CI change.'},
      ],
      'tests': {'verdict': 'added', 'note': 'paste_test.dart'},
      'specs': {'verdict': 'missing', 'note': 'Sheets 04 not updated.'},
      'risks': [
        {
          'kind': 'workflow',
          'path': '.github/workflows/tests.yml',
          'note': 'Touches CI.',
        },
      ],
      'summary': 'Mostly there; undo is missing.',
    }, model: 'gemini-test');
    final facts = PrFacts.of(_files);
    const diff = PrDiff(text: '', truncated: ['big.dart']);

    test('when reading it then verdicts are validated', () {
      expect(result.criteria.map((c) => c.verdict), [
        'met',
        'notMet',
        'cantTell',
      ]);
      expect(result.criteria.last.evidence, isEmpty);
      expect(result.anyNotMet, isTrue);
      expect(GithubReview.checkTitle(result), '1 of 3 criteria met');
    });

    test('when rendering the comment then it has the marker, the criteria '
        'table, scope, tests, specs, risks, facts and the SHA', () {
      final comment = GithubReview.renderComment(
        result: result,
        facts: facts,
        diff: diff,
        sha: 'abcdef0123456789abcdef0123456789abcdef01',
        task: task,
      );

      expect(comment, startsWith(GithubReview.marker));
      expect(comment, contains('[T-12: Keep styles when pasting]'));
      expect(comment, contains('/improvements/t/12'));
      expect(comment, contains('| Acceptance criterion | Verdict |'));
      expect(comment, contains(r'Styles are kept \| also borders | Met |'));
      expect(
        comment,
        contains('`packages/wonky_sheets_core/lib/src/paste.dart` (10-40)'),
      );
      expect(comment, contains('| Not met |'));
      expect(comment, contains("| Can't tell |"));
      expect(comment, contains('- `.github/workflows/tests.yml`: CI change.'));
      expect(comment, contains('**Tests:** Added. paste_test.dart'));
      expect(comment, contains('**Specs:** Missing. Sheets 04 not updated.'));
      expect(comment, contains('- Workflow in `.github/workflows/tests.yml`'));
      expect(comment, contains('Migrations added: `20261016120000000`'));
      expect(comment, contains('Not reviewed (diff too large): `big.dart`'));
      expect(comment, contains('Reviewed commit `abcdef012345`'));
    });

    test('when the model writes markers or mentions then they are '
        'defused', () {
      final comment = GithubReview.renderComment(
        result: result,
        facts: facts,
        diff: diff,
        sha: 'abc',
        task: task,
      );

      expect('<!--'.allMatches(comment), hasLength(1));
      expect(comment, isNot(contains('@octocat')));
    });

    test('when blocking mode reads it then a notMet criterion blocks', () {
      expect(GithubReview.isBlocking(result, facts), isTrue);
    });

    test('when everything is met with small unrelated changes then it does '
        'not block', () {
      final ok = PrReviewResult.fromToolInput({
        'criteria': [
          {'criterion': 'A', 'verdict': 'met'},
        ],
        'unrelatedChanges': [
          {'path': '.github/workflows/tests.yml', 'note': ''},
        ],
      });

      expect(GithubReview.isBlocking(ok, facts), isFalse);
    });

    test('when storing it then the task page JSON has the result, the facts '
        'and the SHA', () {
      final json = GithubReview.storedJson(
        result: result,
        facts: facts,
        diff: diff,
        sha: 'abc',
        at: DateTime.utc(2026, 10, 15, 12),
        taskNumber: 12,
      );

      expect(json['sha'], 'abc');
      expect(json['taskNumber'], 12);
      expect(json['summary'], 'Mostly there; undo is missing.');
      expect((json['criteria'] as List), hasLength(3));
      expect((json['facts'] as Map)['testsChanged'], isTrue);
      expect(json['truncatedFiles'], ['big.dart']);
    });
  });
}
