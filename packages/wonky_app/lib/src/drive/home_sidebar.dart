import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_ui/wonky_ui.dart';

import '../bootstrap/app_urls.dart';
import '../branding/product_icon.dart';
import '../config/home_scope.dart';
import '../data/models_ext.dart';
import '../l10n/wonky_app_localizations.dart';
import '../menus/menu_resolver.dart';
import '../shell/account_menu.dart' show productOf;
import '../shell/shell_services.dart';
import '../storage/storage_meter.dart';
import 'drive_location.dart';
import 'item_actions.dart';

/// The left menu of every home (suite 03 §3.3, Drive 04 §2): the app
/// section (four apps, the current one highlighted), *+ New* (Drive and v1
/// homes only: the app homes create from their template strip), the app's
/// navigation (`WonkyAppConfig.homeNav`, Drive: with the folder tree) and
/// the bottom section (app settings, Wonky Work settings, *Bugs & improvements*,
/// storage meter). Below `md` it is shown in a drawer ([onNavigate] closes
/// it after a navigation).
class HomeSidebar extends StatefulWidget {
  const HomeSidebar({
    super.key,
    required this.services,
    required this.location,
    this.onNavigate,
    this.activeDestination,
  });

  /// Width of the left menu.
  static const double width = 256;

  final ShellServices services;
  final DriveLocation location;

  /// Called before a navigation from the menu (closes the drawer).
  final VoidCallback? onNavigate;

  /// The highlighted destination of a page that is not a drive location
  /// (Drive's Storage page); null: derived from [location].
  final HomeNavDestination? activeDestination;

  @override
  State<HomeSidebar> createState() => _HomeSidebarState();
}

class _HomeSidebarState extends State<HomeSidebar> {
  late final WonkyTreeController<DriveItemView> _tree =
      WonkyTreeController<DriveItemView>(loader: _load);
  bool _treeOpen = false;
  StreamSubscription<DriveChange>? _sub;

  ShellServices get s => widget.services;

