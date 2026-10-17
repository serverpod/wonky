import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/board.dart';

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../notifications/notification_service.dart';
import 'ai/board_ai.dart';
import 'ai/jev_gemini_board_ai.dart' show BoardAiBudgetException;
import 'ai/task_prompt_template.dart';
import 'board_access.dart';
import 'board_comments.dart';
import 'board_common.dart';
import 'board_config.dart';
import 'board_notify.dart';
import 'board_views.dart';

/// Tasks, claims and bundle suggestions (specs/16 §8, §9.3, §10).
abstract final class BoardTasks {
  static const maxPostsPerTask = 20;
  static const maxPromptLength = 50000;
  static const maxCommentsPerPost = 20;
  static const maxBundleInput = 200;

  /// Crockford base32 (no I, L, O, U).
  static const claimAlphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  /// Source of claim codes (tests may seed it).
  static Random random = Random.secure();

  /// A new claim code: 8 characters, `XXXX-XXXX` (specs/16 §13.7).
  static String newClaimCode() {
    final chars = [
      for (var i = 0; i < 8; i++) claimAlphabet[random.nextInt(32)],
    ].join();
    return '${chars.substring(0, 4)}-${chars.substring(4)}';
  }

  static const _activeStatuses = {
    BoardTaskStatus.published,
    BoardTaskStatus.claimed,
    BoardTaskStatus.inReview,
  };

  // ------------------------------------------------------------------ read

  static Future<BoardTaskPage> list(
    Session session,
    List<BoardTaskStatus> statuses,
    String? cursor,
    int limit,
  ) async {
    final c = await BoardAccess.caller(session);
    final wanted = {
      for (final s in statuses.isEmpty ? _activeStatuses : statuses)
        if (s != BoardTaskStatus.draft || c.isAdmin) s,
    };
    if (wanted.isEmpty) return BoardTaskPage(items: const []);
    // An expired claim shows as published, so `published` also reads
    // `claimed` rows.
    final query = {
      ...wanted,
      if (wanted.contains(BoardTaskStatus.published)) BoardTaskStatus.claimed,
    };
    final now = nowUtc();
    final rows = [
      for (final t in await BoardTask.db.find(
        session,
        where: (t) => t.status.inSet(query),
        orderBy: (t) => t.id.desc(),
        limit: 1000,
      ))
        if (wanted.contains(BoardViews.effectiveStatus(t, now))) t,
    ];
    final offset = int.tryParse(cursor ?? '')?.clamp(0, rows.length) ?? 0;
    final size = limit <= 0 ? 30 : limit.clamp(1, 50);
    final page = rows.skip(offset).take(size).toList();
    final next = offset + page.length;
    return BoardTaskPage(
      items: await BoardViews.tasks(session, c, page),
      nextCursor: next < rows.length ? '$next' : null,
    );
  }

  /// (Up for grabs, Claimed): published tasks without a valid claim, and
  /// claimed or in-review ones (specs/16 §4.4).
  static Future<(int, int)> counts(Session session) async {
    final now = nowUtc();
    var open = 0;
    var claimed = 0;
    for (final t in await BoardTask.db.find(
      session,
      where: (t) => t.status.inSet(_activeStatuses),
    )) {
      if (BoardViews.effectiveStatus(t, now) == BoardTaskStatus.published) {
        open++;
      } else {
        claimed++;
      }
    }
    return (open, claimed);
  }

  static Future<BoardTaskView> get(Session session, int number) async {
    final c = await BoardAccess.caller(session);
    return BoardViews.task(
      session,
      c,
      await BoardAccess.task(session, c, number),
    );
  }

  // --------------------------------------------------------------- helpers

  static Future<BoardTask> _adminTask(
    Session session,
    BoardCaller c,
    int number,
  ) => BoardAccess.task(session, c, number);

