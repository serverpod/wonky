import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart' show PresenceRoster;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_sheets/features/history/local_conflicts.dart';
import 'package:wonky_sheets_core/model.dart' hide ActorKind;

import '../collab/support/collab_harness.dart';

/// Bo's auth uuid in the collab harness (`participant(userId: 2)`).
const boUuid = '00000000-0000-4000-8000-000000000002';

void main() {
  group('Given edits made offline', () {
    late CollabHarness s;
    late bool offline;
    late List<RevOpMeta> logs;
    late SheetsConflicts conflicts;

    /// A write by Bo that reached us through sync (not a local command).
    void remote(String a1, String input) {
      final r = s.model.parseA1(a1, contextSheetId: s.sheetId);
      final sheet = s.sheet;
      final before = sheet.cellAt(r.rect.top, r.rect.left)?.content;
      s.session.execute(
        SetCellInputs(
          sheetId: s.sheetId,
          row: r.rect.top,
          col: r.rect.left,
          inputs: [
            [CellInput.user(input)],
          ],
        ),
      );
      final after = sheet.cellAt(r.rect.top, r.rect.left)?.content;
      logs.add(
        RevOpMeta(
          revision: logs.length + 1,
          authorUuid: boUuid,
          actorKind: 'user',
          sessionId: 'bo',
          label: 'Edit',
          summary: ChangeSummary(sheets: {s.sheetId}).toJson(),
          detail: {
            'cells': [
              {
                's': s.sheetId,
                'r': sheet.rows.idAt(r.rect.top),
                'c': sheet.columns.idAt(r.rect.left),
                'b': before,
                'a': after,
              },
            ],
          },
          committedAt: clock.now().toUtc(),
        ),
      );
    }

    setUp(() async {
      s = await CollabHarness.open();
      s.presenceRepo.emit(
        PresenceRoster(
          sessionId: 'me',
          participants: [
            participant('me', userId: 1, name: 'Anna'),
            participant('bo', name: 'Bo Stone'),
          ],
        ),
      );
      await pumpEventQueue();
      offline = true;
      logs = [];
      conflicts = SheetsConflicts(
        s.editor,
        changeLogs: () async => logs,
        isOffline: () => offline,
        names: (u) => u == boUuid ? 'Bo Stone' : null,
      );
      await pumpEventQueue();
    });
    tearDown(() async {
      conflicts.dispose();
      await s.dispose();
    });

    test('when Bo overwrote one of them then a conflict lists my value, his '
        'value and him, and the toast offers the review', () async {
      await s.type('B2', 'Done');
      await s.type('B3', 'Kept');
      expect(conflicts.trackedCells, 2);
      offline = false;
      remote('B2', 'Pending');

      final found = await conflicts.check();
      expect(found, hasLength(1));
      final c = found.single;
      expect(c.kind, LocalConflictKind.overwritten);
      expect(c.myValue, 's:Done');
      expect(c.theirValue, 's:Pending');
      expect(c.theirName, 'Bo Stone');
      expect(c.label, 'Sheet1!B2');
      expect(conflicts.open, hasLength(1));
      expect(conflicts.trackedCells, 0);
      expect(
        s.editor.l10n.toastConflicts(1, 'Bo Stone'),
        '1 of your offline edits was replaced by a newer edit from Bo Stone',
      );
    });

    test('when an edit of mine wins later online then it is not a '
        'conflict', () async {
      await s.type('B2', 'Done');
      offline = false;
      remote('B2', 'Pending');
      await s.type('B2', 'Final');
      expect(await conflicts.check(), isEmpty);
    });

    test('when Bo sorted the same rows later then my sort is reported as '
        'replaced', () async {
      offline = false;
      await s.type('A1', '3');
      await s.type('A2', '1');
      await s.type('A3', '2');
      offline = true;
      final range = s.model.parseA1('A1:A3', contextSheetId: s.sheetId);
      final col = s.sheet.columns.idAt(0);
      s.editor.apply(null, SortRange(range, [SortKeySpec(col)]));
      offline = false;
      s.session.execute(SortRange(range, [SortKeySpec(col, ascending: false)]));
      logs.add(
        RevOpMeta(
          revision: logs.length + 1,
          authorUuid: boUuid,
          actorKind: 'user',
          sessionId: 'bo',
          label: 'Sort range',
          summary: ChangeSummary(sheets: {s.sheetId}).toJson(),
          committedAt: clock.now().toUtc(),
        ),
      );

      await conflicts.check();
      expect(conflicts.lastSortReplacedBy, 'Bo Stone');
    });

    test('when the row was deleted then the conflict says so and cannot be '
        'applied', () async {
      await s.type('B5', 'Gone soon');
      offline = false;
      final rowId = s.sheet.rows.idAt(4);
      s.session.execute(DeleteDimension(s.sheetId, Dimension.rows, [rowId]));
      logs.add(
        RevOpMeta(
          revision: logs.length + 1,
          authorUuid: boUuid,
          actorKind: 'user',
          sessionId: 'bo',
          label: 'Delete row',
          summary: (ChangeSummary()..addDeleted('rows', rowId)).toJson(),
          committedAt: clock.now().toUtc(),
        ),
      );
      final found = await conflicts.check();
      expect(found.single.kind, LocalConflictKind.rowDeleted);
      expect(found.single.canApply, isFalse);
      expect(found.single.theirName, 'Bo Stone');
    });
  });

  group('Given an overwritten offline edit in the collaboration features', () {
    late CollabHarness s;

    setUp(() async => s = await CollabHarness.open());
    tearDown(() => s.dispose());

    test('when Apply mine again runs then my value is written back as one '
        'undo step and the conflict is closed', () async {
      final conflicts = s.collab.conflicts;
      s.services.connectivity.forceOffline(true);
      await s.type('B2', 'Done');
      s.services.connectivity.forceOffline(false);
      final r = s.model.parseA1('B2', contextSheetId: s.sheetId);
      s.session.execute(
        SetCellInputs(
          sheetId: s.sheetId,
          row: r.rect.top,
          col: r.rect.left,
          inputs: [
            [CellInput.user('Pending')],
          ],
        ),
      );
      final found = await conflicts.check();
      expect(found, hasLength(1));
      expect(found.single.theirName, isNull); // no change log in memory

      final res = await s.run('sheets.conflicts.applyMine', {
        'conflictIds': [found.single.id],
      });
      expect(res.isOk, isTrue);
      expect(s.text('B2'), 'Done');
      expect(conflicts.open, isEmpty);

      await s.h.undo();
      expect(s.text('B2'), 'Pending');
    });
  });
}
