import 'dart:collection';
import 'dart:math';

import '../apply/apply_rules.dart';
import '../apply/validation.dart';
import '../codec/change_set.dart';
import '../client/rev_sync_core.dart';
import '../rows/row_change.dart';
import '../schema/rev_schema.dart';

/// A server → client message of the fake transport.
sealed class FakeServerMessage {
  const FakeServerMessage();
}

/// RevInit.
final class FakeInit extends FakeServerMessage {
  /// Creates the message.
  const FakeInit(this.revision, this.ops, {this.bootstrap = false});

  /// Head.
  final int revision;

  /// Tail ops, or null with [bootstrap].
  final List<RevOpIn>? ops;

  /// Re-bootstrap needed.
  final bool bootstrap;
}

/// RevAck.
final class FakeAck extends FakeServerMessage {
  /// Creates the message.
  const FakeAck(this.ack);

  /// The ack.
  final RevAckIn ack;
}

/// RevRemoteOp.
final class FakeRemote extends FakeServerMessage {
  /// Creates the message.
  const FakeRemote(this.op);

  /// The op.
  final RevOpIn op;
}

/// RevRejected.
final class FakeRejected extends FakeServerMessage {
  /// Creates the message.
  const FakeRejected(this.clientOpId, this.rejection);

  /// The op.
  final String clientOpId;

  /// Why.
  final RevRejection rejection;
}

/// One connection of [FakeRevServer].
final class FakeRevLink {
  FakeRevLink._(this.server, this.userId, this.sessionId);

  /// The server.
  final FakeRevServer server;

  /// Connected user.
  final String userId;

  /// Session id.
  final String sessionId;

  /// Pending server → client messages (in order).
  final Queue<FakeServerMessage> toClient = Queue();

  /// Pending client → server ops (in order).
  final Queue<ChangeSet> toServer = Queue();

  /// Whether the link is open.
  bool open = true;

  /// Closes the link (pending messages are lost).
  void close() {
    open = false;
    toClient.clear();
    toServer.clear();
    server._links.remove(this);
  }
}

/// An in-memory RevLog sequencer for tests (RevLog spec 09 §1): the same
/// pure apply rules as the real server, total order by revision, acks,
/// fan-out to other links with optional message loss (lost bus messages).
final class FakeRevServer {
  /// Creates a server for one file.
  FakeRevServer(this.schema, {required this.fileUuid, MapRowStore? initial})
    : state = initial ?? MapRowStore();

  /// Schema.
  final RevSchema schema;

  /// The file id.
  final String fileUuid;

  /// Materialized state.
  final MapRowStore state;

  /// Committed ops, index = revision - 1.
  final List<RevOpIn> log = [];

  final Map<String, RevAckIn> _byClientOp = {};
  final List<FakeRevLink> _links = [];
  final Set<String> _readOnly = {};
  int _session = 0;

  /// Head revision.
  int get head => log.length;

  /// Makes [userId] a viewer (submits are rejected).
  void setReadOnly(String userId, {bool readOnly = true}) =>
      readOnly ? _readOnly.add(userId) : _readOnly.remove(userId);

  /// Opens a connection at [knownRevision].
  FakeRevLink connect(String userId, int knownRevision) {
    final link = FakeRevLink._(this, userId, 's${_session++}');
    _links.add(link);
    if (knownRevision == head) {
      link.toClient.add(FakeInit(head, const []));
    } else if (knownRevision > head ||
        knownRevision == 0 ||
        head - knownRevision > 1000) {
      // Like the server: a first open always loads pages.
      link.toClient.add(FakeInit(head, null, bootstrap: true));
    } else {
      link.toClient.add(FakeInit(head, opsSince(knownRevision)));
    }
    return link;
  }

  /// Ops in (from, head].
  List<RevOpIn> opsSince(int from) => [
    for (var r = from + 1; r <= head; r++) log[r - 1],
  ];

  /// Ops in [from, to].
  List<RevOpIn> opsRange(int from, int to) => [
    for (var r = max(1, from); r <= min(to, head); r++) log[r - 1],
  ];

  /// Commits the next pending op of [link]; fan-out to other links drops
  /// messages with probability [dropRate].
  void processNext(FakeRevLink link, {Random? random, double dropRate = 0}) {
    if (link.toServer.isEmpty) return;
    final cs = link.toServer.removeFirst();
    final dup = _byClientOp[cs.clientOpId];
    if (dup != null) {
      link.toClient.add(
        FakeAck(
          RevAckIn(
            clientOpId: cs.clientOpId,
            revision: dup.revision,
            applied: dup.applied,
            outcome: dup.outcome,
            duplicate: true,
          ),
        ),
      );
      return;
    }
    try {
      if (_readOnly.contains(link.userId)) {
        throw RevRejection(RevRejectReason.forbiddenForRole, 'read only');
      }
      validateChangeSet(
        schema,
        cs,
        fromClient: true,
        isCreation: head == 0,
        fileUuid: fileUuid,
      );
      final result = applyChangeSet(schema, state, cs);
      final applied = [
        for (final c in result.applied)
          c.op == RowOp.update
              ? RowChange.update(c.table, c.rowId, const {}, c.columnsAfter)
              : c,
      ];
      final outcome = <String, Object?>{
        if (result.dropped.isNotEmpty)
          'dropped': [
            for (final d in result.dropped)
              {
                't': d.change.table,
                'id': d.change.rowId,
                'reason': d.reason.name,
              },
          ],
        if (result.cascaded.isNotEmpty)
          'cascaded': [
            for (final c in result.cascaded) {'t': c.table, 'id': c.rowId},
          ],
      };
      final op = RevOpIn(
        revision: head + 1,
        clientOpId: cs.clientOpId,
        applied: applied,
        authorUuid: link.userId,
        sessionId: link.sessionId,
        actorKind: cs.actorKind,
        label: cs.label,
        summary: cs.summary,
        detail: cs.detail,
        offline: cs.offline,
        groupId: cs.groupId,
        groupIndex: cs.groupIndex,
        groupLast: cs.groupLast,
        outcome: outcome.isEmpty ? null : outcome,
      );
      log.add(op);
      final ack = RevAckIn(
        clientOpId: cs.clientOpId,
        revision: op.revision,
        applied: result.equalsSubmitted ? null : applied,
        outcome: op.outcome,
      );
      _byClientOp[cs.clientOpId] = ack;
      for (final other in _links) {
        if (other == link) continue;
        if (random != null && random.nextDouble() < dropRate) continue;
        other.toClient.add(FakeRemote(op));
      }
      link.toClient.add(FakeAck(ack));
    } on RevRejection catch (e) {
      link.toClient.add(FakeRejected(cs.clientOpId, e));
    }
  }

  /// Commits every pending op of every link.
  void processAll() {
    var progress = true;
    while (progress) {
      progress = false;
      for (final link in List.of(_links)) {
        if (link.toServer.isNotEmpty) {
          processNext(link);
          progress = true;
        }
      }
    }
  }

  /// Open links.
  List<FakeRevLink> get links => List.unmodifiable(_links);
}
