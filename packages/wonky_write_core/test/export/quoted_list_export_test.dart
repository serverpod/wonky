import 'dart:convert';

import 'package:test/test.dart';
import 'package:wonky_write_core/wonky_write_core.dart';

import 'export_support.dart';

/// Exports of a list inside a quote (Write 02 §1.2, 07; T-19).
void main() {
  const source = '> Said:\n>\n> - one\n> - two\n\n- outside\n';

  test('Given a list in a quote when exporting text then the items are '
      'behind "> " and the list outside is not', () async {
    final a = await const TxtExporter().export(
      input(md(source)),
      const TxtExportOptions(),
    );

    expect(utf8.decode(a.bytes), '> Said:\n>\n> - one\n> - two\n\n- outside\n');
  });

  test('Given a list in a quote when exporting RTF then the quoted items '
      'have the quote bar and the outside item does not', () async {
    final a = await const RtfExporter().export(
      input(md(source)),
      const RtfExportOptions(),
    );
    final rtf = ascii.decode(a.bytes);
    // The paragraph's group up to [text]: from the previous `\par` end.
    String paragraphOf(String text) {
      final at = rtf.indexOf(text);
      final ends = RegExp(r'\\par(?![a-z])').allMatches(rtf.substring(0, at));
      return rtf.substring(ends.isEmpty ? 0 : ends.last.end, at);
    }

    expect(paragraphOf('one'), contains(r'\brdrl'));
    expect(paragraphOf('two'), contains(r'\brdrl'));
    expect(paragraphOf('outside'), isNot(contains(r'\brdrl')));
  });

  test('Given a list in a quote when exporting DOCX then the quoted items '
      'are numbered with a left border', () async {
    final a = await const DocxExporter().export(
      input(md(source)),
      const OfficeExportOptions(),
    );
    final xml = utf8.decode(
      DeterministicZip.decode(a.bytes)['word/document.xml']!,
    );
    String paragraphOf(String text) {
      final at = xml.indexOf('>$text<');
      return xml.substring(xml.lastIndexOf('<w:p>', at), at);
    }

    expect(paragraphOf('one'), contains('<w:numPr>'));
    expect(paragraphOf('one'), contains('<w:left '));
    expect(paragraphOf('outside'), isNot(contains('<w:left ')));
  });

  test('Given a list in a quote when exporting ODT and PDF then both '
      'succeed', () async {
    final odt = await const OdtExporter().export(
      input(md(source)),
      const OfficeExportOptions(),
    );
    final pdf = await const PdfExporter().export(
      input(md(source)),
      const PdfExportOptions(),
    );

    expect(odt.bytes, isNotEmpty);
    expect(pdf.bytes, isNotEmpty);
  });
}
