/// Table cell and grid item lines (specs/wonky_write/12-native-cells.md §1).
library;

import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:wonky_rich_text/wonky_rich_text.dart';

import 'document.dart';
import 'embeds.dart';

/// The `cell` line attribute: the line is a cell of table [table], in row
/// [row] (Write 12 §1.1).
final class CellAttr {
  /// Creates a cell attribute.
  const CellAttr({required this.table, required this.row, this.align});

  /// The table's id.
  final String table;

  /// The row's id (unique within the table).
  final String row;

  /// The cell's alignment (`null` = default).
  final CellAlign? align;

  /// Parses a `cell` value; `null` when it is not a map with non-empty
  /// `table` and `row` strings. Unknown keys and invalid `align` values are
  /// ignored (the normalizer removes them).
  static CellAttr? tryParse(Object? value) {
    if (value is! Map) return null;
    final table = value['table'];
    final row = value['row'];
    if (table is! String || table.isEmpty || row is! String || row.isEmpty) {
      return null;
    }
    return CellAttr(
      table: table,
      row: row,
      align: CellAlign.tryParse(value['align']),
    );
  }

  /// The cell attribute of a line's [attributes], if any.
  static CellAttr? of(Map<String, dynamic>? attributes) =>
      tryParse(attributes?[WonkyAttr.cell]);

  /// Whether [value] is a `cell` value in canonical form (validator).
  static bool isCanonical(Object? value) {
    final cell = tryParse(value);
    return cell != null && _sameJson(cell.toJson(), value as Map);
  }

  /// The JSON value.
  Map<String, dynamic> toJson() => {
    'table': table,
    'row': row,
    if (align != null) 'align': align!.value,
  };

  /// Copy with changed fields.
  CellAttr copyWith({
    String? table,
    String? row,
    CellAlign? align,
    bool clearAlign = false,
  }) => CellAttr(
    table: table ?? this.table,
    row: row ?? this.row,
    align: clearAlign ? null : (align ?? this.align),
  );

  @override
  bool operator ==(Object other) =>
      other is CellAttr &&
      other.table == table &&
      other.row == row &&
      other.align == align;

  @override
  int get hashCode => Object.hash(table, row, align);

  @override
  String toString() => 'CellAttr(${toJson()})';
}

/// The `grid` line attribute: the line is an item of grid [id] (Write 12
/// §1.2).
final class GridItemAttr {
  /// Creates a grid item attribute.
  const GridItemAttr({
    required this.id,
    this.columns = GridEmbed.defaultColumns,
    this.bullets = GridBullets.check,
  });

  /// The grid's id.
  final String id;

  /// The grid's column count, 1–4 (canonical, 11 §2.2).
  final int columns;

  /// The grid's bullets.
  final GridBullets bullets;

  /// Parses a `grid` value; `null` when it is not a map with a non-empty
  /// `id`. Other values are canonicalized.
  static GridItemAttr? tryParse(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    if (id is! String || id.isEmpty) return null;
    return GridItemAttr(
      id: id,
      columns: GridEmbed.canonicalColumns(value['columns']),
      bullets: GridBullets.parse(value['bullets']),
    );
  }

  /// The grid item attribute of a line's [attributes], if any.
  static GridItemAttr? of(Map<String, dynamic>? attributes) =>
      tryParse(attributes?[WonkyAttr.grid]);

  /// Whether [value] is a `grid` value in canonical form (validator).
  static bool isCanonical(Object? value) {
    final item = tryParse(value);
    return item != null && _sameJson(item.toJson(), value as Map);
  }

  /// The JSON value.
  Map<String, dynamic> toJson() => {
    'id': id,
    'columns': columns,
    'bullets': bullets.value,
  };

  /// Copy with changed fields.
  GridItemAttr copyWith({String? id, int? columns, GridBullets? bullets}) =>
      GridItemAttr(
        id: id ?? this.id,
        columns: columns == null
            ? this.columns
            : GridEmbed.canonicalColumns(columns),
        bullets: bullets ?? this.bullets,
      );

  @override
  bool operator ==(Object other) =>
      other is GridItemAttr &&
      other.id == id &&
      other.columns == columns &&
      other.bullets == bullets;

  @override
  int get hashCode => Object.hash(id, columns, bullets);

  @override
  String toString() => 'GridItemAttr(${toJson()})';
}

bool _sameJson(Map<String, dynamic> canonical, Map<dynamic, dynamic> value) {
  if (canonical.length != value.length) return false;
  for (final e in canonical.entries) {
    if (value[e.key] != e.value) return false;
  }
  return true;
}

/// New table, grid and row ids (Write 12 §1.3).
abstract final class CellIds {
  static final _random = Random.secure();
  static const _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  /// A new table or grid id (UUIDv7).
  static String group() => const Uuid().v7();

