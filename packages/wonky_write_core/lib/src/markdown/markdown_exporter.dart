/// [DocTree] → Markdown (02 §2.2, 07 §5.1).
library;

import '../delta/boxes.dart';
import '../delta/delta_utils.dart';
import '../import/import_api.dart';
import '../delta/embeds.dart';
import '../ir/doc_tree.dart';
import 'front_matter.dart';
import 'inline_markdown.dart';
import 'inline_writer.dart';
import 'markdown_importer.dart';
import 'wonky_to_gfm.dart';

/// Options of [MarkdownExporter].
final class MarkdownExportOptions {
  /// Creates options.
  const MarkdownExportOptions({
    this.frontMatter = true,
    this.imageSource,
    this.omitImages = false,
    this.linkRewriter,
    this.flavor = MarkdownFlavor.gfm,
  });

  /// Emit [DocMeta.frontMatter] when present.
  final bool frontMatter;

  /// Rewrites image sources (signed URLs, zip-relative paths); `null` keeps
  /// the stored `src`.
  final String Function(ImageBlock image)? imageSource;

  /// Drop images entirely (`images: omit`).
  final bool omitImages;

  /// Rewrites link targets (internal `wonky://` links → https / `#slug`).
  final String Function(String link)? linkRewriter;

  /// The flavor to write (Write 11 §5.2). GFM export writes Wonky elements
  /// in their GFM form ([WonkyToGfm]).
  final MarkdownFlavor flavor;
}

/// Serializes the IR to GFM (or Wonky Markdown) with context-aware escaping.
///
/// Every paragraph-like block is verified by parsing it back; when delimiter
/// flanking rules cannot express the formatting, `_`-delimiters and finally
/// `<strong>/<em>/<del>` tags are used, so `import(export(D)) == normalize(D)`.
final class MarkdownExporter {
  /// Creates an exporter.
  const MarkdownExporter({this.options = const MarkdownExportOptions()});

  /// Options.
  final MarkdownExportOptions options;

  /// Exports [tree].
  String export(DocTree tree) => exportWithPositions(tree).markdown;

  /// Exports [tree] and reports the Markdown range of every block (same
  /// order as [DocTree.blocks]; omitted images get an empty range).
  ({String markdown, List<({int start, int length})> blocks})
  exportWithPositions(DocTree tree) {
    final b = StringBuffer();
    final fm = tree.meta.frontMatter;
    if (options.frontMatter && fm != null && fm.trim().isNotEmpty) {
      b.write(FrontMatter.wrap(fm));
    }
    final positions = <({int start, int length})>[];
    final blocks = _wonky ? tree.blocks : WonkyToGfm.blocks(tree.blocks);
    _writeBlocks(blocks, b, positions: positions, top: true);
    b.write('\n');
    return (markdown: b.toString(), blocks: positions);
  }

  bool get _wonky => options.flavor == MarkdownFlavor.wonky;

  /// Writes [blocks] separated per [_separator]; [positions] gets the range
  /// of each block.
  void _writeBlocks(
    List<DocBlock> blocks,
    StringBuffer b, {
    List<({int start, int length})>? positions,
    required bool top,
  }) {
    DocBlock? prev;
    var first = true;
    final cols = _ListColumns();
    for (final block in blocks) {
      if (block is ImageBlock && options.omitImages) {
        positions?.add((start: b.length, length: 0));
        continue;
      }
      final text = _block(block, isFirst: first && top, cols: cols);
      if (!first) b.write(_separator(prev, block));
      positions?.add((start: b.length, length: text.length));
      b.write(text);
      prev = block;
      first = false;
    }
  }

  static bool _isListLike(DocBlock? b) => b is ListItemBlock || b is TaskBlock;

  /// What goes between [prev] and [next]. Inside one quote (Write 02 §2.2):
  /// items of a list are on consecutive lines, anything else is separated by
  /// a blank `>` line. A quoted and an unquoted block are always separated by
  /// a blank line, so the quote ends (no lazy continuation).
  static String _separator(DocBlock? prev, DocBlock next) {
    final prevQuoted = isInQuote(prev);
    final nextQuoted = isInQuote(next);
    final lists = _isListLike(prev) && _isListLike(next);
    if (prevQuoted && nextQuoted) return lists ? '\n' : '\n>\n';
    if (prevQuoted != nextQuoted) return '\n\n';
    return lists ? '\n' : '\n\n';
  }

