import 'package:flutter/services.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../l10n/wonky_app_localizations.dart';
import '../shell/shell_services.dart';
import 'comments_controller.dart';

/// One comment as `CommentThreadBody` renders it: the `CommentView`-shaped
/// data both document comments ([ThreadComment.fromCommentView]) and the
/// board (from `BoardCommentView`) supply (specs/16 §7.3).
class ThreadComment {
  const ThreadComment({
    required this.id,
    required this.body,
    required this.createdAt,
    this.authorId,
    this.authorName,
    this.authorColor,
    this.authorAvatarUrl,
    this.authorIsAgent = false,
    this.authorBadge,
    this.editedAt,
    this.deleted = false,
    this.systemText,
    this.reactions = const {},
    this.source,
  });

  /// Unique within the thread; used in widget keys (`<prefix>.event.<id>`).
  final String id;

  /// The author's user id (null: unknown or the system).
  final int? authorId;

  /// The author's display name (null: "Someone").
  final String? authorName;

  /// The author's avatar color (`#rrggbb`; null: muted).
  final String? authorColor;
  final String? authorAvatarUrl;

  /// Written by an agent (MCP, the assistant): a bot avatar.
  final bool authorIsAgent;

  /// A badge next to the author's name (the board's *Admin*).
  final String? authorBadge;

  /// Markdown (rendered with `MarkdownProfile.comment`); empty when deleted.
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool deleted;

  /// A system row (resolved, claimed …): shown as this muted text instead
  /// of a comment.
  final String? systemText;

  /// Emoji → user ids (shown when the actions support reactions).
  final Map<String, List<int>> reactions;

  /// The view this comment was made from (a `CommentView`, a
  /// `BoardCommentView` …), for the actions.
  final Object? source;

  /// A document comment.
  factory ThreadComment.fromCommentView(
    CommentView cm,
    WonkyAppLocalizations l,
  ) {
    final event = cm.systemEvent;
    String? system;
    if (event != null) {
      final who = cm.author?.displayName;
      // Orphaning and reviving are the server's doing (the anchored content
      // was deleted or came back): no "Someone ·" and no raw enum name.
      system = who == null && event == CommentSystemEvent.orphaned
          ? l.commentEventOrphanedBySystem
          : who == null && event == CommentSystemEvent.reopened
          ? l.commentEventRestoredBySystem
          : '${who ?? l.someone} · ${switch (event) {
              CommentSystemEvent.resolved => l.commentEventResolved,
              CommentSystemEvent.reopened => l.commentEventReopened,
              CommentSystemEvent.assigned => l.commentEventAssigned,
              CommentSystemEvent.orphaned => l.commentEventOrphaned,
              CommentSystemEvent.suggestionAccepted => l.commentEventSuggestionAccepted,
              CommentSystemEvent.suggestionRejected => l.commentEventSuggestionRejected,
              CommentSystemEvent.suggestionWithdrawn => l.commentEventSuggestionWithdrawn,
              CommentSystemEvent.suggestionSuperseded => l.commentEventSuggestionSuperseded,
              CommentSystemEvent.suggestionReopened => l.commentEventSuggestionReopened,
            }}';
    }
    return ThreadComment(
      id: '${cm.id}',
      authorId: cm.author?.id,
      authorName: cm.author?.displayName,
      authorColor: cm.author?.avatarColor,
      authorAvatarUrl: cm.author?.avatarUrl,
      authorIsAgent: cm.authorKind.name != 'user',
      body: cm.body,
      createdAt: cm.createdAt,
      editedAt: cm.editedAt,
      deleted: cm.deleted,
      systemText: system,
      reactions: cm.reactions,
      source: cm,
    );
  }
}

/// What `CommentThreadBody` does with a thread (specs/16 §7.3): document
/// comments dispatch `shell.comments.*` ([DocumentCommentThreadActions]),
/// the board its own commands. Optional features (resolve, reactions, copy
/// link, mentions) are off unless overridden.
///
/// Failures thrown by [reply], [edit], [delete], [setResolved] and [react]
/// are shown as the *comment could not be saved* toast.
abstract class CommentThreadActions {
  const CommentThreadActions();

  /// The thread's id, in widget keys (`<keyPrefix>.reply.<threadId>`).
  String get threadId;

  /// The prefix of the widget keys.
  String get keyPrefix => 'comments';

  /// The signed-in user (own reactions are highlighted).
  int? get meId => null;

  /// Whether the reply box is shown.
  bool get canReply;

