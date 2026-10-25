@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

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

    test(
      'when creating an upload then a description is returned and the file is pending',
      () async {
        final uuid = const Uuid().v7obj();

        final ticket = await endpoints.file.createUpload(
          anna.endpointSession,
          uuid,
          doc.uuid,
          'photo.png',
          'image/png',
          1000,
        );
        final url = await endpoints.file.getUrl(anna.endpointSession, uuid);

        expect(ticket.uploadDescription, isNotNull);
        expect(url.status, StoredFileStatus.pending);
        expect(url.url, isNull);
      },
    );

    test(
      'when repeating createUpload with the same uuid then it succeeds again',
      () async {
        final uuid = const Uuid().v7obj();
        await endpoints.file.createUpload(
          anna.endpointSession,
          uuid,
          doc.uuid,
          'a.png',
          'image/png',
          10,
        );

        final again = await endpoints.file.createUpload(
          anna.endpointSession,
          uuid,
          doc.uuid,
          'a.png',
          'image/png',
          10,
        );

        expect(again.fileUuid, uuid);
      },
    );

    test('when uploading an unsupported type then it is refused', () async {
      await expectLater(
        endpoints.file.createUpload(
          anna.endpointSession,
          const Uuid().v7obj(),
          doc.uuid,
          'evil.svg',
          'image/svg+xml',
          10,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when uploading a BMP then it is refused', () async {
      await expectLater(
        endpoints.file.createUpload(
          anna.endpointSession,
          const Uuid().v7obj(),
          doc.uuid,
          'scan.bmp',
          'image/bmp',
          10,
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.message,
            'message',
            'Unsupported image type "image/bmp".',
          ),
        ),
      );
      expect(
        FileService.sniffImage(Uint8List.fromList([0x42, 0x4D, 0, 0])),
        isNull,
      );
    });

    test('when uploading a too large image then it is refused', () async {
      await expectLater(
        endpoints.file.createUpload(
          anna.endpointSession,
          const Uuid().v7obj(),
          doc.uuid,
          'big.png',
          'image/png',
          500 * 1024 * 1024,
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.tooLarge,
          ),
        ),
      );
    });

    test('when a viewer creates an image upload then it is refused', () async {
      final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
      await TestDrive.share(endpoints, doc, anna, vic, AccessRole.viewer);

      await expectLater(
        endpoints.file.createUpload(
          vic.endpointSession,
          const Uuid().v7obj(),
          doc.uuid,
          'a.png',
          'image/png',
          10,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test(
      'when a file of the document is ready then collaborators get a signed url and strangers do not',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
        final item = await DriveItem.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(doc.uuid),
        );
        final file = await FileService.storeServerFile(
          anna.session,
          ownerId: anna.id,
          itemId: item!.id,
          kind: StoredFileKind.image,
          fileName: 'x.png',
          mimeType: 'image/png',
          bytes: Uint8List.fromList([
            0x89,
            0x50,
            0x4E,
            0x47,
            0x0D,
            0x0A,
            0x1A,
            0x0A,
          ]),
        );

        final url = await endpoints.file.getUrl(
          bo.endpointSession,
          file.fileUuid,
        );

        expect(url.status, StoredFileStatus.ready);
        expect(url.url, isNotNull);
        await expectLater(
          endpoints.file.getUrl(eve.endpointSession, file.fileUuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );
  });

  group('Given image bytes', () {
    test('when sniffing PNG, JPEG and text then the types are detected', () {
      expect(
        FileService.sniffImage(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ),
        'image/png',
      );
      expect(
        FileService.sniffImage(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0])),
        'image/jpeg',
      );
      expect(
        FileService.sniffImage(Uint8List.fromList('<svg'.codeUnits)),
        isNull,
      );
    });
  });
}
