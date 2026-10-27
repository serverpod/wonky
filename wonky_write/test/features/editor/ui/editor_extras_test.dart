import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/dnd/drop_indicator.dart';
import 'package:wonky_app/platform.dart';
import 'package:wonky_write/features/editor/keyboard/editor_keyboard.dart';
import 'package:wonky_write/features/editor/popovers/editor_popovers.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';

import '../support/editor_harness.dart';

/// An [ExternalDropSource] driven by the test.
class FakeDrops implements ExternalDropSource {
  bool Function(Offset, ExternalDragKind)? over;
  VoidCallback? leave;
  void Function(ExternalDrop)? drop;

  @override
  void attach({
    required bool Function(Offset globalPosition, ExternalDragKind kind) onOver,
    required VoidCallback onLeave,
    required void Function(ExternalDrop drop) onDrop,
  }) {
    over = onOver;
    leave = onLeave;
    drop = onDrop;
  }

  @override
  void detach() {
    over = null;
    leave = null;
    drop = null;
  }
}

class _Pumped {
  _Pumped(this.h, this.key, this.drops);

  final EditorHarness h;
  final GlobalKey<WonkyEditorState> key;
  final FakeDrops drops;

  WonkyEditorState get state => key.currentState!;
}

Future<_Pumped> _pump(
  WidgetTester tester,
  Delta delta, {
  EmojiSuggester? emoji,
  void Function(List<DroppedFile> files, int index)? onDropFiles,
  VoidCallback? onUndo,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = EditorHarness(delta);
  final key = GlobalKey<WonkyEditorState>();
  final drops = FakeDrops();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WonkyEditor(
          key: key,
          controller: h.controller,
          documentTitle: 'Test doc',
          emojiSuggestions: emoji,
          onDropFiles: onDropFiles,
          externalDrops: drops,
          shortcutCallbacks: EditorShortcutCallbacks(onUndo: onUndo),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  addTearDown(h.dispose);
  return _Pumped(h, key, drops);
}

Delta _tableDoc() => Delta()
  ..insert('Intro\n')
  ..insert({
    'table': {
      'id': 't1',
      'align': [null, null],
      'rows': [
        ['Name', 'Qty'],
        ['Apples', '3'],
      ],
    },
  })
  ..insert('\n')
  ..insert('Outro\n');

List<List<String>> _rows(Delta delta) {
  for (final op in delta.operations) {
    final data = op.data;
    if (data is Map && data['table'] is Map) {
      return [
        for (final row in (data['table'] as Map)['rows'] as List)
          [for (final c in row as List) '$c'],
      ];
    }
  }
  return const [];
}

Offset _center(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text, findRichText: true).first);

void main() {
  group('Given a table in the document (SE-4 in-place editing)', () {
    testWidgets('when tapping a cell then it becomes a field with its '
        'Markdown source', (tester) async {
      final p = await _pump(tester, _tableDoc());

      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pump();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, 'Apples');
      expect(p.state.tableEditing.active?.row, 1);
      expect(p.state.tableEditing.active?.column, 0);
    });

    testWidgets(
      'when another cell is pressed while editing then editing moves there '
      'without stopping in between',
      (tester) async {
        final p = await _pump(tester, _tableDoc());
        await tester.tapAt(_center(tester, 'Apples'));
        await tester.pumpAndSettle();
        final editing = p.state.tableEditing;
        final stops = <Object?>[];
        void record() {
          if (editing.active == null) stops.add(null);
        }

        editing.addListener(record);
        addTearDown(() => editing.removeListener(record));

        final gesture = await tester.startGesture(
          _center(tester, '3'),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        expect(editing.active?.column, 0);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(editing.active?.row, 1);
        expect(editing.active?.column, 1);
        expect(stops, isEmpty);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets(
      'when a word of a cell is double-clicked then editing starts with the '
      'word selected',
      (tester) async {
        final p = await _pump(tester, _tableDoc());
        final at = _center(tester, 'Apples');
        final gesture = await tester.startGesture(
          at,
          kind: PointerDeviceKind.mouse,
        );
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 40));
        await gesture.down(at);
        await gesture.up();
        await tester.pumpAndSettle();

        expect(p.state.tableEditing.active?.row, 1);
        expect(
          p.state.tableEditing.text.selection,
          const TextSelection(baseOffset: 0, extentOffset: 6),
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('when typing and pressing Tab then the cell is replaced in '
        'one "Edit cell" step and the next cell is edited', (tester) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Pears **ripe**');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_rows(p.h.delta)[1], ['Pears **ripe**', '3']);
      expect(p.h.changes.where((c) => c.label == 'Edit cell'), hasLength(1));
      expect(p.state.tableEditing.active?.column, 1);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller!.text, '3');
    });

    testWidgets('when pressing Tab in the last cell then a row is appended', (
      tester,
    ) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, '3'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_rows(p.h.delta), hasLength(3));
      expect(p.h.changes.last.label, 'Insert row');
      expect(p.state.tableEditing.active?.row, 2);
      expect(p.state.tableEditing.active?.column, 0);
    });

    testWidgets('when pressing Enter in the last row then a row is added '
        'below and Shift+Enter goes back up', (tester) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, '3'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(_rows(p.h.delta), hasLength(3));
      expect(p.state.tableEditing.active?.row, 2);
      expect(p.state.tableEditing.active?.column, 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(p.state.tableEditing.active?.row, 1);
    });

    testWidgets('when pressing Mod+B over the field selection then it is '
        'wrapped in ** and Esc leaves the cell with the table selected', (
      tester,
    ) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pump();
      final field = tester.widget<TextField>(find.byType(TextField));
      field.controller!.selection = const TextSelection(
        baseOffset: 0,
        extentOffset: 6,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(field.controller!.text, '**Apples**');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(_rows(p.h.delta)[1][0], '**Apples**');
      expect(p.state.tableEditing.active, isNull);
      expect(find.byType(TextField), findsNothing);
      expect(p.h.selection, const DeltaSelection(6, 7));
    });

    testWidgets('when a collaborator deletes the table while editing then '
        'editing stops', (tester) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pump();

      p.h.controller.applyRemote(
        Delta()
          ..retain(6)
          ..delete(2),
      );
      await tester.pump();

      expect(p.state.tableEditing.active, isNull);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('when undoing in a clean cell then the document undo runs', (
      tester,
    ) async {
      var undos = 0;
      await _pump(tester, _tableDoc(), onUndo: () => undos += 1);
      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();

      expect(undos, 1);
    });
  });

  group('Given selected text (drag and drop, Write 04 §24)', () {
    testWidgets('when dragging the selection to the end of another '
        'paragraph then the text moves in one "Move text" step', (
      tester,
    ) async {
      final p = await _pump(tester, Delta()..insert('Hello world\nSecond\n'));
      await tester.placeCaretInParagraph(p.h.controller.document.first.id, 0);
      p.h.select(0, 5);
      await tester.pump();

      final from =
          tester.getTopLeft(find.text('Hello world', findRichText: true)) +
          const Offset(12, 8);
      final to = tester.getTopRight(find.text('Second', findRichText: true));
      final gesture = await tester.startGesture(
        from,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(10, 4));
      await tester.pump();
      await gesture.moveTo(to + const Offset(-1, 8));
      await tester.pump();
      expect(p.state.dropIndicator.value, isA<CaretDropSpot>());
      await gesture.up();
      await tester.pump();

      expect(p.h.delta, Delta()..insert(' world\nSecondHello\n'));
      expect(p.h.changes.last.label, 'Move text');
      expect(p.h.selection, const DeltaSelection(13, 18));
      expect(p.state.dropIndicator.value, isNull);
      await tester.pump(const Duration(seconds: 1));
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('when dropping with copy then the original stays', (
      tester,
    ) async {
      final p = await _pump(tester, Delta()..insert('Hello world\n'));

      final ok = p.state.textDrag.drop(
        const DeltaSelection(0, 5),
        11,
        copy: true,
      );

      expect(ok, isTrue);
      expect(p.h.delta, Delta()..insert('Hello worldHello\n'));
      expect(p.h.changes.last.label, 'Copy text');
    });

    testWidgets('when dropping inside the selection itself then nothing '
        'changes', (tester) async {
      final p = await _pump(tester, Delta()..insert('Hello world\n'));

      final ok = p.state.textDrag.drop(const DeltaSelection(0, 5), 3);

      expect(ok, isFalse);
      expect(p.h.delta, Delta()..insert('Hello world\n'));
    });
  });

  group('Given drops from other applications (Write 04 §24)', () {
    testWidgets('when dropping text then it is pasted at the drop '
        'position', (tester) async {
      final p = await _pump(tester, Delta()..insert('Hello\n'));
      final at =
          tester.getTopRight(find.text('Hello', findRichText: true)) +
          const Offset(-1, 8);

      final accepted = p.drops.over!(at, ExternalDragKind.text);
      p.drops.drop!(ExternalDrop(globalPosition: at, plainText: ' world'));
      await tester.pump();

      expect(accepted, isTrue);
      expect(p.h.delta, Delta()..insert('Hello world\n'));
      expect(p.h.changes.last.label, 'Paste');
    });

    testWidgets('when dropping HTML then its formatting is kept', (
      tester,
    ) async {
      final p = await _pump(tester, Delta()..insert('Hello\n'));
      final at = _center(tester, 'Hello');

      p.drops.over!(at, ExternalDragKind.text);
      p.drops.drop!(
        ExternalDrop(globalPosition: at, plainText: 'big', html: '<b>big</b>'),
      );
      await tester.pump();

      expect(
        p.h.delta.operations.any((op) => op.attributes?['bold'] == true),
        isTrue,
      );
    });

    testWidgets('when dropping files then the host gets them with the block '
        'index under the drop line', (tester) async {
      List<DroppedFile>? dropped;
      int? index;
      final p = await _pump(
        tester,
        Delta()..insert('One\nTwo\n'),
        onDropFiles: (files, i) {
          dropped = files;
          index = i;
        },
      );
      final at =
          tester.getTopLeft(find.text('Two', findRichText: true)) +
          const Offset(4, 1);

      expect(p.drops.over!(at, ExternalDragKind.files), isTrue);
      expect(p.state.dropIndicator.value, const BlockDropSpot(1));
      p.drops.drop!(
        ExternalDrop(
          globalPosition: at,
          files: [
            DroppedFile(
              name: 'a.png',
              mimeType: 'image/png',
              bytes: Uint8List(4),
            ),
          ],
        ),
      );

      expect(dropped?.single.extension, 'png');
      expect(index, 1);
    });

    testWidgets('when inserting blocks at a drop index then they become '
        'whole blocks there', (tester) async {
      final p = await _pump(tester, Delta()..insert('One\nTwo\n'));

      p.state.commands.insertBlocksAt(
        2,
        Delta()
          ..insert('New')
          ..insert('\n', {'header': 2}),
        label: 'Insert file',
      );

      expect(
        p.h.delta,
        Delta()
          ..insert('One\nTwo\nNew')
          ..insert('\n', {'header': 2}),
      );
    });
  });

  group('Given the emoji trigger (Write 04 §20.1)', () {
    testWidgets('when typing ":smi" and pressing Enter then the emoji '
        'replaces the query in one step', (tester) async {
      final p = await _pump(
        tester,
        Delta()..insert('\n'),
        emoji: (q) => [
          if ('smile'.startsWith(q))
            const EmojiSuggestion(
              emoji: '😄',
              name: 'grinning face with smiling eyes',
              shortcode: 'smile',
            ),
        ],
      );
      await tester.placeCaretInParagraph(p.h.controller.document.first.id, 0);
      await tester.typeImeText('Hi :smi');
      await tester.pump();
      expect(find.byKey(EmojiMenu.menuKey), findsOneWidget);

      await tester.pressEnter();
      await tester.pump();

      expect(p.h.delta, Delta()..insert('Hi 😄\n'));
      expect(p.h.changes.last.label, 'Insert emoji');
      expect(find.byKey(EmojiMenu.menuKey), findsNothing);
    });

    testWidgets('when typing a time like 10:30 then no emoji menu opens', (
      tester,
    ) async {
      final p = await _pump(
        tester,
        Delta()..insert('\n'),
        emoji: (q) => const [EmojiSuggestion(emoji: '⏰', name: 'alarm')],
      );
      await tester.placeCaretInParagraph(p.h.controller.document.first.id, 0);
      await tester.typeImeText('At 10:30');
      await tester.pump();

      expect(find.byKey(EmojiMenu.menuKey), findsNothing);
    });
  });
}
