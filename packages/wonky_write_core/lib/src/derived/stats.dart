/// Document statistics (02 §5, 09 §2.1 `write.get_stats`).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';

/// Statistics of a document or a range of it.
final class DocumentStats {
  /// Creates statistics.
  const DocumentStats({
    required this.words,
    required this.characters,
    required this.charactersNoSpaces,
    required this.paragraphs,
    required this.headings,
    required this.listItems,
    required this.images,
    required this.tables,
    required this.dividers,
    required this.codeBlocks,
    required this.commentThreads,
    required this.suggestions,
  });

  /// Words (CJK ideographs and kana count one word each).
  final int words;

  /// Characters (Unicode code points) excluding line ends and embeds.
  final int characters;

  /// [characters] without whitespace.
  final int charactersNoSpaces;

  /// Non-empty text lines (a code block counts as one paragraph).
  final int paragraphs;

  /// Heading lines.
  final int headings;

  /// List and task items.
  final int listItems;

  /// Image embeds.
  final int images;

  /// Table embeds.
  final int tables;

  /// Divider embeds.
  final int dividers;

  /// Code blocks (runs of code lines with the same language).
  final int codeBlocks;

  /// Distinct comment threads anchored in the range.
  final int commentThreads;

  /// Distinct suggestion ids in the range.
  final int suggestions;

  /// Words per minute used for [readingTimeMinutes].
  static const wordsPerMinute = 200;

  /// Estimated reading time in whole minutes (0 for an empty document).
  int get readingTimeMinutes =>
      words == 0 ? 0 : (words / wordsPerMinute).ceil();

  /// JSON form (snake_case, as used by MCP).
  Map<String, dynamic> toJson() => {
    'words': words,
    'characters': characters,
    'characters_no_spaces': charactersNoSpaces,
    'paragraphs': paragraphs,
    'headings': headings,
    'lists': listItems,
    'images': images,
    'tables': tables,
    'dividers': dividers,
    'code_blocks': codeBlocks,
    'comment_threads': commentThreads,
    'suggestions': suggestions,
    'reading_time_minutes': readingTimeMinutes,
  };

  @override
  String toString() => 'DocumentStats(${toJson()})';
}

/// Computes [DocumentStats].
final class DocumentStatsCalculator {
  /// Creates a calculator.
  const DocumentStatsCalculator();

  static final _wordChar = RegExp(r"[\p{L}\p{N}\p{M}\p{Pc}'’]", unicode: true);
  static final _cjk = RegExp(
    r'[\p{Script=Han}\p{Script=Hiragana}\p{Script=Katakana}]',
    unicode: true,
  );
  static final _space = RegExp(r'\s', unicode: true);

  /// Statistics of [document], or of the range `[start, start + length)`
  /// when given.
  DocumentStats stats(Delta document, {int? start, int? length}) =>
      statsOf(WonkyDocument(document), start: start, length: length);

  /// Statistics of a parsed document (optionally of a range).
  DocumentStats statsOf(WonkyDocument doc, {int? start, int? length}) {
    final from = start ?? 0;
    final to = length == null ? doc.length : from + length;
    var words = 0;
    var chars = 0;
    var charsNoSpace = 0;
    var paragraphs = 0;
    var headings = 0;
    var listItems = 0;
    var images = 0;
    var tables = 0;
    var dividers = 0;
    var codeBlocks = 0;
    final comments = <String>{};
    final suggestions = <String>{};
    String? prevCodeLanguage;
    var inWord = false;

    for (final line in doc.lines) {
      if (line.end <= from || line.start >= to) {
        if (line.start >= to) break;
        continue;
      }
      final f = line.format;
      var hasText = false;
      for (final s in line.segments) {
        if (s.end <= from || s.start >= to) continue;
        _collectOverlays(s.attributes, comments, suggestions);
        if (s.isEmbed) {
          switch (WonkyEmbed.tryParse(s.data)) {
            case ImageEmbed():
              images++;
            case TableEmbed():
              tables++;
            case DividerEmbed():
              dividers++;
            case GridEmbed() || YouTubeEmbed():
              break;
            case null:
              break;
          }
          inWord = false;
          continue;
        }
        final text = s.text;
        final a = from > s.start ? from - s.start : 0;
        final b = to < s.end ? to - s.start : text.length;
        final part = text.substring(a, b);
        for (final rune in part.runes) {
          final ch = String.fromCharCode(rune);
          if (rune == 0x2028) {
            inWord = false;
            continue;
          }
          chars++;
          final isSpace = _space.hasMatch(ch);
          if (!isSpace) {
            charsNoSpace++;
            hasText = true;
          }
          if (_cjk.hasMatch(ch)) {
            words++;
            inWord = false;
          } else if (_wordChar.hasMatch(ch)) {
            if (!inWord) words++;
            inWord = true;
          } else {
            inWord = false;
          }
        }
      }
      if (line.newlineOffset >= from && line.newlineOffset < to) {
        _collectOverlays(line.attributes, comments, suggestions);
      }
      inWord = false;
      if (f.type == BlockType.code) {
        if (prevCodeLanguage != f.language) {
          codeBlocks++;
          paragraphs++;
        }
        prevCodeLanguage = f.language;
        continue;
      }
      prevCodeLanguage = null;
      if (line.isEmbedLine) continue;
      if (f.type == BlockType.heading) headings++;
      if (f.isList) listItems++;
      if (hasText) paragraphs++;
    }
    return DocumentStats(
      words: words,
      characters: chars,
      charactersNoSpaces: charsNoSpace,
      paragraphs: paragraphs,
      headings: headings,
      listItems: listItems,
      images: images,
      tables: tables,
      dividers: dividers,
      codeBlocks: codeBlocks,
      commentThreads: comments.length,
      suggestions: suggestions.length,
    );
  }

  static void _collectOverlays(
    Map<String, dynamic>? attributes,
    Set<String> comments,
    Set<String> suggestions,
  ) {
    if (attributes == null) return;
    for (final key in attributes.keys) {
      final c = WonkyAttr.commentThreadId(key);
      if (c != null) comments.add(c);
      final s = WonkyAttr.suggestionId(key);
      if (s != null) suggestions.add(s);
    }
  }
}
