import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:wonky_core/wonky_core.dart' show presenceColorIndex;

import 'wonky_style.dart';

/// Visual style of the document surface, in logical pixels at 100 % zoom
/// (Write 06 §6). Built from the document's resolved Write theme
/// (`ResolvedWriteTheme`, `wonky_write_core`) for the current variant, or from
/// [EditorTheme.fallback] while no theme is loaded.
@immutable
class EditorTheme {
  const EditorTheme({
    required this.brightness,
    required this.paperColor,
    required this.canvasColor,
    required this.body,
    required this.paragraphSpacing,
    required this.headings,
    required this.headingSpacingBefore,
    required this.headingSpacingAfter,
    required this.quote,
    required this.quoteBarColor,
    required this.quoteBarWidth,
    required this.codeBlock,
    required this.codeBlockBackground,
    required this.codeBlockPadding,
    required this.codeBlockRadius,
    this.codeBlockBorder = BorderSide.none,
    required this.inlineCodeColor,
    required this.inlineCodeBackground,
    required this.inlineCodeSizeRatio,
    required this.monoFontFamily,
    required this.linkColor,
    required this.linkUnderline,
    required this.mentionColor,
    required this.mentionBackground,
    required this.listMarkerColor,
    required this.listIndentPerLevel,
    required this.listItemSpacing,
    required this.bullets,
    required this.checkedTextColor,
    required this.checkedStrike,
    required this.ruleColor,
    required this.ruleThickness,
    required this.tableBorderColor,
    required this.tableHeaderBackground,
    required this.mutedColor,
    required this.syntax,
    required this.selectionColor,
    required this.caretColor,
    required this.commentHighlight,
    required this.commentHighlightActive,
    required this.suggestionInsert,
    required this.suggestionDelete,
    required this.findMatch,
    required this.findMatchActive,
    required this.presenceColors,
    required this.ringColor,
    required this.pagelessMaxWidth,
    required this.pagelessPadding,
    this.contentHash = 'fallback',
    this._wonky,
  });

