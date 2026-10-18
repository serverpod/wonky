import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';

import '../../../generated/future_calls.dart';
import '../../cluster/cluster.dart';
import '../../common/models.dart';
import '../../common/time.dart';
import '../board_config.dart';
import 'github_app_auth.dart';
import 'github_client.dart';
import 'github_gate.dart';
import 'github_lifecycle.dart';
import 'github_review.dart';

/// A pull request from a `pull_request` payload (or fetched for a check
/// re-run).
class GithubPrEvent {
  const GithubPrEvent({
    required this.number,
    required this.body,
    required this.author,
    required this.headSha,
    this.state = 'open',
    this.draft = false,
    this.merged = false,
    this.mergeCommitSha,
  });

  factory GithubPrEvent.fromCompact(Map<dynamic, dynamic> pr) => GithubPrEvent(
    number: pr['number'] as int,
    body: pr['body'] is String ? pr['body'] as String : '',
    author: '${pr['author'] ?? ''}',
    headSha: '${pr['headSha'] ?? ''}',
    state: '${pr['state'] ?? 'open'}',
    draft: pr['draft'] == true,
    merged: pr['merged'] == true,
    mergeCommitSha: pr['mergeCommitSha'] as String?,
  );

  factory GithubPrEvent.fromPullRequest(GithubPullRequest pr) => GithubPrEvent(
    number: pr.number,
    body: pr.body,
    author: pr.authorLogin,
    headSha: pr.headSha,
    state: pr.state,
    draft: pr.draft,
    merged: pr.merged,
  );

  final int number;
  final String body;
  final String author;
  final String headSha;
  final String state;
  final bool draft;
  final bool merged;
  final String? mergeCommitSha;
}

/// The GitHub integration of Bugs & improvements (specs/16 §13): the
/// handler of stored webhook deliveries, the API client, scheduling, and
/// the sweep part (auto-close, postponed reviews, delivery purge).
abstract final class BoardGithub {
  static const deliveryRetention = Duration(days: 7);
  static const maxAttempts = 3;

  /// The pull request actions that run the gate (specs/16 §13.4).
  static const gateActions = {
    'opened',
    'edited',
    'reopened',
    'synchronize',
    'ready_for_review',
  };

  // ------------------------------------------------------------------ API

  /// Replaces the GitHub API (tests).
  static GithubApi? apiOverride;
  static GithubClient? _client;
  static (int, String, GithubAppJwt)? _jwt;

  static GithubApi get api => apiOverride ?? (_client ??= _newClient());

  static GithubClient _newClient() => GithubClient(credentials: _credentials);

  static GithubAppCredentials _credentials() {
    final config = BoardConfig.current;
    final gh = config.github;
    String? pem;
    try {
      pem = Serverpod.instance.getPassword(
        BoardGithubConfig.privateKeyPassword,
      );
    } on Object {
      pem = null;
    }
    if (gh.appId <= 0 || pem == null || pem.trim().isEmpty) {
      throw GithubApiException(
        0,
        'AUTH',
        '',
        'the GitHub App is not configured (board.github.appId and the '
            'password ${BoardGithubConfig.privateKeyPassword})',
      );
    }
    // Keyed by a hash so the key itself is never kept twice.
    final keyHash = sha256.convert(utf8.encode(pem)).toString();
    final cached = _jwt;
    final GithubAppJwt jwt;
    if (cached != null && cached.$1 == gh.appId && cached.$2 == keyHash) {
      jwt = cached.$3;
    } else {
      jwt = GithubAppJwt.fromPem(gh.appId, pem);
      _jwt = (gh.appId, keyHash, jwt);
    }
    return GithubAppCredentials(repository: config.repository, jwt: jwt);
  }

  // ----------------------------------------------------------- scheduling

  /// Runs [BoardGithubFutureCall.handle] for a stored delivery; tests
  /// replace it to record or run inline.
  static Future<void> Function(
    Session session,
    String deliveryId,
    Duration delay,
  )
  deliveryScheduler = _deliveryViaFutureCall;

  /// Schedules [BoardGithubFutureCall.review] at [at] under one identifier
  /// per PR, cancelling the run it supersedes; tests replace it.
  static Future<void> Function(
    Session session,
    int prNumber,
    String headSha,
    DateTime at,
  )
  reviewScheduler = _reviewViaFutureCall;

  static Future<void> _deliveryViaFutureCall(
    Session session,
    String deliveryId,
    Duration delay,
  ) => session.serverpod.futureCalls
      .callWithDelay(delay)
      .boardGithub
      .handle(deliveryId);

  static String reviewCallId(int prNumber) => 'board.github.review.$prNumber';

  static Future<void> _reviewViaFutureCall(
    Session session,
    int prNumber,
    String headSha,
    DateTime at,
  ) async {
    final calls = session.serverpod.futureCalls;
    await calls.cancel(reviewCallId(prNumber));
    await calls
        .callAtTime(at, identifier: reviewCallId(prNumber))
        .boardGithub
        .review(prNumber, headSha);
  }

  /// Restores the defaults (tests).
  static void reset() {
    apiOverride = null;
    deliveryScheduler = _deliveryViaFutureCall;
    reviewScheduler = _reviewViaFutureCall;
  }

  // ------------------------------------------------------------- handler

