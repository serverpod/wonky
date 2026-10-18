import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/rate_limiter.dart';
import '../common/time.dart';
import '../users/user_service.dart';

/// "Report a problem" and client error reports (specs/03, 11 §5).
///
/// Public (error reports are sent before sign-in too), so calls are rate
/// limited per signed-in user, or per client address when signed out.
class FeedbackEndpoint extends Endpoint {
  static const maxMessage = 20000;
  static const maxStack = 50000;

  Future<void> submit(Session session, FeedbackSubmission feedback) =>
      _store(session, feedback);

  /// Client error reports (anonymized state, no document content).
  Future<void> reportError(Session session, FeedbackSubmission report) =>
      _store(session, report.copyWith(kind: FeedbackKind.errorReport));

  Future<void> _store(Session session, FeedbackSubmission f) async {
    if (f.message.trim().isEmpty) throw Errors.invalid('The message is empty.');
    int? userId;
    if (session.authenticated != null) {
      userId = (await UserService.actorOf(session)).userId;
    }
    final retry = userId != null
        ? await FeedbackLimits.limiter.check(
            'user:$userId',
            limit: FeedbackLimits.userPerHour,
          )
        : await FeedbackLimits.limiter.check(
            'ip:${_clientAddress(session)}',
            limit: FeedbackLimits.anonymousPerHour,
          );
    if (retry != null) {
      throw Errors.limit('Too many reports for now. Try again later.');
    }
    String cap(String s, int n) => s.length > n ? s.substring(0, n) : s;
    await FeedbackReport.db.insertRow(
      session,
      FeedbackReport(
        userId: userId,
        kind: f.kind,
        message: cap(f.message, maxMessage),
        app: cap(f.app, 32),
        appVersion: cap(f.appVersion, 64),
        platform: cap(f.platform, 64),
        route: f.route == null ? null : cap(f.route!, 500),
        stackTrace: f.stackTrace == null ? null : cap(f.stackTrace!, maxStack),
        contextJson: f.contextJson == null
            ? null
            : cap(f.contextJson!, maxMessage),
        createdAt: nowUtc(),
      ),
    );
    session.log(
      'Feedback (${f.kind.name}) from ${f.app} ${f.appVersion} on ${f.platform}',
      level: f.kind == FeedbackKind.errorReport
          ? LogLevel.warning
          : LogLevel.info,
    );
  }

  static String _clientAddress(Session session) {
    try {
      return session.request?.remoteInfo ?? 'unknown';
    } on Object {
      return 'unknown';
    }
  }
}

/// Rate limits of [FeedbackEndpoint] (specs/13 §4).
abstract final class FeedbackLimits {
  /// Reports per signed-in user and hour.
  static const userPerHour = 60;

  /// Reports per client address and hour when signed out.
  static const anonymousPerHour = 10;

  static final limiter = RateLimiter(
    name: 'feedback',
    window: const Duration(hours: 1),
  );
}
