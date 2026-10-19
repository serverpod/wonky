import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';

import '../features/history/change_labels.dart';
import '../features/ai/sheets_a1.dart';
import '../features/ai/sheets_ai_controller.dart';
import '../features/ai/sheets_assistant_adapter.dart' show markdownToRows;
import '../features/explore/explore_panel.dart' show explorePanelId;
import '../features/sheet_editor/sheet_editor_controller.dart';
import '../l10n/sheets_l10n.dart';
import 'sheets_command.dart';

SheetsText get _ai =>
    (l) => l.categoryAi;

/// A Sheets AI command: hidden unless AI is shown, disabled with the
/// server's reason ("AI isn't configured …") while it can't be used.
class SheetsAiCommand extends SheetsCommand {
  SheetsAiCommand(
    super.id, {
    required super.label,
    required super.run,
    super.icon = LucideIcons.sparkles,
    super.descriptionText,
    super.defaultBindings,
    super.keyScope,
    super.mutates,
    super.argsSchema,
    super.showInPalette,
    super.enabled,
    super.undoLabelOf,
    this.needsAi = true,
    this.minRole = Role.viewer,
  }) : super(categoryName: _ai);

  /// Whether the command calls the model (deterministic ones work without
  /// a key).
  final bool needsAi;

  /// Editor for commands that write (Fill, Insert).
  final Role minRole;

  @override
  Role get requiredRole => mutates ? Role.editor : minRole;

  @override
  bool isEnabled(CommandContext ctx, JsonArgs args) {
    final ed = editorOf(ctx);
    if (ed == null) return false;
    final ai = SheetsAiController.of(ed);
    if (needsAi && !ai.available) return false;
    if (minRole >= Role.editor && !ed.canEdit) return false;
    return super.isEnabled(ctx, args);
  }

  @override
  String? disabledReason(CommandContext ctx, JsonArgs args) {
    final ed = editorOf(ctx);
    if (ed != null && needsAi) {
      final reason = SheetsAiController.of(ed).unavailableReason;
      if (reason != null) return reason;
    }
    if (ed != null && minRole >= Role.editor && !ed.canEdit) {
      final l = sheetsL10nOf(ctx.services);
      return ed.roleCanEdit ? l.reasonViewingMode : l.reasonViewAccess;
    }
    return super.disabledReason(ctx, args);
  }
}

bool _activeIsFormula(SheetEditorController ed) =>
    ed.activeDisplay()?.isFormula ?? false;

