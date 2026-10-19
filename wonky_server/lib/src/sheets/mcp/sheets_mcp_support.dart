import 'dart:async';

import 'package:clock/clock.dart';
import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_sheets_core/wonky_sheets_core.dart'
    hide ActorKind, CellInput;

import '../../platform/common/models.dart';
import '../../platform/config/wonky_config.dart';
import '../../platform/mcp/tool_support.dart';
import '../../platform/sharing/access_service.dart';
import '../headless/headless_workbook.dart';
import '../headless/headless_workbook_provider.dart';
import 'sheets_shadow.dart';

/// Sheets-specific tool error codes (Sheets 12 §3.15); the suite codes
/// (`not_found`, `forbidden`, `invalid_args`, `busy`, …) come from
/// [McpErrorCode].
abstract final class SheetsErrorCode {
  static const invalidRange = 'invalid_range';
  static const duplicateName = 'duplicate_name';
  static const protectedRange = 'protected_range';
  static const limitExceeded = McpErrorCode.limitExceeded;
  static const cellLimitExceeded = 'cell_limit_exceeded';
  static const formulaParseError = 'formula_parse_error';
  static const mergeConflict = 'merge_conflict';

  /// The AI destructive guard (Sheets 12 §6.13): the assistant loop asks
  /// the user and retries (the same code as Write's guard).
  static const confirmationRequired = 'needs_confirmation';
}

/// Per-call limits (Sheets 12 §3.14).
abstract final class SheetsLimits {
  static const cellsWrittenPerCall = 50000;
  static const cellsReadPerCall = 100000;
  static const defaultReadPage = 10000;
  static const cellsClearedPerCall = 1000000;
  static const rowsInsertedPerCall = 10000;
  static const columnsInsertedPerCall = 1000;
  static const findMatches = 1000;
  static const validationWarnings = 100;

  /// AI confirmations (Sheets 12 §6.13).
  static const aiDeleteDimension = 1000;
  static const aiNonEmptyCells = 10000;
}

/// The spreadsheet a tool call operates on: the drive item, the caller's
/// role and the (cached) headless workbook.
class SheetsTarget {
  SheetsTarget(this.item, this.role, this.wb);

  final DriveItem item;
  final Role role;
  HeadlessWorkbook wb;

  /// The spreadsheet (space) uuid.
  UuidValue get space => item.contentRef!;

  WorkbookModel get model => wb.model;

  bool get isOwner => role == Role.owner;

  /// The browser URL of the spreadsheet.
  String url(Uri base) =>
      base.replace(path: '/sheets/s/${item.uuid.uuid}').toString();
}

/// Shared helpers of the `sheets.*` tool handlers: target resolution, A1
/// parsing and error mapping.
abstract final class SheetsMcp {
  static final _uuid = RegExp(
    '[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    '[0-9a-fA-F]{12}',
  );

