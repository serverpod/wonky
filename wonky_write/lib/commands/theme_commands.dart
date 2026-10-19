import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_write_core/wonky_write_core.dart' hide ThemeCatalog;

import '../features/screen/write_document_controller.dart';
import '../features/theme_editor/theme_dialogs.dart';
import '../features/theme_editor/theme_editor_controller.dart';
import '../features/theme_editor/theme_editor_model.dart';
import '../features/theme_editor/theme_library.dart';
import '../features/theme_editor/theme_undo.dart';
import '../features/themes/document_theme.dart';
import '../features/themes/theme_repository.dart';
import '../l10n/write_l10n.dart';
import 'write_command.dart';

/// The path of the theme editor route (Write 06 §10.1).
String themeEditorPath(
  String? themeUuid, {
  String? docItemUuid,
  String? element,
}) {
  final q = {'doc': ?docItemUuid, 'element': ?element};
  final base = themeUuid == null ? '/themes' : '/themes/$themeUuid';
  return Uri(path: base, queryParameters: q.isEmpty ? null : q).toString();
}

/// A theme command (Write 06 §11). Theme editor commands act on the open
/// theme editor ([ThemeEditorController.active]); library commands work
/// anywhere.
class ThemeCommand extends JsonCommand {
  ThemeCommand(
    String id, {
    required this.label,
    required this.run,
    this.descriptionText,
    this.isUndoable = false,
    this.argsSchema = JsonSchema.empty,
    this.needsEditor = false,
    this.needsEditable = false,
    this.showInPalette = true,
    this.icon,
    this.checked,
    this.enabled,
  }) : id = CommandId(id);

  @override
  final CommandId id;
  final WriteText label;
  final WriteText? descriptionText;
  @override
  final bool isUndoable;
  @override
  final JsonSchema argsSchema;
  @override
  final bool showInPalette;
  @override
  final IconData? icon;

  /// Needs the theme editor route.
  final bool needsEditor;

  /// Needs an editable (own, not deleted) theme in the editor.
  final bool needsEditable;
  final bool? Function(ThemeEditorController? editor, JsonArgs args)? checked;
  final bool Function(ThemeEditorController? editor, JsonArgs args)? enabled;
  final FutureOr<CommandResult> Function(
    CommandContext ctx,
    ThemeEditorController? editor,
    JsonArgs args,
  )
  run;

  static ThemeEditorController? get _editor =>
      ThemeEditorController.active.value;

  @override
  String title(BuildContext context) => label(writeL10n(context));

  @override
  String? description(BuildContext context) =>
      descriptionText?.call(writeL10n(context));

  @override
  String? category(BuildContext context) => writeL10n(context).categoryThemes;

  @override
  Role get requiredRole => Role.viewer;

  /// Entries go to explicit stacks (draft / shell), never the document's.
  @override
  UndoTarget get undoTarget => UndoTarget.shell;

  @override
  bool isEnabled(CommandContext ctx, JsonArgs args) {
    final e = _editor;
    if (needsEditor && (e == null || e.loading)) return false;
    if (needsEditable && (e == null || e.readOnly)) return false;
    return enabled?.call(e, args) ?? true;
  }

  @override
  String? disabledReason(CommandContext ctx, JsonArgs args) {
    final e = _editor;
    final l = writeL10nOf(ctx.services);
    if (needsEditor && e == null) return l.commandReasonOpenThemeEditorFirst;
    if (needsEditable && (e?.readOnly ?? true)) {
      return e?.isBuiltin ?? false
          ? l.commandReasonBuiltinThemeReadOnly
          : l.commandReasonThemeReadOnly;
    }
    return null;
  }

  @override
  bool? isChecked(CommandContext ctx, JsonArgs args) =>
      checked?.call(_editor, args);

  @override
  Future<CommandResult> execute(CommandContext ctx, JsonArgs args) async =>
      await run(ctx, _editor, args);
}

ThemeVariant? _variant(JsonArgs a) => switch (a.string('variant')) {
  'dark' => ThemeVariant.dark,
  'light' => ThemeVariant.light,
  _ => null,
};

