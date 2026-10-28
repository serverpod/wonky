import 'package:test/test.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

/// A document with a paragraph, a table [id] of [rows] (row ids r0, r1, …)
/// and a paragraph.
Delta tableDoc(
  List<List<String>> rows, {
  String id = 't',
  List<CellAlign?> align = const [],
}) {
  var n = 0;
  final d = Delta()..insert('Before\n');
  for (final op in CellLines.table(
    id: id,
    rows: [
      for (final r in rows) [for (final c in r) Delta()..insert(c)],
    ],
    align: align,
    rowId: () => 'r${n++}',
  ).toList()) {
    d.push(op);
  }
  return d..insert('After\n');
}

/// The table's cell texts, row by row.
List<List<String>> cells(Delta doc, [String id = 't']) {
  final t = CellRuns.table(WonkyDocument(doc), id);
  if (t == null) return const [];
  return [
    for (final r in t.rows) [for (final c in r.cells) c.text],
  ];
}

/// [doc] with [change] applied; checks the result is valid.
Delta apply(Delta doc, Delta? change) {
  expect(change, isNotNull);
  final out = const WonkyDeltaNormalizer()
      .normalize(doc.compose(change!))
      .document;
  final validation = const WonkyDeltaValidator().validate(out);
  expect(validation.isValid, isTrue, reason: '${validation.issues}');
  return out;
}

