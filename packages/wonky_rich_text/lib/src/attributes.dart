/// Wonky Delta Schema v1 attribute keys and typed helpers
/// (specs/wonky_write/02-document-model.md §1).
library;

import 'package:collection/collection.dart';

/// Attribute keys of the Wonky Delta Schema v1.
///
/// Inline attributes live on text (and embed) inserts; block attributes live
/// on the `"\n"` that ends a line. Overlay attributes (`cmt_*`, `sug_*`) may be
/// on any insert.
abstract final class WonkyAttr {
  // Inline.

  /// `true` — bold text (`**x**`).
  static const bold = 'bold';

  /// `true` — italic text (`*x*`).
  static const italic = 'italic';

  /// `true` — struck-through text (`~~x~~`).
  static const strike = 'strike';

  /// `true` — inline code (`` `x` ``). Excludes [bold], [italic], [strike].
  static const code = 'code';

  /// `String` — absolute URL, `mailto:` or `wonky://` link.
  static const link = 'link';

  /// `String` — user UUID of a mention; always paired with a `mailto:` [link].
  static const mention = 'mention';

  // Block.

  /// `int` 1–6 — heading level.
  static const header = 'header';

  /// `true` — blockquote line.
  static const blockquote = 'blockquote';

  /// `String` — code block line; the value is the language (`""` = none).
  static const codeBlock = 'code-block';

  /// `String` — `bullet`, `ordered`, `checked`, `unchecked`.
  static const list = 'list';

  /// `int` 1–8 — list nesting level; only valid together with [list].
  static const indent = 'indent';

  // Overlays.

  /// Prefix of comment anchor keys: `cmt_<threadUuid>: true`.
  static const commentPrefix = 'cmt_';

  /// Prefix of suggestion keys: `sug_<suggestionId>: {t, by, at, before?, via?}`.
  static const suggestionPrefix = 'sug_';

  /// All inline attribute keys.
  static const inlineKeys = {bold, italic, strike, code, link, mention};

  /// Inline keys that `code` excludes.
  static const codeExcludedKeys = {bold, italic, strike};

  /// All block attribute keys.
  static const blockKeys = {header, blockquote, codeBlock, list, indent};

  /// Mutually exclusive block-type keys (in normalization priority order);
  /// only [blockquote] may sit next to [list] (a list item in a quote).
  static const blockTypeKeys = [codeBlock, header, list, blockquote];

  /// Maximum list indent.
  static const maxIndent = 8;

  /// Whether [key] is a comment anchor key (`cmt_*`).
  static bool isComment(String key) =>
      key.startsWith(commentPrefix) && key.length > commentPrefix.length;

  /// Whether [key] is a suggestion key (`sug_*`).
  static bool isSuggestion(String key) =>
      key.startsWith(suggestionPrefix) && key.length > suggestionPrefix.length;

  /// Whether [key] is an overlay key (`cmt_*` or `sug_*`).
  static bool isOverlay(String key) => isComment(key) || isSuggestion(key);

  /// Whether [key] is an inline attribute key.
  static bool isInline(String key) => inlineKeys.contains(key);

  /// Whether [key] is a block attribute key.
  static bool isBlock(String key) => blockKeys.contains(key);

  /// The attribute key of comment thread [threadUuid].
  static String commentKey(String threadUuid) => '$commentPrefix$threadUuid';

  /// The attribute key of suggestion [suggestionId].
  static String suggestionKey(String suggestionId) =>
      '$suggestionPrefix$suggestionId';

  /// The thread UUID of comment key [key], or `null` if it is not one.
  static String? commentThreadId(String key) =>
      isComment(key) ? key.substring(commentPrefix.length) : null;

  /// The suggestion id of suggestion key [key], or `null` if it is not one.
  static String? suggestionId(String key) =>
      isSuggestion(key) ? key.substring(suggestionPrefix.length) : null;
}

/// Values of the `list` block attribute.
enum ListKind {
  /// `- item`
  bullet('bullet'),

  /// `1. item`
  ordered('ordered'),

  /// `- [x] item`
  checked('checked'),

  /// `- [ ] item`
  unchecked('unchecked');

  const ListKind(this.value);

  /// The attribute value.
  final String value;

  /// Whether this is a task list kind.
  bool get isTask => this == checked || this == unchecked;

