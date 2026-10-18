import 'package:wonky_server/src/platform/board/github/github_client.dart';

/// A check run the fake API received.
class FakeCheckRun {
  FakeCheckRun({
    required this.id,
    required this.name,
    required this.headSha,
    required this.status,
    required this.conclusion,
    required this.title,
    required this.summary,
    this.detailsUrl,
  });

  final int id;
  final String name;
  final String headSha;
  String status;
  String? conclusion;
  String title;
  String summary;
  final String? detailsUrl;
}

/// An in-memory GitHub for the board's GitHub tests: records every call,
/// keeps comments and labels per PR, answers org membership, PR data,
/// files, diffs and compares from fields the test sets.
class FakeGithubApi implements GithubApi {
  final calls = <String>[];

  /// Logins in the maintainer org.
  final members = <String>{};

  /// PRs for [getPullRequest].
  final pulls = <int, GithubPullRequest>{};
  final files = <int, List<GithubPrFile>>{};
  final diffs = <int, String>{};

  /// `base...head` → status; anything else is `diverged`.
  final compares = <String, String>{};

  final checkRuns = <FakeCheckRun>[];

  /// Comment id → (issue, body).
  final comments = <int, (int, String)>{};
  final labels = <int, Set<String>>{};
  final closed = <int>{};

  var _nextId = 1000;

  /// Thrown by [getPullRequestDiff] when set (e.g. a 406 "too large").
  Object? diffError;

  List<FakeCheckRun> runsNamed(String name) =>
      checkRuns.where((r) => r.name == name).toList();

  List<String> commentsOn(int issue) => [
    for (final c in comments.values)
      if (c.$1 == issue) c.$2,
  ];

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
    calls.add('createCheckRun $name $status ${conclusion ?? ''}'.trim());
    final id = _nextId++;
    checkRuns.add(
      FakeCheckRun(
        id: id,
        name: name,
        headSha: headSha,
        status: status,
        conclusion: conclusion,
        title: title,
        summary: summary,
        detailsUrl: detailsUrl,
      ),
    );
    return id;
  }

  @override
  Future<void> updateCheckRun(
    int id, {
    required String status,
    String? conclusion,
    required String title,
    required String summary,
  }) async {
    calls.add('updateCheckRun $id $status ${conclusion ?? ''}'.trim());
    final run = checkRuns.firstWhere((r) => r.id == id);
    run
      ..status = status
      ..conclusion = conclusion
      ..title = title
      ..summary = summary;
  }

  @override
  Future<int> createComment(int issue, String body) async {
    calls.add('createComment $issue');
    final id = _nextId++;
    comments[id] = (issue, body);
    return id;
  }

  @override
  Future<bool> updateComment(int id, String body) async {
    calls.add('updateComment $id');
    final c = comments[id];
    if (c == null) return false;
    comments[id] = (c.$1, body);
    return true;
  }

  @override
  Future<int?> findBotComment(int issue, String marker) async {
    calls.add('findBotComment $issue');
    for (final e in comments.entries) {
      if (e.value.$1 == issue && e.value.$2.contains(marker)) return e.key;
    }
    return null;
  }

  @override
  Future<void> addLabels(int issue, List<String> labels) async {
    calls.add('addLabels $issue ${labels.join(',')}');
    this.labels.putIfAbsent(issue, () => {}).addAll(labels);
  }

  @override
  Future<void> removeLabel(int issue, String label) async {
    calls.add('removeLabel $issue $label');
    labels[issue]?.remove(label);
  }

  @override
  Future<void> closePullRequest(int number) async {
    calls.add('closePullRequest $number');
    closed.add(number);
  }

  @override
  Future<GithubPullRequest> getPullRequest(int number) async {
    calls.add('getPullRequest $number');
    final pr = pulls[number];
    if (pr == null) {
      throw GithubApiException(404, 'GET', '/pulls/$number', 'Not Found');
    }
    return pr;
  }

  @override
  Future<List<GithubPrFile>> listPullRequestFiles(int number) async {
    calls.add('listPullRequestFiles $number');
    return files[number] ?? const [];
  }

  @override
  Future<String> getPullRequestDiff(int number) async {
    calls.add('getPullRequestDiff $number');
    final e = diffError;
    if (e != null) throw e;
    return diffs[number] ?? '';
  }

  @override
  Future<String> compareStatus(String base, String head) async {
    calls.add('compare $base...$head');
    return compares['$base...$head'] ?? 'diverged';
  }

  @override
  Future<bool> isOrgMember(String org, String login) async {
    calls.add('isOrgMember $org $login');
    return members.contains(login);
  }
}
