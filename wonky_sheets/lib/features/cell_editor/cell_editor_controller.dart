import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart' hide RichText;
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_sheets_core/model.dart' show RichText;
import 'package:wonky_sheets_core/formula.dart';

import '../grid/selection/data_edge_finder.dart';
import '../model/custom_function_forwarder.dart';
import '../model/memory_workbook_session.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import '../formatting/rich_text_editing.dart';
import '../formatting/sheets_user_defaults.dart';
import 'column_autocomplete.dart';
import 'formula_preview.dart';
import 'formula_text_controller.dart';

/// Editing modes (03 §8.1). Point mode is a flag on top of [enter]/[edit].
enum EditMode { enter, edit }

/// Where the user types.
enum EditSurface { cell, formulaBar }

/// Where the active cell goes after a commit (03 §7.2).
enum CommitMove {
  none,
  enter,
  enterReverse,
  tab,
  tabReverse,
  up,
  down,
  left,
  right;

  static CommitMove parse(String? name) =>
      values.where((m) => m.name == name).firstOrNull ?? CommitMove.enter;
}

/// One open edit (03 §8.2 `CellEditSession`): the target cell by ids, the
/// original text and the point-mode reference being placed.
class CellEditSession {
  CellEditSession({
    required this.sheetId,
    required this.rowId,
    required this.colId,
    required this.original,
    required this.mode,
    required this.surface,
  });

  final String sheetId;
  final String rowId;
  final String colId;
  final String original;
  EditMode mode;
  EditSurface surface;

  /// Span of the reference inserted by point mode (start, end), if any.
  (int, int)? pointSpan;

  /// The pointed range: anchor and focus cells (indices on the active sheet).
  (int, int)? pointAnchor;
  (int, int)? pointFocus;
}

/// The cell editor state machine (03 §8): begin/commit/cancel, Enter ⇄ Edit,
/// point mode, F4, function autocomplete and signature help. The overlay and
/// the formula bar share [text].
class CellEditorController extends ChangeNotifier {
  CellEditorController(this.host) {
    text.addListener(_onText);
  }

  final SheetEditorController host;
  final FormulaTextController text = FormulaTextController();
  final FocusNode cellFocus = FocusNode(
    debugLabel: 'sheets.cellEditor',
    skipTraversal: true,
  );
  final FocusNode barFocus = FocusNode(debugLabel: 'sheets.formulaBar');

  CellEditSession? _session;

  /// The rich runs the edited cell had when editing started.
  RichText? _originalRuns;
  bool _internal = false;
  bool _checking = false;

  /// Checks typed input before it is committed (data validation, 03 §8.4);
  /// false keeps the editor open with the text selected.
  /// Returns synchronously when no dialog is needed.
  FutureOr<bool> Function(CellEditSession session, String input)? commitCheck;
  String _lastText = '';

  /// Live formula result preview (03 §8.7).
  late final FormulaPreviewController preview = FormulaPreviewController(
    engine: () => host.engine,
    model: () => host.model,
  );

  /// The editing preferences of the user (Settings › Sheets).
  SheetsUserDefaults get _prefs => SheetsUserDefaults.of(host.services);

  CompletionList completions = CompletionList.empty;
  int completionIndex = 0;
  bool _completionDismissed = false;
  SignatureInfo? signature;
  FormulaParseError? parseError;

  /// Signature help card shown (Shift+F1) / expanded (F1).
  bool _helpVisible = true;
  bool _helpExpanded = false;
  bool get helpVisible => _helpVisible;
  set helpVisible(bool v) {
    _helpVisible = v;
    notifyListeners();
  }

  bool get helpExpanded => _helpExpanded;
  set helpExpanded(bool v) {
    _helpExpanded = v;
    notifyListeners();
  }

  CellEditSession? get session => _session;
  bool get isEditing => _session != null;
  bool get isFormula => text.text.startsWith('=');
  EditMode? get mode => _session?.mode;

  /// Whether the autocomplete popup shows.
  bool get showCompletions =>
      isEditing && !_completionDismissed && completions.items.isNotEmpty;

  /// The cell being edited, as indices of its sheet (null when gone).
  (int, int)? get target {
    final s = _session;
    if (s == null) return null;
    final sheet = host.model.sheet(s.sheetId);
    if (sheet == null) return null;
    final r = sheet.rows.indexOf(s.rowId);
    final c = sheet.columns.indexOf(s.colId);
    if (r < 0 || c < 0) return null;
    return (r, c);
  }

