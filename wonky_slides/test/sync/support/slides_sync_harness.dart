import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serverpod_offline_sync_client/serverpod_offline_sync_client.dart'
    show
        OfflineSyncClient,
        OfflineSyncDatabaseSession,
        OfflineSyncPeerMode,
        OfflineSyncTransport;
import 'package:wonky_app/wonky_app.dart' show OfflineException;
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides/features/sync/deck_remote_patch.dart';
import 'package:wonky_slides/features/sync/slides_remote.dart';
import 'package:wonky_slides/features/sync/slides_replica.dart';
import 'package:wonky_slides/features/sync/slides_session_host.dart';
import 'package:wonky_slides/features/sync/slides_sync_controller.dart';
import 'package:wonky_slides/features/sync/slides_writer.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;

/// Test support of the Slides data layer (Slides 12 §7.3 in miniature, as
/// Sheets' `test/sync/support`): replicas on temporary files, a fake
/// session host, an in-process sync "server" (an authoritative offline-sync
/// peer on its own SQLite file) with its remote, and model helpers.

/// Test users of the local replicas.
final testUser = UuidValue.fromString('0190a000-0000-7000-8000-0000000000aa');
final otherUser = UuidValue.fromString('0190a000-0000-7000-8000-0000000000bb');

/// The production planner.
const planner = SlidesPlanner();

/// A fixed planning time (deterministic rows).
final testNow = DateTime.utc(2026, 10, 1, 9);

/// Opens a replica on a temporary file (closed and deleted after the test).
/// No server is involved: memberships are granted with [grantLocally].
Future<SlidesReplica> openTestReplica({UuidValue? user}) async {
  final dir = await Directory.systemTemp.createTemp('wonky_slides_replica_');
  final replica = await SlidesReplica.open(
    client: Client('http://localhost:1/'),
    path: '${dir.path}/slides.db',
    userUuid: user ?? testUser,
  );
  addTearDown(() async {
    await replica.close();
    await dir.delete(recursive: true);
  });
  return replica;
}

String hexOf(UuidValue u) => [
  for (final b in Uint8List.fromList(u.toBytes()))
    b.toRadixString(16).padLeft(2, '0'),
].join();

/// Puts [space] into the replica's membership cache, as a sync cycle does
/// after `slides.subscribe` / `reserveSpaces`.
Future<void> grantLocally(
  SlidesReplica replica,
  UuidValue space, {
  String role = 'readWrite',
}) async {
  final db = replica.db;
  // One transaction: an open session reading the membership between the
  // delete and the insert would see it removed and close the deck (a
  // flaky "still opening" instead of the role change under test).
  await db.transaction((tx) async {
    await db.unsafeExecute(
      'INSERT OR IGNORE INTO "offline_sync_spaces" ("uuidSpaceId") '
      "VALUES (x'${hexOf(space)}')",
      transaction: tx,
    );
    await db.unsafeExecute(
      'DELETE FROM "offline_sync_space_members" WHERE "userUuid" = '
      "x'${hexOf(replica.userUuid)}' AND \"spaceId\" = (SELECT \"id\" FROM "
      "\"offline_sync_spaces\" WHERE \"uuidSpaceId\" = x'${hexOf(space)}')",
      transaction: tx,
    );
    await db.unsafeExecute(
      'INSERT INTO "offline_sync_space_members" ("spaceId", "userUuid", '
      "\"role\") SELECT \"id\", x'${hexOf(replica.userUuid)}', '$role' FROM "
      "\"offline_sync_spaces\" WHERE \"uuidSpaceId\" = x'${hexOf(space)}'",
      transaction: tx,
    );
  });
}

/// Removes [space] from the membership cache (unshared).
Future<void> revokeLocally(SlidesReplica replica, UuidValue space) =>
    replica.db.unsafeExecute(
      'DELETE FROM "offline_sync_space_members" WHERE "spaceId" = (SELECT '
      "\"id\" FROM \"offline_sync_spaces\" WHERE \"uuidSpaceId\" = "
      "x'${hexOf(space)}')",
    );

