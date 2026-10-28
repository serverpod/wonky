import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_write/features/editor/attributions/wonky_attributions.dart';

import '../support/editor_harness.dart';
import 'wonky_editor_test.dart' show pumpEditor;

/// The global box of the character at [offset] in [nodeId].
Rect characterBox(EditorHarness h, String nodeId, int offset) {
  final layout = h.controller.documentLayout!;
  final rect = layout.getRectForSelection(
    DocumentPosition(
      nodeId: nodeId,
      nodePosition: TextNodePosition(offset: offset),
    ),
    DocumentPosition(
      nodeId: nodeId,
      nodePosition: TextNodePosition(offset: offset + 1),
    ),
  )!;
  return rect.shift(layout.getGlobalOffsetFromDocumentOffset(Offset.zero));
}

/// Clicks reach the editor's interactor, which lies below the document
/// content: nothing a component paints may be a hit target of its own.
void main() {
  Future<void> click(WidgetTester tester, Offset at) async {
    await tester.tapAt(at);
    await tester.pump(kTapMinTime + const Duration(milliseconds: 1));
    await tester.pump(kDoubleTapTimeout);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Given a line with a chip and a button when clicking in it then the caret is placed there',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Try ')
          ..insert('Newer', {'chip': true})
          ..insert('! now\nSee ')
          ..insert('Docs', {
            'link': 'https://example.com',
            'linkStyle': 'button',
          })
          ..insert('\n'),
      );
      final first = h.controller.document.first.id;
      final second = h.controller.document.getNodeAt(1)!.id;

      await tester.placeCaretInParagraph(first, 1);
      expect(h.controller.composer.selection?.extent.nodeId, first);

      await tester.placeCaretInParagraph(second, 1);
      expect(
        h.controller.composer.selection?.extent,
        DocumentPosition(
          nodeId: second,
          nodePosition: const TextNodePosition(offset: 1),
        ),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Given a video and an image when clicking them then each is selected',
    (tester) async {
      final h = await pumpEditor(
        tester,
        Delta()
          ..insert('Above\n')
          ..insert({
            'youtube': {'id': 'v1', 'videoId': 'AGAQ_N56wCs'},
          })
          ..insert('\nBetween\n')
          ..insert({
            'image': {
              'id': 'i1',
              'src': 'https://example.com/a.png',
              'alt': 'A',
              'title': 'A title',
            },
          })
          ..insert('\nBelow\n'),
      );
      final video = find.byKey(const ValueKey('write.editor.youtube.v1'));
      final image = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_WonkyImage',
      );

      for (final (finder, id) in [(video, 'v1'), (image, 'i1')]) {
        await click(tester, tester.getCenter(finder));
        final selection = h.controller.composer.selection;
        expect(selection?.base.nodeId, id);
        expect(selection?.isCollapsed, isFalse);
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  for (final (name, attributes, attribution) in [
    ('a chip', {'chip': true}, ChipAttribution.plain as Attribution),
    (
      'a button',
      {'link': 'https://example.com', 'linkStyle': 'button'},
      LinkStyleAttribution.button,
    ),
    (
      'an arrow link',
      {'link': 'https://example.com', 'linkStyle': 'arrow'},
      LinkStyleAttribution.arrow,
    ),
  ]) {
    testWidgets(
      'Given $name at the end of a line when clicking right of it then the '
      'caret is outside it, and on its last glyph inside it (Write 11 §7.4)',
      (tester) async {
        final h = await pumpEditor(
          tester,
          Delta()
            ..insert('See ')
            ..insert('Docs', attributes)
            ..insert('\nNext\n'),
        );
        final id = h.controller.document.first.id;
        final end = DocumentPosition(
          nodeId: id,
          nodePosition: const TextNodePosition(offset: 8),
        );
        final last = characterBox(h, id, 7);
        DocumentPosition caret() => h.controller.composer.selection!.extent;
        bool inside() => h.controller.composer.preferences.currentAttributions
            .contains(attribution);

        await click(tester, Offset(last.right + 30, last.center.dy));
        expect(caret().isEquivalentTo(end), isTrue);
        expect(h.controller.pillBoundary.isOutsideAt(caret()), isTrue);
        expect(inside(), isFalse);

        // On the last glyph's right half, at the same position: inside.
        await click(tester, Offset(last.right - 2, last.center.dy));
        expect(caret().isEquivalentTo(end), isTrue);
        expect(h.controller.pillBoundary.isOutsideAt(caret()), isFalse);
        expect(inside(), isTrue);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    );
  }
}
