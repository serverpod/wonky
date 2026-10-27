/// The property catalog of theme schema v1: which properties each element,
/// the page, overlays and syntax tokens accept (06 §2.3–§2.6).
///
/// The catalog drives parsing/validation, the generated JSON schema and the
/// theme editor's property paths.
library;

import 'properties.dart';
import 'values.dart';

const _spacing = LengthProp(LengthKind.spacing);
const _stroke = LengthProp(LengthKind.stroke);
const _color = ColorProp();
const _bool = BoolProp();

/// The colors of one callout type (Write 11 §8): [color] is the type's
/// hue; the other colors are derived from it unless set.
const _calloutVariant = ObjectProp({
  'color': _color,
  'background': _color,
  'border': _color,
  'titleColor': _color,
});

/// Allowed `align` values.
const alignValues = ['left', 'center', 'right', 'justify'];

/// Allowed `caseTransform` values.
const caseTransformValues = [
  'none',
  'uppercase',
  'lowercase',
  'capitalize',
  'smallCaps',
];

/// Allowed list numbering styles per level.
const listNumberStyleValues = [
  'decimal',
  'lowerAlpha',
  'upperAlpha',
  'lowerRoman',
  'upperRoman',
];

/// Allowed heading numbering styles.
const headingNumberingStyleValues = [
  'decimal',
  'outline',
  'legal',
  'upperRoman-upperAlpha-decimal',
];

/// TextStyleProps (06 §2.4).
const Map<String, PropType> textStyleProps = {
  'fontFamily': FontProp(),
  'fontSize': LengthProp(LengthKind.fontSize),
  'fontWeight': WeightProp(),
  'fontStyle': EnumProp(['normal', 'italic']),
  'lineHeight': NumberProp(0.8, 3.0),
  'letterSpacing': LengthProp(LengthKind.letterSpacing),
  'color': _color,
  'caseTransform': EnumProp(caseTransformValues),
  'fontFeatures': FeatureListProp(),
};

const Map<String, PropType> _blockCore = {
  'spaceBefore': _spacing,
  'spaceAfter': _spacing,
  'padding': EdgesProp.lengths(LengthKind.spacing),
  'background': _color,
  'borderRadius': _spacing,
  'keepWithNext': _bool,
  'pageBreakBefore': _bool,
};

/// BlockProps (06 §2.4).
const Map<String, PropType> blockProps = {
  ..._blockCore,
  'border': EdgesProp.borders(),
  'align': EnumProp(alignValues),
};

/// Properties of `page.headerFooter`, `elements.header` and
/// `elements.footer`.
const Map<String, PropType> headerFooterProps = {
  ...textStyleProps,
  'align': EnumProp(alignValues),
  'borderBottom': BorderProp(),
  'borderTop': BorderProp(),
};

const _headingProps = <String, PropType>{
  ...textStyleProps,
  ...blockProps,
  'borderBottom': BorderProp(),
  'borderBottomGap': _spacing,
};

