import 'package:test/test.dart';
import 'package:wonky_revlog/apply.dart';
import 'package:wonky_revlog/codec.dart';
import 'package:wonky_revlog/schema.dart';
import 'package:wonky_sheets_core/formula.dart' show GridRect;
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';
import 'package:wonky_sheets_core/revlog.dart';

import '../support/planner_harness.dart';

/// Schema guard (RevLog spec 02 §4, 10 R1): the RevLog schema generated from
/// the `.spy.yaml` models matches what the Sheets model and planner write.
void main() {
  group('Given the Sheets RevLog schema', () {
    test(
      'when compared with the model tables then every synced table is in it',
      () {
        final expected = SheetsTables.dependencyOrder.toSet()
          ..remove(SheetsTables.changeLog);
        expect(sheetsSchema.tables.map((t) => t.name).toSet(), expected);
        expect(sheetsSchema.root.name, SheetsTables.spreadsheet);
      },
    );

    test('when walking parents then every parent exists and ranks lower', () {
      for (final t in sheetsSchema.tables) {
        for (final p in t.parents) {
          final parent = sheetsSchema.tryTable(p.table);
          expect(parent, isNotNull, reason: '${t.name}.${p.column}');
          expect(
            sheetsSchema.rank(p.table),
            lessThan(sheetsSchema.rank(t.name)),
            reason: '${t.name} → ${p.table}',
          );
          expect(
            t.column(p.column),
            isNotNull,
            reason: '${t.name}.${p.column}',
          );
        }
      }
    });

    test('when reading cells then ids are deterministic and loaded by row', () {
      final cell = sheetsSchema.table(SheetsTables.cell);
      expect(cell.deterministicIds, isTrue);
      expect(cell.coverage, RevCoverage.cellsByRow);
      expect(
        sheetsSchema.table(SheetsTables.scriptBuild).clientWritable,
        isFalse,
      );
    });

    test('when hashed twice then the hash is stable', () {
      expect(RevSchema('sheets', sheetsSchema.tables).hash, sheetsSchema.hash);
    });
  });

  group('Given planner output', () {
    late PlannerHarness h;
    setUp(() {
      h = PlannerHarness(
        WorkbookBuilder()
          ..sheet('Sheet1', rows: 20, cols: 6)
          ..values('A1', [
            ['Name', 'Qty'],
            ['Apple', 3],
            ['Pear', 5],
          ]),
      );
    });

    void validates(SheetsOperation op) {
      final plan = h.plan(op);
      final cs = ChangeSet(
        clientOpId: '0190f0b0-0000-7000-8000-0000000000aa',
        baseRevision: 1,
        changes: plan.changes,
      );
      expect(
        () => validateChangeSet(
          sheetsSchema,
          cs,
          fromClient: true,
          isCreation: false,
          fileUuid: h.model.spreadsheetId,
        ),
        returnsNormally,
        reason: '$op',
      );
      // And the codec carries every change.
      final codec = RevCodec(sheetsSchema);
      expect(
        codec.decodeText(codec.encodeText(plan.changes)).changes,
        plan.changes,
      );
      h.model.applyPlan(plan);
    }

    test('when creating a spreadsheet then the creation op is valid', () {
      final m = WorkbookModel(
        spreadsheetId: '00000000-0000-4000-8000-00000000aaaa',
      );
      final plan = const SheetsMutationPlanner().plan(
        const CreateSpreadsheet(
          spreadsheetId: '00000000-0000-4000-8000-00000000aaaa',
          rows: 5,
          columns: 3,
        ),
        m,
        h.ctx,
      );
      expect(
        () => validateChangeSet(
          sheetsSchema,
          ChangeSet(
            clientOpId: '0190f0b0-0000-7000-8000-0000000000ab',
            baseRevision: 0,
            changes: plan.changes,
          ),
          fromClient: true,
          isCreation: true,
          fileUuid: '00000000-0000-4000-8000-00000000aaaa',
        ),
        returnsNormally,
      );
    });

    test('when running common operations then every plan is valid', () {
      final s = h.sheetId;
      validates(
        SetCellInputs(
          sheetId: s,
          row: 3,
          col: 0,
          inputs: [
            [const CellInput.user('Plum'), const CellInput.user('=SUM(B2:B3)')],
          ],
        ),
      );
      validates(SetFormat([h.range('A1:B1')], {FormatAttr.bold: true}));
      validates(MergeCells([h.range('D1:E2')]));
      validates(InsertDimension(s, Dimension.rows, 2, 2));
      validates(
        DeleteDimension(s, Dimension.rows, [h.model.sheet(s)!.rows.idAt(2)]),
      );
      validates(
        AddCfRule(
          s,
          [h.range('B2:B5').rect],
          '{"v":1,"type":"boolean","condition":{"type":"numberGreater","values":[{"v":"3"}]}}',
        ),
      );
      validates(
        SetDataValidation(s, [
          const GridRect(1, 2, 5, 2),
        ], '{"type":"checkbox"}'),
      );
      validates(SetBasicFilter(s, const GridRect(0, 0, 4, 1)));
      validates(AddNamedRange('Fruit', range: h.range('A2:A4')));
      validates(
        AddProtection(
          s,
          range: const GridRect(0, 0, 0, 1),
          description: 'Header',
        ),
      );
      validates(
        AddBanding(
          s,
          const GridRect(0, 0, 4, 1),
          const BandingStyle().toJson(),
        ),
      );
      validates(const AddSheet(name: 'Notes', rows: 5, columns: 3));
      validates(
        SortRange(h.range('A1:B5'), [
          SortKeySpec(h.model.sheet(s)!.columns.idAt(0)),
        ], hasHeader: true),
      );
      validates(DeleteSheet(h.model.sheets.last.id));
    });
  });
}
