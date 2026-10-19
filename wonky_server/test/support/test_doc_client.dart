import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_server/src/platform/common/models.dart';
import 'package:wonky_server/src/write/ot/document_cache.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'streams.dart';
import 'test_users.dart';
import 'wonky_serverpod.dart';

/// A scripted Write client on `document.connect` implementing the ot.js
/// client states (Write 03 §3) so tests can check convergence.
class TestDocClient {
  TestDocClient._(this.user, this.documentUuid, this._input, this._queue);

  final TestUser user;
  final UuidValue documentUuid;
  final StreamController<DocClientMessage> _input;
  final StreamQueue<DocServerMessage> _queue;

  late DocInit init;
  late Delta document;
  late int revision;

  /// In-flight op and its id, plus the buffered local changes.
  Delta? inflight;
  UuidValue? inflightId;
  Delta? buffer;

  static Future<TestDocClient> connect(
    TestEndpoints endpoints,
    TestUser user,
    UuidValue documentUuid, {
    int knownRevision = 0,
  }) async {
    final input = StreamController<DocClientMessage>();
    final stream = endpoints.document.connect(
      user.endpointSession,
      documentUuid,
      knownRevision,
      input.stream,
    );
    final client = TestDocClient._(
      user,
      documentUuid,
      input,
      StreamQueue(stream),
    );
    final first = await client._queue.next.timeout(const Duration(seconds: 10));
    client.init = first as DocInit;
    client.revision = client.init.revision;
    client.document = client.init.snapshotJson == null
        ? Delta()
        : Delta.fromJson(jsonDecode(client.init.snapshotJson!) as List);
    return client;
  }

  void send(DocClientMessage m) => _input.add(m);

  /// Next server message of type [T] (others are skipped).
  Future<T> next<T extends DocServerMessage>() async =>
      await nextWhere(_queue, (m) => m is T) as T;

  /// Next message without skipping.
  Future<DocServerMessage> nextAny() =>
      _queue.next.timeout(const Duration(seconds: 10));

  /// Submits a raw op (bypassing the client state machine).
  UuidValue submitRaw(String deltaJson, {int? base, DocumentOpKind? kind}) {
    final id = const Uuid().v7obj();
    send(
      DocSubmitOp(
        clientOpId: id,
        baseRevision: base ?? revision,
        deltaJson: deltaJson,
        kind: kind ?? DocumentOpKind.content,
      ),
    );
    return id;
  }

  /// A local edit through the client state machine.
  void edit(Delta change) {
    document = WonkyOt.apply(document, change);
    if (inflight == null) {
      inflight = change;
      inflightId = submitRaw(jsonEncode(change.toJson()));
    } else {
      buffer = buffer == null ? change : WonkyOt.compose(buffer!, change);
    }
  }

  /// Processes server messages until the client is synchronized (no op in
  /// flight) and no further ops are pending, then waits for the server's
  /// post-commit side effects (activity, versions, comment threads), which
  /// run after the Ack.
  Future<void> processUntilSynchronized() async {
    while (inflight != null) {
      await processOne();
    }
    await sideEffectsDone();
  }

  /// Completes when the side effects of the acknowledged ops have run on
  /// the server.
  Future<void> sideEffectsDone() => DocumentCache.settle(documentUuid);

  /// Handles one Ack or RemoteOp.
  Future<void> processOne() async {
    final m = await nextWhere(
      _queue,
      (m) => m is DocAck || m is DocRemoteOp || m is DocOpRejected,
    );
    switch (m) {
      case DocAck():
        revision = m.revision;
        if (buffer != null) {
          inflight = buffer;
          buffer = null;
          inflightId = submitRaw(jsonEncode(inflight!.toJson()));
        } else {
          inflight = null;
          inflightId = null;
        }
      case DocRemoteOp():
        if (m.revision <= revision) return;
        var remote = Delta.fromJson(jsonDecode(m.deltaJson) as List);
        if (inflight != null) {
          final i = inflight!;
          inflight = WonkyOt.transform(remote, i, aWinsTies: true);
          remote = WonkyOt.transform(i, remote, aWinsTies: false);
          if (buffer != null) {
            final b = buffer!;
            buffer = WonkyOt.transform(remote, b, aWinsTies: true);
            remote = WonkyOt.transform(b, remote, aWinsTies: false);
          }
        }
        document = WonkyOt.apply(document, remote);
        revision = m.revision;
      case DocOpRejected():
        throw StateError('Op rejected: ${m.code} ${m.message}');
      default:
        break;
    }
  }

  /// Applies remote ops until [targetRevision] is reached.
  Future<void> catchUpTo(int targetRevision) async {
    while (revision < targetRevision || inflight != null) {
      await processOne();
    }
    await sideEffectsDone();
  }

  Future<void> close() async {
    await _input.close();
    await _queue.cancel(immediate: true);
  }
}