  /// Handles stored delivery [deliveryId] once. Errors are retried
  /// ([maxAttempts] runs, a minute apart and growing), then dropped.
  static Future<void> handleDelivery(Session session, String deliveryId) async {
    final row = await BoardGithubDelivery.db.findFirstRow(
      session,
      where: (t) => t.deliveryId.equals(deliveryId),
    );
    if (row == null || row.processedAt != null) return;
    final config = BoardConfig.current;
    Map<dynamic, dynamic> payload;
    try {
      final decoded = jsonDecode(row.payload ?? '{}');
      payload = decoded is Map ? decoded : const {};
    } on FormatException {
      payload = const {};
    }
    final repo = '${payload['repo'] ?? ''}'.toLowerCase();
    if (!config.github.enabled ||
        repo != config.repository.toLowerCase() ||
        payload.isEmpty) {
      await _finish(session, row);
      return;
    }
    try {
      await dispatch(session, payload);
      await _finish(session, row);
    } on Object catch (e, st) {
      final attempts = row.attempts + 1;
      final giveUp = attempts >= maxAttempts;
      session.log(
        'board.github: delivery ${row.event} $deliveryId failed '
        '(attempt $attempts${giveUp ? ', dropped' : ''}): $e',
        level: giveUp ? LogLevel.error : LogLevel.warning,
        stackTrace: st,
      );
      if (giveUp) {
        await _finish(session, row.copyWith(attempts: attempts));
      } else {
        await BoardGithubDelivery.db.updateRow(
          session,
          row.copyWith(attempts: attempts),
          columns: (t) => [t.attempts],
        );
        await deliveryScheduler(
          session,
          deliveryId,
          Duration(minutes: attempts),
        );
      }
    }
  }

  static Future<void> _finish(
    Session session,
    BoardGithubDelivery row,
  ) => BoardGithubDelivery.db.updateRow(
    session,
    row.copyWith(processedAt: nowUtc(), payload: null),
    columns: (t) => [t.processedAt, t.payload, t.attempts],
  );

  /// Routes a compact payload to the gate, the review or the lifecycle.
  static Future<void> dispatch(
    Session session,
    Map<dynamic, dynamic> payload,
  ) async {
    final action = '${payload['action']}';
    switch (payload['event']) {
      case 'pull_request':
        final pr = GithubPrEvent.fromCompact(payload['pr'] as Map);
        await withPrLock(session, pr.number, () async {
          if (action == 'closed') {
            await GithubLifecycle.onClosed(session, pr);
          } else if (gateActions.contains(action)) {
            if (action == 'reopened') {
              await GithubLifecycle.onReopened(session, pr);
            }
            await GithubGate.run(session, pr);
          }
        });
      case 'check_run':
        if (action != 'rerequested') return;
        final run = payload['checkRun'] as Map;
        final numbers = [
          for (final n in (run['prNumbers'] as List?) ?? const []) n as int,
        ];
        if (numbers.isEmpty) {
          // Fork PRs: GitHub leaves `pull_requests` empty; find the PR by
          // its head commit.
          final sha = '${run['headSha'] ?? ''}';
          final rows = sha.isEmpty
              ? const <BoardPullRequest>[]
              : await BoardPullRequest.db.find(
                  session,
                  where: (t) => t.headSha.equals(sha) & t.state.equals('open'),
                );
          numbers.addAll(rows.map((r) => r.prNumber));
        }
        for (final n in numbers) {
          if (run['name'] == GithubGate.checkName) {
            final pr = GithubPrEvent.fromPullRequest(
              await api.getPullRequest(n),
            );
            if (pr.state != 'open') continue;
            await withPrLock(session, n, () => GithubGate.run(session, pr));
          } else if (run['name'] == GithubReview.checkName) {
            await GithubReview.rerequest(session, n);
          }
        }
      case 'workflow_run':
        if (action != 'completed') return;
        await GithubLifecycle.onWorkflowRun(
          session,
          payload['workflowRun'] as Map,
        );
    }
  }

  /// Serializes the handling of one PR across instances.
  static Future<T> withPrLock<T>(
    Session session,
    int prNumber,
    Future<T> Function() action,
  ) => Cluster.withLock(session, 'board.github.pr.$prNumber', action);

  // ---------------------------------------------------------------- sweep

  /// Deliveries still unhandled after this long lost their scheduled run
  /// (scheduling failed, or the instance stopped): the sweep runs them again.
  static const lostAfter = Duration(minutes: 30);

  /// Schedules deliveries older than [lostAfter] that were never handled
  /// (CQ-34: a delivery whose scheduling failed is otherwise lost, and
  /// GitHub's redelivery is deduplicated). Each pass counts as an attempt,
  /// so a delivery that keeps failing is dropped after [maxAttempts].
  static Future<int> rescheduleLost(Session session) async {
    final lost = await BoardGithubDelivery.db.find(
      session,
      where: (t) =>
          t.processedAt.equals(null) &
          (t.receivedAt < nowUtc().subtract(lostAfter)),
      orderBy: (t) => t.receivedAt,
      limit: 100,
    );
    for (final row in lost) {
      final attempts = row.attempts + 1;
      if (attempts > maxAttempts) {
        session.log(
          'board.github: delivery ${row.deliveryId} dropped after '
          '${row.attempts} attempts',
          level: LogLevel.error,
        );
        await _finish(session, row);
        continue;
      }
      await BoardGithubDelivery.db.updateRow(
        session,
        row.copyWith(attempts: attempts),
        columns: (t) => [t.attempts],
      );
      await deliveryScheduler(session, row.deliveryId, Duration.zero);
    }
    return lost.length;
  }

  /// The GitHub part of `wonky.boardSweep`: delivery purge, auto-close,
  /// postponed and lost reviews. Returns the rows touched.
  static Future<int> sweep(Session session) async {
    final purged = await BoardGithubDelivery.db.deleteWhere(
      session,
      where: (t) => t.receivedAt < nowUtc().subtract(deliveryRetention),
    );
    if (!BoardConfig.current.github.enabled) return purged.length;
    var count = purged.length;
    count += await rescheduleLost(session);
    count += await GithubGate.autoClose(session);
    count += await GithubReview.runDue(session);
    return count;
  }
}
