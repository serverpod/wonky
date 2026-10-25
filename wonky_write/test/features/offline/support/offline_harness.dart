import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:wonky_app/spellcheck.dart' show ShellSpelling;
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write/features/document/write_document_api.dart';
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/offline/write_local_store.dart';
import 'package:wonky_write/features/offline/write_offline.dart';
import 'package:wonky_write/features/sync/sync_transport.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../sync/support/fake_document_server.dart';

/// Polls [condition] until it holds (SQLite work runs on real I/O, so
/// `pumpEventQueue` alone is not enough).
Future<void> eventually(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String? reason,
}) async {
  final watch = Stopwatch()..start();
  while (!condition()) {
    if (watch.elapsed > timeout) {
      throw StateError('Timed out waiting${reason == null ? '' : ': $reason'}');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// The "network" of an offline test: fake servers that survive app reloads.
class FakeBackend {
  FakeBackend() : drive = FakeDriveRepository(me: TestUsers.anna);

  final FakeDriveRepository drive;

  /// One OT server per document uuid.
  final Map<String, FakeDocumentServer> documents = {};
  final List<(String doc, String field, String value, String opId)> metaWrites =
      [];
  final Map<String, List<int>> uploaded = {};

  /// Seeds a document [name] with [text] on the server.
  ({DriveItemView item, FakeDocumentServer server}) seedDocument(
    String name,
    String text,
  ) {
    final item = drive.seed(name: name);
    final doc = UuidValue.fromString(
      '00000000-0000-7000-8000-${(documents.length + 1).toRadixString(16).padLeft(12, '0')}',
    );
    final withRef = item.copyWith(contentRef: doc);
    _refs[item.uuid.uuid] = doc;
    final server = FakeDocumentServer(initial: Delta()..insert('$text\n'));
    documents[doc.uuid] = server;
    return (item: withRef, server: server);
  }

  final Map<String, UuidValue> _refs = {};

  /// The drive item as the server has it (with its content reference).
  DriveItemView? item(UuidValue itemUuid) {
    try {
      final v = drive.item(itemUuid);
      final ref = _refs[itemUuid.uuid];
      return ref == null || v.contentRef != null
          ? v
          : v.copyWith(contentRef: ref);
    } on FakeNotFound {
      return null;
    }
  }

  FakeDocumentServer serverFor(UuidValue documentUuid) =>
      documents.putIfAbsent(documentUuid.uuid, FakeDocumentServer.new);

  bool exists(UuidValue documentUuid) =>
      drive.items.any((i) => i.contentRef == documentUuid) ||
      _refs.values.contains(documentUuid);
}

/// Drive calls fail while the device is (simulated) offline.
class _NetworkDrive implements DriveRepository {
  _NetworkDrive(this.backend);

  final FakeBackend backend;

  Future<T> _net<T>(Future<T> Function() f) async {
    if (Api.simulatedOffline) throw const OfflineException('offline');
    return f();
  }

  DriveItemView _ref(DriveItemView v) => backend.item(v.uuid) ?? v;

  @override
  Future<DriveItemView> get(UuidValue uuid) =>
      _net(() async => _ref(await backend.drive.get(uuid)));

  @override
  Future<DriveListPage> list({
    UuidValue? folderUuid,
    required DriveListFilter filter,
    required DriveSort sort,
    String? cursor,
    int limit = 100,
  }) => _net(() async {
    final p = await backend.drive.list(
      folderUuid: folderUuid,
      filter: filter,
      sort: sort,
      cursor: cursor,
      limit: limit,
    );
    return DriveListPage(items: [for (final i in p.items) _ref(i)]);
  });

  @override
  Future<DriveItemView> createDocument({
    UuidValue? parentUuid,
    required String name,
    UuidValue? templateUuid,
    String? initialMarkdown,
    UuidValue? documentUuid,
    UuidValue? itemUuid,
  }) => _net(() async {
    final existing = itemUuid == null ? null : backend.item(itemUuid);
    if (existing != null) return existing; // idempotent
    return backend.drive.createDocument(
      parentUuid: parentUuid,
      name: name,
      templateUuid: templateUuid,
      initialMarkdown: initialMarkdown,
      documentUuid: documentUuid,
      itemUuid: itemUuid,
    );
  });

  @override
  Future<DriveItemView> rename(UuidValue uuid, String name) =>
      _net(() async => _ref(await backend.drive.rename(uuid, name)));

  @override
  Future<DriveItemView> setStarred(UuidValue uuid, bool starred) =>
      _net(() async => _ref(await backend.drive.setStarred(uuid, starred)));

  @override
  Future<DriveItemView> setPinnedOffline(UuidValue uuid, bool pinned) => _net(
    () async => _ref(await backend.drive.setPinnedOffline(uuid, pinned)),
  );

  @override
  Future<void> trash(List<UuidValue> uuids) =>
      _net(() => backend.drive.trash(uuids));

  @override
  Future<List<DriveItemView>> move(List<UuidValue> uuids, UuidValue? p) =>
      _net(() => backend.drive.move(uuids, p));

  @override
  Stream<DriveChange> watch() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _GatedTransport implements DocumentSyncTransport {
  _GatedTransport(this.inner, this.exists);

  final FakeTransport inner;
  final bool Function() exists;

  @override
  Stream<DocServerMessage> connect(
    int knownRevision,
    Stream<DocClientMessage> input,
  ) {
    if (Api.simulatedOffline) {
      return Stream.error(const OfflineException('offline'));
    }
    if (!exists()) {
      return Stream.error(
        WonkyException(
          code: WonkyErrorCode.notFound,
          message: 'No such document',
        ),
      );
    }
    return inner.connect(knownRevision, input);
  }

  @override
  Future<List<DocumentOpView>> getOps(int fromRevision, int toRevision) =>
      inner.getOps(fromRevision, toRevision);

  @override
  Future<DocumentSnapshotView> getSnapshot() => inner.getSnapshot();
}

/// The Write server calls against the [FakeBackend].
class OfflineTestApi implements WriteDocumentApi {
  OfflineTestApi(this.backend);

  final FakeBackend backend;
  final Map<String, FakeTransport> transports = {};

  @override
  Future<DriveItemView> getItem(UuidValue itemUuid) async {
    if (Api.simulatedOffline) throw const OfflineException('offline');
    return backend.item(itemUuid) ??
        (throw WonkyException(
          code: WonkyErrorCode.notFound,
          message: 'Not found',
        ));
  }

  @override
  Future<DocumentInfo> getDocumentInfo(UuidValue documentUuid) async {
    if (Api.simulatedOffline) throw const OfflineException('offline');
    final s = backend.serverFor(documentUuid);
    final item = backend.drive.items.firstWhere(
      (i) => backend.item(i.uuid)?.contentRef == documentUuid,
    );
    return DocumentInfo(
      documentUuid: documentUuid,
      item: item,
      headRevision: s.revision,
      meta: s.meta,
      charCount: 0,
      wordCount: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  }

  @override
  DocumentSyncTransport transport(UuidValue documentUuid) {
    final t = transports.putIfAbsent(
      documentUuid.uuid,
      () => backend
          .serverFor(documentUuid)
          .transport(
            userId: TestUsers.anna.id,
            userUuid: TestUsers.anna.uuid.uuid,
          ),
    );
    return _GatedTransport(t, () => backend.exists(documentUuid));
  }

  @override
  Future<void> updateMeta(
    UuidValue documentUuid,
    String field,
    String valueJson,
    UuidValue clientOpId,
  ) async {
    if (Api.simulatedOffline) throw const OfflineException('offline');
    backend.metaWrites.add((
      documentUuid.uuid,
      field,
      valueJson,
      clientOpId.uuid,
    ));
    backend
        .serverFor(documentUuid)
        .changeMeta(field, valueJson, authorId: TestUsers.anna.id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Files implements FileRepository {
  _Files(this.backend);

  final FakeBackend backend;

  @override
  Future<FileUrlView> upload({
    required UuidValue fileUuid,
    UuidValue? itemUuid,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    StoredFileKind kind = StoredFileKind.image,
    ImageProfile? imageProfile,
  }) async {
    if (Api.simulatedOffline) throw const OfflineException('offline');
    backend.uploaded[fileUuid.uuid] = bytes;
    return _view(fileUuid);
  }

  FileUrlView _view(UuidValue fileUuid) => FileUrlView(
    fileUuid: fileUuid,
    status: StoredFileStatus.ready,
    url: 'https://files.example.test/${fileUuid.uuid}',
    fileName: 'image.png',
    mimeType: 'image/png',
    sizeBytes: backend.uploaded[fileUuid.uuid]?.length ?? 0,
  );

  @override
  Future<FileUrlView> getUrl(UuidValue fileUuid) async => _view(fileUuid);
}

class _Unimplemented {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Comments extends _Unimplemented implements CommentRepository {
  @override
  Future<List<CommentThreadView>> listThreads(
    UuidValue itemUuid, {
    CommentFilter filter = CommentFilter.all,
  }) async => const [];

  @override
  Stream<CommentEvent> watch(UuidValue itemUuid) => const Stream.empty();
}

class _Config extends WonkyAppConfig {
  const _Config();

  @override
  WonkyAppKind get app => WonkyAppKind.write;

  @override
  String get appName => 'Wonky Write';

  @override
  DriveItemKind get primaryKind => DriveItemKind.document;

  @override
  Color get brandColor => const Color(0xff2563eb);

  @override
  Widget logo({double size = 28}) => SizedBox(width: size, height: size);

  @override
  String itemPath(String uuid) => '/d/$uuid';

  @override
  Widget buildEditor(BuildContext context, GoRouterState state, String uuid) =>
      const SizedBox();

  @override
  String untitledName(BuildContext context) => 'Untitled document';
}

/// One "app run" of Wonky Write against a [FakeBackend]: shell services
/// with the real cached drive repository, connectivity (and its test hook),
/// stream supervisor, undo service and the user's `WriteOffline` store on
/// a SQLite file in [dir]. A new `OfflineApp` on the same [device] store
/// and [dir] is an app reload.
class OfflineApp {
  OfflineApp(this.backend, {required this.dir, required this.device});

  final FakeBackend backend;
  final Directory dir;

  /// Device-local key-value storage (drive cache, pending drive ops).
  final MemoryStore device;

  late final ShellServices services;
  late final CachedDriveRepository drive;
  late final OfflineTestApi api;
  WriteOffline? offline;
  final List<WriteDocumentSession> sessions = [];

  Future<void> boot({bool online = true}) async {
    Api.simulatedOffline = false;
    final connectivity = ConnectivityService(ping: () async {});
    if (!online) connectivity.forceOffline(true);
    api = OfflineTestApi(backend);
    late final ShellServices s;
    drive = CachedDriveRepository(
      remote: _NetworkDrive(backend),
      cache: DriveCache(device),
      queue: PendingDriveOpQueue(device),
      connectivity: connectivity,
      currentUser: () => s.me,
    );
    ShellSpelling.debugDictionaries ??= noSpellDictionaries();
    s = services = ShellServices(
      config: const _Config(),
      auth: AuthController(FakeAuthRepository()),
      repositories: ShellRepositories(
        drive: drive,
        users: FakeUserRepository(),
        sharing: UnfakedSharing(),
        comments: _Comments(),
        notifications: UnfakedNotifications(),
        presence: UnfakedPresence(),
        versions: UnfakedVersions(),
        files: _Files(backend),
        meta: UnfakedMeta(),
      ),
      urls: const AppUrls(apiUrl: 'http://localhost:8080/', apps: {}),
      connectivity: connectivity,
      deviceStore: device,
    );
    s.currentUser.value = UserProfileView(
      summary: TestUsers.anna,
      createdAt: DateTime.utc(2026),
    );
    await drive.init();
    WriteOffline.install(
      s,
      openDatabase: (name) => LocalDatabases.open(
        name,
        migrations: writeCacheMigrations,
        directory: dir.path,
      ),
      api: () => api,
      keeper: (services) =>
          ShellConnectionKeeper(services.supervisor, services.connectivity),
    );
    offline = await WriteOffline.ready(s);
  }

  /// Opens [itemUuid] like the editor screen does.
  Future<WriteDocumentSession> open(UuidValue itemUuid) async {
    final session = WriteDocumentSession(
      services: services,
      itemUuid: itemUuid.uuid,
      api: api,
      keeper: ShellConnectionKeeper(services.supervisor, services.connectivity),
    );
    sessions.add(session);
    for (final h in session.undoHandlers) {
      services.undo.registerHandler(h);
    }
    await services.undo.openStack(session.undoStackKey, persist: false);
    services.undo.setActiveDocument(session.undoStackKey);
    await session.open();
    await eventually(
      () => session.phase.value != WriteSessionPhase.loading,
      reason: 'session phase',
    );
    return session;
  }

  ConnectivityService get connectivity => services.connectivity;

  void goOffline() => connectivity.forceOffline(true);

  Future<void> goOnline() async {
    connectivity.forceOffline(false);
    await eventually(() => connectivity.online, reason: 'online');
  }

  /// Closes everything like a page reload would (sessions flush their
  /// outbox on dispose).
  Future<void> shutdown() async {
    for (final s in sessions) {
      s.dispose();
      await s.whenClosed;
    }
    sessions.clear();
    await offline?.close();
    services.supervisor.dispose();
    Api.simulatedOffline = false;
  }

  /// Text of a session's local document.
  static String text(WriteDocumentSession s) => DeltaUtils.text(s.editor.delta);
}

class UnfakedSharing extends _Unimplemented implements SharingRepository {}

class UnfakedNotifications extends _Unimplemented
    implements NotificationRepository {}

class UnfakedPresence extends _Unimplemented implements PresenceRepository {}

class UnfakedVersions extends _Unimplemented implements VersionRepository {}

class UnfakedMeta extends _Unimplemented implements MetaRepository {}
