part of 'write_editor_commands.dart';

/// A container found in the document: its blocks `[first, last]` (mirror
/// indices) and its frame at [depth] (from its first line).
class ContainerRef {
  const ContainerRef(this.first, this.last, this.depth, this.frame);

  final int first;
  final int last;
  final int depth;
  final BoxFrame frame;
}

/// The Wonky Markdown commands of the editor (Write 11 §7.4, §7.5). Every
/// one builds one change Delta (one undo step).
extension WonkyMarkdownCommands on WriteEditorCommands {
  // ---------------------------------------------------------------------------
  // Helpers.

  /// The Delta offsets of every line end of [block] (code blocks have one
  /// per line).
  List<int> _lineEndsOf(BlockRef block) {
    final out = <int>[];
    var offset = block.start;
    for (final op in controller.mirror.entryAt(block.index).delta.operations) {
      final data = op.data;
      if (data is String) {
        for (var i = 0; i < data.length; i++) {
          if (data.codeUnitAt(i) == 0x0A) out.add(offset + i);
        }
      }
      offset += op.length!;
    }
    return out;
  }

  /// A change setting the `box` of every line of [blocks] to what [boxOfBlock]
  /// returns for its block (`null` or empty removes it).
  Delta _boxChange(
    Iterable<BlockRef> blocks,
    List<BoxFrame> Function(BlockRef block) boxOfBlock,
  ) {
    final patches = <int, List<BoxFrame>>{};
    for (final b in blocks) {
      final box = boxOfBlock(b);
      for (final end in _lineEndsOf(b)) {
        patches[end] = box;
      }
    }
    final change = Delta();
    var pos = 0;
    for (final end in patches.keys.toList()..sort()) {
      change
        ..retain(end - pos)
        ..retain(1, {DeltaKeys.box: Boxes.toValue(patches[end]!)});
      pos = end + 1;
    }
    return change;
  }

  /// The container at [depth] (innermost when `null`) of [nodeId]'s block,
  /// or of the caret's block.
  ContainerRef? containerAt({String? nodeId, int? depth}) {
    final block = _targetBlock(nodeId);
    if (block == null) return null;
    final frames = boxOf(block.node);
    if (frames.isEmpty) return null;
    final d = (depth ?? frames.length - 1).clamp(0, frames.length - 1);
    final mirror = controller.mirror;
    var first = block.index;
    while (first > 0 &&
        Boxes.sameAt(boxOf(mirror.blockAt(first - 1).node), frames, d)) {
      first--;
    }
    var last = block.index;
    while (last < mirror.nodeCount - 1 &&
        Boxes.sameAt(boxOf(mirror.blockAt(last + 1).node), frames, d)) {
      last++;
    }
    return ContainerRef(first, last, d, boxOf(mirror.blockAt(first).node)[d]);
  }

  Iterable<BlockRef> _blocksOf(ContainerRef c) sync* {
    for (var i = c.first; i <= c.last; i++) {
      yield controller.mirror.blockAt(i);
    }
  }

  BoxFrame _newFrame(BoxType type, {CalloutVariant? variant}) =>
      type == BoxType.callout
      ? BoxFrame.callout(
          id: controller.newEmbedId(),
          variant: variant ?? CalloutVariant.info,
        )
      : BoxFrame(id: controller.newEmbedId(), type: type);

  String _containerLabel(BoxType type) => switch (type) {
    BoxType.callout => _l.cmdInsertCallout,
    BoxType.details => _l.cmdInsertDetails,
    BoxType.card => _l.cmdInsertCard,
  };

  /// [fragment] with its Wonky elements in their GFM form (pasting into a
  /// GitHub Markdown document, Write 11 §3.2).
  Delta _gfmFragment(Delta fragment) {
    final hasNewline =
        fragment.isNotEmpty &&
        fragment.last.data is String &&
        (fragment.last.data! as String).endsWith('\n');
    final doc = hasNewline ? fragment : (Delta.from(fragment)..insert('\n'));
    final normalized = const WonkyDeltaNormalizer().normalize(doc).document;
    if (WonkyToGfm.inventory(normalized).isEmpty) return fragment;
    final converted = normalized.compose(WonkyToGfm.change(normalized));
    if (hasNewline) return converted;
    final length = DeltaUtils.documentLength(converted);
    return converted.slice(0, length - 1);
  }

