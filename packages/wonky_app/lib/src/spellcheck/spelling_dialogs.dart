import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;

import '../core/l10n_or_english.dart';
import '../shell/form_dialog.dart';

/// The stable widget keys of the spelling dialogs of one app (specs/15
/// §7): `<app>.dialog.spelling…` and `<app>.dialog.dictionary…`.
@immutable
final class SpellingKeySet {
  const SpellingKeySet(this.app);

  /// The key prefix (`write`, `slides`).
  final String app;

  ValueKey<String> get dialog => ValueKey<String>('$app.dialog.spelling');
  ValueKey<String> get word => ValueKey<String>('$app.dialog.spelling.word');
  ValueKey<String> get change =>
      ValueKey<String>('$app.dialog.spelling.change');
  ValueKey<String> get changeAll =>
      ValueKey<String>('$app.dialog.spelling.changeAll');
  ValueKey<String> get ignore =>
      ValueKey<String>('$app.dialog.spelling.ignore');
  ValueKey<String> get ignoreAll =>
      ValueKey<String>('$app.dialog.spelling.ignoreAll');
  ValueKey<String> get add => ValueKey<String>('$app.dialog.spelling.add');
  ValueKey<String> get done => ValueKey<String>('$app.dialog.spelling.done');
  ValueKey<String> get dictionary => ValueKey<String>('$app.dialog.dictionary');

  ValueKey<String> suggestion(int i) =>
      ValueKey<String>('$app.dialog.spelling.suggestion.$i');

  ValueKey<String> remove(String word) =>
      ValueKey<String>('$app.dialog.dictionary.remove.$word');

  @override
  bool operator ==(Object other) => other is SpellingKeySet && other.app == app;

  @override
  int get hashCode => app.hashCode;
}

/// Stable keys (specs/15 §7): Write's (`write.dialog.spelling…`, the
/// default of the dialogs) and Slides' ([slides]).
abstract final class SpellingKeys {
  /// Write's keys (the dialogs' default).
  static const write = SpellingKeySet('write');

  /// Slides' keys (`slides.dialog.spelling…`).
  static const slides = SpellingKeySet('slides');

  static const dialog = ValueKey<String>('write.dialog.spelling');
  static const word = ValueKey<String>('write.dialog.spelling.word');
  static const change = ValueKey<String>('write.dialog.spelling.change');
  static const changeAll = ValueKey<String>('write.dialog.spelling.changeAll');
  static const ignore = ValueKey<String>('write.dialog.spelling.ignore');
  static const ignoreAll = ValueKey<String>('write.dialog.spelling.ignoreAll');
  static const add = ValueKey<String>('write.dialog.spelling.add');
  static const done = ValueKey<String>('write.dialog.spelling.done');
  static const dictionary = ValueKey<String>('write.dialog.dictionary');

  static ValueKey<String> suggestion(int i) => write.suggestion(i);

  static ValueKey<String> remove(String word) => write.remove(word);
}

/// A flagged word in an editor's text, with UTF-16 offsets `[start, end)`.
@immutable
class SpellingIssue {
  const SpellingIssue(this.word, this.start, this.end);

  final String word;
  final int start;
  final int end;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is SpellingIssue &&
      other.word == word &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(word, start, end);

  @override
  String toString() => 'SpellingIssue($word, $start..$end)';
}

/// What the Check spelling dialog needs from an editor (Write 05 §12,
/// Slides 03 §14): the flagged words and the edits it makes. Each app
/// implements it over its own checker and commands, so every change is a
/// command and one undo step.
abstract class SpellingSession {
  /// The flagged words in document order.
  List<SpellingIssue> get issues;

  /// Whether a dictionary is loaded (otherwise the dialog says spellcheck
  /// isn't available for the language).
  bool get isAvailable;

  /// Where the walk starts (the caret).
  int get startOffset;

  /// Up to five suggestions for [word], best first.
  List<String> suggestionsFor(String word);

  /// Selects [issue] in the editor (scrolls it into view).
  void select(SpellingIssue issue);

  /// Replaces [issue] with [replacement] ("Change", one undo step).
  void change(SpellingIssue issue, String replacement);

  /// Replaces every flagged [word] with [replacement] ("Change all", one
  /// undo step).
  void changeAll(String word, String replacement);

  /// Stops flagging [word] for the session ("Ignore all").
  void ignoreAll(String word);

  /// Adds [word] to the user's personal dictionary.
  Future<void> addToDictionary(String word);

  /// Re-checks the text now (after a change).
  void recheck();
}

