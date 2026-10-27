import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellRuns, CellTable, WonkyDocument;
import 'package:shad/shad.dart';
import 'package:wonky_core/wonky_core.dart'
    show CommandResult, CommandStatus, InvocationSource;
import 'package:wonky_ui/testing.dart';
import 'package:wonky_write/features/editor/model/table_model.dart';
import 'package:wonky_write/features/tables/table_editor.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show Delta;

import '../screen/support/screen_harness.dart';

const _open = ValueKey<String>('test.open');
const _dialog = ValueKey<String>('write.dialog.tableEditor');
const _size = ValueKey<String>('write.dialog.tableEditor.size');
const _done = ValueKey<String>('write.dialog.tableEditor.done');
const _cancel = ValueKey<String>('write.dialog.tableEditor.cancel');

ValueKey<String> _cell(int r, int c) =>
    ValueKey<String>('write.dialog.tableEditor.cell.$r.$c');

ValueKey<String> _tool(String name) =>
    ValueKey<String>('write.dialog.tableEditor.$name');

/// What a dialog returned once it closed.
class _Closed<T> {
  bool closed = false;
  T? value;
}

TableModel _fruit() => TableModel(
  id: 't1',
  align: const [TableAlign.none, TableAlign.none],
  rows: const [
    ['Name', 'Qty'],
    ['Apples', '3'],
    ['Pears', '5'],
  ],
);

Future<_Closed<TableModel>> _openEditor(
  WidgetTester tester, {
  TableModel? table,
  int row = 0,
  int column = 0,
  Brightness brightness = Brightness.light,
}) async {
  final closed = _Closed<TableModel>();
  await pumpWonky(
    tester,
    Builder(
      builder: (context) => ShadButton(
        key: _open,
        onPressed: () => unawaited(
          showTableEditor(
            context,
            table ?? _fruit(),
            row: row,
            column: column,
          ).then((v) {
            closed
              ..closed = true
              ..value = v;
          }),
        ),
        child: const Text('Open'),
      ),
    ),
    brightness: brightness,
  );
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
  return closed;
}

TextEditingController _controllerOf(WidgetTester tester, int r, int c) =>
    tester.widget<EditableText>(find.byKey(_cell(r, c))).controller;

String _cellText(WidgetTester tester, int r, int c) =>
    _controllerOf(tester, r, c).text;

bool _cellFocused(WidgetTester tester, int r, int c) =>
    tester.widget<EditableText>(find.byKey(_cell(r, c))).focusNode.hasFocus;

bool _toolEnabled(WidgetTester tester, String name) =>
    tester.widget<ShadIconButton>(find.byKey(_tool(name))).enabled;

String _sizeLabel(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(_size)).data!;

Future<void> _tapCell(WidgetTester tester, int r, int c) async {
  await tester.tap(find.byKey(_cell(r, c)));
  await tester.pump();
}

Future<void> _tapTool(WidgetTester tester, String name) async {
  await tester.tap(find.byKey(_tool(name)));
  await tester.pumpAndSettle();
}

Future<void> _withMod(WidgetTester tester, LogicalKeyboardKey key) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  await tester.pump();
}

