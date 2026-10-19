import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_server/src/platform/board/board_config.dart';
import 'package:wonky_server/src/platform/board/github/board_github.dart';
import 'package:wonky_server/src/platform/board/github/github_review_ai.dart';
import 'package:wonky_server/src/platform/board/github/github_webhook.dart';

import '../test_users.dart';
import '../wonky_serverpod.dart';
import 'board_harness.dart';
import 'fake_github_api.dart';

/// A scheduled review (recorded instead of a future call).
typedef ScheduledReview = ({int prNumber, String sha, DateTime at});

/// A [PrReviewer] answering with [result] (or throwing [error]).
class FakePrReviewer implements PrReviewer {
  PrReviewResult result = PrReviewResult.fromToolInput(const {
    'criteria': [
      {
        'criterion': 'Styles are kept',
        'verdict': 'met',
        'evidence': [
          {'path': 'packages/wonky_sheets_core/lib/paste.dart'},
        ],
        'note': 'Copies the style runs.',
      },
    ],
    'unrelatedChanges': <Object>[],
    'tests': {'verdict': 'added', 'note': ''},
    'specs': {'verdict': 'notNeeded', 'note': ''},
    'risks': <Object>[],
    'summary': 'Does what the task asks.',
  });

  Object? error;
  bool isConfigured = true;
  final inputs = <PrReviewInput>[];

  @override
  bool get configured => isConfigured;

  @override
  Future<PrReviewResult> review(Session session, PrReviewInput input) async {
    inputs.add(input);
    final e = error;
    if (e != null) throw e;
    return result;
  }
}

/// Test setup of the GitHub integration on top of [BoardHarness]: the
/// integration enabled, a [FakeGithubApi], a fixed webhook secret,
/// recorded deliveries and reviews, a [FakePrReviewer].
class GithubHarness {
  GithubHarness._(this.board, this.api, this.reviewer);

  final BoardHarness board;
  final FakeGithubApi api;
  final FakePrReviewer reviewer;
  final deliveries = <String>[];
  final reviews = <ScheduledReview>[];

  static const secret = 'test-webhook-secret';
  static const repository = 'serverpod/wonky';

  static var _seq = 0;

  static BoardConfig config({
    bool enabled = true,
    int reviewsPerPrPerDay = 10,
    bool reviewBlocking = false,
    int maxDiffTokens = 400000,
  }) => BoardConfig(
    repository: repository,
    github: BoardGithubConfig(
      enabled: enabled,
      appId: 4242,
      reviewsPerPrPerDay: reviewsPerPrPerDay,
      reviewBlocking: reviewBlocking,
      maxDiffTokens: maxDiffTokens,
    ),
  );

  static GithubHarness install({BoardConfig? config}) {
    final board = BoardHarness.install(
      config: config ?? GithubHarness.config(),
    );
    board.ai.jev = false;
    final h = GithubHarness._(board, FakeGithubApi(), FakePrReviewer());
    BoardGithub.apiOverride = h.api;
    PrReviewer.override = h.reviewer;
    GithubWebhook.secretSource = () => secret;
    BoardGithub.deliveryScheduler = (session, id, delay) async =>
        h.deliveries.add(id);
    BoardGithub.reviewScheduler = (session, pr, sha, at) async =>
        h.reviews.add((prNumber: pr, sha: sha, at: at));
    return h;
  }

  void uninstall() {
    BoardGithub.reset();
    PrReviewer.override = null;
    GithubWebhook.secretSource = GithubWebhook.secret;
    board.uninstall();
  }

  /// A PR number no other test uses (the database is shared).
  static int prNumber() {
    _seq++;
    return (clock.now().microsecondsSinceEpoch % 100000000) * 10 + _seq;
  }

  /// A fresh 40-hex commit SHA.
  static String sha([String seed = '']) {
    _seq++;
    return sha1
        .convert(
          utf8.encode('$seed ${clock.now().microsecondsSinceEpoch} $_seq'),
        )
        .toString();
  }

  static String signature(List<int> body, [String key = secret]) =>
      'sha256=${Hmac(sha256, utf8.encode(key)).convert(body)}';

