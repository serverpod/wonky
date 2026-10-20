import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../shell/shell_services.dart';
import 'board_hub.dart';
import 'board_repository.dart';

/// Board operations recorded on the shell stack (specs/16 §9.2, §14): undo
/// and redo call the inverse endpoint (08 §3: undo is a forward change).
enum BoardUndoOp {
  /// `{post, before, after}`: vote values.
  vote,

  /// `{post, before: {title, body}, after: {title, body}}`.
  editPost,

  /// `{post}`: undo restores, redo deletes.
  deletePost,

  /// `{post}` (a report was posted): undo deletes, redo restores.
  createPost,

  /// `{uuid, post?, task?, body}`: undo deletes, redo restores.
  addComment,

  /// `{uuid, before, after}`: comment bodies.
  editComment,

  /// `{uuid, post?, task?}`: undo restores, redo deletes.
  deleteComment,

  /// `{post?, comment?, reason, note?}`: undo unflags, redo flags again.
  flag,

  /// `{task}`: undo releases, redo claims.
  claim,

  /// `{task}`: undo claims, redo releases.
  release,

  /// `{post?, comment?, action, inverse, reason?, inverseReason?}`.
  moderate,

  /// `{post, before: labels, after: labels}`.
  setLabels,

  /// `{post, before: {title, body}, after: {title, body}}` (admin edit,
  /// *Apply suggested title*).
  adminEdit,

  /// `{source, target}`: undo unmerges, redo merges.
  merge,

  /// `{post, reason}`: undo reopens, redo declines.
  decline,

  /// `{post, reason}`: undo declines again with [reason], redo reopens.
  reopen,

  /// `{source, target}`: undo merges again, redo unmerges.
  unmerge,

  /// `{user, reason}`: undo unblocks, redo blocks.
  block,

  /// `{task, posts, title, area, size}`: undo cancels, redo creates a new
  /// draft (its number goes into the redone entry).
  createTask,

  /// `{task, before: {title, area, size}, after: …}`.
  updateTask,

  /// `{task, before: [posts], after: [posts]}`.
  setTaskPosts,

  /// `{task, tasks, title, area, size}` ([task] is the oldest of [tasks],
  /// the one that remains): undo unmerges, redo merges again.
  mergeTasks,

  /// `{task, before, after}`: prompt bodies.
  setPrompt,

  /// `{task, before}`: undo sets the prompt body [before] (which also
  /// drops a pending AI pass), redo asks the AI again.
  regeneratePrompt,

  /// `{task, before, after}`: task statuses (publish, done, shipped,
  /// cancel).
  setTaskStatus,

  /// `{task, before: url?, after: url?}`.
  linkPullRequest,
}

class BoardUndoEntry extends UndoEntry {
  const BoardUndoEntry(this.op, this.data);

  final BoardUndoOp op;
  final Map<String, Object?> data;

  static const domainName = 'board';

  @override
  String get domain => domainName;

  @override
  UndoEntry? rebase(RemoteChange change) => this;

  BoardUndoEntry withData(Map<String, Object?> more) =>
      BoardUndoEntry(op, {...data, ...more});
}

/// Applies [BoardUndoEntry]s through the [BoardRepository]; a `notFound`
/// or `conflict` answer (someone else changed it, the claim was taken) is
/// an [UndoConflict].
class BoardUndoHandler extends UndoHandler<BoardUndoEntry> {
  BoardUndoHandler(this.services);

  final ShellServices services;

  BoardRepository get _repo => services.repositories.board;
  BoardHub get _hub => BoardHub.of(services);

  @override
  String get domain => BoardUndoEntry.domainName;

  @override
  Future<BoardUndoEntry> undo(BoardUndoEntry e) => _apply(e, undo: true);

  @override
  Future<BoardUndoEntry> redo(BoardUndoEntry e) => _apply(e, undo: false);

