@Tags(['integration'])
library;

import 'package:clock/clock.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/cluster/cluster.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/ot/document_bus.dart';
import 'package:wonky_server/src/write/ot/document_cache.dart';
import 'package:wonky_server/src/write/ot/document_connection.dart';

import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Several server instances (specs/13 §4) simulated in one process: each
/// instance has its own in-memory [DocumentState]; evicting the cache
/// makes later connections use a fresh state, like another instance would.
void main() {
  withWonkyServerpod('Given a document open on two instances', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late DriveItemView item;
    late TestDocClient first;
    late TestDocClient second;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, name: 'Shared');
      first = await TestDocClient.connect(endpoints, anna, item.contentRef!);
      // The second connection lives on "another instance".
      DocumentCache.evict(item.contentRef!);
      second = await TestDocClient.connect(endpoints, anna, item.contentRef!);
    });
    tearDown(() async {
      await first.close();
      await second.close();
    });

    test(
      'when the other instance commits then requesting the gap returns the op',
      () async {
        second.submitRaw(TestDrive.insertAt(0, 'Hello'));
        await second.next<DocAck>();
        final relayed = await first.next<DocRemoteOp>();

        first.send(DocRequestOps(fromRevision: 1, toRevision: 1));
        final filled = await first.next<DocRemoteOp>();

        expect(relayed.revision, 1);
        expect(filled.revision, 1);
      },
    );

    test(
      'when a cursor is sent at the new head then it is stamped with that revision',
      () async {
        second.submitRaw(TestDrive.insertAt(0, 'Hello'));
        await second.next<DocAck>();
        await first.next<DocRemoteOp>();

        first.send(
          DocCursorUpdate(revision: 1, anchor: 3, head: 5, focused: true),
        );
        final cursor = await second.next<DocRemoteCursor>();

        expect(cursor.revision, 1);
        expect((cursor.anchor, cursor.head), (3, 5));
      },
    );
  });

  withWonkyServerpod('Given a cluster with Redis', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView item;
    setUp(() async {
      Cluster.debugDistributed = true;
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, name: 'Shared');
    });
    tearDown(() {
      Cluster.debugDistributed = null;
      DocumentConnection.heartbeatInterval = const Duration(seconds: 30);
      DocumentConnection.maxEditors = 100;
      DocumentConnection.rosterSettle = const Duration(seconds: 2);
    });

    Participant participant(String sessionId, DateTime joinedAt) => Participant(
      sessionId: sessionId,
      userId: anna.id,
      userUuid: anna.actor.authUserId,
      displayName: 'Elsewhere',
      colorIndex: 0,
      role: AccessRole.editor,
      actorKind: ActorKind.user,
      state: PresenceState.active,
      joinedAt: joinedAt,
    );

    test(
      'when a participant of a crashed instance stops beating then it leaves',
      () async {
        DocumentConnection.heartbeatInterval = const Duration(
          milliseconds: 40,
        );
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        await DocumentBus.post(
          anna.session,
          item.contentRef!,
          DocBusMessage(
            type: 'hello',
            originSessionId: 'ghost',
            participant: participant('ghost', clock.now().toUtc()),
          ),
        );
        final joined = await c.next<DocParticipantJoined>();
        final left = await c.next<DocParticipantLeft>();

        expect(joined.participant.sessionId, 'ghost');
        expect(left.sessionId, 'ghost');
        await c.close();
      },
    );

    test(
      'when the editor limit is reached by a late roster reply then the joiner becomes a viewer',
      () async {
        DocumentConnection.maxEditors = 1;
        DocumentConnection.rosterSettle = const Duration(milliseconds: 200);
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final me = c.init.participants.firstWhere(
          (p) => p.sessionId == c.init.sessionId,
        );

        // The `here` of an editor on another instance arrives after Init.
        await DocumentBus.post(
          anna.session,
          item.contentRef!,
          DocBusMessage(
            type: 'here',
            originSessionId: 'early',
            sessionId: c.init.sessionId,
            participant: participant(
              'early',
              me.joinedAt.subtract(const Duration(minutes: 1)),
            ),
          ),
        );
        final changed = await c.next<DocRoleChanged>();

        expect(c.init.role, AccessRole.owner);
        expect(changed.role, AccessRole.viewer);
        await c.close();
      },
    );
  });
}
