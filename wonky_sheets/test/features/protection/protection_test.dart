import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_sheets/features/in_cell/cell_features.dart';
import 'package:wonky_sheets/features/protection/protection_controller.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../support/sheets_harness.dart';

const _other = '00000000-0000-7000-8000-0000000000bb';

/// Adds a protection created by another user (the harness user can't edit
/// it unless they own the file).
String protectAs(
  SheetsHarness s,
  String? a1, {
  bool warningOnly = false,
  List<String> except = const [],
  List<String> editors = const [],
}) {
  final sheet = s.sheet;
  final id = 'p-${sheet.protections.length + 1}';
  String json(String a) => sheet
      .gridRange(s.model.parseA1(a, contextSheetId: sheet.id).rect)
      .encode();
  s.session.applyChanges([
    RowChange.insert(SheetsTables.protectedRange, id, {
      Cols.sheetId: sheet.id,
      Cols.rangeJson: a1 == null ? null : json(a1),
      'exceptRangesJson': except.isEmpty
          ? null
          : '[${except.map(json).join(',')}]',
      'description': 'Totals',
      'warningOnly': warningOnly,
      'editorsJson': '[${editors.map((e) => '"$e"').join(',')}]',
      Cols.createdBy: _other,
    }),
  ], label: 'seed');
  return id;
}

