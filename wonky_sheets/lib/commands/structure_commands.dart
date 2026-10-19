import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:shad/shad.dart' show LucideIcons;
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect, ColumnLetters;
import 'package:wonky_sheets_core/model.dart';

import '../features/dialogs/sheets_dialogs.dart';
import '../features/grid/paint/layers/content_layers.dart';
import '../features/grid/paint/text_layout_cache.dart';
import '../features/grid/selection/grid_selection.dart';
import '../features/sheet_editor/sheet_editor_controller.dart';
import 'cell_commands.dart' show rowsLabel, colsLabel;
import 'sheets_command.dart';

String _rc(SheetsLocalizations l) => l.categoryRowsColumns;

/// The selected index span of [d] (active range), clipped to the grid.
(int, int) _span(SheetEditorController ed, Dimension d) {
  final r = ed.selection.resolved.activeRange.rect;
  final s = ed.activeSheet!;
  return d == Dimension.rows
      ? (r.top, math.min(r.bottom, s.rows.length - 1))
      : (r.left, math.min(r.right, s.columns.length - 1));
}

int _count(SheetEditorController ed, Dimension d) {
  final (a, b) = _span(ed, d);
  return b - a + 1;
}

/// Ids of an `ids` argument, else of the selected rows/columns (all ranges).
List<String> _ids(SheetEditorController ed, Dimension d, JsonArgs a) {
  final given = a.strings('ids');
  if (given.isNotEmpty) return given;
  final axis = ed.activeSheet!.axis(d);
  final out = <String>{};
  for (final r in ed.selection.resolved.ranges) {
    final lo = d == Dimension.rows ? r.rect.top : r.rect.left;
    final hi = math.min(
      d == Dimension.rows ? r.rect.bottom : r.rect.right,
      axis.length - 1,
    );
    for (var i = lo; i <= hi; i++) {
      out.add(axis.idAt(i));
    }
  }
  return out.toList();
}

const _idsSchema = JsonSchema.object(
  properties: {
    'ids': JsonSchema.array(
      JsonSchema.string(),
      description: 'Row/column ids (default: the selection).',
    ),
  },
);

/// Width that fits the displayed values of column [col] (03 §13.6).
double autoFitWidth(SheetEditorController ed, int col) {
  final s = ed.activeSheet!;
  final colId = s.columns.idAt(col);
  final cache = TextLayoutCache(capacity: 4096);
  var w = 30.0;
  for (final cell in s.cells.inColumn(colId)) {
    final r = s.rows.indexOf(cell.rowId);
    if (r < 0) continue;
    final d = ed.cells.displayAt(s.id, r, col);
    if (d == null || d.text.isEmpty) continue;
    final f = d.format;
    final p = cache.layout(
      d.text,
      GridTextStyle(
        fontFamily: f.fontFamily,
        fontSize: f.fontSize * kPointToPx,
        color: const Color(0xFF000000),
        bold: f.bold,
        italic: f.italic,
      ),
    );
    w = math.max(w, p.maxIntrinsicWidth + 2 * kCellPadH + 4);
  }
  cache.clear();
  return math.min(1000, w.ceilToDouble());
}

SheetsCommand _insert(
  String id,
  Dimension d, {
  required bool after,
  required SheetsText label,
  required String Function(SheetsLocalizations l, int n) dynamic,
  IconData? icon,
}) => SheetsCommand(
  id,
  label: label,
  icon: icon,
  categoryName: _rc,
  mutates: true,
  repeatable: true,
  dynamicLabel: (l, ed) => dynamic(l, _count(ed, d)),
  argsSchema: const JsonSchema.object(
    properties: {'count': JsonSchema.integer(minimum: 1, maximum: 10000)},
  ),
  run: (ctx, ed, a) {
    final (lo, hi) = _span(ed, d);
    final count = a.integer('count') ?? (hi - lo + 1);
    ed.apply(
      ctx,
      InsertDimension(
        ed.activeSheetId,
        d,
        after ? hi + 1 : lo,
        count,
        inheritFrom: after ? InheritFrom.before : InheritFrom.after,
      ),
    );
    if (!after) {
      // Keep the selection on the same data (it moved down/right).
      final sel = ed.selection.resolved;
      ed.selection.setRanges([
        for (final r in sel.ranges)
          (
            r.kind,
            d == Dimension.rows
                ? GridRect(lo, r.rect.left, lo + count - 1, r.rect.right)
                : GridRect(r.rect.top, lo, r.rect.bottom, lo + count - 1),
          ),
      ]);
    }
    return ok();
  },
);

