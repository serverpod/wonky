import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../branding/product_icon.dart';
import '../commands/keymap_service.dart';
import '../commands/shell_commands/general_commands.dart';
import '../config/home_scope.dart';
import '../config/wonky_app_config.dart';
import '../data/api.dart';
import '../l10n/wonky_app_localizations.dart';
import '../menus/menu_resolver.dart';
import '../shell/shell_services.dart';
import '../storage/storage_banner.dart';
import 'details_panel.dart';
import 'drive_format.dart';
import 'drive_controller.dart';
import 'drive_location.dart';
import 'home_sidebar.dart';
import 'item_actions.dart';
import 'template_gallery.dart';
import 'top_bar.dart';
import 'item_list.dart';

/// Home and every drive view (suite 05 §3): top bar, sidebar, template strip,
/// filter / selection bar, list or grid, details panel.
class DriveHomeScreen extends StatefulWidget {
  const DriveHomeScreen({
    super.key,
    required this.services,
    required this.location,
  });

  final ShellServices services;
  final DriveLocation location;

  @override
  State<DriveHomeScreen> createState() => _DriveHomeScreenState();
}

class _DriveHomeScreenState extends State<DriveHomeScreen> {
  late final DriveController c = DriveController(
    services: widget.services,
    location: widget.location,
  );
  final _listFocus = FocusNode(debugLabel: 'drive.list');
  final _searchFocus = FocusNode(debugLabel: 'drive.search');
  final _sidebarFocus = FocusNode(
    debugLabel: 'drive.sidebar',
    skipTraversal: true,
  );
  final _topFocus = FocusNode(debugLabel: 'drive.top', skipTraversal: true);
  bool _sidebarOpen = true;
  bool _dropping = false;

