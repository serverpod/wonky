import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/files.dart';

/// The M8 contracts of Drive 05 D-1: new protocol values reach the client,
/// home scopes, the config defaults that keep v1 behavior, and FakeStorage.
void main() {
  final protocol = Protocol();

  T roundTrip<T>(Object model) =>
      protocol.deserialize<T>(jsonDecode(jsonEncode(model)));

  group('Given the v2 protocol values', () {
    test('when every new enum value is deserialized then it survives', () {
      for (final v in [DriveItemKind.presentation, DriveItemKind.file]) {
        expect(protocol.deserialize<DriveItemKind>(v.name), v);
      }
      expect(
        protocol.deserialize<DriveChangeKind>('storageChanged'),
        DriveChangeKind.storageChanged,
      );
      expect(
        protocol.deserialize<NotificationKind>('storage'),
        NotificationKind.storage,
      );
      expect(
        protocol.deserialize<WonkyErrorCode>('quotaExceeded'),
        WonkyErrorCode.quotaExceeded,
      );
      expect(
        protocol.deserialize<ActivityType>('uploaded'),
        ActivityType.uploaded,
      );
      for (final v in [StoredFileKind.driveFile, StoredFileKind.preview]) {
        expect(protocol.deserialize<StoredFileKind>(v.name), v);
      }
      for (final v in FileCategory.values) {
        expect(protocol.deserialize<FileCategory>(v.name), v);
      }
      for (final v in FileUploadState.values) {
        expect(protocol.deserialize<FileUploadState>(v.name), v);
      }
      for (final v in UploadConflictMode.values) {
        expect(protocol.deserialize<UploadConflictMode>(v.name), v);
      }
    });

    test('when comparing categories then core and protocol names match', () {
      expect(
        FileTypeCategory.values.map((c) => c.name),
        FileCategory.values.map((c) => c.name),
      );
    });

    test('when a file item view round-trips then its v2 fields survive', () {
      final view = roundTrip<DriveItemView>(
        DriveItemView(
          uuid: UuidValue.fromString('0190a0e0-0000-7000-8000-000000000001'),
          kind: DriveItemKind.file,
          name: 'photo.png',
          owner: UserSummary(
            id: 1,
            uuid: UuidValue.fromString('0190a0e0-0000-7000-8000-0000000000aa'),
            displayName: 'Anna',
            email: 'anna@example.com',
            avatarColor: '#2563eb',
            colorIndex: 0,
          ),
          role: AccessRole.owner,
          shared: false,
          sizeBytes: 10,
          createdAt: DateTime.utc(2026),
          modifiedAt: DateTime.utc(2026),
          starred: false,
          pinnedOffline: false,
          editorsCanShare: true,
          nonEditorsCanExport: true,
          viewersSeeComments: false,
          attachmentBytes: 5,
          countedBytes: 15,
          mimeType: 'image/png',
          fileCategory: FileCategory.image,
          uploadState: FileUploadState.uploading,
          fileMetaJson: '{"width":1,"height":1}',
        ),
      );
      expect(view.kind, DriveItemKind.file);
      expect(view.countedBytes, 15);
      expect(view.fileCategory, FileCategory.image);
      expect(view.uploadState, FileUploadState.uploading);
    });

    test('when a storage change and quota details round-trip then they '
        'keep their data', () {
      final change = roundTrip<DriveChange>(
        DriveChange(
          kind: DriveChangeKind.storageChanged,
          itemUuid: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000000',
          ),
          storage: FakeStorage.usageOf(46 * 1024 * 1024),
        ),
      );
      expect(change.storage?.availableBytes, 4 * 1024 * 1024);

      final details = QuotaExceededDetails.fromJson(
        jsonDecode(
              jsonEncode(
                QuotaExceededDetails(
                  neededBytes: 12998246,
                  availableBytes: 3250585,
                  quotaBytes: 52428800,
                  chargedUserId: 42,
                  chargedUserName: 'Anna Berg',
                  isCaller: false,
                  reason: 'image',
                ),
              ),
            )
            as Map<String, dynamic>,
      );
      expect(details.reason, 'image');
      expect(details.isCaller, isFalse);
    });

    test('when an old StorageUsage payload arrives then v2 fields default', () {
      final usage = protocol.deserialize<StorageUsage>({
        'bytesUsed': 1,
        'documents': 0,
        'spreadsheets': 0,
        'folders': 0,
        'files': 0,
      });
      expect(usage.quotaBytes, 50 * 1024 * 1024);
      expect(usage.calculating, isFalse);
    });
  });

  group('Given home scopes', () {
    test('when Drive lists then every kind is listed and managed', () {
      const s = HomeScope.all();
      expect(s.isAll, isTrue);
      expect(s.listKinds, isNull);
      expect(s.foldersContaining, isNull);
      expect(s.managesFolders && s.uploadsFiles && s.showsTypeFilter, isTrue);
      expect(s.showsTemplateStrip, isFalse);
      expect(s.newKinds, contains(DriveItemKind.presentation));
      expect(s.lists(DriveItemKind.file), isTrue);
    });

    test('when an app home lists then only its kind and folders show', () {
      const s = HomeScope.kind(DriveItemKind.spreadsheet);
      expect(s.listKinds, [DriveItemKind.spreadsheet, DriveItemKind.folder]);
      expect(s.searchKinds, [DriveItemKind.spreadsheet]);
      expect(s.foldersContaining, DriveItemKind.spreadsheet);
      expect(s.newKinds, [DriveItemKind.spreadsheet]);
      expect(s.managesFolders || s.uploadsFiles || s.showsTypeFilter, isFalse);
      expect(s.showsTemplateStrip, isTrue);
      expect(s.lists(DriveItemKind.document), isFalse);
      expect(s, const HomeScope.kind(DriveItemKind.spreadsheet));
    });

    test('when the nav specs are read then Drive has the tree and Storage', () {
      expect(HomeNavSpec.drive.folderTree, isTrue);
      expect(
        HomeNavSpec.drive.items.map((i) => i.destination),
        contains(HomeNavDestination.storage),
      );
      expect(HomeNavSpec.appHome.folderTree, isFalse);
      expect(HomeNavSpec.appHome.items.first.route, '/');
      expect(
        HomeNavSpec.appHome.items.map((i) => i.destination),
        isNot(contains(HomeNavDestination.storage)),
      );
    });

    test('when route queries are parsed then invalid uuids are dropped', () {
      final r = NewItemRequest.fromQuery({
        'folder': '0190a0e0-0000-7000-8000-000000000001',
        'template': 'nope',
      });
      expect(r.folderUuid?.uuid, '0190a0e0-0000-7000-8000-000000000001');
      expect(r.templateUuid, isNull);
      expect(ImportRouteRequest.fromQuery({}), isNull);
      expect(
        ImportRouteRequest.fromQuery({
          'file': '0190a0e0-0000-7000-8000-000000000002',
        })?.fileItemUuid.uuid,
        '0190a0e0-0000-7000-8000-000000000002',
      );
    });
  });

  group('Given an app config', () {
    test('when an app does not opt in then the v1 home is kept', () {
      const config = TestAppConfig();
      expect(config.homeScope, isNull);
      expect(config.homeNav, HomeNavSpec.legacy);
      expect(config.homeNav.myFilesRoute, '/my-drive');
      expect(config.newItemRoute, isNotNull);
      expect(config.importRoute, isNull);
      expect(config.appName, 'Wonky Test');
    });

    test('when the app is Drive then it has no primary kind or /new', () {
      const config = TestAppConfig(
        app: WonkyAppKind.drive,
        scope: HomeScope.all(),
      );
      expect(config.primaryKind, isNull);
      expect(config.itemPath('u'), '/file/u');
      expect(config.homeNav, HomeNavSpec.drive);
      expect(config.newItemRoute, isNull);
    });

    test('when an app home opts in then it gets the app-home menu', () {
      const config = TestAppConfig(
        scope: HomeScope.kind(DriveItemKind.document),
      );
      expect(config.homeNav, HomeNavSpec.appHome);
      expect(config.homeNav.myFilesRoute, '/my-files');
    });

    test(
      'when the Drive app creates an item then nothing is created',
      () async {
        final h = CommandTestHarness(
          config: const TestAppConfig(app: WonkyAppKind.drive),
        );
        expect(await h.services.config.createItem(h.services), isNull);
      },
    );
  });

  group('Given FakeStorage', () {
    test('when usage changes then listeners hear it and checks follow', () {
      final storage = FakeStorage.used(10 * 1024 * 1024);
      var heard = 0;
      storage.addListener(() => heard++);

      expect(storage.value!.fits(40 * 1024 * 1024), isTrue);
      expect(storage.value!.fits(41 * 1024 * 1024), isFalse);
      expect(storage.value!.isWarning(), isFalse);

      storage.emit(FakeStorage.usageOf(51 * 1024 * 1024));
      expect(heard, 1);
      expect(storage.value!.overQuota, isTrue);
      expect(storage.value!.availableBytes, 0);
      expect(storage.value!.isWarning(), isTrue);
      expect(
        FakeStorage.usageOf(60 * 1024 * 1024, calculating: true).fits(1),
        isTrue,
      );
    });

    test('when a harness gets a storage then the services expose it', () {
      final storage = FakeStorage.used(1);
      final h = CommandTestHarness(storage: storage);
      expect(h.services.storage, same(storage));
      expect(CommandTestHarness().services.storage.value, isNull);
    });
  });
}
