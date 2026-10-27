import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/attributions/wonky_attributions.dart';
import 'package:wonky_write/features/editor/reactions/pill_boundary.dart';

void main() {
  group('Given a caret at the end of an inline element', () {
    // A caret 12 px high: 10 px font, so 1 em is 10 px (SE-11).
    const caret = Rect.fromLTWH(100, 0, 0, 12);
    late PillBoundary boundary;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      boundary = PillBoundary();
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      boundary.dispose();
    });

    (Document, DocumentPosition) docWith(Attribution a) {
      final text = AttributedText('See Docs now')
        ..addAttribution(a, const SpanRange(4, 7));
      final doc = MutableDocument(
        nodes: [ParagraphNode(id: 'p', text: text)],
      );
      return (
        doc,
        const DocumentPosition(
          nodeId: 'p',
          nodePosition: TextNodePosition(offset: 8),
        ),
      );
    }

    for (final (name, attribution, gap) in [
      ('a chip', ChipAttribution.plain, PillGapAttribution.pill.em),
      ('a button', LinkStyleAttribution.button, PillGapAttribution.pill.em),
      (
        'an arrow link',
        LinkStyleAttribution.arrow,
        PillGapAttribution.arrow.em,
      ),
    ]) {
      test('of $name, inside it, then the caret is drawn after the last '
          'glyph, before the gap', () {
        final (doc, position) = docWith(attribution);

        expect(boundary.caretRect(doc, position, caret).left, 100 - 10 * gap);
      });

      test('of $name, outside it, then the caret is after the gap', () {
        final (doc, position) = docWith(attribution);
        boundary.leaveAt(position);

        // A pill's edge is 0.05 em short of the gap's end: 0.1 em of room.
        expect(
          boundary.caretRect(doc, position, caret).left,
          attribution == LinkStyleAttribution.arrow ? 100 : 101,
        );
      });
    }

    for (final (name, attribution) in [
      ('a chip', ChipAttribution.plain),
      ('a button', LinkStyleAttribution.button),
    ]) {
      test('at the start of $name after a space then the caret is drawn '
          'before the pill (before the space\'s gap)', () {
        final (doc, _) = docWith(attribution);
        const start = DocumentPosition(
          nodeId: 'p',
          nodePosition: TextNodePosition(offset: 4),
        );

        expect(
          boundary.caretRect(doc, start, caret).left,
          closeTo(100 - 10 * (PillGapAttribution.space.em + 0.1), 1e-9),
        );
      });
    }

    test('at the start of an arrow link then the caret stays (no pill)', () {
      final (doc, _) = docWith(LinkStyleAttribution.arrow);
      const start = DocumentPosition(
        nodeId: 'p',
        nodePosition: TextNodePosition(offset: 4),
      );

      expect(boundary.caretRect(doc, start, caret), caret);
    });

    test('of plain text then the caret stays where it is', () {
      final doc = MutableDocument(
        nodes: [ParagraphNode(id: 'p', text: AttributedText('See Docs now'))],
      );
      const position = DocumentPosition(
        nodeId: 'p',
        nodePosition: TextNodePosition(offset: 8),
      );

      expect(boundary.caretRect(doc, position, caret), caret);
    });
  });
}
