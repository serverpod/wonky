import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart' show FindBarModel;
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../sheet_editor/sheet_editor_controller.dart';

/// Find options of the find bar and the Find and replace dialog (07 §11).
@immutable
class FindOptions {
  const FindOptions({
    this.matchCase = false,
    this.entireCell = false,
    this.regex = false,
    this.searchFormulas = false,
    this.searchLinks = false,
    this.scope = FindScope.sheet,
    this.range,
  });

  final bool matchCase;
  final bool entireCell;
  final bool regex;
  final bool searchFormulas;
  final bool searchLinks;
  final FindScope scope;

  /// A1 text of [FindScope.range].
  final String? range;

  FindOptions copyWith({
    bool? matchCase,
    bool? entireCell,
    bool? regex,
    bool? searchFormulas,
    bool? searchLinks,
    FindScope? scope,
    String? range,
  }) => FindOptions(
    matchCase: matchCase ?? this.matchCase,
    entireCell: entireCell ?? this.entireCell,
    regex: regex ?? this.regex,
    searchFormulas: searchFormulas ?? this.searchFormulas,
    searchLinks: searchLinks ?? this.searchLinks,
    scope: scope ?? this.scope,
    range: range ?? this.range,
  );

  /// The `sheets.find.replaceAll` arguments.
  Map<String, Object?> toArgs() => {
    'matchCase': matchCase,
    'matchEntireCell': entireCell,
    'useRegex': regex,
    'searchFormulas': searchFormulas,
    'searchLinks': searchLinks,
    'scope': switch (scope) {
      FindScope.allSheets => 'allSheets',
      FindScope.sheet => 'sheet',
      FindScope.range => 'range',
    },
    'range': ?range,
  };

  static FindOptions fromArgs(Map<String, Object?> a) => FindOptions(
    matchCase: a['matchCase'] == true,
    entireCell: a['matchEntireCell'] == true,
    regex: a['useRegex'] == true,
    searchFormulas: a['searchFormulas'] == true,
    searchLinks: a['searchLinks'] == true,
    scope: switch (a['scope']) {
      'allSheets' => FindScope.allSheets,
      'range' => FindScope.range,
      _ => FindScope.sheet,
    },
    range: a['range'] as String?,
  );
}

/// State of find (07 §11): query, options, the match list in navigation
/// order and the current match. The find bar, the dialog and the match
/// highlight layer read it; commands change it.
class FindController extends ChangeNotifier implements FindBarModel {
  FindController(this.ed);

  final SheetEditorController ed;

  WorkbookModel get model => ed.model;

  String _query = '';
  FindOptions _options = const FindOptions();
  List<FindMatch> _matches = const [];
  bool _capped = false;
  int _current = -1;
  String? _error;
  Timer? _debounce;
  bool _started = false;
  Map<String, Set<int>> _keys = const {};

  /// The find bar is open.
  final ValueNotifier<bool> barOpen = ValueNotifier(false);

  /// The Find and replace dialog is open.
  final ValueNotifier<bool> dialogOpen = ValueNotifier(false);

  /// Focus requests for the find bar input (bumped by `sheets.find.open`).
  @override
  final ValueNotifier<int> focusRequest = ValueNotifier(0);

  @override
  String get query => _query;
  FindOptions get options => _options;
  List<FindMatch> get matches => _matches;
  @override
  bool get hasResults => _matches.isNotEmpty;
  bool get capped => _capped;
  int get current => _current;
  String? get error => _error;

  /// Whether matches are highlighted (bar or dialog open with a query).
  bool get active =>
      (barOpen.value || dialogOpen.value) &&
      _query.isNotEmpty &&
      _error == null;

  FindMatch? get currentMatch =>
      _current >= 0 && _current < _matches.length ? _matches[_current] : null;

  void start() {
    if (_started) return;
    _started = true;
    model.addListener(_onBatch);
    barOpen.addListener(notifyListeners);
    dialogOpen.addListener(notifyListeners);
  }

  @override
  void dispose() {
    if (_started) model.removeListener(_onBatch);
    _debounce?.cancel();
    barOpen.dispose();
    dialogOpen.dispose();
    focusRequest.dispose();
    super.dispose();
  }

  /// Sets the query and searches; the first match from the active cell
  /// becomes current (and selected when [select]).
  @override
  void setQuery(String query, {FindOptions? options, bool select = true}) {
    _query = query;
    if (options != null) _options = options;
    _search(keepCurrent: false);
    if (select && _matches.isNotEmpty) {
      _current = 0;
      _reveal();
    }
    notifyListeners();
  }

