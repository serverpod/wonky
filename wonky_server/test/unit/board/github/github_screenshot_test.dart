import 'package:test/test.dart';
import 'package:wonky_server/src/platform/board/ai/task_prompt_template.dart';
import 'package:wonky_server/src/platform/board/github/github_screenshot.dart';

/// The screenshot check of the review (T-16, specs/16 §13.5): only image
/// markers in the PR description are read.
void main() {
  group('Given a PR description', () {
    for (final (name, body) in [
      ('a Markdown image', 'Done.\n\n![after](https://github.com/u/a.png)'),
      (
        'a Markdown image with a title',
        '![dark mode](<https://x.example/a b.png> "Dark")',
      ),
      ('a reference image', '![after][1]\n\n[1]: https://x.example/a.png'),
      (
        "GitHub's pasted <img>",
        '<img width="800" alt="UI" src="https://github.com/user-attachments/'
            'assets/1b2c" />',
      ),
      ('an <IMG> in upper case', "<IMG SRC='https://x.example/a.png'>"),
    ]) {
      test('with $name then it has an image', () {
        expect(PrScreenshot.hasImage(body), isTrue);
      });
    }

    for (final (name, body) in [
      ('only text', 'Keeps styles.\n\nWonky-Task: T-12'),
      ('a plain link', '[after](https://x.example/a.png)'),
      ('an image in a fenced code block', '```md\n![a](https://x/a.png)\n```'),
      ('an image in a ~~~ block', '~~~\n<img src="https://x/a.png">\n~~~'),
      ('an image in inline code', 'Use `![a](https://x/a.png)` here.'),
      (
        'an image in an HTML comment (the template hint)',
        '<!-- Add a screenshot: ![a](https://x/a.png) -->',
      ),
      ('an <img> without src', '<img alt="nothing">'),
      ('an empty image', '![]()'),
    ]) {
      test('with $name then it has no image', () {
        expect(PrScreenshot.hasImage(body), isFalse);
      });
    }
  });

  group('Given a task prompt body', () {
    const body =
        '## Goal\nFix it.\n\n## Acceptance criteria\n- [ ] Styles are kept.\n'
        '- [ ] Undo restores them.\n\n## Specs to read\n- specs/x.md\n';

    test('when the screenshot criterion is added then it is the last item '
        'of the acceptance criteria and is read back', () {
      final out = TaskPromptTemplate.withScreenshotCriterion(body);

      expect(
        out,
        contains(
          '- [ ] Undo restores them.\n'
          '- [ ] ${TaskPromptTemplate.screenshotCriterion}\n\n'
          '## Specs to read',
        ),
      );
      expect(TaskPromptTemplate.requiresScreenshot(out), isTrue);
      expect(TaskPromptTemplate.requiresScreenshot(body), isFalse);
      // Adding it twice keeps one.
      expect(TaskPromptTemplate.withScreenshotCriterion(out), out);
    });

    test('when it has no acceptance criteria then the section is added '
        'after the goal', () {
      final out = TaskPromptTemplate.withScreenshotCriterion(
        '## Goal\nFix it.\n\n## Specs to read\n- specs/x.md',
      );

      expect(
        out,
        '## Goal\nFix it.\n\n## Acceptance criteria\n'
        '- [ ] ${TaskPromptTemplate.screenshotCriterion}\n\n'
        '## Specs to read\n- specs/x.md',
      );
    });

    test("when an admin wrote their own screenshot item then it counts, but "
        'prose mentioning screenshots does not', () {
      expect(
        TaskPromptTemplate.requiresScreenshot(
          '- [ ] Put a screenshot in the PR description.',
        ),
        isTrue,
      );
      expect(
        TaskPromptTemplate.requiresScreenshot(
          'The post has a screenshot; see the PR description template.',
        ),
        isFalse,
      );
    });

    test('when the state is computed then it combines the task and the '
        'description', () {
      final ui = TaskPromptTemplate.withScreenshotCriterion(body);

      expect(PrScreenshot.of(body, 'text'), PrScreenshot.notRequired);
      expect(PrScreenshot.of(ui, 'text'), PrScreenshot.missing);
      expect(PrScreenshot.of(ui, null), PrScreenshot.missing);
      expect(
        PrScreenshot.of(ui, '![a](https://x/a.png)'),
        PrScreenshot.present,
      );
      expect(PrScreenshot.parse('missing'), PrScreenshot.missing);
      expect(PrScreenshot.parse('other'), isNull);
    });
  });
}
