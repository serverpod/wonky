import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart'
    show PresenceHints, PresenceRoster;
import 'package:wonky_sheets/features/collab/hints/commit_hints.dart';
import 'package:wonky_sheets_core/model.dart';

import 'support/collab_harness.dart';

/// Commit hints (Sheets 10 §2): typing previews and the `pending` shimmer of
/// big commits; committed values arrive as ops (no per-cell hints).
void main() {
  group('Given an open spreadsheet with commit hints', () {
    late CollabHarness s;

    setUp(() async {
      s = await CollabHarness.open();
      s.presenceRepo.emit(
        PresenceRoster(
          sessionId: 'me',
          participants: [
            participant('me', userId: 1, name: 'Anna'),
            participant('bo'),
          ],
        ),
      );
      await pumpEventQueue();
    });
    tearDown(() => s.dispose());

    List<Map<String, Object?>> sentHints() => [
      for (final h in s.presenceRepo.updates.expand(
        (u) => u.hints ?? const <String>[],
      ))
        (jsonDecode(h) as Map).cast<String, Object?>(),
    ];

    String pendingHint() {
      final (r1, c1) = s.ids('A1');
      final (r2, c2) = s.ids('B5');
      return jsonEncode({
        't': 'pending',
        'sheetId': s.sheetId,
        'range': {'r1': r1, 'c1': c1, 'r2': r2, 'c2': c2},
        'hlcMillis': 1,
      });
    }

    test('when a cell is committed then no value hint is sent', () async {
      await s.type('B2', '42');
      await Future<void>.delayed(Duration.zero);
      expect(sentHints().where((h) => h['t'] != 'typing'), isEmpty);
    });

    test('when more than 500 cells are committed then a pending hint covers '
        'their range', () async {
      s.session.execute(
        SetCellInputs(
          sheetId: s.sheetId,
          row: 0,
          col: 0,
          inputs: [
            for (var r = 0; r < 26; r++)
              [for (var c = 0; c < 20; c++) CellInput.user('$r')],
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      final h = sentHints().singleWhere((h) => h['t'] == 'pending');
      final (r1, c1) = s.ids('A1');
      final (r2, c2) = s.ids('T26');
      expect(h['range'], {'r1': r1, 'c1': c1, 'r2': r2, 'c2': c2});
    });

    test('when a pending hint arrives then it shows until 5 s pass', () {
      final t0 = DateTime(2026, 10, 1, 12);
      withClock(Clock.fixed(t0), () {
        s.collab.hints.receive(
          PresenceHints(sessionId: 'bo', hints: [pendingHint()]),
        );
      });
      expect(s.collab.hints.pending, hasLength(1));
      withClock(
        Clock.fixed(t0.add(CommitHints.lifetime + const Duration(seconds: 1))),
        s.collab.hints.expire,
      );
      expect(s.collab.hints.pending, isEmpty);
    });

    test('when the sender leaves then their pending hint is dropped', () async {
      s.collab.hints.receive(
        PresenceHints(sessionId: 'bo', hints: [pendingHint()]),
      );
      expect(s.collab.hints.pending, hasLength(1));
      s.presenceRepo.emit(
        PresenceRoster(
          sessionId: 'me',
          participants: [participant('me', userId: 1, name: 'Anna')],
        ),
      );
      await pumpEventQueue();
      expect(s.collab.hints.pending, isEmpty);
    });

    test('when an old client sends a cell hint then it is ignored', () {
      final (r, c) = s.ids('C3');
      s.collab.hints.receive(
        PresenceHints(
          sessionId: 'bo',
          hints: [
            jsonEncode({
              't': 'cell',
              'sheetId': s.sheetId,
              'rowId': r,
              'colId': c,
              'content': 's:Hello',
            }),
          ],
        ),
      );
      expect(s.text('C3'), '');
      expect(s.collab.hints.pending, isEmpty);
    });
  });
}
