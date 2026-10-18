import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/mcp/tool_support.dart';
import '../revlog/slides_server_writes.dart';

/// `changes.revert` for presentation changes (Slides 11 §1.4, §3.12): the
/// deck records share Sheets' `ServerChangeRecord` table (02 §8), so they
/// are recognized by their item before the spreadsheet path.
abstract final class SlidesChanges {
  /// Reverts the deck change [changeId] when it is one (null otherwise).
  /// Only the caller's own changes of the last 24 h can be reverted; the
  /// per-column skip rule keeps what others changed since.
  static Future<Map<String, Object?>?> tryRevert(
    ToolContext ctx,
    String changeId,
  ) async {
    UuidValue id;
    try {
      id = UuidValue.withValidation(changeId);
    } on FormatException {
      return null;
    }
    final record = await ServerChangeRecord.db.findFirstRow(
      ctx.session,
      where: (t) => t.changeId.equals(id),
    );
    if (record == null) return null;
    final item = await DriveItem.db.findFirstRow(
      ctx.session,
      where: (t) =>
          t.contentRef.equals(record.fileUuid) &
          t.kind.equals(DriveItemKind.presentation),
    );
    if (item == null) return null;
    if (record.userId != ctx.actor.userId) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Change not found. Only your own changes of the last 24 hours can '
        'be reverted.',
      );
    }
    if (record.revertedAt != null) {
      throw McpToolException(
        McpErrorCode.conflict,
        'This change was already reverted.',
      );
    }
    if (record.expiresAt.isBefore(clock.now().toUtc())) {
      throw McpToolException(
        McpErrorCode.expired,
        'Changes can only be reverted within 24 hours.',
      );
    }
    final r = await SlidesServerWrites.revert(ctx.session, ctx.actor, id);
    final skipped = [
      for (final s in r.skipped)
        {
          'table': s.table,
          'row_id': s.rowId.uuid,
          'column': s.column,
          'reason': s.reason,
          'by': ?s.byUserUuid?.uuid,
        },
    ];
    return {
      'change_id': r.changeId.uuid,
      'reverted_change_id': changeId,
      'deck': item.uuid.uuid,
      'reverted_rows': r.revertedCells,
      'skipped': skipped,
      'summary':
          'Reverted "${record.label}"'
          '${skipped.isEmpty ? '' : ' (${skipped.length} value(s) changed by others were kept)'}',
    };
  }
}
