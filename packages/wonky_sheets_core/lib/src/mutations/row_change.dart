import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:wonky_revlog/rows.dart' as kit;
import 'package:wonky_revlog/rows.dart'
    show
        CurrentRowReader,
        RowChange,
        RowOp,
        SkippedColumn,
        TableColumnwiseInserts,
        UndoInverter;

import '../model/schema.dart';

// The generic row changes, plans, undo inverter and remote patching live in
// `wonky_revlog` (RevLog spec 03). Sheets keeps its names: [ChangeSummary]
// is Sheets' summary (implementing the RevLog interface) and [MutationPlan]
// the RevLog plan over it. The RevLog
// `UndoInverter` is not re-exported: [SheetsUndo] binds Sheets' cell rule.
export 'package:wonky_revlog/rows.dart'
    show
        ColumnwiseInserts,
        CoupledColumns,
        CurrentRowReader,
        RowChange,
        RowOp,
        RowPatch,
        SkippedColumn,
        TableColumnwiseInserts,
        TableCoupledColumns,
        TableRank;

/// Kinds listed in `ChangeLog.summaryJson.kinds`.
abstract final class ChangeKinds {
  static const values = 'values';
  static const format = 'format';
  static const structure = 'structure';
  static const sheets = 'sheets';
  static const rules = 'rules';
  static const objects = 'objects';
  static const names = 'names';
  static const protection = 'protection';
  static const filters = 'filters';
  static const notes = 'notes';
  static const settings = 'settings';
  static const scripts = 'scripts';
  static const import = 'import';
  static const restore = 'restore';
}

/// `ChangeLog.summaryJson` (02 §3.7, 10 A-10-1).
final class ChangeSummary implements kit.ChangeSummary {
  /// Creates a summary.
  ChangeSummary({
    Set<String>? sheets,
    List<Map<String, Object?>>? ranges,
    Set<String>? kinds,
    Map<String, List<String>>? deleted,
    Map<String, List<String>>? revived,
    this.structureOverflow = false,
  }) : sheets = sheets ?? {},
       ranges = ranges ?? [],
       kinds = kinds ?? {},
       deleted = deleted ?? {},
       revived = revived ?? {};

  /// A summary of [changes] without a plan (undo/redo, remote
  /// re-application, server-side ops without a client summary): sheets,
  /// kinds and deleted/revived structure ids.
  factory ChangeSummary.ofChanges(Iterable<RowChange> changes) {
    final s = ChangeSummary();
    for (final c in changes) {
      final sheet =
          c.columnsAfter[Cols.sheetId] ?? c.columnsBefore[Cols.sheetId];
      if (sheet != null) s.sheets.add('$sheet');
      s.kinds.add(switch (c.table) {
        SheetsTables.cell =>
          c.touchedColumns.any(
                (k) => k == CellCols.content || k == CellCols.note,
              )
              ? ChangeKinds.values
              : ChangeKinds.format,
        SheetsTables.sheetRow ||
        SheetsTables.sheetColumn ||
        SheetsTables.mergedRange ||
        SheetsTables.dimensionGroup => ChangeKinds.structure,
        SheetsTables.sheet => ChangeKinds.sheets,
        SheetsTables.spreadsheet => ChangeKinds.settings,
        SheetsTables.namedRange => ChangeKinds.names,
        SheetsTables.protectedRange => ChangeKinds.protection,
        SheetsTables.basicFilter ||
        SheetsTables.filterView => ChangeKinds.filters,
        SheetsTables.embeddedObject ||
        SheetsTables.pivotTable => ChangeKinds.objects,
        SheetsTables.conditionalFormatRule ||
        SheetsTables.dataValidationRule ||
        SheetsTables.banding => ChangeKinds.rules,
        _ => ChangeKinds.scripts,
      });
      final kind = switch (c.table) {
        SheetsTables.sheetRow => 'rows',
        SheetsTables.sheetColumn => 'cols',
        SheetsTables.sheet => 'sheets',
        _ => null,
      };
      if (kind == null) continue;
      if (c.op == RowOp.delete) s.addDeleted(kind, c.rowId);
      if (c.op == RowOp.insert) s.addRevived(kind, c.rowId);
    }
    return s;
  }

  /// Max ids per deleted/revived list before [structureOverflow].
  static const maxIds = 1000;

  /// Max ranges kept (bigger edits keep the bounding ranges).
  static const maxRanges = 1000;

  final Set<String> sheets;

  /// GridRange JSON maps.
  final List<Map<String, Object?>> ranges;
  final Set<String> kinds;

  /// `{rows: [...], cols: [...], sheets: [...]}`.
  final Map<String, List<String>> deleted;
  final Map<String, List<String>> revived;
  bool structureOverflow;

