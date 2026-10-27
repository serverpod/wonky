import 'dart:math';

import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

Delta d(List<Map<String, dynamic>> json) => Delta.fromJson(json);

Delta md(String markdown) => const MarkdownCodec()
    .importMarkdown(markdown, options: ImportOptions(idGenerator: () => 'e'))
    .delta;

String toMd(Delta doc) => const MarkdownCodec().exportMarkdown(doc);

List<InlineRun> _runs(DocumentLine line) => [
  for (final s in line.segments) InlineRun.fromAttributes(s.text, s.attributes),
];

void main() {
  var ids = 0;
  final edits = DocumentEdits(idGenerator: () => 'id${ids++}');

  group('Given a document with a quote that occurs twice', () {
    final doc = md('alpha beta\n\nalpha gamma\n');
    final resolver = AddressResolver(doc);

    test(
      'when resolving without occurrence then quote_ambiguous lists matches',
      () {
        expect(
          () => resolver.resolveRange(const QuoteRange('alpha')),
          throwsA(
            isA<AddressException>()
                .having((e) => e.code, 'code', 'quote_ambiguous')
                .having((e) => e.details!['count'], 'count', 2),
          ),
        );
      },
    );

    test('when resolving occurrence 2 then the second match is returned', () {
      expect(
        resolver.resolveRange(const QuoteRange('alpha', occurrence: 2)),
        const ResolvedRange(11, 5),
      );
    });

    test('when the quote is missing then quote_not_found is thrown', () {
      expect(
        () => resolver.resolveRange(const QuoteRange('delta')),
        throwsA(
          isA<AddressException>().having(
            (e) => e.code,
            'code',
            'quote_not_found',
          ),
        ),
      );
    });

    test('when an offset is out of bounds then invalid_offset is thrown', () {
      expect(
        () => resolver.resolvePosition(const OffsetPosition(999)),
        throwsA(
          isA<AddressException>().having(
            (e) => e.code,
            'code',
            'invalid_offset',
          ),
        ),
      );
    });
  });

  group('Given a document with an emoji', () {
    final doc = Delta()..insert('a😀b\n');

    test(
      'when an offset points inside the surrogate pair then it is rejected',
      () {
        expect(
          () => AddressResolver(doc).resolvePosition(const OffsetPosition(2)),
          throwsA(
            isA<AddressException>().having(
              (e) => e.code,
              'code',
              'invalid_offset',
            ),
          ),
        );
      },
    );
  });

  group('Given a document with sections', () {
    final doc = md(
      '# Plan\n\nintro\n\n## Budget\n\nmoney\n\n## Risks\n\nmany\n\n# End\n',
    );
    final resolver = AddressResolver(doc);

    test(
      'when resolving a heading section then it ends before the next same-level heading',
      () {
        final r = resolver.resolveRange(
          HeadingSectionRange(const HeadingRef.text('budget')),
        );
        expect(
          doc.slice(r.start, r.end).toJson().map((o) => o['insert']).join(),
          'Budget\nmoney\n',
        );
      },
    );

    test(
      'when resolving a section without its heading then only the body is returned',
      () {
        final r = resolver.resolveRange(
          HeadingSectionRange(
            const HeadingRef.text('Plan'),
            includeHeading: false,
          ),
        );
        expect(
          DeltaUtils.text(doc.slice(r.start, r.end)),
          'intro\nBudget\nmoney\nRisks\nmany\n',
        );
      },
    );

    test(
      'when replacing a section body with Markdown then other sections are untouched',
      () {
        final range = resolver.resolveRange(
          HeadingSectionRange(
            const HeadingRef.text('Budget'),
            includeHeading: false,
          ),
        );

        final r = edits.replaceRange(doc, range, '- one\n- two\n');

        expect(
          toMd(r.document),
          '# Plan\n\nintro\n\n## Budget\n\n- one\n- two\n\n## Risks\n\nmany\n\n# End\n',
        );
      },
    );

    test(
      'when inserting after a heading then the blocks follow the heading line',
      () {
        final at = resolver.resolvePosition(
          HeadingPosition(const HeadingRef.text('Risks'), HeadingAnchor.after),
        );

        final r = edits.insertMarkdown(doc, at, 'New **text**');

        expect(toMd(r.document), contains('## Risks\n\nNew **text**\n\nmany'));
      },
    );

    test(
      'when inserting at the end of a section then it lands before the next heading',
      () {
        final at = resolver.resolvePosition(
          HeadingPosition(
            const HeadingRef.text('Plan'),
            HeadingAnchor.endOfSection,
          ),
        );

        final r = edits.insertMarkdown(doc, at, 'tail');

        expect(toMd(r.document), endsWith('many\n\ntail\n\n# End\n'));
      },
    );
  });

  group('Given insertion positions', () {
    final doc = md('Hello world\n\n- item\n');

    final cases = <(String, int, String, InsertAs, String)>[
      (
        'mid-line single paragraph merges inline',
        6,
        'big',
        InsertAs.auto,
        'Hello bigworld\n\n- item\n',
      ),
      (
        'mid-line blocks split the line',
        5,
        '# H',
        InsertAs.blocks,
        'Hello\n\n# H\n\n&#32;world\n\n- item\n',
      ),
      (
        'line start inserts blocks before',
        0,
        'Top',
        InsertAs.auto,
        'Top\n\nHello world\n\n- item\n',
      ),
      (
        'end of a list item appends inline',
        16,
        ' more',
        InsertAs.auto,
        'Hello world\n\n- item more\n',
      ),
      (
        'end of a list item as blocks keeps the list',
        16,
        '> q',
        InsertAs.blocks,
        'Hello world\n\n- item\n\n> q\n',
      ),
    ];
    for (final (name, at, insert, mode, expected) in cases) {
      test('when inserting at $at ($name) then the result is as expected', () {
        final r = edits.insertMarkdown(doc, at, insert, as: mode);

        expect(toMd(r.document), expected);
      });
    }

    test('when inserting into an empty paragraph then it is filled', () {
      final r = edits.insertMarkdown(Delta()..insert('\n'), 0, '## Title');

      expect(r.document.toJson(), [
        {'insert': 'Title'},
        {
          'insert': '\n',
          'attributes': {'header': 2},
        },
      ]);
    });
  });

  group('Given a commented paragraph', () {
    final doc = d([
      {'insert': 'The quick '},
      {
        'insert': 'brown',
        'attributes': {'cmt_t1': true},
      },
      {'insert': ' fox jumps\n'},
    ]);

    test(
      'when replacing the sentence with minimal diff then the anchor survives',
      () {
        final r = edits.replaceRange(
          doc,
          const ResolvedRange(0, 25),
          'The slow brown fox jumps',
        );

        final anchored = r.document.operations.where(
          (o) => o.attributes?['cmt_t1'] == true,
        );
        expect(anchored.map((o) => o.data), ['brown']);
        expect(DeltaUtils.text(r.document), 'The slow brown fox jumps\n');
      },
    );

    test(
      'when replacing without preserving overlays then the anchor is dropped',
      () {
        final r = edits.replaceRange(
          doc,
          const ResolvedRange(0, 25),
          'The slow brown fox jumps',
          preserveOverlays: false,
        );

        expect(
          r.document.operations.any(
            (o) => o.attributes?.containsKey('cmt_t1') ?? false,
          ),
          isFalse,
        );
      },
    );

    test(
      'when setting the whole Markdown then unchanged anchored words keep the comment',
      () {
        final r = edits.setMarkdown(doc, 'A quick brown fox jumps high');

        expect(
          r.document.operations
              .where((o) => o.attributes?['cmt_t1'] == true)
              .map((o) => o.data),
          ['brown'],
        );
      },
    );
  });

  group('Given formatting edits', () {
    final doc = Delta()
      ..insert('ab')
      ..insert('cd', {'code': true})
      ..insert('\n');

    test('when applying bold over code then code is removed there', () {
      final r = edits.applyInlineFormat(
        doc,
        const ResolvedRange(0, 4),
        const InlineFormatPatch(bold: true),
      );

      expect(r.document.toJson(), [
        {
          'insert': 'abcd',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
    });

    test('when applying an invalid link then invalid_args is thrown', () {
      expect(
        () => edits.applyInlineFormat(
          doc,
          const ResolvedRange(0, 2),
          const InlineFormatPatch(link: 'javascript:x'),
        ),
        throwsA(
          isA<AddressException>().having((e) => e.code, 'code', 'invalid_args'),
        ),
      );
    });

    test(
      'when converting formatted lines to code then they merge into one block',
      () {
        final doc2 = md('a **b**\n\nc\n');

        final r = edits.setBlockType(
          doc2,
          const ResolvedRange(0, 6),
          const BlockTypeSpec(BlockType.code, language: 'dart'),
        );

        expect(toMd(r.document), '```dart\na b\nc\n```\n');
      },
    );

    test(
      'when converting a heading to a task then the block attributes are replaced',
      () {
        final r = edits.setBlockType(
          md('# T\n'),
          const ResolvedRange(0, 1),
          const BlockTypeSpec(BlockType.task, checked: true),
        );

        expect(toMd(r.document), '- [x] T\n');
      },
    );
  });

  group('Given find and replace', () {
    final doc = md('cat cat Cat\n');

    test(
      'when replacing all case-insensitive matches then ranges are reported',
      () {
        final r = edits.replaceText(doc, const FindSpec('cat'), 'dog');

        expect(DeltaUtils.text(r.document), 'dog dog dog\n');
        expect(r.extra['replacements'], 3);
        expect(r.extra['ranges'], [
          {'start': 0, 'length': 3},
          {'start': 4, 'length': 3},
          {'start': 8, 'length': 3},
        ]);
      },
    );

    test(
      'when replacing occurrence 2 with a regex group then only it changes',
      () {
        final r = edits.replaceText(
          doc,
          const FindSpec(r'c(a)t', regex: true, matchCase: true),
          r'b$1t',
          occurrence: 2,
        );

        expect(DeltaUtils.text(r.document), 'cat bat Cat\n');
      },
    );

    test('when replacing with inline Markdown then formatting is applied', () {
      final r = edits.replaceText(
        doc,
        const FindSpec('Cat', matchCase: true),
        '**Lion**',
        format: ReplaceFormat.markdownInline,
      );

      expect(toMd(r.document), 'cat cat **Lion**\n');
    });

    test('when searching then occurrence numbers support quote addressing', () {
      final res = TextSearch(
        WonkyDocument(doc),
      ).search(const FindSpec('cat', wholeWord: true));

      expect(res.matches.map((m) => (m.text, m.occurrence)), [
        ('cat', 1),
        ('cat', 2),
        ('Cat', 1),
      ]);
    });
  });

  group('Given deletions', () {
    final doc = md('a\n\nb\n\nc\n');

    test(
      'when deleting a whole middle line then no empty paragraph remains',
      () {
        final r = edits.deleteRange(doc, const ResolvedRange(2, 2));
        expect(DeltaUtils.text(r.document), 'a\nc\n');
      },
    );

    test('when deleting everything then one empty paragraph remains', () {
      final r = edits.deleteRange(md('# a\n\nb\n'), const ResolvedRange(0, 4));
      expect(r.document.toJson(), [
        {'insert': '\n'},
      ]);
    });

    test(
      'when deleting the last lines then the previous line keeps its type',
      () {
        final r = edits.deleteRange(
          md('# a\n\nb\n'),
          const ResolvedRange(2, 2),
        );
        expect(toMd(r.document), '# a\n');
      },
    );
  });

  group('Given tables', () {
    test('when inserting and updating a table then the table keeps its id', () {
      final doc = md('text\n');
      final ins = edits.insertTable(doc, 4, [
        ['a', 'b'],
        ['1'],
      ]);
      final id = ins.extra['table_id'] as String;

      final upd = edits.updateTable(
        ins.document,
        tableId: id,
        operations: const [
          SetCellOp(1, 1, '**2**'),
          InsertColumnOp(2, header: 'c'),
          SetAlignOp(0, CellAlign.right),
          InsertRowOp(2, cells: ['x', 'y', 'z']),
        ],
      );

      final table = DocumentEdits.findTable(upd.document, tableIndex: 0);
      expect(table.id, id);
      expect(
        [
          for (final r in table.rows)
            [
              for (final c in r.cells)
                InlineMarkdownWriter.write(
                  _runs(c),
                  context: InlineContext.tableCell,
                ),
            ],
        ],
        [
          ['a', 'b', 'c'],
          ['1', '**2**', ''],
          ['x', 'y', 'z'],
        ],
      );
      expect(table.align, [CellAlign.right, null, null]);
    });

    test('when updating a table then cells that do not change keep their '
        'lines', () {
      final ins = edits.insertTable(md('text\n'), 4, [
        ['a', 'b'],
        ['1', '2'],
      ]);
      final id = ins.extra['table_id'] as String;

      final upd = edits.updateTable(
        ins.document,
        tableId: id,
        operations: const [SetCellOp(1, 1, 'two')],
      );

      final deleted = upd.change
          .toList()
          .where((op) => op.isDelete)
          .fold(0, (n, op) => n + op.length!);
      expect(deleted, 1);
    });

    test('when deleting the only row then invalid_args is thrown', () {
      final ins = edits.insertTable(md('text\n'), 4, [
        ['a'],
      ]);
      expect(
        () => edits.updateTable(
          ins.document,
          tableIndex: 0,
          operations: const [DeleteRowOp(0)],
        ),
        throwsA(isA<AddressException>()),
      );
    });
  });

  group('Given the document reader', () {
    final doc = md('# T\n\nPara with **b**\n\n- x\n- y\n');

    test(
      'when reading with blocks then Markdown positions point into the content',
      () {
        final r = const DocumentReader().read(doc, includeBlocks: true);
        final content = r.content as String;
        final blocks = r.blocks!;

        expect(blocks.map((b) => b['type']), [
          'heading',
          'paragraph',
          'bullet',
          'bullet',
        ]);
        expect(
          [
            for (final b in blocks)
              content.substring(
                b['md_start'] as int,
                (b['md_start'] as int) + (b['md_length'] as int),
              ),
          ],
          ['# T', 'Para with **b**', '- x', '- y'],
        );
      },
    );

    test(
      'when paging with max_chars then the cursor continues the content',
      () {
        final first = const DocumentReader().read(doc, maxChars: 10);
        final second = const DocumentReader().read(
          doc,
          maxChars: 1000,
          cursor: first.nextCursor,
        );

        expect('${first.content}${second.content}', toMd(doc));
        expect(first.truncated, isTrue);
      },
    );

    test('when reading raw Markdown then suggestions use CriticMarkup', () {
      final sugDoc = d([
        {'insert': 'a '},
        {
          'insert': 'new',
          'attributes': {
            'sug_1': {'t': 'ins', 'by': 'u', 'at': 1},
          },
        },
        {
          'insert': 'old',
          'attributes': {
            'sug_1': {'t': 'del', 'by': 'u', 'at': 1},
          },
        },
        {'insert': '\n'},
      ]);

      final r = const DocumentReader().read(
        sugDoc,
        view: SuggestionViewMode.raw,
      );

      expect(r.content, 'a {++new++}{--old--}\n');
    });
  });

  group('Given random documents and edits', () {
    propertyTest(
      'when diffing two documents then applying the diff yields the second',
      (random, _) {
        final gen = DeltaGen(
          random,
          options: const DeltaGenOptions(overlays: true),
        );
        final a = gen.document();
        final b = gen.document();

        expect(WonkyOt.apply(a, DeltaDiff.diff(a, b)), equals(b));
      },
    );

    propertyTest(
      'when inserting Markdown at a random position then the result validates',
      (random, _) {
        final gen = DeltaGen(random);
        final doc = gen.document();
        final len = DeltaUtils.documentLength(doc);
        var at = random.nextInt(len);
        if (DeltaUtils.isInsideSurrogatePair(DeltaUtils.text(doc), at)) at--;
        final markdown = const MarkdownCodec().exportMarkdown(gen.document());
        final as = InsertAs.values[random.nextInt(3)];

        final r = edits.insertMarkdown(doc, at, markdown, as: as);

        expect(
          const WonkyDeltaValidator().validate(r.document).isValid,
          isTrue,
        );
        expect(WonkyOt.apply(doc, r.change), equals(r.document));
      },
    );

    propertyTest(
      'when replacing a random range then overlays outside it survive',
      (random, _) {
        final gen = DeltaGen(
          random,
          options: const DeltaGenOptions(overlays: true, embeds: false),
        );
        final doc = gen.document();
        final len = DeltaUtils.documentLength(doc);
        final text = DeltaUtils.text(doc);
        var start = random.nextInt(len);
        if (DeltaUtils.isInsideSurrogatePair(text, start)) start--;
        var end = start + random.nextInt(min(10, len - start));
        if (end < len && DeltaUtils.isInsideSurrogatePair(text, end)) end--;
        if (end < start) end = start;

        final r = edits.replaceRange(
          doc,
          ResolvedRange(start, end - start),
          'replacement *text*',
        );

        expect(
          const WonkyDeltaValidator().validate(r.document).isValid,
          isTrue,
        );
        // Everything before the replaced lines is untouched (including overlays).
        final lineStart = WonkyDocument(doc).lineAt(start).start;
        expect(r.document.slice(0, lineStart), equals(doc.slice(0, lineStart)));
      },
      runs: 200,
    );
  });
}
