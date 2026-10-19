import 'package:serverpod/serverpod.dart';
import 'package:wonky_core/wonky_core.dart' show Role;
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/rows.dart' show RowChange, RowOp;
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_sheets_core/model.dart'
    show
        ChangeSummary,
        Cols,
        GuardResult,
        GuardStatus,
        ProtectedRangeRecord,
        ProtectionCheck,
        SheetCols,
        SheetsTables,
        WorkbookModel;
import 'package:wonky_sheets_core/revlog.dart';

import '../../platform/common/models.dart';
import '../../platform/config/wonky_config.dart';
import '../../platform/revlog/rev_binding.dart';
import '../../platform/revlog/rev_hooks.dart';
import '../headless/headless_workbook.dart';
import 'sheets_hooks.dart';

/// The RevLog binding of spreadsheets (RevLog spec 05 §1, §3.5).
final class SheetsRevBinding extends RevBinding {
  SheetsRevBinding._();

  /// The instance registered at startup.
  static final instance = SheetsRevBinding._();

  @override
  RevFileKind get kind => RevFileKind.spreadsheet;

  @override
  RevSchema get schema => sheetsSchema;

  @override
  DriveItemKind get itemKind => DriveItemKind.spreadsheet;

  @override
  String get rootTitleColumn => 'title';

  @override
  Set<String> get perSheetTables => const {SheetsTables.cell};

  @override
  Future<Map<String, List<String>>> perSheetScopes(
    Session session,
    int fileId, {
    Transaction? transaction,
  }) async => {Cols.sheetId: await sheetIds(session, fileId, transaction)};

  /// The file's sheet ids.
  static Future<List<String>> sheetIds(
    Session session,
    int fileId, [
    Transaction? transaction,
  ]) async {
    final rows = await session.db.unsafeQuery(
      'SELECT id::text FROM sheet WHERE "fileId" = @f',
      parameters: QueryParameters.named({'f': fileId}),
      transaction: transaction,
    );
    return [for (final r in rows) r[0]! as String];
  }

  // ---------------------------------------------------------------- stats

  @override
  RevStats updateStats(RevStats before, List<RowChange> applied) {
    final base = super.updateStats(before, applied);
    final sheets = <String, Map<String, Object?>>{
      for (final e in ((before.extra['sheets'] as Map?) ?? const {}).entries)
        e.key as String: {...(e.value as Map).cast<String, Object?>()},
    };
    void bump(String? sheetId, String key, int by) {
      if (sheetId == null) return;
      final s = sheets[sheetId];
      if (s == null) return;
      s[key] = ((s[key] as num?)?.toInt() ?? 0) + by;
    }

    for (final c in applied) {
      final cols = c.op == RowOp.delete ? c.columnsBefore : c.columnsAfter;
      switch (c.table) {
        case SheetsTables.sheet:
          if (c.op == RowOp.insert) {
            sheets[c.rowId] = {
              'rows': 0,
              'cols': 0,
              'grid': (cols[SheetCols.kind] ?? 'grid') == 'grid',
            };
          } else if (c.op == RowOp.delete) {
            sheets.remove(c.rowId);
          } else if (cols.containsKey(SheetCols.kind)) {
            sheets[c.rowId]?['grid'] = cols[SheetCols.kind] == 'grid';
          }
        case SheetsTables.sheetRow || SheetsTables.sheetColumn:
          if (c.op == RowOp.update) continue;
          bump(
            cols[Cols.sheetId] as String?,
            c.table == SheetsTables.sheetRow ? 'rows' : 'cols',
            c.op == RowOp.insert ? 1 : -1,
          );
      }
    }
    return RevStats(
      tables: base.tables,
      extra: {...base.extra, 'sheets': sheets},
    );
  }

  @override
  int contentCount(RevStats stats) {
    var n = 0;
    for (final s in ((stats.extra['sheets'] as Map?) ?? const {}).values) {
      final m = (s as Map).cast<String, Object?>();
      if (m['grid'] == false) continue;
      n +=
          ((m['rows'] as num?)?.toInt() ?? 0) *
          ((m['cols'] as num?)?.toInt() ?? 0);
    }
    return n;
  }

  // ------------------------------------------------------------ authorize