  /// Whether [c] offers *Edit*.
  bool canEdit(ThreadComment c);

  /// Whether [c] offers *Delete*.
  bool canDelete(ThreadComment c);

  /// Whether deleting [c] deletes the whole thread (*Delete thread*).
  bool deletesThread(ThreadComment c) => false;

  Future<void> reply(String body, {List<int> mentions = const []});
  Future<void> edit(ThreadComment c, String body);
  Future<void> delete(ThreadComment c);

  /// Toggles the signed-in user's [emoji] reaction on a comment; null hides
  /// reactions.
  Future<void> Function(ThreadComment c, String emoji)? get react => null;

  /// Whether the first comment offers Resolve / Reopen.
  bool get canResolve => false;
  bool get resolved => false;
  Future<void> setResolved(bool resolved) async {}

  /// Copies a link to the thread; null hides *Link to comment*.
  Future<void> Function(ThreadComment c)? get copyLink => null;

  /// Whether the reply box suggests @mentions (a `MentionField`); otherwise
  /// it is a `MarkdownComposer`.
  bool get mentions => false;

  /// The maximum length of a reply or edit (null: no limit).
  int? get maxLength => null;

  /// The placeholder of the reply box (null: the default).
  String? replyHint(WonkyAppLocalizations l) => null;

  /// Whether [c] has a checkbox before its author, and whether it is
  /// checked; null shows none (the board's comments for a task prompt,
  /// specs/16 §9.3). [select] changes it, [selectLabel] names it for
  /// screen readers.
  bool? selected(ThreadComment c) => null;
  void select(ThreadComment c, bool selected) {}
  String selectLabel(WonkyAppLocalizations l, ThreadComment c) => '';
}

/// Document comments (Write, Sheets, Slides): the `shell.comments.*`
/// commands, the open document's role and the comments controller.
class DocumentCommentThreadActions extends CommentThreadActions {
  DocumentCommentThreadActions({
    required this.services,
    required this.controller,
    required this.thread,
    this.resolvable = true,
  });

  final ShellServices services;
  final CommentsController controller;
  final CommentThreadView thread;

  /// Whether the thread offers Resolve / Reopen at all (Write's suggestion
  /// cards resolve through accept / reject).
  final bool resolvable;

  Role get _role => services.activeDocument.value?.role ?? Role.viewer;

  bool _mine(ThreadComment c) => c.authorId == services.me?.id;

  Future<void> _invoke(String id, Map<String, Object?> args) =>
      services.dispatcher.invoke(id, args: args, source: InvocationSource.ui);

  @override
  String get threadId => thread.uuid.uuid;

  @override
  int? get meId => services.me?.id;

  @override
  bool get resolved => thread.status == CommentStatus.resolved;

  @override
  bool get canReply => _role.canComment && !resolved;

  @override
  bool get canResolve => _role.canComment && resolvable;

  @override
  bool canEdit(ThreadComment c) => _mine(c);

  @override
  bool canDelete(ThreadComment c) => _mine(c) || _role.canEdit;

  @override
  bool deletesThread(ThreadComment c) =>
      thread.comments.isNotEmpty && '${thread.comments.first.id}' == c.id;

  @override
  bool get mentions => true;

  @override
  Future<void> reply(String body, {List<int> mentions = const []}) => _invoke(
    'shell.comments.reply',
    {'threadUuid': threadId, 'body': body, 'mentions': mentions},
  );

  @override
  Future<void> edit(ThreadComment c, String body) =>
      controller.edit(_idOf(c), body);

  @override
  Future<void> delete(ThreadComment c) => _invoke('shell.comments.delete', {
    'threadUuid': threadId,
    if (!deletesThread(c)) 'commentId': _idOf(c),
  });

  @override
  Future<void> setResolved(bool resolved) => _invoke(
    resolved ? 'shell.comments.resolve' : 'shell.comments.reopen',
    {'threadUuid': threadId},
  );

  @override
  Future<void> Function(ThreadComment c)? get copyLink => (c) async {
    final s = services;
    final item = s.currentItem.value;
    if (item == null) return;
    final url =
        '${s.urls.urlFor(s.config.app, s.config.itemPath(item.uuid.uuid))}?comment=$threadId';
    await Clipboard.setData(ClipboardData(text: url));
    final l = s.l10n;
    if (l != null) s.toasts.show(l.toastLinkCopied);
  };

  static int _idOf(ThreadComment c) {
    final src = c.source;
    return src is CommentView ? src.id : int.parse(c.id);
  }
}
