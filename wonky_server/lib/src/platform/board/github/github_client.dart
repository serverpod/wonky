// Named parameters can't initialize private fields directly.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../common/time.dart';
import 'github_app_auth.dart';

/// A pull request as the review reads it.
class GithubPullRequest {
  const GithubPullRequest({
    required this.number,
    required this.title,
    required this.body,
    required this.headSha,
    required this.state,
    required this.authorLogin,
    this.draft = false,
    this.merged = false,
  });

  final int number;
  final String title;
  final String body;
  final String headSha;

  /// `open` or `closed`.
  final String state;
  final String authorLogin;
  final bool draft;
  final bool merged;
}

/// A changed file of a pull request (`GET /pulls/{n}/files`).
class GithubPrFile {
  const GithubPrFile({
    required this.path,
    required this.status,
    this.additions = 0,
    this.deletions = 0,
    this.patch,
    this.previousPath,
  });

  final String path;

  /// `added`, `removed`, `modified`, `renamed`, `copied`, `changed`,
  /// `unchanged`.
  final String status;
  final int additions;
  final int deletions;

  /// The unified diff hunk; null for binary or very large files.
  final String? patch;
  final String? previousPath;
}

/// The calls the board makes on GitHub (specs/16 §13.3), all on the
/// repository `board.repository` with the App's installation token.
/// [GithubClient] is the REST implementation; tests use a fake.
abstract class GithubApi {
  /// Creates a check run; returns its id.
  Future<int> createCheckRun({
    required String name,
    required String headSha,
    required String status,
    String? conclusion,
    required String title,
    required String summary,
    String? detailsUrl,
  });

  Future<void> updateCheckRun(
    int id, {
    required String status,
    String? conclusion,
    required String title,
    required String summary,
  });

  /// Creates an issue (PR) comment; returns its id.
  Future<int> createComment(int issue, String body);

  /// Updates comment [id]; false when the comment no longer exists.
  Future<bool> updateComment(int id, String body);

  /// The id of a comment on [issue] written by a bot that contains
  /// [marker] (the first page of comments), or null.
  Future<int?> findBotComment(int issue, String marker);

  Future<void> addLabels(int issue, List<String> labels);

  /// Removes [label]; a label that is not set is fine.
  Future<void> removeLabel(int issue, String label);

  Future<void> closePullRequest(int number);

  Future<GithubPullRequest> getPullRequest(int number);

  /// Up to 3000 changed files (GitHub's limit).
  Future<List<GithubPrFile>> listPullRequestFiles(int number);

  /// The unified diff of the pull request.
  Future<String> getPullRequestDiff(int number);

  /// `ahead`, `identical`, `behind` or `diverged`: how [head] relates to
  /// [base] (`GET /compare/{base}...{head}`).
  Future<String> compareStatus(String base, String head);

  /// Whether [login] is a member of [org] (`GET /orgs/{org}/members/
  /// {login}`: 204 member, 404 not). Needs the App permission
  /// *Organization → Members: read*.
  Future<bool> isOrgMember(String org, String login);
}

/// A failed GitHub call. Carries the method, the path and GitHub's
/// `message`, never a token or header.
class GithubApiException implements Exception {
  GithubApiException(this.statusCode, this.method, this.path, this.message);

  final int statusCode;
  final String method;
  final String path;
  final String message;

  bool get isNotFound => statusCode == 404;

  @override
  String toString() =>
      'GithubApiException($statusCode $method $path: $message)';
}

/// GitHub's rate limit held for longer than the client waits.
class GithubRateLimitException extends GithubApiException {
  GithubRateLimitException(
    int statusCode,
    String method,
    String path,
    this.retryAfter,
  ) : super(
        statusCode,
        method,
        path,
        'rate limited, retry in ${retryAfter.inSeconds} s',
      );

  final Duration retryAfter;
}

/// Credentials of the GitHub App: its id and the signer of the App JWT.
class GithubAppCredentials {
  const GithubAppCredentials({required this.repository, required this.jwt});

  /// `owner/name`.
  final String repository;
  final GithubAppJwt jwt;
}