/// The schema-v1 property catalog.
abstract final class ThemeCatalog {
  /// Properties of each element (06 §2.4).
  static const Map<ThemeElement, ObjectProp> elements = {
    ThemeElement.body: ObjectProp({
      ...textStyleProps,
      ..._blockCore,
      'border': EdgesProp.borders(),
      'align': EnumProp(['left', 'justify']),
      'firstLineIndent': _spacing,
    }),
    ThemeElement.headings: ObjectProp({
      ...textStyleProps,
      ...blockProps,
      'numbering': ObjectProp({
        'enabled': _bool,
        'fromLevel': IntProp(1, 6),
        'toLevel': IntProp(1, 6),
        'style': EnumProp(headingNumberingStyleValues),
        'suffix': StringProp(maxLength: 8),
      }),
    }),
    ThemeElement.h1: ObjectProp(_headingProps),
    ThemeElement.h2: ObjectProp(_headingProps),
    ThemeElement.h3: ObjectProp(_headingProps),
    ThemeElement.h4: ObjectProp(_headingProps),
    ThemeElement.h5: ObjectProp(_headingProps),
    ThemeElement.h6: ObjectProp(_headingProps),
    ThemeElement.paragraphAfterHeading: ObjectProp(blockProps),
    ThemeElement.bold: ObjectProp({
      'fontWeight': WeightProp(),
      'color': _color,
    }),
    ThemeElement.italic: ObjectProp({
      'fontStyle': EnumProp(['italic', 'oblique']),
      'color': _color,
    }),
    ThemeElement.strike: ObjectProp({
      'lineColor': _color,
      'lineThickness': _stroke,
      'color': _color,
    }),
    ThemeElement.inlineCode: ObjectProp({
      'fontFamily': FontProp(),
      'fontWeight': WeightProp(),
      'fontStyle': EnumProp(['normal', 'italic']),
      'letterSpacing': LengthProp(LengthKind.letterSpacing),
      'fontFeatures': FeatureListProp(),
      'sizeRatio': NumberProp(0.5, 2),
      'color': _color,
      'background': _color,
      'paddingX': _spacing,
      'borderRadius': _spacing,
      'border': BorderProp(),
    }),
    ThemeElement.link: ObjectProp({
      'color': _color,
      'hoverColor': _color,
      'underline': EnumProp(['always', 'hover', 'none']),
      'underlineStyle': EnumProp(['solid', 'dotted', 'dashed']),
      'underlineThickness': _stroke,
    }),
    ThemeElement.mention: ObjectProp({
      'color': _color,
      'background': _color,
      'borderRadius': _spacing,
      'fontWeight': WeightProp(),
      'prefix': EnumProp(['@', '']),
    }),
    ThemeElement.blockquote: ObjectProp({
      ...textStyleProps,
      ...blockProps,
      'bar': BorderProp(),
      'italic': _bool,
    }),
    ThemeElement.codeBlock: ObjectProp({
      ...textStyleProps,
      ...blockProps,
      'wrap': _bool,
      'showLanguageLabel': _bool,
      'tabSize': IntProp(2, 8),
      'lineNumbers': _bool,
    }),
    ThemeElement.list: ObjectProp({
      ...blockProps,
      'bullets': ListProp(StringProp(maxLength: 8)),
      'bulletColor': _color,
      'bulletScale': NumberProp(0.25, 4),
      'numbering': ListProp(EnumProp(listNumberStyleValues)),
      'numberSuffix': EnumProp(['.', ')']),
      'numberColor': _color,
      'indentPerLevel': _spacing,
      'markerGap': _spacing,
      'itemSpacing': _spacing,
    }),
    ThemeElement.task: ObjectProp({
      ...blockProps,
      'checkbox': ObjectProp({
        'shape': EnumProp(['square', 'rounded', 'circle']),
        'size': _spacing,
        'borderColor': _color,
        'checkedFill': _color,
        'checkColor': _color,
      }),
      'checkedText': ObjectProp({
        'strike': _bool,
        'opacity': NumberProp(0, 1),
        'color': _color,
      }),
    }),
    ThemeElement.rule: ObjectProp({
      ...blockProps,
      'style': EnumProp(['solid', 'dashed', 'dotted', 'double', 'ornament']),
      'thickness': _stroke,
      'color': _color,
      'width': LengthProp(LengthKind.width),
      'ornament': StringProp(maxLength: 16),
    }),
    ThemeElement.image: ObjectProp({
      ..._blockCore,
      'align': EnumProp(['center', 'left']),
      'border': BorderProp(),
      'maxWidth': LengthProp(LengthKind.width),
      'shadow': EnumProp(['none', 'soft', 'strong']),
      'caption': ObjectProp({
        ...textStyleProps,
        'show': _bool,
        'align': EnumProp(alignValues),
        'gap': _spacing,
      }),
    }),
    ThemeElement.table: ObjectProp({
      ...textStyleProps,
      ...blockProps,
      'width': EnumProp(['auto', 'full']),
      'headerBackground': _color,
      'headerColor': _color,
      'headerFontWeight': WeightProp(),
      'borders': EnumProp(['all', 'horizontal', 'outer', 'headerOnly', 'none']),
      'borderColor': _color,
      'borderWidth': _stroke,
      'zebra': _bool,
      'zebraColor': _color,
      'cellPadding': EdgesProp.lengths(LengthKind.spacing),
      'fontSizeRatio': NumberProp(0.5, 2),
    }),
    // Wonky Markdown elements (Write 11 §8).
    ThemeElement.callout: ObjectProp({
      'spaceBefore': _spacing,
      'spaceAfter': _spacing,
      'padding': EdgesProp.lengths(LengthKind.spacing),
      'borderRadius': _spacing,
      'borderWidth': _stroke,
      'titleCaseTransform': EnumProp(caseTransformValues),
      'titleSizeRatio': NumberProp(0.5, 2),
      'titleWeight': WeightProp(),
      'info': _calloutVariant,
      'tip': _calloutVariant,
      'note': _calloutVariant,
      'warning': _calloutVariant,
      'danger': _calloutVariant,
    }),
    ThemeElement.details: ObjectProp({
      'spaceBefore': _spacing,
      'spaceAfter': _spacing,
      'padding': EdgesProp.lengths(LengthKind.spacing),
      'background': _color,
      'border': BorderProp(),
      'borderRadius': _spacing,
      'summaryWeight': WeightProp(),
      'chevronColor': _color,
    }),
    ThemeElement.card: ObjectProp({
      'spaceBefore': _spacing,
      'spaceAfter': _spacing,
      'padding': EdgesProp.lengths(LengthKind.spacing),
      'background': _color,
      'borderRadius': _spacing,
      'shadow': EnumProp(['none', 'soft']),
    }),
    ThemeElement.grid: ObjectProp({
      'spaceBefore': _spacing,
      'spaceAfter': _spacing,
      'bulletColor': _color,
      'columnGap': _spacing,
      'rowGap': _spacing,
    }),
    ThemeElement.button: ObjectProp({
      'background': _color,
      'color': _color,
      'secondaryBackground': _color,
      'secondaryColor': _color,
      'borderRadius': _spacing,
      'fontWeight': WeightProp(),
      'arrowColor': _color,
      'arrowWeight': WeightProp(),
    }),
    ThemeElement.chip: ObjectProp({
      'background': _color,
      'color': _color,
      'borderRadius': _spacing,
      'fontWeight': WeightProp(),
    }),
    ThemeElement.stepBadge: ObjectProp({
      'background': _color,
      'color': _color,
      'sizeRatio': NumberProp(0.6, 2),
    }),
    ThemeElement.header: ObjectProp(headerFooterProps),
    ThemeElement.footer: ObjectProp(headerFooterProps),
  };

