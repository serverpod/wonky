@Tags(['integration'])
library;

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_file_state.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/platform/revlog/rev_jobs.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';
import 'package:wonky_server/src/platform/revlog/server_change_records.dart';

import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'support/test_rev_binding.dart';

/// `revlog.pruneOps` (RevLog spec 05 §10, CQ-59): op payloads past the
/// retention go, unless a live server change record still needs them for
/// revert; slim rows go after the tombstone period.
void main() {
  withWonkyServerpod('Given a RevLog file with old ops', (
    sessionBuilder,
    endpoints,
  ) {
    final binding = TestRevBinding.instance;
    late TestUser anna;
    late Session session;
    late RevFileState state;
    late RevFileLease lease;
    late TestFileIds ids;

    setUpAll(() async {
      await createTestTables(sessionBuilder.build());
      RevHooks.debounce = const Duration(hours: 1);
    });

    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      session = sessionBuilder.build();
      final item = await testItem(session, anna, 'Old');
      ids = TestFileIds(item.uuid.uuid);
      await RevLogService.createFile(
        session,
        binding: binding,
        item: item,
        submitter: submitterOf(anna),
        initialChanges: ids.creation(title: 'Old'),
      );
      state = (await RevFileStates.of(session, binding, item.uuid))!;
      lease = RevFileStates.retain(state);
    });
    tearDown(() async {
      lease.release();
      await RevHooks.idle();
    });

    Future<int> submit(List<RowChange> changes) async =>
        (await RevLogService.submit(
          session,
          binding: binding,
          state: state,
          cs: ChangeSet(
            clientOpId: const Uuid().v7(),
            baseRevision: state.revision,
            changes: changes,
          ),
          submitter: submitterOf(anna),
          connectionRole: Role.editor,
        )).revision;

    Future<void> age(int revision, Duration by) => session.db.unsafeExecute(
      'UPDATE rev_op SET "committedAt" = now() - make_interval(days => @d) '
      'WHERE "fileId" = @f AND revision = @r',
      parameters: QueryParameters.named({
        'd': by.inDays,
        'f': state.fileId,
        'r': revision,
      }),
    );

    Future<Map<int, bool>> payloads() async {
      final ops = await RevOp.db.find(
        session,
        where: (t) => t.fileId.equals(state.fileId),
        orderBy: (t) => t.revision,
      );
      return {for (final o in ops) o.revision: o.payload != null};
    }

    test('when ops are past the retention then their payloads are dropped '
        'and prunedBelow moves past them', () async {
      final r2 = await submit([ids.setCell(0, 0, 'n:1')]);
      final r3 = await submit([ids.setCell(0, 1, 'n:2')]);
      for (final r in [1, r2]) {
        await age(r, const Duration(days: 40));
      }

      final pruned = await RevJobs.pruneOps(session);

      // Global job: other files of the shared database may be pruned too.
      expect(pruned, greaterThanOrEqualTo(2));
      expect(await payloads(), {1: false, r2: false, r3: true});
      final file = await RevFile.db.findById(session, state.fileId);
      expect(file!.prunedBelow, r3);
    });

    test('when an old op belongs to a live server change record then its '
        'payload is kept for revert', () async {
      final r2 = await submit([ids.setCell(1, 0, 'n:3')]);
      final recordId = const Uuid().v7obj();
      await session.db.unsafeExecute(
        'UPDATE rev_op SET "recordId" = @rec::uuid '
        'WHERE "fileId" = @f AND revision = @r',
        parameters: QueryParameters.named({
          'rec': recordId.uuid,
          'f': state.fileId,
          'r': r2,
        }),
      );
      await ServerChangeRecords.store(
        session,
        actor: anna.actor,
        fileUuid: state.fileUuid,
        label: 'Recorded',
        recordId: recordId,
        cellsAffected: 1,
      );
      for (final r in [1, r2]) {
        await age(r, const Duration(days: 40));
      }

      await RevJobs.pruneOps(session);

      expect(await payloads(), {1: false, r2: true});
      final file = await RevFile.db.findById(session, state.fileId);
      expect(file!.prunedBelow, r2);
    });

    test('when a pruned op is older than the tombstone period then its row '
        'is deleted', () async {
      final r2 = await submit([ids.setCell(2, 0, 'n:4')]);
      await age(1, const Duration(days: 400));
      await age(r2, const Duration(days: 40));

      await RevJobs.pruneOps(session);

      expect(await payloads(), {r2: false});
    });
  });
}
