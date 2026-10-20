import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_app/spellcheck.dart';

import '../editor/attributions/wonky_attributions.dart';
import '../editor/controller/write_editor_controller.dart';
import '../editor/mapping/wonky_schema.dart';

/// State of the spellchecker for the open document.
enum SpellcheckState {
  /// Underlines are turned off (Tools › Spelling › Underline errors).
  off,

  /// The dictionary is loading.
  loading,

  /// Checking is active.
  ready,

  /// No dictionary for the document language.
  noDictionary,
}

/// A misspelled word in the document (Delta offsets `[start, end)`).
@immutable
class SpellError {
  const SpellError({
    required this.nodeId,
    required this.word,
    required this.start,
    required this.end,
    required this.localStart,
  });

  final String nodeId;
  final String word;
  final int start;
  final int end;

  /// Offset of the word inside its block's text.
  final int localStart;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      other is SpellError &&
      other.nodeId == nodeId &&
      other.word == word &&
      other.start == start;

  @override
  int get hashCode => Object.hash(nodeId, word, start);
}

/// Spellcheck of one open document (Write 04 §28.2): checks changed blocks
/// incrementally (the caret block first) in time-sliced idle tasks of at
/// most [sliceBudget], and paints red wavy underlines through super_editor's
/// [SpellingAndGrammarStyler] (presentation only, never in the Delta).
///
/// Skipped: code blocks, inline code, links, mentions, URLs, emails, words
/// with digits, CamelCase, ALL-CAPS (setting), words under two characters,
/// and the word being typed. Personal words come from the user preferences;
/// *Ignore* lasts for this document's session.
class WriteSpellcheck extends ChangeNotifier {
  WriteSpellcheck({
    required this.controller,
    SpellDictionaries? dictionaries,
    this.debounce = const Duration(milliseconds: 120),
    this.sliceBudget = const Duration(milliseconds: 8),
  }) : _dictionaries = dictionaries ?? SpellDictionaries.instance {
    controller.document.addListener(_onDocumentChange);
    controller.composer.selectionNotifier.addListener(_onSelection);
  }

  final WriteEditorController controller;
  final SpellDictionaries _dictionaries;

  /// Wait after the last change before checking.
  final Duration debounce;

  /// Maximum work per slice (keeps frames under 16 ms while typing).
  final Duration sliceBudget;

  /// The underline layer (a custom style phase of the editor).
  final SpellingAndGrammarStyler styler = SpellingAndGrammarStyler(
    spellingErrorUnderlineStyle: const SquiggleUnderlineStyle(
      color: Color(0xffdc2626),
    ),
  );

  SpellEngine? _engine;
  SpellcheckState _state = SpellcheckState.off;
  bool _enabled = false;
  bool _skipAllCaps = true;
  String? _language;
  Set<String> _personal = const {};
  final Set<String> _ignored = {};
  int _generation = 0;

  final _dirty = <String>{};
  final _errors = <String, List<(int, int, String)>>{};
  final _cache = <String, bool>{};
  bool _frameScheduled = false;
  bool _immediate = false;
  Duration? _changedAt;
  String? _caretNodeId;

  SpellcheckState get state => _state;
  bool get enabled => _enabled;
  bool get skipAllCaps => _skipAllCaps;

  /// The dictionary in use ("en-US"), or `null`.
  String? get dictionaryTag => _engine?.tag;

  /// Words ignored in this document for the session.
  Set<String> get ignoredWords => Set.unmodifiable(_ignored);

  /// Sets the preferences and the document language; reloads as needed.
  void configure({
    required bool enabled,
    required String? language,
    bool skipAllCaps = true,
    Iterable<String> personalWords = const [],
  }) {
    final personal = personalWords.toSet();
    final languageChanged = language != _language;
    final changed =
        enabled != _enabled ||
        languageChanged ||
        skipAllCaps != _skipAllCaps ||
        personal.length != _personal.length ||
        !personal.containsAll(_personal);
    if (!changed) return;
    _enabled = enabled;
    _language = language;
    _skipAllCaps = skipAllCaps;
    _personal = personal;
    _engine?.setPersonalWords(_personal);
    if (!enabled) {
      _generation += 1;
      _setState(SpellcheckState.off);
      _clearAll();
      return;
    }
    if (_engine == null || languageChanged) {
      unawaited(_loadEngine());
    } else {
      _recheckAll();
    }
  }

