import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../../l10n/write_l10n.dart';
import '../editor/controller/editor_types.dart';
import '../offline/write_offline.dart';
import 'write_document_api.dart';
import 'write_document_session.dart';

const _ok = CommandResult.ok();

/// Write's collaboration commands (Write 08 §7): comments, suggestions,
/// presence and history. Shared comment/version actions stay the suite's
/// `shell.comments.*` / `shell.versions.*`; these add the Write-specific
/// ones. Register them from `WriteAppConfig.commands`.
///
/// Also installs the offline store (suite 12 §1) of the signed-in user when
/// the shell runs against a server.
List<Command<CommandArgs>> writeCollabCommands(ShellServices services) {
  if (services.client != null) WriteOffline.install(services);
  WriteDocumentSession? session(CommandContext ctx) =>
      WriteDocumentSession.of(ctx);
  bool loaded(CommandContext ctx) => session(ctx)?.isLoaded ?? false;
  CommandResult nothing() =>
      CommandResult.failed(writeL10nOf(services).commandToastNothingToDo);

  const threadArgs = JsonSchema.object(
    properties: {'threadUuid': JsonSchema.string(format: 'uuid')},
    required: ['threadUuid'],
  );
  const idsArgs = JsonSchema.object(
    properties: {
      'suggestionIds': JsonSchema.array(
        JsonSchema.string(),
        description:
            'Suggestion ids; default: the active suggestion or the one at '
            'the caret.',
      ),
    },
  );
  const authorArgs = JsonSchema.object(
    properties: {
      'authorUuid': JsonSchema.string(
        format: 'uuid',
        description: 'Only suggestions by this user.',
      ),
    },
  );
  const sessionArgs = JsonSchema.object(
    properties: {'sessionId': JsonSchema.string(minLength: 1)},
    required: ['sessionId'],
  );

  Set<String> ids(WriteDocumentSession s, JsonArgs a) {
    final raw = a.values['suggestionIds'];
    if (raw is List && raw.isNotEmpty) {
      return {for (final v in raw) '$v'};
    }
    final active = s.suggestions.activeId;
    if (active != null) return {active};
    final caret = s.editor.selection?.anchor;
    final at = caret == null ? null : s.suggestions.idAt(caret);
    return {?at};
  }

  return [
    // ---- Offline (suite 12) ----
    CallbackCommand(
      id: 'write.offline.simulate',
      title: (c) => writeL10n(c).cmdOfflineSimulate,
      icon: LucideIcons.cloudOff,
      category: (c) => writeL10n(c).categoryDeveloper,
      argsSchema: const JsonSchema.object(
        properties: {
          'offline': JsonSchema.boolean(
            description:
                'true = disconnect, false = reconnect; default: toggle.',
          ),
        },
      ),
      checked: (_, _) => services.connectivity.forcedOffline,
      run: (ctx, a) async {
        final value =
            a.boolean('offline') ?? !services.connectivity.forcedOffline;
        services.connectivity.forceOffline(value);
        await services.prefs.setDevice(simulateOfflinePref, value);
        return CommandResult.ok({'offline': value});
      },
    ),
    // ---- Comments ----
    CallbackCommand(
      id: 'write.comments.addDocumentComment',
      title: (c) => writeL10n(c).cmdCommentsAddDocumentComment,
      icon: LucideIcons.messageSquareText,
      requiredRole: Role.commenter,
      category: (c) => writeL10n(c).categoryComments,
      enabled: (ctx, _) => loaded(ctx) && services.comments.value != null,
      run: (ctx, _) async {
        session(ctx)!.comments.startDocumentComment();
        return _ok;
      },
    ),
    CallbackCommand(
      id: 'write.comments.activate',
      title: (c) => writeL10n(c).cmdCommentsActivate,
      argsSchema: threadArgs,
      showInPalette: false,
      category: (c) => writeL10n(c).categoryComments,
      enabled: (ctx, _) => loaded(ctx),
      run: (ctx, a) async {
        session(ctx)!.comments.activate(a.requireString('threadUuid'));
        return _ok;
      },
    ),
    for (final previous in [false, true])
      CallbackCommand(
        id: previous ? 'write.comments.previous' : 'write.comments.next',
        title: (c) => previous
            ? writeL10n(c).cmdCommentsPrevious
            : writeL10n(c).cmdCommentsNext,
        icon: previous ? LucideIcons.chevronUp : LucideIcons.chevronDown,
        defaultBindings: [
          KeyBinding(previous ? 'P' : 'N', mod: true, alt: true),
        ],
        keyScope: KeyScope.editor,
        category: (c) => writeL10n(c).categoryComments,
        enabled: (ctx, _) =>
            loaded(ctx) &&
            session(ctx)!.comments.anchoredOpenThreads.isNotEmpty,
        run: (ctx, _) async =>
            session(ctx)!.comments.next(previous: previous) ? _ok : nothing(),
      ),
    CallbackCommand(
      id: 'write.comments.reattach',
      title: (c) => writeL10n(c).cmdCommentsReattach,
      argsSchema: threadArgs,
      requiredRole: Role.editor,
      isUndoable: true,
      showInPalette: false,
      category: (c) => writeL10n(c).categoryComments,
      enabled: (ctx, _) =>
          loaded(ctx) && session(ctx)!.comments.selectionRange() != null,
      run: (ctx, a) async =>
          session(ctx)!.comments.reattach(a.requireString('threadUuid'))
          ? _ok
          : nothing(),
    ),
    CallbackCommand(
      id: 'write.comments.deleteThread',
      title: (c) => writeL10n(c).cmdCommentsDeleteThread,
      argsSchema: threadArgs,
      requiredRole: Role.commenter,
      showInPalette: false,
      category: (c) => writeL10n(c).categoryComments,
      enabled: (ctx, _) => loaded(ctx) && services.comments.value != null,
      run: (ctx, a) => services.dispatcher.invoke(
        'shell.comments.delete',
        args: {'threadUuid': a.requireString('threadUuid')},
        source: ctx.source,
        context: ctx.buildContext,
      ),
    ),

    // ---- Suggestions ----
    CallbackCommand(
      id: 'write.suggestions.accept',
      title: (c) => writeL10n(c).cmdSuggestionsAccept,
      icon: LucideIcons.check,
      argsSchema: idsArgs,
      requiredRole: Role.editor,
      isUndoable: true,
      category: (c) => writeL10n(c).categorySuggestions,
      enabled: (ctx, a) => loaded(ctx) && ids(session(ctx)!, a).isNotEmpty,
      run: (ctx, a) async {
        final s = session(ctx)!;
        return s.suggestions.accept(ids(s, a)) ? _ok : nothing();
      },
    ),
    CallbackCommand(
      id: 'write.suggestions.reject',
      title: (c) => writeL10n(c).cmdSuggestionsReject,
      icon: LucideIcons.x,
      argsSchema: idsArgs,
      requiredRole: Role.commenter,
      isUndoable: true,
      category: (c) => writeL10n(c).categorySuggestions,
      enabled: (ctx, a) {
        final s = session(ctx);
        if (s == null || !s.isLoaded) return false;
        final selected = ids(s, a);
        return selected.isNotEmpty &&
            selected.every((id) {
              final info = s.suggestions.byId(id);
              return info != null && s.suggestions.canReject(info);
            });
      },
      run: (ctx, a) async {
        final s = session(ctx)!;
        return s.suggestions.reject(ids(s, a)) ? _ok : nothing();
      },
    ),
    for (final accept in [true, false])
      CallbackCommand(
        id: accept
            ? 'write.suggestions.acceptAll'
            : 'write.suggestions.rejectAll',
        title: (c) => accept
            ? writeL10n(c).cmdSuggestionsAcceptAll
            : writeL10n(c).cmdSuggestionsRejectAll,
        icon: accept ? LucideIcons.checkCheck : LucideIcons.listX,
        argsSchema: authorArgs,
        requiredRole: Role.editor,
        isUndoable: true,
        category: (c) => writeL10n(c).categorySuggestions,
        enabled: (ctx, a) =>
            loaded(ctx) &&
            session(
                  ctx,
                )!.suggestions.count(authorUuid: a.string('authorUuid')) >
                0,
        run: (ctx, a) async {
          final c = session(ctx)!.suggestions;
          final author = a.string('authorUuid');
          final ok = accept
              ? c.acceptAll(authorUuid: author)
              : c.rejectAll(authorUuid: author);
          return ok ? _ok : nothing();
        },
      ),
    for (final previous in [false, true])
      CallbackCommand(
        id: previous ? 'write.suggestions.previous' : 'write.suggestions.next',
        title: (c) => previous
            ? writeL10n(c).cmdSuggestionsPrevious
            : writeL10n(c).cmdSuggestionsNext,
        category: (c) => writeL10n(c).categorySuggestions,
        enabled: (ctx, _) =>
            loaded(ctx) && session(ctx)!.suggestions.pending.isNotEmpty,
        run: (ctx, _) async =>
            session(ctx)!.suggestions.next(previous: previous)
            ? _ok
            : nothing(),
      ),
    CallbackCommand(
      id: 'write.mode.suggest',
      title: (c) => writeL10n(c).cmdModeSuggest,
      icon: LucideIcons.pencilLine,
      requiredRole: Role.commenter,
      category: (c) => writeL10n(c).categoryView,
      showInPalette: false,
      enabled: (ctx, _) => loaded(ctx),
      checked: (ctx, _) => session(ctx)?.editor.mode == EditorMode.suggesting,
      run: (ctx, _) async {
        final s = session(ctx)!;
        s.setMode(
          s.editor.mode == EditorMode.suggesting && s.currentRole.canEdit
              ? EditorMode.editing
              : EditorMode.suggesting,
        );
        return _ok;
      },
    ),

    // ---- Presence ----
    CallbackCommand(
      id: 'write.presence.jumpTo',
      title: (c) => writeL10n(c).cmdPresenceJumpTo,
      argsSchema: sessionArgs,
      showInPalette: false,
      category: (c) => writeL10n(c).categoryCollaboration,
      enabled: (ctx, _) => loaded(ctx),
      run: (ctx, a) async =>
          session(ctx)!.presence.reveal(a.requireString('sessionId'))
          ? _ok
          : CommandResult.failed(
              writeL10nOf(services).commandToastNoCollaboratorCursor,
            ),
    ),
    CallbackCommand(
      id: 'write.presence.follow',
      title: (c) => writeL10n(c).cmdPresenceFollow,
      argsSchema: sessionArgs,
      showInPalette: false,
      category: (c) => writeL10n(c).categoryCollaboration,
      enabled: (ctx, _) => loaded(ctx),
      run: (ctx, a) async {
        session(ctx)!.presence.follow(a.requireString('sessionId'));
        return _ok;
      },
    ),
    CallbackCommand(
      id: 'write.presence.unfollow',
      title: (c) => writeL10n(c).cmdPresenceUnfollow,
      category: (c) => writeL10n(c).categoryCollaboration,
      enabled: (ctx, _) => session(ctx)?.presence.following != null,
      run: (ctx, _) async {
        session(ctx)!.presence.unfollow();
        return _ok;
      },
    ),

    // ---- History ----
    CallbackCommand(
      id: 'write.history.open',
      title: (c) => writeL10n(c).cmdHistoryOpen,
      icon: LucideIcons.history,
      requiredRole: Role.editor,
      category: (c) => writeL10n(c).categoryVersionHistory,
      argsSchema: const JsonSchema.object(
        properties: {'versionId': JsonSchema.integer()},
      ),
      enabled: (ctx, _) => loaded(ctx) && services.connectivity.online,
      run: (ctx, a) async {
        final s = session(ctx)!;
        final v = a.integer('versionId');
        services.router.go(
          '${services.config.itemPath(s.itemUuid.uuid)}/history'
          '${v == null ? '' : '?version=$v'}',
        );
        return _ok;
      },
    ),
    CallbackCommand(
      id: 'write.history.nameCurrentVersion',
      title: (c) => writeL10n(c).cmdHistoryNameCurrentVersion,
      requiredRole: Role.editor,
      category: (c) => writeL10n(c).categoryVersionHistory,
      argsSchema: const JsonSchema.object(
        properties: {'name': JsonSchema.string(minLength: 1, maxLength: 200)},
      ),
      run: (ctx, a) => services.dispatcher.invoke(
        'shell.versions.nameCurrent',
        args: {'name': ?a.string('name')},
        source: ctx.source,
        context: ctx.buildContext,
      ),
    ),
    CallbackCommand(
      id: 'write.history.restore',
      title: (c) => writeL10n(c).cmdHistoryRestore,
      requiredRole: Role.editor,
      category: (c) => writeL10n(c).categoryVersionHistory,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'versionId': JsonSchema.integer(),
          'confirmed': JsonSchema.boolean(),
        },
        required: ['versionId'],
      ),
      run: (ctx, a) => services.dispatcher.invoke(
        'shell.versions.restore',
        args: a.values,
        source: ctx.source,
        context: ctx.buildContext,
      ),
    ),
    CallbackCommand(
      id: 'write.history.copyVersion',
      title: (c) => writeL10n(c).cmdHistoryCopyVersion,
      requiredRole: Role.editor,
      category: (c) => writeL10n(c).categoryVersionHistory,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'versionId': JsonSchema.integer(),
          'name': JsonSchema.string(minLength: 1, maxLength: 255),
        },
        required: ['versionId', 'name'],
      ),
      run: (ctx, a) async {
        final item = services.currentItem.value;
        final doc = item?.contentRef;
        final client = services.client;
        if (doc == null || client == null) return nothing();
        final copy = await ServerWriteDocumentApi(client).copyVersion(
          doc,
          a.integer('versionId')!,
          a.requireString('name'),
          parentUuid: item!.parentUuid,
        );
        return CommandResult.ok({'uuid': copy.uuid.uuid});
      },
    ),

    // ---- Sync ----
    CallbackCommand(
      id: 'write.sync.retry',
      title: (c) => writeL10n(c).cmdSyncRetry,
      icon: LucideIcons.refreshCw,
      category: (c) => writeL10n(c).categoryFile,
      enabled: (ctx, _) => session(ctx)?.sync != null,
      run: (ctx, _) async {
        await session(ctx)!.retry();
        return _ok;
      },
    ),
  ];
}
