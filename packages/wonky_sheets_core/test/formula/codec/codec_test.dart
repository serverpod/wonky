import 'package:test/test.dart';
import 'package:wonky_sheets_core/formula.dart';
import 'package:wonky_sheets_core/formula_testing.dart';

void main() {
  late MemoryWorkbook wb;
  late MemorySheet s1, s2;
  CodecContext ctx({
    int row = 0,
    int col = 0,
    String sheet = 'Sheet1',
    String locale = 'en_US',
  }) => CodecContext(
    workbook: wb,
    hostSheetId: wb.sheetByName(sheet)!.id,
    hostRow: row,
    hostCol: col,
    locale: FormulaLocale.forId(locale),
  );

  setUp(() {
    wb = MemoryWorkbook();
    s1 = wb.addSheet('Sheet1', rows: 1000, cols: 26);
    s2 = wb.addSheet('Q3 plan', rows: 100, cols: 10);
  });

  group('Given A1 formulas', () {
    final cases = <(String, String)>[
      ('=sum(a1:a3)', '=SUM(A1:A3)'),
      ('=A1+\$B\$2*B\$3-\$C4', r'=A1+$B$2*B$3-$C4'),
      ('=SUM(A:A, 1:1, A2:B, B3:5)', '=SUM(A:A, 1:1, A2:B, B3:5)'),
      ("='q3 PLAN'!A1+'Q3 plan'!B2:C3", "='Q3 plan'!A1+'Q3 plan'!B2:C3"),
      ('=Sheet1!A1', '=A1'),
      ('=true+false', '=TRUE+FALSE'),
      ('=IF(A1 > 1,\n  "yes",  "no")', '=IF(A1 > 1,\n  "yes",  "no")'),
      ('="A1 is text"&A1', '="A1 is text"&A1'),
      ('={1,2;3,4}', '={1,2;3,4}'),
      ('=#ref!+1', '=#REF!+1'),
      ('=Unknown!A1', '=Unknown!A1'),
      ('=A5000', '=A5000'),
      ('=myName*2', '=myName*2'),
    ];
    for (final (a1, normal) in cases) {
      test(
        'when converting "$a1" to stored and back then it reads "$normal"',
        () {
          final stored = FormulaCodec.toStored(a1, ctx());
          expect(FormulaCodec.toA1(stored, ctx()), normal);
        },
      );
    }

    test(
      'when a formula is stored then it contains id tokens only (no A1 text)',
      () {
        final stored = FormulaCodec.toStored('=SUM(A1:A3)+B7', ctx());
        expect(stored, isNot(contains('A1')));
        expect(stored, contains('⟦R:'));
        expect(FormulaCodec.references(stored), hasLength(2));
      },
    );

    test(
      'when a range is stored then its endpoints carry sort keys and the second omits S:',
      () {
        final stored = FormulaCodec.toStored("='Q3 plan'!B2:B10", ctx());
        final ref = FormulaCodec.references(stored).single;
        expect(ref.start.sheetId, s2.id);
        expect(ref.end!.sheetId, isNull);
        expect(ref.start.rowKey, isNotNull);
        expect(ref.end!.colKey, isNotNull);
      },
    );

    test(
      'when the sheet is unknown then an unbound X: token keeps the text',
      () {
        final stored = FormulaCodec.toStored("='Budget 2027'!A1", ctx());
        final ref = FormulaCodec.references(stored).single;
        expect(ref.start.unbound, "'Budget 2027'!A1");
      },
    );

    test(
      'when the reference is beyond the grid then it is unbound until the grid grows',
      () {
        final stored = FormulaCodec.toStored('=A5000', ctx());
        expect(FormulaCodec.references(stored).single.start.unbound, 'A5000');
      },
    );
  });

  group('Given a de_DE spreadsheet', () {
    test('when typing locale separators then the stored form is canonical', () {
      final stored = FormulaCodec.toStored(
        '=ROUND(1,5;0)',
        ctx(locale: 'de_DE'),
      );
      expect(stored, '=ROUND(1.5,0)');
      expect(FormulaCodec.toA1(stored, ctx(locale: 'de_DE')), '=ROUND(1,5;0)');
      expect(FormulaCodec.toA1(stored, ctx()), '=ROUND(1.5,0)');
    });
    test(
      r'when typing an array with \ column separators then they become commas',
      () {
        expect(
          FormulaCodec.toStored(r'={1\2;3\4}', ctx(locale: 'de_DE')),
          '={1,2;3,4}',
        );
      },
    );
  });

  group('Given structural changes', () {
    test(
      'when inserting a row inside a range then the A1 form grows without rewriting',
      () {
        final stored = FormulaCodec.toStored('=SUM(A1:A3)', ctx(row: 9));
        s1.rows.insert(1, 1);
        expect(FormulaCodec.toA1(stored, ctx(row: 10)), '=SUM(A1:A4)');
      },
    );
    test('when deleting the range end row then the range shrinks', () {
      final stored = FormulaCodec.toStored('=SUM(A1:A3)', ctx(row: 9));
      s1.rows.delete(2, 1);
      expect(FormulaCodec.toA1(stored, ctx(row: 8)), '=SUM(A1:A2)');
    });
    test('when deleting a single referenced row then it renders #REF!', () {
      final stored = FormulaCodec.toStored('=A3+1', ctx(row: 9));
      s1.rows.delete(2, 1);
      expect(FormulaCodec.toA1(stored, ctx(row: 8)), '=#REF!+1');
    });
    test(
      'when renaming a sheet then the display follows without rewriting',
      () {
        final stored = FormulaCodec.toStored("='Q3 plan'!A1", ctx());
        s2.name = 'Plan';
        expect(FormulaCodec.toA1(stored, ctx()), '=Plan!A1');
      },
    );
    test('when deleting a sheet then its references render #REF!', () {
      final stored = FormulaCodec.toStored("='Q3 plan'!A1", ctx());
      wb.removeSheet(s2.id);
      expect(FormulaCodec.toA1(stored, ctx()), '=#REF!');
    });
  });

  group('Given copy and fill (translate)', () {
    test(
      r'when filling down then relative parts shift and absolute parts stay',
      () {
        final stored = FormulaCodec.toStored(
          r'=A1+$B$1+B$1+$C1',
          ctx(row: 0, col: 3),
        );
        final moved = FormulaCodec.translate(
          stored,
          const CellPos(0, 3),
          const CellPos(4, 4),
          wb,
          fromSheetId: s1.id,
        );
        expect(
          FormulaCodec.toA1(moved, ctx(row: 4, col: 4)),
          r'=B5+$B$1+C$1+$C5',
        );
      },
    );
    test('when shifting out of the grid then the reference becomes #REF!', () {
      final stored = FormulaCodec.toStored('=A2', ctx(row: 1));
      final moved = FormulaCodec.translate(
        stored,
        const CellPos(1, 0),
        const CellPos(0, 0),
        wb,
        fromSheetId: s1.id,
      );
      expect(
        FormulaCodec.toA1(
          FormulaCodec.translate(
            moved,
            const CellPos(0, 0),
            const CellPos(0, 0),
            wb,
            fromSheetId: s1.id,
          ),
          ctx(),
        ),
        '=A1',
      );
      final out = FormulaCodec.translate(
        stored,
        const CellPos(1, 0),
        const CellPos(-1 + 0, 0),
        wb,
        fromSheetId: s1.id,
      );
      expect(FormulaCodec.toA1(out, ctx()), '=#REF!');
    });
    test(
      'when pasting to another sheet then same-sheet references re-resolve there by index',
      () {
        final stored = FormulaCodec.toStored('=B2', ctx());
        final moved = FormulaCodec.translate(
          stored,
          const CellPos(0, 0),
          const CellPos(0, 0),
          wb,
          fromSheetId: s1.id,
          toSheetId: s2.id,
        );
        expect(
          FormulaCodec.references(moved).single.start.rowId,
          s2.rows.idAt(1),
        );
      },
    );
  });

  group('Given R1C1', () {
    test(
      'when rendering stored refs as R1C1 then offsets are relative to the host',
      () {
        final stored = FormulaCodec.toStored(r'=A1+$B$2', ctx(row: 2, col: 2));
        expect(
          FormulaCodec.toR1C1(stored, ctx(row: 2, col: 2)),
          '=R[-2]C[-2]+R2C2',
        );
      },
    );
    test('when converting R1C1 input then it becomes stored references', () {
      final stored = FormulaCodec.fromR1C1(
        '=SUM(R[-2]C:R[-1]C)',
        ctx(row: 2, col: 0),
      );
      expect(FormulaCodec.toA1(stored, ctx(row: 2, col: 0)), '=SUM(A1:A2)');
    });
  });

  group('Given reference rewrites', () {
    test('when renaming a named range then only name tokens change', () {
      expect(
        ReferenceRewriter.renameName(
          '=SUM(Sales)+"Sales"+sales',
          'SALES',
          'Revenue',
        ),
        '=SUM(Revenue)+"Sales"+Revenue',
      );
      expect(ReferenceRewriter.renameName('=A1', 'Sales', 'X'), isNull);
    });
    test(
      'when cutting a block then references fully inside follow it and partial ranges stay',
      () {
        final stored = FormulaCodec.toStored(
          '=A1+SUM(A1:A2)+SUM(A1:A5)',
          ctx(row: 9, col: 5),
        );
        final out = ReferenceRewriter.remap(
          stored,
          workbook: wb,
          hostSheetId: s1.id,
          sourceSheetId: s1.id,
          source: const GridRect(0, 0, 1, 0),
          destSheetId: s1.id,
          dest: const GridRect(4, 2, 5, 2),
        );
        expect(
          FormulaCodec.toA1(out!, ctx(row: 9, col: 5)),
          '=C5+SUM(C5:C6)+SUM(A1:A5)',
        );
      },
    );
    test(
      'when repairing boundaries before a delete then endpoints move inward',
      () {
        final stored = FormulaCodec.toStored('=SUM(A2:A5)+A3', ctx(row: 9));
        final deleted = {s1.rows.idAt(1), s1.rows.idAt(2)};
        final out = ReferenceRewriter.repairBoundaries(
          stored,
          workbook: wb,
          deletedRowIds: deleted,
          deletedColIds: const {},
          hostSheetId: s1.id,
        );
        expect(FormulaCodec.toA1(out!, ctx(row: 9)), '=SUM(A4:A5)+#REF!');
      },
    );
    test(
      'when all rows of a range are deleted then the range becomes #REF!',
      () {
        final stored = FormulaCodec.toStored('=SUM(A2:A3)', ctx(row: 9));
        final out = ReferenceRewriter.repairBoundaries(
          stored,
          workbook: wb,
          deletedRowIds: {s1.rows.idAt(1), s1.rows.idAt(2)},
          deletedColIds: const {},
          hostSheetId: s1.id,
        );
        expect(out, '=SUM(#REF!)');
      },
    );
    test(
      'when repinning a sorted block then references keep pointing at positions',
      () {
        final stored = FormulaCodec.toStored('=A2', ctx(row: 9));
        final before = [for (var i = 0; i < 4; i++) s1.rows.idAt(i)];
        s1.rows.permute([0, 3, 2, 1, for (var i = 4; i < 1000; i++) i]);
        final out = ReferenceRewriter.repinRows(
          stored,
          workbook: wb,
          hostSheetId: s1.id,
          sheetId: s1.id,
          blockTop: 1,
          blockBottom: 3,
          newRowIdAt: s1.rows.idAt,
          oldIndexOf: before.indexOf,
        );
        expect(FormulaCodec.toA1(out!, ctx(row: 9)), '=A2');
      },
    );
    test(
      'when testing whether a formula references a rectangle then ranges count',
      () {
        final stored = FormulaCodec.toStored('=SUM(B1:B10)', ctx());
        expect(
          ReferenceRewriter.references(
            stored,
            workbook: wb,
            hostSheetId: s1.id,
            sheetId: s1.id,
            rect: const GridRect(4, 1, 4, 1),
          ),
          isTrue,
        );
        expect(
          ReferenceRewriter.references(
            stored,
            workbook: wb,
            hostSheetId: s1.id,
            sheetId: s1.id,
            rect: const GridRect(4, 2, 4, 2),
          ),
          isFalse,
        );
      },
    );
  });

  group('Given reference tokens', () {
    test('when encoding and decoding all fields then they round-trip', () {
      const t = RefToken(
        sheetId: 's',
        rowId: 'r',
        colId: 'c',
        absRow: true,
        absCol: true,
        rowKey: 'a0',
        colKey: 'b1',
      );
      expect(RefToken.decode(t.encode()), t);
      const u = RefToken(unbound: "'A;B⟧'!A1");
      expect(RefToken.decode(u.encode()), u);
    });
    test('when decoding malformed tokens then null is returned', () {
      expect(RefToken.decode('⟦Q:1⟧'), isNull);
      expect(RefToken.decode('⟦⟧'), isNull);
    });
  });
}