  Future<void> _loadEngine() async {
    final generation = ++_generation;
    _engine = null;
    _clearAll();
    _setState(SpellcheckState.loading);
    final engine = await _dictionaries.engineFor(_language);
    if (generation != _generation || _disposed) return;
    if (engine == null) {
      _setState(SpellcheckState.noDictionary);
      return;
    }
    _engine = engine..setPersonalWords(_personal);
    _setState(SpellcheckState.ready);
    _recheckAll();
  }

  void _setState(SpellcheckState value) {
    if (value == _state) return;
    _state = value;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Scheduling.

  void _onDocumentChange(DocumentChangeLog log) {
    if (_engine == null) return;
    final removed = <String>[];
    for (final change in log.changes) {
      if (change is NodeRemovedEvent) {
        _dirty.remove(change.nodeId);
        if (_errors.remove(change.nodeId) != null) removed.add(change.nodeId);
      } else if (change is NodeDocumentChange) {
        _dirty.add(change.nodeId);
      }
    }
    if (removed.isNotEmpty) {
      // Not now: this listener may run before super_editor's layout has seen
      // the removal, and a style phase marked dirty then makes the layout
      // restyle its stale view model, which still has the removed block. It
      // throws ("No such position in document") and stops updating (#21).
      scheduleMicrotask(() {
        if (_disposed) return;
        for (final id in removed) {
          styler.clearErrorsForNode(id);
        }
      });
    }
    _schedule();
  }

  void _onSelection() {
    final caret = controller.composer.selection?.extent.nodeId;
    if (caret != _caretNodeId) {
      // Leaving a block: its last word is no longer "being typed".
      final left = _caretNodeId;
      _caretNodeId = caret;
      if (left != null && _engine != null) {
        _dirty.add(left);
        _schedule();
      }
    }
  }

  void _recheckAll() {
    _cache.clear();
    for (final node in controller.document) {
      _dirty.add(node.id);
    }
    _schedule(immediately: true);
  }

  /// Work runs in post-frame slices (no timers): the first frame after a
  /// change notes its time, slices start [debounce] later.
  void _schedule({bool immediately = false}) {
    if (_dirty.isEmpty || _engine == null || _disposed) return;
    if (immediately) _immediate = true;
    if (!immediately) _changedAt = null;
    _requestFrame();
  }

  void _requestFrame() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    final binding = SchedulerBinding.instance;
    binding.addPostFrameCallback(_onFrame);
    binding.scheduleFrame();
  }

  void _onFrame(Duration timeStamp) {
    _frameScheduled = false;
    if (_disposed || _dirty.isEmpty || _engine == null) return;
    if (!_immediate) {
      final changedAt = _changedAt ??= timeStamp;
      if (timeStamp - changedAt < debounce) {
        _requestFrame();
        return;
      }
    }
    _immediate = false;
    _changedAt = null;
    if (_runSlice()) {
      _immediate = true;
      _requestFrame();
    }
  }

  /// Checks dirty blocks (caret block first) for at most [sliceBudget].
  /// Returns whether work remains.
  bool _runSlice() {
    final engine = _engine;
    if (engine == null || _disposed) return false;
    final watch = Stopwatch()..start();
    final caret = controller.composer.selection?.extent.nodeId;
    if (caret != null && _dirty.remove(caret)) _checkNode(caret, engine);
    while (_dirty.isNotEmpty && watch.elapsed < sliceBudget) {
      final id = _dirty.first;
      _dirty.remove(id);
      _checkNode(id, engine);
    }
    return _dirty.isNotEmpty;
  }