  /// [fragment] (a pasted or inserted Delta) with new container ids and
  /// the [host] containers around every line (Write 11 §7.4).
  Delta _nestFragment(Delta fragment, List<BoxFrame> host) {
    final ids = <String, String>{};
    var touched = false;
    final out = Delta();
    for (final op in fragment.operations) {
      final data = op.data;
      if (data is! String || !data.contains('\n')) {
        out.push(op);
        continue;
      }
      var start = 0;
      while (true) {
        final nl = data.indexOf('\n', start);
        if (nl < 0) {
          if (start < data.length) {
            out.insert(data.substring(start), op.attributes);
          }
          break;
        }
        if (nl > start) out.insert(data.substring(start, nl), op.attributes);
        final own = Boxes.of(op.attributes);
        if (own.isEmpty && host.isEmpty) {
          out.insert('\n', op.attributes);
        } else {
          touched = true;
          final path = [
            ...host,
            for (final f in own)
              f.copyWith(id: ids[f.id] ??= controller.newEmbedId()),
          ];
          out.insert('\n', {
            ...?op.attributes,
            DeltaKeys.box: Boxes.toValue(
              path.length > BoxFrame.maxDepth
                  ? path.sublist(0, BoxFrame.maxDepth)
                  : path,
            ),
          });
        }
        start = nl + 1;
      }
    }
    return touched ? out : fragment;
  }

  // ---------------------------------------------------------------------------
  // Containers.

  /// Whether a container can be inserted at the selection.
  bool canInsertContainer() {
    final s = selection;
    if (!canEdit || s == null) return false;
    return _selectedBlocks().every(
      (b) => boxOf(b.node).length < BoxFrame.maxDepth,
    );
  }

  /// `write.insert.callout {variant}` / `write.insert.details` /
  /// `write.insert.card`: wraps the selected lines in a new container, turns
  /// an empty paragraph at the caret into one, or adds one after the caret's
  /// line (Write 11 §7.4). A new details gets a summary line (H3).
  bool insertContainer(BoxType type, {CalloutVariant? variant}) {
    final s = selection;
    if (!canInsertContainer() || s == null) return false;
    final frame = _newFrame(type, variant: variant);
    final mirror = controller.mirror;
    final blocks = _selectedBlocks();
    if (blocks.isEmpty) return false;
    final label = _containerLabel(type);
    List<BoxFrame> wrapped(BlockRef b) => [...boxOf(b.node), frame];
    final first = blocks.first;
    final node = first.node;
    final emptyParagraph =
        s.isCollapsed &&
        node is ParagraphNode &&
        node.text.isEmpty &&
        WriteEditorCommands.kindOf(first) == BlockKind.paragraph;

    if (!s.isCollapsed || emptyParagraph) {
      // Wrap the selected lines (or the empty paragraph).
      final change = _boxChange(blocks, wrapped);
      if (type == BoxType.details) {
        final summaryAttrs = {
          DeltaKeys.header: 3,
          DeltaKeys.box: Boxes.toValue(wrapped(first)),
        };
        if (emptyParagraph) {
          // The empty paragraph becomes the summary, a body line follows.
          final details = Delta()
            ..retain(first.lineEnd)
            ..retain(1, summaryAttrs)
            ..insert('\n', {DeltaKeys.box: Boxes.toValue(wrapped(first))});
          _apply(
            details,
            label,
            selectionAfter: DeltaSelection.collapsed(first.start),
          );
          return true;
        }
        final firstIsH3 =
            node is ParagraphNode &&
            headingLevelOf(node.getMetadataValue(NodeMetadata.blockType)) ==
                3 &&
            boxOf(node).isEmpty;
        if (!firstIsH3) {
          // A summary line before the wrapped lines.
          final withSummary = Delta()
            ..retain(first.start)
            ..insert(_l.editorDetailsSummaryPlaceholder)
            ..insert('\n', summaryAttrs);
          _apply(
            withSummary.compose(withSummary.transform(change, false)),
            label,
            selectionAfter: DeltaSelection(
              first.start,
              first.start + _l.editorDetailsSummaryPlaceholder.length,
            ),
          );
          return true;
        }
      }
      _apply(change, label, selectionAfter: s);
      return true;
    }

    // A caret in a non-empty line: a new container after the line.
    final at = first.start + first.length;
    final box = Boxes.toValue(wrapped(first));
    final change = Delta()..retain(at);
    if (type == BoxType.details) {
      change
        ..insert('\n', {DeltaKeys.header: 3, DeltaKeys.box: box})
        ..insert('\n', {DeltaKeys.box: box});
    } else {
      change.insert('\n', {DeltaKeys.box: box});
    }
    if (at >= mirror.length) {
      // Keep a plain line after the container at the document end.
      change.insert('\n');
    }
    _apply(change, label, selectionAfter: DeltaSelection.collapsed(at));
    return true;
  }