  static String _title(String title) {
    final t = title.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length < 3) throw Errors.invalid('The task needs a title.');
    if (t.length > 120) {
      throw Errors.invalid('The title can have at most 120 characters.');
    }
    return t;
  }

  /// Posts for task [taskId] (null: a new task): visible, not deleted, and
  /// not in another task that is not cancelled.
  static Future<List<BoardPost>> _postsFor(
    Session session,
    List<int> numbers, {
    int? taskId,
  }) async {
    final ids = numbers.toSet();
    if (ids.isEmpty) throw Errors.invalid('Select at least one post.');
    if (ids.length > maxPostsPerTask) {
      throw Errors.invalid('A task can have at most $maxPostsPerTask posts.');
    }
    final posts = await BoardPost.db.find(
      session,
      where: (t) => t.id.inSet(ids),
      orderBy: (t) => t.id,
    );
    final found = {for (final p in posts) p.id};
    for (final id in ids) {
      if (!found.contains(id)) throw Errors.notFound('Post #$id');
    }
    final otherTaskIds = {
      for (final p in posts)
        if (p.taskId != null && p.taskId != taskId) p.taskId!,
    };
    final otherTasks = otherTaskIds.isEmpty
        ? const <BoardTask>[]
        : await BoardTask.db.find(
            session,
            where: (t) => t.id.inSet(otherTaskIds),
          );
    final busy = {
      for (final t in otherTasks)
        if (t.status != BoardTaskStatus.cancelled) t.id,
    };
    for (final p in posts) {
      if (p.deletedAt != null || p.moderation != BoardModeration.visible) {
        throw Errors.conflict('#${p.id} is not public.');
      }
      if (busy.contains(p.taskId)) {
        throw Errors.conflict('#${p.id} is already part of T-${p.taskId}.');
      }
      final inThisTask = taskId != null && p.taskId == taskId;
      if (p.status != BoardPostStatus.open && !inThisTask) {
        throw Errors.conflict('#${p.id} is ${p.status.name}.');
      }
    }
    return posts;
  }

  static Future<List<BoardPost>> _postsOf(Session session, int taskId) =>
      BoardPost.db.find(
        session,
        where: (t) => t.taskId.equals(taskId) & t.deletedAt.equals(null),
        orderBy: (t) => t.id,
      );

  /// The post status that goes with a task status (specs/16 §3.3).
  static BoardPostStatus postStatusFor(BoardTaskStatus s) => switch (s) {
    BoardTaskStatus.published ||
    BoardTaskStatus.claimed ||
    BoardTaskStatus.inReview => BoardPostStatus.planned,
    BoardTaskStatus.done => BoardPostStatus.done,
    BoardTaskStatus.shipped => BoardPostStatus.shipped,
    BoardTaskStatus.draft || BoardTaskStatus.cancelled => BoardPostStatus.open,
  };

  static const _syncable = {
    BoardPostStatus.open,
    BoardPostStatus.planned,
    BoardPostStatus.done,
    BoardPostStatus.shipped,
  };

  static Future<List<BoardPost>> _syncPosts(
    Session session,
    int taskId,
    BoardTaskStatus status,
  ) async {
    final target = postStatusFor(status);
    final posts = await _postsOf(session, taskId);
    final changed = <BoardPost>[];
    for (final p in posts) {
      if (!_syncable.contains(p.status) || p.status == target) continue;
      changed.add(
        await BoardPost.db.updateRow(
          session,
          p.copyWith(status: target),
          columns: (t) => [t.status],
        ),
      );
      await BoardLive.post(session, p.id!);
    }
    return changed;
  }

  /// Hook for status changes outside admin actions (the GitHub App,
  /// specs/16 §13.6): the task's posts follow [status]. Returns the
  /// task's posts.
  static Future<List<BoardPost>> followTaskStatus(
    Session session,
    int taskId,
    BoardTaskStatus status,
  ) async {
    await _syncPosts(session, taskId, status);
    return _postsOf(session, taskId);
  }

  static Future<Map<int, List<BoardComment>>> _commentsFor(
    Session session,
    List<BoardPost> posts,
  ) async {
    final result = <int, List<BoardComment>>{};
    for (final p in posts) {
      result[p.id!] = await BoardComment.db.find(
        session,
        where: (t) =>
            t.postId.equals(p.id!) &
            t.moderation.equals(BoardModeration.visible) &
            t.deletedAt.equals(null) &
            t.systemEvent.equals(null),
        orderBy: (t) => t.id,
        limit: maxCommentsPerPost,
      );
    }
    return result;
  }

  /// How long a scheduled prompt may take before the task stops showing
  /// it as pending (a lost future call must not block publishing).
  static const promptTimeout = Duration(minutes: 10);

  static const promptBudgetNote = "Today's AI budget is used up.";
  static const promptFailedNote =
      'The AI could not write the prompt. Try Regenerate.';

  /// Whether the AI is writing the prompt of [t] at [now].
  static bool promptPending(BoardTask t, DateTime now) {
    final at = t.promptRequestedAt;
    return at != null && now.difference(at) < promptTimeout;
  }

  /// Marks [task] as waiting for its AI prompt and schedules
  /// `BoardFutureCall.writePrompt` (specs/16 §10.1); the request is
  /// dropped again when it cannot be scheduled.
  static Future<BoardTask> _requestPrompt(
    Session session,
    BoardTask task,
  ) async {
    var updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(promptRequestedAt: nowUtc(), promptNote: null),
    );
    if (!await BoardJobs.schedule(session, BoardJob.prompt, task.id!)) {
      updated = await BoardTask.db.updateRow(
        session,
        updated.copyWith(promptRequestedAt: null, promptNote: promptFailedNote),
      );
    }
    return updated;
  }

  /// The background pass of a requested prompt (`BoardFutureCall.writePrompt`):
  /// Gemini writes the body; a budget or provider failure leaves the body
  /// and records [BoardTask.promptNote]. The result is dropped when the
  /// request was replaced or cancelled meanwhile (a newer *Regenerate*, the
  /// admin's own text). Open task pages refresh through `watchTasks`.
  static Future<void> writePrompt(Session session, int taskId) async {
    final task = await BoardTask.db.findById(session, taskId);
    final requested = task?.promptRequestedAt;
    if (task == null || requested == null) return;
    final ai = BoardAi.instance;
    String? body;
    String? note;
    if (!await ai.geminiAvailable(session)) {
      note = ai.geminiConfigured ? promptBudgetNote : promptFailedNote;
    } else {
      try {
        final posts = await _postsOf(session, taskId);
        final text = await ai.writeTaskPrompt(
          session,
          task: task,
          posts: posts,
          comments: await _commentsFor(session, posts),
          webOrigin: NotificationService.webOrigin(),
        );
        body = text.trim().isEmpty ? null : text.trim();
        if (body == null) note = promptFailedNote;
      } on BoardAiBudgetException {
        note = promptBudgetNote;
      } on Object catch (e) {
        session.log(
          'board: prompt of T-$taskId failed: $e',
          level: LogLevel.warning,
        );
        note = promptFailedNote;
      }
    }
    final current = await BoardTask.db.findById(session, taskId);
    if (current == null || current.promptRequestedAt != requested) return;
    // A written prompt publishes its draft (T-11): the admin's *Select for
    // building* is the approval. Unless the lint flags it (§10.2): then the
    // task waits for an admin to read and save the prompt.
    // A regenerated prompt of a task that is already out is not applied
    // when flagged: contributors would get it unread.
    final lint = body == null ? const <PromptLint>[] : lintTaskPrompt(body);
    final draft = current.status == BoardTaskStatus.draft;
    if (lint.isNotEmpty) {
      note = draft ? heldNote(lint) : notAppliedNote(lint);
      if (!draft) body = null;
    }
    var updated = await BoardTask.db.updateRow(
      session,
      current.copyWith(
        promptBody: body ?? current.promptBody,
        promptGeneratedAt: body == null ? current.promptGeneratedAt : nowUtc(),
        promptRequestedAt: null,
        promptNote: note,
      ),
    );
    if (body != null &&
        lint.isEmpty &&
        updated.status == BoardTaskStatus.draft &&
        (await _postsOf(session, taskId)).isNotEmpty) {
      updated = await _applyStatus(
        session,
        updated,
        BoardTaskStatus.published,
        adminId: updated.createdById,
        reason: autoPublishReason,
      );
    }
    await BoardLive.task(session, taskId);
  }

  /// The moderation-log reason of a task published by [writePrompt].
  static const autoPublishReason = 'Published when the AI prompt was written.';

  /// [BoardTask.promptNote] of a written prompt the lint flagged: the task
  /// stays a draft until an admin saves the prompt (specs/16 §10.2).
  static String heldNote(List<PromptLint> lint) =>
      'Held for review: ${_lintSummary(lint)}. Read the prompt, then save it '
      'to publish the task.';

  /// [BoardTask.promptNote] of a regenerated prompt the lint flagged on a
  /// task that is no longer a draft: the current prompt stays.
  static String notAppliedNote(List<PromptLint> lint) =>
      'The regenerated prompt was not applied: ${_lintSummary(lint)}. The '
      'current prompt stays.';

  static String _lintSummary(List<PromptLint> lint) {
    final first = lint.first;
    final more = lint.length > 1 ? ' (and ${lint.length - 1} more)' : '';
    return 'line ${first.line} has "${first.match}"$more, which is unusual '
        'for a task';
  }

  static Map<String, Object?> _snap(BoardTask t) => {
    'status': t.status.name,
    'title': t.title,
    'area': t.area.name,
    'size': t.size.name,
    'claimedById': t.claimedById,
    'prNumber': t.prNumber,
  };

  static Future<BoardTaskView> _done(
    Session session,
    BoardCaller c,
    BoardTask task,
  ) async {
    await BoardLive.task(session, task.id!);
    return BoardViews.task(session, c, task);
  }

  // ----------------------------------------------------------------- admin

  static Future<BoardTaskView> create(
    Session session,
    List<int> postNumbers,
    String title,
    BoardArea area,
    BoardSize size,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final clean = _title(title);
    final posts = await _postsFor(session, postNumbers);
    final now = nowUtc();
    var task = await session.db.transaction((tx) async {
      final task = await BoardTask.db.insertRow(
        session,
        BoardTask(
          title: clean,
          area: area,
          size: size,
          status: BoardTaskStatus.draft,
          promptBody: TaskPromptTemplate.blankBody,
          createdById: c.id,
          createdAt: now,
        ),
        transaction: tx,
      );
      await BoardPost.db.updateWhere(
        session,
        columnValues: (t) => [t.taskId(task.id)],
        where: (t) => t.id.inSet(<int>{for (final p in posts) p.id!}),
        transaction: tx,
      );
      return task;
    });
    // The AI writes the prompt in the background (about a minute); the
    // draft is there at once with the blank template.
    final ai = BoardAi.instance;
    if (await ai.geminiAvailable(session)) {
      task = await _requestPrompt(session, task);
    } else if (ai.geminiConfigured) {
      task = await BoardTask.db.updateRow(
        session,
        task.copyWith(promptNote: promptBudgetNote),
      );
    }
    // A pending suggestion with exactly these posts is now accepted.
    final ids = {for (final p in posts) p.id!};
    for (final s in await BoardBundleSuggestion.db.find(
      session,
      where: (t) => t.state.equals('pending'),
    )) {
      if (s.postIds.toSet().containsAll(ids) && ids.containsAll(s.postIds)) {
        await BoardBundleSuggestion.db.updateRow(
          session,
          s.copyWith(state: 'accepted'),
        );
      }
    }
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'createTask',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      after: {..._snap(task), 'postIds': ids.toList()},
    );
    for (final p in posts) {
      await BoardLive.post(session, p.id!);
    }
    return _done(session, c, task);
  }

  static Future<BoardTaskView> update(
    Session session,
    int number,
    String title,
    BoardArea area,
    BoardSize size,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(title: _title(title), area: area, size: size),
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'updateTask',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      before: _snap(task),
      after: _snap(updated),
    );
    return _done(session, c, updated);
  }

  static Future<BoardTaskView> setPosts(
    Session session,
    int number,
    List<int> postNumbers,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    if (task.status == BoardTaskStatus.done ||
        task.status == BoardTaskStatus.shipped ||
        task.status == BoardTaskStatus.cancelled) {
      throw Errors.conflict('The posts of this task can no longer change.');
    }
    final posts = await _postsFor(session, postNumbers, taskId: task.id);
    final before = await _postsOf(session, task.id!);
    final ids = {for (final p in posts) p.id!};
    final removed = [
      for (final p in before)
        if (!ids.contains(p.id)) p,
    ];
    await session.db.transaction((tx) async {
      for (final p in removed) {
        await BoardPost.db.updateRow(
          session,
          p.copyWith(
            taskId: null,
            status: p.status == BoardPostStatus.planned
                ? BoardPostStatus.open
                : p.status,
          ),
          columns: (t) => [t.taskId, t.status],
          transaction: tx,
        );
      }
      await BoardPost.db.updateWhere(
        session,
        columnValues: (t) => [t.taskId(task.id)],
        where: (t) => t.id.inSet(ids),
        transaction: tx,
      );
    });
    await _syncPosts(session, task.id!, task.status);
    for (final p in removed) {
      await BoardLive.post(session, p.id!);
    }
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'setTaskPosts',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      before: {'postIds': before.map((p) => p.id).toList()},
      after: {'postIds': ids.toList()},
    );
    return _done(session, c, task);
  }

  static Future<BoardTaskView> regeneratePrompt(
    Session session,
    int number,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    final ai = BoardAi.instance;
    if (!ai.geminiConfigured) {
      throw Errors.unavailable('The board AI is not configured.');
    }
    if (!await ai.geminiAvailable(session)) {
      throw Errors.unavailable("Today's AI budget is used up.");
    }
    final updated = await _requestPrompt(session, task);
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'regeneratePrompt',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      before: {'promptBody': task.promptBody},
    );
    return _done(session, c, updated);
  }

  static Future<BoardTaskView> setPrompt(
    Session session,
    int number,
    String body,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    final clean = body.trim();
    if (clean.isEmpty) throw Errors.invalid('The prompt is empty.');
    if (clean.length > maxPromptLength) {
      throw Errors.invalid('The prompt is too long.');
    }
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(
        promptBody: clean,
        promptEditedById: c.id,
        promptEditedAt: nowUtc(),
        // The admin's text wins over a prompt the AI is still writing.
        promptRequestedAt: null,
        promptNote: null,
      ),
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'setPrompt',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      before: {'promptBody': task.promptBody},
      after: {'promptBody': clean},
    );
    return _done(session, c, updated);
  }

  static Future<BoardTaskView> publish(Session session, int number) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    if (task.status != BoardTaskStatus.draft) {
      throw Errors.conflict('Only draft tasks can be published.');
    }
    if (promptPending(task, nowUtc())) {
      throw Errors.conflict('The AI is still writing the prompt.');
    }
    if ((await _postsOf(session, task.id!)).isEmpty) {
      throw Errors.conflict('The task has no posts.');
    }
    return _setStatus(session, c, task, BoardTaskStatus.published);
  }

  static Future<BoardTaskView> setStatus(
    Session session,
    int number,
    BoardTaskStatus status,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    if (status == BoardTaskStatus.claimed &&
        !(task.claimedById != null && task.claimExpiresAt != null)) {
      throw Errors.invalid('Tasks are claimed by contributors.');
    }
    return _setStatus(session, c, task, status);
  }

  static Future<BoardTaskView> _setStatus(
    Session session,
    BoardCaller c,
    BoardTask task,
    BoardTaskStatus status,
  ) async => _done(
    session,
    c,
    await _applyStatus(session, task, status, adminId: c.id, actor: c.actor),
  );

  /// Moves [task] to [status] with its side effects (posts, activity row,
  /// moderation log, notifications), on behalf of the admin [adminId]
  /// ([actor] null: the background job of [writePrompt], T-11).
  static Future<BoardTask> _applyStatus(
    Session session,
    BoardTask task,
    BoardTaskStatus status, {
    required int adminId,
    Actor? actor,
    String? reason,
  }) async {
    final now = nowUtc();
    final previous = BoardViews.effectiveStatus(task, now);
    final keepClaim =
        status == BoardTaskStatus.claimed ||
        status == BoardTaskStatus.inReview ||
        status == BoardTaskStatus.done ||
        status == BoardTaskStatus.shipped;
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: status,
        publishedAt: status == BoardTaskStatus.draft
            ? null
            : task.publishedAt ??
                  (status == BoardTaskStatus.published ? now : null),
        doneAt:
            status == BoardTaskStatus.done || status == BoardTaskStatus.shipped
            ? task.doneAt ?? now
            : null,
        shippedAt: status == BoardTaskStatus.shipped
            ? task.shippedAt ?? now
            : null,
        claimedById: keepClaim ? task.claimedById : null,
        claimedAt: keepClaim ? task.claimedAt : null,
        claimExpiresAt: keepClaim ? task.claimExpiresAt : null,
        claimWarnedAt: keepClaim ? task.claimWarnedAt : null,
        claimCode: keepClaim ? task.claimCode : null,
      ),
    );
    await _syncPosts(session, task.id!, status);
    final event = switch (status) {
      BoardTaskStatus.done => 'done',
      BoardTaskStatus.shipped => 'shipped',
      BoardTaskStatus.cancelled => 'cancelled',
      BoardTaskStatus.published when previous == BoardTaskStatus.draft =>
        'published',
      _ => null,
    };
    if (event != null) {
      await BoardComments.systemRow(
        session,
        taskId: task.id,
        event: event,
        actorId: adminId,
      );
    }
    await BoardLog.write(
      session,
      adminId: adminId,
      action: 'setTaskStatus',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      before: _snap(task),
      after: _snap(updated),
      reason: reason,
    );
    final line = switch (status) {
      BoardTaskStatus.published when previous == BoardTaskStatus.draft =>
        'can now be picked up by a contributor',
      BoardTaskStatus.done when previous != BoardTaskStatus.shipped =>
        'was built and ships with the next release',
      BoardTaskStatus.shipped => 'is now live on wonky.work',
      _ => null,
    };
    if (line != null) {
      final label = switch (status) {
        BoardTaskStatus.published => 'Planned',
        BoardTaskStatus.done => 'Built',
        _ => 'Shipped',
      };
      for (final p in await _postsOf(session, task.id!)) {
        await BoardNotify.postStatus(
          session,
          p,
          '$label: ${BoardText.quoted(p.title)} $line.',
          actor: actor,
        );
      }
    }
    return updated;
  }

  /// The admin fallback for linking a PR (specs/16 §8.3); null unlinks.
  static Future<BoardTaskView> linkPullRequest(
    Session session,
    int number,
    String? url,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final task = await _adminTask(session, c, number);
    final now = nowUtc();
    final status = BoardViews.effectiveStatus(task, now);
    if (!_activeStatuses.contains(status)) {
      throw Errors.conflict('Pull requests are linked to published tasks.');
    }
    final BoardTask updated;
    if (url == null || url.trim().isEmpty) {
      if (task.prNumber == null) return BoardViews.task(session, c, task);
      final claimed =
          task.claimedById != null &&
          task.claimExpiresAt != null &&
          task.claimExpiresAt!.isAfter(now);
      updated = await BoardTask.db.updateRow(
        session,
        task.copyWith(
          status: claimed ? BoardTaskStatus.claimed : BoardTaskStatus.published,
          pullRequestUrl: null,
          prNumber: null,
          prAuthorLogin: null,
          claimedById: claimed ? task.claimedById : null,
          claimedAt: claimed ? task.claimedAt : null,
          claimExpiresAt: claimed ? task.claimExpiresAt : null,
          claimCode: claimed ? task.claimCode : null,
        ),
      );
      await BoardComments.systemRow(
        session,
        taskId: task.id,
        event: 'prUnlinked',
        actorId: c.id,
      );
    } else {
      final repo = RegExp.escape(BoardConfig.current.repository);
      final match = RegExp(
        '^https://github\\.com/$repo/pull/(\\d+)/?\$',
        caseSensitive: false,
      ).firstMatch(url.trim());
      if (match == null) {
        throw Errors.invalid(
          'Use a pull request of github.com/${BoardConfig.current.repository}.',
        );
      }
      final prNumber = int.parse(match[1]!);
      updated = await BoardTask.db.updateRow(
        session,
        task.copyWith(
          status: BoardTaskStatus.inReview,
          pullRequestUrl:
              'https://github.com/${BoardConfig.current.repository}/pull/$prNumber',
          prNumber: prNumber,
        ),
      );
      await BoardComments.systemRow(
        session,
        taskId: task.id,
        event: 'prLinked',
        actorId: c.id,
        body: updated.pullRequestUrl!,
      );
    }
    await _syncPosts(session, task.id!, updated.status);
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'linkPullRequest',
      targetKind: BoardTargetKind.task,
      targetId: task.id!,
      before: {..._snap(task), 'pullRequestUrl': task.pullRequestUrl},
      after: {..._snap(updated), 'pullRequestUrl': updated.pullRequestUrl},
    );
    return _done(session, c, updated);
  }

  // ---------------------------------------------------------------- claims

  static Future<BoardTaskView> claim(Session session, int number) async {
    final c = await BoardAccess.requireWriter(session);
    await BoardAccess.task(session, c, number);
    final config = BoardConfig.current;
    final now = nowUtc();
    final (task, expiredClaimant) = await session.db.transaction((tx) async {
      final task = await BoardTask.db.findById(
        session,
        number,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (task == null) throw Errors.notFound('Task');
      final valid = BoardViews.claimValid(task, now);
      if (valid && task.claimedById == c.id) return (task, null);
      final status = BoardViews.effectiveStatus(task, now);
      if (status == BoardTaskStatus.claimed ||
          status == BoardTaskStatus.inReview) {
        throw Errors.conflict('This task is already claimed.');
      }
      if (status != BoardTaskStatus.published) {
        throw Errors.conflict('Only published tasks can be claimed.');
      }
      final active = await BoardTask.db.count(
        session,
        where: (t) =>
            t.claimedById.equals(c.id) &
            t.status.equals(BoardTaskStatus.claimed) &
            (t.claimExpiresAt > now) &
            t.id.notEquals(task.id!),
        transaction: tx,
      );
      if (active >= config.maxActiveClaimsPerUser) {
        throw Errors.limit(
          'You can hold ${config.maxActiveClaimsPerUser} claims at a time. '
          'Finish or release one first.',
        );
      }
      final expired = task.status == BoardTaskStatus.claimed
          ? task.claimedById
          : null;
      if (task.status == BoardTaskStatus.claimed) {
        await BoardComments.systemRow(
          session,
          taskId: task.id,
          event: 'expired',
          actorId: task.claimedById,
          transaction: tx,
        );
      }
      final updated = await BoardTask.db.updateRow(
        session,
        task.copyWith(
          status: BoardTaskStatus.claimed,
          claimedById: c.id,
          claimedAt: now,
          claimExpiresAt: now.add(config.claimDuration),
          claimWarnedAt: null,
          claimCode: newClaimCode(),
        ),
        transaction: tx,
      );
      await BoardComments.systemRow(
        session,
        taskId: task.id,
        event: 'claimed',
        actorId: c.id,
        transaction: tx,
      );
      return (updated, expired);
    });
    if (expiredClaimant != null && expiredClaimant != c.id) {
      await BoardNotify.claim(
        session,
        userId: expiredClaimant,
        task: task,
        line: _expiredLine(task),
      );
    }
    return _done(session, c, task);
  }

  static String _expiredLine(BoardTask t) =>
      'Your claim on T-${t.id} ${BoardText.quoted(t.title)} expired. The '
      'task is up for grabs again.';

  static Future<BoardTaskView> release(Session session, int number) async {
    final c = await BoardAccess.requireWriter(session);
    final task = await BoardAccess.task(session, c, number);
    final now = nowUtc();
    final valid = BoardViews.claimValid(task, now);
    if (!valid) {
      if (task.status == BoardTaskStatus.claimed &&
          (c.isAdmin || c.isAuthor(task.claimedById))) {
        // Expired: shows as published already; clean up.
        return _expire(session, task, notify: false, viewer: c);
      }
      throw Errors.conflict('This task is not claimed.');
    }
    final claimant = c.isAuthor(task.claimedById);
    if (!claimant && !c.isAdmin) throw Errors.forbidden();
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: BoardTaskStatus.published,
        claimedById: null,
        claimedAt: null,
        claimExpiresAt: null,
        claimWarnedAt: null,
        claimCode: null,
        pullRequestUrl: null,
        prNumber: null,
        prAuthorLogin: null,
      ),
    );
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'released',
      actorId: c.id,
    );
    if (!claimant) {
      await BoardLog.write(
        session,
        adminId: c.id,
        action: 'releaseClaim',
        targetKind: BoardTargetKind.task,
        targetId: task.id!,
        before: _snap(task),
        after: _snap(updated),
      );
      await BoardNotify.claim(
        session,
        userId: task.claimedById!,
        task: task,
        line:
            'An admin released your claim on T-${task.id} '
            '${BoardText.quoted(task.title)}.',
        actor: c.actor,
      );
    }
    await _syncPosts(session, task.id!, BoardTaskStatus.published);
    return _done(session, c, updated);
  }

  static Future<BoardTaskView> _expire(
    Session session,
    BoardTask task, {
    required bool notify,
    BoardCaller? viewer,
  }) async {
    final updated = await BoardTask.db.updateRow(
      session,
      task.copyWith(
        status: BoardTaskStatus.published,
        claimedById: null,
        claimedAt: null,
        claimExpiresAt: null,
        claimWarnedAt: null,
        claimCode: null,
      ),
    );
    await BoardComments.systemRow(
      session,
      taskId: task.id,
      event: 'expired',
      actorId: task.claimedById,
    );
    if (notify && task.claimedById != null) {
      await BoardNotify.claim(
        session,
        userId: task.claimedById!,
        task: task,
        line: _expiredLine(task),
      );
    }
    await BoardLive.task(session, task.id!);
    return BoardViews.task(
      session,
      viewer ?? const BoardCaller.signedOut(),
      updated,
    );
  }

  /// Sweep: expired claims go back to published (system row and a
  /// `boardClaim` notification). Returns the count.
  static Future<int> expireClaims(Session session) async {
    final now = nowUtc();
    final tasks = await BoardTask.db.find(
      session,
      where: (t) =>
          t.status.equals(BoardTaskStatus.claimed) & (t.claimExpiresAt <= now),
      limit: 500,
    );
    for (final t in tasks) {
      await _expire(session, t, notify: true);
    }
    return tasks.length;
  }

  /// Sweep: one reminder per claim with `claimWarnHours` or less left.
  static Future<int> warnClaims(Session session) async {
    final now = nowUtc();
    final config = BoardConfig.current;
    final tasks = await BoardTask.db.find(
      session,
      where: (t) =>
          t.status.equals(BoardTaskStatus.claimed) &
          (t.claimExpiresAt > now) &
          (t.claimExpiresAt <=
              now.add(Duration(hours: config.claimWarnHours))) &
          t.claimWarnedAt.equals(null),
      limit: 500,
    );
    for (final t in tasks) {
      await BoardTask.db.updateRow(
        session,
        t.copyWith(claimWarnedAt: now),
        columns: (c) => [c.claimWarnedAt],
      );
      final hours = (t.claimExpiresAt!.difference(now).inMinutes / 60).ceil();
      await BoardNotify.claim(
        session,
        userId: t.claimedById!,
        task: t,
        line:
            'Your claim on T-${t.id} ${BoardText.quoted(t.title)} expires in '
            '$hours ${hours == 1 ? 'hour' : 'hours'}. Link your pull request '
            'or release the task.',
      );
    }
    return tasks.length;
  }

  // --------------------------------------------------------------- bundles

  static Future<List<BoardBundleSuggestionView>> suggestBundles(
    Session session,
  ) async {
    await BoardAccess.requireAdmin(session);
    final ai = BoardAi.instance;
    if (!ai.geminiConfigured) {
      throw Errors.unavailable('The board AI is not configured.');
    }
    if (!await ai.geminiAvailable(session)) {
      throw Errors.unavailable("Today's AI budget is used up.");
    }
    final cancelled = {
      for (final t in await BoardTask.db.find(
        session,
        where: (t) => t.status.equals(BoardTaskStatus.cancelled),
      ))
        t.id!,
    };
    final posts = [
      for (final p in await BoardPost.db.find(
        session,
        where: (t) =>
            t.moderation.equals(BoardModeration.visible) &
            t.status.equals(BoardPostStatus.open) &
            t.size.equals(BoardSize.small) &
            t.deletedAt.equals(null),
        orderBy: (t) => t.score.desc(),
        limit: maxBundleInput * 2,
      ))
        if (p.taskId == null || cancelled.contains(p.taskId)) p,
    ].take(maxBundleInput).toList();
    if (posts.length < 2) return listSuggestions(session);
    final List<BoardBundleProposal> proposals;
    try {
      proposals = await ai.suggestBundles(session, posts);
    } on BoardAiException catch (e) {
      throw Errors.unavailable(
        'The AI could not suggest bundles: ${e.message}',
      );
    }
    final allowed = {for (final p in posts) p.id!};
    final known = {
      for (final s in await BoardBundleSuggestion.db.find(
        session,
        where: (t) => t.state.inSet({'pending', 'dismissed'}),
      ))
        _key(s.postIds),
    };
    final now = nowUtc();
    for (final p in proposals) {
      final ids = {
        for (final id in p.postIds)
          if (allowed.contains(id)) id,
      };
      if (ids.length < 2) continue;
      final key = _key(ids);
      if (!known.add(key)) continue;
      await BoardBundleSuggestion.db.insertRow(
        session,
        BoardBundleSuggestion(
          title: p.title.trim().isEmpty ? 'Bundle' : p.title.trim(),
          rationale: p.rationale.trim(),
          area: p.area,
          postIds: ids.toList()..sort(),
          state: 'pending',
          createdAt: now,
        ),
      );
    }
    return listSuggestions(session);
  }

  static String _key(Iterable<int> ids) =>
      (ids.toSet().toList()..sort()).join(',');

  static Future<List<BoardBundleSuggestionView>> listSuggestions(
    Session session,
  ) async {
    final c = await BoardAccess.requireAdmin(session);
    final suggestions = await BoardBundleSuggestion.db.find(
      session,
      where: (t) => t.state.equals('pending'),
      orderBy: (t) => t.id.desc(),
    );
    final ids = {for (final s in suggestions) ...s.postIds};
    final posts = ids.isEmpty
        ? const <BoardPost>[]
        : await BoardPost.db.find(session, where: (t) => t.id.inSet(ids));
    final activeTasks = {
      for (final t in await BoardTask.db.find(
        session,
        where: (t) => t.status.notEquals(BoardTaskStatus.cancelled),
      ))
        t.id!,
    };
    final usable = {
      for (final p in posts)
        if (p.deletedAt == null &&
            p.moderation == BoardModeration.visible &&
            p.status == BoardPostStatus.open &&
            !activeTasks.contains(p.taskId))
          p.id!: p,
    };
    final result = <BoardBundleSuggestionView>[];
    for (final s in suggestions) {
      final members = [
        for (final id in s.postIds)
          if (usable[id] != null) usable[id]!,
      ];
      if (members.length < 2) continue;
      result.add(
        BoardBundleSuggestionView(
          id: s.id!,
          title: s.title,
          rationale: s.rationale,
          area: s.area,
          posts: await BoardViews.listItems(session, c, members),
          createdAt: s.createdAt,
        ),
      );
    }
    return result;
  }

  static Future<void> dismissSuggestion(Session session, int id) async {
    final c = await BoardAccess.requireAdmin(session);
    final s = await BoardBundleSuggestion.db.findById(session, id);
    if (s == null) throw Errors.notFound('Suggestion');
    await BoardBundleSuggestion.db.updateRow(
      session,
      s.copyWith(state: 'dismissed'),
    );
    await BoardLog.write(
      session,
      adminId: c.id,
      action: 'dismissSuggestion',
      targetKind: BoardTargetKind.task,
      targetId: id,
    );
  }
}
