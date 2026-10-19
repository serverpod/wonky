import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' as api;
import 'package:wonky_revlog/client.dart' show RevChunker;
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

import '../store/rev_local_store.dart';
import '../transport/rev_transport.dart';
import 'rev_file_sync.dart';

/// The RevLog client of one user and app (RevLog spec 06): the local
/// cache, the open files' connections, background sync of closed files'
/// outboxes and the offline provider.
final class RevLogClient {
  /// Creates a client over an open [store] (tests use their own [keeper]
  /// and transport; the app uses [open]).
  RevLogClient({
    required this.app,
    required this.schema,
    required this.store,
    required this.transport,
    required this.keeper,
    required this.kind,
  });

  /// Opens the client of [userUuid].
  static Future<RevLogClient> open(
    ShellServices services, {
    required String app,
    required RevSchema schema,
    required RevTransport transport,
    required String userUuid,
    required api.DriveItemKind kind,
    String? directory,
  }) async {
    final store = await RevLocalStore.open(
      schema: schema,
      userUuid: userUuid,
      app: app,
      directory: directory,
    );
    return RevLogClient(
      app: app,
      schema: schema,
      store: store,
      transport: transport,
      keeper: ShellConnectionKeeper(services.supervisor, services.connectivity),
      kind: kind,
    );
  }

  final String app;
  final RevSchema schema;
  final RevLocalStore store;
  final RevTransport transport;
  final ConnectionKeeper keeper;
  final api.DriveItemKind kind;

  /// This app instance (06 §2.6).
  final String tabId = const Uuid().v4();

  final Map<String, RevFileSync> _open = {};
  final Map<String, RevFileSync> _background = {};
  late final RevOfflineProvider offline = RevOfflineProvider(this);
  Timer? _maintain;
  bool _closed = false;

  /// Opens the connection of [fileUuid] for a session.
  RevFileSync openFile(
    String fileUuid, {
    required RevModelPort port,
    RevBootstrapPlan? plan,
  }) {
    final existing = _background.remove(fileUuid);
    if (existing != null) unawaited(existing.dispose());
    final sync = RevFileSync(
      store: store,
      transport: transport,
      keeper: keeper,
      schema: schema,
      fileUuid: fileUuid,
      tabId: tabId,
      port: port,
      plan: plan,
      keyPrefix: '$app.revlog',
    );
    _open[fileUuid] = sync;
    return sync;
  }

  /// Creates [fileUuid] on this device (06 §5.1, §7.1): its [creation] op
  /// is the first outbox entry; the file opens at once and syncs once the
  /// queued drive create reached the server.
  Future<void> createLocal(String fileUuid, ChangeSet creation) async {
    await store.touchFile(fileUuid, createdLocally: true, opened: true);
    // Every row of a file made here comes from this device: the cache is
    // complete (it reopens offline from the store once synced).
    await store.markComplete(fileUuid, complete: true);
    // Big creations (copies, imports) become one group of ops.
    final ops = RevChunker.split(
      creation,
      RevCodec(schema, lenient: true),
      () => const Uuid().v7(),
    );
    await store.replaceOutbox(fileUuid, tabId, ops);
  }

  /// A session closed [fileUuid].
  Future<void> closeFile(String fileUuid, RevFileSync sync) async {
    if (identical(_open[fileUuid], sync)) _open.remove(fileUuid);
    await sync.dispose();
    offline.refresh();
    _runInBackground(syncOutboxes);
  }

  final Set<Future<void>> _running = {};

  /// Runs background [work]; [close] waits for it (the store must not
  /// close under it). Failures are logged.
  void _runInBackground(Future<void> Function() work) {
    if (_closed) return;
    late final Future<void> f;
    f = work()
        .catchError((Object e) => debugPrint('RevLog $app background: $e'))
        .whenComplete(() => _running.remove(f));
    _running.add(f);
  }

  /// Starts background work (06 §7.3, §2.5).
  void start() {
    keeper.connectivity.addListener(_onConnectivity);
    _maintain = Timer.periodic(const Duration(minutes: 5), (_) {
      _runInBackground(syncOutboxes);
    });
    _runInBackground(syncOutboxes);
    _runInBackground(maintain);
  }

  void _onConnectivity() {
    if (keeper.online) _runInBackground(syncOutboxes);
  }

  /// Sends the outboxes of files no session of this tab has open (06
  /// §7.3): one headless connection per file until its outbox is empty.
  Future<void> syncOutboxes() async {
    if (_closed || !keeper.online) return;
    for (final file in await store.filesWithOutbox()) {
      if (_open.containsKey(file) || _background.containsKey(file)) continue;
      final local = await store.loadFile(file);
      if (local?.createdLocally ?? false) {
        // Wait until the queued drive create reached the server.
        try {
          await transport.info(api.UuidValue.fromString(file));
          await store.touchFile(file, createdLocally: false);
        } on Object {
          continue;
        }
      }
      // Adopt rows of tabs that are gone (older than 10 minutes and not
      // ours); resends are idempotent (same clientOpId).
      final stale = <String>{
        for (final op in await store.outbox(file))
          if (op.tabId != tabId &&
              DateTime.now().toUtc().difference(op.op.createdAt) >
                  const Duration(minutes: 10))
            op.tabId,
      };
      await store.adopt(file, stale, tabId);
      final mine = (await store.outbox(file)).where((o) => o.tabId == tabId);
      if (mine.isEmpty) continue;
      final sync = RevFileSync(
        store: store,
        transport: transport,
        keeper: keeper,
        schema: schema,
        fileUuid: file,
        tabId: tabId,
        port: const _NoModel(),
        keyPrefix: '$app.offline',
        headless: true,
      );
      _background[file] = sync;
      await sync.open();
      unawaited(() async {
        try {
          await sync.whenSynced(timeout: const Duration(minutes: 2));
        } on Object {
          // Retried on the next sync.
        } finally {
          if (identical(_background[file], sync)) _background.remove(file);
          await sync.dispose();
          offline.refresh();
        }
      }());
    }
  }

