import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart'
    show AuthenticationInfoAuthUserId;
import 'package:serverpod_auth_idp_server/providers/email.dart'
    show EmailAccount;

import '../cluster/cluster.dart';
import '../common/models.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/json.dart';
import '../common/lru_map.dart';
import '../common/time.dart';
import '../../write/themes/builtin_theme_ids.dart';
import '../storage/storage_counters.dart';

/// Users, profiles and preferences (specs/04 §3, §5).
abstract final class UserService {
  /// Presence/initials palette; [UserSummary.avatarColor] is one of these.
  static const avatarPalette = [
    '#E5484D',
    '#F76B15',
    '#FFC53D',
    '#46A758',
    '#12A594',
    '#00A2C7',
    '#0090FF',
    '#3E63DD',
    '#6E56CF',
    '#8E4EC6',
    '#D6409F',
    '#AD7F58',
  ];

  /// Profile ids by auth user (bounded, CQ-32: an id never changes, so
  /// there is no expiry; account deletion forgets it everywhere).
  static final LruMap<String, int> _profileIdByAuthUser = LruMap(100000);

  /// Public avatar URLs by file (bounded; an avatar file is immutable).
  static final LruMap<String, String> _avatarUrlCache = LruMap(20000);

  /// The stable presence color index of a user.
  static int colorIndexFor(UuidValue authUserId) {
    var hash = 0;
    for (final b in authUserId.toBytes()) {
      hash = (hash * 31 + b) & 0x7fffffff;
    }
    return hash % avatarPalette.length;
  }

  /// The [Actor] of an authenticated request, creating the profile on first
  /// use (accounts created before the sign-up hook existed).
  static Future<Actor> actorOf(Session session, {ActorKind? kind}) async {
    final auth = session.authenticated;
    if (auth == null) {
      throw Errors.forbidden('You need to sign in.');
    }
    final authUserId = auth.authUserId;
    final userId = await profileIdFor(session, authUserId);
    return Actor(
      userId: userId,
      authUserId: authUserId,
      kind: kind ?? ActorKind.user,
    );
  }

  /// The UserProfile id of [authUserId], creating the profile if needed.
  static Future<int> profileIdFor(Session session, UuidValue authUserId) async {
    final cached = _profileIdByAuthUser.get(authUserId.uuid);
    if (cached != null) return cached;
    final profile = await ensureProfile(session, authUserId);
    if (Cluster.distributed) {
      // Other instances may delete the account (specs/13 §4).
      await Cluster.on(session, 'user.forget', (s) {
        if (s.authUserId != null) forget(s.authUserId!);
      });
    }
    _profileIdByAuthUser.put(authUserId.uuid, profile.id!);
    return profile.id!;
  }

  /// Forgets cached ids on this instance (tests).
  static void forget(UuidValue authUserId) =>
      _profileIdByAuthUser.remove(authUserId.uuid);

  /// Forgets cached ids on every instance (account deletion).
  static Future<void> forgetEverywhere(
    Session session,
    UuidValue authUserId,
  ) async {
    forget(authUserId);
    await Cluster.signal(
      session,
      Cluster.build('user.forget', authUserId: authUserId),
    );
  }

  /// Returns the profile of [authUserId], creating it (with preferences) if
  /// it does not exist yet. Pending email invites for the user's address are
  /// converted to grants.
  static Future<UserProfile> ensureProfile(
    Session session,
    UuidValue authUserId, {
    String? email,
    String? displayName,
    Transaction? transaction,
  }) async {
    final existing = await UserProfile.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
      transaction: transaction,
    );
    if (existing != null) return existing;

