import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' hide ActorKind;

import '../../data/models_ext.dart';
import '../../l10n/wonky_app_localizations.dart';
import '../../shell/shell_services.dart';
import '../command.dart';

/// Shorthand for the shell's localizations.
WonkyAppLocalizations l10nOf(BuildContext context) =>
    WonkyAppLocalizations.of(context);

/// Builds a shell command (most shell commands are thin delegations).
CallbackCommand shellCommand(
  String id, {
  required String Function(WonkyAppLocalizations l) title,
  required Future<CommandResult> Function(CommandContext ctx, JsonArgs args)
  run,
  IconData? icon,
  IconData? Function(Map<String, Object?> args)? iconFor,
  List<KeyBinding> bindings = const [],
  KeyScope scope = KeyScope.global,
  Role role = Role.viewer,
  bool undoable = false,
  UndoTarget undoTarget = UndoTarget.document,
  JsonSchema args = JsonSchema.empty,
  bool palette = true,
  bool Function(CommandContext ctx, JsonArgs args)? enabled,
  bool? Function(CommandContext ctx, JsonArgs args)? checked,
  String Function(WonkyAppLocalizations l)? description,
  String Function(WonkyAppLocalizations l)? category,
}) => CallbackCommand(
  id: id,
  title: (c) => title(l10nOf(c)),
  description: description == null ? null : (c) => description(l10nOf(c)),
  category: category == null ? null : (c) => category(l10nOf(c)),
  run: run,
  icon: icon,
  iconFor: iconFor,
  defaultBindings: bindings,
  keyScope: scope,
  requiredRole: role,
  isUndoable: undoable,
  undoTarget: undoTarget,
  argsSchema: args,
  showInPalette: palette,
  enabled: enabled,
  checked: checked,
);

/// `{uuid?, uuids?}` targets of drive commands.
const targetProps = <String, JsonSchema>{
  'uuid': JsonSchema.string(
    format: 'uuid',
    description: 'Target item; defaults to the selection or the open file.',
  ),
  'uuids': JsonSchema.array(JsonSchema.string(format: 'uuid')),
};

/// Resolves the items a drive command acts on: explicit args, else the home
/// selection, else the open file. Items not known locally are skipped here
/// and fetched in [fetchTargets].
List<DriveItemView> knownTargets(ShellServices s, JsonArgs a) {
  final ids = [...a.strings('uuids'), ?a.string('uuid')];
  if (ids.isNotEmpty) {
    return [for (final id in ids) ?s.knownItem(UuidValue.fromString(id))];
  }
  final sel = s.driveSelection.value;
  if (sel.isNotEmpty) return sel;
  final cur = s.currentItem.value;
  return cur == null ? const [] : [cur];
}

/// Like [knownTargets] but fetches explicitly named items from the server.
Future<List<DriveItemView>> fetchTargets(ShellServices s, JsonArgs a) async {
  final ids = [...a.strings('uuids'), ?a.string('uuid')];
  if (ids.isEmpty) return knownTargets(s, a);
  return [
    for (final id in ids)
      s.knownItem(UuidValue.fromString(id)) ??
          await s.drive.get(UuidValue.fromString(id)),
  ];
}

/// Whether explicit targets were named in [a] (then enabled-checks are
/// deferred to execution).
bool hasExplicitTargets(JsonArgs a) =>
    a.strings('uuids').isNotEmpty || a.string('uuid') != null;

bool targetsAll(
  ShellServices s,
  JsonArgs a,
  bool Function(DriveItemView) test,
) {
  if (hasExplicitTargets(a)) return true;
  final t = knownTargets(s, a);
  return t.isNotEmpty && t.every(test);
}

/// The single target, if exactly one.
DriveItemView? singleTarget(ShellServices s, JsonArgs a) {
  final t = knownTargets(s, a);
  return t.length == 1 ? t.single : null;
}

/// Role accessors on targets.
bool canManageItem(DriveItemView i) => i.canManage && !i.isTrashed;
