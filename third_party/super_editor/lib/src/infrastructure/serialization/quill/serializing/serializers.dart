import 'package:attributed_text/attributed_text.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:super_editor/src/core/document.dart';
import 'package:super_editor/src/default_editor/attributions.dart';
import 'package:super_editor/src/default_editor/horizontal_rule.dart';
import 'package:super_editor/src/default_editor/image.dart';
import 'package:super_editor/src/default_editor/list_items.dart';
import 'package:super_editor/src/default_editor/paragraph.dart';
import 'package:super_editor/src/default_editor/tables/table_block.dart';
import 'package:super_editor/src/default_editor/tasks.dart';
import 'package:super_editor/src/default_editor/text.dart';
import 'package:super_editor/src/infrastructure/serialization/markdown/document_to_markdown_serializer.dart';
import 'package:super_editor/src/infrastructure/serialization/quill/content/formatting.dart';
import 'package:super_editor/src/infrastructure/serialization/quill/content/multimedia.dart';

/// A [DeltaSerializer] that serializes [ParagraphNode]s into deltas.
const paragraphDeltaSerializer = ParagraphDeltaSerializer();

class ParagraphDeltaSerializer extends TextBlockDeltaSerializer {
  const ParagraphDeltaSerializer({
    super.inlineEmbedDeltaSerializers = const [],
  });

  @override
  bool shouldSerialize(DocumentNode node) => node is ParagraphNode;

  @override
  Map<String, dynamic> getBlockFormats(TextNode textBlock) {
    if (textBlock is! ParagraphNode) {
      // This shouldn't happen, but we do a sane thing if it does.
      return super.getBlockFormats(textBlock);
    }

    final formats = super.getBlockFormats(textBlock);
    if (textBlock.indent != 0) {
      formats["indent"] = textBlock.indent;
    }
    return formats;
  }
}

/// A [DataSerializer] that serializes [ListItemNode]s into deltas.
const listItemDeltaSerializer = ListItemDeltaSerializer();

class ListItemDeltaSerializer extends TextBlockDeltaSerializer {
  const ListItemDeltaSerializer({
    super.inlineEmbedDeltaSerializers = const [],
  });

  @override
  bool shouldSerialize(DocumentNode node) => node is ListItemNode;

  @override
  Map<String, dynamic> getBlockFormats(TextNode textBlock) {
    if (textBlock is! ListItemNode) {
      // This shouldn't happen, but we do a sane thing if it does.
      return super.getBlockFormats(textBlock);
    }

    final formats = super.getBlockFormats(textBlock);
    switch (textBlock.type) {
      case ListItemType.ordered:
        formats["list"] = "ordered";
      case ListItemType.unordered:
        formats["list"] = "bullet";
    }
    // WONKY PATCH SE-1: serialize list item indentation.
    if (textBlock.indent > 0) {
      formats["indent"] = textBlock.indent;
    }
    return formats;
  }
}

/// A [DeltaSerializer] that serializes [TaskNode]s into deltas.
const taskDeltaSerializer = TaskDeltaSerializer();

class TaskDeltaSerializer extends TextBlockDeltaSerializer {
  const TaskDeltaSerializer({
    super.inlineEmbedDeltaSerializers = const [],
  });

  @override
  bool shouldSerialize(DocumentNode node) => node is TaskNode;

  @override
  Map<String, dynamic> getBlockFormats(TextNode textBlock) {
    if (textBlock is! TaskNode) {
      // This shouldn't happen, but we do a sane thing if it does.
      return super.getBlockFormats(textBlock);
    }

    final formats = super.getBlockFormats(textBlock);
    formats["list"] = textBlock.isComplete ? "checked" : "unchecked";
    // WONKY PATCH SE-1: serialize task indentation.
    if (textBlock.indent > 0) {
      formats["indent"] = textBlock.indent;
    }
    return formats;
  }
}

/// A [DeltaSerializer] that serializes [ImageNode]s into deltas.
const imageDeltaSerializer = FunctionalDeltaSerializer(_serializeImage);
bool _serializeImage(DocumentNode node, Delta deltas) {
  if (node is! ImageNode) {
    return false;
  }

  deltas.operations.add(
    Operation.insert({
      "image": node.imageUrl,
    }),
  );

  return true;
}

/// Node metadata key that holds the language of a code block, e.g., "dart".
///
/// Read by the Quill serializer to produce `{"code-block": "<language>"}` and
/// written by [CodeBlockDeltaFormat] when parsing.
// WONKY PATCH SE-1
const codeLanguageMetadataKey = "codeLanguage";

