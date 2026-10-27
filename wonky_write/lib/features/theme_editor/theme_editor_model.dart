import 'package:wonky_write_core/wonky_write_core.dart' as core;
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        ColorRef,
        FontRef,
        FontRole,
        PaletteKey,
        PropType,
        ObjectProp,
        SyntaxToken,
        ThemeElement,
        ThemePropertyPath,
        ThemeVariant,
        WriteThemeData;

import '../../l10n/write_l10n.dart';

/// Decoded theme JSON.
typedef ThemeJson = Map<String, Object?>;

/// A node of the theme editor's element tree (Write 06 §10.2): a section
/// (Page, Theme colors, Fonts, …) or one element.
enum ThemeNodeKind {
  general,
  palette,
  fonts,
  page,
  element,
  syntax,
  headerFooter,
  advanced,
}

/// One selectable node: `general`, `palette`, `fonts`, `page`, `syntax`,
/// `headerFooter`, `advanced` or `element:<key>`.
class ThemeNode {
  const ThemeNode._(this.kind) : element = null;

  static const general = ThemeNode._(ThemeNodeKind.general);
  static const palette = ThemeNode._(ThemeNodeKind.palette);
  static const fonts = ThemeNode._(ThemeNodeKind.fonts);
  static const page = ThemeNode._(ThemeNodeKind.page);
  static const syntax = ThemeNode._(ThemeNodeKind.syntax);
  static const headerFooter = ThemeNode._(ThemeNodeKind.headerFooter);
  static const advanced = ThemeNode._(ThemeNodeKind.advanced);

  const ThemeNode.element(ThemeElement this.element)
    : kind = ThemeNodeKind.element;

  final ThemeNodeKind kind;
  final ThemeElement? element;

  /// Stable id (`write.theme.selectElement {element}`, widget keys).
  String get id => element == null ? kind.name : element!.name;

  /// Parses [id] (an element key or a section name); null when unknown.
  static ThemeNode? parse(String id) {
    final e = ThemeElement.fromJsonName(id);
    if (e != null) return ThemeNode.element(e);
    for (final k in ThemeNodeKind.values) {
      if (k != ThemeNodeKind.element && k.name == id) return ThemeNode._(k);
    }
    return null;
  }

  /// Display name in the element tree and inspector.
  String label(WriteLocalizations l) => switch (kind) {
    ThemeNodeKind.general => l.themeEditorNodeGeneral,
    ThemeNodeKind.palette => l.themeEditorNodePalette,
    ThemeNodeKind.fonts => l.themeEditorNodeFonts,
    ThemeNodeKind.page => l.themeEditorNodePage,
    ThemeNodeKind.syntax => l.themeEditorNodeSyntax,
    ThemeNodeKind.headerFooter => l.themeEditorNodeHeaderFooter,
    ThemeNodeKind.advanced => l.themeEditorNodeAdvanced,
    ThemeNodeKind.element => elementLabel(l, element!),
  };

  @override
  bool operator ==(Object other) =>
      other is ThemeNode && other.kind == kind && other.element == element;

  @override
  int get hashCode => Object.hash(kind, element);

  @override
  String toString() => 'ThemeNode($id)';
}

/// Display name of [e].
String elementLabel(WriteLocalizations l, ThemeElement e) => switch (e) {
  ThemeElement.body => l.themeElementBody,
  ThemeElement.headings => l.themeElementHeadings,
  ThemeElement.h1 => l.themeElementHeading(1),
  ThemeElement.h2 => l.themeElementHeading(2),
  ThemeElement.h3 => l.themeElementHeading(3),
  ThemeElement.h4 => l.themeElementHeading(4),
  ThemeElement.h5 => l.themeElementHeading(5),
  ThemeElement.h6 => l.themeElementHeading(6),
  ThemeElement.paragraphAfterHeading => l.themeElementParagraphAfterHeading,
  ThemeElement.bold => l.themeElementBold,
  ThemeElement.italic => l.themeElementItalic,
  ThemeElement.strike => l.themeElementStrike,
  ThemeElement.inlineCode => l.themeElementInlineCode,
  ThemeElement.link => l.themeElementLink,
  ThemeElement.mention => l.themeElementMention,
  ThemeElement.blockquote => l.themeElementBlockquote,
  ThemeElement.codeBlock => l.themeElementCodeBlock,
  ThemeElement.list => l.themeElementList,
  ThemeElement.task => l.themeElementTask,
  ThemeElement.rule => l.themeElementRule,
  ThemeElement.image => l.themeElementImage,
  ThemeElement.table => l.themeElementTable,
  ThemeElement.callout => l.themeElementCallout,
  ThemeElement.details => l.themeElementDetails,
  ThemeElement.card => l.themeElementCard,
  ThemeElement.grid => l.themeElementGrid,
  ThemeElement.button => l.themeElementButton,
  ThemeElement.chip => l.themeElementChip,
  ThemeElement.stepBadge => l.themeElementStepBadge,
  ThemeElement.header => l.themeElementHeader,
  ThemeElement.footer => l.themeElementFooter,
};

