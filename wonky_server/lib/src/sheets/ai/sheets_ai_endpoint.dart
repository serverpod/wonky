import 'package:serverpod/serverpod.dart';

import '../../platform/common/models.dart';
import '../../platform/users/user_service.dart';
import 'sheets_ai_service.dart';
import 'sheets_ai_preview_service.dart';
import 'sheets_ai_cells.dart';

/// The inline AI features of Wonky Sheets (Sheets 12 §6.4–6.10) and the AI
/// changes preview of Suggest-mode assistant runs (§6.3). The assistant
/// panel itself uses `assistant.chat` with the spreadsheet's item uuid and
/// the `sheets*` fields of [AssistantContextHints].
class SheetsAiEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Formula from natural language for [cell] (A1 with sheet). Nothing is
  /// written; the app inserts the formula with `sheets.edit.setCellInput`.
  Future<SheetsFormulaSuggestion> suggestFormula(
    Session session,
    UuidValue itemUuid,
    String cell,
    String prompt,
  ) async => SheetsAiService.suggestFormula(
    session,
    await UserService.actorOf(session),
    itemUuid,
    cell,
    prompt,
  );

  /// Streams a plain-language explanation of the formula in [cell] (the
  /// assistant panel shows it).
  Stream<InlineAiEvent> explainFormula(
    Session session,
    UuidValue itemUuid,
    String cell,
  ) async* {
    final actor = await UserService.actorOf(session);
    yield* await SheetsAiService.explainFormula(
      session,
      actor,
      itemUuid,
      cell,
    );
  }

  /// Fill with AI: proposals for the empty cells of a column [range]
  /// (examples = its filled cells). Nothing is written.
  Future<SheetsFillProposal> fillRange(
    Session session,
    UuidValue itemUuid,
    String range,
    String? instructions,
  ) async => SheetsAiService.fillRange(
    session,
    await UserService.actorOf(session),
    itemUuid,
    range,
    instructions,
  );

  /// Writes the accepted proposals as one undo step "AI: Fill …"
  /// (`SheetsEndpoint.revertChange(changeId)` undoes it).
  Future<SheetsAiApplyResult> applyFill(
    Session session,
    UuidValue itemUuid,
    String range,
    List<SheetsFillRow> rows,
  ) async => SheetsAiService.applyFill(
    session,
    await UserService.actorOf(session),
    itemUuid,
    range,
    rows,
  );

  /// Prompt chips of *Data › Analyze with AI* for [range] (or the first
  /// table).
  Future<List<String>> analyzeChips(
    Session session,
    UuidValue itemUuid,
    String? range,
  ) async => SheetsAiService.analyzeChips(
    session,
    await UserService.actorOf(session),
    itemUuid,
    range,
  );

  /// An alt-text proposal for a chart.
  Future<String> describeChart(
    Session session,
    UuidValue itemUuid,
    String chartId,
  ) async => SheetsAiService.describeChart(
    session,
    await UserService.actorOf(session),
    itemUuid,
    chartId,
  );

  /// The AI changes preview of a Suggest-mode run (`previewId` of the
  /// `previewReady` / `done` assistant events).
  Future<SheetsAiPreview> getPreview(Session session, String previewId) async =>
      SheetsAiPreviews.getPreview(
        session,
        await UserService.actorOf(session),
        previewId,
      );

  /// Applies the selected calls (null = all) as one undo step.
  Future<SheetsAiApplyResult> applyPreview(
    Session session,
    String previewId,
    List<String>? callIds,
  ) async => SheetsAiPreviews.applyPreview(
    session,
    await UserService.actorOf(session),
    previewId,
    callIds,
  );

  /// Evaluates `=AI()` cells (Sheets 12 §6.8): cached values, new ones for
  /// Editors; [refresh] recomputes (*Refresh AI cells*).
  Future<List<SheetsAiCellResult>> evaluateAiCells(
    Session session,
    UuidValue itemUuid,
    List<SheetsAiCellRequest> requests,
    bool refresh,
  ) async => SheetsAiCells.evaluateAiCells(
    session,
    await UserService.actorOf(session),
    itemUuid,
    requests,
    refresh: refresh,
  );

  /// Discards a preview.
  Future<void> discardPreview(Session session, String previewId) async =>
      SheetsAiPreviews.discardPreview(
        session,
        await UserService.actorOf(session),
        previewId,
      );
}
