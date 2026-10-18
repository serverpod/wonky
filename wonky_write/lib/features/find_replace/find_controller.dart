import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:super_editor/super_editor.dart'
    show DocumentChangeLog, MutableDocument;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../l10n/write_l10n.dart';
import '../editor/commands/write_editor_commands.dart';
import '../editor/controller/write_editor_controller.dart';
import '../editor/view/editor_view_state.dart';

/// Find and replace state (Write 04 §25, 05 §10.5): query, options,
/// matches (painted through `EditorViewState.setFindMatches`), the active
/// match, replace one / replace all (one undo step).
class FindController extends ChangeNotifier {
  FindController(this.editor, {this.commands, this.reveal, this.strings}) {
    editor.addListener(_onEditorChanged);
  }

  final WriteEditorController editor;

  /// Editing commands (replace). Defaults to a fresh instance.
  final WriteEditorCommands? commands;

  /// Scrolls a Delta offset into view.
  final void Function(int offset)? reveal;

  /// The UI strings (count label, errors, undo labels); English when null.
  final WriteLocalizations Function()? strings;

  WriteLocalizations get _l => strings?.call() ?? writeL10nEnglish;

  late final WriteEditorCommands _commands =
      commands ?? WriteEditorCommands(editor);

  static const maxMatches = 10000;

  String _query = '';
  String _replacement = '';
  bool _matchCase = false;
  bool _wholeWord = false;
  bool _regex = false;
  bool _active = false;
  bool _showReplace = false;
  List<SearchMatch> _matches = const [];
  int? _current;
  String? _error;
  bool _truncated = false;
  Timer? _timer;
  MutableDocument? _document;
  bool _replacing = false;

  String get query => _query;
  String get replacement => _replacement;
  bool get matchCase => _matchCase;
  bool get wholeWord => _wholeWord;
  bool get regex => _regex;

  /// Whether the panel is open (highlights painted).
  bool get isActive => _active;

  /// Whether the replace row is visible.
  bool get showReplace => _showReplace;
  List<SearchMatch> get matches => _matches;

  /// Index of the active match.
  int? get current => _current;

  /// Invalid regular expression message.
  String? get error => _error;

  /// More matches than [maxMatches] exist.
  bool get truncated => _truncated;

  bool get hasQuery => _query.isNotEmpty;

  /// "3 of 42" / "No results".
  String get countLabel {
    if (_query.isEmpty) return '';
    if (_error != null) return '';
    final l = _l;
    if (_matches.isEmpty) return l.findNoResults;
    final n = _truncated
        ? l.findCountMore(_matches.length)
        : '${_matches.length}';
    return _current == null ? n : l.findCountOf(_current! + 1, n);
  }

  /// Opens find (panel open; [query] prefills, e.g. the selected text).
  void open({String? query, bool replace = false}) {
    _active = true;
    if (replace) _showReplace = true;
    if (query != null && query.isNotEmpty && !query.contains('\n')) {
      _query = query;
    }
    _attachDocument();
    _search(selectNearest: true);
  }

  void close() {
    _active = false;
    _timer?.cancel();
    editor.view.clearFindMatches();
    notifyListeners();
  }

  void toggleReplace() {
    _showReplace = !_showReplace;
    notifyListeners();
  }

  set query(String value) {
    if (value == _query) return;
    _query = value;
    _search(selectNearest: true);
  }

  set replacement(String value) {
    if (value == _replacement) return;
    _replacement = value;
    notifyListeners();
  }

  set matchCase(bool value) {
    if (value == _matchCase) return;
    _matchCase = value;
    _search(selectNearest: true);
  }

  set wholeWord(bool value) {
    if (value == _wholeWord) return;
    _wholeWord = value;
    _search(selectNearest: true);
  }

  set regex(bool value) {
    if (value == _regex) return;
    _regex = value;
    _search(selectNearest: true);
  }

  FindSpec get spec => FindSpec(
    _query,
    regex: _regex,
    matchCase: _matchCase,
    wholeWord: _wholeWord,
  );

  void _attachDocument() {
    final doc = editor.document;
    if (identical(doc, _document)) return;
    _document?.removeListener(_onContent);
    _document = doc..addListener(_onContent);
  }

