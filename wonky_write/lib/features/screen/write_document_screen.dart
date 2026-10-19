import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show DriveItemView;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../ai/ai_panel.dart';
import '../ai/ai_preview_overlay.dart';
import '../ai/write_ai_controller.dart';
import '../import/import_warnings_banner.dart';
import '../../commands/extras_commands.dart';
import '../../commands/screen_commands.dart';
import '../comments/comment_margin.dart';
import '../document/write_document_session.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show DeltaSelection;
import '../editor/components/editor_services.dart';
import '../editor/controller/editor_types.dart';
import '../editor/keyboard/editor_keyboard.dart';
import '../editor/pagination/pagination.dart';
import '../editor/plugins/slash_items.dart';
import '../editor/popovers/editor_popovers.dart';
import '../editor/ui/wonky_editor.dart';
import '../find_replace/find_panel.dart';
import '../outline/outline_panel.dart';
import '../themes/document_theme.dart';
import '../../l10n/write_l10n.dart';
import 'command_invoke.dart';
import 'document_menus.dart';
import 'selection_toolbar.dart';
import 'write_document_controller.dart';
import 'write_toolbar.dart';

/// Creates the document session of the screen (tests inject fakes).
typedef WriteSessionFactory =
    WriteDocumentSession Function(ShellServices services, String itemUuid);

/// The document editor screen `/d/:uuid` (Write 05 §3): the shell's
/// `EditorScaffold` (title row, menubar, panels, word count bar) around the
/// Write toolbar and the document canvas with its comment margin.
class WriteDocumentScreen extends StatefulWidget {
  const WriteDocumentScreen({
    super.key,
    required this.services,
    required this.itemUuid,
    required this.themes,
    this.heading,
    this.sessionFactory,
  });

  final ShellServices services;
  final String itemUuid;
  final WriteThemeCatalog themes;

  /// `?heading=<anchor>`: scroll to this heading once loaded.
  final String? heading;
  final WriteSessionFactory? sessionFactory;

  /// Left and right padding around the text in the mobile layout, instead
  /// of the page margins (suite 02 §6.1, T-12).
  static const double mobileTextPadding = 16;

  @override
  State<WriteDocumentScreen> createState() => _WriteDocumentScreenState();
}

