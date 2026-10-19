import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../sharing/access_service.dart';
import 'drive_events.dart';
import 'drive_views.dart';
import '../cluster/cluster_bus.dart';

/// Per-user state of drive items (specs/05 §2): starred, available
/// offline, recently opened and edited, shortcuts.
abstract final class DriveUserStates {
  static Future<DriveItemUserState> _state(
    Session session,
    int userId,
    DriveItem item,
  ) async {
    final existing = await DriveItemUserState.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(item.id!) & t.userId.equals(userId),
    );
    if (existing != null) return existing;
    try {
      return await DriveItemUserState.db.insertRow(
        session,
        DriveItemUserState(itemId: item.id!, userId: userId),
      );
    } on DatabaseException {
      return (await DriveItemUserState.db.findFirstRow(
        session,
        where: (t) => t.itemId.equals(item.id!) & t.userId.equals(userId),
      ))!;
    }
  }

  static Future<DriveItemView> setStarred(
    Session session,
    Actor actor,
    UuidValue uuid,
    bool starred,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final state = await _state(session, actor.userId, item);
    await DriveItemUserState.db.updateRow(
      session,
      state.copyWith(starred: starred),
      columns: (t) => [t.starred],
    );
    await ClusterBus.post(
      session,
      DriveEvents.channel(actor.userId),
      DriveChangeSignal(kind: DriveChangeKind.updated, itemUuid: item.uuid),
    );
    return DriveViews.one(session, actor.userId, item, role: role);
  }

  static Future<DriveItemView> setPinnedOffline(
    Session session,
    Actor actor,
    UuidValue uuid,
    bool pinned,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    final state = await _state(session, actor.userId, item);
    await DriveItemUserState.db.updateRow(
      session,
      state.copyWith(pinnedOffline: pinned),
      columns: (t) => [t.pinnedOffline],
    );
    await ClusterBus.post(
      session,
      DriveEvents.channel(actor.userId),
      DriveChangeSignal(kind: DriveChangeKind.updated, itemUuid: item.uuid),
    );
    return DriveViews.one(session, actor.userId, item, role: role);
  }

  /// Records that the caller opened [uuid]. A first open through link
  /// sharing adds the item to "Shared with me" (specs/06 §2.2).
  static Future<DriveItemView> markOpened(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    await recordOpen(session, actor, item, role);
    return DriveViews.one(session, actor.userId, item, role: role);
  }

  static Future<void> recordOpen(
    Session session,
    Actor actor,
    DriveItem item,
    Role role,
  ) async {
    final state = await _state(session, actor.userId, item);
    var viaLink = state.viaLink;
    if (!viaLink && item.ownerId != actor.userId) {
      final grant = await DriveItemPermission.db.findFirstRow(
        session,
        where: (t) => t.itemId.equals(item.id!) & t.userId.equals(actor.userId),
      );
      viaLink = grant == null;
    }
    await DriveItemUserState.db.updateRow(
      session,
      state.copyWith(lastOpenedAt: nowUtc(), viaLink: viaLink),
      columns: (t) => [t.lastOpenedAt, t.viaLink],
    );
    // Activity dashboard view counts (specs/07 §6).
    await ActivityService.recordView(session, item.id!, actor.userId);
  }

  /// Records that the caller edited [item] (for "Last modified by me").
  static Future<void> recordEdit(
    Session session,
    int userId,
    DriveItem item,
  ) async {
    final state = await _state(session, userId, item);
    await DriveItemUserState.db.updateRow(
      session,
      state.copyWith(lastEditedAt: nowUtc()),
      columns: (t) => [t.lastEditedAt],
    );
  }

  /// "Add shortcut to My Drive": shows a shared item in [parentUuid] (null =
  /// the caller's root) without moving it.
  static Future<DriveItemView> addShortcut(
    Session session,
    Actor actor,
    UuidValue uuid,
    UuidValue? parentUuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      uuid,
      Role.viewer,
    );
    var parentId = 0;
    if (parentUuid != null) {
      final (parent, _) = await AccessService.require(
        session,
        actor,
        parentUuid,
        Role.editor,
      );
      if (parent.kind != DriveItemKind.folder) {
        throw Errors.invalid('Shortcuts can only be added to folders.');
      }
      parentId = parent.id!;
    }
    final state = await _state(session, actor.userId, item);
    await DriveItemUserState.db.updateRow(
      session,
      state.copyWith(shortcutParentId: parentId),
      columns: (t) => [t.shortcutParentId],
    );
    await ClusterBus.post(
      session,
      DriveEvents.channel(actor.userId),
      DriveChangeSignal(kind: DriveChangeKind.updated, itemUuid: item.uuid),
    );
    return DriveViews.one(session, actor.userId, item, role: role);
  }

  static Future<void> removeShortcut(
    Session session,
    Actor actor,
    UuidValue uuid,
  ) async {
    final item = await AccessService.findItem(session, uuid);
    if (item == null) throw Errors.notFound();
    await DriveItemUserState.db.updateWhere(
      session,
      columnValues: (t) => [t.shortcutParentId(null)],
      where: (t) => t.itemId.equals(item.id!) & t.userId.equals(actor.userId),
    );
    await ClusterBus.post(
      session,
      DriveEvents.channel(actor.userId),
      DriveChangeSignal(kind: DriveChangeKind.updated, itemUuid: item.uuid),
    );
  }
}
