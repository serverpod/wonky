import 'package:serverpod/serverpod.dart';

import '../common/models.dart';
import 'board_service.dart';

/// Bugs & improvements (specs/16 §12). Read methods work signed out; write
/// methods need a signed-in user who is not blocked; admin methods need an
/// admin (specs/16 §9.1). Posts and tasks are addressed by their public
/// number (the row id), for example #123 and T-12.
class BoardEndpoint extends Endpoint {
  // ------------------------------------------------------------------ read

  /// The caller's board status (signed out works).
  Future<BoardMe> me(Session session) => BoardService.me(session);

  Future<BoardPostPage> list(Session session, BoardListQuery query) =>
      BoardService.list(session, query);

  /// The tab counts: open ideas and bugs, *Up for grabs* and *Claimed*.
  Future<BoardCounts> counts(Session session) => BoardService.counts(session);

  Future<BoardPostView> getPost(Session session, int number) =>
      BoardService.getPost(session, number);

  /// Comments of a post, oldest first.
  Future<List<BoardCommentView>> listComments(Session session, int number) =>
      BoardService.listComments(session, postNumber: number);

  /// The activity rows of a task (claimed, released, PR linked …), oldest
  /// first; for admins only (empty for everyone else). Tasks have no
  /// discussion.
  Future<List<BoardCommentView>> listTaskComments(
    Session session,
    int number,
  ) => BoardService.listComments(session, taskNumber: number);

  /// Up to 5 visible posts similar to a draft (specs/16 §6.4).
  Future<List<BoardSimilarPost>> similar(
    Session session,
    String title,
    String body,
    BoardPostKind? kind,
  ) => BoardService.similar(session, title: title, body: body, kind: kind);

  /// A short-lived URL of a post's screenshot, or null.
  Future<String?> getScreenshotUrl(Session session, int number) =>
      BoardService.getScreenshotUrl(session, number);

  /// Tasks with [statuses] (empty: published, claimed and inReview). An
  /// expired claim counts as published.
  Future<BoardTaskPage> listTasks(
    Session session,
    List<BoardTaskStatus> statuses,
    String? cursor,
    int limit,
  ) => BoardService.listTasks(session, statuses, cursor, limit);

  Future<BoardTaskView> getTask(Session session, int number) =>
      BoardService.getTask(session, number);

  /// Live changes of a post: votes, comments, moderation, status.
  Stream<BoardPostEvent> watchPost(Session session, int number) =>
      BoardService.watchPost(session, number);

  /// Live task changes (claims, status) for the Up for grabs and Claimed
  /// tabs.
  Stream<BoardPostEvent> watchTasks(Session session) =>
      BoardService.watchTasks(session);

  // ----------------------------------------------------------------- write

  /// Where to upload a screenshot (PNG or JPEG, ≤ 5 MB); finish with
  /// `file.completeUpload`, then pass the uuid to [createPost].
  Future<FileUploadTicket> createScreenshotUpload(
    Session session,
    UuidValue fileUuid,
    String mimeType,
    int size,
  ) => BoardService.createScreenshotUpload(session, fileUuid, mimeType, size);

  Future<BoardPostView> createPost(Session session, BoardPostDraft draft) =>
      BoardService.createPost(session, draft);

  /// The author edits their post (open, not in a task).
  Future<BoardPostView> editPost(
    Session session,
    int number,
    String title,
    String body,
  ) => BoardService.editPost(session, number, title, body);

  /// Soft delete by the author (or an admin).
  Future<void> deletePost(Session session, int number) =>
      BoardService.deletePost(session, number);

  /// Undo of [deletePost].
  Future<BoardPostView> restorePost(Session session, int number) =>
      BoardService.restorePost(session, number);

  /// Deletes the screenshot bytes (author or admin); not undoable.
  Future<BoardPostView> removeScreenshot(Session session, int number) =>
      BoardService.removeScreenshot(session, number);

  /// Votes -1, 0 (remove) or +1; -1 only on ideas.
  Future<BoardVoteResult> vote(Session session, int number, int value) =>
      BoardService.vote(session, number, value);

  /// Adds a comment to post [postNumber]; idempotent on [uuid]. Tasks have
  /// no discussion: a [taskNumber] is refused (`invalidArgument`); the
  /// parameter stays for older clients.
  Future<BoardCommentView> addComment(
    Session session,
    UuidValue uuid,
    int? postNumber,
    int? taskNumber,
    String body,
  ) => BoardService.addComment(
    session,
    uuid: uuid,
    postNumber: postNumber,
    taskNumber: taskNumber,
    body: body,
  );

  Future<BoardCommentView> editComment(
    Session session,
    UuidValue uuid,
    String body,
  ) => BoardService.editComment(session, uuid, body);

  Future<void> deleteComment(Session session, UuidValue uuid) =>
      BoardService.deleteComment(session, uuid);

  /// Undo of [deleteComment].
  Future<BoardCommentView> restoreComment(Session session, UuidValue uuid) =>
      BoardService.restoreComment(session, uuid);

  /// Flags a post ([number]) or a comment ([commentUuid]).
  Future<void> flag(
    Session session,
    int? number,
    UuidValue? commentUuid,
    BoardFlagReason reason,
    String? note,
  ) => BoardService.flag(session, number, commentUuid, reason, note);

  /// Undo of [flag].
  Future<void> unflag(Session session, int? number, UuidValue? commentUuid) =>
      BoardService.unflag(session, number, commentUuid);

