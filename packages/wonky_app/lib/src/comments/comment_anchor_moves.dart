import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wonky_client/wonky_client.dart' show CommentAnchorKind;

import '../commands/command.dart';
import 'comments_controller.dart';
import 'comments_undo.dart';

/// One comment thread re-anchored by a cut & paste: its anchor before and
/// after, encoded (Sheets 10 §3.2, Slides 09 §3.2).
@immutable
class CommentAnchorChange {
  const CommentAnchorChange({
    required this.threadUuid,
    required this.anchorKind,
    required this.beforeJson,
    required this.afterJson,
  });

  final String threadUuid;
  final CommentAnchorKind anchorKind;
  final String beforeJson;
  final String afterJson;
}

/// Moves the threads of [changes] to their new anchors with
/// `comment.updateAnchor` (which also revives a thread the server already
/// orphaned) and records each move in the transaction of [ctx] (undo domain
/// `comments`), so one undo puts the pasted content and its comments back
/// (CQ-53: shared by Sheets and Slides, which compute the moves). Failures
/// are logged; the thread keeps its anchor.
void applyCommentAnchorChanges(
  CommandContext? ctx,
  CommentsController comments,
  Iterable<CommentAnchorChange> changes,
) {
  for (final m in changes) {
    if (ctx?.transaction != null) {
      ctx!.record(
        CommentUndoEntry(
          op: CommentUndoOp.updateAnchor,
          threadUuid: m.threadUuid,
          anchorKind: m.anchorKind,
          anchorJson: m.afterJson,
          previousAnchorJson: m.beforeJson,
        ),
      );
    }
    unawaited(
      comments.updateAnchor(m.threadUuid, m.afterJson).catchError((Object e) {
        debugPrint('Moving comment ${m.threadUuid} failed: $e');
        return comments.thread(m.threadUuid)!;
      }),
    );
  }
}
