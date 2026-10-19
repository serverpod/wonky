import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_script/wonky_sheets_script.dart';
import 'package:wonky_ui/wonky_ui.dart';

import '../../l10n/sheets_l10n.dart';
import '../data_tools/mcp_dialog.dart';
import '../scripts/script_project.dart';
import '../scripts/script_widgets.dart';
import '../sheet_editor/sheet_editor_controller.dart';
import 'macro_service.dart';

/// The shortcut label of [slot] ("⌘⌥⇧1").
String macroSlotLabel(ShellServices s, int slot) =>
    macroSlotBinding(slot).format(s.keymap.platform);

/// Shortcut options for a select: none + slots 1..10 (conflicts named).
Map<String, String> macroSlotOptions(
  SheetsLocalizations l,
  SheetEditorController ed, {
  String? exceptMacroId,
}) {
  final svc = MacroService.of(ed);
  return {
    '': l.macroShortcutNone,
    for (var slot = 1; slot <= 10; slot++)
      '$slot': () {
        final label = macroSlotLabel(ed.services, slot);
        final other = svc.macroWithSlot(slot, exceptId: exceptMacroId);
        return other == null
            ? label
            : l.macroShortcutTaken(label, ScriptProjectRows.nameOf(other));
      }(),
  };
}

/// The *Save new macro* dialog (09 §15 step 4): name and optional
/// shortcut. Returns (name, slot) or null.
Future<(String, int?)?> showSaveMacroDialog(
  BuildContext context,
  SheetEditorController ed,
) async {
  final l = sheetsL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final n = MacroService.of(ed).macros.length + 1;
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.macroSaveTitle,
      dialogKey: 'dialog.saveMacro',
      fields: [
        TextFieldSpec(
          id: 'name',
          label: l.macroName,
          initial: l.macroDefaultName(n),
          validator: (v) => v.trim().isEmpty ? l.macroNameEmpty : null,
        ),
        SelectFieldSpec(
          id: 'shortcut',
          label: l.macroShortcut,
          options: macroSlotOptions(l, ed),
          initial: '',
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(id: 'save', label: l.dialogSave, primary: true),
      ],
    ),
  );
  if (r?.buttonId != 'save') return null;
  return (r!.text('name').trim(), int.tryParse(r.text('shortcut')));
}

/// *Import macro* (09 §15): a runnable function that is not a macro yet,
/// a name and a shortcut. Returns (function, name, slot) or null.
Future<(String, String, int?)?> showImportMacroDialog(
  BuildContext context,
  SheetEditorController ed,
  ScriptExports exports,
) async {
  final l = sheetsL10n(context);
  final la = WonkyAppLocalizations.of(context);
  final taken = {
    for (final m in MacroService.of(ed).macros)
      '${m.columns[ScriptCols.functionName]}',
  };
  final fns = [
    for (final f in exports.runnableFunctions)
      if (!taken.contains(f.name) && !f.name.startsWith('on')) f.name,
  ];
  if (fns.isEmpty) {
    ed.services.toasts.show(l.macroImportNone);
    return null;
  }
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.cmdMacroImport,
      dialogKey: 'dialog.importMacro',
      fields: [
        SelectFieldSpec(
          id: 'function',
          label: l.triggerFunction,
          options: {for (final f in fns) f: f},
          initial: fns.first,
        ),
        TextFieldSpec(
          id: 'name',
          label: l.macroName,
          placeholder: l.macroNameFromFunction,
          selectAll: false,
        ),
        SelectFieldSpec(
          id: 'shortcut',
          label: l.macroShortcut,
          options: macroSlotOptions(l, ed),
          initial: '',
        ),
      ],
      buttons: [
        DialogButtonSpec(id: 'cancel', label: la.actionCancel),
        DialogButtonSpec(
          id: 'import',
          label: l.macroImportAction,
          primary: true,
        ),
      ],
    ),
  );
  if (r?.buttonId != 'import') return null;
  final fn = r!.text('function');
  final name = r.text('name').trim();
  return (fn, name.isEmpty ? fn : name, int.tryParse(r.text('shortcut')));
}

/// *Manage macros* (09 §15): rename, change shortcut, edit script,
/// remove. Each change is a command (undoable).
Future<void> showManageMacrosDialog(
  BuildContext context,
  SheetEditorController editor,
) => showShadDialog<void>(
  context: context,
  builder: (_) => ManageMacrosDialog(editor: editor),
);

class ManageMacrosDialog extends StatefulWidget {
  const ManageMacrosDialog({super.key, required this.editor});

  final SheetEditorController editor;

  @override
  State<ManageMacrosDialog> createState() => _ManageMacrosDialogState();
}

