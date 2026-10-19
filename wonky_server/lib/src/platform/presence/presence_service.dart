import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../cluster/cluster.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../common/time.dart';
import '../sharing/access_service.dart';
import '../users/user_service.dart';
import '../cluster/cluster_bus.dart';
import '../drive/drive_events.dart';

/// Ephemeral presence (specs/07 §1). Nothing is stored: every joined session
/// keeps its own view of the roster from the `presence:<itemUuid>` channel
/// (global with Redis), so it works across server instances. A new session
/// says `hello`, everyone present answers `here`. With several instances
/// every session also sends a `beat` every [heartbeatInterval]; sessions
/// not heard of for three intervals leave the roster (their instance
/// crashed or the `bye` was lost; specs/13 §4).
abstract final class PresenceService {
  /// Variable for tests.
  static Duration heartbeatInterval = const Duration(seconds: 30);

  /// Max hint messages per second and cells per message (Sheets 10 §2.1).
  static const maxHintsPerSecond = 20;
  static const maxHintCells = 500;
  static const maxHintBytes = 64 * 1024;

  /// Largest cursor (`cursorJson`) relayed; larger updates are dropped.
  static const maxCursorBytes = 8 * 1024;

  /// Longest `mode` and followed session id accepted.
  static const maxShortField = 64;

  /// State/cursor/follow updates relayed per second and session; more are
  /// coalesced (the latest one is sent when the window ends).
  static const maxUpdatesPerSecond = 20;

  /// How often a joined session re-checks its access without an ACL
  /// change signal (expired grants have none). Variable for tests.
  static Duration accessRecheckInterval = const Duration(minutes: 5);

  static String channel(UuidValue itemUuid) => 'presence:${itemUuid.uuid}';

