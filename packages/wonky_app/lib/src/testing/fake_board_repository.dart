import 'dart:async';

import 'package:clock/clock.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/board.dart';

import '../board/board_repository.dart';

/// A post of [FakeBoardRepository] (mutable; views are built on read).
class FakeBoardPost {
  FakeBoardPost({
    required this.number,
    required this.kind,
    required this.title,
    required this.body,
    required this.authorId,
    required this.createdAt,
    BoardPostKind? reportedKind,
    this.area,
    this.size,
    this.aiLabels = false,
    this.contextJson,
    this.appHint = 'write',
    this.hasScreenshot = false,
    this.status = BoardPostStatus.open,
    this.moderation = BoardModeration.visible,
    this.moderationReason,
    this.triageState = BoardTriageState.done,
    this.triageJson,
    this.reviewScores,
    this.needsCheck = false,
    this.suggestedTitle,
    this.summary,
    this.possibleDuplicateOf,
    this.duplicateOf,
    this.declineReason,
    this.taskNumber,
  }) : reportedKind = reportedKind ?? kind;

  final int number;
  BoardPostKind kind;
  BoardPostKind reportedKind;
  BoardArea? area;
  BoardSize? size;
  bool aiLabels;
  String title;
  String body;
  String? contextJson;
  String appHint;
  bool hasScreenshot;
  BoardPostStatus status;
  BoardModeration moderation;
  String? moderationReason;
  bool editedByModerator = false;
  BoardTriageState triageState;
  String? triageJson;

  /// Moderation scores in their review band (the server derives them from
  /// the triage; seeded directly here).
  Map<String, double>? reviewScores;
  bool needsCheck;
  String? suggestedTitle;
  String? summary;
  int? possibleDuplicateOf;
  int? duplicateOf;
  String? declineReason;
  int? taskNumber;
  final int? authorId;
  final DateTime createdAt;
  DateTime? editedAt;
  DateTime? deletedAt;

  /// userId → +1 / −1.
  final Map<int, int> votes = {};

  /// Votes moved here by a merge, per source post (for unmerge).
  final Map<int, Map<int, int>> movedVotes = {};
}

/// A comment of [FakeBoardRepository].
class FakeBoardComment {
  FakeBoardComment({
    required this.uuid,
    required this.body,
    required this.createdAt,
    this.postNumber,
    this.taskNumber,
    this.authorId,
    this.systemEvent,
    this.moderation = BoardModeration.visible,
  });

  final UuidValue uuid;
  final int? postNumber;
  final int? taskNumber;
  final int? authorId;
  String body;
  final String? systemEvent;
  BoardModeration moderation;
  String? moderationReason;
  bool needsCheck = false;
  final DateTime createdAt;
  DateTime? editedAt;
  bool deleted = false;
}

/// A task of [FakeBoardRepository].
class FakeBoardTask {
  FakeBoardTask({
    required this.number,
    required this.title,
    required this.area,
    required this.size,
    required this.createdAt,
    this.status = BoardTaskStatus.draft,
    this.promptBody = '',
    List<int>? posts,
  }) : posts = posts ?? [];

  final int number;
  String title;
  BoardArea area;
  BoardSize size;
  BoardTaskStatus status;
  String promptBody;
  final List<int> posts;
  int? claimedById;
  DateTime? claimedAt;
  DateTime? claimExpiresAt;
  String? claimCode;
  String? pullRequestUrl;
  int? prNumber;
  String? reviewJson;
  DateTime? publishedAt;
  DateTime? promptEditedAt;

  /// The "AI" is writing the prompt (see
  /// [FakeBoardRepository.writesPromptLater]).
  bool promptPending = false;
  String? promptNote;

  /// The task this cancelled one was merged into.
  int? mergedInto;
  final DateTime createdAt;
}

/// In-memory [BoardRepository] with the server's rules for what the board
/// pages and `shell.board.*` commands use (specs/16 §7–§9): visibility per
/// moderation state, votes (no down votes on bugs, closed when done),
/// comments, flags, claims (48 h, 2 per user, a claim code for the
/// claimant), admin moderation, labels, merge, tasks and bundles.
///
/// The caller is [userId] (null = signed out) and an admin when [isAdmin].
/// Every call is appended to [calls] (`'vote 12 1'`).
class FakeBoardRepository implements BoardRepository {
  FakeBoardRepository({this.userId = 1, this.isAdmin = false});

  /// The caller; null when signed out.
  int? userId;
  bool isAdmin;
  bool blocked = false;

  /// When set, every call throws it (offline, server errors).
  Object? failWith;

  /// Like the server with Gemini (specs/16 §10.1): `createTask` and
  /// `regeneratePrompt` leave the prompt pending until [finishPrompt].
  /// Otherwise the prompt is written at once.
  bool writesPromptLater = false;

  final List<String> calls = [];

  final Map<int, BoardAuthor> users = {
    1: BoardAuthor(
      id: 1,
      displayName: 'Anna Berg',
      avatarColor: '#6366f1',
      colorIndex: 1,
      isAdmin: false,
    ),
    2: BoardAuthor(
      id: 2,
      displayName: 'Bob Stone',
      avatarColor: '#0ea5e9',
      colorIndex: 2,
      isAdmin: false,
    ),
    3: BoardAuthor(
      id: 3,
      displayName: 'Ada Admin',
      avatarColor: '#22c55e',
      colorIndex: 3,
      isAdmin: true,
    ),
  };

  final Map<int, FakeBoardPost> posts = {};
  final Map<int, FakeBoardTask> tasks = {};
  final Map<String, FakeBoardComment> comments = {};
  final List<BoardBundleSuggestionView> suggestions = [];

  /// `post:<n>` / `comment:<uuid>` → userId → (reason, note).
  final Map<String, Map<int, (BoardFlagReason, String?)>> flags = {};

  /// Blocked user ids → reason.
  final Map<int, String> blockedUsers = {};

  int _nextPost = 1;
  int _nextTask = 1;
  int _nextSuggestion = 1;
  int _codes = 0;

  final _postEvents = StreamController<BoardPostEvent>.broadcast();
  final _taskEvents = StreamController<BoardPostEvent>.broadcast();

