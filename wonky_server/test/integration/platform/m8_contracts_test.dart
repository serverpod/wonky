@Tags(['integration'])
library;

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/files.dart';
import 'package:wonky_server/src/platform/common/errors.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/storage/storage_service.dart';

import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Matcher _wonky(WonkyErrorCode code) =>
    throwsA(isA<WonkyException>().having((e) => e.code, 'code', code));

/// The M8 contracts of Drive 05 D-1: models, the migration's columns,
/// endpoint signatures and the pass-through StorageService.
void main() {
  withWonkyServerpod('Given the M8 contracts', (sessionBuilder, endpoints) {
    late TestUser anna;
    setUp(
      () async => anna = await TestUsers.create(sessionBuilder, name: 'Anna'),
    );

    test('when reading storage then the v2 usage fields are filled', () async {
      await TestDrive.document(endpoints, anna, markdown: 'abc');

      final usage = await endpoints.drive.storageUsage(anna.endpointSession);

      expect(usage.documents, 1);
      expect(usage.quotaBytes, 50 * 1024 * 1024);
      expect(usage.availableBytes, usage.quotaBytes - usage.bytesUsed);
      expect(usage.overQuota, isFalse);
      expect(usage.reservedBytes, 0);
      expect(usage.calculating, isFalse);
      expect(usage.maxFileUploadBytes, lessThanOrEqualTo(usage.quotaBytes));
    });

    test(
      'when pre-checking room then bytes that fit pass and the rest is '
      'refused with quotaExceeded (D-9 service)',
      () async {
        final doc = await TestDrive.document(endpoints, anna);

        await endpoints.drive.checkRoom(anna.endpointSession, 1, null);
        await endpoints.drive.checkRoom(anna.endpointSession, 1, doc.uuid);
        await expectLater(
          endpoints.drive.checkRoom(anna.endpointSession, 1 << 40, null),
          _wonky(WonkyErrorCode.quotaExceeded),
        );
      },
    );

    test('when pre-checking room on an inaccessible item then it is not '
        'found', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final doc = await TestDrive.document(endpoints, bo);

      await expectLater(
        endpoints.drive.checkRoom(anna.endpointSession, 1, doc.uuid),
        _wonky(WonkyErrorCode.notFound),
      );
    });

    test('when patching the v2 preference keys then they are merged', () async {
      await endpoints.user.updatePreferences(
        anna.endpointSession,
        UserPreferencesPatch(
          driveDefaults: jsonEncode({'layout': 'grid'}),
          slidesDefaults: jsonEncode({'defaultSize': '16:9'}),
          slidesPresenter: jsonEncode({'timerMode': 'elapsed'}),
        ),
      );
      final prefs = await endpoints.user.updatePreferences(
        anna.endpointSession,
        UserPreferencesPatch(driveDefaults: jsonEncode({'sort': 'name'})),
      );

      expect(jsonDecode(prefs.driveDefaults), {
        'layout': 'grid',
        'sort': 'name',
      });
      expect(jsonDecode(prefs.slidesDefaults), {'defaultSize': '16:9'});
      expect(jsonDecode(prefs.slidesPresenter), {'timerMode': 'elapsed'});
    });

    test('when the drive item has the v2 columns then they persist', () async {
      final session = sessionBuilder.build();
      final doc = await TestDrive.document(endpoints, anna);
      final row = (await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(doc.uuid),
      ))!;
      expect(row.kindMask, 0);
      expect(row.attachmentBytes, 0);

      await DriveItem.db.updateRow(
        session,
        row.copyWith(
          attachmentBytes: 7,
          mimeType: 'image/png',
          fileCategory: FileCategory.image,
          uploadState: FileUploadState.ready,
          fileMetaJson: '{"width":1}',
        ),
      );
      final again = (await DriveItem.db.findById(session, row.id!))!;
      expect(again.fileCategory, FileCategory.image);
      expect(again.uploadState, FileUploadState.ready);
      expect(again.attachmentBytes, 7);
    });

    test(
      'when storing counters and a reservation then the tables exist',
      () async {
        final session = sessionBuilder.build();
        final now = clock.now().toUtc();
        // New users get their (reconciled) counters row at sign-up (D-9).
        final storage = (await UserStorage.db.findFirstRow(
          session,
          where: (t) => t.userId.equals(anna.id),
        ))!;
        final reservation = await StorageReservation.db.insertRow(
          session,
          StorageReservation(
            userId: anna.id,
            fileUuid: UuidValue.fromString(
              '0190a0e0-0000-7000-8000-000000000009',
            ),
            bytes: 10,
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
          ),
        );
        expect(storage.usedBytes, 0);
        expect(storage.reconciledAt, isNotNull);
        expect(reservation.id, isNotNull);
      },
    );

    test(
      'when reading protocol info then the v2 limits are announced',
      () async {
        final info = await endpoints.meta.getInfo(anna.endpointSession);
        expect(info.limits.maxFileUploadBytes, 50 * 1024 * 1024);
        expect(info.limits.quotaBytesPerUser, 50 * 1024 * 1024);
        // M13 (RevLog) raised it to 3.0.0 (specs/17 RD-17).
        expect(info.minClientVersion, '3.0.0');
      },
    );
  });

  group('Given the quota error', () {
    test(
      'when building it then the message and details follow Drive 03 §7.1',
      () {
        final e = Errors.quotaExceeded(
          QuotaExceededDetails(
            neededBytes: 12998246,
            availableBytes: 3250585,
            quotaBytes: 52428800,
            chargedUserId: 42,
            chargedUserName: 'Anna Berg',
            isCaller: false,
            reason: QuotaReason.image,
          ),
        );

        expect(e.code, WonkyErrorCode.quotaExceeded);
        expect(
          e.message,
          'Not enough storage: this needs 12.4 MB, 3.1 MB is available.',
        );
        final details = QuotaExceededDetails.fromJson(
          jsonDecode(e.detailsJson!) as Map<String, dynamic>,
        );
        expect(details.chargedUserName, 'Anna Berg');
        expect(details.reason, 'image');
        expect(QuotaReason.values, hasLength(8));
      },
    );

    test('when comparing categories then core and protocol names match', () {
      expect(
        FileTypeCategory.values.map((c) => c.name),
        FileCategory.values.map((c) => c.name),
      );
    });
  });
}
