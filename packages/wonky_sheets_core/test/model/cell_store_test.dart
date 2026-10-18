import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sync_models/ids.dart';

/// The used extent as it was computed before it was maintained incrementally:
/// the last row and the last column holding a content cell.
(int, int)? _scannedExtent(CellStore cells, AxisIndex rows, AxisIndex cols) {
  var lastRow = -1, lastCol = -1;
  for (final c in cells.all) {
    if (c.content == null) continue;
    final r = rows.indexOf(c.rowId), k = cols.indexOf(c.columnId);
    if (r > lastRow) lastRow = r;
    if (k > lastCol) lastCol = k;
  }
  return lastRow < 0 || lastCol < 0 ? null : (lastRow, lastCol);
}

CellRecord _cell(String rowId, String colId, {String? content, String? note}) =>
    CellRecord(
      id: 'c:$rowId:$colId',
      sheetId: 's',
      rowId: rowId,
      columnId: colId,
      content: content,
      note: note,
    );

void main() {
  group('Given a cell store with axes', () {
    late CellStore cells;
    late AxisIndex rows;
    late AxisIndex cols;
    late Random random;
    late List<String> rowIds;
    late List<String> colIds;
    var next = 0;

    void addRow() {
      final key = FractionalIndex.between(
        rows.length == 0 ? null : rows.sortKeyAt(rows.length - 1),
        null,
      );
      final id = 'r${next++}';
      rows.upsert(id, key);
      rowIds.add(id);
    }

    setUp(() {
      cells = CellStore();
      rows = AxisIndex();
      cols = AxisIndex();
      random = Random(42);
      rowIds = [];
      colIds = [];
      for (var i = 0; i < 30; i++) {
        addRow();
      }
      final ck = FractionalIndex.nBetween(null, null, 12);
      for (var i = 0; i < 12; i++) {
        cols.upsert('k$i', ck[i]);
        colIds.add('k$i');
      }
    });

    test(
      'when cells and rows change at random then the used extent always matches a full scan',
      () {
        for (var step = 0; step < 3000; step++) {
          final r = rowIds[random.nextInt(rowIds.length)];
          final c = colIds[random.nextInt(colIds.length)];
          switch (random.nextInt(9)) {
            case 0 || 1 || 2:
              cells.put(_cell(r, c, content: 'n:$step'));
            case 3:
              cells.put(_cell(r, c, note: 'only a note'));
            case 4 || 5:
              cells.remove('c:$r:$c');
            case 6:
              // Insert a row anywhere.
              final i = random.nextInt(rows.length);
              final id = 'r${next++}';
              rows.upsert(
                id,
                FractionalIndex.between(
                  i == 0 ? null : rows.sortKeyAt(i - 1),
                  rows.sortKeyAt(i),
                ),
              );
              rowIds.add(id);
            case 7:
              rows.remove(rowIds[random.nextInt(rowIds.length)]);
            default:
              cells.removeRow(r);
          }

          expect(
            cells.usedExtent(rows, cols),
            _scannedExtent(cells, rows, cols),
            reason: 'step $step',
          );
        }
      },
    );

    test(
      'when the content of the last row is replaced then the extent stays',
      () {
        cells.put(_cell(rowIds[3], colIds[2], content: 'n:1'));
        cells.put(_cell(rowIds[20], colIds[5], content: 'n:2'));
        expect(cells.usedExtent(rows, cols), (20, 5));

        cells.put(_cell(rowIds[20], colIds[5], content: 'n:3'));

        expect(cells.usedExtent(rows, cols), (20, 5));
      },
    );

    test(
      'when the last content cell becomes a note then the extent shrinks',
      () {
        cells.put(_cell(rowIds[3], colIds[2], content: 'n:1'));
        cells.put(_cell(rowIds[20], colIds[5], content: 'n:2'));
        expect(cells.usedExtent(rows, cols), (20, 5));

        cells.put(_cell(rowIds[20], colIds[5], note: 'x'));

        expect(cells.usedExtent(rows, cols), (3, 2));
        expect(cells.usedExtent(rows, cols, includeFormatOnly: true), (20, 5));
      },
    );

    test(
      'when iterating a range with a callback then cells and order match cellsIn',
      () {
        for (var i = 0; i < 200; i++) {
          final r = rowIds[random.nextInt(rowIds.length)];
          final c = colIds[random.nextInt(colIds.length)];
          cells.put(
            i.isEven ? _cell(r, c, content: 'n:$i') : _cell(r, c, note: 'n$i'),
          );
        }
        for (final (top, left, bottom, right) in const [
          (0, 0, 29, 11),
          (5, 3, 9, 3),
          (0, 0, 2, 0),
          (-3, -1, 100, 100),
          (10, 10, 5, 5),
        ]) {
          for (final contentOnly in const [false, true]) {
            final visited = <(int, int, CellRecord)>[];
            cells.forEachIn(
              rows,
              cols,
              top,
              left,
              bottom,
              right,
              (r, c, cell) => visited.add((r, c, cell)),
              contentOnly: contentOnly,
            );

            expect(
              visited,
              cells
                  .cellsIn(
                    rows,
                    cols,
                    top,
                    left,
                    bottom,
                    right,
                    contentOnly: contentOnly,
                  )
                  .toList(),
            );
          }
        }
      },
    );

    test(
      'when formulas are put, replaced and removed then formulaCells follows in the order of all',
      () {
        cells.put(_cell(rowIds[0], colIds[0], content: '=1'));
        cells.put(_cell(rowIds[1], colIds[0], content: 'n:1'));
        cells.put(_cell(rowIds[2], colIds[0], content: '=2'));
        cells.put(_cell(rowIds[3], colIds[0], content: '=3'));
        cells.put(_cell(rowIds[0], colIds[0], content: '=1+1'));
        cells.put(_cell(rowIds[1], colIds[0], content: '=4'));
        cells.put(_cell(rowIds[2], colIds[0], content: 'n:2'));
        cells.remove('c:${rowIds[3]}:${colIds[0]}');

        expect(cells.formulaCells.map((c) => c.content), ['=1+1', '=4']);
        expect(
          cells.formulaCells.map((c) => c.id),
          cells.all.where((c) => c.content!.startsWith('=')).map((c) => c.id),
        );
      },
    );

    test('when a cell of a column changes then the column version changes', () {
      final v0 = cells.columnVersion(colIds[1]);
      cells.put(_cell(rowIds[0], colIds[1], content: 'n:1'));
      final v1 = cells.columnVersion(colIds[1]);
      cells.put(_cell(rowIds[0], colIds[1], content: 'n:2'));
      final v2 = cells.columnVersion(colIds[1]);
      cells.remove('c:${rowIds[0]}:${colIds[1]}');
      final v3 = cells.columnVersion(colIds[1]);

      expect({v0, v1, v2, v3}, hasLength(4));
      expect(cells.columnVersion(colIds[2]), 0);
    });
  });
}