  /// Emits a live event on the post's `watchPost` stream.
  void emitPost(
    int number, [
    BoardEventKind kind = BoardEventKind.postChanged,
  ]) => _postEvents.add(BoardPostEvent(kind: kind, number: number));

  /// Finishes the pending prompt of task [number] with [body] (or leaves
  /// the body with [note]) and emits the task event, like the server's
  /// `BoardFutureCall.writePrompt`: a written prompt publishes its draft
  /// unless the lint flags it (T-11), then the draft is held with a note.
  void finishPrompt(int number, {String? body, String? note}) {
    final t = tasks[number]!
      ..promptPending = false
      ..promptNote = note;
    if (body != null) {
      t.promptBody = body;
      if (t.status == BoardTaskStatus.draft) {
        if (lintTaskPrompt(body).isEmpty) {
          t
            ..status = BoardTaskStatus.published
            ..publishedAt = clock.now();
          _syncPosts(t);
        } else {
          t.promptNote = 'Held for review.';
        }
      }
    }
    emitTask(number);
  }

  /// Emits a live event on `watchTasks`.
  void emitTask(int number) => _taskEvents.add(
    BoardPostEvent(kind: BoardEventKind.taskChanged, number: number),
  );

  Future<void> dispose() async {
    await _postEvents.close();
    await _taskEvents.close();
  }

  // ------------------------------------------------------------- seeding

  /// Adds a post (author [authorId], default Bob) and returns it.
  FakeBoardPost seedPost({
    String title = 'Paste into merged cells drops styles',
    String body = 'It loses the **formatting**.',
    BoardPostKind kind = BoardPostKind.idea,
    int? authorId = 2,
    BoardArea? area = BoardArea.sheets,
    BoardSize? size = BoardSize.small,
    bool aiLabels = false,
    BoardPostStatus status = BoardPostStatus.open,
    BoardModeration moderation = BoardModeration.visible,
    String? moderationReason,
    int score = 0,
    bool hasScreenshot = false,
    String? contextJson,
    DateTime? createdAt,
    bool needsCheck = false,
    BoardTriageState triageState = BoardTriageState.done,
    int? possibleDuplicateOf,
    String? suggestedTitle,
    String? triageJson,
    Map<String, double>? reviewScores,
  }) {
    final n = _nextPost++;
    final p = FakeBoardPost(
      number: n,
      kind: kind,
      title: title,
      body: body,
      authorId: authorId,
      createdAt: createdAt ?? clock.now().subtract(Duration(hours: n)),
      area: area,
      size: size,
      aiLabels: aiLabels,
      status: status,
      moderation: moderation,
      moderationReason: moderationReason,
      hasScreenshot: hasScreenshot,
      contextJson: contextJson,
      needsCheck: needsCheck,
      triageState: triageState,
      possibleDuplicateOf: possibleDuplicateOf,
      suggestedTitle: suggestedTitle,
      triageJson: triageJson,
      reviewScores: reviewScores,
    );
    // Score from distinct fake voters (ids 100+).
    for (var i = 0; i < score.abs(); i++) {
      p.votes[100 + i] = score > 0 ? 1 : -1;
    }
    posts[n] = p;
    return p;
  }

  FakeBoardTask seedTask({
    String title = 'Merged cells keep formatting',
    BoardArea area = BoardArea.sheets,
    BoardSize size = BoardSize.small,
    BoardTaskStatus status = BoardTaskStatus.published,
    String promptBody = '## Goal\nKeep styles when pasting.',
    List<int> posts = const [],
    int? claimedById,
  }) {
    final n = _nextTask++;
    final t = FakeBoardTask(
      number: n,
      title: title,
      area: area,
      size: size,
      createdAt: clock.now(),
      status: status,
      promptBody: promptBody,
      posts: [...posts],
    );
    if (status != BoardTaskStatus.draft) t.publishedAt = clock.now();
    if (claimedById != null) {
      t
        ..status = BoardTaskStatus.claimed
        ..claimedById = claimedById
        ..claimedAt = clock.now()
        ..claimExpiresAt = clock.now().add(const Duration(hours: 31))
        ..claimCode = _code();
    }
    for (final p in posts) {
      this.posts[p]?.taskNumber = n;
      if (status != BoardTaskStatus.draft) {
        this.posts[p]?.status = BoardPostStatus.planned;
      }
    }
    tasks[n] = t;
    return t;
  }

  FakeBoardComment seedComment({
    int? postNumber,
    int? taskNumber,
    int? authorId = 2,
    String body = 'Same here.',
    String? systemEvent,
    BoardModeration moderation = BoardModeration.visible,
    DateTime? createdAt,
  }) {
    final c = FakeBoardComment(
      uuid: UuidValue.fromString(
        '00000000-0000-7000-8000-${(comments.length + 1).toRadixString(16).padLeft(12, '0')}',
      ),
      postNumber: postNumber,
      taskNumber: taskNumber,
      authorId: authorId,
      body: body,
      systemEvent: systemEvent,
      moderation: moderation,
      createdAt: createdAt ?? clock.now(),
    );
    comments[c.uuid.uuid] = c;
    return c;
  }

  BoardBundleSuggestionView seedSuggestion({
    String title = 'Merged cells',
    String rationale = 'Same code path.',
    List<int> postNumbers = const [],
  }) {
    final s = BoardBundleSuggestionView(
      id: _nextSuggestion++,
      title: title,
      rationale: rationale,
      area: BoardArea.sheets,
      posts: [for (final n in postNumbers) _listItem(posts[n]!)],
      createdAt: clock.now(),
    );
    suggestions.add(s);
    return s;
  }

  // ------------------------------------------------------------- helpers

  void _log(String call) {
    calls.add(call);
    final f = failWith;
    if (f != null) throw f;
  }

  static WonkyException _err(WonkyErrorCode code, String message) =>
      WonkyException(code: code, message: message);

  void _writer() {
    if (userId == null) {
      throw _err(WonkyErrorCode.forbidden, 'Sign in to continue.');
    }
    if (blocked) {
      throw _err(
        WonkyErrorCode.forbidden,
        "You can't post on Bugs & improvements",
      );
    }
  }

  void _admin() {
    if (!isAdmin || userId == null) {
      throw _err(WonkyErrorCode.forbidden, 'Admins only.');
    }
  }

