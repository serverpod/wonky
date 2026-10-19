import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/wonky_app.dart' show ConflictReviewChoice;
import 'package:wonky_sheets/features/history/conflict_review_dialog.dart';
import 'package:wonky_sheets/features/history/local_conflicts.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

void main() {
  for (final dark in [false, true]) {
    for (final width in [1200.0, 360.0]) {
      testWidgets('when the review dialog shows (${dark ? 'dark' : 'light'}, '
          '${width.toInt()} px) then overwritten cells are checkable, '
          'deleted ones are listed, and Apply returns the checked ids', (
        tester,
      ) async {
        final s = SheetsHarness.open();
        addTearDown(s.dispose);
        await s.type('B2', 'Pending');
        final sheet = s.sheet;
        final conflicts = [
          LocalConflict(
            id: 'c1',
            kind: LocalConflictKind.overwritten,
            sheetId: s.sheetId,
            rowId: sheet.rows.idAt(1),
            colId: sheet.columns.idAt(1),
            myValue: 's:Done',
            theirValue: 's:Pending',
            theirName: 'Bo Stone',
            detectedAt: clock.now(),
          ),
          LocalConflict(
            id: 'c2',
            kind: LocalConflictKind.rowDeleted,
            sheetId: s.sheetId,
            rowId: 'gone',
            colId: sheet.columns.idAt(0),
            myValue: 's:Lost',
            theirValue: null,
            theirName: 'Bo Stone',
            label: 'Sheet1!A9',
            detectedAt: clock.now(),
          ),
        ];
        ConflictReviewChoice? choice;
        await pumpSheets(
          tester,
          s,
          dark: dark,
          size: Size(width, 800),
          child: Builder(
            builder: (context) => Center(
              child: GestureDetector(
                key: const ValueKey('open'),
                behavior: HitTestBehavior.opaque,
                onTap: () async => choice = await showConflictReviewDialog(
                  context,
                  editor: s.editor,
                  conflicts: conflicts,
                ),
                child: const SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        );
        await tester.tap(find.byKey(const ValueKey('open')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Sheet1!B2 — yours: Done · now: Pending'),
          findsOneWidget,
        );
        expect(find.textContaining('Row deleted by Bo Stone'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Apply mine again'));
        await tester.pumpAndSettle();
        expect(choice?.action, 'apply');
        expect(choice?.ids, ['c1']);
      });
    }
  }
}
