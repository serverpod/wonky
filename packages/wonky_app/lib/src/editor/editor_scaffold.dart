import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../commands/shell_commands/general_commands.dart';
import '../comments/comments_controller.dart';
import '../comments/comments_panel.dart';
import '../data/api.dart';
import '../data/models_ext.dart';
import '../drive/details_panel.dart';
import '../l10n/wonky_app_localizations.dart';
import '../menus/menu_resolver.dart';
import '../presence/presence_session.dart';
import '../routing/misc_pages.dart';
import '../shell/account_menu.dart';
import '../shell/shell_services.dart';
import '../storage/storage_banner.dart';
import '../versions/versions_list.dart';
import '../document/document_controller.dart';
import 'package:flutter/foundation.dart';

/// The shared editor frame (suite 03 §3.1): title row, menubar, toolbar,
/// document area with the side panel host, and an optional status bar.
/// Loads the drive item, joins presence, creates the comments controller and
/// handles the no-access state.
///
/// Apps build their editor screen with it:
///
/// ```dart
/// EditorScaffold(
///   itemUuid: uuid,
///   controller: docController,          // null while loading
///   toolbar: (context) => WriteToolbar(...),
///   body: (context, item) => DocumentCanvas(...),
///   statusLeft: (context) => [WordCount(...)],
///   panels: [outlinePanel],
/// )
/// ```
class EditorScaffold extends StatefulWidget {
  const EditorScaffold({
    super.key,
    required this.services,
    required this.itemUuid,
    required this.body,
    this.controller,
    this.toolbar,
    this.statusLeft,
    this.statusRight,
    this.panels = const [],
    this.titleRowExtras,
    this.titleActions,
    this.onItemLoaded,
    this.customMenuItems = const MenuCustomItems(),
    this.syncStatus,
    this.showStatusBar = true,
    this.commentsInPanel = true,
    this.belowToolbar,
    this.commentsButton = true,
    this.historyPanel = true,
    this.mobileTitleActions,
  });

  final ShellServices services;
  final String itemUuid;

  /// The document area.
  final Widget Function(BuildContext context, DriveItemView item) body;

  /// The active document (made active by the scaffold; null while loading).
  final DocumentController? controller;

  /// Row 3 (usually a `WonkyToolbar`).
  final WidgetBuilder? toolbar;
  final List<Widget> Function(BuildContext context)? statusLeft;
  final List<Widget> Function(BuildContext context)? statusRight;

  /// App panels (outline, …) in addition to comments and history.
  final List<SidePanelSpec> panels;

  /// Extra widgets in the title row before the presence avatars.
  final List<Widget> Function(BuildContext context)? titleRowExtras;

  /// (v2) App buttons in the title row right before *Share* (Slides'
  /// *Present* split button; Slides 04 A-04-4).
  final List<Widget> Function(BuildContext context)? titleActions;

  /// Called once the drive item is known (role, name).
  final ValueChanged<DriveItemView>? onItemLoaded;

  /// Builders for `MenuSpec.custom` items of the app menus.
  final MenuCustomItems customMenuItems;

  /// Overrides the controller's sync status.
  final ValueListenable<SyncStatus>? syncStatus;

  /// Whether the title row has the comments button (Write has it in its
  /// toolbar instead).
  final bool commentsButton;

  /// A full-width strip between the toolbar and the document area (Write:
  /// the 2 px mode line, green while suggesting).
  final WidgetBuilder? belowToolbar;

  /// Whether the status bar ([statusLeft], [statusRight]) is shown.
  final bool showStatusBar;

  /// Whether comments get the comments side panel. Apps that show comments
  /// elsewhere (Write's margin) set a `CommentsHost` and pass false.
  final bool commentsInPanel;

  /// (v2) Whether the version history side panel is offered (Slides has no
  /// version history before M11).
  final bool historyPanel;

  /// App buttons in the title row of the mobile layout (suite 02 §6.1),
  /// before the account menu (Slides: *Present*).
  final List<Widget> Function(BuildContext context)? mobileTitleActions;

