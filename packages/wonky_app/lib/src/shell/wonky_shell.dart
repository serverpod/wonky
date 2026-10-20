import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;
import 'package:wonky_ui/wonky_ui.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_repository.dart';
import '../bootstrap/wonky_client.dart';
import '../commands/keymap_service.dart';
import '../commands/shell_commands/general_commands.dart';
import '../config/wonky_app_config.dart';
import '../core/connectivity_service.dart';
import '../core/local_store.dart';
import '../data/api.dart';
import '../data/cached_drive_repository.dart';
import '../data/collab_repositories.dart';
import '../data/drive_cache.dart';
import '../data/drive_repository.dart';
import '../data/file_repository.dart';
import '../data/sharing_repository.dart';
import '../data/user_repository.dart';
import '../l10n/wonky_app_localizations.dart';
import '../mcp_bridge/mcp_bridge_scope.dart';
import '../routing/router.dart';
import '../storage/live_storage_controller.dart';
import '../board/board_repository.dart';
import '../publications/publication_repository.dart';
import 'overlays/shell_overlays.dart';
import 'shell_services.dart';
import 'usage_ping.dart';
import '../undo/undo_service.dart';

/// The locale tag forced at build time with
/// `--dart-define=WONKY_LOCALE=<tag>` (e.g. `en_XA`, the pseudo-locale of
/// specs/11 §4); empty to follow the system locale.
const wonkyLocaleTag = String.fromEnvironment('WONKY_LOCALE');

/// Parses a locale [tag] (`en`, `en_XA`, `en-XA`, `zh_Hant_TW`) into a locale
/// the shell supports, or null when [tag] is empty or its language isn't
/// supported (the shell then follows the system locale).
Locale? forcedLocale([String tag = wonkyLocaleTag]) {
  final parts = tag.trim().split(RegExp('[-_]'));
  if (parts.first.isEmpty) return null;
  String? script;
  String? country;
  for (final p in parts.skip(1)) {
    if (p.length == 4 && script == null && country == null) {
      script = '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}';
    } else {
      country = p.toUpperCase();
    }
  }
  final locale = Locale.fromSubtags(
    languageCode: parts.first.toLowerCase(),
    scriptCode: script,
    countryCode: country,
  );
  final supported = WonkyAppLocalizations.supportedLocales.any(
    (s) => s.languageCode == locale.languageCode,
  );
  if (!supported) {
    debugPrint('WONKY_LOCALE=$tag is not a supported locale; ignored.');
    return null;
  }
  return locale;
}

/// The shared app shell (suite 03): bootstraps the client, auth, commands,
/// keymap, undo, routing and overlays, then hosts the app's screens.
///
/// ```dart
/// void main() => WonkyShell.run(WriteAppConfig());
/// ```
class WonkyShell extends StatefulWidget {
  const WonkyShell({
    super.key,
    required this.config,
    this.client,
    this.services,
  });

  final WonkyAppConfig config;

  /// The initialized client (production). Ignored when [services] is given.
  final WonkyClient? client;

  /// Pre-built services (tests with fake repositories).
  final ShellServices? services;

  /// Initializes the client and runs the app.
  static Future<void> run(WonkyAppConfig config) async {
    WidgetsFlutterBinding.ensureInitialized();
    // Real paths (`/d/<uuid>`), served by the dev server and the server's
    // FlutterRoute SPA fallback.
    usePathUrlStrategy();
    final client = await WonkyClient.initialize();
    runApp(WonkyShell(config: config, client: client));
  }

