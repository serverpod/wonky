import 'package:collection/collection.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show
        BoxFrame,
        BoxType,
        Boxes,
        CalloutVariant,
        CellAlign,
        CellEditException,
        CellEdits,
        CellGrid,
        CellLines,
        DeltaUtils,
        GridBullets,
        MarkdownFlavor,
        WonkyAttr,
        WonkyDeltaNormalizer,
        WonkyDocument,
        WonkyEmbed,
        WonkyToGfm,
        YouTubeEmbed;

import '../../../l10n/write_l10n.dart';
import '../applier/delta_applier.dart';
import '../attributions/wonky_attributions.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../mapping/delta_node_codec.dart';
import '../mapping/delta_ops.dart';
import '../mapping/wonky_schema.dart';
import '../model/cells.dart';
import '../model/code_languages.dart';
import '../model/document_queries.dart';
import '../model/embeds.dart';
import '../model/link_url_policy.dart';
import '../model/table_model.dart';
import '../reactions/typing_attributes_reaction.dart';

part 'wonky_markdown_commands.dart';

/// Block types of `write.format.blockType` / `write.block.turnInto`.
enum BlockKind {
  paragraph,
  heading1,
  heading2,
  heading3,
  heading4,
  heading5,
  heading6,
  quote,
  codeBlock,
  bulleted,
  numbered,
  checklist;

  static BlockKind? tryParse(String? name) =>
      BlockKind.values.firstWhereOrNull((k) => k.name == name);

  int? get headingLevel => switch (this) {
    heading1 => 1,
    heading2 => 2,
    heading3 => 3,
    heading4 => 4,
    heading5 => 5,
    heading6 => 6,
    _ => null,
  };

  String get label => switch (this) {
    paragraph => 'Normal text',
    heading1 => 'Heading 1',
    heading2 => 'Heading 2',
    heading3 => 'Heading 3',
    heading4 => 'Heading 4',
    heading5 => 'Heading 5',
    heading6 => 'Heading 6',
    quote => 'Quote',
    codeBlock => 'Code block',
    bulleted => 'Bulleted list',
    numbered => 'Numbered list',
    checklist => 'Checklist',
  };

  /// [label] in [l]'s language (undo labels, announcements).
  String labelOf(WriteLocalizations l) => switch (this) {
    paragraph => l.cmdFormatBlockTypeParagraph,
    heading1 => l.cmdFormatBlockTypeHeading1,
    heading2 => l.cmdFormatBlockTypeHeading2,
    heading3 => l.cmdFormatBlockTypeHeading3,
    heading4 => l.cmdFormatBlockTypeHeading4,
    heading5 => l.cmdFormatBlockTypeHeading5,
    heading6 => l.cmdFormatBlockTypeHeading6,
    quote => l.cmdFormatBlockTypeQuote,
    codeBlock => l.cmdFormatBlockTypeCodeBlock,
    bulleted => l.cmdListToggleBulleted,
    numbered => l.cmdListToggleNumbered,
    checklist => l.cmdListToggleChecklist,
  };
}

/// Inline formats of the toggle commands.
enum InlineFormat {
  bold('bold', 'Bold'),
  italic('italic', 'Italic'),
  strikethrough('strike', 'Strikethrough'),
  code('code', 'Code');

  const InlineFormat(this.key, this.label);

  /// Delta attribute key.
  final String key;
  final String label;

  /// [label] in [l]'s language (undo labels, announcements).
  String labelOf(WriteLocalizations l) => switch (this) {
    bold => l.cmdFormatBold,
    italic => l.cmdFormatItalic,
    strikethrough => l.cmdFormatStrikethrough,
    code => l.cmdFormatInlineCode,
  };

  Attribution get attribution => switch (this) {
    bold => boldAttribution,
    italic => italicsAttribution,
    strikethrough => strikethroughAttribution,
    code => codeAttribution,
  };
}

/// A link found in the document.
class LinkRun {
  const LinkRun(this.url, this.start, this.end, {this.mentionUuid});

  final String url;

  /// Delta range `[start, end)`.
  final int start;
  final int end;

  /// Set when the link is a mention chip.
  final String? mentionUuid;
}

/// Thrown by commands for invalid arguments (reported to MCP callers).
class EditorCommandError implements Exception {
  const EditorCommandError(this.message);
  final String message;

  @override
  String toString() => 'EditorCommandError: $message';
}

/// The editor-level implementation of the Write 04 command catalog (§40).
///
/// Every mutating method builds one change Delta and applies it through
/// [WriteEditorController.applyLocal] (one undo step, label = command title),
/// so it behaves the same from menus, shortcuts and MCP, and becomes a
/// suggestion in Suggesting mode. Methods return `false` when not applicable.
class WriteEditorCommands {
  WriteEditorCommands(this.controller, {LinkUrlPolicy? linkPolicy})
    : linkPolicy =
          linkPolicy ?? LinkUrlPolicy(documentUuid: controller.documentUuid);

  final WriteEditorController controller;
  final LinkUrlPolicy linkPolicy;

  /// Language used for new code blocks (the user's last-used language).
  String lastCodeLanguage = '';

  bool get canEdit => controller.mode != EditorMode.viewing;

  bool get isSuggesting => controller.mode == EditorMode.suggesting;

  DeltaSelection? get selection => controller.selection;

  /// The Write strings for undo labels and announcements (CQ-57).
  WriteLocalizations get _l => controller.strings();

  LocalDeltaChange? _apply(
    Delta change,
    String label, {
    DeltaSelection? selectionAfter,
  }) {
    if (!canEdit) return null;
    if (isSuggesting) controller.startNewSuggestion();
    return controller.applyLocal(
      change,
      label: label,
      selectionAfter: selectionAfter,
    );
  }

  List<BlockRef> _selectedBlocks() {
    final s = selection;
    if (s == null) return const [];
    return controller.mirror.blocksInSelection(s);
  }

  // ---------------------------------------------------------------------------
  // Inline formatting (§10).

  bool _eligibleFor(InlineFormat format, Operation piece, BlockRef block) {
    if (block.isCode || !FormatChanges.isInlineText(piece)) return false;
    if (format != InlineFormat.code &&
        piece.attributes?[DeltaKeys.code] == true) {
      return false;
    }
    return true;
  }

  /// Whether [format] can be toggled at the current selection.
  bool canToggleFormat(InlineFormat format) {
    final s = selection;
    if (!canEdit || s == null) return false;
    final blocks = controller.mirror.blocksInSelection(s);
    if (blocks.isEmpty || blocks.every((b) => b.isEmbed)) return false;
    if (s.isCollapsed) return !blocks.first.isCode && blocks.first.isText;
    return blocks.any((b) => b.isText && !b.isCode);
  }

  /// Whether [format] is active: all eligible selected characters have it,
  /// or the typing attributes have it for a collapsed caret.
  bool isFormatActive(InlineFormat format) {
    final s = selection;
    if (s == null) return false;
    if (s.isCollapsed) {
      return controller.composer.preferences.currentAttributions.contains(
        format.attribution,
      );
    }
    // Walks the attribute runs of the selection without copying text and
    // stops at the first eligible run without the format (W-14: the toolbar
    // asks on every rebuild, also after select-all on a long document).
    // Eligible: inline text (not line ends, not embeds) outside code
    // blocks, and not inline code unless [format] is code.
    var any = false;
    final mirror = controller.mirror;
    for (final block in mirror.blocksIn(s.start, s.end)) {
      if (block.isCode) continue;
      var offset = block.start;
      for (final op in mirror.entryAt(block.index).delta.operations) {
        final opStart = offset;
        offset += op.length!;
        final from = opStart > s.start ? opStart : s.start;
        final to = offset < s.end ? offset : s.end;
        if (to <= from) continue;
        final data = op.data;
        if (data is! String ||
            !_hasTextBetween(data, from - opStart, to - opStart)) {
          continue;
        }
        final attributes = op.attributes;
        if (format != InlineFormat.code &&
            attributes?[DeltaKeys.code] == true) {
          continue;
        }
        any = true;
        if (attributes?[format.key] != true) return false;
      }
    }
    return any;
  }