  static Map<String, dynamic> fixture(String name) =>
      (jsonDecode(
                File(
                  'test/fixtures/github/$name.json',
                ).readAsStringSync(),
              )
              as Map)
          .cast<String, dynamic>();

  /// A `pull_request` payload from the recorded fixture.
  static Map<String, dynamic> pullRequest({
    required int number,
    String action = 'opened',
    String body = '',
    String author = 'octocat',
    String? headSha,
    String state = 'open',
    bool draft = false,
    bool merged = false,
    String? mergeCommitSha,
  }) {
    final p = fixture('pull_request');
    p['action'] = action;
    p['number'] = number;
    final pr = (p['pull_request'] as Map).cast<String, dynamic>();
    pr['number'] = number;
    pr['html_url'] = 'https://github.com/$repository/pull/$number';
    pr['body'] = body;
    (pr['user'] as Map)['login'] = author;
    (pr['head'] as Map)['sha'] = headSha ?? sha('head');
    pr['state'] = state;
    pr['draft'] = draft;
    pr['merged'] = merged;
    pr['merge_commit_sha'] = mergeCommitSha;
    return p;
  }

  static Map<String, dynamic> checkRunRerequested({
    required String name,
    required String headSha,
    List<int> prNumbers = const [],
  }) {
    final p = fixture('check_run_rerequested');
    final run = (p['check_run'] as Map).cast<String, dynamic>();
    run['name'] = name;
    run['head_sha'] = headSha;
    run['pull_requests'] = [
      for (final n in prNumbers) {'number': n, 'id': n},
    ];
    return p;
  }

  static Map<String, dynamic> workflowRun({
    required String headSha,
    String conclusion = 'success',
    String path = '.github/workflows/deploy.yml',
  }) {
    final p = fixture('workflow_run_completed');
    final run = (p['workflow_run'] as Map).cast<String, dynamic>();
    run['head_sha'] = headSha;
    run['conclusion'] = conclusion;
    run['path'] = path;
    return p;
  }

  /// Sends [payload] as a signed webhook and returns the HTTP status.
  Future<int> send(
    Session session,
    String event,
    Map<String, dynamic> payload, {
    String? deliveryId,
    String? signature,
  }) {
    final body = utf8.encode(jsonEncode(payload));
    return GithubWebhook.receive(
      session,
      headers: {
        'X-GitHub-Event': event,
        'X-GitHub-Delivery': deliveryId ?? 'd-${sha('delivery')}',
        'X-Hub-Signature-256': signature ?? GithubHarness.signature(body),
        'Content-Type': 'application/json',
      },
      body: body,
    );
  }

  /// Sends [payload] and handles the delivery inline (as the future call
  /// would).
  Future<void> deliver(
    Session session,
    String event,
    Map<String, dynamic> payload,
  ) async {
    final before = deliveries.length;
    final status = await send(session, event, payload);
    if (status != 202) throw StateError('webhook answered $status');
    for (final id in deliveries.sublist(before)) {
      await BoardGithub.handleDelivery(session, id);
    }
  }

  /// A published task of a new post by [author], claimed by [claimant]:
  /// its number and the claim code.
  static Future<({int number, String code})> claimedTask(
    TestEndpoints endpoints, {
    required TestUser admin,
    required TestUser author,
    required TestUser claimant,
    String title = 'Keep styles when pasting',
  }) async {
    final number = await publishedTask(
      endpoints,
      admin: admin,
      author: author,
      title: title,
    );
    final view = await endpoints.board.claimTask(
      claimant.endpointSession,
      number,
    );
    return (number: number, code: view.claimCode!);
  }

  /// A published task of a new post by [author].
  static Future<int> publishedTask(
    TestEndpoints endpoints, {
    required TestUser admin,
    required TestUser author,
    String title = 'Keep styles when pasting',
  }) async {
    final post = await BoardHarness.post(endpoints, author);
    final task = await BoardHarness.publishedTask(endpoints, admin, [
      post.number,
    ], title: title);
    return task.number;
  }

  /// A description with the two lines.
  static String body(int task, String code) =>
      'Keeps styles.\n\nWonky-Task: T-$task\nWonky-Claim: $code\n';
}
