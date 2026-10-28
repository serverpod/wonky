import 'package:flutter/material.dart';
import 'package:super_editor/super_editor.dart';

import '../attributions/wonky_attributions.dart';
import '../controller/editor_types.dart';
import '../mapping/wonky_schema.dart';
import 'editor_theme.dart';

/// Comment highlight state the inline styler needs (Write 04 §33, Write 08
/// §3.1): which threads are resolved/orphaned (no highlight) and which is
/// active.
@immutable
class CommentHighlightState {
  const CommentHighlightState({
    this.hiddenThreads = const {},
    this.activeThread,
    this.visible = true,
  });

  /// Resolved or orphaned threads (rendered without highlight).
  final Set<String> hiddenThreads;

  /// The active thread (`commentHighlightActive`).
  final String? activeThread;

  /// Whether comments are shown at all (Viewing mode without comment rights).
  final bool visible;

  @override
  bool operator ==(Object other) =>
      other is CommentHighlightState &&
      other.activeThread == activeThread &&
      other.visible == visible &&
      other.hiddenThreads.length == hiddenThreads.length &&
      other.hiddenThreads.containsAll(hiddenThreads);

  @override
  int get hashCode => Object.hash(activeThread, visible, hiddenThreads.length);
}

/// The super_editor configuration derived from a theme (Write 06 §6).
class WriteEditorStyle {
  const WriteEditorStyle({
    required this.stylesheet,
    required this.selectionStyles,
    required this.caretStyle,
    required this.theme,
    required this.zoom,
  });

  final Stylesheet stylesheet;
  final SelectionStyles selectionStyles;
  final CaretStyle caretStyle;
  final EditorTheme theme;
  final double zoom;
}

/// Builds and memoizes [WriteEditorStyle]s per (theme, zoom, layout, comment
/// state) so that typing never rebuilds the stylesheet (Write 04 §36).
class WriteStylesheetBuilder {
  WriteStylesheetBuilder();

  WriteEditorStyle? _last;
  Object? _lastKey;

  WriteEditorStyle build({
    required EditorTheme theme,
    double zoom = 1,
    double textScale = 1,
    LayoutMode layout = LayoutMode.pageless,
    double? contentWidth,
    CommentHighlightState comments = const CommentHighlightState(),
    String selfUserUuid = '',
    bool focused = true,
  }) {
    final key = (
      theme,
      zoom,
      textScale,
      layout,
      contentWidth,
      comments,
      selfUserUuid,
      focused,
    );
    if (_lastKey == key && _last != null) return _last!;
    final scale = zoom * textScale;
    final style = WriteEditorStyle(
      stylesheet: buildStylesheet(
        theme,
        scale: scale,
        layout: layout,
        contentWidth: contentWidth,
        comments: comments,
        selfUserUuid: selfUserUuid,
      ),
      selectionStyles: SelectionStyles(
        selectionColor: focused
            ? theme.selectionColor
            : theme.selectionColor.withValues(
                alpha: theme.selectionColor.a * 0.5,
              ),
        highlightEmptyTextBlocks: true,
      ),
      caretStyle: CaretStyle(color: theme.caretColor, width: 2),
      theme: theme,
      zoom: zoom,
    );
    _last = style;
    _lastKey = key;
    return style;
  }

