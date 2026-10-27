/// Delta → [DocTree] and [DocTree] → Delta (07 §2.1).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../collab/suggestion_view.dart';
import '../delta/attributes.dart';
import '../delta/boxes.dart';
import '../delta/cells.dart';
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
  /// shallower item, a change of list kind or of containers) and unique
  /// heading anchors, and nests the blocks of Wonky Markdown containers into
  /// [ContainerBlock]s (Write 11 §2.2: consecutive lines with the same frame
  /// id at a depth are one container).
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
    // The containers of each block in [blocks].
    final paths = <List<BoxFrame>>[];
    final anchors = AnchorIdGenerator();
    // Ordinal state per indent level: (kind, count).
    final ordinals = <int, (ListKindIr, int)>{};
    // Whether the list run so far is inside a quote (a quoted and an
    // unquoted list next to each other are two lists).
    var quotedRun = false;
    var runPath = const <BoxFrame>[];
    var i = 0;
    final lines = doc.lines;
    while (i < lines.length) {
      final line = lines[i];
      final f = line.format;
      final path = Boxes.of(line.attributes);
      bool samePath(DocumentLine l) =>
          Boxes.samePath(Boxes.of(l.attributes), path);
      if (!f.isList ||
          f.quoted != quotedRun ||
          !Boxes.samePath(path, runPath)) {
        ordinals.clear();
      }
      quotedRun = f.isList && f.quoted;
      runPath = path;
      final blockCount = blocks.length;
      if (CellAttr.of(line.attributes) != null ||
          GridItemAttr.of(line.attributes) != null) {
        // A table or grid: one block for its run of lines (Write 12 §2).
        final run = CellRuns.at(doc, i)!;
        final int count;
        if (run is CellTable) {
          blocks.add(_table(run));
          count = run.rows.fold(0, (n, r) => n + r.cells.length);
        } else {
          run as CellGrid;
          blocks.add(_grid(run));
          count = run.items.length;
        }
        paths.add(path);
        ordinals.clear();
        i += count;
        continue;
      }
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
                    [for (final c in r) InlineMarkdown.parseCell(c)],
                ],
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          case GridEmbed():
            blocks.add(
              GridBlock(
                embed.id,
                embed.columns,
                embed.bullets,
                [
                  for (final item in embed.items)
                    InlineMarkdown.parseCell(item),
                ],
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          case YouTubeEmbed():
            blocks.add(
              YouTubeBlock(
                embed,
                deltaStart: line.start,
                deltaLength: line.length,
              ),
            );
          case null:
            break;
        }
        if (blocks.length > blockCount) paths.add(path);
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
              step: f.step,
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
              !lines[i].isEmbedLine &&
              samePath(lines[i])) {
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
              lines[i].format.language == language &&
              !lines[i].isEmbedLine &&
              samePath(lines[i])) {
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
      if (blocks.length > blockCount) paths.add(path);
    }
    return DocTree(_nest(blocks, paths, 0, blocks.length, 0), meta: meta);
  }

  /// Nests `blocks[from..to)` at container [depth]: runs of blocks whose
  /// frame at [depth] has the same id become one [ContainerBlock].
  static List<DocBlock> _nest(
    List<DocBlock> blocks,
    List<List<BoxFrame>> paths,
    int from,
    int to,
    int depth,
  ) {
    final out = <DocBlock>[];
    var i = from;
    while (i < to) {
      final path = paths[i];
      if (path.length <= depth) {
        out.add(blocks[i]);
        i++;
        continue;
      }
      final frame = path[depth];
      var j = i + 1;
      while (j < to &&
          paths[j].length > depth &&
          paths[j][depth].id == frame.id) {
        j++;
      }
      final start = blocks[i].deltaStart;
      final last = blocks[j - 1];
      out.add(
        ContainerBlock(
          frame,
          _nest(blocks, paths, i, j, depth + 1),
          deltaStart: start,
          deltaLength: last.deltaStart + last.deltaLength - start,
        ),
      );
      i = j;
    }
    return out;
  }

  static List<InlineRun> _runs(DocumentLine line) => InlineRun.merge([
    for (final s in line.segments)
      if (!s.isEmbed) InlineRun.fromAttributes(s.text, s.attributes),
  ]);

  /// The block of a table's cell lines; ragged rows are padded with empty
  /// cells (Write 12 §1.1).
  static TableBlock _table(CellTable t) {
    final columns = t.columnCount;
    return TableBlock(
      t.id,
      t.align,
      [
        for (final r in t.rows)
          [
            for (var c = 0; c < columns; c++)
              c < r.cells.length ? _runs(r.cells[c]) : const <InlineRun>[],
          ],
      ],
      rowIds: [for (final r in t.rows) r.id],
      deltaStart: t.start,
      deltaLength: t.end - t.start,
    );
  }

  /// The block of a grid's item lines.
  static GridBlock _grid(CellGrid g) => GridBlock(
    g.id,
    g.columns,
    g.bullets,
    [for (final item in g.items) _runs(item)],
    deltaStart: g.start,
    deltaLength: g.end - g.start,
  );
}

