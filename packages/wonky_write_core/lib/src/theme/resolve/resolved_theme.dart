/// `ResolvedWriteTheme`: fully cascaded, unit-normalized, variant-specific
/// style values consumed by every renderer (06 §3).
///
/// Conventions: all lengths are **points** (`double`), all colors are
/// 32-bit **ARGB** `int`s (`0xAARRGGBB`), nullable colors mean "none" (no
/// fill) unless documented otherwise. Values are immutable; equality is by
/// value (via [ResolvedValue.toJson]).
library;

import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:wonky_fonts/wonky_fonts.dart';
import '../model/color_ref.dart';
import '../model/json_util.dart';
import '../model/style_enums.dart';
import '../model/syntax_token.dart';
import '../model/values.dart';
import '../numbering/list_markers.dart';

/// Value equality for resolved style classes, defined by [toJson].
mixin ResolvedValue {
  /// JSON form (also used by MCP `write.get_theme` with `resolved: true`).
  Object? toJson();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other.runtimeType == runtimeType &&
          other is ResolvedValue &&
          const DeepCollectionEquality().equals(other.toJson(), toJson()));

  @override
  int get hashCode => const DeepCollectionEquality().hash(toJson());

  @override
  String toString() => '$runtimeType(${jsonEncode(toJson())})';
}

String? _hex(int? argb) =>
    argb == null ? null : argbToHex(argb, withAlpha: (argb >>> 24) != 255);

num _n(double v) => normalizeJsonNumber(double.parse(v.toStringAsFixed(4)));

/// Four side lengths in pt.
final class EdgesPt with ResolvedValue {
  /// Creates edges.
  const EdgesPt({this.top = 0, this.right = 0, this.bottom = 0, this.left = 0});

  /// All sides [v].
  const EdgesPt.all(double v) : top = v, right = v, bottom = v, left = v;

  /// Zero on all sides.
  static const zero = EdgesPt();

  /// Top.
  final double top;

  /// Right.
  final double right;

  /// Bottom.
  final double bottom;

  /// Left.
  final double left;

  /// `left + right`.
  double get horizontal => left + right;

  /// `top + bottom`.
  double get vertical => top + bottom;

  /// Whether all sides are equal.
  bool get isUniform => top == right && top == bottom && top == left;

  /// Mirrors left/right (RTL documents, 06 §6.6).
  EdgesPt mirrored() =>
      EdgesPt(top: top, right: left, bottom: bottom, left: right);

  @override
  JsonMap toJson() => {
    'top': _n(top),
    'right': _n(right),
    'bottom': _n(bottom),
    'left': _n(left),
  };
}

/// A concrete border line.
final class BorderPt with ResolvedValue {
  /// Creates a border.
  const BorderPt({
    required this.width,
    required this.style,
    required this.color,
  });

  /// No border.
  static const none = BorderPt(width: 0, style: LineStyle.none, color: 0);

  /// Width in pt.
  final double width;

  /// Line style.
  final LineStyle style;

  /// ARGB color.
  final int color;

  /// Whether anything is drawn.
  bool get isVisible =>
      style != LineStyle.none && width > 0 && (color >>> 24) != 0;

  @override
  JsonMap toJson() => {
    'width': _n(width),
    'style': style.json,
    'color': _hex(color),
  };
}

/// Per-side borders.
final class BordersPt with ResolvedValue {
  /// Creates borders.
  const BordersPt({
    this.top = BorderPt.none,
    this.right = BorderPt.none,
    this.bottom = BorderPt.none,
    this.left = BorderPt.none,
  });

  /// No borders.
  static const none = BordersPt();

  /// Top border.
  final BorderPt top;

  /// Right border.
  final BorderPt right;

  /// Bottom border.
  final BorderPt bottom;

  /// Left border.
  final BorderPt left;

  /// Whether any side is visible.
  bool get hasAny =>
      top.isVisible || right.isVisible || bottom.isVisible || left.isVisible;

  /// Whether all sides are equal.
  bool get isUniform => top == right && top == bottom && top == left;

  /// Visible widths per side (0 for invisible sides).
  EdgesPt get widths => EdgesPt(
    top: top.isVisible ? top.width : 0,
    right: right.isVisible ? right.width : 0,
    bottom: bottom.isVisible ? bottom.width : 0,
    left: left.isVisible ? left.width : 0,
  );

  @override
  JsonMap toJson() => {
    'top': top.toJson(),
    'right': right.toJson(),
    'bottom': bottom.toJson(),
    'left': left.toJson(),
  };
}

/// Concrete typography (TextStyleProps, 06 §2.4).
final class ResolvedTextStyle with ResolvedValue {
  /// Creates a text style.
  const ResolvedTextStyle({
    required this.fontFamily,
    required this.fontSize,
    required this.fontWeight,
    required this.italic,
    required this.lineHeight,
    required this.letterSpacing,
    required this.color,
    required this.caseTransform,
    required this.fontFeatures,
  });

  /// Concrete family name (registry spelling).
  final String fontFamily;

  /// Font size in pt.
  final double fontSize;

  /// Weight, snapped to a shipped weight of [fontFamily].
  final int fontWeight;

  /// Whether italic.
  final bool italic;

  /// Line height multiplier of [fontSize].
  final double lineHeight;

  /// Letter spacing in pt.
  final double letterSpacing;

  /// ARGB text color.
  final int color;

  /// Case transform.
  final CaseTransform caseTransform;

  /// OpenType feature tags (e.g. `onum`; `smcp` is implied by
  /// [CaseTransform.smallCaps] and not listed).
  final List<String> fontFeatures;

  /// Line height in pt (`fontSize × lineHeight`).
  double get lineHeightPt => fontSize * lineHeight;

  /// WCAG large text: ≥ 18pt, or ≥ 14pt with weight ≥ 700 (06 §10.6).
  bool get isLargeText =>
      fontSize >= 18 || (fontSize >= 14 && fontWeight >= 700);

