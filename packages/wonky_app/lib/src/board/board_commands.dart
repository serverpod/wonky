import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../commands/command.dart';
import '../commands/shell_commands/shell_command_base.dart';
import '../l10n/wonky_app_localizations.dart';
import '../shell/dialogs.dart';
import '../shell/shell_services.dart';
import 'board_hub.dart';
import 'board_repository.dart';
import 'board_undo.dart';
import 'pages/board_dialogs.dart';
import 'pages/prompt_editor.dart';

/// The page URL of post [number] in this app (`/sheets/improvements/p/12`).
String boardPostUrl(ShellServices s, int number) =>
    s.urls.urlFor(s.config.app, '/improvements/p/$number');

/// The page URL of task [number] in this app.
String boardTaskUrl(ShellServices s, int number) =>
    s.urls.urlFor(s.config.app, '/improvements/t/$number');

/// The two lines a contributor puts in the PR description (specs/16 §13.1).
String boardPrLines(int task, String code) =>
    'Wonky-Task: T-$task\nWonky-Claim: $code';

/// `shell.board.*` (specs/16 §14) apart from `report` / `open`, which come
/// with the report dialog. Every state change is undoable on the shell
/// stack through [BoardUndoHandler] (the server inverse); admin commands are
/// registered for everyone and enabled only for board admins
/// (`BoardMe.isAdmin`).
List<Command<CommandArgs>> boardCommands(ShellServices s) {
  s.undo.registerHandler(BoardUndoHandler(s));
  final hub = BoardHub.of(s);
  BoardRepository repo() => s.repositories.board;

  bool writer(CommandContext ctx, JsonArgs a) => s.auth.isSignedIn;
  bool admin(CommandContext ctx, JsonArgs a) {
    if (hub.me.value == null && s.auth.isSignedIn) hub.loadMe();
    return hub.isAdmin;
  }

  const post = JsonSchema.integer(minimum: 1, description: 'Issue number.');
  const task = JsonSchema.integer(minimum: 1, description: 'Task number.');
  const uuid = JsonSchema.string(format: 'uuid');

  CallbackCommand cmd(
    String id, {
    required String Function(WonkyAppLocalizations l) title,
    required Future<CommandResult> Function(CommandContext ctx, JsonArgs a) run,
    IconData? icon,
    bool undoable = true,
    bool adminOnly = false,
    JsonSchema args = JsonSchema.empty,
    bool palette = false,
  }) => shellCommand(
    id,
    title: title,
    icon: icon,
    run: run,
    undoable: undoable,
    undoTarget: UndoTarget.shell,
    args: args,
    palette: palette,
    category: (l) => l.boardReportName,
    enabled: adminOnly ? admin : (undoable ? writer : null),
  );

  BoardUndoEntry entry(BoardUndoOp op, Map<String, Object?> data) =>
      BoardUndoEntry(op, data);

  Map<String, Object?> labels(BoardPostView p) => {
    'kind': p.kind.name,
    'area': p.area?.name,
    'size': p.size?.name,
  };

  Future<CommandResult> taskStatus(
    CommandContext ctx,
    int number,
    BoardTaskStatus status,
  ) async {
    final before = await repo().getTask(number);
    final keepsClaim = {
      BoardTaskStatus.claimed,
      BoardTaskStatus.inReview,
      BoardTaskStatus.done,
      BoardTaskStatus.shipped,
    }.contains(status);
    // A cleared claim can't come back: undo returns to `published`.
    final previous = before.status == BoardTaskStatus.claimed && !keepsClaim
        ? BoardTaskStatus.published
        : before.status;
    final v = await repo().setTaskStatus(number, status);
    ctx.record(
      entry(BoardUndoOp.setTaskStatus, {
        'task': number,
        'before': previous.name,
        'after': status.name,
      }),
    );
    hub.changed(task: number);
    return CommandResult.ok({'task': number, 'status': v.status.name});
  }

  return [
    // ------------------------------------------------------------ votes
    cmd(
      'shell.board.vote',
      title: (l) => l.cmdBoardVote,
      icon: LucideIcons.thumbsUp,
      args: const JsonSchema.object(
        properties: {
          'postNumber': post,
          'value': JsonSchema.integer(
            minimum: -1,
            maximum: 1,
            description:
                '1 up, -1 down (ideas only: bugs can only be '
                'upvoted), 0 removes the vote.',
          ),
        },
        required: ['postNumber', 'value'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final value = a.integer('value')!;
        final before = hub.myVotes[n] ?? (await repo().getPost(n)).myVote;
        if (before == value) return const CommandResult.cancelled();
        final r = await repo().vote(n, value);
        hub.myVotes[n] = r.myVote;
        ctx.record(
          entry(BoardUndoOp.vote, {
            'post': n,
            'before': before,
            'after': r.myVote,
          }),
        );
        hub.changed(post: n, lists: false);
        return CommandResult.ok({
          'postNumber': n,
          'score': r.score,
          'myVote': r.myVote,
        });
      },
    ),
    // ------------------------------------------------------------ posts
    cmd(
      'shell.board.editPost',
      title: (l) => l.cmdBoardEditPost,
      icon: LucideIcons.pencil,
      args: const JsonSchema.object(
        properties: {
          'postNumber': post,
          'title': JsonSchema.string(minLength: 8, maxLength: 120),
          'body': JsonSchema.string(minLength: 1, maxLength: 10000),
        },
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final p = await repo().getPost(n);
        var title = a.string('title');
        var body = a.string('body');
        if (title == null && body == null) {
          final c = ctx.dialogContext;
          if (c == null || !c.mounted) return const CommandResult.cancelled();
          final r = await showBoardEditPostDialog(
            c,
            s,
            title: p.title,
            body: p.body,
          );
          if (r == null) return const CommandResult.cancelled();
          (title, body) = r;
        }
        title ??= p.title;
        body ??= p.body;
        if (title == p.title && body == p.body) {
          return const CommandResult.cancelled();
        }
        await repo().editPost(n, title, body);
        ctx.record(
          entry(BoardUndoOp.editPost, {
            'post': n,
            'before': {'title': p.title, 'body': p.body},
            'after': {'title': title, 'body': body},
          }),
        );
        hub.changed(post: n);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    cmd(
      'shell.board.deletePost',
      title: (l) => l.cmdBoardDeletePost,
      icon: LucideIcons.trash2,
      args: const JsonSchema.object(
        properties: {'postNumber': post},
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        await repo().deletePost(n);
        ctx.record(entry(BoardUndoOp.deletePost, {'post': n}));
        hub.changed(post: n);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    cmd(
      'shell.board.removeScreenshot',
      title: (l) => l.cmdBoardRemoveScreenshot,
      icon: LucideIcons.imageOff,
      // The bytes are deleted at once (specs/16 §5.3): confirmed, not
      // undoable.
      undoable: false,
      args: const JsonSchema.object(
        properties: {'postNumber': post},
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final bc = ctx.dialogContext;
        if (ctx.source == InvocationSource.ui && bc != null && bc.mounted) {
          final l = WonkyAppLocalizations.of(bc);
          final ok = await confirmDialog(
            bc,
            title: l.cmdBoardRemoveScreenshot,
            description: l.boardRemoveScreenshotHint,
            confirmLabel: l.boardActionRemove,
            destructive: true,
          );
          if (!ok) return const CommandResult.cancelled();
        }
        await repo().removeScreenshot(n);
        hub.changed(post: n, lists: false);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    // --------------------------------------------------------- comments
    cmd(
      'shell.board.comment.add',
      title: (l) => l.cmdBoardComment,
      icon: LucideIcons.messageSquare,
      // Posts only: tasks have no discussion (specs/16 §4.6).
      args: const JsonSchema.object(
        properties: {
          'uuid': uuid,
          'postNumber': post,
          'body': JsonSchema.string(minLength: 1, maxLength: 10000),
        },
        required: ['postNumber', 'body'],
      ),
      run: (ctx, a) async {
        final p = a.integer('postNumber')!;
        final id = switch (a.string('uuid')) {
          final String u => UuidValue.fromString(u),
          _ => s.ids.next(),
        };
        final c = await repo().addComment(
          id,
          postNumber: p,
          body: a.string('body')!,
        );
        hub.commentBodies[c.uuid.uuid] = c.body;
        ctx.record(
          entry(BoardUndoOp.addComment, {'uuid': c.uuid.uuid, 'post': p}),
        );
        hub.changed(post: p, lists: false);
        return CommandResult.ok({'uuid': c.uuid.uuid});
      },
    ),
    cmd(
      'shell.board.comment.edit',
      title: (l) => l.cmdBoardEditComment,
      icon: LucideIcons.pencil,
      args: const JsonSchema.object(
        properties: {
          'uuid': uuid,
          'body': JsonSchema.string(minLength: 1, maxLength: 10000),
          'previousBody': JsonSchema.string(),
          'postNumber': post,
          'taskNumber': task,
        },
        required: ['uuid', 'body'],
      ),
      run: (ctx, a) async {
        final id = a.string('uuid')!;
        final before = a.string('previousBody') ?? hub.commentBodies[id];
        final body = a.string('body')!;
        await repo().editComment(UuidValue.fromString(id), body);
        hub.commentBodies[id] = body;
        // Without the previous text there is nothing to undo to.
        if (before != null && before != body) {
          ctx.record(
            entry(BoardUndoOp.editComment, {
              'uuid': id,
              'before': before,
              'after': body,
              'post': a.integer('postNumber'),
              'task': a.integer('taskNumber'),
            }),
          );
        }
        hub.changed(
          post: a.integer('postNumber'),
          task: a.integer('taskNumber'),
          lists: false,
        );
        return CommandResult.ok({'uuid': id});
      },
    ),
    cmd(
      'shell.board.comment.delete',
      title: (l) => l.cmdBoardDeleteComment,
      icon: LucideIcons.trash2,
      args: const JsonSchema.object(
        properties: {'uuid': uuid, 'postNumber': post, 'taskNumber': task},
        required: ['uuid'],
      ),
      run: (ctx, a) async {
        final id = a.string('uuid')!;
        await repo().deleteComment(UuidValue.fromString(id));
        ctx.record(
          entry(BoardUndoOp.deleteComment, {
            'uuid': id,
            'post': a.integer('postNumber'),
            'task': a.integer('taskNumber'),
          }),
        );
        hub.changed(
          post: a.integer('postNumber'),
          task: a.integer('taskNumber'),
          lists: false,
        );
        return CommandResult.ok({'uuid': id});
      },
    ),
    // ------------------------------------------------------------ flags
    cmd(
      'shell.board.flag',
      title: (l) => l.cmdBoardFlag,
      icon: LucideIcons.flag,
      args: JsonSchema.object(
        properties: {
          'postNumber': post,
          'commentUuid': uuid,
          'reason': JsonSchema.string(
            enumValues: [for (final r in BoardFlagReason.values) r.name],
          ),
          'note': const JsonSchema.string(maxLength: 1000),
        },
      ),
      run: (ctx, a) async {
        final p = a.integer('postNumber');
        final c = a.string('commentUuid');
        if ((p == null) == (c == null)) {
          return const CommandResult.failed(
            'Pass exactly one of postNumber and commentUuid.',
          );
        }
        var reason = switch (a.string('reason')) {
          final String r => BoardFlagReason.values.byName(r),
          _ => null,
        };
        var note = a.string('note');
        if (reason == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) {
            return const CommandResult.cancelled();
          }
          final r = await showBoardFlagDialog(bc);
          if (r == null) return const CommandResult.cancelled();
          (reason, note) = r;
        }
        await repo().flag(
          number: p,
          commentUuid: c == null ? null : UuidValue.fromString(c),
          reason: reason,
          note: note,
        );
        ctx.record(
          entry(BoardUndoOp.flag, {
            'post': p,
            'comment': c,
            'reason': reason.name,
            'note': note,
          }),
        );
        final l = s.l10n;
        if (ctx.source == InvocationSource.ui && l != null) {
          s.toasts.show(l.boardFlagged);
        }
        return CommandResult.ok({'reason': reason.name});
      },
    ),
    // ----------------------------------------------------------- claims
    cmd(
      'shell.board.claim',
      title: (l) => l.cmdBoardClaim,
      icon: LucideIcons.hand,
      args: const JsonSchema.object(
        properties: {'taskNumber': task},
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final t = await repo().claimTask(n);
        ctx.record(entry(BoardUndoOp.claim, {'task': n}));
        await hub.loadMe(force: true);
        hub.changed(task: n);
        return CommandResult.ok({
          'taskNumber': n,
          'claimCode': ?t.claimCode,
          'claimExpiresAt': ?t.claimExpiresAt?.toIso8601String(),
        });
      },
    ),
    cmd(
      'shell.board.release',
      title: (l) => l.cmdBoardRelease,
      icon: LucideIcons.ban,
      args: const JsonSchema.object(
        properties: {'taskNumber': task},
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final before = await repo().getTask(n);
        await repo().releaseTask(n);
        // Undo re-claims only the caller's own claim (an admin release of
        // someone else's claim can't be given back).
        if (before.isMine) {
          ctx.record(entry(BoardUndoOp.release, {'task': n}));
        }
        await hub.loadMe(force: true);
        hub.changed(task: n);
        return CommandResult.ok({'taskNumber': n});
      },
    ),
    cmd(
      'shell.board.copyPrompt',
      title: (l) => l.cmdBoardCopyPrompt,
      icon: LucideIcons.copy,
      undoable: false,
      args: const JsonSchema.object(
        properties: {'taskNumber': task},
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final t = await repo().getTask(a.integer('taskNumber')!);
        // The server sends the prompt to the claimant and admins only.
        if (t.prompt.isEmpty) {
          return const CommandResult.failed(
            'Claim this task to get the prompt.',
          );
        }
        await Clipboard.setData(ClipboardData(text: t.prompt));
        final l = s.l10n;
        if (l != null) s.toasts.show(l.boardPromptCopied);
        return CommandResult.ok({'prompt': t.prompt});
      },
    ),
    cmd(
      'shell.board.copyClaimCode',
      title: (l) => l.cmdBoardCopyClaimCode,
      icon: LucideIcons.copy,
      undoable: false,
      args: const JsonSchema.object(
        properties: {
          'taskNumber': task,
          'lines': JsonSchema.boolean(
            description: 'Copy the two PR description lines instead.',
          ),
        },
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final t = await repo().getTask(n);
        final code = t.claimCode;
        if (code == null) {
          return const CommandResult.failed('You have not claimed this task.');
        }
        final text = a.boolean('lines') == true ? boardPrLines(n, code) : code;
        await Clipboard.setData(ClipboardData(text: text));
        final l = s.l10n;
        if (l != null) s.toasts.show(l.boardCopied);
        return CommandResult.ok({'text': text});
      },
    ),
    // ------------------------------------------------------------ admin
    cmd(
      'shell.board.admin.moderate',
      title: (l) => l.cmdBoardModerate,
      icon: LucideIcons.shieldCheck,
      adminOnly: true,
      args: JsonSchema.object(
        properties: {
          'postNumber': post,
          'commentUuid': uuid,
          'action': JsonSchema.string(
            enumValues: [for (final x in BoardModerationAction.values) x.name],
          ),
          'reason': const JsonSchema.string(maxLength: 1000),
        },
        required: const ['action'],
      ),
      run: (ctx, a) async {
        final p = a.integer('postNumber');
        final c = a.string('commentUuid');
        if ((p == null) == (c == null)) {
          return const CommandResult.failed(
            'Pass exactly one of postNumber and commentUuid.',
          );
        }
        final action = BoardModerationAction.values.byName(a.string('action')!);
        var reason = a.string('reason');
        final before = p == null ? null : await repo().getPost(p);
        if (action == BoardModerationAction.remove && reason == null) {
          final bc = ctx.dialogContext;
          if (bc != null && bc.mounted) {
            final r = await showBoardRemoveDialog(
              bc,
              initial: boardRemoveReasonFor(before),
            );
            if (r == null) return const CommandResult.cancelled();
            reason = r;
          }
        }
        String? inverse;
        String? inverseReason;
        if (p != null && before != null) {
          await repo().moderatePost(p, action, reason: reason);
          // Undo writes the previous moderation state back.
          if (action != BoardModerationAction.removeScreenshot &&
              action != BoardModerationAction.markChecked) {
            inverse = switch (before.moderation) {
              BoardModeration.visible => BoardModerationAction.approve.name,
              BoardModeration.removed => BoardModerationAction.remove.name,
              _ => BoardModerationAction.hold.name,
            };
            inverseReason = before.moderationReason;
            if (inverse == action.name) inverse = null;
          }
        } else {
          await repo().moderateComment(
            UuidValue.fromString(c!),
            action,
            reason: reason,
          );
          inverse = switch (action) {
            BoardModerationAction.approve => 'hold',
            BoardModerationAction.hold => 'approve',
            BoardModerationAction.remove => 'restore',
            BoardModerationAction.restore => 'remove',
            _ => null,
          };
        }
        if (inverse != null) {
          ctx.record(
            entry(BoardUndoOp.moderate, {
              'post': p,
              'comment': c,
              'action': action.name,
              'reason': reason,
              'inverse': inverse,
              'inverseReason': inverseReason,
            }),
          );
        }
        hub.changed(post: p);
        return CommandResult.ok({'action': action.name});
      },
    ),
    cmd(
      'shell.board.admin.setLabels',
      title: (l) => l.cmdBoardSetLabels,
      icon: LucideIcons.tags,
      adminOnly: true,
      args: JsonSchema.object(
        properties: {
          'postNumber': post,
          'kind': JsonSchema.string(
            enumValues: [for (final x in BoardPostKind.values) x.name],
          ),
          'area': JsonSchema.nullable(
            JsonSchema.string(
              enumValues: [for (final x in BoardArea.values) x.name],
            ),
          ),
          'size': JsonSchema.nullable(
            JsonSchema.string(
              enumValues: [for (final x in BoardSize.values) x.name],
            ),
          ),
        },
        required: const ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final p = await repo().getPost(n);
        final v = a.values;
        var kind = p.kind;
        var area = p.area;
        var size = p.size;
        if (!v.containsKey('kind') &&
            !v.containsKey('area') &&
            !v.containsKey('size')) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          final r = await showBoardLabelsDialog(
            bc,
            kind: kind,
            area: area,
            size: size,
          );
          if (r == null) return const CommandResult.cancelled();
          (kind, area, size) = r;
        } else {
          if (a.string('kind') case final k?) {
            kind = BoardPostKind.values.byName(k);
          }
          if (v.containsKey('area')) {
            area = switch (a.string('area')) {
              final String x => BoardArea.values.byName(x),
              _ => null,
            };
          }
          if (v.containsKey('size')) {
            size = switch (a.string('size')) {
              final String x => BoardSize.values.byName(x),
              _ => null,
            };
          }
        }
        final after = await repo().setLabels(n, kind, area, size);
        ctx.record(
          entry(BoardUndoOp.setLabels, {
            'post': n,
            'before': labels(p),
            'after': labels(after),
          }),
        );
        hub.changed(post: n);
        return CommandResult.ok(labels(after));
      },
    ),
    cmd(
      'shell.board.admin.editPost',
      title: (l) => l.cmdBoardAdminEdit,
      icon: LucideIcons.pencil,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'postNumber': post,
          'title': JsonSchema.string(minLength: 1, maxLength: 120),
          'body': JsonSchema.string(minLength: 1, maxLength: 10000),
          'approve': JsonSchema.boolean(
            description: 'Also approve a held issue (Edit and approve).',
          ),
        },
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final p = await repo().getPost(n);
        var title = a.string('title');
        var body = a.string('body');
        if (title == null && body == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          final r = await showBoardEditPostDialog(
            bc,
            s,
            title: p.title,
            body: p.body,
            moderator: true,
          );
          if (r == null) return const CommandResult.cancelled();
          (title, body) = r;
        }
        title ??= p.title;
        body ??= p.body;
        await repo().adminEditPost(n, title, body);
        ctx.record(
          entry(BoardUndoOp.adminEdit, {
            'post': n,
            'before': {'title': p.title, 'body': p.body},
            'after': {'title': title, 'body': body},
          }),
        );
        if (a.boolean('approve') == true &&
            p.moderation != BoardModeration.visible) {
          await repo().moderatePost(n, BoardModerationAction.approve);
          ctx.record(
            entry(BoardUndoOp.moderate, {
              'post': n,
              'action': 'approve',
              'inverse': p.moderation == BoardModeration.removed
                  ? 'remove'
                  : 'hold',
              'inverseReason': p.moderationReason,
            }),
          );
        }
        hub.changed(post: n);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    cmd(
      'shell.board.admin.applySuggestedTitle',
      title: (l) => l.cmdBoardApplyTitle,
      icon: LucideIcons.sparkles,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {'postNumber': post},
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final p = await repo().getPost(n);
        final v = await repo().applySuggestedTitle(n);
        ctx.record(
          entry(BoardUndoOp.adminEdit, {
            'post': n,
            'before': {'title': p.title, 'body': p.body},
            'after': {'title': v.title, 'body': v.body},
          }),
        );
        hub.changed(post: n);
        return CommandResult.ok({'title': v.title});
      },
    ),
    cmd(
      'shell.board.admin.dismissDuplicate',
      title: (l) => l.cmdBoardNotDuplicate,
      icon: LucideIcons.x,
      adminOnly: true,
      // The server has no call that sets a duplicate hint again.
      undoable: false,
      args: const JsonSchema.object(
        properties: {'postNumber': post},
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        await repo().dismissDuplicateHint(n);
        hub.changed(post: n);
        return const CommandResult.ok();
      },
    ),
    cmd(
      'shell.board.admin.merge',
      title: (l) => l.cmdBoardMerge,
      icon: LucideIcons.merge,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'source': JsonSchema.integer(
            minimum: 1,
            description: 'The duplicate issue.',
          ),
          'target': JsonSchema.integer(
            minimum: 1,
            description: 'The issue that remains.',
          ),
        },
        required: ['source'],
      ),
      run: (ctx, a) async {
        final source = a.integer('source')!;
        var target = a.integer('target');
        if (target == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          target = await showBoardMergeDialog(bc, source);
          if (target == null) return const CommandResult.cancelled();
        }
        await repo().merge(source, target);
        ctx.record(
          entry(BoardUndoOp.merge, {'source': source, 'target': target}),
        );
        hub.changed(post: source);
        hub.changed(post: target);
        return CommandResult.ok({'source': source, 'target': target});
      },
    ),
    cmd(
      'shell.board.admin.decline',
      title: (l) => l.cmdBoardDecline,
      icon: LucideIcons.ban,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'postNumber': post,
          'reason': JsonSchema.string(minLength: 1, maxLength: 1000),
        },
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        var reason = a.string('reason');
        if (reason == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          reason = await showBoardDeclineDialog(bc);
          if (reason == null) return const CommandResult.cancelled();
        }
        await repo().decline(n, reason);
        ctx.record(entry(BoardUndoOp.decline, {'post': n, 'reason': reason}));
        hub.changed(post: n);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    cmd(
      'shell.board.admin.reopen',
      title: (l) => l.cmdBoardReopen,
      icon: LucideIcons.rotateCcw,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {'postNumber': post},
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final p = await repo().getPost(n);
        await repo().reopen(n);
        if (p.status == BoardPostStatus.declined) {
          ctx.record(
            entry(BoardUndoOp.reopen, {
              'post': n,
              'reason': p.declineReason ?? '',
            }),
          );
        }
        hub.changed(post: n);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    cmd(
      'shell.board.admin.unmerge',
      title: (l) => l.cmdBoardUnmerge,
      icon: LucideIcons.split,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {'postNumber': post},
        required: ['postNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('postNumber')!;
        final p = await repo().getPost(n);
        final target = p.duplicateOfNumber;
        if (target == null) return const CommandResult.cancelled();
        await repo().unmerge(n);
        ctx.record(entry(BoardUndoOp.unmerge, {'source': n, 'target': target}));
        hub.changed(post: n);
        hub.changed(post: target);
        return CommandResult.ok({'postNumber': n});
      },
    ),
    cmd(
      'shell.board.admin.block',
      title: (l) => l.cmdBoardBlock,
      icon: LucideIcons.userX,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'userId': JsonSchema.integer(minimum: 1),
          'postNumber': JsonSchema.integer(
            minimum: 1,
            description: 'Blocks the author of this issue.',
          ),
          'reason': JsonSchema.string(minLength: 1, maxLength: 1000),
        },
      ),
      run: (ctx, a) async {
        var user = a.integer('userId');
        String? name;
        if (user == null) {
          final n = a.integer('postNumber');
          if (n == null) {
            return const CommandResult.failed('Pass userId or postNumber.');
          }
          final author = (await repo().getPost(n)).author;
          if (author == null) return const CommandResult.cancelled();
          user = author.id;
          name = author.displayName;
        }
        var reason = a.string('reason');
        if (reason == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          reason = await showBoardBlockDialog(bc, name);
          if (reason == null) return const CommandResult.cancelled();
        }
        await repo().blockUser(user, reason);
        ctx.record(entry(BoardUndoOp.block, {'user': user, 'reason': reason}));
        hub.changed();
        return CommandResult.ok({'userId': user});
      },
    ),
    cmd(
      'shell.board.admin.createTask',
      title: (l) => l.cmdBoardCreateTask,
      icon: LucideIcons.listPlus,
      adminOnly: true,
      args: JsonSchema.object(
        properties: {
          'postNumbers': const JsonSchema.array(
            JsonSchema.integer(minimum: 1),
            minItems: 1,
          ),
          'title': const JsonSchema.string(minLength: 1, maxLength: 120),
          'area': JsonSchema.string(
            enumValues: [for (final x in BoardArea.values) x.name],
          ),
          'size': JsonSchema.string(
            enumValues: [for (final x in BoardSize.values) x.name],
          ),
        },
        required: const ['postNumbers'],
      ),
      run: (ctx, a) async {
        final numbers = [
          for (final x in a.values['postNumbers']! as List) (x as num).toInt(),
        ];
        var title = a.string('title');
        var area = switch (a.string('area')) {
          final String x => BoardArea.values.byName(x),
          _ => null,
        };
        var size = switch (a.string('size')) {
          final String x => BoardSize.values.byName(x),
          _ => null,
        };
        if (title == null || area == null || size == null) {
          // Defaults from the first post (Select for building, §9.3).
          final first = await repo().getPost(numbers.first);
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) {
            title ??= first.title;
            area ??= first.area ?? BoardArea.suite;
            size ??= first.size ?? BoardSize.small;
          } else {
            final r = await showBoardTaskDialog(
              bc,
              count: numbers.length,
              title: title ?? first.title,
              area: area ?? first.area ?? BoardArea.suite,
              size: size ?? first.size ?? BoardSize.small,
            );
            if (r == null) return const CommandResult.cancelled();
            (title, area, size) = r;
          }
        }
        final t = await repo().createTask(numbers, title, area, size);
        ctx.record(
          entry(BoardUndoOp.createTask, {
            'task': t.number,
            'posts': numbers,
            'title': title,
            'area': area.name,
            'size': size.name,
          }),
        );
        hub.changed(task: t.number);
        return CommandResult.ok({'taskNumber': t.number});
      },
    ),
    cmd(
      'shell.board.admin.updateTask',
      title: (l) => l.cmdBoardEditTask,
      icon: LucideIcons.pencil,
      adminOnly: true,
      args: JsonSchema.object(
        properties: {
          'taskNumber': task,
          'title': const JsonSchema.string(minLength: 1, maxLength: 120),
          'area': JsonSchema.string(
            enumValues: [for (final x in BoardArea.values) x.name],
          ),
          'size': JsonSchema.string(
            enumValues: [for (final x in BoardSize.values) x.name],
          ),
        },
        required: const ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final t = await repo().getTask(n);
        var title = a.string('title');
        var area = switch (a.string('area')) {
          final String x => BoardArea.values.byName(x),
          _ => null,
        };
        var size = switch (a.string('size')) {
          final String x => BoardSize.values.byName(x),
          _ => null,
        };
        if (title == null && area == null && size == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          final r = await showBoardTaskDialog(
            bc,
            title: t.title,
            area: t.area,
            size: t.size,
          );
          if (r == null) return const CommandResult.cancelled();
          (title, area, size) = r;
        }
        title ??= t.title;
        area ??= t.area;
        size ??= t.size;
        await repo().updateTask(n, title, area, size);
        ctx.record(
          entry(BoardUndoOp.updateTask, {
            'task': n,
            'before': {
              'title': t.title,
              'area': t.area.name,
              'size': t.size.name,
            },
            'after': {'title': title, 'area': area.name, 'size': size.name},
          }),
        );
        hub.changed(task: n);
        return CommandResult.ok({'taskNumber': n});
      },
    ),
    cmd(
      'shell.board.admin.setTaskPosts',
      title: (l) => l.cmdBoardSetTaskPosts,
      icon: LucideIcons.listChecks,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'taskNumber': task,
          'postNumbers': JsonSchema.array(JsonSchema.integer(minimum: 1)),
          'add': JsonSchema.array(JsonSchema.integer(minimum: 1)),
          'remove': JsonSchema.array(JsonSchema.integer(minimum: 1)),
        },
      ),
      run: (ctx, a) async {
        List<int> ints(String k) => [
          for (final x in (a.values[k] as List?) ?? const [])
            (x as num).toInt(),
        ];
        var n = a.integer('taskNumber');
        if (n == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          final open = await repo().listTasks(const [
            BoardTaskStatus.draft,
            BoardTaskStatus.published,
            BoardTaskStatus.claimed,
          ], limit: 50);
          if (!bc.mounted) return const CommandResult.cancelled();
          n = await showBoardPickTaskDialog(bc, open.items);
          if (n == null) return const CommandResult.cancelled();
        }
        final t = await repo().getTask(n);
        final before = [for (final p in t.posts) p.number];
        final after = a.values.containsKey('postNumbers')
            ? ints('postNumbers')
            : <int>{
                for (final p in [...before, ...ints('add')])
                  if (!ints('remove').contains(p)) p,
              }.toList();
        await repo().setTaskPosts(n, after);
        ctx.record(
          entry(BoardUndoOp.setTaskPosts, {
            'task': n,
            'before': before,
            'after': after,
          }),
        );
        hub.changed(task: n);
        return CommandResult.ok({'taskNumber': n, 'postNumbers': after});
      },
    ),
    cmd(
      'shell.board.admin.mergeTasks',
      title: (l) => l.cmdBoardMergeTasks,
      icon: LucideIcons.merge,
      adminOnly: true,
      args: JsonSchema.object(
        properties: {
          'taskNumbers': const JsonSchema.array(
            JsonSchema.integer(minimum: 1),
            minItems: 2,
          ),
          'title': const JsonSchema.string(minLength: 1, maxLength: 120),
          'area': JsonSchema.string(
            enumValues: [for (final x in BoardArea.values) x.name],
          ),
          'size': JsonSchema.string(
            enumValues: [for (final x in BoardSize.values) x.name],
          ),
        },
        required: const ['taskNumbers'],
      ),
      run: (ctx, a) async {
        final numbers = {
          for (final x in a.values['taskNumbers']! as List) (x as num).toInt(),
        }.toList()..sort();
        var title = a.string('title');
        var area = switch (a.string('area')) {
          final String x => BoardArea.values.byName(x),
          _ => null,
        };
        var size = switch (a.string('size')) {
          final String x => BoardSize.values.byName(x),
          _ => null,
        };
        if (title == null || area == null || size == null) {
          // Defaults from the oldest task, the one that remains (§9.3).
          final first = await repo().getTask(numbers.first);
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) {
            title ??= first.title;
            area ??= first.area;
            size ??= first.size;
          } else {
            final r = await showBoardTaskDialog(
              bc,
              mergeCount: numbers.length,
              title: title ?? first.title,
              area: area ?? first.area,
              size: size ?? first.size,
            );
            if (r == null) return const CommandResult.cancelled();
            (title, area, size) = r;
          }
        }
        final t = await repo().mergeTasks(numbers, title, area, size);
        ctx.record(
          entry(BoardUndoOp.mergeTasks, {
            'task': t.number,
            'tasks': numbers,
            'title': title,
            'area': area.name,
            'size': size.name,
          }),
        );
        for (final n in numbers) {
          hub.changed(task: n);
        }
        return CommandResult.ok({'taskNumber': t.number});
      },
    ),
    cmd(
      'shell.board.admin.regeneratePrompt',
      title: (l) => l.cmdBoardRegeneratePrompt,
      icon: LucideIcons.refreshCw,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {'taskNumber': task},
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final before = await repo().getTask(n);
        // The server writes the prompt in the background (specs/16 §10.1):
        // the view comes back pending, and the body arrives live.
        final v = await repo().regeneratePrompt(n);
        ctx.record(
          entry(BoardUndoOp.regeneratePrompt, {
            'task': n,
            'before': before.promptBody,
          }),
        );
        hub.changed(task: n, lists: false);
        return CommandResult.ok({
          'promptBody': v.promptBody,
          'promptPending': v.promptPending,
        });
      },
    ),
    cmd(
      'shell.board.admin.setPrompt',
      title: (l) => l.cmdBoardEditPrompt,
      icon: LucideIcons.squarePen,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'taskNumber': task,
          'body': JsonSchema.string(minLength: 1, maxLength: 50000),
        },
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final t = await repo().getTask(n);
        var body = a.string('body');
        var publish = false;
        if (body == null) {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          final r = await showPromptEditor(bc, s, task: t);
          if (r == null) return const CommandResult.cancelled();
          body = r.body;
          publish = r.publish;
        }
        if (body != t.promptBody) {
          await repo().setPrompt(n, body);
          ctx.record(
            entry(BoardUndoOp.setPrompt, {
              'task': n,
              'before': t.promptBody,
              'after': body,
            }),
          );
        }
        hub.changed(task: n, lists: false);
        return CommandResult.ok({'taskNumber': n, 'publish': publish});
      },
    ),
    cmd(
      'shell.board.admin.publishTask',
      title: (l) => l.cmdBoardPublishTask,
      icon: LucideIcons.send,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {'taskNumber': task},
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        await repo().publishTask(n);
        ctx.record(
          entry(BoardUndoOp.setTaskStatus, {
            'task': n,
            'before': BoardTaskStatus.draft.name,
            'after': BoardTaskStatus.published.name,
          }),
        );
        hub.changed(task: n);
        return CommandResult.ok({'taskNumber': n});
      },
    ),
    cmd(
      'shell.board.admin.linkPullRequest',
      title: (l) => l.cmdBoardLinkPr,
      icon: LucideIcons.gitPullRequest,
      adminOnly: true,
      args: const JsonSchema.object(
        properties: {
          'taskNumber': task,
          'url': JsonSchema.nullable(
            JsonSchema.string(
              description:
                  'https://github.com/<repository>/pull/<n>; empty '
                  'or null unlinks.',
            ),
          ),
        },
        required: ['taskNumber'],
      ),
      run: (ctx, a) async {
        final n = a.integer('taskNumber')!;
        final t = await repo().getTask(n);
        String? url;
        if (a.values.containsKey('url')) {
          url = a.string('url');
        } else {
          final bc = ctx.dialogContext;
          if (bc == null || !bc.mounted) return const CommandResult.cancelled();
          url = await showBoardLinkPrDialog(bc, t.pullRequestUrl);
          if (url == null) return const CommandResult.cancelled();
        }
        if (url != null && url.trim().isEmpty) url = null;
        final v = await repo().linkPullRequest(n, url);
        ctx.record(
          entry(BoardUndoOp.linkPullRequest, {
            'task': n,
            'before': t.pullRequestUrl,
            'after': v.pullRequestUrl,
          }),
        );
        hub.changed(task: n);
        return CommandResult.ok({'pullRequestUrl': v.pullRequestUrl});
      },
    ),
    for (final (id, status, title, icon) in [
      (
        'shell.board.admin.markDone',
        BoardTaskStatus.done,
        (WonkyAppLocalizations l) => l.cmdBoardMarkDone,
        LucideIcons.circleCheck,
      ),
      (
        'shell.board.admin.markShipped',
        BoardTaskStatus.shipped,
        (WonkyAppLocalizations l) => l.cmdBoardMarkShipped,
        LucideIcons.rocket,
      ),
      (
        'shell.board.admin.cancelTask',
        BoardTaskStatus.cancelled,
        (WonkyAppLocalizations l) => l.cmdBoardCancelTask,
        LucideIcons.circleX,
      ),
    ])
      cmd(
        id,
        title: title,
        icon: icon,
        adminOnly: true,
        args: const JsonSchema.object(
          properties: {'taskNumber': task},
          required: ['taskNumber'],
        ),
        run: (ctx, a) => taskStatus(ctx, a.integer('taskNumber')!, status),
      ),
    cmd(
      'shell.board.admin.suggestBundles',
      title: (l) => l.cmdBoardSuggestBundles,
      icon: LucideIcons.sparkles,
      adminOnly: true,
      undoable: false,
      run: (ctx, a) async {
        final r = await repo().suggestBundles();
        hub.changed();
        return CommandResult.ok({'suggestions': r.length});
      },
    ),
    cmd(
      'shell.board.admin.dismissSuggestion',
      title: (l) => l.cmdBoardDismissSuggestion,
      icon: LucideIcons.x,
      adminOnly: true,
      // No server call restores a dismissed suggestion.
      undoable: false,
      args: const JsonSchema.object(
        properties: {'id': JsonSchema.integer(minimum: 1)},
        required: ['id'],
      ),
      run: (ctx, a) async {
        await repo().dismissSuggestion(a.integer('id')!);
        hub.changed();
        return const CommandResult.ok();
      },
    ),
  ];
}