/// The REST client of the board's GitHub App (specs/16 §13.3): App JWT →
/// installation token (cached for 50 minutes), then plain REST calls.
///
/// Rate limits: a `403`/`429` with `retry-after`, or with
/// `x-ratelimit-remaining: 0` and `x-ratelimit-reset`, is retried after
/// the wait when it is at most [maxWait] (two retries); otherwise a
/// [GithubRateLimitException] is thrown. Tokens and the key are never
/// logged or put into exceptions.
class GithubClient implements GithubApi {
  GithubClient({
    required GithubAppCredentials Function() credentials,
    http.Client? httpClient,
    Future<void> Function(Duration)? sleep,
    this.apiBase = 'https://api.github.com',
    this.maxWait = const Duration(seconds: 60),
    this.log,
  }) : _credentials = credentials,
       _http = httpClient ?? http.Client(),
       _sleep = sleep ?? ((d) => Future<void>.delayed(d));

  final GithubAppCredentials Function() _credentials;
  final http.Client _http;
  final Future<void> Function(Duration) _sleep;
  final String apiBase;
  final Duration maxWait;

  /// Diagnostics (rate-limit waits); never receives secrets.
  final void Function(String message)? log;

  static const tokenLifetime = Duration(minutes: 50);
  static const _maxRetries = 2;
  static const userAgent = 'wonky-work-bot';

  String? _token;
  DateTime? _tokenAt;
  String? _tokenRepo;

  /// Forgets the cached installation token (tests, key rotation).
  void resetToken() {
    _token = null;
    _tokenAt = null;
    _tokenRepo = null;
  }

  String get _repo => _credentials().repository;

  // ------------------------------------------------------------- auth

  Future<String> _installationToken() async {
    final creds = _credentials();
    final now = nowUtc();
    final cached = _token;
    if (cached != null &&
        _tokenRepo == creds.repository &&
        now.difference(_tokenAt!) < tokenLifetime) {
      return cached;
    }
    final jwt = creds.jwt.sign(now);
    final install = await _send(
      'GET',
      '/repos/${creds.repository}/installation',
      bearer: jwt,
    );
    final installJson = _json(install);
    final installationId = installJson is Map ? installJson['id'] : null;
    if (installationId is! int) {
      throw GithubApiException(
        install.statusCode,
        'GET',
        '/repos/${creds.repository}/installation',
        'the App is not installed on the repository',
      );
    }
    final tokenResponse = await _send(
      'POST',
      '/app/installations/$installationId/access_tokens',
      bearer: jwt,
    );
    final tokenJson = _json(tokenResponse);
    final token = tokenJson is Map ? tokenJson['token'] : null;
    if (token is! String || token.isEmpty) {
      throw GithubApiException(
        tokenResponse.statusCode,
        'POST',
        '/app/installations/$installationId/access_tokens',
        'no token in the response',
      );
    }
    _token = token;
    _tokenAt = now;
    _tokenRepo = creds.repository;
    return token;
  }

  // ------------------------------------------------------------- calls

  @override
  Future<int> createCheckRun({
    required String name,
    required String headSha,
    required String status,
    String? conclusion,
    required String title,
    required String summary,
    String? detailsUrl,
  }) async {
    final r = await _call(
      'POST',
      '/repos/$_repo/check-runs',
      body: {
        'name': name,
        'head_sha': headSha,
        'status': status,
        'conclusion': ?conclusion,
        'details_url': ?detailsUrl,
        if (status == 'completed') 'completed_at': nowUtc().toIso8601String(),
        'output': {'title': title, 'summary': _clip(summary, 65000)},
      },
    );
    return _id(r);
  }

  @override
  Future<void> updateCheckRun(
    int id, {
    required String status,
    String? conclusion,
    required String title,
    required String summary,
  }) => _call(
    'PATCH',
    '/repos/$_repo/check-runs/$id',
    body: {
      'status': status,
      'conclusion': ?conclusion,
      if (status == 'completed') 'completed_at': nowUtc().toIso8601String(),
      'output': {'title': title, 'summary': _clip(summary, 65000)},
    },
  );