  /// Whether `text[start, end)` has a character other than a line end.
  static bool _hasTextBetween(String text, int start, int end) {
    for (var i = start; i < end; i++) {
      if (text.codeUnitAt(i) != 0x0A) return true;
    }
    return false;
  }

  /// `write.format.bold` / `italic` / `strikethrough` / `inlineCode`.
  bool toggleFormat(InlineFormat format) {
    final s = selection;
    if (!canToggleFormat(format) || s == null) return false;
    if (s.isCollapsed) {
      final preferences = controller.composer.preferences;
      preferences.toggleStyle(format.attribution);
      if (format == InlineFormat.code &&
          preferences.currentAttributions.contains(codeAttribution)) {
        preferences.removeStyles({
          boldAttribution,
          italicsAttribution,
          strikethroughAttribution,
        });
      }
      controller.notify(
        EditorNotice(
          EditorNoticeKind.announcement,
          preferences.currentAttributions.contains(format.attribution)
              ? _l.announceFormatOn(format.labelOf(_l))
              : _l.announceFormatOff(format.labelOf(_l)),
        ),
      );
      return true;
    }
    final active = isFormatActive(format);
    final attributes = <String, dynamic>{format.key: active ? null : true};
    if (format == InlineFormat.code && !active) {
      attributes.addAll({
        DeltaKeys.bold: null,
        DeltaKeys.italic: null,
        DeltaKeys.strike: null,
      });
    }
    final change = FormatChanges.format(
      controller.mirror,
      s.start,
      s.end,
      attributes,
      eligible: (piece, block) => _eligibleFor(format, piece, block),
    );
    if (change.isEmpty) return false;
    _apply(change, format.labelOf(_l), selectionAfter: s);
    controller.notify(
      EditorNotice(
        EditorNoticeKind.announcement,
        active
            ? _l.announceFormatOff(format.labelOf(_l))
            : _l.announceFormatOn(format.labelOf(_l)),
      ),
    );
    return true;
  }

