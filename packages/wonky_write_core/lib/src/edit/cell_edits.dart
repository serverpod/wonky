/// Structural edits of tables and grids made of cell and grid item lines
/// (specs/wonky_write/12-native-cells.md §3.5, §4).
library;

import 'package:wonky_rich_text/wonky_rich_text.dart';

import '../delta/cells.dart';
import '../delta/document.dart';
import '../delta/embeds.dart';

/// An invalid structural edit (an index out of range, an unknown table).
final class CellEditException implements Exception {
  /// Creates the exception.
  const CellEditException(this.message);

  /// What is wrong.
  final String message;

  @override
  String toString() => 'CellEditException: $message';
}

/// Builds the changes of the table and grid commands (Write 12 §3.5) and
/// the MCP tools (§4). Every method returns a change relative to the
/// document it was given (not normalized: callers normalize it), or `null`
/// when the document already has the requested value.
///
/// Edits keep the lines they do not touch: a cell that keeps its place
/// keeps its text, its comments and its row id, so concurrent typing in
/// other cells transforms cleanly. Ragged rows are completed with empty
/// cells as part of every table edit (§1.1); row and column indices count
/// the completed table.
abstract final class CellEdits {
  // -- Tables --------------------------------------------------------------

  /// The table with id [tableId] in [doc].
  static CellTable tableOf(WonkyDocument doc, String tableId) =>
      CellRuns.table(doc, tableId) ??
      (throw CellEditException('Table $tableId not found'));

  /// The grid with id [gridId] in [doc].
  static CellGrid gridOf(WonkyDocument doc, String gridId) =>
      CellRuns.grid(doc, gridId) ??
      (throw CellEditException('Grid $gridId not found'));

  /// Completes the ragged rows of the table (empty cells at their ends);
  /// `null` when no row is short.
  static Delta? completeRows(WonkyDocument doc, String tableId) {
    final t = tableOf(doc, tableId);
    if (!t.isRagged) return null;
    return _TableModel(doc, t).compile();
  }