  static Stream<PresenceEvent> join(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    Stream<PresenceUpdate> updates,
  ) {
    late StreamController<PresenceEvent> out;
    final sessionId = const Uuid().v4();
    final roster = <String, Participant>{};
    final lastSeen = <String, DateTime>{};
    Timer? heartbeat;
    final followers = <String, String>{}; // follower → target
    var role = Role.viewer;
    Participant? me;
    StreamSubscription<PresenceUpdate>? input;
    var closed = false;
    var hintWindowStart = DateTime.fromMillisecondsSinceEpoch(0);
    var hintsInWindow = 0;
    var updateWindowStart = DateTime.fromMillisecondsSinceEpoch(0);
    var updatesInWindow = 0;
    PresenceUpdate? pendingUpdate;
    Timer? flushTimer;
    Timer? recheckTimer;
    var rechecking = false;
    var recheckAgain = false;
    String? following;
    final ch = channel(itemUuid);
    final driveCh = DriveEvents.channel(actor.userId);

    void emit(PresenceEvent e) {
      if (!out.isClosed) out.add(e);
    }

    void logFailure(String what, Object e, [StackTrace? st]) {
      try {
        session.log(
          'presence: $what failed: $e',
          level: LogLevel.warning,
          stackTrace: st,
        );
      } on Object {
        // The session is closing.
      }
    }

    void emitFollowerCount() {
      final count = followers.values.where((t) => t == sessionId).length;
      emit(PresenceFollowerCount(count: count));
    }

    void onBus(SerializableModel model) {
      if (model is! PresenceBusMessage || closed) return;
      final m = model;
      if (m.sessionId == sessionId) return;
      lastSeen[m.sessionId] = clock.now();
      switch (m.type) {
        case 'beat':
          final p = m.participant;
          if (p == null || roster.containsKey(m.sessionId)) return;
          roster[m.sessionId] = p;
          emit(PresenceJoined(participant: p));
        case 'hello':
          final p = m.participant;
          if (p == null) return;
          roster[p.sessionId] = p;
          emit(PresenceJoined(participant: p));
          if (me != null) {
            unawaited(
              ClusterBus.post(
                session,
                ch,
                PresenceBusMessage(
                  type: 'here',
                  sessionId: sessionId,
                  participant: me,
                  replyTo: m.sessionId,
                ),
              ).catchError((Object e, StackTrace st) {
                logFailure('here', e, st);
              }),
            );
          }
        case 'probe':
          // (v2, Slides 11 §2.1) A server-side observer (headless soft-lock
          // check) asks who is here without joining the roster.
          if (me != null) {
            unawaited(
              ClusterBus.post(
                session,
                ch,
                PresenceBusMessage(
                  type: 'here',
                  sessionId: sessionId,
                  participant: me,
                  replyTo: m.sessionId,
                ),
              ).catchError((Object e, StackTrace st) {
                logFailure('here', e, st);
              }),
            );
          }
        case 'here':
          if (m.replyTo != sessionId || m.participant == null) return;
          if (!roster.containsKey(m.sessionId)) {
            roster[m.sessionId] = m.participant!;
            emit(PresenceJoined(participant: m.participant!));
          }
        case 'update':
          final p = roster[m.sessionId];
          if (p == null || m.state == null) return;
          roster[m.sessionId] = p.copyWith(
            state: m.state,
            cursorJson: m.cursorJson,
            mode: m.mode,
          );
          emit(
            PresenceUpdated(
              sessionId: m.sessionId,
              state: m.state!,
              cursorJson: m.cursorJson,
              mode: m.mode,
            ),
          );
        case 'hints':
          if (m.hints != null && m.hints!.isNotEmpty) {
            emit(PresenceHints(sessionId: m.sessionId, hints: m.hints!));
          }
        case 'follow':
          final before = followers[m.sessionId];
          if (m.target == null) {
            followers.remove(m.sessionId);
          } else {
            followers[m.sessionId] = m.target!;
          }
          if (before == sessionId || m.target == sessionId) {
            emitFollowerCount();
          }
        case 'bye':
          lastSeen.remove(m.sessionId);
          if (roster.remove(m.sessionId) != null) {
            emit(PresenceLeft(sessionId: m.sessionId));
          }
          if (followers.remove(m.sessionId) == sessionId) emitFollowerCount();
        case 'notice':
          emit(
            PresenceNotice(
              kind: m.noticeKind ?? 'notice',
              payloadJson: m.noticePayloadJson ?? '{}',
            ),
          );
      }
    }

    void beat() {
      if (closed || me == null) return;
      unawaited(
        ClusterBus.post(
          session,
          ch,
          PresenceBusMessage(
            type: 'beat',
            sessionId: sessionId,
            participant: me,
          ),
          coalesceKey: 'beat:$sessionId',
        ).catchError((Object _) {}),
      );
      final now = clock.now();
      final cutoff = now.subtract(heartbeatInterval * 3);
      for (final id in roster.keys.toList()) {
        final seen = lastSeen[id];
        if (seen == null) {
          lastSeen[id] = now;
          continue;
        }
        if (seen.isAfter(cutoff)) continue;
        roster.remove(id);
        lastSeen.remove(id);
        emit(PresenceLeft(sessionId: id));
        if (followers.remove(id) == sessionId) emitFollowerCount();
      }
    }

    late final void Function(SerializableModel) onDrive;

    Future<void> leave() async {
      if (closed) return;
      closed = true;
      heartbeat?.cancel();
      flushTimer?.cancel();
      recheckTimer?.cancel();
      session.messages.removeListener(ch, onBus);
      session.messages.removeListener(driveCh, onDrive);
      await input?.cancel();
      await ClusterBus.post(
        session,
        ch,
        PresenceBusMessage(type: 'bye', sessionId: sessionId),
      );
    }

    /// Ends the stream of a user who lost access (`notFound`, like a join
    /// without access).
    Future<void> revoke() async {
      if (!out.isClosed) out.addError(Errors.notFound());
      await leave();
      if (!out.isClosed) await out.close();
    }

    /// Re-resolves the role; closes the stream without viewer access.
    /// Concurrent requests run once more after the current one.
    Future<void> recheck() async {
      if (closed || me == null) return;
      if (rechecking) {
        recheckAgain = true;
        return;
      }
      rechecking = true;
      try {
        do {
          recheckAgain = false;
          Role? now;
          try {
            (_, now) = await AccessService.require(
              session,
              actor,
              itemUuid,
              Role.viewer,
            );
          } on WonkyException catch (e) {
            if (e.code != WonkyErrorCode.notFound &&
                e.code != WonkyErrorCode.forbidden) {
              rethrow;
            }
          }
          if (closed) return;
          if (now == null) {
            await revoke();
            return;
          }
          role = now;
          me = me!.copyWith(role: now.access);
        } while (recheckAgain && !closed);
      } on Object catch (e, st) {
        // Database trouble: keep the stream; the next check decides.
        logFailure('access re-check', e, st);
      } finally {
        rechecking = false;
      }
    }

    onDrive = (SerializableModel model) {
      if (closed || model is! DriveChangeSignal) return;
      if (model.itemUuid != itemUuid) return;
      unawaited(recheck());
    };

    /// Relays the state, cursor and followed session of [u].
    Future<void> relay(PresenceUpdate u) async {
      if (closed || me == null) return;
      me = me!.copyWith(state: u.state, cursorJson: u.cursorJson, mode: u.mode);
      await ClusterBus.post(
        session,
        ch,
        PresenceBusMessage(
          type: 'update',
          sessionId: sessionId,
          state: u.state,
          cursorJson: u.cursorJson,
          mode: u.mode,
        ),
        // Other instances only need the latest state and cursor.
        coalesceKey: 'update:$sessionId',
      );
      if (u.followingSessionId != following) {
        following = u.followingSessionId;
        await ClusterBus.post(
          session,
          ch,
          PresenceBusMessage(
            type: 'follow',
            sessionId: sessionId,
            target: following,
          ),
        );
      }
    }

    /// Takes one of this second's [maxUpdatesPerSecond] relays; else
    /// returns the time left in the window.
    Duration? takeUpdateSlot() {
      final now = clock.now();
      final elapsed = now.difference(updateWindowStart);
      if (elapsed >= const Duration(seconds: 1)) {
        updateWindowStart = now;
        updatesInWindow = 0;
      }
      if (updatesInWindow >= maxUpdatesPerSecond) {
        return const Duration(seconds: 1) - now.difference(updateWindowStart);
      }
      updatesInWindow++;
      return null;
    }

    void flush() {
      flushTimer = null;
      final u = pendingUpdate;
      if (u == null || closed) return;
      final wait = takeUpdateSlot();
      if (wait != null) {
        flushTimer = Timer(wait, flush);
        return;
      }
      pendingUpdate = null;
      unawaited(
        relay(u).catchError((Object e, StackTrace st) {
          logFailure('update', e, st);
        }),
      );
    }

    Future<void> handle(PresenceUpdate u) async {
      if (closed || me == null) return;
      if ((u.cursorJson?.length ?? 0) > maxCursorBytes ||
          (u.mode?.length ?? 0) > maxShortField ||
          (u.followingSessionId?.length ?? 0) > maxShortField) {
        return;
      }
      final wait = takeUpdateSlot();
      if (wait == null) {
        pendingUpdate = null;
        await relay(u);
      } else {
        // Over the rate: only the latest update is sent, when the window
        // ends.
        pendingUpdate = u;
        flushTimer ??= Timer(wait, flush);
      }
      final hints = u.hints;
      if (hints != null && hints.isNotEmpty && role >= Role.editor) {
        final now = nowUtc();
        if (now.difference(hintWindowStart) > const Duration(seconds: 1)) {
          hintWindowStart = now;
          hintsInWindow = 0;
        }
        final accepted = <String>[];
        for (final h in hints) {
          if (hintsInWindow >= maxHintsPerSecond) break;
          if (h.length > maxHintBytes || !_validHint(h)) continue;
          accepted.add(h);
          hintsInWindow++;
        }
        if (accepted.isNotEmpty) {
          await ClusterBus.post(
            session,
            ch,
            PresenceBusMessage(
              type: 'hints',
              sessionId: sessionId,
              hints: accepted,
            ),
          );
        }
      }
    }

    Future<void> start() async {
      final (item, r) = await AccessService.require(
        session,
        actor,
        itemUuid,
        Role.viewer,
      );
      role = r;
      final profile = await UserService.requireProfile(session, actor.userId);
      final summary = await UserService.summaryOf(session, profile);
      me = Participant(
        sessionId: sessionId,
        userId: actor.userId,
        userUuid: actor.authUserId,
        displayName: summary.displayName,
        avatarUrl: summary.avatarUrl,
        colorIndex: summary.colorIndex,
        role: role.access,
        actorKind: actor.kind,
        state: PresenceState.active,
        joinedAt: nowUtc(),
      );
      session.messages.addListener(ch, onBus);
      // Access is re-checked when the item's ACL changes (the user's drive
      // channel) and periodically (grants that expire send no signal).
      session.messages.addListener(driveCh, onDrive);
      recheckTimer = Timer.periodic(
        accessRecheckInterval,
        (_) => unawaited(recheck()),
      );
      await ClusterBus.post(
        session,
        ch,
        PresenceBusMessage(
          type: 'hello',
          sessionId: sessionId,
          participant: me,
        ),
      );
      emit(
        PresenceRoster(
          sessionId: sessionId,
          participants: [me!, ...roster.values],
        ),
      );
      input = updates.listen(
        (u) => unawaited(
          handle(u).catchError((Object e, StackTrace st) {
            logFailure('update', e, st);
          }),
        ),
        onDone: () async {
          await leave();
          if (!out.isClosed) await out.close();
        },
        onError: (Object _) async {
          await leave();
          if (!out.isClosed) await out.close();
        },
      );
      session.addWillCloseListener((_) => leave());
      if (Cluster.distributed) {
        heartbeat = Timer.periodic(heartbeatInterval, (_) => beat());
      }
      if (item.trashedAt != null) {
        emit(PresenceNotice(kind: 'trashed', payloadJson: '{}'));
      }
    }

    out = StreamController<PresenceEvent>(
      onListen: () {
        unawaited(
          start().catchError((Object e, StackTrace st) {
            if (!out.isClosed) {
              out.addError(e, st);
              unawaited(out.close());
            }
          }),
        );
      },
      onCancel: leave,
    );
    return out.stream;
  }

