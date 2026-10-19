import 'dart:math';

import 'package:uuid/uuid.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/rows.dart';
import 'package:wonky_revlog/schema.dart';

/// A small spreadsheet-like schema: doc (root) → sheet → row → cell
/// (deterministic ids), plus a JSON rule table.
final testSchema = RevSchema('test', const [
  RevTable('doc', [RevColumn('title', RevColumnType.string)], isRoot: true),
  RevTable(
    'sheet',
    [
      RevColumn('docId', RevColumnType.uuid, immutable: true),
      RevColumn('name', RevColumnType.string),
      RevColumn('sortKey', RevColumnType.string),
    ],
    parents: [RevParent('docId', 'doc')],
    rank: 1,
  ),
  RevTable(
    'row',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('sortKey', RevColumnType.string),
      RevColumn('height', RevColumnType.double, nullable: true),
    ],
    parents: [RevParent('sheetId', 'sheet')],
    rank: 2,
  ),
  RevTable(
    'cell',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('rowId', RevColumnType.uuid, immutable: true),
      RevColumn('col', RevColumnType.int, immutable: true),
      RevColumn('content', RevColumnType.string, nullable: true),
      RevColumn('bold', RevColumnType.bool, nullable: true),
      RevColumn('at', RevColumnType.dateTime, nullable: true),
    ],
    parents: [RevParent('sheetId', 'sheet'), RevParent('rowId', 'row')],
    rank: 3,
    deterministicIds: true,
    coverage: RevCoverage.cellsByRow,
  ),
  RevTable(
    'rule',
    [
      RevColumn('sheetId', RevColumnType.uuid, immutable: true),
      RevColumn('ruleJson', RevColumnType.json),
      RevColumn('kind', RevColumnType.enumName, enumValues: ['a', 'b']),
    ],
    parents: [RevParent('sheetId', 'sheet')],
    rank: 2,
  ),
]);

const docId = '0190f0b0-0000-7000-8000-000000000001';
const sheetId = '0190f0b0-0000-7000-8000-000000000002';

/// Deterministic cell id.
String cellId(String sheet, String row, int col) => const Uuid().v5(
  '94020249-01b0-4143-b745-68f9aa91516f',
  'cell:$sheet:$row:$col',
);

String newId() => const Uuid().v7();

/// The creation changes of a fresh doc with one sheet and [rows] rows.
List<RowChange> creation({int rows = 3, List<String>? rowIds}) {
  final ids = rowIds ?? [for (var i = 0; i < rows; i++) newId()];
  return [
    RowChange.insert('doc', docId, {'title': 'Doc'}),
    RowChange.insert('sheet', sheetId, {
      'docId': docId,
      'name': 'Sheet1',
      'sortKey': 'a0',
    }),
    for (var i = 0; i < ids.length; i++)
      RowChange.insert('row', ids[i], {
        'sheetId': sheetId,
        'sortKey': 'a$i',
        'height': null,
      }),
  ];
}

/// Random planner-like edits over [model] (the replica's view).
List<RowChange> randomEdit(Random r, CurrentRowReader model, MapRowStore view) {
  final rows = (view.rows['row'] ?? const {}).keys.toList()..sort();
  if (rows.isEmpty) {
    if (model.currentColumns('sheet', sheetId) == null) return const [];
    return [
      RowChange.insert('row', newId(), {
        'sheetId': sheetId,
        'sortKey': 'z',
        'height': null,
      }),
    ];
  }
  switch (r.nextInt(10)) {
    case 0:
      return [
        RowChange.insert('row', newId(), {
          'sheetId': sheetId,
          'sortKey': 'k${r.nextInt(100)}',
          'height': null,
        }),
      ];
    case 1:
      // Delete a row with its cells (listed explicitly, like the planners).
      final row = rows[r.nextInt(rows.length)];
      final cells = (view.rows['cell'] ?? const {}).values
          .where((c) => c['rowId'] == row)
          .map((c) => RowChange.delete('cell', c['id']! as String, c))
          .toList();
      final full = model.currentColumns('row', row)!;
      return [...cells, RowChange.delete('row', row, full)];
    case 2:
      final row = rows[r.nextInt(rows.length)];
      final cur = model.currentColumns('row', row)!;
      final h = r.nextInt(5) * 10.0;
      return [
        RowChange.update('row', row, {'height': cur['height']}, {'height': h}),
      ];
    case 3:
      final cur = model.currentColumns('sheet', sheetId)!;
      return [
        RowChange.update(
          'sheet',
          sheetId,
          {'name': cur['name']},
          {'name': 'S${r.nextInt(9)}'},
        ),
      ];
    default:
      final row = rows[r.nextInt(rows.length)];
      final col = r.nextInt(4);
      final id = cellId(sheetId, row, col);
      final cur = model.currentColumns('cell', id);
      final bold = r.nextBool();
      if (cur == null) {
        return [
          RowChange.insert('cell', id, {
            'sheetId': sheetId,
            'rowId': row,
            'col': col,
            'content': bold ? null : 'v${r.nextInt(50)}',
            'bold': bold ? true : null,
            'at': null,
          }),
        ];
      }
      return bold
          ? [
              RowChange.update(
                'cell',
                id,
                {'bold': cur['bold']},
                {'bold': r.nextBool()},
              ),
            ]
          : [
              RowChange.update(
                'cell',
                id,
                {'content': cur['content']},
                {'content': 'v${r.nextInt(50)}'},
              ),
            ];
  }
}
