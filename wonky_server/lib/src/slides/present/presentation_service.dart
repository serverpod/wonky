import 'dart:async';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/cluster/cluster.dart';
import '../../platform/cluster/cluster_bus.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/lru_map.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/sharing/access_service.dart';
import '../../platform/users/user_service.dart';

/// The presentation session (Slides 10 §6): ephemeral, like presence —
/// nothing is stored. Every joined connection keeps its own view of the
/// session from the bus channel `present:<sessionId>` (global with Redis),
/// so presenter and audience may be served by different instances.
///
/// - A presenter join without a session id creates the session (128-bit,
///   base-62). A presenter join with an id probes the channel (`who`): a
///   connected presenter of the same account must be taken over
///   (`takeOver`, "Take over the presentation from your other window?");
///   a session known for another account is refused.
/// - Audience, remote and follower joins say `hello` and wait for the
///   presenter's `here` (or, while the presenter reconnects, another
///   member's `meta`). `audience` and `remote` must be the presenter's own
///   account — or, for a `remote`, carry a pairing key the presenter issued
///   (SL-41, 10 §6.4); `follower` needs ≥ viewer on the deck, which every
///   join checks.
/// - The presenter relays `state`, `laser`, `ink` and `end`; audiences and
///   remotes send `command`s (≤ [maxCommandsPerSecond]; access re-checked)
///   that only the presenter receives.
/// - When the presenter's stream closes without `end` the others get
///   `PresentationPresenterEvent(connected: false)` and the session ends
///   after [presenterGrace] unless the presenter rejoins.
///
/// Sessions carry no deck content; session ids are never logged.
abstract final class PresentationService {
  /// Grace for a presenter reconnect (10 §6.1: 30 s). Variable for tests.
  static Duration presenterGrace = const Duration(seconds: 30);

  /// How long a joining audience waits for the presenter.
  static Duration joinTimeout = const Duration(seconds: 3);

  /// How long a presenter rejoin and [find] listen for answers.
  static Duration probeTimeout = const Duration(milliseconds: 400);

  /// How often members receiving the presenter's state re-check their
  /// access (10 §6.5). Variable for tests.
  static Duration memberAccessRecheck = const Duration(seconds: 5);

  /// Remote commands per second and connection (10 §6.5).
  static const maxCommandsPerSecond = 20;

  /// Laser messages per second (10 §4.2: ≤ 30 Hz).
  static const maxLaserPerSecond = 30;

  /// Largest ink stroke JSON accepted.
  static const maxStrokeBytes = 64 * 1024;

  static String channel(String sessionId) => 'present:$sessionId';

  static String deckChannel(String deckUuid) => 'present-deck:$deckUuid';

  static String _findChannel(String requestId) => 'present-find:$requestId';

  // ---------------------------------------------- pairing (SL-41, 10 §6.4)

  /// How long a phone-remote pairing key (and its code) is valid.
  static Duration pairingTtl = const Duration(minutes: 10);

  /// Typed codes a user may try per [_resolveWindow] (6-digit codes are
  /// guessable otherwise).
  static const maxResolvesPerWindow = 10;
  static const _resolveWindow = Duration(minutes: 1);
  static final LruMap<int, List<int>> _resolves = LruMap(10000);

  /// Codes issued by presenters on this instance (avoids local repeats).
  static final Set<String> _localCodes = {};

  static String codeChannel(String code) => 'present-code:$code';

  static final _codePattern = RegExp(r'^[0-9]{6}$');

  /// A six-digit code not issued on this instance.
  static String newCode() {
    final r = Random.secure();
    while (true) {
      final c = r.nextInt(1000000).toString().padLeft(6, '0');
      if (_localCodes.add(c)) return c;
    }
  }

  static void releaseCode(String code) => _localCodes.remove(code);

