import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/rate_limiter.dart';
import '../common/time.dart';
import '../config/wonky_config.dart';
import 'publication_keys.dart';
import 'publication_rules.dart';

/// Shared lookups and links of publications (specs/18).
abstract final class Publications {
  /// The public id of a submission: `sub_<uuid>`.
  static String submissionId(Submission s) => 'sub_${s.uuid.uuid}';

  static UuidValue? parseSubmissionId(String id) =>
      _uuid(id.startsWith('sub_') ? id.substring(4) : null);

  /// The public id of an image of a submission: `ast_<fileUuid>`.
  static String assetId(UuidValue fileUuid) => 'ast_${fileUuid.uuid}';

  static UuidValue? parseAssetId(String id) =>
      _uuid(id.startsWith('ast_') ? id.substring(4) : null);

  static UuidValue? _uuid(String? s) {
    if (s == null) return null;
    try {
      return UuidValue.withValidation(s);
    } on FormatException {
      return null;
    }
  }

  static Uri webOrigin(Session session) =>
      WonkyConfig.current.webOrigin(session.serverpod.config);

  /// `https://<host>/write/d/<uuid>`.
  static String documentUrl(Session session, UuidValue itemUuid) =>
      webOrigin(session).resolve('write/d/${itemUuid.uuid}').toString();

  /// `https://<host>/write/new?publication=<publicId>`.
  static String contributorLink(Session session, String publicId) => webOrigin(
    session,
  ).resolve('write/new?publication=$publicId').toString();

  /// The API URL of an image (specs/18 §7.1).
  static String assetUrl(Session session, UuidValue fileUuid) => webOrigin(
    session,
  ).resolve('api/pub/v1/assets/${assetId(fileUuid)}').toString();

  /// The host contributors are shown: the verified site host, else the
  /// webhook host (specs/18 §8.2).
  static String shownHost(Publication p) =>
      p.verifiedHost ?? PublicationRules.hostOf(p.webhookUrl);

  /// What a contributor agrees to; consent is asked again when it changes.
  static String consentKey(Publication p) => sha256
      .convert(
        utf8.encode(
          '${shownHost(p)}|${PublicationRules.hostOf(p.webhookUrl)}|'
          '${p.termsUrl ?? ''}',
        ),
      )
      .toString();

  static Future<Publication> byPublicId(
    Session session,
    String publicId,
  ) async {
    if (!PublicationKeys.publicIdPattern.hasMatch(publicId)) {
      throw Errors.notFound('Publication');
    }
    final p = await Publication.db.findFirstRow(
      session,
      where: (t) => t.publicId.equals(publicId),
    );
    if (p == null) throw Errors.notFound('Publication');
    return p;
  }

  static Future<bool> isBlocked(
    Session session,
    int publicationId,
    int userId,
  ) async =>
      await PublicationBlock.db.findFirstRow(
        session,
        where: (t) =>
            t.publicationId.equals(publicationId) & t.userId.equals(userId),
      ) !=
      null;

  static Future<bool> consentNeeded(
    Session session,
    Publication p,
    int userId,
  ) async {
    final consent = await PublicationConsent.db.findFirstRow(
      session,
      where: (t) => t.publicationId.equals(p.id!) & t.userId.equals(userId),
    );
    return consent?.consentKey != consentKey(p);
  }

  static Future<void> recordConsent(
    Session session,
    Publication p,
    int userId,
  ) async {
    final key = consentKey(p);
    final now = nowUtc();
    final existing = await PublicationConsent.db.findFirstRow(
      session,
      where: (t) => t.publicationId.equals(p.id!) & t.userId.equals(userId),
    );
    if (existing == null) {
      await PublicationConsent.db.insertRow(
        session,
        PublicationConsent(
          publicationId: p.id!,
          userId: userId,
          consentKey: key,
          at: now,
        ),
      );
    } else if (existing.consentKey != key) {
      await PublicationConsent.db.updateRow(
        session,
        existing.copyWith(consentKey: key, at: now),
        columns: (t) => [t.consentKey, t.at],
      );
    }
  }

  /// The users who may edit [item]: its owner and Editor grants.
  static Future<Set<int>> editorsOf(Session session, DriveItem item) async {
    final grants = await DriveItemPermission.db.find(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          t.userId.notEquals(null) &
          t.role.inSet({AccessRole.editor, AccessRole.owner}),
    );
    return {item.ownerId, for (final g in grants) g.userId!};
  }

  /// Per user and publication: stories started and submits per day
  /// (specs/18 §10).
  static final startLimiter = RateLimiter(
    name: 'publications.start',
    limit: PublicationRules.startsPerDay,
    window: const Duration(days: 1),
  );
  static final submitLimiter = RateLimiter(
    name: 'publications.submit',
    limit: PublicationRules.submitsPerDay,
    window: const Duration(days: 1),
  );

  /// Calls of the publication API per key (specs/18 §7.3).
  static final apiLimiter = RateLimiter(
    name: 'publications.api',
    limit: PublicationRules.apiCallsPerMinute,
  );

  static Future<void> checkLimit(
    RateLimiter limiter,
    Object key,
    String message,
  ) async {
    final retry = await limiter.check(key);
    if (retry != null) {
      throw Errors.limit(
        message,
        detailsJson: jsonEncode({'retryAfterSeconds': retry.inSeconds + 1}),
      );
    }
  }
}
