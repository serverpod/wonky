import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:wonky_write_core/testing.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import '../export/export_support.dart';

const _ns =
    'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
    'xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" '
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
    'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
    'xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" '
    'xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" '
    'xmlns:xlink="http://www.w3.org/1999/xlink" '
    'xmlns:dc="http://purl.org/dc/elements/1.1/" '
    'xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" '
    'xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"';

/// LibreOffice-like common styles, page layout (A4, 2 cm margins, header)
/// and master page.
const _styles =
    '<office:document-styles $_ns office:version="1.3">'
    '<office:font-face-decls>'
    '<style:font-face style:name="Liberation Serif" svg:font-family="&apos;Liberation Serif&apos;" style:font-family-generic="roman" style:font-pitch="variable"/>'
    '<style:font-face style:name="Liberation Mono" svg:font-family="&apos;Liberation Mono&apos;" style:font-family-generic="modern" style:font-pitch="fixed"/>'
    '</office:font-face-decls>'
    '<office:styles>'
    '<style:default-style style:family="paragraph"><style:text-properties style:font-name="Liberation Serif" fo:language="de" fo:country="DE"/></style:default-style>'
    '<style:style style:name="Standard" style:family="paragraph" style:class="text"/>'
    '<style:style style:name="Heading" style:family="paragraph" style:parent-style-name="Standard"><style:text-properties fo:font-weight="bold"/></style:style>'
    '<style:style style:name="Heading_20_1" style:display-name="Heading 1" style:family="paragraph" style:parent-style-name="Heading" style:default-outline-level="1"/>'
    '<style:style style:name="Quotations" style:family="paragraph" style:parent-style-name="Standard"/>'
    '<style:style style:name="Preformatted_20_Text" style:display-name="Preformatted Text" style:family="paragraph" style:parent-style-name="Standard"><style:text-properties style:font-name="Liberation Mono"/></style:style>'
    '<style:style style:name="Table_20_Contents" style:display-name="Table Contents" style:family="paragraph" style:parent-style-name="Standard"/>'
    '<style:style style:name="Table_20_Heading" style:display-name="Table Heading" style:family="paragraph" style:parent-style-name="Table_20_Contents"><style:paragraph-properties fo:text-align="center"/><style:text-properties fo:font-weight="bold"/></style:style>'
    '<style:style style:name="Source_20_Text" style:display-name="Source Text" style:family="text"><style:text-properties style:font-name="Liberation Mono"/></style:style>'
    '<style:style style:name="Internet_20_link" style:display-name="Internet link" style:family="text"><style:text-properties fo:color="#000080" style:text-underline-style="solid"/></style:style>'
    '<text:list-style style:name="Numbering_20_123" style:display-name="Numbering 123">'
    '<text:list-level-style-number text:level="1" style:num-suffix="." style:num-format="1"/>'
    '</text:list-style>'
    '</office:styles>'
    '<office:automatic-styles>'
    '<style:page-layout style:name="pm1"><style:page-layout-properties fo:page-width="21.001cm" fo:page-height="29.7cm" fo:margin-top="1cm" fo:margin-bottom="2cm" fo:margin-left="2cm" fo:margin-right="2cm"/>'
    '<style:header-style><style:header-footer-properties fo:min-height="0.5cm" fo:margin-bottom="0.5cm"/></style:header-style></style:page-layout>'
    '</office:automatic-styles>'
    '<office:master-styles><style:master-page style:name="Standard" style:page-layout-name="pm1">'
    '<style:header><text:p text:style-name="Standard">Running head</text:p></style:header>'
    '</style:master-page></office:master-styles>'
    '</office:document-styles>';

/// LibreOffice-style automatic styles of `content.xml`.
const _autoStyles =
    '<style:style style:name="P1" style:family="paragraph" style:parent-style-name="Standard"><style:paragraph-properties fo:text-align="center"/></style:style>'
    '<style:style style:name="P2" style:family="paragraph" style:parent-style-name="Table_20_Contents"><style:paragraph-properties fo:text-align="end"/></style:style>'
    '<style:style style:name="P3" style:family="paragraph" style:parent-style-name="Standard"><style:paragraph-properties fo:border-bottom="0.06pt solid #000000"/></style:style>'
    '<style:style style:name="T1" style:family="text"><style:text-properties fo:font-weight="bold" style:font-weight-asian="bold"/></style:style>'
    '<style:style style:name="T2" style:family="text"><style:text-properties fo:font-style="italic"/></style:style>'
    '<style:style style:name="T3" style:family="text"><style:text-properties style:text-line-through-style="solid" style:text-line-through-type="single"/></style:style>'
    '<style:style style:name="T4" style:family="text"><style:text-properties style:font-name="Liberation Mono"/></style:style>'
    '<style:style style:name="T5" style:family="text"><style:text-properties style:text-underline-style="solid" fo:color="#ff0000"/></style:style>'
    '<style:style style:name="T6" style:family="text"><style:text-properties fo:font-weight="600"/></style:style>'
    '<text:list-style style:name="L1">'
    '<text:list-level-style-bullet text:level="1" text:bullet-char="•"/>'
    '<text:list-level-style-number text:level="2" style:num-suffix="." style:num-format="a"/>'
    '</text:list-style>';

