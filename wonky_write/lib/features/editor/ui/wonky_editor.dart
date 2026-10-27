import 'dart:async';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shad/shad.dart' show ShadTheme;
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show SuggestionView;

import '../../../l10n/write_l10n.dart';
import '../applier/delta_applier.dart';
import '../commands/write_editor_commands.dart';
import '../components/box_frames.dart';
import '../components/cell_layout.dart';
import '../components/editor_services.dart';
import '../components/grid_component.dart';
import '../components/youtube_component.dart';
import '../components/inline_pills.dart';
import '../components/wonky_components.dart';
import '../controller/editor_types.dart';
import '../controller/write_editor_controller.dart';
import '../dnd/drop_indicator.dart';
import 'package:wonky_app/platform.dart';
import '../dnd/text_drag.dart';
import '../keyboard/editor_keyboard.dart';
import '../attributions/wonky_attributions.dart';
import '../layers/document_geometry.dart';
import '../layers/editor_layers.dart';
import '../mapping/delta_document_mapper.dart';
import '../model/document_queries.dart';
import '../pagination/pagination.dart';
import '../paste/clipboard_codec.dart';
import '../paste/editor_clipboard.dart';
import '../plugins/slash_items.dart';
import '../plugins/trigger_queries.dart';
import '../popovers/editor_popovers.dart';
import '../reactions/pill_boundary.dart';
import '../setup/editor_factory.dart' show selectionGuard;
import '../styles/editor_theme.dart';
import '../styles/style_phases.dart';
import '../styles/write_stylesheet.dart';

/// The Write document editor surface (Write 04): `SuperEditor` (Editing,
/// Suggesting) or `SuperReader` (Viewing, suggestion previews) over the
/// [WriteEditorController]'s document, with the Wonky stylesheet, component
/// builders, layers (find matches, remote cursors and selections, block
/// handle), the slash menu, the mention picker, the link hover card, Pages /
/// Pageless layout with pagination, and zoom.
///
/// Chrome (menubar, toolbar, panels) is built by the screen around it; every
/// action goes through [commands] / [controller].
class WonkyEditor extends StatefulWidget {
  const WonkyEditor({
    super.key,
    required this.controller,
    this.commands,
    this.clipboard,
    this.theme,
    this.documentTitle,
    this.imageServices = const NetworkImageServices(),
    this.blockCallbacks = const EditorBlockCallbacks(),
    this.shortcutCallbacks,
    this.keymap,
    this.builtInShortcuts = true,
    this.slashHost = const SlashHost(),
    this.mentionCandidates,
    this.onOpenLink,
    this.onEditLink,
    this.autofocus = false,
    this.scrollController,
    this.hint,
    this.extraStylePhases = const [],
    this.emojiSuggestions,
    this.onDropFiles,
    this.externalDrops,
    this.endInset = 0,
    this.compactPadding,
  });

  final WriteEditorController controller;

  /// The command layer (created from [controller] when omitted).
  final WriteEditorCommands? commands;

  /// Clipboard actions (created when omitted).
  final EditorClipboard? clipboard;

  /// Document theme; defaults to Wonky Default for the ambient brightness.
  final EditorTheme? theme;

  /// Semantics label of the editor (the document title; null: "Document").
  final String? documentTitle;

  final EditorImageServices imageServices;
  final EditorBlockCallbacks blockCallbacks;

  /// Shell actions behind shortcuts (undo/redo, link popover, find…). When
  /// omitted, copy/cut/paste use [clipboard] and the rest is not bound.
  final EditorShortcutCallbacks? shortcutCallbacks;

  /// The shell keymap (`KeymapService`, scope `editor`), tried first.
  final EditorKeyHandler? keymap;

  /// Whether the editor's own default shortcuts apply (disable when the shell
  /// keymap binds every editor command).
  final bool builtInShortcuts;

  final SlashHost slashHost;

  /// People to mention for a query (sharing + contacts + search); `null`
  /// disables the mention picker.
  final Future<List<MentionCandidate>> Function(String query)?
  mentionCandidates;

  /// Opens a link (internal links navigate; external links show the shell's
  /// "Open external link?" confirm). Mod+click in Editing, click in Viewing.
  final void Function(String url)? onOpenLink;

  /// Opens the link popover for the link at the caret (`write.link.edit`).
  final VoidCallback? onEditLink;

  final bool autofocus;
  final ScrollController? scrollController;

  /// Placeholder of an empty document (null: the editor's default).
  final String? hint;

  /// More style phases (e.g. the spellcheck underlines, Write 04 §28.2).
  final List<SingleColumnLayoutStylePhase> extraStylePhases;

  /// Emoji for a `:query` (Write 04 §20.1); `null` disables the trigger.
  final EmojiSuggester? emojiSuggestions;

  /// Files dropped from the OS before the block at `blockIndex` (Write 04
  /// §24): the host uploads images and imports documents. Text and HTML
  /// drops are pasted by the editor itself.
  final void Function(List<DroppedFile> files, int blockIndex)? onDropFiles;

  /// Pages mode: width at the end of the canvas that something is drawn over
  /// (the comment margin). The page centers in the rest — moving left, down
  /// to an 8 px gutter — so it stays clear of it when there is room.
  final double endInset;

  /// Left and right padding around the text instead of the page margins
  /// (Pages; the page then fills the width) or the pageless padding, where
  /// it is also the space above the first and below the last block: the
  /// mobile layout's (suite 02 §6.1, T-12, T-1). Null: the document's own.
  /// Only the rendering changes, not the page setup.
  final double? compactPadding;

  /// Source of OS drops (defaults to the platform's; tests inject one).
  final ExternalDropSource? externalDrops;

  @override
  State<WonkyEditor> createState() => WonkyEditorState();
}

