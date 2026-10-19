@Tags(['integration'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/actor.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/ot/document_cache.dart';
import 'package:wonky_server/src/write/ot/document_connection.dart';
import 'package:wonky_server/src/write/ot/document_service.dart';
import 'package:wonky_server/src/write/ot/document_store.dart';
import 'package:wonky_server/src/write/ot/ot_service.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

/// Robustness of the Write OT server (code-quality review CQ-4, CQ-5,
/// CQ-17, CQ-22, CQ-23): concurrent writers, unexpected failures, early
/// cancels, size caps, history access and retention.
void main() {
  withWonkyServerpod('Given an open document', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView item;
    late TestDocClient client;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, markdown: 'Hello');
      client = await TestDocClient.connect(endpoints, anna, item.contentRef!);
    });
    tearDown(() async {
      DocumentConnection.debugOnMessage = null;
      await client.close();
    });

    test(
      'when an op commits while a meta change waits for the row then the head revision is kept',
      () async {
        final session = sessionBuilder.build();
        final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
        final head = doc.headRevision;
        late Future<void> meta;
        await session.db.transaction((tx) async {
          // Hold the row like an op commit does, and let updateMeta read
          // the old head and block on its write.
          await Document.db.findById(
            session,
            doc.id!,
            transaction: tx,
            lockMode: LockMode.forUpdate,
          );
          meta = endpoints.document.updateMeta(
            anna.endpointSession,
            item.contentRef!,
            DocumentMetaPatch(field: 'pageSetup', valueJson: '{"size":"a5"}'),
            const Uuid().v7obj(),
          );
          await _waitForBlockedUpdate(session, '"pageSetupJson"');
          await DocumentOp.db.insertRow(
            session,
            DocumentOp(
              documentId: doc.id!,
              revision: head + 1,
              clientOpId: const Uuid().v7obj(),
              authorId: anna.id,
              actorKind: ActorKind.user,
              kind: DocumentOpKind.content,
              baseRevision: head,
              deltaJson: TestDrive.insertAt(0, 'x'),
              inverseJson: jsonEncode([
                {'delete': 1},
              ]),
              createdAt: clock.now().toUtc(),
            ),
            transaction: tx,
          );
          await Document.db.updateWhere(
            session,
            columnValues: (t) => [t.headRevision(head + 1)],
            where: (t) => t.id.equals(doc.id!),
            transaction: tx,
          );
        });
        await meta;
        final after = (await DocumentStore.byUuid(session, item.contentRef!))!;
        client.submitRaw(TestDrive.insertAt(0, 'y'), base: head + 1);
        final ack = await client.next<DocAck>();

        expect(after.headRevision, head + 1);
        expect(after.pageSetupJson, '{"size":"a5"}');
        expect(ack.revision, head + 2);
      },
    );

    test(
      'when the same op is resent on two connections at once then both get the same revision',
      () async {
        final other = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final op = DocSubmitOp(
          clientOpId: const Uuid().v7obj(),
          baseRevision: client.revision,
          deltaJson: TestDrive.insertAt(0, 'Once '),
          kind: DocumentOpKind.content,
        );

        client.send(op);
        other.send(op);
        final acks = await Future.wait([
          client.next<DocAck>(),
          other.next<DocAck>(),
        ]);
        await other.close();
        final content = await endpoints.document.getSnapshot(
          anna.endpointSession,
          item.contentRef!,
          null,
        );

        expect(acks[0].revision, acks[1].revision);
        expect(content.deltaJson, contains('Once Hello'));
        expect(content.deltaJson, isNot(contains('Once Once')));
      },
    );

    test(
      'when handling a message fails unexpectedly then the connection keeps working',
      () async {
        DocumentConnection.debugOnMessage = (m) {
          if (m is DocPing && m.t == 1) throw StateError('boom');
        };

        client.send(DocPing(t: 1));
        client.send(DocPing(t: 2));
        final pong = await client.next<DocPong>();

        expect(pong.t, 2);
      },
    );

    test(
      'when a submit fails unexpectedly then it is rejected and later ops are acknowledged',
      () async {
        final failing = const Uuid().v7obj();
        DocumentConnection.debugOnMessage = (m) {
          if (m is DocSubmitOp && m.clientOpId == failing) {
            throw StateError('boom');
          }
        };

        client.send(
          DocSubmitOp(
            clientOpId: failing,
            baseRevision: client.revision,
            deltaJson: TestDrive.insertAt(0, 'Lost '),
            kind: DocumentOpKind.content,
          ),
        );
        final rejected = await client.next<DocOpRejected>();
        final id = client.submitRaw(TestDrive.insertAt(0, 'Kept '));
        final ack = await client.next<DocAck>();

        expect(rejected.clientOpId, failing);
        expect(ack.clientOpId, id);
      },
    );

    test(
      'when the side effects of earlier ops are slow then the next op is still acknowledged',
      () async {
        final session = sessionBuilder.build();
        final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
        final state = await DocumentCache.of(session, doc);
        final gate = Completer<void>();
        final blocked = state.runSideEffect(() => gate.future);

        client.submitRaw(TestDrive.insertAt(0, 'Fast '));
        final ack = await client.next<DocAck>();
        var settled = false;
        unawaited(client.sideEffectsDone().then((_) => settled = true));
        await pumpEventQueue();
        final settledWhileBlocked = settled;
        gate.complete();
        await blocked;
        await client.sideEffectsDone();

        expect(ack.revision, greaterThan(client.init.revision));
        expect(settledWhileBlocked, isFalse);
      },
    );

    test(
      'when an op is larger than 1 MiB then it is rejected as too large',
      () async {
        client.submitRaw(
          TestDrive.insertAt(0, 'x' * (OtService.maxOpBytes + 1)),
        );
        final rejected = await client.next<DocOpRejected>();

        expect(rejected.code, DocRejectCode.tooLarge);
      },
    );

    test(
      'when an op has more than 20,000 parts then it is rejected as too large',
      () async {
        client.submitRaw(
          jsonEncode([
            for (var i = 0; i <= OtService.maxOpComponents; i++)
              {
                'insert': 'a',
                'attributes': {'bold': i.isEven ? true : null},
              },
          ]),
        );
        final rejected = await client.next<DocOpRejected>();

        expect(rejected.code, DocRejectCode.tooLarge);
      },
    );
  });

  withWonkyServerpod('Given a connection cancelled while it starts', (
    sessionBuilder,
    endpoints,
  ) {
    tearDown(() => DocumentConnection.debugOnStart = null);

    test(
      'when it is cancelled before Init then nothing stays retained or announced',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final item = await TestDrive.document(endpoints, anna);
        final started = Completer<Future<void>>();
        DocumentConnection.debugOnStart = started.complete;
        final input = StreamController<DocClientMessage>();

        final subscription = endpoints.document
            .connect(anna.endpointSession, item.contentRef!, 0, input.stream)
            .listen((_) {}, onError: (Object _) {});
        final start = await started.future.timeout(const Duration(seconds: 10));
        DocumentConnection.debugOnStart = null;
        await subscription.cancel();
        // The start goes on after the cancel until its next check.
        await start;
        await input.close();
        final later = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final session = sessionBuilder.build();
        final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
        final state = await DocumentCache.of(session, doc);
        final connections = state.connections;
        await later.close();

        expect(later.init.participants, hasLength(1));
        expect(connections, 1);
      },
    );
  });

  withWonkyServerpod('Given a document used only headlessly', (
    sessionBuilder,
    endpoints,
  ) {
    final disposeAfter = DocumentCache.disposeAfter;
    tearDown(() => DocumentCache.disposeAfter = disposeAfter);

    test(
      'when a server change is submitted then its state is disposed after the idle delay',
      () async {
        DocumentCache.disposeAfter = Duration.zero;
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final item = await TestDrive.document(endpoints, anna, markdown: 'Hi');
        final session = sessionBuilder.build();
        final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
        final driveItem = (await DriveItem.db.findById(session, doc.itemId))!;

        final committed = await OtService.submitServerChange(
          session,
          actor: Actor(
            userId: anna.id,
            authUserId: anna.authUserId,
            kind: ActorKind.user,
          ),
          document: doc,
          item: driveItem,
          build: (head) => Delta()..insert('Oh '),
        );
        await Future<void>.delayed(Duration.zero);

        expect(committed.revision, doc.headRevision + 1);
        expect(DocumentCache.isCached(item.contentRef!), isFalse);
      },
    );
  });

  withWonkyServerpod('Given a long document history', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser vic;
    late DriveItemView item;
    late int head;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      vic = await TestUsers.create(sessionBuilder, name: 'Vic');
      item = await TestDrive.document(endpoints, anna);
      await TestDrive.share(endpoints, item, anna, vic, AccessRole.viewer);
      final session = sessionBuilder.build();
      final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
      head = DocumentService.recentOpWindow + 5;
      final now = clock.now().toUtc();
      await DocumentOp.db.insert(session, [
        for (var r = 1; r <= head; r++)
          DocumentOp(
            documentId: doc.id!,
            revision: r,
            clientOpId: const Uuid().v7obj(),
            authorId: anna.id,
            actorKind: ActorKind.user,
            kind: DocumentOpKind.content,
            baseRevision: r - 1,
            deltaJson: TestDrive.insertAt(0, 'x'),
            inverseJson: jsonEncode([
              {'delete': 1},
            ]),
            createdAt: now,
          ),
      ]);
      await Document.db.updateWhere(
        session,
        columnValues: (t) => [t.headRevision(head)],
        where: (t) => t.id.equals(doc.id!),
      );
      DocumentCache.evict(item.contentRef!);
    });

    test(
      'when a viewer asks for ops older than the recent window then it is refused',
      () async {
        final old = endpoints.document.getOps(
          vic.endpointSession,
          item.contentRef!,
          1,
          10,
        );

        await expectLater(old, throwsA(isA<WonkyException>()));
      },
    );

    test(
      'when a viewer asks for ops within the recent window then they are returned',
      () async {
        final from = head - DocumentService.recentOpWindow + 1;

        final ops = await endpoints.document.getOps(
          vic.endpointSession,
          item.contentRef!,
          from,
          from + 9,
        );

        expect(ops.map((o) => o.revision), [
          for (var i = 0; i < 10; i++) from + i,
        ]);
      },
    );

    test('when the owner asks for old ops then they are returned', () async {
      final ops = await endpoints.document.getOps(
        anna.endpointSession,
        item.contentRef!,
        1,
        10,
      );

      expect(ops, hasLength(10));
    });

    test(
      'when a viewer requests old ops on the stream then none are sent',
      () async {
        final c = await TestDocClient.connect(endpoints, vic, item.contentRef!);

        c.send(DocRequestOps(fromRevision: 1, toRevision: 5));
        c.send(DocPing(t: 7));
        final next = await c.nextAny();
        await c.close();

        expect(next, isA<DocPong>());
      },
    );
  });

  withWonkyServerpod('Given ops older than the retention', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when pruning then old ops and unneeded snapshots go and versions still materialize',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final item = await TestDrive.document(endpoints, anna);
        final client = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        client.edit(Delta()..insert('One '));
        await client.processUntilSynchronized();
        final version = await endpoints.version.nameCurrent(
          anna.endpointSession,
          item.uuid,
          'v1',
        );
        client.edit(Delta()..insert('Two '));
        await client.processUntilSynchronized();
        client.edit(Delta()..insert('Three '));
        await client.processUntilSynchronized();
        await client.close();
        final session = sessionBuilder.build();
        final doc = (await DocumentStore.byUuid(session, item.contentRef!))!;
        await DocumentStore.writeSnapshot(
          session,
          doc,
          version.revision! + 1,
          await DocumentStore.contentAt(session, doc, version.revision! + 1),
        );
        final now = clock.now().toUtc();
        await session.db.unsafeExecute(
          'UPDATE document_op SET "createdAt" = @at WHERE "documentId" = @doc',
          parameters: QueryParameters.named({
            'at': now.subtract(const Duration(days: 40)),
            'doc': doc.id!,
          }),
        );

        final pruned = await DocumentService.pruneOps(session, now: now);
        final ops = await DocumentOp.db.count(
          session,
          where: (t) => t.documentId.equals(doc.id!),
        );
        final snapshots = await DocumentSnapshot.db.find(
          session,
          where: (t) => t.documentId.equals(doc.id!),
        );
        final atVersion = await endpoints.document.getSnapshot(
          anna.endpointSession,
          item.contentRef!,
          version.revision,
        );
        final atHead = await endpoints.document.getSnapshot(
          anna.endpointSession,
          item.contentRef!,
          null,
        );

        // The prune is global: other documents of the shared test database
        // may be pruned in the same call.
        expect(pruned, greaterThanOrEqualTo(doc.headRevision));
        expect(ops, 0);
        expect(snapshots.map((s) => s.revision).toSet(), {
          version.revision,
          doc.headRevision,
        });
        expect(atVersion.deltaJson, contains('One '));
        expect(atHead.deltaJson, contains('Three Two One '));
      },
    );
  });
}

/// Waits until a statement containing [marker] waits for a row lock.
Future<void> _waitForBlockedUpdate(Session session, String marker) async {
  final watch = Stopwatch()..start();
  while (watch.elapsed < const Duration(seconds: 10)) {
    final rows = await session.db.unsafeQuery(
      '''
      SELECT count(*) FROM pg_stat_activity
      WHERE wait_event_type = 'Lock' AND query LIKE @marker
      ''',
      parameters: QueryParameters.named({'marker': '%UPDATE%$marker%'}),
    );
    if ((rows.first[0] as int) > 0) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw TimeoutException('The meta update never waited for the row lock');
}