  /// Inserts a row before row [at] (`rows.length` appends) with [cells]
  /// (inline Deltas; missing cells are empty).
  static Delta insertRow(
    WonkyDocument doc,
    String tableId,
    int at, {
    List<Delta>? cells,
    String Function()? rowId,
  }) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(at >= 0 && at <= m.rows.length, 'Row index $at out of range');
    m.rows.insert(
      at,
      _RowSlot.fresh((rowId ?? CellIds.row)(), [
        for (var c = 0; c < m.columns; c++)
          _CellSlot.fresh(
            cells != null && c < cells.length ? cells[c] : Delta(),
            m.align[c],
          ),
      ]),
    );
    return m.compile();
  }

  /// Deletes row [row]; deleting the only row deletes the table.
  static Delta deleteRow(WonkyDocument doc, String tableId, int row) {
    final t = tableOf(doc, tableId);
    final m = _TableModel(doc, t);
    _check(row >= 0 && row < m.rows.length, 'Row $row out of range');
    if (m.rows.length == 1) return deleteTable(doc, tableId);
    m.rows.removeAt(row);
    return m.compile();
  }

  /// Moves row [from] to index [to] (indices before the move).
  static Delta? moveRow(WonkyDocument doc, String tableId, int from, int to) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(from >= 0 && from < m.rows.length, 'Row $from out of range');
    _check(to >= 0 && to < m.rows.length, 'Row $to out of range');
    if (from == to) return m.compileOrNull();
    final row = m.rows.removeAt(from).moved();
    m.rows.insert(to, row);
    return m.compile();
  }

  /// Inserts a column before column [at] (`columnCount` appends): [header]
  /// in row 0 and [cells] in the body rows (inline Deltas; missing cells are
  /// empty).
  static Delta insertColumn(
    WonkyDocument doc,
    String tableId,
    int at, {
    Delta? header,
    List<Delta>? cells,
  }) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(at >= 0 && at <= m.columns, 'Column index $at out of range');
    for (var r = 0; r < m.rows.length; r++) {
      final content = r == 0
          ? header
          : (cells != null && r - 1 < cells.length ? cells[r - 1] : null);
      m.rows[r].cells.insert(at, _CellSlot.fresh(content ?? Delta(), null));
    }
    m.align.insert(at, null);
    return m.compile();
  }

  /// Deletes column [col]; deleting the only column deletes the table.
  static Delta deleteColumn(WonkyDocument doc, String tableId, int col) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(col >= 0 && col < m.columns, 'Column $col out of range');
    if (m.columns == 1) return deleteTable(doc, tableId);
    for (final r in m.rows) {
      r.cells.removeAt(col);
    }
    m.align.removeAt(col);
    return m.compile();
  }

  /// Moves column [from] to index [to] (indices before the move).
  static Delta? moveColumn(
    WonkyDocument doc,
    String tableId,
    int from,
    int to,
  ) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(from >= 0 && from < m.columns, 'Column $from out of range');
    _check(to >= 0 && to < m.columns, 'Column $to out of range');
    if (from == to) return m.compileOrNull();
    for (final r in m.rows) {
      r.cells.insert(to, r.cells.removeAt(from).moved());
    }
    m.align.insert(to, m.align.removeAt(from));
    return m.compile();
  }

  /// Sets the alignment of column [col] (on every cell of the column).
  static Delta? setColumnAlignment(
    WonkyDocument doc,
    String tableId,
    int col,
    CellAlign? align,
  ) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(col >= 0 && col < m.columns, 'Column $col out of range');
    m.align[col] = align;
    return m.compileOrNull();
  }

  /// Replaces the content of cell ([row], [col]) with [content] (an inline
  /// Delta); `null` when the cell already holds it.
  static Delta? setCell(
    WonkyDocument doc,
    String tableId,
    int row,
    int col,
    Delta content,
  ) {
    final m = _TableModel(doc, tableOf(doc, tableId));
    _check(
      row >= 0 && row < m.rows.length && col >= 0 && col < m.columns,
      'Cell ($row, $col) out of range',
    );
    m.rows[row].cells[col].setContent(content);
    return m.compileOrNull();
  }

  /// Replaces the table's content with [rows] (inline Deltas, row 0 the
  /// header; padded to the longest row) and [align] (kept when `null`).
  /// Cells that keep their position and content keep their lines (Write
  /// 12 §3.6); `null` when nothing changes.
  static Delta? replaceTable(
    WonkyDocument doc,
    String tableId,
    List<List<Delta>> rows, {
    List<CellAlign?>? align,
    String Function()? rowId,
  }) {
    _check(rows.isNotEmpty, 'A table needs at least one row');
    final m = _TableModel(doc, tableOf(doc, tableId));
    final columns = rows.fold(
      align?.length ?? 1,
      (n, r) => r.length > n ? r.length : n,
    );
    final newAlign = [
      for (var c = 0; c < columns; c++)
        align != null
            ? (c < align.length ? align[c] : null)
            : (c < m.align.length ? m.align[c] : null),
    ];
    final out = <_RowSlot>[];
    for (var r = 0; r < rows.length; r++) {
      final old = r < m.rows.length ? m.rows[r] : null;
      final cells = <_CellSlot>[
        for (var c = 0; c < columns; c++)
          if (old != null && c < old.cells.length)
            old.cells[c]..setContent(c < rows[r].length ? rows[r][c] : Delta())
          else
            _CellSlot.fresh(
              c < rows[r].length ? rows[r][c] : Delta(),
              newAlign[c],
            ),
      ];
      out.add(
        old == null
            ? _RowSlot.fresh((rowId ?? CellIds.row)(), cells)
            : _RowSlot.existing(old.id, cells),
      );
    }
    m.rows
      ..clear()
      ..addAll(out);
    m.align
      ..clear()
      ..addAll(newAlign);
    return m.compileOrNull();
  }

  /// Deletes the table.
  static Delta deleteTable(WonkyDocument doc, String tableId) {
    final t = tableOf(doc, tableId);
    return Delta()
      ..retain(t.start)
      ..delete(t.end - t.start);
  }

  // -- Grids ---------------------------------------------------------------

  /// Sets the grid's column count (canonical 1–4) on every item.
  static Delta? setGridColumns(WonkyDocument doc, String gridId, int columns) {
    final g = gridOf(doc, gridId);
    return _patchGrid(g, g.attr.copyWith(columns: columns));
  }

  /// Sets the grid's bullets on every item.
  static Delta? setGridBullets(
    WonkyDocument doc,
    String gridId,
    GridBullets bullets,
  ) {
    final g = gridOf(doc, gridId);
    return _patchGrid(g, g.attr.copyWith(bullets: bullets));
  }

  /// Inserts an item with [content] before item [at] (`items.length`
  /// appends).
  static Delta addGridItem(
    WonkyDocument doc,
    String gridId,
    int at, {
    Delta? content,
  }) {
    final g = gridOf(doc, gridId);
    _check(at >= 0 && at <= g.items.length, 'Item index $at out of range');
    _check(
      g.items.length < GridEmbed.maxItems,
      'A grid has at most ${GridEmbed.maxItems} items',
    );
    final offset = at == g.items.length ? g.end : g.items[at].start;
    return _append(
      Delta()..retain(offset),
      CellLines.grid(
        id: g.id,
        items: [content ?? Delta()],
        columns: g.columns,
        bullets: g.bullets,
        box: g.box,
      ),
    );
  }

  /// Removes item [index]; removing the only item deletes the grid.
  static Delta removeGridItem(WonkyDocument doc, String gridId, int index) {
    final g = gridOf(doc, gridId);
    _check(index >= 0 && index < g.items.length, 'Item $index out of range');
    final item = g.items[index];
    return Delta()
      ..retain(item.start)
      ..delete(item.length);
  }

  /// Replaces the content of item [index] with [content] (an inline Delta);
  /// `null` when the item already holds it.
  static Delta? setGridItem(
    WonkyDocument doc,
    String gridId,
    int index,
    Delta content,
  ) {
    final g = gridOf(doc, gridId);
    _check(index >= 0 && index < g.items.length, 'Item $index out of range');
    final item = g.items[index];
    final clean = _singleLine(content);
    if (_content(item) == clean) return null;
    return _append(
      Delta()
        ..retain(item.start)
        ..delete(item.contentLength),
      clean,
    );
  }

  /// Deletes the grid.
  static Delta deleteGrid(WonkyDocument doc, String gridId) {
    final g = gridOf(doc, gridId);
    return Delta()
      ..retain(g.start)
      ..delete(g.end - g.start);
  }

  static Delta? _patchGrid(CellGrid g, GridItemAttr attr) {
    final json = attr.toJson();
    final d = Delta();
    var cursor = 0;
    var changed = false;
    for (final item in g.items) {
      if (GridItemAttr.of(item.attributes) == attr) continue;
      d
        ..retain(item.newlineOffset - cursor)
        ..retain(1, {WonkyAttr.grid: json});
      cursor = item.end;
      changed = true;
    }
    return changed ? d : null;
  }

  // -- Helpers -------------------------------------------------------------

  /// [d] with the ops of [other] pushed onto it.
  static Delta _append(Delta d, Delta other) {
    for (final op in other.toList()) {
      d.push(op);
    }
    return d;
  }

  static void _check(bool ok, String message) {
    if (!ok) throw CellEditException(message);
  }

  /// The inline content of [line] (without its newline).
  static Delta _content(DocumentLine line) {
    final d = Delta();
    for (final s in line.segments) {
      d.insert(s.data, s.attributes);
    }
    return d;
  }

  /// [content] as one line: newlines, soft breaks and tabs become spaces,
  /// embeds are dropped (cells hold text only, §1.1).
  static Delta _singleLine(Delta content) {
    final d = Delta();
    for (final op in content.toList()) {
      final data = op.data;
      if (op.isInsert && data is String) {
        final text = data.replaceAll(RegExp('[\n\r\t  ]'), ' ');
        if (text.isNotEmpty) d.insert(text, op.attributes);
      }
    }
    return d;
  }
}

