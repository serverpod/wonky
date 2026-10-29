import 'dart:convert';
import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart'
    show
        AuthUser,
        AuthUserModel,
        AuthUsers,
        TokenManager,
        UserImageSource,
        UserProfileData,
        UserProfileModel,
        UserProfiles;
import 'package:serverpod_auth_idp_server/providers/google.dart';

import '../common/models.dart' show UserProfile;
import 'user_service.dart';

/// Name of the Serverpod password holding the Google OAuth client
/// (`{"web": {"client_id", "client_secret", "redirect_uris"}}`, specs/04
/// §1.6).
const googleClientSecretPassword = 'googleClientSecret';

/// The Google OAuth client from the `googleClientSecret` password (the JSON
/// downloaded from the Google Cloud console, `redirect_uris` optional), or
/// null when it is missing or invalid (a warning is printed: an invalid secret
/// turns Google sign-in off instead of stopping the server).
GoogleClientSecret? googleClientSecret() {
  final String? json;
  try {
    json = Serverpod.instance.getPassword(googleClientSecretPassword);
  } catch (_) {
    return null;
  }
  if (json == null || json.trim().isEmpty) return null;
  try {
    final data = jsonDecode(json);
    // Google's download only has `redirect_uris` when the client had some
    // when it was downloaded. Serverpod requires the key but never uses it:
    // Google checks the redirect URI against the console.
    final web = data is Map ? data['web'] : null;
    if (web is Map && web['redirect_uris'] == null) {
      web['redirect_uris'] = <String>[];
    }
    return GoogleClientSecret.fromJson((data as Map).cast<String, dynamic>());
  } catch (e) {
    _warnInvalidSecret(e);
    return null;
  }
}

var _warned = false;

void _warnInvalidSecret(Object error) {
  if (_warned) return;
  _warned = true;
  // Never print the secret itself.
  stderr.writeln(
    'WARNING: Sign in with Google is off: the `$googleClientSecretPassword` '
    'password is not a valid Google client JSON '
    '({"web": {"client_id", "client_secret", "redirect_uris"}}): $error',
  );
}

/// The Google OAuth web client id when Google sign-in is configured, else
/// null. Public: the web apps get it in `config.json`.
String? googleWebClientId() => googleClientSecret()?.clientId;

/// The Google identity provider (specs/04 §1.6), or null when Google
/// sign-in isn't configured. A first Google sign-in creates the Wonky
/// profile (name from Google), or — when an account with the same verified
/// email exists — signs in to that account instead of creating a second one.
GoogleIdpConfig? wonkyGoogleIdpConfig() {
  final secret = googleClientSecret();
  if (secret == null) return null;
  return _WonkyGoogleIdpConfig(
    clientSecret: secret,
    getExtraGoogleInfoCallback: rememberGoogleDetails,
    onAfterGoogleAccountCreated: afterGoogleAccountCreated,
  );
}

/// [GoogleIdpConfig] whose IDP keeps the existing auth profile of an account
/// that [afterGoogleAccountCreated] linked the Google account to.
class _WonkyGoogleIdpConfig extends GoogleIdpConfig {
  _WonkyGoogleIdpConfig({
    required super.clientSecret,
    super.getExtraGoogleInfoCallback,
    super.onAfterGoogleAccountCreated,
  });

  @override
  GoogleIdp build({
    required TokenManager tokenManager,
    required AuthUsers authUsers,
    required UserProfiles userProfiles,
  }) => super.build(
    tokenManager: tokenManager,
    authUsers: authUsers,
    userProfiles: LinkedAccountUserProfiles(config: userProfiles.config),
  );
}

/// [UserProfiles] that returns the existing auth profile instead of creating
/// a second one. The Google IDP creates the profile of every new Google
/// account, also when [afterGoogleAccountCreated] linked it to an existing
/// account, which already has one (unique per auth user).
class LinkedAccountUserProfiles extends UserProfiles {
  const LinkedAccountUserProfiles({super.config});

  @override
  Future<UserProfileModel> createUserProfile(
    Session session,
    UuidValue authUserId,
    UserProfileData userProfile, {
    Transaction? transaction,
    UserImageSource? imageSource,
  }) async {
    final existing = await maybeFindUserProfileByUserId(
      session,
      authUserId,
      transaction: transaction,
    );
    if (existing != null) return existing;
    return super.createUserProfile(
      session,
      authUserId,
      userProfile,
      transaction: transaction,
      imageSource: imageSource,
    );
  }
}

/// Google's account details of the request, between the two callbacks.
final _details = Expando<GoogleAccountDetails>('googleAccountDetails');

/// Keeps Google's account details (name) for [afterGoogleAccountCreated].
Future<void> rememberGoogleDetails(
  Session session, {
  required GoogleAccountDetails accountDetails,
  required String accessToken,
  required Transaction? transaction,
}) async {
  _details[session] = accountDetails;
}

/// Creates the profile of a new Google account, or links it to the existing
/// account with the same email.
Future<void> afterGoogleAccountCreated(
  Session session,
  AuthUserModel authUser,
  GoogleAccount googleAccount, {
  required Transaction? transaction,
}) async {
  final email = googleAccount.email.trim().toLowerCase();
  // The email is verified by Google (default validation) and by our own
  // sign-up: the same address is the same person.
  final existing = await UserProfile.db.findFirstRow(
    session,
    where: (t) => t.email.equals(email),
    transaction: transaction,
  );
  if (existing != null && existing.authUserId != authUser.id) {
    await linkGoogleAccount(
      session,
      googleAccount,
      to: existing.authUserId,
      unusedAuthUserId: authUser.id,
      transaction: transaction,
    );
    return;
  }
  final details = _details[session];
  await UserService.ensureProfile(
    session,
    authUser.id,
    email: email,
    displayName: details?.fullName ?? details?.name,
    transaction: transaction,
  );
}

/// Moves [googleAccount] to the existing auth user [to] and deletes the
/// auth user that was just created for it ([unusedAuthUserId]). The sign-in
/// in progress then returns [to] (it reads `googleAccount.authUserId`).
Future<void> linkGoogleAccount(
  Session session,
  GoogleAccount googleAccount, {
  required UuidValue to,
  required UuidValue unusedAuthUserId,
  required Transaction? transaction,
}) async {
  googleAccount.authUserId = to;
  await GoogleAccount.db.updateRow(
    session,
    googleAccount,
    transaction: transaction,
  );
  await AuthUser.db.deleteWhere(
    session,
    where: (t) => t.id.equals(unusedAuthUserId),
    transaction: transaction,
  );
}
