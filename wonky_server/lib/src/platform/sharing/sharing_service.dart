import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/rate_limiter.dart';
import '../common/roles.dart';
import '../common/time.dart';
import '../drive/drive_service.dart';
import '../drive/drive_user_state.dart';
import '../notifications/notification_service.dart';
import '../storage/storage_service.dart';
import '../users/user_service.dart';
import 'access_service.dart';
import 'acl_events.dart';

/// Sharing (specs/06 §2, §4). Sharing changes are not undoable.
abstract final class SharingService {
  /// The columns a role change writes (never the whole grant row).
  static List<Column<Object?>> _grantColumns(DriveItemPermissionTable t) => [
    t.role,
    t.grantedById,
    t.grantedAt,
    t.expiresAt,
    t.viaPublicationId,
  ];

  static final _random = Random.secure();
  static const _tokenAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Longest message of an access request.
  static const maxRequestMessage = 1000;

  /// Access requests per requester and item (specs/13 §4).
  static final _requestLimiter = RateLimiter(
    name: 'sharing.requestAccess',
    limit: 5,
    window: const Duration(hours: 1),
  );

  /// Clears the in-memory request limits (tests).
  static void resetLimits() => _requestLimiter.reset();

  static String newToken() => String.fromCharCodes([
    for (var i = 0; i < 22; i++)
      _tokenAlphabet.codeUnitAt(_random.nextInt(_tokenAlphabet.length)),
  ]);

  static Future<(DriveItem, Role)> _requireSharer(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    if (!AccessService.canShare(item, role)) {
      throw Errors.forbidden('You cannot share this item.');
    }
    return (item, role);
  }

  /// Refuses [userId] as the target of a role change or an ownership
  /// transfer unless they already have access to [item] or are related to
  /// [actor] (share or mention them first); unknown ids are not found.
  static Future<void> _requireKnownTarget(
    Session session,
    Actor actor,
    DriveItem item,
    int userId,
  ) async {
    if (await AccessService.effectiveRole(session, userId, item) != null) {
      return;
    }
    final related = await UserService.relatedIds(session, actor, [userId]);
    if (!related.contains(userId)) throw Errors.notFound('User');
  }

  // ------------------------------------------------------------------ read

