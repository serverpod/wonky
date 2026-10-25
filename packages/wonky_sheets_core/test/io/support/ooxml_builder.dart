import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

const String _main =
    'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const String _rel =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const String _pkgRel =
    'http://schemas.openxmlformats.org/package/2006/relationships';

/// One worksheet of a hand-built XLSX file.
final class TestSheet {
  /// Creates a sheet: [data] is the inner XML of `<sheetData>`, [before]
  /// and [after] are worksheet elements around it (in ECMA order).
  const TestSheet(
    this.name, {
    this.data = '',
    this.before = '',
    this.after = '',
    this.state,
    this.rels = const {},
  });

  final String name;
  final String data;
  final String before;
  final String after;

  /// `hidden` / `veryHidden`.
  final String? state;

  /// Sheet relationships `id → (type suffix, target, external)`.
  final Map<String, (String, String, bool)> rels;
}

/// Builds a minimal XLSX package (11 §12 hand-built fixtures).
///
/// [styles] is the inner XML of `<styleSheet>`; [sharedStrings] are `<si>`
/// bodies; [workbookExtra] is inserted after `<sheets>` (defined names);
/// [parts] adds arbitrary parts, [binaryParts] binary ones (media).
Uint8List buildXlsx(
  List<TestSheet> sheets, {
  String? styles,
  List<String> sharedStrings = const [],
  String workbookPr = '',
  String workbookExtra = '',
  Map<String, String> parts = const {},
  Map<String, List<int>> binaryParts = const {},
}) {
  final archive = Archive();
  void add(String path, String text) =>
      archive.add(ArchiveFile.bytes(path, utf8.encode(text)));
  add(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/></Types>',
  );
  add(
    '_rels/.rels',
    '<Relationships xmlns="$_pkgRel">'
        '<Relationship Id="rId1" Type="$_rel/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );
  final wbRels = StringBuffer('<Relationships xmlns="$_pkgRel">');
  final sheetEls = StringBuffer();
  for (var i = 0; i < sheets.length; i++) {
    final s = sheets[i];
    wbRels.write(
      '<Relationship Id="rId${i + 1}" Type="$_rel/worksheet" Target="worksheets/sheet${i + 1}.xml"/>',
    );
    sheetEls.write(
      '<sheet name="${s.name}" sheetId="${i + 1}"'
      '${s.state == null ? '' : ' state="${s.state}"'} r:id="rId${i + 1}"/>',
    );
    add(
      'xl/worksheets/sheet${i + 1}.xml',
      '<?xml version="1.0" encoding="UTF-8"?>'
          '<worksheet xmlns="$_main" xmlns:r="$_rel">${s.before}'
          '<sheetData>${s.data}</sheetData>${s.after}</worksheet>',
    );
    if (s.rels.isNotEmpty) {
      add(
        'xl/worksheets/_rels/sheet${i + 1}.xml.rels',
        '<Relationships xmlns="$_pkgRel">'
            '${[for (final e in s.rels.entries) '<Relationship Id="${e.key}" Type="$_rel/${e.value.$1}" Target="${e.value.$2}"${e.value.$3 ? ' TargetMode="External"' : ''}/>'].join()}'
            '</Relationships>',
      );
    }
  }
  var n = sheets.length;
  if (styles != null) {
    wbRels.write(
      '<Relationship Id="rId${++n}" Type="$_rel/styles" Target="styles.xml"/>',
    );
    add('xl/styles.xml', '<styleSheet xmlns="$_main">$styles</styleSheet>');
  }
  if (sharedStrings.isNotEmpty) {
    wbRels.write(
      '<Relationship Id="rId${++n}" Type="$_rel/sharedStrings" Target="sharedStrings.xml"/>',
    );
    add(
      'xl/sharedStrings.xml',
      '<sst xmlns="$_main">${[for (final s in sharedStrings) '<si>$s</si>'].join()}</sst>',
    );
  }
  wbRels.write('</Relationships>');
  add('xl/_rels/workbook.xml.rels', wbRels.toString());
  add(
    'xl/workbook.xml',
    '<workbook xmlns="$_main" xmlns:r="$_rel">$workbookPr<sheets>$sheetEls</sheets>'
        '$workbookExtra</workbook>',
  );
  parts.forEach(add);
  binaryParts.forEach(
    (path, bytes) => archive.add(ArchiveFile.bytes(path, bytes)),
  );
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

/// Styles with fonts (0: Calibri 11, 1: bold, 2: italic), a date and a
/// `0.00` number format and the cell formats:
/// 0 default, 1 bold, 2 italic, 3 date (`yyyy-mm-dd`), 4 bold + `0.00`.
const String kTestStyles =
    '<numFmts count="2"><numFmt numFmtId="164" formatCode="yyyy-mm-dd"/>'
    '<numFmt numFmtId="165" formatCode="0.00"/></numFmts>'
    '<fonts count="3"><font><sz val="11"/><name val="Calibri"/></font>'
    '<font><b/><sz val="11"/><name val="Calibri"/></font>'
    '<font><i/><sz val="11"/><name val="Calibri"/></font></fonts>'
    '<fills count="2"><fill><patternFill patternType="none"/></fill>'
    '<fill><patternFill patternType="gray125"/></fill></fills>'
    '<borders count="1"><border/></borders>'
    '<cellXfs count="5"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>'
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0"/>'
    '<xf numFmtId="0" fontId="2" fillId="0" borderId="0"/>'
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0"/>'
    '<xf numFmtId="165" fontId="1" fillId="0" borderId="0"/></cellXfs>';
