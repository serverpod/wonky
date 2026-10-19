import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

void main() {
  final registry = FunctionRegistry.standard;
  final implemented = [
    for (final s in registry.all)
      if (s.implemented) s,
  ];

  group('Given the built-in function registry', () {
    test('when listing implemented functions then each has a summary', () {
      final missing = [
        for (final s in implemented)
          if (s.help.summary.trim().isEmpty) s.name,
      ];

      expect(missing, isEmpty);
    });

    test(
      'when listing implemented functions then each syntax starts with its name',
      () {
        final wrong = [
          for (final s in implemented)
            if (!s.help.syntax.startsWith('${s.name}(')) s.name,
        ];

        expect(wrong, isEmpty);
      },
    );

    test(
      'when listing implemented functions then every argument is described',
      () {
        final missing = [
          for (final s in implemented)
            for (final a in s.help.args)
              if (a.description.trim().isEmpty) '${s.name}.${a.name}',
        ];

        expect(missing, isEmpty);
      },
    );

    test(
      'when listing implemented functions then each has an example that parses',
      () {
        final bad = <String>[];
        for (final s in implemented) {
          if (s.help.examples.isEmpty) bad.add('${s.name}: no example');
          for (final e in s.help.examples) {
            final (expr, error) = FormulaParser.tryParse(e, storedForm: false);
            if (expr == null) bad.add('${s.name}: $e ($error)');
          }
        }

        expect(bad, isEmpty);
      },
    );

    test(
      'when listing stubs then each is hidden and explains itself with #NAME?',
      () {
        final t = FormulaTestBench();
        final wrong = <String>[];
        for (final s in registry.all.where((s) => !s.implemented)) {
          final v = t.eval('=${s.name}()');
          final explained =
              v is FError &&
              v.kind == ErrorKind.name &&
              (v.message ?? '').isNotEmpty;
          if (!explained) wrong.add(s.name);
        }
        expect(wrong, isEmpty);
      },
    );
  });

  group('Given the catalog of spec 05 §15', () {
    // Text (§15.5), ROMAN/ARABIC (§15.1), database (§15.12) and QUERY (§15.17).
    const required = [
      'ARABIC', 'ASC', 'CHAR', 'CLEAN', 'CODE', 'CONCAT', 'CONCATENATE', //
      'DOLLAR', 'EXACT', 'FIND', 'FINDB', 'FIXED', 'JOIN', 'LEFT', 'LEFTB', //
      'LEN', 'LENB', 'LOWER', 'MID', 'MIDB', 'NUMBERVALUE', 'PROPER', //
      'REGEXEXTRACT', 'REGEXMATCH', 'REGEXREPLACE', 'REGEXTEST', 'REPLACE', //
      'REPLACEB', 'REPT', 'RIGHT', 'RIGHTB', 'ROMAN', 'SEARCH', 'SEARCHB', //
      'SPLIT', 'SUBSTITUTE', 'T', 'TEXT', 'TEXTAFTER', 'TEXTBEFORE', //
      'TEXTJOIN', 'TEXTSPLIT', 'TRIM', 'UNICHAR', 'UNICODE', 'UPPER', //
      'VALUE', 'VALUETOTEXT', 'ARRAYTOTEXT', //
      'DAVERAGE', 'DCOUNT', 'DCOUNTA', 'DGET', 'DMAX', 'DMIN', 'DPRODUCT', //
      'DSTDEV', 'DSTDEVP', 'DSUM', 'DVAR', 'DVARP', 'QUERY',
    ];

    for (final name in required) {
      test('when looking up $name then it is implemented', () {
        final spec = registry.lookup(name);

        expect(
          spec,
          isA<FunctionSpec>().having(
            (s) => s.implemented,
            'implemented',
            isTrue,
          ),
        );
      });
    }

    test(
      'when building the UI catalog then the Text and Database sections are listed',
      () {
        final labels = [for (final s in FunctionCatalog().forUi()) s.label];

        expect(labels, containsAll(['Text', 'Database', 'Google']));
      },
    );
  });
}
