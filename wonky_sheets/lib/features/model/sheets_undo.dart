import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_revlog/undo.dart'
    show RowsUndoEntry, RowsUndoHandler, RowsUndoTarget;

import 'workbook_session.dart';

/// Undo domain of synced-row changes (suite 08 §3.3).
const sheetsRowsDomain = 'sheets.rows';

/// One `sheets.rows` undo entry: the [RowChange]s a plan applied (in order),
/// the shared kit's [RowsUndoEntry]. Undo writes their inverse against the
/// current state with the per-column skip rule (`SheetsUndo`), so
/// collaborators' later edits are never reverted.
class SheetsRowsUndoEntry extends RowsUndoEntry {
  SheetsRowsUndoEntry(
    List<RowChange> changes, {
    String label = '',
    String? groupId,
  }) : super(sheetsRowsDomain, changes, label: label, groupId: groupId);

  @override
  SheetsRowsUndoEntry withChanges(List<RowChange> changes) =>
      SheetsRowsUndoEntry(changes, label: label, groupId: groupId);

  static SheetsRowsUndoEntry? fromJson(Map<String, Object?> json) {
    final decoded = RowsUndoEntry.decode(json);
    if (decoded == null) return null;
    return SheetsRowsUndoEntry(decoded.$1, label: decoded.$2);
  }
}

/// Applies `sheets.rows` entries through the open [WorkbookSession] (the
/// shared kit's [RowsUndoHandler] with Sheets' cell rule).
///
/// Undo and redo are the same operation: invert the entry's changes against
/// the current model (skipping columns someone else changed since) and
/// apply the result; the returned entry holds what was applied, so its
/// inversion is the next redo/undo.
class SheetsRowsUndoHandler extends RowsUndoHandler<SheetsRowsUndoEntry> {
  SheetsRowsUndoHandler(this.session, {super.onPartial})
    : super(columnwise: SheetsUndo.columnwise);

  final WorkbookSession Function() session;

  @override
  String get domain => sheetsRowsDomain;

  @override
  RowsUndoTarget get target => _SessionTarget(session());

  @override
  SheetsRowsUndoEntry entryFor(
    SheetsRowsUndoEntry from,
    List<RowChange> changes,
  ) => SheetsRowsUndoEntry(changes, label: from.label);

  @override
  SheetsRowsUndoEntry? decode(Map<String, Object?> json) =>
      SheetsRowsUndoEntry.fromJson(json);
}

class _SessionTarget implements RowsUndoTarget {
  _SessionTarget(this.session);

  final WorkbookSession session;

  @override
  CurrentRowReader get currentRows => session.model;

  @override
  void applyChanges(
    List<RowChange> changes, {
    required String label,
    String actorKind = 'user',
  }) => session.applyChanges(changes, label: label, actorKind: actorKind);
}
