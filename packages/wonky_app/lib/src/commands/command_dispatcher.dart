import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_core/wonky_core.dart';

import '../shell/shell_services.dart';
import '../undo/undo_service.dart';
import 'command.dart';
import 'command_registry.dart';

/// Emitted after every invocation (debug log, MCP `ui.events`).
class CommandInvoked {
  const CommandInvoked({
    required this.id,
    required this.args,
    required this.source,
    required this.at,
    required this.result,
    this.error,
  });

  final CommandId id;
  final Map<String, Object?> args;
  final InvocationSource source;
  final DateTime at;
  final CommandResult? result;
  final Object? error;
}

/// Resolved runtime state of a command (for menus, palette, MCP).
class CommandState {
  const CommandState({
    required this.enabled,
    required this.checked,
    required this.disabledReason,
    this.visible = true,
  });

  /// Whether the command is shown ([Command.isVisible]).
  final bool visible;

  final bool enabled;
  final bool? checked;
  final String? disabledReason;
}

/// Runs commands (suite 08 §1.1): lookup → schema validation → role check →
/// enabled check → undo transaction → execute → commit/rollback → event.
class CommandDispatcher {
  CommandDispatcher(this.services);

  final ShellServices services;
  final _events = StreamController<CommandInvoked>.broadcast();

  CommandRegistry get registry => services.registry;

  Stream<CommandInvoked> get events => _events.stream;

  CommandContext _context(InvocationSource source, BuildContext? context) =>
      CommandContext(services: services, source: source, buildContext: context);

  Command<CommandArgs> _lookup(CommandId id) =>
      registry[id] ?? (throw UnknownCommand(id));

  /// Parses and validates [json] for [command].
  CommandArgs parse(Command<CommandArgs> command, Map<String, Object?> json) {
    final violations = command.argsSchema.validate(json);
    if (violations.isNotEmpty) throw InvalidCommandArgs(violations);
    return command.parseArgs(json);
  }

  /// Role check message, or null when allowed.
  String? roleProblem(Command<CommandArgs> command, CommandContext ctx) {
    final role = ctx.role;
    if (role == null) return null;
    if (role >= command.requiredRole) return null;
    final l = services.l10n;
    return switch (role) {
      Role.viewer => l?.youHaveViewAccess ?? 'You have view access',
      Role.commenter => l?.youHaveCommentAccess ?? 'You have comment access',
      _ => l?.notAllowed ?? 'Not allowed',
    };
  }

  /// Enabled/checked state of [id] with [args] (never throws).
  CommandState stateOf(String id, [Map<String, Object?> args = const {}]) {
    final command = registry.byId(id);
    if (command == null) {
      return const CommandState(
        enabled: false,
        checked: null,
        disabledReason: null,
      );
    }
    final ctx = _context(InvocationSource.menu, null);
    try {
      final a = command.parseArgs(args);
      final visible = command.isVisible(ctx, a);
      final role = roleProblem(command, ctx);
      if (role != null) {
        return CommandState(
          enabled: false,
          checked: command.isChecked(ctx, a),
          disabledReason: role,
          visible: visible,
        );
      }
      final enabled = command.isEnabled(ctx, a);
      return CommandState(
        enabled: enabled,
        checked: command.isChecked(ctx, a),
        disabledReason: enabled ? null : command.disabledReason(ctx, a),
        visible: visible,
      );
    } catch (_) {
      return const CommandState(
        enabled: false,
        checked: null,
        disabledReason: null,
      );
    }
  }

  /// Invokes [id] with JSON [args] from [source].
  Future<CommandResult> invoke(
    String id, {
    Map<String, Object?> args = const {},
    InvocationSource source = InvocationSource.ui,
    BuildContext? context,
  }) async {
    final cid = CommandId(id);
    CommandResult? result;
    Object? error;
    try {
      final command = _lookup(cid);
      final parsed = parse(command, args);
      result = await _run(command, parsed, _context(source, context));
      return result;
    } catch (e) {
      error = e;
      rethrow;
    } finally {
      _events.add(
        CommandInvoked(
          id: cid,
          args: args,
          source: source,
          at: clock.now(),
          result: result,
          error: error,
        ),
      );
    }
  }

  /// Invokes a typed command instance directly (apps).
  Future<CommandResult> run<A extends CommandArgs>(
    Command<A> command,
    A args, {
    InvocationSource source = InvocationSource.ui,
    BuildContext? context,
  }) => _run(command, args, _context(source, context));

  Future<CommandResult> _run<A extends CommandArgs>(
    Command<A> command,
    A args,
    CommandContext ctx,
  ) async {
    final role = roleProblem(command, ctx);
    if (role != null) throw CommandForbidden(command.id, role);
    if (!command.isEnabled(ctx, args)) {
      throw CommandDisabled(command.id, command.disabledReason(ctx, args));
    }
    if (!command.isUndoable) return command.execute(ctx, args);

    final undo = services.undo;
    // Only the transaction of this call chain: a command that starts while
    // another one awaits (typing during a long sort, an agent command) gets
    // its own step instead of joining the other one.
    final outer = undo.currentTransaction;
    if (outer != null) {
      // Nested command: joins the gesture's transaction.
      return command.execute(ctx.withTransaction(outer), args);
    }
    final bc = ctx.dialogContext;
    var label = bc == null ? command.id.value : command.undoLabel(bc, args);
    if (ctx.source.isAgent) {
      label = services.l10n?.agentUndoLabel(label) ?? 'AI: $label';
    }
    final doc = ctx.document;
    final t = undo.beginTransaction(
      label,
      stack: command.undoTarget == UndoTarget.shell
          ? UndoStackKey.shell
          : doc?.undoStackKey ?? UndoStackKey.shell,
      source: ctx.source,
      selectionBefore: ctx.selection,
      scoped: true,
    );
    try {
      final r = await undo.runInTransaction(
        t,
        () => command.execute(ctx.withTransaction(t), args),
      );
      if (r.status == CommandStatus.ok) {
        t.commit(selectionAfter: ctx.selection);
      } else {
        await t.rollback();
      }
      return r;
    } catch (e) {
      await t.rollback();
      rethrow;
    }
  }

  void dispose() => _events.close();
}
