import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart';

import '../cluster/cluster.dart';
import '../common/actor.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../common/time.dart';
import '../drive/drive_user_state.dart';
import '../sharing/access_service.dart';
import '../users/user_service.dart';
import 'rev_binding.dart';
import 'rev_legacy_files.dart';
import 'rev_bus.dart';
import 'rev_file_state.dart';
import 'rev_log_service.dart';
import 'rev_views.dart';

/// One editing/viewing session of `<app>Doc.connect` (RevLog spec 05 §4),
/// lifted from Write's `DocumentConnection`.
class RevLogConnection {
  RevLogConnection._(
    this.session,
    this.binding,
    this.actor,
    this.fileUuid,
    this.tabId,
  );

  /// Ops sent in `RevInit` at most (04 §2.2 `opsInInit`).
  static int opsInInit = 1000;

  /// Beyond this many editors, new joiners become viewers.
  static int maxEditors = 100;

  /// Roster heartbeat with several instances.
  static Duration heartbeatInterval = const Duration(seconds: 30);

  /// Roster settle time with several instances.
  static Duration rosterSettle = const Duration(seconds: 2);

  /// Role re-check interval (expired grants without an ACL event).
  static Duration roleRecheck = const Duration(minutes: 5);

  /// Tests: called with the future of each connection's start.
  static void Function(Future<void> started)? debugOnStart;

  /// Tests: called before each client message is handled (may throw).
  static void Function(RevClientMessage message)? debugOnMessage;

  /// Optional per-binding warm-up when a connection starts (protected
  /// Sheets files take a headless lease, 05 §3.5). Returns the release.
  static final Map<
    RevFileKind,
    Future<void Function()?> Function(
      Session session,
      RevFileState state,
      Role role,
    )
  >
  warmers = {};

  final Session session;
  final RevBinding binding;
  final Actor actor;
  final UuidValue fileUuid;
  final String tabId;
  final String sessionId = const Uuid().v4();

  late DriveItem _item;
  late Role _role;
  late RevFileState _state;
  late StreamController<RevServerMessage> _out;
  StreamSubscription<RevClientMessage>? _input;
  RevFileLease? _lease;
  void Function()? _unlisten;
  void Function()? _unwarm;
  final Map<String, Participant> _participants = {};
  final Map<String, DateTime> _lastSeen = {};
  Participant? _me;
  bool _limitedToViewer = false;
  bool _announced = false;
  Timer? _heartbeat;
  Timer? _settle;
  Timer? _recheck;
  bool _closed = false;
  Future<void>? _closing;
  Future<void> _queue = Future.value();

  /// Ops are forwarded after this revision (set when `RevInit` is sent);
  /// ops arriving before it are buffered.
  int? _initRevision;
  final List<RevOpView> _early = [];

  /// Opens a session.
  static Stream<RevServerMessage> open(
    Session session,
    RevBinding binding,
    Actor actor,
    UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<RevClientMessage> input,
  ) {
    final c = RevLogConnection._(session, binding, actor, fileUuid, tabId);
    c._out = StreamController<RevServerMessage>(
      onListen: () {
        final started = c._start(knownRevision, input).catchError((
          Object e,
          StackTrace st,
        ) {
          if (!c._out.isClosed) {
            c._sessionError(e);
            unawaited(c._close());
          }
        });
        debugOnStart?.call(started);
      },
      onCancel: c._close,
    );
    return c._out.stream;
  }

  void _send(RevServerMessage m) {
    if (!_out.isClosed) _out.add(m);
  }

  void _sessionError(Object e) {
    final (code, message) = switch (e) {
      RevRejection() => (RevLogService.codeOf(e), e.message),
      WonkyException(:final code) when code == WonkyErrorCode.forbidden => (
        RevRejectCode.forbidden,
        'You no longer have access.',
      ),
      WonkyException(:final message) => (RevRejectCode.notFound, message),
      _ => (RevRejectCode.internal, 'The server could not open the file.'),
    };
    if (code == RevRejectCode.internal) {
      session.log(
        'Opening ${fileUuid.uuid} failed: $e',
        level: LogLevel.error,
      );
    }
    _send(RevRejected(code: code, message: message));
  }

