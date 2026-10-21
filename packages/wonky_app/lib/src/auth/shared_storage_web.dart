import 'dart:async';

import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:web/web.dart' as web;

import 'shared_session.dart';

/// The `localStorage` key of the shared token-mode session.
const _sessionKey = 'wonky.auth.session';

/// The token-mode session in `localStorage`, shared by every tab and app of
/// the origin (suite 01 §2.5). Not cached: each read sees what another tab
/// stored. Moves the session out of the package default storage once.
ClientAuthSuccessStorage sharedSessionStorage() => MigratingAuthSuccessStorage(
  storage: KeyValueClientAuthSuccessStorage(
    keyValueStorage: _LocalStorage(),
    authSuccessStorageKey: _sessionKey,
  ),
  legacy: SecureClientAuthSuccessStorage(),
);

/// Fires when another tab or app changed the shared session (sign-in,
/// sign-out, rotated tokens).
Stream<void> sharedSessionChanges() => web.EventStreamProviders.storageEvent
    .forTarget(web.window)
    .where((e) => e.key == null || e.key == _sessionKey)
    .map((_) {});

class _LocalStorage implements KeyValueStorage {
  @override
  Future<String?> get(String key) async => web.window.localStorage.getItem(key);

  @override
  Future<void> set(String key, String? value) async => value == null
      ? web.window.localStorage.removeItem(key)
      : web.window.localStorage.setItem(key, value);
}