/// A cell of a [_TableModel]: an existing line (kept in place, possibly with
/// new content) or a new cell.
final class _CellSlot {
  _CellSlot.existing(DocumentLine this.line)
    : align = CellAttr.of(line.attributes)?.align;

  _CellSlot.fresh(Delta content, this.align)
    : line = null,
      content = CellEdits._singleLine(content);

  /// The kept line, `null` for a new cell.
  final DocumentLine? line;

  /// The new content: of a new cell, or replacing the kept line's text.
  Delta? content;

  /// The cell's alignment before the table's alignment is applied.
  CellAlign? align;

  /// Replaces the content (no change when equal to the current one).
  void setContent(Delta value) {
    final clean = CellEdits._singleLine(value);
    final current =
        content ?? (line == null ? Delta() : CellEdits._content(line!));
    if (current == clean) return;
    content = clean;
  }

  /// A new cell with this cell's content (moving deletes and re-inserts).
  _CellSlot moved() => line == null
      ? this
      : (_CellSlot.fresh(Delta(), align)
          ..content = content ?? CellEdits._content(line!));
}

/// A row of a [_TableModel].
final class _RowSlot {
  _RowSlot.existing(this.id, this.cells) : isNew = false;

  _RowSlot.fresh(this.id, this.cells) : isNew = true;