class _WriteDocumentScreenState extends State<WriteDocumentScreen> {
  late final WriteDocumentSession session;
  late final WriteDocumentController doc;
  late final WriteAiController ai;
  final _editorKey = GlobalKey<WonkyEditorState>();
  final _toolbar = WonkyToolbarController();
  final _scroll = ScrollController();
  bool _headingHandled = false;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    session =
        widget.sessionFactory?.call(s, widget.itemUuid) ??
        WriteDocumentSession(services: s, itemUuid: widget.itemUuid);
    doc = WriteDocumentController(
      services: s,
      session: session,
      themes: widget.themes,
    );
    doc.revealOffset = _reveal;
    doc.focusToolbar = _toolbar.focus;
    ai = WriteAiController(services: s, session: session, doc: doc);
    // Comments and suggestions are shown in the margin (Write 05 §10).
    s.commentsHost = doc.viewPrefs;
    unawaited(session.open());
    session.phase.addListener(_onPhase);
    _marginCardSources.addListener(_onMarginCards);
    s.panels.addListener(_onPanels);
    if (kIsWeb) unawaited(BrowserContextMenu.disableContextMenu());
  }

  @override
  void dispose() {
    session.phase.removeListener(_onPhase);
    _marginCardSources.removeListener(_onMarginCards);
    _hasMarginCards.dispose();
    s.panels.removeListener(_onPanels);
    if (identical(s.commentsHost, doc.viewPrefs)) s.commentsHost = null;
    if (kIsWeb) unawaited(BrowserContextMenu.enableContextMenu());
    if (s.panels.isOpen(WritePanels.find)) s.panels.close(WritePanels.find);
    _pagination?.removeListener(_onPages);
    ai.dispose();
    doc.dispose();
    session.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _reveal(int offset) => _editorKey.currentState?.revealOffset(offset);

  PaginationController? _pagination;

  /// Mirrors the editor's page count into the controller (status bar, word
  /// count dialog).
  void _attachPagination() {
    final p = _editorKey.currentState?.pagination;
    if (p == null || identical(p, _pagination)) return;
    _pagination?.removeListener(_onPages);
    _pagination = p..addListener(_onPages);
    _onPages();
  }

  void _onPages() {
    final n = _pagination?.pageCount;
    if (mounted) doc.pageCount.value = n == null || n < 1 ? null : n;
  }

  void _onPanels() {
    if (doc.find.isActive && !s.panels.isOpen(WritePanels.find)) {
      doc.find.close();
    }
  }

  void _onPhase() {
    if (session.phase.value != WriteSessionPhase.ready) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final heading = widget.heading;
      if (heading != null && !_headingHandled) {
        _headingHandled = true;
        doc.insights.refresh();
        final i = doc.insights.outline.indexWhere((e) => e.anchorId == heading);
        if (i >= 0) doc.goToHeading(i);
      } else if (doc.editor.selection == null && doc.editable) {
        doc.focusEditor();
      }
    });
  }

  void _invoke(String id, [Map<String, Object?> args = const {}]) =>
      unawaited(invokeWith(s, id, args: args, context: context));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: doc.viewPrefs,
      builder: (context, _) => _scaffold(context),
    );
  }

  Widget _scaffold(BuildContext context) {
    return EditorScaffold(
      key: ValueKey<String>('write.screen.${widget.itemUuid}'),
      services: s,
      itemUuid: widget.itemUuid,
      controller: doc,
      toolbar: (context) =>
          WriteToolbar(services: s, doc: doc, controller: _toolbar),
      body: (context, item) => _body(context, item),
      // The bar only shows the word count, when it is turned on (Write 05
      // §11).
      showStatusBar: doc.viewPrefs.showWordCount,
      statusLeft: (context) => [WordCountStatus(doc: doc)],
      commentsInPanel: false,
      belowToolbar: _modeLine,
      // The comments toggle is in the toolbar, next to the mode switcher.
      commentsButton: false,
      // Rail order: Assistant, Outline, Find (then the shell's History).
      panels: [
        if (s.assistant?.available ?? false) writeAssistantPanelSpec(ai),
        SidePanelSpec(
          id: WritePanels.outline,
          title: writeL10n(context).screenPanelOutline,
          icon: LucideIcons.listTree,
          builder: (context) => OutlinePanel(
            insights: doc.insights,
            view: doc.outlineView,
            onClose: () {
              s.panels.close(WritePanels.outline);
              doc.focusEditor();
            },
          ),
        ),
        SidePanelSpec(
          id: WritePanels.find,
          title: writeL10n(context).screenPanelFind,
          icon: LucideIcons.search,
          builder: (context) => ListenableBuilder(
            listenable: doc,
            builder: (context, _) => FindPanel(
              controller: doc.find,
              editable: doc.editable,
              onClose: () => _invoke('write.find.close'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, DriveItemView item) {
    return ValueListenableBuilder<WriteSessionPhase>(
      valueListenable: session.phase,
      builder: (context, phase, _) {
        switch (phase) {
          case WriteSessionPhase.noAccess:
            return NoAccessPage(services: s, itemUuid: widget.itemUuid);
          case WriteSessionPhase.failed:
            return _failed(context);
          case WriteSessionPhase.loading:
            return const _CanvasLoading();
          case WriteSessionPhase.ready:
            return ImportWarningsBanner(
              services: s,
              documentUuid: item.contentRef,
              child: _canvas(context, item),
            );
        }
      },
    );
  }

  Widget _failed(BuildContext context) {
    final err = session.error;
    final l = writeL10n(context);
    return WonkyEmptyState(
      illustration: err != null && isOfflineError(err)
          ? EmptyIllustration.offline
          : EmptyIllustration.error,
      title: err != null && isOfflineError(err)
          ? l.screenOfflineUnavailable
          : l.screenOpenFailed,
      description: err == null ? null : errorMessage(err),
      actions: [
        ShadButton.outline(
          onPressed: () => unawaited(session.retry()),
          child: Text(l.screenTryAgain),
        ),
        ShadButton.ghost(
          onPressed: () => s.router.go('/'),
          child: Text(l.screenGoBack),
        ),
      ],
    );
  }

  Widget _canvas(BuildContext context, DriveItemView item) {
    final brightness = ShadTheme.of(context).brightness;
    final ui = CommandUi(context, s);
    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.documentTheme,
        doc.viewPrefs,
        session,
        // The page makes room for the comment margin when it shows. Not
        // `session.comments` / `session.suggestions`: they notify on every
        // keystroke, and a new `WonkyEditor` rebuilds the whole document
        // layout (Write 04 §36).
        _hasMarginCards,
        // `ai.shown` (the slash menu's AI items): the shell scaffold no
        // longer rebuilds the body on command-state signals (CQ-39).
        s.prefs,
        ?ai.assistant?.status,
      ]),
      builder: (context, _) {
        final theme = doc.documentTheme.editorTheme(brightness);
        final editor = WonkyEditor(
          endInset: _marginShown(context) ? _marginColumn : 0,
          // Phones: 16 px beside the text instead of the page margins
          // (suite 02 §6.1, T-12).
          compactPadding: WonkyLayout.isMobile(context)
              ? WriteDocumentScreen.mobileTextPadding
              : null,
          key: _editorKey,
          controller: doc.editor,
          commands: doc.commands,
          clipboard: doc.clipboard,
          theme: theme,
          documentTitle: item.name,
          imageServices: doc.images,
          scrollController: _scroll,
          keymap: (event) =>
              s.keymap.handle(event, KeyScope.editor, context: context) ==
              KeyEventResult.handled,
          shortcutCallbacks: EditorShortcutCallbacks(
            onUndo: () => _invoke('shell.edit.undo'),
            onRedo: () => _invoke('shell.edit.redo'),
            onInsertLink: () => _invoke('write.link.insert'),
            onCopy: () => _invoke('write.edit.copy'),
            onCut: () => _invoke('write.edit.cut'),
            onPaste: () => _invoke('write.edit.paste'),
            onPasteWithoutFormatting: () =>
                _invoke('write.edit.pasteWithoutFormatting'),
            onFind: () => _invoke('write.find.open'),
          ),
          slashHost: SlashHost(
            onInsertImage: () => _invoke('write.insert.image'),
            onInsertImageFromUrl: () => _invoke('write.insert.imageFromUrl'),
            onInsertLink: () => _invoke('write.link.insert'),
            onTableInserted: (id) =>
                _invoke('write.table.editCell', {'nodeId': id}),
            onComment: () => _invoke('shell.comments.create'),
            onEmoji: () => _invoke('write.insert.emoji'),
            onSpecialCharacter: () => _invoke('write.insert.specialCharacter'),
            onAskAi: ai.shown ? () => _invoke('write.ai.inline') : null,
            onContinueWriting: ai.shown
                ? () => _invoke('write.ai.continue')
                : null,
          ),
          blockCallbacks: EditorBlockCallbacks(
            onEditTable: (nodeId, {row, column}) => _invoke(
              'write.table.edit',
              {'nodeId': nodeId, 'row': ?row, 'col': ?column},
            ),
            onCodeLanguageTap: (nodeId, rect) =>
                PopupMenuHost.maybeOf(_menuContext ?? context)?.show(
                  rect.bottomLeft,
                  () => codeLanguageEntries(ui, doc, nodeId: nodeId),
                ),
            onCopyCode: (nodeId) =>
                _invoke('write.code.copy', {'nodeId': nodeId}),
            onImageDoubleTap: (nodeId) =>
                _invoke('write.image.preview', {'nodeId': nodeId}),
            onImageTap: (nodeId) =>
                _invoke('write.image.preview', {'nodeId': nodeId}),
            onRemoveImage: (nodeId) {
              final data = doc.embedData('image', nodeId);
              if (data != null) doc.images.cancel('${data['src']}');
              _invoke('write.block.delete', {'nodeId': nodeId});
            },
          ),
          mentionCandidates: _mentionCandidates,
          emojiSuggestions: _emoji,
          extraStylePhases: [doc.spellcheck.styler],
          onDropFiles: (files, index) => unawaited(
            handleDroppedFiles(s, doc, files, index, context: context),
          ),
          onOpenLink: (url) =>
              unawaited(openWriteLink(s, doc, url, context: context)),
          onEditLink: () => _invoke('write.link.edit'),
          hint: doc.editable ? writeL10n(context).screenEditorHint : '',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _attachPagination();
        });
        return PopupMenuHost(
          child: Builder(
            builder: (context) {
              _menuContext = context;
              final stack = Stack(
                children: [
                  Positioned.fill(
                    child: Listener(
                      onPointerDown: (e) {
                        if (e.buttons == kSecondaryMouseButton) {
                          _openContextMenu(context, e.position);
                        }
                      },
                      child: SelectionToolbarLayer(
                        doc: doc,
                        ui: ui,
                        // Material ancestor for the editor's checkbox and
                        // text-selection widgets (the shell is shad-only).
                        child: Material(
                          type: MaterialType.transparency,
                          child: editor,
                        ),
                      ),
                    ),
                  ),
                  // Inline AI prompt, preview and ghost text (Write 09 §5.3).
                  Positioned.fill(child: AiPreviewLayer(ai: ai)),
                ],
              );
              return LayoutBuilder(
                builder: (context, c) => ListenableBuilder(
                  listenable: Listenable.merge([
                    doc.editor.view,
                    session.comments,
                    session.suggestions,
                  ]),
                  builder: (context, _) => _withMargin(context, c, stack),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// The 2 px line under the toolbar across the whole window (Write 05 §3):
  /// green while suggesting, otherwise the page background's color (so the
  /// layout doesn't shift between modes).
  Widget _modeLine(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([doc, doc.documentTheme]),
    builder: (context, _) {
      final suggesting = doc.editor.mode == EditorMode.suggesting;
      final theme = doc.documentTheme.editorTheme(
        ShadTheme.of(context).brightness,
      );
      final pages = doc.editor.view.layout == LayoutMode.pages;
      return SizedBox(
        height: 2,
        child: ColoredBox(
          key: ValueKey<String>(
            suggesting ? 'write.canvas.suggestingCue' : 'write.canvas.modeLine',
          ),
          color: suggesting
              ? ShadTheme.of(context).colorScheme.success
              : (pages ? theme.canvasColor : theme.paperColor),
        ),
      );
    },
  );

  /// Width of the comment margin column including its padding.
  static const double _marginColumn = 300 + 8 + 16;

  /// Whether the margin has cards (threads, suggestions or a draft) the
  /// user may see; updated when comments or suggestions change.
  late final ValueNotifier<bool> _hasMarginCards = ValueNotifier(
    _computeHasMarginCards(),
  );

  late final Listenable _marginCardSources = Listenable.merge([
    session,
    session.comments,
    session.suggestions,
  ]);

  void _onMarginCards() => _hasMarginCards.value = _computeHasMarginCards();

  bool _computeHasMarginCards() {
    final comments = session.comments;
    return comments.controller != null &&
        comments.visible &&
        (comments.anchoredOpenThreads.isNotEmpty ||
            comments.unanchoredThreads.isNotEmpty ||
            session.suggestions.pending.isNotEmpty ||
            comments.draftOffset != null);
  }

  /// Whether the comment margin shows: there are cards (threads,
  /// suggestions or a draft), the user may see comments, the margin is
  /// turned on and the window is wide enough.
  bool _marginShown(BuildContext context) {
    return _hasMarginCards.value &&
        doc.viewPrefs.showCommentMargin &&
        // Not in the read-only mobile layout (suite 02 §6.1).
        !WonkyLayout.isMobile(context);
  }

  /// The canvas with the comment margin (Write 05 §3, 08 §3.2): comments
  /// and suggestions are shown only there, toggled with the comments button
  /// (`shell.comments.togglePanel`). Pages: the margin is drawn over the
  /// canvas's right edge and the page centers in the rest (`endInset`),
  /// moving left down to an 8 px gutter — it overlaps the page only when the
  /// window is too narrow for both. Pageless: the margin is a column beside
  /// the content.
  Widget _withMargin(BuildContext context, BoxConstraints c, Widget stack) {
    if (!_marginShown(context)) return stack;
    final theme = doc.documentTheme.editorTheme(
      ShadTheme.of(context).brightness,
    );
    final pages = doc.editor.view.layout == LayoutMode.pages;
    final margin = SizedBox(
      width: _marginColumn,
      child: ClipRect(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
          child: CommentMargin(
            key: const ValueKey<String>('write.commentMargin'),
            session: session,
            width: 300,
            scrollController: _scroll,
          ),
        ),
      ),
    );
    if (!pages) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: stack),
          ColoredBox(color: theme.paperColor, child: margin),
        ],
      );
    }
    return Stack(
      children: [
        Positioned.fill(child: stack),
        Positioned(top: 0, right: 0, bottom: 0, child: margin),
      ],
    );
  }

  BuildContext? _menuContext;

  late final _emoji = emojiSuggester(s);

  void _openContextMenu(BuildContext context, Offset global) {
    final layout = doc.editor.documentLayout;
    if (layout != null) {
      final local = layout.getDocumentOffsetFromAncestorOffset(global);
      final position = layout.getDocumentPositionNearestToOffset(local);
      final offset = position == null
          ? null
          : doc.editor.mirror.offsetOf(position);
      final sel = doc.editor.selection;
      if (offset != null &&
          (sel == null ||
              sel.isCollapsed ||
              offset < sel.start ||
              offset > sel.end)) {
        doc.editor.select(DeltaSelection.collapsed(offset));
      }
    }
    final ui = CommandUi(context, s);
    PopupMenuHost.maybeOf(context)?.show(
      global,
      () => contextMenuEntries(ui, doc),
      onClosed: doc.focusEditor,
    );
  }

  Future<List<MentionCandidate>> _mentionCandidates(String query) async {
    try {
      final users = await s.repositories.users.searchUsers(query, limit: 8);
      return [
        for (final u in users)
          MentionCandidate(
            userUuid: u.uuid.uuid,
            displayName: u.displayName,
            email: u.email,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }
}

class _CanvasLoading extends StatelessWidget {
  const _CanvasLoading();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: ShadTheme.of(context).colorScheme.canvas,
    child: LoadingShimmer.documentPage(),
  );
}

// ---------------------------------------------------------------------------
// Status bar (Write 05 §11).

/// "1,234 words" / "56 of 1,234 words" (+ "Page 2 of 7").
class WordCountStatus extends StatelessWidget {
  const WordCountStatus({super.key, required this.doc});

  final WriteDocumentController doc;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([
        doc.insights,
        doc.viewPrefs,
        doc.pageCount,
      ]),
      builder: (context, _) {
        if (!doc.viewPrefs.showWordCount) return const SizedBox.shrink();
        final l = writeL10n(context);
        final stats = doc.insights.stats;
        final selection = doc.insights.selectionStats;
        final words = selection == null
            ? l.screenStatusWords(stats.words)
            : l.screenStatusSelectedOfWords(selection.words, stats.words);
        final pages = doc.view.layout == LayoutMode.pages
            ? doc.pageCount.value
            : null;
        final text = pages == null || pages < 1
            ? words
            : l.screenStatusWordsAndPages(words, pages);
        void open() => unawaited(
          invokeWith(
            ShellScope.of(context),
            'write.tools.wordCount',
            context: context,
          ),
        );
        return ShadTooltip(
          builder: (_) => Text(
            l.screenStatusCharactersReading(
              stats.characters,
              math.max(0, stats.readingTimeMinutes),
            ),
          ),
          // One labeled button node for screen readers (the text is the
          // label; tapping opens the word count dialog).
          child: Semantics(
            container: true,
            button: true,
            label: text,
            hint: l.screenWordCountHint,
            onTap: open,
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey<String>('write.status.wordCount'),
              onTap: open,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  text,
                  style: theme.textTheme.muted.copyWith(fontSize: 12),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
