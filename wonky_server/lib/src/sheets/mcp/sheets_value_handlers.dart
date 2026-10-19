import 'dart:convert';
import 'dart:math' as math;

import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    as core
    show CellInput;

import '../../platform/mcp/tool_support.dart';
import '../headless/headless_workbook.dart';
import '../headless/sheets_core_internal.dart';
import 'sheets_mcp_support.dart';
import 'sheets_read_handlers.dart';
import 'sheets_read_model.dart';
import 'sheets_writes.dart';

/// The value-writing `sheets.*` tools (Sheets 12 §3.2, §3.7, §3.11, §3.13).
abstract final class SheetsValueHandlers {
  // --------------------------------------------------------------- inputs

  static int _cellCount(List<Object?> values) =>
      values.fold(0, (n, r) => n + (r is List ? r.length : 0));

  /// Checks the per-call write limit (Sheets 12 §3.14).
  static void checkWriteLimit(int cells) {
    if (cells > SheetsLimits.cellsWrittenPerCall) {
      throw McpToolException.limit(
        'At most ${SheetsLimits.cellsWrittenPerCall} cells can be written per '
        'call ($cells given). Split the data into several calls.',
        limit: 'cells_written_per_call',
        max: SheetsLimits.cellsWrittenPerCall,
      );
    }
  }

  /// Validates the formulas of [values] (English syntax) before writing.
  static void checkFormulas(List<Object?> values, {required bool raw}) {
    if (raw) return;
    for (var r = 0; r < values.length; r++) {
      final row = values[r];
      if (row is! List) continue;
      for (var c = 0; c < row.length; c++) {
        final v = row[c];
        if (v is! String || v.length < 2 || !v.startsWith('=')) continue;
        final check = validateFormula(v);
        if (!check.ok) {
          throw McpToolException(
            SheetsErrorCode.formulaParseError,
            'values[$r][$c]: ${check.error?.message ?? 'Formula parse error.'}',
            details: {
              'row': r,
              'column': c,
              'formula': v,
              'position': (check.error?.offset ?? 0) + 1,
            },
          );
        }
      }
    }
  }

  /// Cell inputs of [values] written at ([top], [left]) of [sheetId]:
  /// `=formulas` are encoded with the English syntax at their target cell
  /// (Sheets 12 §1.7); other strings are parsed like typing (spreadsheet
  /// locale or [parseLocale]) unless [raw].
  static List<List<core.CellInput>> inputs(
    HeadlessWorkbook wb,
    String sheetId,
    int top,
    int left,
    List<Object?> values, {
    required bool raw,
  }) => [
    for (var r = 0; r < values.length; r++)
      [
        for (final (c, v) in ((values[r] as List?) ?? const []).indexed)
          _input(wb, sheetId, top + r, left + c, v, raw: raw),
      ],
  ];

  static core.CellInput _input(
    HeadlessWorkbook wb,
    String sheetId,
    int row,
    int col,
    Object? v, {
    required bool raw,
  }) {
    if (v == null) return const core.CellInput.content(null);
    if (raw || v is! String) return core.CellInput.raw(v);
    if (v.length > 1 && v.startsWith('=')) {
      final stored = wb.hooks.toStored(
        v,
        sheetId: sheetId,
        row: row,
        col: col,
      );
      return core.CellInput.content(
        FormulaContent(stored.startsWith('=') ? stored : '=$stored'),
      );
    }
    return core.CellInput.user(v);
  }

  /// Cells overwritten by [plans] that had content before (AI guard).
  static int overwrittenNonEmpty(List<MutationPlan> plans) {
    var n = 0;
    for (final p in plans) {
      for (final c in p.changes) {
        if (c.table != SheetsTables.cell) continue;
        if (c.op == RowOp.delete && c.columnsBefore[CellCols.content] != null) {
          n++;
        } else if (c.op == RowOp.update &&
            c.columnsAfter.containsKey(CellCols.content) &&
            c.columnsBefore[CellCols.content] != null) {
          n++;
        }
      }
    }
    return n;
  }

  static String? _confirmCells(List<MutationPlan> plans, String what) {
    final n = overwrittenNonEmpty(plans);
    return n > SheetsLimits.aiNonEmptyCells
        ? 'The assistant wants to $what $n non-empty cells.'
        : null;
  }

