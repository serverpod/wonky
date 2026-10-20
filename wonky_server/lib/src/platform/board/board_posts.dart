import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../files/file_service.dart';
import 'ai/board_ai.dart';
import 'board_access.dart';
import 'board_common.dart';
import 'board_config.dart';
import 'board_pipeline.dart';
import 'board_search.dart';
import 'board_task_claims.dart';
import 'board_views.dart';

/// Posts (specs/16 §4, §5.3, §6.4, §7): reading, the list and search,
/// similar posts, creating and editing, deleting, screenshots.
abstract final class BoardPosts {
  static const defaultPageSize = 30;
  static const maxPageSize = 50;
  static const maxContextJson = 20000;
  static final _appHint = RegExp(r'^[a-z]{1,20}$');

  // ------------------------------------------------------------------ read

  static Future<BoardMe> me(Session session) async {
    final c = await BoardAccess.caller(session);
    final config = BoardConfig.current;
    final ai = BoardAi.instance;
    if (!c.signedIn) {
      return BoardMe(
        signedIn: false,
        isAdmin: false,
        blocked: false,
        activeClaims: const [],
        aiChecks: ai.jevConfigured,
        repository: config.repository,
        securityContact: config.securityContact,
        claimHours: config.claimHours,
        maxActiveClaims: config.maxActiveClaimsPerUser,
      );
    }
    final claims = await BoardTask.db.find(
      session,
      where: (t) =>
          t.claimedById.equals(c.id) &
          t.status.equals(BoardTaskStatus.claimed) &
          (t.claimExpiresAt > nowUtc()),
      orderBy: (t) => t.id,
    );
    final profile = await BoardUserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(c.id),
    );
    final block = c.isAdmin
        ? null
        : await BoardTaskClaims.claimBlock(session, c.id);
    return BoardMe(
      signedIn: true,
      userId: c.id,
      isAdmin: c.isAdmin,
      blocked: c.blocked,
      blockedReason: c.blockedReason,
      activeClaims: [for (final t in claims) t.id!],
      githubLogin: profile?.githubLogin,
      aiChecks: ai.jevConfigured,
      repository: config.repository,
      securityContact: config.securityContact,
      claimHours: config.claimHours,
      maxActiveClaims: config.maxActiveClaimsPerUser,
      claimBlockedUntil: block?.until,
      claimBlockedReason: block?.message,
    );
  }

  /// Longest search text used (`list` query; `similar` title).
  static const maxQueryLength = 200;

  static String _clip(String s, int max) =>
      s.length <= max ? s : s.substring(0, max);

  static Future<BoardPostPage> list(Session session, BoardListQuery q) async {
    final c = await BoardAccess.caller(session);
    final query = q.query;
    if (query != null && query.trim().isNotEmpty) {
      if (!c.signedIn) await BoardRateLimits.checkSignedOut(session);
      if (query.length > maxQueryLength) {
        q = q.copyWith(query: _clip(query, maxQueryLength));
      }
    }
    final offset = int.tryParse(q.cursor ?? '')?.clamp(0, 1 << 30) ?? 0;
    final limit = q.limit <= 0
        ? defaultPageSize
        : q.limit.clamp(1, maxPageSize);
    final (ids, total) = await BoardSearch.list(
      session,
      c,
      q,
      offset: offset,
      limit: limit,
    );
    final posts = await BoardSearch.byIds(session, ids);
    return BoardPostPage(
      items: await BoardViews.listItems(session, c, posts),
      nextCursor: offset + ids.length < total ? '${offset + ids.length}' : null,
      total: total,
    );
  }

  static Future<BoardPostView> getPost(Session session, int number) async {
    final c = await BoardAccess.caller(session);
    final post = await BoardAccess.post(session, c, number);
    return BoardViews.post(session, c, post);
  }

  static Future<List<BoardSimilarPost>> similar(
    Session session, {
    required String title,
    required String body,
    BoardPostKind? kind,
  }) async {
    final c = await BoardAccess.caller(session);
    if (c.signedIn) {
      await BoardRateLimits.check(BoardLimit.similarPerMinute, c);
    } else {
      await BoardRateLimits.checkSignedOut(session);
    }
    // A draft's title and body: longer text adds nothing to the search.
    title = _clip(title, maxQueryLength);
    body = _clip(body, BoardText.maxBodyLength);
    final text = '$title ${BoardText.plain(body, max: 2000)}'.trim();
    if (text.isEmpty) return const [];
    var posts = await BoardSearch.similarPosts(
      session,
      text,
      kind: kind,
      limit: 10,
      // Only issues one can still vote for: done and shipped ones are
      // built (specs/16 §4.2.2).
      statuses: const [BoardPostStatus.open, BoardPostStatus.planned],
    );
    final ai = BoardAi.instance;
    if (posts.isNotEmpty && c.signedIn && await ai.jevAvailable(session)) {
      try {
        final ranked = await ai
            .rerankSimilar(
              session,
              title: title,
              body: body,
              candidates: posts,
            )
            .timeout(const Duration(seconds: 3));
        final min = BoardConfig.current.ai.thresholds.rerank;
        final byId = {for (final p in posts) p.id!: p};
        posts = [
          for (final (id, p) in ranked)
            if (p >= min && byId[id] != null) byId[id]!,
        ];
      } on Object catch (e) {
        session.log('board: rerank failed: $e', level: LogLevel.info);
      }
    }
    posts = posts.take(5).toList();
    final votes = await BoardViews.myVotes(session, c, posts.map((p) => p.id!));
    return [
      for (final p in posts)
        BoardSimilarPost(
          number: p.id!,
          kind: p.kind,
          title: p.title,
          status: p.status,
          score: p.score,
          myVote: votes[p.id] ?? 0,
        ),
    ];
  }

  // ------------------------------------------------------------ screenshots

  static Future<FileUploadTicket> createScreenshotUpload(
    Session session,
    UuidValue fileUuid,
    String mimeType,
    int size,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final mime = mimeType.toLowerCase().split(';').first.trim();
    return FileService.createUpload(
      session,
      c.actor!,
      fileUuid: fileUuid,
      fileName: mime == 'image/jpeg' ? 'screenshot.jpg' : 'screenshot.png',
      mimeType: mime,
      size: size,
      kind: StoredFileKind.boardScreenshot,
    );
  }

  static Future<String?> getScreenshotUrl(Session session, int number) async {
    final c = await BoardAccess.caller(session);
    final post = await BoardAccess.post(session, c, number);
    if (post.screenshotFileId == null) return null;
    final file = await StoredFile.db.findById(session, post.screenshotFileId!);
    if (file == null || file.status != StoredFileStatus.ready) return null;
    return (await FileService.viewOf(session, file)).url;
  }

  static Future<BoardPostView> removeScreenshot(
    Session session,
    int number,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final post = await BoardAccess.post(session, c, number);
    if (!c.isAdmin && !c.isAuthor(post.authorId)) throw Errors.forbidden();
    final updated = await deleteScreenshot(session, post);
    if (c.isAdmin && !c.isAuthor(post.authorId)) {
      await BoardLog.write(
        session,
        adminId: c.id,
        action: 'removeScreenshot',
        targetKind: BoardTargetKind.post,
        targetId: post.id!,
      );
    }
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  /// Deletes the screenshot bytes of [post] at once (specs/16 §5.3).
  static Future<BoardPost> deleteScreenshot(
    Session session,
    BoardPost post,
  ) async {
    final fileId = post.screenshotFileId;
    if (fileId == null) return post;
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(screenshotFileId: null),
      columns: (t) => [t.screenshotFileId],
    );
    final file = await StoredFile.db.findById(session, fileId);
    if (file != null) await FileService.deleteFile(session, file.fileUuid);
    return updated;
  }

  // ----------------------------------------------------------------- write

  static String? _context(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    if (json.length > maxContextJson) {
      throw Errors.invalid('The included details are too long.');
    }
    try {
      if (jsonDecode(json) is! Map) throw const FormatException();
    } on FormatException {
      throw Errors.invalid('The included details are not valid JSON.');
    }
    return json;
  }

  static Future<StoredFile?> _screenshot(
    Session session,
    BoardCaller c,
    UuidValue? uuid,
  ) async {
    if (uuid == null) return null;
    final file = await FileService.byUuid(session, uuid);
    if (file == null ||
        file.ownerId != c.id ||
        file.kind != StoredFileKind.boardScreenshot) {
      throw Errors.notFound('Screenshot');
    }
    if (file.status != StoredFileStatus.ready) {
      throw Errors.invalid('The screenshot upload is not complete.');
    }
    final used = await BoardPost.db.count(
      session,
      where: (t) => t.screenshotFileId.equals(file.id!),
    );
    if (used > 0) {
      throw Errors.conflict('This screenshot is already attached to an issue.');
    }
    return file;
  }

  static Future<BoardPostView> createPost(
    Session session,
    BoardPostDraft draft,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final title = BoardText.title(draft.title);
    final body = BoardText.body(draft.body, what: 'description');
    final appHint = draft.appHint.trim().toLowerCase();
    if (!_appHint.hasMatch(appHint)) {
      throw Errors.invalid('Unknown app "${draft.appHint}".');
    }
    final contextJson = _context(draft.contextJson);
    final screenshot = await _screenshot(session, c, draft.screenshotFileUuid);
    await BoardRateLimits.check(BoardLimit.postsPerHour, c);
    await BoardRateLimits.check(BoardLimit.postsPerDay, c);
    final jev = await BoardAi.instance.jevAvailable(session);
    final now = nowUtc();
    final post = await session.db.transaction((tx) async {
      final post = await BoardPost.db.insertRow(
        session,
        BoardPost(
          authorId: c.id,
          kind: draft.kind,
          reportedKind: draft.kind,
          title: title,
          body: body,
          contextJson: contextJson,
          appHint: appHint,
          screenshotFileId: screenshot?.id,
          status: BoardPostStatus.open,
          moderation: jev ? BoardModeration.checking : BoardModeration.visible,
          triageState: jev
              ? BoardTriageState.pending
              : BoardTriageState.unchecked,
          summary: BoardText.plain(body),
          score: 1,
          voteCount: 1,
          createdAt: now,
        ),
        transaction: tx,
      );
      // The author's own vote (specs/16 §7.2).
      await BoardVote.db.insertRow(
        session,
        BoardVote(postId: post.id!, userId: c.id, value: 1, createdAt: now),
        transaction: tx,
      );
      if (screenshot != null) {
        // Attached: no longer cleaned up as an abandoned upload.
        await StoredFile.db.updateRow(
          session,
          screenshot.copyWith(expiresAt: null),
          columns: (t) => [t.expiresAt],
          transaction: tx,
        );
      }
      return post;
    });
    final current = await BoardPipeline.afterCreate(session, post);
    return BoardViews.post(session, c, current);
  }

  static Future<BoardPost> _own(
    Session session,
    BoardCaller c,
    int number, {
    bool allowAdmin = false,
  }) async {
    final post = await BoardAccess.post(session, c, number);
    if (!c.isAuthor(post.authorId) && !(allowAdmin && c.isAdmin)) {
      throw Errors.forbidden();
    }
    return post;
  }

  static Future<BoardTask?> _activeTask(Session session, BoardPost p) async {
    if (p.taskId == null) return null;
    final task = await BoardTask.db.findById(session, p.taskId!);
    return task == null || task.status == BoardTaskStatus.cancelled
        ? null
        : task;
  }

  static Future<BoardPostView> editPost(
    Session session,
    int number,
    String title,
    String body,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final post = await _own(session, c, number);
    final task = await _activeTask(session, post);
    if (!BoardViews.canEdit(c, post, task)) {
      throw Errors.conflict(
        'Issues can be edited while they are open and not part of a task.',
      );
    }
    final cleanTitle = BoardText.title(title);
    final cleanBody = BoardText.body(body, what: 'description');
    if (cleanTitle == post.title && cleanBody == post.body) {
      return BoardViews.post(session, c, post);
    }
    // Every edit is triaged by Jev (shared daily budget).
    await BoardRateLimits.check(BoardLimit.editsPerHour, c);
    var updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(
        title: cleanTitle,
        body: cleanBody,
        editedAt: nowUtc(),
        summary: BoardText.plain(cleanBody),
        suggestedTitle: null,
      ),
      columns: (t) => [
        t.title,
        t.body,
        t.editedAt,
        t.summary,
        t.suggestedTitle,
      ],
    );
    final wasVisible = updated.moderation == BoardModeration.visible;
    updated = await BoardPipeline.afterEdit(session, updated);
    if (wasVisible && updated.moderation == BoardModeration.visible) {
      await BoardPipeline.afterVisible(session, updated);
    }
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  static Future<void> deletePost(Session session, int number) async {
    final c = await BoardAccess.requireWriter(session);
    final post = await _own(session, c, number, allowAdmin: true);
    if (post.deletedAt != null) return;
    if (await _activeTask(session, post) != null) {
      throw Errors.conflict(
        'Issues that are part of a task cannot be deleted.',
      );
    }
    await BoardPost.db.updateRow(
      session,
      post.copyWith(deletedAt: nowUtc()),
      columns: (t) => [t.deletedAt],
    );
    if (c.isAdmin && !c.isAuthor(post.authorId)) {
      await BoardLog.write(
        session,
        adminId: c.id,
        action: 'delete',
        targetKind: BoardTargetKind.post,
        targetId: post.id!,
      );
    }
    await BoardLive.post(session, post.id!, BoardEventKind.postRemoved);
  }

  static Future<BoardPostView> restorePost(Session session, int number) async {
    final c = await BoardAccess.requireWriter(session);
    final post = await _own(session, c, number, allowAdmin: true);
    var updated = post;
    if (post.deletedAt != null) {
      updated = await BoardPost.db.updateRow(
        session,
        post.copyWith(deletedAt: null),
        columns: (t) => [t.deletedAt],
      );
      await BoardLive.post(session, post.id!);
    }
    return BoardViews.post(session, c, updated);
  }
}
