/// RTF export (07 §5.7, 06 §7.1).
library;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../delta/embeds.dart';
import 'package:wonky_fonts/wonky_fonts.dart';
import '../../import/import_support.dart' show MonospaceFonts;
import '../../ir/doc_tree.dart';
import '../../layout/page_setup.dart';
import '../../markdown/inline_reader.dart' show mentionTitlePrefix;
import '../../theme/model/style_enums.dart';
import '../../theme/model/values.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../../theme/resolve/theme_resolver.dart';
import '../export_api.dart';
import '../markdown_file_exporter.dart';
import '../office/office_support.dart';

/// Rich Text Format exporter: a hand-written RTF 1.9 writer that renders
/// the document through its resolved theme.
///
/// Output: `{\rtf1\ansi\ansicpg1252\deff0\uc1`, a font table (theme body,
/// heading and mono families), a color table (theme colors in first-use
/// order), a stylesheet (`Normal`, `heading 1…6` with `\outlinelevelN
/// \keepn`, `Quote`, `Code Block`, `Caption`, `List Paragraph`, `Horizontal
/// Line`, `Table Heading`, `Table Contents`, `header`, `footer` and the
/// character styles `Inline Code` and `Hyperlink`), a list table (bullets,
/// numbers and tasks with 9 levels each; every ordered run restarts through
/// its own `\lsN` override), `\info` (title, author, `meta.modifiedAt`),
/// page geometry and header/footer groups with `PAGE`/`NUMPAGES` fields,
/// then the body. Paragraph spacing is collapsed like in the PDF (space
/// between two blocks = max(after, before)). Text is ASCII-escaped
/// (`\uN?`, surrogate pairs as two `\u`), the output is deterministic.
///
/// RTF has no page color: the light variant is always used (a dark request
/// adds a `variant_unsupported` warning).
final class RtfExporter implements DocumentExporter<RtfExportOptions> {
  /// Creates the exporter.
  const RtfExporter();

  @override
  ExportFormat get format => ExportFormat.rtf;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    RtfExportOptions options,
  ) async {
    input.cancel?.throwIfCancelled();
    final tree = exportTree(input, options);
    final warnings = <ExportWarning>[];
    if (input.variant == ThemeVariant.dark) {
      warnings.add(
        const ExportWarning(
          'variant_unsupported',
          'RTF has no page color; the light theme colors were used',
        ),
      );
    }
    final theme = ThemeResolver.instance.resolve(
      input.theme,
      ThemeVariant.light,
    );
    final images = await resolveOfficeImages(input, tree, warnings);
    input.cancel?.throwIfCancelled();
    input.progress?.call(ExportPhase.packaging, 0);
    final rtf = _RtfWriter(input, tree, theme, images).write();
    input.progress?.call(ExportPhase.packaging, 1);
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        format.extension,
      ),
      mimeType: format.mimeType,
      bytes: Uint8List.fromList(ascii.encode(rtf)),
      warnings: warnings,
    );
  }
}

// ---------------------------------------------------------------------------
// Low-level RTF output

/// An RTF fragment builder that inserts control-word delimiters and
/// escapes text to 7-bit ASCII.
final class _Rtf {
  final _b = StringBuffer();
  var _delim = false;

