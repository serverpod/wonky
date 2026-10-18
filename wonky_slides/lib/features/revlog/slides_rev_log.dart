import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/codec.dart' show ChangeSet;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/ops.dart'
    show CreateDeck, SlidesMutationPlanner, SlidesPlanContext;
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/revlog.dart' show slidesSchema;
import 'package:wonky_slides_core/templates.dart' show SlidesTemplates;
import 'package:wonky_slides_core/themes.dart'
    show SlideAppearance, SlideSize, SlideSizeKind;

import '../../config/slides_features.dart';
import '../../l10n/slides_l10n.dart';
import '../model/deck_session.dart';
import '../model/memory_deck_session.dart';
import '../settings/slides_user_defaults.dart';
import 'logged_deck_session.dart';

export 'logged_deck_session.dart' show DeckLoadStrings, LoggedDeckSession;

/// Opens the [DeckSession] of a presentation item (Slides 02 §9.1, RevLog
/// spec 08 §2).
///
/// With the data layer installed ([SlidesRevLog.install], done at sign-in)
/// this is a [LoggedDeckSession]; follow its `loadState`. Without it
/// (widget tests with fake services, signed out) an in-memory blank deck.
/// The editor only depends on this function and [DeckSession].
Future<DeckSession> openDeckSession(
  ShellServices services,
  UuidValue itemUuid, {
  @visibleForTesting Duration readyTimeout = const Duration(seconds: 10),
}) async {
  final client = await SlidesRevLog.ready(services, timeout: readyTimeout);
  if (client == null) {
    // Installed but not started (the cache failed to open or is still
    // opening): an empty in-memory deck would look like the data is gone
    // and lose every edit; the editor offers *Try again*.
    if (SlidesRevLog.isInstalled(services)) {
      throw SlidesDataUnavailableException(
        slidesL10nOf(services).screenStorageUnavailable,
      );
    }
    return MemoryDeckSession.blank(
      planner: SlidesRevLog.planner,
      itemUuid: itemUuid,
      title: slidesL10nOf(services).untitledPresentation,
    );
  }
  DriveItemView? item;
  try {
    item = await services.drive.get(itemUuid);
  } catch (_) {
    item = services.knownItem(itemUuid);
  }
  // Decks use the file uuid as item uuid (02 §9.3).
  final file = item?.contentRef ?? itemUuid;
  final session = LoggedDeckSession.open(
    client,
    itemUuid: itemUuid,
    fileUuid: file,
    userId: services.me?.uuid.uuid ?? '',
    planner: SlidesRevLog.planner,
    role: item?.myRole ?? Role.viewer,
    strings: SlidesRevLog.strings(services),
  );
  // Sharing changes (role up/downgrades) arrive on the drive watch.
  final sub = services.driveChanges
      .where((c) => c.itemUuid == itemUuid && c.item != null)
      .listen((c) => session.updateRole(c.item!.myRole));
  session.addDisposeCallback(sub.cancel);
  return session;
}

/// The signed-in user's local data layer did not start, so a presentation
/// can't be opened (see [openDeckSession]).
final class SlidesDataUnavailableException implements Exception {
  /// Creates the exception with the user-facing [message].
  const SlidesDataUnavailableException(this.message);

  /// What the editor shows.
  final String message;

  @override
  String toString() => message;
}

/// The Slides data layer of the signed-in user (RevLog spec 08 §2): one
/// [RevLogClient] per user, opened when the profile is known (also
/// offline) and closed when the user signs out or changes. Called from
/// `SlidesAppConfig.onSignedIn` / `onSigningOut`.
abstract final class SlidesRevLog {
  static final Expando<RevLogInstallation> _installations = Expando(
    'SlidesRevLog',
  );

  /// Desktop directory of the cache (tests).
  static String? directoryOverride;

  /// Elements kept on a device whose browser has no OPFS (suite 12 intro).
  static const limitedStorageElements = 50000;

  /// The planner of every deck write in the app (SL-7).
  static SlidesMutationPlanner planner = const SlidesPlanner();

  /// Installs (idempotent). [transport] replaces the server API (tests).
  static void install(
    ShellServices services, {
    RevTransport Function()? transport,
  }) {
    if (_installations[services] != null) return;
    final inst = RevLogInstallation(services, (user) async {
      final client = services.client;
      final t =
          transport?.call() ??
          (client == null ? null : ClientRevTransport.slides(client));
      if (t == null) return null;
      final c = await RevLogClient.open(
        services,
        app: 'slides',
        schema: slidesSchema,
        transport: t,
        userUuid: user,
        kind: DriveItemKind.presentation,
        directory: directoryOverride,
      );
      if (await offlineStorageLimited()) {
        c.offline.warnings = [_limitedWarning(services)];
        unawaited(_announceLimitedStorage(services));
      }
      return c;
    });
    _installations[services] = inst;
    inst.attach();
  }

  /// Closes the user's client and stops listening.
  static Future<void> uninstall(ShellServices services) async {
    final inst = _installations[services];
    if (inst == null) return;
    _installations[services] = null;
    await inst.detach();
  }

  /// The open client (null while opening, signed out or not installed).
  static RevLogClient? current(ShellServices services) =>
      _installations[services]?.client;

  /// Whether the data layer is installed (signed in), even when it has not
  /// started yet.
  static bool isInstalled(ShellServices services) =>
      _installations[services] != null;

  /// The client once open; null when not installed or no user appears
  /// within [timeout].
  static Future<RevLogClient?> ready(
    ShellServices services, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final inst = _installations[services];
    if (inst == null) return null;
    return inst.ready(timeout);
  }

