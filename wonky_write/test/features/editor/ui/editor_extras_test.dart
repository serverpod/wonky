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
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellRuns, WonkyDocument;

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

/// A paragraph, a 2×2 table of cell lines and a paragraph.
Delta _tableDoc() {
  Map<String, dynamic> cell(String row) => {
    'cell': {'table': 't1', 'row': row},
  };
  return Delta()
    ..insert('Intro\n')
    ..insert('Name')
    ..insert('\n', cell('r0'))
    ..insert('Qty')
    ..insert('\n', cell('r0'))
    ..insert('Apples')
    ..insert('\n', cell('r1'))
    ..insert('3')
    ..insert('\n', cell('r1'))
    ..insert('Outro\n');
}

/// The table's cell texts, row by row.
List<List<String>> _rows(Delta delta) {
  final t = CellRuns.table(WonkyDocument(delta), 't1');
  if (t == null) return const [];
  return [
    for (final r in t.rows) [for (final c in r.cells) c.text],
  ];
}

/// The text of the node with the caret and the caret's offset in it.
(String, int, int) _caret(EditorHarness h) {
  final s = h.controller.composer.selection!;
  final node = h.controller.document.getNodeById(s.extent.nodeId)! as TextNode;
  return (
    node.text.toPlainText(),
    (s.base.nodePosition as TextNodePosition).offset,
    (s.extent.nodePosition as TextNodePosition).offset,
  );
}

Offset _center(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text, findRichText: true).first);