  /// `write.box.setVariant {variant}`: the type of the innermost callout at
  /// the caret (or of [nodeId]'s container at [depth]).
  bool setBoxVariant(CalloutVariant variant, {String? nodeId, int? depth}) {
    final c = containerAt(nodeId: nodeId, depth: depth);
    if (!canEdit || c == null || c.frame.type != BoxType.callout) return false;
    // Unchanged: nothing to do, which succeeds.
    if (c.frame.variant == variant) return true;
    return _replaceFrame(
      c,
      c.frame.copyWith(variant: variant),
      _l.cmdBoxSetVariant,
    );
  }

  /// `write.box.editTitle {title}`: an empty title removes it.
  bool setBoxTitle(String? title, {String? nodeId, int? depth}) {
    final c = containerAt(nodeId: nodeId, depth: depth);
    if (!canEdit || c == null || c.frame.type != BoxType.callout) return false;
    final t = BoxFrame.canonicalTitle(title);
    if (t == c.frame.title) return true;
    return _replaceFrame(
      c,
      t == null
          ? c.frame.copyWith(clearTitle: true)
          : c.frame.copyWith(title: t),
      _l.cmdBoxEditTitle,
    );
  }

  /// `write.box.convert {type}`: callout ⇄ details ⇄ card. A details whose
  /// first line isn't a level-3 heading gets one (a paragraph becomes it).
  bool convertBox(BoxType type, {String? nodeId, int? depth}) {
    final c = containerAt(nodeId: nodeId, depth: depth);
    if (!canEdit || c == null) return false;
    if (c.frame.type == type) return true;
    final frame = c.frame.copyWith(type: type);
    var change = _frameChange(c, frame);
    if (type == BoxType.details) {
      final first = controller.mirror.blockAt(c.first);
      final node = first.node;
      final level = node is ParagraphNode
          ? headingLevelOf(node.getMetadataValue(NodeMetadata.blockType))
          : null;
      final direct = boxOf(node).length == c.depth + 1;
      if (level != 3 &&
          direct &&
          WriteEditorCommands.kindOf(first) == BlockKind.paragraph) {
        change = change.compose(
          DeltaOps.format(first.lineEnd, 1, {DeltaKeys.header: 3}),
        );
      }
    }
    _apply(change, _l.cmdBoxConvert, selectionAfter: selection);
    return true;
  }

  Delta _frameChange(ContainerRef c, BoxFrame frame) =>
      _boxChange(_blocksOf(c), (b) => [...boxOf(b.node)]..[c.depth] = frame);

  bool _replaceFrame(ContainerRef c, BoxFrame frame, String label) {
    _apply(_frameChange(c, frame), label, selectionAfter: selection);
    return true;
  }

  /// `write.box.unwrap`: removes the container, keeps its content.
  bool unwrapBox({String? nodeId, int? depth}) {
    final c = containerAt(nodeId: nodeId, depth: depth);
    if (!canEdit || c == null) return false;
    final change = _boxChange(
      _blocksOf(c),
      (b) => [...boxOf(b.node)]..removeAt(c.depth),
    );
    _apply(change, _l.cmdBoxUnwrap, selectionAfter: selection);
    return true;
  }

