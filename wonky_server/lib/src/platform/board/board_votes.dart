import 'package:serverpod/serverpod.dart';

import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import 'board_access.dart';
import 'board_common.dart';
import 'board_search.dart';

/// Votes (specs/16 §7.2): one per user and post, +1 or −1 (ideas only),
/// while the post is open or planned. Scores are denormalized on the post
/// and exclude votes of blocked users.
abstract final class BoardVotes {
  static const votable = {BoardPostStatus.open, BoardPostStatus.planned};

  /// Recomputes `score` and `voteCount` of [postIds] from the votes of
  /// users who are not blocked.
  static Future<void> recompute(
    Session session,
    Iterable<int> postIds, {
    Transaction? transaction,
  }) async {
    final ids = postIds.toSet();
    if (ids.isEmpty) return;
    await session.db.unsafeExecute(
      '''
      UPDATE board_post p SET
        score = COALESCE((SELECT SUM(v.value) FROM board_vote v
          WHERE v."postId" = p.id AND ${BoardSearch.activeVoter}), 0),
        "voteCount" = (SELECT count(*) FROM board_vote v
          WHERE v."postId" = p.id AND ${BoardSearch.activeVoter})
      WHERE p.id IN (${ids.join(', ')})
      ''',
      parameters: QueryParameters.named({'now': nowUtc()}),
      transaction: transaction,
    );
  }

  /// Recomputes every post [userId] voted on (block, unblock).
  static Future<void> recomputeVotesOf(Session session, int userId) async {
    final votes = await BoardVote.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    await recompute(session, votes.map((v) => v.postId));
  }

  static Future<BoardVoteResult> vote(
    Session session,
    int number,
    int value,
  ) async {
    final c = await BoardAccess.requireWriter(session);
    if (value < -1 || value > 1) {
      throw Errors.invalid('A vote is -1, 0 or 1.');
    }
    final post = await BoardAccess.publicPost(session, c, number);
    if (value == -1 && post.kind == BoardPostKind.bug) {
      throw Errors.invalid('Bugs can only be up-voted.');
    }
    if (!votable.contains(post.status)) {
      throw Errors.conflict('Voting is closed for this post.');
    }
    await BoardRateLimits.check(BoardLimit.votesPerHour, c);
    final changed = await setVote(session, post.id!, c.id, value);
    final updated = (await BoardPost.db.findById(session, post.id!))!;
    if (changed) await BoardLive.post(session, post.id!);
    return BoardVoteResult(
      number: post.id!,
      score: updated.score,
      voteCount: updated.voteCount,
      myVote: value,
    );
  }

  /// Sets [userId]'s vote on [postId] to [value] (0 removes it) and updates
  /// the score in the same transaction. Returns whether anything changed.
  static Future<bool> setVote(
    Session session,
    int postId,
    int userId,
    int value,
  ) => session.db.transaction((tx) async {
    final existing = await BoardVote.db.findFirstRow(
      session,
      where: (t) => t.postId.equals(postId) & t.userId.equals(userId),
      transaction: tx,
    );
    if ((existing?.value ?? 0) == value) return false;
    if (value == 0) {
      await BoardVote.db.deleteRow(session, existing!, transaction: tx);
    } else if (existing != null) {
      await BoardVote.db.updateRow(
        session,
        existing.copyWith(value: value, createdAt: nowUtc()),
        transaction: tx,
        columns: (t) => [t.value, t.createdAt],
      );
    } else {
      await BoardVote.db.insertRow(
        session,
        BoardVote(
          postId: postId,
          userId: userId,
          value: value,
          createdAt: nowUtc(),
        ),
        transaction: tx,
      );
    }
    await recompute(session, [postId], transaction: tx);
    return true;
  });
}
