/// The built-in, complete base of the cascade: hard-coded *Wonky Default*
/// values (06 §3).
library;

import '../model/catalog.dart';
import '../model/color_ref.dart';
import '../model/properties.dart';
import '../model/syntax_token.dart';
import '../model/theme_parser.dart';
import '../model/values.dart';
import '../model/write_theme_data.dart';

/// Light palette of *Wonky Default* (06 §2.2).
const Map<String, Object?> wonkyDefaultPaletteJson = {
  'text': '#1f2328',
  'heading': '#111111',
  'muted': '#6b7280',
  'accent': '#1d4ed8',
  'link': '@accent',
  'linkHover': '#1e40af',
  'page': '#ffffff',
  'canvas': '#f1f3f4',
  'border': '#d0d7de',
  'codeText': '#24292f',
  'codeBg': '#f6f8fa',
  'quoteText': '#4b5563',
  'quoteBar': '#d0d7de',
  'quoteBg': 'transparent',
  'tableHeaderBg': '#f3f4f6',
  'tableStripe': '#fafafa',
  'mentionBg': '#e0e7ff',
  'mentionText': '#3730a3',
  'highlight': '#fff3bf',
  'custom1': null,
  'custom2': null,
  'custom3': null,
  'custom4': null,
  'custom5': null,
  'custom6': null,
};

/// Light syntax palette of *Wonky Default* (GitHub-like).
const Map<String, Object?> wonkyDefaultSyntaxJson = {
  'keyword': {'color': '#cf222e'},
  'string': {'color': '#0a3069'},
  'number': {'color': '#0550ae'},
  'comment': {'color': '#57606a', 'fontStyle': 'italic'},
  'function': {'color': '#8250df'},
  'type': {'color': '#953800'},
  'variable': {'color': '#953800'},
  'builtin': {'color': '#0550ae'},
  'literal': {'color': '#0550ae'},
  'meta': {'color': '#8250df'},
  'tag': {'color': '#116329'},
  'attribute': {'color': '#0550ae'},
  'regexp': {'color': '#0a3069'},
  'addition': {'color': '#116329'},
  'deletion': {'color': '#82071e'},
};

/// Page section of the base (06 §2.3 defaults).
const Map<String, Object?> wonkyDefaultPageJson = {
  'paperColor': '@page',
  'canvasColor': '@canvas',
  'pageShadow': 'soft',
  'pagelessMaxWidth': '760px',
  'pagelessPadding': {
    'top': '48px',
    'right': '32px',
    'bottom': '96px',
    'left': '32px',
  },
  'defaultMargins': '1in',
  'headerFooter': {
    'fontFamily': '@body',
    'fontSize': '9pt',
    'fontWeight': 400,
    'fontStyle': 'normal',
    'color': '@muted',
    'caseTransform': 'none',
    'letterSpacing': '0pt',
    'lineHeight': 1.2,
    'align': 'left',
  },
};

