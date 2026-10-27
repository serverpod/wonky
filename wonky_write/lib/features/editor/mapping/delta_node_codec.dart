import 'package:collection/collection.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:super_editor/super_editor.dart';

import 'attribution_mapping.dart';
import 'wonky_embed_node.dart';
import 'wonky_schema.dart';

const _deepEquality = DeepCollectionEquality();

/// Serializes one super_editor node to its Wonky Delta lines and parses Delta
/// lines back into nodes (Write 02 §4).
///
/// Mapping (one node = one Delta line, except code blocks):
///
/// | Delta line | Node |
/// |---|---|
/// | paragraph / `header` / `blockquote` | [ParagraphNode] with block type |
/// | consecutive `code-block` lines of one language | one [ParagraphNode] (`codeAttribution`) whose text contains `\n`; language in [WonkyNodeMetadata.codeLanguage] |
/// | `list: bullet/ordered` (+ `indent`, `blockquote`) | [ListItemNode] ([WonkyNodeMetadata.quoted] inside a quote) |
/// | `list: checked/unchecked` (+ `indent`, `blockquote`) | [TaskNode] (same) |
/// | `image` / `divider` / `table` embed + `\n` | [ImageNode] / [HorizontalRuleNode] / [TableBlockNode] (raw embed in [WonkyNodeMetadata.embed]) |
///
/// Soft line breaks (U+2028) are `\n` inside non-code node text. Overlay
/// attributes of a line end are kept in [WonkyNodeMetadata.lineAttributes];
/// those of the `\n` between code lines are attributions on the `\n` char.
class WonkyDeltaSerializer implements DeltaSerializer {
  const WonkyDeltaSerializer();

  @override
  bool serialize(DocumentNode node, Delta deltas) {
    if (node is TextNode) {
      _serializeTextNode(node, deltas);
      return true;
    }
    final embed = embedValueOf(node);
    if (embed == null) {
      // Unknown block node without an embed value: it has no Delta
      // representation. The schema guard removes such nodes.
      return true;
    }
    final embedAttributes = _mapOf(
      node.getMetadataValue(WonkyNodeMetadata.embedAttributes),
    );
    deltas.insert(embed, embedAttributes);
    final box = boxValueOf(node);
    deltas.insert(
      '\n',
      _merge(
        box == null ? null : {DeltaKeys.box: box},
        _mapOf(node.getMetadataValue(WonkyNodeMetadata.lineAttributes)),
      ),
    );
    return true;
  }

  /// Serializes [node] into a new Delta.
  Delta serializeNode(DocumentNode node) {
    final delta = Delta();
    serialize(node, delta);
    return delta;
  }

  void _serializeTextNode(TextNode node, Delta out) {
    final isCode = isCodeBlockNode(node);
    final blockAttributes = blockAttributesOf(node);
    final lineAttributes = _mapOf(
      node.getMetadataValue(WonkyNodeMetadata.lineAttributes),
    );
    final text = node.text;
    final plainText = text.toPlainText(includePlaceholders: false);

    if (plainText.isNotEmpty) {
      for (final span in text.computeAttributionSpans()) {
        final spanText = plainText.substring(span.start, span.end + 1);
        if (!isCode) {
          out.insert(
            spanText.contains('\n')
                ? spanText.replaceAll('\n', DeltaKeys.softBreak)
                : spanText,
            AttributionMapping.toAttributes(span.attributions),
          );
          continue;
        }

        final attributes = AttributionMapping.toAttributes(span.attributions);
        var start = 0;
        while (start <= spanText.length) {
          final newline = spanText.indexOf('\n', start);
          final end = newline < 0 ? spanText.length : newline;
          if (end > start) {
            out.insert(spanText.substring(start, end), attributes);
          }
          if (newline < 0) {
            break;
          }
          out.insert(
            '\n',
            _merge(blockAttributes, AttributionMapping.overlaysOf(attributes)),
          );
          start = newline + 1;
        }
      }
    }

    out.insert('\n', _merge(blockAttributes, lineAttributes));
  }

