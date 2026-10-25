import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_sheets/features/images/image_object_view.dart';
import 'package:wonky_sheets/features/images/image_service.dart';
import 'package:wonky_sheets/features/import_export/pending_uploads.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

const _id = '0190a000-0000-7000-8000-0000000000ab';

/// The files service: refuses on quota while [full].
class _Files implements FileRepository {
  bool full = true;
  final List<String> attempts = [];
  final List<String> stored = [];

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
    attempts.add(fileUuid.uuid);
    if (full) throw FakeStorage.quotaError(neededBytes: bytes.length);
    stored.add(fileUuid.uuid);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = Uint8List.fromList([1, 2, 3]);

  late _Files files;
  late ConnectivityService net;
  late SheetsPendingUploads queue;

  setUp(() {
    files = _Files();
    net = ConnectivityService(ping: () async {});
    queue = SheetsPendingUploads(
      store: MemorySheetsUploadStore(),
      files: files,
      connectivity: net,
    );
  });

  Future<void> add() => queue.add(
    fileUuid: _id,
    itemUuid: testItemUuid,
    bytes: bytes,
    mimeType: 'image/png',
    fileName: 'a.png',
  );

  group('Given an image in the Sheets upload queue (Drive 03 §6.3)', () {
    test('when the server refuses it on quota then it stays on the device '
        'and is not retried on its own', () async {
      await queue.start();
      await add();
      await queue.flush();

      expect(files.attempts, [_id]);
      expect(queue.isOutOfStorage(_id), isTrue);
      expect(queue.contains(_id), isTrue);
      expect(await queue.bytesOf(_id), bytes);

      await queue.flush();
      expect(files.attempts, hasLength(1));
      queue.dispose();
    });

    test('when Retry runs after space was freed then it uploads', () async {
      await queue.start();
      await add();
      await queue.flush();
      files.full = false;

      queue.retry(_id);
      await queue.flush();

      expect(files.stored, [_id]);
      expect(queue.contains(_id), isFalse);
      expect(queue.isOutOfStorage(_id), isFalse);
      queue.dispose();
    });

    test('when Remove forgets it then the queue drops it', () async {
      await queue.start();
      await add();
      await queue.flush();

      await queue.cancel(_id);

      expect(queue.contains(_id), isFalse);
      queue.dispose();
    });
  });

  group('Given an image object whose upload was refused on quota', () {
    late SheetsHarness s;

    setUp(() => s = SheetsHarness.open());
    tearDown(() => s.dispose());

    for (final dark in [false, true]) {
      testWidgets('when it renders (${dark ? 'dark' : 'light'}) then it reads '
          '"Not uploaded — out of storage" with Retry and Remove', (
        tester,
      ) async {
        SheetsPendingUploads.installQueue(s.services, queue);
        await queue.start();
        await add();
        await queue.flush();
        final service = SheetsImageService.of(s.editor)
          ..remoteLoader = (_) async => null;
        var removed = 0;

        await pumpSheets(
          tester,
          s,
          dark: dark,
          child: Center(
            child: SizedBox(
              width: 320,
              height: 200,
              child: ImageObjectView(
                service: service,
                spec: const ImageSpec(fileUuid: _id),
                onRemove: () => removed++,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          find.byKey(const ValueKey('sheets.image.outOfStorage')),
          findsOneWidget,
        );
        expect(find.text('Not uploaded — out of storage'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('sheets.image.remove')));
        await tester.pump();
        expect(removed, 1);
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        expect(queue.contains(_id), isFalse);
        await tester.pumpWidget(const SizedBox());
        queue.dispose();
      });
    }

    testWidgets('when Retry is pressed after space was freed then the '
        'overlay goes away', (tester) async {
      SheetsPendingUploads.installQueue(s.services, queue);
      await queue.start();
      await add();
      await queue.flush();
      final service = SheetsImageService.of(s.editor)
        ..remoteLoader = (_) async => null;

      await pumpSheets(
        tester,
        s,
        child: Center(
          child: SizedBox(
            width: 320,
            height: 200,
            child: ImageObjectView(
              service: service,
              spec: const ImageSpec(fileUuid: _id),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('sheets.image.remove')), findsNothing);
      files.full = false;

      await tester.tap(find.byKey(const ValueKey('sheets.image.retryUpload')));
      await tester.runAsync(queue.flush);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('sheets.image.outOfStorage')),
        findsNothing,
      );
      expect(files.stored, [_id]);
      await tester.pumpWidget(const SizedBox());
      queue.dispose();
    });
  });
}
