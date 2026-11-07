import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_write/features/sync/document_sync_controller.dart';
import 'package:wonky_write/features/sync/sync_transport.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

/// One committed op of the [FakeDocumentServer].
class FakeOp {
  FakeOp(
    this.revision,
    this.delta,
    this.clientOpId,
    this.sessionId,
    this.userId, {
    this.onBehalfOfSessionId,
    this.groupId,
  });
  final int revision;
  final Delta delta;
  final UuidValue clientOpId;
  final String sessionId;
  final int userId;

  /// An assistant run's session and run (gap fills carry them, Write 09
  /// §5.2).
  final String? onBehalfOfSessionId;
  final String? groupId;

  bool get isAi => groupId != null;
}

/// An in-process Write OT server (Write 03 §2) for sync tests: revisions,
/// idempotent submits, server-wins transforms, normalization (including
/// suggestion timestamp stamping), acks, broadcasts, gap fills, cursors and
/// integrity checks.
///
/// With [autoDeliver] off, server → client messages wait in per-connection
/// queues until [deliverNext] / [deliverRandom] pushes them, which lets tests
/// reorder broadcasts (simulated unordered bus) and drop them.
class FakeDocumentServer {
  FakeDocumentServer({
    Delta? initial,
    this.autoDeliver = true,
    this.maxOpsInInit = 1000,
  }) : document = DeltaUtils.canonical(initial ?? (Delta()..insert('\n'))) {
    history.add(document);
  }

  Delta document;
  int get revision => ops.length;
  final List<FakeOp> ops = [];
  final List<FakeConnection> connections = [];
  final List<DocClientMessage> received = [];
  bool autoDeliver;
  int maxOpsInInit;
  int _sessions = 0;
  int nowMs = 1000000;

  /// When set, the next submit from any client is rejected with this code.
  DocRejectCode? rejectNext;

  /// Corrupts hash results (integrity test).
  bool corruptHashes = false;

  /// Submits are received but dropped (lost in transit).
  bool dropSubmits = false;

  AccessRole roleFor(int userId) => _roles[userId] ?? AccessRole.editor;
  final Map<int, AccessRole> _roles = {};

  DocumentMetaView meta = DocumentMetaView(pageSetupJson: '{}');

  FakeTransport transport({int userId = 1, String? userUuid}) => FakeTransport(
    this,
    userId,
    userUuid ?? '00000000-0000-7000-8000-00000000000$userId',
  );

  /// Documents after each revision (index = revision).
  final List<Delta> history = [];

  Delta contentAt(int rev) => history[rev];

  void setRole(int userId, AccessRole role) {
    _roles[userId] = role;
    for (final c in connections.where((c) => c.userId == userId)) {
      c.push(DocRoleChanged(role: role));
    }
  }

  void changeMeta(String field, String valueJson, {int? authorId}) {
    for (final c in connections) {
      c.push(
        DocMetaChanged(field: field, valueJson: valueJson, authorId: authorId),
        bus: true,
      );
    }
  }

  /// Commits a server-side change (another client not modelled here).
  int commitExternal(Delta change, {int userId = 99}) {
    final c = DeltaUtils.canonical(change);
    document = WonkyOt.apply(document, c);
    history.add(document);
    ops.add(
      FakeOp(
        revision + 1,
        c,
        UuidValue.fromString(_uuid(revision + 1)),
        'external',
        userId,
      ),
    );
    for (final conn in connections) {
      conn.push(_remoteOf(ops.last), bus: true);
    }
    return revision;
  }

  static String _uuid(int n) =>
      '00000000-0000-7000-9000-${n.toRadixString(16).padLeft(12, '0')}';

  DocRemoteOp _remoteOf(FakeOp o) => DocRemoteOp(
    revision: o.revision,
    deltaJson: jsonEncode(o.delta.toJson()),
    authorId: o.userId,
    authorSessionId: o.sessionId,
    actorKind: o.isAi ? ActorKind.ai : ActorKind.user,
    kind: o.isAi ? DocumentOpKind.aiEdit : DocumentOpKind.content,
    onBehalfOfSessionId: o.onBehalfOfSessionId,
    groupId: o.groupId,
  );

  DocumentOpView _viewOf(FakeOp o) => DocumentOpView(
    revision: o.revision,
    deltaJson: jsonEncode(o.delta.toJson()),
    clientOpId: o.clientOpId,
    authorId: o.userId,
    actorKind: o.isAi ? ActorKind.ai : ActorKind.user,
    kind: o.isAi ? DocumentOpKind.aiEdit : DocumentOpKind.content,
    sessionId: o.sessionId,
    onBehalfOfSessionId: o.onBehalfOfSessionId,
    groupId: o.groupId,
    createdAt: DateTime.utc(2026),
  );

