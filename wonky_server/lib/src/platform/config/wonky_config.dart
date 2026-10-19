import 'dart:io';

import 'package:serverpod/serverpod.dart';

import 'wonky_config_file.dart';

/// Wonky Work settings from the `wonky:` section of `config/<runMode>.yaml`
/// (specs/01-architecture.md §6). Serverpod ignores the section; this class
/// reads it. Environment variables `WONKY_<SECTION>_<KEY>` override values,
/// e.g. `WONKY_FEATURES_AI=false`.
class WonkyConfig {
  WonkyConfig({
    this.aiEnabled = true,
    this.scriptingEnabled = false,
    this.mcpUiBridgeEnabled = true,
    this.experimentalCharts = false,
    this.maxCellsPerSpreadsheet = 1000000,
    this.maxSheetsPerSpreadsheet = 200,
    this.scriptTimeoutMs = 30000,
    this.scriptDailyQuotaMs = 5400000,
    this.scriptServerTimeoutMs = 360000,
    this.scriptAllowHttp = false,
    this.scriptPoolSize = 4,
    this.scriptWorker = true,
    this.scriptUserConcurrency = 10,
    this.snapshotEveryNOps = 500,
    this.maxDocumentChars = 2000000,
    this.maxImageUploadBytes = 20 * 1024 * 1024,
    this.maxImportUploadBytes = 100 * 1024 * 1024,
    this.maxFileUploadBytes = defaultQuotaBytes,
    this.quotaBytesPerUser = defaultQuotaBytes,
    this.warnAtPercent = 90,
    this.maxPendingUploadsPerUser = 100,
    this.uploadsPerHour = 200,
    this.uploadBytesPerDay = 500 * 1024 * 1024,
    this.downloadBytesPerDay = 2 * 1024 * 1024 * 1024,
    this.minClientVersion = '3.0.0',
    this.serverVersion = '3.0.0',
    this.publicWebUrl,
    this.publicApiUrl,
    this.busFlushMs = 1000,
  });

  /// The public origin of the web apps in production (`wonky.work`).
  /// Serverpod Cloud generates the server config with its own hosts, and
  /// `config/*.yaml` is not uploaded (`.scloudignore`), so production
  /// defaults to this in code.
  static const productionWebUrl = 'https://wonky.work';

  /// The public URL of the API in production (`api.wonky.work`, a custom
  /// domain on Serverpod Cloud). It is on the same site as
  /// [productionWebUrl], which cookie auth needs: a `SameSite=Lax` refresh
  /// cookie is not sent from `wonky.work` to the generated
  /// `*.api.serverpod.space` host (specs/01-architecture.md §2.5).
  static const productionApiUrl = 'https://api.wonky.work';

  final bool aiEnabled;
  final bool scriptingEnabled;
  final bool mcpUiBridgeEnabled;
  final bool experimentalCharts;
  final int maxCellsPerSpreadsheet;
  final int maxSheetsPerSpreadsheet;

  /// Time limit of client script runs (menus, macros, editor; Sheets 09 §10).
  final int scriptTimeoutMs;

  /// Daily server script runtime per user.
  final int scriptDailyQuotaMs;

  /// Time limit of server script runs (triggers, MCP, Run on server).
  final int scriptServerTimeoutMs;

  /// Whether `UrlFetchApp` may use plain `http` (Sheets 09 §8.3 rule 1).
  final bool scriptAllowHttp;

  /// Sandbox isolates per server instance (Sheets 09 §8.8 `poolSize`).
  final int scriptPoolSize;

  /// Whether this instance runs queued server script jobs (the worker
  /// role, Sheets 09 §8.5 `sheets.scriptWorker`). Instances without it only
  /// enqueue.
  final bool scriptWorker;

  /// Server script jobs of one user running at once (Sheets 09 §10).
  final int scriptUserConcurrency;
  final int snapshotEveryNOps;
  final int maxDocumentChars;
  final int maxImageUploadBytes;
  final int maxImportUploadBytes;