/// The `write.theme` undo handler and the theme commands of Write 06 §11.
List<Command<CommandArgs>> themeCommands(
  ShellServices s,
  WriteThemeCatalog themes,
) {
  s.undo.registerHandler(
    ThemeUndoHandler(
      repository: () => themeRepositoryFor(s),
      catalog: themes,
      host: () => ThemeEditorController.active.value,
    ),
  );

  ThemeLibrary? library() {
    final repo = themeRepositoryFor(s);
    return repo == null
        ? null
        : ThemeLibrary(
            repository: repo,
            catalog: themes,
            undo: s.undo,
            strings: () => writeL10nOf(s),
          );
  }

  WriteLocalizations l10n() => writeL10nOf(s);

  CommandResult editResult(ThemeEditResult r) => r.isOk
      ? CommandResult.ok(r.data)
      : CommandResult.failed(r.error ?? l10n().commandToastFailed);

  BuildContext? ui(CommandContext ctx) =>
      ctx.source.isAgent ? null : ctx.dialogContext;

  String? docItem(CommandContext ctx) {
    final d = WriteDocumentController.of(ctx);
    return d?.itemUuid.uuid ??
        ThemeEditorController.active.value?.documentItemUuid;
  }

  void open(String uuid, {String? doc, String? element}) =>
      s.router.go(themeEditorPath(uuid, docItemUuid: doc, element: element));

  String? targetUuid(ThemeEditorController? e, JsonArgs a) =>
      a.string('themeUuid') ?? e?.themeUuid;

  const themeArg = JsonSchema.object(
    properties: {'themeUuid': JsonSchema.string()},
  );

  return [
    // ------------------------------------------------------------ open
    ThemeCommand(
      'write.theme.openEditor',
      label: (l) => l.cmdThemeOpenEditor,
      descriptionText: (l) => l.cmdThemeOpenEditorDescription,
      icon: LucideIcons.paintbrush,
      argsSchema: const JsonSchema.object(
        properties: {
          'themeUuid': JsonSchema.string(),
          'element': JsonSchema.string(),
        },
      ),
      run: (ctx, e, a) {
        final d = WriteDocumentController.of(ctx);
        final uuid =
            a.string('themeUuid') ??
            d?.documentTheme.option.uuid ??
            defaultThemeUuidOf(s.prefs.writeDefaults) ??
            BuiltinThemes.wonkyDefault.uuid;
        open(uuid, doc: docItem(ctx), element: a.string('element'));
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.openManager',
      label: (l) => l.cmdThemeOpenManager,
      icon: LucideIcons.swatchBook,
      run: (ctx, e, a) {
        final doc = docItem(ctx);
        s.router.go(themeEditorPath(null, docItemUuid: doc));
        return const CommandResult.ok();
      },
    ),
    WriteCommand(
      'write.theme.useDefault',
      label: (l) => l.cmdThemeUseDefault,
      categoryName: (l) => l.categoryFormat,
      requiredRole: Role.editor,
      isUndoable: true,
      enabled: (d, a) => d.canChangeSettings,
      checked: (d, a) => d.themeUuid == null,
      run: (ctx, d, a) async {
        if (d.themeUuid == null) return const CommandResult.ok();
        await d.setMeta('themeId', null, label: l10n().undoUseDefaultTheme);
        return const CommandResult.ok();
      },
    ),

    // --------------------------------------------------------- library
    ThemeCommand(
      'write.theme.create',
      label: (l) => l.cmdThemeCreate,
      icon: LucideIcons.plus,
      isUndoable: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'name': JsonSchema.string(),
          'fromThemeUuid': JsonSchema.string(),
        },
      ),
      run: (ctx, e, a) async {
        final lib = library();
        if (lib == null) {
          return CommandResult.failed(l10n().commandToastOffline);
        }
        final from = a.string('fromThemeUuid');
        final source = from == null ? null : await themes.load(from);
        final r = await lib.create(
          a.string('name') ??
              (source == null
                  ? l10n().commandDialogNewThemeName
                  : l10n().commandDialogThemeCopyName(source.name)),
          (source?.data ?? BuiltinThemes.wonkyDefault.theme).toJson(),
          basedOnUuid: source?.uuid ?? BuiltinThemes.wonkyDefault.uuid,
        );
        if (ui(ctx) != null) open(r.uuid, doc: docItem(ctx));
        return CommandResult.ok({'themeUuid': r.uuid});
      },
    ),
    ThemeCommand(
      'write.theme.duplicate',
      label: (l) => l.cmdThemeDuplicate,
      descriptionText: (l) => l.cmdThemeDuplicateDescription,
      icon: LucideIcons.copy,
      isUndoable: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'themeUuid': JsonSchema.string(),
          'name': JsonSchema.string(),
        },
      ),
      enabled: (e, a) => targetUuid(e, a) != null,
      run: (ctx, e, a) async {
        final uuid = targetUuid(e, a)!;
        final ThemeRecord? r;
        if (e != null && e.themeUuid == uuid) {
          r = await e.duplicate(name: a.string('name'));
        } else {
          r = await library()?.duplicate(uuid, name: a.string('name'));
        }
        if (r == null) return CommandResult.failed(l10n().commandToastOffline);
        if (ui(ctx) != null) {
          open(r.uuid, doc: docItem(ctx));
          final doc = e?.document;
          if (doc != null && doc.canEdit && doc.themeUuid == uuid) {
            s.toasts.show(
              l10n().commandToastThemeCopied(r.name),
              actionLabel: l10n().cmdThemeApplyToDocument,
              onAction: () => unawaited(
                s.dispatcher.invoke(
                  'write.theme.applyToDocument',
                  source: InvocationSource.ui,
                ),
              ),
            );
          }
        }
        return CommandResult.ok({'themeUuid': r.uuid});
      },
    ),
    ThemeCommand(
      'write.theme.rename',
      label: (l) => l.cmdThemeRename,
      icon: LucideIcons.pencil,
      isUndoable: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'themeUuid': JsonSchema.string(),
          'name': JsonSchema.string(),
        },
      ),
      enabled: (e, a) =>
          a.string('themeUuid') != null || (e != null && !e.readOnly),
      run: (ctx, e, a) async {
        final uuid = targetUuid(e, a);
        if (uuid == null) {
          return CommandResult.failed(l10n().commandToastNoTheme);
        }
        var name = a.string('name');
        final current = themes.lookup(uuid)?.name ?? e?.name ?? '';
        if (name == null) {
          final c = ui(ctx);
          if (c == null) return const CommandResult.failed('name is required');
          name = await showRenameThemeDialog(c, current);
          if (name == null) return const CommandResult.cancelled();
        }
        if (e != null && e.themeUuid == uuid) {
          return editResult(await e.rename(name));
        }
        final repo = themeRepositoryFor(s);
        final lib = library();
        if (repo == null || lib == null) {
          return CommandResult.failed(l10n().commandToastOffline);
        }
        try {
          await lib.rename(await repo.get(uuid), name);
        } on ThemeConflict {
          return CommandResult.failed(l10n().commandToastThemeChangedElsewhere);
        }
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.delete',
      label: (l) => l.cmdThemeDelete,
      icon: LucideIcons.trash2,
      isUndoable: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'themeUuid': JsonSchema.string(),
          'confirmed': JsonSchema.boolean(),
        },
      ),
      enabled: (e, a) =>
          a.string('themeUuid') != null || (e != null && !e.readOnly),
      run: (ctx, e, a) async {
        final uuid = targetUuid(e, a);
        final repo = themeRepositoryFor(s);
        if (uuid == null || repo == null) {
          return CommandResult.failed(l10n().commandToastNoTheme);
        }
        if (themes.lookup(uuid)?.isBuiltin ?? false) {
          return CommandResult.failed(
            l10n().commandToastBuiltinThemeCannotBeDeleted,
          );
        }
        final c = ui(ctx);
        if (a.boolean('confirmed') != true && c != null) {
          var used = 0;
          try {
            used = await repo.usage(uuid);
          } catch (_) {}
          if (used > 0 && c.mounted) {
            final ok = await confirmDialog(
              c,
              title: writeL10n(c).commandDialogDeleteThemeTitle,
              description: writeL10n(c).commandDialogDeleteThemeBody(used),
              confirmLabel: writeL10n(c).commonDelete,
              destructive: true,
            );
            if (!ok) return const CommandResult.cancelled();
          }
        }
        if (e != null && e.themeUuid == uuid) {
          final r = await e.delete();
          if (!r.isOk) return editResult(r);
        } else {
          await library()!.delete(uuid);
        }
        s.toasts.show(
          l10n().commandToastThemeDeleted,
          actionLabel: l10n().commonUndo,
          onAction: () => unawaited(
            s.dispatcher.invoke('shell.edit.undo', source: InvocationSource.ui),
          ),
        );
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.restore',
      label: (l) => l.cmdThemeRestore,
      icon: LucideIcons.archiveRestore,
      isUndoable: true,
      argsSchema: themeArg,
      enabled: (e, a) =>
          a.string('themeUuid') != null || (e != null && e.isDeleted),
      run: (ctx, e, a) async {
        final uuid = targetUuid(e, a);
        if (uuid == null) {
          return CommandResult.failed(l10n().commandToastNoTheme);
        }
        if (e != null && e.themeUuid == uuid) {
          return editResult(await e.restore());
        }
        final lib = library();
        if (lib == null) {
          return CommandResult.failed(l10n().commandToastOffline);
        }
        await lib.restore(uuid);
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.setAsDefault',
      label: (l) => l.cmdThemeSetAsDefault,
      icon: LucideIcons.star,
      argsSchema: themeArg,
      checked: (e, a) {
        final uuid = targetUuid(e, a);
        return uuid == null
            ? null
            : (defaultThemeUuidOf(s.prefs.writeDefaults) ??
                      BuiltinThemes.wonkyDefault.uuid) ==
                  uuid;
      },
      enabled: (e, a) => targetUuid(e, a) != null,
      run: (ctx, e, a) async {
        final uuid = targetUuid(e, a)!;
        await s.prefs.setWriteDefault(defaultThemeKey, uuid);
        final name = themes.lookup(uuid)?.name ?? e?.name;
        if (ui(ctx) != null) {
          s.toasts.show(
            name == null
                ? l10n().commandToastDefaultThemeUnnamed
                : l10n().commandToastDefaultTheme(name),
          );
        }
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.applyToDocument',
      label: (l) => l.cmdThemeApplyToDocument,
      icon: LucideIcons.check,
      isUndoable: true,
      needsEditor: true,
      enabled: (e, a) =>
          e?.document?.canEdit == true && !(e?.isDeleted ?? true),
      run: (ctx, e, a) async {
        final r = await e!.applyToDocument();
        if (r.isOk && ui(ctx) != null) {
          final title = e.document?.title;
          s.toasts.show(
            title == null
                ? l10n().commandToastThemeApplied
                : l10n().commandToastThemeAppliedTo(title),
          );
        }
        return editResult(r);
      },
    ),

    // ---------------------------------------------------------- editor
    ThemeCommand(
      'write.theme.selectElement',
      label: (l) => l.cmdThemeSelectElement,
      showInPalette: false,
      needsEditor: true,
      argsSchema: const JsonSchema.object(
        properties: {'element': JsonSchema.string()},
        required: ['element'],
      ),
      run: (ctx, e, a) {
        final node = ThemeNode.parse(a.requireString('element'));
        if (node == null) return const CommandResult.failed('Unknown element');
        e!.select(node);
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.setProperty',
      label: (l) => l.cmdThemeSetProperty,
      showInPalette: false,
      isUndoable: true,
      needsEditor: true,
      needsEditable: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'path': JsonSchema.string(
            description: 'e.g. elements.h2.fontSize, palette.accent',
          ),
          'value': JsonSchema.any(description: 'JSON value; null = inherit'),
          'variant': JsonSchema.string(enumValues: ['light', 'dark']),
          'gesture': JsonSchema.string(
            description: 'Coalesces the steps of one drag into one undo step',
          ),
        },
        required: ['path'],
      ),
      run: (ctx, e, a) => editResult(
        e!.setProperty(
          a.requireString('path'),
          a.values['value'],
          variant: _variant(a),
          coalesceKey: a.string('gesture'),
        ),
      ),
    ),
    ThemeCommand(
      'write.theme.resetElement',
      label: (l) => l.cmdThemeResetElement,
      showInPalette: false,
      isUndoable: true,
      needsEditor: true,
      needsEditable: true,
      argsSchema: const JsonSchema.object(
        properties: {'element': JsonSchema.string()},
      ),
      run: (ctx, e, a) {
        final id = a.string('element');
        final node = id == null ? e!.selected : ThemeNode.parse(id);
        if (node == null) return const CommandResult.failed('Unknown element');
        return editResult(e!.resetElement(node));
      },
    ),
    ThemeCommand(
      'write.theme.fixContrast',
      label: (l) => l.cmdThemeFixContrast,
      showInPalette: false,
      isUndoable: true,
      needsEditor: true,
      needsEditable: true,
      argsSchema: const JsonSchema.object(
        properties: {
          'pairId': JsonSchema.string(),
          'variant': JsonSchema.string(enumValues: ['light', 'dark']),
        },
        required: ['pairId'],
      ),
      run: (ctx, e, a) => editResult(
        e!.fixContrast(
          a.requireString('pairId'),
          _variant(a) ?? ThemeVariant.light,
        ),
      ),
    ),
    ThemeCommand(
      'write.theme.revert',
      label: (l) => l.cmdThemeRevert,
      icon: LucideIcons.undo,
      needsEditor: true,
      enabled: (e, a) => e?.dirty ?? false,
      argsSchema: const JsonSchema.object(
        properties: {'confirmed': JsonSchema.boolean()},
      ),
      run: (ctx, e, a) async {
        final c = ui(ctx);
        if (c != null && a.boolean('confirmed') != true) {
          final ok = await confirmDialog(
            c,
            title: writeL10n(c).commandDialogRevertThemeTitle,
            description: writeL10n(c).commandDialogRevertThemeBody,
            confirmLabel: writeL10n(c).commandDialogRevertThemeConfirm,
            destructive: true,
          );
          if (!ok) return const CommandResult.cancelled();
        }
        await e!.revert();
        return const CommandResult.ok();
      },
    ),
    ThemeCommand(
      'write.theme.save',
      label: (l) => l.cmdThemeSave,
      icon: LucideIcons.save,
      isUndoable: true,
      needsEditor: true,
      needsEditable: true,
      enabled: (e, a) => (e?.dirty ?? false) && !(e?.saving ?? false),
      run: (ctx, e, a) async {
        final r = await e!.save();
        final conflict = e.conflict;
        final c = ui(ctx);
        if (conflict != null && c != null && c.mounted) {
          final choice = await showThemeConflictDialog(c, conflict);
          switch (choice) {
            case ThemeConflictChoice.reload:
              await e.reloadTheirs();
              return const CommandResult.ok();
            case ThemeConflictChoice.overwrite:
              return editResult(await e.overwrite());
            case ThemeConflictChoice.copy:
              final copy = await e.saveAsCopy();
              if (copy != null) open(copy.uuid, doc: e.documentItemUuid);
              return const CommandResult.ok();
            case null:
              return const CommandResult.cancelled();
          }
        }
        return editResult(r);
      },
    ),
    ThemeCommand(
      'write.theme.showRevisions',
      label: (l) => l.cmdThemeShowRevisions,
      icon: LucideIcons.history,
      needsEditor: true,
      enabled: (e, a) => e?.isMine ?? false,
      run: (ctx, e, a) async {
        final c = ui(ctx);
        final list = await e!.revisions();
        if (c == null || !c.mounted) {
          return CommandResult.ok({
            'revisions': [
              for (final r in list)
                {
                  'version': r.version,
                  'savedAt': r.createdAt.toIso8601String(),
                },
            ],
          });
        }
        final picked = await showThemeRevisionsDialog(
          c,
          list,
          current: e.version,
        );
        if (picked == null) return const CommandResult.cancelled();
        return editResult(e.loadRevision(picked));
      },
    ),
    for (final (id, value) in const [
      ('write.theme.setPreviewSource', 'source'),
      ('write.theme.setPreviewVariant', 'variant'),
      ('write.theme.setPreviewLayout', 'layout'),
    ])
      ThemeCommand(
        id,
        label: (l) => switch (value) {
          'source' => l.cmdThemeSetPreviewSource,
          'variant' => l.cmdThemeSetPreviewVariant,
          _ => l.cmdThemeSetPreviewLayout,
        },
        showInPalette: false,
        needsEditor: true,
        argsSchema: JsonSchema.object(
          properties: {
            value: JsonSchema.string(
              enumValues: switch (value) {
                'source' => const ['sample', 'document'],
                'variant' => const ['light', 'dark'],
                _ => const ['pages', 'pageless'],
              },
            ),
          },
          required: [value],
        ),
        checked: (e, a) {
          final v = a.string(value);
          if (e == null || v == null) return null;
          return switch (value) {
            'source' => e.source.name == v,
            'variant' => e.variant.name == v,
            _ => e.layout.name == v,
          };
        },
        run: (ctx, e, a) {
          final v = a.requireString(value);
          switch (value) {
            case 'source':
              e!.setSource(
                v == 'document'
                    ? ThemePreviewSource.document
                    : ThemePreviewSource.sample,
              );
            case 'variant':
              e!.setVariant(
                v == 'dark' ? ThemeVariant.dark : ThemeVariant.light,
              );
            default:
              e!.setLayout(
                v == 'pages'
                    ? ThemePreviewLayout.pages
                    : ThemePreviewLayout.pageless,
              );
          }
          return const CommandResult.ok();
        },
      ),

    // ---------------------------------------------------- import/export
    ThemeCommand(
      'write.theme.importJson',
      label: (l) => l.cmdThemeImportJson,
      icon: LucideIcons.upload,
      isUndoable: true,
      argsSchema: const JsonSchema.object(
        properties: {'json': JsonSchema.string()},
      ),
      run: (ctx, e, a) async {
        final lib = library();
        if (lib == null) {
          return CommandResult.failed(l10n().commandToastOffline);
        }
        var source = a.string('json');
        final c = ui(ctx);
        if (source == null) {
          if (c == null) return const CommandResult.failed('json is required');
          final f = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: const ['json'],
            dialogTitle: writeL10n(c).commandDialogImportThemeTitle,
          );
          if (f == null) return const CommandResult.cancelled();
          final bytes = await f.readAsBytes();
          source = utf8.decode(bytes, allowMalformed: true);
        }
        final result = const WriteThemeValidator().validateString(source);
        if (result.theme == null) {
          if (c != null && c.mounted) {
            await showThemeImportReport(c, errors: result.errors);
          }
          return CommandResult.failed(
            result.errors.map((i) => '${i.path}: ${i.message}').join('; '),
          );
        }
        if (result.warnings.isNotEmpty && c != null && c.mounted) {
          final ok = await showThemeImportReport(c, warnings: result.warnings);
          if (!ok) return const CommandResult.cancelled();
        }
        final theme = result.theme!;
        final r = await lib.create(theme.name, theme.toJson());
        if (c != null) open(r.uuid, doc: docItem(ctx));
        return CommandResult.ok({
          'themeUuid': r.uuid,
          'warnings': [for (final w in result.warnings) w.toJson()],
        });
      },
    ),
    for (final css in const [false, true])
      ThemeCommand(
        css ? 'write.theme.exportCss' : 'write.theme.exportJson',
        label: (l) => css ? l.cmdThemeExportCss : l.cmdThemeExportJson,
        icon: LucideIcons.download,
        argsSchema: themeArg,
        enabled: (e, a) => targetUuid(e, a) != null,
        run: (ctx, e, a) async {
          final uuid = targetUuid(e, a)!;
          final WriteThemeData data;
          final String name;
          if (e != null && e.themeUuid == uuid) {
            data = e.draft;
            name = e.name;
          } else {
            final o = await themes.load(uuid);
            if (o == null) return const CommandResult.failed('Unknown theme');
            data = o.data;
            name = o.name;
          }
          final String text;
          if (css) {
            text = const ThemeCssWriter().write(
              ThemeResolver.instance.resolve(data, ThemeVariant.light),
              dark: ThemeResolver.instance.resolve(data, ThemeVariant.dark),
              target: CssTarget.standalone,
            );
          } else {
            text = const JsonEncoder.withIndent('  ').convert({
              r'$schema': themeSchemaUrl,
              'exportedAt': DateTime.now().toUtc().toIso8601String(),
              ...data.toJson(),
            });
          }
          final safe = name.replaceAll(RegExp(r'[/\\:*?"<>|]'), ' ').trim();
          final fileName = css ? '$safe.css' : '$safe.wonkytheme.json';
          if (ui(ctx) == null) return CommandResult.ok({'text': text});
          final saved = await FilePicker.saveFile(
            fileName: fileName,
            bytes: Uint8List.fromList(utf8.encode(text)),
            mimeType: css ? 'text/css' : 'application/json',
            dialogTitle: l10n().commandDialogSaveFileTitle(fileName),
          );
          return kIsWeb || saved != null
              ? const CommandResult.ok()
              : const CommandResult.cancelled();
        },
      ),
  ];
}