/// A group of the element tree.
class ThemeTreeGroup {
  const ThemeTreeGroup(this.id, this.nodes, {this.node});

  /// `headings`, `inline`, `blocks`, `wonky`, or empty for an untitled
  /// group.
  final String id;

  /// The group's title (empty for an untitled group).
  String label(WriteLocalizations l) => switch (id) {
    'headings' => l.themeEditorTreeHeadings,
    'inline' => l.themeEditorTreeInline,
    'blocks' => l.themeEditorTreeBlocks,
    'wonky' => l.themeEditorTreeWonky,
    _ => '',
  };

  /// The group's own node (Headings → all headings), if selectable.
  final ThemeNode? node;
  final List<ThemeNode> nodes;
}

/// The element tree of Write 06 §10.2.
const List<ThemeTreeGroup> themeTree = [
  ThemeTreeGroup('', [
    ThemeNode.general,
    ThemeNode.page,
    ThemeNode.palette,
    ThemeNode.fonts,
    ThemeNode.element(ThemeElement.body),
  ]),
  ThemeTreeGroup('headings', node: ThemeNode.element(ThemeElement.headings), [
    ThemeNode.element(ThemeElement.h1),
    ThemeNode.element(ThemeElement.h2),
    ThemeNode.element(ThemeElement.h3),
    ThemeNode.element(ThemeElement.h4),
    ThemeNode.element(ThemeElement.h5),
    ThemeNode.element(ThemeElement.h6),
    ThemeNode.element(ThemeElement.paragraphAfterHeading),
  ]),
  ThemeTreeGroup('inline', [
    ThemeNode.element(ThemeElement.bold),
    ThemeNode.element(ThemeElement.italic),
    ThemeNode.element(ThemeElement.strike),
    ThemeNode.element(ThemeElement.inlineCode),
    ThemeNode.element(ThemeElement.link),
    ThemeNode.element(ThemeElement.mention),
  ]),
  ThemeTreeGroup('blocks', [
    ThemeNode.element(ThemeElement.blockquote),
    ThemeNode.element(ThemeElement.codeBlock),
    ThemeNode.syntax,
    ThemeNode.element(ThemeElement.list),
    ThemeNode.element(ThemeElement.task),
    ThemeNode.element(ThemeElement.rule),
    ThemeNode.element(ThemeElement.image),
    ThemeNode.element(ThemeElement.table),
  ]),
  // Wonky Markdown elements (Write 11 §8), shown for every document.
  ThemeTreeGroup('wonky', [
    ThemeNode.element(ThemeElement.callout),
    ThemeNode.element(ThemeElement.details),
    ThemeNode.element(ThemeElement.card),
    ThemeNode.element(ThemeElement.grid),
    ThemeNode.element(ThemeElement.button),
    ThemeNode.element(ThemeElement.chip),
    ThemeNode.element(ThemeElement.stepBadge),
  ]),
  ThemeTreeGroup('', [ThemeNode.headerFooter, ThemeNode.advanced]),
];

/// All selectable nodes in tree order.
final List<ThemeNode> allThemeNodes = [
  for (final g in themeTree) ...[?g.node, ...g.nodes],
];

