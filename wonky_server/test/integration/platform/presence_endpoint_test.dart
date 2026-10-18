@Tags(['integration'])
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/cluster/cluster.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/presence/presence_service.dart';

import '../../support/streams.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given two users on one document', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when the second joins then both see each other and leaving is announced',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);

        final annaUpdates = StreamController<PresenceUpdate>();
        final annaEvents = StreamQueue(
          endpoints.presence.join(
            anna.endpointSession,
            doc.uuid,
            annaUpdates.stream,
          ),
        );
        final annaRoster =
            await nextWhere(annaEvents, (e) => e is PresenceRoster)
                as PresenceRoster;

        final boUpdates = StreamController<PresenceUpdate>();
        final boEvents = StreamQueue(
          endpoints.presence.join(
            bo.endpointSession,
            doc.uuid,
            boUpdates.stream,
          ),
        );
        final boRoster =
            await nextWhere(boEvents, (e) => e is PresenceRoster)
                as PresenceRoster;
        final joined =
            await nextWhere(annaEvents, (e) => e is PresenceJoined)
                as PresenceJoined;

        annaUpdates.add(PresenceUpdate(state: PresenceState.idle));
        final updated =
            await nextWhere(boEvents, (e) => e is PresenceUpdated)
                as PresenceUpdated;

        await boUpdates.close();
        final left =
            await nextWhere(annaEvents, (e) => e is PresenceLeft)
                as PresenceLeft;

        expect(annaRoster.participants.map((p) => p.userId), [anna.id]);
        expect(boRoster.participants.map((p) => p.userId).toSet(), {
          anna.id,
          bo.id,
        });
        expect(joined.participant.userId, bo.id);
        expect(updated.state, PresenceState.idle);
        expect(left.sessionId, boRoster.sessionId);
        await annaUpdates.close();
        await annaEvents.cancel(immediate: true);
        await boEvents.cancel(immediate: true);
      },
    );

    test('when a user without access joins then it is refused', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final eve = await TestUsers.create(sessionBuilder, name: 'Eve');
      final doc = await TestDrive.document(endpoints, anna);

      final stream = endpoints.presence.join(
        eve.endpointSession,
        doc.uuid,
        const Stream<PresenceUpdate>.empty(),
      );

      await expectLater(stream.first, throwsA(isA<WonkyException>()));
    });

    test('when the owner removes a joined user then the user\'s stream '
        'ends with notFound', () async {
      final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      final doc = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
      final updates = StreamController<PresenceUpdate>();
      final events = StreamQueue(
        endpoints.presence.join(bo.endpointSession, doc.uuid, updates.stream),
      );
      await nextWhere(events, (e) => e is PresenceRoster);

      await endpoints.sharing.remove(anna.endpointSession, doc.uuid, bo.id);

      await expectLater(
        nextWhere(events, (e) => false),
        throwsA(
          isA<WonkyException>().having(
            (e) => e.code,
            'code',
            WonkyErrorCode.notFound,
          ),
        ),
      );
      await updates.close();
      await events.cancel(immediate: true);
    });

    test(
      'when a cursor is over the size limit then it is not relayed',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
        final doc = await TestDrive.document(endpoints, anna);
        await TestDrive.share(endpoints, doc, anna, bo, AccessRole.viewer);
        final annaUpdates = StreamController<PresenceUpdate>();
        final annaEvents = StreamQueue(
          endpoints.presence.join(
            anna.endpointSession,
            doc.uuid,
            annaUpdates.stream,
          ),
        );
        await nextWhere(annaEvents, (e) => e is PresenceRoster);
        final boUpdates = StreamController<PresenceUpdate>();
        final boEvents = StreamQueue(
          endpoints.presence.join(
            bo.endpointSession,
            doc.uuid,
            boUpdates.stream,
          ),
        );
        await nextWhere(boEvents, (e) => e is PresenceRoster);

        annaUpdates.add(
          PresenceUpdate(
            state: PresenceState.active,
            cursorJson: 'x' * (PresenceService.maxCursorBytes + 1),
          ),
        );
        annaUpdates.add(
          PresenceUpdate(state: PresenceState.idle, cursorJson: '{}'),
        );
        final updated =
            await nextWhere(boEvents, (e) => e is PresenceUpdated)
                as PresenceUpdated;

        expect((updated.state, updated.cursorJson), (PresenceState.idle, '{}'));
        await annaUpdates.close();
        await boUpdates.close();
        await annaEvents.cancel(immediate: true);
        await boEvents.cancel(immediate: true);
      },
    );
  });

  withWonkyServerpod('Given a cluster with Redis', (sessionBuilder, endpoints) {
    setUp(() {
      Cluster.debugDistributed = true;
      PresenceService.heartbeatInterval = const Duration(milliseconds: 40);
    });
    tearDown(() {
      Cluster.debugDistributed = null;
      PresenceService.heartbeatInterval = const Duration(seconds: 30);
    });

    test(
      'when a session of a crashed instance stops beating then it leaves',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final doc = await TestDrive.document(endpoints, anna);
        final updates = StreamController<PresenceUpdate>();
        final events = StreamQueue(
          endpoints.presence.join(
            anna.endpointSession,
            doc.uuid,
            updates.stream,
          ),
        );
        await nextWhere(events, (e) => e is PresenceRoster);

        await anna.session.messages.postMessage(
          PresenceService.channel(doc.uuid),
          PresenceBusMessage(
            type: 'hello',
            sessionId: 'ghost',
            participant: Participant(
              sessionId: 'ghost',
              userId: anna.id,
              userUuid: anna.actor.authUserId,
              displayName: 'Elsewhere',
              colorIndex: 0,
              role: AccessRole.viewer,
              actorKind: ActorKind.user,
              state: PresenceState.active,
              joinedAt: clock.now().toUtc(),
            ),
          ),
        );
        final joined =
            await nextWhere(events, (e) => e is PresenceJoined)
                as PresenceJoined;
        final left =
            await nextWhere(events, (e) => e is PresenceLeft) as PresenceLeft;

        expect(joined.participant.sessionId, 'ghost');
        expect(left.sessionId, 'ghost');
        await updates.close();
        await events.cancel(immediate: true);
      },
    );
  });
}