  /// A copy with the given values replaced.
  ResolvedTextStyle copyWith({
    String? fontFamily,
    double? fontSize,
    int? fontWeight,
    bool? italic,
    double? lineHeight,
    double? letterSpacing,
    int? color,
    CaseTransform? caseTransform,
    List<String>? fontFeatures,
  }) => ResolvedTextStyle(
    fontFamily: fontFamily ?? this.fontFamily,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    italic: italic ?? this.italic,
    lineHeight: lineHeight ?? this.lineHeight,
    letterSpacing: letterSpacing ?? this.letterSpacing,
    color: color ?? this.color,
    caseTransform: caseTransform ?? this.caseTransform,
    fontFeatures: fontFeatures ?? this.fontFeatures,
  );

  /// The font face this style uses.
  FontFaceKey get faceKey =>
      FontFaceKey(fontFamily, fontWeight, italic: italic);

  @override
  JsonMap toJson() => {
    'fontFamily': fontFamily,
    'fontSize': _n(fontSize),
    'fontWeight': fontWeight,
    'italic': italic,
    'lineHeight': _n(lineHeight),
    'letterSpacing': _n(letterSpacing),
    'color': _hex(color),
    'caseTransform': caseTransform.json,
    'fontFeatures': fontFeatures,
  };
}

/// Concrete box / block properties (BlockProps, 06 §2.4).
final class ResolvedBox with ResolvedValue {
  /// Creates a box.
  const ResolvedBox({
    this.spaceBefore = 0,
    this.spaceAfter = 0,
    this.padding = EdgesPt.zero,
    this.background,
    this.border = BordersPt.none,
    this.borderRadius = 0,
    this.align = ThemeAlign.left,
    this.keepWithNext = false,
    this.pageBreakBefore = false,
  });

  /// Space above the block in pt (collapses with the previous block's
  /// [spaceAfter], see `collapsedSpacing`).
  final double spaceBefore;

  /// Space below the block in pt.
  final double spaceAfter;

  /// Inner padding in pt.
  final EdgesPt padding;

  /// ARGB background, or `null` for none.
  final int? background;

  /// Borders.
  final BordersPt border;

  /// Corner radius in pt.
  final double borderRadius;

  /// Text alignment.
  final ThemeAlign align;

  /// Keep with the next block when paginating.
  final bool keepWithNext;

  /// Start a new page before this block (print/export only).
  final bool pageBreakBefore;

  @override
  JsonMap toJson() => {
    'spaceBefore': _n(spaceBefore),
    'spaceAfter': _n(spaceAfter),
    'padding': padding.toJson(),
    'background': _hex(background),
    'border': border.toJson(),
    'borderRadius': _n(borderRadius),
    'align': align.json,
    'keepWithNext': keepWithNext,
    'pageBreakBefore': pageBreakBefore,
  };
}

/// Body text / paragraphs.
final class ResolvedText with ResolvedValue {
  /// Creates body text style.
  const ResolvedText({
    required this.style,
    required this.box,
    this.firstLineIndent = 0,
  });

  /// Typography.
  final ResolvedTextStyle style;

  /// Block properties (paragraph spacing, alignment `left`/`justify`).
  final ResolvedBox box;

  /// First-line indent in pt (P2, 06 §6.5).
  final double firstLineIndent;

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'box': box.toJson(),
    'firstLineIndent': _n(firstLineIndent),
  };
}

/// One heading level.
final class ResolvedHeading with ResolvedValue {
  /// Creates a heading style.
  const ResolvedHeading({
    required this.level,
    required this.style,
    required this.box,
    this.borderBottom,
    this.borderBottomGap = 0,
  });

  /// Level 1–6.
  final int level;

  /// Typography.
  final ResolvedTextStyle style;

  /// Block properties (keepWithNext defaults to true for headings).
  final ResolvedBox box;

  /// Bottom border line, or `null` for none.
  final BorderPt? borderBottom;

  /// Gap between the text and [borderBottom] in pt.
  final double borderBottomGap;

  @override
  JsonMap toJson() => {
    'level': level,
    'style': style.toJson(),
    'box': box.toJson(),
    'borderBottom': borderBottom?.toJson(),
    'borderBottomGap': _n(borderBottomGap),
  };
}

/// Heading numbering configuration (06 §2.4 `headings.numbering`).
final class ResolvedHeadingNumbering with ResolvedValue {
  /// Creates the configuration.
  const ResolvedHeadingNumbering({
    this.enabled = false,
    this.fromLevel = 1,
    this.toLevel = 6,
    this.style = HeadingNumberingStyle.decimal,
    this.suffix = ' ',
  });

  /// Whether headings are numbered.
  final bool enabled;

  /// First numbered level (1–6).
  final int fromLevel;

  /// Last numbered level (1–6).
  final int toLevel;

  /// Label style.
  final HeadingNumberingStyle style;

  /// Text between label and heading text (a leading `.` is dropped when the
  /// label already ends with a dot).
  final String suffix;

  /// Whether headings of [level] get a label.
  bool numbers(int level) => enabled && level >= fromLevel && level <= toLevel;

  @override
  JsonMap toJson() => {
    'enabled': enabled,
    'fromLevel': fromLevel,
    'toLevel': toLevel,
    'style': style.json,
    'suffix': suffix,
  };
}

/// Spacing override for a paragraph directly after a heading; `null` =
/// keep the paragraph's own value.
final class ResolvedSpacingOverride with ResolvedValue {
  /// Creates the override.
  const ResolvedSpacingOverride({this.spaceBefore, this.spaceAfter});

  /// Space before in pt.
  final double? spaceBefore;

  /// Space after in pt.
  final double? spaceAfter;

  /// Whether nothing is overridden.
  bool get isEmpty => spaceBefore == null && spaceAfter == null;