  /// Wonky Default, used until the document's theme is resolved.
  factory EditorTheme.fallback(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final text = dark ? const Color(0xffe6e8eb) : const Color(0xff1f2328);
    final heading = dark ? const Color(0xfff3f4f6) : const Color(0xff111111);
    final muted = dark ? const Color(0xff9aa4b2) : const Color(0xff6b7280);
    final accent = dark ? const Color(0xff93c5fd) : const Color(0xff1d4ed8);
    const body = 'Inter';
    TextStyle headingStyle(double size, FontWeight weight) => TextStyle(
      fontFamily: body,
      fontSize: size,
      fontWeight: weight,
      height: 1.25,
      color: heading,
    );
    return EditorTheme(
      brightness: brightness,
      paperColor: dark ? const Color(0xff24262a) : const Color(0xffffffff),
      canvasColor: dark ? const Color(0xff0d0f12) : const Color(0xfff1f3f4),
      body: TextStyle(
        fontFamily: body,
        fontSize: 14.67,
        height: 1.5,
        color: text,
      ),
      paragraphSpacing: 8,
      headings: [
        headingStyle(32, FontWeight.w700),
        headingStyle(24, FontWeight.w700),
        headingStyle(20, FontWeight.w600),
        headingStyle(17.33, FontWeight.w600),
        headingStyle(14.67, FontWeight.w600),
        headingStyle(14.67, FontWeight.w600).copyWith(color: muted),
      ],
      headingSpacingBefore: const [24, 20, 16, 14, 12, 12],
      headingSpacingAfter: const [8, 6, 6, 4, 4, 4],
      quote: TextStyle(
        fontFamily: body,
        fontSize: 14.67,
        height: 1.5,
        color: muted,
      ),
      quoteBarColor: dark ? const Color(0xff3f4650) : const Color(0xffd0d7de),
      quoteBarWidth: 3,
      codeBlock: TextStyle(
        fontFamily: 'JetBrains Mono',
        fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
        fontSize: 13,
        height: 1.45,
        color: dark ? const Color(0xffe6edf3) : const Color(0xff24292f),
      ),
      codeBlockBackground: dark
          ? const Color(0xff161b22)
          : const Color(0xfff6f8fa),
      codeBlockPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      codeBlockRadius: 6,
      inlineCodeColor: dark ? const Color(0xffe6edf3) : const Color(0xff24292f),
      inlineCodeBackground: dark
          ? const Color(0x33a3b3c3)
          : const Color(0x1f818b98),
      inlineCodeSizeRatio: 0.9,
      monoFontFamily: 'JetBrains Mono',
      linkColor: accent,
      linkUnderline: true,
      mentionColor: dark ? const Color(0xffc7d2fe) : const Color(0xff3730a3),
      mentionBackground: dark
          ? const Color(0xff312e81)
          : const Color(0xffe0e7ff),
      listMarkerColor: text,
      listIndentPerLevel: 24,
      listItemSpacing: 2,
      bullets: const ['•', '◦', '▪', '•', '◦', '▪', '•', '◦', '▪'],
      checkedTextColor: muted,
      checkedStrike: true,
      ruleColor: dark ? const Color(0xff3f4650) : const Color(0xffd0d7de),
      ruleThickness: 1,
      tableBorderColor: dark
          ? const Color(0xff3f4650)
          : const Color(0xffd0d7de),
      tableHeaderBackground: dark
          ? const Color(0xff22272e)
          : const Color(0xfff3f4f6),
      mutedColor: muted,
      syntax: dark ? _darkSyntax : _lightSyntax,
      selectionColor: dark ? const Color(0x4d60a5fa) : const Color(0x401a73e8),
      caretColor: dark ? const Color(0xfff3f4f6) : const Color(0xff111111),
      commentHighlight: dark
          ? const Color(0x40fbbf24)
          : const Color(0x59fbbc04),
      commentHighlightActive: dark
          ? const Color(0x80fbbf24)
          : const Color(0xa6fbbc04),
      suggestionInsert: dark
          ? const Color(0xff4ade80)
          : const Color(0xff15803d),
      suggestionDelete: dark
          ? const Color(0xfff87171)
          : const Color(0xffb91c1c),
      findMatch: dark ? const Color(0x4dfacc15) : const Color(0x66fde047),
      findMatchActive: dark ? const Color(0x99f97316) : const Color(0xb3fb923c),
      presenceColors: dark ? _presenceDark : _presenceLight,
      ringColor: accent,
      pagelessMaxWidth: 760,
      pagelessPadding: const EdgeInsets.fromLTRB(32, 48, 32, 96),
    );
  }

  final WonkyEditorStyle? _wonky;

  /// The Wonky Markdown elements (Write 11 §7.2).
  WonkyEditorStyle get wonky => _wonky ?? WonkyEditorStyle.fallback(brightness);

  final Brightness brightness;
  final Color paperColor;
  final Color canvasColor;

  /// Body text (paragraphs, list items).
  final TextStyle body;
  final double paragraphSpacing;

  /// Heading styles, index 0 = H1.
  final List<TextStyle> headings;
  final List<double> headingSpacingBefore;
  final List<double> headingSpacingAfter;

  final TextStyle quote;
  final Color quoteBarColor;
  final double quoteBarWidth;

  /// Code block text; the block is drawn as one box (Write 04 §15.1) with
  /// [codeBlockBackground], [codeBlockRadius], [codeBlockBorder] and
  /// [codeBlockPadding] between the box edge and the text.
  final TextStyle codeBlock;
  final Color codeBlockBackground;
  final EdgeInsets codeBlockPadding;
  final double codeBlockRadius;
  final BorderSide codeBlockBorder;
  final Color inlineCodeColor;
  final Color inlineCodeBackground;
  final double inlineCodeSizeRatio;
  final String monoFontFamily;

  final Color linkColor;
  final bool linkUnderline;
  final Color mentionColor;
  final Color mentionBackground;

