import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';
import 'package:wonky_sheets_core/src/content/cell_content.dart';
import 'package:wonky_sheets_core/src/data_tools/data_tools.dart';

import 'support/legacy_sort_collation.dart';

/// CQ-50: `SORT()` used its own collation (a small accent table), Data ›
/// Sort a larger one; both now use [Collation]. This pins the merge: on
/// strings the old `SORT()` table covers, the keys are unchanged; outside it
/// (ligatures, combining marks, fullwidth forms) `SORT()` now orders like
/// Data › Sort.
void main() {
  group('Given strings within the former SORT() collation table', () {
    const ascii =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_.,/';
    final alphabet = [
      ...ascii.split(''),
      ...legacyFoldedCharacters.split(''),
      ...legacyFoldedCharacters.toUpperCase().split(''),
    ];

    for (final seed in [1, 7, 42, 1234, 98765]) {
      test('when computing keys (seed $seed) then the shared collation gives '
          'the former SORT() key', () {
        final random = Random(seed);
        for (var run = 0; run < 500; run++) {
          final s = [
            for (var i = random.nextInt(12); i >= 0; i--)
              alphabet[random.nextInt(alphabet.length)],
          ].join();

          expect(Collation.key(s), legacySortCollationKey(s), reason: s);
        }
      });
    }
  });

  group('Given text the former SORT() collation did not fold', () {
    const values = ['æb', 'af', 'Ab', 'ab', 'ß', 'ss', 'st', 'Ölz', 'Oz'];

    test('when sorting with SORT() then the order equals Data › Sort', () {
      final t = FormulaTestBench();
      t.setColumn('A1', values);
      t.set('B1', '=SORT(A1:A9)');

      final sorted = [for (var r = 1; r <= 9; r++) t.value('B$r')];
      final expected = [...values]
        ..sort((a, b) => SortKeys.compare(TextValue(a), TextValue(b)));

      expect(sorted, [for (final v in expected) FText(v)]);
      expect(expected.take(4), ['Ab', 'ab', 'æb', 'af']);
    });
  });
}
