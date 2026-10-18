import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart' as auth;

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../board/board_sweep.dart';
import '../common/time.dart';
import '../drive/drive_service.dart';
import '../drive/drive_trash.dart';
import '../drive/templates/builtin_templates.dart';
import 'user_service.dart';

/// Account lifecycle: welcome content, deletion (specs/04 §1.1, §4, 13 §2)
/// and personal access tokens (specs/04 §3, 09 §2).
abstract final class AccountService {
  // --------------------------------------------------------------- welcome

  /// Creates the welcome document and spreadsheet once per account.
  static Future<void> ensureWelcomeContent(Session session, Actor actor) async {
    final profile = await UserService.requireProfile(session, actor.userId);
    if (profile.welcomeContentAt != null) return;
    // Claim first so concurrent calls do not create duplicates.
    final claimed = await UserProfile.db.updateWhere(
      session,
      columnValues: (t) => [t.welcomeContentAt(nowUtc())],
      where: (t) => t.id.equals(profile.id!) & t.welcomeContentAt.equals(null),
    );
    if (claimed.isEmpty) return;
    try {
      final doc = BuiltinTemplates.byKey(BuiltinTemplates.welcomeDocumentKey);
      await DriveService.createDocument(
        session,
        actor,
        name: doc.name,
        templateUuid: doc.uuid,
      );
      final sheet = BuiltinTemplates.byKey(
        BuiltinTemplates.welcomeSpreadsheetKey,
      );
      await DriveService.createSpreadsheet(
        session,
        actor,
        name: sheet.name,
        templateUuid: sheet.uuid,
        timeZone: profile.timeZone ?? 'UTC',
      );
    } on Exception catch (e, st) {
      session.log(
        'Welcome content for user ${actor.userId} failed: $e',
        level: LogLevel.error,
        stackTrace: st,
      );
    }
  }

  // -------------------------------------------------------------- deletion

  static Future<AccountDeletionPreview> deletionPreview(
    Session session,
    Actor actor,
  ) async {
    final result = await session.db.unsafeQuery(
      r'''
      SELECT
        count(*) FILTER (WHERE kind = 'document'),
        count(*) FILTER (WHERE kind = 'spreadsheet'),
        count(*) FILTER (WHERE kind = 'folder'),
        count(*) FILTER (WHERE EXISTS (
          SELECT 1 FROM drive_item_permission p WHERE p."itemId" = d.id
            AND (p."userId" IS NULL OR p."userId" <> @me))
          OR EXISTS (SELECT 1 FROM share_link l WHERE l."itemId" = d.id AND l.role IS NOT NULL))
      FROM drive_item d WHERE d."ownerId" = @me
      ''',
      parameters: QueryParameters.named({'me': actor.userId}),
    );
    final row = result.first;
    return AccountDeletionPreview(
      ownedDocuments: row[0] as int,
      ownedSpreadsheets: row[1] as int,
      ownedFolders: row[2] as int,
      sharedOwnedItems: row[3] as int,
    );
  }

  /// Deletes the account: owned items (documents, spreadsheets with their
  /// spaces, folders), memberships, the personal space and the auth user
  /// (cascading to profile, preferences, tokens and notifications).
  /// Authorship in shared items stays as "Deleted user". [confirmation]
  /// must equal the account's email.
  static Future<void> deleteAccount(
    Session session,
    Actor actor,
    String confirmation,
  ) async {
    final profile = await UserService.requireProfile(session, actor.userId);
    if (confirmation.trim().toLowerCase() != profile.email) {
      throw Errors.invalid('Type your email address to confirm.');
    }
    await _purgeOwnedItems(session, actor.userId);
    // Bugs & improvements (specs/16 §11): posts outside tasks, screenshots
    // and votes go; comments and posts in tasks stay as "Deleted user".
    await BoardSweep.deleteUserData(session, actor.userId);
    // The steps above are restartable (a failed deletion can be retried);
    // the account itself goes last.
    await auth.AuthUser.db.deleteWhere(
      session,
      where: (t) => t.id.equals(actor.authUserId),
    );
    await UserService.forgetEverywhere(session, actor.authUserId);
  }

  /// Deletes every item [userId] owns, from the top of each owned subtree.
  /// `DriveService.purge` never deletes other people's items: those inside
  /// the user's folders (at any depth) move to their owners' roots with
  /// their inherited grants rebuilt, and the user's items below them are
  /// purged in a later round.
  static Future<void> _purgeOwnedItems(Session session, int userId) async {
    for (var round = 0; round < 50; round++) {
      final owned = await DriveItem.db.find(
        session,
        where: (t) => t.ownerId.equals(userId),
      );
      if (owned.isEmpty) return;
      final ownedIds = {for (final i in owned) i.id!};
      for (final item in owned) {
        if (item.parentId != null && ownedIds.contains(item.parentId)) {
          continue;
        }
        final current = await DriveItem.db.findById(session, item.id!);
        if (current == null || current.ownerId != userId) continue;
        await DriveTrash.purge(session, current);
      }
    }
    throw StateError('The items of user $userId could not all be deleted.');
  }

