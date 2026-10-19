@Tags(['property'])
library;

import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';
import 'package:wonky_sheets_core/revlog.dart';

import '../support/planner_harness.dart';

/// Plans list descendants (RevLog spec 09 §2.4, RD-3): for random models and
/// delete operations, the plan deletes every model descendant of every row
/// it deletes, so the sequencer's cascade never has to remove rows the
/// client didn't list.
void main() {
  for (var seed = 0; seed < 12; seed++) {
    test(
      'Given a random workbook (seed $seed) when rows, columns and sheets are deleted then plans list every descendant',
      () {
        final r = Random(seed);
        final h = PlannerHarness(
          WorkbookBuilder()
            ..sheet('Sheet1', rows: 30, cols: 8)
            ..sheet('Sheet2', rows: 20, cols: 6),
          seed: seed,
        );
        _populate(h, r);
        for (var step = 0; step < 25; step++) {
          final op = _randomDelete(h, r);
          if (op == null) continue;
          final plan = h.plan(op);
          final missing = _unlistedDescendants(sheetsSchema, h.model, plan);
          expect(missing, isEmpty, reason: 'seed $seed step $step: $op');
          h.model.applyPlan(plan);
          if (r.nextInt(3) == 0) _populate(h, r);
        }
      },
    );
  }
}

void _populate(PlannerHarness h, Random r) {
  for (final s in h.model.sheets) {
    final rows = s.rows.length, cols = s.columns.length;
    if (rows < 4 || cols < 4) continue;
    for (var i = 0; i < 6; i++) {
      h.apply(
        SetCellInputs(
          sheetId: s.id,
          row: r.nextInt(rows),
          col: r.nextInt(cols),
          inputs: [
            [CellInput.user(r.nextBool() ? 'v$i' : '=A1+$i')],
          ],
        ),
      );
    }
    final top = r.nextInt(rows - 3), left = r.nextInt(cols - 3);
    final rect = GridRect(top, left, top + 2, left + 1);
    switch (r.nextInt(4)) {
      case 0:
        h.apply(MergeCells([ResolvedRange(s.id, rect)], force: true));
      case 1:
        h.apply(
          AddCfRule(
            s.id,
            [rect],
            '{"v":1,"type":"boolean","condition":{"type":"numberGreater","values":[{"v":"3"}]}}',
          ),
        );
      case 2:
        h.apply(SetDataValidation(s.id, [rect], '{"type":"checkbox"}'));
      default:
        h.apply(AddProtection(s.id, range: rect));
    }
  }
}

SheetsOperation? _randomDelete(PlannerHarness h, Random r) {
  final sheets = h.model.sheets;
  final s = sheets[r.nextInt(sheets.length)];
  switch (r.nextInt(6)) {
    case 0:
      if (sheets.length < 2) return null;
      return DeleteSheet(s.id);
    case 1 || 2:
      final axis = s.axis(Dimension.columns);
      if (axis.length < 3) return null;
      final i = r.nextInt(axis.length - 1);
      return DeleteDimension(s.id, Dimension.columns, [
        axis.idAt(i),
        axis.idAt(i + 1),
      ]);
    default:
      final axis = s.axis(Dimension.rows);
      if (axis.length < 3) return null;
      final i = r.nextInt(axis.length - 2);
      return DeleteDimension(s.id, Dimension.rows, [
        axis.idAt(i),
        if (r.nextBool()) axis.idAt(i + 1),
      ]);
  }
}

/// Model rows whose parent chain reaches a row [plan] deletes, but which
/// the plan neither deletes nor moves to another parent.
List<String> _unlistedDescendants(
  RevSchema schema,
  WorkbookModel model,
  MutationPlan plan,
) {
  final deleted = <(String, String)>{
    for (final c in plan.changes)
      if (c.op == RowOp.delete) (c.table, c.rowId),
  };
  final rewritten = <(String, String), Map<String, Object?>>{
    for (final c in plan.changes)
      if (c.op == RowOp.update) (c.table, c.rowId): c.columnsAfter,
  };
  final rows = [
    for (final (table, cols) in model.allRows())
      if (schema.tryTable(table) != null) (table, cols),
  ];
  final gone = {...deleted};
  final missing = <String>[];
  var grew = true;
  while (grew) {
    grew = false;
    for (final (table, cols) in rows) {
      final key = (table, cols[Cols.id]! as String);
      if (gone.contains(key)) continue;
      final after = {...cols, ...?rewritten[key]};
      final orphan = schema
          .table(table)
          .parents
          .any((p) => gone.contains((p.table, '${after[p.column]}')));
      if (orphan) {
        gone.add(key);
        missing.add('$table ${key.$2}');
        grew = true;
      }
    }
  }
  return missing;
}
