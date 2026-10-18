/// The block parser of `WonkyMarkdown` (specs/16 §7.3): a small, forgiving
/// line-based Markdown parser that also renders partial (streamed) input.
library;

/// The kind of a parsed block.
enum MdKind { heading, paragraph, listItem, quote, code, table, rule }

/// A parsed block.
class MdBlock {
  MdBlock(
    this.kind,
    this.text, {
    this.level = 0,
    this.marker = '',
    this.info = '',
    this.rows = const [],
    String? source,
  }) : source = source ?? text;

  final MdKind kind;

  /// The block's content: inline Markdown (headings, paragraphs, list items,
  /// quotes), the code (code blocks) or the aligned table text (tables).
  final String text;

  /// Heading level or list nesting.
  final int level;

  /// List marker ("•", "1.", "☐").
  final String marker;

  /// The info string of a fenced code block (`dart` in ```` ```dart ````).
  final String info;

  /// The cells of a table (header row first, without the delimiter row).
  final List<List<String>> rows;

  /// The block's source lines, joined with `\n` (a profile that does not
  /// allow the block kind renders it as text).
  final String source;
}

/// A small block parser (assistant replies, board posts and comments).
abstract final class MarkdownBlocks {
  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');
  static final _bullet = RegExp(r'^(\s*)[-*+]\s+(\[( |x|X)\]\s+)?(.*)$');
  static final _ordered = RegExp(r'^(\s*)(\d+)[.)]\s+(.*)$');
  static final _rule = RegExp(r'^\s*([-*_])(\s*\1){2,}\s*$');
  static final _delimiterCell = RegExp(r'^:?-{2,}:?$');

