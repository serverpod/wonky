import 'package:wonky_revlog/rows.dart'
    show TableColumnwiseInserts, TableCoupledColumns;

import 'slides_schema.dart';

/// The table hooks of the `slides.rows` undo domain (02 §12.2) for the
/// shared `UndoInverter` of `wonky_revlog`.
abstract final class SlidesUndoHooks {
  /// Coupled columns (02 P4): every writer that changes any column of a
  /// group writes the group's other columns too (when they change), and
  /// undo skips a group as a unit — if someone else changed any of its
  /// columns that a step wrote, none of them is undone, so position keys
  /// never tear from their key space and frames never tear from the
  /// coordinate space they are in. A group only spans the columns a step
  /// actually wrote (moving writes `x,y`, resizing `x,y,width,height`).
  ///
  /// - `slide`: `{groupId, sortKey}` — the key space and the key (02 §3.4).
  /// - `slide_group`: `{parentId, sortKey}` — same rule one level up (P2
  ///   nesting).
  /// - `slide_element`: `{parentId, zKey, x, y, width, height, rotation,
  ///   flipH, flipV}` — the frame is in the parent's child space (02 §6.9)
  ///   and `zKey` in the parent's key space, so (un)grouping, which
  ///   re-parents and bakes frames, is undone together or not at all.
  /// - `slide_table_cell`: `{rowSpan, colSpan}` — a merge (02 §3.6).
  /// - `slide_master`: `{themeId, sortKey}`; `slide_layout`:
  ///   `{masterId, sortKey}` — the key space and the key.
  /// - `chart_link`: the snapshot (`sourceSpecJson`, `dataSnapshotJson`,
  ///   `sourceVersion`, `sheetId`, `updatedAt`, `updatedBy`) — always
  ///   written together (08 A-08-2).
  /// - `deck`: `{width, height, sizePreset}` — the page size (05 §7).
  static const coupled = TableCoupledColumns({
    SlidesTables.slide: [
      {SlideCols.groupId, SlidesCols.sortKey},
    ],
    SlidesTables.slideGroup: [
      {SlidesCols.parentId, SlidesCols.sortKey},
    ],
    SlidesTables.slideElement: [
      {
        SlidesCols.parentId,
        ElementCols.zKey,
        ElementCols.x,
        ElementCols.y,
        ElementCols.width,
        ElementCols.height,
        ElementCols.rotation,
        ElementCols.flipH,
        ElementCols.flipV,
      },
    ],
    SlidesTables.slideTableCell: [
      {TableCellCols.rowSpan, TableCellCols.colSpan},
    ],
    SlidesTables.slideMaster: [
      {SlideMasterCols.themeId, SlidesCols.sortKey},
    ],
    SlidesTables.slideLayout: [
      {SlideLayoutCols.masterId, SlidesCols.sortKey},
    ],
    SlidesTables.chartLink: [
      {
        ChartLinkCols.sourceSpecJson,
        ChartLinkCols.dataSnapshotJson,
        ChartLinkCols.sourceVersion,
        ChartLinkCols.sheetId,
        ChartLinkCols.updatedAt,
        ChartLinkCols.updatedBy,
      },
    ],
    SlidesTables.deck: [
      {DeckCols.width, DeckCols.height, DeckCols.sizePreset},
    ],
  });

  /// Tables whose inserts are undone column by column: table cells, whose
  /// deterministic ids (`SlidesIds.tableCellId`) let two users create the
  /// same row, like Sheets' cells (02 §3.6). Undoing a cell insert someone
  /// else changed since doesn't delete the cell; the columns still holding
  /// what the insert wrote are cleared, the others are skipped.
  static const columnwise = TableColumnwiseInserts({
    SlidesTables.slideTableCell: {
      SlidesCols.id,
      SlidesCols.elementId,
      TableCellCols.rowId,
      TableCellCols.columnId,
      SlidesCols.createdAt,
    },
  });
}
