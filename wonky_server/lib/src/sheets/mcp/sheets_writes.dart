import 'dart:async';

import 'package:serverpod/serverpod.dart';
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/common/actor.dart';
import '../../platform/common/errors.dart';
import '../../platform/common/models.dart';
import '../../platform/mcp/tool_support.dart';
import '../changelog/agent_cursors.dart';
import '../headless/headless_workbook.dart';
import '../headless/headless_workbook_provider.dart';
import '../revlog/sheets_server_writes.dart';
import 'sheets_bulk_writer.dart';
import 'sheets_mcp_support.dart';
import 'sheets_shadow.dart';

/// One planning step of a tool call: plans against the model state left by
/// the previous steps.
typedef SheetsPlanStep =
    MutationPlan Function(WorkbookModel model, PlanContext ctx);

/// The result of a mutating tool call.
class SheetsWriteOutcome {
  SheetsWriteOutcome({
    required this.plans,
    required this.cellsAffected,
    required this.warnings,
    this.changeId,
    this.preview = false,
    this.callId,
    this.skipped = 0,
  });

  /// The recorded change (null when nothing changed or in a preview).
  final UuidValue? changeId;
  final List<MutationPlan> plans;
  final int cellsAffected;
  final List<String> warnings;

  /// Whether the call was recorded in an AI Suggest-mode preview instead
  /// of being committed.
  final bool preview;
  final String? callId;

  /// Row/column writes skipped by the writer (rows deleted meanwhile).
  final int skipped;

  /// Results of the plans (`sheetId`, `ruleId`, …), later steps win.
  Map<String, Object?> get result => {for (final p in plans) ...p.result};

  /// The common output fields of mutating tools (Sheets 12 §3).
  Map<String, Object?> toJson() => {
    'change_id': changeId?.uuid,
    'cells_affected': cellsAffected,
    'warnings': warnings,
    if (preview) ...{
      'preview': true,
      'note':
          'Suggest mode: the change was recorded for the user to review and '
          'is not applied yet.',
    },
  };
}

/// The mutation pipeline of the `sheets.*` tools (Sheets 12 §2.3–2.4):
/// serialized per spreadsheet, planned with [SheetsMutationPlanner] against
/// the headless model, checked against protected ranges and the AI
/// destructive guard, committed as RevLog server changes (chunked ops
/// checked again by the sequencer, a [ServerChangeRecord] for
/// `changes.revert`); the cached model follows the committed ops.
abstract final class SheetsWrites {
  static const planner = SheetsMutationPlanner();