  /// Parses an attribute value; `null` if unknown.
  static ListKind? tryParse(Object? value) =>
      ListKind.values.firstWhereOrNull((k) => k.value == value);
}

/// The type of a line (block), derived from its block attributes.
enum BlockType {
  /// Plain paragraph.
  paragraph,

  /// Heading (`header` 1–6).
  heading,

  /// Blockquote line.
  quote,

  /// Code block line.
  code,

  /// Bullet list item.
  bullet,

  /// Ordered list item.
  ordered,

  /// Task list item.
  task,
}

/// Typed view of a line's block attributes.
final class BlockFormat {
  /// Creates a block format.
  const BlockFormat(
    this.type, {
    this.level = 0,
    this.indent = 0,
    this.checked = false,
    this.language = '',
    this.quoted = false,
  });

  /// A plain paragraph.
  static const paragraph = BlockFormat(BlockType.paragraph);

  /// Heading of [level] 1–6.
  const BlockFormat.heading(int level) : this(BlockType.heading, level: level);

  /// The block type.
  final BlockType type;

  /// Heading level (1–6) for [BlockType.heading], otherwise 0.
  final int level;

  /// List indent (0–8) for list and task items, otherwise 0.
  final int indent;

  /// Whether a task item is checked.
  final bool checked;

  /// Code block language (`""` = none).
  final String language;

  /// Whether a list or task item is inside a blockquote (`blockquote: true`
  /// next to `list`, Write 02 §1.2). Always false for other types: a quote
  /// line is [BlockType.quote].
  final bool quoted;

  /// Whether the line is part of a blockquote (a quote line or a quoted
  /// list item).
  bool get inQuote => type == BlockType.quote || quoted;

  /// Whether this is a list (bullet, ordered or task) item.
  bool get isList =>
      type == BlockType.bullet ||
      type == BlockType.ordered ||
      type == BlockType.task;

  /// The list kind for list items, else `null`.
  ListKind? get listKind => switch (type) {
    BlockType.bullet => ListKind.bullet,
    BlockType.ordered => ListKind.ordered,
    BlockType.task => checked ? ListKind.checked : ListKind.unchecked,
    _ => null,
  };

  /// Reads the block attributes of a line-end `"\n"`. Unknown or invalid
  /// values are treated as a paragraph (use the validator to detect them).
  static BlockFormat fromAttributes(Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) return paragraph;
    final code = attributes[WonkyAttr.codeBlock];
    if (code is String) return BlockFormat(BlockType.code, language: code);
    final header = attributes[WonkyAttr.header];
    if (header is int && header >= 1 && header <= 6) {
      return BlockFormat(BlockType.heading, level: header);
    }
    final list = ListKind.tryParse(attributes[WonkyAttr.list]);
    if (list != null) {
      final rawIndent = attributes[WonkyAttr.indent];
      final indent = rawIndent is int
          ? rawIndent.clamp(0, WonkyAttr.maxIndent)
          : 0;
      final quoted = attributes[WonkyAttr.blockquote] == true;
      return switch (list) {
        ListKind.bullet => BlockFormat(
          BlockType.bullet,
          indent: indent,
          quoted: quoted,
        ),
        ListKind.ordered => BlockFormat(
          BlockType.ordered,
          indent: indent,
          quoted: quoted,
        ),
        ListKind.checked => BlockFormat(
          BlockType.task,
          indent: indent,
          checked: true,
          quoted: quoted,
        ),
        ListKind.unchecked => BlockFormat(
          BlockType.task,
          indent: indent,
          quoted: quoted,
        ),
      };
    }
    if (attributes[WonkyAttr.blockquote] == true) {
      return const BlockFormat(BlockType.quote);
    }
    return paragraph;
  }

  /// The block attributes for this format (`null` for a paragraph).
  Map<String, dynamic>? toAttributes() => switch (type) {
    BlockType.paragraph => null,
    BlockType.heading => {WonkyAttr.header: level},
    BlockType.quote => {WonkyAttr.blockquote: true},
    BlockType.code => {WonkyAttr.codeBlock: language},
    BlockType.bullet || BlockType.ordered || BlockType.task => {
      WonkyAttr.list: listKind!.value,
      if (indent > 0) WonkyAttr.indent: indent,
      if (quoted) WonkyAttr.blockquote: true,
    },
  };

  /// An attribute patch (for a `retain` on the `"\n"`) that changes
  /// [current] block attributes into this format: every block key not in this
  /// format is set to `null`.
  Map<String, dynamic> patchFrom(Map<String, dynamic>? current) {
    final target = toAttributes() ?? const {};
    final patch = <String, dynamic>{};
    for (final key in WonkyAttr.blockKeys) {
      final has = current?.containsKey(key) ?? false;
      if (target.containsKey(key)) {
        if (!has || current![key] != target[key]) patch[key] = target[key];
      } else if (has) {
        patch[key] = null;
      }
    }
    return patch;
  }

  @override
  bool operator ==(Object other) =>
      other is BlockFormat &&
      other.type == type &&
      other.level == level &&
      other.indent == indent &&
      other.checked == checked &&
      other.language == language &&
      other.quoted == quoted;

  @override
  int get hashCode =>
      Object.hash(type, level, indent, checked, language, quoted);

  @override
  String toString() =>
      'BlockFormat($type, level: $level, indent: $indent, '
      'checked: $checked, language: "$language"'
      '${quoted ? ', quoted' : ''})';
}

