import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_slides_core/find.dart';
import 'package:wonky_slides_core/model.dart' show DeckChangeBatch;
import 'package:wonky_slides_core/ops.dart';

import '../../l10n/slides_l10n.dart';
import '../canvas/slide_canvas_controller.dart' show selectionOf;
import '../editor_screen/deck_editor_controller.dart';
import '../text_editing/text_editing_host.dart';

/// Find and replace of an open deck (Slides 03 §13): the query, options
/// and matches (core `DeckFind`, recomputed when the deck changes), the
/// current match, navigation (the match's slide becomes current and the
/// match is selected in its body — text editing when the canvas is
/// shown) and replacing (one undo step; bodies soft-locked by others are
/// skipped). The find bar and the *Find and replace* panel are views of
/// it. View state, not undoable.
class DeckFindController extends ChangeNotifier implements FindBarModel {
  DeckFindController._(this.editor) {
    editor.session.model.addListener(_onModel);
  }

  static final Expando<DeckFindController> _registry = Expando('slidesFind');

  /// The find state of [ed].
  static DeckFindController of(DeckEditorController ed) =>
      _registry[ed] ??= DeckFindController._(ed);

  /// Whether [ed] has a find state (without creating one).
  static DeckFindController? maybeOf(DeckEditorController ed) => _registry[ed];

  final DeckEditorController editor;

  bool _barOpen = false;
  bool _panelOpen = false;
  String _query = '';
  DeckFindOptions _options = const DeckFindOptions();
  List<DeckFindMatch> _matches = const [];
  int _current = -1;
  String? _error;
  Timer? _debounce;

  /// Asks the find bar to focus and select its query.
  @override
  final ValueNotifier<int> focusRequest = ValueNotifier(0);

  /// The replacement text of the panel (kept while it is closed).
  String replacement = '';

  bool get barOpen => _barOpen;
  bool get panelOpen => _panelOpen;
  bool get isOpen => _barOpen || _panelOpen;
  @override
  String get query => _query;
  DeckFindOptions get options => _options;
  List<DeckFindMatch> get matches => _matches;
  @override
  bool get hasResults => _matches.isNotEmpty;

  /// The index of the current match (-1 = none yet).
  int get currentIndex => _current;

  /// The invalid regular expression message, or null.
  String? get error => _error;

  DeckFindMatch? get currentMatch =>
      _current >= 0 && _current < _matches.length ? _matches[_current] : null;

  /// Opens the compact find bar (03 §13, ⌘F).
  void openBar({String? query}) {
    _barOpen = true;
    _panelOpen = false;
    if (query != null) _setQuery(query);
    focusRequest.value++;
    notifyListeners();
  }

  /// Opens the *Find and replace* panel (⇧⌘H).
  void openPanel({String? query, String? replace}) {
    _panelOpen = true;
    _barOpen = false;
    if (query != null) _setQuery(query);
    if (replace != null) replacement = replace;
    notifyListeners();
  }

  /// Closes the bar and the panel (the canvas gets the focus back).
  void close() {
    if (!isOpen) return;
    _barOpen = false;
    _panelOpen = false;
    notifyListeners();
    editor.canvasFocus.requestFocus();
  }

  /// Sets the query and options and searches again.
  @override
  void setQuery(String query) => search(query);

  void search(String query, {DeckFindOptions? options}) {
    final o = options ?? _options;
    if (query == _query && o == _options) return;
    _options = o;
    _setQuery(query);
    notifyListeners();
  }

  void _setQuery(String q) {
    _query = q;
    _current = -1;
    _recompute();
  }

  /// The options with the scope's slides filled in from the editor.
  DeckFindOptions _scoped(DeckFindOptions o) => switch (o.scope) {
    FindScope.all => o,
    FindScope.currentSlide => o.copyWith(slideIds: [?editor.currentSlideId]),
    FindScope.selectedSlides => o.copyWith(
      slideIds: editor.selectedSlideIds.isEmpty
          ? [?editor.currentSlideId]
          : editor.order.entries
                .where((e) => editor.selectedSlideIds.contains(e.id))
                .map((e) => e.id)
                .toList(),
    ),
  };

