import 'package:flutter/foundation.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:wonky_client/wonky_client.dart';

import '../core/local_store.dart';
import 'api.dart';

/// The signed-in user's profile, preferences and access tokens (suite 04 §5).
abstract class UserRepository {
  Future<UserProfileView> getMe();

  /// The profile [getMe] last returned on this device for the signed-in
  /// user, without a network call (the shell renders from it first, CQ-45),
  /// or null.
  Future<UserProfileView?> cachedMe();

  Future<UserProfileView> updateProfile({
    String? displayName,
    String? locale,
    String? timeZone,
  });

  /// Sets the avatar from an uploaded (ready) file.
  Future<UserProfileView> setAvatar(UuidValue? fileUuid);

  Future<UserPreferences> getPreferences();

  Future<UserPreferences> updatePreferences(UserPreferencesPatch patch);

  /// Users who share at least one item with the caller, or exact email
  /// matches (share dialog, @mentions).
  Future<List<UserSummary>> searchUsers(String query, {int limit = 10});

  Future<AccountDeletionPreview> deleteAccountPreview();

  Future<void> deleteAccount(String confirmation);

  Future<List<AccessTokenView>> listTokens();

  Future<CreatedAccessToken> createToken({
    required String name,
    required List<String> scopes,
    DateTime? expiresAt,
  });

  Future<void> revokeToken(int id);
}

/// [UserRepository] backed by the `user` and `accessToken` endpoints.
///
/// The last profile is kept on the device (per auth user) so the app can
/// start offline with the signed-in user's local data (suite 12).
class ServerUserRepository implements UserRepository {
  ServerUserRepository(this.api, {LocalStore? profileCache})
    : _cache = profileCache ?? SharedPreferencesStore();

  final Api api;
  final LocalStore _cache;

  String? get _cacheKey {
    try {
      final id = api.client.auth.authInfo?.authUserId;
      return id == null ? null : 'profile.${id.uuid}';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserProfileView?> cachedMe() async {
    final key = _cacheKey;
    if (key == null) return null;
    try {
      final cached = await _cache.read(key);
      return cached is Map
          ? UserProfileView.fromJson(cached.cast<String, dynamic>())
          : null;
    } catch (e) {
      debugPrint('Reading the cached profile failed: $e');
      return null;
    }
  }

  @override
  Future<UserProfileView> getMe() async {
    final key = _cacheKey;
    try {
      final me = await api.guard((c) => c.user.getMe());
      if (key != null) {
        try {
          await _cache.write(key, me.toJson());
        } catch (e) {
          debugPrint('Caching the profile failed: $e');
        }
      }
      return me;
    } catch (e) {
      if (!isOfflineError(e) || key == null) rethrow;
      final cached = await _cache.read(key);
      if (cached is! Map) rethrow;
      return UserProfileView.fromJson(cached.cast<String, dynamic>());
    }
  }

  @override
  Future<UserProfileView> updateProfile({
    String? displayName,
    String? locale,
    String? timeZone,
  }) => api.guard(
    (c) => c.user.updateProfile(
      displayName: displayName,
      locale: locale,
      timeZone: timeZone,
    ),
  );

  @override
  Future<UserProfileView> setAvatar(UuidValue? fileUuid) =>
      api.guard((c) => c.user.setAvatar(fileUuid));

  @override
  Future<UserPreferences> getPreferences() =>
      api.guard((c) => c.user.getPreferences());

  @override
  Future<UserPreferences> updatePreferences(UserPreferencesPatch patch) =>
      api.guard((c) => c.user.updatePreferences(patch));

  @override
  Future<List<UserSummary>> searchUsers(String query, {int limit = 10}) =>
      api.guard((c) => c.user.searchUsers(query, limit));

  @override
  Future<AccountDeletionPreview> deleteAccountPreview() =>
      api.guard((c) => c.user.accountDeletionPreview());

  @override
  Future<void> deleteAccount(String confirmation) =>
      api.guard((c) => c.user.deleteAccount(confirmation));

  @override
  Future<List<AccessTokenView>> listTokens() =>
      api.guard((c) => c.accessToken.list());

  @override
  Future<CreatedAccessToken> createToken({
    required String name,
    required List<String> scopes,
    DateTime? expiresAt,
  }) => api.guard((c) => c.accessToken.create(name, scopes, expiresAt));

  @override
  Future<void> revokeToken(int id) =>
      api.guard((c) => c.accessToken.revoke(id));
}
