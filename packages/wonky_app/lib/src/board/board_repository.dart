import 'package:wonky_client/wonky_client.dart';

import '../data/api.dart';

/// Bugs & improvements (specs/16 §12): the `board` endpoint. Read methods
/// work signed out.
abstract class BoardRepository {
  Future<BoardMe> me();
  Future<BoardPostPage> list(BoardListQuery query);

  /// The tab counts: open ideas and bugs, *Up for grabs*, *Claimed*.
  Future<BoardCounts> counts();
  Future<BoardPostView> getPost(int number);
  Future<List<BoardCommentView>> listComments(int number);
  Future<List<BoardCommentView>> listTaskComments(int number);
  Future<List<BoardSimilarPost>> similar(
    String title,
    String body,
    BoardPostKind? kind,
  );
  Future<String?> getScreenshotUrl(int number);
  Future<BoardTaskPage> listTasks(
    List<BoardTaskStatus> statuses, {
    String? cursor,
    int limit = 30,
  });
  Future<BoardTaskView> getTask(int number);
  Stream<BoardPostEvent> watchPost(int number);
  Stream<BoardPostEvent> watchTasks();

  Future<FileUploadTicket> createScreenshotUpload(
    UuidValue fileUuid,
    String mimeType,
    int size,
  );
  Future<BoardPostView> createPost(BoardPostDraft draft);
  Future<BoardPostView> editPost(int number, String title, String body);
  Future<void> deletePost(int number);
  Future<BoardPostView> restorePost(int number);
  Future<BoardPostView> removeScreenshot(int number);
  Future<BoardVoteResult> vote(int number, int value);
  Future<BoardCommentView> addComment(
    UuidValue uuid, {
    int? postNumber,
    int? taskNumber,
    required String body,
  });
  Future<BoardCommentView> editComment(UuidValue uuid, String body);
  Future<void> deleteComment(UuidValue uuid);
  Future<BoardCommentView> restoreComment(UuidValue uuid);
  Future<void> flag({
    int? number,
    UuidValue? commentUuid,
    required BoardFlagReason reason,
    String? note,
  });
  Future<void> unflag({int? number, UuidValue? commentUuid});
  Future<BoardTaskView> claimTask(int number);
  Future<BoardTaskView> releaseTask(int number);

  // Admin.
  Future<BoardReviewCounts> reviewCounts();
  Future<List<BoardReviewItem>> reviewQueue(BoardReviewSection section);
  Future<BoardPostView> moderatePost(
    int number,
    BoardModerationAction action, {
    String? reason,
  });
  Future<BoardCommentView> moderateComment(
    UuidValue uuid,
    BoardModerationAction action, {
    String? reason,
  });
  Future<BoardPostView> adminEditPost(int number, String title, String body);
  Future<BoardPostView> setLabels(
    int number,
    BoardPostKind kind,
    BoardArea? area,
    BoardSize? size,
  );
  Future<BoardPostView> applySuggestedTitle(int number);
  Future<BoardPostView> dismissDuplicateHint(int number);
  Future<BoardPostView> merge(int source, int target);
  Future<BoardPostView> unmerge(int source);
  Future<BoardPostView> decline(int number, String reason);
  Future<BoardPostView> reopen(int number);
  Future<void> blockUser(int userId, String reason, {DateTime? until});
  Future<void> unblockUser(int userId);

  /// [excludedComments]: comments of the posts left out of the prompt's
  /// context (specs/16 §9.3).
  Future<BoardTaskView> createTask(
    List<int> postNumbers,
    String title,
    BoardArea area,
    BoardSize size, {
    List<UuidValue> excludedComments = const [],
  });
  Future<BoardTaskView> updateTask(
    int number,
    String title,
    BoardArea area,
    BoardSize size,
  );
  Future<BoardTaskView> setTaskPosts(int number, List<int> postNumbers);
  Future<BoardTaskView> mergeTasks(
    List<int> numbers,
    String title,
    BoardArea area,
    BoardSize size,
  );
  Future<BoardTaskView> unmergeTasks(int number);
  Future<BoardTaskView> regeneratePrompt(int number);
  Future<BoardTaskView> setPrompt(int number, String body);
  Future<BoardTaskView> publishTask(int number);
  Future<BoardTaskView> setTaskStatus(int number, BoardTaskStatus status);
  Future<BoardTaskView> linkPullRequest(int number, String? url);
  Future<List<BoardBundleSuggestionView>> suggestBundles();
  Future<List<BoardBundleSuggestionView>> listSuggestions();
  Future<void> dismissSuggestion(int id);
}

