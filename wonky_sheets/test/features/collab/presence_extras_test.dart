import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart'
    show ActorKind, PresenceHints, PresenceRoster;
import 'package:wonky_sheets/features/collab/presence/presence_cursor.dart';

import 'support/collab_harness.dart';

void main() {
  group('Given a collaborator editing B4', () {
    late CollabHarness s;

    Future<void> roster({bool editing = true}) async {
      final (r, c) = s.ids('B4');
      s.presenceRepo.emit(
        PresenceRoster(
          sessionId: 'me',
          participants: [
            participant('me', userId: 1, name: 'Anna'),
            participant(
              'bo',
              cursorJson: SheetsPresenceCursor(
                sheetId: s.sheetId,
                activeRowId: r,
                activeColId: c,
                editing: editing,
              ).encode(),
            ),
          ],
        ),
      );
      await pumpEventQueue();
    }

    setUp(() async => s = await CollabHarness.open());
    tearDown(() => s.dispose());

    test('when they edit then their border marches, and stops when they '
        'commit', () async {
      await roster();
      expect(s.collab.presence.marching, isTrue);
      final before = s.collab.presence.marchPhase;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(s.collab.presence.marchPhase, isNot(before));

      await roster(editing: false);
      expect(s.collab.presence.marching, isFalse);
    });

    test('when their cell is hovered then their name flag shows after the '
        '3 s window', () async {
      await roster(editing: false);
      final c = s.collab.presence.cursorOf('bo')!;
      final later = clock.now().add(const Duration(seconds: 10));
      expect(s.collab.presence.flagVisible(c, later), isFalse);

      s.collab.presence.setHover(s.sheetId, 3, 1);
      expect(s.collab.presence.flagVisible(c, later), isTrue);
      s.collab.presence.setHover(s.sheetId, 3, 2);
      expect(s.collab.presence.flagVisible(c, later), isFalse);
      s.collab.presence.setHover(null, 0, 0);
      expect(s.collab.presence.flagVisible(c, later), isFalse);
    });

    test('when a typing hint arrives then the preview shows their text until '
        'they stop editing', () async {
      await roster();
      final (r, c) = s.ids('B4');
      s.collab.hints.receive(
        PresenceHints(
          sessionId: 'bo',
          hints: [
            jsonEncode({
              't': 'typing',
              'sheetId': s.sheetId,
              'rowId': r,
              'colId': c,
              'text': 'Hel',
            }),
          ],
        ),
      );
      final cursor = s.collab.presence.cursorOf('bo')!;
      expect(s.collab.presence.typingOf(cursor, clock.now())?.text, 'Hel');

      await roster(editing: false);
      final after = s.collab.presence.cursorOf('bo')!;
      expect(s.collab.presence.typingOf(after, clock.now()), isNull);
      expect(s.collab.presence.typing, isEmpty);
    });

    test('when an agent participant writes then its flag reads "Claude via '
        'MCP (name)"', () async {
      await roster(editing: false);
      final p = participant(
        'agent-1',
        name: 'Anna Berg',
      ).copyWith(actorKind: ActorKind.mcp);
      expect(s.collab.participantLabel(p), 'Claude via MCP (Anna Berg)');
      expect(
        s.collab.participantLabel(p.copyWith(actorKind: ActorKind.ai)),
        'Assistant (Anna Berg)',
      );
    });
  });

  group('Given the local cell editor', () {
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

    test('when typing then the in-progress text is sent as a typing hint '
        '(throttled)', () async {
      await s.select('C3');
      s.editor.editor.begin(initialText: 'H');
      s.editor.editor.text.text = 'He';
      s.editor.editor.text.text = 'Hel';
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final typing = [
        for (final u in s.presenceRepo.updates)
          for (final h in u.hints ?? const <String>[])
            if ((jsonDecode(h) as Map)['t'] == 'typing') jsonDecode(h) as Map,
      ];
      expect(typing, isNotEmpty);
      expect(typing.last['text'], 'Hel');
      final (r, c) = s.ids('C3');
      expect((typing.last['rowId'], typing.last['colId']), (r, c));
      // Throttled to 4/s: fewer messages than edits.
      expect(typing.length, lessThanOrEqualTo(2));
    });
  });
}
