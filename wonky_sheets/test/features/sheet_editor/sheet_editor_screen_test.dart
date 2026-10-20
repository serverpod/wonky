import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/sheet_editor/sheet_editor_screen.dart';
import 'package:wonky_sheets/features/sheet_editor/sheets_document_controller.dart';
import 'package:wonky_sheets/features/tab_bar/sheet_tab_bar.dart';
import 'package:shad/shad.dart' show ShadTheme;
import 'package:wonky_ui/wonky_ui.dart'
    show DocumentTitleField, WonkyMenubar, WonkyToolbar;

import '../../support/grid_pump.dart';
import '../../support/sheets_harness.dart';

void main() {
  late SheetsHarness s;

  setUp(() => s = SheetsHarness.open());

  Future<void> pumpScreen(
    WidgetTester tester, {
    bool dark = false,
    Size size = const Size(1440, 900),
  }) async {
    s.services.deactivate(s.doc);
    await pumpSheets(
      tester,
      s,
      dark: dark,
      size: size,
      child: SheetEditorScreen(
        services: s.services,
        itemUuid: testItemUuid,
        sessionFactory: (services, item) async => s.session,
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  SheetsDocumentController doc() =>
      s.services.activeDocument.value! as SheetsDocumentController;

  for (final dark in [false, true]) {
    testWidgets('Given an open spreadsheet (${dark ? 'dark' : 'light'}) when '
        'the screen loads then menubar, toolbar, formula bar, grid, tabs and '
        'status bar render', (tester) async {
      await pumpScreen(tester, dark: dark);

      for (final m in ['File', 'Edit', 'View', 'Insert', 'Format', 'Data']) {
        expect(find.text(m), findsWidgets, reason: m);
      }
      expect(
        find.byKey(const ValueKey('sheets.toolbar.format.bold')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('sheets.formulaBar')), findsOneWidget);
      expect(find.byKey(const ValueKey('sheets.grid')), findsOneWidget);
      expect(find.byKey(const ValueKey('sheets.tabBar')), findsOneWidget);
      expect(find.byKey(const ValueKey('sheets.status.mode')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  }

  testWidgets('Given the screen when typing into a cell then the editor '
      'and the formula bar show the text and Enter commits', (tester) async {
    await pumpScreen(tester);
    final ed = doc().editor!;
    ed.gridFocus.requestFocus();
    await tester.pump();

    await typeChars(tester, ed.editor, '4');
    await typeChars(tester, ed.editor, '2');
    expect(find.byKey(const ValueKey('sheets.cellEditor')), findsOneWidget);
    expect(ed.editor.text.text, '42');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();

    expect(ed.cells.displayAt(ed.activeSheetId, 0, 0)?.text, '42');
    expect(ed.activeA1, 'A2');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  group('Given a narrow (mobile) window', () {
    Finder key(String k) => find.byKey(ValueKey<String>(k));

    testWidgets('when an owner opens a spreadsheet then it is read-only: the '
        'grid and the sheet tabs show, without menubar, toolbar, formula bar '
        'or status bar (suite 02 §6.1)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      final ed = doc().editor!;

      expect(key('editor.mobile'), findsOneWidget);
      expect(key('editor.mobile.readOnly'), findsOneWidget);
      expect(find.byType(WonkyMenubar), findsNothing);
      expect(find.byType(WonkyToolbar), findsNothing);
      expect(key('sheets.toolbar.format.bold'), findsNothing);
      expect(key('sheets.formulaBar'), findsNothing);
      expect(key('sheets.status.mode'), findsNothing);
      expect(key('sheets.grid'), findsOneWidget);
      expect(key('sheets.tabBar'), findsOneWidget);
      expect(ed.readOnlyView, isTrue);
      expect(ed.canEdit, isFalse);
      expect(doc().mode, 'viewing');
      expect(
        s.services.dispatcher.stateOf('sheets.mode.editing').enabled,
        isFalse,
      );

      // Typing does not change a cell.
      ed.gridFocus.requestFocus();
      await tester.pump();
      await typeChars(tester, ed.editor, '4');
      expect(ed.cells.displayAt(ed.activeSheetId, 0, 0)?.text ?? '', '');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('when the window becomes wide then the formula bar, the '
        'toolbar and editing return (the desktop is unchanged)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(390, 844));
      expect(doc().editor!.canEdit, isFalse);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pump();
      await tester.pump();

      expect(key('editor.mobile'), findsNothing);
      expect(key('sheets.formulaBar'), findsOneWidget);
      expect(key('sheets.toolbar.format.bold'), findsOneWidget);
      expect(doc().editor!.readOnlyView, isFalse);
      expect(doc().editor!.canEdit, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    for (final dark in [false, true]) {
      testWidgets('when it shows in ${dark ? 'dark' : 'light'} then a 1 px '
          'line in the theme border color separates the title row from the '
          'grid (T-12)', (tester) async {
        await pumpScreen(tester, size: const Size(390, 844), dark: dark);

        final line = key('sheets.mobile.separator');
        expect(line, findsOneWidget);
        final theme = ShadTheme.of(tester.element(line));
        expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
        final box = tester.widget<ColoredBox>(
          find.descendant(of: line, matching: find.byType(ColoredBox)),
        );
        expect(box.color, theme.colorScheme.border);
        final rect = tester.getRect(line);
        expect(rect.height, 1);
        expect(rect.width, 390);
        // Below the title row, right above the grid.
        expect(
          rect.top,
          greaterThanOrEqualTo(
            tester.getRect(find.byType(DocumentTitleField)).bottom,
          ),
        );
        expect(tester.getRect(key('sheets.grid')).top, rect.bottom);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }

    testWidgets('when the window is wide then there is no separator: the '
        'formula bar is there (the desktop is unchanged)', (tester) async {
      await pumpScreen(tester);
      expect(key('sheets.mobile.separator'), findsNothing);
      expect(key('sheets.formulaBar'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    for (final dark in [false, true]) {
      testWidgets('when it shows at 360 px in ${dark ? 'dark' : 'light'} '
          'then nothing overflows', (tester) async {
        await pumpScreen(tester, size: const Size(360, 640), dark: dark);
        expect(key('sheets.grid'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }

    /// The center of cell [row], [col] on screen (row header 48 px, column
    /// header 24 px, rows 21 px, columns 100 px at 100 %).
    Offset cellAt(WidgetTester tester, int row, int col) =>
        tester.getTopLeft(key('sheets.grid')) +
        Offset(48 + col * 100 + 50, 24 + row * 21 + 10);

    Future<void> drag(
      WidgetTester tester,
      Offset from,
      Offset by, {
      PointerDeviceKind kind = PointerDeviceKind.touch,
      Duration hold = Duration.zero,
    }) async {
      final g = await tester.startGesture(from, kind: kind);
      if (hold > Duration.zero) await tester.pump(hold);
      for (var i = 0; i < 10; i++) {
        await g.moveBy(by / 10);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('when tapping or long-pressing cells then nothing is '
        'selected, and swiping (also after a long press, or with a mouse) '
        'pans the grid (T-1)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      final ed = doc().editor!;
      final before = ed.selection.describe();

      await tester.tapAt(cellAt(tester, 3, 1), kind: PointerDeviceKind.touch);
      await tester.pump(const Duration(milliseconds: 500));
      expect(ed.selection.describe(), before);

      final press = await tester.startGesture(
        cellAt(tester, 2, 1),
        kind: PointerDeviceKind.touch,
      );
      await tester.pump(const Duration(milliseconds: 700));
      await press.up();
      await tester.pump(const Duration(milliseconds: 500));
      expect(ed.selection.describe(), before);

      await drag(tester, cellAt(tester, 20, 1), const Offset(0, -200));
      final y = ed.scroll.y;
      expect(y, greaterThan(150));
      expect(ed.selection.describe(), before);

      // A held finger that then moves pans instead of selecting a range.
      await drag(
        tester,
        cellAt(tester, 10, 1),
        const Offset(0, -100),
        hold: const Duration(milliseconds: 700),
      );
      expect(ed.scroll.y, greaterThan(y + 50));
      expect(ed.selection.describe(), before);

      // A mouse in a narrow window pans too.
      final y2 = ed.scroll.y;
      await drag(
        tester,
        cellAt(tester, 10, 1),
        const Offset(0, -100),
        kind: PointerDeviceKind.mouse,
      );
      expect(ed.scroll.y, greaterThan(y2 + 50));
      expect(ed.selection.describe(), before);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('when the window is wide then a tap selects the cell (the '
        'desktop is unchanged)', (tester) async {
      await pumpScreen(tester);
      final ed = doc().editor!;
      await tester.tapAt(cellAt(tester, 3, 1), kind: PointerDeviceKind.touch);
      await tester.pump(const Duration(milliseconds: 500));
      expect(ed.selection.describe(), 'B4');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    for (final dark in [false, true]) {
      testWidgets('when it shows in ${dark ? 'dark' : 'light'} then the sheet '
          'tabs are taller and the bar shows the all-sheets menu and the tabs '
          'only (T-1)', (tester) async {
        await pumpScreen(tester, size: const Size(390, 844), dark: dark);
        final sheetId = doc().editor!.activeSheetId;

        expect(
          tester.getSize(key('sheets.tabBar')).height,
          SheetTabBar.mobileHeight,
        );
        final tab = find.descendant(
          of: key('sheets.tab.$sheetId'),
          matching: find.byType(Container),
        );
        expect(
          tester.getSize(tab.first).height,
          greaterThanOrEqualTo(SheetTabBar.mobileTabHeight),
        );
        expect(key('sheets.tab.all'), findsOneWidget);
        expect(key('sheets.tab.$sheetId'), findsOneWidget);
        for (final hidden in [
          'sheets.tab.add',
          'sheets.tab.scrollLeft',
          'sheets.tab.scrollRight',
          'sheets.tab.explore',
          'sheets.tab.menu.$sheetId',
        ]) {
          expect(key(hidden), findsNothing, reason: hidden);
        }
        final theme = ShadTheme.of(tester.element(key('sheets.tabBar')));
        expect(theme.brightness, dark ? Brightness.dark : Brightness.light);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }

    testWidgets('when the window is wide then the tab bar keeps its height '
        'and every control (the desktop is unchanged)', (tester) async {
      await pumpScreen(tester);
      final sheetId = doc().editor!.activeSheetId;
      expect(tester.getSize(key('sheets.tabBar')).height, 36);
      for (final shown in [
        'sheets.tab.add',
        'sheets.tab.all',
        'sheets.tab.scrollLeft',
        'sheets.tab.scrollRight',
        'sheets.tab.explore',
        'sheets.tab.menu.$sheetId',
      ]) {
        expect(key(shown), findsOneWidget, reason: shown);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
