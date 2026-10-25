import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/src/addressing/grid_geometry.dart';

import '../support/ooxml_builder.dart';

WorkbookDocument _read(
  List<TestSheet> sheets, {
  String? styles,
  List<String> sharedStrings = const [],
  String workbookPr = '',
  String workbookExtra = '',
  Map<String, String> parts = const {},
  Map<String, List<int>> binaryParts = const {},
  XlsxImportOptions options = const XlsxImportOptions(),
}) => XlsxImporter.import(
  buildXlsx(
    sheets,
    styles: styles,
    sharedStrings: sharedStrings,
    workbookPr: workbookPr,
    workbookExtra: workbookExtra,
    parts: parts,
    binaryParts: binaryParts,
  ),
  options,
);

IrCell? _cell(WorkbookDocument d, String a1, {int sheet = 0}) {
  final p = IrRange.parseA1(a1)!.$2;
  return d.sheets[sheet].cells.get(p.r1!, p.c1!);
}

Map<String, Object?> _fmt(WorkbookDocument d, String a1) =>
    d.formatOf(_cell(d, a1)!).attrs.toMap();

void main() {
  group('Given cells of every value type', () {
    late WorkbookDocument doc;
    setUp(() {
      doc = _read(
        [
          const TestSheet(
            'Values',
            data:
                '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
                '<c r="C1" t="inlineStr"><is><t>inline</t></is></c></row>'
                '<row r="2"><c r="A2"><v>42.5</v></c><c r="B2" t="b"><v>1</v></c>'
                '<c r="C2" t="e"><v>#N/A</v></c><c r="D2" t="str"><f>"a"&amp;"b"</f><v>ab</v></c></row>',
          ),
        ],
        sharedStrings: [
          '<t>plain_x000D_</t>',
          '<r><rPr><b/></rPr><t>Bold</t></r><r><t xml:space="preserve"> rest</t></r>',
        ],
      );
    });

    test('when importing then shared strings decode escapes', () {
      expect(_cell(doc, 'A1')!.value, const IrText('plain\r'));
    });

    test('when importing then rich runs become rich text', () {
      final v = _cell(doc, 'B1')!.value! as IrRich;
      expect(v.rich.text, 'Bold rest');
      expect(v.rich.runs.single.format, {'bold': true});
    });

    test('when importing then inline strings, numbers, booleans and errors '
        'are read', () {
      expect(_cell(doc, 'C1')!.value, const IrText('inline'));
      expect(_cell(doc, 'A2')!.value, const IrNumber(42.5));
      expect(_cell(doc, 'B2')!.value, const IrBool(true));
      expect(_cell(doc, 'C2')!.value, const IrError(CellErrorKind.na));
    });

    test('when importing a formula then its cached value is kept', () {
      final c = _cell(doc, 'D2')!;
      expect(c.formulaA1, '"a"&"b"');
      expect(c.value, const IrText('ab'));
    });
  });

  group('Given formulas in Excel storage form', () {
    late WorkbookDocument doc;
    setUp(() {
      doc = _read(
        [
          const TestSheet(
            'F',
            data:
                '<row r="1"><c r="A1"><v>1</v></c><c r="B1"><f t="shared" ref="B1:B3" si="0">A1*2</f><v>2</v></c>'
                '<c r="C1"><f t="array" ref="C1:C3">A1:A3*10</f><v>10</v></c>'
                '<c r="D1" cm="1"><f t="array" ref="D1:D3">_xlfn.SEQUENCE(3)</f><v>1</v></c>'
                '<c r="E1" cm="1"><f t="array" ref="E1:E3">A1:A3+1</f><v>2</v></c></row>'
                '<row r="2"><c r="A2"><v>2</v></c><c r="B2"><f t="shared" si="0"/><v>4</v></c>'
                '<c r="C2"><v>20</v></c><c r="D2"><v>2</v></c><c r="E2"><v>3</v></c></row>'
                '<row r="3"><c r="A3"><v>3</v></c><c r="B3"><f t="shared" si="0"/><v>6</v></c>'
                '<c r="C3"><v>30</v></c><c r="D3"><v>3</v></c><c r="E3"><v>4</v></c></row>'
                '<row r="4"><c r="A4"><f>_xlfn.IFS(A1&gt;0,"p",TRUE(),"n")</f><v>p</v></c>'
                '<c r="B4"><f>SUM(@A1:A3)</f><v>6</v></c>'
                '<c r="C4"><f>CUBEVALUE("x")</f><v>7</v></c>'
                '<c r="D4"><f>[1]Other!A1</f><v>8</v></c></row>',
          ),
        ],
        options: const XlsxImportOptions(
          isSupportedFunction: ImportOptions.isWonkyFunction,
        ),
      );
    });

    test('when importing shared formulas then they are shifted per cell', () {
      expect(_cell(doc, 'B1')!.formulaA1, 'A1*2');
      expect(_cell(doc, 'B2')!.formulaA1, 'A2*2');
      expect(_cell(doc, 'B3')!.formulaA1, 'A3*2');
    });

    test(
      'when importing a legacy array formula then it is an ARRAYFORMULA',
      () {
        final c = _cell(doc, 'C1')!;
        expect(c.formulaA1, 'ARRAYFORMULA(A1:A3*10)');
        expect(c.formulaKind, IrFormulaKind.array);
        expect(c.arrayRef, const GridRect(0, 2, 2, 2));
        expect(_cell(doc, 'C2'), isNull, reason: 'cached elements are dropped');
      },
    );

    test('when importing a dynamic array of an array function then it is '
        'kept as is', () {
      final c = _cell(doc, 'D1')!;
      expect(c.formulaA1, 'SEQUENCE(3)');
      expect(c.formulaKind, IrFormulaKind.dynamicArray);
    });

    test(
      'when importing a dynamic array expression then it needs array mode',
      () {
        expect(_cell(doc, 'E1')!.formulaA1, 'ARRAYFORMULA(A1:A3+1)');
      },
    );

    test('when importing then prefixes and TRUE() are normalized', () {
      expect(_cell(doc, 'A4')!.formulaA1, 'IFS(A1>0,"p",TRUE,"n")');
    });

    test(
      'when importing then the implicit intersection operator is removed',
      () {
        expect(_cell(doc, 'B4')!.formulaA1, 'SUM(A1:A3)');
        expect(doc.warnings.withCode('implicitIntersection').single.count, 1);
      },
    );

    test(
      'when a function is unsupported then the value is kept with a note',
      () {
        final c = _cell(doc, 'C4')!;
        expect(c.formulaA1, isNull);
        expect(c.value, const IrNumber(7));
        expect(c.note, contains('CUBEVALUE'));
        expect(
          doc.warnings.withCode('unsupportedFunction').map((w) => w.message),
          contains('1 cells used unsupported function CUBEVALUE'),
        );
      },
    );

    test('when a reference is external then the cached value is kept', () {
      expect(_cell(doc, 'D4')!.formulaA1, isNull);
      expect(_cell(doc, 'D4')!.value, const IrNumber(8));
    });
  });

  group('Given unsupported formulas and the text option', () {
    test('when importing then the formula text is kept as text', () {
      final doc = _read(
        [
          const TestSheet(
            'F',
            data:
                '<row r="1"><c r="A1"><f>WEBSERVICE("u")</f><v>1</v></c></row>',
          ),
        ],
        options: const XlsxImportOptions(
          unsupportedFormulas: UnsupportedFormulaMode.text,
        ),
      );
      expect(_cell(doc, 'A1')!.value, const IrText('=WEBSERVICE("u")'));
    });

    test('when an array formula is unsupported then its cached cells stay', () {
      final doc = _read([
        const TestSheet(
          'F',
          data:
              '<row r="1"><c r="A1"><f t="array" ref="A1:A2">CUBESET("x")</f><v>1</v></c></row>'
              '<row r="2"><c r="A2"><v>2</v></c></row>',
        ),
      ]);
      expect(_cell(doc, 'A1')!.value, const IrNumber(1));
      expect(_cell(doc, 'A2')!.value, const IrNumber(2));
    });
  });

  group('Given dates', () {
    const sheet = TestSheet(
      'D',
      data:
          '<row r="1"><c r="A1" s="3"><v>46115</v></c><c r="B1" s="3"><v>30</v></c>'
          '<c r="C1" s="3"><v>60</v></c><c r="D1"><v>30</v></c></row>',
    );

    test('when importing date cells then serials follow the Wonky epoch', () {
      final doc = _read([sheet], styles: kTestStyles);
      expect(_cell(doc, 'A1')!.value, const IrNumber(46115));
      expect(_cell(doc, 'B1')!.value, const IrNumber(31));
      expect(_cell(doc, 'D1')!.value, const IrNumber(30));
      expect(_fmt(doc, 'A1'), {'numberFormat': 'yyyy-mm-dd'});
    });

    test('when a date is the fictitious 1900-02-29 then it is #VALUE!', () {
      final doc = _read([sheet], styles: kTestStyles);
      expect(_cell(doc, 'C1')!.value, const IrError(CellErrorKind.value));
      expect(doc.warnings.withCode('fictitiousDate'), hasLength(1));
    });

    test('when the workbook uses the 1904 system then dates are shifted', () {
      final doc = _read(
        [sheet],
        styles: kTestStyles,
        workbookPr: '<workbookPr date1904="1"/>',
      );
      expect(doc.date1904, isTrue);
      expect(_cell(doc, 'B1')!.value, const IrNumber(30 + 1462));
      expect(_cell(doc, 'D1')!.value, const IrNumber(30));
    });
  });

  group('Given column and row styles', () {
    late WorkbookDocument doc;
    setUp(() {
      doc = _read([
        const TestSheet(
          'S',
          before:
              '<cols><col min="2" max="2" width="20" customWidth="1" style="4"/>'
              '<col min="3" max="16384" width="9.140625" style="2"/></cols>',
          data:
              '<row r="1"><c r="A1"><v>1</v></c><c r="B1" s="4"><v>2</v></c>'
              '<c r="C1" s="2"><v>3</v></c></row>'
              '<row r="2"><c r="B2"><v>4</v></c><c r="C2" s="1"><v>5</v></c></row>'
              '<row r="3" ht="30" customHeight="1" hidden="1" s="1" customFormat="1"><c r="A3" s="1"><v>6</v></c></row>',
        ),
      ], styles: kTestStyles);
    });

    IrSheet s() => doc.sheets.single;

    test('when a styled column run reaches the last column then it is the '
        'sheet default', () {
      expect(doc.formats[s().defaultFormat].attrs.toMap(), {'italic': true});
    });

    test('when a column has a style then it is relative to the default', () {
      expect(doc.formats[s().columns[1]!.format].attrs.toMap(), {
        'numberFormat': '0.00',
        'bold': true,
        'italic': false,
      });
      expect(s().columns[1]!.size, 140);
    });

    test('when a cell repeats its column style then it has no own format', () {
      expect(_cell(doc, 'B1')!.format, 0);
    });

    test('when a cell lacks inherited attributes then they are reset', () {
      expect(_fmt(doc, 'B2'), {
        'numberFormat': 'preset:automatic',
        'bold': false,
      });
      expect(_fmt(doc, 'C2'), {'bold': true, 'italic': false});
    });

    test(
      'when a row has a style, height and hidden flag then they are read',
      () {
        final r = s().rows[2]!;
        expect(r.size, 40);
        expect(r.hidden, isTrue);
        expect(doc.formats[r.format].attrs.toMap(), {
          'bold': true,
          'italic': false,
        });
        expect(_cell(doc, 'A3')!.format, 0);
      },
    );

    test('when converting back to effective formats then they match Excel', () {
      expect(IrFormats.effective(doc, s(), 1, 1).toMap(), {
        'numberFormat': 'preset:automatic',
        'bold': false,
        'italic': false,
      });
    });
  });

  group('Given workbook structure', () {
    late WorkbookDocument doc;
    setUp(() {
      doc = _read(
        [
          const TestSheet(
            'Main',
            before:
                '<sheetPr><tabColor rgb="FFFF0000"/></sheetPr>'
                '<sheetViews><sheetView showGridLines="0" workbookViewId="0">'
                '<pane xSplit="1" ySplit="2" topLeftCell="B3" state="frozen"/></sheetView></sheetViews>'
                '<sheetFormatPr defaultRowHeight="15"/>',
            data:
                '<row r="1"><c r="A1"><v>1</v></c></row>'
                '<row r="2"><c r="A2" t="inlineStr"><is><t>link</t></is></c>'
                '<c r="B2" t="inlineStr"><is><t>web</t></is></c></row>',
            after:
                '<mergeCells count="1"><mergeCell ref="C1:D2"/></mergeCells>'
                '<hyperlinks><hyperlink ref="A2" location="\'Second\'!B5"/>'
                '<hyperlink ref="B2" r:id="rId1"/></hyperlinks>',
            rels: {'rId1': ('hyperlink', 'https://example.com/', true)},
          ),
          const TestSheet('Second', state: 'hidden'),
          const TestSheet('Secret', state: 'veryHidden'),
        ],
        workbookExtra:
            '<definedNames><definedName name="Total">Main!\$A\$1:\$A\$5</definedName>'
            '<definedName name="Local" localSheetId="0">Main!\$B\$1</definedName>'
            '<definedName name="_xlnm.Print_Area" localSheetId="0">Main!\$A\$1:\$D\$9</definedName>'
            '<definedName name="_xlnm.Print_Titles" localSheetId="0">Main!\$1:\$1</definedName>'
            '<definedName name="Rate">0.19</definedName></definedNames>',
      );
    });

    test('when importing then sheet view settings are read', () {
      final s = doc.sheets.first;
      expect(s.tabColor, '#FF0000');
      expect(s.showGridlines, isFalse);
      expect((s.frozenRows, s.frozenColumns), (2, 1));
      expect(s.defaultRowHeight, 20);
      expect(s.merges, [const GridRect(0, 2, 1, 3)]);
    });

    test('when importing then hidden sheets stay hidden', () {
      expect([for (final s in doc.sheets) s.hidden], [false, true, true]);
      expect(doc.warnings.withCode('veryHidden'), hasLength(1));
    });

    test('when importing then hyperlinks are external URLs or internal A1', () {
      expect(_cell(doc, 'A2')!.link, '#Second!B5');
      expect(_cell(doc, 'B2')!.link, 'https://example.com/');
    });

    test('when importing then defined names become named ranges', () {
      final names = {for (final n in doc.namedRanges) n.name: n};
      expect(names['Total']!.sheet, 'Main');
      expect(names['Total']!.range, IrRange(0, 0, 4, 0));
      expect(names['Main_Local']!.range, IrRange.cell(0, 1));
      expect(names['Rate']!.formulaA1, '0.19');
      expect(doc.warnings.withCode('sheetScopedName'), hasLength(1));
    });

    test(
      'when importing then print areas and titles become print settings',
      () {
        expect(doc.sheets.first.print, {
          'printArea': 'A1:D9',
          'repeatRows': {'start': 0, 'end': 0},
        });
      },
    );

    test('when listing sheets then names and visibility are reported', () {
      final infos = XlsxImporter.listSheets(
        buildXlsx([
          const TestSheet(
            'A',
            before: '<dimension ref="A1:C10"/>',
            data: '<row r="1"><c r="A1"><v>1</v></c></row>',
          ),
          const TestSheet('B', state: 'hidden'),
        ]),
      );
      expect(
        [for (final i in infos) (i.name, i.hidden)],
        [('A', false), ('B', true)],
      );
      expect(infos.first.estimatedCells, 30);
    });
  });

  group('Given notes', () {
    test('when importing legacy comments then the author prefix is removed', () {
      final doc = _read(
        [
          const TestSheet(
            'N',
            data: '<row r="1"><c r="A1"><v>1</v></c></row>',
            rels: {'rId1': ('comments', '../comments1.xml', false)},
          ),
        ],
        parts: {
          'xl/comments1.xml':
              '<comments xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
              '<authors><author>Anna</author></authors><commentList>'
              '<comment ref="A1" authorId="0"><text><r><t>Anna:</t></r>'
              '<r><t xml:space="preserve">\nCheck this</t></r></text></comment>'
              '</commentList></comments>',
        },
      );
      expect(_cell(doc, 'A1')!.note, 'Check this');
    });
  });

  group('Given a picture in BMP format', () {
    const rel =
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
    const pkgRel =
        'http://schemas.openxmlformats.org/package/2006/relationships';
    WorkbookDocument withMedia(List<int> bmp) => _read(
      [
        const TestSheet(
          'S',
          data: '<row r="1"><c r="A1"><v>1</v></c></row>',
          after: '<drawing r:id="rId1"/>',
          rels: {'rId1': ('drawing', '../drawings/drawing1.xml', false)},
        ),
      ],
      parts: {
        'xl/drawings/drawing1.xml':
            '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" '
            'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="$rel">'
            '<xdr:oneCellAnchor><xdr:from><xdr:col>1</xdr:col><xdr:colOff>0</xdr:colOff>'
            '<xdr:row>1</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from>'
            '<xdr:ext cx="95250" cy="95250"/><xdr:pic><xdr:nvPicPr>'
            '<xdr:cNvPr id="1" name="Picture 1"/><xdr:cNvPicPr/></xdr:nvPicPr>'
            '<xdr:blipFill><a:blip r:embed="rId1"/></xdr:blipFill><xdr:spPr/></xdr:pic>'
            '<xdr:clientData/></xdr:oneCellAnchor></xdr:wsDr>',
        'xl/drawings/_rels/drawing1.xml.rels':
            '<Relationships xmlns="$pkgRel">'
            '<Relationship Id="rId1" Type="$rel/image" Target="../media/image1.bmp"/>'
            '</Relationships>',
      },
      binaryParts: {'xl/media/image1.bmp': bmp},
    );

    test('when importing then it becomes a PNG', () {
      final bmp = img.encodeBmp(img.Image(width: 3, height: 2));

      final image = withMedia(bmp).sheets.single.images.single;

      expect(image.mimeType, 'image/png');
      expect(image.name, 'image1.png');
      final png = img.decodePng(image.bytes!)!;
      expect((png.width, png.height), (3, 2));
    });

    test('when the BMP is unreadable then it is skipped with a warning', () {
      final doc = withMedia(ascii.encode('BM not really a bitmap'));

      expect(doc.sheets.single.images, isEmpty);
      expect(doc.warnings.withCode('imageFormat'), isNotEmpty);
    });
  });

  group('Given charts written by another application', () {
    const c = 'http://schemas.openxmlformats.org/drawingml/2006/chart';
    const pkgRel =
        'http://schemas.openxmlformats.org/package/2006/relationships';
    const rel =
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
    String drawing(int n) =>
        '<xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing" '
        'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="$rel">'
        '${[for (var i = 1; i <= n; i++) '<xdr:twoCellAnchor><xdr:from><xdr:col>3</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>1</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:from>'
              '<xdr:to><xdr:col>5</xdr:col><xdr:colOff>0</xdr:colOff><xdr:row>4</xdr:row><xdr:rowOff>0</xdr:rowOff></xdr:to>'
              '<xdr:graphicFrame><xdr:nvGraphicFramePr><xdr:cNvPr id="$i" name="Chart $i"/><xdr:cNvGraphicFramePr/></xdr:nvGraphicFramePr>'
              '<a:graphic><a:graphicData uri="$c"><c:chart xmlns:c="$c" r:id="rId$i"/></a:graphicData></a:graphic>'
              '</xdr:graphicFrame><xdr:clientData/></xdr:twoCellAnchor>'].join()}</xdr:wsDr>';
    late WorkbookDocument doc;
    setUp(() {
      doc = _read(
        [
          const TestSheet(
            'S',
            data:
                '<row r="1"><c r="A1"><v>1</v></c><c r="B1"><v>5</v></c></row>'
                '<row r="2"><c r="A2"><v>2</v></c><c r="B2"><v>6</v></c></row>',
            after: '<drawing r:id="rId1"/>',
            rels: {'rId1': ('drawing', '../drawings/drawing1.xml', false)},
          ),
        ],
        parts: {
          'xl/drawings/drawing1.xml': drawing(2),
          'xl/drawings/_rels/drawing1.xml.rels':
              '<Relationships xmlns="$pkgRel">'
              '<Relationship Id="rId1" Type="$rel/chart" Target="../charts/chart1.xml"/>'
              '<Relationship Id="rId2" Type="$rel/chart" Target="../charts/chart2.xml"/>'
              '</Relationships>',
          'xl/charts/chart1.xml':
              '<c:chartSpace xmlns:c="$c" xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
              '<c:chart><c:plotArea><c:barChart><c:barDir val="bar"/><c:grouping val="clustered"/>'
              '<c:ser><c:idx val="0"/><c:order val="0"/><c:tx><c:v>Totals</c:v></c:tx>'
              '<c:cat><c:numRef><c:f>S!\$A\$1:\$A\$2</c:f></c:numRef></c:cat>'
              '<c:val><c:numRef><c:f>S!\$B\$1:\$B\$2</c:f></c:numRef></c:val></c:ser>'
              '<c:axId val="1"/><c:axId val="2"/></c:barChart>'
              '<c:catAx><c:axId val="1"/></c:catAx><c:valAx><c:axId val="2"/></c:valAx>'
              '</c:plotArea></c:chart></c:chartSpace>',
          'xl/charts/chart2.xml':
              '<c:chartSpace xmlns:c="$c"><c:chart><c:plotArea><c:bubbleChart/>'
              '</c:plotArea></c:chart></c:chartSpace>',
        },
      );
    });

    test('when importing a bar chart then its data ranges are A1', () {
      final chart = doc.sheets.single.charts.single;
      expect(chart.spec['type'], 'bar');
      expect(chart.spec['data'], {
        'ranges': [r'S!$A$1:$A$2', r'S!$B$1:$B$2'],
        'headerCount': 0,
        'domain': {
          'ref': {'range': 0, 'offset': 0},
        },
        'seriesRefs': [
          {
            'key': '#1:0',
            'ref': {'range': 1, 'offset': 0},
          },
        ],
      });
      expect(chart.spec['series'], {
        '#1:0': {'labelOverride': 'Totals'},
      });
      expect((chart.anchor.row, chart.anchor.col), (1, 3));
      expect((chart.anchor.width, chart.anchor.height), (128, 60));
    });

    test('when a chart type is not supported then it is reported', () {
      expect(
        doc.warnings.withCode('chartSkipped').single.message,
        'Charts of type bubble were not imported',
      );
    });
  });

  group('Given broken files', () {
    test('when the bytes are not a zip then a format error is thrown', () {
      expect(
        () => XlsxImporter.import(Uint8List.fromList(utf8.encode('a,b\n1,2'))),
        throwsA(isA<XlsxFormatException>()),
      );
    });

    test('when the zip has no workbook then a format error is thrown', () {
      final a = Archive()
        ..add(ArchiveFile.bytes('hello.txt', utf8.encode('x')));
      expect(
        () => XlsxImporter.import(
          Uint8List.fromList(ZipEncoder().encodeBytes(a)),
        ),
        throwsA(
          isA<XlsxFormatException>().having(
            (e) => e.message,
            'message',
            contains('not an XLSX file'),
          ),
        ),
      );
    });

    test('when the file is an ODS package then the message says so', () {
      final a = Archive()
        ..add(ArchiveFile.bytes('content.xml', utf8.encode('<x/>')));
      expect(
        () => XlsxImporter.import(
          Uint8List.fromList(ZipEncoder().encodeBytes(a)),
        ),
        throwsA(
          isA<XlsxFormatException>().having(
            (e) => e.message,
            'message',
            contains('OpenDocument'),
          ),
        ),
      );
    });

    test(
      'when a sheet is not well-formed XML then a format error is thrown',
      () {
        expect(
          () => _read([const TestSheet('Bad', data: '<row r="1"><c r="A1">')]),
          throwsA(isA<XlsxFormatException>()),
        );
      },
    );
  });
}
