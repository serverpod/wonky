import 'dart:async';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

Matcher isError(String literal) =>
    isA<FError>().having((e) => e.kind.literal, 'literal', literal);

final class _FakeCustomFunctions implements CustomFunctionProvider {
  final Map<String, FValue> results = {};
  final List<String> calls = [];
  final StreamController<String?> _updates = StreamController.broadcast(
    sync: true,
  );

  @override
  bool has(String upperName) => upperName == 'TO_F';

  @override
  FunctionHelp help(String upperName) => const FunctionHelp(
    summary: 'Celsius to Fahrenheit',
    syntax: 'TO_F(celsius)',
  );

  @override
  CustomFunctionResult? lookup(
    String upperName,
    List<FValue> args,
    String callerCellId,
  ) {
    final key = '$upperName(${args.map((a) => a.debugText).join(',')})';
    calls.add(key);
    final r = results[key];
    return r == null ? null : CustomFunctionResult(r);
  }

  void complete(String key, FValue v) {
    results[key] = v;
    _updates.add('TO_F');
  }

  @override
  Stream<String?> get updates => _updates.stream;
}

void main() {
  group('Given a chain of dependent formulas', () {
    late FormulaTestBench t;
    setUp(() {
      t = FormulaTestBench();
      t.setAll({'A1': 2, 'A2': '=A1*3', 'A3': '=A2+A1', 'B1': '=SUM(A:A)'});
    });

    test('when reading then values are computed', () {
      expect(t.value('A3'), const FNumber(8));
      expect(t.value('B1'), const FNumber(16));
    });
    test('when the input changes then dependents recalculate', () {
      t.value('A3');
      t.set('A1', 10);
      expect(t.value('A3'), const FNumber(40));
      expect(t.value('B1'), const FNumber(80));
    });
    test('when a formula is cleared then dependents see a blank', () {
      t.set('A2', null);
      expect(t.value('A3'), const FNumber(2));
    });
    test(
      'when a value changes then the change stream reports the cells',
      () async {
        t.engine.settle();
        final batches = <RecalcBatch>[];
        final sub = t.engine.changes.listen(batches.add);
        t.set('A1', 5);
        t.engine.settle();
        await sub.cancel();
        final cells = batches
            .expand((b) => b.cells)
            .map((c) => CellPos(c.row, c.col).a1)
            .toSet();
        expect(cells, containsAll(['A2', 'A3', 'B1']));
      },
    );
    test(
      'when asking for dependencies then precedents and dependents are reported',
      () {
        t.engine.settle();
        final s = t.sheet1.id;
        final info = t.engine.dependencies(s, 0, 0, transitive: true);
        expect(
          info.dependents.map((d) => CellPos(d.row, d.col).a1),
          containsAll(['A2', 'A3', 'B1']),
        );
        final p = t.engine.dependencies(s, 2, 0);
        expect(p.precedents.map((a) => a.rect.a1), containsAll(['A1', 'A2']));
      },
    );
  });

  group('Given row and column operations', () {
    late FormulaTestBench t;
    setUp(() {
      t = FormulaTestBench();
      t.setColumn('A1', [1, 2, 3]);
      t.set('C1', '=SUM(A1:A3)');
      t.set('C2', '=A3*10');
    });
    test(
      'when inserting a row inside the range then the formula displays the grown range',
      () {
        t.insertRows(1, 1);
        t.set('A2', 100);
        expect(t.formula('C1'), '=SUM(A1:A4)');
        expect(t.value('C1'), const FNumber(106));
      },
    );
    test(
      'when deleting the range end row then the range shrinks and the single ref is #REF!',
      () {
        t.deleteRows(2, 1);
        expect(t.formula('C1'), '=SUM(A1:A2)');
        expect(t.value('C1'), const FNumber(3));
        expect(t.formula('C2'), '=#REF!*10');
        expect(t.value('C2'), isError('#REF!'));
      },
    );
    test('when moving rows then references follow the data', () {
      // Row 3 moves to the top; whole rows move, so the formula of C2 travels
      // with its row to C3 and its reference follows the moved data (A3 → A1).
      t.moveRows(2, 1, 0);
      expect(t.formula('C3'), '=A1*10');
      expect(t.value('C3'), const FNumber(30));
    });
    test(
      'when a range endpoint row is moved then the coverage follows the endpoint ids',
      () {
        expect(t.value('C1'), const FNumber(6));
        // A3 (the end of A1:A3) moves above A1: the range now spans the moved
        // row and the old first row only (Excel semantics, 05 §5.5).
        t.moveRows(2, 1, 0);
        expect(t.formula('C2'), '=SUM(A1:A2)');
        expect(t.value('C2'), const FNumber(4));
        t.moveRows(0, 1, 2);
        expect(t.formula('C1'), '=SUM(A1:A3)');
        expect(t.value('C1'), const FNumber(6));
      },
    );
    test(
      'when a row moves into a range then lookups over the range see the new order',
      () {
        t.set('A5', 99);
        t.set('E1', '=INDEX(A1:A3, 2)');
        expect(t.value('E1'), const FNumber(2));
        t.moveRows(4, 1, 1);
        expect(t.value('E1'), const FNumber(99));
        expect(t.value('C1'), const FNumber(105));
      },
    );
    test('when moving columns then references follow the data', () {
      t.set('E1', '=SUM(A1:B1)');
      t.set('B1', 5);
      expect(t.value('E1'), const FNumber(6));
      final s = t.sheet1;
      final ids = s.columns.move(0, 1, 3);
      s.structureChanged();
      t.engine.axisChanged(s.id, GridDimension.columns, AxisChange.moved(ids));
      // A moved to D: SUM(A1:B1) now runs from D (old A) back to A (old B) and
      // covers the old C1 (=6) that now sits between them: 5 + 6 + 1.
      // C2 (=A3*10) is now B2 and reads the moved A3 at D3.
      expect(t.formula('E1'), '=SUM(A1:D1)');
      expect(t.value('E1'), const FNumber(12));
      expect(t.formula('B2'), '=D3*10');
      expect(t.value('B2'), const FNumber(30));
    });
    test(
      'when inserting a column before the data then formulas move with their ids',
      () {
        t.insertColumns(0, 1);
        expect(t.formula('D1'), '=SUM(B1:B3)');
        expect(t.value('D1'), const FNumber(6));
      },
    );
    test('when ROW() is used then it updates after an insert above', () {
      t.set('E5', '=ROW()');
      expect(t.value('E5'), const FNumber(5));
      t.insertRows(0, 2);
      expect(t.value('E7'), const FNumber(7));
    });
  });

  group('Given array formulas (spill)', () {
    late FormulaTestBench t;
    setUp(() => t = FormulaTestBench());
    test(
      'when a formula returns an array then it spills into overlay cells',
      () {
        t.set('A1', '=SEQUENCE(3, 2)');
        expect(t.value('A1'), const FNumber(1));
        expect(t.value('B3'), const FNumber(6));
        final ov = t.engine.overlayAt(t.sheet1.id, 2, 1);
        expect(ov?.hostRow, 0);
        expect(t.computed('A1').spill?.rect, const GridRect(0, 0, 2, 1));
      },
    );
    test(
      'when a cell inside the spill area gets content then the host shows #SPILL! and clearing restores it',
      () {
        t.set('A1', '=SEQUENCE(3)');
        t.set('C1', '=SUM(A1:A3)');
        expect(t.value('C1'), const FNumber(6));
        t.set('A2', 'x');
        final v = t.value('A1');
        expect(v, isError('#SPILL!'));
        expect((v as FError).message, ErrorMessages.spillBlocked('A2'));
        t.set('A2', null);
        expect(t.value('A1'), const FNumber(1));
        expect(t.value('C1'), const FNumber(6));
      },
    );
    test('when two spills collide then the earlier anchor wins', () {
      // Anchors are ordered by (sheet order, row index, column index) (05 §7.5):
      // B1 (row 1) comes before A2 (row 2), so B1 keeps its spill.
      t.set('A2', '=SEQUENCE(1, 3)');
      t.set('B1', '=SEQUENCE(3)');
      expect(t.value('B1'), const FNumber(1));
      expect(t.value('B2'), const FNumber(2));
      final v = t.value('A2');
      expect(v, isError('#SPILL!'));
      expect((v as FError).message, ErrorMessages.spillBlocked('B2'));
    });
    test(
      'when two spills collide then the winner does not depend on evaluation order',
      () {
        for (final first in ['A2', 'B1']) {
          final b = FormulaTestBench();
          final formulas = {'A2': '=SEQUENCE(1, 3)', 'B1': '=SEQUENCE(3)'};
          final second = first == 'A2' ? 'B1' : 'A2';
          b.set(first, formulas[first]);
          b.value(first);
          b.set(second, formulas[second]);
          expect(b.value('B1'), const FNumber(1), reason: '$first first');
          expect(b.value('B3'), const FNumber(3), reason: '$first first');
          expect(b.value('A2'), isError('#SPILL!'), reason: '$first first');
          expect(b.value('C2'), FEmpty.instance, reason: '$first first');
        }
      },
    );
    test('when the winning spill goes away then the blocked spill appears', () {
      t.set('A2', '=SEQUENCE(1, 3)');
      t.set('B1', '=SEQUENCE(3)');
      expect(t.value('A2'), isError('#SPILL!'));
      t.set('B1', 5);
      expect(t.value('A2'), const FNumber(1));
      expect(t.value('C2'), const FNumber(3));
      t.set('B1', '=SEQUENCE(2)');
      expect(t.value('A2'), isError('#SPILL!'));
      t.set('B1', null);
      expect(t.value('B2'), const FNumber(2));
    });
    test('when the winning spill shrinks then the blocked spill appears', () {
      t.set('E1', 3);
      t.set('B1', '=SEQUENCE(E1)');
      t.set('A2', '=SEQUENCE(1, 3)');
      expect(t.value('A2'), isError('#SPILL!'));
      t.set('E1', 1);
      expect(t.value('B1'), const FNumber(1));
      expect(t.value('A2'), const FNumber(1));
      expect(t.value('B2'), const FNumber(2));
    });
    test(
      'when a result does not fit the grid then #REF! asks for more rows',
      () {
        final small = FormulaTestBench(rows: 5);
        small.set('A4', '=SEQUENCE(4)');
        final v = small.value('A4');
        expect(v, isError('#REF!'));
        expect((v as FError).message, ErrorMessages.spillRows(2));
      },
    );
    test(
      'when reading a spilled cell from another formula then it updates with the host',
      () {
        t.set('A1', '=SEQUENCE(3, 1, D1)');
        t.set('D1', 10);
        t.set('E1', '=A3*2');
        expect(t.value('E1'), const FNumber(24));
        t.set('D1', 20);
        expect(t.value('E1'), const FNumber(44));
      },
    );
    test('when a bare range is the result then it spills', () {
      t.setColumn('A1', [1, 2]);
      t.set('B1', '=A1:A2');
      expect(t.value('B2'), const FNumber(2));
    });
    test(
      'when an expression over arrays is evaluated then it is lifted element-wise',
      () {
        t.set('A1', '={1,2,3}*2');
        expect(t.value('C1'), const FNumber(6));
        t.setColumn('E1', [1, 2, 3]);
        t.set('F1', '=ARRAYFORMULA(E1:E3+1)');
        expect(t.value('F3'), const FNumber(4));
      },
    );
    test('when a LAMBDA is the cell result then it is #CALC!', () {
      t.set('A1', '=LAMBDA(x, x)');
      expect(t.value('A1'), isError('#CALC!'));
    });
  });

  group('Given circular references', () {
    test('when a cell references itself then it shows the circular #REF!', () {
      final t = FormulaTestBench();
      t.set('A1', '=A1+1');
      final v = t.value('A1');
      expect(v, isError('#REF!'));
      expect((v as FError).message, ErrorMessages.circular);
    });
    test(
      'when two cells form a cycle then both are circular and dependents propagate the error',
      () {
        final t = FormulaTestBench();
        t.setAll({
          'A1': '=B1',
          'B1': '=A1',
          'C1': '=A1+1',
          'D1': '=IFERROR(A1, 0)',
        });
        expect(t.value('A1'), isError('#REF!'));
        expect(t.value('B1'), isError('#REF!'));
        expect(t.value('C1'), isError('#REF!'));
        expect(t.value('D1'), const FNumber(0));
        expect(
          t.engine.circularCells().map((c) => CellPos(c.row, c.col).a1),
          containsAll(['A1', 'B1']),
        );
      },
    );
    test('when the cycle is broken then values compute again', () {
      final t = FormulaTestBench();
      t.setAll({'A1': '=B1', 'B1': '=A1'});
      t.value('A1');
      t.set('B1', 5);
      expect(t.value('A1'), const FNumber(5));
      expect(t.engine.circularCells(), isEmpty);
    });
    test('when an edit closes a cycle then it is detected', () {
      final t = FormulaTestBench();
      t.setAll({'A1': '=B1*2', 'B1': 5, 'C1': '=A1+1'});
      expect(t.value('C1'), const FNumber(11));
      t.set('B1', '=A1');
      expect(t.value('C1'), isError('#REF!'));
      expect(t.value('A1'), isError('#REF!'));
      expect(t.engine.circularCells().map((c) => CellPos(c.row, c.col).a1), [
        'A1',
        'B1',
      ]);
    });
    test(
      'when a cycle member is reached through an already evaluated member then the whole component is circular',
      () {
        // A1 → B1 → A1 closes first; C1 reads B1 after B1 completed, but A1
        // also reads C1, so C1 is in the same strongly connected component.
        final t = FormulaTestBench();
        t.setAll({'A1': '=B1+C1', 'B1': '=A1', 'C1': '=IFERROR(B1, 7)'});
        expect(t.value('C1'), isError('#REF!'));
        expect(t.value('A1'), isError('#REF!'));
        expect(t.engine.circularCells().map((c) => CellPos(c.row, c.col).a1), [
          'A1',
          'B1',
          'C1',
        ]);
      },
    );
    test(
      'when the dependent of a cycle is read first then the cycle is still detected',
      () {
        final t = FormulaTestBench();
        t.setAll({'C1': '=A1+1', 'A1': '=B1', 'B1': '=A1'});
        expect(t.engine.valueAt(t.sheet1.id, 0, 2), isError('#REF!'));
        expect(t.value('A1'), isError('#REF!'));
        expect(t.value('B1'), isError('#REF!'));
      },
    );
    test(
      'when a cycle is longer than the nested evaluation depth then every member is circular',
      () {
        final t = FormulaTestBench();
        t.set('A1', '=A200+1');
        for (var r = 2; r <= 200; r++) {
          t.set('A$r', '=A${r - 1}');
        }
        t.set('B1', '=A100*2');
        expect(t.value('B1'), isError('#REF!'));
        expect(t.engine.circularCells(), hasLength(200));
      },
    );
    test(
      'when iterative calculation is enabled then A1=A1+1 increments by max iterations per recalculation',
      () {
        final t = FormulaTestBench(
          settings: const CalcSettings(
            iterativeCalc: true,
            maxIterations: 50,
            convergenceThreshold: 0.05,
          ),
        );
        t.set('A1', '=A1+1');
        expect(t.value('A1'), const FNumber(50));
        t.set(
          'B1',
          1,
        ); // any edit does not recalc A1 (not volatile) — force a recalculation:
        t.engine.invalidateAll();
        expect(t.value('A1'), const FNumber(100));
      },
    );
    test(
      'when an iterative cycle converges then the value stops near the fixpoint',
      () {
        final t = FormulaTestBench(
          settings: const CalcSettings(
            iterativeCalc: true,
            maxIterations: 100,
            convergenceThreshold: 0.0001,
          ),
        );
        t.setAll({'A1': '=(B1+4)/2', 'B1': '=A1'});
        expect((t.value('A1') as FNumber).v, closeTo(4, 0.001));
      },
    );
    test(
      'when the change falls below the convergence threshold then iteration stops',
      () {
        final t = FormulaTestBench(
          settings: const CalcSettings(
            iterativeCalc: true,
            maxIterations: 100,
            convergenceThreshold: 0.5,
          ),
        );
        // Sweeps from 0: 2, 3, 3.5, 3.75 (|Δ| = 0.25 < 0.5 stops).
        t.setAll({'A1': '=(B1+4)/2', 'B1': '=A1'});
        expect(t.value('A1'), const FNumber(3.75));
        expect(t.value('B1'), const FNumber(3.75));
      },
    );
    test(
      'when iterating a cycle then the result does not depend on which member is read first',
      () {
        for (final first in [0, 1]) {
          final t = FormulaTestBench(
            settings: const CalcSettings(
              iterativeCalc: true,
              maxIterations: 10,
              convergenceThreshold: 0.001,
            ),
          );
          t.setAll({'A1': '=B1+1', 'B1': '=A1+1'});
          t.engine.valueAt(t.sheet1.id, 0, first);
          // Gauss–Seidel sweeps in position order: A1 then B1.
          expect(t.value('A1'), const FNumber(19), reason: 'first $first');
          expect(t.value('B1'), const FNumber(20), reason: 'first $first');
        }
      },
    );
    test(
      'when a cycle is longer than the nested evaluation depth then it iterates',
      () {
        final t = FormulaTestBench(
          settings: const CalcSettings(
            iterativeCalc: true,
            maxIterations: 3,
            convergenceThreshold: 0.001,
          ),
        );
        t.set('A1', '=A200+1');
        for (var r = 2; r <= 200; r++) {
          t.set('A$r', '=A${r - 1}');
        }
        t.set('B1', '=A100*2');
        expect(t.value('B1'), const FNumber(6));
        expect(t.value('A200'), const FNumber(3));
        expect(t.engine.circularCells(), isEmpty);
      },
    );
    test(
      'when iterative calculation is switched on and off then the cycle follows the setting',
      () {
        final t = FormulaTestBench();
        t.set('A1', '=A1+1');
        expect(t.value('A1'), isError('#REF!'));
        t.updateSettings(
          const CalcSettings(iterativeCalc: true, maxIterations: 10),
        );
        expect(t.value('A1'), const FNumber(10));
        t.updateSettings(
          const CalcSettings(iterativeCalc: true, maxIterations: 1),
        );
        expect(t.value('A1'), const FNumber(11));
        t.updateSettings(const CalcSettings());
        expect(t.value('A1'), isError('#REF!'));
      },
    );
  });

  group('Given volatile functions', () {
    test(
      'when the clock moves and a cell is edited then NOW() recalculates',
      () {
        final t = FormulaTestBench(now: DateTime.utc(2026, 1, 1, 12));
        t.set('A1', '=RAND()');
        t.set('A2', '=RAND()');
        final a = t.value('A1'), b = t.value('A2');
        expect(a, isNot(equals(b)));
        expect((a as FNumber).v, inInclusiveRange(0, 1));
        t.engine.setRandomEpoch('epoch-2');
        expect(t.value('A1'), isNot(equals(a)));
      },
    );
    test('when two replicas use the same epoch then RAND() agrees', () {
      FValue run() {
        final t = FormulaTestBench();
        t.engine.setRandomEpoch('changelog-123');
        t.set('B2', '=RANDBETWEEN(1, 1000000)');
        t.engine.setRandomEpoch('changelog-123');
        return t.value('B2');
      }

      expect(run(), run());
    });
  });

  group('Given named ranges and named functions', () {
    late FormulaTestBench t;
    setUp(() {
      t = FormulaTestBench();
      t.setColumn('B2', [10, 20, 30]);
      final s = t.sheet1;
      t.workbook.addNamedRange(
        'Sales',
        IdRange(
          s.id,
          rowStart: s.rows.idAt(1),
          rowEnd: s.rows.idAt(3),
          colStart: s.columns.idAt(1),
          colEnd: s.columns.idAt(1),
        ),
      );
      t.workbook.addNamedFunction(
        'GROSS',
        '=LAMBDA(price, rate, price*(1+rate))',
      );
      t.workbook.addNamedFunction(
        'FACTR',
        '=LAMBDA(n, IF(n<=1, 1, n*FACTR(n-1)))',
      );
      t.engine.namesChanged({'Sales', 'GROSS', 'FACTR'});
    });
    test('when summing a named range then the range is used', () {
      t.set('D1', '=SUM(Sales)');
      expect(t.value('D1'), const FNumber(60));
    });
    test('when a row is inserted inside the named range then it grows', () {
      t.set('D1', '=SUM(Sales)');
      t.insertRows(2, 1);
      t.set('B3', 5);
      expect(t.value('D1'), const FNumber(65));
    });
    test(
      'when calling named functions then they evaluate, including recursion',
      () {
        expect((t.eval('=GROSS(100, 0.19)') as FNumber).v, closeTo(119, 1e-9));
        expect(t.eval('=FACTR(5)'), const FNumber(120));
        expect(
          t.eval('=MAP({1,2}, LAMBDA(x, GROSS(x, 1)))'),
          FArray.row(const [FNumber(2), FNumber(4)]),
        );
      },
    );
    test('when the argument count does not match then #N/A explains it', () {
      final v = t.eval('=GROSS(100)');
      expect(v, isError('#N/A'));
      expect(
        (v as FError).message,
        contains('Expected 2 arguments, but got 1 argument'),
      );
    });
    test('when a name is unknown then #NAME? names it', () {
      final v = t.eval('=SUM(Nope)');
      expect((v as FError).message, "Unknown range name: 'Nope'.");
      expect((t.eval('=FOO(1)') as FError).message, "Unknown function: 'FOO'.");
    });
    test('when a name is defined later then dependents recompute', () {
      t.set('D1', '=Later*2');
      expect(t.value('D1'), isError('#NAME?'));
      final s = t.sheet1;
      t.workbook.addNamedRange(
        'Later',
        IdRange(
          s.id,
          rowStart: s.rows.idAt(1),
          rowEnd: s.rows.idAt(1),
          colStart: s.columns.idAt(1),
          colEnd: s.columns.idAt(1),
        ),
      );
      t.engine.namesChanged({'Later'});
      expect(t.value('D1'), const FNumber(20));
    });
  });

  group('Given sheets', () {
    test(
      'when a referenced sheet is created later then the unbound reference resolves',
      () {
        final t = FormulaTestBench();
        t.set('A1', "='Budget 2027'!A1");
        expect(
          (t.value('A1') as FError).message,
          "Unresolved sheet name 'Budget 2027'.",
        );
        t.addSheet('Budget 2027');
        t.set("'Budget 2027'!A1", 7);
        expect(t.value('A1'), const FNumber(7));
      },
    );
    test('when a sheet is renamed then formulas keep working', () {
      final t = FormulaTestBench(sheets: ['Sheet1', 'Data']);
      t.set('Data!A1', 3);
      t.set('A1', '=Data!A1*2');
      t.renameSheet('Data', 'Numbers');
      expect(t.formula('A1'), '=Numbers!A1*2');
      expect(t.value('A1'), const FNumber(6));
    });
    test(
      'when INDIRECT points at a cell then edits of that cell recalculate it',
      () {
        final t = FormulaTestBench();
        t.setAll({'A1': 'B2', 'B2': 5, 'C1': '=INDIRECT(A1)+1'});
        expect(t.value('C1'), const FNumber(6));
        t.set('B2', 9);
        expect(t.value('C1'), const FNumber(10));
        t.set('A1', 'B3');
        t.set('B3', 1);
        expect(t.value('C1'), const FNumber(2));
      },
    );
  });

  group('Given async functions', () {
    test(
      'when a custom function has no cached result then the cell is pending and updates on arrival',
      () {
        final cf = _FakeCustomFunctions();
        final t = FormulaTestBench(customFunctions: cf);
        t.set('A1', 100);
        t.set('B1', '=TO_F(A1)');
        t.set('C1', '=IFERROR(B1, "caught")');
        final v = t.value('B1');
        expect(v, isA<FError>().having((e) => e.pending, 'pending', isTrue));
        expect(
          t.value('C1'),
          isA<FError>().having((e) => e.pending, 'pending', isTrue),
        );
        cf.complete('TO_F(100)', const FNumber(212));
        expect(t.value('B1'), const FNumber(212));
        expect(t.value('C1'), const FNumber(212));
      },
    );
    test('when IMPORTRANGE data arrives then the spill appears', () {
      final t = FormulaTestBench();
      t.set('A1', '=IMPORTRANGE("abc", "Sheet1!A1:A2")');
      expect((t.value('A1') as FError).pending, isTrue);
      final (key, _) = t.externalData.requests.single;
      t.externalData.complete(
        key,
        FArray.column(const [FNumber(1), FNumber(2)]),
      );
      expect(t.value('A2'), const FNumber(2));
    });
  });

  group('Given headless evaluation', () {
    test('when evaluating a detached formula then nothing is registered', () {
      final t = FormulaTestBench();
      t.set('A1', 4);
      expect(t.eval('=A1^2'), const FNumber(16));
      expect(t.engine.formulaCount, 0);
    });
    test(
      'when evaluating a rule formula relative to an anchor then references shift per cell',
      () {
        final t = FormulaTestBench();
        t.setColumn('B2', [50, 150, 200]);
        final stored = FormulaCodec.toStored(
          r'=$B2>100',
          CodecContext(
            workbook: t.workbook,
            hostSheetId: t.sheet1.id,
            hostRow: 1,
          ),
        );
        final rule = t.engine.compileRelative(
          stored,
          sheetId: t.sheet1.id,
          anchor: const CellPos(1, 0),
        );
        expect(
          [for (var r = 1; r <= 3; r++) rule.test(r, 3)],
          [false, true, true],
        );
      },
    );
    test('when previewing within a budget then a value is returned', () {
      final t = FormulaTestBench();
      t.set('A1', 2);
      final v = t.engine.evaluateDetached(
        '=A1*21',
        sheetId: t.sheet1.id,
        at: const CellPos(5, 5),
      );
      expect(v?.value, const FNumber(42));
    });
    test(
      'when explaining a formula then the tree has sub-expression values',
      () {
        final t = FormulaTestBench();
        t.setAll({'A1': 2, 'B1': '=A1*3+1'});
        final node = t.engine.explain(t.sheet1.id, 0, 1)!;
        expect(node.label, 'A1 * 3 + 1');
        expect(node.value, const FNumber(7));
        expect(node.children.first.label, 'A1 * 3');
        expect(node.children.first.children.first.area?.rect.a1, 'A1');
      },
    );
  });

  group('Given a long dependency chain', () {
    test(
      'when reading the last cell of a 20,000-cell chain then evaluation does not overflow the stack',
      () {
        final t = FormulaTestBench(rows: 20001, cols: 2);
        final s = t.sheet1;
        CodecContext ctxFor(int r) =>
            CodecContext(workbook: t.workbook, hostSheetId: s.id, hostRow: r);
        s.setInput(0, 0, EngineCellInput.value(const FNumber(1)));
        for (var r = 1; r < 20000; r++) {
          s.setInput(
            r,
            0,
            EngineCellInput.formula(FormulaCodec.toStored('=A$r+1', ctxFor(r))),
          );
        }
        t.engine.rectChanged(s.id, const GridRect(0, 0, 19999, 0));
        // pull the last cell first (reverse order)
        expect(t.engine.valueAt(s.id, 19999, 0), const FNumber(20000));
      },
    );
  });
}
