import 'package:serverpod/serverpod.dart';

import '../common/lru_map.dart';
import '../common/models.dart';
import 'organization_config.dart';

/// An organization: the users whose verified email is in one of [domains]
/// (specs/04 §6). Never stored: it follows from the email and the
/// configuration at every request.
class Organization {
  Organization(this.domains) : assert(domains.isNotEmpty);

  /// The domains of the organization, its [key] first.
  final List<String> domains;

  /// The organization's stable key and name: its first domain
  /// (`serverpod.dev`). Stored on organization grants (`orgKey`).
  String get key => domains.first;

  /// Whether [domain] belongs to the organization.
  bool contains(String domain) => domains.contains(domain);

  /// [domains] as an SQL list of string literals (`'a.dev', 'a.com'`).
  /// Safe to inline: every domain matched `[a-z0-9.-]+` (checked by
  /// [OrganizationService.forEmail]).
  String get sqlList => domains.map((d) => "'$d'").join(', ');

  @override
  bool operator ==(Object other) => other is Organization && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'Organization($key)';
}

/// Which organization a user is in (specs/04 §6): users whose verified
/// email has the same domain are one organization, unless the domain is a
/// public mail provider ([OrganizationConfig.isPublic]); configured alias
/// groups merge domains into one organization.
///
/// The profile email is verified: email/password accounts exist only after
/// the verification code, Google sign-in requires Google's verified email,
/// and there is no email-change endpoint (the same reasoning as the board
/// admins, specs/16 §9.1; guarded by a server test). Profiles created
/// without an email get `<uuid>@users.invalid`, a reserved name without an
/// organization.
///
/// Other features (sharing with an organization, people search, the
/// assistant's organization style guides) ask this service; nothing else
/// derives organizations from emails.
abstract final class OrganizationService {
  /// Profile emails by user id (bounded; an email never changes).
  static final LruMap<int, String> _emailByUser = LruMap(100000);

  /// Forgets cached emails (tests, account deletion).
  static void forget([int? userId]) {
    if (userId == null) {
      _emailByUser.clear();
    } else {
      _emailByUser.remove(userId);
    }
  }

  /// The domain of [email] (lowercase), or null without one.
  static String? domainOf(String email) {
    final e = email.trim().toLowerCase();
    final at = e.lastIndexOf('@');
    if (at <= 0 || at == e.length - 1) return null;
    return e.substring(at + 1);
  }

  /// The organization of a user with [email] under [config] (default: the
  /// current configuration), or null for public and reserved domains.
  static Organization? forEmail(String email, [OrganizationConfig? config]) {
    final c = config ?? OrganizationConfig.current;
    if (!c.enabled) return null;
    final domain = domainOf(email);
    if (domain == null || c.isPublic(domain)) return null;
    final domains = [
      for (final d in c.domainsOf(domain))
        if (!c.isPublic(d)) d,
    ];
    return domains.isEmpty ? null : Organization(domains);
  }

  /// The organization of the stored org key [key] (an organization grant),
  /// under the current configuration: null when the domain became public
  /// or organizations are off.
  static Organization? forKey(String key) => forEmail('x@$key');

  /// The organization of the profile [userId], or null (no organization,
  /// unknown user, or the signed-out viewer, id 0).
  static Future<Organization?> orgOf(Session session, int userId) async {
    if (userId <= 0) return null;
    if (!OrganizationConfig.current.enabled) return null;
    var email = _emailByUser.get(userId);
    if (email == null) {
      final profile = await UserProfile.db.findById(session, userId);
      if (profile == null) return null;
      email = profile.email;
      _emailByUser.put(userId, email);
    }
    return forEmail(email);
  }

  /// The org key of [userId] (see [Organization.key]), or null.
  static Future<String?> orgKeyOf(Session session, int userId) async =>
      (await orgOf(session, userId))?.key;

  /// Whether [a] and [b] are in the same organization.
  static Future<bool> sameOrganization(Session session, int a, int b) async {
    final org = await orgOf(session, a);
    return org != null && org == await orgOf(session, b);
  }

  /// The ids among [userIds] that are in [org] (one query).
  static Future<Set<int>> membersAmong(
    Session session,
    Organization org,
    Iterable<int> userIds,
  ) async {
    final ids = userIds.toSet();
    if (ids.isEmpty) return const {};
    final profiles = await UserProfile.db.find(
      session,
      where: (t) => t.id.inSet(ids),
    );
    return {
      for (final p in profiles)
        if (forEmail(p.email) == org) p.id!,
    };
  }

  /// An SQL condition: the email column [emailColumn] (lowercase emails) is
  /// at one of [org]'s domains.
  static String sqlMemberCondition(String emailColumn, Organization org) =>
      "split_part($emailColumn, '@', 2) IN (${org.sqlList})";
}
