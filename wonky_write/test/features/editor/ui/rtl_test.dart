import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/attributions/wonky_attributions.dart';

import '../support/editor_harness.dart';
import 'wonky_editor_test.dart' show pumpEditor;

Map<String, dynamic> _cell(String row) => {
  'cell': {'table': 't1', 'row': row},
};

const _grid = {
  'grid': {'id': 'g1', 'columns': 3, 'bullets': 'check'},
};

/// Arabic blocks of every kind, a table, a grid and an English quote.
Delta _doc() => Delta()
  ..insert('مرحبا بالعالم\n')
  ..insert('عنوان')
  ..insert('\n', {'header': 2, 'step': 3})
  ..insert('بند أول')
  ..insert('\n', {'list': 'bullet'})
  ..insert('مهمة')
  ..insert('\n', {'list': 'unchecked'})
  ..insert('اقتباس')
  ..insert('\n', {'blockquote': true})
  ..insert('English quote')
  ..insert('\n', {'blockquote': true})
  ..insert('الاسم')
  ..insert('\n', _cell('r0'))
  ..insert('الكمية')
  ..insert('\n', _cell('r0'))
  ..insert('تفاح')
  ..insert('\n', _cell('r1'))
  ..insert('\n', _cell('r1'))
  ..insert('واحد')
  ..insert('\n', _grid)
  ..insert('اثنان')
  ..insert('\n', _grid)
  ..insert('ثلاثة')
  ..insert('\n', _grid)
  ..insert('English line\n');

/// The node of the [index]th text block.
TextNode _node(EditorHarness h, int index) =>
    h.controller.document.toList()[index] as TextNode;

