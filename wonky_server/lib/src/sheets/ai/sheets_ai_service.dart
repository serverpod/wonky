import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show McpScope, Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/ai/ai_models.dart';
import '../../platform/ai/ai_call.dart';
import '../../platform/ai/llm/ai_client.dart';
import '../../platform/ai/prompts/sheets_prompts.dart';
import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/mcp_errors.dart';
import '../../platform/mcp/tool_support.dart';
import '../headless/headless_workbook.dart';
import '../headless/headless_workbook_provider.dart';
import '../mcp/sheets_mcp_support.dart';
import '../mcp/sheets_read_model.dart';
import '../mcp/sheets_value_handlers.dart';
import '../mcp/sheets_writes.dart';

/// The inline AI features of Wonky Sheets (Sheets 12 §6.3–6.10): formula
/// suggestion, formula explanation, Fill with AI, analysis prompt chips,
/// chart descriptions and the AI changes preview of Suggest-mode runs.
/// Model calls run here on the server with the user's provider
/// ([AiCall]); the app never sees API keys.
abstract final class SheetsAiService {
  static const fillBatch = 50;
  static const fillParallel = 2;
  static const fillMaxCells = 2000;
  static const maxPreviewCells = 200;

  static final _external = RegExp(
    r'\b(IMPORTDATA|IMPORTRANGE|IMPORTXML|IMPORTHTML|IMPORTFEED|IMAGE)\s*\(',
    caseSensitive: false,
  );

  /// The inline tier: the fast model at low effort (suite 10 rule).
  static const inlineTier = AiTier(AiModelSize.small, AiEffort.low);

  // --------------------------------------------------------------- shared

  static Future<(SheetsTarget, AiCall)> _open(
    Session session,
    Actor actor,
    UuidValue itemUuid, {
    Role min = Role.viewer,
  }) async {
    final ai = await AiCall.open(session, actor);
    final ctx = toolContext(session, actor);
    final (item, role) = await McpErrors.guard(
      () => SheetsMcp.resolveItem(session, ctx, itemUuid.uuid, min: min),
    );
    final wb = await HeadlessWorkbookProvider.open(session, item.contentRef!);
    return (SheetsTarget(item, role, wb), ai);
  }

  /// The tool context of the AI features (the user acting as AI).
  static ToolContext toolContext(Session session, Actor actor) => ToolContext(
    session: session,
    actor: actor.copyWith(kind: ActorKind.ai),
    scopes: {McpScope.sheetsRead, McpScope.sheetsEdit},
    clientName: 'Assistant',
  );

  /// [v] as text, cut to [max] characters.
  static String shortText(Object? v, [int max = 100]) {
    final s = v == null ? '' : '$v';
    return s.length <= max ? s : '${s.substring(0, max)}…';
  }

  // ----------------------------------------------------- suggest formula

