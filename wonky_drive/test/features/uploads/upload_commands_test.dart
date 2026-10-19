import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show CommandResult;
import 'package:wonky_drive/config/drive_app_config.dart';
import 'package:wonky_drive/features/preview/preview_commands.dart';
import 'package:wonky_drive/features/uploads/upload_host.dart';
import 'package:wonky_drive/features/uploads/upload_precheck.dart';
import 'package:wonky_drive/features/uploads/upload_queue.dart';
import 'package:wonky_drive/features/uploads/upload_store.dart';
import 'package:wonky_drive/features/uploads/upload_task.dart';
import 'package:wonky_drive/l10n/drive_l10n.dart';

import '../../support/upload_fakes.dart';

/// The upload commands (Drive 04 §9) through the real dispatcher and undo
/// service: one undo step per batch (AC-D2.7), headless pre-checks, the
/// panel actions, folder drops.
void main() {
  const mb = 1024 * 1024;
  late CommandTestHarness h;
  late FakeUploadApi api;
  late UploadHost host;
  late UploadQueue q;
  var harnessed = false;

  Future<void> setUpHarness({StorageController? storage}) async {
    h = CommandTestHarness(
      config: const DriveAppConfig(),
      storage: storage ?? FakeStorage.used(0),
    );
    api = FakeUploadApi()
      ..onReady = (v) => h.drive.seed(
        name: v.name,
        kind: DriveItemKind.file,
        uuid: v.uuid,
        parentUuid: v.parentUuid,
      );
    host = UploadHost.of(h.services)..api = api;
    q = UploadQueue(
      api: api,
      store: MemoryUploadStore(),
      connectivity: h.services.connectivity,
      newId: sequentialIds(),
    );
    host.attach(q);
    await q.start();
    harnessed = true;
  }

  Future<CommandResult> upload(List<UploadFile> files, {UuidValue? parent}) =>
      h.invoke('drive.upload.files', {
        'staged': host.stage(files),
        'parentUuid': ?parent?.uuid,
      });

  bool trashed(UuidValue uuid) => h.drive.item(uuid).trashedAt != null;

  tearDown(() async {
    if (!harnessed) return;
    harnessed = false;
    await host.stop();
    await h.dispose();
  });

  group('Given Wonky Drive with an empty drive', () {
    setUp(setUpHarness);

    test('when 5 files are uploaded then undo moves them to the trash and '
        'redo restores them (AC-D2.7)', () async {
      final r = await upload([for (var i = 1; i <= 5; i++) textFile('$i.txt')]);
      await settle();
      final uuids = [for (final t in q.tasks) t.result!.uuid];

      expect((r.data! as Map)['queued'], 5);
      expect(uuids.map(trashed), everyElement(isFalse));

      await h.undo();
      expect(uuids.map(trashed), everyElement(isTrue));

      await h.redo();
      expect(uuids.map(trashed), everyElement(isFalse));
    });

    test('when a batch is undone while a file still uploads then that '
        'upload is cancelled and redo starts it again', () async {
      api.sendGates['slow.bin'] = Completer<void>();
      await upload([textFile('fast.txt'), textFile('slow.bin')]);
      await settle();
      final fast = q.tasks.first.result!.uuid;

      await h.undo();
      await settle();

      expect(trashed(fast), isTrue);
      expect(q.tasks.last.status, UploadStatus.cancelled);
      expect(api.calls, contains('cancel:slow.bin'));

      api.sendGates.remove('slow.bin');
      await h.redo();
      await settle();

      expect(trashed(fast), isFalse);
      expect(q.tasks.last.status, UploadStatus.done);
    });

    test('when files are uploaded into a folder then the requests carry '
        'the folder and its name shows in the rows', () async {
      final team = h.drive.seed(name: 'Team', kind: DriveItemKind.folder);

      await upload([textFile('a.txt')], parent: team.uuid);
      await settle();

      expect(api.requests.single.parentUuid, team.uuid);
      expect(q.tasks.single.parentName, 'Team');
    });

    test('when a file is over 50 MB then it becomes a failed row and the '
        'others upload', () async {
      await upload([textFile('photo.raw', 51 * mb), textFile('ok.txt')]);
      await settle();

      final byName = {for (final t in q.tasks) t.fileName: t};
      expect(byName['photo.raw']!.failure, UploadFailure.tooLarge);
      expect(byName['ok.txt']!.status, UploadStatus.done);
      expect(api.requests.map((r) => r.name), ['ok.txt']);
    });

    test('when a picked file is over 50 MB then it is refused from its '
        'size without reading it, and only the accepted file is read '
        '(DR-1)', () async {
      final read = <String>[];
      UploadFile picked(String name, int size) => UploadFile.lazy(
        name: name,
        size: size,
        read: () async {
          read.add(name);
          return bytesOf(10);
        },
      );

      await upload([picked('video.mp4', 2000 * mb), picked('ok.txt', 10)]);
      await settle();

      final byName = {for (final t in q.tasks) t.fileName: t};
      expect(byName['video.mp4']!.failure, UploadFailure.tooLarge);
      expect(byName['video.mp4']!.sizeBytes, 2000 * mb);
      expect(byName['ok.txt']!.status, UploadStatus.done);
      expect(read, ['ok.txt']);
    });

    test('when more files are picked than a batch allows then none of '
        'them is read', () async {
      var reads = 0;
      final files = [
        for (var i = 0; i <= maxUploadBatchFiles; i++)
          UploadFile.lazy(
            name: '$i.txt',
            size: 10,
            read: () async {
              reads++;
              return bytesOf(10);
            },
          ),
      ];

      await upload(files);
      await settle();

      expect(reads, 0);
      expect(q.tasks, isEmpty);
    });

    test('when an accepted file can no longer be read then its row fails '
        'and the others upload', () async {
      await upload([
        UploadFile.lazy(
          name: 'gone.txt',
          size: 10,
          read: () async => throw StateError('moved'),
        ),
        textFile('ok.txt'),
      ]);
      await settle();

      final byName = {for (final t in q.tasks) t.fileName: t};
      expect(byName['gone.txt']!.status, UploadStatus.failed);
      expect(byName['gone.txt']!.failure, UploadFailure.notSaved);
      expect(byName['ok.txt']!.status, UploadStatus.done);
      expect(api.requests.map((r) => r.name), ['ok.txt']);
    });

    test('when a folder is dropped then its structure is created and the '
        'files upload into it; undo trashes the folder', () async {
      await upload([
        textFile('top.txt'),
        UploadFile(
          name: 'a.jpg',
          bytes: bytesOf(3),
          folderPath: const ['Holiday'],
        ),
        UploadFile(
          name: 'b.jpg',
          bytes: bytesOf(3),
          folderPath: const ['Holiday', 'Day 1'],
        ),
      ]);
      await settle();

      final holiday = h.drive.items.singleWhere((i) => i.name == 'Holiday');
      final day1 = h.drive.items.singleWhere((i) => i.name == 'Day 1');
      expect(day1.parentUuid, holiday.uuid);
      final parents = {for (final r in api.requests) r.name: r.parentUuid};
      expect(parents, {
        'top.txt': null,
        'a.jpg': holiday.uuid,
        'b.jpg': day1.uuid,
      });

      await h.undo();
      expect(trashed(holiday.uuid), isTrue);
    });

    test('when uploads are cancelled with cancelAll then nothing runs any '
        'more', () async {
      api.allSendsGate = Completer<void>();
      await upload([textFile('a.txt'), textFile('b.txt')]);
      await settle();

      final r = await h.invoke('drive.upload.cancelAll', {'confirmed': true});
      await settle();

      expect((r.data! as Map)['cancelled'], 2);
      expect(q.hasActive, isFalse);
    });

    test(
      'when a failed upload is retried with retryAll then it uploads',
      () async {
        api.failNext(
          'create',
          'a.txt',
          WonkyException(code: WonkyErrorCode.limitExceeded, message: 'Wait'),
        );
        await upload([textFile('a.txt')]);
        await settle();
        expect(q.tasks.single.failure, UploadFailure.rateLimited);

        await h.invoke('drive.upload.retryAll');
        await settle();

        expect(q.tasks.single.status, UploadStatus.done);
      },
    );

    test('when finished uploads are cleared then the panel hides', () async {
      await upload([textFile('a.txt')]);
      await settle();
      expect(host.panelVisible.value, isTrue);

      await h.invoke('drive.upload.clearFinished');

      expect(q.tasks, isEmpty);
      expect(host.panelVisible.value, isFalse);
    });

    test('when the panel is toggled then it reports the queue', () async {
      await upload([textFile('a.txt')]);
      await settle();
      host.panelVisible.value = false;

      final r = await h.invoke('drive.upload.togglePanel');

      expect(host.panelVisible.value, isTrue);
      expect(
        ((r.data! as Map)['uploads'] as List).single,
        containsPair('name', 'a.txt'),
      );
    });

    test('when offline then File upload… stays available in Drive', () {
      h.services.connectivity.forceOffline(true);
      addTearDown(() => h.services.connectivity.forceOffline(false));

      expect(
        h.services.dispatcher.stateOf('shell.drive.upload').enabled,
        isTrue,
      );
    });
  });

  group('Given an account with 5 MB left', () {
    setUp(() => setUpHarness(storage: FakeStorage.used(45 * mb)));

    test('when an agent uploads more than fits then only the files that '
        'fit are queued', () async {
      final r = await upload([
        textFile('a.bin', 3 * mb),
        textFile('b.bin', 4 * mb),
        textFile('c.bin', mb),
      ]);

      expect((r.data! as Map)['queued'], 2);
      expect(q.tasks.map((t) => t.fileName), ['a.bin', 'c.bin']);
    });
  });

  group('Given a selection in the Drive list', () {
    testWidgets('when it is one CSV file then the menu offers Preview, Open '
        'with Wonky Sheets and Download instead of Open', (tester) async {
      late ItemMenuContribution menu;
      final csv = fileView(
        UuidValue.fromString('00000000-0000-7000-8000-000000000042'),
        'data.csv',
      );
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('en'),
          delegates: const [
            DriveLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Builder(
            builder: (context) {
              menu = fileItemMenu(context, [csv]);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(menu.hide, {'shell.drive.open'});
      expect(
        [for (final c in menu.commands) (c.id, c.label)],
        [
          ('drive.file.preview', null),
          ('drive.file.openWith', 'Open with Wonky Sheets'),
          ('drive.file.download', null),
        ],
      );
      expect(menu.commands[1].args, {'uuid': csv.uuid.uuid, 'app': 'sheets'});
    });
  });
}
