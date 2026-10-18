@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/json.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/versions/version_service.dart';
import 'package:wonky_server/src/write/ot/document_cache.dart';
import 'package:wonky_server/src/write/ot/document_store.dart';
import 'package:wonky_server/src/write/ot/edit_bookkeeping.dart';
import 'package:wonky_server/src/write/versions/write_history_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Write's batched edit bookkeeping, bounded version diffs and snapshot
/// cleanup of thinned versions (code-quality CQ-22, Write 03 §2 step 8).
void main() {
  withWonkyServerpod('Given an open document whose bookkeeping waits', (
    sessionBuilder,
    endpoints,
  ) {
    final flushDelay = PendingEdits.flushDelay;
    late TestUser anna;
    late DriveItemView item;
    late TestDocClient client;
    setUp(() async {
      PendingEdits.flushDelay = const Duration(hours: 1);
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, markdown: 'Hello');
      client = await TestDocClient.connect(endpoints, anna, item.contentRef!);
    });
    tearDown(() async {
      PendingEdits.flushDelay = flushDelay;
      await client.close();
    });

    /// Types [text] and waits for the Ack only (not for the bookkeeping).
    Future<void> type(String text) async {
      client.edit(Delta()..insert(text));
      while (client.inflight != null) {
        await client.processOne();
      }
    }

    Future<List<ActivityEvent>> edits() async {
      final session = sessionBuilder.build();
      final row = (await DriveItem.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(item.uuid),
      ))!;
      return ActivityEvent.db.find(
        session,
        where: (t) =>
            t.itemId.equals(row.id!) & t.type.equals(ActivityType.edited),
      );
    }

    test('when ops are acknowledged then their bookkeeping waits and is then '
        'written in one batch', () async {
      await type('a');
      await type('bc');
      await type('def');
      final before = await edits();
      final session = sessionBuilder.build();
      final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
      final state = await DocumentCache.of(session, doc);

      await DocumentCache.settle(item.contentRef!);
      final after = await edits();

      expect(before, isEmpty);
      expect(state.edits.flushes, 1);
      expect(after, hasLength(1));
      expect(decodeObject(after.single.summary)['insertedChars'], 6);
    });

    test('when a version is named right after typing then the typist is '
        'one of its authors', () async {
      await type('Draft ');

      final version = await endpoints.version.nameCurrent(
        anna.endpointSession,
        item.uuid,
        'v1',
      );

      expect(version.authors.map((a) => a.id), [anna.id]);
    });
  });

  withWonkyServerpod('Given a document history', (sessionBuilder, endpoints) {
    final maxReplayOps = WriteHistoryService.maxReplayOps;
    tearDown(() => WriteHistoryService.maxReplayOps = maxReplayOps);

    test('when a diff spans more ops than the replay cap then it compares '
        'snapshots', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final item = await TestDrive.document(endpoints, anna, markdown: 'A');
      final client = await TestDocClient.connect(
        endpoints,
        anna,
        item.contentRef!,
      );
      for (final t in ['1', '2', '3', '4']) {
        client.edit(Delta()..insert(t));
        await client.processUntilSynchronized();
      }
      await client.close();
      WriteHistoryService.maxReplayOps = 2;

      final diff = await endpoints.writeHistory.diff(
        anna.endpointSession,
        item.contentRef!,
        1,
        client.revision,
      );

      expect(diff.exact, isFalse);
      expect(diff.deltaJson, contains('4321'));
    });

    test('when an auto version is thinned then its snapshot goes unless '
        'something still needs it', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final item = await TestDrive.document(endpoints, anna, markdown: 'A');
      final client = await TestDocClient.connect(
        endpoints,
        anna,
        item.contentRef!,
      );
      for (final t in ['1', '2', '3']) {
        client.edit(Delta()..insert(t));
        await client.processUntilSynchronized();
      }
      await client.close();
      final session = sessionBuilder.build();
      final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
      for (final r in [2, 3, 4]) {
        await DocumentStore.writeSnapshot(
          session,
          doc,
          r,
          await DocumentStore.contentAt(session, doc, r),
        );
      }
      final now = clock.now().toUtc();
      final hour = DateTime.utc(
        now.year,
        now.month,
        now.day,
        now.hour,
      ).subtract(const Duration(days: 10));
      await ItemVersion.db.insert(session, [
        for (final (revision, minute) in [(2, 1), (3, 40)])
          ItemVersion(
            itemId: doc.itemId,
            kind: VersionKind.auto,
            createdAt: hour.add(Duration(minutes: minute)),
            authors: const [],
            storageKind: VersionStorage.writeRevision,
            revision: revision,
          ),
      ]);

      await VersionService.thin(session, now: now);
      final snapshots = await DocumentSnapshot.db.find(
        session,
        where: (t) => t.documentId.equals(doc.id!),
      );

      // 1: the base of the op log; 3: the kept version; 4: the newest.
      expect(snapshots.map((s) => s.revision).toSet(), {1, 3, 4});
    });
  });
}
