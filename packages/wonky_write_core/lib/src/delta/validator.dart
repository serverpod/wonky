/// `WonkyDeltaValidator` (specs/wonky_write/02-document-model.md §1.4).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:wonky_rich_text/wonky_rich_text.dart' show TextRules;

import 'attributes.dart';
import 'embeds.dart';
import 'links.dart';

export 'package:wonky_rich_text/wonky_rich_text.dart' show TextRules;

/// Kinds of schema violations.
enum ValidationCode {
  /// The delta contains `retain` or `delete` ops.
  notDocument,

  /// An insert with empty text.
  emptyInsert,

  /// The document does not end with `"\n"` (or is empty).
  missingTrailingNewline,

  /// Adjacent inserts with equal attributes are not merged.
  notCanonical,

  /// An attribute key that is not part of the schema (or not allowed at this
  /// position, e.g. a block key on text or an inline key on `"\n"`).
  unknownAttribute,

  /// An attribute value of the wrong type or range.
  invalidAttributeValue,

  /// More than one of `header`, `blockquote`, `code-block`, `list` (only
  /// `blockquote` with `list` is allowed: a list item inside a quote).
  conflictingBlockAttributes,

  /// `indent` without `list`, or an indent deeper than allowed by the
  /// preceding list items of the same run.
  invalidIndent,

  /// `code` combined with `bold`/`italic`/`strike`.
  codeWithFormatting,

  /// `mention` without a `mailto:` link.
  mentionWithoutMailto,

  /// An embed that is not on its own line, or followed by a `"\n"` with block
  /// attributes.
  embedPlacement,

  /// An embed with non-overlay attributes.
  embedAttributes,

  /// An embed value that is not a valid image/divider/table.
  invalidEmbed,

  /// Two embeds with the same `id`.
  duplicateEmbedId,

  /// A control character (or U+2029, U+FFFC, lone surrogate) in text.
  invalidCharacter,

  /// A tab outside a code block.
  tabOutsideCode,

  /// A soft break (U+2028) inside a code block line.
  softBreakInCode,

  /// Inline formatting (bold, link, …) on text of a code block line.
  formattingInCode,

  /// The document exceeds the maximum length.
  tooLong,
}

/// A single schema violation.
final class ValidationIssue {
  /// Creates an issue.
  const ValidationIssue(this.code, this.offset, this.message);

  /// Violation kind.
  final ValidationCode code;

  /// Delta offset where the violation was found.
  final int offset;

  /// Human-readable description.
  final String message;

  /// JSON form (`{code, offset, message}`).
  Map<String, dynamic> toJson() => {
    'code': code.name,
    'offset': offset,
    'message': message,
  };

  @override
  String toString() => '${code.name}@$offset: $message';
}

/// Result of [WonkyDeltaValidator.validate].
final class ValidationResult {
  /// Creates a result.
  const ValidationResult(this.issues, {this.truncated = false});

  /// Violations found (at most [WonkyDeltaValidator.maxIssues]).
  final List<ValidationIssue> issues;

  /// Whether more issues existed than were reported.
  final bool truncated;

  /// Whether the document is valid.
  bool get isValid => issues.isEmpty;

  /// JSON form.
  Map<String, dynamic> toJson() => {
    'valid': isValid,
    'issues': [for (final i in issues) i.toJson()],
    if (truncated) 'truncated': true,
  };

  @override
  String toString() => isValid ? 'valid' : 'invalid: ${issues.join('; ')}';
}

/// Validates document deltas against the Wonky Delta Schema v1.
///
/// Used by the client before submitting, by the server after transforming
/// and by importers/MCP tools on their results.
final class WonkyDeltaValidator {
  /// Creates a validator.
  const WonkyDeltaValidator({this.maxDocumentChars = defaultMaxDocumentChars});

  /// Default `write.maxDocumentChars`.
  static const defaultMaxDocumentChars = 2000000;

  /// Maximum number of issues reported.
  static const maxIssues = 50;

  /// Maximum document length (config `write.maxDocumentChars`).
  final int maxDocumentChars;