/// The property sections a node edits: `(title, pathPrefix, catalog
/// object)`. A path prefix plus a field name is a `setProperty` path.
List<(String, String, ObjectProp)> sectionsOf(
  WriteLocalizations l,
  ThemeNode node,
) => switch (node.kind) {
  ThemeNodeKind.element => [
    ('', 'elements.${node.element!.name}', _catalog(node.element!)),
  ],
  ThemeNodeKind.page => [('', 'page', _pageWithoutHeaderFooter)],
  ThemeNodeKind.headerFooter => [
    (l.themeEditorSectionHeaderAndFooter, 'page.headerFooter', _headerFooter),
    (
      l.themeEditorSectionHeaderOnly,
      'elements.header',
      _catalog(ThemeElement.header),
    ),
    (
      l.themeEditorSectionFooterOnly,
      'elements.footer',
      _catalog(ThemeElement.footer),
    ),
  ],
  ThemeNodeKind.advanced => [
    (l.themeEditorSectionAppOverlays, 'overlays', core.ThemeCatalog.overlays),
  ],
  _ => const [],
};

ObjectProp _catalog(ThemeElement e) => core.ThemeCatalog.elements[e]!;

final ObjectProp _pageWithoutHeaderFooter = ObjectProp({
  for (final f in core.ThemeCatalog.page.fields.entries)
    if (f.key != 'headerFooter') f.key: f.value,
});

final ObjectProp _headerFooter =
    core.ThemeCatalog.page.fields['headerFooter']! as ObjectProp;

/// Property groups of the inspector (Write 06 §10.2: Text, Spacing, Box,
/// element-specific).
enum PropGroup { text, spacing, box, specific }

String propGroupLabel(WriteLocalizations l, PropGroup g, ThemeNode node) =>
    switch (g) {
      PropGroup.text => l.themeEditorGroupText,
      PropGroup.spacing => l.themeEditorGroupSpacing,
      PropGroup.box => l.themeEditorGroupBox,
      PropGroup.specific => switch (node.element) {
        ThemeElement.list => l.themeEditorGroupMarkers,
        ThemeElement.task => l.themeEditorGroupCheckboxes,
        ThemeElement.table => l.themeEditorGroupTable,
        ThemeElement.image => l.themeEditorGroupImage,
        ThemeElement.rule => l.themeEditorGroupLine,
        ThemeElement.link => l.themeEditorGroupLink,
        ThemeElement.codeBlock => l.themeEditorGroupCode,
        ThemeElement.headings => l.themeEditorGroupNumbering,
        _ => l.themeEditorGroupMore,
      },
    };

const _textKeys = {
  'fontFamily',
  'fontSize',
  'fontWeight',
  'fontStyle',
  'lineHeight',
  'letterSpacing',
  'color',
  'caseTransform',
  'fontFeatures',
  'sizeRatio',
  'italic',
};

const _spacingKeys = {
  'spaceBefore',
  'spaceAfter',
  'padding',
  'paddingX',
  'firstLineIndent',
  'indentPerLevel',
  'markerGap',
  'itemSpacing',
  'borderBottomGap',
  'cellPadding',
  'pagelessPadding',
  'defaultMargins',
  'pagelessMaxWidth',
};

const _boxKeys = {
  'background',
  'border',
  'borderRadius',
  'borderBottom',
  'borderTop',
  'bar',
  'align',
  'shadow',
  'keepWithNext',
  'pageBreakBefore',
  'paperColor',
  'canvasColor',
  'pageShadow',
};

PropGroup groupOf(String key) {
  if (_textKeys.contains(key)) return PropGroup.text;
  if (_spacingKeys.contains(key)) return PropGroup.spacing;
  if (_boxKeys.contains(key)) return PropGroup.box;
  return PropGroup.specific;
}