  /// The block attributes of a text node, or `null` for a plain paragraph:
  /// its block type attributes plus its containers (Write 11 §7.1).
  static Map<String, dynamic>? blockAttributesOf(DocumentNode node) {
    final type = _blockTypeAttributesOf(node);
    final box = boxValueOf(node);
    if (box == null) return type;
    return {...?type, DeltaKeys.box: box};
  }

  static Map<String, dynamic>? _blockTypeAttributesOf(DocumentNode node) {
    if (node is ListItemNode) {
      return {
        DeltaKeys.list: node.type == ListItemType.ordered
            ? 'ordered'
            : 'bullet',
        if (node.indent > 0) DeltaKeys.indent: node.indent,
        if (isQuotedListNode(node)) DeltaKeys.blockquote: true,
      };
    }
    if (node is TaskNode) {
      return {
        DeltaKeys.list: node.isComplete ? 'checked' : 'unchecked',
        if (node.indent > 0) DeltaKeys.indent: node.indent,
        if (isQuotedListNode(node)) DeltaKeys.blockquote: true,
      };
    }
    if (node is ParagraphNode) {
      final blockType = node.getMetadataValue(NodeMetadata.blockType);
      if (blockType == codeAttribution) {
        return {DeltaKeys.codeBlock: codeLanguageOf(node)};
      }
      if (blockType == blockquoteAttribution) {
        return {DeltaKeys.blockquote: true};
      }
      final level = headingLevelOf(blockType);
      if (level != null) {
        final step = stepOf(node);
        return {
          DeltaKeys.header: level,
          if (step != null && (level == 2 || level == 3)) DeltaKeys.step: step,
        };
      }
    }
    return null;
  }

  /// The raw embed insert value of an embed node, kept consistent with the
  /// node's own fields (e.g. [ImageNode.imageUrl]).
  static Map<String, dynamic>? embedValueOf(DocumentNode node) {
    final stored = node.getMetadataValue(WonkyNodeMetadata.embed);
    final storedMap = stored is Map<String, dynamic> ? stored : null;
    if (node is ImageNode) {
      final image = storedMap?[DeltaKeys.imageEmbed];
      if (image is Map &&
          image['src'] == node.imageUrl &&
          (image['alt'] ?? '') == node.altText) {
        return storedMap;
      }
      return {
        DeltaKeys.imageEmbed: {
          if (image is Map) ...image.cast<String, dynamic>(),
          'id': image is Map && image['id'] is String ? image['id'] : node.id,
          'src': node.imageUrl,
          'alt': node.altText,
        },
      };
    }
    if (node is HorizontalRuleNode) {
      return storedMap ??
          {
            DeltaKeys.dividerEmbed: {'id': node.id},
          };
    }
    if (node is TableBlockNode) {
      return storedMap ??
          {
            DeltaKeys.tableEmbed: {
              'id': node.id,
              ...TableDeltaSerializer.defaultTableEmbed(node),
            },
          };
    }
    return storedMap;
  }

  static Map<String, dynamic>? _mapOf(Object? value) {
    if (value is Map && value.isNotEmpty) {
      return value.cast<String, dynamic>();
    }
    return null;
  }

  static Map<String, dynamic>? _merge(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    if (a == null || a.isEmpty) return b == null || b.isEmpty ? null : b;
    if (b == null || b.isEmpty) return a;
    return {...a, ...b};
  }
}

/// One Delta line: its segments and the attributes of its line-end `"\n"`.
class DeltaLine {
  DeltaLine(this.segments, this.endAttributes);

  /// Text inserts (`String`) or embed inserts (`Map`) with their attributes.
  final List<Operation> segments;

  /// Attributes of the line-end `"\n"`.
  final Map<String, dynamic>? endAttributes;

  bool get isEmbedLine => segments.length == 1 && segments.first.data is Map;

  int get length => segments.fold<int>(0, (sum, op) => sum + op.length!) + 1;

  /// The code language when this is a code-block line, else `null`.
  String? get codeLanguage {
    final value = endAttributes?[DeltaKeys.codeBlock];
    return value is String ? value : null;
  }
}

