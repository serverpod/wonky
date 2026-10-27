import 'package:wonky_write_core/wonky_write_core.dart' as core;

import '../../platform/common/models.dart';

/// Conversions between Markdown/plain text and Write document deltas for
/// server-side creation (templates, imports, MCP), using the shared
/// `wonky_write_core` codecs so results equal client-side imports.
abstract final class WriteContent {
  static List<ImportWarningView> warningsOf(core.ImportResult r) => [
    for (final w in r.warnings)
      ImportWarningView(kind: w.kind.name, message: w.message, line: w.line),
  ];

  /// Converts Markdown to a normalized document delta.
  static ({
    core.Delta delta,
    List<ImportWarningView> warnings,
    String? frontMatter,
    String? title,
  })
  fromMarkdown(
    String markdown, {
    core.MarkdownFlavor flavor = core.MarkdownFlavor.gfm,
  }) {
    final result = const core.MarkdownCodec().importMarkdown(
      markdown,
      options: core.ImportOptions(flavor: flavor),
    );
    return (
      delta: result.delta,
      warnings: warningsOf(result),
      frontMatter: result.frontMatter,
      title: result.title,
    );
  }

  /// Converts plain text to a document delta: each line becomes a
  /// paragraph, or with [softBreaks] blank-line separated blocks become
  /// paragraphs with soft breaks (U+2028) inside (Write 07 §3.4).
  static ({core.Delta delta, List<ImportWarningView> warnings}) fromPlainText(
    String text, {
    bool softBreaks = false,
  }) {
    final normalizedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final delta = core.Delta();
    final blocks = softBreaks
        ? normalizedText.split(RegExp(r'\n\s*\n'))
        : normalizedText.split('\n');
    for (final block in blocks) {
      final line = softBreaks ? block.trim().replaceAll('\n', '\u2028') : block;
      if (line.isNotEmpty) delta.insert(line);
      delta.insert('\n');
    }
    final normalized = const core.WonkyDeltaNormalizer().normalize(delta);
    return (delta: normalized.document, warnings: const []);
  }

  /// Markdown export of a document (overlays dropped, suggestions accepted)
  /// in [flavor].
  static String toMarkdown(
    core.Delta document, {
    String? frontMatter,
    core.MarkdownFlavor flavor = core.MarkdownFlavor.gfm,
  }) => const core.MarkdownCodec().exportMarkdown(
    document,
    frontMatter: frontMatter,
    options: core.MarkdownExportOptions(flavor: flavor),
  );
}
