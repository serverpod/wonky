/// Wonky Markdown containers: the `box` block attribute
/// (specs/wonky_write/11-wonky-markdown.md §2.2).
library;

import 'package:collection/collection.dart';

import 'attributes.dart';

/// The type of a container.
enum BoxType {
  /// `:::info` … `:::danger` — a tinted note box.
  callout('callout'),

  /// `:::details` — an expandable item; its first H3 is the summary.
  details('details'),

  /// `:::card` — a promo box.
  card('card');

  const BoxType(this.value);

  /// The stored value.
  final String value;

  /// Parses a stored value; `null` if unknown.
  static BoxType? tryParse(Object? value) =>
      BoxType.values.firstWhereOrNull((t) => t.value == value);
}

/// The type of a callout.
enum CalloutVariant {
  /// Info.
  info('info', 'Info'),

  /// Tip.
  tip('tip', 'Tip'),

  /// Note.
  note('note', 'Note'),

  /// Warning.
  warning('warning', 'Warning'),

  /// Caution (the blog styles it as a warning with its own label).
  caution('caution', 'Caution'),

  /// Danger.
  danger('danger', 'Danger');

  const CalloutVariant(this.value, this.label);

  /// The stored value (and the directive name, `:::warning`).
  final String value;

  /// The English label shown when the callout has no title (the blog's).
  final String label;

  /// Parses a stored value; `null` if unknown.
  static CalloutVariant? tryParse(Object? value) =>
      CalloutVariant.values.firstWhereOrNull((v) => v.value == value);
}

/// One container a line is in: an entry of the `box` attribute.
final class BoxFrame {
  /// Creates a frame.
  const BoxFrame({
    required this.id,
    required this.type,
    this.variant,
    this.title,
  });

  /// A callout frame.
  const BoxFrame.callout({
    required String id,
    CalloutVariant variant = CalloutVariant.info,
    String? title,
  }) : this(id: id, type: BoxType.callout, variant: variant, title: title);

  /// Identity of the container (UUIDv7).
  final String id;

  /// The container type.
  final BoxType type;

  /// The callout type (callouts only, never null for them).
  final CalloutVariant? variant;

  /// The callout title (callouts only; plain text, single line).
  final String? title;

  /// Maximum nesting depth of containers.
  static const maxDepth = 3;

  /// Maximum title length.
  static const maxTitleLength = 200;

  /// Parses a frame; `null` when invalid. A callout without a valid variant
  /// is invalid; [variant] and [title] of other types are ignored.
  static BoxFrame? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final type = BoxType.tryParse(json['type']);
    if (id is! String || id.isEmpty || type == null) return null;
    if (type != BoxType.callout) return BoxFrame(id: id, type: type);
    final variant = CalloutVariant.tryParse(json['variant']);
    if (variant == null) return null;
    final title = json['title'];
    return BoxFrame(
      id: id,
      type: type,
      variant: variant,
      title: title is String && title.isNotEmpty ? title : null,
    );
  }

  /// The canonical form of a title: one line, trimmed, at most
  /// [maxTitleLength] characters, `]` written as `)` (the blog's grammar
  /// cannot hold it); `null` when empty.
  static String? canonicalTitle(String? title) {
    if (title == null) return null;
    var t = title
        .replaceAll(RegExp('[\n\r\t  ]'), ' ')
        .replaceAll(']', ')')
        .trim();
    if (t.length > maxTitleLength) t = t.substring(0, maxTitleLength).trim();
    return t.isEmpty ? null : t;
  }

  /// The JSON value.
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.value,
    if (type == BoxType.callout)
      'variant': (variant ?? CalloutVariant.info).value,
    if (type == BoxType.callout && title != null) 'title': title,
  };

  /// Copy with changed fields.
  BoxFrame copyWith({
    String? id,
    BoxType? type,
    CalloutVariant? variant,
    String? title,
    bool clearTitle = false,
  }) {
    final t = type ?? this.type;
    return BoxFrame(
      id: id ?? this.id,
      type: t,
      variant: t == BoxType.callout
          ? (variant ?? this.variant ?? CalloutVariant.info)
          : null,
      title: t != BoxType.callout || clearTitle ? null : (title ?? this.title),
    );
  }

  /// The label a callout shows: its title, else the variant's label.
  String get calloutLabel => title ?? (variant ?? CalloutVariant.info).label;

  /// Whether [other] has the same properties (ignoring [id]).
  bool sameProperties(BoxFrame other) =>
      other.type == type && other.variant == variant && other.title == title;

  @override
  bool operator ==(Object other) =>
      other is BoxFrame &&
      other.id == id &&
      other.type == type &&
      other.variant == variant &&
      other.title == title;

  @override
  int get hashCode => Object.hash(id, type, variant, title);

  @override
  String toString() => 'BoxFrame(${toJson()})';
}

/// Helpers for the `box` attribute value (a list of [BoxFrame] JSON maps).
abstract final class Boxes {
  /// The frames of a line's attributes, outermost first; invalid frames are
  /// skipped (use the validator to detect them).
  static List<BoxFrame> of(Map<String, dynamic>? attributes) =>
      parse(attributes?[WonkyAttr.box]);

  /// Parses a `box` value.
  static List<BoxFrame> parse(Object? value) {
    if (value is! List) return const [];
    final out = <BoxFrame>[];
    for (final v in value) {
      final f = BoxFrame.tryParse(v);
      if (f != null) out.add(f);
    }
    return out;
  }

  /// The `box` value of [frames] (`null` when empty).
  static List<Map<String, dynamic>>? toValue(List<BoxFrame> frames) =>
      frames.isEmpty ? null : [for (final f in frames) f.toJson()];

  /// Whether lines with frame paths [a] and [b] are in the same container
  /// at [depth] (the same frame ids at depths 0…[depth]).
  static bool sameAt(List<BoxFrame> a, List<BoxFrame> b, int depth) {
    if (a.length <= depth || b.length <= depth) return false;
    for (var k = 0; k <= depth; k++) {
      if (a[k].id != b[k].id) return false;
    }
    return true;
  }

  /// The number of leading containers [a] and [b] share.
  static int commonDepth(List<BoxFrame> a, List<BoxFrame> b) {
    var k = 0;
    while (k < a.length && k < b.length && a[k].id == b[k].id) {
      k++;
    }
    return k;
  }

  /// Whether two frame paths are the same containers (ids only).
  static bool samePath(List<BoxFrame> a, List<BoxFrame> b) =>
      a.length == b.length && commonDepth(a, b) == a.length;
}
