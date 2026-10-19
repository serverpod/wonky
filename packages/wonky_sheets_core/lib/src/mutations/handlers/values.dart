import 'package:wonky_sync_models/ids.dart';

import '../../addressing/grid_geometry.dart';
import '../../content/cell_content.dart';
import '../../content/rich_text.dart';
import '../../format/attributes.dart';
import '../../format/format_resolver.dart';
import '../../input/input_parser.dart';
import '../../model/grid_range.dart';
import '../../model/schema.dart';
import '../../model/sheet_model.dart';
import '../operations.dart';
import '../plan_builder.dart';
import '../row_change.dart';
import 'helpers.dart';
import 'rules.dart';

/// Effective number format at a cell (overlay-aware for the cell level).
String? effectiveNumberFormat(
  PlanBuilder b,
  SheetModel s,
  String rowId,
  String colId,
) {
  final cell = b.currentCell(s.id, rowId, colId);
  final explicit = cell?[CellCols.numberFormat] as String?;
  if (explicit != null) return explicit;
  final row =
      b.formatJsonOf(SheetsTables.sheetRow, rowId)[FormatAttr.numberFormat]
          as String?;
  if (row != null) return row;
  final col =
      b.formatJsonOf(SheetsTables.sheetColumn, colId)[FormatAttr.numberFormat]
          as String?;
  if (col != null) return col;
  return s.record?.format[FormatAttr.numberFormat] as String?;
}

bool _isAutomatic(String? f) => f == null || f == kAutomaticNumberFormat;

/// Converts one [CellInput] at a cell to column writes (content + auto
/// number format + auto link).
Map<String, Object?> inputColumns(
  PlanBuilder b,
  SheetModel s,
  String rowId,
  String colId,
  int row,
  int col,
  CellInput input, {
  String? parseLocale,
  String? Function()? numberFormat,
}) {
  switch (input) {
    case ContentCellInput(:final content):
      return {CellCols.content: content?.encode()};
    case RawCellInput(:final value):
      final cv = CellValue.from(value);
      return {CellCols.content: CellContent.fromValue(cv)?.encode()};
    case UserCellInput(:final text):
      final locale = parseLocale ?? b.locale;
      final fmt = numberFormat != null
          ? numberFormat()
          : effectiveNumberFormat(b, s, rowId, colId);
      final parsed = InputParser.instance.parse(
        text,
        locale: locale,
        targetNumberFormat: fmt,
        today: b.ctx.now,
      );
      final out = <String, Object?>{};
      if (parsed.isFormula) {
        final stored = b.formulas.toStored(
          parsed.formulaA1!,
          sheetId: s.id,
          row: row,
          col: col,
          locale: locale,
        );
        out[CellCols.content] = stored.startsWith('=') ? stored : '=$stored';
      } else {
        out[CellCols.content] = parsed.content?.encode();
      }
      if (parsed.autoNumberFormat != null && _isAutomatic(fmt)) {
        out[CellCols.numberFormat] = parsed.autoNumberFormat;
      }
      if (parsed.autoLinkUrl != null) {
        out[CellCols.linkUrl] = parsed.autoLinkUrl;
      }
      return out;
  }
}

