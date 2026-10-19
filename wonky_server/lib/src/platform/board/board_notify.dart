import 'package:serverpod/serverpod.dart';

import '../common/actor.dart';
import '../common/models.dart';
import '../notifications/notification_service.dart';
import 'board_common.dart';

/// Board notifications (specs/16 §12): `boardReply`, `boardStatus` and
/// `boardClaim`. Payloads carry the post or task number, its title and a
/// one-sentence `line` (or an `excerpt` for replies); never emails.
abstract final class BoardNotify {
  /// The author and up-voters of [posts] (deduplicated).
  static Future<Set<int>> authorsAndVoters(
    Session session,
    Iterable<BoardPost> posts, {
    bool voters = true,
  }) async {
    final ids = {for (final p in posts) p.id!};
    final result = {for (final p in posts) ?p.authorId};
    if (voters && ids.isNotEmpty) {
      final votes = await BoardVote.db.find(
        session,
        where: (t) => t.postId.inSet(ids) & (t.value > 0),
      );
      result.addAll(votes.map((v) => v.userId));
    }
    return result;
  }

  static Future<void> status(
    Session session, {
    required Iterable<int> to,
    required String title,
    required String line,
    int? postNumber,
    int? taskNumber,
    Actor? actor,
  }) async {
    for (final userId in to.toSet()) {
      await _safe(
        session,
        () => NotificationService.notify(
          session,
          userId: userId,
          kind: NotificationKind.boardStatus,
          actor: actor,
          payload: {
            'postNumber': ?postNumber,
            'taskNumber': ?taskNumber,
            'title': title,
            'line': line,
          },
        ),
      );
    }
  }

  /// A post's status changed: its author and voters.
  static Future<void> postStatus(
    Session session,
    BoardPost post,
    String line, {
    Actor? actor,
    bool voters = true,
  }) async => status(
    session,
    to: await authorsAndVoters(session, [post], voters: voters),
    postNumber: post.id,
    title: post.title,
    line: line,
    actor: actor,
  );

  static Future<void> reply(
    Session session, {
    required Iterable<int> to,
    required BoardPost post,
    required String body,
    required Actor actor,
  }) async {
    for (final userId in to.toSet()) {
      await _safe(
        session,
        () => NotificationService.notify(
          session,
          userId: userId,
          kind: NotificationKind.boardReply,
          actor: actor,
          payload: {
            'postNumber': post.id,
            'title': post.title,
            'excerpt': BoardText.plain(body, max: 160),
          },
        ),
      );
    }
  }

  static Future<void> claim(
    Session session, {
    required int userId,
    required BoardTask task,
    required String line,
    Actor? actor,
  }) => _safe(
    session,
    () => NotificationService.notify(
      session,
      userId: userId,
      kind: NotificationKind.boardClaim,
      actor: actor,
      payload: {'taskNumber': task.id, 'title': task.title, 'line': line},
    ),
  );

  static Future<void> _safe(
    Session session,
    Future<Object?> Function() send,
  ) async {
    try {
      await send();
    } on Object catch (e) {
      session.log('board: notification failed: $e', level: LogLevel.warning);
    }
  }
}