  /// `write.box.delete`: deletes the container with its content.
  bool deleteBox({String? nodeId, int? depth}) {
    final c = containerAt(nodeId: nodeId, depth: depth);
    if (!canEdit || c == null) return false;
    final mirror = controller.mirror;
    final start = mirror.blockAt(c.first).start;
    final last = mirror.blockAt(c.last);
    final end = last.start + last.length;
    final change = Delta()..retain(start);
    if (start == 0 && end >= mirror.length) {
      // The whole document: one empty paragraph is left.
      change
        ..delete(end - start - 1)
        ..retain(1, {for (final k in DeltaKeys.blockKeys) k: null});
    } else {
      change.delete(end - start);
    }
    _apply(
      change,
      _l.cmdBoxDelete,
      selectionAfter: DeltaSelection.collapsed(
        start.clamp(0, mirror.length - (end - start) - 1).toInt(),
      ),
    );
    return true;
  }

  /// Leaves the innermost container at [nodeId] (Enter on its empty last
  /// line, Backspace at the start of its first line): pops one frame from
  /// the block's lines.
  bool leaveContainer(String nodeId) {
    final block = controller.mirror.blockOf(nodeId);
    if (!canEdit || block == null) return false;
    final frames = boxOf(block.node);
    if (frames.isEmpty) return false;
    final change = _boxChange([
      block,
    ], (_) => frames.sublist(0, frames.length - 1));
    _apply(change, _l.cmdBoxLeave, selectionAfter: selection);
    return true;
  }

  /// The innermost details container at [nodeId] or the caret.
  ContainerRef? detailsAt({String? nodeId}) {
    final block = _targetBlock(nodeId);
    if (block == null) return null;
    final frames = boxOf(block.node);
    for (var d = frames.length - 1; d >= 0; d--) {
      if (frames[d].type == BoxType.details) {
        return containerAt(nodeId: block.node.id, depth: d);
      }
    }
    return null;
  }

  /// `write.details.toggleCollapsed`: collapses or expands the details at
  /// [nodeId] or the caret (a view state, not undoable; Write 11 §7.3).
  /// Collapsing moves a caret in the body to the summary.
  bool toggleDetailsCollapsed({String? nodeId}) {
    final c = detailsAt(nodeId: nodeId);
    if (c == null) return false;
    final layout = controller.boxFrames;
    final collapse = !layout.isCollapsed(c.frame.id);
    layout.setCollapsed(c.frame.id, collapse);
    final s = selection;
    final mirror = controller.mirror;
    if (collapse && s != null) {
      final caret = mirror.blockAtOffset(s.end).index;
      if (caret > c.first && caret <= c.last) {
        final summaryEnd =
            mirror.startOfIndex(c.first) + mirror.entryAt(c.first).length - 1;
        controller.select(DeltaSelection.collapsed(summaryEnd));
      }
    }
    return true;
  }

  // ---------------------------------------------------------------------------
  // Grids.

  /// The grid at [nodeId], or at the selection.
  GridEmbed? gridOf({String? nodeId}) {
    final block = _embedBlock(nodeId, DeltaKeys.gridEmbed);
    if (block == null) return null;
    final value = block.node.getMetadataValue(WonkyNodeMetadata.embed);
    final embed = WonkyEmbed.tryParse(value);
    return embed is GridEmbed ? embed : null;
  }

  /// `write.insert.grid {columns?, bullets?}`: three empty items.
  String? insertGrid({
    int columns = 3,
    GridBullets bullets = GridBullets.check,
  }) {
    if (isSuggesting) return null;
    final grid = GridEmbed(
      id: controller.newEmbedId(),
      columns: GridEmbed.canonicalColumns(columns),
      bullets: bullets,
      items: const ['', '', ''],
    );
    if (_insertEmbeds([grid.toInsert()], _l.cmdInsertGrid) == null) {
      return null;
    }
    // The caret goes into the first item.
    controller.gridEditing?.activate(grid.id, 0);
    return grid.id;
  }

  // ---------------------------------------------------------------------------
  // YouTube videos.

  /// The YouTube video at [nodeId], or at the selection.
  YouTubeEmbed? youtubeOf({String? nodeId}) {
    final block = _embedBlock(nodeId, DeltaKeys.youtubeEmbed);
    if (block == null) return null;
    final value = block.node.getMetadataValue(WonkyNodeMetadata.embed);
    final embed = WonkyEmbed.tryParse(value);
    return embed is YouTubeEmbed ? embed : null;
  }

