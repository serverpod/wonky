import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';

/// Wonky Markdown (Write 11): the blog's directives in the codec, schema and
/// GFM conversion.
void main() {
  const codec = MarkdownCodec();
  const normalizer = WonkyDeltaNormalizer();
  const validator = WonkyDeltaValidator();

  ImportResult importWonky(String md, {List<String>? ids}) {
    var n = 0;
    return codec.importMarkdown(
      md,
      options: ImportOptions(
        flavor: MarkdownFlavor.wonky,
        idGenerator: () =>
            ids != null && n < ids.length ? ids[n++] : 'id-${n++}',
      ),
    );
  }

  String exportWonky(Delta d) => codec.exportMarkdown(
    d,
    options: const MarkdownExportOptions(flavor: MarkdownFlavor.wonky),
  );

  List<Map<String, dynamic>> lines(Delta d) => [
    for (final l in WonkyDocument(d).lines) {'text': l.text, ...l.attributes},
  ];

  group('Given the blog spec examples', () {
    test('when importing inline directives then buttons, arrow links and '
        'chips become styled text', () {
      final d = importWonky(
        ':button[Get started](https://example.com) '
        ':button[Read more](https://example.com){variant=secondary} '
        ':link[Docs](https://docs.serverpod.dev/) '
        ':chip[Facebook] :chip[Google]{icon=google}\n',
      ).delta;

      expect(d.toJson(), [
        {
          'insert': 'Get started',
          'attributes': {'link': 'https://example.com', 'linkStyle': 'button'},
        },
        {'insert': ' '},
        {
          'insert': 'Read more',
          'attributes': {
            'link': 'https://example.com',
            'linkStyle': 'buttonSecondary',
          },
        },
        {'insert': ' '},
        {
          'insert': 'Docs',
          'attributes': {
            'link': 'https://docs.serverpod.dev/',
            'linkStyle': 'arrow',
          },
        },
        {'insert': ' '},
        {
          'insert': 'Facebook',
          'attributes': {'chip': true},
        },
        {'insert': ' '},
        {
          'insert': 'Google',
          'attributes': {'chip': 'google'},
        },
        {'insert': '\n'},
      ]);
    });

    test('when importing a callout with a title then its lines carry the '
        'callout frame', () {
      final d = importWonky(
        ':::warning[Heads up]\nThis action cannot be undone.\n:::\n',
      ).delta;

      expect(lines(d), [
        {
          'text': 'This action cannot be undone.',
          'box': [
            {
              'id': 'id-0',
              'type': 'callout',
              'variant': 'warning',
              'title': 'Heads up',
            },
          ],
        },
      ]);
    });

    test('when importing details then the summary is the first line, a '
        'level-3 heading', () {
      final d = importWonky(
        ':::details\n### How does hot reload work?\n\n'
        'Serverpod detects changes.\n:::\n',
      ).delta;
      const box = [
        {'id': 'id-0', 'type': 'details'},
      ];

      expect(lines(d), [
        {'text': 'How does hot reload work?', 'header': 3, 'box': box},
        {'text': 'Serverpod detects changes.', 'box': box},
      ]);
    });

    test('when importing a grid then it becomes a grid embed', () {
      final d = importWonky(
        ':::grid{columns=3 bullets=check}\n- Automatic migrations\n'
        '- Stateful hot reload\n- Integrated **AI** tooling\n:::\n',
      ).delta;

      expect(WonkyDocument(d).lines.single.embed, isA<GridEmbed>());
      final grid = WonkyDocument(d).lines.single.embed! as GridEmbed;
      expect(grid.columns, 3);
      expect(grid.bullets, GridBullets.check);
      expect(grid.items, [
        'Automatic migrations',
        'Stateful hot reload',
        'Integrated **AI** tooling',
      ]);
    });

    test('when importing a card with an arrow link then both survive', () {
      final d = importWonky(
        ':::card\nServerpod is an open-source backend framework.\n\n'
        ':link[Get started](https://docs.serverpod.dev/)\n:::\n',
      ).delta;

      final ls = WonkyDocument(d).lines;
      expect(ls, hasLength(2));
      expect(Boxes.of(ls[0].attributes).single.type, BoxType.card);
      expect(ls[1].segments.single.attributes, {
        'link': 'https://docs.serverpod.dev/',
        'linkStyle': 'arrow',
      });
    });

    test('when importing numbered headings then the numbers are steps', () {
      final d = importWonky(
        '## How it works\n\n### (1) Define your model\n\n'
        '### (2) Run serverpod generate\n',
      ).delta;

      expect(lines(d), [
        {'text': 'How it works', 'header': 2},
        {'text': 'Define your model', 'header': 3, 'step': 1},
        {'text': 'Run serverpod generate', 'header': 3, 'step': 2},
      ]);
    });

    test('when exporting them then the Markdown is the blog syntax', () {
      const md =
          ':::warning[Heads up]\n\nThis action cannot be undone.\n\n:::\n\n'
          ':::details\n\n### How does hot reload work?\n\nIt detects changes.'
          '\n\n:::\n\n'
          ':::grid{columns=3 bullets=check}\n\n- Automatic migrations\n'
          '- Stateful hot reload\n\n:::\n\n'
          ':::card\n\nServerpod.\n\n:link[Get started](https://docs.serverpod.dev/)'
          '\n\n:::\n\n'
          '### (1) Define your model\n\n'
          ':button[Go](https://example.com){variant=secondary} :chip[Dart]\n';

      expect(exportWonky(importWonky(md).delta), md);
    });
  });

  group('Given nested containers', () {
    const md =
        ':::card\n\nIntro\n\n:::tip\n\n- One\n- Two\n\n:::\n\nOutro\n\n:::\n';

    test('when importing then the inner lines carry both frames', () {
      final d = importWonky(md).delta;
      final paths = [
        for (final l in WonkyDocument(d).lines)
          [for (final f in Boxes.of(l.attributes)) f.type.value],
      ];

      expect(paths, [
        ['card'],
        ['card', 'callout'],
        ['card', 'callout'],
        ['card'],
      ]);
      expect(validator.validate(d).isValid, isTrue);
    });

    test('when exporting then the directives nest', () {
      expect(exportWonky(importWonky(md).delta), md);
    });

    test('when building the IR then containers nest', () {
      final tree = const DocTreeBuilder().fromDelta(importWonky(md).delta);
      final card = tree.blocks.single as ContainerBlock;

      expect(card.type, BoxType.card);
      expect(card.children, hasLength(3));
      expect((card.children[1] as ContainerBlock).children, hasLength(2));
    });
  });

  group('Given GitHub-flavored import', () {
    test('when the source has directives then they stay text', () {
      final d = codec.importMarkdown(':::card\n:chip[x]\n:::\n').delta;

      expect(
        InlineRun.plainText([
          for (final l in WonkyDocument(d).lines) InlineRun(l.text),
        ]),
        contains(':chip[x]'),
      );
      expect(
        WonkyDocument(d).lines.every((l) => Boxes.of(l.attributes).isEmpty),
        isTrue,
      );
    });
  });

  group('Given text that looks like a directive', () {
    final d = Delta()
      ..insert(':::card')
      ..insert('\n')
      ..insert('see :chip[x] here')
      ..insert('\n')
      ..insert('(1) Not a step')
      ..insert('\n', {'header': 2});

    test(
      'when exporting Wonky Markdown then it is escaped and round-trips',
      () {
        final md = exportWonky(d);

        expect(md, contains(r'\:::card'));
        expect(md, contains(r':chip\[x\]'));
        expect(md, contains(r'## \(1) Not a step'));
        expect(importWonky(md).delta, normalizer.normalize(d).document);
      },
    );

    test('when exporting GitHub Markdown then the directive text is escaped '
        'too and the heading is not', () {
      final md = codec.exportMarkdown(d);

      expect(md, contains(r'\:::card'));
      expect(md, contains('## (1) Not a step'));
    });
  });

  group('Given a Wonky document exported as GitHub Markdown', () {
    final d = importWonky(
      ':::warning[Heads up]\n\nCareful.\n\n- a\n\n:::\n\n'
      ':::grid{columns=2}\n\n- x\n- y\n\n:::\n\n'
      '## (3) Step\n\n:button[Go](https://example.com) :chip[Tag]\n',
    ).delta;

    test('then each element has its GFM form', () {
      expect(
        codec.exportMarkdown(d),
        '> **Heads up**\n>\n> Careful.\n>\n> - a\n\n'
        '- x\n- y\n\n'
        '## (3) Step\n\n[Go](https://example.com) Tag\n',
      );
    });

    test('when converting the document then the change gives the same '
        'GFM content and a valid document', () {
      final change = WonkyToGfm.change(d);
      final converted = d.compose(change);

      expect(validator.validate(converted).isValid, isTrue);
      expect(
        const DocTreeBuilder().fromDelta(converted).hasWonkyElements,
        isFalse,
      );
      expect(codec.exportMarkdown(converted), codec.exportMarkdown(d));
    });

    test('then the inventory counts the elements', () {
      final inv = WonkyToGfm.inventory(d);

      expect(inv.callouts, 1);
      expect(inv.grids, 1);
      expect(inv.steps, 1);
      expect(inv.buttons, 1);
      expect(inv.chips, 1);
      expect(inv.details + inv.cards + inv.arrowLinks, 0);
    });
  });

  group('Given invalid Wonky attributes', () {
    test('when normalizing then exclusions and limits are applied', () {
      final d = Delta()
        ..insert('a', {'chip': true, 'bold': true, 'link': 'https://x.com'})
        ..insert('b', {'linkStyle': 'button', 'italic': true})
        ..insert('c', {
          'linkStyle': 'arrow',
          'link': 'https://x.com',
          'code': true,
        })
        ..insert('\n', {'header': 4, 'step': 2})
        ..insert('t')
        ..insert('\n', {
          'box': [
            {'id': 'a', 'type': 'callout', 'variant': 'nope'},
            {'id': 'b', 'type': 'card', 'variant': 'info'},
            {'id': 'b', 'type': 'details'},
            {'id': 'c', 'type': 'callout', 'variant': 'tip', 'title': ' x]y '},
          ],
        });

      final r = normalizer.normalize(d);

      expect(r.document.toJson(), [
        {
          'insert': 'a',
          'attributes': {'chip': true},
        },
        {
          'insert': 'b',
          'attributes': {'italic': true},
        },
        {
          'insert': 'c',
          'attributes': {'link': 'https://x.com', 'linkStyle': 'arrow'},
        },
        {
          'insert': '\n',
          'attributes': {'header': 4},
        },
        {'insert': 't'},
        {
          'insert': '\n',
          'attributes': {
            'box': [
              {'id': 'b', 'type': 'card'},
              {'id': 'c', 'type': 'callout', 'variant': 'tip', 'title': 'x)y'},
            ],
          },
        },
      ]);
      expect(validator.validate(r.document).isValid, isTrue);
      expect(validator.validate(d).isValid, isFalse);
    });

    test('when an embed line carries a box then it is kept', () {
      final d = Delta()
        ..insert({
          'divider': {'id': 'd1'},
        })
        ..insert('\n', {
          'box': [
            {'id': 'k', 'type': 'card'},
          ],
        });

      expect(normalizer.normalize(d).document, d);
      expect(validator.validate(d).isValid, isTrue);
    });

    test('when a list continues into another container then its indent '
        'restarts', () {
      final d = Delta()
        ..insert('a')
        ..insert('\n', {'list': 'bullet'})
        ..insert('b')
        ..insert('\n', {
          'list': 'bullet',
          'indent': 1,
          'box': [
            {'id': 'k', 'type': 'card'},
          ],
        });

      final out = normalizer.normalize(d).document;

      expect(Attributes.block(WonkyDocument(out).lines[1].attributes), {
        'list': 'bullet',
        'box': [
          {'id': 'k', 'type': 'card'},
        ],
      });
    });
  });

  group('Given a callout in a document', () {
    final doc = importWonky(':::tip\n\nFirst\n\n:::\n').delta;

    test('when inserting Markdown blocks at its end then they go into it', () {
      final edits = DocumentEdits(flavor: MarkdownFlavor.wonky);
      final at = WonkyDocument(doc).lines.first.newlineOffset;

      final r = edits.insertMarkdown(doc, at, '- a\n- b\n');

      final ls = WonkyDocument(r.document).lines;
      expect(ls, hasLength(3));
      expect(ls.map((l) => Boxes.of(l.attributes).single.id).toSet(), {'id-0'});
      expect(ls[1].format.type, BlockType.bullet);
    });

    test('when inserting inline Markdown mid-line then it stays inline', () {
      final edits = DocumentEdits(flavor: MarkdownFlavor.wonky);

      final r = edits.insertMarkdown(doc, 2, '**x**');

      expect(WonkyDocument(r.document).lines.single.text, 'Fixrst');
    });
  });

  group('Given YouTube videos (Write 11 §2.3)', () {
    test('when parsing YouTube URLs then the id and start time are found', () {
      for (final (url, start) in [
        ('https://www.youtube.com/watch?v=AGAQ_N56wCs', null),
        ('https://youtu.be/AGAQ_N56wCs?t=90', 90),
        ('youtube.com/watch?v=AGAQ_N56wCs&t=1m30s', 90),
        ('https://www.youtube.com/embed/AGAQ_N56wCs?start=5', 5),
        ('https://m.youtube.com/shorts/AGAQ_N56wCs', null),
        ('https://www.youtube-nocookie.com/embed/AGAQ_N56wCs', null),
        ('AGAQ_N56wCs', null),
      ]) {
        expect(YouTubeEmbed.parseUrl(url), (
          videoId: 'AGAQ_N56wCs',
          start: start,
        ), reason: url);
      }
      expect(YouTubeEmbed.parseUrl('https://vimeo.com/123'), isNull);
      expect(YouTubeEmbed.parseUrl('https://youtu.be/short'), isNull);
    });

    test('when importing ::youtube then it becomes an embed that exports '
        'the same way', () {
      const md = '::youtube[Launch talk]{id=AGAQ_N56wCs start=90}\n';
      final d = importWonky(md, ids: ['v1']).delta;
      expect(d.operations.first.data, {
        'youtube': {
          'id': 'v1',
          'videoId': 'AGAQ_N56wCs',
          'start': 90,
          'title': 'Launch talk',
        },
      });
      expect(exportWonky(d), md);
      expect(validator.validate(d).isValid, isTrue);
    });

    test('when the id is invalid then the line stays as text with a '
        'warning', () {
      final r = importWonky('::youtube{id=nope}\n');
      expect(r.delta, Delta()..insert('::youtube{id=nope}\n'));
      expect(r.warnings, isNotEmpty);
    });

    test('when text starts with "::youtube" then it is escaped', () {
      final d = Delta()..insert('::youtube{id=AGAQ_N56wCs}\n');
      final md = exportWonky(d);
      expect(md, startsWith(r'\:'));
      expect(importWonky(md).delta, d);
    });

    test(
      'when converting to GitHub Markdown then it is a link to the video',
      () {
        final d = importWonky(
          '::youtube{id=AGAQ_N56wCs start=90}\n',
          ids: ['v1'],
        ).delta;
        expect(WonkyToGfm.inventory(d).videos, 1);
        expect(
          d.compose(WonkyToGfm.change(d)),
          Delta()
            ..insert('https://www.youtube.com/watch?v=AGAQ_N56wCs&t=90s', {
              'link': 'https://www.youtube.com/watch?v=AGAQ_N56wCs&t=90s',
            })
            ..insert('\n'),
        );
      },
    );
  });

  group('Given random Wonky documents', () {
    propertyTest('when exporting and importing Wonky Markdown then the delta '
        'round-trips', (random, _) {
      checkWonkyRoundTrip(
        DeltaGen(
          random,
          options: const DeltaGenOptions(wonky: true),
        ).document(),
      );
    }, runs: 300);

    propertyTest('when normalizing a change on its lines then it equals '
        'normalizing it on the whole document', (random, _) {
      final gen = DeltaGen(random, options: const DeltaGenOptions(wonky: true));
      final doc = gen.document();
      final change = EditGen(random, deltaGen: gen).change(doc);

      expect(
        normalizer.normalizedChange(doc, change),
        normalizer.normalizeChange(doc, change).change,
        reason: 'doc: ${doc.toJson()}\nchange: ${change.toJson()}',
      );
    }, runs: 200);

    propertyTest('when converting to GitHub Markdown then the document is '
        'valid and has no Wonky elements', (random, _) {
      final doc = DeltaGen(
        random,
        options: const DeltaGenOptions(wonky: true, overlays: true),
      ).document();
      final converted = doc.compose(WonkyToGfm.change(doc));

      expect(validator.validate(converted).issues, isEmpty);
      expect(WonkyToGfm.inventory(converted).isEmpty, isTrue);
    }, runs: 200);

    propertyTest('when normalizing then the result is valid and normalizing '
        'again changes nothing', (random, _) {
      final raw = DeltaGen(
        random,
        options: const DeltaGenOptions(wonky: true, overlays: true),
      ).rawDocument();
      final once = normalizer.normalize(raw).document;

      expect(validator.validate(once).issues, isEmpty);
      expect(normalizer.normalize(once).document, once);
    }, runs: 200);
  });
}

/// `import(export(D, wonky), wonky) == normalize(D)` (Write 11 §5.4), with
/// container and embed ids replayed in import order.
void checkWonkyRoundTrip(Delta d) {
  const codec = MarkdownCodec();
  final normalized = const WonkyDeltaNormalizer().normalize(d).document;
  final ids = <String>[];
  var prevPath = const <BoxFrame>[];
  for (final line in WonkyDocument(normalized).lines) {
    final path = Boxes.of(line.attributes);
    for (var k = Boxes.commonDepth(prevPath, path); k < path.length; k++) {
      ids.add(path[k].id);
    }
    prevPath = path;
    if (line.embed case final e?) ids.add(e.id);
  }
  var next = 0;

  final markdown = codec.exportMarkdown(
    normalized,
    options: const MarkdownExportOptions(flavor: MarkdownFlavor.wonky),
  );
  final back = codec.importMarkdown(
    markdown,
    options: ImportOptions(
      flavor: MarkdownFlavor.wonky,
      idGenerator: () => next < ids.length ? ids[next++] : 'extra-${next++}',
    ),
  );

  expect(
    back.delta.toJson(),
    equals(normalized.toJson()),
    reason: 'Markdown:\n$markdown',
  );
}