  /// Availability (06 §2.5): keeps files opened in the last 14 days (max
  /// 50) and pinned ones; never evicts files with an outbox.
  Future<void> maintain() async {
    final files = await store.files();
    final withOutbox = (await store.filesWithOutbox()).toSet();
    final recent = [
      for (final f in files)
        if (f.lastOpenedAt != null) f,
    ]..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    final keep = {
      for (final f in recent.take(50))
        if (DateTime.now().toUtc().difference(f.lastOpenedAt!) <
            const Duration(days: 14))
          f.fileUuid,
      for (final f in files)
        if (f.pinned) f.fileUuid,
      ...withOutbox,
      ..._open.keys,
    };
    for (final f in files) {
      if (_closed) return;
      if (!keep.contains(f.fileUuid)) await store.evict(f.fileUuid);
      await store.pruneOps(f.fileUuid);
    }
    offline.refresh();
  }

  /// Closes everything.
  Future<void> close() async {
    _closed = true;
    _maintain?.cancel();
    keeper.connectivity.removeListener(_onConnectivity);
    await Future.wait([..._running]);
    for (final s in [..._open.values, ..._background.values]) {
      await s.dispose();
    }
    _open.clear();
    _background.clear();
    offline.dispose();
    await store.close();
  }
}

final class _NoModel implements RevModelPort {
  const _NoModel();

  @override
  CurrentRowReader get reader => const _NoRows();

  @override
  void apply(List<RowChange> changes, {required bool remote}) {}

  @override
  void reset() {}
}

final class _NoRows implements CurrentRowReader {
  const _NoRows();

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) => null;
}

/// Settings › Offline & storage for one app (06 §7.1).
final class RevOfflineProvider extends ChangeNotifier
    implements OfflineDataProvider {
  RevOfflineProvider(this.client) {
    refresh();
  }

  final RevLogClient client;

  /// Limits shown in Settings (web without OPFS).
  List<OfflineWarning> warnings = const [];

  Set<String> _complete = const {};
  OfflineUsage _usage = OfflineUsage.empty;
  bool _disposed = false;

  @override
  String get id => client.app;

  @override
  bool? isAvailableOffline(api.DriveItemView item) {
    if (item.kind != client.kind) return null;
    final file = item.contentRef?.uuid ?? item.uuid.uuid;
    return _complete.contains(file);
  }

  @override
  OfflineUsage get usage => _usage;

  /// Re-reads the cache state.
  void refresh() {
    unawaited(() async {
      try {
        final files = await client.store.files();
        final pending = await client.store.filesWithOutbox();
        final bytes = await client.store.usageBytes();
        if (_disposed) return;
        _complete = {
          for (final f in files)
            if (f.complete) f.fileUuid,
        };
        _usage = OfflineUsage(
          documents: _complete.length,
          pinned: files.where((f) => f.pinned).length,
          pendingChanges: pending.length,
          bytes: bytes,
          warnings: warnings,
        );
        notifyListeners();
      } on Object {
        // The store is closing.
      }
    }());
  }

  @override
  Future<void> clear() async {
    await client.store.clearAll();
    refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Opens a [RevLogClient] for the signed-in user and closes it when the
/// user signs out or changes (as the replica installations did).
final class RevLogInstallation {
  RevLogInstallation(this.services, this.create);

  final ShellServices services;

  /// Opens the client for a user (null: not possible, e.g. no client).
  final Future<RevLogClient?> Function(String userUuid) create;

  RevLogClient? client;
  Completer<RevLogClient> _next = Completer();
  Future<void> _switching = Future.value();
  String? _user;

  /// Starts following the signed-in user.
  void attach() {
    services.currentUser.addListener(_onUser);
    _onUser();
  }

  /// Stops and closes.
  Future<void> detach() async {
    services.currentUser.removeListener(_onUser);
    _user = null;
    await (_switching = _switching.then((_) => _close()));
  }

  /// The client once open, null when none appears within [timeout].
  Future<RevLogClient?> ready(Duration timeout) async {
    if (client != null) return client;
    try {
      return await _next.future.timeout(timeout);
    } on TimeoutException {
      return null;
    }
  }

  void _onUser() {
    final user = services.me?.uuid.uuid;
    if (user == _user) return;
    _user = user;
    _switching = _switching.then((_) async {
      await _close();
      if (user != null && user == _user) await _openFor(user);
    });
  }

  Future<void> _close() async {
    final c = client;
    client = null;
    if (c != null) {
      OfflineStorage.of(services).unregister(c.offline);
      await c.close();
    }
    if (_next.isCompleted) _next = Completer();
  }

  Future<void> _openFor(String user) async {
    try {
      final c = await create(user);
      if (c == null) return;
      if (_user != user) {
        await c.close();
        return;
      }
      client = c;
      OfflineStorage.of(services).register(c.offline);
      c.start();
      if (!_next.isCompleted) _next.complete(c);
    } catch (e, st) {
      debugPrint('Starting the local cache failed: $e\n$st');
    }
  }
}