  FakeConnection _connect(
    FakeTransport t,
    int knownRevision,
    Stream<DocClientMessage> input,
  ) {
    final conn = FakeConnection(this, 's${++_sessions}', t.userId, t.userUuid);
    connections.add(conn);
    conn.inputSub = input.listen((m) => _handle(conn, m));
    List<DocumentOpView>? initOps;
    String? snapshot;
    if (knownRevision > 0 &&
        knownRevision <= revision &&
        revision - knownRevision <= maxOpsInInit) {
      initOps = [for (final o in ops.skip(knownRevision)) _viewOf(o)];
    } else {
      snapshot = jsonEncode(document.toJson());
    }
    conn.push(
      DocInit(
        revision: revision,
        snapshotJson: snapshot,
        ops: initOps,
        meta: meta,
        role: roleFor(t.userId),
        sessionId: conn.sessionId,
        participants: [
          for (final c in connections)
            Participant(
              sessionId: c.sessionId,
              userId: c.userId,
              userUuid: UuidValue.fromString(c.userUuid),
              displayName: 'User ${c.userId}',
              colorIndex: c.userId % 12,
              role: roleFor(c.userId),
              actorKind: ActorKind.user,
              state: PresenceState.active,
              joinedAt: DateTime.utc(2026),
            ),
        ],
      ),
    );
    return conn;
  }

  void _handle(FakeConnection conn, DocClientMessage m) {
    if (conn.closed) return;
    received.add(m);
    switch (m) {
      case DocSubmitOp():
        if (!dropSubmits) _submit(conn, m);
      case DocRequestOps():
        for (final o in ops) {
          if (o.revision >= m.fromRevision && o.revision <= m.toRevision) {
            conn.push(_remoteOf(o));
          }
        }
      case DocCursorUpdate():
        var a = m.anchor;
        var h = m.head;
        for (final o in ops.skip(m.revision)) {
          a = WonkyOt.transformPosition(o.delta, a);
          h = WonkyOt.transformPosition(o.delta, h);
        }
        for (final c in connections) {
          if (c == conn) continue;
          c.push(
            DocRemoteCursor(
              sessionId: conn.sessionId,
              userId: conn.userId,
              revision: revision,
              anchor: a,
              head: h,
              focused: m.focused,
            ),
            bus: true,
          );
        }
      case DocPing():
        conn.push(DocPong(t: m.t));
      case DocHashCheck():
        // Only head hashes are supported by the fake (enough for tests).
        final hash = m.revision == revision ? documentHash(document) : m.sha256;
        conn.push(
          DocHashResult(
            revision: m.revision,
            sha256: hash,
            matches: !corruptHashes && hash == m.sha256,
          ),
        );
    }
  }

  void _submit(FakeConnection conn, DocSubmitOp m) {
    final dup = ops.where((o) => o.clientOpId == m.clientOpId).firstOrNull;
    if (dup != null) {
      conn.push(DocAck(clientOpId: m.clientOpId, revision: dup.revision));
      return;
    }
    void reject(DocRejectCode code, String message) => conn.push(
      DocOpRejected(clientOpId: m.clientOpId, code: code, message: message),
    );
    final forced = rejectNext;
    if (forced != null) {
      rejectNext = null;
      reject(forced, 'forced');
      return;
    }
    if (roleFor(conn.userId) == AccessRole.viewer) {
      reject(DocRejectCode.forbiddenForRole, 'viewer');
      return;
    }
    if (m.baseRevision > revision) {
      reject(DocRejectCode.unknownBase, 'unknown base');
      return;
    }
    var op = Delta.fromJson(jsonDecode(m.deltaJson) as List);
    if (m.baseRevision < revision) {
      op = WonkyOt.rebaseOnServer(op, [
        for (final o in ops.skip(m.baseRevision)) o.delta,
      ]);
    }
    if (DeltaUtils.baseLength(op) > DeltaUtils.documentLength(document)) {
      reject(DocRejectCode.invalidOp, 'does not fit');
      return;
    }
    if (roleFor(conn.userId) == AccessRole.commenter) {
      final violation = OpShapeValidator.validateCommenterOp(
        document,
        op,
        conn.userUuid,
      );
      if (violation != null) {
        reject(DocRejectCode.forbiddenForRole, violation.message);
        return;
      }
    }
    final NormalizeChangeResult normalized;
    try {
      normalized = const WonkyDeltaNormalizer().normalizeChange(
        document,
        op,
        suggestionTimestamp: nowMs++,
      );
    } catch (e) {
      reject(DocRejectCode.invalidOp, '$e');
      return;
    }
    if (!const WonkyDeltaValidator().validate(normalized.document).isValid) {
      reject(DocRejectCode.invalidOp, 'invalid result');
      return;
    }
    document = normalized.document;
    history.add(document);
    final committed = FakeOp(
      revision + 1,
      normalized.change,
      m.clientOpId,
      conn.sessionId,
      conn.userId,
    );
    ops.add(committed);
    conn.push(DocAck(clientOpId: m.clientOpId, revision: committed.revision));
    for (final c in connections) {
      if (c != conn) c.push(_remoteOf(committed), bus: true);
    }
  }