class WonkyEditorState extends State<WonkyEditor> {
  late WriteEditorCommands _commands;
  late EditorClipboard _clipboard;
  late TriggerQueryTracker _triggers;
  late final WriteStylesheetBuilder _styles = WriteStylesheetBuilder();
  final _pagination = PaginationController();
  late final PaginationStylePhase _paginationPhase = PaginationStylePhase(
    _pagination,
  );
  final _codeHighlight = CodeHighlightStylePhase();
  BoxFrameLayout get _boxLayout => controller.boxFrames;
  late final _boxPhase = BoxStylePhase(
    _boxLayout,
    wonkyStyle: (widget.theme ?? EditorTheme.fallback(Brightness.light)).wonky,
    zoom: 1,
  );
  final _direction = TextDirectionStylePhase();
  // Table cells and grid items laid out side by side (Write 12 §3.2), one
  // layout per document shown (the document, a suggestion preview).
  WriteCellLayout? _mainCells;
  WriteCellLayout? _previewCells;
  late final _cellPhase = CellStylePhase(_cellsFor(controller.document));
  WriteCellLayout? _cellsInBuild;
  final _pillSpacing = PillSpacingStylePhase();
  final _slashPicker = PickerController<SlashItem>();
  final _mentionPicker = PickerController<MentionCandidate>();
  final _emojiPicker = PickerController<EmojiSuggestion>();
  final _dropIndicator = DropIndicator();
  final _outerFocus = FocusNode(
    debugLabel: 'write-editor-host',
    canRequestFocus: false,
    skipTraversal: true,
  );
  late TextDragController _textDrag;
  ExternalDropSource? _drops;

