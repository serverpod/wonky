import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../config/wonky_config.dart';
import '../config/wonky_config_file.dart';

/// Settings of the `/mcp` endpoint from the `wonky: mcp:` section of
/// `config/<runMode>.yaml` (suite 09 §1–2):
///
/// ```yaml
/// wonky:
///   mcp:
///     enabled: true
///     allowedHosts: [localhost, 127.0.0.1]
///     allowedOrigins: [http://localhost:8082]
///     rateLimitPerMinute: 600
///     sessionIdleMinutes: 60
/// ```
///
/// Hosts default to the web and API servers' public hosts plus loopback;
/// origins default to Serverpod's `allowedOrigins`. Requests without an
/// `Origin` header (non-browser MCP clients) are always allowed; requests
/// with one must match (DNS-rebinding / CSRF protection, suite 13).
class McpConfig {
  McpConfig({
    this.enabled = true,
    Set<String>? allowedHosts,
    Set<String>? allowedOrigins,
    this.rateLimitPerMinute = 600,
    this.sessionIdle = const Duration(minutes: 60),
  }) : allowedHosts = allowedHosts ?? const {'localhost', '127.0.0.1', '::1'},
       allowedOrigins = allowedOrigins ?? const {};

  final bool enabled;

  /// Accepted `Host` header values (host names, without port).
  final Set<String> allowedHosts;

  /// Accepted `Origin` header values (`scheme://host[:port]`).
  final Set<String> allowedOrigins;
  final int rateLimitPerMinute;

  /// Legacy (`Mcp-Session-Id`) sessions expire after this idle time.
  final Duration sessionIdle;

  static McpConfig? _current;

  static McpConfig get current => _current ??= _load();

  /// Replaces the configuration (tests).
  static set current(McpConfig config) => _current = config;

  /// The hosts `/mcp` answers on without an `allowedHosts` list: loopback,
  /// the configured web and API servers and the public origins users reach
  /// (`WonkyConfig.webOrigin`/`apiUrl`: `wonky.work` and `api.wonky.work` in
  /// production, where Serverpod Cloud's generated config names only its
  /// own `*.serverpod.space` hosts).
  static Set<String> defaultAllowedHosts(
    ServerpodConfig? config,
    WonkyConfig wonky,
  ) => {
    'localhost',
    '127.0.0.1',
    '::1',
    if (config?.webServer?.publicHost case final h?) h.toLowerCase(),
    if (config != null) ...[
      config.apiServer.publicHost.toLowerCase(),
      wonky.webOrigin(config).host.toLowerCase(),
      wonky.apiUrl(config).host.toLowerCase(),
    ],
  };

  static McpConfig _load() {
    final section = WonkyConfigFile.section('mcp');
    ServerpodConfig? config;
    try {
      config = Serverpod.instance.config;
    } on StateError {
      // No server (unit tests, tools).
    }
    Set<String>? strings(Object? v) =>
        v is List ? {for (final e in v) '$e'.toLowerCase()} : null;
    final hosts =
        strings(section['allowedHosts']) ??
        defaultAllowedHosts(config, WonkyConfig.current);
    final origins =
        strings(section['allowedOrigins']) ??
        {
          for (final o in config?.allowedOrigins ?? const [])
            '$o'.toLowerCase(),
        };
    final env = Platform.environment;
    return McpConfig(
      enabled:
          (env['WONKY_MCP_ENABLED'] ?? '${section['enabled'] ?? true}') ==
          'true',
      allowedHosts: hosts,
      allowedOrigins: origins,
      rateLimitPerMinute: section['rateLimitPerMinute'] is int
          ? section['rateLimitPerMinute'] as int
          : 600,
      sessionIdle: Duration(
        minutes: section['sessionIdleMinutes'] is int
            ? section['sessionIdleMinutes'] as int
            : 60,
      ),
    );
  }

  /// Whether the `Host` header [hostHeader] (`name[:port]`) is accepted.
  bool hostAllowed(String? hostHeader) {
    if (hostHeader == null || hostHeader.isEmpty) return false;
    var host = hostHeader.trim().toLowerCase();
    if (host.startsWith('[')) {
      final end = host.indexOf(']');
      host = end < 0 ? host : host.substring(1, end);
    } else {
      final colon = host.lastIndexOf(':');
      if (colon > 0) host = host.substring(0, colon);
    }
    return allowedHosts.contains(host);
  }

  /// Whether [origin] is accepted (null = no Origin header = allowed).
  bool originAllowed(String? origin) {
    if (origin == null || origin.isEmpty) return true;
    final o = origin.trim().toLowerCase().replaceAll(RegExp(r'/+$'), '');
    return allowedOrigins.contains(o);
  }
}
