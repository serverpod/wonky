import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../../theme/sheets_tokens.dart';
import '../cell_editor/formula_text_controller.dart';
import '../sheet_editor/sheet_editor_controller.dart';

/// A one-line formula input for panels and dialogs (custom formulas of
/// conditional formatting and filters, 06 §15.2): syntax colors, function
/// autocomplete (↑/↓, Enter/Tab, Esc), signature help, a live parse error
/// (shown once the user typed) and **point mode** — while the caret sits at
/// a reference insertion point (after `=`, `(`, a separator or an
/// operator), selecting on the grid inserts the reference; dragging or
/// selecting again replaces it until the user types.
class FormulaField extends StatefulWidget {
  const FormulaField({
    super.key,
    required this.editor,
    required this.value,
    required this.onChanged,
    this.keyName = 'formulaField',
    this.placeholder,
    this.enabled = true,
    this.error,
  });

  final SheetEditorController editor;
  final String value;
  final ValueChanged<String> onChanged;
  final String keyName;
  final String? placeholder;
  final bool enabled;

  /// An error to show under the field (besides the parse error), e.g.
  /// "Enter a value." once the user interacted.
  final String? error;

  @override
  State<FormulaField> createState() => FormulaFieldState();
}

class FormulaFieldState extends State<FormulaField> {
  late final FormulaTextController _text = FormulaTextController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode(debugLabel: 'formulaField');
  CompletionList _completions = CompletionList.empty;
  SignatureInfo? _signature;
  int _index = 0;
  bool _dismissed = false;

  /// Armed for point mode: the caret was at an insertion point when the
  /// grid took the focus.
  bool _armed = false;

  /// The span of the last pointed reference (replaced by the next pick).
  (int, int)? _pointSpan;
  bool _internal = false;

  SheetEditorController get ed => widget.editor;