  @override
  Future<void> authorize(
    Session session,
    Transaction transaction,
    ChangeSet cs,
    ApplyResult applied,
    RevAuthor author,
    RevStats statsAfter,
    RevModelAccess models,
  ) async {
    final config = WonkyConfig.current;
    // Limits apply when an op grows past them (03 §5 rule 6).
    final cells = contentCount(statsAfter);
    final grew = applied.applied.any(
      (c) =>
          c.op == RowOp.insert &&
          (c.table == SheetsTables.sheetRow ||
              c.table == SheetsTables.sheetColumn ||
              c.table == SheetsTables.sheet),
    );
    if (grew && cells > config.maxCellsPerSpreadsheet) {
      throw RevRejection(
        RevRejectReason.limitExceeded,
        'This spreadsheet has reached the limit of '
        '${config.maxCellsPerSpreadsheet} cells.',
      );
    }
    final sheetCount = statsAfter.tables[SheetsTables.sheet] ?? 0;
    final addsSheet = applied.applied.any(
      (c) => c.table == SheetsTables.sheet && c.op == RowOp.insert,
    );
    if (addsSheet && sheetCount > config.maxSheetsPerSpreadsheet) {
      throw RevRejection(
        RevRejectReason.limitExceeded,
        'A spreadsheet can have at most '
        '${config.maxSheetsPerSpreadsheet} sheets.',
      );
    }
    await _checkProtections(applied, author, statsAfter, models);
  }

  /// Protected ranges (05 §3.5): every op except system ops, when the file
  /// has protections or the op touches them.
  Future<void> _checkProtections(
    ApplyResult applied,
    RevAuthor author,
    RevStats statsAfter,
    RevModelAccess models,
  ) async {
    if (author.actorKind == 'system' || author.authUuid == null) return;
    final touches = applied.applied.any(
      (c) => c.table == SheetsTables.protectedRange,
    );
    final had =
        (statsAfter.tables[SheetsTables.protectedRange] ?? 0) > 0 || touches;
    if (!had) return;
    final wb = await models.atPrevious() as HeadlessWorkbook;
    final model = wb.model;
    if (!touches && !model.sheets.any((s) => s.protections.isNotEmpty)) {
      return;
    }
    final result = ProtectionCheck.ofApplied(
      model,
      applied.applied,
      author.authUuid!.uuid.toLowerCase(),
      isOwner: author.role == Role.owner,
    );
    if (result.status != GuardStatus.blocked) return;
    throw RevRejection(
      RevRejectReason.protectedRange,
      GuardResult.blockedMessage,
      details: {
        'message': GuardResult.blockedMessage,
        'protections': [
          for (final id in {for (final h in result.hits) h.protectionId})
            _describe(model, id),
        ],
      },
    );
  }

  static Map<String, Object?> _describe(WorkbookModel model, String id) {
    for (final s in model.sheets) {
      final ProtectedRangeRecord? p = s.protections[id];
      if (p == null) continue;
      return {
        'id': id,
        'description': p.description,
        'sheet': s.name,
      };
    }
    return {'id': id};
  }

  // ---------------------------------------------------------------- misc

  @override
  String summarize(List<RowChange> changes) =>
      ChangeSummary.ofChanges(changes).encode();

  @override
  List<RevHook> get hooks => SheetsHooks.all;

  @override
  Object buildModel(
    UuidValue fileUuid,
    Iterable<(String, Map<String, Object?>)> rows,
  ) {
    final list = rows.toList();
    final counts = <String, int>{};
    for (final (t, _) in list) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final ordered = [
      for (final table in SheetsTables.dependencyOrder)
        for (final r in list)
          if (r.$1 == table) r,
    ];
    return HeadlessWorkbook(
      space: fileUuid,
      model: WorkbookModel.fromRows(fileUuid.uuid, ordered),
      watermark: 0,
      estimatedBytes: HeadlessWorkbook.estimate(counts),
    );
  }

  @override
  void applyToModel(Object model, List<RowChange> applied) =>
      (model as HeadlessWorkbook).apply(applied);

  @override
  int estimateBytes(Object model) {
    final wb = model as HeadlessWorkbook;
    final counts = <String, int>{};
    for (final (t, _) in wb.model.allRows()) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    return wb.estimatedBytes = HeadlessWorkbook.estimate(counts);
  }
}
