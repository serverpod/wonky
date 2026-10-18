import 'package:test/test.dart';
import 'package:wonky_sheets_core/src/data_tools/data_tools.dart';
import 'package:wonky_sheets_core/src/formula/values/collation.dart';

import '../../rules/support/core.dart';
import '../../rules/support/rule_fixtures.dart';

void main() {
  group('Given the sort ordering of 07 §2.3', () {
    NumberValue n(double x) => NumberValue(x);
    const t = TextValue.new;
    final mixed = <CellValue>[
      t('cherry'),
      CellValue.empty,
      const BoolValue(true),
      n(10),
      const ErrorValue(CellErrorKind.na),
      t('Banana'),
      n(-1),
      const BoolValue(false),
      t(''),
      t('apple'),
      const ErrorValue(CellErrorKind.div0),
    ];

    List<CellValue> sorted(bool asc) {
      final col = SortKeyColumn.fromValues(mixed);
      final perm = SortPermutation.compute(
        SortTable(mixed.length, {'c': col}),
        [ValueSortSpec('c', ascending: asc)],
      );
      return [for (final i in perm) mixed[i]];
    }

    test(
      'when sorting ascending then numbers < text (case-insensitive) < booleans < errors < blanks',
      () {
        expect(sorted(true), [
          n(-1),
          n(10),
          t('apple'),
          t('Banana'),
          t('cherry'),
          const BoolValue(false),
          const BoolValue(true),
          const ErrorValue(CellErrorKind.div0),
          const ErrorValue(CellErrorKind.na),
          CellValue.empty,
          t(''),
        ]);
      },
    );

    test(
      'when sorting descending then groups reverse but blanks stay last',
      () {
        expect(sorted(false), [
          const ErrorValue(CellErrorKind.na),
          const ErrorValue(CellErrorKind.div0),
          const BoolValue(true),
          const BoolValue(false),
          t('cherry'),
          t('Banana'),
          t('apple'),
          n(10),
          n(-1),
          CellValue.empty,
          t(''),
        ]);
      },
    );

    final textVectors = <(String, String, int)>[
      ('apple', 'Banana', -1),
      ('é', 'f', -1),
      ('e', 'é', -1),
      ('Ä', 'b', -1),
      ('straße', 'strasse', 1),
      ('a10', 'a9', -1),
      ('ABC', 'abc', -1),
      ('ｂ', 'c', -1),
    ];
    for (final (a, b, sign) in textVectors) {
      test('when comparing "$a" with "$b" then the sign is $sign', () {
        expect(Collation.compare(a, b).sign, sign);
        expect(SortKeys.compare(TextValue(a), TextValue(b)).sign, sign);
      });
    }

    test('when keys tie then the original order is kept (stable)', () {
      final vals = [n(1), n(0), n(1), n(0), n(1)];
      final perm = SortPermutation.compute(
        SortTable(5, {'c': SortKeyColumn.fromValues(vals)}),
        [const ValueSortSpec('c')],
      );
      expect(perm, [1, 3, 0, 2, 4]);
    });

    test(
      'when sorting by two keys then the second breaks ties of the first',
      () {
        final a = [t('x'), t('y'), t('x'), t('y')];
        final b = [n(2), n(1), n(1), n(0)];
        final perm = SortPermutation.compute(
          SortTable(4, {
            'a': SortKeyColumn.fromValues(a),
            'b': SortKeyColumn.fromValues(b),
          }),
          [
            const ValueSortSpec('a'),
            const ValueSortSpec('b', ascending: false),
          ],
        );
        expect(perm, [0, 2, 1, 3]);
      },
    );

    test('when sorting by fill color then rows with the color come first', () {
      final perm = SortPermutation.compute(
        SortTable(
          4,
          const {},
          fills: {
            'c': ['#ff0000', null, '#FF0000', '#00FF00'],
          },
        ),
        [const ColorSortSpec('c', fillColor: '#FF0000')],
      );
      expect(perm, [0, 2, 1, 3]);
    });

    test('when sorting many rows then the merge passes stay stable', () {
      final vals = [
        for (var i = 0; i < 1000; i++) n((i * 7919 % 13).toDouble()),
      ];
      final perm = SortPermutation.compute(
        SortTable(1000, {'c': SortKeyColumn.fromValues(vals)}),
        [const ValueSortSpec('c')],
      );
      for (var i = 1; i < perm.length; i++) {
        final a = vals[perm[i - 1]], b = vals[perm[i]];
        expect(
          a.number < b.number ||
              (a.number == b.number && perm[i - 1] < perm[i]),
          isTrue,
        );
      }
    });

    test('when cancelled then the sort throws DataJobCancelled', () {
      final vals = [for (var i = 0; i < 100; i++) n(-i.toDouble())];
      expect(
        () => SortPermutation.compute(
          SortTable(100, {'c': SortKeyColumn.fromValues(vals)}),
          [const ValueSortSpec('c')],
          isCancelled: () => true,
        ),
        throwsA(isA<DataJobCancelled>()),
      );
    });

    test('when inverting a permutation then composition is the identity', () {
      final p = SortPermutation.compute(
        SortTable(3, {
          'c': SortKeyColumn.fromValues([n(3), n(1), n(2)]),
        }),
        [const ValueSortSpec('c')],
      );
      final inv = SortPermutation.inverse(p);
      expect([for (var i = 0; i < 3; i++) inv[p[i]]], [0, 1, 2]);
    });
  });

  group('Given sort JSON', () {
    test('when round-tripping value and color specs then JSON is preserved', () {
      const json =
          '[{"colId":"a","ascending":false},{"colId":"b","fillColor":"#FF0000"}]';
      final specs = SortSpec.parseList(json);
      expect(specs, [
        const ValueSortSpec('a', ascending: false),
        const ColorSortSpec('b', fillColor: '#FF0000'),
      ]);
      expect(SortSpec.encodeList(specs), json);
      expect(SortSpec.parseList('nope'), isEmpty);
    });
  });

  group('Given a sheet to sort', () {
    late WorkbookBuilder b;
    late String sid;
    setUp(() {
      b = WorkbookBuilder();
      sid = b.sheet('Sheet1', rows: 10, cols: 4);
      b.values('A1', [
        ['Name', 'Score'],
        ['b', 2],
        ['a', 1],
      ]);
    });

    test(
      'when building a snapshot from the sheet then the key column is read from computed values',
      () {
        final m = b.build();
        final s = m.sheets.single;
        final table = SortTable.fromSheet(
          s,
          ModelCellSource(m),
          const GridRect(1, 0, 2, 1),
          [ValueSortSpec(b.colId(1))],
        );
        expect(SortPermutation.compute(table, [ValueSortSpec(b.colId(1))]), [
          1,
          0,
        ]);
      },
    );

    test(
      'when the first row is text over numbers then it looks like a header',
      () {
        final m = b.build();
        final src = ModelCellSource(m);
        expect(
          HeaderDetector.looksLikeHeader(
            (r, c) => src.cellValueAt(sid, r, c),
            const GridRect(0, 0, 2, 1),
          ),
          isTrue,
        );
        expect(
          HeaderDetector.looksLikeHeader(
            (r, c) => src.cellValueAt(sid, r, c),
            const GridRect(1, 0, 2, 0),
          ),
          isFalse,
        );
      },
    );

    test(
      'when the rows have cells outside the range then content move is chosen',
      () {
        final m = b.build();
        final s = m.sheets.single;
        expect(
          SortStrategy.choose(s, const GridRect(1, 0, 2, 3)),
          SortStrategyKind.rowReorder,
        );
        expect(
          SortStrategy.choose(s, const GridRect(1, 0, 2, 1)),
          SortStrategyKind.rowReorder,
        );
        expect(
          SortStrategy.choose(s, const GridRect(1, 1, 2, 1)),
          SortStrategyKind.contentMove,
        );
      },
    );

    test(
      'when the range has a vertical merge then sorting is refused with the documented message',
      () {
        b.row(SheetsTables.mergedRange, fid(1), {
          Cols.sheetId: sid,
          Cols.rangeJson: gridRange(b, sid, 1, 2, 2, 2).encode(),
        });
        final s = b.build().sheets.single;
        expect(
          SortStrategy.choose(s, const GridRect(1, 0, 2, 3)),
          SortStrategyKind.contentMove,
        );
        expect(
          SortStrategy.refusal(s, const GridRect(1, 0, 2, 3))!.message,
          "Can't sort a range with vertically merged cells",
        );
      },
    );

    test(
      'when a vertical merge outside the range spans the rows then content move is chosen',
      () {
        b.row(SheetsTables.mergedRange, fid(3), {
          Cols.sheetId: sid,
          Cols.rangeJson: gridRange(b, sid, 1, 3, 2, 3).encode(),
        });
        final s = b.build().sheets.single;
        expect(
          SortStrategy.choose(s, const GridRect(1, 0, 2, 1)),
          SortStrategyKind.contentMove,
        );
        expect(SortStrategy.refusal(s, const GridRect(1, 0, 2, 1)), isNull);
      },
    );

    test(
      'when a single-row merge sits in the rows then rows can still be reordered',
      () {
        b.row(SheetsTables.mergedRange, fid(4), {
          Cols.sheetId: sid,
          Cols.rangeJson: gridRange(b, sid, 1, 0, 1, 1).encode(),
        });
        final s = b.build().sheets.single;
        expect(
          SortStrategy.choose(s, const GridRect(1, 0, 2, 1)),
          SortStrategyKind.rowReorder,
        );
      },
    );

    test('when the range contains overlay output then sorting is refused', () {
      final s = b.build().sheets.single;
      expect(
        SortStrategy.refusal(
          s,
          const GridRect(1, 0, 2, 1),
          hasOverlay: (_) => true,
        )!.kind,
        SortRefusalKind.overlay,
      );
      expect(SortStrategy.refusal(s, const GridRect(1, 0, 2, 1)), isNull);
    });

    test(
      'when the range has protected cells the user can\'t edit then sorting is refused',
      () {
        b.row(SheetsTables.protectedRange, fid(2), {
          Cols.sheetId: sid,
          Cols.rangeJson: gridRange(b, sid, 2, 1, 2, 1).encode(),
          'editorsJson': '[]',
          Cols.createdBy: 'owner',
        });
        final m = b.build();
        final r = SortStrategy.refusal(
          m.sheets.single,
          const GridRect(1, 0, 2, 1),
          guard: ProtectionGuard(m),
          userId: 'editor',
        );
        expect(r!.kind, SortRefusalKind.protected);
      },
    );
  });
}