  /// Whether a grid selection would insert a reference now (tests).
  bool get armed => _armed;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
    _focus.addListener(_onFocus);
    FocusManager.instance.addListener(_onGlobalFocus);
    ed.selection.addListener(_onSelection);
  }

  @override
  void didUpdateWidget(FormulaField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editor != widget.editor) {
      oldWidget.editor.selection.removeListener(_onSelection);
      ed.selection.addListener(_onSelection);
    }
    if (widget.value != _text.text) {
      _internal = true;
      _text.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
      _internal = false;
    }
  }

  @override
  void dispose() {
    ed.selection.removeListener(_onSelection);
    FocusManager.instance.removeListener(_onGlobalFocus);
    _text.removeListener(_onText);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  FormulaLocale get _locale => ed.formulaLocale;

  int get _caret =>
      _text.selection.isValid ? _text.selection.baseOffset : _text.text.length;

  bool get _eligible {
    if (!_text.text.startsWith('=')) return false;
    if (_pointSpan != null) return true;
    try {
      return refInsertionPoint(_text.text, _caret, locale: _locale);
    } catch (_) {
      return false;
    }
  }

  String? _lastText;

  void _onText() {
    final t = _text.text;
    if (t != _lastText) {
      _lastText = t;
      if (!_internal) {
        _pointSpan = null;
        _dismissed = false;
        widget.onChanged(t);
      }
    }
    _refreshAssist();
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _armed = false;
    } else {
      _armed = _eligible;
    }
    _refreshAssist();
  }

  /// Focus moving anywhere except the grid ends point mode.
  void _onGlobalFocus() {
    if (!_armed) return;
    final f = FocusManager.instance.primaryFocus;
    if (f == null || f == _focus || f == ed.gridFocus) return;
    if (ed.gridFocus.hasFocus) return;
    _armed = false;
    _pointSpan = null;
  }

  void _onSelection() {
    if (!mounted || !widget.enabled) return;
    if (!_armed && !(_focus.hasFocus && _eligible)) return;
    final sel = ed.selection.resolved;
    final ranges = sel.toResolvedRanges();
    if (ranges.isEmpty) return;
    final r = ranges[math.min(sel.activeRangeIndex, ranges.length - 1)];
    insertReference(_refText(r.sheetId, r.rect));
    // Typing continues in the formula, not in the grid.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focus.hasFocus) _focus.requestFocus();
    });
  }

  String _refText(String sheetId, GridRect rect) {
    final body = rect.isSingleCell ? CellPos(rect.top, rect.left).a1 : rect.a1;
    if (sheetId == ed.activeSheetId && _contextSheet == sheetId) return body;
    final name = ed.model.sheet(sheetId)?.name ?? '';
    final plain = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name);
    return plain ? '$name!$body' : "'${name.replaceAll("'", "''")}'!$body";
  }

  /// The sheet the formula belongs to (the active sheet when the field was
  /// last focused).
  late String _contextSheet = ed.activeSheetId;

  /// Inserts [ref] at the caret (or replaces the last pointed reference).
  void insertReference(String ref) {
    final t = _text.text;
    final span = _pointSpan;
    int start;
    int end;
    if (span != null && span.$2 <= t.length) {
      (start, end) = span;
    } else {
      final sel = _text.selection.isValid
          ? _text.selection
          : TextSelection.collapsed(offset: t.length);
      start = sel.start;
      end = sel.end;
    }
    final next = t.replaceRange(start, end, ref);
    _internal = true;
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + ref.length),
    );
    _internal = false;
    _lastText = next;
    _pointSpan = (start, start + ref.length);
    _dismissed = true;
    widget.onChanged(next);
    _refreshAssist();
  }

  void _refreshAssist() {
    final t = _text.text;
    var completions = CompletionList.empty;
    SignatureInfo? signature;
    if (_focus.hasFocus && t.startsWith('=')) {
      try {
        completions = completionsAt(
          t,
          _caret,
          CompletionContext(
            locale: _locale,
            sheetNames: [for (final s in ed.model.sheets) s.name],
            maxItems: 6,
          ),
        );
      } catch (_) {}
      try {
        signature = signatureAt(t, _caret, locale: _locale);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _completions = completions;
      _signature = signature;
      if (_index >= completions.items.length) _index = 0;
    });
  }

  bool get _showCompletions =>
      _focus.hasFocus && !_dismissed && _completions.items.isNotEmpty;

  void _accept([int? index]) {
    final items = _completions.items;
    if (items.isEmpty) return;
    final item = items[math.min(index ?? _index, items.length - 1)];
    final t = _text.text;
    final next = t.replaceRange(
      _completions.replaceStart,
      _completions.replaceEnd,
      item.insertText,
    );
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: _completions.replaceStart + item.insertText.length,
      ),
    );
    _index = 0;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_showCompletions) return KeyEventResult.ignored;
    final n = _completions.items.length;
    switch (e.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        setState(() => _index = (_index + 1) % n);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        setState(() => _index = (_index - 1 + n) % n);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.tab:
        _accept();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        setState(() => _dismissed = true);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String? _parseError() {
    final t = _text.text.trim();
    if (!t.startsWith('=') || t == '=') return null;
    try {
      final v = validateFormula(t, locale: _locale);
      return v.ok ? null : v.error?.message;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final cs = theme.colorScheme;
    final l = sheetsL10n(context);
    final tokens = GridPaintTokens.ofContext(context);
    _text
      ..tokens = tokens
      ..locale = _locale;
    if (_focus.hasFocus) _contextSheet = ed.activeSheetId;
    final parse = _parseError();
    final error = parse != null ? l.formulaParseError(parse) : widget.error;
    final mono = theme.textTheme.small.copyWith(
      fontFamily: WonkyFonts.geistMono,
      fontSize: 13,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: _onKey,
          child: ShadInput(
            key: ValueKey<String>(widget.keyName),
            controller: _text,
            focusNode: _focus,
            enabled: widget.enabled,
            placeholder: widget.placeholder == null
                ? null
                : Text(widget.placeholder!),
            style: const TextStyle(
              fontFamily: WonkyFonts.geistMono,
              fontSize: 13,
            ),
          ),
        ),
        if (_showCompletions)
          Container(
            key: ValueKey<String>('${widget.keyName}.completions'),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: cs.popover,
              border: Border.all(color: cs.border),
              borderRadius: theme.radius,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < _completions.items.length; i++)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _accept(i),
                    child: Container(
                      key: ValueKey<String>(
                        '${widget.keyName}.completion.${_completions.items[i].name}',
                      ),
                      color: i == _index ? cs.accent : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: _completions.items[i].name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_completions.items[i].summary.isNotEmpty)
                              TextSpan(
                                text: '  ${_completions.items[i].summary}',
                                style: TextStyle(color: cs.mutedForeground),
                              ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          )
        else if (_signature != null && _focus.hasFocus)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${_signature!.functionName}('),
                  for (var i = 0; i < _signature!.params.length; i++) ...[
                    if (i > 0) const TextSpan(text: ', '),
                    TextSpan(
                      text: _signature!.params[i],
                      style: i == _signature!.activeParam
                          ? TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.foreground,
                            )
                          : null,
                    ),
                  ],
                  const TextSpan(text: ')'),
                ],
              ),
              key: ValueKey<String>('${widget.keyName}.signature'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: mono.copyWith(fontSize: 12, color: cs.mutedForeground),
            ),
          ),
        if (_focus.hasFocus && _eligible)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              l.formulaFieldPointHint,
              key: ValueKey<String>('${widget.keyName}.pointHint'),
              style: theme.textTheme.muted.copyWith(fontSize: 12),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              error,
              key: ValueKey<String>('${widget.keyName}.error'),
              style: theme.textTheme.small.copyWith(
                color: cs.destructive,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
