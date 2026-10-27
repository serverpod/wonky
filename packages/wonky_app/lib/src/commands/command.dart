import 'package:flutter/widgets.dart';
import 'package:wonky_core/wonky_core.dart';

import '../document/document_controller.dart';
import '../shell/shell_services.dart';
import '../undo/undo_service.dart';

/// Which undo stack a command's changes land on (suite 08 §3.2).
enum UndoTarget {
  /// The active document's stack (content, document metadata, comments).
  document,

  /// The shell stack (drive operations: move, rename, star, trash…).
  shell,
}

/// A user-visible action (suite 08 §1). Menus, toolbars, context menus,
/// shortcuts, the palette, MCP and the AI assistant all invoke commands
/// through the `CommandDispatcher`; no menu or toolbar calls business logic
/// directly.
abstract class Command<A extends CommandArgs> {
  const Command();

  /// Stable id (`<app|shell>.<area>.<action>`). Never rename.
  CommandId get id;

  /// Localized title for menus, palette, tooltips and undo labels.
  String title(BuildContext context);

  /// Longer description (palette; MCP tool description).
  String? description(BuildContext context) => null;

  IconData? get icon => null;

  /// The icon of a menu item that invokes the command with [args] (a
  /// command with a choice argument can show one icon per choice).
  IconData? iconFor(Map<String, Object?> args) => icon;

  /// Extra search terms for the palette.
  List<String> aliases(BuildContext context) => const [];

  /// Grouping in the keyboard-shortcuts help ("File", "Edit", …).
  String? category(BuildContext context) => null;

  /// JSON schema of the arguments (MCP `ui.invoke_command`, AI assistant).
  JsonSchema get argsSchema => JsonSchema.empty;

  /// Parses validated JSON into typed arguments.
  A parseArgs(Map<String, Object?> json);

  /// Default bindings (platform-aware); users can override them.
  List<KeyBinding> get defaultBindings => const [];

  /// The scope the default bindings live in.
  KeyScope get keyScope => KeyScope.global;

  /// Bindings that invoke the command with fixed arguments, optionally in
  /// another scope (`sheets.nav.move {dir: down}` on ↓ in the grid scope).
  /// Not user-overridable.
  List<ArgsKeyBinding> get argBindings => const [];

  /// Minimum role on the active document; checked only when a document is
  /// active (drive commands check per-item roles in [isEnabled]).
  Role get requiredRole => Role.editor;

  /// Whether the command mutates undoable state.
  bool get isUndoable => true;

  /// Where undo entries go.
  UndoTarget get undoTarget => UndoTarget.document;

  /// Whether the palette lists the command.
  bool get showInPalette => true;

  /// Whether the command can run now (drives disabled state everywhere).
  bool isEnabled(CommandContext ctx, A args) => true;

  /// Whether menus, the palette and toolbars show the command at all (Write
  /// hides its Wonky Markdown commands in GitHub Markdown documents).
  bool isVisible(CommandContext ctx, A args) => true;

  /// Tooltip for the disabled state ("You have view access").
  String? disabledReason(CommandContext ctx, A args) => null;

  /// Checked state of toggles / radio items (null = not checkable).
  bool? isChecked(CommandContext ctx, A args) => null;

  /// Label of the undo step ("Undo Rename"). Defaults to [title].
  String undoLabel(BuildContext context, A args) => title(context);

  /// Runs the command. Record undo entries with `ctx.record(entry)`.
  Future<CommandResult> execute(CommandContext ctx, A args);
}

/// A key binding with fixed command arguments ([Command.argBindings]).
class ArgsKeyBinding {
  const ArgsKeyBinding(this.binding, this.args, {this.scope});

  final KeyBinding binding;
  final Map<String, Object?> args;

  /// Scope of the binding; null = the command's [Command.keyScope].
  final KeyScope? scope;
}

/// A command whose arguments are a validated JSON map ([JsonArgs]).
abstract class JsonCommand extends Command<JsonArgs> {
  const JsonCommand();

  @override
  JsonArgs parseArgs(Map<String, Object?> json) => JsonArgs(json);
}

/// A command defined by closures — handy for app commands that delegate to
/// a controller.
class CallbackCommand extends JsonCommand {
  CallbackCommand({
    required String id,
    required this._title,
    required this._run,
    this.icon,
    this.defaultBindings = const [],
    this.keyScope = KeyScope.global,
    this.requiredRole = Role.viewer,
    this.isUndoable = false,
    this.undoTarget = UndoTarget.document,
    this.argsSchema = JsonSchema.empty,
    this.showInPalette = true,
    this._enabled,
    this._checked,
    this._description,
    this._category,
  }) : id = CommandId(id);

  @override
  final CommandId id;
  @override
  final IconData? icon;
  @override
  final List<KeyBinding> defaultBindings;
  @override
  final KeyScope keyScope;
  @override
  final Role requiredRole;
  @override
  final bool isUndoable;
  @override
  final UndoTarget undoTarget;
  @override
  final JsonSchema argsSchema;
  @override
  final bool showInPalette;
  final String Function(BuildContext) _title;
  final Future<CommandResult> Function(CommandContext, JsonArgs) _run;
  final bool Function(CommandContext, JsonArgs)? _enabled;
  final bool? Function(CommandContext, JsonArgs)? _checked;
  final String? Function(BuildContext)? _description;
  final String? Function(BuildContext)? _category;

  @override
  String title(BuildContext context) => _title(context);

  @override
  String? description(BuildContext context) => _description?.call(context);

  @override
  String? category(BuildContext context) => _category?.call(context);

  @override
  bool isEnabled(CommandContext ctx, JsonArgs args) =>
      _enabled?.call(ctx, args) ?? true;

  @override
  bool? isChecked(CommandContext ctx, JsonArgs args) =>
      _checked?.call(ctx, args);

  @override
  Future<CommandResult> execute(CommandContext ctx, JsonArgs args) =>
      _run(ctx, args);
}

/// Everything a command can use while running (suite 08 §1).
class CommandContext {
  CommandContext({
    required this.services,
    required this.source,
    this.buildContext,
    this.transaction,
  });

  final ShellServices services;
  final InvocationSource source;

  /// For dialogs; null when headless.
  final BuildContext? buildContext;

  /// The open undo transaction (undoable commands only).
  final UndoTransaction? transaction;

  /// `write` or `sheets`.
  String get app => services.config.app.name;

  /// The active document controller, if an editor is open.
  DocumentController? get document => services.activeDocument.value;

  /// The current selection (restored by undo).
  SelectionSnapshot? get selection => document?.captureSelection();

  /// The user's role on the active document.
  Role? get role => document?.role;

  UndoService get undo => services.undo;

  /// A context usable for dialogs: the invoking widget's, or the shell's
  /// navigator context (MCP/headless invocations still show dialogs in the
  /// live window).
  ///
  /// The global key scope sits above the navigator, so a context without a
  /// [Navigator] ancestor falls back to the navigator's own context.
  BuildContext? get dialogContext {
    final bc = buildContext;
    if (bc != null && bc.mounted && Navigator.maybeOf(bc) != null) return bc;
    return services.navigatorContext;
  }

  /// Records an undo entry in the open transaction.
  void record(UndoEntry entry) {
    final t = transaction;
    if (t == null) {
      throw StateError(
        'No undo transaction: is the command marked isUndoable?',
      );
    }
    t.record(entry);
  }

  CommandContext withTransaction(UndoTransaction? t) => CommandContext(
    services: services,
    source: source,
    buildContext: buildContext,
    transaction: t,
  );
}