  @override
  JsonMap toJson() => {
    'spaceBefore': spaceBefore == null ? null : _n(spaceBefore!),
    'spaceAfter': spaceAfter == null ? null : _n(spaceAfter!),
  };
}

/// Bold or italic: a delta over the surrounding text style; `null` fields
/// keep the surrounding value.
final class ResolvedInline with ResolvedValue {
  /// Creates an inline delta.
  const ResolvedInline({
    this.fontWeight,
    this.italic,
    this.oblique = false,
    this.color,
  });

  /// Weight to apply (bold).
  final int? fontWeight;

  /// Italic to apply (italic).
  final bool? italic;

  /// Synthetic slant even if the family has an italic face (06 §2.4).
  final bool oblique;

  /// Text color override.
  final int? color;

  @override
  JsonMap toJson() => {
    'fontWeight': fontWeight,
    'italic': italic,
    'oblique': oblique,
    'color': _hex(color),
  };
}

/// Strikethrough delta.
final class ResolvedStrike with ResolvedValue {
  /// Creates a strike style.
  const ResolvedStrike({
    this.color,
    this.lineColor,
    required this.lineThickness,
  });

  /// Text color of struck text, or `null` to keep.
  final int? color;

  /// Line color, or `null` = current text color.
  final int? lineColor;

  /// Line thickness in pt.
  final double lineThickness;

  @override
  JsonMap toJson() => {
    'color': _hex(color),
    'lineColor': _hex(lineColor),
    'lineThickness': _n(lineThickness),
  };
}

/// Inline code.
final class ResolvedInlineCode with ResolvedValue {
  /// Creates an inline code style.
  const ResolvedInlineCode({
    required this.fontFamily,
    required this.sizeRatio,
    required this.fontWeight,
    required this.italic,
    required this.letterSpacingEm,
    required this.fontFeatures,
    required this.color,
    required this.background,
    required this.paddingX,
    required this.borderRadius,
    this.border,
  });

  /// Concrete mono family.
  final String fontFamily;

  /// Font size relative to the surrounding text.
  final double sizeRatio;

  /// Weight (snapped for [fontFamily]).
  final int fontWeight;

  /// Whether italic.
  final bool italic;

  /// Letter spacing in em of the code font size.
  final double letterSpacingEm;

  /// OpenType features.
  final List<String> fontFeatures;

  /// ARGB text color.
  final int color;

  /// ARGB chip background, or `null`.
  final int? background;

  /// Horizontal chip padding in pt.
  final double paddingX;

  /// Chip corner radius in pt.
  final double borderRadius;

  /// Chip border, or `null`.
  final BorderPt? border;

  @override
  JsonMap toJson() => {
    'fontFamily': fontFamily,
    'sizeRatio': _n(sizeRatio),
    'fontWeight': fontWeight,
    'italic': italic,
    'letterSpacingEm': _n(letterSpacingEm),
    'fontFeatures': fontFeatures,
    'color': _hex(color),
    'background': _hex(background),
    'paddingX': _n(paddingX),
    'borderRadius': _n(borderRadius),
    'border': border?.toJson(),
  };
}

/// Links.
final class ResolvedLink with ResolvedValue {
  /// Creates a link style.
  const ResolvedLink({
    required this.color,
    required this.hoverColor,
    required this.underline,
    required this.underlineStyle,
    required this.underlineThickness,
  });

  /// ARGB text color.
  final int color;

  /// ARGB hover color.
  final int hoverColor;

  /// Underline mode.
  final LinkUnderline underline;

  /// Underline line style (`solid`, `dotted`, `dashed`).
  final LineStyle underlineStyle;

  /// Underline thickness in pt.
  final double underlineThickness;

  @override
  JsonMap toJson() => {
    'color': _hex(color),
    'hoverColor': _hex(hoverColor),
    'underline': underline.json,
    'underlineStyle': underlineStyle.json,
    'underlineThickness': _n(underlineThickness),
  };
}

/// Mentions.
final class ResolvedMention with ResolvedValue {
  /// Creates a mention style.
  const ResolvedMention({
    required this.color,
    required this.background,
    required this.borderRadius,
    required this.fontWeight,
    required this.prefix,
  });

  /// ARGB text color.
  final int color;

  /// ARGB chip background, or `null`.
  final int? background;

  /// Chip radius in pt.
  final double borderRadius;

  /// Weight (snapped for the body family).
  final int fontWeight;

  /// Prefix shown before the name (`"@"` or `""`).
  final String prefix;

  @override
  JsonMap toJson() => {
    'color': _hex(color),
    'background': _hex(background),
    'borderRadius': _n(borderRadius),
    'fontWeight': fontWeight,
    'prefix': prefix,
  };
}

/// Blockquotes. Total left inset = `bar.width` (when visible) +
/// `box.padding.left`.
final class ResolvedBlockquote with ResolvedValue {
  /// Creates a blockquote style.
  const ResolvedBlockquote({
    required this.style,
    required this.box,
    required this.bar,
  });

  /// Typography (`italic` already applied).
  final ResolvedTextStyle style;

  /// Block properties.
  final ResolvedBox box;

  /// The left bar.
  final BorderPt bar;

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'box': box.toJson(),
    'bar': bar.toJson(),
  };
}

/// Code blocks.
final class ResolvedCodeBlock with ResolvedValue {
  /// Creates a code block style.
  const ResolvedCodeBlock({
    required this.style,
    required this.box,
    required this.wrap,
    required this.showLanguageLabel,
    required this.tabSize,
    required this.lineNumbers,
  });

  /// Typography (mono).
  final ResolvedTextStyle style;

  /// Block properties (background = code background).
  final ResolvedBox box;

  /// Editor: wrap long lines (exports always wrap).
  final bool wrap;

  /// Show the language label.
  final bool showLanguageLabel;

  /// Tab width in spaces (2–8).
  final int tabSize;