/// Display label of property [key] (a catalog field name). Unknown keys
/// are spelled out from their camel case.
String propLabel(WriteLocalizations l, String key) => switch (key) {
  'fontFamily' => l.themePropFontFamily,
  'fontSize' => l.themePropFontSize,
  'fontWeight' => l.themePropFontWeight,
  'fontStyle' => l.themePropFontStyle,
  'lineHeight' => l.themePropLineHeight,
  'letterSpacing' => l.themePropLetterSpacing,
  'color' => l.themePropColor,
  'caseTransform' => l.themePropCaseTransform,
  'fontFeatures' => l.themePropFontFeatures,
  'spaceBefore' => l.themePropSpaceBefore,
  'spaceAfter' => l.themePropSpaceAfter,
  'padding' => l.themePropPadding,
  'background' => l.themePropBackground,
  'border' => l.themePropBorder,
  'borderRadius' => l.themePropBorderRadius,
  'keepWithNext' => l.themePropKeepWithNext,
  'pageBreakBefore' => l.themePropPageBreakBefore,
  'align' => l.themePropAlign,
  'firstLineIndent' => l.themePropFirstLineIndent,
  'numbering' => l.themePropNumbering,
  'enabled' => l.themePropEnabled,
  'fromLevel' => l.themePropFromLevel,
  'toLevel' => l.themePropToLevel,
  'style' => l.themePropStyle,
  'suffix' => l.themePropSuffix,
  'borderBottom' => l.themePropBorderBottom,
  'borderTop' => l.themePropBorderTop,
  'borderBottomGap' => l.themePropBorderBottomGap,
  'lineColor' => l.themePropLineColor,
  'lineThickness' => l.themePropLineThickness,
  'sizeRatio' => l.themePropSizeRatio,
  'paddingX' => l.themePropPaddingX,
  'hoverColor' => l.themePropHoverColor,
  'underline' => l.themePropUnderline,
  'underlineStyle' => l.themePropUnderlineStyle,
  'underlineThickness' => l.themePropUnderlineThickness,
  'prefix' => l.themePropPrefix,
  'bar' => l.themePropBar,
  'italic' => l.themePropItalic,
  'wrap' => l.themePropWrap,
  'showLanguageLabel' => l.themePropShowLanguageLabel,
  'tabSize' => l.themePropTabSize,
  'lineNumbers' => l.themePropLineNumbers,
  'bullets' => l.themePropBullets,
  'bulletColor' => l.themePropBulletColor,
  'bulletScale' => l.themePropBulletScale,
  'numberSuffix' => l.themePropNumberSuffix,
  'numberColor' => l.themePropNumberColor,
  'indentPerLevel' => l.themePropIndentPerLevel,
  'markerGap' => l.themePropMarkerGap,
  'itemSpacing' => l.themePropItemSpacing,
  'checkbox' => l.themePropCheckbox,
  'shape' => l.themePropShape,
  'size' => l.themePropSize,
  'borderColor' => l.themePropBorderColor,
  'checkedFill' => l.themePropCheckedFill,
  'checkColor' => l.themePropCheckColor,
  'checkedText' => l.themePropCheckedText,
  'strike' => l.themePropStrike,
  'opacity' => l.themePropOpacity,
  'thickness' => l.themePropThickness,
  'width' => l.themePropWidth,
  'ornament' => l.themePropOrnament,
  'maxWidth' => l.themePropMaxWidth,
  'shadow' => l.themePropShadow,
  'caption' => l.themePropCaption,
  'show' => l.themePropShow,
  'gap' => l.themePropGap,
  'headerBackground' => l.themePropHeaderBackground,
  'headerColor' => l.themePropHeaderColor,
  'headerFontWeight' => l.themePropHeaderFontWeight,
  'borders' => l.themePropBorders,
  'borderWidth' => l.themePropBorderWidth,
  'zebra' => l.themePropZebra,
  'zebraColor' => l.themePropZebraColor,
  'cellPadding' => l.themePropCellPadding,
  'fontSizeRatio' => l.themePropFontSizeRatio,
  'paperColor' => l.themePropPaperColor,
  'canvasColor' => l.themePropCanvasColor,
  'pageShadow' => l.themePropPageShadow,
  'pagelessMaxWidth' => l.themePropPagelessMaxWidth,
  'pagelessPadding' => l.themePropPagelessPadding,
  'defaultMargins' => l.themePropDefaultMargins,
  'selection' => l.themePropSelection,
  'caret' => l.themePropCaret,
  'commentHighlight' => l.themePropCommentHighlight,
  'commentHighlightActive' => l.themePropCommentHighlightActive,
  'suggestionInsert' => l.themePropSuggestionInsert,
  'suggestionDelete' => l.themePropSuggestionDelete,
  'findMatch' => l.themePropFindMatch,
  'findMatchActive' => l.themePropFindMatchActive,
  _ => _spelledOut(key),
};

