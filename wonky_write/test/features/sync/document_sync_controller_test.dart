import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_ui/wonky_ui.dart' show SyncState;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_write/features/sync/document_sync_controller.dart';
import 'package:wonky_write/features/sync/sync_persistence.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'support/fake_document_server.dart';

class _Client {
  _Client(this.server, {int userId = 1})
    : transport = server.transport(userId: userId),
      keeper = SimpleConnectionKeeper(minDelay: Duration.zero),
      host = DeltaHost() {
    sync = DocumentSyncController(
      transport: transport,
      host: host,
      keeper: keeper,
      pingEvery: Duration.zero,
      gapRetry: const Duration(hours: 1),
    );
    sync.events.listen(events.add);
  }

  final FakeDocumentServer server;
  final FakeTransport transport;
  final SimpleConnectionKeeper keeper;
  final DeltaHost host;
  late final DocumentSyncController sync;
  final List<SyncEvent> events = [];

  FakeConnection get connection => transport.last!;

  String get text => DeltaUtils.text(host.doc);

  Delta insert(int at, String text, [Map<String, dynamic>? attrs]) => host.edit(
    sync,
    Delta()
      ..retain(at)
      ..insert(text, attrs),
  );

  Future<void> dispose() async {
    await sync.dispose();
    keeper.dispose();
  }
}

Delta _doc(String text) => Delta()..insert('$text\n');

List<T> _sent<T>(FakeDocumentServer s) => s.received.whereType<T>().toList();

