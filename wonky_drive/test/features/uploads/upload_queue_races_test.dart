import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_drive/features/uploads/upload_queue.dart';
import 'package:wonky_drive/features/uploads/upload_store.dart';
import 'package:wonky_drive/features/uploads/upload_task.dart';

import '../../support/upload_fakes.dart';

/// Cancel races of the upload queue beyond the plain cases in
/// `upload_queue_test.dart` (DR-2): an undo (cancel that keeps the bytes)
/// followed by a redo (retry with new ids) while a server call of the first
/// attempt is still in flight, and a cancel while completing with *Convert
/// uploads* on.
void main() {
  late FakeUploadApi api;
  late ConnectivityService net;
  late UploadQueue q;
  final now = DateTime.utc(2026, 10, 15, 9);

  setUp(() async {
    api = FakeUploadApi();
    net = testConnectivity();
    q = UploadQueue(
      api: api,
      store: MemoryUploadStore(),
      connectivity: net,
      newId: sequentialIds(),
      now: () => now,
      random: Random(1),
    );
    await q.start();
  });

  tearDown(() {
    q.dispose();
    net.forceOffline(false);
    Api.simulatedOffline = false;
  });

  test('Given an upload whose createFileUpload is in flight, when it is '
      'undone and redone before the server answers, then the first '
      'reservation is released and the redo uploads under new ids', () async {
    api.createGates['a.txt'] = Completer<void>();
    final [t] = await q.enqueue([textFile('a.txt')]);
    await settle();
    expect(t.status, UploadStatus.starting);
    final firstItem = t.itemUuid;

    await q.cancel(t.id, byUndo: true);
    expect(await q.retry(t.id), isTrue);
    await settle();
    api.createGates['a.txt']!.complete();
    await settle();

    expect(t.status, UploadStatus.done);
    expect(t.itemUuid, isNot(firstItem));
    expect(api.requests.map((r) => r.itemUuid), [firstItem, t.itemUuid]);
    expect(api.calls.where((c) => c == 'cancel:a.txt'), hasLength(1));
    expect(api.items.keys, [t.itemUuid]);
    expect(api.items[t.itemUuid]!.uploadState, FileUploadState.ready);
  });

  test('Given an upload whose completion is in flight and will fail, when it '
      'is undone and redone before the server answers, then the first '
      'reservation is released and the redo uploads under new ids', () async {
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
    expect(t.status, UploadStatus.verifying);
    final firstItem = t.itemUuid;

    await q.cancel(t.id, byUndo: true);
    expect(await q.retry(t.id), isTrue);
    await settle();
    api.completeGates['a.txt']!.complete();
    await settle();

    // The first attempt releases the reservation it made (the old ids).
    expect(api.items.keys, isNot(contains(firstItem)));
    expect(api.calls, isNot(contains('cancel:?')));
    expect(t.status, UploadStatus.done);
    expect(api.items[t.itemUuid]!.uploadState, FileUploadState.ready);
  });

  test('Given Convert uploads is on, when an upload is cancelled while it is '
      'being completed and the completion succeeds, then the file is kept '
      'as uploaded and not converted', () async {
    q.convertTo = (_) => DriveItemKind.document;
    api.completeGates['notes.md'] = Completer<void>();
    final [t] = await q.enqueue([textFile('notes.md')]);
    await settle();
    expect(t.status, UploadStatus.verifying);

    await q.cancel(t.id);
    api.completeGates['notes.md']!.complete();
    await settle();

    expect(t.status, UploadStatus.done);
    expect(t.result!.kind, DriveItemKind.file);
    expect(api.calls.where((c) => c.startsWith('convert')), isEmpty);
    expect(api.calls, isNot(contains('cancel:notes.md')));
  });
}
