import 'package:serverpod/serverpod.dart';

import '../../generated/future_calls.dart';
import '../revlog/rev_bus.dart';
import '../../write/ot/document_bus.dart';
import '../common/models.dart';
import '../drive/drive_events.dart';
import 'access_service.dart';

/// Propagates permission changes (specs/06 §3): drive lists of affected users,
/// open RevLog sessions (`RevRoleChanged`) and open document streams
/// (`DocRoleChanged`).
///
/// The drive fan-out is batched (CQ-26): the interested users of a whole
/// subtree in a few queries and one signal per user. Subtrees larger than
/// [inlineNodes] are fanned out by a future call ([AclFutureCall]) right
/// after the request, so a share or move of a big folder answers at once.
abstract final class AclEvents {
  /// Subtree size up to which the fan-out runs in the request.
  static int inlineNodes = 200;

  /// Schedules the deferred fan-out (tests replace it to run inline).
  static Future<void> Function(
    Session session,
    int itemId,
    DriveChangeKind kind,
    Set<int> affectedUsers,
  )
  schedule = scheduleFutureCall;

  /// The default [schedule]: [AclFutureCall] without delay.
  static Future<void> scheduleFutureCall(
    Session session,
    int itemId,
    DriveChangeKind kind,
    Set<int> affectedUsers,
  ) => session.serverpod.futureCalls
      .callWithDelay(Duration.zero)
      .acl
      .fanOut(itemId, kind.name, affectedUsers.toList());

  /// Call after grants, links, ownership, trash state or the position of
  /// [item] changed. [affectedUsers] are users who may have lost access and
  /// must be notified as well. Folders propagate to their descendants.
  static Future<void> changed(
    Session session,
    DriveItem item, {
    Set<int> affectedUsers = const {},
    DriveChangeKind kind = DriveChangeKind.shared,
  }) async {
    final nodes = item.kind == DriveItemKind.folder
        ? await AccessService.subtree(session, item)
        : [item];
    if (nodes.length > inlineNodes) {
      await schedule(session, item.id!, kind, affectedUsers);
      return;
    }
    await fanOut(session, nodes, kind: kind, affectedUsers: affectedUsers);
  }

  /// The deferred [changed] of item [itemId] (from [AclFutureCall]).
  static Future<int> fanOutDeferred(
    Session session,
    int itemId,
    DriveChangeKind kind,
    Set<int> affectedUsers,
  ) async {
    final item = await DriveItem.db.findById(session, itemId);
    if (item == null) return 0;
    final nodes = item.kind == DriveItemKind.folder
        ? await AccessService.subtree(session, item)
        : [item];
    await fanOut(session, nodes, kind: kind, affectedUsers: affectedUsers);
    return nodes.length;
  }

  /// Notifies the drive watchers of [nodes] (batched) and the open editing
  /// sessions of their files.
  static Future<void> fanOut(
    Session session,
    List<DriveItem> nodes, {
    required DriveChangeKind kind,
    Set<int> affectedUsers = const {},
  }) async {
    await DriveEvents.notifyAll(
      session,
      nodes,
      kind,
      alsoNotify: affectedUsers,
    );
    for (final node in nodes) {
      switch (node.kind) {
        case DriveItemKind.spreadsheet || DriveItemKind.presentation:
          // Open RevLog sessions re-check their role (RevLog spec 05 §4).
          if (node.contentRef != null) {
            await RevBus.rolesChanged(session, node.contentRef!);
          }
        case DriveItemKind.document:
          if (node.contentRef != null) {
            await DocumentBus.rolesChanged(session, node.contentRef!);
          }
        case DriveItemKind.folder:
        case DriveItemKind.file:
          break;
      }
    }
  }
}