  /// Show line numbers (P2).
  final bool lineNumbers;

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'box': box.toJson(),
    'wrap': wrap,
    'showLanguageLabel': showLanguageLabel,
    'tabSize': tabSize,
    'lineNumbers': lineNumbers,
  };
}

/// Bullet and ordered lists (9 indent levels, 0–8).
final class ResolvedList with ResolvedValue {
  /// Creates a list style.
  const ResolvedList({
    required this.style,
    required this.box,
    required this.bullets,
    required this.bulletColor,
    required this.bulletScale,
    required this.numbering,
    required this.numberSuffix,
    required this.numberColor,
    required this.indentPerLevel,
    required this.markerGap,
    required this.itemSpacing,
  });

  /// Item text typography (= body).
  final ResolvedTextStyle style;

  /// Spacing around a list run (`spaceBefore`/`spaceAfter`) etc.
  final ResolvedBox box;

  /// Bullet glyph per level (9 entries).
  final List<String> bullets;

  /// ARGB bullet color.
  final int bulletColor;

  /// Bullet size relative to the text.
  final double bulletScale;

  /// Number style per level (9 entries).
  final List<ListNumberStyle> numbering;

  /// `"."` or `")"`.
  final String numberSuffix;

  /// ARGB number color.
  final int numberColor;

  /// Indent per level in pt.
  final double indentPerLevel;

  /// Gap between marker and text in pt.
  final double markerGap;

  /// Space between items in pt.
  final double itemSpacing;

  /// Bullet glyph of [level] (clamped to 0–8).
  String bulletFor(int level) => bullets[level.clamp(0, 8)];

  /// Number style of [level] (clamped to 0–8).
  ListNumberStyle numberStyleFor(int level) => numbering[level.clamp(0, 8)];

  /// Marker text of an ordered item, e.g. `"iv."` for level 2, ordinal 4.
  String numberMarker(int level, int ordinal) =>
      ListMarkers.ordinal(ordinal, numberStyleFor(level)) + numberSuffix;

  /// Left indent of the item text at [level] in pt.
  double indentFor(int level) => indentPerLevel * (level.clamp(0, 8) + 1);

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'box': box.toJson(),
    'bullets': bullets,
    'bulletColor': _hex(bulletColor),
    'bulletScale': _n(bulletScale),
    'numbering': [for (final n in numbering) n.json],
    'numberSuffix': numberSuffix,
    'numberColor': _hex(numberColor),
    'indentPerLevel': _n(indentPerLevel),
    'markerGap': _n(markerGap),
    'itemSpacing': _n(itemSpacing),
  };
}

/// Task checkbox.
final class ResolvedCheckbox with ResolvedValue {
  /// Creates a checkbox style.
  const ResolvedCheckbox({
    required this.shape,
    required this.size,
    required this.borderColor,
    required this.checkedFill,
    required this.checkColor,
  });

  /// Shape.
  final CheckboxShape shape;

  /// Box size in pt.
  final double size;

  /// ARGB border color.
  final int borderColor;

  /// ARGB fill when checked.
  final int checkedFill;

  /// ARGB check mark color.
  final int checkColor;

  @override
  JsonMap toJson() => {
    'shape': shape.json,
    'size': _n(size),
    'borderColor': _hex(borderColor),
    'checkedFill': _hex(checkedFill),
    'checkColor': _hex(checkColor),
  };
}

/// Task lists (indent/marker gap/item spacing come from [ResolvedList]).
final class ResolvedTask with ResolvedValue {
  /// Creates a task style.
  const ResolvedTask({
    required this.style,
    required this.box,
    required this.checkbox,
    required this.checkedStrike,
    required this.checkedOpacity,
    required this.checkedColor,
  });

  /// Item text typography (= body).
  final ResolvedTextStyle style;

  /// Spacing around a task run.
  final ResolvedBox box;

  /// Checkbox.
  final ResolvedCheckbox checkbox;

  /// Strike checked item text.
  final bool checkedStrike;

  /// Opacity 0–1 of checked item text.
  final double checkedOpacity;

  /// ARGB color of checked text (before [checkedOpacity]).
  final int checkedColor;

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'box': box.toJson(),
    'checkbox': checkbox.toJson(),
    'checkedStrike': checkedStrike,
    'checkedOpacity': _n(checkedOpacity),
    'checkedColor': _hex(checkedColor),
  };
}

/// A width either relative to the content width or absolute.
final class ResolvedExtent with ResolvedValue {
  /// A fraction 0–1 of the content width.
  const ResolvedExtent.fraction(double this.fraction) : points = null;

  /// An absolute width in pt.
  const ResolvedExtent.points(double this.points) : fraction = null;

  /// Fraction of the content width, or `null`.
  final double? fraction;

  /// Absolute pt, or `null`.
  final double? points;

  /// The width in pt for a content box of [contentWidth] pt (absolute
  /// values are capped at the content width).
  double resolve(double contentWidth) => fraction != null
      ? fraction! * contentWidth
      : (points! < contentWidth ? points! : contentWidth);

  /// CSS form (`60%` or `<n>pt`).
  String toCss() => fraction != null
      ? '${formatThemeNumber(_n(fraction! * 100))}%'
      : '${formatThemeNumber(_n(points!))}pt';

  @override
  JsonMap toJson() => {
    'fraction': fraction == null ? null : _n(fraction!),
    'points': points == null ? null : _n(points!),
  };
}

/// Horizontal rules.
final class ResolvedRule with ResolvedValue {
  /// Creates a rule style.
  const ResolvedRule({
    required this.box,
    required this.style,
    required this.thickness,
    required this.color,
    required this.width,
    required this.ornament,
    required this.ornamentStyle,
  });

  /// Spacing.
  final ResolvedBox box;

  /// Line style or ornament.
  final RuleStyle style;

  /// Line thickness in pt.
  final double thickness;

