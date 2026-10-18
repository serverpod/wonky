import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:super_editor/super_editor.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_rich_editor/wonky_rich_editor.dart';
import 'package:wonky_ui/wonky_ui.dart' show WonkyTheme;

/// CQ-50 (shared M-7): the board/comment composer writes Markdown with
/// `MarkdownDocumentCodec` (`package:markdown`), and the renderer
/// (`MarkdownBlocks` + `MarkdownInline`, hand-written) shows it. This
/// cross-checks them: random composer documents are written, and the
/// renderer must see the blocks, nesting, list markers, text, inline styles
/// and links that the composer reads back from the same Markdown.
void main() {
  const codec = MarkdownDocumentCodec();
  const cs = ShadSlateColorScheme.light();

  for (final seed in [1, 7, 42, 1234, 98765]) {
    test('Given random composer documents (seed $seed) when the Markdown is '
        'rendered then blocks, text, styles and links match the composer', () {
      final random = Random(seed);
      for (var round = 0; round < 150; round++) {
        final doc = MutableDocument(
          nodes: [
            for (var i = 0; i < 1 + random.nextInt(7); i++) _node(random, i),
          ],
        );
        final markdown = codec.encode(doc);

        final expected = _composerBlocks(codec.decode(markdown));
        final actual = _rendererBlocks(
          MarkdownBlocks.parse(markdown, hardBreaks: true),
          cs,
        );

        expect(actual, expected, reason: 'round $round:\n$markdown');
      }
    });
  }
}

/// One block as both sides describe it: kind, level, marker and the text
/// with its inline styles per character.
typedef _Block = (String kind, int level, String marker, String chars);

/// A character with its styles: `c|b i s k|url` (bold, italic, strike,
/// code, link).
String _styled(
  String c, {
  bool bold = false,
  bool italic = false,
  bool strike = false,
  bool code = false,
  String? link,
}) =>
    '$c|${bold ? 'b' : ''}${italic ? 'i' : ''}${strike ? 's' : ''}'
    '${code ? 'k' : ''}|${link ?? ''}';

List<_Block> _composerBlocks(Document document) {
  final out = <_Block>[];
  // super_editor numbering: per level, reset by other blocks.
  final numbers = <int>[];
  for (final node in document) {
    final kind = MarkdownDocumentCodec.kindOf(node);
    if (node is! ListItemNode) numbers.clear();
    switch (node) {
      case HorizontalRuleNode():
        out.add(('rule', 0, '', ''));
      case ListItemNode():
        final level = node.indent;
        numbers.length = min(numbers.length, level + 1);
        while (numbers.length <= level) {
          numbers.add(0);
        }
        final String marker;
        if (node.type == ListItemType.ordered) {
          numbers[level]++;
          marker = '${numbers[level]}.';
        } else {
          numbers[level] = 0;
          marker = '•';
        }
        out.add(('item', level, marker, _chars(node.text)));
      case TaskNode():
        out.add((
          'item',
          node.indent,
          node.isComplete ? '☑' : '☐',
          _chars(node.text),
        ));
      case ParagraphNode():
        if (node.text.toPlainText().trim().isEmpty) continue;
        final level = MarkdownDocumentCodec.headingLevelOf(node);
        out.add((
          level != null ? 'heading' : (kind == 'quote' ? 'quote' : 'p'),
          level ?? 0,
          '',
          _chars(node.text),
        ));
      default:
        break;
    }
  }
  return out;
}

String _chars(AttributedText text) {
  final s = text.toPlainText();
  return [
    for (var i = 0; i < s.length; i++)
      _styled(
        s[i],
        bold: text.hasAttributionAt(i, attribution: boldAttribution),
        italic: text.hasAttributionAt(i, attribution: italicsAttribution),
        strike: text.hasAttributionAt(i, attribution: strikethroughAttribution),
        code: text.hasAttributionAt(i, attribution: codeAttribution),
        link: text
            .getAllAttributionsAt(i)
            .whereType<LinkAttribution>()
            .firstOrNull
            ?.plainTextUri,
      ),
  ].join(' ');
}

