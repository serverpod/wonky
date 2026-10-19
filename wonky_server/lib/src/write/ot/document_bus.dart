import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/cluster/cluster_bus.dart';

/// The `doc:<documentUuid>` channel connecting all editing sessions of a
/// document (Write 03 §2 step 7): remote ops, cursors, participants, meta
/// and role changes. Global scope when Redis is enabled.
abstract final class DocumentBus {
  static String channel(UuidValue documentUuid) => 'doc:${documentUuid.uuid}';

  static Future<void> post(
    Session session,
    UuidValue documentUuid,
    DocBusMessage message,
  ) => ClusterBus.post(
    session,
    channel(documentUuid),
    message,
    // Other instances only need a session's latest cursor and beat.
    coalesceKey: switch (message.type) {
      'cursor' || 'beat' => '${message.type}:${message.originSessionId}',
      _ => null,
    },
    // Ops reach the other instances' editors without the batching delay.
    immediate: message.type == 'op',
  );

  /// Asks every connected session of the document to re-check its role.
  static Future<void> rolesChanged(
    Session session,
    UuidValue documentUuid, {
    int? userId,
  }) => post(
    session,
    documentUuid,
    DocBusMessage(type: 'role', userId: userId),
  );

  /// Broadcasts a metadata change (`DocMetaChanged`).
  static Future<void> metaChanged(
    Session session,
    UuidValue documentUuid,
    DocMetaChanged meta, {
    String? originSessionId,
  }) => post(
    session,
    documentUuid,
    DocBusMessage(type: 'meta', meta: meta, originSessionId: originSessionId),
  );
}
