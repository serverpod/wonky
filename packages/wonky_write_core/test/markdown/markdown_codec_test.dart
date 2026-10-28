import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../property/markdown_round_trip_test.dart' show checkRoundTrip;

Delta d(List<Map<String, dynamic>> json) => Delta.fromJson(json);

ImportResult imp(String md) {
  var n = 0;
  return const MarkdownCodec().importMarkdown(
    md,
    options: ImportOptions(idGenerator: () => 'id${n++}'),
  );
}

String exp(List<Map<String, dynamic>> json) =>
    const MarkdownCodec().exportMarkdown(d(json));

void main() {
  group('Given Markdown with unsupported constructs', () {
    final cases =
        <(String, String, List<Map<String, dynamic>>, Set<ImportWarningKind>)>[
          (
            'a setext heading',
            'Title\n=====\n',
            [
              {'insert': 'Title'},
              {
                'insert': '\n',
                'attributes': {'header': 1},
              },
            ],
            {},
          ),
          (
            'inline HTML',
            'a <span>b</span> c<br>d\n',
            [
              {'insert': 'a b c\u2028d\n'},
            ],
            {ImportWarningKind.htmlStripped},
          ),
          (
            'an HTML block',
            '<div>\n<p>Hello</p>\n</div>\n',
            [
              {'insert': 'Hello\n'},
            ],
            {ImportWarningKind.htmlBlock},
          ),
          (
            'nested blockquotes',
            '> a\n>\n> > b\n',
            [
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {'blockquote': true},
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {'blockquote': true},
              },
            ],
            {ImportWarningKind.nestedQuoteFlattened},
          ),
          (
            'footnotes',
            'Text[^1]\n\n[^1]: Note\n',
            [
              {'insert': 'Text[^1]\n[^1]: Note\n'},
            ],
            {},
          ),
          (
            'a reference link',
            '[x][r]\n\n[r]: https://ex.com\n',
            [
              {
                'insert': 'x',
                'attributes': {'link': 'https://ex.com'},
              },
              {'insert': '\n'},
            ],
            {},
          ),
          (
            'a loose list',
            '- a\n\n- b\n',
            [
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {'list': 'bullet'},
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {'list': 'bullet'},
              },
            ],
            {},
          ),
          (
            'an ordered list starting at 3',
            '3. a\n4. b\n',
            [
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {'list': 'ordered'},
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {'list': 'ordered'},
              },
            ],
            {ImportWarningKind.orderedListStart},
          ),
          (
            'an image inside a paragraph',
            'before ![a](https://x.com/i.png) after\n',
            [
              {'insert': 'before \n'},
              {
                'insert': {
                  'image': {
                    'id': 'id0',
                    'src': 'https://x.com/i.png',
                    'alt': 'a',
                  },
                },
              },
              {'insert': '\n after\n'},
            ],
            {},
          ),
          (
            'a relative image',
            '![logo](img/logo.png)\n',
            [
              {'insert': '[image: logo (img/logo.png)]\n'},
            ],
            {ImportWarningKind.unresolvedImage},
          ),
          (
            'a relative link',
            '[docs](./docs.md)\n',
            [
              {'insert': 'docs\n'},
            ],
            {ImportWarningKind.unsupportedLink},
          ),
          (
            'an indented code block',
            '    code\n',
            [
              {'insert': 'code'},
              {
                'insert': '\n',
                'attributes': {'code-block': ''},
              },
            ],
            {},
          ),
          (
            'a tilde fence with info',
            '~~~ python extra\nx = 1\n~~~\n',
            [
              {'insert': 'x = 1'},
              {
                'insert': '\n',
                'attributes': {'code-block': 'python'},
              },
            ],
            {},
          ),
          (
            'a task list with nesting',
            '- [ ] a\n  - [x] b\n',
            [
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {'list': 'unchecked'},
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {'list': 'checked', 'indent': 1},
              },
            ],
            {},
          ),
          (
            'a bare URL',
            'see https://ex.com now\n',
            [
              {'insert': 'see '},
              {
                'insert': 'https://ex.com',
                'attributes': {'link': 'https://ex.com'},
              },
              {'insert': ' now\n'},
            ],
            {},
          ),
          (
            'a mention link',
            '[@Anna](mailto:anna@x.com "wonky-mention:u-1")\n',
            [
              {
                'insert': '@Anna',
                'attributes': {'link': 'mailto:anna@x.com', 'mention': 'u-1'},
              },
              {'insert': '\n'},
            ],
            {},
          ),
          (
            'a ragged table',
            '| a | b |\n|---|:-:|\n| 1 |\n',
            [
              {'insert': 'a'},
              {
                'insert': '\n',
                'attributes': {
                  'cell': {'table': 'id0', 'row': 'r0'},
                },
              },
              {'insert': 'b'},
              {
                'insert': '\n',
                'attributes': {
                  'cell': {'table': 'id0', 'row': 'r0', 'align': 'center'},
                },
              },
              {'insert': '1'},
              {
                'insert': '\n',
                'attributes': {
                  'cell': {'table': 'id0', 'row': 'r1'},
                },
              },
              {
                'insert': '\n',
                'attributes': {
                  'cell': {'table': 'id0', 'row': 'r1', 'align': 'center'},
                },
              },
            ],
            {},
          ),
          (
            'a hard break',
            'a  \nb\\\nc\n',
            [
              {'insert': 'a\u2028b\u2028c\n'},
            ],
            {},
          ),
        ];
    for (final (name, md, expected, warnings) in cases) {
      test('when importing $name then the delta and warnings match', () {
        final r = imp(md);

        // Row ids are random: compared in the canonical form.
        expect(CellCanon.canonical(r.delta).toJson(), equals(expected));
        expect(r.warnings.map((w) => w.kind).toSet(), equals(warnings));
      });
    }
  });

  group('Given Markdown with front matter', () {
    const md = '---\ntitle: "My doc"\ntags: [a, b]\n---\n\n# Heading\n';

    test('when importing then front matter and title are extracted', () {
      final r = imp(md);

      expect(r.frontMatter, 'title: "My doc"\ntags: [a, b]');
      expect(r.title, 'My doc');
      expect(r.delta.toJson().first, {'insert': 'Heading'});
    });

    test('when exporting with front matter then it is re-emitted', () {
      final out = const MarkdownCodec().exportMarkdown(
        imp(md).delta,
        frontMatter: imp(md).frontMatter,
      );

      expect(out, '---\ntitle: "My doc"\ntags: [a, b]\n---\n\n# Heading\n');
    });

    test(
      'when a document starts with a thematic break then it is not front matter',
      () {
        final r = imp('---\n\nText\n\n---\n');

        expect(r.frontMatter, isNull);
      },
    );
  });

  group('Given documents to export', () {
    final cases = <(String, List<Map<String, dynamic>>, String)>[
      (
        'plain text with significant characters',
        [
          {
            'insert':
                r'1. *a* _b_ [c] `d` #e <f> a|b ~g~ \h'
                '\n',
          },
        ],
        r'1\. \*a\* \_b\_ \[c\] &#96;d&#96; #e \<f> a\|b \~g\~ \\h'
            '\n',
      ),
      (
        'intraword underscores and spaced asterisks',
        [
          {'insert': 'snake_case and 2 * 3\n'},
        ],
        'snake_case and 2 * 3\n',
      ),
      (
        'a leading heading marker and list marker',
        [
          {'insert': '# not a heading\n- not a list\n+ x\n'},
        ],
        '\\# not a heading\n\n\\- not a list\n\n\\+ x\n',
      ),
      (
        'URLs and emails in plain text',
        [
          {'insert': 'http://x.com a@b.com www.y.com\n'},
        ],
        'http\\://x.com a\\@b.com www\\.y.com\n',
      ),
      (
        'leading and trailing spaces',
        [
          {'insert': '  a  \n'},
        ],
        '&#32; a &#32;\n',
      ),
      (
        'nested formatting',
        [
          {
            'insert': 'a',
            'attributes': {'bold': true},
          },
          {
            'insert': 'b',
            'attributes': {'bold': true, 'italic': true},
          },
          {
            'insert': 'c',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ],
        '**a*b*c**\n',
      ),
      (
        'bold ending in a space falls back to tags',
        [
          {
            'insert': 'a ',
            'attributes': {'bold': true},
          },
          {'insert': 'b\n'},
        ],
        '<strong>a </strong>b\n',
      ),
      (
        'a soft break',
        [
          {'insert': 'a\u2028b\u2028\n'},
        ],
        'a\\\nb<br>\n',
      ),
      (
        'an empty paragraph between paragraphs',
        [
          {'insert': 'a\n\nb\n'},
        ],
        'a\n\n<br>\n\nb\n',
      ),
      (
        'lists with nesting and numbering',
        [
          {'insert': 'a'},
          {
            'insert': '\n',
            'attributes': {'list': 'ordered'},
          },
          {'insert': 'b'},
          {
            'insert': '\n',
            'attributes': {'list': 'bullet', 'indent': 1},
          },
          {'insert': 'c'},
          {
            'insert': '\n',
            'attributes': {'list': 'ordered'},
          },
          {'insert': 'd'},
          {
            'insert': '\n',
            'attributes': {'list': 'checked', 'indent': 1},
          },
        ],
        '1. a\n   - b\n2. c\n   - [x] d\n',
      ),
      (
        'quotes',
        [
          {'insert': 'a'},
          {
            'insert': '\n',
            'attributes': {'blockquote': true},
          },
          {'insert': 'b'},
          {
            'insert': '\n',
            'attributes': {'blockquote': true},
          },
        ],
        '> a\n>\n> b\n',
      ),
      (
        'a code block containing a fence',
        [
          {'insert': '```'},
          {
            'insert': '\n',
            'attributes': {'code-block': 'md'},
          },
        ],
        '````md\n```\n````\n',
      ),
      (
        'a link with parentheses',
        [
          {
            'insert': 'x',
            'attributes': {'link': 'https://e.com/(a)'},
          },
          {'insert': '\n'},
        ],
        '[x](<https://e.com/(a)>)\n',
      ),
      (
        'a table with pipes',
        [
          {
            'insert': {
              'table': {
                'id': 't',
                'align': [null, 'right'],
                'rows': [
                  ['h', r'a\|b'],
                  ['`x|y`', ''],
                ],
              },
            },
          },
          {'insert': '\n'},
        ],
        '| h | a\\|b |\n| --- | ---: |\n| `x\\|y` |  |\n',
      ),
      (
        'a leading divider',
        [
          {
            'insert': {
              'divider': {'id': 'r'},
            },
          },
          {'insert': '\nx\n'},
        ],
        '***\n\nx\n',
      ),
    ];
    for (final (name, json, expected) in cases) {
      test('when exporting $name then the Markdown is $expected', () {
        expect(exp(json), expected);
      });
    }
  });

  group('Given suggestions and comments', () {
    final doc = d([
      {'insert': 'keep '},
      {
        'insert': 'old',
        'attributes': {
          'sug_1': {'t': 'del', 'by': 'u', 'at': 1},
          'cmt_c': true,
        },
      },
      {
        'insert': 'new',
        'attributes': {
          'sug_1': {'t': 'ins', 'by': 'u', 'at': 1},
        },
      },
      {'insert': '\n'},
    ]);

    test('when exporting the accepted view then deletions are dropped', () {
      expect(const MarkdownCodec().exportMarkdown(doc), 'keep new\n');
    });

    test('when exporting the original view then insertions are dropped', () {
      expect(
        const MarkdownCodec().exportMarkdown(
          doc,
          view: SuggestionViewMode.original,
        ),
        'keep old\n',
      );
    });
  });

  group('Given shrunk round-trip regressions', () {
    final cases = <List<Map<String, dynamic>>>[
      [
        {
          'insert': 'Z',
          'attributes': {'code': true},
        },
        {
          'insert': '\n',
          'attributes': {'list': 'checked'},
        },
        {
          'insert': '\n',
          'attributes': {'list': 'bullet', 'indent': 1},
        },
      ],
      [
        {
          'insert': '9',
          'attributes': {'italic': true, 'strike': true},
        },
        {'insert': '&'},
        {
          'insert': '\n',
          'attributes': {'list': 'checked'},
        },
        {
          'insert': '\n',
          'attributes': {'list': 'ordered', 'indent': 1},
        },
      ],
      [
        {
          'insert': 'p',
          'attributes': {'italic': true},
        },
        {'insert': '`'},
        {
          'insert': 'h',
          'attributes': {'code': true},
        },
        {'insert': '\n'},
      ],
      [
        {
          'insert': '6',
          'attributes': {'code': true},
        },
        {'insert': '` \n'},
      ],
      [
        {'insert': '!'},
        {
          'insert': '1',
          'attributes': {'code': true, 'link': 'http://wonky.test/(paren)'},
        },
        {'insert': 'X'},
        {
          'insert': '\n',
          'attributes': {'header': 4},
        },
      ],
      [
        {
          'insert': '\n',
          'attributes': {'list': 'bullet'},
        },
        {
          'insert': 'Z',
          'attributes': {'code': true},
        },
        {'insert': '_'},
        {
          'insert': '\n',
          'attributes': {'list': 'bullet', 'indent': 1},
        },
      ],
    ];
    for (final (i, c) in cases.indexed) {
      test(
        'when round-tripping regression #$i then the delta is unchanged',
        () {
          checkRoundTrip(d(c));
        },
      );
    }
  });
}