  bool _canSee(FakeBoardPost p) {
    if (isAdmin) return true;
    final mine = userId != null && p.authorId == userId;
    if (p.deletedAt != null) return mine;
    if (p.moderation == BoardModeration.visible) return true;
    return mine;
  }

  FakeBoardPost _post(int number) {
    final p = posts[number];
    if (p == null || !_canSee(p)) {
      throw _err(WonkyErrorCode.notFound, 'Post #$number not found.');
    }
    return p;
  }

  FakeBoardTask _task(int number) {
    final t = tasks[number];
    if (t == null || (t.status == BoardTaskStatus.draft && !isAdmin)) {
      throw _err(WonkyErrorCode.notFound, 'Task T-$number not found.');
    }
    return t;
  }

  FakeBoardComment _comment(UuidValue uuid) =>
      comments[uuid.uuid] ??
      (throw _err(WonkyErrorCode.notFound, 'Comment not found.'));

  int _score(FakeBoardPost p) => p.votes.values.fold(0, (a, b) => a + b);

  int _commentCount(int number) => comments.values
      .where(
        (c) =>
            c.postNumber == number &&
            !c.deleted &&
            c.moderation == BoardModeration.visible &&
            c.systemEvent == null,
      )
      .length;

  BoardTaskRef? _taskRef(FakeBoardPost p) {
    final t = p.taskNumber == null ? null : tasks[p.taskNumber];
    if (t == null) return null;
    if (t.status == BoardTaskStatus.draft && !isAdmin) return null;
    return BoardTaskRef(number: t.number, title: t.title, status: _status(t));
  }

  List<BoardFlagView>? _flagsOf(String key) => isAdmin
      ? [
          for (final e in (flags[key] ?? const {}).entries)
            BoardFlagView(
              reason: e.value.$1,
              note: e.value.$2,
              by: users[e.key],
              createdAt: clock.now(),
            ),
        ]
      : null;

  BoardPostListItem _listItem(FakeBoardPost p) => BoardPostListItem(
    number: p.number,
    kind: p.kind,
    area: p.area,
    size: p.size,
    aiLabels: p.aiLabels,
    title: p.title,
    status: p.status,
    moderation: p.moderation,
    needsCheck: p.needsCheck,
    score: _score(p),
    voteCount: p.votes.length,
    commentCount: _commentCount(p.number),
    myVote: userId == null ? 0 : p.votes[userId] ?? 0,
    author: p.authorId == null ? null : users[p.authorId],
    isMine: userId != null && p.authorId == userId,
    hasScreenshot: p.hasScreenshot,
    task: _taskRef(p),
    createdAt: p.createdAt,
  );

  BoardPostView _view(FakeBoardPost p) {
    final mine = userId != null && p.authorId == userId;
    return BoardPostView(
      number: p.number,
      kind: p.kind,
      reportedKind: p.reportedKind,
      area: p.area,
      size: p.size,
      aiLabels: p.aiLabels,
      title: p.title,
      body: p.body,
      contextJson: p.contextJson,
      appHint: p.appHint,
      hasScreenshot: p.hasScreenshot,
      status: p.status,
      moderation: p.moderation,
      moderationReason: mine || isAdmin ? p.moderationReason : null,
      editedByModerator: p.editedByModerator,
      triageState: p.triageState,
      summary: p.summary,
      duplicateOfNumber: p.duplicateOf,
      declineReason: p.declineReason,
      task: _taskRef(p),
      mergedFrom: [
        for (final o in posts.values)
          if (o.duplicateOf == p.number) o.number,
      ],
      score: _score(p),
      voteCount: p.votes.length,
      commentCount: _commentCount(p.number),
      myVote: userId == null ? 0 : p.votes[userId] ?? 0,
      author: p.authorId == null ? null : users[p.authorId],
      isMine: mine,
      canEdit: mine && p.status == BoardPostStatus.open && p.taskNumber == null,
      createdAt: p.createdAt,
      editedAt: p.editedAt,
      deleted: p.deletedAt != null,
      needsCheck: isAdmin && p.needsCheck,
      suggestedTitle: isAdmin ? p.suggestedTitle : null,
      possibleDuplicateOfNumber: isAdmin ? p.possibleDuplicateOf : null,
      triageJson: isAdmin ? p.triageJson : null,
      reviewScores: isAdmin ? p.reviewScores : null,
      flags: _flagsOf('post:${p.number}'),
    );
  }

  BoardCommentView _commentView(FakeBoardComment c) => BoardCommentView(
    uuid: c.uuid,
    postNumber: c.postNumber,
    taskNumber: c.taskNumber,
    author: c.authorId == null ? null : users[c.authorId],
    body: c.deleted ? '' : c.body,
    systemEvent: c.systemEvent,
    moderation: c.moderation,
    moderationReason: c.moderationReason,
    isMine: userId != null && c.authorId == userId,
    createdAt: c.createdAt,
    editedAt: c.editedAt,
    deleted: c.deleted,
    needsCheck: isAdmin && c.needsCheck,
    flags: _flagsOf('comment:${c.uuid.uuid}'),
  );

  BoardTaskStatus _status(FakeBoardTask t) {
    if (t.status == BoardTaskStatus.claimed &&
        (t.claimExpiresAt == null || !t.claimExpiresAt!.isAfter(clock.now()))) {
      return BoardTaskStatus.published;
    }
    return t.status;
  }

  bool _claimValid(FakeBoardTask t) =>
      t.claimedById != null &&
      t.claimExpiresAt != null &&
      (t.status == BoardTaskStatus.inReview ||
          t.claimExpiresAt!.isAfter(clock.now()));

