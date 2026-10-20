import 'package:serverpod/serverpod.dart';
import 'package:wonky_server/src/platform/board/ai/board_ai.dart';
import 'package:wonky_server/src/platform/common/models.dart';

/// A scripted [BoardAi] for board server tests (install with
/// `BoardAi.override`). Every call is recorded in [calls].
class FakeBoardAi implements BoardAi {
  /// Jev / Gemini configured and within budget.
  bool jev = true;
  bool gemini = false;

  /// Jev has a key but today's budget is spent ([jev] false).
  bool jevOverBudget = false;

  /// Gemini has a key but today's budget is spent ([gemini] false).
  bool geminiOverBudget = false;

  /// Answers of [triagePost]; the default is a clean post of the author's
  /// kind.
  BoardTriage Function(BoardPost post, List<BoardPost> candidates)? onTriage;

  /// Thrown by [triagePost] instead of answering (timeouts, provider
  /// errors).
  Object? triageError;

  /// Runs while [triagePost] "thinks" (before it answers): changes made
  /// here race with the triage, like an edit or a moderation during the
  /// AI call.
  Future<void> Function(BoardPost post)? whileTriaging;

  BoardModerationScores commentScores = const BoardModerationScores();
  Object? commentError;

  /// Probabilities of [rerankSimilar] per candidate id (default 0.5).
  Map<int, double> rerank = {};

  ({String? title, String summary}) summary = (
    title: null,
    summary: 'A short summary.',
  );

  String prompt = '## Goal\nFix it.\n\n## Acceptance criteria\n- [ ] Done';

  /// Thrown by [writeTaskPrompt] instead of answering (budget, provider
  /// errors).
  Object? promptError;

  /// The comments the last [writeTaskPrompt] was given, by post id.
  Map<int, List<BoardComment>>? promptComments;

  List<BoardBundleProposal> Function(List<BoardPost> posts)? onBundles;

  final calls = <String>[];
  final triageCandidates = <List<int>>[];

  static BoardTriage clean(
    BoardPost post, {
    BoardModerationScores scores = const BoardModerationScores(),
    BoardPostKind? kind,
    double kindConfidence = 0.9,
    BoardArea? area = BoardArea.sheets,
    BoardSize? size = BoardSize.small,
    Map<int, double> duplicates = const {},
  }) => BoardTriage(
    scores: scores,
    kind: kind ?? post.reportedKind,
    kindConfidence: kindConfidence,
    area: area,
    size: size,
    duplicates: duplicates,
    model: 'jev-test',
  );

  @override
  bool get jevConfigured => jev || jevOverBudget;

  @override
  bool get geminiConfigured => gemini || geminiOverBudget;

  @override
  Future<bool> jevAvailable(Session session) async => jev;

  @override
  Future<bool> geminiAvailable(Session session) async => gemini;

  @override
  Future<BoardTriage> triagePost(
    Session session,
    BoardPost post, {
    List<BoardPost> candidates = const [],
    Duration timeout = const Duration(seconds: 60),
  }) async {
    calls.add('triage');
    triageCandidates.add([for (final c in candidates) c.id!]);
    final error = triageError;
    if (error != null) throw error;
    await whileTriaging?.call(post);
    return (onTriage ?? (p, _) => clean(p))(post, candidates);
  }

  @override
  Future<BoardModerationScores> checkComment(
    Session session,
    String body, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    calls.add('checkComment');
    final error = commentError;
    if (error != null) throw error;
    return commentScores;
  }

  @override
  Future<List<(int, double)>> rerankSimilar(
    Session session, {
    required String title,
    required String body,
    required List<BoardPost> candidates,
  }) async {
    calls.add('rerank');
    final ranked = [
      for (final c in candidates) (c.id!, rerank[c.id] ?? 0.5),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    return ranked;
  }

  @override
  Future<({String? title, String summary})> summarize(
    Session session,
    BoardPost post,
  ) async {
    calls.add('summarize');
    return summary;
  }

  @override
  Future<List<BoardBundleProposal>> suggestBundles(
    Session session,
    List<BoardPost> posts,
  ) async {
    calls.add('bundles');
    return (onBundles ?? (_) => const <BoardBundleProposal>[])(posts);
  }

  @override
  Future<String> writeTaskPrompt(
    Session session, {
    required BoardTask task,
    required List<BoardPost> posts,
    required Map<int, List<BoardComment>> comments,
    required Uri webOrigin,
  }) async {
    calls.add('prompt');
    promptComments = comments;
    final error = promptError;
    if (error != null) throw error;
    return prompt;
  }
}
