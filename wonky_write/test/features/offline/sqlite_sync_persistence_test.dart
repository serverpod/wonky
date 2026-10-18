import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write/features/offline/sqlite_sync_persistence.dart';
import 'package:wonky_write/features/offline/write_local_store.dart';
import 'package:wonky_write/features/sync/document_sync_controller.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../sync/support/fake_document_server.dart';
import 'support/offline_harness.dart';

final _doc = UuidValue.fromString('00000000-0000-7000-8000-0000000000d1');
final _item = UuidValue.fromString('00000000-0000-7000-8000-0000000000a1');

/// One "run" of a document's sync controller on the SQLite store.
class _Run {
  _Run(
    this.server,
    this.store, {
    StoredDocument? stored,
    int compactAfter = 200,
  }) : keeper = SimpleConnectionKeeper(minDelay: Duration.zero),
       host = DeltaHost() {
    persistence = SqliteSyncPersistence(
      store,
      documentUuid: _doc.uuid,
      itemUuid: _item.uuid,
      loggedOps: stored?.loggedOps ?? 0,
      storedOutbox: stored?.storedOutbox ?? const {},
      compactAfter: compactAfter,
    );
    sync = DocumentSyncController(
      transport: server.transport(),
      host: host,
      keeper: keeper,
      persistence: persistence,
      pingEvery: Duration.zero,
      gapRetry: const Duration(hours: 1),
    );
    if (stored != null) sync.restore(stored.state);
  }

  final FakeDocumentServer server;
  final WriteLocalStore store;
  final SimpleConnectionKeeper keeper;
  final DeltaHost host;
  late final SqliteSyncPersistence persistence;
  late final DocumentSyncController sync;

  String get text => DeltaUtils.text(host.doc);

  void edit(int at, String text) => host.edit(
    sync,
    Delta()
      ..retain(at)
      ..insert(text),
  );

  Future<void> close() async {
    await sync.dispose();
    keeper.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SqliteDatabase db;
  late WriteLocalStore store;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('wonky_persistence_test');
    db = await LocalDatabases.open(
      'write_cache_test.db',
      migrations: writeCacheMigrations,
      directory: dir.path,
    );
    store = WriteLocalStore(db);
  });

  tearDown(() async {
    await db.close();
    dir.deleteSync(recursive: true);
  });

  test('when the controller is reopened on the same database then the server '
      'copy and the outbox are restored and the outbox converges', () async {
    final server = FakeDocumentServer(initial: Delta()..insert('Hello\n'));
    final a = _Run(server, store);
    a.sync.start();
    await eventually(() => a.sync.isLoaded);
    a.keeper.online = false;
    var now = DateTime.utc(2026, 1, 1, 12);
    withClock(Clock(() => now), () {
      a.edit(5, ' a');
      now = now.add(const Duration(seconds: 1));
      a.edit(7, 'b');
      now = now.add(const Duration(seconds: 3));
      a.edit(8, 'c');
    });
    expect(a.sync.bufferedChunks, 2, reason: 'one chunk per 2 s');
    await a.persistence.whenDurable();
    await a.close();

    final stored = await store.loadDocument(_doc);
    expect(stored, isNotNull);
    expect(stored!.state.revision, 0);
    expect(stored.state.outbox, hasLength(2));
    expect(DeltaUtils.text(stored.state.serverDocument), 'Hello\n');

    final b = _Run(server, store, stored: stored);
    expect(b.sync.isLoaded, isTrue);
    expect(b.text, 'Hello abc\n');
    b.edit(0, '>');
    b.keeper.online = true;
    b.sync.start();
    await eventually(() => !b.sync.hasPendingChanges);
    expect(DeltaUtils.text(server.document), '>Hello abc\n');
    expect(b.text, '>Hello abc\n');
    await b.persistence.whenDurable();
    final after = await store.loadDocument(_doc);
    expect(after!.state.outbox, isEmpty);
    expect(after.state.revision, server.revision);
    expect(
      DeltaUtils.equals(after.state.serverDocument, server.document),
      isTrue,
    );
    await b.close();
  });

  test('when many remote ops arrive then the op log is compacted into the '
      'snapshot and the stored copy still equals the server', () async {
    final server = FakeDocumentServer(initial: Delta()..insert('x\n'));
    final a = _Run(server, store, compactAfter: 10);
    a.sync.start();
    await eventually(() => a.sync.isLoaded);
    for (var i = 0; i < 25; i++) {
      server.commitExternal(
        Delta()
          ..retain(0)
          ..insert('$i'),
      );
    }
    await eventually(() => a.sync.revision == 25);
    await a.persistence.whenDurable();
    final rows = await db.get('SELECT COUNT(*) AS n FROM local_document_op');
    expect(rows['n']! as int, lessThan(10));
    final stored = await store.loadDocument(_doc);
    expect(stored!.state.revision, 25);
    expect(
      DeltaUtils.equals(stored.state.serverDocument, server.document),
      isTrue,
    );
    await a.close();
    final closed = await db.get('SELECT COUNT(*) AS n FROM local_document_op');
    expect(closed['n'], 0, reason: 'folded into the snapshot on close');
  });

  test(
    'when the stored copy is ahead of the server then it is replaced by the '
    "server's document and the local state is offered for recovery",
    () async {
      final server = FakeDocumentServer(initial: Delta()..insert('Hello\n'));
      final a = _Run(server, store);
      a.sync.start();
      await eventually(() => a.sync.isLoaded);
      a.edit(5, '!');
      await eventually(() => !a.sync.hasPendingChanges);
      a.keeper.online = false;
      a.edit(0, 'local ');
      await a.persistence.whenDurable();
      await a.close();

      // The server lost its history (e.g. restored from a backup).
      final reset = FakeDocumentServer(initial: Delta()..insert('Other\n'));
      final stored = await store.loadDocument(_doc);
      final b = _Run(reset, store, stored: stored);
      final events = <SyncEvent>[];
      b.sync.events.listen(events.add);
      b.keeper.online = true;
      b.sync.start();
      await eventually(() => events.whereType<SyncResynced>().isNotEmpty);
      final resynced = events.whereType<SyncResynced>().single;
      expect(resynced.lostLocalChanges, isTrue);
      expect(DeltaUtils.text(resynced.recoveryDocument!), 'local Hello!\n');
      expect(b.text, 'Other\n');
      await b.close();
    },
  );
}
