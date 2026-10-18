/// # WriteOffline — Wonky Write's local data (suite 12 §1)
///
/// One instance per signed-in user, on `write_cache_<userId>.db`:
///
/// | Member | What |
/// |--------|------|
/// | [install] / [ready] / [current] | Opens the user's database after sign-in (closes it on sign-out) |
/// | [load], [persistenceFor], [opened] | Stale-while-revalidate open: cached server copy + durable outbox (`WriteDocumentSession`) |
/// | [claim] / [release] | One writer per document: background sync stops while a session has it |
/// | [createDocument] | Offline-capable creation (client UUIDv7s, queued idempotent `drive.createDocument`) |
/// | [isPendingCreate], [whenCreated] | Documents whose creation is still queued |
/// | [queueMeta], [replayMeta] | Queued `document.updateMeta` (same `clientOpId` on replay) |
/// | [saveUndo], [loadUndo] | Best-effort undo/redo stacks (`LocalUndoStack`) |
/// | [uploads] | `LocalPendingUpload`: images inserted offline |
/// | [syncPinned] | Downloads documents made available offline |
/// | [syncOutboxes] | Pushes outboxes of documents that are not open |
/// | [evict] | Keeps documents opened in the last 14 days (max 50), pinned ones and ones with local changes |
/// | [isAvailableOffline], [usage], [clear] | `OfflineDataProvider` (drive badges, Settings › Offline & storage) |
library;

import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show UuidV7Generator;
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaUtils, WonkyOt;

import '../../l10n/write_l10n.dart';
import '../document/write_document_api.dart';
import '../sync/document_sync_controller.dart';
import 'pending_uploads.dart';
import 'sqlite_sync_persistence.dart';
import 'write_local_store.dart';

/// Opens a database file (tests: a temporary directory).
typedef WriteDatabaseOpener = Future<SqliteDatabase> Function(String fileName);

/// Builds the connection keeper of a background sync (tests: a simple one).
typedef WriteKeeperFactory = ConnectionKeeper Function(ShellServices services);

class _Installation {
  _Installation(this.services, this.openDatabase, this.api, this.keeper);

  final ShellServices services;
  final WriteDatabaseOpener openDatabase;
  final WriteDocumentApi Function()? api;
  final WriteKeeperFactory? keeper;
  WriteOffline? instance;
  Future<WriteOffline?>? opening;
  String? user;
  bool simulatedRestored = false;

  void onUser() {
    final me = services.me?.uuid.uuid;
    if (me == user) return;
    final previous = instance;
    instance = null;
    user = me;
    if (previous != null) unawaited(previous.close());
    if (me == null) {
      opening = null;
      return;
    }
    opening = _open(me);
  }

  Future<WriteOffline?> _open(String me) async {
    try {
      final db = await openDatabase(WriteOffline.fileNameFor(me));
      if (user != me) {
        await db.close();
        return null;
      }
      final o = WriteOffline._(
        services: services,
        userUuid: me,
        store: WriteLocalStore(db),
        apiFactory: api,
        keeperFactory: keeper,
      );
      instance = o;
      await o._start();
      return o;
    } on Object catch (e, st) {
      debugPrint('Opening the offline store failed: $e\n$st');
      return null;
    }
  }
}

/// Wonky Write's local data of one user. See the library documentation.
class WriteOffline extends ChangeNotifier implements OfflineDataProvider {
  WriteOffline._({
    required this.services,
    required this.userUuid,
    required this.store,
    this._apiFactory,
    this._keeperFactory,
    UuidV7Generator? ids,
  }) : _ids = ids ?? UuidV7Generator.instance {
    uploads = PendingUploads(
      store: store,
      files: services.repositories.files,
      connectivity: services.connectivity,
      onChanged: _scheduleRefresh,
    );
  }

  static final Expando<_Installation> _installations = Expando('WriteOffline');

  /// `write_cache_<userId>.db`.
  static String fileNameFor(String userUuid) => 'write_cache_$userUuid.db';