/// Complete element values of the base (every property the resolver reads
/// that does not inherit from body).
const Map<String, Object?> wonkyDefaultElementsJson = {
  'body': {
    'fontFamily': '@body',
    'fontSize': '11pt',
    'fontWeight': 400,
    'fontStyle': 'normal',
    'lineHeight': 1.5,
    'letterSpacing': '0pt',
    'color': '@text',
    'caseTransform': 'none',
    'fontFeatures': <String>[],
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'padding': '0pt',
    'background': 'transparent',
    'borderRadius': '0pt',
    'align': 'left',
    'keepWithNext': false,
    'pageBreakBefore': false,
    'firstLineIndent': '0pt',
  },
  'headings': {
    'fontFamily': '@heading',
    'fontWeight': 600,
    'lineHeight': 1.25,
    'color': '@heading',
    'spaceBefore': '0pt',
    'spaceAfter': '6pt',
    'padding': '0pt',
    'background': 'transparent',
    'borderRadius': '0pt',
    'align': 'left',
    'keepWithNext': true,
    'pageBreakBefore': false,
    'numbering': {
      'enabled': false,
      'fromLevel': 1,
      'toLevel': 6,
      'style': 'decimal',
      'suffix': ' ',
    },
  },
  'h1': {
    'fontSize': '24pt',
    'spaceBefore': '24pt',
    'spaceAfter': '8pt',
    'borderBottomGap': '4pt',
  },
  'h2': {
    'fontSize': '18pt',
    'spaceBefore': '20pt',
    'spaceAfter': '6pt',
    'borderBottomGap': '4pt',
  },
  'h3': {
    'fontSize': '15pt',
    'spaceBefore': '16pt',
    'spaceAfter': '6pt',
    'borderBottomGap': '3pt',
  },
  'h4': {
    'fontSize': '13pt',
    'spaceBefore': '14pt',
    'spaceAfter': '4pt',
    'borderBottomGap': '3pt',
  },
  'h5': {
    'fontSize': '12pt',
    'spaceBefore': '12pt',
    'spaceAfter': '4pt',
    'borderBottomGap': '2pt',
  },
  'h6': {
    'fontSize': '11pt',
    'spaceBefore': '12pt',
    'spaceAfter': '4pt',
    'borderBottomGap': '2pt',
  },
  'bold': {'fontWeight': 700},
  'italic': {'fontStyle': 'italic'},
  'strike': {'lineThickness': '1px'},
  'inlineCode': {
    'fontFamily': '@mono',
    'fontWeight': 400,
    'fontStyle': 'normal',
    'letterSpacing': '0em',
    'fontFeatures': <String>[],
    'sizeRatio': 0.9,
    'color': '@codeText',
    'background': '@codeBg',
    'paddingX': '3px',
    'borderRadius': '3px',
  },
  'link': {
    'color': '@link',
    'hoverColor': '@linkHover',
    'underline': 'always',
    'underlineStyle': 'solid',
    'underlineThickness': '1px',
  },
  'mention': {
    'color': '@mentionText',
    'background': '@mentionBg',
    'borderRadius': '4px',
    'fontWeight': 600,
    'prefix': '@',
  },
  // Wonky Markdown elements (Write 11 §8), close to the Serverpod blog.
  'callout': {
    'spaceBefore': '6pt',
    'spaceAfter': '10pt',
    'padding': '12pt',
    'borderRadius': '6pt',
    'borderWidth': '1px',
    'titleCaseTransform': 'uppercase',
    'titleSizeRatio': 0.75,
    'titleWeight': 600,
    'info': {'color': '#0284c7'},
    'tip': {'color': '#059669'},
    'note': {'color': '#6b7280'},
    'warning': {'color': '#d97706'},
    'danger': {'color': '#dc2626'},
  },
  'details': {
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'padding': '14pt',
    'background': '@page',
    'border': {'width': '1px', 'style': 'solid', 'color': '@border'},
    'borderRadius': '9pt',
    'summaryWeight': 600,
    'chevronColor': '@muted',
  },
  'card': {
    'spaceBefore': '10pt',
    'spaceAfter': '14pt',
    'padding': {
      'top': '14pt',
      'right': '18pt',
      'bottom': '14pt',
      'left': '18pt',
    },
    'background': '@codeBg',
    'borderRadius': '9pt',
    'shadow': 'soft',
  },
  'grid': {
    'spaceBefore': '10pt',
    'spaceAfter': '14pt',
    'bulletColor': '@accent',
    'columnGap': '24pt',
    'rowGap': '9pt',
  },
  'button': {
    'background': '@accent',
    'color': '@page',
    'secondaryBackground': '@muted',
    'secondaryColor': '@page',
    'borderRadius': '6pt',
    'fontWeight': 600,
    'arrowColor': '@accent',
    'arrowWeight': 600,
  },
  'chip': {
    'background': '@codeBg',
    'color': '@text',
    'borderRadius': '200pt',
    'fontWeight': 500,
  },
  'stepBadge': {'background': '@accent', 'color': '@page', 'sizeRatio': 1.1},
  'blockquote': {
    'color': '@quoteText',
    'background': '@quoteBg',
    'bar': {'width': '3px', 'style': 'solid', 'color': '@quoteBar'},
    'italic': false,
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'padding': {'top': '0pt', 'right': '0pt', 'bottom': '0pt', 'left': '12px'},
    'borderRadius': '0pt',
    'align': 'left',
    'keepWithNext': false,
    'pageBreakBefore': false,
  },
  'codeBlock': {
    'fontFamily': '@mono',
    'fontSize': '0.9em',
    'fontWeight': 400,
    'fontStyle': 'normal',
    'letterSpacing': '0em',
    'color': '@codeText',
    'caseTransform': 'none',
    'fontFeatures': <String>[],
    'background': '@codeBg',
    'padding': '12px',
    'borderRadius': '6px',
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'align': 'left',
    'keepWithNext': false,
    'pageBreakBefore': false,
    'wrap': true,
    'showLanguageLabel': true,
    'tabSize': 4,
    'lineNumbers': false,
  },
  'list': {
    'bullets': ['•', '◦', '▪', '•', '◦', '▪', '•', '◦', '▪'],
    'bulletScale': 1,
    'numbering': [
      'decimal',
      'lowerAlpha',
      'lowerRoman',
      'decimal',
      'lowerAlpha',
      'lowerRoman',
      'decimal',
      'lowerAlpha',
      'lowerRoman',
    ],
    'numberSuffix': '.',
    'indentPerLevel': '18pt',
    'markerGap': '6pt',
    'itemSpacing': '2pt',
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'padding': '0pt',
    'background': 'transparent',
    'borderRadius': '0pt',
    'align': 'left',
    'keepWithNext': false,
    'pageBreakBefore': false,
  },
  'task': {
    'checkbox': {
      'shape': 'rounded',
      'size': '0.9em',
      'borderColor': '@muted',
      'checkedFill': '@accent',
      'checkColor': '@page',
    },
    'checkedText': {'strike': true, 'opacity': 0.7},
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'padding': '0pt',
    'background': 'transparent',
    'borderRadius': '0pt',
    'align': 'left',
    'keepWithNext': false,
    'pageBreakBefore': false,
  },
  'rule': {
    'style': 'solid',
    'thickness': '1px',
    'color': '@border',
    'width': '100%',
    'ornament': '⁂',
    'spaceBefore': '12pt',
    'spaceAfter': '12pt',
    'padding': '0pt',
    'background': 'transparent',
    'borderRadius': '0pt',
    'align': 'center',
    'keepWithNext': false,
    'pageBreakBefore': false,
  },
  'image': {
    'maxWidth': '100%',
    'align': 'center',
    'borderRadius': '6px',
    'shadow': 'none',
    'spaceBefore': '8pt',
    'spaceAfter': '8pt',
    'padding': '0pt',
    'background': 'transparent',
    'keepWithNext': false,
    'pageBreakBefore': false,
    'caption': {
      'show': true,
      'align': 'center',
      'gap': '4pt',
      'fontSize': '0.85em',
      'color': '@muted',
      'fontStyle': 'normal',
    },
  },
  'table': {
    'width': 'auto',
    'headerBackground': '@tableHeaderBg',
    'headerColor': '@heading',
    'headerFontWeight': 600,
    'borders': 'all',
    'borderColor': '@border',
    'borderWidth': '1px',
    'zebra': false,
    'zebraColor': '@tableStripe',
    'cellPadding': {
      'top': '4pt',
      'right': '6pt',
      'bottom': '4pt',
      'left': '6pt',
    },
    'fontSizeRatio': 1,
    'spaceBefore': '0pt',
    'spaceAfter': '8pt',
    'padding': '0pt',
    'background': 'transparent',
    'borderRadius': '0pt',
    'align': 'left',
    'keepWithNext': false,
    'pageBreakBefore': false,
  },
};