  /// ARGB line / ornament color.
  final int color;

  /// Rule width.
  final ResolvedExtent width;

  /// Ornament glyph(s) for [RuleStyle.ornament].
  final String ornament;

  /// Typography of the ornament (body style in [color], centered).
  final ResolvedTextStyle ornamentStyle;

  @override
  JsonMap toJson() => {
    'box': box.toJson(),
    'style': style.json,
    'thickness': _n(thickness),
    'color': _hex(color),
    'width': width.toJson(),
    'ornament': ornament,
    'ornamentStyle': ornamentStyle.toJson(),
  };
}

/// Image captions (text = image `title`).
final class ResolvedCaption with ResolvedValue {
  /// Creates a caption style.
  const ResolvedCaption({
    required this.show,
    required this.style,
    required this.align,
    required this.gap,
  });

  /// Whether captions are shown.
  final bool show;

  /// Typography.
  final ResolvedTextStyle style;

  /// Alignment.
  final ThemeAlign align;

  /// Gap between image and caption in pt.
  final double gap;

  @override
  JsonMap toJson() => {
    'show': show,
    'style': style.toJson(),
    'align': align.json,
    'gap': _n(gap),
  };
}

/// Images (named `…Style` to avoid clashing with the exporters'
/// `ResolvedImage` bytes type, 07 §2.2).
final class ResolvedImageStyle with ResolvedValue {
  /// Creates an image style.
  const ResolvedImageStyle({
    required this.box,
    required this.maxWidth,
    required this.align,
    required this.borderRadius,
    this.border,
    required this.shadow,
    required this.caption,
  });

  /// Spacing.
  final ResolvedBox box;

  /// Maximum width.
  final ResolvedExtent maxWidth;

  /// Alignment.
  final ImageAlign align;

  /// Corner radius in pt.
  final double borderRadius;

  /// Border, or `null`.
  final BorderPt? border;

  /// Shadow.
  final ShadowLevel shadow;

  /// Caption style.
  final ResolvedCaption caption;

  @override
  JsonMap toJson() => {
    'box': box.toJson(),
    'maxWidth': maxWidth.toJson(),
    'align': align.json,
    'borderRadius': _n(borderRadius),
    'border': border?.toJson(),
    'shadow': shadow.json,
    'caption': caption.toJson(),
  };
}

/// Tables.
final class ResolvedTable with ResolvedValue {
  /// Creates a table style.
  const ResolvedTable({
    required this.style,
    required this.headerStyle,
    required this.box,
    required this.width,
    required this.headerBackground,
    required this.borders,
    required this.borderColor,
    required this.borderWidth,
    required this.zebra,
    required this.zebraColor,
    required this.cellPadding,
  });

  /// Cell text typography (size includes `fontSizeRatio`).
  final ResolvedTextStyle style;

  /// Header cell typography (header color and weight applied).
  final ResolvedTextStyle headerStyle;

  /// Spacing etc.
  final ResolvedBox box;

  /// Width mode.
  final TableWidth width;

  /// ARGB header row background, or `null`.
  final int? headerBackground;

  /// Which borders are drawn.
  final TableBorders borders;

  /// ARGB border color.
  final int borderColor;

  /// Border width in pt.
  final double borderWidth;

  /// Zebra striping of body rows.
  final bool zebra;

  /// ARGB stripe color (every second body row), or `null`.
  final int? zebraColor;

  /// Cell padding in pt.
  final EdgesPt cellPadding;

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'headerStyle': headerStyle.toJson(),
    'box': box.toJson(),
    'width': width.json,
    'headerBackground': _hex(headerBackground),
    'borders': borders.json,
    'borderColor': _hex(borderColor),
    'borderWidth': _n(borderWidth),
    'zebra': zebra,
    'zebraColor': _hex(zebraColor),
    'cellPadding': cellPadding.toJson(),
  };
}

/// Page header or footer typography (content comes from page setup).
final class ResolvedHeaderFooter with ResolvedValue {
  /// Creates a header/footer style.
  const ResolvedHeaderFooter({
    required this.style,
    required this.align,
    this.borderBottom,
    this.borderTop,
  });

  /// Typography.
  final ResolvedTextStyle style;

  /// Default alignment of single-slot content.
  final ThemeAlign align;

  /// Line below (headers), or `null`.
  final BorderPt? borderBottom;

  /// Line above (footers), or `null`.
  final BorderPt? borderTop;

  @override
  JsonMap toJson() => {
    'style': style.toJson(),
    'align': align.json,
    'borderBottom': borderBottom?.toJson(),
    'borderTop': borderTop?.toJson(),
  };
}

/// Page surface and geometry defaults (06 §2.3).
final class ResolvedPage with ResolvedValue {
  /// Creates a page style.
  const ResolvedPage({
    required this.paperColor,
    required this.canvasColor,
    required this.pageShadow,
    required this.pagelessMaxWidth,
    required this.pagelessPadding,
    required this.defaultMargins,
  });

  /// ARGB page surface (Pages) / content background (Pageless).
  final int paperColor;

  /// ARGB area around pages.
  final int canvasColor;

  /// Editor page shadow.
  final ShadowLevel pageShadow;

  /// Pageless max content width in pt (`760px` = 570pt).
  final double pagelessMaxWidth;

  /// Pageless padding in pt.
  final EdgesPt pagelessPadding;

  /// Default page margins in pt (page setup `margins: "theme"`).
  final EdgesPt defaultMargins;

  @override
  JsonMap toJson() => {
    'paperColor': _hex(paperColor),
    'canvasColor': _hex(canvasColor),
    'pageShadow': pageShadow.json,
    'pagelessMaxWidth': _n(pagelessMaxWidth),
    'pagelessPadding': pagelessPadding.toJson(),
    'defaultMargins': defaultMargins.toJson(),
  };
}

