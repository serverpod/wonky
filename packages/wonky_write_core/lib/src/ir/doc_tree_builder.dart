/// Delta → [DocTree] and [DocTree] → Delta (07 §2.1).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../collab/suggestion_view.dart';
import '../delta/attributes.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';
import '../delta/normalizer.dart';
import '../markdown/inline_markdown.dart';
import 'anchors.dart';
import 'doc_tree.dart';

/// Builds the IR from a document delta.
final class DocTreeBuilder {
  /// Creates a builder.
  const DocTreeBuilder();

  /// Builds a [DocTree] from [document]: applies the suggestion [view],
  /// strips `cmt_*`, groups quote and code lines, computes list ordinals
  /// (per list run and indent level, restarting after a non-list block, a
  /// shallower item or a change of list kind) and unique heading anchors.
  DocTree fromDelta(
    Delta document, {
    SuggestionViewMode view = SuggestionViewMode.accepted,
    DocMeta meta = const DocMeta(),
  }) {
    final viewed = view == SuggestionViewMode.raw
        ? document
        : SuggestionView.render(document, view, stripComments: true);
    final doc = WonkyDocument(viewed);
    final blocks = <DocBlock>[];
    final anchors = AnchorIdGenerator();
    // Ordinal state per indent level: (kind, count).
    final ordinals = <int, (ListKindIr, int)>{};
    // Whether the list run so far is inside a quote (a quoted and an
    // unquoted list next to each other are two lists).
    var quotedRun = false;
    var i = 0;
    final lines = doc.lines;
    while (i < lines.length) {
      final line = lines[i];
      final f = line.format;
      if (!f.isList || f.quoted != quotedRun) ordinals.clear();
      quotedRun = f.isList && f.quoted;
      if (line.isEmbedLine) {
        final embed = line.embed;
        switch (embed) {
          case ImageEmbed():
            blocks.add(
              ImageBlock(
                embed.id,
                embed.src,
                embed.alt,
                title: embed.title,
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          case DividerEmbed():
            blocks.add(
              RuleBlock(
                embed.id,
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          case TableEmbed():
            final t = embed.padded();
            blocks.add(
              TableBlock(
                t.id,
                t.align,
                [
                  for (final r in t.rows)
                    [for (final c in r) InlineMarkdown.parse(c)],
                ],
                cellMarkdown: t.rows,
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          case null:
            break;
        }
        ordinals.clear();
        i++;
        continue;
      }
      switch (f.type) {
        case BlockType.paragraph:
          blocks.add(
            ParagraphBlock(
              _runs(line),
              deltaStart: line.start,
              deltaLength: line.length,
            ),
          );
          i++;
        case BlockType.heading:
          final runs = _runs(line);
          blocks.add(
            HeadingBlock(
              f.level,
              runs,
              anchorId: anchors.next(
                InlineRun.plainText(runs).replaceAll('\u2028', ' ').trim(),
              ),
              deltaStart: line.start,
              deltaLength: line.length,
            ),
          );
          i++;
        case BlockType.quote:
          final start = line.start;
          final quoteLines = <List<InlineRun>>[];
          var end = start;
          while (i < lines.length &&
              lines[i].format.type == BlockType.quote &&
              !lines[i].isEmbedLine) {
            quoteLines.add(_runs(lines[i]));
            end = lines[i].end;
            i++;
          }
          blocks.add(
            QuoteBlock(quoteLines, deltaStart: start, deltaLength: end - start),
          );
        case BlockType.code:
          final start = line.start;
          final language = f.language;
          final codeLines = <String>[];
          var end = start;
          while (i < lines.length &&
              lines[i].format.type == BlockType.code &&
              lines[i].format.language == language) {
            codeLines.add(lines[i].text);
            end = lines[i].end;
            i++;
          }
          blocks.add(
            CodeBlock(
              language,
              codeLines.join('\n'),
              deltaStart: start,
              deltaLength: end - start,
            ),
          );
        case BlockType.bullet || BlockType.ordered || BlockType.task:
          final indent = f.indent;
          ordinals.removeWhere((level, _) => level > indent);
          if (f.type == BlockType.task) {
            ordinals.remove(indent);
            blocks.add(
              TaskBlock(
                f.checked,
                indent,
                _runs(line),
                inQuote: f.quoted,
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          } else {
            final kind = f.type == BlockType.ordered
                ? ListKindIr.ordered
                : ListKindIr.bullet;
            final prev = ordinals[indent];
            final n = prev != null && prev.$1 == kind ? prev.$2 + 1 : 1;
            ordinals[indent] = (kind, n);
            blocks.add(
              ListItemBlock(
                kind,
                indent,
                _runs(line),
                ordinal: n,
                inQuote: f.quoted,
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          }
          i++;
      }
    }
    return DocTree(blocks, meta: meta);
  }

  static List<InlineRun> _runs(DocumentLine line) => InlineRun.merge([
    for (final s in line.segments)
      if (!s.isEmbed) InlineRun.fromAttributes(s.text, s.attributes),
  ]);
}

/// Converts an IR tree back into a normalized document delta.
final class DocTreeToDelta {
  /// Creates a converter.
  const DocTreeToDelta();

  /// Converts [tree]; the result is normalized (and therefore valid).
  Delta convert(DocTree tree) {
    final d = Delta();
    void runs(List<InlineRun> rs) {
      for (final r in rs) {
        if (r.text.isEmpty) continue;
        d.insert(r.text.replaceAll('\n', ' '), r.toAttributes());
      }
    }

    for (final b in tree.blocks) {
      switch (b) {
        case ParagraphBlock(runs: final rs):
          runs(rs);
          d.insert('\n');
        case HeadingBlock(:final level, runs: final rs):
          runs(rs);
          d.insert('\n', {WonkyAttr.header: level.clamp(1, 6)});
        case ListItemBlock(
          :final kind,
          :final indent,
          :final inQuote,
          runs: final rs,
        ):
          runs(rs);
          d.insert('\n', {
            WonkyAttr.list: kind == ListKindIr.ordered
                ? ListKind.ordered.value
                : ListKind.bullet.value,
            if (indent > 0)
              WonkyAttr.indent: indent.clamp(1, WonkyAttr.maxIndent),
            if (inQuote) WonkyAttr.blockquote: true,
          });
        case TaskBlock(
          :final checked,
          :final indent,
          :final inQuote,
          runs: final rs,
        ):
          runs(rs);
          d.insert('\n', {
            WonkyAttr.list: checked
                ? ListKind.checked.value
                : ListKind.unchecked.value,
            if (indent > 0)
              WonkyAttr.indent: indent.clamp(1, WonkyAttr.maxIndent),
            if (inQuote) WonkyAttr.blockquote: true,
          });
        case QuoteBlock(:final lines):
          for (final l in lines) {
            runs(l);
            d.insert('\n', {WonkyAttr.blockquote: true});
          }
        case CodeBlock(:final language, :final text):
          for (final l in text.split('\n')) {
            if (l.isNotEmpty) d.insert(l);
            d.insert('\n', {WonkyAttr.codeBlock: language});
          }
        case ImageBlock():
          d.insert(b.toEmbed().toInsert());
          d.insert('\n');
        case RuleBlock(:final id):
          d.insert(DividerEmbed(id: id).toInsert());
          d.insert('\n');
        case TableBlock():
          d.insert(b.toEmbed().toInsert());
          d.insert('\n');
      }
    }
    return const WonkyDeltaNormalizer().normalize(d).document;
  }
}
