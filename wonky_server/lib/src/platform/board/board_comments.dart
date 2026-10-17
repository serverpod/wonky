import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'ai/board_ai.dart';
import 'board_access.dart';
import 'board_common.dart';
import 'board_config.dart';
import 'board_notify.dart';
import 'board_pipeline.dart';
import 'board_triage.dart';
import 'board_views.dart';

/// Comments on posts (specs/16 §7.3), the activity rows of tasks (§4.6:
/// tasks have no discussion; their rows are system rows, listed to admins)
/// and community flags (§7.5).
abstract final class BoardComments {
  static Future<List<BoardCommentView>> list(
    Session session, {
    int? postNumber,
    int? taskNumber,
  }) async {
    final c = await BoardAccess.caller(session);
    final List<BoardComment> rows;
    if (postNumber != null) {
      final post = await BoardAccess.post(session, c, postNumber);
      rows = await BoardComment.db.find(
        session,
        where: (t) => t.postId.equals(post.id!),
        orderBy: (t) => t.id,
        limit: 2000,
      );
    } else if (taskNumber != null) {
      final task = await BoardAccess.task(session, c, taskNumber);
      // A task's activity is admin information.
      if (!c.isAdmin) return const [];
      rows = await BoardComment.db.find(
        session,
        where: (t) => t.taskId.equals(task.id!),
        orderBy: (t) => t.id,
        limit: 2000,
      );
    } else {
      throw Errors.invalid('Name a post or a task.');
    }
    return BoardViews.comments(session, c, [
      for (final r in rows)
        if (BoardAccess.canSeeComment(c, r)) r,
    ]);
  }

  /// The number of public comments on [postId] (visible, not deleted, not
  /// system rows).
  static Future<void> recount(Session session, int? postId) async {
    if (postId == null) return;
    final count = await BoardComment.db.count(
      session,
      where: (t) =>
          t.postId.equals(postId) &
          t.moderation.equals(BoardModeration.visible) &
          t.deletedAt.equals(null) &
          t.systemEvent.equals(null),
    );
    await BoardPost.db.updateWhere(
      session,
      columnValues: (t) => [t.commentCount(count)],
      where: (t) => t.id.equals(postId),
    );
  }

  static Future<void> signal(Session session, BoardComment comment) async {
    if (comment.postId != null) {
      await BoardLive.post(
        session,
        comment.postId!,
        BoardEventKind.commentsChanged,
      );
    }
    if (comment.taskId != null) await BoardLive.task(session, comment.taskId!);
  }

  /// The comment check (specs/16 §6.3 step 6): inline, 3 s, the same
  /// bands as posts. Without Jev or on errors the comment is visible.
  static Future<({BoardModeration moderation, bool needsCheck, String? reason})>
  check(Session session, String body) async {
    const visible = (
      moderation: BoardModeration.visible,
      needsCheck: false,
      reason: null,
    );
    final ai = BoardAi.instance;
    if (!await ai.jevAvailable(session)) return visible;
    try {
      final scores = await ai
          .checkComment(session, body, timeout: BoardPipeline.inlineTimeout)
          .timeout(
            BoardPipeline.inlineTimeout + const Duration(milliseconds: 500),
          );
      return applyCommentCheck(scores, BoardConfig.current.ai.thresholds);
    } on Object catch (e) {
      session.log('board: comment check failed: $e', level: LogLevel.info);
      return visible;
    }
  }