  /// Documents opened in the last [recentDays] days stay available offline,
  /// at most [maxRecent] of them (plus pinned ones).
  static const recentDays = 14;
  static const maxRecent = 50;

  /// Opens the signed-in user's store now and whenever the user changes
  /// (idempotent). Called from `writeCollabCommands`.
  static void install(
    ShellServices services, {
    WriteDatabaseOpener? openDatabase,
    WriteDocumentApi Function()? api,
    WriteKeeperFactory? keeper,
  }) {
    if (_installations[services] != null) return;
    final inst = _Installation(
      services,
      openDatabase ??
          (name) => LocalDatabases.open(name, migrations: writeCacheMigrations),
      api,
      keeper,
    );
    _installations[services] = inst;
    services.currentUser.addListener(inst.onUser);
    inst.onUser();
    unawaited(_restoreSimulatedOffline(services));
  }

  /// Re-applies the "Simulate offline" developer switch after a reload.
  static Future<void> _restoreSimulatedOffline(ShellServices s) async {
    try {
      final device = await s.deviceStore.read('prefs.device');
      if (device is Map && device[simulateOfflinePref] == true) {
        s.connectivity.forceOffline(true);
      }
    } catch (_) {}
  }

  /// The open store of the signed-in user (null while opening, signed out,
  /// or not installed).
  static WriteOffline? current(ShellServices services) =>
      _installations[services]?.instance;

  /// The signed-in user's store once open. Waits briefly for the profile
  /// (offline starts load it from the device); null when unavailable.
  static Future<WriteOffline?> ready(ShellServices services) async {
    final inst = _installations[services];
    if (inst == null) return null;
    if (inst.opening == null && services.me == null) {
      final c = Completer<void>();
      void l() {
        if (services.me != null && !c.isCompleted) c.complete();
      }

      services.currentUser.addListener(l);
      try {
        await c.future.timeout(const Duration(seconds: 10));
      } on TimeoutException {
        // Not signed in.
      } finally {
        services.currentUser.removeListener(l);
      }
    }
    return inst.opening;
  }

  final ShellServices services;
  final String userUuid;
  final WriteLocalStore store;
  final WriteDocumentApi Function()? _apiFactory;
  final WriteKeeperFactory? _keeperFactory;
  final UuidV7Generator _ids;

  /// Images inserted while offline.
  late final PendingUploads uploads;

  WriteDocumentApi? _api;
  WriteDocumentApi? get _remote {
    final f = _apiFactory;
    if (f != null) return _api ??= f();
    final c = services.client;
    return c == null ? null : _api ??= ServerWriteDocumentApi(c);
  }

  final Set<String> _availableItems = {};
  final Map<String, bool> _pinnedItems = {};
  final Set<String> _claimed = {};
  final Map<String, DocumentSyncController> _background = {};
  final Map<String, Future<void>> _stopping = {};
  OfflineUsage _usage = OfflineUsage.empty;
  Timer? _refreshTimer;
  StreamSubscription<DriveItemView>? _pinSub;
  bool _closed = false;
  bool _syncingOutboxes = false;
  bool _syncingPinned = false;
  bool _wasOnline = true;

  Future<void> _start() async {
    OfflineStorage.of(services).register(this);
    services.connectivity.addListener(_onConnectivity);
    _wasOnline = services.connectivity.online;
    final d = services.drive;
    if (d is CachedDriveRepository) {
      d.addListener(_onDrive);
      _pinSub = d.cache.changes.listen(_onItemChanged);
    }
    await refresh();
    await evict();
    uploads.start();
    if (services.connectivity.online) _whenOnline();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    OfflineStorage.of(services).unregister(this);
    services.connectivity.removeListener(_onConnectivity);
    final d = services.drive;
    if (d is CachedDriveRepository) d.removeListener(_onDrive);
    await _pinSub?.cancel();
    _refreshTimer?.cancel();
    uploads.dispose();
    for (final c in [..._background.values]) {
      await c.dispose();
    }
    _background.clear();
    try {
      await store.db.close();
    } catch (_) {}
    super.dispose();
  }

