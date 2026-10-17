import '../ai/task_prompt_template.dart';

/// Whether a pull request shows the screenshot its task asks for (T-16,
/// specs/16 §13.5).
enum PrScreenshot {
  /// The task's acceptance criteria don't ask for one.
  notRequired,

  /// Asked for, and the PR description has an image.
  present,

  /// Asked for, and the PR description has no image: the review check
  /// fails.
  missing;

  /// The state for a task prompt body [taskPrompt] and a PR [prBody].
  static PrScreenshot of(String taskPrompt, String? prBody) =>
      !TaskPromptTemplate.requiresScreenshot(taskPrompt)
      ? notRequired
      : hasImage(prBody ?? '')
      ? present
      : missing;

  /// The stored name of [state] in the review JSON, read back by [parse].
  static PrScreenshot? parse(Object? name) =>
      values.where((v) => v.name == name).firstOrNull;

  /// Whether [markdown] has an image: Markdown `![alt](url)` (also a
  /// reference `![alt][ref]`) or an HTML `<img src=…>` — what GitHub writes
  /// for a pasted or dropped screenshot. Code blocks, inline code and HTML
  /// comments (the PR template's hints) don't count. Only the markers are
  /// read; images are never downloaded or analyzed.
  static bool hasImage(String markdown) {
    final text = markdown
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
        .replaceAll(
          RegExp(r'^ {0,3}(```|~~~)[\s\S]*?^ {0,3}\1', multiLine: true),
          '',
        )
        .replaceAll(RegExp(r'`[^`\n]*`'), '');
    return _markdownImage.hasMatch(text) || _htmlImage.hasMatch(text);
  }

  static final _markdownImage = RegExp(
    r'!\[[^\]\n]*\](\(\s*<?[^\s)>]+|\[[^\]\n]+\])',
  );
  static final _htmlImage = RegExp(
    r'''<img\b[^>]*\bsrc\s*=\s*["']?[^\s"'>]+''',
    caseSensitive: false,
  );
}
