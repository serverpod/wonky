import 'dart:io';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show SyncState;
import 'package:wonky_write/features/document/write_document_session.dart';
import 'package:wonky_write/features/editor/controller/editor_types.dart';
import 'package:wonky_write/features/sync/document_sync_controller.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'support/offline_harness.dart';

Delta _ins(int at, String text) => Delta()
  ..retain(at)
  ..insert(text);

void _type(WriteDocumentSession s, int at, String text) => s.editor.applyLocal(
  _ins(at, text),
  label: 'Typing',
  source: LocalChangeSource.input,
);

Future<int> _pendingRows(OfflineApp app) async {
  final r = await app.offline!.store.db.get(
    'SELECT COUNT(*) AS n FROM local_pending_op',
  );
  return r['n']! as int;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late FakeBackend backend;
  late MemoryStore device;
  final apps = <OfflineApp>[];

  /// Starts (or, with the same [dir] and [device], reloads) the app.
  Future<OfflineApp> start({bool online = true}) async {
    final app = OfflineApp(backend, dir: dir, device: device);
    apps.add(app);
    await app.boot(online: online);
    return app;
  }

  setUp(() {
    dir = Directory.systemTemp.createTempSync('wonky_offline_test');
    backend = FakeBackend();
    device = MemoryStore();
  });

  tearDown(() async {
    for (final a in apps.reversed) {
      try {
        await a.shutdown();
      } catch (_) {}
    }
    apps.clear();
    Api.simulatedOffline = false;
    dir.deleteSync(recursive: true);
  });

  group('Given a document edited offline', () {
    test(
      'when the app reloads offline then the document opens from the device '
      'with the unsent changes, and they reach the server once online',
      () async {
        final seeded = backend.seedDocument('Plan', 'Hello');
        final app = await start();
        final s1 = await app.open(seeded.item.uuid);
        expect(OfflineApp.text(s1), 'Hello\n');

        app.goOffline();
        await eventually(() => s1.syncStatus.value.state == SyncState.offline);
        _type(s1, 5, ' world');
        _type(s1, 11, '!');
        expect(OfflineApp.text(s1), 'Hello world!\n');
        expect(s1.syncStatus.value.pendingChanges, greaterThan(0));
        await app.shutdown();

        // Reload while still offline.
        final app2 = await start(online: false);
        expect(await _pendingRows(app2), greaterThan(0));
        final s2 = await app2.open(seeded.item.uuid);
        // ignore: avoid_print
        print('DEBUG ${s2.error} ${await app2.offline!.store.list()}');
        expect(s2.phase.value, WriteSessionPhase.ready);
        expect(s2.openedFromCache, isTrue);
        expect(OfflineApp.text(s2), 'Hello world!\n');
        expect(s2.title, 'Plan');
        expect(DeltaUtils.text(seeded.server.document), 'Hello\n');

        // Keep editing, then come back online.
        _type(s2, 0, '> ');
        await app2.goOnline();
        await eventually(
          () => DeltaUtils.text(seeded.server.document) == '> Hello world!\n',
          reason: 'server converges',
        );
        await eventually(() => !s2.sync!.hasPendingChanges);
        expect(OfflineApp.text(s2), '> Hello world!\n');
        await eventually(() => s2.syncStatus.value.state == SyncState.saved);
        await eventually(() => app2.offline!.usage.pendingChanges == 0);
      },
    );

    test('when a collaborator edited meanwhile then the offline changes are '
        'rebased and both sides converge', () async {
      final seeded = backend.seedDocument('Plan', 'Hello');
      final app = await start();
      final s1 = await app.open(seeded.item.uuid);
      app.goOffline();
      await eventually(() => !s1.sync!.isConnected);
      _type(s1, 5, ' world');
      seeded.server.commitExternal(_ins(0, 'Bo: '));
      await app.goOnline();
      await eventually(
        () => DeltaUtils.text(seeded.server.document) == 'Bo: Hello world\n',
      );
      await eventually(() => OfflineApp.text(s1) == 'Bo: Hello world\n');
    });

    test(
      'when an op was committed but its ack was lost then the reloaded app '
      'recognizes it in the missed ops and the server applies it once',
      () async {
        final seeded = backend.seedDocument('Plan', 'Hello');
        final app = await start();
        final s1 = await app.open(seeded.item.uuid);
        seeded.server.autoDeliver = false;
        _type(s1, 5, ' world');
        await eventually(
          () => seeded.server.received.whereType<DocSubmitOp>().isNotEmpty,
          reason: 'submit reaches the server',
        );
        expect(seeded.server.revision, 1, reason: 'committed, ack held back');
        app.goOffline();
        await app.shutdown();

        final app2 = await start(online: false);
        final s2 = await app2.open(seeded.item.uuid);
        expect(OfflineApp.text(s2), 'Hello world\n');
        seeded.server.autoDeliver = true;
        await app2.goOnline();
        await eventually(() => !s2.sync!.hasPendingChanges);
        expect(seeded.server.revision, 1, reason: 'applied once');
        expect(DeltaUtils.text(seeded.server.document), 'Hello world\n');
        expect(OfflineApp.text(s2), 'Hello world\n');
        await eventually(() => app2.offline!.usage.pendingChanges == 0);
      },
    );

    test('when a sent op was lost in transit then the reloaded app resends it '
        'with the same client op id', () async {
      final seeded = backend.seedDocument('Plan', 'Hello');
      final app = await start();
      final s1 = await app.open(seeded.item.uuid);
      seeded.server.dropSubmits = true;
      _type(s1, 5, ' world');
      await eventually(
        () => seeded.server.received.whereType<DocSubmitOp>().isNotEmpty,
      );
      expect(seeded.server.revision, 0);
      app.goOffline();
      await app.shutdown();

      final app2 = await start(online: false);
      final s2 = await app2.open(seeded.item.uuid);
      seeded.server.dropSubmits = false;
      await app2.goOnline();
      await eventually(() => !s2.sync!.hasPendingChanges);
      final submits = seeded.server.received.whereType<DocSubmitOp>().toList();
      expect(submits, hasLength(2));
      expect(submits[1].clientOpId, submits[0].clientOpId);
      expect(seeded.server.revision, 1);
      expect(DeltaUtils.text(seeded.server.document), 'Hello world\n');
      expect(OfflineApp.text(s2), 'Hello world\n');
    });

    test('when editing offline for a while then the outbox holds one op per '
        '2 s of editing and it is sent as one op', () async {
      final seeded = backend.seedDocument('Plan', 'Hello');
      final app = await start();
      final s1 = await app.open(seeded.item.uuid);
      app.goOffline();
      await eventually(() => !s1.sync!.isConnected);
      for (var i = 0; i < 20; i++) {
        _type(s1, 5 + i, 'x');
      }
      expect(s1.sync!.bufferedChunks, 1);
      await s1.sync!.persistence!.whenDurable();
      expect(await _pendingRows(app), 1);

      await app.goOnline();
      await eventually(() => !s1.sync!.hasPendingChanges);
      expect(seeded.server.revision, 1);
      expect(DeltaUtils.text(seeded.server.document), 'Hello${'x' * 20}\n');
    });

    test('when undoing after a reload then the restored history reverts the '
        'offline change', () async {
      final seeded = backend.seedDocument('Plan', 'Hello');
      final app = await start();
      final s1 = await app.open(seeded.item.uuid);
      app.goOffline();
      await eventually(() => !s1.sync!.isConnected);
      _type(s1, 5, ' world');
      await app.shutdown();

      final app2 = await start(online: false);
      final s2 = await app2.open(seeded.item.uuid);
      expect(app2.services.undo.undoStepsOf(s2.undoStackKey), hasLength(1));
      await app2.services.undo.undo();
      expect(OfflineApp.text(s2), 'Hello\n');
      await app2.services.undo.redo();
      expect(OfflineApp.text(s2), 'Hello world\n');
    });

    test('when a document setting is changed offline then it is queued and '
        'sent once connected', () async {
      final seeded = backend.seedDocument('Plan', 'Hello');
      final app = await start();
      final s1 = await app.open(seeded.item.uuid);
      app.goOffline();
      await s1.setLanguage('de');
      expect(s1.meta.value.language, 'de');
      expect(backend.metaWrites, isEmpty);
      await app.goOnline();
      await eventually(() => backend.metaWrites.isNotEmpty);
      expect(backend.metaWrites.single.$2, 'language');
      expect(backend.metaWrites.single.$3, '"de"');
    });

    test('when the server rejects offline changes as too old then the local '
        'state is offered as a copy, which syncs as a new document', () async {
      final seeded = backend.seedDocument('Plan', 'Hello');
      final app = await start();
      final s1 = await app.open(seeded.item.uuid);
      app.goOffline();
      await eventually(() => !s1.sync!.isConnected);
      _type(s1, 5, ' offline');
      seeded.server.rejectNext = DocRejectCode.rebaseTooOld;
      Delta? recovery;
      final sub = s1.sync!.events.listen((e) {
        if (e is SyncResynced && e.recoveryDocument != null) {
          recovery = e.recoveryDocument;
        }
      });
      await app.goOnline();
      await eventually(() => recovery != null, reason: 'resync');
      await sub.cancel();
      expect(OfflineApp.text(s1), 'Hello\n');
      expect(DeltaUtils.text(recovery!), 'Hello offline\n');

      final copy = await s1.saveCopy(recovery!, offlineChanges: true);
      expect(copy, isNotNull);
      expect(copy!.name, 'Plan (offline changes)');
      final server = backend.serverFor(copy.contentRef!);
      await eventually(
        () => DeltaUtils.text(server.document) == 'Hello offline\n',
        reason: 'copy content synced',
      );
    });
  });

  group('Given no connection', () {
    test('when creating a document then it opens at once, is editable, and is '
        'registered and filled on the server after reconnecting', () async {
      final app = await start(online: false);
      final created = await app.services.drive.createDocument(
        name: 'Offline notes',
      );
      expect(app.drive.isPendingCreate(created.uuid), isTrue);
      final s = await app.open(created.uuid);
      expect(s.phase.value, WriteSessionPhase.ready);
      expect(s.editor.mode, EditorMode.editing);
      _type(s, 0, 'Draft');
      expect(backend.item(created.uuid), isNull);

      // Reload while still offline: still there.
      await app.shutdown();
      final app2 = await start(online: false);
      expect(app2.drive.isPendingCreate(created.uuid), isTrue);
      final s2 = await app2.open(created.uuid);
      expect(OfflineApp.text(s2), 'Draft\n');
      _type(s2, 5, '!');

      await app2.goOnline();
      await eventually(() => backend.item(created.uuid) != null);
      final server = backend.serverFor(created.contentRef!);
      await eventually(
        () => DeltaUtils.text(server.document) == 'Draft!\n',
        reason: 'content synced after registration',
      );
      expect(backend.item(created.uuid)!.name, 'Offline notes');
      expect(app2.drive.isPendingCreate(created.uuid), isFalse);
    });

    test('when a document that is not on this device is opened then it fails '
        'as unavailable offline and opens once back online', () async {
      final seeded = backend.seedDocument('Remote', 'From the server');
      final app = await start();
      // The drive listing is cached, the document is not.
      await app.services.drive.get(seeded.item.uuid);
      app.goOffline();
      final s = await app.open(seeded.item.uuid);
      expect(s.phase.value, WriteSessionPhase.failed);
      expect(isOfflineError(s.error!), isTrue);
      expect(
        OfflineStorage.of(app.services).isAvailableOffline(seeded.item),
        isFalse,
      );
      await app.goOnline();
      await eventually(() => s.phase.value == WriteSessionPhase.ready);
      expect(OfflineApp.text(s), 'From the server\n');
    });

    test('when drive operations are made offline then they are replayed in '
        'order after a reload and reconnect', () async {
      final a = backend.seedDocument('A', 'a');
      final b = backend.seedDocument('B', 'b');
      final app = await start();
      await app.services.drive.get(a.item.uuid);
      await app.services.drive.get(b.item.uuid);
      app.goOffline();
      await app.services.drive.rename(a.item.uuid, 'A2');
      await app.services.drive.setStarred(b.item.uuid, true);
      await app.services.drive.trash([a.item.uuid]);
      expect(app.drive.pendingCount, 3);
      expect(app.drive.cache.item(a.item.uuid)!.name, 'A2');
      await app.shutdown();

      final app2 = await start(online: false);
      expect(app2.drive.pendingCount, 3);
      expect(backend.drive.calls, isEmpty);
      await app2.goOnline();
      await eventually(() => app2.drive.pendingCount == 0);
      expect(backend.drive.calls, ['rename', 'setStarred', 'trash']);
      expect(backend.drive.item(a.item.uuid).name, 'A2');
      expect(backend.drive.item(a.item.uuid).trashedAt, isNotNull);
      expect(backend.drive.item(b.item.uuid).starred, isTrue);
    });
  });

  group('Given the offline store', () {
    test('when a document is made available offline then it is downloaded and '
        'opens without a connection', () async {
      final seeded = backend.seedDocument('Pinned', 'Keep me');
      final app = await start();
      await app.services.drive.setPinnedOffline(seeded.item.uuid, true);
      await eventually(
        () => app.offline!.isAvailableOffline(seeded.item) == true,
        reason: 'downloaded',
      );
      app.goOffline();
      final s = await app.open(seeded.item.uuid);
      expect(s.phase.value, WriteSessionPhase.ready);
      expect(OfflineApp.text(s), 'Keep me\n');
    });

    test('when documents were opened long ago or beyond the limit then they '
        'are evicted, except pinned ones and ones with local changes', () async {
      final app = await start();
      final o = app.offline!;
      Future<UuidValue> cached(
        String name,
        DateTime opened, {
        bool pinned = false,
      }) async {
        final v = await app.services.drive.createDocument(name: name);
        await o.prepareLocalDocument(
          documentUuid: v.contentRef!,
          item: v.copyWith(pinnedOffline: pinned),
        );
        await o.store.touch(v.contentRef!, v.copyWith(pinnedOffline: pinned));
        await o.store.db.execute(
          'UPDATE local_document SET last_opened_at = ? WHERE document_uuid = ?',
          [opened.millisecondsSinceEpoch, v.contentRef!.uuid],
        );
        return v.contentRef!;
      }

      final now = clock.now();
      final old = await cached('Old', now.subtract(const Duration(days: 20)));
      final pinned = await cached(
        'Pinned',
        now.subtract(const Duration(days: 40)),
        pinned: true,
      );
      final dirty = await cached(
        'Dirty',
        now.subtract(const Duration(days: 30)),
      );
      await o.queueMeta(
        dirty,
        'language',
        '"de"',
        UuidValue.fromString('00000000-0000-7000-8000-00000000f00d'),
      );
      final recent = <UuidValue>[
        for (var i = 0; i < 52; i++)
          await cached('R$i', now.subtract(Duration(minutes: i))),
      ];
      await o.evict();
      final left = {for (final d in await o.store.list()) d.documentUuid};
      expect(left, isNot(contains(old.uuid)));
      expect(left, contains(pinned.uuid));
      expect(left, contains(dirty.uuid));
      expect(left, containsAll(recent.take(50).map((u) => u.uuid)));
      expect(left, isNot(contains(recent[50].uuid)));
      expect(left, isNot(contains(recent[51].uuid)));
    });

    test('when an image is inserted offline then its bytes survive a reload, '
        'render locally and upload once online', () async {
      final app = await start(online: false);
      final file = UuidValue.fromString('00000000-0000-7000-8000-0000000000f1');
      final bytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3]);
      await app.offline!.uploads.add(
        fileUuid: file,
        bytes: bytes,
        mimeType: 'image/png',
        fileName: 'dot.png',
      );
      await app.shutdown();

      final app2 = await start(online: false);
      await eventually(() => app2.offline!.uploads.contains(file));
      expect(await app2.offline!.uploads.bytesOf(file), bytes);
      expect(backend.uploaded, isEmpty);
      await app2.goOnline();
      await eventually(() => backend.uploaded.containsKey(file.uuid));
      expect(backend.uploaded[file.uuid], bytes);
      await eventually(() => !app2.offline!.uploads.contains(file));
    });

    test(
      'when clearing local data then cached documents and outboxes are gone',
      () async {
        final seeded = backend.seedDocument('Plan', 'Hello');
        final app = await start();
        final s = await app.open(seeded.item.uuid);
        app.goOffline();
        _type(s, 0, 'x');
        await s.sync!.persistence!.whenDurable();
        await app.offline!.refresh();
        expect(app.offline!.usage.documents, 1);
        expect(app.offline!.usage.pendingChanges, 1);
        await clearLocalData(app.services);
        expect(app.offline!.usage.documents, 0);
        expect(await _pendingRows(app), 0);
      },
    );
  });
}
