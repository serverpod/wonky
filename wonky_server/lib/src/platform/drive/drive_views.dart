import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../common/actor.dart';
import '../common/models.dart';
import '../common/roles.dart';
import '../sharing/access_service.dart';
import '../users/user_service.dart';

/// Builds [DriveItemView]s for a user in batches.
abstract final class DriveViews {
  static Future<DriveItemView> one(
    Session session,
    int userId,
    DriveItem item, {
    Role? role,
  }) async {
    final views = await build(
      session,
      userId,
      [item],
      roles: role == null ? null : {item.id!: role},
    );
    return views.single;
  }

  /// Views of [items] for [userId]. Items the user cannot access are left
  /// out unless [roles] provides their role.
  static Future<List<DriveItemView>> build(
    Session session,
    int userId,
    List<DriveItem> items, {
    Map<int, Role>? roles,
  }) async {
    if (items.isEmpty) return const [];
    final effective =
        roles ?? await AccessService.rolesFor(session, userId, items);
    final visible = [
      for (final item in items)
        if (effective[item.id!] != null) item,
    ];
    if (visible.isEmpty) return const [];
    final ids = {for (final i in visible) i.id!};

    final states = await DriveItemUserState.db.find(
      session,
      where: (t) => t.itemId.inSet(ids) & t.userId.equals(userId),
    );
    final stateByItem = {for (final s in states) s.itemId: s};

    final links = await ShareLink.db.find(
      session,
      where: (t) => t.itemId.inSet(ids),
    );
    final linkByItem = {for (final l in links) l.itemId: l};

    final shared = <int>{};
    final perms = await DriveItemPermission.db.find(
      session,
      where: (t) => t.itemId.inSet(ids),
    );
    final ownerById = {for (final i in visible) i.id!: i.ownerId};
    for (final p in perms) {
      if (p.userId != ownerById[p.itemId] || p.invitedEmail != null) {
        shared.add(p.itemId);
      }
    }

    final parentIds = {for (final i in visible) ?i.parentId};
    final parents = parentIds.isEmpty
        ? <DriveItem>[]
        : await DriveItem.db.find(
            session,
            where: (t) => t.id.inSet(parentIds),
          );
    final parentUuid = {for (final p in parents) p.id!: p.uuid};

    final users = await UserService.summaries(session, [
      for (final i in visible) ...[i.ownerId, i.modifiedById],
    ]);
    if (userId == Actor.anonymousUserId) {
      // Signed-out viewers never see emails (specs/06 §2.4).
      users.updateAll((_, u) => u.copyWith(email: ''));
    }

    return [
      for (final item in visible)
        if (users[item.ownerId] != null)
          DriveItemView(
            uuid: item.uuid,
            kind: item.kind,
            name: item.name,
            description: item.description,
            contentRef: item.contentRef,
            parentUuid: item.parentId == null || userId == Actor.anonymousUserId
                ? null
                : parentUuid[item.parentId],
            owner: users[item.ownerId]!,
            role: effective[item.id!]!.access,
            shared:
                shared.contains(item.id) || linkByItem[item.id!]?.role != null,
            linkRole: linkByItem[item.id!]?.role,
            thumbnailFileId: item.thumbnailFileId,
            sizeBytes: item.sizeBytes,
            createdAt: item.createdAt,
            modifiedAt: item.modifiedAt,
            modifiedBy: item.modifiedById == null
                ? null
                : users[item.modifiedById],
            trashedAt: item.trashedAt,
            templateOf: item.templateOf,
            starred: stateByItem[item.id!]?.starred ?? false,
            pinnedOffline: stateByItem[item.id!]?.pinnedOffline ?? false,
            lastOpenedAt: stateByItem[item.id!]?.lastOpenedAt,
            lastEditedAt: stateByItem[item.id!]?.lastEditedAt,
            editorsCanShare: item.editorsCanShare,
            nonEditorsCanExport: item.nonEditorsCanExport,
            viewersSeeComments: item.viewersSeeComments,
            attachmentBytes: item.attachmentBytes,
            countedBytes: item.sizeBytes + item.attachmentBytes,
            mimeType: item.mimeType,
            fileCategory: item.fileCategory,
            uploadState: item.uploadState,
            fileMetaJson: item.fileMetaJson,
            previewFileId: item.previewFileId,
          ),
    ];
  }
}
