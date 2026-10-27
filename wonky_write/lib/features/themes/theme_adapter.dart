import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Brightness;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../editor/styles/editor_theme.dart';
import '../editor/styles/wonky_style.dart';
import 'write_fonts.dart';

/// Logical pixels per point (96 dpi screen, 72 pt per inch).
const double pxPerPt = 96 / 72;

/// Converts a resolved Write theme (`wonky_write_core`, points + ARGB ints)
/// into the editor's [EditorTheme] (logical pixels + Flutter colors), Write 06
/// §6. Overlay tokens the theme doesn't override come from
/// [EditorTheme.fallback] of the same brightness.
class EditorThemeAdapter {
  const EditorThemeAdapter();

  static final Map<String, EditorTheme> _cache = {};

  /// The editor theme for [theme] (memoized by content hash + variant).
  EditorTheme adapt(ResolvedWriteTheme theme) {
    final key = '${theme.contentHash}/${theme.variant.name}';
    final hit = _cache[key];
    if (hit != null) return hit;
    // The theme editor adapts a new draft on every change: keep the cache
    // bounded.
    if (_cache.length >= 64) _cache.remove(_cache.keys.first);
    return _cache[key] = _adapt(theme);
  }

  /// Every screen font family the theme uses (for [WriteFonts.ensureLoaded]).
  static Set<String> screenFamilies(ResolvedWriteTheme theme) => {
    WriteFonts.screenFamilyFor(theme.body.style.fontFamily),
    for (final h in theme.headings)
      WriteFonts.screenFamilyFor(h.style.fontFamily),
    WriteFonts.screenFamilyFor(theme.codeBlock.style.fontFamily),
    WriteFonts.screenFamilyFor(theme.inlineCode.fontFamily),
    WriteFonts.screenFamilyFor(theme.blockquote.style.fontFamily),
  };