  static bool _validHint(String json) {
    try {
      final value = jsonDecode(json);
      if (value is! Map) return false;
      final cells = value['cells'];
      if (cells is List && cells.length > maxHintCells) return false;
      return true;
    } on FormatException {
      return false;
    }
  }

  /// Shows an agent (MCP/AI) as a transient participant on [itemUuid] for
  /// [ttl] (specs/07 §1.1). Returns its session id. Passing the [sessionId]
  /// of an earlier call updates that participant (e.g. its [cursorJson],
  /// Sheets 10 §1.1); a null [ttl] leaves removing it to the caller
  /// ([removeAgent]).
  static Future<String> injectAgent(
    Session session,
    UuidValue itemUuid, {
    required Actor actor,
    required String displayName,
    Duration? ttl = const Duration(seconds: 30),
    String? sessionId,
    String? cursorJson,
  }) async {
    final id = sessionId ?? 'agent-${const Uuid().v4()}';
    final participant = Participant(
      sessionId: id,
      userId: actor.userId,
      userUuid: actor.authUserId,
      displayName: displayName,
      colorIndex: UserService.colorIndexFor(actor.authUserId),
      role: AccessRole.editor,
      actorKind: actor.kind,
      state: PresenceState.active,
      mode: 'editing',
      cursorJson: cursorJson,
      joinedAt: nowUtc(),
    );
    final ch = channel(itemUuid);
    await ClusterBus.post(
      session,
      ch,
      PresenceBusMessage(
        type: 'hello',
        sessionId: id,
        participant: participant,
      ),
    );
    if (ttl != null) {
      final pod = session.serverpod;
      Timer(ttl, () {
        unawaited(
          ClusterBus.postOn(
            pod,
            ch,
            PresenceBusMessage(type: 'bye', sessionId: id),
          ),
        );
      });
    }
    return id;
  }

  /// Removes an agent participant added by [injectAgent].
  static void removeAgent(
    Serverpod pod,
    UuidValue itemUuid,
    String sessionId,
  ) => ClusterBus.postOn(
    pod,
    channel(itemUuid),
    PresenceBusMessage(type: 'bye', sessionId: sessionId),
  );

  /// Broadcasts a system notice to everyone on [itemUuid].
  static Future<void> notice(
    Session session,
    UuidValue itemUuid,
    String kind,
    Map<String, Object?> payload,
  ) => ClusterBus.post(
    session,
    channel(itemUuid),
    PresenceBusMessage(
      type: 'notice',
      sessionId: 'system',
      noticeKind: kind,
      noticePayloadJson: jsonEncode(payload),
    ),
  );
}
