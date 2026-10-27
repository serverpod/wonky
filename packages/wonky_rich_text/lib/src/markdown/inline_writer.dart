/// [InlineRun]s → inline Markdown with context-aware escaping.
library;

import '../delta_utils.dart';
import '../inline_run.dart';
import 'inline_reader.dart';
import 'wonky_syntax.dart';

/// How emphasis is written.
enum EmphasisStyle {
  /// `**bold**`, `*italic*`, `~~strike~~` (preferred).
  asterisk,

  /// `__bold__`, `_italic_`, `~~strike~~`.
  underscore,

  /// `<strong>`, `<em>`, `<del>` (always round-trips; used when delimiter
  /// flanking rules cannot express the formatting).
  html,
}

/// Context of an inline content line.
enum InlineContext {
  /// Paragraph-like content: paragraphs, quote lines, list items.
  block,

  /// Heading content: no hard breaks (soft breaks become `<br>`), trailing
  /// `#` escaped.
  heading,

  /// Table cell: single line, no soft breaks.
  tableCell,

  /// Image alt text / link-free plain text.
  plain,
}

sealed class _Tok {
  const _Tok();
}

final class _Char extends _Tok {
  const _Char(this.ch);
  final String ch; // one code point (1 or 2 code units)
}

final class _Markup extends _Tok {
  const _Markup(this.s);
  final String s;
}

final class _Break extends _Tok {
  const _Break({required this.trailing});
  final bool trailing; // `<br>` (no content after) vs `\` + newline
}

/// Writes inline Markdown.
abstract final class InlineMarkdownWriter {
  /// Writes [runs] in [context] using [style]. Visual lines (after hard
  /// breaks) are separated by `"\n"`; callers add container prefixes.
  ///
  /// Chips and styled links are written as Wonky directives (Write 11 §4)
  /// in the [MarkdownFlavor.wonky] flavor (the default: table cells and grid
  /// items store them so) and as plain text and plain links in
  /// [MarkdownFlavor.gfm].
  static String write(
    List<InlineRun> runs, {
    InlineContext context = InlineContext.block,
    EmphasisStyle style = EmphasisStyle.asterisk,
    MarkdownFlavor flavor = MarkdownFlavor.wonky,
  }) {
    final wonky = flavor == MarkdownFlavor.wonky;
    final merged = InlineRun.merge([
      for (final r in runs)
        wonky || (!r.chip && r.linkStyle == null)
            ? r
            : r.copyWith(clearLinkStyle: true, chip: false),
    ]);
    final toks = <_Tok>[];
    _writeSequence(merged, toks, style, context);
    _markTrailingBreaks(toks, context);
    return _render(toks, context, wonky: wonky);
  }

  /// Escapes plain [text] (no formatting) for [context].
  static String escapePlain(
    String text, {
    InlineContext context = InlineContext.plain,
    MarkdownFlavor flavor = MarkdownFlavor.wonky,
  }) => write([InlineRun(text)], context: context, flavor: flavor);

  /// A chip or styled link label as the blog reads it: plain text without
  /// `]` (written as `)`) and without line breaks (Write 11 §2.1).
  static String directiveLabel(String text) => text
      .replaceAll(']', ')')
      .replaceAll(softBreak, ' ')
      .replaceAll('\n', ' ');

  /// A styled link URL as the blog reads it (`\(([^)]*)\)`): no `(`, `)`
  /// or whitespace.
  static String directiveUrl(String url) =>
      url.replaceAll('(', '%28').replaceAll(')', '%29').replaceAll(' ', '%20');

  // ---------------------------------------------------------------------
  // Structure

  static Set<String> _marks(InlineRun r) => {
    if (r.bold) 'b',
    if (r.italic) 'i',
    if (r.strike) 's',
  };

