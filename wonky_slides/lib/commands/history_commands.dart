import 'dart:async';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart' show UuidValue;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides_core/model.dart' show SlidesText;
import 'package:wonky_slides_core/ops.dart' show SetText;

import '../features/history/conflict_review_dialog.dart';
import '../features/history/local_conflicts.dart';
import '../features/history/slides_version_view.dart';
import '../l10n/slides_l10n.dart';
import 'slides_command.dart' show SlidesCategory, SlidesCommand, ok;

/// Version history and overwritten-text commands (Slides 09 §4, §6.3, §7).
/// The suite's `shell.versions.*` commands do the server work (they record
/// a restore as one `slides.serverChange` undo step through
/// `SlidesVersionRenderer.restoreUndoEntry`); the `slides.history.*`
/// commands are the Slides ids of the menus and the history route's
/// actions, which also run without an open deck editor.
List<Command<CommandArgs>> historyCommands(ShellServices s) {
  bool canHistory() =>
      (s.currentItem.value?.myRole.canViewHistory ?? false) &&
      s.connectivity.online;
  bool canEdit() => s.currentItem.value?.canEdit ?? false;
  SlidesVersionViewState? view() => SlidesVersionView.current.value;
  String? category(BuildContext c) => SlidesCategory.file.label(slidesL10n(c));

  Future<CommandResult> delegate(
    CommandContext ctx,
    String id, [
    Map<String, Object?> args = const {},
  ]) => s.dispatcher.invoke(
    id,
    args: args,
    source: ctx.source,
    context: ctx.dialogContext,
  );

  CallbackCommand command(
    String id, {
    required String Function(SlidesLocalizations l) title,
    required Future<CommandResult> Function(CommandContext, JsonArgs) run,
    IconData? icon,
    bool Function()? enabled,
    bool? Function()? checked,
    JsonSchema args = JsonSchema.empty,
    List<KeyBinding> bindings = const [],
    bool palette = true,
  }) => CallbackCommand(
    id: id,
    title: (c) => title(slidesL10n(c)),
    run: run,
    icon: icon,
    argsSchema: args,
    defaultBindings: bindings,
    showInPalette: palette,
    enabled: enabled == null ? null : (_, _) => enabled(),
    checked: checked == null ? null : (_, _) => checked(),
    category: category,
  );

  return [
    command(
      'slides.history.open',
      title: (l) => l.cmdHistoryOpen,
      icon: LucideIcons.history,
      bindings: const [KeyBinding('H', mod: true, alt: true, shift: true)],
      args: const JsonSchema.object(
        properties: {
          'versionId': JsonSchema.integer(
            description: 'The version to show (default: the newest).',
          ),
        },
      ),
      enabled: canHistory,
      run: (ctx, a) async {
        final id = a.integer('versionId');
        final item = s.currentItem.value;
        if (id == null || item == null) {
          return delegate(ctx, 'shell.versions.open');
        }
        s.router.go('${s.config.itemPath(item.uuid.uuid)}/history?version=$id');
        return ok({'versionId': id});
      },
    ),
    command(
      'slides.history.nameCurrentVersion',
      title: (l) => l.cmdHistoryNameCurrentVersion,
      icon: LucideIcons.bookmarkPlus,
      args: const JsonSchema.object(
        properties: {'name': JsonSchema.string(minLength: 1, maxLength: 200)},
      ),
      enabled: () => canHistory() && canEdit(),
      run: (ctx, a) => delegate(ctx, 'shell.versions.nameCurrent', {
        if (a.string('name') != null) 'name': a.string('name'),
      }),
    ),
    command(
      'slides.history.restoreVersion',
      title: (l) => l.cmdHistoryRestoreVersion,
      icon: LucideIcons.archiveRestore,
      palette: false,
      args: const JsonSchema.object(
        properties: {
          'versionId': JsonSchema.integer(),
          'confirmed': JsonSchema.boolean(),
        },
        required: ['versionId'],
      ),
      enabled: () => canHistory() && canEdit(),
      // The shell command records the `slides.serverChange` undo step.
      run: (ctx, a) => delegate(ctx, 'shell.versions.restore', {
        'versionId': a.integer('versionId'),
        if (a.boolean('confirmed') != null) 'confirmed': a.boolean('confirmed'),
      }),
    ),
    command(
      'slides.history.makeCopy',
      title: (l) => l.cmdHistoryMakeCopy,
      icon: LucideIcons.copy,
      args: const JsonSchema.object(
        properties: {
          'name': JsonSchema.string(
            minLength: 1,
            maxLength: 255,
            description: 'Name of the copy. Omit to open the dialog.',
          ),
          'folderUuid': JsonSchema.string(
            description: 'Folder of the copy (default: the deck’s folder).',
          ),
          'copyComments': JsonSchema.boolean(),
          'copySharing': JsonSchema.boolean(),
        },
      ),
      enabled: () => view()?.model != null && s.connectivity.online,
      run: (ctx, a) async {
        final v = view();
        if (v == null) {
          return CommandResult.failed(slidesL10nOf(s).reasonNoVersionShown);
        }
        final c = ctx.dialogContext;
        final name = a.string('name');
        final UuidValue? id;
        if (name == null && c != null && c.mounted) {
          id = await v.makeCopyWithDialog(c);
          if (id == null) return const CommandResult.cancelled();
        } else {
          final folder = a.string('folderUuid');
          id = await v.makeCopy(
            name: name,
            folderUuid: folder == null ? null : UuidValue.fromString(folder),
            copyComments: a.boolean('copyComments') ?? false,
            copySharing: a.boolean('copySharing') ?? false,
          );
        }
        return id == null
            ? CommandResult.failed(slidesL10nOf(s).errorCopyFailed)
            : ok({'itemUuid': id.uuid});
      },
    ),
    command(
      'slides.history.download',
      title: (l) => l.cmdHistoryDownload,
      icon: LucideIcons.download,
      args: const JsonSchema.object(
        properties: {
          'format': JsonSchema.string(enumValues: ['pdf']),
        },
      ),
      enabled: () => view()?.model != null,
      run: (ctx, a) async {
        final v = view();
        if (v == null) {
          return CommandResult.failed(slidesL10nOf(s).reasonNoVersionShown);
        }
        try {
          final file = await v.download();
          return file == null
              ? const CommandResult.cancelled()
              : ok({'fileName': file});
        } catch (e) {
          return CommandResult.failed('$e');
        }
      },
    ),
    command(
      'slides.history.toggleShowChanges',
      title: (l) => l.cmdHistoryToggleShowChanges,
      icon: LucideIcons.highlighter,
      checked: () => VersionHistoryScreen.showChanges.value,
      run: (ctx, a) async {
        final n = VersionHistoryScreen.showChanges;
        n.value = !n.value;
        return ok({'showChanges': n.value});
      },
    ),
    command(
      'slides.history.toggleShowRemoved',
      title: (l) => l.cmdHistoryToggleShowRemoved,
      icon: LucideIcons.squareDashed,
      checked: () => SlidesVersionView.showRemoved.value,
      run: (ctx, a) async {
        final n = SlidesVersionView.showRemoved;
        n.value = !n.value;
        return ok({'showRemoved': n.value});
      },
    ),
    for (final forward in const [true, false])
      command(
        forward ? 'slides.history.nextChange' : 'slides.history.previousChange',
        title: (l) =>
            forward ? l.cmdHistoryNextChange : l.cmdHistoryPreviousChange,
        icon: forward ? LucideIcons.chevronDown : LucideIcons.chevronUp,
        bindings: [
          KeyBinding(forward ? 'ArrowDown' : 'ArrowUp', mod: true, alt: true),
        ],
        enabled: () => view()?.diff?.stops.isNotEmpty ?? false,
        run: (ctx, a) async {
          final stop = view()?.step(forward: forward);
          if (stop == null) {
            return CommandResult.failed(slidesL10nOf(s).reasonNoChanges);
          }
          return ok({'slideId': stop.slideId, 'elementId': ?stop.elementId});
        },
      ),
    // Overwritten text (09 §6.3).
    SlidesCommand(
      'slides.conflicts.review',
      label: (l) => l.cmdConflictsReview,
      icon: LucideIcons.gitCompareArrows,
      categoryOf: SlidesCategory.file,
      enabled: (ed, _) =>
          ed.roleCanEdit && (SlidesConflicts.of(ed)?.open.isNotEmpty ?? false),
      reason: (l, _) => l.reasonNoConflicts,
      run: (ctx, ed, a) async {
        final conflicts = SlidesConflicts.of(ed)!;
        final open = conflicts.open;
        final c = ctx.dialogContext;
        if (open.isEmpty || c == null || !c.mounted) {
          return ok({'conflicts': open.length});
        }
        final choice = await showConflictReviewDialog(
          c,
          editor: ed,
          conflicts: open,
        );
        if (choice == null) return const CommandResult.cancelled();
        switch (choice.action) {
          case 'dismiss':
            await conflicts.dismiss();
            return ok({'dismissed': open.length});
          case 'copy':
            final texts = [
              for (final x in conflicts.byIds(choice.ids))
                SlidesText.plainText(x.myText).trimRight(),
            ];
            await Clipboard.setData(ClipboardData(text: texts.join('\n\n')));
            s.toasts.show(slidesL10nOf(s).toastConflictsCopied);
            return ok({'copied': texts.length});
        }
        if (choice.ids.isEmpty) return const CommandResult.cancelled();
        final r = await ed.invokeCommand('slides.conflicts.restoreMine', {
          'conflictIds': choice.ids,
        });
        return r;
      },
    ),
    SlidesCommand(
      'slides.conflicts.restoreMine',
      label: (l) => l.cmdConflictsRestoreMine,
      icon: LucideIcons.undo2,
      categoryOf: SlidesCategory.file,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'conflictIds': JsonSchema.array(JsonSchema.string(minLength: 1)),
        },
        required: ['conflictIds'],
      ),
      enabled: (ed, _) => SlidesConflicts.of(ed) != null,
      run: (ctx, ed, a) async {
        final conflicts = SlidesConflicts.of(ed)!;
        final ids = [
          for (final x in (a.values['conflictIds'] as List?) ?? const []) '$x',
        ];
        final done = <String>[];
        for (final c in conflicts.byIds(ids)) {
          if (!c.canRestore || c.target.currentIn(ed.model) == null) continue;
          ed.apply(
            ctx,
            SetText(
              c.target.target,
              c.myText ??
                  (c.target.kind == 'notes' ? '[{"insert":"\\n"}]' : null),
            ),
          );
          done.add(c.id);
        }
        if (done.isEmpty) {
          return CommandResult.failed(
            slidesL10nOf(ed.services).errorNothingToRestore,
          );
        }
        await conflicts.dismiss(done);
        return ok({'restored': done.length});
      },
    ),
  ];
}
