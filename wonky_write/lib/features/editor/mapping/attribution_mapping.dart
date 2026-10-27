import 'package:super_editor/super_editor.dart';

import '../attributions/wonky_attributions.dart';
import 'wonky_schema.dart';

/// Maps super_editor attributions ⇄ Wonky Delta inline/overlay attributes
/// (Write 02 §4.2). Only the attributions of the whitelist (Write 04 §2.5)
/// are mapped; everything else is presentation-only and ignored.
abstract final class AttributionMapping {
  /// Whether [attribution] is part of the Wonky schema (i.e. produces a Delta
  /// attribute).
  static bool isSchemaAttribution(Attribution attribution) =>
      attribution == boldAttribution ||
      attribution == italicsAttribution ||
      attribution == strikethroughAttribution ||
      attribution == codeAttribution ||
      attribution is LinkAttribution ||
      attribution is MentionAttribution ||
      attribution is LinkStyleAttribution ||
      attribution is ChipAttribution ||
      attribution is CommentAttribution ||
      attribution is SuggestionAttribution;

  /// Whether [attribution] is an overlay (comment or suggestion).
  static bool isOverlayAttribution(Attribution attribution) =>
      attribution is CommentAttribution || attribution is SuggestionAttribution;

  /// Whether [attribution] is inline formatting (bold, italic, strike, code).
  static bool isFormattingAttribution(Attribution attribution) =>
      attribution == boldAttribution ||
      attribution == italicsAttribution ||
      attribution == strikethroughAttribution ||
      attribution == codeAttribution;

  /// Converts [attributions] to Delta attributes, or `null` when there are none.
  ///
  /// With [overlaysOnly], only `cmt_*`/`sug_*` are produced (used for line ends).
  static Map<String, dynamic>? toAttributes(
    Iterable<Attribution> attributions, {
    bool overlaysOnly = false,
  }) {
    Map<String, dynamic>? result;
    for (final attribution in attributions) {
      final String key;
      final Object value;
      if (attribution is CommentAttribution) {
        key = attribution.key;
        value = true;
      } else if (attribution is SuggestionAttribution) {
        key = attribution.key;
        value = attribution.data;
      } else if (overlaysOnly) {
        continue;
      } else if (attribution == boldAttribution) {
        key = DeltaKeys.bold;
        value = true;
      } else if (attribution == italicsAttribution) {
        key = DeltaKeys.italic;
        value = true;
      } else if (attribution == strikethroughAttribution) {
        key = DeltaKeys.strike;
        value = true;
      } else if (attribution == codeAttribution) {
        key = DeltaKeys.code;
        value = true;
      } else if (attribution is LinkAttribution) {
        key = DeltaKeys.link;
        value = attribution.plainTextUri;
      } else if (attribution is MentionAttribution) {
        key = DeltaKeys.mention;
        value = attribution.userUuid;
      } else if (attribution is LinkStyleAttribution) {
        key = DeltaKeys.linkStyle;
        value = attribution.style;
      } else if (attribution is ChipAttribution) {
        key = DeltaKeys.chip;
        value = attribution.icon ?? true;
      } else {
        continue;
      }
      (result ??= <String, dynamic>{})[key] = value;
    }
    return result;
  }

  /// Converts Delta attributes to attributions. Unknown keys and block keys are
  /// ignored. With [overlaysOnly], only `cmt_*`/`sug_*` are converted.
  static Set<Attribution> fromAttributes(
    Map<String, dynamic>? attributes, {
    bool overlaysOnly = false,
  }) {
    if (attributes == null || attributes.isEmpty) {
      return const {};
    }
    final result = <Attribution>{};
    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value == null) {
        continue;
      }
      if (DeltaKeys.isComment(key)) {
        if (value == true) {
          result.add(
            CommentAttribution(key.substring(DeltaKeys.commentPrefix.length)),
          );
        }
        continue;
      }
      if (DeltaKeys.isSuggestion(key)) {
        if (value is Map) {
          result.add(
            SuggestionAttribution(
              key.substring(DeltaKeys.suggestionPrefix.length),
              value.cast<String, dynamic>(),
            ),
          );
        }
        continue;
      }
      if (overlaysOnly) {
        continue;
      }
      switch (key) {
        case DeltaKeys.bold:
          if (value == true) result.add(boldAttribution);
        case DeltaKeys.italic:
          if (value == true) result.add(italicsAttribution);
        case DeltaKeys.strike:
          if (value == true) result.add(strikethroughAttribution);
        case DeltaKeys.code:
          if (value == true) result.add(codeAttribution);
        case DeltaKeys.link:
          if (value is String) result.add(linkAttributionFor(value));
        case DeltaKeys.mention:
          if (value is String) result.add(MentionAttribution(value));
        case DeltaKeys.linkStyle:
          if (value is String) result.add(LinkStyleAttribution(value));
        case DeltaKeys.chip:
          if (value == true) {
            result.add(ChipAttribution.plain);
          } else if (value is String) {
            result.add(ChipAttribution(value));
          }
      }
    }
    return result;
  }

  /// A [LinkAttribution] that keeps [url] verbatim as its plain-text URI.
  static LinkAttribution linkAttributionFor(String url) =>
      LinkAttribution(url, Uri.tryParse(url));

  /// Only the overlay entries (`cmt_*`, `sug_*`) of [attributes], or `null`.
  static Map<String, dynamic>? overlaysOf(Map<String, dynamic>? attributes) {
    if (attributes == null || attributes.isEmpty) {
      return null;
    }
    Map<String, dynamic>? result;
    for (final entry in attributes.entries) {
      if (DeltaKeys.isOverlay(entry.key) && entry.value != null) {
        (result ??= <String, dynamic>{})[entry.key] = entry.value;
      }
    }
    return result;
  }
}
