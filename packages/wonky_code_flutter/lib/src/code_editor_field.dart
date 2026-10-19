import 'dart:async';

import 'package:flutter/foundation.dart' show mapEquals, setEquals;
import 'package:flutter/material.dart' show Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:re_editor/re_editor.dart';
import 'package:wonky_code/wonky_code.dart';

import 'code_text_styler.dart';

/// A change mark of a line in a [CodeEditorGutter] (Slides 07 §7 *Show
/// changes*).
enum CodeGutterMark {
  /// The line is new (green).
  added,

  /// The line changed (amber).
  changed,
}

/// The line-number gutter of a [CodeEditorField]: a fixed [width] (from the
/// code element's box geometry) with numbers right-aligned at
/// [numbersRight] in [fontSize], so they sit where the static rendering
/// draws them (Slides 07 §3.4, §3.5).
@immutable
class CodeEditorGutter {
  /// Creates a gutter.
  const CodeEditorGutter({
    required this.width,
    this.numbersRight,
    this.fontSize = 12,
    this.startLine = 1,
    this.color = const Color(0xff8b949e),
    this.activeColor = const Color(0xffe6edf3),
    this.marks = const {},
    this.removedBefore = const {},
  });

  /// Width left of the code text (padding and numbers).
  final double width;

  /// Right edge of the numbers (from the gutter's left), or null to hide
  /// them.
  final double? numbersRight;
  final double fontSize;

  /// Number of the first line.
  final int startLine;
  final Color color;

  /// The caret line's number.
  final Color activeColor;

  /// Change marks by 0-based line index (diff gutter).
  final Map<int, CodeGutterMark> marks;

  /// 0-based line indexes before which lines were removed (the line count
  /// = after the last line): a thin red marker.
  final Set<int> removedBefore;

  /// Mark colors (GitHub's diff colors, readable on light and dark code).
  static const addedColor = Color(0xff2da44e);
  static const changedColor = Color(0xffd29922);
  static const removedColor = Color(0xffcf222e);

  @override
  bool operator ==(Object other) =>
      other is CodeEditorGutter &&
      mapEquals(other.marks, marks) &&
      setEquals(other.removedBefore, removedBefore) &&
      other.width == width &&
      other.numbersRight == numbersRight &&
      other.fontSize == fontSize &&
      other.startLine == startLine &&
      other.color == color &&
      other.activeColor == activeColor;

  @override
  int get hashCode => Object.hash(
    width,
    numbersRight,
    fontSize,
    startLine,
    color,
    activeColor,
    marks.length,
    removedBefore.length,
  );
}

/// Edits code in place with `re_editor` (Slides 07 §3.5): the same font,
/// size, line height and palette as the static `CodeView`/code element
/// rendering, tokens colored by the shared `wonky_code` tokenizer, ligatures
/// off, a fixed gutter and an optional baseline correction ([baselineInRow])
/// so entering and leaving edit mode doesn't move the text.
///
/// Keys are re_editor's (aligned with Write 04 §15.2): Enter keeps the
/// indentation, Tab / Shift+Tab indent and outdent the touched lines,
/// auto-pairs of `( [ { " ' \``, `Mod+/` toggles line comments (by
/// [language]), `Mod+A` selects all, `Mod+Z` / `Mod+Shift+Z` undo inside the
/// field. `Esc` calls [onExit]. Paste is plain text (`\r\n` normalized).
///
/// [text] is the external value: when it changes to something other than
/// the field's text (undo, a collaborator), the field takes it over.
/// Every edit reports the whole text to [onChanged].
class CodeEditorField extends StatefulWidget {
  /// Creates a field.
  const CodeEditorField({
    super.key,
    required this.text,
    required this.palette,
    this.language = '',
    this.fontFamily = MonoFontMetrics.defaultFamily,
    this.fontSize = 14,
    this.lineHeight = 1.5,
    this.tabSize = 2,
    this.wrap = false,
    this.gutter,
    this.padding = EdgeInsets.zero,
    this.baselineInRow,
    this.readOnly = false,
    this.autofocus = true,
    this.focusNode,
    this.tokenizer,
    this.syncTokenizeLength = 20000,
    this.onChanged,
    this.onExit,
    this.semanticsLabel,
  });

