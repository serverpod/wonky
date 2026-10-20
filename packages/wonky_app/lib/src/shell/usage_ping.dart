import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';

import 'shell_services.dart';

/// Tells the server that the signed-in user is using this app, for the
/// usage analytics (specs/19 §2): at sign-in and whenever the app comes
/// back to the foreground, at most every [interval]. Best effort: a failed
/// ping is dropped.
class UsagePing with WidgetsBindingObserver {
  UsagePing(this.services);

  final ShellServices services;

  /// The shortest time between two pings.
  static const interval = Duration(minutes: 30);

  DateTime? _last;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(ping());
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _last = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(ping());
  }

  Future<void> ping() async {
    final c = services.client;
    if (c == null || !services.auth.isSignedIn) return;
    final now = clock.now();
    final last = _last;
    if (last != null && now.difference(last) < interval) return;
    _last = now;
    try {
      await c.analytics.ping(UsageApp.values.byName(services.config.app.name));
    } catch (_) {
      // Best effort: analytics never disturb the app.
    }
  }
}
