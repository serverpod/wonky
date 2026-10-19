import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:wonky_client/wonky_client.dart' as api;
import 'package:wonky_revlog/client.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_revlog/testing.dart';

import '../transport/rev_transport.dart';

/// An in-process RevLog server for client tests (RevLog spec 09 §1): one
/// [FakeRevServer] per file (the same pure apply rules as the real
/// server), shared by the [FakeRevTransport]s of several users.
///
/// Files are created by the first connection (as the drive create does
/// with `initialize: false`), so a client's creation op is the file's first
/// op. Messages are delivered asynchronously, in order.
final class FakeRevHub {
  /// Creates a hub for [schema].
  FakeRevHub(this.schema) : _codec = RevCodec(schema);

  /// The schema of every file.
  final RevSchema schema;
  final RevCodec _codec;
  final Map<String, FakeRevServer> _files = {};
  final Map<(String, String), api.AccessRole> _roles = {};
  final Map<FakeRevLink, _Conn> _conns = {};

  /// The server of [fileUuid] (created when missing).
  FakeRevServer file(String fileUuid) => _files.putIfAbsent(
    fileUuid,
    () => FakeRevServer(schema, fileUuid: fileUuid),
  );

  /// Whether [fileUuid] exists.
  bool hasFile(String fileUuid) => _files.containsKey(fileUuid);

  /// The role of [userUuid] on [fileUuid] (default editor).
  api.AccessRole roleOf(String userUuid, String fileUuid) =>
      _roles[(userUuid, fileUuid)] ?? api.AccessRole.editor;

  /// Sets the role of [userUuid] on [fileUuid] and tells open connections.
  void setRole(String userUuid, String fileUuid, api.AccessRole role) {
    _roles[(userUuid, fileUuid)] = role;
    final f = _files[fileUuid];
    if (f == null) return;
    f.setReadOnly(userUuid, readOnly: role.index < api.AccessRole.editor.index);
    for (final c in _conns.values) {
      if (c.link.server == f && c.link.userId == userUuid) {
        c.out.add(api.RevRoleChanged(role: role));
      }
    }
  }

  /// A transport of [userUuid].
  FakeRevTransport transport(String userUuid) =>
      FakeRevTransport._(this, userUuid);

  /// Open connections (tests).
  int get connections => _conns.length;

  /// Commits [op] by [userUuid] directly (a fixture, or another client's
  /// write) and fans it out; returns the revision, or throws the
  /// rejection.
  int commit(String fileUuid, String userUuid, ChangeSet op) {
    final server = file(fileUuid);
    final link = server.connect(userUuid, server.head)..toClient.clear();
    try {
      link.toServer.add(op);
      server.processNext(link);
      final reply = link.toClient.removeLast();
      _flush();
      return switch (reply) {
        FakeAck(:final ack) => ack.revision,
        FakeRejected(:final rejection) => throw rejection,
        _ => throw StateError('unexpected $reply'),
      };
    } finally {
      link.close();
    }
  }

  /// Drops every connection of [userUuid] (a lost network); the clients
  /// reconnect on their own.
  void dropConnections(String userUuid) {
    for (final c in [..._conns.values]) {
      if (c.link.userId == userUuid) c.close(error: true);
    }
  }

  api.RevOpView _view(RevOpIn op) {
    final packed = RevCodec.pack(
      _codec.encodeText(op.applied, withBefore: false),
    );
    return api.RevOpView(
      revision: op.revision,
      clientOpId: api.UuidValue.fromString(op.clientOpId),
      payload: packed.text,
      payloadGz: packed.gz == null ? null : ByteData.sublistView(packed.gz!),
      authorUuid: op.authorUuid == null
          ? null
          : api.UuidValue.fromString(op.authorUuid!),
      authorSessionId: op.sessionId,
      actorKind: api.ActorKind.values.byName(op.actorKind),
      label: op.label,
      summaryJson: op.summary == null ? null : jsonEncode(op.summary),
      detailJson: op.detail == null ? null : jsonEncode(op.detail),
      offline: op.offline,
      groupId: op.groupId,
      groupIndex: op.groupIndex,
      groupLast: op.groupLast,
      outcomeJson: op.outcome == null ? null : jsonEncode(op.outcome),
      committedAt: op.committedAt,
    );
  }

