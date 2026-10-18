import 'dart:io';

import 'package:test/test.dart';
import 'package:wonky_numfmt/wonky_numfmt.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

/// CQ-50: TEXT() formatted with its own engine (1,100 lines) that disagreed
/// with the cell display (`wonky_numfmt`) on about 6 % of (pattern, value)
/// pairs; it now formats through `wonky_numfmt`.
///
/// `test/fixtures/text_format_vectors.tsv` pins the former engine's output
/// on the 3,375 pairs (en_US, de_DE) where both agreed. The groups below pin
/// where TEXT() intentionally changed to what the cell shows (Sheets 06 §5.11).
void main() {
  const formatter = NumberFormatTextFormatter();

  String? text(Object value, String pattern, [String locale = 'en_US']) =>
      formatter.format(
        value is double ? FNumber(value) : FText(value as String),
        pattern,
        FormulaLocale.forId(locale),
      );

  group(
    'Given the vectors where the former TEXT() agreed with the display',
    () {
      final rows = [
        for (final line in File(
          'test/fixtures/text_format_vectors.tsv',
        ).readAsLinesSync())
          if (line.isNotEmpty && !line.startsWith('#')) line.split('\t'),
      ];

      test('when formatting each with TEXT() then the output is unchanged', () {
        final failures = <String>[];
        for (final [locale, pattern, value, expected] in rows) {
          final v = value.startsWith('text:')
              ? value.substring(5)
              : double.parse(value);
          final actual = text(v, pattern, locale);
          if (actual != expected) {
            failures.add('$locale "$pattern" $value: "$actual" != "$expected"');
          }
        }

        expect(rows, hasLength(3375));
        expect(failures, isEmpty);
      });
    },
  );

  group('Given values where TEXT() now matches the cell display', () {
    final cases = <(String, String, Object, String)>[
      (
        'a negative number rounding to zero keeps its sign',
        '0.00',
        -0.0001,
        '-0.00',
      ),
      ('a fraction keeps its alignment padding', '# ?/?', 0.3333, ' 1/3'),
      ('a whole number in a fraction format is padded', '# ?/?', 1.0, '1    '),
      (
        'the else section of a conditional format adds the minus sign',
        '[>100]"big";"small"',
        -1.0,
        '-small',
      ),
      ('scaled negatives keep their sign', '0.00,,"M"', -1.5, '-0.00M'),
      ('a large serial formats as a time', 'h:mm AM/PM', 1e9, '12:00 AM'),
      (
        'an elapsed format counts past the date range',
        '[h]:mm',
        12345678.0,
        '296296272:00',
      ),
    ];
    for (final (name, pattern, value, expected) in cases) {
      test('when formatting: $name', () {
        expect(text(value, pattern), expected);
        expect(
          NumberPatternFormatter.instance
              .formatNumber(value as double, pattern)
              .plainText,
          expected,
        );
      });
    }

    test(
      'when formatting a German date then the CLDR abbreviation is used',
      () {
        expect(text(45000.75, 'd-mmm', 'de_DE'), '15-März');
        expect(text(0.0, 'ddd', 'de_DE'), 'Sa.');
      },
    );

    test('when formatting AM/PM in en_GB then the pattern case is kept', () {
      expect(text(0.5, 'h AM/PM', 'en_GB'), '12 PM');
    });
  });

  group('Given special patterns', () {
    test('when the pattern is invalid then TEXT() has no result', () {
      expect(text(1.5, 'invalid['), isNull);
      expect(text(1.5, '"unterminated'), isNull);
      expect(text(1.5, '[Red'), isNull);
    });

    test('when the pattern is an internal preset id then it is invalid', () {
      expect(text(1.5, 'preset:currency'), isNull);
    });

    test('when the pattern is empty then numbers give "" and text stays', () {
      expect(text(1.5, ''), '');
      expect(text('abc', ''), 'abc');
    });

    test('when formatting a boolean then it is TRUE or FALSE', () {
      expect(
        formatter.format(FBool.t, '0.00', FormulaLocale.forId('en_US')),
        'TRUE',
      );
    });

    test(
      'when formatting with TEXT() in a formula then the display is used',
      () {
        final t = FormulaTestBench();
        t.set('A1', '=TEXT(-0.0001, "0.00")');

        expect(t.value('A1'), const FText('-0.00'));
      },
    );
  });
}
