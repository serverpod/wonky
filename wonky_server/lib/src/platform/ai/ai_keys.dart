import 'package:serverpod/serverpod.dart';

import '../organizations/organization_service.dart';
import '../users/user_service.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'ai_config.dart';
import 'ai_models.dart';
import 'llm/ai_client.dart';

/// Whose API key a request uses.
enum AiKeySource { server, user, organization }

/// The provider and key a user's AI requests go out with.
class AiCredentials {
  const AiCredentials(this.provider, this.apiKey, this.source);

  final AiProvider provider;
  final String apiKey;
  final AiKeySource source;
}

/// The resolved model backend of one user: credentials, the client and the
/// model ids of the provider.
class AiBackend {
  AiBackend(this.credentials, this.client, this.config);

  final AiCredentials credentials;
  final AiModelClient client;
  final AiConfig config;

  AiProvider get provider => credentials.provider;

  /// The model id of [tier] for this provider.
  String model(AiTier tier) => config.modelFor(provider, tier.size);
}

/// API keys of the AI features (suite 10 §1 "Keys"): the server's keys
/// (Serverpod passwords) win; without any, a user's own key
/// ([AiUserKey], Settings › AI providers) is used for that user's requests,
/// and without that their organization's shared key ([AiOrgKey]), which
/// any member may add. Keys are stored server-side, readable only through
/// this class for the requests they serve, and never returned to a client
/// (only the provider and the last four characters).
abstract final class AiKeys {
  static const minKeyLength = 16;
  static const maxKeyLength = 512;

  /// Server key > the user's own key > their organization's key > none.
  static AiCredentials? resolve(
    AiConfig config, {
    AiUserKey? userKey,
    AiOrgKey? orgKey,
  }) {
    final p = config.serverProvider;
    if (p != null) {
      return AiCredentials(p, config.serverKeys[p]!, AiKeySource.server);
    }
    if (!config.allowUserKeys) return null;
    final own = userKey?.apiKey.trim() ?? '';
    if (own.isNotEmpty) {
      return AiCredentials(userKey!.provider, own, AiKeySource.user);
    }
    final shared = orgKey?.apiKey.trim() ?? '';
    if (shared.isNotEmpty) {
      return AiCredentials(orgKey!.provider, shared, AiKeySource.organization);
    }
    return null;
  }

  /// The shared key of [userId]'s organization (server-side only; null
  /// without an organization or a key).
  static Future<AiOrgKey?> orgKeyFor(Session session, int userId) async {
    final org = await OrganizationService.orgKeyOf(session, userId);
    if (org == null) return null;
    return AiOrgKey.db.findFirstRow(
      session,
      where: (t) => t.orgKey.equals(org),
    );
  }

  /// The stored key of [userId] (server-side only).
  static Future<AiUserKey?> userKey(Session session, int userId) =>
      AiUserKey.db.findFirstRow(session, where: (t) => t.userId.equals(userId));

  /// The credentials of [userId]'s requests (null = not configured).
  static Future<AiCredentials?> forUser(Session session, int userId) async {
    final config = AiConfig.current;
    if (config.configured) return resolve(config);
    if (!config.allowUserKeys) return null;
    final own = await userKey(session, userId);
    return resolve(
      config,
      userKey: own,
      orgKey: own == null ? await orgKeyFor(session, userId) : null,
    );
  }

  /// The backend of [userId] (null = not configured).
  static Future<AiBackend?> backendFor(Session session, int userId) async {
    final c = await forUser(session, userId);
    if (c == null) return null;
    return AiBackend(
      c,
      AiConfig.clientFor(c.provider, c.apiKey),
      AiConfig.current,
    );
  }

  /// The last four characters of [key].
  static String last4(String key) {
    final k = key.trim();
    return k.length <= 4 ? k : k.substring(k.length - 4);
  }

  static AiProviderKeyView view(AiUserKey k) => AiProviderKeyView(
    provider: k.provider,
    last4: last4(k.apiKey),
    updatedAt: k.updatedAt,
  );

