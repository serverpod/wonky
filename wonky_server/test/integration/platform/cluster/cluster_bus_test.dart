@Tags(['integration'])
library;

import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/cluster/cluster.dart';
import 'package:wonky_server/src/platform/cluster/cluster_bus.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/ot/document_bus.dart';

import '../../../support/wonky_serverpod.dart';

void main() {
  withWonkyServerpod('Given the cluster bus with other instances', (
    sessionBuilder,
    endpoints,
  ) {
    final published = <ClusterBusBatch>[];
    late Duration interval;
    // Completes with the first publish (no fixed wait for the timer).
    late Completer<void> firstPublish;

    setUp(() {
      published.clear();
      firstPublish = Completer<void>();
      interval = ClusterBus.flushInterval;
      ClusterBus.flushInterval = const Duration(milliseconds: 50);
      ClusterBus.debugPublish = (batch) async {
        published.add(batch);
        if (!firstPublish.isCompleted) firstPublish.complete();
      };
    });
    tearDown(() {
      ClusterBus.debugPublish = null;
      ClusterBus.flushInterval = interval;
    });

    DocBusMessage cursor(String session, int at) => DocBusMessage(
      type: 'cursor',
      originSessionId: session,
      cursor: DocRemoteCursor(
        sessionId: session,
        userId: 1,
        revision: at,
        anchor: at,
        head: at,
        focused: true,
      ),
    );

    test(
      'when posting then local listeners get the message at once and the '
      'other instances in one batch per interval',
      () async {
        final session = sessionBuilder.build();
        final local = <SerializableModel>[];
        session.messages.addListener('doc:a', local.add);

        await ClusterBus.post(
          session,
          'doc:a',
          DocBusMessage(type: 'left', originSessionId: 's1'),
        );
        await ClusterBus.post(
          session,
          'presence:b',
          PresenceBusMessage(type: 'bye', sessionId: 's2'),
        );
        expect(local, hasLength(1));
        expect(published, isEmpty);

        await firstPublish.future.timeout(const Duration(seconds: 10));

        expect(published, hasLength(1));
        expect(published.single.channels, ['doc:a', 'presence:b']);
        expect(published.single.originInstance, Cluster.instanceId);
      },
    );

    test(
      'when a session moves its cursor several times then the batch only '
      'carries the latest, after the messages queued before it',
      () async {
        final session = sessionBuilder.build();
        final doc = UuidValue.fromString(const Uuid().v4());

        await DocumentBus.post(session, doc, cursor('s1', 1));
        await DocumentBus.post(
          session,
          doc,
          DocBusMessage(type: 'left', originSessionId: 's2'),
        );
        await DocumentBus.post(session, doc, cursor('s1', 2));
        await DocumentBus.post(session, doc, cursor('s3', 7));
        await ClusterBus.flush(session.serverpod);

        final decoded = [
          for (final m in published.single.messages)
            session.serverpod.serializationManager.decodeWithType(m)
                as DocBusMessage,
        ];
        expect([for (final m in decoded) m.type], ['left', 'cursor', 'cursor']);
        expect(decoded[1].cursor!.anchor, 2);
        expect(decoded[2].cursor!.sessionId, 's3');
      },
    );

    test(
      'when an op is posted then it and the messages queued before it are '
      'published at once, in order',
      () async {
        ClusterBus.flushInterval = const Duration(seconds: 30);
        final session = sessionBuilder.build();
        final doc = UuidValue.fromString(const Uuid().v4());

        await DocumentBus.post(session, doc, cursor('s1', 1));
        expect(published, isEmpty);
        await DocumentBus.post(
          session,
          doc,
          DocBusMessage(type: 'op', originSessionId: 's1'),
        );
        await Future<void>.delayed(Duration.zero);

        expect(published, hasLength(1));
        final types = [
          for (final m in published.single.messages)
            (session.serverpod.serializationManager.decodeWithType(m)
                    as DocBusMessage)
                .type,
        ];
        expect(types, ['cursor', 'op']);
      },
    );

    test(
      'when a batch of another instance arrives then its messages reach the '
      'listeners here, and an own batch is ignored',
      () async {
        final session = sessionBuilder.build();
        final pod = session.serverpod;
        final local = <SerializableModel>[];
        session.messages.addListener('doc:c', local.add);
        ClusterBusBatch batch(String origin) => ClusterBusBatch(
          originInstance: origin,
          channels: ['doc:c', 'doc:other'],
          messages: [
            pod.serializationManager.encodeWithType(cursor('s9', 4)),
            pod.serializationManager.encodeWithType(cursor('s8', 5)),
          ],
        );

        ClusterBus.receive(pod, batch(Cluster.instanceId));
        ClusterBus.receive(pod, batch('another-instance'));
        await pumpEventQueue();

        expect(local, hasLength(1));
        expect((local.single as DocBusMessage).cursor!.sessionId, 's9');
      },
    );
  });
}