  @override
  void initState() {
    super.initState();
    _sub = s.driveChanges.listen((c) {
      if (c.item?.isFolder ?? true) _tree.refresh(c.item?.parentUuid?.uuid);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tree.dispose();
    super.dispose();
  }

  Future<List<WonkyTreeNode<DriveItemView>>> _load(
    WonkyTreeNode<DriveItemView>? parent,
  ) async {
    final page = await s.drive.list(
      folderUuid: parent?.value.uuid,
      filter: DriveListFilter(
        view: DriveView.folder,
        kinds: [DriveItemKind.folder],
        foldersContaining: s.config.homeScope?.foldersContaining,
      ),
      sort: DriveSort(field: DriveSortField.name, descending: false),
      limit: 200,
    );
    return [
      for (final f in page.items)
        if (f.isFolder && !f.isTrashed)
          WonkyTreeNode(
            id: f.uuid.uuid,
            label: f.name,
            value: f,
            icon: LucideIcons.folder,
          ),
    ];
  }

  void _go(String path) {
    widget.onNavigate?.call();
    s.router.go(path);
  }

  void _invoke(String id, [Map<String, Object?> args = const {}]) {
    widget.onNavigate?.call();
    unawaited(
      s.dispatcher.invoke(
        id,
        args: args,
        source: InvocationSource.menu,
        context: context,
      ),
    );
  }

  bool _isActive(HomeNavItem item) {
    final active = widget.activeDestination;
    if (active != null) return item.destination == active;
    final k = widget.location.kind;
    return switch (item.destination) {
      HomeNavDestination.home => k == DriveLocationKind.home,
      HomeNavDestination.recent =>
        item.route == '/'
            ? k == DriveLocationKind.home
            : k == DriveLocationKind.recent,
      HomeNavDestination.myFiles => k == DriveLocationKind.myDrive,
      HomeNavDestination.shared => k == DriveLocationKind.shared,
      HomeNavDestination.starred => k == DriveLocationKind.starred,
      HomeNavDestination.offline => k == DriveLocationKind.offline,
      HomeNavDestination.trash => k == DriveLocationKind.trash,
      HomeNavDestination.storage => false,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final scope = s.config.homeScope;
    final nav = s.config.homeNav;
    // Item drags onto folders: Drive and the v1 homes (app homes manage no
    // folders, suite 03 §3.3).
    final dragMoves = scope == null || scope.managesFolders;

    Widget navRow(HomeNavItem item) {
      final (icon, label) = homeNavLabel(l, item.destination, scope: scope);
      final key = 'drive.nav.${item.destination.name}';
      final row = DragTarget<DriveDragData>(
        onWillAcceptWithDetails: (_) =>
            dragMoves && item.destination == HomeNavDestination.myFiles,
        onAcceptWithDetails: (d) => dropIntoFolder(s, d.data, null),
        builder: (context, cand, _) => SidebarNavButton(
          key: ValueKey<String>(key),
          icon: icon,
          label: label,
          active: _isActive(item) || cand.isNotEmpty,
          onPressed: () => _go(item.route),
        ),
      );
      if (!(nav.folderTree && item.destination == HomeNavDestination.myFiles)) {
        return row;
      }
      return Row(
        children: [
          Expanded(child: row),
          ShadIconButton.ghost(
            key: const ValueKey<String>('drive.nav.tree'),
            width: WonkyLayout.isMobile(context) ? 44 : 28,
            height: WonkyLayout.isMobile(context) ? 44 : 28,
            iconSize: 14,
            semanticLabel: _treeOpen ? l.collapseFolders : l.expandFolders,
            icon: Icon(
              _treeOpen ? LucideIcons.chevronDown : LucideIcons.chevronRight,
            ),
            onPressed: () => setState(() => _treeOpen = !_treeOpen),
          ),
        ],
      );
    }

    final top = <Widget>[
      AppLinksSection(services: s, onNavigate: widget.onNavigate),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: ShadSeparator.horizontal(margin: EdgeInsets.zero),
      ),
      if (showsSidebarNewButton(scope))
        HomeNewButton(services: s, onNavigate: widget.onNavigate)
      else
        const SizedBox(height: 4),
      for (final item in nav.items) ...[
        navRow(item),
        if (_treeOpen &&
            nav.folderTree &&
            item.destination == HomeNavDestination.myFiles)
          SizedBox(
            height: 240,
            child: WonkyTreeView<DriveItemView>(
              keyPrefix: 'drive.tree',
              controller: _tree,
              semanticLabel: l.folderTree,
              onActivate: (n) => _go('/f/${n.id}'),
              dragData: (n) =>
                  dragMoves && n.value.canManage ? DriveDragData([n.id]) : null,
              canAcceptDrop: (data, target, pos) =>
                  dragMoves &&
                  data is DriveDragData &&
                  pos == WonkyTreeDropPosition.inside &&
                  target.value.canEdit &&
                  !data.uuids.contains(target.id),
              onDrop: (data, target, pos) {
                if (data is DriveDragData) dropIntoFolder(s, data, target.id);
              },
            ),
          ),
      ],
    ];

    return SizedBox(
      key: const ValueKey<String>('home.sidebar'),
      width: HomeSidebar.width,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            sliver: SliverList.list(children: top),
          ),
          // The bottom section sits at the bottom and scrolls with the menu
          // when the window is short (Drive 04 §2).
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [HomeSidebarFooter(services: s, onInvoke: _invoke)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon and label of a left-menu destination; *My files* is *My Drive* in
/// Drive and the v1 homes.
(IconData, String) homeNavLabel(
  WonkyAppLocalizations l,
  HomeNavDestination d, {
  HomeScope? scope,
}) => switch (d) {
  HomeNavDestination.home => (LucideIcons.house, l.navHome),
  HomeNavDestination.recent => (LucideIcons.clock, l.navRecent),
  HomeNavDestination.myFiles => (
    LucideIcons.hardDrive,
    scope == null || scope.isAll ? l.navMyDrive : l.navMyFiles,
  ),
  HomeNavDestination.shared => (LucideIcons.users, l.navShared),
  HomeNavDestination.starred => (LucideIcons.star, l.navStarred),
  HomeNavDestination.offline => (LucideIcons.cloudDownload, l.navOffline),
  HomeNavDestination.trash => (LucideIcons.trash2, l.navTrash),
  HomeNavDestination.storage => (LucideIcons.chartPie, l.navStorage),
};

/// Whether the home of [scope] has a *+ New* button: Drive and v1 homes;
/// the app homes create from their template strip's large *Blank* card.
bool showsSidebarNewButton(HomeScope? scope) => scope == null || scope.isAll;

/// The app section of the left menu (Drive 04 §2): Drive, a divider, then
/// Write, Sheets and Slides (short names) with their product icons; the
/// current app is
/// highlighted and not clickable, the others switch apps in the same tab
/// (`shell.account.switchApp {app}`).
class AppLinksSection extends StatelessWidget {
  const AppLinksSection({super.key, required this.services, this.onNavigate});

  final ShellServices services;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: l.navApps,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final app in WonkyAppKind.values) ...[
            SidebarNavButton(
              key: ValueKey<String>('home.app.${app.name}'),
              leading: WonkyProductIcon(
                productOf(app),
                size: 18,
                semanticLabel: '',
              ),
              label: app.shortName,
              height: 32,
              active: app == services.config.app,
              onPressed: app == services.config.app
                  ? null
                  : () {
                      onNavigate?.call();
                      unawaited(
                        services.dispatcher.invoke(
                          'shell.account.switchApp',
                          args: {'app': app.name},
                          source: InvocationSource.menu,
                          context: context,
                        ),
                      );
                    },
            ),
            // Drive (all files) is set apart from the editors.
            if (app == WonkyAppKind.drive)
              const Padding(
                key: ValueKey<String>('home.apps.divider'),
                padding: EdgeInsets.symmetric(vertical: 4),
                child: ShadSeparator.horizontal(margin: EdgeInsets.zero),
              ),
          ],
        ],
      ),
    );
  }
}