/// A planning context for [user].
SlidesPlanContext contextFor(UuidValue user) =>
    SlidesPlanContext(userId: user.uuid, now: testNow, isOwner: true);

/// Writes a new deck into [space] (granted first) like
/// `createLocalPresentation`, returning the plan.
Future<SlidesPlan> createDeck(
  SlidesReplica replica,
  UuidValue space, {
  String title = 'Test deck',
}) async {
  await grantLocally(replica, space);
  final plan = planner.plan(
    CreateDeck(deckId: space.uuid, title: title),
    DeckModel(deckId: space.uuid),
    contextFor(replica.userUuid),
  );
  await SlidesWriter(replica).write(
    spaceId: space,
    changes: plan.changes,
    plan: plan,
    label: plan.label,
    actorKind: 'user',
    sessionId: 'test',
  );
  return plan;
}

/// A model of [space] read back from the replica (the "full reload").
Future<DeckModel> reloadModel(SlidesReplica replica, UuidValue space) async {
  final key = await replica.spaceKey(space);
  return DeckModel.fromRows(space.uuid, await replica.loadSpace(key!));
}

/// Plans [op] against the replica's current state of [space] and writes it
/// as another device's merge would (no session involved).
Future<SlidesPlan> writeOp(
  SlidesReplica replica,
  UuidValue space,
  SlidesOperation Function(DeckModel m) op, {
  String sessionId = 'remote',
}) async {
  final m = await reloadModel(replica, space);
  final plan = planner.plan(op(m), m, contextFor(replica.userUuid));
  await SlidesWriter(replica).write(
    spaceId: space,
    changes: plan.changes,
    plan: plan,
    label: plan.label,
    actorKind: 'user',
    sessionId: sessionId,
  );
  return plan;
}

/// Canonical, comparable rows of a model: one line per row, columns sorted,
/// nulls dropped (a planner insert names fewer columns than a replica row),
/// numbers as doubles, times in milliseconds.
List<String> canonical(DeckModel model) {
  Object? norm(Object? v) => switch (v) {
    num() => v.toDouble(),
    DateTime() => v.toUtc().millisecondsSinceEpoch,
    Enum() => v.name,
    _ => v,
  };
  return [
    for (final (table, columns) in DeckRemotePatch.modelRows(model))
      '$table ${(columns.keys.where((k) => columns[k] != null).toList()..sort()).map((k) => '$k=${norm(columns[k])}').join(' ')}',
  ]..sort();
}

/// A [SlidesSessionHost] on a local replica without a server.
class FakeSessionHost implements SlidesSessionHost {
  FakeSessionHost(this.replica, {bool online = false})
    : writer = SlidesWriter(replica),
      online = ValueNotifier(online);

  @override
  final SlidesReplica replica;

  @override
  final SlidesWriter writer;

  @override
  final ValueNotifier<bool> online;

  @override
  String get sessionId => 'test-session';

  final StreamController<UuidValue> mergesController =
      StreamController.broadcast();

  @override
  Stream<UuidValue> get merges => mergesController.stream;

  /// What `subscribe` returns (null = throws offline).
  SubscribeResult? subscribeResult;

  /// Thrown by `subscribe` (access refused), when set.
  Exception? subscribeError;
  int subscribeCalls = 0;
  int kicks = 0;

  @override
  Future<SubscribeResult> subscribe(UuidValue itemUuid) async {
    subscribeCalls++;
    final error = subscribeError;
    if (error != null) throw error;
    final r = subscribeResult;
    if (r == null || !online.value) throw const SlidesOfflineException();
    return r;
  }

  @override
  Future<SpaceStats> spaceStats(UuidValue itemUuid) async =>
      subscribeResult?.stats ?? (throw const SlidesOfflineException());

