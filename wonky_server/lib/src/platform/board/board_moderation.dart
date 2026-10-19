import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/json.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'board_access.dart';
import 'board_comments.dart';
import 'board_common.dart';
import 'board_notify.dart';
import 'board_pipeline.dart';
import 'board_posts.dart';
import 'board_views.dart';
import 'board_votes.dart';

/// Admin tools (specs/16 §9.2): the review queue, moderation, labels,
/// merging, declining and blocking. Every action writes a
/// `board_moderation_log` row; the undo of each is another call (approve ↔
/// hold, remove ↔ restore, merge ↔ unmerge, decline ↔ reopen, block ↔
/// unblock).
abstract final class BoardModerationService {
  static const queueLimit = 200;

  // ---------------------------------------------------------------- review

  static Future<BoardReviewCounts> reviewCounts(Session session) async {
    await BoardAccess.requireAdmin(session);
    final heldPosts = await BoardPost.db.count(
      session,
      where: (t) =>
          t.moderation.equals(BoardModeration.held) & t.deletedAt.equals(null),
    );
    final heldComments = await BoardComment.db.count(
      session,
      where: (t) =>
          t.moderation.equals(BoardModeration.held) & t.deletedAt.equals(null),
    );
    final checkPosts = await BoardPost.db.count(
      session,
      where: (t) =>
          t.moderation.equals(BoardModeration.visible) &
          t.needsCheck.equals(true) &
          t.deletedAt.equals(null),
    );
    final checkComments = await BoardComment.db.count(
      session,
      where: (t) =>
          t.moderation.equals(BoardModeration.visible) &
          t.needsCheck.equals(true) &
          t.deletedAt.equals(null),
    );
    return BoardReviewCounts(
      held: heldPosts + heldComments,
      check: checkPosts + checkComments,
      unchecked: await BoardPost.db.count(session, where: _unchecked),
      duplicates: await BoardPost.db.count(session, where: _duplicates),
      drafts: await BoardTask.db.count(
        session,
        where: (t) => t.status.equals(BoardTaskStatus.draft),
      ),
      suggestions: await BoardBundleSuggestion.db.count(
        session,
        where: (t) => t.state.equals('pending'),
      ),
    );
  }

  static Expression<Object?> _unchecked(BoardPostTable t) =>
      t.triageState.equals(BoardTriageState.unchecked) &
      t.moderation.equals(BoardModeration.visible) &
      t.deletedAt.equals(null);

  static Expression<Object?> _duplicates(BoardPostTable t) =>
      t.possibleDuplicateOfId.notEquals(null) &
      t.duplicateHintDismissed.equals(false) &
      t.status.notEquals(BoardPostStatus.duplicate) &
      t.moderation.equals(BoardModeration.visible) &
      t.deletedAt.equals(null);