void main() {
  late SheetsHarness s;

  Future<CommandResult> mcp(String id, Map<String, Object?> args) =>
      s.h.invoke(id, args, InvocationSource.mcp);

  group('Given an editor and a range F2:F40 protected by someone else', () {
    setUp(() {
      s = SheetsHarness.open(role: Role.editor);
      s.editor.itemRole = Role.editor;
      attachCellFeatures(s.editor);
      protectAs(s, 'F2:F40');
    });
    tearDown(() => s.dispose());

    test('when typing in F5 then nothing is written', () async {
      await s.type('F5', '42');

      expect(s.content('F5'), isNull);
      expect(s.h.undoLabels, isEmpty);
    });

    test('when the same write comes through MCP then it fails with '
        'protected_range', () async {
      final r = await mcp('sheets.cell.setInput', {'a1': 'F5', 'input': '1'});

      expect(r.status, CommandStatus.failed);
      expect(r.message, contains(kProtectedRangeErrorCode));
    });

    test('when typing outside the range then the value is written', () async {
      await s.type('E5', '42');

      expect(s.text('E5'), '42');
    });

    test('when entering a value for E4:F5 (overlapping F5) then the whole '
        'command is aborted', () async {
      await s.select('E4:F5');

      await s.run('sheets.cell.setInputForSelection', {'input': 'x'});

      expect(s.content('E4'), isNull);
      expect(s.content('F5'), isNull);
    });

    test('when bolding F3 then the format is blocked too', () async {
      await s.select('F3');

      await s.run('sheets.format.bold');

      expect(s.format('F3')[FormatAttr.bold], isNull);
    });

    test('when inserting a row inside the range then it is blocked, and '
        'above it is allowed', () async {
      final rows = s.sheet.rows.length;
      await s.select('A10');
      await s.run('sheets.rows.insertAbove');
      expect(s.sheet.rows.length, rows);

      await s.select('A1');
      await s.run('sheets.rows.insertAbove');
      expect(s.sheet.rows.length, rows + 1);
    });

    test('when deleting row 5 then it is blocked', () async {
      final rows = s.sheet.rows.length;
      await s.select('5:5');

      await s.run('sheets.rows.delete');

      expect(s.sheet.rows.length, rows);
    });

    test(
      'when removing the protection then it fails (not a manager)',
      () async {
        final id = s.sheet.protections.keys.single;

        final r = await s.run('sheets.protect.delete', {'id': id});

        expect(r.status, CommandStatus.failed);
        expect(s.sheet.protections, hasLength(1));
      },
    );

    test('when the cell query asks then F5 is not editable', () {
      final p = ProtectionController.of(s.editor);

      expect(p.canEditCell(s.sheetId, 4, 5), isFalse);
      expect(p.canEditCell(s.sheetId, 4, 4), isTrue);
    });
  });

  group('Given the owner and a range protected by someone else', () {
    setUp(() {
      s = SheetsHarness.open();
      attachCellFeatures(s.editor);
      protectAs(s, 'F2:F40');
    });
    tearDown(() => s.dispose());

    test('when typing in F5 then the owner may edit it', () async {
      await s.type('F5', '7');

      expect(s.text('F5'), '7');
    });
  });

  group('Given an editor listed as editor of the protection', () {
    setUp(() {
      s = SheetsHarness.open(role: Role.editor);
      s.editor.itemRole = Role.editor;
      attachCellFeatures(s.editor);
      protectAs(s, 'F2:F40', editors: [s.session.userId]);
    });
    tearDown(() => s.dispose());

    test('when typing in F5 then it is written', () async {
      await s.type('F5', '7');

      expect(s.text('F5'), '7');
    });
  });

  group('Given a warning-only protection', () {
    setUp(() {
      s = SheetsHarness.open(role: Role.editor);
      s.editor.itemRole = Role.editor;
      attachCellFeatures(s.editor);
      protectAs(s, 'B2:B5', warningOnly: true);
    });
    tearDown(() => s.dispose());

    test('when an agent writes into it then the write passes', () async {
      final r = await mcp('sheets.cell.setInput', {'a1': 'B3', 'input': '5'});

      expect(r.status, CommandStatus.ok);
      expect(s.text('B3'), '5');
    });

    test('when a person writes without a dialog context then it is not '
        'written (the confirmation could not be shown)', () async {
      await s.type('B3', '5');

      expect(s.content('B3'), isNull);
    });
  });

  group('Given the owner and a warning-only protection', () {
    setUp(() {
      s = SheetsHarness.open(role: Role.owner);
      s.editor.itemRole = Role.owner;
      attachCellFeatures(s.editor);
      protectAs(s, 'B2:B5', warningOnly: true);
    });
    tearDown(() => s.dispose());

    test('when the owner types into it then the "Heads up!" confirmation '
        'is still required (it is not written without it)', () async {
      await s.type('B3', '5');

      expect(s.content('B3'), isNull);
    });
  });

  group('Given a protected sheet except B2:B5', () {
    setUp(() {
      s = SheetsHarness.open(role: Role.editor);
      s.editor.itemRole = Role.editor;
      attachCellFeatures(s.editor);
      protectAs(s, null, except: ['B2:B5']);
    });
    tearDown(() => s.dispose());

    test('when typing inside the exception then it is written, and outside '
        'it is blocked', () async {
      await s.type('B3', 'ok');
      await s.type('C3', 'no');

      expect(s.text('B3'), 'ok');
      expect(s.content('C3'), isNull);
    });

    test('when renaming the sheet then it is blocked', () async {
      final name = s.sheet.name;

      await s.run('sheets.sheet.rename', {
        'sheetId': s.sheetId,
        'name': 'Other',
      });

      expect(s.sheet.name, name);
    });
  });

  group('Given an owner protecting ranges', () {
    setUp(() {
      s = SheetsHarness.open();
      attachCellFeatures(s.editor);
    });
    tearDown(() => s.dispose());

    test('when adding a protection then undo and redo round-trip', () async {
      final r = await s.run('sheets.protect.add', {
        'range': 'F2:F40',
        'description': 'Budget totals',
      });
      expect(r.status, CommandStatus.ok);
      final p = s.sheet.protections.values.single;
      expect(p.description, 'Budget totals');
      expect(p.createdBy, s.session.userId);

      await s.undo();
      expect(s.sheet.protections, isEmpty);

      await s.redo();
      expect(s.sheet.protections, hasLength(1));
    });

    test(
      'when protecting the sheet with exceptions then they are stored',
      () async {
        await s.run('sheets.protect.add', {
          'sheetId': s.sheetId,
          'exceptRanges': ['B2:B5, D1'],
        });

        final e = ProtectionController.of(s.editor).entries.single;
        expect(e.isSheet, isTrue);
        expect(e.except.map((r) => r.a1), ['B2:B5', 'D1']);
      },
    );

    test(
      'when updating to warning only and deleting then each is one step',
      () async {
        await s.run('sheets.protect.add', {'range': 'A1:B2'});
        final id = s.sheet.protections.keys.single;

        await s.run('sheets.protect.update', {'id': id, 'warningOnly': true});
        expect(s.sheet.protections[id]!.warningOnly, isTrue);
        await s.run('sheets.protect.delete', {'id': id});
        expect(s.sheet.protections, isEmpty);

        await s.undo();
        expect(s.sheet.protections[id]!.warningOnly, isTrue);
        await s.undo();
        expect(s.sheet.protections[id]!.warningOnly, isFalse);
      },
    );

    test(
      'when toggling View › Protected ranges then the stripes hide',
      () async {
        final p = ProtectionController.of(s.editor);
        expect(p.showStripes, isTrue);

        await s.run('sheets.view.toggleProtectedRanges');

        expect(p.showStripes, isFalse);
      },
    );
  });

  group('Given planned row changes', () {
    setUp(() {
      s = SheetsHarness.open();
      attachCellFeatures(s.editor);
    });
    tearDown(() => s.dispose());

    test('when deriving the intents of a value write then they are cell '
        'writes of row runs', () {
      final plan = const SheetsMutationPlanner().plan(
        SetCellInputs(
          sheetId: s.sheetId,
          row: 1,
          col: 1,
          inputs: [
            [const UserCellInput('a'), const UserCellInput('b')],
          ],
        ),
        s.model,
        s.session.planContext(),
      );

      final intents = WriteIntents.fromChanges(plan.changes, s.model);

      expect(intents.single, isA<CellWrites>());
      expect((intents.single as CellWrites).rects.map((r) => r.a1), ['B2:C2']);
    });
  });
}
