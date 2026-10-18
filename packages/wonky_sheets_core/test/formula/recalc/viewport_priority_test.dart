import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// [n] rows: numbers in A, `=A{r}*2` in B.
FormulaTestBench _bench(int n) {
  final b = FormulaTestBench(rows: n, cols: 2);
  final s = b.sheet1;
  for (var r = 0; r < n; r++) {
    s.setInput(r, 0, b.inputFor(s, r, 0, r));
    s.setInput(r, 1, b.inputFor(s, r, 1, '=A${r + 1}*2'));
  }
  b.engine.settle();
  return b;
}

bool _stale(FormulaTestBench b, int row) =>
    b.engine.peekValueAt(b.sheet1.id, row, 1)?.stale ?? true;

void main() {
  group('Given many dirty formulas and a viewport in the middle', () {
    late FormulaTestBench b;
    setUp(() {
      b = _bench(5000);
      b.engine.invalidateAll();
    });

    test(
      'when draining one slice then the visible formulas are evaluated first',
      () {
        b.engine.setViewport(b.sheet1.id, GridRect(2500, 0, 2519, 1));

        b.engine.drain(Duration.zero);

        expect([
          for (var r = 2500; r < 2520; r++) _stale(b, r),
        ], everyElement(isFalse));
        expect(b.engine.valueAt(b.sheet1.id, 2519, 1), FNumber(2 * 2519));
        expect(_stale(b, 4999), isTrue);
      },
    );

    test(
      'when the priority viewport is larger than the dirty set then it is honoured too',
      () {
        b.engine.settle();
        for (var r = 4000; r < 4010; r++) {
          b.sheet1.setInput(r, 0, b.inputFor(b.sheet1, r, 0, -r));
        }
        b.engine.rectChanged(b.sheet1.id, GridRect(4000, 0, 4009, 0));

        b.engine.drain(
          Duration.zero,
          priority: Viewport(b.sheet1.id, GridRect(0, 0, 4999, 1)),
        );

        expect(b.engine.pendingCount, 0);
        expect(b.engine.valueAt(b.sheet1.id, 4005, 1), FNumber(-2.0 * 4005));
      },
    );

    test('when draining everything then each value is right', () {
      b.engine.setViewport(b.sheet1.id, GridRect(10, 0, 30, 1));

      while (b.engine.pendingCount > 0) {
        b.engine.drain(Duration.zero);
      }

      expect(
        [
          for (var r = 0; r < 5000; r += 499)
            b.engine.valueAt(b.sheet1.id, r, 1),
        ],
        [for (var r = 0; r < 5000; r += 499) FNumber(2.0 * r)],
      );
    });
  });
}