  /// `write.insert.youtube {url, title?}`: the video of a YouTube link (or
  /// id); `null` when [url] isn't one.
  String? insertYouTube(String url, {String? title}) {
    if (isSuggesting) return null;
    final parsed = YouTubeEmbed.parseUrl(url);
    if (parsed == null) return null;
    final video = YouTubeEmbed(
      id: controller.newEmbedId(),
      videoId: parsed.videoId,
      start: parsed.start,
      title: YouTubeEmbed.canonicalTitle(title),
    );
    return _insertEmbeds([video.toInsert()], _l.cmdInsertYouTube) == null
        ? null
        : video.id;
  }

  /// `write.youtube.edit {url?, title?}`: another link (video and start
  /// time) and/or title (empty removes it) for the video at [nodeId].
  bool setYouTube({String? nodeId, String? url, String? title}) {
    final current = youtubeOf(nodeId: nodeId);
    if (!canEdit || isSuggesting || current == null) return false;
    var next = current;
    if (url != null) {
      final parsed = YouTubeEmbed.parseUrl(url);
      if (parsed == null) return false;
      next = next.copyWith(
        videoId: parsed.videoId,
        start: parsed.start,
        clearStart: parsed.start == null,
      );
    }
    if (title != null) {
      final t = YouTubeEmbed.canonicalTitle(title);
      next = next.copyWith(title: t, clearTitle: t == null);
    }
    if (next == current) return true;
    final block = _embedBlock(current.id, DeltaKeys.youtubeEmbed)!;
    return _replaceEmbed(block, next.toInsert(), _l.cmdYouTubeEdit) != null;
  }

  /// Replaces the grid at [nodeId] with [grid] (same id).
  bool replaceGrid(GridEmbed grid, {String? nodeId, String? label}) {
    final block = _embedBlock(nodeId ?? grid.id, DeltaKeys.gridEmbed);
    if (!canEdit || isSuggesting || block == null) return false;
    final current = gridOf(nodeId: block.id);
    final next = grid.copyWith(
      id: current?.id ?? grid.id,
      items: grid.items.isEmpty ? const [''] : grid.items,
    );
    if (next == current) return true;
    return _replaceEmbed(block, next.toInsert(), label ?? _l.undoEditGrid) !=
        null;
  }

  /// `write.grid.setColumns {columns}`.
  bool setGridColumns(int columns, {String? nodeId}) {
    final grid = gridOf(nodeId: nodeId);
    if (grid == null) return false;
    return replaceGrid(
      grid.copyWith(columns: GridEmbed.canonicalColumns(columns)),
      nodeId: nodeId,
      label: _l.cmdGridSetColumns,
    );
  }

  /// `write.grid.setBullets {bullets}`.
  bool setGridBullets(GridBullets bullets, {String? nodeId}) {
    final grid = gridOf(nodeId: nodeId);
    if (grid == null) return false;
    return replaceGrid(
      grid.copyWith(bullets: bullets),
      nodeId: nodeId,
      label: _l.cmdGridSetBullets,
    );
  }

  /// `write.grid.addItem {index?}`: an empty item at [index] (default: the
  /// end).
  bool addGridItem({String? nodeId, int? index}) {
    final grid = gridOf(nodeId: nodeId);
    if (grid == null || grid.items.length >= GridEmbed.maxItems) return false;
    final items = [...grid.items]
      ..insert((index ?? grid.items.length).clamp(0, grid.items.length), '');
    return replaceGrid(
      grid.copyWith(items: items),
      nodeId: nodeId,
      label: _l.cmdGridAddItem,
    );
  }

  /// `write.grid.removeItem {index}`.
  bool removeGridItem(int index, {String? nodeId}) {
    final grid = gridOf(nodeId: nodeId);
    if (grid == null || index < 0 || index >= grid.items.length) return false;
    if (grid.items.length == 1) {
      return deleteBlock(nodeId: nodeId ?? grid.id);
    }
    final items = [...grid.items]..removeAt(index);
    return replaceGrid(
      grid.copyWith(items: items),
      nodeId: nodeId,
      label: _l.cmdGridRemoveItem,
    );
  }

  // ---------------------------------------------------------------------------
  // Link styles and chips.

