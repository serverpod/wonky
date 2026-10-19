import 'dart:async';
import 'dart:convert';

import 'package:html/parser.dart' as html;
import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../support/property.dart';
import 'export_support.dart';

void main() {
  final logo = ResolvedImage(
    bytes: pngBytes(),
    mime: 'image/png',
    widthPx: 4,
    heightPx: 2,
  );
  final images = {'https://img.example.com/logo.png': logo};

  group('Given the Markdown exporters', () {
    test(
      'when exporting .md then front matter, content and file name are produced',
      () async {
        final a = await const MarkdownFileExporter().export(
          input(md(sample)),
          const MarkdownFileExportOptions(),
        );

        final text = utf8.decode(a.bytes);
        expect(a.fileName, 'Q3 planning.md');
        expect(
          text,
          startsWith('---\ntags: [plan, q3]\n---\n\n# Q3 planning\n'),
        );
        expect(
          text,
          contains('![Logo](https://img.example.com/logo.png "The logo")'),
        );
      },
    );

    test(
      'when exporting the zip then images are stored and referenced relatively',
      () async {
        final a = await const MarkdownZipExporter().export(
          input(md(sample), images: images),
          const MarkdownFileExportOptions(),
        );

        final files = DeterministicZip.decode(a.bytes);
        expect(files.keys, containsAll(['document.md', 'images/1-logo.png']));
        expect(
          utf8.decode(files['document.md']!),
          contains('![Logo](images/1-logo.png "The logo")'),
        );
      },
    );

    test('when an image is missing then the zip export warns', () async {
      final a = await const MarkdownZipExporter().export(
        input(md(sample)),
        const MarkdownFileExportOptions(),
      );

      expect(a.warnings.map((w) => w.code), contains('image_unavailable'));
    });

    test('when exporting twice then the zip bytes are identical', () async {
      final a = await const MarkdownZipExporter().export(
        input(md(sample), images: images),
        const MarkdownFileExportOptions(),
      );
      final b = await const MarkdownZipExporter().export(
        input(md(sample), images: images),
        const MarkdownFileExportOptions(),
      );

      expect(a.bytes, equals(b.bytes));
    });
  });

  group('Given the text exporter', () {
    test('when exporting then blocks are rendered as plain text', () async {
      final a = await const TxtExporter().export(
        input(md(sample)),
        const TxtExportOptions(),
      );

      final text = utf8.decode(a.bytes);
      expect(
        text,
        contains(
          'Q3 planning\n\nIntro with bold, italic, strike, code and a link (https://example.com).',
        ),
      );
      expect(
        text,
        contains('1. First\n2. Second\n  - nested\n[x] done\n[ ] todo'),
      );
      expect(text, contains('> A quote'));
      expect(text, contains('----'));
      expect(text, contains('[image: Logo]'));
      expect(text, contains('Name  Value\n----  -----\na     1'));
    });

    test(
      'when wrapping at 20 columns with CRLF then lines are short and CRLF-terminated',
      () async {
        final a = await const TxtExporter().export(
          input(md('one two three four five six seven eight nine ten\n')),
          const TxtExportOptions(wrapColumn: 20, crlf: true),
        );

        expect(
          utf8.decode(a.bytes),
          'one two three four\r\nfive six seven eight\r\nnine ten\r\n',
        );
      },
    );
  });

  group('Given the HTML exporter', () {
    test(
      'when exporting then the document is themed, escaped and structured',
      () async {
        final a = await const HtmlExporter().export(
          input(md(sample), images: images),
          const HtmlExportOptions(),
        );

        final text = utf8.decode(a.bytes);
        final dom = html.parse(text);
        expect(dom.querySelector('title')!.text, 'Q3 planning');
        expect(dom.querySelector('html')!.attributes['lang'], 'en');
        expect(dom.querySelector('h1')!.id, 'h-q3-planning-1');
        expect(dom.querySelectorAll('ol > li').length, 2);
        expect(dom.querySelector('ol li ul li')!.text, 'nested');
        expect(dom.querySelectorAll('li.wonky-task input[disabled]').length, 2);
        expect(
          dom.querySelector('a[href="https://example.com"]')!.attributes['rel'],
          'noopener noreferrer',
        );
        expect(
          dom.querySelector('pre code.language-dart span.tok-string'),
          isNotNull,
        );
        expect(
          dom.querySelector('figure img')!.attributes['src'],
          startsWith('data:image/png;base64,'),
        );
        expect(dom.querySelector('figcaption')!.text, 'The logo');
        expect(
          dom.querySelector('thead th:last-child')!.attributes['style'],
          'text-align: right',
        );
        expect(
          dom.querySelector('style')!.text,
          contains('@media (prefers-color-scheme: dark)'),
        );
        expect(dom.querySelector('style')!.text, contains('.wonky-doc h1'));
      },
    );

    test(
      'when exporting the web page zip then index, style and images are separate files',
      () async {
        final a = await const HtmlZipExporter().export(
          input(md(sample), images: images),
          const HtmlExportOptions(),
        );

        final files = DeterministicZip.decode(a.bytes);
        expect(
          files.keys,
          containsAll(['index.html', 'style.css', 'images/1-logo.png']),
        );
        expect(
          utf8.decode(files['index.html']!),
          contains('<link rel="stylesheet" href="style.css">'),
        );
      },
    );

    test(
      'when text contains markup characters then they are escaped',
      () async {
        final a = await const HtmlExporter().export(
          input(
            md(
              r'a \<script> & b'
              '\n',
            ),
          ),
          const HtmlExportOptions(),
        );

        expect(
          utf8.decode(a.bytes),
          contains('<p>a &lt;script&gt; &amp; b</p>'),
        );
      },
    );

    propertyTest(
      'Given random documents when exporting HTML and importing it then the delta round-trips',
      (random, _) {
        final gen = DeltaGen(
          random,
          options: const DeltaGenOptions(embeds: false, mentions: false),
        );
        final doc = gen.document();
        final tree = const DocTreeBuilder().fromDelta(doc);
        final body = const HtmlBodyWriter().article(tree);

        final back = const HtmlImporter().importFragment(
          body,
          options: ImportOptions(idGenerator: () => 'x'),
        );

        // HTML collapses whitespace runs (exact otherwise).
        String norm(Delta d) => DeltaUtils.text(d)
            .replaceAll(softBreak, '\n')
            .replaceAll(RegExp('[ \u00a0]+'), ' ')
            .split('\n')
            .map((l) => l.trim())
            .join('\n');
        expect(norm(back.delta), norm(doc));
      },
      runs: 100,
    );
  });

  group('Given the PDF exporter', () {
    test(
      'when exporting the sample then a valid PDF with outline and links is produced',
      () async {
        final a = await const PdfExporter(
          compress: false,
        ).export(input(md(sample), images: images), const PdfExportOptions());

        final text = latin1.decode(a.bytes);
        expect(text, startsWith('%PDF-1.4'));
        expect(text.trimRight(), endsWith('%%EOF'));
        expect(a.pageCount, 1);
        expect(text, contains('/Outlines'));
        expect(text, contains('/URI(https://example.com)'));
        expect(text, contains('/Subtype/Image'));
        expect(text, contains('(Q3 planning)'));
      },
    );

    test('when exporting twice then the bytes are identical', () async {
      final a = await const PdfExporter().export(
        input(md(sample), images: images),
        const PdfExportOptions(),
      );
      final b = await const PdfExporter().export(
        input(md(sample), images: images),
        const PdfExportOptions(),
      );

      expect(a.bytes, equals(b.bytes));
    });

    test(
      'when the document is long then it paginates with page numbers in the footer',
      () async {
        final long = md(
          List.generate(
            200,
            (i) => 'Paragraph number $i with some words to fill the line.',
          ).join('\n\n'),
        );
        final setup = PageSetup.fromJson({
          'footer': {'enabled': true, 'center': 'Page {page} of {pages}'},
          'header': {'enabled': false},
        });

        final a = await const PdfExporter(
          compress: false,
        ).export(input(long, pageSetup: setup), const PdfExportOptions());

        expect(a.pageCount, greaterThan(3));
        final text = latin1.decode(a.bytes);
        expect(text, contains('[(Page)]TJ'));
        expect(text, contains('[(${a.pageCount})]TJ'));
      },
    );

    test(
      'when selecting a page range then only those pages are emitted',
      () async {
        final long = md(
          List.generate(200, (i) => 'Paragraph $i.').join('\n\n'),
        );

        final a = await const PdfExporter().export(
          input(long),
          const PdfExportOptions(pageRange: '1-2'),
        );

        expect(a.pageCount, 2);
      },
    );

    test('when Cancel is pressed during a long export on the UI isolate '
        '(a yielder) then the export stops (07 §4.3, W-07)', () async {
      final long = md(
        List.generate(400, (i) => 'Paragraph $i with text.').join('\n\n'),
      );
      final cancel = CancellationToken();
      final yielder = ExportYielder(slice: Duration.zero);
      // A timer only runs when the export gives the event loop a turn.
      Timer.run(cancel.cancel);

      await expectLater(
        const PdfExporter().export(
          input(long, cancel: cancel, yielder: yielder),
          const PdfExportOptions(),
        ),
        throwsA(isA<ExportCancelledException>()),
      );
      expect(yielder.turns, greaterThan(0));
    });

    test('when exporting with a yielder then the bytes equal an export '
        'without one', () async {
      final doc = md(sample);

      final a = await const PdfExporter().export(
        input(doc, yielder: ExportYielder(slice: Duration.zero)),
        const PdfExportOptions(),
      );
      final b = await const PdfExporter().export(
        input(doc),
        const PdfExportOptions(),
      );

      expect(a.bytes, b.bytes);
    });

    test('when counting pages then the counter matches the exporter', () async {
      final long = md(
        List.generate(120, (i) => 'Paragraph $i with text.').join('\n\n'),
      );

      final count = await PdfPageCounter.count(input(long));
      final a = await const PdfExporter().export(
        input(long),
        const PdfExportOptions(),
      );

      expect(count, a.pageCount);
    });

    test(
      'when an image is missing then a placeholder and a warning are produced',
      () async {
        final a = await const PdfExporter().export(
          input(md(sample)),
          const PdfExportOptions(),
        );

        expect(
          a.warnings.map((w) => w.code),
          containsAll(['image_unavailable', 'font_fallback']),
        );
      },
    );

    test(
      'when exporting in dark with a table of contents then it succeeds',
      () async {
        final a = await const PdfExporter(compress: false).export(
          input(md(sample), variant: ThemeVariant.dark, theme: 'technical'),
          const PdfExportOptions(includeToc: true),
        );

        expect(latin1.decode(a.bytes), contains('/Dest'));
      },
    );

    for (final b in BuiltinThemes.all) {
      test('when exporting with ${b.key} then it succeeds', () async {
        final a = await const PdfExporter().export(
          input(md(sample), images: images, theme: b.key),
          const PdfExportOptions(),
        );
        expect(a.pageCount, greaterThanOrEqualTo(1));
      });
    }

    propertyTest(
      'Given random documents when exporting PDF then it never throws',
      (random, _) {
        final doc = DeltaGen(random).document();
        expect(
          const PdfExporter()
              .export(input(doc), const PdfExportOptions())
              .then((a) => a.pageCount),
          completion(greaterThanOrEqualTo(1)),
        );
      },
      runs: 20,
    );
  });
}
