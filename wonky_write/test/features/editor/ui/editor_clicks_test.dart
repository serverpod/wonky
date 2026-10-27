import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

import 'wonky_editor_test.dart' show pumpEditor;

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
}
