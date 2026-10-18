import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

void main() {
  group('Given a formula with named bindings', () {
    late FormulaTestBench t;
    setUp(() => t = FormulaTestBench());

    FValue eval(
      String formula,
      Map<String, FValue> bindings, {
      bool stored = false,
    }) => t.engine.evaluateWithBindings(
      formula,
      bindings,
      sheetId: t.sheet1.id,
      stored: stored,
    );

    test('when names are plain or quoted then their values are used', () {
      expect(
        eval("=Quantity * 'Unit price'", {
          'Quantity': const FNumber(3),
          'Unit price': const FNumber(2.5),
        }),
        const FNumber(7.5),
      );
    });

    test(
      'when names differ in case or contain quotes then they still match',
      () {
        expect(
          eval("=QUANTITY & 'o''brien'", {
            'quantity': const FNumber(2),
            "O'Brien": const FText('x'),
          }),
          const FText('2x'),
        );
      },
    );

    test('when bound to arrays then aggregates see all values', () {
      expect(
        eval('=SUM(Revenue)/COUNTA(Region)', {
          'Revenue': FArray.column(const [FNumber(10), FNumber(20)]),
          'Region': FArray.column(const [FText('East'), FText('West')]),
        }),
        const FNumber(15),
      );
    });

    test('when the formula also references cells then they are read', () {
      t.set('A1', 10);
      expect(eval('=Units*A1', {'Units': const FNumber(4)}), const FNumber(40));
    });

    test('when a named range has the same name then the binding wins', () {
      t.setColumn('B1', [100]);
      final s = t.sheet1;
      t.workbook.addNamedRange(
        'Units',
        IdRange(
          s.id,
          rowStart: s.rows.idAt(0),
          rowEnd: s.rows.idAt(0),
          colStart: s.columns.idAt(1),
          colEnd: s.columns.idAt(1),
        ),
      );
      t.engine.namesChanged({'Units'});
      expect(eval('=Units+1', {'Units': const FNumber(1)}), const FNumber(2));
      expect(t.eval('=Units+1'), const FNumber(101));
    });

    test('when LET binds the same name then the LET value shadows it', () {
      expect(
        eval('=LET(Units, 5, Units*2)+Units', {'Units': const FNumber(1)}),
        const FNumber(11),
      );
    });

    test('when the formula uses pivot field tokens then they bind by id', () {
      expect(
        eval('=⟦F:rev⟧/⟦F:units⟧', {
          'rev': const FNumber(100),
          'units': const FNumber(4),
        }, stored: true),
        const FNumber(25),
      );
    });

    test('when compiled once then it evaluates with new values each time', () {
      final f = t.engine.compileWithBindings('=a*b', [
        'a',
        'b',
      ], sheetId: t.sheet1.id);
      expect(f.parseError, isNull);
      expect(f.evaluate(const [FNumber(2), FNumber(3)]), const FNumber(6));
      expect(f.evaluate(const [FNumber(4), FNumber(5)]), const FNumber(20));
      expect(f.evaluate(const [FNumber(4)]), const FNumber(0));
    });

    test('when a name is not bound then it is #NAME?', () {
      final v = eval('=Price*2', {'Units': const FNumber(1)});
      expect(v, isA<FError>().having((e) => e.kind, 'kind', ErrorKind.name));
    });
  });
}