  /// Plans and commits [steps] as one change labeled [label].
  ///
  /// [intents] lists protection intents beyond the cell writes the plans
  /// make (structure, sheet and rule operations), evaluated before the
  /// first step. [confirmIf] returns a reason when an assistant call must
  /// be confirmed by the user (Sheets 12 §6.13). [ranges] and [structural]
  /// describe the call in AI previews.
  static Future<SheetsWriteOutcome> run(
    ToolContext ctx,
    SheetsTarget t, {
    required String tool,
    required String label,
    required List<SheetsPlanStep> steps,
    List<WriteIntent> Function(WorkbookModel model)? intents,
    String? Function(List<MutationPlan> plans, WorkbookModel model)? confirmIf,
    List<String> ranges = const [],
    String? structural,
  }) async {
    final shadow = SheetsShadows.forGroup(ctx.groupId);
    final preview = shadow != null && shadow.space == t.space;
    return HeadlessWorkbookProvider.withWriteLock(t.space, () async {
      if (!preview) {
        t.wb = await HeadlessWorkbookProvider.open(ctx.session, t.space);
      }
      final wb = preview ? shadow.wb : t.wb;
      final model = wb.model;
      final pctx = SheetsMcp.planContext(ctx, SheetsTarget(t.item, t.role, wb));
      final userId = ctx.actor.authUserId.uuid;
      final warnings = <String>[];
      final plans = <MutationPlan>[];
      final guard = ProtectionGuard(model);

      void rollback() {
        for (final p in plans.reversed) {
          model.applyChanges([for (final c in p.changes.reversed) c.inverse()]);
        }
      }

      try {
        for (final intent in intents?.call(model) ?? const <WriteIntent>[]) {
          _checkGuard(
            ctx,
            t,
            guard.check(intent, userId, isOwner: t.isOwner),
            warnings,
            model,
            intent.sheetId,
          );
        }
        for (final step in steps) {
          MutationPlan plan;
          try {
            plan = step(model, pctx);
          } on PlanException catch (e) {
            throw SheetsMcp.fromPlan(e);
          } on InvalidRangeException catch (e) {
            throw SheetsMcp.invalidRange(e.message);
          }
          _checkPlan(ctx, t, guard, plan, model, warnings);
          if (ctx.guardDestructive && confirmIf != null) {
            final reason = confirmIf([...plans, plan], model);
            if (reason != null) throw _confirmation(tool, reason);
          }
          model.applyPlan(plan);
          plans.add(plan);
          warnings.addAll(plan.warnings);
        }
      } on Object {
        rollback();
        rethrow;
      }
      final changes = [for (final p in plans) ...p.changes];
      final cells = {
        for (final c in changes)
          if (c.table == SheetsTables.cell) c.rowId,
      }.length;
      if (changes.isEmpty) {
        return SheetsWriteOutcome(
          plans: plans,
          cellsAffected: 0,
          warnings: warnings,
          preview: preview,
        );
      }
      final kinds = {for (final p in plans) ...p.summary.kinds};
      if (preview) {
        final callId = shadow.nextCallId();
        shadow.calls.add(
          ShadowCall(
            callId: callId,
            toolName: tool,
            label: label,
            changes: changes,
            ranges: ranges,
            cellsAffected: cells,
            kinds: kinds.isEmpty ? {ChangeKinds.values} : kinds,
            structural: structural,
          ),
        );
        return SheetsWriteOutcome(
          plans: plans,
          cellsAffected: cells,
          warnings: warnings,
          preview: true,
          callId: callId,
        );
      }
      // The plans were applied to the shared headless model so that later
      // steps see the earlier ones. Undo that before committing: the
      // sequencer checks protections against the model before the op, and
      // the committed op reaches the model through the file's ops.
      rollback();
      final UuidValue changeId;
      final AppliedChanges applied;
      try {
        (changeId, applied) = await SheetsBulkWriter.applyRecorded(
          ctx.session,
          actor: ctx.actor,
          item: t.item,
          changes: changes,
          label: label,
          plans: plans,
        );
      } on WonkyException catch (e) {
        if (Errors.isProtectedRange(e)) {
          throw McpToolException(SheetsErrorCode.protectedRange, e.message);
        }
        rethrow;
      }
      await showCursor(
        ctx.session,
        t.item,
        ctx.actor,
        SheetsBulkWriter.summaryOf(plans, const {}, changes),
      );
      return SheetsWriteOutcome(
        changeId: changeId,
        plans: plans,
        cellsAffected: cells,
        warnings: warnings,
        skipped: applied.skipped.length,
      );
    });
  }

  /// Shows the agent cursor of an MCP/AI write (RevLog spec 05 §6.2: inline
  /// after the commit, best effort).
  static Future<void> showCursor(
    Session session,
    DriveItem item,
    Actor actor,
    ChangeSummary summary,
  ) async {
    try {
      await AgentCursors.show(session, item, actor, summary);
    } on Object catch (e) {
      session.log('Agent cursor failed: $e', level: LogLevel.warning);
    }
  }

  /// The model a call's results are read from: the AI preview shadow when
  /// the call was recorded in one, else the live workbook.
  static WorkbookModel modelAfter(ToolContext ctx, SheetsTarget t) {
    final shadow = SheetsShadows.forGroup(ctx.groupId);
    return shadow != null && shadow.space == t.space
        ? shadow.wb.model
        : t.model;
  }

  static McpToolException _confirmation(String tool, String reason) =>
      McpToolException(
        SheetsErrorCode.confirmationRequired,
        '$reason The user must confirm it.',
        details: {'summary': reason, 'tool': tool},
      );

  // ---------------------------------------------------------- protection

  static void _checkPlan(
    ToolContext ctx,
    SheetsTarget t,
    ProtectionGuard guard,
    MutationPlan plan,
    WorkbookModel model,
    List<String> warnings,
  ) {
    final bySheet = <String, List<GridRect>>{};
    for (final c in plan.changes) {
      final rect = _rectOf(model, c);
      if (rect == null) continue;
      bySheet.putIfAbsent(rect.$1, () => []).add(rect.$2);
    }
    final userId = ctx.actor.authUserId.uuid;
    for (final e in bySheet.entries) {
      final sheet = model.sheet(e.key);
      if (sheet == null || sheet.protections.isEmpty) continue;
      var top = e.value.first.top, left = e.value.first.left;
      var bottom = e.value.first.bottom, right = e.value.first.right;
      for (final r in e.value) {
        if (r.top < top) top = r.top;
        if (r.left < left) left = r.left;
        if (r.bottom > bottom) bottom = r.bottom;
        if (r.right > right) right = r.right;
      }
      final box = guard.check(
        CellWrites(e.key, [GridRect(top, left, bottom, right)]),
        userId,
        isOwner: t.isOwner,
      );
      if (box.isAllowed) continue;
      // Refine: only the cells actually written count.
      _checkGuard(
        ctx,
        t,
        guard.check(CellWrites(e.key, e.value), userId, isOwner: t.isOwner),
        warnings,
        model,
        e.key,
      );
    }
  }

