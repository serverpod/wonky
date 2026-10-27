import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/grid/inline_grid_editing.dart';
import 'package:wonky_write/features/editor/styles/editor_theme.dart';
import 'package:wonky_write_core/wonky_write_core.dart' show MarkdownFlavor;

import '../ui/wonky_editor_test.dart' show pumpEditor;

Finder _item(int i) => find.byKey(ValueKey('write.editor.gridItem.g1.$i'));

void main() {
  testWidgets(
    'Given an item being edited when another item is pressed then editing '
    'moves there without stopping in between',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Above\n')
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 3,
              'items': ['One', 'Two', 'Three'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final editing = h.controller.gridEditing!;
      expect(editing.activate('g1', 0), isTrue);
      await tester.pumpAndSettle();
      final selection = h.controller.selection;

      final states = <GridItemRef?>[];
      void record() => states.add(editing.active);
      editing.addListener(record);
      addTearDown(() => editing.removeListener(record));

      final gesture = await tester.startGesture(
        tester.getCenter(_item(1)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      // Pressed, not released: the first item is still being edited.
      expect(editing.active, const GridItemRef('g1', 0));
      expect(h.controller.selection, selection);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(editing.active, const GridItemRef('g1', 1));
      expect(states, isNot(contains(null)));
      expect(h.controller.selection, selection);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Given an item being edited when a word is double-clicked then it is '
    'selected',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 1,
              'items': ['Alpha Beta Gamma'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final editing = h.controller.gridEditing!;
      expect(editing.activate('g1', 0), isTrue);
      await tester.pumpAndSettle();

      final field = find.byType(TextField);
      final box = tester.getRect(field);
      // "Beta": a little right of the field's middle third's start.
      final at = Offset(box.left + box.width * 0.0 + 50, box.center.dy);
      final gesture = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.down(at);
      await gesture.up();
      await tester.pumpAndSettle();

      final s = editing.text.selection;
      // ignore: avoid_print
      print('selection $s of "${editing.text.text}"');
      expect(s.isCollapsed, isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Given a grid not being edited when a word of an item is double-clicked '
    'then editing starts with that word selected',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 1,
              'items': ['Alpha Beta Gamma'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final editing = h.controller.gridEditing!;
      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('Alpha Beta Gamma', findRichText: true),
      );
      // In "Beta" (offsets 6–10).
      final at = paragraph.localToGlobal(
        paragraph.getOffsetForCaret(const TextPosition(offset: 8), Rect.zero) +
            Offset(0, paragraph.size.height / 2),
      );

      final gesture = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 40));
      expect(editing.active, const GridItemRef('g1', 0));
      await gesture.down(at);
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        editing.text.selection,
        const TextSelection(baseOffset: 6, extentOffset: 10),
      );

      // A fast double click: the second click lands before the field is
      // built, on the rendered item (here: another item, then back).
      editing.deactivate();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      // (Later than the clicks above: a new series.)
      final fast = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await fast.down(at, timeStamp: const Duration(seconds: 10));
      await fast.up(timeStamp: const Duration(seconds: 10, milliseconds: 10));
      await fast.down(
        at,
        timeStamp: const Duration(seconds: 10, milliseconds: 20),
      );
      await fast.up(timeStamp: const Duration(seconds: 10, milliseconds: 30));
      await tester.pumpAndSettle();

      expect(
        editing.text.selection,
        const TextSelection(baseOffset: 6, extentOffset: 10),
      );
      // The editor's selection color, not Material's.
      final theme = TextSelectionTheme.of(
        tester.element(find.byType(EditableText)),
      );
      expect(
        theme.selectionColor,
        EditorTheme.fallback(Brightness.light).selectionColor,
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Given the caret in the text when an item is clicked then the grid '
    'becomes the selection only once its field has the focus',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Above\n')
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 2,
              'items': ['Alpha', 'Beta'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      await tester.placeCaretInParagraph(h.controller.document.first.id, 2);
      await tester.pump(const Duration(milliseconds: 400));
      expect(h.controller.focusNode.hasPrimaryFocus, isTrue);

      // Selecting the grid while the editor still had the focus let the
      // editor take the text input back from the field.
      final editorFocusedAtSelection = <bool>[];
      void record() {
        final s = h.controller.selection;
        if (s != null && !s.isCollapsed) {
          editorFocusedAtSelection.add(h.controller.focusNode.hasPrimaryFocus);
        }
      }

      h.controller.addListener(record);
      addTearDown(() => h.controller.removeListener(record));

      final gesture = await tester.startGesture(
        tester.getCenter(_item(1)),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(h.controller.gridEditing!.focusNode.hasFocus, isTrue);
      expect(editorFocusedAtSelection, isNotEmpty);
      expect(editorFocusedAtSelection, everyElement(isFalse));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Given an unsaved item when the editor is disposed then the edit is '
    'saved without errors',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 1,
              'items': ['Alpha'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      h.controller.gridEditing!.activate('g1', 0);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Alpha more');
      await tester.pump();

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
      final grid = (h.delta.operations.first.data! as Map)['grid'] as Map;
      expect(grid['items'], ['Alpha more']);
    },
  );

  testWidgets(
    'Given an item being edited when its field is clicked then the editor '
    'neither moves its caret nor takes the focus',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Above\n')
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 2,
              'items': ['Alpha beta', 'Gamma'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final editing = h.controller.gridEditing!;
      final first = await tester.startGesture(
        tester.getCenter(_item(0)),
        kind: PointerDeviceKind.mouse,
      );
      await first.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));
      final selection = h.controller.selection;
      expect(selection?.isCollapsed, isFalse);

      // The left half of the grid: the editor would put its caret before it.
      final field = tester.getRect(find.byType(TextField));
      final click = await tester.startGesture(
        Offset(field.left + 4, field.center.dy),
        kind: PointerDeviceKind.mouse,
      );
      await click.up();
      await tester.pumpAndSettle();

      expect(editing.active, const GridItemRef('g1', 0));
      expect(editing.focusNode.hasFocus, isTrue);
      expect(h.controller.selection, selection);
      expect(editing.text.selection.baseOffset, lessThan(3));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Given an item being edited when it is triple-clicked then its text is '
    'selected',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert({
            'grid': {
              'id': 'g1',
              'columns': 1,
              'items': ['Alpha Beta Gamma'],
            },
          })
          ..insert('\nBelow\n'),
      );
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final editing = h.controller.gridEditing!;
      expect(editing.activate('g1', 0), isTrue);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 400));

      final field = tester.getRect(find.byType(TextField));
      final at = Offset(field.left + 30, field.center.dy);
      final gesture = await tester.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      for (var i = 0; i < 2; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        await gesture.down(at);
        await gesture.up();
      }
      await tester.pumpAndSettle();

      expect(
        editing.text.selection,
        const TextSelection(baseOffset: 0, extentOffset: 16),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
