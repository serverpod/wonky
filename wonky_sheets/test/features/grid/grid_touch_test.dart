import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

/// Touch on the grid (S-01) and cancelled pointers (S-08), at 100 % zoom:
/// row header 48 px wide, column header 24 px high, rows 21 px, columns
/// 100 px.
void main() {
  late SheetsHarness s;

  setUp(() => s = SheetsHarness.open());
  tearDown(() => s.dispose());

  Offset cell(int row, int col) =>
      Offset(48 + col * 100 + 50, 24 + row * 21 + 10);

  /// Moves [g] from [from] by [by] in [steps] frames of 16 ms.
  Future<void> moveBy(
    WidgetTester tester,
    TestGesture g,
    Offset by, {
    int steps = 10,
  }) async {
    for (var i = 0; i < steps; i++) {
      await g.moveBy(by / steps.toDouble());
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  group('Given the grid on a touch screen', () {
    testWidgets('when one finger drags up then the grid scrolls and the '
        'selection stays', (tester) async {
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        cell(20, 3),
        kind: PointerDeviceKind.touch,
      );
      await moveBy(tester, g, const Offset(-60, -200));
      await g.up();
      await tester.pumpAndSettle();

      expect(s.editor.scroll.y, greaterThan(150));
      expect(s.editor.scroll.x, greaterThan(40));
      expect(s.editor.selection.describe(), 'A1');
    });

    testWidgets('when a finger flicks then the grid keeps scrolling after '
        'it lifts', (tester) async {
      await pumpSheets(tester, s);

      await tester.flingFrom(
        cell(25, 2),
        const Offset(0, -300),
        3000,
        deviceKind: PointerDeviceKind.touch,
      );
      await tester.pump();
      final atLift = s.editor.scroll.y;
      await tester.pumpAndSettle();

      expect(atLift, greaterThan(200));
      expect(s.editor.scroll.y, greaterThan(atLift + 100));
      expect(s.editor.selection.describe(), 'A1');
    });

    testWidgets('when a cell is tapped then it is selected', (tester) async {
      await pumpSheets(tester, s);

      await tester.tapAt(cell(2, 1), kind: PointerDeviceKind.touch);
      await tester.pump(const Duration(milliseconds: 500));

      expect(s.editor.activeA1, 'B3');
      expect(s.editor.scroll.y, 0);
    });

    testWidgets('when a cell is long-pressed and the finger drags then the '
        'range is selected instead of scrolling', (tester) async {
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        cell(0, 0),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await moveBy(tester, g, cell(2, 3) - cell(0, 0));
      await g.up();
      await tester.pump();

      expect(s.editor.selection.describe(), 'A1:D3');
      expect(s.editor.scroll.y, 0);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('when two fingers spread then the grid zooms in, at most to '
        '200 %, and pinching zooms out to at least 50 %', (tester) async {
      await pumpSheets(tester, s);
      final center = cell(10, 4);
      final a = await tester.startGesture(
        center - const Offset(40, 0),
        kind: PointerDeviceKind.touch,
        pointer: 1,
      );
      final b = await tester.startGesture(
        center + const Offset(40, 0),
        kind: PointerDeviceKind.touch,
        pointer: 2,
      );
      await tester.pump();

      // 80 px → 120 px apart: 150 %.
      await a.moveBy(const Offset(-20, 0));
      await b.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(s.editor.scroll.zoom, closeTo(1.5, 0.001));

      // Far apart: clamped to 200 %.
      await a.moveBy(const Offset(-300, 0));
      await b.moveBy(const Offset(300, 0));
      await tester.pump();
      expect(s.editor.scroll.zoom, 2.0);

      // Close together: clamped to 50 %.
      await a.moveTo(center - const Offset(5, 0));
      await b.moveTo(center + const Offset(5, 0));
      await tester.pump();
      expect(s.editor.scroll.zoom, 0.5);

      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      expect(s.editor.selection.describe(), 'A1');
    });

    testWidgets('when a long-press fill drag is cancelled by the system '
        'then nothing is filled', (tester) async {
      await s.type('A1', '1');
      await s.type('A2', '3');
      await s.select('A1:A2');
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        const Offset(148, 24 + 2 * 21),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(const Duration(milliseconds: 600));
      await moveBy(tester, g, cell(4, 0) - const Offset(148, 24 + 2 * 21));
      expect(s.editor.drag.value, isNotNull);

      await g.cancel();
      await tester.pump();

      expect(s.editor.drag.value, isNull);
      expect(s.text('A3'), '');
      await tester.pump(const Duration(seconds: 1));
    });
  });

  group('Given a mouse drag (S-08)', () {
    testWidgets('when a fill-handle drag is cancelled then nothing is '
        'filled', (tester) async {
      await s.type('A1', '1');
      await s.type('A2', '3');
      await s.select('A1:A2');
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        const Offset(148, 24 + 2 * 21),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await g.moveTo(cell(4, 0));
      await tester.pump();
      expect(s.editor.drag.value, isNotNull);

      await g.cancel();
      await tester.pump();

      expect(s.editor.drag.value, isNull);
      expect([s.text('A3'), s.text('A4'), s.text('A5')], ['', '', '']);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('when a column resize is cancelled then the width is kept', (
      tester,
    ) async {
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        const Offset(248, 12),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await g.moveTo(const Offset(298, 12));
      await tester.pump();

      await g.cancel();
      await tester.pump();

      expect(s.sheet.columns.sizeAt(1), 100);
      expect(s.editor.drag.value, isNull);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('when column A is dragged past C and the drag is cancelled '
        'then nothing moves', (tester) async {
      await s.type('A1', 'a');
      await s.select('A:A');
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        const Offset(98, 12),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await g.moveTo(const Offset(48 + 280, 12));
      await tester.pump();

      await g.cancel();
      await tester.pump();

      expect(s.text('A1'), 'a');
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('when a mouse drags across cells then it still selects the '
        'range and does not scroll', (tester) async {
      await pumpSheets(tester, s);
      final g = await tester.startGesture(
        cell(0, 0),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await g.moveTo(cell(2, 3));
      await tester.pump();
      await g.up();
      await tester.pump();

      expect(s.editor.selection.describe(), 'A1:D3');
      expect(s.editor.scroll.y, 0);
      await tester.pump(const Duration(seconds: 1));
    });
  });
}