/// Style of one syntax token.
final class ResolvedTokenStyle with ResolvedValue {
  /// Creates a token style.
  const ResolvedTokenStyle({
    required this.color,
    this.italic = false,
    this.fontWeight,
  });

  /// ARGB color.
  final int color;

  /// Whether italic.
  final bool italic;

  /// Weight, or `null` = code block weight.
  final int? fontWeight;

  @override
  JsonMap toJson() => {
    'color': _hex(color),
    'italic': italic,
    'fontWeight': fontWeight,
  };
}

/// Overlay overrides; `null` = use the app token (06 §2.6).
final class ResolvedOverlays with ResolvedValue {
  /// Creates overlays.
  const ResolvedOverlays({
    this.selection,
    this.caretColor,
    this.caretWidth,
    this.commentHighlight,
    this.commentHighlightActive,
    this.suggestionInsert,
    this.suggestionDelete,
    this.findMatch,
    this.findMatchActive,
  });

  /// Selection color.
  final int? selection;

  /// Caret color.
  final int? caretColor;

  /// Caret width in pt.
  final double? caretWidth;

  /// Open comment highlight.
  final int? commentHighlight;

  /// Active comment highlight.
  final int? commentHighlightActive;

  /// Suggested insertion.
  final int? suggestionInsert;

  /// Suggested deletion.
  final int? suggestionDelete;

  /// Find match.
  final int? findMatch;

  /// Active find match.
  final int? findMatchActive;

  @override
  JsonMap toJson() => {
    'selection': _hex(selection),
    'caretColor': _hex(caretColor),
    'caretWidth': caretWidth == null ? null : _n(caretWidth!),
    'commentHighlight': _hex(commentHighlight),
    'commentHighlightActive': _hex(commentHighlightActive),
    'suggestionInsert': _hex(suggestionInsert),
    'suggestionDelete': _hex(suggestionDelete),
    'findMatch': _hex(findMatch),
    'findMatchActive': _hex(findMatchActive),
  };
}

/// Concrete families of the font roles.
final class ResolvedFonts with ResolvedValue {
  /// Creates the fonts.
  const ResolvedFonts({
    required this.body,
    required this.heading,
    required this.mono,
  });

  /// Body family.
  final String body;

  /// Heading family.
  final String heading;

  /// Mono family.
  final String mono;

  @override
  JsonMap toJson() => {'body': body, 'heading': heading, 'mono': mono};
}

/// The fully resolved theme for one variant (06 §3). Never persisted.
final class ResolvedWriteTheme with ResolvedValue {
  /// Creates a resolved theme (normally built by `ThemeResolver`).
  const ResolvedWriteTheme({
    required this.variant,
    required this.name,
    required this.fonts,
    required this.palette,
    required this.page,
    required this.body,
    required this.headings,
    required this.headingNumbering,
    required this.paragraphAfterHeading,
    required this.bold,
    required this.italic,
    required this.strike,
    required this.inlineCode,
    required this.link,
    required this.mention,
    required this.blockquote,
    required this.codeBlock,
    required this.list,
    required this.task,
    required this.rule,
    required this.image,
    required this.table,
    required this.wonky,
    required this.header,
    required this.footer,
    required this.syntax,
    required this.overlays,
    required this.themeHash,
    required this.contentHash,
  });

  /// The variant.
  final ThemeVariant variant;

  /// Theme name.
  final String name;

  /// Role families.
  final ResolvedFonts fonts;

  /// The resolved palette of this variant (ARGB; unset custom keys absent).
  final Map<PaletteKey, int> palette;

  /// Page.
  final ResolvedPage page;

  /// Body text / paragraphs.
  final ResolvedText body;

  /// Headings, index 0 = h1.
  final List<ResolvedHeading> headings;

  /// Heading numbering.
  final ResolvedHeadingNumbering headingNumbering;

  /// Paragraph-after-heading spacing override.
  final ResolvedSpacingOverride paragraphAfterHeading;

  /// Bold delta.
  final ResolvedInline bold;

  /// Italic delta.
  final ResolvedInline italic;

  /// Strike delta.
  final ResolvedStrike strike;

  /// Inline code.
  final ResolvedInlineCode inlineCode;

  /// Links.
  final ResolvedLink link;

  /// Mentions.
  final ResolvedMention mention;

  /// Blockquotes.
  final ResolvedBlockquote blockquote;

  /// Code blocks.
  final ResolvedCodeBlock codeBlock;

  /// Lists.
  final ResolvedList list;

  /// Task lists.
  final ResolvedTask task;

  /// Rules.
  final ResolvedRule rule;

  /// Images.
  final ResolvedImageStyle image;

  /// Tables.
  final ResolvedTable table;

  /// Wonky Markdown elements (Write 11 §8).
  final ResolvedWonkyElements wonky;

  /// Page header.
  final ResolvedHeaderFooter header;

  /// Page footer.
  final ResolvedHeaderFooter footer;

  /// Syntax token styles (complete: every token has a style).
  final Map<SyntaxToken, ResolvedTokenStyle> syntax;

  /// Overlay overrides.
  final ResolvedOverlays overlays;

  /// `contentHash` of the source `WriteThemeData`.
  final String themeHash;

  /// SHA-256 of the source canonical JSON + variant (cache key).
  final String contentHash;

  /// The heading of [level] 1–6.
  ResolvedHeading heading(int level) => headings[level.clamp(1, 6) - 1];