  String _block(
    DocBlock block, {
    required bool isFirst,
    required _ListColumns cols,
  }) {
    switch (block) {
      case ParagraphBlock(:final runs):
        return _verified(runs, marker: '', cont: '', kind: _Kind.paragraph);
      case HeadingBlock(:final level, :final runs, :final step):
        return _verified(
          runs,
          marker:
              '${'#' * level} '
              '${step != null && _wonky && (level == 2 || level == 3) ? '($step) ' : ''}',
          cont: '',
          kind: _Kind.heading,
          level: level,
        );
      case ListItemBlock():
      case TaskBlock():
        return _listItem(block, cols);
      case QuoteBlock(:final lines):
        return [
          for (final l in lines)
            _verified(l, marker: '> ', cont: '> ', kind: _Kind.quote),
        ].join('\n>\n');
      case CodeBlock(:final language, :final text):
        var longest = 0;
        for (final m in RegExp('`+').allMatches(text)) {
          if (m.group(0)!.length > longest) longest = m.group(0)!.length;
        }
        final fence = '`' * (longest >= 3 ? longest + 1 : 3);
        return '$fence$language\n$text\n$fence';
      case ImageBlock():
        final src = options.imageSource?.call(block) ?? block.src;
        final alt = InlineMarkdownWriter.escapePlain(block.alt);
        final title = block.title == null
            ? ''
            : ' "${_escapeTitle(block.title!)}"';
        return '![$alt](${_destination(src)}$title)';
      case RuleBlock():
        // A leading `---` would read as front matter.
        return isFirst ? '***' : '---';
      case TableBlock():
        return _table(block);
      case GridBlock():
        return _grid(block);
      case YouTubeBlock(:final embed):
        return _youtube(embed);
      case ContainerBlock():
        return _container(block);
    }
  }

  /// `::youtube[title]{id=… start=…}` (Write 11 §5.2).
  String _youtube(YouTubeEmbed video) =>
      '::youtube${video.title == null ? '' : '[${video.title}]'}'
      '{id=${video.videoId}'
      '${video.start == null ? '' : ' start=${video.start}'}}';

  /// `:::type` … `:::` around the container's blocks (Write 11 §5.2).
  String _container(ContainerBlock block) {
    final frame = block.frame;
    final open = switch (frame.type) {
      BoxType.callout =>
        ':::${(frame.variant ?? CalloutVariant.info).value}'
            '${frame.title == null ? '' : '[${frame.title}]'}',
      BoxType.details => ':::details',
      BoxType.card => ':::card',
    };
    final b = StringBuffer('$open\n\n');
    _writeBlocks(block.children, b, top: false);
    b.write('\n\n:::');
    return b.toString();
  }

  /// `:::grid{…}` with one `- item` line per item (Write 11 §5.2).
  String _grid(GridBlock grid) {
    final lines = [
      ':::grid{columns=${grid.columns} bullets=${grid.bullets.value}}',
      '',
      for (final item in grid.items)
        switch (_cell(item)) {
          '' => '- <!-- -->',
          final text => '- $text',
        },
      '',
      ':::',
    ];
    return lines.join('\n');
  }

  List<InlineRun> _rewriteLinks(List<InlineRun> runs) =>
      options.linkRewriter == null
      ? runs
      : [
          for (final r in runs)
            r.link == null
                ? r
                : r.copyWith(link: options.linkRewriter!(r.link!)),
        ];

  String _listItem(DocBlock block, _ListColumns cols) {
    final (indent, runs, marker) = switch (block) {
      ListItemBlock(:final indent, :final runs, :final kind, :final ordinal) =>
        (indent, runs, kind == ListKindIr.ordered ? '$ordinal. ' : '- '),
      TaskBlock(:final indent, :final runs, :final checked) => (
        indent,
        runs,
        checked ? '- [x] ' : '- [ ] ',
      ),
      _ => throw StateError('not a list item'),
    };
    // Marker column of this level = content column of the parent level.
    final markerCol = indent == 0 ? 0 : cols.contentColumn(indent - 1);
    final markerWidth = block is TaskBlock ? 2 : marker.length;
    cols.set(indent, markerCol + markerWidth);
    final pad = ' ' * markerCol;
    final item = _verified(
      runs,
      marker: marker,
      cont: ' ' * markerWidth,
      kind: block is TaskBlock ? _Kind.task : _Kind.list,
      nested: indent > 0,
    );
    // A list inside a quote: the same item behind the quote marker.
    final quote = isInQuote(block) ? '> ' : '';
    return item.split('\n').map((l) => '$quote$pad$l').join('\n');
  }

