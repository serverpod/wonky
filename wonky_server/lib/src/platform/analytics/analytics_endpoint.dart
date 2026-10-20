import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../users/user_service.dart';
import 'analytics_service.dart';
import 'usage_tracker.dart';

/// Usage analytics (specs/19): the apps' activity ping, and the admin
/// dashboard of Wonky Drive (overview, admins only).
class AnalyticsEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The caller is using [app] (sent at app start and on resume).
  Future<void> ping(Session session, UsageApp app) async {
    final actor = await UserService.actorOf(session);
    await UsageTracker.active(session, actor.userId, app);
  }

  /// The dashboard for the last [days] days (7, 30, 90 or 365); admins are
  /// left out of every count unless [includeAdmins].
  Future<AnalyticsOverview> overview(
    Session session,
    int days,
    bool includeAdmins,
  ) async {
    await AnalyticsService.requireAdmin(session);
    return AnalyticsService.overview(
      session,
      days: days,
      includeAdmins: includeAdmins,
    );
  }
}
