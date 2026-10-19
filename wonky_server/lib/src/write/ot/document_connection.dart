import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart';

import '../../platform/cluster/cluster.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/common/roles.dart';
import '../../platform/common/time.dart';
import '../../platform/drive/drive_user_state.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/users/user_service.dart';
import '../themes/theme_service.dart';
import 'document_bus.dart';
import 'document_cache.dart';
import 'document_service.dart';
import 'document_store.dart';
import 'ot_service.dart';

/// One editing/viewing session of `document.connect` (Write 03 §1–2).
class DocumentConnection {
  DocumentConnection._(this.session, this.actor, this.documentUuid);

  /// Clients more than this many revisions behind get a snapshot.
  static const maxOpsInInit = 1000;

  /// Beyond this many editors, new joiners become viewers (Write 03 §7).
  /// Variable for tests, like the durations below.
  static int maxEditors = 100;

  /// With several instances (specs/13 §4) every session re-announces itself
  /// this often; participants not heard of for [participantExpiry] are
  /// dropped (their instance crashed or the `left` message was lost).
  static Duration heartbeatInterval = const Duration(seconds: 30);

  static Duration get participantExpiry => heartbeatInterval * 3;

  /// With several instances the `here` replies of sessions on other
  /// instances arrive after Init; the editor limit is re-checked once this
  /// long after joining.
  static Duration rosterSettle = const Duration(seconds: 2);

  final Session session;
  final Actor actor;
  final UuidValue documentUuid;
  final String sessionId = const Uuid().v4();

  late Document _document;
  late DriveItem _item;
  late Role _role;
  late DocumentState _state;
  late StreamController<DocServerMessage> _out;
  StreamSubscription<DocClientMessage>? _input;
  final Map<String, Participant> _participants = {};
  final Map<String, DateTime> _lastSeen = {};
  Participant? _me;

  /// Joined as a viewer because of [maxEditors]; role re-checks keep it.
  bool _limitedToViewer = false;
  Timer? _heartbeat;
  Timer? _settle;
  String? _themeChannel;
  bool _closed = false;
  Future<void>? _closing;

  /// [_state] is retained (released by [_close]).
  bool _retained = false;

  /// This session announced itself with `hello` (`left` follows on close).
  bool _announced = false;

  /// Serial queue of client messages and role re-checks. Every entry
  /// catches its errors, so one failure never stops the queue.
  Future<void> _queue = Future.value();

  /// How long closing waits for the queued side effects of the document,
  /// which use this connection's session.
  static Duration closeGrace = const Duration(seconds: 10);

  /// Tests: called with the future of each connection's start.
  static void Function(Future<void> started)? debugOnStart;

  /// Tests: called before each client message is handled (may throw to
  /// simulate an unexpected failure).
  static void Function(DocClientMessage message)? debugOnMessage;

  static Stream<DocServerMessage> open(
    Session session,
    Actor actor,
    UuidValue documentUuid,
    int knownRevision,
    Stream<DocClientMessage> input,
  ) {
    final c = DocumentConnection._(session, actor, documentUuid);
    c._out = StreamController<DocServerMessage>(
      onListen: () {
        final started = c._start(knownRevision, input).catchError((
          Object e,
          StackTrace st,
        ) {
          if (!c._out.isClosed) {
            c._out.addError(e, st);
            unawaited(c._close());
          }
        });
        debugOnStart?.call(started);
      },
      onCancel: c._close,
    );
    return c._out.stream;
  }

  void _send(DocServerMessage m) {
    if (!_out.isClosed) _out.add(m);
  }