  /// The slash menu items in the UI language (set in [didChangeDependencies]).
  List<SlashItem> _slashItems = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slashItems = defaultSlashItems(writeL10n(context));
  }

  final _linkCard = ValueNotifier<LinkRun?>(null);
  late ScrollController _scrollController;
  Timer? _hoverTimer;
  Timer? _previewTimer;
  int _mentionRequest = 0;

  // Read-only preview document (Viewing / suggestion previews).
  Editor? _previewEditor;

  /// Layout of the read-only preview document (Viewing mode shows the
  /// document without suggestions), so its pages are measured too.
  final _previewLayoutKey = GlobalKey();
  SuggestionPreviewMode? _previewMode;

  WriteEditorController get controller => widget.controller;

  /// The command layer used by this editor.
  WriteEditorCommands get commands => _commands;

  /// The clipboard actions used by this editor.
  EditorClipboard get clipboard => _clipboard;

  /// The pagination state (page count for the status bar).
  PaginationController get pagination => _pagination;

  /// Drag and drop of the selection (Write 04 §24).
  TextDragController get textDrag => _textDrag;

  /// The current drop indicator.
  DropIndicator get dropIndicator => _dropIndicator;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    // The card is drawn with the other popovers: redraw when it changes
    // without a controller change (→ out of a button, the hover timer).
    _linkCard.addListener(_onLinkCardChanged);
    _attach();
  }

  void _onLinkCardChanged() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _attach() {
    _commands = widget.commands ?? WriteEditorCommands(controller);
    _clipboard =
        widget.clipboard ??
        EditorClipboard(controller: controller, commands: _commands);
    _triggers = TriggerQueryTracker(controller)
      ..emojiEnabled = widget.emojiSuggestions != null;
    _triggers.slash.addListener(_onSlash);
    _triggers.mention.addListener(_onMention);
    _triggers.emoji.addListener(_onEmoji);
    _textDrag = TextDragController(
      controller: controller,
      commands: _commands,
      indicator: _dropIndicator,
    );
    controller.addListener(_onControllerChanged);
    controller.view.addListener(_onViewChanged);
    controller.pillBoundary.addListener(_updateLinkCardFromCaret);
    controller.notices.listen(_onNotice);
    _drops = widget.externalDrops ?? ExternalDropSource.platform();
    _drops!.attach(
      onOver: _onExternalOver,
      onLeave: _dropIndicator.clear,
      onDrop: _onExternalDrop,
    );
  }

  void _detach(WriteEditorController old) {
    old.removeListener(_onControllerChanged);
    old.view.removeListener(_onViewChanged);
    old.pillBoundary.removeListener(_updateLinkCardFromCaret);
    _triggers.slash.removeListener(_onSlash);
    _triggers.mention.removeListener(_onMention);
    _triggers.emoji.removeListener(_onEmoji);
    _triggers.dispose();
    _textDrag.cancel();
    _drops?.detach();
  }

  @override
  void didUpdateWidget(WonkyEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detach(oldWidget.controller);
      _boxPhase.layout = _boxLayout;
      _attach();
    }
  }

  /// The cell layout of [document] (made when the document changes).
  WriteCellLayout _cellsFor(Document document) {
    final main = identical(document, controller.document);
    var cells = main ? _mainCells : _previewCells;
    if (cells == null || !identical(cells.slots.document, document)) {
      cells?.slots.dispose();
      cells?.dispose();
      cells = WriteCellLayout(CellSlots(document), pagination: _pagination);
      if (main) {
        _mainCells = cells;
      } else {
        _previewCells = cells;
      }
    }
    return cells;
  }

  @override
  void dispose() {
    for (final cells in [_mainCells, _previewCells]) {
      cells?.slots.dispose();
      cells?.dispose();
    }
    _detach(controller);
    _hoverTimer?.cancel();
    _previewTimer?.cancel();
    _paginationPhase.close();
    _codeHighlight.close();
    _pagination.dispose();
    _slashPicker.dispose();
    _mentionPicker.dispose();
    _emojiPicker.dispose();
    _dropIndicator.dispose();
    _outerFocus.dispose();
    _linkCard.dispose();
    if (widget.scrollController == null) _scrollController.dispose();
    super.dispose();
  }

  void _onNotice(EditorNotice notice) {
    if (!mounted) return;
    if (notice.kind == EditorNoticeKind.announcement &&
        notice.message != null) {
      final direction = Directionality.maybeOf(context) ?? TextDirection.ltr;
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          notice.message!,
          direction,
        ),
      );
    }
  }

  void _onControllerChanged() {
    final s = controller.selection;
    if (s != null) _revealAt(s.end);
    _updateLinkCardFromCaret();
    if (_previewMode != null) _schedulePreviewRebuild();
    if (mounted) setState(() {});
  }

  void _onViewChanged() {
    final view = controller.view;
    final active = view.activeFindMatch;
    if (active != null) _revealAt(view.findMatches[active].start);
    if (mounted) setState(() {});
  }

  /// Opens collapsed details around Delta [offset] (Write 11 §7.2).
  void _revealAt(int offset) {
    final mirror = controller.mirror;
    if (offset < 0 || offset >= mirror.length) return;
    _boxLayout.reveal(controller.document, mirror.blockAtOffset(offset).node);
  }

  // ---------------------------------------------------------------------------
  // Slash menu and mentions.

  void _onSlash() {
    final query = _triggers.slash.value;
    _slashPicker.items = query == null
        ? const []
        : filterSlashItems(
            [
              for (final i in _slashItems)
                if (slashItemAvailable(i, widget.slashHost)) i,
            ],
            query.query,
            mode: controller.mode,
          ).take(10).toList();
    if (mounted) setState(() {});
  }

  Future<void> _onMention() async {
    final query = _triggers.mention.value;
    final provider = widget.mentionCandidates;
    if (query == null || provider == null) {
      _mentionPicker.items = const [];
      if (mounted) setState(() {});
      return;
    }
    final request = ++_mentionRequest;
    final candidates = await provider(query.query);
    if (!mounted || request != _mentionRequest) return;
    _mentionPicker.items = candidates.take(8).toList();
    setState(() {});
  }

  void _onEmoji() {
    final query = _triggers.emoji.value;
    final suggest = widget.emojiSuggestions;
    _emojiPicker.items = query == null || suggest == null
        ? const []
        : suggest(query.query).take(8).toList();
    if (mounted) setState(() {});
  }

  void _chooseEmoji(EmojiSuggestion item) {
    final query = _triggers.emoji.value;
    if (query == null) return;
    _commands.replaceRangeWithTextLabelled(
      query.start,
      query.end - query.start,
      item.emoji,
      label: writeL10n(context).undoInsertEmoji,
    );
    _triggers.dismiss();
  }

  void _chooseSlash(SlashItem item) {
    final query = _triggers.slash.value;
    if (query == null) return;
    runSlashItem(
      controller,
      _commands,
      _triggers,
      query,
      item,
      widget.slashHost,
    );
    _triggers.dismiss();
  }

  void _chooseMention(MentionCandidate person) {
    final query = _triggers.mention.value;
    if (query == null) return;
    _commands.insertMention(
      userUuid: person.userUuid,
      displayName: person.displayName,
      email: person.email,
      replaceStart: query.start,
      replaceEnd: query.end,
    );
    _triggers.dismiss();
  }

  bool _popoverKeys(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _textDrag.isDragging) {
      _textDrag.cancel();
      return true;
    }
    if (_triggers.emoji.value != null && _emojiPicker.items.isNotEmpty) {
      if (_emojiPicker.handleKey(
        event,
        onChoose: _chooseEmoji,
        onClose: _triggers.dismiss,
      )) {
        return true;
      }
    }
    if (_triggers.slash.value != null && _slashPicker.items.isNotEmpty) {
      return _slashPicker.handleKey(
        event,
        onChoose: _chooseSlash,
        onClose: _triggers.dismiss,
      );
    }
    if (_triggers.mention.value != null && widget.mentionCandidates != null) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.space &&
          _mentionPicker.items.isEmpty) {
        _triggers.dismiss();
        return false;
      }
      return _mentionPicker.handleKey(
        event,
        onChoose: _chooseMention,
        onClose: _triggers.dismiss,
      );
    }
    if (_linkCard.value != null &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _linkCard.value = null;
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Drops from other applications (§24).

  bool get _acceptsDrops =>
      mounted &&
      controller.mode != EditorMode.viewing &&
      _effectivePreview == SuggestionPreviewMode.show &&
      _commands.canEdit;

  /// Whether [global] is over this editor.
  bool _isOverEditor(Offset global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) return false;
    return (box.localToGlobal(Offset.zero) & box.size).contains(global);
  }

  bool _onExternalOver(Offset global, ExternalDragKind kind) {
    if (!_acceptsDrops || !_isOverEditor(global)) {
      _dropIndicator.clear();
      return false;
    }
    final layout = controller.documentLayout;
    if (layout == null) return false;
    final local = layout.getDocumentOffsetFromAncestorOffset(global);
    if (kind == ExternalDragKind.files) {
      if (widget.onDropFiles == null) return false;
      final index = DropGeometry.blockIndexAt(layout, controller, local);
      _dropIndicator.value = index == null ? null : BlockDropSpot(index);
      return index != null;
    }
    final offset = DropGeometry.caretOffsetAt(layout, controller, local);
    _dropIndicator.value = offset == null ? null : CaretDropSpot(offset);
    return offset != null;
  }

  void _onExternalDrop(ExternalDrop drop) {
    final spot = _dropIndicator.value;
    _dropIndicator.clear();
    if (!_acceptsDrops || !_isOverEditor(drop.globalPosition)) return;
    final layout = controller.documentLayout;
    if (layout == null) return;
    final local = layout.getDocumentOffsetFromAncestorOffset(
      drop.globalPosition,
    );
    if (drop.hasFiles) {
      final index = spot is BlockDropSpot
          ? spot.index
          : DropGeometry.blockIndexAt(layout, controller, local);
      if (index != null) widget.onDropFiles?.call(drop.files, index);
      return;
    }
    final offset = spot is CaretDropSpot
        ? spot.offset
        : DropGeometry.caretOffsetAt(layout, controller, local);
    if (offset == null) return;
    final plain = drop.plainText ?? '';
    if (plain.isEmpty && drop.html == null) return;
    controller.select(DeltaSelection.collapsed(offset));
    _clipboard.pasteContent(
      ClipboardContent(plainText: plain, html: drop.html),
    );
    controller.focusNode.requestFocus();
  }

  // ---------------------------------------------------------------------------
  // Links.

  void _updateLinkCardFromCaret() {
    final selection = controller.selection;
    if (selection == null || !selection.isCollapsed) {
      if (_linkCard.value != null && _hoverTimer == null) {
        _linkCard.value = null;
      }
      return;
    }
    final run = _commands.linkAt(selection.start);
    final inside =
        run != null &&
        (selection.start > run.start && selection.start < run.end ||
            selection.start == run.end && _insideStyledLinkEnd());
    _linkCard.value = inside ? run : null;
  }

  /// The caret at the end of a button or arrow link, still inside it
  /// (typing extends it; Write 11 §7.4): the card shows there too, so a
  /// one-character button can be edited.
  bool _insideStyledLinkEnd() {
    final extent = controller.composer.selection?.extent;
    final p = extent?.nodePosition;
    final node = extent == null
        ? null
        : controller.document.getNodeById(extent.nodeId);
    if (extent == null || p is! TextNodePosition || node is! TextNode) {
      return false;
    }
    return !controller.pillBoundary.isOutsideAt(extent) &&
        PillBoundary.endingAt(
          node.text,
          p.offset,
        ).any((a) => a is LinkStyleAttribution);
  }

  void _onHover(PointerHoverEvent event) {
    final layout = controller.documentLayout;
    if (layout == null) return;
    final local = layout.getDocumentOffsetFromAncestorOffset(event.position);
    final position = layout.getDocumentPositionAtOffset(local) == null
        ? null
        : DocumentGeometry.characterAt(layout, local);
    final offset = position == null
        ? null
        : controller.mirror.offsetOf(position);
    final run = offset == null ? null : _commands.linkAt(offset);
    _hoverTimer?.cancel();
    if (run == null) {
      _hoverTimer = Timer(const Duration(milliseconds: 200), () {
        _hoverTimer = null;
        _updateLinkCardFromCaret();
      });
      return;
    }
    _hoverTimer = Timer(const Duration(milliseconds: 400), () {
      _hoverTimer = null;
      _linkCard.value = run;
    });
  }

  // ---------------------------------------------------------------------------
  // Read-only previews (§31).

  SuggestionPreviewMode get _effectivePreview =>
      controller.view.suggestionPreview ??
      (controller.mode == EditorMode.viewing
          ? SuggestionPreviewMode.original
          : SuggestionPreviewMode.show);

  void _schedulePreviewRebuild() {
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(_rebuildPreview);
    });
  }

  void _rebuildPreview() {
    final mode = _previewMode;
    if (mode == null) {
      _previewEditor = null;
      return;
    }
    final delta = controller.delta;
    final Delta viewed = mode == SuggestionPreviewMode.accepted
        ? SuggestionView.accepted(delta)
        : SuggestionView.original(delta);
    final document = const DeltaDocumentMapper().documentFromDelta(viewed);
    // No text selection where the controller has none (mobile, T-1).
    _previewEditor = Editor(
      editables: {
        Editor.documentKey: document,
        Editor.composerKey: MutableDocumentComposer(),
      },
      requestHandlers: [
        selectionGuard(() => controller.selectable),
        ...defaultRequestHandlers.cast<EditRequestHandler>(),
      ],
      reactionPipeline: List.from(defaultEditorReactions),
      isHistoryEnabled: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Build.

  EditorTheme _theme(BuildContext context) {
    final explicit = widget.theme;
    if (explicit != null) return explicit;
    final brightness =
        ShadTheme.maybeOf(context)?.brightness ?? Theme.of(context).brightness;
    return EditorTheme.fallback(brightness);
  }

  @override
  Widget build(BuildContext context) {
    // Task checkboxes and the text-selection widgets need a Material
    // ancestor; read-only hosts (history, theme preview) have none.
    if (Material.maybeOf(context) == null) {
      return Material(
        type: MaterialType.transparency,
        child: Builder(builder: _build),
      );
    }
    return _build(context);
  }

  Widget _build(BuildContext context) {
    final theme = _theme(context);
    final view = controller.view;
    final pages = view.layout == LayoutMode.pages;
    final zoom = view.zoom;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    _pagination.configure(view.pageSetup, zoom * textScale);

    final preview = _effectivePreview;
    final readOnly =
        controller.mode == EditorMode.viewing ||
        preview != SuggestionPreviewMode.show;
    final previewMode = preview == SuggestionPreviewMode.show ? null : preview;
    if (previewMode != _previewMode) {
      _previewMode = previewMode;
      _rebuildPreview();
    }

    final style = _styles.build(
      theme: theme,
      zoom: zoom,
      textScale: textScale,
      layout: view.layout,
      contentWidth: view.pageSetup.contentWidth,
      comments: view.comments,
      selfUserUuid: controller.userUuid,
      focused: controller.focusNode.hasFocus,
    );
    final compact = widget.compactPadding;
    var stylesheet = pages
        ? _paddedStylesheet(
            style.stylesheet,
            _compact(view.pageSetup.margins * (zoom * textScale), compact),
          )
        : compact == null
        ? style.stylesheet
        // Pageless: [compact] also above the first and below the last block.
        : _paddedStylesheet(
            style.stylesheet,
            (style.stylesheet.documentPadding ?? EdgeInsets.zero).copyWith(
              left: compact,
              right: compact,
              top: compact,
            ),
            lastBlockBottom: compact,
          );

    // The SuperEditor/SuperReader widget is reused while its inputs are the
    // same: a new instance rebuilds super_editor's layout, which walks every
    // component of the document (Write 04 §36). This build also runs on
    // every controller notify (typing, caret moves) for the popovers.
    final memoKey = (
      widget,
      theme,
      style,
      stylesheet,
      readOnly,
      previewMode,
      _previewEditor,
      pages,
      pages ? _pagination.contentHeight : null,
      controller.document.nodeCount == 1,
      // The hint text (a locale switch).
      writeL10n(context),
    );
    var editorWidget = _editorMemo?.key == memoKey ? _editorMemo?.widget : null;
    if (editorWidget == null) {
      editorWidget = readOnly
          ? _buildReader(theme, style, stylesheet, previewMode)
          : _buildEditor(theme, style, stylesheet);
      _editorMemo = (key: memoKey, widget: editorWidget);
    }

    Widget surface = MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      // Material ancestor for the task checkboxes and text-selection
      // widgets: hosts (the editor screen, version history) are shad-only.
      child: Material(type: MaterialType.transparency, child: editorWidget),
    );

    if (pages) {
      final fullWidth = view.pageSetup.size.width * zoom * textScale;
      final page = surface;
      surface = ColoredBox(
        color: theme.canvasColor,
        child: LayoutBuilder(
          builder: (context, c) {
            // Compact: the page fills the width (its margins are reduced).
            final pageWidth = compact == null ? fullWidth : c.maxWidth;
            const gutter = 8.0;
            final free = c.maxWidth - widget.endInset;
            final left = free >= pageWidth + 2 * gutter
                ? (free - pageWidth) / 2
                : widget.endInset > 0
                ? gutter
                : ((c.maxWidth - pageWidth) / 2).clamp(0.0, double.infinity);
            return Padding(
              padding: EdgeInsets.only(left: left),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  key: const ValueKey<String>('write.page'),
                  width: pageWidth,
                  child: page,
                ),
              ),
            );
          },
        ),
      );
      // A rebuild (edit, selection, view change) gets a fresh budget of
      // repagination passes (§29.3).
      _repaginationPasses = 0;
      _scheduleRepagination();
    } else {
      surface = ColoredBox(color: theme.paperColor, child: surface);
    }

    return Semantics(
      textField: true,
      multiline: true,
      readOnly: readOnly,
      label: widget.documentTitle ?? writeL10n(context).editorDocumentTitle,
      child: Focus(
        // Parent of the in-place table cell field: outside the SuperEditor,
        // so the editor's key handlers and IME never see the cell's input.
        focusNode: _outerFocus,
        canRequestFocus: false,
        skipTraversal: true,
        child: MouseRegion(
          onHover: _onHover,
          child: Stack(
            children: [
              Positioned.fill(child: surface),
              ..._buildPopovers(context, theme, readOnly),
            ],
          ),
        ),
      ),
    );
  }

  /// [padding] with [compact] left and right (`compactPadding`).
  static EdgeInsets _compact(EdgeInsets padding, double? compact) =>
      compact == null
      ? padding
      : padding.copyWith(left: compact, right: compact);

  /// [base] with [margins] as document padding (Pages: the page margins;
  /// `compactPadding`) and, when given, [lastBlockBottom] below the last
  /// block, memoized: a new stylesheet makes `super_editor` recreate its
  /// layout presenter and restyle every block, which must not happen on
  /// every keystroke.
  Stylesheet _paddedStylesheet(
    Stylesheet base,
    EdgeInsets margins, {
    double? lastBlockBottom,
  }) {
    final cached = _pagesSheet;
    if (cached != null &&
        identical(cached.base, base) &&
        cached.margins == margins &&
        cached.lastBlockBottom == lastBlockBottom) {
      return cached.sheet;
    }
    final sheet = base.copyWith(
      documentPadding: margins,
      addRulesAfter: [
        if (lastBlockBottom != null)
          StyleRule(
            BlockSelector.all.last(),
            (doc, node) => {
              Styles.padding: CascadingPadding.only(bottom: lastBlockBottom),
            },
          ),
      ],
    );
    _pagesSheet = (
      base: base,
      margins: margins,
      lastBlockBottom: lastBlockBottom,
      sheet: sheet,
    );
    return sheet;
  }

  ({
    Stylesheet base,
    EdgeInsets margins,
    double? lastBlockBottom,
    Stylesheet sheet,
  })?
  _pagesSheet;

  /// The last SuperEditor/SuperReader widget and the inputs it was built
  /// from (see `_build`).
  ({Object key, Widget widget})? _editorMemo;

  /// Coalesces repagination to one measure per frame, after layout (§29.3).
  /// Called after every rebuild in Pages mode and whenever the document's
  /// content is laid out again (the page chrome layer is rebuilt after each
  /// content layout), so heights that change without an editor rebuild (an
  /// image that finishes loading, a web font, an upload preview swapped for
  /// the uploaded file, a collaborator's edit) are re-measured too.
  void _scheduleRepagination() {
    if (_repaginationScheduled) return;
    _repaginationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repaginationScheduled = false;
      _repaginate();
    });
  }

  bool _repaginationScheduled = false;

  /// Consecutive measures that changed the gaps. Each change re-lays out the
  /// document, which measures again, until the gaps are stable; the bound
  /// stops a (theoretical) oscillation until the next rebuild.
  int _repaginationPasses = 0;
  static const _maxRepaginationPasses = 8;

  void _repaginate() {
    if (!mounted || controller.view.layout != LayoutMode.pages) return;
    // A read-only preview (Viewing mode, previews) has its own document.
    final preview = _previewMode == null ? null : _previewEditor;
    final layout = preview == null
        ? controller.documentLayout
        : _previewLayoutKey.currentState as DocumentLayout?;
    if (layout == null) return;
    if (_repaginationPasses >= _maxRepaginationPasses) return;
    final changed = _pagination.measure(
      layout,
      preview?.document ?? controller.document,
    );
    _repaginationPasses = changed ? _repaginationPasses + 1 : 0;
  }

  List<ComponentBuilder> _componentBuilders(
    EditorTheme theme,
    double zoom, {
    required bool editable,
    Document? document,
  }) {
    _boxPhase.update(theme.wonky, zoom, theme.body.fontSize ?? 14.67);
    final doc = document ?? controller.document;
    // Every component in the frames of its containers (Write 11 §7.2).
    ComponentBuilder framed(ComponentBuilder inner) => BoxFrameComponentBuilder(
      inner,
      document: doc,
      layout: _boxLayout,
      theme: theme,
      zoom: zoom,
      callbacks: widget.blockCallbacks,
      editable: editable,
    );
    // Tables and grids are framed as a whole (Write 12 §3.2).
    final cells = _cellsFor(doc)
      ..update(
        theme: theme,
        zoom: zoom,
        editable: editable,
        callbacks: widget.blockCallbacks,
        frames:
            framed(const ParagraphComponentBuilder())
                as BoxFrameComponentBuilder,
      );
    _cellPhase.layout = cells;
    _cellsInBuild = cells;
    return [
      for (final builder in _unframedBuilders(
        theme,
        zoom,
        editable: editable,
        document: document,
      ))
        builder is HintComponentBuilder
            ? builder
            : framed(InlinePillComponentBuilder(builder, theme: theme)),
    ];
  }

  List<ComponentBuilder> _unframedBuilders(
    EditorTheme theme,
    double zoom, {
    required bool editable,
    Document? document,
  }) {
    return [
      if (editable && controller.document.nodeCount == 1)
        HintComponentBuilder(
          widget.hint ?? writeL10n(context).editorHint,
          (context) => theme.body.copyWith(
            color: theme.mutedColor,
            fontSize: (theme.body.fontSize ?? 14.67) * zoom,
          ),
        ),
      WonkyImageComponentBuilder(
        services: widget.imageServices,
        theme: theme,
        callbacks: widget.blockCallbacks,
        editable: editable,
        // Pages mode: an image always fits on one page (§17.3).
        maxHeight: controller.view.layout == LayoutMode.pages
            ? _pagination.contentHeight
            : null,
      ),
      WonkyTableComponentBuilder(theme: theme),
      WonkyTaskComponentBuilder(
        controller.editor,
        editable: editable,
        onToggle: (nodeId) => _commands.toggleChecked(nodeId: nodeId),
        theme: theme,
        zoom: zoom,
        document: document,
      ),
      WonkyListItemComponentBuilder(
        document: document ?? controller.document,
        theme: theme,
        zoom: zoom,
      ),
      WonkyParagraphComponentBuilder(
        document: document ?? controller.document,
        theme: theme,
        zoom: zoom,
        callbacks: widget.blockCallbacks,
        editable: editable,
      ),
      WonkyRuleComponentBuilder(theme: theme),
      WonkyGridComponentBuilder(theme: theme, zoom: zoom),
      WonkyYouTubeComponentBuilder(
        services: widget.imageServices,
        theme: theme,
        zoom: zoom,
        callbacks: widget.blockCallbacks,
        editable: editable,
      ),
      WonkyEmbedComponentBuilder(theme: theme),
      ...defaultComponentBuilders,
      const MarkdownTableComponentBuilder(),
    ];
  }

  Widget _buildEditor(
    EditorTheme theme,
    WriteEditorStyle style,
    Stylesheet stylesheet,
  ) {
    final callbacks =
        widget.shortcutCallbacks ??
        EditorShortcutCallbacks(
          onCopy: () => unawaited(_clipboard.copy()),
          onCut: () => unawaited(_clipboard.cut()),
          onPaste: () => unawaited(_clipboard.paste()),
          onPasteWithoutFormatting: () =>
              unawaited(_clipboard.paste(plainOnly: true)),
          onInsertLink: widget.onEditLink,
        );
    final pages = controller.view.layout == LayoutMode.pages;
    return SuperEditor(
      key: WonkyEditorKeys.editor,
      editor: controller.editor,
      focusNode: controller.focusNode,
      autofocus: widget.autofocus,
      documentLayoutKey: controller.documentLayoutKey,
      scrollController: _scrollController,
      inputRole: 'write-doc-${controller.documentUuid}',
      inputSource: TextInputSource.ime,
      // Keep the selection while focus is elsewhere (a menubar menu, the
      // find field, the comment box), like a word processor: commands from
      // menus act on it and it comes back when the editor regains focus.
      selectionPolicies: const SuperEditorSelectionPolicies(
        clearSelectionWhenEditorLosesFocus: false,
        clearSelectionWhenImeConnectionCloses: false,
      ),
      stylesheet: stylesheet,
      selectionStyle: style.selectionStyles,
      customStylePhases: [
        _boxPhase,
        _cellPhase,
        _pillSpacing,
        if (pages) _paginationPhase,
        _codeHighlight,
        _direction,
        ...widget.extraStylePhases,
      ],
      componentBuilders: _componentBuilders(theme, style.zoom, editable: true),
      cellLayout: _cellsInBuild,
      contentDragDelegate: _textDrag,
      documentUnderlayBuilders: [
        if (pages)
          _PageChromeLayerBuilder(
            pagination: _pagination,
            theme: theme,
            onContentLayout: _scheduleRepagination,
          ),
        WonkyHighlightLayerBuilder(controller: controller, theme: theme),
      ],
      documentOverlayBuilders: [
        DefaultCaretOverlayBuilder(
          caretStyle: style.caretStyle,
          // No caret with a selection (like desktop editors): a selected
          // block (a grid or table being edited in place) showed a large
          // caret beside it.
          displayCaretWithExpandedSelection: false,
          adjustCaretRect: (position, rect, _) => controller.pillBoundary
              .caretRect(controller.document, position, rect),
          caretRectListenable: controller.pillBoundary,
        ),
        WonkyRemoteCaretLayerBuilder(controller: controller, theme: theme),
        DropIndicatorLayerBuilder(
          controller: controller,
          indicator: _dropIndicator,
          theme: theme,
        ),
      ],
      keyboardActions: wonkyKeyboardActions(
        controller: controller,
        commands: _commands,
        keymap: widget.keymap,
        popoverKeys: _popoverKeys,
        builtInShortcuts: widget.builtInShortcuts,
        callbacks: callbacks,
      ),
      contentTapDelegateFactories: [
        (editContext) => WonkyLinkTapHandler(
          document: controller.document,
          composer: controller.composer,
          requireModifier: true,
          onOpenLink: widget.onOpenLink,
        ),
        superEditorAddEmptyParagraphTapHandlerFactory,
      ],
    );
  }

  Widget _buildReader(
    EditorTheme theme,
    WriteEditorStyle style,
    Stylesheet stylesheet,
    SuggestionPreviewMode? preview,
  ) {
    final editor = preview == null
        ? controller.editor
        : (_previewEditor ?? controller.editor);
    final isMain = identical(editor, controller.editor);
    final pages = controller.view.layout == LayoutMode.pages;
    return SuperReader(
      key: const ValueKey<String>('write.editor.reader'),
      editor: editor,
      focusNode: isMain ? controller.focusNode : null,
      documentLayoutKey: isMain
          ? controller.documentLayoutKey
          : _previewLayoutKey,
      scrollController: _scrollController,
      stylesheet: stylesheet,
      customStylePhases: [
        _boxPhase,
        _cellPhase,
        _pillSpacing,
        // Pages also for previews (Viewing mode shows one).
        if (pages) _paginationPhase,
        _codeHighlight,
        _direction,
        if (isMain) ...widget.extraStylePhases,
      ],
      componentBuilders: _componentBuilders(
        theme,
        style.zoom,
        editable: false,
        document: editor.document,
      ),
      cellLayout: _cellsInBuild,
      documentUnderlayBuilders: [
        if (pages)
          _ReaderPageChromeLayerBuilder(
            pagination: _pagination,
            theme: theme,
            onContentLayout: _scheduleRepagination,
          ),
        if (isMain)
          WonkyReaderHighlightLayerBuilder(
            controller: controller,
            theme: theme,
          ),
      ],
      documentOverlayBuilders: [
        if (isMain)
          WonkyReaderRemoteCaretLayerBuilder(
            controller: controller,
            theme: theme,
          ),
        ...defaultSuperReaderDocumentOverlayBuilders,
      ],
      contentTapDelegateFactory: (readerContext) => WonkyLinkTapHandler(
        document: editor.document,
        composer: editor.composer,
        requireModifier: false,
        onOpenLink: widget.onOpenLink,
      ),
    );
  }

  List<Widget> _buildPopovers(
    BuildContext context,
    EditorTheme theme,
    bool readOnly,
  ) {
    final widgets = <Widget>[];
    final layout = controller.documentLayout;
    if (layout == null) return widgets;
    final box = context.findRenderObject() as RenderBox?;
    Offset? anchorBelow(int offset) {
      final position = controller.mirror.positionAt(offset);
      if (position == null || box == null || !box.hasSize) return null;
      final rect = layout.getRectForPosition(position);
      if (rect == null) return null;
      final global = layout.getGlobalOffsetFromDocumentOffset(rect.bottomLeft);
      return box.globalToLocal(global) + const Offset(0, 4);
    }

    final slash = _triggers.slash.value;
    if (!readOnly && slash != null && _slashPicker.items.isNotEmpty) {
      final at = anchorBelow(slash.start);
      if (at != null) {
        widgets.add(
          Positioned(
            left: at.dx,
            top: at.dy,
            child: SlashMenu(
              picker: _slashPicker,
              theme: theme,
              onChoose: _chooseSlash,
            ),
          ),
        );
      }
    }
    final mention = _triggers.mention.value;
    if (!readOnly && mention != null && widget.mentionCandidates != null) {
      final at = anchorBelow(mention.start);
      if (at != null) {
        widgets.add(
          Positioned(
            left: at.dx,
            top: at.dy,
            child: MentionPicker(
              picker: _mentionPicker,
              theme: theme,
              onChoose: _chooseMention,
            ),
          ),
        );
      }
    }
    final emoji = _triggers.emoji.value;
    if (!readOnly && emoji != null && _emojiPicker.items.isNotEmpty) {
      final at = anchorBelow(emoji.start);
      if (at != null) {
        widgets.add(
          Positioned(
            left: at.dx,
            top: at.dy,
            child: EmojiMenu(
              picker: _emojiPicker,
              theme: theme,
              onChoose: _chooseEmoji,
            ),
          ),
        );
      }
    }
    final link = _linkCard.value;
    if (link != null &&
        link.mentionUuid == null &&
        slash == null &&
        mention == null &&
        emoji == null) {
      final at = anchorBelow(link.start);
      if (at != null) {
        widgets.add(
          Positioned(
            left: at.dx,
            top: at.dy,
            child: LinkHoverCard(
              url: link.url,
              theme: theme,
              actions: LinkCardActions(
                onOpen: widget.onOpenLink == null
                    ? null
                    : () => widget.onOpenLink!(link.url),
                onCopy: () =>
                    unawaited(Clipboard.setData(ClipboardData(text: link.url))),
                onEdit: readOnly || widget.onEditLink == null
                    ? null
                    : () {
                        controller.select(DeltaSelection(link.start, link.end));
                        widget.onEditLink!();
                      },
                onRemove: readOnly
                    ? null
                    : () {
                        _commands.removeLink(
                          start: link.start,
                          length: link.end - link.start,
                        );
                        _linkCard.value = null;
                      },
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

/// Opens links: with the Mod key in Editing/Suggesting ("interaction mode"),
/// with a plain click in Viewing (Write 04 §11.6).
class WonkyLinkTapHandler extends ContentTapDelegate {
  WonkyLinkTapHandler({
    required this.document,
    required this.composer,
    required this.requireModifier,
    this.onOpenLink,
  }) {
    composer.isInInteractionMode.addListener(notifyListeners);
  }

  final Document document;
  final DocumentComposer composer;
  final bool requireModifier;
  final void Function(String url)? onOpenLink;

  @override
  void dispose() {
    composer.isInInteractionMode.removeListener(notifyListeners);
    super.dispose();
  }

  bool get _active => !requireModifier || composer.isInInteractionMode.value;

  /// The hover position is the nearest caret position: right of a link's
  /// last glyph's middle (or over an arrow link's arrow) it follows the link.
  @override
  MouseCursor? mouseCursorForContentHover(DocumentPosition hoverPosition) =>
      _active &&
          (_linkAt(hoverPosition) ?? _linkEndingAt(hoverPosition)) != null
      ? SystemMouseCursors.click
      : null;

  String? _linkEndingAt(DocumentPosition position) {
    final p = position.nodePosition;
    if (p is! TextNodePosition || p.offset == 0) return null;
    return _linkAt(
      DocumentPosition(
        nodeId: position.nodeId,
        nodePosition: TextNodePosition(offset: p.offset - 1),
      ),
    );
  }

  @override
  TapHandlingInstruction onTap(DocumentTapDetails details) {
    if (!_active || onOpenLink == null) {
      return TapHandlingInstruction.continueHandling;
    }
    final position = DocumentGeometry.characterAt(
      details.documentLayout,
      details.layoutOffset,
    );
    final url = position == null ? null : _linkAt(position);
    if (url == null) return TapHandlingInstruction.continueHandling;
    onOpenLink!(url);
    return TapHandlingInstruction.halt;
  }

  String? _linkAt(DocumentPosition position) {
    final nodePosition = position.nodePosition;
    final node = document.getNodeById(position.nodeId);
    if (node is! TextNode ||
        nodePosition is! TextNodePosition ||
        nodePosition.offset >= node.text.length) {
      return null;
    }
    for (final attribution in node.text.getAllAttributionsAt(
      nodePosition.offset,
    )) {
      if (attribution is LinkAttribution) return attribution.plainTextUri;
    }
    return null;
  }
}

class _PageChromeLayerBuilder implements SuperEditorLayerBuilder {
  const _PageChromeLayerBuilder({
    required this.pagination,
    required this.theme,
    required this.onContentLayout,
  });

  final PaginationController pagination;
  final EditorTheme theme;
  final VoidCallback onContentLayout;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperEditorContext editContext,
  ) => _PageChromeLayer(
    pagination: pagination,
    theme: theme,
    onContentLayout: onContentLayout,
  );
}

class _ReaderPageChromeLayerBuilder implements SuperReaderDocumentLayerBuilder {
  const _ReaderPageChromeLayerBuilder({
    required this.pagination,
    required this.theme,
    required this.onContentLayout,
  });

  final PaginationController pagination;
  final EditorTheme theme;
  final VoidCallback onContentLayout;

  @override
  ContentLayerWidget build(
    BuildContext context,
    SuperReaderContext readerContext,
  ) => _PageChromeLayer(
    pagination: pagination,
    theme: theme,
    onContentLayout: onContentLayout,
  );
}

class _PageChromeLayer extends ContentLayerStatelessWidget {
  const _PageChromeLayer({
    required this.pagination,
    required this.theme,
    required this.onContentLayout,
  });

  final PaginationController pagination;
  final EditorTheme theme;

  /// Called on every build of this layer. Content layers are rebuilt after
  /// each layout of the document content, so this reports every layout:
  /// block heights may have changed and the pages are re-measured (§29.3).
  final VoidCallback onContentLayout;

  @override
  Widget doBuild(
    BuildContext context,
    Element? contentElement,
    RenderObject? contentLayout,
  ) {
    onContentLayout();
    return IgnorePointer(
      child: CustomPaint(
        painter: PageChromePainter(
          pagination: pagination,
          paperColor: theme.paperColor,
          borderColor: theme.tableBorderColor,
          textStyle: TextStyle(
            fontSize: 11 * pagination.zoom,
            color: theme.mutedColor,
          ),
        ),
      ),
    );
  }
}

/// Keeps the caret visible after keyboard edits (Write 04 §5) — exposed for
/// the screen's scroll helpers.
extension WonkyEditorScrolling on WonkyEditorState {
  /// Scrolls so that Delta [offset] is visible with a 64 px margin.
  void revealOffset(int offset) {
    final layout = controller.documentLayout;
    final position = controller.mirror.positionAt(offset);
    if (layout == null || position == null) return;
    final rect = layout.getRectForPosition(position);
    if (rect == null || !_scrollController.hasClients) return;
    final viewport = _scrollController.position.viewportDimension;
    final current = _scrollController.offset;
    double? target;
    if (rect.top - 64 < current) target = rect.top - 64;
    if (rect.bottom + 64 > current + viewport) {
      target = rect.bottom + 64 - viewport;
    }
    if (target != null) {
      _scrollController.jumpTo(
        target.clamp(0, _scrollController.position.maxScrollExtent),
      );
    }
  }
}

/// Convenience for screens: the blocks touched by the selection.
extension WonkyEditorBlocks on WriteEditorController {
  List<BlockRef> get selectedBlocks =>
      selection == null ? const [] : mirror.blocksInSelection(selection!);
}