  final String text;
  final SyntaxPalette palette;

  /// Normalized language id ('' = plain text).
  final String language;
  final String fontFamily;

  /// Logical px.
  final double fontSize;

  /// Line height factor (≥ 1; re_editor's minimum).
  final double lineHeight;

  /// Indent unit (spaces).
  final int tabSize;
  final bool wrap;
  final CodeEditorGutter? gutter;

  /// Padding around the code text (right/bottom; the gutter is the left).
  final EdgeInsets padding;

  /// Where the baseline should sit in a row of `fontSize × lineHeight`
  /// (logical px from the row top; `MonoFontMetrics.baselineInRow`): the
  /// field shifts its text so its own baseline lands there. Null = as laid
  /// out by re_editor.
  final double? baselineInRow;
  final bool readOnly;
  final bool autofocus;
  final FocusNode? focusNode;

  /// Tokenizer of the colors (default: the shared cached tokenizer).
  final CodeTokenizer? tokenizer;

  /// Texts up to this many UTF-16 units are tokenized on every edit;
  /// longer ones keep their tokens shifted past the edit and are
  /// tokenized again once typing pauses for [retokenizeDelay] (CD-2).
  final int syncTokenizeLength;

  /// The pause after which a long text is tokenized again.
  static const retokenizeDelay = Duration(milliseconds: 150);
  final ValueChanged<String>? onChanged;

  /// `Esc`.
  final VoidCallback? onExit;
  final String? semanticsLabel;

  /// The line comment prefix of [language] (`Mod+/`), or null.
  static String? commentPrefixOf(String language) => switch (language) {
    'python' ||
    'yaml' ||
    'serverpod' ||
    'bash' ||
    'ruby' ||
    'dockerfile' ||
    'r' ||
    'perl' ||
    'elixir' ||
    'powershell' ||
    'makefile' ||
    'nginx' ||
    'graphql' => '#',
    'sql' || 'lua' || 'haskell' => '--',
    'ini' => ';',
    'erlang' || 'matlab' => '%',
    'clojure' => ';;',
    '' || 'json' || 'markdown' || 'diff' || 'html' || 'xml' || 'css' => null,
    _ => '//',
  };

  @override
  State<CodeEditorField> createState() => CodeEditorFieldState();
}

/// The state of a [CodeEditorField] (tests read [controller]).
class CodeEditorFieldState extends State<CodeEditorField> {
  late CodeLineEditingController controller;
  late CodeTextStyler _styler;
  String _lastText = '';

  // Token cache of the whole text (re_editor builds spans per line).
  CodeLines? _tokensFor;
  List<CodeToken> _tokens = const [];
  List<int> _lineStarts = const [0];
  String? _tokensText;
  Timer? _retokenize;

  /// Whole-text tokenizations so far (tests).
  @visibleForTesting
  int debugTokenizations = 0;

  static const _noLigatures = [
    FontFeature.disable('calt'),
    FontFeature.disable('liga'),
  ];

  @override
  void initState() {
    super.initState();
    _styler = CodeTextStyler(widget.palette, tabSize: widget.tabSize);
    _lastText = widget.text.replaceAll('\r\n', '\n');
    controller = CodeLineEditingController(
      codeLines: CodeLines.fromText(_lastText),
      options: CodeLineOptions(indentSize: widget.tabSize),
      spanBuilder: _span,
    );
    controller.addListener(_onEdit);
  }