void main() {
  group('Given a table of cell lines (Write 12)', () {
    testWidgets('when it is laid out then the cells of a row are side by side '
        'and the rows stacked', (tester) async {
      await _pump(tester, _tableDoc());
      final name = _center(tester, 'Name');
      final qty = _center(tester, 'Qty');
      final apples = _center(tester, 'Apples');
      expect(qty.dy, closeTo(name.dy, 1));
      expect(qty.dx, greaterThan(name.dx + 50));
      expect(apples.dy, greaterThan(name.dy + 5));
      expect(apples.dx, closeTo(name.dx, 30));
    });

    testWidgets('when clicking a word in a cell then the caret is there, and '
        'double-clicking another word of that cell selects it (AC-12.1)', (
      tester,
    ) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(
        _center(tester, 'Apples'),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
      expect(_caret(p.h).$1, 'Apples');

      // Another word of the same cell, while the caret is in it.
      p.h.controller.applyRemote(
        Delta()
          ..retain('Intro\nName\nQty\nApples'.length)
          ..insert(' and pears'),
      );
      await tester.pumpAndSettle();
      final s = p.h.controller.composer.selection!;
      final layout = p.h.controller.documentLayout!;
      final rect = layout.getRectForPosition(
        DocumentPosition(
          nodeId: s.extent.nodeId,
          nodePosition: const TextNodePosition(offset: 13),
        ),
      )!;
      final at = layout.getGlobalOffsetFromDocumentOffset(rect.center);
      await tester.tapAt(at, kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 40));
      await tester.tapAt(at, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(_caret(p.h), ('Apples and pears', 11, 16));
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets(
      'when dragging from inside one cell into the next then the selection '
      'runs from the drag start to its end',
      (tester) async {
        final p = await _pump(tester, _tableDoc());
        final layout = p.h.controller.documentLayout!;
        Offset at(String text, int offset) {
          final node = p.h.controller.document.firstWhere(
            (n) => n is TextNode && n.text.toPlainText() == text,
          );
          return layout.getGlobalOffsetFromDocumentOffset(
            layout
                .getRectForPosition(
                  DocumentPosition(
                    nodeId: node.id,
                    nodePosition: TextNodePosition(offset: offset),
                  ),
                )!
                .center,
          );
        }

        final from = at('Name', 2);
        final to = at('Qty', 1);
        final gesture = await tester.startGesture(
          from,
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump();
        // A hand moves a few pixels first: the drag starts where it is
        // recognized (beyond the 2 px mouse slop).
        await gesture.moveTo(from + const Offset(0, 3));
        await tester.pump(const Duration(milliseconds: 16));
        for (var i = 1; i <= 10; i++) {
          await gesture.moveTo(Offset.lerp(from, to, i / 10)!);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();
        final s = p.h.controller.composer.selection!;
        final doc = p.h.controller.document;
        expect(
          (doc.getNodeById(s.base.nodeId)! as TextNode).text.toPlainText(),
          'Name',
        );
        expect((s.base.nodePosition as TextNodePosition).offset, 2);
        expect(
          (doc.getNodeById(s.extent.nodeId)! as TextNode).text.toPlainText(),
          'Qty',
        );
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('when clicking below a short cell then the caret goes into '
        'that cell', (tester) async {
      final p = await _pump(
        tester,
        _tableDoc().compose(
          Delta()
            ..retain('Intro\nName\n'.length)
            ..insert(
              'A long header that wraps over several lines in its column '
              'so the row is much taller than the first cell ',
            ),
        ),
      );
      final name = tester.getRect(find.text('Name', findRichText: true).first);
      await tester.tapAt(Offset(name.center.dx, name.bottom + 30));
      await tester.pumpAndSettle();
      expect(_caret(p.h).$1, 'Name');
    });

    testWidgets('when typing in a cell then the text goes into that cell', (
      tester,
    ) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pumpAndSettle();
      p.h.controller.select(
        DeltaSelection.collapsed('Intro\nName\nQty\nApples'.length),
      );
      await tester.typeImeText('!');
      await tester.pumpAndSettle();
      expect(_rows(p.h.delta), [
        ['Name', 'Qty'],
        ['Apples!', '3'],
      ]);
    });

    testWidgets('when pressing Tab then the next cell is selected and Tab in '
        'the last cell appends a row (AC-12.2)', (tester) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, 'Apples'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_caret(p.h), ('3', 0, 1));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_rows(p.h.delta), [
        ['Name', 'Qty'],
        ['Apples', '3'],
        ['', ''],
      ]);
      expect(_caret(p.h), ('', 0, 0));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(_caret(p.h), ('3', 0, 1));
    });

    testWidgets('when pressing ↑ and ↓ then the caret keeps its column', (
      tester,
    ) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, '3'));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_caret(p.h).$1, 'Qty');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_caret(p.h).$1, 'Intro');

      await tester.tapAt(_center(tester, 'Name'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_caret(p.h).$1, 'Apples');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_caret(p.h).$1, 'Outro');
    });

    testWidgets('when pressing Enter in a cell then the caret goes to the cell '
        'below, and in the last row a row is added', (tester) async {
      final p = await _pump(tester, _tableDoc());
      await tester.tapAt(_center(tester, 'Qty'));
      await tester.pumpAndSettle();

      p.h.controller.editor.execute([
        InsertNewlineAtCaretRequest(Editor.createNodeId()),
      ]);
      await tester.pumpAndSettle();
      expect(_caret(p.h).$1, '3');

      p.h.controller.editor.execute([
        InsertNewlineAtCaretRequest(Editor.createNodeId()),
      ]);
      await tester.pumpAndSettle();
      expect(_rows(p.h.delta), hasLength(3));
      expect(_rows(p.h.delta)[2], ['', '']);
      expect(_caret(p.h), ('', 0, 0));
    });

    testWidgets('when deleting a selection across cells then their text is '
        'cleared, the shape stays and undo restores it (AC-12.3)', (
      tester,
    ) async {
      final p = await _pump(tester, _tableDoc());
      // From "Na|me" to "App|les".
      p.h.controller.select(
        DeltaSelection('Intro\nNa'.length, 'Intro\nName\nQty\nApp'.length),
      );
      await tester.pump();

      p.h.controller.editor.execute([
        const DeleteSelectionRequest(TextAffinity.downstream),
      ]);
      await tester.pumpAndSettle();
      expect(_rows(p.h.delta), [
        ['Na', ''],
        ['les', '3'],
      ]);
      expect(_caret(p.h), ('Na', 2, 2));

      expect(p.h.changes, hasLength(1));
      p.h.undo(p.h.changes.last);
      await tester.pumpAndSettle();
      expect(_rows(p.h.delta), [
        ['Name', 'Qty'],
        ['Apples', '3'],
      ]);
    });

    testWidgets('when pressing Backspace at the start of a cell then the '
        'caret goes to the previous cell without merging', (tester) async {
      final p = await _pump(tester, _tableDoc());
      p.h.controller.select(
        DeltaSelection.collapsed('Intro\nName\nQty\n'.length),
      );
      await tester.pump();

      p.h.controller.editor.execute([const DeleteUpstreamRequest()]);
      await tester.pumpAndSettle();
      expect(_rows(p.h.delta), [
        ['Name', 'Qty'],
        ['Apples', '3'],
      ]);
      expect(_caret(p.h), ('Qty', 3, 3));
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
