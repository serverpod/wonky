import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../ai/design_ideas_panel.dart' show DesignIdeasController;
import '../ai/slides_ai_controller.dart';
import '../elements/shape/shape_gallery.dart';
import '../elements/shape/shape_tool.dart';
import '../../config/menus/context_menu_specs.dart';
import '../../config/menus/slides_menu_spec.dart';
import '../../config/slides_features.dart';
import '../../config/panels/slides_panels.dart';
import '../../l10n/slides_l10n.dart';
import '../canvas/slide_canvas_controller.dart';
import '../collab/slides_collab.dart';
import '../comments/slides_comments.dart';
import '../history/local_conflicts.dart';
import '../../mcp/slides_ui_bridge.dart';
import '../model/deck_session.dart';
import '../revlog/slides_rev_log.dart' show openDeckSession;
import '../layouts/layout_gallery.dart' show galleryLayouts;
import '../themes/theme_previews.dart';
import '../toolbar/slides_toolbar.dart';
import 'chrome_prefs.dart';
import 'deck_body.dart';
import '../spellcheck/spelling_actions.dart' show canvasSpellingMenu;
import '../text_editing/text_editing_host.dart' show textEditingOf;
import '../uploads/slides_image_service.dart';
import 'deck_document_controller.dart';
import 'deck_editor_controller.dart';
import 'deck_loading_view.dart';
import 'deck_status_bar.dart';
import 'present_button.dart';
import '../present/present_session_banner.dart';
import 'slide_labels.dart';

/// Opens the deck session of a presentation (tests inject fakes).
typedef DeckSessionFactory =
    Future<DeckSession> Function(ShellServices services, UuidValue item);

/// The deck editor at `/p/:uuid` (Slides 04 §2): the shell's
/// `EditorScaffold` (title row with the *Present* split button, the Slides
/// menubar, side panels) around the Slides toolbar, the editor body
/// (navigator, canvas, speaker notes, inspector, view modes) and the status
/// bar. The deck opens through `openDeckSession` (02 §9): "Downloading
/// presentation… 42 %" while it downloads, *not available offline* /
/// unavailable states, and *Try again* when the local storage didn't start.
class DeckEditorScreen extends StatefulWidget {
  const DeckEditorScreen({
    super.key,
    required this.services,
    required this.itemUuid,
    this.sessionFactory,
    this.initialSlideId,
    this.initialCommentId,
  });

  final ShellServices services;
  final String itemUuid;
  final DeckSessionFactory? sessionFactory;

  /// `?slide=<slideId>` deep link.
  final String? initialSlideId;

  /// `?comment=<threadUuid>` deep link (09 §3.4).
  final String? initialCommentId;

  @override
  State<DeckEditorScreen> createState() => _DeckEditorScreenState();
}