void main() {
  group('Given a document on the server', () {
    late FakeDocumentServer server;
    late _Client a;

    setUp(() async {
      server = FakeDocumentServer(initial: _doc('Hello'));
      a = _Client(server);
      a.sync.start();
      await pumpEventQueue();
    });

    tearDown(() => a.dispose());

    test(
      'when connecting then the snapshot is loaded and the status is saved',
      () {
        expect(a.sync.isLoaded, isTrue);
        expect(a.text, 'Hello\n');
        expect(a.sync.revision, 0);
        expect(a.sync.status.value.state, SyncState.saved);
        expect(a.events.whereType<SyncLoaded>(), hasLength(1));
      },
    );

    test(
      'when typing then one op is in flight and later changes are buffered',
      () async {
        server.autoDeliver = false;
        a.insert(5, '!');
        a.insert(6, '?');

        expect(a.sync.otState, SyncOtState.awaitingAckWithBuffer);
        await pumpEventQueue();
        expect(_sent<DocSubmitOp>(server), hasLength(1));
        expect(a.sync.status.value.state, SyncState.saving);

        server.deliverAll();
        await pumpEventQueue();
        expect(_sent<DocSubmitOp>(server), hasLength(2));
        expect(_sent<DocSubmitOp>(server).last.baseRevision, 1);
        server.deliverAll();
        await pumpEventQueue();

        expect(a.sync.otState, SyncOtState.synchronized);
        expect(server.document, a.host.doc);
        expect(a.sync.revision, 2);
        expect(a.sync.status.value.state, SyncState.saved);
      },
    );

    test(
      'when a remote op arrives while awaiting an ack then both converge',
      () async {
        server.autoDeliver = false;
        a.insert(0, 'A');
        await pumpEventQueue();
        server.commitExternal(Delta()..insert('X'));

        server.deliverAll();
        await pumpEventQueue();
        server.deliverAll();
        await pumpEventQueue();

        expect(a.host.doc, server.document);
        expect(DeltaUtils.text(server.document), 'XAHello\n');
      },
    );

    test(
      'when remote ops arrive out of order then the gap is requested and applied in order',
      () async {
        server.autoDeliver = false;
        server.commitExternal(Delta()..insert('1'));
        server.commitExternal(Delta()..insert('2'));
        final conn = a.connection;
        final (second, _) = conn.pending.removeAt(1);
        conn.out.add(second);
        await pumpEventQueue();

        expect(a.sync.revision, 0);
        expect(_sent<DocRequestOps>(server).single.fromRevision, 1);
        expect(_sent<DocRequestOps>(server).single.toRevision, 1);

        server.deliverAll();
        await pumpEventQueue();
        expect(a.sync.revision, 2);
        expect(a.text, '21Hello\n');
      },
    );

    test(
      'when a remote op is delivered twice then it is applied once',
      () async {
        server.autoDeliver = false;
        server.commitExternal(Delta()..insert('1'));
        final (m, _) = a.connection.pending.single;
        server.deliverAll();
        a.connection.out.add(m);
        await pumpEventQueue();

        expect(a.text, '1Hello\n');
      },
    );

    test(
      'when the ack overtakes a remote op then the ack waits for the gap',
      () async {
        server.autoDeliver = false;
        server.commitExternal(Delta()..insert('X'));
        a.insert(5, '!');
        await pumpEventQueue();
        // Deliver the ack (revision 2) before the remote op (revision 1).
        final conn = a.connection;
        final ackIndex = conn.pending.indexWhere((p) => p.$1 is DocAck);
        final (ack, _) = conn.pending.removeAt(ackIndex);
        conn.out.add(ack);
        await pumpEventQueue();
        expect(a.sync.otState, isNot(SyncOtState.synchronized));
        expect(_sent<DocRequestOps>(server), isNotEmpty);

        server.deliverAll();
        await pumpEventQueue();
        expect(a.sync.revision, 2);
        expect(a.host.doc, server.document);
        expect(a.text, 'XHello!\n');
      },
    );

    test(
      'when reconnecting after the ack was lost then the committed op is not duplicated',
      () async {
        server.autoDeliver = false;
        a.insert(5, '!');
        await pumpEventQueue();
        expect(server.revision, 1);
        a.keeper.online = false;
        await pumpEventQueue();
        expect(a.sync.status.value.state, SyncState.offline);

        server.autoDeliver = true;
        a.keeper.online = true;
        await pumpEventQueue();

        expect(a.sync.otState, SyncOtState.synchronized);
        expect(a.text, 'Hello!\n');
        expect(server.document, a.host.doc);
        expect(server.revision, 1);
      },
    );

    test(
      'when reconnecting before the op reached the server then it is resent with the same id',
      () async {
        a.keeper.online = false;
        await pumpEventQueue();
        a.insert(5, '!');
        a.insert(6, '?');
        expect(a.sync.otState, SyncOtState.synchronized);
        expect(a.sync.hasPendingChanges, isTrue);

        a.keeper.online = true;
        await pumpEventQueue();

        expect(_sent<DocSubmitOp>(server), hasLength(1));
        expect(server.document, a.host.doc);
        expect(a.text, 'Hello!?\n');
      },
    );

    test(
      'when the in-flight op is resent after a reconnect then the server acknowledges it once',
      () async {
        server.autoDeliver = false;
        a.insert(5, '!');
        await pumpEventQueue();
        final firstId = _sent<DocSubmitOp>(server).single.clientOpId;
        // Lose the connection (ack never arrives), then reconnect.
        a.keeper.online = false;
        await pumpEventQueue();
        server.autoDeliver = true;
        a.keeper.online = true;
        await pumpEventQueue();

        final submits = _sent<DocSubmitOp>(server);
        expect(submits.every((s) => s.clientOpId == firstId), isTrue);
        expect(server.revision, 1);
        expect(a.host.doc, server.document);
      },
    );

    test(
      'when the server rejects an op then the document is re-synchronized',
      () async {
        server.rejectNext = DocRejectCode.invalidOp;
        a.insert(5, '!');
        await pumpEventQueue();

        final resync = a.events.whereType<SyncResynced>().single;
        expect(resync.reason, ResyncReason.rejected);
        expect(resync.lostLocalChanges, isTrue);
        expect(DeltaUtils.text(resync.recoveryDocument!), 'Hello!\n');
        expect(a.text, 'Hello\n');
        expect(a.sync.status.value.state, SyncState.error);

        a.insert(0, 'A');
        await pumpEventQueue();
        expect(a.sync.status.value.state, SyncState.saved);
        expect(server.document, a.host.doc);
      },
    );

    test('when the role changes then an event is emitted', () async {
      server.setRole(1, AccessRole.commenter);
      await pumpEventQueue();

      final e = a.events.whereType<SyncRoleChanged>().last;
      expect(e.role, AccessRole.commenter);
      expect(e.initial, isFalse);
      expect(a.sync.role, AccessRole.commenter);
    });

    test('when the page setup changes then the meta is updated', () async {
      server.changeMeta('pageSetup', '{"size":"letter"}', authorId: 2);
      await pumpEventQueue();

      expect(a.sync.meta!.pageSetupJson, '{"size":"letter"}');
      expect(a.events.whereType<SyncMetaChanged>().single.field, 'pageSetup');
    });

    test(
      'when suggesting then the stamped suggestion time is taken from the server',
      () async {
        final mark = {
          'sug_s1': {'t': 'ins', 'by': a.transport.userUuid, 'at': 1},
        };
        a.insert(5, ' there', mark);
        await pumpEventQueue();

        expect(a.transport.getOpsCalls, 1);
        expect(a.host.doc, server.document);
        final at =
            (server.document.operations[1].attributes!['sug_s1'] as Map)['at'];
        expect(at, isNot(1));
        expect(a.sync.serverDocument, server.document);
      },
    );

    test(
      'when the server normalizes an op then the local document follows',
      () async {
        // A tab outside code blocks is replaced by spaces on the server.
        a.insert(0, '\t');
        await pumpEventQueue();

        expect(a.transport.getOpsCalls, 0);
        expect(a.host.doc, server.document);
        expect(a.text, '    Hello\n');
        expect(a.host.applied.last.$2.origin, RemoteChangeOrigin.fixup);
      },
    );

    test(
      'when the integrity check fails then the document is re-synchronized',
      () async {
        server.corruptHashes = true;
        a.sync.checkIntegrity();
        await pumpEventQueue();

        expect(
          a.events.whereType<SyncResynced>().single.reason,
          ResyncReason.integrity,
        );
      },
    );

    test(
      'when a restored copy differs from the server then connecting re-synchronizes it',
      () async {
        a.insert(5, ' world');
        await pumpEventQueue();
        // The cached copy has text the server never committed (e.g. an
        // embed an older server dropped while normalizing).
        final b = _Client(server, userId: 2);
        b.sync.restore(
          SyncLocalState(revision: 1, serverDocument: _doc('Hello world!')),
        );
        expect(b.text, 'Hello world!\n');

        b.sync.start();
        await pumpEventQueue();

        expect(_sent<DocHashCheck>(server), hasLength(1));
        expect(
          b.events.whereType<SyncResynced>().single.reason,
          ResyncReason.integrity,
        );
        expect(b.text, 'Hello world\n');
        await b.dispose();
      },
    );

    test(
      'when a remote cursor arrives then it is mapped through pending local changes',
      () async {
        final b = _Client(server, userId: 2);
        b.sync.start();
        await pumpEventQueue();
        server.autoDeliver = false;
        b.sync.sendCursor(5, 5);
        await pumpEventQueue();
        a.insert(0, 'abc');
        await pumpEventQueue();
        final conn = a.connection;
        final i = conn.pending.indexWhere((p) => p.$1 is DocRemoteCursor);
        final (cursor, _) = conn.pending.removeAt(i);
        conn.out.add(cursor);
        await pumpEventQueue();

        final c = a.events.whereType<SyncRemoteCursor>().single;
        expect(c.anchor, 8);
        expect(c.userId, 2);
        await b.dispose();
      },
    );

    test(
      'when sending the cursor with pending changes then it is expressed at the server revision',
      () async {
        server.autoDeliver = false;
        a.insert(0, 'abc');
        a.sync.sendCursor(8, 8);
        await pumpEventQueue();

        final update = _sent<DocCursorUpdate>(server).single;
        expect(update.revision, 0);
        expect(update.anchor, 5);
      },
    );

    test('when sending the cursor with a pending replacement then it is '
        'expressed at the server revision', () async {
      server.autoDeliver = false;
      // "Hello" → "Hxyo": "ell" deleted, "xy" inserted.
      a.host.edit(
        a.sync,
        Delta()
          ..retain(1)
          ..insert('xy')
          ..delete(3),
      );
      a.sync.sendCursor(4, 3);
      await pumpEventQueue();

      final update = _sent<DocCursorUpdate>(server).single;
      // Mapped through the inverse ("xy" goes, the deleted "ell" comes back):
      // the caret before "o" stays before it (4), the one after it after it.
      expect((update.anchor, update.head), (5, 4));
    });
  });

  group('Given two clients editing the same document', () {
    test('when both type at the same position then they converge', () async {
      final server = FakeDocumentServer(
        initial: _doc('ab'),
        autoDeliver: false,
      );
      final a = _Client(server, userId: 1);
      final b = _Client(server, userId: 2);
      a.sync.start();
      b.sync.start();
      server.deliverAll();
      await pumpEventQueue();

      a.insert(1, 'X');
      b.insert(1, 'Y');
      await pumpEventQueue();
      for (var i = 0; i < 5; i++) {
        server.deliverAll();
        await pumpEventQueue();
      }

      expect(a.host.doc, server.document);
      expect(b.host.doc, server.document);
      expect(jsonEncode(server.document.toJson()), contains('X'));
      await a.dispose();
      await b.dispose();
    });
  });
}
