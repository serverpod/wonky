/// Smaller theme value types: font references, borders, edges and the
/// enumerations of the theme schema (06 §2.1, §2.4).
library;

import 'color_ref.dart';
import 'json_util.dart';
import 'length.dart';

/// A font role of the theme `fonts` section.
enum FontRole implements JsonEnum {
  /// Body text font.
  body,

  /// Heading font.
  heading,

  /// Monospace font (code).
  mono;

  @override
  String get json => name;
}

/// A font reference: a role (`"@body"`, `"@heading"`, `"@mono"`) or a family
/// name from the font registry (06 §2.1).
final class FontRef {
  /// A reference to the font of [role].
  const FontRef.role(FontRole this.role) : family = null;

  /// A concrete family name.
  const FontRef.family(String this.family) : role = null;

  /// The referenced role, or `null` for a concrete family.
  final FontRole? role;

  /// The concrete family, or `null` for a role reference.
  final String? family;

  /// Parses `"@body"`/`"@heading"`/`"@mono"` or a family name. Returns
  /// `null` for an empty string or an unknown `@role`.
  static FontRef? tryParse(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    if (t.startsWith('@')) {
      final role = enumFromJson(FontRole.values, t.substring(1));
      return role == null ? null : FontRef.role(role);
    }
    return FontRef.family(t);
  }

  /// The JSON form.
  String toJson() => role != null ? '@${role!.name}' : family!;

  @override
  bool operator ==(Object other) =>
      other is FontRef && other.role == role && other.family == family;

  @override
  int get hashCode => Object.hash(role, family);

  @override
  String toString() => toJson();
}

/// Text alignment (06 §2.1).
enum ThemeAlign implements JsonEnum {
  /// Start-aligned (mirrored for RTL documents).
  left,

  /// Centered.
  center,

  /// End-aligned (mirrored for RTL documents).
  right,

  /// Justified.
  justify;

  @override
  String get json => name;
}

/// Case transform of text (06 §2.1, §6.4).
enum CaseTransform implements JsonEnum {
  /// No transform.
  none,

  /// ALL CAPS.
  uppercase,

  /// all lower case.
  lowercase,

  /// First Letter Of Each Word.
  capitalize,

  /// Small caps (OpenType `smcp`).
  smallCaps;

  @override
  String get json => name;
}

/// Style of a border or rule line.
enum LineStyle implements JsonEnum {
  /// No line.
  none('none'),

  /// Solid line.
  solid('solid'),

  /// Dashed line.
  dashed('dashed'),

  /// Dotted line.
  dotted('dotted'),

  /// Double line.
  doubleLine('double');

  const LineStyle(this.json);

  @override
  final String json;
}

/// A (possibly partial) border specification `{width, style, color}`
/// (06 §2.1). Missing parts inherit / use defaults during resolution.
final class BorderSpec {
  /// Creates a border spec.
  const BorderSpec({this.width, this.style, this.color});

  /// Border width.
  final Length? width;

  /// Line style.
  final LineStyle? style;

  /// Line color.
  final ColorRef? color;

  /// Whether no part is set.
  bool get isEmpty => width == null && style == null && color == null;

  /// Returns this spec with the non-null parts of [over] applied.
  BorderSpec merge(BorderSpec? over) => over == null
      ? this
      : BorderSpec(
          width: over.width ?? width,
          style: over.style ?? style,
          color: over.color ?? color,
        );

  /// The JSON form (only set parts).
  JsonMap toJson() => {
    if (width != null) 'width': width!.toJson(),
    if (style != null) 'style': style!.json,
    if (color != null) 'color': color!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is BorderSpec &&
      other.width == width &&
      other.style == style &&
      other.color == color;

  @override
  int get hashCode => Object.hash(width, style, color);

  @override
  String toString() => 'BorderSpec(${toJson()})';
}

/// Four optional per-side values (06 §2.1 `Edges<T>`). In JSON either a
/// single `T` (all sides) or `{"top", "right", "bottom", "left"}`.
final class Edges<T extends Object> {
  /// Creates edges with the given sides.
  const Edges({this.top, this.right, this.bottom, this.left});

  /// All four sides set to [value].
  const Edges.all(T value)
    : top = value,
      right = value,
      bottom = value,
      left = value;