  /// The super_editor [Stylesheet] for [theme] (Write 06 §6.1–6.2).
  static Stylesheet buildStylesheet(
    EditorTheme theme, {
    double scale = 1,
    LayoutMode layout = LayoutMode.pageless,
    double? contentWidth,
    CommentHighlightState comments = const CommentHighlightState(),
    String selfUserUuid = '',
  }) {
    TextStyle scaled(TextStyle style) => style.copyWith(
      fontSize: (style.fontSize ?? 14.67) * scale,
      letterSpacing: style.letterSpacing == null
          ? null
          : style.letterSpacing! * scale,
    );
    double px(double value) => value * scale;
    // List and task items; inside a quote they sit in the quote's indent
    // and their spacing is inside the bar (WonkyParagraphComponentBuilder).
    // The indent of a quote's bar, on the start side of the block (Write 04
    // §38).
    CascadingPadding quoteIndent(DocumentNode node) => isRtlNode(node)
        ? CascadingPadding.only(
            right: px(theme.quoteBarWidth + 12),
            top: 0,
            bottom: 0,
          )
        : CascadingPadding.only(
            left: px(theme.quoteBarWidth + 12),
            top: 0,
            bottom: 0,
          );
    CascadingPadding listItemPadding(DocumentNode node) =>
        isQuotedListNode(node)
        ? quoteIndent(node)
        : CascadingPadding.only(
            top: px(theme.listItemSpacing),
            bottom: px(theme.listItemSpacing),
          );
    final maxWidth = layout == LayoutMode.pageless
        ? px(theme.pagelessMaxWidth)
        : (contentWidth ?? 794) * scale;

    final rules = <StyleRule>[
      StyleRule(BlockSelector.all, (doc, node) {
        return {
          Styles.maxWidth: maxWidth,
          Styles.padding: CascadingPadding.only(
            top: px(theme.paragraphSpacing / 2),
            bottom: px(theme.paragraphSpacing / 2),
          ),
          Styles.textStyle: scaled(theme.body),
          Styles.textAlign: TextAlign.start,
        };
      }),
      for (var level = 1; level <= 6; level += 1)
        StyleRule(BlockSelector('header$level'), (doc, node) {
          return {
            Styles.textStyle: scaled(theme.headings[level - 1]),
            Styles.padding: CascadingPadding.only(
              top: px(theme.headingSpacingBefore[level - 1]),
              bottom: px(theme.headingSpacingAfter[level - 1]),
            ),
          };
        }),
      for (var level = 1; level <= 6; level += 1)
        StyleRule(const BlockSelector('paragraph').after('header$level'), (
          doc,
          node,
        ) {
          return {Styles.padding: CascadingPadding.only(top: px(2))};
        }),
      StyleRule(const BlockSelector('blockquote'), (doc, node) {
        return {
          Styles.textStyle: scaled(theme.quote),
          // The space above and below each quote line is inside the bar
          // (WonkyParagraphComponentBuilder), so consecutive lines and
          // paragraphs of one quote share one unbroken bar (Write 04 §14).
          Styles.padding: quoteIndent(node),
        };
      }),
      // Space around the block; the box itself (background, corners, border,
      // inner padding) is painted by WonkyParagraphComponentBuilder.
      StyleRule(const BlockSelector('code'), (doc, node) {
        return {
          Styles.textStyle: scaled(theme.codeBlock),
          Styles.padding: CascadingPadding.only(top: px(8), bottom: px(8)),
        };
      }),
      StyleRule(const BlockSelector('listItem'), (doc, node) {
        final indent = node is ListItemNode ? node.indent : 0;
        final glyph = theme.bullets[indent % theme.bullets.length];
        return {
          Styles.padding: listItemPadding(node),
          if (isQuotedListNode(node)) Styles.textStyle: scaled(theme.quote),
          Styles.dotColor: theme.listMarkerColor,
          Styles.dotShape: glyph == '▪' ? BoxShape.rectangle : BoxShape.circle,
          Styles.dotSize: Size(
            px(glyph == '◦' ? 4 : 5),
            px(glyph == '◦' ? 4 : 5),
          ),
          Styles.listNumeralStyle: switch (indent % 3) {
            0 => OrderedListNumeralStyle.arabic,
            1 => OrderedListNumeralStyle.lowerAlpha,
            _ => OrderedListNumeralStyle.lowerRoman,
          },
        };
      }),
      StyleRule(const BlockSelector('task'), (doc, node) {
        return {
          Styles.padding: listItemPadding(node),
          if (isQuotedListNode(node)) Styles.textStyle: scaled(theme.quote),
        };
      }),
      StyleRule(const BlockSelector('horizontalRule'), (doc, node) {
        return {
          Styles.padding: CascadingPadding.only(top: px(12), bottom: px(12)),
        };
      }),
      StyleRule(const BlockSelector('image'), (doc, node) {
        return {
          Styles.padding: CascadingPadding.only(top: px(8), bottom: px(8)),
        };
      }),
      StyleRule(const BlockSelector('tableBlock'), (doc, node) {
        return {
          Styles.padding: CascadingPadding.only(top: px(8), bottom: px(8)),
          TableStyles.headerTextStyle: scaled(
            theme.body,
          ).copyWith(fontWeight: FontWeight.w600),
          TableStyles.border: TableBorder.all(
            color: theme.tableBorderColor,
            width: 1,
          ),
          TableStyles.cellPadding: CascadingPadding.symmetric(
            horizontal: px(8),
            vertical: px(4),
          ),
          TableStyles.cellDecorator:
              ({
                required int rowIndex,
                required int columnIndex,
                required AttributedText cellText,
                required Map<String, dynamic> cellMetadata,
              }) => rowIndex == 0
              ? BoxDecoration(color: theme.tableHeaderBackground)
              : null,
        };
      }),
      StyleRule(BlockSelector.all.first(), (doc, node) {
        return {Styles.padding: const CascadingPadding.only(top: 0)};
      }),
      StyleRule(BlockSelector.all.last(), (doc, node) {
        return {
          Styles.padding: CascadingPadding.only(
            bottom: layout == LayoutMode.pageless
                ? px(theme.pagelessPadding.bottom)
                : 0,
          ),
        };
      }),
    ];

    final styler = WriteInlineStyler(
      theme,
      scale: scale,
      comments: comments,
      selfUserUuid: selfUserUuid,
    );
    return Stylesheet(
      rules: rules,
      inlineTextStyler: styler.call,
      documentPadding: layout == LayoutMode.pageless
          ? EdgeInsets.fromLTRB(
              px(theme.pagelessPadding.left),
              px(theme.pagelessPadding.top),
              px(theme.pagelessPadding.right),
              0,
            )
          : EdgeInsets.zero,
      selectedTextColorStrategy:
          ({
            required Color originalTextColor,
            required Color selectionHighlightColor,
          }) => originalTextColor,
    );
  }
}