/// Splits a document Delta (inserts only) into lines.
///
/// Trailing content without a final `"\n"` (not valid in the schema) becomes a
/// line with no end attributes.
List<DeltaLine> splitDeltaIntoLines(Delta document) {
  final lines = <DeltaLine>[];
  var segments = <Operation>[];
  for (final op in document.operations) {
    if (!op.isInsert) {
      throw ArgumentError(
        'Expected a document Delta (inserts only), found $op',
      );
    }
    final data = op.data;
    if (data is! String) {
      segments.add(op);
      continue;
    }
    var start = 0;
    while (true) {
      final newline = data.indexOf('\n', start);
      if (newline < 0) {
        if (start < data.length) {
          segments.add(Operation.insert(data.substring(start), op.attributes));
        }
        break;
      }
      if (newline > start) {
        segments.add(
          Operation.insert(data.substring(start, newline), op.attributes),
        );
      }
      lines.add(DeltaLine(segments, op.attributes));
      segments = <Operation>[];
      start = newline + 1;
    }
  }
  if (segments.isNotEmpty) {
    lines.add(DeltaLine(segments, null));
  }
  return lines;
}

/// Builds super_editor nodes from Delta lines.
class WonkyDeltaParser {
  const WonkyDeltaParser();

  /// Parses [document] into nodes. [newNodeId] creates ids for text nodes and
  /// for embeds whose `id` is missing or already taken.
  ///
  /// [claimId] reserves an id and returns whether it was still available;
  /// by default ids must be unique within the parsed nodes.
  List<DocumentNode> parse(
    Delta document, {
    required String Function() newNodeId,
    bool Function(String id)? claimId,
  }) {
    return parseLines(
      splitDeltaIntoLines(document),
      newNodeId: newNodeId,
      claimId: claimId,
    );
  }