  BoardTaskView _taskView(FakeBoardTask t) {
    final claimed = _claimValid(t);
    final mine = claimed && userId != null && t.claimedById == userId;
    // Like the server: the prompt only for the claimant (with their claim
    // code in the PR lines) and admins (with the placeholder).
    final seesPrompt = mine || isAdmin;
    final code = mine ? t.claimCode! : '<your claim code from the task page>';
    return BoardTaskView(
      number: t.number,
      title: t.title,
      area: t.area,
      size: t.size,
      status: _status(t),
      promptBody: seesPrompt ? t.promptBody : '',
      prompt: seesPrompt
          ? '# Wonky task T-${t.number}: ${t.title}\n\n${t.promptBody}\n\n'
                '## When you are done\n\n```\nWonky-Task: T-${t.number}\n'
                'Wonky-Claim: $code\n```\n'
          : '',
      promptEditedAt: t.promptEditedAt,
      promptPending: t.promptPending,
      promptNote: isAdmin ? t.promptNote : null,
      posts: [
        for (final n in t.posts)
          if (posts[n] case final p? when _canSee(p)) _listItem(p),
      ],
      claimedBy: claimed ? users[t.claimedById] : null,
      claimedAt: claimed ? t.claimedAt : null,
      claimExpiresAt: claimed ? t.claimExpiresAt : null,
      claimCode: mine ? t.claimCode : null,
      isMine: mine,
      pullRequestUrl: t.pullRequestUrl,
      prNumber: t.prNumber,
      reviewJson: t.reviewJson,
      mergedInto: t.status == BoardTaskStatus.cancelled ? t.mergedInto : null,
      publishedAt: t.publishedAt,
      createdAt: t.createdAt,
    );
  }

  String _code() {
    _codes++;
    return '7Q4F-${_codes.toString().padLeft(4, '0')}';
  }

  void _system(int taskNumber, String event) => seedComment(
    taskNumber: taskNumber,
    authorId: userId,
    body: '',
    systemEvent: event,
  );

  void _syncPosts(FakeBoardTask t) {
    for (final n in t.posts) {
      final p = posts[n];
      if (p == null) continue;
      p.status = switch (t.status) {
        BoardTaskStatus.draft => p.status,
        BoardTaskStatus.cancelled => BoardPostStatus.open,
        BoardTaskStatus.done => BoardPostStatus.done,
        BoardTaskStatus.shipped => BoardPostStatus.shipped,
        _ => BoardPostStatus.planned,
      };
      if (t.status == BoardTaskStatus.cancelled) p.taskNumber = null;
    }
  }

  // ---------------------------------------------------------------- read

  @override
  Future<BoardMe> me() async {
    _log('me');
    final id = userId;
    return BoardMe(
      signedIn: id != null,
      userId: id,
      isAdmin: id != null && isAdmin,
      blocked: blocked,
      activeClaims: [
        for (final t in tasks.values)
          if (id != null && t.claimedById == id && _claimValid(t)) t.number,
      ],
      aiChecks: true,
      repository: 'serverpod/wonky',
      securityContact: 'security@serverpod.dev',
      claimHours: 48,
    );
  }

  @override
  Future<BoardPostPage> list(BoardListQuery query) async {
    _log('list ${query.kind?.name} ${query.sort.name} ${query.cursor}');
    final q = query.query?.trim().toLowerCase() ?? '';
    final rows = [
      for (final p in posts.values)
        if (p.deletedAt == null &&
            (p.moderation == BoardModeration.visible ||
                (isAdmin && p.moderation != BoardModeration.removed)) &&
            (query.kind == null || p.kind == query.kind) &&
            (query.statuses.isEmpty || query.statuses.contains(p.status)) &&
            (query.areas.isEmpty || query.areas.contains(p.area)) &&
            (query.sizes.isEmpty || query.sizes.contains(p.size)) &&
            (!query.mine ||
                (userId != null &&
                    (p.authorId == userId || p.votes.containsKey(userId)))) &&
            (q.isEmpty || _searchRank(p, q) > 0))
          p,
    ];
    int byScore(FakeBoardPost a, FakeBoardPost b) {
      final c = _score(b).compareTo(_score(a));
      return c != 0 ? c : b.number.compareTo(a.number);
    }

    final bySort = switch (query.sort) {
      BoardSort.top || BoardSort.trending => byScore,
      BoardSort.newest =>
        (FakeBoardPost a, FakeBoardPost b) =>
            b.createdAt.compareTo(a.createdAt),
      BoardSort.discussed => (FakeBoardPost a, FakeBoardPost b) {
        final c = _commentCount(b.number).compareTo(_commentCount(a.number));
        return c != 0 ? c : byScore(a, b);
      },
    };
    rows.sort((a, b) {
      if (q.isNotEmpty) {
        final r = _searchRank(b, q).compareTo(_searchRank(a, q));
        if (r != 0) return r;
      }
      return bySort(a, b);
    });
    final offset = int.tryParse(query.cursor ?? '') ?? 0;
    final limit = query.limit <= 0 ? 30 : query.limit;
    final page = rows.skip(offset).take(limit).toList();
    final next = offset + page.length;
    return BoardPostPage(
      items: [for (final p in page) _listItem(p)],
      nextCursor: next < rows.length ? '$next' : null,
      total: rows.length,
    );
  }

  /// Like the server's search (specs/16 §6.4), 0 when [p] does not match
  /// [q] (lowercase): 3 for its number (`12`, `#12`), 2 when every word of
  /// [q] starts a word of the title or body, 1 for a title substring.
  int _searchRank(FakeBoardPost p, String q) {
    final number = RegExp(r'^#?\s*(\d+)$').firstMatch(q);
    if (number != null && int.parse(number[1]!) == p.number) return 3;
    final words = [
      for (final m in RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(q))
        if (m[0]!.length > 1) m[0]!,
    ];
    final text = RegExp(
      r'[\p{L}\p{N}]+',
      unicode: true,
    ).allMatches('${p.title} ${p.body}'.toLowerCase()).map((m) => m[0]!);
    if (words.isNotEmpty &&
        words.every((w) => text.any((t) => t.startsWith(w)))) {
      return 2;
    }
    return p.title.toLowerCase().contains(q) ? 1 : 0;
  }

  @override
  Future<BoardCounts> counts() async {
    _log('counts');
    int open(BoardPostKind kind) => posts.values
        .where(
          (p) =>
              p.deletedAt == null &&
              p.moderation == BoardModeration.visible &&
              p.kind == kind &&
              (p.status == BoardPostStatus.open ||
                  p.status == BoardPostStatus.planned),
        )
        .length;
    int tasksIn(Set<BoardTaskStatus> statuses) =>
        tasks.values.where((t) => statuses.contains(_status(t))).length;
    return BoardCounts(
      ideas: open(BoardPostKind.idea),
      bugs: open(BoardPostKind.bug),
      upForGrabs: tasksIn({BoardTaskStatus.published}),
      claimed: tasksIn({BoardTaskStatus.claimed, BoardTaskStatus.inReview}),
    );
  }

