import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../files/file_service.dart';
import 'account_service.dart';
import 'user_service.dart';

/// The signed-in user: profile, preferences, user search and account
/// deletion (specs/04 §5).
class UserEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// The caller's profile. The first call after sign-up also creates the
  /// welcome document and spreadsheet.
  Future<UserProfileView> getMe(Session session) async {
    final actor = await UserService.actorOf(session);
    await AccountService.ensureWelcomeContent(session, actor);
    return UserService.me(session, actor);
  }

  /// Updates the profile; null leaves a field unchanged, an empty string
  /// clears [locale]/[timeZone] (follow the device).
  Future<UserProfileView> updateProfile(
    Session session, {
    String? displayName,
    String? locale,
    String? timeZone,
  }) async => UserService.updateProfile(
    session,
    await UserService.actorOf(session),
    displayName: displayName,
    locale: locale,
    timeZone: timeZone,
  );

  /// Starts an avatar upload (upload description flow); finish with
  /// `file.completeUpload(fileUuid)` (stores a 256 × 256 WebP) and
  /// [setAvatar].
  Future<FileUploadTicket> uploadAvatar(
    Session session,
    UuidValue fileUuid,
    String fileName,
    String mimeType,
    int size,
  ) async => FileService.createUpload(
    session,
    await UserService.actorOf(session),
    fileUuid: fileUuid,
    fileName: fileName,
    mimeType: mimeType,
    size: size,
    kind: StoredFileKind.avatar,
  );

  /// Sets (or with null removes) the avatar.
  Future<UserProfileView> setAvatar(
    Session session,
    UuidValue? fileUuid,
  ) async {
    final actor = await UserService.actorOf(session);
    await UserService.setAvatar(session, actor, fileUuid);
    return UserService.me(session, actor);
  }

  Future<UserPreferences> getPreferences(Session session) async =>
      UserService.preferences(session, await UserService.actorOf(session));

  Future<UserPreferences> updatePreferences(
    Session session,
    UserPreferencesPatch patch,
  ) async => UserService.updatePreferences(
    session,
    await UserService.actorOf(session),
    patch,
  );

  /// Users for the share dialog and @mentions (people sharing items with the
  /// caller, or exact email matches).
  Future<List<UserSummary>> searchUsers(
    Session session,
    String query,
    int limit,
  ) async => UserService.searchUsers(
    session,
    await UserService.actorOf(session),
    query,
    limit,
  );

  /// Summaries of users by id (authors, participants): only the caller and
  /// users related to them (who share an item with them, as in
  /// [searchUsers]); other ids are left out.
  Future<List<UserSummary>> getUsers(Session session, List<int> ids) async {
    final actor = await UserService.actorOf(session);
    final allowed = await UserService.relatedIds(session, actor, ids.take(200));
    final map = await UserService.summaries(session, allowed);
    return map.values.toList();
  }

  Future<AccountDeletionPreview> accountDeletionPreview(
    Session session,
  ) async => AccountService.deletionPreview(
    session,
    await UserService.actorOf(session),
  );

  /// Deletes the account; [confirmation] must equal the account email.
  Future<void> deleteAccount(Session session, String confirmation) async =>
      AccountService.deleteAccount(
        session,
        await UserService.actorOf(session),
        confirmation,
      );
}
