@Tags(['integration'])
library;

import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/drive/kind_masks.dart';

import '../../support/test_drive.dart';
import '../../support/test_files.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

int _bits(Iterable<DriveItemKind> kinds) =>
    kinds.fold(0, (m, k) => m | KindMasks.bit(k));

void main() {
  withWonkyServerpod('Given nested folders', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView outer;
    late DriveItemView inner;
    setUp(() async {
      TestFiles.skipPreviews();
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      outer = await TestDrive.folder(endpoints, anna, name: 'Outer');
      inner = await TestDrive.folder(
        endpoints,
        anna,
        name: 'Inner',
        parentUuid: outer.uuid,
      );
    });

    Future<int> mask(DriveItemView folder) async =>
        (await TestFiles.row(anna.session, folder.uuid)).kindMask;

    test(
      'when a document is created inside then both folders have it',
      () async {
        await TestDrive.document(endpoints, anna, parentUuid: inner.uuid);

        expect(await mask(inner), _bits([DriveItemKind.document]));
        expect(
          await mask(outer),
          _bits([DriveItemKind.folder, DriveItemKind.document]),
        );
      },
    );

    test(
      'when the document is trashed and restored then the masks follow',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          parentUuid: inner.uuid,
        );

        await endpoints.drive.trash(anna.endpointSession, [doc.uuid]);
        final trashed = (await mask(inner), await mask(outer));
        await endpoints.drive.restore(anna.endpointSession, [doc.uuid]);

        expect(trashed, (0, _bits([DriveItemKind.folder])));
        expect(await mask(inner), _bits([DriveItemKind.document]));
      },
    );

    test(
      'when the inner folder is trashed and restored then the outer mask follows',
      () async {
        await TestDrive.document(endpoints, anna, parentUuid: inner.uuid);

        await endpoints.drive.trash(anna.endpointSession, [inner.uuid]);
        final trashed = await mask(outer);
        await endpoints.drive.restore(anna.endpointSession, [inner.uuid]);

        expect(trashed, 0);
        expect(
          await mask(outer),
          _bits([DriveItemKind.folder, DriveItemKind.document]),
        );
      },
    );

    test('when the document moves out then the old chain loses it', () async {
      final other = await TestDrive.folder(endpoints, anna, name: 'Other');
      final doc = await TestDrive.document(
        endpoints,
        anna,
        parentUuid: inner.uuid,
      );

      await endpoints.drive.move(anna.endpointSession, [doc.uuid], other.uuid);

      expect(await mask(inner), 0);
      expect(await mask(outer), _bits([DriveItemKind.folder]));
      expect(await mask(other), _bits([DriveItemKind.document]));
    });

    test(
      'when the document is deleted forever then the masks lose it',
      () async {
        final doc = await TestDrive.document(
          endpoints,
          anna,
          parentUuid: inner.uuid,
        );
        await endpoints.drive.trash(anna.endpointSession, [doc.uuid]);
        await endpoints.drive.restore(anna.endpointSession, [doc.uuid]);
        await endpoints.drive.trash(anna.endpointSession, [doc.uuid]);

        await endpoints.drive.deletePermanently(anna.endpointSession, [
          doc.uuid,
        ]);

        expect(await mask(inner), 0);
      },
    );

    test('when a file is uploading then it counts only once ready', () async {
      final start = await TestFiles.start(
        endpoints,
        anna,
        name: 'a.txt',
        bytes: [0x61],
        parentUuid: inner.uuid,
      );
      final uploading = await mask(inner);
      await TestFiles.putBytes(anna.session, start.ticket.fileUuid, [0x61]);
      await endpoints.drive.completeFileUpload(
        anna.endpointSession,
        start.item.uuid,
      );

      expect(uploading, 0);
      expect(await mask(inner), _bits([DriveItemKind.file]));
      expect(
        await mask(outer),
        _bits([DriveItemKind.folder, DriveItemKind.file]),
      );
    });

    test(
      'when listing with foldersContaining then only folders with that kind are returned',
      () async {
        final empty = await TestDrive.folder(endpoints, anna, name: 'Empty');
        await TestDrive.document(endpoints, anna, parentUuid: inner.uuid);
        final doc = await TestDrive.document(endpoints, anna);

        final page = await endpoints.drive.list(
          anna.endpointSession,
          null,
          DriveListFilter(
            kinds: [DriveItemKind.folder, DriveItemKind.document],
            foldersContaining: DriveItemKind.document,
          ),
          DriveSort(),
          null,
          100,
        );
        final sheetsPage = await endpoints.drive.list(
          anna.endpointSession,
          null,
          DriveListFilter(foldersContaining: DriveItemKind.spreadsheet),
          DriveSort(),
          null,
          100,
        );

        final uuids = page.items.map((i) => i.uuid).toSet();
        expect(uuids, containsAll([outer.uuid, doc.uuid]));
        expect(uuids, isNot(contains(empty.uuid)));
        expect(
          sheetsPage.items.where((i) => i.kind == DriveItemKind.folder),
          isEmpty,
        );
      },
    );

    test('when a mask drifted then the nightly recompute repairs it', () async {
      await TestDrive.document(endpoints, anna, parentUuid: inner.uuid);
      await DriveItem.db.updateWhere(
        anna.session,
        columnValues: (t) => [t.kindMask(0)],
        where: (t) => t.uuid.inSet({inner.uuid, outer.uuid}),
      );

      final fixed = await KindMasks.recomputeAll(anna.session);

      expect(fixed, greaterThanOrEqualTo(2));
      expect(await mask(inner), _bits([DriveItemKind.document]));
      expect(
        await mask(outer),
        _bits([DriveItemKind.folder, DriveItemKind.document]),
      );
    });
  });

  withWonkyServerpod('Given random drive operations', (
    sessionBuilder,
    endpoints,
  ) {
    for (final seed in [7, 42]) {
      test(
        'when applying 50 random operations (seed $seed) then the maintained masks equal a full recompute',
        () async {
          TestFiles.skipPreviews();
          final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
          final s = anna.endpointSession;
          final random = Random(seed);
          final live = <DriveItemView>[];
          final folders = <UuidValue>{};
          final trashed = <UuidValue>[];

          Future<void> check(String step) async {
            final rows = await DriveItem.db.find(
              anna.session,
              where: (t) =>
                  t.ownerId.equals(anna.id) &
                  t.kind.equals(DriveItemKind.folder) &
                  t.trashedAt.equals(null),
            );
            final computed = await KindMasks.computeAll(anna.session);
            for (final f in rows) {
              expect(
                f.kindMask,
                computed[f.id] ?? 0,
                reason: 'folder ${f.name} after $step',
              );
            }
          }

          UuidValue? randomFolder() {
            final live = folders.toList();
            if (live.isEmpty || random.nextInt(4) == 0) return null;
            return live[random.nextInt(live.length)];
          }

          for (var i = 0; i < 50; i++) {
            final op = random.nextInt(10);
            String step;
            if (op < 4 || live.isEmpty) {
              final parent = randomFolder();
              final which = random.nextInt(3);
              final DriveItemView item;
              if (which == 0) {
                item = await TestDrive.folder(
                  endpoints,
                  anna,
                  name: 'F$i',
                  parentUuid: parent,
                );
                folders.add(item.uuid);
              } else if (which == 1) {
                item = await TestDrive.document(
                  endpoints,
                  anna,
                  name: 'D$i',
                  parentUuid: parent,
                );
              } else {
                item = await TestFiles.upload(
                  endpoints,
                  anna,
                  name: 'f$i.txt',
                  parentUuid: parent,
                );
              }
              live.add(item);
              step = 'create ${item.name}';
            } else if (op < 6) {
              final item = live[random.nextInt(live.length)];
              final target = randomFolder();
              step = 'move ${item.name}';
              try {
                await endpoints.drive.move(s, [item.uuid], target);
              } on WonkyException {
                step = 'refused move ${item.name}';
              }
            } else if (op < 8) {
              final item = live.removeAt(random.nextInt(live.length));
              await endpoints.drive.trash(s, [item.uuid]);
              trashed.add(item.uuid);
              folders.remove(item.uuid);
              step = 'trash ${item.name}';
            } else if (op < 9 && trashed.isNotEmpty) {
              final uuid = trashed.removeAt(random.nextInt(trashed.length));
              await endpoints.drive.restore(s, [uuid]);
              final view = await endpoints.drive.get(s, uuid);
              live.add(view);
              if (view.kind == DriveItemKind.folder) folders.add(uuid);
              step = 'restore ${view.name}';
            } else if (trashed.isNotEmpty) {
              final uuid = trashed.removeAt(random.nextInt(trashed.length));
              await endpoints.drive.deletePermanently(s, [uuid]);
              step = 'delete';
            } else {
              step = 'noop';
            }
            // Items inside trashed or deleted folders leave the live sets.
            final rows = await DriveItem.db.find(
              anna.session,
              where: (t) => t.ownerId.equals(anna.id),
            );
            final liveIds = {
              for (final r in rows)
                if (r.trashedAt == null) r.uuid,
            };
            final existing = {for (final r in rows) r.uuid};
            live.removeWhere((v) => !liveIds.contains(v.uuid));
            folders.removeWhere((u) => !liveIds.contains(u));
            trashed.removeWhere(
              (u) => liveIds.contains(u) || !existing.contains(u),
            );
            await check(step);
          }
        },
      );
    }
  });
}