Uint8List lo(
  String body, {
  String autoStyles = _autoStyles,
  String styles = _styles,
  Map<String, Uint8List> pictures = const {},
  String mimetype = 'application/vnd.oasis.opendocument.text',
}) => DeterministicZip.encode(
  [
    ZipEntry.text('mimetype', mimetype, store: true),
    ZipEntry.text(
      'META-INF/manifest.xml',
      '<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"/>',
    ),
    ZipEntry.text(
      'meta.xml',
      '<office:document-meta $_ns><office:meta><dc:title>LO title</dc:title>'
          '</office:meta></office:document-meta>',
    ),
    ZipEntry.text('styles.xml', styles),
    ZipEntry.text(
      'content.xml',
      '<office:document-content $_ns office:version="1.3">'
          '<office:automatic-styles>$autoStyles</office:automatic-styles>'
          '<office:body><office:text>$body</office:text></office:body>'
          '</office:document-content>',
    ),
    for (final p in pictures.entries) ZipEntry(p.key, p.value),
  ],
  first: const ['mimetype'],
);

String _p(String inner, {String style = 'Standard'}) =>
    '<text:p text:style-name="$style">$inner</text:p>';

String _span(String style, String text) =>
    '<text:span text:style-name="$style">$text</text:span>';

ImportOptions _opts() {
  var n = 0;
  return ImportOptions(idGenerator: () => 'e${n++}', fileName: 'f.odt');
}

ImportResult _import(Uint8List bytes) =>
    const OdtImporter().importSync(bytes, _opts());

String _md(ImportResult r) => const MarkdownCodec().exportMarkdown(r.delta);

Set<ImportWarningKind> _kinds(ImportResult r) =>
    r.warnings.map((w) => w.kind).toSet();

/// [delta] with embed ids numbered in order and image sources replaced by
/// `img<n>` (sources differ between export and import).
List<Object?> _normalized(Delta delta) {
  var id = 0;
  final srcs = <String, String>{};
  return [
    for (final op in CellCanon.canonical(delta).toJson())
      if (op['insert'] is Map)
        {
          ...op,
          'insert': {
            for (final e in (op['insert'] as Map).entries)
              e.key: {
                ...(e.value as Map),
                'id': 'id${id++}',
                if ((e.value as Map).containsKey('src'))
                  'src': srcs.putIfAbsent(
                    (e.value as Map)['src'] as String,
                    () => 'img${srcs.length}',
                  ),
              },
          },
        }
      else
        op,
  ];
}

