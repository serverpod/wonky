@Tags(['integration'])
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/cluster/cluster.dart';
import 'package:wonky_server/src/platform/cluster/cluster_bus.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/slides/present/presentation_service.dart';

import '../../support/streams.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// One joined client: its update sink and event queue.
class _Client {
  _Client(this.updates, this.events);

  final StreamController<PresentationUpdate> updates;
  final StreamQueue<PresentationEvent> events;

  Future<T> next<T extends PresentationEvent>() async =>
      await nextWhere(events, (e) => e is T) as T;

  Future<void> close() async {
    await updates.close();
    await events.cancel(immediate: true);
  }
}

PresentationState _state(int revision, String slideId, {int step = 0}) =>
    PresentationState(
      revision: revision,
      slideId: slideId,
      step: step,
      stepElapsedMs: 0,
      blank: 'none',
      picker: false,
      endScreen: false,
      timerRunning: true,
      timerElapsedMs: 1000,
    );

/// The presentation session (Slides 10 §6; SL-19): presenter + audience on
/// the same account, followers, commands, end, presenter grace, takeover.
void main() {
  withWonkyServerpod('Given a presentation', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView deck;

    setUp(() async {
      PresentationService.presenterGrace = const Duration(milliseconds: 200);
      PresentationService.joinTimeout = const Duration(milliseconds: 600);
      PresentationService.probeTimeout = const Duration(milliseconds: 150);
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      deck = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Q3 Review',
        null,
      );
    });

    tearDown(() {
      PresentationService.presenterGrace = const Duration(seconds: 30);
      PresentationService.joinTimeout = const Duration(seconds: 3);
      PresentationService.probeTimeout = const Duration(milliseconds: 400);
    });

    _Client connect(
      TestUser user,
      PresentationRole role, {
      String? sessionId,
      bool? takeOver,
      String device = 'Laptop',
    }) {
      final updates = StreamController<PresentationUpdate>();
      final events = StreamQueue(
        endpoints.presentation.join(
          user.endpointSession,
          deck.uuid,
          PresentationJoin(
            sessionId: sessionId,
            role: role,
            deviceLabel: device,
            takeOver: takeOver,
          ),
          updates.stream,
        ),
      );
      return _Client(updates, events);
    }

    test('when the presenter starts then a new base-62 session is created '
        'and found for the same account only', () async {
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();

      expect(welcome.sessionId, matches(RegExp(r'^[0-9A-Za-z]{22}$')));
      expect(welcome.role, PresentationRole.presenter);
      expect(welcome.presenterConnected, isTrue);
      expect(welcome.state, isNull);

      final found = await endpoints.presentation.findSession(
        anna.endpointSession,
        deck.uuid,
      );
      expect(found?.sessionId, welcome.sessionId);
      expect(found?.deviceLabel, 'Laptop');

      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await TestDrive.share(endpoints, deck, anna, bo, AccessRole.viewer);
      expect(
        await endpoints.presentation.findSession(bo.endpointSession, deck.uuid),
        isNull,
      );
      await presenter.close();
    });

    test('when an audience device of the same account joins then it gets '
        'the state, follows state, laser and ink, and its commands reach '
        'the presenter', () async {
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();
      presenter.updates.add(PresentationStateUpdate(state: _state(1, 's1')));

      final audience = connect(
        anna,
        PresentationRole.audience,
        sessionId: welcome.sessionId,
        device: 'Projector',
      );
      final joined = await audience.next<PresentationWelcome>();
      final roster = await presenter.next<PresentationRosterEvent>();

      expect(joined.role, PresentationRole.audience);
      expect(joined.presenterConnected, isTrue);
      expect(joined.presenterDevice, 'Laptop');
      expect(joined.state?.slideId, 's1');
      expect(joined.stateSentAtMs, isNotNull);
      expect(roster.participants.single.deviceLabel, 'Projector');

      presenter.updates.add(
        PresentationStateUpdate(state: _state(2, 's2', step: 1)),
      );
      final state = await audience.next<PresentationStateEvent>();
      expect(state.state.slideId, 's2');
      expect(state.state.step, 1);

      presenter.updates.add(
        PresentationLaserUpdate(slideId: 's2', x: 100, y: 200),
      );
      final laser = await audience.next<PresentationLaserEvent>();
      expect((laser.x, laser.y), (100.0, 200.0));

      presenter.updates.add(
        PresentationInkUpdate(
          slideId: 's2',
          op: 'add',
          strokeId: 'k1',
          strokeJson: '{"id":"k1"}',
        ),
      );
      final ink = await audience.next<PresentationInkEvent>();
      expect((ink.op, ink.strokeId), ('add', 'k1'));

      audience.updates.add(PresentationCommandUpdate(command: 'next'));
      final command = await presenter.next<PresentationCommandEvent>();
      expect(command.command, 'next');
      expect(command.fromConnectionId, joined.connectionId);

      await audience.close();
      final left = await presenter.next<PresentationRosterEvent>();
      expect(left.participants, isEmpty);
      await presenter.close();
    });

    test(
      'when the presenter ends then the audience is told and closed',
      () async {
        final presenter = connect(anna, PresentationRole.presenter);
        final welcome = await presenter.next<PresentationWelcome>();
        final audience = connect(
          anna,
          PresentationRole.audience,
          sessionId: welcome.sessionId,
        );
        await audience.next<PresentationWelcome>();

        presenter.updates.add(PresentationEndUpdate());
        final ended = await audience.next<PresentationEndedEvent>();

        expect(ended.reason, 'ended');
        expect(await audience.events.hasNext, isFalse);
        await presenter.close();
        await audience.close();
      },
    );

    test('when another account joins as audience then it is refused, but a '
        'viewer may follow without controlling', () async {
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
      await TestDrive.share(endpoints, deck, anna, bo, AccessRole.viewer);
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();

      final boAudience = connect(
        bo,
        PresentationRole.audience,
        sessionId: welcome.sessionId,
      );
      await expectLater(
        boAudience.events.next,
        throwsA(isA<WonkyException>()),
      );

      final eveFollower = connect(
        eve,
        PresentationRole.follower,
        sessionId: welcome.sessionId,
      );
      await expectLater(
        eveFollower.events.next,
        throwsA(isA<WonkyException>()),
      );

      final follower = connect(
        bo,
        PresentationRole.follower,
        sessionId: welcome.sessionId,
      );
      await follower.next<PresentationWelcome>();
      await presenter.next<PresentationRosterEvent>();
      follower.updates.add(PresentationCommandUpdate(command: 'next'));
      presenter.updates.add(PresentationStateUpdate(state: _state(1, 's1')));
      await follower.next<PresentationStateEvent>();
      // The follower's command was dropped: nothing reached the presenter.
      final none = await presenter.events.hasNext.timeout(
        const Duration(milliseconds: 150),
        onTimeout: () => false,
      );
      expect(none, isFalse);
      await follower.close();
      await presenter.close();
      await boAudience.close();
      await eveFollower.close();
    });

    test('when a follower loses access then the next presenter state ends '
        'its session with noAccess', () async {
      PresentationService.memberAccessRecheck = Duration.zero;
      addTearDown(
        () => PresentationService.memberAccessRecheck = const Duration(
          seconds: 5,
        ),
      );
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await TestDrive.share(endpoints, deck, anna, bo, AccessRole.viewer);
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();
      final follower = connect(
        bo,
        PresentationRole.follower,
        sessionId: welcome.sessionId,
      );
      await follower.next<PresentationWelcome>();

      await endpoints.sharing.remove(anna.endpointSession, deck.uuid, bo.id);
      presenter.updates.add(PresentationStateUpdate(state: _state(1, 's1')));
      final ended = await follower.next<PresentationEndedEvent>();

      expect(ended.reason, 'noAccess');
      await follower.close();
      await presenter.close();
    });

    test(
      'when an unknown session is joined then it ends with notFound',
      () async {
        final audience = connect(
          anna,
          PresentationRole.audience,
          sessionId: PresentationService.newSessionId(),
        );
        final ended = await audience.next<PresentationEndedEvent>();
        expect(ended.reason, 'notFound');
        await audience.close();
      },
    );

    test('when the presenter drops then the audience waits, and the session '
        'expires after the grace period', () async {
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();
      final audience = connect(
        anna,
        PresentationRole.audience,
        sessionId: welcome.sessionId,
      );
      await audience.next<PresentationWelcome>();

      await presenter.close();
      final away = await audience.next<PresentationPresenterEvent>();
      final ended = await audience.next<PresentationEndedEvent>();

      expect(away.connected, isFalse);
      expect(ended.reason, 'expired');
      await audience.close();
    });

    test('when the presenter reconnects within the grace period then the '
        'audience keeps following', () async {
      PresentationService.presenterGrace = const Duration(seconds: 5);
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();
      presenter.updates.add(PresentationStateUpdate(state: _state(3, 's3')));
      final audience = connect(
        anna,
        PresentationRole.audience,
        sessionId: welcome.sessionId,
      );
      await audience.next<PresentationWelcome>();
      await presenter.close();
      await audience.next<PresentationPresenterEvent>();

      final again = connect(
        anna,
        PresentationRole.presenter,
        sessionId: welcome.sessionId,
      );
      final rejoined = await again.next<PresentationWelcome>();
      final back = await audience.next<PresentationPresenterEvent>();
      final roster = await again.next<PresentationRosterEvent>();

      expect(rejoined.sessionId, welcome.sessionId);
      expect(rejoined.state?.slideId, 's3');
      expect(back.connected, isTrue);
      expect(roster.participants, hasLength(1));
      again.updates.add(PresentationStateUpdate(state: _state(4, 's4')));
      final state = await audience.next<PresentationStateEvent>();
      expect(state.state.slideId, 's4');
      await again.close();
      await audience.close();
    });

    test('when a second presenter joins then it must take over, and the first '
        'is ended', () async {
      final first = connect(anna, PresentationRole.presenter);
      final welcome = await first.next<PresentationWelcome>();

      final second = connect(
        anna,
        PresentationRole.presenter,
        sessionId: welcome.sessionId,
      );
      final refused = await second.next<PresentationEndedEvent>();
      expect(refused.reason, 'presenterActive');

      final taker = connect(
        anna,
        PresentationRole.presenter,
        sessionId: welcome.sessionId,
        takeOver: true,
      );
      await taker.next<PresentationWelcome>();
      final ended = await first.next<PresentationEndedEvent>();
      expect(ended.reason, 'takenOver');

      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      await TestDrive.share(endpoints, deck, anna, bo, AccessRole.editor);
      final thief = connect(
        bo,
        PresentationRole.presenter,
        sessionId: welcome.sessionId,
        takeOver: true,
      );
      await expectLater(thief.events.next, throwsA(isA<WonkyException>()));
      await taker.close();
      await first.close();
      await second.close();
      await thief.close();
    });

    test('when an audience sends a burst of commands then at most 20 per '
        'second reach the presenter', () async {
      final presenter = connect(anna, PresentationRole.presenter);
      final welcome = await presenter.next<PresentationWelcome>();
      final audience = connect(
        anna,
        PresentationRole.audience,
        sessionId: welcome.sessionId,
      );
      await audience.next<PresentationWelcome>();
      await presenter.next<PresentationRosterEvent>();

      for (var i = 0; i < 30; i++) {
        audience.updates.add(PresentationCommandUpdate(command: 'next'));
      }
      var count = 0;
      while (await presenter.events.hasNext.timeout(
        const Duration(milliseconds: 200),
        onTimeout: () => false,
      )) {
        if (await presenter.events.next is PresentationCommandEvent) count++;
      }
      expect(count, PresentationService.maxCommandsPerSecond);
      await audience.close();
      await presenter.close();
    });
  });

  withWonkyServerpod('Given a presenter here and an audience on another '
      'instance (CQ-59)', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView deck;
    final published = <ClusterBusBatch>[];
    late Duration interval;

    setUp(() async {
      Cluster.debugDistributed = true;
      published.clear();
      interval = ClusterBus.flushInterval;
      ClusterBus.flushInterval = const Duration(minutes: 1);
      ClusterBus.debugPublish = (batch) async => published.add(batch);
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      deck = await endpoints.drive.createPresentation(
        anna.endpointSession,
        null,
        'Remote',
        null,
      );
    });
    tearDown(() {
      Cluster.debugDistributed = null;
      ClusterBus.debugPublish = null;
      ClusterBus.flushInterval = interval;
    });

    Future<(_Client, PresentationWelcome)> present() async {
      final updates = StreamController<PresentationUpdate>();
      final client = _Client(
        updates,
        StreamQueue(
          endpoints.presentation.join(
            anna.endpointSession,
            deck.uuid,
            PresentationJoin(
              role: PresentationRole.presenter,
              deviceLabel: 'Laptop',
            ),
            updates.stream,
          ),
        ),
      );
      return (client, await client.next<PresentationWelcome>());
    }

    test('when the presenter changes the state then it leaves this instance '
        'for the other ones', () async {
      final (presenter, welcome) = await present();
      final pod = sessionBuilder.build().serverpod;

      presenter.updates.add(PresentationStateUpdate(state: _state(1, 's1')));
      final channel = PresentationService.channel(welcome.sessionId);
      Future<List<PresentationBusMessage>> sent() async {
        await ClusterBus.flush(pod);
        return [
          for (final b in published)
            for (var i = 0; i < b.channels.length; i++)
              if (b.channels[i] == channel)
                pod.serializationManager.decodeWithType(b.messages[i])
                    as PresentationBusMessage,
        ];
      }

      var messages = await sent();
      for (var i = 0; i < 100 && !messages.any((m) => m.type == 'state'); i++) {
        await pumpEventQueue();
        messages = await sent();
      }

      final state = messages.lastWhere((m) => m.type == 'state');
      expect(state.state?.slideId, 's1');
      expect(
        published.every((b) => b.originInstance == Cluster.instanceId),
        isTrue,
      );
      await presenter.close();
    });

    test('when an audience on another instance sends a command then it '
        'reaches the presenter here', () async {
      final (presenter, welcome) = await present();
      final pod = sessionBuilder.build().serverpod;

      ClusterBus.receive(
        pod,
        ClusterBusBatch(
          originInstance: 'another-instance',
          channels: [PresentationService.channel(welcome.sessionId)],
          messages: [
            pod.serializationManager.encodeWithType(
              PresentationBusMessage(
                type: 'command',
                connectionId: 'remote-audience',
                sessionId: welcome.sessionId,
                deckUuid: deck.uuid.uuid,
                userId: anna.id,
                role: PresentationRole.audience,
                command: 'next',
              ),
            ),
          ],
        ),
      );
      final command = await presenter.next<PresentationCommandEvent>();

      expect(command.command, 'next');
      expect(command.fromConnectionId, 'remote-audience');
      await presenter.close();
    });
  });
}
