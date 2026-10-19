import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show AccessRole;
import 'package:wonky_revlog/apply.dart' show RevRejectReason;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';

import '../support/harness.dart';

void main() {
  late FakeRevHub hub;
  final rows = [newId(), newId(), newId()];

  setUp(() => hub = FakeRevHub(testSchema));

  /// Anna creates the file on her device and it is committed.
  Future<(Device, RevFileSync, MapPort)> created() async {
    final a = await Device.open(hub, anna);
    final (sync, port, _) = await a.openFile(docId);
    a.edit(sync, port, creation(rows));
    await sync.whenSynced(timeout: const Duration(seconds: 5));
    return (a, sync, port);
  }

  group('Given a file created on one device', () {
    test('when a second user opens it, then the pages load the same state '
        'and edits reach the other side', () async {
      final (a, sa, pa) = await created();
      a.edit(sa, pa, setCell(pa.model, rows[0], 0, 'from Anna'));
      await sa.whenSynced(timeout: const Duration(seconds: 5));

      final b = await Device.open(hub, bo);
      final (sb, pb, plan) = await b.openFile(docId);
      await plan.isComplete.future.timeout(const Duration(seconds: 5));
      expect(pb.snapshot, pa.snapshot);
      expect(pb.cell(rows[0], 0), 'from Anna');

      b.edit(sb, pb, setCell(pb.model, rows[1], 1, 'from Bo'));
      await sb.whenSynced(timeout: const Duration(seconds: 5));
      await eventually(() => pa.cell(rows[1], 1) == 'from Bo');
      expect(pa.snapshot, pb.snapshot);
      expect(hub.file(docId).head, 3);
    });

    test('when both write the same cell, then the later arrival wins on '
        'both devices', () async {
      final (a, sa, pa) = await created();
      final b = await Device.open(hub, bo);
      final (sb, pb, plan) = await b.openFile(docId);
      await plan.isComplete.future.timeout(const Duration(seconds: 5));

      a.edit(sa, pa, setCell(pa.model, rows[2], 0, 'A'));
      await sa.whenSynced(timeout: const Duration(seconds: 5));
      b.edit(sb, pb, setCell(pb.model, rows[2], 0, 'B'));
      await sb.whenSynced(timeout: const Duration(seconds: 5));

      await eventually(() => pa.cell(rows[2], 0) == 'B');
      expect(pb.cell(rows[2], 0), 'B');
      expect(pa.snapshot, pb.snapshot);
    });
  });

  group('Given a device that goes offline', () {
    test('when it edits and reopens the file offline, then the outbox '
        'survives and is sent after reconnecting', () async {
      final (a, sa, pa) = await created();
      final tab = sa.tabId;
      a.online = false;
      a.edit(sa, pa, setCell(pa.model, rows[0], 3, 'offline'));
      await sa.whenStored();
      await a.closeFile(sa);
      expect(hub.file(docId).head, 1);

      // Reopened (same tab) while still offline: cache + outbox.
      final (sa2, pa2, _) = await a.openFile(docId, tabId: tab);
      expect(pa2.cell(rows[0], 3), 'offline');
      expect(sa2.core.pendingChanges, greaterThan(0));

      a.online = true;
      await sa2.whenSynced(timeout: const Duration(seconds: 5));
      expect(hub.file(docId).head, 2);
      final b = await Device.open(hub, bo);
      final (_, pb, plan) = await b.openFile(docId);
      await plan.isComplete.future.timeout(const Duration(seconds: 5));
      expect(pb.cell(rows[0], 3), 'offline');
    });

    test('when a collaborator deletes the row it edited offline, then the '
        'edit is dropped and both converge', () async {
      final (a, sa, pa) = await created();
      final b = await Device.open(hub, bo);
      final (sb, pb, plan) = await b.openFile(docId);
      await plan.isComplete.future.timeout(const Duration(seconds: 5));

      a.online = false;
      a.edit(sa, pa, setCell(pa.model, rows[1], 0, 'lost'));
      final row = pb.model.currentColumns('row', rows[1])!;
      b.edit(sb, pb, [
        RowChange.delete('row', rows[1], {
          for (final e in row.entries)
            if (e.key != 'id') e.key: e.value,
        }),
      ]);
      await sb.whenSynced(timeout: const Duration(seconds: 5));

      final outcomes = <RevOutcome>[];
      final sub = sa.outcomes.listen(outcomes.add);
      addTearDown(sub.cancel);
      a.online = true;
      await sa.whenSynced(timeout: const Duration(seconds: 5));
      await eventually(() => pa.model.currentColumns('row', rows[1]) == null);
      expect(pa.cell(rows[1], 0), isNull);
      expect(pa.snapshot, pb.snapshot);
      expect(outcomes.single.json['dropped'], isNotEmpty);
      expect(outcomes.single.offline, isTrue);
    });
  });

  group('Given a viewer', () {
    test('when they edit, then the group is rejected and the model rolls '
        'back', () async {
      final (_, _, pa) = await created();
      hub.setRole(bo, docId, AccessRole.viewer);
      final b = await Device.open(hub, bo);
      final (sb, pb, plan) = await b.openFile(docId);
      await plan.isComplete.future.timeout(const Duration(seconds: 5));
      final rejected = <RevGroupRejection>[];
      final sub = sb.rejections.listen(rejected.add);
      addTearDown(sub.cancel);

      b.edit(sb, pb, setCell(pb.model, rows[0], 0, 'nope'));
      expect(pb.cell(rows[0], 0), 'nope');
      await eventually(() => rejected.isNotEmpty);
      expect(
        rejected.single.rejection.reason,
        RevRejectReason.forbiddenForRole,
      );
      expect(pb.cell(rows[0], 0), isNull);
      expect(pb.snapshot, pa.snapshot);
      expect(sb.role.value, AccessRole.viewer);
    });
  });
}