  @override
  void didUpdateWidget(CodeEditorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget;
    if (old.palette != widget.palette || old.tabSize != widget.tabSize) {
      _styler = CodeTextStyler(widget.palette, tabSize: widget.tabSize);
      _tokensFor = null;
    }
    if (old.language != widget.language ||
        !identical(old.tokenizer, widget.tokenizer)) {
      _tokensFor = null;
      _tokensText = null;
    }
    final next = widget.text.replaceAll('\r\n', '\n');
    if (next != old.text.replaceAll('\r\n', '\n') && next != controller.text) {
      _lastText = next;
      final sel = controller.selection;
      controller.codeLines = CodeLines.fromText(next);
      final lines = controller.codeLines.length;
      final index = sel.extentIndex.clamp(0, lines - 1);
      controller.selection = CodeLineSelection.collapsed(
        index: index,
        offset: sel.extentOffset.clamp(
          0,
          controller.codeLines[index].text.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _retokenize?.cancel();
    controller.removeListener(_onEdit);
    controller.dispose();
    super.dispose();
  }

  /// The field's text.
  String get text => controller.text;

  /// Puts the caret at ([line], [column]) (0-based) and types [text] there
  /// as the user would (tests, automation).
  void typeAt(int line, int column, String text) {
    final lines = controller.codeLines.length;
    final i = line.clamp(0, lines - 1);
    controller.selection = CodeLineSelection.collapsed(
      index: i,
      offset: column.clamp(0, controller.codeLines[i].text.length),
    );
    controller.replaceSelection(text);
  }

  void _onEdit() {
    final t = controller.text;
    if (t == _lastText) return;
    _lastText = t;
    widget.onChanged?.call(t);
  }

  CodeTokenizer get _tokenizer =>
      widget.tokenizer ?? CachedCodeTokenizer.shared;

  bool get _highlights =>
      widget.language.isNotEmpty && _tokenizer.supports(widget.language);

  void _ensureTokens() {
    final lines = controller.codeLines;
    if (identical(lines, _tokensFor)) return;
    _tokensFor = lines;
    final text = controller.text;
    final starts = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0a) starts.add(i + 1);
    }
    _lineStarts = starts;
    if (!_highlights) {
      _tokens = const [];
      _tokensText = text;
      return;
    }
    final previous = _tokensText;
    if (text.length <= widget.syncTokenizeLength || previous == null) {
      _tokenize(text);
      return;
    }
    // A long text: the old tokens, shifted past the edit (the edited
    // range stays plain), until typing pauses.
    _tokens = shiftTokens(_tokens, previous, text);
    _tokensText = text;
    _retokenize?.cancel();
    _retokenize = Timer(CodeEditorField.retokenizeDelay, _retokenizeNow);
  }

  void _tokenize(String text) {
    _retokenize?.cancel();
    debugTokenizations++;
    _tokens = _tokenizer.tokenize(text, widget.language);
    _tokensText = text;
  }

  void _retokenizeNow() {
    if (!mounted || !_highlights) return;
    _tokenize(controller.text);
    _tokensFor = controller.codeLines;
    // re_editor lays its lines out again (and asks [_span] for new spans)
    // when the selection changes; a round trip through the other caret
    // affinity ends where it started.
    final sel = controller.selection;
    controller.selection = sel.copyWith(
      extentAffinity: sel.extentAffinity == TextAffinity.downstream
          ? TextAffinity.upstream
          : TextAffinity.downstream,
    );
    controller.selection = sel;
  }

  /// [tokens] of [before] moved onto [after] (one edit): tokens before the
  /// changed range stay, tokens after it shift by the length change, and
  /// tokens overlapping it are dropped.
  @visibleForTesting
  static List<CodeToken> shiftTokens(
    List<CodeToken> tokens,
    String before,
    String after,
  ) {
    final n = before.length < after.length ? before.length : after.length;
    var prefix = 0;
    while (prefix < n &&
        before.codeUnitAt(prefix) == after.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < n - prefix &&
        before.codeUnitAt(before.length - 1 - suffix) ==
            after.codeUnitAt(after.length - 1 - suffix)) {
      suffix++;
    }
    final changedEnd = before.length - suffix;
    final delta = after.length - before.length;
    return [
      for (final t in tokens)
        if (t.end <= prefix)
          t
        else if (t.start >= changedEnd)
          CodeToken(t.start + delta, t.end + delta, t.token),
    ];
  }

  TextSpan _span({
    required BuildContext context,
    required int index,
    required CodeLine codeLine,
    required TextSpan textSpan,
    required TextStyle style,
  }) {
    _ensureTokens();
    final base = style.copyWith(
      color: Color(widget.palette.text),
      fontFeatures: _noLigatures,
    );
    final text = codeLine.text;
    if (index >= _lineStarts.length || _tokens.isEmpty) {
      return TextSpan(text: text, style: base);
    }
    final start = _lineStarts[index];
    final end = start + text.length;
    final children = <TextSpan>[];
    var pos = start;
    // Binary search the first token ending after the line start.
    var lo = 0, hi = _tokens.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_tokens[mid].end <= start) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    String slice(int a, int b) => text.substring(
      (a - start).clamp(0, text.length),
      (b - start).clamp(0, text.length),
    );
    for (var t = lo; t < _tokens.length && _tokens[t].start < end; t++) {
      final tk = _tokens[t];
      final s = tk.start < start ? start : tk.start;
      final e = tk.end > end ? end : tk.end;
      if (s > pos) children.add(TextSpan(text: slice(pos, s)));
      if (e > s) {
        final st = _styler.styleFor(tk.token);
        children.add(
          TextSpan(
            text: slice(s, e),
            style: TextStyle(
              color: st.color,
              fontWeight: st.fontWeight,
              fontStyle: st.fontStyle,
            ),
          ),
        );
        pos = e;
      }
    }
    if (pos < end) children.add(TextSpan(text: slice(pos, end)));
    return TextSpan(style: base, children: children);
  }

