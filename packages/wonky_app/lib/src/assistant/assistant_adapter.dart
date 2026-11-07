import 'package:flutter/widgets.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_ui/wonky_ui.dart' show WonkyMenuEntry;

import '../mcp_bridge/ui_tool.dart';
import 'assistant_models.dart';

/// What an app contributes to the shared assistant panel for its open file
/// (suite 10 §3 "specialized per app"): context hints and chips, Show and
/// Undo of tool changes, quick prompts and inserting results.
abstract class AssistantDocumentAdapter implements Listenable {
  /// The open drive item.
  UuidValue get itemUuid;

  /// The user's role on it (Commenters always get Suggest).
  Role get role;

  /// Volatile context for a chat message. [chips] are the chips the user
  /// kept (removed chips are not sent).
  AssistantContextHints hints({
    required AiApplyMode applyMode,
    required Set<String> chips,
    bool includeComments = false,
  });

  /// The context chips right now (selection, …). Notifies listeners when
  /// they change.
  List<AssistantContextChip> get chips;

  /// Quick prompts of the app.
  List<AssistantQuickPrompt> get quickPrompts;

  /// Reveals and flashes the range of a tool change.
  void show(AssistantActivity activity);

  /// Undoes the run's undo step when it is still the latest change of that
  /// run on the user's stack; false when it can't (the panel then reverts
  /// each change on the server).
  Future<bool> undoRun(String runId);

  /// A run finished: relabel its undo step (`AI: <summary>`).
  void runFinished(String runId, String summary);

  /// Inserts Markdown at the cursor ([atTop]: at the document start) as one
  /// undoable step.
  Future<bool> insertMarkdown(String markdown, {bool atTop = false});
}

/// Optional hooks of an [AssistantDocumentAdapter] whose AI changes are
/// server-side change records (Wonky Sheets 12 §6.2–6.3): an adapter that
/// also implements this interface is told about the run's composite
/// server change (one undo step), Suggest-mode previews and finished tool
/// calls, and can add widgets under a reply ("Review changes").
abstract interface class AssistantRunHooks {
  /// A tool call finished ([activity] carries `range` / `objectId`).
  void toolFinished(AssistantActivity activity);

  /// An Edit-mode run committed its changes as one server change
  /// (`done.changeId`); [summary] is the short label of the run.
  void runCommitted(AssistantReplyEntry reply, String changeId, String summary);

  /// A Suggest-mode run recorded an AI changes preview (`previewReady`).
  void previewReady(AssistantReplyEntry reply, String previewId);

  /// Extra widgets under [reply] (null = none).
  Widget? replyFooter(BuildContext context, AssistantReplyEntry reply);
}

/// Optional texts of an [AssistantDocumentAdapter] whose files are not
/// "documents" (Wonky Sheets: "this spreadsheet"). An adapter that also
/// implements this interface replaces the panel's texts; null keeps the
/// shell's text.
abstract interface class AssistantPanelTexts {
  /// The empty state ("Ask about this spreadsheet …").
  String? get emptyTitle;

  /// The privacy notice; [provider] is the provider's display name (null
  /// when unknown).
  String? privacyNotice(String? provider);

  /// Tooltip of *Edit* ("changes go straight into the spreadsheet").
  String? get modeEditHint;

  /// Tooltip of *Edit* when the user can only suggest.
  String? get modeEditUnavailable;

  /// Tooltip of *Suggest*.
  String? get modeSuggestHint;
}

/// Optional window tools of an [AssistantDocumentAdapter] (Sheets 12
/// §6.2): the assistant runs these `ui.*` tools in the window the request
/// came from (relayed as `uiToolCall` events of the chat stream). The
/// adapter lists them in [AssistantContextHints.uiTools].
abstract interface class AssistantWindowTools {
  /// Runs [tool] with [args] in this window; throws [UiToolException].
  Future<UiToolResult> runWindowTool(String tool, Map<String, Object?> args);
}

/// A quick action button of the panel (Write: Summarize, Proofread, …).
/// [onPressed] runs the action's command.
class AssistantQuickActionButton {
  const AssistantQuickActionButton({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.tooltip,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final String? tooltip;
}

/// Optional panel features of an [AssistantDocumentAdapter] (Write 09
/// §5): an adapter that also implements this interface gets quick action
/// buttons instead of quick prompts, extra ⋮ menu items, a follow-up
/// button under failed replies, and can hide the Edit / Suggest toggle.
abstract interface class AssistantPanelExtras {
  /// The assistant's edits are always suggestions: no Edit / Suggest
  /// toggle (Write).
  bool get alwaysSuggests;

  /// Buttons above the composer (they replace the quick prompts).
  List<AssistantQuickActionButton> get quickActions;

  /// Extra items of the panel's ⋮ menu ("Style guides…").
  List<WonkyMenuEntry> moreMenuEntries();

  /// A button under a failed reply (e.g. `no_style` → *Choose a style
  /// guide*), or null.
  Widget? errorAction(BuildContext context, AssistantReplyEntry reply);
}
