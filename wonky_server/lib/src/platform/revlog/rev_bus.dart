import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../cluster/cluster_bus.dart';
import '../common/models.dart';
import 'rev_file_state.dart';

/// The `rev:<fileUuid>` channel (RevLog spec 05 §5): committed ops, role
/// re-checks, the editor roster and purges.
abstract final class RevBus {
  /// Ops whose view JSON is larger travel without it; receivers read them
  /// from `rev_op`.
  static const maxInlineOpBytes = 64 << 10;

  /// The channel of [fileUuid].
  static String channel(UuidValue fileUuid) => 'rev:${fileUuid.uuid}';

  /// Posts a committed op (immediately, in revision order per instance).
  static Future<void> postOp(
    Session session,
    UuidValue fileUuid,
    RevOpView view,
  ) {
    // A payload too big to inline is not encoded at all (base64 grows the
    // gzip by a third).
    final payload =
        (view.payload?.length ?? 0) +
        (view.payloadGz?.lengthInBytes ?? 0) * 4 ~/ 3;
    final json = payload > maxInlineOpBytes ? null : jsonEncode(view.toJson());
    return ClusterBus.post(
      session,
      channel(fileUuid),
      RevBusMessage(
        type: 'op',
        revision: view.revision,
        opJson: json != null && json.length <= maxInlineOpBytes ? json : null,
        originSessionId: view.authorSessionId,
      ),
      immediate: true,
    );
  }

  /// Asks every connection of the file to re-check its role ([userId] null:
  /// everyone).
  static Future<void> rolesChanged(
    Session session,
    UuidValue fileUuid, {
    int? userId,
  }) => ClusterBus.post(
    session,
    channel(fileUuid),
    RevBusMessage(type: 'role', userId: userId),
    immediate: true,
  );

  /// Tells every instance that the file is being purged.
  static Future<void> purged(Session session, UuidValue fileUuid) =>
      ClusterBus.post(
        session,
        channel(fileUuid),
        RevBusMessage(type: 'purged'),
        immediate: true,
      );

  /// Posts a roster message (`hello`, `here`, `beat`, `left`).
  static Future<void> roster(
    Session session,
    UuidValue fileUuid,
    RevBusMessage message,
  ) => ClusterBus.post(
    session,
    channel(fileUuid),
    message,
    coalesceKey: message.type == 'beat'
        ? 'beat:${message.originSessionId}'
        : null,
  );

  /// Keeps [state] current from the bus: ops of this and other instances
  /// advance it in revision order; a gap (lost or reordered message, large
  /// op) is filled from `rev_op`. Returns the detacher.
  static void Function() attach(Serverpod pod, RevFileState state) {
    Session? session;
    var detached = false;
    void onMessage(SerializableModel m) {
      if (m is! RevBusMessage || session == null) return;
      final s = session!;
      switch (m.type) {
        case 'op':
          final rev = m.revision;
          if (rev == null || rev <= state.revision) return;
          final json = m.opJson;
          if (json != null && rev == state.revision + 1) {
            state.advance(
              Protocol().deserialize<RevOpView>(jsonDecode(json)),
            );
          } else {
            unawaited(
              state.ensureAtLeast(s, rev).catchError((Object e) {
                s.log(
                  'Catching up ${state.fileUuid.uuid} failed: $e',
                  level: LogLevel.warning,
                );
              }),
            );
          }
        case 'purged':
          state.purged = true;
          RevFileStates.evict(state.fileUuid);
      }
    }

    unawaited(() async {
      final created = await pod.createSession(enableLogging: false);
      if (detached) {
        await created.close();
        return;
      }
      session = created;
      created.messages.addListener(channel(state.fileUuid), onMessage);
    }());
    return () {
      detached = true;
      final s = session;
      if (s == null) return;
      s.messages.removeListener(channel(state.fileUuid), onMessage);
      unawaited(s.close());
    };
  }
}