  api.RevServerMessage _message(FakeRevLink link, FakeServerMessage m) =>
      switch (m) {
        FakeInit() => api.RevInit(
          revision: m.revision,
          role: roleOf(link.userId, link.server.fileUuid),
          sessionId: link.sessionId,
          schemaHash: schema.hash,
          acceptedHashes: [schema.hash],
          stats: '{}',
          prunedBelow: 0,
          ops: m.ops?.map(_view).toList(),
          more: false,
          bootstrap: m.bootstrap,
        ),
        FakeAck(:final ack) => api.RevAck(
          clientOpId: api.UuidValue.fromString(ack.clientOpId),
          revision: ack.revision,
          duplicate: ack.duplicate,
          applied: ack.applied == null
              ? null
              : _codec.encodeText(ack.applied!, withBefore: false),
          outcome: ack.outcome == null ? null : jsonEncode(ack.outcome),
        ),
        FakeRemote(:final op) => api.RevRemoteOp(op: _view(op)),
        FakeRejected() => api.RevRejected(
          clientOpId: api.UuidValue.fromString(m.clientOpId),
          code: api.RevRejectCode.values.byName(m.rejection.reason.name),
          message: m.rejection.message,
          detailsJson: m.rejection.details == null
              ? null
              : jsonEncode(m.rejection.details),
        ),
      };

  /// Moves every queued server message to its connection's stream.
  void _flush() {
    for (final c in _conns.values) {
      while (c.link.toClient.isNotEmpty) {
        c.out.add(_message(c.link, c.link.toClient.removeFirst()));
      }
    }
  }

  ChangeSet _decodeSubmit(api.RevSubmit s) {
    final p = _codec.decodeText(
      RevCodec.unpack(
        text: s.payload,
        gz: s.payloadGz?.buffer.asUint8List(
          s.payloadGz!.offsetInBytes,
          s.payloadGz!.lengthInBytes,
        ),
      ),
    );
    return ChangeSet(
      clientOpId: s.clientOpId.uuid,
      baseRevision: s.baseRevision,
      changes: p.changes,
      label: s.label,
      actorKind: s.actorKind.name,
      summary: p.summary,
      detail: p.detail,
      groupId: s.groupId,
      groupIndex: s.groupIndex,
      groupLast: s.groupLast,
      offline: s.offline,
      createdAt: s.createdAt,
    );
  }

  /// All rows of [server] as (table, row with `id`).
  Iterable<(String, Map<String, Object?>)> _rows(
    FakeRevServer server,
    bool Function(RevTable) include,
  ) sync* {
    for (final t in schema.tables) {
      if (!include(t)) continue;
      final rows = server.state.rows[t.name];
      if (rows == null) continue;
      final ids = rows.keys.toList()..sort();
      for (final id in ids) {
        yield (t.name, {...rows[id]!, RowChange.idColumn: id});
      }
    }
  }