  /// Parses [lines] into nodes, merging consecutive code lines of the same
  /// language into one code block node.
  List<DocumentNode> parseLines(
    List<DeltaLine> lines, {
    required String Function() newNodeId,
    bool Function(String id)? claimId,
  }) {
    final ids = claimId ?? <String>{}.add;
    final nodes = <DocumentNode>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (line.isEmbedLine) {
        nodes.add(_embedNode(line, newNodeId, ids));
        i += 1;
        continue;
      }
      final language = line.codeLanguage;
      if (language != null) {
        var j = i + 1;
        while (j < lines.length &&
            !lines[j].isEmbedLine &&
            lines[j].codeLanguage == language &&
            _sameBox(lines[j], line)) {
          j += 1;
        }
        nodes.add(
          _codeNode(lines.sublist(i, j), language, _takeId(newNodeId, ids)),
        );
        i = j;
        continue;
      }
      nodes.add(_textNode(line, _takeId(newNodeId, ids)));
      i += 1;
    }
    return nodes;
  }

  static final _boxEquality = const DeepCollectionEquality();

  /// Whether two lines are in the same containers.
  static bool _sameBox(DeltaLine a, DeltaLine b) => _boxEquality.equals(
    a.endAttributes?[DeltaKeys.box],
    b.endAttributes?[DeltaKeys.box],
  );

  String _takeId(String Function() newNodeId, bool Function(String id) claim) {
    var id = newNodeId();
    while (!claim(id)) {
      id = newNodeId();
    }
    return id;
  }

  DocumentNode _textNode(DeltaLine line, String id) {
    final builder = _AttributedTextBuilder();
    for (final segment in line.segments) {
      final data = segment.data;
      if (data is! String) {
        // An embed inside a text line is not valid in the schema; it has no
        // node representation and is dropped.
        continue;
      }
      builder.append(
        data.contains(DeltaKeys.softBreak)
            ? data.replaceAll(DeltaKeys.softBreak, '\n')
            : data,
        AttributionMapping.fromAttributes(segment.attributes),
      );
    }
    final text = builder.build();
    final end = line.endAttributes;
    final overlays = AttributionMapping.overlaysOf(end);
    final box = end?[DeltaKeys.box];
    final metadata = <String, dynamic>{
      WonkyNodeMetadata.lineAttributes: ?overlays,
      if (box is List && box.isNotEmpty) WonkyNodeMetadata.box: box,
    };

    final list = end?[DeltaKeys.list];
    final rawIndent = end?[DeltaKeys.indent];
    final indent = rawIndent is int
        ? rawIndent.clamp(0, DeltaKeys.maxIndent)
        : 0;
    // A list item inside a quote (Write 02 §1.2).
    final listMetadata = {
      ...metadata,
      if (end?[DeltaKeys.blockquote] == true) WonkyNodeMetadata.quoted: true,
    };
    if (list == 'bullet' || list == 'ordered') {
      return ListItemNode(
        id: id,
        itemType: list == 'ordered'
            ? ListItemType.ordered
            : ListItemType.unordered,
        text: text,
        indent: indent,
        metadata: listMetadata,
      );
    }
    if (list == 'checked' || list == 'unchecked') {
      return TaskNode(
        id: id,
        text: text,
        isComplete: list == 'checked',
        indent: indent,
        metadata: listMetadata,
      );
    }

    final header = end?[DeltaKeys.header];
    Attribution blockType = paragraphAttribution;
    if (header is int && header >= 1 && header <= 6) {
      blockType = headerAttributions[header - 1];
    } else if (end?[DeltaKeys.blockquote] == true) {
      blockType = blockquoteAttribution;
    }
    final step = end?[DeltaKeys.step];
    return ParagraphNode(
      id: id,
      text: text,
      metadata: {
        ...metadata,
        NodeMetadata.blockType: blockType,
        if (step is int && (header == 2 || header == 3))
          WonkyNodeMetadata.step: step,
      },
    );
  }

  DocumentNode _codeNode(List<DeltaLine> lines, String language, String id) {
    final builder = _AttributedTextBuilder();
    for (var l = 0; l < lines.length; l += 1) {
      final line = lines[l];
      for (final segment in line.segments) {
        final data = segment.data;
        if (data is String) {
          builder.append(
            data,
            AttributionMapping.fromAttributes(segment.attributes),
          );
        }
      }
      if (l < lines.length - 1) {
        builder.append(
          '\n',
          AttributionMapping.fromAttributes(
            line.endAttributes,
            overlaysOnly: true,
          ),
        );
      }
    }
    final overlays = AttributionMapping.overlaysOf(lines.last.endAttributes);
    final box = lines.first.endAttributes?[DeltaKeys.box];
    return ParagraphNode(
      id: id,
      text: builder.build(),
      metadata: {
        NodeMetadata.blockType: codeAttribution,
        WonkyNodeMetadata.codeLanguage: language,
        WonkyNodeMetadata.lineAttributes: ?overlays,
        if (box is List && box.isNotEmpty) WonkyNodeMetadata.box: box,
      },
    );
  }

  DocumentNode _embedNode(
    DeltaLine line,
    String Function() newNodeId,
    bool Function(String id) ids,
  ) {
    final segment = line.segments.single;
    final embed = (segment.data as Map).cast<String, dynamic>();
    final lineAttributes = {...?line.endAttributes};
    final box = lineAttributes.remove(DeltaKeys.box);
    final metadata = <String, dynamic>{
      WonkyNodeMetadata.embed: embed,
      if (segment.attributes != null && segment.attributes!.isNotEmpty)
        WonkyNodeMetadata.embedAttributes: segment.attributes,
      if (lineAttributes.isNotEmpty)
        WonkyNodeMetadata.lineAttributes: lineAttributes,
      if (box is List && box.isNotEmpty) WonkyNodeMetadata.box: box,
    };

    final type = embed.keys.isEmpty ? null : embed.keys.first;
    final value = type == null ? null : embed[type];
    final embedId = value is Map ? value['id'] : null;
    final String id;
    if (embedId is String && embedId.isNotEmpty && ids(embedId)) {
      id = embedId;
    } else {
      id = _takeId(newNodeId, ids);
    }

    switch (type) {
      case DeltaKeys.imageEmbed when value is Map:
        return ImageNode(
          id: id,
          imageUrl: '${value['src'] ?? ''}',
          altText: '${value['alt'] ?? ''}',
          metadata: metadata,
        );
      case DeltaKeys.dividerEmbed:
        return HorizontalRuleNode(id: id, metadata: metadata);
      case DeltaKeys.tableEmbed when value is Map:
        return TableBlockNode(
          id: id,
          cells: tableCellsFromEmbed(value),
          metadata: metadata,
        );
      default:
        return WonkyEmbedNode(id: id, metadata: metadata);
    }
  }

  /// Builds the rendered cells of a table embed: inline Markdown parsed into
  /// attributed text; row 0 is the header row; alignment from `align`.
  static List<List<TextNode>> tableCellsFromEmbed(Map<Object?, Object?> value) {
    final rows = value['rows'] is List
        ? value['rows'] as List
        : const <Object?>[];
    final align = value['align'] is List
        ? value['align'] as List
        : const <Object?>[];
    var columns = 0;
    for (final row in rows) {
      if (row is List && row.length > columns) columns = row.length;
    }
    if (rows.isEmpty || columns == 0) {
      return [
        [TextNode(id: Editor.createNodeId(), text: AttributedText(''))],
      ];
    }
    return [
      for (var r = 0; r < rows.length; r += 1)
        [
          for (var c = 0; c < columns; c += 1)
            TextNode(
              id: Editor.createNodeId(),
              text: _parseCell(
                rows[r] is List && c < (rows[r] as List).length
                    ? '${(rows[r] as List)[c] ?? ''}'
                    : '',
              ),
              metadata: {
                if (r == 0) NodeMetadata.blockType: tableHeaderAttribution,
                if (c < align.length && align[c] is String)
                  TextNodeMetadata.textAlign: align[c],
              },
            ),
        ],
    ];
  }

  static AttributedText _parseCell(String markdown) {
    if (markdown.isEmpty) {
      return AttributedText('');
    }
    try {
      return parseInlineMarkdown(markdown);
    } catch (_) {
      return AttributedText(markdown);
    }
  }
}

