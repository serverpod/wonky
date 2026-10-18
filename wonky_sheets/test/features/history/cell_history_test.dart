import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart'
    show RevertResult, RevertSkip, UuidValue;
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart' show RevOpMeta;
import 'package:wonky_sheets/features/history/cell_history.dart';
import 'package:wonky_sheets/features/history/server_change_undo.dart';

import '../collab/support/collab_harness.dart';

final _user = UuidValue.fromString('00000000-0000-4000-8000-000000000001');
int _ids = 1;

RevOpMeta log({
  required DateTime at,
  String label = 'Typing',
  Map<String, Object?>? detail,
  Map<String, Object?>? summary,
}) => RevOpMeta(
  revision: _ids++,
  authorUuid: _user.uuid,
  actorKind: 'user',
  sessionId: 's',
  label: label,
  summary:
      summary ??
      {
        'kinds': ['values'],
      },
  detail: detail,
  committedAt: at,
);

void main() {
  group('Given a cell with local change log entries', () {
    late CollabHarness s;
    late CellHistoryTarget target;
    final now = DateTime.utc(2026, 10, 14, 12);

    setUp(() async {
      s = await CollabHarness.open();
      final (r, c) = s.ids('B2');
      target = CellHistoryTarget(s.sheetId, r, c);
    });
    tearDown(() => s.dispose());

    Map<String, Object?> cell(String? b, String? a, {String? col}) => {
      'cells': [
        {
          's': target.sheetId,
          'r': target.rowId,
          'c': col ?? target.colId,
          'b': b,
          'a': a,
        },
      ],
    };

    test('when parsed then only entries of the cell within 30 days are '
        'listed, bulk changes covering it included', () {
      final items = withClock(
        Clock.fixed(now),
        () => CellHistoryController.localItems(
          [
            log(
              at: now.subtract(const Duration(hours: 2)),
              detail: cell(null, 's:A'),
            ),
            log(
              at: now.subtract(const Duration(hours: 1)),
              detail: cell('s:A', 's:B'),
              label: 'Paste',
            ),
            log(
              at: now,
              detail: cell(null, 'n:1', col: 'other'),
            ),
            log(
              at: now.subtract(const Duration(days: 40)),
              detail: cell(null, 's:old'),
            ),
            log(
              at: now.subtract(const Duration(minutes: 5)),
              label: 'Fill down',
              summary: {
                'kinds': ['values'],
                'ranges': [
                  {
                    's': target.sheetId,
                    'r1': target.rowId,
                    'r2': target.rowId,
                    'c1': target.colId,
                    'c2': target.colId,
                  },
                ],
              },
            ),
          ],
          target,
          s.model,
        ),
      );
      final merged = CellHistoryController.merge(items, const []);
      expect(merged.map((e) => e.label), ['Fill down', 'Paste', 'Typing']);
      expect(merged.first.bulk, isTrue);
      expect((merged[1].before, merged[1].after), ('s:A', 's:B'));
    });

    test('when local and server entries overlap then they are merged by id, '
        'newest first', () {
      final a = CellHistoryItem(
        changeLogId: '1',
        at: now,
        actorKind: 'user',
        label: 'Typing',
        before: 's:x',
        after: 's:y',
      );
      final b = CellHistoryItem(
        changeLogId: '2',
        at: now.subtract(const Duration(days: 60)),
        actorKind: 'user',
        label: 'Typing',
      );
      final merged = CellHistoryController.merge([a], [a, b]);
      expect(merged.map((e) => e.changeLogId), ['1', '2']);
    });

    test(
      'when a previous value is restored then it is one undo step',
      () async {
        await s.type('B2', 'new');
        final r = await s.run('sheets.history.restoreCellValue', {
          'sheetId': target.sheetId,
          'rowId': target.rowId,
          'colId': target.colId,
          'changeLogId': 'x',
          'content': 's:old',
        });
        expect(r.isOk, isTrue);
        expect(s.text('B2'), 'old');
        await s.h.undo();
        expect(s.text('B2'), 'new');
      },
    );

    test('when showing the edit history then the popover controller targets '
        'the active cell', () async {
      await s.select('B2');
      final r = await s.run('sheets.history.showCellHistory');
      expect(r.isOk, isTrue);
      expect(s.collab.cellHistory.value?.target, target);
      await s.select('C3');
      expect(s.collab.cellHistory.value, isNull);
    });
  });

  group('Given a server-side change on the undo stack', () {
    test('when undone and redone then the latest record is reverted each '
        'time and skipped columns show the partial toast', () async {
      final s = await CollabHarness.open();
      addTearDown(s.dispose);
      final calls = <String>[];
      var n = 0;
      final handler = SheetsServerChangeHandler(
        s.services,
        revert: (id) async {
          calls.add(id);
          n++;
          return RevertResult(
            changeId: UuidValue.fromString(
              '00000000-0000-7000-8000-00000000000$n',
            ),
            revertedCells: 1,
            skipped: n == 1
                ? [
                    RevertSkip(
                      table: 'cell',
                      rowId: UuidValue.fromString(
                        '00000000-0000-7000-8000-0000000000ff',
                      ),
                      column: 'content',
                      reason: 'changed_by_other',
                    ),
                  ]
                : const [],
          );
        },
      );
      const e = SheetsServerChangeEntry(
        changeId: '00000000-0000-7000-8000-000000000000',
      );
      final undone = await handler.undo(e);
      final redone = await handler.redo(undone);
      expect(calls, [e.changeId, undone.changeId]);
      expect(redone.changeId, '00000000-0000-7000-8000-000000000002');
      expect(
        SheetsServerChangeEntry.fromJson(redone.toJson())?.changeId,
        redone.changeId,
      );
    });
  });
}