  /// Validates [document].
  ValidationResult validate(Delta document) {
    final issues = <ValidationIssue>[];
    var truncated = false;
    void add(ValidationCode code, int offset, String message) {
      if (issues.length >= maxIssues) {
        truncated = true;
        return;
      }
      issues.add(ValidationIssue(code, offset, message));
    }

    final ops = document.operations;
    if (ops.isEmpty) {
      add(ValidationCode.missingTrailingNewline, 0, 'Document is empty');
      return ValidationResult(issues);
    }

    var offset = 0;
    final embedIds = <String>{};
    // Per-line state.
    var lineHasText = false; // any non-embed content on the current line
    var lineHasEmbed = false;
    var lineContentStart = 0;
    var lineIsCode = false; // only known at line end; text checks deferred
    final pendingTabs = <int>[];
    final pendingInline = <int>[];
    final pendingSoftBreaks = <int>[];
    // List run state.
    // (A quoted and an unquoted list next to each other are two runs.)
    int? prevListIndent;
    var prevListQuoted = false;
    Operation? prev;
    var prevWasEmbed = false;

    for (var i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (!op.isInsert) {
        add(ValidationCode.notDocument, offset, 'Non-insert op ${op.key}');
        return ValidationResult(issues, truncated: truncated);
      }
      final attrs = op.attributes ?? const <String, dynamic>{};
      if (prev != null &&
          prev.data is String &&
          op.data is String &&
          Attributes.equals(prev.attributes, op.attributes)) {
        add(
          ValidationCode.notCanonical,
          offset,
          'Adjacent inserts with equal attributes',
        );
      }
      final data = op.data;
      if (data is String) {
        if (data.isEmpty) {
          add(ValidationCode.emptyInsert, offset, 'Empty insert');
          prev = op;
          continue;
        }
        final lone = TextRules.firstLoneSurrogate(data);
        if (lone >= 0) {
          add(
            ValidationCode.invalidCharacter,
            offset + lone,
            'Unpaired surrogate',
          );
        }
        var segStart = 0;
        for (var j = 0; j <= data.length; j++) {
          final isEnd = j == data.length;
          final unit = isEnd ? -1 : data.codeUnitAt(j);
          if (!isEnd && unit != 0x0A) {
            if (TextRules.isForbiddenUnit(unit)) {
              add(
                ValidationCode.invalidCharacter,
                offset + j,
                'Character U+${unit.toRadixString(16).padLeft(4, '0')} not allowed',
              );
            } else if (unit == 0x09) {
              pendingTabs.add(offset + j);
            } else if (unit == 0x2028) {
              pendingSoftBreaks.add(offset + j);
            }
            continue;
          }
          // Text segment [segStart, j) (without newline).
          if (j > segStart) {
            if (prevWasEmbed) {
              add(
                ValidationCode.embedPlacement,
                offset + segStart,
                'Text after an embed on the same line',
              );
            }
            lineHasText = true;
            _checkInlineAttributes(attrs, offset + segStart, add);
            if (attrs.keys.any(WonkyAttr.isInline)) {
              pendingInline.add(offset + segStart);
            }
            prevWasEmbed = false;
          }
          if (isEnd) break;
          // Line end at j.
          final nlOffset = offset + j;
          final format = _checkBlockAttributes(attrs, nlOffset, add);
          if (lineHasEmbed) {
            if (Attributes.block(attrs).isNotEmpty) {
              add(
                ValidationCode.embedPlacement,
                nlOffset,
                'Block attributes on an embed line end',
              );
            }
          }
          lineIsCode = format?.type == BlockType.code;
          for (final t in pendingTabs) {
            if (!lineIsCode) {
              add(ValidationCode.tabOutsideCode, t, 'Tab outside a code block');
            }
          }
          for (final s in pendingSoftBreaks) {
            if (lineIsCode) {
              add(
                ValidationCode.softBreakInCode,
                s,
                'Soft break inside a code block',
              );
            }
          }
          if (lineIsCode) {
            for (final o in pendingInline) {
              add(
                ValidationCode.formattingInCode,
                o,
                'Inline formatting inside a code block',
              );
            }
          }
          pendingTabs.clear();
          pendingSoftBreaks.clear();
          pendingInline.clear();
          // Indent rules.
          if (format != null && format.isList) {
            final maxAllowed =
                prevListIndent == null || prevListQuoted != format.quoted
                ? 0
                : prevListIndent + 1;
            if (format.indent > maxAllowed) {
              add(
                ValidationCode.invalidIndent,
                nlOffset,
                'Indent ${format.indent} deeper than allowed ($maxAllowed)',
              );
            }
            prevListIndent = format.indent;
            prevListQuoted = format.quoted;
          } else {
            prevListIndent = null;
          }
          lineHasText = false;
          lineHasEmbed = false;
          prevWasEmbed = false;
          lineContentStart = nlOffset + 1;
          segStart = j + 1;
        }
        offset += data.length;
      } else {
        // Embed.
        if (lineHasText || lineHasEmbed || offset != lineContentStart) {
          add(
            ValidationCode.embedPlacement,
            offset,
            'Embed not at the start of a line',
          );
        }
        final embed = WonkyEmbed.tryParse(data);
        if (embed == null) {
          add(ValidationCode.invalidEmbed, offset, 'Invalid or unknown embed');
        } else {
          if (!embedIds.add(embed.id)) {
            add(
              ValidationCode.duplicateEmbedId,
              offset,
              'Duplicate embed id ${embed.id}',
            );
          }
          _checkEmbed(embed, offset, add);
        }
        for (final key in attrs.keys) {
          if (!WonkyAttr.isOverlay(key)) {
            add(
              ValidationCode.embedAttributes,
              offset,
              'Attribute "$key" on an embed',
            );
          }
        }
        _checkOverlays(attrs, offset, add, block: false);
        final next = i + 1 < ops.length ? ops[i + 1] : null;
        final nextData = next?.data;
        if (next == null || nextData is! String || !nextData.startsWith('\n')) {
          add(
            ValidationCode.embedPlacement,
            offset,
            'Embed not followed by a line end',
          );
        }
        lineHasEmbed = true;
        prevWasEmbed = true;
        offset += 1;
      }
      prev = op;
    }

    final last = ops.last;
    if (last.data is! String || !(last.data as String).endsWith('\n')) {
      add(
        ValidationCode.missingTrailingNewline,
        offset,
        'Document must end with a line end',
      );
    }
    if (offset > maxDocumentChars) {
      add(
        ValidationCode.tooLong,
        maxDocumentChars,
        'Document longer than $maxDocumentChars characters',
      );
    }
    return ValidationResult(issues, truncated: truncated);
  }

