import 'dart:convert';
import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';

import '../../rules/support/rule_fixtures.dart';
import '../../support/planner_harness.dart';

const creator = 'creator-uuid';
const editor = 'editor-uuid';
const bo = 'bo-uuid';

/// Sheet1 (50 × 8): F2:F40 restricted to the creator + Bo, A45:B46 warning
/// only. Config (10 × 4): protected except B2:B5.
PlannerHarness protectedWorkbook({int seed = 1}) {
  final b = WorkbookBuilder();
  final s1 = b.sheet('Sheet1', rows: 50, cols: 8);
  final s2 = b.sheet('Config', rows: 10, cols: 4);
  b.use('Sheet1');
  b.row(SheetsTables.protectedRange, fid(1), {
    Cols.sheetId: s1,
    Cols.rangeJson: gridRange(b, s1, 1, 5, 39, 5).encode(),
    'editorsJson': jsonEncode([bo]),
    Cols.createdBy: creator,
  });
  b.row(SheetsTables.protectedRange, fid(2), {
    Cols.sheetId: s1,
    Cols.rangeJson: gridRange(b, s1, 44, 0, 45, 1).encode(),
    'warningOnly': true,
    Cols.createdBy: creator,
  });
  b.use('Config');
  b.row(SheetsTables.protectedRange, fid(3), {
    Cols.sheetId: s2,
    'exceptRangesJson': GridRange.encodeList([gridRange(b, s2, 1, 1, 4, 1)]),
    Cols.createdBy: creator,
  });
  return PlannerHarness(b, seed: seed);
}

GuardStatus client(PlannerHarness h, SheetsOperation op, String user) {
  if (op is AddProtection || op is UpdateProtection || op is DeleteProtection) {
    return GuardStatus.allowed;
  }
  final writes = WriteIntents.of(op, h.model, () => h.plan(op));
  return ProtectionCheck.ofWrites(h.model, writes, user, isOwner: false).status;
}

/// The applied form drops the `before` values of updates (RevLog 03 §2).
List<RowChange> appliedForm(List<RowChange> changes) => [
  for (final c in changes)
    c.op == RowOp.update
        ? RowChange.update(c.table, c.rowId, const {}, c.columnsAfter)
        : c,
];

GuardStatus server(PlannerHarness h, List<RowChange> applied, String user) =>
    ProtectionCheck.ofApplied(h.model, applied, user, isOwner: false).status;