/// Kind of a suggestion part.
enum SuggestionKind {
  /// Suggested insertion.
  ins('ins'),

  /// Suggested deletion (the text is still present, rendered struck).
  del('del'),

  /// Suggested formatting change; `before` holds the original attributes.
  fmt('fmt');

  const SuggestionKind(this.value);

  /// The JSON value (`t`).
  final String value;

  /// Parses a JSON value; `null` if unknown.
  static SuggestionKind? tryParse(Object? value) =>
      SuggestionKind.values.firstWhereOrNull((k) => k.value == value);
}

/// The value of a `sug_<id>` attribute:
/// `{"t": "ins"|"del"|"fmt", "by": userUuid, "at": epochMs, "before"?: {…},
/// "via"?: "ai"|"mcp"}`.
final class SuggestionMark {
  /// Creates a suggestion mark.
  const SuggestionMark({
    required this.kind,
    required this.by,
    required this.at,
    this.before,
    this.via,
  });

  /// Allowed values of [via].
  static const viaValues = {'ai', 'mcp'};

  /// The part kind.
  final SuggestionKind kind;

  /// Author user UUID.
  final String by;

  /// Creation time (epoch milliseconds; server-stamped).
  final int at;

  /// Original attributes for [SuggestionKind.fmt] (absent key = not set).
  final Map<String, dynamic>? before;

  /// `ai` or `mcp` when produced on the user's behalf.
  final String? via;

  /// Parses an attribute value; returns `null` when invalid.
  static SuggestionMark? tryParse(Object? json) {
    if (json is! Map) return null;
    final kind = SuggestionKind.tryParse(json['t']);
    final by = json['by'];
    final at = json['at'];
    if (kind == null || by is! String || by.isEmpty || at is! int) return null;
    final before = json['before'];
    if (before != null && before is! Map) return null;
    if (kind == SuggestionKind.fmt && before == null) return null;
    final via = json['via'];
    if (via != null && !viaValues.contains(via)) return null;
    for (final key in json.keys) {
      if (!const {'t', 'by', 'at', 'before', 'via'}.contains(key)) return null;
    }
    return SuggestionMark(
      kind: kind,
      by: by,
      at: at,
      before: before == null ? null : Map<String, dynamic>.from(before as Map),
      via: via as String?,
    );
  }

  /// The JSON attribute value.
  Map<String, dynamic> toJson() => {
    't': kind.value,
    'by': by,
    'at': at,
    if (before != null) 'before': Map<String, dynamic>.from(before!),
    if (via != null) 'via': via,
  };

  /// Copy with changed fields.
  SuggestionMark copyWith({
    SuggestionKind? kind,
    String? by,
    int? at,
    Map<String, dynamic>? before,
    String? via,
  }) => SuggestionMark(
    kind: kind ?? this.kind,
    by: by ?? this.by,
    at: at ?? this.at,
    before: before ?? this.before,
    via: via ?? this.via,
  );