class ServerBoardRepository implements BoardRepository {
  ServerBoardRepository(this.api);

  final Api api;

  @override
  Future<BoardMe> me() => api.guard((c) => c.board.me());

  @override
  Future<BoardPostPage> list(BoardListQuery query) =>
      api.guard((c) => c.board.list(query));

  @override
  Future<BoardCounts> counts() => api.guard((c) => c.board.counts());

  @override
  Future<BoardPostView> getPost(int number) =>
      api.guard((c) => c.board.getPost(number));

  @override
  Future<List<BoardCommentView>> listComments(int number) =>
      api.guard((c) => c.board.listComments(number));

  @override
  Future<List<BoardCommentView>> listTaskComments(int number) =>
      api.guard((c) => c.board.listTaskComments(number));

  @override
  Future<List<BoardSimilarPost>> similar(
    String title,
    String body,
    BoardPostKind? kind,
  ) => api.guard((c) => c.board.similar(title, body, kind));

  @override
  Future<String?> getScreenshotUrl(int number) =>
      api.guard((c) => c.board.getScreenshotUrl(number));

  @override
  Future<BoardTaskPage> listTasks(
    List<BoardTaskStatus> statuses, {
    String? cursor,
    int limit = 30,
  }) => api.guard((c) => c.board.listTasks(statuses, cursor, limit));

  @override
  Future<BoardTaskView> getTask(int number) =>
      api.guard((c) => c.board.getTask(number));

  @override
  Stream<BoardPostEvent> watchPost(int number) =>
      api.client.board.watchPost(number);

  @override
  Stream<BoardPostEvent> watchTasks() => api.client.board.watchTasks();

  @override
  Future<FileUploadTicket> createScreenshotUpload(
    UuidValue fileUuid,
    String mimeType,
    int size,
  ) => api.guard(
    (c) => c.board.createScreenshotUpload(fileUuid, mimeType, size),
  );

  @override
  Future<BoardPostView> createPost(BoardPostDraft draft) =>
      api.guard((c) => c.board.createPost(draft));

  @override
  Future<BoardPostView> editPost(int number, String title, String body) =>
      api.guard((c) => c.board.editPost(number, title, body));

  @override
  Future<void> deletePost(int number) =>
      api.guard((c) => c.board.deletePost(number));

  @override
  Future<BoardPostView> restorePost(int number) =>
      api.guard((c) => c.board.restorePost(number));

  @override
  Future<BoardPostView> removeScreenshot(int number) =>
      api.guard((c) => c.board.removeScreenshot(number));

  @override
  Future<BoardVoteResult> vote(int number, int value) =>
      api.guard((c) => c.board.vote(number, value));

  @override
  Future<BoardCommentView> addComment(
    UuidValue uuid, {
    int? postNumber,
    int? taskNumber,
    required String body,
  }) =>
      api.guard((c) => c.board.addComment(uuid, postNumber, taskNumber, body));

  @override
  Future<BoardCommentView> editComment(UuidValue uuid, String body) =>
      api.guard((c) => c.board.editComment(uuid, body));

  @override
  Future<void> deleteComment(UuidValue uuid) =>
      api.guard((c) => c.board.deleteComment(uuid));

  @override
  Future<BoardCommentView> restoreComment(UuidValue uuid) =>
      api.guard((c) => c.board.restoreComment(uuid));

  @override
  Future<void> flag({
    int? number,
    UuidValue? commentUuid,
    required BoardFlagReason reason,
    String? note,
  }) => api.guard((c) => c.board.flag(number, commentUuid, reason, note));

  @override
  Future<void> unflag({int? number, UuidValue? commentUuid}) =>
      api.guard((c) => c.board.unflag(number, commentUuid));

  @override
  Future<BoardTaskView> claimTask(int number) =>
      api.guard((c) => c.board.claimTask(number));

  @override
  Future<BoardTaskView> releaseTask(int number) =>
      api.guard((c) => c.board.releaseTask(number));

  @override
  Future<BoardReviewCounts> reviewCounts() =>
      api.guard((c) => c.board.reviewCounts());

