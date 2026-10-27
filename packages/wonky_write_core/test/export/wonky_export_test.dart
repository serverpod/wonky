import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'export_support.dart';

/// Exports of Wonky Markdown elements (Write 11 §9).
void main() {
  Delta wonky(String markdown) {
    var n = 0;
    return const MarkdownCodec()
        .importMarkdown(
          markdown,
          options: ImportOptions(
            flavor: MarkdownFlavor.wonky,
            idGenerator: () => 'e${n++}',
          ),
        )
        .delta;
  }

  const source =
      '## (1) Define your model\n\n'
      ':::card\n\nCard intro\n\n'
      ':::warning[Heads up]\n\nCannot be undone.\n\n- one\n- two\n\n:::\n\n'
      ':::details\n\n### How does it work?\n\nIt detects changes.\n\n:::\n\n'
      ':::\n\n'
      ':::grid{columns=3 bullets=check}\n\n- Migrations\n- Hot reload\n'
      '- AI tooling\n- Fourth item\n\n:::\n\n'
      ':button[Get started](https://example.com) '
      ':button[More](https://example.com/more){variant=secondary} '
      ':link[Docs](https://docs.example.com) :chip[Dart] :chip[Flutter]\n';

  group('Given a document with nested containers, a grid, a numbered '
      'heading, buttons and chips', () {
    test('when exporting PDF then every text is drawn and the links are '
        'kept', () async {
      final a = await const PdfExporter(
        compress: false,
      ).export(input(wonky(source)), const PdfExportOptions());
      final text = latin1.decode(a.bytes);

      expect(text, startsWith('%PDF-1.4'));
      expect(a.pageCount, 1);
      // Standard fonts draw each word as its own string.
      for (final word in [
        'HEADS',
        'UP',
        'Cannot',
        'does',
        'detects',
        'Card',
        'Migrations',
        'Fourth',
        'started',
        'Dart',
        'Flutter',
        'Define',
      ]) {
        expect(text, contains('($word'), reason: word);
      }
      expect(text, contains('/URI(https://example.com)'));
      expect(text, contains('/URI(https://example.com/more)'));
      expect(text, contains('/URI(https://docs.example.com)'));
    });

    test('when exporting PDF with every built-in theme in light and dark '
        'then it succeeds', () async {
      for (final b in BuiltinThemes.all) {
        for (final v in ThemeVariant.values) {
          final a = await const PdfExporter().export(
            input(wonky(source), theme: b.key, variant: v),
            const PdfExportOptions(),
          );
          expect(a.pageCount, greaterThan(0), reason: '${b.key} $v');
        }
      }
    });

    test('when a container spans pages then the PDF paginates it', () async {
      final long = StringBuffer(':::tip\n\n');
      for (var i = 0; i < 120; i++) {
        long.write('Paragraph number $i in a long tip.\n\n');
      }
      long.write(':::\n');
      final a = await const PdfExporter().export(
        input(wonky(long.toString())),
        const PdfExportOptions(),
      );

      expect(a.pageCount, greaterThan(1));
    });

    test('when exporting DOCX then containers are shaded, the grid is a '
        'table and the step number leads the heading', () async {
      final a = await const DocxExporter().export(
        input(wonky(source)),
        const OfficeExportOptions(),
      );
      final xml = utf8.decode(
        DeterministicZip.decode(a.bytes)['word/document.xml']!,
      );

      expect(xml, contains('>1. <'));
      expect(xml, contains('Heads up'));
      expect(xml, contains('<w:shd '));
      expect(xml, contains('<w:tbl>'));
      expect(xml, contains('Fourth item'));
      expect(xml, contains('Get started'));
      expect(xml, contains('Dart'));
    });

    test('when exporting ODT then containers are shaded, the grid is a '
        'table and the step number leads the heading', () async {
      final a = await const OdtExporter().export(
        input(wonky(source)),
        const OfficeExportOptions(),
      );
      final xml = utf8.decode(DeterministicZip.decode(a.bytes)['content.xml']!);

      expect(xml, contains('1. '));
      expect(xml, contains('Heads up'));
      expect(xml, contains('fo:background-color'));
      expect(xml, contains('<table:table '));
      expect(xml, contains('Fourth item'));
      expect(xml, contains('Get started'));
    });
  });

  group('Given a YouTube video', () {
    const md = '::youtube[Launch talk]{id=AGAQ_N56wCs start=90}\n';

    test('when exporting HTML then the player is embedded', () async {
      final a = await const HtmlExporter().export(
        input(wonky(md)),
        const HtmlExportOptions(),
      );
      final html = utf8.decode(a.bytes);
      expect(
        html,
        contains('src="https://www.youtube.com/embed/AGAQ_N56wCs?start=90"'),
      );
      expect(html, contains('allowfullscreen'));
    });

    test('when exporting PDF then it is a link to the video', () async {
      final a = await const PdfExporter(
        compress: false,
      ).export(input(wonky(md)), const PdfExportOptions());
      final text = latin1.decode(a.bytes);
      expect(text, contains('Launch'));
      expect(text, contains('watch?v=AGAQ_N56wCs'));
    });
  });
}
