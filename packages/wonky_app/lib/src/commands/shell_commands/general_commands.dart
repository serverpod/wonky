import 'dart:convert';

import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../../board/board_commands.dart';
import '../../board/report_commands.dart';
import '../../bootstrap/app_urls.dart';
import '../../comments/comment_anchor.dart';
import '../../config/home_scope.dart';
import '../../comments/comments_undo.dart';
import '../../data/models_ext.dart';
import '../../shell/bug_report.dart';
import '../../shell/dialogs.dart';
import '../../shell/overlays/shell_overlays.dart' show clientVersion;
import '../../shell/shell_services.dart';
import '../../sharing/share_dialog.dart';
import '../../undo/undo_history.dart';
import '../../undo/undo_service.dart';
import '../../versions/versions_undo.dart';
import '../command.dart';
import '../palette/command_palette.dart';
import '../palette/quick_switcher.dart';
import '../shortcuts_help.dart';
import 'drive_commands.dart';
import 'shell_command_base.dart';

/// Panel ids owned by the shell.
abstract final class ShellPanels {
  static const comments = 'comments';
  static const history = 'history';
  static const details = 'details';
  static const assistant = 'assistant';
}

/// Every shell command of suite 08 §5 except the drive group.
List<Command<CommandArgs>> generalCommands(ShellServices s) => [
  ...navigationCommands(s),
  ...fileCommands(s),
  ...sharingCommands(s),
  ...editCommands(s),
  ...commentCommands(s),
  ...versionCommands(s),
  ...panelCommands(s),
  ...viewCommands(s),
  ...miscCommands(s),
  shellCommandFocusSearch(s),
];

const _desktopOnly = false;