void main() {
  group('Given a LibreOffice-style document', () {
    test('when importing then headings, spans and links are mapped', () {
      final r = _import(
        lo(
          '<text:h text:style-name="Heading_20_1" text:outline-level="2">Title ${_span('T1', 'bold')}</text:h>'
          '${_p('Plain ${_span('T1', 'b')} ${_span('T2', 'i')} ${_span('T3', 's')} ${_span('T4', 'mono')} '
          '${_span('T6', 'semi')} ${_span('T5', 'under')} and <text:a xlink:type="simple" xlink:href="https://example.com/x" text:style-name="Internet_20_link">link</text:a>.', style: 'P1')}'
          '${_p('Code ${_span('Source_20_Text', 'x = 1')}')}',
        ),
      );

      expect(
        _md(r),
        '## Title **bold**\n\n'
        'Plain **b** *i* ~~s~~ `mono` **semi** under and '
        '[link](https://example.com/x).\n\n'
        'Code `x = 1`\n',
      );
      expect(r.title, 'LO title');
      expect(r.language, 'de-DE');
      final formatting = r.warnings
          .where((w) => w.kind == ImportWarningKind.formattingRemoved)
          .single;
      expect(formatting.message, contains('underline'));
      expect(formatting.message, contains('alignment'));
    });

    test(
      'when importing white space then text:s, tabs and breaks are kept',
      () {
        final r = _import(
          lo(
            _p('  a<text:s text:c="3"/>b<text:tab/>c<text:line-break/>d   e '),
          ),
        );
        final ops = CellCanon.canonical(r.delta).toJson();
        expect(ops.first['insert'], 'a   b    c d e \n');
      },
    );

    test('when importing quotes, code and rules then blocks are mapped', () {
      final r = _import(
        lo(
          _p('Quoted', style: 'Quotations') +
              _p('if (x) {', style: 'Preformatted_20_Text') +
              _p('<text:s text:c="2"/>y();', style: 'Preformatted_20_Text') +
              _p('}', style: 'Preformatted_20_Text') +
              _p('', style: 'P3') +
              _p(_span('T4', 'mono only')),
        ),
      );

      expect(
        _md(r),
        '> Quoted\n\n```\nif (x) {\n  y();\n}\n```\n\n---\n\n```\nmono only\n```\n',
      );
    });

    test('when importing nested lists then kinds follow the list style levels', () {
      final r = _import(
        lo(
          '<text:list text:style-name="L1">'
          '<text:list-item>${_p('bullet')}'
          '<text:list><text:list-item>${_p('letter')}</text:list-item>'
          '<text:list-item>${_p('☑ done')}</text:list-item></text:list>'
          '</text:list-item>'
          '<text:list-item>${_p('☐ open')}</text:list-item>'
          '</text:list>'
          '${_p('Between')}'
          '<text:list text:style-name="Numbering_20_123">'
          '<text:list-item text:start-value="3">${_p('three')}</text:list-item>'
          '</text:list>',
        ),
      );

      expect(
        _md(r),
        '- bullet\n  1. letter\n  - [x] done\n- [ ] open\n\nBetween\n\n1. three\n',
      );
      expect(_kinds(r), contains(ImportWarningKind.orderedListStart));
    });

    test('when importing a table then header, spans and alignment are mapped', () {
      final r = _import(
        lo(
          '<table:table table:name="T">'
          '<table:table-column table:number-columns-repeated="3"/>'
          '<table:table-header-rows><table:table-row>'
          '<table:table-cell>${_p('Name', style: 'Table_20_Heading')}</table:table-cell>'
          '<table:table-cell table:number-columns-spanned="2">${_p('Value', style: 'Table_20_Heading')}</table:table-cell>'
          '<table:covered-table-cell/>'
          '</table:table-row></table:table-header-rows>'
          '<table:table-row>'
          '<table:table-cell>${_p('a ${_span('T1', 'b')}', style: 'Table_20_Contents')}</table:table-cell>'
          '<table:table-cell>${_p('1', style: 'P2')}</table:table-cell>'
          '<table:table-cell>${_p('x', style: 'Table_20_Contents')}${_p('y', style: 'Table_20_Contents')}</table:table-cell>'
          '</table:table-row></table:table>',
        ),
      );

      final table =
          const DocTreeBuilder().fromDelta(r.delta).blocks.first as TableBlock;
      expect(table.id, 'e0');
      expect(table.align, [null, CellAlign.right, null]);
      expect(table.cellMarkdown, [
        ['Name', 'Value', ''],
        ['a **b**', '1', 'x y'],
      ]);
      expect(_kinds(r), contains(ImportWarningKind.tableFlattened));
    });

    test('when importing an image frame then the picture is collected', () {
      final png = pngBytes();
      final r = _import(
        lo(
          '${_p('<draw:frame draw:name="Image1" text:anchor-type="as-char" svg:width="2cm" svg:height="1cm">'
          '<draw:image xlink:href="Pictures/a.png" xlink:type="simple"/>'
          '<svg:desc>A logo</svg:desc></draw:frame>')}'
          '${_p('Logo caption', style: 'Caption')}'
          '<table:table><table:table-row><table:table-cell>'
          '${_p('<draw:frame><draw:image xlink:href="Pictures/a.png"/><svg:title>In cell</svg:title></draw:frame>')}'
          '</table:table-cell></table:table-row></table:table>',
          styles: _styles.replaceFirst(
            '</office:styles>',
            '<style:style style:name="Caption" style:family="paragraph" style:parent-style-name="Standard"/></office:styles>',
          ),
          pictures: {'Pictures/a.png': png},
        ),
      );

      final image =
          CellCanon.canonical(r.delta).toJson().first['insert'] as Map;
      expect(image['image'], {
        'id': 'e0',
        'src': 'import-image://img1',
        'alt': 'A logo',
        'title': 'Logo caption',
      });
      expect(r.images.single.bytes, png);
      expect(r.images.single.mime, 'image/png');
      expect(_md(r), contains('| In cell |'));
      expect(_kinds(r), contains(ImportWarningKind.imageFlattened));
    });

    test('when importing notes, comments and tracked changes then warnings '
        'are reported', () {
      final r = _import(
        lo(
          '<text:tracked-changes><text:changed-region text:id="c1"><text:deletion>'
          '${_p('gone')}</text:deletion></text:changed-region></text:tracked-changes>'
          '${_p('Text<text:note text:note-class="footnote"><text:note-citation>1</text:note-citation>'
          '<text:note-body>${_p('A note')}</text:note-body></text:note> '
          '<office:annotation><dc:creator>Bo</dc:creator>${_p('Comment')}</office:annotation>'
          '<text:change-start text:change-id="c2"/>kept<text:change-end text:change-id="c2"/>')}',
        ),
      );

      expect(_md(r), 'Text\\[1\\] kept\n\n## Notes\n\n1. A note\n');
      expect(
        _kinds(r),
        containsAll([
          ImportWarningKind.footnotesAppended,
          ImportWarningKind.commentsDropped,
          ImportWarningKind.trackedChangesAccepted,
          ImportWarningKind.headersFootersDropped,
        ]),
      );
    });

    test(
      'when importing then the master page layout becomes the page setup',
      () {
        final r = _import(lo(_p('x')));

        final ps = r.pageSetup!;
        expect(ps.widthPt, closeTo(595.3, 0.1));
        expect(ps.heightPt, closeTo(841.9, 0.1));
        // 1 cm page margin + 0.5 cm header + 0.5 cm spacing.
        expect(ps.marginTopPt, closeTo(56.69, 0.01));
        expect(ps.marginBottomPt, closeTo(56.69, 0.01));
        expect(ps.marginLeftPt, closeTo(56.69, 0.01));
      },
    );
  });

  group('Given invalid or damaged input', () {
    test('when the bytes are not a zip then a format exception is thrown', () {
      expect(
        () => _import(Uint8List.fromList(utf8.encode('hello'))),
        throwsA(isA<ImportFormatException>()),
      );
    });

    test('when the package is another ODF type then it is rejected', () {
      expect(
        () => _import(
          lo('', mimetype: 'application/vnd.oasis.opendocument.spreadsheet'),
        ),
        throwsA(isA<ImportFormatException>()),
      );
    });

    test('when content.xml is malformed then its text is salvaged', () {
      final bytes = DeterministicZip.encode([
        ZipEntry.text(
          'mimetype',
          'application/vnd.oasis.opendocument.text',
          store: true,
        ),
        ZipEntry.text(
          'content.xml',
          '<office:document-content $_ns><office:body><office:text>'
              '<text:p>One &amp; two<text:p>broken</text:p>',
        ),
      ]);
      final r = _import(bytes);

      expect(_md(r), contains('One & two'));
      expect(_kinds(r), contains(ImportWarningKind.contentDropped));
    });
  });

  group('Given an ODT exported by Wonky Write', () {
    final logo = ResolvedImage(
      bytes: pngBytes(),
      mime: 'image/png',
      widthPx: 4,
      heightPx: 2,
    );
    const source = '''# Round trip

Intro with **bold**, *italic*, ~~strike~~, `code`, ***both*** and a [link](https://example.com/a?b=1).
Second line  with  spaces.

## Lists

1. First
2. Second
   - nested **bullet**
     1. deep
3. Third

- [x] done
- [ ] todo
  - [ ] nested todo

Between

1. restarted

> A quote
> second line

```
void main() {
  print('hi');
}
```

---

![Logo](https://img.example.com/logo.png "The logo")

| Name | Value | Note |
| :--- | ---: | :---: |
| a | **1** | `x` |
| b | 2 | [l](https://example.com) |
''';

    for (final theme in BuiltinThemes.all) {
      test('when importing the ${theme.key} export then the source delta '
          'returns', () async {
        final src = md(source);
        final exported = await const OdtExporter().export(
          input(
            src,
            images: {'https://img.example.com/logo.png': logo},
            theme: theme.key,
          ),
          const OfficeExportOptions(includeToc: true),
        );
        final r = _import(exported.bytes);

        expect(_normalized(r.delta), _normalized(src));
        expect(r.images.single.bytes, logo.bytes);
        expect(r.title, 'Q3 planning');
        expect(r.language, 'en');
        expect(r.pageSetup!.widthPt, 612);
        expect(r.pageSetup!.marginTopPt, closeTo(72, 0.01));
      });
    }
  });
}
