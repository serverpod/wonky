import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/sharing/anonymous_access.dart';
import '../../platform/users/user_service.dart';
import '../ot/document_connection.dart';
import '../ot/document_service.dart';

/// Write documents: the OT editing stream and helpers (Write 03 §1).
///
/// `connect`, `getInfo`, `getOps` and `getSnapshot` also serve signed-out
/// viewers of link-shared documents (read-only, rate limited, specs/06
/// §2.4); `updateMeta` needs an account.
class DocumentEndpoint extends Endpoint {
  @override
  bool get requireLogin => false;

  /// Opens an editing/viewing session. The first message is [DocInit] with
  /// the ops since [knownRevision] (0 = none) or a snapshot.
  Stream<DocServerMessage> connect(
    Session session,
    UuidValue documentUuid,
    int knownRevision,
    Stream<DocClientMessage> input,
  ) async* {
    final actor = await AnonymousAccess.actorOf(session, stream: true);
    yield* AnonymousAccess.track(
      actor,
      DocumentConnection.open(
        session,
        actor,
        documentUuid,
        knownRevision,
        input,
      ),
    );
  }

  Future<DocumentInfo> getInfo(Session session, UuidValue documentUuid) async =>
      DocumentService.getInfo(
        session,
        await AnonymousAccess.actorOf(session),
        documentUuid,
      );

  /// Ops in [fromRevision]…[toRevision] (at most 1,000).
  Future<List<DocumentOpView>> getOps(
    Session session,
    UuidValue documentUuid,
    int fromRevision,
    int toRevision,
  ) async => DocumentService.getOps(
    session,
    await AnonymousAccess.actorOf(session),
    documentUuid,
    fromRevision,
    toRevision,
  );

  /// Content at [revision] (head when null; older revisions need Editor+).
  Future<DocumentSnapshotView> getSnapshot(
    Session session,
    UuidValue documentUuid,
    int? revision,
  ) async => DocumentService.getSnapshot(
    session,
    await AnonymousAccess.actorOf(session),
    documentUuid,
    revision,
  );

  /// LWW metadata change (themeId, pageSetup, language, frontMatter).
  Future<void> updateMeta(
    Session session,
    UuidValue documentUuid,
    DocumentMetaPatch patch,
    UuidValue clientOpId,
  ) async => DocumentService.updateMeta(
    session,
    await UserService.actorOf(session),
    documentUuid,
    patch,
    clientOpId,
  );
}
