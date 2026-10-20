import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

/// Server access of the Analytics page (specs/19 §3), replaceable in tests.
abstract class AnalyticsApi {
  /// `analytics.overview`: the dashboard of the last [days] days.
  Future<AnalyticsOverview> overview(int days, {required bool includeAdmins});
}

/// [AnalyticsApi] on the generated client (errors become `WonkyException` /
/// `OfflineException` through [Api.guard]).
class ServerAnalyticsApi implements AnalyticsApi {
  ServerAnalyticsApi(this.services);

  final ShellServices services;

  Client _client() {
    final c = services.client;
    if (c == null ||
        Api.simulatedOffline ||
        services.connectivity.forcedOffline) {
      throw const OfflineException('offline');
    }
    return c;
  }

  @override
  Future<AnalyticsOverview> overview(int days, {required bool includeAdmins}) =>
      Api(_client()).guard((c) => c.analytics.overview(days, includeAdmins));
}