  /// The link style at the caret or selection start (`plain` without one),
  /// or `null` when not on a link.
  String? linkStyleAt() {
    final s = selection;
    if (s == null) return null;
    final link =
        linkAt(s.start) ?? (s.isCollapsed ? null : linkAt(s.start + 1));
    if (link == null) return null;
    final block = controller.mirror.blockAtOffset(link.start);
    final node = block.node;
    if (node is! TextNode) return 'plain';
    final style = node.text
        .getAllAttributionsAt(link.start - block.start)
        .whereType<LinkStyleAttribution>()
        .firstOrNull;
    return style?.style ?? 'plain';
  }

  /// `write.link.setStyle {style}`: `plain`, `arrow`, `button` or
  /// `buttonSecondary` on the link at the caret, or on the links in the
  /// selection. Returns false when there is no link (the caller opens the
  /// link popover with the style preset).
  bool setLinkStyle(String style) {
    final s = selection;
    if (!canEdit || s == null) return false;
    final value = style == 'plain' ? null : style;
    if (value != null && !WonkyAttr.linkStyles.contains(value)) return false;
    final attributes = <String, dynamic>{
      DeltaKeys.linkStyle: value,
      // A styled link's label is plain text (Write 11 §2.1).
      if (value != null) ...{
        DeltaKeys.bold: null,
        DeltaKeys.italic: null,
        DeltaKeys.strike: null,
        DeltaKeys.code: null,
      },
    };
    Delta change;
    if (s.isCollapsed) {
      final link = linkAt(s.start);
      if (link == null || link.mentionUuid != null) return false;
      change = DeltaOps.format(link.start, link.end - link.start, attributes);
    } else {
      change = FormatChanges.format(
        controller.mirror,
        s.start,
        s.end,
        attributes,
        eligible: (piece, block) =>
            !block.isCode &&
            FormatChanges.isInlineText(piece) &&
            piece.attributes?[DeltaKeys.link] is String &&
            piece.attributes?[DeltaKeys.mention] == null,
      );
    }
    if (change.isEmpty) return false;
    _apply(change, _l.cmdLinkSetStyle, selectionAfter: s);
    return true;
  }

  /// Whether the selection (or the character before the caret) is a chip.
  bool isChipActive() {
    final s = selection;
    if (s == null) return false;
    final block = controller.mirror.blockAtOffset(s.start);
    final node = block.node;
    if (node is! TextNode) return false;
    final local = (s.isCollapsed ? s.start - 1 : s.start) - block.start;
    if (local < 0 || local >= node.text.length) return false;
    return node.text
        .getAllAttributionsAt(local)
        .any((a) => a is ChipAttribution);
  }

