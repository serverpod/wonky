import 'package:wonky_write_core/wonky_write_core.dart';

/// The `bench_100_pages` fixture of Write 04 §36, generated (deterministic,
/// no files): ≈ 53k words in 2,355 blocks with 20 tables, 40 images and
/// 30 code blocks, plus [comments] comment anchors and [suggestions]
/// pending suggestions spread over the document.
class BenchDocument {
  BenchDocument._(this.delta, this.commentThreads, this.suggestionIds);

  /// Builds the fixture. [sections] scales it (50 sections ≈ 100 pages).
  factory BenchDocument.hundredPages({
    int sections = 50,
    int comments = 12,
    int suggestions = 6,
    String suggestionAuthor = '00000000-0000-7000-8000-000000000002',
  }) {
    final md = StringBuffer();
    var words = 0;
    var tables = 0;
    var images = 0;
    var code = 0;
    for (var s = 0; s < sections; s++) {
      md.writeln('## Section ${s + 1}: ${_sentence(s, 4)}');
      md.writeln();
      for (var p = 0; p < 36; p++) {
        md.writeln(_sentence(s * 100 + p, 26));
        md.writeln();
        words += 26;
      }
      for (var i = 0; i < 8; i++) {
        md.writeln('- ${_sentence(s * 10 + i, 7)}');
        words += 7;
      }
      md.writeln();
      if (s % 5 == 2 || s % 5 == 4) {
        // 20 tables over 50 sections.
        md.writeln('| Item | Owner | Amount | Note |');
        md.writeln('| --- | --- | --- | --- |');
        for (var r = 0; r < 5; r++) {
          md.writeln(
            '| ${_word(r + s)} | ${_word(r * 3 + s)} | ${r * 17 + s} | '
            '${_sentence(r + s, 3)} |',
          );
        }
        md.writeln();
        tables++;
      }
      if (s % 5 != 1) {
        // 40 images (unresolvable sources: placeholders, no network).
        md.writeln('![Figure ${images + 1}](bench://image-$images.png)');
        md.writeln();
        images++;
      }
      if (s % 5 != 0 || s % 10 == 0) {
        // 30 code blocks.
        md.writeln('```dart');
        for (var l = 0; l < 10; l++) {
          md.writeln('final value$l = compute($l, "${_word(l + s)}") + $s;');
        }
        md.writeln('```');
        md.writeln();
        code++;
      }
    }
    assert(tables == 20 && images == 40 && code >= 30, '$tables $images $code');
    var delta = const MarkdownCodec().importMarkdown(md.toString()).delta;
    final text = DeltaUtils.text(delta);
    final length = text.length;
    // The start of the first paragraph at or after [offset].
    int paragraphAt(int offset) =>
        RegExp(r'\n[A-Z]').firstMatch(text.substring(offset))!.start +
        offset +
        1;
    final threads = <String>[];
    for (var i = 0; i < comments; i++) {
      final uuid = _uuid(0xc0 + i);
      threads.add(uuid);
      final start = paragraphAt((length * (i + 0.5) / comments).floor());
      delta = delta.compose(CommentAnchors.addAnchor(uuid, start, 12));
    }
    final ids = <String>[];
    // Offsets come from the original text: insert back to front.
    for (var i = suggestions - 1; i >= 0; i--) {
      final id = 'bench-suggestion-$i';
      ids.insert(0, id);
      final start = paragraphAt((length * (i + 0.3) / suggestions).floor());
      delta = delta.compose(
        Delta()
          ..retain(start)
          ..insert('suggested ', {
            WonkyAttr.suggestionKey(id): SuggestionMark(
              kind: SuggestionKind.ins,
              by: suggestionAuthor,
              at: 1790000000000 + i,
            ).toJson(),
          }),
      );
    }
    assert(words > 45000, '$words words');
    return BenchDocument._(delta, threads, ids);
  }

  /// The document (normalized Wonky Delta).
  final Delta delta;

  /// Thread UUIDs anchored in [delta] (`cmt_*`).
  final List<String> commentThreads;

  /// Pending suggestion ids in [delta] (`sug_*`).
  final List<String> suggestionIds;

  static const _words = [
    'wonky',
    'document',
    'review',
    'budget',
    'plan',
    'quarter',
    'team',
    'shipping',
    'editor',
    'margin',
    'comment',
    'table',
    'chart',
    'growth',
    'design',
    'meeting',
    'summary',
    'target',
    'release',
    'feedback',
    'draft',
    'customer',
    'office',
    'suite',
    'paragraph',
    'layout',
    'theme',
    'export',
  ];

  static String _word(int i) => _words[(i * 7 + 3) % _words.length];

  static String _sentence(int seed, int count) {
    final b = StringBuffer();
    for (var i = 0; i < count; i++) {
      if (i > 0) b.write(' ');
      final w = _word(seed * 31 + i * 13);
      b.write(i == 0 ? '${w[0].toUpperCase()}${w.substring(1)}' : w);
    }
    b.write('.');
    return b.toString();
  }

  static String _uuid(int n) =>
      '00000000-0000-7000-8000-${n.toRadixString(16).padLeft(12, '0')}';
}
