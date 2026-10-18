import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

/// Pointer interactions of 03 §3, §6.2, §10 on the grid at 100 % zoom:
/// row header 48 px wide, column header 24 px high, rows 21 px, columns
/// 100 px.
void main() {
  late SheetsHarness s;

  setUp(() => s = SheetsHarness.open());
  tearDown(() => s.dispose());

  Offset cell(int row, int col) =>
      Offset(48 + col * 100 + 50, 24 + row * 21 + 10);

  Future<void> drag(WidgetTester tester, Offset from, Offset to) async {
    final g = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await g.moveTo(Offset.lerp(from, to, 0.5)!);
    await tester.pump();
    await g.moveTo(to);
    await tester.pump();
    await g.up();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('Given the grid when clicking a cell then it is selected, and '
      'shift-clicking extends the range', (tester) async {
    await pumpSheets(tester, s);

    await tester.tapAt(cell(1, 1));
    await tester.pump(const Duration(milliseconds: 500));
    expect(s.editor.activeA1, 'B2');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tapAt(cell(3, 2));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(s.editor.selection.describe(), 'B2:C4');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Given the grid when dragging across cells then the range is '
      'selected', (tester) async {
    await pumpSheets(tester, s);

    await drag(tester, cell(0, 0), cell(2, 3));

    expect(s.editor.selection.describe(), 'A1:D3');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Given the column header when dragging the boundary of B then '
      'column B is resized in one undo step', (tester) async {
    await pumpSheets(tester, s);

    await drag(tester, const Offset(248, 12), const Offset(298, 12));

    expect(s.sheet.columns.sizeAt(1), 150);
    await s.undo();
    expect(s.sheet.columns.sizeAt(1), 100);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Given 1 and 3 in A1:A2 when dragging the fill handle to A5 '
      'then the series continues 5, 7, 9', (tester) async {
    await s.type('A1', '1');
    await s.type('A2', '3');
    await s.select('A1:A2');
    await pumpSheets(tester, s);

    await drag(tester, const Offset(148, 24 + 2 * 21), cell(4, 0));

    expect([s.text('A3'), s.text('A4'), s.text('A5')], ['5', '7', '9']);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Given a column header when clicking it then the whole column '
      'is selected', (tester) async {
    await pumpSheets(tester, s);

    await tester.tapAt(const Offset(48 + 250, 12));
    await tester.pump(const Duration(milliseconds: 500));

    expect(s.editor.selection.describe(), 'C:C');
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Given column A selected when dragging its header past C then '
      'the column moves (one undo step)', (tester) async {
    await s.type('A1', 'a');
    await s.type('B1', 'b');
    await s.select('A:A');
    await pumpSheets(tester, s);

    await drag(tester, const Offset(98, 12), const Offset(48 + 280, 12));

    expect(s.text('A1'), 'b');
    expect(s.text('C1'), 'a');
    await s.undo();
    expect(s.text('A1'), 'a');
    await tester.pump(const Duration(seconds: 1));
  });

  // CQ-41 (S-07): a cursor change rebuilds only the mouse region.
  testWidgets('Given the grid when the pointer moves onto a column boundary '
      'then the cursor changes and the paint passes are not rebuilt', (
    tester,
  ) async {
    await pumpSheets(tester, s);
    final pass = find.byKey(const ValueKey<String>('sheets.grid.content'));
    final before = tester.widget(pass);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: cell(2, 2));
    addTearDown(mouse.removePointer);
    await tester.pump();

    // The boundary between B and C in the column header.
    await mouse.moveTo(const Offset(48 + 200, 12));
    await tester.pump();

    final cursors = tester
        .widgetList<MouseRegion>(find.byType(MouseRegion))
        .map((m) => m.cursor);
    expect(cursors, contains(SystemMouseCursors.resizeColumn));
    expect(identical(tester.widget(pass), before), isTrue);
    await tester.pump(const Duration(seconds: 1));
  });

  // CQ-41 (S-06): widgets built before the paint use this frame's geometry.
  testWidgets('Given the grid when it scrolls then the geometry read before '
      'the next paint is already scrolled', (tester) async {
    await pumpSheets(tester, s);

    s.editor.scroll.scrollBy(0, 210);

    expect(s.editor.geometry?.scrollY, 210);
    await tester.pump(const Duration(seconds: 1));
  });
}
