/// A run of uniformly formatted inline text and its Delta attributes
/// (Write 07 §2.1; shared by the Markdown inline codec).
library;

/// A run of text with uniform inline formatting.
final class InlineRun {
  /// Creates a run.
  const InlineRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.strike = false,
    this.code = false,
    this.link,
    this.mentionUserUuid,
    this.linkStyle,
    this.chip = false,
    this.chipIcon,
  });

  /// Text; may contain U+2028 (soft break), never `"\n"`.
  final String text;

  /// Bold.
  final bool bold;

  /// Italic.
  final bool italic;

  /// Strikethrough.
  final bool strike;

  /// Inline code.
  final bool code;

  /// Link target.
  final String? link;

  /// Mentioned user UUID (with a `mailto:` [link]).
  final String? mentionUserUuid;

  /// Wonky Markdown look of the [link]: `arrow`, `button` or
  /// `buttonSecondary` (Write 11 §2.1).
  final String? linkStyle;

  /// Whether the run is a Wonky Markdown chip.
  final bool chip;

  /// The chip's icon name (kept, not shown; Write 11 WM10).
  final String? chipIcon;

  /// Whether formatting equals [other]'s.
  bool sameFormat(InlineRun other) =>
      bold == other.bold &&
      italic == other.italic &&
      strike == other.strike &&
      code == other.code &&
      link == other.link &&
      mentionUserUuid == other.mentionUserUuid &&
      linkStyle == other.linkStyle &&
      chip == other.chip &&
      chipIcon == other.chipIcon;

  /// Whether the run has no formatting.
  bool get isPlain =>
      !bold &&
      !italic &&
      !strike &&
      !code &&
      link == null &&
      mentionUserUuid == null &&
      linkStyle == null &&
      !chip;

  /// Copy with changed fields.
  InlineRun copyWith({
    String? text,
    bool? bold,
    bool? italic,
    bool? strike,
    bool? code,
    String? link,
    bool clearLink = false,
    String? mentionUserUuid,
    bool clearMention = false,
    String? linkStyle,
    bool clearLinkStyle = false,
    bool? chip,
    String? chipIcon,
  }) => InlineRun(
    text ?? this.text,
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    strike: strike ?? this.strike,
    code: code ?? this.code,
    link: clearLink ? null : (link ?? this.link),
    mentionUserUuid: clearMention
        ? null
        : (mentionUserUuid ?? this.mentionUserUuid),
    linkStyle: clearLinkStyle ? null : (linkStyle ?? this.linkStyle),
    chip: chip ?? this.chip,
    chipIcon: chip == false ? null : (chipIcon ?? this.chipIcon),
  );

  /// Delta attributes of this run (`null` when plain). A chip or a styled
  /// link drops what it excludes (Write 11 §2.1).
  Map<String, dynamic>? toAttributes() {
    if (chip) return {'chip': chipIcon ?? true};
    final styled = linkStyle != null && link != null;
    final a = <String, dynamic>{
      if (bold && !code && !styled) 'bold': true,
      if (italic && !code && !styled) 'italic': true,
      if (strike && !code && !styled) 'strike': true,
      if (code && !styled) 'code': true,
      'link': ?link,
      if (!styled) 'mention': ?mentionUserUuid,
      if (styled) 'linkStyle': linkStyle,
    };
    return a.isEmpty ? null : a;
  }

  /// Reads a run from Delta attributes (overlays are ignored).
  factory InlineRun.fromAttributes(String text, Map<String, dynamic>? a) =>
      InlineRun(
        text,
        bold: a?['bold'] == true,
        italic: a?['italic'] == true,
        strike: a?['strike'] == true,
        code: a?['code'] == true,
        link: a?['link'] as String?,
        mentionUserUuid: a?['mention'] as String?,
        linkStyle: a?['linkStyle'] as String?,
        chip: a?['chip'] == true || a?['chip'] is String,
        chipIcon: a?['chip'] is String ? a!['chip'] as String : null,
      );

  @override
  bool operator ==(Object other) =>
      other is InlineRun && other.text == text && sameFormat(other);

  @override
  int get hashCode => Object.hash(
    text,
    bold,
    italic,
    strike,
    code,
    link,
    mentionUserUuid,
    linkStyle,
    chip,
    chipIcon,
  );

  @override
  String toString() {
    final f = [
      if (bold) 'b',
      if (italic) 'i',
      if (strike) 's',
      if (code) 'c',
      if (link != null) 'link=$link',
      if (mentionUserUuid != null) '@$mentionUserUuid',
      if (linkStyle != null) 'style=$linkStyle',
      if (chip) 'chip${chipIcon == null ? '' : '=$chipIcon'}',
    ];
    return 'Run("$text"${f.isEmpty ? '' : ' ${f.join(',')}'})';
  }

  /// Merges adjacent runs with equal formatting and drops empty runs.
  static List<InlineRun> merge(Iterable<InlineRun> runs) {
    final out = <InlineRun>[];
    for (final r in runs) {
      if (r.text.isEmpty) continue;
      if (out.isNotEmpty && out.last.sameFormat(r)) {
        out[out.length - 1] = out.last.copyWith(text: out.last.text + r.text);
      } else {
        out.add(r);
      }
    }
    return out;
  }

  /// Concatenated text of [runs].
  static String plainText(Iterable<InlineRun> runs) =>
      runs.map((r) => r.text).join();
}
