import 'package:super_editor/super_editor.dart';

import '../controller/editor_pipeline.dart';
import '../controller/editor_types.dart';
import '../mapping/wonky_schema.dart';
import '../reactions/auto_pair_reaction.dart';
import '../reactions/block_conversion_reactions.dart';
import '../reactions/box_guard_reaction.dart';
import '../reactions/embed_selection_reaction.dart';
import '../reactions/mention_atomicity_reaction.dart';
import '../reactions/reaction_wrappers.dart';
import '../reactions/typing_attributes_reaction.dart';
import '../reactions/typography_reactions.dart';
import '../reactions/pill_boundary.dart';
import '../reactions/wonky_shortcuts.dart';
import '../schema_guard/schema_guard_reaction.dart';

/// A command that does nothing (used by guards to refuse requests).
class NoOpEditCommand extends EditCommand {
  const NoOpEditCommand();

  @override
  HistoryBehavior get historyBehavior => HistoryBehavior.nonHistorical;

  @override
  void execute(EditContext context, CommandExecutor executor) {}
}

/// Requests that never change content; they pass the mode guard.
bool isNonMutatingRequest(EditRequest request) =>
    request is ChangeSelectionRequest ||
    request is ClearSelectionRequest ||
    request is ChangeComposingRegionRequest ||
    request is ClearComposingRegionRequest ||
    request is ChangeInteractionModeRequest ||
    request is RemoveComposerPreferenceStylesRequest ||
    request is CancelComposingActionTagRequest ||
    request is CancelComposingStableTagRequest ||
    // Collaborators' changes still apply in Viewing mode.
    request is ApplyDocumentPatchRequest;

/// Requests that insert text (refused at the document size limit).
bool isTextInsertionRequest(EditRequest request) =>
    request is InsertTextRequest ||
    request is InsertCharacterAtCaretRequest ||
    request is InsertPlainTextAtCaretRequest ||
    request is InsertStyledTextAtCaretRequest ||
    request is InsertAttributedTextRequest ||
    request is InsertNewlineAtCaretRequest ||
    request is InsertSoftNewlineAtCaretRequest ||
    request is PasteEditorRequest;

/// Collapses the selections the user makes (double taps, drags, long presses)
/// while [selectable] is false: the read-only mobile layout has no text
/// selection (suite 02 §6.1, T-1). Read-only documents don't show a
/// collapsed selection, and super_editor's gesture interactors expect their
/// selection requests to set one (refusing them crashes the touch
/// interactors). Selections set by content changes still apply.
EditRequestHandler selectionGuard(bool Function() selectable) =>
    (editor, request) {
      if (selectable() ||
          request is! ChangeSelectionRequest ||
          request.reason != SelectionReason.userInteraction) {
        return null;
      }
      final selection = request.newSelection;
      if (selection == null || selection.isCollapsed) return null;
      return ChangeSelectionCommand(
        DocumentSelection.collapsed(position: selection.extent),
        request.changeType,
        request.reason,
      );
    };

/// Request handlers that run before super_editor's own (Write 04 §2.2).
List<EditRequestHandler> wonkyRequestHandlers({
  required EditorMode Function() mode,
  bool Function()? selectable,
  required int Function() documentLength,
  required void Function() onMaxLengthReached,
  int maxDocumentChars = 2000000,
}) {
  return [
    if (selectable != null) selectionGuard(selectable),
    // Mode guard (§31): Viewing refuses every content change.
    (editor, request) =>
        mode() == EditorMode.viewing && !isNonMutatingRequest(request)
        ? const NoOpEditCommand()
        : null,
    // Document size limit (§3.1).
    (editor, request) {
      if (!isTextInsertionRequest(request) ||
          documentLength() < maxDocumentChars) {
        return null;
      }
      onMaxLengthReached();
      return const NoOpEditCommand();
    },
  ];
}

/// The Wonky reaction pipeline (Write 04 §41.2). Autoformat and smart
/// typography are marked reactions (their own undo steps) and toggleable by
/// user preferences. The schema guard is last.
List<EditReaction> wonkyReactions(
  EditorPipeline pipeline, {
  required WriteEditorPreferences Function() preferences,
  required EditorMode Function() mode,
  required String Function() newEmbedId,
  bool Function()? isWonky,
  PillBoundary? pillBoundary,
}) {
  final extractor = pipeline.extractor;
  bool notInCode() {
    final selection = pipeline.composer.selection;
    if (selection == null) return true;
    return !isCodeBlockNode(
      pipeline.document.getNodeById(selection.extent.nodeId),
    );
  }

  bool markdown() =>
      preferences().markdownShortcuts &&
      notInCode() &&
      mode() != EditorMode.viewing;
  bool smart() =>
      preferences().smartTypography &&
      notInCode() &&
      mode() != EditorMode.viewing;
  bool autolink() =>
      preferences().autolink && notInCode() && mode() != EditorMode.viewing;

  EditReaction marked(
    EditReaction inner,
    String label,
    bool Function() enabled,
  ) => MarkedReaction(
    ToggleableReaction(inner, enabled),
    label: label,
    extractor: extractor,
  );

  final boxGuard = WonkyBoxGuard(pipeline.mirror);
  return [
    boxGuard.snapshot,
    WonkyTypingAttributesReaction(boundary: pillBoundary),
    marked(const LinkifyReaction(), 'Autolink', autolink),
    marked(
      BlockPrefixConversionReaction(newEmbedId: newEmbedId, isWonky: isWonky),
      'Autoformat',
      markdown,
    ),
    marked(
      const MarkdownInlineUpstreamSyntaxReaction(
        defaultUpstreamInlineMarkdownParsers,
      ),
      'Autoformat',
      markdown,
    ),
    marked(const EmDashReaction(), 'Smart dash', smart),
    marked(const EllipsisReaction(), 'Smart ellipsis', smart),
    marked(const SmartQuotesReaction(), 'Smart quote', smart),
    AutoPairReaction(
      enabled: () => preferences().autoPair && mode() != EditorMode.viewing,
      markdownShortcuts: () => preferences().markdownShortcuts,
    ),
    // After auto-pair, which overtypes the closer first.
    marked(
      WonkyInlineShortcutReaction(boundary: pillBoundary),
      'Autoformat',
      () => markdown() && (isWonky?.call() ?? false),
    ),
    UpdateSubTaskIndentAfterTaskDeletionReaction(),
    const MentionAtomicityReaction(),
    EmbedSelectionReaction(isEditable: () => mode() != EditorMode.viewing),
    boxGuard.restore,
    const WonkySchemaGuardReaction(),
  ];
}