  api.RevPage _page(String fileUuid, api.RevPageRequest r) {
    final server = file(fileUuid);
    final List<(String, Map<String, Object?>)> rows;
    final List<String> coverage;
    switch (r.kind) {
      case api.RevPageKind.structure:
        bool structure(RevTable t) => t.coverage == RevCoverage.structure;
        rows = _rows(server, structure).toList();
        coverage = [
          for (final t in schema.tables)
            if (structure(t)) 'tbl:${t.name}:-:+',
        ];
      case api.RevPageKind.rows:
        rows = _rows(server, (t) => t.name == r.table).toList();
        coverage = ['tbl:${r.table}:-:+'];
      case api.RevPageKind.cells:
        final table = schema.tables.firstWhere(
          (t) => t.coverage == RevCoverage.cellsByRow,
        );
        final sheet = r.sheetId!.uuid;
        final wanted = {for (final id in r.rowIds!) id.uuid};
        final scope = table.parents.first.column;
        final key = table.parents[1].column;
        rows = [
          for (final row in _rows(server, (t) => t == table))
            if (row.$2[scope] == sheet && wanted.contains(row.$2[key])) row,
        ];
        coverage = [for (final id in wanted) 'row:$sheet:$id'];
    }
    return api.RevPage(
      revision: server.head,
      // The format the client asked for, as the server negotiates it.
      body: ByteData.sublistView(
        RevPageCodec.negotiate(r.format) == RevPageCodec.version
            ? RevPageCodec.encode(schema, rows)
            : RevPageCodec.encodeLegacy(schema, rows),
      ),
      coverage: coverage,
      excludedTables: const [],
    );
  }
}

final class _Conn {
  _Conn(this.link, this.out);

  final FakeRevLink link;
  final StreamController<api.RevServerMessage> out;
  StreamSubscription<api.RevClientMessage>? input;

  void close({bool error = false}) {
    link.close();
    unawaited(input?.cancel());
    if (error && !out.isClosed) {
      out.addError(StateError('connection lost'));
    }
    unawaited(out.close());
  }
}

/// The [RevTransport] of one user on a [FakeRevHub].
final class FakeRevTransport implements RevTransport {
  FakeRevTransport._(this.hub, this.userUuid);

  /// The hub.
  final FakeRevHub hub;

  /// The user.
  final String userUuid;

  /// When false, [connect], [page], [ops] and [info] fail like a network
  /// error.
  bool reachable = true;

  /// Awaited before a page is served (lets a test hold pages back).
  Future<void> Function(api.RevPageRequest request)? beforePage;

  void _check() {
    if (!reachable) throw StateError('server unreachable');
  }

  @override
  Stream<api.RevServerMessage> connect(
    api.UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<api.RevClientMessage> input,
  ) {
    late final _Conn conn;
    final out = StreamController<api.RevServerMessage>(
      onCancel: () {
        hub._conns.remove(conn.link);
        conn.close();
      },
    );
    if (!reachable) {
      out.addError(StateError('server unreachable'));
      unawaited(out.close());
      return out.stream;
    }
    final server = hub.file(fileUuid.uuid);
    conn = _Conn(server.connect(userUuid, knownRevision), out);
    hub._conns[conn.link] = conn;
    conn.input = input.listen((m) {
      if (!conn.link.open) return;
      switch (m) {
        case api.RevSubmit():
          conn.link.toServer.add(hub._decodeSubmit(m));
          server.processNext(conn.link);
        case api.RevRequestOps():
          for (final op in server.opsRange(m.fromRevision, m.toRevision)) {
            conn.link.toClient.add(FakeRemote(op));
          }
        case api.RevPing():
          out.add(api.RevPong(t: m.t, headRevision: server.head));
      }
      hub._flush();
    });
    scheduleMicrotask(hub._flush);
    return out.stream;
  }

  @override
  Future<api.RevPage> page(
    api.UuidValue fileUuid,
    api.RevPageRequest request,
  ) async {
    _check();
    await beforePage?.call(request);
    _check();
    return hub._page(fileUuid.uuid, request);
  }

  @override
  Future<List<api.RevOpView>> ops(
    api.UuidValue fileUuid,
    int from,
    int to,
  ) async {
    _check();
    return [
      for (final op in hub.file(fileUuid.uuid).opsRange(from + 1, to))
        hub._view(op),
    ];
  }

  @override
  Future<api.RevFileInfo> info(api.UuidValue fileUuid) async {
    _check();
    final f = hub.file(fileUuid.uuid);
    return api.RevFileInfo(
      fileUuid: fileUuid,
      revision: f.head,
      role: hub.roleOf(userUuid, fileUuid.uuid),
      schemaHash: hub.schema.hash,
      stats: '{}',
    );
  }
}
