import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/model.dart';

void main() {
  const row = '0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5b';
  const col = '0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5c';
  const sheet = '0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5d';
  const other = '0190a1b2-c3d4-7e5f-8a9b-0c1d2e3f4a5e';
  final cell = RefToken(rowId: row, colId: col).encode();
  final range =
      '${RefToken(rowId: row, colId: col, rowKey: 'a0', colKey: 'a0').encode()}:'
      '${RefToken(rowId: other, colId: col, rowKey: 'a1', colKey: 'a0').encode()}';
  final onSheet = RefToken(sheetId: sheet, rowId: other, colId: other).encode();

  group('Given stored formulas and the encoded ids of a structural edit', () {
    for (final (formula, ids, expected) in [
      ('=$cell+1', {row}, true),
      ('=$cell+1', {col}, true),
      ('=SUM($range)', {other}, true),
      ('=$onSheet', {sheet}, true),
      ('=$onSheet', {row}, false),
      ('=1+2', {row}, false),
      ('="${Base62Uuid.toToken(row)}"&$onSheet', {row}, false),
      ('=$cell', <String>{}, false),
      ('=$cell', {'r1', 'r2'}, false),
    ]) {
      test('when checking $formula against $ids then it is $expected', () {
        expect(
          StoredFormula.referencesAny(formula, StoredFormula.idTokens(ids)),
          expected,
        );
        // The convenience form agrees.
        expect(StoredFormula.mayReference(formula, ids), expected);
      });
    }

    test('when many ids are checked then a match among them is found', () {
      final many = {
        for (var i = 0; i < 20; i++)
          '0190a1b2-c3d4-7e5f-8a9b-${i.toRadixString(16).padLeft(12, '0')}',
      };

      expect(
        StoredFormula.referencesAny('=$cell', StoredFormula.idTokens(many)),
        isFalse,
      );
      expect(
        StoredFormula.referencesAny(
          '=$cell',
          StoredFormula.idTokens({...many, row}),
        ),
        isTrue,
      );
    });

    test('when ids are not UUIDs then they match verbatim', () {
      final f = '=${const RefToken(rowId: 'r1', colId: 'c10').encode()}';

      expect(StoredFormula.referencesAny(f, {'c1'}), isFalse);
      expect(StoredFormula.referencesAny(f, {'c10'}), isTrue);
    });
  });
}
