import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wonky_code/wonky_code.dart';

import 'code_text_styler.dart';

/// Read-only, syntax-highlighted code (Slides 07 §2.3, Write 04 §15.5):
/// line numbers, soft wrap, highlighted lines and text selection.
///
/// Used by Drive's text/code previews (Drive 02 §6.4) and Slides. Lines are
/// built lazily, so megabyte-sized files scroll smoothly; with bounded
/// height the view scrolls itself (vertically, and horizontally without
/// [wrap]), with unbounded height it lays out every line (no scrolling).
///
/// Code up to [syncHighlightLength] UTF-16 units is tokenized before the
/// first frame; longer code renders plain first and is highlighted right
/// after (only its first [maxHighlightLength] units; the rest stays plain).
class CodeView extends StatefulWidget {
  /// Creates a code view.
  const CodeView({
    super.key,
    required this.code,
    this.language = '',
    this.palette,
    this.textStyle,
    this.lineNumbers = true,
    this.startLine = 1,
    this.wrap = false,
    this.highlightedLines = const {},
    this.selectable = true,
    this.tokenizer = DefaultCodeTokenizer.instance,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.tabSize = 4,
    this.syncHighlightLength = 50000,
    this.maxHighlightLength = 500000,
    this.verticalController,
    this.semanticsLabel,
  });

  /// The code. `\n` and `\r\n` separate lines.
  final String code;

  /// Language id, normalized with `CodeLanguages.normalize` (`''` = plain).
  final String language;

  /// Colors; defaults to `BuiltInPalettes.forBrightness` of the ambient
  /// `Theme` brightness.
  final SyntaxPalette? palette;

  /// Font family, size and line height (merged over
  /// [CodeTextStyler.defaultBaseStyle]); colors come from the palette.
  final TextStyle? textStyle;

  /// Whether to show a line number gutter.
  final bool lineNumbers;

  /// Number of the first line.
  final int startLine;

  /// Soft-wrap long lines instead of scrolling horizontally.
  final bool wrap;

  /// Line numbers (as displayed, see [startLine]) drawn with the palette's
  /// highlight bar and active line number color (search hits, focus lines).
  final Set<int> highlightedLines;

  /// Whether the code text can be selected and copied.
  final bool selectable;

  /// Tokenizer; [DefaultCodeTokenizer] by default.
  final CodeTokenizer tokenizer;

  /// Padding around the code inside the background.
  final EdgeInsets padding;

  /// Columns per tab stop.
  final int tabSize;

  /// Longer code is highlighted after the first frame.
  final int syncHighlightLength;

  /// Only the first this many UTF-16 units are highlighted.
  final int maxHighlightLength;

  /// Optional controller of the vertical scroll position (bounded height).
  final ScrollController? verticalController;

  /// Semantics label of the whole view (e.g. the file name).
  final String? semanticsLabel;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  List<CodeToken> _tokens = const [];
  String? _tokenizedCode;
  String? _tokenizedLanguage;
  CodeTokenizer? _tokenizedWith;
  Timer? _pending;

  late List<String> _lines;

  // Memoized per input (CD-1): rebuilds (a parent notifying, a resize)
  // reuse the line spans, the widest line and the font metrics.
  CodeTextStyler? _styler;
  List<TextSpan> _spans = const [];
  List<CodeToken>? _spansTokens;
  String? _spansCode;
  CodeTextStyler? _spansStyler;
  int _columns = 0;
  String? _columnsOf;
  int? _columnsTab;
  _Metrics? _metrics;
  (TextStyle, TextScaler)? _metricsKey;
  String? _linesOf;

  final ScrollController _ownVertical = ScrollController();
  final ScrollController _horizontal = ScrollController();
  final ScrollController _gutter = ScrollController();

  ScrollController get _vertical => widget.verticalController ?? _ownVertical;

  @override
  void initState() {
    super.initState();
    _vertical.addListener(_syncGutter);
  }