    email ??= (await EmailAccount.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
      transaction: transaction,
    ))?.email;
    final normalizedEmail = (email ?? '${authUserId.uuid}@users.invalid')
        .trim()
        .toLowerCase();
    final now = nowUtc();

    Future<UserProfile> create(Transaction tx) async {
      final profile = await UserProfile.db.insertRow(
        session,
        UserProfile(
          authUserId: authUserId,
          displayName: _cleanDisplayName(
            displayName ?? _nameFromEmail(normalizedEmail),
          ),
          email: normalizedEmail,
          avatarColor: avatarPalette[colorIndexFor(authUserId)],
          createdAt: now,
        ),
        transaction: tx,
      );
      await UserPreferences.db.insertRow(
        session,
        UserPreferences(
          userId: profile.id!,
          writeDefaults: jsonEncode({
            'defaultThemeId': BuiltinThemeIds.wonkyDefault.uuid,
          }),
          updatedAt: now,
        ),
        transaction: tx,
      );
      // (v2) A new user's storage counters start reconciled (Drive 03 §9).
      await StorageCounters.ensureRow(
        session,
        profile.id!,
        transaction: tx,
        newUser: true,
      );
      // Pending invites (specs/06 §2): convert to grants for this user.
      await DriveItemPermission.db.updateWhere(
        session,
        columnValues: (t) => [t.userId(profile.id!)],
        where: (t) =>
            t.invitedEmail.equals(normalizedEmail) & t.userId.equals(null),
        transaction: tx,
      );
      return profile;
    }

    try {
      if (transaction != null) return await create(transaction);
      return await session.db.transaction(create);
    } on DatabaseException {
      // A concurrent request created it first.
      final again = await UserProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(authUserId),
        transaction: transaction,
      );
      if (again != null) return again;
      rethrow;
    }
  }

  static String _nameFromEmail(String email) {
    final local = email.split('@').first.replaceAll(RegExp(r'[._+-]+'), ' ');
    final words = local.split(' ').where((w) => w.isNotEmpty);
    final name = words
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    return name.isEmpty ? 'User' : name;
  }

  static String _cleanDisplayName(String name) {
    final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) throw Errors.invalid('The name cannot be empty.');
    return trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
  }

  static Future<UserProfile> requireProfile(Session session, int userId) async {
    final profile = await UserProfile.db.findById(session, userId);
    if (profile == null) throw Errors.notFound('User');
    return profile;
  }

  // ---------------------------------------------------------------- views

  /// Public summaries of [userIds] (missing users are left out).
  static Future<Map<int, UserSummary>> summaries(
    Session session,
    Iterable<int?> userIds,
  ) async {
    final ids = userIds.whereType<int>().toSet();
    if (ids.isEmpty) return {};
    final profiles = await UserProfile.db.find(
      session,
      where: (t) => t.id.inSet(ids),
    );
    // Uncached avatars in one query (CQ-32), not one per profile.
    await _loadAvatarUrls(session, {
      for (final p in profiles) ?p.avatarFileId,
    });
    final result = <int, UserSummary>{};
    for (final p in profiles) {
      result[p.id!] = await summaryOf(session, p);
    }
    return result;
  }

  static Future<UserSummary?> summary(Session session, int? userId) async {
    if (userId == null) return null;
    return (await summaries(session, [userId]))[userId];
  }

  static Future<UserSummary> summaryOf(
    Session session,
    UserProfile profile,
  ) async => UserSummary(
    id: profile.id!,
    uuid: profile.authUserId,
    displayName: profile.displayName,
    email: profile.email,
    avatarUrl: await avatarUrl(session, profile.avatarFileId),
    avatarColor: profile.avatarColor,
    colorIndex: colorIndexFor(profile.authUserId),
  );

  static Future<String?> avatarUrl(Session session, UuidValue? fileId) async {
    if (fileId == null) return null;
    final cached = _avatarUrlCache.get(fileId.uuid);
    if (cached != null) return cached;
    await _loadAvatarUrls(session, {fileId});
    return _avatarUrlCache.get(fileId.uuid);
  }

  /// Caches the public URLs of the ready avatar files among [fileIds] that
  /// are not cached yet (one query).
  static Future<void> _loadAvatarUrls(
    Session session,
    Set<UuidValue> fileIds,
  ) async {
    final missing = {
      for (final id in fileIds)
        if (!_avatarUrlCache.containsKey(id.uuid)) id,
    };
    if (missing.isEmpty) return;
    final files = await StoredFile.db.find(
      session,
      where: (t) =>
          t.fileUuid.inSet(missing) & t.status.equals(StoredFileStatus.ready),
    );
    for (final file in files) {
      try {
        final url = await session.storage.publicDownloadUrl(
          storageId: file.storageId,
          path: file.path,
        );
        _avatarUrlCache.put(file.fileUuid.uuid, url.toString());
      } on Exception {
        // Not available: the summary shows the initials.
      }
    }
  }

  static Future<UserProfileView> me(Session session, Actor actor) async {
    final profile = await requireProfile(session, actor.userId);
    await UserProfile.db.updateRow(
      session,
      profile.copyWith(lastSeenAt: nowUtc()),
      columns: (t) => [t.lastSeenAt],
    );
    return UserProfileView(
      summary: await summaryOf(session, profile),
      locale: profile.locale,
      timeZone: profile.timeZone,
      createdAt: profile.createdAt,
    );
  }

  static Future<UserProfileView> updateProfile(
    Session session,
    Actor actor, {
    String? displayName,
    String? locale,
    String? timeZone,
  }) async {
    final profile = await requireProfile(session, actor.userId);
    final updated = profile.copyWith(
      displayName: displayName == null
          ? profile.displayName
          : _cleanDisplayName(displayName),
      locale: locale == null
          ? profile.locale
          : (locale.isEmpty ? null : locale),
      timeZone: timeZone == null
          ? profile.timeZone
          : (timeZone.isEmpty ? null : timeZone),
    );
    // Only the edited columns: a full-row write from a stale read would
    // reset `welcomeContentAt` (or `lastSeenAt`, `avatarFileId`) set by a
    // concurrent request (e.g. the first getMe after sign-up).
    await UserProfile.db.updateRow(
      session,
      updated,
      columns: (t) => [t.displayName, t.locale, t.timeZone],
    );
    return me(session, actor);
  }

  static Future<void> setAvatar(
    Session session,
    Actor actor,
    UuidValue? fileUuid,
  ) async {
    final profile = await requireProfile(session, actor.userId);
    if (fileUuid != null) {
      final file = await StoredFile.db.findFirstRow(
        session,
        where: (t) => t.fileUuid.equals(fileUuid),
      );
      if (file == null ||
          file.ownerId != actor.userId ||
          file.kind != StoredFileKind.avatar) {
        throw Errors.notFound('Avatar');
      }
      if (file.status != StoredFileStatus.ready) {
        throw Errors.invalid('The avatar upload is not complete.');
      }
    }
    await UserProfile.db.updateRow(
      session,
      profile.copyWith(avatarFileId: fileUuid),
      columns: (t) => [t.avatarFileId],
    );
  }

  // ---------------------------------------------------------- preferences

  static Future<UserPreferences> preferences(
    Session session,
    Actor actor,
  ) async {
    final prefs = await UserPreferences.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(actor.userId),
    );
    if (prefs != null) return prefs;
    return UserPreferences.db.insertRow(
      session,
      UserPreferences(
        userId: actor.userId,
        writeDefaults: jsonEncode({
          'defaultThemeId': BuiltinThemeIds.wonkyDefault.uuid,
        }),
        updatedAt: nowUtc(),
      ),
    );
  }

  static Future<UserPreferences> updatePreferences(
    Session session,
    Actor actor,
    UserPreferencesPatch patch,
  ) async {
    final prefs = await preferences(session, actor);
    String merge(String base, String? json) {
      if (json == null) return base;
      final value = jsonDecode(json);
      if (value is! Map) {
        throw Errors.invalid('Preference patches must be JSON objects.');
      }
      return jsonEncode(
        mergeObjects(decodeObject(base), value.cast<String, Object?>()),
      );
    }

    final updated = prefs.copyWith(
      appTheme: patch.appTheme ?? prefs.appTheme,
      accentColor: patch.clearAccentColor == true
          ? null
          : (patch.accentColor ?? prefs.accentColor),
      density: patch.density ?? prefs.density,
      reduceMotion: patch.reduceMotion ?? prefs.reduceMotion,
      keymapOverrides: merge(prefs.keymapOverrides, patch.keymapOverrides),
      writeDefaults: merge(prefs.writeDefaults, patch.writeDefaults),
      sheetsDefaults: merge(prefs.sheetsDefaults, patch.sheetsDefaults),
      slidesDefaults: merge(prefs.slidesDefaults, patch.slidesDefaults),
      slidesPresenter: merge(prefs.slidesPresenter, patch.slidesPresenter),
      driveDefaults: merge(prefs.driveDefaults, patch.driveDefaults),
      notificationSettings: merge(
        prefs.notificationSettings,
        patch.notificationSettings,
      ),
      aiEnabled: patch.aiEnabled ?? prefs.aiEnabled,
      updatedAt: nowUtc(),
    );
    // `copyWith` cannot clear a nullable field; write explicitly.
    final row = patch.clearAccentColor == true
        ? UserPreferences(
            id: updated.id,
            userId: updated.userId,
            appTheme: updated.appTheme,
            accentColor: null,
            density: updated.density,
            reduceMotion: updated.reduceMotion,
            keymapOverrides: updated.keymapOverrides,
            writeDefaults: updated.writeDefaults,
            sheetsDefaults: updated.sheetsDefaults,
            slidesDefaults: updated.slidesDefaults,
            slidesPresenter: updated.slidesPresenter,
            driveDefaults: updated.driveDefaults,
            notificationSettings: updated.notificationSettings,
            aiEnabled: updated.aiEnabled,
            updatedAt: updated.updatedAt,
          )
        : updated;
    return UserPreferences.db.updateRow(session, row);
  }

  /// The user's default Write theme (falls back to Wonky Default).
  static Future<UuidValue> defaultThemeId(Session session, int userId) async {
    final prefs = await UserPreferences.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    final id = decodeObject(prefs?.writeDefaults)['defaultThemeId'];
    if (id is String) {
      try {
        return UuidValue.withValidation(id);
      } on FormatException {
        // Fall back.
      }
    }
    return BuiltinThemeIds.wonkyDefault;
  }

  /// Whether the user's new documents are Pageless (Write settings › Page &
  /// export › Default layout, `writeDefaults.pageless`; Write 05 §13.3).
  /// Pageless unless the user chose Pages (T-1).
  static Future<bool> defaultPageless(Session session, int userId) async {
    final prefs = await UserPreferences.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return decodeObject(prefs?.writeDefaults)['pageless'] != false;
  }

  // --------------------------------------------------------------- search

  /// The users related to `@me`: the owners of and grantees on the items
  /// `@me` owns or has a grant on (`related.uid`).
  static const _relatedCte = r'''
      WITH my_items AS (
        SELECT d.id FROM drive_item d WHERE d."ownerId" = @me
        UNION
        SELECT p."itemId" FROM drive_item_permission p WHERE p."userId" = @me
      ),
      related AS (
        SELECT d."ownerId" AS uid FROM drive_item d
          WHERE d.id IN (SELECT id FROM my_items)
        UNION
        SELECT p."userId" FROM drive_item_permission p
          WHERE p."itemId" IN (SELECT id FROM my_items) AND p."userId" IS NOT NULL
      )''';

  /// The ids among [userIds] that [actor] may look up: themself and the
  /// users related to them (the [searchUsers] relation). Others' names and
  /// emails are not revealed by id.
  static Future<Set<int>> relatedIds(
    Session session,
    Actor actor,
    Iterable<int> userIds,
  ) async {
    final ids = userIds.toSet();
    final result = <int>{if (ids.remove(actor.userId)) actor.userId};
    if (ids.isEmpty) return result;
    final rows = await session.db.unsafeQuery(
      '$_relatedCte SELECT uid FROM related '
      'WHERE uid IN (${ids.join(',')})',
      parameters: QueryParameters.named({'me': actor.userId}),
    );
    return {...result, for (final row in rows) row[0] as int};
  }

  /// Users for the share dialog and @mentions: users who share at least one
  /// item with the caller, plus exact email matches (specs/04 §5).
  static Future<List<UserSummary>> searchUsers(
    Session session,
    Actor actor,
    String query,
    int limit,
  ) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final cap = limit.clamp(1, 50);
    final like = '%${_escapeLike(q)}%';
    final result = await session.db.unsafeQuery(
      '''
      $_relatedCte
      SELECT u.id FROM user_profile u
      WHERE u.id <> @me AND (
        u.email = @exact OR (
          u.id IN (SELECT uid FROM related) AND
          (lower(u."displayName") LIKE @like OR u.email LIKE @like)
        )
      )
      ORDER BY (u.email = @exact) DESC, lower(u."displayName")
      LIMIT @limit
      ''',
      parameters: QueryParameters.named({
        'me': actor.userId,
        'exact': q,
        'like': like,
        'limit': cap,
      }),
    );
    final ids = [for (final row in result) row[0] as int];
    final summaries = await UserService.summaries(session, ids);
    return [
      for (final id in ids)
        if (summaries[id] != null) summaries[id]!,
    ];
  }

  static String _escapeLike(String s) =>
      s.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
}
