@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
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

Matcher _code(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// `file.copyToItem` as the cross-deck and cross-app paste uses it (Slides
/// 03 §12.3, A-03-3, SL-18): images of a Write document pasted into a
/// presentation, images pasted into a deck someone else owns (charged to
/// that owner), copies of uploads that haven't finished yet (retried by
/// the client's re-homing queue) and the target role.
void main() {
  withWonkyServerpod('Given images in documents and decks', (
    sessionBuilder,
    endpoints,
  ) {
    late Session server;

    setUpAll(() => server = sessionBuilder.build());

    Future<DriveItem> row(DriveItemView v) async => (await DriveItem.db
        .findFirstRow(server, where: (t) => t.uuid.equals(v.uuid)))!;

    Future<StoredFile> image(TestUser owner, DriveItemView item) async =>
        FileService.storeServerFile(
          server,
          ownerId: owner.id,
          itemId: (await row(item)).id!,
          kind: StoredFileKind.image,
          fileName: 'dot.png',
          mimeType: 'image/png',
          bytes: _png,
        );

    Future<DriveItemView> deck(TestUser u, String name) =>
        endpoints.drive.createPresentation(u.endpointSession, null, name, null);

    test('when a viewer of a Write document pastes its image into their '
        'presentation then the copy is charged to the presentation; '
        'strangers are refused', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
      final doc = await TestDrive.document(endpoints, anna, name: 'Notes');
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
      final file = await image(anna, doc);
      final boDeck = await deck(bo, 'Bo deck');
      final copy = const Uuid().v7obj();

      final v = await endpoints.file.copyToItem(
        bo.endpointSession,
        file.fileUuid,
        copy,
        boDeck.uuid,
      );

      expect((v.fileUuid, v.status), (copy, StoredFileStatus.ready));
      expect((await row(boDeck)).attachmentBytes, _png.length);
      final eveDeck = await deck(eve, 'Eve deck');
      await expectLater(
        endpoints.file.copyToItem(
          eve.endpointSession,
          file.fileUuid,
          const Uuid().v7obj(),
          eveDeck.uuid,
        ),
        _code(WonkyErrorCode.notFound),
      );
    });

    test('when an editor pastes into a deck someone else owns then the owner '
        'is charged; a commenter of the target is refused', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final cy = await TestUsers.create(sessionBuilder, name: 'Cy');
      final annaDeck = await deck(anna, 'Anna deck');
      final boDeck = await deck(bo, 'Bo deck');
      await TestDrive.share(endpoints, annaDeck, anna, bo, AccessRole.editor);
      await TestDrive.share(
        endpoints,
        annaDeck,
        anna,
        cy,
        AccessRole.commenter,
      );
      await TestDrive.share(endpoints, boDeck, bo, cy, AccessRole.viewer);
      final file = await image(bo, boDeck);

      await endpoints.file.copyToItem(
        bo.endpointSession,
        file.fileUuid,
        const Uuid().v7obj(),
        annaDeck.uuid,
      );

      final target = await row(annaDeck);
      expect(target.attachmentBytes, _png.length);
      expect(target.ownerId, anna.id);
      await expectLater(
        endpoints.file.copyToItem(
          cy.endpointSession,
          file.fileUuid,
          const Uuid().v7obj(),
          annaDeck.uuid,
        ),
        throwsA(isA<WonkyException>()),
      );
    });

    test('when the source upload has not finished then the copy is refused '
        'without charging, and the retry succeeds once it is ready', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final a = await deck(anna, 'A');
      final b = await deck(anna, 'B');
      final file = await image(anna, a);
      await StoredFile.db.updateRow(
        server,
        file.copyWith(status: StoredFileStatus.pending),
        columns: (t) => [t.status],
      );
      final copy = const Uuid().v7obj();

      await expectLater(
        endpoints.file.copyToItem(
          anna.endpointSession,
          file.fileUuid,
          copy,
          b.uuid,
        ),
        throwsA(isA<WonkyException>()),
      );
      expect((await row(b)).attachmentBytes, 0);

      await StoredFile.db.updateRow(
        server,
        file.copyWith(status: StoredFileStatus.ready),
        columns: (t) => [t.status],
      );
      final v = await endpoints.file.copyToItem(
        anna.endpointSession,
        file.fileUuid,
        copy,
        b.uuid,
      );
      expect(v.fileUuid, copy);
      expect((await row(b)).attachmentBytes, _png.length);
    });
  });
}