  static Future<BoardComment> _byUuid(
    Session session,
    BoardCaller c,
    UuidValue uuid,
  ) async {
    final comment = await BoardComment.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    );
    if (comment == null || !BoardAccess.canSeeComment(c, comment)) {
      throw Errors.notFound('Comment');
    }
    if (comment.postId != null) {
      await BoardAccess.post(session, c, comment.postId!);
    } else if (comment.taskId != null) {
      await BoardAccess.task(session, c, comment.taskId!);
    }
    return comment;
  }

  static Future<BoardCommentView> _view(
    Session session,
    BoardCaller c,
    BoardComment comment,
  ) async => (await BoardViews.comments(session, c, [comment])).single;

  static Future<BoardCommentView> add(
    Session session, {
    required UuidValue uuid,
    int? postNumber,
    int? taskNumber,
    required String body,
  }) async {
    final c = await BoardAccess.requireWriter(session);
    if (taskNumber != null) {
      throw Errors.invalid(
        'Tasks have no discussion: comment on one of its posts.',
      );
    }
    if (postNumber == null) throw Errors.invalid('Name the post.');
    final existing = await BoardComment.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    );
    if (existing != null) {
      if (existing.authorId != c.id) {
        throw Errors.conflict('This comment id is already in use.');
      }
      return _view(session, c, existing);
    }
    final clean = BoardText.body(body, what: 'comment');
    final post = await BoardAccess.post(session, c, postNumber);
    if (post.deletedAt != null || post.moderation == BoardModeration.removed) {
      throw Errors.conflict('This post can no longer be commented on.');
    }
    await BoardRateLimits.check(BoardLimit.commentsPerHour, c);
    final verdict = await check(session, clean);
    final earlier = await BoardComment.db.find(
      session,
      where: (t) =>
          t.postId.equals(post.id!) &
          t.systemEvent.equals(null) &
          t.authorId.notEquals(null),
    );
    final comment = await BoardComment.db.insertRow(
      session,
      BoardComment(
        uuid: uuid,
        postId: post.id,
        authorId: c.id,
        body: clean,
        moderation: verdict.moderation,
        moderationReason: verdict.reason,
        needsCheck: verdict.needsCheck,
        createdAt: nowUtc(),
      ),
    );
    await recount(session, post.id);
    if (comment.moderation == BoardModeration.visible) {
      await BoardNotify.reply(
        session,
        to: {?post.authorId, for (final e in earlier) e.authorId!}
          ..remove(c.id),
        post: post,
        body: clean,
        actor: c.actor!,
      );
    }
    await signal(session, comment);
    return _view(session, c, comment);
  }

  static Future<BoardComment> _ownComment(
    Session session,
    BoardCaller c,
    UuidValue uuid,
  ) async {
    final comment = await _byUuid(session, c, uuid);
    if (!c.isAuthor(comment.authorId) || comment.systemEvent != null) {
      throw Errors.forbidden();
    }
    return comment;
  }

  static Future<BoardCommentView> edit(
    Session session,
    UuidValue uuid,
    String body,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final comment = await _ownComment(session, c, uuid);
    if (comment.deletedAt != null ||
        comment.moderation == BoardModeration.removed) {
      throw Errors.conflict('This comment can no longer be edited.');
    }
    final clean = BoardText.body(body, what: 'comment');
    if (clean == comment.body) return _view(session, c, comment);
    final verdict = await check(session, clean);
    final held =
        verdict.moderation == BoardModeration.held ||
        comment.moderation == BoardModeration.held;
    final updated = await BoardComment.db.updateRow(
      session,
      comment.copyWith(
        body: clean,
        editedAt: nowUtc(),
        moderation: held ? BoardModeration.held : BoardModeration.visible,
        moderationReason: held
            ? verdict.reason ?? comment.moderationReason
            : null,
        needsCheck: verdict.needsCheck || comment.needsCheck,
      ),
    );
    await recount(session, comment.postId);
    await signal(session, updated);
    return _view(session, c, updated);
  }

  static Future<void> delete(Session session, UuidValue uuid) async {
    final c = await BoardAccess.requireWriter(session);
    final comment = await _ownComment(session, c, uuid);
    if (comment.deletedAt != null) return;
    final updated = await BoardComment.db.updateRow(
      session,
      comment.copyWith(deletedAt: nowUtc()),
      columns: (t) => [t.deletedAt],
    );
    await recount(session, comment.postId);
    await signal(session, updated);
  }

  static Future<BoardCommentView> restore(
    Session session,
    UuidValue uuid,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final comment = await _ownComment(session, c, uuid);
    var updated = comment;
    if (comment.deletedAt != null) {
      updated = await BoardComment.db.updateRow(
        session,
        comment.copyWith(deletedAt: null),
        columns: (t) => [t.deletedAt],
      );
      await recount(session, comment.postId);
      await signal(session, updated);
    }
    return _view(session, c, updated);
  }

  /// A system activity row of a task (claimed, released, expired, …).
  static Future<BoardComment> systemRow(
    Session session, {
    int? taskId,
    int? postId,
    required String event,
    int? actorId,
    String body = '',
    Transaction? transaction,
  }) => BoardComment.db.insertRow(
    session,
    BoardComment(
      uuid: const Uuid().v4obj(),
      taskId: taskId,
      postId: postId,
      authorId: actorId,
      body: body,
      systemEvent: event,
      moderation: BoardModeration.visible,
      createdAt: nowUtc(),
    ),
    transaction: transaction,
  );

  // ----------------------------------------------------------------- flags

  static Future<(BoardPost?, BoardComment?)> _flagTarget(
    Session session,
    BoardCaller c,
    int? number,
    UuidValue? commentUuid,
  ) async {
    if ((number == null) == (commentUuid == null)) {
      throw Errors.invalid('Flag a post or a comment.');
    }
    if (number != null) {
      return (await BoardAccess.post(session, c, number), null);
    }
    final comment = await _byUuid(session, c, commentUuid!);
    if (comment.systemEvent != null) {
      throw Errors.invalid('Activity rows cannot be flagged.');
    }
    return (null, comment);
  }

  static Future<void> flag(
    Session session,
    int? number,
    UuidValue? commentUuid,
    BoardFlagReason reason,
    String? note,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final (post, comment) = await _flagTarget(session, c, number, commentUuid);
    final cleanNote = note?.trim();
    if (cleanNote != null && cleanNote.length > 1000) {
      throw Errors.invalid('The note is too long (max 1,000 characters).');
    }
    final existing = await BoardFlag.db.findFirstRow(
      session,
      where: (t) =>
          t.userId.equals(c.id) &
          (post != null
              ? t.postId.equals(post.id!)
              : t.commentId.equals(comment!.id!)),
    );
    if (existing != null) {
      await BoardFlag.db.updateRow(
        session,
        existing.copyWith(
          reason: reason,
          note: cleanNote?.isEmpty ?? true ? null : cleanNote,
        ),
      );
      return;
    }
    await BoardRateLimits.check(BoardLimit.flagsPerDay, c);
    await BoardFlag.db.insertRow(
      session,
      BoardFlag(
        postId: post?.id,
        commentId: comment?.id,
        userId: c.id,
        reason: reason,
        note: cleanNote?.isEmpty ?? true ? null : cleanNote,
        createdAt: nowUtc(),
      ),
    );
    await _afterFlags(session, post: post, comment: comment);
  }

  static Future<void> unflag(
    Session session,
    int? number,
    UuidValue? commentUuid,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    final (post, comment) = await _flagTarget(session, c, number, commentUuid);
    await BoardFlag.db.deleteWhere(
      session,
      where: (t) =>
          t.userId.equals(c.id) &
          (post != null
              ? t.postId.equals(post.id!)
              : t.commentId.equals(comment!.id!)),
    );
    if (post != null) await _countPostFlags(session, post.id!);
  }

  static Future<int> _countPostFlags(Session session, int postId) async {
    final flags = await BoardFlag.db.find(
      session,
      where: (t) => t.postId.equals(postId),
    );
    final count = {for (final f in flags) f.userId}.length;
    await BoardPost.db.updateWhere(
      session,
      columnValues: (t) => [t.flagCount(count)],
      where: (t) => t.id.equals(postId),
    );
    return count;
  }

  /// Holds a visible target once `flagsToHold` distinct users flagged it.
  static Future<void> _afterFlags(
    Session session, {
    BoardPost? post,
    BoardComment? comment,
  }) async {
    final threshold = BoardConfig.current.flagsToHold;
    const reason = 'Waiting for review: flagged by the community.';
    if (post != null) {
      final count = await _countPostFlags(session, post.id!);
      final current = (await BoardPost.db.findById(session, post.id!))!;
      if (count >= threshold &&
          current.moderation == BoardModeration.visible &&
          current.deletedAt == null) {
        final held = await BoardPost.db.updateRow(
          session,
          current.copyWith(
            moderation: BoardModeration.held,
            moderationReason: reason,
            needsCheck: true,
          ),
        );
        await BoardLive.post(session, post.id!);
        await BoardNotify.postStatus(
          session,
          held,
          'Your post ${BoardText.quoted(held.title)} is hidden until a '
          'moderator reviews it.',
          voters: false,
        );
      }
      return;
    }
    final flags = await BoardFlag.db.find(
      session,
      where: (t) => t.commentId.equals(comment!.id!),
    );
    final count = {for (final f in flags) f.userId}.length;
    final current = (await BoardComment.db.findById(session, comment!.id!))!;
    if (count >= threshold &&
        current.moderation == BoardModeration.visible &&
        current.deletedAt == null) {
      final held = await BoardComment.db.updateRow(
        session,
        current.copyWith(
          moderation: BoardModeration.held,
          moderationReason: reason,
          needsCheck: true,
        ),
      );
      await recount(session, held.postId);
      await signal(session, held);
    }
  }
}
