import 'package:flutter/widgets.dart';
import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../auth/auth_controller.dart';
import '../bootstrap/app_urls.dart';
import '../bootstrap/cross_app.dart';
import '../comments/comments_controller.dart';
import '../comments/comments_host.dart';
import '../comments/comments_undo.dart';
import '../versions/versions_undo.dart';
import '../commands/command_dispatcher.dart';
import '../commands/command_registry.dart';
import '../commands/keymap_service.dart';
import '../config/wonky_app_config.dart';
import '../core/connectivity_service.dart';
import '../core/local_store.dart';
import '../core/preferences_controller.dart';
import '../core/stream_supervisor.dart';
import '../core/toasts.dart';
import '../data/collab_repositories.dart';
import '../data/cached_drive_repository.dart';
import '../data/drive_repository.dart';
import '../data/file_repository.dart';
import '../data/sharing_repository.dart';
import '../data/user_repository.dart';
import '../document/document_controller.dart';
import '../drive/drive_controller.dart';
import '../l10n/wonky_app_localizations.dart';
import '../mcp_bridge/mcp_control.dart';
import '../storage/storage_controller.dart';
import '../storage/quota_error_presenter.dart';
import '../board/board_repository.dart';
import '../publications/publication_repository.dart';
import '../publications/submission_undo.dart';
import '../storage/storage_checks.dart';
import '../menus/shell_menus.dart';
import '../undo/drive_undo.dart';
import 'form_dialog.dart';
import '../undo/undo_service.dart';

/// The AI assistant integration point (suite 10): the assistant panel and
/// `shell.ai.*` commands delegate here once the assistant is installed.
abstract class AssistantHook {
  /// The side panel id of the assistant.
  String get panelId => 'assistant';

  bool get available;
  Future<void> newThread();
  Future<void> send(String prompt);
  Future<void> stop();
}

/// The repositories the shell uses (all wrap the generated client; fakes in
/// `package:wonky_app/testing.dart`).
class ShellRepositories {
  const ShellRepositories({
    required this.drive,
    required this.users,
    required this.sharing,
    required this.comments,
    required this.notifications,
    required this.presence,
    required this.versions,
    required this.files,
    required this.meta,
    ActivityRepository? activity,
    BoardRepository? board,
    PublicationRepository? publications,
  }) : _activity = activity, // ignore: prefer_initializing_formals
       _board = board, // ignore: prefer_initializing_formals
       _publications = publications; // ignore: prefer_initializing_formals

  final DriveRepository drive;
  final UserRepository users;
  final SharingRepository sharing;
  final CommentRepository comments;
  final NotificationRepository notifications;
  final PresenceRepository presence;
  final VersionRepository versions;
  final FileRepository files;
  final MetaRepository meta;
  final ActivityRepository? _activity;
  final BoardRepository? _board;
  final PublicationRepository? _publications;

  /// Publications and submissions (specs/18); throws when the shell was
  /// built without one.
  PublicationRepository get publications =>
      _publications ??
      (throw StateError('No PublicationRepository installed.'));

  /// Whether [publications] is available.
  bool get hasPublications => _publications != null;

  /// Bugs & improvements (specs/16); throws when the shell was built
  /// without one.
  BoardRepository get board =>
      _board ?? (throw StateError('No BoardRepository installed.'));

  /// The activity dashboard; throws when the shell was built without one.
  ActivityRepository get activity =>
      _activity ?? (throw StateError('No ActivityRepository installed.'));
}