  EditorTheme _adapt(ResolvedWriteTheme t) {
    final brightness = t.variant == ThemeVariant.dark
        ? Brightness.dark
        : Brightness.light;
    final fallback = EditorTheme.fallback(brightness);
    Color c(int argb) => Color(argb);
    Color? oc(int? argb) => argb == null ? null : Color(argb);
    double px(double pt) => pt * pxPerPt;
    EdgeInsets edges(EdgesPt e) =>
        EdgeInsets.fromLTRB(px(e.left), px(e.top), px(e.right), px(e.bottom));

    TextStyle text(ResolvedTextStyle s) => TextStyle(
      fontFamily: WriteFonts.screenFamilyFor(s.fontFamily),
      fontFamilyFallback: WriteFonts.screenFallbackFor(s.fontFamily),
      fontSize: px(s.fontSize),
      fontWeight: _weight(s.fontWeight),
      fontStyle: s.italic ? FontStyle.italic : FontStyle.normal,
      height: s.lineHeight,
      letterSpacing: px(s.letterSpacing),
      color: c(s.color),
    );

    final muted = t.palette[PaletteKey.muted] ?? fallback.mutedColor.toARGB32();
    final accent =
        t.palette[PaletteKey.accent] ?? fallback.ringColor.toARGB32();
    final bullets = t.list.bullets.isEmpty
        ? fallback.bullets
        : [
            for (var i = 0; i < 9; i++)
              t.list.bullets[i % t.list.bullets.length],
          ];
    final syntax = <String, Color>{...fallback.syntax};
    t.syntax.forEach((token, style) {
      for (final key in _syntaxKeys(token)) {
        syntax[key] = c(style.color);
      }
    });
    final o = t.overlays;
    final codeBackground =
        oc(t.codeBlock.box.background) ?? fallback.codeBlockBackground;
    return EditorTheme(
      brightness: brightness,
      paperColor: c(t.page.paperColor),
      canvasColor: c(t.page.canvasColor),
      body: text(t.body.style),
      paragraphSpacing: px(t.body.box.spaceAfter),
      headings: [for (final h in t.headings) text(h.style)],
      headingSpacingBefore: [for (final h in t.headings) px(h.box.spaceBefore)],
      headingSpacingAfter: [for (final h in t.headings) px(h.box.spaceAfter)],
      quote: text(t.blockquote.style),
      quoteBarColor: t.blockquote.bar.isVisible
          ? c(t.blockquote.bar.color)
          : fallback.quoteBarColor,
      quoteBarWidth: t.blockquote.bar.isVisible
          ? px(t.blockquote.bar.width)
          : fallback.quoteBarWidth,
      codeBlock: text(t.codeBlock.style),
      codeBlockBackground: codeBackground,
      codeBlockPadding: t.codeBlock.box.padding == EdgesPt.zero
          ? fallback.codeBlockPadding
          : edges(t.codeBlock.box.padding),
      codeBlockRadius: px(t.codeBlock.box.borderRadius),
      codeBlockBorder: _codeBorder(t.codeBlock.box.border, px),
      inlineCodeColor: c(t.inlineCode.color),
      inlineCodeBackground:
          oc(t.inlineCode.background) ?? fallback.inlineCodeBackground,
      inlineCodeSizeRatio: t.inlineCode.sizeRatio,
      monoFontFamily: WriteFonts.screenFamilyFor(t.inlineCode.fontFamily),
      linkColor: c(t.link.color),
      linkUnderline: t.link.underline == LinkUnderline.always,
      mentionColor: c(t.mention.color),
      mentionBackground: oc(t.mention.background) ?? fallback.mentionBackground,
      listMarkerColor: c(t.list.bulletColor),
      listIndentPerLevel: px(t.list.indentPerLevel),
      listItemSpacing: px(t.list.itemSpacing),
      bullets: bullets,
      checkedTextColor: c(t.task.checkedColor),
      checkedStrike: t.task.checkedStrike,
      ruleColor: c(t.rule.color),
      ruleThickness: px(t.rule.thickness).clamp(0.5, 8),
      tableBorderColor: c(t.table.borderColor),
      tableHeaderBackground:
          oc(t.table.headerBackground) ?? fallback.tableHeaderBackground,
      mutedColor: c(muted),
      syntax: syntax,
      selectionColor: oc(o.selection) ?? fallback.selectionColor,
      caretColor: oc(o.caretColor) ?? c(t.body.style.color),
      commentHighlight: oc(o.commentHighlight) ?? fallback.commentHighlight,
      commentHighlightActive:
          oc(o.commentHighlightActive) ?? fallback.commentHighlightActive,
      suggestionInsert: oc(o.suggestionInsert) ?? fallback.suggestionInsert,
      suggestionDelete: oc(o.suggestionDelete) ?? fallback.suggestionDelete,
      findMatch: oc(o.findMatch) ?? fallback.findMatch,
      findMatchActive: oc(o.findMatchActive) ?? fallback.findMatchActive,
      presenceColors: fallback.presenceColors,
      ringColor: c(accent),
      pagelessMaxWidth: px(t.page.pagelessMaxWidth),
      pagelessPadding: edges(t.page.pagelessPadding),
      contentHash: '${t.contentHash}/${t.variant.name}',
      wonky: WonkyEditorStyle.fromResolved(t.wonky, px),
    );
  }

  /// The code block box border. A rounded box needs one uniform side, so the
  /// theme's top border is used for all four.
  static BorderSide _codeBorder(
    BordersPt border,
    double Function(double pt) px,
  ) {
    final side = border.top;
    if (!side.isVisible) return BorderSide.none;
    return BorderSide(color: Color(side.color), width: px(side.width));
  }

  static FontWeight _weight(int w) {
    final index = ((w.clamp(100, 900) / 100).round() - 1).clamp(0, 8);
    return FontWeight.values[index];
  }

  static List<String> _syntaxKeys(SyntaxToken token) => switch (token) {
    SyntaxToken.keyword => const ['keyword'],
    SyntaxToken.string => const ['string'],
    SyntaxToken.number => const ['number'],
    SyntaxToken.comment => const ['comment'],
    SyntaxToken.function => const ['title', 'function'],
    SyntaxToken.type => const ['type'],
    SyntaxToken.variable => const ['variable'],
    SyntaxToken.operator => const ['operator'],
    SyntaxToken.punctuation => const ['punctuation'],
    SyntaxToken.builtin => const ['built_in'],
    SyntaxToken.literal => const ['literal'],
    SyntaxToken.meta => const ['meta'],
    SyntaxToken.tag => const ['tag'],
    SyntaxToken.attribute => const ['attr', 'attribute'],
    SyntaxToken.regexp => const ['regexp'],
    SyntaxToken.addition => const ['addition'],
    SyntaxToken.deletion => const ['deletion'],
  };
}