/// A [DeltaSerializer] that serializes [BitmapImageNode]s into deltas, as an
/// `image` embed whose value is a base64 PNG data URI.
// WONKY PATCH SE-1
const bitmapImageDeltaSerializer = FunctionalDeltaSerializer(_serializeBitmapImage);
bool _serializeBitmapImage(DocumentNode node, Delta deltas) {
  if (node is! BitmapImageNode) {
    return false;
  }

  deltas.operations.add(
    Operation.insert({
      "image": "data:image/png;base64,${base64Encode(node.imageData)}",
    }),
  );

  return true;
}

/// A [DeltaSerializer] that serializes [HorizontalRuleNode]s into a
/// `divider` embed.
///
/// By default the embed is `{"divider": true}`. Apps that need extra data in
/// the embed, e.g., a stable id, can provide an [embedBuilder].
// WONKY PATCH SE-1
const horizontalRuleDeltaSerializer = HorizontalRuleDeltaSerializer();

class HorizontalRuleDeltaSerializer implements DeltaSerializer {
  const HorizontalRuleDeltaSerializer({
    this.embedBuilder,
    this.appendNewline = false,
  });

  /// Builds the embed value for the given node, e.g., `{"divider": true}`.
  final Map<String, dynamic> Function(HorizontalRuleNode node)? embedBuilder;

  /// Whether a `"\n"` is inserted after the embed, as Quill does for block
  /// embeds.
  final bool appendNewline;

  @override
  bool serialize(DocumentNode node, Delta deltas) {
    if (node is! HorizontalRuleNode) {
      return false;
    }

    deltas.operations.add(Operation.insert(embedBuilder?.call(node) ?? const {"divider": true}));
    if (appendNewline) {
      deltas.insert("\n");
    }
    return true;
  }
}

/// A [DeltaSerializer] that serializes [TableBlockNode]s into a `table` embed:
///
///     {"table": {"align": ["left", "center", null], "rows": [["**a**", "b", "c"], ...]}}
///
/// Row 0 is the header row. Cells are serialized as inline Markdown. Column
/// alignment is read from the [TextNodeMetadata.textAlign] of the cells in
/// the first body row (or the header when there is no body row).
// WONKY PATCH SE-1
const tableDeltaSerializer = TableDeltaSerializer();

class TableDeltaSerializer implements DeltaSerializer {
  const TableDeltaSerializer({
    this.embedBuilder,
    this.appendNewline = false,
  });

  /// Builds the embed value for the given node. Defaults to
  /// [defaultTableEmbed].
  final Map<String, dynamic> Function(TableBlockNode node)? embedBuilder;

  /// Whether a `"\n"` is inserted after the embed, as Quill does for block
  /// embeds.
  final bool appendNewline;

  @override
  bool serialize(DocumentNode node, Delta deltas) {
    if (node is! TableBlockNode) {
      return false;
    }

    deltas.operations.add(Operation.insert(embedBuilder?.call(node) ?? {"table": defaultTableEmbed(node)}));
    if (appendNewline) {
      deltas.insert("\n");
    }
    return true;
  }

  /// The default content of a `table` embed: `{"align": [...], "rows": [[...]]}`.
  static Map<String, dynamic> defaultTableEmbed(TableBlockNode node) {
    final rows = <List<String>>[];
    for (int r = 0; r < node.rowCount; r += 1) {
      rows.add([
        for (final cell in node.getRow(r)) cell.text.toMarkdown(),
      ]);
    }

    final alignmentRow = node.rowCount > 1 ? 1 : 0;
    final align = <String?>[];
    for (int c = 0; c < node.columnCount; c += 1) {
      final cellAlign = node.rowCount == 0
          ? null
          : node.getCell(rowIndex: alignmentRow, columnIndex: c).getMetadataValue(TextNodeMetadata.textAlign);
      align.add(cellAlign is String && const {"left", "center", "right"}.contains(cellAlign) ? cellAlign : null);
    }

    return {"align": align, "rows": rows};
  }
}

/// A [DeltaSerializer] that serializes [VideoNode]s into deltas.
const videoDeltaSerializer = FunctionalDeltaSerializer(_serializeVideo);
bool _serializeVideo(DocumentNode node, Delta deltas) {
  if (node is! VideoNode) {
    return false;
  }

  deltas.operations.add(
    Operation.insert({
      "video": node.url,
    }),
  );

  return true;
}

