import 'dart:async';
import 'dart:io';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show UuidV7Generator;
import 'package:wonky_write/features/editor/components/editor_services.dart';
import 'package:wonky_write/features/editor/components/wonky_components.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/images/image_services.dart';
import 'package:wonky_write/features/offline/pending_uploads.dart';
import 'package:wonky_write/features/offline/write_local_store.dart';

import '../editor/support/editor_harness.dart';

/// The files service: refuses on quota while [full], else stores.
class _Files implements FileRepository {
  bool full = true;
  final List<UuidValue> attempts = [];
  final List<UuidValue> stored = [];

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
    attempts.add(fileUuid);
    if (full) throw FakeStorage.quotaError(neededBytes: bytes.length);
    stored.add(fileUuid);
    return FileUrlView(
      fileUuid: fileUuid,
      status: StoredFileStatus.ready,
      url: 'https://files.test/$fileUuid',
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }

  @override
  Future<FileUrlView> getUrl(UuidValue fileUuid) => throw UnimplementedError();
}

final _png = Uint8List.fromList([0x89, 0x50, 0x4e, 0x47, 1, 2, 3, 4]);
final _doc = UuidValue.fromString('0190a8a0-0000-7000-8000-0000000000d0');
final _file = UuidValue.fromString('0190a8a0-0000-7000-8000-0000000000f1');

/// Image services whose [uploadStatus] is set by the test.
class _StatusImages extends EditorImageServices {
  final status = ValueNotifier<ImageUploadStatus?>(null);
  final retried = <String>[];
  final cancelled = <String>[];

  @override
  FutureOr<ImageProvider?> resolve(String src, {double? displayWidth}) => null;

  @override
  ValueListenable<ImageUploadStatus?> uploadStatus(String src) => status;

  @override
  void retry(String src) => retried.add(src);

