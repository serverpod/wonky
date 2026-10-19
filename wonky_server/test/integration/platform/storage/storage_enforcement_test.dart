@Tags(['integration'])
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/templates/builtin_templates.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/platform/storage/content_sizes.dart';
import 'package:wonky_server/src/platform/storage/storage_events.dart';
import 'package:wonky_server/src/platform/storage/storage_hooks.dart';
import 'package:wonky_server/src/platform/storage/storage_service.dart';
import 'package:wonky_server/src/sheets/revlog/sheets_server_writes.dart';
import 'package:wonky_sheets_core/model.dart' show RowChange;

import '../../../support/mcp_harness.dart';
import '../../../support/streams.dart';
import '../../../support/test_drive.dart';
import '../../../support/test_files.dart';
import '../../../support/test_storage.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

/// A 1×1 PNG.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

Future<UuidValue> _importSource(TestUser user, String name, String text) async {
  final file = await FileService.storeServerFile(
    user.session,
    ownerId: user.id,
    kind: StoredFileKind.importSource,
    fileName: name,
    mimeType: 'text/plain',
    bytes: Uint8List.fromList(utf8.encode(text)),
  );
  return file.fileUuid;
}

Future<int> _ownedCount(TestUser user) => DriveItem.db.count(
  user.session,
  where: (t) => t.ownerId.equals(user.id),
);

Future<DriveItem> _row(TestUser user, UuidValue uuid) =>
    TestFiles.row(user.session, uuid);

/// The `rev_file` id of the spreadsheet item `@u`.
const _fileIdOf =
    '(SELECT f.id FROM rev_file f JOIN drive_item i '
    'ON i."contentRef" = f."fileUuid" WHERE i.uuid = @u::uuid)';

/// Rows of [table] stored for the spreadsheet [uuid].
Future<int> _spaceRows(TestUser user, UuidValue uuid, String table) async {
  final r = await user.session.db.unsafeQuery(
    'SELECT count(*) FROM "$table" WHERE "fileId" = $_fileIdOf',
    parameters: QueryParameters.named({'u': uuid.uuid}),
  );
  return r.first[0] as int;
}

/// Sets [columns] on the first [n] rows (by sort key) of [table] of the
/// spreadsheet [uuid], committed through RevLog.
Future<void> _updateFirst(
  TestUser user,
  UuidValue uuid,
  String table,
  Map<String, Object?> columns,
  int n,
) async {
  final item = await _row(user, uuid);
  final ids = await user.session.db.unsafeQuery(
    'SELECT id FROM "$table" WHERE "fileId" = $_fileIdOf '
    'ORDER BY "sortKey" LIMIT $n',
    parameters: QueryParameters.named({'u': uuid.uuid}),
  );
  await SheetsServerWrites.apply(
    user.session,
    actor: user.actor,
    fileUuid: item.contentRef!,
    changes: [
      for (final r in ids)
        RowChange.update(table, '${r[0]}', {
          for (final k in columns.keys) k: null,
        }, columns),
    ],
    label: 'Format',
  );
}

