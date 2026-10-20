import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../users/user_service.dart';
import 'submission_service.dart';

/// A document's submission to a publication (specs/18 §9.2).
class SubmissionEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The document's submission, or null (viewer+).
  Future<SubmissionView?> get(Session session, UuidValue itemUuid) async =>
      SubmissionService.get(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  /// Submits the current revision (editor+); [agreed] confirms the
  /// publication's terms when they changed.
  Future<SubmissionView> submit(
    Session session,
    UuidValue itemUuid,
    SubmissionValues values,
    bool agreed,
  ) async => SubmissionService.submit(
    session,
    await UserService.actorOf(session),
    itemUuid,
    values,
    agreed: agreed,
  );

  Future<SubmissionView> withdraw(Session session, UuidValue itemUuid) async =>
      SubmissionService.withdraw(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  Future<void> disconnect(Session session, UuidValue itemUuid) async =>
      SubmissionService.disconnect(
        session,
        await UserService.actorOf(session),
        itemUuid,
      );

  /// Undoes [disconnect].
  Future<SubmissionView?> reconnect(
    Session session,
    UuidValue itemUuid,
  ) async => SubmissionService.reconnect(
    session,
    await UserService.actorOf(session),
    itemUuid,
  );
}