/// Long-lived services created by `WonkyShell` and provided to the whole
/// app (suite 03 §5): commands, keymap, undo, repositories, connectivity,
/// preferences, view state, panels, MCP hook.
class ShellServices implements ActiveDocumentHost {
  ShellServices({
    required this.config,
    required this.auth,
    required this.repositories,
    required this.urls,
    required this.connectivity,
    required LocalStore deviceStore,
    LocalStore? userStore,
    UuidV7Generator? ids,
    this.client,
    StorageController? storage,
    CrossAppNavigator? crossApp,
  }) : storage = storage ?? StorageController.none(),
       deviceStore = deviceStore,
       userStore = userStore ?? deviceStore.scoped('user.'),
       ids = ids ?? UuidV7Generator.instance {
    registry = CommandRegistry();
    dispatcher = CommandDispatcher(this);
    keymap = KeymapService(registry: registry, dispatcher: dispatcher);
    undo = UndoService(persistence: this.userStore);
    prefs = PreferencesController(
      device: deviceStore,
      users: repositories.users,
    );
    supervisor = StreamSupervisor(connectivity);
    this.crossApp = crossApp ?? CrossAppNavigator(urls);
    toasts = Toasts(() => navigatorContext);
    panels = WonkySplitViewController(
      width: prefs.device<double>('panel.width'),
      onWidthChanged: (w) => prefs.setDevice('panel.width', w),
    );
    undo.registerHandler(DriveUndoHandler(repositories.drive));
    undo.registerHandler(CommentsUndoHandler(this));
    if (repositories.hasPublications) {
      undo.registerHandler(SubmissionUndoHandler(this));
    }
    undo.registerHandler(VersionsUndoHandler(this));
    quotaErrors.attach();
  }

  final WonkyAppConfig config;
  final AuthController auth;
  final ShellRepositories repositories;
  final AppUrls urls;
  final ConnectivityService connectivity;
  final LocalStore deviceStore;
  LocalStore userStore;
  final UuidV7Generator ids;

  /// The generated client (null in widget tests with fakes).
  final Client? client;

  /// (v2) The user's storage for meters, banners and quota pre-checks
  /// (Drive 03 §6): `LiveStorageController` in the app,
  /// `StorageController.none()` by default, `FakeStorage` in tests.
  final StorageController storage;

  /// (v2) Shows the *Out of storage* dialog for `quotaExceeded` errors
  /// (Drive 03 §6.3); attached to every human-invoked command.
  late final QuotaErrorPresenter quotaErrors = QuotaErrorPresenter(this);

  /// (v2) Quota pre-checks before uploads, imports, copies and image
  /// inserts (Drive 03 §7.2).
  late final StorageChecks storageChecks = StorageChecks(this);

  late final CommandRegistry registry;
  late final CommandDispatcher dispatcher;
  late final KeymapService keymap;
  late final UndoService undo;
  late final PreferencesController prefs;
  late final StreamSupervisor supervisor;
  late final CrossAppNavigator crossApp;
  late final Toasts toasts;
  late final WonkySplitViewController panels;
  final McpControl mcp = McpControl();