/// Maps attributions to text styles (Write 06 §6.2, Write 08 §2.5).
class WriteInlineStyler {
  WriteInlineStyler(
    this.theme, {
    this.scale = 1,
    this.comments = const CommentHighlightState(),
    this.selfUserUuid = '',
  });

  final EditorTheme theme;
  final double scale;
  final CommentHighlightState comments;
  final String selfUserUuid;

  TextStyle call(Set<Attribution> attributions, TextStyle existingStyle) {
    var style = existingStyle;
    var decorations = <TextDecoration>[
      if (existingStyle.decoration != null &&
          existingStyle.decoration != TextDecoration.none)
        existingStyle.decoration!,
    ];
    Color? decorationColor;
    TextDecorationStyle? decorationStyle;
    var openComments = 0;
    var activeComment = false;

    for (final attribution in attributions) {
      if (attribution == boldAttribution) {
        style = style.copyWith(fontWeight: FontWeight.w700);
      } else if (attribution == italicsAttribution) {
        style = style.copyWith(fontStyle: FontStyle.italic);
      } else if (attribution == strikethroughAttribution) {
        decorations.add(TextDecoration.lineThrough);
      } else if (attribution == codeAttribution) {
        style = style.copyWith(
          fontFamily: theme.monoFontFamily,
          fontFamilyFallback: const ['Menlo', 'Consolas', 'monospace'],
          fontSize: (style.fontSize ?? 14.67) * theme.inlineCodeSizeRatio,
          color: theme.inlineCodeColor,
          backgroundColor: theme.inlineCodeBackground,
        );
      } else if (attribution is LinkAttribution) {
        // Mentions, buttons and arrow links have their own look.
        if (!attributions.any(
          (a) => a is MentionAttribution || a is LinkStyleAttribution,
        )) {
          style = style.copyWith(color: theme.linkColor);
          if (theme.linkUnderline) {
            decorations.add(TextDecoration.underline);
            decorationColor ??= theme.linkColor;
          }
        }
      } else if (attribution is LinkStyleAttribution) {
        final w = theme.wonky;
        style = switch (attribution.style) {
          'arrow' => style.copyWith(
            color: w.arrowColor,
            fontWeight: w.arrowWeight,
          ),
          // A taller line box: room for the pill around the label.
          'buttonSecondary' => style.copyWith(
            color: w.secondaryButtonColor,
            fontWeight: w.buttonWeight,
            height: 2.3,
          ),
          _ => style.copyWith(
            color: w.buttonColor,
            fontWeight: w.buttonWeight,
            height: 2.3,
          ),
        };
      } else if (attribution is ChipAttribution) {
        style = style.copyWith(
          color: theme.wonky.chipColor,
          fontWeight: theme.wonky.chipWeight,
          height: 1.8,
        );
      } else if (attribution is PillGapAttribution) {
        style = style.copyWith(
          letterSpacing:
              (style.letterSpacing ?? 0) +
              attribution.em * (style.fontSize ?? 14.67),
        );
      } else if (attribution is MentionAttribution) {
        style = style.copyWith(
          color: theme.mentionColor,
          fontWeight: FontWeight.w500,
          backgroundColor: attribution.userUuid == selfUserUuid
              ? theme.commentHighlight
              : theme.mentionBackground,
        );
      } else if (attribution is CommentAttribution) {
        if (comments.visible &&
            !comments.hiddenThreads.contains(attribution.threadUuid)) {
          openComments += 1;
          if (attribution.threadUuid == comments.activeThread) {
            activeComment = true;
          }
        }
      } else if (attribution is SuggestionAttribution) {
        // Insertions are green, deletions red and struck through (Write 08
        // §2.5); the author shows on the card, not in the text.
        switch (attribution.type) {
          case SuggestionType.insertion:
            style = style.copyWith(
              color: theme.suggestionInsert,
              backgroundColor: theme.suggestionInsert.withValues(alpha: 0.12),
            );
          case SuggestionType.deletion:
            style = style.copyWith(
              color: theme.suggestionDelete,
              backgroundColor: theme.suggestionDelete.withValues(alpha: 0.08),
            );
            decorations.add(TextDecoration.lineThrough);
            decorationColor = theme.suggestionDelete;
          case SuggestionType.format:
            decorations.add(TextDecoration.underline);
            decorationColor = theme.presenceColorFor(
              attribution.authorUuid ?? '',
            );
            decorationStyle = TextDecorationStyle.dotted;
          case null:
            break;
        }
      } else if (attribution is CodeTokenAttribution) {
        final color = theme.syntax[attribution.tokenClass];
        if (color != null) {
          style = style.copyWith(
            color: color,
            fontStyle: attribution.tokenClass == 'comment'
                ? FontStyle.italic
                : null,
          );
        }
      } else if (attribution is SuggestionPreviewAttribution &&
          attribution.hidden) {
        style = style.copyWith(
          color: const Color(0x00000000),
          fontSize: 0.01,
          letterSpacing: 0,
        );
      }
    }

    if (openComments > 0) {
      final base = activeComment
          ? theme.commentHighlightActive
          : theme.commentHighlight;
      final extra = (openComments - 1).clamp(0, 2) * 0.15;
      style = style.copyWith(
        backgroundColor: base.withValues(
          alpha: (base.a + extra).clamp(0.0, 1.0),
        ),
      );
    }
    if (decorations.isNotEmpty) {
      style = style.copyWith(
        decoration: TextDecoration.combine(decorations),
        decorationColor: decorationColor ?? style.color,
        decorationStyle: decorationStyle,
      );
    }
    return style;
  }
}