  static const proposeFormulaTool = AiToolSpec(
    name: 'propose_formula',
    description:
        'Proposes the formula for the target cell. Call it exactly once.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'formula': {
          'type': 'string',
          'description': 'The formula in English syntax, starting with "=".',
        },
        'explanation': {'type': 'string'},
        'references': {
          'type': 'array',
          'items': {'type': 'string'},
        },
      },
      'required': ['formula', 'explanation', 'references'],
      'additionalProperties': false,
    },
  );

  /// The table context of a formula request: the table around (or above)
  /// the cell, sample rows, neighbor formulas and named ranges.
  static String formulaContext(
    HeadlessWorkbook wb,
    SheetModel s,
    int row,
    int col,
  ) {
    final tables = SheetsReadModel.detectTables(wb, s, max: 50);
    GridRect? table;
    for (final t in tables) {
      if (t.top <= row &&
          t.bottom >= row - 1 &&
          t.left <= col + 1 &&
          t.right >= col - 1) {
        table = t;
        break;
      }
    }
    table ??=
        tables.where((t) => t.top <= row).lastOrNull ?? tables.firstOrNull;
    final b = StringBuffer();
    b.writeln('Spreadsheet locale: ${wb.locale}');
    b.writeln('Sheet: "${s.name}"');
    b.writeln('Target cell: ${CellPos(row, col).a1}');
    if (table != null) {
      final header = SheetsReadModel.looksLikeHeader(wb, s.id, table);
      b.writeln(
        'Table: ${table.a1}${header ? ' (row ${table.top + 1} is the header)' : ''}',
      );
      final right = math.min(table.right, table.left + 25);
      final rows = <int>[
        if (header) table.top,
        for (
          var r = header ? table.top + 1 : table.top;
          r <= table.bottom && r < (header ? table.top + 6 : table.top + 5);
          r++
        )
          r,
      ];
      b.writeln('<sheet_data>');
      b.writeln(
        'row,${[for (var c = table.left; c <= right; c++) ColumnLetters.fromIndex(c)].join(',')}',
      );
      for (final r in rows) {
        b.writeln(
          '${r + 1},${[for (var c = table.left; c <= right; c++) _csv(shortText(wb.displayAt(s.id, r, c), 60))].join(',')}',
        );
      }
      b.writeln('</sheet_data>');
    }
    final neighbors = <String>[
      if (col > 0)
        if (wb.formulaAt(s.id, row, col - 1) case final String f)
          '${CellPos(row, col - 1).a1}: $f',
      if (row > 0)
        if (wb.formulaAt(s.id, row - 1, col) case final String f)
          '${CellPos(row - 1, col).a1}: $f',
    ];
    if (neighbors.isNotEmpty) {
      b.writeln('Neighbor formulas: ${neighbors.join('; ')}');
    }
    final names = [
      for (final n in wb.model.namedRanges.take(30))
        if (n.rangeJson != null)
          if (GridRange.tryParse(n.rangeJson) case final GridRange g)
            if (wb.model.resolve(g) case final ResolvedRange rr)
              '${n.name} = ${wb.model.a1Of(rr)}',
    ];
    if (names.isNotEmpty) b.writeln('Named ranges: ${names.join('; ')}');
    return b.toString();
  }

  static String _csv(String s) =>
      s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;

  static (String, String, List<String>)? _proposal(AiResponse r) {
    for (final call in r.toolCalls) {
      if (call.toolName != proposeFormulaTool.name) continue;
      final f = call.arguments?['formula'];
      if (f is! String || f.trim().isEmpty) continue;
      final refs = call.arguments?['references'];
      return (
        f.trim(),
        '${call.arguments?['explanation'] ?? ''}',
        [
          if (refs is List)
            for (final x in refs) '$x',
        ],
      );
    }
    // Fallback: a formula in the text (Sheets 12 §6.4 step 2).
    final f = extractFormula(r.text);
    return f == null ? null : (f, '', const <String>[]);
  }

  /// The longest formula-looking text in [text] that parses ("Use
  /// =SUM(A1:A3) here" → "=SUM(A1:A3)").
  static String? extractFormula(String text) {
    for (final m in RegExp(r'=[A-Za-z_][^\n`]*').allMatches(text)) {
      var candidate = m.group(0)!.trim();
      while (candidate.length > 1) {
        if (validateFormula(candidate).ok) return candidate;
        final cut = candidate.lastIndexOf(RegExp(r'[\s,;.]'));
        if (cut <= 0) break;
        candidate = candidate.substring(0, cut).trimRight();
      }
    }
    return null;
  }

  /// Proposes a formula for [cell] from [prompt] (Sheets 12 §6.4): never
  /// writes; the app inserts it with `sheets.edit.setCellInput`.
  static Future<SheetsFormulaSuggestion> suggestFormula(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String cell,
    String prompt,
  ) async {
    final text = prompt.trim();
    if (text.isEmpty) throw Errors.invalid('Describe the formula you need.');
    if (text.length > 2000) throw Errors.tooLarge('The request is too long.');
    final (t, ai) = await _open(session, actor, itemUuid);
    final r = McpErrors.guardSync(() => SheetsMcp.range(t, cell));
    final s = t.model.sheet(r.sheetId)!;
    final row = r.rect.top, col = r.rect.left;
    final messages = <ChatMessage>[
      ChatMessage.user(
        '${formulaContext(t.wb, s, row, col)}\n<request>${shortText(text, 2000)}</request>\n'
        'Answer with the propose_formula tool.',
      ),
    ];
    SheetsFormulaSuggestion? last;
    for (var attempt = 0; attempt < 2; attempt++) {
      final response = await ai.send(
        session,
        AiRequest(
          model: ai.model(inlineTier),
          effort: inlineTier.effort,
          maxTokens: 4000,
          system: SheetsPrompts.formulaSuggest,
          tools: const [proposeFormulaTool],
          messages: messages,
          userId: 'u${actor.userId}',
          feature: 'sheets_formula',
        ),
      );
      final p = _proposal(response);
      if (p == null) {
        throw WonkyException(
          code: WonkyErrorCode.unavailable,
          message: 'The assistant did not propose a formula. Try again.',
        );
      }
      last = _evaluateProposal(t.wb, s, row, col, p.$1, p.$2, p.$3);
      final retry =
          last.errorMessage != null &&
          (last.previewType == null || '${last.previewValue}' == '#NAME?');
      if (!retry || attempt == 1) break;
      messages
        ..add(response.message)
        ..add(
          ChatMessage(
            role: ChatMessageRole.user,
            parts: [
              for (final c in response.toolCalls)
                ToolPart.result(
                  callId: c.callId,
                  toolName: c.toolName,
                  result: jsonEncode({'error': last.errorMessage}),
                ),
              TextPart(
                'That formula failed: ${last.errorMessage}. Propose a '
                'corrected formula with propose_formula.',
              ),
            ],
          ),
        );
    }
    return last!;
  }

  static SheetsFormulaSuggestion _evaluateProposal(
    HeadlessWorkbook wb,
    SheetModel s,
    int row,
    int col,
    String formula,
    String explanation,
    List<String> references,
  ) {
    final text = formula.startsWith('=') ? formula : '=$formula';
    final check = validateFormula(text);
    if (!check.ok) {
      return SheetsFormulaSuggestion(
        formula: text,
        localizedFormula: text,
        explanation: explanation,
        references: references,
        errorMessage: check.error?.message ?? 'Formula parse error.',
        usesExternalData: _external.hasMatch(text),
      );
    }
    final stored = wb.hooks.toStored(text, sheetId: s.id, row: row, col: col);
    final localized = wb.hooks.toA1(
      stored,
      sheetId: s.id,
      row: row,
      col: col,
      locale: wb.locale,
    );
    final v = wb.engine.evaluateStored(
      stored,
      sheetId: s.id,
      row: row,
      col: col,
    );
    final cv = v.toCellValue();
    final unknown = check.unknownFunctions;
    String? error;
    if (unknown.isNotEmpty) {
      error = 'Unknown function(s): ${unknown.join(', ')}';
    } else if (v is FError) {
      error = '${v.kind.literal}${v.message == null ? '' : ': ${v.message}'}';
    }
    return SheetsFormulaSuggestion(
      formula: text,
      localizedFormula: localized,
      explanation: explanation,
      references: references.isEmpty ? check.references : references,
      previewValue: v is FArray
          ? '${wb.display.displayText(cv, null)} (array ${v.rows}×${v.cols})'
          : wb.display.displayText(cv, null),
      previewType: switch (v) {
        FArray() => 'array',
        FNumber() => 'number',
        FBool() => 'bool',
        FError() => 'error',
        _ => 'text',
      },
      errorMessage: error,
      usesExternalData: _external.hasMatch(text),
    );
  }

  // ----------------------------------------------------- explain formula

  /// The explanation request of the formula in [cell] (Sheets 12 §6.5):
  /// the formula, the referenced ranges' headers and samples and the
  /// evaluation trace (≤ 50 nodes). No tools.
  static String explainMessage(
    HeadlessWorkbook wb,
    SheetModel s,
    int row,
    int col,
  ) {
    final formula = wb.formulaAt(s.id, row, col);
    if (formula == null) {
      throw Errors.invalid('${CellPos(row, col).a1} has no formula.');
    }
    final b = StringBuffer()
      ..writeln(
        'Cell: ${wb.model.a1Of(ResolvedRange(s.id, GridRect.cell(row, col)))}',
      )
      ..writeln('Formula: $formula')
      ..writeln(
        '<sheet_data>Result: ${shortText(wb.displayAt(s.id, row, col))}</sheet_data>',
      );
    final check = validateFormula(formula);
    for (final ref in check.references.take(10)) {
      try {
        final rr = wb.model.parseA1(ref, contextSheetId: s.id);
        final rs = wb.model.sheet(rr.sheetId)!;
        final rect = SheetsMcp.clipToUsed(rs, rr);
        final top = rect.top > 0 ? rect.top - 1 : rect.top;
        b.writeln('Range $ref:');
        b.writeln('<sheet_data>');
        for (var r = top; r <= math.min(rect.bottom, top + 5); r++) {
          b.writeln(
            '${r + 1}: ${[for (var c = rect.left; c <= math.min(rect.right, rect.left + 9); c++) _csv(shortText(wb.displayAt(rs.id, r, c), 40))].join(',')}',
          );
        }
        b.writeln('</sheet_data>');
      } on Object {
        continue;
      }
    }
    final node = explainCell(wb.engine, s.id, row, col);
    if (node != null) {
      var budget = 50;
      Map<String, Object?>? prune(Map<String, Object?> n) {
        if (budget <= 0) return null;
        budget--;
        final children = (n['children'] as List?)?.cast<Map<String, Object?>>();
        return {
          ...n..remove('range'),
          if (children != null)
            'children': [
              for (final c in children)
                if (prune(c) case final Map<String, Object?> p) p,
            ],
        };
      }

      b
        ..writeln('Evaluation trace:')
        ..writeln(
          '<sheet_data>${jsonEncode(prune(node.toJson()))}</sheet_data>',
        );
    }
    return b.toString();
  }

  /// Streams a plain-language explanation of the formula in [cell].
  static Future<Stream<InlineAiEvent>> explainFormula(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String cell,
  ) async {
    final (t, ai) = await _open(session, actor, itemUuid);
    final r = McpErrors.guardSync(() => SheetsMcp.range(t, cell));
    final s = t.model.sheet(r.sheetId)!;
    final message = explainMessage(t.wb, s, r.rect.top, r.rect.left);
    final quality = await ai.quality(session);
    final tier = AiTier.document(quality);
    final request = AiRequest(
      model: ai.model(tier),
      effort: tier.effort,
      maxTokens: 8000,
      system: SheetsPrompts.explainFormula,
      messages: [ChatMessage.user(message)],
      userId: 'u${actor.userId}',
      feature: 'sheets_explain',
    );
    return ai.stream(
      session,
      (s2, cancel, emit) async {
        final msg = await ai.send(
          s2,
          request,
          cancel: cancel,
          onText: (d) =>
              emit(InlineAiEvent(type: InlineAiEventType.textDelta, text: d)),
        );
        emit(
          InlineAiEvent(
            type: InlineAiEventType.done,
            markdown: msg.text.trim(),
          ),
        );
      },
      onFailure: (f) => f.inlineEvent,
    );
  }

  // -------------------------------------------------------------- fill

  static const fillValuesTool = AiToolSpec(
    name: 'fill_values',
    description: 'Returns a value for every row to fill. Call it exactly once.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'rows': {
          'type': 'array',
          'items': {
            'type': 'object',
            'properties': {
              'row': {'type': 'integer'},
              'value': {
                'type': ['string', 'number', 'boolean', 'null'],
              },
              'confidence': {
                'type': 'string',
                'enum': ['low', 'medium', 'high'],
              },
            },
            'required': ['row', 'value', 'confidence'],
            'additionalProperties': false,
          },
        },
      },
      'required': ['rows'],
      'additionalProperties': false,
    },
  );

  /// Proposals for the empty cells of a column range (Sheets 12 §6.6).
  static Future<SheetsFillProposal> fillRange(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String range,
    String? instructions,
  ) async {
    final (t, ai) = await _open(
      session,
      actor,
      itemUuid,
      min: Role.editor,
    );
    final rr = McpErrors.guardSync(() => SheetsMcp.range(t, range));
    final s = t.model.sheet(rr.sheetId)!;
    final rect = SheetsMcp.clipToUsed(s, rr);
    if (rect.colCount != 1) {
      throw Errors.invalid('Select one column to fill.');
    }
    final col = rect.left;
    final table = SheetsReadModel.detectTables(t.wb, s, max: 100)
        .where(
          (x) => x.contains(rect.top, col) || x.intersects(rect),
        )
        .firstOrNull;
    final header =
        table != null && SheetsReadModel.looksLikeHeader(t.wb, s.id, table);
    final headerRow = header ? table.top : null;
    final top = headerRow != null && rect.top <= headerRow
        ? headerRow + 1
        : rect.top;
    final bottom = math.max(rect.bottom, table?.bottom ?? rect.bottom);
    // Source columns: the table's other columns (max 10, nearest first).
    final sources = <int>[
      if (table != null)
        for (var c = table.left; c <= table.right; c++)
          if (c != col) c,
    ]..sort((a, b) => (a - col).abs().compareTo((b - col).abs()));
    final inputs = sources.take(10).toList()..sort();
    String label(int c) => headerRow == null
        ? ColumnLetters.fromIndex(c)
        : '${ColumnLetters.fromIndex(c)} "${shortText(t.wb.displayAt(s.id, headerRow, c), 40)}"';
    String inputsOf(int r) => [
      for (final c in inputs)
        '${label(c)}=${shortText(t.wb.displayAt(s.id, r, c), 80)}',
    ].join('; ');

    final examples = <int>[];
    final empty = <int>[];
    for (var r = top; r <= bottom; r++) {
      final hasInput = inputs.any(
        (c) => t.wb.valueAt(s.id, r, c) is! EmptyValue,
      );
      if (t.wb.valueAt(s.id, r, col) is EmptyValue) {
        if (hasInput && r <= rect.bottom) empty.add(r);
      } else {
        examples.add(r);
      }
    }
    if (examples.isEmpty) {
      throw Errors.invalid(
        'Type at least one example value in the column first (three work '
        'best).',
      );
    }
    final truncated = empty.length > fillMaxCells;
    final todo = empty.take(fillMaxCells).toList();
    final exampleText = StringBuffer('<sheet_data>\n');
    for (final r in examples.take(20)) {
      exampleText.writeln(
        'row ${r + 1}: ${inputsOf(r)} → ${shortText(t.wb.displayAt(s.id, r, col), 200)}',
      );
    }
    exampleText.write('</sheet_data>');
    final targetHeader = headerRow == null
        ? ColumnLetters.fromIndex(col)
        : t.wb.displayAt(s.id, headerRow, col);
    final batches = <List<int>>[
      for (var i = 0; i < todo.length; i += fillBatch)
        todo.sublist(i, math.min(i + fillBatch, todo.length)),
    ];
    final results = <int, (Object?, String)>{};
    Future<void> runBatch(List<int> batch) async {
      final rowsText = StringBuffer('<sheet_data>\n');
      for (final r in batch) {
        rowsText.writeln('row ${r + 1}: ${inputsOf(r)}');
      }
      rowsText.write('</sheet_data>');
      final response = await ai.send(
        session,
        AiRequest(
          model: ai.model(inlineTier),
          effort: inlineTier.effort,
          maxTokens: 16000,
          system: SheetsPrompts.fill,
          tools: const [fillValuesTool],
          messages: [
            ChatMessage.user(
              'Column to fill: ${label(col)} ("${shortText(targetHeader, 60)}")\n'
              '${instructions == null || instructions.trim().isEmpty ? '' : '<instructions>${shortText(instructions.trim(), 1000)}</instructions>\n'}'
              'Examples:\n$exampleText\nRows to fill:\n$rowsText\n'
              'Answer with fill_values; "row" is the row number shown.',
            ),
          ],
          userId: 'u${actor.userId}',
          feature: 'sheets_fill',
        ),
      );
      final wanted = {for (final r in batch) r + 1};
      for (final call in response.toolCalls) {
        if (call.toolName != fillValuesTool.name) continue;
        final rows = call.arguments?['rows'];
        if (rows is! List) continue;
        for (final e in rows) {
          if (e is! Map) continue;
          final n = (e['row'] as num?)?.toInt();
          if (n == null || !wanted.contains(n)) continue;
          final conf = '${e['confidence'] ?? 'low'}';
          results[n - 1] = (
            e['value'],
            const {'low', 'medium', 'high'}.contains(conf) ? conf : 'low',
          );
        }
      }
    }

    for (var i = 0; i < batches.length; i += fillParallel) {
      await Future.wait([
        for (final b in batches.skip(i).take(fillParallel)) runBatch(b),
      ]);
    }
    return SheetsFillProposal(
      range: SheetsMcp.a1(t.model, s.id, GridRect(top, col, rect.bottom, col)),
      header: headerRow == null ? null : targetHeader,
      examples: examples.length,
      rows: [
        for (final r in todo)
          SheetsFillRow(
            cell: SheetsMcp.cellA1(t.model, s.id, r, col),
            row: r + 1,
            inputs: shortText(inputsOf(r), 200),
            value: results[r]?.$1?.toString(),
            confidence: results[r]?.$2 ?? 'low',
          ),
      ],
      truncated: truncated,
    );
  }

  /// Writes accepted Fill with AI values (user-entered semantics) as one
  /// undo step "AI: Fill …" (Sheets 12 §6.6).
  static Future<SheetsAiApplyResult> applyFill(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String range,
    List<SheetsFillRow> rows,
  ) async {
    final ctx = toolContext(session, actor);
    final t = await McpErrors.guard(
      () => SheetsMcp.open(
        ctx,
        ToolArgs({'spreadsheet': itemUuid.uuid}),
        min: Role.editor,
      ),
    );
    final accepted = [
      for (final r in rows)
        if (r.value != null) r,
    ];
    if (accepted.length > fillMaxCells) {
      throw Errors.tooLarge('At most $fillMaxCells cells per fill.');
    }
    final cells = <(String, int, int, String)>[];
    for (final r in accepted) {
      final rr = McpErrors.guardSync(() => SheetsMcp.range(t, r.cell));
      cells.add((rr.sheetId, rr.rect.top, rr.rect.left, r.value!));
    }
    final label = 'AI: Fill $range';
    final o = await McpErrors.guard(
      () => SheetsWrites.run(
        ctx,
        t,
        tool: 'sheets.ai.fillRange',
        label: label,
        ranges: [range],
        steps: [
          for (final (sheetId, row, col, value) in cells)
            (model, pctx) => SheetsWrites.planner.plan(
              SetCellInputs(
                sheetId: sheetId,
                row: row,
                col: col,
                inputs: SheetsValueHandlers.inputs(
                  t.wb,
                  sheetId,
                  row,
                  col,
                  [
                    [value],
                  ],
                  raw: false,
                ),
                label: label,
              ),
              model,
              pctx,
            ),
        ],
      ),
    );
    return SheetsAiApplyResult(
      changeId: o.changeId,
      label: label,
      cellsAffected: o.cellsAffected,
      skipped: o.skipped,
    );
  }

  // -------------------------------------------------- chips and charts

  /// Prompt chips of *Data › Analyze with AI* from `describe_data`
  /// (Sheets 12 §6.7). Deterministic; no model call.
  static Future<List<String>> analyzeChips(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String? range,
  ) async {
    final ctx = toolContext(session, actor);
    final t = await McpErrors.guard(
      () => SheetsMcp.open(ctx, ToolArgs({'spreadsheet': itemUuid.uuid})),
    );
    SheetModel s;
    GridRect? rect;
    if (range != null) {
      final rr = McpErrors.guardSync(() => SheetsMcp.range(t, range));
      s = t.model.sheet(rr.sheetId)!;
      rect = SheetsMcp.clipToUsed(s, rr);
    } else {
      s = McpErrors.guardSync(() => SheetsMcp.sheetOrFirst(t, null));
      rect = SheetsReadModel.detectTables(t.wb, s).firstOrNull;
    }
    final chips = ['Summarize this table', 'Find anomalies'];
    if (rect == null) return chips;
    final d = SheetsReadModel.describe(
      t.wb,
      s,
      rect,
      sampleRows: 0,
      includeTables: false,
    );
    final cols = (d['columns'] as List).cast<Map<String, Object?>>();
    String? name(Map<String, Object?> c) =>
        (c['header'] as String?) ?? 'column ${c['column']}';
    final measure = cols.where((c) => c['type'] == 'number').firstOrNull;
    final dimension = cols
        .where(
          (c) =>
              (c['type'] == 'text' || c['type'] == 'date') &&
              (c['distinct'] as int) > 1 &&
              (c['distinct'] as int) < (c['non_empty'] as int),
        )
        .firstOrNull;
    if (measure != null && dimension != null) {
      chips.add(
        'Create a pivot table of ${name(measure)} by ${name(dimension)}',
      );
      chips.add('Make a chart of ${name(measure)} by ${name(dimension)}');
    } else {
      chips.add('Make a chart');
    }
    return chips;
  }

  /// Alt text for a chart (Sheets 12 §6.10) from its spec and data
  /// summary; nothing is written.
  static Future<String> describeChart(
    Session session,
    Actor actor,
    UuidValue itemUuid,
    String chartId,
  ) async {
    final (t, ai) = await _open(session, actor, itemUuid);
    EmbeddedObjectRecord? chart;
    for (final s in t.model.sheets) {
      chart ??= s.objects[chartId];
    }
    if (chart == null) throw Errors.notFound('Chart');
    final spec = ChartSpec.fromJson(chart.specJson);
    final data = ChartDataResolver.resolve(
      spec,
      t.model,
      t.wb.engine,
      locale: t.wb.locale,
    );
    final summary = StringBuffer()
      ..writeln('Type: ${spec.type.displayName}')
      ..writeln(
        'Title: ${shortText(spec.title.text.isEmpty ? chart.title : spec.title.text)}',
      )
      ..writeln('Automatic description: ${ChartDescriber.describe(spec, data)}')
      ..writeln('Categories (${data.domain.name}): ${data.pointCount}')
      ..writeln('<sheet_data>');
    for (final se in data.series.take(10)) {
      final values = se.values.take(40).map((v) => v.isNaN ? '' : '$v');
      summary.writeln('${shortText(se.name, 60)}: ${values.join(', ')}');
    }
    summary.write('</sheet_data>');
    final r = await ai.send(
      session,
      AiRequest(
        model: ai.model(inlineTier),
        effort: inlineTier.effort,
        maxTokens: 1000,
        system: SheetsPrompts.describeChart,
        messages: [ChatMessage.user(summary.toString())],
        userId: 'u${actor.userId}',
        feature: 'sheets_describe_chart',
      ),
    );
    final text = r.text.trim();
    return text.length <= 300 ? text : '${text.substring(0, 297)}…';
  }
}