  @override
  void kick() => kicks++;

  @override
  void journalCursorsChanged() {}
}

/// A subscribe result for [space] with [role].
SubscribeResult subscribed(
  UuidValue space, {
  AccessRole role = AccessRole.editor,
  bool alreadyMember = true,
  int totalRows = 1,
}) => SubscribeResult(
  spaceUuid: space,
  role: role,
  canWrite: role == AccessRole.editor || role == AccessRole.owner,
  alreadyMember: alreadyMember,
  stats: SpaceStats(
    spaceUuid: space,
    rowCounts: const {},
    totalRows: totalRows,
    sheetCount: 1,
    cellCount: 0,
    gridCells: 0,
  ),
);

/// Polls [condition] (real async work: SQLite runs in a worker).
Future<void> eventually(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('Condition not met in $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// An in-process "server": an authoritative offline-sync peer on its own
/// SQLite file. Devices sync with it through [transport] like they do with
/// `slidesSync.sync`; membership is granted with [grant] (what
/// `slides.subscribe`, `reserveSpaces` and sharing do on the real server).
class FakeSlidesServer {
  FakeSlidesServer._(this.session);

  static Future<FakeSlidesServer> open() async {
    final dir = await Directory.systemTemp.createTemp('wonky_slides_server_');
    final session = await Client(
      'http://localhost:1/',
    ).createSyncSession('${dir.path}/server.db');
    addTearDown(() async {
      await session.close();
      await dir.delete(recursive: true);
    });
    return FakeSlidesServer._(session);
  }

  final OfflineSyncDatabaseSession session;

  /// Grants [user] membership of [space] with [role] (an existing
  /// membership's role is updated in place: like the real server, a grant
  /// never leaves a moment without membership — a sync that observed one
  /// would drop the space from the device's membership cache and hide its
  /// rows).
  Future<void> grant(
    UuidValue user,
    UuidValue space, {
    String role = 'readWrite',
  }) async {
    final db = session.db;
    await db.initialize();
    await db.unsafeExecute(
      'INSERT OR IGNORE INTO "offline_sync_spaces" ("uuidSpaceId") '
      "VALUES (x'${hexOf(space)}')",
    );
    final member =
        '"userUuid" = x\'${hexOf(user)}\' AND "spaceId" = (SELECT "id" FROM '
        '"offline_sync_spaces" WHERE "uuidSpaceId" = x\'${hexOf(space)}\')';
    await db.unsafeExecute(
      'UPDATE "offline_sync_space_members" SET "role" = \'$role\' '
      'WHERE $member',
    );
    await db.unsafeExecute(
      'INSERT INTO "offline_sync_space_members" ("spaceId", "userUuid", "role") '
      "SELECT \"id\", x'${hexOf(user)}', '$role' FROM "
      "\"offline_sync_spaces\" WHERE \"uuidSpaceId\" = x'${hexOf(space)}' "
      'AND NOT EXISTS (SELECT 1 FROM "offline_sync_space_members" '
      'WHERE $member)',
    );
  }

  /// [user]'s role in [space] (null = not a member).
  Future<String?> roleOf(UuidValue user, UuidValue space) async {
    final rows = await session.db.unsafeQuery(
      'SELECT m."role" FROM "offline_sync_space_members" m '
      'JOIN "offline_sync_spaces" s ON s."id" = m."spaceId" '
      "WHERE m.\"userUuid\" = x'${hexOf(user)}' "
      "AND s.\"uuidSpaceId\" = x'${hexOf(space)}'",
    );
    return rows.isEmpty ? null : rows.first[0] as String?;
  }

  /// Removes [user]'s membership of [space].
  Future<void> revoke(UuidValue user, UuidValue space) =>
      session.db.unsafeExecute(
        'DELETE FROM "offline_sync_space_members" WHERE "userUuid" = '
        "x'${hexOf(user)}' AND \"spaceId\" = (SELECT \"id\" FROM "
        "\"offline_sync_spaces\" WHERE \"uuidSpaceId\" = x'${hexOf(space)}')",
      );

  /// The stream transport of [user].
  OfflineSyncTransport transport(UuidValue user) =>
      ({required changes, required once}) => session.db.sync(
        inbound: changes,
        mode: OfflineSyncPeerMode.authoritative,
        userId: user,
        once: once,
      );
}

/// [SlidesRemote] on a [FakeSlidesServer]. [offline] makes every call fail
/// like a network error.
class FakeRemote implements SlidesRemote {
  FakeRemote(this.server, this.user)
    : sync = OfflineSyncClient(
        ({required changes, required once}) =>
            server.transport(user)(changes: changes, once: once),
      );

  final FakeSlidesServer server;
  final UuidValue user;

  @override
  final OfflineSyncClient sync;

  bool offline = false;
  final List<List<UuidValue>> ensureCalls = [];
  static int _next = 0x100;

  /// The role [subscribe] grants.
  AccessRole subscribeRole = AccessRole.editor;

  void _check() {
    if (offline) throw const OfflineException('fake offline');
  }

  @override
  Future<List<UuidValue>> reserveSpaces(int count) async {
    _check();
    final out = <UuidValue>[];
    for (var i = 0; i < count; i++) {
      final space = UuidValue.fromString(
        '0190a000-0000-7000-8000-${(_next++).toRadixString(16).padLeft(12, '0')}',
      );
      await server.grant(user, space);
      out.add(space);
    }
    return out;
  }

  @override
  Future<SubscribeResult> subscribe(UuidValue itemUuid) async {
    _check();
    final write =
        subscribeRole == AccessRole.editor || subscribeRole == AccessRole.owner;
    // As the real server (`SpaceService.subscribe`): grants only when the
    // role differs.
    final wanted = write ? 'readWrite' : 'readOnly';
    final existing = await server.roleOf(user, itemUuid);
    if (existing != wanted) await server.grant(user, itemUuid, role: wanted);
    return subscribed(
      itemUuid,
      role: subscribeRole,
      alreadyMember: existing != null,
    );
  }

  @override
  Future<SpaceStats> spaceStats(UuidValue itemUuid) async =>
      (await subscribe(itemUuid)).stats;

  @override
  Future<List<UuidValue>> ensureSubscribed(List<UuidValue> spaces) async {
    _check();
    ensureCalls.add(spaces);
    return spaces;
  }

  /// Spaces whose `unsubscribe` keeps the membership (owned).
  final Set<UuidValue> owned = {};
  final List<UuidValue> unsubscribeCalls = [];

  @override
  Future<void> unsubscribe(UuidValue itemUuid) async {
    _check();
    unsubscribeCalls.add(itemUuid);
    if (!owned.contains(itemUuid)) await server.revoke(user, itemUuid);
  }
}

/// [SlidesConnectivity] for tests.
class FakeConnectivity implements SlidesConnectivity {
  FakeConnectivity({bool online = true}) : online = ValueNotifier(online);

  @override
  final ValueNotifier<bool> online;

  @override
  void reportFailure() => online.value = false;

  @override
  void reportSuccess() {}
}

/// A controller of [user] on a fresh replica syncing with [server].
Future<(SlidesSyncController, FakeRemote, FakeConnectivity)> openDevice(
  FakeSlidesServer server,
  UuidValue user,
) async {
  final remote = FakeRemote(server, user);
  final net = FakeConnectivity();
  final c = SlidesSyncController(
    replica: await openTestReplica(user: user),
    remote: remote,
    connectivity: net,
    planner: planner,
  );
  addTearDown(c.stop);
  return (c, remote, net);
}

/// One reservation pool, usable on [c] (sync → reserve → sync).
Future<void> prepareReservations(SlidesSyncController c) async {
  await c.syncNow();
  await c.refillReservations();
  await c.syncNow();
}