class _ManageMacrosDialogState extends State<ManageMacrosDialog>
    with McpDialogState<ManageMacrosDialog> {
  SheetEditorController get ed => widget.editor;
  late final MacroService _svc = MacroService.of(ed);
  final Map<String, TextEditingController> _names = {};

  @override
  void initState() {
    super.initState();
    _svc.scripts.addListener(_changed);
  }

  @override
  void dispose() {
    _svc.scripts.removeListener(_changed);
    for (final c in _names.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _invoke(String id, Map<String, Object?> args) =>
      ed.invokeCommand(id, args, InvocationSource.ui);

  TextEditingController _nameCtl(GenericRecord m) => _names.putIfAbsent(
    m.id,
    () => TextEditingController(text: ScriptProjectRows.nameOf(m)),
  );

  void _rename(GenericRecord m) {
    final name = _nameCtl(m).text.trim();
    if (name.isEmpty || name == ScriptProjectRows.nameOf(m)) return;
    unawaited(_invoke('sheets.macro.update', {'macroId': m.id, 'name': name}));
  }

  @override
  Map<String, Object?> describe() {
    final l = sheetsL10n(context);
    return {
      'title': l.cmdMacroManage,
      'fields': [
        for (final m in _svc.macros) ...[
          {
            'id': 'name.${m.id}',
            'label': l.macroName,
            'type': 'text',
            'value': ScriptProjectRows.nameOf(m),
          },
          {
            'id': 'shortcut.${m.id}',
            'label': l.macroShortcut,
            'type': 'select',
            'value': '${m.columns[ScriptCols.shortcutSlot] ?? ''}',
            'options': macroSlotOptions(
              l,
              ed,
              exceptMacroId: m.id,
            ).keys.toList(),
          },
        ],
      ],
      'buttons': [
        for (final m in _svc.macros)
          {'id': 'remove.${m.id}', 'label': l.macroRemove},
        {'id': 'close', 'label': l.dialogClose},
      ],
    };
  }

  @override
  bool setField(String id, Object? value) {
    if (id.startsWith('name.') && value is String) {
      unawaited(
        _invoke('sheets.macro.update', {
          'macroId': id.substring(5),
          'name': value,
        }),
      );
      return true;
    }
    if (id.startsWith('shortcut.')) {
      unawaited(
        _invoke('sheets.macro.update', {
          'macroId': id.substring(9),
          'shortcutSlot': int.tryParse('${value ?? ''}'),
        }),
      );
      return true;
    }
    return false;
  }

  @override
  bool press(String buttonId) {
    if (buttonId == 'close') {
      Navigator.of(context).pop();
      return true;
    }
    if (buttonId.startsWith('remove.')) {
      unawaited(
        _invoke('sheets.macro.delete', {'macroId': buttonId.substring(7)}),
      );
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final macros = _svc.macros;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.of(context).pop(),
      },
      child: ShadDialog(
        key: const ValueKey<String>('dialog.manageMacros'),
        closeIcon: const WonkyDialogCloseButton(),
        title: Text(l.cmdMacroManage),
        actions: [
          ShadButton.outline(
            key: const ValueKey<String>('dialog.manageMacros.close'),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.dialogClose),
          ),
        ],
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 420),
          child: macros.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l.macrosEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.muted,
                  ),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [for (final m in macros) _row(context, m)],
                ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, GenericRecord m) {
    final l = sheetsL10n(context);
    final theme = ShadTheme.of(context);
    final slot = m.columns[ScriptCols.shortcutSlot] as int?;
    final options = macroSlotOptions(l, ed, exceptMacroId: m.id);
    final fn = '${m.columns[ScriptCols.functionName]}';
    return Padding(
      key: ValueKey<String>('dialog.manageMacros.row.${m.id}'),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Focus(
                  onFocusChange: (f) {
                    if (!f) _rename(m);
                  },
                  child: ShadInput(
                    key: ValueKey<String>('dialog.manageMacros.name.${m.id}'),
                    controller: _nameCtl(m),
                    enabled: ed.canEdit,
                    onSubmitted: (_) => _rename(m),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fn,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(
                    fontFamily: WonkyTheme.monoFamily,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: ShadSelect<String>(
              key: ValueKey<String>('dialog.manageMacros.shortcut.${m.id}'),
              initialValue: '${slot ?? ''}',
              enabled: ed.canEdit,
              minWidth: 150,
              options: [
                for (final e in options.entries)
                  ShadOption(value: e.key, child: Text(e.value)),
              ],
              selectedOptionBuilder: (context, v) =>
                  Text(options[v] ?? '', overflow: TextOverflow.ellipsis),
              onChanged: (v) => unawaited(
                _invoke('sheets.macro.update', {
                  'macroId': m.id,
                  'shortcutSlot': int.tryParse(v ?? ''),
                }),
              ),
            ),
          ),
          scriptIconButton(
            key: ValueKey<String>('dialog.manageMacros.edit.${m.id}'),
            icon: LucideIcons.code,
            tooltip: l.macroEditScript,
            onPressed: () {
              Navigator.of(context).pop();
              unawaited(
                _invoke('sheets.script.openEditor', {'file': macrosFileName}),
              );
            },
          ),
          scriptIconButton(
            key: ValueKey<String>('dialog.manageMacros.remove.${m.id}'),
            icon: LucideIcons.trash2,
            tooltip: l.macroRemove,
            onPressed: ed.canEdit
                ? () => _invoke('sheets.macro.delete', {'macroId': m.id})
                : null,
          ),
        ],
      ),
    );
  }
}
