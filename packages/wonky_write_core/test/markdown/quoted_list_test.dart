import 'package:test/test.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../property/markdown_round_trip_test.dart' show checkRoundTrip;

/// Lists inside blockquotes (Write 02 §1.2, §2.2; T-19): a list line with
/// `blockquote: true`.
void main() {
  const quote = {'blockquote': true};
  Delta doc(List<(String, Map<String, dynamic>?)> lines) {
    final d = Delta();
    for (final (text, attributes) in lines) {
      if (text.isNotEmpty) d.insert(text);
      d.insert('\n', attributes);
    }
    return d;
  }

  final quotedList = doc([
    ('Intro', null),
    ('Before the list', quote),
    ('One', {'list': 'bullet', ...quote}),
    ('Nested', {'list': 'bullet', 'indent': 1, ...quote}),
    ('Two', {'list': 'bullet', ...quote}),
    ('First', {'list': 'ordered', ...quote}),
    ('Done', {'list': 'checked', ...quote}),
    ('After the list', quote),
    ('Outside', {'list': 'bullet'}),
  ]);

  group('Given a quote with a paragraph, lists and tasks', () {
    test('then the delta is valid', () {
      expect(
        const WonkyDeltaValidator().validate(quotedList).isValid,
        isTrue,
        reason: '${const WonkyDeltaValidator().validate(quotedList).issues}',
      );
    });

    test('then normalizing keeps the quote on the list lines', () {
      final normalized = const WonkyDeltaNormalizer().normalize(quotedList);

      expect(normalized.document, quotedList);
      expect(normalized.fixes, isEmpty);
    });

    test('then Markdown has one quote with the lists behind `>` and the '
        'unquoted list after it', () {
      final md = const MarkdownCodec().exportMarkdown(quotedList);

      expect(
        md,
        'Intro\n'
        '\n'
        '> Before the list\n'
        '>\n'
        '> - One\n'
        '>   - Nested\n'
        '> - Two\n'
        '> 1. First\n'
        '> - [x] Done\n'
        '>\n'
        '> After the list\n'
        '\n'
        '- Outside\n',
      );
    });

    test('then Markdown round-trips', () => checkRoundTrip(quotedList));

    test('then HTML puts the paragraphs and lists in one blockquote', () {
      final tree = const DocTreeBuilder().fromDelta(quotedList);
      final html = const HtmlBodyWriter().blocks(tree.blocks);

      expect(html, contains('<blockquote><p>Before the list</p><ul>'));
      expect(html, contains('<li>Nested'));
      expect(html, contains('<p>After the list</p></blockquote>'));
      expect(
        '<blockquote>'.allMatches(html),
        hasLength(1),
        reason: 'one quote',
      );
      expect(
        html.indexOf('Outside'),
        greaterThan(html.indexOf('</blockquote>')),
      );
    });
  });

  test('Given Markdown with a list in a quote then it imports as quoted '
      'list items without warnings', () {
    final result = const MarkdownCodec().importMarkdown('> - a\n> - b\n');

    expect(
      result.delta,
      doc([
        ('a', {'list': 'bullet', ...quote}),
        ('b', {'list': 'bullet', ...quote}),
      ]),
    );
    expect(result.warnings, isEmpty);
  });

  test('Given pasted HTML with a list in a blockquote then it imports as a '
      'quote line and quoted list items', () {
    final result = const HtmlImporter().importFragment(
      '<blockquote><p>Said:</p><ul><li>a<ul><li>b</li></ul></li></ul>'
      '<ol><li>c</li></ol></blockquote><p>After</p>',
    );

    expect(
      result.delta,
      doc([
        ('Said:', quote),
        ('a', {'list': 'bullet', ...quote}),
        ('b', {'list': 'bullet', 'indent': 1, ...quote}),
        ('c', {'list': 'ordered', ...quote}),
        ('After', null),
      ]),
    );
    expect(
      result.warnings.map((w) => w.kind),
      isNot(contains(ImportWarningKind.listInQuoteFlattened)),
    );
  });

  test('Given the HTML export of a quoted list then importing it gives the '
      'same document', () {
    final html = const HtmlBodyWriter().blocks(
      const DocTreeBuilder().fromDelta(quotedList).blocks,
    );

    expect(const HtmlImporter().importFragment(html).delta, quotedList);
  });

  test('Given an ordered list in a quote next to one outside then each is '
      'numbered from 1', () {
    final tree = const DocTreeBuilder().fromDelta(
      doc([
        ('a', {'list': 'ordered', ...quote}),
        ('b', {'list': 'ordered', ...quote}),
        ('c', {'list': 'ordered'}),
      ]),
    );

    expect(
      [for (final b in tree.blocks.cast<ListItemBlock>()) b.ordinal],
      [1, 2, 1],
    );
  });

  test('Given a quote on a heading then it is still a conflict', () {
    final d = doc([
      ('h', {'header': 1, ...quote}),
    ]);

    expect(
      const WonkyDeltaValidator().validate(d).issues.map((i) => i.code),
      contains(ValidationCode.conflictingBlockAttributes),
    );
  });
}
