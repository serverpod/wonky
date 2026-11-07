import 'package:wonky_client/wonky_client.dart';

import 'api.dart';

/// Sharing and permissions (suite 06 §4). Sharing changes are not undoable.
abstract class SharingRepository {
  Future<SharingInfo> getSharing(UuidValue itemUuid);

  Future<SharingInfo> share(
    UuidValue itemUuid, {
    required List<String> emails,
    required AccessRole role,
    bool notify = true,
    String? message,
    DateTime? expiresAt,
  });

  Future<SharingInfo> updateRole(
    UuidValue itemUuid, {
    required int userId,
    required AccessRole role,
    DateTime? expiresAt,
  });

  Future<SharingInfo> remove(
    UuidValue itemUuid, {
    int? userId,
    String? invitedEmail,
  });

  Future<SharingInfo> transferOwnership(UuidValue itemUuid, int newOwnerUserId);

  Future<DriveItemView> respondToOwnershipTransfer(int transferId, bool accept);

  /// `role == null` turns link sharing off ("Restricted").
  Future<SharingInfo> setLink(UuidValue itemUuid, AccessRole? role);

  /// Sets who besides the people with access can open the item: no one
  /// ([GeneralAccess.restricted], [role] null), everyone in the caller's
  /// organization or anyone with the link, with [role]. The choices exclude
  /// each other (suite 06 §2.2–2.3).
  Future<SharingInfo> setGeneralAccess(
    UuidValue itemUuid,
    GeneralAccess access,
    AccessRole? role,
  );

  Future<SharingInfo> rotateLink(UuidValue itemUuid);

  Future<SharingInfo> updateSettings(
    UuidValue itemUuid,
    ItemSharingSettings settings,
  );

  Future<void> requestAccess(
    UuidValue itemUuid,
    AccessRole role,
    String? message,
  );

  Future<SharingInfo> handleAccessRequest(
    int requestId,
    bool approve,
    AccessRole? role,
  );

  Future<InviteResolution> resolveInvite(String token);
}

/// [SharingRepository] backed by the `sharing` endpoint.
class ServerSharingRepository implements SharingRepository {
  ServerSharingRepository(this.api);

  final Api api;

  @override
  Future<SharingInfo> getSharing(UuidValue itemUuid) =>
      api.guard((c) => c.sharing.getSharing(itemUuid));

  @override
  Future<SharingInfo> share(
    UuidValue itemUuid, {
    required List<String> emails,
    required AccessRole role,
    bool notify = true,
    String? message,
    DateTime? expiresAt,
  }) => api.guard(
    (c) => c.sharing.share(itemUuid, emails, role, notify, message, expiresAt),
  );

  @override
  Future<SharingInfo> updateRole(
    UuidValue itemUuid, {
    required int userId,
    required AccessRole role,
    DateTime? expiresAt,
  }) => api.guard(
    (c) => c.sharing.updateRole(itemUuid, userId, role, expiresAt: expiresAt),
  );

  @override
  Future<SharingInfo> remove(
    UuidValue itemUuid, {
    int? userId,
    String? invitedEmail,
  }) => api.guard(
    (c) => c.sharing.remove(itemUuid, userId, invitedEmail: invitedEmail),
  );

  @override
  Future<SharingInfo> transferOwnership(
    UuidValue itemUuid,
    int newOwnerUserId,
  ) => api.guard((c) => c.sharing.transferOwnership(itemUuid, newOwnerUserId));

  @override
  Future<DriveItemView> respondToOwnershipTransfer(
    int transferId,
    bool accept,
  ) => api.guard(
    (c) => c.sharing.respondToOwnershipTransfer(transferId, accept),
  );

  @override
  Future<SharingInfo> setLink(UuidValue itemUuid, AccessRole? role) =>
      api.guard((c) => c.sharing.setLink(itemUuid, role));

  @override
  Future<SharingInfo> setGeneralAccess(
    UuidValue itemUuid,
    GeneralAccess access,
    AccessRole? role,
  ) => api.guard((c) => c.sharing.setGeneralAccess(itemUuid, access, role));

  @override
  Future<SharingInfo> rotateLink(UuidValue itemUuid) =>
      api.guard((c) => c.sharing.rotateLink(itemUuid));

  @override
  Future<SharingInfo> updateSettings(
    UuidValue itemUuid,
    ItemSharingSettings settings,
  ) => api.guard((c) => c.sharing.updateSettings(itemUuid, settings));

  @override
  Future<void> requestAccess(
    UuidValue itemUuid,
    AccessRole role,
    String? message,
  ) => api.guard((c) => c.sharing.requestAccess(itemUuid, role, message));

  @override
  Future<SharingInfo> handleAccessRequest(
    int requestId,
    bool approve,
    AccessRole? role,
  ) =>
      api.guard((c) => c.sharing.handleAccessRequest(requestId, approve, role));

  @override
  Future<InviteResolution> resolveInvite(String token) =>
      api.guard((c) => c.sharing.resolveInvite(token));
}