  static Future<List<BoardReviewItem>> reviewQueue(
    Session session,
    BoardReviewSection section,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    Future<List<BoardReviewItem>> mixed(
      List<BoardPost> posts,
      List<BoardComment> comments,
    ) async {
      final entries = <(DateTime, BoardReviewItem)>[
        for (final p in posts)
          (
            p.createdAt,
            BoardReviewItem(
              section: section,
              post: await BoardViews.post(session, c, p),
            ),
          ),
        for (final (i, v) in (await BoardViews.comments(
          session,
          c,
          comments,
        )).indexed)
          (
            comments[i].createdAt,
            BoardReviewItem(section: section, comment: v),
          ),
      ]..sort((a, b) => a.$1.compareTo(b.$1));
      return [for (final e in entries.take(queueLimit)) e.$2];
    }

    switch (section) {
      case BoardReviewSection.held:
        return mixed(
          await BoardPost.db.find(
            session,
            where: (t) =>
                t.moderation.equals(BoardModeration.held) &
                t.deletedAt.equals(null),
            orderBy: (t) => t.createdAt,
            limit: queueLimit,
          ),
          await BoardComment.db.find(
            session,
            where: (t) =>
                t.moderation.equals(BoardModeration.held) &
                t.deletedAt.equals(null),
            orderBy: (t) => t.createdAt,
            limit: queueLimit,
          ),
        );
      case BoardReviewSection.check:
        return mixed(
          await BoardPost.db.find(
            session,
            where: (t) =>
                t.moderation.equals(BoardModeration.visible) &
                t.needsCheck.equals(true) &
                t.deletedAt.equals(null),
            orderBy: (t) => t.createdAt,
            limit: queueLimit,
          ),
          await BoardComment.db.find(
            session,
            where: (t) =>
                t.moderation.equals(BoardModeration.visible) &
                t.needsCheck.equals(true) &
                t.deletedAt.equals(null),
            orderBy: (t) => t.createdAt,
            limit: queueLimit,
          ),
        );
      case BoardReviewSection.unchecked:
        return mixed(
          await BoardPost.db.find(
            session,
            where: _unchecked,
            orderBy: (t) => t.createdAt,
            limit: queueLimit,
          ),
          const [],
        );
      case BoardReviewSection.duplicates:
        return mixed(
          await BoardPost.db.find(
            session,
            where: _duplicates,
            orderBy: (t) => t.createdAt,
            limit: queueLimit,
          ),
          const [],
        );
      case BoardReviewSection.drafts:
        final tasks = await BoardTask.db.find(
          session,
          where: (t) => t.status.equals(BoardTaskStatus.draft),
          orderBy: (t) => t.createdAt,
          limit: queueLimit,
        );
        return [
          for (final v in await BoardViews.tasks(session, c, tasks))
            BoardReviewItem(section: section, task: v),
        ];
    }
  }

  // ------------------------------------------------------------ moderation

  static Map<String, Object?> _snap(BoardPost p) => {
    'moderation': p.moderation.name,
    'moderationReason': p.moderationReason,
    'needsCheck': p.needsCheck,
    'status': p.status.name,
  };

  static Map<String, Object?> _snapComment(BoardComment c) => {
    'moderation': c.moderation.name,
    'moderationReason': c.moderationReason,
    'needsCheck': c.needsCheck,
  };

  static String? _reason(String? reason) {
    final r = reason?.trim();
    if (r == null || r.isEmpty) return null;
    if (r.length > 1000) throw Errors.invalid('The reason is too long.');
    return r;
  }