  final String id;
  final bool isNew;
  final List<_CellSlot> cells;

  /// This row as new lines (moving deletes and re-inserts), same row id.
  _RowSlot moved() => _RowSlot.fresh(id, [for (final c in cells) c.moved()]);
}

/// A completed (non-ragged) table being edited; [compile] turns it into the
/// change from the document's table.
final class _TableModel {
  _TableModel(this.doc, this.table)
    : align = [...table.align],
      rows = [
        for (final r in table.rows)
          _RowSlot.existing(r.id, [
            for (final line in r.cells) _CellSlot.existing(line),
            // Completes a ragged row (§1.1).
            for (var c = r.cells.length; c < table.columnCount; c++)
              _CellSlot.fresh(Delta(), table.align[c]),
          ]),
      ];

  final WonkyDocument doc;
  final CellTable table;

  /// The column alignments (applied to every cell on [compile]).
  final List<CellAlign?> align;

  final List<_RowSlot> rows;

  int get columns => rows.isEmpty ? align.length : rows.first.cells.length;

  /// [compile], or `null` when it changes nothing.
  Delta? compileOrNull() {
    final d = compile();
    return d.isEmpty ? null : d;
  }

  /// The change from the document's table to this model. Kept lines must
  /// be in their original order (moves re-insert).
  Delta compile() {
    final box = table.box;
    final old = table.lines.toList();
    final kept = <DocumentLine>{
      for (final r in rows)
        for (final c in r.cells)
          if (c.line != null) c.line!,
    };
    final d = Delta()..retain(table.start);
    var next = 0; // Index of the next old line not yet passed.
    void deleteUpTo(int index) {
      while (next < index) {
        final line = old[next];
        if (!kept.contains(line)) d.delete(line.length);
        next++;
      }
    }

    for (final r in rows) {
      for (var c = 0; c < r.cells.length; c++) {
        final slot = r.cells[c];
        final attr = CellAttr(
          table: table.id,
          row: r.id,
          align: c < align.length ? align[c] : null,
        );
        final line = slot.line;
        if (line == null) {
          CellEdits._append(
            d,
            slot.content ?? Delta(),
          ).insert('\n', {WonkyAttr.cell: attr.toJson(), WonkyAttr.box: ?box});
          continue;
        }
        deleteUpTo(old.indexOf(line));
        if (slot.content != null) {
          CellEdits._append(d..delete(line.contentLength), slot.content!);
        } else if (line.contentLength > 0) {
          d.retain(line.contentLength);
        }
        d.retain(
          1,
          CellAttr.of(line.attributes) == attr
              ? null
              : {WonkyAttr.cell: attr.toJson()},
        );
        next++;
      }
    }
    deleteUpTo(old.length);
    return d..trim();
  }
}
