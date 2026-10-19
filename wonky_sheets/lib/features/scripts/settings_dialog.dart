import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show DateFormat;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource, Role;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';

import '../history/change_labels.dart';
import '../../l10n/sheets_l10n.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'script_project.dart';
import 'script_service.dart';

/// Applies a settings patch (`sheets.script.updateSettings`, 09 §14.7):
/// `name` goes to the project row, the rest into `settingsJson`
/// (`timeZone`, `urlAllowlist`, `showMenusInMenubar`).
void applyScriptSettings(
  CommandContext ctx,
  SheetEditorController ed,
  Map<String, Object?> patch,
) {
  final project = scriptProjectOf(ed.model);
  if (project == null) return;
  final name = patch['name'];
  if (name is String && name.trim().isNotEmpty) {
    ed.apply(
      ctx,
      GenericRowWrite(SheetsTables.scriptProject, project.id, {
        ScriptCols.name: name.trim(),
      }, label: SheetsChangeLabels.scriptSettings),
    );
  }
  final settings = {...ScriptService.of(ed).settings};
  for (final e in patch.entries) {
    if (e.key == 'name') continue;
    if (e.value == null) {
      settings.remove(e.key);
    } else {
      settings[e.key] = e.value;
    }
  }
  ScriptProjectWriter(ed).updateSettings(ctx, settings);
}

/// Project settings (09 §14.7): name, time zone, URL allowlist, "Show
/// script menus in menubar", build info, *Revoke my authorization* and
/// *Delete project* (owner).
Future<void> showScriptSettingsDialog(
  BuildContext context,
  SheetEditorController ed,
) async {
  final l = sheetsL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final svc = ScriptService.of(ed);
  final project = scriptProjectOf(ed.model);
  if (project == null) return;
  final settings = svc.settings;
  final allow = settings['urlAllowlist'];
  final built = svc.builtAt;
  final hash = svc.program?.buildHash;
  final info = [
    l.scriptSettingsApiVersion(wonkyApiVersion),
    if (built != null)
      l.scriptSettingsBuiltAt(
        DateFormat.yMMMd().add_Hm().format(built.toLocal()),
      ),
    if (hash != null) l.scriptSettingsBuildHash(hash.substring(0, 12)),
  ].join(' · ');
  final canEdit = ed.canEdit;
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdScriptOpenSettings,
      description: info,
      dialogKey: 'dialog.scriptSettings',
      width: 480,
      fields: [
        TextFieldSpec(
          id: 'name',
          label: l.scriptSettingsName,
          initial: ScriptProjectRows.nameOf(project),
          validator: (v) => v.trim().isEmpty ? l.scriptSettingsNameEmpty : null,
        ),
        TextFieldSpec(
          id: 'timeZone',
          label: l.scriptSettingsTimeZone,
          initial:
              settings['timeZone'] as String? ?? ed.model.spreadsheet.timeZone,
        ),
        TextFieldSpec(
          id: 'urlAllowlist',
          label: l.scriptSettingsAllowlist,
          initial: allow is List ? allow.join(', ') : '',
          placeholder: 'api.example.com, *.example.org',
          selectAll: false,
        ),
        CheckboxFieldSpec(
          id: 'showMenusInMenubar',
          label: l.scriptSettingsShowMenus,
          initial: svc.showMenusInMenubar,
        ),
      ],
      buttons: [
        DialogButtonSpec(
          id: 'revoke',
          label: l.cmdScriptRevokeAuthorization,
          validates: false,
        ),
        if (ed.itemRole >= Role.owner && canEdit)
          DialogButtonSpec(
            id: 'delete',
            label: l.scriptSettingsDeleteProject,
            destructive: true,
            validates: false,
          ),
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        if (canEdit)
          DialogButtonSpec(id: 'save', label: l.dialogSave, primary: true),
      ],
    ),
  );
  switch (r?.buttonId) {
    case 'save':
      final hosts = [
        for (final h in r!.text('urlAllowlist').split(RegExp(r'[,\s]+')))
          if (h.trim().isNotEmpty) h.trim(),
      ];
      await ed.invokeCommand('sheets.script.updateSettings', {
        'patch': {
          'name': r.text('name').trim(),
          'timeZone': r.text('timeZone').trim(),
          'urlAllowlist': hosts,
          'showMenusInMenubar': r.flag('showMenusInMenubar'),
        },
      }, InvocationSource.ui);
    case 'revoke':
      await ed.invokeCommand(
        'sheets.script.revokeAuthorization',
        const {},
        InvocationSource.ui,
      );
    case 'delete':
      final c = ed.services.navigatorContext;
      if (c == null || !c.mounted) return;
      final ok = await confirmDialog(
        c,
        title: l.scriptDeleteProjectTitle,
        description: l.scriptDeleteProjectBody,
        confirmLabel: l.dialogDelete,
        destructive: true,
      );
      if (ok) {
        unawaited(
          ed.invokeCommand(
            'sheets.script.deleteProject',
            const {},
            InvocationSource.ui,
          ),
        );
      }
  }
}

/// Deletes the project with its files, triggers, macros and build (one
/// undo step; the rows cascade on the server, here they are deleted
/// explicitly so undo restores them).
void deleteScriptProject(CommandContext ctx, SheetEditorController ed) {
  final project = scriptProjectOf(ed.model);
  if (project == null) return;
  final m = ed.model;
  for (final table in [
    SheetsTables.macro,
    SheetsTables.scriptTrigger,
    SheetsTables.scriptProperty,
    SheetsTables.scriptBuild,
    SheetsTables.scriptFile,
  ]) {
    for (final r in m.otherRecords(table).toList()) {
      if (r.columns[ScriptCols.projectId] != project.id) continue;
      ed.apply(ctx, GenericRowWrite(table, r.id, const {}, delete: true));
    }
  }
  ed.apply(
    ctx,
    GenericRowWrite(
      SheetsTables.scriptProject,
      project.id,
      const {},
      delete: true,
      label: SheetsChangeLabels.deleteScriptProject,
    ),
  );
}
