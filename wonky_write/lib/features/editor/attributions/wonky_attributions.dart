import 'package:collection/collection.dart';
import 'package:super_editor/super_editor.dart';

/// Comment anchor `cmt_<threadUuid>: true` (Write 02 §4.2).
///
/// Every thread has its own attribution id, so overlapping comments compose
/// independently (attributions with the same id cannot overlap).
class CommentAttribution implements Attribution {
  const CommentAttribution(this.threadUuid);

  final String threadUuid;

  /// The Delta attribute key, `cmt_<threadUuid>`.
  String get key => 'cmt_$threadUuid';

  @override
  String get id => key;

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommentAttribution && other.threadUuid == threadUuid;

  @override
  int get hashCode => threadUuid.hashCode;

  @override
  String toString() => '[CommentAttribution]: $threadUuid';
}

/// Kind of a suggestion part (Write 08 §2.2).
enum SuggestionType {
  /// Suggested insertion.
  insertion('ins'),

  /// Suggested deletion (the text is still in the document).
  deletion('del'),

  /// Suggested formatting change; `before` holds the original attributes.
  format('fmt');

  const SuggestionType(this.code);

  /// The value of the `t` field.
  final String code;

  static SuggestionType? tryParse(Object? code) =>
      SuggestionType.values.firstWhereOrNull((t) => t.code == code);
}

/// Suggestion `sug_<id>: {t, by, at, before?, via?}` (Write 02 §1.1).
///
/// The raw attribute value is kept in [data] so that it round-trips exactly.
class SuggestionAttribution implements Attribution {
  const SuggestionAttribution(this.suggestionId, this.data);

  /// Creates a suggestion attribution from typed values.
  factory SuggestionAttribution.create({
    required String suggestionId,
    required SuggestionType type,
    required String authorUuid,
    required int atMs,
    Map<String, dynamic>? before,
    String? via,
  }) {
    return SuggestionAttribution(suggestionId, {
      't': type.code,
      'by': authorUuid,
      'at': atMs,
      'before': ?before,
      'via': ?via,
    });
  }

  final String suggestionId;

  /// The attribute value (`{t, by, at, before?, via?}`).
  final Map<String, dynamic> data;

  /// The Delta attribute key, `sug_<id>`.
  String get key => 'sug_$suggestionId';

  SuggestionType? get type => SuggestionType.tryParse(data['t']);

  String? get authorUuid => data['by'] as String?;

  int? get atMs => (data['at'] as num?)?.toInt();

  Map<String, dynamic>? get before =>
      (data['before'] as Map?)?.cast<String, dynamic>();

  String? get via => data['via'] as String?;

  @override
  String get id => key;

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionAttribution &&
          other.suggestionId == suggestionId &&
          const DeepCollectionEquality().equals(other.data, data);

  @override
  int get hashCode => suggestionId.hashCode;

  @override
  String toString() => '[SuggestionAttribution]: $suggestionId $data';
}

/// Mention of a user: Delta `mention: <userUuid>` (always paired with a
/// `mailto:` [LinkAttribution]).
class MentionAttribution implements Attribution {
  const MentionAttribution(this.userUuid);

  final String userUuid;

  @override
  String get id => 'mention';

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MentionAttribution && other.userUuid == userUuid;

  @override
  int get hashCode => userUuid.hashCode;

  @override
  String toString() => '[MentionAttribution]: $userUuid';
}

/// The Wonky Markdown look of a link: Delta `linkStyle: arrow | button |
/// buttonSecondary` (Write 11 §2.1); always paired with a [LinkAttribution].
class LinkStyleAttribution implements Attribution {
  const LinkStyleAttribution(this.style);

  /// An arrow link (`:link[…](…)`).
  static const arrow = LinkStyleAttribution('arrow');

  /// A primary button (`:button[…](…)`).
  static const button = LinkStyleAttribution('button');

  /// A secondary button (`:button[…](…){variant=secondary}`).
  static const buttonSecondary = LinkStyleAttribution('buttonSecondary');

  /// `arrow`, `button` or `buttonSecondary`.
  final String style;

  /// Whether this is a button (primary or secondary).
  bool get isButton => style != 'arrow';

  @override
  String get id => 'linkStyle';

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkStyleAttribution && other.style == style;

  @override
  int get hashCode => style.hashCode;

  @override
  String toString() => '[LinkStyleAttribution]: $style';
}

/// A Wonky Markdown chip: Delta `chip: true | <icon>` (Write 11 §2.1). The
/// icon is kept, not shown (WM10).
class ChipAttribution implements Attribution {
  const ChipAttribution([this.icon]);

  /// A chip without an icon.
  static const plain = ChipAttribution();

  /// The icon name, or `null`.
  final String? icon;

  @override
  String get id => 'chip';

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChipAttribution && other.icon == icon;

  @override
  int get hashCode => icon.hashCode;

  @override
  String toString() => '[ChipAttribution]: ${icon ?? '-'}';
}

/// Presentation-only syntax highlighting token (Write 04 §15.4). Never part of
/// the document Delta.
class CodeTokenAttribution implements Attribution {
  const CodeTokenAttribution(this.tokenClass);

  /// highlight.js token class, e.g. `keyword`, `string`.
  final String tokenClass;

  @override
  String get id => 'code-token';

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CodeTokenAttribution && other.tokenClass == tokenClass;

  @override
  int get hashCode => tokenClass.hashCode;

  @override
  String toString() => '[CodeTokenAttribution]: $tokenClass';
}

/// Presentation-only extra space after a character (`em` of the font size,
/// as letter spacing): around chips and buttons so their pills never touch,
/// and after an arrow link for its arrow (Write 11 §7.2). Never part of the
/// document Delta.
class PillGapAttribution implements Attribution {
  const PillGapAttribution(this.em);

  /// After a pill's last character (its right padding).
  static const pill = PillGapAttribution(0.45);

  /// A space next to a pill (room for the pill's left padding).
  static const space = PillGapAttribution(0.6);

  /// After an arrow link (room for the arrow).
  static const arrow = PillGapAttribution(1.05);

  final double em;

  @override
  String get id => 'pill-gap';

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PillGapAttribution && other.em == em;

  @override
  int get hashCode => em.hashCode;

  @override
  String toString() => '[PillGapAttribution]: $em';
}

/// Presentation-only marker for text that is hidden or shown differently by a
/// suggestion preview mode (Write 04 §31). Never part of the document Delta.
class SuggestionPreviewAttribution implements Attribution {
  const SuggestionPreviewAttribution(this.hidden);

  final bool hidden;

  @override
  String get id => 'suggestion-preview';

  @override
  bool canMergeWith(Attribution other) => this == other;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionPreviewAttribution && other.hidden == hidden;

  @override
  int get hashCode => hidden.hashCode;
}