  /// Starts editing the active cell. [initialText] replaces the content
  /// (typing); null loads the existing input.
  void begin({
    String? initialText,
    EditMode mode = EditMode.edit,
    EditSurface surface = EditSurface.cell,
    int? caret,
  }) {
    if (!host.canEdit) return;
    final sheet = host.activeSheet;
    if (sheet == null) return;
    final r = host.selection.resolved;
    final row = r.activeRow;
    final col = r.activeCol;
    final refusal = host.editRefusalAt(row, col);
    if (refusal != null) {
      host.services.toasts.show(refusal);
      return;
    }
    final original = host.editableText(row, col);
    _session = CellEditSession(
      sheetId: sheet.id,
      rowId: sheet.rows.idAt(row),
      colId: sheet.columns.idAt(col),
      original: original,
      mode: mode,
      surface: surface,
    );
    final t = initialText ?? original;
    text.locale = host.formulaLocale;
    // Typing in the ready state already put the text (and an IME
    // composition) into the field: keep it as it is.
    if (text.text != t || initialText == null) {
      _internal = true;
      text.value = TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(
          offset: (caret ?? t.length).clamp(0, t.length),
        ),
      );
      _internal = false;
    }
    _lastText = t;
    // Rich text runs of the edited cell (06 §11, 03 §8.8).
    text.richRuns = initialText == null
        ? RichTextEditing.runsOfCell(host, sheet.id, row, col)
        : null;
    _originalRuns = text.richRuns;
    text.richStyle = (f, base) => RichTextEditing.runStyle(
      f,
      base,
      theme: host.model.theme,
      pxPerPoint: 4 / 3 * host.scroll.zoom,
    );
    _completionDismissed = false;
    _refreshAssist();
    if (initialText != null) _autocompleteColumn('');
    _schedulePreview();
    host.clipMark.value = null;
    host.revealCell(row, col);
    notifyListeners();
    host.overlaySignal.fire();
    _focusSurface();
  }

  void _focusSurface() {
    final s = _session;
    if (s == null) return;
    final node = s.surface == EditSurface.cell ? cellFocus : barFocus;
    // The cell editor's EditableText is always mounted, so focus moves now
    // and the next keystroke already reaches it. The formula bar's field is
    // built on demand: focus it after the frame too.
    node.requestFocus();
    if (node == barFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_session != null) node.requestFocus();
      });
    }
  }

  /// Appends typed characters that arrived before the editor took focus.
  void appendTyped(String chars) {
    if (_session == null) return;
    final v = text.value;
    final sel = v.selection.isValid
        ? v.selection
        : TextSelection.collapsed(offset: v.text.length);
    final t = v.text.replaceRange(sel.start, sel.end, chars);
    text.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: sel.start + chars.length),
    );
  }

  /// Switches the surface (click into the formula bar while editing).
  void setSurface(EditSurface surface) {
    final s = _session;
    if (s == null || s.surface == surface) return;
    s.surface = surface;
    s.mode = EditMode.edit;
    notifyListeners();
    host.overlaySignal.fire();
  }

  void _onText() {
    if (_session == null) {
      // Ready state: the hidden field has focus while the grid is focused;
      // the first typed text (keyboard, IME, dictation) starts editing with
      // it (03 §8.3).
      if (!_internal && text.text.isNotEmpty) {
        if (host.canEdit && host.activeSheet != null) {
          begin(initialText: text.text, mode: EditMode.enter);
        } else {
          clearReady();
        }
      }
      return;
    }
    final previous = _lastText;
    final changed = text.text != _lastText;
    _lastText = text.text;
    final runs = text.richRuns;
    if (changed && runs != null) {
      text.richRuns = RichTextEditing.remapRuns(runs, text.text);
    }
    if (changed && !_internal) {
      final s = _session!;
      s.pointSpan = null;
      s.pointAnchor = null;
      s.pointFocus = null;
      _completionDismissed = false;
    }
    _refreshAssist();
    if (changed && !_internal) {
      _autocompleteColumn(previous);
      _schedulePreview();
    }
    notifyListeners();
    host.overlaySignal.fire();
  }

  /// Completes typed text from the column (03 §8.5): the rest of the only
  /// matching value is inserted selected, so typing on refines it,
  /// Backspace drops it and Tab/Enter accept it.
  void _autocompleteColumn(String previous) {
    final s = _session;
    final t = text.text;
    final sel = text.selection;
    if (s == null ||
        s.mode != EditMode.enter ||
        text.richRuns != null ||
        t.length <= previous.length ||
        !t.startsWith(previous) ||
        !sel.isCollapsed ||
        sel.baseOffset != t.length ||
        !_prefs.columnAutocomplete) {
      return;
    }
    final at = target;
    final sheet = host.model.sheet(s.sheetId);
    if (at == null || sheet == null) return;
    final full = ColumnAutocomplete.suggest(sheet, at.$1, at.$2, t);
    if (full == null) return;
    final completed = t + full.substring(t.length);
    _internal = true;
    text.value = TextEditingValue(
      text: completed,
      selection: TextSelection(
        baseOffset: t.length,
        extentOffset: completed.length,
      ),
    );
    _internal = false;
    _lastText = completed;
  }

  void _schedulePreview() {
    final s = _session;
    final at = target;
    preview.schedule(text.text, sheetId: s?.sheetId, row: at?.$1, col: at?.$2);
  }

  ForwardingCustomFunctionProvider? get _customFunctions {
    final s = host.session;
    return s is WorkbookSessionBase ? s.customFunctions : null;
  }

  void _refreshAssist() {
    final t = text.text;
    final caret = text.selection.isValid ? text.selection.baseOffset : t.length;
    if (!t.startsWith('=')) {
      completions = CompletionList.empty;
      signature = null;
      parseError = null;
      return;
    }
    final locale = host.formulaLocale;
    final prefs = _prefs;
    try {
      if (!prefs.formulaAutocomplete) throw const _Off();
      completions = completionsAt(
        t,
        caret,
        CompletionContext(
          locale: locale,
          sheetNames: [for (final s in host.model.sheets) s.name],
          maxItems: 8,
          // Script custom functions (09 §5).
          customFunctions: _customFunctions,
          customFunctionNames: _customFunctions?.names ?? const [],
        ),
      );
    } catch (_) {
      completions = CompletionList.empty;
    }
    if (completionIndex >= completions.items.length) completionIndex = 0;
    try {
      if (!prefs.formulaHelp) throw const _Off();
      signature = signatureAt(
        t,
        caret,
        locale: locale,
        customFunctions: _customFunctions,
      );
    } catch (_) {
      signature = null;
    }
    try {
      final v = validateFormula(t, locale: locale);
      // Missing closing parentheses are appended on commit (03 §8.4).
      parseError =
          v.ok || v.error?.messageKey == ParseErrorKey.missingCloseParen
          ? null
          : v.error;
    } catch (_) {
      parseError = null;
    }
  }

  /// Empties the hidden field between sessions.
  void clearReady() {
    text.richRuns = null;
    if (text.text.isEmpty) return;
    _internal = true;
    text.value = TextEditingValue.empty;
    _internal = false;
    _lastText = '';
  }

  /// Ends the session without writing.
  void cancel() {
    if (_session == null) return;
    _session = null;
    clearReady();
    _completionDismissed = false;
    completions = CompletionList.empty;
    signature = null;
    preview.clear();
    notifyListeners();
    host.overlaySignal.fire();
    _returnFocusToGrid();
  }

  /// Gives focus back to the grid outside the current key event: closing
  /// the text input connection while the browser is still dispatching the
  /// key (Esc) leaves the DOM text field focused on web.
  void _returnFocusToGrid() {
    if (cellFocus.hasFocus) return; // Ready state: the field keeps focus.
    if (barFocus.hasFocus) {
      scheduleMicrotask(() {
        if (_session == null) host.gridFocus.requestFocus();
      });
    } else {
      host.gridFocus.requestFocus();
    }
  }

  /// Commits without awaiting (sheet switches, clicks elsewhere).
  void commitSync({CommitMove move = CommitMove.none}) =>
      unawaited(commit(move: move));

  /// Writes the text to the target cell (or the whole selection with
  /// [toSelection]) through `sheets.cell.setInput`, then moves the active
  /// cell (03 §8.4). [source] is the invocation source of the write (an agent
  /// typing through `ui.sheets.type_in_cell` passes `mcp`).
  Future<bool> commit({
    CommitMove move = CommitMove.enter,
    bool toSelection = false,
    InvocationSource source = InvocationSource.ui,
  }) async {
    final s = _session;
    if (s == null) return false;
    final input = text.text;
    final rich = text.richRuns;
    final check = commitCheck;
    if (check != null && (input != s.original || toSelection)) {
      // Data validation (03 §8.4): a rejected input keeps the editor open
      // with its text selected.
      if (_checking) return false;
      var accepted = true;
      final r = check(s, input);
      if (r is Future<bool>) {
        _checking = true;
        try {
          accepted = await r;
        } finally {
          _checking = false;
        }
        if (!identical(_session, s)) return false;
      } else {
        accepted = r;
      }
      if (!accepted) {
        text.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.text.length,
        );
        _focusSurface();
        return false;
      }
    }
    _session = null;
    clearReady();
    completions = CompletionList.empty;
    signature = null;
    preview.clear();
    notifyListeners();
    host.overlaySignal.fire();
    if (host.activeSheetId != s.sheetId) host.activateSheet(s.sheetId);
    var ok = true;
    if (rich != null &&
        !toSelection &&
        !input.startsWith('=') &&
        (input != s.original || rich != _originalRuns)) {
      ok = await host.invokeCommand('sheets.cell.setRichText', {
        'text': input,
        'runs': rich.toJson()['runs'],
        'sheetId': s.sheetId,
        'rowId': s.rowId,
        'colId': s.colId,
      }, source);
    } else if (input != s.original || toSelection) {
      ok = await host.invokeCommand(
        toSelection
            ? 'sheets.cell.setInputForSelection'
            : 'sheets.cell.setInput',
        {
          'input': input,
          'sheetId': s.sheetId,
          'rowId': s.rowId,
          'colId': s.colId,
        },
        source,
      );
    }
    switch (move) {
      case CommitMove.none:
        break;
      case CommitMove.enter:
        host.enterMove();
      case CommitMove.enterReverse:
        host.enterMove(reverse: true);
      case CommitMove.tab:
        host.tabMove();
      case CommitMove.tabReverse:
        host.tabMove(reverse: true);
      case CommitMove.up:
        host.moveActive(NavDirection.up);
      case CommitMove.down:
        host.moveActive(NavDirection.down);
      case CommitMove.left:
        host.moveActive(NavDirection.left);
      case CommitMove.right:
        host.moveActive(NavDirection.right);
    }
    _returnFocusToGrid();
    return ok;
  }

  /// F2 inside the editor: Enter ⇄ Edit.
  void toggleMode() {
    final s = _session;
    if (s == null) return;
    s.mode = s.mode == EditMode.enter ? EditMode.edit : EditMode.enter;
    notifyListeners();
  }

  /// Inserts a newline at the caret (Alt+Enter).
  void insertNewline() => appendTyped('\n');

  // ---------------------------------------------------------------------------
  // Point mode (03 §8.7).

  /// Whether a click/arrow inserts a reference now.
  bool get pointEligible {
    final s = _session;
    if (s == null || !isFormula) return false;
    if (s.pointSpan != null) return true;
    if (s.mode == EditMode.edit && s.surface == EditSurface.cell) {
      // Edit mode: only when the caret sits at an insertion point.
    }
    final caret = text.selection.isValid
        ? text.selection.baseOffset
        : text.text.length;
    try {
      return refInsertionPoint(text.text, caret, locale: host.formulaLocale);
    } catch (_) {
      return false;
    }
  }

  /// Whether a point reference is being placed (arrows move it).
  bool get isPointing => _session?.pointSpan != null;

  /// Inserts (or replaces the pending) reference to [rect] on the active
  /// sheet. [add] inserts a separator and a new reference (Mod+click).
  void pointAt(
    GridRect rect, {
    bool add = false,
    bool wholeRows = false,
    bool wholeColumns = false,
  }) {
    final s = _session;
    if (s == null) return;
    var ref = wholeColumns
        ? '${ColumnLetters.fromIndex(rect.left)}:${ColumnLetters.fromIndex(rect.right)}'
        : wholeRows
        ? '${rect.top + 1}:${rect.bottom + 1}'
        : (rect.isSingleCell ? CellPos(rect.top, rect.left).a1 : rect.a1);
    if (host.activeSheetId != s.sheetId) {
      final name = host.activeSheet?.name ?? '';
      ref = '${_quoteSheet(name)}!$ref';
    }
    final t = text.text;
    int start;
    int end;
    var prefix = '';
    final span = s.pointSpan;
    if (span != null && !add) {
      (start, end) = span;
    } else {
      final sel = text.selection.isValid
          ? text.selection
          : TextSelection.collapsed(offset: t.length);
      start = sel.start;
      end = sel.end;
      if (add && span != null) {
        start = span.$2;
        end = span.$2;
        prefix = host.formulaLocale.argSeparator;
      }
    }
    final insert = '$prefix$ref';
    final next = t.replaceRange(start, end, insert);
    final refStart = start + prefix.length;
    _internal = true;
    text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    _internal = false;
    s.pointSpan = (refStart, refStart + ref.length);
    s.pointAnchor = (rect.top, rect.left);
    s.pointFocus = (rect.bottom, rect.right);
    // A pointed reference is not a function prefix to complete.
    _completionDismissed = true;
    _refreshAssist();
    notifyListeners();
    host.overlaySignal.fire();
  }

  /// Arrow keys in point mode: moves (or extends) the pointed reference.
  void movePoint(NavDirection d, {bool extend = false, bool toEdge = false}) {
    final s = _session;
    final sheet = host.activeSheet;
    if (s == null || sheet == null) return;
    var focus = s.pointFocus;
    var anchor = s.pointAnchor;
    if (focus == null) {
      final t = host.activeSheetId == s.sheetId ? target : null;
      focus = t ?? (0, 0);
      anchor = focus;
      if (!extend) {
        // The first arrow press points at the neighbour of the edited cell.
      }
    }
    var (r, c) = focus;
    if (toEdge) {
      (r, c) = host.edgeFinder().next(r, c, d);
    } else {
      r = (r + d.dRow).clamp(0, sheet.rows.length - 1);
      c = (c + d.dCol).clamp(0, sheet.columns.length - 1);
    }
    if (extend && anchor != null) {
      pointAt(GridRect.normalized(anchor.$1, anchor.$2, r, c));
      s.pointAnchor = anchor;
      s.pointFocus = (r, c);
    } else {
      pointAt(GridRect.cell(r, c));
    }
    host.revealCell(r, c);
  }

  static String _quoteSheet(String name) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name) &&
          A1Area.tryParse(name) == null
      ? name
      : "'${name.replaceAll("'", "''")}'";

  /// F4: cycles `$` on the reference at the caret (03 §8.7).
  bool cycleAbsoluteRef() {
    if (!isFormula) return false;
    final sel = text.selection;
    final caret = sel.isValid ? sel.start : text.text.length;
    final edit = cycleAbsolute(
      text.text,
      caret,
      selectionEnd: sel.isValid && !sel.isCollapsed ? sel.end : null,
      locale: host.formulaLocale,
    );
    if (edit == null) return false;
    text.value = TextEditingValue(
      text: edit.text,
      selection: TextSelection(
        baseOffset: edit.selectionStart,
        extentOffset: edit.selectionEnd,
      ),
    );
    return true;
  }

  /// Wraps/unwraps the formula in ARRAYFORMULA (Mod+Shift+Enter).
  void toggleArray() {
    if (!isFormula) return;
    final t = toggleArrayFormula(text.text);
    text.value = TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }

  // ---------------------------------------------------------------------------
  // Autocomplete.

  void moveCompletion(int delta) {
    final n = completions.items.length;
    if (n == 0) return;
    completionIndex = (completionIndex + delta) % n;
    if (completionIndex < 0) completionIndex += n;
    notifyListeners();
  }

  void dismissCompletions() {
    _completionDismissed = true;
    notifyListeners();
  }

  /// Inserts the highlighted completion (`SUM(`).
  void acceptCompletion([int? index]) {
    final items = completions.items;
    if (items.isEmpty) return;
    final item = items[math.min(index ?? completionIndex, items.length - 1)];
    final t = text.text;
    final start = completions.replaceStart;
    final end = completions.replaceEnd;
    final next = t.replaceRange(start, end, item.insertText);
    text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: start + item.insertText.length,
      ),
    );
    completionIndex = 0;
  }

  @override
  void dispose() {
    preview.dispose();
    text.removeListener(_onText);
    text.dispose();
    cellFocus.dispose();
    barFocus.dispose();
    super.dispose();
  }
}

/// A disabled preference (formula autocomplete / help off).
class _Off implements Exception {
  const _Off();
}
