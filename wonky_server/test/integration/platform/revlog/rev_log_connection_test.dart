@Tags(['integration'])
library;

import 'dart:async';

import 'package:async/async.dart';
import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/platform/revlog/rev_bus.dart';
import 'package:wonky_server/src/platform/revlog/rev_hooks.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_connection.dart';
import 'package:wonky_server/src/platform/revlog/rev_log_service.dart';
import 'package:wonky_server/src/platform/revlog/rev_views.dart';

import '../../../support/test_drive.dart';
import '../../../support/test_users.dart';
import '../../../support/wonky_serverpod.dart';
import 'support/test_rev_binding.dart';

/// A test client of one `RevLogConnection`.
final class _Client {
  _Client._(this.input, this.messages);

  final StreamController<RevClientMessage> input;
  final StreamQueue<RevServerMessage> messages;

  static Future<_Client> open(
    TestUser user,
    UuidValue fileUuid, {
    int known = 0,
  }) async {
    final input = StreamController<RevClientMessage>();
    final out = RevLogConnection.open(
      user.session,
      TestRevBinding.instance,
      user.actor,
      fileUuid,
      known,
      'tab-${user.name}',
      input.stream,
    );
    return _Client._(input, StreamQueue(out));
  }

  Future<T> next<T extends RevServerMessage>() async {
    final m = await messages.next.timeout(const Duration(seconds: 10));
    if (m is! T) throw StateError('expected $T, got $m');
    return m;
  }

  void submit(List<RowChange> changes, int base, {String? id}) => input.add(
    RevSubmit(
      clientOpId: UuidValue.fromString(id ?? const Uuid().v7()),
      baseRevision: base,
      payload: TestRevBinding.instance.codec.encodeText(changes),
      label: 'Edit',
      actorKind: ActorKind.user,
      groupIndex: 0,
      groupLast: true,
      offline: false,
      createdAt: clock.now().toUtc(),
    ),
  );

  Future<void> close() async {
    await input.close();
    await messages.cancel(immediate: true);
  }
}