  void _onContent(DocumentChangeLog _) {
    if (!_active || _replacing) return;
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 150), () => _search());
  }

  void _onEditorChanged() {
    if (_active) _attachDocument();
  }

  /// Recomputes matches. With [selectNearest], the active match becomes the
  /// first one at or after the caret.
  void _search({bool selectNearest = false}) {
    _error = null;
    if (_query.isEmpty) {
      _matches = const [];
      _current = null;
      _truncated = false;
      _paint();
      notifyListeners();
      return;
    }
    try {
      final result = TextSearch(
        WonkyDocument(editor.delta),
      ).search(spec, limit: maxMatches, contextChars: 32);
      final previous = _current == null || _current! >= _matches.length
          ? null
          : _matches[_current!].start;
      _matches = result.matches;
      _truncated = result.truncated || result.total > result.matches.length;
      if (_matches.isEmpty) {
        _current = null;
      } else if (selectNearest || previous == null) {
        final caret = editor.selection?.start ?? 0;
        final i = _matches.indexWhere((m) => m.start >= caret);
        _current = i < 0 ? 0 : i;
      } else {
        final i = _matches.indexWhere((m) => m.start >= previous);
        _current = i < 0 ? _matches.length - 1 : i;
      }
    } on AddressException catch (e) {
      _matches = const [];
      _current = null;
      _error = _regex ? _l.findInvalidRegex : e.message;
    }
    _paint();
    notifyListeners();
  }

  void _paint() {
    if (!_active) return;
    editor.view.setFindMatches([
      for (final m in _matches) HighlightRange(m.start, m.start + m.length),
    ], active: _current);
  }

  /// Moves to the next match (wraps) and selects it.
  void next() => _step(1);

  /// Moves to the previous match (wraps) and selects it.
  void previous() => _step(-1);

  void _step(int delta) {
    if (_matches.isEmpty) return;
    final n = _matches.length;
    _current = _current == null
        ? (delta > 0 ? 0 : n - 1)
        : (_current! + delta + n) % n;
    _selectCurrent();
    _paint();
    notifyListeners();
  }

  /// Selects the match at [index] (results list click).
  void goTo(int index) {
    if (index < 0 || index >= _matches.length) return;
    _current = index;
    _selectCurrent();
    _paint();
    notifyListeners();
  }

  void _selectCurrent() {
    final m = _matches[_current!];
    editor.select(DeltaSelection(m.start, m.start + m.length));
    reveal?.call(m.start);
  }

  bool get canReplace => _commands.canEdit && _matches.isNotEmpty;

  String _replacementFor(SearchMatch m) {
    if (!_regex) return _replacement;
    // $1 … $9 and $& refer to the regex groups.
    return _replacement.replaceAllMapped(RegExp(r'\$(\d|&)'), (g) {
      final ref = g.group(1)!;
      if (ref == '&') return m.text;
      final index = int.parse(ref);
      return index < m.groups.length ? (m.groups[index] ?? '') : '';
    });
  }

  /// Replaces the active match and moves to the next one.
  bool replace() {
    if (!canReplace) return false;
    final index = _current ?? 0;
    final m = _matches[index];
    _replacing = true;
    final ok = _commands.replaceRangeWithTextLabelled(
      m.start,
      m.length,
      _replacementFor(m),
      label: _l.findUndoReplace,
    );
    _replacing = false;
    _search();
    if (ok && _matches.isNotEmpty) {
      _current = _current!.clamp(0, _matches.length - 1);
      _selectCurrent();
      _paint();
      notifyListeners();
    }
    return ok;
  }

  /// Replaces every match as **one** undo step; returns the count.
  int replaceAll() {
    if (!canReplace) return 0;
    final targets = List<SearchMatch>.of(_matches);
    var count = 0;
    _replacing = true;
    final label = _l.findUndoReplaceAll;
    try {
      editor.group(label, () {
        for (final m in targets.reversed) {
          if (_commands.replaceRangeWithTextLabelled(
            m.start,
            m.length,
            _replacementFor(m),
            label: label,
          )) {
            count++;
          }
        }
      });
    } finally {
      _replacing = false;
    }
    _search();
    return count;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _document?.removeListener(_onContent);
    editor.removeListener(_onEditorChanged);
    super.dispose();
  }
}
