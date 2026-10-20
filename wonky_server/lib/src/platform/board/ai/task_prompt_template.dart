import '../../common/models.dart';

/// The fixed frame around a task prompt (specs/16 §10.1). The AI writes
/// only the body; the header and the "When you are done" part come from
/// here and cannot be changed by the model.
abstract final class TaskPromptTemplate {
  /// The placeholder of the claim line in prompts read by anyone but the
  /// claimant (admins).
  static const claimPlaceholder = '<your claim code from the task page>';

  /// The full prompt shown on the task page: header, [body], the posts the
  /// task comes from, and the PR instructions with the two description
  /// lines — filled in with [claimCode] for the claimant, else the
  /// [claimPlaceholder].
  static String wrap({
    required BoardTask task,
    required List<BoardPost> posts,
    required String body,
    required Uri webOrigin,
    String repository = 'serverpod/wonky',
    String? claimCode,
  }) {
    final b = StringBuffer()
      ..writeln('# Wonky task T-${task.id}: ${task.title}')
      ..writeln()
      ..writeln(
        'You are working in a clone of github.com/$repository. Read '
        'AGENTS.md first and follow it (specs are the source of truth, every '
        'action is a command and undoable, single window, light and dark, '
        'the checklist after changes).',
      )
      ..writeln()
      ..writeln(body.trim())
      ..writeln()
      ..writeln('## Reports this task comes from');
    for (final p in posts) {
      // The issue as Markdown (body, details, comments): an agent reads it
      // without the web app (specs/16 §10.1).
      final link = webOrigin.replace(path: '/improvements/p/${p.id}.md');
      b.writeln(
        '- #${p.id} ${p.title} — $link '
        '(${p.score} ${p.score == 1 ? 'vote' : 'votes'})',
      );
    }
    b
      ..writeln()
      ..writeln('## When you are done')
      ..writeln('- Run the checklist in AGENTS.md (analyze, format, tests).')
      ..writeln('- Update the specs if behavior changed.')
      ..writeln(
        '- $manualVerificationStep',
      )
      ..writeln()
      ..writeln(
        'Once the user has confirmed, open a pull request against `main`. '
        'Its description contains these two lines:',
      )
      ..writeln()
      ..writeln('```')
      ..writeln('Wonky-Task: T-${task.id}')
      ..writeln('Wonky-Claim: ${claimCode ?? claimPlaceholder}')
      ..writeln('```')
      ..writeln()
      ..writeln(
        'and a short summary of how each acceptance criterion is met.',
      );
    return b.toString();
  }

  /// The manual review before the pull request (specs/16 §10.1): part of the
  /// fixed frame, so every task gets it whatever the AI wrote.
  static const manualVerificationStep =
      'Before you open the pull request, stop and ask the user to verify the '
      'feature or the fixed bug by hand: tell them how to try it (which app '
      'to start, where to go, what to do and what they should see) and wait '
      'for their answer. If they find a problem, fix it, run the checklist '
      'again and ask again. Do not open the pull request until they confirm '
      'that it works.';

  /// The acceptance criterion of tasks that change the UI (T-16, specs/16
  /// §10.1). The review bot reads it back ([requiresScreenshot]) and checks
  /// the PR description for an image (§13.5).
  static const screenshotCriterion =
      'The pull request description includes a screenshot of the changed UI '
      '(light and dark where both change).';

  /// [body] with [screenshotCriterion] as the last item of its *Acceptance
  /// criteria* (a new section after *Goal*, or at the end, when it has
  /// none). Unchanged when it is there already.
  static String withScreenshotCriterion(String body) {
    if (requiresScreenshot(body)) return body;
    const item = '- [ ] $screenshotCriterion';
    final lines = body.replaceAll('\r\n', '\n').split('\n');
    final start = lines.indexWhere(
      (l) => _heading(l) == 'acceptance criteria',
    );
    if (start < 0) {
      final goal = lines.indexWhere((l) => _heading(l) == 'goal');
      var at = lines.length;
      if (goal >= 0) {
        final next = lines.indexWhere((l) => _heading(l) != null, goal + 1);
        at = next < 0 ? lines.length : next;
      }
      lines.insertAll(at, ['', '## Acceptance criteria', item, '']);
      return lines.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    }
    var end = lines.indexWhere((l) => _heading(l) != null, start + 1);
    if (end < 0) end = lines.length;
    // After the last non-empty line of the section.
    var at = end;
    while (at > start + 1 && lines[at - 1].trim().isEmpty) {
      at--;
    }
    lines.insert(at, item);
    return lines.join('\n');
  }

  /// Whether the acceptance criteria of [body] ask for a screenshot in the
  /// PR description: a checklist item naming a screenshot and the pull
  /// request description ([screenshotCriterion], or an admin's wording).
  static bool requiresScreenshot(String body) {
    for (final line in body.split('\n')) {
      final t = line.trim().toLowerCase();
      if (!RegExp(r'^[-*] \[[ x]\] ').hasMatch(t)) continue;
      if (t.contains('screenshot') &&
          (t.contains('pull request description') ||
              t.contains('pr description'))) {
        return true;
      }
    }
    return false;
  }

  /// The lower-case title of a level-2 heading, else null.
  static String? _heading(String line) {
    final t = line.trim();
    return t.startsWith('## ') ? t.substring(3).trim().toLowerCase() : null;
  }

  /// The body admins fill in when no AI is available.
  static const blankBody = '''
## Goal

## Acceptance criteria
- [ ] 

## Specs to read

## Likely code

## Out of scope

## Tests to add
''';
}
