import 'package:flutter/services.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../../comments/comment_thread_actions.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/shell_services.dart';
import '../board_commands.dart';
import '../board_hub.dart';

/// Maps board comments to the shared thread widget's rows (specs/16 §7.3):
/// system rows (claimed, released, PR linked …) become muted activity text.
List<ThreadComment> boardThreadComments(
  WonkyAppLocalizations l,
  List<BoardCommentView> comments,
) => [
  for (final c in comments)
    ThreadComment(
      id: c.uuid.uuid,
      authorId: c.author?.id,
      authorName: c.author?.displayName ?? l.boardDeletedUser,
      authorColor: c.author?.avatarColor,
      authorAvatarUrl: c.author?.avatarUrl,
      authorBadge: c.author?.isAdmin == true ? l.boardAdmin : null,
      body: c.moderation == BoardModeration.visible || c.deleted
          ? c.body
          : '${c.body}\n\n_${c.moderation == BoardModeration.removed ? l.boardCommentRemoved : l.boardCommentHeld}_',
      createdAt: c.createdAt,
      editedAt: c.editedAt,
      deleted: c.deleted,
      systemText: c.systemEvent == null ? null : boardActivityText(l, c),
      source: c,
    ),
];

/// The text of a system row in a task's activity (specs/16 §4.6): rows
/// by a person read "Ada · claimed the task"; rows of the GitHub
/// integration and the sweep (no author) are full sentences.
String boardActivityText(WonkyAppLocalizations l, BoardCommentView c) {
  final body = c.body.trim();
  final sha = body.length > 7 ? body.substring(0, 7) : body;
  final automatic = switch (c.systemEvent) {
    'expired' => l.boardEventExpired,
    'prClosed' => l.boardEventPrClosed(body),
    'done' when body.isNotEmpty => l.boardEventPrMerged(body),
    'shipped' when body.isNotEmpty => l.boardEventDeployed(sha),
    'prLinked' when c.author == null => l.boardEventPrOpened(body),
    _ => null,
  };
  if (automatic != null) return automatic;
  final who = c.author?.displayName ?? l.someone;
  final what = switch (c.systemEvent) {
    'claimed' => l.boardEventClaimed,
    'released' => l.boardEventReleased,
    'prLinked' => l.boardEventPrLinked(body),
    'prUnlinked' => l.boardEventPrUnlinked,
    'published' => l.boardEventPublished,
    'done' => l.boardEventDone,
    'shipped' => l.boardEventShipped,
    'cancelled' => l.boardEventCancelled,
    'merged' => l.boardEventMerged,
    'mergedInto' => l.boardEventMergedInto(body),
    'mergedTasks' => l.boardEventMergedTasks(body),
    'unmerged' => l.boardEventUnmerged,
    'rewriting' => l.boardEventRewriting,
    _ => c.systemEvent ?? '',
  };
  return '$who · $what';
}

/// [CommentThreadActions] of a post's discussion (tasks have none, specs/16
/// §4.6): the `shell.board.comment.*` commands, Markdown composer (no
/// mentions), author edits, author or admin deletes, *Link to comment*.
class BoardCommentActions extends CommentThreadActions {
  BoardCommentActions({
    required this.services,
    required this.postNumber,
    this.open = true,
  });

  final ShellServices services;
  final int postNumber;

  /// Whether new comments are accepted (not on removed or deleted posts).
  final bool open;

  BoardHub get _hub => BoardHub.of(services);

  BoardCommentView? _view(ThreadComment c) =>
      c.source is BoardCommentView ? c.source! as BoardCommentView : null;

  Map<String, Object?> get _target => {'postNumber': postNumber};

  Future<void> _invoke(String id, Map<String, Object?> args) async {
    final r = await services.dispatcher.invoke(
      id,
      args: args,
      source: InvocationSource.ui,
    );
    if (r.status == CommandStatus.failed) throw StateError(r.message ?? id);
  }

  @override
  String get threadId => 'post-$postNumber';

  @override
  String get keyPrefix => 'board';

  @override
  int? get meId => _hub.me.value?.userId;

  @override
  bool get canReply => open && _hub.canWrite;

  @override
  bool canEdit(ThreadComment c) =>
      _view(c)?.isMine == true && c.systemText == null && _hub.canWrite;

  @override
  bool canDelete(ThreadComment c) =>
      c.systemText == null &&
      _hub.signedIn &&
      (_view(c)?.isMine == true || _hub.isAdmin);

  @override
  int? get maxLength => 10000;

  @override
  String? replyHint(WonkyAppLocalizations l) => l.boardCommentHint;

  @override
  Future<void> reply(String body, {List<int> mentions = const []}) =>
      _invoke('shell.board.comment.add', {..._target, 'body': body});

  @override
  Future<void> edit(ThreadComment c, String body) => _invoke(
    'shell.board.comment.edit',
    {..._target, 'uuid': c.id, 'body': body, 'previousBody': c.body},
  );

  @override
  Future<void> delete(ThreadComment c) =>
      _invoke('shell.board.comment.delete', {..._target, 'uuid': c.id});

  @override
  Future<void> Function(ThreadComment c)? get copyLink => (c) async {
    final s = services;
    final base = boardPostUrl(s, postNumber);
    await Clipboard.setData(ClipboardData(text: '$base#comment-${c.id}'));
    final l = s.l10n;
    if (l != null) s.toasts.show(l.toastLinkCopied);
  };
}
