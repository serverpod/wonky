import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/users/user_service.dart';
import '../revlog/slides_server_writes.dart';

/// Online-only Slides operations (Slides 02 §9): undo and redo of server
/// changes. Deck sessions are `slidesDoc.*` (RevLog spec 04 §1).
class SlidesEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Undo of a server-side change (`slides.serverChange`: MCP, AI,
  /// restores): reverts the recorded ops with the per-column skip rule
  /// (columns others changed since stay; coupled columns stay together).
  /// Editor+.
  Future<RevertResult> revertChange(
    Session session,
    UuidValue changeId,
  ) async => SlidesServerWrites.revert(
    session,
    await UserService.actorOf(session),
    changeId,
  );

  /// Redo of a reverted server-side change ([changeId] of the original or
  /// of its revert).
  Future<RevertResult> reapplyChange(
    Session session,
    UuidValue changeId,
  ) async => SlidesServerWrites.reapply(
    session,
    await UserService.actorOf(session),
    changeId,
  );
}
