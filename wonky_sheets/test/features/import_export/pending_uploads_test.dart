import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/uploads.dart' show PendingUpload;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_sheets/features/import_export/pending_uploads.dart';

const _id = '0190a000-0000-7000-8000-0000000000aa';

class _Files implements FileRepository {
  final List<String> uploaded = [];
  bool fail = false;

  @override
  Future<FileUrlView> upload({
    required UuidValue fileUuid,
    UuidValue? itemUuid,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    StoredFileKind kind = StoredFileKind.image,
  }) async {
    if (fail) throw const SocketException('offline');
    uploaded.add(fileUuid.uuid);
    return FileUrlView(
      fileUuid: fileUuid,
      status: StoredFileStatus.ready,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }

  @override
  Future<FileUrlView> getUrl(UuidValue fileUuid) => throw UnimplementedError();
}

SheetsPendingUploads _queue(
  SheetsUploadStore store,
  _Files files,
  ConnectivityService net,
) => SheetsPendingUploads(store: store, files: files, connectivity: net);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = Uint8List.fromList([1, 2, 3]);

  late ConnectivityService net;
  late _Files files;

  setUp(() {
    net = ConnectivityService(ping: () async {});
    files = _Files();
  });

  group('Given an imported image queued while offline', () {
    test(
      'when the device is offline then the bytes are served locally and '
      'nothing uploads; back online the upload runs and the row goes',
      () async {
        net.forceOffline(true);
        final store = MemorySheetsUploadStore();
        final q = _queue(store, files, net);
        await q.start();

        await q.add(
          fileUuid: _id,
          bytes: bytes,
          mimeType: 'image/png',
          fileName: 'a.png',
        );

        expect(await q.bytesOf(_id), bytes);
        expect(q.contains(_id), isTrue);
        expect(files.uploaded, isEmpty);
        expect(store.rows, contains(_id));

        net.forceOffline(false);
        await q.flush();

        expect(files.uploaded, [_id]);
        expect(store.rows, isEmpty);
        expect(q.contains(_id), isFalse);
        q.dispose();
      },
    );

    test('when the app restarts then a queued upload is read back from the '
        'store, shown and uploaded', () async {
      net.forceOffline(true);
      final store = MemorySheetsUploadStore();
      final first = _queue(store, files, net);
      await first.start();
      await first.add(
        fileUuid: _id,
        bytes: bytes,
        mimeType: 'image/png',
        fileName: 'a.png',
      );
      first.dispose();

      final again = _queue(store, files, net);
      await again.start();
      expect(again.contains(_id), isTrue);
      expect(await again.bytesOf(_id), bytes);

      net.forceOffline(false);
      await again.flush();
      expect(files.uploaded, [_id]);
      again.dispose();
    });

    test('when an upload fails then the row stays for a later retry', () async {
      final store = MemorySheetsUploadStore();
      files.fail = true;
      final q = _queue(store, files, net);
      await q.start();

      await q.add(
        fileUuid: _id,
        bytes: bytes,
        mimeType: 'image/png',
        fileName: 'a.png',
      );
      await q.flush();

      expect(store.rows, contains(_id));
      expect(q.contains(_id), isTrue);
      q.dispose();
    });
  });

  group('Given the SQLite store', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('sheets_uploads'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('when a row is put then it reads back and can be removed', () async {
      final db = await LocalDatabases.open(
        'sheets_uploads_test.db',
        migrations: sheetsUploadMigrations,
        directory: dir.path,
      );
      final store = SqliteSheetsUploadStore(db);

      await store.put(
        PendingUpload(
          fileUuid: _id,
          itemUuid: _id,
          bytes: bytes,
          mimeType: 'image/png',
          fileName: 'a.png',
        ),
      );

      expect(await store.ids(), [_id]);
      final row = await store.get(_id);
      expect(row?.bytes, bytes);
      expect(row?.fileName, 'a.png');
      await store.remove(_id);
      expect(await store.ids(), isEmpty);
      await store.close();
    });
  });
}