/// Drive 03 §7.2, row by row.
void main() {
  withWonkyServerpod('Given the quota enforcement points (Drive 03 §7.2)', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    final scheduled = <int>[];

    setUp(() async {
      StorageService.resetInstance();
      StorageEvents.debounce = Duration.zero;
      ContentSizes.reset();
      ContentSizes.scheduleRefresh = (session, itemId, delay) async =>
          scheduled.add(itemId);
      scheduled.clear();
      TestFiles.skipPreviews();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
    });

    group('drive.createFileUpload (uploads)', () {
      test('when the declared size does not fit then it is refused before '
          'any byte is sent (AC-D3.1)', () async {
        await TestStorage.setQuota(anna, 1000);

        await expectLater(
          TestFiles.start(
            endpoints,
            anna,
            name: 'big.bin',
            bytes: List.filled(2000, 1),
          ),
          throwsQuota(QuotaReason.upload, isCaller: true),
        );
        expect(await _ownedCount(anna), 0);
      });

      test('when an upload completes then its reservation becomes file '
          'bytes', () async {
        final start = await TestFiles.start(
          endpoints,
          anna,
          name: 'a.txt',
          bytes: List.filled(500, 65),
        );
        final during = await TestStorage.usage(anna);
        await TestFiles.putBytes(
          anna.session,
          start.ticket.fileUuid,
          List.filled(500, 65),
        );
        await endpoints.drive.completeFileUpload(
          anna.endpointSession,
          start.item.uuid,
        );

        final after = await TestStorage.usage(anna);
        expect(during.reservedBytes, 500);
        expect(after.reservedBytes, 0);
        expect(after.filesBytes, 500);
        expect(after.files, 1);
      });

      test(
        'when an upload is cancelled then the reservation is released',
        () async {
          final start = await TestFiles.start(
            endpoints,
            anna,
            name: 'a.txt',
            bytes: List.filled(500, 65),
          );

          await endpoints.drive.cancelFileUpload(
            anna.endpointSession,
            start.item.uuid,
          );

          expect((await TestStorage.usage(anna)).reservedBytes, 0);
        },
      );
    });

    group('file.createUpload(kind: image)', () {
      test('when an editor adds an image to a full owner\'s document then the '
          'owner variant is refused (AC-D3.3)', () async {
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        await TestStorage.setQuota(anna, 10);

        await expectLater(
          endpoints.file.createUpload(
            bo.endpointSession,
            const Uuid().v4obj(),
            doc.uuid,
            'dot.png',
            'image/png',
            3000,
          ),
          throwsQuota(
            QuotaReason.image,
            isCaller: false,
            chargedUserId: anna.id,
          ),
        );
        expect((await TestStorage.row(bo)).usedBytes, 0);
      });

      test('when an editor\'s image upload completes then the owner pays it '
          'as attachment bytes', () async {
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        final before = (await TestStorage.usage(anna)).documentsBytes;
        final fileUuid = const Uuid().v4obj();

        await endpoints.file.createUpload(
          bo.endpointSession,
          fileUuid,
          doc.uuid,
          'dot.png',
          'image/png',
          _png.length,
        );
        final reserved = (await TestStorage.row(anna)).reservedBytes;
        await TestFiles.putBytes(bo.session, fileUuid, _png);
        await endpoints.file.completeUpload(bo.endpointSession, fileUuid);

        expect(reserved, _png.length);
        expect((await _row(anna, doc.uuid)).attachmentBytes, _png.length);
        expect(
          (await TestStorage.usage(anna)).documentsBytes,
          before + _png.length,
        );
        expect((await TestStorage.row(anna)).reservedBytes, 0);
        expect((await TestStorage.row(bo)).usedBytes, 0);
      });

      test(
        'when uploading an import source then only the size cap applies',
        () async {
          await TestStorage.setQuota(anna, 10);

          final ticket = await endpoints.file.createUpload(
            anna.endpointSession,
            const Uuid().v4obj(),
            null,
            'data.csv',
            'text/csv',
            5000,
            kind: StoredFileKind.importSource,
          );

          expect(ticket.status, StoredFileStatus.pending);
        },
      );
    });

    group('drive.import and drive.convertFile (imports)', () {
      test(
        'when a document import does not fit then nothing is created',
        () async {
          await TestStorage.setQuota(anna, 100);
          final upload = await _importSource(
            anna,
            'notes.md',
            '# Notes\n\n${'Long text. ' * 50}',
          );

          await expectLater(
            endpoints.drive.import(
              anna.endpointSession,
              upload,
              DriveItemKind.document,
              DriveImportOptions(),
            ),
            throwsQuota(QuotaReason.import, isCaller: true),
          );
          expect(await _ownedCount(anna), 0);
        },
      );

      test('when a document import fits then its content counts', () async {
        final upload = await _importSource(anna, 'notes.md', '# Notes\n\nHi.');

        final report = await endpoints.drive.import(
          anna.endpointSession,
          upload,
          DriveItemKind.document,
          DriveImportOptions(),
        );

        final item = await _row(anna, report.item.uuid);
        expect(item.sizeBytes, greaterThan(0));
        expect(
          (await TestStorage.usage(anna)).documentsBytes,
          item.sizeBytes,
        );
      });

      test(
        'when a spreadsheet import does not fit then nothing is created',
        () async {
          await TestStorage.setQuota(anna, 10);
          final upload = await _importSource(
            anna,
            'data.csv',
            'a,b\n1,2\n' * 5,
          );

          await expectLater(
            endpoints.drive.import(
              anna.endpointSession,
              upload,
              DriveItemKind.spreadsheet,
              DriveImportOptions(),
            ),
            throwsQuota(QuotaReason.import),
          );
          expect(await _ownedCount(anna), 0);
        },
      );

      test(
        'when a spreadsheet import fits then its estimated content counts',
        () async {
          final upload = await _importSource(anna, 'data.csv', 'a,b\n1,2\n');

          final report = await endpoints.drive.import(
            anna.endpointSession,
            upload,
            DriveItemKind.spreadsheet,
            DriveImportOptions(),
          );

          final item = await _row(anna, report.item.uuid);
          expect(item.sizeBytes, greaterThan(0));
          expect(
            (await TestStorage.usage(anna)).spreadsheetsBytes,
            item.sizeBytes,
          );
        },
      );

      test(
        'when converting a file that does not fit then it is refused',
        () async {
          final file = await TestFiles.upload(
            endpoints,
            anna,
            name: 'data.csv',
            bytes: utf8.encode('a,b\n1,2\n'),
          );
          await TestStorage.setQuota(
            anna,
            (await TestStorage.row(anna)).usedBytes,
          );

          await expectLater(
            endpoints.drive.convertFile(
              anna.endpointSession,
              file.uuid,
              DriveItemKind.spreadsheet,
              DriveImportOptions(),
            ),
            throwsQuota(QuotaReason.convert),
          );
        },
      );

      test('when importing into a full owner\'s spreadsheet then the job is '
          'refused before it is queued', () async {
        final mcp = await McpHarness.forUser(anna);
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        final uuid = UuidValue.fromString(
          (ss['item'] as Map)['uuid'] as String,
        );
        await TestStorage.setQuota(anna, 10);
        final upload = await _importSource(anna, 'more.csv', 'x,y\n1,2\n');

        await expectLater(
          endpoints.sheetsImport.importInto(
            anna.endpointSession,
            uuid,
            upload,
            jsonEncode({'location': 'newSheet'}),
            null,
          ),
          throwsQuota(QuotaReason.import),
        );
      });

      test('when pre-checking a client-side import for someone else\'s item '
          'then the owner is charged', () async {
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        await TestStorage.setQuota(anna, 10);

        await expectLater(
          endpoints.drive.checkRoom(bo.endpointSession, 100, doc.uuid),
          throwsQuota(QuotaReason.image, isCaller: false),
        );
        await endpoints.drive.checkRoom(bo.endpointSession, 100, null);
      });
    });

    group('drive.copy and version copies', () {
      test('when copying a document that does not fit then it is refused; '
          'when it fits the copier pays the content size', () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          markdown: '# Report\n\n${'Words and more words. ' * 20}',
        );
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
        final source = await _row(anna, doc.uuid);
        await TestStorage.setQuota(bo, source.sizeBytes - 1);

        await expectLater(
          endpoints.drive.copy(
            bo.endpointSession,
            doc.uuid,
            'Copy',
            null,
            false,
            false,
          ),
          throwsQuota(QuotaReason.copy, isCaller: true),
        );
        await TestStorage.setQuota(bo, 1 << 30);
        final copy = await endpoints.drive.copy(
          bo.endpointSession,
          doc.uuid,
          'Copy',
          null,
          false,
          false,
        );

        expect((await _row(bo, copy.uuid)).sizeBytes, source.sizeBytes);
        expect((await TestStorage.usage(bo)).documentsBytes, source.sizeBytes);
      });

      test(
        'when copying a spreadsheet then the copy is measured and counts',
        () async {
          final mcp = await McpHarness.forUser(anna);
          final ss = await mcp.call('drive.create_spreadsheet', {
            'name': 'S',
            'sheets': [
              {
                'name': 'Data',
                'values': [
                  ['a', 'b'],
                  [1, 2],
                ],
              },
            ],
          });
          final uuid = UuidValue.fromString(
            (ss['item'] as Map)['uuid'] as String,
          );
          final before = (await TestStorage.usage(anna)).spreadsheetsBytes;

          final copy = await endpoints.drive.copy(
            anna.endpointSession,
            uuid,
            'Copy',
            null,
            false,
            false,
          );

          final size = (await _row(anna, copy.uuid)).sizeBytes;
          expect(size, greaterThan(0));
          expect(
            (await TestStorage.usage(anna)).spreadsheetsBytes,
            before + size,
          );
        },
      );

      test('when an MCP copy does not fit then the tool error is '
          'quota_exceeded with the details', () async {
        final doc = await TestDrive.document(endpoints, anna, markdown: 'Text');
        await TestStorage.setQuota(
          anna,
          (await TestStorage.row(anna)).usedBytes,
        );
        final mcp = await McpHarness.forUser(anna);

        final error = await mcp.error('drive.copy', {'uuid': doc.uuid.uuid});

        expect(error['code'], 'quota_exceeded');
        expect((error['details'] as Map)['reason'], QuotaReason.copy);
      });

      test(
        'when copying a version that does not fit then it is refused',
        () async {
          final doc = await TestDrive.document(
            endpoints,
            anna,
            markdown: 'Text',
          );
          final v1 = await endpoints.version.nameCurrent(
            anna.endpointSession,
            doc.uuid,
            'v1',
          );
          await TestStorage.setQuota(
            anna,
            (await TestStorage.row(anna)).usedBytes,
          );

          await expectLater(
            endpoints.writeHistory.copyVersion(
              anna.endpointSession,
              doc.contentRef!,
              v1.id,
              'Copy of v1',
              null,
            ),
            throwsQuota(QuotaReason.restoreVersionCopy),
          );
        },
      );
    });

    group('creations', () {
      final docTemplate = BuiltinTemplates.all.firstWhere(
        (t) => t.inGallery && t.kind == DriveItemKind.document,
      );
      final sheetTemplate = BuiltinTemplates.all.firstWhere(
        (t) => t.inGallery && t.sheets.isNotEmpty,
      );

      test('when the user is full then template documents and spreadsheets '
          'and initial content are refused, blank items are not', () async {
        await TestStorage.setQuota(anna, 10);

        await expectLater(
          endpoints.drive.createDocument(
            anna.endpointSession,
            null,
            'T',
            docTemplate.uuid,
            null,
          ),
          throwsQuota(QuotaReason.template),
        );
        await expectLater(
          endpoints.drive.createSpreadsheet(
            anna.endpointSession,
            null,
            'T',
            sheetTemplate.uuid,
          ),
          throwsQuota(QuotaReason.template),
        );
        await expectLater(
          endpoints.drive.createDocument(
            anna.endpointSession,
            null,
            'T',
            null,
            '# Content',
          ),
          throwsQuota(QuotaReason.import),
        );
        await endpoints.drive.createDocument(
          anna.endpointSession,
          null,
          'Blank',
          null,
          null,
        );
        expect(await _ownedCount(anna), 1);
      });

      test(
        'when listing templates then each has the size it would add',
        () async {
          final templates = await endpoints.drive.listTemplates(
            anna.endpointSession,
            null,
          );

          expect(templates.where((t) => t.builtin), isNotEmpty);
          expect(templates.every((t) => t.sizeBytes > 0), isTrue);
        },
      );
    });

    group('sharing.transferOwnership (§7.3)', () {
      test('when the new owner lacks room then the request is refused; after '
          'they free space acceptance succeeds and both meters update '
          '(AC-D3.6)', () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          markdown: 'Some text to transfer.',
        );
        // Ownership goes only to people with access (or related users).
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        final size = (await _row(anna, doc.uuid)).sizeBytes;
        final filler = await TestStorage.fill(endpoints, bo, 1000);
        await TestStorage.setQuota(bo, 1000 + size - 1);

        await expectLater(
          endpoints.sharing.transferOwnership(
            anna.endpointSession,
            doc.uuid,
            bo.id,
          ),
          throwsQuota(QuotaReason.transfer, isCaller: false),
        );
        await StorageService.instance.setItemSize(bo.session, filler, 0);
        final info = await endpoints.sharing.transferOwnership(
          anna.endpointSession,
          doc.uuid,
          bo.id,
        );
        await endpoints.sharing.respondToOwnershipTransfer(
          bo.endpointSession,
          info.pendingTransfer!.id,
          true,
        );

        expect((await TestStorage.usage(anna)).documentsBytes, 0);
        expect((await TestStorage.usage(bo)).documentsBytes, size);
      });

      test('when the new owner filled up before accepting then acceptance is '
          'refused and the offer stays open', () async {
        final doc = await TestDrive.document(endpoints, anna, markdown: 'Text');
        // Ownership goes only to people with access (or related users).
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.editor);
        final info = await endpoints.sharing.transferOwnership(
          anna.endpointSession,
          doc.uuid,
          bo.id,
        );
        await TestStorage.setQuota(bo, 1);

        await expectLater(
          endpoints.sharing.respondToOwnershipTransfer(
            bo.endpointSession,
            info.pendingTransfer!.id,
            true,
          ),
          throwsQuota(QuotaReason.transfer, isCaller: true),
        );
        final transfer = await OwnershipTransfer.db.findById(
          bo.session,
          info.pendingTransfer!.id,
        );
        expect(transfer!.handledAt, isNull);
        expect((await _row(anna, doc.uuid)).ownerId, anna.id);
      });
    });

    group('edits are never refused (AC-D3.5)', () {
      test('when over quota then document and spreadsheet edits through MCP '
          'still work, while image inserts are refused', () async {
        final mcp = await McpHarness.forUser(anna);
        final doc = await TestDrive.document(endpoints, anna, markdown: 'A.');
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        await TestStorage.fill(endpoints, anna, 2000);
        await TestStorage.setQuota(anna, 1000);

        await mcp.call('write.insert_markdown', {
          'document_uuid': docOf(doc),
          'markdown': 'More text while over quota.',
          'at': {'type': 'end'},
        });
        await mcp.call('sheets.set_values', {
          'spreadsheet': (ss['item'] as Map)['uuid'],
          'range': 'Sheet1!A1',
          'values': [
            ['still', 'editing'],
          ],
        });
        final error = await mcp.error('write.insert_image', {
          'document_uuid': docOf(doc),
          'at': {'type': 'end'},
          'source': {'base64': base64Encode(_png), 'mime': 'image/png'},
          'alt': 'A dot',
        });

        expect(error['code'], 'quota_exceeded');
        expect((await TestStorage.usage(anna)).overQuota, isTrue);
      });

      test('when an MCP image insert fits then the owner pays it', () async {
        final mcp = await McpHarness.forUser(anna);
        final doc = await TestDrive.document(endpoints, anna, markdown: 'A.');

        await mcp.call('write.insert_image', {
          'document_uuid': docOf(doc),
          'at': {'type': 'end'},
          'source': {'base64': base64Encode(_png), 'mime': 'image/png'},
          'alt': 'A dot',
        });

        expect((await _row(anna, doc.uuid)).attachmentBytes, _png.length);
      });
    });

    group('drive.listByStorage (§6.4)', () {
      test('when listing then owned items come by counted size with paging '
          'and filters', () async {
        final small = await TestStorage.fill(endpoints, anna, 100, name: 'S');
        final big = await TestStorage.fill(endpoints, anna, 5000, name: 'B');
        final mid = await TestStorage.fill(endpoints, anna, 2000, name: 'M');
        await endpoints.drive.trash(anna.endpointSession, [mid.uuid]);
        await TestStorage.fill(endpoints, bo, 9000, name: 'Other');

        final first = await endpoints.drive.listByStorage(
          anna.endpointSession,
          StorageListFilter(),
          null,
          2,
        );
        final second = await endpoints.drive.listByStorage(
          anna.endpointSession,
          StorageListFilter(),
          first.nextCursor,
          2,
        );
        final trash = await endpoints.drive.listByStorage(
          anna.endpointSession,
          StorageListFilter(trashedOnly: true),
          null,
          50,
        );
        final large = await endpoints.drive.listByStorage(
          anna.endpointSession,
          StorageListFilter(minCountedBytes: 1000),
          null,
          50,
        );

        expect(first.items.map((i) => i.uuid), [big.uuid, mid.uuid]);
        expect(second.items.map((i) => i.uuid), [small.uuid]);
        expect(second.nextCursor, isNull);
        expect(trash.items.map((i) => i.uuid), [mid.uuid]);
        expect(large.items.map((i) => i.countedBytes), [5000, 2000]);
      });
    });

    group('drive.watch', () {
      test('when the caller\'s storage changes then a storageChanged event '
          'carries the new usage', () async {
        final item = await TestStorage.fill(endpoints, anna, 10);
        final queue = await subscribed(
          endpoints.drive.watch(anna.endpointSession),
          () => StorageService.instance.setItemSize(
            anna.session,
            item,
            item.sizeBytes == 10 ? 11 : 10,
          ),
        );

        await StorageService.instance.setItemSize(anna.session, item, 4321);
        final change = await nextWhere(
          queue,
          (c) =>
              c.kind == DriveChangeKind.storageChanged &&
              c.storage?.documentsBytes == 4321,
        );

        expect(change.itemUuid, StorageEvents.nilUuid);
        expect(change.item, isNull);
        await queue.cancel(immediate: true);
      });
    });

    group('spreadsheet size estimates (§2)', () {
      test('when a spreadsheet grows or loses rows then its estimate follows '
          'and is deterministic', () async {
        final mcp = await McpHarness.forUser(anna);
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        final uuid = UuidValue.fromString(
          (ss['item'] as Map)['uuid'] as String,
        );
        final item = await _row(anna, uuid);
        final empty = (await ContentSizes.estimate(anna.session, item))!;

        await mcp.call('sheets.set_values', {
          'spreadsheet': uuid.uuid,
          'range': 'Sheet1!A1',
          'values': [
            for (var r = 0; r < 50; r++) ['Row $r', r, r * 2],
          ],
        });
        final grown = (await ContentSizes.estimate(anna.session, item))!;
        final again = (await ContentSizes.estimate(anna.session, item))!;
        await mcp.call('sheets.delete_rows', {
          'spreadsheet': uuid.uuid,
          'sheet': 'Sheet1',
          'start': 1,
          'count': 40,
        });
        final shrunk = (await ContentSizes.estimate(anna.session, item))!;

        expect(
          grown,
          greaterThan(empty + 150 * SheetsSizeEstimator.propertyRowBytes),
        );
        expect(again, grown);
        expect(shrunk, lessThan(grown));
      });

      test('when a spreadsheet is new and empty then it costs the base and '
          'one sheet, not its 1,000 default rows', () async {
        final mcp = await McpHarness.forUser(anna);
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        final uuid = UuidValue.fromString(
          (ss['item'] as Map)['uuid'] as String,
        );
        final item = await _row(anna, uuid);

        final size = await ContentSizes.estimate(anna.session, item);
        final rows = await _spaceRows(anna, uuid, 'sheet_row');

        expect(rows, greaterThanOrEqualTo(1000));
        expect(
          size,
          SheetsSizeEstimator.base + SheetsSizeEstimator.sheetBytes,
        );
        expect(item.sizeBytes, size);
        expect(size, lessThan(4 * 1024));
      });

      test('when rows and columns get a height, are hidden or formatted then '
          'only those count, by their properties', () async {
        final mcp = await McpHarness.forUser(anna);
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        final uuid = UuidValue.fromString(
          (ss['item'] as Map)['uuid'] as String,
        );
        final item = await _row(anna, uuid);
        final empty = (await ContentSizes.estimate(anna.session, item))!;

        await _updateFirst(anna, uuid, 'sheet_row', {'height': 40.0}, 2);
        await _updateFirst(anna, uuid, 'sheet_column', {'hidden': true}, 1);
        await _updateFirst(
          anna,
          uuid,
          'sheet_column',
          {'formatJson': '{"b":1}'},
          1,
        );
        final formatted = (await ContentSizes.estimate(anna.session, item))!;

        // 2 × (16 + 8 height) + (16 + 1 hidden + 7 format) on one column.
        const row = SheetsSizeEstimator.propertyRowBytes;
        expect(formatted - empty, 2 * (row + 8) + (row + 1 + 7));
      });

      test('when a sheet has many cells then the estimate grows by the '
          'content, far below the stored row size', () async {
        final mcp = await McpHarness.forUser(anna);
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        final uuid = UuidValue.fromString(
          (ss['item'] as Map)['uuid'] as String,
        );
        final item = await _row(anna, uuid);
        final empty = (await ContentSizes.estimate(anna.session, item))!;

        await mcp.call('sheets.set_values', {
          'spreadsheet': uuid.uuid,
          'range': 'Sheet1!A1',
          'values': [
            for (var r = 0; r < 100; r++)
              [for (var c = 0; c < 20; c++) c.isEven ? 'R${r}C$c' : r * c],
          ],
        });
        final full = (await ContentSizes.estimate(anna.session, item))!;
        // The stored size of the cell rows alone.
        final stored =
            (await anna.session.db.unsafeQuery(
                  'SELECT coalesce(sum(pg_column_size(t.*)), 0)::bigint '
                  'FROM cell t WHERE t."sheetId" IN (SELECT s.id FROM sheet s '
                  'JOIN rev_file f ON f.id = s."fileId" '
                  'WHERE f."fileUuid" = @u::uuid)',
                  parameters: QueryParameters.named({
                    'u': item.contentRef!.uuid,
                  }),
                )).first[0]!
                as int;

        final perCell = (full - empty) / 2000;
        expect(perCell, inInclusiveRange(18, 32));
        expect(full * 4, lessThan(stored));
      });

      test('when a built-in template is created then its measured size is '
          'close to the pre-check estimate', () async {
        final template = BuiltinTemplates.all.firstWhere(
          (t) => t.inGallery && t.sheets.isNotEmpty,
        );

        final view = await endpoints.drive.createSpreadsheet(
          anna.endpointSession,
          null,
          'T',
          template.uuid,
        );
        final measured = (await _row(anna, view.uuid)).sizeBytes;
        final pre = StorageHooks.sheetsEstimate(template.sheets);

        expect(measured, closeTo(pre, pre * 0.25));
      });

      test('when the change log is processed twice within 5 minutes then the '
          'second estimate is deferred to the end of the interval', () async {
        final mcp = await McpHarness.forUser(anna);
        final ss = await mcp.call('drive.create_spreadsheet', {'name': 'S'});
        final uuid = UuidValue.fromString(
          (ss['item'] as Map)['uuid'] as String,
        );
        final item = await _row(anna, uuid);
        final start = DateTime.utc(2030);
        ContentSizes.reset();

        await withClock(Clock.fixed(start), () async {
          await ContentSizes.onSpaceChanged(anna.session, item);
        });
        await withClock(
          Clock.fixed(start.add(const Duration(minutes: 1))),
          () async {
            await ContentSizes.onSpaceChanged(anna.session, item);
            await ContentSizes.onSpaceChanged(anna.session, item);
          },
        );
        final deferred = List.of(scheduled);
        await withClock(
          Clock.fixed(start.add(const Duration(minutes: 6))),
          () async {
            await ContentSizes.onSpaceChanged(anna.session, item);
          },
        );

        expect(deferred, [item.id]);
        expect(scheduled, [item.id]);
      });
    });
  });
}
