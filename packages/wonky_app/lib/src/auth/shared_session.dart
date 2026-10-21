import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';

/// The JWT key provider of the token-mode web session (suite 01 §2.5): the
/// session sits in storage shared by every tab and app of the origin
/// (`localStorage`), and refresh tokens rotate one tab at a time.
///
/// A refresh token is single-use: the server revokes the session when a
/// rotated one comes back. So a refresh runs under the cross-tab lock and
/// re-reads the shared session inside it; when another tab or app rotated
/// while this one waited, its fresh token is used instead of rotating again.
/// Every read goes to the storage, so a token another tab stored is used
/// right away.
class SharedJwtAuthKeyProvider extends MutexRefresherClientAuthKeyProvider {
  factory SharedJwtAuthKeyProvider({
    required ClientAuthSuccessStorage storage,
    required Future<AuthSuccess> Function(String refreshToken) refresh,
    required Future<void> Function(AuthSuccess authInfo) onRefreshed,
    required CrossTabLock? Function() crossTabLock,
    Duration refreshBefore = const Duration(seconds: 30),
  }) => SharedJwtAuthKeyProvider._(
    _SharedJwtRefresher(
      storage: storage,
      refresh: refresh,
      onRefreshed: onRefreshed,
      crossTabLock: crossTabLock,
      refreshBefore: refreshBefore,
    ),
  );

  SharedJwtAuthKeyProvider._(this._refresher) : super(_refresher);

  final _SharedJwtRefresher _refresher;

  /// Completes when no refresh call is in flight. A page that goes away
  /// mid-refresh loses the rotated token the server already handed out, and
  /// the next refresh with the old one revokes the session, so navigations
  /// wait for this first.
  Future<void> get settled => _refresher.settled;
}

class _SharedJwtRefresher implements RefresherClientAuthKeyProvider {
  _SharedJwtRefresher({
    required this.storage,
    required this.refresh,
    required this.onRefreshed,
    required this.crossTabLock,
    required this.refreshBefore,
  });

  final ClientAuthSuccessStorage storage;
  final Future<AuthSuccess> Function(String refreshToken) refresh;
  final Future<void> Function(AuthSuccess authInfo) onRefreshed;
  final CrossTabLock? Function() crossTabLock;
  final Duration refreshBefore;

  Future<void>? _inFlight;

  Future<void> get settled async {
    try {
      await _inFlight;
    } catch (_) {
      // Failures are reported to the refreshing call.
    }
  }

  @override
  Future<String?> get authHeaderValue async {
    final auth = await storage.get();
    if (auth == null || auth.token.isEmpty) return null;
    return wrapAsBearerAuthHeaderValue(auth.token);
  }

  @override
  Future<RefreshAuthKeyResult> refreshAuthKey({bool force = false}) async {
    final seen = await storage.get();
    if (seen?.refreshToken == null) return RefreshAuthKeyResult.skipped;
    if (!force && !_isExpiring(seen!)) return RefreshAuthKeyResult.skipped;
    final lock = crossTabLock();
    return lock == null
        ? _refreshLocked(seen!)
        : lock.synchronize(() => _refreshLocked(seen!));
  }

  Future<RefreshAuthKeyResult> _refreshLocked(AuthSuccess seen) async {
    final current = await storage.get();
    final refreshToken = current?.refreshToken;
    // Signed out in another tab or app while this one waited.
    if (current == null || refreshToken == null) {
      return RefreshAuthKeyResult.failedUnauthorized;
    }
    // Rotated by another tab or app while this one waited: use its token.
    if (refreshToken != seen.refreshToken && !_isExpiring(current)) {
      await onRefreshed(current);
      return RefreshAuthKeyResult.success;
    }
    final call = refresh(refreshToken);
    _inFlight = call;
    try {
      await onRefreshed(await call);
      return RefreshAuthKeyResult.success;
    } on RefreshTokenMalformedException {
      return RefreshAuthKeyResult.failedUnauthorized;
    } on RefreshTokenNotFoundException {
      return RefreshAuthKeyResult.failedUnauthorized;
    } on RefreshTokenExpiredException {
      return RefreshAuthKeyResult.failedUnauthorized;
    } on RefreshTokenInvalidSecretException {
      return RefreshAuthKeyResult.failedUnauthorized;
    } catch (_) {
      return RefreshAuthKeyResult.failedOther;
    } finally {
      if (identical(_inFlight, call)) _inFlight = null;
    }
  }

  bool _isExpiring(AuthSuccess auth) {
    final expiresAt = auth.tokenExpiresAt;
    if (auth.token.isEmpty) return true;
    return expiresAt != null &&
        clock.now().toUtc().add(refreshBefore).isAfter(expiresAt);
  }
}

/// The startup check of a restored shared session, in place of
/// `FlutterAuthSessionManager.initialize()`, which rotates the refresh token
/// on every page load (and so on every switch between the apps). Rotates
/// only when the stored token is about to expire, or once when the server
/// rejects a token that still looks valid here (clock skew); signs out
/// when the session is gone. Network errors propagate and keep the session.
Future<void> validateSharedSession({
  required FlutterAuthSessionManager auth,
  required Future<bool> Function() isSignedIn,
}) async {
  await auth.restore();
  if (!auth.isAuthenticated) return;
  final result = await auth.refreshAuthKey();
  if (result == RefreshAuthKeyResult.failedUnauthorized) {
    await auth.signOutDevice();
    return;
  }
  if (await isSignedIn()) return;
  final retry = await auth.refreshAuthKey(force: true);
  if (retry == RefreshAuthKeyResult.failedOther) return;
  if (retry == RefreshAuthKeyResult.failedUnauthorized || !await isSignedIn()) {
    await auth.signOutDevice();
  }
}

/// [storage] with a one-time move of the session from [legacy] (the
/// package default, `flutter_secure_storage`), so nobody is signed out when
/// the shared storage ships. The legacy copy is cleared, so a tab still
/// running the previous build can no longer rotate the refresh token.
class MigratingAuthSuccessStorage implements ClientAuthSuccessStorage {
  MigratingAuthSuccessStorage({required this.storage, required this.legacy});

  final ClientAuthSuccessStorage storage;
  final ClientAuthSuccessStorage legacy;

  bool _migrated = false;

  @override
  Future<AuthSuccess?> get() async {
    final data = await storage.get();
    if (data != null || _migrated) return data;
    _migrated = true;
    final old = await legacy.get();
    if (old == null) return null;
    await storage.set(old);
    await legacy.set(null);
    return old;
  }

  @override
  Future<void> set(AuthSuccess? data) async {
    await storage.set(data);
    if (_migrated) return;
    _migrated = true;
    await legacy.set(null);
  }
}
