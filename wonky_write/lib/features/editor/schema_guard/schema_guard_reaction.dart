import 'package:super_editor/super_editor.dart';

import '../attributions/wonky_attributions.dart';
import '../mapping/attribution_mapping.dart';
import '../mapping/wonky_embed_node.dart';
import '../mapping/wonky_schema.dart';

/// Keeps the document inside the Wonky Delta Schema v1 no matter which
/// super_editor feature produced a change (Write 04 §2.4). Runs last, inside
/// the same transaction, only on the nodes the transaction touched.
class WonkySchemaGuardReaction extends EditReaction {
  const WonkySchemaGuardReaction();

  static final _controlCharacters = RegExp(
    '[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
  );
  static final _tab = RegExp('\t');

  static final _allowedBlockTypes = <Attribution>{
    paragraphAttribution,
    blockquoteAttribution,
    codeAttribution,
    header1Attribution,
    header2Attribution,
    header3Attribution,
    header4Attribution,
    header5Attribution,
    header6Attribution,
  };

  @override
  void modifyContent(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    _guard(editorContext, requestDispatcher, changeList);
  }

  @override
  void react(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    _guard(editorContext, requestDispatcher, changeList);
  }

  void _guard(
    EditContext editContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final touched = <String>{};
    for (final event in changeList) {
      if (event is! DocumentEdit) continue;
      final change = event.change;
      if (change is NodeDocumentChange && change is! NodeRemovedEvent) {
        touched.add(change.nodeId);
      }
    }
    if (touched.isEmpty) {
      return;
    }
    final document = editContext.document;
    final composer = editContext.composer;
    final requests = <EditRequest>[];
    final neighbors = <String>{};

    for (final nodeId in touched) {
      final node = document.getNodeById(nodeId);
      if (node == null) continue;
      final index = document.getNodeIndexById(nodeId);
      final next = document.getNodeAt(index + 1);
      if (next != null) neighbors.add(next.id);

      if (node is TextNode) {
        final fixed = fixTextNode(node, document.getNodeAt(index - 1));
        if (!identical(fixed, node)) {
          requests.add(
            ReplaceNodeRequest(existingNodeId: node.id, newNode: fixed),
          );
        }
      } else if (node is! ImageNode &&
          node is! HorizontalRuleNode &&
          node is! TableBlockNode &&
          node is! WonkyEmbedNode) {
        // A node type the schema can't express (e.g. video, audio, files).
        if (document.nodeCount > 1) {
          requests.add(DeleteNodeRequest(nodeId: node.id));
        } else {
          requests.add(
            ReplaceNodeRequest(
              existingNodeId: node.id,
              newNode: ParagraphNode(id: node.id, text: AttributedText('')),
            ),
          );
        }
      }
    }

    // Children whose indent jumps by more than one level after an edit.
    for (final nodeId in neighbors.difference(touched)) {
      final node = document.getNodeById(nodeId);
      if (node is ListItemNode || node is TaskNode) {
        final index = document.getNodeIndexById(nodeId);
        final fixed = fixTextNode(
          node as TextNode,
          document.getNodeAt(index - 1),
        );
        if (!identical(fixed, node)) {
          requests.add(
            ReplaceNodeRequest(existingNodeId: node.id, newNode: fixed),
          );
        }
      }
    }

    if (requests.isEmpty) {
      return;
    }
    final selection = composer.selection;
    requestDispatcher.execute([
      ...requests,
      if (selection != null)
        ChangeSelectionRequest(
          _clampSelection(document, selection, requests),
          SelectionChangeType.alteredContent,
          SelectionReason.contentChange,
        ),
    ]);
  }

  DocumentSelection _clampSelection(
    Document document,
    DocumentSelection selection,
    List<EditRequest> requests,
  ) {
    DocumentPosition clamp(DocumentPosition position) {
      for (final request in requests) {
        if (request is ReplaceNodeRequest &&
            request.existingNodeId == position.nodeId) {
          final node = request.newNode;
          final nodePosition = position.nodePosition;
          if (node is TextNode &&
              nodePosition is TextNodePosition &&
              nodePosition.offset > node.text.length) {
            return DocumentPosition(
              nodeId: node.id,
              nodePosition: TextNodePosition(offset: node.text.length),
            );
          }
        }
      }
      return position;
    }

    return DocumentSelection(
      base: clamp(selection.base),
      extent: clamp(selection.extent),
    );
  }