List<_Block> _rendererBlocks(List<MdBlock> blocks, ShadColorScheme cs) {
  final out = <_Block>[];
  for (final b in blocks) {
    final kind = switch (b.kind) {
      MdKind.heading => 'heading',
      MdKind.paragraph => 'p',
      MdKind.listItem => 'item',
      MdKind.quote => 'quote',
      MdKind.rule => 'rule',
      MdKind.code => 'code',
      MdKind.table => 'table',
    };
    if (b.kind == MdKind.rule) {
      out.add((kind, 0, '', ''));
      continue;
    }
    final urls = <GestureRecognizer, String>{};
    final span = MarkdownInline.spans(
      b.text,
      const TextStyle(),
      cs,
      link: (url) {
        final recognizer = TapGestureRecognizer();
        urls[recognizer] = url;
        return recognizer;
      },
    );
    final chars = <String>[];
    // A struck link is drawn underlined (one decoration); the strike is
    // read from the span tree, as the renderer meant it.
    void walk(InlineSpan s, TextStyle style, {required bool struck}) {
      if (s is! TextSpan) return;
      final merged = style.merge(s.style);
      final strike =
          struck || s.style?.decoration == TextDecoration.lineThrough;
      final text = s.text ?? '';
      for (var i = 0; i < text.length; i++) {
        chars.add(
          _styled(
            text[i],
            bold: merged.fontWeight == FontWeight.w600,
            italic: merged.fontStyle == FontStyle.italic,
            strike: strike,
            code: merged.fontFamily == WonkyTheme.monoFamily,
            link: s.recognizer == null ? null : urls[s.recognizer],
          ),
        );
      }
      for (final c in s.children ?? const <InlineSpan>[]) {
        walk(c, merged, struck: strike);
      }
    }

    walk(span, const TextStyle(), struck: false);
    out.add((
      kind,
      b.level,
      b.kind == MdKind.listItem ? b.marker : '',
      chars.join(' '),
    ));
  }
  return out;
}

/// Words with the characters Markdown cares about.
const _words = [
  'plain',
  'snake_case',
  'a*b',
  '2 * 3',
  '[x]',
  'a|b',
  '~/p',
  '#tag',
  '<T>',
  'R&D',
  '1.',
  '3)',
  '-',
  '+1',
  '>',
  'back`tick',
  r'C:\dir',
  '**',
  '__',
  '`',
  '!',
  '(paren)',
  'é',
  '日本',
  '=',
  'x_',
  '_y',
  'end.',
];

AttributedText _text(Random r, {bool lines = true}) {
  final n = 1 + r.nextInt(6);
  var s = [
    for (var i = 0; i < n; i++) _words[r.nextInt(_words.length)],
  ].join(' ');
  if (lines && r.nextInt(4) == 0) s = '$s\n${_words[r.nextInt(_words.length)]}';
  final t = AttributedText(s);
  for (var k = 0; k < r.nextInt(3); k++) {
    // Styles cover whole words (what the composer's toolbar and shortcuts
    // produce on a word selection); mid-word runs of mixed `*`/`**`
    // delimiters are where a regex renderer and CommonMark's delimiter
    // algorithm part ways (a shared grammar is the longer-term fix, M-7).
    final starts = [
      0,
      for (var i = 1; i < s.length; i++)
        if (s[i - 1] == ' ' || s[i - 1] == '\n') i,
    ];
    final a = starts[r.nextInt(starts.length)];
    final ends = [
      for (var i = a + 1; i <= s.length; i++)
        if (i == s.length || s[i] == ' ' || s[i] == '\n') i - 1,
    ];
    final b = ends[r.nextInt(ends.length)];
    final attribution = [
      boldAttribution,
      italicsAttribution,
      strikethroughAttribution,
      codeAttribution,
      LinkAttribution('https://example.com/${r.nextInt(9)}'),
    ][r.nextInt(5)];
    t.addAttribution(
      attribution,
      SpanRange(a, b),
      overwriteConflictingSpans: true,
    );
  }
  return t;
}

DocumentNode _node(Random r, int i) {
  final id = 'n$i';
  return switch (r.nextInt(8)) {
    0 => ParagraphNode(
      id: id,
      text: _text(r, lines: false),
      metadata: {
        NodeMetadata.blockType: MarkdownDocumentCodec.headerAttribution(
          1 + r.nextInt(3),
        ),
      },
    ),
    1 => ListItemNode.unordered(id: id, text: _text(r), indent: r.nextInt(2)),
    2 => ListItemNode.ordered(id: id, text: _text(r), indent: r.nextInt(2)),
    3 => TaskNode(
      id: id,
      text: _text(r),
      isComplete: r.nextBool(),
      indent: r.nextInt(2),
    ),
    4 => ParagraphNode(
      id: id,
      text: _text(r),
      metadata: {NodeMetadata.blockType: blockquoteAttribution},
    ),
    5 => HorizontalRuleNode(id: id),
    _ => ParagraphNode(id: id, text: _text(r)),
  };
}
