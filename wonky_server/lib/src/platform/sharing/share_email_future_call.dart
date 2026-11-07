import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import 'share_email_service.dart';

/// Sends the emails of a share with *Send an email* right after the share
/// (specs/06 §4): the email to an existing user and the invitation to an
/// address without an account.
class ShareEmailFutureCall extends FutureCall {
  Future<void> shared(Session session, int notificationId) => runGuarded(
    session,
    'Share email $notificationId',
    () => ShareEmailService.sendShared(session, notificationId),
  );

  Future<void> invite(Session session, int permissionId, String? message) =>
      runGuarded(
        session,
        'Invitation email $permissionId',
        () => ShareEmailService.sendInvite(session, permissionId, message),
      );
}