  /// Opens the session. The client may cancel at any await: every step
  /// checks [_closed] afterwards and stops, and [_close] undoes what was
  /// registered so far (retain, bus listener, `hello`, timers).
  Future<void> _start(int knownRevision, Stream<DocClientMessage> input) async {
    session.addWillCloseListener((_) => _close());
    final doc = await DocumentStore.byUuid(session, documentUuid);
    if (doc == null) throw Errors.notFound('Document');
    final item = await DriveItem.db.findById(session, doc.itemId);
    if (item == null) throw Errors.notFound('Document');
    _item = item;
    _role = await AccessService.requireRole(session, actor, item, Role.viewer);
    if (_closed) return;
    await DriveUserStates.recordOpen(session, actor, item, _role);
    _document = doc;
    final state = await DocumentCache.of(session, doc);
    if (_closed) return;
    _state = state;
    DocumentCache.retain(state);
    _retained = true;
    await state.lock(() async {
      final fresh = await Document.db.findById(session, doc.id!);
      if (fresh == null) throw Errors.notFound('Document');
      await state.catchUp(session, fresh.headRevision);
    });
    if (_closed) return;

    final profile = await UserService.requireProfile(session, actor.userId);
    final summary = await UserService.summaryOf(session, profile);
    if (_closed) return;
    _me = Participant(
      sessionId: sessionId,
      userId: actor.userId,
      userUuid: actor.authUserId,
      displayName: summary.displayName,
      avatarUrl: summary.avatarUrl,
      colorIndex: summary.colorIndex,
      role: _role.access,
      actorKind: actor.kind,
      state: PresenceState.active,
      joinedAt: nowUtc(),
    );

    session.messages.addListener(DocumentBus.channel(documentUuid), _onBus);
    _announced = true;
    await DocumentBus.post(
      session,
      documentUuid,
      DocBusMessage(
        type: 'hello',
        originSessionId: sessionId,
        participant: _me,
      ),
    );
    if (_closed) {
      // [_close] may have posted `left` before this `hello` arrived.
      await _postLeft();
      return;
    }
    // Over the editor limit: join as a viewer.
    final editors = _participants.values
        .where((p) => p.role.index >= AccessRole.editor.index)
        .length;
    if (_role >= Role.editor && editors >= maxEditors) {
      _limitToViewer();
    }
    _subscribeTheme(doc.themeId);

    final head = _state.revision;
    List<DocumentOpView>? ops;
    String? snapshot;
    if (knownRevision > 0 &&
        knownRevision <= head &&
        head - knownRevision <= maxOpsInInit) {
      ops = await _opViews(knownRevision + 1, head);
      if (_closed) return;
      if (ops.length != head - knownRevision) ops = null;
    }
    if (ops == null) {
      snapshot = DocumentStore.encodeContent(_state.content, compress: false);
    }
    _send(
      DocInit(
        revision: head,
        snapshotJson: snapshot,
        ops: ops,
        meta: _metaOf(_document),
        role: _role.access,
        sessionId: sessionId,
        participants: [_me!, ..._participants.values],
      ),
    );
    _input = input.listen(
      (m) => _enqueue('${m.runtimeType}', () => _handle(m)),
      onDone: _close,
      onError: (Object _) => _close(),
    );
    if (Cluster.distributed) {
      _heartbeat = Timer.periodic(heartbeatInterval, (_) => _beat());
      if (_role >= Role.editor) {
        _settle = Timer(rosterSettle, _enforceEditorLimit);
      }
    }
  }

  void _limitToViewer() {
    _limitedToViewer = true;
    _role = Role.viewer;
    _me = _me!.copyWith(role: AccessRole.viewer);
  }

  /// Re-checks the editor limit once the roster of other instances
  /// arrived: counts the editors that joined before this session.
  void _enforceEditorLimit() {
    final me = _me;
    if (_closed || me == null || _role < Role.editor) return;
    bool before(Participant p) {
      final c = p.joinedAt.compareTo(me.joinedAt);
      return c < 0 || c == 0 && p.sessionId.compareTo(me.sessionId) < 0;
    }

    final earlier = _participants.values
        .where((p) => p.role.index >= AccessRole.editor.index && before(p))
        .length;
    if (earlier < maxEditors) return;
    _limitToViewer();
    _send(DocRoleChanged(role: AccessRole.viewer));
  }

