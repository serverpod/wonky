/// Reading documents for MCP `write.get_document` (09 §2.1).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../collab/suggestion_view.dart';
import '../delta/attributes.dart';
import '../delta/delta_utils.dart';
import '../delta/document.dart';
import '../derived/outline.dart';
import '../derived/plain_text.dart';
import '../import/import_api.dart' show MarkdownFlavor;
import '../ir/doc_tree.dart';
import '../ir/doc_tree_builder.dart';
import '../markdown/markdown_exporter.dart';
import 'address.dart';

/// Output formats of [DocumentReader.read].
enum ReadFormat {
  /// GFM Markdown.
  markdown,

  /// Delta JSON (ops list).
  delta,

  /// Plain text.
  text,

  /// Outline entries.
  outline,
}

/// Result of a document read.
final class ReadResult {
  /// Creates a result.
  const ReadResult({
    required this.format,
    required this.content,
    required this.docLength,
    required this.truncated,
    this.nextCursor,
    this.blocks,
  });

  /// Format.
  final ReadFormat format;

  /// `String` (markdown/text) or a JSON list (delta ops / outline entries).
  final Object content;

  /// Length of the head document.
  final int docLength;

  /// Whether more content follows ([nextCursor]).
  final bool truncated;

  /// Cursor for the next page (valid for the same revision and arguments).
  final String? nextCursor;

  /// Blocks map, when requested.
  final List<Map<String, dynamic>>? blocks;

  /// JSON form (merged into the tool output by the server).
  Map<String, dynamic> toJson() => {
    'format': format.name,
    'content': content,
    'doc_length': docLength,
    'truncated': truncated,
    'next_cursor': ?nextCursor,
    'blocks': ?blocks,
  };
}

/// Reads documents in agent-friendly formats.
final class DocumentReader {
  /// Creates a reader writing Markdown in [flavor] (Write 11 §5.2).
  const DocumentReader({this.flavor = MarkdownFlavor.gfm});

  /// The flavor of Markdown content.
  final MarkdownFlavor flavor;

  /// Reads [document] (head, raw with overlays).
  ///
  /// [range] restricts the content (Markdown/outline expand it to whole
  /// lines). [view] defaults to accepted for markdown/text and raw for delta;
  /// raw Markdown renders suggestions as CriticMarkup (`{++ins++}`,
  /// `{--del--}`). Text content is paged by [maxChars] with [cursor].
  ReadResult read(
    Delta document, {
    ReadFormat format = ReadFormat.markdown,
    ResolvedRange? range,
    SuggestionViewMode? view,
    bool includeBlocks = false,
    int maxChars = 50000,
    String? cursor,
    String? frontMatter,
  }) {
    final doc = WonkyDocument(document);
    final mode =
        view ??
        (format == ReadFormat.delta
            ? SuggestionViewMode.raw
            : SuggestionViewMode.accepted);
    // Whole lines covering the range (or the whole document).
    var slice = document;
    var lineRangeStart = 0;
    if (range != null) {
      final lines = doc.linesInRange(range.start, range.length);
      lineRangeStart = lines.first.start;
      slice = format == ReadFormat.delta
          ? document.slice(range.start, range.end)
          : document.slice(lines.first.start, lines.last.end);
    }
    final blocks = includeBlocks ? _blocksMap(doc, range, mode) : null;

    switch (format) {
      case ReadFormat.delta:
        final viewed = mode == SuggestionViewMode.raw
            ? slice
            : SuggestionView.render(slice, mode);
        return ReadResult(
          format: format,
          content: viewed.toJson(),
          docLength: doc.length,
          truncated: false,
          blocks: blocks,
        );
      case ReadFormat.outline:
        final entries = [
          for (final e in const OutlineExtractor().outlineOf(doc))
            if (range == null ||
                (e.deltaOffset >= lineRangeStart &&
                    e.deltaOffset <
                        lineRangeStart + DeltaUtils.documentLength(slice)))
              e.toJson(),
        ];
        return ReadResult(
          format: format,
          content: entries,
          docLength: doc.length,
          truncated: false,
          blocks: blocks,
        );
      case ReadFormat.text:
        return _page(
          PlainTextRenderer.render(slice, view: mode),
          format,
          doc.length,
          maxChars,
          cursor,
          blocks,
        );
      case ReadFormat.markdown:
        final md = renderMarkdown(
          slice,
          mode,
          frontMatter: range == null ? frontMatter : null,
          flavor: flavor,
        );
        return _page(md, format, doc.length, maxChars, cursor, blocks);
    }
  }

  /// Markdown of [document] in [mode]; raw mode renders CriticMarkup.
  static String renderMarkdown(
    Delta document,
    SuggestionViewMode mode, {
    String? frontMatter,
    MarkdownFlavor flavor = MarkdownFlavor.gfm,
  }) {
    final source = mode == SuggestionViewMode.raw
        ? _criticMarkup(document)
        : document;
    final tree = const DocTreeBuilder().fromDelta(
      source,
      view: mode == SuggestionViewMode.raw ? SuggestionViewMode.raw : mode,
      meta: DocMeta(frontMatter: frontMatter),
    );
    return MarkdownExporter(
      options: MarkdownExportOptions(flavor: flavor),
    ).export(tree);
  }

