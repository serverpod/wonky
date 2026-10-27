import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_runners/flutter_test_runners.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

// WONKY PATCH SE-11: the caret spans the characters next to it.
void main() {
  group('SuperEditor caret height (SE-11)', () {
    final stylesheet = defaultStylesheet.copyWith(
      addRulesAfter: [
        StyleRule(BlockSelector.all, (doc, node) {
          return {
            Styles.textStyle: const TextStyle(fontSize: 16, height: 1.6),
          };
        }),
      ],
    );

    for (final offset in [0, 5, 11]) {
      testWidgetsOnMac('with a line height of 1.6 the caret at $offset spans the text, not the line box',
          (tester) async {
        await tester //
            .createDocument()
            .fromMarkdown('Hello world')
            .useStylesheet(stylesheet)
            .pump();
        final nodeId = SuperEditorInspector.findDocument()!.first.id;
        final position = DocumentPosition(
          nodeId: nodeId,
          nodePosition: TextNodePosition(offset: offset),
        );
        final layout = SuperEditorInspector.findDocumentLayout();

        final edge = layout.getEdgeForPosition(position)!;
        final line = layout.getRectForPosition(position)!;

        expect(edge.height, lessThan(line.height));
        expect(edge.top, greaterThan(line.top));
        expect(edge.bottom, lessThanOrEqualTo(line.bottom + 0.01));
      });
    }

    testWidgetsOnMac('on an empty line the caret has the height of text', (tester) async {
      await tester //
          .createDocument()
          .withSingleEmptyParagraph()
          .useStylesheet(stylesheet)
          .pump();
      final nodeId = SuperEditorInspector.findDocument()!.first.id;
      final position = DocumentPosition(
        nodeId: nodeId,
        nodePosition: const TextNodePosition(offset: 0),
      );
      final layout = SuperEditorInspector.findDocumentLayout();

      final edge = layout.getEdgeForPosition(position)!;
      final line = layout.getRectForPosition(position)!;

      expect(edge.height, closeTo(16 * 1.2, 0.5));
      expect(edge.bottom, lessThanOrEqualTo(line.bottom + 0.01));
    });

    testWidgetsOnMac('in a taller run the caret is as tall as in plain text, on the same baseline', (tester) async {
      await tester //
          .createDocument()
          .fromMarkdown('Hello **world** now')
          .useStylesheet(stylesheet.copyWith(
            inlineTextStyler: (attributions, style) =>
                attributions.contains(boldAttribution) ? style.copyWith(height: 2.3) : style,
          ))
          .pump();
      final nodeId = SuperEditorInspector.findDocument()!.first.id;
      Rect edgeAt(int offset) => SuperEditorInspector.findDocumentLayout().getEdgeForPosition(
            DocumentPosition(nodeId: nodeId, nodePosition: TextNodePosition(offset: offset)),
          )!;

      final plain = edgeAt(3);
      for (final offset in [8, 11, 15]) {
        final edge = edgeAt(offset);
        expect(edge.height, closeTo(plain.height, 0.01), reason: 'offset $offset');
        expect(edge.bottom, closeTo(plain.bottom, 0.01), reason: 'offset $offset');
      }
    });
  });
}