  /// Re-announces this session and drops participants that went silent.
  void _beat() {
    if (_closed || _me == null) return;
    unawaited(
      DocumentBus.post(
        session,
        documentUuid,
        DocBusMessage(
          type: 'beat',
          originSessionId: sessionId,
          participant: _me,
        ),
      ).catchError((Object _) {}),
    );
    final now = clock.now();
    final cutoff = now.subtract(participantExpiry);
    for (final id in _participants.keys.toList()) {
      final seen = _lastSeen[id];
      if (seen == null) {
        _lastSeen[id] = now;
        continue;
      }
      if (seen.isAfter(cutoff)) continue;
      _participants.remove(id);
      _lastSeen.remove(id);
      _send(DocParticipantLeft(sessionId: id));
    }
  }

  void _seen(String? id) {
    if (id != null) _lastSeen[id] = clock.now();
  }

  static DocumentMetaView _metaOf(Document d) => DocumentMetaView(
    themeId: d.themeId,
    pageSetupJson: d.pageSetupJson,
    language: d.language,
    frontMatter: d.frontMatter,
  );

  Future<List<DocumentOpView>> _opViews(int from, int to) async {
    final ops = await DocumentOp.db.find(
      session,
      where: (t) =>
          t.documentId.equals(_document.id!) &
          (t.revision >= from) &
          (t.revision <= to),
      orderBy: (t) => t.revision,
      limit: maxOpsInInit,
    );
    final users = await UserService.summaries(session, [
      for (final o in ops) o.authorId,
    ]);
    return [
      for (final o in ops)
        DocumentOpView(
          revision: o.revision,
          deltaJson: o.deltaJson,
          clientOpId: o.clientOpId,
          authorId: o.authorId,
          authorUuid: o.authorId == null ? null : users[o.authorId]?.uuid,
          actorKind: o.actorKind,
          kind: o.kind,
          sessionId: o.sessionId,
          createdAt: o.createdAt,
        ),
    ];
  }

  void _subscribeTheme(UuidValue? themeId) {
    final channel = themeId == null ? null : ThemeService.channel(themeId);
    if (channel == _themeChannel) return;
    if (_themeChannel != null) {
      session.messages.removeListener(_themeChannel!, _onTheme);
    }
    _themeChannel = channel;
    if (channel != null) session.messages.addListener(channel, _onTheme);
  }

  void _onTheme(SerializableModel m) {
    if (m is DocMetaChanged) _send(m);
  }

  void _onBus(SerializableModel model) {
    if (model is! DocBusMessage || _closed) return;
    final m = model;
    if (m.originSessionId != sessionId) _seen(m.originSessionId);
    switch (m.type) {
      case 'op':
        final op = m.op;
        if (op == null) return;
        // Committed on another instance: keep this instance's state warm,
        // so cursor transforms and gap fills see the op (specs/13 §4).
        if (op.revision > _state.revision) {
          unawaited(
            _state.ensureAtLeast(session, op.revision).catchError((Object e) {
              session.log(
                'Catching up ${documentUuid.uuid} failed: $e',
                level: LogLevel.warning,
              );
            }),
          );
        }
        if (m.originSessionId == sessionId) return;
        _send(op);
      case 'cursor':
        if (m.cursor == null || m.originSessionId == sessionId) return;
        _send(m.cursor!);
      case 'beat':
        final p = m.participant;
        if (p == null || m.originSessionId == sessionId) return;
        // A participant whose hello this session missed.
        if (_participants.containsKey(p.sessionId) || !_initSent) return;
        _participants[p.sessionId] = p;
        _send(DocParticipantJoined(participant: p));
      case 'hello':
        final p = m.participant;
        if (p == null || m.originSessionId == sessionId) return;
        _participants[p.sessionId] = p;
        _send(DocParticipantJoined(participant: p));
        if (_me != null) {
          unawaited(
            DocumentBus.post(
              session,
              documentUuid,
              DocBusMessage(
                type: 'here',
                originSessionId: sessionId,
                participant: _me,
                sessionId: p.sessionId,
              ),
            ).catchError(_logFailure('here')),
          );
        }
      case 'here':
        final p = m.participant;
        if (p == null || m.sessionId != sessionId) return;
        _seen(p.sessionId);
        if (_participants.containsKey(p.sessionId)) return;
        _participants[p.sessionId] = p;
        // Before Init the roster goes into DocInit.participants.
        if (_out.hasListener && _initSent) {
          _send(DocParticipantJoined(participant: p));
        }
      case 'left':
        final id = m.originSessionId;
        _lastSeen.remove(id);
        if (id == null || _participants.remove(id) == null) return;
        _send(DocParticipantLeft(sessionId: id));
      case 'meta':
        final meta = m.meta;
        if (meta == null) return;
        if (meta.field == 'themeId') {
          unawaited(_refreshDocument().catchError(_logFailure('refresh')));
        }
        _send(meta);
      case 'role':
        if (m.userId == null || m.userId == actor.userId) {
          _enqueue('role re-check', _recheckRole);
        }
    }
  }