/// Row, column, cell-shift, freeze and merge structure commands (03 §13,
/// 04 §3.2–3.4).
List<Command<CommandArgs>> structureCommands(ShellServices s) => [
  _insert(
    'sheets.rows.insertAbove',
    Dimension.rows,
    after: false,
    label: (l) => l.cmdRowsInsertAbove,
    dynamic: (l, n) => l.cmdRowsInsertAboveN(n),
    icon: LucideIcons.arrowUpToLine,
  ),
  _insert(
    'sheets.rows.insertBelow',
    Dimension.rows,
    after: true,
    label: (l) => l.cmdRowsInsertBelow,
    dynamic: (l, n) => l.cmdRowsInsertBelowN(n),
    icon: LucideIcons.arrowDownToLine,
  ),
  _insert(
    'sheets.cols.insertLeft',
    Dimension.columns,
    after: false,
    label: (l) => l.cmdColsInsertLeft,
    dynamic: (l, n) => l.cmdColsInsertLeftN(n),
    icon: LucideIcons.arrowLeftToLine,
  ),
  _insert(
    'sheets.cols.insertRight',
    Dimension.columns,
    after: true,
    label: (l) => l.cmdColsInsertRight,
    dynamic: (l, n) => l.cmdColsInsertRightN(n),
    icon: LucideIcons.arrowRightToLine,
  ),
  SheetsCommand(
    'sheets.rows.addMore',
    label: (l) => l.cmdRowsAddMore,
    categoryName: _rc,
    mutates: true,
    argsSchema: const JsonSchema.object(
      properties: {'count': JsonSchema.integer(minimum: 1, maximum: 100000)},
    ),
    run: (ctx, ed, a) {
      final sh = ed.activeSheet!;
      ed.apply(
        ctx,
        InsertDimension(
          sh.id,
          Dimension.rows,
          sh.rows.length,
          a.integer('count') ?? 1000,
        ),
      );
      return ok();
    },
  ),
  for (final d in Dimension.values)
    SheetsCommand(
      d == Dimension.rows ? 'sheets.rows.delete' : 'sheets.cols.delete',
      label: (l) => d == Dimension.rows ? l.cmdRowsDelete : l.cmdColsDelete,
      icon: LucideIcons.trash2,
      categoryName: _rc,
      mutates: true,
      repeatable: true,
      dynamicLabel: (l, ed) {
        final (a, b) = _span(ed, d);
        return d == Dimension.rows
            ? l.cmdDeleteRowsLabel(rowsLabel(l, a, b))
            : l.cmdDeleteColumnsLabel(colsLabel(l, a, b));
      },
      argsSchema: _idsSchema,
      run: (ctx, ed, a) {
        final ids = _ids(ed, d, a);
        final axis = ed.activeSheet!.axis(d);
        if (ids.length >= axis.length) {
          return CommandResult.failed(
            d == Dimension.rows
                ? ed.l10n.toastCantDeleteAllRows
                : ed.l10n.toastCantDeleteAllColumns,
          );
        }
        ed.apply(ctx, DeleteDimension(ed.activeSheetId, d, ids));
        return ok();
      },
    ),
  for (final d in Dimension.values)
    for (final hide in [true, false])
      SheetsCommand(
        '${d == Dimension.rows ? 'sheets.rows' : 'sheets.cols'}.${hide ? 'hide' : 'unhide'}',
        label: (l) => switch ((d, hide)) {
          (Dimension.rows, true) => l.cmdRowsHide,
          (Dimension.rows, false) => l.cmdRowsUnhide,
          (_, true) => l.cmdColsHide,
          _ => l.cmdColsUnhide,
        },
        icon: hide ? LucideIcons.eyeOff : LucideIcons.eye,
        categoryName: _rc,
        mutates: true,
        dynamicLabel: hide
            ? (l, ed) {
                final (a, b) = _span(ed, d);
                return d == Dimension.rows
                    ? l.cmdHideRowsLabel(rowsLabel(l, a, b))
                    : l.cmdHideColumnsLabel(colsLabel(l, a, b));
              }
            : null,
        defaultBindings: [
          if (d == Dimension.rows && hide)
            const KeyBinding('9', mod: true, alt: true),
          if (d == Dimension.rows && !hide)
            const KeyBinding('9', mod: true, shift: true),
          if (d == Dimension.columns && hide)
            const KeyBinding('0', mod: true, alt: true),
          if (d == Dimension.columns && !hide)
            const KeyBinding('0', mod: true, shift: true),
        ],
        argsSchema: _idsSchema,
        run: (ctx, ed, a) {
          var ids = _ids(ed, d, a);
          final axis = ed.activeSheet!.axis(d);
          if (!hide && a.strings('ids').isEmpty) {
            // Unhide hidden runs inside or adjacent to the selection.
            final (lo, hi) = _span(ed, d);
            final from = math.max(0, lo - 1);
            final to = math.min(axis.length - 1, hi + 1);
            ids = [
              for (var i = from; i <= to; i++)
                if (axis.isUserHidden(i)) axis.idAt(i),
            ];
            var i = to + 1;
            while (i < axis.length && axis.isUserHidden(i)) {
              ids.add(axis.idAt(i));
              i++;
            }
            i = from - 1;
            while (i >= 0 && axis.isUserHidden(i)) {
              ids.add(axis.idAt(i));
              i--;
            }
          }
          if (ids.isEmpty) return const CommandResult.cancelled();
          if (hide && ids.length >= axis.length) {
            return CommandResult.failed(ed.l10n.toastCantHideAll);
          }
          ed.apply(
            ctx,
            SetDimensionHidden(ed.activeSheetId, d, ids, hidden: hide),
          );
          if (hide) {
            // Move the active cell to the next visible row/column.
            final (lo, hi) = _span(ed, d);
            final next =
                axis.nextVisible(hi + 1, 1) ?? axis.nextVisible(lo, -1);
            final sel = ed.selection.resolved;
            if (next != null) {
              ed.selection.selectCell(
                d == Dimension.rows ? next : sel.activeRow,
                d == Dimension.rows ? sel.activeCol : next,
              );
            }
          }
          return ok();
        },
      ),
  for (final d in Dimension.values)
    SheetsCommand(
      d == Dimension.rows ? 'sheets.rows.resize' : 'sheets.cols.resize',
      label: (l) => d == Dimension.rows ? l.cmdRowsResize : l.cmdColsResize,
      categoryName: _rc,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'ids': JsonSchema.array(JsonSchema.string()),
          'size': JsonSchema.nullable(
            JsonSchema.number(minimum: 2, maximum: 5000),
          ),
        },
      ),
      run: (ctx, ed, a) {
        final size = (a.values['size'] as num?)?.toDouble();
        ed.apply(
          ctx,
          ResizeDimension(ed.activeSheetId, d, _ids(ed, d, a), size),
        );
        return ok();
      },
    ),
  for (final d in Dimension.values)
    SheetsCommand(
      d == Dimension.rows ? 'sheets.rows.autoFit' : 'sheets.cols.autoFit',
      label: (l) => l.cmdFitToData,
      categoryName: _rc,
      mutates: true,
      argsSchema: _idsSchema,
      run: (ctx, ed, a) {
        final ids = _ids(ed, d, a);
        if (d == Dimension.rows) {
          ed.apply(ctx, ResizeDimension(ed.activeSheetId, d, ids, null));
          return ok();
        }
        // Group columns by fitted width (one plan per width).
        final byWidth = <double, List<String>>{};
        final axis = ed.activeSheet!.columns;
        for (final id in ids) {
          final i = axis.indexOf(id);
          if (i < 0) continue;
          byWidth.putIfAbsent(autoFitWidth(ed, i), () => []).add(id);
        }
        for (final e in byWidth.entries) {
          ed.apply(ctx, ResizeDimension(ed.activeSheetId, d, e.value, e.key));
        }
        return ok();
      },
    ),
  for (final d in Dimension.values)
    SheetsCommand(
      d == Dimension.rows
          ? 'sheets.rows.openResizeDialog'
          : 'sheets.cols.openResizeDialog',
      label: (l) =>
          d == Dimension.rows ? l.cmdRowsResizeDialog : l.cmdColsResizeDialog,
      categoryName: _rc,
      mutates: true,
      dynamicLabel: (l, ed) {
        final (a, b) = _span(ed, d);
        return d == Dimension.rows
            ? l.cmdResizeRowsLabel(rowsLabel(l, a, b))
            : l.cmdResizeColumnsLabel(colsLabel(l, a, b));
      },
      undoLabelOf: (l, a) =>
          d == Dimension.rows ? l.cmdRowsResize : l.cmdColsResize,
      run: (ctx, ed, a) async {
        final c = ctx.dialogContext;
        if (c == null) return const CommandResult.cancelled();
        final (lo, hi) = _span(ed, d);
        final axis = ed.activeSheet!.axis(d);
        final title = d == Dimension.rows
            ? ed.l10n.cmdResizeRowsLabel(rowsLabel(ed.l10n, lo, hi))
            : ed.l10n.cmdResizeColumnsLabel(colsLabel(ed.l10n, lo, hi));
        final r = await showResizeDialog(
          c,
          title: title,
          rows: d == Dimension.rows,
          current: axis.naturalSizeAt(lo),
        );
        if (r == null) return const CommandResult.cancelled();
        final ids = _ids(ed, d, const JsonArgs());
        if (r.fit) {
          if (d == Dimension.rows) {
            await ed.applyConfirmed(
              ctx,
              ResizeDimension(ed.activeSheetId, d, ids, null),
            );
          } else {
            for (final id in ids) {
              await ed.applyConfirmed(
                ctx,
                ResizeDimension(ed.activeSheetId, d, [
                  id,
                ], autoFitWidth(ed, axis.indexOf(id))),
              );
            }
          }
        } else {
          await ed.applyConfirmed(
            ctx,
            ResizeDimension(ed.activeSheetId, d, ids, r.size),
          );
        }
        return ok();
      },
    ),
  for (final d in Dimension.values)
    SheetsCommand(
      d == Dimension.rows
          ? 'sheets.rows.openInsertDialog'
          : 'sheets.cols.openInsertDialog',
      label: (l) =>
          d == Dimension.rows ? l.cmdRowsInsertDialog : l.cmdColsInsertDialog,
      categoryName: _rc,
      mutates: true,
      run: (ctx, ed, a) async {
        final c = ctx.dialogContext;
        if (c == null) return const CommandResult.cancelled();
        final r = await showInsertDimensionDialog(c, rows: d == Dimension.rows);
        if (r == null) return const CommandResult.cancelled();
        final (lo, hi) = _span(ed, d);
        await ed.applyConfirmed(
          ctx,
          InsertDimension(
            ed.activeSheetId,
            d,
            r.after ? hi + 1 : lo,
            r.count,
            inheritFrom: r.after ? InheritFrom.before : InheritFrom.after,
          ),
        );
        return ok();
      },
    ),
  for (final (id, d, before, label) in [
    (
      'sheets.rows.moveUp',
      Dimension.rows,
      true,
      (SheetsLocalizations l) => l.cmdRowsMoveUp,
    ),
    (
      'sheets.rows.moveDown',
      Dimension.rows,
      false,
      (SheetsLocalizations l) => l.cmdRowsMoveDown,
    ),
    (
      'sheets.cols.moveLeft',
      Dimension.columns,
      true,
      (SheetsLocalizations l) => l.cmdColsMoveLeft,
    ),
    (
      'sheets.cols.moveRight',
      Dimension.columns,
      false,
      (SheetsLocalizations l) => l.cmdColsMoveRight,
    ),
  ])
    SheetsCommand(
      id,
      label: label,
      categoryName: _rc,
      mutates: true,
      enabled: (ed, a) {
        final (lo, hi) = _span(ed, d);
        final n = ed.activeSheet!.axis(d).length;
        return before ? lo > 0 : hi < n - 1;
      },
      run: (ctx, ed, a) {
        final (lo, hi) = _span(ed, d);
        final axis = ed.activeSheet!.axis(d);
        final ids = [for (var i = lo; i <= hi; i++) axis.idAt(i)];
        final beforeId = before
            ? axis.idAt(lo - 1)
            : (hi + 2 < axis.length ? axis.idAt(hi + 2) : null);
        ed.apply(ctx, MoveDimension(ed.activeSheetId, d, ids, beforeId));
        final shift = before ? -1 : 1;
        final sel = ed.selection.resolved;
        ed.selection.setRanges(
          [
            for (final r in sel.ranges)
              (
                r.kind,
                d == Dimension.rows
                    ? r.rect.shift(r.wholeColumns ? 0 : shift, 0)
                    : r.rect.shift(0, r.wholeRows ? 0 : shift),
              ),
          ],
          activeRow: sel.activeRow + (d == Dimension.rows ? shift : 0),
          activeCol: sel.activeCol + (d == Dimension.columns ? shift : 0),
        );
        return ok();
      },
    ),
  for (final d in Dimension.values)
    SheetsCommand(
      d == Dimension.rows ? 'sheets.rows.move' : 'sheets.cols.move',
      label: (l) => d == Dimension.rows ? l.cmdRowsMove : l.cmdColsMove,
      categoryName: _rc,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'ids': JsonSchema.array(JsonSchema.string()),
          'before': JsonSchema.nullable(JsonSchema.string()),
        },
        required: ['ids'],
      ),
      run: (ctx, ed, a) {
        ed.apply(
          ctx,
          MoveDimension(
            ed.activeSheetId,
            d,
            a.strings('ids'),
            a.string('before'),
          ),
        );
        return ok();
      },
    ),
  // ---- Cells shift (03 §13.3) ----
  for (final (id, dir, label) in [
    (
      'sheets.cells.insertShiftRight',
      ShiftDirection.right,
      (SheetsLocalizations l) => l.cmdCellsInsertShiftRight,
    ),
    (
      'sheets.cells.insertShiftDown',
      ShiftDirection.down,
      (SheetsLocalizations l) => l.cmdCellsInsertShiftDown,
    ),
    (
      'sheets.cells.deleteShiftLeft',
      ShiftDirection.left,
      (SheetsLocalizations l) => l.cmdCellsDeleteShiftLeft,
    ),
    (
      'sheets.cells.deleteShiftUp',
      ShiftDirection.up,
      (SheetsLocalizations l) => l.cmdCellsDeleteShiftUp,
    ),
  ])
    SheetsCommand(
      id,
      label: label,
      categoryName: _rc,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'range': JsonSchema.string()},
      ),
      enabled: (ed, a) => ed.selection.resolved.ranges.length == 1,
      run: (ctx, ed, a) {
        ed.apply(ctx, ShiftCells(rangeArg(ed, a), dir));
        return ok();
      },
    ),
  for (final (id, insert) in [
    ('sheets.structure.insertBySelection', true),
    ('sheets.structure.deleteBySelection', false),
  ])
    SheetsCommand(
      id,
      label: (l) => insert
          ? l.cmdStructureInsertBySelection
          : l.cmdStructureDeleteBySelection,
      categoryName: _rc,
      mutates: true,
      defaultBindings: [KeyBinding(insert ? '=' : '-', mod: true, alt: true)],
      run: (ctx, ed, a) async {
        final r = ed.selection.resolved.activeRange;
        final String target;
        if (r.kind == SelectionKind.rows) {
          target = insert ? 'sheets.rows.insertAbove' : 'sheets.rows.delete';
        } else if (r.kind == SelectionKind.columns) {
          target = insert ? 'sheets.cols.insertLeft' : 'sheets.cols.delete';
        } else {
          final c = ctx.dialogContext;
          if (c == null) return const CommandResult.cancelled();
          final choice = await showShiftCellsDialog(c, insert: insert);
          if (choice == null) return const CommandResult.cancelled();
          target = choice;
        }
        return ed.services.dispatcher.invoke(
          target,
          source: ctx.source,
          context: ctx.buildContext,
        );
      },
    ),
  // ---- Move / copy ranges (03 §11) ----
  for (final copy in [false, true])
    SheetsCommand(
      copy ? 'sheets.cells.copyRange' : 'sheets.cells.moveRange',
      label: (l) => copy ? l.cmdCellsCopyRange : l.cmdCellsMoveRange,
      categoryName: _rc,
      mutates: true,
      showInPalette: false,
      argsSchema: const JsonSchema.object(
        properties: {
          'source': JsonSchema.string(),
          'destTopLeft': JsonSchema.string(),
          'copy': JsonSchema.boolean(),
        },
        required: ['source', 'destTopLeft'],
      ),
      run: (ctx, ed, a) async {
        final src = rangeArg(ed, a, 'source');
        final dest = rangeArg(ed, a, 'destTopLeft');
        final destRect = GridRect(
          dest.rect.top,
          dest.rect.left,
          dest.rect.top + src.rect.rowCount - 1,
          dest.rect.left + src.rect.colCount - 1,
        );
        final s = ed.model.sheet(dest.sheetId)!;
        final occupied = s
            .cellsIn(destRect, contentOnly: true)
            .any(
              (e) =>
                  !src.rect.contains(e.$1, e.$2) || src.sheetId != dest.sheetId,
            );
        final c = ctx.dialogContext;
        if (occupied && c != null && !ctx.source.isAgent) {
          if (!await confirmReplaceDataDialog(c)) {
            return const CommandResult.cancelled();
          }
        }
        await ed.applyConfirmed(
          ctx,
          MoveRange(
            src,
            dest.sheetId,
            dest.rect.top,
            dest.rect.left,
            copy: copy || (a.boolean('copy') ?? false),
          ),
        );
        ed.selection.setRanges([(SelectionKind.cells, destRect)]);
        return ok();
      },
    ),
  // ---- Freeze (03 §4) ----
  for (final rows in [true, false])
    SheetsCommand(
      rows ? 'sheets.view.freezeRows' : 'sheets.view.freezeColumns',
      label: (l) => rows ? l.cmdViewFreezeRows : l.cmdViewFreezeColumns,
      icon: LucideIcons.snowflake,
      categoryName: (l) => l.categoryView,
      mutates: true,
      argsSchema: const JsonSchema.object(
        properties: {'count': JsonSchema.integer(minimum: 0, maximum: 1000)},
        required: ['count'],
      ),
      checked: (ed, a) {
        final n = a.integer('count');
        if (n == null) return null;
        final rec = ed.activeSheet?.record;
        return (rows ? rec?.frozenRows : rec?.frozenColumns) == n;
      },
      enabled: (ed, a) {
        final n = a.integer('count');
        final axis = rows ? ed.activeSheet!.rows : ed.activeSheet!.columns;
        return n == null || n < axis.length;
      },
      run: (ctx, ed, a) {
        final n = a.integer('count') ?? 0;
        final g = ed.geometry;
        if (g != null && n > 0) {
          final extent =
              (rows ? g.sheet.rows.offsetOf(n) : g.sheet.columns.offsetOf(n)) *
              g.zoom;
          final avail = rows
              ? g.size.height - g.colHeaderHeight
              : g.size.width - g.rowHeaderWidth;
          if (avail - extent < 50) {
            return CommandResult.failed(ed.l10n.toastFreezeTooLarge);
          }
        }
        ed.apply(
          ctx,
          SetFrozen(
            ed.activeSheetId,
            rows: rows ? n : null,
            columns: rows ? null : n,
          ),
        );
        return ok();
      },
    ),
];

/// Column letter helper for labels.
String columnLetter(int c) => ColumnLetters.fromIndex(c);