  static Future<BoardPostView> moderatePost(
    Session session,
    int number,
    BoardModerationAction action,
    String? reason,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    final why = _reason(reason);
    final now = nowUtc();
    BoardPost updated;
    switch (action) {
      case BoardModerationAction.approve:
        updated = await BoardPost.db.updateRow(
          session,
          post.copyWith(
            moderation: BoardModeration.visible,
            moderationReason: null,
            needsCheck: false,
            removedAt: null,
            triageState: post.triageState == BoardTriageState.pending
                ? BoardTriageState.done
                : post.triageState,
          ),
          columns: (t) => [
            t.moderation,
            t.moderationReason,
            t.needsCheck,
            t.removedAt,
            t.triageState,
          ],
        );
        if (post.moderation != BoardModeration.visible) {
          await BoardPipeline.afterVisible(session, updated);
        }
      case BoardModerationAction.hold:
        updated = await BoardPost.db.updateRow(
          session,
          post.copyWith(
            moderation: BoardModeration.held,
            moderationReason: why ?? 'Waiting for review.',
            removedAt: null,
          ),
          columns: (t) => [t.moderation, t.moderationReason, t.removedAt],
        );
        if (post.moderation != BoardModeration.held) {
          await BoardNotify.postStatus(
            session,
            updated,
            'Your issue ${BoardText.quoted(post.title)} is hidden until a '
            'moderator reviews it.',
            actor: c.actor,
            voters: false,
          );
        }
      case BoardModerationAction.remove:
        updated = await BoardPost.db.updateRow(
          session,
          post.copyWith(
            moderation: BoardModeration.removed,
            moderationReason: why ?? 'Removed by a moderator.',
            removedAt: now,
          ),
          columns: (t) => [t.moderation, t.moderationReason, t.removedAt],
        );
        if (post.moderation != BoardModeration.removed) {
          await BoardNotify.postStatus(
            session,
            updated,
            'Your issue ${BoardText.quoted(post.title)} was removed by a '
            'moderator${why == null ? '' : ': $why'}.',
            actor: c.actor,
            voters: false,
          );
        }
      case BoardModerationAction.restore:
        if (post.moderation != BoardModeration.removed) {
          throw Errors.conflict('Only removed issues can be restored.');
        }
        updated = await BoardPost.db.updateRow(
          session,
          post.copyWith(
            moderation: BoardModeration.visible,
            moderationReason: null,
            removedAt: null,
          ),
          columns: (t) => [t.moderation, t.moderationReason, t.removedAt],
        );
      case BoardModerationAction.removeScreenshot:
        updated = await BoardPosts.deleteScreenshot(session, post);
      case BoardModerationAction.markChecked:
        updated = await BoardPost.db.updateRow(
          session,
          post.copyWith(
            needsCheck: false,
            triageState: post.triageState == BoardTriageState.unchecked
                ? BoardTriageState.done
                : post.triageState,
          ),
          columns: (t) => [t.needsCheck, t.triageState],
        );
    }
    await BoardLog.write(
      session,
      adminId: c.id,
      action: action.name,
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: _snap(post),
      after: _snap(updated),
      reason: why,
    );
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  static Future<BoardCommentView> moderateComment(
    Session session,
    UuidValue uuid,
    BoardModerationAction action,
    String? reason,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final comment = await BoardComment.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    );
    if (comment == null) throw Errors.notFound('Comment');
    final why = _reason(reason);
    final BoardComment updated;
    switch (action) {
      case BoardModerationAction.approve:
        updated = comment.copyWith(
          moderation: BoardModeration.visible,
          moderationReason: null,
          needsCheck: false,
          removedAt: null,
        );
      case BoardModerationAction.hold:
        updated = comment.copyWith(
          moderation: BoardModeration.held,
          moderationReason: why ?? 'Waiting for review.',
          removedAt: null,
        );
      case BoardModerationAction.remove:
        updated = comment.copyWith(
          moderation: BoardModeration.removed,
          moderationReason: why ?? 'Removed by a moderator.',
          removedAt: nowUtc(),
        );
      case BoardModerationAction.restore:
        if (comment.moderation != BoardModeration.removed) {
          throw Errors.conflict('Only removed comments can be restored.');
        }
        updated = comment.copyWith(
          moderation: BoardModeration.visible,
          moderationReason: null,
          removedAt: null,
        );
      case BoardModerationAction.markChecked:
        updated = comment.copyWith(needsCheck: false);
      case BoardModerationAction.removeScreenshot:
        throw Errors.invalid('Comments have no screenshot.');
    }
    final saved = await BoardComment.db.updateRow(
      session,
      updated,
      columns: (t) => [
        t.moderation,
        t.moderationReason,
        t.needsCheck,
        t.removedAt,
      ],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: action.name,
      targetKind: BoardTargetKind.comment,
      targetId: comment.id!,
      before: _snapComment(comment),
      after: _snapComment(saved),
      reason: why,
    );
    await BoardComments.recount(session, saved.postId);
    await BoardComments.signal(session, saved);
    return (await BoardViews.comments(session, c, [saved])).single;
  }

