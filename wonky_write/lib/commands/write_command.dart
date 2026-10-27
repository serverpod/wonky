import 'dart:async';

import 'command_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';

import '../features/screen/write_document_controller.dart';
import '../l10n/write_l10n.dart';

export '../l10n/write_l10n.dart' show WriteLocalizations, WriteText;

/// Runs a Write command against the active document.
typedef WriteRun =
    FutureOr<CommandResult> Function(
      CommandContext ctx,
      WriteDocumentController doc,
      JsonArgs args,
    );

/// A Write command (Write 04 §40, 05 §24): needs an open, loaded document
/// unless [needsDocument] is false. Titles, categories, descriptions and
/// reasons are resolved from the Write localizations when shown.
class WriteCommand extends JsonCommand {
  WriteCommand(
    String id, {
    required this.label,
    required this.run,
    IconData? icon,
    this.categoryName,
    this.descriptionText,
    this.defaultBindings = const [],
    this.keyScope = KeyScope.global,
    this.requiredRole = Role.viewer,
    this.isUndoable = false,
    this.argsSchema = JsonSchema.empty,
    this.showInPalette = true,
    this.needsDocument = true,
    this.needsEditable = false,
    this.enabled,
    this.checked,
    this.reason,
    this.undoLabelOf,
    this.aliasList = const [],
    this.wonkyOnly = false,
  }) : id = CommandId(id),
       // Menus show the command's icon; fall back to the shared table so
       // every Write command has one (Write 05 §7).
       icon = icon ?? commandIcons[id];

  @override
  final CommandId id;
  final WriteText label;
  @override
  final IconData? icon;

  @override
  IconData? iconFor(Map<String, Object?> args) =>
      args.isEmpty ? icon : (commandIconFor(id.value, args) ?? icon);
  final WriteText? categoryName;
  final WriteText? descriptionText;
  @override
  final List<KeyBinding> defaultBindings;
  @override
  final KeyScope keyScope;
  @override
  final Role requiredRole;
  @override
  final bool isUndoable;
  @override
  final JsonSchema argsSchema;
  @override
  final bool showInPalette;
  final List<String> aliasList;

  /// Whether the command needs an open Write document.
  final bool needsDocument;

  /// Whether the command changes content (needs Editing/Suggesting rights).
  final bool needsEditable;

  /// Only shown and enabled in Wonky Markdown documents (Write 11 §7.5).
  final bool wonkyOnly;
  final bool Function(WriteDocumentController doc, JsonArgs args)? enabled;
  final bool? Function(WriteDocumentController doc, JsonArgs args)? checked;
  final String? Function(
    WriteLocalizations l,
    WriteDocumentController doc,
    JsonArgs args,
  )?
  reason;
  final String Function(WriteLocalizations l, JsonArgs args)? undoLabelOf;
  final WriteRun run;

  @override
  String title(BuildContext context) => label(writeL10n(context));

  @override
  String? description(BuildContext context) =>
      descriptionText?.call(writeL10n(context));

  @override
  String? category(BuildContext context) =>
      categoryName?.call(writeL10n(context));

  @override
  List<String> aliases(BuildContext context) => aliasList;

  @override
  String undoLabel(BuildContext context, JsonArgs args) {
    final l = writeL10n(context);
    return undoLabelOf?.call(l, args) ?? label(l);
  }

  @override
  bool isEnabled(CommandContext ctx, JsonArgs args) {
    final doc = WriteDocumentController.of(ctx);
    if (doc == null) return !needsDocument;
    if (needsDocument && !doc.isLoaded) return false;
    if (needsEditable && !doc.editable) return false;
    if (wonkyOnly && !doc.isWonky) return false;
    return enabled?.call(doc, args) ?? true;
  }

  @override
  bool isVisible(CommandContext ctx, JsonArgs args) {
    if (!wonkyOnly) return true;
    return WriteDocumentController.of(ctx)?.isWonky ?? false;
  }

  @override
  String? disabledReason(CommandContext ctx, JsonArgs args) {
    final doc = WriteDocumentController.of(ctx);
    if (doc == null) return null;
    final l = writeL10nOf(ctx.services);
    if (needsEditable && !doc.editable) return editDisabledReason(l, doc);
    return reason?.call(l, doc, args);
  }

  @override
  bool? isChecked(CommandContext ctx, JsonArgs args) {
    final doc = WriteDocumentController.of(ctx);
    if (doc == null || checked == null) return null;
    return checked!(doc, args);
  }

  @override
  Future<CommandResult> execute(CommandContext ctx, JsonArgs args) async {
    final doc = WriteDocumentController.of(ctx);
    if (doc == null) {
      if (needsDocument) {
        return const CommandResult.failed('No document is open');
      }
    }
    return await run(ctx, doc!, args);
  }
}

/// A Write command that works without an open document (help, prefs).
class WriteGlobalCommand extends JsonCommand {
  WriteGlobalCommand(
    String id, {
    required this.label,
    required this.run,
    IconData? icon,
    this.categoryName,
    this.defaultBindings = const [],
    this.argsSchema = JsonSchema.empty,
    this.checked,
    this.enabled,
  }) : id = CommandId(id),
       icon = icon ?? commandIcons[id];

  @override
  final CommandId id;
  final WriteText label;
  @override
  final IconData? icon;
  final WriteText? categoryName;
  @override
  final List<KeyBinding> defaultBindings;
  @override
  final JsonSchema argsSchema;
  final bool? Function(CommandContext ctx, JsonArgs args)? checked;
  final bool Function(CommandContext ctx, JsonArgs args)? enabled;
  final FutureOr<CommandResult> Function(CommandContext ctx, JsonArgs args) run;

  @override
  Role get requiredRole => Role.viewer;

  @override
  bool get isUndoable => false;

  @override
  String title(BuildContext context) => label(writeL10n(context));

  @override
  String? category(BuildContext context) =>
      categoryName?.call(writeL10n(context));

  @override
  bool isEnabled(CommandContext ctx, JsonArgs args) =>
      enabled?.call(ctx, args) ?? true;

  @override
  bool? isChecked(CommandContext ctx, JsonArgs args) =>
      checked?.call(ctx, args);

  @override
  Future<CommandResult> execute(CommandContext ctx, JsonArgs args) async =>
      await run(ctx, args);
}

/// Why content commands are disabled for [doc].
String editDisabledReason(WriteLocalizations l, WriteDocumentController doc) {
  if (!doc.isLoaded) return l.reasonDocumentLoading;
  if (doc.role < Role.commenter) return l.reasonViewAccess;
  if (doc.editor.mode.name == 'viewing') return l.reasonSwitchToEditOrSuggest;
  if (doc.role < Role.editor) return l.reasonSuggestOnly;
  return l.reasonNotAvailable;
}

/// `ok` or `failed(message)`.
CommandResult okIf(bool ok, [String message = 'Not available here']) =>
    ok ? const CommandResult.ok() : CommandResult.failed(message);