  @override
  Future<BoardPostView> getPost(int number) async {
    _log('getPost $number');
    return _view(_post(number));
  }

  List<BoardCommentView> _commentsWhere(bool Function(FakeBoardComment) test) {
    final rows =
        [
          for (final c in comments.values)
            if (test(c) &&
                (c.moderation == BoardModeration.visible ||
                    isAdmin ||
                    (userId != null && c.authorId == userId)))
              c,
        ]..sort((a, b) {
          final t = a.createdAt.compareTo(b.createdAt);
          return t != 0 ? t : a.uuid.uuid.compareTo(b.uuid.uuid);
        });
    return [for (final c in rows) _commentView(c)];
  }

  @override
  Future<List<BoardCommentView>> listComments(int number) async {
    _log('listComments $number');
    _post(number);
    return _commentsWhere((c) => c.postNumber == number);
  }

  @override
  Future<List<BoardCommentView>> listTaskComments(int number) async {
    _log('listTaskComments $number');
    _task(number);
    // A task's activity rows are for admins only.
    if (!isAdmin) return const [];
    return _commentsWhere((c) => c.taskNumber == number);
  }

  @override
  Future<List<BoardSimilarPost>> similar(
    String title,
    String body,
    BoardPostKind? kind,
  ) async {
    _log('similar $title');
    final words = {
      for (final w in '$title $body'.toLowerCase().split(RegExp(r'\W+')))
        if (w.length > 3) w,
    };
    return [
      for (final p in posts.values)
        if (p.moderation == BoardModeration.visible &&
            p.deletedAt == null &&
            (kind == null || p.kind == kind) &&
            words.any((w) => p.title.toLowerCase().contains(w)))
          BoardSimilarPost(
            number: p.number,
            kind: p.kind,
            title: p.title,
            status: p.status,
            score: _score(p),
            myVote: userId == null ? 0 : p.votes[userId] ?? 0,
          ),
    ].take(5).toList();
  }

  @override
  Future<String?> getScreenshotUrl(int number) async {
    _log('getScreenshotUrl $number');
    final p = _post(number);
    return p.hasScreenshot
        ? 'https://files.example.test/board/$number.png'
        : null;
  }

  @override
  Future<BoardTaskPage> listTasks(
    List<BoardTaskStatus> statuses, {
    String? cursor,
    int limit = 30,
  }) async {
    _log('listTasks ${statuses.map((s) => s.name).join(',')}');
    final wanted = statuses.isEmpty
        ? const {
            BoardTaskStatus.published,
            BoardTaskStatus.claimed,
            BoardTaskStatus.inReview,
          }
        : statuses.toSet();
    final rows = [
      for (final t in tasks.values.toList().reversed)
        if (wanted.contains(_status(t)) &&
            (_status(t) != BoardTaskStatus.draft || isAdmin))
          t,
    ];
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final page = rows.skip(offset).take(limit).toList();
    final next = offset + page.length;
    return BoardTaskPage(
      items: [for (final t in page) _taskView(t)],
      nextCursor: next < rows.length ? '$next' : null,
    );
  }

  @override
  Future<BoardTaskView> getTask(int number) async {
    _log('getTask $number');
    return _taskView(_task(number));
  }

  @override
  Stream<BoardPostEvent> watchPost(int number) =>
      _postEvents.stream.where((e) => e.number == number);

  @override
  Stream<BoardPostEvent> watchTasks() => _taskEvents.stream;

  // --------------------------------------------------------------- write

  @override
  Future<FileUploadTicket> createScreenshotUpload(
    UuidValue fileUuid,
    String mimeType,
    int size,
  ) async {
    _log('createScreenshotUpload');
    _writer();
    return FileUploadTicket(
      fileUuid: fileUuid,
      status: StoredFileStatus.pending,
    );
  }

  @override
  Future<BoardPostView> createPost(BoardPostDraft draft) async {
    _log('createPost ${draft.title}');
    _writer();
    final p = seedPost(
      title: draft.title,
      body: draft.body,
      kind: draft.kind,
      authorId: userId,
      area: null,
      size: null,
      hasScreenshot: draft.screenshotFileUuid != null,
      contextJson: draft.contextJson,
      createdAt: clock.now(),
    );
    p.votes[userId!] = 1;
    return _view(p);
  }

  @override
  Future<BoardPostView> editPost(int number, String title, String body) async {
    _log('editPost $number');
    _writer();
    final p = _post(number);
    if (p.authorId != userId) {
      throw _err(WonkyErrorCode.forbidden, 'Only the author can edit.');
    }
    p
      ..title = title
      ..body = body
      ..editedAt = clock.now();
    return _view(p);
  }

  @override
  Future<void> deletePost(int number) async {
    _log('deletePost $number');
    _writer();
    final p = _post(number);
    if (p.authorId != userId) {
      throw _err(WonkyErrorCode.forbidden, 'Only the author can delete.');
    }
    p.deletedAt = clock.now();
  }

  @override
  Future<BoardPostView> restorePost(int number) async {
    _log('restorePost $number');
    _writer();
    final p = _post(number);
    p.deletedAt = null;
    return _view(p);
  }

  @override
  Future<BoardPostView> removeScreenshot(int number) async {
    _log('removeScreenshot $number');
    _writer();
    final p = _post(number);
    p.hasScreenshot = false;
    return _view(p);
  }

  @override
  Future<BoardVoteResult> vote(int number, int value) async {
    _log('vote $number $value');
    _writer();
    final p = _post(number);
    if (value < -1 || value > 1) {
      throw _err(WonkyErrorCode.invalidArgument, 'Invalid vote.');
    }
    if (value == -1 && p.kind == BoardPostKind.bug) {
      throw _err(WonkyErrorCode.invalidArgument, 'Bugs take +1 only.');
    }
    if (p.status != BoardPostStatus.open &&
        p.status != BoardPostStatus.planned) {
      throw _err(WonkyErrorCode.conflict, 'Voting is closed.');
    }
    if (value == 0) {
      p.votes.remove(userId);
    } else {
      p.votes[userId!] = value;
    }
    return BoardVoteResult(
      number: number,
      score: _score(p),
      voteCount: p.votes.length,
      myVote: value,
    );
  }

