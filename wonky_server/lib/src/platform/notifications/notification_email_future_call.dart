import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import 'notification_service.dart';

/// Sends the email of a single notification right after it was created
/// (mentions and assignments; specs/07 §4).
class NotificationEmailFutureCall extends FutureCall {
  Future<void> send(Session session, int notificationId) => runGuarded(
    session,
    'Notification email $notificationId',
    () => NotificationService.sendImmediate(session, notificationId),
  );
}