  /// The remote route a typed pairing [code] stands for (the presenter's
  /// connection answers on `present-code:<code>`), or null. Needs ≥ viewer
  /// on the deck; at most [maxResolvesPerWindow] tries a minute per user.
  static Future<PresentationPairingTarget?> resolveCode(
    Session session,
    Actor actor,
    String code,
  ) async {
    final now = _now();
    final tries = (_resolves.get(actor.userId) ?? <int>[])
      ..removeWhere((t) => now - t > _resolveWindow.inMilliseconds);
    if (tries.length >= maxResolvesPerWindow) {
      throw Errors.limit('Too many pairing codes. Try again in a minute.');
    }
    tries.add(now);
    _resolves.put(actor.userId, tries);
    final digits = code.replaceAll(RegExp(r'\s'), '');
    if (!_codePattern.hasMatch(digits)) return null;
    final requestId = const Uuid().v4();
    PresentationBusMessage? answer;
    void onReply(SerializableModel m) {
      if (m is! PresentationBusMessage || m.type != 'resolved') return;
      answer ??= m;
    }

    final ch = _findChannel(requestId);
    session.messages.addListener(ch, onReply);
    try {
      await _post(
        session,
        codeChannel(digits),
        PresentationBusMessage(
          type: 'resolve',
          connectionId: requestId,
          sessionId: '',
          deckUuid: '',
          userId: actor.userId,
          replyTo: requestId,
        ),
      );
      final until = clockNow().add(probeTimeout);
      while (answer == null && clockNow().isBefore(until)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    } finally {
      session.messages.removeListener(ch, onReply);
    }
    final a = answer;
    final key = a?.pairingKey;
    if (a == null || key == null) return null;
    final deck = UuidValue.fromString(a.deckUuid);
    await AccessService.require(session, actor, deck, Role.viewer);
    return PresentationPairingTarget(
      deckUuid: deck,
      sessionId: a.sessionId,
      pairingKey: key,
    );
  }

  static final _idPattern = RegExp(r'^[0-9A-Za-z]{16,32}$');

  static const _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';

  /// A new session id: 128 random bits in base 62 (22 characters).
  static String newSessionId() {
    final r = Random.secure();
    var n = BigInt.zero;
    for (var i = 0; i < 16; i++) {
      n = (n << 8) | BigInt.from(r.nextInt(256));
    }
    final b = BigInt.from(62);
    final out = StringBuffer();
    for (var i = 0; i < 22; i++) {
      out.write(_alphabet[(n % b).toInt()]);
      n = n ~/ b;
    }
    return out.toString();
  }

  static int _now() => nowUtc().millisecondsSinceEpoch;

  /// Joins (or, as presenter, creates) a session on [deckUuid].
  static Stream<PresentationEvent> join(
    Session session,
    Actor actor,
    UuidValue deckUuid,
    PresentationJoin join,
    Stream<PresentationUpdate> updates,
  ) {
    final c = _Connection(session, actor, deckUuid, join, updates);
    return c.out.stream;
  }

  /// The caller's live presenter session on [deckUuid], if any (the
  /// *Show audience view here* banner, 10 §5.2).
  static Future<PresentationSessionInfo?> find(
    Session session,
    Actor actor,
    UuidValue deckUuid,
  ) async {
    await AccessService.require(session, actor, deckUuid, Role.viewer);
    final requestId = const Uuid().v4();
    final replies = <PresentationSessionInfo>[];
    void onReply(SerializableModel m) {
      if (m is! PresentationBusMessage || m.type != 'found') return;
      if (m.presenterUserId != actor.userId) return;
      replies.add(
        PresentationSessionInfo(
          sessionId: m.sessionId,
          deviceLabel: m.deviceLabel ?? '',
          startedAtMs: m.startedAtMs ?? 0,
        ),
      );
    }

    final ch = _findChannel(requestId);
    session.messages.addListener(ch, onReply);
    try {
      await _post(
        session,
        deckChannel(deckUuid.uuid),
        PresentationBusMessage(
          type: 'find',
          connectionId: requestId,
          sessionId: '',
          deckUuid: deckUuid.uuid,
          userId: actor.userId,
          replyTo: requestId,
        ),
      );
      final until = clockNow().add(probeTimeout);
      while (replies.isEmpty && clockNow().isBefore(until)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      // A moment more for other instances' answers.
      if (replies.isNotEmpty && Cluster.distributed) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      session.messages.removeListener(ch, onReply);
    }
    if (replies.isEmpty) return null;
    replies.sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return replies.first;
  }

  static DateTime clockNow() => nowUtc();

  /// Posts [m] and, in a cluster, sends it to the other instances at once
  /// (the bus otherwise batches for up to a second; presenting needs
  /// ≤ 300 ms p95, 10 AC 4).
  static Future<void> _post(
    Session session,
    String ch,
    PresentationBusMessage m, {
    String? coalesceKey,
  }) async {
    await ClusterBus.post(session, ch, m, coalesceKey: coalesceKey);
    if (Cluster.distributed) await ClusterBus.flush(session.serverpod);
  }
}

/// One joined connection (a client stream).
class _Connection {
  _Connection(
    this.session,
    this.actor,
    this.deckUuid,
    this.join,
    this.updates,
  ) {
    out = StreamController<PresentationEvent>(
      onListen: () {
        unawaited(
          _start().catchError((Object e, StackTrace st) {
            if (!out.isClosed) {
              out.addError(e, st);
              unawaited(_close());
            }
          }),
        );
      },
      onCancel: _leave,
    );
  }

  final Session session;
  final Actor actor;
  final UuidValue deckUuid;
  final PresentationJoin join;
  final Stream<PresentationUpdate> updates;
  late final StreamController<PresentationEvent> out;

  final String connectionId = const Uuid().v4();
  late String sessionId;
  late final PresentationRole role = join.role;
  String displayName = '';

  /// Whether this connection was admitted (it relays nothing before).
  bool verified = false;
  int? presenterUserId;
  bool presenterConnected = false;
  String? presenterDevice;
  PresentationState? lastState;
  int? lastStateSentAt;
  int startedAtMs = 0;

  final Map<String, PresentationParticipant> roster = {};
  final List<PresentationBusMessage> _replies = [];
  StreamSubscription<PresentationUpdate>? _input;
  Timer? _grace;
  bool _closed = false;
  bool _left = false;
  bool _quiet = false;

  int _commandWindowStart = 0;
  int _commandsInWindow = 0;
  int _lastLaser = 0;
  int _accessCheckedAt = 0;

  bool get isPresenter => role == PresentationRole.presenter;
  String get ch => PresentationService.channel(sessionId);
  String get _deckCh => PresentationService.deckChannel(deckUuid.uuid);

  void _emit(PresentationEvent e) {
    if (!out.isClosed && !_closed) out.add(e);
  }

  int _now() => PresentationService._now();

  PresentationBusMessage _msg(
    String type, {
    String? replyTo,
    PresentationState? state,
    int? stateSentAtMs,
    String? slideId,
    double? x,
    double? y,
    String? inkOp,
    String? strokeId,
    String? strokeJson,
    String? command,
    String? argsJson,
    int? sentAtMs,
    String? pairingKey,
    bool? admitted,
  }) => PresentationBusMessage(
    type: type,
    connectionId: connectionId,
    sessionId: sessionId,
    deckUuid: deckUuid.uuid,
    userId: actor.userId,
    role: role,
    deviceLabel: join.deviceLabel,
    displayName: displayName,
    presenterUserId: presenterUserId,
    presenterConnected: isPresenter || presenterConnected,
    state: state,
    stateSentAtMs: stateSentAtMs,
    slideId: slideId,
    x: x,
    y: y,
    inkOp: inkOp,
    strokeId: strokeId,
    strokeJson: strokeJson,
    command: command,
    argsJson: argsJson,
    sentAtMs: sentAtMs,
    startedAtMs: isPresenter ? startedAtMs : null,
    replyTo: replyTo,
    pairingKey: pairingKey,
    admitted: admitted,
  );

  Future<void> _send(PresentationBusMessage m, {String? coalesceKey}) =>
      PresentationService._post(session, ch, m, coalesceKey: coalesceKey);

  // ------------------------------------------------------------- joining

  Future<void> _start() async {
    await AccessService.require(session, actor, deckUuid, Role.viewer);
    _accessCheckedAt = _now();
    final profile = await UserService.requireProfile(session, actor.userId);
    displayName = (await UserService.summaryOf(session, profile)).displayName;
    final requested = join.sessionId;
    if (requested != null &&
        !PresentationService._idPattern.hasMatch(requested)) {
      throw Errors.invalid('Invalid presentation session.');
    }
    if (isPresenter) {
      await _startPresenter(requested);
    } else {
      if (requested == null) {
        throw Errors.invalid('A presentation session is required.');
      }
      await _startMember(requested);
    }
    if (_closed) return;
    _input = updates.listen(
      (u) => unawaited(_handle(u).catchError(_logFailure)),
      onDone: () => unawaited(_close()),
      onError: (Object _) => unawaited(_close()),
    );
    session.addWillCloseListener((_) => _leave());
  }

  Future<void> _startPresenter(String? requested) async {
    startedAtMs = _now();
    presenterUserId = actor.userId;
    if (requested == null) {
      sessionId = PresentationService.newSessionId();
      _listen();
    } else {
      sessionId = requested;
      _listen();
      await _send(_msg('who'));
      await _waitReplies(
        PresentationService.probeTimeout,
        (r) => r.role == PresentationRole.presenter,
      );
      final presenter = _replies
          .where((r) => r.role == PresentationRole.presenter)
          .firstOrNull;
      final known = _replies
          .map((r) => r.presenterUserId)
          .whereType<int>()
          .firstOrNull;
      if ((presenter != null && presenter.userId != actor.userId) ||
          (known != null && known != actor.userId)) {
        _unlisten();
        throw Errors.forbidden('This presentation belongs to someone else.');
      }
      if (presenter != null && join.takeOver != true) {
        _emit(
          PresentationEndedEvent(
            serverTimeMs: _now(),
            reason: 'presenterActive',
          ),
        );
        _quiet = true;
        await _close();
        return;
      }
      if (presenter != null) await _send(_msg('takeover'));
      // Keep the latest state any member knew (the client resumes it).
      for (final r in _replies) {
        if (r.state != null &&
            (lastState == null || r.state!.revision > lastState!.revision)) {
          lastState = r.state;
          lastStateSentAt = r.stateSentAtMs;
        }
      }
      _replies.clear();
    }
    verified = true;
    session.messages.addListener(_deckCh, _onDeck);
    _emit(
      PresentationWelcome(
        serverTimeMs: _now(),
        sessionId: sessionId,
        connectionId: connectionId,
        role: role,
        presenterConnected: true,
        presenterDevice: join.deviceLabel,
        state: lastState,
        stateSentAtMs: lastStateSentAt,
      ),
    );
    // Members answer with `here` (the roster of a rejoined presenter).
    await _send(_msg('hello'));
  }

  Future<void> _startMember(String requested) async {
    sessionId = requested;
    _listen();
    // A phone remote of another account shows its pairing key (SL-41).
    await _send(
      _msg(
        'hello',
        pairingKey: role == PresentationRole.remote ? join.pairingKey : null,
      ),
    );
    await _waitReplies(
      PresentationService.joinTimeout,
      (r) => r.role == PresentationRole.presenter,
    );
    final presenter = _replies
        .where((r) => r.role == PresentationRole.presenter)
        .firstOrNull;
    final answer = presenter ?? _replies.firstOrNull;
    _replies.clear();
    if (answer == null ||
        answer.deckUuid != deckUuid.uuid ||
        answer.presenterUserId == null) {
      _emit(PresentationEndedEvent(serverTimeMs: _now(), reason: 'notFound'));
      _quiet = true;
      await _close();
      return;
    }
    final owner = answer.presenterUserId!;
    if (role == PresentationRole.remote &&
        owner != actor.userId &&
        presenter?.admitted != true) {
      // ---- SL-41: a remote of another account needs a valid pairing key
      // (or an earlier pairing in this session) that the presenter admits.
      _emit(
        PresentationEndedEvent(
          serverTimeMs: _now(),
          reason: join.pairingKey == null ? 'noAccess' : 'pairingExpired',
        ),
      );
      _quiet = true;
      await _close();
      return;
    }
    if (role != PresentationRole.follower &&
        role != PresentationRole.remote &&
        owner != actor.userId) {
      _unlisten();
      throw Errors.forbidden('Only the presenter can join this way.');
    }
    presenterUserId = owner;
    presenterConnected = answer.presenterConnected ?? presenter != null;
    presenterDevice = presenter?.deviceLabel;
    lastState = answer.state;
    lastStateSentAt = answer.stateSentAtMs;
    verified = true;
    _emit(
      PresentationWelcome(
        serverTimeMs: _now(),
        sessionId: sessionId,
        connectionId: connectionId,
        role: role,
        presenterConnected: presenterConnected,
        presenterDevice: presenterDevice,
        state: lastState,
        stateSentAtMs: lastStateSentAt,
      ),
    );
    if (!presenterConnected) _startGrace();
    // Only admitted members join the presenter's roster.
    await _send(_msg('joined'));
  }

  Future<void> _waitReplies(
    Duration timeout,
    bool Function(PresentationBusMessage) enough,
  ) async {
    final until = _now() + timeout.inMilliseconds;
    while (!_closed && _now() < until) {
      if (_replies.any(enough)) return;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void _listen() => session.messages.addListener(ch, _onBus);

  void _unlisten() {
    session.messages.removeListener(ch, _onBus);
    session.messages.removeListener(_deckCh, _onDeck);
  }

  // ----------------------------------------------------------------- bus

  void _onDeck(SerializableModel model) {
    if (model is! PresentationBusMessage || _closed || !verified) return;
    if (model.type != 'find' || model.userId != actor.userId) return;
    final replyTo = model.replyTo;
    if (replyTo == null) return;
    unawaited(
      PresentationService._post(
        session,
        PresentationService._findChannel(replyTo),
        _msg('found', replyTo: replyTo),
      ).catchError(_logFailure),
    );
  }

  void _onBus(SerializableModel model) {
    if (model is! PresentationBusMessage || _closed) return;
    final m = model;
    if (m.connectionId == connectionId || m.sessionId != sessionId) return;
    if (m.deckUuid != deckUuid.uuid) return;
    switch (m.type) {
      case 'here' || 'meta':
        if (m.replyTo != connectionId) return;
        if (!verified) {
          _replies.add(m);
        } else if (isPresenter && m.role != PresentationRole.presenter) {
          _addToRoster(m);
          // A rejoined presenter keeps the remotes paired before (SL-41).
          if (m.role == PresentationRole.remote && m.userId != actor.userId) {
            _paired.add(m.userId);
          }
        }
      case 'who':
        if (!verified) return;
        _reply(m, isPresenter ? 'here' : 'meta');
      case 'hello':
        if (!verified) return;
        if (isPresenter) {
          if (m.role == PresentationRole.presenter) return;
          _reply(m, 'here', admitted: _admit(m));
        } else if (m.role == PresentationRole.presenter) {
          if (m.userId != presenterUserId) return;
          _grace?.cancel();
          _grace = null;
          presenterDevice = m.deviceLabel;
          if (!presenterConnected) {
            presenterConnected = true;
            _emit(
              PresentationPresenterEvent(
                serverTimeMs: _now(),
                connected: true,
              ),
            );
          }
          // Tell the (re)joined presenter who is here.
          _reply(m, 'here');
        } else if (!presenterConnected) {
          _reply(m, 'meta');
        }
      case 'joined':
        if (isPresenter && verified && m.role != PresentationRole.presenter) {
          _addToRoster(m);
        }
      case 'takeover':
        if (isPresenter && verified && m.userId == actor.userId) {
          _emit(
            PresentationEndedEvent(serverTimeMs: _now(), reason: 'takenOver'),
          );
          _quiet = true;
          unawaited(_close());
        }
      case 'bye':
        if (isPresenter && roster.remove(m.connectionId) != null) {
          _emitRoster();
        }
      case 'away':
        if (isPresenter || !verified || m.userId != presenterUserId) return;
        if (m.role != PresentationRole.presenter) return;
        presenterConnected = false;
        _emit(
          PresentationPresenterEvent(serverTimeMs: _now(), connected: false),
        );
        _startGrace();
      case 'state':
        if (!_fromPresenter(m) || m.state == null) return;
        lastState = m.state;
        lastStateSentAt = m.sentAtMs;
        _emit(
          PresentationStateEvent(
            serverTimeMs: m.sentAtMs ?? _now(),
            state: m.state!,
          ),
        );
      case 'laser':
        if (!_fromPresenter(m)) return;
        _emit(
          PresentationLaserEvent(
            serverTimeMs: m.sentAtMs ?? _now(),
            slideId: m.slideId,
            x: m.x,
            y: m.y,
          ),
        );
      case 'ink':
        if (!_fromPresenter(m) || m.slideId == null || m.inkOp == null) {
          return;
        }
        _emit(
          PresentationInkEvent(
            serverTimeMs: m.sentAtMs ?? _now(),
            slideId: m.slideId!,
            op: m.inkOp!,
            strokeId: m.strokeId,
            strokeJson: m.strokeJson,
          ),
        );
      case 'command':
        if (!isPresenter || !verified || m.command == null) return;
        if (m.role == PresentationRole.follower) return;
        _emit(
          PresentationCommandEvent(
            serverTimeMs: m.sentAtMs ?? _now(),
            command: m.command!,
            argsJson: m.argsJson,
            fromConnectionId: m.connectionId,
          ),
        );
      case 'end':
        if (!_fromPresenter(m)) return;
        _emit(PresentationEndedEvent(serverTimeMs: _now(), reason: 'ended'));
        _quiet = true;
        unawaited(_close());
    }
  }

  bool _fromPresenter(PresentationBusMessage m) {
    final from =
        !isPresenter &&
        verified &&
        m.role == PresentationRole.presenter &&
        m.userId == presenterUserId;
    if (from) _recheckAccess();
    return from;
  }

  bool _accessChecking = false;

  /// Members (audience, followers, remotes) receiving the presenter's
  /// state re-check their access at most every 5 s, like commands (10
  /// §6.5): a member who lost access is ended with `noAccess`. Runs in the
  /// background; what arrives meanwhile is still relayed.
  void _recheckAccess() {
    final now = _now();
    if (_accessChecking ||
        _closed ||
        now - _accessCheckedAt <=
            PresentationService.memberAccessRecheck.inMilliseconds) {
      return;
    }
    _accessChecking = true;
    // Also throttles retries after a database error.
    _accessCheckedAt = now;
    unawaited(
      AccessService.require(session, actor, deckUuid, Role.viewer)
          .then((_) => _accessCheckedAt = _now())
          .catchError((Object e, StackTrace st) async {
            if (e is WonkyException &&
                (e.code == WonkyErrorCode.notFound ||
                    e.code == WonkyErrorCode.forbidden)) {
              _emit(
                PresentationEndedEvent(
                  serverTimeMs: _now(),
                  reason: 'noAccess',
                ),
              );
              await _close();
            } else {
              _logFailure(e, st);
            }
            return 0;
          })
          .whenComplete(() => _accessChecking = false),
    );
  }

  void _logFailure(Object e, StackTrace st) {
    try {
      session.log(
        'presentation: relay failed: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );
    } on Object {
      // The session is closing.
    }
  }

  void _reply(PresentationBusMessage to, String type, {bool? admitted}) =>
      unawaited(
        _send(
          _msg(
            type,
            replyTo: to.connectionId,
            state: lastState,
            stateSentAtMs: lastStateSentAt,
            admitted: admitted,
          ),
        ).catchError(_logFailure),
      );

  void _addToRoster(PresentationBusMessage m) {
    roster[m.connectionId] = PresentationParticipant(
      connectionId: m.connectionId,
      role: m.role ?? PresentationRole.audience,
      deviceLabel: m.deviceLabel ?? '',
      userId: m.userId,
      displayName: m.displayName ?? '',
    );
    _emitRoster();
  }

  void _emitRoster() => _emit(
    PresentationRosterEvent(
      serverTimeMs: _now(),
      participants: roster.values.toList(),
    ),
  );

  void _startGrace() {
    _grace?.cancel();
    _grace = Timer(PresentationService.presenterGrace, () {
      _emit(PresentationEndedEvent(serverTimeMs: _now(), reason: 'expired'));
      _quiet = true;
      unawaited(_close());
    });
  }

  // ------------------------------------------------------------- updates

  Future<void> _handle(PresentationUpdate u) async {
    if (_closed || !verified) return;
    final now = _now();
    if (isPresenter) {
      switch (u) {
        case PresentationStateUpdate(:final state):
          lastState = state;
          lastStateSentAt = now;
          await _send(_msg('state', state: state, sentAtMs: now));
        case PresentationLaserUpdate(:final slideId, :final x, :final y):
          final hide = x == null || y == null;
          if (!hide &&
              now - _lastLaser <
                  1000 ~/ PresentationService.maxLaserPerSecond) {
            return;
          }
          _lastLaser = now;
          await _send(
            _msg('laser', slideId: slideId, x: x, y: y, sentAtMs: now),
            coalesceKey: 'laser:$connectionId',
          );
        case PresentationInkUpdate(
          :final slideId,
          :final op,
          :final strokeId,
          :final strokeJson,
        ):
          if (!const {'add', 'remove', 'clear'}.contains(op)) return;
          if ((strokeJson?.length ?? 0) > PresentationService.maxStrokeBytes) {
            return;
          }
          await _send(
            _msg(
              'ink',
              slideId: slideId,
              inkOp: op,
              strokeId: strokeId,
              strokeJson: strokeJson,
              sentAtMs: now,
            ),
          );
        case PresentationEndUpdate():
          await _send(_msg('end', sentAtMs: now));
          _quiet = true;
          await _close();
        case PresentationPairingUpdate(:final revoke):
          _revokePairings();
          if (revoke == true) return;
          _issuePairing();
        case PresentationCommandUpdate():
          return;
      }
      return;
    }
    if (u is! PresentationCommandUpdate || role == PresentationRole.follower) {
      return;
    }
    if (now - _commandWindowStart >= 1000) {
      _commandWindowStart = now;
      _commandsInWindow = 0;
    }
    if (++_commandsInWindow > PresentationService.maxCommandsPerSecond) return;
    if (u.command.length > 64 || (u.argsJson?.length ?? 0) > 4096) return;
    if (now - _accessCheckedAt > 5000) {
      // Commands of a user who lost access are rejected (10 §6.5).
      try {
        await AccessService.require(session, actor, deckUuid, Role.viewer);
        _accessCheckedAt = now;
      } on Object {
        _emit(PresentationEndedEvent(serverTimeMs: now, reason: 'noAccess'));
        await _close();
        return;
      }
    }
    await _send(
      _msg('command', command: u.command, argsJson: u.argsJson, sentAtMs: now),
    );
  }

  // ------------------------------------- pairing (SL-41, Slides 10 §6.4)

  /// Open pairing keys of this presenter connection: key → (code, expiry,
  /// the listener on the code's channel).
  final Map<String, (String, int, void Function(SerializableModel))> _pairings =
      {};

  /// Accounts whose remote was admitted with a key (they rejoin without).
  final Set<int> _paired = {};

  void _issuePairing() {
    final key = PresentationService.newSessionId();
    final code = PresentationService.newCode();
    final now = _now();
    final expires = now + PresentationService.pairingTtl.inMilliseconds;
    void onCode(SerializableModel m) => _onCode(m, key);
    _pairings[key] = (code, expires, onCode);
    session.messages.addListener(PresentationService.codeChannel(code), onCode);
    _emit(
      PresentationPairingEvent(
        serverTimeMs: now,
        pairingKey: key,
        code: code,
        expiresAtMs: expires,
      ),
    );
  }

  void _dropPairing(String key) {
    final p = _pairings.remove(key);
    if (p == null) return;
    PresentationService.releaseCode(p.$1);
    try {
      session.messages.removeListener(
        PresentationService.codeChannel(p.$1),
        p.$3,
      );
    } on Object {
      // The session is closing.
    }
  }

  void _revokePairings() {
    for (final k in [..._pairings.keys]) {
      _dropPairing(k);
    }
  }

  /// A typed code of pairing [key] asks for its session (`resolveCode`).
  void _onCode(SerializableModel model, String key) {
    if (model is! PresentationBusMessage || _closed || !verified) return;
    final replyTo = model.replyTo;
    if (model.type != 'resolve' || replyTo == null) return;
    final p = _pairings[key];
    if (p == null || p.$2 < _now()) return;
    unawaited(
      PresentationService._post(
        session,
        PresentationService._findChannel(replyTo),
        _msg('resolved', replyTo: replyTo, pairingKey: key),
      ).catchError(_logFailure),
    );
  }

  /// Whether the remote of [m] (another account) may join: a valid,
  /// unexpired key (used up now), or an account paired before.
  bool? _admit(PresentationBusMessage m) {
    if (m.role != PresentationRole.remote || m.userId == actor.userId) {
      return null;
    }
    if (_paired.contains(m.userId)) return true;
    final key = m.pairingKey;
    final p = key == null ? null : _pairings[key];
    if (p == null || p.$2 < _now()) return false;
    _dropPairing(key!);
    _paired.add(m.userId);
    return true;
  }

  // ------------------------------------------------------------- closing

  Future<void> _leave() async {
    if (_left) return;
    _left = true;
    _closed = true;
    _grace?.cancel();
    _revokePairings();
    final wasVerified = verified;
    try {
      _unlisten();
    } on Object {
      // Not listening yet.
    }
    await _input?.cancel();
    if (!wasVerified || _quiet) return;
    try {
      await _send(_msg(isPresenter ? 'away' : 'bye'));
    } on Object {
      // The server is shutting down.
    }
  }

  Future<void> _close() async {
    await _leave();
    if (!out.isClosed) await out.close();
  }
}
