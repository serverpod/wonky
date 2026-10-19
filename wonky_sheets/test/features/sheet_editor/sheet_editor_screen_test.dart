import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/features/sheet_editor/sheet_editor_screen.dart';
import 'package:wonky_sheets/features/sheet_editor/sheets_document_controller.dart';
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
  });
}