  @override
  Future<BoardCommentView> addComment(
    UuidValue uuid, {
    int? postNumber,
    int? taskNumber,
    required String body,
  }) async {
    _log('addComment ${postNumber ?? 'T$taskNumber'}');
    _writer();
    if (comments[uuid.uuid] case final existing?) {
      return _commentView(existing);
    }
    if (taskNumber != null || postNumber == null) {
      throw _err(
        WonkyErrorCode.invalidArgument,
        'Tasks have no discussion: comment on a post.',
      );
    }
    _post(postNumber);
    final c = FakeBoardComment(
      uuid: uuid,
      postNumber: postNumber,
      taskNumber: taskNumber,
      authorId: userId,
      body: body,
      createdAt: clock.now(),
    );
    comments[uuid.uuid] = c;
    return _commentView(c);
  }

  @override
  Future<BoardCommentView> editComment(UuidValue uuid, String body) async {
    _log('editComment');
    _writer();
    final c = _comment(uuid);
    if (c.authorId != userId) {
      throw _err(WonkyErrorCode.forbidden, 'Only the author can edit.');
    }
    c
      ..body = body
      ..editedAt = clock.now();
    return _commentView(c);
  }

  @override
  Future<void> deleteComment(UuidValue uuid) async {
    _log('deleteComment');
    _writer();
    final c = _comment(uuid);
    if (c.authorId != userId && !isAdmin) {
      throw _err(WonkyErrorCode.forbidden, 'Not your comment.');
    }
    c.deleted = true;
  }

  @override
  Future<BoardCommentView> restoreComment(UuidValue uuid) async {
    _log('restoreComment');
    _writer();
    final c = _comment(uuid)..deleted = false;
    return _commentView(c);
  }

  @override
  Future<void> flag({
    int? number,
    UuidValue? commentUuid,
    required BoardFlagReason reason,
    String? note,
  }) async {
    _log('flag ${number ?? commentUuid?.uuid} ${reason.name}');
    _writer();
    final key = number != null
        ? 'post:$number'
        : 'comment:${commentUuid!.uuid}';
    (flags[key] ??= {})[userId!] = (reason, note);
  }

  @override
  Future<void> unflag({int? number, UuidValue? commentUuid}) async {
    _log('unflag ${number ?? commentUuid?.uuid}');
    _writer();
    final key = number != null
        ? 'post:$number'
        : 'comment:${commentUuid!.uuid}';
    flags[key]?.remove(userId);
  }