  /// The uuid in a `spreadsheet` argument: a uuid, an app URL
  /// (`…/sheets/s/<uuid>…`) or anything containing one uuid.
  static UuidValue parseRef(String ref) {
    final text = ref.trim();
    final s = Uri.tryParse(text);
    final candidates = <String>[
      if (s != null && s.pathSegments.isNotEmpty)
        for (final seg in s.pathSegments.reversed)
          if (_uuid.hasMatch(seg)) _uuid.firstMatch(seg)!.group(0)!,
      for (final m in _uuid.allMatches(text)) m.group(0)!,
    ];
    if (candidates.isEmpty) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Unknown spreadsheet "$ref": pass its uuid or URL.',
      );
    }
    return UuidValue.withValidation(candidates.first.toLowerCase());
  }

  /// Resolves the `spreadsheet` argument and checks the caller's role
  /// (Sheets 12 §1.3: viewers can use read tools only).
  static Future<(DriveItem, Role)> resolveItem(
    Session session,
    ToolContext ctx,
    String ref, {
    Role min = Role.viewer,
  }) async {
    final uuid = parseRef(ref);
    var item = await AccessService.findItem(session, uuid);
    item ??= await DriveItem.db.findFirstRow(
      session,
      where: (t) =>
          t.contentRef.equals(uuid) & t.kind.equals(DriveItemKind.spreadsheet),
    );
    if (item == null || item.trashedAt != null && min > Role.viewer) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Spreadsheet not found or not visible to you.',
      );
    }
    final role = await AccessService.effectiveRole(
      session,
      ctx.actor.userId,
      item,
    );
    if (role == null) {
      throw McpToolException(
        McpErrorCode.notFound,
        'Spreadsheet not found or not visible to you.',
      );
    }
    if (item.kind != DriveItemKind.spreadsheet || item.contentRef == null) {
      throw McpToolException(
        McpErrorCode.invalidArgs,
        '"${item.name}" is not a spreadsheet.',
      );
    }
    if (!(role >= min)) {
      throw McpToolException(
        McpErrorCode.forbidden,
        min >= Role.editor
            ? 'You need edit access to change this spreadsheet (your role: '
                  '${role.name}).'
            : 'You do not have access to this spreadsheet.',
      );
    }
    return (item, role);
  }

  /// Resolves the target of a tool call and opens its workbook.
  static Future<SheetsTarget> open(
    ToolContext ctx,
    ToolArgs a, {
    Role min = Role.viewer,
  }) async {
    final (item, role) = await resolveItem(
      ctx.session,
      ctx,
      a.requireString('spreadsheet'),
      min: min,
    );
    // AI Suggest mode: the run reads and plans against its shadow.
    final shadow = SheetsShadows.forGroup(ctx.groupId);
    if (shadow != null && shadow.space == item.contentRef) {
      return SheetsTarget(item, role, shadow.wb);
    }
    final wb = await HeadlessWorkbookProvider.open(
      ctx.session,
      item.contentRef!,
    );
    return SheetsTarget(item, role, wb);
  }

  // ------------------------------------------------------------- ranges

  static McpToolException invalidRange(String message) =>
      McpToolException(SheetsErrorCode.invalidRange, message);

  /// Parses an A1 range (sheet names, named ranges; Sheets 12 §1.1).
  static ResolvedRange range(
    SheetsTarget t,
    String a1, {
    String? contextSheetId,
  }) {
    try {
      final r = t.model.parseA1(a1, contextSheetId: contextSheetId);
      if (t.model.sheet(r.sheetId) == null) {
        throw invalidRange('Range "$a1" is not on a sheet.');
      }
      return r;
    } on InvalidRangeException catch (e) {
      final names = [for (final s in t.model.sheets) s.name];
      throw McpToolException(
        SheetsErrorCode.invalidRange,
        '${e.message}. Sheets: ${names.map((n) => '"$n"').join(', ')}.',
        details: {'range': a1, 'sheets': names},
      );
    }
  }

  /// A sheet by name (case-insensitive) or id.
  static SheetModel sheet(SheetsTarget t, String nameOrId) {
    final m = t.model;
    final s =
        m.sheetByName(nameOrId) ??
        m.sheet(nameOrId) ??
        m.sheetByName(SheetNames.unquote(nameOrId));
    if (s == null) {
      final names = [for (final s in m.sheets) s.name];
      throw McpToolException(
        McpErrorCode.notFound,
        'No sheet "$nameOrId". Sheets: ${names.map((n) => '"$n"').join(', ')}.',
        details: {'sheets': names},
      );
    }
    return s;
  }

  /// The sheet of an optional `sheet` argument: the given one, else the
  /// first visible sheet.
  static SheetModel sheetOrFirst(SheetsTarget t, String? nameOrId) {
    if (nameOrId != null) return sheet(t, nameOrId);
    final visible = t.model.visibleSheets;
    if (visible.isEmpty) {
      throw McpToolException(
        McpErrorCode.notFound,
        'The spreadsheet has no sheets.',
      );
    }
    return visible.first;
  }

  /// A 0-based row/column index from a 1-based number or a column letter.
  static int index(Object? v, {required String name}) {
    if (v is num) {
      if (v < 1) {
        throw McpToolException(McpErrorCode.invalidArgs, '"$name" must be ≥ 1');
      }
      return v.toInt() - 1;
    }
    if (v is String) {
      final t = v.trim().toUpperCase();
      final n = int.tryParse(t);
      if (n != null) return index(n, name: name);
      if (RegExp(r'^[A-Z]{1,3}$').hasMatch(t)) return ColumnLetters.toIndex(t);
    }
    throw McpToolException(
      McpErrorCode.invalidArgs,
      '"$name" must be a 1-based number or a column letter.',
    );
  }

  /// `Sheet1!A1:B2` of an index rectangle.
  static String a1(WorkbookModel m, String sheetId, GridRect rect) =>
      m.a1Of(ResolvedRange(sheetId, rect));

  /// `Sheet1!B4` of a cell.
  static String cellA1(WorkbookModel m, String sheetId, int row, int col) =>
      a1(m, sheetId, GridRect.cell(row, col));

  /// The column letter of a 0-based index.
  static String letter(int col) => ColumnLetters.fromIndex(col);

  /// A range clipped to the used range (open-ended ranges, whole sheets).
  static GridRect clipToUsed(SheetModel s, ResolvedRange r) {
    if (!r.wholeColumns && !r.wholeRows) return r.rect;
    final used = s.usedRect();
    if (used == null) {
      return GridRect(r.rect.top, r.rect.left, r.rect.top, r.rect.left);
    }
    final bottom = r.wholeColumns && used.bottom < r.rect.bottom
        ? used.bottom
        : r.rect.bottom;
    final right = r.wholeRows && used.right < r.rect.right
        ? used.right
        : r.rect.right;
    return GridRect(
      r.rect.top,
      r.rect.left,
      bottom < r.rect.top ? r.rect.top : bottom,
      right < r.rect.left ? r.rect.left : right,
    );
  }

  // ------------------------------------------------------------- errors

  /// Maps a planner refusal to a tool error.
  static McpToolException fromPlan(PlanException e) {
    final code = switch (e.code) {
      'invalid_argument' => McpErrorCode.invalidArgs,
      'not_found' => McpErrorCode.notFound,
      'unsupported' => McpErrorCode.unsupported,
      _ => e.code,
    };
    return McpToolException(
      code,
      e.message,
      details: e.details.isEmpty ? null : e.details,
    );
  }

  /// The planning context of [t] for [ctx]'s user.
  static PlanContext planContext(ToolContext ctx, SheetsTarget t) =>
      PlanContext(
        userId: ctx.actor.authUserId.uuid,
        now: clock.now().toUtc(),
        formulas: t.wb.hooks,
        values: t.wb.engine,
        locale: t.model.spreadsheet.locale,
        maxCells: _maxCells,
        isOwner: t.isOwner,
      );

  static int get _maxCells {
    try {
      return WonkyConfig.current.maxCellsPerSpreadsheet;
    } on Object {
      return 1000000;
    }
  }

  /// The cell limit of a spreadsheet (`sheets.maxCellsPerSpreadsheet`).
  static int get maxCells => _maxCells;

  /// The grid cells of all sheets of [m].
  static int gridCells(WorkbookModel m) => m.sheets.fold(
    0,
    (n, s) => n + s.rows.length * s.columns.length,
  );

  /// The label of a tool change in history and undo ("MCP: set_values
  /// Sheet1!A1:C3", "AI: …").
  static String label(ToolContext ctx, String tool, [String? detail]) {
    final short = tool.startsWith('sheets.') ? tool.substring(7) : tool;
    final prefix = ctx.actor.kind == ActorKind.ai ? 'AI' : 'MCP';
    return detail == null || detail.isEmpty
        ? '$prefix: $short'
        : '$prefix: $short $detail';
  }
}
