@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/comments/comment_service.dart';
import 'package:wonky_server/src/platform/files/file_service.dart';
import 'package:wonky_server/src/platform/versions/version_service.dart';
import 'package:wonky_server/src/sheets/changelog/agent_cursors.dart';
import 'package:wonky_server/src/sheets/headless/headless_workbook_provider.dart';
import 'package:wonky_server/src/sheets/versions/sheets_version_changes.dart';
import 'package:wonky_sheets_core/model.dart' show ChangeSummary;

import '../../../support/mcp_harness.dart';
import '../../../support/sheets_fixtures.dart';
import '../../../support/sheets_rev_hooks.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given a spreadsheet edited by Anna and Bo', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser a;
    late TestUser b;
    late McpHarness anna;
    late McpHarness bo;
    late String ss;
    late UuidValue item;

    SheetsRevHooks.install();

    Future<void> set(McpHarness who, String range, Object? value) async {
      await who.call('sheets.set_values', {
        'spreadsheet': ss,
        'range': range,
        'values': [
          [value],
        ],
      });
      await SheetsRevHooks.drainItem(a.session, item);
    }

    Future<ItemVersionState> state() async {
      final d = await DriveItem.db.findFirstRow(
        a.session,
        where: (t) => t.uuid.equals(item),
      );
      return (await ItemVersionState.db.findFirstRow(
        a.session,
        where: (t) => t.itemId.equals(d!.id!),
      ))!;
    }

    setUp(() async {
      a = await TestUsers.create(sessionBuilder, name: 'Anna');
      b = await TestUsers.create(sessionBuilder, name: 'Bo');
      anna = await McpHarness.forUser(a);
      bo = await McpHarness.forUser(b);
      ss = await SheetsFixtures.create(anna, name: 'Budget');
      item = UuidValue.fromString(ss);
      await SheetsFixtures.share(anna, ss, b.email, 'editor');
    });
    tearDown(HeadlessWorkbookProvider.clear);

    test('when edits stop then an auto version is captured only after 5 min '
        'of inactivity, once', () async {
      await set(anna, 'A1', 'one');
      final s = await state();
      expect(s.dirtySince, isNotNull);
      expect(s.editorsSinceLastVersion, contains(a.id));
      final edit = s.lastEditAt;

      Future<List<ItemVersion>> versions() => ItemVersion.db.find(
        a.session,
        where: (t) => t.itemId.equals(s.itemId),
      );
      final before = (await versions()).length;
      await VersionService.captureDue(
        a.session,
        now: edit.add(const Duration(minutes: 4)),
      );
      expect((await versions()).length, before);

      await VersionService.captureDue(
        a.session,
        now: edit.add(const Duration(minutes: 5, seconds: 1)),
      );
      final after = await versions();
      expect(after.length, before + 1);
      expect(after.last.kind, VersionKind.auto);
      expect(after.last.authors, [a.id]);
      expect((await state()).dirtySince, isNull);

      // Nothing new: no second version.
      await VersionService.captureDue(
        a.session,
        now: edit.add(const Duration(minutes: 20)),
      );
      expect((await versions()).length, before + 1);
    });

    test(
      'when editing continues for 30 min then a version is forced',
      () async {
        await set(anna, 'A1', 'one');
        final s = await state();
        // Still editing a minute ago, dirty for over 30 minutes.
        final now = s.lastEditAt.add(const Duration(minutes: 1));
        await ItemVersionState.db.updateRow(
          a.session,
          s.copyWith(dirtySince: now.subtract(const Duration(minutes: 31))),
        );
        final n = await VersionService.captureDue(a.session, now: now);
        expect(n, greaterThanOrEqualTo(1));
        expect((await state()).dirtySince, isNull);
      },
    );

    test('when a version is captured then its index lists the changed ranges '
        'with their authors, also through the endpoint', () async {
      final v0 = await VersionService.nameCurrent(
        a.session,
        a.actor,
        item,
        'Start',
      );
      await set(anna, 'B2', 'anna');
      await set(bo, 'C3', 'bo');
      final v1 = await VersionService.nameCurrent(
        a.session,
        a.actor,
        item,
        'After',
      );
      expect(v1.authors.map((u) => u.id), containsAll([a.id, b.id]));

      final index = await SheetsSnapshotIndex.db.findFirstRow(
        a.session,
        where: (t) => t.itemVersionId.equals(v1.id),
      );
      final ranges =
          ((jsonDecode(index!.changedRangesJson) as Map)['ranges'] as List)
              .cast<Map<Object?, Object?>>();
      expect({for (final r in ranges) r['u']}, {a.id, b.id});

      final viaEndpoint =
          jsonDecode(
                await endpoints.sheetsVersion.changes(
                  a.endpointSession,
                  item,
                  v1.id,
                ),
              )
              as Map;
      expect((viaEndpoint['ranges'] as List).length, ranges.length);

      // The first version holds no edits of this window.
      final first =
          jsonDecode(
                await endpoints.sheetsVersion.changes(
                  a.endpointSession,
                  item,
                  v0.id,
                ),
              )
              as Map;
      expect(
        [for (final r in first['ranges'] as List) (r as Map)['u']],
        isNot(contains(b.id)),
      );
    });

    test('when the server diff is requested then changed cells come with '
        'their authors and the file is cached', () async {
      await VersionService.nameCurrent(a.session, a.actor, item, 'Start');
      await set(anna, 'B2', 'anna');
      await set(bo, 'C3', 'bo');
      final v1 = await VersionService.nameCurrent(
        a.session,
        a.actor,
        item,
        'After',
      );
      final url = await endpoints.sheetsVersion.diff(
        a.endpointSession,
        item,
        v1.id,
        null,
      );
      expect(url.url, isNotNull);
      final index = await SheetsSnapshotIndex.db.findFirstRow(
        a.session,
        where: (t) => t.itemVersionId.equals(v1.id),
      );
      expect(index!.diffFileId, isNotNull);
      final file = await FileService.byUuid(a.session, index.diffFileId!);
      final bytes = await FileService.readBytes(a.session, file!);
      final (diff, authors) = SheetsVersionChanges.decodeDiff(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      expect(diff.cells, hasLength(2));
      expect(authors.toSet(), {a.id, b.id});

      // Cached: the same file again.
      await endpoints.sheetsVersion.diff(a.endpointSession, item, v1.id, null);
      final again = await SheetsSnapshotIndex.db.findFirstRow(
        a.session,
        where: (t) => t.itemVersionId.equals(v1.id),
      );
      expect(again!.diffFileId, index.diffFileId);
    });

    test('when a version is restored then later edits are undone, and '
        'reverting the restore brings them back except cells edited by '
        'others since', () async {
      await set(anna, 'A1', 'v1');
      final v1 = await VersionService.nameCurrent(
        a.session,
        a.actor,
        item,
        'One',
      );
      await set(anna, 'A1', 'later');
      await set(anna, 'B1', 'new');

      final r = await VersionService.restore(a.session, a.actor, item, v1.id);
      expect(r.changeId, isNotNull);
      expect(r.restorePoint.kind, VersionKind.restorePoint);
      HeadlessWorkbookProvider.clear();
      expect(await SheetsFixtures.read(anna, ss, 'A1:B1'), [
        ['v1'],
      ]);

      // Bo edits a restored cell; the revert skips it.
      await set(bo, 'A1', 'bo');
      final revert = await endpoints.sheets.revertChange(
        a.endpointSession,
        r.changeId!,
      );
      expect(revert.skipped, hasLength(1));
      HeadlessWorkbookProvider.clear();
      expect(await SheetsFixtures.read(anna, ss, 'A1:B1'), [
        ['bo', 'new'],
      ]);
    });

    test('when a version is captured then it records the file revision, and '
        'a restore that would change ranges protected from the restorer is '
        'refused before anything is written', () async {
      await set(anna, 'A1', 'old');
      final v1 = await VersionService.nameCurrent(
        a.session,
        a.actor,
        item,
        'Old',
      );
      expect(v1.revision, isNotNull);
      await set(anna, 'A1', 'new');
      await set(anna, 'C5', 'free');
      await anna.call('sheets.protect_range', {
        'spreadsheet': ss,
        'range': 'A1:B2',
        'description': 'Anna only',
      });
      final v2 = await VersionService.nameCurrent(
        a.session,
        a.actor,
        item,
        'Protected',
      );
      expect(v2.revision, greaterThan(v1.revision!));

      final driveItem = await DriveItem.db.findFirstRow(
        a.session,
        where: (t) => t.uuid.equals(item),
      );
      final head = await RevFile.db.findFirstRow(
        a.session,
        where: (t) => t.fileUuid.equals(driveItem!.contentRef!),
      );
      await expectLater(
        VersionService.restore(b.session, b.actor, item, v1.id),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.message,
            'message',
            "This version changes protected ranges you can't edit",
          ),
        ),
      );
      final after = await RevFile.db.findById(a.session, head!.id!);
      expect(after!.headRevision, head.headRevision);
      expect(await SheetsFixtures.read(anna, ss, 'A1'), [
        ['new'],
      ]);

      // The owner of the protection may restore it.
      await VersionService.restore(a.session, a.actor, item, v1.id);
      expect(await SheetsFixtures.read(anna, ss, 'A1'), [
        ['old'],
      ]);
    });

    test('when copy extras run then the comments are copied with remapped '
        'anchors and the copy is shared with the same people', () async {
      const sourceRow = '01900000-0000-7000-8000-000000000001';
      const sourceCol = '01900000-0000-7000-8000-000000000002';
      const targetRow = '01900000-0000-7000-8000-000000000003';
      const targetCol = '01900000-0000-7000-8000-000000000004';
      await CommentService.createThread(
        a.session,
        a.actor,
        threadUuid: UuidValue.fromString(
          '01900000-0000-7000-8000-0000000000aa',
        ),
        itemUuid: item,
        anchorKind: CommentAnchorKind.cell,
        anchorJson: jsonEncode({
          'v': 1,
          'sheetId': 's',
          'rowId': sourceRow,
          'colId': sourceCol,
        }),
        body: 'Check',
      );
      final copy = UuidValue.fromString(
        await SheetsFixtures.create(anna, name: 'Copy'),
      );
      await endpoints.sheetsVersion.copyExtras(
        a.endpointSession,
        item,
        copy,
        jsonEncode({sourceRow: targetRow, sourceCol: targetCol}),
        true,
        true,
      );
      final target = await DriveItem.db.findFirstRow(
        a.session,
        where: (t) => t.uuid.equals(copy),
      );
      final threads = await CommentThread.db.find(
        a.session,
        where: (t) => t.itemId.equals(target!.id!),
      );
      expect(threads, hasLength(1));
      expect(threads.single.anchorJson, contains(targetRow));
      expect(threads.single.anchorJson, contains(targetCol));
      final grants = await DriveItemPermission.db.find(
        a.session,
        where: (t) => t.itemId.equals(target!.id!),
      );
      expect(grants.map((g) => g.userId), contains(b.id));

      // Bo can't add extras to Anna's copy.
      await expectLater(
        endpoints.sheetsVersion.copyExtras(
          b.endpointSession,
          item,
          copy,
          '{}',
          true,
          false,
        ),
        throwsA(anything),
      );
    });

    test('when an agent writes then its cursor shows the written range for '
        'a few seconds', () async {
      await set(anna, 'D4', 'agent');
      final driveItem = await DriveItem.db.findFirstRow(
        a.session,
        where: (t) => t.uuid.equals(item),
      );
      expect(
        AgentCursors.isShown(
          driveItem!,
          a.actor.copyWith(kind: ActorKind.mcp),
        ),
        isTrue,
      );
      final cursor =
          jsonDecode(
                AgentCursors.cursorOf(
                  ChangeSummary(
                    ranges: [
                      {'s': 'S', 'r1': 'r', 'c1': 'c', 'r2': 'r', 'c2': 'c'},
                    ],
                  ),
                )!,
              )
              as Map;
      expect(cursor['sheetId'], 'S');
      expect((cursor['activeCell'] as Map)['rowId'], 'r');
      expect(AgentCursors.cursorOf(ChangeSummary()), isNull);
    });
  });
}
