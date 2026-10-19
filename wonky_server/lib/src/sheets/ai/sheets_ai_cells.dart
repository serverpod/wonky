import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;

import '../../platform/ai/ai_call.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/ai/prompts/sheets_prompts.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/mcp_errors.dart';
import '../mcp/sheets_mcp_support.dart';

import 'sheets_ai_service.dart';

/// `=AI(prompt, ranges…)` cells of Wonky Sheets (Sheets 12 §6.8): cached
/// results per spreadsheet and model calls with the small model, within
/// per-user and per-spreadsheet limits.
abstract final class SheetsAiCells {
  // ------------------------------------------------------ AI() cells

  /// Per-call batch limit of `evaluateAiCells`.
  static const aiCellBatch = 20;

  /// Uncached `AI()` evaluations per user and day (Sheets 12 §6.8).
  static int aiCellsPerUserDay = 500;

  /// Cached `AI()` results per spreadsheet.
  static int aiCellsPerSpreadsheet = 5000;

  /// The cache key of an `AI()` call: sha256(version ‖ prompt ‖ values).
  /// The model is not part of the key: viewers of a spreadsheet may use
  /// other providers and must still see the cached values.
  static String aiCellKey(String prompt, String valuesJson) => sha256
      .convert(utf8.encode('ai-v1\u0000$prompt\u0000$valuesJson'))
      .toString();

  /// Evaluates `=AI(prompt, ranges…)` calls (Sheets 12 §6.8): cached values
  /// come from [AiFunctionCache] (never recomputed unless the inputs change
  /// or [refresh]); new ones are computed with the small model for Editors
  /// only (others get no value: "waiting for an editor").
  static Future<List<SheetsAiCellResult>> evaluateAiCells(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    List<SheetsAiCellRequest> requests, {
    bool refresh = false,
  }) async {
    if (requests.length > aiCellBatch) {
      throw Errors.invalid('At most $aiCellBatch AI cells per request.');
    }
    final ctx = SheetsAiService.toolContext(session, actor);
    final (item, role) = await McpErrors.guard(
      () =>
          SheetsMcp.resolveItem(session, ctx, itemUuid.uuid, min: Role.viewer),
    );
    final space = item.contentRef!;
    final out = <SheetsAiCellResult>[];
    final todo = <(SheetsAiCellRequest, String)>[];
    for (final r in requests) {
      final key = aiCellKey(r.prompt, r.valuesJson);
      final hit = refresh && role >= Role.editor
          ? null
          : await AiFunctionCache.db.findFirstRow(
              session,
              where: (t) => t.key.equals(key),
            );
      if (hit != null) {
        await AiFunctionCache.db.updateRow(
          session,
          hit.copyWith(hits: hit.hits + 1),
        );
        out.add(
          SheetsAiCellResult(
            id: r.id,
            value: hit.value,
            error: hit.error,
            cached: true,
          ),
        );
      } else if (role < Role.editor) {
        out.add(SheetsAiCellResult(id: r.id, cached: false));
      } else {
        todo.add((r, key));
      }
    }
    if (todo.isEmpty) return out;

    String? quotaError;
    final count = await AiFunctionCache.db.count(
      session,
      where: (t) => t.spreadsheetUuid.equals(space),
    );
    if (count + todo.length > aiCellsPerSpreadsheet) {
      quotaError =
          'This spreadsheet has reached the limit of '
          '$aiCellsPerSpreadsheet AI cells.';
    } else {
      final today = DateTime.now().toUtc();
      final start = DateTime.utc(today.year, today.month, today.day);
      final used = await AiUsage.db.count(
        session,
        where: (t) =>
            t.userId.equals(actor.userId) &
            t.feature.equals('sheets_ai_function') &
            (t.at >= start),
      );
      if (used + todo.length > aiCellsPerUserDay) {
        quotaError =
            'You reached the daily limit of $aiCellsPerUserDay AI cell '
            'calculations. Try again tomorrow.';
      }
    }
    AiCall? ai;
    if (quotaError == null) {
      try {
        ai = await AiCall.open(session, actor);
      } on WonkyException catch (e) {
        quotaError = e.message;
      }
    }
    for (final (r, key) in todo) {
      if (quotaError != null || ai == null) {
        out.add(SheetsAiCellResult(id: r.id, error: quotaError, cached: false));
        continue;
      }
      try {
        final resp = await ai.send(
          session,
          AiRequest(
            model: ai.model(SheetsAiService.inlineTier),
            effort: SheetsAiService.inlineTier.effort,
            maxTokens: 1024,
            system: SheetsPrompts.aiFunction,
            messages: [
              ChatMessage.user(
                '${r.prompt}\n\n<sheet_data>\n'
                '${SheetsAiService.shortText(r.valuesJson, 20000)}\n</sheet_data>',
              ),
            ],
            userId: 'u${actor.userId}',
            feature: 'sheets_ai_function',
          ),
        );
        final value = resp.text.trim();
        final row = AiFunctionCache(
          key: key,
          spreadsheetUuid: space,
          model: resp.model ?? ai.model(SheetsAiService.inlineTier),
          value: value,
          createdAt: DateTime.now().toUtc(),
        );
        final old = await AiFunctionCache.db.findFirstRow(
          session,
          where: (t) => t.key.equals(key),
        );
        if (old == null) {
          await AiFunctionCache.db.insertRow(session, row);
        } else {
          await AiFunctionCache.db.updateRow(
            session,
            old.copyWith(value: value, error: null, createdAt: row.createdAt),
          );
        }
        out.add(SheetsAiCellResult(id: r.id, value: value, cached: false));
      } on WonkyException catch (e) {
        out.add(SheetsAiCellResult(id: r.id, error: e.message, cached: false));
      } on Object catch (e) {
        session.log('AI() evaluation failed: $e', level: LogLevel.warning);
        out.add(
          SheetsAiCellResult(
            id: r.id,
            error: 'The AI service returned an error.',
            cached: false,
          ),
        );
      }
    }
    return out;
  }
}