  /// Delivers the next queued message of [conn] (in order).
  bool deliverNext(FakeConnection conn) {
    if (conn.pending.isEmpty || conn.closed) return false;
    final (m, _) = conn.pending.removeAt(0);
    conn.out.add(m);
    return true;
  }

  /// Delivers every queued message in order.
  void deliverAll() {
    var progress = true;
    while (progress) {
      progress = false;
      for (final c in [...connections]) {
        while (deliverNext(c)) {
          progress = true;
        }
      }
    }
  }

  bool get hasPending =>
      connections.any((c) => !c.closed && c.pending.isNotEmpty);

  /// Delivers one random message: direct messages keep their order, bus
  /// messages may overtake anything; [dropRate] of bus messages are lost.
  bool deliverRandom(Random random, {double dropRate = 0}) {
    final open = [
      for (final c in connections)
        if (!c.closed && c.pending.isNotEmpty) c,
    ];
    if (open.isEmpty) return false;
    final conn = open[random.nextInt(open.length)];
    final candidates = <int>[];
    for (var i = 0; i < conn.pending.length; i++) {
      final (_, bus) = conn.pending[i];
      if (bus) {
        candidates.add(i);
      } else {
        candidates.add(i);
        break;
      }
    }
    final index = candidates[random.nextInt(candidates.length)];
    final (m, bus) = conn.pending.removeAt(index);
    if (bus && random.nextDouble() < dropRate) return true;
    conn.out.add(m);
    return true;
  }

  Future<List<DocumentOpView>> getOps(int from, int to) async => [
    for (final o in ops)
      if (o.revision >= from && o.revision <= to) _viewOf(o),
  ];

  Future<DocumentSnapshotView> getSnapshot() async => DocumentSnapshotView(
    revision: revision,
    deltaJson: jsonEncode(document.toJson()),
  );
}

/// One `document.connect` session of the fake server.
class FakeConnection {
  FakeConnection(this.server, this.sessionId, this.userId, this.userUuid) {
    out = StreamController<DocServerMessage>(onCancel: close);
  }

  final FakeDocumentServer server;
  final String sessionId;
  final int userId;
  final String userUuid;
  late final StreamController<DocServerMessage> out;
  StreamSubscription<DocClientMessage>? inputSub;
  final List<(DocServerMessage, bool)> pending = [];
  bool closed = false;

  void push(DocServerMessage m, {bool bus = false}) {
    if (closed) return;
    if (server.autoDeliver) {
      out.add(m);
    } else {
      pending.add((m, bus));
    }
  }

  /// Closes the connection from the server side.
  Future<void> close() async {
    if (closed) return;
    closed = true;
    pending.clear();
    server.connections.remove(this);
    await inputSub?.cancel();
    if (!out.isClosed) unawaited(out.close());
  }
}

/// The client's view of the [FakeDocumentServer].
class FakeTransport implements DocumentSyncTransport {
  FakeTransport(this.server, this.userId, this.userUuid);

  final FakeDocumentServer server;
  final int userId;
  final String userUuid;
  FakeConnection? last;
  int getOpsCalls = 0;
  bool failGetOps = false;

  @override
  Stream<DocServerMessage> connect(
    int knownRevision,
    Stream<DocClientMessage> input,
  ) {
    final c = server._connect(this, knownRevision, input);
    last = c;
    return c.out.stream;
  }

  @override
  Future<List<DocumentOpView>> getOps(int fromRevision, int toRevision) {
    getOpsCalls++;
    if (failGetOps) return Future.error(StateError('offline'));
    return server.getOps(fromRevision, toRevision);
  }

  @override
  Future<DocumentSnapshotView> getSnapshot() => server.getSnapshot();
}

/// A plain-Delta [SyncDocumentHost] for tests.
class DeltaHost implements SyncDocumentHost {
  Delta doc = Delta()..insert('\n');
  final List<(Delta, RemoteChangeInfo)> applied = [];
  int resets = 0;

  @override
  Delta get localDocument => doc;

  @override
  void applyRemoteChange(Delta change, RemoteChangeInfo info) {
    doc = WonkyOt.apply(doc, change);
    applied.add((change, info));
  }

  @override
  void resetDocument(Delta document) {
    doc = document;
    resets++;
  }

  /// Makes a local edit and returns the change.
  Delta edit(DocumentSyncController sync, Delta change) {
    doc = WonkyOt.apply(doc, change);
    sync.submitLocal(change);
    return change;
  }
}

/// Lets streams and microtasks run.
Future<void> pump([int turns = 3]) async {
  for (var i = 0; i < turns; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
