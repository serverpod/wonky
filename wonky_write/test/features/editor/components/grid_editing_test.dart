import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show CellGrid, CellRuns, DocumentLine, MarkdownFlavor, WonkyDocument;

import '../support/editor_harness.dart';
import '../ui/wonky_editor_test.dart' show pumpEditor;

/// A paragraph, a grid of three items in three columns and a paragraph.
Delta _gridDoc() {
  const grid = {
    'grid': {'id': 'g1', 'columns': 3, 'bullets': 'check'},
  };
  return Delta()
    ..insert('Above\n')
    ..insert('One')
    ..insert('\n', grid)
    ..insert('Two')
    ..insert('\n', grid)
    ..insert('Three')
    ..insert('\n', grid)
    ..insert('Below\n');
}

List<String> _items(EditorHarness h) {
  final grid = CellRuns.grid(WonkyDocument(h.delta), 'g1');
  return [for (final l in grid?.items ?? const <DocumentLine>[]) l.text];
}

String _caretText(EditorHarness h) {
  final s = h.controller.composer.selection!;
  final node = h.controller.document.getNodeById(s.extent.nodeId)! as TextNode;
  return node.text.toPlainText();
}

Offset _center(WidgetTester tester, String text) =>
    tester.getCenter(find.text(text, findRichText: true).first);

void main() {
  group('Given a grid of item lines (Write 12 §1.2)', () {
    testWidgets('when it is laid out then the items flow side by side', (
      tester,
    ) async {
      final h = await pumpEditor(tester, _gridDoc());
      h.controller.markdownFlavor = () => MarkdownFlavor.wonky;
      final one = _center(tester, 'One');
      final two = _center(tester, 'Two');
      final three = _center(tester, 'Three');
      expect(two.dy, closeTo(one.dy, 1));
      expect(three.dy, closeTo(one.dy, 1));
      expect(two.dx, greaterThan(one.dx + 50));
      expect(three.dx, greaterThan(two.dx + 50));
      expect(_center(tester, 'Below').dy, greaterThan(one.dy + 5));
    });

    testWidgets(
      'when clicking an item then the caret is there and double-clicking '
      'selects its word',
      (tester) async {
        final h = await pumpEditor(tester, _gridDoc());
        await tester.tapAt(
          _center(tester, 'Two'),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
        expect(_caretText(h), 'Two');

        // The middle of "Three"'s third character.
        final three = h.controller.document.firstWhere(
          (n) => n is TextNode && n.text.toPlainText() == 'Three',
        );
        final layout = h.controller.documentLayout!;
        final at = layout.getGlobalOffsetFromDocumentOffset(
          layout
              .getRectForPosition(
                DocumentPosition(
                  nodeId: three.id,
                  nodePosition: const TextNodePosition(offset: 2),
                ),
              )!
              .center,
        );
        await tester.tapAt(at, kind: PointerDeviceKind.mouse);
        await tester.pump(const Duration(milliseconds: 40));
        await tester.tapAt(at, kind: PointerDeviceKind.mouse);
        await tester.pumpAndSettle();
        final s = h.controller.composer.selection!;
        expect(_caretText(h), 'Three');
        expect((s.base.nodePosition as TextNodePosition).offset, 0);
        expect((s.extent.nodePosition as TextNodePosition).offset, 5);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );

    testWidgets('when pressing Enter in an item then the next item is added, '
        'and Backspace in an empty item removes it (AC-12.7)', (tester) async {
      final h = await pumpEditor(tester, _gridDoc());
      h.controller.select(DeltaSelection.collapsed('Above\nOne'.length));
      await tester.pump();

      h.controller.editor.execute([
        InsertNewlineAtCaretRequest(Editor.createNodeId()),
      ]);
      await tester.pumpAndSettle();
      expect(_items(h), ['One', '', 'Two', 'Three']);
      expect(_caretText(h), '');

      h.controller.editor.execute([const DeleteUpstreamRequest()]);
      await tester.pumpAndSettle();
      expect(_items(h), ['One', 'Two', 'Three']);
      expect(_caretText(h), 'One');
    });

    testWidgets('when pressing Enter in the empty last item then it leaves '
        'the grid', (tester) async {
      final h = await pumpEditor(tester, _gridDoc());
      h.controller.select(
        DeltaSelection.collapsed('Above\nOne\nTwo\nThree'.length),
      );
      await tester.pump();
      h.controller.editor.execute([
        InsertNewlineAtCaretRequest(Editor.createNodeId()),
      ]);
      await tester.pumpAndSettle();
      expect(_items(h), ['One', 'Two', 'Three', '']);

      h.controller.editor.execute([
        InsertNewlineAtCaretRequest(Editor.createNodeId()),
      ]);
      await tester.pumpAndSettle();
      expect(_items(h), ['One', 'Two', 'Three']);
      final grid = CellRuns.of(WonkyDocument(h.delta)).single as CellGrid;
      expect(h.delta.toList().last.data, '\nBelow\n');
      expect(grid.items, hasLength(3));
    });

    testWidgets('when pressing Tab then the next item is selected and Tab in '
        'the last item appends one', (tester) async {
      final h = await pumpEditor(tester, _gridDoc());
      await tester.tapAt(_center(tester, 'Two'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_caretText(h), 'Three');
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(_items(h), ['One', 'Two', 'Three', '']);
      expect(_caretText(h), '');
    });
  });
}