  /// The baseline re_editor puts in a row (proportional leading over a
  /// forced strut).
  double _ownBaseline() {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      strutStyle: StrutStyle(
        fontFamily: widget.fontFamily,
        fontSize: widget.fontSize,
        height: _height,
        forceStrutHeight: true,
      ),
      text: TextSpan(
        text: '0',
        style: TextStyle(
          fontFamily: widget.fontFamily,
          fontSize: widget.fontSize,
          height: _height,
        ),
      ),
    )..layout();
    final b = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.dispose();
    return b;
  }

  double get _height => widget.lineHeight < 1 ? 1 : widget.lineHeight;

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final gutter = widget.gutter;
    final shift = widget.baselineInRow == null
        ? 0.0
        : widget.baselineInRow! - _ownBaseline();
    final prefix = CodeEditorField.commentPrefixOf(widget.language);
    Widget editor = CodeEditor(
      controller: controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      wordWrap: widget.wrap,
      autocompleteSymbols: true,
      padding: EdgeInsets.fromLTRB(
        0,
        widget.padding.top,
        widget.padding.right,
        widget.padding.bottom,
      ),
      commentFormatter: prefix == null
          ? null
          : DefaultCodeCommentFormatter(singleLinePrefix: prefix),
      style: CodeEditorStyle(
        fontSize: widget.fontSize,
        fontFamily: widget.fontFamily,
        fontHeight: _height,
        textColor: Color(p.text),
        backgroundColor: const Color(0x00000000),
        selectionColor: Color(p.selection),
        highlightColor: Color(p.selection),
        cursorColor: Color(p.caret),
        cursorWidth: (widget.fontSize / 12).clamp(1.5, 4.0),
        cursorLineColor: const Color(0x00000000),
      ),
      indicatorBuilder: gutter == null
          ? null
          : (context, editing, chunks, notifier) => _Gutter(
              gutter: gutter,
              controller: editing,
              notifier: notifier,
              fontFamily: widget.fontFamily,
              codeFontSize: widget.fontSize,
              lineHeight: _height,
            ),
      scrollbarBuilder: (context, child, details) => child,
    );
    editor = Theme(
      data: Theme.of(context).copyWith(
        textSelectionTheme: Theme.of(context).textSelectionTheme.copyWith(
          cursorColor: Color(p.caret),
          selectionColor: Color(p.selection),
        ),
      ),
      child: editor,
    );
    if (shift != 0) {
      editor = Transform.translate(offset: Offset(0, shift), child: editor);
    }
    return Semantics(
      label: widget.semanticsLabel,
      textField: true,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              widget.onExit != null) {
            widget.onExit!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: editor,
      ),
    );
  }
}