  @override
  bool operator ==(Object other) =>
      other is SuggestionMark &&
      other.kind == kind &&
      other.by == by &&
      other.at == at &&
      other.via == via &&
      const DeepCollectionEquality().equals(other.before, before);

  @override
  int get hashCode => Object.hash(
    kind,
    by,
    at,
    via,
    const DeepCollectionEquality().hash(before),
  );

  @override
  String toString() => 'SuggestionMark(${toJson()})';
}

/// Attribute map helpers.
abstract final class Attributes {
  static const _eq = DeepCollectionEquality();

  /// Deep equality of attribute maps; `null` and `{}` are equal.
  static bool equals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if ((a == null || a.isEmpty) && (b == null || b.isEmpty)) return true;
    return _eq.equals(a, b);
  }

  /// Deep hash consistent with [equals].
  static int hash(Map<String, dynamic>? a) =>
      (a == null || a.isEmpty) ? 0 : _eq.hash(a);

  /// `null` for empty maps, otherwise a copy of [a].
  static Map<String, dynamic>? orNull(Map<String, dynamic>? a) =>
      (a == null || a.isEmpty) ? null : Map<String, dynamic>.from(a);

  /// The inline attributes of [a] (no overlays).
  static Map<String, dynamic> inline(Map<String, dynamic>? a) => {
    for (final e in (a ?? const <String, dynamic>{}).entries)
      if (WonkyAttr.isInline(e.key)) e.key: e.value,
  };

  /// The block attributes of [a] (no overlays).
  static Map<String, dynamic> block(Map<String, dynamic>? a) => {
    for (final e in (a ?? const <String, dynamic>{}).entries)
      if (WonkyAttr.isBlock(e.key)) e.key: e.value,
  };

  /// The overlay attributes (`cmt_*`, `sug_*`) of [a].
  static Map<String, dynamic> overlays(Map<String, dynamic>? a) => {
    for (final e in (a ?? const <String, dynamic>{}).entries)
      if (WonkyAttr.isOverlay(e.key)) e.key: e.value,
  };

  /// [a] without overlay attributes.
  static Map<String, dynamic> withoutOverlays(Map<String, dynamic>? a) => {
    for (final e in (a ?? const <String, dynamic>{}).entries)
      if (!WonkyAttr.isOverlay(e.key)) e.key: e.value,
  };

  /// All suggestion marks in [a], keyed by suggestion id (invalid values are
  /// skipped).
  static Map<String, SuggestionMark> suggestions(Map<String, dynamic>? a) {
    final result = <String, SuggestionMark>{};
    for (final e in (a ?? const <String, dynamic>{}).entries) {
      final id = WonkyAttr.suggestionId(e.key);
      if (id == null) continue;
      final mark = SuggestionMark.tryParse(e.value);
      if (mark != null) result[id] = mark;
    }
    return result;
  }

  /// All comment thread ids in [a].
  static Set<String> comments(Map<String, dynamic>? a) => {
    for (final e in (a ?? const <String, dynamic>{}).entries)
      if (WonkyAttr.isComment(e.key) && e.value == true)
        WonkyAttr.commentThreadId(e.key)!,
  };

  /// A `retain` attribute patch that turns [from] into [to] (keys removed in
  /// [to] are set to `null`); `null` when they are equal.
  static Map<String, dynamic>? diff(
    Map<String, dynamic>? from,
    Map<String, dynamic>? to,
  ) {
    from ??= const {};
    to ??= const {};
    final patch = <String, dynamic>{};
    for (final key in {...from.keys, ...to.keys}) {
      final inTo = to.containsKey(key);
      if (!inTo) {
        patch[key] = null;
      } else if (!from.containsKey(key) || !_eq.equals(from[key], to[key])) {
        patch[key] = to[key];
      }
    }
    return patch.isEmpty ? null : patch;
  }

  /// Applies a retain [patch] to [attributes] (null values remove keys).
  static Map<String, dynamic>? apply(
    Map<String, dynamic>? attributes,
    Map<String, dynamic>? patch,
  ) {
    final result = Map<String, dynamic>.from(attributes ?? const {});
    for (final e in (patch ?? const <String, dynamic>{}).entries) {
      if (e.value == null) {
        result.remove(e.key);
      } else {
        result[e.key] = e.value;
      }
    }
    return result.isEmpty ? null : result;
  }
}