/// A [DeltaSerializer] that serializes [AudioNode]s to deltas.
const audioDeltaSerializer = FunctionalDeltaSerializer(_serializeAudio);
bool _serializeAudio(DocumentNode node, Delta deltas) {
  if (node is! AudioNode) {
    return false;
  }

  deltas.operations.add(
    Operation.insert({
      "audio": node.url,
    }),
  );

  return true;
}

/// A [DeltaSerializer] that serializes [FileNode]s into deltas.
const fileDeltaSerializer = FunctionalDeltaSerializer(_serializeFile);
bool _serializeFile(DocumentNode node, Delta deltas) {
  if (node is! FileNode) {
    return false;
  }

  deltas.operations.add(
    Operation.insert({
      "file": node.url,
    }),
  );

  return true;
}

/// A [DeltaSerializer] that includes standard Quill Delta rules for
/// serializing text blocks, e.g., paragraphs, lists, and tasks.
class TextBlockDeltaSerializer implements DeltaSerializer {
  const TextBlockDeltaSerializer({
    this.inlineEmbedDeltaSerializers = const [],
  });

  final List<InlineEmbedDeltaSerializer> inlineEmbedDeltaSerializers;

  @override
  bool serialize(DocumentNode node, Delta deltas) {
    if (!shouldSerialize(node)) {
      return false;
    }
    final textBlock = node as TextNode;

    final blockFormats = getBlockFormats(textBlock);

    final textByLine = textBlock.text.split("\n");
    for (int i = 0; i < textByLine.length; i += 1) {
      _serializeLine(deltas, blockFormats, inlineEmbedDeltaSerializers, textByLine[i]);
    }

    return true;
  }

  void _serializeLine(
    Delta deltas,
    Map<String, dynamic> blockFormats,
    List<InlineEmbedDeltaSerializer> inlineEmbedDeltaSerializers,
    AttributedText line,
  ) {
    var spans = line.computeAttributionSpans().toList();
    if (spans.isEmpty) {
      // The text is empty. Inject a span so that our loop below doesn't
      // violate list bounds.
      spans = [const MultiAttributionSpan(attributions: {}, start: 0, end: 0)];
    }

    for (int i = 0; i < spans.length; i += 1) {
      final span = spans[i];
      final spanText = line.copyText(span.start, line.isNotEmpty ? span.end + 1 : span.end);
      final spanPlainText = line.toPlainText().substring(span.start, line.isNotEmpty ? span.end + 1 : span.end);

      // Attempt to serialize this text span as an inline embed.
      bool didSerializeAsInlineEmbed = false;
      for (final inlineEmbedSerializer in inlineEmbedDeltaSerializers) {
        didSerializeAsInlineEmbed = inlineEmbedSerializer.serializeText(spanPlainText, span.attributions, deltas);
        if (didSerializeAsInlineEmbed) {
          // This span was successfully serialized as an inline embed. Skip remaining
          // inline embed serializers.
          break;
        }
      }
      if (didSerializeAsInlineEmbed) {
        // This span was successfully interpreted as an inline embed and serialized.
        // Move to the next span.
        continue;
      }

      // This span doesn't refer to an inline embed - it's just inline text with some styles.
      // Serialize the text and styles.
      final placeholderIndices = spanText.placeholders.keys.toList();
      final textRunsAndPlaceholders = <Object>[];
      int start = 0;
      for (final placeholderIndex in placeholderIndices) {
        if (placeholderIndex >= spanText.length) {
          continue;
        }

        final textRun = spanText.substring(start, placeholderIndex);
        if (textRun.isNotEmpty) {
          textRunsAndPlaceholders.add(textRun);
        }
        textRunsAndPlaceholders.add(spanText.placeholders[placeholderIndex]!);

        start = placeholderIndex + 1;
      }
      if (start != spanText.length) {
        textRunsAndPlaceholders.add(spanText.substring(start));
      }

      final inlineAttributes = getInlineAttributesFor(span.attributions);
      for (final item in textRunsAndPlaceholders) {
        if (item is! String) {
          // This is an inline placeholder. Try to embed it.
          for (final inlineSerializer in inlineEmbedDeltaSerializers) {
            final didSerialize = inlineSerializer.serializeInlinePlaceholder(item, inlineAttributes, deltas);
            if (didSerialize) {
              // We successfully serialized the placeholder. We're done with this item.
              continue;
            }
          }

          // We failed to serialize this placeholder. Ignore it and continue
          // processing items.
          continue;
        }

        // This is a text run.
        final newDelta = Operation.insert(
          item,
          inlineAttributes.isNotEmpty ? inlineAttributes : null,
        );

        final previousDelta = deltas.operations.lastOrNull;
        if (previousDelta != null && !previousDelta.hasBlockFormats && newDelta.canMergeWith(previousDelta)) {
          deltas.operations[deltas.operations.length - 1] = newDelta.mergeWith(previousDelta);
          continue;
        }

        deltas.operations.add(newDelta);
      }
    }

    if (line.isNotEmpty && line.last == "\n") {
      // There's already a trailing newline. No need to add another one.
      return;
    }

    // We didn't have a natural trailing newline. Insert a newline as per the
    // Delta spec.
    final newlineDelta = Operation.insert("\n", blockFormats.isNotEmpty ? blockFormats : null);
    final previousDelta = deltas.operations.isNotEmpty ? deltas.operations[deltas.operations.length - 1] : null;
    if (previousDelta != null && newlineDelta.canMergeWith(previousDelta)) {
      deltas.operations[deltas.operations.length - 1] = newlineDelta.mergeWith(previousDelta);
    } else {
      deltas.operations.add(newlineDelta);
    }
  }

