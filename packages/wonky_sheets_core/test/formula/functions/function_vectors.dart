import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// Matcher for an expected formula result:
/// - a number (relative tolerance 1e-12 plus 1e-12 absolute),
/// - an error literal (`'#NUM!'`),
/// - a text, a boolean, `null` for an empty value,
/// - a `List<List<Object?>>` for an array (each element matched by these rules).
Matcher formulaResult(Object? want) => switch (want) {
  null => isA<FEmpty>(),
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, n.abs() * 1e-12 + 1e-12),
  ),
  final String s when s.startsWith('#') && s.length > 1 => isA<FError>().having(
    (v) => v.kind.literal,
    'error',
    s,
  ),
  final String s => isA<FText>().having((v) => v.v, 'text', s),
  final bool b => isA<FBool>().having((v) => v.v, 'bool', b),
  final List<List<Object?>> rows =>
    isA<FArray>()
        .having((a) => a.rows, 'rows', rows.length)
        .having((a) => a.cols, 'cols', rows.isEmpty ? 0 : rows.first.length)
        .having((a) => a.toRows(), 'elements', [
          for (final r in rows) [for (final e in r) formulaResult(e)],
        ]),
  _ => throw ArgumentError(want),
};

/// One test per `(formula, expected)` vector, evaluated with [bench].
void formulaVectors(FormulaTestBench bench, List<(String, Object?)> cases) {
  for (final (f, want) in cases) {
    test('when evaluating $f then it returns $want', () {
      final v = bench.eval(f);

      expect(v, formulaResult(want));
    });
  }
}
