import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/status/selection_stats.dart';

import '../../support/sheets_harness.dart';

/// CQ-41 (S-03, S-05): the grid's render cache drops only what changed, the
/// border fast path is kept up to date from model batches, and the
/// selection stats never fill the render cache.
void main() {
  late SheetsHarness s;

  setUp(() => s = SheetsHarness.open());
  tearDown(() => s.dispose());

  (int, int) at(String a1) {
    final r = s.model.parseA1(a1, contextSheetId: s.sheetId);
    return (r.rect.top, r.rect.left);
  }

  bool cached(String a1) {
    final (r, c) = at(a1);
    return s.editor.cells.isCached(s.sheetId, r, c);
  }

  group('Given cached cells A1:C1 where C1 is =A1*2', () {
    setUp(() async {
      await s.type('A1', '1');
      await s.type('B1', 'x');
      await s.type('C1', '=A1*2');
      for (final a1 in ['A1', 'B1', 'C1']) {
        s.text(a1);
      }
    });

    test('when A1 is edited then A1 and the dependent C1 show the new '
        'values and B1 stays cached', () async {
      await s.type('A1', '5');

      expect(cached('B1'), isTrue);
      expect(s.text('A1'), '5');
      expect(s.text('C1'), '10');
    });

    test('when a spill grows into a cached empty cell then it shows the '
        'spilled value', () async {
      await s.type('D1', '=SEQUENCE(A1)');
      expect(s.text('D2'), '');

      await s.type('A1', '3');

      // Painted in reading order: the anchor first.
      expect(s.text('D1'), '1');
      expect(s.text('D2'), '2');
      expect(s.text('D3'), '3');
    });

    test('when a cell is formatted then the whole cache is dropped', () async {
      await s.select('A1');
      await s.run('sheets.format.borders', {'preset': 'all'});

      expect(cached('B1'), isFalse);
    });

    test('when the sheet has a conditional format rule and A1 is edited '
        'then the whole sheet is dropped', () async {
      await s.run('sheets.cf.addRule', {
        'ranges': ['B1:B2'],
        'rule': {
          'v': 1,
          'type': 'boolean',
          'condition': {
            'type': 'customFormula',
            'values': [
              {'v': r'=$A$1>3'},
            ],
          },
          'format': {'fillColor': '#FAD2CF'},
        },
      });
      s.text('B1');

      await s.type('A1', '5');

      expect(cached('B1'), isFalse);
    });
  });

  group('Given a sheet without borders', () {
    setUp(() async {
      await s.type('A1', '1');
    });

    test('when it is painted then the border fast path says no', () {
      expect(s.editor.cells.sheetHasBorders(s.sheetId), isFalse);
    });

    test('when a cell gets a border then the fast path says yes', () async {
      expect(s.editor.cells.sheetHasBorders(s.sheetId), isFalse);
      await s.select('B2');

      await s.run('sheets.format.borders', {'preset': 'all'});

      expect(s.editor.cells.sheetHasBorders(s.sheetId), isTrue);
    });
  });

  group('Given 12 numbers in A1:A12, two with a currency format', () {
    setUp(() async {
      for (var i = 1; i <= 12; i++) {
        await s.type('A$i', '$i');
      }
      await s.select('A11:A12');
      await s.run('sheets.format.numberFormat', {'pattern': r'$#,##0.00'});
      s.editor.cells.invalidate();
      await s.select('A1:A12');
    });

    test('when the stats are computed then the render cache stays empty', () {
      final stats = SelectionStats.of(s.editor);

      expect(stats.sum, 78);
      expect(stats.numberFormat, isNull);
      expect(s.editor.cells.cachedCount(s.sheetId), 0);
    });

    test('when they are computed in steps of 5 cells then the result equals '
        'the one-pass result', () {
      final acc = SelectionStatsAccumulator(s.editor);
      var steps = 1;
      while (!acc.step(5)) {
        steps++;
      }

      final whole = SelectionStats.of(s.editor);
      expect(steps, 3);
      expect(acc.result.sum, whole.sum);
      expect(acc.result.count, whole.count);
      expect(acc.result.min, whole.min);
      expect(acc.result.max, whole.max);
      expect(acc.result.numberFormat, whole.numberFormat);
    });

    test('when only the first ten are selected then their shared format is '
        'Automatic', () async {
      await s.select('A1:A10');

      expect(SelectionStats.of(s.editor).numberFormat, 'preset:automatic');
    });
  });
}
