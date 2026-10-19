@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/files/file_image_proxy.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// A 1×1 PNG.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  ),
);

/// `file.fetchImage` (Slides 03 A-03-4) and `file.copyToItem` of Wonky
/// Drive image files (*Insert image ▸ From Wonky Drive*, 03 §6.5.1).
void main() {
  withWonkyServerpod('Given documents and images', (sessionBuilder, endpoints) {
    late Session server;
    final fetched = <String>[];

    setUpAll(() => server = sessionBuilder.build());

    setUp(() {
      fetched.clear();
      FileImageProxy.clear();
      FileImageProxy.fetcher = (url) async {
        fetched.add(url);
        return _png;
      };
    });

    test('when a viewer fetches an image by URL then the bytes come back and '
        'are cached; without access it is refused', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
      final doc = await TestDrive.document(endpoints, anna);

      final a = await endpoints.file.fetchImage(
        anna.endpointSession,
        doc.uuid,
        'https://example.com/a.png',
      );
      final b = await endpoints.file.fetchImage(
        anna.endpointSession,
        doc.uuid,
        'https://example.com/a.png',
      );

      expect(a.lengthInBytes, _png.length);
      expect(b.lengthInBytes, _png.length);
      expect(fetched, ['https://example.com/a.png'], reason: 'cached');
      await expectLater(
        endpoints.file.fetchImage(
          eve.endpointSession,
          doc.uuid,
          'https://example.com/b.png',
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.notFound,
          ),
        ),
      );
    });

    test('when a Drive image file is copied into an item then the copy is an '
        'image of the target; other Drive files are refused', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final source = await TestDrive.document(endpoints, anna, name: 'Src');
      final target = await TestDrive.document(endpoints, anna, name: 'Deck');
      final item = (await DriveItem.db.findFirstRow(
        server,
        where: (t) => t.uuid.equals(source.uuid),
      ))!;
      final image = await FileService.storeServerFile(
        server,
        ownerId: anna.id,
        itemId: item.id,
        kind: StoredFileKind.driveFile,
        fileName: 'photo.png',
        mimeType: 'image/png',
        bytes: _png,
      );
      final pdf = await FileService.storeServerFile(
        server,
        ownerId: anna.id,
        itemId: item.id,
        kind: StoredFileKind.driveFile,
        fileName: 'doc.pdf',
        mimeType: 'application/pdf',
        bytes: _png,
      );
      final copy = const Uuid().v7obj();

      final v = await endpoints.file.copyToItem(
        anna.endpointSession,
        image.fileUuid,
        copy,
        target.uuid,
      );

      expect(v.fileUuid, copy);
      final stored = await FileService.byUuid(server, copy);
      expect(stored!.kind, StoredFileKind.image);
      await expectLater(
        endpoints.file.copyToItem(
          anna.endpointSession,
          pdf.fileUuid,
          const Uuid().v7obj(),
          target.uuid,
        ),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.notFound,
          ),
        ),
      );
    });
  });
}