  /// Wraps `ins`/`del` suggestion text in CriticMarkup markers.
  static Delta _criticMarkup(Delta document) {
    final out = Delta();
    String? open; // "id|kind"
    void close() {
      if (open == null) return;
      out.insert(open!.endsWith('|ins') ? '++}' : '--}');
      open = null;
    }

    for (final op in document.operations) {
      final data = op.data;
      if (data is! String) {
        close();
        out.push(
          Operation.insert(
            data,
            Attributes.orNull(Attributes.withoutOverlays(op.attributes)),
          ),
        );
        continue;
      }
      final marks = Attributes.suggestions(op.attributes);
      final entry = marks.entries
          .where((e) => e.value.kind != SuggestionKind.fmt)
          .firstOrNull;
      final attrs = Attributes.orNull(
        Attributes.withoutOverlays(op.attributes),
      );
      final parts = data.split('\n');
      for (var i = 0; i < parts.length; i++) {
        final text = parts[i];
        if (text.isNotEmpty) {
          final key = entry == null
              ? null
              : '${entry.key}|${entry.value.kind.value}';
          if (key != open) {
            close();
            if (key != null) {
              out.insert(
                entry!.value.kind == SuggestionKind.ins ? '{++' : '{--',
              );
              open = key;
            }
          }
          out.insert(text, attrs);
        }
        if (i < parts.length - 1) {
          close();
          out.insert('\n', attrs);
        }
      }
    }
    close();
    return DeltaUtils.canonical(out);
  }

  List<Map<String, dynamic>> _blocksMap(
    WonkyDocument doc,
    ResolvedRange? range,
    SuggestionViewMode mode,
  ) {
    final infos = DocumentBlocks.of(doc);
    // Markdown positions are exact when the document has no suggestions
    // (block structure of the export equals the raw block structure).
    final hasSuggestions = doc.delta.operations.any(
      (op) => op.attributes?.keys.any(WonkyAttr.isSuggestion) ?? false,
    );
    List<({int start, int length})>? mdPositions;
    if (!hasSuggestions && range == null) {
      final tree = const DocTreeBuilder().fromDelta(
        doc.delta,
        view: SuggestionViewMode.raw,
      );
      final export = MarkdownExporter(
        options: MarkdownExportOptions(flavor: flavor),
      ).exportWithPositions(tree);
      if (export.blocks.length == infos.length) mdPositions = export.blocks;
    }
    final result = <Map<String, dynamic>>[];
    for (final b in infos) {
      if (range != null &&
          (b.start + b.length <= range.start || b.start >= range.end)) {
        continue;
      }
      final line = doc.lines[b.firstLine];
      final f = line.format;
      final preview = [
        for (var i = b.firstLine; i < b.firstLine + b.lineCount; i++)
          doc.lines[i].text,
      ].join(' ').replaceAll(softBreak, ' ').replaceAll(embedChar, '');
      result.add({
        'index': b.index,
        'type': b.type,
        if (b.type == 'heading') 'level': f.level,
        if (f.isList) 'indent': f.indent,
        if (b.type == 'task') 'checked': f.checked,
        if (f.quoted) 'quoted': true,
        if (b.type == 'code') 'language': f.language,
        'delta_start': b.start,
        'delta_length': b.length,
        if (mdPositions != null) 'md_start': mdPositions[b.index].start,
        if (mdPositions != null) 'md_length': mdPositions[b.index].length,
        'preview': preview.length > 80
            ? '${preview.substring(0, 80)}…'
            : preview,
      });
    }
    return result;
  }

  static ReadResult _page(
    String full,
    ReadFormat format,
    int docLength,
    int maxChars,
    String? cursor,
    List<Map<String, dynamic>>? blocks,
  ) {
    var start = 0;
    if (cursor != null) {
      final m = RegExp(r'^c:(\d+)$').firstMatch(cursor);
      if (m == null) {
        throw AddressException(
          AddressErrorCode.invalidArgs,
          'Invalid cursor "$cursor"',
        );
      }
      start = int.parse(m.group(1)!).clamp(0, full.length);
    }
    var end = full.length;
    if (end - start > maxChars) {
      end = start + maxChars;
      // Prefer a line boundary.
      final nl = full.lastIndexOf('\n', end - 1);
      if (nl > start) end = nl + 1;
      if (DeltaUtils.isInsideSurrogatePair(full, end)) end--;
    }
    final truncated = end < full.length;
    return ReadResult(
      format: format,
      content: full.substring(start, end),
      docLength: docLength,
      truncated: truncated,
      nextCursor: truncated ? 'c:$end' : null,
      blocks: blocks,
    );
  }
}