  @protected
  bool shouldSerialize(DocumentNode node) {
    return node is TextNode;
  }

  /// Given the [textBlock], decides what combination of block-level attributes
  /// should be applied to the Quill Delta for this text block.
  @protected
  Map<String, dynamic> getBlockFormats(TextNode textBlock) {
    final blockAttributes = <String, dynamic>{};

    // Add all the block-level formats that aren't mutually exclusive.
    final textAlign = textBlock.metadata["textAlign"];
    if (textAlign != null && textAlign != "left") {
      blockAttributes["align"] = textAlign;
    }

    final blockType = textBlock.metadata["blockType"] as Attribution?;
    if (blockType == null) {
      return blockAttributes;
    }

    // Add the mutually exclusive block format.
    switch (blockType) {
      case header1Attribution:
        blockAttributes["header"] = 1;
      case header2Attribution:
        blockAttributes["header"] = 2;
      case header3Attribution:
        blockAttributes["header"] = 3;
      case header4Attribution:
        blockAttributes["header"] = 4;
      case header5Attribution:
        blockAttributes["header"] = 5;
      case header6Attribution:
        blockAttributes["header"] = 6;
      case blockquoteAttribution:
        blockAttributes["blockquote"] = true;
      case codeAttribution:
        // WONKY PATCH SE-1: the code language is stored in the node metadata
        // under [codeLanguageMetadataKey]; "plain" when unknown.
        final language = textBlock.metadata[codeLanguageMetadataKey];
        blockAttributes["code-block"] = language is String ? language : "plain";
    }

    return blockAttributes;
  }

  /// Given a set of [superEditorAttributions], serializes those into Quill Delta
  /// inline text attributes, returning all attributes in a map that should be set as
  /// the "attributes" in an insertion delta.
  @protected
  Map<String, dynamic> getInlineAttributesFor(Set<Attribution> superEditorAttributions) {
    final attributes = <String, dynamic>{};

    for (final attribution in superEditorAttributions) {
      if (attribution == boldAttribution) {
        attributes["bold"] = true;
        continue;
      }
      if (attribution == italicsAttribution) {
        attributes["italic"] = true;
        continue;
      }
      if (attribution == strikethroughAttribution) {
        attributes["strike"] = true;
        continue;
      }
      // WONKY PATCH SE-1: inline code was parsed but never serialized.
      if (attribution == codeAttribution) {
        attributes["code"] = true;
        continue;
      }
      if (attribution == underlineAttribution) {
        attributes["underline"] = true;
        continue;
      }
      if (attribution == superscriptAttribution) {
        attributes["script"] = "super";
        continue;
      }
      if (attribution == subscriptAttribution) {
        attributes["script"] = "sub";
        continue;
      }
      if (attribution is ColorAttribution) {
        // WONKY PATCH (infra, SE-10): `toARGB32()` replaces the deprecated `value`.
        attributes["color"] = "#${attribution.color.toARGB32().toRadixString(16).substring(2)}";
        continue;
      }
      if (attribution is BackgroundColorAttribution) {
        attributes["background"] = "#${attribution.color.toARGB32().toRadixString(16).substring(2)}";
        continue;
      }
      if (attribution is FontFamilyAttribution) {
        attributes["font"] = attribution.fontFamily;
        continue;
      }
      if (attribution is NamedFontSizeAttribution) {
        attributes["size"] = attribution.fontSizeName;
        continue;
      }
      if (attribution is FontSizeAttribution) {
        attributes["size"] = attribution.fontSize;
        continue;
      }
      if (attribution is LinkAttribution) {
        attributes["link"] = attribution.plainTextUri;
        continue;
      }
    }

    return attributes;
  }
}