/// The global bounds of [node]'s component.
Rect _box(EditorHarness h, DocumentNode node) {
  final component = h.controller.documentLayout!.getComponentByNodeId(node.id)!;
  final box = component.context.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// The global caret rect at [offset] in [node].
Rect _caret(EditorHarness h, DocumentNode node, int offset) {
  final layout = h.controller.documentLayout!;
  final rect = layout.getRectForPosition(
    DocumentPosition(
      nodeId: node.id,
      nodePosition: TextNodePosition(offset: offset),
    ),
  )!;
  return rect.shift(layout.getGlobalOffsetFromDocumentOffset(Offset.zero));
}

TextNodePosition _extent(EditorHarness h) =>
    h.controller.composer.selection!.extent.nodePosition as TextNodePosition;

Future<void> _tapAt(
  WidgetTester tester,
  EditorHarness h,
  DocumentNode node,
  int offset,
) async {
  await tester.tapAt(_caret(h, node, offset).center);
  await tester.pumpAndSettle();
  // Not a double click with the next tap.
  await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
}

void main() {
  group('Given right-to-left blocks (Write 04 §38)', () {
    testWidgets('when laid out then text, list markers, checkboxes, quote '
        'bars and step badges are on the right', (tester) async {
      final h = await pumpEditor(tester, _doc());
      final paragraph = _node(h, 0);
      final column = _box(h, paragraph);

      // The paragraph starts at the right edge.
      expect(_caret(h, paragraph, 0).left, closeTo(column.right, 2));

      // The heading's text starts left of its step badge.
      final heading = _node(h, 1);
      final badge = tester.getRect(
        find.byKey(ValueKey('write.editor.step.${heading.id}')),
      );
      expect(badge.right, closeTo(column.right, 2));
      expect(_caret(h, heading, 0).left, lessThan(badge.left));

      // The bullet item's text starts left of its marker.
      final item = _node(h, 2);
      expect(_caret(h, item, 0).left, lessThan(column.right - 10));

      // The checkbox is right of the task's text.
      final task = _node(h, 3);
      final checkbox = tester.getRect(find.byType(Checkbox));
      expect(checkbox.center.dx, greaterThan(_caret(h, task, 0).left));
      expect(checkbox.right, closeTo(column.right, 18));

      // The Arabic quote is indented from the right, the English one from
      // the left.
      final quote = _node(h, 4);
      expect(_box(h, quote).right, lessThan(column.right - 8));
      expect(_box(h, quote).left, closeTo(column.left, 1));
      final english = _node(h, 5);
      expect(_box(h, english).left, greaterThan(column.left + 8));
      expect(_box(h, english).right, closeTo(column.right, 1));

      // The English line is unaffected.
      final last = h.controller.document.last;
      expect(_caret(h, last, 0).left, closeTo(column.left, 2));
    });

    testWidgets(
      'when pressing ← and → then the caret moves visually, also by word '
      'and with Shift',
      (tester) async {
        final h = await pumpEditor(tester, _doc());
        final paragraph = _node(h, 0);
        await _tapAt(tester, h, paragraph, 2);
        expect(_extent(h).offset, 2);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(_extent(h).offset, 3);
        expect(
          _caret(h, paragraph, 3).left,
          lessThan(_caret(h, paragraph, 2).left),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(_extent(h).offset, 1);

        // ⌥← to the end of the word (visually left).
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.pump();
        expect(_extent(h).offset, 'مرحبا'.length);

        // ⇧← extends the selection forward.
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        final s = h.controller.composer.selection!;
        expect((s.base.nodePosition as TextNodePosition).offset, 5);
        expect(_extent(h).offset, 6);

        // ⌘← to the line's visual left end (its logical end), ⌘→ back.
        await _tapAt(tester, h, paragraph, 2);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        expect(_extent(h).offset, paragraph.text.length);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await tester.pump();
        expect(_extent(h).offset, 0);

        // In the English line ← still moves back.
        final last = h.controller.document.last;
        await _tapAt(tester, h, last, 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(_extent(h).offset, 2);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('when pressing ← at the visual left end then the caret moves '
        'to the next block', (tester) async {
      final h = await pumpEditor(tester, _doc());
      final paragraph = _node(h, 0);
      final length = paragraph.text.length;
      await _tapAt(tester, h, paragraph, length);
      expect(_extent(h).offset, length);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      final s = h.controller.composer.selection!;
      expect(s.extent.nodeId, _node(h, 1).id);
      expect(_extent(h).offset, 0);
    });
  });

  group('Given a chip at the end of a right-to-left line (Write 11 §7.4)', () {
    Future<EditorHarness> pumpChip(WidgetTester tester) => pumpEditor(
      tester,
      Delta()
        ..insert('انظر ')
        ..insert('وثائق', {'chip': true})
        ..insert('\nEnglish line\n'),
    );
    const end = 'انظر وثائق'.length;
    bool inside(EditorHarness h) => h
        .controller
        .composer
        .preferences
        .currentAttributions
        .contains(ChipAttribution.plain);
    bool outside(EditorHarness h) => h.controller.pillBoundary.isOutsideAt(
      h.controller.composer.selection!.extent,
    );

    testWidgets('when clicking left of it then the caret is outside it', (
      tester,
    ) async {
      final h = await pumpChip(tester);
      final line = _node(h, 0);
      final last = _caret(h, line, end);
      await tester.tapAt(Offset(last.left - 30, last.center.dy));
      await tester.pumpAndSettle();
      expect(_extent(h).offset, end);
      expect(outside(h), isTrue);
      expect(inside(h), isFalse);
    });

    testWidgets(
      'when pressing ← at its end then the caret moves out of it, → back in',
      (tester) async {
        final h = await pumpChip(tester);
        h.controller.focusNode.requestFocus();
        h.controller.select(DeltaSelection.collapsed(end));
        await tester.pump();
        expect(inside(h), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        expect(_extent(h).offset, end);
        expect(outside(h), isTrue);
        expect(inside(h), isFalse);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(_extent(h).offset, end);
        expect(outside(h), isFalse);
        expect(inside(h), isTrue);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  });

  group('Given a right-to-left table and grid (Write 12 §3.10)', () {
    testWidgets('when laid out then column 0 is on the right and cells are '
        'right aligned, also an empty one', (tester) async {
      final h = await pumpEditor(tester, _doc());
      final name = _node(h, 6);
      final qty = _node(h, 7);
      final apples = _node(h, 8);
      final empty = _node(h, 9);
      expect(_box(h, name).left, greaterThan(_box(h, qty).right - 1));
      expect(_box(h, apples).left, closeTo(_box(h, name).left, 1));
      // Text starts at the cell's right (the box is inside its padding).
      expect(_caret(h, name, 0).left, closeTo(_box(h, name).right, 2));
      expect(_caret(h, empty, 0).left, closeTo(_box(h, empty).right, 2));
      // The table is as wide as the text column.
      final column = _box(h, _node(h, 0));
      expect(_box(h, name).right, closeTo(column.right - 8, 1));
      expect(_box(h, qty).left, closeTo(column.left + 8, 1));
    });

    testWidgets('when pressing Tab then the next cell (on the left) is '
        'selected', (tester) async {
      final h = await pumpEditor(tester, _doc());
      final name = _node(h, 6);
      await _tapAt(tester, h, name, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      final s = h.controller.composer.selection!;
      expect(s.extent.nodeId, _node(h, 7).id);
    });

    testWidgets('when the grid is laid out then it flows from the right with '
        'its bullets on the right', (tester) async {
      final h = await pumpEditor(tester, _doc());
      final one = _node(h, 10);
      final two = _node(h, 11);
      final three = _node(h, 12);
      expect(_box(h, one).left, greaterThan(_box(h, two).right));
      expect(_box(h, two).left, greaterThan(_box(h, three).right));
      // The bullet's room is right of the text.
      final column = _box(h, _node(h, 0));
      expect(_caret(h, one, 0).left, lessThan(column.right - 15));
      expect(_caret(h, one, 0).left, greaterThan(column.right - 40));
    });

    testWidgets('when its first cell gets Arabic text then the table is laid '
        'out right to left', (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('مرحبا\n')
          ..insert('\n', _cell('r0'))
          ..insert('\n', _cell('r0'))
          ..insert('End\n'),
      );
      final a = _node(h, 1);
      final b = _node(h, 2);
      // No strong characters: the document's direction (left to right).
      expect(_box(h, a).right, lessThan(_box(h, b).left + 1));

      h.controller.select(DeltaSelection.collapsed('مرحبا\n'.length));
      await tester.pump();
      h.controller.editor.execute([
        InsertTextRequest(
          documentPosition: DocumentPosition(
            nodeId: a.id,
            nodePosition: const TextNodePosition(offset: 0),
          ),
          textToInsert: 'نص',
          attributions: const {},
        ),
      ]);
      await tester.pumpAndSettle();
      expect(_box(h, a).left, greaterThan(_box(h, b).right - 1));
      // The empty cell follows the table.
      expect(_caret(h, b, 0).left, closeTo(_box(h, b).right, 2));
    });
  });

  testWidgets('Given a table in a wide window then it is no wider than the '
      'text column', (tester) async {
    final h = await pumpEditor(
      tester,
      Delta()
        ..insert('Para\n')
        ..insert('A')
        ..insert('\n', _cell('r0'))
        ..insert('B')
        ..insert('\n', _cell('r0'))
        ..insert('End\n'),
    );
    final column = _box(h, _node(h, 0));
    expect(column.width, lessThan(1100));
    // The cells' boxes are inside their 8 px padding.
    expect(_box(h, _node(h, 1)).left, closeTo(column.left + 8, 1));
    expect(_box(h, _node(h, 2)).right, closeTo(column.right - 8, 1));
  });
}
