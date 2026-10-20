import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import '../notifications/notification_service.dart';
import 'board_comments.dart';
import 'board_live_streams.dart';
import 'board_markdown.dart';
import 'board_moderation.dart';
import 'board_posts.dart';
import 'board_search.dart';
import 'board_tasks.dart';
import 'board_task_bundles.dart';
import 'board_task_claims.dart';
import 'board_votes.dart';

/// Facade of Bugs & improvements (specs/16): the endpoint delegates here;
/// the work is split by area (posts, votes, comments and flags,
/// moderation, tasks and claims, live streams).
abstract final class BoardService {
  static Future<BoardMe> me(Session session) => BoardPosts.me(session);
  static Future<BoardPostPage> list(Session session, BoardListQuery q) =>
      BoardPosts.list(session, q);
  static Future<BoardCounts> counts(Session session) async {
    final (ideas, bugs) = await BoardSearch.openCounts(session);
    final (upForGrabs, claimed) = await BoardTasks.counts(session);
    return BoardCounts(
      ideas: ideas,
      bugs: bugs,
      upForGrabs: upForGrabs,
      claimed: claimed,
    );
  }

  static Future<BoardPostView> getPost(Session session, int number) =>
      BoardPosts.getPost(session, number);
  static Future<List<BoardCommentView>> listComments(
    Session session, {
    int? postNumber,
    int? taskNumber,
  }) => BoardComments.list(
    session,
    postNumber: postNumber,
    taskNumber: taskNumber,
  );
  static Future<List<BoardSimilarPost>> similar(
    Session session, {
    required String title,
    required String body,
    BoardPostKind? kind,
  }) => BoardPosts.similar(session, title: title, body: body, kind: kind);
  static Future<String?> getScreenshotUrl(Session session, int number) =>
      BoardPosts.getScreenshotUrl(session, number);