/// The parsed base layer of the cascade.
final class BaseTheme {
  BaseTheme._(this.theme);

  /// The base as a theme (*Wonky Default* light values, no dark spec).
  final WriteThemeData theme;

  /// The singleton base.
  static final BaseTheme instance = BaseTheme._(_parse());

  static WriteThemeData _parse() {
    final r = parseThemeJson({
      'schemaVersion': currentThemeSchemaVersion,
      'name': 'Wonky Default',
      'palette': wonkyDefaultPaletteJson,
      'page': wonkyDefaultPageJson,
      'elements': wonkyDefaultElementsJson,
      'syntax': wonkyDefaultSyntaxJson,
    });
    if (r.theme == null) {
      throw StateError('Invalid base theme: ${r.errors}');
    }
    return r.theme!;
  }

  /// Base values of [element].
  PropertyBag element(ThemeElement element) => theme.element(element);

  /// Base page values.
  PropertyBag get page => theme.page;

  /// Base syntax style of [token], or `null`.
  PropertyBag? syntax(SyntaxToken token) => theme.syntax[token];

  /// Base light palette.
  ThemePalette get palette => theme.palette;

  /// Base palette value of [key] (used when resetting a required light
  /// palette entry).
  ColorRef? paletteValue(PaletteKey key) => theme.palette[key];

  /// Properties defined by the catalog for [element] (for editors).
  static Iterable<String> propertiesOf(ThemeElement element) =>
      ThemeCatalog.elements[element]!.fields.keys;
}
