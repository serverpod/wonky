/// Inline Markdown helpers (table cells, inline insertion, plain text).
library;

import 'package:markdown/markdown.dart' as md;

import '../import_warning.dart';
import '../inline_run.dart';
import 'inline_reader.dart';
import 'inline_writer.dart';
import 'md_syntax.dart';
import 'wonky_syntax.dart';

/// Parsing and canonicalization of inline Markdown strings.
abstract final class InlineMarkdown {
  /// Parses inline Markdown into runs. Block structure is ignored: the text
  /// is read as one paragraph. The [MarkdownFlavor.wonky] flavor reads chips
  /// and styled links (Write 11 §4).
  static List<InlineRun> parse(
    String source, {
    List<ImportWarning>? warnings,
    MarkdownFlavor flavor = MarkdownFlavor.gfm,
  }) {
    final nodes = parseMarkdownAst(
      source.replaceAll('\n', ' '),
      flavor: flavor,
      blocks: false,
    );
    final reader = InlineReader(warnings ?? <ImportWarning>[]);
    final runs = <InlineRun>[];
    for (final n in nodes) {
      if (n is md.Element && n.children != null) {
        runs.addAll(reader.readRuns(n.children!));
      } else {
        runs.addAll(reader.readRuns([n]));
      }
    }
    return InlineRun.merge(runs);
  }

  /// Plain text of inline Markdown (formatting removed).
  static String toPlainText(
    String source, {
    MarkdownFlavor flavor = MarkdownFlavor.gfm,
  }) => InlineRun.plainText(parse(source, flavor: flavor));

  /// Parses a stored cell: a Write table cell or grid item. Stored cells are
  /// written in the Wonky inline syntax whatever the document's flavor, so
  /// chips and styled links in cells survive (Write 11 §2.3).
  static List<InlineRun> parseCell(
    String cell, {
    List<ImportWarning>? warnings,
  }) => parse(cell, warnings: warnings, flavor: MarkdownFlavor.wonky);

  /// Plain text of a stored cell.
  static String cellPlainText(String cell) =>
      InlineRun.plainText(parseCell(cell));

  /// Canonical inline Markdown for a stored cell: `write(parseCell(cell))`.
  static String canonicalCell(String cell) => InlineMarkdownWriter.write(
    parseCell(cell),
    context: InlineContext.tableCell,
  );
}