void main() {
  var ids = 0;
  String rowId() => 'n${ids++}';
  setUp(() => ids = 0);

  group('Given a 2×2 table', () {
    final doc = tableDoc([
      ['A', 'B'],
      ['1', '2'],
    ]);
    final w = WonkyDocument(doc);

    test('when inserting a row in the middle then the cells are empty and '
        'the row gets a new id', () {
      final out = apply(doc, CellEdits.insertRow(w, 't', 1, rowId: rowId));
      expect(cells(out), [
        ['A', 'B'],
        ['', ''],
        ['1', '2'],
      ]);
      final t = CellRuns.table(WonkyDocument(out), 't')!;
      expect(t.rows.map((r) => r.id), ['r0', 'n0', 'r1']);
    });

    test('when appending a row with content then it is the last row', () {
      final out = apply(
        doc,
        CellEdits.insertRow(
          w,
          't',
          2,
          cells: [
            Delta()..insert('x', {'bold': true}),
          ],
          rowId: rowId,
        ),
      );
      expect(cells(out).last, ['x', '']);
      expect(WonkyDocument(out).lines.last.text, 'After');
    });

    test('when inserting a row then the change only inserts', () {
      final change = CellEdits.insertRow(w, 't', 1, rowId: rowId);
      expect(change.toList().where((op) => op.isDelete), isEmpty);
    });

    test('when deleting a row then the others keep their ids', () {
      final out = apply(doc, CellEdits.deleteRow(w, 't', 0));
      expect(cells(out), [
        ['1', '2'],
      ]);
      expect(CellRuns.table(WonkyDocument(out), 't')!.rows.single.id, 'r1');
    });

    test('when deleting every row then the table is gone', () {
      final one = apply(doc, CellEdits.deleteRow(w, 't', 1));
      final out = apply(one, CellEdits.deleteRow(WonkyDocument(one), 't', 0));
      expect(cells(out), isEmpty);
      expect(DeltaUtils.text(out), 'Before\nAfter\n');
    });

    test('when inserting a column at each position then every row grows', () {
      for (final at in [0, 1, 2]) {
        final out = apply(
          doc,
          CellEdits.insertColumn(
            w,
            't',
            at,
            header: Delta()..insert('H'),
            cells: [Delta()..insert('v')],
          ),
        );
        final expected = [
          ['A', 'B'],
          ['1', '2'],
        ];
        expected[0].insert(at, 'H');
        expected[1].insert(at, 'v');
        expect(cells(out), expected, reason: 'at $at');
      }
    });

    test('when deleting a column then every row shrinks', () {
      final out = apply(doc, CellEdits.deleteColumn(w, 't', 0));
      expect(cells(out), [
        ['B'],
        ['2'],
      ]);
    });

    test('when deleting the only column then the table is gone', () {
      final one = apply(doc, CellEdits.deleteColumn(w, 't', 0));
      final out = apply(
        one,
        CellEdits.deleteColumn(WonkyDocument(one), 't', 0),
      );
      expect(DeltaUtils.text(out), 'Before\nAfter\n');
    });

    test('when moving a row then its cells and id move', () {
      final out = apply(doc, CellEdits.moveRow(w, 't', 1, 0));
      expect(cells(out), [
        ['1', '2'],
        ['A', 'B'],
      ]);
      final t = CellRuns.table(WonkyDocument(out), 't')!;
      expect(t.rows.map((r) => r.id), ['r1', 'r0']);
    });

    test('when moving a column then every row is reordered', () {
      final out = apply(doc, CellEdits.moveColumn(w, 't', 0, 1));
      expect(cells(out), [
        ['B', 'A'],
        ['2', '1'],
      ]);
    });

    test('when moving to the same place then nothing changes', () {
      expect(CellEdits.moveRow(w, 't', 0, 0), isNull);
      expect(CellEdits.moveColumn(w, 't', 1, 1), isNull);
    });

    test('when setting a column alignment then every cell of the column has '
        'it and setting it again is a no-op', () {
      final out = apply(
        doc,
        CellEdits.setColumnAlignment(w, 't', 1, CellAlign.right),
      );
      final t = CellRuns.table(WonkyDocument(out), 't')!;
      expect(t.align, [null, CellAlign.right]);
      for (final r in t.rows) {
        expect(CellAttr.of(r.cells[1].attributes)!.align, CellAlign.right);
        expect(CellAttr.of(r.cells[0].attributes)!.align, isNull);
      }
      expect(
        CellEdits.setColumnAlignment(
          WonkyDocument(out),
          't',
          1,
          CellAlign.right,
        ),
        isNull,
      );
    });

    test('when setting a cell then only that cell changes', () {
      final out = apply(
        doc,
        CellEdits.setCell(w, 't', 1, 0, Delta()..insert('one\ntwo')),
      );
      expect(cells(out), [
        ['A', 'B'],
        ['one two', '2'],
      ]);
      expect(
        CellEdits.setCell(
          WonkyDocument(out),
          't',
          1,
          0,
          Delta()..insert('one two'),
        ),
        isNull,
      );
    });

    test('when an index is out of range then CellEditException is thrown', () {
      expect(
        () => CellEdits.deleteRow(w, 't', 5),
        throwsA(isA<CellEditException>()),
      );
      expect(
        () => CellEdits.insertColumn(w, 't', 3),
        throwsA(isA<CellEditException>()),
      );
      expect(
        () => CellEdits.setCell(w, 't', 0, 2, Delta()),
        throwsA(isA<CellEditException>()),
      );
      expect(
        () => CellEdits.deleteTable(w, 'nope'),
        throwsA(isA<CellEditException>()),
      );
    });

    test('when replacing the table then unchanged cells keep their lines', () {
      final change = CellEdits.replaceTable(w, 't', [
        [Delta()..insert('A'), Delta()..insert('B')],
        [Delta()..insert('1'), Delta()..insert('two')],
        [Delta()..insert('3'), Delta()],
      ], rowId: rowId)!;
      final out = apply(doc, change);
      expect(cells(out), [
        ['A', 'B'],
        ['1', 'two'],
        ['3', ''],
      ]);
      // Only the changed cell's text is deleted.
      final deleted = change
          .toList()
          .where((op) => op.isDelete)
          .fold(0, (n, op) => n + op.length!);
      expect(deleted, 1);
    });

    test('when replacing the table with fewer columns then the extra cells '
        'are deleted', () {
      final out = apply(
        doc,
        CellEdits.replaceTable(w, 't', [
          [Delta()..insert('A')],
          [Delta()..insert('1')],
        ]),
      );
      expect(cells(out), [
        ['A'],
        ['1'],
      ]);
    });

    test('when replacing with the same content then nothing changes', () {
      expect(
        CellEdits.replaceTable(w, 't', [
          [Delta()..insert('A'), Delta()..insert('B')],
          [Delta()..insert('1'), Delta()..insert('2')],
        ]),
        isNull,
      );
    });
  });

  group('Given a table with a comment in a cell', () {
    final doc =
        tableDoc([
          ['A', 'B'],
          ['1', '2'],
        ]).compose(
          Delta()
            ..retain('Before\nA\nB\n'.length)
            ..retain(1, {'cmt_c1': true}),
        );

    test('when inserting a column then the comment stays on its text', () {
      final out = apply(
        doc,
        CellEdits.insertColumn(WonkyDocument(doc), 't', 0),
      );
      final line = CellRuns.table(WonkyDocument(out), 't')!.rows[1].cells[1];
      expect(line.text, '1');
      expect(line.segments.single.attributes, {'cmt_c1': true});
    });

    test('when moving its row then the comment moves with the text', () {
      final out = apply(doc, CellEdits.moveRow(WonkyDocument(doc), 't', 1, 0));
      final line = CellRuns.table(WonkyDocument(out), 't')!.rows[0].cells[0];
      expect(line.segments.single.attributes, {'cmt_c1': true});
    });
  });

  group('Given a ragged table', () {
    // Row 1 has one cell, row 2 three.
    final doc = Delta()
      ..insert('A\n', {
        'cell': {'table': 't', 'row': 'a'},
      })
      ..insert('B\n', {
        'cell': {'table': 't', 'row': 'a'},
      })
      ..insert('1\n', {
        'cell': {'table': 't', 'row': 'b'},
      })
      ..insert('x\n', {
        'cell': {'table': 't', 'row': 'c'},
      })
      ..insert('y\n', {
        'cell': {'table': 't', 'row': 'c'},
      })
      ..insert('z\n', {
        'cell': {'table': 't', 'row': 'c'},
      });
    final w = WonkyDocument(doc);

    test('when completing the rows then every row has three cells', () {
      final out = apply(doc, CellEdits.completeRows(w, 't'));
      expect(cells(out), [
        ['A', 'B', ''],
        ['1', '', ''],
        ['x', 'y', 'z'],
      ]);
      expect(CellEdits.completeRows(WonkyDocument(out), 't'), isNull);
    });

    test('when inserting a column then the rows are completed too', () {
      final out = apply(doc, CellEdits.insertColumn(w, 't', 3));
      expect(cells(out), [
        ['A', 'B', '', ''],
        ['1', '', '', ''],
        ['x', 'y', 'z', ''],
      ]);
    });

    test('when deleting the column a short row lacks then that row is '
        'completed up to the new width', () {
      final out = apply(doc, CellEdits.deleteColumn(w, 't', 2));
      expect(cells(out), [
        ['A', 'B'],
        ['1', ''],
        ['x', 'y'],
      ]);
    });
  });

  group('Given a table in a callout', () {
    final box = Boxes.toValue([BoxFrame(id: 'b1', type: BoxType.callout)]);
    final doc = Delta()
      ..insert('A\n', {
        'cell': {'table': 't', 'row': 'a'},
        'box': box,
      })
      ..insert('Tail\n');

    test('when inserting a row then its cells are in the callout', () {
      final out = apply(
        doc,
        CellEdits.insertRow(WonkyDocument(doc), 't', 1, rowId: rowId),
      );
      final t = CellRuns.table(WonkyDocument(out), 't')!;
      expect(t.rows.last.cells.single.attributes['box'], box);
    });
  });

  group('Given a grid of two items', () {
    final doc = Delta()
      ..insert('Intro\n')
      ..insert('One\n', {
        'grid': {'id': 'g', 'columns': 2, 'bullets': 'check'},
      })
      ..insert('Two\n', {
        'grid': {'id': 'g', 'columns': 2, 'bullets': 'check'},
      });
    final w = WonkyDocument(doc);
    List<String> items(Delta d) => [
      for (final l
          in CellRuns.grid(WonkyDocument(d), 'g')?.items ??
              const <DocumentLine>[])
        l.text,
    ];

    test('when setting the columns then every item has them', () {
      final out = apply(doc, CellEdits.setGridColumns(w, 'g', 3));
      final g = CellRuns.grid(WonkyDocument(out), 'g')!;
      for (final item in g.items) {
        expect(GridItemAttr.of(item.attributes)!.columns, 3);
      }
      expect(CellEdits.setGridColumns(WonkyDocument(out), 'g', 3), isNull);
    });

    test('when setting the bullets then every item has them', () {
      final out = apply(
        doc,
        CellEdits.setGridBullets(w, 'g', GridBullets.none),
      );
      expect(CellRuns.grid(WonkyDocument(out), 'g')!.bullets, GridBullets.none);
    });

    test('when adding items then they are inserted in place', () {
      final first = apply(
        doc,
        CellEdits.addGridItem(w, 'g', 0, content: Delta()..insert('Zero')),
      );
      expect(items(first), ['Zero', 'One', 'Two']);
      final last = apply(doc, CellEdits.addGridItem(w, 'g', 2));
      expect(items(last), ['One', 'Two', '']);
    });

    test('when removing items then the last removal deletes the grid', () {
      final one = apply(doc, CellEdits.removeGridItem(w, 'g', 0));
      expect(items(one), ['Two']);
      final none = apply(
        one,
        CellEdits.removeGridItem(WonkyDocument(one), 'g', 0),
      );
      expect(CellRuns.grid(WonkyDocument(none), 'g'), isNull);
    });

    test('when setting an item then only its text changes', () {
      final out = apply(
        doc,
        CellEdits.setGridItem(w, 'g', 1, Delta()..insert('2')),
      );
      expect(items(out), ['One', '2']);
    });

    test('when deleting the grid then only the intro is left', () {
      final out = apply(doc, CellEdits.deleteGrid(w, 'g'));
      expect(DeltaUtils.text(out), 'Intro\n');
    });
  });
}