  void _onConnectivity() {
    final online = services.connectivity.online;
    if (online && !_wasOnline) _whenOnline();
    _wasOnline = online;
  }

  void _whenOnline() {
    unawaited(syncOutboxes());
    unawaited(syncPinned());
  }

  void _onDrive() {
    // Queued creations finish → their outboxes can go up.
    if (services.connectivity.online) unawaited(syncOutboxes());
    _scheduleRefresh();
  }

  void _onItemChanged(DriveItemView item) {
    if (item.kind != DriveItemKind.document) return;
    final doc = item.contentRef;
    if (doc == null) return;
    if (_availableItems.contains(item.uuid.uuid)) {
      if (_pinnedItems[item.uuid.uuid] != item.pinnedOffline) {
        _pinnedItems[item.uuid.uuid] = item.pinnedOffline;
        unawaited(store.setPinned(item.uuid, item.pinnedOffline));
        _scheduleRefresh();
      }
    } else if (item.pinnedOffline && services.connectivity.online) {
      unawaited(_download(item));
    }
  }

  // ---------------------------------------------------------------------------
  // OfflineDataProvider.

  @override
  String get id => 'write';

  @override
  bool? isAvailableOffline(DriveItemView item) {
    if (item.kind != DriveItemKind.document) return null;
    return _availableItems.contains(item.uuid.uuid) ||
        isPendingCreate(item.uuid);
  }

  @override
  OfflineUsage get usage => _usage;

  /// Re-reads availability and usage.
  Future<void> refresh() async {
    if (_closed) return;
    try {
      final docs = await store.list();
      final u = await store.usage();
      final items = {for (final d in docs) d.itemUuid};
      final usage = OfflineUsage(
        documents: u.documents,
        pinned: u.pinned,
        pendingChanges: u.pendingDocs,
        pendingUploads: u.uploads,
        bytes: u.bytes,
      );
      final changed =
          usage != _usage ||
          items.length != _availableItems.length ||
          !items.every(_availableItems.contains);
      _availableItems
        ..clear()
        ..addAll(items);
      _pinnedItems
        ..clear()
        ..addEntries(docs.map((d) => MapEntry(d.itemUuid, d.pinned)));
      _usage = usage;
      if (changed && !_closed) notifyListeners();
    } on Object catch (e) {
      debugPrint('Reading the offline store failed: $e');
    }
  }

