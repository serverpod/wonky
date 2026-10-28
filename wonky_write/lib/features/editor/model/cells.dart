import 'package:super_editor/super_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../mapping/document_mirror.dart';
import '../mapping/wonky_schema.dart';

/// A table or grid of the editor document (Write 12 §3.1): its nodes in the
/// mirror and its lines as a [WonkyDocument] of their own, so [CellEdits]
/// can run on it; [shift] moves a change of [doc] to the whole document.
class EditorCellRun {
  EditorCellRun._(this.first, this.last, this.start, this.doc, this.run);

  /// Mirror index of the run's first node.
  final int first;

  /// Mirror index of the run's last node.
  final int last;

  /// Delta offset of the run's first character.
  final int start;

  /// The run's lines (offset 0 = [start]).
  final WonkyDocument doc;

  /// The [CellTable] or [CellGrid] of [doc].
  final Object run;

  CellTable? get table => run is CellTable ? run as CellTable : null;

  CellGrid? get grid => run is CellGrid ? run as CellGrid : null;

  /// The table or grid id.
  String get id => table?.id ?? grid!.id;

  /// Delta offset just after the run.
  int get end => start + doc.length;

  /// [change] (relative to [doc]) relative to the whole document.
  Delta shift(Delta change) {
    final out = Delta();
    if (start > 0) out.retain(start);
    for (final op in change.toList()) {
      out.push(op);
    }
    return out;
  }

  /// The (row, column) of the cell node [nodeIndex] (a mirror index).
  (int, int)? cellAt(DocumentMirror mirror, int nodeIndex) {
    final t = table;
    if (t == null || nodeIndex < first || nodeIndex > last) return null;
    return t.cellOf(mirror.startOfIndex(nodeIndex) - start);
  }

  /// The item index of the grid item node [nodeIndex] (a mirror index).
  int? itemOf(int nodeIndex) =>
      grid == null || nodeIndex < first || nodeIndex > last
      ? null
      : nodeIndex - first;

  /// The mirror index of the node of cell ([row], [column]), if it exists.
  int? nodeIndexOfCell(int row, int column) {
    final t = table;
    if (t == null || row < 0 || row >= t.rows.length) return null;
    final cells = t.rows[row].cells;
    if (column < 0 || column >= cells.length) return null;
    return first + cells[column].index;
  }

  /// The run around mirror node [index], or `null` when that node is not a
  /// table cell or grid item.
  static EditorCellRun? at(DocumentMirror mirror, int index) {
    if (index < 0 || index >= mirror.nodeCount) return null;
    final key = _groupOf(mirror.entryAt(index).node);
    if (key == null) return null;
    var first = index;
    while (first > 0 && _groupOf(mirror.entryAt(first - 1).node) == key) {
      first--;
    }
    var last = index;
    while (last + 1 < mirror.nodeCount &&
        _groupOf(mirror.entryAt(last + 1).node) == key) {
      last++;
    }
    final doc = WonkyDocument(mirror.entriesDelta(first, last + 1));
    final runs = CellRuns.of(doc);
    if (runs.length != 1) return null;
    return EditorCellRun._(
      first,
      last,
      mirror.startOfIndex(first),
      doc,
      runs.single,
    );
  }

  /// The run of node [nodeId], or of the table or grid with id [nodeId].
  static EditorCellRun? of(DocumentMirror mirror, String nodeId) {
    final index = mirror.indexOfNode(nodeId);
    if (index >= 0) return at(mirror, index);
    for (var i = 0; i < mirror.nodeCount; i++) {
      final node = mirror.entryAt(i).node;
      if (cellOf(node)?.table == nodeId || gridItemOf(node)?.id == nodeId) {
        return at(mirror, i);
      }
    }
    return null;
  }

  /// `t:<id>` for a cell node, `g:<id>` for a grid item node, else `null`.
  static String? _groupOf(DocumentNode node) {
    final cell = cellOf(node);
    if (cell != null) return 't:${cell.table}';
    final item = gridItemOf(node);
    return item == null ? null : 'g:${item.id}';
  }
}