  @override
  Future<BoardTaskView> claimTask(int number) async {
    _log('claimTask $number');
    _writer();
    final t = _task(number);
    if (_status(t) != BoardTaskStatus.published) {
      throw _err(WonkyErrorCode.conflict, 'This task is already claimed.');
    }
    final active = tasks.values
        .where((x) => x.claimedById == userId && _claimValid(x))
        .length;
    if (active >= 2) {
      throw _err(WonkyErrorCode.limitExceeded, 'You have 2 active claims.');
    }
    t
      ..status = BoardTaskStatus.claimed
      ..claimedById = userId
      ..claimedAt = clock.now()
      ..claimExpiresAt = clock.now().add(const Duration(hours: 48))
      ..claimCode = _code();
    _system(number, 'claimed');
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> releaseTask(int number) async {
    _log('releaseTask $number');
    _writer();
    final t = _task(number);
    if (!_claimValid(t)) {
      throw _err(WonkyErrorCode.conflict, 'The task is not claimed.');
    }
    if (t.claimedById != userId && !isAdmin) {
      throw _err(WonkyErrorCode.forbidden, 'Not your claim.');
    }
    t
      ..status = BoardTaskStatus.published
      ..claimedById = null
      ..claimedAt = null
      ..claimExpiresAt = null
      ..claimCode = null;
    _system(number, 'released');
    return _taskView(t);
  }

  // --------------------------------------------------------------- admin

  @override
  Future<BoardReviewCounts> reviewCounts() async {
    _log('reviewCounts');
    _admin();
    int n(BoardReviewSection s) => _review(s).length;
    return BoardReviewCounts(
      held: n(BoardReviewSection.held),
      check: n(BoardReviewSection.check),
      unchecked: n(BoardReviewSection.unchecked),
      duplicates: n(BoardReviewSection.duplicates),
      drafts: n(BoardReviewSection.drafts),
      suggestions: suggestions.length,
    );
  }

  List<BoardReviewItem> _review(BoardReviewSection s) {
    final live = [
      for (final p in posts.values)
        if (p.deletedAt == null) p,
    ];
    BoardReviewItem post(FakeBoardPost p) =>
        BoardReviewItem(section: s, post: _view(p));
    return switch (s) {
      BoardReviewSection.held => [
        for (final p in live)
          if (p.moderation == BoardModeration.held) post(p),
        for (final c in comments.values)
          if (c.moderation == BoardModeration.held && !c.deleted)
            BoardReviewItem(section: s, comment: _commentView(c)),
      ],
      BoardReviewSection.check => [
        for (final p in live)
          if (p.needsCheck && p.moderation == BoardModeration.visible) post(p),
      ],
      BoardReviewSection.unchecked => [
        for (final p in live)
          if (p.triageState == BoardTriageState.unchecked) post(p),
      ],
      BoardReviewSection.duplicates => [
        for (final p in live)
          if (p.possibleDuplicateOf != null && p.duplicateOf == null) post(p),
      ],
      BoardReviewSection.drafts => [
        for (final t in tasks.values)
          if (t.status == BoardTaskStatus.draft)
            BoardReviewItem(section: s, task: _taskView(t)),
      ],
    };
  }

  @override
  Future<List<BoardReviewItem>> reviewQueue(BoardReviewSection section) async {
    _log('reviewQueue ${section.name}');
    _admin();
    return _review(section);
  }

  @override
  Future<BoardPostView> moderatePost(
    int number,
    BoardModerationAction action, {
    String? reason,
  }) async {
    _log('moderatePost $number ${action.name}');
    _admin();
    final p = _post(number);
    switch (action) {
      case BoardModerationAction.approve:
        p
          ..moderation = BoardModeration.visible
          ..moderationReason = null
          ..needsCheck = false;
      case BoardModerationAction.hold:
        p
          ..moderation = BoardModeration.held
          ..moderationReason = reason ?? 'Waiting for review.';
      case BoardModerationAction.remove:
        p
          ..moderation = BoardModeration.removed
          ..moderationReason = reason ?? 'Removed by a moderator.';
      case BoardModerationAction.restore:
        if (p.moderation != BoardModeration.removed) {
          throw _err(WonkyErrorCode.conflict, 'Only removed posts.');
        }
        p
          ..moderation = BoardModeration.visible
          ..moderationReason = null;
      case BoardModerationAction.removeScreenshot:
        p.hasScreenshot = false;
      case BoardModerationAction.markChecked:
        p.needsCheck = false;
        if (p.triageState == BoardTriageState.unchecked) {
          p.triageState = BoardTriageState.done;
        }
    }
    return _view(p);
  }

  @override
  Future<BoardCommentView> moderateComment(
    UuidValue uuid,
    BoardModerationAction action, {
    String? reason,
  }) async {
    _log('moderateComment ${action.name}');
    _admin();
    final c = _comment(uuid);
    switch (action) {
      case BoardModerationAction.approve:
      case BoardModerationAction.restore:
        c
          ..moderation = BoardModeration.visible
          ..moderationReason = null;
      case BoardModerationAction.hold:
        c.moderation = BoardModeration.held;
      case BoardModerationAction.remove:
        c
          ..moderation = BoardModeration.removed
          ..moderationReason = reason;
      case BoardModerationAction.markChecked:
      case BoardModerationAction.removeScreenshot:
        c.needsCheck = false;
    }
    return _commentView(c);
  }

  @override
  Future<BoardPostView> adminEditPost(
    int number,
    String title,
    String body,
  ) async {
    _log('adminEditPost $number');
    _admin();
    final p = _post(number)
      ..title = title
      ..body = body
      ..editedByModerator = true
      ..editedAt = clock.now();
    return _view(p);
  }

  @override
  Future<BoardPostView> setLabels(
    int number,
    BoardPostKind kind,
    BoardArea? area,
    BoardSize? size,
  ) async {
    _log('setLabels $number ${kind.name} ${area?.name} ${size?.name}');
    _admin();
    final p = _post(number)
      ..kind = kind
      ..area = area
      ..size = size
      ..aiLabels = false;
    return _view(p);
  }

  @override
  Future<BoardPostView> applySuggestedTitle(int number) async {
    _log('applySuggestedTitle $number');
    _admin();
    final p = _post(number);
    final t = p.suggestedTitle;
    if (t == null) throw _err(WonkyErrorCode.conflict, 'No suggestion.');
    p
      ..title = t
      ..suggestedTitle = null;
    return _view(p);
  }

  @override
  Future<BoardPostView> dismissDuplicateHint(int number) async {
    _log('dismissDuplicateHint $number');
    _admin();
    final p = _post(number)..possibleDuplicateOf = null;
    return _view(p);
  }

  @override
  Future<BoardPostView> merge(int source, int target) async {
    _log('merge $source $target');
    _admin();
    final s = _post(source);
    final t = _post(target);
    if (source == target) {
      throw _err(WonkyErrorCode.invalidArgument, 'Same post.');
    }
    final moved = <int, int>{};
    for (final e in s.votes.entries) {
      if (!t.votes.containsKey(e.key)) {
        t.votes[e.key] = e.value;
        moved[e.key] = e.value;
      }
    }
    t.movedVotes[source] = moved;
    s
      ..status = BoardPostStatus.duplicate
      ..duplicateOf = target
      ..possibleDuplicateOf = null;
    return _view(s);
  }

  @override
  Future<BoardPostView> unmerge(int source) async {
    _log('unmerge $source');
    _admin();
    final s = _post(source);
    final target = s.duplicateOf;
    if (target == null) {
      throw _err(WonkyErrorCode.conflict, 'Not merged.');
    }
    final t = posts[target]!;
    for (final e in (t.movedVotes.remove(source) ?? const {}).entries) {
      t.votes.remove(e.key);
    }
    s
      ..status = BoardPostStatus.open
      ..duplicateOf = null;
    return _view(s);
  }

  @override
  Future<BoardPostView> decline(int number, String reason) async {
    _log('decline $number $reason');
    _admin();
    final p = _post(number)
      ..status = BoardPostStatus.declined
      ..declineReason = reason;
    return _view(p);
  }

  @override
  Future<BoardPostView> reopen(int number) async {
    _log('reopen $number');
    _admin();
    final p = _post(number)
      ..status = BoardPostStatus.open
      ..declineReason = null;
    return _view(p);
  }

  @override
  Future<void> blockUser(int userId, String reason, {DateTime? until}) async {
    _log('blockUser $userId');
    _admin();
    blockedUsers[userId] = reason;
  }

  @override
  Future<void> unblockUser(int userId) async {
    _log('unblockUser $userId');
    _admin();
    blockedUsers.remove(userId);
  }

  @override
  Future<BoardTaskView> createTask(
    List<int> postNumbers,
    String title,
    BoardArea area,
    BoardSize size,
  ) async {
    _log('createTask ${postNumbers.join(',')}');
    _admin();
    final t = seedTask(
      title: title,
      area: area,
      size: size,
      status: BoardTaskStatus.draft,
      promptBody: writesPromptLater ? '## Goal\n' : '## Goal\n$title',
      posts: postNumbers,
    );
    t.promptPending = writesPromptLater;
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> updateTask(
    int number,
    String title,
    BoardArea area,
    BoardSize size,
  ) async {
    _log('updateTask $number');
    _admin();
    final t = _task(number)
      ..title = title
      ..area = area
      ..size = size;
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> setTaskPosts(int number, List<int> postNumbers) async {
    _log('setTaskPosts $number ${postNumbers.join(',')}');
    _admin();
    final t = _task(number);
    for (final n in t.posts) {
      if (!postNumbers.contains(n)) {
        posts[n]
          ?..taskNumber = null
          ..status = BoardPostStatus.open;
      }
    }
    t.posts
      ..clear()
      ..addAll(postNumbers);
    for (final n in postNumbers) {
      posts[n]?.taskNumber = number;
    }
    _rewritePrompt(t);
    return _taskView(t);
  }

  /// Like the server after the issues of [t] changed: the prompt is
  /// rewritten, and a published task waits as a draft while
  /// [writesPromptLater]; [finishPrompt] publishes it again.
  void _rewritePrompt(FakeBoardTask t) {
    if (!writesPromptLater) {
      t.promptBody = '## Goal\n${t.title}';
      _syncPosts(t);
      return;
    }
    t
      ..promptPending = true
      ..promptNote = null;
    if (_status(t) == BoardTaskStatus.published) {
      t
        ..status = BoardTaskStatus.draft
        ..claimedById = null
        ..claimedAt = null
        ..claimExpiresAt = null
        ..claimCode = null;
    }
  }

  /// The tasks a merge replaced: `{target: [snapshots of all tasks]}`.
  final Map<int, List<Map<String, Object?>>> _merges = {};

  @override
  Future<BoardTaskView> mergeTasks(
    List<int> numbers,
    String title,
    BoardArea area,
    BoardSize size,
  ) async {
    _log('mergeTasks ${numbers.join(',')}');
    _admin();
    final ids = numbers.toSet().toList()..sort();
    if (ids.length < 2) {
      throw _err(WonkyErrorCode.invalidArgument, 'Select at least two.');
    }
    final tasks = [for (final n in ids) _task(n)];
    for (final t in tasks) {
      final s = _status(t);
      if (s != BoardTaskStatus.draft && s != BoardTaskStatus.published) {
        throw _err(WonkyErrorCode.conflict, 'T-${t.number} is claimed.');
      }
    }
    _merges[ids.first] = [
      for (final t in tasks)
        {
          'number': t.number,
          'status': _status(t),
          'title': t.title,
          'area': t.area,
          'size': t.size,
          'promptBody': t.promptBody,
          'posts': [...t.posts],
        },
    ];
    final target = tasks.first;
    for (final s in tasks.skip(1)) {
      for (final n in s.posts) {
        posts[n]?.taskNumber = target.number;
      }
      target.posts.addAll(s.posts);
      s.posts.clear();
      s
        ..status = BoardTaskStatus.cancelled
        ..mergedInto = target.number;
    }
    target
      ..title = title
      ..area = area
      ..size = size;
    _rewritePrompt(target);
    return _taskView(target);
  }

  @override
  Future<BoardTaskView> unmergeTasks(int number) async {
    _log('unmergeTasks $number');
    _admin();
    final before = _merges.remove(number);
    if (before == null) {
      throw _err(WonkyErrorCode.conflict, 'No merge to undo.');
    }
    for (final m in before) {
      final t = _task(m['number']! as int)
        ..status = m['status']! as BoardTaskStatus
        ..title = m['title']! as String
        ..area = m['area']! as BoardArea
        ..size = m['size']! as BoardSize
        ..promptBody = m['promptBody']! as String
        ..promptPending = false
        ..mergedInto = null;
      final own = m['posts']! as List<int>;
      if (t.number == number) {
        t.posts.removeWhere((n) => !own.contains(n));
      } else {
        t.posts
          ..clear()
          ..addAll(own);
        for (final n in own) {
          posts[n]?.taskNumber = t.number;
        }
      }
      _syncPosts(t);
    }
    return _taskView(_task(number));
  }

  @override
  Future<BoardTaskView> regeneratePrompt(int number) async {
    _log('regeneratePrompt $number');
    _admin();
    final t = _task(number);
    if (writesPromptLater) {
      t
        ..promptPending = true
        ..promptNote = null;
    } else {
      t.promptBody = '## Goal\nRegenerated.';
    }
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> setPrompt(int number, String body) async {
    _log('setPrompt $number');
    _admin();
    final t = _task(number)
      ..promptBody = body
      ..promptEditedAt = clock.now()
      ..promptPending = false
      ..promptNote = null;
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> publishTask(int number) async {
    _log('publishTask $number');
    _admin();
    final t = _task(number);
    if (t.status != BoardTaskStatus.draft) {
      throw _err(WonkyErrorCode.conflict, 'Only draft tasks.');
    }
    if (t.promptPending) {
      throw _err(WonkyErrorCode.conflict, 'The prompt is still being written.');
    }
    t
      ..status = BoardTaskStatus.published
      ..publishedAt = clock.now();
    _syncPosts(t);
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> setTaskStatus(
    int number,
    BoardTaskStatus status,
  ) async {
    _log('setTaskStatus $number ${status.name}');
    _admin();
    final t = _task(number);
    final keep = {
      BoardTaskStatus.claimed,
      BoardTaskStatus.inReview,
      BoardTaskStatus.done,
      BoardTaskStatus.shipped,
    }.contains(status);
    t.status = status;
    if (!keep) {
      t
        ..claimedById = null
        ..claimExpiresAt = null
        ..claimCode = null;
    }
    if (status == BoardTaskStatus.draft) t.publishedAt = null;
    if (status != BoardTaskStatus.cancelled) {
      for (final n in t.posts) {
        posts[n]?.taskNumber = number;
      }
    }
    _syncPosts(t);
    return _taskView(t);
  }

  @override
  Future<BoardTaskView> linkPullRequest(int number, String? url) async {
    _log('linkPullRequest $number $url');
    _admin();
    final t = _task(number);
    if (url == null || url.isEmpty) {
      t
        ..pullRequestUrl = null
        ..prNumber = null
        ..status = _claimValid(t)
            ? BoardTaskStatus.claimed
            : BoardTaskStatus.published;
    } else {
      final m = RegExp(
        r'^https://github\.com/serverpod/wonky/pull/(\d+)/?$',
      ).firstMatch(url);
      if (m == null) {
        throw _err(WonkyErrorCode.invalidArgument, 'Not a pull request URL.');
      }
      t
        ..pullRequestUrl = url
        ..prNumber = int.parse(m[1]!)
        ..status = BoardTaskStatus.inReview;
    }
    return _taskView(t);
  }

  @override
  Future<List<BoardBundleSuggestionView>> suggestBundles() async {
    _log('suggestBundles');
    _admin();
    return [...suggestions];
  }

  @override
  Future<List<BoardBundleSuggestionView>> listSuggestions() async {
    _log('listSuggestions');
    _admin();
    return [...suggestions];
  }

  @override
  Future<void> dismissSuggestion(int id) async {
    _log('dismissSuggestion $id');
    _admin();
    suggestions.removeWhere((s) => s.id == id);
  }
}