  /// (v2) 50 MB: the default quota and the cap for one uploaded file
  /// (Drive 03 §1).
  static const defaultQuotaBytes = 50 * 1024 * 1024;

  /// (v2) Cap for one uploaded Drive file (`files.maxFileUploadBytes`,
  /// ≤ the quota; Drive 03 §3).
  final int maxFileUploadBytes;

  /// (v2) Storage quota per user (`drive.quotaBytesPerUser`, env
  /// `WONKY_DRIVE_QUOTA_BYTES_PER_USER`; Drive 03 §3). `UserStorage.
  /// quotaBytesOverride` overrides it per user.
  final int quotaBytesPerUser;

  /// (v2) Banner threshold in percent of the quota (`drive.warnAtPercent`).
  final int warnAtPercent;

  /// (v2) Open upload reservations per user (`drive.maxPendingUploadsPerUser`,
  /// Drive 03 §5).
  final int maxPendingUploadsPerUser;

  /// (v2) Upload rate limits (`files.uploadsPerHour`,
  /// `files.uploadBytesPerDay`; suite 13 §6).
  final int uploadsPerHour;
  final int uploadBytesPerDay;

  /// (v2) Download traffic per user and day (`files.downloadBytesPerDay`,
  /// suite 13 §6: 2 GB), counted per instance.
  final int downloadBytesPerDay;
  final String minClientVersion;
  final String serverVersion;

  /// The origin users reach the apps on (`publicWebUrl` / env
  /// `WONKY_PUBLIC_WEB_URL`), when it differs from the web server's
  /// configured public host. Used for every public link: the apps' config,
  /// emails, MCP links, the legal pages and the Google sign-in redirect.
  final String? publicWebUrl;

  /// The URL the apps call the API on (`publicApiUrl` / env
  /// `WONKY_PUBLIC_API_URL`), when it differs from the API server's
  /// configured public host (Serverpod Cloud generates that one).
  final String? publicApiUrl;

  /// How long bus messages wait before they are relayed to the other
  /// instances in one Redis publish (`cluster.busFlushMs`, specs/13 §4).
  final int busFlushMs;

  /// [publicWebUrl] or, without it, the web server's public URL in
  /// [config].
  Uri webOrigin(ServerpodConfig config) {
    final url = publicWebUrl;
    if (url != null && url.isNotEmpty) return Uri.parse(url).resolve('/');
    final server = config.webServer ?? config.apiServer;
    return Uri(
      scheme: server.publicScheme,
      host: server.publicHost,
      port: server.publicPort,
    ).resolve('/');
  }

  /// [publicApiUrl] or, without it, the API server's public URL in
  /// [config].
  Uri apiUrl(ServerpodConfig config) {
    final url = publicApiUrl;
    if (url != null && url.isNotEmpty) return Uri.parse(url);
    final server = config.apiServer;
    return Uri(
      scheme: server.publicScheme,
      host: server.publicHost,
      port: server.publicPort,
    );
  }

  static WonkyConfig? _current;

  /// The configuration of the running server, loaded on first use from the
  /// config file of [Serverpod.instance]'s run mode.
  static WonkyConfig get current => _current ??= _loadForRunningServer();

  /// Replaces the current configuration (tests).
  static set current(WonkyConfig config) => _current = config;

  static WonkyConfig _loadForRunningServer() => load(WonkyConfigFile.runMode());

  /// Loads the configuration for [runMode] from `config/<runMode>.yaml`
  /// relative to [directory] (default: the working directory).
  static WonkyConfig load(String runMode, {Directory? directory}) {
    return fromMap(
      WonkyConfigFile.wonky(runMode: runMode, directory: directory),
      environment: Platform.environment,
      defaultPublicWebUrl: runMode == ServerpodRunMode.production
          ? productionWebUrl
          : null,
      defaultPublicApiUrl: runMode == ServerpodRunMode.production
          ? productionApiUrl
          : null,
    );
  }