  /// `write.format.clearFormatting`: removes bold, italic, strike and code
  /// (links, mentions, comments, suggestions and block types are kept).
  bool clearFormatting() {
    final s = selection;
    if (!canEdit || s == null) return false;
    if (s.isCollapsed) {
      controller.composer.preferences.removeStyles({
        boldAttribution,
        italicsAttribution,
        strikethroughAttribution,
        codeAttribution,
      });
      return true;
    }
    final change = FormatChanges.format(
      controller.mirror,
      s.start,
      s.end,
      {
        DeltaKeys.bold: null,
        DeltaKeys.italic: null,
        DeltaKeys.strike: null,
        DeltaKeys.code: null,
      },
      eligible: (piece, block) =>
          !block.isCode && FormatChanges.isInlineText(piece),
    );
    if (change.isEmpty) return false;
    _apply(change, _l.undoClearFormatting, selectionAfter: s);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Block types and lists (§12, §13).

  static const _clearBlock = {
    DeltaKeys.header: null,
    DeltaKeys.blockquote: null,
    DeltaKeys.codeBlock: null,
    DeltaKeys.list: null,
    DeltaKeys.indent: null,
  };

  /// The block kind of [block] (lists by their list type).
  static BlockKind kindOf(BlockRef block) {
    final node = block.node;
    if (node is ListItemNode) {
      return node.type == ListItemType.ordered
          ? BlockKind.numbered
          : BlockKind.bulleted;
    }
    if (node is TaskNode) return BlockKind.checklist;
    if (node is ParagraphNode) {
      final type = node.getMetadataValue(NodeMetadata.blockType);
      if (type == codeAttribution) return BlockKind.codeBlock;
      if (type == blockquoteAttribution) return BlockKind.quote;
      final level = headingLevelOf(type);
      if (level != null) {
        return BlockKind.values[BlockKind.heading1.index + level - 1];
      }
    }
    return BlockKind.paragraph;
  }

  /// The common kind of the selected text blocks, or `null` when mixed.
  BlockKind? get selectedBlockKind {
    final kinds = _selectedBlocks().where((b) => b.isText).map(kindOf).toSet();
    return kinds.length == 1 ? kinds.single : null;
  }

  /// Whether every selected text block is in a quote (a quote line or a
  /// quoted list item): the Quote toggle is on.
  bool get selectionInQuote {
    final blocks = _selectedBlocks().where((b) => b.isText).toList();
    return blocks.isNotEmpty && blocks.every((b) => isInQuoteNode(b.node));
  }

  bool canChangeBlockType() =>
      canEdit && _selectedBlocks().any((b) => b.isText);

  /// `write.format.blockType {type}` and the list toggles. Quote, code and
  /// lists are toggles; headings are not. With [toggle] `false`
  /// (`write.block.turnInto`), the type is always applied.
  bool setBlockType(
    BlockKind kind, {
    bool toggle = true,
    String? nodeId,
    String? label,
  }) {
    final blocks = nodeId != null
        ? [?controller.mirror.blockOf(nodeId)]
        : _selectedBlocks();
    final textBlocks = blocks.where((b) => b.isText).toList();
    if (!canEdit || textBlocks.isEmpty) return false;
    final isToggle =
        toggle &&
        const {
          BlockKind.quote,
          BlockKind.codeBlock,
          BlockKind.bulleted,
          BlockKind.numbered,
          BlockKind.checklist,
        }.contains(kind);
    final target = isToggle && textBlocks.every((b) => kindOf(b) == kind)
        ? BlockKind.paragraph
        : kind;
    // Lists inside quotes (§14): Quote on lines that are all in a quote
    // takes them out of it (list items stay list items); Quote on list items
    // moves them into a quote; list kinds keep the quote a line is in, and
    // toggling a list off inside a quote leaves a quote line.
    const listKinds = {
      BlockKind.bulleted,
      BlockKind.numbered,
      BlockKind.checklist,
    };
    final unquote =
        isToggle &&
        kind == BlockKind.quote &&
        textBlocks.every((b) => isInQuoteNode(b.node));
    final listOff = listKinds.contains(kind) && target == BlockKind.paragraph;

    final language = lastCodeLanguage;
    Map<String, dynamic> attributesOf(BlockRef block) {
      final node = block.node;
      final isItem = node is ListItemNode || node is TaskNode;
      final inQuote = isInQuoteNode(node);
      if (unquote) {
        return isItem ? {DeltaKeys.blockquote: null} : {..._clearBlock};
      }
      if (kind == BlockKind.quote && isItem) {
        return {DeltaKeys.blockquote: true};
      }
      final current = kindOf(block);
      final currentIndent = switch (node) {
        ListItemNode(:final indent) || TaskNode(:final indent) => indent,
        _ => 0,
      };
      final attributes = _blockAttributesFor(
        listOff && inQuote ? BlockKind.quote : target,
        current,
        currentIndent,
        node,
        language,
      );
      if (listKinds.contains(target) && inQuote) {
        attributes[DeltaKeys.blockquote] = true;
      }
      return attributes;
    }

    final change = Delta();
    var offset = 0;
    for (final block in textBlocks) {
      change.retain(block.start - offset);
      offset = block.start;
      final delta = controller.mirror.entryAt(block.index).delta;
      final attributes = attributesOf(block);
      for (final op in delta.operations) {
        final data = op.data;
        if (data is! String) {
          change.retain(op.length!);
          continue;
        }
        var runStart = 0;
        for (var i = 0; i <= data.length; i += 1) {
          final atEnd = i == data.length;
          final char = atEnd ? null : data[i];
          if (!atEnd &&
              char != '\n' &&
              !(target == BlockKind.codeBlock && char == DeltaKeys.softBreak)) {
            continue;
          }
          if (i > runStart) {
            // Text: code blocks drop inline formatting.
            change.retain(
              i - runStart,
              target == BlockKind.codeBlock
                  ? _stripInline(op.attributes)
                  : null,
            );
          }
          if (!atEnd) {
            if (char == DeltaKeys.softBreak) {
              change
                ..delete(1)
                ..insert('\n', {DeltaKeys.codeBlock: language});
            } else {
              change.retain(1, attributes);
            }
          }
          runStart = i + 1;
        }
      }
      offset += block.length;
    }
    change.trim();
    if (change.isEmpty) return false;
    final s = selection;
    _apply(
      change,
      label ?? target.labelOf(_l),
      selectionAfter: s?.transform(change),
    );
    controller.notify(
      EditorNotice(EditorNoticeKind.announcement, target.labelOf(_l)),
    );
    return true;
  }

  static Map<String, dynamic>? _stripInline(Map<String, dynamic>? attributes) {
    if (attributes == null) return null;
    final result = <String, dynamic>{
      for (final key in DeltaKeys.inlineKeys)
        if (attributes.containsKey(key)) key: null,
    };
    return result.isEmpty ? null : result;
  }

  Map<String, dynamic> _blockAttributesFor(
    BlockKind target,
    BlockKind current,
    int currentIndent,
    DocumentNode node,
    String language,
  ) {
    final isList = const {
      BlockKind.bulleted,
      BlockKind.numbered,
      BlockKind.checklist,
    };
    final keepIndent =
        isList.contains(target) &&
        isList.contains(current) &&
        currentIndent > 0;
    return switch (target) {
      BlockKind.paragraph => {..._clearBlock},
      BlockKind.quote => {..._clearBlock, DeltaKeys.blockquote: true},
      BlockKind.codeBlock => {
        ..._clearBlock,
        DeltaKeys.codeBlock: current == BlockKind.codeBlock
            ? codeLanguageOf(node)
            : language,
      },
      BlockKind.bulleted => {
        ..._clearBlock,
        DeltaKeys.list: 'bullet',
        if (keepIndent) DeltaKeys.indent: currentIndent,
      },
      BlockKind.numbered => {
        ..._clearBlock,
        DeltaKeys.list: 'ordered',
        if (keepIndent) DeltaKeys.indent: currentIndent,
      },
      BlockKind.checklist => {
        ..._clearBlock,
        DeltaKeys.list: node is TaskNode && node.isComplete
            ? 'checked'
            : 'unchecked',
        if (keepIndent) DeltaKeys.indent: currentIndent,
      },
      _ => {..._clearBlock, DeltaKeys.header: target.headingLevel},
    };
  }

  bool toggleBulleted() => setBlockType(BlockKind.bulleted);
  bool toggleNumbered() => setBlockType(BlockKind.numbered);
  bool toggleChecklist() => setBlockType(BlockKind.checklist);

  int _indentOf(DocumentNode node) => node is ListItemNode
      ? node.indent
      : node is TaskNode
      ? node.indent
      : -1;

  bool _isListNode(DocumentNode? node) =>
      node is ListItemNode || node is TaskNode;

  /// Whether `write.list.indent` can indent at least one selected item.
  bool canIndent() {
    if (!canEdit) return false;
    return _indentPlan().isNotEmpty;
  }

  Map<BlockRef, int> _indentPlan() {
    final plan = <BlockRef, int>{};
    int? previousNewIndent;
    for (final block in _selectedBlocks()) {
      if (!_isListNode(block.node)) {
        previousNewIndent = null;
        continue;
      }
      final indent = _indentOf(block.node);
      final previousIndent =
          previousNewIndent ??
          (block.index > 0
              ? _indentOf(controller.mirror.blockAt(block.index - 1).node)
              : -1);
      final maxIndent = (previousIndent + 1).clamp(0, DeltaKeys.maxIndent);
      final newIndent = indent + 1 <= maxIndent ? indent + 1 : indent;
      if (newIndent != indent) plan[block] = newIndent;
      previousNewIndent = newIndent;
    }
    return plan;
  }

  /// `write.list.indent` (Tab).
  bool indent() {
    final plan = _indentPlan();
    if (!canEdit || plan.isEmpty) return false;
    final change = Delta();
    var offset = 0;
    for (final MapEntry(key: block, value: level) in plan.entries) {
      change
        ..retain(block.lineEnd - offset)
        ..retain(1, {DeltaKeys.indent: level});
      offset = block.lineEnd + 1;
    }
    _apply(change, _l.undoIndent, selectionAfter: selection);
    controller.notify(
      EditorNotice(
        EditorNoticeKind.announcement,
        _l.announceListLevel(plan.values.last + 1),
      ),
    );
    return true;
  }

  bool canOutdent() =>
      canEdit && _selectedBlocks().any((b) => _isListNode(b.node));

  /// `write.list.outdent` (Shift+Tab): at level 0 the item becomes a paragraph.
  bool outdent() {
    final items = _selectedBlocks().where((b) => _isListNode(b.node)).toList();
    if (!canEdit || items.isEmpty) return false;
    final change = Delta();
    var offset = 0;
    for (final block in items) {
      final indent = _indentOf(block.node);
      change
        ..retain(block.lineEnd - offset)
        ..retain(
          1,
          indent > 0
              ? {DeltaKeys.indent: indent - 1 == 0 ? null : indent - 1}
              : {..._clearBlock},
        );
      offset = block.lineEnd + 1;
    }
    _apply(change, _l.undoOutdent, selectionAfter: selection);
    return true;
  }

  bool canToggleChecked({String? nodeId}) =>
      canEdit &&
      (nodeId != null
          ? controller.mirror.blockOf(nodeId)?.node is TaskNode
          : _selectedBlocks().any((b) => b.node is TaskNode));

  /// `write.list.toggleChecked {nodeId?}`.
  bool toggleChecked({String? nodeId}) {
    final tasks =
        (nodeId != null
                ? [?controller.mirror.blockOf(nodeId)]
                : _selectedBlocks())
            .where((b) => b.node is TaskNode)
            .toList();
    if (!canEdit || tasks.isEmpty) return false;
    final check = !tasks.every((b) => (b.node as TaskNode).isComplete);
    final change = Delta();
    var offset = 0;
    for (final block in tasks) {
      change
        ..retain(block.lineEnd - offset)
        ..retain(1, {DeltaKeys.list: check ? 'checked' : 'unchecked'});
      offset = block.lineEnd + 1;
    }
    _apply(
      change,
      check ? _l.undoCheckItem : _l.undoUncheckItem,
      selectionAfter: selection,
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Links (§11).

  /// The link run at [offset] (or the caret / selection start).
  LinkRun? linkAt([int? offset]) {
    final s = selection;
    final at = offset ?? s?.start;
    if (at == null) return null;
    final block = controller.mirror.blockAtOffset(at);
    final node = block.node;
    if (node is! TextNode) return null;
    final local = at - block.start;
    for (final probe in [local, local - 1]) {
      if (probe < 0 || probe >= node.text.length) continue;
      final link = node.text
          .getAllAttributionsAt(probe)
          .whereType<LinkAttribution>()
          .firstOrNull;
      if (link == null) continue;
      final range = node.text.getAttributedRange({link}, probe);
      final mention = node.text
          .getAllAttributionsAt(probe)
          .whereType<MentionAttribution>()
          .firstOrNull;
      return LinkRun(
        link.plainTextUri,
        block.start + range.start,
        block.start + range.end + 1,
        mentionUuid: mention?.userUuid,
      );
    }
    return null;
  }

  bool canInsertLink() {
    final s = selection;
    if (!canEdit || s == null) return false;
    final blocks = controller.mirror.blocksInSelection(s);
    return blocks.any((b) => b.isText && !b.isCode);
  }

  /// `write.link.set {url, text?, range?}`. Throws [EditorCommandError] for
  /// URLs the policy rejects.
  bool setLink(String url, {String? text, int? start, int? length}) {
    final normalized = linkPolicy.normalize(url);
    if (normalized is InvalidLinkUrl) {
      throw EditorCommandError(normalized.reason);
    }
    final link = (normalized as ValidLinkUrl).url;
    if (!canEdit) return false;
    final s = selection;
    final rangeStart = start ?? s?.start;
    final rangeEnd = start != null ? start + (length ?? 0) : s?.end;
    if (rangeStart == null || rangeEnd == null) return false;

    if (rangeEnd > rangeStart &&
        (text == null ||
            text == controller.mirror.textOf(rangeStart, rangeEnd))) {
      final change = FormatChanges.format(
        controller.mirror,
        rangeStart,
        rangeEnd,
        {DeltaKeys.link: link},
        eligible: (piece, block) =>
            !block.isCode && FormatChanges.isInlineText(piece),
      );
      if (change.isEmpty) return false;
      _apply(
        change,
        _l.undoInsertLink,
        selectionAfter: DeltaSelection(rangeStart, rangeEnd),
      );
      return true;
    }

    // Collapsed caret (or replacing the selected text): insert linked text.
    final existing = rangeEnd == rangeStart ? linkAt(rangeStart) : null;
    if (existing != null && text == null) {
      final change = DeltaOps.format(
        existing.start,
        existing.end - existing.start,
        {DeltaKeys.link: link},
      );
      _apply(change, _l.undoEditLink);
      return true;
    }
    final insertText = (text == null || text.isEmpty) ? link : text;
    final attributes = <String, dynamic>{
      ...?_inlineFormattingAt(rangeStart),
      DeltaKeys.link: link,
    };
    final change = Delta()
      ..retain(rangeStart)
      ..delete(rangeEnd - rangeStart)
      ..insert(insertText.replaceAll('\n', ' '), attributes);
    _apply(
      change,
      _l.undoInsertLink,
      selectionAfter: DeltaSelection.collapsed(rangeStart + insertText.length),
    );
    return true;
  }

  Map<String, dynamic>? _inlineFormattingAt(int offset) {
    final s = DeltaSelection.collapsed(offset);
    final documentSelection = controller.mirror.selectionAt(s.anchor, s.head);
    if (documentSelection == null) return null;
    final attributions = WonkyTypingAttributesReaction.typingAttributesAt(
      controller.document,
      documentSelection,
    );
    final result = <String, dynamic>{
      for (final format in InlineFormat.values)
        if (attributions.contains(format.attribution)) format.key: true,
    };
    return result.isEmpty ? null : result;
  }

  /// `write.link.remove {range?}` (default: the link run at the caret).
  bool removeLink({int? start, int? length}) {
    if (!canEdit) return false;
    int from;
    int to;
    if (start != null) {
      from = start;
      to = start + (length ?? 0);
    } else {
      final s = selection;
      if (s == null) return false;
      if (s.isCollapsed) {
        final run = linkAt(s.start);
        if (run == null) return false;
        from = run.start;
        to = run.end;
      } else {
        from = s.start;
        to = s.end;
      }
    }
    final change = FormatChanges.format(
      controller.mirror,
      from,
      to,
      {DeltaKeys.link: null},
      eligible: (piece, block) => piece.attributes?[DeltaKeys.mention] == null,
    );
    if (change.isEmpty) return false;
    _apply(change, _l.undoRemoveLink);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Insertions (§16–19).

  /// Where a new block embed goes: `(offset, replacesEmptyParagraph)`.
  (int, bool) _embedInsertionPoint() {
    final s = selection;
    final block = s == null
        ? controller.mirror.blockAt(controller.mirror.nodeCount - 1)
        : controller.mirror.blockAtOffset(s.end);
    final node = block.node;
    if (node is ParagraphNode &&
        node.text.isEmpty &&
        kindOf(block) == BlockKind.paragraph) {
      return (block.start, true);
    }
    return (block.start + block.length, false);
  }

  /// The line-end attributes that put a new line in the containers of the
  /// caret's block (`{box: …}`), or `null` outside containers.
  Map<String, dynamic>? _hostLineAttributes() {
    final s = selection;
    final block = s == null
        ? controller.mirror.blockAt(controller.mirror.nodeCount - 1)
        : controller.mirror.blockAtOffset(s.end);
    final box = boxValueOf(block.node);
    return box == null ? null : {DeltaKeys.box: box};
  }

  bool get _caretInCode {
    final s = selection;
    return s != null && controller.mirror.blockAtOffset(s.start).isCode;
  }

  /// Blocks are not inserted in code blocks, table cells or grid items
  /// (Write 12 §3.4).
  bool canInsertBlock() => canEdit && !_caretInCode && !caretInCell;

  /// Inserts the embed [values] (each followed by `"\n"`) after the current
  /// block (or replacing an empty paragraph), creating a text block after the
  /// last one when needed, and moves the caret to the following text block.
  LocalDeltaChange? _insertEmbeds(
    List<Map<String, dynamic>> values,
    String label,
  ) {
    if (!canInsertBlock() || values.isEmpty) return null;
    final (at, replaces) = _embedInsertionPoint();
    // Embeds inserted in a container go into it (Write 11 §7.4).
    final host = _hostLineAttributes();
    final change = Delta()..retain(at);
    for (var i = 0; i < values.length; i += 1) {
      change.insert(values[i]);
      if (!(replaces && i == values.length - 1)) {
        change.insert('\n', host);
      }
    }
    final insertedLength = values.length * 2 - (replaces ? 1 : 0);
    final afterEnd = at + insertedLength + (replaces ? 1 : 0);
    final nextIndex = replaces
        ? controller.mirror.indexAtOffset(at) + 1
        : controller.mirror.indexAtOffset(at);
    final hasTextAfter =
        at < controller.mirror.length &&
        nextIndex < controller.mirror.nodeCount &&
        (replaces || controller.mirror.startOfIndex(nextIndex) == at) &&
        controller.mirror.blockAt(nextIndex).isText;
    if (!hasTextAfter) {
      if (replaces) change.retain(1);
      change.insert('\n', host);
    }
    return _apply(
      change,
      label,
      selectionAfter: DeltaSelection.collapsed(afterEnd),
    );
  }

  /// `write.insert.divider`.
  bool insertDivider() =>
      _insertEmbeds([
        {
          DeltaKeys.dividerEmbed: {'id': controller.newEmbedId()},
        },
      ], _l.undoInsertDivider) !=
      null;

  /// `write.insert.imageFromUrl {url, alt?}` and the upload flow
  /// (`write.insert.imageFiles` with `wonky-file://` sources). Returns the
  /// embed ids.
  List<String> insertImages(
    List<({String src, String alt, String? title})> images, {
    String? label,
  }) {
    label ??= _l.undoInsertImage;
    final ids = <String>[];
    final values = <Map<String, dynamic>>[];
    for (final image in images) {
      final id = controller.newEmbedId();
      ids.add(id);
      values.add({
        DeltaKeys.imageEmbed: {
          'id': id,
          'src': image.src,
          'alt': image.alt,
          'title': ?image.title,
        },
      });
    }
    if (!canInsertBlock()) return const [];

    // Mid-paragraph: split the paragraph at the caret (§17.2).
    final s = selection;
    if (s != null && s.isCollapsed) {
      final block = controller.mirror.blockAtOffset(s.start);
      final local = s.start - block.start;
      if (block.isText && local > 0 && local < block.length - 1) {
        final change = Delta()
          ..retain(s.start)
          ..insert('\n', block.blockAttributes);
        final host = _hostLineAttributes();
        for (final value in values) {
          change
            ..insert(value)
            ..insert('\n', host);
        }
        _apply(
          change,
          label,
          selectionAfter: DeltaSelection.collapsed(
            s.start + 1 + values.length * 2,
          ),
        );
        return ids;
      }
    }
    return _insertEmbeds(values, label) == null ? const [] : ids;
  }

  /// `write.insert.table {rows, cols}`: a table of empty cell lines (Write
  /// 12 §3.5), the caret in its first cell. Returns the table's id.
  String? insertTable({int rows = 3, int columns = 3}) {
    if (isSuggesting || caretInCell) return null;
    final id = controller.newEmbedId();
    final lines = CellLines.table(
      id: id,
      rows: List.generate(
        rows.clamp(1, 2000),
        (_) => List.generate(columns.clamp(1, 64), (_) => Delta()),
      ),
    );
    return _insertLines(lines, _l.undoInsertTable) == null ? null : id;
  }

  /// `write.insert.mention {userUuid, replaceComposing}`: replaces `[start,
  /// end)` (the composing `@query`, or nothing) with `@Display Name` + space.
  bool insertMention({
    required String userUuid,
    required String displayName,
    required String email,
    int? replaceStart,
    int? replaceEnd,
  }) {
    final s = selection;
    final start = replaceStart ?? s?.start;
    final end = replaceEnd ?? s?.end;
    if (!canEdit || start == null || end == null || _caretInCode) return false;
    final text = '@$displayName';
    final change = Delta()
      ..retain(start)
      ..delete(end - start)
      ..insert(text, {
        DeltaKeys.mention: userUuid,
        DeltaKeys.link: 'mailto:$email',
      })
      ..insert(' ');
    _apply(
      change,
      _l.undoMention,
      selectionAfter: DeltaSelection.collapsed(start + text.length + 1),
    );
    return true;
  }

  /// `write.edit.insertText {text}` (emoji, special characters, MCP).
  bool insertText(String text, {int? position, String? label}) {
    label ??= _l.undoInsertText;
    final s = selection;
    final start = position ?? s?.start;
    final end = position ?? s?.end;
    if (!canEdit || start == null || end == null || text.isEmpty) return false;
    final block = controller.mirror.blockAtOffset(start);
    final clean = block.isCode
        ? text
        : text.replaceAll('\n', DeltaKeys.softBreak);
    final change = Delta()
      ..retain(start)
      ..delete(end - start)
      ..insert(clean, block.isCode ? null : _inlineFormattingAt(start));
    _apply(
      change,
      label,
      selectionAfter: DeltaSelection.collapsed(start + clean.length),
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Code blocks (§15).

  BlockRef? _codeBlock(String? nodeId) {
    final block = nodeId != null
        ? controller.mirror.blockOf(nodeId)
        : (selection == null
              ? null
              : controller.mirror.blockAtOffset(selection!.start));
    return block != null && block.isCode ? block : null;
  }

  bool canEditCode({String? nodeId}) => canEdit && _codeBlock(nodeId) != null;

  /// `write.code.setLanguage {language, nodeId?}`.
  bool setCodeLanguage(String language, {String? nodeId}) {
    final block = _codeBlock(nodeId);
    if (!canEdit || block == null) return false;
    final normalized = CodeLanguages.normalize(language);
    lastCodeLanguage = normalized;
    final change = Delta()..retain(block.start);
    final delta = controller.mirror.entryAt(block.index).delta;
    for (final op in delta.operations) {
      final data = op.data;
      if (data is! String) {
        change.retain(op.length!);
        continue;
      }
      var runStart = 0;
      for (var i = 0; i < data.length; i += 1) {
        if (data[i] != '\n') continue;
        if (i > runStart) change.retain(i - runStart);
        change.retain(1, {DeltaKeys.codeBlock: normalized});
        runStart = i + 1;
      }
      if (runStart < data.length) change.retain(data.length - runStart);
    }
    change.trim();
    _apply(change, _l.undoSetCodeLanguage, selectionAfter: selection);
    return true;
  }

  /// `write.code.exit`: an empty paragraph after the block, caret there.
  bool exitCodeBlock({bool removeTrailingEmptyLines = false}) {
    final block = _codeBlock(null);
    if (!canEdit || block == null) return false;
    final text = (block.node as TextNode).text.toPlainText();
    final change = Delta();
    var end = block.start + block.length;
    if (removeTrailingEmptyLines && text.endsWith('\n\n')) {
      // Triple Enter: drop the two empty lines (§15.3).
      change
        ..retain(block.lineEnd - 2)
        ..delete(2)
        ..retain(1)
        ..insert('\n');
      end -= 2;
    } else {
      change
        ..retain(end)
        ..insert('\n');
    }
    _apply(
      change,
      _l.undoExitCodeBlock,
      selectionAfter: DeltaSelection.collapsed(end),
    );
    return true;
  }

  static const _indentUnit = 2;

  /// `write.code.indentLines` (Tab in code).
  bool indentCodeLines() => _shiftCodeLines(indent: true);

  /// `write.code.outdentLines` (Shift+Tab in code).
  bool outdentCodeLines() => _shiftCodeLines(indent: false);

  bool _shiftCodeLines({required bool indent}) {
    final s = selection;
    final block = _codeBlock(null);
    if (!canEdit || block == null || s == null) return false;
    final text = (block.node as TextNode).text.toPlainText();
    final localStart = (s.start - block.start).clamp(0, text.length);
    final localEnd = (s.end - block.start).clamp(0, text.length);

    if (indent && s.isCollapsed) {
      final lineStart = localStart == 0
          ? 0
          : text.lastIndexOf('\n', localStart - 1) + 1;
      final column = localStart - lineStart;
      final spaces = _indentUnit - column % _indentUnit;
      final change = Delta()
        ..retain(s.start)
        ..insert(' ' * spaces);
      _apply(
        change,
        _l.undoIndent,
        selectionAfter: DeltaSelection.collapsed(s.start + spaces),
      );
      return true;
    }

    // Every touched line.
    final lineStarts = <int>[];
    var lineStart = localStart == 0
        ? 0
        : text.lastIndexOf('\n', localStart - 1) + 1;
    while (true) {
      lineStarts.add(lineStart);
      final next = text.indexOf('\n', lineStart);
      if (next < 0 ||
          next + 1 > localEnd ||
          (next + 1 == localEnd && localEnd > localStart)) {
        break;
      }
      lineStart = next + 1;
    }
    final change = Delta();
    var offset = 0;
    for (final start in lineStarts) {
      change.retain(block.start + start - offset);
      offset = block.start + start;
      if (indent) {
        change.insert(' ' * _indentUnit);
      } else {
        var count = 0;
        while (count < _indentUnit &&
            start + count < text.length &&
            text[start + count] == ' ') {
          count += 1;
        }
        if (count > 0) {
          change.delete(count);
          offset += count;
        }
      }
    }
    change.trim();
    if (change.isEmpty) return true;
    _apply(
      change,
      indent ? _l.undoIndent : _l.undoOutdent,
      selectionAfter: s.transform(change),
    );
    return true;
  }

  /// The plain text of a code block (`write.code.copy`).
  String? codeText({String? nodeId}) {
    final block = _codeBlock(nodeId);
    return block == null ? null : (block.node as TextNode).text.toPlainText();
  }

  // ---------------------------------------------------------------------------
  // Blocks (§22).

  BlockRef? _targetBlock(String? nodeId) => nodeId != null
      ? controller.mirror.blockOf(nodeId)
      : (selection == null
            ? null
            : controller.mirror.blockAtOffset(selection!.start));

  /// The blocks a block command acts on: the selection's blocks, plus the
  /// descendants of list items (§22.4).
  List<BlockRef> _blocksToMove(String? nodeId) {
    final blocks = nodeId != null
        ? [?controller.mirror.blockOf(nodeId)]
        : _selectedBlocks();
    if (blocks.isEmpty) return const [];
    final last = blocks.last;
    final lastIndent = _indentOf(last.node);
    final result = [...blocks];
    if (lastIndent >= 0) {
      for (var i = last.index + 1; i < controller.mirror.nodeCount; i += 1) {
        final next = controller.mirror.blockAt(i);
        if (_indentOf(next.node) > lastIndent) {
          result.add(next);
        } else {
          break;
        }
      }
    }
    return result;
  }

  /// The blocks `write.block.move*` acts on for [nodeId] (or the selection):
  /// list items include their descendants (§22.4).
  List<BlockRef> blocksToMove({String? nodeId}) => _blocksToMove(nodeId);

  /// Inserts the complete Delta [lines] (each ending with `"\n"`) as new
  /// blocks before the block at [index] (`nodeCount` = after the last block),
  /// e.g. dropped files and images (§24). The caret goes to the end of the
  /// inserted content.
  LocalDeltaChange? insertBlocksAt(
    int index,
    Delta lines, {
    required String label,
  }) {
    if (!canEdit || lines.isEmpty) return null;
    final last = lines.last.data;
    if (last is! String || !last.endsWith('\n')) return null;
    final count = controller.mirror.nodeCount;
    final at = index >= count
        ? controller.mirror.length
        : controller.mirror.startOfIndex(index.clamp(0, count));
    final change = Delta()..retain(at);
    var length = 0;
    for (final op in lines.operations) {
      change.push(op);
      length += op.length!;
    }
    return _apply(
      change..trim(),
      label,
      selectionAfter: DeltaSelection.collapsed(
        (at + length - 1).clamp(0, controller.mirror.length + length - 1),
      ),
    );
  }

  bool canMoveBlock({required bool up, String? nodeId}) {
    if (!canEdit || isSuggesting) return false;
    final blocks = _blocksToMove(nodeId);
    if (blocks.isEmpty) return false;
    return up
        ? blocks.first.index > 0
        : blocks.last.index < controller.mirror.nodeCount - 1;
  }

  /// `write.block.moveUp` / `moveDown`.
  bool moveBlock({required bool up, String? nodeId}) {
    if (!canMoveBlock(up: up, nodeId: nodeId)) return false;
    final blocks = _blocksToMove(nodeId);
    final target = up ? blocks.first.index - 1 : blocks.last.index + 2;
    return moveBlocks(
      [for (final b in blocks) b.id],
      target,
      label: _l.undoMoveBlock,
    );
  }

  /// `write.block.move {nodeIds, toIndex}`: moves the blocks (contiguous run)
  /// so that they end up before the node currently at [toIndex].
  bool moveBlocks(List<String> nodeIds, int toIndex, {String? label}) {
    label ??= _l.undoMoveBlock;
    if (!canEdit || isSuggesting || nodeIds.isEmpty) return false;
    final blocks = [for (final id in nodeIds) ?controller.mirror.blockOf(id)]
      ..sort((a, b) => a.index.compareTo(b.index));
    if (blocks.isEmpty) return false;
    final first = blocks.first;
    final last = blocks.last;
    if (toIndex >= first.index && toIndex <= last.index + 1) return false;
    final start = first.start;
    final end = last.start + last.length;
    final fragment = controller.mirror.slice(start, end);
    final s = selection;
    final Delta change;
    int movedStart;
    if (toIndex < first.index) {
      final at = controller.mirror.startOfIndex(toIndex);
      change = Delta()
        ..retain(at)
        ..concatInto(fragment)
        ..retain(start - at)
        ..delete(end - start);
      movedStart = at;
    } else {
      final at = controller.mirror.startOfIndex(
        toIndex.clamp(0, controller.mirror.nodeCount),
      );
      change = Delta()
        ..retain(start)
        ..delete(end - start)
        ..retain(at - end)
        ..concatInto(fragment);
      movedStart = at - (end - start);
    }
    DeltaSelection? after;
    if (s != null && s.start >= start && s.end <= end) {
      after = DeltaSelection(
        s.anchor - start + movedStart,
        s.head - start + movedStart,
      );
    }
    _apply(change..trim(), label, selectionAfter: after);
    return true;
  }

  /// `write.block.duplicate {nodeId?}` (embeds get new ids).
  bool duplicateBlock({String? nodeId}) {
    final block = _targetBlock(nodeId);
    if (!canEdit || isSuggesting || block == null) return false;
    var fragment = controller.mirror.slice(
      block.start,
      block.start + block.length,
    );
    fragment = Delta.fromOperations([
      for (final op in fragment.operations)
        if (op.data is Map)
          Operation.insert(_withNewId(op.data as Map), op.attributes)
        else
          op,
    ]);
    final change = Delta()..retain(block.start + block.length);
    for (final op in fragment.operations) {
      change.push(op);
    }
    _apply(
      change,
      _l.undoDuplicate,
      selectionAfter: DeltaSelection.collapsed(block.start + block.length),
    );
    return true;
  }

  Map<String, dynamic> _withNewId(Map<Object?, Object?> value) {
    final type = value.keys.first as String;
    final inner = (value[type] as Map).cast<String, dynamic>();
    return {
      type: {...inner, 'id': controller.newEmbedId()},
    };
  }

  /// `write.block.delete {nodeId?}`. The document keeps at least one
  /// paragraph.
  bool deleteBlock({String? nodeId}) {
    final blocks = nodeId != null
        ? [?controller.mirror.blockOf(nodeId)]
        : _selectedBlocks();
    if (!canEdit || blocks.isEmpty) return false;
    final start = blocks.first.start;
    final end = blocks.last.start + blocks.last.length;
    final change = Delta()
      ..retain(start)
      ..delete(end - start);
    if (start == 0 && end == controller.mirror.length) {
      change.insert('\n');
    }
    _apply(
      change,
      _l.undoDelete,
      selectionAfter: DeltaSelection.collapsed(start),
    );
    return true;
  }

  /// `write.block.select {nodeId?}` (block selection, not undoable).
  bool selectBlock({String? nodeId}) {
    final block = _targetBlock(nodeId);
    if (block == null) return false;
    controller.select(
      DeltaSelection(block.start, block.start + block.length - 1),
    );
    return true;
  }

  // ---------------------------------------------------------------------------
  // Images (§17.4).

  BlockRef? _embedBlock(String? nodeId, String type) {
    final block = _targetBlock(nodeId);
    if (block == null || EmbedNodes.embedTypeOf(block.node) != type) {
      return null;
    }
    return block;
  }

  /// Replaces the embed of [block] with [value] (same id): delete + insert.
  LocalDeltaChange? _replaceEmbed(
    BlockRef block,
    Map<String, dynamic> value,
    String label,
  ) {
    final change = Delta()
      ..retain(block.start)
      ..delete(1)
      ..insert(
        value,
        block.node.getMetadataValue(WonkyNodeMetadata.embedAttributes)
            as Map<String, dynamic>?,
      );
    return _apply(change, label, selectionAfter: selection);
  }

  /// `write.image.setAlt {nodeId?, alt, title?}`.
  bool setImageAlt(String alt, {String? title, String? nodeId}) {
    final block = _embedBlock(nodeId, DeltaKeys.imageEmbed);
    if (!canEdit || block == null) return false;
    final data = EmbedNodes.embedDataOf(block.node)!;
    final value = {
      DeltaKeys.imageEmbed:
          {
            ...data,
            'alt': alt.length > 500 ? alt.substring(0, 500) : alt,
            if (title != null && title.isNotEmpty) 'title': title,
          }..removeWhere(
            (key, v) => key == 'title' && (title != null && title.isEmpty),
          ),
    };
    return _replaceEmbed(block, value, _l.undoAltText) != null;
  }

  /// `write.image.replace` / `replaceFromUrl {nodeId?, url}`: keeps the id.
  bool replaceImage(String src, {String? nodeId}) {
    final block = _embedBlock(nodeId, DeltaKeys.imageEmbed);
    if (!canEdit || isSuggesting || block == null) return false;
    final data = EmbedNodes.embedDataOf(block.node)!;
    return _replaceEmbed(block, {
          DeltaKeys.imageEmbed: {...data, 'src': src},
        }, _l.undoReplaceImage) !=
        null;
  }

  // ---------------------------------------------------------------------------
  // Tables (§18, Write 12 §3.5).

  /// The table or grid around node [nodeId] (a cell or item node, or the
  /// table or grid id), or around the caret.
  EditorCellRun? cellRunAt({String? nodeId}) {
    if (nodeId != null) return EditorCellRun.of(controller.mirror, nodeId);
    final s = selection;
    if (s == null) return null;
    return EditorCellRun.at(
      controller.mirror,
      controller.mirror.blockAtOffset(s.end).index,
    );
  }

  /// The table around [nodeId] or the caret.
  EditorCellRun? tableRunAt({String? nodeId}) {
    final run = cellRunAt(nodeId: nodeId);
    return run?.table == null ? null : run;
  }

  /// The (row, column) of the caret in its table.
  (int, int)? caretCell() {
    final s = selection;
    if (s == null) return null;
    final index = controller.mirror.blockAtOffset(s.end).index;
    return EditorCellRun.at(
      controller.mirror,
      index,
    )?.cellAt(controller.mirror, index);
  }

  /// `write.table.editCell {row, col}`: selects the text of cell ([row],
  /// [col]) of the table at [nodeId] or the caret (the caret when empty).
  bool selectCell(int row, int col, {String? nodeId}) {
    final run = tableRunAt(nodeId: nodeId);
    final index = run?.nodeIndexOfCell(row, col);
    if (run == null || index == null) return false;
    final block = controller.mirror.blockAt(index);
    controller.select(DeltaSelection(block.start, block.lineEnd));
    return true;
  }

  /// Whether the caret is in a table cell or grid item.
  bool get caretInCell {
    final s = selection;
    return s != null &&
        isCellNode(controller.mirror.blockAtOffset(s.start).node);
  }

  /// The table at [nodeId] (or the caret's) as a [TableModel].
  TableModel? tableOf({String? nodeId}) {
    final t = tableRunAt(nodeId: nodeId)?.table;
    return t == null ? null : TableModel.fromCells(t);
  }

  bool canEditTable({String? nodeId}) =>
      canEdit && !isSuggesting && tableRunAt(nodeId: nodeId) != null;

  /// Runs the structural edit [edit] on the table or grid at [nodeId] (or
  /// the caret's) as one undo step [label]. Structural edits are not
  /// suggestable (Write 12 §3.5). `true` when the edit applied or the table
  /// already had the requested value.
  bool editCells(
    Delta? Function(EditorCellRun run) edit, {
    String? nodeId,
    required String label,
    DeltaSelection? Function(EditorCellRun run, Delta change)? selectionAfter,
  }) {
    if (!canEdit || isSuggesting) return false;
    final run = cellRunAt(nodeId: nodeId);
    if (run == null) return false;
    final Delta? change;
    try {
      change = edit(run);
    } on CellEditException {
      return false;
    }
    if (change == null) return true;
    final shifted = run.shift(change);
    final normalized = const WonkyDeltaNormalizer()
        .normalizeChange(
          controller.mirror.slice(0, controller.mirror.length),
          shifted,
        )
        .change;
    return _apply(
          normalized,
          label,
          selectionAfter: selectionAfter?.call(run, normalized),
        ) !=
        null;
  }

  /// `write.table.replace {nodeId, table}` (the table editor's Done): one
  /// undo step "Edit table". Cells whose Markdown did not change keep their
  /// lines (comments and all, Write 12 §3.6).
  bool replaceTable(TableModel table, {String? nodeId, String? label}) {
    if (!canEditTable(nodeId: nodeId ?? table.id)) return false;
    return editCells(
      (run) {
        final current = TableModel.fromCells(run.table!);
        Delta cellAt(int r, int c) {
          final markdown = table.rows[r][c];
          if (r < current.rows.length &&
              c < current.rows[r].length &&
              current.rows[r][c] == markdown &&
              c < run.table!.rows[r].cells.length) {
            final line = run.table!.rows[r].cells[c];
            final d = Delta();
            for (final s in line.segments) {
              d.insert(s.data, s.attributes);
            }
            return d;
          }
          return CellLines.markdown(markdown);
        }

        return CellEdits.replaceTable(
          run.doc,
          run.id,
          [
            for (var r = 0; r < table.rows.length; r++)
              [for (var c = 0; c < table.rows[r].length; c++) cellAt(r, c)],
          ],
          align: [for (final a in table.align) CellAlign.tryParse(a.value)],
        );
      },
      nodeId: nodeId ?? table.id,
      label: label ?? _l.undoEditTable,
    );
  }

  /// Inserts the complete lines [lines] after the current block (or in place
  /// of an empty paragraph) in the caret's containers, with a text block
  /// after them, and puts the caret at [caret] (an offset in [lines]).
  LocalDeltaChange? _insertLines(Delta lines, String label, {int caret = 0}) {
    if (!canInsertBlock()) return null;
    final (at, replaces) = _embedInsertionPoint();
    final host = _hostLineAttributes();
    final box = host?[DeltaKeys.box];
    final change = Delta()..retain(at);
    if (replaces) change.delete(1);
    for (final line in WonkyDocument(lines).lines) {
      for (final seg in line.segments) {
        change.insert(seg.data, seg.attributes);
      }
      change.insert('\n', {...line.attributes, DeltaKeys.box: ?box});
    }
    final length = DeltaUtils.documentLength(lines);
    final nextIndex = replaces
        ? controller.mirror.indexAtOffset(at) + 1
        : controller.mirror.indexAtOffset(at);
    final hasTextAfter =
        at < controller.mirror.length &&
        nextIndex < controller.mirror.nodeCount &&
        controller.mirror.blockAt(nextIndex).isText &&
        !isCellNode(controller.mirror.blockAt(nextIndex).node);
    if (!hasTextAfter) change.insert('\n', host);
    return _apply(
      change,
      label,
      selectionAfter: DeltaSelection.collapsed(at + caret.clamp(0, length)),
    );
  }

  // ---------------------------------------------------------------------------
  // Selection and editing (§4, §23.5).

  /// `write.edit.selectAll`: inside a code block that isn't fully selected,
  /// selects the code; otherwise the whole document.
  void selectAll() {
    final s = selection;
    final block = s == null ? null : controller.mirror.blockAtOffset(s.start);
    if (block != null && block.isCode && s != null) {
      final codeEnd = block.start + block.length - 1;
      final isFullySelected = s.start == block.start && s.end == codeEnd;
      final endBlock = controller.mirror.blockAtOffset(s.end);
      if (!isFullySelected && endBlock.id == block.id) {
        controller.select(DeltaSelection(block.start, codeEnd));
        return;
      }
    }
    controller.select(DeltaSelection(0, controller.mirror.length - 1));
  }

  /// `write.edit.selectRange {anchor, head}`.
  void selectRange(int anchor, int head) =>
      controller.select(DeltaSelection(anchor, head));

  /// `write.edit.delete`: deletes the selection.
  bool deleteSelection() {
    final s = selection;
    if (!canEdit || s == null || s.isCollapsed) return false;
    return controller.runLabelled(_l.undoDelete, () {
      controller.editor.execute([
        DeleteContentRequest(
          documentRange: controller.composer.selection!.normalize(
            controller.document,
          ),
        ),
        ChangeSelectionRequest(
          controller.mirror.selectionAt(s.start, s.start),
          SelectionChangeType.deleteContent,
          SelectionReason.userInteraction,
        ),
      ]);
      return true;
    });
  }

  /// Inserts a Delta [fragment] (from paste, Markdown, MCP) at the selection
  /// with the paste semantics of §23.3: the first line merges into the
  /// current block (whose type is kept unless it's an empty paragraph), the
  /// last line merges with the text after the caret, a selection is replaced.
  /// In code blocks only plain text is inserted.
  LocalDeltaChange? insertFragment(
    Delta fragment, {
    String? label,
    int? start,
    int? end,
  }) {
    label ??= _l.undoPaste;
    var s = selection;
    if (start == null &&
        s != null &&
        !s.isCollapsed &&
        _selectionTouchesCells(s) &&
        controller.mirror.blockAtOffset(s.start).id !=
            controller.mirror.blockAtOffset(s.end).id) {
      // Pasting over a selection across cells clears the cells first and
      // pastes into the first (Write 12 §3.4).
      deleteSelection();
      s = selection;
    }
    final from = start ?? s?.start;
    final to = end ?? s?.end ?? from;
    if (!canEdit || from == null || to == null || fragment.isEmpty) return null;
    // A pasted table or grid is a new one (Write 12 §1.3).
    fragment = CellLines.regenerateIds(fragment);
    var lines = splitDeltaIntoLines(fragment);
    if (lines.isEmpty) return null;

    final change = Delta()..retain(from);
    if (to > from) change.delete(to - from);

    final block = controller.mirror.blockAtOffset(from);
    final local = from - block.start;
    final blockAttributes = block.blockAttributes;
    final fragmentEndsWithNewline = _endsWithNewline(fragment);

    if (isCellNode(block.node)) {
      // A cell or grid item is one line: the pasted lines' text joined with
      // spaces, inline formatting kept (Write 12 §3.4).
      var first = true;
      for (final line in lines) {
        if (!first) change.insert(' ');
        first = false;
        for (final segment in line.segments) {
          final data = segment.data;
          if (data is! String) continue;
          final text = data.replaceAll(DeltaKeys.softBreak, ' ');
          if (text.isNotEmpty) {
            change.insert(text, segment.attributes);
          }
        }
      }
      final inserted = _insertedLength(change);
      return _apply(
        change..trim(),
        label,
        selectionAfter: DeltaSelection.collapsed(from + inserted),
      );
    }

    if (block.isCode) {
      // Plain text; newlines stay code lines.
      final text = lines
          .map(
            (l) => l.segments
                .map((s) => s.data is String ? s.data as String : '')
                .join(),
          )
          .join('\n');
      _insertCodeText(
        change,
        text.replaceAll(DeltaKeys.softBreak, '\n'),
        blockAttributes,
      );
      final inserted = _insertedLength(change);
      return _apply(
        change..trim(),
        label,
        selectionAfter: DeltaSelection.collapsed(from + inserted),
      );
    }

    // Pasted containers get new ids and go into the caret's containers
    // (Write 11 §7.4).
    if (controller.markdownFlavor() == MarkdownFlavor.gfm) {
      fragment = _gfmFragment(fragment);
    } else {
      fragment = _nestFragment(fragment, boxOf(block.node));
    }
    lines = splitDeltaIntoLines(fragment);
    final isEmptyParagraph =
        block.isText &&
        (block.node as TextNode).text.isEmpty &&
        kindOf(block) == BlockKind.paragraph &&
        to == from;

    if (isEmptyParagraph) {
      // The pasted lines win: insert them all before the empty line end and
      // drop that line end when the fragment brings its own.
      for (final op in fragment.operations) {
        change.push(op);
      }
      if (fragmentEndsWithNewline) change.delete(1);
      final inserted = _insertedLength(change);
      final caret = from + inserted - (fragmentEndsWithNewline ? 1 : 0);
      return _apply(
        change..trim(),
        label,
        selectionAfter: DeltaSelection.collapsed(caret),
      );
    }

    // Non-empty block: merge the first line, keep the block's type.
    final complete = fragmentEndsWithNewline
        ? lines
        : lines.sublist(0, lines.length - 1);
    final trailing = fragmentEndsWithNewline ? null : lines.last;
    for (var i = 0; i < complete.length; i += 1) {
      final line = complete[i];
      if (_isCellLine(line)) {
        // Cell and item lines stay whole lines (Write 12 §3.4).
        if (i == 0 && local > 0) change.insert('\n', blockAttributes);
        for (final segment in line.segments) {
          change.insert(segment.data, segment.attributes);
        }
        change.insert('\n', line.endAttributes);
        continue;
      }
      if (line.isEmbedLine) {
        if (i == 0 && local > 0) change.insert('\n', blockAttributes);
        change
          ..insert(line.segments.single.data, line.segments.single.attributes)
          ..insert(
            '\n',
            {
              ...?AttributionMappingOverlays.of(line.endAttributes),
              if (line.endAttributes?[DeltaKeys.box] != null)
                DeltaKeys.box: line.endAttributes![DeltaKeys.box],
            }.nullIfEmpty,
          );
        continue;
      }
      for (final segment in line.segments) {
        change.insert(segment.data, segment.attributes);
      }
      final ends = i == 0
          ? _mergeOverlays(blockAttributes, line.endAttributes)
          : line.endAttributes;
      change.insert('\n', ends);
    }
    if (trailing != null) {
      for (final segment in trailing.segments) {
        change.insert(segment.data, segment.attributes);
      }
    }
    final inserted = _insertedLength(change);
    return _apply(
      change..trim(),
      label,
      selectionAfter: DeltaSelection.collapsed(from + inserted),
    );
  }

  static bool _isCellLine(DeltaLine line) =>
      line.endAttributes?[DeltaKeys.cell] != null ||
      line.endAttributes?[DeltaKeys.gridItem] != null;

  bool _selectionTouchesCells(DeltaSelection s) => controller.mirror
      .blocksInSelection(s)
      .any((block) => isCellNode(block.node));

  static Map<String, dynamic>? _mergeOverlays(
    Map<String, dynamic>? block,
    Map<String, dynamic>? end,
  ) {
    final overlays = AttributionMappingOverlays.of(end);
    if (block == null) return overlays;
    if (overlays == null) return block;
    return {...block, ...overlays};
  }

  void _insertCodeText(
    Delta change,
    String text,
    Map<String, dynamic>? codeAttributes,
  ) {
    final parts = text.split('\n');
    for (var i = 0; i < parts.length; i += 1) {
      if (parts[i].isNotEmpty) change.insert(parts[i]);
      if (i < parts.length - 1) change.insert('\n', codeAttributes);
    }
  }

  static int _insertedLength(Delta change) {
    var length = 0;
    for (final op in change.operations) {
      if (op.isInsert) length += op.length!;
    }
    return length;
  }

  static bool _endsWithNewline(Delta fragment) {
    if (fragment.isEmpty) return false;
    final data = fragment.last.data;
    return data is String && data.endsWith('\n');
  }

  /// `write.edit.replaceRange {start, length, text}` (MCP/AI).
  bool replaceRangeWithText(int start, int length, String text) =>
      replaceRangeWithTextLabelled(start, length, text);

  /// [replaceRangeWithText] with an undo [label] ("Cut", "Replace"…).
  bool replaceRangeWithTextLabelled(
    int start,
    int length,
    String text, {
    String? label,
  }) {
    label ??= _l.undoReplace;
    if (!canEdit) return false;
    final block = controller.mirror.blockAtOffset(start);
    final clean = block.isCode
        ? text
        : text.replaceAll('\n', DeltaKeys.softBreak);
    final change = Delta()
      ..retain(start)
      ..delete(length)
      ..insert(clean, block.isCode ? null : _inlineFormattingAt(start));
    _apply(
      change..trim(),
      label,
      selectionAfter: DeltaSelection.collapsed(start + clean.length),
    );
    return true;
  }
}

extension on Delta {
  void concatInto(Delta fragment) {
    for (final op in fragment.operations) {
      push(op);
    }
  }
}

/// Overlay-only view of attributes (comments/suggestions on line ends).
abstract final class AttributionMappingOverlays {
  static Map<String, dynamic>? of(Map<String, dynamic>? attributes) {
    if (attributes == null) return null;
    final result = <String, dynamic>{
      for (final e in attributes.entries)
        if (DeltaKeys.isOverlay(e.key)) e.key: e.value,
    };
    return result.isEmpty ? null : result;
  }
}

/// Builds the image embed value used by commands (kept here for callers).
Map<String, dynamic> imageEmbedValue({
  required String id,
  required String src,
  String alt = '',
  String? title,
}) => {
  DeltaKeys.imageEmbed: {'id': id, 'src': src, 'alt': alt, 'title': ?title},
};

/// The embed id of a node, for callers that need it.
String embedIdOf(DocumentNode node) => EmbedNodes.embedIdOf(node);

/// Serializes a node (for copy-as-Markdown of a block).
Delta deltaOfNode(DocumentNode node) =>
    const WonkyDeltaSerializer().serializeNode(node);

extension on Map<String, dynamic> {
  Map<String, dynamic>? get nullIfEmpty => isEmpty ? null : this;
}