/// The AI commands of Sheets (12 §7, 04 §3.7–3.8) and Explore (04 §7).
List<Command<CommandArgs>> aiCommands(ShellServices s) => [
  SheetsAiCommand(
    'sheets.ai.suggestFormula',
    label: (l) => l.cmdAiSuggestFormula,
    descriptionText: (l) => l.cmdAiSuggestFormulaDescription,
    minRole: Role.editor,
    keyScope: KeyScope.global,
    defaultBindings: const [KeyBinding('J', mod: true, alt: true)],
    argsSchema: const JsonSchema.object(
      properties: {
        'cell': JsonSchema.string(description: 'Target cell (A1).'),
        'prompt': JsonSchema.string(
          maxLength: 2000,
          description:
              'What the formula should do. With a prompt the suggestion is '
              'returned (nothing is written; insert it with '
              'sheets.cell.setInput).',
        ),
      },
    ),
    run: (ctx, ed, a) async {
      final ai = SheetsAiController.of(ed);
      final f = await ai.openSuggest(
        cell: a.string('cell'),
        prompt: a.string('prompt'),
      );
      final state = ai.popover.value;
      if (f == null) {
        if (state?.error != null) return CommandResult.failed(state!.error!);
        return ok({'cell': state?.cellA1});
      }
      return ok({
        'cell': state?.cellA1,
        'formula': f.formula,
        'localized_formula': f.localizedFormula,
        'explanation': f.explanation,
        'preview_value': f.previewValue,
        'error_message': f.errorMessage,
        'uses_external_data': f.usesExternalData,
      });
    },
  ),
  SheetsAiCommand(
    'sheets.ai.explainFormula',
    label: (l) => l.cmdAiExplainFormula,
    argsSchema: const JsonSchema.object(
      properties: {'cell': JsonSchema.string(description: 'A1 of the cell.')},
    ),
    enabled: (ed, a) => a.string('cell') != null || _activeIsFormula(ed),
    run: (ctx, ed, a) {
      final ai = SheetsAiController.of(ed);
      if (!ai.explain(cell: a.string('cell'))) {
        return CommandResult.failed(ai.l10n.aiNoFormula);
      }
      return ok({'cell': ai.popover.value?.cellA1});
    },
  ),
  SheetsAiCommand(
    'sheets.ai.fillRange',
    label: (l) => l.cmdAiFillRange,
    descriptionText: (l) => l.cmdAiFillRangeDescription,
    minRole: Role.editor,
    argsSchema: const JsonSchema.object(
      properties: {
        'range': JsonSchema.string(
          description: 'One column with some examples (default: selection).',
        ),
        'instructions': JsonSchema.string(maxLength: 2000),
      },
    ),
    enabled: (ed, a) {
      if (a.string('range') != null) return true;
      final sel = ed.selection.resolved;
      return sel.ranges.length == 1 &&
          sel.activeRange.rect.left == sel.activeRange.rect.right &&
          !sel.isSingleCell;
    },
    run: (ctx, ed, a) async {
      final ai = SheetsAiController.of(ed);
      final r = await ai.fill(
        range: a.string('range'),
        instructions: a.string('instructions'),
        context: ctx.buildContext,
      );
      if (r == null) return const CommandResult.cancelled();
      return ok({
        'change_id': r.changeId?.uuid,
        'cells_affected': r.cellsAffected,
        'label': r.label,
      });
    },
  ),
  SheetsAiCommand(
    'sheets.ai.analyze',
    label: (l) => l.cmdAiAnalyze,
    needsAi: false,
    argsSchema: const JsonSchema.object(
      properties: {'range': JsonSchema.string()},
    ),
    enabled: (ed, a) => SheetsAiController.of(ed).shown,
    run: (ctx, ed, a) async {
      final chips = await SheetsAiController.of(
        ed,
      ).analyze(range: a.string('range'));
      return ok({'prompts': chips});
    },
  ),
  SheetsAiCommand(
    'sheets.ai.cleanupSuggestions',
    label: (l) => l.cmdAiCleanupSuggestions,
    icon: LucideIcons.sparkles,
    argsSchema: const JsonSchema.object(
      properties: {'range': JsonSchema.string()},
    ),
    run: (ctx, ed, a) async {
      final prompt = await SheetsAiController.of(
        ed,
      ).cleanupWithAi(range: a.string('range'));
      return prompt == null
          ? const CommandResult.cancelled()
          : ok({'prompt': prompt});
    },
  ),
  SheetsAiCommand(
    'sheets.ai.refreshAiCells',
    label: (l) => l.cmdAiRefreshAiCells,
    icon: LucideIcons.refreshCw,
    minRole: Role.editor,
    argsSchema: const JsonSchema.object(
      properties: {'ranges': JsonSchema.array(JsonSchema.string())},
    ),
    run: (ctx, ed, a) async {
      SheetsAiController.of(ed).refreshAiCells();
      return ok();
    },
  ),
  SheetsAiCommand(
    'sheets.ai.describeChart',
    label: (l) => l.cmdAiDescribeChart,
    showInPalette: false,
    argsSchema: const JsonSchema.object(
      properties: {
        'objectId': JsonSchema.string(minLength: 1),
        'show': JsonSchema.boolean(
          defaultValue: true,
          description:
              'Show the proposal in the assistant panel (the alt-text '
              'dialog passes false and uses the returned text).',
        ),
      },
      required: ['objectId'],
    ),
    run: (ctx, ed, a) async {
      final ai = SheetsAiController.of(ed);
      final text = await ai.describeChart(a.requireString('objectId'));
      if (a.boolean('show') ?? true) {
        final chat = ai.chat;
        if (chat != null) {
          final r = chat.addResult(ai.l10n.aiDescribeChartResult);
          r
            ..markdown = text
            ..status = AssistantReplyStatus.done;
          chat.refresh();
          s.panels.open(ShellPanels.assistant);
        }
      }
      return ok({'alt_text': text});
    },
  ),
  SheetsAiCommand(
    'sheets.ai.applyPreview',
    label: (l) => l.cmdAiApplyPreview,
    showInPalette: false,
    minRole: Role.editor,
    argsSchema: const JsonSchema.object(
      properties: {
        'previewId': JsonSchema.string(minLength: 1),
        'selectedCallIds': JsonSchema.array(JsonSchema.string()),
      },
      required: ['previewId'],
    ),
    needsAi: false,
    run: (ctx, ed, a) async {
      final ids = a.values['selectedCallIds'];
      final r = await SheetsAiController.of(ed).applyPreview(
        a.requireString('previewId'),
        callIds: ids is List ? [for (final x in ids) '$x'] : null,
      );
      return ok({
        'change_id': r.changeId?.uuid,
        'cells_affected': r.cellsAffected,
        'skipped': r.skipped,
      });
    },
  ),
  SheetsAiCommand(
    'sheets.ai.discardPreview',
    label: (l) => l.cmdAiDiscardPreview,
    showInPalette: false,
    needsAi: false,
    argsSchema: const JsonSchema.object(
      properties: {'previewId': JsonSchema.string(minLength: 1)},
      required: ['previewId'],
    ),
    run: (ctx, ed, a) async {
      await SheetsAiController.of(
        ed,
      ).discardPreview(a.requireString('previewId'));
      return ok();
    },
  ),
  SheetsAiCommand(
    'sheets.ai.insertResult',
    label: (l) => l.cmdAiInsertResult,
    showInPalette: false,
    needsAi: false,
    mutates: true,
    undoLabelOf: (l, a) => l.aiInsertUndo,
    argsSchema: const JsonSchema.object(
      properties: {
        'markdown': JsonSchema.string(maxLength: 200000),
        'cell': JsonSchema.string(description: 'Top-left cell (A1).'),
      },
      required: ['markdown'],
    ),
    run: (ctx, ed, a) {
      final rows = markdownToRows(a.requireString('markdown'));
      if (rows.isEmpty) return const CommandResult.failed('Nothing to insert');
      final at = a.string('cell');
      var sheetId = ed.activeSheetId;
      var row = ed.selection.resolved.activeRow;
      var col = ed.selection.resolved.activeCol;
      if (at != null) {
        final rr = ed.model.parseA1(at, contextSheetId: sheetId);
        sheetId = rr.sheetId;
        row = rr.rect.top;
        col = rr.rect.left;
      }
      final width = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
      ed.apply(
        ctx,
        SetCellInputs(
          sheetId: sheetId,
          row: row,
          col: col,
          inputs: [
            for (final r in rows)
              [
                for (var i = 0; i < width; i++)
                  UserCellInput(i < r.length ? r[i] : ''),
              ],
          ],
          parseLocale: ed.locale,
          label: SheetsChangeLabels.insertAiResult,
        ),
      );
      final range = rectA1(
        GridRect(row, col, row + rows.length - 1, col + width - 1),
      );
      return ok({'range': qualifiedA1(ed.sheetName(sheetId), range)});
    },
  ),
  SheetsCommand(
    'sheets.explore.toggle',
    label: (l) => l.cmdExploreToggle,
    icon: LucideIcons.telescope,
    categoryName: (l) => l.categoryAi,
    keyScope: KeyScope.global,
    defaultBindings: const [KeyBinding('X', alt: true, shift: true)],
    checked: (ed, a) => s.panels.isOpen(explorePanelId),
    run: (ctx, ed, a) {
      s.panels.toggle(explorePanelId);
      return ok({'open': s.panels.isOpen(explorePanelId)});
    },
  ),
];
