/// Wonky Markdown elements → their closest GitHub-Flavored Markdown form
/// (specs/wonky_write/11-wonky-markdown.md §3.2).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/boxes.dart';
import '../delta/cells.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';
import '../delta/normalizer.dart';
import '../ir/doc_tree.dart';
import '../import/import_api.dart' show MarkdownFlavor;
import 'inline_markdown.dart';

/// The Wonky elements of a document, counted for the conversion dialog.
final class WonkyInventory {
  /// Creates an inventory.
  const WonkyInventory({
    this.callouts = 0,
    this.details = 0,
    this.cards = 0,
    this.grids = 0,
    this.buttons = 0,
    this.arrowLinks = 0,
    this.chips = 0,
    this.steps = 0,
    this.videos = 0,
  });

  /// Callouts.
  final int callouts;

  /// Details.
  final int details;

  /// Cards.
  final int cards;

  /// Grids.
  final int grids;

  /// Buttons (primary and secondary).
  final int buttons;

  /// Arrow links.
  final int arrowLinks;

  /// Chips.
  final int chips;

  /// Numbered headings.
  final int steps;

  /// YouTube videos.
  final int videos;

  /// Whether there is nothing to convert.
  bool get isEmpty =>
      callouts +
          details +
          cards +
          grids +
          buttons +
          arrowLinks +
          chips +
          steps +
          videos ==
      0;

  /// JSON form (MCP).
  Map<String, int> toJson() => {
    'callouts': callouts,
    'details': details,
    'cards': cards,
    'grids': grids,
    'buttons': buttons,
    'arrowLinks': arrowLinks,
    'chips': chips,
    'steps': steps,
    'videos': videos,
  };
}

/// Converts Wonky Markdown elements to GFM (Write 11 §3.2).
abstract final class WonkyToGfm {
  /// Counts the Wonky elements of [document].
  static WonkyInventory inventory(Delta document) {
    final counts = <String, int>{};
    void add(String key) => counts[key] = (counts[key] ?? 0) + 1;
    var prevPath = const <BoxFrame>[];
    String? prevStyleRun;
    String? prevGrid;
    for (final line in WonkyDocument(document).lines) {
      final path = Boxes.of(line.attributes);
      final common = Boxes.commonDepth(prevPath, path);
      for (var k = common; k < path.length; k++) {
        add(path[k].type.value);
      }
      prevPath = path;
      if (line.format.step != null) add('step');
      final item = GridItemAttr.of(line.attributes);
      if (item != null && item.id != prevGrid) add('grid');
      prevGrid = item?.id;
      for (final s in line.segments) {
        if (s.isEmbed) {
          switch (WonkyEmbed.tryParse(s.data)) {
            case GridEmbed():
              add('grid');
            case YouTubeEmbed():
              add('video');
            default:
              break;
          }
          prevStyleRun = null;
          continue;
        }
        final a = s.attributes;
        final style = a?[WonkyAttr.linkStyle];
        final key = a?[WonkyAttr.chip] != null
            ? 'chip'
            : style == 'arrow'
            ? 'arrowLink'
            : style != null
            ? 'button'
            : null;
        final run = key == null ? null : '$key|${a?[WonkyAttr.link]}';
        if (key != null && run != prevStyleRun) add(key);
        prevStyleRun = run;
      }
      prevStyleRun = null;
    }
    return WonkyInventory(
      callouts: counts['callout'] ?? 0,
      details: counts['details'] ?? 0,
      cards: counts['card'] ?? 0,
      grids: counts['grid'] ?? 0,
      buttons: counts['button'] ?? 0,
      arrowLinks: counts['arrowLink'] ?? 0,
      chips: counts['chip'] ?? 0,
      steps: counts['step'] ?? 0,
      videos: counts['video'] ?? 0,
    );
  }

