import 'dart:math';

import 'package:uuid/uuid.dart';

import '../apply/apply_rules.dart';
import '../apply/overlay.dart';
import '../apply/validation.dart';
import '../codec/change_set.dart';
import '../codec/rev_codec.dart';
import '../client/rev_sync_core.dart';
import '../rows/row_change.dart';
import '../schema/rev_schema.dart';
import 'fake_rev_server.dart';

/// A model over a [MapRowStore] (tests).
final class MapModel implements CurrentRowReader {
  /// Creates the model.
  MapModel([MapRowStore? store]) : store = store ?? MapRowStore();

  /// Rows.
  final MapRowStore store;

  @override
  Map<String, Object?>? currentColumns(String table, String rowId) =>
      store.row(table, rowId);

  /// Applies model changes literally (inserts are upserts of full rows).
  void apply(List<RowChange> changes) {
    for (final c in changes) {
      switch (c.op) {
        case RowOp.insert:
          store.put(c.table, c.rowId, {
            ...c.columnsAfter,
            RowChange.idColumn: c.rowId,
          });
        case RowOp.update:
          final cur = store.row(c.table, c.rowId);
          if (cur != null) {
            store.put(c.table, c.rowId, {...cur, ...c.columnsAfter});
          }
        case RowOp.delete:
          store.remove(c.table, c.rowId);
      }
    }
  }
}

/// A client of [FakeRevServer]: [RevSyncCore] + [RevOverlay] + a model and a
/// server-state cache, like a real session (RevLog spec 06).
final class RevTestReplica implements RevSyncHost {
  /// Creates a replica for [userId].
  RevTestReplica(this.server, this.userId, {Random? random})
    : random = random ?? Random(0),
      overlay = RevOverlay(server.schema) {
    core = RevSyncCore(
      host: this,
      codec: RevCodec(server.schema),
      newId: () => const Uuid().v7(),
    );
  }

  /// The server.
  final FakeRevServer server;

  /// User id.
  final String userId;

  /// Randomness (durability delays).
  final Random random;

  /// The model (server state + outbox).
  final MapModel model = MapModel();

  /// Cached server state.
  final MapRowStore serverCache = MapRowStore();

  /// Overlay.
  final RevOverlay overlay;

  /// The core.
  late final RevSyncCore core;

  /// The current link.
  FakeRevLink? link;

  /// Rejections received.
  final List<RevRejection> rejections = [];

  /// Outcomes of acked ops.
  final List<Map<String, Object?>> outcomes = [];

  /// Whether durability is confirmed at once (else on [flushDurable]).
  bool autoDurable = true;
  final List<String> _pendingDurable = [];

  /// Schema.
  RevSchema get schema => server.schema;

  /// Connects (RevInit is delivered by [pump]).
  void connect() {
    link?.close();
    link = server.connect(userId, core.serverRevision);
    core.connectedStream();
  }

  /// Drops the connection.
  void disconnect() {
    link?.close();
    link = null;
    core.disconnected();
  }

  /// A local edit: [changes] as a planner would produce them for the model.
  void edit(List<RowChange> changes, {String label = 'Edit', String? groupId}) {
    overlay.captureLocal(changes, model);
    model.apply(changes);
    core.submitLocal(changes, label: label, groupId: groupId);
  }

  /// Confirms pending durability (when [autoDurable] is false).
  void flushDurable() {
    final ids = List.of(_pendingDurable);
    _pendingDurable.clear();
    core.markDurable(ids);
  }

  /// Processes [max] incoming messages (all when null).
  void pump({int? max}) {
    final l = link;
    if (l == null) return;
    var n = 0;
    while (l.toClient.isNotEmpty && (max == null || n < max)) {
      n++;
      switch (l.toClient.removeFirst()) {
        case FakeInit(:final revision, :final ops, :final bootstrap):
          core.init(revision, ops: ops, bootstrap: bootstrap);
        case FakeAck(:final ack):
          core.ack(ack);
        case FakeRemote(:final op):
          core.remoteOp(op);
        case FakeRejected(:final clientOpId, :final rejection):
          core.rejected(clientOpId, rejection);
      }
    }
  }

  /// Emulates a pong carrying the server head.
  void pong() => core.headSeen(server.head);

  // ------------------------------------------------------------ RevSyncHost

  @override
  void persistOutbox(List<ChangeSet> outbox) {
    final ids = outbox.map((o) => o.clientOpId);
    if (autoDurable) {
      core.markDurable(ids);
    } else {
      _pendingDurable.addAll(ids);
    }
  }

  @override
  void sendOp(ChangeSet op) => link?.toServer.add(op);

  @override
  void requestOps(int from, int to) {
    final l = link;
    if (l == null) return;
    for (final op in server.opsRange(from, to)) {
      l.toClient.add(FakeRemote(op));
    }
  }

  @override
  void applyRemote(RevOpIn op) {
    model.apply(overlay.remote(op.applied, core.outbox, model));
    replayApplied(serverCache, op.applied);
  }

  @override
  void applyAck(ChangeSet op, RevAckIn ack, List<RowChange> applied) {
    model.apply(overlay.acked(op, applied, core.outbox, model));
    replayApplied(serverCache, applied);
    if (ack.outcome != null) outcomes.add(ack.outcome!);
  }

  @override
  void applyRejected(List<ChangeSet> ops, RevRejection rejection) {
    rejections.add(rejection);
    model.apply(overlay.rejected(ops, core.outbox, model));
  }

  @override
  void bootstrap(int revision) {
    // Full download (the fake has no pages): server state at its head.
    serverCache.rows
      ..clear()
      ..addAll(server.state.copy().rows);
    overlay.clear();
    final rebuilt = MapModel(serverCache.copy());
    for (final op in core.outbox) {
      for (final c in op.changes) {
        overlay.seed(c.table, c.rowId, serverCache.row(c.table, c.rowId));
      }
      applyChanges(schema, rebuilt.store, op.changes, cascade: false);
    }
    model.store.rows
      ..clear()
      ..addAll(rebuilt.store.rows);
    core.bootstrapped(server.head);
  }
}