  @override
  State<EditorScaffold> createState() => _EditorScaffoldState();
}

class _EditorScaffoldState extends State<EditorScaffold> {
  DriveItemView? _item;
  Object? _error;
  late CommentsController _comments;
  late PresenceSession _presence;
  final _titleField = DocumentTitleFieldController();
  final _menubar = WonkyMenubarController();
  final _toolbarFocus = FocusNode(
    debugLabel: 'editor.toolbar',
    skipTraversal: true,
  );
  final _menubarFocus = FocusNode(
    debugLabel: 'editor.menubar',
    skipTraversal: true,
  );
  final _docFocus = FocusNode(
    debugLabel: 'editor.document',
    skipTraversal: true,
  );
  final _panelFocus = FocusNode(
    debugLabel: 'editor.panel',
    skipTraversal: true,
  );
  final _statusFocus = FocusNode(
    debugLabel: 'editor.status',
    skipTraversal: true,
  );
  StreamSubscription<DriveChange>? _changes;

  ShellServices get s => widget.services;
  UuidValue get _uuid => UuidValue.fromString(widget.itemUuid);

  @override
  void initState() {
    super.initState();
    _comments = CommentsController(services: s, itemUuid: _uuid);
    _presence = PresenceSession(services: s, itemUuid: _uuid);
    s.comments.value = _comments;
    s.startTitleRename = _titleField.startEditing;
    s.focusRegions
      ..clear()
      ..addAll([
        _menubarFocus,
        _toolbarFocus,
        _docFocus,
        _panelFocus,
        _statusFocus,
      ]);
    _changes = s.driveChanges.listen((c) {
      if (c.itemUuid == _uuid && c.item != null) _setItem(c.item!);
    });
    s.currentItem.addListener(_onCurrentItem);
    unawaited(_load());
    _activateAfterBuild();
  }