  // ---------------------------------------------------------------- tokens

  static const tokenPrefix = 'wkpat_';
  static const allowedScopes = {
    'drive:read',
    'drive:write',
    'write:read',
    'write:edit',
    'sheets:read',
    'sheets:edit',
    // (v2) Slides 11 §2.4.
    'slides:read',
    'slides:edit',
    'scripts:run',
    'ui:control',
    // Bugs & improvements (specs/16 §14).
    'board',
  };
  static const maxTokensPerUser = 50;
  static final _random = Random.secure();
  static const _alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

  static String hashSecret(String secret) =>
      sha256.convert(utf8.encode(secret)).toString();

  static AccessTokenView tokenView(PersonalAccessToken t) => AccessTokenView(
    id: t.id!,
    name: t.name,
    prefix: t.prefix,
    scopes: t.scopes,
    expiresAt: t.expiresAt,
    lastUsedAt: t.lastUsedAt,
    createdAt: t.createdAt,
    revokedAt: t.revokedAt,
  );

  static Future<List<AccessTokenView>> listTokens(
    Session session,
    Actor actor,
  ) async {
    final tokens = await PersonalAccessToken.db.find(
      session,
      where: (t) => t.userId.equals(actor.userId),
      orderBy: (t) => t.createdAt.desc(),
    );
    return [for (final t in tokens) tokenView(t)];
  }

  static Future<CreatedAccessToken> createToken(
    Session session,
    Actor actor, {
    required String name,
    required List<String> scopes,
    DateTime? expiresAt,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty || clean.length > 100) {
      throw Errors.invalid('Token names have 1–100 characters.');
    }
    final unique = scopes.toSet();
    if (unique.isEmpty) throw Errors.invalid('Choose at least one scope.');
    final unknown = unique.difference(allowedScopes);
    if (unknown.isNotEmpty) {
      throw Errors.invalid('Unknown scopes: ${unknown.join(', ')}.');
    }
    if (expiresAt != null && !expiresAt.isAfter(nowUtc())) {
      throw Errors.invalid('The expiration must be in the future.');
    }
    final active = await PersonalAccessToken.db.count(
      session,
      where: (t) => t.userId.equals(actor.userId) & t.revokedAt.equals(null),
    );
    if (active >= maxTokensPerUser) {
      throw Errors.limit('Revoke unused tokens first.');
    }
    final secret =
        tokenPrefix +
        String.fromCharCodes([
          for (var i = 0; i < 40; i++)
            _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
        ]);
    final token = await PersonalAccessToken.db.insertRow(
      session,
      PersonalAccessToken(
        userId: actor.userId,
        name: clean,
        tokenHash: hashSecret(secret),
        prefix: secret.substring(0, tokenPrefix.length + 4),
        scopes: unique.toList()..sort(),
        expiresAt: expiresAt,
        createdAt: nowUtc(),
      ),
    );
    return CreatedAccessToken(token: tokenView(token), secret: secret);
  }

  static Future<AccessTokenView> revokeToken(
    Session session,
    Actor actor,
    int id,
  ) async {
    final token = await PersonalAccessToken.db.findById(session, id);
    if (token == null || token.userId != actor.userId) {
      throw Errors.notFound('Token');
    }
    if (token.revokedAt != null) return tokenView(token);
    final updated = await PersonalAccessToken.db.updateRow(
      session,
      token.copyWith(revokedAt: nowUtc()),
    );
    return tokenView(updated);
  }

  /// Resolves a bearer secret to its token and user (MCP). Returns null for
  /// unknown, revoked or expired tokens; records `lastUsedAt`.
  static Future<(PersonalAccessToken, Actor)?> authenticate(
    Session session,
    String secret, {
    ActorKind kind = ActorKind.mcp,
  }) async {
    if (!secret.startsWith(tokenPrefix)) return null;
    final token = await PersonalAccessToken.db.findFirstRow(
      session,
      where: (t) => t.tokenHash.equals(hashSecret(secret)),
    );
    final now = nowUtc();
    if (token == null ||
        token.revokedAt != null ||
        (token.expiresAt != null && token.expiresAt!.isBefore(now))) {
      return null;
    }
    final profile = await UserProfile.db.findById(session, token.userId);
    if (profile == null) return null;
    if (token.lastUsedAt == null ||
        now.difference(token.lastUsedAt!) > const Duration(minutes: 1)) {
      await PersonalAccessToken.db.updateRow(
        session,
        token.copyWith(lastUsedAt: now),
        columns: (t) => [t.lastUsedAt],
      );
    }
    return (
      token,
      Actor(userId: profile.id!, authUserId: profile.authUserId, kind: kind),
    );
  }
}