  /// Claims a published task for `board.claimHours` (specs/16 §8.1).
  Future<BoardTaskView> claimTask(Session session, int number) =>
      BoardService.claimTask(session, number);

  /// Releases a claim (the claimant or an admin).
  Future<BoardTaskView> releaseTask(Session session, int number) =>
      BoardService.releaseTask(session, number);

  // ----------------------------------------------------------------- admin

  Future<BoardReviewCounts> reviewCounts(Session session) =>
      BoardService.reviewCounts(session);

  Future<List<BoardReviewItem>> reviewQueue(
    Session session,
    BoardReviewSection section,
  ) => BoardService.reviewQueue(session, section);

  Future<BoardPostView> moderatePost(
    Session session,
    int number,
    BoardModerationAction action,
    String? reason,
  ) => BoardService.moderatePost(session, number, action, reason);

  Future<BoardCommentView> moderateComment(
    Session session,
    UuidValue uuid,
    BoardModerationAction action,
    String? reason,
  ) => BoardService.moderateComment(session, uuid, action, reason);

  /// Edit and approve (e.g. removing personal data).
  Future<BoardPostView> adminEditPost(
    Session session,
    int number,
    String title,
    String body,
  ) => BoardService.adminEditPost(session, number, title, body);

  /// Sets kind, area and size (confirms the AI labels; null clears).
  Future<BoardPostView> setLabels(
    Session session,
    int number,
    BoardPostKind kind,
    BoardArea? area,
    BoardSize? size,
  ) => BoardService.setLabels(session, number, kind, area, size);

  Future<BoardPostView> applySuggestedTitle(Session session, int number) =>
      BoardService.applySuggestedTitle(session, number);

  Future<BoardPostView> dismissDuplicateHint(Session session, int number) =>
      BoardService.dismissDuplicateHint(session, number);

  Future<BoardPostView> merge(Session session, int source, int target) =>
      BoardService.merge(session, source, target);

  /// Undo of [merge].
  Future<BoardPostView> unmerge(Session session, int source) =>
      BoardService.unmerge(session, source);

  Future<BoardPostView> decline(Session session, int number, String reason) =>
      BoardService.decline(session, number, reason);

  /// Undo of [decline].
  Future<BoardPostView> reopen(Session session, int number) =>
      BoardService.reopen(session, number);

  Future<void> blockUser(
    Session session,
    int userId,
    String reason,
    DateTime? until,
  ) => BoardService.blockUser(session, userId, reason, until);

  Future<void> unblockUser(Session session, int userId) =>
      BoardService.unblockUser(session, userId);

  /// Creates a draft task from posts and generates its prompt.
  /// [excludedComments] are comments of the posts the admin left out of the
  /// prompt's context (specs/16 §9.3).
  Future<BoardTaskView> createTask(
    Session session,
    List<int> postNumbers,
    String title,
    BoardArea area,
    BoardSize size, {
    List<UuidValue>? excludedComments,
  }) => BoardService.createTask(
    session,
    postNumbers,
    title,
    area,
    size,
    excludedComments: excludedComments ?? const [],
  );

  Future<BoardTaskView> updateTask(
    Session session,
    int number,
    String title,
    BoardArea area,
    BoardSize size,
  ) => BoardService.updateTask(session, number, title, area, size);

  Future<BoardTaskView> setTaskPosts(
    Session session,
    int number,
    List<int> postNumbers,
  ) => BoardService.setTaskPosts(session, number, postNumbers);

  /// Merges the tasks [numbers] into the oldest one, which takes all their
  /// issues and [title], [area] and [size]; the AI rewrites its prompt
  /// (specs/16 §9.3). Only tasks nobody has claimed.
  Future<BoardTaskView> mergeTasks(
    Session session,
    List<int> numbers,
    String title,
    BoardArea area,
    BoardSize size,
  ) => BoardService.mergeTasks(session, numbers, title, area, size);

  /// Reverts the last merge into task [number] (the undo of [mergeTasks]).
  Future<BoardTaskView> unmergeTasks(Session session, int number) =>
      BoardService.unmergeTasks(session, number);

  Future<BoardTaskView> regeneratePrompt(Session session, int number) =>
      BoardService.regeneratePrompt(session, number);

  Future<BoardTaskView> setPrompt(Session session, int number, String body) =>
      BoardService.setPrompt(session, number, body);

  Future<BoardTaskView> publishTask(Session session, int number) =>
      BoardService.publishTask(session, number);

  /// Sets a task's status directly (undo of publish, done, shipped, cancel;
  /// admin fallbacks).
  Future<BoardTaskView> setTaskStatus(
    Session session,
    int number,
    BoardTaskStatus status,
  ) => BoardService.setTaskStatus(session, number, status);

  /// Admin fallback when the GitHub App is not available (specs/16 §8.3).
  Future<BoardTaskView> linkPullRequest(
    Session session,
    int number,
    String? url,
  ) => BoardService.linkPullRequest(session, number, url);

  Future<List<BoardBundleSuggestionView>> suggestBundles(Session session) =>
      BoardService.suggestBundles(session);

  Future<List<BoardBundleSuggestionView>> listSuggestions(Session session) =>
      BoardService.listSuggestions(session);

  Future<void> dismissSuggestion(Session session, int id) =>
      BoardService.dismissSuggestion(session, id);
}
