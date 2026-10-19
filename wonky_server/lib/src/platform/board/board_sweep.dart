import 'package:serverpod/serverpod.dart';

import '../common/guarded.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../files/file_service.dart';
import 'board_access.dart';
import 'board_comments.dart';
import 'board_common.dart';
import 'board_pipeline.dart';
import 'board_task_claims.dart';
import 'board_votes.dart';
import 'github/board_github.dart';

/// The recurring board job `wonky.boardSweep` (every 10 minutes, specs/16
/// §8.2, §11): claims, unchecked posts and comments, and retention.
abstract final class BoardSweep {
  static const removedRetention = Duration(days: 90);
  static const deletedRetention = Duration(days: 30);
  static const logRetention = Duration(days: 365);

  /// Runs every part; returns the number of rows touched.
  static Future<int> run(Session session) async {
    var count = 0;
    Future<void> part(String name, Future<int> Function() job) async {
      count += await runGuarded(session, 'board.sweep $name', job) ?? 0;
    }

    await part('expireClaims', () => BoardTaskClaims.expireClaims(session));
    await part('warnClaims', () => BoardTaskClaims.warnClaims(session));
    await part('retriage', () => BoardPipeline.retriageUnchecked(session));
    await part(
      'recheckComments',
      () => BoardComments.recheckUnchecked(session),
    );
    await part('purge', () => purge(session));
    await part('github', () => BoardGithub.sweep(session));
    return count;
  }

  /// Retention (specs/16 §11): removed posts and comments after 90 days
  /// (with their screenshots), posts deleted by their authors after 30
  /// days, the moderation log after a year.
  static Future<int> purge(Session session) async {
    final now = nowUtc();
    final posts = await BoardPost.db.find(
      session,
      where: (t) =>
          (t.moderation.equals(BoardModeration.removed) &
              (t.removedAt < now.subtract(removedRetention))) |
          (t.deletedAt < now.subtract(deletedRetention)),
      limit: 500,
    );
    await deletePosts(session, posts);
    final comments = await BoardComment.db.deleteWhere(
      session,
      where: (t) =>
          t.moderation.equals(BoardModeration.removed) &
          (t.removedAt < now.subtract(removedRetention)),
    );
    final logs = await BoardModerationLog.db.deleteWhere(
      session,
      where: (t) => t.createdAt < now.subtract(logRetention),
    );
    return posts.length + comments.length + logs.length;
  }

  /// Deletes [posts] for good with their screenshot bytes (votes, comments
  /// and flags cascade).
  static Future<void> deletePosts(
    Session session,
    List<BoardPost> posts,
  ) async {
    if (posts.isEmpty) return;
    final fileIds = {for (final p in posts) ?p.screenshotFileId};
    final files = fileIds.isEmpty
        ? const <StoredFile>[]
        : await StoredFile.db.find(session, where: (t) => t.id.inSet(fileIds));
    final ids = {for (final p in posts) p.id!};
    // Merged duplicates keep pointing nowhere: clear the links.
    await BoardPost.db.updateWhere(
      session,
      columnValues: (t) => [t.duplicateOfId(null)],
      where: (t) => t.duplicateOfId.inSet(ids),
    );
    await BoardPost.db.updateWhere(
      session,
      columnValues: (t) => [t.possibleDuplicateOfId(null)],
      where: (t) => t.possibleDuplicateOfId.inSet(ids),
    );
    await BoardPost.db.deleteWhere(session, where: (t) => t.id.inSet(ids));
    for (final f in files) {
      await FileService.deleteFile(session, f.fileUuid);
    }
    for (final id in ids) {
      await BoardLive.post(session, id, BoardEventKind.postRemoved);
    }
  }

  /// Account deletion (specs/16 §11): removes the user's posts that are
  /// not part of a task, all their screenshots and their votes. Their
  /// comments and posts in tasks stay, anonymized when the profile is
  /// deleted (`authorId` is set null).
  static Future<void> deleteUserData(Session session, int userId) async {
    final posts = await BoardPost.db.find(
      session,
      where: (t) => t.authorId.equals(userId) & t.taskId.equals(null),
    );
    await deletePosts(session, posts);
    final votes = await BoardVote.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    await BoardVote.db.deleteWhere(
      session,
      where: (t) => t.userId.equals(userId),
    );
    await BoardVotes.recompute(session, votes.map((v) => v.postId));
    final screenshots = await StoredFile.db.find(
      session,
      where: (t) =>
          t.ownerId.equals(userId) &
          t.kind.equals(StoredFileKind.boardScreenshot),
    );
    for (final f in screenshots) {
      await FileService.deleteFile(session, f.fileUuid);
    }
    BoardAccess.forget(session);
  }
}