  @override
  void didUpdateWidget(CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.verticalController != widget.verticalController) {
      (oldWidget.verticalController ?? _ownVertical).removeListener(
        _syncGutter,
      );
      _vertical.addListener(_syncGutter);
    }
  }

  @override
  void dispose() {
    _pending?.cancel();
    _vertical.removeListener(_syncGutter);
    _ownVertical.dispose();
    _horizontal.dispose();
    _gutter.dispose();
    super.dispose();
  }

  void _syncGutter() {
    if (!_gutter.hasClients || !_vertical.hasClients) return;
    final offset = _vertical.offset.clamp(
      _gutter.position.minScrollExtent,
      _gutter.position.maxScrollExtent,
    );
    if (_gutter.offset != offset) _gutter.jumpTo(offset);
  }

  List<String> _linesFor(String code) {
    if (!identical(_linesOf, code)) {
      _linesOf = code;
      _lines = [
        for (final line in code.split('\n'))
          line.endsWith('\r') ? line.substring(0, line.length - 1) : line,
      ];
    }
    return _lines;
  }

  /// Tokens of the current code, (re)computed when code, language or
  /// tokenizer change.
  List<CodeToken> _tokensFor() {
    final code = widget.code;
    final language = widget.language;
    if (identical(_tokenizedCode, code) &&
        _tokenizedLanguage == language &&
        identical(_tokenizedWith, widget.tokenizer)) {
      return _tokens;
    }
    _pending?.cancel();
    _tokenizedCode = code;
    _tokenizedLanguage = language;
    _tokenizedWith = widget.tokenizer;
    if (code.length <= widget.syncHighlightLength) {
      _tokens = widget.tokenizer.tokenize(code, language);
    } else {
      _tokens = const [];
      final tokenizer = widget.tokenizer;
      _pending = Timer(Duration.zero, () {
        if (!mounted || !identical(widget.code, code)) return;
        var prefix = code;
        if (prefix.length > widget.maxHighlightLength) {
          final cut = prefix.lastIndexOf('\n', widget.maxHighlightLength);
          prefix = prefix.substring(
            0,
            cut > 0 ? cut : widget.maxHighlightLength,
          );
        }
        setState(() => _tokens = tokenizer.tokenize(prefix, language));
      });
    }
    return _tokens;
  }

  CodeTextStyler _stylerFor(SyntaxPalette palette) {
    final s = _styler;
    if (s != null &&
        s.palette == palette &&
        s.tabSize == widget.tabSize &&
        s.baseStyle ==
            CodeTextStyler.defaultBaseStyle.merge(widget.textStyle)) {
      return s;
    }
    return _styler = CodeTextStyler(
      palette,
      baseStyle: widget.textStyle,
      tabSize: widget.tabSize,
    );
  }

  List<TextSpan> _spansFor(CodeTextStyler styler, List<CodeToken> tokens) {
    if (!identical(_spansCode, widget.code) ||
        !identical(_spansTokens, tokens) ||
        !identical(_spansStyler, styler)) {
      _spansCode = widget.code;
      _spansTokens = tokens;
      _spansStyler = styler;
      _spans = styler.lineSpans(widget.code, tokens);
    }
    return _spans;
  }

  int _columnsFor(CodeTextStyler styler, List<String> lines) {
    if (!identical(_columnsOf, widget.code) || _columnsTab != styler.tabSize) {
      _columnsOf = widget.code;
      _columnsTab = styler.tabSize;
      var columns = 0;
      for (final line in lines) {
        columns = math.max(columns, styler.columnsOf(line));
      }
      _columns = columns;
    }
    return _columns;
  }

  _Metrics _metricsFor(CodeTextStyler styler, TextScaler scaler) {
    final key = (styler.baseStyle, scaler);
    final hit = _metrics;
    if (hit != null && _metricsKey == key) return hit;
    _metricsKey = key;
    return _metrics = _Metrics.of(styler, scaler);
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        widget.palette ??
        BuiltInPalettes.forBrightness(
          Theme.of(context).brightness == Brightness.dark
              ? PaletteBrightness.dark
              : PaletteBrightness.light,
        );
    final styler = _stylerFor(palette);
    final lines = _linesFor(widget.code);
    final spans = _spansFor(styler, _tokensFor());
    final metrics = _metricsFor(styler, MediaQuery.textScalerOf(context));
    final lastNumber = widget.startLine + lines.length - 1;
    final gutterWidth = widget.lineNumbers
        ? (lastNumber.abs().toString().length + 2) * metrics.charWidth
        : 0.0;

    Widget gutterCell(int index) {
      final number = widget.startLine + index;
      final active = widget.highlightedLines.contains(number);
      return Container(
        alignment: Alignment.topRight,
        padding: EdgeInsets.only(right: metrics.charWidth),
        decoration: active
            ? BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(palette.highlightBar),
                    width: 3,
                  ),
                ),
              )
            : null,
        child: Text(
          '$number',
          maxLines: 1,
          softWrap: false,
          style: styler.plainStyle.copyWith(
            color: Color(
              active ? palette.lineNumberActive : palette.lineNumber,
            ),
          ),
        ),
      );
    }

    Widget lineText(int index) => Text.rich(
      spans[index],
      softWrap: widget.wrap,
      maxLines: widget.wrap ? null : 1,
      overflow: TextOverflow.visible,
    );

    Widget lineBackground(int index, Widget child) {
      if (!widget.highlightedLines.contains(widget.startLine + index)) {
        return child;
      }
      return ColoredBox(
        color: Color(palette.highlightBar).withValues(alpha: 0.12),
        child: child,
      );
    }

    Widget selectableArea(Widget child) =>
        widget.selectable ? SelectionArea(child: child) : child;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        final vPad = EdgeInsets.only(
          top: widget.padding.top,
          bottom: widget.padding.bottom,
        );

        if (widget.wrap || !bounded) {
          // One list (or column): each row carries its own line number, so
          // wrapped lines keep their number at the top.
          Widget row(int i) => lineBackground(
            i,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.lineNumbers)
                  SelectionContainer.disabled(
                    child: SizedBox(width: gutterWidth, child: gutterCell(i)),
                  ),
                if (widget.wrap) Expanded(child: lineText(i)) else lineText(i),
              ],
            ),
          );
          final rowPadding = EdgeInsets.only(
            left: widget.lineNumbers ? 0 : widget.padding.left,
            right: widget.padding.right,
          );
          if (!bounded) {
            final column = Padding(
              padding: vPad.add(rowPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [for (var i = 0; i < lines.length; i++) row(i)],
              ),
            );
            return selectableArea(
              widget.wrap
                  ? column
                  : SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      child: column,
                    ),
            );
          }
          return Scrollbar(
            controller: _vertical,
            child: selectableArea(
              ListView.builder(
                controller: _vertical,
                padding: vPad.add(rowPadding),
                itemCount: lines.length,
                itemBuilder: (context, i) => row(i),
              ),
            ),
          );
        }

        // No wrap, bounded height: a fixed gutter beside a horizontally
        // scrolling code list with fixed line extents (fast for big files).
        final columns = _columnsFor(styler, lines);
        final contentWidth =
            columns * metrics.charWidth + widget.padding.right + 1;
        final codeList = ListView.builder(
          controller: _vertical,
          padding: vPad,
          itemExtent: metrics.lineHeight,
          itemCount: lines.length,
          itemBuilder: (context, i) => lineBackground(
            i,
            Align(alignment: Alignment.centerLeft, child: lineText(i)),
          ),
        );
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.lineNumbers)
              SizedBox(
                width: gutterWidth,
                child: ListView.builder(
                  controller: _gutter,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: vPad,
                  itemExtent: metrics.lineHeight,
                  itemCount: lines.length,
                  itemBuilder: (context, i) => lineBackground(i, gutterCell(i)),
                ),
              )
            else
              SizedBox(width: widget.padding.left),
            Expanded(
              child: Scrollbar(
                controller: _vertical,
                notificationPredicate: (n) => n.depth == 1,
                child: Scrollbar(
                  controller: _horizontal,
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(contentWidth, 1),
                      height: constraints.maxHeight,
                      child: selectableArea(codeList),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    return Semantics(
      container: true,
      label: widget.semanticsLabel,
      child: ColoredBox(
        color: Color(palette.background),
        child: DefaultTextStyle.merge(style: styler.plainStyle, child: content),
      ),
    );
  }
}

/// Measured line height and column width of the mono font.
class _Metrics {
  const _Metrics(this.lineHeight, this.charWidth);

  factory _Metrics.of(CodeTextStyler styler, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(text: '0000000000', style: styler.plainStyle),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final metrics = _Metrics(painter.height, painter.width / 10);
    painter.dispose();
    return metrics;
  }

  final double lineHeight;
  final double charWidth;
}