  static void _writeSequence(
    List<InlineRun> runs,
    List<_Tok> out,
    EmphasisStyle style,
    InlineContext context,
  ) {
    final active = <String>[];
    var i = 0;
    while (i < runs.length) {
      final r = runs[i];
      if (r.chip) {
        _closeUntil(active, out, style, (_) => false);
        final icon = r.chipIcon == null ? '' : '{icon=${r.chipIcon}}';
        out.add(_Markup(':chip[${directiveLabel(r.text)}]$icon'));
        i++;
        continue;
      }
      if (r.link != null && r.linkStyle != null) {
        _closeUntil(active, out, style, (_) => false);
        final label = StringBuffer();
        var j = i;
        while (j < runs.length &&
            runs[j].link == r.link &&
            runs[j].linkStyle == r.linkStyle &&
            !runs[j].chip) {
          label.write(runs[j].text);
          j++;
        }
        final text = directiveLabel(label.toString());
        final url = directiveUrl(r.link!);
        out.add(
          _Markup(switch (r.linkStyle) {
            'arrow' => ':link[$text]($url)',
            'buttonSecondary' => ':button[$text]($url){variant=secondary}',
            _ => ':button[$text]($url)',
          }),
        );
        i = j;
        continue;
      }
      if (r.link != null) {
        // Link group: consecutive runs with the same link + mention.
        var j = i;
        while (j < runs.length &&
            runs[j].link == r.link &&
            runs[j].linkStyle == null &&
            !runs[j].chip &&
            runs[j].mentionUserUuid == r.mentionUserUuid) {
          j++;
        }
        final group = runs.sublist(i, j);
        final common = group.map(_marks).reduce((a, b) => a.intersection(b));
        // Close marks not common to the whole group.
        _closeUntil(active, out, style, (m) => common.contains(m));
        final outer = active.toSet();
        out.add(const _Markup('['));
        _writeSequence(
          [
            for (final g in group)
              InlineRun(
                g.text,
                bold: g.bold && !outer.contains('b'),
                italic: g.italic && !outer.contains('i'),
                strike: g.strike && !outer.contains('s'),
                code: g.code,
              ),
          ],
          out,
          style,
          context,
        );
        out.add(
          _Markup(
            '](${_destination(r.link!)}${_mentionTitle(r.mentionUserUuid)})',
          ),
        );
        i = j;
        continue;
      }
      final want = _marks(r);
      _closeUntil(active, out, style, want.contains);
      // Open missing marks, longest-lasting first (outermost).
      final missing = want.where((m) => !active.contains(m)).toList()
        ..sort((a, b) => _extent(runs, i, b).compareTo(_extent(runs, i, a)));
      for (final m in missing) {
        out.add(_Markup(_open(m, style)));
        active.add(m);
      }
      if (r.code) {
        _codeSpan(r.text, out, context);
      } else {
        _text(r.text, out);
      }
      i++;
    }
    _closeUntil(active, out, style, (_) => false);
  }

  /// Closes marks from the top of [active] down to (and including) the
  /// lowest mark that [keep] rejects.
  static void _closeUntil(
    List<String> active,
    List<_Tok> out,
    EmphasisStyle style,
    bool Function(String) keep,
  ) {
    var lowest = active.length;
    for (var k = 0; k < active.length; k++) {
      if (!keep(active[k])) {
        lowest = k;
        break;
      }
    }
    while (active.length > lowest) {
      out.add(_Markup(_close(active.removeLast(), style)));
    }
  }

  static int _extent(List<InlineRun> runs, int from, String mark) {
    var n = 0;
    for (var k = from; k < runs.length; k++) {
      if (runs[k].link != null || !_marks(runs[k]).contains(mark)) break;
      n += runs[k].text.length;
    }
    return n;
  }

  static String _open(String mark, EmphasisStyle style) =>
      switch ((mark, style)) {
        ('b', EmphasisStyle.asterisk) => '**',
        ('b', EmphasisStyle.underscore) => '__',
        ('b', EmphasisStyle.html) => '<strong>',
        ('i', EmphasisStyle.asterisk) => '*',
        ('i', EmphasisStyle.underscore) => '_',
        ('i', EmphasisStyle.html) => '<em>',
        ('s', EmphasisStyle.html) => '<del>',
        _ => '~~',
      };

  static String _close(String mark, EmphasisStyle style) =>
      switch ((mark, style)) {
        ('b', EmphasisStyle.html) => '</strong>',
        ('i', EmphasisStyle.html) => '</em>',
        ('s', EmphasisStyle.html) => '</del>',
        _ => _open(mark, style),
      };