  /// Completes once the dictionary has loaded (or failed to) — at most
  /// after [timeout].
  Future<void> whenSettled({Duration timeout = const Duration(seconds: 15)}) {
    if (_state != SpellcheckState.loading) return Future.value();
    final done = Completer<void>();
    void check() {
      if (_state != SpellcheckState.loading && !done.isCompleted) {
        done.complete();
      }
    }

    addListener(check);
    return done.future
        .timeout(timeout, onTimeout: () {})
        .whenComplete(() => removeListener(check));
  }

  /// Checks everything now (the spelling dialog, tests).
  void checkAllNow() {
    final engine = _engine;
    if (engine == null) return;
    for (final node in controller.document) {
      _dirty.add(node.id);
    }
    while (_dirty.isNotEmpty) {
      final id = _dirty.first;
      _dirty.remove(id);
      _checkNode(id, engine);
    }
  }

  // ---------------------------------------------------------------------------
  // Checking.

  void _checkNode(String nodeId, SpellEngine engine) {
    final node = controller.document.getNodeById(nodeId);
    if (node is! TextNode || isCodeBlockNode(node)) {
      if (_errors.remove(nodeId) != null) styler.clearErrorsForNode(nodeId);
      return;
    }
    final text = node.text;
    // Text with suggested deletions accepted, so a suggested replacement is
    // checked as the edit it proposes and not as old + new text glued
    // together (Write 04 §28.2).
    final (plain, toNode) = _acceptedText(text);
    final words = engine
        .words(
          plain,
          skipRanges: [
            for (final (start, end) in _skipRanges(text))
              ?_toProjected(toNode, start, end),
          ],
          skipAllCaps: _skipAllCaps,
        )
        .map(
          (w) => (
            start: toNode[w.start],
            end: toNode[w.end - 1] + 1,
            word: w.word,
            followedByPeriod: w.followedByPeriod,
          ),
        );
    final selection = controller.composer.selection;
    final caret =
        selection != null &&
            selection.isCollapsed &&
            selection.extent.nodeId == nodeId &&
            selection.extent.nodePosition is TextNodePosition
        ? (selection.extent.nodePosition as TextNodePosition).offset
        : null;
    final found = <(int, int, String)>[];
    for (final w in words) {
      // The word being typed is checked once the caret leaves it.
      if (caret != null && caret >= w.start && caret <= w.end) continue;
      if (_ignored.contains(w.word)) continue;
      final key = w.followedByPeriod ? '${w.word}.' : w.word;
      final ok = _cache[key] ??= engine.check(
        w.word,
        followedByPeriod: w.followedByPeriod,
      );
      if (!ok) found.add((w.start, w.end, w.word));
      if (_cache.length > 20000) _cache.clear();
    }
    final previous = _errors[nodeId];
    if (found.isEmpty) {
      if (previous != null) {
        _errors.remove(nodeId);
        styler.clearErrorsForNode(nodeId);
        notifyListeners();
      }
      return;
    }
    if (previous != null && _sameErrors(previous, found)) return;
    _errors[nodeId] = found;
    styler
      ..clearErrorsForNode(nodeId)
      ..addErrors(nodeId, {
        for (final (start, end, word) in found)
          TextError.spelling(
            nodeId: nodeId,
            range: TextRange(start: start, end: end),
            value: word,
          ),
      });
    notifyListeners();
  }

