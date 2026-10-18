import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_write_core/wonky_write_core.dart'
    show Delta, DeltaUtils, WonkyAttr;

import '../common/models.dart';
import '../common/time.dart';

/// Copies comment threads with "Make a copy › Copy comments" (Write 08 §1.1,
/// Sheets 10 §5.4).
abstract final class CommentCopier {
  /// Whether a caller with [role] on [source] may copy its comments: the
  /// same rule as reading them (viewers only when the owner lets viewers
  /// see comments, specs/06 §2).
  static bool mayCopy(DriveItem source, Role role) =>
      role > Role.viewer || source.viewersSeeComments;

  /// New thread UUIDs for the copyable (non-suggestion) threads of [source].
  static Future<Map<String, String>> newThreadUuids(
    Session session,
    DriveItem source,
  ) async {
    final threads = await CommentThread.db.find(
      session,
      where: (t) => t.itemId.equals(source.id!) & t.suggestionId.equals(null),
    );
    return {
      for (final t in threads) t.uuid.uuid: const Uuid().v7(),
    };
  }

  /// Rewrites `cmt_<old>` keys to the new thread UUIDs; anchors of unknown
  /// threads and all suggestions are dropped.
  static Delta rewriteAnchors(Delta content, Map<String, String> threadMap) =>
      DeltaUtils.mapAttributes(content, (attrs) {
        if (attrs == null) return null;
        final result = <String, dynamic>{};
        attrs.forEach((key, value) {
          if (WonkyAttr.isSuggestion(key)) return;
          if (WonkyAttr.isComment(key)) {
            final id = WonkyAttr.commentThreadId(key);
            final mapped = id == null ? null : threadMap[id];
            if (mapped != null) result[WonkyAttr.commentKey(mapped)] = value;
            return;
          }
          result[key] = value;
        });
        return result;
      });

  /// Copies the threads of [from] onto [to]. Documents pass [threadMap]
  /// (old → new uuid, from [newThreadUuids]); spreadsheets pass the entity
  /// [anchorIdMap] of the space copy to remap cell anchors.
  static Future<void> copyThreads(
    Session session, {
    required DriveItem from,
    required DriveItem to,
    Map<String, String>? threadMap,
    Map<String, String>? anchorIdMap,
    Transaction? transaction,
  }) async {
    final threads = await CommentThread.db.find(
      session,
      where: (t) => t.itemId.equals(from.id!) & t.suggestionId.equals(null),
      transaction: transaction,
    );
    final uuidPattern = RegExp(
      r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',
    );
    for (final thread in threads) {
      final newUuid = threadMap?[thread.uuid.uuid] ?? const Uuid().v7();
      final anchor = anchorIdMap == null
          ? thread.anchorJson
          : thread.anchorJson.replaceAllMapped(
              uuidPattern,
              (m) => anchorIdMap[m[0]!] ?? m[0]!,
            );
      final copy = await CommentThread.db.insertRow(
        session,
        CommentThread(
          uuid: UuidValue.fromString(newUuid),
          itemId: to.id!,
          anchorKind: thread.anchorKind,
          anchorJson: anchor,
          quotedText: thread.quotedText,
          status: thread.status,
          createdById: thread.createdById,
          createdAt: thread.createdAt,
          updatedAt: nowUtc(),
          resolvedById: thread.resolvedById,
          resolvedAt: thread.resolvedAt,
          assigneeId: thread.assigneeId,
          statusBeforeOrphan: thread.statusBeforeOrphan,
          orphanReasonJson: thread.orphanReasonJson,
        ),
        transaction: transaction,
      );
      final comments = await Comment.db.find(
        session,
        where: (t) => t.threadId.equals(thread.id!),
        orderBy: (t) => t.createdAt,
        transaction: transaction,
      );
      if (comments.isEmpty) continue;
      await Comment.db.insert(
        session,
        [
          for (final c in comments)
            Comment(
              threadId: copy.id!,
              authorId: c.authorId,
              authorKind: c.authorKind,
              body: c.body,
              mentions: c.mentions,
              reactions: c.reactions,
              createdAt: c.createdAt,
              editedAt: c.editedAt,
              deletedAt: c.deletedAt,
              systemEvent: c.systemEvent,
            ),
        ],
        transaction: transaction,
      );
    }
  }
}
