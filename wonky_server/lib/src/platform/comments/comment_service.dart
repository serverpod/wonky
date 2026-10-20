import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../activity/activity_service.dart';
import '../common/actor.dart';
import '../common/errors.dart';
import '../common/guarded.dart';
import '../common/json.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../notifications/notification_service.dart';
import '../publications/submission_service.dart';
import '../sharing/access_service.dart';
import '../users/user_service.dart';
import '../cluster/cluster_bus.dart';

/// Comment threads (specs/07 §2). Commenter+ create, reply, react and
/// resolve; authors edit/delete their comments; Editors+ delete any thread.
/// Viewers read comments only when the owner allows it.
abstract final class CommentService {
  static const maxBodyLength = 10000;
  static const maxQuotedText = 500;
  static const maxMentions = 50;

  static String channel(UuidValue itemUuid) => 'comments:${itemUuid.uuid}';

  // ---------------------------------------------------------------- access

  static Future<(DriveItem, Role)> _requireRead(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async {
    final (item, role) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.viewer,
    );
    if (role == Role.viewer && !item.viewersSeeComments) {
      throw Errors.forbidden('Comments are hidden for viewers.');
    }
    return (item, role);
  }

  static Future<(CommentThread, DriveItem, Role)> _thread(
    Session session,
    Actor actor,
    UuidValue threadUuid, {
    Role min = Role.commenter,
  }) async {
    final thread = await CommentThread.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(threadUuid),
    );
    if (thread == null) throw Errors.notFound('Comment');
    final item = await DriveItem.db.findById(session, thread.itemId);
    if (item == null) throw Errors.notFound('Comment');
    final role = await AccessService.effectiveRole(session, actor.userId, item);
    if (role == null) throw Errors.notFound('Comment');
    if (!(role >= min)) throw Errors.forbidden();
    return (thread, item, role);
  }

  // ------------------------------------------------------------------ read

  static Future<List<CommentThreadView>> listThreads(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    CommentFilter filter = CommentFilter.all,
  }) async {
    final (item, _) = await _requireRead(session, actor, itemUuid);
    final threads = await CommentThread.db.find(
      session,
      where: (t) =>
          t.itemId.equals(item.id!) &
          switch (filter) {
            CommentFilter.open => t.status.equals(CommentStatus.open),
            CommentFilter.resolved => t.status.equals(CommentStatus.resolved),
            _ => Constant.bool(true),
          },
      orderBy: (t) => t.createdAt,
    );
    final views = await viewsOf(session, item, threads);
    if (filter != CommentFilter.forYou) return views;
    return [
      for (final v in views)
        if (v.assignee?.id == actor.userId ||
            v.comments.any((c) => c.mentions.any((m) => m.id == actor.userId)))
          v,
    ];
  }

  static Future<CommentThreadView> getThread(
    Session session,
    Actor actor,
    UuidValue threadUuid,
  ) async {
    final (thread, item, role) = await _thread(
      session,
      actor,
      threadUuid,
      min: Role.viewer,
    );
    if (role == Role.viewer && !item.viewersSeeComments) {
      throw Errors.forbidden('Comments are hidden for viewers.');
    }
    return (await viewsOf(session, item, [thread])).single;
  }

  static Future<List<CommentThreadView>> viewsOf(
    Session session,
    DriveItem item,
    List<CommentThread> threads,
  ) async {
    if (threads.isEmpty) return const [];
    final comments = await Comment.db.find(
      session,
      where: (t) => t.threadId.inSet({for (final t in threads) t.id!}),
      orderBy: (t) => t.createdAt,
    );
    final byThread = <int, List<Comment>>{};
    for (final c in comments) {
      byThread.putIfAbsent(c.threadId, () => []).add(c);
    }
    final users = await UserService.summaries(session, [
      for (final t in threads) ...[t.createdById, t.resolvedById, t.assigneeId],
      for (final c in comments) ...[c.authorId, ...c.mentions],
    ]);
    // (M14) A publication's messages show its name (specs/18 §5.2).
    final publicationIds = {
      for (final c in comments)
        if (c.publicationId != null) c.publicationId!,
    };
    final publications = publicationIds.isEmpty
        ? const <int, String>{}
        : {
            for (final p in await Publication.db.find(
              session,
              where: (t) => t.id.inSet(publicationIds),
            ))
              p.id!: p.name,
          };
    return [
      for (final t in threads)
        CommentThreadView(
          uuid: t.uuid,
          itemUuid: item.uuid,
          anchorKind: t.anchorKind,
          anchorJson: t.anchorJson,
          quotedText: t.quotedText,
          status: t.status,
          createdBy: users[t.createdById],
          createdAt: t.createdAt,
          resolvedBy: t.resolvedById == null ? null : users[t.resolvedById],
          resolvedAt: t.resolvedAt,
          assignee: t.assigneeId == null ? null : users[t.assigneeId],
          orphanReasonJson: t.orphanReasonJson,
          suggestionId: t.suggestionId,
          comments: [
            for (final c in byThread[t.id] ?? const <Comment>[])
              CommentView(
                id: c.id!,
                uuid: c.uuid,
                threadUuid: t.uuid,
                author: c.authorId == null ? null : users[c.authorId],
                authorKind: c.authorKind,
                body: c.deletedAt == null ? c.body : '',
                mentions: [
                  if (c.deletedAt == null)
                    for (final m in c.mentions)
                      if (users[m] != null) users[m]!,
                ],
                reactions: _reactions(c.reactions),
                createdAt: c.createdAt,
                editedAt: c.editedAt,
                deleted: c.deletedAt != null,
                systemEvent: c.systemEvent,
                authorLabel: c.publicationId == null
                    ? null
                    : publications[c.publicationId] ?? 'Publication',
              ),
          ],
        ),
    ];
  }

  static Map<String, List<int>> _reactions(String json) {
    final map = decodeObject(json);
    return {
      for (final e in map.entries)
        if (e.value is List)
          e.key: [
            for (final v in e.value! as List)
              if (v is int) v,
          ],
    };
  }

  // ----------------------------------------------------------------- write

  static String _cleanBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw Errors.invalid('The comment is empty.');
    if (trimmed.length > maxBodyLength) {
      throw Errors.invalid('The comment is too long.');
    }
    return trimmed;
  }

  /// The mentions that are kept: users with a role on [item], and users
  /// related to [actor] (mention without sharing, specs/07 §3). Other ids
  /// are dropped, so a comment can't reveal anyone's name and email.
  static Future<List<int>> _validMentions(
    Session session,
    Actor actor,
    DriveItem item,
    List<int> mentions,
  ) async {
    if (mentions.isEmpty) return const [];
    final ids = mentions.toSet();
    if (ids.length > maxMentions) {
      throw Errors.invalid(
        'A comment can mention at most $maxMentions people.',
      );
    }
    final allowed = await UserService.relatedIds(session, actor, ids);
    for (final id in ids.difference(allowed)) {
      if (await AccessService.effectiveRole(session, id, item) != null) {
        allowed.add(id);
      }
    }
    if (allowed.isEmpty) return const [];
    final profiles = await UserProfile.db.find(
      session,
      where: (t) => t.id.inSet(allowed),
    );
    return [for (final p in profiles) p.id!];
  }

  /// Creates a thread with its first comment; idempotent on [threadUuid]
  /// (offline creation is replayed with the same id).
  static Future<CommentThreadView> createThread(
    Session session,
    Actor actor, {
    required UuidValue threadUuid,
    required UuidValue itemUuid,
    required CommentAnchorKind anchorKind,
    required String anchorJson,
    String? quotedText,
    required String body,
    List<int> mentions = const [],
    int? assigneeId,
  }) async {
    final existing = await CommentThread.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(threadUuid),
    );
    if (existing != null) {
      final (thread, item, _) = await _thread(
        session,
        actor,
        threadUuid,
        min: Role.viewer,
      );
      if (thread.createdById != actor.userId) {
        throw Errors.conflict('This comment id is already in use.');
      }
      return (await viewsOf(session, item, [thread])).single;
    }
    final (item, _) = await AccessService.require(
      session,
      actor,
      itemUuid,
      Role.commenter,
    );
    final clean = _cleanBody(body);
    try {
      jsonDecode(anchorJson);
    } on FormatException {
      throw Errors.invalid('The anchor is not valid JSON.');
    }
    final validMentions = await _validMentions(session, actor, item, mentions);
    if (assigneeId != null && !validMentions.contains(assigneeId)) {
      throw Errors.invalid('The assignee must be mentioned in the comment.');
    }
    final now = nowUtc();
    final thread = await session.db.transaction((tx) async {
      final thread = await CommentThread.db.insertRow(
        session,
        CommentThread(
          uuid: threadUuid,
          itemId: item.id!,
          anchorKind: anchorKind,
          anchorJson: anchorJson,
          quotedText: _quote(quotedText),
          createdById: actor.userId,
          createdAt: now,
          updatedAt: now,
          assigneeId: assigneeId,
        ),
        transaction: tx,
      );
      await Comment.db.insertRow(
        session,
        Comment(
          threadId: thread.id!,
          authorId: actor.userId,
          authorKind: actor.kind,
          body: clean,
          mentions: validMentions,
          createdAt: now,
        ),
        transaction: tx,
      );
      return thread;
    });
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.commented,
      summary: {'thread': threadUuid.uuid},
    );
    await _notifyMentions(
      session,
      actor,
      item,
      thread,
      validMentions,
      clean,
      assigneeId: assigneeId,
    );
    await _signal(session, item, CommentEventKind.threadCreated, thread.uuid);
    return (await viewsOf(session, item, [thread])).single;
  }

  static String? _quote(String? text) {
    if (text == null) return null;
    return text.length > maxQuotedText
        ? text.substring(0, maxQuotedText)
        : text;
  }

  static Future<CommentThreadView> reply(
    Session session,
    Actor actor,
    UuidValue threadUuid, {
    required String body,
    List<int> mentions = const [],
    UuidValue? commentUuid,
    int? assigneeId,
  }) async {
    final (thread, item, _) = await _thread(session, actor, threadUuid);
    if (commentUuid != null) {
      final existing = await Comment.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(commentUuid),
      );
      if (existing != null) {
        return (await viewsOf(session, item, [thread])).single;
      }
    }
    final clean = _cleanBody(body);
    final validMentions = await _validMentions(session, actor, item, mentions);
    if (assigneeId != null && !validMentions.contains(assigneeId)) {
      throw Errors.invalid('The assignee must be mentioned in the comment.');
    }
    final now = nowUtc();
    final previous = await Comment.db.find(
      session,
      where: (t) => t.threadId.equals(thread.id!) & t.authorId.notEquals(null),
    );
    await session.db.transaction((tx) async {
      await Comment.db.insertRow(
        session,
        Comment(
          threadId: thread.id!,
          uuid: commentUuid,
          authorId: actor.userId,
          authorKind: actor.kind,
          body: clean,
          mentions: validMentions,
          createdAt: now,
        ),
        transaction: tx,
      );
      // Only the touched columns: the thread row was read before, and a
      // concurrent resolve must not be reverted.
      await CommentThread.db.updateRow(
        session,
        thread.copyWith(
          updatedAt: now,
          assigneeId: assigneeId ?? thread.assigneeId,
        ),
        columns: (t) => [t.updatedAt, if (assigneeId != null) t.assigneeId],
        transaction: tx,
      );
      if (assigneeId != null && assigneeId != thread.assigneeId) {
        await _system(session, thread, actor, CommentSystemEvent.assigned, tx);
      }
    });
    await ActivityService.log(
      session,
      item.id!,
      actor,
      ActivityType.commented,
      summary: {'thread': threadUuid.uuid, 'reply': true},
    );
    // Replies to a publication's messages go to the blog (specs/18 §5.2).
    await runGuarded<void>(
      session,
      'publications.onReply',
      () => SubmissionService.onReply(
        session,
        thread,
        actor,
        body: clean,
        commentUuid: commentUuid,
      ),
    );
    final participants = {
      thread.createdById,
      ?thread.assigneeId,
      for (final c in previous) c.authorId!,
    }..removeAll(validMentions);
    for (final userId in participants) {
      if (await AccessService.effectiveRole(session, userId, item) == null) {
        continue;
      }
      await NotificationService.notify(
        session,
        userId: userId,
        kind: NotificationKind.reply,
        item: item,
        actor: actor,
        payload: await _payload(session, item, thread, clean),
      );
    }
    await _notifyMentions(
      session,
      actor,
      item,
      thread,
      validMentions,
      clean,
      assigneeId: assigneeId,
    );
    await _signal(session, item, CommentEventKind.threadUpdated, thread.uuid);
    return getThread(session, actor, threadUuid);
  }

  /// (v2) Extra notification payload fields per item kind, added by the
  /// apps' server parts (Slides: `slideNumber`, `slideTitle`, Slides 09
  /// §3.6). A failing hook only drops its fields.
  static final Map<
    DriveItemKind,
    Future<Map<String, Object?>> Function(
      Session session,
      DriveItem item,
      CommentThread thread,
    )
  >
  payloadExtras = {};

  static Future<Map<String, Object?>> _payload(
    Session session,
    DriveItem item,
    CommentThread thread,
    String body,
  ) async {
    var extras = const <String, Object?>{};
    final hook = payloadExtras[item.kind];
    if (hook != null) {
      try {
        extras = await hook(session, item, thread);
      } on Exception catch (e) {
        session.log(
          'Comment payload extras failed: $e',
          level: LogLevel.warning,
        );
      }
    }
    return {
      'threadUuid': thread.uuid.uuid,
      'quotedText': thread.quotedText,
      'excerpt': body.length > 200 ? '${body.substring(0, 200)}…' : body,
      'anchorJson': thread.anchorJson,
      ...extras,
    };
  }

  static Future<void> _notifyMentions(
    Session session,
    Actor actor,
    DriveItem item,
    CommentThread thread,
    List<int> mentions,
    String body, {
    int? assigneeId,
  }) async {
    for (final userId in mentions) {
      // Mentioning without sharing does not notify people without access.
      if (await AccessService.effectiveRole(session, userId, item) == null) {
        continue;
      }
      await NotificationService.notify(
        session,
        userId: userId,
        kind: userId == assigneeId
            ? NotificationKind.assigned
            : NotificationKind.mention,
        item: item,
        actor: actor,
        payload: await _payload(session, item, thread, body),
      );
    }
  }

  static Future<CommentView> edit(
    Session session,
    Actor actor,
    int commentId,
    String body, {
    List<int>? mentions,
  }) async {
    final comment = await Comment.db.findById(session, commentId);
    if (comment == null || comment.deletedAt != null) {
      throw Errors.notFound('Comment');
    }
    final thread = (await CommentThread.db.findById(
      session,
      comment.threadId,
    ))!;
    final (_, item, _) = await _thread(session, actor, thread.uuid);
    if (comment.authorId != actor.userId) {
      throw Errors.forbidden('Only the author can edit a comment.');
    }
    final clean = _cleanBody(body);
    final validMentions = mentions == null
        ? comment.mentions
        : await _validMentions(session, actor, item, mentions);
    final updated = await Comment.db.updateRow(
      session,
      comment.copyWith(
        body: clean,
        mentions: validMentions,
        editedAt: nowUtc(),
      ),
      columns: (t) => [t.body, t.mentions, t.editedAt],
    );
    final added = validMentions.where((m) => !comment.mentions.contains(m));
    await _notifyMentions(session, actor, item, thread, added.toList(), clean);
    await _signal(session, item, CommentEventKind.threadUpdated, thread.uuid);
    final view = (await viewsOf(session, item, [thread])).single;
    return view.comments.firstWhere((c) => c.id == updated.id);
  }

  /// Soft-deletes a comment ("Comment deleted"). Authors delete their own;
  /// Editors+ any. Deleting the first comment deletes the thread.
  static Future<void> delete(
    Session session,
    Actor actor,
    int commentId,
  ) async {
    final comment = await Comment.db.findById(session, commentId);
    if (comment == null) throw Errors.notFound('Comment');
    final thread = (await CommentThread.db.findById(
      session,
      comment.threadId,
    ))!;
    final (_, item, role) = await _thread(session, actor, thread.uuid);
    if (comment.authorId != actor.userId && !(role >= Role.editor)) {
      throw Errors.forbidden('Only the author can delete this comment.');
    }
    final first = await Comment.db.findFirstRow(
      session,
      where: (t) => t.threadId.equals(thread.id!),
      orderBy: (t) => t.createdAt,
    );
    if (first?.id == comment.id) {
      await deleteThread(session, actor, thread.uuid);
      return;
    }
    await Comment.db.updateRow(
      session,
      comment.copyWith(deletedAt: nowUtc()),
      columns: (t) => [t.deletedAt],
    );
    await _signal(session, item, CommentEventKind.threadUpdated, thread.uuid);
  }

  /// Deletes a thread (author of the root comment, or Editors+).
  static Future<void> deleteThread(
    Session session,
    Actor actor,
    UuidValue threadUuid,
  ) async {
    final (thread, item, role) = await _thread(session, actor, threadUuid);
    if (thread.createdById != actor.userId && !(role >= Role.editor)) {
      throw Errors.forbidden('Only the author or an editor can delete this.');
    }
    await CommentThread.db.deleteRow(session, thread);
    await _signal(session, item, CommentEventKind.threadDeleted, thread.uuid);
  }

  static Future<CommentThreadView> resolve(
    Session session,
    Actor actor,
    UuidValue threadUuid,
  ) => _setStatus(session, actor, threadUuid, CommentStatus.resolved);

  static Future<CommentThreadView> reopen(
    Session session,
    Actor actor,
    UuidValue threadUuid,
  ) => _setStatus(session, actor, threadUuid, CommentStatus.open);

  static Future<CommentThreadView> _setStatus(
    Session session,
    Actor actor,
    UuidValue threadUuid,
    CommentStatus status,
  ) async {
    final (thread, item, _) = await _thread(session, actor, threadUuid);
    if (thread.status == status) {
      return (await viewsOf(session, item, [thread])).single;
    }
    final now = nowUtc();
    await session.db.transaction((tx) async {
      await CommentThread.db.updateRow(
        session,
        thread.copyWith(
          status: status,
          updatedAt: now,
          resolvedById: status == CommentStatus.resolved ? actor.userId : null,
          resolvedAt: status == CommentStatus.resolved ? now : null,
        ),
        columns: (t) => [t.status, t.updatedAt, t.resolvedById, t.resolvedAt],
        transaction: tx,
      );
      await _system(
        session,
        thread,
        actor,
        status == CommentStatus.resolved
            ? CommentSystemEvent.resolved
            : CommentSystemEvent.reopened,
        tx,
      );
    });
    await _signal(session, item, CommentEventKind.statusChanged, thread.uuid);
    return getThread(session, actor, threadUuid);
  }

  static Future<void> _system(
    Session session,
    CommentThread thread,
    Actor? actor,
    CommentSystemEvent event,
    Transaction? tx,
  ) async {
    await Comment.db.insertRow(
      session,
      Comment(
        threadId: thread.id!,
        authorId: actor?.userId,
        authorKind: actor?.kind ?? ActorKind.system,
        body: '',
        mentions: const [],
        createdAt: nowUtc(),
        systemEvent: event,
      ),
      transaction: tx,
    );
  }

  /// Toggles the caller's [emoji] reaction on a comment.
  static Future<CommentView> react(
    Session session,
    Actor actor,
    int commentId,
    String emoji,
  ) async {
    final comment = await Comment.db.findById(session, commentId);
    if (comment == null || comment.deletedAt != null) {
      throw Errors.notFound('Comment');
    }
    final thread = (await CommentThread.db.findById(
      session,
      comment.threadId,
    ))!;
    final (_, item, _) = await _thread(session, actor, thread.uuid);
    final e = emoji.trim();
    if (e.isEmpty || e.length > 16) throw Errors.invalid('Invalid reaction.');
    // Read-modify-write of the JSON under the row lock, so two people
    // reacting at once don't drop each other's reaction.
    await session.db.transaction((tx) async {
      final locked = await Comment.db.findById(
        session,
        commentId,
        transaction: tx,
        lockMode: LockMode.forUpdate,
      );
      if (locked == null) throw Errors.notFound('Comment');
      final reactions = _reactions(locked.reactions);
      final users = reactions[e] ?? <int>[];
      if (users.contains(actor.userId)) {
        users.remove(actor.userId);
      } else {
        users.add(actor.userId);
      }
      if (users.isEmpty) {
        reactions.remove(e);
      } else {
        reactions[e] = users;
      }
      await Comment.db.updateRow(
        session,
        locked.copyWith(reactions: jsonEncode(reactions)),
        columns: (t) => [t.reactions],
        transaction: tx,
      );
    });
    await _signal(session, item, CommentEventKind.threadUpdated, thread.uuid);
    final view = (await viewsOf(session, item, [thread])).single;
    return view.comments.firstWhere((c) => c.id == commentId);
  }

  /// Moves a thread's anchor (Sheets cut/paste, Write re-attach). Editors+
  /// or the thread author.
  static Future<CommentThreadView> updateAnchor(
    Session session,
    Actor actor,
    UuidValue threadUuid,
    String anchorJson, {
    CommentAnchorKind? anchorKind,
  }) async {
    final (thread, item, role) = await _thread(session, actor, threadUuid);
    if (thread.createdById != actor.userId && !(role >= Role.editor)) {
      throw Errors.forbidden();
    }
    try {
      jsonDecode(anchorJson);
    } on FormatException {
      throw Errors.invalid('The anchor is not valid JSON.');
    }
    final reopen = thread.status == CommentStatus.orphaned;
    await CommentThread.db.updateRow(
      session,
      thread.copyWith(
        anchorKind: anchorKind ?? thread.anchorKind,
        anchorJson: anchorJson,
        status: reopen
            ? (thread.statusBeforeOrphan ?? CommentStatus.open)
            : thread.status,
        updatedAt: nowUtc(),
        statusBeforeOrphan: null,
        orphanReasonJson: null,
      ),
      columns: (t) => [
        t.anchorKind,
        t.anchorJson,
        t.updatedAt,
        if (reopen) ...[t.status, t.statusBeforeOrphan, t.orphanReasonJson],
      ],
    );
    await _signal(
      session,
      item,
      reopen ? CommentEventKind.statusChanged : CommentEventKind.threadUpdated,
      thread.uuid,
    );
    return getThread(session, actor, threadUuid);
  }

  // --------------------------------------------------- server transitions

  /// Marks a thread orphaned (its anchored content was deleted), keeping the
  /// previous status for revival. No-op for resolved threads.
  static Future<void> orphan(
    Session session,
    CommentThread thread,
    DriveItem item, {
    Map<String, Object?> reason = const {},
  }) async {
    if (thread.status != CommentStatus.open) return;
    // Conditional on the status still being open (the row was read before).
    final updated = await CommentThread.db.updateWhere(
      session,
      columnValues: (t) => [
        t.status(CommentStatus.orphaned),
        t.statusBeforeOrphan(CommentStatus.open),
        t.orphanReasonJson(jsonEncode(reason)),
        t.updatedAt(nowUtc()),
      ],
      where: (t) =>
          t.id.equals(thread.id!) & t.status.equals(CommentStatus.open),
    );
    if (updated.isEmpty) return;
    await _system(session, thread, null, CommentSystemEvent.orphaned, null);
    await _signal(session, item, CommentEventKind.statusChanged, thread.uuid);
  }

  /// Revives an orphaned thread whose anchor came back.
  static Future<void> revive(
    Session session,
    CommentThread thread,
    DriveItem item,
  ) async {
    if (thread.status != CommentStatus.orphaned) return;
    // Conditional on the thread still being orphaned.
    final updated = await CommentThread.db.updateWhere(
      session,
      columnValues: (t) => [
        t.status(thread.statusBeforeOrphan ?? CommentStatus.open),
        t.statusBeforeOrphan(null),
        t.orphanReasonJson(null),
        t.updatedAt(nowUtc()),
      ],
      where: (t) =>
          t.id.equals(thread.id!) & t.status.equals(CommentStatus.orphaned),
    );
    if (updated.isEmpty) return;
    await _system(session, thread, null, CommentSystemEvent.reopened, null);
    await _signal(session, item, CommentEventKind.statusChanged, thread.uuid);
  }

  /// Resolves or reopens a thread on behalf of the system (suggestion
  /// decisions) with a [CommentSystemEvent].
  static Future<void> systemStatus(
    Session session,
    CommentThread thread,
    DriveItem item,
    CommentStatus status,
    CommentSystemEvent event, {
    Actor? actor,
  }) async {
    final now = nowUtc();
    await CommentThread.db.updateWhere(
      session,
      columnValues: (t) => [
        t.status(status),
        t.updatedAt(now),
        t.resolvedById(
          status == CommentStatus.resolved ? actor?.userId : null,
        ),
        t.resolvedAt(status == CommentStatus.resolved ? now : null),
        t.statusBeforeOrphan(null),
        t.orphanReasonJson(null),
      ],
      where: (t) => t.id.equals(thread.id!),
    );
    await _system(session, thread, actor, event, null);
    await _signal(session, item, CommentEventKind.statusChanged, thread.uuid);
  }

  static Future<void> signal(
    Session session,
    DriveItem item,
    CommentEventKind kind,
    UuidValue threadUuid,
  ) => _signal(session, item, kind, threadUuid);

  static Future<void> _signal(
    Session session,
    DriveItem item,
    CommentEventKind kind,
    UuidValue threadUuid,
  ) => ClusterBus.post(
    session,
    channel(item.uuid),
    CommentSignal(kind: kind, threadUuid: threadUuid),
  );

  /// Live comment changes on [itemUuid].
  static Stream<CommentEvent> watch(
    Session session,
    Actor actor,
    UuidValue itemUuid,
  ) async* {
    final (item, _) = await _requireRead(session, actor, itemUuid);
    final signals = session.messages.createStream<CommentSignal>(
      channel(item.uuid),
    );
    await for (final signal in signals) {
      final current = await DriveItem.db.findById(session, item.id!);
      if (current == null) return;
      final role = await AccessService.effectiveRole(
        session,
        actor.userId,
        current,
      );
      if (role == null || role == Role.viewer && !current.viewersSeeComments) {
        throw Errors.forbidden('You no longer have access to these comments.');
      }
      if (signal.kind == CommentEventKind.threadDeleted) {
        yield CommentEvent(kind: signal.kind, threadUuid: signal.threadUuid);
        continue;
      }
      final thread = await CommentThread.db.findFirstRow(
        session,
        where: (t) => t.uuid.equals(signal.threadUuid),
      );
      if (thread == null) {
        yield CommentEvent(
          kind: CommentEventKind.threadDeleted,
          threadUuid: signal.threadUuid,
        );
        continue;
      }
      yield CommentEvent(
        kind: signal.kind,
        threadUuid: signal.threadUuid,
        thread: (await viewsOf(session, current, [thread])).single,
      );
    }
  }
}