  static bool _sameErrors(
    List<(int, int, String)> a,
    List<(int, int, String)> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// [text] without its suggested deletions, and for every character of it
  /// its offset in [text].
  static (String, List<int>) _acceptedText(AttributedText text) {
    final plain = text.toPlainText();
    if (plain.isEmpty) return (plain, const []);
    final deleted = List<bool>.filled(plain.length, false);
    for (final span in text.getAttributionSpansInRange(
      attributionFilter: (a) =>
          a is SuggestionAttribution && a.type == SuggestionType.deletion,
      range: SpanRange(0, plain.length - 1),
    )) {
      for (var i = span.start; i <= span.end && i < plain.length; i += 1) {
        deleted[i] = true;
      }
    }
    final buffer = StringBuffer();
    final toNode = <int>[];
    for (var i = 0; i < plain.length; i += 1) {
      if (deleted[i]) continue;
      buffer.writeCharCode(plain.codeUnitAt(i));
      toNode.add(i);
    }
    return (buffer.toString(), toNode);
  }

  /// The node range `[start, end)` in the coordinates of [_acceptedText], or
  /// null when it was deleted entirely.
  static (int, int)? _toProjected(List<int> toNode, int start, int end) {
    var from = 0;
    while (from < toNode.length && toNode[from] < start) {
      from += 1;
    }
    var to = from;
    while (to < toNode.length && toNode[to] < end) {
      to += 1;
    }
    return to > from ? (from, to) : null;
  }

  static List<(int, int)> _skipRanges(AttributedText text) {
    final ranges = <(int, int)>[];
    for (final span in text.getAttributionSpansInRange(
      attributionFilter: (a) =>
          a == codeAttribution ||
          a is LinkAttribution ||
          a is MentionAttribution,
      range: SpanRange(0, text.length == 0 ? 0 : text.length - 1),
    )) {
      ranges.add((span.start, span.end + 1));
    }
    return ranges;
  }

  void _clearAll() {
    _dirty.clear();
    _errors.clear();
    styler.clearAllErrors();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Queries and actions.

  /// All current errors in document order.
  List<SpellError> get errors {
    final out = <SpellError>[];
    final mirror = controller.mirror;
    for (final node in controller.document) {
      final list = _errors[node.id];
      if (list == null) continue;
      final index = mirror.indexOfNode(node.id);
      if (index < 0) continue;
      final start = mirror.startOfIndex(index);
      for (final (s, e, word) in list) {
        out.add(
          SpellError(
            nodeId: node.id,
            word: word,
            start: start + s,
            end: start + e,
            localStart: s,
          ),
        );
      }
    }
    return out;
  }

  /// The error at Delta [offset] (inside or at its end), or `null`.
  SpellError? errorAt(int offset) {
    final position = controller.mirror.positionAt(offset);
    if (position == null) return null;
    final list = _errors[position.nodeId];
    final nodePosition = position.nodePosition;
    if (list == null || nodePosition is! TextNodePosition) return null;
    final local = nodePosition.offset;
    for (final (s, e, word) in list) {
      if (local >= s && local <= e) {
        final start = offset - (local - s);
        return SpellError(
          nodeId: position.nodeId,
          word: word,
          start: start,
          end: start + (e - s),
          localStart: s,
        );
      }
    }
    return null;
  }

  /// Suggestions for [word] (at most [max]).
  List<String> suggestionsFor(String word, {int max = 5}) =>
      _engine?.suggest(word, max: max) ?? const [];

  /// Whether [word] is spelled correctly (`null` without a dictionary).
  bool? isCorrect(String word) => _engine?.check(word);

  /// Ignores [word] in this document for the session.
  void ignore(String word) {
    if (!_ignored.add(word)) return;
    _recheckWord(word);
  }

  /// Rechecks blocks that contain [word] (after Ignore / Add).
  void _recheckWord(String word) {
    _cache.remove(word);
    for (final entry in _errors.entries) {
      if (entry.value.any((e) => e.$3 == word)) _dirty.add(entry.key);
    }
    final engine = _engine;
    if (engine == null) return;
    for (final id in _dirty.toList()) {
      _dirty.remove(id);
      _checkNode(id, engine);
    }
  }

  /// Called after the personal dictionary gained [word].
  void wordAdded(String word) {
    _personal = {..._personal, word};
    _engine?.setPersonalWords(_personal);
    _recheckWord(word);
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    controller.document.removeListener(_onDocumentChange);
    controller.composer.selectionNotifier.removeListener(_onSelection);
    styler.dispose();
    super.dispose();
  }
}