  void _recompute() {
    final prev = currentMatch;
    try {
      _matches = DeckFind.search(editor.model, _query, _scoped(_options));
      _error = null;
    } on FormatException {
      _matches = const [];
      _error = slidesL10nOf(editor.services).findInvalidRegex;
    }
    if (prev != null) {
      // Keep the position on the same match when it still exists.
      _current = _matches.indexWhere(
        (m) => m.bodyKey == prev.bodyKey && m.start == prev.start,
      );
    } else if (_current >= _matches.length) {
      _current = -1;
    }
  }

  void _onModel(DeckChangeBatch _) {
    if (!isOpen || _query.isEmpty) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _recompute();
      notifyListeners();
    });
  }

  /// Recomputes now (tests, after a replace).
  void refresh() {
    _debounce?.cancel();
    _recompute();
    notifyListeners();
  }

  /// `(current 1-based or 0, total)`.
  (int, int) get status => (_current + 1, _matches.length);

  /// Moves to the next ([forward]) or previous match and shows it. Returns
  /// the match (null without matches).
  DeckFindMatch? step({bool forward = true}) {
    _debounce?.cancel();
    _recompute();
    if (_matches.isEmpty) {
      _current = -1;
      notifyListeners();
      return null;
    }
    if (_current < 0) {
      _current = forward ? _firstFromCurrentSlide() : _matches.length - 1;
    } else {
      _current = (_current + (forward ? 1 : -1)) % _matches.length;
      if (_current < 0) _current += _matches.length;
    }
    final m = _matches[_current];
    show(m);
    notifyListeners();
    return m;
  }

  /// The first match on or after the current slide.
  int _firstFromCurrentSlide() {
    final cur = editor.currentSlideId;
    if (cur == null) return 0;
    final order = editor.order.entries.map((e) => e.id).toList();
    final at = order.indexOf(cur);
    final i = _matches.indexWhere((m) => order.indexOf(m.slideId) >= at);
    return i < 0 ? 0 : i;
  }

  /// Shows [m]: its slide becomes current; element and cell matches are
  /// selected in their body (text editing on the canvas, unless someone
  /// else edits it), notes matches open the notes.
  void show(DeckFindMatch m) {
    if (editor.currentSlideId != m.slideId) editor.setCurrentSlide(m.slideId);
    final t = m.target;
    switch (t) {
      case NotesText():
        if (!editor.notesVisible) editor.setNotesVisible(true);
      case ElementText(:final elementId):
        _showInBody(elementId, m, null);
      case CellText(:final elementId, :final rowId, :final columnId):
        _showInBody(elementId, m, (rowId: rowId, columnId: columnId));
    }
  }

  void _showInBody(
    String elementId,
    DeckFindMatch m,
    ({String rowId, String columnId})? cell,
  ) {
    final host = textEditingOf(editor);
    final lockTarget = cell == null
        ? TextLockTarget.element(elementId)
        : TextLockTarget.cell(elementId, cell.rowId, cell.columnId);
    final locked = host.locks.heldByTarget(lockTarget) != null;
    if (!locked && host.canEdit(elementId, cell: cell != null)) {
      unawaited(
        host.begin(elementId, caretOffset: m.start, cell: cell).then((ok) {
          if (ok) host.active?.selectRange(m.start, m.start + m.length);
        }),
      );
      return;
    }
    host.end(select: false);
    final parent = editor.model.element(elementId)?.parentId;
    selectionOf(editor).select([elementId], enteredGroup: parent);
  }

  /// Replaces the current match (or shows the first one) and moves on —
  /// one undo step. Returns whether something was replaced.
  bool replaceCurrent(CommandContext ctx, String replace) {
    final m = currentMatch;
    if (m == null) {
      step();
      return false;
    }
    final l = slidesL10nOf(editor.services);
    final holder = _holderOf(m.target);
    if (holder != null) {
      if (!ctx.source.isAgent) {
        editor.services.toasts.show(l.toastFindBodyLocked(holder));
      }
      step();
      return false;
    }
    textEditingOf(editor).active?.commit();
    final json = _jsonOf(m.target);
    if (json == null) return false;
    final re = DeckFind.pattern(_query, _options)!;
    final text = DeckFind.expand(
      m.text,
      replace,
      re,
      useRegex: _options.useRegex,
    );
    final next = DeckFind.replaceRanges(json, [
      (m.start, m.length, text),
    ], notes: m.inNotes);
    editor.apply(ctx, SetText(m.target, next));
    final idx = _current;
    _recompute();
    // The next match is the one now at the same index.
    _current = _matches.isEmpty ? -1 : (idx - 1) % _matches.length;
    if (_matches.isNotEmpty) step();
    notifyListeners();
    return true;
  }

  /// Replaces every match (one undo step "Replace all", 03 §13); bodies
  /// another participant is editing are skipped. Returns (replaced,
  /// skipped, skipped holder name).
  (int, int, String?) replaceAll(CommandContext ctx, String replace) {
    _recompute();
    final re = DeckFind.pattern(_query, _options);
    if (re == null || _matches.isEmpty) return (0, 0, null);
    textEditingOf(editor).active?.commit();
    final byBody = <String, List<DeckFindMatch>>{};
    for (final m in _matches) {
      byBody.putIfAbsent(m.bodyKey, () => []).add(m);
    }
    var replaced = 0, skipped = 0;
    String? holderName;
    for (final list in byBody.values) {
      final target = list.first.target;
      final holder = _holderOf(target);
      if (holder != null) {
        skipped += list.length;
        holderName ??= holder;
        continue;
      }
      final json = _jsonOf(target);
      if (json == null) continue;
      final next = DeckFind.replaceRanges(json, [
        for (final m in list)
          (
            m.start,
            m.length,
            DeckFind.expand(m.text, replace, re, useRegex: _options.useRegex),
          ),
      ], notes: list.first.inNotes);
      editor.apply(ctx, SetText(target, next));
      replaced += list.length;
    }
    _current = -1;
    _recompute();
    notifyListeners();
    return (replaced, skipped, holderName);
  }

  /// The display name of someone else editing [t], or null.
  String? _holderOf(TextTarget t) {
    final locks = textEditingOf(editor).locks;
    return locks.heldByTarget(switch (t) {
      ElementText(:final elementId) => TextLockTarget.element(elementId),
      CellText(:final elementId, :final rowId, :final columnId) =>
        TextLockTarget.cell(elementId, rowId, columnId),
      NotesText(:final slideId) => TextLockTarget.notes(slideId),
    });
  }

  String? _jsonOf(TextTarget t) => switch (t) {
    ElementText(:final elementId) => editor.model.element(elementId)?.text,
    CellText(:final elementId, :final rowId, :final columnId) =>
      editor.model
          .cellsOf(elementId)
          .where((c) => c.rowId == rowId && c.columnId == columnId)
          .firstOrNull
          ?.text,
    NotesText(:final slideId) => editor.model.slide(slideId)?.notes,
  };

  /// The matches of the current slide's element and cell bodies, by body
  /// key (canvas highlights).
  Map<String, List<DeckFindMatch>> matchesOnSlide(String slideId) {
    final out = <String, List<DeckFindMatch>>{};
    for (final m in _matches) {
      if (m.slideId != slideId || m.inNotes) continue;
      out.putIfAbsent(m.bodyKey, () => []).add(m);
    }
    return out;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    editor.session.model.removeListener(_onModel);
    focusRequest.dispose();
    if (_registry[editor] == this) _registry[editor] = null;
    super.dispose();
  }
}
