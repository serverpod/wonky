/// Plain-text exporter (07 §5.9).
library;

import 'dart:convert';
import 'dart:typed_data';

import '../delta/delta_utils.dart';
import '../ir/doc_tree.dart';
import '../markdown/inline_markdown.dart';
import '../markdown/wonky_to_gfm.dart';
import 'export_api.dart';
import 'markdown_file_exporter.dart';

/// `.txt` exporter.
final class TxtExporter implements DocumentExporter<TxtExportOptions> {
  /// Creates the exporter.
  const TxtExporter();

  @override
  ExportFormat get format => ExportFormat.txt;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    TxtExportOptions options,
  ) async {
    final text = render(
      exportTree(input, options),
      options,
      links: input.links,
    );
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        'txt',
      ),
      mimeType: format.mimeType,
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
  }

  /// Renders [tree] as plain text.
  static String render(
    DocTree tree,
    TxtExportOptions options, {
    LinkResolver links = const IdentityLinkResolver(),
  }) {
    // Wonky elements as text: a callout's label line, grid items as lines,
    // `(n) ` before numbered headings (Write 11 §9).
    tree = WonkyToGfm.tree(tree);
    final blocks = <(String text, bool listLike, bool code)>[];
    String runs(List<InlineRun> rs) => runsText(rs, links);

    String indented(String text, String firstPrefix, int indent) {
      final pad = '  ' * indent;
      final cont = ' ' * firstPrefix.length;
      final lines = text.split('\n');
      return [
        '$pad$firstPrefix${lines.first}',
        for (final l in lines.skip(1)) '$pad$cont$l',
      ].join('\n');
    }

    for (final block in tree.blocks) {
      switch (block) {
        case ParagraphBlock():
          blocks.add((
            _wrap(runs(block.runs), options.wrapColumn),
            false,
            false,
          ));
        case HeadingBlock(runs: final rs):
          blocks.add((_wrap(runs(rs), options.wrapColumn), false, false));
        case ListItemBlock(
          :final kind,
          :final indent,
          :final ordinal,
          runs: final rs,
        ):
          blocks.add((
            indented(
              runs(rs),
              kind == ListKindIr.ordered ? '$ordinal. ' : '- ',
              indent,
            ),
            true,
            false,
          ));
        case TaskBlock(:final checked, :final indent, runs: final rs):
          blocks.add((
            indented(runs(rs), checked ? '[x] ' : '[ ] ', indent),
            true,
            false,
          ));
        case QuoteBlock(:final lines):
          blocks.add((
            [
              for (final l in lines)
                ..._wrap(
                  runs(l),
                  options.wrapColumn == 0 ? 0 : options.wrapColumn - 2,
                ).split('\n'),
            ].map((l) => '> $l').join('\n'),
            false,
            false,
          ));
        case CodeBlock(:final text):
          blocks.add((text, false, true));
        case ImageBlock(:final alt):
          blocks.add((alt.isEmpty ? '[image]' : '[image: $alt]', false, false));
        case RuleBlock():
          blocks.add(('----', false, false));
        case TableBlock(:final cellMarkdown):
          final cells = [
            for (final r in cellMarkdown)
              [for (final c in r) InlineMarkdown.cellPlainText(c)],
          ];
          blocks.add((_table(cells, options.tables), false, true));
        case ContainerBlock() || GridBlock() || YouTubeBlock():
          // Converted above.
          blocks.add(('', false, false));
      }
    }
    // A list inside a quote (Write 02 §1.2): the items behind `> `, joined to
    // the quote's lines by a `>` line like in Markdown.
    final quoted = [
      for (final block in tree.blocks)
        block is ListItemBlock || block is TaskBlock ? isInQuote(block) : false,
    ];
    final inQuote = [for (final block in tree.blocks) isInQuote(block)];
    final b = StringBuffer();
    for (var i = 0; i < blocks.length; i++) {
      if (i > 0) {
        final lists = blocks[i - 1].$2 && blocks[i].$2;
        b.write(
          inQuote[i - 1] && inQuote[i]
              ? (lists ? '\n' : '\n>\n')
              : lists && !inQuote[i - 1] && !inQuote[i]
              ? '\n'
              : '\n\n',
        );
      }
      final text = blocks[i].$1;
      b.write(
        quoted[i] ? text.split('\n').map((l) => '> $l').join('\n') : text,
      );
    }
    b.write('\n');
    final out = b.toString();
    return options.crlf ? out.replaceAll('\n', '\r\n') : out;
  }

  /// Text of runs with links in parentheses.
  static String runsText(List<InlineRun> rs, LinkResolver links) {
    final b = StringBuffer();
    for (final r in rs) {
      b.write(r.text.replaceAll(softBreak, '\n'));
      final link = r.link;
      if (link != null &&
          r.mentionUserUuid == null &&
          !link.startsWith('mailto:') &&
          r.text != link) {
        b.write(' (${links.resolve(link)})');
      }
    }
    return b.toString();
  }

  static String _table(List<List<String>> rows, TxtTables mode) {
    if (mode == TxtTables.tsv) {
      return rows
          .map((r) => r.map((c) => c.replaceAll('\t', ' ')).join('\t'))
          .join('\n');
    }
    final cols = rows.fold(0, (m, r) => r.length > m ? r.length : m);
    final widths = List.filled(cols, 0);
    for (final r in rows) {
      for (var c = 0; c < r.length; c++) {
        if (r[c].runes.length > widths[c]) widths[c] = r[c].runes.length;
      }
    }
    String pad(String s, int w) => s + ' ' * (w - s.runes.length);
    final lines = <String>[];
    for (var i = 0; i < rows.length; i++) {
      lines.add(
        [
          for (var c = 0; c < cols; c++)
            pad(c < rows[i].length ? rows[i][c] : '', widths[c]),
        ].join('  ').trimRight(),
      );
      if (i == 0 && rows.length > 1) {
        lines.add([for (final w in widths) '-' * w].join('  '));
      }
    }
    return lines.join('\n');
  }

  /// Hard-wraps [text] at [column] (0 = off); words are never broken.
  static String _wrap(String text, int column) {
    if (column <= 0) return text;
    final out = <String>[];
    for (final line in text.split('\n')) {
      var current = StringBuffer();
      for (final word in line.split(' ')) {
        if (current.isEmpty) {
          current.write(word);
        } else if (current.length + 1 + word.length > column) {
          out.add(current.toString());
          current = StringBuffer(word);
        } else {
          current.write(' $word');
        }
      }
      out.add(current.toString());
    }
    return out.join('\n');
  }
}
