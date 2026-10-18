@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/errors.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/config/wonky_config.dart';
import 'package:wonky_server/src/platform/drive/drive_file_service.dart';
import 'package:wonky_server/src/platform/storage/storage_service.dart';

import '../../support/file_fixtures.dart';
import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _wonky(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// A storage service that refuses reservations or commits (quota paths
/// of Drive 03 §5 without D-9's counters).
class _RefusingStorage extends PassThroughStorageService {
  _RefusingStorage({this.refuseReserve = false, this.refuseCommit = false});

  final bool refuseReserve;
  final bool refuseCommit;
  final released = <UuidValue>[];

  WonkyException get _error => Errors.quotaExceeded(
    QuotaExceededDetails(
      neededBytes: 10,
      availableBytes: 0,
      quotaBytes: 10,
      chargedUserId: 0,
      chargedUserName: 'Anna',
      isCaller: true,
      reason: QuotaReason.upload,
    ),
  );

  @override
  Future<void> reserve(
    Session session, {
    required int userId,
    required UuidValue fileUuid,
    int? itemId,
    required int bytes,
    String reason = QuotaReason.upload,
    int? callerUserId,
    Transaction? transaction,
  }) async {
    if (refuseReserve) throw _error;
  }

  @override
  Future<void> commitReservation(
    Session session,
    UuidValue fileUuid,
    int actualBytes, {
    Transaction? transaction,
  }) async {
    if (refuseCommit) throw _error;
  }

  @override
  Future<void> releaseReservation(
    Session session,
    UuidValue fileUuid, {
    Transaction? transaction,
  }) async => released.add(fileUuid);
}

void main() {
  withWonkyServerpod('Given Drive file uploads', (sessionBuilder, endpoints) {
    late TestUser anna;
    late StorageService installed;
    late WonkyConfig config;
    setUp(() async {
      TestFiles.skipPreviews();
      installed = StorageService.instance;
      config = WonkyConfig.current;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });
    tearDown(() {
      StorageService.instance = installed;
      WonkyConfig.current = config;
    });

    test(
      'when creating, uploading and completing then the item is ready with the sniffed type',
      () async {
        final bytes = FileFixtures.bytes('report.pdf');

        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'report.pdf',
          bytes: bytes,
        );
        await TestFiles.putBytes(anna.session, start.ticket.fileUuid, bytes);
        final item = await endpoints.drive.completeFileUpload(
          anna.endpointSession,
          start.item.uuid,
        );

        expect(start.item.uploadState, FileUploadState.uploading);
        expect(start.ticket.uploadDescription, isNotNull);
        expect(item.kind, DriveItemKind.file);
        expect(item.uploadState, FileUploadState.ready);
        expect(item.mimeType, 'application/pdf');
        expect(item.fileCategory, FileCategory.pdf);
        expect(item.sizeBytes, bytes.length);
        expect(item.countedBytes, bytes.length);
        expect(item.contentRef, start.ticket.fileUuid);
      },
    );

    test('when completing then an uploaded activity is recorded', () async {
      final item = await TestFiles.upload(endpoints, anna, name: 'a.txt');

      final events = await endpoints.drive.activity(
        anna.endpointSession,
        item.uuid,
        null,
        10,
      );

      expect(events.map((e) => e.type), contains(ActivityType.uploaded));
    });

    test(
      'when a .jpg is really HTML then it is stored as text/html (AC-D2.4)',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'photo.jpg',
          bytes: FileFixtures.bytes('html_page.html'),
        );

        expect(item.mimeType, 'text/html');
        expect(item.fileCategory, FileCategory.text);
        expect(item.name, 'photo.jpg');
      },
    );

    test(
      'when completing a text file then its lines and encoding are recorded',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'main.dart',
          bytes: FileFixtures.bytes('main_dart.txt'),
        );

        expect(jsonDecode(item.fileMetaJson!), {
          'encoding': 'utf-8',
          'lines': 3,
        });
      },
    );

    test(
      'when the name has bidi overrides then they are removed',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'invoice\u202Efdp.exe',
        );

        expect(item.name, 'invoicefdp.exe');
      },
    );

    test(
      'when uploading an empty file then no transfer is needed and it is ready',
      () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'empty.txt',
          bytes: const [],
        );
        final item = await endpoints.drive.completeFileUpload(
          anna.endpointSession,
          start.item.uuid,
        );

        expect(start.ticket.uploadDescription, isNull);
        expect(item.uploadState, FileUploadState.ready);
        expect(item.sizeBytes, 0);
      },
    );

    test(
      'when retrying createFileUpload then the same item gets a fresh description',
      () async {
        final req = TestFiles.request(name: 'a.txt', size: 5);

        final first = await endpoints.drive.createFileUpload(
          anna.endpointSession,
          req,
        );
        final again = await endpoints.drive.createFileUpload(
          anna.endpointSession,
          req,
        );

        expect(again.item.uuid, first.item.uuid);
        expect(again.ticket.uploadDescription, isNotNull);
        final count = await DriveItem.db.count(
          anna.session,
          where: (t) => t.ownerId.equals(anna.id),
        );
        expect(count, 1);
      },
    );

    test(
      'when retrying createFileUpload after completion then no description is returned',
      () async {
        final req = TestFiles.request(name: 'a.txt', size: 5);
        await endpoints.drive.createFileUpload(anna.endpointSession, req);
        await TestFiles.putBytes(
          anna.session,
          req.fileUuid,
          utf8.encode('hello'),
        );
        await endpoints.drive.completeFileUpload(
          anna.endpointSession,
          req.itemUuid,
        );

        final again = await endpoints.drive.createFileUpload(
          anna.endpointSession,
          req,
        );

        expect(again.ticket.uploadDescription, isNull);
        expect(again.ticket.status, StoredFileStatus.ready);
        expect(again.item.uploadState, FileUploadState.ready);
      },
    );

    test(
      'when reusing an item uuid with another file uuid or size then it conflicts',
      () async {
        final req = TestFiles.request(name: 'a.txt', size: 5);
        await endpoints.drive.createFileUpload(anna.endpointSession, req);

        await expectLater(
          endpoints.drive.createFileUpload(
            anna.endpointSession,
            req.copyWith(fileUuid: const Uuid().v7obj()),
          ),
          _wonky(WonkyErrorCode.conflict),
        );
        await expectLater(
          endpoints.drive.createFileUpload(
            anna.endpointSession,
            req.copyWith(sizeBytes: 6),
          ),
          _wonky(WonkyErrorCode.conflict),
        );
      },
    );

    test('when the file is larger than 50 MB then it is too large', () async {
      await expectLater(
        endpoints.drive.createFileUpload(
          anna.endpointSession,
          TestFiles.request(name: 'big.raw', size: 50 * 1024 * 1024 + 1),
        ),
        _wonky(WonkyErrorCode.tooLarge),
      );
    });

    test('when the name is empty then it is invalid', () async {
      await expectLater(
        endpoints.drive.createFileUpload(
          anna.endpointSession,
          TestFiles.request(name: '  ', size: 1),
        ),
        _wonky(WonkyErrorCode.invalidArgument),
      );
    });

    test('when the parent folder is gone then it is not found', () async {
      await expectLater(
        endpoints.drive.createFileUpload(
          anna.endpointSession,
          TestFiles.request(
            name: 'a.txt',
            size: 1,
            parentUuid: const Uuid().v7obj(),
          ),
        ),
        _wonky(WonkyErrorCode.notFound),
      );
    });

    test(
      'when a ready file with the same name exists then Keep both numbers the new one',
      () async {
        await TestFiles.upload(endpoints, anna, name: 'Photo.jpg');

        final second = await TestFiles.start(
          endpoints,
          anna,
          name: 'photo.JPG',
          bytes: [1, 2, 3],
        );

        expect(second.item.name, 'photo (1).JPG');
      },
    );

    test('when the conflict mode is fail then a duplicate conflicts', () async {
      await TestFiles.upload(endpoints, anna, name: 'a.txt');

      await expectLater(
        TestFiles.start(
          endpoints,
          anna,
          name: 'A.txt',
          bytes: [1],
          conflict: UploadConflictMode.fail,
        ),
        _wonky(WonkyErrorCode.conflict),
      );
    });

    test(
      'when the stored size differs then completion fails and the item is removed',
      () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: utf8.encode('hello'),
        );
        await TestFiles.putBytes(anna.session, start.ticket.fileUuid, [1, 2]);

        await expectLater(
          endpoints.drive.completeFileUpload(
            anna.endpointSession,
            start.item.uuid,
          ),
          _wonky(WonkyErrorCode.invalidArgument),
        );
        final item = await DriveItem.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(start.item.uuid),
        );
        expect(item, isNull);
      },
    );

    test(
      'when completing before any byte arrived then it fails and the reservation is released',
      () async {
        final storage = _RefusingStorage();
        StorageService.instance = storage;
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: utf8.encode('hello'),
        );

        await expectLater(
          endpoints.drive.completeFileUpload(
            anna.endpointSession,
            start.item.uuid,
          ),
          _wonky(WonkyErrorCode.invalidArgument),
        );
        expect(storage.released, [start.ticket.fileUuid]);
      },
    );

    test('when cancelling then the item and the bytes are gone', () async {
      final start = await TestFiles.start(
        endpoints,
        anna,
        name: 'a.txt',
        bytes: utf8.encode('hello'),
      );
      await TestFiles.putBytes(
        anna.session,
        start.ticket.fileUuid,
        utf8.encode('hello'),
      );

      await endpoints.drive.cancelFileUpload(
        anna.endpointSession,
        start.item.uuid,
      );

      await expectLater(
        endpoints.drive.fileUploadStatus(anna.endpointSession, start.item.uuid),
        _wonky(WonkyErrorCode.notFound),
      );
      final file = await StoredFile.db.findFirstRow(
        anna.session,
        where: (t) => t.fileUuid.equals(start.ticket.fileUuid),
      );
      expect(file?.status, StoredFileStatus.failed);
      expect(file?.itemId, isNull);
      // Cancelling again is a no-op.
      await endpoints.drive.cancelFileUpload(
        anna.endpointSession,
        start.item.uuid,
      );
    });

    test('when trashing an upload in progress then it is cancelled', () async {
      final start = await TestFiles.start(
        endpoints,
        anna,
        name: 'a.txt',
        bytes: [1],
      );

      await endpoints.drive.trash(anna.endpointSession, [start.item.uuid]);

      final item = await DriveItem.db.findFirstRow(
        anna.session,
        where: (t) => t.uuid.equals(start.item.uuid),
      );
      expect(item, isNull);
    });

    test(
      'when asking for the status then it reports the received bytes',
      () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: utf8.encode('hello'),
        );
        final before = await endpoints.drive.fileUploadStatus(
          anna.endpointSession,
          start.item.uuid,
        );
        await TestFiles.putBytes(
          anna.session,
          start.ticket.fileUuid,
          utf8.encode('hello'),
        );
        await endpoints.drive.completeFileUpload(
          anna.endpointSession,
          start.item.uuid,
        );

        final after = await endpoints.drive.fileUploadStatus(
          anna.endpointSession,
          start.item.uuid,
        );

        expect(before.uploadState, FileUploadState.uploading);
        expect(before.receivedBytes, 0);
        expect(after.uploadState, FileUploadState.ready);
        expect(after.receivedBytes, 5);
      },
    );

    test(
      'when the quota refuses the reservation then nothing is created',
      () async {
        StorageService.instance = _RefusingStorage(refuseReserve: true);
        final req = TestFiles.request(name: 'a.txt', size: 5);

        await expectLater(
          endpoints.drive.createFileUpload(anna.endpointSession, req),
          _wonky(WonkyErrorCode.quotaExceeded),
        );
        final item = await DriveItem.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(req.itemUuid),
        );
        expect(item, isNull);
      },
    );

    test(
      'when the actual size no longer fits at completion then the upload fails',
      () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: utf8.encode('hello'),
        );
        await TestFiles.putBytes(
          anna.session,
          start.ticket.fileUuid,
          utf8.encode('hello'),
        );
        StorageService.instance = _RefusingStorage(refuseCommit: true);

        await expectLater(
          endpoints.drive.completeFileUpload(
            anna.endpointSession,
            start.item.uuid,
          ),
          _wonky(WonkyErrorCode.quotaExceeded),
        );
        final item = await DriveItem.db.findFirstRow(
          anna.session,
          where: (t) => t.uuid.equals(start.item.uuid),
        );
        expect(item, isNull);
      },
    );

    test(
      'when more uploads are pending than allowed then it is limited',
      () async {
        WonkyConfig.current = WonkyConfig(maxPendingUploadsPerUser: 2);
        await TestFiles.start(endpoints, anna, name: 'a.txt', bytes: [1]);
        await TestFiles.start(endpoints, anna, name: 'b.txt', bytes: [1]);

        await expectLater(
          TestFiles.start(endpoints, anna, name: 'c.txt', bytes: [1]),
          _wonky(WonkyErrorCode.limitExceeded),
        );
      },
    );

    test('when uploads start in parallel then the last free slot goes to '
        'one of them only', () async {
      WonkyConfig.current = WonkyConfig(maxPendingUploadsPerUser: 1);

      final results = await Future.wait([
        for (final n in ['a.txt', 'b.txt', 'c.txt'])
          TestFiles.start(
            endpoints,
            anna,
            name: n,
            bytes: [1],
          ).then<Object>((s) => s, onError: (Object e) => e),
      ]);

      expect(results.whereType<FileUploadStart>(), hasLength(1));
      expect(
        results.whereType<WonkyException>().map((e) => e.code),
        everyElement(WonkyErrorCode.limitExceeded),
      );
    });

    test(
      'when the hourly upload rate is used up then it is limited, cancelled ones included',
      () async {
        WonkyConfig.current = WonkyConfig(uploadsPerHour: 2);
        final a = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: [1],
        );
        await endpoints.drive.cancelFileUpload(
          anna.endpointSession,
          a.item.uuid,
        );
        await TestFiles.start(endpoints, anna, name: 'b.txt', bytes: [1]);

        await expectLater(
          TestFiles.start(endpoints, anna, name: 'c.txt', bytes: [1]),
          _wonky(WonkyErrorCode.limitExceeded),
        );
      },
    );

    test(
      'when the daily upload bytes are used up then it is limited',
      () async {
        WonkyConfig.current = WonkyConfig(uploadBytesPerDay: 8);
        await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: [1, 2, 3, 4, 5],
        );

        await expectLater(
          TestFiles.start(endpoints, anna, name: 'b.txt', bytes: [1, 2, 3, 4]),
          _wonky(WonkyErrorCode.limitExceeded),
        );
      },
    );

    test(
      'when an upload is older than 24 hours then the daily job deletes it',
      () async {
        final stale = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: [1],
        );
        final done = await TestFiles.upload(endpoints, anna, name: 'b.txt');

        final count = await DriveFileService.expireUploads(
          anna.session,
          now: clock.now().toUtc().add(const Duration(hours: 25)),
        );

        expect(count, greaterThanOrEqualTo(1));
        expect(
          await DriveItem.db.findFirstRow(
            anna.session,
            where: (t) => t.uuid.equals(stale.item.uuid),
          ),
          isNull,
        );
        expect(
          (await TestFiles.row(anna.session, done.uuid)).uploadState,
          FileUploadState.ready,
        );
      },
    );

    test(
      'when listing the storage of an upload start then the usage is returned',
      () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: [1],
        );

        expect(start.storage.quotaBytes, 50 * 1024 * 1024);
      },
    );
  });

  withWonkyServerpod('Given an upload into a shared folder', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView folder;
    setUp(() async {
      TestFiles.skipPreviews();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      folder = await TestDrive.folder(endpoints, anna, name: 'Team');
      await TestDrive.share(endpoints, folder, anna, bo, AccessRole.editor);
    });

    Future<List<UuidValue>> listedBy(TestUser user) async {
      final page = await endpoints.drive.list(
        user.endpointSession,
        folder.uuid,
        DriveListFilter(),
        DriveSort(),
        null,
        100,
      );
      return [for (final i in page.items) i.uuid];
    }

    test(
      'when a collaborator lists the folder then the upload in progress is hidden (AC-D2.8)',
      () async {
        final start = await TestFiles.start(
          endpoints,
          bo,
          name: 'secret.txt',
          bytes: utf8.encode('hello'),
          parentUuid: folder.uuid,
        );

        expect(await listedBy(anna), isNot(contains(start.item.uuid)));
        expect(await listedBy(bo), contains(start.item.uuid));
        await expectLater(
          endpoints.drive.get(anna.endpointSession, start.item.uuid),
          _wonky(WonkyErrorCode.notFound),
        );
        await expectLater(
          endpoints.drive.fileContentUrl(
            anna.endpointSession,
            start.item.uuid,
            download: false,
          ),
          _wonky(WonkyErrorCode.notFound),
        );
      },
    );

    test(
      'when the upload completes then the collaborator sees it, owned by the uploader',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          bo,
          name: 'shared.txt',
          parentUuid: folder.uuid,
        );

        expect(await listedBy(anna), contains(item.uuid));
        expect(item.owner.id, bo.id);
      },
    );

    test('when searching then uploads in progress are never found', () async {
      final start = await TestFiles.start(
        endpoints,
        bo,
        name: 'zebrafile.txt',
        bytes: [1],
        parentUuid: folder.uuid,
      );

      final page = await endpoints.drive.search(
        bo.endpointSession,
        'zebrafile',
        DriveSearchFilters(),
        null,
        50,
      );

      expect(page.items.map((i) => i.uuid), isNot(contains(start.item.uuid)));
    });

    test('when a viewer uploads then it is forbidden', () async {
      final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
      await TestDrive.share(endpoints, folder, anna, vic, AccessRole.viewer);

      await expectLater(
        TestFiles.start(
          endpoints,
          vic,
          name: 'a.txt',
          bytes: [1],
          parentUuid: folder.uuid,
        ),
        _wonky(WonkyErrorCode.forbidden),
      );
    });
  });

  withWonkyServerpod('Given uploaded images', (sessionBuilder, endpoints) {
    late TestUser anna;
    setUp(() async {
      TestFiles.runPreviewsInline();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
    });
    tearDown(TestFiles.skipPreviews);

    test(
      'when a PNG upload completes then a preview and a thumbnail are made',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'wide.png',
          bytes: FileFixtures.bytes('wide.png'),
        );

        final row = await TestFiles.row(anna.session, item.uuid);
        expect(row.previewFileId, isNotNull);
        expect(row.thumbnailFileId, isNotNull);
        expect(jsonDecode(row.fileMetaJson!), {'width': 2400, 'height': 1000});
        final preview = await StoredFile.db.findFirstRow(
          anna.session,
          where: (t) => t.fileUuid.equals(row.previewFileId!),
        );
        expect(preview?.kind, StoredFileKind.preview);
        expect(preview?.itemId, row.id);
      },
    );

    test(
      'when the preview exists then collaborators can fetch it and strangers cannot',
      () async {
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'photo.jpg',
          bytes: FileFixtures.bytes('photo.jpg'),
        );
        await TestDrive.share(endpoints, item, anna, bo, AccessRole.viewer);
        final row = await TestFiles.row(anna.session, item.uuid);

        final url = await endpoints.file.getUrl(
          bo.endpointSession,
          row.previewFileId!,
        );

        expect(url.url, isNotNull);
        await expectLater(
          endpoints.file.getUrl(eve.endpointSession, row.previewFileId!),
          throwsA(isA<WonkyException>()),
        );
      },
    );

    test(
      'when the file is not a renderable image then no preview is made',
      () async {
        final item = await TestFiles.upload(
          endpoints,
          anna,
          name: 'scan.tif',
          bytes: FileFixtures.bytes('scan.tif'),
        );

        final row = await TestFiles.row(anna.session, item.uuid);
        expect(row.fileCategory, FileCategory.image);
        expect(row.previewFileId, isNull);
      },
    );
  });
}