  static Future<SharingInfo> getSharing(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    final canShare = AccessService.canShare(item, role);
    final now = nowUtc();
    final grants = await DriveItemPermission.db.find(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          (t.expiresAt.equals(null) | (t.expiresAt > now)),
    );
    final sourceIds = {for (final g in grants) ?g.inheritedFromId};
    final sources = sourceIds.isEmpty
        ? <DriveItem>[]
        : await DriveItem.db.find(
            session,
            where: (t) => t.id.inSet(sourceIds),
          );
    final sourceById = {for (final s in sources) s.id!: s};
    final users = await UserService.summaries(session, [
      item.ownerId,
      for (final g in grants) g.userId,
    ]);
    // One entry per person: the highest grant (direct grants win ties).
    final best = <String, DriveItemPermission>{};
    for (final g in grants) {
      if (g.userId == item.ownerId) continue;
      final key = g.userId != null ? 'u${g.userId}' : 'e${g.invitedEmail}';
      final prev = best[key];
      if (prev == null ||
          g.role.index > prev.role.index ||
          g.role == prev.role && g.inheritedFromId == null) {
        best[key] = g;
      }
    }
    // (M14) Moderator grants show the publication's name (specs/18 §5.1).
    final publications = {
      for (final p in await Publication.db.find(
        session,
        where: (t) => t.id.inSet(<int>{
          for (final g in best.values)
            if (g.viaPublicationId != null) g.viaPublicationId!,
        }),
      ))
        p.id!: p.name,
    };
    final permissions = [
      for (final g in best.values)
        PermissionView(
          user: g.userId == null ? null : users[g.userId],
          invitedEmail: g.invitedEmail,
          role: g.role,
          inheritedFromUuid: g.inheritedFromId == null
              ? null
              : sourceById[g.inheritedFromId]?.uuid,
          inheritedFromName: g.inheritedFromId == null
              ? null
              : sourceById[g.inheritedFromId]?.name,
          grantedAt: g.grantedAt,
          expiresAt: g.expiresAt,
          viaPublication: g.viaPublicationId == null
              ? null
              : publications[g.viaPublicationId],
        ),
    ]..sort((a, b) => b.role.index.compareTo(a.role.index));
    final link = await ShareLink.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(item.id!),
    );
    final requests = canShare
        ? await AccessRequest.db.find(
            session,
            where: (t) => t.itemId.equals(item.id!) & t.handledAt.equals(null),
            orderBy: (t) => t.createdAt,
          )
        : <AccessRequest>[];
    final requesters = await UserService.summaries(session, [
      for (final r in requests) r.requesterId,
    ]);
    final transfer = await OwnershipTransfer.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(item.id!) & t.handledAt.equals(null),
    );
    return SharingInfo(
      itemUuid: item.uuid,
      itemName: item.name,
      itemKind: item.kind,
      owner: users[item.ownerId]!,
      myRole: role.access,
      canShare: canShare,
      permissions: permissions,
      link: canShare || link?.role != null
          ? (link == null
                ? null
                : ShareLinkView(token: link.token, role: link.role))
          : null,
      settings: ItemSharingSettings(
        editorsCanShare: item.editorsCanShare,
        nonEditorsCanExport: item.nonEditorsCanExport,
        viewersSeeComments: item.viewersSeeComments,
      ),
      pendingRequests: [
        for (final r in requests)
          if (requesters[r.requesterId] != null)
            AccessRequestView(
              id: r.id!,
              itemUuid: item.uuid,
              requester: requesters[r.requesterId]!,
              requestedRole: r.requestedRole,
              message: r.message,
              createdAt: r.createdAt,
            ),
      ],
      pendingTransfer: transfer == null || !canShare
          ? null
          : await _transferView(session, item, transfer),
    );
  }

  static Future<OwnershipTransferView?> _transferView(
    Session session,
    DriveItem item,
    OwnershipTransfer t,
  ) async {
    final users = await UserService.summaries(session, [
      t.fromUserId,
      t.toUserId,
    ]);
    if (users[t.fromUserId] == null || users[t.toUserId] == null) return null;
    return OwnershipTransferView(
      id: t.id!,
      itemUuid: item.uuid,
      itemName: item.name,
      from: users[t.fromUserId]!,
      to: users[t.toUserId]!,
      createdAt: t.createdAt,
    );
  }

  // ----------------------------------------------------------------- write

  /// Grants [role] to people by email. Unknown addresses become pending
  /// invites converted at sign-up.
  static Future<SharingInfo> share(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    required List<String> emails,
    required AccessRole role,
    bool notify = true,
    String? message,
    DateTime? expiresAt,
  }) async {
    final (item, myRole) = await _requireSharer(session, actor, itemUuid);
    if (role == AccessRole.owner) {
      throw Errors.invalid('Use transferOwnership to change the owner.');
    }
    if (role.role > myRole) throw Errors.forbidden();
    if (expiresAt != null && !expiresAt.isAfter(nowUtc())) {
      throw Errors.invalid('The expiration must be in the future.');
    }
    final normalized = {
      for (final e in emails) e.trim().toLowerCase(),
    }..remove('');
    if (normalized.isEmpty) throw Errors.invalid('Add at least one person.');
    if (normalized.length > 100) {
      throw Errors.invalid('Share with at most 100 people at a time.');
    }
    for (final e in normalized) {
      if (!_emailPattern.hasMatch(e)) {
        throw Errors.invalid('"$e" is not a valid email address.');
      }
    }
    final profiles = await UserProfile.db.find(
      session,
      where: (t) => t.email.inSet(normalized),
    );
    final byEmail = {for (final p in profiles) p.email: p};
    final now = nowUtc();
    final notified = <int>[];
    await session.db.transaction((tx) async {
      for (final email in normalized) {
        final profile = byEmail[email];
        if (profile?.id == item.ownerId) continue;
        final existing = await DriveItemPermission.db.findFirstRow(
          session,
          where: (t) =>
              t.itemId.equals(item.id!) &
              t.inheritedFromId.equals(null) &
              (profile == null
                  ? t.invitedEmail.equals(email)
                  : t.userId.equals(profile.id!)),
          transaction: tx,
        );
        if (existing != null) {
          await DriveItemPermission.db.updateRow(
            session,
            existing.copyWith(
              role: role,
              grantedById: actor.userId,
              grantedAt: now,
              expiresAt: expiresAt,
              // A moderator grant shared directly becomes a direct grant.
              viaPublicationId: null,
            ),
            columns: _grantColumns,
            transaction: tx,
          );
        } else {
          await DriveItemPermission.db.insertRow(
            session,
            DriveItemPermission(
              itemId: item.id!,
              userId: profile?.id,
              invitedEmail: profile == null ? email : null,
              role: role,
              grantedById: actor.userId,
              grantedAt: now,
              expiresAt: expiresAt,
            ),
            transaction: tx,
          );
          if (profile != null) notified.add(profile.id!);
        }
      }
      if (item.kind == DriveItemKind.folder) {
        await AccessService.rebuildInherited(session, item, transaction: tx);
      }
    });
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.shared,
      summary: {'emails': normalized.toList(), 'role': role.name},
    );
    await AclEvents.changed(session, item);
    if (notify) {
      for (final userId in notified) {
        await NotificationService.notify(
          session,
          userId: userId,
          kind: NotificationKind.shared,
          item: item,
          actor: actor,
          payload: {
            'role': role.name,
            if (message != null && message.trim().isNotEmpty)
              'message': message.trim(),
          },
        );
      }
    }
    return getSharing(session, actor, itemUuid);
  }

  static Future<SharingInfo> updateRole(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    int userId,
    AccessRole role, {
    DateTime? expiresAt,
  }) async {
    final (item, myRole) = await _requireSharer(session, actor, itemUuid);
    if (role == AccessRole.owner) {
      throw Errors.invalid('Use transferOwnership to change the owner.');
    }
    if (role.role > myRole) throw Errors.forbidden();
    if (userId == item.ownerId) {
      throw Errors.invalid("The owner's role cannot be changed.");
    }
    await _requireKnownTarget(session, actor, item, userId);
    final grant = await DriveItemPermission.db.findFirstRow(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          t.userId.equals(userId) &
          t.inheritedFromId.equals(null),
    );
    if (grant == null) {
      // Only people who have the item already (inherited from a folder)
      // get a direct grant here; anyone else goes through `share`, which
      // notifies them and logs it (S-20, CQ-34).
      final inherited = await DriveItemPermission.db.count(
        session,
        where: (t) => t.itemId.equals(item.id!) & t.userId.equals(userId),
      );
      if (inherited == 0) {
        throw Errors.invalid(
          'This person has no access yet. Share the item with them instead.',
        );
      }
      // Inherited only: add a direct grant overriding upwards.
      await DriveItemPermission.db.insertRow(
        session,
        DriveItemPermission(
          itemId: item.id!,
          userId: userId,
          role: role,
          grantedById: actor.userId,
          grantedAt: nowUtc(),
          expiresAt: expiresAt,
        ),
      );
    } else {
      await DriveItemPermission.db.updateRow(
        session,
        grant.copyWith(
          role: role,
          grantedById: actor.userId,
          grantedAt: nowUtc(),
          expiresAt: expiresAt,
          viaPublicationId: null,
        ),
        columns: _grantColumns,
      );
    }
    if (item.kind == DriveItemKind.folder) {
      await AccessService.rebuildInherited(session, item);
    }
    await AclEvents.changed(session, item, affectedUsers: {userId});
    return getSharing(session, actor, itemUuid);
  }

  /// Removes a direct grant (or a pending invite by [invitedEmail]).
  static Future<SharingInfo> remove(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    int? userId,
    String? invitedEmail,
  }) async {
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    final role = await AccessService.effectiveRole(session, actor.userId, item);
    // People may remove their own access; otherwise sharing rights are needed.
    final self = userId == actor.userId;
    if (!self && !AccessService.canShare(item, role!)) {
      throw Errors.forbidden('You cannot change who has access.');
    }
    if (userId == item.ownerId) {
      throw Errors.invalid('The owner cannot be removed.');
    }
    if (userId == null && invitedEmail == null) {
      throw Errors.invalid('Name a person to remove.');
    }
    await DriveItemPermission.db.deleteWhere(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          t.inheritedFromId.equals(null) &
          (userId != null
              ? t.userId.equals(userId)
              : t.invitedEmail.equals(invitedEmail!.trim().toLowerCase())),
    );
    if (userId != null) {
      await DriveItemUserState.db.deleteWhere(
        session,
        where: (t) =>
            t.itemId.equals(item.id!) &
            t.userId.equals(userId) &
            t.viaLink.equals(false) &
            t.starred.equals(false),
      );
    }
    if (item.kind == DriveItemKind.folder) {
      await AccessService.rebuildInherited(session, item);
    }
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.unshared,
      summary: {'userId': ?userId, 'email': ?invitedEmail},
    );
    await AclEvents.changed(
      session,
      item,
      affectedUsers: {?userId},
      kind: DriveChangeKind.unshared,
    );
    if (self) {
      return SharingInfo(
        itemUuid: item.uuid,
        itemName: item.name,
        itemKind: item.kind,
        owner: (await UserService.summary(session, item.ownerId))!,
        myRole: AccessRole.viewer,
        canShare: false,
        permissions: const [],
        settings: ItemSharingSettings(
          editorsCanShare: item.editorsCanShare,
          nonEditorsCanExport: item.nonEditorsCanExport,
          viewersSeeComments: item.viewersSeeComments,
        ),
        pendingRequests: const [],
      );
    }
    return getSharing(session, actor, itemUuid);
  }

  /// Offers ownership to [newOwnerUserId]; they accept with
  /// [respondToOwnershipTransfer].
  static Future<SharingInfo> transferOwnership(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    int newOwnerUserId,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    if (role != Role.owner) {
      throw Errors.forbidden('Only the owner can transfer ownership.');
    }
    if (newOwnerUserId == actor.userId) {
      throw Errors.invalid('You already own this item.');
    }
    final target = await UserProfile.db.findById(session, newOwnerUserId);
    if (target == null) throw Errors.notFound('User');
    // Before the quota check, which would reveal the target's headroom.
    await _requireKnownTarget(session, actor, item, newOwnerUserId);
    // (v2) The new owner must have room (Drive 03 §7.3).
    await StorageService.instance.checkRoom(
      session,
      userId: newOwnerUserId,
      bytes: item.sizeBytes + item.attachmentBytes,
      reason: QuotaReason.transfer,
      callerUserId: actor.userId,
    );
    await OwnershipTransfer.db.updateWhere(
      session,
      columnValues: (t) => [t.handledAt(nowUtc()), t.accepted(false)],
      where: (t) => t.itemId.equals(item.id!) & t.handledAt.equals(null),
    );
    final transfer = await OwnershipTransfer.db.insertRow(
      session,
      OwnershipTransfer(
        itemId: item.id!,
        fromUserId: actor.userId,
        toUserId: newOwnerUserId,
        createdAt: nowUtc(),
      ),
    );
    await NotificationService.notify(
      session,
      userId: newOwnerUserId,
      kind: NotificationKind.ownershipTransfer,
      item: item,
      actor: actor,
      payload: {'transferId': transfer.id},
    );
    return getSharing(session, actor, itemUuid);
  }

  static Future<DriveItemView> respondToOwnershipTransfer(
    Session session,
    Actor actor,
    int transferId,
    bool accept,
  ) async {
    final transfer = await OwnershipTransfer.db.findById(session, transferId);
    if (transfer == null ||
        transfer.toUserId != actor.userId ||
        transfer.handledAt != null) {
      throw Errors.notFound('Transfer');
    }
    final item = await DriveItem.db.findById(session, transfer.itemId);
    if (item == null) throw Errors.notFound();
    // Claims the transfer: only the first of two concurrent answers wins.
    Future<bool> claim(bool accepted, [Transaction? tx]) async =>
        (await OwnershipTransfer.db.updateWhere(
          session,
          columnValues: (t) => [t.handledAt(nowUtc()), t.accepted(accepted)],
          where: (t) => t.id.equals(transfer.id!) & t.handledAt.equals(null),
          transaction: tx,
        )).isNotEmpty;
    if (item.ownerId != transfer.fromUserId) {
      await claim(false);
      throw Errors.conflict(
        'The owner changed since the transfer was offered.',
      );
    }
    await session.db.transaction((tx) async {
      if (!await claim(accept, tx)) throw Errors.notFound('Transfer');
      if (!accept) return;
      // (v2) Checked again inside the transfer (Drive 03 §7.3).
      await StorageService.instance.checkRoom(
        session,
        userId: actor.userId,
        bytes: item.sizeBytes + item.attachmentBytes,
        reason: QuotaReason.transfer,
        transaction: tx,
      );
      final moved = await DriveItem.db.updateWhere(
        session,
        columnValues: (t) => [t.ownerId(actor.userId)],
        where: (t) =>
            t.id.equals(item.id!) & t.ownerId.equals(transfer.fromUserId),
        transaction: tx,
      );
      if (moved.isEmpty) {
        throw Errors.conflict(
          'The owner changed since the transfer was offered.',
        );
      }
      await StorageService.instance.onOwnerChange(
        session,
        item,
        fromUserId: transfer.fromUserId,
        toUserId: actor.userId,
        transaction: tx,
      );
      await DriveItemPermission.db.deleteWhere(
        session,
        where: (t) =>
            t.itemId.equals(item.id!) &
            t.userId.equals(actor.userId) &
            t.inheritedFromId.equals(null),
        transaction: tx,
      );
      // The previous owner becomes an Editor.
      await DriveItemPermission.db.insertRow(
        session,
        DriveItemPermission(
          itemId: item.id!,
          userId: transfer.fromUserId,
          role: AccessRole.editor,
          grantedById: actor.userId,
          grantedAt: nowUtc(),
        ),
        transaction: tx,
      );
    });
    final updated = (await DriveItem.db.findById(session, item.id!))!;
    if (accept) {
      await AccessService.rebuildInherited(session, updated);
      await ActivityService.log(
        session,
        item.id!,
        actor,
        ActivityType.shared,
        summary: {'ownershipFrom': transfer.fromUserId},
      );
      await AclEvents.changed(
        session,
        updated,
        affectedUsers: {transfer.fromUserId},
      );
    }
    return DriveService.get(session, actor, updated.uuid);
  }

  /// Turns link sharing on with [role], or off with null.
  static Future<SharingInfo> setLink(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    AccessRole? role,
  ) async {
    final (item, myRole) = await _requireSharer(session, actor, itemUuid);
    if (role == AccessRole.owner) {
      throw Errors.invalid('Links cannot own items.');
    }
    if (role != null && role.role > myRole) throw Errors.forbidden();
    final link = await ShareLink.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(item.id!),
    );
    final linkVisitors = await DriveItemUserState.db.find(
      session,
      where: (t) => t.itemId.equals(item.id!) & t.viaLink.equals(true),
    );
    if (link == null) {
      await ShareLink.db.insertRow(
        session,
        ShareLink(
          itemId: item.id!,
          token: newToken(),
          role: role,
          createdById: actor.userId,
          createdAt: nowUtc(),
        ),
      );
    } else {
      await ShareLink.db.updateWhere(
        session,
        columnValues: (t) => [t.role(role)],
        where: (t) => t.id.equals(link.id!),
      );
    }
    await ActivityService.log(
      session,
      item.id!,
      actor,
      role == null ? ActivityType.unshared : ActivityType.shared,
      summary: {'link': role?.name},
    );
    await AclEvents.changed(
      session,
      item,
      affectedUsers: {for (final v in linkVisitors) v.userId},
      kind: role == null ? DriveChangeKind.unshared : DriveChangeKind.shared,
    );
    return getSharing(session, actor, itemUuid);
  }

  /// Replaces the link token (old links stop working).
  static Future<SharingInfo> rotateLink(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, _) = await _requireSharer(session, actor, itemUuid);
    final link = await ShareLink.db.findFirstRow(
      session,
      where: (t) => t.itemId.equals(item.id!),
    );
    if (link == null) {
      await ShareLink.db.insertRow(
        session,
        ShareLink(
          itemId: item.id!,
          token: newToken(),
          createdById: actor.userId,
          createdAt: nowUtc(),
        ),
      );
    } else {
      await ShareLink.db.updateRow(
        session,
        link.copyWith(token: newToken()),
        columns: (t) => [t.token],
      );
    }
    return getSharing(session, actor, itemUuid);
  }

  static Future<SharingInfo> updateSettings(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    ItemSharingSettings settings,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    if (role != Role.owner) {
      throw Errors.forbidden('Only the owner can change these settings.');
    }
    await DriveItem.db.updateWhere(
      session,
      columnValues: (t) => [
        t.editorsCanShare(settings.editorsCanShare),
        t.nonEditorsCanExport(settings.nonEditorsCanExport),
        t.viewersSeeComments(settings.viewersSeeComments),
      ],
      where: (t) => t.id.equals(item.id!),
    );
    final updated = (await DriveItem.db.findById(session, item.id!))!;
    await AclEvents.changed(session, updated, kind: DriveChangeKind.updated);
    return getSharing(session, actor, itemUuid);
  }

  /// Asks the owner (and editors who can share) for access.
  static Future<void> requestAccess(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    AccessRole role,
    String? message,
  ) async {
    final item = await AccessService.findItem(session, itemUuid);
    if (item == null) throw Errors.notFound();
    final current = await AccessService.effectiveRole(
      session,
      actor.userId,
      item,
    );
    if (current != null && current >= role.role) {
      throw Errors.invalid('You already have this access.');
    }
    if (role == AccessRole.owner) {
      throw Errors.invalid('Request editor access.');
    }
    final text = message?.trim();
    if (text != null && text.length > maxRequestMessage) {
      throw Errors.invalid('The message is too long.');
    }
    final retry = await _requestLimiter.check('${actor.userId}:${item.id}');
    if (retry != null) {
      throw Errors.limit(
        'You asked for access to this item too often. Try again later.',
      );
    }
    final pending = await AccessRequest.db.findFirstRow(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          t.requesterId.equals(actor.userId) &
          t.handledAt.equals(null),
    );
    if (pending != null) {
      // Updated quietly: the owner and editors were notified when it was
      // created, unless a higher role is asked for now.
      await AccessRequest.db.updateWhere(
        session,
        columnValues: (t) => [
          t.requestedRole(role),
          t.message(text),
        ],
        where: (t) => t.id.equals(pending.id!),
      );
      if (role.index <= pending.requestedRole.index) return;
    }
    final request =
        pending ??
        await AccessRequest.db.insertRow(
          session,
          AccessRequest(
            itemId: item.id!,
            requesterId: actor.userId,
            requestedRole: role,
            message: text,
            createdAt: nowUtc(),
          ),
        );
    final recipients = <int>{item.ownerId};
    if (item.editorsCanShare) {
      final editors = await DriveItemPermission.db.find(
        session,
        where: (t) =>
            t.itemId.equals(item.id!) &
            t.role.equals(AccessRole.editor) &
            t.userId.notEquals(null),
      );
      recipients.addAll(editors.map((e) => e.userId!));
    }
    for (final userId in recipients) {
      await NotificationService.notify(
        session,
        userId: userId,
        kind: NotificationKind.accessRequest,
        item: item,
        actor: actor,
        payload: {
          'requestId': request.id,
          'role': role.name,
          'message': ?text,
        },
      );
    }
  }

  static Future<SharingInfo> handleAccessRequest(
    Session session,
    Actor actor,
    int requestId,
    bool approve,
    AccessRole? role,
  ) async {
    final request = await AccessRequest.db.findById(session, requestId);
    if (request == null) throw Errors.notFound('Request');
    final item = await DriveItem.db.findById(session, request.itemId);
    if (item == null) throw Errors.notFound();
    final (_, myRole) = await _requireSharer(session, actor, item.uuid);
    if (request.handledAt != null) {
      throw Errors.conflict('The request was already handled.');
    }
    final grantRole = role ?? request.requestedRole;
    if (approve && grantRole.role > myRole) throw Errors.forbidden();
    // Conditional: of two people answering at once, only the first wins.
    final claimed = await AccessRequest.db.updateWhere(
      session,
      columnValues: (t) => [
        t.handledAt(nowUtc()),
        t.handledById(actor.userId),
        t.outcome(
          approve ? AccessRequestOutcome.approved : AccessRequestOutcome.denied,
        ),
      ],
      where: (t) => t.id.equals(request.id!) & t.handledAt.equals(null),
    );
    if (claimed.isEmpty) {
      throw Errors.conflict('The request was already handled.');
    }
    if (approve) {
      final requester = await UserProfile.db.findById(
        session,
        request.requesterId,
      );
      if (requester != null) {
        return share(
          session,
          actor,
          item.uuid,
          emails: [requester.email],
          role: grantRole,
        );
      }
    }
    return getSharing(session, actor, item.uuid);
  }

  /// Resolves a share link token for the signed-in caller and records the
  /// visit (the item appears in "Shared with me").
  static Future<InviteResolution> resolveInvite(
    Session session,
    Actor actor,
    String token,
  ) async {
    final link = await ShareLink.db.findFirstRow(
      session,
      where: (t) => t.token.equals(token.trim()),
    );
    if (link == null) throw Errors.notFound('Link');
    final item = await DriveItem.db.findById(session, link.itemId);
    if (item == null || item.trashedAt != null) throw Errors.notFound();
    final role = await AccessService.effectiveRole(session, actor.userId, item);
    if (role == null) {
      throw Errors.forbidden('Link sharing is turned off for this item.');
    }
    await DriveUserStates.recordOpen(session, actor, item, role);
    return InviteResolution(
      itemUuid: item.uuid,
      kind: item.kind,
      name: item.name,
      role: role.access,
    );
  }

  /// Hourly job: removes expired grants in batches until none are left (or
  /// [budget] is spent), rebuilds inherited grants of folders and
  /// re-mirrors affected spaces and open documents (`AclEvents`).
  static Future<int> removeExpiredGrants(
    Session session, {
    DateTime? now,
    int batchSize = 1000,
    Duration budget = const Duration(minutes: 10),
  }) async {
    final at = now ?? nowUtc();
    final watch = Stopwatch()..start();
    var removed = 0;
    while (watch.elapsed < budget) {
      final expired = await DriveItemPermission.db.find(
        session,
        where: (t) => t.expiresAt < at,
        orderBy: (t) => t.id,
        limit: batchSize,
      );
      if (expired.isEmpty) break;
      final ids = <int>{for (final e in expired) e.id!};
      final usersByItem = <int, Set<int>>{};
      for (final e in expired) {
        final users = usersByItem.putIfAbsent(e.itemId, () => {});
        if (e.userId != null) users.add(e.userId!);
      }
      await DriveItemPermission.db.deleteWhere(
        session,
        where: (t) => t.id.inSet(ids),
      );
      removed += expired.length;
      for (final MapEntry(key: id, value: users) in usersByItem.entries) {
        final item = await DriveItem.db.findById(session, id);
        if (item == null) continue;
        if (item.kind == DriveItemKind.folder) {
          await AccessService.rebuildInherited(session, item);
        }
        await AclEvents.changed(session, item, affectedUsers: users);
      }
    }
    return removed;
  }
}
