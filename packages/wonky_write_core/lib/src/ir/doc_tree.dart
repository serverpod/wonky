/// Document IR shared by importers and exporters (07 §2.1).
library;

import 'package:collection/collection.dart';
import 'package:wonky_rich_text/wonky_rich_text.dart' show InlineRun;

import '../delta/embeds.dart';

export 'package:wonky_rich_text/wonky_rich_text.dart' show InlineRun;

/// Kind of a [ListItemBlock].
enum ListKindIr {
  /// Bullet list.
  bullet,

  /// Ordered list.
  ordered,
}

/// Document metadata passed to exporters.
final class DocMeta {
  /// Creates metadata.
  const DocMeta({
    this.documentUuid,
    this.title,
    this.authorName,
    this.language,
    this.frontMatter,
    this.description,
    this.createdAt,
    this.modifiedAt,
  });

  /// Document UUID.
  final String? documentUuid;

  /// Title (Drive item name).
  final String? title;

  /// Owner display name (or front matter `author`).
  final String? authorName;

  /// BCP-47 language.
  final String? language;

  /// Front matter (without `---` fences).
  final String? frontMatter;

  /// Drive description.
  final String? description;

  /// Creation time.
  final DateTime? createdAt;

  /// Last modification time (used for deterministic timestamps).
  final DateTime? modifiedAt;

  /// Copy with changed fields.
  DocMeta copyWith({
    String? documentUuid,
    String? title,
    String? authorName,
    String? language,
    String? frontMatter,
    String? description,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) => DocMeta(
    documentUuid: documentUuid ?? this.documentUuid,
    title: title ?? this.title,
    authorName: authorName ?? this.authorName,
    language: language ?? this.language,
    frontMatter: frontMatter ?? this.frontMatter,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
  );
}

/// A block of the IR. Offsets map back to the source Delta (exports only;
/// 0 for imported trees).
sealed class DocBlock {
  const DocBlock({this.deltaStart = 0, this.deltaLength = 0});

  /// Delta offset of the first line of the block.
  final int deltaStart;

  /// Delta length of the block (all its lines).
  final int deltaLength;
}

/// A paragraph.
final class ParagraphBlock extends DocBlock {
  /// Creates a paragraph.
  const ParagraphBlock(this.runs, {super.deltaStart, super.deltaLength});

  /// Inline content (empty = empty paragraph).
  final List<InlineRun> runs;
}

/// A heading.
final class HeadingBlock extends DocBlock {
  /// Creates a heading.
  const HeadingBlock(
    this.level,
    this.runs, {
    this.anchorId = '',
    super.deltaStart,
    super.deltaLength,
  });

  /// Level 1–6.
  final int level;

  /// Inline content.
  final List<InlineRun> runs;

  /// Unique anchor id (`h-<slug>-<n>`).
  final String anchorId;
}

/// A bullet or ordered list item.
final class ListItemBlock extends DocBlock {
  /// Creates a list item.
  const ListItemBlock(
    this.kind,
    this.indent,
    this.runs, {
    this.ordinal = 1,
    this.inQuote = false,
    super.deltaStart,
    super.deltaLength,
  });

  /// Whether the item is inside a blockquote; it belongs to the quote of the
  /// [QuoteBlock]s and quoted items right before and after it.
  final bool inQuote;

  /// Bullet or ordered.
  final ListKindIr kind;

  /// Nesting level 0–8.
  final int indent;

  /// 1-based number among consecutive ordered items at this level.
  final int ordinal;

  /// Inline content.
  final List<InlineRun> runs;
}

/// A task list item.
final class TaskBlock extends DocBlock {
  /// Creates a task item.
  const TaskBlock(
    this.checked,
    this.indent,
    this.runs, {
    this.inQuote = false,
    super.deltaStart,
    super.deltaLength,
  });

  /// Whether the item is inside a blockquote (see [ListItemBlock.inQuote]).
  final bool inQuote;

  /// Whether the task is done.
  final bool checked;

  /// Nesting level 0–8.
  final int indent;

  /// Inline content.
  final List<InlineRun> runs;
}

/// Whether [block] is part of a blockquote: a [QuoteBlock] or a quoted list
/// or task item. Consecutive such blocks form one quote.
bool isInQuote(DocBlock? block) => switch (block) {
  QuoteBlock() => true,
  ListItemBlock(:final inQuote) || TaskBlock(:final inQuote) => inQuote,
  _ => false,
};

/// Consecutive blockquote lines.
final class QuoteBlock extends DocBlock {
  /// Creates a quote.
  const QuoteBlock(this.lines, {super.deltaStart, super.deltaLength});

  /// One entry per quote line.
  final List<List<InlineRun>> lines;
}

/// Consecutive code lines with the same language.
final class CodeBlock extends DocBlock {
  /// Creates a code block.
  const CodeBlock(
    this.language,
    this.text, {
    super.deltaStart,
    super.deltaLength,
  });

  /// Language (`""` = none).
  final String language;

  /// Code text; lines separated by `"\n"` (no trailing newline).
  final String text;

  /// The code lines.
  List<String> get lines => text.split('\n');
}

/// An image.
final class ImageBlock extends DocBlock {
  /// Creates an image block.
  const ImageBlock(
    this.id,
    this.src,
    this.alt, {
    this.title,
    super.deltaStart,
    super.deltaLength,
  });

  /// Embed id.
  final String id;

  /// Source URL.
  final String src;

  /// Alt text.
  final String alt;

  /// Optional title / caption.
  final String? title;

  /// As an embed.
  ImageEmbed toEmbed() => ImageEmbed(id: id, src: src, alt: alt, title: title);
}

/// A horizontal rule.
final class RuleBlock extends DocBlock {
  /// Creates a rule.
  const RuleBlock(this.id, {super.deltaStart, super.deltaLength});

  /// Embed id.
  final String id;
}

/// A table.
final class TableBlock extends DocBlock {
  /// Creates a table.
  const TableBlock(
    this.id,
    this.align,
    this.rows, {
    required this.cellMarkdown,
    super.deltaStart,
    super.deltaLength,
  });

  /// Embed id.
  final String id;

  /// Column alignment.
  final List<CellAlign?> align;

  /// Parsed cells: rows → cells → runs. Row 0 is the header.
  final List<List<List<InlineRun>>> rows;

  /// The original inline-Markdown cell strings (same shape as [rows]).
  final List<List<String>> cellMarkdown;

  /// Number of columns.
  int get columnCount => align.length;

  /// As an embed.
  TableEmbed toEmbed() => TableEmbed(id: id, align: align, rows: cellMarkdown);
}

/// The document IR: blocks plus metadata.
final class DocTree {
  /// Creates a tree.
  const DocTree(this.blocks, {this.meta = const DocMeta()});

  /// Blocks in document order.
  final List<DocBlock> blocks;

  /// Metadata.
  final DocMeta meta;

  /// Headings in order.
  Iterable<HeadingBlock> get headings => blocks.whereType<HeadingBlock>();

  /// Images in order.
  Iterable<ImageBlock> get images => blocks.whereType<ImageBlock>();

  /// The first block if it is a level-1 heading.
  HeadingBlock? get titleHeading {
    final first = blocks.firstOrNull;
    return first is HeadingBlock && first.level == 1 ? first : null;
  }
}
