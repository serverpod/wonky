// STOPGAP(org-sharing): organizations are built by the org-sharing work
// (`OrganizationService` in `platform/organizations/`). Until that lands,
// this file derives a user's organization the same way (the verified
// profile email's domain, no public mail providers). At merge, replace the
// body of [StyleGuideOrgs.orgKeyOf] with
// `OrganizationService.orgKeyOf(session, userId)` and delete
// [StyleGuideOrgs.publicDomains].
import 'package:serverpod/serverpod.dart';

import '../common/models.dart';

/// The organization of a user for style guides (suite 10 §7).
abstract final class StyleGuideOrgs {
  /// The org key of [userId] (the lowercase domain of the profile email),
  /// or null for public mail providers, reserved domains and unknown users.
  ///
  /// The profile email is verified: email/password accounts exist only
  /// after the verification code and Google sign-in requires Google's
  /// verified email.
  static Future<String?> orgKeyOf(Session session, int userId) async {
    final p = await UserProfile.db.findById(session, userId);
    if (p == null) return null;
    return orgKeyOfEmail(p.email);
  }

  /// The org key of [email], or null.
  static String? orgKeyOfEmail(String email) {
    final at = email.lastIndexOf('@');
    if (at < 0) return null;
    final domain = email.substring(at + 1).trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9.-]+\.[a-z]{2,}$').hasMatch(domain)) return null;
    if (domain.endsWith('.invalid') || domain.endsWith('.test')) return null;
    if (publicDomains.contains(domain)) return null;
    return domain;
  }

  /// Public mail providers (no organization).
  static const publicDomains = {
    'gmail.com',
    'googlemail.com',
    'outlook.com',
    'hotmail.com',
    'hotmail.co.uk',
    'live.com',
    'msn.com',
    'yahoo.com',
    'yahoo.co.uk',
    'ymail.com',
    'icloud.com',
    'me.com',
    'mac.com',
    'aol.com',
    'proton.me',
    'protonmail.com',
    'pm.me',
    'gmx.com',
    'gmx.de',
    'gmx.net',
    'web.de',
    'mail.com',
    'zoho.com',
    'yandex.com',
    'yandex.ru',
    'mail.ru',
    'qq.com',
    '163.com',
    '126.com',
    'hey.com',
    'fastmail.com',
    'tutanota.com',
    'example.com',
  };
}
