import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyDialogCloseButton;
import 'package:wonky_write_core/wonky_write_core.dart' show ThemeIssue;

import '../../l10n/write_l10n.dart';
import '../themes/theme_repository.dart';

/// Rename dialog (`write.theme.rename` without a name).
Future<String?> showRenameThemeDialog(BuildContext context, String current) {
  final l = writeL10n(context);
  return showTextInputDialog(
    context,
    title: l.themeDialogRenameTitle,
    label: l.themeInspectorName,
    confirmLabel: l.commonRename,
    initial: current,
    maxLength: 80,
    dialogKey: 'write.dialog.renameTheme',
    validator: (v) {
      final t = v.trim();
      if (t.isEmpty) return l.themeDialogEnterName;
      if (t.length > 80) return l.themeDialogMaxLength(80);
      return null;
    },
  );
}

/// How to resolve a [ThemeConflict] (Write 06 §10.4).
enum ThemeConflictChoice { reload, overwrite, copy }

/// The theme was saved from another window or by someone else.
Future<ThemeConflictChoice?> showThemeConflictDialog(
  BuildContext context,
  ThemeConflict conflict,
) async {
  final l = writeL10n(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.themeDialogConflictTitle,
      description: l.themeDialogConflictDescription(
        conflict.serverName,
        conflict.serverVersion,
      ),
      dialogKey: 'write.dialog.themeConflict',
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.commonCancel),
        DialogButtonSpec(id: 'copy', label: l.themeDialogSaveAsCopy),
        DialogButtonSpec(id: 'reload', label: l.themeDialogReloadTheirs),
        DialogButtonSpec(
          id: 'overwrite',
          label: l.themeDialogOverwrite,
          primary: true,
          destructive: true,
        ),
      ],
    ),
  );
  return switch (r?.buttonId) {
    'reload' => ThemeConflictChoice.reload,
    'overwrite' => ThemeConflictChoice.overwrite,
    'copy' => ThemeConflictChoice.copy,
    _ => null,
  };
}

/// What to do with unsaved theme changes when leaving the editor.
enum UnsavedThemeChoice { save, discard }

Future<UnsavedThemeChoice?> showUnsavedThemeDialog(
  BuildContext context,
  String name,
) async {
  final l = writeL10n(context);
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: l.themeDialogUnsavedTitle(name),
      description: l.themeDialogUnsavedDescription,
      dialogKey: 'write.dialog.unsavedTheme',
      buttons: [
        DialogButtonSpec(id: 'cancel', label: l.commonCancel),
        DialogButtonSpec(
          id: 'discard',
          label: l.themeDialogDiscard,
          destructive: true,
        ),
        DialogButtonSpec(id: 'save', label: l.commonSave, primary: true),
      ],
    ),
  );
  return switch (r?.buttonId) {
    'save' => UnsavedThemeChoice.save,
    'discard' => UnsavedThemeChoice.discard,
    _ => null,
  };
}

/// Import report (Write 06 §10.5): errors block the import; warnings ask
/// to *Import anyway*. Returns true to import.
Future<bool> showThemeImportReport(
  BuildContext context, {
  List<ThemeIssue> errors = const [],
  List<ThemeIssue> warnings = const [],
}) async {
  final l = writeL10n(context);
  String lines(List<ThemeIssue> issues) => [
    for (final i in issues.take(12))
      '• ${i.path.isEmpty ? '' : '${i.path}: '}${i.message}',
    if (issues.length > 12) l.themeDialogImportMore(issues.length - 12),
  ].join('\n');
  final blocking = errors.isNotEmpty;
  final r = await showWonkyFormDialog(
    context,
    WonkyDialogSpec(
      title: blocking
          ? l.themeDialogImportBlockedTitle
          : l.themeDialogImportWarningsTitle,
      description: blocking
          ? lines(errors)
          : l.themeDialogImportAdjusted(lines(warnings)),
      dialogKey: 'write.dialog.themeImport',
      buttons: [
        if (blocking)
          DialogButtonSpec(id: 'cancel', label: l.commonOk, primary: true)
        else ...[
          DialogButtonSpec(id: 'cancel', label: l.commonCancel),
          DialogButtonSpec(
            id: 'import',
            label: l.themeDialogImportAnyway,
            primary: true,
          ),
        ],
      ],
    ),
  );
  return r?.buttonId == 'import';
}

/// The revision history of a theme; returns the revision to load into the
/// draft.
Future<ThemeRevision?> showThemeRevisionsDialog(
  BuildContext context,
  List<ThemeRevision> revisions, {
  required int current,
}) => showShadDialog<ThemeRevision>(
  context: context,
  builder: (context) {
    final theme = ShadTheme.of(context);
    final l = writeL10n(context);
    final format = DateFormat.yMMMd(l.localeName).add_jm();
    String when(DateTime d) => format.format(d.toLocal());

    return ShadDialog(
      key: const ValueKey<String>('write.dialog.themeRevisions'),
      closeIcon: const WonkyDialogCloseButton(),
      title: Text(l.themeDialogRevisionsTitle),
      description: Text(l.themeDialogRevisionsDescription),
      constraints: const BoxConstraints(maxWidth: 480),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonClose),
        ),
      ],
      child: revisions.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l.themeDialogNoRevisions,
                style: theme.textTheme.muted,
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in revisions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.version == current
                                        ? l.themeDialogRevisionCurrent(
                                            r.version,
                                          )
                                        : l.themeDialogRevision(r.version),
                                    style: theme.textTheme.small.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    [
                                      when(r.createdAt),
                                      ?r.savedBy,
                                      if (r.byAgent) l.themeDialogViaAssistant,
                                    ].join(' · '),
                                    style: theme.textTheme.muted.copyWith(
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (r.version != current)
                              ShadButton.outline(
                                key: ValueKey<String>(
                                  'write.dialog.themeRevisions.load.${r.version}',
                                ),
                                size: ShadButtonSize.sm,
                                onPressed: () => Navigator.of(context).pop(r),
                                child: Text(l.themeDialogLoad),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  },
);