  /// Activating notifies shell listeners (undo, command state, active
  /// document); doing that from initState/didUpdateWidget marked other
  /// widgets dirty during the build (found by the E2E journeys).
  void _activateAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _activate();
    });
  }

  void _activate() {
    final c = widget.controller;
    if (c == null) return;
    s.activate(c);
    _comments.anchors = c.commentAnchors;
    c.attachPresence(_presence);
  }

  @override
  void didUpdateWidget(EditorScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final old = oldWidget.controller;
      old?.attachPresence(null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (old != null) s.deactivate(old);
      });
      _activateAfterBuild();
    }
  }

  void _onCurrentItem() {
    final v = s.currentItem.value;
    if (v != null && v.uuid == _uuid && v != _item && mounted) {
      setState(() => _item = v);
    }
  }

  void _setItem(DriveItemView v) {
    if (!mounted) return;
    setState(() => _item = v);
    if (s.currentItem.value != v) s.currentItem.value = v;
  }

  Future<void> _load() async {
    try {
      final v = await s.drive.markOpened(_uuid);
      // Left before the item loaded: starting presence/comments now would
      // leave zombie streams (and could replace a reopened editor's ones).
      if (!mounted) return;
      _setItem(v);
      widget.onItemLoaded?.call(v);
      unawaited(_comments.start());
      _presence.mode = v.canEdit ? 'editing' : 'viewing';
      _presence.start();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    s.currentItem.removeListener(_onCurrentItem);
    final controller = widget.controller;
    if (controller != null) {
      // Not while the tree is locked (see [_activateAfterBuild]); a no-op
      // when another editor activated in the meantime.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => s.deactivate(controller),
      );
    }
    controller?.attachPresence(null);
    if (s.comments.value == _comments) s.comments.value = null;
    if (s.startTitleRename == _titleField.startEditing) {
      s.startTitleRename = null;
    }
    s.focusRegions.removeWhere(
      (f) => [
        _menubarFocus,
        _toolbarFocus,
        _docFocus,
        _panelFocus,
        _statusFocus,
      ].contains(f),
    );
    if (s.currentItem.value?.uuid == _uuid) s.currentItem.value = null;
    _comments.dispose();
    _presence.dispose();
    _menubar.dispose();
    for (final f in [
      _toolbarFocus,
      _menubarFocus,
      _docFocus,
      _panelFocus,
      _statusFocus,
    ]) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _rename(String name) => s.dispatcher.invoke(
    'shell.drive.rename',
    args: {'uuid': widget.itemUuid, 'name': name},
    source: InvocationSource.ui,
  );

  void _invoke(String id, [Map<String, Object?> args = const {}]) => s
      .dispatcher
      .invoke(id, args: args, source: InvocationSource.ui, context: context)
      .catchError((Object e) {
        s.toasts.error(
          s.l10n?.commandFailed(id) ?? id,
          description: errorMessage(e),
        );
        return const CommandResult.failed('error');
      });

  bool _isNoAccess(Object e) =>
      e is WonkyException &&
      (e.code == WonkyErrorCode.forbidden || e.code == WonkyErrorCode.notFound);

  DocumentController? _readOnlyController;
  bool _readOnlyView = false;

  /// Tells the controller when the mobile layout starts or ends (suite 02
  /// §6.1). After the frame: apps notify their listeners.
  void _syncReadOnlyView(bool mobile) {
    final c = widget.controller;
    if (c == null || (c == _readOnlyController && mobile == _readOnlyView)) {
      return;
    }
    final changed = c != _readOnlyController ? mobile : true;
    _readOnlyController = c;
    _readOnlyView = mobile;
    if (!changed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.controller == c && _readOnlyView == mobile) {
        c.setReadOnlyView(mobile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final mobile = WonkyLayout.isMobile(context);
    _syncReadOnlyView(mobile);
    final err = _error;
    if (err != null) {
      if (_isNoAccess(err)) {
        return NoAccessPage(services: s, itemUuid: widget.itemUuid);
      }
      return ColoredBox(
        color: theme.colorScheme.background,
        child: WonkyEmptyState(
          illustration: isOfflineError(err)
              ? EmptyIllustration.offline
              : EmptyIllustration.error,
          title: isOfflineError(err) ? l.editorOfflineTitle : l.errorGeneric,
          description: errorMessage(err),
          actions: [
            ShadButton.outline(
              onPressed: () {
                setState(() => _error = null);
                _load();
              },
              child: Text(l.actionRetry),
            ),
            ShadButton.ghost(
              onPressed: () => s.router.go('/'),
              child: Text(l.goHome),
            ),
          ],
        ),
      );
    }
    final item = _item;
    return Listener(
      onPointerDown: (_) => _presence.activity(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, _) {
          _presence.activity();
          return KeyEventResult.ignored;
        },
        // Not rebuilt from command-state signals (CQ-39): only the menubar
        // (an open menu shows enabled/checked states) listens to the
        // registry; the toolbar, panels and status widgets listen to what
        // they show, and the document body never rebuilds from the shell.
        child: Builder(
          builder: (context) {
            if (mobile) return _mobileLayout(context, item);
            final statusLeft = widget.statusLeft?.call(context) ?? const [];
            final statusRight = widget.statusRight?.call(context) ?? const [];
            final panels = [
              if (widget.commentsInPanel)
                SidePanelSpec(
                  id: ShellPanels.comments,
                  title: l.panelComments,
                  icon: LucideIcons.messageSquare,
                  builder: (_) =>
                      CommentsPanel(services: s, controller: _comments),
                ),
              SidePanelSpec(
                id: ShellPanels.details,
                title: l.cmdDetails,
                icon: LucideIcons.info,
                // Opened from File › Details, not a tab (Write 05 §10).
                showAsTab: false,
                builder: (_) => DriveDetailsPanel(services: s, item: _item),
              ),
              // App panels first, then history; all of them are icons in
              // the rail (suite 03 §3.1), so the title row has no buttons
              // for them.
              ...widget.panels,
              if (widget.historyPanel && (item?.myRole.canViewHistory ?? false))
                SidePanelSpec(
                  id: ShellPanels.history,
                  title: l.panelHistory,
                  icon: LucideIcons.history,
                  builder: (_) => _VersionsPanel(services: s, itemUuid: _uuid),
                ),
            ];
            return ColoredBox(
              color: theme.colorScheme.background,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _titleRow(context, item),
                  Focus(
                    focusNode: _menubarFocus,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 52),
                      child: ListenableBuilder(
                        listenable: s.registry,
                        builder: (context, _) => WonkyMenubar(
                          controller: _menubar,
                          menus: MenuResolver(
                            s,
                            custom: _customItems(),
                          ).menubar(context, s.menuRoot(context)),
                        ),
                      ),
                    ),
                  ),
                  if (widget.toolbar != null)
                    Focus(
                      focusNode: _toolbarFocus,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.muted.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: widget.toolbar!(context),
                      ),
                    ),
                  ?widget.belowToolbar?.call(context),
                  // Drive 03 §6.2: only for items the user owns.
                  StorageBanner(
                    services: s,
                    place: StorageBannerPlace.editor,
                    item: item,
                  ),
                  Expanded(
                    child: WonkySplitView(
                      controller: s.panels,
                      panels: [
                        for (final p in panels)
                          SidePanelSpec(
                            id: p.id,
                            title: p.title,
                            icon: p.icon,
                            headerActions: p.headerActions,
                            showAsTab: p.showAsTab,
                            builder: (c) => Focus(
                              focusNode: _panelFocus,
                              child: p.builder(c),
                            ),
                          ),
                      ],
                      child: Focus(
                        focusNode: _docFocus,
                        child: item == null || widget.controller == null
                            ? LoadingShimmer.documentPage()
                            : _trashedBanner(
                                context,
                                item,
                                widget.body(context, item),
                              ),
                      ),
                    ),
                  ),
                  if (widget.showStatusBar &&
                      (statusLeft.isNotEmpty || statusRight.isNotEmpty))
                    Focus(
                      focusNode: _statusFocus,
                      child: StatusBar(left: statusLeft, right: statusRight),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// The mobile layout (suite 02 §6.1): a compact title row and the
  /// document, read-only — no menubar, toolbar, side panels or status bar.
  Widget _mobileLayout(BuildContext context, DriveItemView? item) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final controller = widget.controller;
    return ColoredBox(
      key: const ValueKey<String>('editor.mobile'),
      color: theme.colorScheme.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Row(
                children: [
                  _homeButton(l, size: 32),
                  const SizedBox(width: 4),
                  Expanded(
                    child: DocumentTitleField(
                      key: const ValueKey<String>('editor.title'),
                      title: item?.name ?? '',
                      placeholder: s.config.untitledName(context),
                      controller: _titleField,
                      readOnly: true,
                      onRename: _rename,
                    ),
                  ),
                  if (controller != null)
                    ValueListenableBuilder<SyncStatus>(
                      valueListenable:
                          widget.syncStatus ?? controller.syncStatus,
                      builder: (context, st, _) => SyncStatusIndicator(
                        status: st,
                        compact: true,
                        onRetry: controller.retrySync,
                      ),
                    ),
                  if (item != null) ...[
                    const SizedBox(width: 4),
                    ShadBadge.secondary(
                      key: const ValueKey<String>('editor.mobile.readOnly'),
                      child: Text(l.badgeViewOnly),
                    ),
                  ],
                  const SizedBox(width: 4),
                  ...?widget.mobileTitleActions?.call(context),
                  AccountMenuButton(services: s),
                ],
              ),
            ),
          ),
          StorageBanner(
            services: s,
            place: StorageBannerPlace.editor,
            item: item,
          ),
          Expanded(
            child: Focus(
              focusNode: _docFocus,
              child: item == null || controller == null
                  ? LoadingShimmer.documentPage()
                  : _trashedBanner(context, item, widget.body(context, item)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _homeButton(WonkyAppLocalizations l, {double size = 36}) =>
      ShadTooltip(
        builder: (_) => Text(l.cmdHome),
        // A labelled button for screen readers (the logo has no text).
        child: Semantics(
          button: true,
          label: l.cmdHome,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey<String>('editor.home'),
            onTap: () => _invoke('shell.nav.home'),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: s.config.logo(size: size),
              ),
            ),
          ),
        ),
      );

  MenuCustomItems _customItems() {
    final doc = widget.controller;
    return MenuCustomItems(
      widgets: widget.customMenuItems.widgets,
      entries: {
        ...widget.customMenuItems.entries,
        'file.download.formats': (context) => [
          for (final f in doc?.downloadFormats ?? const <DownloadFormat>[])
            WonkyMenuItem(
              key: ValueKey<String>('menu.download.${f.id}'),
              label: f.label,
              enabled: s.currentItem.value?.canDownload ?? false,
              onSelected: () =>
                  _invoke('shell.file.download', {'format': f.id}),
            ),
        ],
      },
    );
  }

  Widget _trashedBanner(BuildContext context, DriveItemView item, Widget body) {
    if (!item.isTrashed) return body;
    final l = WonkyAppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: ShadAlert(
            icon: const Icon(LucideIcons.trash2),
            title: Text(l.trashedBanner),
            description: Align(
              alignment: Alignment.centerLeft,
              child: ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: () =>
                    _invoke('shell.drive.restore', {'uuid': item.uuid.uuid}),
                child: Text(l.cmdRestore),
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  Widget _titleRow(BuildContext context, DriveItemView? item) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final role = item?.myRole ?? Role.viewer;
    final narrow = MediaQuery.sizeOf(context).width < 720;
    Widget icon(
      String key,
      IconData i,
      String label,
      VoidCallback? onPressed, {
      Color? color,
    }) => ShadTooltip(
      builder: (_) => Text(label),
      child: ShadIconButton.ghost(
        key: ValueKey<String>(key),
        width: 32,
        height: 32,
        iconSize: 18,
        semanticLabel: label,
        enabled: onPressed != null,
        icon: Icon(i, color: color),
        onPressed: onPressed,
      ),
    );
    return SizedBox(
      height: WonkyThemeScope.of(context).titleRowHeight + 8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
        child: Row(
          children: [
            _homeButton(l),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: DocumentTitleField(
                          key: const ValueKey<String>('editor.title'),
                          title: item?.name ?? '',
                          placeholder: s.config.untitledName(context),
                          controller: _titleField,
                          readOnly: !(item?.canManage ?? false),
                          onRename: _rename,
                        ),
                      ),
                      // Below 480 px Star and Move stay in the File menu
                      // (the title row must not overflow at 360 px, Slides
                      // 04 §16).
                      if (item != null &&
                          MediaQuery.sizeOf(context).width >= 480) ...[
                        icon(
                          'editor.star',
                          item.starred ? LucideIcons.star : LucideIcons.star,
                          item.starred ? l.cmdUnstar : l.cmdStar,
                          () => _invoke('shell.drive.setStarred', {
                            'uuid': item.uuid.uuid,
                            'starred': !item.starred,
                          }),
                          color: item.starred
                              ? theme.colorScheme.warning
                              : null,
                        ),
                        icon(
                          'editor.move',
                          LucideIcons.folderInput,
                          l.cmdMove,
                          item.canManage
                              ? () => _invoke('shell.drive.move', {
                                  'uuid': item.uuid.uuid,
                                })
                              : null,
                        ),
                      ],
                      if (widget.controller != null)
                        ValueListenableBuilder<SyncStatus>(
                          valueListenable:
                              widget.syncStatus ??
                              widget.controller!.syncStatus,
                          builder: (context, st, _) => SyncStatusIndicator(
                            status: st,
                            compact: narrow,
                            onRetry: widget.controller!.retrySync,
                          ),
                        ),
                      if (role < Role.editor && item != null) ...[
                        const SizedBox(width: 6),
                        ShadBadge.secondary(
                          child: Text(
                            role == Role.commenter
                                ? l.badgeCommentOnly
                                : l.badgeViewOnly,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ...?widget.titleRowExtras?.call(context),
            ListenableBuilder(
              listenable: _presence,
              builder: (context, _) => PresenceAvatarStack(
                participants: _presence.avatars(),
                onJumpTo: (p) => widget.controller?.revealParticipant(
                  p.sessionId,
                  userId: int.tryParse(p.userKey),
                ),
                onFollow: (p) =>
                    widget.controller?.followParticipant(p.sessionId),
              ),
            ),
            const SizedBox(width: 8),
            // *Report a bug* and *Suggest an improvement* (specs/16 §4.1):
            // outline buttons, icons only below 1200 px, hidden below `sm`
            // (still in Help).
            if (MediaQuery.sizeOf(context).width >= 640)
              for (final (key, icon, label, kind) in [
                ('editor.reportBug', LucideIcons.bug, l.boardReportBug, 'bug'),
                (
                  'editor.suggest',
                  LucideIcons.leaf,
                  l.boardSuggestImprovement,
                  'idea',
                ),
              ]) ...[
                if (MediaQuery.sizeOf(context).width >= 1200)
                  ShadButton.outline(
                    key: ValueKey<String>(key),
                    size: ShadButtonSize.sm,
                    leading: Icon(icon, size: 16),
                    onPressed: () =>
                        _invoke('shell.board.report', {'kind': kind}),
                    child: Text(label),
                  )
                else
                  ShadTooltip(
                    builder: (_) => Text(label),
                    child: ShadIconButton.outline(
                      key: ValueKey<String>(key),
                      width: 32,
                      height: 32,
                      iconSize: 16,
                      semanticLabel: label,
                      icon: Icon(icon),
                      onPressed: () =>
                          _invoke('shell.board.report', {'kind': kind}),
                    ),
                  ),
                const SizedBox(width: 6),
              ],
            if (widget.commentsButton)
              ListenableBuilder(
                listenable: _comments,
                // Merged so the tap target carries the label (and the count).
                builder: (context, _) => MergeSemantics(
                  child: Semantics(
                    label: l.cmdCommentsPanel,
                    child: ShadTooltip(
                      builder: (_) => Text(l.cmdCommentsPanel),
                      child: ShadButton.ghost(
                        key: const ValueKey<String>('editor.comments'),
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        leading: const Icon(
                          LucideIcons.messageSquare,
                          size: 18,
                        ),
                        onPressed: () => _invoke('shell.comments.togglePanel'),
                        child: _comments.openCount == 0
                            ? null
                            : Text('${_comments.openCount}'),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 6),
            ...?widget.titleActions?.call(context),
            if (item != null)
              ShadButton(
                key: const ValueKey<String>('editor.share'),
                leading: Icon(
                  item.linkRole != null
                      ? LucideIcons.globe
                      : (item.shared ? LucideIcons.users : LucideIcons.lock),
                  size: 16,
                ),
                onPressed: () =>
                    _invoke('shell.sharing.open', {'uuid': item.uuid.uuid}),
                child: Text(l.shareButton),
              ),
            const SizedBox(width: 10),
            AccountMenuButton(services: s),
          ],
        ),
      ),
    );
  }
}

class _VersionsPanel extends StatefulWidget {
  const _VersionsPanel({required this.services, required this.itemUuid});

  final ShellServices services;
  final UuidValue itemUuid;

  @override
  State<_VersionsPanel> createState() => _VersionsPanelState();
}

class _VersionsPanelState extends State<_VersionsPanel> {
  late final VersionsController c = VersionsController(
    widget.services,
    widget.itemUuid,
  )..load();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => VersionsList(
    controller: c,
    onOpenFull: widget.services.config.versionRenderer == null
        ? null
        : () => widget.services.dispatcher.invoke(
            'shell.versions.open',
            source: InvocationSource.ui,
          ),
  );
}