List<Command<CommandArgs>> navigationCommands(ShellServices s) => [
  shellCommand(
    'shell.nav.home',
    title: (l) => l.cmdHome,
    icon: LucideIcons.house,
    category: (l) => l.categoryNavigation,
    run: (ctx, a) async {
      s.router.go('/');
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.nav.openInDrive',
    title: (l) => l.cmdOpenInDrive,
    icon: LucideIcons.hardDrive,
    category: (l) => l.categoryNavigation,
    args: const JsonSchema.object(
      properties: {
        'folderUuid': JsonSchema.string(
          format: 'uuid',
          description:
              'Folder to show; default: the current folder or drive view.',
        ),
      },
    ),
    enabled: (ctx, a) => s.config.app != WonkyAppKind.drive,
    run: (ctx, a) async {
      final path = drivePathFor(s, folderUuid: a.string('folderUuid'));
      await s.crossApp.open(WonkyAppKind.drive, path);
      return CommandResult.ok({'path': path});
    },
  ),
  shellCommand(
    'shell.nav.back',
    title: (l) => l.cmdBack,
    icon: LucideIcons.arrowLeft,
    bindings: const [KeyBinding('[', mod: true, web: _desktopOnly)],
    category: (l) => l.categoryNavigation,
    enabled: (ctx, a) => s.canGoBack,
    run: (ctx, a) async {
      s.goBack();
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.nav.forward',
    title: (l) => l.cmdForward,
    icon: LucideIcons.arrowRight,
    bindings: const [KeyBinding(']', mod: true, web: _desktopOnly)],
    category: (l) => l.categoryNavigation,
    enabled: (ctx, a) => s.canGoForward,
    run: (ctx, a) async {
      s.goForward();
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.nav.quickSwitcher',
    title: (l) => l.cmdQuickSwitcher,
    icon: LucideIcons.search,
    bindings: const [KeyBinding('O', mod: true)],
    category: (l) => l.categoryNavigation,
    run: (ctx, a) async {
      final c = ctx.dialogContext;
      if (c == null || !c.mounted) return const CommandResult.cancelled();
      await showQuickSwitcher(c, s);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.nav.commandPalette',
    title: (l) => l.cmdCommandPalette,
    icon: LucideIcons.squareTerminal,
    bindings: const [KeyBinding('P', mod: true, shift: true)],
    category: (l) => l.categoryNavigation,
    palette: false,
    run: (ctx, a) async {
      final c = ctx.dialogContext;
      if (c == null || !c.mounted) return const CommandResult.cancelled();
      await showCommandPalette(c, s);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.focus.nextRegion',
    title: (l) => l.cmdNextRegion,
    bindings: const [KeyBinding('F6')],
    category: (l) => l.categoryNavigation,
    run: (ctx, a) async {
      _cycleRegion(s, 1);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.focus.previousRegion',
    title: (l) => l.cmdPreviousRegion,
    bindings: const [KeyBinding('F6', shift: true)],
    category: (l) => l.categoryNavigation,
    run: (ctx, a) async {
      _cycleRegion(s, -1);
      return const CommandResult.ok();
    },
  ),
];

void _cycleRegion(ShellServices s, int delta) {
  final regions = [
    for (final r in s.focusRegions)
      if (r.context != null && r.context!.mounted) r,
  ];
  if (regions.isEmpty) return;
  final primary = FocusManager.instance.primaryFocus;
  var current = -1;
  for (var i = 0; i < regions.length; i++) {
    final r = regions[i];
    if (r == primary || (primary != null && primary.ancestors.contains(r))) {
      current = i;
    }
  }
  final next =
      regions[((current + delta) % regions.length + regions.length) %
          regions.length];
  final first = next.traversalDescendants
      .where((n) => n.canRequestFocus)
      .firstOrNull;
  (first ?? next).requestFocus();
}

List<Command<CommandArgs>> fileCommands(ShellServices s) {
  Future<CommandResult> newItem(
    CommandContext ctx,
    DriveItemKind kind, {
    UuidValue? template,
  }) async {
    if (s.creatingFile.value) return const CommandResult.cancelled();
    s.creatingFile.value = true;
    try {
      final parent = s.currentFolder.value?.uuid;
      if (kind == s.config.primaryKind) {
        final uuid = await s.config.createItem(
          s,
          parentUuid: parent,
          templateUuid: template,
        );
        if (uuid == null) return const CommandResult.cancelled();
        s.router.go(s.config.itemPath(uuid.uuid));
        return CommandResult.ok({'uuid': uuid.uuid});
      }
      // Other kinds are created by their app's `/new` route (suite 03 §2,
      // Drive 04 §5): offline-first where that app supports it.
      final app = appForKind(kind);
      final path = NewItemRequest(
        folderUuid: parent,
        templateUuid: template,
      ).path;
      await s.crossApp.open(app, path);
      return CommandResult.ok({'app': app.name, 'path': path});
    } finally {
      s.creatingFile.value = false;
    }
  }

  // Drive has no primary kind (D-17 gives it its own New menu).
  final defaultKind = s.config.primaryKind ?? DriveItemKind.document;

  DriveItemKind kindOf(JsonArgs a) => switch (a.string('kind')) {
    'spreadsheet' => DriveItemKind.spreadsheet,
    'presentation' => DriveItemKind.presentation,
    _ => DriveItemKind.document,
  };

  return [
    shellCommand(
      'shell.file.new',
      title: (l) => l.cmdNewFile,
      icon: LucideIcons.filePlus,
      bindings: const [KeyBinding('N', mod: true, alt: true)],
      scope: KeyScope.drive,
      category: (l) => l.categoryFile,
      args: const JsonSchema.object(
        properties: {
          'kind': JsonSchema.string(
            enumValues: ['document', 'spreadsheet', 'presentation'],
          ),
          'templateUuid': JsonSchema.string(format: 'uuid'),
        },
      ),
      enabled: (ctx, a) =>
          !s.creatingFile.value &&
          (s.connectivity.online ||
              kindOf(
                    a.values.containsKey('kind')
                        ? a
                        : JsonArgs({'kind': defaultKind.name}),
                  ) ==
                  s.config.primaryKind),
      run: (ctx, a) {
        final kind = a.values.containsKey('kind') ? kindOf(a) : defaultKind;
        final t = a.string('templateUuid');
        return newItem(
          ctx,
          kind,
          template: t == null ? null : UuidValue.fromString(t),
        );
      },
    ),
    // Sheets 04 §3.1 ids (aliases of shell.file.new).
    shellCommand(
      'shell.drive.newDocument',
      title: (l) => l.cmdNewDocument,
      icon: LucideIcons.fileText,
      category: (l) => l.categoryFile,
      run: (ctx, a) => newItem(ctx, DriveItemKind.document),
    ),
    shellCommand(
      'shell.drive.newSpreadsheet',
      title: (l) => l.cmdNewSpreadsheet,
      icon: LucideIcons.sheet,
      category: (l) => l.categoryFile,
      run: (ctx, a) => newItem(ctx, DriveItemKind.spreadsheet),
    ),
    shellCommand(
      'shell.file.newFromTemplate',
      title: (l) => l.cmdNewFromTemplate,
      icon: LucideIcons.layoutTemplate,
      category: (l) => l.categoryFile,
      run: (ctx, a) async {
        s.router.go('/templates');
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.drive.newFromTemplate',
      title: (l) => l.cmdNewFromTemplate,
      icon: LucideIcons.layoutTemplate,
      palette: false,
      run: (ctx, a) async {
        s.router.go('/templates');
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.drive.makeCopy',
      title: (l) => l.cmdMakeCopy,
      icon: LucideIcons.copy,
      palette: false,
      args: const JsonSchema.object(
        properties: targetProps,
        additionalProperties: true,
      ),
      enabled: (ctx, a) =>
          s.dispatcher.stateOf('shell.drive.copy', a.values).enabled,
      run: (ctx, a) => s.dispatcher.invoke(
        'shell.drive.copy',
        args: a.values,
        source: ctx.source,
        context: ctx.buildContext,
      ),
    ),
    shellCommand(
      'shell.file.open',
      title: (l) => l.cmdOpenFile,
      icon: LucideIcons.folderOpen,
      category: (l) => l.categoryFile,
      run: (ctx, a) async {
        final c = ctx.dialogContext;
        if (c == null || !c.mounted) return const CommandResult.cancelled();
        await showQuickSwitcher(c, s);
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.file.import',
      title: (l) => l.cmdImport,
      icon: LucideIcons.fileUp,
      category: (l) => l.categoryFile,
      enabled: (ctx, a) =>
          s.config.importHandler != null && s.connectivity.online,
      run: (ctx, a) => s.dispatcher.invoke(
        'shell.drive.upload',
        source: ctx.source,
        context: ctx.buildContext,
      ),
    ),
    shellCommand(
      'shell.file.print',
      title: (l) => l.cmdPrint,
      icon: LucideIcons.printer,
      bindings: const [KeyBinding('P', mod: true)],
      category: (l) => l.categoryFile,
      enabled: (ctx, a) => ctx.document?.canPrint ?? false,
      run: (ctx, a) async {
        await ctx.document?.print();
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.file.download',
      title: (l) => l.cmdDownload,
      icon: LucideIcons.download,
      category: (l) => l.categoryFile,
      args: const JsonSchema.object(
        properties: {
          'format': JsonSchema.string(
            description: 'Format id, e.g. docx, pdf, xlsx, csv, md.',
          ),
        },
        required: ['format'],
      ),
      enabled: (ctx, a) {
        final doc = ctx.document;
        final item = s.currentItem.value;
        return doc != null &&
            (item?.canDownload ?? true) &&
            doc.downloadFormats.isNotEmpty;
      },
      run: (ctx, a) async {
        await ctx.document!.download(a.requireString('format'));
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.file.details',
      title: (l) => l.cmdDetails,
      icon: LucideIcons.info,
      bindings: const [KeyBinding('I')],
      scope: KeyScope.drive,
      category: (l) => l.categoryFile,
      checked: (ctx, a) => s.panels.isOpen(ShellPanels.details),
      run: (ctx, a) async {
        s.panels.toggle(ShellPanels.details);
        return const CommandResult.ok();
      },
    ),
  ];
}

List<Command<CommandArgs>> sharingCommands(ShellServices s) => [
  shellCommand(
    'shell.sharing.open',
    title: (l) => l.cmdShare,
    icon: LucideIcons.userPlus,
    bindings: const [KeyBinding('.')],
    scope: KeyScope.drive,
    category: (l) => l.categorySharing,
    args: const JsonSchema.object(properties: targetProps),
    enabled: (ctx, a) => hasExplicitTargets(a) || singleTarget(s, a) != null,
    run: (ctx, a) async {
      final t = await fetchTargets(s, a);
      final c = ctx.dialogContext;
      if (t.length != 1 || c == null || !c.mounted) {
        return const CommandResult.cancelled();
      }
      await showShareDialog(c, s, t.single);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.sharing.copyLink',
    title: (l) => l.cmdCopyLink,
    icon: LucideIcons.link,
    category: (l) => l.categorySharing,
    args: const JsonSchema.object(properties: targetProps),
    enabled: (ctx, a) => hasExplicitTargets(a) || singleTarget(s, a) != null,
    run: (ctx, a) async {
      final t = await fetchTargets(s, a);
      if (t.length != 1) return const CommandResult.cancelled();
      final url = itemUrl(s, t.single);
      await Clipboard.setData(ClipboardData(text: url));
      s.toasts.show(s.l10n?.toastLinkCopied ?? 'Link copied');
      return CommandResult.ok({'url': url});
    },
  ),
  shellCommand(
    'shell.sharing.requestAccess',
    title: (l) => l.cmdRequestAccess,
    icon: LucideIcons.keyRound,
    category: (l) => l.categorySharing,
    args: const JsonSchema.object(
      properties: {
        'uuid': JsonSchema.string(format: 'uuid'),
        'role': JsonSchema.string(
          enumValues: ['viewer', 'commenter', 'editor'],
        ),
        'message': JsonSchema.string(),
      },
    ),
    enabled: (ctx, a) =>
        a.string('uuid') != null || s.currentItem.value != null,
    run: (ctx, a) async {
      final id = a.string('uuid') ?? s.currentItem.value?.uuid.uuid;
      if (id == null) return const CommandResult.cancelled();
      final uuid = UuidValue.fromString(id);
      final role = a.string('role');
      if (role != null) {
        await s.repositories.sharing.requestAccess(
          uuid,
          AccessRole.values.byName(role),
          a.string('message'),
        );
        s.toasts.show(s.l10n?.toastAccessRequested ?? 'Request sent');
        return const CommandResult.ok();
      }
      final c = ctx.dialogContext;
      if (c == null || !c.mounted) return const CommandResult.cancelled();
      final sent = await showRequestAccessDialog(c, s, uuid);
      return sent ? const CommandResult.ok() : const CommandResult.cancelled();
    },
  ),
];

List<Command<CommandArgs>> editCommands(ShellServices s) {
  bool inDrive() => s.activeDocument.value == null;
  return [
    shellCommand(
      'shell.edit.undo',
      title: (l) => s.undo.undoLabel.value == null
          ? l.cmdUndo
          : l.cmdUndoLabel(s.undo.undoLabel.value!),
      icon: LucideIcons.undo2,
      bindings: const [KeyBinding('Z', mod: true)],
      category: (l) => l.categoryEdit,
      enabled: (ctx, a) => s.undo.canUndo.value,
      run: (ctx, a) async {
        await ctx.document?.beforeUndo();
        final o = await s.undo.undo();
        _announceUndo(s, o);
        return o == null
            ? const CommandResult.cancelled()
            : CommandResult.ok({'undone': o.step.label});
      },
    ),
    shellCommand(
      'shell.edit.redo',
      title: (l) => s.undo.redoLabel.value == null
          ? l.cmdRedo
          : l.cmdRedoLabel(s.undo.redoLabel.value!),
      icon: LucideIcons.redo2,
      bindings: const [
        KeyBinding('Z', mod: true, shift: true),
        KeyBinding('Y', mod: true, mac: false),
      ],
      category: (l) => l.categoryEdit,
      enabled: (ctx, a) => s.undo.canRedo.value,
      run: (ctx, a) async {
        await ctx.document?.beforeRedo();
        final o = await s.undo.redo();
        _announceUndo(s, o);
        return o == null
            ? const CommandResult.cancelled()
            : CommandResult.ok({'redone': o.step.label});
      },
    ),
    shellCommand(
      'shell.edit.undoHistory',
      title: (l) => l.cmdUndoHistory,
      icon: LucideIcons.history,
      category: (l) => l.categoryEdit,
      enabled: (ctx, a) => s.undo.canUndo.value,
      run: (ctx, a) async {
        final c = ctx.dialogContext;
        if (c == null || !c.mounted) return const CommandResult.cancelled();
        await showUndoHistoryDialog(c, s);
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.edit.undoTo',
      title: (l) => l.cmdUndoTo,
      palette: false,
      category: (l) => l.categoryEdit,
      args: const JsonSchema.object(
        properties: {
          'stepId': JsonSchema.string(
            description: 'Id of the step from the undo history.',
          ),
        },
        required: ['stepId'],
      ),
      enabled: (ctx, a) => s.undo.canUndo.value,
      run: (ctx, a) async {
        await ctx.document?.beforeUndo();
        await s.undo.undoTo(a.requireString('stepId'));
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.edit.cut',
      title: (l) => l.cmdCut,
      icon: LucideIcons.scissors,
      bindings: const [KeyBinding('X', mod: true)],
      category: (l) => l.categoryEdit,
      role: Role.editor,
      enabled: (ctx, a) => ctx.document?.canCut ?? false,
      run: (ctx, a) async {
        await ctx.document?.cut();
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.edit.copy',
      title: (l) => l.cmdCopy,
      icon: LucideIcons.copy,
      bindings: const [KeyBinding('C', mod: true)],
      category: (l) => l.categoryEdit,
      enabled: (ctx, a) => ctx.document?.canCopy ?? false,
      run: (ctx, a) async {
        await ctx.document?.copy();
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.edit.paste',
      title: (l) => l.cmdPaste,
      icon: LucideIcons.clipboardPaste,
      bindings: const [KeyBinding('V', mod: true)],
      category: (l) => l.categoryEdit,
      role: Role.editor,
      enabled: (ctx, a) => ctx.document?.canPaste ?? false,
      run: (ctx, a) async {
        await ctx.document?.paste();
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.edit.pasteWithoutFormatting',
      title: (l) => l.cmdPastePlain,
      icon: LucideIcons.clipboardType,
      bindings: const [KeyBinding('V', mod: true, shift: true)],
      category: (l) => l.categoryEdit,
      role: Role.editor,
      enabled: (ctx, a) => ctx.document?.canPaste ?? false,
      run: (ctx, a) async {
        await ctx.document?.paste(plainText: true);
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.edit.selectAll',
      title: (l) => l.cmdSelectAll,
      icon: LucideIcons.textSelect,
      bindings: const [KeyBinding('A', mod: true)],
      category: (l) => l.categoryEdit,
      enabled: (ctx, a) => inDrive()
          ? s.driveSelectAll != null
          : (ctx.document?.canSelectAll ?? false),
      run: (ctx, a) async {
        if (inDrive()) {
          s.driveSelectAll?.call();
        } else {
          ctx.document?.selectAll();
        }
        return const CommandResult.ok();
      },
    ),
  ];
}

void _announceUndo(ShellServices s, UndoOutcome? outcome) {
  if (outcome == null) return;
  final l = s.l10n;
  final c = s.navigatorContext;
  final label = outcome.step.label;
  if (c != null) {
    SemanticsService.sendAnnouncement(
      View.of(c),
      outcome.isRedo
          ? (l?.cmdRedoLabel(label) ?? label)
          : (l?.cmdUndoLabel(label) ?? label),
      Directionality.of(c),
    );
  }
  if (outcome.partial) {
    s.toasts.show(
      l?.toastUndoPartial ??
          'Some changes could not be undone because they were edited by someone else.',
    );
  }
}

/// The anchor of a new comment: [scope]'s when [anchors] knows scopes
/// ([CommentAnchorScopes]), else the selection's.
NewCommentAnchor? _anchorOf(CommentAnchorProvider? anchors, String? scope) =>
    scope != null && anchors is CommentAnchorScopes
    ? (anchors as CommentAnchorScopes).anchorForScope(scope)
    : anchors?.anchorForSelection();

List<Command<CommandArgs>> commentCommands(ShellServices s) {
  final comments = s.comments;
  return [
    shellCommand(
      'shell.comments.create',
      title: (l) => l.cmdComment,
      icon: LucideIcons.messageSquarePlus,
      bindings: const [KeyBinding('M', mod: true, alt: true)],
      category: (l) => l.categoryComments,
      role: Role.commenter,
      undoable: true,
      args: const JsonSchema.object(
        properties: {
          'body': JsonSchema.string(
            minLength: 1,
            description: 'Comment text (Markdown). Omit to open the composer.',
          ),
          'mentions': JsonSchema.array(JsonSchema.integer()),
          'assigneeId': JsonSchema.integer(),
          'anchorKind': JsonSchema.string(
            enumValues: [
              'textRange',
              'cell',
              'range',
              'document',
              'slide',
              'element',
            ],
          ),
          'anchorJson': JsonSchema.string(),
          'quotedText': JsonSchema.string(),
          'anchor': JsonSchema.string(
            description:
                'An app-specific anchor scope instead of the selection '
                '(Slides: slide, element).',
          ),
        },
      ),
      enabled: (ctx, a) =>
          comments.value != null &&
          (a.string('anchorJson') != null ||
              _anchorOf(ctx.document?.commentAnchors, a.string('anchor')) !=
                  null),
      run: (ctx, a) async {
        final c = comments.value!;
        final anchor = a.string('anchorJson') != null
            ? NewCommentAnchor(
                kind: CommentAnchorKind.values.byName(
                  a.string('anchorKind') ?? 'document',
                ),
                anchorJson: a.string('anchorJson')!,
                quotedText: a.string('quotedText'),
              )
            : _anchorOf(ctx.document?.commentAnchors, a.string('anchor'))!;
        final body = a.string('body');
        if (body == null) {
          // Sheets composes next to the cell unless the panel is open.
          final inline =
              (commentPanelOptionsOf(
                    ctx.document?.commentAnchors,
                  )?.composesInline ??
                  false) &&
              !s.panels.isOpen(ShellPanels.comments);
          if (!inline) _showComments(s);
          c.startDraft(anchor);
          return const CommandResult.cancelled();
        }
        final t = await c.createThread(
          anchor: anchor,
          body: body,
          mentions: [
            for (final m in (a.values['mentions'] as List?) ?? const [])
              (m as num).toInt(),
          ],
          assigneeId: a.integer('assigneeId'),
        );
        ctx.record(
          CommentUndoEntry(
            op: CommentUndoOp.createThread,
            threadUuid: t.uuid.uuid,
            body: body,
            anchorKind: anchor.kind,
            anchorJson: anchor.anchorJson,
            quotedText: anchor.quotedText,
          ),
        );
        return CommandResult.ok({'threadUuid': t.uuid.uuid});
      },
    ),
    shellCommand(
      'shell.comments.reply',
      title: (l) => l.cmdReply,
      icon: LucideIcons.reply,
      palette: false,
      category: (l) => l.categoryComments,
      role: Role.commenter,
      undoable: true,
      args: const JsonSchema.object(
        properties: {
          'threadUuid': JsonSchema.string(format: 'uuid'),
          'body': JsonSchema.string(minLength: 1),
          'mentions': JsonSchema.array(JsonSchema.integer()),
        },
        required: ['threadUuid', 'body'],
      ),
      enabled: (ctx, a) => comments.value != null,
      run: (ctx, a) async {
        final threadUuid = a.requireString('threadUuid');
        final body = a.requireString('body');
        final t = await comments.value!.reply(
          threadUuid,
          body,
          mentions: [
            for (final m in (a.values['mentions'] as List?) ?? const [])
              (m as num).toInt(),
          ],
        );
        ctx.record(
          CommentUndoEntry(
            op: CommentUndoOp.reply,
            threadUuid: threadUuid,
            commentId: t.comments.isEmpty ? null : t.comments.last.id,
            body: body,
          ),
        );
        return const CommandResult.ok();
      },
    ),
    for (final (id, op, title, icon) in [
      (
        'shell.comments.resolve',
        CommentUndoOp.resolve,
        'resolve',
        LucideIcons.check,
      ),
      (
        'shell.comments.reopen',
        CommentUndoOp.reopen,
        'reopen',
        LucideIcons.rotateCcw,
      ),
    ])
      shellCommand(
        id,
        title: (l) => title == 'resolve' ? l.cmdResolve : l.cmdReopen,
        icon: icon,
        palette: false,
        category: (l) => l.categoryComments,
        role: Role.commenter,
        undoable: true,
        args: const JsonSchema.object(
          properties: {'threadUuid': JsonSchema.string(format: 'uuid')},
          required: ['threadUuid'],
        ),
        enabled: (ctx, a) => comments.value != null,
        run: (ctx, a) async {
          final threadUuid = a.requireString('threadUuid');
          if (op == CommentUndoOp.resolve) {
            await comments.value!.resolve(threadUuid);
          } else {
            await comments.value!.reopen(threadUuid);
          }
          ctx.record(CommentUndoEntry(op: op, threadUuid: threadUuid));
          return const CommandResult.ok();
        },
      ),
    shellCommand(
      'shell.comments.delete',
      title: (l) => l.cmdDeleteComment,
      icon: LucideIcons.trash2,
      palette: false,
      category: (l) => l.categoryComments,
      role: Role.commenter,
      undoable: true,
      args: const JsonSchema.object(
        properties: {
          'threadUuid': JsonSchema.string(format: 'uuid'),
          'commentId': JsonSchema.integer(
            description: 'Delete one comment instead of the whole thread.',
          ),
        },
        required: ['threadUuid'],
      ),
      enabled: (ctx, a) => comments.value != null,
      run: (ctx, a) async {
        final c = comments.value!;
        final threadUuid = a.requireString('threadUuid');
        final t = c.thread(threadUuid);
        final commentId = a.integer('commentId');
        if (commentId != null) {
          final body = t?.comments
              .where((x) => x.id == commentId)
              .firstOrNull
              ?.body;
          await c.deleteComment(commentId);
          ctx.record(
            CommentUndoEntry(
              op: CommentUndoOp.deleteComment,
              threadUuid: threadUuid,
              commentId: commentId,
              body: body,
            ),
          );
        } else {
          await c.deleteThread(threadUuid);
          ctx.record(
            CommentUndoEntry(
              op: CommentUndoOp.deleteThread,
              threadUuid: threadUuid,
              body: t?.comments.firstOrNull?.body,
              anchorKind: t?.anchorKind,
              anchorJson: t?.anchorJson,
              quotedText: t?.quotedText,
            ),
          );
        }
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.comments.activate',
      title: (l) => l.cmdOpenComment,
      palette: false,
      category: (l) => l.categoryComments,
      args: const JsonSchema.object(
        properties: {'threadUuid': JsonSchema.string(format: 'uuid')},
        required: ['threadUuid'],
      ),
      enabled: (ctx, a) => comments.value != null,
      run: (ctx, a) async {
        _showComments(s);
        comments.value!.activate(a.requireString('threadUuid'));
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.comments.togglePanel',
      title: (l) => l.cmdCommentsPanel,
      icon: LucideIcons.messageSquare,
      category: (l) => l.categoryComments,
      enabled: (ctx, a) => comments.value != null,
      checked: (ctx, a) =>
          s.commentsHost?.isShown ?? s.panels.isOpen(ShellPanels.comments),
      run: (ctx, a) async {
        final host = s.commentsHost;
        if (host != null) {
          host.isShown = !host.isShown;
        } else {
          s.panels.toggle(ShellPanels.comments);
        }
        return const CommandResult.ok();
      },
    ),
  ];
}

/// Shows the open file's comments: through the app's [CommentsHost] when it
/// has one, otherwise in the comments side panel.
void _showComments(ShellServices s) {
  final host = s.commentsHost;
  if (host != null) {
    host.isShown = true;
  } else {
    s.panels.open(ShellPanels.comments);
  }
}

List<Command<CommandArgs>> versionCommands(ShellServices s) {
  bool canHistory() => s.currentItem.value?.myRole.canViewHistory ?? false;
  return [
    shellCommand(
      'shell.versions.open',
      title: (l) => l.cmdSeeVersionHistory,
      icon: LucideIcons.history,
      bindings: const [KeyBinding('H', mod: true, alt: true, shift: true)],
      category: (l) => l.categoryVersions,
      enabled: (ctx, a) => canHistory() && s.connectivity.online,
      run: (ctx, a) async {
        final item = s.currentItem.value!;
        s.router.go('${s.config.itemPath(item.uuid.uuid)}/history');
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.versions.togglePanel',
      title: (l) => l.cmdVersionsPanel,
      icon: LucideIcons.history,
      category: (l) => l.categoryVersions,
      enabled: (ctx, a) => canHistory() && s.connectivity.online,
      checked: (ctx, a) => s.panels.isOpen(ShellPanels.history),
      run: (ctx, a) async {
        s.panels.toggle(ShellPanels.history);
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.versions.nameCurrent',
      title: (l) => l.cmdNameCurrentVersion,
      icon: LucideIcons.bookmarkPlus,
      category: (l) => l.categoryVersions,
      role: Role.editor,
      args: const JsonSchema.object(
        properties: {'name': JsonSchema.string(minLength: 1, maxLength: 200)},
      ),
      enabled: (ctx, a) => canHistory() && s.connectivity.online,
      run: (ctx, a) async {
        var name = a.string('name');
        if (name == null) {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          name = await showNameVersionDialog(c, s);
          if (name == null) return const CommandResult.cancelled();
        }
        final v = await s.repositories.versions.nameCurrent(
          s.currentItem.value!.uuid,
          name,
        );
        s.refreshVersions();
        s.toasts.show(s.l10n?.toastVersionNamed(name) ?? name);
        return CommandResult.ok({'versionId': v.id});
      },
    ),
    shellCommand(
      'shell.versions.restore',
      title: (l) => l.cmdRestoreVersion,
      icon: LucideIcons.archiveRestore,
      palette: false,
      category: (l) => l.categoryVersions,
      role: Role.editor,
      undoable: true,
      args: const JsonSchema.object(
        properties: {
          'versionId': JsonSchema.integer(),
          'confirmed': JsonSchema.boolean(),
        },
        required: ['versionId'],
      ),
      enabled: (ctx, a) => canHistory() && s.connectivity.online,
      run: (ctx, a) async {
        final item = s.currentItem.value!;
        if (a.boolean('confirmed') != true) {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          final l = s.l10n!;
          final ok = await confirmDialog(
            c,
            title: l.restoreVersionTitle,
            description: l.restoreVersionBody,
            confirmLabel: l.restoreVersionAction,
          );
          if (!ok) return const CommandResult.cancelled();
        }
        final versionId = a.integer('versionId')!;
        final r = await s.repositories.versions.restore(item.uuid, versionId);
        ctx.record(
          s.config.versionRenderer?.restoreUndoEntry(item.uuid, versionId, r) ??
              VersionRestoreEntry(
                itemUuid: item.uuid.uuid,
                versionId: versionId,
                restorePointId: r.restorePoint.id,
              ),
        );
        s.refreshVersions();
        s.toasts.show(s.l10n?.toastVersionRestored ?? 'Version restored');
        return CommandResult.ok({'restorePointId': r.restorePoint.id});
      },
    ),
  ];
}

List<Command<CommandArgs>> panelCommands(ShellServices s) {
  const schema = JsonSchema.object(
    properties: {'panelId': JsonSchema.string(minLength: 1)},
    required: ['panelId'],
  );
  return [
    shellCommand(
      'shell.panels.open',
      title: (l) => l.cmdOpenPanel,
      palette: false,
      args: schema,
      run: (ctx, a) async {
        s.panels.open(a.requireString('panelId'));
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.panels.close',
      title: (l) => l.cmdClosePanel,
      palette: false,
      args: schema,
      run: (ctx, a) async {
        s.panels.close(a.requireString('panelId'));
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.panels.toggle',
      title: (l) => l.cmdTogglePanel,
      palette: false,
      args: schema,
      checked: (ctx, a) => s.panels.isOpen(a.string('panelId') ?? ''),
      run: (ctx, a) async {
        s.panels.toggle(a.requireString('panelId'));
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.panels.next',
      title: (l) => l.cmdNextPanel,
      bindings: const [KeyBinding(']', mod: true, alt: true, shift: true)],
      enabled: (ctx, a) => s.panels.recentPanelIds.isNotEmpty,
      run: (ctx, a) async {
        s.panels.cycle(1);
        return const CommandResult.ok();
      },
    ),
    shellCommand(
      'shell.panels.previous',
      title: (l) => l.cmdPreviousPanel,
      bindings: const [KeyBinding('[', mod: true, alt: true, shift: true)],
      enabled: (ctx, a) => s.panels.recentPanelIds.isNotEmpty,
      run: (ctx, a) async {
        s.panels.cycle(-1);
        return const CommandResult.ok();
      },
    ),
  ];
}

List<Command<CommandArgs>> viewCommands(ShellServices s) {
  bool editor() => s.activeDocument.value != null;
  return [
    shellCommand(
      'shell.view.zoom',
      title: (l) => l.cmdZoom,
      icon: LucideIcons.zoomIn,
      category: (l) => l.categoryView,
      args: const JsonSchema.object(
        properties: {'percent': JsonSchema.integer(minimum: 25, maximum: 400)},
        required: ['percent'],
      ),
      enabled: (ctx, a) => editor(),
      checked: (ctx, a) {
        final p = a.integer('percent');
        final d = ctx.document;
        return p == null || d == null ? null : (d.zoom * 100).round() == p;
      },
      run: (ctx, a) async {
        ctx.document?.setZoom(a.integer('percent')! / 100);
        return const CommandResult.ok();
      },
    ),
  ];
}

List<Command<CommandArgs>> miscCommands(ShellServices s) => [
  shellCommand(
    'shell.appearance.setTheme',
    title: (l) => l.cmdSetTheme,
    icon: LucideIcons.sunMoon,
    category: (l) => l.categoryView,
    args: const JsonSchema.object(
      properties: {
        'mode': JsonSchema.string(
          enumValues: ['system', 'light', 'dark', 'cycle'],
        ),
      },
    ),
    checked: (ctx, a) {
      final m = a.string('mode');
      return m == null || m == 'cycle' ? null : s.prefs.appTheme.name == m;
    },
    run: (ctx, a) async {
      final m = a.string('mode') ?? 'cycle';
      if (m == 'cycle') {
        await s.prefs.cycleTheme();
      } else {
        await s.prefs.setAppTheme(AppThemeMode.values.byName(m));
      }
      return CommandResult.ok({'mode': s.prefs.appTheme.name});
    },
  ),
  shellCommand(
    'shell.settings.open',
    title: (l) => l.cmdWorkSettings,
    icon: LucideIcons.settings,
    category: (l) => l.categoryTools,
    // Wonky Work settings (suite 04 §4); the v1 ids of the apps' sections
    // (`write`, `themes`, `sheets`) redirect to their app settings.
    args: const JsonSchema.object(properties: {'section': JsonSchema.string()}),
    run: (ctx, a) async {
      s.router.go('/settings/${a.string('section') ?? 'account'}');
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.settings.openApp',
    title: (l) => l.cmdAppSettings(s.config.shortAppName),
    icon: LucideIcons.settings2,
    // Mod+, (desktop) opens the app's settings (suite 04 §4.2).
    bindings: const [KeyBinding(',', mod: true, web: false)],
    category: (l) => l.categoryTools,
    args: const JsonSchema.object(properties: {'section': JsonSchema.string()}),
    run: (ctx, a) async {
      final section = a.string('section');
      s.router.go(section == null ? '/settings/app' : '/settings/app/$section');
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.storage.open',
    title: (l) => l.cmdManageStorage,
    icon: LucideIcons.chartPie,
    category: (l) => l.categoryTools,
    run: (ctx, a) async {
      if (s.config.app == WonkyAppKind.drive) {
        s.router.go('/storage');
      } else {
        await s.crossApp.open(WonkyAppKind.drive, '/storage');
      }
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.ai.togglePanel',
    title: (l) => l.cmdAssistant,
    icon: LucideIcons.sparkles,
    bindings: const [KeyBinding('J', mod: true)],
    category: (l) => l.categoryTools,
    enabled: (ctx, a) => (s.assistant?.available ?? false) && s.prefs.aiEnabled,
    checked: (ctx, a) => s.panels.isOpen(ShellPanels.assistant),
    run: (ctx, a) async {
      s.panels.toggle(s.assistant?.panelId ?? ShellPanels.assistant);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.ai.newThread',
    title: (l) => l.cmdAssistantNewThread,
    icon: LucideIcons.messageSquareDashed,
    category: (l) => l.categoryTools,
    enabled: (ctx, a) => s.assistant?.available ?? false,
    run: (ctx, a) async {
      await s.assistant!.newThread();
      s.panels.open(s.assistant!.panelId);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.ai.send',
    title: (l) => l.cmdAssistantSend,
    palette: false,
    args: const JsonSchema.object(
      properties: {'prompt': JsonSchema.string(minLength: 1)},
      required: ['prompt'],
    ),
    enabled: (ctx, a) => s.assistant?.available ?? false,
    run: (ctx, a) async {
      await s.assistant!.send(a.requireString('prompt'));
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.ai.stop',
    title: (l) => l.cmdAssistantStop,
    palette: false,
    enabled: (ctx, a) => s.assistant?.available ?? false,
    run: (ctx, a) async {
      await s.assistant!.stop();
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.help.shortcuts',
    title: (l) => l.cmdKeyboardShortcuts,
    icon: LucideIcons.keyboard,
    bindings: const [KeyBinding('/', mod: true)],
    category: (l) => l.categoryHelp,
    run: (ctx, a) async {
      final c = ctx.dialogContext;
      if (c == null || !c.mounted) return const CommandResult.cancelled();
      await showShortcutsHelp(c, s);
      return const CommandResult.ok();
    },
  ),
  // `shell.help.reportBug` and `shell.help.feedback` are aliases of
  // `shell.board.report` (board/report_commands.dart, specs/16 §4.1).
  shellCommand(
    'shell.help.whatsNew',
    title: (l) => l.cmdWhatsNew,
    icon: LucideIcons.gift,
    category: (l) => l.categoryHelp,
    run: (ctx, a) async {
      final c = ctx.dialogContext;
      if (c == null || !c.mounted) return const CommandResult.cancelled();
      await showWhatsNewDialog(c, s);
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.help.about',
    title: (l) => l.cmdAbout,
    icon: LucideIcons.info,
    category: (l) => l.categoryHelp,
    run: (ctx, a) async {
      s.router.go('/settings/about');
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.mcp.copyConnectionInfo',
    title: (l) => l.cmdCopyMcpConfig,
    icon: LucideIcons.plug,
    category: (l) => l.categoryTools,
    run: (ctx, a) async {
      await Clipboard.setData(ClipboardData(text: mcpConnectionJson(s)));
      s.toasts.show(s.l10n?.toastMcpConfigCopied ?? 'Copied');
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.mcp.toggleUiBridge',
    title: (l) => l.cmdToggleUiBridge,
    icon: LucideIcons.bot,
    category: (l) => l.categoryTools,
    checked: (ctx, a) => s.mcp.enabled,
    run: (ctx, a) async {
      s.mcp.setEnabled(!s.mcp.enabled);
      await s.prefs.setDevice('mcp.uiBridge', s.mcp.enabled);
      return CommandResult.ok({'enabled': s.mcp.enabled});
    },
  ),
  shellCommand(
    'shell.mcp.stopControl',
    title: (l) => l.cmdStopAgent,
    icon: LucideIcons.octagonX,
    category: (l) => l.categoryTools,
    enabled: (ctx, a) => s.mcp.controlling,
    run: (ctx, a) async {
      s.mcp.stop();
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.account.signOut',
    title: (l) => l.cmdSignOut,
    icon: LucideIcons.logOut,
    category: (l) => l.categoryAccount,
    run: (ctx, a) async {
      await s.auth.signOut();
      return const CommandResult.ok();
    },
  ),
  shellCommand(
    'shell.account.switchApp',
    title: (l) =>
        s.config.app == WonkyAppKind.write ? l.cmdOpenSheets : l.cmdOpenWrite,
    icon: LucideIcons.arrowLeftRight,
    category: (l) => l.categoryAccount,
    args: JsonSchema.object(
      properties: {
        'app': JsonSchema.string(
          enumValues: [for (final k in WonkyAppKind.values) k.name],
        ),
      },
    ),
    run: (ctx, a) async {
      // Without `app`: Write ⇄ Sheets as in v1 (Drive, Slides → Write); the
      // menus pass `app` (left menu, account menu *Open ▸*).
      final app = a.string('app') == null
          ? (s.config.app == WonkyAppKind.write
                ? WonkyAppKind.sheets
                : WonkyAppKind.write)
          : WonkyAppKind.values.byName(a.string('app')!);
      if (app == s.config.app) {
        s.router.go('/');
      } else {
        await s.crossApp.open(app, '/');
      }
      return const CommandResult.ok();
    },
  ),
];

/// The MCP connection snippet for Claude Desktop / Claude Code (suite 04 §4
/// Developer / MCP).
String mcpConnectionJson(ShellServices s, {String token = r'${WONKY_TOKEN}'}) {
  final url = mcpUrl(s);
  return const JsonEncoder.withIndent('  ').convert({
    'mcpServers': {
      'wonky': {
        'type': 'http',
        'url': url,
        'headers': {'Authorization': 'Bearer $token'},
      },
    },
  });
}

/// All shell commands.
List<Command<CommandArgs>> allShellCommands(ShellServices s) => [
  ...driveCommands(s),
  ...generalCommands(s),
  ...boardReportCommands(s),
  ...boardCommands(s),
];

/// The server's MCP endpoint (`<web server origin>/mcp`). In development the
/// apps run on their own ports and the web server listens on 8082.
String mcpUrl(ShellServices s) {
  final app = Uri.parse(s.urls.apps[s.config.app]!);
  if (app.port == 8101 || app.port == 8102) {
    final api = Uri.parse(s.urls.apiUrl);
    return api.replace(port: 8082, path: '/mcp').toString();
  }
  return app.replace(path: '/mcp').toString();
}

/// `/` focuses the drive search (home screen).
Command<CommandArgs> shellCommandFocusSearch(ShellServices s) => shellCommand(
  'shell.drive.focusSearch',
  title: (l) => l.cmdFocusSearch,
  icon: LucideIcons.search,
  bindings: const [KeyBinding('/')],
  scope: KeyScope.drive,
  category: (l) => l.categoryDrive,
  run: (ctx, a) async {
    s.driveSearchFocus?.requestFocus();
    return const CommandResult.ok();
  },
);

/// The *Report a bug* link of this app (suite 03 §3.4): app, build
/// version, platform and browser family only.
String bugReportUrl(ShellServices s) => BugReportLink.build(
  issuesUrl: s.urls.bugReportUrl,
  app: s.config.app,
  version: clientVersion,
  platform: BugReportLink.currentPlatform,
  browser: s.crossApp.browserLabel(),
);

/// The Wonky Drive route showing what an app home shows now
/// (`shell.nav.openInDrive`): [folderUuid], else the current folder, else
/// the matching drive view (`/my-files` → `/my-drive`, `/shared`, …).
String drivePathFor(ShellServices s, {String? folderUuid}) {
  final folder = folderUuid ?? s.currentFolder.value?.uuid.uuid;
  if (folder != null) return '/f/$folder';
  Uri? uri;
  try {
    uri = s.router.state.uri;
  } catch (_) {
    uri = null;
  }
  return switch (uri?.path) {
    '/my-files' || '/my-drive' => '/my-drive',
    '/shared' || '/starred' || '/recent' || '/trash' => uri!.path,
    '/search' => uri.toString(),
    _ => '/',
  };
}
