import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/config/drive_app_config.dart';
import 'package:wonky_drive/features/storage/storage_api.dart';
import 'package:wonky_drive/features/storage/storage_controller.dart';
import 'package:wonky_drive/l10n/drive_l10n.dart';
import 'package:wonky_ui/testing.dart';

const kb = 1024;
const mb = 1024 * 1024;

/// The fixed "now" of Storage tests.
final storageNow = DateTime.utc(2026, 10, 15, 12);

/// `drive.listByStorage` over a [FakeDriveRepository] (Drive 03 §6.4): the
/// owner's items incl. trashed, no folders, by counted size then uuid,
/// descending; the cursor is the next offset. [overrides] patch fields the
/// fake drive can't seed (`lastOpenedAt`, `createdAt`).
class FakeStorageApi implements StorageApi {
  FakeStorageApi(this.drive);

  final FakeDriveRepository drive;

  final Map<UuidValue, DriveItemView Function(DriveItemView)> overrides = {};

  /// Every request: `(filter, cursor, limit)`.
  final List<(StorageListFilter, String?, int)> requests = [];

  /// Thrown by every call when set (e.g. `OfflineException`).
  Object? failWith;

  @override
  Future<DriveListPage> listByStorage(
    StorageListFilter filter, {
    String? cursor,
    int limit = 50,
  }) async {
    requests.add((filter, cursor, limit));
    final error = failWith;
    if (error != null) throw error;
    final since = filter.notOpenedSince;
    final rows =
        [
          for (final raw in drive.items)
            if (overrides[raw.uuid]?.call(raw) ?? raw case final i)
              if (i.owner.id == drive.me.id &&
                  i.kind != DriveItemKind.folder &&
                  (filter.kinds == null || filter.kinds!.contains(i.kind)) &&
                  (!filter.trashedOnly || i.trashedAt != null) &&
                  i.countedBytes >= (filter.minCountedBytes ?? 0) &&
                  (since == null ||
                      i.lastOpenedAt == null ||
                      i.lastOpenedAt!.isBefore(since)))
                i,
        ]..sort((a, b) {
          final c = b.countedBytes.compareTo(a.countedBytes);
          return c != 0 ? c : b.uuid.uuid.compareTo(a.uuid.uuid);
        });
    final start = cursor == null ? 0 : int.parse(cursor);
    final end = (start + limit).clamp(0, rows.length);
    return DriveListPage(
      items: rows.sublist(start.clamp(0, rows.length), end),
      nextCursor: end < rows.length ? '$end' : null,
    );
  }
}

/// A Drive harness with the fake Storage API, a usage of [usedBytes] and
/// a router with the Storage page (`/storage`), the home and the preview
/// route stubs.
class StorageTestbed {
  StorageTestbed({
    int usedBytes = 20 * mb,
    int trashBytes = 0,
    BoardRepository? board,
  }) : storage = FakeStorage.used(usedBytes, trashBytes: trashBytes) {
    h = CommandTestHarness(
      config: const DriveAppConfig(),
      storage: storage,
      board: board,
    );
    api = FakeStorageApi(h.drive);
    StorageHost.of(h.services)
      ..api = api
      ..now = () => storageNow;
  }

  late final CommandTestHarness h;
  late final FakeStorageApi api;
  final FakeStorage storage;

  ShellServices get services => h.services;

  /// Seeds an owned item of [bytes] counted bytes.
  DriveItemView seed(
    String name, {
    DriveItemKind kind = DriveItemKind.file,
    int bytes = 0,
    FileCategory? category,
    UuidValue? parent,
    bool trashed = false,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
  }) {
    final v = h.drive.seed(
      name: name,
      kind: kind,
      countedBytes: bytes,
      fileCategory: category,
      parentUuid: parent,
      trashedAt: trashed ? storageNow : null,
    );
    if (createdAt != null || lastOpenedAt != null) {
      api.overrides[v.uuid] = (i) => i.copyWith(
        createdAt: createdAt ?? i.createdAt,
        lastOpenedAt: lastOpenedAt ?? i.lastOpenedAt,
      );
    }
    return v;
  }

  /// Usage with a breakdown (documents, spreadsheets, files, trash).
  void setUsage({
    int documents = 0,
    int spreadsheets = 0,
    int presentations = 0,
    int files = 0,
    int trash = 0,
    int quota = 50 * mb,
    bool calculating = false,
  }) {
    final used = documents + spreadsheets + presentations + files + trash;
    storage.emit(
      FakeStorage.usageOf(
        used,
        quotaBytes: quota,
        trashBytes: trash,
        calculating: calculating,
      ).copyWith(
        documentsBytes: documents,
        spreadsheetsBytes: spreadsheets,
        presentationsBytes: presentations,
        filesBytes: files,
      ),
    );
  }

  late GoRouter router;

  /// Pumps the app at [location] (default `/storage`).
  Future<void> pump(
    WidgetTester tester, {
    String location = '/storage',
    Brightness brightness = Brightness.light,
    Size size = const Size(1280, 900),
    Locale locale = const Locale('en'),
    bool settle = true,
  }) async {
    final config = const DriveAppConfig();
    Page<void> page(GoRouterState st, Widget child) =>
        NoTransitionPage<void>(key: st.pageKey, child: child);
    router = GoRouter(
      navigatorKey: services.navigatorKey,
      initialLocation: location,
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (c, st) => page(
            st,
            DriveHomeScreen(
              services: services,
              location: const DriveLocation.home(),
            ),
          ),
        ),
        GoRoute(
          path: '/my-drive',
          pageBuilder: (c, st) => page(
            st,
            DriveHomeScreen(
              services: services,
              location: const DriveLocation.myDrive(),
            ),
          ),
        ),
        GoRoute(
          path: '/trash',
          pageBuilder: (c, st) => page(
            st,
            DriveHomeScreen(
              services: services,
              location: const DriveLocation.trash(),
            ),
          ),
        ),
        GoRoute(
          path: '/file/:uuid',
          builder: (c, st) => Text('preview ${st.pathParameters['uuid']}'),
        ),
        ...config.routes(services),
        ...settingsRoutes(services, page),
      ],
    );
    router.routerDelegate.addListener(
      () => services.recordLocation(router.state.uri.toString()),
    );
    services.router = router;
    await pumpWonky(
      tester,
      Router.withConfig(config: router),
      size: size,
      brightness: brightness,
      // The test app supports `en` only: the pseudo-locale is forced below.
      wrap: locale == const Locale('en')
          ? null
          : (context, child) => Localizations.override(
              context: context,
              locale: locale,
              child: child,
            ),
      extraDelegates: const [
        WonkyAppLocalizations.delegate,
        DriveLocalizations.delegate,
      ],
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }
  }

  String get location => router.state.uri.toString();

  /// The shown Storage page's controller.
  StoragePageController? get page => StorageHost.of(services).page.value;

  Future<void> dispose() => h.dispose();
}
