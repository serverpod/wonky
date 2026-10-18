import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';

import '../support/harness.dart';

/// Reopening a complete cache viewport-first (RevLog spec 06 §5.1, 17 As
/// built 24): the structure and the first rows' cells before ready, the
/// rest streamed in from the cache, exact like bootstrap pages (06 §5.3).
void main() {
  late FakeRevHub hub;
  final rows = [for (var i = 0; i < 30; i++) newId()];
  const wait = Duration(seconds: 10);

  setUp(() => hub = FakeRevHub(testSchema));

  /// Anna creates the file: 30 rows with a cell `v<i>` in column 0 of each.
  Future<(Device, RevFileSync, MapPort)> created() async {
    final a = await Device.open(hub, anna);
    final (sync, port, _) = await a.openFile(docId);
    a.edit(sync, port, creation(rows));
    for (var i = 0; i < rows.length; i++) {
      a.edit(sync, port, setCell(port.model, rows[i], 0, 'v$i'));
    }
    await sync.whenSynced(timeout: wait);
    return (a, sync, port);
  }

  /// Bo opens the file and loads all of it (his cache is complete).
  Future<(Device, RevFileSync, MapPort)> loadedByBo() async {
    final b = await Device.open(hub, bo);
    final (sync, port, plan) = await b.openFile(docId);
    await plan.isComplete.future.timeout(wait);
    await sync.whenStored();
    expect((await b.store.loadFile(docId))!.complete, isTrue);
    return (b, sync, port);
  }

  RowChange deleteCell(MapPort port, String row, int col) {
    final cur = port.model.currentColumns('cell', cellId(row, col))!;
    return RowChange.delete('cell', cellId(row, col), {
      for (final e in cur.entries)
        if (e.key != RowChange.idColumn) e.key: e.value,
    });
  }

  group('Given a complete cache reopened viewport-first', () {
    test('when the outbox inserts, updates and deletes cells in rows the '
        'viewport does not load, then they show server state plus the '
        'outbox once loaded, and the edits sync', () async {
      final (_, _, pa) = await created();
      final (b, sb, pb) = await loadedByBo();
      final tab = sb.tabId;
      b.online = false;
      b.edit(sb, pb, setCell(pb.model, rows[25], 1, 'new'));
      b.edit(sb, pb, setCell(pb.model, rows[26], 0, 'mine'));
      b.edit(sb, pb, [deleteCell(pb, rows[27], 0)]);
      await b.closeFile(sb);

      // Reopened offline: row 0 before ready, then one row per block.
      late RevFileSync sb2;
      final atReady = <String, String?>{};
      final plan = RowBlocksPlan(
        rows,
        onReady: () {
          final port = sb2.port as MapPort;
          atReady['0'] = port.cell(rows[0], 0);
          atReady['5'] = port.cell(rows[5], 0);
          atReady['25/1'] = port.cell(rows[25], 1);
        },
      );
      final (_, pb2) = await b.openWith(
        docId,
        plan,
        tabId: tab,
        beforeOpen: (s) => sb2 = s,
      );
      expect(atReady, {'0': 'v0', '5': null, '25/1': 'new'});

      await plan.isComplete.future.timeout(wait);
      expect(plan.loaded, rows);
      expect(pb2.cell(rows[5], 0), 'v5');
      expect(pb2.cell(rows[25], 0), 'v25');
      expect(pb2.cell(rows[25], 1), 'new');
      expect(pb2.cell(rows[26], 0), 'mine');
      expect(pb2.cell(rows[27], 0), isNull);
      expect(sb2.core.pendingChanges, 3);

      b.online = true;
      await sb2.whenSynced(timeout: wait);
      await eventually(() => pa.cell(rows[26], 0) == 'mine');
      expect(pa.snapshot, pb2.snapshot);
    });

    test('when a collaborator\'s op arrives after a row was read from the '
        'cache but before it is applied, then the row shows the op', () async {
      final (a, sa, pa) = await created();
      final (b, sb, _) = await loadedByBo();
      await b.closeFile(sb);

      late RevFileSync sb2;
      var raced = false;
      final plan = RowBlocksPlan(rows);
      final (_, pb2) = await b.openWith(
        docId,
        plan,
        beforeOpen: (s) {
          sb2 = s;
          s.cachedCellsRead = (scope, keys) async {
            if (!keys.contains(rows[20])) return;
            // Row 20 is read (server state before the op); the op reaches
            // the model and the store before the row is applied.
            a.edit(sa, pa, [
              ...setCell(pa.model, rows[20], 0, 'anna'),
              ...setCell(pa.model, rows[20], 2, 'anna2'),
              deleteCell(pa, rows[21], 0),
            ]);
            await sa.whenSynced(timeout: wait);
            final head = hub.file(docId).head;
            await eventually(() => sb2.core.serverRevision == head);
            await sb2.whenStored();
            raced = true;
          };
        },
      );

      await plan.isComplete.future.timeout(wait);
      expect(raced, isTrue);
      expect(pb2.cell(rows[20], 0), 'anna');
      expect(pb2.cell(rows[20], 2), 'anna2');
      expect(pb2.cell(rows[21], 0), isNull);
      expect(pb2.snapshot, pa.snapshot);
    });

    test('when collaborators edit while the cells stream in, then the model '
        'converges to the server state', () async {
      final (a, sa, pa) = await created();
      final (b, sb, _) = await loadedByBo();
      await b.closeFile(sb);
      // Caught up at connect: edits made while Bo was away.
      a.edit(sa, pa, [
        for (var i = 15; i < 30; i++) ...setCell(pa.model, rows[i], 0, 'away'),
      ]);
      await sa.whenSynced(timeout: wait);

      final plan = RowBlocksPlan(rows, viewport: 2);
      final (sb2, pb2) = await b.openWith(
        docId,
        plan,
        beforeOpen: (s) => s.cachedCellsRead = (scope, keys) async {
          // Live edits while streaming, in every third block.
          final i = plan.loaded.length;
          if (i % 3 != 0) return;
          a.edit(sa, pa, [
            for (var r = i; r < rows.length; r += 4)
              ...setCell(pa.model, rows[r], 1, 'live$i'),
            if (i + 1 < rows.length)
              ...setCell(pa.model, rows[i + 1], 0, 'next$i'),
          ]);
        },
      );
      // Bo types into a loaded row meanwhile.
      b.edit(sb2, pb2, setCell(pb2.model, rows[0], 3, 'bo'));

      await plan.isComplete.future.timeout(wait);
      await sa.whenSynced(timeout: wait);
      await sb2.whenSynced(timeout: wait);
      final head = hub.file(docId).head;
      await eventually(
        () => sa.core.serverRevision == head && sb2.core.serverRevision == head,
      );
      expect(pb2.cell(rows[0], 3), 'bo');
      expect(pb2.cell(rows[16], 0), isNot('v16'));
      expect(pb2.snapshot, pa.snapshot);
    });

    test('when it edits a cell offline that a collaborator also changed, '
        'then the later arrival (its own) wins on both sides', () async {
      final (a, sa, pa) = await created();
      final (b, sb, pb) = await loadedByBo();
      final tab = sb.tabId;
      b.online = false;
      b.edit(sb, pb, setCell(pb.model, rows[22], 0, 'bo'));
      await b.closeFile(sb);
      a.edit(sa, pa, setCell(pa.model, rows[22], 0, 'anna'));
      await sa.whenSynced(timeout: wait);

      final plan = RowBlocksPlan(rows);
      final (sb2, pb2) = await b.openWith(docId, plan, tabId: tab);
      b.online = true;
      await plan.isComplete.future.timeout(wait);
      await sb2.whenSynced(timeout: wait);
      await eventually(() => pa.cell(rows[22], 0) == 'bo');
      expect(pb2.cell(rows[22], 0), 'bo');
      expect(pb2.snapshot, pa.snapshot);
    });
  });

  group('Given a cache reset by a new schema', () {
    test('when the file is reopened, then it loads from the server with the '
        'outbox on top and the outbox is sent', () async {
      final (_, _, pa) = await created();
      final (b, sb, pb) = await loadedByBo();
      final tab = sb.tabId;
      b.online = false;
      b.edit(sb, pb, setCell(pb.model, rows[3], 1, 'kept'));
      await b.closeFile(sb);
      await b.store.db.execute(
        "UPDATE rev_meta SET value = 'older' WHERE key = 'schemaHash'",
      );
      await b.close();

      final b2 = await Device.open(hub, bo, dir: b.directory);
      final local = (await b2.store.loadFile(docId))!;
      expect(local.revision, 0);
      expect(local.complete, isFalse);
      final plan = RowBlocksPlan(rows);
      final (s2, p2) = await b2.openWith(docId, plan, tabId: tab);
      await plan.isComplete.future.timeout(wait);
      await s2.whenSynced(timeout: wait);
      expect(p2.cell(rows[3], 1), 'kept');
      expect(p2.cell(rows[9], 0), 'v9');
      await eventually(() => pa.cell(rows[3], 1) == 'kept');
      expect(pa.snapshot, p2.snapshot);
    });
  });
}