  /// Parses [text]. With [hardBreaks], the lines of a paragraph or quote
  /// stay separate lines (joined with `\n`, like GitHub comments); without,
  /// they are joined with a space (CommonMark soft breaks).
  static List<MdBlock> parse(String text, {bool hardBreaks = false}) {
    final out = <MdBlock>[];
    final lines = text.replaceAll('\r\n', '\n').split('\n');
    final para = <String>[];
    final paraSource = <String>[];
    final joiner = hardBreaks ? '\n' : ' ';
    // Content columns of the open list items: an item indented to at least
    // the previous item's content column is its child (CommonMark nesting,
    // the way the composer writes nested items: 2 spaces under `- `, 3
    // under `1. `).
    final stack = <int>[];
    int level(int indent, int column) {
      while (stack.isNotEmpty && indent < stack.last) {
        stack.removeLast();
      }
      final l = stack.length;
      stack.add(column);
      return l;
    }

    /// The lines after item line [at] that continue it (indented to its
    /// content [column], no blank line before): returns the end index.
    int continuation(int at, int column, List<String> text, List<String> src) {
      var k = at + 1;
      while (k < lines.length) {
        final l = lines[k];
        final t = l.trimLeft();
        if (t.isEmpty || l.length - t.length < column) break;
        if (t.startsWith('```') ||
            t.startsWith('>') ||
            t.startsWith('|') ||
            _heading.hasMatch(t) ||
            _rule.hasMatch(t) ||
            _bullet.hasMatch(l) ||
            _ordered.hasMatch(l)) {
          break;
        }
        text.add(t.trim());
        src.add(l);
        k++;
      }
      return k;
    }

    void flushPara() {
      if (para.isEmpty) return;
      stack.clear();
      out.add(
        MdBlock(
          MdKind.paragraph,
          para.join(joiner).trim(),
          source: paraSource.join('\n'),
        ),
      );
      para.clear();
      paraSource.clear();
    }

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('```')) {
        flushPara();
        stack.clear();
        final info = trimmed.substring(3).trim();
        final code = <String>[];
        final src = <String>[line];
        i++;
        while (i < lines.length && !lines[i].trimLeft().startsWith('```')) {
          code.add(lines[i]);
          src.add(lines[i]);
          i++;
        }
        if (i < lines.length) src.add(lines[i]);
        i++; // closing fence (or end of a streaming block)
        out.add(
          MdBlock(
            MdKind.code,
            code.join('\n'),
            info: info,
            source: src.join('\n'),
          ),
        );
        continue;
      }
      if (trimmed.isEmpty) {
        flushPara();
        i++;
        continue;
      }
      final h = _heading.firstMatch(trimmed);
      if (h != null) {
        flushPara();
        stack.clear();
        out.add(
          MdBlock(
            MdKind.heading,
            h.group(2)!,
            level: h.group(1)!.length,
            source: line,
          ),
        );
        i++;
        continue;
      }
      if (_rule.hasMatch(trimmed)) {
        flushPara();
        stack.clear();
        out.add(MdBlock(MdKind.rule, '', source: line));
        i++;
        continue;
      }
      final b = _bullet.firstMatch(line);
      if (b != null) {
        flushPara();
        final task = b.group(3);
        final indent = b.group(1)!.length;
        final column = indent + 2;
        final text = [b.group(4)!];
        final src = [line];
        final end = continuation(i, column, text, src);
        out.add(
          MdBlock(
            MdKind.listItem,
            text.join(joiner),
            level: level(indent, column),
            marker: task == null ? '•' : (task == ' ' ? '☐' : '☑'),
            source: src.join('\n'),
          ),
        );
        i = end;
        continue;
      }
      final o = _ordered.firstMatch(line);
      if (o != null) {
        flushPara();
        final indent = o.group(1)!.length;
        final column = indent + o.group(2)!.length + 2;
        final text = [o.group(3)!];
        final src = [line];
        final end = continuation(i, column, text, src);
        out.add(
          MdBlock(
            MdKind.listItem,
            text.join(joiner),
            level: level(indent, column),
            marker: '${o.group(2)}.',
            source: src.join('\n'),
          ),
        );
        i = end;
        continue;
      }
      if (trimmed.startsWith('>')) {
        flushPara();
        stack.clear();
        // An empty `>` line separates the paragraphs of a quote (the
        // composer writes consecutive quote paragraphs that way): each
        // paragraph is a quote block of its own.
        final q = <String>[];
        final src = <String>[];
        void flushQuote() {
          if (q.isNotEmpty) {
            out.add(
              MdBlock(MdKind.quote, q.join(joiner), source: src.join('\n')),
            );
          }
          q.clear();
          src.clear();
        }

        while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
          final content = lines[i].trimLeft().substring(1).trim();
          if (content.isEmpty) {
            flushQuote();
          } else {
            src.add(lines[i]);
            q.add(content);
          }
          i++;
        }
        flushQuote();
        continue;
      }
      if (trimmed.startsWith('|')) {
        flushPara();
        stack.clear();
        final rows = <List<String>>[];
        final src = <String>[];
        while (i < lines.length && lines[i].trimLeft().startsWith('|')) {
          src.add(lines[i]);
          final cells = lines[i]
              .trim()
              .replaceAll(RegExp(r'^\||\|$'), '')
              .split('|')
              .map((c) => c.trim())
              .toList();
          if (!cells.every(_delimiterCell.hasMatch)) {
            rows.add(cells);
          }
          i++;
        }
        final widths = <int>[];
        for (final r in rows) {
          for (var c = 0; c < r.length; c++) {
            if (widths.length <= c) widths.add(0);
            if (r[c].length > widths[c]) widths[c] = r[c].length;
          }
        }
        out.add(
          MdBlock(
            MdKind.table,
            [
              for (final r in rows)
                [
                  for (var c = 0; c < r.length; c++) r[c].padRight(widths[c]),
                ].join('  '),
            ].join('\n'),
            rows: rows,
            source: src.join('\n'),
          ),
        );
        continue;
      }
      para.add(trimmed);
      paraSource.add(line);
      i++;
    }
    flushPara();
    return out;
  }
}
