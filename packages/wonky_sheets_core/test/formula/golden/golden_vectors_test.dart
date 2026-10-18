import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';
import 'package:yaml/yaml.dart';

/// Golden compatibility vectors (Sheets 05 §22.4; CQ-61): every
/// `test/formula/golden/<category>/*.yaml` entry is evaluated on a fresh
/// [FormulaTestBench] (en_US, fixed clock) and compared with the expected
/// value. The file format is described in `test/formula/golden/README.yaml`.
void main() {
  final root = Directory('test/formula/golden');
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.yaml'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final ids = <String>{};

  test('Given the vector files when loading them then every id is unique and '
      'every vector has a formula and an expected value', () {
    var count = 0;
    for (final f in files) {
      for (final v in _vectors(f)) {
        expect(ids.add(v.id), isTrue, reason: 'duplicate id ${v.id}');
        expect(v.formula, startsWith('='), reason: v.id);
        count++;
      }
    }
    expect(count, greaterThanOrEqualTo(100));
  });

  for (final f in files) {
    final category = f.parent.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
    group('Given the $category vectors', () {
      for (final v in _vectors(f)) {
        test(
          'when evaluating [${v.id}] ${v.formula} then it returns ${v.expected}',
          () {
            final bench = FormulaTestBench();
            bench.setAll(v.setup);

            final result = bench.eval(v.formula);

            expect(result, _matches(v.expected, v.tolerance));
          },
          skip: v.skip,
        );
      }
    });
  }
}

typedef _Vector = ({
  String id,
  Map<String, Object?> setup,
  String formula,
  Object? expected,
  double tolerance,
  String? skip,
});

List<_Vector> _vectors(File file) {
  final doc = loadYaml(file.readAsStringSync());
  if (doc == null) return const [];
  return [
    for (final e in (doc as YamlList).cast<YamlMap>())
      (
        id: e['id'] as String,
        setup: {
          for (final MapEntry(:key, :value)
              in ((e['setup'] as YamlMap?) ?? YamlMap()).entries)
            key as String: _plain(value),
        },
        formula: e['formula'] as String,
        expected: _plain((e['expect'] as YamlMap)['value']),
        tolerance: (e['tolerance'] as num?)?.toDouble() ?? 1e-12,
        skip: e['skip'] as String?,
      ),
  ];
}

/// YAML nodes as plain Dart values (`List<List<Object?>>` for arrays).
Object? _plain(Object? v) => switch (v) {
  final YamlList rows => <List<Object?>>[
    for (final r in rows) [for (final c in r as YamlList) _plain(c)],
  ],
  _ => v,
};

/// The expected [want] (number within [tolerance], error literal, text,
/// boolean, null for empty, rows for an array).
Matcher _matches(Object? want, double tolerance) => switch (want) {
  null => isA<FEmpty>(),
  final num n => isA<FNumber>().having(
    (v) => v.v,
    'value',
    closeTo(n, n.abs() * tolerance + 1e-12),
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
          for (final r in rows) [for (final e in r) _matches(e, tolerance)],
        ]),
  _ => throw ArgumentError(want),
};
