import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show SimpleConnectionKeeper;
import 'package:wonky_client/wonky_client.dart'
    show DriveItemKind, Uuid, UuidValue;
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/codec.dart' show ChangeSet;
import 'package:wonky_revlog/rows.dart' show RowChange;
import 'package:wonky_revlog_flutter/testing.dart';
import 'package:wonky_revlog_flutter/wonky_revlog_flutter.dart';
import 'package:wonky_slides/features/model/deck_session.dart';
import 'package:wonky_slides/features/revlog/logged_deck_session.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/planner.dart' show SlidesPlanner;
import 'package:wonky_slides_core/revlog.dart' show slidesSchema;

export 'package:wonky_revlog_flutter/testing.dart' show FakeRevHub;

const planner = SlidesPlanner();

/// A hub of Slides files (RevLog spec 09 §1).
FakeRevHub slidesHub() => FakeRevHub(slidesSchema);

/// The creation changes of a blank deck [file].
List<RowChange> deckCreation(UuidValue file, UuidValue user) => planner
    .plan(
      CreateDeck(deckId: file.uuid, title: 'Deck'),
      DeckModel(deckId: file.uuid),
      SlidesPlanContext(
        userId: user.uuid,
        now: DateTime.utc(2026, 10, 1),
        isOwner: true,
      ),
    )
    .changes;

/// Commits [changes] to [file] on the hub as [user] (a fixture or another
/// device's write).
int commitChanges(
  FakeRevHub hub,
  UuidValue file,
  UuidValue user,
  List<RowChange> changes, {
  String label = 'Edit',
}) => hub.commit(
  file.uuid,
  user.uuid,
  ChangeSet(
    clientOpId: const Uuid().v7(),
    baseRevision: hub.file(file.uuid).head,
    changes: changes,
    label: label,
  ),
);

/// One user's device with the Slides RevLog client: a cache in a temporary
/// directory, a connection keeper and a fake transport.
final class DeckDevice {
  DeckDevice._(this.user, this.client, this.transport, this.keeper);

  /// Opens a device of [user] on [hub].
  static Future<DeckDevice> start(FakeRevHub hub, UuidValue user) async {
    final dir = await Directory.systemTemp.createTemp('wonky_slides_rev_');
    final store = await RevLocalStore.open(
      schema: slidesSchema,
      userUuid: user.uuid,
      app: 'slides',
      directory: dir.path,
    );
    final keeper = SimpleConnectionKeeper(
      minDelay: const Duration(milliseconds: 10),
      maxDelay: const Duration(milliseconds: 50),
    );
    final transport = hub.transport(user.uuid);
    final client = RevLogClient(
      app: 'slides',
      schema: slidesSchema,
      store: store,
      transport: transport,
      keeper: keeper,
      kind: DriveItemKind.presentation,
    );
    final d = DeckDevice._(user, client, transport, keeper);
    addTearDown(() async {
      await d.close();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });
    return d;
  }

  final UuidValue user;
  final RevLogClient client;
  final FakeRevTransport transport;
  final SimpleConnectionKeeper keeper;
  final List<LoggedDeckSession> _sessions = [];
  bool _closed = false;

  /// Creates a blank deck [file] on this device (offline first) and opens
  /// it.
  Future<LoggedDeckSession> create(UuidValue file) async {
    await client.createLocal(
      file.uuid,
      ChangeSet(
        clientOpId: const Uuid().v7(),
        baseRevision: 0,
        changes: deckCreation(file, user),
        label: 'Create presentation',
      ),
    );
    return openFile(file, role: Role.owner);
  }

  /// Opens [file] (and waits until it is ready unless [waitReady] is
  /// false).
  Future<LoggedDeckSession> openFile(
    UuidValue file, {
    Role role = Role.editor,
    bool waitReady = true,
    Duration maintenanceDelay = const Duration(milliseconds: 20),
  }) async {
    final s = LoggedDeckSession.open(
      client,
      itemUuid: file,
      fileUuid: file,
      userId: user.uuid,
      planner: planner,
      role: role,
      maintenanceDelay: maintenanceDelay,
    );
    _sessions.add(s);
    await s.opened;
    if (waitReady) await whenReady(s);
    return s;
  }

  /// Simulates losing / regaining the network.
  set online(bool v) {
    transport.reachable = v;
    keeper.online = v;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    for (final s in _sessions) {
      if (!s.isDisposed) await s.dispose();
    }
    await client.close();
    keeper.dispose();
  }
}

/// Completes when [s] is ready (fails after [timeout]).
Future<void> whenReady(
  DeckSession s, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  if (s.loadState.value is DeckReady) return;
  final c = Completer<void>();
  void check() {
    final v = s.loadState.value;
    if (c.isCompleted) return;
    if (v is DeckReady) c.complete();
    if (v is DeckUnavailable && !v.offline) {
      c.completeError(StateError(v.reason));
    }
  }

  s.loadState.addListener(check);
  try {
    check();
    await c.future.timeout(timeout);
  } finally {
    s.loadState.removeListener(check);
  }
}

/// Polls [check] until it holds (fails after [timeout]).
Future<void> eventually(
  bool Function() check, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final watch = Stopwatch()..start();
  while (!check()) {
    if (watch.elapsed > timeout) fail('Condition not met within $timeout');
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
