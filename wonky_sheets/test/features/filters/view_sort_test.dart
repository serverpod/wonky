import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/clipboard/system_clipboard.dart';
import 'package:wonky_sheets/features/data_tools/data_tools.dart';
import 'package:wonky_sheets/features/filters/filter_view_bar.dart';
import 'package:wonky_sheets/features/grid/grid_area.dart';
import 'package:wonky_sheets/features/grid/selection/data_edge_finder.dart';
import 'package:wonky_sheets/features/sheet_editor/sheet_editor_controller.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

/// Model rows 1–5 hold d, b, e, a, c: sorted on screen a b c d e is model
/// rows 4, 2, 5, 1, 3.
Future<SheetsHarness> sortedView({bool saved = false}) async {
  final s = SheetsHarness.open();
  const names = ['Name', 'd', 'b', 'e', 'a', 'c'];
  for (var r = 0; r < names.length; r++) {
    await s.type('A${r + 1}', names[r]);
    await s.type('B${r + 1}', r == 0 ? 'N' : '$r');
  }
  await s.select('A1');
  await s.run('sheets.filterView.create', {'temporary': !saved});
  await s.run('sheets.filterView.sortColumn', {
    'colId': s.sheet.columns.idAt(0),
    'ascending': true,
  });
  return s;
}

List<int> shown(SheetEditorController ed) => [
  for (var d = 1; d <= 5; d++) ed.rowOrder!.modelRow(d),
];

void main() {
  test('Given a filter view, when it is sorted, then only the display order '
      'changes (the data, and the order outside the view, stay)', () async {
    final s = await sortedView();
    expect(shown(s.editor), [4, 2, 5, 1, 3]);
    expect(s.text('A2'), 'd', reason: 'data not moved');
    expect(s.editor.rowOrder!.modelRow(0), 0);

    // Closing the view restores the stored order on screen.
    await s.run('sheets.filterView.activate', {'viewId': null});
    expect(s.editor.rowOrder, isNull);
    await s.dispose();
  });

  test('Given a saved view, when it is sorted, then the sort is one undo '
      'step and editing re-sorts the view after a moment', () async {
    final s = await sortedView(saved: true);
    final view = DataTools.of(s.editor).filters;
    expect(view.effective(s.sheetId)!.sort, isNotEmpty);
    await s.undo();
    expect(s.editor.rowOrder, isNull);
    await s.redo();
    expect(shown(s.editor), [4, 2, 5, 1, 3]);

    await s.type('A5', 'zz'); // "a" → "zz": it moves to the end.
    expect(shown(s.editor), [4, 2, 5, 1, 3], reason: 'not before the delay');
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(shown(s.editor), [2, 5, 1, 3, 4]);
    await s.dispose();
  });

  test('Given a sorted view, when moving and extending with the keyboard, '
      'then it follows the screen order and the selection resolves to the '
      'model rows shown', () async {
    final s = await sortedView();
    final ed = s.editor;
    ed.selection.selectCell(4, 0); // "a", first on screen.
    ed.moveActive(NavDirection.down);
    expect(ed.selection.resolved.activeRow, 2, reason: '"b" is next');
    ed.moveActive(NavDirection.down, extend: true);
    ed.moveActive(NavDirection.down, extend: true);
    final sel = ed.selection.resolved;
    // Screen rows 2–4 (b, c, d) are model rows 2, 5, 1.
    expect([for (final r in sel.ranges) r.rect.top], [2, 5, 1]);
    expect(sel.isSingleGroup, isTrue);
    expect(sel.activeRange.displayRect!.rowCount, 3);
    await s.dispose();
  });

  test('Given rows selected on screen in a sorted view, when copying, '
      'pasting and filling down, then they follow the display order in one '
      'step each', () async {
    final s = await sortedView();
    final ed = s.editor;
    ed.selection.selectCell(4, 0);
    ed.selection.extendTo(5, 1); // a, b, c on screen.
    expect((await s.run('sheets.edit.copy')).isOk, isTrue);
    expect(s.clip.data!.plainText.trim().split(RegExp(r'\r?\n')), [
      'a\t4',
      'b\t2',
      'c\t5',
    ]);

    // Paste three lines at "d" (screen row 4): d, e and past the view.
    s.clip.data = const SystemClipboardData(plainText: 'x\ny\nz');
    ed.selection.selectCell(1, 0);
    final steps = s.h.undoLabels.length;
    expect((await s.run('sheets.edit.paste')).isOk, isTrue);
    expect(s.text('A2'), 'x', reason: 'model row 1 shows 4th');
    expect(s.text('A4'), 'y', reason: 'model row 3 shows 5th');
    expect(s.text('A7'), 'z', reason: 'below the view');
    expect(s.h.undoLabels.length, steps + 1);
    await s.undo();
    expect(s.text('A2'), 'd');

    // Fill down "a"'s B over b and c on screen.
    ed.selection.selectCell(4, 1);
    ed.selection.extendTo(5, 1);
    expect((await s.run('sheets.fill.down')).isOk, isTrue);
    expect(s.text('B3'), '4');
    expect(s.text('B6'), '4');
    expect(s.text('B2'), '1', reason: '"d" is not on screen below');
    await s.dispose();
  });

  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('Given a sorted view ($mode), when the grid paints, then '
        'rows hit-test in screen order with model row numbers, and the bar '
        'clears the sort', (tester) async {
      final s = await sortedView();
      await pumpSheets(
        tester,
        s,
        dark: dark,
        size: const Size(800, 600),
        child: Column(
          children: [
            FilterViewBar(editor: s.editor),
            Expanded(
              child: GridArea(controller: s.editor, services: s.services),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final g = s.editor.geometry!;
      // Screen row 1 (y of display row 1) holds model row 4 ("a").
      final y = g.main.yDisplay(1) + 2;
      expect(g.rowAtY(y), 4);
      expect(g.main.cellRect(4, 0).top, closeTo(g.main.yDisplay(1), 0.01));
      expect(find.byKey(const ValueKey('sheets.filterViewBar.sort')), findsOne);
      // At 800 px the range field and the "Sorted by" chip keep room for
      // their text (the chip had shrunk to its icon).
      expect(
        tester
            .getSize(find.byKey(const ValueKey('sheets.filterViewBar.sort')))
            .width,
        greaterThan(120),
      );
      expect(
        tester
            .getSize(find.byKey(const ValueKey('sheets.filterViewBar.range')))
            .width,
        greaterThanOrEqualTo(140),
      );

      await tester.tap(
        find.byKey(const ValueKey('sheets.filterViewBar.clearSort')),
      );
      await tester.pumpAndSettle();
      expect(s.editor.rowOrder, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await s.dispose();
    });
  }
}
