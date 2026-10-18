import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:wonky_app/wonky_app.dart' show CommandContext;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';
import 'package:wonky_sync_models/ids.dart' show FractionalIndex;

import '../history/change_labels.dart';
import '../sheet_editor/sheet_editor_controller.dart';

/// Template of a new project's `main.dart` (09 §4).
const scriptTemplate = '''import 'package:wonky/wonky.dart';

/// Runs when the spreadsheet is opened. Add custom menus here.
void onOpen(OpenEvent e) {
  SpreadsheetApp.ui
      .createMenu('My tools')
      .addItem('Say hello', 'sayHello')
      .addToUi();
}

void sayHello() {
  SpreadsheetApp.active.toast('Hello from Wonky Script!');
}
''';

/// `script_file.name` rule (09 §4).
final scriptFileNamePattern = RegExp(r'^[a-z][a-z0-9_]{0,63}\.dart$');

/// Max files per project (09 §4).
const maxScriptFiles = 50;

/// sha256 hex of [source] (`ScriptFile.contentHash`, A-09-2).
String scriptContentHash(String source) =>
    sha256.convert(utf8.encode(source)).toString();

/// Read access to the synced script rows of a workbook (02 §3.6).
abstract final class ScriptProjectRows {
  static String? _projectId(WorkbookModel model) => scriptProjectOf(model)?.id;

  static Iterable<GenericRecord> _of(WorkbookModel model, String table) {
    final p = _projectId(model);
    if (p == null) return const [];
    return model
        .otherRecords(table)
        .where((r) => r.columns[ScriptCols.projectId] == p);
  }

  /// Files ordered by `sortKey` (then name).
  static List<GenericRecord> files(WorkbookModel model) {
    final list = _of(model, SheetsTables.scriptFile).toList()
      ..sort((a, b) {
        final c = '${a.columns[ScriptCols.sortKey]}'.compareTo(
          '${b.columns[ScriptCols.sortKey]}',
        );
        return c != 0 ? c : nameOf(a).compareTo(nameOf(b));
      });
    return list;
  }

  /// The file named [name].
  static GenericRecord? fileNamed(WorkbookModel model, String name) =>
      files(model).where((f) => nameOf(f) == name).firstOrNull;

  /// The file [id].
  static GenericRecord? file(WorkbookModel model, String id) =>
      files(model).where((f) => f.id == id).firstOrNull;

  /// The build row of the project.
  static GenericRecord? build(WorkbookModel model) =>
      _of(model, SheetsTables.scriptBuild).firstOrNull;

  /// Macros ordered by creation.
  static List<GenericRecord> macros(WorkbookModel model) =>
      _of(model, SheetsTables.macro).toList()..sort((a, b) {
        final c = '${a.columns[ScriptCols.createdAt]}'.compareTo(
          '${b.columns[ScriptCols.createdAt]}',
        );
        return c != 0 ? c : a.id.compareTo(b.id);
      });

  /// The macro [id].
  static GenericRecord? macro(WorkbookModel model, String id) =>
      macros(model).where((m) => m.id == id).firstOrNull;

  /// Installable trigger rows.
  static List<GenericRecord> triggers(WorkbookModel model) =>
      _of(model, SheetsTables.scriptTrigger).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  /// `name` of a row.
  static String nameOf(GenericRecord r) => '${r.columns[ScriptCols.name]}';

  /// `source` of a file row.
  static String sourceOf(GenericRecord r) =>
      r.columns[ScriptCols.source] as String? ?? '';

  /// `contentHash` of a file row.
  static String hashOf(GenericRecord r) =>
      r.columns[ScriptCols.contentHash] as String? ?? '';
}

/// Writes to the script rows through the planner (`GenericRowWrite`).
/// Structural changes (project, files, macros, triggers) are undoable
/// steps of the command in [ctx]; saving a file's source is not (09 §14.3).
class ScriptProjectWriter {
  ScriptProjectWriter(this.editor);

  final SheetEditorController editor;

  WorkbookModel get model => editor.model;
  String get _user => editor.session.userId;
  DateTime get _now => clock.now().toUtc();

  String _newId() => editor.services.ids.next().uuid;

