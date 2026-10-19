// Generates the file-compatibility corpus (Sheets 05 §22, 11 §12; CQ-61):
// XLSX and ODS files laid out the way Excel and LibreOffice write them
// (shared strings, shared formulas, `t="str"`/`t="b"`/`t="e"` results, a
// date style, a second sheet with cross-sheet references; ODS `of:=`
// formulas with `office:value` results and `calcext:value-type="error"`),
// each formula cell carrying its cached result. The cached results are the
// expected values: `test/io/compat/compat_corpus_test.dart` imports every
// file, recalculates it with the engine and compares.
//
//   dart run tool/compat/gen_compat_fixtures.dart    # from the package root
//
// Writes `test/fixtures/compat/*.xlsx|*.ods`. Real files saved by Excel,
// LibreOffice or Google Sheets go into the same folder (the test picks up
// every file there); they must carry cached values (save after a recalc).
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

/// Fixed timestamp of the zip entries, so regenerating is byte-stable.
final _modified = DateTime.utc(2026, 10, 18);

void main() {
  final dir = Directory('test/fixtures/compat')..createSync(recursive: true);
  File('${dir.path}/excel_budget.xlsx').writeAsBytesSync(excelBudget());
  File('${dir.path}/libreoffice_grades.ods').writeAsBytesSync(loGrades());
  stdout.writeln('Wrote ${dir.path}/excel_budget.xlsx, libreoffice_grades.ods');
}

List<int> _zip(Map<String, String> parts, {String? storedFirst}) {
  final archive = Archive();
  void add(String name, String text, {bool store = false}) {
    final bytes = utf8.encode(text);
    final f = ArchiveFile(name, bytes.length, bytes)
      ..lastModTime = _modified.millisecondsSinceEpoch ~/ 1000;
    if (store) f.compression = CompressionType.none;
    archive.addFile(f);
  }

  if (storedFirst != null) add(storedFirst, parts[storedFirst]!, store: true);
  for (final e in parts.entries) {
    if (e.key != storedFirst) add(e.key, e.value);
  }
  return ZipEncoder().encode(archive);
}

// ------------------------------------------------------------------ XLSX

const _ns = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _r =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _pr = 'http://schemas.openxmlformats.org/package/2006/relationships';
const _xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';

