import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../users/user_service.dart';
import 'access_service.dart';
import 'anonymous_access.dart';

/// What a signed-out visitor of a link learns about the item (specs/06
/// §2.4): `publicItem.get`. Callable signed out (rate limited) and signed
/// in.
class PublicItemEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// The document, spreadsheet or presentation [uuid] (its drive item uuid
  /// or its content ref) if the caller may view it; `notFound` otherwise,
  /// so ids do not leak.
  Future<PublicItemView> get(Session session, UuidValue uuid) async {
    final actor = await AnonymousAccess.actorOf(session);
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.kind.inSet(AccessService.anonymousKinds) &
          (t.uuid.equals(uuid) | t.contentRef.equals(uuid)),
    );
    if (item == null) throw Errors.notFound();
    final role = await AccessService.effectiveRole(
      session,
      actor.userId,
      item,
    );
    if (role == null || item.trashedAt != null) throw Errors.notFound();
    final owner = await UserService.summary(session, item.ownerId);
    return PublicItemView(
      uuid: item.uuid,
      kind: item.kind,
      name: item.name,
      contentRef: item.contentRef ?? item.uuid,
      ownerName: owner?.displayName ?? '',
      modifiedAt: item.modifiedAt,
    );
  }
}
