@Tags(['integration'])
library;

import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/collab/overlay_lifecycle.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../support/test_doc_client.dart';
import '../../support/test_drive.dart';
import '../../support/test_users.dart';
import '../../support/wonky_serverpod.dart';

Future<Delta> _serverContent(
  TestEndpoints endpoints,
  TestUser user,
  UuidValue documentUuid,
) async {
  final snapshot = await endpoints.document.getSnapshot(
    user.endpointSession,
    documentUuid,
    null,
  );
  return Delta.fromJson(jsonDecode(snapshot.deltaJson) as List);
}

String _text(Delta d) => DeltaUtils.text(d);

void main() {
  withWonkyServerpod('Given a blank document', (sessionBuilder, endpoints) {
    late TestUser anna;
    late DriveItemView item;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      item = await TestDrive.document(endpoints, anna, name: 'Blank');
    });

    test(
      'when connecting then Init carries a snapshot, revision 0 and the owner role',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        expect(c.init.revision, 0);
        expect(c.init.role, AccessRole.owner);
        expect(_text(c.document), '\n');
        expect(c.init.participants.map((p) => p.userId), [anna.id]);
        await c.close();
      },
    );

    test(
      'when submitting an insert then it is acknowledged as revision 1',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        final id = c.submitRaw(TestDrive.insertAt(0, 'Hello'));
        final ack = await c.next<DocAck>();

        expect(ack.clientOpId, id);
        expect(ack.revision, 1);
        expect(
          _text(await _serverContent(endpoints, anna, item.contentRef!)),
          'Hello\n',
        );
        await c.close();
      },
    );

    test(
      'when resubmitting the same clientOpId then the original revision is acknowledged',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final id = const Uuid().v7obj();
        final op = DocSubmitOp(
          clientOpId: id,
          baseRevision: 0,
          deltaJson: TestDrive.insertAt(0, 'Once'),
          kind: DocumentOpKind.content,
        );

        c.send(op);
        final first = await c.next<DocAck>();
        c.send(op);
        final second = await c.next<DocAck>();

        expect(second.revision, first.revision);
        expect(
          _text(await _serverContent(endpoints, anna, item.contentRef!)),
          'Once\n',
        );
        await c.close();
      },
    );

    test(
      'when an op does not fit the document then it is rejected as invalid',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        c.submitRaw(
          jsonEncode([
            {'retain': 50},
            {'insert': 'x'},
          ]),
        );
        final rejected = await c.next<DocOpRejected>();

        expect(rejected.code, DocRejectCode.invalidOp);
        await c.close();
      },
    );

    test(
      'when the base revision is in the future then it is rejected',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        c.submitRaw(TestDrive.insertAt(0, 'x'), base: 7);
        final rejected = await c.next<DocOpRejected>();

        expect(rejected.code, DocRejectCode.unknownBase);
        await c.close();
      },
    );

    test(
      'when reconnecting with a known revision then Init carries the missed ops',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        c.edit(Delta()..insert('One '));
        await c.processUntilSynchronized();
        c.edit(
          Delta()
            ..retain(4)
            ..insert('Two'),
        );
        await c.processUntilSynchronized();
        await c.close();

        final again = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
          knownRevision: 1,
        );

        expect(again.init.snapshotJson, isNull);
        expect(again.init.ops!.map((o) => o.revision), [2]);
        await again.close();
      },
    );

    test(
      'when updating the page setup then connected clients get MetaChanged',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        await endpoints.document.updateMeta(
          anna.endpointSession,
          item.contentRef!,
          DocumentMetaPatch(field: 'pageSetup', valueJson: '{"size":"a4"}'),
          const Uuid().v7obj(),
        );
        final meta = await c.next<DocMetaChanged>();
        final info = await endpoints.document.getInfo(
          anna.endpointSession,
          item.contentRef!,
        );

        expect(meta.field, 'pageSetup');
        expect(info.meta.pageSetupJson, '{"size":"a4"}');
        await c.close();
      },
    );

    test(
      'when sending a ping then a pong with the same value arrives',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );

        c.send(DocPing(t: 42));
        final pong = await c.next<DocPong>();

        expect(pong.t, 42);
        await c.close();
      },
    );

    test('when checking the hash then it matches the server content', () async {
      final c = await TestDocClient.connect(endpoints, anna, item.contentRef!);
      c.edit(Delta()..insert('Hash me'));
      await c.processUntilSynchronized();

      c.send(
        DocHashCheck(revision: c.revision, sha256: documentHash(c.document)),
      );
      final result = await c.next<DocHashResult>();

      expect(result.matches, isTrue);
      await c.close();
    });
  });

  withWonkyServerpod('Given two editors on one document', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser bo;
    late DriveItemView item;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      bo = await TestUsers.create(sessionBuilder, name: 'Bo');
      item = await TestDrive.document(endpoints, anna, name: 'Pair');
      await TestDrive.share(endpoints, item, anna, bo, AccessRole.editor);
    });

    test('when one submits then the other receives the remote op', () async {
      final a = await TestDocClient.connect(endpoints, anna, item.contentRef!);
      final b = await TestDocClient.connect(endpoints, bo, item.contentRef!);

      a.edit(Delta()..insert('Hi Bo'));
      await a.processUntilSynchronized();
      await b.catchUpTo(1);

      expect(_text(b.document), 'Hi Bo\n');
      await a.close();
      await b.close();
    });

    test(
      'when the second joins then the first sees ParticipantJoined',
      () async {
        final a = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final b = await TestDocClient.connect(endpoints, bo, item.contentRef!);

        final joined = await a.next<DocParticipantJoined>();

        expect(joined.participant.userId, bo.id);
        expect(b.init.participants.map((p) => p.userId).toSet(), {
          anna.id,
          bo.id,
        });
        await a.close();
        await b.close();
      },
    );

    test(
      'when both edit concurrently then both converge with the server',
      () async {
        final a = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final b = await TestDocClient.connect(endpoints, bo, item.contentRef!);

        // Concurrent edits on the same base revision, plus buffered follow-ups.
        a.edit(Delta()..insert('Anna '));
        b.edit(Delta()..insert('Bo '));
        a.edit(
          Delta()
            ..retain(5)
            ..insert('again '),
        );
        b.edit(
          Delta()
            ..retain(3)
            ..insert('too '),
        );
        await Future.wait([
          a.processUntilSynchronized(),
          b.processUntilSynchronized(),
        ]);
        final server = await _serverContent(endpoints, anna, item.contentRef!);
        final head = (await endpoints.document.getInfo(
          anna.endpointSession,
          item.contentRef!,
        )).headRevision;
        await a.catchUpTo(head);
        await b.catchUpTo(head);

        expect(DeltaUtils.equals(a.document, server), isTrue);
        expect(DeltaUtils.equals(b.document, server), isTrue);
        expect(
          _text(server).split(RegExp(r'\s+')).toSet(),
          containsAll(['Anna', 'Bo', 'again', 'too']),
        );
        await a.close();
        await b.close();
      },
    );

    test('when many ops interleave then all replicas converge', () async {
      final a = await TestDocClient.connect(endpoints, anna, item.contentRef!);
      final b = await TestDocClient.connect(endpoints, bo, item.contentRef!);

      for (var i = 0; i < 10; i++) {
        a.edit(Delta()..insert('a$i'));
        b.edit(Delta()..insert('b$i'));
        if (i.isEven) {
          final len = DeltaUtils.documentLength(b.document);
          if (len > 3) {
            b.edit(
              Delta()
                ..retain(1)
                ..delete(1),
            );
          }
        }
        await a.processOne();
        await b.processOne();
      }
      await Future.wait([
        a.processUntilSynchronized(),
        b.processUntilSynchronized(),
      ]);
      final head = (await endpoints.document.getInfo(
        anna.endpointSession,
        item.contentRef!,
      )).headRevision;
      await a.catchUpTo(head);
      await b.catchUpTo(head);
      final server = await _serverContent(endpoints, anna, item.contentRef!);

      expect(DeltaUtils.equals(a.document, server), isTrue);
      expect(DeltaUtils.equals(b.document, server), isTrue);
      await a.close();
      await b.close();
    });

    test(
      'when sending a cursor then the other receives RemoteCursor',
      () async {
        final a = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        final b = await TestDocClient.connect(endpoints, bo, item.contentRef!);

        a.send(DocCursorUpdate(revision: 0, anchor: 0, head: 0, focused: true));
        final cursor = await b.next<DocRemoteCursor>();

        expect(cursor.userId, anna.id);
        await a.close();
        await b.close();
      },
    );

    test(
      'when the editor is downgraded to viewer then RoleChanged arrives and ops are refused',
      () async {
        final b = await TestDocClient.connect(endpoints, bo, item.contentRef!);

        await endpoints.sharing.updateRole(
          anna.endpointSession,
          item.uuid,
          bo.id,
          AccessRole.viewer,
        );
        final changed = await b.next<DocRoleChanged>();
        b.submitRaw(TestDrive.insertAt(0, 'x'));
        final rejected = await b.next<DocOpRejected>();

        expect(changed.role, AccessRole.viewer);
        expect(rejected.code, DocRejectCode.forbiddenForRole);
        await b.close();
      },
    );
  });

  withWonkyServerpod('Given a commenter on a document', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser carl;
    late DriveItemView item;
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      carl = await TestUsers.create(sessionBuilder, name: 'Carl');
      item = await TestDrive.document(endpoints, anna, markdown: 'Hello world');
      await TestDrive.share(endpoints, item, anna, carl, AccessRole.commenter);
    });

    test(
      'when inserting plain text then the op is rejected for the role',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          carl,
          item.contentRef!,
        );

        c.submitRaw(TestDrive.insertAt(0, 'Hack '));
        final rejected = await c.next<DocOpRejected>();

        expect(rejected.code, DocRejectCode.forbiddenForRole);
        await c.close();
      },
    );

    test('when adding a comment anchor then it is accepted', () async {
      final c = await TestDocClient.connect(endpoints, carl, item.contentRef!);
      final threadUuid = const Uuid().v7obj();
      await endpoints.comment.createThread(
        carl.endpointSession,
        threadUuid,
        item.uuid,
        CommentAnchorKind.textRange,
        '{"v":1}',
        'Hello',
        'Nice',
        const [],
        null,
      );

      c.submitRaw(
        jsonEncode([
          {
            'retain': 5,
            'attributes': {'cmt_${threadUuid.uuid}': true},
          },
        ]),
      );
      final ack = await c.next<DocAck>();

      expect(ack.revision, greaterThan(c.init.revision));
      await c.close();
    });

    test(
      'when suggesting an insertion then a suggestion thread is created',
      () async {
        final c = await TestDocClient.connect(
          endpoints,
          carl,
          item.contentRef!,
        );
        const suggestionId = 's1';

        c.submitRaw(
          jsonEncode([
            {
              'insert': 'Big ',
              'attributes': {
                'sug_$suggestionId': {
                  't': 'ins',
                  'by': carl.authUserId.uuid,
                  'at': 0,
                },
              },
            },
          ]),
        );
        await c.next<DocAck>();
        await c.sideEffectsDone();
        final threads = await endpoints.comment.listThreads(
          anna.endpointSession,
          item.uuid,
          CommentFilter.all,
        );

        expect(threads.map((t) => t.uuid), [
          OverlayLifecycle.suggestionThreadUuid(item.contentRef!, suggestionId),
        ]);
        expect(threads.single.createdBy?.id, carl.id);
        await c.close();
      },
    );

    test('when a viewer connects then submitting is refused', () async {
      final vic = await TestUsers.create(sessionBuilder, name: 'Vic');
      await TestDrive.share(endpoints, item, anna, vic, AccessRole.viewer);
      final c = await TestDocClient.connect(endpoints, vic, item.contentRef!);

      c.submitRaw(TestDrive.insertAt(0, 'x'));
      final rejected = await c.next<DocOpRejected>();

      expect(c.init.role, AccessRole.viewer);
      expect(rejected.code, DocRejectCode.forbiddenForRole);
      await c.close();
    });
  });

  withWonkyServerpod('Given a comment anchored in a document', (
    sessionBuilder,
    endpoints,
  ) {
    test(
      'when the anchored text is deleted then the thread is orphaned and revives on undo',
      () async {
        final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
        final item = await TestDrive.document(
          endpoints,
          anna,
          markdown: 'Hello world',
        );
        final threadUuid = const Uuid().v7obj();
        await endpoints.comment.createThread(
          anna.endpointSession,
          threadUuid,
          item.uuid,
          CommentAnchorKind.textRange,
          '{"v":1}',
          'Hello',
          'About hello',
          const [],
          null,
        );
        final c = await TestDocClient.connect(
          endpoints,
          anna,
          item.contentRef!,
        );
        c.edit(Delta()..retain(5, {'cmt_${threadUuid.uuid}': true}));
        await c.processUntilSynchronized();
        final before = c.document;

        final deletion = Delta()..delete(5);
        c.edit(deletion);
        await c.processUntilSynchronized();
        final orphaned = await endpoints.comment.getThread(
          anna.endpointSession,
          threadUuid,
        );
        c.edit(WonkyOt.invert(deletion, before));
        await c.processUntilSynchronized();
        final revived = await endpoints.comment.getThread(
          anna.endpointSession,
          threadUuid,
        );

        expect(orphaned.status, CommentStatus.orphaned);
        expect(revived.status, CommentStatus.open);
        await c.close();
      },
    );
  });

  withWonkyServerpod('Given the document permission matrix', (
    sessionBuilder,
    endpoints,
  ) {
    for (final (role, allowed) in [
      (AccessRole.viewer, true),
      (null, false),
    ]) {
      test(
        'when connecting with ${role?.name ?? 'no access'} then it is ${allowed ? 'allowed' : 'refused'}',
        () async {
          final anna = await TestUsers.create(sessionBuilder, name: 'Anna');
          final bo = await TestUsers.create(sessionBuilder, name: 'Bo');
          final item = await TestDrive.document(endpoints, anna);
          if (role != null) {
            await TestDrive.share(endpoints, item, anna, bo, role);
          }

          final connect = TestDocClient.connect(
            endpoints,
            bo,
            item.contentRef!,
          );

          if (allowed) {
            await (await connect).close();
          } else {
            await expectLater(connect, throwsA(isA<WonkyException>()));
          }
        },
      );
    }
  });
}
