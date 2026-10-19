@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/drive_trash.dart';
import 'package:wonky_server/src/write/ot/document_cache.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<DriveItem?> _row(TestUser user, UuidValue uuid) =>
    DriveItem.db.findFirstRow(user.session, where: (t) => t.uuid.equals(uuid));

void main() {
  withWonkyServerpod('Given Bo\'s document deep inside Anna\'s shared folder', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView folder;
    late DriveItemView boDoc;
    late DriveItemView annaDoc;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      folder = await TestDrive.folder(endpoints, anna, name: 'Team');
      final sub = await TestDrive.folder(
        endpoints,
        anna,
        name: 'Sub',
        parentUuid: folder.uuid,
      );
      await TestDrive.share(endpoints, folder, anna, bo, AccessRole.editor);
      boDoc = await TestDrive.document(
        endpoints,
        bo,
        name: 'Bo notes',
        parentUuid: sub.uuid,
      );
      annaDoc = await TestDrive.document(
        endpoints,
        anna,
        name: 'Anna notes',
        parentUuid: sub.uuid,
      );
      await endpoints.drive.trash(anna.endpointSession, [folder.uuid]);
    });

    test('when Anna deletes the folder forever then Bo\'s document moves to '
        'his root, out of the trash, and Anna\'s items are gone', () async {
      await endpoints.drive.deletePermanently(anna.endpointSession, [
        folder.uuid,
      ]);

      final kept = await _row(bo, boDoc.uuid);
      final view = await endpoints.drive.get(bo.endpointSession, boDoc.uuid);
      expect(kept, isNotNull);
      expect(kept!.parentId, isNull);
      expect(kept.trashedAt, isNull);
      expect(view.role, AccessRole.owner);
      expect(await _row(anna, annaDoc.uuid), isNull);
      expect(await _row(anna, folder.uuid), isNull);
    });

    test(
      'when Bo\'s document is kept then Anna loses her inherited access',
      () async {
        await endpoints.drive.deletePermanently(anna.endpointSession, [
          folder.uuid,
        ]);

        await expectLater(
          endpoints.drive.get(anna.endpointSession, boDoc.uuid),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test('when Anna empties her trash then Bo\'s document is kept', () async {
      await endpoints.drive.emptyTrash(anna.endpointSession);

      expect((await _row(bo, boDoc.uuid))?.parentId, isNull);
      expect(await _row(anna, annaDoc.uuid), isNull);
    });

    test('when the trash retention passed then the purge job keeps Bo\'s '
        'document', () async {
      await DriveTrash.purgeExpiredTrash(
        sessionBuilder.build(),
        now: clock.now().toUtc().add(const Duration(days: 31)),
      );

      final kept = await _row(bo, boDoc.uuid);
      expect(kept, isNotNull);
      expect(kept!.trashedAt, isNull);
      expect(await _row(anna, annaDoc.uuid), isNull);
    });
  });

  withWonkyServerpod('Given a trashed document whose state is cached', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when it is deleted forever then its cached state is dropped',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final view = await TestDrive.document(endpoints, anna, markdown: 'Hi');
        final item = (await _row(anna, view.uuid))!;
        final doc = (await Document.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(item.contentRef!),
        ))!;
        await DocumentCache.of(anna.session, doc);
        expect(DocumentCache.isCached(doc.uuid), isTrue);
        await endpoints.drive.trash(anna.endpointSession, [view.uuid]);

        await endpoints.drive.deletePermanently(anna.endpointSession, [
          view.uuid,
        ]);

        expect(DocumentCache.isCached(doc.uuid), isFalse);
      },
    );
  });

  withWonkyServerpod('Given Anna\'s document inside Bo\'s folder inside '
      'Anna\'s folder', (sessionBuilder, endpoints) {
    test('when Anna deletes her account then Bo\'s folder survives at his '
        'root and Anna\'s items are gone', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final top = await TestDrive.folder(endpoints, anna, name: 'Top');
      final mid = await TestDrive.folder(
        endpoints,
        anna,
        name: 'Mid',
        parentUuid: top.uuid,
      );
      await TestDrive.share(endpoints, top, anna, bo, AccessRole.editor);
      final boFolder = await TestDrive.folder(
        endpoints,
        bo,
        name: 'Bo folder',
        parentUuid: mid.uuid,
      );
      final boDoc = await TestDrive.document(
        endpoints,
        bo,
        name: 'Bo doc',
        parentUuid: boFolder.uuid,
      );
      final annaInside = await TestDrive.document(
        endpoints,
        anna,
        name: 'Anna inside',
        parentUuid: boFolder.uuid,
      );

      await endpoints.user.deleteAccount(anna.endpointSession, anna.email);

      final keptFolder = await _row(bo, boFolder.uuid);
      expect(keptFolder?.parentId, isNull);
      expect((await _row(bo, boDoc.uuid))?.parentId, keptFolder?.id);
      expect(await _row(bo, annaInside.uuid), isNull);
      expect(await _row(bo, top.uuid), isNull);
      expect(await _row(bo, mid.uuid), isNull);
      final remaining = await DriveItem.db.count(
        bo.session,
        where: (t) => t.ownerId.equals(anna.id),
      );
      expect(remaining, 0);
    });
  });

  withWonkyServerpod('Given Bo is an Editor of Anna\'s document', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
    });

    test('when Bo moves it into his own folder then it is refused', () async {
      final doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
      final mine = await TestDrive.folder(endpoints, bo, name: 'Mine');

      await expectLater(
        endpoints.drive.move(bo.endpointSession, [doc.uuid], mine.uuid),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.forbidden,
          ),
        ),
      );
      expect((await _row(anna, doc.uuid))?.parentId, isNull);
    });

    test('when Bo moves it between folders of Anna\'s shared tree then it '
        'moves', () async {
      final team = await TestDrive.folder(endpoints, anna, name: 'Team');
      final archive = await TestDrive.folder(
        endpoints,
        anna,
        name: 'Archive',
        parentUuid: team.uuid,
      );
      final doc = await TestDrive.document(
        endpoints,
        anna,
        parentUuid: team.uuid,
      );
      await TestDrive.share(endpoints, team, anna, bo, AccessRole.editor);

      await endpoints.drive.move(bo.endpointSession, [doc.uuid], archive.uuid);

      final path = await endpoints.drive.path(anna.endpointSession, doc.uuid);
      expect(path.map((p) => p.name), ['Team', 'Archive']);
    });

    test('when Bo moves it into his own folder inside Anna\'s tree, trashes '
        'and deletes that folder then Anna\'s document survives', () async {
      final team = await TestDrive.folder(endpoints, anna, name: 'Team');
      final doc = await TestDrive.document(
        endpoints,
        anna,
        parentUuid: team.uuid,
      );
      await TestDrive.share(endpoints, team, anna, bo, AccessRole.editor);
      final boFolder = await TestDrive.folder(
        endpoints,
        bo,
        name: 'Bo folder',
        parentUuid: team.uuid,
      );

      await endpoints.drive.move(bo.endpointSession, [doc.uuid], boFolder.uuid);
      await endpoints.drive.trash(bo.endpointSession, [boFolder.uuid]);
      await endpoints.drive.deletePermanently(bo.endpointSession, [
        boFolder.uuid,
      ]);

      final kept = await _row(anna, doc.uuid);
      expect(kept, isNotNull);
      expect(kept!.parentId, isNull);
      expect(kept.trashedAt, isNull);
    });
  });
}
