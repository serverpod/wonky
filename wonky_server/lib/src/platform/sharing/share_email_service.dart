import 'package:serverpod/serverpod.dart';

import '../common/json.dart';
import '../common/models.dart';
import '../common/rate_limiter.dart';
import '../common/roles.dart';
import '../config/wonky_config.dart';
import '../../generated/future_calls.dart';
import '../notifications/email/share_emails.dart';
import '../notifications/notification_service.dart';
import '../users/user_service.dart';
import 'access_service.dart';

/// The emails of a share with *Send an email* (specs/06 §4, specs/07 §4):
/// sent right away, off the request path ([ShareEmailFutureCall]), through
/// [NotificationService.emailSender].
abstract final class ShareEmailService {
  /// Schedules the email of a share notification. By default a future call
  /// without delay; tests replace it to run [sendShared] inline.
  static Future<void> Function(Session session, int notificationId)
  scheduleShared = _scheduleShared;

  /// Schedules the invitation of a pending invite. By default a future call
  /// without delay; tests replace it to run [sendInvite] inline.
  static Future<void> Function(
    Session session,
    int permissionId,
    String? message,
  )
  scheduleInvite = _scheduleInvite;

  static Future<void> _scheduleShared(Session session, int notificationId) =>
      session.serverpod.futureCalls
          .callWithDelay(Duration.zero)
          .shareEmail
          .shared(notificationId);

  static Future<void> _scheduleInvite(
    Session session,
    int permissionId,
    String? message,
  ) => session.serverpod.futureCalls
      .callWithDelay(Duration.zero)
      .shareEmail
      .invite(permissionId, message);

  static final _invitesPerHour = RateLimiter(
    name: 'sharing.inviteEmails.hour',
    limit: 30,
    window: const Duration(hours: 1),
  );
  static final _invitesPerDay = RateLimiter(
    name: 'sharing.inviteEmails.day',
    limit: 100,
    window: const Duration(days: 1),
  );

  /// Clears the in-memory invite limits (tests).
  static void resetLimits() {
    _invitesPerHour.reset();
    _invitesPerDay.reset();
  }

  /// Whether invitation emails are on (both limits above 0).
  static bool get invitesEnabled {
    final c = WonkyConfig.current;
    return c.inviteEmailsPerHour > 0 && c.inviteEmailsPerDay > 0;
  }

  /// Spends [count] invitation emails of [senderId]'s hourly and daily
  /// allowance; returns false when either is used up (nothing should be
  /// sent then).
  static Future<bool> takeInvites(
    Session session,
    int senderId,
    int count,
  ) async {
    if (count <= 0) return true;
    final c = WonkyConfig.current;
    if (await _invitesPerHour.check(
          senderId,
          limit: c.inviteEmailsPerHour,
          cost: count,
        ) !=
        null) {
      return false;
    }
    return await _invitesPerDay.check(
          senderId,
          limit: c.inviteEmailsPerDay,
          cost: count,
        ) ==
        null;
  }

  static ShareEmails get _emails =>
      ShareEmails(webOrigin: NotificationService.webOrigin());

  /// Sends the email of the share notification [notificationId] (created
  /// with `emailedNow`). Skips it when the recipient lost access or the
  /// item was trashed in the meantime. Returns whether an email was sent.
  static Future<bool> sendShared(Session session, int notificationId) async {
    final row = await UserNotification.db.findById(session, notificationId);
    if (row == null || row.itemId == null) return false;
    final item = await DriveItem.db.findById(session, row.itemId!);
    final profile = await UserProfile.db.findById(session, row.userId);
    if (item == null || item.trashedAt != null || profile == null) {
      return false;
    }
    final role = await AccessService.effectiveRole(session, row.userId, item);
    if (role == null) return false;
    final sender = row.actorId == null
        ? null
        : (await UserService.summaries(session, [row.actorId]))[row.actorId];
    final payload = decodeObject(row.payload);
    try {
      await NotificationService.emailSender.send(
        session,
        _emails.shared(
          to: profile.email,
          displayName: profile.displayName,
          senderName: sender?.displayName ?? 'Someone',
          itemName: item.name,
          itemKind: item.kind,
          itemUuid: item.uuid.uuid,
          role: _roleOf(payload['role']) ?? role.access,
          message: payload['message'] as String?,
        ),
      );
    } on Object catch (e) {
      // Given back: the digest sends it when shares are set to email.
      await NotificationService.unclaimEmail(session, notificationId);
      session.log(
        'Share email of notification $notificationId failed: $e',
        level: LogLevel.warning,
      );
      return false;
    }
    return true;
  }

  /// Sends the invitation of the pending invite [permissionId] with the
  /// sender's [message]. Skips invites that were removed or accepted
  /// (signed up) in the meantime and trashed items. Returns whether an
  /// email was sent.
  static Future<bool> sendInvite(
    Session session,
    int permissionId,
    String? message,
  ) async {
    final grant = await DriveItemPermission.db.findById(session, permissionId);
    final email = grant?.invitedEmail;
    if (grant == null || email == null || grant.userId != null) return false;
    final item = await DriveItem.db.findById(session, grant.itemId);
    if (item == null || item.trashedAt != null) return false;
    final sender = (await UserService.summaries(session, [
      grant.grantedById,
    ]))[grant.grantedById];
    try {
      await NotificationService.emailSender.send(
        session,
        _emails.invite(
          to: email,
          senderName: sender?.displayName ?? 'Someone',
          itemName: item.name,
          itemKind: item.kind,
          itemUuid: item.uuid.uuid,
          role: grant.role,
          message: message,
        ),
      );
    } on Object catch (e) {
      session.log(
        'Invitation email of grant $permissionId failed: $e',
        level: LogLevel.warning,
      );
      return false;
    }
    return true;
  }

  static AccessRole? _roleOf(Object? name) => name is String
      ? AccessRole.values.where((r) => r.name == name).firstOrNull
      : null;
}
