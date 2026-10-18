import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/revlog/rev_endpoint_support.dart';
import '../../platform/revlog/rev_log_connection.dart';
import '../../platform/users/user_service.dart';
import '../revlog/slides_rev_binding.dart';

/// Deck sessions over RevLog (RevLog spec 04 §1, 08): `slidesDoc.*`.
class SlidesDocEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Opens an editing/viewing session (04 §2).
  Stream<RevServerMessage> connect(
    Session session,
    UuidValue fileUuid,
    int knownRevision,
    String tabId,
    Stream<RevClientMessage> input,
  ) async* {
    final actor = await UserService.actorOf(session);
    yield* RevLogConnection.open(
      session,
      SlidesRevBinding.instance,
      actor,
      fileUuid,
      knownRevision,
      tabId,
      input,
    );
  }

  /// A bootstrap page (04 §3). Viewer+.
  Future<RevPage> page(
    Session session,
    UuidValue fileUuid,
    RevPageRequest request,
  ) async => RevEndpointSupport.page(
    session,
    SlidesRevBinding.instance,
    await UserService.actorOf(session),
    fileUuid,
    request,
  );

  /// Ops in (fromRevision, toRevision] (04 §1, 05 §11).
  Future<List<RevOpView>> ops(
    Session session,
    UuidValue fileUuid,
    int fromRevision,
    int toRevision,
  ) async => RevEndpointSupport.ops(
    session,
    SlidesRevBinding.instance,
    await UserService.actorOf(session),
    fileUuid,
    fromRevision,
    toRevision,
  );

  /// Head revision, role and stats. Viewer+.
  Future<RevFileInfo> info(Session session, UuidValue fileUuid) async =>
      RevEndpointSupport.info(
        session,
        SlidesRevBinding.instance,
        await UserService.actorOf(session),
        fileUuid,
      );
}