  void _scheduleRefresh() {
    if (_closed) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 250), refresh);
  }

  @override
  Future<void> clear() async {
    for (final c in [..._background.values]) {
      await c.dispose();
    }
    _background.clear();
    await uploads.clear();
    await store.clear();
    if (LocalDatabases.canDelete) {
      // Desktop: the file is deleted on the next sign-in-free start; the
      // truncated tables are equivalent meanwhile.
    }
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Opening documents.

  /// The cached document of [itemUuid].
  Future<StoredDocument?> load(UuidValue itemUuid) =>
      store.loadByItem(itemUuid);

  /// The durable sync state writer of a document (restored or new).
  SqliteSyncPersistence persistenceFor({
    required UuidValue documentUuid,
    required UuidValue itemUuid,
    StoredDocument? stored,
    DriveItemView? item,
  }) => SqliteSyncPersistence(
    store,
    documentUuid: documentUuid.uuid,
    itemUuid: itemUuid.uuid,
    loggedOps: stored?.loggedOps ?? 0,
    storedOutbox: stored?.storedOutbox ?? const {},
    onWritten: _scheduleRefresh,
    item: item ?? stored?.item,
  );

  /// Stops background work on [documentUuid] before a session opens it.
  Future<void> claim(UuidValue documentUuid) async {
    final id = documentUuid.uuid;
    _claimed.add(id);
    final bg = _background.remove(id);
    if (bg != null) {
      _stopping[id] = bg.dispose();
    }
    await _stopping[id];
    unawaited(_stopping.remove(id));
  }

  /// The session closed [documentUuid].
  void release(UuidValue documentUuid) {
    _claimed.remove(documentUuid.uuid);
    _scheduleRefresh();
  }

  /// Records that [item] (document [documentUuid]) was opened: drive item,
  /// pin and time, then trims the cache.
  Future<void> opened(UuidValue documentUuid, DriveItemView item) async {
    try {
      await store.touch(documentUuid, item, opened: true);
      await evict();
    } on Object catch (e) {
      debugPrint('Updating the offline store failed: $e');
    }
  }

  /// Access to [documentUuid] was lost: drops its local copy unless it
  /// holds changes that were not sent (kept for recovery).
  Future<void> forget(UuidValue documentUuid) async {
    try {
      final docs = await store.list();
      final d = docs
          .where((d) => d.documentUuid == documentUuid.uuid)
          .firstOrNull;
      if (d != null && d.pendingOps == 0) {
        await store.deleteDocument(documentUuid.uuid);
        await refresh();
      }
    } on Object catch (e) {
      debugPrint('Removing the local copy failed: $e');
    }
  }

  /// Updates the cached drive item (title, role, pin) of [documentUuid].
  Future<void> updateItem(UuidValue documentUuid, DriveItemView item) async {
    try {
      await store.touch(documentUuid, item);
    } on Object catch (e) {
      debugPrint('Updating the offline store failed: $e');
    }
  }

  /// Drops documents that are no longer needed offline: not pinned, no
  /// local changes, not open, and not among the [maxRecent] documents
  /// opened in the last [recentDays] days.
  Future<void> evict() async {
    final docs = await store.list();
    final cutoff = clock.now().subtract(const Duration(days: recentDays));
    final recent =
        docs
            .where(
              (d) => d.lastOpenedAt != null && d.lastOpenedAt!.isAfter(cutoff),
            )
            .toList()
          ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    final keep = {for (final d in recent.take(maxRecent)) d.documentUuid};
    for (final d in docs) {
      if (d.pinned ||
          d.pendingOps > 0 ||
          keep.contains(d.documentUuid) ||
          _claimed.contains(d.documentUuid) ||
          isPendingCreate(UuidValue.fromString(d.itemUuid))) {
        continue;
      }
      await store.deleteDocument(d.documentUuid);
    }
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Creation.

  /// Whether [itemUuid]'s creation is still queued (created offline).
  bool isPendingCreate(UuidValue itemUuid) {
    final d = services.drive;
    return d is CachedDriveRepository && d.isPendingCreate(itemUuid);
  }

  /// Completes once [itemUuid] exists on the server (immediately when its
  /// creation is not queued).
  Future<void> whenCreated(UuidValue itemUuid) async {
    final d = services.drive;
    if (d is! CachedDriveRepository || !d.isPendingCreate(itemUuid)) return;
    final c = Completer<void>();
    void l() {
      if (!d.isPendingCreate(itemUuid) && !c.isCompleted) c.complete();
    }

    d.addListener(l);
    try {
      await c.future;
    } finally {
      d.removeListener(l);
    }
  }

  /// Creates a document (online or offline): client-generated UUIDv7s, the
  /// idempotent `drive.createDocument` (queued when offline) and a local
  /// copy with [content] as its first pending change, so it opens at once
  /// and its content syncs with the outbox.
  Future<DriveItemView> createDocument({
    UuidValue? parentUuid,
    required String name,
    Delta? content,
  }) async {
    final documentUuid = _ids.next();
    final itemUuid = _ids.next();
    final item = await services.drive.createDocument(
      parentUuid: parentUuid,
      name: name,
      documentUuid: documentUuid,
      itemUuid: itemUuid,
    );
    await prepareLocalDocument(
      documentUuid: item.contentRef ?? documentUuid,
      item: item,
      content: content,
    );
    if (services.connectivity.online) unawaited(syncOutboxes());
    return item;
  }

  /// Creates the local copy of a new, empty document [item] (revision 0),
  /// optionally with [content] queued as its first change.
  Future<void> prepareLocalDocument({
    required UuidValue documentUuid,
    required DriveItemView item,
    Delta? content,
  }) async {
    await store.createLocalDocument(
      documentUuid: documentUuid,
      item: item,
      clientOpId: _ids.next(),
      initial: content == null ? null : DeltaUtils.stripOverlays(content),
    );
    await refresh();
  }

  // ---------------------------------------------------------------------------
  // Metadata outbox.

  /// Queues a metadata change made offline.
  Future<void> queueMeta(
    UuidValue documentUuid,
    String field,
    String valueJson,
    UuidValue clientOpId,
  ) async {
    await store.addMetaOp(
      documentUuid,
      PendingMetaOp(
        clientOpId: clientOpId,
        field: field,
        valueJson: valueJson,
        createdAt: clock.now(),
      ),
    );
    _scheduleRefresh();
  }

  /// Sends queued metadata changes of [documentUuid] in order. Stops at the
  /// first network failure; drops changes the server refuses.
  Future<void> replayMeta(
    UuidValue documentUuid, [
    WriteDocumentApi? api,
  ]) async {
    final remote = api ?? _remote;
    if (remote == null) return;
    for (final op in await store.metaOps(documentUuid)) {
      try {
        await remote.updateMeta(
          documentUuid,
          op.field,
          op.valueJson,
          op.clientOpId,
        );
      } catch (e) {
        if (isOfflineError(e)) return;
        debugPrint('A queued document setting was refused: $e');
      }
      await store.deleteMetaOp(documentUuid, op.clientOpId);
    }
    _scheduleRefresh();
  }

  // ---------------------------------------------------------------------------
  // Undo.

  /// Stores the undo/redo stacks of [documentUuid] for the document whose
  /// hash is [docHash].
  Future<void> saveUndo(
    UuidValue documentUuid,
    Map<String, Object?> stacks,
    String docHash,
  ) async {
    try {
      await store.saveUndo(documentUuid.uuid, jsonEncode(stacks), docHash);
    } on Object catch (e) {
      debugPrint('Storing the undo history failed: $e');
    }
  }

  /// The stored stacks of [documentUuid] if they belong to [docHash].
  Future<Map<String, Object?>?> loadUndo(
    UuidValue documentUuid,
    String docHash,
  ) async {
    try {
      final r = await store.loadUndo(documentUuid.uuid);
      if (r == null || r.$2 != docHash) return null;
      return (jsonDecode(r.$1) as Map).cast<String, Object?>();
    } on Object catch (e) {
      debugPrint('Restoring the undo history failed: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Pinned documents.

  /// Downloads every document made available offline that is missing or
  /// out of date.
  Future<void> syncPinned() async {
    if (_syncingPinned || _closed || !services.connectivity.online) return;
    _syncingPinned = true;
    try {
      String? cursor;
      do {
        final page = await services.drive.list(
          filter: DriveListFilter(
            view: DriveView.offline,
            kinds: const [DriveItemKind.document],
          ),
          sort: DriveSort(field: DriveSortField.modifiedAt),
          cursor: cursor,
        );
        for (final item in page.items) {
          if (_closed || !services.connectivity.online) return;
          await _download(item);
        }
        cursor = page.nextCursor;
      } while (cursor != null);
    } catch (e) {
      if (!isOfflineError(e)) debugPrint('Downloading offline files: $e');
    } finally {
      _syncingPinned = false;
    }
  }

  final Set<String> _downloading = {};

  Future<void> _download(DriveItemView item) async {
    final doc = item.contentRef;
    final remote = _remote;
    if (doc == null || remote == null || item.kind != DriveItemKind.document) {
      return;
    }
    if (_claimed.contains(doc.uuid) || !_downloading.add(doc.uuid)) return;
    try {
      final info = await remote.getDocumentInfo(doc);
      final cached = await store.loadDocument(doc);
      if (cached != null && cached.state.revision >= info.headRevision) {
        await store.touch(doc, item);
        return;
      }
      final snap = await remote.transport(doc).getSnapshot();
      await store.putSnapshot(
        documentUuid: doc,
        item: item,
        document: Delta.fromJson(jsonDecode(snap.deltaJson) as List<dynamic>),
        revision: snap.revision,
        meta: info.meta,
      );
      _scheduleRefresh();
    } catch (e) {
      if (!isOfflineError(e)) debugPrint('Downloading ${item.name}: $e');
    } finally {
      _downloading.remove(doc.uuid);
    }
  }

  // ---------------------------------------------------------------------------
  // Background outbox sync.

  /// Sends the outboxes of documents that are not open (edited offline and
  /// closed). Each runs a headless sync session until acknowledged.
  Future<void> syncOutboxes() async {
    if (_syncingOutboxes || _closed || !services.connectivity.online) return;
    final remote = _remote;
    if (remote == null) return;
    _syncingOutboxes = true;
    try {
      for (final id in await store.documentsWithPendingOps()) {
        if (_closed || !services.connectivity.online) return;
        if (_claimed.contains(id) || _background.containsKey(id)) continue;
        final doc = UuidValue.fromString(id);
        final stored = await store.loadDocument(doc);
        if (stored == null) continue;
        if (isPendingCreate(stored.itemUuid)) continue;
        await replayMeta(doc, remote);
        if (stored.state.outbox.isEmpty) continue;
        await _syncInBackground(stored, remote);
      }
    } catch (e) {
      if (!isOfflineError(e)) debugPrint('Syncing offline changes: $e');
    } finally {
      _syncingOutboxes = false;
      _scheduleRefresh();
    }
  }

  Future<void> _syncInBackground(
    StoredDocument stored,
    WriteDocumentApi remote,
  ) async {
    final id = stored.documentUuid.uuid;
    final host = _HeadlessHost();
    final keeper =
        _keeperFactory?.call(services) ??
        ShellConnectionKeeper(services.supervisor, services.connectivity);
    final sync = DocumentSyncController(
      transport: remote.transport(stored.documentUuid),
      host: host,
      keeper: keeper,
      key: 'write.offline:$id',
      persistence: persistenceFor(
        documentUuid: stored.documentUuid,
        itemUuid: stored.itemUuid,
        stored: stored,
      ),
      ids: _ids,
    );
    _background[id] = sync;
    var lost = false;
    final sub = sync.events.listen((e) {
      if (e is SyncAccessLost) lost = true;
      if (e is SyncResynced &&
          e.lostLocalChanges &&
          e.recoveryDocument != null) {
        unawaited(_saveRecovery(stored, e.recoveryDocument!));
      }
    });
    try {
      sync.restore(stored.state);
      sync.start();
      await Future.any([
        sync.whenSynchronized(),
        Future<void>.delayed(const Duration(minutes: 2)),
      ]);
      if (lost) {
        debugPrint('Offline changes of $id cannot be sent (no access)');
      }
    } finally {
      await sub.cancel();
      if (_background[id] == sync) {
        _background.remove(id);
        await sync.dispose();
      }
    }
  }

  /// "Save my offline changes as a copy" for a document that is not open
  /// (the server rejected the offline changes, e.g. `rebaseTooOld`).
  Future<void> _saveRecovery(StoredDocument stored, Delta document) async {
    try {
      final l = writeL10nOf(services);
      final name = stored.item?.name ?? l.untitledDocument;
      final copy = await createDocument(
        parentUuid: stored.item?.parentUuid,
        name: l.sessionCopyNameOfflineChanges(name),
        content: document,
      );
      services.toasts.show(
        l.offlineChangesSavedAsCopy(name),
        description: copy.name,
        actionLabel: l.sessionOpen,
        onAction: () => services.openItem(copy),
      );
    } catch (e) {
      debugPrint('Saving offline changes as a copy failed: $e');
    }
  }
}

/// The document of a background sync session (no editor).
class _HeadlessHost implements SyncDocumentHost {
  Delta _doc = Delta()..insert('\n');

  @override
  Delta get localDocument => _doc;

  @override
  void applyRemoteChange(Delta change, RemoteChangeInfo info) =>
      _doc = WonkyOt.apply(_doc, change);

  @override
  void resetDocument(Delta document) => _doc = document;
}