  @override
  Future<int> createComment(int issue, String body) async => _id(
    await _call(
      'POST',
      '/repos/$_repo/issues/$issue/comments',
      body: {'body': _clip(body, 65000)},
    ),
  );

  @override
  Future<bool> updateComment(int id, String body) async {
    try {
      await _call(
        'PATCH',
        '/repos/$_repo/issues/comments/$id',
        body: {'body': _clip(body, 65000)},
      );
      return true;
    } on GithubApiException catch (e) {
      if (e.isNotFound) return false;
      rethrow;
    }
  }

  @override
  Future<int?> findBotComment(int issue, String marker) async {
    final r = await _call(
      'GET',
      '/repos/$_repo/issues/$issue/comments?per_page=100',
    );
    final list = _json(r);
    if (list is! List) return null;
    for (final c in list) {
      if (c is! Map) continue;
      final user = c['user'];
      final isBot = user is Map && user['type'] == 'Bot';
      final body = c['body'];
      if (isBot && body is String && body.contains(marker)) {
        return c['id'] as int?;
      }
    }
    return null;
  }

  @override
  Future<void> addLabels(int issue, List<String> labels) => _call(
    'POST',
    '/repos/$_repo/issues/$issue/labels',
    body: {'labels': labels},
  );

  @override
  Future<void> removeLabel(int issue, String label) async {
    try {
      await _call(
        'DELETE',
        '/repos/$_repo/issues/$issue/labels/${Uri.encodeComponent(label)}',
      );
    } on GithubApiException catch (e) {
      if (!e.isNotFound) rethrow;
    }
  }

  @override
  Future<void> closePullRequest(int number) => _call(
    'PATCH',
    '/repos/$_repo/pulls/$number',
    body: {'state': 'closed'},
  );

  @override
  Future<GithubPullRequest> getPullRequest(int number) async {
    final j = _json(await _call('GET', '/repos/$_repo/pulls/$number')) as Map;
    final head = j['head'] is Map
        ? j['head'] as Map
        : const <Object?, Object?>{};
    final user = j['user'] is Map
        ? j['user'] as Map
        : const <Object?, Object?>{};
    return GithubPullRequest(
      number: number,
      title: '${j['title'] ?? ''}',
      body: j['body'] is String ? j['body'] as String : '',
      headSha: '${head['sha'] ?? ''}',
      state: '${j['state'] ?? 'open'}',
      authorLogin: '${user['login'] ?? ''}',
      draft: j['draft'] == true,
      merged: j['merged'] == true,
    );
  }

  @override
  Future<List<GithubPrFile>> listPullRequestFiles(int number) async {
    final files = <GithubPrFile>[];
    for (var page = 1; page <= 30; page++) {
      final list = _json(
        await _call(
          'GET',
          '/repos/$_repo/pulls/$number/files?per_page=100&page=$page',
        ),
      );
      if (list is! List || list.isEmpty) break;
      for (final f in list) {
        if (f is! Map) continue;
        files.add(
          GithubPrFile(
            path: '${f['filename']}',
            status: '${f['status'] ?? 'modified'}',
            additions: (f['additions'] as num?)?.toInt() ?? 0,
            deletions: (f['deletions'] as num?)?.toInt() ?? 0,
            patch: f['patch'] as String?,
            previousPath: f['previous_filename'] as String?,
          ),
        );
      }
      if (list.length < 100) break;
    }
    return files;
  }

  @override
  Future<String> getPullRequestDiff(int number) async => (await _call(
    'GET',
    '/repos/$_repo/pulls/$number',
    accept: 'application/vnd.github.diff',
  )).body;

  @override
  Future<String> compareStatus(String base, String head) async {
    final j = _json(
      await _call(
        'GET',
        '/repos/$_repo/compare/${Uri.encodeComponent(base)}...'
            '${Uri.encodeComponent(head)}?per_page=1',
      ),
    );
    return j is Map ? '${j['status']}' : '';
  }