/// [SetCellInputs].
MutationPlan planSetCellInputs(PlanBuilder b, SetCellInputs op) {
  final s = b.sheetOf(op.sheetId);
  final height = op.inputs.length;
  var width = 0;
  for (final r in op.inputs) {
    if (r.length > width) width = r.length;
  }
  if (height == 0 || width == 0) return b.build(op.label ?? 'Edit cells');
  final needRows = op.row + height - s.rows.length;
  final needCols = op.col + width - s.columns.length;
  final extraRows = <String>[];
  final extraCols = <String>[];
  if (needRows > 0 || needCols > 0) {
    if (!op.growGrid) {
      throw PlanException(
        'invalid_range',
        'The values extend beyond the grid of "${s.name}"',
      );
    }
    b.checkCellLimit(
      b.gridCellsWith(
        s.id,
        s.rows.length + (needRows > 0 ? needRows : 0),
        s.columns.length + (needCols > 0 ? needCols : 0),
      ),
    );
    extraRows.addAll(b.appendDimension(s, Dimension.rows, needRows));
    extraCols.addAll(b.appendDimension(s, Dimension.columns, needCols));
  }
  String rowIdAt(int i) =>
      i < s.rows.length ? s.rows.idAt(i) : extraRows[i - s.rows.length];
  String colIdAt(int i) => i < s.columns.length
      ? s.columns.idAt(i)
      : extraCols[i - s.columns.length];
  // The effective number format is cell ▸ row ▸ column ▸ sheet: the row and
  // column formats are read once per row and column, not per cell (a 1M
  // cell paste, P9).
  final sheetFormat = s.record?.format[FormatAttr.numberFormat] as String?;
  final colIds = [for (var c = 0; c < width; c++) colIdAt(op.col + c)];
  final colFormats = List<String?>.filled(width, null);
  final colFormatKnown = List<bool>.filled(width, false);
  var cells = 0;
  for (var r = 0; r < height; r++) {
    final rowInputs = op.inputs[r];
    final rowId = rowIdAt(op.row + r);
    String? rowFormat;
    var rowFormatKnown = false;
    for (var c = 0; c < rowInputs.length; c++) {
      final colId = colIds[c];
      final id = SheetsIds.cellId(s.id, rowId, colId);
      final cur = b.current(SheetsTables.cell, id);
      String? format() {
        final explicit = cur?[CellCols.numberFormat] as String?;
        if (explicit != null) return explicit;
        if (!rowFormatKnown) {
          rowFormatKnown = true;
          rowFormat =
              b.formatJsonOf(
                    SheetsTables.sheetRow,
                    rowId,
                  )[FormatAttr.numberFormat]
                  as String?;
        }
        if (rowFormat != null) return rowFormat;
        if (!colFormatKnown[c]) {
          colFormatKnown[c] = true;
          colFormats[c] =
              b.formatJsonOf(
                    SheetsTables.sheetColumn,
                    colId,
                  )[FormatAttr.numberFormat]
                  as String?;
        }
        return colFormats[c] ?? sheetFormat;
      }

      final cols = inputColumns(
        b,
        s,
        rowId,
        colId,
        op.row + r,
        op.col + c,
        rowInputs[c],
        parseLocale: op.parseLocale,
        numberFormat: format,
      );
      b.writeCellOf(id, s.id, rowId, colId, cols, cur);
      cells++;
    }
  }

  b.summary.sheets.add(s.id);
  if (extraRows.isEmpty && extraCols.isEmpty) {
    b.addResolvedRange(
      ResolvedRange(
        s.id,
        GridRect(op.row, op.col, op.row + height - 1, op.col + width - 1),
      ),
    );
  }
  b.result['cells'] = cells;
  return b.build(
    op.label ?? (cells == 1 ? 'Edit cell' : 'Edit cells'),
    kinds: [ChangeKinds.values],
  );
}

/// [ClearRanges].
MutationPlan planClearRanges(PlanBuilder b, ClearRanges op) {
  var cleared = 0;
  for (final range in op.ranges) {
    final s = b.sheetOf(range.sheetId);
    b.addResolvedRange(range);
    switch (op.what) {
      case ClearWhat.contents:
        for (final (_, _, rowId, colId, cur)
            in b.cellsIn(s, range.rect).toList()) {
          if (cur[CellCols.content] == null) continue;
          b.writeCell(s.id, rowId, colId, {CellCols.content: null});
          cleared++;
        }
      case ClearWhat.notes:
        for (final (_, _, rowId, colId, cur)
            in b.cellsIn(s, range.rect).toList()) {
          if (cur[CellCols.note] == null) continue;
          b.writeCell(s.id, rowId, colId, {CellCols.note: null});
          cleared++;
        }
      case ClearWhat.links:
        for (final (_, _, rowId, colId, cur)
            in b.cellsIn(s, range.rect).toList()) {
          final writes = <String, Object?>{};
          if (cur[CellCols.linkUrl] != null) writes[CellCols.linkUrl] = null;
          final content = CellContent.decode(cur[CellCols.content] as String?);
          if (content is RichTextContent && content.rich.links.isNotEmpty) {
            final n = content.rich.withoutKey(RichRunKeys.link).normalize();
            writes[CellCols.content] = n.rich == null
                ? TextContent(content.rich.text).encode()
                : RichTextContent(n.rich!).encode();
          }
          if (writes.isEmpty) continue;
          b.writeCell(s.id, rowId, colId, writes);
          cleared++;
        }
      case ClearWhat.formats:
        cleared += clearFormattingIn(b, s, range);
      case ClearWhat.validation:
        clearValidationIn(b, s, [range.rect]);
      case ClearWhat.all:
        for (final (_, _, rowId, colId, _)
            in b.cellsIn(s, range.rect).toList()) {
          b.deleteCell(s.id, rowId, colId);
          cleared++;
        }
        clearRowColFormats(b, s, range, FormatAttr.values);
    }
  }
  b.result['cells'] = cleared;
  final kinds = switch (op.what) {
    ClearWhat.contents => [ChangeKinds.values],
    ClearWhat.notes => [ChangeKinds.notes],
    ClearWhat.links => [ChangeKinds.values, ChangeKinds.format],
    ClearWhat.formats => [ChangeKinds.format],
    ClearWhat.validation => [ChangeKinds.rules],
    ClearWhat.all => [
      ChangeKinds.values,
      ChangeKinds.format,
      ChangeKinds.notes,
    ],
  };
  final label = switch (op.what) {
    ClearWhat.contents => 'Delete values',
    ClearWhat.notes => 'Clear notes',
    ClearWhat.links => 'Remove link',
    ClearWhat.formats => 'Clear formatting',
    ClearWhat.validation => 'Remove data validation',
    ClearWhat.all => 'Clear',
  };
  return b.build(label, kinds: kinds);
}

