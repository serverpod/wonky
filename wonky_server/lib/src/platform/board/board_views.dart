import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../common/time.dart';
import '../notifications/notification_service.dart';
import '../users/user_service.dart';
import 'ai/board_ai.dart';
import 'ai/task_prompt_template.dart';
import 'board_access.dart';
import 'board_admins.dart';
import 'board_config.dart';
import 'board_tasks.dart';
import 'board_triage.dart';

/// Builds the client views of the board. Views never contain emails;
/// admin-only fields are null (or false) for everyone else (specs/16 §11).
abstract final class BoardViews {
  // --------------------------------------------------------------- authors

  static Future<Map<int, BoardAuthor>> authors(
    Session session,
    Iterable<int?> userIds,
  ) async {
    final ids = userIds.whereType<int>().toSet();
    if (ids.isEmpty) return const {};
    final summaries = await UserService.summaries(session, ids);
    final admins = await BoardAdmins.adminsAmong(session, ids);
    return {
      for (final s in summaries.values)
        s.id: BoardAuthor(
          id: s.id,
          displayName: s.displayName,
          avatarUrl: s.avatarUrl,
          avatarColor: s.avatarColor,
          colorIndex: s.colorIndex,
          isAdmin: admins.contains(s.id),
        ),
    };
  }

  // ----------------------------------------------------------------- claims

  /// Whether [task] holds a claim that has not expired (computed on every
  /// read, specs/16 §8.2). `inReview` claims don't expire.
  static bool claimValid(BoardTask task, [DateTime? now]) {
    if (task.claimedById == null) return false;
    if (task.status == BoardTaskStatus.inReview) return true;
    return task.status == BoardTaskStatus.claimed &&
        task.claimExpiresAt != null &&
        task.claimExpiresAt!.isAfter(now ?? nowUtc());
  }

  /// The status a task shows: an expired claim is `published`.
  static BoardTaskStatus effectiveStatus(BoardTask task, [DateTime? now]) =>
      task.status == BoardTaskStatus.claimed && !claimValid(task, now)
      ? BoardTaskStatus.published
      : task.status;

  // ------------------------------------------------------------------ posts

  static Future<Map<int, int>> myVotes(
    Session session,
    BoardCaller c,
    Iterable<int> postIds,
  ) async {
    final ids = postIds.toSet();
    if (!c.signedIn || ids.isEmpty) return const {};
    final votes = await BoardVote.db.find(
      session,
      where: (t) => t.userId.equals(c.userId) & t.postId.inSet(ids),
    );
    return {for (final v in votes) v.postId: v.value};
  }

  static Future<Map<int, BoardTask>> _tasks(
    Session session,
    Iterable<BoardPost> posts,
  ) async {
    final ids = {for (final p in posts) ?p.taskId};
    if (ids.isEmpty) return const {};
    final tasks = await BoardTask.db.find(
      session,
      where: (t) => t.id.inSet(ids),
    );
    return {for (final t in tasks) t.id!: t};
  }

  static BoardTaskRef? _taskRef(BoardCaller c, BoardTask? task) {
    if (task == null || task.status == BoardTaskStatus.cancelled) return null;
    if (!BoardAccess.canSeeTask(c, task)) return null;
    return BoardTaskRef(
      number: task.id!,
      title: task.title,
      status: effectiveStatus(task),
    );
  }

  static Future<List<BoardPostListItem>> listItems(
    Session session,
    BoardCaller c,
    List<BoardPost> posts,
  ) async {
    if (posts.isEmpty) return const [];
    final votes = await myVotes(session, c, posts.map((p) => p.id!));
    final authors = await BoardViews.authors(
      session,
      posts.map((p) => p.authorId),
    );
    final tasks = await _tasks(session, posts);
    return [
      for (final p in posts)
        BoardPostListItem(
          number: p.id!,
          kind: p.kind,
          area: p.area,
          size: p.size,
          aiLabels: p.aiLabels,
          title: p.title,
          status: p.status,
          moderation: p.moderation,
          needsCheck: c.isAdmin && p.needsCheck,
          score: p.score,
          voteCount: p.voteCount,
          commentCount: p.commentCount,
          myVote: votes[p.id] ?? 0,
          author: authors[p.authorId],
          isMine: c.isAuthor(p.authorId),
          hasScreenshot: p.screenshotFileId != null,
          task: _taskRef(c, tasks[p.taskId]),
          createdAt: p.createdAt,
        ),
    ];
  }

  static bool canEdit(BoardCaller c, BoardPost p, BoardTask? task) =>
      c.isAuthor(p.authorId) &&
      p.deletedAt == null &&
      p.status == BoardPostStatus.open &&
      p.moderation != BoardModeration.removed &&
      (task == null || task.status == BoardTaskStatus.cancelled);