  /// The folder row/card an OS file drag hovers (Drive: drops upload
  /// into it, Drive 04 §3.5).
  final _osDropFolder = ValueNotifier<UuidValue?>(null);
  String? _osDropFolderName;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    s.creatingFile.value = false;
    unawaited(c.reload());
    s.focusRegions
      ..clear()
      ..addAll([_topFocus, _sidebarFocus, _listFocus]);
    s.driveSearchFocus = _searchFocus;
    s.currentItem.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _listFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(DriveHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) c.setLocation(widget.location);
  }

  @override
  void dispose() {
    s.focusRegions.removeWhere(
      (f) => f == _topFocus || f == _sidebarFocus || f == _listFocus,
    );
    if (s.driveSearchFocus == _searchFocus) s.driveSearchFocus = null;
    c.dispose();
    _osDropFolder.dispose();
    _listFocus.dispose();
    _searchFocus.dispose();
    _sidebarFocus.dispose();
    _topFocus.dispose();
    super.dispose();
  }

  String _title(WonkyAppLocalizations l) => switch (widget.location.kind) {
    // App homes call `/` *Recent* (suite 03 §3.3).
    DriveLocationKind.home =>
      s.config.homeScope?.kind != null ? l.navRecent : l.navHome,
    DriveLocationKind.myDrive => homeNavLabel(
      l,
      HomeNavDestination.myFiles,
      scope: s.config.homeScope,
    ).$2,
    DriveLocationKind.folder => c.folder?.name ?? '',
    DriveLocationKind.shared => l.navShared,
    DriveLocationKind.starred => l.navStarred,
    DriveLocationKind.recent => l.navRecent,
    DriveLocationKind.offline => l.navOffline,
    DriveLocationKind.trash => l.navTrash,
    DriveLocationKind.search => l.searchResultsFor(widget.location.query ?? ''),
  };

  /// Whether this home uploads any file (Drive) instead of importing its
  /// convertible types.
  bool get _uploadsFiles => s.config.homeScope?.uploadsFiles ?? false;

  void _onDragUpdated(DropEventDetails d) {
    if (!_uploadsFiles) return;
    final folder = osDropFolderAt(context, d.globalPosition);
    if (_osDropFolder.value == folder?.uuid) return;
    setState(() {
      _osDropFolder.value = folder?.uuid;
      _osDropFolderName = folder?.name;
    });
  }

  void _endDrag() => setState(() {
    _dropping = false;
    _osDropFolder.value = null;
    _osDropFolderName = null;
  });

  /// Drop overlay text: "Upload to Designs" over a folder row, else
  /// "Drop files to upload to Team" (Drive 04 §3.5).
  String _dropLabel(WonkyAppLocalizations l) {
    if (!_uploadsFiles) return l.dropToUpload;
    final hovered = _osDropFolderName;
    if (hovered != null) return l.dropUploadToFolder(hovered);
    final target =
        c.folder?.name ??
        homeNavLabel(
          l,
          HomeNavDestination.myFiles,
          scope: s.config.homeScope,
        ).$2;
    return l.dropToUploadInto(target);
  }

  /// Files of a drop; folders (Drive) become [ImportFile.folderPath]s.
  Future<List<ImportFile>> _dropFiles(
    List<DropItem> items,
    ImportHandler handler,
  ) async {
    final files = <ImportFile>[];
    Future<void> add(DropItem f, List<String> path) async {
      if (f is DropItemDirectory) {
        if (!_uploadsFiles) return;
        for (final child in f.children) {
          await add(child, [...path, f.name]);
        }
        return;
      }
      final name = f.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
      if (!_uploadsFiles && !handler.extensions.contains(ext)) return;
      DateTime? modified;
      try {
        modified = await f.lastModified();
      } on Object {
        modified = null;
      }
      files.add(
        ImportFile(
          name: name,
          bytes: await f.readAsBytes(),
          mimeType: f.mimeType,
          lastModified: modified,
          folderPath: path,
        ),
      );
    }

    for (final f in items) {
      await add(f, const []);
    }
    return files;
  }

  Future<void> _onDrop(DropDoneDetails d) async {
    final folder = _uploadsFiles
        ? osDropFolderAt(context, d.globalPosition)
        : null;
    _endDrag();
    final handler = s.config.importHandler;
    if (handler == null || (folder == null && !c.canCreateHere)) return;
    final files = await _dropFiles(d.files, handler);
    if (!mounted) return;
    if (files.isEmpty) {
      s.toasts.show(WonkyAppLocalizations.of(context).importUnsupported);
      return;
    }
    try {
      final items = await handler.importFiles(
        context,
        s,
        files,
        parentUuid: folder?.uuid ?? c.folder?.uuid,
      );
      for (final v in items) {
        s.emitDriveChange(
          DriveChange(kind: DriveChangeKind.created, itemUuid: v.uuid, item: v),
        );
      }
    } catch (e) {
      s.toasts.error(
        s.l10n?.importFailed ?? 'Error',
        description: errorMessage(e),
      );
    }
  }

  /// Below `md` the left menu is a drawer (Drive 04 §2).
  Future<void> _openDrawer() => showShadSheet<void>(
    context: context,
    side: ShadSheetSide.left,
    barrierLabel: WonkyAppLocalizations.of(context).actionClose,
    builder: (sheetContext) => ShadSheet(
      key: const ValueKey<String>('home.drawer'),
      closeIcon: ShadIconButton.ghost(
        key: const ValueKey<String>('home.drawer.close'),
        width: 32,
        height: 32,
        iconSize: 16,
        semanticLabel: WonkyAppLocalizations.of(sheetContext).actionClose,
        icon: const Icon(LucideIcons.x),
        onPressed: () => Navigator.of(sheetContext).maybePop(),
      ),
      scrollable: false,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(maxWidth: HomeSidebar.width + 8),
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height,
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: HomeSidebar(
            services: s,
            location: widget.location,
            onNavigate: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 768;
    final sidebarVisible = _sidebarOpen && !narrow;
    final scope = s.config.homeScope;
    final main = ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        // Not in the mobile layout (suite 02 §6.1, T-12): phones only read.
        final showTemplates =
            !WonkyLayout.isMobile(context) &&
            (scope?.showsTemplateStrip ?? true) &&
            (widget.location.kind == DriveLocationKind.home ||
                widget.location.kind == DriveLocationKind.myDrive);
        return LayoutBuilder(
          // Short windows (phones in landscape, 360 px drawers) skip the
          // template strip: *+ New ▸ From template…* stays.
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTemplates && box.maxHeight >= 560)
                TemplateStrip(services: s),
              _Header(controller: c, services: s, title: _title(l)),
              Expanded(child: _body(context, l)),
            ],
          ),
        );
      },
    );
    return ColoredBox(
      color: theme.colorScheme.background,
      child: KeymapScope(
        scope: KeyScope.drive,
        keymap: s.keymap,
        child: Column(
          children: [
            Focus(
              focusNode: _topFocus,
              child: WonkyTopBar(
                services: s,
                searchFocus: _searchFocus,
                initialQuery: widget.location.query,
                onToggleSidebar: narrow
                    ? _openDrawer
                    : () => setState(() => _sidebarOpen = !_sidebarOpen),
                // Search starts where the content does (sidebar + the
                // content's 20 px inset).
                contentStart: sidebarVisible ? HomeSidebar.width + 20 : null,
                showNewButton: !sidebarVisible && showsSidebarNewButton(scope),
              ),
            ),
            // Drive 03 §6.2: ≥ 90 % and over quota (not dismissible here).
            StorageBanner(services: s),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sidebarVisible)
                    Focus(
                      focusNode: _sidebarFocus,
                      child: HomeSidebar(
                        services: s,
                        location: widget.location,
                      ),
                    ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: narrow ? 0 : 12,
                        bottom: narrow ? 0 : 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.card,
                        borderRadius: narrow ? null : BorderRadius.circular(16),
                        border: narrow
                            ? null
                            : Border.all(color: theme.colorScheme.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: WonkySplitView(
                        controller: s.panels,
                        // One panel: closing hides it (no icon rail).
                        rail: false,
                        panels: [
                          SidePanelSpec(
                            id: ShellPanels.details,
                            title: l.cmdDetails,
                            icon: LucideIcons.info,
                            builder: (_) => SelectionDetailsPanel(services: s),
                          ),
                        ],
                        child: DropTarget(
                          onDragEntered: (_) =>
                              setState(() => _dropping = true),
                          onDragUpdated: _onDragUpdated,
                          onDragExited: (_) => _endDrag(),
                          onDragDone: _onDrop,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: DriveOsDropScope(
                                  hovered: _osDropFolder,
                                  child: main,
                                ),
                              ),
                              if (_dropping)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.06),
                                        border: Border.all(
                                          color: theme.colorScheme.ring,
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _dropLabel(l),
                                          key: const ValueKey<String>(
                                            'drive.dropOverlay',
                                          ),
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.large,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WonkyAppLocalizations l) {
    if (c.loading && c.items.isEmpty) {
      // Clipped: the placeholder rows may be taller than a short window.
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          maxHeight: double.infinity,
          child: LoadingShimmer.driveList(),
        ),
      );
    }
    if (c.error != null && c.items.isEmpty) {
      final offline = isOfflineError(c.error!);
      return WonkyEmptyState(
        illustration: offline
            ? EmptyIllustration.offline
            : EmptyIllustration.error,
        title: offline ? l.driveOfflineTitle : l.errorGeneric,
        description: offline ? l.driveOfflineBody : errorMessage(c.error!),
        actions: [
          ShadButton.outline(onPressed: c.reload, child: Text(l.actionRetry)),
        ],
      );
    }
    if (c.items.isEmpty) return _empty(context, l);
    return DriveItemsView(controller: c, services: s, focusNode: _listFocus);
  }

  Widget _empty(BuildContext context, WonkyAppLocalizations l) {
    final (ill, title, desc) = switch (widget.location.kind) {
      DriveLocationKind.starred => (
        EmptyIllustration.starred,
        l.emptyStarredTitle,
        l.emptyStarredBody,
      ),
      DriveLocationKind.shared => (
        EmptyIllustration.shared,
        l.emptySharedTitle,
        l.emptySharedBody,
      ),
      DriveLocationKind.trash => (
        EmptyIllustration.trash,
        l.emptyTrashViewTitle,
        l.emptyTrashViewBody,
      ),
      DriveLocationKind.offline => (
        EmptyIllustration.offline,
        l.emptyOfflineTitle,
        l.emptyOfflineBody,
      ),
      DriveLocationKind.search => (
        EmptyIllustration.search,
        l.emptySearchTitle,
        l.emptySearchBody,
      ),
      DriveLocationKind.folder => (
        EmptyIllustration.folder,
        l.emptyFolderTitle,
        l.emptyFolderBody,
      ),
      // (v2) Scoped homes name the app and its kind (D-16).
      _ => switch (s.config.homeScope) {
        null => (
          EmptyIllustration.documents,
          l.emptyHomeTitle,
          l.emptyHomeBody,
        ),
        final scope => (
          EmptyIllustration.documents,
          l.emptyAppHomeTitle(s.config.appName),
          l.emptyAppHomeBody(scope.kind?.name ?? 'all'),
        ),
      },
    };
    final r = MenuResolver(s);
    final newEntry = r.commandEntry(
      context,
      'shell.file.new',
      key: 'empty.new',
    );
    // Drive: *Upload files* in My Drive and folders (Drive 04 §3.8).
    final uploadEntry =
        _uploadsFiles &&
            c.canCreateHere &&
            (widget.location.kind == DriveLocationKind.folder ||
                widget.location.kind == DriveLocationKind.myDrive)
        ? r.commandEntry(context, 'shell.drive.upload', key: 'empty.upload')
        : null;
    return WonkyEmptyState(
      key: const ValueKey<String>('drive.empty'),
      illustration: ill,
      title: title,
      description: desc,
      actions: [
        if (c.canCreateHere &&
            newEntry != null &&
            widget.location.kind != DriveLocationKind.trash)
          ListenableBuilder(
            listenable: s.creatingFile,
            builder: (context, _) {
              final creating = s.creatingFile.value;
              return ShadButton(
                key: const ValueKey<String>('drive.empty.new'),
                leading: creating
                    ? const SizedBox.square(
                        dimension: 16,
                        child: ShadSpinner(size: 16),
                      )
                    : const Icon(LucideIcons.plus, size: 16),
                onPressed: creating
                    ? null
                    : () async {
                        try {
                          await s.dispatcher.invoke(
                            'shell.file.new',
                            source: InvocationSource.menu,
                            context: context,
                          );
                        } catch (_) {}
                      },
                child: Text(newEntry.label),
              );
            },
          ),
        if (uploadEntry != null)
          ShadButton.outline(
            key: const ValueKey<String>('drive.empty.upload'),
            leading: const Icon(LucideIcons.upload, size: 16),
            onPressed: uploadEntry.onSelected,
            child: Text(uploadEntry.label),
          ),
      ],
    );
  }
}

/// Breadcrumb/title + filter bar, or the selection action bar.
class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.services,
    required this.title,
  });

  final DriveController controller;
  final ShellServices services;
  final String title;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    final c = controller;
    final sel = c.selection;
    void run(String id, [Map<String, Object?> args = const {}]) =>
        services.dispatcher.invoke(
          id,
          args: args,
          source: InvocationSource.toolbar,
          context: context,
        );
    Widget cmdIcon(String id, IconData icon, String label, {String? key}) {
      final st = services.dispatcher.stateOf(id);
      return ShadTooltip(
        builder: (_) => Text(label),
        child: ShadIconButton.ghost(
          key: ValueKey<String>(key ?? 'drive.selection.${id.split('.').last}'),
          width: 32,
          height: 32,
          iconSize: 16,
          semanticLabel: label,
          enabled: st.enabled,
          icon: Icon(icon),
          onPressed: () => run(id),
        ),
      );
    }

    final titleRow = Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: c.location.kind == DriveLocationKind.folder
                ? _Breadcrumb(controller: c, services: services)
                : Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.h4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
          if (c.scope?.kind != null)
            _OpenInDriveButton(
              compact: MediaQuery.sizeOf(context).width < 640,
              onPressed: () => run('shell.nav.openInDrive', {
                if (c.folder != null) 'folderUuid': c.folder!.uuid.uuid,
              }),
            ),
          if (c.location.isTrash && c.items.isNotEmpty)
            ShadButton.outline(
              key: const ValueKey<String>('drive.emptyTrash'),
              size: ShadButtonSize.sm,
              onPressed: () => run('shell.drive.emptyTrash'),
              child: Text(l.cmdEmptyTrash),
            ),
          // Phones show the list only (suite 02 §6.1, T-12).
          if (!WonkyLayout.isMobile(context))
            ShadTooltip(
              builder: (_) => Text(
                c.layout == DriveLayout.list ? l.layoutGrid : l.layoutList,
              ),
              child: ShadIconButton.ghost(
                key: const ValueKey<String>('drive.layout'),
                semanticLabel: c.layout == DriveLayout.list
                    ? l.layoutGrid
                    : l.layoutList,
                icon: Icon(
                  c.layout == DriveLayout.list
                      ? LucideIcons.layoutGrid
                      : LucideIcons.list,
                  size: 18,
                ),
                onPressed: () => c.setLayout(
                  c.layout == DriveLayout.list
                      ? DriveLayout.grid
                      : DriveLayout.list,
                ),
              ),
            ),
          ShadTooltip(
            builder: (_) => Text(l.cmdDetails),
            child: ShadIconButton.ghost(
              key: const ValueKey<String>('drive.details'),
              semanticLabel: l.cmdDetails,
              icon: const Icon(LucideIcons.info, size: 18),
              onPressed: () => run('shell.file.details'),
            ),
          ),
        ],
      ),
    );

    Widget bar;
    if (sel.isNotEmpty) {
      final trash = c.location.isTrash;
      bar = Container(
        key: const ValueKey<String>('drive.selectionBar'),
        margin: const EdgeInsets.fromLTRB(12, 2, 12, 6),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            ShadIconButton.ghost(
              key: const ValueKey<String>('drive.selection.clear'),
              width: 32,
              height: 32,
              iconSize: 16,
              semanticLabel: l.actionClear,
              icon: const Icon(LucideIcons.x),
              onPressed: c.clearSelection,
            ),
            Text(l.selectedCount(sel.length), style: theme.textTheme.small),
            const SizedBox(width: 12),
            // Scrolls on phones (360 px) instead of overflowing.
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey<String>('drive.selectionBar.actions'),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (trash) ...[
                      cmdIcon(
                        'shell.drive.restore',
                        LucideIcons.archiveRestore,
                        l.cmdRestore,
                      ),
                      cmdIcon(
                        'shell.drive.deleteForever',
                        LucideIcons.trash,
                        l.cmdDeleteForever,
                      ),
                    ] else ...[
                      cmdIcon(
                        'shell.sharing.open',
                        LucideIcons.userPlus,
                        l.cmdShare,
                      ),
                      cmdIcon(
                        'shell.drive.move',
                        LucideIcons.folderInput,
                        l.cmdMove,
                      ),
                      cmdIcon(
                        'shell.drive.copy',
                        LucideIcons.copy,
                        l.cmdMakeCopy,
                      ),
                      cmdIcon(
                        'shell.drive.setStarred',
                        LucideIcons.star,
                        l.cmdStar,
                      ),
                      if (sel.length == 1)
                        cmdIcon(
                          'shell.drive.rename',
                          LucideIcons.pencil,
                          l.cmdRename,
                        ),
                      cmdIcon(
                        'shell.drive.trash',
                        LucideIcons.trash2,
                        l.cmdMoveToTrash,
                      ),
                      // Only what the icons above don't already offer.
                      WonkyDropdownMenu(
                        entries: () => itemMenuEntries(
                          context,
                          services,
                          trash: false,
                          exclude: {
                            'shell.sharing.open',
                            'shell.drive.move',
                            'shell.drive.copy',
                            'shell.drive.setStarred',
                            if (sel.length == 1) 'shell.drive.rename',
                            'shell.drive.trash',
                          },
                        ),
                        builder: (context, ctl) => ShadIconButton.ghost(
                          width: 32,
                          height: 32,
                          iconSize: 16,
                          semanticLabel: l.moreActions,
                          icon: const Icon(LucideIcons.ellipsisVertical),
                          onPressed: ctl.toggle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      String typeLabel(DriveTypeFilter t, [FileCategory? cat]) => switch (t) {
        DriveTypeFilter.primary =>
          services.config.primaryKind == DriveItemKind.document
              ? l.typeDocuments
              : l.typeSpreadsheets,
        DriveTypeFilter.documents => l.typeDocuments,
        DriveTypeFilter.spreadsheets => l.typeSpreadsheets,
        DriveTypeFilter.presentations => l.typePresentations,
        DriveTypeFilter.folders => l.typeFolders,
        DriveTypeFilter.files =>
          cat == null ? l.typeFiles : fileCategoryLabel(l, cat),
        DriveTypeFilter.all => l.typeAll,
      };
      final scope = c.scope;
      // The v1 type list; Wonky Drive lists every kind and file subtypes.
      List<WonkyMenuEntry> typeEntries() => scope?.isAll ?? false
          ? [
              for (final t in const [
                DriveTypeFilter.all,
                DriveTypeFilter.folders,
                DriveTypeFilter.documents,
                DriveTypeFilter.spreadsheets,
                DriveTypeFilter.presentations,
              ])
                WonkyMenuRadioItem(
                  label: typeLabel(t),
                  selected: c.typeFilter == t,
                  onSelected: () => c.setTypeFilter(t),
                ),
              WonkyMenuSubmenu(
                label: l.typeFiles,
                children: [
                  WonkyMenuRadioItem(
                    label: l.typeAllFiles,
                    selected:
                        c.typeFilter == DriveTypeFilter.files &&
                        c.fileCategory == null,
                    onSelected: () => c.setTypeFilter(DriveTypeFilter.files),
                  ),
                  const WonkyMenuSeparator(),
                  for (final cat in filterFileCategories)
                    WonkyMenuRadioItem(
                      label: fileCategoryLabel(l, cat),
                      selected:
                          c.typeFilter == DriveTypeFilter.files &&
                          c.fileCategory == cat,
                      onSelected: () =>
                          c.setTypeFilter(DriveTypeFilter.files, category: cat),
                    ),
                ],
              ),
            ]
          : [
              for (final t in const [
                DriveTypeFilter.primary,
                DriveTypeFilter.documents,
                DriveTypeFilter.spreadsheets,
                DriveTypeFilter.folders,
                DriveTypeFilter.all,
              ])
                if (!(t == DriveTypeFilter.primary &&
                    (services.config.primaryKind == DriveItemKind.document
                            ? DriveTypeFilter.documents
                            : DriveTypeFilter.spreadsheets) ==
                        t))
                  WonkyMenuRadioItem(
                    label: typeLabel(t),
                    selected: c.typeFilter == t,
                    onSelected: () => c.setTypeFilter(t),
                  ),
            ];
      String ownerLabel(DriveOwnerFilter o) => switch (o) {
        DriveOwnerFilter.anyone => l.ownerAnyone,
        DriveOwnerFilter.me => l.ownerMeFilter,
        DriveOwnerFilter.notMe => l.ownerNotMe,
      };
      String sortLabel(DriveSortField f) => switch (f) {
        DriveSortField.name => l.sortName,
        DriveSortField.modifiedAt => l.sortModified,
        DriveSortField.lastOpenedByMe => l.sortOpenedByMe,
        DriveSortField.lastModifiedByMe => l.sortModifiedByMe,
        DriveSortField.size => l.sortSize,
        DriveSortField.createdAt => l.sortCreated,
      };
      Widget chip(
        String key,
        String label,
        List<WonkyMenuEntry> Function() entries,
      ) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: WonkyDropdownMenu(
          entries: entries,
          builder: (context, ctl) => ShadButton.outline(
            key: ValueKey<String>('drive.filter.$key'),
            size: ShadButtonSize.sm,
            trailing: const Icon(LucideIcons.chevronDown, size: 14),
            onPressed: ctl.toggle,
            child: Text(label),
          ),
        ),
      );
      bar = Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
        child: SingleChildScrollView(
          key: const ValueKey<String>('drive.filterBar'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // App homes list only their kind: no type chip (suite 03
              // §3.3).
              if (scope == null || scope.showsTypeFilter)
                chip(
                  'type',
                  typeLabel(c.typeFilter, c.fileCategory),
                  typeEntries,
                ),
              chip(
                'owner',
                ownerLabel(c.ownerFilter),
                () => [
                  for (final o in DriveOwnerFilter.values)
                    WonkyMenuRadioItem(
                      label: ownerLabel(o),
                      selected: c.ownerFilter == o,
                      onSelected: () => c.setOwnerFilter(o),
                    ),
                ],
              ),
              chip(
                'sort',
                l.sortBy(sortLabel(c.sortField)),
                () => [
                  for (final f in [
                    DriveSortField.name,
                    DriveSortField.modifiedAt,
                    DriveSortField.lastOpenedByMe,
                    DriveSortField.lastModifiedByMe,
                    DriveSortField.size,
                  ])
                    WonkyMenuRadioItem(
                      label: sortLabel(f),
                      selected: c.sortField == f,
                      onSelected: () =>
                          c.setSort(f, descending: f != DriveSortField.name),
                    ),
                  const WonkyMenuSeparator(),
                  WonkyMenuCheckItem(
                    label: l.sortDescending,
                    checked: c.descending,
                    onSelected: () =>
                        c.setSort(c.sortField, descending: !c.descending),
                  ),
                  WonkyMenuCheckItem(
                    label: l.foldersOnTop,
                    checked: c.foldersFirst,
                    onSelected: () => c.setFoldersFirst(!c.foldersFirst),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titleRow,
        // The selection bar replaces the filter bar in place with the same
        // height, so selecting a row never moves the rows (a double click
        // must hit the same row twice).
        SizedBox(
          key: const ValueKey<String>('drive.headerBar'),
          height: _barHeight,
          child: bar,
        ),
      ],
    );
  }

  static const double _barHeight = 48;
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.controller, required this.services});

  final DriveController controller;
  final ShellServices services;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    Widget crumb(String label, String? folderUuid, {bool last = false}) =>
        DragTarget<DriveDragData>(
          onWillAcceptWithDetails: (_) =>
              !last && (services.config.homeScope?.managesFolders ?? true),
          onAcceptWithDetails: (d) =>
              dropIntoFolder(services, d.data, folderUuid),
          builder: (context, cand, _) => last
              ? Text(label, style: theme.textTheme.h4)
              : ShadButton.ghost(
                  size: ShadButtonSize.sm,
                  backgroundColor: cand.isNotEmpty
                      ? theme.colorScheme.selection
                      : null,
                  onPressed: () => services.router.go(
                    folderUuid == null
                        ? services.config.homeNav.myFilesRoute
                        : '/f/$folderUuid',
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.large.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
        );
    final f = controller.folder;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          crumb(
            homeNavLabel(
              l,
              HomeNavDestination.myFiles,
              scope: services.config.homeScope,
            ).$2,
            null,
          ),
          for (final p in controller.path) ...[
            const Icon(LucideIcons.chevronRight, size: 16),
            crumb(p.name, p.uuid.uuid),
          ],
          if (f != null) ...[
            const Icon(LucideIcons.chevronRight, size: 16),
            crumb(f.name, f.uuid.uuid, last: true),
          ],
        ],
      ),
    );
  }
}

/// *Open in Wonky Drive* (app homes, suite 03 §3.3): a ghost button with
/// the Drive product icon in the header row; icon only on narrow widths.
class _OpenInDriveButton extends StatelessWidget {
  const _OpenInDriveButton({required this.onPressed, this.compact = false});

  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    const icon = WonkyProductIcon(
      WonkyProduct.drive,
      size: 16,
      semanticLabel: '',
    );
    if (compact) {
      return ShadTooltip(
        builder: (_) => Text(l.cmdOpenInDrive),
        child: ShadIconButton.ghost(
          key: const ValueKey<String>('drive.openInDrive'),
          semanticLabel: l.cmdOpenInDrive,
          icon: icon,
          onPressed: onPressed,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: ShadButton.ghost(
        key: const ValueKey<String>('drive.openInDrive'),
        size: ShadButtonSize.sm,
        leading: icon,
        onPressed: onPressed,
        child: Text(l.cmdOpenInDrive),
      ),
    );
  }
}
