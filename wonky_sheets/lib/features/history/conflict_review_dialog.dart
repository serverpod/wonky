import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_sheets_core/formula.dart' show CellPos;
import 'package:wonky_sheets_core/model.dart';

import '../sheet_editor/sheet_editor_controller.dart';
import 'cell_history.dart';
import 'cell_history_popover.dart' show historyValueText;

import '../../l10n/sheets_l10n.dart';
import 'local_conflicts.dart';

/// "Sheet1!B4" of a conflict from its ids (the label at detection time
/// when the cell is gone).
String conflictReference(WorkbookModel model, LocalConflict c) {
  final sheet = model.sheet(c.sheetId);
  final row = sheet?.rows.indexOf(c.rowId) ?? -1;
  final col = sheet?.columns.indexOf(c.colId) ?? -1;
  if (sheet == null || row < 0 || col < 0) return c.label ?? '—';
  return '${sheet.name}!${CellPos(row, col).a1}';
}

/// Shown text of a stored content ("(empty)" for none, formulas in A1).
String conflictValue(
  SheetEditorController editor,
  LocalConflict c,
  String? content,
) {
  final l = editor.l10n;
  if (content == null || content.isEmpty) return l.conflictsEmptyValue;
  final text = historyValueText(
    editor,
    CellHistoryTarget(c.sheetId, c.rowId, c.colId),
    content,
  );
  if (text.isEmpty) return l.conflictsEmptyValue;
  return text.length > 60 ? '${text.substring(0, 59)}…' : text;
}

/// The review of overwritten offline edits (Sheets 10 §9): one checkbox per
/// overwritten cell ("B4 — yours: Done · now: Pending (Bo)"), the cells in
/// deleted rows/columns/sheets listed in the description, *Apply mine
/// again* for the checked cells and *Dismiss all*. MCP-operable
/// ([WonkyDialogSpec]).
Future<ConflictReviewChoice?> showConflictReviewDialog(
  BuildContext context, {
  required SheetEditorController editor,
  required List<LocalConflict> conflicts,
}) {
  final model = editor.model;
  final l = sheetsL10n(context);
  String who(LocalConflict c) => c.theirName ?? l.someone;
  return showConflictReview<LocalConflict>(
    context,
    conflicts: conflicts,
    id: (c) => c.id,
    actionable: (c) => c.canApply,
    rowLabel: (c) => l.conflictsRow(
      conflictReference(model, c),
      conflictValue(editor, c, c.myValue),
      conflictValue(editor, c, c.theirValue),
      who(c),
    ),
    goneLine: (c) =>
        '${conflictReference(model, c)}: ${switch (c.kind) {
          LocalConflictKind.sheetDeleted => l.conflictsSheetDeletedBy(who(c)),
          LocalConflictKind.columnDeleted => l.conflictsColumnDeletedBy(who(c)),
          _ => l.conflictsRowDeletedBy(who(c)),
        }} · ${l.conflictsYours(conflictValue(editor, c, c.myValue))}',
    title: l.conflictsTitle,
    description: l.conflictsDescription,
    dialogKey: 'dialog.conflicts',
    width: 560,
    buttons: (anyActionable) => [
      DialogButtonSpec(id: 'dismiss', label: l.conflictsDismissAll),
      if (anyActionable)
        DialogButtonSpec(
          id: 'apply',
          label: l.conflictsApplyMine,
          primary: true,
        ),
    ],
  );
}
