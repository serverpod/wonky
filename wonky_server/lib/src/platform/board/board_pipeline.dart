import 'dart:async';
import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'ai/board_ai.dart';
import 'board_common.dart';
import 'board_config.dart';
import 'board_notify.dart';
import 'board_search.dart';
import 'board_triage.dart';

/// The AI pipeline of a post (specs/16 §6.3): inline triage at submit
/// (3 s), the background path with retries, the unchecked path without
/// Jev, and the writing pass (summary, suggested title).
abstract final class BoardPipeline {
  static const inlineTimeout = Duration(seconds: 3);
  static const backgroundTimeout = Duration(seconds: 60);

  /// Delays of the background retries after a failed attempt.
  static const retryDelays = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 30),
  ];

  /// Up to this many unchecked posts are re-triaged per sweep.
  static const retriageBatch = 20;

  /// Runs Jev on [post] and stores the result (moderation, labels unless
  /// an admin confirmed them, duplicate hint, triage JSON). Throws when
  /// the AI fails or times out.
  ///
  /// The AI call takes up to [timeout]; the post may change meanwhile (an
  /// author's edit, an admin's moderation, a delete). The result is
  /// therefore written under a row lock to the AI-owned columns only, and
  /// only when the post is still in the state the triage started from
  /// (same moderation, not deleted, and the same text unless it is still
  /// `checking`). Otherwise nothing is written and the current row is
  /// returned (an edit runs its own triage).
  static Future<BoardPost> triage(
    Session session,
    BoardPost post, {
    Duration timeout = inlineTimeout,
  }) async {
    final candidates = await BoardSearch.similarPosts(
      session,
      '${post.title} ${BoardText.plain(post.body, max: 2000)}',
      limit: 5,
      excludeId: post.id,
    );
    final result = await BoardAi.instance
        .triagePost(session, post, candidates: candidates, timeout: timeout)
        .timeout(timeout + const Duration(milliseconds: 500));
    final o = applyTriage(
      result,
      BoardConfig.current.ai.thresholds,
      reportedKind: post.reportedKind,
    );
    final candidateIds = {for (final p in candidates) p.id};
    return session.db.transaction((tx) async {
      final current = await BoardPost.db.findById(
        session,
        post.id!,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (current == null) return post;
      if (!triageStillApplies(post, current)) return current;
      final confirmed = !current.aiLabels;
      return BoardPost.db.updateRow(
        session,
        current.copyWith(
          moderation: o.moderation,
          moderationReason: o.reason,
          needsCheck: o.needsCheck,
          kind: confirmed ? current.kind : o.kind,
          area: confirmed ? current.area : o.area,
          size: confirmed ? current.size : o.size,
          possibleDuplicateOfId: candidateIds.contains(o.possibleDuplicateOfId)
              ? o.possibleDuplicateOfId
              : null,
          triageState: BoardTriageState.done,
          triageJson: jsonEncode(result.toJson()),
        ),
        columns: (t) => [
          t.moderation,
          t.moderationReason,
          t.needsCheck,
          t.kind,
          t.area,
          t.size,
          t.possibleDuplicateOfId,
          t.triageState,
          t.triageJson,
        ],
        transaction: tx,
      );
    });
  }

  /// Whether a triage of [read] may still be stored on [current] (the row
  /// now): not deleted, the moderation unchanged (an admin's decision
  /// wins), and the same text unless the post is still `checking` (a
  /// visible post that was edited is triaged again by its edit).
  static bool triageStillApplies(BoardPost read, BoardPost current) {
    if (current.deletedAt != null) return false;
    if (current.moderation != read.moderation) return false;
    if (current.moderation == BoardModeration.checking) return true;
    return current.title == read.title && current.body == read.body;
  }

  /// After a new post is stored as `checking` (Jev available) or
  /// `visible` (no Jev): the inline triage, or the background path when it
  /// fails. Returns the post as stored now.
  static Future<BoardPost> afterCreate(Session session, BoardPost post) async {
    var current = post;
    if (post.moderation == BoardModeration.checking) {
      try {
        current = await triage(session, post);
      } on Object catch (e) {
        session.log(
          'board: inline triage of #${post.id} failed, continuing in the '
          'background: $e',
          level: LogLevel.info,
        );
        await BoardJobs.schedule(session, BoardJob.triage, post.id!);
        return post;
      }
    }
    if (current.moderation == BoardModeration.visible) {
      await afterVisible(session, current);
    }
    return current;
  }

  /// Re-runs the inline triage after an author's edit (specs/16 §6.3
  /// step 5): a visible post stays visible unless a score reaches hold.
  static Future<BoardPost> afterEdit(Session session, BoardPost post) async {
    if (post.moderation == BoardModeration.checking) return post;
    if (!await BoardAi.instance.jevAvailable(session)) {
      return _markUnchecked(session, post);
    }
    try {
      return await triage(session, post);
    } on Object catch (e) {
      session.log(
        'board: triage of the edit of #${post.id} failed: $e',
        level: LogLevel.info,
      );
      return _markUnchecked(session, post);
    }
  }

  /// Marks [post] for the sweep's re-triage (only the triage state).
  static Future<BoardPost> _markUnchecked(Session session, BoardPost post) =>
      BoardPost.db.updateRow(
        session,
        post.copyWith(triageState: BoardTriageState.unchecked),
        columns: (t) => [t.triageState],
      );

  /// The writing pass for a post that became visible: a Gemini summary in
  /// the background when available.
  static Future<void> afterVisible(Session session, BoardPost post) async {
    if (await BoardAi.instance.geminiAvailable(session)) {
      await BoardJobs.schedule(session, BoardJob.summarize, post.id!);
    }
  }

  /// `BoardFutureCall.triage`: the background path with retries at 1, 5
  /// and 30 minutes; afterwards the post is published unchecked (or held
  /// when `publishWhenTriageFails` is false).
  static Future<void> backgroundTriage(Session session, int postId) async {
    final post = await BoardPost.db.findById(session, postId);
    if (post == null ||
        post.deletedAt != null ||
        post.moderation != BoardModeration.checking) {
      return;
    }
    if (!await BoardAi.instance.jevAvailable(session)) {
      final published = await _whileChecking(
        session,
        postId,
        (t) => [
          t.moderation(BoardModeration.visible),
          t.triageState(BoardTriageState.unchecked),
        ],
      );
      if (published == null) return;
      await BoardLive.post(session, postId);
      await afterVisible(session, published);
      return;
    }
    try {
      final updated = await triage(
        session,
        post,
        timeout: backgroundTimeout,
      );
      await BoardLive.post(session, postId);
      if (updated.moderation == BoardModeration.held) {
        await _notifyHeld(session, updated);
      } else if (updated.moderation == BoardModeration.visible) {
        await afterVisible(session, updated);
      }
    } on Object catch (e) {
      final attempts = post.triageAttempts + 1;
      if (attempts <= retryDelays.length) {
        session.log(
          'board: triage of #$postId failed (attempt $attempts): $e',
          level: LogLevel.warning,
        );
        await BoardPost.db.updateRow(
          session,
          post.copyWith(triageAttempts: attempts),
          columns: (t) => [t.triageAttempts],
        );
        await BoardJobs.schedule(
          session,
          BoardJob.triage,
          postId,
          delay: retryDelays[attempts - 1],
        );
        return;
      }
      session.log(
        'board: triage of #$postId failed for good: $e',
        level: LogLevel.warning,
      );
      final publish = BoardConfig.current.publishWhenTriageFails;
      final updated = await _whileChecking(
        session,
        postId,
        (t) => [
          t.triageAttempts(attempts),
          t.moderation(
            publish ? BoardModeration.visible : BoardModeration.held,
          ),
          t.moderationReason(publish ? null : boardHoldReason(const [])),
          t.triageState(
            publish ? BoardTriageState.unchecked : BoardTriageState.failed,
          ),
        ],
      );
      if (updated == null) return;
      await BoardLive.post(session, postId);
      if (publish) {
        await afterVisible(session, updated);
      } else {
        await _notifyHeld(session, updated);
      }
    }
  }

  /// Sets [columns] of post [postId] only while it is still `checking` and
  /// not deleted (an admin may have decided meanwhile). Returns the
  /// updated row, or null when the post moved on.
  static Future<BoardPost?> _whileChecking(
    Session session,
    int postId,
    ColumnValueListBuilder<BoardPostUpdateTable> columns,
  ) async {
    final rows = await BoardPost.db.updateWhere(
      session,
      columnValues: columns,
      where: (t) =>
          t.id.equals(postId) &
          t.moderation.equals(BoardModeration.checking) &
          t.deletedAt.equals(null),
    );
    return rows.firstOrNull;
  }

  static Future<void> _notifyHeld(Session session, BoardPost post) =>
      BoardNotify.postStatus(
        session,
        post,
        'Waiting for review: a moderator will look at '
        '${BoardText.quoted(post.title)}.',
        voters: false,
      );

  /// `BoardFutureCall.summarize`: a clearer title (only kept when it
  /// differs) and a short summary, from Gemini.
  static Future<void> summarize(Session session, int postId) async {
    final post = await BoardPost.db.findById(session, postId);
    if (post == null ||
        post.deletedAt != null ||
        post.moderation != BoardModeration.visible) {
      return;
    }
    if (!await BoardAi.instance.geminiAvailable(session)) return;
    try {
      final r = await BoardAi.instance.summarize(session, post);
      final title = r.title?.trim().replaceAll(RegExp(r'\s+'), ' ');
      String norm(String s) => s.toLowerCase().replaceAll(
        RegExp(r'[^\p{L}\p{N}]+', unicode: true),
        '',
      );
      final differs =
          title != null &&
          title.length >= BoardText.minTitleLength &&
          title.length <= BoardText.maxTitleLength &&
          norm(title) != norm(post.title);
      final summary = BoardText.plain(r.summary, max: 200);
      await BoardPost.db.updateRow(
        session,
        post.copyWith(
          suggestedTitle: differs ? title : null,
          summary: summary.isEmpty ? post.summary : summary,
        ),
        columns: (t) => [t.suggestedTitle, t.summary],
      );
    } on Object catch (e) {
      session.log(
        'board: summary of #$postId failed: $e',
        level: LogLevel.warning,
      );
    }
  }

  /// Sweep: re-triages unchecked visible posts when Jev is available
  /// again. Returns the number checked.
  static Future<int> retriageUnchecked(Session session) async {
    if (!await BoardAi.instance.jevAvailable(session)) return 0;
    final posts = await BoardPost.db.find(
      session,
      where: (t) =>
          t.triageState.equals(BoardTriageState.unchecked) &
          t.moderation.equals(BoardModeration.visible) &
          t.deletedAt.equals(null),
      orderBy: (t) => t.id,
      limit: retriageBatch,
    );
    var count = 0;
    for (final post in posts) {
      try {
        final updated = await triage(
          session,
          post,
          timeout: backgroundTimeout,
        );
        count++;
        if (updated.moderation == BoardModeration.held) {
          await BoardLive.post(session, post.id!);
          await _notifyHeld(session, updated);
        }
      } on Object catch (e) {
        session.log(
          'board: re-triage of #${post.id} failed: $e',
          level: LogLevel.warning,
        );
        break;
      }
    }
    return count;
  }
}