/// Converts an IR tree back into a normalized document delta.
final class DocTreeToDelta {
  /// Creates a converter.
  const DocTreeToDelta();

  /// Converts [tree]; the result is normalized (and therefore valid).
  /// Blocks in [ContainerBlock]s get the containers' frames as `box`.
  Delta convert(DocTree tree) {
    final d = Delta();
    void runs(List<InlineRun> rs) {
      for (final r in rs) {
        if (r.text.isEmpty) continue;
        d.insert(r.text.replaceAll('\n', ' '), r.toAttributes());
      }
    }

    void line(List<BoxFrame> path, [Map<String, dynamic>? block]) {
      final attrs = <String, dynamic>{
        ...?block,
        if (path.isNotEmpty) WonkyAttr.box: Boxes.toValue(path),
      };
      d.insert('\n', attrs.isEmpty ? null : attrs);
    }

    void blocks(List<DocBlock> list, List<BoxFrame> path) {
      for (final b in list) {
        switch (b) {
          case ParagraphBlock(runs: final rs):
            runs(rs);
            line(path);
          case HeadingBlock(:final level, :final step, runs: final rs):
            runs(rs);
            line(path, {
              WonkyAttr.header: level.clamp(1, 6),
              WonkyAttr.step: ?step,
            });
          case ListItemBlock(
            :final kind,
            :final indent,
            :final inQuote,
            runs: final rs,
          ):
            runs(rs);
            line(path, {
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
            line(path, {
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
              line(path, {WonkyAttr.blockquote: true});
            }
          case CodeBlock(:final language, :final text):
            for (final l in text.split('\n')) {
              if (l.isNotEmpty) d.insert(l);
              line(path, {WonkyAttr.codeBlock: language});
            }
          case ImageBlock():
            d.insert(b.toEmbed().toInsert());
            line(path);
          case RuleBlock(:final id):
            d.insert(DividerEmbed(id: id).toInsert());
            line(path);
          case TableBlock(:final id, :final align, :final rowIds):
            final box = path.isEmpty ? null : Boxes.toValue(path);
            var r = 0;
            for (final op in CellLines.table(
              id: id,
              rows: [
                for (final row in b.rows)
                  [for (final c in row) CellLines.inline(c)],
              ],
              align: align,
              box: box,
              rowId: rowIds != null && rowIds.length == b.rows.length
                  ? () => rowIds[r++]
                  : null,
            ).toList()) {
              d.push(op);
            }
          case GridBlock(
            :final id,
            :final columns,
            :final bullets,
            :final items,
          ):
            final box = path.isEmpty ? null : Boxes.toValue(path);
            for (final op in CellLines.grid(
              id: id,
              items: [for (final item in items) CellLines.inline(item)],
              columns: columns,
              bullets: bullets,
              box: box,
            ).toList()) {
              d.push(op);
            }
          case YouTubeBlock(:final embed):
            d.insert(embed.toInsert());
            line(path);
          case ContainerBlock(:final frame, :final children):
            if (path.length >= BoxFrame.maxDepth) {
              // Too deep: the content joins the enclosing container.
              blocks(children, path);
            } else if (children.isEmpty) {
              // A container holds at least one line.
              line([...path, frame]);
            } else {
              blocks(children, [...path, frame]);
            }
        }
      }
    }

    blocks(tree.blocks, const []);
    return const WonkyDeltaNormalizer().normalize(d).document;
  }
}