/// Clear formatting inside one range (06 §3); returns cells touched.
int clearFormattingIn(PlanBuilder b, SheetModel s, ResolvedRange range) {
  var n = 0;
  final attrs = FormatAttr.clearable;
  for (final (_, _, rowId, colId, cur) in b.cellsIn(s, range.rect).toList()) {
    final writes = <String, Object?>{
      for (final a in attrs)
        if (cur[a.column] != null) a.column: null,
    };
    final content = CellContent.decode(cur[CellCols.content] as String?);
    if (content is RichTextContent) {
      final links = content.rich.onlyLinks().normalize();
      writes[CellCols.content] = links.rich == null
          ? TextContent(content.rich.text).encode()
          : RichTextContent(links.rich!).encode();
      if (links.wholeCellLink != null && cur[CellCols.linkUrl] == null) {
        writes[CellCols.linkUrl] = links.wholeCellLink;
      }
    }
    if (writes.isEmpty) continue;
    b.writeCell(s.id, rowId, colId, writes);
    n++;
  }
  clearRowColFormats(b, s, range, attrs);
  return n;
}

/// Removes [attrs] from row/column/sheet `formatJson` when the range covers
/// whole rows/columns/the sheet.
void clearRowColFormats(
  PlanBuilder b,
  SheetModel s,
  ResolvedRange range,
  Iterable<FormatAttr> attrs,
) {
  final remove = {for (final a in attrs) a: null};
  if (range.wholeSheet) {
    b.writeFormatJson(SheetsTables.sheet, s.id, remove);
    for (final id in s.rowRecords.keys) {
      b.writeFormatJson(SheetsTables.sheetRow, id, remove);
    }
    for (final id in s.columnRecords.keys) {
      b.writeFormatJson(SheetsTables.sheetColumn, id, remove);
    }
    return;
  }
  if (range.wholeRows) {
    for (var r = range.rect.top; r <= range.rect.bottom; r++) {
      b.writeFormatJson(SheetsTables.sheetRow, s.rows.idAt(r), remove);
    }
  }
  if (range.wholeColumns) {
    for (var c = range.rect.left; c <= range.rect.right; c++) {
      b.writeFormatJson(SheetsTables.sheetColumn, s.columns.idAt(c), remove);
    }
  }
}

/// [SetNote].
MutationPlan planSetNote(PlanBuilder b, SetNote op) {
  final s = b.sheetOf(op.sheetId);
  b.checkRect(s, GridRect.cell(op.row, op.col));
  final note = op.note == null || op.note!.isEmpty ? null : op.note;
  b.writeCellAt(s.id, op.row, op.col, {CellCols.note: note});
  b.addResolvedRange(ResolvedRange(s.id, GridRect.cell(op.row, op.col)));
  return b.build(
    note == null ? 'Delete note' : 'Edit note',
    kinds: [ChangeKinds.notes],
  );
}

/// [SetLink].
MutationPlan planSetLink(PlanBuilder b, SetLink op) {
  for (final range in op.ranges) {
    final s = b.sheetOf(range.sheetId);
    b.addResolvedRange(range);
    if (op.url == null) {
      return planClearRanges(b, ClearRanges(op.ranges, what: ClearWhat.links));
    }
    final rect = range.rect;
    if (op.text != null && rect.isSingleCell) {
      b.writeCellAt(s.id, rect.top, rect.left, {
        CellCols.content: TextContent(op.text!).encode(),
        CellCols.linkUrl: op.url,
      });
      continue;
    }
    for (var r = rect.top; r <= rect.bottom; r++) {
      for (var c = rect.left; c <= rect.right; c++) {
        b.writeCellAt(s.id, r, c, {CellCols.linkUrl: op.url});
      }
    }
  }
  return b.build(
    op.url == null ? 'Remove link' : 'Insert link',
    kinds: [ChangeKinds.values],
  );
}

/// [RestoreCellValue].
MutationPlan planRestoreCellValue(PlanBuilder b, RestoreCellValue op) {
  final s = b.sheetOf(op.sheetId);
  b.writeCell(s.id, op.rowId, op.colId, {CellCols.content: op.content});
  final r = s.rows.indexOf(op.rowId);
  final c = s.columns.indexOf(op.colId);
  if (r >= 0 && c >= 0) {
    b.addResolvedRange(ResolvedRange(s.id, GridRect.cell(r, c)));
  }
  return b.build('Restore value', kinds: [ChangeKinds.values]);
}
