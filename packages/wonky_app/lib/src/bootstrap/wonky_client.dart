import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:wonky_client/wonky_client.dart';

import '../auth/shared_session.dart';
import '../auth/shared_storage_io.dart'
    if (dart.library.js_interop) '../auth/shared_storage_web.dart'
    as shared;
import 'app_urls.dart';

/// Creates and owns the generated Serverpod [Client] (suite 01 §2.5): server
/// URL from `config.json`, `FlutterConnectivityMonitor`,
/// `FlutterAuthSessionManager`, cookie auth on web, else the token-mode
/// session shared by all tabs and apps (`SharedJwtAuthKeyProvider`).
///
/// Only repositories use the client; widgets never do (suite 03 §5).
class WonkyClient {
  WonkyClient._(this.client, this.urls);

  final Client client;
  final AppUrls urls;

  /// Replaces the persisted session storage (E2E tests keep the session in
  /// memory so runs neither depend on nor touch the OS keychain).
  @visibleForTesting
  static ClientAuthSuccessStorage? sessionStorageOverride;

  /// Loads the config and initializes the client and its auth session.
  static Future<WonkyClient> initialize({AppUrls? urls}) async {
    final u = urls ?? await AppUrls.load();
    final client = Client(u.apiUrl)
      ..connectivityMonitor = FlutterConnectivityMonitor();
    final sharedSession =
        kIsWeb && !u.cookieAuth && sessionStorageOverride == null;
    if (sharedSession) {
      _installSharedSession(client);
    } else {
      client.authSessionManager = FlutterAuthSessionManager(
        storage: sessionStorageOverride ?? _desktopSessionStorage(),
      );
    }
    if (kIsWeb && u.cookieAuth) {
      // One sign-in for both apps: the session lives in the httpOnly auth
      // cookie on the shared origin; tokens never sit in JS storage. Only
      // when the server is configured for it (`cookieAuth` in config.json):
      // without `authCookie`/`allowedOrigins` the API answers CORS with `*`
      // and browsers block every credentialed request. Otherwise the
      // session is kept in localStorage, shared by every tab and app.
      client.cookieAuth = true;
    }
    // Restores the persisted session (or the cookie session on web). Never
    // blocks startup for long: the shell shows a splash until it completes.
    try {
      await (sharedSession
              ? validateSharedSession(
                  auth: client.auth,
                  isSignedIn: client.auth.caller.status.isSignedIn,
                )
              : client.auth.initialize())
          .timeout(const Duration(seconds: 8));
    } on TimeoutException {
      // Offline start: keep whatever session info was restored.
    } catch (e) {
      debugPrint('Auth initialization failed: $e');
    }
    return WonkyClient._(client, u);
  }

  /// Token mode on web (suite 01 §2.5): the session in `localStorage`,
  /// shared by every tab and app, with refreshes serialized across them;
  /// a change made in another tab or app is picked up right away.
  static void _installSharedSession(Client client) {
    final storage = shared.sharedSessionStorage();
    late final FlutterAuthSessionManager manager;
    final keys = SharedJwtAuthKeyProvider(
      storage: storage,
      refresh: (refreshToken) =>
          client.jwtRefresh.refreshAccessToken(refreshToken: refreshToken),
      onRefreshed: (authInfo) => manager.updateSignedInUser(authInfo),
      crossTabLock: () => client.authRefreshCrossTabLock,
    );
    manager = FlutterAuthSessionManager(
      storage: storage,
      authKeyProviderDelegates: {AuthStrategy.jwt.name: keys},
    );
    client.authSessionManager = manager;
    shared.sharedSessionChanges().listen((_) => manager.restore());
  }

  /// Completes when no auth refresh is in flight in this page (bounded), so
  /// a page navigation does not drop a rotated refresh token (token mode).
  static Future<void> authRefreshSettled(Client? client) async {
    final keys = client?.auth.authKeyProviderDelegate;
    if (keys is! SharedJwtAuthKeyProvider) return;
    await keys.settled.timeout(const Duration(seconds: 5), onTimeout: () {});
  }

  /// macOS: the data-protection keychain needs a signed app with the
  /// `keychain-access-groups` entitlement (error -34018 otherwise, so the
  /// session could not be saved and sign-in failed in debug and E2E runs).
  /// The login keychain works for sandboxed, unsigned builds too. Other
  /// platforms keep the package default.
  static ClientAuthSuccessStorage? _desktopSessionStorage() {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return null;
    return SecureClientAuthSuccessStorage(
      secureStorage: const FlutterSecureStorage(
        mOptions: MacOsOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
          usesDataProtectionKeychain: false,
        ),
      ),
    );
  }
}
