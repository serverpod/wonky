import 'dart:math';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_write/features/editor/attributions/wonky_attributions.dart';
import 'package:wonky_write/features/editor/mapping/delta_document_mapper.dart';
import 'package:wonky_write/features/editor/mapping/wonky_schema.dart';

import 'package:wonky_write_core/testing.dart' as core;

import '../support/delta_gen.dart';

void main() {
  const mapper = DeltaDocumentMapper();
  var ids = 0;
  String newId() => 'n${ids++}';

  Delta roundTrip(Delta delta) => mapper.deltaFromDocument(
    mapper.documentFromDelta(delta, newNodeId: newId),
  );

  group('Given a Wonky Delta', () {
    final cases = <String, Delta>{
      'a plain paragraph': Delta()..insert('Hello\n'),
      'an empty last line': Delta()..insert('Hello\n\n'),
      'inline formatting': Delta()
        ..insert('a ')
        ..insert('b', {'bold': true, 'italic': true})
        ..insert(' ')
        ..insert('c', {'code': true})
        ..insert(' ')
        ..insert('d', {'strike': true, 'link': 'https://x.dev'})
        ..insert('\n'),
      'headings and quotes': Delta()
        ..insert('Title')
        ..insert('\n', {'header': 1})
        ..insert('Quote')
        ..insert('\n', {'blockquote': true})
        ..insert('Quote 2')
        ..insert('\n', {'blockquote': true}),
      'lists with indents': Delta()
        ..insert('a')
        ..insert('\n', {'list': 'bullet'})
        ..insert('b')
        ..insert('\n', {'list': 'ordered', 'indent': 1})
        ..insert('c')
        ..insert('\n', {'list': 'checked', 'indent': 2}),
      'a multi-line code block with language': Delta()
        ..insert('void main() {')
        ..insert('\n', {'code-block': 'dart'})
        ..insert('  print(1);')
        ..insert('\n', {'code-block': 'dart'})
        ..insert('\n', {'code-block': 'dart'})
        ..insert('}')
        ..insert('\n', {'code-block': 'dart'}),
      'embeds': Delta()
        ..insert({
          'image': {
            'id': 'i1',
            'src': 'wonky-file://f1',
            'alt': 'Cat',
            'title': 'T',
          },
        })
        ..insert('\n')
        ..insert({
          'divider': {'id': 'd1'},
        })
        ..insert('\n')
        ..insert({
          'table': {
            'id': 't1',
            'align': [null, 'right'],
            'rows': [
              ['**A**', 'B'],
              ['1', 'a \\| b'],
            ],
          },
        })
        ..insert('\n'),
      'a soft line break': Delta()..insert('one two\n'),
      'overlays on text and line ends': Delta()
        ..insert('commented', {'cmt_th1': true})
        ..insert('\n', {'cmt_th1': true, 'header': 2})
        ..insert('new', {
          'sug_s1': {'t': 'ins', 'by': 'u1', 'at': 1},
        })
        ..insert('\n'),
      'a mention': Delta()
        ..insert('@Anna', {'mention': 'u1', 'link': 'mailto:anna@x.dev'})
        ..insert(' hi\n'),
      'Wonky containers, steps, grids and pills (Write 11)': Delta()
        ..insert('Install')
        ..insert('\n', {'header': 2, 'step': 1})
        ..insert('Careful')
        ..insert('\n', {
          'box': [
            {'id': 'w', 'type': 'callout', 'variant': 'warning', 'title': 'T'},
          ],
        })
        ..insert('More')
        ..insert('\n', {
          'box': [
            {'id': 'w', 'type': 'callout', 'variant': 'warning', 'title': 'T'},
            {'id': 'c', 'type': 'card'},
          ],
        })
        ..insert({
          'grid': {
            'id': 'g',
            'columns': 2,
            'bullets': 'check',
            'items': ['**a**', 'b'],
          },
        })
        ..insert('\n', {
          'box': [
            {'id': 'd', 'type': 'details'},
          ],
        })
        ..insert('fn main', {'code': true})
        ..insert('\n', {
          'code-block': 'rust',
          'box': [
            {'id': 'd', 'type': 'details'},
          ],
        })
        ..insert('New', {'chip': 'star'})
        ..insert(' ')
        ..insert('Go', {'link': 'https://x.dev', 'linkStyle': 'button'})
        ..insert(' ')
        ..insert('Docs', {'link': 'https://x.dev', 'linkStyle': 'arrow'})
        ..insert('\n'),
    };

    for (final MapEntry(key: name, value: delta) in cases.entries) {
      test(
        'with $name when mapping to a document and back then the Delta is unchanged',
        () {
          expect(roundTrip(delta), delta);
        },
      );
    }

    test(
      'with a code block when mapping then one code node holds all lines and the language',
      () {
        final document = mapper.documentFromDelta(
          cases['a multi-line code block with language']!,
        );

        final node = document.single as ParagraphNode;
        expect(node.getMetadataValue(NodeMetadata.blockType), codeAttribution);
        expect(node.getMetadataValue(WonkyNodeMetadata.codeLanguage), 'dart');
        expect(node.text.toPlainText(), 'void main() {\n  print(1);\n\n}');
      },
    );

    test('with embeds when mapping then the embed ids become node ids', () {
      final document = mapper.documentFromDelta(cases['embeds']!);

      expect(document.map((n) => n.id), ['i1', 'd1', 't1']);
      expect(
        document.first,
        isA<ImageNode>().having((n) => n.altText, 'alt', 'Cat'),
      );
      expect(
        document.last,
        isA<TableBlockNode>().having((n) => n.rowCount, 'rows', 2),
      );
    });

    test(
      'with overlays when mapping then they become comment and suggestion attributions',
      () {
        final document = mapper.documentFromDelta(
          cases['overlays on text and line ends']!,
        );

        final heading = document.first as ParagraphNode;
        expect(
          heading.text.getAllAttributionsAt(0),
          contains(const CommentAttribution('th1')),
        );
        expect(heading.getMetadataValue(WonkyNodeMetadata.lineAttributes), {
          'cmt_th1': true,
        });
        final second = document.last as ParagraphNode;
        expect(
          second.text
              .getAllAttributionsAt(0)
              .whereType<SuggestionAttribution>()
              .single
              .type,
          SuggestionType.insertion,
        );
      },
    );

    test(
      'that is empty when mapping then the document has one empty paragraph',
      () {
        final document = mapper.documentFromDelta(Delta());

        expect(
          document.single,
          isA<ParagraphNode>().having((n) => n.text.length, 'length', 0),
        );
        expect(mapper.deltaFromDocument(document), Delta()..insert('\n'));
      },
    );
  });

  group('Given random valid Wonky Markdown documents', () {
    for (final seed in propertySeeds()) {
      test(
        'when round-tripping through the mapper (seed $seed) then every Delta is unchanged',
        () {
          final gen = core.DeltaGen(
            Random(seed),
            options: const core.DeltaGenOptions(wonky: true),
          );
          for (var run = 0; run < propertyRuns(); run += 1) {
            final delta = gen.document();
            expect(
              roundTrip(delta),
              delta,
              reason: 'seed $seed run $run: $delta',
            );
          }
        },
      );
    }
  });

  group('Given random valid documents', () {
    for (final seed in propertySeeds()) {
      test(
        'when round-tripping through the mapper (seed $seed) then every Delta is unchanged',
        () {
          final gen = DeltaGen(Random(seed));
          for (var run = 0; run < propertyRuns(); run += 1) {
            final delta = gen.document();
            expect(
              roundTrip(delta),
              delta,
              reason: 'seed $seed run $run: $delta',
            );
          }
        },
      );
    }
  });
}