class _DeckEditorScreenState extends State<DeckEditorScreen> {
  late final DeckDocumentController doc = DeckDocumentController(
    services: s,
    itemUuid: UuidValue.fromString(widget.itemUuid),
  );
  DeckSession? _session;
  DeckEditorController? _editor;
  SlideCanvasController? _canvas;
  SlidesChromePrefs? _prefs;
  Object? _error;
  final _toolbar = WonkyToolbarController();
  final _bodyKey = GlobalKey();
  bool _disposed = false;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
    if (kIsWeb) unawaited(BrowserContextMenu.disableContextMenu());
  }

  Future<void> _open() async {
    try {
      final prefs = SlidesChromePrefs.read(s.userStore);
      final factory = widget.sessionFactory ?? openDeckSession;
      final session = await factory(s, UuidValue.fromString(widget.itemUuid));
      _prefs = await prefs;
      if (_disposed) {
        unawaited(session.dispose());
        return;
      }
      _session = session;
      session.loadState.addListener(_onLoadState);
      _onLoadState();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onLoadState() {
    final session = _session;
    if (session == null || !mounted) return;
    if (session.loadState.value is DeckReady && _editor == null) {
      final editor = DeckEditorController(
        services: s,
        session: session,
        itemRole: doc.role,
        prefs: _prefs,
        initialSlideId: widget.initialSlideId,
      );
      doc.attach(editor);
      _editor = editor;
      // The canvas state of the deck (renderer, viewport, selection; SL-12).
      _canvas = SlideCanvasController.attach(editor);
      // Presence, soft locks and hints (SL-21, 09 §1–§2).
      SlidesCollab.attach(editor, presence: doc.presence);
      // Comment anchors, pins and badges (SL-38, 09 §3).
      final comments = SlidesComments.attach(editor);
      // Overwritten-text review and restore notices (SL-39, 09 §6.3).
      if (SlidesFeatures.isOn(SlidesFeature.versionHistory)) {
        SlidesConflicts.attach(editor, presence: doc.presence).forced = (body) {
          final claim = SlidesCollab.of(editor)?.locks.published;
          return claim != null &&
              claim.forced &&
              switch (body.kind) {
                'notes' =>
                  claim.kind == 'notes' && claim.slideId == body.slideId,
                'cell' =>
                  claim.kind == 'tableCell' &&
                      claim.elementId == body.elementId &&
                      claim.rowId == body.rowId &&
                      claim.columnId == body.columnId,
                _ => claim.kind == 'text' && claim.elementId == body.elementId,
              };
        };
      }
      // MCP UI bridge: agent highlights, headless-write flashes, the
      // soft-lock popover as a dialog (SL-42, 11 §5).
      SlidesUiBridge.attach(editor);
      final thread = widget.initialCommentId;
      if (thread != null) comments.openDeepLink(thread);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _disposed = true;
    if (kIsWeb) unawaited(BrowserContextMenu.enableContextMenu());
    _session?.loadState.removeListener(_onLoadState);
    final editor = _editor;
    final canvas = _canvas;
    final session = _session;
    // Pending typing is written while the session is still open (SL-13).
    if (editor != null) textEditingOf(editor).dispose();
    if (editor != null) SlidesCollab.of(editor)?.dispose();
    if (editor != null) SlidesComments.of(editor)?.dispose();
    if (editor != null) SlidesConflicts.of(editor)?.dispose();
    if (editor != null) SlidesUiBridge.of(editor)?.dispose();
    if (editor != null) SlidesAiController.maybeOf(editor)?.dispose();
    if (editor != null) DesignIdeasController.maybeOf(editor)?.dispose();
    // The shell deactivates the document after this frame; dispose after.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      canvas?.dispose();
      if (editor != null) ThemePreviews.maybeOf(editor)?.dispose();
      // Cancels polls for other users' pending uploads (CQ-43).
      if (editor != null) SlidesImageService.maybeOf(editor)?.dispose();
      editor?.dispose();
      doc.dispose();
      if (session != null) unawaited(session.dispose());
    });
    super.dispose();
  }

  /// Opens context menu [menuId] (04 §11) at [global].
  void _openMenu(String menuId, Offset global) {
    final editor = _editor;
    final ctx = _bodyKey.currentContext;
    if (editor == null || ctx == null) return;
    final l = slidesL10n(ctx);
    WonkyPopupMenuHost.maybeOf(ctx)?.show(
      global,
      () => MenuResolver(
        s,
        custom: _menuItems(editor),
      ).entries(ctx, contextMenuFor(l, menuId, editor.selectionKind)),
      onClosed: () =>
          (menuId.startsWith('context.nav')
                  ? editor.navigatorFocus
                  : editor.canvasFocus)
              .requestFocus(),
    );
  }

  /// The dynamic menu slots (04 §4): the deck theme's layouts, the deck's
  /// groups and the insert pickers.
  MenuCustomItems _menuItems(DeckEditorController? editor) {
    if (editor == null) return const MenuCustomItems();
    List<WonkyMenuEntry> layouts(BuildContext context, String id, String key) {
      final r = MenuResolver(s);
      return [
        // Apply layout ▸ lists the current slide's theme (SL-17).
        for (final layout
            in id == 'slides.slide.applyLayout'
                ? galleryLayouts(editor)
                : SlideLabels.layouts(editor.model))
          ?r.commandEntry(
            context,
            id,
            args: {'layoutId': layout.id},
            label: layout.name,
            key: '$key.${layout.id}',
          ),
      ];
    }

    return MenuCustomItems(
      entries: {
        // The spelling section of the text context menu (SL-44).
        SlidesMenuIds.spellingSuggestions: (context) =>
            canvasSpellingMenu(editor),
        SlidesMenuIds.newSlideLayouts: (context) =>
            layouts(context, 'slides.slide.new', 'insert.newSlideLayout'),
        SlidesMenuIds.applyLayouts: (context) =>
            layouts(context, 'slides.slide.applyLayout', 'slide.applyLayout'),
        SlidesMenuIds.addToGroup: (context) {
          final r = MenuResolver(s);
          final l = slidesL10n(context);
          return [
            for (final g in editor.model.groups)
              ?r.commandEntry(
                context,
                'slides.group.addSlides',
                args: {'groupId': g.id},
                label: g.title.isEmpty ? l.groupUntitled : g.title,
                key: 'slide.group.addTo.${g.id}',
              ),
          ];
        },
      },
      widgets: {
        // The shape galleries (SL-14).
        SlidesMenuIds.shapeGallery: (context, close) => ShapeGallery(
          selected: ShapeInsert.geometryOf(editor.armedTool),
          onSelected: (g) {
            close();
            s.dispatcher.invoke(
              'slides.insert.shape',
              args: {'geometry': g},
              source: InvocationSource.menu,
              context: context,
            );
          },
        ),
        SlidesMenuIds.changeShapeGallery: (context, close) => ShapeGallery(
          onSelected: (g) {
            close();
            s.dispatcher.invoke(
              'slides.shape.change',
              args: {'geometry': g},
              source: InvocationSource.menu,
              context: context,
            );
          },
        ),
        SlidesMenuIds.tablePicker: (context, close) => WonkyTableSizePicker(
          onSelected: (rows, cols) {
            close();
            s.dispatcher.invoke(
              'slides.insert.table',
              args: {'rows': rows, 'cols': cols},
              source: InvocationSource.menu,
              context: context,
            );
          },
        ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final editor = _editor;
    return EditorScaffold(
      key: ValueKey<String>('slides.screen.${widget.itemUuid}'),
      services: s,
      itemUuid: widget.itemUuid,
      controller: doc,
      onItemLoaded: (item) => doc.update(title: item.name, role: item.myRole),
      syncStatus: _session?.syncStatus,
      customMenuItems: _menuItems(editor),
      titleActions: (context) => [PresentButton(services: s)],
      mobileTitleActions: (context) => [
        MobilePresentButton(services: s),
        const SizedBox(width: 6),
      ],
      // Comments (SL-38), version history (SL-39).
      commentsButton: SlidesFeatures.isOn(SlidesFeature.comments),
      commentsInPanel: SlidesFeatures.isOn(SlidesFeature.comments),
      historyPanel: SlidesFeatures.isOn(SlidesFeature.versionHistory),
      panels: editor == null ? const [] : slidesPanelSpecs(context, s, editor),
      toolbar: (context) => editor == null
          ? SizedBox(height: WonkyThemeScope.of(context).toolbarButtonSize + 8)
          : SlidesToolbar(services: s, editor: editor, controller: _toolbar),
      body: (context, item) => _body(context),
      statusLeft: (context) =>
          editor == null ? const [] : [DeckStatusLeft(editor: editor)],
      statusRight: (context) => editor == null
          ? const []
          : [DeckStatusRight(services: s, editor: editor)],
    );
  }

  Widget _body(BuildContext context) {
    final l = slidesL10n(context);
    final la = WonkyAppLocalizations.of(context);
    final err = _error;
    if (err != null) {
      return WonkyEmptyState(
        key: const ValueKey<String>('slides.openFailed'),
        illustration: EmptyIllustration.error,
        title: l.deckOpenFailed,
        description: errorMessage(err),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('slides.openFailed.retry'),
            onPressed: () {
              setState(() => _error = null);
              unawaited(_open());
            },
            child: Text(la.actionRetry),
          ),
        ],
      );
    }
    final session = _session;
    if (session == null) return const DeckLoadingView();
    return ValueListenableBuilder<DeckLoadState>(
      valueListenable: session.loadState,
      builder: (context, state, _) {
        switch (state) {
          case DeckLoading(:final progress, :final message):
            return DeckLoadingView(progress: progress, message: message);
          case DeckUnavailable(:final reason, :final offline):
            return WonkyEmptyState(
              key: const ValueKey<String>('slides.unavailable'),
              illustration: offline
                  ? EmptyIllustration.offline
                  : EmptyIllustration.error,
              title: offline ? l.deckNotAvailableOffline : l.deckUnavailable,
              description: offline ? l.deckOfflineHint : reason,
              actions: [
                ShadButton.ghost(
                  key: const ValueKey<String>('slides.unavailable.home'),
                  onPressed: () => s.dispatcher.invoke(
                    'shell.nav.home',
                    source: InvocationSource.ui,
                    context: context,
                  ),
                  child: Text(l.backToSlides),
                ),
              ],
            );
          case DeckReady():
            final editor = _editor;
            if (editor == null) return const DeckLoadingView();
            return Material(
              type: MaterialType.transparency,
              child: WonkyPopupMenuHost(
                child: KeyedSubtree(
                  key: _bodyKey,
                  // "You're presenting on …" (SL-19, Slides 10 §5.2).
                  child: PresentSessionBanner(
                    services: s,
                    itemUuid: widget.itemUuid,
                    child: DeckBody(
                      services: s,
                      editor: editor,
                      onContextMenu: _openMenu,
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
