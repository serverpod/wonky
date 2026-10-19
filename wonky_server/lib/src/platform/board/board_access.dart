import 'package:serverpod/serverpod.dart';

import '../common/actor.dart';
import '../common/errors.dart';
import '../common/models.dart';
import '../common/time.dart';
import '../users/user_service.dart';
import 'board_admins.dart';

/// The caller of a board method (specs/16 §7.1): signed out, a signed-in
/// user, an admin, or a blocked user.
class BoardCaller {
  const BoardCaller.signedOut()
    : actor = null,
      isAdmin = false,
      blocked = false,
      blockedReason = null;

  const BoardCaller({
    required Actor this.actor,
    required this.isAdmin,
    this.blocked = false,
    this.blockedReason,
  });

  final Actor? actor;
  final bool isAdmin;
  final bool blocked;
  final String? blockedReason;

  int? get userId => actor?.userId;
  bool get signedIn => actor != null;

  /// The signed-in user's id (only call after [BoardAccess.requireWriter]).
  int get id => actor!.userId;

  bool isAuthor(int? authorId) => authorId != null && authorId == userId;
}

/// Who may read and write what on the board (specs/16 §7.1, §9.1).
abstract final class BoardAccess {
  static final _callers = Expando<BoardCaller>('boardCaller');

  /// The caller of [session], cached per session.
  static Future<BoardCaller> caller(Session session) async {
    final cached = _callers[session];
    if (cached != null) return cached;
    final BoardCaller result;
    if (session.authenticated == null) {
      result = const BoardCaller.signedOut();
    } else {
      final actor = await UserService.actorOf(session);
      final profile = await BoardUserProfile.db.findFirstRow(
        session,
        where: (t) => t.userId.equals(actor.userId),
      );
      final blocked = isBlocked(profile, nowUtc());
      result = BoardCaller(
        actor: actor,
        isAdmin: await BoardAdmins.isAdminUser(session, actor.userId),
        blocked: blocked,
        blockedReason: blocked ? profile?.blockedReason : null,
      );
    }
    return _callers[session] = result;
  }

  /// Makes [actor] the caller of [session]: MCP tool calls authenticate
  /// with a personal access token, not the session (specs/16 §14).
  static Future<BoardCaller> useActor(Session session, Actor actor) async {
    final profile = await BoardUserProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(actor.userId),
    );
    final blocked = isBlocked(profile, nowUtc());
    return _callers[session] = BoardCaller(
      actor: actor,
      isAdmin: await BoardAdmins.isAdminUser(session, actor.userId),
      blocked: blocked,
      blockedReason: blocked ? profile?.blockedReason : null,
    );
  }

  /// Forgets the cached caller of [session] (after blocking within one
  /// session, tests).
  static void forget(Session session) => _callers[session] = null;

  /// Signed in and not blocked.
  static Future<BoardCaller> requireWriter(Session session) async {
    final c = await caller(session);
    if (!c.signedIn) throw Errors.forbidden('You need to sign in.');
    if (c.blocked) {
      throw Errors.forbidden("You can't post on Bugs & improvements.");
    }
    return c;
  }

  /// A board admin (specs/16 §9.1).
  static Future<BoardCaller> requireAdmin(Session session) async {
    final c = await caller(session);
    if (!c.signedIn) throw Errors.forbidden('You need to sign in.');
    if (!c.isAdmin) throw Errors.forbidden();
    return c;
  }

  static bool isBlocked(BoardUserProfile? profile, DateTime now) =>
      profile?.blockedAt != null &&
      (profile!.blockedUntil == null || profile.blockedUntil!.isAfter(now));

  /// Whether [c] may see [post] at all (specs/16 §3.2): visible posts for
  /// everyone; checking and held ones for the author and admins; removed
  /// ones for admins and (with the reason) the author; soft-deleted ones
  /// for the author and admins.
  static bool canSeePost(BoardCaller c, BoardPost post) {
    if (c.isAdmin) return true;
    final mine = c.isAuthor(post.authorId);
    if (post.deletedAt != null) return mine;
    return post.moderation == BoardModeration.visible || mine;
  }

  /// Whether [c] may see [comment] (its post or task is checked apart).
  static bool canSeeComment(BoardCaller c, BoardComment comment) {
    if (c.isAdmin || comment.systemEvent != null) return true;
    return comment.moderation == BoardModeration.visible ||
        c.isAuthor(comment.authorId);
  }

  /// Draft tasks are for admins only.
  static bool canSeeTask(BoardCaller c, BoardTask task) =>
      c.isAdmin || task.status != BoardTaskStatus.draft;

  /// The post #[number] if [c] may see it; notFound otherwise.
  static Future<BoardPost> post(
    Session session,
    BoardCaller c,
    int number, {
    Transaction? transaction,
  }) async {
    final post = await BoardPost.db.findById(
      session,
      number,
      transaction: transaction,
    );
    if (post == null || !canSeePost(c, post)) throw Errors.notFound('Issue');
    return post;
  }

  /// The public post #[number] (visible, not deleted): votes, flags and
  /// comments by others need it.
  static Future<BoardPost> publicPost(
    Session session,
    BoardCaller c,
    int number, {
    Transaction? transaction,
  }) async {
    final post = await BoardAccess.post(
      session,
      c,
      number,
      transaction: transaction,
    );
    if (post.deletedAt != null || post.moderation != BoardModeration.visible) {
      throw Errors.conflict('This issue is not public.');
    }
    return post;
  }

  /// The task T-[number] if [c] may see it.
  static Future<BoardTask> task(
    Session session,
    BoardCaller c,
    int number, {
    Transaction? transaction,
  }) async {
    final task = await BoardTask.db.findById(
      session,
      number,
      transaction: transaction,
    );
    if (task == null || !canSeeTask(c, task)) throw Errors.notFound('Task');
    return task;
  }
}