  /// The change that converts every Wonky element of [document] to GFM,
  /// normalized (`document.compose(change)` is valid). Comments and
  /// suggestions on converted text stay (a legacy grid embed's are dropped
  /// with it).
  static Delta change(Delta document) {
    final doc = WonkyDocument(document);
    final d = Delta();
    for (final line in doc.lines) {
      final path = Boxes.of(line.attributes);
      final inCallout = path.any((f) => f.type == BoxType.callout);
      final prevPath = line.index == 0
          ? const <BoxFrame>[]
          : Boxes.of(doc.lines[line.index - 1].attributes);
      // A label line before each callout that starts here.
      final common = Boxes.commonDepth(prevPath, path);
      for (var k = common; k < path.length; k++) {
        final f = path[k];
        if (f.type != BoxType.callout) continue;
        d
          ..insert(f.calloutLabel, {WonkyAttr.bold: true})
          ..insert('\n', {WonkyAttr.blockquote: true});
      }
      final format = line.format;
      final video = line.embed;
      if (video is YouTubeEmbed) {
        // A link to the video on its own line.
        d
          ..delete(1)
          ..insert(video.title ?? video.watchUrl, {
            WonkyAttr.link: video.watchUrl,
          })
          ..retain(1, {
            if (path.isNotEmpty) WonkyAttr.box: null,
            if (inCallout) WonkyAttr.blockquote: true,
          });
        continue;
      }
      final grid = line.embed;
      if (grid is GridEmbed) {
        d.delete(1);
        for (var i = 0; i < grid.items.length; i++) {
          for (final r in InlineMarkdown.parseCell(grid.items[i])) {
            if (r.text.isEmpty) continue;
            d.insert(
              r.text,
              r.copyWith(clearLinkStyle: true, chip: false).toAttributes(),
            );
          }
          final item = {
            WonkyAttr.list: ListKind.bullet.value,
            if (inCallout) WonkyAttr.blockquote: true,
          };
          if (i < grid.items.length - 1) {
            d.insert('\n', item);
          } else {
            d.retain(1, {...item, WonkyAttr.box: null});
          }
        }
        continue;
      }
      if (format.step != null) d.insert('(${format.step}) ');
      for (final s in line.segments) {
        final a = s.attributes;
        final styled =
            a != null &&
            (a.containsKey(WonkyAttr.chip) ||
                a.containsKey(WonkyAttr.linkStyle));
        d.retain(
          s.length,
          styled ? {WonkyAttr.chip: null, WonkyAttr.linkStyle: null} : null,
        );
      }
      // A grid item becomes a bullet; a cell stays a cell (and leaves a
      // callout's quote: a cell line has no other block format).
      final gridItem = line.attributes.containsKey(WonkyAttr.grid);
      final isCell = line.attributes.containsKey(WonkyAttr.cell);
      final patch = <String, dynamic>{
        if (path.isNotEmpty) WonkyAttr.box: null,
        if (format.step != null) WonkyAttr.step: null,
        if (gridItem) ...{
          WonkyAttr.grid: null,
          WonkyAttr.list: ListKind.bullet.value,
          if (inCallout) WonkyAttr.blockquote: true,
        },
        if (inCallout &&
            !gridItem &&
            !isCell &&
            !line.isEmbedLine &&
            (format.type == BlockType.paragraph || format.isList) &&
            !format.inQuote)
          WonkyAttr.blockquote: true,
      };
      d.retain(1, patch.isEmpty ? null : patch);
    }
    d.trim();
    return const WonkyDeltaNormalizer().normalizeChange(document, d).change;
  }

  /// [tree] with every Wonky element in its GFM form (the GFM export, and
  /// the exporters that approximate Wonky elements: TXT, RTF).
  static DocTree tree(DocTree tree) => tree.hasWonkyElements
      ? DocTree(blocks(tree.blocks), meta: tree.meta)
      : tree;

  /// [blocks] with every Wonky element in its GFM form (the GFM Markdown
  /// export of a document with Wonky elements).
  static List<DocBlock> blocks(List<DocBlock> blocks) {
    final out = <DocBlock>[];
    _convert(blocks, out, inCallout: false);
    return out;
  }

  static void _convert(
    List<DocBlock> blocks,
    List<DocBlock> out, {
    required bool inCallout,
  }) {
    for (final b in blocks) {
      switch (b) {
        case ContainerBlock(:final frame, :final children):
          if (frame.type == BoxType.callout) {
            out.add(
              QuoteBlock([
                [InlineRun(frame.calloutLabel, bold: true)],
              ]),
            );
          }
          _convert(
            children,
            out,
            inCallout: inCallout || frame.type == BoxType.callout,
          );
        case YouTubeBlock(:final embed):
          final link = [
            InlineRun(embed.title ?? embed.watchUrl, link: embed.watchUrl),
          ];
          out.add(inCallout ? QuoteBlock([link]) : ParagraphBlock(link));
        case GridBlock(:final items):
          for (final item in items) {
            out.add(
              ListItemBlock(ListKindIr.bullet, 0, item, inQuote: inCallout),
            );
          }
        case HeadingBlock(:final step, :final level, :final runs)
            when step != null:
          out.add(
            HeadingBlock(
              level,
              [InlineRun('($step) '), ...runs],
              anchorId: b.anchorId,
              deltaStart: b.deltaStart,
              deltaLength: b.deltaLength,
            ),
          );
        case ParagraphBlock(:final runs) when inCallout:
          out.add(QuoteBlock([runs]));
        case ListItemBlock(
              :final kind,
              :final indent,
              :final runs,
              :final ordinal,
            )
            when inCallout:
          out.add(
            ListItemBlock(kind, indent, runs, ordinal: ordinal, inQuote: true),
          );
        case TaskBlock(:final checked, :final indent, :final runs)
            when inCallout:
          out.add(TaskBlock(checked, indent, runs, inQuote: true));
        case TableBlock(:final rows)
            when rows.any(
              (r) => r.any((c) => c.any((x) => x.chip || x.linkStyle != null)),
            ):
          out.add(
            TableBlock(
              b.id,
              b.align,
              rows,
              cellFlavor: MarkdownFlavor.gfm,
              deltaStart: b.deltaStart,
              deltaLength: b.deltaLength,
            ),
          );
        default:
          out.add(b);
      }
    }
  }
}
