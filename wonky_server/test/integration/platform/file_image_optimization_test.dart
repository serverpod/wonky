@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/platform/files/image_optimizer.dart';

import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_storage.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Uint8List _jpeg(int width, int height) => img.encodeJpg(
  img.Image(width: width, height: height)..clear(img.ColorRgb8(200, 80, 40)),
);

Uint8List _png(int width, int height) => img.encodePng(
  img.Image(width: width, height: height)..clear(img.ColorRgb8(0, 90, 200)),
);

/// Width and height from the header of encoded [bytes].
(int, int) _size(Uint8List bytes) {
  final info = img.findDecoderForData(bytes)!.startDecode(bytes)!;
  return (info.width, info.height);
}

/// Image optimization on upload (specs/12 §1.1 *Image optimization*):
/// images of documents become WebP (≤ 2048 px, covers 1200 × 630), by
/// local libvips in tests.
void main() {
  withWonkyServerpod('Given a document for image uploads', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView doc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      doc = await TestDrive.document(endpoints, anna);
    });

    Future<FileUrlView> upload(
      Uint8List bytes, {
      String name = 'photo.jpg',
      String mime = 'image/jpeg',
      ImageProfile? profile,
      UuidValue? fileUuid,
    }) async {
      final uuid = fileUuid ?? const Uuid().v7obj();
      await endpoints.file.createUpload(
        anna.endpointSession,
        uuid,
        doc.uuid,
        name,
        mime,
        bytes.length,
        imageProfile: profile,
      );
      await TestFiles.putBytes(anna.session, uuid, bytes);
      return endpoints.file.completeUpload(anna.endpointSession, uuid);
    }

    Future<Uint8List> stored(UuidValue fileUuid) async {
      final file = (await FileService.byUuid(anna.session, fileUuid))!;
      final data = await FileService.readBytes(anna.session, file);
      return Uint8List.sublistView(data);
    }

    test('when a large photo is uploaded then it is stored as a WebP that '
        'fits 2048 px, and the upload is deleted', () async {
      final uuid = const Uuid().v7obj();
      final jpeg = _jpeg(3000, 1500);

      final view = await upload(jpeg, fileUuid: uuid);
      final file = (await FileService.byUuid(anna.session, uuid))!;
      final bytes = await stored(uuid);

      expect(view.status, StoredFileStatus.ready);
      expect(view.mimeType, 'image/webp');
      expect(view.fileName, 'photo.webp');
      expect(view.sizeBytes, bytes.length);
      expect(file.path, 'files/image/${uuid.uuid}/web/photo.webp');
      expect(file.imageProfile, ImageProfile.content);
      expect(FileService.sniffImage(bytes), 'image/webp');
      expect(_size(bytes), (2048, 1024));
      expect(
        await anna.session.storage.fileExists(
          storageId: 'private',
          path: 'files/image/${uuid.uuid}/photo.jpg',
        ),
        isFalse,
      );
    });

    test('when a small image is uploaded then it is re-encoded without '
        'upscaling', () async {
      final view = await upload(
        _png(300, 200),
        name: 'chart.png',
        mime: 'image/png',
      );

      expect(view.mimeType, 'image/webp');
      expect(_size(await stored(view.fileUuid)), (300, 200));
    });

    test('when a cover is uploaded then it is cropped to 1200 × 630', () async {
      final view = await upload(
        _jpeg(1600, 1600),
        name: 'cover.jpg',
        profile: ImageProfile.cover,
      );

      expect(view.mimeType, 'image/webp');
      expect(_size(await stored(view.fileUuid)), (1200, 630));
    });

    test('when the quota is committed then it counts the WebP', () async {
      final view = await upload(_jpeg(2500, 2500));

      expect((await TestStorage.row(anna)).reservedBytes, 0);
      final item = (await DriveItem.db.findFirstRow(
        anna.session,
        where: (t) => t.uuid.equals(doc.uuid),
      ))!;
      expect(item.attachmentBytes, view.sizeBytes);
    });

    test('when an image is not readable then the upload fails and its '
        'reservation is released', () async {
      // A PNG signature followed by garbage passes the sniffer only.
      final broken = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
        ...List.filled(200, 7),
      ]);
      final uuid = const Uuid().v7obj();

      await expectLater(
        upload(broken, name: 'x.png', mime: 'image/png', fileUuid: uuid),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.message,
            'message',
            'The image could not be read.',
          ),
        ),
      );
      final file = (await FileService.byUuid(anna.session, uuid))!;
      expect(file.status, StoredFileStatus.failed);
      expect((await TestStorage.row(anna)).reservedBytes, 0);
    });

    test('when a profile is given for another kind then it is refused', () {
      expect(
        endpoints.file.createUpload(
          anna.endpointSession,
          const Uuid().v7obj(),
          null,
          'notes.md',
          'text/markdown',
          10,
          kind: StoredFileKind.importSource,
          imageProfile: ImageProfile.cover,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    group('and Pixtronaut fails', () {
      setUp(
        () => ImageOptimizer.transform =
            (
              session, {
              required storageId,
              required sourcePath,
              required variant,
            }) => throw StateError('Pixtronaut is down'),
      );
      tearDown(
        () => ImageOptimizer.transform = ImageOptimizer.pixtronautTransform,
      );

      test('when an image is uploaded then it is kept as uploaded', () async {
        final jpeg = _jpeg(400, 300);

        final view = await upload(jpeg);

        expect(view.status, StoredFileStatus.ready);
        expect(view.mimeType, 'image/jpeg');
        expect(await stored(view.fileUuid), jpeg);
      });
    });

    test('when an avatar is uploaded then it is cropped to 256 × 256 in '
        'public storage', () async {
      final uuid = const Uuid().v7obj();
      final jpeg = _jpeg(800, 600);
      await endpoints.user.uploadAvatar(
        anna.endpointSession,
        uuid,
        'me.jpg',
        'image/jpeg',
        jpeg.length,
      );
      await TestFiles.putBytes(anna.session, uuid, jpeg);

      final view = await endpoints.file.completeUpload(
        anna.endpointSession,
        uuid,
      );
      final file = (await FileService.byUuid(anna.session, uuid))!;

      expect(view.mimeType, 'image/webp');
      expect(file.storageId, 'public');
      expect(file.imageProfile, ImageProfile.avatar);
      expect(_size(await stored(uuid)), (256, 256));
    });

    test('when a board screenshot is uploaded then it is a WebP that fits '
        '2048 px', () async {
      final uuid = const Uuid().v7obj();
      final png = _png(2600, 1300);
      await endpoints.board.createScreenshotUpload(
        anna.endpointSession,
        uuid,
        'image/png',
        png.length,
      );
      await TestFiles.putBytes(anna.session, uuid, png);

      final view = await endpoints.file.completeUpload(
        anna.endpointSession,
        uuid,
      );

      expect(view.mimeType, 'image/webp');
      expect(view.fileName, 'screenshot.webp');
      expect(_size(await stored(uuid)), (2048, 1024));
    });

    test('when the server stores an image for a document then it is '
        're-encoded too', () async {
      final file = await FileService.storeServerFile(
        anna.session,
        ownerId: anna.id,
        kind: StoredFileKind.image,
        fileName: 'imported-1.png',
        mimeType: 'image/png',
        bytes: _png(4000, 1000),
        optimize: true,
      );

      expect(file.mimeType, 'image/webp');
      expect(file.fileName, 'imported-1.webp');
      expect(_size(await stored(file.fileUuid)), (2048, 512));
    });
  });
}
