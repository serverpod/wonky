// The prompt lint of specs/16 §10.2, shared by the prompt editor (a
// warning list) and the server, which holds a generated prompt that it
// flags for an admin's review instead of publishing the task (T-11).

/// What [lintTaskPrompt] found unusual in a line.
enum PromptLintKind {
  /// A shell command other than `flutter`, `dart`, `serverpod` or `git`.
  command,

  /// A URL outside the repository (`github.com/serverpod/wonky`) and
  /// `wonky.work`.
  url,

  /// "ignore", "secret", "token" or "credential" wording.
  wording,
}

/// One finding of [lintTaskPrompt]: [line] is 1-based, [match] the text
/// that triggered it.
class PromptLint {
  const PromptLint(this.kind, this.line, this.match);

  final PromptLintKind kind;
  final int line;
  final String match;

  @override
  String toString() => '${kind.name}@$line: $match';
}

const _allowedCommands = {'flutter', 'dart', 'serverpod', 'git', 'cd', 'fvm'};

/// Commands that are unusual in a task prompt even in inline code.
const _riskyCommands = {
  'curl', 'wget', 'rm', 'sudo', 'chmod', 'chown', 'bash', 'sh', 'zsh', //
  'python', 'python3', 'node', 'npm', 'npx', 'pip', 'pip3', 'brew', 'apt',
  'apt-get', 'docker', 'ssh', 'scp', 'eval', 'export', 'nc', 'netcat',
  'powershell', 'iex', 'kill', 'dd', 'mkfs', 'crontab', 'base64', 'env',
  'printenv', 'gh', 'source',
};

final _url = RegExp(r'''https?://[^\s<>)\]"'`]+''', caseSensitive: false);
final _words = RegExp(
  r'\b(ignore[sd]?|secrets?|tokens?|credentials?)\b',
  caseSensitive: false,
);
final _inlineCode = RegExp(r'`([^`\n]+)`');
final _shellLangs = {'', 'sh', 'bash', 'shell', 'console', 'zsh', 'terminal'};

bool _allowedUrl(String raw) {
  final u = Uri.tryParse(raw);
  if (u == null) return false;
  final host = u.host.toLowerCase();
  if (host == 'wonky.work' || host.endsWith('.wonky.work')) return true;
  if (host == 'localhost' || host == '127.0.0.1') return true;
  if (host == 'github.com' || host == 'www.github.com') {
    final p = u.path.toLowerCase();
    return p == '/serverpod/wonky' || p.startsWith('/serverpod/wonky/');
  }
  return false;
}

String? _commandOf(String line) {
  var t = line.trim();
  if (t.startsWith(r'$ ')) t = t.substring(2).trim();
  if (t.isEmpty || t.startsWith('#')) return null;
  final first = t.split(RegExp(r'\s+')).first;
  return RegExp(r'^[A-Za-z][\w.+-]*$').hasMatch(first) ? first : null;
}

/// The prompt lint of specs/16 §10.2: instructions that are unusual for a
/// task. A warning list for the admin, never a block.
List<PromptLint> lintTaskPrompt(String text) {
  final out = <PromptLint>[];
  final lines = text.split('\n');
  String? fence;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final n = i + 1;
    final trimmed = line.trimLeft();
    if (trimmed.startsWith('```')) {
      fence = fence == null ? trimmed.substring(3).trim().toLowerCase() : null;
      continue;
    }
    // Shell lines: inside a shell (or untyped) fence, or `$ cmd`.
    final inShell = fence != null && _shellLangs.contains(fence);
    if (inShell || trimmed.startsWith(r'$ ')) {
      final c = _commandOf(line);
      if (c != null && !_allowedCommands.contains(c.toLowerCase())) {
        out.add(PromptLint(PromptLintKind.command, n, line.trim()));
      }
    } else if (fence == null) {
      for (final m in _inlineCode.allMatches(line)) {
        final c = _commandOf(m[1]!);
        if (c != null && _riskyCommands.contains(c.toLowerCase())) {
          out.add(PromptLint(PromptLintKind.command, n, m[1]!.trim()));
        }
      }
    }
    if (RegExp(r'\|\s*(sudo\s+)?(ba|z)?sh\b').hasMatch(line) &&
        !out.any((x) => x.line == n && x.kind == PromptLintKind.command)) {
      out.add(PromptLint(PromptLintKind.command, n, line.trim()));
    }
    for (final m in _url.allMatches(line)) {
      final u = m[0]!.replaceFirst(RegExp(r'[.,;:]+$'), '');
      if (!_allowedUrl(u)) out.add(PromptLint(PromptLintKind.url, n, u));
    }
    for (final m in _words.allMatches(line)) {
      out.add(PromptLint(PromptLintKind.wording, n, m[0]!));
    }
  }
  return out;
}