  static void _checkInlineAttributes(
    Map<String, dynamic> attrs,
    int offset,
    void Function(ValidationCode, int, String) add,
  ) {
    for (final e in attrs.entries) {
      final key = e.key;
      final v = e.value;
      if (WonkyAttr.isOverlay(key)) continue;
      if (!WonkyAttr.isInline(key)) {
        add(
          ValidationCode.unknownAttribute,
          offset,
          'Attribute "$key" not allowed on text',
        );
        continue;
      }
      switch (key) {
        case WonkyAttr.bold ||
            WonkyAttr.italic ||
            WonkyAttr.strike ||
            WonkyAttr.code:
          if (v != true) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              '"$key" must be true',
            );
          }
        case WonkyAttr.link:
          if (v is! String || !LinkPolicy.isValidLink(v)) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              'Invalid link "$v"',
            );
          }
        case WonkyAttr.mention:
          if (v is! String || v.isEmpty) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              'Invalid mention',
            );
          }
      }
    }
    if (attrs[WonkyAttr.code] == true &&
        WonkyAttr.codeExcludedKeys.any(attrs.containsKey)) {
      add(
        ValidationCode.codeWithFormatting,
        offset,
        '"code" combined with bold/italic/strike',
      );
    }
    if (attrs.containsKey(WonkyAttr.mention)) {
      final link = attrs[WonkyAttr.link];
      if (link is! String || !LinkPolicy.isMailto(link)) {
        add(
          ValidationCode.mentionWithoutMailto,
          offset,
          'Mention without mailto link',
        );
      }
    }
    _checkOverlays(attrs, offset, add, block: false);
  }

  /// Returns the line's format if its block attributes are valid enough to
  /// interpret (used for contextual checks).
  static BlockFormat? _checkBlockAttributes(
    Map<String, dynamic> attrs,
    int offset,
    void Function(ValidationCode, int, String) add,
  ) {
    var types = 0;
    for (final e in attrs.entries) {
      final key = e.key;
      final v = e.value;
      if (WonkyAttr.isOverlay(key)) continue;
      if (!WonkyAttr.isBlock(key)) {
        add(
          ValidationCode.unknownAttribute,
          offset,
          'Attribute "$key" not allowed on a line end',
        );
        continue;
      }
      switch (key) {
        case WonkyAttr.header:
          types++;
          if (v is! int || v < 1 || v > 6) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              'Invalid header level "$v"',
            );
          }
        case WonkyAttr.blockquote:
          // A list item may be inside a quote (Write 02 §1.2).
          if (!attrs.containsKey(WonkyAttr.list)) types++;
          if (v != true) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              '"blockquote" must be true',
            );
          }
        case WonkyAttr.codeBlock:
          types++;
          if (v is! String || !TextRules.codeLanguage.hasMatch(v)) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              'Invalid code language "$v"',
            );
          }
        case WonkyAttr.list:
          types++;
          if (ListKind.tryParse(v) == null) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              'Invalid list "$v"',
            );
          }
        case WonkyAttr.indent:
          if (v is! int || v < 1 || v > WonkyAttr.maxIndent) {
            add(
              ValidationCode.invalidAttributeValue,
              offset,
              'Invalid indent "$v"',
            );
          }
          if (!attrs.containsKey(WonkyAttr.list)) {
            add(
              ValidationCode.invalidIndent,
              offset,
              '"indent" without "list"',
            );
          }
      }
    }
    if (types > 1) {
      add(
        ValidationCode.conflictingBlockAttributes,
        offset,
        'Conflicting block attributes',
      );
    }
    _checkOverlays(attrs, offset, add, block: true);
    return BlockFormat.fromAttributes(attrs);
  }

  static void _checkOverlays(
    Map<String, dynamic> attrs,
    int offset,
    void Function(ValidationCode, int, String) add, {
    required bool block,
  }) {
    for (final e in attrs.entries) {
      if (WonkyAttr.isComment(e.key)) {
        if (e.value != true) {
          add(
            ValidationCode.invalidAttributeValue,
            offset,
            '"${e.key}" must be true',
          );
        }
      } else if (WonkyAttr.isSuggestion(e.key)) {
        final mark = SuggestionMark.tryParse(e.value);
        if (mark == null) {
          add(
            ValidationCode.invalidAttributeValue,
            offset,
            'Invalid suggestion "${e.key}"',
          );
        } else if (mark.before != null) {
          final allowed = block ? WonkyAttr.blockKeys : WonkyAttr.inlineKeys;
          for (final k in mark.before!.keys) {
            if (!allowed.contains(k)) {
              add(
                ValidationCode.invalidAttributeValue,
                offset,
                'Suggestion "before" contains "$k"',
              );
            }
          }
        }
      } else if (e.key.startsWith(WonkyAttr.commentPrefix) ||
          e.key.startsWith(WonkyAttr.suggestionPrefix)) {
        add(
          ValidationCode.unknownAttribute,
          offset,
          'Empty overlay id "${e.key}"',
        );
      }
    }
  }

  static void _checkEmbed(
    WonkyEmbed embed,
    int offset,
    void Function(ValidationCode, int, String) add,
  ) {
    switch (embed) {
      case ImageEmbed(:final src, :final alt, :final title):
        if (!LinkPolicy.isValidImageSource(src)) {
          add(
            ValidationCode.invalidEmbed,
            offset,
            'Invalid image source "$src"',
          );
        }
        if (!_isSingleLineText(alt) ||
            (title != null && !_isSingleLineText(title))) {
          add(
            ValidationCode.invalidEmbed,
            offset,
            'Image alt/title must be trimmed single-line text',
          );
        }
      case DividerEmbed():
        break;
      case TableEmbed(:final rows, :final align):
        final cols = rows.first.length;
        if (cols == 0 ||
            rows.any((r) => r.length != cols) ||
            align.length != cols) {
          add(
            ValidationCode.invalidEmbed,
            offset,
            'Table must be rectangular with one align per column',
          );
        }
        for (final r in rows) {
          for (final c in r) {
            if (!_isSingleLineText(c, allowPadding: false)) {
              add(
                ValidationCode.invalidEmbed,
                offset,
                'Table cells must be single-line inline Markdown',
              );
              return;
            }
          }
        }
    }
  }

  static bool _isSingleLineText(String s, {bool allowPadding = false}) {
    for (var i = 0; i < s.length; i++) {
      final u = s.codeUnitAt(i);
      if (u == 0x0A ||
          u == 0x2028 ||
          u == 0x09 ||
          TextRules.isForbiddenUnit(u)) {
        return false;
      }
    }
    if (TextRules.firstLoneSurrogate(s) >= 0) return false;
    return allowPadding || s.trim() == s;
  }
}