  /// The project, created with `main.dart` from the template when missing
  /// (09 §4). Creation is part of the command's undo step.
  GenericRecord ensureProject(CommandContext? ctx) {
    final existing = scriptProjectOf(model);
    if (existing != null) return existing;
    final id = _newId();
    editor.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptProject, id, {
        Cols.spreadsheetId: model.spreadsheetId,
        ScriptCols.name: '${model.spreadsheet.title} script',
        ScriptCols.settingsJson: '{}',
        ScriptCols.createdAt: _now,
      }, label: SheetsChangeLabels.createScriptProject),
    );
    createFile(ctx, 'main.dart', source: scriptTemplate);
    return scriptProjectOf(model)!;
  }

  /// Validates [name] for a new or renamed file; returns an error code
  /// (`invalid`, `duplicate`, `limit`) or null.
  String? checkName(String name, {String? exceptId}) {
    if (!scriptFileNamePattern.hasMatch(name)) return 'invalid';
    final files = ScriptProjectRows.files(model);
    if (files.any(
      (f) => f.id != exceptId && ScriptProjectRows.nameOf(f) == name,
    )) {
      return 'duplicate';
    }
    if (exceptId == null && files.length >= maxScriptFiles) return 'limit';
    return null;
  }

  /// Creates the file [name] at the end of the list.
  String createFile(
    CommandContext? ctx,
    String name, {
    String source = "import 'package:wonky/wonky.dart';\n",
  }) {
    final project = scriptProjectOf(model)!;
    final files = ScriptProjectRows.files(model);
    final last = files.isEmpty
        ? null
        : '${files.last.columns[ScriptCols.sortKey]}';
    final id = _newId();
    editor.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptFile, id, {
        ScriptCols.projectId: project.id,
        ScriptCols.name: name,
        ScriptCols.sortKey: FractionalIndex.between(last, null),
        ScriptCols.source: source,
        ScriptCols.contentHash: scriptContentHash(source),
        'updatedBy': _user,
        'updatedAt': _now,
        ScriptCols.createdAt: _now,
      }, label: SheetsChangeLabels.createScriptFile),
    );
    return id;
  }

  /// Renames the file [id].
  void renameFile(CommandContext? ctx, String id, String name) => editor.apply(
    ctx,
    GenericRowWrite(SheetsTables.scriptFile, id, {
      ScriptCols.name: name,
    }, label: SheetsChangeLabels.renameScriptFile),
  );

  /// Deletes the file [id] (undo restores its source).
  void deleteFile(CommandContext? ctx, String id) => editor.apply(
    ctx,
    GenericRowWrite(
      SheetsTables.scriptFile,
      id,
      const {},
      delete: true,
      label: SheetsChangeLabels.deleteScriptFile,
    ),
  );

  /// Moves the file [id] to [index].
  void reorderFile(CommandContext? ctx, String id, int index) {
    final others = [
      for (final f in ScriptProjectRows.files(model))
        if (f.id != id) f,
    ];
    final i = index.clamp(0, others.length);
    String? key(int j) => j < 0 || j >= others.length
        ? null
        : '${others[j].columns[ScriptCols.sortKey]}';
    editor.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptFile, id, {
        ScriptCols.sortKey: FractionalIndex.between(key(i - 1), key(i)),
      }, label: SheetsChangeLabels.moveScriptFile),
    );
  }

  /// Saves [source] into the file [id] (not an undo step, 09 §14.3).
  /// Returns the new content hash.
  String saveSource(String id, String source) {
    final hash = scriptContentHash(source);
    editor.session.execute(
      GenericRowWrite(SheetsTables.scriptFile, id, {
        ScriptCols.source: source,
        ScriptCols.contentHash: hash,
        'updatedBy': _user,
        'updatedAt': _now,
      }, label: SheetsChangeLabels.saveScriptFile),
    );
    return hash;
  }

  /// Writes the project's settings JSON.
  void updateSettings(CommandContext? ctx, Map<String, Object?> settings) {
    final p = scriptProjectOf(model);
    if (p == null) return;
    editor.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptProject, p.id, {
        ScriptCols.settingsJson: jsonEncode(settings),
      }, label: SheetsChangeLabels.scriptSettings),
    );
  }

  /// Creates a macro row.
  String createMacro(
    CommandContext? ctx, {
    required String name,
    required String functionName,
    int? shortcutSlot,
  }) {
    final project = scriptProjectOf(model)!;
    final id = _newId();
    editor.apply(
      ctx,
      GenericRowWrite(SheetsTables.macro, id, {
        ScriptCols.projectId: project.id,
        ScriptCols.name: name,
        ScriptCols.functionName: functionName,
        ScriptCols.shortcutSlot: shortcutSlot,
        ScriptCols.createdAt: _now,
      }, label: SheetsChangeLabels.createMacro),
    );
    return id;
  }

  /// Updates columns of the macro [id].
  void updateMacro(CommandContext? ctx, String id, Map<String, Object?> cols) =>
      editor.apply(
        ctx,
        GenericRowWrite(
          SheetsTables.macro,
          id,
          cols,
          label: SheetsChangeLabels.editMacro,
        ),
      );

  /// Deletes the macro [id].
  void deleteMacro(CommandContext? ctx, String id) => editor.apply(
    ctx,
    GenericRowWrite(
      SheetsTables.macro,
      id,
      const {},
      delete: true,
      label: SheetsChangeLabels.deleteMacro,
    ),
  );

  /// Writes [source] into `name` (creating it), as part of [ctx]'s step
  /// (macro recording, 09 §15: the file change and the macro row are one
  /// undo step).
  void writeFileInStep(CommandContext? ctx, String name, String source) {
    final f = ScriptProjectRows.fileNamed(model, name);
    if (f == null) {
      createFile(ctx, name, source: source);
      return;
    }
    editor.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptFile, f.id, {
        ScriptCols.source: source,
        ScriptCols.contentHash: scriptContentHash(source),
        'updatedBy': _user,
        'updatedAt': _now,
      }, label: SheetsChangeLabels.recordMacro),
    );
  }
}