  @override
  Future<bool> isOrgMember(String org, String login) async {
    try {
      final r = await _call(
        'GET',
        '/orgs/${Uri.encodeComponent(org)}/members/'
            '${Uri.encodeComponent(login)}',
      );
      return r.statusCode == 204;
    } on GithubApiException catch (e) {
      if (e.isNotFound) return false;
      rethrow;
    }
  }

  // ---------------------------------------------------------- plumbing

  /// A call with the installation token; a `401` drops the cached token
  /// and retries once.
  Future<http.Response> _call(
    String method,
    String path, {
    Object? body,
    String accept = 'application/vnd.github+json',
  }) async {
    for (var attempt = 0; ; attempt++) {
      final token = await _installationToken();
      try {
        return await _send(
          method,
          path,
          bearer: token,
          body: body,
          accept: accept,
        );
      } on GithubApiException catch (e) {
        if (e.statusCode != 401 || attempt > 0) rethrow;
        resetToken();
      }
    }
  }

  Future<http.Response> _send(
    String method,
    String path, {
    required String bearer,
    Object? body,
    String accept = 'application/vnd.github+json',
  }) async {
    final uri = Uri.parse('$apiBase$path');
    final cleanPath = path.split('?').first;
    for (var attempt = 0; ; attempt++) {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Accept': accept,
          'Authorization': 'Bearer $bearer',
          'User-Agent': userAgent,
          'X-GitHub-Api-Version': '2022-11-28',
        });
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final http.Response response;
      try {
        response = await http.Response.fromStream(
          await _http.send(request).timeout(const Duration(seconds: 30)),
        ).timeout(const Duration(seconds: 60));
      } on TimeoutException {
        throw GithubApiException(0, method, cleanPath, 'timed out');
      } on http.ClientException catch (e) {
        throw GithubApiException(0, method, cleanPath, e.message);
      }
      final status = response.statusCode;
      if (status >= 200 && status < 300) return response;
      final wait = _rateLimitWait(response);
      if (wait != null) {
        if (attempt >= _maxRetries || wait > maxWait) {
          throw GithubRateLimitException(status, method, cleanPath, wait);
        }
        log?.call(
          'github: rate limited on $method $cleanPath, '
          'waiting ${wait.inSeconds} s',
        );
        await _sleep(wait);
        continue;
      }
      throw GithubApiException(
        status,
        method,
        cleanPath,
        _errorMessage(response),
      );
    }
  }

  /// How long to wait before retrying [r], or null when it is not a rate
  /// limit.
  static Duration? _rateLimitWait(http.Response r) {
    if (r.statusCode != 403 && r.statusCode != 429) return null;
    final retryAfter = int.tryParse(r.headers['retry-after'] ?? '');
    if (retryAfter != null) return Duration(seconds: retryAfter.clamp(0, 3600));
    if (r.headers['x-ratelimit-remaining'] == '0') {
      final reset = int.tryParse(r.headers['x-ratelimit-reset'] ?? '');
      if (reset == null) return const Duration(seconds: 60);
      final at = DateTime.fromMillisecondsSinceEpoch(reset * 1000, isUtc: true);
      final d = at.difference(nowUtc()) + const Duration(seconds: 1);
      return d.isNegative ? Duration.zero : d;
    }
    if (r.statusCode == 429) return const Duration(seconds: 60);
    return null;
  }

  static String _errorMessage(http.Response r) {
    try {
      final j = jsonDecode(r.body);
      if (j is Map && j['message'] is String) {
        return _clip(j['message'] as String, 300);
      }
    } on FormatException {
      // Not JSON.
    }
    return 'HTTP ${r.statusCode}';
  }

  static Object? _json(http.Response r) {
    if (r.body.isEmpty) return null;
    try {
      return jsonDecode(r.body);
    } on FormatException {
      return null;
    }
  }

  static int _id(http.Response r) {
    final j = _json(r);
    final id = j is Map ? j['id'] : null;
    if (id is! int) {
      throw GithubApiException(r.statusCode, 'POST', '', 'no id returned');
    }
    return id;
  }

  static String _clip(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max - 1)}…';
}