/// Tools › Spelling › Check spelling… (Write 05 §12): walks the flagged
/// words from the caret with Change, Change all, Ignore, Ignore all and Add
/// to dictionary.
/// [keys] names the app's widget keys (Write's by default).
Future<void> showSpellingDialog(
  BuildContext context, {
  required SpellingSession session,
  SpellingKeySet keys = SpellingKeys.write,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => SpellingDialog(session: session, keys: keys),
);

class SpellingDialog extends StatefulWidget {
  const SpellingDialog({
    super.key,
    required this.session,
    this.keys = SpellingKeys.write,
  });

  final SpellingSession session;

  /// The app's widget keys.
  final SpellingKeySet keys;

  @override
  State<SpellingDialog> createState() => _SpellingDialogState();
}

class _SpellingDialogState extends State<SpellingDialog>
    with McpDialogRegistration<SpellingDialog> {
  SpellingIssue? _current;
  List<String> _suggestions = const [];
  int _chosen = 0;
  int _from = 0;
  final _skipped = <(String, int)>{};

  @override
  void initState() {
    super.initState();
    _from = widget.session.startOffset;
    _next();
  }

  /// Moves to the next flagged word at or after [_from] (wrapping once).
  void _next() {
    final errors = widget.session.issues
        .where((e) => !_skipped.contains((e.word, e.start)))
        .toList();
    SpellingIssue? found;
    for (final e in errors) {
      if (e.start >= _from) {
        found = e;
        break;
      }
    }
    found ??= errors.isEmpty ? null : errors.first;
    setState(() {
      _current = found;
      _chosen = 0;
      _suggestions = found == null
          ? const []
          : widget.session.suggestionsFor(found.word);
    });
    if (found != null) widget.session.select(found);
  }

  String? get _replacement =>
      _suggestions.isEmpty ? null : _suggestions[_chosen];

  void _change() {
    final e = _current;
    final r = _replacement;
    if (e == null || r == null) return;
    widget.session.change(e, r);
    _from = e.start + r.length;
    widget.session.recheck();
    _next();
  }

  void _changeAll() {
    final e = _current;
    final r = _replacement;
    if (e == null || r == null) return;
    widget.session.changeAll(e.word, r);
    widget.session.recheck();
    _next();
  }

  void _ignore() {
    final e = _current;
    if (e == null) return;
    _skipped.add((e.word, e.start));
    _from = e.end;
    _next();
  }

  void _ignoreAll() {
    final e = _current;
    if (e == null) return;
    widget.session.ignoreAll(e.word);
    _next();
  }

  Future<void> _add() async {
    final e = _current;
    if (e == null) return;
    await widget.session.addToDictionary(e.word);
    if (mounted) _next();
  }

  // MCP (`ui.get_dialog`, suite 09 §6.2): the flagged word, the
  // `suggestion` select and the dialog's buttons.

  @override
  Map<String, Object?> describe() {
    final l = wonkyAppL10nOrEnglish(context);
    final e = _current;
    final canChange = e != null && _replacement != null;
    return {
      'title': l.spellingTitle,
      'kind': 'spelling',
      'word': e?.word,
      if (e == null)
        'message': widget.session.isAvailable
            ? l.spellingNoErrors
            : l.spellingUnavailable,
      'fields': [
        if (e != null)
          {
            'id': 'suggestion',
            'label': l.spellingSuggestions,
            'type': 'select',
            'value': _replacement,
            'options': _suggestions,
          },
      ],
      'buttons': [
        if (e != null) ...[
          {'id': 'change', 'label': l.spellingChange, 'enabled': canChange},
          {
            'id': 'change_all',
            'label': l.spellingChangeAll,
            'enabled': canChange,
          },
          {'id': 'ignore', 'label': l.spellingIgnore},
          {'id': 'ignore_all', 'label': l.spellingIgnoreAll},
          {'id': 'add', 'label': l.spellingAddToDictionary},
        ],
        {'id': 'done', 'label': l.spellingDone},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id != 'suggestion') return false;
    final i = value is int ? value : _suggestions.indexOf('$value');
    if (i < 0 || i >= _suggestions.length) return false;
    setState(() => _chosen = i);
    return true;
  }

  @override
  bool press(String buttonId) {
    final e = _current;
    switch (buttonId) {
      case 'done' || 'cancel' || 'close':
        Navigator.of(context).pop();
      case 'change' when e != null && _replacement != null:
        _change();
      case 'change_all' when e != null && _replacement != null:
        _changeAll();
      case 'ignore' when e != null:
        _ignore();
      case 'ignore_all' when e != null:
        _ignoreAll();
      case 'add' when e != null:
        _add();
      default:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = wonkyAppL10nOrEnglish(context);
    final k = widget.keys;
    final e = _current;
    return ShadDialog(
      key: k.dialog,
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.spellingTitle),
      constraints: const BoxConstraints(maxWidth: 440),
      actions: [
        ShadButton(
          key: k.done,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.spellingDone),
        ),
      ],
      child: e == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.session.isAvailable
                    ? l.spellingNoErrors
                    : l.spellingUnavailable,
                style: theme.textTheme.muted,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.spellingNotInDictionary, style: theme.textTheme.small),
                const SizedBox(height: 4),
                Text(
                  e.word,
                  key: k.word,
                  style: theme.textTheme.large.copyWith(
                    color: theme.colorScheme.destructive,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l.spellingSuggestions, style: theme.textTheme.small),
                const SizedBox(height: 4),
                if (_suggestions.isEmpty)
                  Text(l.spellingNoSuggestions, style: theme.textTheme.muted)
                else
                  for (var i = 0; i < _suggestions.length; i += 1)
                    ShadButton.ghost(
                      key: k.suggestion(i),
                      mainAxisAlignment: MainAxisAlignment.start,
                      backgroundColor: i == _chosen
                          ? theme.colorScheme.accent
                          : null,
                      onPressed: () => setState(() => _chosen = i),
                      onDoubleTap: _change,
                      child: Text(_suggestions[i]),
                    ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ShadButton.secondary(
                      key: k.change,
                      enabled: _replacement != null,
                      onPressed: _change,
                      child: Text(l.spellingChange),
                    ),
                    ShadButton.outline(
                      key: k.changeAll,
                      enabled: _replacement != null,
                      onPressed: _changeAll,
                      child: Text(l.spellingChangeAll),
                    ),
                    ShadButton.outline(
                      key: k.ignore,
                      onPressed: _ignore,
                      child: Text(l.spellingIgnore),
                    ),
                    ShadButton.outline(
                      key: k.ignoreAll,
                      onPressed: _ignoreAll,
                      child: Text(l.spellingIgnoreAll),
                    ),
                    ShadButton.outline(
                      key: k.add,
                      onPressed: _add,
                      child: Text(l.spellingAddToDictionary),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// Tools › Spelling › Personal dictionary…: the user's added words.
Future<void> showPersonalDictionaryDialog(
  BuildContext context, {
  required List<String> Function() words,
  required Future<void> Function(String word) onRemove,
  required Future<void> Function(String word) onAdd,
  SpellingKeySet keys = SpellingKeys.write,
}) => showShadDialog<void>(
  context: context,
  builder: (_) => _PersonalDictionaryDialog(
    words: words,
    onRemove: onRemove,
    onAdd: onAdd,
    keys: keys,
  ),
);

class _PersonalDictionaryDialog extends StatefulWidget {
  const _PersonalDictionaryDialog({
    required this.words,
    required this.onRemove,
    required this.onAdd,
    required this.keys,
  });

  final SpellingKeySet keys;
  final List<String> Function() words;
  final Future<void> Function(String word) onRemove;
  final Future<void> Function(String word) onAdd;

  @override
  State<_PersonalDictionaryDialog> createState() =>
      _PersonalDictionaryDialogState();
}

class _PersonalDictionaryDialogState extends State<_PersonalDictionaryDialog>
    with McpDialogRegistration<_PersonalDictionaryDialog> {
  final _field = TextEditingController();

  // MCP (`ui.get_dialog`): the `word` field, the words, `add`,
  // `remove:<word>` and `done`.

  @override
  Map<String, Object?> describe() {
    final l = wonkyAppL10nOrEnglish(context);
    final words = [...widget.words()]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return {
      'title': l.spellingPersonalDictionary,
      'description': l.spellingPersonalDictionaryHint,
      'kind': 'personalDictionary',
      'fields': [
        {
          'id': 'word',
          'label': l.spellingAddWord,
          'type': 'text',
          'value': _field.text,
        },
      ],
      'words': words,
      'buttons': [
        {'id': 'add', 'label': l.spellingAdd},
        for (final w in words)
          {'id': 'remove:$w', 'label': l.spellingRemoveWord(w)},
        {'id': 'done', 'label': l.spellingDone},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id != 'word') return false;
    _field.text = '${value ?? ''}'.replaceAll(RegExp(r'\s'), '');
    return true;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'done' || buttonId == 'cancel' || buttonId == 'close') {
      Navigator.of(context).pop();
      return true;
    }
    if (buttonId == 'add') {
      _add();
      return true;
    }
    if (buttonId.startsWith('remove:')) {
      final w = buttonId.substring(7);
      if (!widget.words().contains(w)) return false;
      widget.onRemove(w).then((_) {
        if (mounted) setState(() {});
      });
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final word = _field.text.trim();
    if (word.isEmpty || word.contains(RegExp(r'\s'))) return;
    await widget.onAdd(word);
    _field.clear();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final l = wonkyAppL10nOrEnglish(context);
    final words = [...widget.words()]
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ShadDialog(
      key: widget.keys.dictionary,
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.spellingPersonalDictionary),
      description: Text(l.spellingPersonalDictionaryHint),
      constraints: const BoxConstraints(maxWidth: 420),
      actions: [
        ShadButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.spellingDone),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  controller: _field,
                  placeholder: Text(l.spellingAddWord),
                  onSubmitted: (_) => _add(),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ShadButton.outline(onPressed: _add, child: Text(l.spellingAdd)),
            ],
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: words.isEmpty
                ? Text(l.spellingNoWords, style: theme.textTheme.muted)
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final w in words)
                        Row(
                          children: [
                            Expanded(child: Text(w)),
                            ShadIconButton.ghost(
                              key: widget.keys.remove(w),
                              width: 28,
                              height: 28,
                              iconSize: 14,
                              semanticLabel: l.spellingRemoveWord(w),
                              icon: const Icon(LucideIcons.x),
                              onPressed: () async {
                                await widget.onRemove(w);
                                if (mounted) setState(() {});
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