  static Future<BoardPostView> adminEditPost(
    Session session,
    int number,
    String title,
    String body,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(
        title: BoardText.title(title),
        body: BoardText.body(body, what: 'description'),
        editedByModerator: true,
        editedAt: nowUtc(),
        moderation: post.moderation == BoardModeration.removed
            ? BoardModeration.removed
            : BoardModeration.visible,
        moderationReason: post.moderation == BoardModeration.removed
            ? post.moderationReason
            : null,
        needsCheck: false,
      ),
      columns: (t) => [
        t.title,
        t.body,
        t.editedByModerator,
        t.editedAt,
        t.moderation,
        t.moderationReason,
        t.needsCheck,
      ],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'editAndApprove',
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: {..._snap(post), 'title': post.title, 'body': post.body},
      after: {..._snap(updated), 'title': updated.title, 'body': updated.body},
    );
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  static Future<BoardPostView> setLabels(
    Session session,
    int number,
    BoardPostKind kind,
    BoardArea? area,
    BoardSize? size,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(kind: kind, area: area, size: size, aiLabels: false),
      columns: (t) => [t.kind, t.area, t.size, t.aiLabels],
    );
    Map<String, Object?> labels(BoardPost p) => {
      'kind': p.kind.name,
      'area': p.area?.name,
      'size': p.size?.name,
      'aiLabels': p.aiLabels,
    };
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'setLabels',
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: labels(post),
      after: labels(updated),
    );
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  static Future<BoardPostView> applySuggestedTitle(
    Session session,
    int number,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    final suggested = post.suggestedTitle;
    if (suggested == null) throw Errors.conflict('There is no suggestion.');
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(title: suggested, suggestedTitle: null),
      columns: (t) => [t.title, t.suggestedTitle],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'applySuggestedTitle',
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: {'title': post.title},
      after: {'title': suggested},
    );
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  static Future<BoardPostView> dismissDuplicateHint(
    Session session,
    int number,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(duplicateHintDismissed: true),
      columns: (t) => [t.duplicateHintDismissed],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'dismissDuplicateHint',
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: {'possibleDuplicateOfId': post.possibleDuplicateOfId},
    );
    return BoardViews.post(session, c, updated);
  }

  // ----------------------------------------------------------------- merge

  /// Merges [source] into [target] (specs/16 §7.4): the source becomes a
  /// duplicate and its votes move to the target (a user who voted on both
  /// keeps the target vote). The moved vote ids and dropped votes are
  /// recorded in the log so [unmerge] can revert.
  static Future<BoardPostView> merge(
    Session session,
    int source,
    int target,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    if (source == target) {
      throw Errors.invalid('An issue cannot be merged into itself.');
    }
    final src = await BoardAccess.post(session, c, source);
    final tgt = await BoardAccess.post(session, c, target);
    if (src.deletedAt != null || tgt.deletedAt != null) {
      throw Errors.conflict('Deleted issues cannot be merged.');
    }
    if (src.status == BoardPostStatus.duplicate) {
      throw Errors.conflict('#$source is already merged.');
    }
    if (tgt.status == BoardPostStatus.duplicate) {
      throw Errors.conflict('#$target is merged into another issue.');
    }
    final recipients = await BoardNotify.authorsAndVoters(session, [src]);
    await session.db.transaction((tx) async {
      final srcVotes = await BoardVote.db.find(
        session,
        where: (t) => t.postId.equals(src.id!),
        transaction: tx,
      );
      final tgtVoters = {
        for (final v in await BoardVote.db.find(
          session,
          where: (t) => t.postId.equals(tgt.id!),
          transaction: tx,
        ))
          v.userId,
      };
      final moved = <int>[];
      final dropped = <Map<String, Object?>>[];
      for (final v in srcVotes) {
        if (tgtVoters.contains(v.userId) ||
            (v.value < 0 && tgt.kind == BoardPostKind.bug)) {
          dropped.add({
            'userId': v.userId,
            'value': v.value,
            'createdAt': v.createdAt.toIso8601String(),
          });
          await BoardVote.db.deleteRow(session, v, transaction: tx);
        } else {
          await BoardVote.db.updateRow(
            session,
            v.copyWith(postId: tgt.id!),
            columns: (t) => [t.postId],
            transaction: tx,
          );
          moved.add(v.id!);
        }
      }
      await BoardPost.db.updateRow(
        session,
        src.copyWith(
          status: BoardPostStatus.duplicate,
          duplicateOfId: tgt.id,
        ),
        columns: (t) => [t.status, t.duplicateOfId],
        transaction: tx,
      );
      await BoardVotes.recompute(session, [src.id!, tgt.id!], transaction: tx);
      await BoardLog.write(
        session,
        adminId: c.id,
        action: 'merge',
        targetKind: BoardTargetKind.post,
        targetId: src.id!,
        before: {'status': src.status.name},
        after: {
          'targetId': tgt.id,
          'movedVoteIds': moved,
          'droppedVotes': dropped,
        },
        transaction: tx,
      );
    });
    await BoardNotify.status(
      session,
      to: recipients,
      postNumber: src.id,
      title: src.title,
      line:
          'Merged: ${BoardText.quoted(src.title)} is now tracked as '
          '#${tgt.id} ${BoardText.quoted(tgt.title)}.',
      actor: c.actor,
    );
    await BoardLive.post(session, src.id!);
    await BoardLive.post(session, tgt.id!);
    return BoardViews.post(
      session,
      c,
      (await BoardPost.db.findById(session, tgt.id!))!,
    );
  }

  /// Undo of [merge]: moves the recorded votes back and restores the
  /// source's status.
  static Future<BoardPostView> unmerge(Session session, int source) async {
    final c = await BoardAccess.requireAdmin(session);
    final src = await BoardAccess.post(session, c, source);
    if (src.status != BoardPostStatus.duplicate || src.duplicateOfId == null) {
      throw Errors.conflict('#$source is not merged.');
    }
    final log = await BoardModerationLog.db.findFirstRow(
      session,
      where: (t) =>
          t.action.equals('merge') &
          t.targetKind.equals(BoardTargetKind.post) &
          t.targetId.equals(src.id!),
      orderBy: (t) => t.id.desc(),
    );
    final after = decodeObject(log?.afterJson);
    final before = decodeObject(log?.beforeJson);
    final targetId = src.duplicateOfId!;
    final movedIds = [
      for (final id in (after['movedVoteIds'] as List?) ?? const [])
        if (id is int) id,
    ];
    final dropped = [
      for (final d in (after['droppedVotes'] as List?) ?? const [])
        if (d is Map) d,
    ];
    final status = BoardPostStatus.values.firstWhere(
      (s) => s.name == before['status'],
      orElse: () => BoardPostStatus.open,
    );
    await session.db.transaction((tx) async {
      final existing = {
        for (final v in await BoardVote.db.find(
          session,
          where: (t) => t.postId.equals(src.id!),
          transaction: tx,
        ))
          v.userId,
      };
      if (movedIds.isNotEmpty) {
        final moved = await BoardVote.db.find(
          session,
          where: (t) =>
              t.id.inSet(movedIds.toSet()) & t.postId.equals(targetId),
          transaction: tx,
        );
        for (final v in moved) {
          if (existing.add(v.userId)) {
            await BoardVote.db.updateRow(
              session,
              v.copyWith(postId: src.id!),
              columns: (t) => [t.postId],
              transaction: tx,
            );
          }
        }
      }
      for (final d in dropped) {
        final userId = d['userId'];
        final value = d['value'];
        if (userId is! int || value is! int || !existing.add(userId)) continue;
        if (await UserProfile.db.findById(session, userId, transaction: tx) ==
            null) {
          continue;
        }
        await BoardVote.db.insertRow(
          session,
          BoardVote(
            postId: src.id!,
            userId: userId,
            value: value,
            createdAt:
                DateTime.tryParse('${d['createdAt']}')?.toUtc() ?? nowUtc(),
          ),
          transaction: tx,
        );
      }
      await BoardPost.db.updateRow(
        session,
        src.copyWith(status: status, duplicateOfId: null),
        columns: (t) => [t.status, t.duplicateOfId],
        transaction: tx,
      );
      await BoardVotes.recompute(session, [src.id!, targetId], transaction: tx);
      await BoardLog.write(
        session,
        adminId: c.id,
        action: 'unmerge',
        targetKind: BoardTargetKind.post,
        targetId: src.id!,
        before: {'targetId': targetId},
        after: {'status': status.name},
        transaction: tx,
      );
    });
    await BoardLive.post(session, src.id!);
    await BoardLive.post(session, targetId);
    return BoardViews.post(
      session,
      c,
      (await BoardPost.db.findById(session, src.id!))!,
    );
  }

  // --------------------------------------------------------------- decline

  static Future<BoardPostView> decline(
    Session session,
    int number,
    String reason,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    final why = _reason(reason);
    if (why == null) throw Errors.invalid('Give a reason.');
    if (post.status == BoardPostStatus.duplicate ||
        post.status == BoardPostStatus.declined) {
      throw Errors.conflict('This issue cannot be declined.');
    }
    if (post.taskId != null) {
      final task = await BoardTask.db.findById(session, post.taskId!);
      if (task != null && task.status != BoardTaskStatus.cancelled) {
        throw Errors.conflict('Remove the issue from its task first.');
      }
    }
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(status: BoardPostStatus.declined, declineReason: why),
      columns: (t) => [t.status, t.declineReason],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'decline',
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: {'status': post.status.name},
      after: {'status': 'declined'},
      reason: why,
    );
    await BoardNotify.postStatus(
      session,
      updated,
      'Declined: ${BoardText.quoted(post.title)} ($why).',
      actor: c.actor,
    );
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  static Future<BoardPostView> reopen(Session session, int number) async {
    final c = await BoardAccess.requireAdmin(session);
    final post = await BoardAccess.post(session, c, number);
    if (post.status != BoardPostStatus.declined) {
      throw Errors.conflict('Only declined issues can be reopened.');
    }
    final updated = await BoardPost.db.updateRow(
      session,
      post.copyWith(status: BoardPostStatus.open, declineReason: null),
      columns: (t) => [t.status, t.declineReason],
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'reopen',
      targetKind: BoardTargetKind.post,
      targetId: post.id!,
      before: {'status': 'declined', 'declineReason': post.declineReason},
      after: {'status': 'open'},
    );
    await BoardLive.post(session, post.id!);
    return BoardViews.post(session, c, updated);
  }

  // ---------------------------------------------------------------- blocks

  static Future<void> blockUser(
    Session session,
    int userId,
    String reason,
    DateTime? until,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    if (userId == c.id) throw Errors.invalid('You cannot block yourself.');
    if (await UserProfile.db.findById(session, userId) == null) {
      throw Errors.notFound('User');
    }
    final why = _reason(reason);
    final now = nowUtc();
    if (until != null && !until.toUtc().isAfter(now)) {
      throw Errors.invalid('The block must end in the future.');
    }
    final profile = await _profile(session, userId);
    await BoardUserProfile.db.updateRow(
      session,
      profile.copyWith(
        blockedAt: now,
        blockedUntil: until?.toUtc(),
        blockedReason: why,
        blockedById: c.id,
      ),
      columns: (t) => [
        t.blockedAt,
        t.blockedUntil,
        t.blockedReason,
        t.blockedById,
      ],
    );
    await BoardVotes.recomputeVotesOf(session, userId);
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'block',
      targetKind: BoardTargetKind.user,
      targetId: userId,
      before: {'blockedAt': profile.blockedAt?.toIso8601String()},
      after: {'until': until?.toUtc().toIso8601String()},
      reason: why,
    );
  }

  static Future<void> unblockUser(Session session, int userId) async {
    final c = await BoardAccess.requireAdmin(session);
    final profile = await BoardUserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    if (profile == null || profile.blockedAt == null) return;
    await BoardUserProfile.db.updateRow(
      session,
      profile.copyWith(
        blockedAt: null,
        blockedUntil: null,
        blockedReason: null,
        blockedById: null,
      ),
      columns: (t) => [
        t.blockedAt,
        t.blockedUntil,
        t.blockedReason,
        t.blockedById,
      ],
    );
    await BoardVotes.recomputeVotesOf(session, userId);
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'unblock',
      targetKind: BoardTargetKind.user,
      targetId: userId,
      before: {
        'blockedAt': profile.blockedAt?.toIso8601String(),
        'reason': profile.blockedReason,
      },
    );
  }

  /// The board profile of [userId], created when missing.
  static Future<BoardUserProfile> _profile(Session session, int userId) async {
    final existing = await BoardUserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
    return existing ??
        await BoardUserProfile.db.insertRow(
          session,
          BoardUserProfile(userId: userId),
        );
  }
}