  static SheetsPlanStep _setStep(
    HeadlessWorkbook wb,
    String Function() sheetId,
    int top,
    int left,
    List<Object?> values, {
    required bool raw,
    String? parseLocale,
    String? label,
  }) =>
      (model, pctx) => SheetsWrites.planner.plan(
        SetCellInputs(
          sheetId: sheetId(),
          row: top,
          col: left,
          inputs: inputs(wb, sheetId(), top, left, values, raw: raw),
          parseLocale: parseLocale,
          growGrid: true,
          label: label,
        ),
        model,
        pctx,
      );

  static Map<String, Object?> _result(
    SheetsWriteOutcome o, {
    Map<String, Object?> extra = const {},
  }) => {...extra, ...o.toJson()};

  static ToolResult _toolResult(
    SheetsWriteOutcome o,
    String summary, {
    Map<String, Object?> extra = const {},
  }) {
    final out = {..._result(o, extra: extra), 'summary': summary};
    final id = o.changeId?.uuid;
    return ToolResult(
      out,
      text:
          '$summary'
          '${o.preview ? ' (suggested, not applied)' : ''}'
          '${id == null ? '' : ' · change_id $id'}'
          '${o.warnings.isEmpty ? '' : '\nWarnings: ${o.warnings.join(' ')}'}',
    );
  }

  // ----------------------------------------------------------- set values

