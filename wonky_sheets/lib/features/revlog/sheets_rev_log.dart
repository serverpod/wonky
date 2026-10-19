import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/codec.dart' show ChangeSet;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/revlog.dart';

import '../../l10n/sheets_l10n.dart';
import '../formatting/sheets_user_defaults.dart';
import '../model/local_view_state.dart';
import '../model/memory_workbook_session.dart';
import '../model/workbook_session.dart';
import 'logged_workbook_session.dart';

export 'logged_workbook_session.dart' show LoggedWorkbookSession, ViewportHint;

/// Opens the [WorkbookSession] of a spreadsheet item (RevLog spec 06 §7.1).
///
/// With the data layer installed ([SheetsRevLog.install], done at sign-in)
/// this is a [LoggedWorkbookSession]; follow its `loadState`. Without it
/// (widget tests with fake services, signed out) an in-memory blank
/// spreadsheet. The editor only depends on this function and
/// [WorkbookSession].
Future<WorkbookSession> openWorkbookSession(
  ShellServices services,
  UuidValue itemUuid, {
  @visibleForTesting Duration readyTimeout = const Duration(seconds: 10),
}) async {
  final client = await SheetsRevLog.ready(services, timeout: readyTimeout);
  if (client == null) {
    if (SheetsRevLog.isInstalled(services)) {
      throw SheetsDataUnavailableException(
        sheetsL10nOf(services).screenStorageUnavailable,
      );
    }
    return MemoryWorkbookSession.blank(itemUuid: itemUuid);
  }
  DriveItemView? item;
  try {
    item = await services.drive.get(itemUuid);
  } catch (_) {
    item = services.knownItem(itemUuid);
  }
  final file = item?.contentRef ?? itemUuid;
  final view = await LocalViewStateStore(services.userStore).read(file.uuid);
  final session = LoggedWorkbookSession.open(
    client,
    itemUuid: itemUuid,
    fileUuid: file,
    userId: services.me?.uuid.uuid ?? '',
    role: item?.myRole ?? Role.viewer,
    viewport: view == null
        ? null
        : ViewportHint(sheetId: view.activeSheetId, topRow: view.topRow),
  );
  final sub = services.driveChanges
      .where((c) => c.itemUuid == itemUuid && c.item != null)
      .listen((c) => session.updateRole(c.item!.myRole));
  session.addDisposeCallback(sub.cancel);
  return session;
}

/// The signed-in user's local data layer did not start, so a spreadsheet
/// can't be opened (see [openWorkbookSession]).
final class SheetsDataUnavailableException implements Exception {
  /// Creates the exception with the user-facing [message].
  const SheetsDataUnavailableException(this.message);

  /// What the editor shows.
  final String message;

  @override
  String toString() => message;
}

/// The Sheets data layer of the signed-in user (RevLog spec 06 §7.1): one
/// [RevLogClient] per user, opened when the profile is known (also
/// offline) and closed when the user signs out or changes.
abstract final class SheetsRevLog {
  static final Expando<RevLogInstallation> _installations = Expando(
    'SheetsRevLog',
  );

  /// Desktop directory of the cache (tests).
  static String? directoryOverride;

  /// Cells kept on a device whose browser has no OPFS (06 §2.5).
  static const limitedStorageCells = 200000;

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
          (client == null ? null : ClientRevTransport.sheets(client));
      if (t == null) return null;
      final c = await RevLogClient.open(
        services,
        app: 'sheets',
        schema: sheetsSchema,
        transport: t,
        userUuid: user,
        kind: DriveItemKind.spreadsheet,
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

  /// Creates a spreadsheet on this device (06 §7.1): the creation op goes
  /// into the outbox and the drive create (`registerSpreadsheet`, queued
  /// while offline) makes the server file with `initialize: false`, whose
  /// first op is ours. Templates are created on the server. Returns the
  /// item uuid (= file uuid).
  static Future<UuidValue?> createSpreadsheet(
    ShellServices services, {
    UuidValue? parentUuid,
    UuidValue? templateUuid,
    String? name,
  }) async {
    Future<UuidValue?> onServer() => services.createItemOnServer(
      DriveItemKind.spreadsheet,
      parentUuid: parentUuid,
      templateUuid: templateUuid,
      name: name,
    );
    final ctx = services.navigatorContext;
    final title =
        name ??
        (ctx == null
            ? 'Untitled spreadsheet'
            : services.config.untitledName(ctx));
    if (templateUuid != null) return onServer();
    final client = await SheetsRevLog.ready(services);
    if (client == null) return onServer();
    final file = UuidValue.fromString(const Uuid().v7());
    final d = SheetsUserDefaults.of(services);
    final model = WorkbookModel(spreadsheetId: file.uuid);
    final plan = const SheetsMutationPlanner().plan(
      CreateSpreadsheet(
        spreadsheetId: file.uuid,
        title: title,
        locale: d.locale ?? 'en_US',
        timeZone: d.timeZone ?? 'UTC',
        fontFamily: d.fontFamily,
        fontSize: d.fontSize,
      ),
      model,
      PlanContext(
        userId: services.me?.uuid.uuid ?? '',
        now: DateTime.fromMillisecondsSinceEpoch(
          clock.now().millisecondsSinceEpoch,
          isUtc: true,
        ),
      ),
    );
    await client.createLocal(
      file.uuid,
      ChangeSet(
        clientOpId: const Uuid().v7(),
        baseRevision: 0,
        changes: plan.changes,
        label: plan.label,
        summary: plan.summary.toJson(),
        offline: !services.connectivity.online,
      ),
    );
    try {
      await services.drive.registerSpreadsheet(
        spaceUuid: file,
        parentUuid: parentUuid,
        name: title,
      );
    } catch (e) {
      // The spreadsheet exists locally; the drive queue retries the create
      // while offline. Other errors are reported.
      debugPrint('Creating spreadsheet $file failed: $e');
      if (!isOfflineError(e)) rethrow;
    }
    services.refreshDrive();
    unawaited(client.syncOutboxes());
    return file;
  }

  static OfflineWarning _limitedWarning(ShellServices services) {
    final l = sheetsL10nOf(services);
    return OfflineWarning(
      title: l.storageLimitedTitle,
      description: l.storageLimitedDescription(
        NumberFormat.decimalPattern().format(limitedStorageCells),
      ),
    );
  }

  /// Tells the user once per device and user that offline storage is
  /// limited in this browser.
  static Future<void> _announceLimitedStorage(ShellServices services) async {
    const key = 'sheets.storageLimitedShown';
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