  /// Vertical sides [vertical], horizontal sides [horizontal].
  const Edges.symmetric({T? vertical, T? horizontal})
    : top = vertical,
      bottom = vertical,
      left = horizontal,
      right = horizontal;

  /// Top side.
  final T? top;

  /// Right side.
  final T? right;

  /// Bottom side.
  final T? bottom;

  /// Left side.
  final T? left;

  /// Whether no side is set.
  bool get isEmpty =>
      top == null && right == null && bottom == null && left == null;

  /// Whether all four sides are set to equal values.
  bool get isUniform =>
      top != null && top == right && top == bottom && top == left;

  /// Returns these edges with the set sides of [over] applied.
  Edges<T> merge(Edges<T>? over) => over == null
      ? this
      : Edges<T>(
          top: over.top ?? top,
          right: over.right ?? right,
          bottom: over.bottom ?? bottom,
          left: over.left ?? left,
        );

  /// Maps each set side with [f].
  Edges<R> map<R extends Object>(R Function(T value) f) => Edges<R>(
    top: top == null ? null : f(top as T),
    right: right == null ? null : f(right as T),
    bottom: bottom == null ? null : f(bottom as T),
    left: left == null ? null : f(left as T),
  );

  /// The JSON form: a single value when uniform, else a map of the set
  /// sides. [encode] encodes one side.
  Object? toJson(Object? Function(T value) encode) {
    if (isUniform) return encode(top as T);
    return <String, Object?>{
      if (top != null) 'top': encode(top as T),
      if (right != null) 'right': encode(right as T),
      if (bottom != null) 'bottom': encode(bottom as T),
      if (left != null) 'left': encode(left as T),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is Edges<T> &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom &&
      other.left == left;

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  String toString() =>
      'Edges(top: $top, right: $right, bottom: $bottom, left: $left)';
}

/// Theme variant (06 §1).
enum ThemeVariant implements JsonEnum {
  /// Light variant (default for exports and print).
  light,

  /// Dark variant.
  dark;

  @override
  String get json => name;
}

/// The element keys of the theme `elements` section (06 §2.4).
enum ThemeElement implements JsonEnum {
  /// Body text and paragraphs.
  body,

  /// Shared base of all headings.
  headings,

  /// Heading level 1.
  h1,

  /// Heading level 2.
  h2,

  /// Heading level 3.
  h3,

  /// Heading level 4.
  h4,

  /// Heading level 5.
  h5,

  /// Heading level 6.
  h6,

  /// Spacing override for a paragraph directly after a heading.
  paragraphAfterHeading,

  /// Bold text (inline delta).
  bold,

  /// Italic text (inline delta).
  italic,

  /// Struck-through text (inline delta).
  strike,

  /// Inline code (inline delta).
  inlineCode,

  /// Links (inline delta).
  link,

  /// Mentions (inline delta).
  mention,

  /// Blockquotes.
  blockquote,

  /// Code blocks.
  codeBlock,

  /// Bullet and ordered lists.
  list,

  /// Task lists.
  task,

  /// Horizontal rules.
  rule,

  /// Images and captions.
  image,

  /// Tables.
  table,

  /// Wonky Markdown callouts (Write 11 §8).
  callout,

  /// Wonky Markdown details.
  details,

  /// Wonky Markdown cards.
  card,

  /// Wonky Markdown grids.
  grid,

  /// Wonky Markdown buttons and arrow links (inline).
  button,

  /// Wonky Markdown chips (inline).
  chip,

  /// Wonky Markdown numbered heading badges.
  stepBadge,

  /// Page header (overrides `page.headerFooter`).
  header,

  /// Page footer (overrides `page.headerFooter`).
  footer;

  @override
  String get json => name;

  /// The heading element for [level] 1–6.
  static ThemeElement heading(int level) => switch (level) {
    1 => h1,
    2 => h2,
    3 => h3,
    4 => h4,
    5 => h5,
    6 => h6,
    _ => throw RangeError.range(level, 1, 6, 'level'),
  };

  /// The heading level 1–6 of `h1…h6`, else `null`.
  int? get headingLevel => switch (this) {
    h1 => 1,
    h2 => 2,
    h3 => 3,
    h4 => 4,
    h5 => 5,
    h6 => 6,
    _ => null,
  };

  /// The element for JSON key [name], or `null`.
  static ThemeElement? fromJsonName(String name) =>
      enumFromJson(ThemeElement.values, name);
}