/// A budget as Excel saves it: items × quantity × price with a shared
/// formula, totals, text/boolean/error/date results, an exact VLOOKUP and a
/// second sheet that references the first.
List<int> excelBudget() {
  const strings = [
    'Item', 'Qty', 'Price', 'Total', 'Apple', 'Pear', 'Plum', 'Fig', //
    'Sum', 'big', 'Rate', 'Taxed',
  ];
  int s(String t) => strings.indexOf(t);
  String str(String ref, String t) => '<c r="$ref" t="s"><v>${s(t)}</v></c>';
  String number(String ref, num v) => '<c r="$ref"><v>$v</v></c>';

  final rows = <String>[
    '<row r="1">${str('A1', 'Item')}${str('B1', 'Qty')}${str('C1', 'Price')}'
        '${str('D1', 'Total')}</row>',
  ];
  const items = [
    ('Apple', 3, 0.5),
    ('Pear', 10, 1.25),
    ('Plum', 4, 2),
    ('Fig', 7, 3.5),
  ];
  for (var i = 0; i < items.length; i++) {
    final r = i + 2;
    final (name, qty, price) = items[i];
    final f = i == 0
        ? '<f t="shared" ref="D2:D5" si="0">B2*C2</f>'
        : '<f t="shared" si="0"/>';
    rows.add(
      '<row r="$r">${str('A$r', name)}${number('B$r', qty)}${number('C$r', price)}'
      '<c r="D$r">$f<v>${qty * price}</v></c></row>',
    );
  }
  // 1.5 + 12.5 + 8 + 24.5 = 46.5; average price 1.8125.
  rows.add(
    '<row r="7">${str('A7', 'Sum')}'
    '<c r="B7"><f>SUM(B2:B5)</f><v>24</v></c>'
    '<c r="C7"><f>AVERAGE(C2:C5)</f><v>1.8125</v></c>'
    '<c r="D7"><f>SUM(D2:D5)</f><v>46.5</v></c>'
    '<c r="E7" t="str"><f>IF(D7&gt;40,"big","small")</f><v>big</v></c>'
    '<c r="F7" t="b"><f>ISERROR(1/0)</f><v>1</v></c>'
    '<c r="G7" t="e"><f>1/0</f><v>#DIV/0!</v></c>'
    '<c r="H7" s="1"><f>DATE(2024,2,29)</f><v>45351</v></c>'
    '</row>',
  );
  rows.add(
    '<row r="8">'
    '<c r="B8"><f>VLOOKUP("Pear",A2:D5,4,FALSE)</f><v>12.5</v></c>'
    '<c r="C8"><f>SUMIF(B2:B5,"&gt;5",D2:D5)</f><v>37</v></c>'
    '<c r="D8"><f>ROUND(D7/B7,2)</f><v>1.94</v></c>'
    '<c r="E8" t="str"><f>TEXT(H7,"yyyy-mm-dd")</f><v>2024-02-29</v></c>'
    '<c r="F8"><f>COUNTIF(A2:A5,"P*")</f><v>2</v></c>'
    '<c r="G8" t="e"><f>MATCH("Kiwi",A2:A5,0)</f><v>#N/A</v></c>'
    '</row>',
  );
  final budget =
      '$_xml<worksheet xmlns="$_ns" xmlns:r="$_r"><dimension ref="A1:H8"/>'
      '<sheetData>${rows.join()}</sheetData></worksheet>';
  final rates =
      '$_xml<worksheet xmlns="$_ns" xmlns:r="$_r"><dimension ref="A1:B2"/>'
      '<sheetData>'
      '<row r="1">${str('A1', 'Rate')}${number('B1', 0.2)}</row>'
      '<row r="2">${str('A2', 'Taxed')}'
      '<c r="B2"><f>Budget!D7*(1+B1)</f><v>55.8</v></c></row>'
      '</sheetData></worksheet>';
  final sst = StringBuffer(
    '$_xml<sst xmlns="$_ns" count="${strings.length}" '
    'uniqueCount="${strings.length}">',
  );
  for (final t in strings) {
    sst.write('<si><t>$t</t></si>');
  }
  sst.write('</sst>');

  return _zip({
    '[Content_Types].xml':
        '$_xml<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
        '</Types>',
    '_rels/.rels':
        '$_xml<Relationships xmlns="$_pr">'
        '<Relationship Id="rId1" Type="$_r/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
    'xl/workbook.xml':
        '$_xml<workbook xmlns="$_ns" xmlns:r="$_r">'
        '<workbookPr defaultThemeVersion="166925"/>'
        '<sheets><sheet name="Budget" sheetId="1" r:id="rId1"/>'
        '<sheet name="Rates" sheetId="2" r:id="rId2"/></sheets>'
        '<calcPr calcId="191029"/></workbook>',
    'xl/_rels/workbook.xml.rels':
        '$_xml<Relationships xmlns="$_pr">'
        '<Relationship Id="rId1" Type="$_r/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="$_r/worksheet" Target="worksheets/sheet2.xml"/>'
        '<Relationship Id="rId3" Type="$_r/styles" Target="styles.xml"/>'
        '<Relationship Id="rId4" Type="$_r/sharedStrings" Target="sharedStrings.xml"/>'
        '</Relationships>',
    'xl/styles.xml':
        '$_xml<styleSheet xmlns="$_ns">'
        '<fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="2"><fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="14" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs>'
        '</styleSheet>',
    'xl/sharedStrings.xml': sst.toString(),
    'xl/worksheets/sheet1.xml': budget,
    'xl/worksheets/sheet2.xml': rates,
  });
}

// ------------------------------------------------------------------- ODS

const _odsNs =
    'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
    'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
    'xmlns:calcext="urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0" '
    'xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" '
    'office:version="1.3"';

