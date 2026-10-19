// Tests for WONKY PATCH SE-1 (complete Quill serialization).
import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:super_editor/super_editor_test.dart';

void main() {
  group('SE-1 Quill serialization >', () {
    test('serializes inline code', () {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: '1',
          text: AttributedText(
              'a code b',
              AttributedSpans(attributions: [
                const SpanMarker(
                    attribution: codeAttribution,
                    offset: 2,
                    markerType: SpanMarkerType.start),
                const SpanMarker(
                    attribution: codeAttribution,
                    offset: 5,
                    markerType: SpanMarkerType.end),
              ])),
        ),
      ]);

      expect(
        document.toQuillDeltas(),
        quillDocumentEquivalentTo(Delta()
          ..insert('a ')
          ..insert('code', {'code': true})
          ..insert(' b\n')),
      );
    });

    test('serializes list item and task indentation', () {
      final document = MutableDocument(nodes: [
        ListItemNode.unordered(id: '1', text: AttributedText('a')),
        ListItemNode.ordered(id: '2', text: AttributedText('b'), indent: 2),
        TaskNode(
            id: '3', text: AttributedText('c'), isComplete: true, indent: 1),
      ]);

      expect(
        document.toQuillDeltas(),
        quillDocumentEquivalentTo(Delta()
          ..insert('a')
          ..insert('\n', {'list': 'bullet'})
          ..insert('b')
          ..insert('\n', {'list': 'ordered', 'indent': 2})
          ..insert('c')
          ..insert('\n', {'list': 'checked', 'indent': 1})),
      );
    });

    test('serializes the code block language from node metadata', () {
      final document = MutableDocument(nodes: [
        ParagraphNode(
          id: '1',
          text: AttributedText('main() {}'),
          metadata: const {
            'blockType': codeAttribution,
            codeLanguageMetadataKey: 'dart'
          },
        ),
        ParagraphNode(
            id: '2',
            text: AttributedText('x'),
            metadata: const {'blockType': codeAttribution}),
      ]);

      expect(
        document.toQuillDeltas(),
        quillDocumentEquivalentTo(Delta()
          ..insert('main() {}')
          ..insert('\n', {'code-block': 'dart'})
          ..insert('x')
          ..insert('\n', {'code-block': 'plain'})),
      );
    });

    test('serializes horizontal rules and tables instead of throwing', () {
      final document = MutableDocument(nodes: [
        HorizontalRuleNode(id: '1'),
        TableBlockNode(id: '2', cells: [
          [
            TextNode(id: 'h1', text: AttributedText('A')),
            TextNode(id: 'h2', text: AttributedText('B'))
          ],
          [
            TextNode(id: 'c1', text: AttributedText('1')),
            TextNode(
                id: 'c2',
                text: AttributedText('2'),
                metadata: const {TextNodeMetadata.textAlign: 'right'}),
          ],
        ]),
      ]);

      final delta = document.toQuillDeltas();

      expect(delta.operations[0].data, {'divider': true});
      expect(delta.operations[1].data, {
        'table': {
          'align': [null, 'right'],
          'rows': [
            ['A', 'B'],
            ['1', '2'],
          ],
        },
      });
    });

    test('keeps a trailing empty paragraph when asked to', () {
      final document = MutableDocument(nodes: [
        ParagraphNode(id: '1', text: AttributedText('a')),
        ParagraphNode(id: '2', text: AttributedText('')),
      ]);

      expect(document.toQuillDeltas(),
          quillDocumentEquivalentTo(Delta()..insert('a\n')));
      expect(
        document.toQuillDeltas(omitTrailingEmptyParagraph: false),
        quillDocumentEquivalentTo(Delta()..insert('a\n\n')),
      );
    });
  });

  group('SE-1 Quill parsing >', () {
    test('parses the code block language into node metadata', () {
      final document = parseQuillDeltaOps([
        {'insert': 'print(1)'},
        {
          'insert': '\n',
          'attributes': {'code-block': 'python'},
        },
      ]);

      final code = document.first as ParagraphNode;
      expect(code.getMetadataValue('blockType'), codeAttribution);
      expect(code.getMetadataValue(codeLanguageMetadataKey), 'python');
    });

    test('parses list item and task indentation', () {
      final document = parseQuillDeltaOps([
        {'insert': 'a'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {'insert': 'b'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet', 'indent': 1},
        },
        {'insert': 'c'},
        {
          'insert': '\n',
          'attributes': {'list': 'unchecked', 'indent': 1},
        },
      ]);

      final nodes = document.toList();
      expect((nodes[1] as ListItemNode).indent, 1);
      expect((nodes[2] as TaskNode).indent, 1);
    });

    test('parses divider and table embeds', () {
      final document = parseQuillDeltaOps([
        {
          'insert': {'divider': true},
        },
        {
          'insert': {
            'table': {
              'align': [null, 'center'],
              'rows': [
                ['**A**', 'B'],
                ['1', '2'],
              ],
            },
          },
        },
      ]);

      final nodes = document.toList();
      expect(nodes.whereType<HorizontalRuleNode>(), hasLength(1));
      final table = nodes.whereType<TableBlockNode>().single;
      expect(table.rowCount, 2);
      expect(
          table.getCell(rowIndex: 0, columnIndex: 0).text.toPlainText(), 'A');
      expect(
        table
            .getCell(rowIndex: 0, columnIndex: 0)
            .text
            .hasAttributionAt(0, attribution: boldAttribution),
        isTrue,
      );
      expect(
          table
              .getCell(rowIndex: 1, columnIndex: 1)
              .getMetadataValue(TextNodeMetadata.textAlign),
          'center');
    });
  });
}