  /// A control word with an optional parameter.
  void cw(String word, [int? param]) {
    _b
      ..write(r'\')
      ..write(word);
    if (param != null) _b.write(param);
    _delim = true;
  }

  /// A finished fragment (see [done]).
  void add(String fragment) {
    if (fragment.isEmpty) return;
    _b.write(fragment);
    _delim = false;
  }

  void open() => add('{');

  void close() => add('}');

  /// A line break in the file (ignored by readers).
  void nl() {
    _b.write('\n');
    _delim = false;
  }

  /// Escaped text: `\ { }` escaped, tabs as `\tab`, U+2028/LF as `\line`,
  /// U+00A0 as `\~`, other non-ASCII as `\uN?` (signed 16-bit).
  void text(String s) {
    for (var i = 0; i < s.length; i++) {
      final u = s.codeUnitAt(i);
      if (u == 0x09) {
        cw('tab');
      } else if (u == 0x2028 || u == 0x0A) {
        cw('line');
      } else if (u == 0xA0) {
        add(r'\~');
      } else if (u < 0x20) {
        continue;
      } else if (u < 0x7F) {
        if (_delim) _b.write(' ');
        _delim = false;
        if (u == 0x5C || u == 0x7B || u == 0x7D) _b.write(r'\');
        _b.writeCharCode(u);
      } else {
        _b
          ..write(r'\u')
          ..write(u > 0x7FFF ? u - 0x10000 : u)
          ..write('?');
        _delim = false;
      }
    }
  }

  /// The fragment, terminated so that any text may follow.
  String done() => _delim ? '$_b ' : _b.toString();

  bool get isEmpty => _b.isEmpty;
}

/// Escaped text as a finished fragment.
String _escaped(String s) => (_Rtf()..text(s)).done();

// ---------------------------------------------------------------------------
// Document model of the writer

/// A paragraph or a table with the spacing it wants around it.
final class _Unit {
  _Unit.para(this.props, this.content, {this.before = 0, this.after = 0})
    : table = null;

  _Unit.table(this.table, {this.before = 0, this.after = 0})
    : props = '',
      content = '';

  /// Paragraph properties (style, indents, borders, character defaults).
  final String props;

  /// Paragraph content.
  final String content;

  /// A complete table (rows), or `null` for a paragraph.
  final String? table;

  final double before;
  final double after;
}

/// Style ids.
abstract final class _S {
  static const normal = 0;
  static const quote = 7;
  static const code = 8;
  static const caption = 9;
  static const listParagraph = 10;
  static const rule = 11;
  static const tableHeading = 12;
  static const tableContents = 13;
  static const header = 14;
  static const footer = 15;
  static const inlineCode = 16;
  static const hyperlink = 17;
}

/// List ids.
abstract final class _L {
  static const bullets = 1;
  static const numbers = 2;
  static const tasks = 3;
}

final class _RtfWriter {
  _RtfWriter(this.input, this.tree, this.theme, this.images)
    : contentWidth = contentWidthPt(input, theme),
      contentHeight = contentHeightPt(input, theme);

  final ExportInput input;
  final DocTree tree;
  final ResolvedWriteTheme theme;
  final Map<String, OfficeImage> images;
  final double contentWidth;
  final double contentHeight;

  final _fonts = <String>[];
  final _colors = <int>[];

  /// Overrides: index + 1 = `\ls` number; value = (list id, restart).
  final _overrides = <(int, bool)>[];
  int? _bulletLs;
  int? _taskLs;

  // -------------------------------------------------------------------------
  // Tables of fonts and colors

  int _font(String family) {
    final i = _fonts.indexOf(family);
    if (i >= 0) return i;
    _fonts.add(family);
    return _fonts.length - 1;
  }

  int _color(int argb) {
    final c = flattenAlpha(argb, background: theme.page.paperColor) & 0xFFFFFF;
    final i = _colors.indexOf(c);
    if (i >= 0) return i + 1;
    _colors.add(c);
    return _colors.length;
  }

  static int _tw(double pt) => OfficeUnits.twips(pt);

  static int _hp(double pt) => math.max(2, OfficeUnits.halfPoints(pt));

  // -------------------------------------------------------------------------
  // Property fragments

  /// Character properties of [s] (after `\plain`).
  String _chars(ResolvedTextStyle s, {int? color, double? size}) {
    final r = _Rtf()
      ..cw('f', _font(s.fontFamily))
      ..cw('fs', _hp(size ?? s.fontSize));
    if (s.fontWeight >= 600) r.cw('b');
    if (s.italic) r.cw('i');
    r.cw('cf', _color(color ?? s.color));
    if (s.caseTransform == CaseTransform.uppercase) r.cw('caps');
    if (s.caseTransform == CaseTransform.smallCaps) r.cw('scaps');
    final spacing = _tw(s.letterSpacing);
    if (spacing != 0) r.cw('expndtw', spacing);
    return r.done();
  }

  static String _align(ThemeAlign a) => switch (a) {
    ThemeAlign.left => r'\ql',
    ThemeAlign.center => r'\qc',
    ThemeAlign.right => r'\qr',
    ThemeAlign.justify => r'\qj',
  };

  static String _lineSpacing(ResolvedTextStyle s) =>
      '\\sl${(s.lineHeight * 240).round().clamp(120, 2400)}\\slmult1';

  static String _borderStyle(LineStyle s) => switch (s) {
    LineStyle.dashed => r'\brdrdash',
    LineStyle.dotted => r'\brdrdot',
    LineStyle.doubleLine => r'\brdrdb',
    LineStyle.solid || LineStyle.none => r'\brdrs',
  };

  /// A border definition after a side word (`\brdrb`, `\clbrdrt`, …).
  String _border(BorderPt b, {double space = 0}) {
    final sp = _tw(space);
    return '${_borderStyle(b.style)}\\brdrw${_tw(b.width).clamp(1, 75)}'
        '${sp > 0 ? '\\brsp${sp.clamp(0, 600)}' : ''}'
        '\\brdrcf${_color(b.color)}';
  }

  String _boxBorders(ResolvedBox box) {
    final b = box.border;
    final out = StringBuffer();
    if (b.top.isVisible) {
      out.write('\\brdrt${_border(b.top, space: box.padding.top)}');
    }
    if (b.left.isVisible) {
      out.write('\\brdrl${_border(b.left, space: box.padding.left)}');
    }
    if (b.bottom.isVisible) {
      out.write('\\brdrb${_border(b.bottom, space: box.padding.bottom)}');
    }
    if (b.right.isVisible) {
      out.write('\\brdrr${_border(b.right, space: box.padding.right)}');
    }
    return out.toString();
  }

  String _shading(int? background) =>
      background == null || (background >>> 24) == 0
      ? ''
      : '\\cbpat${_color(background)}';

  // Paragraph styles: paragraph part (without spacing) and character part.

  String _normalPara() =>
      '${_align(theme.body.box.align)}'
      '${theme.body.firstLineIndent != 0 ? '\\fi${_tw(theme.body.firstLineIndent)}' : ''}'
      '${_lineSpacing(theme.body.style)}';

  String _headingPara(ResolvedHeading h) {
    final b = h.box;
    final border = h.borderBottom;
    return '${_align(b.align)}'
        '${b.padding.left > 0 ? '\\li${_tw(b.padding.left)}' : ''}'
        '${b.padding.right > 0 ? '\\ri${_tw(b.padding.right)}' : ''}'
        '\\keepn\\outlinelevel${h.level - 1}${_lineSpacing(h.style)}'
        '${border != null && border.isVisible ? '\\brdrb${_border(border, space: h.borderBottomGap)}' : ''}'
        '${_shading(b.background)}';
  }

  String _quotePara() {
    final q = theme.blockquote;
    final bar = q.bar.isVisible ? q.bar.width : 0.0;
    final left = q.box.padding.left + bar;
    return '${_align(q.box.align)}'
        '${left > 0 ? '\\li${_tw(left)}' : ''}'
        '${q.box.padding.right > 0 ? '\\ri${_tw(q.box.padding.right)}' : ''}'
        '${_lineSpacing(q.style)}'
        '${q.bar.isVisible ? '\\brdrl${_border(q.bar, space: q.box.padding.left)}' : ''}'
        '${_shading(q.box.background)}';
  }

  String _codePara() {
    final c = theme.codeBlock;
    final box = c.box;
    final borders = _boxBorders(box);
    return '\\ql'
        '${box.padding.left > 0 ? '\\li${_tw(box.padding.left)}' : ''}'
        '${box.padding.right > 0 ? '\\ri${_tw(box.padding.right)}' : ''}'
        '${_lineSpacing(c.style)}$borders${_shading(box.background)}';
  }

  String _captionPara() =>
      '${_align(theme.image.caption.align)}'
      '${_lineSpacing(theme.image.caption.style)}';

  String _rulePara() {
    final r = theme.rule;
    if (r.style == RuleStyle.ornament) {
      return '\\qc${_lineSpacing(r.ornamentStyle)}';
    }
    final width = r.width.resolve(contentWidth);
    final inset = math.max(0.0, (contentWidth - width) / 2);
    final line = BorderPt(
      width: r.style == RuleStyle.doubleLine ? r.thickness / 3 : r.thickness,
      style: switch (r.style) {
        RuleStyle.dashed => LineStyle.dashed,
        RuleStyle.dotted => LineStyle.dotted,
        RuleStyle.doubleLine => LineStyle.doubleLine,
        _ => LineStyle.solid,
      },
      color: r.color,
    );
    return '\\ql${inset > 0 ? '\\li${_tw(inset)}\\ri${_tw(inset)}' : ''}'
        '\\sl-20\\slmult0\\brdrb${_border(line)}';
  }

  String _ruleChars() {
    final r = theme.rule;
    if (r.style == RuleStyle.ornament) {
      return _chars(r.ornamentStyle, color: r.color);
    }
    return '\\f${_font(theme.body.style.fontFamily)}\\fs2 ';
  }

  String _slotPara() {
    final center = _tw(contentWidth / 2);
    final right = _tw(contentWidth);
    return '\\ql\\tqc\\tx$center\\tqr\\tx$right';
  }

  String _inlineCodeChars(double baseSize, {bool style = true}) {
    final ic = theme.inlineCode;
    final r = _Rtf();
    if (style) r.cw('cs', _S.inlineCode);
    r
      ..cw('f', _font(ic.fontFamily))
      ..cw('fs', _hp(baseSize * ic.sizeRatio));
    if (ic.fontWeight >= 600) r.cw('b');
    if (ic.italic) r.cw('i');
    r.cw('cf', _color(ic.color));
    if (ic.background != null && (ic.background! >>> 24) != 0) {
      r
        ..cw('chshdng', 0)
        ..cw('chcbpat', _color(ic.background!));
    }
    return r.done();
  }

  String _hyperlinkChars({bool style = true}) {
    final r = _Rtf();
    if (style) r.cw('cs', _S.hyperlink);
    r.cw('cf', _color(theme.link.color));
    if (theme.link.underline == LinkUnderline.always) r.cw('ul');
    return r.done();
  }

  // -------------------------------------------------------------------------
  // Inline content

  /// Writes [runs] on a paragraph whose character defaults are [base].
  void _runs(
    _Rtf out,
    List<InlineRun> runs,
    ResolvedTextStyle base, {
    int? color,
    bool strikeAll = false,
  }) {
    var i = 0;
    while (i < runs.length) {
      final r = runs[i];
      if (r.link == null) {
        _run(out, r, base, color: color, strikeAll: strikeAll);
        i++;
        continue;
      }
      var j = i;
      while (j < runs.length &&
          runs[j].link == r.link &&
          runs[j].mentionUserUuid == r.mentionUserUuid) {
        j++;
      }
      final mention = r.mentionUserUuid != null;
      final url = mention ? r.link! : input.links.resolve(r.link!);
      final instr = StringBuffer('HYPERLINK "${url.replaceAll('"', '%22')}"');
      if (mention) {
        instr.write(
          ' \\o "$mentionTitlePrefix${r.mentionUserUuid!.replaceAll('"', '')}"',
        );
      }
      out
        ..add(r'{\field{\*\fldinst ')
        ..add(_escaped(instr.toString()))
        ..add(r'}{\fldrslt {');
      if (mention) {
        final m = theme.mention;
        final c = _Rtf()..cw('cf', _color(m.color));
        if (m.background != null && (m.background! >>> 24) != 0) {
          c
            ..cw('chshdng', 0)
            ..cw('chcbpat', _color(m.background!));
        }
        out.add(c.done());
      } else {
        out.add(_hyperlinkChars());
      }
      for (var k = i; k < j; k++) {
        _run(out, runs[k], base, link: true, strikeAll: strikeAll);
      }
      out.add('}}}');
      i = j;
    }
  }

  void _run(
    _Rtf out,
    InlineRun r,
    ResolvedTextStyle base, {
    int? color,
    bool link = false,
    bool strikeAll = false,
  }) {
    // Upper case and small caps are character properties (\caps,
    // \scaps); the text keeps its case.
    final text = switch (base.caseTransform) {
      CaseTransform.lowercase ||
      CaseTransform.capitalize => applyCase(r.text, base.caseTransform),
      _ => r.text,
    };
    if (text.isEmpty) return;
    final props = _Rtf();
    if (r.code) {
      props.add(_inlineCodeChars(base.fontSize));
      if (strikeAll) props.cw('strike');
    } else {
      if (r.bold) props.cw('b');
      if (r.italic) props.cw('i');
      if (r.strike || strikeAll) props.cw('strike');
      if (!link) {
        int? c = color;
        if (r.bold && theme.bold.color != null) c = theme.bold.color;
        if (r.italic && theme.italic.color != null) c = theme.italic.color;
        if (r.strike && theme.strike.color != null) c = theme.strike.color;
        if (c != null && c != base.color) props.cw('cf', _color(c));
      }
    }
    if (props.isEmpty) {
      out.text(text);
      return;
    }
    out
      ..open()
      ..add(props.done())
      ..text(text)
      ..close();
  }

  // -------------------------------------------------------------------------
  // Blocks

  List<_Unit> _body() {
    final units = <_Unit>[];
    final labels = headingLabels(tree, theme);
    final blocks = tree.blocks;
    final orderedLs = <int, int>{};
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final prev = i > 0 ? blocks[i - 1] : null;
      final next = i + 1 < blocks.length ? blocks[i + 1] : null;
      if (b is! ListItemBlock || b.kind != ListKindIr.ordered) {
        if (b is! ListItemBlock && b is! TaskBlock) orderedLs.clear();
      }
      switch (b) {
        case ParagraphBlock(:final runs):
          final box = theme.body.box;
          final after = prev is HeadingBlock;
          final o = theme.paragraphAfterHeading;
          final content = _Rtf();
          _runs(content, runs, theme.body.style);
          units.add(
            _Unit.para(
              '\\s${_S.normal}${_normalPara()}${_chars(theme.body.style)}',
              content.done(),
              before: after
                  ? (o.spaceBefore ?? box.spaceBefore)
                  : box.spaceBefore,
              after: after ? (o.spaceAfter ?? box.spaceAfter) : box.spaceAfter,
            ),
          );
        case HeadingBlock(:final level, :final runs):
          final h = theme.heading(level);
          final label = labels[i];
          final content = _Rtf();
          _runs(content, [
            if (label != null) InlineRun(label),
            ...runs,
          ], h.style);
          units.add(
            _Unit.para(
              '\\s$level${_headingPara(h)}${_chars(h.style)}',
              content.done(),
              before: h.box.spaceBefore,
              after: h.box.spaceAfter,
            ),
          );
        case ListItemBlock(:final kind, :final indent, :final ordinal):
          final int ls;
          if (kind == ListKindIr.ordered) {
            orderedLs.removeWhere((level, _) => level > indent);
            final current = orderedLs[indent];
            if (current == null || ordinal == 1) {
              _overrides.add((_L.numbers, true));
              ls = _overrides.length;
              orderedLs[indent] = ls;
            } else {
              ls = current;
            }
          } else {
            ls = _bulletLs ??= _addOverride(_L.bullets);
          }
          units.add(_listUnit(b, ls, prev: prev, next: next));
        case TaskBlock():
          final ls = _taskLs ??= _addOverride(_L.tasks);
          units.add(_listUnit(b, ls, prev: prev, next: next));
        case QuoteBlock(:final lines):
          final q = theme.blockquote;
          for (var l = 0; l < lines.length; l++) {
            final content = _Rtf();
            _runs(content, lines[l], q.style);
            units.add(
              _Unit.para(
                '\\s${_S.quote}${_quotePara()}${_chars(q.style)}',
                content.done(),
                before: l == 0 ? q.box.spaceBefore : 0,
                after: l == lines.length - 1 ? q.box.spaceAfter : 0,
              ),
            );
          }
        case CodeBlock(:final language, :final text):
          units.addAll(_codeUnits(language, text));
        case ImageBlock():
          units.addAll(_imageUnits(b));
        case RuleBlock():
          final r = theme.rule;
          units.add(
            _Unit.para(
              '\\s${_S.rule}${_rulePara()}${_ruleChars()}',
              r.style == RuleStyle.ornament ? _escaped(r.ornament) : '',
              before: r.box.spaceBefore,
              after: r.box.spaceAfter,
            ),
          );
        case TableBlock():
          units.add(_tableUnit(b));
      }
    }
    return units;
  }

  int _addOverride(int listId) {
    _overrides.add((listId, false));
    return _overrides.length;
  }

  _Unit _listUnit(
    DocBlock b,
    int ls, {
    required DocBlock? prev,
    required DocBlock? next,
  }) {
    final l = theme.list;
    final task = b is TaskBlock;
    final indent = switch (b) {
      ListItemBlock(:final indent) => indent,
      TaskBlock(:final indent) => indent,
      _ => 0,
    }.clamp(0, 8);
    final runs = switch (b) {
      ListItemBlock(:final runs) => runs,
      TaskBlock(:final runs) => runs,
      _ => const <InlineRun>[],
    };
    final style = task ? theme.task.style : l.style;
    var (li, fi) = _listIndents(indent);
    // A list inside a quote (Write 02 §1.2): moved right by the quote's
    // indent, with its bar and background.
    var quote = '';
    if (isInQuote(b)) {
      final q = theme.blockquote;
      li += _tw(q.box.padding.left + (q.bar.isVisible ? q.bar.width : 0.0));
      quote =
          '${q.bar.isVisible ? '\\brdrl${_border(q.bar, space: q.box.padding.left)}' : ''}'
          '${_shading(q.box.background)}';
    }
    final content = _Rtf();
    switch (b) {
      case ListItemBlock(:final kind, :final ordinal):
        final ordered = kind == ListKindIr.ordered;
        final marker = ordered
            ? l.numberMarker(indent, ordinal)
            : l.bulletFor(indent);
        final markerChars = _Rtf()
          ..cw('f', _font(style.fontFamily))
          ..cw(
            'fs',
            _hp(ordered ? style.fontSize : style.fontSize * l.bulletScale),
          )
          ..cw('cf', _color(ordered ? l.numberColor : l.bulletColor));
        content
          ..add(r'{\listtext\pard\plain')
          ..add(markerChars.done())
          ..text(marker)
          ..cw('tab')
          ..close();
        _runs(content, runs, style);
      case TaskBlock(:final checked):
        content
          ..text(checked ? '☒' : '☐')
          ..cw('tab');
        final strike = checked && theme.task.checkedStrike;
        _runs(
          content,
          runs,
          style,
          color: checked ? theme.task.checkedColor : null,
          strikeAll: strike,
        );
      default:
        break;
    }
    final first = prev is! ListItemBlock && prev is! TaskBlock;
    final last = next is! ListItemBlock && next is! TaskBlock;
    final box = task ? theme.task.box : l.box;
    return _Unit.para(
      '\\s${_S.listParagraph}\\ql\\fi$fi\\li$li${_lineSpacing(style)}'
      '\\ls$ls\\ilvl$indent$quote${_chars(style)}',
      content.done(),
      before: first ? box.spaceBefore : l.itemSpacing,
      after: last ? math.max(l.itemSpacing, box.spaceAfter) : l.itemSpacing,
    );
  }

  /// `\li` and `\fi` (twips) of list level [level]: the text starts at the
  /// theme indent, the marker hangs one indent step to the left.
  (int, int) _listIndents(int level) {
    final l = theme.list;
    final step = math.max(l.indentPerLevel, 12.0);
    final li = _tw(l.indentPerLevel * level + step);
    return (li, -_tw(step));
  }

  List<_Unit> _codeUnits(String language, String text) {
    final c = theme.codeBlock;
    final lines = highlightedCodeLines(text, language);
    final props = '\\s${_S.code}${_codePara()}${_chars(c.style)}';
    final out = <_Unit>[];
    for (var l = 0; l < lines.length; l++) {
      final content = _Rtf();
      if (l == 0 && language.isNotEmpty) {
        content
          ..add(r'{\*\wonkycodelang ')
          ..text(language)
          ..close();
      }
      for (final piece in lines[l]) {
        final tok = piece.token == null ? null : theme.syntax[piece.token];
        final p = _Rtf();
        if (tok != null) {
          if (tok.color != c.style.color) p.cw('cf', _color(tok.color));
          if (tok.italic && !c.style.italic) p.cw('i');
          final w = tok.fontWeight;
          if (w != null && w >= 600 && c.style.fontWeight < 600) p.cw('b');
        }
        if (p.isEmpty) {
          content.text(piece.text);
        } else {
          content
            ..open()
            ..add(p.done())
            ..text(piece.text)
            ..close();
        }
      }
      out.add(
        _Unit.para(
          props,
          content.done(),
          before: l == 0 ? c.box.spaceBefore : 0,
          after: l == lines.length - 1 ? c.box.spaceAfter : 0,
        ),
      );
    }
    return out;
  }

  List<_Unit> _imageUnits(ImageBlock b) {
    final st = theme.image;
    final align = st.align == ImageAlign.center ? r'\qc' : r'\ql';
    final image = images[b.src];
    final content = _Rtf();
    final caption = b.title?.trim() ?? '';
    if (image == null) {
      content.text(b.alt.isEmpty ? '[Image]' : '[Image: ${b.alt}]');
    } else {
      final maxW = st.maxWidth.resolve(contentWidth);
      final (w, h) = image.fit(maxW, contentHeight);
      content
        ..add(r'{\pict')
        ..add(r'{\*\picprop{\sp{\sn wzDescription}{\sv ')
        ..text(b.alt)
        ..add('}}}')
        ..cw(image.mime == 'image/jpeg' ? 'jpegblip' : 'pngblip')
        ..cw('picw', image.widthPx)
        ..cw('pich', image.heightPx)
        ..cw('picwgoal', _tw(w))
        ..cw('pichgoal', _tw(h))
        ..nl()
        ..add(_hex(image.bytes))
        ..close();
    }
    return [
      _Unit.para(
        '\\s${_S.normal}$align${_chars(theme.body.style)}',
        content.done(),
        before: st.box.spaceBefore,
        after: caption.isEmpty ? st.box.spaceAfter : 0,
      ),
      if (caption.isNotEmpty)
        _Unit.para(
          '\\s${_S.caption}${_captionPara()}${_chars(st.caption.style)}',
          _escaped(caption),
          before: st.caption.gap,
          after: st.box.spaceAfter,
        ),
    ];
  }

  static String _hex(Uint8List bytes) {
    const digits = '0123456789abcdef';
    final b = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      if (i > 0 && i % 64 == 0) b.write('\n');
      final v = bytes[i];
      b
        ..write(digits[v >> 4])
        ..write(digits[v & 15]);
    }
    return b.toString();
  }

  _Unit _tableUnit(TableBlock t) {
    final ts = theme.table;
    final cols = math.max(1, t.columnCount);
    final pad = ts.cellPadding;
    // Column widths from the longest cell text (Markdown cells are short).
    final weights = List<double>.filled(cols, 3);
    for (final row in t.rows) {
      for (var c = 0; c < cols && c < row.length; c++) {
        final len = InlineRun.plainText(row[c]).runes.length.toDouble();
        weights[c] = math.max(weights[c], math.min(len, 40));
      }
    }
    final charW = ts.style.fontSize * 0.55;
    final natural = [for (final w in weights) w * charW + pad.horizontal + 2];
    final sum = natural.fold(0.0, (s, w) => s + w);
    final widths = ts.width == TableWidth.full || sum > contentWidth
        ? [for (final w in natural) w / sum * contentWidth]
        : natural;
    final edges = <int>[];
    var x = 0.0;
    for (final w in widths) {
      x += w;
      edges.add(_tw(x));
    }
    final border = BorderPt(
      width: ts.borderWidth,
      style: LineStyle.solid,
      color: ts.borderColor,
    );
    final line = _border(border);
    final out = _Rtf();
    final rows = t.rows.isEmpty ? <List<List<InlineRun>>>[[]] : t.rows;
    for (var r = 0; r < rows.length; r++) {
      final header = r == 0;
      final lastRow = r == rows.length - 1;
      out
        ..cw('trowd')
        ..cw('trgaph', 108)
        ..cw('trleft', 0);
      if (header) out.cw('trhdr');
      out
        ..cw('trpaddl', _tw(pad.left))
        ..cw('trpaddr', _tw(pad.right))
        ..cw('trpaddt', _tw(pad.top))
        ..cw('trpaddb', _tw(pad.bottom))
        ..cw('trpaddfl', 3)
        ..cw('trpaddfr', 3)
        ..cw('trpaddft', 3)
        ..cw('trpaddfb', 3);
      final bg = header
          ? ts.headerBackground
          : (ts.zebra && r.isEven ? ts.zebraColor : null);
      for (var c = 0; c < cols; c++) {
        if (bg != null && (bg >>> 24) != 0) out.cw('clcbpat', _color(bg));
        final (top, left, bottom, right) = switch (ts.borders) {
          TableBorders.all => (true, true, true, true),
          TableBorders.horizontal => (false, false, true, false),
          TableBorders.headerOnly => (false, false, header, false),
          TableBorders.outer => (header, c == 0, lastRow, c == cols - 1),
          TableBorders.none => (false, false, false, false),
        };
        if (top) out.add('\\clbrdrt$line');
        if (left) out.add('\\clbrdrl$line');
        if (bottom) out.add('\\clbrdrb$line');
        if (right) out.add('\\clbrdrr$line');
        out.cw('cellx', edges[c]);
      }
      out.nl();
      final style = header ? ts.headerStyle : ts.style;
      final styleId = header ? _S.tableHeading : _S.tableContents;
      for (var c = 0; c < cols; c++) {
        final runs = c < rows[r].length ? rows[r][c] : const <InlineRun>[];
        final align = c < t.align.length ? t.align[c] : null;
        out
          ..cw('pard')
          ..cw('plain')
          ..cw('intbl')
          ..cw('s', styleId)
          ..add(switch (align) {
            CellAlign.left => r'\ql',
            CellAlign.center => r'\qc',
            CellAlign.right => r'\qr',
            null => '',
          })
          ..add(_lineSpacing(style))
          ..add(_chars(style));
        _runs(out, runs, style);
        out
          ..cw('cell')
          ..nl();
      }
      out
        ..cw('row')
        ..nl();
    }
    return _Unit.table(
      out.done(),
      before: ts.box.spaceBefore,
      after: ts.box.spaceAfter,
    );
  }

  // -------------------------------------------------------------------------
  // Document

  String write() {
    // Register the style fonts and colors first (body = \f0).
    final normal = _chars(theme.body.style);
    final units = _body();
    final body = _serializeBody(units);
    final headerFooter = _headersFooters();
    final styles = _stylesheet(normal);
    final lists = _listTables();

    final out = StringBuffer()
      ..write(r'{\rtf1\ansi\ansicpg1252\deff0\uc1')
      ..write('\n')
      ..write(_fontTable())
      ..write('\n')
      ..write(_colorTable())
      ..write('\n')
      ..write(styles)
      ..write(lists)
      ..write(r'{\*\generator Wonky Write;}')
      ..write('\n')
      ..write(_info())
      ..write(_documentFormat())
      ..write(headerFooter)
      ..write(body)
      ..write('}\n');
    return out.toString();
  }

  String _fontTable() {
    final b = StringBuffer(r'{\fonttbl');
    for (var i = 0; i < _fonts.length; i++) {
      final family = _fonts[i];
      final category = FontRegistry.lookup(family)?.category;
      final mono =
          category == FontCategory.mono || MonospaceFonts.isMonospace(family);
      final kind = mono
          ? r'\fmodern'
          : switch (category) {
              FontCategory.serif => r'\froman',
              FontCategory.sans => r'\fswiss',
              _ => r'\fnil',
            };
      b.write(
        '{\\f$i$kind\\fcharset0\\fprq${mono ? 1 : 2} ${_escaped(family)};}',
      );
    }
    b.write('}');
    return b.toString();
  }

  String _colorTable() {
    final b = StringBuffer(r'{\colortbl;');
    for (final c in _colors) {
      b.write(
        '\\red${(c >> 16) & 0xFF}\\green${(c >> 8) & 0xFF}\\blue${c & 0xFF};',
      );
    }
    b.write('}');
    return b.toString();
  }

  String _styleSpacing(ResolvedBox box) =>
      '\\sb${_tw(box.spaceBefore)}\\sa${_tw(box.spaceAfter)}';

  String _stylesheet(String normalChars) {
    final t = theme;
    final b = StringBuffer(r'{\stylesheet')..write('\n');
    void style(int id, String props, String name, {int? next}) {
      b.write(
        '{\\s$id$props${id == 0 ? '' : '\\sbasedon0'}'
        '\\snext${next ?? id} ${_escaped(name)};}\n',
      );
    }

    style(
      _S.normal,
      '${_normalPara()}${_styleSpacing(t.body.box)}$normalChars',
      'Normal',
    );
    for (final h in t.headings) {
      style(
        h.level,
        '${_headingPara(h)}${_styleSpacing(h.box)}${_chars(h.style)}',
        'heading ${h.level}',
        next: _S.normal,
      );
    }
    style(
      _S.quote,
      '${_quotePara()}${_styleSpacing(t.blockquote.box)}'
          '${_chars(t.blockquote.style)}',
      'Quote',
    );
    style(
      _S.code,
      '${_codePara()}${_styleSpacing(t.codeBlock.box)}'
          '${_chars(t.codeBlock.style)}',
      'Code Block',
    );
    style(
      _S.caption,
      '${_captionPara()}${_chars(t.image.caption.style)}',
      'Caption',
      next: _S.normal,
    );
    style(
      _S.listParagraph,
      '\\ql${_lineSpacing(t.list.style)}${_chars(t.list.style)}',
      'List Paragraph',
    );
    style(
      _S.rule,
      '${_rulePara()}${_styleSpacing(t.rule.box)}${_ruleChars()}',
      'Horizontal Line',
      next: _S.normal,
    );
    style(
      _S.tableHeading,
      '\\ql${_lineSpacing(t.table.headerStyle)}${_chars(t.table.headerStyle)}',
      'Table Heading',
    );
    style(
      _S.tableContents,
      '\\ql${_lineSpacing(t.table.style)}${_chars(t.table.style)}',
      'Table Contents',
    );
    style(_S.header, '${_slotPara()}${_chars(t.header.style)}', 'header');
    style(_S.footer, '${_slotPara()}${_chars(t.footer.style)}', 'footer');
    b
      ..write(
        '{\\*\\cs${_S.inlineCode}\\additive '
        '${_inlineCodeChars(t.body.style.fontSize, style: false)}'
        'Inline Code;}\n',
      )
      ..write(
        '{\\*\\cs${_S.hyperlink}\\additive '
        '${_hyperlinkChars(style: false)}Hyperlink;}\n',
      )
      ..write('}\n');
    return b.toString();
  }

  static int _nfc(ListNumberStyle s) => switch (s) {
    ListNumberStyle.decimal => 0,
    ListNumberStyle.upperRoman => 1,
    ListNumberStyle.lowerRoman => 2,
    ListNumberStyle.upperAlpha => 3,
    ListNumberStyle.lowerAlpha => 4,
  };

  String _listTables() {
    if (_overrides.isEmpty) return '';
    final l = theme.list;
    final style = l.style;
    final b = StringBuffer(r'{\*\listtable')..write('\n');
    void list(int id, String name, String Function(int level) levelBody) {
      b.write('{\\list\\listtemplateid$id');
      for (var level = 0; level < 9; level++) {
        final (li, fi) = _listIndents(level);
        b.write('{\\listlevel${levelBody(level)}\\fi$fi\\li$li\\lin$li }');
      }
      b.write('{\\listname ${_escaped(name)};}\\listid$id}\n');
    }

    const common =
        r'\leveljc0\leveljcn0\levelstartat1\levelspace0\levelindent0';
    list(_L.bullets, 'Wonky Bullets', (level) {
      final glyph = l.bulletFor(level);
      final chars = _Rtf()
        ..cw('f', _font(style.fontFamily))
        ..cw('fs', _hp(style.fontSize * l.bulletScale))
        ..cw('cf', _color(l.bulletColor));
      final marker = switch (glyph) {
        '•' => r'\{disc\}',
        '◦' => r'\{circle\}',
        '▪' || '■' => r'\{square\}',
        '-' || '–' => r'\{hyphen\}',
        _ => _escaped(glyph),
      };
      return '\\levelnfc23\\levelnfcn23$common\\levelfollow0'
          '{\\*\\levelmarker $marker}'
          '{\\leveltext\\\'${_hex2(glyph.length)}${_escaped(glyph)};}'
          '{\\levelnumbers;}${chars.done()}';
    });
    list(_L.numbers, 'Wonky Numbers', (level) {
      final nfc = _nfc(l.numberStyleFor(level));
      final suffix = l.numberSuffix;
      final chars = _Rtf()
        ..cw('f', _font(style.fontFamily))
        ..cw('fs', _hp(style.fontSize))
        ..cw('cf', _color(l.numberColor));
      final marker = switch (l.numberStyleFor(level)) {
        ListNumberStyle.decimal => 'decimal',
        ListNumberStyle.lowerAlpha => 'lower-alpha',
        ListNumberStyle.upperAlpha => 'upper-alpha',
        ListNumberStyle.lowerRoman => 'lower-roman',
        ListNumberStyle.upperRoman => 'upper-roman',
      };
      return '\\levelnfc$nfc\\levelnfcn$nfc$common\\levelfollow0'
          '{\\*\\levelmarker \\{$marker\\}${_escaped(suffix)}}'
          '{\\leveltext\\\'${_hex2(1 + suffix.length)}\\\'${_hex2(level)}'
          '${_escaped(suffix)};}{\\levelnumbers\\\'01;}${chars.done()}';
    });
    list(
      _L.tasks,
      'Wonky Tasks',
      (level) =>
          '\\levelnfc255\\levelnfcn255$common\\levelfollow2'
          "{\\leveltext\\'00;}{\\levelnumbers;}",
    );
    b
      ..write('}\n')
      ..write(r'{\*\listoverridetable');
    for (var i = 0; i < _overrides.length; i++) {
      final (listId, restart) = _overrides[i];
      if (restart) {
        b.write('{\\listoverride\\listid$listId\\listoverridecount9');
        for (var level = 0; level < 9; level++) {
          b.write(r'{\lfolevel\listoverridestartat\levelstartat1}');
        }
        b.write('\\ls${i + 1}}');
      } else {
        b.write(
          '{\\listoverride\\listid$listId\\listoverridecount0\\ls${i + 1}}',
        );
      }
    }
    b.write('}\n');
    return b.toString();
  }

  static String _hex2(int v) =>
      v.clamp(0, 255).toRadixString(16).padLeft(2, '0');

  String _info() {
    final b = StringBuffer(r'{\info');
    final title = input.meta.title?.trim() ?? '';
    if (title.isNotEmpty) b.write('{\\title ${_escaped(title)}}');
    final author = exportAuthor(input)?.trim() ?? '';
    if (author.isNotEmpty) b.write('{\\author ${_escaped(author)}}');
    final modified = input.meta.modifiedAt?.toUtc();
    if (modified != null) {
      final time =
          '\\yr${modified.year}\\mo${modified.month}\\dy${modified.day}'
          '\\hr${modified.hour}\\min${modified.minute}';
      b.write('{\\creatim$time}{\\revtim$time}');
    }
    b.write('}\n');
    return b.toString();
  }

  String _documentFormat() {
    final setup = input.pageSetup;
    final m = pageMarginsPt(input, theme);
    final w = _tw(setup.pageWidthPt);
    final h = _tw(setup.pageHeightPt);
    final landscape = setup.orientation == PageOrientation.landscape;
    final b = StringBuffer()
      ..write(
        '\\paperw$w\\paperh$h\\margl${_tw(m.left)}\\margr${_tw(m.right)}'
        '\\margt${_tw(m.top)}\\margb${_tw(m.bottom)}',
      )
      ..write(landscape ? r'\landscape' : '')
      ..write(r'\widowctrl\deftab720\viewkind4')
      ..write('\n')
      ..write(
        '\\sectd\\pgwsxn$w\\pghsxn$h\\marglsxn${_tw(m.left)}'
        '\\margrsxn${_tw(m.right)}\\margtsxn${_tw(m.top)}'
        '\\margbsxn${_tw(m.bottom)}',
      )
      ..write(landscape ? r'\lndscpsxn' : '')
      ..write(
        '\\headery${_tw(setup.header.distancePt)}'
        '\\footery${_tw(setup.footer.distancePt)}',
      );
    if (setup.differentFirstPage) b.write(r'\titlepg');
    b.write('\\pgnstarts${setup.pageNumberStart}');
    if (setup.pageNumberStart != 1) b.write(r'\pgnrestart');
    b
      ..write(switch (setup.pageNumberFormat) {
        PageNumberFormat.decimal => r'\pgndec',
        PageNumberFormat.lowerRoman => r'\pgnlcrm',
        PageNumberFormat.upperRoman => r'\pgnucrm',
      })
      ..write('\n');
    return b.toString();
  }

  String _headersFooters() {
    final setup = input.pageSetup;
    final ctx = HeaderFooterSlots.context(input);
    final b = StringBuffer();
    void slot(String dest, HeaderFooterSpec spec, bool header) {
      final style = header ? theme.header : theme.footer;
      final out = _Rtf()
        ..add('{\\$dest')
        ..cw('pard')
        ..cw('plain')
        ..cw('s', header ? _S.header : _S.footer)
        ..add(_slotPara());
      final line = header ? style.borderBottom : style.borderTop;
      if (line != null && line.isVisible) {
        out.add('${header ? r'\brdrb' : r'\brdrt'}${_border(line, space: 4)}');
      }
      out.add(_chars(style.style));
      if (spec.enabled && !spec.isEmpty) {
        final slots = [spec.left, spec.center, spec.right];
        for (var i = 0; i < 3; i++) {
          if (i > 0) out.cw('tab');
          for (final part in HeaderFooterSlots.parts(slots[i], ctx)) {
            switch (part) {
              case SlotText(:final text):
                out.text(text);
              case SlotField(:final pageCount):
                out
                  ..add(r'{\field{\*\fldinst ')
                  ..add(pageCount ? 'NUMPAGES' : _pageInstr(setup))
                  ..add(r'}{\fldrslt ')
                  ..text(pageCount ? '1' : setup.pageLabel(0))
                  ..add('}}');
            }
          }
        }
      }
      out
        ..cw('par')
        ..close()
        ..nl();
      b.write(out.done());
    }

    bool used(HeaderFooterSpec s) => s.enabled && !s.isEmpty;
    if (used(setup.header)) slot('header', setup.header, true);
    if (used(setup.footer)) slot('footer', setup.footer, false);
    if (setup.differentFirstPage) {
      slot('headerf', setup.firstPageHeader, true);
      slot('footerf', setup.firstPageFooter, false);
    }
    return b.toString();
  }

  static String _pageInstr(PageSetup setup) => switch (setup.pageNumberFormat) {
    PageNumberFormat.decimal => 'PAGE',
    PageNumberFormat.lowerRoman => r'PAGE \\* roman',
    PageNumberFormat.upperRoman => r'PAGE \\* ROMAN',
  };

  /// Writes [units] with collapsed spacing: the gap between two units is
  /// `max(after, before)`, put on the paragraph below (or above a table);
  /// adjacent tables get an empty separator paragraph.
  String _serializeBody(List<_Unit> units) {
    final n = units.length;
    final sb = List<double>.filled(n, 0);
    final sa = List<double>.filled(n, 0);
    final separator = List<double?>.filled(n, null);
    for (var i = 0; i < n; i++) {
      final u = units[i];
      final gap = i == 0 ? u.before : math.max(units[i - 1].after, u.before);
      if (u.table == null) {
        sb[i] = gap;
      } else if (i > 0 && units[i - 1].table == null) {
        sa[i - 1] = gap;
      } else if (i > 0) {
        separator[i] = gap;
      }
    }
    if (n > 0 && units.last.table == null) sa[n - 1] = units.last.after;
    final b = StringBuffer();
    final normal = '\\s${_S.normal}${_normalPara()}${_chars(theme.body.style)}';
    for (var i = 0; i < n; i++) {
      input.cancel?.throwIfCancelled();
      final u = units[i];
      if (separator[i] != null) {
        b.write(
          '\\pard\\plain$normal\\sb${_tw(separator[i]!)}\\sa0\\fs2\\par\n',
        );
      }
      if (u.table != null) {
        b.write(u.table);
        continue;
      }
      b
        ..write(r'\pard\plain')
        ..write(u.props)
        ..write('\\sb${_tw(sb[i])}\\sa${_tw(sa[i])} ')
        ..write(u.content);
      if (i < n - 1) b.write(r'\par');
      b.write('\n');
    }
    if (n == 0 || units.last.table != null) {
      b.write('\\pard\\plain$normal\n');
    }
    return b.toString();
  }
}