  /// Issue #[number] as Markdown (public content only), or null.
  static Future<String?> postMarkdown(Session session, int number) =>
      BoardMarkdown.post(
        session,
        number,
        webOrigin: NotificationService.webOrigin(),
      );
  static Future<BoardTaskPage> listTasks(
    Session session,
    List<BoardTaskStatus> statuses,
    String? cursor,
    int limit,
  ) => BoardTasks.list(session, statuses, cursor, limit);
  static Future<BoardTaskView> getTask(Session session, int number) =>
      BoardTasks.get(session, number);
  static Stream<BoardPostEvent> watchPost(Session session, int number) =>
      BoardStreams.watchPost(session, number);
  static Stream<BoardPostEvent> watchTasks(Session session) =>
      BoardStreams.watchTasks(session);
  static Future<FileUploadTicket> createScreenshotUpload(
    Session session,
    UuidValue fileUuid,
    String mimeType,
    int size,
  ) => BoardPosts.createScreenshotUpload(session, fileUuid, mimeType, size);
  static Future<BoardPostView> createPost(
    Session session,
    BoardPostDraft draft,
  ) => BoardPosts.createPost(session, draft);
  static Future<BoardPostView> editPost(
    Session session,
    int number,
    String title,
    String body,
  ) => BoardPosts.editPost(session, number, title, body);
  static Future<void> deletePost(Session session, int number) =>
      BoardPosts.deletePost(session, number);
  static Future<BoardPostView> restorePost(Session session, int number) =>
      BoardPosts.restorePost(session, number);
  static Future<BoardPostView> removeScreenshot(
    Session session,
    int number,
  ) => BoardPosts.removeScreenshot(session, number);
  static Future<BoardVoteResult> vote(
    Session session,
    int number,
    int value,
  ) => BoardVotes.vote(session, number, value);
  static Future<BoardCommentView> addComment(
    Session session, {
    required UuidValue uuid,
    int? postNumber,
    int? taskNumber,
    required String body,
  }) => BoardComments.add(
    session,
    uuid: uuid,
    postNumber: postNumber,
    taskNumber: taskNumber,
    body: body,
  );
  static Future<BoardCommentView> editComment(
    Session session,
    UuidValue uuid,
    String body,
  ) => BoardComments.edit(session, uuid, body);
  static Future<void> deleteComment(Session session, UuidValue uuid) =>
      BoardComments.delete(session, uuid);
  static Future<BoardCommentView> restoreComment(
    Session session,
    UuidValue uuid,
  ) => BoardComments.restore(session, uuid);
  static Future<void> flag(
    Session session,
    int? number,
    UuidValue? commentUuid,
    BoardFlagReason reason,
    String? note,
  ) => BoardComments.flag(session, number, commentUuid, reason, note);
  static Future<void> unflag(
    Session session,
    int? number,
    UuidValue? commentUuid,
  ) => BoardComments.unflag(session, number, commentUuid);
  static Future<BoardTaskView> claimTask(Session session, int number) =>
      BoardTaskClaims.claim(session, number);
  static Future<BoardTaskView> releaseTask(Session session, int number) =>
      BoardTaskClaims.release(session, number);
  static Future<BoardReviewCounts> reviewCounts(Session session) =>
      BoardModerationService.reviewCounts(session);
  static Future<List<BoardReviewItem>> reviewQueue(
    Session session,
    BoardReviewSection section,
  ) => BoardModerationService.reviewQueue(session, section);
  static Future<BoardPostView> moderatePost(
    Session session,
    int number,
    BoardModerationAction action,
    String? reason,
  ) => BoardModerationService.moderatePost(session, number, action, reason);
  static Future<BoardCommentView> moderateComment(
    Session session,
    UuidValue uuid,
    BoardModerationAction action,
    String? reason,
  ) => BoardModerationService.moderateComment(session, uuid, action, reason);
  static Future<BoardPostView> adminEditPost(
    Session session,
    int number,
    String title,
    String body,
  ) => BoardModerationService.adminEditPost(session, number, title, body);
  static Future<BoardPostView> setLabels(
    Session session,
    int number,
    BoardPostKind kind,
    BoardArea? area,
    BoardSize? size,
  ) => BoardModerationService.setLabels(session, number, kind, area, size);
  static Future<BoardPostView> applySuggestedTitle(
    Session session,
    int number,
  ) => BoardModerationService.applySuggestedTitle(session, number);
  static Future<BoardPostView> dismissDuplicateHint(
    Session session,
    int number,
  ) => BoardModerationService.dismissDuplicateHint(session, number);
  static Future<BoardPostView> merge(
    Session session,
    int source,
    int target,
  ) => BoardModerationService.merge(session, source, target);
  static Future<BoardPostView> unmerge(Session session, int source) =>
      BoardModerationService.unmerge(session, source);
  static Future<BoardPostView> decline(
    Session session,
    int number,
    String reason,
  ) => BoardModerationService.decline(session, number, reason);
  static Future<BoardPostView> reopen(Session session, int number) =>
      BoardModerationService.reopen(session, number);
  static Future<void> blockUser(
    Session session,
    int userId,
    String reason,
    DateTime? until,
  ) => BoardModerationService.blockUser(session, userId, reason, until);
  static Future<void> unblockUser(Session session, int userId) =>
      BoardModerationService.unblockUser(session, userId);
  static Future<BoardTaskView> createTask(
    Session session,
    List<int> postNumbers,
    String title,
    BoardArea area,
    BoardSize size, {
    List<UuidValue> excludedComments = const [],
  }) => BoardTasks.create(
    session,
    postNumbers,
    title,
    area,
    size,
    excludedComments: excludedComments,
  );
  static Future<BoardTaskView> updateTask(
    Session session,
    int number,
    String title,
    BoardArea area,
    BoardSize size,
  ) => BoardTasks.update(session, number, title, area, size);
  static Future<BoardTaskView> setTaskPosts(
    Session session,
    int number,
    List<int> postNumbers,
  ) => BoardTasks.setPosts(session, number, postNumbers);
  static Future<BoardTaskView> mergeTasks(
    Session session,
    List<int> numbers,
    String title,
    BoardArea area,
    BoardSize size,
  ) => BoardTasks.merge(session, numbers, title, area, size);
  static Future<BoardTaskView> unmergeTasks(Session session, int number) =>
      BoardTasks.unmerge(session, number);
  static Future<BoardTaskView> regeneratePrompt(
    Session session,
    int number,
  ) => BoardTasks.regeneratePrompt(session, number);
  static Future<BoardTaskView> setPrompt(
    Session session,
    int number,
    String body,
  ) => BoardTasks.setPrompt(session, number, body);
  static Future<BoardTaskView> publishTask(Session session, int number) =>
      BoardTasks.publish(session, number);
  static Future<BoardTaskView> setTaskStatus(
    Session session,
    int number,
    BoardTaskStatus status,
  ) => BoardTasks.setStatus(session, number, status);
  static Future<BoardTaskView> linkPullRequest(
    Session session,
    int number,
    String? url,
  ) => BoardTasks.linkPullRequest(session, number, url);
  static Future<List<BoardBundleSuggestionView>> suggestBundles(
    Session session,
  ) => BoardTaskBundles.suggestBundles(session);
  static Future<List<BoardBundleSuggestionView>> listSuggestions(
    Session session,
  ) => BoardTaskBundles.listSuggestions(session);
  static Future<void> dismissSuggestion(Session session, int id) =>
      BoardTaskBundles.dismissSuggestion(session, id);
}