// TODO: Move to AttributedText
extension Split on AttributedText {
  List<AttributedText> split(String pattern) {
    final segments = <AttributedText>[];
    int segmentStart = 0;
    int searchIndex = 0;
    // FIXME: This doesn't account for space taken up by placeholders
    final plainText = toPlainText();

    int patternIndex = plainText.indexOf(pattern, searchIndex);
    while (patternIndex >= 0) {
      segments.add(copyText(segmentStart, patternIndex));
      segmentStart = patternIndex + pattern.length;
      searchIndex = segmentStart;

      patternIndex = plainText.indexOf(pattern, searchIndex);
    }

    // Copy the final segment that appears after the last instance of the pattern.
    segments.add(copyText(segmentStart, length));

    return segments;
  }
}

/// A [DeltaSerializer] that forwards to a given delegate function.
class FunctionalDeltaSerializer implements DeltaSerializer {
  const FunctionalDeltaSerializer(this._delegate);

  final DeltaSerializerDelegate _delegate;

  @override
  bool serialize(DocumentNode node, Delta deltas) => _delegate(node, deltas);
}

typedef DeltaSerializerDelegate = bool Function(DocumentNode node, Delta deltas);

/// Serializes some part of a [MutableDocument] to a Quill Delta document.
///
/// For example, a [DeltaSerializer] might serialize a [ParagraphNode], or
/// an [ImageNode].
abstract interface class DeltaSerializer {
  /// Tries to serialize the given [DocumentNode] into the given [deltas],
  /// returning `true` if this serializer was able to serialize the [node],
  /// or `false` if this serializer wasn't made to serialize this kind of [node].
  ///
  /// For example, serializing a [ParagraphNode], or an [ImageNode], into
  /// an insertion operation.
  bool serialize(DocumentNode node, Delta deltas);
}

/// Serializes pieces of text to Quill Deltas.
abstract interface class InlineEmbedDeltaSerializer {
  /// Tries to serialize the given [text] into the given [deltas].
  ///
  /// If this serializer doesn't apply to the given [text], nothing happens.
  bool serializeText(String text, Set<Attribution> attributions, Delta deltas);

  /// Tries to serialize the given inline [placeholder] into the given [deltas].
  ///
  /// If this serialize doesn't apply to the given [placeholder], nothing happens.
  bool serializeInlinePlaceholder(Object placeholder, Map<String, dynamic> attributes, Delta deltas);
}

extension DeltaSerialization on Operation {
  // TODO: make this query extensible
  bool get hasBlockFormats {
    const blockFormats = {
      'header',
      'blockquote',
      'code-block',
    };

    if (attributes == null || attributes!.isEmpty) {
      return false;
    }

    final formats = attributes!.keys;
    for (final blockFormat in blockFormats) {
      if (formats.contains(blockFormat)) {
        return true;
      }
    }

    return false;
  }

  bool canMergeWith(Operation previousDelta) {
    if (!isInsert) {
      // We've only implement this for insertions, for now.
      // TODO: Add support for retain/delete.
      return false;
    }

    if (value is! String || previousDelta.value is! String) {
      // One or both of the deltas aren't text. Only text can be merged.
      return false;
    }

    // If the attributes are equivalent then we can merge the text deltas.
    if (const DeepCollectionEquality().equals(previousDelta.attributes, attributes)) {
      return true;
    }
    if (previousDelta.attributes == null && attributes!.isEmpty) {
      return true;
    }
    if (attributes == null && previousDelta.attributes!.isEmpty) {
      return true;
    }

    // There's a difference in the attributes. We need separate deltas.
    return false;
  }

  Operation mergeWith(Operation previousDelta) {
    if (!canMergeWith(previousDelta)) {
      throw Exception(
          "Tried to merge two deltas that can't be merged. Previous delta: $previousDelta. Next delta: $this");
    }

    return Operation.insert(
      "${previousDelta.value as String}${value as String}",
      previousDelta.attributes,
    );
  }
}

extension NewlineCharacter on String {
  String toNewlineString() => toString().replaceAll("\n", "⏎");
}