String _spelledOut(String key) {
  final spaced = key.replaceAllMapped(
    RegExp('([A-Z])'),
    (m) => ' ${m[1]!.toLowerCase()}',
  );
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Display labels of enum values.
String enumLabel(WriteLocalizations l, String value) => switch (value) {
  'none' => l.themeEditorEnumNone,
  'smallCaps' => l.themeEditorEnumSmallCaps,
  'upperRoman-upperAlpha-decimal' => 'I. A. 1.',
  'decimal' => '1.',
  'outline' => '1.1.1',
  'legal' => '1.1.1.',
  'lowerAlpha' => 'a.',
  'upperAlpha' => 'A.',
  'lowerRoman' => 'i.',
  'upperRoman' => 'I.',
  'headerOnly' => l.themeEditorEnumHeaderOnly,
  '@' => l.themeEditorEnumAtPrefix,
  '' => l.themeEditorEnumNoPrefix,
  'normal' => l.themeEditorEnumNormal,
  'italic' => l.themeEditorEnumItalic,
  'oblique' => l.themeEditorEnumOblique,
  'uppercase' => l.themeEditorEnumUppercase,
  'lowercase' => l.themeEditorEnumLowercase,
  'capitalize' => l.themeEditorEnumCapitalize,
  'left' => l.themeEditorEnumLeft,
  'center' => l.themeEditorEnumCenter,
  'right' => l.themeEditorEnumRight,
  'justify' => l.themeEditorEnumJustify,
  'top' => l.themeEditorEnumTop,
  'bottom' => l.themeEditorEnumBottom,
  'always' => l.themeEditorEnumAlways,
  'hover' => l.themeEditorEnumHover,
  'solid' => l.themeEditorEnumSolid,
  'dotted' => l.themeEditorEnumDotted,
  'dashed' => l.themeEditorEnumDashed,
  'double' => l.themeEditorEnumDouble,
  'ornament' => l.themeEditorEnumOrnament,
  'square' => l.themeEditorEnumSquare,
  'rounded' => l.themeEditorEnumRounded,
  'circle' => l.themeEditorEnumCircle,
  'soft' => l.themeEditorEnumSoft,
  'strong' => l.themeEditorEnumStrong,
  'auto' => l.themeEditorEnumAuto,
  'full' => l.themeEditorEnumFull,
  'all' => l.themeEditorEnumAll,
  'horizontal' => l.themeEditorEnumHorizontal,
  'outer' => l.themeEditorEnumOuter,
  // Other values (font families, symbols) are shown as they are.
  _ => value[0].toUpperCase() + value.substring(1),
};

/// Display name of a palette key.
String paletteLabel(WriteLocalizations l, PaletteKey k) => switch (k) {
  PaletteKey.text => l.themeEditorPaletteText,
  PaletteKey.heading => l.themeEditorPaletteHeading,
  PaletteKey.muted => l.themeEditorPaletteMuted,
  PaletteKey.accent => l.themeEditorPaletteAccent,
  PaletteKey.link => l.themeEditorPaletteLink,
  PaletteKey.linkHover => l.themeEditorPaletteLinkHover,
  PaletteKey.page => l.themeEditorPalettePage,
  PaletteKey.canvas => l.themeEditorPaletteCanvas,
  PaletteKey.border => l.themeEditorPaletteBorder,
  PaletteKey.codeText => l.themeEditorPaletteCodeText,
  PaletteKey.codeBg => l.themeEditorPaletteCodeBg,
  PaletteKey.quoteText => l.themeEditorPaletteQuoteText,
  PaletteKey.quoteBar => l.themeEditorPaletteQuoteBar,
  PaletteKey.quoteBg => l.themeEditorPaletteQuoteBg,
  PaletteKey.tableHeaderBg => l.themeEditorPaletteTableHeaderBg,
  PaletteKey.tableStripe => l.themeEditorPaletteTableStripe,
  PaletteKey.mentionBg => l.themeEditorPaletteMentionBg,
  PaletteKey.mentionText => l.themeEditorPaletteMentionText,
  PaletteKey.highlight => l.themeEditorPaletteHighlight,
  _ => l.themeEditorPaletteCustom(k.name.substring(6)),
};

/// Display name of a syntax token.
String syntaxLabel(WriteLocalizations l, SyntaxToken t) => switch (t) {
  SyntaxToken.keyword => l.themeEditorSyntaxKeyword,
  SyntaxToken.string => l.themeEditorSyntaxString,
  SyntaxToken.number => l.themeEditorSyntaxNumber,
  SyntaxToken.comment => l.themeEditorSyntaxComment,
  SyntaxToken.function => l.themeEditorSyntaxFunction,
  SyntaxToken.type => l.themeEditorSyntaxType,
  SyntaxToken.variable => l.themeEditorSyntaxVariable,
  SyntaxToken.operator => l.themeEditorSyntaxOperator,
  SyntaxToken.punctuation => l.themeEditorSyntaxPunctuation,
  SyntaxToken.builtin => l.themeEditorSyntaxBuiltin,
  SyntaxToken.literal => l.themeEditorSyntaxLiteral,
  SyntaxToken.meta => l.themeEditorSyntaxMeta,
  SyntaxToken.tag => l.themeEditorSyntaxTag,
  SyntaxToken.attribute => l.themeEditorSyntaxAttribute,
  SyntaxToken.regexp => l.themeEditorSyntaxRegexp,
  SyntaxToken.addition => l.themeEditorSyntaxAddition,
  SyntaxToken.deletion => l.themeEditorSyntaxDeletion,
};

/// The node a contrast pair belongs to (tree ⚠ and inspector warnings).
ThemeNode nodeOfPair(String pairId) {
  if (pairId.startsWith('syntax.')) return ThemeNode.syntax;
  final level = RegExp(r'^h([1-6])$').firstMatch(pairId);
  if (level != null) {
    return ThemeNode.element(ThemeElement.heading(int.parse(level[1]!)));
  }
  return switch (pairId) {
    'body' => const ThemeNode.element(ThemeElement.body),
    'caption' => const ThemeNode.element(ThemeElement.image),
    'header' || 'footer' => ThemeNode.headerFooter,
    'link' => const ThemeNode.element(ThemeElement.link),
    'mention' => const ThemeNode.element(ThemeElement.mention),
    'inlineCode' => const ThemeNode.element(ThemeElement.inlineCode),
    'codeBlock' => const ThemeNode.element(ThemeElement.codeBlock),
    'blockquote' => const ThemeNode.element(ThemeElement.blockquote),
    'tableHeader' ||
    'tableCell' ||
    'tableZebra' => const ThemeNode.element(ThemeElement.table),
    'taskChecked' => const ThemeNode.element(ThemeElement.task),
    _ => ThemeNode.palette,
  };
}

/// Human name of a contrast pair ("Heading 2 on the page").
String pairLabel(WriteLocalizations l, String pairId) {
  if (pairId.startsWith('syntax.')) {
    final t = SyntaxToken.fromJsonName(pairId.substring(7));
    return l.themeEditorPairSyntax(t == null ? pairId : syntaxLabel(l, t));
  }
  return switch (pairId) {
    'body' => l.themeEditorPairBody,
    'caption' => l.themeEditorPairCaption,
    'header' => l.themeEditorPairHeader,
    'footer' => l.themeEditorPairFooter,
    'link' => l.themeEditorPairLink,
    'mention' => l.themeEditorPairMention,
    'inlineCode' => l.themeEditorPairInlineCode,
    'codeBlock' => l.themeEditorPairCodeBlock,
    'blockquote' => l.themeEditorPairBlockquote,
    'tableHeader' => l.themeEditorPairTableHeader,
    'tableCell' => l.themeEditorPairTableCell,
    'tableZebra' => l.themeEditorPairTableZebra,
    'taskChecked' => l.themeEditorPairTaskChecked,
    _ => switch (nodeOfPair(pairId).element) {
      final e? => l.themeEditorPairElement(elementLabel(l, e)),
      null => pairId,
    },
  };
}

/// Where a property's value comes from when the theme doesn't set it.
class InheritedValue {
  const InheritedValue(this.value, this.source);

  final Object? value;

  /// "Body", "All headings", "Wonky Default" …
  final WriteText source;
}

/// Looks up inherited values for the inspector's placeholders and reset
/// tooltips ("Inherited from Body: 11pt", Write 06 §10.2): the variant's
/// layer, the cascade parents (text properties only) and finally the
/// built-in base.
abstract final class ThemeInheritance {
  /// The built-in base theme (its name is not translated).
  static String _builtinBase(WriteLocalizations _) =>
      core.BuiltinThemes.wonkyDefault.name;

  static List<ThemeElement> _parents(ThemeElement e) => switch (e) {
    ThemeElement.h1 ||
    ThemeElement.h2 ||
    ThemeElement.h3 ||
    ThemeElement.h4 ||
    ThemeElement.h5 ||
    ThemeElement.h6 => const [ThemeElement.headings, ThemeElement.body],
    ThemeElement.headings ||
    ThemeElement.blockquote ||
    ThemeElement.list ||
    ThemeElement.task ||
    ThemeElement.table ||
    ThemeElement.header ||
    ThemeElement.footer => const [ThemeElement.body],
    ThemeElement.codeBlock ||
    ThemeElement.inlineCode => const [ThemeElement.body],
    _ => const [],
  };

  static const _inheritedFromParents = {
    'fontFamily',
    'fontSize',
    'fontWeight',
    'fontStyle',
    'lineHeight',
    'letterSpacing',
    'color',
    'caseTransform',
    'fontFeatures',
  };

  static const _codeInherits = {'color', 'lineHeight'};

  /// The value [path] inherits in [json] (it is not set at [path] itself).
  static InheritedValue? of(
    ThemeJson json,
    String path, {
    ThemeVariant variant = ThemeVariant.light,
  }) {
    final base = core.BaseTheme.instance.theme.toJson();
    Object? at(ThemeJson j, String p) {
      try {
        return ThemePropertyPath.get(j, p);
      } on core.ThemePathException {
        return null;
      }
    }

    final segs = path.split('.');
    // A dark override inherits the light value first.
    if (segs.first == 'dark') {
      final light = segs.sublist(1).join('.');
      final v = at(json, light);
      if (v != null) {
        return InheritedValue(v, (l) => l.themeEditorSourceLightVariant);
      }
      return of(json, light);
    }
    if (segs.first == 'elements' && segs.length >= 3) {
      final e = ThemeElement.fromJsonName(segs[1]);
      final rest = segs.sublist(2).join('.');
      if (e != null) {
        final key = segs[2];
        final code =
            e == ThemeElement.codeBlock || e == ThemeElement.inlineCode;
        final inherits =
            segs.length == 3 &&
            (code ? _codeInherits : _inheritedFromParents).contains(key);
        if (inherits) {
          for (final p in _parents(e)) {
            final v = at(json, 'elements.${p.name}.$rest');
            if (v != null) return InheritedValue(v, (l) => elementLabel(l, p));
            if (p == ThemeElement.body &&
                (e == ThemeElement.header || e == ThemeElement.footer)) {
              final hf = at(json, 'page.headerFooter.$rest');
              if (hf != null) {
                return InheritedValue(
                  hf,
                  (l) => l.themeEditorSectionHeaderAndFooter,
                );
              }
            }
          }
        }
        if (key == 'fontFamily' && segs.length == 3) {
          final role = core.ThemeCatalog.roleOf(e);
          return InheritedValue(
            '@${role.name}',
            (l) => l.themeEditorSourceThemeFonts,
          );
        }
        final b = at(base, path);
        if (b != null) return InheritedValue(b, _builtinBase);
        if (inherits) {
          for (final p in _parents(e)) {
            final v = at(base, 'elements.${p.name}.$rest');
            if (v != null) return InheritedValue(v, (l) => elementLabel(l, p));
          }
        }
        return null;
      }
    }
    final b = at(base, path);
    return b == null ? null : InheritedValue(b, _builtinBase);
  }

  /// The concrete font family [element] uses in [theme] (for weight
  /// options).
  static String familyOf(
    WriteThemeData theme,
    ThemeJson json,
    ThemeElement element,
  ) {
    Object? raw;
    try {
      raw = ThemePropertyPath.get(json, 'elements.${element.name}.fontFamily');
    } on core.ThemePathException {
      raw = null;
    }
    raw ??= of(json, 'elements.${element.name}.fontFamily')?.value;
    final ref = raw is String ? FontRef.tryParse(raw) : null;
    if (ref?.family != null) return ref!.family!;
    final role = ref?.role ?? core.ThemeCatalog.roleOf(element);
    return theme.fonts.of(role);
  }
}

/// The type of a property path (`fontSize` of `elements.h2` → the length
/// type), or null.
PropType? propTypeAt(ObjectProp object, List<String> rest) {
  PropType? t = object;
  for (final seg in rest) {
    if (t is! ObjectProp) return null;
    t = t.fields[seg];
  }
  return t;
}

/// Palette keys shown in the editor (all, custom last).
const editablePaletteKeys = PaletteKey.values;

/// A palette key as a color reference (`"@accent"`).
String paletteRef(PaletteKey k) => ColorRef.palette(k).toJson();

/// The theme fonts as `@role` references with their families.
List<(String, String)> roleFonts(WriteThemeData t) => [
  for (final r in FontRole.values) ('@${r.name}', t.fonts.of(r)),
];