  Future<void> _start(int knownRevision, Stream<RevClientMessage> input) async {
    session.addWillCloseListener((_) => _close());
    final file = await RevFile.db.findFirstRow(
      session,
      where: (t) => t.fileUuid.equals(fileUuid),
    );
    if (file == null) {
      await RevLegacyFiles.removeIfLegacy(session, binding, actor, fileUuid);
    }
    if (file == null || file.purging || file.kind != binding.kind) {
      throw RevRejection(RevRejectReason.notFound, 'The file does not exist.');
    }
    final item = await DriveItem.db.findById(session, file.itemId);
    if (item == null) {
      throw RevRejection(RevRejectReason.notFound, 'The file does not exist.');
    }
    _item = item;
    _role = await AccessService.requireRole(session, actor, item, Role.viewer);
    if (_closed) return;
    await DriveUserStates.recordOpen(session, actor, item, _role);
    final state = await RevFileStates.of(session, binding, fileUuid);
    if (_closed) return;
    if (state == null) {
      throw RevRejection(RevRejectReason.notFound, 'The file does not exist.');
    }
    _state = state;
    _lease = RevFileStates.retain(state);
    await state.ensureAtLeast(session, file.headRevision);
    if (_closed) return;
    final warm = warmers[binding.kind];
    if (warm != null) {
      _unwarm = await warm(session, state, _role);
      if (_closed) return;
    }

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

    // Ops from now on are forwarded (buffered until Init).
    _unlisten = state.listen(_onOp);
    session.messages.addListener(RevBus.channel(fileUuid), _onBus);
    _announced = true;
    await RevBus.roster(
      session,
      fileUuid,
      RevBusMessage(
        type: 'hello',
        originSessionId: sessionId,
        participant: _me,
      ),
    );
    if (_closed) {
      await _postLeft();
      return;
    }
    final editors = _participants.values
        .where((p) => p.role.index >= AccessRole.editor.index)
        .length;
    if (_role >= Role.editor && editors >= maxEditors) _limitToViewer();

    final fresh = await RevFile.db.findById(session, file.id!);
    if (_closed) return;
    if (fresh == null || fresh.purging) {
      throw RevRejection(RevRejectReason.notFound, 'The file does not exist.');
    }
    final head = state.revision;
    if (knownRevision > head) {
      throw RevRejection(
        RevRejectReason.unknownBase,
        'This device is ahead of the server.',
      );
    }
    List<RevOpView>? ops;
    var more = false;
    var bootstrap = false;
    if (knownRevision == head) {
      ops = const [];
    } else if (knownRevision == 0 ||
        knownRevision < fresh.prunedBelow ||
        head - knownRevision > opsInInit) {
      bootstrap = true;
    } else {
      ops =
          state.recent.range(knownRevision + 1, head) ??
          await RevViews.read(
            session,
            binding.codec,
            file.id!,
            knownRevision + 1,
            head,
          );
      if (_closed) return;
      final last = ops.isEmpty ? knownRevision : ops.last.revision;
      more = last < head;
    }
    _send(
      RevInit(
        revision: head,
        role: _role.access,
        sessionId: sessionId,
        schemaHash: binding.schema.hash,
        acceptedHashes: RevLogService.acceptedHashes(binding).toList(),
        stats: fresh.stats,
        prunedBelow: fresh.prunedBelow,
        ops: bootstrap ? null : ops,
        more: more,
        bootstrap: bootstrap,
      ),
    );
    _initRevision = head;
    for (final op in _early) {
      _onOp(op);
    }
    _early.clear();
    _input = input.listen(
      (m) => _enqueue('${m.runtimeType}', () => _handle(m)),
      onDone: _close,
      onError: (Object _) => _close(),
    );
    _recheck = Timer.periodic(roleRecheck, (_) {
      _enqueue('role re-check', _recheckRole);
    });
    if (Cluster.distributed) {
      _heartbeat = Timer.periodic(heartbeatInterval, (_) => _beat());
      if (_role >= Role.editor) {
        _settle = Timer(rosterSettle, _enforceEditorLimit);
      }
    }
  }

