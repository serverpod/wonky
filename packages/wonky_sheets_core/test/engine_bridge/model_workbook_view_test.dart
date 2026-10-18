import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';

import '../support/planner_harness.dart';

void main() {
  group('Given a tall sheet read through the engine view', () {
    late PlannerHarness h;
    late ModelWorkbookView view;
    late SheetModel sheet;

    /// What the view visits, as (row, col, input).
    List<(int, int, Object)> viaView(GridRect rect) {
      final out = <(int, int, Object)>[];
      view
          .sheetById(h.sheetId)!
          .forEachInput(rect, (r, c, i) => out.add((r, c, i)));
      return out;
    }

    /// The cells of [rect] straight from the model, in row-major order.
    List<(int, int, Object)> fromModel(GridRect rect) => [
      for (final (r, c, cell) in sheet.cellsIn(rect, contentOnly: true))
        (r, c, cellInputOf(cell)!),
    ];

    void put(int row, int col, String text) => h.apply(
      SetCellInputs(
        sheetId: h.sheetId,
        row: row,
        col: col,
        inputs: [
          [CellInput.user(text)],
        ],
      ),
    );

    setUp(() {
      final random = Random(5);
      final b = WorkbookBuilder()..sheet('Sheet1', rows: 3000, cols: 6);
      for (var r = 0; r < 3000; r++) {
        if (r % 7 != 3) b.value('A${r + 1}', r);
        if (random.nextInt(3) == 0) b.value('B${r + 1}', 'x$r');
        if (r % 500 == 0) b.set('C${r + 1}', null, note: 'note only');
      }
      h = PlannerHarness(b);
      view = ModelWorkbookView(h.model);
      sheet = h.model.sheets.first;
    });

    test(
      'when reading tall ranges then the cells and their order match the model',
      () {
        for (final rect in [
          GridRect(0, 0, 2999, 0),
          GridRect(10, 0, 2500, 1),
          GridRect(0, 0, 2999, 5),
          GridRect(-5, 0, 99999, 2),
          GridRect(2990, 0, 2999, 0),
        ]) {
          expect(viaView(rect), fromModel(rect), reason: '$rect');
        }
      },
    );

    test(
      'when a cell is edited, a row inserted and rows deleted then reads see the new state',
      () {
        final column = GridRect(0, 0, 2999, 0);
        viaView(column);

        put(3, 0, '42');
        expect(viaView(column), fromModel(column));

        h.apply(InsertDimension(h.sheetId, Dimension.rows, 100, 2));
        put(100, 0, '7');
        final grown = GridRect(0, 0, 3001, 0);
        expect(viaView(grown), fromModel(grown));

        h.apply(
          DeleteDimension(h.sheetId, Dimension.rows, [
            for (var r = 0; r < 50; r++) sheet.rows.idAt(r),
          ]),
        );
        final shrunk = GridRect(0, 0, 2951, 0);
        expect(viaView(shrunk), fromModel(shrunk));
        expect(viaView(shrunk).first.$1, 0);
      },
    );

    test('when the column is cleared then nothing is visited', () {
      final column = GridRect(0, 0, 2999, 0);
      viaView(column);

      h.apply(ClearRanges([h.range('A1:A3000')]));

      expect(viaView(column), isEmpty);
    });

    test('when the bound engine sums the column then edits are reflected', () {
      final binding = ModelEngineBinding.create(h.model);
      addTearDown(binding.dispose);
      put(0, 5, '=SUM(A:A)');
      final sum = [
        for (var r = 0; r < 3000; r++)
          if (r % 7 != 3) r,
      ].fold<int>(0, (a, b) => a + b);
      expect(binding.engine.valueAt(h.sheetId, 0, 5), FNumber(sum.toDouble()));

      put(1, 0, '1001');

      expect(binding.engine.valueAt(h.sheetId, 0, 5), FNumber(sum + 1000.0));
    });
  });

  group('Given a named range used by formulas', () {
    late PlannerHarness h;
    late ModelEngineBinding binding;

    void put(String a1, String text) {
      final r = h.range(a1);
      h.apply(
        SetCellInputs(
          sheetId: h.sheetId,
          row: r.rect.top,
          col: r.rect.left,
          inputs: [
            [CellInput.user(text)],
          ],
        ),
      );
    }

    FValue v(String a1) {
      final r = h.range(a1);
      return binding.engine.valueAt(r.sheetId, r.rect.top, r.rect.left);
    }

    setUp(() {
      final b = WorkbookBuilder()..sheet('Sheet1', rows: 20, cols: 4);
      b.values('A1', [
        [1],
        [2],
        [3],
        [4],
      ]);
      h = PlannerHarness(b);
      binding = ModelEngineBinding.create(h.model);
      h.apply(AddNamedRange('Data', range: h.range('A1:A2')));
      for (var r = 1; r <= 10; r++) {
        put('C$r', '=SUM(Data)+$r');
      }
    });
    tearDown(() => binding.dispose());

    test('when reading the names twice then the views are reused', () {
      final view = ModelWorkbookView(h.model);

      expect(view.namedRanges.single, same(view.namedRanges.single));
      expect(view.namedRanges.single.range, isNotNull);
    });

    test(
      'when the named range changes then every formula uses the new range',
      () {
        expect(v('C10'), const FNumber(13));
        final id = h.model.namedRanges.single.id;

        h.apply(UpdateNamedRange(id, range: h.range('A1:A4')));

        expect(v('C1'), const FNumber(11));
        expect(v('C10'), const FNumber(20));
      },
    );
  });

  group('Given a rule formula evaluated relative to its anchor', () {
    late PlannerHarness h;
    late ModelEngineBinding binding;
    late EngineFormulaHooks hooks;

    FValue rule(String stored, int row, {int anchorRow = 0}) =>
        hooks.evaluateRelative(
          stored,
          sheetId: h.sheetId,
          anchorRow: anchorRow,
          anchorCol: 1,
          row: row,
          col: 1,
        );

    setUp(() {
      final b = WorkbookBuilder()..sheet('Sheet1', rows: 10, cols: 3);
      b.values('A1', [
        [5],
        [50],
        [500],
      ]);
      h = PlannerHarness(b);
      binding = ModelEngineBinding.create(h.model);
      hooks = EngineFormulaHooks(h.model, engine: binding.engine);
    });
    tearDown(() => binding.dispose());

    test(
      'when rows are inserted above the cells then the compiled rule still follows the ids',
      () {
        final stored = hooks.toStored(
          '=A1>10',
          sheetId: h.sheetId,
          row: 0,
          col: 1,
        );
        expect(
          [for (var r = 0; r < 3; r++) rule(stored, r)],
          [FBool(false), FBool(true), FBool(true)],
        );

        h.apply(InsertDimension(h.sheetId, Dimension.rows, 0, 2));

        // The rule's range moved down with its rows: so did its anchor.
        expect(
          [for (var r = 2; r < 5; r++) rule(stored, r, anchorRow: 2)],
          [FBool.f, FBool.t, FBool.t],
        );
        // Relative to the old anchor, the references shift by the offset.
        expect(rule(stored, 2), FBool.t);
      },
    );

    test('when the rule text changes then the new formula is evaluated', () {
      String stored(String a1) =>
          hooks.toStored(a1, sheetId: h.sheetId, row: 0, col: 1);
      expect(rule(stored('=A1>10'), 1), FBool.t);

      expect(rule(stored('=A1>100'), 1), FBool.f);
      expect(rule(stored('=A1>100'), 2), FBool.t);
    });
  });
}
