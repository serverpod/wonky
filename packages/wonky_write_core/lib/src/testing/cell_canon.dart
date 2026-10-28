/// Comparing documents with tables in tests (Write 12 §5.1).
library;

import 'package:dart_quill_delta/dart_quill_delta.dart';

import '../delta/attributes.dart';
import '../delta/cells.dart';
import '../delta/document.dart';
import '../edit/cell_edits.dart';

/// Normal forms of tables for comparisons: row ids are random and ragged
/// rows export as complete ones, so tests compare [canonical] forms.
abstract final class CellCanon {
  /// [document] with every table's ragged rows completed, its row ids
  /// replaced by `r0`, `r1`, … (per table, in order) and every cell's
  /// alignment set to its column's (the header's, §1.1).
  static Delta canonical(Delta document) {
    var doc = WonkyDocument(document);
    for (final run in CellRuns.of(doc)) {
      if (run is! CellTable) continue;
      final change = CellEdits.completeRows(doc, run.id);
      if (change != null) doc = WonkyDocument(doc.delta.compose(change));
    }
    final align = {
      for (final run in CellRuns.of(doc))
        if (run is CellTable) run.id: run.align,
    };
    final out = Delta();
    final rowIndex = <String, Map<String, int>>{};
    // The column of the next cell line per table and row.
    final column = <String, int>{};
    for (final line in doc.lines) {
      for (final s in line.segments) {
        out.insert(s.data, s.attributes);
      }
      if (!line.hasNewline) continue;
      final cell = CellAttr.of(line.attributes);
      if (cell == null) {
        out.insert('\n', line.attributes.isEmpty ? null : line.attributes);
        continue;
      }
      final rows = rowIndex.putIfAbsent(cell.table, () => {});
      final r = rows.putIfAbsent(cell.row, () => rows.length);
      final key = '${cell.table}/${cell.row}';
      final c = column[key] = (column[key] ?? -1) + 1;
      final columns = align[cell.table]!;
      out.insert('\n', {
        ...line.attributes,
        WonkyAttr.cell: CellAttr(
          table: cell.table,
          row: 'r$r',
          align: c < columns.length ? columns[c] : null,
        ).toJson(),
      });
    }
    return out;
  }

  /// The ids of [document]'s embeds, tables and grids in document order:
  /// the order in which an importer asks its id generator for them.
  static List<String> blockIds(Delta document) {
    final ids = <String>[];
    String? prevGroup;
    for (final line in WonkyDocument(document).lines) {
      final group =
          CellAttr.of(line.attributes)?.table ??
          GridItemAttr.of(line.attributes)?.id;
      if (group != null && group != prevGroup) ids.add(group);
      prevGroup = group;
      if (group != null) continue;
      if (line.isEmbedLine) {
        final embed = line.embed;
        if (embed != null) ids.add(embed.id);
      }
    }
    return ids;
  }
}