  final Color listMarkerColor;
  final double listIndentPerLevel;
  final double listItemSpacing;

  /// Bullet glyph per indent level (9 entries).
  final List<String> bullets;
  final Color checkedTextColor;
  final bool checkedStrike;

  final Color ruleColor;
  final double ruleThickness;
  final Color tableBorderColor;
  final Color tableHeaderBackground;
  final Color mutedColor;

  /// Syntax token class (`keyword`, `string`, `title`, `built_in`, …; see
  /// `CodeHighlightStylePhase.syntaxClassOf`) → color.
  final Map<String, Color> syntax;

  // App overlay tokens (Write 06 §2.6).
  final Color selectionColor;
  final Color caretColor;
  final Color commentHighlight;
  final Color commentHighlightActive;
  final Color suggestionInsert;
  final Color suggestionDelete;
  final Color findMatch;
  final Color findMatchActive;
  final List<Color> presenceColors;
  final Color ringColor;

  final double pagelessMaxWidth;
  final EdgeInsets pagelessPadding;

  /// Identity of the source theme + variant (memoization key).
  final String contentHash;

  /// Presence color for a user key (stable hash, 12 slots).
  Color presenceColorFor(String userKey) =>
      presenceColors[presenceColorIndex(userKey, slots: presenceColors.length)];

  static const _lightSyntax = {
    'keyword': Color(0xffcf222e),
    'built_in': Color(0xff8250df),
    'type': Color(0xff953800),
    'literal': Color(0xff0550ae),
    'number': Color(0xff0550ae),
    'string': Color(0xff0a3069),
    'regexp': Color(0xff0a3069),
    'comment': Color(0xff6e7781),
    'title': Color(0xff8250df),
    'function': Color(0xff8250df),
    'attr': Color(0xff0550ae),
    'attribute': Color(0xff0550ae),
    'symbol': Color(0xff0550ae),
    'meta': Color(0xff6e7781),
    'variable': Color(0xff953800),
    'tag': Color(0xff116329),
    'addition': Color(0xff116329),
    'deletion': Color(0xff82071e),
    'punctuation': Color(0xff57606a),
    'operator': Color(0xffcf222e),
  };

  static const _darkSyntax = {
    'keyword': Color(0xffff7b72),
    'built_in': Color(0xffd2a8ff),
    'type': Color(0xffffa657),
    'literal': Color(0xff79c0ff),
    'number': Color(0xff79c0ff),
    'string': Color(0xffa5d6ff),
    'regexp': Color(0xffa5d6ff),
    'comment': Color(0xff8b949e),
    'title': Color(0xffd2a8ff),
    'function': Color(0xffd2a8ff),
    'attr': Color(0xff79c0ff),
    'attribute': Color(0xff79c0ff),
    'symbol': Color(0xff79c0ff),
    'meta': Color(0xff8b949e),
    'variable': Color(0xffffa657),
    'tag': Color(0xff7ee787),
    'addition': Color(0xffaff5b4),
    'deletion': Color(0xffffdcd7),
    'punctuation': Color(0xffc9d1d9),
    'operator': Color(0xffff7b72),
  };

  static const _presenceLight = [
    Color(0xff2563eb),
    Color(0xffdc2626),
    Color(0xff16a34a),
    Color(0xffd97706),
    Color(0xff7c3aed),
    Color(0xff0d9488),
    Color(0xffdb2777),
    Color(0xff0891b2),
    Color(0xff65a30d),
    Color(0xffea580c),
    Color(0xff4f46e5),
    Color(0xffc026d3),
  ];

  static const _presenceDark = [
    Color(0xff60a5fa),
    Color(0xfff87171),
    Color(0xff4ade80),
    Color(0xfffbbf24),
    Color(0xffa78bfa),
    Color(0xff2dd4bf),
    Color(0xfff472b6),
    Color(0xff22d3ee),
    Color(0xffa3e635),
    Color(0xfffb923c),
    Color(0xff818cf8),
    Color(0xffe879f9),
  ];
}