  /// What a member sees of their organization's key.
  static Future<AiOrgKeyView> orgView(Session session, AiOrgKey k) async {
    final by = k.addedById == null
        ? null
        : (await UserService.summaries(session, [k.addedById]))[k.addedById];
    return AiOrgKeyView(
      provider: k.provider,
      last4: last4(k.apiKey),
      updatedAt: k.updatedAt,
      addedBy: by?.displayName,
    );
  }

  /// Checks that keys may be added and [apiKey] looks like one; returns it
  /// trimmed.
  static String _validKey(String apiKey) {
    final config = AiConfig.current;
    if (!config.enabled) {
      throw WonkyException(
        code: WonkyErrorCode.unavailable,
        message: 'AI is turned off on this server.',
      );
    }
    if (!config.userKeysAllowed) {
      throw Errors.invalid(
        config.configured
            ? 'This server already provides AI; your own key is not needed.'
            : 'This server does not allow personal API keys.',
      );
    }
    final key = apiKey.trim();
    if (key.length < minKeyLength ||
        key.length > maxKeyLength ||
        RegExp(r'\s').hasMatch(key)) {
      throw Errors.invalid('That does not look like an API key.');
    }
    return key;
  }

  /// The organization of [userId], or `invalid` without one (a public mail
  /// provider's address has no organization to share a key with).
  static Future<String> _requireOrg(Session session, int userId) async {
    final org = await OrganizationService.orgKeyOf(session, userId);
    if (org == null) {
      throw Errors.invalid(
        'Your email address does not belong to an organization, so there '
        'is no one to share a key with.',
      );
    }
    return org;
  }

  /// Stores [apiKey] for [provider] as the shared key of [userId]'s
  /// organization (replacing any earlier one; any member may). Only while
  /// the server has no key and personal keys are allowed.
  static Future<void> setOrgKey(
    Session session,
    int userId,
    AiProvider provider,
    String apiKey,
  ) async {
    final key = _validKey(apiKey);
    final org = await _requireOrg(session, userId);
    final now = nowUtc();
    final existing = await AiOrgKey.db.findFirstRow(
      session,
      where: (t) => t.orgKey.equals(org),
    );
    if (existing == null) {
      await AiOrgKey.db.insertRow(
        session,
        AiOrgKey(
          orgKey: org,
          provider: provider,
          apiKey: key,
          addedById: userId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await AiOrgKey.db.updateRow(
        session,
        existing.copyWith(
          provider: provider,
          apiKey: key,
          addedById: userId,
          updatedAt: now,
        ),
        // Any member may replace it: write only what changes (T1).
        columns: (t) => [t.provider, t.apiKey, t.addedById, t.updatedAt],
      );
    }
    session.log(
      'AI key for the organization $org set by user $userId '
      '(${provider.name}, …${last4(key)}).',
      level: LogLevel.info,
    );
  }

  /// Removes the shared key of [userId]'s organization (any member may).
  static Future<void> removeOrgKey(Session session, int userId) async {
    final org = await _requireOrg(session, userId);
    await AiOrgKey.db.deleteWhere(
      session,
      where: (t) => t.orgKey.equals(org),
    );
    session.log(
      'AI key for the organization $org removed by user $userId.',
      level: LogLevel.info,
    );
  }

  /// Stores [apiKey] for [provider] as the user's key (replacing any
  /// earlier one). Only while the server has no key of its own.
  static Future<void> setUserKey(
    Session session,
    int userId,
    AiProvider provider,
    String apiKey,
  ) async {
    final key = _validKey(apiKey);
    final existing = await userKey(session, userId);
    final now = nowUtc();
    if (existing == null) {
      await AiUserKey.db.insertRow(
        session,
        AiUserKey(
          userId: userId,
          provider: provider,
          apiKey: key,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await AiUserKey.db.updateRow(
        session,
        existing.copyWith(provider: provider, apiKey: key, updatedAt: now),
      );
    }
  }

  /// Removes the user's key.
  static Future<void> removeUserKey(Session session, int userId) =>
      AiUserKey.db.deleteWhere(session, where: (t) => t.userId.equals(userId));
}