  /// `write.format.chip`: toggles chips on the selection; at a caret inserts
  /// a chip with a placeholder label, selected.
  bool toggleChip() {
    final s = selection;
    if (!canEdit || s == null || _caretInCode) return false;
    if (s.isCollapsed) {
      final label = _l.editorChipPlaceholder;
      final change = Delta()
        ..retain(s.start)
        ..insert(label, {DeltaKeys.chip: true});
      _apply(
        change,
        _l.cmdFormatChip,
        selectionAfter: DeltaSelection(s.start, s.start + label.length),
      );
      return true;
    }
    final active = isChipActive();
    final change = FormatChanges.format(
      controller.mirror,
      s.start,
      s.end,
      active
          ? {DeltaKeys.chip: null}
          : {
              DeltaKeys.chip: true,
              for (final k in DeltaKeys.inlineKeys)
                if (k != DeltaKeys.chip) k: null,
            },
      eligible: (piece, block) =>
          !block.isCode && FormatChanges.isInlineText(piece),
    );
    if (change.isEmpty) return false;
    _apply(change, _l.cmdFormatChip, selectionAfter: s);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Numbered headings.

  /// The number the next step heading of level [level] at [index] gets: the
  /// previous step of that level in its section + 1, else 1. A section
  /// starts after the last heading of a higher level (Write 11 §7.4).
  int nextStepNumber(int index, int level) {
    final mirror = controller.mirror;
    for (var i = index - 1; i >= 0; i--) {
      final node = mirror.blockAt(i).node;
      if (node is! ParagraphNode) continue;
      final l = headingLevelOf(node.getMetadataValue(NodeMetadata.blockType));
      if (l == null) continue;
      if (l < level) return 1;
      if (l == level) {
        final step = stepOf(node);
        if (step != null) return step + 1;
      }
    }
    return 1;
  }

  /// Whether the caret's line is a numbered heading.
  bool isStepActive() {
    final s = selection;
    if (s == null) return false;
    return stepOf(controller.mirror.blockAtOffset(s.start).node) != null;
  }

  /// `write.heading.toggleStep`: numbers the selected headings (a paragraph
  /// becomes a level-3 heading) or removes their numbers.
  bool toggleStep() {
    if (!canEdit) return false;
    final blocks = _selectedBlocks()
        .where((b) => b.node is ParagraphNode && !b.isCode)
        .toList();
    if (blocks.isEmpty) return false;
    final remove = blocks.every((b) => stepOf(b.node) != null);
    final change = Delta();
    var pos = 0;
    final assigned = <int, int>{};
    for (final b in blocks) {
      final node = b.node as ParagraphNode;
      final blockType = node.getMetadataValue(NodeMetadata.blockType);
      var level = headingLevelOf(blockType);
      final attrs = <String, dynamic>{};
      if (remove) {
        attrs[DeltaKeys.step] = null;
      } else {
        if (level != 2 && level != 3) {
          if (blockType != paragraphAttribution && level == null) continue;
          level = 3;
          attrs[DeltaKeys.header] = 3;
          attrs[DeltaKeys.blockquote] = null;
        }
        // Earlier headings of this command count as numbered.
        var n = nextStepNumber(b.index, level!);
        for (final e in assigned.entries) {
          if (e.key < b.index) n = e.value + 1;
        }
        assigned[b.index] = n;
        attrs[DeltaKeys.step] = n;
      }
      change
        ..retain(b.lineEnd - pos)
        ..retain(1, attrs);
      pos = b.lineEnd + 1;
    }
    if (change.isEmpty) return false;
    _apply(change, _l.cmdHeadingToggleStep, selectionAfter: selection);
    return true;
  }

  /// `write.heading.setStepNumber {n}` on [nodeId] or the caret's heading.
  bool setStepNumber(int n, {String? nodeId}) {
    final block = _targetBlock(nodeId);
    if (!canEdit || block == null || stepOf(block.node) == null) return false;
    final value = n.clamp(0, WonkyAttr.maxStep).toInt();
    if (stepOf(block.node) == value) return true;
    _apply(
      DeltaOps.format(block.lineEnd, 1, {DeltaKeys.step: value}),
      _l.cmdHeadingSetStepNumber,
      selectionAfter: selection,
    );
    return true;
  }

  /// `write.heading.renumberSteps`: renumbers the numbered headings of the
  /// caret's section from 1, per level.
  bool renumberSteps() {
    final s = selection;
    if (!canEdit || s == null) return false;
    final mirror = controller.mirror;
    final here = mirror.blockAtOffset(s.start);
    final hereLevel = () {
      final node = here.node;
      if (node is! ParagraphNode) return 3;
      return headingLevelOf(node.getMetadataValue(NodeMetadata.blockType)) ?? 3;
    }();
    int? levelAt(int i) {
      final node = mirror.blockAt(i).node;
      return node is ParagraphNode
          ? headingLevelOf(node.getMetadataValue(NodeMetadata.blockType))
          : null;
    }

    // The section: from after the last heading above the steps' level.
    var start = here.index;
    while (start > 0) {
      final l = levelAt(start - 1);
      if (l != null &&
          l < hereLevel &&
          stepOf(mirror.blockAt(start - 1).node) == null) {
        break;
      }
      start--;
    }
    final change = Delta();
    var pos = 0;
    final counters = <int, int>{};
    for (var i = start; i < mirror.nodeCount; i++) {
      final l = levelAt(i);
      final block = mirror.blockAt(i);
      if (l != null &&
          l < hereLevel &&
          stepOf(block.node) == null &&
          i > start) {
        break;
      }
      if (l == null || stepOf(block.node) == null) continue;
      counters.removeWhere((level, _) => level > l);
      final n = (counters[l] ?? 0) + 1;
      counters[l] = n;
      if (stepOf(block.node) == n) continue;
      change
        ..retain(block.lineEnd - pos)
        ..retain(1, {DeltaKeys.step: n});
      pos = block.lineEnd + 1;
    }
    if (change.isEmpty) return false;
    _apply(change, _l.cmdHeadingRenumberSteps, selectionAfter: s);
    return true;
  }
}