  /// Records a deleted entity of [kind] (`rows`, `cols`, `sheets`).
  void addDeleted(String kind, String id) => _add(deleted, kind, id);

  /// Records a revived entity.
  void addRevived(String kind, String id) => _add(revived, kind, id);

  void _add(Map<String, List<String>> m, String kind, String id) {
    final l = m.putIfAbsent(kind, () => []);
    if (l.length >= maxIds) {
      structureOverflow = true;
      return;
    }
    l.add(id);
  }

  /// Adds a range (GridRange JSON map).
  void addRange(Map<String, Object?> range) {
    if (ranges.length >= maxRanges) return;
    if (ranges.any((r) => const DeepCollectionEquality().equals(r, range))) {
      return;
    }
    ranges.add(range);
  }

  /// JSON map.
  @override
  Map<String, Object?> toJson() => {
    'sheets': sheets.toList()..sort(),
    'ranges': ranges,
    'kinds': kinds.toList()..sort(),
    if (deleted.isNotEmpty) 'deleted': deleted,
    if (revived.isNotEmpty) 'revived': revived,
    if (structureOverflow) 'structureOverflow': true,
  };

  /// `summaryJson` string.
  String encode() => jsonEncode(toJson());

  /// Parses `summaryJson`.
  static ChangeSummary parse(String json) =>
      ChangeSummary.fromJson(jsonDecode(json) as Map<String, Object?>);

  /// Reads the [toJson] form (an op's summary).
  factory ChangeSummary.fromJson(Map<String, Object?> m) {
    List<String> strs(Object? v) =>
        v is List ? v.map((e) => e.toString()).toList() : [];
    Map<String, List<String>> lists(Object? v) => v is Map
        ? {for (final e in v.entries) e.key.toString(): strs(e.value)}
        : {};
    return ChangeSummary(
      sheets: strs(m['sheets']).toSet(),
      ranges: m['ranges'] is List
          ? [
              for (final r in m['ranges']! as List)
                (r as Map).cast<String, Object?>(),
            ]
          : [],
      kinds: strs(m['kinds']).toSet(),
      deleted: lists(m['deleted']),
      revived: lists(m['revived']),
      structureOverflow: m['structureOverflow'] == true,
    );
  }
}

/// One cell's before/after content in `ChangeLog.detailJson` (≤ 200 cells).
typedef CellDetail = ({
  String sheetId,
  String rowId,
  String colId,
  String? before,
  String? after,
});

/// A planned transaction of Sheets: ordered row changes + undo label +
/// `ChangeLog` data (02 §7, 13 §4.1) — the shared kit's plan over Sheets'
/// [ChangeSummary].
typedef MutationPlan = kit.MutationPlan<ChangeSummary>;

/// Sheets-specific reads of a [MutationPlan].
extension SheetsMutationPlanX on kit.MutationPlan<ChangeSummary> {
  /// Columns of the `ChangeLog` row written in the same transaction as the
  /// plan (02 §3.7).
  Map<String, Object?> changeLogColumns({
    required String spreadsheetId,
    required String userId,
    required ActorKind actorKind,
    required String sessionId,
    required DateTime at,
  }) => {
    Cols.spreadsheetId: spreadsheetId,
    'userId': userId,
    'actorKind': actorKind.name,
    'sessionId': sessionId,
    'label': label,
    'summaryJson': summary.encode(),
    'detailJson': detailJson,
    'at': at,
  };

  /// Number of distinct cells touched.
  int get cellCount =>
      changes.where((c) => c.table == SheetsTables.cell).length;
}

/// The undo of Sheets plans: the kit's [UndoInverter] with Sheets' cell rule
/// (08 §3.3, 02 §7, 10 §10 #16): a cell someone else changed since (value
/// or format) is not deleted by undoing its insert; the columns still
/// holding what the insert wrote are cleared, the others are skipped.
abstract final class SheetsUndo {
  /// Cell columns that identify the row (never cleared by an undo).
  static const columnwise = TableColumnwiseInserts({
    SheetsTables.cell: {
      Cols.id,
      Cols.sheetId,
      CellCols.rowId,
      CellCols.columnId,
      Cols.createdAt,
    },
  });

  /// The changes that undo [plan] given [current]. [skipped] receives
  /// `(table, rowId, column)` triples that were skipped.
  static List<RowChange> invert(
    MutationPlan plan,
    CurrentRowReader current, {
    SkippedColumn? skipped,
  }) => invertChanges(plan.changes, current, skipped: skipped);

  /// [invert] for a raw change list.
  static List<RowChange> invertChanges(
    List<RowChange> changes,
    CurrentRowReader current, {
    SkippedColumn? skipped,
  }) => UndoInverter.invertChanges(
    changes,
    current,
    columnwise: columnwise,
    skipped: skipped,
  );
}