class _Gutter extends StatelessWidget {
  const _Gutter({
    required this.gutter,
    required this.controller,
    required this.notifier,
    required this.fontFamily,
    required this.codeFontSize,
    required this.lineHeight,
  });

  final CodeEditorGutter gutter;
  final CodeLineEditingController controller;
  final CodeIndicatorValueNotifier notifier;
  final String fontFamily;
  final double codeFontSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: gutter.width,
    child: CustomPaint(
      painter: _GutterPainter(
        notifier: notifier,
        gutter: gutter,
        fontFamily: fontFamily,
        baseline: _baseline(),
      ),
    ),
  );

  double _baseline() {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      strutStyle: StrutStyle(
        fontFamily: fontFamily,
        fontSize: codeFontSize,
        height: lineHeight,
        forceStrutHeight: true,
      ),
      text: TextSpan(
        text: '0',
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: codeFontSize,
          height: lineHeight,
        ),
      ),
    )..layout();
    final b = painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    painter.dispose();
    return b;
  }
}

class _GutterPainter extends CustomPainter {
  _GutterPainter({
    required this.notifier,
    required this.gutter,
    required this.fontFamily,
    required this.baseline,
  }) : super(repaint: notifier);

  final CodeIndicatorValueNotifier notifier;
  final CodeEditorGutter gutter;
  final String fontFamily;
  final double baseline;

  @override
  void paint(Canvas canvas, Size size) {
    final right = gutter.numbersRight;
    final v = notifier.value;
    if (v == null) return;
    final markWidth = (gutter.fontSize / 5).clamp(2.0, 6.0);
    for (final p in v.paragraphs) {
      final mark = gutter.marks[p.index];
      final h = p.paragraph.preferredLineHeight;
      if (mark != null) {
        canvas.drawRect(
          Rect.fromLTWH(1, p.offset.dy, markWidth, h),
          Paint()
            ..color = mark == CodeGutterMark.added
                ? CodeEditorGutter.addedColor
                : CodeEditorGutter.changedColor,
        );
      }
      if (gutter.removedBefore.contains(p.index)) {
        _removed(canvas, size, p.offset.dy);
      }
      if (gutter.removedBefore.contains(p.index + 1) &&
          identical(p, v.paragraphs.last)) {
        _removed(canvas, size, p.offset.dy + h);
      }
    }
    if (right == null) return;
    for (final p in v.paragraphs) {
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: '${gutter.startLine + p.index}',
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: gutter.fontSize,
            color: p.index == v.focusedIndex
                ? gutter.activeColor
                : gutter.color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      )..layout();
      final b = painter.computeDistanceToActualBaseline(
        TextBaseline.alphabetic,
      );
      painter.paint(
        canvas,
        Offset(right - painter.width, p.offset.dy + baseline - b),
      );
      painter.dispose();
    }
  }

  void _removed(Canvas canvas, Size size, double y) => canvas.drawRect(
    Rect.fromLTWH(0, y - 1, size.width, 2),
    Paint()..color = CodeEditorGutter.removedColor,
  );

  @override
  bool shouldRepaint(_GutterPainter old) =>
      old.notifier != notifier ||
      old.gutter != gutter ||
      old.baseline != baseline;
}