/// *+ New* of the left menu with the home's New menu (suite 03 §3.3,
/// Drive 04 §3.1): Drive — folder, file upload, document, spreadsheet,
/// presentation, template; app homes — their kind and *From template…*;
/// v1 homes — as in v1.
class HomeNewButton extends StatelessWidget {
  const HomeNewButton({
    super.key,
    required this.services,
    this.onNavigate,
    this.compact = false,
  });

  final ShellServices services;
  final VoidCallback? onNavigate;

  /// The top bar's variant while the left menu is collapsed (Drive 04 §2):
  /// a regular-height button, icon only below 640 px.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final theme = ShadTheme.of(context);
    if (compact) {
      final iconOnly = MediaQuery.sizeOf(context).width < 640;
      return WonkyDropdownMenu(
        entries: () => homeNewMenuEntries(context, services),
        builder: (context, c) => iconOnly
            ? ShadIconButton.outline(
                key: const ValueKey<String>('drive.new.topBar'),
                semanticLabel: l.newButton,
                icon: const Icon(LucideIcons.plus, size: 18),
                onPressed: c.toggle,
              )
            : ShadButton.outline(
                key: const ValueKey<String>('drive.new.topBar'),
                leading: const Icon(LucideIcons.plus, size: 18),
                onPressed: c.toggle,
                child: Text(l.newButton),
              ),
      );
    }
    return WonkyDropdownMenu(
      entries: () =>
          _closingFirst(homeNewMenuEntries(context, services), onNavigate),
      builder: (context, c) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.outline(
            key: const ValueKey<String>('drive.new'),
            height: 48,
            padding: const EdgeInsets.fromLTRB(12, 0, 20, 0),
            leading: const Icon(LucideIcons.plus, size: 20),
            onPressed: c.toggle,
            decoration: const ShadDecoration(
              shadows: [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              l.newButton,
              style: theme.textTheme.small.copyWith(fontSize: 15),
            ),
          ),
        ),
      ),
    );
  }
}