  static void _text(String text, List<_Tok> out) {
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == softBreak) {
        out.add(const _Break(trailing: false));
      } else {
        out.add(_Char(ch));
      }
    }
  }

  static void _codeSpan(String text, List<_Tok> out, InlineContext context) {
    var longest = 0;
    var run = 0;
    final counts = <int>{};
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x60) {
        run++;
        if (run > longest) longest = run;
      } else {
        if (run > 0) counts.add(run);
        run = 0;
      }
    }
    if (run > 0) counts.add(run);
    var fence = 1;
    while (counts.contains(fence)) {
      fence++;
    }
    final ticks = '`' * fence;
    final allSpaces = text.trim().isEmpty && !text.contains(RegExp(r'[^ ]'));
    final pad =
        text.startsWith('`') ||
        text.endsWith('`') ||
        (!allSpaces && text.startsWith(' ') && text.endsWith(' '));
    out.add(_Markup('$ticks${pad ? ' ' : ''}$text${pad ? ' ' : ''}$ticks'));
  }

  static String _destination(String url) {
    var u = url.replaceAllMapped(
      RegExp(r'&(?=#?[A-Za-z0-9]+;)'),
      (_) => '&amp;',
    );
    if (u.contains('(') || u.contains(')') || u.contains(' ')) u = '<$u>';
    return u;
  }

  static String _mentionTitle(String? uuid) =>
      uuid == null ? '' : ' "$mentionTitlePrefix${uuid.replaceAll('"', '')}"';

  /// A soft break renders as `\` + newline only when text follows it
  /// somewhere later in the content (a hard break at the end of a block is
  /// not a hard break in CommonMark); otherwise, and always in headings and
  /// cells, it renders as `<br>`.
  static void _markTrailingBreaks(List<_Tok> toks, InlineContext context) {
    var textAfter = false;
    for (var i = toks.length - 1; i >= 0; i--) {
      final t = toks[i];
      if (t is _Break) {
        toks[i] = _Break(
          trailing: !textAfter || context != InlineContext.block,
        );
      } else if (t is _Char ||
          (t is _Markup &&
              (t.s.startsWith('`') || t.s == '[' || t.s.startsWith(':')))) {
        textAfter = true;
      }
    }
  }

  // ---------------------------------------------------------------------
  // Rendering with escaping

  static final _entityLike = RegExp(r'^&#?[A-Za-z0-9]+;');
  static final _ws = RegExp(r'\s', unicode: true);
  static final _asciiAlnum = RegExp('[A-Za-z0-9]');
  static final _alnum = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static String _render(
    List<_Tok> toks,
    InlineContext context, {
    required bool wonky,
  }) {
    final b = StringBuffer();
    // Split into visual lines at hard breaks.
    var lineStart = 0;
    for (var i = 0; i <= toks.length; i++) {
      final isEnd = i == toks.length;
      final t = isEnd ? null : toks[i];
      if (!isEnd && !(t is _Break && !t.trailing)) continue;
      _renderLine(toks, lineStart, i, b, context, wonky: wonky);
      if (!isEnd) b.write('\\\n');
      lineStart = i + 1;
    }
    return b.toString();
  }

  static String? _outChar(_Tok t, {required bool first}) => switch (t) {
    _Char(:final ch) => ch,
    _Markup(:final s) => first ? s[0] : s[s.length - 1],
    _Break() => '<',
  };

  static void _renderLine(
    List<_Tok> toks,
    int from,
    int to,
    StringBuffer b,
    InlineContext context, {
    required bool wonky,
  }) {
    // Digit-list rule: a line starting with 1–9 digits then "." or ")".
    var escapeIndex = -1;
    if (from < to && toks[from] is _Char) {
      var k = from;
      while (k < to &&
          k - from < 10 &&
          toks[k] is _Char &&
          RegExp(r'^\d$').hasMatch((toks[k] as _Char).ch)) {
        k++;
      }
      if (k > from && k < to && toks[k] is _Char) {
        final ch = (toks[k] as _Char).ch;
        if (ch == '.' || ch == ')') escapeIndex = k;
      }
    }
    // Trailing `#` in headings (closing sequence).
    var hashIndex = -1;
    if (context == InlineContext.heading &&
        to > from &&
        toks[to - 1] is _Char &&
        (toks[to - 1] as _Char).ch == '#') {
      hashIndex = to - 1;
    }
    String? prevOut;
    var recent = '';
    for (var i = from; i < to; i++) {
      final t = toks[i];
      final nextOut = i + 1 < to ? _outChar(toks[i + 1], first: true) : null;
      switch (t) {
        case _Markup(:final s):
          b.write(s);
          prevOut = s[s.length - 1];
          recent = '';
        case _Break():
          b.write('<br>');
          prevOut = '>';
          recent = '';
        case _Char(:final ch):
          final atStart = i == from;
          final atEnd = i == to - 1;
          final escaped = _escapeChar(
            ch,
            prev: prevOut,
            next: nextOut,
            atLineStart: atStart,
            atLineEnd: atEnd,
            forceEscape: i == escapeIndex || i == hashIndex,
            rest: i + 1 < to ? _restText(toks, i + 1, to) : '',
            recent: recent,
            context: context,
            wonky: wonky,
          );
          // package:markdown does not decode a character reference right
          // after a backtick; an empty HTML comment separates them.
          if (prevOut == '`' && escaped.startsWith('&') && escaped != '&') {
            b.write('<!-- -->');
          }
          b.write(escaped);
          prevOut = ch;
          recent = (recent + ch).length > 4
              ? (recent + ch).substring((recent + ch).length - 4)
              : recent + ch;
      }
    }
  }

  static String _restText(List<_Tok> toks, int from, int to) {
    final b = StringBuffer();
    for (var i = from; i < to && b.length < 40; i++) {
      final t = toks[i];
      if (t is _Char) {
        b.write(t.ch);
      } else {
        break;
      }
    }
    return b.toString();
  }

  static String _entity(String ch) => '&#${ch.runes.first};';

  static String _escapeChar(
    String ch, {
    required String? prev,
    required String? next,
    required bool atLineStart,
    required bool atLineEnd,
    required bool forceEscape,
    required String rest,
    required String recent,
    required InlineContext context,
    required bool wonky,
  }) {
    if ((atLineStart || atLineEnd) && _ws.hasMatch(ch)) return _entity(ch);
    if (forceEscape) return '\\$ch';
    switch (ch) {
      case '`':
        // `\`` directly before a code span confuses package:markdown.
        return '&#96;';
      case r'\' || '[' || ']' || '|' || '~':
        return '\\$ch';
      case '*':
        final spaced =
            prev != null &&
            next != null &&
            _ws.hasMatch(prev) &&
            _ws.hasMatch(next);
        return spaced && !atLineStart ? ch : '\\$ch';
      case '_':
        final intraword =
            prev != null &&
            next != null &&
            _asciiAlnum.hasMatch(prev) &&
            _asciiAlnum.hasMatch(next);
        return intraword ? ch : '\\$ch';
      case '<':
        return next != null && RegExp(r'[A-Za-z/!?]').hasMatch(next)
            ? '\\<'
            : '<';
      case '>' || '#' || '+' || '-' || '=':
        return atLineStart ? '\\$ch' : ch;
      case '&':
        return _entityLike.hasMatch('&$rest') ? '&amp;' : '&';
      case ':':
        // `://` would become an autolink, a line starting with `::` a
        // Wonky directive (`:::type`, `::youtube`; escaped in both flavors,
        // Write 11 §5.3; `[` is always escaped, so `:chip[` in text never
        // reads as a chip).
        return rest.startsWith('//') || (atLineStart && rest.startsWith(':'))
            ? r'\:'
            : ch;
      case '(':
        // `## (1) Title` is a numbered heading in Wonky Markdown.
        return wonky &&
                atLineStart &&
                context == InlineContext.heading &&
                _stepPrefix.hasMatch(rest)
            ? r'\('
            : ch;
      case '@':
        final emailish =
            prev != null &&
            next != null &&
            _alnumOrDot(prev) &&
            _alnumOrDot(next);
        return emailish ? r'\@' : ch;
      case '.':
        // `www.` would become an extended autolink.
        return recent.toLowerCase().endsWith('www') ? r'\.' : ch;
      case '!':
        // `!` before a link would make it an image.
        return next == '[' ? r'\!' : ch;
    }
    if (atLineStart && ch == '\t') return _entity(ch);
    return ch;
  }

  static final _stepPrefix = RegExp(r'^\d+\)\s');

  static bool _alnumOrDot(String c) =>
      _alnum.hasMatch(c) || c == '.' || c == '_' || c == '-' || c == '+';
}