void main() {
  late PlannerHarness h;
  late String s1;
  late String s2;
  setUp(() {
    h = protectedWorkbook();
    s1 = h.model.sheets[0].id;
    s2 = h.model.sheets[1].id;
  });

  SetCellInputs type(String sheet, int row, int col, String text) =>
      SetCellInputs(
        sheetId: sheet,
        row: row,
        col: col,
        inputs: [
          [CellInput.user(text)],
        ],
      );

  String rowId(int i, [String? sheet]) =>
      h.model.sheet(sheet ?? s1)!.rows.idAt(i);

  group('Given the applied form of an op (RevLog 05 §3.5)', () {
    test('when an editor types in a protected cell then it is blocked', () {
      final p = h.plan(type(s1, 4, 5, 'x'));
      expect(server(h, appliedForm(p.changes), editor), GuardStatus.blocked);
      expect(server(h, appliedForm(p.changes), bo), GuardStatus.allowed);
    });

    test('when an editor types in a warning range then it warns', () {
      final p = h.plan(type(s1, 44, 0, 'x'));
      expect(server(h, appliedForm(p.changes), editor), GuardStatus.warnings);
    });

    test('when rows are inserted inside a protection then it is blocked', () {
      final p = h.plan(InsertDimension(s1, Dimension.rows, 10, 2));
      expect(server(h, appliedForm(p.changes), editor), GuardStatus.blocked);
    });

    test(
      'when rows are inserted at the edge of a protection then it is allowed',
      () {
        final p = h.plan(InsertDimension(s1, Dimension.rows, 1, 1));
        expect(server(h, appliedForm(p.changes), editor), GuardStatus.allowed);
      },
    );

    test('when a protected row is deleted then it is blocked', () {
      final p = h.plan(DeleteDimension(s1, Dimension.rows, [rowId(9)]));
      expect(server(h, appliedForm(p.changes), editor), GuardStatus.blocked);
    });

    test('when a row is resized then it is allowed', () {
      final p = h.plan(ResizeDimension(s1, Dimension.rows, [rowId(9)], 40));
      expect(server(h, appliedForm(p.changes), editor), GuardStatus.allowed);
    });

    test(
      'when an unprotected row is deleted then the repair of a protected formula is exempt',
      () {
        h.apply(type(s1, 9, 5, '=A48+1'));
        final p = h.plan(DeleteDimension(s1, Dimension.rows, [rowId(47)]));
        final f10 = p.changes.where(
          (c) => c.table == SheetsTables.cell && c.op == RowOp.update,
        );
        expect(f10, isNotEmpty, reason: 'F10 is repaired to #REF!');
        expect(server(h, appliedForm(p.changes), editor), GuardStatus.allowed);
      },
    );

    test(
      'when a formula repair also rewrites other text then it is not exempt',
      () {
        h.apply(type(s1, 9, 5, '=A48+1'));
        final p = h.plan(DeleteDimension(s1, Dimension.rows, [rowId(47)]));
        final forged = [
          for (final c in appliedForm(p.changes))
            if (c.table == SheetsTables.cell && c.op == RowOp.update)
              RowChange.update(c.table, c.rowId, const {}, {
                CellCols.content: '${c.columnsAfter[CellCols.content]}+2',
              })
            else
              c,
        ];
        expect(server(h, forged, editor), GuardStatus.blocked);
      },
    );

    test(
      'when a formula ref is repointed without a deleted line then it is not exempt',
      () {
        h.apply(type(s1, 9, 5, '=A48+1'));
        final before = h.content('F10')!;
        final other = h.plan(type(s1, 9, 6, '=A3+1'));
        final after =
            other.changes
                    .firstWhere((c) => c.table == SheetsTables.cell)
                    .columnsAfter[CellCols.content]!
                as String;
        final f10 = cellAtA1(h.model, 'F10')!;
        expect(
          BoundaryRepair.isRepair(
            RowChange.update(
              SheetsTables.cell,
              f10.id,
              {CellCols.content: before},
              {CellCols.content: after},
            ),
            {rowId(20)},
          ),
          isFalse,
        );
      },
    );

    test('when an editor deletes a protection then it is blocked', () {
      final rec = h.model.record(SheetsTables.protectedRange, fid(1))!;
      final del = RowChange.delete(
        SheetsTables.protectedRange,
        fid(1),
        h.model.currentColumns(SheetsTables.protectedRange, rec.id)!,
      );
      expect(server(h, [del], editor), GuardStatus.blocked);
      expect(server(h, [del], creator), GuardStatus.allowed);
    });

    test('when a protected sheet is deleted then it is blocked', () {
      final p = h.plan(DeleteSheet(s2));
      expect(server(h, appliedForm(p.changes), editor), GuardStatus.blocked);
      expect(client(h, DeleteSheet(s2), editor), GuardStatus.blocked);
    });
  });

  group('Given random operations (09 §2.8 parity)', () {
    for (var seed = 0; seed < 12; seed++) {
      test(
        'when checked on the client and on the server (seed $seed) then both agree',
        () {
          final h = protectedWorkbook(seed: seed);
          final r = Random(seed);
          // A protected formula pointing at an unprotected row.
          h.apply(type(h.model.sheets[0].id, 9, 5, '=A48+1'));
          final seen = <GuardStatus>{};
          for (var step = 0; step < 40; step++) {
            final op = _randomOp(h, r);
            if (op == null) continue;
            final user = [editor, bo, creator][r.nextInt(3)];
            final MutationPlan plan;
            try {
              plan = h.plan(op);
            } on Object {
              continue;
            }
            final expected = client(h, op, user);
            final actual = server(h, appliedForm(plan.changes), user);
            seen.add(actual);
            expect(
              actual,
              expected,
              reason: 'seed $seed step $step: $op by $user',
            );
            h.model.applyPlan(plan);
          }
          expect(seen, containsAll([GuardStatus.allowed, GuardStatus.blocked]));
        },
        tags: ['property'],
      );
    }
  });
}

SheetsOperation? _randomOp(PlannerHarness h, Random r) {
  final sheets = h.model.sheets;
  final s = sheets[r.nextInt(sheets.length)];
  final rows = s.rows.length;
  final cols = s.columns.length;
  if (rows < 3 || cols < 3) return null;
  int row() => r.nextInt(rows);
  int col() => r.nextInt(cols);
  switch (r.nextInt(9)) {
    case 0 || 1 || 2:
      return SetCellInputs(
        sheetId: s.id,
        row: row(),
        col: col(),
        inputs: [
          [CellInput.user('v${r.nextInt(9)}')],
        ],
      );
    case 3:
      final top = row(), left = col();
      return ClearRanges([
        ResolvedRange(
          s.id,
          GridRect(top, left, min(rows - 1, top + 2), min(cols - 1, left + 1)),
        ),
      ]);
    case 4:
      final top = row(), left = col();
      return SetFormat(
        [
          ResolvedRange(
            s.id,
            GridRect(top, left, min(rows - 1, top + 1), left),
          ),
        ],
        {FormatAttr.bold: true},
      );
    case 5:
      return InsertDimension(
        s.id,
        r.nextBool() ? Dimension.rows : Dimension.columns,
        r.nextInt(r.nextBool() ? rows : cols),
        1 + r.nextInt(2),
      );
    case 6:
      final dim = r.nextBool() ? Dimension.rows : Dimension.columns;
      final axis = s.axis(dim);
      final i = r.nextInt(axis.length - 1);
      return DeleteDimension(s.id, dim, [axis.idAt(i)]);
    case 7:
      final axis = s.axis(Dimension.rows);
      return ResizeDimension(s.id, Dimension.rows, [
        axis.idAt(r.nextInt(axis.length)),
      ], 30);
    default:
      final axis = s.axis(Dimension.rows);
      final i = r.nextInt(axis.length - 2);
      return MoveDimension(s.id, Dimension.rows, [
        axis.idAt(i),
      ], axis.idAt(axis.length - 1));
  }
}
