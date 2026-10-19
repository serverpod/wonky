import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/features/uploads/upload_api.dart';
import 'package:wonky_drive/features/uploads/upload_queue.dart';
import 'package:wonky_drive/features/uploads/upload_store.dart';
import 'package:wonky_drive/features/uploads/upload_task.dart';

import '../../support/upload_fakes.dart';

/// The upload queue (Drive 02 §3.5, §4): parallelism, persistence,
/// offline queueing, retries and failures — on the in-memory store and a
/// fake server, plus the SQLite store round trip.
void main() {
  late FakeUploadApi api;
  late MemoryUploadStore store;
  late ConnectivityService net;
  late UploadQueue q;
  var now = DateTime.utc(2026, 10, 15, 9);

  UploadQueue queue({
    UploadStore? on,
    bool storeAllBytes = true,
    UuidValue Function()? ids,
  }) => UploadQueue(
    api: api,
    store: on ?? store,
    connectivity: net,
    newId: ids ?? sequentialIds(),
    storeAllBytes: storeAllBytes,
    now: () => now,
    random: Random(1),
  );

  UploadStatus statusOf(String name) =>
      q.tasks.firstWhere((t) => t.fileName == name).status;

  setUp(() {
    api = FakeUploadApi();
    store = MemoryUploadStore();
    net = testConnectivity();
    now = DateTime.utc(2026, 10, 15, 9);
  });

  tearDown(() {
    net.forceOffline(false);
    Api.simulatedOffline = false;
  });

  group('Given an online queue', () {
    setUp(() async {
      q = queue();
      await q.start();
    });
    tearDown(() => q.dispose());

    test('when 3 files are added then they upload and become ready '
        'items in the target folder', () async {
      final parent = UuidValue.fromString(
        '00000000-0000-7000-9000-000000000001',
      );
      final events = <UploadEvent>[];
      q.events.listen(events.add);

      await q.enqueue([
        textFile('a.txt'),
        textFile('b.txt'),
        textFile('c.txt'),
      ], parentUuid: parent);
      await settle();

      expect(q.tasks.map((t) => t.status), everyElement(UploadStatus.done));
      expect(api.ready.keys, unorderedEquals(['a.txt', 'b.txt', 'c.txt']));
      expect(api.requests.map((r) => r.parentUuid), everyElement(parent));
      expect(events.map((e) => (e.task.fileName, e.done)), [
        ('a.txt', true),
        ('b.txt', true),
        ('c.txt', true),
      ]);
    });

    test('when a file is uploaded then its stored bytes are dropped and '
        'its row says done', () async {
      final [t] = await q.enqueue([textFile('a.txt')]);
      await settle();

      expect(store.hasBytes(t.id), isFalse);
      expect(store.rows[t.id]!['state'], 'done');
      expect(t.result?.uploadState, FileUploadState.ready);
    });

    test('when 5 files are added then at most 3 upload at the same time, '
        'in order', () async {
      api.allSendsGate = Completer<void>();
      await q.enqueue([for (var i = 1; i <= 5; i++) textFile('f$i.txt')]);
      await settle();

      expect(api.running, 3);
      expect(
        [for (final r in api.requests) r.name],
        ['f1.txt', 'f2.txt', 'f3.txt'],
      );
      expect(statusOf('f4.txt'), UploadStatus.queued);

      api.allSendsGate!.complete();
      await settle();

      expect(api.maxRunning, 3);
      expect(q.doneCount, 5);
    });

    test('when an upload runs then progress and the batch progress are '
        'reported', () async {
      api.sendGates['a.txt'] = Completer<void>();
      final [t] = await q.enqueue([textFile('a.txt', 100)]);
      await settle();

      expect(t.status, UploadStatus.uploading);
      expect(t.progress, 0.5);
      expect(q.batchProgress, 0.5);

      api.sendGates['a.txt']!.complete();
      await settle();
      expect(t.status, UploadStatus.done);
    });

    test('when uploads have sent data for 2 s then the time left is '
        'estimated', () async {
      api.sendGates['a.txt'] = Completer<void>();
      await q.enqueue([textFile('a.txt', 100)]);
      await settle();
      expect(q.timeLeft, isNull);

      now = now.add(const Duration(seconds: 4));

      // 50 bytes in 4 s, 50 left → about 4 s.
      expect(q.timeLeft, const Duration(seconds: 4));
      api.sendGates['a.txt']!.complete();
      await settle();
    });

    test('when an upload is cancelled while sending then the server '
        'releases it and the row says cancelled', () async {
      api.sendGates['a.txt'] = Completer<void>();
      final [t] = await q.enqueue([textFile('a.txt')]);
      await settle();

      await q.cancel(t.id);
      await settle();

      expect(t.status, UploadStatus.cancelled);
      expect(api.calls, contains('cancel:a.txt'));
      expect(api.calls, isNot(contains('complete:a.txt')));
    });

    test('when an upload is cancelled while createFileUpload is in flight '
        'then the reservation it made is released (DR-2)', () async {
      api.createGates['a.txt'] = Completer<void>();
      final [t] = await q.enqueue([textFile('a.txt')]);
      await settle();
      expect(t.status, UploadStatus.starting);

      await q.cancel(t.id);
      await settle();
      expect(api.calls, isNot(contains('cancel:a.txt')));

      api.createGates['a.txt']!.complete();
      await settle();

      expect(t.status, UploadStatus.cancelled);
      expect(api.calls.where((c) => c == 'cancel:a.txt'), hasLength(1));
      expect(api.items, isEmpty);
      expect(api.calls, isNot(contains('send:a.txt')));
      expect(q.unreservedBytes, 0);
    });

    test('when an upload is cancelled while it is being completed and the '
        'completion succeeds then the row is done and nothing is released '
        '(DR-2)', () async {
      api.completeGates['a.txt'] = Completer<void>();
      final [t] = await q.enqueue([textFile('a.txt')]);
      await settle();
      expect(t.status, UploadStatus.verifying);

      await q.cancel(t.id);
      await settle();
      api.completeGates['a.txt']!.complete();
      await settle();

      expect(api.calls, isNot(contains('cancel:a.txt')));
      expect(t.status, UploadStatus.done);
      expect(api.items.values.single.uploadState, FileUploadState.ready);
    });

    test('when an upload is cancelled while it is being completed and the '
        'completion fails then the reservation is released (DR-2)', () async {
      api
        ..completeGates['a.txt'] = Completer<void>()
        ..failNext(
          'complete',
          'a.txt',
          WonkyException(
            code: WonkyErrorCode.invalidArgument,
            message: 'Incomplete',
          ),
        );
      final [t] = await q.enqueue([textFile('a.txt')]);
      await settle();

      await q.cancel(t.id);
      await settle();
      api.completeGates['a.txt']!.complete();
      await settle();

      expect(t.status, UploadStatus.cancelled);
      expect(api.calls.where((c) => c == 'cancel:a.txt'), hasLength(1));
      expect(api.items, isEmpty);
    });

    test('when the server is out of storage then the row fails with '
        '"out of storage" and Retry uploads it with new ids', () async {
      api.failNext(
        'create',
        'big.bin',
        WonkyException(
          code: WonkyErrorCode.quotaExceeded,
          message: 'Out of storage',
        ),
      );
      final [t] = await q.enqueue([textFile('big.bin')]);
      await settle();
      expect(t.status, UploadStatus.failed);
      expect(t.failure, UploadFailure.outOfStorage);
      final firstItem = t.itemUuid;

      expect(await q.retry(t.id), isTrue);
      await settle();

      expect(t.status, UploadStatus.done);
      expect(t.itemUuid, isNot(firstItem));
    });

    test('when the server reports an incomplete upload then the whole '
        'file is uploaded once more with new ids', () async {
      api.failNext(
        'complete',
        'a.txt',
        WonkyException(
          code: WonkyErrorCode.invalidArgument,
          message: 'The upload was incomplete. Try again.',
        ),
      );
      final [t] = await q.enqueue([textFile('a.txt')]);
      await settle();

      expect(t.status, UploadStatus.done);
      expect(api.requests, hasLength(2));
      expect(api.requests.first.itemUuid, isNot(api.requests.last.itemUuid));
    });

    test('when the target folder is gone then Upload to My Drive '
        'uploads into the root', () async {
      api.failNext(
        'create',
        'a.txt',
        WonkyException(code: WonkyErrorCode.notFound, message: 'Gone'),
      );
      final [t] = await q.enqueue(
        [textFile('a.txt')],
        parentUuid: UuidValue.fromString(
          '00000000-0000-7000-9000-000000000002',
        ),
        parentName: 'Team',
      );
      await settle();
      expect(t.failure, UploadFailure.folderGone);

      await q.retry(t.id, toMyDrive: true);
      await settle();

      expect(t.status, UploadStatus.done);
      expect(api.requests.last.parentUuid, isNull);
      expect(t.parentName, isNull);
    });

    test(
      'when finished rows are cleared then only running uploads stay',
      () async {
        api.sendGates['b.txt'] = Completer<void>();
        await q.enqueue([textFile('a.txt'), textFile('b.txt')]);
        await settle();

        expect(await q.clearFinished(), 1);
        expect(q.tasks.map((t) => t.fileName), ['b.txt']);
        expect(store.rows, hasLength(1));
        api.sendGates['b.txt']!.complete();
        await settle();
      },
    );

    test('when files over the size limit are rejected then they show as '
        'failed rows that are not stored', () async {
      q.addRejected([textFile('huge.raw', 99)], UploadFailure.tooLarge);

      expect(q.tasks.single.failure, UploadFailure.tooLarge);
      expect(store.rows, isEmpty);
      expect(await q.retry(q.tasks.single.id), isFalse);
    });
  });

  group('Given network trouble', () {
    tearDown(() => q.dispose());

    testWidgets('when files are added offline then they wait for the '
        'connection and upload in order when it returns', (tester) async {
      q = queue();
      await q.start();
      net.forceOffline(true);

      await q.enqueue([textFile('one.txt'), textFile('two.txt')]);
      await tester.pump();

      expect(q.tasks.map((t) => t.status), [
        UploadStatus.waitingForNetwork,
        UploadStatus.waitingForNetwork,
      ]);
      expect(api.requests, isEmpty);

      net.forceOffline(false);
      await tester.pump();
      await tester.pump();

      expect(q.doneCount, 2);
      expect([for (final r in api.requests) r.name], ['one.txt', 'two.txt']);
    });

    testWidgets('when sending fails on the network then the upload is '
        'retried with backoff and keeps its ids', (tester) async {
      q = queue();
      await q.start();
      api.failNext('send', 'a.txt', const UploadTransferException('HTTP 503'));
      final [t] = await q.enqueue([textFile('a.txt')]);
      await tester.pump();

      expect(t.status, UploadStatus.queued);
      expect(t.attempts, 1);

      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));

      expect(t.status, UploadStatus.done);
      expect(api.requests.map((r) => r.itemUuid).toSet(), hasLength(1));
    });

    testWidgets('when every automatic retry fails then the row says '
        '"network error" and Retry starts again', (tester) async {
      q = UploadQueue(
        api: api,
        store: store,
        connectivity: net,
        newId: sequentialIds(),
        maxAutomaticAttempts: 2,
        now: () => now,
        random: Random(1),
      );
      await q.start();
      for (var i = 0; i < 2; i++) {
        api.failNext(
          'send',
          'a.txt',
          const UploadTransferException('HTTP 500'),
        );
      }
      final [t] = await q.enqueue([textFile('a.txt')]);
      await tester.pump();
      now = now.add(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 3));

      expect(t.status, UploadStatus.failed);
      expect(t.failure, UploadFailure.network);

      await q.retry(t.id);
      await tester.pump();
      expect(t.status, UploadStatus.done);
    });

    test('when backoff is computed then it doubles from 2 s up to 10 min '
        'with ±20 % jitter', () {
      q = queue();
      for (final (attempt, seconds) in [(1, 2), (2, 4), (5, 32), (12, 600)]) {
        final d = q.backoff(attempt).inMilliseconds;
        expect(d, inInclusiveRange(seconds * 800, seconds * 1200));
      }
    });
  });

  group('Given a stored queue (reload)', () {
    tearDown(() => q.dispose());

    test('when the app starts again then interrupted uploads continue, '
        'finished ones are forgotten and failed ones stay', () async {
      api.sendGates['run.txt'] = Completer<void>();
      final first = queue();
      await first.start();
      await first.enqueue([textFile('done.txt'), textFile('run.txt')]);
      api.failNext(
        'create',
        'full.txt',
        WonkyException(code: WonkyErrorCode.quotaExceeded, message: ''),
      );
      await first.enqueue([textFile('full.txt')]);
      await settle();
      expect(store.rows[first.tasks[1].id]!['state'], 'uploading');
      first.dispose();

      api = FakeUploadApi();
      q = queue(ids: sequentialIds(100));
      await q.start();
      await settle();

      expect(q.tasks.map((t) => (t.fileName, t.status)), [
        ('run.txt', UploadStatus.done),
        ('full.txt', UploadStatus.failed),
      ]);
      expect(api.requests.single.name, 'run.txt');
    });

    test('when uploads waited for the connection before a reload then '
        'they start once the app is online again', () async {
      final first = queue();
      await first.start();
      net.forceOffline(true);
      await first.enqueue([textFile('later.txt')]);
      first.dispose();
      net.forceOffline(false);

      q = queue(ids: sequentialIds(100));
      await q.start();
      await settle();

      expect(q.tasks.single.status, UploadStatus.done);
    });

    test('when large files can only be kept in memory then a reload asks '
        'to add them again', () async {
      final first = queue(storeAllBytes: false);
      await first.start();
      net.forceOffline(true);
      final [small, large] = await first.enqueue([
        textFile('small.txt', 10),
        textFile('large.bin', 6 * 1024 * 1024),
      ]);
      expect(small.volatile, isFalse);
      expect(large.volatile, isTrue);
      expect(store.hasBytes(small.id), isTrue);
      expect(store.hasBytes(large.id), isFalse);
      first.dispose();

      q = queue(storeAllBytes: false);
      await q.start();
      net.forceOffline(false);
      await settle();

      expect(q.task(small.id)!.status, UploadStatus.done);
      expect(q.task(large.id)!.failure, UploadFailure.notSaved);
    });
  });

  group('Given the SQLite store', () {
    late Directory dir;
    late SqliteUploadStore db;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('drive_uploads');
      db = await SqliteUploadStore.open('user-1', directory: dir.path);
    });
    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    test('when a task is added and updated then it reads back with its '
        'bytes, state and result', () async {
      final ids = sequentialIds();
      final t = UploadTask(
        id: ids().uuid,
        batchId: 'b1',
        itemUuid: ids(),
        fileUuid: ids(),
        parentName: 'Team',
        fileName: 'notes.pdf',
        sizeBytes: 3,
        mimeType: 'application/pdf',
        lastModified: DateTime.utc(2026, 1, 2),
        createdAt: DateTime.utc(2026, 10, 15),
      );
      await db.add(t, bytesOf(3));
      t
        ..status = UploadStatus.failed
        ..failure = UploadFailure.outOfStorage
        ..error = 'Full'
        ..attempts = 2;
      await db.update(t);

      final [back] = await db.load();
      expect(back.fileName, 'notes.pdf');
      expect(back.parentName, 'Team');
      expect(back.status, UploadStatus.failed);
      expect(back.failure, UploadFailure.outOfStorage);
      expect(back.attempts, 2);
      expect(back.lastModified, DateTime.utc(2026, 1, 2).toLocal());
      expect(await db.bytes(t.id), bytesOf(3));

      await db.dropBytes(t.id);
      expect(await db.bytes(t.id), isNull);
      await db.remove(t.id);
      expect(await db.load(), isEmpty);
    });
  });
}