  /// The router (set by `WonkyShell`).
  late GoRouter router;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
    debugLabel: 'shell',
  );

  /// The `RepaintBoundary` around the whole app (built by `McpBridgeScope`):
  /// `captureAppScreenshot` and the `ui.screenshot` MCP tool capture it
  /// (specs/16 §5.1).
  final GlobalKey screenshotBoundary = GlobalKey(
    debugLabel: 'shell.screenshot',
  );

  /// Whether a file is currently being created from a home screen or menu.
  final ValueNotifier<bool> creatingFile = ValueNotifier(false);

  /// The active editor's controller.
  final ValueNotifier<DocumentController?> activeDocument = ValueNotifier(null);

  /// The signed-in user's profile.
  final ValueNotifier<UserProfileView?> currentUser = ValueNotifier(null);

  /// The drive item of the open document (title row, file commands).
  final ValueNotifier<DriveItemView?> currentItem = ValueNotifier(null);

  /// The selected items on the home screen.
  final ValueNotifier<List<DriveItemView>> driveSelection = ValueNotifier(
    const [],
  );

  /// The folder shown on the home screen (null = root / virtual view).
  final ValueNotifier<DriveItemView?> currentFolder = ValueNotifier(null);

  /// Select-all on the home screen (set by the drive list).
  VoidCallback? driveSelectAll;

  /// (v2) The list controller of the shown home view (layout, sort and
  /// selection for Drive's `drive.view.*` commands and `ui.drive.*` tools);
  /// null while no home is shown.
  final ValueNotifier<DriveController?> driveView = ValueNotifier(null);

  /// The home screen's search field (`/`).
  FocusNode? driveSearchFocus;

  /// Starts inline title editing in the editor header (File › Rename).
  VoidCallback? startTitleRename;

  /// Focus regions in F6 order (menubar, toolbar, document, panel, status
  /// bar; on Home: top bar, sidebar, list).
  final List<FocusNode> focusRegions = [];

  /// Navigation history for Back/Forward (`Mod+[` / `Mod+]` on desktop).
  final List<String> navHistory = [];
  int navIndex = -1;
  bool _navigatingHistory = false;
  bool _replacingHistory = false;

  /// Records a visited location (called by the router listener).
  void recordLocation(String location) {
    if (_navigatingHistory) {
      _navigatingHistory = false;
      return;
    }
    if (_replacingHistory) {
      _replacingHistory = false;
      if (navIndex >= 0 && navIndex < navHistory.length) {
        navHistory
          ..[navIndex] = location
          ..removeRange(navIndex + 1, navHistory.length);
        return;
      }
    }
    if (navIndex >= 0 && navHistory[navIndex] == location) return;
    if (navIndex < navHistory.length - 1) {
      navHistory.removeRange(navIndex + 1, navHistory.length);
    }
    navHistory.add(location);
    if (navHistory.length > 100) navHistory.removeAt(0);
    navIndex = navHistory.length - 1;
  }

  /// Goes to [location] in place of the current entry, in the shell's
  /// history and (given a [context] below the router) the browser's: for
  /// moves that stay at the same depth, such as switching tabs or opening a
  /// sibling, so Back does not walk through them (specs/16 §4.3).
  void goReplacing(String location, {BuildContext? context}) {
    final here = router.routerDelegate.currentConfiguration.uri.toString();
    if (here == location) return;
    _replacingHistory = true;
    if (context != null && Router.maybeOf(context) != null) {
      Router.neglect(context, () => router.go(location));
    } else {
      router.go(location);
    }
  }

  bool get canGoBack => navIndex > 0;
  bool get canGoForward => navIndex >= 0 && navIndex < navHistory.length - 1;

  void goBack() {
    if (!canGoBack) return;
    navIndex--;
    _navigatingHistory = true;
    router.go(navHistory[navIndex]);
  }

  void goForward() {
    if (!canGoForward) return;
    navIndex++;
    _navigatingHistory = true;
    router.go(navHistory[navIndex]);
  }

  /// A known drive item view (selection, open item or offline cache).
  DriveItemView? knownItem(UuidValue uuid) {
    for (final i in driveSelection.value) {
      if (i.uuid == uuid) return i;
    }
    final c = currentItem.value;
    if (c != null && c.uuid == uuid) return c;
    final d = drive;
    if (d is CachedDriveRepository) return d.cache.item(uuid);
    return null;
  }

  /// Comments of the open file (set by the editor scaffold).
  final ValueNotifier<CommentsController?> comments = ValueNotifier(null);

  /// Where the open file's comments are shown when not in the comments side
  /// panel (set by the app's editor screen, e.g. Write's margin).
  CommentsHost? commentsHost;

  /// Open MCP-describable dialogs, innermost last (`ui.get_dialog`).
  final List<McpDescribableDialog> openDialogs = [];

  /// The AI assistant (suite 10), contributed by the assistant workstream.
  AssistantHook? assistant;

  /// Server protocol info (version check, feature flags).
  final ValueNotifier<ProtocolInfo?> serverInfo = ValueNotifier(null);

  /// Live drive changes (fed by the supervised `drive.watch` stream).
  final StreamController<DriveChange> _driveChanges =
      StreamController.broadcast();
  Stream<DriveChange> get driveChanges => _driveChanges.stream;
  void emitDriveChange(DriveChange c) => _driveChanges.add(c);

  /// Bumped when listings must reload (empty trash, reconnect).
  final ValueNotifier<int> driveRefresh = ValueNotifier(0);
  void refreshDrive() => driveRefresh.value++;

  /// Bumped when this client created, renamed or restored a version, so that
  /// open version lists reload.
  final ValueNotifier<int> versionsRefresh = ValueNotifier(0);
  void refreshVersions() => versionsRefresh.value++;

  /// Recently invoked command ids (palette "Recent").
  final List<String> recentCommands = [];

  DriveRepository get drive => repositories.drive;

  BuildContext? get navigatorContext => navigatorKey.currentContext;

  WonkyAppLocalizations? get l10n {
    final c = navigatorContext;
    return c == null
        ? null
        : Localizations.of<WonkyAppLocalizations>(c, WonkyAppLocalizations);
  }

  UserSummary? get me => currentUser.value?.summary;

  // ---- Active document host ----

  DocumentController? _active;

  @override
  void activate(DocumentController controller) {
    if (_disposed || _active == controller) return;
    if (_active != null) deactivate(_active!);
    _active = controller;
    for (final h in controller.undoHandlers) {
      undo.registerHandler(h);
    }
    unawaited(
      undo.openStack(
        controller.undoStackKey,
        restoreSelection: controller.restoreSelection,
        persist: controller.persistUndo,
      ),
    );
    undo.setActiveDocument(controller.undoStackKey);
    controller.addListener(_onDocumentChanged);
    activeDocument.value = controller;
    registry.notifyStateChanged();
  }

  @override
  void deactivate(DocumentController controller) {
    if (_disposed || _active != controller) return;
    controller.removeListener(_onDocumentChanged);
    _active = null;
    undo.setActiveDocument(null);
    unawaited(undo.closeStack(controller.undoStackKey));
    activeDocument.value = null;
    registry.notifyStateChanged();
  }

  void _onDocumentChanged() => registry.notifyStateChanged();

  // ---- Navigation helpers ----

  /// Opens a drive item: folders in the drive, files in their app (same
  /// window; other app = full page load on web).
  Future<void> openItem(DriveItemView item) async {
    final app = WonkyAppKind.forItemKind(item.kind, current: config.app);
    final path = WonkyAppKind.itemPathFor(item.kind, item.uuid.uuid);
    if (app == config.app) {
      router.go(path);
    } else {
      await crossApp.open(app, path);
    }
  }

  /// Opens a route that may belong to another app (`/d/…`, `/s/…`, `/p/…`,
  /// `/file/…`).
  Future<void> openPath(String path) async {
    final owner = WonkyAppKind.ownerOfPath(path);
    if (owner != null && owner != config.app) {
      await crossApp.open(owner, path);
    } else {
      router.go(path);
    }
  }

  /// Creates a document/spreadsheet/presentation on the server (default
  /// `WonkyAppConfig.createItem`).
  Future<UuidValue?> createItemOnServer(
    DriveItemKind kind, {
    UuidValue? parentUuid,
    UuidValue? templateUuid,
    String? name,
  }) async {
    final ctx = navigatorContext;
    final untitled = ctx == null ? 'Untitled' : config.untitledName(ctx);
    final v = switch (kind) {
      DriveItemKind.spreadsheet => await drive.createSpreadsheet(
        parentUuid: parentUuid,
        name: name ?? untitled,
        templateUuid: templateUuid,
      ),
      DriveItemKind.presentation => await drive.createPresentation(
        parentUuid: parentUuid,
        name: name ?? untitled,
        templateUuid: templateUuid,
      ),
      _ => await drive.createDocument(
        parentUuid: parentUuid,
        name: name ?? untitled,
        templateUuid: templateUuid,
      ),
    };
    return v.uuid;
  }

  /// The app's menubar tree (shared menus extended by the app).
  MenuRoot menuRoot(BuildContext context) =>
      config.menus(context, ShellMenus(WonkyAppLocalizations.of(context)));

  /// Menu label paths of every command in the menubar.
  Map<String, List<String>> menuPaths(BuildContext context) =>
      menuRoot(context).commandPaths(
        titleOf: (c) =>
            registry.byId(c.commandId)?.title(context) ?? c.commandId,
      );

  /// Records a command in the palette's recent list.
  void noteRecentCommand(String id) {
    recentCommands
      ..remove(id)
      ..insert(0, id);
    if (recentCommands.length > 8) recentCommands.removeLast();
  }

  bool _disposed = false;

  void dispose() {
    _disposed = true;
    keymap.dispose();
    quotaErrors.dispose();
    dispatcher.dispose();
    undo.dispose();
    supervisor.dispose();
    storage.dispose();
    creatingFile.dispose();
    _driveChanges.close();
  }
}