  static void _checkGuard(
    ToolContext ctx,
    SheetsTarget t,
    GuardResult r,
    List<String> warnings,
    WorkbookModel model,
    String sheetId,
  ) {
    if (r.isAllowed) return;
    final ranges = <String>{
      for (final h in r.hits)
        if (h.rect != null)
          SheetsMcp.a1(model, sheetId, h.rect!)
        else
          model.sheet(sheetId)?.name ?? sheetId,
    }.toList();
    if (r.isBlocked) {
      throw McpToolException(
        SheetsErrorCode.protectedRange,
        'The change touches protected cells you cannot edit: '
        '${ranges.join(', ')}.',
        details: {'ranges': ranges},
      );
    }
    if (ctx.guardDestructive) {
      throw _confirmation(
        'protection',
        'The change edits ${ranges.join(', ')}, which is protected with a '
            'warning.',
      );
    }
    warnings.add(
      'Edited ${ranges.join(', ')}, which is protected with a warning '
      '(warning-only protection).',
    );
  }

  /// The sheet and index rectangle a row change writes (null for rows
  /// without grid position: new rows, sheets, rules).
  static (String, GridRect)? _rectOf(WorkbookModel model, RowChange c) {
    Object? col(String name) =>
        c.columnsAfter[name] ??
        c.columnsBefore[name] ??
        model.currentColumns(c.table, c.rowId)?[name];
    switch (c.table) {
      case SheetsTables.cell:
        final sheetId = col(Cols.sheetId)?.toString();
        final rowId = col(CellCols.rowId)?.toString();
        final colId = col(CellCols.columnId)?.toString();
        final sheet = sheetId == null ? null : model.sheet(sheetId);
        if (sheet == null || rowId == null || colId == null) return null;
        final r = sheet.rows.indexOf(rowId);
        final k = sheet.columns.indexOf(colId);
        if (r < 0 || k < 0) return null;
        return (sheetId!, GridRect.cell(r, k));
      case SheetsTables.sheetRow || SheetsTables.sheetColumn:
        if (c.op == RowOp.insert) return null;
        final sheetId = col(Cols.sheetId)?.toString();
        final sheet = sheetId == null ? null : model.sheet(sheetId);
        if (sheet == null ||
            sheet.columns.length == 0 ||
            sheet.rows.length == 0) {
          return null;
        }
        final isRow = c.table == SheetsTables.sheetRow;
        final i = (isRow ? sheet.rows : sheet.columns).indexOf(c.rowId);
        if (i < 0) return null;
        return (
          sheetId!,
          isRow
              ? GridRect(i, 0, i, sheet.columns.length - 1)
              : GridRect(0, i, sheet.rows.length - 1, i),
        );
      default:
        return null;
    }
  }

  // ---------------------------------------------------------- validation

  /// Cells of [rects] on [sheetId] whose new values violate data
  /// validation rules (Sheets 12 §2.4: tool writes are never rejected;
  /// max 100).
  static List<String> validationWarnings(
    HeadlessWorkbook wb,
    String sheetId,
    List<GridRect> rects,
  ) {
    final sheet = wb.model.sheet(sheetId);
    if (sheet == null || sheet.dvRules.isEmpty) return const [];
    final dv = DvEvaluator(
      wb.model,
      wb.engine,
      wb.display,
      hooks: wb.hooks,
    );
    final out = <String>[];
    for (final rect in rects) {
      for (final (r, c, _) in sheet.cellsIn(rect, contentOnly: true)) {
        if (!dv.validateCell(sheetId, r, c).valid) {
          out.add(SheetsMcp.cellA1(wb.model, sheetId, r, c));
          if (out.length >= SheetsLimits.validationWarnings) return out;
        }
      }
    }
    return out;
  }
}