  static Future<BoardPostView> post(
    Session session,
    BoardCaller c,
    BoardPost p,
  ) async {
    final votes = await myVotes(session, c, [p.id!]);
    final merged = await BoardPost.db.find(
      session,
      where: (t) => t.duplicateOfId.equals(p.id!),
      orderBy: (t) => t.id,
    );
    final flags = c.isAdmin
        ? await BoardFlag.db.find(
            session,
            where: (t) => t.postId.equals(p.id!),
            orderBy: (t) => t.createdAt,
          )
        : const <BoardFlag>[];
    final authors = await BoardViews.authors(session, [
      p.authorId,
      for (final f in flags) f.userId,
    ]);
    final task = p.taskId == null
        ? null
        : await BoardTask.db.findById(session, p.taskId!);
    final mine = c.isAuthor(p.authorId);
    return BoardPostView(
      number: p.id!,
      kind: p.kind,
      reportedKind: p.reportedKind,
      area: p.area,
      size: p.size,
      aiLabels: p.aiLabels,
      title: p.title,
      body: p.body,
      contextJson: p.contextJson,
      appHint: p.appHint,
      hasScreenshot: p.screenshotFileId != null,
      status: p.status,
      moderation: p.moderation,
      moderationReason: c.isAdmin || mine ? p.moderationReason : null,
      editedByModerator: p.editedByModerator,
      triageState: p.triageState,
      summary: p.summary,
      duplicateOfNumber: p.duplicateOfId,
      declineReason: p.declineReason,
      task: _taskRef(c, task),
      mergedFrom: [
        for (final m in merged)
          if (BoardAccess.canSeePost(c, m)) m.id!,
      ],
      score: p.score,
      voteCount: p.voteCount,
      commentCount: p.commentCount,
      myVote: votes[p.id] ?? 0,
      author: authors[p.authorId],
      isMine: mine,
      canEdit: canEdit(c, p, task),
      createdAt: p.createdAt,
      editedAt: p.editedAt,
      deleted: p.deletedAt != null,
      needsCheck: c.isAdmin && p.needsCheck,
      suggestedTitle: c.isAdmin ? p.suggestedTitle : null,
      possibleDuplicateOfNumber: c.isAdmin && !p.duplicateHintDismissed
          ? p.possibleDuplicateOfId
          : null,
      triageJson: c.isAdmin ? p.triageJson : null,
      reviewScores: c.isAdmin ? reviewScores(p.triageJson) : null,
      flags: c.isAdmin ? _flagViews(flags, authors) : null,
    );
  }

  /// The moderation scores of [triageJson] at or above their review band
  /// under the current thresholds (specs/16 §6.2), best first.
  static Map<String, double>? reviewScores(String? triageJson) {
    if (triageJson == null) return null;
    Map<dynamic, dynamic> raw;
    try {
      raw = (jsonDecode(triageJson) as Map)['scores'] as Map;
    } on Object {
      return null;
    }
    double v(String k) => switch (raw[k]) {
      final num x => x.toDouble(),
      _ => 0,
    };
    final scores = BoardModerationScores(
      offensive: v('offensive'),
      spam: v('spam'),
      notActionable: v('not_actionable'),
      offTopic: v('off_topic'),
      personalData: v('personal_data'),
      security: v('security'),
    );
    final bands = moderationBands(
      scores,
      BoardConfig.current.ai.thresholds,
    );
    final all = scores.toJson();
    final ids = [...bands.hold, ...bands.review]
      ..sort((a, b) => all[b]!.compareTo(all[a]!));
    return {for (final id in ids) id: all[id]!};
  }

  static List<BoardFlagView> _flagViews(
    List<BoardFlag> flags,
    Map<int, BoardAuthor> authors,
  ) => [
    for (final f in flags)
      BoardFlagView(
        reason: f.reason,
        note: f.note,
        by: authors[f.userId],
        createdAt: f.createdAt,
      ),
  ];

  // --------------------------------------------------------------- comments

  static Future<List<BoardCommentView>> comments(
    Session session,
    BoardCaller c,
    List<BoardComment> comments,
  ) async {
    if (comments.isEmpty) return const [];
    final flags = c.isAdmin
        ? await BoardFlag.db.find(
            session,
            where: (t) =>
                t.commentId.inSet(<int>{for (final x in comments) x.id!}),
            orderBy: (t) => t.createdAt,
          )
        : const <BoardFlag>[];
    final authors = await BoardViews.authors(session, [
      for (final x in comments) x.authorId,
      for (final f in flags) f.userId,
    ]);
    final flagsBy = <int, List<BoardFlag>>{};
    for (final f in flags) {
      flagsBy.putIfAbsent(f.commentId!, () => []).add(f);
    }
    return [
      for (final x in comments)
        () {
          final mine = c.isAuthor(x.authorId);
          final hidden =
              x.deletedAt != null ||
              (x.moderation == BoardModeration.removed && !c.isAdmin && !mine);
          return BoardCommentView(
            uuid: x.uuid,
            postNumber: x.postId,
            taskNumber: x.taskId,
            author: authors[x.authorId],
            body: hidden ? '' : x.body,
            systemEvent: x.systemEvent,
            moderation: x.moderation,
            moderationReason: c.isAdmin || mine ? x.moderationReason : null,
            isMine: mine,
            createdAt: x.createdAt,
            editedAt: x.editedAt,
            deleted: x.deletedAt != null,
            needsCheck: c.isAdmin && x.needsCheck,
            flags: c.isAdmin ? _flagViews(flagsBy[x.id] ?? [], authors) : null,
          );
        }(),
    ];
  }

