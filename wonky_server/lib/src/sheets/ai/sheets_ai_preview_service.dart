import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/mcp_errors.dart';
import '../headless/headless_workbook.dart';
import '../headless/headless_workbook_provider.dart';
import '../mcp/sheets_bulk_writer.dart';
import '../mcp/sheets_mcp_support.dart';
import '../mcp/sheets_shadow.dart';
import '../mcp/sheets_writes.dart';
import 'sheets_ai_previews.dart';

import 'sheets_ai_service.dart';

/// The AI changes preview of Suggest-mode assistant runs in Sheets (Sheets
/// 12 §6.3): get, apply (one recorded server change) and discard.
abstract final class SheetsAiPreviews {
  // ---------------------------------------------------------- previews

  /// The preview [previewId] of [actor]: the in-memory shadow of this
  /// instance, else the stored copy (any instance, Sheets 12 §6.3).
  static Future<(SheetsShadow?, StoredAiPreview?)> _preview(
    Session session,
    Actor actor,
    String previewId,
  ) async {
    final s = SheetsShadows.preview(previewId);
    if (s != null) {
      if (s.userId != actor.userId) throw Errors.notFound('Preview');
      return (s, null);
    }
    final stored = await SheetsAiPreviewStore.load(session, previewId);
    if (stored == null || stored.userId != actor.userId) {
      throw Errors.notFound('Preview');
    }
    return (null, stored);
  }

  /// The preview of [shadow] for the dialog.
  static SheetsAiPreview previewOf(SheetsShadow shadow, UuidValue itemUuid) =>
      SheetsAiPreview(
        previewId: shadow.previewId,
        itemUuid: itemUuid,
        calls: [
          for (final c in shadow.calls)
            SheetsAiPreviewCall(
              callId: c.callId,
              toolName: c.toolName,
              label: c.label,
              ranges: c.ranges,
              cellsAffected: c.cellsAffected,
              structural: c.structural,
              cells: _previewCells(shadow, c),
            ),
        ],
        expiresAt: shadow.createdAt.add(SheetsShadows.lifetime).toUtc(),
      );

  /// Stores the preview of a finished Suggest-mode run so every instance
  /// can serve it (best effort: the in-memory shadow still works).
  static Future<void> persistPreview(
    Session session,
    SheetsShadow shadow,
    UuidValue itemUuid,
  ) async {
    try {
      await SheetsAiPreviewStore.save(
        session,
        shadow,
        previewOf(shadow, itemUuid),
      );
    } on Object catch (e, st) {
      session.log(
        'Storing AI preview ${shadow.previewId} failed: $e',
        level: LogLevel.warning,
        stackTrace: st,
      );
    }
  }

  /// The AI changes preview (Sheets 12 §6.3): calls with before → after.
  static Future<SheetsAiPreview> getPreview(
    Session session,
    Actor actor,
    String previewId,
  ) async {
    final (shadow, stored) = await _preview(session, actor, previewId);
    if (stored != null) return stored.preview;
    final item = await DriveItem.db.findFirstRow(
      session,
      where: (t) => t.contentRef.equals(shadow!.space),
    );
    if (item == null) throw Errors.notFound('Spreadsheet');
    return previewOf(shadow!, item.uuid);
  }

  static List<SheetsAiPreviewCell> _previewCells(
    SheetsShadow shadow,
    ShadowCall call,
  ) {
    final out = <SheetsAiPreviewCell>[];
    for (final c in call.changes) {
      if (c.table != SheetsTables.cell) continue;
      Object? col(String n) => c.columnsAfter[n] ?? c.columnsBefore[n];
      final sheetId = '${col(Cols.sheetId)}';
      final rowId = '${col(CellCols.rowId)}';
      final colId = '${col(CellCols.columnId)}';
      final after = shadow.wb.model.sheet(sheetId);
      final before = shadow.base.model.sheet(sheetId);
      final s = after ?? before;
      if (s == null) continue;
      final r = s.rows.indexOf(rowId);
      final k = s.columns.indexOf(colId);
      if (r < 0 || k < 0) continue;
      String? display(HeadlessWorkbook wb) {
        final sh = wb.model.sheet(sheetId);
        if (sh == null) return null;
        final rr = sh.rows.indexOf(rowId), kk = sh.columns.indexOf(colId);
        if (rr < 0 || kk < 0) return null;
        final f = wb.formulaAt(sheetId, rr, kk);
        final v = wb.displayAt(sheetId, rr, kk);
        if (f != null) return '$f → $v';
        return v.isEmpty ? null : v;
      }

      out.add(
        SheetsAiPreviewCell(
          cell: SheetsMcp.cellA1(shadow.wb.model, s.id, r, k),
          before: before == null ? null : display(shadow.base),
          after: after == null ? null : display(shadow.wb),
        ),
      );
      if (out.length >= SheetsAiService.maxPreviewCells) break;
    }
    return out;
  }

  /// Applies the selected calls of a preview (all when [callIds] is null)
  /// as one undo step, re-validated against the current state with the
  /// per-column skip rule; the preview is closed.
  static Future<SheetsAiApplyResult> applyPreview(
    Session session,
    Actor actor,
    String previewId,
    List<String>? callIds,
  ) async {
    final (shadow, stored) = await _preview(session, actor, previewId);
    final space = shadow?.space ?? stored!.space;
    final ctx = SheetsAiService.toolContext(session, actor);
    final (item, _) = await McpErrors.guard(
      () => SheetsMcp.resolveItem(session, ctx, space.uuid, min: Role.editor),
    );
    final all = <(String, String, List<RowChange>, Set<String>)>[
      if (shadow != null)
        for (final c in shadow.calls) (c.callId, c.label, c.changes, c.kinds)
      else
        for (final c in stored!.preview.calls)
          if (stored.calls[c.callId] case final x?)
            (c.callId, c.label, x.changes, x.kinds),
    ];
    final selected = [
      for (final c in all)
        if (callIds == null || callIds.contains(c.$1)) c,
    ];
    final label = selected.length == 1
        ? selected.single.$2
        : 'AI: ${selected.length} changes';
    Future<void> close() async {
      SheetsShadows.discard(previewId);
      await SheetsAiPreviewStore.delete(session, previewId);
    }

    if (selected.isEmpty) {
      await close();
      return SheetsAiApplyResult(label: label, cellsAffected: 0, skipped: 0);
    }
    final changes = [for (final c in selected) ...c.$3];
    final kinds = {for (final c in selected) ...c.$4};
    final aiActor = actor.copyWith(kind: ActorKind.ai);
    final (changeId, applied) = await HeadlessWorkbookProvider.withWriteLock(
      space,
      () => SheetsBulkWriter.applyRecorded(
        session,
        actor: aiActor,
        item: item,
        changes: changes,
        label: label,
        plans: const [],
        skipChanged: true,
        kinds: kinds,
      ),
    );
    await SheetsWrites.showCursor(
      session,
      item,
      aiActor,
      SheetsBulkWriter.summaryOf(const [], kinds, changes),
    );
    await close();
    return SheetsAiApplyResult(
      changeId: changeId,
      label: label,
      cellsAffected: applied.cellsAffected,
      skipped: applied.skipped.length,
    );
  }

  /// Discards a preview.
  static Future<void> discardPreview(
    Session session,
    Actor actor,
    String previewId,
  ) async {
    await _preview(session, actor, previewId);
    SheetsShadows.discard(previewId);
    await SheetsAiPreviewStore.delete(session, previewId);
  }
}
