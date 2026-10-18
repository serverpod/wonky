@Tags(['integration'])
library;

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/storage/storage_counters.dart';
import 'package:wonky_server/src/platform/storage/storage_events.dart';
import 'package:wonky_server/src/platform/storage/storage_maintenance.dart';
import 'package:wonky_server/src/platform/storage/storage_service.dart';

import '../../../support/test_storage.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

const _mb = 1024 * 1024;

StorageService get _storage => StorageService.instance;

void main() {
  withWonkyServerpod('Given the storage service (Drive 03 §4)', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;

    setUp(() async {
      StorageService.resetInstance();
      StorageEvents.debounce = Duration.zero;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
    });

    group('when a user is created', () {
      test('then the counters exist, are reconciled and empty', () async {
        final usage = await TestStorage.usage(anna);

        expect(usage.calculating, isFalse);
        expect(usage.bytesUsed, 0);
        expect(usage.quotaBytes, 50 * _mb);
        expect(usage.availableBytes, 50 * _mb);
        expect(usage.maxFileUploadBytes, 50 * _mb);
      });
    });

    group('reservations (§5)', () {
      test('when reserving within the quota then the bytes are held', () async {
        await TestStorage.setQuota(anna, 10 * _mb);

        await _storage.reserve(
          anna.session,
          userId: anna.id,
          fileUuid: const Uuid().v4obj(),
          bytes: 4 * _mb,
        );

        final usage = await TestStorage.usage(anna);
        expect(usage.reservedBytes, 4 * _mb);
        expect(usage.availableBytes, 6 * _mb);
        expect(usage.maxFileUploadBytes, 6 * _mb);
      });

      test('when reserving the same file twice then it is held once', () async {
        final file = const Uuid().v4obj();

        for (var i = 0; i < 2; i++) {
          await _storage.reserve(
            anna.session,
            userId: anna.id,
            fileUuid: file,
            bytes: 1000,
          );
        }

        expect((await TestStorage.row(anna)).reservedBytes, 1000);
      });

      test('when the bytes do not fit then quotaExceeded names the caller '
          'and nothing is held', () async {
        await TestStorage.setQuota(anna, 10 * _mb);
        await TestStorage.fill(endpoints, anna, 9 * _mb);

        await expectLater(
          _storage.reserve(
            anna.session,
            userId: anna.id,
            fileUuid: const Uuid().v4obj(),
            bytes: 2 * _mb,
          ),
          throwsQuota(QuotaReason.upload, isCaller: true),
        );
        expect((await TestStorage.row(anna)).reservedBytes, 0);
      });

      test('when an editor adds an image to the owner\'s item then the owner '
          'is charged and the error is the owner variant', () async {
        await TestStorage.setQuota(anna, 1 * _mb);

        await expectLater(
          _storage.reserve(
            bo.session,
            userId: anna.id,
            fileUuid: const Uuid().v4obj(),
            bytes: 3 * _mb,
            reason: QuotaReason.image,
            callerUserId: bo.id,
          ),
          throwsQuota(
            QuotaReason.image,
            isCaller: false,
            chargedUserId: anna.id,
          ),
        );
      });

      test('when two 30 MB uploads race for 50 MB then exactly one wins '
          '(AC-D3.2)', () async {
        final results = await Future.wait([
          for (var i = 0; i < 2; i++)
            _storage
                .reserve(
                  sessionBuilder.build(),
                  userId: anna.id,
                  fileUuid: const Uuid().v4obj(),
                  bytes: 30 * _mb,
                )
                .then((_) => 'ok', onError: (Object e) => '$e'),
        ]);

        expect(results.where((r) => r == 'ok'), hasLength(1));
        expect((await TestStorage.row(anna)).reservedBytes, 30 * _mb);
      });

      test(
        'when ten small uploads race for room for five then five win',
        () async {
          await TestStorage.setQuota(anna, 5000);

          final results = await Future.wait([
            for (var i = 0; i < 10; i++)
              _storage
                  .reserve(
                    sessionBuilder.build(),
                    userId: anna.id,
                    fileUuid: const Uuid().v4obj(),
                    bytes: 1000,
                  )
                  .then((_) => true, onError: (Object _) => false),
          ]);

          expect(results.where((ok) => ok), hasLength(5));
          expect((await TestStorage.row(anna)).reservedBytes, 5000);
        },
      );

      test('when releasing then the bytes are available again', () async {
        final file = const Uuid().v4obj();
        await _storage.reserve(
          anna.session,
          userId: anna.id,
          fileUuid: file,
          bytes: 30 * _mb,
        );

        await _storage.releaseReservation(anna.session, file);
        await _storage.releaseReservation(anna.session, file);

        expect((await TestStorage.row(anna)).reservedBytes, 0);
        expect(
          await StorageReservation.db.count(
            anna.session,
            where: (t) => t.fileUuid.equals(file),
          ),
          0,
        );
      });

      test('when 100 uploads are open then the next one is refused', () async {
        for (var i = 0; i < 100; i++) {
          await _storage.reserve(
            anna.session,
            userId: anna.id,
            fileUuid: const Uuid().v4obj(),
            bytes: 1,
          );
        }

        await expectLater(
          _storage.reserve(
            anna.session,
            userId: anna.id,
            fileUuid: const Uuid().v4obj(),
            bytes: 1,
          ),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.code,
              'code',
              WonkyErrorCode.limitExceeded,
            ),
          ),
        );
      });
    });

    group('room checks', () {
      test('when the bytes fit then checkRoom passes, else it refuses with '
          'the numbers', () async {
        await TestStorage.setQuota(anna, 10 * _mb);
        await TestStorage.fill(endpoints, anna, 7 * _mb);

        await _storage.checkRoom(
          anna.session,
          userId: anna.id,
          bytes: 3 * _mb,
          reason: QuotaReason.copy,
        );
        await expectLater(
          _storage.checkRoom(
            anna.session,
            userId: anna.id,
            bytes: 3 * _mb + 1,
            reason: QuotaReason.copy,
          ),
          throwsA(
            isA<WonkyException>().having(
              (e) => e.message,
              'message',
              'Not enough storage: this needs 3.0 MB, 3.0 MB is available.',
            ),
          ),
        );
      });

      test('when over quota then 0 bytes (blank items) still pass', () async {
        await TestStorage.setQuota(anna, 1000);
        await TestStorage.fill(endpoints, anna, 5000);

        await _storage.checkRoom(
          anna.session,
          userId: anna.id,
          bytes: 0,
          reason: QuotaReason.template,
        );
      });
    });

    group('content growth', () {
      test('when content grows past the quota then it is never refused and '
          'the user is over quota', () async {
        await TestStorage.setQuota(anna, 1000);

        final item = await TestStorage.fill(endpoints, anna, 5000);

        final row = await TestStorage.row(anna);
        final usage = await TestStorage.usage(anna);
        expect(item.sizeBytes, 5000);
        expect(row.documentsBytes, 5000);
        expect(row.overQuotaSince, isNotNull);
        expect(usage.overQuota, isTrue);
        expect(usage.availableBytes, 0);
      });

      test(
        'when content shrinks under the quota then overQuotaSince clears',
        () async {
          await TestStorage.setQuota(anna, 1000);
          final item = await TestStorage.fill(endpoints, anna, 5000);

          await _storage.setItemSize(anna.session, item, 10);

          final row = await TestStorage.row(anna);
          expect(row.usedBytes, 10);
          expect(row.overQuotaSince, isNull);
        },
      );

      test(
        'when attachments are added and removed then the owner pays',
        () async {
          final item = await TestStorage.fill(endpoints, anna, 100);

          await _storage.addAttachment(bo.session, item, 400);
          await _storage.addAttachment(bo.session, item, -100);

          final row = await TestStorage.row(anna);
          expect(row.documentsBytes, 400);
          expect((await TestStorage.row(bo)).usedBytes, 0);
        },
      );
    });

    group('trash, restore and delete (§7.4)', () {
      test('when trashing then the bytes move to trash and usage is unchanged; '
          'restoring moves them back; deleting frees them (AC-D3.4)', () async {
        final item = await TestStorage.fill(endpoints, anna, 8 * _mb);

        await endpoints.drive.trash(anna.endpointSession, [item.uuid]);
        final trashed = await TestStorage.usage(anna);
        await endpoints.drive.restore(anna.endpointSession, [item.uuid]);
        final restored = await TestStorage.usage(anna);
        await endpoints.drive.trash(anna.endpointSession, [item.uuid]);
        await endpoints.drive.emptyTrash(anna.endpointSession);
        final emptied = await TestStorage.usage(anna);

        expect(trashed.trashBytes, 8 * _mb);
        expect(trashed.documentsBytes, 0);
        expect(trashed.bytesUsed, 8 * _mb);
        expect(restored.trashBytes, 0);
        expect(restored.documentsBytes, 8 * _mb);
        expect(emptied.bytesUsed, 0);
      });

      test(
        'when restoring over quota then the restore is never refused (Q16)',
        () async {
          final item = await TestStorage.fill(endpoints, anna, 5000);
          await endpoints.drive.trash(anna.endpointSession, [item.uuid]);
          await TestStorage.setQuota(anna, 1000);

          await endpoints.drive.restore(anna.endpointSession, [item.uuid]);

          expect((await TestStorage.usage(anna)).documentsBytes, 5000);
        },
      );

      test('when trashing a folder with a collaborator\'s item then each '
          'owner\'s trash grows', () async {
        final folder = await endpoints.drive.createFolder(
          anna.endpointSession,
          null,
          'Shared',
        );
        await endpoints.sharing.share(
          anna.endpointSession,
          folder.uuid,
          [bo.email],
          AccessRole.editor,
          false,
          null,
          null,
        );
        final boDoc = await endpoints.drive.createDocument(
          bo.endpointSession,
          folder.uuid,
          'Bo in Anna',
          null,
          'Some text',
        );

        await endpoints.drive.trash(anna.endpointSession, [folder.uuid]);

        final boRow = await TestStorage.row(bo);
        expect(boRow.trashBytes, greaterThan(0));
        expect(boRow.documentsBytes, 0);
        expect(boRow.trashBytes, (await _item(bo, boDoc.uuid)).sizeBytes);
      });
    });

    group('fail open while calculating (§9)', () {
      test('when the user is not reconciled then usage is calculating and '
          'nothing is refused', () async {
        await TestStorage.setQuota(anna, 1000);
        await TestStorage.fill(endpoints, anna, 5000);
        await UserStorage.db.updateWhere(
          anna.session,
          columnValues: (t) => [t.reconciledAt(null)],
          where: (t) => t.userId.equals(anna.id),
        );

        await _storage.reserve(
          anna.session,
          userId: anna.id,
          fileUuid: const Uuid().v4obj(),
          bytes: 10 * _mb,
        );
        await _storage.checkRoom(
          anna.session,
          userId: anna.id,
          bytes: 10 * _mb,
          reason: QuotaReason.copy,
        );

        final usage = await TestStorage.usage(anna);
        expect(usage.calculating, isTrue);
        expect(usage.bytesUsed, 5000);
      });
    });

    group('reconcile (§4.3)', () {
      test('when a counter drifted then the reconcile corrects and reports '
          'it', () async {
        await TestStorage.fill(endpoints, anna, 1234);
        await UserStorage.db.updateWhere(
          anna.session,
          columnValues: (t) => [t.documentsBytes(99), t.usedBytes(99)],
          where: (t) => t.userId.equals(anna.id),
        );

        final drifts = await StorageMaintenance.reconcileUser(
          anna.session,
          anna.id,
        );

        expect(
          drifts.map((d) => (d.field, d.before, d.after)),
          containsAll([('documentsBytes', 99, 1234), ('usedBytes', 99, 1234)]),
        );
        expect((await TestStorage.row(anna)).documentsBytes, 1234);
      });

      test('when a spreadsheet size is from an older estimator then the '
          'nightly reconcile re-estimates it and corrects the counter '
          '(Drive 03 §11)', () async {
        final view = await endpoints.drive.createSpreadsheet(
          anna.endpointSession,
          null,
          'S',
          null,
        );
        final item = await _item(anna, view.uuid);
        final current = item.sizeBytes;
        // The pre-D-18 estimate counted the 1,000 default rows (~80 KB).
        await DriveItem.db.updateRow(
          anna.session,
          item.copyWith(sizeBytes: 80000),
          columns: (t) => [t.sizeBytes],
        );
        await StorageMaintenance.reconcileUser(anna.session, anna.id);
        final stale = await TestStorage.row(anna);

        await StorageMaintenance.reconcileAll(anna.session);

        expect(stale.spreadsheetsBytes, 80000);
        expect((await _item(anna, view.uuid)).sizeBytes, current);
        expect((await TestStorage.row(anna)).spreadsheetsBytes, current);
        expect(current, lessThan(4 * 1024));
      });

      test(
        'when expired reservations exist then the reconcile deletes them',
        () async {
          final file = const Uuid().v4obj();
          await _storage.reserve(
            anna.session,
            userId: anna.id,
            fileUuid: file,
            bytes: 500,
          );
          await StorageReservation.db.updateWhere(
            anna.session,
            columnValues: (t) => [
              t.expiresAt(DateTime.utc(2020)),
            ],
            where: (t) => t.fileUuid.equals(file),
          );

          await StorageMaintenance.reconcileUser(anna.session, anna.id);

          expect((await TestStorage.row(anna)).reservedBytes, 0);
          expect(
            await StorageReservation.db.count(
              anna.session,
              where: (t) => t.userId.equals(anna.id),
            ),
            0,
          );
        },
      );

      test('when 1,000 random service calls ran then the reconcile finds no '
          'drift (AC-D3.7)', () async {
        final users = [anna, bo];
        for (final u in users) {
          await TestStorage.setQuota(u, 1 << 40);
        }
        final items = <DriveItem>[
          for (final u in users)
            for (var i = 0; i < 4; i++)
              await TestStorage.fill(endpoints, u, 100 * (i + 1)),
        ];
        final reservations = <(int, UuidValue)>[];
        final random = Random(42);
        final session = anna.session;
        Future<DriveItem> fresh(DriveItem i) async =>
            (await DriveItem.db.findById(session, i.id!))!;

        for (var step = 0; step < 1000; step++) {
          final index = random.nextInt(items.length);
          final item = await fresh(items[index]);
          switch (random.nextInt(7)) {
            case 0:
            case 1:
              await _storage.setItemSize(session, item, random.nextInt(5000));
            case 2:
              await _storage.addAttachment(
                session,
                item,
                random.nextInt(800) - 300,
              );
            case 3:
              await session.db.transaction((tx) async {
                await DriveItem.db.updateRow(
                  session,
                  item.copyWith(
                    trashedAt: item.trashedAt == null ? clock.now() : null,
                  ),
                  columns: (t) => [t.trashedAt],
                  transaction: tx,
                );
                if (item.trashedAt == null) {
                  await _storage.onTrash(session, [item], transaction: tx);
                } else {
                  await _storage.onRestore(session, [item], transaction: tx);
                }
              });
            case 4:
              final to = users[random.nextInt(users.length)].id;
              await session.db.transaction((tx) async {
                await DriveItem.db.updateRow(
                  session,
                  item.copyWith(ownerId: to),
                  columns: (t) => [t.ownerId],
                  transaction: tx,
                );
                await _storage.onOwnerChange(
                  session,
                  item,
                  fromUserId: item.ownerId,
                  toUserId: to,
                  transaction: tx,
                );
              });
            case 5:
              final user = users[random.nextInt(users.length)].id;
              final file = const Uuid().v4obj();
              await _storage.reserve(
                session,
                userId: user,
                fileUuid: file,
                bytes: random.nextInt(1000),
              );
              reservations.add((user, file));
            case 6:
              if (reservations.isEmpty) break;
              final (_, file) = reservations.removeAt(
                random.nextInt(reservations.length),
              );
              await _storage.releaseReservation(session, file);
          }
        }

        for (final u in users) {
          final drifts = await StorageMaintenance.reconcileUser(
            u.session,
            u.id,
          );
          expect(drifts, isEmpty, reason: '${u.name}: $drifts');
        }
      });
    });

    group('backfill (§9)', () {
      Future<void> makePending(TestUser user) => UserStorage.db.deleteWhere(
        user.session,
        where: (t) => t.userId.equals(user.id),
      );

      test('when an existing user has stale sizes then the backfill '
          'recomputes them, reconciles and is idempotent', () async {
        final doc = await endpoints.drive.createDocument(
          anna.endpointSession,
          null,
          'Old',
          null,
          '# Hello\n\nSome **content**.',
        );
        final item = await _item(anna, doc.uuid);
        final expectedSize = item.sizeBytes;
        await StoredFile.db.insertRow(
          anna.session,
          StoredFile(
            fileUuid: const Uuid().v4obj(),
            ownerId: bo.id,
            itemId: item.id,
            kind: StoredFileKind.image,
            storageId: 'private',
            path: 'files/image/x/a.png',
            fileName: 'a.png',
            mimeType: 'image/png',
            sizeBytes: 700,
            status: StoredFileStatus.ready,
            createdAt: clock.now().toUtc(),
          ),
        );
        // v1 state: plain-text sizes, no attachments, no counters.
        await DriveItem.db.updateRow(
          anna.session,
          item.copyWith(sizeBytes: 3, attachmentBytes: 0),
          columns: (t) => [t.sizeBytes, t.attachmentBytes],
        );
        await makePending(anna);
        final before = await TestStorage.usage(anna);

        await StorageMaintenance.backfillUser(anna.session, anna.id);
        final first = await TestStorage.row(anna);
        await StorageMaintenance.backfillUser(anna.session, anna.id);
        final second = await TestStorage.row(anna);

        expect(before.calculating, isTrue);
        expect(first.reconciledAt, isNotNull);
        expect(first.documentsBytes, expectedSize + 700);
        expect(
          (await _item(anna, doc.uuid)).attachmentBytes,
          700,
        );
        expect(
          StorageTotals.ofRow(second).toMap(),
          StorageTotals.ofRow(first).toMap(),
        );
        expect((await TestStorage.usage(anna)).calculating, isFalse);
      });

      test('when the backfill is interrupted then the next run continues with '
          'the remaining users (resumable)', () async {
        await makePending(anna);
        await makePending(bo);
        await StorageMaintenance.backfillUser(anna.session, anna.id);

        final pending = await StorageMaintenance.pendingUsers(
          anna.session,
          limit: 100000,
        );
        await StorageMaintenance.backfillPending(anna.session);

        expect(pending, contains(bo.id));
        expect(pending, isNot(contains(anna.id)));
        expect(
          await StorageMaintenance.pendingUsers(anna.session, limit: 100000),
          isNot(contains(bo.id)),
        );
      });

      test('when a user is over the quota after the backfill then they get '
          'one storage notification', () async {
        // 60 MB of images stored in a document (the backfill sums them).
        final doc = await TestStorage.fill(endpoints, anna, 0);
        await StoredFile.db.insertRow(
          anna.session,
          StoredFile(
            fileUuid: const Uuid().v4obj(),
            ownerId: anna.id,
            itemId: doc.id,
            kind: StoredFileKind.image,
            storageId: 'private',
            path: 'files/image/y/big.png',
            fileName: 'big.png',
            mimeType: 'image/png',
            sizeBytes: 60 * _mb,
            status: StoredFileStatus.ready,
            createdAt: clock.now().toUtc(),
          ),
        );
        await makePending(anna);

        await StorageMaintenance.backfillUser(anna.session, anna.id);
        await UserStorage.db.updateWhere(
          anna.session,
          columnValues: (t) => [t.reconciledAt(null)],
          where: (t) => t.userId.equals(anna.id),
        );
        await StorageMaintenance.backfillUser(anna.session, anna.id);

        final notes = await UserNotification.db.find(
          anna.session,
          where: (t) =>
              t.userId.equals(anna.id) &
              t.kind.equals(NotificationKind.storage),
        );
        expect(notes, hasLength(1));
        expect(notes.single.payload, contains("You're using 60.0 MB"));
        expect(notes.single.payload, contains('50 MB of storage per person'));
      });
    });

    group('ensureRow', () {
      test('when called for an existing row then nothing changes', () async {
        final created = await StorageCounters.ensureRow(anna.session, anna.id);

        expect(created, isFalse);
      });
    });
  });
}

Future<DriveItem> _item(TestUser user, UuidValue uuid) async =>
    (await DriveItem.db.findFirstRow(
      user.session,
      where: (t) => t.uuid.equals(uuid),
    ))!;