void main() {
  for (final brightness in Brightness.values) {
    group('Given the table editor on a 3 × 2 table (${brightness.name})', () {
      testWidgets('when it opens then the cells and the size show and the '
          'first cell is focused', (tester) async {
        await _openEditor(tester, brightness: brightness);

        expect(find.byKey(_dialog), findsOneWidget);
        expect(find.text('Edit table'), findsOneWidget);
        expect(_sizeLabel(tester), '3 × 2');
        expect(_cellText(tester, 0, 0), 'Name');
        expect(_cellText(tester, 2, 1), '5');
        expect(_cellFocused(tester, 0, 0), isTrue);
        expect(
          _controllerOf(tester, 0, 0).selection.textInside('Name'),
          'Name',
        );
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await settleTooltips(tester);
      });
    });
  }

  group('Given the table editor on a 3 × 2 table', () {
    testWidgets('when it opens on row 2, column B then that cell is focused', (
      tester,
    ) async {
      await _openEditor(tester, row: 2, column: 1);

      expect(_cellFocused(tester, 2, 1), isTrue);
      expect(_cellFocused(tester, 0, 0), isFalse);
    });

    testWidgets('when editing a cell and pressing Done then the edited table '
        'is returned', (tester) async {
      final closed = await _openEditor(tester);

      await tester.enterText(find.byKey(_cell(1, 0)), 'Bananas');
      await tester.pump();
      await tester.tap(find.byKey(_done));
      await tester.pumpAndSettle();

      expect(closed.closed, isTrue);
      expect(closed.value?.rows, [
        ['Name', 'Qty'],
        ['Bananas', '3'],
        ['Pears', '5'],
      ]);
      expect(closed.value?.id, 't1');
    });

    testWidgets('when pressing Done without changes then nothing is '
        'returned', (tester) async {
      final closed = await _openEditor(tester);

      await tester.tap(find.byKey(_done));
      await tester.pumpAndSettle();

      expect(closed.closed, isTrue);
      expect(closed.value, isNull);
      expect(find.byKey(_dialog), findsNothing);
    });

    testWidgets('when cancelling after an edit then a confirmation asks and '
        'Keep editing keeps the draft', (tester) async {
      final closed = await _openEditor(tester);
      await tester.enterText(find.byKey(_cell(1, 1)), '30');
      await tester.pump();

      await tester.tap(find.byKey(_cancel));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('write.dialog.discardTable')),
        findsOneWidget,
      );
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();

      expect(closed.closed, isFalse);
      expect(find.byKey(_dialog), findsOneWidget);
      expect(_cellText(tester, 1, 1), '30');
    });

    testWidgets('when cancelling after an edit and choosing Discard then the '
        'editor closes without a result', (tester) async {
      final closed = await _openEditor(tester);
      await tester.enterText(find.byKey(_cell(1, 1)), '30');
      await tester.pump();

      await tester.tap(find.byKey(_cancel));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('write.dialog.discardTable.discard')),
      );
      await tester.pumpAndSettle();

      expect(closed.closed, isTrue);
      expect(closed.value, isNull);
      expect(find.byKey(_dialog), findsNothing);
    });

    testWidgets('when pressing Escape on an unchanged table then it closes', (
      tester,
    ) async {
      final closed = await _openEditor(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(closed.closed, isTrue);
      expect(closed.value, isNull);
    });

    testWidgets('when the header row is current then the row operations that '
        'would move or delete it are disabled', (tester) async {
      await _openEditor(tester);

      expect(_toolEnabled(tester, 'rowAbove'), isFalse);
      expect(_toolEnabled(tester, 'deleteRow'), isFalse);
      expect(_toolEnabled(tester, 'moveUp'), isFalse);
      expect(_toolEnabled(tester, 'moveDown'), isFalse);
      expect(_toolEnabled(tester, 'rowBelow'), isTrue);
      expect(_toolEnabled(tester, 'moveLeft'), isFalse);
      expect(_toolEnabled(tester, 'moveRight'), isTrue);
      expect(_toolEnabled(tester, 'undo'), isFalse);
    });

    testWidgets('when inserting a row below then the size grows and the '
        'editor undo and redo restore it', (tester) async {
      await _openEditor(tester);
      await _tapCell(tester, 1, 0);

      await _tapTool(tester, 'rowBelow');
      expect(_sizeLabel(tester), '4 × 2');
      expect(_cellText(tester, 2, 0), '');
      expect(_cellText(tester, 3, 0), 'Pears');

      await _tapTool(tester, 'undo');
      expect(_sizeLabel(tester), '3 × 2');
      expect(_cellText(tester, 2, 0), 'Pears');

      await _tapTool(tester, 'redo');
      expect(_sizeLabel(tester), '4 × 2');
      await settleTooltips(tester);
    });

    testWidgets('when deleting a body row then it is removed from the '
        'returned table', (tester) async {
      final closed = await _openEditor(tester);
      await _tapCell(tester, 1, 0);

      await _tapTool(tester, 'deleteRow');
      await tester.tap(find.byKey(_done));
      await tester.pumpAndSettle();

      expect(closed.value?.rows, [
        ['Name', 'Qty'],
        ['Pears', '5'],
      ]);
      await settleTooltips(tester);
    });

    testWidgets('when moving column B left then the columns swap', (
      tester,
    ) async {
      final closed = await _openEditor(tester, column: 1);

      await _tapTool(tester, 'moveLeft');
      await tester.tap(find.byKey(_done));
      await tester.pumpAndSettle();

      expect(closed.value?.rows.first, ['Qty', 'Name']);
      expect(closed.value?.rows[1], ['3', 'Apples']);
      await settleTooltips(tester);
    });

    testWidgets('when centering column B then its alignment is returned', (
      tester,
    ) async {
      final closed = await _openEditor(tester, column: 1);

      await tester.tap(find.byKey(_tool('align.center')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ShadToggle>(find.byKey(_tool('align.center'))).value,
        isTrue,
      );
      await tester.tap(find.byKey(_done));
      await tester.pumpAndSettle();

      expect(closed.value?.align, [TableAlign.none, TableAlign.center]);
      await settleTooltips(tester);
    });

    testWidgets('when pressing Ctrl+B on a selected cell then the text is '
        'wrapped in bold markers', (tester) async {
      await _openEditor(tester, row: 1);

      await _withMod(tester, LogicalKeyboardKey.keyB);

      expect(_cellText(tester, 1, 0), '**Apples**');
    });

    testWidgets('when pressing the toolbar Bold on a selected cell then the '
        'text is wrapped in bold markers', (tester) async {
      await _openEditor(tester, row: 1);

      await _tapTool(tester, 'bold');

      expect(_cellText(tester, 1, 0), '**Apples**');
      await settleTooltips(tester);
    });

    testWidgets('when editing and pressing Ctrl+Z then the cell edit is '
        'undone in the draft', (tester) async {
      await _openEditor(tester);
      await tester.enterText(find.byKey(_cell(1, 0)), 'Kiwis');
      await tester.pump();
      expect(_toolEnabled(tester, 'undo'), isTrue);

      await _withMod(tester, LogicalKeyboardKey.keyZ);
      await tester.pumpAndSettle();

      expect(_cellText(tester, 1, 0), 'Apples');
      expect(_toolEnabled(tester, 'redo'), isTrue);
    });

    testWidgets('when pressing Tab then the next cell is focused', (
      tester,
    ) async {
      await _openEditor(tester);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_cellFocused(tester, 0, 1), isTrue);
    });

    testWidgets('when pressing Tab in the last cell then a row is appended', (
      tester,
    ) async {
      await _openEditor(tester, row: 2, column: 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_sizeLabel(tester), '4 × 2');
      expect(_cellFocused(tester, 3, 0), isTrue);
    });

    testWidgets(
      'when typing into a row appended with Tab then the text is kept',
      (tester) async {
        final closed = await _openEditor(tester, row: 2, column: 1);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(_cell(3, 0)), 'Plums');
        await tester.pump();
        await tester.tap(find.byKey(_done));
        await tester.pumpAndSettle();

        expect(closed.value?.rows.last, ['Plums', '']);
      },
    );

    testWidgets(
      'when closing an edited table with the dialog X then the discard '
      'confirmation asks first',
      (tester) async {
        final closed = await _openEditor(tester);
        await tester.enterText(find.byKey(_cell(1, 1)), '30');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: find.byKey(_dialog),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is ShadIconButton &&
                  w.icon is Icon &&
                  (w.icon as Icon).icon == LucideIcons.x,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(closed.closed, isFalse);
        expect(
          find.byKey(const ValueKey('write.dialog.discardTable')),
          findsOneWidget,
        );
      },
    );
  });

  group('Given the table size dialog', () {
    Future<_Closed<({int rows, int cols})>> openSize(
      WidgetTester tester,
    ) async {
      final closed = _Closed<({int rows, int cols})>();
      await pumpWonky(
        tester,
        Builder(
          builder: (context) => ShadButton(
            key: _open,
            onPressed: () => unawaited(
              showTableSizeDialog(context).then((v) {
                closed
                  ..closed = true
                  ..value = v;
              }),
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.byKey(_open));
      await tester.pumpAndSettle();
      return closed;
    }

    Finder stepperButton(String stepper, String label) => find.descendant(
      of: find.byKey(ValueKey<String>('write.dialog.tableSize.$stepper')),
      matching: find.byWidgetPredicate(
        (w) => w is ShadIconButton && w.semanticLabel == label,
      ),
    );

    testWidgets('when pressing Insert right away then 3 × 3 is returned', (
      tester,
    ) async {
      final closed = await openSize(tester);

      await tester.tap(
        find.byKey(const ValueKey('write.dialog.tableSize.insert')),
      );
      await tester.pumpAndSettle();

      expect(closed.value, (rows: 3, cols: 3));
    });

    testWidgets('when adding a row and removing a column then the new size '
        'is returned', (tester) async {
      final closed = await openSize(tester);

      await tester.tap(stepperButton('rows', 'Increase'));
      await tester.pump();
      await tester.tap(stepperButton('cols', 'Decrease'));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('write.dialog.tableSize.insert')),
      );
      await tester.pumpAndSettle();

      expect(closed.value, (rows: 4, cols: 2));
    });

    testWidgets('when cancelling then nothing is returned', (tester) async {
      final closed = await openSize(tester);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(closed.closed, isTrue);
      expect(closed.value, isNull);
    });
  });

  group('Given a document with a table and write.table.edit', () {
    String tableId(Delta delta) =>
        CellRuns.of(WonkyDocument(delta)).whereType<CellTable>().single.id;

    List<Object?> rowsOf(Delta delta) => [
      for (final row in CellRuns.of(
        WonkyDocument(delta),
      ).whereType<CellTable>().single.rows)
        [for (final c in row.cells) c.text],
    ];

    testWidgets('when editing a cell in the editor and pressing Done then '
        'the table changes in one undo step', (tester) async {
      final h = await ScreenHarness.open(
        tester,
        markdown: 'Intro\n\n| Name | Qty |\n| --- | --- |\n| Apples | 3 |\n',
      );
      late BuildContext context;
      await h.pump(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      );
      final id = tableId(h.doc.editor.delta);
      final steps = h.session.undo
          .undoStepsOf(h.session.session.undoStackKey)
          .length;

      final result = h.services.dispatcher.invoke(
        'write.table.edit',
        args: {'nodeId': id, 'row': 1, 'col': 0},
        source: InvocationSource.ui,
        context: context,
      );
      await tester.pumpAndSettle();
      expect(_cellFocused(tester, 1, 0), isTrue);
      await tester.enterText(find.byKey(_cell(1, 0)), 'Pears');
      await tester.pump();
      await tester.tap(find.byKey(_done));
      await tester.pumpAndSettle();

      expect(
        await result,
        isA<CommandResult>().having((r) => r.isOk, 'isOk', isTrue),
      );
      expect(rowsOf(h.doc.editor.delta), [
        ['Name', 'Qty'],
        ['Pears', '3'],
      ]);
      expect(
        h.session.undo.undoStepsOf(h.session.session.undoStackKey),
        hasLength(steps + 1),
      );

      await tester.runAsync(h.session.undo.undo);
      expect(rowsOf(h.doc.editor.delta), [
        ['Name', 'Qty'],
        ['Apples', '3'],
      ]);
      await h.dispose(tester);
    });

    testWidgets('when cancelling the editor then the document is unchanged '
        'and nothing is added to undo', (tester) async {
      final h = await ScreenHarness.open(
        tester,
        markdown: '| Name | Qty |\n| --- | --- |\n| Apples | 3 |\n',
      );
      late BuildContext context;
      await h.pump(
        tester,
        Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      );
      final before = h.doc.editor.delta;
      final steps = h.session.undo
          .undoStepsOf(h.session.session.undoStackKey)
          .length;

      final result = h.services.dispatcher.invoke(
        'write.table.edit',
        args: {'nodeId': tableId(before)},
        source: InvocationSource.ui,
        context: context,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_cancel));
      await tester.pumpAndSettle();

      expect((await result).status, CommandStatus.cancelled);
      expect(h.doc.editor.delta, before);
      expect(
        h.session.undo.undoStepsOf(h.session.session.undoStackKey),
        hasLength(steps),
      );
      await h.dispose(tester);
    });
  });
}
