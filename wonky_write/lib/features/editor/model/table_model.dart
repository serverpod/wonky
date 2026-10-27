import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellTable, InlineContext, InlineMarkdownWriter, InlineRun;

/// Column alignment of a GFM table.
enum TableAlign {
  none,
  left,
  center,
  right;

  String? get value => this == none ? null : name;

  static TableAlign parse(Object? value) =>
      TableAlign.values.firstWhereOrNull((a) => a.name == value && a != none) ??
      TableAlign.none;
}

/// Immutable model of a `table` embed (`{id, align, rows}`, Write 02 §1.3):
/// row 0 is the header row; cells are inline Markdown.
@immutable
class TableModel {
  TableModel({
    required this.id,
    required List<TableAlign> align,
    required List<List<String>> rows,
  }) : align = List.unmodifiable(align),
       rows = List.unmodifiable([
         for (final row in rows) List<String>.unmodifiable(row),
       ]);

  /// An empty table of [rowCount] rows (header included) × [columnCount].
  factory TableModel.empty(
    String id, {
    int rowCount = 3,
    int columnCount = 3,
  }) => TableModel(
    id: id,
    align: List.filled(columnCount, TableAlign.none),
    rows: List.generate(rowCount, (_) => List.filled(columnCount, '')),
  );

  /// A table of cell lines (Write 12 §1.1) with its cells as inline Markdown;
  /// pads ragged rows.
  factory TableModel.fromCells(CellTable table) {
    final columns = table.columnCount;
    return TableModel(
      id: table.id,
      align: [for (final a in table.align) TableAlign.parse(a?.value)],
      rows: [
        for (final row in table.rows)
          [
            for (var c = 0; c < columns; c++)
              c < row.cells.length
                  ? InlineMarkdownWriter.write([
                      for (final s in row.cells[c].segments)
                        if (!s.isEmbed)
                          InlineRun.fromAttributes(s.text, s.attributes),
                    ], context: InlineContext.tableCell)
                  : '',
          ],
      ],
    );
  }

  /// Reads the inner embed value; pads ragged rows.
  factory TableModel.fromEmbed(Map<String, dynamic> value) {
    final rawRows = value['rows'] is List
        ? value['rows'] as List
        : const <Object?>[];
    var columns = 0;
    for (final row in rawRows) {
      if (row is List && row.length > columns) columns = row.length;
    }
    if (columns == 0) columns = 1;
    final rawAlign = value['align'] is List
        ? value['align'] as List
        : const <Object?>[];
    return TableModel(
      id: '${value['id'] ?? ''}',
      align: [
        for (var c = 0; c < columns; c += 1)
          TableAlign.parse(c < rawAlign.length ? rawAlign[c] : null),
      ],
      rows: [
        for (final row in rawRows.isEmpty ? [<Object?>[]] : rawRows)
          [
            for (var c = 0; c < columns; c += 1)
              row is List && c < row.length ? '${row[c] ?? ''}' : '',
          ],
      ],
    );
  }

  final String id;
  final List<TableAlign> align;
  final List<List<String>> rows;

  int get rowCount => rows.length;
  int get columnCount => align.length;

  /// The inner embed value (`{"id", "align", "rows"}`).
  Map<String, dynamic> toEmbed() => {
    'id': id,
    'align': [for (final a in align) a.value],
    'rows': [
      for (final row in rows) [...row],
    ],
  };

  /// The embed insert value (`{"table": {...}}`).
  Map<String, dynamic> toInsert() => {'table': toEmbed()};

  TableModel _with({List<TableAlign>? align, List<List<String>>? rows}) =>
      TableModel(id: id, align: align ?? this.align, rows: rows ?? this.rows);

  TableModel insertRow(int index) {
    final at = index.clamp(1, rowCount);
    return _with(
      rows: [
        ...rows.sublist(0, at),
        List.filled(columnCount, ''),
        ...rows.sublist(at),
      ],
    );
  }

  TableModel deleteRow(int index) {
    if (index <= 0 || index >= rowCount) {
      // The header row can't be deleted.
      return this;
    }
    return _with(rows: [...rows.sublist(0, index), ...rows.sublist(index + 1)]);
  }

  TableModel moveRow(int from, int to) {
    if (from <= 0 ||
        to <= 0 ||
        from >= rowCount ||
        to >= rowCount ||
        from == to) {
      return this;
    }
    final list = [...rows];
    final row = list.removeAt(from);
    list.insert(to, row);
    return _with(rows: list);
  }

  TableModel insertColumn(int index) {
    final at = index.clamp(0, columnCount);
    return _with(
      align: [...align.sublist(0, at), TableAlign.none, ...align.sublist(at)],
      rows: [
        for (final row in rows) [...row.sublist(0, at), '', ...row.sublist(at)],
      ],
    );
  }

  TableModel deleteColumn(int index) {
    if (columnCount <= 1 || index < 0 || index >= columnCount) return this;
    return _with(
      align: [...align.sublist(0, index), ...align.sublist(index + 1)],
      rows: [
        for (final row in rows)
          [...row.sublist(0, index), ...row.sublist(index + 1)],
      ],
    );
  }

  TableModel moveColumn(int from, int to) {
    if (from < 0 ||
        to < 0 ||
        from >= columnCount ||
        to >= columnCount ||
        from == to) {
      return this;
    }
    List<T> move<T>(List<T> list) {
      final copy = [...list];
      final item = copy.removeAt(from);
      copy.insert(to, item);
      return copy;
    }

    return _with(align: move(align), rows: [for (final row in rows) move(row)]);
  }

  TableModel setColumnAlignment(int index, TableAlign value) {
    if (index < 0 || index >= columnCount) return this;
    return _with(
      align: [...align.sublist(0, index), value, ...align.sublist(index + 1)],
    );
  }

  TableModel setCell(int row, int column, String markdown) {
    if (row < 0 || row >= rowCount || column < 0 || column >= columnCount) {
      return this;
    }
    final cell = markdown.replaceAll(RegExp(r'[\r\n]+'), ' ');
    return _with(
      rows: [
        for (var r = 0; r < rowCount; r += 1)
          r == row
              ? [
                  ...rows[r].sublist(0, column),
                  cell,
                  ...rows[r].sublist(column + 1),
                ]
              : rows[r],
      ],
    );
  }

  /// Tab-separated values (for pasting into spreadsheets).
  String toTsv() => rows
      .map((row) => row.map((c) => c.replaceAll('\t', ' ')).join('\t'))
      .join('\n');

  @override
  bool operator ==(Object other) =>
      other is TableModel &&
      other.id == id &&
      const ListEquality<TableAlign>().equals(other.align, align) &&
      const DeepCollectionEquality().equals(other.rows, rows);

  @override
  int get hashCode => Object.hash(id, Object.hashAll(align), rows.length);
}
