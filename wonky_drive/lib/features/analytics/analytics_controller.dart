import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';

import 'analytics_api.dart';

/// The periods of the Analytics page (specs/19 §3.1), in days.
const analyticsPeriods = [7, 30, 90, 365];

/// The default period.
const analyticsDefaultDays = 30;

/// `/analytics?days=…&admins=1` of a period ([analyticsPeriods]) and the
/// *Include admins* switch.
String analyticsPath({int days = analyticsDefaultDays, bool admins = false}) {
  final q = [
    if (days != analyticsDefaultDays) 'days=$days',
    if (admins) 'admins=1',
  ];
  return q.isEmpty ? '/analytics' : '/analytics?${q.join('&')}';
}

/// The period of `?days=` ([analyticsDefaultDays] when absent or unknown).
int parseAnalyticsDays(String? v) {
  final d = int.tryParse(v ?? '');
  return analyticsPeriods.contains(d) ? d! : analyticsDefaultDays;
}

/// State of the Analytics page (specs/19 §3): the overview of the period.
/// Responses of an older period are dropped.
class AnalyticsController extends ChangeNotifier {
  AnalyticsController({
    required this.services,
    this.days = analyticsDefaultDays,
    this.includeAdmins = false,
  });

  final ShellServices services;

  AnalyticsApi get api => AnalyticsHost.of(services).api;

  int days;
  bool includeAdmins;

  AnalyticsOverview? overview;
  Object? error;
  bool loading = false;

  /// Bumped on every request; a response of an older one is dropped.
  int _overviewToken = 0;

  bool _disposed = false;

  /// Reloads the overview.
  Future<void> reload() => loadOverview();

  Future<void> loadOverview() async {
    final token = ++_overviewToken;
    loading = true;
    error = null;
    _notify();
    try {
      final o = await api.overview(days, includeAdmins: includeAdmins);
      if (token != _overviewToken) return;
      overview = o;
    } catch (e) {
      if (token != _overviewToken) return;
      error = e;
    } finally {
      if (token == _overviewToken) {
        loading = false;
        _notify();
      }
    }
  }

  /// Applies the route's period and switch (`?days=`, `?admins=`).
  void setPeriod(int days, {required bool includeAdmins}) {
    if (days == this.days && includeAdmins == this.includeAdmins) return;
    this.days = days;
    this.includeAdmins = includeAdmins;
    unawaited(reload());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Per-shell collaborators of the Analytics page: the server API (replaced
/// in tests).
class AnalyticsHost {
  AnalyticsHost._(this.services);

  static final Expando<AnalyticsHost> _hosts = Expando('AnalyticsHost');

  /// The host of [services] (created on first use).
  static AnalyticsHost of(ShellServices services) =>
      _hosts[services] ??= AnalyticsHost._(services);

  final ShellServices services;

  AnalyticsApi? _api;

  /// Server access ([ServerAnalyticsApi] unless replaced).
  AnalyticsApi get api => _api ??= ServerAnalyticsApi(services);
  set api(AnalyticsApi v) => _api = v;
}

/// Sums [values] (one per day) into buckets of [size] days, oldest first;
/// the first bucket is the shorter one when the days don't divide evenly,
/// so the last bucket always ends today.
List<double> bucketSums(List<num> values, int size) {
  if (size <= 1) return [for (final v in values) v.toDouble()];
  final out = <double>[];
  var end = values.length;
  while (end > 0) {
    final start = end - size < 0 ? 0 : end - size;
    var sum = 0.0;
    for (var i = start; i < end; i++) {
      sum += values[i];
    }
    out.add(sum);
    end = start;
  }
  return out.reversed.toList();
}

/// The first day of each bucket of [bucketSums] over [days].
List<DateTime> bucketStarts(List<DateTime> days, int size) {
  if (size <= 1) return days;
  final out = <DateTime>[];
  var end = days.length;
  while (end > 0) {
    final start = end - size < 0 ? 0 : end - size;
    out.add(days[start]);
    end = start;
  }
  return out.reversed.toList();
}

/// Days per bar of the bar charts: daily up to 90 days, weekly beyond.
int bucketSizeOf(int days) => days > 90 ? 7 : 1;