/// [entries] whose items call [close] (the drawer's pop) before their own
/// action, so a dialog or picker opened by the item (*File upload*, *New
/// folder*) isn't left behind the drawer (D-18). Commands invoked from the
/// closed drawer show their dialogs on the shell navigator.
List<WonkyMenuEntry> _closingFirst(
  List<WonkyMenuEntry> entries,
  VoidCallback? close,
) {
  if (close == null) return entries;
  return [
    for (final e in entries)
      if (e.runtimeType == WonkyMenuItem && (e as WonkyMenuItem).enabled)
        WonkyMenuItem(
          key: e.key,
          label: e.label,
          icon: e.icon,
          leading: e.leading,
          shortcut: e.shortcut,
          disabledReason: e.disabledReason,
          destructive: e.destructive,
          semanticLabel: e.semanticLabel,
          trailing: e.trailing,
          onSelected: e.onSelected == null
              ? null
              : () {
                  close();
                  e.onSelected!();
                },
        )
      else
        e,
  ];
}

/// The entries of the home's New menu (left menu *+ New*).
List<WonkyMenuEntry> homeNewMenuEntries(BuildContext context, ShellServices s) {
  final l = WonkyAppLocalizations.of(context);
  final r = MenuResolver(s);
  final scope = s.config.homeScope;
  String kindLabel(DriveItemKind k) => switch (k) {
    DriveItemKind.spreadsheet => l.menuNewSpreadsheet,
    DriveItemKind.presentation => l.menuNewPresentation,
    _ => l.menuNewDocument,
  };
  WonkyMenuEntry? newKind(DriveItemKind k, {String? label}) => r.commandEntry(
    context,
    'shell.file.new',
    args: {'kind': k.name},
    label: label ?? kindLabel(k),
    key: 'new.${k.name}',
  );
  if (scope == null) {
    // v1: the primary kind first, then the other, folder, upload, template.
    final primaryDoc = s.config.primaryKind != DriveItemKind.spreadsheet;
    return [
      ?r.commandEntry(
        context,
        'shell.file.new',
        args: {'kind': primaryDoc ? 'document' : 'spreadsheet'},
        label: primaryDoc ? l.menuNewDocument : l.menuNewSpreadsheet,
        key: 'new.primary',
      ),
      ?r.commandEntry(
        context,
        'shell.file.new',
        args: {'kind': primaryDoc ? 'spreadsheet' : 'document'},
        label: primaryDoc ? l.menuNewSpreadsheet : l.menuNewDocument,
        key: 'new.other',
      ),
      ?r.commandEntry(context, 'shell.drive.newFolder'),
      const WonkyMenuSeparator(),
      ?r.commandEntry(context, 'shell.drive.upload'),
      ?r.commandEntry(context, 'shell.file.newFromTemplate'),
    ];
  }
  if (scope.isAll) {
    return [
      ?r.commandEntry(context, 'shell.drive.newFolder'),
      const WonkyMenuSeparator(),
      ?r.commandEntry(context, 'shell.drive.upload', label: l.menuFileUpload),
      const WonkyMenuSeparator(),
      for (final k in scope.newKinds) ?newKind(k),
      ?r.commandEntry(context, 'shell.file.newFromTemplate'),
    ];
  }
  // App homes: the kind, *From template…* and *Import file…* (the app's
  // convertible types, suite 05 §3.0; D-16).
  final import = s.config.importHandler == null
      ? null
      : r.commandEntry(
          context,
          'shell.drive.upload',
          label: l.menuImportFile,
          key: 'new.import',
        );
  return [
    for (final k in scope.newKinds) ?newKind(k),
    ?r.commandEntry(context, 'shell.file.newFromTemplate'),
    if (import != null) ...[const WonkyMenuSeparator(), import],
  ];
}

/// The bottom section of the left menu (Drive 04 §2): the app settings,
/// *Contribute & build*, *Report a bug*, *Suggest an improvement* (specs/16
/// §4.1) and the storage meter.
class HomeSidebarFooter extends StatelessWidget {
  const HomeSidebarFooter({
    super.key,
    required this.services,
    required this.onInvoke,
  });

  final ShellServices services;
  final void Function(String id, [Map<String, Object?> args]) onInvoke;