  // ------------------------------------------------------------------ tasks

  static Future<List<BoardTaskView>> tasks(
    Session session,
    BoardCaller c,
    List<BoardTask> tasks,
  ) async {
    if (tasks.isEmpty) return const [];
    final now = nowUtc();
    final ids = {for (final t in tasks) t.id!};
    final posts = await BoardPost.db.find(
      session,
      where: (t) => t.taskId.inSet(ids) & t.deletedAt.equals(null),
      orderBy: (t) => t.score.desc(),
    );
    final visiblePosts = [
      for (final p in posts)
        if (BoardAccess.canSeePost(c, p)) p,
    ];
    final items = await listItems(session, c, visiblePosts);
    final itemsByTask = <int, List<BoardPostListItem>>{};
    for (var i = 0; i < visiblePosts.length; i++) {
      itemsByTask.putIfAbsent(visiblePosts[i].taskId!, () => []).add(items[i]);
    }
    final postsByTask = <int, List<BoardPost>>{};
    for (final p in posts) {
      postsByTask.putIfAbsent(p.taskId!, () => []).add(p);
    }
    final prNumbers = {for (final t in tasks) ?t.prNumber};
    final prs = prNumbers.isEmpty
        ? const <BoardPullRequest>[]
        : await BoardPullRequest.db.find(
            session,
            where: (t) => t.prNumber.inSet(prNumbers),
          );
    final reviewByPr = {for (final p in prs) p.prNumber: p.lastReviewJson};
    final authors = await BoardViews.authors(session, [
      for (final t in tasks) ...[t.claimedById, t.promptEditedById],
    ]);
    final config = BoardConfig.current;
    final origin = NotificationService.webOrigin();
    // A merged task (specs/16 §9.3) is cancelled with a *Merged into T-n*
    // row; the latest one counts.
    final cancelled = {
      for (final t in tasks)
        if (t.status == BoardTaskStatus.cancelled) t.id!,
    };
    final mergedInto = <int, int>{
      if (cancelled.isNotEmpty)
        for (final r in await BoardComment.db.find(
          session,
          where: (t) =>
              t.taskId.inSet(cancelled) & t.systemEvent.equals('mergedInto'),
          orderBy: (t) => t.id,
        ))
          r.taskId!: ?int.tryParse(r.body.replaceAll(RegExp(r'\D'), '')),
    };
    return [
      for (final t in tasks)
        () {
          final valid = claimValid(t, now);
          final mine = valid && c.isAuthor(t.claimedById);
          // The prompt is for the claimant (with their claim code in its PR
          // lines) and admins (with the placeholder) only: everyone else
          // claims the task to get it (specs/16 §4.6, §10.1).
          final seesPrompt = mine || c.isAdmin;
          return BoardTaskView(
            number: t.id!,
            title: t.title,
            area: t.area,
            size: t.size,
            status: effectiveStatus(t, now),
            promptBody: seesPrompt ? t.promptBody : '',
            prompt: seesPrompt
                ? TaskPromptTemplate.wrap(
                    task: t,
                    posts: postsByTask[t.id] ?? const [],
                    body: t.promptBody,
                    webOrigin: origin,
                    repository: config.repository,
                    claimCode: mine ? t.claimCode : null,
                  )
                : '',
            promptGeneratedAt: t.promptGeneratedAt,
            promptPending: BoardTasks.promptPending(t, now),
            promptNote: c.isAdmin ? t.promptNote : null,
            promptEditedAt: t.promptEditedAt,
            promptEditedBy: authors[t.promptEditedById],
            posts: itemsByTask[t.id] ?? const [],
            claimedBy: valid ? authors[t.claimedById] : null,
            claimedAt: valid ? t.claimedAt : null,
            claimExpiresAt: valid && t.status == BoardTaskStatus.claimed
                ? t.claimExpiresAt
                : null,
            claimCode: mine ? t.claimCode : null,
            isMine: mine,
            pullRequestUrl: t.pullRequestUrl,
            prNumber: t.prNumber,
            prAuthorLogin: t.prAuthorLogin,
            reviewJson: t.prNumber == null ? null : reviewByPr[t.prNumber],
            mergedInto: mergedInto[t.id],
            publishedAt: t.publishedAt,
            doneAt: t.doneAt,
            shippedAt: t.shippedAt,
            createdAt: t.createdAt,
          );
        }(),
    ];
  }

  static Future<BoardTaskView> task(
    Session session,
    BoardCaller c,
    BoardTask task,
  ) async => (await tasks(session, c, [task])).single;
}