  /// Changes the options and searches again.
  set options(FindOptions o) {
    _options = o;
    _search(keepCurrent: false);
    notifyListeners();
  }

  /// The query for the core engine.
  FindQuery queryFor({String? sheetId}) {
    final sid = sheetId ?? ed.activeSheetId;
    GridRect? range;
    String? rangeSheet;
    if (_options.scope == FindScope.range && _options.range != null) {
      try {
        final rr = model.parseA1(_options.range!, contextSheetId: sid);
        range = rr.rect;
        rangeSheet = rr.sheetId;
      } on InvalidRangeException {
        range = null;
      }
    }
    return FindQuery(
      _query,
      matchCase: _options.matchCase,
      entireCell: _options.entireCell,
      regex: _options.regex,
      searchFormulas: _options.searchFormulas,
      searchLinks: _options.searchLinks,
      scope: range == null && _options.scope == FindScope.range
          ? FindScope.sheet
          : _options.scope,
      sheetId: rangeSheet ?? sid,
      range: range,
    );
  }

  FindEngine get engine => FindEngine(
    model,
    CellTextReader(ed.engine, FormatterDisplayText(locale: ed.locale)),
    hooks: ed.hooks,
    locale: ed.locale,
  );

  void _search({required bool keepCurrent}) {
    final before = currentMatch;
    _error = null;
    if (_query.isEmpty) {
      _matches = const [];
      _capped = false;
      _current = -1;
      _keys = const {};
      return;
    }
    try {
      final sel = ed.selection.resolved;
      final r = engine.find(
        queryFor(),
        startSheetId: ed.activeSheetId,
        startRow: sel.activeRow,
        startCol: sel.activeCol,
        includeStart: true,
        skipHidden: true,
      );
      _matches = r.matches;
      _capped = r.capped;
    } on FindPatternException catch (e) {
      _error = e.message;
      _matches = const [];
      _capped = false;
    }
    final keys = <String, Set<int>>{};
    for (final m in _matches) {
      keys.putIfAbsent(m.sheetId, () => {}).add(_key(m.row, m.col));
    }
    _keys = keys;
    _current = -1;
    if (keepCurrent && before != null) {
      _current = _matches.indexWhere(
        (m) =>
            m.sheetId == before.sheetId &&
            m.row == before.row &&
            m.col == before.col,
      );
    }
  }

  static int _key(int row, int col) => row * 32768 + col;

  /// Whether (row, col) of [sheetId] is a match (highlight layer).
  bool isMatch(String sheetId, int row, int col) =>
      _keys[sheetId]?.contains(_key(row, col)) ?? false;

  /// Whether [sheetId] has matches.
  bool hasMatches(String sheetId) => _keys[sheetId]?.isNotEmpty ?? false;

  /// Moves to the next (or previous) match and selects it. Returns false
  /// when there is none.
  bool step({bool reverse = false}) {
    if (_matches.isEmpty) return false;
    if (_current < 0) {
      _current = reverse ? _matches.length - 1 : 0;
      // The first match may be the active cell itself: step past it.
      final m = _matches[_current];
      final sel = ed.selection.resolved;
      if (!reverse &&
          m.sheetId == ed.activeSheetId &&
          m.row == sel.activeRow &&
          m.col == sel.activeCol &&
          _matches.length > 1) {
        _current = 1;
      }
    } else {
      final n = _matches.length;
      _current = (_current + (reverse ? -1 : 1) + n) % n;
    }
    _reveal();
    notifyListeners();
    return true;
  }

  void _reveal() {
    final m = currentMatch;
    if (m == null) return;
    if (m.sheetId != ed.activeSheetId) ed.activateSheet(m.sheetId);
    ed.selection.selectCell(m.row, m.col);
    ed.revealCell(m.row, m.col);
    ed.overlaySignal.fire();
  }

  /// Re-runs the search (after a replace or external change).
  void refresh() {
    _search(keepCurrent: true);
    notifyListeners();
  }

  void _onBatch(WorkbookChangeBatch batch) {
    if (_query.isEmpty || !(barOpen.value || dialogOpen.value)) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), refresh);
  }

  /// "3 of 12" status parts: (current 1-based or 0, total, capped).
  (int, int, bool) get status => (_current + 1, _matches.length, _capped);
}
