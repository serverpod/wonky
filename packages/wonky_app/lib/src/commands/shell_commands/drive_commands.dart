import 'package:flutter/services.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../../data/models_ext.dart';
import '../../drive/dialogs/drive_dialogs.dart';
import '../../shell/shell_services.dart';
import '../../undo/drive_undo.dart';
import '../command.dart';
import 'shell_command_base.dart';
import '../../storage/quota_dialog.dart' show QuotaReasons;

/// `shell.drive.*` (suite 05 §3.3, 08 §5). Move, rename, star, trash,
/// restore and folder creation are undoable on the shell stack; permanent
/// delete and empty trash confirm instead.
List<Command<CommandArgs>> driveCommands(ShellServices s) {
  final drive = s.drive;
  void changed(List<DriveItemView> items) {
    for (final i in items) {
      s.emitDriveChange(
        DriveChange(kind: DriveChangeKind.updated, itemUuid: i.uuid, item: i),
      );
    }
    final cur = s.currentItem.value;
    if (cur != null) {
      for (final i in items) {
        if (i.uuid == cur.uuid) s.currentItem.value = i;
      }
    }
  }

  return [
    shellCommand(
      'shell.drive.newFolder',
      title: (l) => l.cmdNewFolder,
      icon: LucideIcons.folderPlus,
      bindings: const [KeyBinding('F', shift: true)],
      scope: KeyScope.drive,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {
          'name': JsonSchema.string(minLength: 1, maxLength: 255),
          'parentUuid': JsonSchema.nullable(JsonSchema.string(format: 'uuid')),
        },
      ),
      enabled: (ctx, a) => s.connectivity.online,
      run: (ctx, a) async {
        var name = a.string('name');
        if (name == null) {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          name = await showNewFolderDialog(c, s);
          if (name == null) return const CommandResult.cancelled();
        }
        // An explicit `parentUuid: null` is My Drive's root (the Move
        // dialog); a missing one is the open folder.
        final parentArg = a.string('parentUuid');
        final parent = parentArg != null
            ? UuidValue.fromString(parentArg)
            : a.values.containsKey('parentUuid')
            ? null
            : s.currentFolder.value?.uuid;
        final v = await drive.createFolder(parentUuid: parent, name: name);
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.createFolder,
            items: [v.uuid.uuid],
            before: {v.uuid.uuid: false},
            after: {v.uuid.uuid: true},
          ),
        );
        s.emitDriveChange(
          DriveChange(kind: DriveChangeKind.created, itemUuid: v.uuid, item: v),
        );
        return CommandResult.ok({'uuid': v.uuid.uuid});
      },
    ),
    shellCommand(
      'shell.drive.rename',
      title: (l) => l.cmdRename,
      icon: LucideIcons.pencil,
      bindings: const [KeyBinding('F2'), KeyBinding('N')],
      scope: KeyScope.drive,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {
          ...targetProps,
          'name': JsonSchema.string(minLength: 1, maxLength: 255),
        },
      ),
      enabled: (ctx, a) =>
          hasExplicitTargets(a) ||
          (singleTarget(s, a)?.let(canManageItem) ?? false),
      run: (ctx, a) async {
        final targets = await fetchTargets(s, a);
        if (targets.length != 1) return const CommandResult.cancelled();
        final item = targets.single;
        var name = a.string('name');
        if (name == null) {
          // In the editor, File › Rename focuses the title field.
          if (s.currentItem.value?.uuid == item.uuid &&
              s.startTitleRename != null &&
              s.driveSelection.value.isEmpty) {
            s.startTitleRename!();
            return const CommandResult.cancelled();
          }
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          name = await showRenameDialog(c, s, item);
          if (name == null || name == item.name) {
            return const CommandResult.cancelled();
          }
        }
        final v = await drive.rename(item.uuid, name);
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.rename,
            items: [item.uuid.uuid],
            before: {item.uuid.uuid: item.name},
            after: {item.uuid.uuid: v.name},
          ),
        );
        changed([v]);
        return CommandResult.ok({'uuid': v.uuid.uuid, 'name': v.name});
      },
    ),
    shellCommand(
      // The details panel's description field (suite 05 §3.1; CQ-54).
      'shell.drive.setDescription',
      title: (l) => l.cmdSetDescription,
      icon: LucideIcons.notebookPen,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {
          ...targetProps,
          'description': JsonSchema.nullable(
            JsonSchema.string(maxLength: 4000),
          ),
        },
        required: ['description'],
      ),
      enabled: (ctx, a) =>
          hasExplicitTargets(a) ||
          (singleTarget(s, a)?.let((i) => i.canEdit && !i.isTrashed) ?? false),
      run: (ctx, a) async {
        final targets = await fetchTargets(s, a);
        if (targets.length != 1) return const CommandResult.cancelled();
        final item = targets.single;
        final text = a.string('description')?.trim();
        final description = text == null || text.isEmpty ? null : text;
        if (description == item.description) {
          return const CommandResult.cancelled();
        }
        final v = await drive.updateDescription(item.uuid, description);
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.description,
            items: [item.uuid.uuid],
            before: {item.uuid.uuid: item.description},
            after: {item.uuid.uuid: v.description},
          ),
        );
        changed([v]);
        return CommandResult.ok({'uuid': v.uuid.uuid});
      },
    ),
    shellCommand(
      'shell.drive.move',
      title: (l) => l.cmdMove,
      icon: LucideIcons.folderInput,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {
          ...targetProps,
          'folderUuid': JsonSchema.nullable(
            JsonSchema.string(
              format: 'uuid',
              description: 'Target folder; null = My Drive root.',
            ),
          ),
        },
      ),
      enabled: (ctx, a) => targetsAll(s, a, canManageItem),
      run: (ctx, a) async {
        final items = await fetchTargets(s, a);
        if (items.isEmpty) return const CommandResult.cancelled();
        UuidValue? target;
        if (a.values.containsKey('folderUuid')) {
          final f = a.string('folderUuid');
          target = f == null ? null : UuidValue.fromString(f);
        } else {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          final picked = await showMoveDialog(c, s, items);
          if (picked == null) return const CommandResult.cancelled();
          target = picked.folderUuid;
        }
        final moved = await drive.move([for (final i in items) i.uuid], target);
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.move,
            items: [for (final i in items) i.uuid.uuid],
            before: {for (final i in items) i.uuid.uuid: i.parentUuid?.uuid},
            after: {for (final i in items) i.uuid.uuid: target?.uuid},
          ),
        );
        changed(moved);
        for (final m in moved) {
          s.emitDriveChange(
            DriveChange(kind: DriveChangeKind.moved, itemUuid: m.uuid, item: m),
          );
        }
        return CommandResult.ok({'moved': moved.length});
      },
    ),
    shellCommand(
      'shell.drive.copy',
      title: (l) => l.cmdMakeCopy,
      icon: LucideIcons.copy,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {
          ...targetProps,
          'name': JsonSchema.string(minLength: 1, maxLength: 255),
          'folderUuid': JsonSchema.nullable(JsonSchema.string(format: 'uuid')),
          'copyComments': JsonSchema.boolean(),
          'copySharing': JsonSchema.boolean(),
        },
      ),
      enabled: (ctx, a) =>
          hasExplicitTargets(a) ||
          (singleTarget(
                s,
                a,
              )?.let((i) => !i.isFolder && i.canDownload && !i.isTrashed) ??
              false),
      run: (ctx, a) async {
        final targets = await fetchTargets(s, a);
        if (targets.length != 1) return const CommandResult.cancelled();
        final item = targets.single;
        CopyRequest? req;
        final name = a.string('name');
        if (name != null) {
          final f = a.string('folderUuid');
          req = CopyRequest(
            name: name,
            folderUuid: f == null ? item.parentUuid : UuidValue.fromString(f),
            copyComments: a.boolean('copyComments', false)!,
            copySharing: a.boolean('copySharing', false)!,
          );
        } else {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          req = await showCopyDialog(c, s, item);
        }
        if (req == null) return const CommandResult.cancelled();
        // Drive 03 §7.2: the copy is charged to the copier (pre-check with
        // the known usage; the server refuses with `quotaExceeded` anyway).
        if (!ctx.source.isAgent &&
            !await s.storageChecks.ensureRoom(
              item.countedBytes,
              reason: QuotaReasons.copy,
              askServer: false,
            )) {
          return const CommandResult.cancelled();
        }
        final v = await drive.copy(
          item.uuid,
          newName: req.name,
          parentUuid: req.folderUuid,
          copyComments: req.copyComments,
          copySharing: req.copySharing,
        );
        s.emitDriveChange(
          DriveChange(kind: DriveChangeKind.created, itemUuid: v.uuid, item: v),
        );
        final l = s.l10n;
        s.toasts.show(
          l?.toastCopyCreated(v.name) ?? v.name,
          actionLabel: l?.actionOpen,
          onAction: () => s.openItem(v),
        );
        return CommandResult.ok({'uuid': v.uuid.uuid});
      },
    ),
    shellCommand(
      'shell.drive.addShortcut',
      title: (l) => l.cmdAddShortcut,
      icon: LucideIcons.folderSymlink,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {
          ...targetProps,
          'folderUuid': JsonSchema.nullable(JsonSchema.string(format: 'uuid')),
        },
      ),
      enabled: (ctx, a) =>
          hasExplicitTargets(a) ||
          (singleTarget(
                s,
                a,
              )?.let((i) => i.owner.uuid != s.me?.uuid && !i.isTrashed) ??
              false),
      run: (ctx, a) async {
        final targets = await fetchTargets(s, a);
        if (targets.length != 1) return const CommandResult.cancelled();
        UuidValue? folder;
        if (a.values.containsKey('folderUuid')) {
          final f = a.string('folderUuid');
          folder = f == null ? null : UuidValue.fromString(f);
        } else {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          final picked = await showMoveDialog(
            c,
            s,
            targets,
            title: s.l10n?.addShortcutTitle,
            actionLabel: s.l10n?.addShortcutAction,
          );
          if (picked == null) return const CommandResult.cancelled();
          folder = picked.folderUuid;
        }
        final v = await drive.addShortcut(targets.single.uuid, folder);
        s.toasts.show(s.l10n?.toastShortcutAdded ?? 'Shortcut added');
        return CommandResult.ok({'uuid': v.uuid.uuid});
      },
    ),
    shellCommand(
      'shell.drive.setStarred',
      title: (l) => l.cmdStar,
      icon: LucideIcons.star,
      bindings: const [KeyBinding('S')],
      scope: KeyScope.drive,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {...targetProps, 'starred': JsonSchema.boolean()},
      ),
      enabled: (ctx, a) => targetsAll(s, a, (i) => !i.isTrashed),
      checked: (ctx, a) {
        final t = knownTargets(s, a);
        return t.isEmpty ? null : t.every((i) => i.starred);
      },
      run: (ctx, a) async {
        final items = await fetchTargets(s, a);
        if (items.isEmpty) return const CommandResult.cancelled();
        final starred = a.boolean('starred') ?? !items.every((i) => i.starred);
        final out = [
          for (final i in items) await drive.setStarred(i.uuid, starred),
        ];
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.star,
            items: [for (final i in items) i.uuid.uuid],
            before: {for (final i in items) i.uuid.uuid: i.starred},
            after: {for (final i in items) i.uuid.uuid: starred},
          ),
        );
        changed(out);
        return CommandResult.ok({'starred': starred});
      },
    ),
    shellCommand(
      'shell.drive.togglePinnedOffline',
      title: (l) => l.cmdMakeAvailableOffline,
      icon: LucideIcons.cloudDownload,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {...targetProps, 'pinned': JsonSchema.boolean()},
      ),
      enabled: (ctx, a) => targetsAll(s, a, (i) => !i.isFolder && !i.isTrashed),
      checked: (ctx, a) {
        final t = knownTargets(s, a);
        return t.isEmpty ? null : t.every((i) => i.pinnedOffline);
      },
      run: (ctx, a) async {
        final items = await fetchTargets(s, a);
        if (items.isEmpty) return const CommandResult.cancelled();
        final pinned =
            a.boolean('pinned') ?? !items.every((i) => i.pinnedOffline);
        changed([
          for (final i in items) await drive.setPinnedOffline(i.uuid, pinned),
        ]);
        return CommandResult.ok({'pinned': pinned});
      },
    ),
    shellCommand(
      'shell.drive.trash',
      title: (l) => l.cmdMoveToTrash,
      icon: LucideIcons.trash2,
      bindings: const [
        KeyBinding(Keys.delete),
        KeyBinding(Keys.backspace, mod: true, mac: true),
      ],
      scope: KeyScope.drive,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(properties: targetProps),
      enabled: (ctx, a) => targetsAll(s, a, canManageItem),
      run: (ctx, a) async {
        final items = await fetchTargets(s, a);
        if (items.isEmpty) return const CommandResult.cancelled();
        await drive.trash([for (final i in items) i.uuid]);
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.trash,
            items: [for (final i in items) i.uuid.uuid],
            before: {for (final i in items) i.uuid.uuid: true},
            after: {for (final i in items) i.uuid.uuid: false},
          ),
        );
        for (final i in items) {
          s.emitDriveChange(
            DriveChange(kind: DriveChangeKind.trashed, itemUuid: i.uuid),
          );
        }
        final cur = s.currentItem.value;
        if (cur != null && items.any((i) => i.uuid == cur.uuid)) {
          s.currentItem.value = cur.copyWith(trashedAt: DateTime.now());
        }
        final l = s.l10n;
        if (ctx.source != InvocationSource.mcp) {
          s.toasts.show(
            l?.toastMovedToTrash(items.length) ?? 'Moved to trash',
            actionLabel: l?.actionUndo,
            onAction: () => s.dispatcher.invoke(
              'shell.edit.undo',
              source: InvocationSource.ui,
            ),
          );
        }
        return CommandResult.ok({'trashed': items.length});
      },
    ),
    shellCommand(
      'shell.drive.restore',
      title: (l) => l.cmdRestore,
      icon: LucideIcons.archiveRestore,
      undoable: true,
      undoTarget: UndoTarget.shell,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(properties: targetProps),
      enabled: (ctx, a) => targetsAll(s, a, (i) => i.isTrashed && i.canManage),
      run: (ctx, a) async {
        final items = await fetchTargets(s, a);
        if (items.isEmpty) return const CommandResult.cancelled();
        await drive.restore([for (final i in items) i.uuid]);
        ctx.record(
          DriveUndoEntry(
            op: DriveUndoOp.trash,
            items: [for (final i in items) i.uuid.uuid],
            before: {for (final i in items) i.uuid.uuid: false},
            after: {for (final i in items) i.uuid.uuid: true},
          ),
        );
        for (final i in items) {
          s.emitDriveChange(
            DriveChange(kind: DriveChangeKind.restored, itemUuid: i.uuid),
          );
        }
        final cur = s.currentItem.value;
        if (cur != null && items.any((i) => i.uuid == cur.uuid)) {
          s.currentItem.value = cur.copyWith(trashedAt: null);
        }
        return CommandResult.ok({'restored': items.length});
      },
    ),
    shellCommand(
      'shell.drive.deleteForever',
      title: (l) => l.cmdDeleteForever,
      icon: LucideIcons.trash,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {...targetProps, 'confirmed': JsonSchema.boolean()},
      ),
      enabled: (ctx, a) =>
          targetsAll(s, a, (i) => i.isTrashed && i.myRole.isOwner),
      run: (ctx, a) async {
        final items = await fetchTargets(s, a);
        if (items.isEmpty) return const CommandResult.cancelled();
        if (a.boolean('confirmed') != true) {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          if (!await confirmDeleteForever(c, items.length)) {
            return const CommandResult.cancelled();
          }
        }
        await drive.deletePermanently([for (final i in items) i.uuid]);
        for (final i in items) {
          s.emitDriveChange(
            DriveChange(kind: DriveChangeKind.removed, itemUuid: i.uuid),
          );
        }
        return CommandResult.ok({'deleted': items.length});
      },
    ),
    shellCommand(
      'shell.drive.emptyTrash',
      title: (l) => l.cmdEmptyTrash,
      icon: LucideIcons.trash,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {'confirmed': JsonSchema.boolean()},
      ),
      enabled: (ctx, a) => s.connectivity.online,
      run: (ctx, a) async {
        if (a.boolean('confirmed') != true) {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          if (!await confirmEmptyTrash(c)) {
            return const CommandResult.cancelled();
          }
        }
        final n = await drive.emptyTrash();
        s.refreshDrive();
        return CommandResult.ok({'deleted': n});
      },
    ),
    shellCommand(
      'shell.drive.upload',
      title: (l) => l.cmdUpload,
      icon: LucideIcons.upload,
      bindings: const [KeyBinding('U', shift: true)],
      scope: KeyScope.drive,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(
        properties: {'parentUuid': JsonSchema.string(format: 'uuid')},
      ),
      // Drive queues uploads offline (Drive 02 §4.2); imports need the
      // server.
      enabled: (ctx, a) =>
          s.config.importHandler != null &&
          (s.connectivity.online ||
              (s.config.homeScope?.uploadsFiles ?? false)),
      run: (ctx, a) async {
        final handler = s.config.importHandler;
        final c = ctx.dialogContext;
        if (handler == null || c == null) {
          return const CommandResult.cancelled();
        }
        final files = await handler.pickFiles(c);
        if (files.isEmpty || !c.mounted) return const CommandResult.cancelled();
        final parent = a.string('parentUuid');
        final items = await handler.importFiles(
          c,
          s,
          files,
          parentUuid: parent != null
              ? UuidValue.fromString(parent)
              : s.currentFolder.value?.uuid,
        );
        for (final v in items) {
          s.emitDriveChange(
            DriveChange(
              kind: DriveChangeKind.created,
              itemUuid: v.uuid,
              item: v,
            ),
          );
        }
        return CommandResult.ok({'imported': items.length});
      },
    ),
    shellCommand(
      'shell.drive.open',
      title: (l) => l.cmdOpen,
      icon: LucideIcons.externalLink,
      bindings: const [KeyBinding(Keys.enter)],
      scope: KeyScope.drive,
      category: (l) => l.categoryDrive,
      args: const JsonSchema.object(properties: targetProps),
      enabled: (ctx, a) => hasExplicitTargets(a) || singleTarget(s, a) != null,
      run: (ctx, a) async {
        final t = await fetchTargets(s, a);
        if (t.length != 1) return const CommandResult.cancelled();
        await s.openItem(t.single);
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.drive.copyLinkToClipboard',
      title: (l) => l.cmdCopyLink,
      palette: false,
      args: const JsonSchema.object(properties: targetProps),
      enabled: (ctx, a) => hasExplicitTargets(a) || singleTarget(s, a) != null,
      run: (ctx, a) async {
        final t = await fetchTargets(s, a);
        if (t.length != 1) return const CommandResult.cancelled();
        await Clipboard.setData(ClipboardData(text: itemUrl(s, t.single)));
        s.toasts.show(s.l10n?.toastLinkCopied ?? 'Link copied');
        return const CommandResult.ok();
      },
    ),
  ];
}

/// The shareable URL of [item] (its app's base URL + path).
String itemUrl(ShellServices s, DriveItemView item) => switch (item.kind) {
  DriveItemKind.folder => s.urls.urlFor(s.config.app, item.path),
  _ => s.urls.urlFor(appForKind(item.kind), item.path),
};

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