  @override
  Future<List<BoardReviewItem>> reviewQueue(BoardReviewSection section) =>
      api.guard((c) => c.board.reviewQueue(section));

  @override
  Future<BoardPostView> moderatePost(
    int number,
    BoardModerationAction action, {
    String? reason,
  }) => api.guard((c) => c.board.moderatePost(number, action, reason));

  @override
  Future<BoardCommentView> moderateComment(
    UuidValue uuid,
    BoardModerationAction action, {
    String? reason,
  }) => api.guard((c) => c.board.moderateComment(uuid, action, reason));

  @override
  Future<BoardPostView> adminEditPost(int number, String title, String body) =>
      api.guard((c) => c.board.adminEditPost(number, title, body));

  @override
  Future<BoardPostView> setLabels(
    int number,
    BoardPostKind kind,
    BoardArea? area,
    BoardSize? size,
  ) => api.guard((c) => c.board.setLabels(number, kind, area, size));

  @override
  Future<BoardPostView> applySuggestedTitle(int number) =>
      api.guard((c) => c.board.applySuggestedTitle(number));

  @override
  Future<BoardPostView> dismissDuplicateHint(int number) =>
      api.guard((c) => c.board.dismissDuplicateHint(number));

  @override
  Future<BoardPostView> merge(int source, int target) =>
      api.guard((c) => c.board.merge(source, target));

  @override
  Future<BoardPostView> unmerge(int source) =>
      api.guard((c) => c.board.unmerge(source));

  @override
  Future<BoardPostView> decline(int number, String reason) =>
      api.guard((c) => c.board.decline(number, reason));

  @override
  Future<BoardPostView> reopen(int number) =>
      api.guard((c) => c.board.reopen(number));

  @override
  Future<void> blockUser(int userId, String reason, {DateTime? until}) =>
      api.guard((c) => c.board.blockUser(userId, reason, until));

  @override
  Future<void> unblockUser(int userId) =>
      api.guard((c) => c.board.unblockUser(userId));

  @override
  Future<BoardTaskView> createTask(
    List<int> postNumbers,
    String title,
    BoardArea area,
    BoardSize size, {
    List<UuidValue> excludedComments = const [],
  }) => api.guard(
    (c) => c.board.createTask(
      postNumbers,
      title,
      area,
      size,
      excludedComments: excludedComments.isEmpty ? null : excludedComments,
    ),
  );

  @override
  Future<BoardTaskView> updateTask(
    int number,
    String title,
    BoardArea area,
    BoardSize size,
  ) => api.guard((c) => c.board.updateTask(number, title, area, size));

  @override
  Future<BoardTaskView> setTaskPosts(int number, List<int> postNumbers) =>
      api.guard((c) => c.board.setTaskPosts(number, postNumbers));

  @override
  Future<BoardTaskView> mergeTasks(
    List<int> numbers,
    String title,
    BoardArea area,
    BoardSize size,
  ) => api.guard((c) => c.board.mergeTasks(numbers, title, area, size));

  @override
  Future<BoardTaskView> unmergeTasks(int number) =>
      api.guard((c) => c.board.unmergeTasks(number));

  @override
  Future<BoardTaskView> regeneratePrompt(int number) =>
      api.guard((c) => c.board.regeneratePrompt(number));

  @override
  Future<BoardTaskView> setPrompt(int number, String body) =>
      api.guard((c) => c.board.setPrompt(number, body));

  @override
  Future<BoardTaskView> publishTask(int number) =>
      api.guard((c) => c.board.publishTask(number));

  @override
  Future<BoardTaskView> setTaskStatus(int number, BoardTaskStatus status) =>
      api.guard((c) => c.board.setTaskStatus(number, status));

  @override
  Future<BoardTaskView> linkPullRequest(int number, String? url) =>
      api.guard((c) => c.board.linkPullRequest(number, url));

  @override
  Future<List<BoardBundleSuggestionView>> suggestBundles() =>
      api.guard((c) => c.board.suggestBundles());

  @override
  Future<List<BoardBundleSuggestionView>> listSuggestions() =>
      api.guard((c) => c.board.listSuggestions());

  @override
  Future<void> dismissSuggestion(int id) =>
      api.guard((c) => c.board.dismissSuggestion(id));
}