  /// A new row id: 8 random base-36 characters.
  static String row([Random? random]) {
    final r = random ?? _random;
    return String.fromCharCodes([
      for (var i = 0; i < 8; i++) _alphabet.codeUnitAt(r.nextInt(36)),
    ]);
  }
}

/// A table read from its lines (Write 12 §1.1).
final class CellTable {
  /// Creates a table view.
  CellTable({required this.id, required this.rows});

  /// The table's id.
  final String id;

  /// The rows, in document order; row 0 is the header row.
  final List<CellRow> rows;

  /// The first line of the table.
  DocumentLine get firstLine => rows.first.cells.first;

  /// The last line of the table.
  DocumentLine get lastLine => rows.last.cells.last;

  /// Document offset of the table's first character.
  int get start => firstLine.start;

  /// Document offset just after the table's last line.
  int get end => lastLine.end;

  /// The column count: the length of the longest row.
  int get columnCount =>
      rows.fold(0, (n, r) => r.cells.length > n ? r.cells.length : n);

  /// Whether a row is shorter than [columnCount].
  bool get isRagged => rows.any((r) => r.cells.length != columnCount);

  /// The column alignments (the header cells', padded to [columnCount]).
  List<CellAlign?> get align => [
    for (var c = 0; c < columnCount; c++)
      c < rows.first.cells.length
          ? CellAttr.of(rows.first.cells[c].attributes)?.align
          : null,
  ];

  /// The `box` value of the table's first cell (containers it is in).
  Object? get box => firstLine.attributes[WonkyAttr.box];

  /// Every line of the table, in order.
  Iterable<DocumentLine> get lines => rows.expand((r) => r.cells);

  /// The (row, column) of the line starting at [lineStart], if it is a cell
  /// of this table.
  (int, int)? cellOf(int lineStart) {
    for (var r = 0; r < rows.length; r++) {
      final cells = rows[r].cells;
      for (var c = 0; c < cells.length; c++) {
        if (cells[c].start == lineStart) return (r, c);
      }
    }
    return null;
  }
}

/// A row of a [CellTable].
final class CellRow {
  /// Creates a row view.
  CellRow({required this.id, required this.cells});

  /// The row's id.
  final String id;

  /// The row's cell lines, column by column.
  final List<DocumentLine> cells;
}

/// A grid read from its lines (Write 12 §1.2).
final class CellGrid {
  /// Creates a grid view.
  CellGrid({required this.id, required this.items});

  /// The grid's id.
  final String id;

  /// The item lines, in order.
  final List<DocumentLine> items;

  /// The first item's attribute (the grid's columns and bullets).
  GridItemAttr get attr => GridItemAttr.of(items.first.attributes)!;

  /// The grid's column count.
  int get columns => attr.columns;

  /// The grid's bullets.
  GridBullets get bullets => attr.bullets;

  /// Document offset of the grid's first character.
  int get start => items.first.start;

  /// Document offset just after the grid's last line.
  int get end => items.last.end;

  /// The `box` value of the first item.
  Object? get box => items.first.attributes[WonkyAttr.box];
}

/// Finds the tables and grids of a document (Write 12 §1.1–1.2).
abstract final class CellRuns {
  /// Every table and grid of [doc], in document order ([CellTable] or
  /// [CellGrid]).
  static List<Object> of(WonkyDocument doc) {
    final out = <Object>[];
    final lines = doc.lines;
    var i = 0;
    while (i < lines.length) {
      final run = _runAt(lines, i);
      if (run == null) {
        i++;
        continue;
      }
      out.add(run.$1);
      i = run.$2;
    }
    return out;
  }

  /// The table or grid that contains line [lineIndex] of [doc], if any.
  static Object? at(WonkyDocument doc, int lineIndex) {
    final lines = doc.lines;
    if (lineIndex < 0 || lineIndex >= lines.length) return null;
    final line = lines[lineIndex];
    final cell = CellAttr.of(line.attributes);
    final item = cell == null ? GridItemAttr.of(line.attributes) : null;
    if (cell == null && item == null) return null;
    // Back to the run's first line.
    var first = lineIndex;
    while (first > 0 && _sameGroup(lines[first - 1], cell, item)) {
      first--;
    }
    return _runAt(lines, first)?.$1;
  }

  /// The table with id [id] in [doc], if any (the first run with that id).
  static CellTable? table(WonkyDocument doc, String id) {
    for (final run in of(doc)) {
      if (run is CellTable && run.id == id) return run;
    }
    return null;
  }

  /// The grid with id [id] in [doc], if any (the first run with that id).
  static CellGrid? grid(WonkyDocument doc, String id) {
    for (final run in of(doc)) {
      if (run is CellGrid && run.id == id) return run;
    }
    return null;
  }

  static bool _sameGroup(
    DocumentLine line,
    CellAttr? cell,
    GridItemAttr? item,
  ) {
    if (cell != null) return CellAttr.of(line.attributes)?.table == cell.table;
    return GridItemAttr.of(line.attributes)?.id == item!.id;
  }

