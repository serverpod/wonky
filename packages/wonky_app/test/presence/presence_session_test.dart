import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show PresenceActivity;

import '../support/fake_collab.dart';

void main() {
  final item = UuidValue.fromString('0199f000-0000-7000-8000-0000000000aa');
  late FakePresenceRepository repo;
  late CommandTestHarness h;

  setUp(() {
    repo = FakePresenceRepository();
    h = CommandTestHarness(presence: repo);
  });
  tearDown(() => h.dispose());

  /// Starts a session and lets the first update go out.
  Future<PresenceSession> start(WidgetTester tester, {String? mode}) async {
    final s = PresenceSession(services: h.services, itemUuid: item, mode: mode)
      ..start();
    // The first update goes out on a zero-length timer after connecting.
    await tester.pump(const Duration(milliseconds: 1));
    return s;
  }

  /// A roster with this window (`me`) and Bob (`bob`).
  void roster() => repo.server.add(
    PresenceRoster(
      sessionId: 'me',
      participants: [
        participant('me'),
        participant('bob', user: TestUsers.bob),
      ],
    ),
  );

  List<PresenceState> sentStates() => [for (final u in repo.updates) u.state];

  group('Given a started presence session', () {
    testWidgets('when it connects then it joins the file and sends its '
        'state and mode', (tester) async {
      final s = await start(tester, mode: 'editing');

      expect(s.isStarted, isTrue);
      expect(repo.joinedItems, [item]);
      expect(h.services.supervisor.isActive('presence:${item.uuid}'), isTrue);
      expect(repo.updates.single.state, PresenceState.active);
      expect(repo.updates.single.mode, 'editing');
      s.dispose();
    });

    testWidgets('when the roster arrives then the participants are listed '
        'and this window is marked as self', (tester) async {
      final s = await start(tester);
      var notified = 0;
      s.addListener(() => notified++);

      roster();
      await tester.pump();

      expect(s.sessionId, 'me');
      expect(s.participants.map((p) => p.sessionId), ['me', 'bob']);
      expect(notified, 1);
      expect(
        [for (final a in s.avatars()) (a.displayName, a.isSelf)],
        [('Anna Berg', true), ('Bob Stone', false)],
      );
      s.dispose();
    });

    testWidgets('when someone joins, says hello again and leaves then the '
        'roster follows without duplicates', (tester) async {
      final s = await start(tester);
      roster();
      final agent = participant(
        'agent',
        user: TestUsers.bob,
        actorKind: ActorKind.mcp,
      );

      repo.server
        ..add(PresenceJoined(participant: agent))
        ..add(
          PresenceJoined(participant: agent.copyWith(cursorJson: '{"x":1}')),
        );
      await tester.pump();
      expect(s.participants.map((p) => p.sessionId), ['me', 'bob', 'agent']);
      expect(s.participants.last.cursorJson, '{"x":1}');
      expect(s.avatars().last.isAgent, isTrue);

      repo.server.add(PresenceLeft(sessionId: 'bob'));
      await tester.pump();

      expect(s.participants.map((p) => p.sessionId), ['me', 'agent']);
      s.dispose();
    });

    testWidgets('when a participant updates then its state, cursor and mode '
        'show in the avatars', (tester) async {
      final s = await start(tester);
      roster();

      repo.server
        ..add(
          PresenceUpdated(
            sessionId: 'bob',
            state: PresenceState.active,
            mode: 'viewing',
            cursorJson: '{"cell":"B4"}',
          ),
        )
        ..add(PresenceUpdated(sessionId: 'me', state: PresenceState.idle));
      await tester.pump();

      expect(s.participants.last.cursorJson, '{"cell":"B4"}');
      expect(
        [for (final a in s.avatars()) a.activity],
        [PresenceActivity.idle, PresenceActivity.viewing],
      );
      s.dispose();
    });

    testWidgets('when hints, notices and follower counts arrive then they '
        'are relayed', (tester) async {
      final s = await start(tester);
      final hints = <PresenceHints>[];
      final notices = <PresenceNotice>[];
      s.hints.listen(hints.add);
      s.notices.listen(notices.add);
      var notified = 0;
      s.addListener(() => notified++);

      repo.server
        ..add(PresenceHints(sessionId: 'bob', hints: ['{"row":3}']))
        ..add(PresenceNotice(kind: 'restored', payloadJson: '{}'))
        ..add(PresenceFollowerCount(count: 2));
      await tester.pump();

      expect(hints.single.hints, ['{"row":3}']);
      expect(notices.single.kind, 'restored');
      expect(s.followerCount, 2);
      expect(notified, 1, reason: 'hints and notices do not notify');
      s.dispose();
    });

    testWidgets('when hints are sent then they go out unthrottled with the '
        'current state', (tester) async {
      final s = await start(tester);

      s
        ..sendHints(['{"a":1}'])
        ..sendHints(['{"a":2}'])
        ..sendHints(const []);
      await tester.pump();

      expect(
        [for (final u in repo.updates.skip(1)) u.hints],
        [
          ['{"a":1}'],
          ['{"a":2}'],
        ],
      );
      s.dispose();
    });

    testWidgets('when following a session then the update names it and '
        'listeners are told; following it again sends nothing', (tester) async {
      final s = await start(tester);
      var notified = 0;
      s.addListener(() => notified++);

      s
        ..follow('bob')
        ..follow('bob');
      await tester.pump();

      expect(s.following, 'bob');
      expect(repo.updates, hasLength(2));
      expect(repo.updates.last.followingSessionId, 'bob');
      expect(notified, 1);
      s.dispose();
    });
  });

  group('Given an active session', () {
    testWidgets('when there is no input for 60 s then it turns idle, and '
        'input makes it active again', (tester) async {
      final s = await start(tester);

      await tester.pump(const Duration(seconds: 59));
      expect(sentStates(), [PresenceState.active]);
      await tester.pump(const Duration(seconds: 1));
      expect(sentStates(), [PresenceState.active, PresenceState.idle]);

      s.activity();
      await tester.pump();

      expect(sentStates(), [
        PresenceState.active,
        PresenceState.idle,
        PresenceState.active,
      ]);
      s.dispose();
    });

    testWidgets('when there is input before 60 s then it stays active', (
      tester,
    ) async {
      final s = await start(tester);

      await tester.pump(const Duration(seconds: 50));
      s.activity();
      await tester.pump(const Duration(seconds: 50));

      expect(sentStates(), [PresenceState.active]);
      s.dispose();
    });

    testWidgets('when the cursor moves quickly then updates are throttled to '
        'one now and the latest one 100 ms later', (tester) async {
      final s = await start(tester);

      s
        ..updateCursor('{"c":1}')
        ..updateCursor('{"c":2}')
        ..updateCursor('{"c":3}');
      await tester.pump(const Duration(milliseconds: 99));
      expect([for (final u in repo.updates.skip(1)) u.cursorJson], ['{"c":1}']);
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        [for (final u in repo.updates.skip(1)) u.cursorJson],
        ['{"c":1}', '{"c":3}'],
      );
      s.dispose();
    });

    testWidgets('when the mode changes then the new mode is sent', (
      tester,
    ) async {
      final s = await start(tester, mode: 'editing');

      s.setMode('viewing');
      await tester.pump();

      expect(repo.updates.last.mode, 'viewing');
      expect(s.mode, 'viewing');
      s.dispose();
    });

    testWidgets('when the app is hidden and resumed then it is away and then '
        'active again', (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      final s = await start(tester);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(sentStates(), [PresenceState.active, PresenceState.away]);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(sentStates(), [
        PresenceState.active,
        PresenceState.away,
        PresenceState.active,
      ]);
      s.dispose();
    });

    testWidgets('when the presence stream drops then it rejoins and resends '
        'its current state', (tester) async {
      final s = await start(tester);
      s.follow('bob');

      unawaited(repo.server.close());
      await tester.pump();
      // The supervisor's first retry: 1 s ± 20 % jitter.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 1));

      expect(repo.joins, hasLength(2));
      expect(repo.updates.last.followingSessionId, 'bob');
      expect(repo.updates.last.state, PresenceState.active);
      s.dispose();
    });
  });

  group('Given a session that is disposed', () {
    testWidgets('when disposed then it leaves the file and stops sending', (
      tester,
    ) async {
      final s = await start(tester);
      final sent = repo.updates.length;

      s.dispose();
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      s
        ..updateCursor('{"c":1}')
        ..sendHints(['{"a":1}']);
      await tester.pump(const Duration(seconds: 61));

      expect(repo.left, isTrue);
      expect(s.isStarted, isFalse);
      expect(h.services.supervisor.isActive('presence:${item.uuid}'), isFalse);
      expect(repo.updates, hasLength(sent));
    });

    testWidgets('when started again then nothing joins', (tester) async {
      final s = await start(tester);
      s.dispose();

      s.start();
      await tester.pump();

      expect(repo.joins, hasLength(1));
    });
  });
}