  void _onOp(RevOpView op) {
    if (_closed) return;
    final init = _initRevision;
    if (init == null) {
      _early.add(op);
      return;
    }
    if (op.revision <= init) return;
    // The committing connection gets RevAck, not its own op (Write's rule).
    if (op.authorSessionId == sessionId) return;
    _send(RevRemoteOp(op: op));
  }

  void _limitToViewer() {
    _limitedToViewer = true;
    _role = Role.viewer;
    _me = _me!.copyWith(role: AccessRole.viewer);
  }

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
    _send(RevRoleChanged(role: AccessRole.viewer));
  }

  void _beat() {
    if (_closed || _me == null) return;
    unawaited(
      RevBus.roster(
        session,
        fileUuid,
        RevBusMessage(
          type: 'beat',
          originSessionId: sessionId,
          participant: _me,
          headRevision: _state.revision,
        ),
      ).catchError(_logFailure('beat')),
    );
    final now = clock.now();
    final cutoff = now.subtract(heartbeatInterval * 3);
    for (final id in _participants.keys.toList()) {
      final seen = _lastSeen[id];
      if (seen == null) {
        _lastSeen[id] = now;
        continue;
      }
      if (seen.isAfter(cutoff)) continue;
      _participants.remove(id);
      _lastSeen.remove(id);
    }
  }

  void _onBus(SerializableModel model) {
    if (model is! RevBusMessage || _closed) return;
    final m = model;
    if (m.originSessionId != null && m.originSessionId != sessionId) {
      _lastSeen[m.originSessionId!] = clock.now();
    }
    switch (m.type) {
      case 'hello':
        final p = m.participant;
        if (p == null || m.originSessionId == sessionId) return;
        _participants[p.sessionId] = p;
        if (_me != null) {
          unawaited(
            RevBus.roster(
              session,
              fileUuid,
              RevBusMessage(
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
        _participants[p.sessionId] = p;
      case 'beat':
        final p = m.participant;
        if (p == null || m.originSessionId == sessionId) return;
        _participants.putIfAbsent(p.sessionId, () => p);
        final head = m.headRevision;
        if (head != null && head > _state.revision) {
          unawaited(
            _state.ensureAtLeast(session, head).catchError(_logFailure('gap')),
          );
        }
      case 'left':
        final id = m.originSessionId;
        if (id == null) return;
        _participants.remove(id);
        _lastSeen.remove(id);
      case 'role':
        if (m.userId == null || m.userId == actor.userId) {
          _enqueue('role re-check', _recheckRole);
        }
      case 'purged':
        _send(
          RevRejected(
            code: RevRejectCode.notFound,
            message: 'The file was deleted.',
          ),
        );
        unawaited(_close());
    }
  }

  void _enqueue(String what, Future<void> Function() work) {
    _queue = _queue.then((_) => work()).catchError((Object e, StackTrace st) {
      session.log(
        'File ${fileUuid.uuid}: $what failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    });
  }

  void Function(Object, StackTrace) _logFailure(String what) =>
      (Object e, StackTrace st) => session.log(
        'File ${fileUuid.uuid}: $what failed: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );

  Future<void> _recheckRole() async {
    if (_closed) return;
    final item = await DriveItem.db.findById(session, _item.id!);
    var role = item == null
        ? null
        : await AccessService.effectiveRole(session, actor.userId, item);
    if (role == null || item!.trashedAt != null && role != Role.owner) {
      _send(
        RevRejected(
          code: RevRejectCode.forbidden,
          message: 'You no longer have access.',
        ),
      );
      await _close();
      return;
    }
    _item = item;
    if (_limitedToViewer && role >= Role.editor) role = Role.viewer;
    if (role != _role) {
      _role = role;
      _send(RevRoleChanged(role: role.access));
    }
  }

  Future<void> _handle(RevClientMessage m) async {
    if (_closed) return;
    try {
      if (m is! RevSubmit) debugOnMessage?.call(m);
      switch (m) {
        case RevSubmit():
          await _submit(m);
        case RevRequestOps():
          await _requestOps(m);
        case RevPing():
          _send(RevPong(t: m.t, headRevision: _state.revision));
      }
    } on Object catch (e, st) {
      session.log(
        'File ${fileUuid.uuid}: ${m.runtimeType} failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    }
  }

  Future<void> _requestOps(RevRequestOps m) async {
    await _state.ensureAtLeast(session, m.toRevision);
    final from = m.fromRevision < 1 ? 1 : m.fromRevision;
    final to = m.toRevision > _state.revision ? _state.revision : m.toRevision;
    if (to < from) return;
    if (from < oldestOpFor(_role, _state.revision)) {
      session.log(
        'Refused ops $from…$to of ${fileUuid.uuid} to a ${_role.name}.',
        level: LogLevel.info,
      );
      return;
    }
    final views =
        _state.recent.range(from, to) ??
        await RevViews.read(session, binding.codec, _state.fileId, from, to);
    for (final v in views) {
      _send(RevRemoteOp(op: v));
    }
  }

  /// The oldest revision [role] may read (05 §11: Viewer the last 1,000).
  static int oldestOpFor(Role role, int head) =>
      role >= Role.editor ? 1 : head - 1000 + 1;

  Future<void> _submit(RevSubmit m) async {
    try {
      debugOnMessage?.call(m);
      final cs = RevLogService.decodeSubmit(binding, m);
      final commit = await RevLogService.submit(
        session,
        binding: binding,
        state: _state,
        cs: cs,
        submitter: RevSubmitter.of(actor, sessionId: sessionId),
        connectionRole: _role,
      );
      String? text;
      ByteData? gz;
      final applied = commit.applied;
      if (!commit.appliedEqualsSubmitted && applied != null) {
        (text, gz) = RevViews.wire(binding.codec, applied, withBefore: false);
      }
      _send(
        RevAck(
          clientOpId: m.clientOpId,
          revision: commit.revision,
          duplicate: commit.duplicate,
          applied: text,
          appliedGz: gz,
          outcome: commit.outcomeJson,
        ),
      );
      if (commit.duplicate && applied == null) {
        // Pruned: the client re-bootstraps (05 §3.2 step 1).
        _send(RevResync(reason: 'pruned'));
      }
    } on RevRejection catch (r) {
      _send(
        RevRejected(
          clientOpId: m.clientOpId,
          code: RevLogService.codeOf(r),
          message: r.message,
          detailsJson: r.details == null ? null : jsonEncode(r.details),
        ),
      );
      if (r.reason == RevRejectReason.forbidden) await _close();
    } on Object catch (e, st) {
      session.log(
        'Submitting to ${fileUuid.uuid} failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
      _send(
        RevRejected(
          clientOpId: m.clientOpId,
          code: RevRejectCode.internal,
          message: 'The server could not apply the change. Please try again.',
        ),
      );
    }
  }

  Future<void> _postLeft() async {
    try {
      await RevBus.roster(
        session,
        fileUuid,
        RevBusMessage(type: 'left', originSessionId: sessionId),
      );
    } on Object {
      // Shutting down.
    }
  }

  Future<void> _close() => _closing ??= _doClose();

  Future<void> _doClose() async {
    _closed = true;
    _heartbeat?.cancel();
    _settle?.cancel();
    _recheck?.cancel();
    _unlisten?.call();
    session.messages.removeListener(RevBus.channel(fileUuid), _onBus);
    await _input?.cancel();
    _unwarm?.call();
    _lease?.release();
    _lease = null;
    if (_announced) await _postLeft();
    // Not awaited: close() completes when the done event reaches the
    // listener, and a listener cancelling meanwhile waits for this close.
    if (!_out.isClosed) unawaited(_out.close());
  }
}
