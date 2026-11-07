import 'dart:io';

import '../config/wonky_config_file.dart';
import 'public_mail_domains.dart';

/// Settings of organizations from the `wonky: organizations:` section of
/// `config/<runMode>.yaml` (specs/04 §6). The defaults are the production
/// values (Serverpod Cloud does not upload `config/*.yaml`): organizations on,
/// no extra public domains and no aliases.
///
/// ```yaml
/// wonky:
///   organizations:
///     enabled: true
///     # Added to the built-in list of public mail providers: these
///     # domains never form an organization.
///     publicDomains: [mail.example]
///     # Domains of one organization; the first one is its name.
///     aliases:
///       - [acme.dev, acme.com]
/// ```
///
/// Environment overrides: `WONKY_ORGANIZATIONS_ENABLED=false`,
/// `WONKY_ORGANIZATIONS_PUBLIC_DOMAINS=a.com,b.net` and
/// `WONKY_ORGANIZATIONS_ALIASES=acme.dev,acme.com;x.io,x.com`
/// (groups separated by `;`, domains by `,`).
class OrganizationConfig {
  OrganizationConfig({
    this.enabled = true,
    Set<String> publicDomains = const {},
    List<List<String>> aliases = const [],
  }) : publicDomains = {for (final d in publicDomains) d.trim().toLowerCase()},
       _groupOf = _groups(aliases);

  /// Without it no one has an organization (sharing with an organization
  /// and organization search are off).
  final bool enabled;

  /// Extra public domains on top of [PublicMailDomains].
  final Set<String> publicDomains;

  /// Each aliased domain → its group (first domain = the organization key).
  final Map<String, List<String>> _groupOf;

  /// The domains of the alias group of [domain] (just [domain] when it has
  /// no aliases), the key first.
  List<String> domainsOf(String domain) => _groupOf[domain] ?? [domain];

  static Map<String, List<String>> _groups(List<List<String>> aliases) {
    final result = <String, List<String>>{};
    for (final group in aliases) {
      final domains = <String>[
        for (final d in group)
          if (d.trim().isNotEmpty) d.trim().toLowerCase(),
      ];
      if (domains.length < 2) continue;
      // A domain listed in two groups joins the first one.
      final fresh = [
        for (final d in domains)
          if (!result.containsKey(d)) d,
      ];
      for (final d in fresh) {
        result[d] = fresh;
      }
    }
    return result;
  }

  static OrganizationConfig? _current;

  static OrganizationConfig get current => _current ??= _load();

  /// Replaces the configuration (tests).
  static set current(OrganizationConfig config) => _current = config;

  /// Back to the configuration of the config file (tests).
  static void reset() => _current = null;

  static OrganizationConfig _load() => fromMap(
    WonkyConfigFile.section('organizations'),
    environment: Platform.environment,
  );

  /// Builds a configuration from the `organizations:` [map] with
  /// [environment] overrides.
  static OrganizationConfig fromMap(
    Map<dynamic, dynamic> map, {
    Map<String, String> environment = const {},
  }) {
    const prefix = 'WONKY_ORGANIZATIONS_';
    final enabledEnv = environment['${prefix}ENABLED'];
    final enabledRaw = map['enabled'];
    final enabled = enabledEnv != null
        ? enabledEnv.toLowerCase() == 'true'
        : (enabledRaw is bool ? enabledRaw : true);

    final publicEnv = environment['${prefix}PUBLIC_DOMAINS'];
    final publicRaw = map['publicDomains'];
    final publicDomains = publicEnv != null
        ? publicEnv.split(',').toSet()
        : (publicRaw is List ? {for (final d in publicRaw) '$d'} : <String>{});

    final aliasEnv = environment['${prefix}ALIASES'];
    final aliasRaw = map['aliases'];
    final List<List<String>> aliases;
    if (aliasEnv != null) {
      aliases = [
        for (final group in aliasEnv.split(';'))
          [for (final d in group.split(',')) d],
      ];
    } else if (aliasRaw is List) {
      aliases = [
        for (final group in aliasRaw)
          if (group is List) [for (final d in group) '$d'],
      ];
    } else {
      aliases = const [];
    }
    return OrganizationConfig(
      enabled: enabled,
      publicDomains: publicDomains,
      aliases: aliases,
    );
  }

  /// Whether [domain] never forms an organization: a public mail provider
  /// (built in or configured) or a reserved name.
  bool isPublic(String domain) =>
      publicDomains.contains(domain) || PublicMailDomains.isPublic(domain);
}