  /// The run starting at line [i] and the index after it.
  static (Object, int)? _runAt(List<DocumentLine> lines, int i) {
    final cell = CellAttr.of(lines[i].attributes);
    if (cell != null) {
      final rows = <CellRow>[];
      var j = i;
      while (j < lines.length) {
        final c = CellAttr.of(lines[j].attributes);
        if (c == null || c.table != cell.table) break;
        if (rows.isEmpty || rows.last.id != c.row) {
          rows.add(CellRow(id: c.row, cells: [lines[j]]));
        } else {
          rows.last.cells.add(lines[j]);
        }
        j++;
      }
      return (CellTable(id: cell.table, rows: rows), j);
    }
    final item = GridItemAttr.of(lines[i].attributes);
    if (item != null) {
      final items = <DocumentLine>[];
      var j = i;
      while (j < lines.length &&
          GridItemAttr.of(lines[j].attributes)?.id == item.id) {
        items.add(lines[j]);
        j++;
      }
      return (CellGrid(id: item.id, items: items), j);
    }
    return null;
  }
}

/// Builds the Delta of new tables and grids (Write 12 §1).
abstract final class CellLines {
  /// The inline Delta of [runs] (no newline).
  static Delta inline(Iterable<InlineRun> runs) {
    final d = Delta();
    for (final r in runs) {
      if (r.text.isEmpty) continue;
      d.insert(r.text, r.toAttributes());
    }
    return d;
  }

  /// The inline Delta of an inline-Markdown cell (Wonky flavor).
  static Delta markdown(String cell) => inline(InlineMarkdown.parseCell(cell));

  /// The lines of a new table: [rows] of inline Deltas (row 0 the header),
  /// padded to the longest row; [align] per column; [box] on every line.
  static Delta table({
    required String id,
    required List<List<Delta>> rows,
    List<CellAlign?> align = const [],
    Object? box,
    String Function()? rowId,
  }) {
    final columns = rows.fold(
      align.length,
      (n, r) => r.length > n ? r.length : n,
    );
    final d = Delta();
    for (final row in rows) {
      final rid = (rowId ?? CellIds.row)();
      for (var c = 0; c < (columns == 0 ? 1 : columns); c++) {
        if (c < row.length) _appendInline(d, row[c]);
        d.insert('\n', {
          WonkyAttr.cell: CellAttr(
            table: id,
            row: rid,
            align: c < align.length ? align[c] : null,
          ).toJson(),
          WonkyAttr.box: ?box,
        });
      }
    }
    return d;
  }

  /// The lines of a new grid: one per item of [items] (at least one).
  static Delta grid({
    required String id,
    required List<Delta> items,
    int columns = GridEmbed.defaultColumns,
    GridBullets bullets = GridBullets.check,
    Object? box,
  }) {
    final attr = GridItemAttr(
      id: id,
      columns: GridEmbed.canonicalColumns(columns),
      bullets: bullets,
    ).toJson();
    final d = Delta();
    for (final item in items.isEmpty ? [Delta()] : items) {
      _appendInline(d, item);
      d.insert('\n', {WonkyAttr.grid: attr, WonkyAttr.box: ?box});
    }
    return d;
  }

  /// [fragment] with new table, row and grid ids (paste and import, Write
  /// 12 §1.3): each table and grid gets a new id, each row a new row id, so
  /// a pasted copy never joins the original.
  static Delta regenerateIds(Delta fragment) {
    final groups = <String, String>{};
    final rows = <String, String>{};
    final out = Delta();
    for (final op in fragment.toList()) {
      final attrs = op.attributes;
      final cell = CellAttr.of(attrs);
      final item = cell == null ? GridItemAttr.of(attrs) : null;
      if (cell == null && item == null) {
        out.push(op);
        continue;
      }
      final next = {...attrs!};
      if (cell != null) {
        final table = groups.putIfAbsent('t:${cell.table}', CellIds.group);
        final row = rows.putIfAbsent(
          '${cell.table}/${cell.row}',
          () => CellIds.row(),
        );
        next[WonkyAttr.cell] = cell.copyWith(table: table, row: row).toJson();
      } else {
        next[WonkyAttr.grid] = item!
            .copyWith(id: groups.putIfAbsent('g:${item.id}', CellIds.group))
            .toJson();
      }
      out.insert(op.data, next);
    }
    return out;
  }

  static void _appendInline(Delta out, Delta inline) {
    for (final op in inline.toList()) {
      final data = op.data;
      if (data is String) {
        final text = data
            .replaceAll('\n', ' ')
            .replaceAll(' ', ' ')
            .replaceAll(' ', ' ');
        if (text.isNotEmpty) out.insert(text, op.attributes);
      }
    }
  }
}