  /// Builds production services on the generated client.
  static ShellServices createServices(WonkyAppConfig config, WonkyClient wc) {
    final api = Api(wc.client);
    final device = SharedPreferencesStore();
    final connectivity = ConnectivityService(
      ping: () async => await wc.client.meta.getInfo(),
    );
    late final ShellServices services;
    final remoteDrive = ServerDriveRepository(api);
    final cached = CachedDriveRepository(
      remote: remoteDrive,
      cache: DriveCache(device.scoped('anon.')),
      queue: PendingDriveOpQueue(device.scoped('anon.')),
      connectivity: connectivity,
      currentUser: () => services.me,
      onConflict: (op, e) => services.toasts.show(
        services.l10n?.toastOfflineOpFailed ??
            'A change made offline could not be applied',
        description: errorMessage(e),
      ),
    );
    services = ShellServices(
      config: config,
      auth: AuthController(
        ServerAuthRepository(wc.client, google: wc.urls.google),
      ),
      repositories: ShellRepositories(
        drive: cached,
        users: ServerUserRepository(api),
        sharing: ServerSharingRepository(api),
        comments: ServerCommentRepository(api),
        notifications: ServerNotificationRepository(api),
        presence: ServerPresenceRepository(api),
        versions: ServerVersionRepository(api),
        files: ServerFileRepository(api),
        meta: ServerMetaRepository(api),
        activity: ServerActivityRepository(api),
        board: ServerBoardRepository(api),
        publications: ServerPublicationRepository(api),
      ),
      urls: wc.urls,
      connectivity: connectivity,
      deviceStore: device,
      client: wc.client,
      // Drive 03 §6 (D-11): usage from `drive.storageUsage`, live from
      // `storageChanged` events, cached per user for offline display.
      storage: LiveStorageController(
        fetch: remoteDrive.storageUsage,
        checkRoom: (bytes, itemUuid) =>
            api.guard((c) => c.drive.checkRoom(bytes, itemUuid)),
        cache: () => services.userStore,
      ),
    );
    return services;
  }

  @override
  State<WonkyShell> createState() => _WonkyShellState();
}