  @override
  Widget build(BuildContext context) {
    final l = WonkyAppLocalizations.of(context);
    final s = services;
    // Phones keep only *Report a bug* and the meter (suite 03 §3.3, T-12);
    // Settings and the board stay in the account menu and on the desktop.
    final mobile = WonkyLayout.isMobile(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: ShadSeparator.horizontal(margin: EdgeInsets.zero),
        ),
        if (!mobile) ...[
          SidebarNavButton(
            key: const ValueKey<String>('home.footer.appSettings'),
            icon: LucideIcons.settings,
            label: l.cmdSettings,
            onPressed: () => onInvoke('shell.settings.openApp'),
          ),
          SidebarNavButton(
            key: const ValueKey<String>('home.footer.contribute'),
            icon: LucideIcons.wrench,
            label: l.boardContributeNav,
            onPressed: () => onInvoke('shell.board.open'),
          ),
        ],
        SidebarNavButton(
          key: const ValueKey<String>('home.footer.reportBug'),
          icon: LucideIcons.bug,
          label: l.boardReportBug,
          onPressed: () => onInvoke('shell.board.report', {'kind': 'bug'}),
        ),
        if (!mobile)
          SidebarNavButton(
            key: const ValueKey<String>('home.footer.suggest'),
            icon: LucideIcons.leaf,
            label: l.boardSuggestImprovement,
            onPressed: () => onInvoke('shell.board.report', {'kind': 'idea'}),
          ),
        const SizedBox(height: 8),
        StorageMeterSlot(
          services: s,
          onOpen: () => onInvoke('shell.storage.open'),
        ),
      ],
    );
  }
}

/// The storage meter slot of the left menu (Drive 03 §6.1): D-11's
/// [StorageMeter] on `ShellServices.storage`, opening the Storage page.
class StorageMeterSlot extends StatelessWidget {
  const StorageMeterSlot({super.key, required this.services, this.onOpen});

  final ShellServices services;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const ValueKey<String>('home.storage'),
    child: StorageMeter(services: services, onOpen: onOpen),
  );
}

/// A left-menu row (pill highlight when active): an [icon] or a [leading]
/// widget (product icons) and a label. A null [onPressed] with [active]
/// is the current, non-clickable entry (the current app).
class SidebarNavButton extends StatelessWidget {
  const SidebarNavButton({
    super.key,
    this.icon,
    this.leading,
    required this.label,
    required this.onPressed,
    this.active = false,
    this.height = 36,
  });

  final IconData? icon;
  final Widget? leading;
  final String label;
  final VoidCallback? onPressed;
  final bool active;

  /// Row height in the mobile layout: a comfortable touch target (suite 02
  /// §6.1, T-12).
  static const double mobileHeight = 48;

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final mobile = WonkyLayout.isMobile(context);
    final height = mobile ? math.max(this.height, mobileHeight) : this.height;
    final lead =
        leading ?? (icon == null ? null : Icon(icon, size: mobile ? 20 : 18));
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.small.copyWith(
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
        fontSize: mobile ? 15 : null,
        color: theme.colorScheme.foreground,
      ),
    );
    if (onPressed == null) {
      // The current app: highlighted, not a button.
      return Semantics(
        selected: active,
        label: label,
        excludeSemantics: true,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: active ? theme.colorScheme.sidebarAccent : null,
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: Row(
            children: [
              ?lead,
              if (lead != null) const SizedBox(width: 8),
              Flexible(child: text),
            ],
          ),
        ),
      );
    }
    return Semantics(
      selected: active,
      child: ShadButton.ghost(
        height: height,
        width: double.infinity,
        mainAxisAlignment: MainAxisAlignment.start,
        backgroundColor: active ? theme.colorScheme.sidebarAccent : null,
        hoverBackgroundColor: active
            ? theme.colorScheme.sidebarAccent
            : theme.colorScheme.accent,
        decoration: ShadDecoration(
          border: ShadBorder(
            radius: BorderRadius.all(Radius.circular(height / 2)),
          ),
        ),
        leading: lead,
        onPressed: onPressed,
        child: Flexible(child: text),
      ),
    );
  }
}