/// The text direction of a block from its first strong character (Write 04
/// §38), falling back to [fallback].
TextDirection detectTextDirection(
  String text, {
  TextDirection fallback = TextDirection.ltr,
}) => strongTextDirection(text) ?? fallback;

/// The direction of [text]'s first strong character, `null` when it has
/// none (digits, punctuation and spaces are neutral).
TextDirection? strongTextDirection(String text) {
  for (final rune in text.runes) {
    if (_isRtl(rune)) return TextDirection.rtl;
    if (_isStrongLtr(rune)) return TextDirection.ltr;
  }
  return null;
}

bool _isRtl(int rune) =>
    (rune >= 0x0590 && rune <= 0x08FF) ||
    (rune >= 0xFB1D && rune <= 0xFDFF) ||
    (rune >= 0xFE70 && rune <= 0xFEFF);

bool _isStrongLtr(int rune) =>
    (rune >= 0x41 && rune <= 0x5A) ||
    (rune >= 0x61 && rune <= 0x7A) ||
    (rune >= 0xC0 && rune <= 0x24F) ||
    (rune >= 0x370 && rune <= 0x58F) ||
    (rune >= 0x0900 && rune <= 0x1FFF) ||
    (rune >= 0x3040 && rune <= 0x9FFF) ||
    (rune >= 0xAC00 && rune <= 0xD7AF);

/// Whether [node] should be laid out right-to-left.
bool isRtlNode(DocumentNode node) =>
    node is TextNode &&
    detectTextDirection(node.text.toPlainText()) == TextDirection.rtl;

/// The code block language label shown in the chip.
String codeLanguageLabelOf(DocumentNode node) => codeLanguageOf(node);