  /// All font faces used by the block and inline styles (for embedding
  /// and `@font-face` generation), sorted. Includes bold/italic variants
  /// of the body and heading families.
  List<FontFaceKey> usedFontFaces() {
    final faces = <FontFaceKey>{};
    void add(ResolvedTextStyle s) {
      faces.add(s.faceKey);
      faces.add(FontFaceKey(s.fontFamily, s.fontWeight, italic: !s.italic));
    }

    add(body.style);
    final boldWeight = bold.fontWeight ?? 700;
    faces.add(FontFaceKey(body.style.fontFamily, boldWeight));
    faces.add(FontFaceKey(body.style.fontFamily, boldWeight, italic: true));
    for (final h in headings) {
      add(h.style);
    }
    add(blockquote.style);
    add(codeBlock.style);
    for (final t in syntax.values) {
      if (t.fontWeight != null) {
        faces.add(
          FontFaceKey(
            codeBlock.style.fontFamily,
            t.fontWeight!,
            italic: t.italic,
          ),
        );
      } else if (t.italic) {
        faces.add(
          FontFaceKey(
            codeBlock.style.fontFamily,
            codeBlock.style.fontWeight,
            italic: true,
          ),
        );
      }
    }
    faces.add(
      FontFaceKey(
        inlineCode.fontFamily,
        inlineCode.fontWeight,
        italic: inlineCode.italic,
      ),
    );
    faces.add(FontFaceKey(body.style.fontFamily, mention.fontWeight));
    faces.add(FontFaceKey(body.style.fontFamily, wonky.button.fontWeight));
    faces.add(FontFaceKey(body.style.fontFamily, wonky.button.arrowWeight));
    faces.add(FontFaceKey(body.style.fontFamily, wonky.chip.fontWeight));
    faces.add(FontFaceKey(body.style.fontFamily, wonky.details.summaryWeight));
    add(table.style);
    faces.add(table.headerStyle.faceKey);
    faces.add(image.caption.style.faceKey);
    faces.add(header.style.faceKey);
    faces.add(footer.style.faceKey);
    return faces.toList()..sort();
  }

  @override
  JsonMap toJson() => {
    'variant': variant.json,
    'name': name,
    'fonts': fonts.toJson(),
    'palette': {for (final e in palette.entries) e.key.name: _hex(e.value)},
    'page': page.toJson(),
    'body': body.toJson(),
    'headings': [for (final h in headings) h.toJson()],
    'headingNumbering': headingNumbering.toJson(),
    'paragraphAfterHeading': paragraphAfterHeading.toJson(),
    'bold': bold.toJson(),
    'italic': italic.toJson(),
    'strike': strike.toJson(),
    'inlineCode': inlineCode.toJson(),
    'link': link.toJson(),
    'mention': mention.toJson(),
    'blockquote': blockquote.toJson(),
    'codeBlock': codeBlock.toJson(),
    'list': list.toJson(),
    'task': task.toJson(),
    'rule': rule.toJson(),
    'image': image.toJson(),
    'table': table.toJson(),
    'wonky': wonky.toJson(),
    'header': header.toJson(),
    'footer': footer.toJson(),
    'syntax': {for (final e in syntax.entries) e.key.name: e.value.toJson()},
    'overlays': overlays.toJson(),
    'themeHash': themeHash,
    'contentHash': contentHash,
  };

  @override
  bool operator ==(Object other) =>
      other is ResolvedWriteTheme && other.contentHash == contentHash;

  @override
  int get hashCode => contentHash.hashCode;
}

// ---------------------------------------------------------------------------
// Wonky Markdown elements (Write 11 §8).

/// The colors of one callout type.
final class ResolvedCalloutColors with ResolvedValue {
  /// Creates callout colors.
  const ResolvedCalloutColors({
    required this.color,
    required this.background,
    required this.border,
    required this.title,
  });

  /// The type's hue (icon).
  final int color;

  /// ARGB box fill.
  final int background;

  /// ARGB border.
  final int border;

  /// ARGB title (label and icon) color.
  final int title;

  @override
  JsonMap toJson() => {
    'color': _hex(color),
    'background': _hex(background),
    'border': _hex(border),
    'titleColor': _hex(title),
  };
}

/// Callouts.
final class ResolvedCallout with ResolvedValue {
  /// Creates a callout style.
  const ResolvedCallout({
    required this.spaceBefore,
    required this.spaceAfter,
    required this.padding,
    required this.borderRadius,
    required this.borderWidth,
    required this.titleCase,
    required this.titleSizeRatio,
    required this.titleWeight,
    required this.variants,
  });

  /// Space before in pt.
  final double spaceBefore;

  /// Space after in pt.
  final double spaceAfter;

  /// Inner padding in pt.
  final EdgesPt padding;

  /// Corner radius in pt.
  final double borderRadius;

  /// Border width in pt.
  final double borderWidth;

  /// Case transform of the title.
  final CaseTransform titleCase;

  /// Title size relative to the body size.
  final double titleSizeRatio;

  /// Title weight.
  final int titleWeight;

  /// Colors per type (`info`, `tip`, `note`, `warning`, `danger`).
  final Map<String, ResolvedCalloutColors> variants;

  /// The colors of callout type [variant] (`caution` uses `warning`).
  ResolvedCalloutColors colorsFor(String variant) =>
      variants[variant == 'caution' ? 'warning' : variant] ?? variants['note']!;

  @override
  JsonMap toJson() => {
    'spaceBefore': _n(spaceBefore),
    'spaceAfter': _n(spaceAfter),
    'padding': padding.toJson(),
    'borderRadius': _n(borderRadius),
    'borderWidth': _n(borderWidth),
    'titleCaseTransform': titleCase.json,
    'titleSizeRatio': _n(titleSizeRatio),
    'titleWeight': titleWeight,
    for (final e in variants.entries) e.key: e.value.toJson(),
  };
}

/// Details.
final class ResolvedDetails with ResolvedValue {
  /// Creates a details style.
  const ResolvedDetails({
    required this.spaceBefore,
    required this.spaceAfter,
    required this.padding,
    required this.background,
    required this.border,
    required this.borderRadius,
    required this.summaryWeight,
    required this.chevronColor,
  });

  /// Space before in pt.
  final double spaceBefore;

  /// Space after in pt.
  final double spaceAfter;

  /// Inner padding in pt.
  final EdgesPt padding;