  /// The localized load-state messages of deck sessions.
  static DeckLoadStrings strings(ShellServices services) {
    final l = slidesL10nOf(services);
    return DeckLoadStrings(
      downloading: l.deckDownloading,
      notAvailableOffline: l.deckNotAvailableOffline,
      noAccess: l.deckNoAccess,
      openFailed: l.deckOpenFailed,
      accessRemoved: l.deckAccessRemoved,
      stillOpening: l.deckStillOpening,
    );
  }

  /// Creates a presentation on this device (02 §9.3, 08 §2): blank decks
  /// (`CreateDeck`: deck row, the default theme copy, a title slide) and
  /// built-in templates (`SlidesTemplates`, SL-22) become the creation op
  /// in the outbox, online or offline; the drive create
  /// (`registerPresentation`, queued while offline) makes the server file
  /// with `initialize: false`, whose first op is ours. Other templates
  /// (presentations published as templates) are created on the server.
  /// Returns the item uuid (= file uuid).
  static Future<UuidValue?> createPresentation(
    ShellServices services, {
    UuidValue? parentUuid,
    UuidValue? templateUuid,
    String? name,
  }) async {
    Future<UuidValue?> onServer() => services.createItemOnServer(
      DriveItemKind.presentation,
      parentUuid: parentUuid,
      templateUuid: templateUuid,
      name: name,
    );
    final builtin = templateUuid == null
        ? null
        : SlidesTemplates.byUuid(templateUuid.uuid);
    final ctx = services.navigatorContext;
    final title =
        name ??
        builtin?.name ??
        (ctx == null
            ? slidesL10nOf(services).untitledPresentation
            : services.config.untitledName(ctx));
    if (templateUuid != null && builtin == null) return onServer();
    final client = await SlidesRevLog.ready(services);
    if (client == null) return onServer();
    final file = UuidValue.fromString(const Uuid().v7());
    final user = services.me?.uuid.uuid ?? '';
    final now = DateTime.fromMillisecondsSinceEpoch(
      clock.now().millisecondsSinceEpoch,
      isUtc: true,
    );
    final List<RowChange> changes;
    Map<String, Object?>? summary;
    if (builtin != null) {
      changes = builtin
          .build(deckId: file.uuid, userId: user, now: now, title: title)
          .inserts;
    } else {
      final d = newPresentationDefaults(services);
      final plan = planner.plan(
        CreateDeck(
          deckId: file.uuid,
          title: title,
          themeKey: d.themeKey,
          size: d.size,
          appearance: d.appearance,
          defaultsJson: d.defaultsJson,
        ),
        DeckModel(deckId: file.uuid),
        SlidesPlanContext(userId: user, now: now, isOwner: true),
      );
      changes = plan.changes;
      summary = plan.summary.toJson();
    }
    await client.createLocal(
      file.uuid,
      ChangeSet(
        clientOpId: const Uuid().v7(),
        baseRevision: 0,
        changes: changes,
        label: 'Create presentation',
        summary: summary,
        offline: !services.connectivity.online,
      ),
    );
    try {
      await services.drive.registerPresentation(
        spaceUuid: file,
        parentUuid: parentUuid,
        name: title,
      );
    } catch (e) {
      // The deck exists locally; the drive queue retries the create while
      // offline. Other errors are reported.
      debugPrint('Creating presentation $file failed: $e');
      if (!isOfflineError(e)) rethrow;
    }
    services.refreshDrive();
    unawaited(client.syncOutboxes());
    return file;
  }

  static OfflineWarning _limitedWarning(ShellServices services) {
    final l = slidesL10nOf(services);
    return OfflineWarning(
      title: l.storageLimitedTitle,
      description: l.storageLimitedDescription(
        NumberFormat.decimalPattern().format(limitedStorageElements),
      ),
    );
  }

  /// Tells the user once per device and user that offline storage is
  /// limited in this browser.
  static Future<void> _announceLimitedStorage(ShellServices services) async {
    const key = 'slides.storageLimitedShown';
    try {
      if (await services.userStore.read(key) == true) return;
      await services.userStore.write(key, true);
    } catch (_) {}
    final w = _limitedWarning(services);
    services.toasts.show(
      w.title,
      description: w.description,
      duration: const Duration(seconds: 12),
    );
  }
}

/// The user's *New presentations* settings (Slides 04 §13.16) for a blank
/// deck: the default theme, slide size and — only when the user chose one —
/// appearance (otherwise the theme's own); and the *Animations* settings'
/// default transition as the deck's `defaultsJson` (06 A-06-7; null for
/// none).
({
  String themeKey,
  SlideSize? size,
  SlideAppearance? appearance,
  String? defaultsJson,
})
newPresentationDefaults(ShellServices services) {
  final d = SlidesUserDefaults.of(services);
  final size = d.string(SlidesUserDefaults.keyDefaultSize);
  final chosen = services.prefs.slidesDefaults.containsKey(
    SlidesUserDefaults.keyDefaultAppearance,
  );
  final appearance = d.string(SlidesUserDefaults.keyDefaultAppearance);
  return (
    themeKey: d.string(SlidesUserDefaults.keyDefaultThemeKey),
    size: [
      for (final k in SlideSizeKind.values)
        if (k.name == size && k != SlideSizeKind.custom) SlideSize.preset(k),
    ].firstOrNull,
    appearance: chosen
        ? SlideAppearance.values.where((a) => a.name == appearance).firstOrNull
        : null,
    // Only while transitions are offered (SL-30).
    defaultsJson: SlidesFeatures.isOn(SlidesFeature.animations)
        ? SlidesUserDefaults.deckDefaultsJson(d)
        : null,
  );
}