void main() {
  withWonkyServerpod('Given a RevLog file with two collaborators', (
    sessionBuilder,
    endpoints,
  ) {
    late TestUser anna;
    late TestUser ben;
    late DriveItem item;
    late TestFileIds ids;
    final clients = <_Client>[];

    setUpAll(() async {
      await createTestTables(sessionBuilder.build());
      RevHooks.debounce = const Duration(hours: 1);
    });
    setUp(() async {
      anna = await TestUsers.create(sessionBuilder, name: 'Anna');
      ben = await TestUsers.create(sessionBuilder, name: 'Ben');
      final session = sessionBuilder.build();
      item = await testItem(session, anna, 'Plan');
      ids = TestFileIds(item.uuid.uuid);
      await RevLogService.createFile(
        session,
        binding: TestRevBinding.instance,
        item: item,
        submitter: submitterOf(anna),
        initialChanges: ids.creation(),
      );
    });
    tearDown(() async {
      for (final c in clients) {
        await c.close();
      }
      clients.clear();
      await RevHooks.idle();
    });

    Future<_Client> open(TestUser u, {int known = 0}) async {
      final c = await _Client.open(u, item.uuid, known: known);
      clients.add(c);
      return c;
    }

    Future<void> share(TestUser with_, AccessRole role) async =>
        TestDrive.share(
          endpoints,
          await endpoints.drive.get(anna.endpointSession, item.uuid),
          anna,
          with_,
          role,
        );

    test('when a client connects at 0 then it is told to bootstrap', () async {
      final a = await open(anna);
      final init = await a.next<RevInit>();
      expect(init.revision, 1);
      expect(init.bootstrap, isTrue);
      expect(init.role, AccessRole.owner);
      expect(init.schemaHash, testRevSchema.hash);
    });

    test(
      'when a client connects behind the head then it gets the missing ops',
      () async {
        final a = await open(anna);
        await a.next<RevInit>();
        a.submit([ids.setCell(0, 0, 'one')], 1);
        expect((await a.next<RevAck>()).revision, 2);
        final late = await open(anna, known: 1);
        final init = await late.next<RevInit>();
        expect(init.bootstrap, isFalse);
        expect(init.ops!.map((o) => o.revision), [2]);
        final applied = RevViews.appliedOf(
          TestRevBinding.instance.codec,
          init.ops!.single,
        );
        expect(applied.single.columnsAfter['content'], 'one');
      },
    );

    test(
      'when one client submits then it gets the ack and the other the remote op',
      () async {
        await share(ben, AccessRole.editor);
        final a = await open(anna, known: 1);
        final b = await open(ben, known: 1);
        await a.next<RevInit>();
        await b.next<RevInit>();
        final id = const Uuid().v7();
        a.submit([ids.setCell(1, 1, 'hi')], 1, id: id);
        final ack = await a.next<RevAck>();
        expect(ack.clientOpId.uuid, id);
        expect(ack.applied, isNull, reason: 'applied as submitted');
        final remote = await b.next<RevRemoteOp>();
        expect(remote.op.revision, ack.revision);
        expect(remote.op.authorUuid, anna.authUserId);
        // The sender never receives its own op.
        a.input.add(RevPing(t: 7));
        final pong = await a.next<RevPong>();
        expect(pong.headRevision, ack.revision);
      },
    );

    test('when an op is resent then the ack says duplicate', () async {
      final a = await open(anna, known: 1);
      await a.next<RevInit>();
      final id = const Uuid().v7();
      a.submit([ids.setCell(2, 0, 'x')], 1, id: id);
      final first = await a.next<RevAck>();
      a.submit([ids.setCell(2, 0, 'x')], 1, id: id);
      final second = await a.next<RevAck>();
      expect(second.duplicate, isTrue);
      expect(second.revision, first.revision);
    });

    test(
      'when the server changes the op then the ack carries the applied form',
      () async {
        final a = await open(anna, known: 1);
        await a.next<RevInit>();
        final rowId = ids.rows[3];
        a.submit([ids.setCell(3, 0, 'a')], 1);
        await a.next<RevAck>();
        a.submit([
          RowChange.delete('rl_row', rowId, {'sheetId': ids.sheet}),
        ], 2);
        final ack = await a.next<RevAck>();
        expect(
          ack.applied,
          isNotNull,
          reason: 'the unlisted cell was cascaded',
        );
        final applied = TestRevBinding.instance.codec.decodeText(ack.applied!);
        expect(applied.changes.map((c) => c.table), contains('rl_cell'));
        expect(ack.outcome, contains('cascaded'));
      },
    );

    test('when a viewer submits then the op is rejected', () async {
      await share(ben, AccessRole.viewer);
      final b = await open(ben, known: 1);
      final init = await b.next<RevInit>();
      expect(init.role, AccessRole.viewer);
      b.submit([ids.setCell(0, 2, 'no')], 1);
      final r = await b.next<RevRejected>();
      expect(r.code, RevRejectCode.forbiddenForRole);
    });

    test('when a client asks for ops then it receives them', () async {
      final a = await open(anna, known: 1);
      await a.next<RevInit>();
      a.submit([ids.setCell(0, 0, 'r2')], 1);
      await a.next<RevAck>();
      a.input.add(RevRequestOps(fromRevision: 1, toRevision: 2));
      final r1 = await a.next<RevRemoteOp>();
      final r2 = await a.next<RevRemoteOp>();
      expect([r1.op.revision, r2.op.revision], [1, 2]);
    });

    test(
      'when access is removed then the stream ends with forbidden',
      () async {
        await share(ben, AccessRole.editor);
        final b = await open(ben, known: 1);
        await b.next<RevInit>();
        await endpoints.sharing.remove(anna.endpointSession, item.uuid, ben.id);
        await RevBus.rolesChanged(sessionBuilder.build(), item.uuid);
        final r = await b.next<RevRejected>();
        expect(r.code, RevRejectCode.forbidden);
        expect(r.clientOpId, isNull);
      },
    );
  });
}
