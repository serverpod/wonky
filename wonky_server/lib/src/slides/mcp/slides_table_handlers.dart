import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart';
import 'package:wonky_slides_core/schema.dart';

import '../../platform/mcp/tool_support.dart';
import 'slides_input.dart';
import 'slides_mcp_support.dart';
import 'slides_writes.dart';

/// MCP tools for table cells in decks (Slides 11 §3).
abstract final class SlidesTableHandlers {
  static Future<ToolResult> setTableCells(ToolContext ctx, ToolArgs a) async {
    final t = await SlidesMcp.edit(ctx, a);
    final warnings = <SlidesWarning>[];
    final o = await SlidesWrites.run(
      ctx,
      t,
      tool: 'slides.set_table_cells',
      force: a.boolean('force') ?? false,
      warnings: warnings,
      build: (s) {
        final m = s.model;
        final id = SlidesMcp.elementId(m, a.values['element']);
        SlidesMcp.elementOfKind(m, id, {ElementKind.table}, 'a table');
        for (final (dim, key) in [
          (TableAxisDimension.row, 'insert_rows'),
          (TableAxisDimension.column, 'insert_columns'),
        ]) {
          for (final raw in a.list(key) ?? const []) {
            final ins = (raw! as Map).cast<String, Object?>();
            s.run(
              InsertTableAxes(
                id,
                dim,
                (ins['at']! as num).toInt(),
                count: (ins['count'] as num?)?.toInt() ?? 1,
              ),
            );
          }
        }
        for (final (dim, key) in [
          (TableAxisDimension.row, 'delete_rows'),
          (TableAxisDimension.column, 'delete_columns'),
        ]) {
          final axes = m.axesOf(id, dim);
          final del = <String>[];
          for (final raw in a.list(key) ?? const []) {
            final i = (raw! as num).toInt();
            if (i >= axes.length) {
              throw SlidesMcp.invalid(
                'The table has ${axes.length} ${dim.name}s.',
                pointer: '/$key',
              );
            }
            del.add(axes[i].id);
          }
          if (del.isNotEmpty) s.run(DeleteTableAxes(id, del));
        }
        final rows = m.axesOf(id, TableAxisDimension.row);
        final cols = m.axesOf(id, TableAxisDimension.column);
        final writes = <CellWrite>[];
        for (final (i, raw) in (a.list('cells') ?? const []).indexed) {
          final c = (raw! as Map).cast<String, Object?>();
          final r = (c['row']! as num).toInt();
          final k = (c['column']! as num).toInt();
          if (r >= rows.length || k >= cols.length) {
            throw SlidesMcp.invalid(
              'Cell ($r, $k) is outside the ${rows.length} × ${cols.length} '
              'table.',
              pointer: '/cells/$i',
            );
          }
          writes.add(
            CellWrite(rows[r].id, cols[k].id, {
              if (c.containsKey('text'))
                SlidesCols.text: SlidesInput.text(
                  m,
                  c['text'],
                  pointer: '/cells/$i/text',
                  warnings: warnings,
                  elementId: id,
                ),
              if (c.containsKey('fill')) TableCellCols.fill: c['fill'],
            }),
          );
        }
        if (writes.isNotEmpty) s.run(SetCells(id, writes));
      },
    );
    return SlidesWrites.result(o, 'Updated the table');
  }
}