  /// Builds a configuration from the `wonky:` [map], applying [environment]
  /// overrides.
  static WonkyConfig fromMap(
    Map<dynamic, dynamic> map, {
    Map<String, String> environment = const {},
    String? defaultPublicWebUrl,
    String? defaultPublicApiUrl,
  }) {
    Object? read(String section, String key) {
      final envKey = 'WONKY_${section.toUpperCase()}_${_snake(key)}';
      final env = environment[envKey];
      if (env != null) return env;
      final s = section.isEmpty ? map : map[section];
      return s is Map ? s[key] : null;
    }

    bool b(String section, String key, bool fallback) {
      final v = read(section, key);
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return fallback;
    }

    int i(String section, String key, int fallback) {
      final v = read(section, key);
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    String s(String key, String fallback) {
      final env = environment['WONKY_${_snake(key)}'];
      if (env != null) return env;
      final v = map[key];
      return v == null ? fallback : '$v';
    }

    return WonkyConfig(
      aiEnabled: b('features', 'ai', true),
      scriptingEnabled: b('features', 'scripting', false),
      mcpUiBridgeEnabled: b('features', 'mcpUiBridge', true),
      experimentalCharts: b('features', 'experimentalCharts', false),
      maxCellsPerSpreadsheet: i('sheets', 'maxCellsPerSpreadsheet', 1000000),
      maxSheetsPerSpreadsheet: i('sheets', 'maxSheetsPerSpreadsheet', 200),
      scriptTimeoutMs: i('sheets', 'scriptTimeoutMs', 30000),
      scriptDailyQuotaMs: i('sheets', 'scriptDailyQuotaMs', 5400000),
      scriptServerTimeoutMs: i('sheets', 'scriptServerTimeoutMs', 360000),
      scriptAllowHttp: b('sheets', 'scriptAllowHttp', false),
      scriptPoolSize: i('sheets', 'scriptPoolSize', 4),
      scriptWorker: b('sheets', 'scriptWorker', true),
      scriptUserConcurrency: i('sheets', 'scriptUserConcurrency', 10),
      snapshotEveryNOps: i('write', 'snapshotEveryNOps', 500),
      maxDocumentChars: i('write', 'maxDocumentChars', 2000000),
      maxImageUploadBytes: i('files', 'maxImageUploadBytes', 20 * 1024 * 1024),
      maxImportUploadBytes: i(
        'files',
        'maxImportUploadBytes',
        100 * 1024 * 1024,
      ),
      maxFileUploadBytes: i('files', 'maxFileUploadBytes', defaultQuotaBytes),
      quotaBytesPerUser: i('drive', 'quotaBytesPerUser', defaultQuotaBytes),
      warnAtPercent: i('drive', 'warnAtPercent', 90),
      maxPendingUploadsPerUser: i('drive', 'maxPendingUploadsPerUser', 100),
      uploadsPerHour: i('files', 'uploadsPerHour', 200),
      uploadBytesPerDay: i('files', 'uploadBytesPerDay', 500 * 1024 * 1024),
      downloadBytesPerDay: i(
        'files',
        'downloadBytesPerDay',
        2 * 1024 * 1024 * 1024,
      ),
      minClientVersion: s('minClientVersion', '3.0.0'),
      serverVersion: s('serverVersion', '3.0.0'),
      busFlushMs: i('cluster', 'busFlushMs', 1000),
      publicWebUrl:
          environment['WONKY_PUBLIC_WEB_URL'] ??
          (map['publicWebUrl'] as String?) ??
          defaultPublicWebUrl,
      publicApiUrl:
          environment['WONKY_PUBLIC_API_URL'] ??
          (map['publicApiUrl'] as String?) ??
          defaultPublicApiUrl,
    );
  }

  static String _snake(String key) =>
      key.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();
}