class _WonkyShellState extends State<WonkyShell> {
  late final ShellServices s;
  bool _ready = false;
  final Locale? _locale = forcedLocale();
  StreamSubscription<UndoOutcome>? _undoSub;
  late final UsagePing _usagePing = UsagePing(s);
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    s =
        widget.services ??
        WonkyShell.createServices(widget.config, widget.client!);
    s.router = buildShellRouter(s);
    s.router.routerDelegate.addListener(_onRoute);
    s.registry.registerAll(
      allShellCommands(
        s,
      ).where((c) => !widget.config.hidesShellCommand(c.id.value)),
    );
    s.registry.registerAll(widget.config.commands(s));
    s.keymap.onOverridesChanged = s.prefs.setKeymapOverrides;
    HardwareKeyboard.instance.addHandler(_onUnfocusedKey);
    // A hidden tab or minimized window stops the connectivity heartbeat;
    // shown again, it checks at once (03 §7).
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) =>
          s.connectivity.setVisible(ConnectivityService.isShown(state)),
    );
    final state = SchedulerBinding.instance.lifecycleState;
    if (state != null) {
      s.connectivity.setVisible(ConnectivityService.isShown(state));
    }
    s.crossApp.rememberLastApp(widget.config.app);
    s.auth.onSignedIn = _afterSignIn;
    s.auth.onSigningOut = _beforeSignOut;
    s.auth.addListener(_onAuth);
    unawaited(_init());
  }

  Future<void> _init() async {
    await s.prefs.loadLocal();
    s.keymap.loadOverrides(s.prefs.keymapOverrides);
    s.mcp.setEnabled(s.prefs.device<bool>('mcp.uiBridge') ?? kDebugMode);
    s.connectivity.start();
    unawaited(_loadServerInfo());
    if (s.auth.isSignedIn) {
      // Render from the device first (CQ-45, H-6): with the profile cached
      // by an earlier session, the UI shows without waiting for the
      // network; the profile and preferences refresh in the background.
      final cached = await s.repositories.users.cachedMe();
      if (cached != null) {
        await _bindUser(cached);
        await _setUpSignedIn();
        if (mounted) setState(() => _ready = true);
        unawaited(_refreshSignedIn());
        return;
      }
      await _afterSignIn(null);
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _loadServerInfo() async {
    try {
      s.serverInfo.value = await s.repositories.meta.getInfo();
    } catch (_) {}
  }

  void _onRoute() {
    final loc = s.router.routerDelegate.currentConfiguration.uri.toString();
    s.recordLocation(loc);
  }

  bool _signedInSetup = false;

  Future<void> _afterSignIn(SignUpDraft? draft) async {
    if (draft != null && draft.displayName.isNotEmpty) {
      try {
        await s.repositories.users.updateProfile(
          displayName: draft.displayName,
        );
      } catch (e) {
        debugPrint('Setting the display name failed: $e');
      }
    }
    // The profile and the preferences in parallel (H-6).
    final remotePrefs = _signedInSetup ? null : s.prefs.loadRemote();
    try {
      await _bindUser(await s.repositories.users.getMe());
    } catch (e) {
      debugPrint('Loading the profile failed: $e');
    }
    if (_signedInSetup) return;
    await remotePrefs;
    s.keymap.loadOverrides(s.prefs.keymapOverrides);
    await _setUpSignedIn();
  }

  /// Makes [me] the current user: their device store and drive cache.
  Future<void> _bindUser(UserProfileView me) async {
    final changed = s.currentUser.value?.summary.uuid != me.summary.uuid;
    s.currentUser.value = me;
    if (!changed) return;
    final user = me.summary.uuid.uuid;
    s.userStore = s.deviceStore.scoped('user.$user.');
    final d = s.drive;
    if (d is CachedDriveRepository) await d.init();
  }

  /// The background part of a start from the cached profile: the server's
  /// profile and preferences, in parallel.
  Future<void> _refreshSignedIn() async {
    await Future.wait([
      () async {
        try {
          final me = await s.repositories.users.getMe();
          if (mounted && s.auth.isSignedIn) await _bindUser(me);
        } catch (e) {
          debugPrint('Loading the profile failed: $e');
        }
      }(),
      s.prefs.loadRemote(),
    ]);
    if (!mounted) return;
    s.keymap.loadOverrides(s.prefs.keymapOverrides);
  }

  /// Once per sign-in: live drive changes, storage, undo signals and the
  /// app's own setup.
  Future<void> _setUpSignedIn() async {
    if (_signedInSetup) return;
    _signedInSetup = true;
    s.supervisor.supervise<DriveChange>(
      'drive.watch',
      s.drive.watch,
      s.emitDriveChange,
      onConnected: s.refreshDrive,
    );
    final storage = s.storage;
    if (storage is LiveStorageController) {
      unawaited(
        storage.start(changes: s.driveChanges, refreshSignal: s.driveRefresh),
      );
    }
    _undoSub ??= s.undo.outcomes.listen((_) => s.registry.notifyStateChanged());
    _usagePing.start();
    await widget.config.onSignedIn(s);
  }

  Future<void> _beforeSignOut() async {
    _usagePing.stop();
    await widget.config.onSigningOut(s);
    await s.supervisor.cancelAll();
    final storage = s.storage;
    if (storage is LiveStorageController) storage.stop();
    s.undo.clearAll();
    s.currentUser.value = null;
    _signedInSetup = false;
  }

  void _onAuth() {
    if (s.auth.isSignedIn && s.currentUser.value == null) {
      unawaited(_afterSignIn(null));
    }
    if (mounted) setState(() {});
  }

  /// Global shortcuts when no widget holds focus (e.g. right after load on
  /// web, before the view regains DOM focus): the focus chain would never
  /// reach the global [KeymapScope], so it handles the event here.
  bool _onUnfocusedKey(KeyEvent event) {
    final primary = FocusManager.instance.primaryFocus;
    if (primary != null && primary != FocusManager.instance.rootScope) {
      return false;
    }
    return s.keymap.handle(
          event,
          KeyScope.global,
          context: s.navigatorContext,
        ) ==
        KeyEventResult.handled;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onUnfocusedKey);
    _lifecycle.dispose();
    _usagePing.stop();
    _undoSub?.cancel();
    s.auth.removeListener(_onAuth);
    s.router.routerDelegate.removeListener(_onRoute);
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;
    return MultiProvider(
      providers: [
        Provider<ShellServices>.value(value: s),
        ChangeNotifierProvider<AuthController>.value(value: s.auth),
      ],
      child: ListenableBuilder(
        listenable: s.prefs,
        builder: (context, _) => ShadApp.router(
          title: config.appName,
          debugShowCheckedModeBanner: false,
          theme: WonkyTheme.light(s.prefs.themeConfig),
          darkTheme: WonkyTheme.dark(s.prefs.themeConfig),
          themeMode: s.prefs.themeMode,
          routerConfig: s.router,
          locale: _locale,
          supportedLocales: WonkyAppLocalizations.supportedLocales,
          localizationsDelegates: [
            WonkyAppLocalizations.delegate,
            WonkyUiLocalizations.delegate,
            ...config.localizationsDelegates,
          ],
          builder: (context, child) => WonkyThemeScope(
            data: WonkyThemeExtension(
              density: s.prefs.wonkyDensity,
              reduceMotion: s.prefs.reduceMotion,
            ),
            child: KeymapScope(
              scope: KeyScope.global,
              keymap: s.keymap,
              child: config.wrap(
                context,
                s,
                McpBridgeScope(
                  services: s,
                  appTools: config.mcpUiTools(s),
                  child: ShellOverlays(
                    services: s,
                    ready: _ready,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