  String _verified(
    List<InlineRun> runs, {
    required String marker,
    required String cont,
    required _Kind kind,
    int level = 1,
    bool nested = false,
  }) {
    final merged = InlineRun.merge(_rewriteLinks(runs));
    if (merged.isEmpty && (kind == _Kind.list || kind == _Kind.task)) {
      // Top level: a bare marker. Nested: an empty item cannot interrupt the
      // parent's paragraph, and a `<br>` HTML block would swallow the next
      // lines, so use a one-line HTML comment block.
      if (nested) return '$marker<!-- -->';
      return kind == _Kind.task ? marker : marker.trimRight();
    }
    if (merged.isEmpty ||
        merged.every(
          (r) => r.isPlain && r.text.split('').every((c) => c == softBreak),
        )) {
      final k = merged.fold(0, (n, r) => n + r.text.length);
      return '$marker${'<br>' * (k + 1)}';
    }
    final context = kind == _Kind.heading
        ? InlineContext.heading
        : InlineContext.block;
    String? fallback;
    for (final style in EmphasisStyle.values) {
      final inline = InlineMarkdownWriter.write(
        merged,
        context: context,
        style: style,
        flavor: options.flavor,
      );
      final lines = inline.split('\n');
      final text = [
        marker + lines.first,
        for (final l in lines.skip(1)) cont + l,
      ].join('\n');
      fallback ??= text;
      if (_readBack(text, kind, level, options.flavor) case final back?
          when _sameRuns(back, _written(merged))) {
        return text;
      }
      if (style == EmphasisStyle.html) return text;
    }
    return fallback!;
  }

  /// A table cell or grid item as inline Markdown: the first emphasis
  /// style whose output reads back as [runs] (as for paragraphs).
  String _cell(List<InlineRun> runs) {
    final merged = InlineRun.merge(_rewriteLinks(runs));
    final expected = _written(merged);
    for (final style in EmphasisStyle.values) {
      final text = InlineMarkdownWriter.write(
        merged,
        context: InlineContext.tableCell,
        style: style,
        flavor: options.flavor,
      );
      if (style == EmphasisStyle.html ||
          _sameRuns(
            InlineMarkdown.parse(text, flavor: options.flavor),
            expected,
          )) {
        return text;
      }
    }
    throw StateError('unreachable');
  }

  /// [runs] as the flavor writes them (GFM drops chips and link styles).
  List<InlineRun> _written(List<InlineRun> runs) => _wonky
      ? runs
      : InlineRun.merge([
          for (final r in runs) r.copyWith(clearLinkStyle: true, chip: false),
        ]);

  static bool _sameRuns(List<InlineRun> a, List<InlineRun> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Parses a single written block back to runs; `null` when the structure is
  /// not the expected single block.
  static List<InlineRun>? _readBack(
    String markdown,
    _Kind kind,
    int level,
    MarkdownFlavor flavor,
  ) {
    final importer = MarkdownImporter(
      ImportOptions(idGenerator: () => 'x', flavor: flavor),
    );
    final tree = importer.parseTree(markdown);
    if (tree.blocks.length != 1) return null;
    final b = tree.blocks.single;
    return switch ((kind, b)) {
      (_Kind.paragraph, ParagraphBlock(:final runs)) => runs,
      (_Kind.heading, HeadingBlock(:final runs, level: final l))
          when l == level =>
        runs,
      (_Kind.quote, QuoteBlock(:final lines)) when lines.length == 1 =>
        lines.single,
      (_Kind.list, ListItemBlock(:final runs)) => runs,
      (_Kind.task, TaskBlock(:final runs)) => runs,
      _ => null,
    };
  }

  String _table(TableBlock t) {
    String row(List<String> cells) =>
        '| ${cells.map(_escapeCell).join(' | ')} |';
    final cols = t.columnCount;
    final cells = [
      for (final r in t.rows) [for (final c in r) _cell(c)],
    ];
    final header = cells.first;
    final delim = [
      for (var c = 0; c < cols; c++)
        switch (c < t.align.length ? t.align[c] : null) {
          null => '---',
          _ when t.align[c]!.value == 'left' => ':---',
          _ when t.align[c]!.value == 'center' => ':---:',
          _ => '---:',
        },
    ];
    return [
      row(header),
      '| ${delim.join(' | ')} |',
      for (final r in cells.skip(1)) row(r),
    ].join('\n');
  }

  /// Escapes unescaped pipes in a cell (the cell is inline Markdown).
  static String _escapeCell(String cell) {
    final b = StringBuffer();
    var backslashes = 0;
    for (var i = 0; i < cell.length; i++) {
      final ch = cell[i];
      if (ch == '|' && backslashes.isEven) b.write(r'\');
      b.write(ch);
      backslashes = ch == r'\' ? backslashes + 1 : 0;
    }
    return b.toString();
  }

  static String _escapeTitle(String title) => title
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAllMapped(RegExp(r'&(?=#?[A-Za-z0-9]+;)'), (_) => '&amp;');

  static String _destination(String url) {
    var u = url.replaceAllMapped(
      RegExp(r'&(?=#?[A-Za-z0-9]+;)'),
      (_) => '&amp;',
    );
    if (u.contains('(') || u.contains(')') || u.contains(' ')) u = '<$u>';
    return u;
  }
}

enum _Kind { paragraph, heading, quote, list, task }

/// List content columns per nesting level during one export.
final class _ListColumns {
  final _cols = <int, int>{};

  int contentColumn(int level) => _cols[level] ?? (level + 1) * 2;

  void set(int level, int column) {
    _cols[level] = column;
    _cols.removeWhere((k, _) => k > level);
  }
}
