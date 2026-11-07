/// Checks the dialog close-button rule of `specs/02-design-system.md` §4.20:
/// a dialog shows the X in its top-right corner only when it has no other
/// way to be dismissed (Cancel, Close, Done, Got it, …).
///
/// Usage (from the repository root; no `pub get` needed):
///
/// ```sh
/// dart run tool/check_dialogs.dart
/// ```
///
/// Every `ShadDialog(…)`, `ShadDialog.alert(…)` and torn-off constructor
/// call (`(alert ? ShadDialog.alert : ShadDialog.new)(…)`) in the `lib/`
/// folders of the apps and packages must pass `closeIcon:`, and its value
/// must be a `WonkyDialogCloseButton(…)` (it hides itself when the dialog
/// has `actions`) or `SizedBox.shrink()` (no X). Without `closeIcon:` shad's
/// theme draws its own X on every dialog, buttons or not.
///
/// A `ShadDialog` without `actions:` whose own arguments build a Cancel,
/// Close, Done, OK or Got it button is reported too: those buttons belong
/// in `actions`, where the close button sees them.
library;

import 'dart:io';

const _roots = [
  'packages',
  'wonky_write/lib',
  'wonky_sheets/lib',
  'wonky_slides/lib',
  'wonky_drive/lib',
];

final _direct = RegExp(r'\bShadDialog(\.alert|\.raw)?\(');
final _tearOff = RegExp(r'\bShadDialog\.(new|alert)\b(?!\s*\()');
final _dismissLabel = RegExp(
  r'\.(action|common)(Cancel|Close|Done|Ok|GotIt)\b|\bgotIt\b',
);
final _closeIcon = RegExp(r'closeIcon:\s*(const\s+)?([A-Za-z_][\w.]*)');

void main(List<String> args) {
  if (args.contains('--help')) {
    stdout.writeln('Usage: dart run tool/check_dialogs.dart');
    return;
  }
  final problems = <String>[];
  for (final root in _roots) {
    final dir = Directory(root);
    if (!dir.existsSync()) continue;
    for (final f in dir.listSync(recursive: true).whereType<File>()) {
      final p = f.path;
      if (!p.endsWith('.dart') ||
          p.contains('/test/') ||
          p.contains('/.dart_tool/') ||
          p.contains('/l10n/') ||
          p.endsWith('.g.dart') ||
          p.startsWith('packages/') && !p.contains('/lib/')) {
        continue;
      }
      problems.addAll(_check(p, f.readAsStringSync()));
    }
  }
  if (problems.isEmpty) {
    stdout.writeln('Dialog close buttons OK.');
    return;
  }
  stderr
    ..writeln('Dialog close-button rule (specs/02-design-system.md §4.20):')
    ..writeAll(problems.map((p) => '  $p\n'));
  exitCode = 1;
}

Iterable<String> _check(String path, String source) sync* {
  final code = _blankComments(source);
  for (final (start, args) in _calls(code)) {
    final line = '\n'.allMatches(code.substring(0, start)).length + 1;
    final where = '$path:$line';
    final close = _closeIcon.firstMatch(args);
    if (close == null) {
      yield '$where: ShadDialog without closeIcon (shad draws its own X); '
          'pass `closeIcon: const WonkyDialogCloseButton()`.';
      continue;
    }
    final value = close.group(2)!;
    if (value != 'WonkyDialogCloseButton' && value != 'SizedBox.shrink') {
      yield '$where: closeIcon is `$value`; use WonkyDialogCloseButton '
          '(hidden when the dialog has actions) or SizedBox.shrink().';
    }
    if (!args.contains('actions:') && _dismissLabel.hasMatch(args)) {
      yield '$where: dismiss button outside `actions`; put Cancel/Close/'
          'Done in `actions` so the dialog has no X.';
    }
  }
}

/// The argument lists (with their offset) of every ShadDialog construction.
Iterable<(int, String)> _calls(String code) sync* {
  for (final m in _direct.allMatches(code)) {
    final end = _matching(code, m.end - 1);
    if (end != null) yield (m.start, code.substring(m.end, end));
  }
  for (final m in _tearOff.allMatches(code)) {
    // `(cond ? ShadDialog.alert : ShadDialog.new)(args)`: the group that
    // holds the tear-off, then the call right after it. Both constructors of
    // one group are one call.
    final open = code.lastIndexOf('(', m.start);
    if (open < 0) continue;
    final close = _matching(code, open);
    if (close == null || close < m.end) continue;
    if (m.start != code.indexOf(_tearOff, open)) continue;
    var i = close + 1;
    while (i < code.length && code[i].trim().isEmpty) {
      i++;
    }
    if (i >= code.length || code[i] != '(') continue;
    final end = _matching(code, i);
    if (end != null) yield (m.start, code.substring(i + 1, end));
  }
}

/// The index of the bracket closing the one at [open] (strings skipped).
int? _matching(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    final c = s[i];
    if (c == "'" || c == '"') {
      final triple = s.startsWith(c * 3, i);
      final quote = triple ? c * 3 : c;
      i += quote.length;
      while (i < s.length && !s.startsWith(quote, i)) {
        if (s[i] == r'\') i++;
        i++;
      }
      i += quote.length - 1;
      continue;
    }
    if (c == '(' || c == '[' || c == '{') depth++;
    if (c == ')' || c == ']' || c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return null;
}

/// [s] with `//` and `/* */` comments replaced by spaces (offsets kept).
String _blankComments(String s) {
  final b = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == "'" || c == '"') {
      final triple = s.startsWith(c * 3, i);
      final quote = triple ? c * 3 : c;
      var j = i + quote.length;
      while (j < s.length && !s.startsWith(quote, j)) {
        if (s[j] == r'\') j++;
        j++;
      }
      j = (j + quote.length).clamp(0, s.length);
      b.write(s.substring(i, j));
      i = j;
    } else if (s.startsWith('//', i)) {
      final end = s.indexOf('\n', i);
      final j = end < 0 ? s.length : end;
      b.write(' ' * (j - i));
      i = j;
    } else if (s.startsWith('/*', i)) {
      final end = s.indexOf('*/', i + 2);
      final j = end < 0 ? s.length : end + 2;
      b.write(s.substring(i, j).replaceAll(RegExp(r'[^\n]'), ' '));
      i = j;
    } else {
      b.write(c);
      i++;
    }
  }
  return b.toString();
}
