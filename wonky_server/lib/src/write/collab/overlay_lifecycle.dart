import 'dart:convert';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show OverlayTransition, SuggestionKind, SuggestionMark, WonkyAttr;

import '../../platform/comments/comment_service.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/models.dart';
import '../../platform/common/time.dart';
import '../../platform/notifications/notification_service.dart';

/// Server-side reactions to overlay transitions (Write 08 §1.4, §2.7–2.11):
/// orphaning/reviving comment threads, creating suggestion threads and
/// inferring suggestion decisions.
abstract final class OverlayLifecycle {
  static const suggestionNotifyWindow = Duration(minutes: 10);

  /// The UUID of the suggestion thread of [suggestionId] in a document:
  /// UUIDv5(documentUuid, "sug:" + id).
  static UuidValue suggestionThreadUuid(
    UuidValue documentUuid,
    String suggestionId,
  ) => const Uuid().v5obj(documentUuid.uuid, 'sug:$suggestionId');

  static Future<void> handle(
    Session session, {
    required DriveItem item,
    required UuidValue documentUuid,
    required Actor actor,
    required Delta before,
    required Delta op,
    required List<OverlayTransition> transitions,
  }) async {
    if (transitions.isEmpty) return;
    final disappearedSug = {
      for (final t in transitions)
        if (!t.appeared && WonkyAttr.isSuggestion(t.key)) t.key,
    };
    final stats = disappearedSug.isEmpty
        ? const <String, _SugStats>{}
        : _collect(before, op, disappearedSug);
    for (final t in transitions) {
      try {
        if (WonkyAttr.isComment(t.key)) {
          await _comment(session, item, t);
        } else if (WonkyAttr.isSuggestion(t.key)) {
          final id = WonkyAttr.suggestionId(t.key)!;
          if (t.appeared) {
            await _suggestionAppeared(
              session,
              item,
              documentUuid,
              actor,
              id,
              _markIn(op, t.key) ?? _markIn(before, t.key),
            );
          } else {
            await _suggestionDecided(
              session,
              item,
              documentUuid,
              actor,
              id,
              stats[t.key],
            );
          }
        }
      } on Object catch (e, st) {
        session.log(
          'Overlay transition ${t.key} failed: $e',
          level: LogLevel.error,
          stackTrace: st,
        );
      }
    }
  }

  static SuggestionMark? _markIn(Delta delta, String key) {
    for (final o in delta.toList()) {
      final v = o.attributes?[key];
      if (v != null) return SuggestionMark.tryParse(v);
    }
    return null;
  }

  static Future<void> _comment(
    Session session,
    DriveItem item,
    OverlayTransition t,
  ) async {
    final threadId = WonkyAttr.commentThreadId(t.key);
    if (threadId == null) return;
    final UuidValue uuid;
    try {
      uuid = UuidValue.withValidation(threadId);
    } on FormatException {
      return;
    }
    final thread = await CommentThread.db.findFirstRow(
      session,
      where: (r) => r.uuid.equals(uuid) & r.itemId.equals(item.id!),
    );
    if (thread == null) return;
    if (t.appeared) {
      await CommentService.revive(session, thread, item);
    } else {
      await CommentService.orphan(
        session,
        thread,
        item,
        reason: {'kind': 'textDeleted'},
      );
    }
  }

  static Future<int?> _userIdOf(Session session, String authUuid) async {
    try {
      final profile = await UserProfile.db.findFirstRow(
        session,
        where: (t) => t.authUserId.equals(UuidValue.withValidation(authUuid)),
      );
      return profile?.id;
    } on FormatException {
      return null;
    }
  }

