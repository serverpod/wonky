@Tags(['integration'])
library;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';

import '../../support/file_fixtures.dart';
import '../../support/role_matrix.dart';
import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _wonky(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

void main() {
  withWonkyServerpod('Given the Drive file endpoints per role', (
    sessionBuilder,
    endpoints,
  ) {
    setUp(TestFiles.skipPreviews);

    Future<DriveItemView> file(TestUser owner) => TestFiles.upload(
      endpoints,
      owner,
      name: 'data.csv',
      bytes: utf8.encode('a,b\n1,2\n'),
    );

    forEachRole(
      'Given a shared folder, createFileUpload',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      setup: (owner) => TestDrive.folder(endpoints, owner),
      act: (caller, c) => endpoints.drive.createFileUpload(
        caller,
        TestFiles.request(name: 'a.txt', size: 1, parentUuid: c.item.uuid),
      ),
    );

    forEachRole(
      'Given a shared file, fileContentUrl for a preview',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      setup: file,
      act: (caller, c) =>
          endpoints.drive.fileContentUrl(caller, c.item.uuid, download: false),
    );

    forEachRole(
      'Given a shared file, fileContentUrl for a download',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      setup: file,
      act: (caller, c) =>
          endpoints.drive.fileContentUrl(caller, c.item.uuid, download: true),
    );

    forEachRole(
      'Given a shared file whose owner turned off exports, a download',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      setup: (owner) async {
        final item = await file(owner);
        await DriveItem.db.updateWhere(
          owner.session,
          columnValues: (t) => [t.nonEditorsCanExport(false)],
          where: (t) => t.uuid.equals(item.uuid),
        );
        return item;
      },
      act: (caller, c) =>
          endpoints.drive.fileContentUrl(caller, c.item.uuid, download: true),
    );

    forEachRole(
      'Given a shared file, updateFileMeta',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner, AccessRole.editor},
      setup: file,
      act: (caller, c) =>
          endpoints.drive.updateFileMeta(caller, c.item.uuid, '{"pages": 3}'),
    );

    forEachRole(
      'Given a shared CSV file, convertFile to a spreadsheet',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      setup: file,
      act: (caller, c) => endpoints.drive.convertFile(
        caller,
        c.item.uuid,
        DriveItemKind.spreadsheet,
        DriveImportOptions(),
      ),
    );

    forEachRole(
      'Given a shared file, copy',
      endpoints,
      sessionBuilder,
      allowed: {
        AccessRole.owner,
        AccessRole.editor,
        AccessRole.commenter,
        AccessRole.viewer,
      },
      setup: file,
      act: (caller, c) => endpoints.drive.copy(
        caller,
        c.item.uuid,
        'Copy of data.csv',
        null,
        false,
        false,
      ),
    );

    forEachRole(
      'Given a file upload in progress, completeFileUpload',
      endpoints,
      sessionBuilder,
      allowed: {AccessRole.owner},
      setup: (owner) async {
        final folder = await TestDrive.folder(endpoints, owner);
        final start = await TestFiles.start(
          endpoints,
          owner,
          name: 'a.txt',
          bytes: [1],
          parentUuid: folder.uuid,
        );
        await TestFiles.putBytes(owner.session, start.ticket.fileUuid, [1]);
        // The matrix shares the folder; the upload is inside it.
        return folder.copyWith(uuid: folder.uuid, contentRef: start.item.uuid);
      },
      act: (caller, c) =>
          endpoints.drive.completeFileUpload(caller, c.item.contentRef!),
    );
  });

  withWonkyServerpod('Given a ready file', (sessionBuilder, endpoints) {
    late TestUser anna;
    setUp(() async {
      TestFiles.skipPreviews();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });

    test(
      'when asking for the preview URL then a signed storage URL is returned',
      () async {
        final item = await TestFiles.upload(endpoints, anna, name: 'a.txt');

        final url = await endpoints.drive.fileContentUrl(
          anna.endpointSession,
          item.uuid,
          download: false,
        );

        expect(url.status, StoredFileStatus.ready);
        expect(url.url, isNotNull);
        expect(url.url, isNot(contains('/files/d/')));
        expect(url.fileName, 'a.txt');
        expect(url.mimeType, 'text/plain');
        expect(url.expiresAt, isNotNull);
      },
    );

    test(
      'when asking for the download URL then it is the token route',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'Résumé.txt',
        );

        final url = await endpoints.drive.fileContentUrl(
          anna.endpointSession,
          item.uuid,
          download: true,
        );

        final uri = Uri.parse(url.url!);
        expect(uri.pathSegments.take(3), ['files', 'd', item.contentRef!.uuid]);
        expect(uri.pathSegments.last, 'Résumé.txt');
        expect(uri.queryParameters['t'], isNotEmpty);
      },
    );

    test(
      'when the uploader asks during the upload then it is pending',
      () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: [1],
        );

        final url = await endpoints.drive.fileContentUrl(
          anna.endpointSession,
          start.item.uuid,
          download: false,
        );

        expect(url.status, StoredFileStatus.pending);
        expect(url.url, isNull);
      },
    );

    test('when asking for a document then it is invalid', () async {
      final doc = await TestDrive.document(endpoints, anna);

      await expectLater(
        endpoints.drive.fileContentUrl(
          anna.endpointSession,
          doc.uuid,
          download: false,
        ),
        _wonky(WonkyErrorCode.invalidArgument),
      );
    });

    test('when setting PDF pages then they merge into the metadata', () async {
      final item = await TestFiles.upload(
        endpoints,
        anna,
        name: 'report.pdf',
        bytes: FileFixtures.bytes('report.pdf'),
      );

      final updated = await endpoints.drive.updateFileMeta(
        anna.endpointSession,
        item.uuid,
        '{"pages": 24}',
      );
      final again = await endpoints.drive.updateFileMeta(
        anna.endpointSession,
        item.uuid,
        '{"encrypted": false}',
      );

      expect(jsonDecode(updated.fileMetaJson!), {'pages': 24});
      expect(jsonDecode(again.fileMetaJson!), {
        'pages': 24,
        'encrypted': false,
      });
    });

    test(
      'when the metadata has unknown keys or is not an object then it is invalid',
      () async {
        final item = await TestFiles.upload(endpoints, anna, name: 'a.txt');

        for (final json in [
          '{"script": "x"}',
          '[1]',
          'nope',
          '{"pages": {}}',
        ]) {
          await expectLater(
            endpoints.drive.updateFileMeta(
              anna.endpointSession,
              item.uuid,
              json,
            ),
            _wonky(WonkyErrorCode.invalidArgument),
          );
        }
      },
    );

    test(
      'when copying then the copy has its own bytes and the same type',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'report.pdf',
          bytes: FileFixtures.bytes('report.pdf'),
        );

        final copy = await endpoints.drive.copy(
          anna.endpointSession,
          item.uuid,
          'Copy of report.pdf',
          null,
          false,
          false,
        );

        expect(copy.kind, DriveItemKind.file);
        expect(copy.contentRef, isNot(item.contentRef));
        expect(copy.mimeType, 'application/pdf');
        expect(copy.sizeBytes, item.sizeBytes);
        expect(copy.uploadState, FileUploadState.ready);
        final stored = await StoredFile.db.findFirstRow(
          anna.session,
          where: (t) => t.fileUuid.equals(copy.contentRef!),
        );
        final data = await anna.session.storage.retrieveFile(
          storageId: stored!.storageId,
          path: stored.path,
        );
        expect(data.lengthInBytes, item.sizeBytes);
      },
    );

    test(
      'when converting a CSV in a folder then a spreadsheet is created next to it',
      () async {
        final folder = await TestDrive.folder(endpoints, anna);
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'budget.csv',
          bytes: utf8.encode('a,b\n1,2\n'),
          parentUuid: folder.uuid,
        );

        final report = await endpoints.drive.convertFile(
          anna.endpointSession,
          item.uuid,
          DriveItemKind.spreadsheet,
          DriveImportOptions(),
        );

        expect(report.item.kind, DriveItemKind.spreadsheet);
        expect(report.item.name, 'budget');
        expect(report.item.parentUuid, folder.uuid);
        // The original file is kept.
        expect(
          (await endpoints.drive.get(anna.endpointSession, item.uuid)).uuid,
          item.uuid,
        );
      },
    );

    test('when converting Markdown then a document is created', () async {
      final item = await TestFiles.upload(
        endpoints,
        anna,
        name: 'notes.md',
        bytes: FileFixtures.bytes('notes.md'),
      );

      final report = await endpoints.drive.convertFile(
        anna.endpointSession,
        item.uuid,
        DriveItemKind.document,
        DriveImportOptions(),
      );

      expect(report.item.kind, DriveItemKind.document);
      expect(report.item.name, 'notes');
    });

    test(
      'when a viewer converts a file in a folder then the result goes to their My Drive',
      () async {
        final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
        final folder = await TestDrive.folder(endpoints, anna);
        await TestDrive.share(endpoints, folder, anna, vic, AccessRole.viewer);
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'notes.md',
          bytes: FileFixtures.bytes('notes.md'),
          parentUuid: folder.uuid,
        );

        final report = await endpoints.drive.convertFile(
          vic.endpointSession,
          item.uuid,
          DriveItemKind.document,
          DriveImportOptions(),
        );

        expect(report.item.parentUuid, isNull);
        expect(report.item.owner.id, vic.id);
      },
    );

    test(
      'when the target does not match the type then it is invalid',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'report.pdf',
          bytes: FileFixtures.bytes('report.pdf'),
        );

        for (final target in [
          DriveItemKind.document,
          DriveItemKind.spreadsheet,
          DriveItemKind.presentation,
        ]) {
          await expectLater(
            endpoints.drive.convertFile(
              anna.endpointSession,
              item.uuid,
              target,
              DriveImportOptions(),
            ),
            _wonky(WonkyErrorCode.invalidArgument),
          );
        }
      },
    );

    test(
      'when filtering a folder by file category then only those files are listed',
      () async {
        final folder = await TestDrive.folder(endpoints, anna);
        final pdf = await TestFiles.upload(
          endpoints,
          anna,
          name: 'report.pdf',
          bytes: FileFixtures.bytes('report.pdf'),
          parentUuid: folder.uuid,
        );
        await TestFiles.upload(
          endpoints,
          anna,
          name: 'a.txt',
          parentUuid: folder.uuid,
        );
        final doc = await TestDrive.document(
          endpoints,
          anna,
          parentUuid: folder.uuid,
        );

        final page = await endpoints.drive.list(
          anna.endpointSession,
          folder.uuid,
          DriveListFilter(fileCategories: [FileCategory.pdf]),
          DriveSort(),
          null,
          100,
        );

        expect(page.items.map((i) => i.uuid).toSet(), {pdf.uuid, doc.uuid});
      },
    );

    test(
      'when searching by file category then only matching files are found',
      () async {
        await TestFiles.upload(
          endpoints,
          anna,
          name: 'quokka.pdf',
          bytes: FileFixtures.bytes('report.pdf'),
        );
        await TestFiles.upload(endpoints, anna, name: 'quokka.txt');

        final page = await endpoints.drive.search(
          anna.endpointSession,
          'quokka',
          DriveSearchFilters(
            kinds: [DriveItemKind.file],
            fileCategories: [FileCategory.text],
          ),
          null,
          50,
        );

        expect(page.items.map((i) => i.name), ['quokka.txt']);
      },
    );
  });
}