  /// Properties of `page` (06 §2.3).
  static const page = ObjectProp({
    'paperColor': _color,
    'canvasColor': _color,
    'pageShadow': EnumProp(['none', 'soft', 'strong']),
    'pagelessMaxWidth': LengthProp(LengthKind.pageWidth),
    'pagelessPadding': EdgesProp.lengths(LengthKind.spacing),
    'defaultMargins': EdgesProp.lengths(LengthKind.margin),
    'headerFooter': ObjectProp(headerFooterProps),
  });

  /// Properties of `overlays` (06 §2.6).
  static const overlays = ObjectProp({
    'selection': _color,
    'caret': ObjectProp({'color': _color, 'width': _stroke}),
    'commentHighlight': _color,
    'commentHighlightActive': _color,
    'suggestionInsert': _color,
    'suggestionDelete': _color,
    'findMatch': _color,
    'findMatchActive': _color,
  });

  /// Properties of one `syntax` token (06 §2.5).
  static const syntaxToken = ObjectProp({
    'color': _color,
    'fontStyle': EnumProp(['normal', 'italic']),
    'fontWeight': WeightProp(),
  });

  /// The font role used for an element's unknown families and weight
  /// snapping.
  static FontRole roleOf(ThemeElement e) => switch (e) {
    ThemeElement.headings ||
    ThemeElement.h1 ||
    ThemeElement.h2 ||
    ThemeElement.h3 ||
    ThemeElement.h4 ||
    ThemeElement.h5 ||
    ThemeElement.h6 => FontRole.heading,
    ThemeElement.codeBlock || ThemeElement.inlineCode => FontRole.mono,
    _ => FontRole.body,
  };
}
