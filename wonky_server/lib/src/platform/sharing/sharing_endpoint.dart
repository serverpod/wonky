import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../users/user_service.dart';
import 'sharing_service.dart';

/// Sharing (specs/06 §4).
class SharingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  Future<SharingInfo> getSharing(Session session, UuidValue itemUuid) async =>
      SharingService.getSharing(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  Future<SharingInfo> share(
    Session session,
    UuidValue itemUuid,
    List<String> emails,
    AccessRole role,
    bool notify,
    String? message,
    DateTime? expiresAt,
  ) async => SharingService.share(
    session,
    await UserService.actorOf(session),
    itemUuid,
    emails: emails,
    role: role,
    notify: notify,
    message: message,
    expiresAt: expiresAt,
  );

  Future<SharingInfo> updateRole(
    Session session,
    UuidValue itemUuid,
    int userId,
    AccessRole role, {
    DateTime? expiresAt,
  }) async => SharingService.updateRole(
    session,
    await UserService.actorOf(session),
    itemUuid,
    userId,
    role,
    expiresAt: expiresAt,
  );

  /// Removes a person (or a pending invite with [invitedEmail]).
  Future<SharingInfo> remove(
    Session session,
    UuidValue itemUuid,
    int? userId, {
    String? invitedEmail,
  }) async => SharingService.remove(
    session,
    await UserService.actorOf(session),
    itemUuid,
    userId: userId,
    invitedEmail: invitedEmail,
  );

  /// Offers ownership; the new owner accepts with
  /// [respondToOwnershipTransfer].
  Future<SharingInfo> transferOwnership(
    Session session,
    UuidValue itemUuid,
    int newOwnerUserId,
  ) async => SharingService.transferOwnership(
    session,
    await UserService.actorOf(session),
    itemUuid,
    newOwnerUserId,
  );

  Future<DriveItemView> respondToOwnershipTransfer(
    Session session,
    int transferId,
    bool accept,
  ) async => SharingService.respondToOwnershipTransfer(
    session,
    await UserService.actorOf(session),
    transferId,
    accept,
  );

  /// Link sharing role; null = restricted.
  Future<SharingInfo> setLink(
    Session session,
    UuidValue itemUuid,
    AccessRole? role,
  ) async => SharingService.setLink(
    session,
    await UserService.actorOf(session),
    itemUuid,
    role,
  );

  /// General access (specs/06 §2.2–2.3): restricted, everyone in the
  /// caller's organization with [role], or anyone with the link with
  /// [role].
  Future<SharingInfo> setGeneralAccess(
    Session session,
    UuidValue itemUuid,
    GeneralAccess access,
    AccessRole? role,
  ) async => SharingService.setGeneralAccess(
    session,
    await UserService.actorOf(session),
    itemUuid,
    access,
    role,
  );

  Future<SharingInfo> rotateLink(Session session, UuidValue itemUuid) async =>
      SharingService.rotateLink(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  Future<SharingInfo> updateSettings(
    Session session,
    UuidValue itemUuid,
    ItemSharingSettings settings,
  ) async => SharingService.updateSettings(
    session,
    await UserService.actorOf(session),
    itemUuid,
    settings,
  );

  Future<void> requestAccess(
    Session session,
    UuidValue itemUuid,
    AccessRole role,
    String? message,
  ) async => SharingService.requestAccess(
    session,
    await UserService.actorOf(session),
    itemUuid,
    role,
    message,
  );

  Future<SharingInfo> handleAccessRequest(
    Session session,
    int requestId,
    bool approve,
    AccessRole? role,
  ) async => SharingService.handleAccessRequest(
    session,
    await UserService.actorOf(session),
    requestId,
    approve,
    role,
  );

  /// Resolves a share link token (`/invite/<token>`).
  Future<InviteResolution> resolveInvite(Session session, String token) async =>
      SharingService.resolveInvite(
        session,
        await UserService.actorOf(session),
        token,
      );
}