  static Future<void> _suggestionAppeared(
    Session session,
    DriveItem item,
    UuidValue documentUuid,
    Actor actor,
    String id,
    SuggestionMark? mark,
  ) async {
    final uuid = suggestionThreadUuid(documentUuid, id);
    final existing = await CommentThread.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    );
    if (existing != null) {
      if (existing.status != CommentStatus.open) {
        await CommentService.systemStatus(
          session,
          existing,
          item,
          CommentStatus.open,
          CommentSystemEvent.suggestionReopened,
          actor: actor,
        );
      }
      return;
    }
    final authorId = mark == null
        ? actor.userId
        : (await _userIdOf(session, mark.by) ?? actor.userId);
    final now = nowUtc();
    final thread = await CommentThread.db.insertRow(
      session,
      CommentThread(
        uuid: uuid,
        itemId: item.id!,
        anchorKind: CommentAnchorKind.textRange,
        anchorJson: jsonEncode({'v': 1, 'suggestionId': id}),
        createdById: authorId,
        createdAt: now,
        updatedAt: now,
        suggestionId: id,
      ),
    );
    await CommentService.signal(
      session,
      item,
      CommentEventKind.threadCreated,
      thread.uuid,
    );
    // One notification per author per document per 10 minutes.
    if (item.ownerId != authorId) {
      final recent = await UserNotification.db.findFirstRow(
        session,
        where: (t) =>
            t.userId.equals(item.ownerId) &
            t.itemId.equals(item.id!) &
            t.actorId.equals(authorId) &
            t.kind.equals(NotificationKind.suggestion) &
            (t.createdAt > now.subtract(suggestionNotifyWindow)),
      );
      if (recent == null) {
        await NotificationService.notify(
          session,
          userId: item.ownerId,
          kind: NotificationKind.suggestion,
          item: item,
          actor: Actor(
            userId: authorId,
            authUserId: actor.authUserId,
            kind: actor.kind,
          ),
          payload: {'threadUuid': uuid.uuid, 'suggestionId': id},
        );
      }
    }
  }

  static Future<void> _suggestionDecided(
    Session session,
    DriveItem item,
    UuidValue documentUuid,
    Actor actor,
    String id,
    _SugStats? stats,
  ) async {
    final uuid = suggestionThreadUuid(documentUuid, id);
    final thread = await CommentThread.db.findFirstRow(
      session,
      where: (t) => t.uuid.equals(uuid),
    );
    if (thread == null || thread.status != CommentStatus.open) return;
    final mark = stats?.mark;
    final isAuthor = mark != null && mark.by == actor.authUserId.uuid;
    CommentSystemEvent event;
    if (stats == null || mark == null) {
      event = CommentSystemEvent.suggestionSuperseded;
    } else if (stats.supersededDelete) {
      event = CommentSystemEvent.suggestionSuperseded;
    } else {
      switch (mark.kind) {
        case SuggestionKind.ins:
          event = stats.deleted > 0
              ? (isAuthor
                    ? CommentSystemEvent.suggestionWithdrawn
                    : CommentSystemEvent.suggestionRejected)
              : CommentSystemEvent.suggestionAccepted;
        case SuggestionKind.del:
          event = stats.deleted > 0
              ? CommentSystemEvent.suggestionAccepted
              : (isAuthor
                    ? CommentSystemEvent.suggestionWithdrawn
                    : CommentSystemEvent.suggestionRejected);
        case SuggestionKind.fmt:
          if (stats.deleted > 0) {
            event = CommentSystemEvent.suggestionSuperseded;
          } else if (stats.restoredBefore) {
            event = isAuthor
                ? CommentSystemEvent.suggestionWithdrawn
                : CommentSystemEvent.suggestionRejected;
          } else {
            event = CommentSystemEvent.suggestionAccepted;
          }
      }
    }
    await CommentService.systemStatus(
      session,
      thread,
      item,
      CommentStatus.resolved,
      event,
      actor: actor,
    );
    final decided =
        event == CommentSystemEvent.suggestionAccepted ||
        event == CommentSystemEvent.suggestionRejected;
    if (decided && mark != null && !isAuthor) {
      final authorId = await _userIdOf(session, mark.by);
      if (authorId != null) {
        await NotificationService.notify(
          session,
          userId: authorId,
          kind: NotificationKind.suggestionDecided,
          item: item,
          actor: actor,
          payload: {
            'threadUuid': uuid.uuid,
            'suggestionId': id,
            'decision': event == CommentSystemEvent.suggestionAccepted
                ? 'accepted'
                : 'rejected',
          },
        );
      }
    }
  }

  /// Collects, per disappearing suggestion key, how its characters left.
  static Map<String, _SugStats> _collect(
    Delta before,
    Delta op,
    Set<String> keys,
  ) {
    final stats = {for (final k in keys) k: _SugStats()};
    final doc = DeltaIterator(before);
    for (final o in op.toList()) {
      if (o.isInsert) continue;
      var remaining = o.length!;
      final inThisDelete = <String>{};
      var otherDeleted = false;
      while (remaining > 0 && doc.hasNext) {
        final part = doc.next(remaining);
        final len = part.length!;
        remaining -= len;
        final attrs = part.attributes ?? const <String, dynamic>{};
        var carriesAny = false;
        for (final key in keys) {
          final value = attrs[key];
          if (value == null) continue;
          carriesAny = true;
          final s = stats[key]!;
          s.mark ??= SuggestionMark.tryParse(value);
          if (o.isDelete) {
            s.deleted += len;
            inThisDelete.add(key);
          } else if (o.attributes != null &&
              o.attributes!.containsKey(key) &&
              o.attributes![key] == null) {
            s.kept += len;
            final mark = SuggestionMark.tryParse(value);
            if (mark?.kind == SuggestionKind.fmt) {
              final after = <String, dynamic>{
                for (final e in attrs.entries)
                  if (!WonkyAttr.isOverlay(e.key)) e.key: e.value,
              };
              o.attributes!.forEach((k, v) {
                if (WonkyAttr.isOverlay(k)) return;
                if (v == null) {
                  after.remove(k);
                } else {
                  after[k] = v;
                }
              });
              s.restoredBefore = const DeepCollectionEquality().equals(
                after,
                mark?.before ?? const <String, dynamic>{},
              );
            }
          }
        }
        if (o.isDelete && !carriesAny) otherDeleted = true;
      }
      if (otherDeleted) {
        for (final key in inThisDelete) {
          stats[key]!.supersededDelete = true;
        }
      }
    }
    return stats;
  }
}

class _SugStats {
  SuggestionMark? mark;
  int deleted = 0;
  int kept = 0;
  bool restoredBefore = false;
  bool supersededDelete = false;
}