/// Builds an [AttributedText] from runs, merging contiguous runs of equal
/// attributions into one span.
class _AttributedTextBuilder {
  final _buffer = StringBuffer();
  final _markers = <SpanMarker>[];
  final _open = <Attribution, (int, int)>{};

  void append(String text, Set<Attribution> attributions) {
    if (text.isEmpty) {
      return;
    }
    final start = _buffer.length;
    _buffer.write(text);
    final end = _buffer.length - 1;

    // Close open spans that don't continue.
    final toClose = _open.keys.where((a) => !attributions.contains(a)).toList();
    for (final attribution in toClose) {
      final (s, e) = _open.remove(attribution)!;
      _addSpan(attribution, s, e);
    }
    for (final attribution in attributions) {
      final existing = _open[attribution];
      if (existing != null && existing.$2 == start - 1) {
        _open[attribution] = (existing.$1, end);
      } else {
        if (existing != null) {
          _addSpan(attribution, existing.$1, existing.$2);
        }
        _open[attribution] = (start, end);
      }
    }
  }

  void _addSpan(Attribution attribution, int start, int end) {
    _markers
      ..add(
        SpanMarker(
          attribution: attribution,
          offset: start,
          markerType: SpanMarkerType.start,
        ),
      )
      ..add(
        SpanMarker(
          attribution: attribution,
          offset: end,
          markerType: SpanMarkerType.end,
        ),
      );
  }

  AttributedText build() {
    for (final entry in _open.entries) {
      _addSpan(entry.key, entry.value.$1, entry.value.$2);
    }
    _open.clear();
    return AttributedText(
      _buffer.toString(),
      AttributedSpans(attributions: _markers),
    );
  }
}

/// Whether two serialized node Deltas are equal (deep equality of ops).
bool nodeDeltasEqual(Delta a, Delta b) =>
    _deepEquality.equals(a.toJson(), b.toJson());