/// Grades as LibreOffice Calc saves them: `of:=` formulas with typed
/// results, a percentage, a boolean, an error and a date.
List<int> loGrades() {
  String s(String t) =>
      '<table:table-cell office:value-type="string" calcext:value-type="string">'
      '<text:p>$t</text:p></table:table-cell>';
  String n(num v) =>
      '<table:table-cell office:value-type="float" office:value="$v" '
      'calcext:value-type="float"><text:p>$v</text:p></table:table-cell>';
  String f(String formula, num v) =>
      '<table:table-cell table:formula="of:=$formula" office:value-type="float" '
      'office:value="$v" calcext:value-type="float"><text:p>$v</text:p>'
      '</table:table-cell>';
  String fs(String formula, String v) =>
      '<table:table-cell table:formula="of:=$formula" office:value-type="string" '
      'office:string-value="$v" calcext:value-type="string"><text:p>$v</text:p>'
      '</table:table-cell>';
  String row(List<String> cells) =>
      '<table:table-row>${cells.join()}</table:table-row>';

  const students = [('Ada', 91, 88), ('Ben', 72, 65), ('Cy', 55, 61)];
  final rows = <String>[
    row([s('Name'), s('Test 1'), s('Test 2'), s('Mean'), s('Grade')]),
  ];
  for (var i = 0; i < students.length; i++) {
    final r = i + 2;
    final (name, a, b) = students[i];
    final mean = (a + b) / 2;
    final grade = mean >= 85 ? 'A' : (mean >= 65 ? 'B' : 'C');
    rows.add(
      row([
        s(name),
        n(a),
        n(b),
        f('AVERAGE([.B$r:.C$r])', mean),
        fs(
          'IF([.D$r]&gt;=85;&quot;A&quot;;IF([.D$r]&gt;=65;&quot;B&quot;;&quot;C&quot;))',
          grade,
        ),
      ]),
    );
  }
  // Means 89.5, 68.5, 58 → max 89.5, average 72, 2 passed (≥ 60).
  rows.add(
    row([
      s('Stats'),
      f('MAX([.D2:.D4])', 89.5),
      f('AVERAGE([.D2:.D4])', 72),
      f('COUNTIF([.D2:.D4];&quot;&gt;=60&quot;)', 2),
      '<table:table-cell table:formula="of:=[.D2]&gt;[.D3]" '
          'office:value-type="boolean" office:boolean-value="true" '
          'calcext:value-type="boolean"><text:p>TRUE</text:p></table:table-cell>',
    ]),
  );
  rows.add(
    row([
      '<table:table-cell table:formula="of:=1/0" office:value-type="float" '
          'office:value="0" calcext:value-type="error"><text:p>#DIV/0!</text:p>'
          '</table:table-cell>',
      '<table:table-cell table:formula="of:=DATE(2024;2;29)" '
          'office:value-type="date" office:date-value="2024-02-29" '
          'calcext:value-type="date"><text:p>02/29/24</text:p></table:table-cell>',
      f('ROUND([.C5]/3;2)', 24),
      fs('UPPER([.A2])&amp;&quot;-&quot;&amp;[.E2]', 'ADA-A'),
      f('SUMPRODUCT([.B2:.B4];[.C2:.C4])', 91 * 88 + 72 * 65 + 55 * 61),
    ]),
  );

  final content =
      '$_xml<office:document-content $_odsNs><office:body><office:spreadsheet>'
      '<table:table table:name="Grades">'
      '<table:table-column table:number-columns-repeated="5"/>'
      '${rows.join()}</table:table></office:spreadsheet></office:body>'
      '</office:document-content>';
  return _zip({
    'mimetype': 'application/vnd.oasis.opendocument.spreadsheet',
    'META-INF/manifest.xml':
        '$_xml<manifest:manifest xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" manifest:version="1.3">'
        '<manifest:file-entry manifest:full-path="/" manifest:media-type="application/vnd.oasis.opendocument.spreadsheet"/>'
        '<manifest:file-entry manifest:full-path="content.xml" manifest:media-type="text/xml"/>'
        '</manifest:manifest>',
    'content.xml': content,
  }, storedFirst: 'mimetype');
}