  Future<BoardUndoEntry> _apply(BoardUndoEntry e, {required bool undo}) async {
    final d = e.data;
    int n(String k) => d[k]! as int;
    int? nOrNull(String k) => d[k] as int?;
    UuidValue u(String k) => UuidValue.fromString(d[k]! as String);
    Map<String, Object?> m(String k) => (d[k]! as Map).cast<String, Object?>();
    final side = undo ? 'before' : 'after';
    try {
      switch (e.op) {
        case BoardUndoOp.vote:
          final value = d[side]! as int;
          await _repo.vote(n('post'), value);
          _hub.myVotes[n('post')] = value;
          _hub.changed(post: n('post'));
        case BoardUndoOp.editPost:
          final v = m(side);
          await _repo.editPost(
            n('post'),
            v['title']! as String,
            v['body']! as String,
          );
          _hub.changed(post: n('post'));
        case BoardUndoOp.adminEdit:
          final v = m(side);
          await _repo.adminEditPost(
            n('post'),
            v['title']! as String,
            v['body']! as String,
          );
          _hub.changed(post: n('post'));
        case BoardUndoOp.deletePost || BoardUndoOp.createPost:
          final remove = (e.op == BoardUndoOp.createPost) == undo;
          remove
              ? await _repo.deletePost(n('post'))
              : await _repo.restorePost(n('post'));
          _hub.changed(post: n('post'));
        case BoardUndoOp.addComment || BoardUndoOp.deleteComment:
          final remove = (e.op == BoardUndoOp.addComment) == undo;
          remove
              ? await _repo.deleteComment(u('uuid'))
              : await _repo.restoreComment(u('uuid'));
          _hub.changed(post: nOrNull('post'), task: nOrNull('task'));
        case BoardUndoOp.editComment:
          final body = d[side]! as String;
          await _repo.editComment(u('uuid'), body);
          _hub.commentBodies[d['uuid']! as String] = body;
          _hub.changed(post: nOrNull('post'), task: nOrNull('task'));
        case BoardUndoOp.flag:
          final comment = d['comment'] as String?;
          final uuid = comment == null ? null : UuidValue.fromString(comment);
          if (undo) {
            await _repo.unflag(number: nOrNull('post'), commentUuid: uuid);
          } else {
            await _repo.flag(
              number: nOrNull('post'),
              commentUuid: uuid,
              reason: BoardFlagReason.values.byName(d['reason']! as String),
              note: d['note'] as String?,
            );
          }
          _hub.changed(post: nOrNull('post'), lists: false);
        case BoardUndoOp.claim || BoardUndoOp.release:
          final claim = (e.op == BoardUndoOp.claim) != undo;
          claim
              ? await _repo.claimTask(n('task'))
              : await _repo.releaseTask(n('task'));
          await _hub.loadMe(force: true);
          _hub.changed(task: n('task'));
        case BoardUndoOp.moderate:
          final action = BoardModerationAction.values.byName(
            (undo ? d['inverse'] : d['action'])! as String,
          );
          final reason = (undo ? d['inverseReason'] : d['reason']) as String?;
          final comment = d['comment'] as String?;
          if (comment != null) {
            await _repo.moderateComment(
              UuidValue.fromString(comment),
              action,
              reason: reason,
            );
          } else {
            await _repo.moderatePost(n('post'), action, reason: reason);
          }
          _hub.changed(post: nOrNull('post'));
        case BoardUndoOp.setLabels:
          final v = m(side);
          await _repo.setLabels(
            n('post'),
            BoardPostKind.values.byName(v['kind']! as String),
            switch (v['area']) {
              final String a => BoardArea.values.byName(a),
              _ => null,
            },
            switch (v['size']) {
              final String s => BoardSize.values.byName(s),
              _ => null,
            },
          );
          _hub.changed(post: n('post'));
        case BoardUndoOp.merge || BoardUndoOp.unmerge:
          final merge = (e.op == BoardUndoOp.merge) != undo;
          merge
              ? await _repo.merge(n('source'), n('target'))
              : await _repo.unmerge(n('source'));
          _hub.changed(post: n('source'));
          _hub.changed(post: n('target'));
        case BoardUndoOp.decline || BoardUndoOp.reopen:
          final decline = (e.op == BoardUndoOp.decline) != undo;
          decline
              ? await _repo.decline(n('post'), d['reason']! as String)
              : await _repo.reopen(n('post'));
          _hub.changed(post: n('post'));
        case BoardUndoOp.block:
          undo
              ? await _repo.unblockUser(n('user'))
              : await _repo.blockUser(n('user'), d['reason']! as String);
          _hub.changed();
        case BoardUndoOp.createTask:
          if (undo) {
            await _repo.setTaskStatus(n('task'), BoardTaskStatus.cancelled);
            _hub.changed(task: n('task'));
            return e;
          }
          final t = await _repo.createTask(
            [for (final p in d['posts']! as List) p as int],
            d['title']! as String,
            BoardArea.values.byName(d['area']! as String),
            BoardSize.values.byName(d['size']! as String),
            excludedComments: [
              for (final u in d['excluded'] as List? ?? const [])
                UuidValue.withValidation(u as String),
            ],
          );
          _hub.changed(task: t.number);
          return e.withData({'task': t.number});
        case BoardUndoOp.updateTask:
          final v = m(side);
          await _repo.updateTask(
            n('task'),
            v['title']! as String,
            BoardArea.values.byName(v['area']! as String),
            BoardSize.values.byName(v['size']! as String),
          );
          _hub.changed(task: n('task'));
        case BoardUndoOp.setTaskPosts:
          await _repo.setTaskPosts(n('task'), [
            for (final p in d[side]! as List) p as int,
          ]);
          _hub.changed(task: n('task'));
        case BoardUndoOp.mergeTasks:
          final tasks = [for (final t in d['tasks']! as List) t as int];
          undo
              ? await _repo.unmergeTasks(n('task'))
              : await _repo.mergeTasks(
                  tasks,
                  d['title']! as String,
                  BoardArea.values.byName(d['area']! as String),
                  BoardSize.values.byName(d['size']! as String),
                );
          for (final t in tasks) {
            _hub.changed(task: t);
          }
        case BoardUndoOp.setPrompt:
          await _repo.setPrompt(n('task'), d[side]! as String);
          _hub.changed(task: n('task'));
        case BoardUndoOp.regeneratePrompt:
          undo
              ? await _repo.setPrompt(n('task'), d['before']! as String)
              : await _repo.regeneratePrompt(n('task'));
          _hub.changed(task: n('task'), lists: false);
        case BoardUndoOp.setTaskStatus:
          final status = BoardTaskStatus.values.byName(d[side]! as String);
          if (!undo && status == BoardTaskStatus.published) {
            await _repo.publishTask(n('task'));
          } else {
            await _repo.setTaskStatus(n('task'), status);
          }
          _hub.changed(task: n('task'));
        case BoardUndoOp.linkPullRequest:
          await _repo.linkPullRequest(n('task'), d[side] as String?);
          _hub.changed(task: n('task'));
      }
      return e;
    } on WonkyException catch (err) {
      if (err.code == WonkyErrorCode.notFound ||
          err.code == WonkyErrorCode.conflict ||
          err.code == WonkyErrorCode.limitExceeded ||
          err.code == WonkyErrorCode.invalidArgument) {
        throw UndoConflict(err.message);
      }
      rethrow;
    }
  }
}
