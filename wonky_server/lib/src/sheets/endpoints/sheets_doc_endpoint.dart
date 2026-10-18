import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/revlog/rev_endpoint_support.dart';
import '../../platform/revlog/rev_log_connection.dart';
import '../../platform/users/user_service.dart';
import '../revlog/sheets_rev_binding.dart';

/// Spreadsheet sessions over RevLog (RevLog spec 04 §1): `sheetsDoc.*`.
class SheetsDocEndpoint extends Endpoint {
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
      SheetsRevBinding.instance,
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
    SheetsRevBinding.instance,
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
    SheetsRevBinding.instance,
    await UserService.actorOf(session),
    fileUuid,
    fromRevision,
    toRevision,
  );

  /// Head revision, role and stats. Viewer+.
  Future<RevFileInfo> info(Session session, UuidValue fileUuid) async =>
      RevEndpointSupport.info(
        session,
        SheetsRevBinding.instance,
        await UserService.actorOf(session),
        fileUuid,
      );
}
