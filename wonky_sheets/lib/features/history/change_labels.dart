import '../../l10n/sheets_l10n.dart';

/// The labels Sheets writes on its RevLog ops and server-change entries
/// (CQ-57). They are stable English codes: the change log is shared by
/// collaborators with other languages (and read by older clients, the
/// server and agents), so the text is localized when shown
/// ([changeLabelText]), not when written.
abstract final class SheetsChangeLabels {
  static const typing = 'Typing';
  static const insertAiResult = 'Insert AI result';
  static const insertImage = 'Insert image';
  static const restoreVersion = 'Restore version';
  static const makeCopy = 'Make a copy';
  static const maintenance = 'Maintenance';
  static const createScriptProject = 'Create script project';
  static const deleteScriptProject = 'Delete script project';
  static const createScriptFile = 'Create script file';
  static const renameScriptFile = 'Rename script file';
  static const deleteScriptFile = 'Delete script file';
  static const moveScriptFile = 'Move script file';
  static const saveScriptFile = 'Save script file';
  static const scriptSettings = 'Script settings';
  static const createMacro = 'Create macro';
  static const editMacro = 'Edit macro';
  static const deleteMacro = 'Delete macro';
  static const recordMacro = 'Record macro';
  static const addTrigger = 'Add trigger';
  static const editTrigger = 'Edit trigger';
}

/// The shown text of a stored change [label]: localized for the labels of
/// [SheetsChangeLabels], as stored for others (server changes, labels of
/// other clients).
String changeLabelText(SheetsLocalizations l, String label) => switch (label) {
  SheetsChangeLabels.typing => l.changeLabelTyping,
  SheetsChangeLabels.insertAiResult => l.changeLabelInsertAiResult,
  SheetsChangeLabels.insertImage => l.changeLabelInsertImage,
  SheetsChangeLabels.restoreVersion => l.changeLabelRestoreVersion,
  SheetsChangeLabels.makeCopy => l.changeLabelMakeCopy,
  SheetsChangeLabels.maintenance => l.changeLabelMaintenance,
  SheetsChangeLabels.createScriptProject => l.changeLabelCreateScriptProject,
  SheetsChangeLabels.deleteScriptProject => l.changeLabelDeleteScriptProject,
  SheetsChangeLabels.createScriptFile => l.changeLabelCreateScriptFile,
  SheetsChangeLabels.renameScriptFile => l.changeLabelRenameScriptFile,
  SheetsChangeLabels.deleteScriptFile => l.changeLabelDeleteScriptFile,
  SheetsChangeLabels.moveScriptFile => l.changeLabelMoveScriptFile,
  SheetsChangeLabels.saveScriptFile => l.changeLabelSaveScriptFile,
  SheetsChangeLabels.scriptSettings => l.changeLabelScriptSettings,
  SheetsChangeLabels.createMacro => l.changeLabelCreateMacro,
  SheetsChangeLabels.editMacro => l.changeLabelEditMacro,
  SheetsChangeLabels.deleteMacro => l.changeLabelDeleteMacro,
  SheetsChangeLabels.recordMacro => l.changeLabelRecordMacro,
  SheetsChangeLabels.addTrigger => l.changeLabelAddTrigger,
  SheetsChangeLabels.editTrigger => l.changeLabelEditTrigger,
  _ => label,
};