  @override
  void cancel(String src) => cancelled.add(src);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late SqliteDatabase db;
  late WriteLocalStore store;
  late _Files files;
  late ConnectivityService net;
  late PendingUploads queue;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('wonky_image_quota_test');
    db = await LocalDatabases.open(
      'write_cache_test.db',
      migrations: writeCacheMigrations,
      directory: dir.path,
    );
    store = WriteLocalStore(db);
    files = _Files();
    net = ConnectivityService(ping: () async {});
    queue = PendingUploads(store: store, files: files, connectivity: net);
  });

  tearDown(() async {
    queue.dispose();
    await db.close();
    dir.deleteSync(recursive: true);
  });

  /// Lets the queue's background run finish (real time: SQLite I/O).
  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Waits (real time, up to 5 s) until [done].
  Future<void> until(bool Function() done) async {
    for (var i = 0; i < 250 && !done(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  group('Given an image queued on this device (Drive 03 §6.3)', () {
    test('when the server refuses it on quota then it stays on the device, '
        'is reported once and is not retried on its own', () async {
      final refused = <UuidValue>[];
      queue.refused.listen(refused.add);
      queue.start();

      await queue.add(
        fileUuid: _file,
        itemUuid: _doc,
        bytes: _png,
        mimeType: 'image/png',
        fileName: 'a.png',
      );
      await until(() => queue.isOutOfStorage(_file));

      expect(files.attempts, [_file]);
      expect(queue.isOutOfStorage(_file), isTrue);
      expect(queue.contains(_file), isTrue);
      expect(await queue.bytesOf(_file), _png);
      expect(refused, [_file]);

      net.reportSuccess();
      await settle();
      expect(files.attempts, hasLength(1));
    });

    test('when Retry runs after space was freed then it uploads and leaves '
        'the device', () async {
      queue.start();
      await queue.add(
        fileUuid: _file,
        itemUuid: _doc,
        bytes: _png,
        mimeType: 'image/png',
        fileName: 'a.png',
      );
      await until(() => queue.isOutOfStorage(_file));
      files.full = false;

      queue.retry(_file);
      await until(() => !queue.contains(_file));

      expect(files.stored, [_file]);
      expect(queue.contains(_file), isFalse);
      expect(queue.isOutOfStorage(_file), isFalse);
    });
  });

  group('Given an image inserted into a document over quota', () {
    test('when the background upload is refused then the image shows "Not '
        'uploaded — out of storage" and the dialog is asked for', () async {
      final errors = <Object>[];
      final images = WriteImageServices(
        files: files,
        documentUuid: _doc,
        ids: UuidV7Generator(),
        offlineUploads: () => queue,
        onQuotaExceeded: errors.add,
      );
      addTearDown(images.dispose);
      queue.start();

      final src = images.startUpload(
        PickedImage(name: 'a.png', bytes: _png, mimeType: 'image/png'),
      );
      await until(() => errors.isNotEmpty);

      expect(
        images.uploadStatus(src).value?.phase,
        ImageUploadPhase.outOfStorage,
      );
      expect(errors, hasLength(1));
      expect(QuotaErrorPresenter.isQuotaExceeded(errors.single), isTrue);
      final fileUuid = UuidValue.fromString(
        src.substring(WriteImageServices.scheme.length),
      );
      expect(queue.isOutOfStorage(fileUuid), isTrue);

      files.full = false;
      images.retry(src);
      await until(() => files.stored.isNotEmpty);
      await settle();

      expect(images.uploadStatus(src).value, isNull);
      expect(files.stored, [fileUuid]);
    });

    test(
      'when an image refused in an earlier session is shown then its '
      'placeholder reads out of storage and Retry hands it to the queue',
      () async {
        queue.start();
        await queue.add(
          fileUuid: _file,
          itemUuid: _doc,
          bytes: _png,
          mimeType: 'image/png',
          fileName: 'a.png',
        );
        await until(() => queue.isOutOfStorage(_file));
        final images = WriteImageServices(
          files: files,
          documentUuid: _doc,
          ids: UuidV7Generator(),
          offlineUploads: () => queue,
        );
        addTearDown(images.dispose);
        final src = '${WriteImageServices.scheme}${_file.uuid}';

        final status = images.uploadStatus(src);
        expect(status.value?.phase, ImageUploadPhase.outOfStorage);

        files.full = false;
        images.retry(src);
        await until(() => files.stored.isNotEmpty);

        expect(status.value, isNull);
        expect(files.stored, [_file]);
      },
    );

    test(
      'when Remove runs on a refused image then the queue forgets it',
      () async {
        queue.start();
        await queue.add(
          fileUuid: _file,
          itemUuid: _doc,
          bytes: _png,
          mimeType: 'image/png',
          fileName: 'a.png',
        );
        await until(() => queue.isOutOfStorage(_file));
        final images = WriteImageServices(
          files: files,
          documentUuid: _doc,
          ids: UuidV7Generator(),
          offlineUploads: () => queue,
        );
        addTearDown(images.dispose);
        final src = '${WriteImageServices.scheme}${_file.uuid}';
        images.uploadStatus(src);

        images.cancel(src);
        await until(() => !queue.contains(_file));

        expect(queue.contains(_file), isFalse);
      },
    );
  });

  group('Given the editor showing an image refused on quota', () {
    testWidgets('when it renders then the overlay reads "Not uploaded — out '
        'of storage" with Retry', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final images = _StatusImages()
        ..status.value = const ImageUploadStatus(ImageUploadPhase.outOfStorage);
      final h = EditorHarness(
        Delta()
          ..insert('Intro\n')
          ..insert({
            'image': {'id': 'embed-1', 'src': 'wonky-file://x', 'alt': ''},
          })
          ..insert('\n'),
      );
      addTearDown(h.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WonkyEditor(
              controller: h.controller,
              documentTitle: 'Test doc',
              imageServices: images,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey(WonkyEditorKeys.imageOutOfStorage)),
        findsOneWidget,
      );
      expect(find.text('Not uploaded — out of storage'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey(WonkyEditorKeys.imageUploadRetry)),
      );
      expect(images.retried, ['wonky-file://x']);
    });
  });
}
