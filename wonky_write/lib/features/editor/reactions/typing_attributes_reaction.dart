import 'package:collection/collection.dart';
import 'package:super_editor/super_editor.dart';

import '../attributions/wonky_attributions.dart';
import '../mapping/attribution_mapping.dart';
import '../mapping/wonky_schema.dart';
import 'pill_boundary.dart';

/// Maintains the typing attributes (`composer.preferences.currentAttributions`)
/// when the caret moves (Write 04 §10.3). Replaces super_editor's
/// `UpdateComposerTextStylesReaction`.
///
/// - Inline formatting (bold, italic, strike, code) comes from the character
///   upstream of the caret (downstream at offset 0).
/// - Links and comment anchors extend only when the caret is strictly inside
///   them; mentions and suggestions never extend.
/// - Chips, buttons and arrow links also extend at their end unless the
///   caret was moved out with → ([PillBoundary], Write 11 §7.4).
/// - In code blocks, typed text gets no inline formatting.
class WonkyTypingAttributesReaction extends EditReaction {
  WonkyTypingAttributesReaction({this.boundary});

  /// Inside or outside the chip or button the caret is at the end of.
  final PillBoundary? boundary;

  DocumentSelection? _previousSelection;

  @override
  void react(
    EditContext editorContext,
    RequestDispatcher requestDispatcher,
    List<EditEvent> changeList,
  ) {
    final lastSelectionChange =
        changeList.lastWhereOrNull((e) => e is SelectionChangeEvent)
            as SelectionChangeEvent?;
    final composer = editorContext.find<MutableDocumentComposer>(
      Editor.composerKey,
    );
    if (lastSelectionChange == null) {
      return;
    }
    final selection = composer.selection;
    boundary?.onSelectionChanged(selection);
    final previous = _previousSelection;
    _previousSelection = selection;
    if (selection == null) {
      composer.preferences.clearStyles();
      return;
    }
    if (previous != null &&
        previous.isCollapsed &&
        selection.isCollapsed &&
        previous.extent.nodeId == selection.extent.nodeId &&
        previous.extent.nodePosition.isEquivalentTo(
          selection.extent.nodePosition,
        )) {
      // Only the affinity changed, or nothing: keep pending toggles.
      return;
    }

    final node = editorContext.document.getNodeById(selection.extent.nodeId);
    if (selection.isCollapsed &&
        node is TextNode &&
        node.text.isEmpty &&
        !isCodeBlockNode(node) &&
        lastSelectionChange.changeType != SelectionChangeType.placeCaret) {
      // A new, empty block (e.g. after Enter): keep the pending formatting,
      // like Google Docs does.
      composer.preferences.replaceStyles(
        composer.preferences.currentAttributions
            .where(AttributionMapping.isFormattingAttribution)
            .toSet(),
      );
      return;
    }

    composer.preferences.replaceStyles(
      typingAttributesAt(editorContext.document, selection, boundary: boundary),
    );
  }

  /// The typing attributes for a caret at [selection] (empty when expanded).
  static Set<Attribution> typingAttributesAt(
    Document document,
    DocumentSelection selection, {
    PillBoundary? boundary,
  }) {
    if (!selection.isCollapsed) {
      return const {};
    }
    final node = document.getNodeById(selection.extent.nodeId);
    final position = selection.extent.nodePosition;
    if (node is! TextNode ||
        position is! TextNodePosition ||
        node.text.isEmpty) {
      return const {};
    }
    final offset = position.offset;
    final text = node.text;
    final isCode = isCodeBlockNode(node);

    final result = <Attribution>{};
    final sourceOffset = offset == 0 ? 0 : offset - 1;
    if (!isCode) {
      for (final attribution in text.getAllAttributionsAt(sourceOffset)) {
        if (AttributionMapping.isFormattingAttribution(attribution)) {
          result.add(attribution);
        }
      }
    }

    // Links and comments extend only strictly inside: the characters on both
    // sides of the caret carry the same attribution.
    if (offset > 0 && offset < text.length) {
      final before = text.getAllAttributionsAt(offset - 1);
      final after = text.getAllAttributionsAt(offset);
      for (final attribution in before) {
        // Chips and styled links too (Write 11 §2.1).
        if ((attribution is LinkAttribution &&
                !before.any((a) => a is MentionAttribution)) ||
            attribution is LinkStyleAttribution ||
            attribution is ChipAttribution ||
            attribution is CommentAttribution) {
          if (after.contains(attribution)) {
            result.add(attribution);
          }
        }
      }
    }
    // At the end of a chip or button: inside unless moved out.
    if (!isCode && !(boundary?.isOutsideAt(selection.extent) ?? false)) {
      result.addAll(PillBoundary.endingAt(text, offset));
    }
    return result;
  }
}

extension on ComposerPreferences {
  void replaceStyles(Set<Attribution> styles) {
    final current = currentAttributions;
    if (const SetEquality<Attribution>().equals(current, styles)) {
      return;
    }
    clearStyles();
    addStyles(styles);
  }
}
