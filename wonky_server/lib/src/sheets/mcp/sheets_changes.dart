import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/model.dart'
    show CellRecord, SheetsTables, WorkbookModel;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/revlog/server_change_records.dart';
import '../headless/headless_workbook_provider.dart';
import '../revlog/sheets_server_writes.dart';
import 'sheets_change_records.dart';
import 'sheets_mcp_support.dart';

/// `changes.revert` for spreadsheet changes (Sheets 12 §2.5) and the
/// composite records of assistant runs (§6.2: one undo step "AI: …").
abstract final class SheetsChanges {
  /// Reverts the spreadsheet change [changeId] when it is one (returns null
  /// otherwise, so `changes.revert` can try Write changes). Only the
  /// caller's own changes can be reverted.
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
    final (item, _) = await SheetsMcp.resolveItem(
      ctx.session,
      ctx,
      record.fileUuid.uuid,
      min: Role.editor,
    );
    // Legacy records (before RevLog) keep their inverse inline or in a
    // file; SheetsServerWrites.revert reads both.
    final inverse = await SheetsChangeRecords.inverse(ctx.session, record);
    if (inverse.isEmpty) {
      throw McpToolException(
        McpErrorCode.expired,
        'The change can no longer be reverted.',
      );
    }
    final result = await HeadlessWorkbookProvider.withWriteLock(
      item.contentRef!,
      () async {
        try {
          return await SheetsServerWrites.revert(
            ctx.session,
            ctx.actor,
            item,
            record.changeId,
          );
        } on WonkyException catch (e) {
          if (Errors.isProtectedRange(e)) {
            throw McpToolException(SheetsErrorCode.protectedRange, e.message);
          }
          rethrow;
        }
      },
    );
    final wb = await HeadlessWorkbookProvider.open(
      ctx.session,
      item.contentRef!,
    );
    final skipped = [
      for (final s in result.skipped)
        {
          if (s.table == SheetsTables.cell)
            if (_cellA1(wb.model, s.rowId.uuid) case final String a1) 'a1': a1,
          'table': s.table,
          'column': s.column,
          'reason': s.reason,
          'by': ?s.byUserUuid?.uuid,
        },
    ];
    return {
      'change_id': result.changeId.uuid,
      'reverted_change_id': changeId,
      'spreadsheet': item.uuid.uuid,
      'reverted_cells': result.revertedCells,
      'skipped': skipped,
      'summary':
          'Reverted "${record.label}"'
          '${skipped.isEmpty ? '' : ' (${skipped.length} value(s) changed by others were kept)'}',
    };
  }

  static String? _cellA1(WorkbookModel model, String cellId) {
    final rec = model.record(SheetsTables.cell, cellId);
    if (rec is! CellRecord) return null;
    final s = model.sheet(rec.sheetId);
    if (s == null) return null;
    final r = s.rows.indexOf(rec.rowId);
    final c = s.columns.indexOf(rec.columnId);
    if (r < 0 || c < 0) return null;
    return SheetsMcp.cellA1(model, s.id, r, c);
  }

  // ------------------------------------------------------------ composite

  /// Combines the records [changeIds] of one assistant run into one
  /// [ServerChangeRecord] labeled [label]: reverting it reverts all of them
  /// with the per-column skip rule (Sheets 12 §6.2). One record is returned
  /// as is; null without records.
  static Future<UuidValue?> composite(
    Session session, {
    required Actor actor,
    required DriveItem item,
    required List<String> changeIds,
    required String label,
  }) => ServerChangeRecords.composite(
    session,
    actor: actor,
    fileUuid: item.contentRef!,
    changeIds: changeIds,
    label: label,
  );
}
