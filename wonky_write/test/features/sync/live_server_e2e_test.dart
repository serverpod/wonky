@Tags(['e2e'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    show
        AuthSuccess,
        ClientAuthSessionManager,
        ClientAuthSessionManagerExtension,
        ClientAuthSuccessStorage;
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_write/features/sync/document_sync_controller.dart';
import 'package:wonky_write/features/sync/sync_transport.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'support/fake_document_server.dart' show DeltaHost;

/// Runs against the server started with `serverpod start` (API on
/// localhost:8080): `flutter test -t e2e --run-skipped
/// test/features/sync/live_server_e2e_test.dart`.
const _api = String.fromEnvironment(
  'WONKY_API',
  defaultValue: 'http://localhost:8080/',
);

class _MemoryAuth implements ClientAuthSuccessStorage {
  AuthSuccess? _v;
  @override
  Future<AuthSuccess?> get() async => _v;
  @override
  Future<void> set(AuthSuccess? data) async => _v = data;
}

Future<Client> _signUp(String email, String name) async {
  final c = Client(_api)
    ..authSessionManager = ClientAuthSessionManager(storage: _MemoryAuth());
  final password = 'Wk-${Random.secure().nextInt(1 << 32)}-e2e!';
  final request = await c.emailIdp.startRegistration(email: email);
  final code = await c.e2eSupport.latestVerificationCode(email);
  final token = await c.emailIdp.verifyRegistrationCode(
    accountRequestId: request,
    verificationCode: code!,
  );
  final success = await c.emailIdp.finishRegistration(
    registrationToken: token,
    password: password,
  );
  await c.auth.updateSignedInUser(success);
  await c.user.getMe();
  await c.user.updateProfile(displayName: name);
  return c;
}

class _Replica {
  _Replica(this.client, UuidValue doc)
    : keeper = SimpleConnectionKeeper(
        minDelay: const Duration(milliseconds: 50),
      ),
      host = DeltaHost() {
    sync = DocumentSyncController(
      transport: ServerDocumentSyncTransport(client, doc),
      host: host,
      keeper: keeper,
    );
    sync.events.listen(events.add);
  }

  final Client client;
  final SimpleConnectionKeeper keeper;
  final DeltaHost host;
  late final DocumentSyncController sync;
  final List<SyncEvent> events = [];

  Future<void> start() async {
    sync.start();
    await _until(() => sync.isLoaded);
  }

  void insert(int at, String text, [Map<String, dynamic>? attrs]) => host.edit(
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

Future<void> _until(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(end)) throw TimeoutException('condition');
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

Future<Delta> _head(Client c, UuidValue doc) async {
  final s = await c.document.getSnapshot(doc, null);
  return Delta.fromJson(jsonDecode(s.deltaJson) as List);
}

Future<void> _settle(List<_Replica> replicas, Client c, UuidValue doc) async {
  for (final r in replicas) {
    await r.sync.whenSynchronized().timeout(const Duration(seconds: 20));
  }
  final head = (await c.document.getInfo(doc)).headRevision;
  await _until(() => replicas.every((r) => r.sync.revision == head));
}

void main() {
  final run = DateTime.now().millisecondsSinceEpoch;
  late Client anna;
  late Client bo;
  late Client cy;
  late DriveItemView item;
  late UuidValue doc;

  setUpAll(() async {
    anna = await _signUp('anna.$run@example.test', 'Anna');
    bo = await _signUp('bo.$run@example.test', 'Bo');
    cy = await _signUp('cy.$run@example.test', 'Cy');
    item = await anna.drive.createDocument(
      null,
      'Sync e2e $run',
      null,
      'Hello world',
    );
    doc = item.contentRef!;
    await anna.sharing.share(
      item.uuid,
      ['bo.$run@example.test'],
      AccessRole.editor,
      false,
      null,
      null,
    );
    await anna.sharing.share(
      item.uuid,
      ['cy.$run@example.test'],
      AccessRole.commenter,
      false,
      null,
      null,
    );
  });

  test(
    'Given two editors on the live server when both type concurrently then they converge',
    () async {
      final a = _Replica(anna, doc);
      final b = _Replica(bo, doc);
      await a.start();
      await b.start();
      final random = Random(7);
      for (var i = 0; i < 60; i++) {
        final r = random.nextBool() ? a : b;
        final len = DeltaUtils.documentLength(r.host.doc);
        r.insert(
          random.nextInt(len),
          String.fromCharCode(97 + random.nextInt(26)),
        );
        if (i % 7 == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 15));
        }
      }
      await _settle([a, b], anna, doc);

      final head = await _head(anna, doc);
      expect(a.host.doc, head);
      expect(b.host.doc, head);
      expect(DeltaUtils.documentLength(head), greaterThan(60));
      await a.dispose();
      await b.dispose();
    },
  );

  test(
    'Given an editor going offline when both keep typing and it reconnects then they converge',
    () async {
      final a = _Replica(anna, doc);
      final b = _Replica(bo, doc);
      await a.start();
      await b.start();

      b.keeper.online = false;
      await Future<void>.delayed(const Duration(milliseconds: 100));
      a.insert(0, 'A-online ');
      b.insert(0, 'B-offline ');
      b.insert(0, 'more ');
      await a.sync.whenSynchronized();
      b.keeper.online = true;
      await _settle([a, b], anna, doc);

      final head = await _head(anna, doc);
      expect(a.host.doc, head);
      expect(b.host.doc, head);
      expect(DeltaUtils.text(head), contains('B-offline'));
      await a.dispose();
      await b.dispose();
    },
  );

  test(
    'Given a commenter when suggesting then the server stamps the time and replicas agree',
    () async {
      final a = _Replica(anna, doc);
      final c = _Replica(cy, doc);
      await a.start();
      await c.start();
      final me = (await cy.user.getMe()).summary.uuid.uuid;

      c.insert(0, 'Maybe ', {
        'sug_e2e$run': {'t': 'ins', 'by': me, 'at': 1},
      });
      await _settle([a, c], anna, doc);

      final head = await _head(anna, doc);
      expect(c.host.doc, head);
      expect(a.host.doc, head);
      final mark = head.operations.first.attributes!['sug_e2e$run'] as Map;
      expect(mark['at'], isNot(1));

      // A plain edit by a commenter is rejected and the replica resyncs.
      c.insert(0, 'direct ');
      await _until(() => c.events.whereType<SyncResynced>().isNotEmpty);
      await _settle([a, c], anna, doc);
      expect(c.host.doc, await _head(anna, doc));
      expect(DeltaUtils.text(c.host.doc), isNot(contains('direct')));

      // The editor accepts the suggestion.
      a.host.edit(a.sync, SuggestionOps.accept(a.host.doc, {'e2e$run'}));
      await _settle([a, c], anna, doc);
      expect(SuggestionIndex.list(c.host.doc), isEmpty);
      await a.dispose();
      await c.dispose();
    },
  );

  test(
    'Given a comment anchor added by one editor then the other sees the thread anchored',
    () async {
      final a = _Replica(anna, doc);
      final b = _Replica(bo, doc);
      await a.start();
      await b.start();
      final thread = UuidValue.fromString(
        '019a0000-0000-7000-8000-${run.toRadixString(16).padLeft(12, '0').substring(0, 12)}',
      );
      await anna.comment.createThread(
        thread,
        item.uuid,
        CommentAnchorKind.textRange,
        '{"v":1}',
        'Hello',
        'Looks good',
        const [],
        null,
      );
      a.host.edit(a.sync, CommentAnchors.addAnchor(thread.uuid, 0, 3));
      await _settle([a, b], anna, doc);

      expect(CommentAnchors.anchorOf(b.host.doc, thread.uuid), isNotNull);
      final threads = await bo.comment.listThreads(
        item.uuid,
        CommentFilter.all,
      );
      expect(threads.map((t) => t.uuid), contains(thread));
      await a.dispose();
      await b.dispose();
    },
  );

  test(
    'Given a named version when diffing it against the start then changes are attributed',
    () async {
      final v = await anna.version.nameCurrent(item.uuid, 'e2e $run');
      final version = await anna.writeHistory.getVersionDocument(
        doc,
        v.revision!,
      );
      expect(
        DeltaUtils.text(Delta.fromJson(jsonDecode(version.deltaJson) as List)),
        DeltaUtils.text(DeltaUtils.stripOverlays(await _head(anna, doc))),
      );
      final diff = await anna.writeHistory.diff(doc, 1, v.revision!);
      expect(diff.changeCount, greaterThan(0));
      expect(diff.authors, isNotEmpty);
    },
  );
}
