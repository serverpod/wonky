/// Document outline (02 §5, 09 §2.1 `write.get_outline`).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/delta_utils.dart';
import '../delta/document.dart';
import '../ir/anchors.dart';

/// One heading of the outline.
final class OutlineEntry {
  /// Creates an entry.
  const OutlineEntry({
    required this.index,
    required this.level,
    required this.text,
    required this.lineIndex,
    required this.deltaOffset,
    required this.sectionStart,
    required this.sectionLength,
    required this.anchorId,
    this.step,
  });

  /// 0-based index among headings.
  final int index;

  /// Heading level 1–6.
  final int level;

  /// Heading text (soft breaks as spaces, trimmed).
  final String text;

  /// Line index of the heading.
  final int lineIndex;

  /// Delta offset of the heading line start.
  final int deltaOffset;

  /// Start of the section (== [deltaOffset]).
  final int sectionStart;

  /// Length of the section: the heading line plus everything up to the next
  /// heading of the same or a higher level (or the document end).
  final int sectionLength;

  /// Unique anchor id (`h-<slug>-<n>`).
  final String anchorId;

  /// The number of a numbered heading (Wonky Markdown, Write 11 §2.3).
  final int? step;

  /// [text] as shown in outlines: `(n) ` before a numbered heading.
  String get label => step == null ? text : '($step) $text';

  /// JSON form (snake_case, as used by MCP).
  Map<String, dynamic> toJson() => {
    'index': index,
    'level': level,
    'text': text,
    'delta_start': deltaOffset,
    'section_start': sectionStart,
    'section_length': sectionLength,
    'anchor_id': anchorId,
    'step': ?step,
  };

  @override
  String toString() => 'OutlineEntry(#$index h$level "$text" @$deltaOffset)';
}

/// Extracts the outline of a document.
final class OutlineExtractor {
  /// Creates an extractor.
  const OutlineExtractor();

  /// Headings of [document] in document order.
  List<OutlineEntry> outline(Delta document) =>
      outlineOf(WonkyDocument(document));

  /// Headings of a parsed document.
  List<OutlineEntry> outlineOf(WonkyDocument doc) {
    final anchors = AnchorIdGenerator();
    final raw = <(DocumentLine, int, String, int?)>[];
    for (final line in doc.lines) {
      final f = line.format;
      if (f.type != BlockType.heading) continue;
      raw.add((line, f.level, headingText(line.text), f.step));
    }
    final result = <OutlineEntry>[];
    for (var i = 0; i < raw.length; i++) {
      final (line, level, text, step) = raw[i];
      var end = doc.length;
      for (var j = i + 1; j < raw.length; j++) {
        if (raw[j].$2 <= level) {
          end = raw[j].$1.start;
          break;
        }
      }
      result.add(
        OutlineEntry(
          index: i,
          level: level,
          text: text,
          lineIndex: line.index,
          deltaOffset: line.start,
          sectionStart: line.start,
          sectionLength: end - line.start,
          anchorId: anchors.next(text),
          step: step,
        ),
      );
    }
    return result;
  }

  /// Display text of a heading line: soft breaks and embed chars become
  /// spaces, whitespace collapsed, trimmed.
  static String headingText(String lineText) => lineText
      .replaceAll(softBreak, ' ')
      .replaceAll(embedChar, ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
