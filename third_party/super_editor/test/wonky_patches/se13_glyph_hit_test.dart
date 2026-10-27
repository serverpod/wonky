import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

// WONKY PATCH SE-13: a click splits a character at the middle of its glyph,
// not of the glyph and its letter spacing.
void main() {
  group('SuperEditor hit testing with letter spacing (SE-13)', () {
    testWidgetsOnMac('a click right of the glyph middle, inside the spacing box middle, lands after the character',
        (tester) async {
      await tester //
          .createDocument()
          .fromMarkdown('See **Docs** now')
          .useStylesheet(defaultStylesheet.copyWith(
            inlineTextStyler: (attributions, style) =>
                attributions.contains(boldAttribution) ? style.copyWith(letterSpacing: 20) : style,
          ))
          .pump();
      final nodeId = SuperEditorInspector.findDocument()!.first.id;
      final layout = SuperEditorInspector.findDocumentLayout();
      final component = layout.getComponentByNodeId(nodeId)!;
      // "s", the last bold character (offset 7), with 20 px of spacing after it.
      final box = component.getRectForSelection(
        const TextNodePosition(offset: 7),
        const TextNodePosition(offset: 8),
      );
      final glyphMiddle = box.left + (box.width - 20) / 2;
      final y = box.center.dy;

      TextNodePosition at(double x) => component.getPositionAtOffset(Offset(x, y))! as TextNodePosition;

      expect(at(glyphMiddle - 1).offset, 7);
      expect(at(glyphMiddle + 1).offset, 8);
      // On the spacing, left of the box middle: still after the character.
      expect(at(box.center.dx - 1).offset, 8);
    });
  });
}