  /// Returns [node] fixed to the schema, or [node] itself when it is valid.
  static TextNode fixTextNode(TextNode node, DocumentNode? previous) {
    var result = node;

    // Block type and paragraph indentation.
    if (result is ParagraphNode) {
      final blockType = result.getMetadataValue(NodeMetadata.blockType);
      if (blockType is! Attribution ||
          !_allowedBlockTypes.contains(blockType)) {
        result = result.copyParagraphWith(
          metadata: {
            ...result.metadata,
            NodeMetadata.blockType: paragraphAttribution,
          },
        );
      }
      if (result.indent != 0) {
        result = result.copyParagraphWith(indent: 0);
      }
    }

    // List indentation: at most 8, at most one deeper than the previous item
    // of the same list (a quoted and an unquoted list are two lists).
    if (result is ListItemNode || result is TaskNode) {
      final indent = result is ListItemNode
          ? result.indent
          : (result as TaskNode).indent;
      final sameList = isQuotedListNode(previous) == isQuotedListNode(result);
      final previousIndent = !sameList
          ? -1
          : previous is ListItemNode
          ? previous.indent
          : previous is TaskNode
          ? previous.indent
          : -1;
      final maxIndent = (previousIndent + 1).clamp(0, DeltaKeys.maxIndent);
      if (indent > maxIndent) {
        result = result is ListItemNode
            ? result.copyListItemWith(indent: maxIndent)
            : (result as TaskNode).copyTaskWith(indent: maxIndent);
      }
    }

    // Attributions.
    final isCode = isCodeBlockNode(result);
    var text = result.text;
    final markers = text.spans.markers.toList();
    var changedSpans = false;
    final keptMarkers = <SpanMarker>[];
    for (final marker in markers) {
      final attribution = marker.attribution;
      final allowed =
          AttributionMapping.isSchemaAttribution(attribution) ||
          !_isDisallowedFormatting(attribution);
      final allowedInCode =
          !isCode ||
          AttributionMapping.isOverlayAttribution(attribution) ||
          !_isInline(attribution);
      if (allowed && allowedInCode) {
        keptMarkers.add(marker);
      } else {
        changedSpans = true;
      }
    }
    if (changedSpans) {
      text = AttributedText(
        text.toPlainText(includePlaceholders: false),
        AttributedSpans(attributions: keptMarkers),
      );
    }

    // Inline code excludes bold/italic/strike.
    if (!isCode) {
      final codeSpans = text.getAttributionSpansInRange(
        attributionFilter: (a) => a == codeAttribution,
        range: SpanRange(0, text.length),
      );
      if (codeSpans.isNotEmpty) {
        AttributedText? copy;
        for (final span in codeSpans) {
          for (final excluded in [
            boldAttribution,
            italicsAttribution,
            strikethroughAttribution,
          ]) {
            final range = SpanRange(span.start, span.end);
            if ((copy ?? text).hasAttributionsWithin(
              attributions: {excluded},
              range: range,
            )) {
              copy ??= text.copy();
              copy.removeAttribution(excluded, range);
            }
          }
        }
        if (copy != null) {
          text = copy;
          changedSpans = true;
        }
      }
    }

    // Characters: tabs outside code → 4 spaces, control characters removed,
    // U+2028 → "\n" (soft breaks are "\n" in node text).
    var plain = text.toPlainText(includePlaceholders: false);
    if (plain.contains(DeltaKeys.softBreak)) {
      plain = plain.replaceAll(DeltaKeys.softBreak, '\n');
      text = AttributedText(plain, text.spans.copy());
      changedSpans = true;
    }
    if (_controlCharacters.hasMatch(plain) ||
        (!isCode && plain.contains('\t'))) {
      text = _replaceCharacters(text, isCode);
      changedSpans = true;
    }

    if (changedSpans) {
      result = result.copyTextNodeWith(text: text);
    }
    return result;
  }

  static bool _isInline(Attribution attribution) =>
      AttributionMapping.isFormattingAttribution(attribution) ||
      attribution is LinkAttribution ||
      attribution is MentionAttribution;

  static bool _isDisallowedFormatting(Attribution attribution) =>
      attribution == underlineAttribution ||
      attribution == superscriptAttribution ||
      attribution == subscriptAttribution ||
      attribution is ScriptAttribution ||
      attribution is ColorAttribution ||
      attribution is BackgroundColorAttribution ||
      attribution is FontFamilyAttribution ||
      attribution is FontSizeAttribution;

  /// Rebuilds [text] with tabs (outside code) expanded to four spaces and
  /// control characters removed, keeping attributions per character.
  static AttributedText _replaceCharacters(AttributedText text, bool isCode) {
    final plain = text.toPlainText(includePlaceholders: false);
    var result = AttributedText('');
    var runStart = 0;
    void flush(int end) {
      if (end > runStart) {
        result = result.copyAndAppend(text.copyText(runStart, end));
      }
    }

    for (var i = 0; i < plain.length; i += 1) {
      final char = plain[i];
      final isControl = _controlCharacters.hasMatch(char);
      final isTab = !isCode && _tab.hasMatch(char);
      if (!isControl && !isTab) continue;
      flush(i);
      if (isTab) {
        final attributions = text.getAllAttributionsAt(i);
        result = result.copyAndAppend(
          AttributedText('    ')
            ..addAttributions(attributions, const SpanRange(0, 3)),
        );
      }
      runStart = i + 1;
    }
    flush(plain.length);
    return result;
  }
}

extension on AttributedText {
  void addAttributions(Set<Attribution> attributions, SpanRange range) {
    for (final attribution in attributions) {
      addAttribution(attribution, range);
    }
  }
}

/// Removes comment anchors from attributions sets (used by copy).
Set<Attribution> withoutComments(Set<Attribution> attributions) =>
    attributions.where((a) => a is! CommentAttribution).toSet();