  /// ARGB fill, or `null`.
  final int? background;

  /// Border.
  final BorderPt border;

  /// Corner radius in pt.
  final double borderRadius;

  /// Summary weight.
  final int summaryWeight;

  /// ARGB chevron color.
  final int chevronColor;

  @override
  JsonMap toJson() => {
    'spaceBefore': _n(spaceBefore),
    'spaceAfter': _n(spaceAfter),
    'padding': padding.toJson(),
    'background': _hex(background),
    'border': border.toJson(),
    'borderRadius': _n(borderRadius),
    'summaryWeight': summaryWeight,
    'chevronColor': _hex(chevronColor),
  };
}

/// Cards.
final class ResolvedCard with ResolvedValue {
  /// Creates a card style.
  const ResolvedCard({
    required this.spaceBefore,
    required this.spaceAfter,
    required this.padding,
    required this.background,
    required this.borderRadius,
    required this.shadow,
  });

  /// Space before in pt.
  final double spaceBefore;

  /// Space after in pt.
  final double spaceAfter;

  /// Inner padding in pt.
  final EdgesPt padding;

  /// ARGB fill, or `null`.
  final int? background;

  /// Corner radius in pt.
  final double borderRadius;

  /// Whether the card casts a soft shadow.
  final bool shadow;

  @override
  JsonMap toJson() => {
    'spaceBefore': _n(spaceBefore),
    'spaceAfter': _n(spaceAfter),
    'padding': padding.toJson(),
    'background': _hex(background),
    'borderRadius': _n(borderRadius),
    'shadow': shadow ? 'soft' : 'none',
  };
}

/// Grids.
final class ResolvedGrid with ResolvedValue {
  /// Creates a grid style.
  const ResolvedGrid({
    required this.spaceBefore,
    required this.spaceAfter,
    required this.bulletColor,
    required this.columnGap,
    required this.rowGap,
  });

  /// Space before in pt.
  final double spaceBefore;

  /// Space after in pt.
  final double spaceAfter;

  /// ARGB bullet color.
  final int bulletColor;

  /// Gap between columns in pt.
  final double columnGap;

  /// Gap between rows in pt.
  final double rowGap;

  @override
  JsonMap toJson() => {
    'spaceBefore': _n(spaceBefore),
    'spaceAfter': _n(spaceAfter),
    'bulletColor': _hex(bulletColor),
    'columnGap': _n(columnGap),
    'rowGap': _n(rowGap),
  };
}

/// Buttons and arrow links.
final class ResolvedButton with ResolvedValue {
  /// Creates a button style.
  const ResolvedButton({
    required this.background,
    required this.color,
    required this.secondaryBackground,
    required this.secondaryColor,
    required this.borderRadius,
    required this.fontWeight,
    required this.arrowColor,
    required this.arrowWeight,
  });

  /// ARGB primary fill.
  final int background;

  /// ARGB primary label color.
  final int color;

  /// ARGB secondary fill.
  final int secondaryBackground;

  /// ARGB secondary label color.
  final int secondaryColor;

  /// Corner radius in pt.
  final double borderRadius;

  /// Label weight (snapped for the body family).
  final int fontWeight;

  /// ARGB arrow link color.
  final int arrowColor;

  /// Arrow link weight (snapped for the body family).
  final int arrowWeight;

  @override
  JsonMap toJson() => {
    'background': _hex(background),
    'color': _hex(color),
    'secondaryBackground': _hex(secondaryBackground),
    'secondaryColor': _hex(secondaryColor),
    'borderRadius': _n(borderRadius),
    'fontWeight': fontWeight,
    'arrowColor': _hex(arrowColor),
    'arrowWeight': arrowWeight,
  };
}

/// Chips.
final class ResolvedChip with ResolvedValue {
  /// Creates a chip style.
  const ResolvedChip({
    required this.background,
    required this.color,
    required this.borderRadius,
    required this.fontWeight,
  });

  /// ARGB fill.
  final int background;

  /// ARGB label color.
  final int color;

  /// Corner radius in pt.
  final double borderRadius;

  /// Label weight (snapped for the body family).
  final int fontWeight;

  @override
  JsonMap toJson() => {
    'background': _hex(background),
    'color': _hex(color),
    'borderRadius': _n(borderRadius),
    'fontWeight': fontWeight,
  };
}

/// Numbered heading badges.
final class ResolvedStepBadge with ResolvedValue {
  /// Creates a badge style.
  const ResolvedStepBadge({
    required this.background,
    required this.color,
    required this.sizeRatio,
  });

  /// ARGB fill.
  final int background;

  /// ARGB number color.
  final int color;

  /// Badge diameter relative to the heading's font size.
  final double sizeRatio;

  @override
  JsonMap toJson() => {
    'background': _hex(background),
    'color': _hex(color),
    'sizeRatio': _n(sizeRatio),
  };
}

/// The Wonky Markdown element styles of a theme (Write 11 §8).
final class ResolvedWonkyElements with ResolvedValue {
  /// Creates the styles.
  const ResolvedWonkyElements({
    required this.callout,
    required this.details,
    required this.card,
    required this.grid,
    required this.button,
    required this.chip,
    required this.stepBadge,
  });

  /// Callouts.
  final ResolvedCallout callout;

  /// Details.
  final ResolvedDetails details;

  /// Cards.
  final ResolvedCard card;

  /// Grids.
  final ResolvedGrid grid;

  /// Buttons and arrow links.
  final ResolvedButton button;

  /// Chips.
  final ResolvedChip chip;

  /// Numbered heading badges.
  final ResolvedStepBadge stepBadge;

  @override
  JsonMap toJson() => {
    'callout': callout.toJson(),
    'details': details.toJson(),
    'card': card.toJson(),
    'grid': grid.toJson(),
    'button': button.toJson(),
    'chip': chip.toJson(),
    'stepBadge': stepBadge.toJson(),
  };
}