  static Future<ToolResult> setValues(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final values = a.list('values')!;
    final raw = a.string('input') == 'raw';
    checkWriteLimit(_cellCount(values));
    checkFormulas(values, raw: raw);
    final r = SheetsMcp.range(t, a.requireString('range'));
    final height = values.length;
    final width = values.fold<int>(
      0,
      (w, row) => math.max<int>(w, (row as List).length),
    );
    if (!r.rect.isSingleCell && !r.wholeColumns && !r.wholeRows) {
      if (height != r.rect.rowCount || width != r.rect.colCount) {
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'The range ${a.string('range')} is ${r.rect.rowCount}×'
          '${r.rect.colCount} but values are $height×$width. Pass the '
          'top-left cell only to write values of any size.',
        );
      }
    }
    final s = t.model.sheet(r.sheetId)!;
    final top = r.rect.top, left = r.rect.left;
    final written = GridRect(
      top,
      left,
      top + math.max<int>(height, 1) - 1,
      left + math.max<int>(width, 1) - 1,
    );
    final writtenA1 = SheetsMcp.a1(t.model, s.id, written);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.set_values',
      label: SheetsMcp.label(ctx, 'sheets.set_values', writtenA1),
      ranges: [writtenA1],
      steps: [
        _setStep(
          t.wb,
          () => s.id,
          top,
          left,
          values,
          raw: raw,
          parseLocale: a.string('parse_locale'),
        ),
      ],
      confirmIf: (plans, _) => _confirmCells(plans, 'overwrite'),
    );
    final dv = o.preview
        ? const <String>[]
        : SheetsWrites.validationWarnings(t.wb, s.id, [written]);
    return _toolResult(
      o,
      'Wrote ${o.cellsAffected} cell(s) to $writtenA1',
      extra: {'updated_range': writtenA1, 'validation_warnings': dv},
    );
  }

  static Future<ToolResult> batchSetValues(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final data = a.list('data')!.cast<Map<String, dynamic>>();
    final raw = a.string('input') == 'raw';
    var total = 0;
    for (final d in data) {
      final v = (d['values'] as List).cast<Object?>();
      total += _cellCount(v);
      checkFormulas(v, raw: raw);
    }
    checkWriteLimit(total);
    final steps = <SheetsPlanStep>[];
    final written = <(String, GridRect)>[];
    for (final d in data) {
      final r = SheetsMcp.range(t, d['range'] as String);
      final values = (d['values'] as List).cast<Object?>();
      final width = values.fold<int>(
        0,
        (w, row) => math.max<int>(w, (row as List).length),
      );
      written.add((
        r.sheetId,
        GridRect(
          r.rect.top,
          r.rect.left,
          r.rect.top + math.max<int>(values.length, 1) - 1,
          r.rect.left + math.max<int>(width, 1) - 1,
        ),
      ));
      steps.add(
        _setStep(
          t.wb,
          () => r.sheetId,
          r.rect.top,
          r.rect.left,
          values,
          raw: raw,
          parseLocale: a.string('parse_locale'),
        ),
      );
    }
    final a1s = [
      for (final (s, rect) in written) SheetsMcp.a1(t.model, s, rect),
    ];
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.batch_set_values',
      label: SheetsMcp.label(
        ctx,
        'sheets.batch_set_values',
        a1s.length == 1 ? a1s.first : '${a1s.length} ranges',
      ),
      ranges: a1s,
      steps: steps,
      confirmIf: (plans, _) => _confirmCells(plans, 'overwrite'),
    );
    final dv = <String>[
      if (!o.preview)
        for (final (s, rect) in written)
          ...SheetsWrites.validationWarnings(t.wb, s, [rect]),
    ];
    return _toolResult(
      o,
      'Wrote ${o.cellsAffected} cell(s) to ${a1s.join(', ')}',
      extra: {
        'updated_ranges': a1s,
        'validation_warnings': dv.take(100).toList(),
      },
    );
  }

  // ----------------------------------------------------------- append rows

  /// The table [r] belongs to (or the first one after it), else null.
  static GridRect? tableFor(
    HeadlessWorkbook wb,
    SheetModel s,
    ResolvedRange r,
  ) {
    final tables = SheetsReadModel.detectTables(wb, s, max: 1000);
    if (r.wholeColumns && r.wholeRows) {
      return tables.isEmpty ? null : tables.first;
    }
    final top = r.rect.top, left = r.rect.left;
    for (final t in tables) {
      if (t.intersects(r.rect) || t.contains(top, left)) return t;
    }
    for (final t in tables) {
      if (t.top >= top && t.right >= left && t.left <= r.rect.right) return t;
    }
    return null;
  }

  static Future<ToolResult> appendRows(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final values = a.list('values')!;
    final raw = a.string('input') == 'raw';
    checkWriteLimit(_cellCount(values));
    checkFormulas(values, raw: raw);
    final r = SheetsMcp.range(t, a.requireString('range'));
    final s = t.model.sheet(r.sheetId)!;
    final table = tableFor(t.wb, s, r);
    final top = table == null ? r.rect.top : table.bottom + 1;
    final left = table?.left ?? r.rect.left;
    final width = values.fold<int>(
      0,
      (w, row) => math.max<int>(w, (row as List).length),
    );
    final written = GridRect(
      top,
      left,
      top + math.max<int>(values.length, 1) - 1,
      left + math.max<int>(width, 1) - 1,
    );
    final writtenA1 = SheetsMcp.a1(t.model, s.id, written);
    final insert = a.boolean('insert_rows') ?? false;
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.append_rows',
      label: SheetsMcp.label(ctx, 'sheets.append_rows', writtenA1),
      ranges: [writtenA1],
      steps: [
        if (insert && top < s.rows.length)
          (model, pctx) => SheetsWrites.planner.plan(
            InsertDimension(
              s.id,
              Dimension.rows,
              top,
              values.length,
              inheritFrom: InheritFrom.before,
            ),
            model,
            pctx,
          ),
        _setStep(
          t.wb,
          () => s.id,
          top,
          left,
          values,
          raw: raw,
          parseLocale: a.string('parse_locale'),
        ),
      ],
    );
    return _toolResult(
      o,
      'Appended ${values.length} row(s) at $writtenA1',
      extra: {
        'table_range': table == null
            ? null
            : SheetsMcp.a1(t.model, s.id, table),
        'updated_range': writtenA1,
        'validation_warnings': o.preview
            ? const <String>[]
            : SheetsWrites.validationWarnings(t.wb, s.id, [written]),
      },
    );
  }

  // ---------------------------------------------------------------- clear

  static Future<ToolResult> clearRange(
    ToolContext ctx,
    ToolArgs a, {
    String? forceWhat,
    String tool = 'sheets.clear_range',
  }) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final what = switch (forceWhat ?? a.string('what')) {
      'formats' => ClearWhat.formats,
      'all' => ClearWhat.all,
      'notes' => ClearWhat.notes,
      'validation' => ClearWhat.validation,
      _ => ClearWhat.contents,
    };
    final ranges = [
      for (final r in a.list('ranges')!.cast<String>()) SheetsMcp.range(t, r),
    ];
    var existing = 0;
    for (final r in ranges) {
      final s = t.model.sheet(r.sheetId)!;
      existing += s.cellsIn(r.rect).length;
    }
    if (existing > SheetsLimits.cellsClearedPerCall) {
      throw McpToolException.limit(
        'At most ${SheetsLimits.cellsClearedPerCall} cells can be cleared per '
        'call.',
        limit: 'cells_cleared_per_call',
        max: SheetsLimits.cellsClearedPerCall,
      );
    }
    final a1s = [for (final r in ranges) t.model.a1Of(r)];
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: tool,
      label: SheetsMcp.label(ctx, tool, a1s.join(', ')),
      ranges: a1s,
      steps: [
        (model, pctx) => SheetsWrites.planner.plan(
          ClearRanges(ranges, what: what),
          model,
          pctx,
        ),
      ],
      confirmIf: (plans, _) => _confirmCells(plans, 'clear'),
    );
    return _toolResult(o, 'Cleared ${what.name} of ${a1s.join(', ')}');
  }

  // ------------------------------------------------------- find / replace

  static Future<ToolResult> findReplace(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final q = SheetsReadHandlers.query(t, a);
    final replacement = a.requireString('replacement');
    final userId = ctx.actor.authUserId.uuid;
    var replaced = 0;
    var skippedProtected = 0;
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.find_replace',
      label: SheetsMcp.label(
        ctx,
        'sheets.find_replace',
        '"${q.query}" → "$replacement"',
      ),
      steps: [
        (model, pctx) {
          try {
            final plan = SheetsWrites.planner.plan(
              FindReplace(
                find: q.query,
                replacement: replacement,
                sheetIds: q.scope == FindScope.sheet ? [q.sheetId!] : null,
                range: q.scope == FindScope.range
                    ? ResolvedRange(q.sheetId!, q.range!)
                    : null,
                matchCase: q.matchCase,
                matchEntireCell: q.entireCell,
                useRegex: q.regex,
                searchFormulas: q.searchFormulas,
              ),
              model,
              pctx,
            );
            replaced = (plan.result['replaced'] as num?)?.toInt() ?? 0;
            skippedProtected =
                (plan.result['skippedProtected'] as num?)?.toInt() ?? 0;
            return plan;
          } on PlanException catch (e) {
            if (e.code != 'unsupported') rethrow;
          }
          final engine = SheetsReadHandlers.findEngine(t);
          final FindResult found;
          try {
            found = engine.find(q, includeStart: true);
          } on FindPatternException catch (e) {
            throw McpToolException(McpErrorCode.invalidArgs, e.message);
          }
          final guard = ProtectionGuard(model);
          final plan = ReplaceEngine(engine).plan(
            q,
            replacement,
            found.matches,
            canEdit: (sheetId, row, col) => !guard
                .check(
                  CellWrites(sheetId, [GridRect.cell(row, col)]),
                  userId,
                  isOwner: t.isOwner,
                )
                .isBlocked,
          );
          replaced = plan.instanceCount;
          skippedProtected = plan.protectedCount;
          return _replacePlan(t.wb, model, pctx, plan.replacements);
        },
      ],
      confirmIf: (plans, _) {
        final n = plans.fold(0, (s, p) => s + p.cellCount);
        return n > SheetsLimits.aiNonEmptyCells
            ? 'The assistant wants to replace text in $n cells.'
            : null;
      },
    );
    return _toolResult(
      o,
      'Replaced $replaced occurrence(s) in ${o.cellsAffected} cell(s)'
      '${skippedProtected == 0 ? '' : '; $skippedProtected protected cell(s) skipped'}',
      extra: {
        'replaced': replaced,
        'cells_changed': o.cellsAffected,
        'skipped_protected': skippedProtected,
      },
    );
  }

  static MutationPlan _replacePlan(
    HeadlessWorkbook wb,
    WorkbookModel model,
    PlanContext pctx,
    List<CellReplacement> replacements,
  ) {
    final b = PlanBuilder(model, pctx);
    for (final r in replacements) {
      final s = b.sheetOf(r.sheetId);
      final rowId = s.rows.idAt(r.row);
      final colId = s.columns.idAt(r.col);
      Map<String, Object?> cols;
      if (r.newFormulaA1 != null) {
        final stored = wb.hooks.toStored(
          r.newFormulaA1!,
          sheetId: s.id,
          row: r.row,
          col: r.col,
          locale: b.locale,
        );
        cols = {CellCols.content: stored.startsWith('=') ? stored : '=$stored'};
      } else if (r.newRichText != null) {
        cols = {CellCols.content: RichTextContent(r.newRichText!).encode()};
      } else if (r.newLinkUrl != null) {
        cols = {CellCols.linkUrl: r.newLinkUrl};
      } else {
        cols = inputColumns(
          b,
          s,
          rowId,
          colId,
          r.row,
          r.col,
          core.CellInput.user(r.newEditText ?? ''),
        );
      }
      b.writeCell(s.id, rowId, colId, cols);
    }
    return b.build('Find and replace', kinds: [ChangeKinds.values]);
  }

  // ----------------------------------------------------------------- sort

  static Future<ToolResult> sortRange(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    final r = SheetsMcp.range(t, a.requireString('range'));
    final s = t.model.sheet(r.sheetId)!;
    final rect = SheetsMcp.clipToUsed(s, r);
    final range = ResolvedRange(s.id, rect);
    final hasHeader = a.boolean('has_header') ?? false;
    final specs = <SortKeySpec>[];
    for (final spec in a.list('specs')!.cast<Map<String, dynamic>>()) {
      final col = SheetsMcp.index(spec['column'], name: 'specs.column');
      if (col < rect.left || col > rect.right) {
        throw SheetsMcp.invalidRange(
          'Sort column ${spec['column']} is outside ${rect.a1}.',
        );
      }
      specs.add(
        SortKeySpec(s.columns.idAt(col), ascending: spec['ascending'] != false),
      );
    }
    final a1 = SheetsMcp.a1(t.model, s.id, rect);
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.sort_range',
      label: SheetsMcp.label(ctx, 'sheets.sort_range', a1),
      ranges: [a1],
      steps: [
        (model, pctx) {
          try {
            return SheetsWrites.planner.plan(
              SortRange(range, specs, hasHeader: hasHeader),
              model,
              pctx,
            );
          } on PlanException catch (e) {
            if (e.code != 'unsupported') rethrow;
            return _sortFallback(model, pctx, range, specs, hasHeader);
          }
        },
      ],
    );
    return _toolResult(o, 'Sorted $a1');
  }

  /// Sort through the shared row-permutation machinery while the planner's
  /// `SortRange` is not available (Sheets STATUS.md open item 2).
  static MutationPlan _sortFallback(
    WorkbookModel model,
    PlanContext pctx,
    ResolvedRange range,
    List<SortKeySpec> specs,
    bool hasHeader,
  ) {
    final b = PlanBuilder(model, pctx);
    final s = b.sheetOf(range.sheetId);
    final full = range.rect;
    final rect = hasHeader
        ? GridRect(full.top + 1, full.left, full.bottom, full.right)
        : full;
    if (rect.rowCount < 2) return b.build('Sort range');
    b.checkRect(s, rect);
    checkNoVerticalMerges(s, rect);
    final sortSpecs = [
      for (final k in specs) ValueSortSpec(k.colId, ascending: k.ascending),
    ];
    final table = SortTable.fromSheet(s, pctx.values!, rect, sortSpecs);
    final perm = SortPermutation.compute(table, sortSpecs);
    applyRowPermutation(b, s, rect, perm.toList());
    b.addResolvedRange(ResolvedRange(s.id, rect));
    return b.build('Sort range', kinds: [ChangeKinds.values]);
  }

  // --------------------------------------------------------------- import

  static Future<ToolResult> importCsv(ToolContext ctx, ToolArgs a) async {
    final t = await SheetsMcp.open(ctx, a, min: Role.editor);
    String text;
    if (a.has('csv_text')) {
      text = a.string('csv_text')!;
    } else if (a.has('content_base64')) {
      try {
        text = utf8.decode(
          base64Decode(a.string('content_base64')!),
          allowMalformed: true,
        );
      } on FormatException {
        throw McpToolException(
          McpErrorCode.invalidArgs,
          'content_base64 is not valid base64.',
        );
      }
    } else {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        'Pass csv_text or content_base64.',
      );
    }
    if (text.startsWith('﻿')) text = text.substring(1);
    var delimiter = switch (a.string('delimiter')) {
      'comma' => ',',
      'semicolon' => ';',
      'tab' => '\t',
      'pipe' => '|',
      _ => null,
    };
    var skip = 0;
    if (delimiter == null) {
      final d = CsvDelimiterDetector.detect(
        text.length > 65536 ? text.substring(0, 65536) : text,
      );
      delimiter = d.delimiter;
      skip = d.sepLineLength;
    }
    final records = CsvParser.parseAll(
      text.substring(skip),
      delimiter: delimiter,
    );
    final values = <List<Object?>>[
      for (final rec in records)
        [for (final f in rec.fields) f.isEmpty ? null : f],
    ];
    final cells = _cellCount(values);
    checkWriteLimit(cells);
    final convert = a.boolean('convert') ?? true;
    if (convert) {
      // Imported text is never rejected for formula syntax: invalid
      // formulas are kept as text.
      for (final row in values) {
        for (var i = 0; i < row.length; i++) {
          final v = row[i];
          if (v is String && v.length > 1 && v.startsWith('=')) {
            if (!validateFormula(v).ok) row[i] = "'$v";
          }
        }
      }
    }
    final width = values.fold<int>(0, (w, r) => math.max<int>(w, r.length));
    final height = values.length;
    final target = a.object('target')!;
    final mode = target['mode'] as String;
    final steps = <SheetsPlanStep>[];
    late String Function() sheetId;
    var top = 0, left = 0;
    String? confirm;
    String? newSheetName;
    switch (mode) {
      case 'new_sheet':
        final id = const Uuid().v7();
        newSheetName = (target['sheet_name'] as String?)?.trim();
        sheetId = () => id;
        steps.add(
          (model, pctx) => SheetsWrites.planner.plan(
            AddSheet(
              name: newSheetName,
              rows: math.max<int>(1000, height),
              columns: math.max<int>(26, width),
              sheetId: id,
            ),
            model,
            pctx,
          ),
        );
      case 'append':
        final s = SheetsMcp.sheetOrFirst(t, target['sheet'] as String?);
        sheetId = () => s.id;
        final used = s.usedRect();
        top = used == null ? 0 : used.bottom + 1;
      case 'replace_sheet':
        final s = SheetsMcp.sheetOrFirst(t, target['sheet'] as String?);
        sheetId = () => s.id;
        confirm = 'The assistant wants to replace all data of "${s.name}".';
        final grid = s.gridRect;
        if (grid != null) {
          steps.add(
            (model, pctx) => SheetsWrites.planner.plan(
              ClearRanges([
                ResolvedRange(s.id, grid, wholeRows: true, wholeColumns: true),
              ], what: ClearWhat.contents),
              model,
              pctx,
            ),
          );
        }
      default: // replace_at
        var s = SheetsMcp.sheetOrFirst(t, target['sheet'] as String?);
        final cell = target['cell'] as String?;
        if (cell != null) {
          final r = SheetsMcp.range(t, cell, contextSheetId: s.id);
          s = t.model.sheet(r.sheetId)!;
          top = r.rect.top;
          left = r.rect.left;
        }
        final sid = s.id;
        sheetId = () => sid;
    }
    if (values.isNotEmpty) {
      steps.add(
        _setStep(
          t.wb,
          () => sheetId(),
          top,
          left,
          values,
          raw: !convert,
          parseLocale: a.string('parse_locale'),
        ),
      );
    }
    final o = await SheetsWrites.run(
      ctx,
      t,
      tool: 'sheets.import_csv',
      label: SheetsMcp.label(ctx, 'sheets.import_csv', '$height×$width'),
      steps: steps,
      confirmIf: (plans, _) => confirm,
    );
    final model = SheetsWrites.modelAfter(ctx, t);
    final sheet = model.sheet(sheetId());
    final updated = sheet == null || values.isEmpty
        ? null
        : SheetsMcp.a1(
            model,
            sheet.id,
            GridRect(
              top,
              left,
              top + height - 1,
              left + math.max<int>(width, 1) - 1,
            ),
          );
    return _toolResult(
      o,
      'Imported $height row(s) × $width column(s)'
      '${updated == null ? '' : ' to $updated'}',
      extra: {
        'updated_range': updated,
        'rows': height,
        'columns': width,
        if (mode == 'new_sheet' && sheet != null)
          'sheet': {'name': sheet.name, 'id': sheet.id},
      },
    );
  }
}