  /// Runs [work] after the earlier queued messages. Errors are logged and
  /// never stop the queue (a failed future would skip every later entry).
  void _enqueue(String what, Future<void> Function() work) {
    _queue = _queue.then((_) => work()).catchError((Object e, StackTrace st) {
      session.log(
        'Document ${documentUuid.uuid}: $what failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    });
  }

  void Function(Object, StackTrace) _logFailure(String what) =>
      (Object e, StackTrace st) => session.log(
        'Document ${documentUuid.uuid}: $what failed: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );

  bool get _initSent => _input != null;

  Future<void> _refreshDocument() async {
    final doc = await Document.db.findById(session, _document.id!);
    if (doc == null) return;
    _document = doc;
    _subscribeTheme(doc.themeId);
  }

  Future<void> _recheckRole() async {
    if (_closed) return;
    final item = await DriveItem.db.findById(session, _item.id!);
    var role = item == null
        ? null
        : await AccessService.effectiveRole(session, actor.userId, item);
    if (role == null || item!.trashedAt != null && role != Role.owner) {
      if (!_out.isClosed) {
        _out.addError(Errors.forbidden('You no longer have access.'));
      }
      await _close();
      return;
    }
    _item = item;
    if (_limitedToViewer && role >= Role.editor) role = Role.viewer;
    if (role != _role) {
      _role = role;
      _send(DocRoleChanged(role: role.access));
    }
  }

  Future<void> _handle(DocClientMessage m) async {
    if (_closed) return;
    try {
      if (m is! DocSubmitOp) debugOnMessage?.call(m);
      switch (m) {
        case DocSubmitOp():
          await _submit(m);
        case DocCursorUpdate():
          // The client may have seen ops this instance only knows from the
          // bus (another instance committed them).
          await _state.ensureAtLeast(session, m.revision);
          final (a, h) = OtService.transformCursor(
            _state,
            m.revision,
            m.anchor,
            m.head,
          );
          await DocumentBus.post(
            session,
            documentUuid,
            DocBusMessage(
              type: 'cursor',
              originSessionId: sessionId,
              cursor: DocRemoteCursor(
                sessionId: sessionId,
                userId: actor.userId,
                revision: _state.revision,
                anchor: a,
                head: h,
                focused: m.focused,
              ),
            ),
          );
        case DocRequestOps():
          await _state.ensureAtLeast(session, m.toRevision);
          final from = m.fromRevision < 1 ? 1 : m.fromRevision;
          final to = m.toRevision > _state.revision
              ? _state.revision
              : m.toRevision;
          if (to < from) return;
          // Older ops are history (Editor+, Write 03 §1).
          if (from < DocumentService.oldestOpFor(_role, _state.revision)) {
            session.log(
              'Refused ops $from…$to of ${documentUuid.uuid} to a '
              '${_role.name}: older than the recent window.',
              level: LogLevel.info,
            );
            return;
          }
          final views = await _opViews(from, to);
          for (final v in views) {
            _send(
              DocRemoteOp(
                revision: v.revision,
                deltaJson: v.deltaJson,
                authorId: v.authorId,
                authorUuid: v.authorUuid,
                authorSessionId: v.sessionId,
                actorKind: v.actorKind,
                kind: v.kind,
              ),
            );
          }
        case DocPing():
          _send(DocPong(t: m.t));
        case DocHashCheck():
          await _state.ensureAtLeast(session, m.revision);
          final content = m.revision == _state.revision
              ? _state.content
              : await DocumentStore.contentAt(session, _document, m.revision);
          final hash = documentHash(content);
          _send(
            DocHashResult(
              revision: m.revision,
              sha256: hash,
              matches: hash == m.sha256,
            ),
          );
      }
    } on WonkyException catch (e) {
      session.log(
        'Document message failed: ${e.message}',
        level: LogLevel.info,
      );
    } on Object catch (e, st) {
      // Unexpected (database, bus, bug): log, keep the connection alive.
      session.log(
        'Document ${documentUuid.uuid}: ${m.runtimeType} failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    }
  }

  Future<void> _submit(DocSubmitOp m) async {
    try {
      debugOnMessage?.call(m);
      final committed = await OtService.submit(
        session,
        actor: actor.copyWith(sessionId: sessionId),
        document: _document,
        item: _item,
        role: _role,
        clientOpId: m.clientOpId,
        baseRevision: m.baseRevision,
        deltaJson: m.deltaJson,
        kind: m.kind,
        sessionId: sessionId,
        groupId: m.groupId,
        // Acknowledge right after the commit; bookkeeping follows.
        awaitSideEffects: false,
      );
      _send(DocAck(clientOpId: m.clientOpId, revision: committed.revision));
    } on OpRejection catch (r) {
      _send(
        DocOpRejected(
          clientOpId: m.clientOpId,
          code: r.code,
          message: r.message,
        ),
      );
    } on Object catch (e, st) {
      session.log(
        'Submitting to ${documentUuid.uuid} failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      // Nothing was committed: the client retries the same op (a resend
      // of an op committed after all is acknowledged as a duplicate).
      _send(
        DocOpRejected(
          clientOpId: m.clientOpId,
          code: DocRejectCode.internal,
          message: 'The server could not apply the change. Please try again.',
        ),
      );
    }
  }

  Future<void> _postLeft() async {
    try {
      await DocumentBus.post(
        session,
        documentUuid,
        DocBusMessage(type: 'left', originSessionId: sessionId),
      );
    } on Object {
      // The server is shutting down.
    }
  }

  /// Idempotent; every caller waits for the same close.
  Future<void> _close() => _closing ??= _doClose();

  Future<void> _doClose() async {
    _closed = true;
    _heartbeat?.cancel();
    _settle?.cancel();
    session.messages.removeListener(DocumentBus.channel(documentUuid), _onBus);
    if (_themeChannel != null) {
      session.messages.removeListener(_themeChannel!, _onTheme);
    }
    await _input?.cancel();
    if (_retained) {
      _retained = false;
      DocumentCache.release(_state);
      // The side effects of this session's ops use its session: let them
      // finish before the session closes.
      try {
        await _state.settle().timeout(closeGrace);
      } on Object {
        // Timed out: they go on, logging on the closed session.
      }
    }
    if (_announced) await _postLeft();
    // Not awaited: close() completes when the done event reaches the
    // listener, and a listener cancelling meanwhile waits for this close.
    if (!_out.isClosed) unawaited(_out.close());
  }
}
