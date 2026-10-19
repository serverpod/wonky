import 'package:test/test.dart';
import 'package:wonky_revlog/rows.dart';

void main() {
  group('Given a plan of 12,001 changes', () {
    final plan = MutationPlan(
      label: 'Import',
      summary: JsonChangeSummary({
        'kinds': ['import'],
      }),
      changes: [
        for (var i = 0; i < 12001; i++)
          RowChange.insert('element', 'e$i', {'n': i}),
      ],
      detail: {'cells': <Object?>[]},
    );

    test('when chunked then the writer transactions hold at most 5,000 '
        'changes each', () {
      expect(plan.chunks.map((c) => c.length), [5000, 5000, 2001]);
    });

    test('when inverted then the changes are reversed and inverted', () {
      final inverse = plan.inverse(label: 'Undo import');
      expect(inverse.label, 'Undo import');
      expect(inverse.changes.first.rowId, 'e12000');
      expect(inverse.changes.first.op, RowOp.delete);
      expect(inverse.summary, same(plan.summary));
    });

    test('when reading the change-log strings then they are JSON', () {
      expect(plan.summaryJson, '{"kinds":["import"]}');
      expect(plan.detailJson, '{"cells":[]}');
    });
  });
}
