import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import '../../addressing/a1.dart';
import '../../addressing/grid_geometry.dart';
import '../../content/cell_content.dart';
import '../../content/rich_text.dart';
import '../../format/attributes.dart';
import '../../formula/values/dates.dart';
import '../color/excel_colors.dart';
import '../formula/excel_formula_translator.dart';
import '../formula/formula_tokens.dart';
import '../formula/function_map.dart';
import '../ir/import_warning.dart';
import '../ir/ir_formats.dart';
import '../ir/ir_range.dart';
import '../ir/workbook_document.dart';
import 'ooxml.dart';
import 'xlsx_charts.dart';
import 'xlsx_print.dart';
import 'xlsx_rules.dart';
import 'xlsx_styles.dart';

/// What to do with formulas using functions Wonky lacks (11 §2.2).
enum UnsupportedFormulaMode {
  /// Keep the last calculated value (plus a note).
  value,

  /// Keep the formula as text (plus a note).
  text,
}

/// Options of an XLSX import.
final class XlsxImportOptions {
  /// Creates options.
  const XlsxImportOptions({
    this.sheets,
    this.unsupportedFormulas = UnsupportedFormulaMode.value,
    this.themeColorReferences = true,
    this.isSupportedFunction,
    this.includeImages = true,
  });

  /// Names of the sheets to import (null = all).
  final Set<String>? sheets;
  final UnsupportedFormulaMode unsupportedFormulas;

  /// Whether untinted theme colors become `theme:<key>` references (the
  /// file's theme is imported as the spreadsheet theme).
  final bool themeColorReferences;

  /// Whether Wonky implements a function (upper case); defaults to the
  /// Wonky function catalog ([FunctionMap.isWonkyFunction]).
  final bool Function(String upperName)? isSupportedFunction;
  final bool includeImages;
}

/// A sheet listed by [XlsxImporter.listSheets].
final class XlsxSheetInfo {
  /// Creates info.
  const XlsxSheetInfo(
    this.name, {
    this.hidden = false,
    this.estimatedCells = 0,
    this.isChart = false,
  });

  final String name;
  final bool hidden;

  /// From `<dimension ref>` (or part size ÷ 40 bytes when missing).
  final int estimatedCells;
  final bool isChart;
}

/// XLSX → IR (11 §5.2), own OOXML reader over `archive` + `xml`.
abstract final class XlsxImporter {
  /// Imports [bytes]. Broken files throw [XlsxFormatException].
  static WorkbookDocument import(
    Uint8List bytes, [
    XlsxImportOptions options = const XlsxImportOptions(),
  ]) {
    try {
      return _Reader(ZipPackage.open(bytes), options).read();
    } on XlsxFormatException {
      rethrow;
    } on Object catch (e) {
      throw XlsxFormatException('The workbook could not be read ($e)');
    }
  }

  /// Lists the sheets of [bytes] (import dialog) without reading cells.
  static List<XlsxSheetInfo> listSheets(Uint8List bytes) {
    try {
      final pkg = ZipPackage.open(bytes);
      final r = _Reader(pkg, const XlsxImportOptions());
      final wbPath = r._workbookPath();
      final wb = pkg.xml(wbPath)?.rootElement;
      if (wb == null) {
        throw const XlsxFormatException('The file has no workbook part');
      }
      final rels = pkg.rels(wbPath);
      return [
        for (final s
            in wb.child('sheets')?.elems('sheet') ?? const <XmlElement>[])
          () {
            final rel = rels[s.attr('id')];
            final path = rel?.target;
            var est = 0;
            final isChart = rel?.type.endsWith('/chartsheet') ?? false;
            if (path != null && !isChart) {
              final head = pkg.text(path);
              final m = head == null
                  ? null
                  : RegExp(
                      r'<(?:\w+:)?dimension\s+ref="([^"]+)"',
                    ).firstMatch(head);
              final dim = m == null ? null : IrRange.parseA1(m.group(1)!)?.$2;
              if (dim != null && dim.isBounded) {
                est = (dim.r2! - dim.r1! + 1) * (dim.c2! - dim.c1! + 1);
              } else {
                est = (pkg.bytes(path)?.length ?? 0) ~/ 40;
              }
            }
            return XlsxSheetInfo(
              s.attr('name') ?? 'Sheet',
              hidden: (s.attr('state') ?? 'visible') != 'visible',
              estimatedCells: est,
              isChart: isChart,
            );
          }(),
      ];
    } on XlsxFormatException {
      rethrow;
    } on Object catch (e) {
      throw XlsxFormatException('The workbook could not be read ($e)');
    }
  }
}

String _local(String name) {
  final i = name.indexOf(':');
  return i < 0 ? name : name.substring(i + 1);
}

String? _evAttr(XmlStartElementEvent e, String local) {
  for (final a in e.attributes) {
    if (_local(a.name) == local) return a.value;
  }
  return null;
}

/// Builds plain or rich text from `<si>`/`<is>` events.
final class _RichBuilder {
  _RichBuilder(this.colors, this.cellDefaults);

  final ColorResolver colors;
  final Map<String, Object?> cellDefaults;
  final StringBuffer text = StringBuffer();
  final List<RichRun> runs = [];
  Map<String, Object?>? _runFormat;
  int _runStart = 0;
  bool inRun = false;
  bool inRPh = false;

  void startRun() {
    inRun = true;
    _runStart = text.length;
    _runFormat = {};
  }

  void prop(XmlStartElementEvent e) {
    final f = _runFormat;
    if (f == null) return;
    final val = _evAttr(e, 'val');
    switch (_local(e.name)) {
      case 'b':
        f[RichRunKeys.bold] = val == null || val == '1' || val == 'true';
      case 'i':
        f[RichRunKeys.italic] = val == null || val == '1' || val == 'true';
      case 'strike':
        f[RichRunKeys.strikethrough] =
            val == null || val == '1' || val == 'true';
      case 'u':
        f[RichRunKeys.underline] = val != 'none';
      case 'sz':
        final d = double.tryParse(val ?? '');
        if (d != null) f[RichRunKeys.fontSize] = d;
      case 'rFont':
        if (val != null) f[RichRunKeys.fontFamily] = val;
      case 'color':
        final c = colors.resolve(
          rgb: _evAttr(e, 'rgb'),
          theme: _evAttr(e, 'theme'),
          indexed: _evAttr(e, 'indexed'),
          auto: _evAttr(e, 'auto'),
          tint: _evAttr(e, 'tint'),
        );
        if (c != null) f[RichRunKeys.textColor] = c;
    }
  }

  void addText(String t) {
    if (!inRPh) text.write(Ooxml.decodeEscapes(t));
  }

  void endRun() {
    if (_runFormat != null &&
        text.length > _runStart &&
        _runFormat!.isNotEmpty) {
      runs.add(RichRun(_runStart, text.length, _runFormat!));
    }
    _runFormat = null;
    inRun = false;
  }

  IrValue build() {
    final s = text.toString();
    if (runs.isEmpty) return IrText(s);
    final n = RichText(s, runs).normalize(cellFormat: cellDefaults);
    return n.rich == null ? IrText(s) : IrRich(n.rich!);
  }
}

final class _Shared {
  _Shared(this.formula, this.translation);
  final SharedFormula formula;
  final FormulaTranslation translation;
}

final class _Reader {
  _Reader(this.pkg, this.options);

  final ZipPackage pkg;
  final XlsxImportOptions options;

  bool Function(String) get _supported =>
      options.isSupportedFunction ?? FunctionMap.isWonkyFunction;
  final WorkbookDocument doc = WorkbookDocument();
  late ColorResolver colors;
  late XlsxStylesReader styles;
  List<IrValue> sst = const [];
  final Map<int, int> _xfIndex = {};
  late Map<String, Object?> _richDefaults;
  Map<String, String> themeSlots = Map.of(ExcelColors.officeTheme);

  String _workbookPath() {
    final rels = pkg.rels('');
    for (final r in rels.values) {
      if (r.type.endsWith('/officeDocument')) return r.target;
    }
    if (pkg.has('xl/workbook.xml')) return 'xl/workbook.xml';
    if (pkg.has('content.xml')) {
      throw const XlsxFormatException(
        'This is an OpenDocument spreadsheet (.ods), not an XLSX file',
      );
    }
    throw const XlsxFormatException(
      'The file has no workbook part (not an XLSX file)',
    );
  }

  WorkbookDocument read() {
    final wbPath = _workbookPath();
    final wb = pkg.xml(wbPath)?.rootElement;
    if (wb == null || wb.localName != 'workbook') {
      throw const XlsxFormatException(
        'The workbook part is missing or invalid',
      );
    }
    final rels = pkg.rels(wbPath);
    OoxmlRel? relOf(String suffix) {
      for (final r in rels.values) {
        if (r.type.endsWith(suffix)) return r;
      }
      return null;
    }

    _readTheme(relOf('/theme')?.target);
    final stylesDoc = pkg.xml(relOf('/styles')?.target ?? 'xl/styles.xml');
    List<String>? palette;
    final idx = stylesDoc?.rootElement.child('colors')?.child('indexedColors');
    if (idx != null) {
      palette = [
        for (final c in idx.elems('rgbColor'))
          ExcelColors.parseRgb(c.attr('rgb')) ?? '#000000',
      ];
    }
    colors = ColorResolver(
      theme: themeSlots,
      palette: palette,
      themeReferences: options.themeColorReferences,
    );
    styles = XlsxStylesReader(stylesDoc, colors);
    for (final w in styles.numberFormatWarnings.toSet()) {
      doc.warnings.add('numberFormat', w);
    }
    doc.defaultFontFamily = styles.defaultFont?.name;
    doc.defaultFontSize = styles.defaultFont?.size;
    _richDefaults = {
      RichRunKeys.fontFamily: ?doc.defaultFontFamily,
      RichRunKeys.fontSize: ?doc.defaultFontSize,
      RichRunKeys.textColor: 'theme:text',
      if (styles.defaultFont?.color != null)
        RichRunKeys.textColor: styles.defaultFont!.color,
    };
    final ssPath = relOf('/sharedStrings')?.target;
    if (ssPath != null) sst = _readSharedStrings(ssPath);

    final pr = wb.child('workbookPr');
    doc.date1904 = pr?.boolAttr('date1904') ?? false;
    final core = pkg.xml('docProps/core.xml')?.rootElement;
    final title = core?.child('title')?.innerText.trim();
    if (title != null && title.isNotEmpty) doc.title = title;

    final sheetEls =
        wb.child('sheets')?.elems('sheet').toList() ?? const <XmlElement>[];
    if (sheetEls.isEmpty) {
      throw const XlsxFormatException('The workbook has no sheets');
    }
    final sheetNames = [for (final s in sheetEls) s.attr('name') ?? 'Sheet'];

    // Defined names first: sheet-scoped renames are needed by formulas.
    final names =
        wb.child('definedNames')?.elems('definedName').toList() ??
        const <XmlElement>[];
    final workbookNames = <String>{
      for (final n in names)
        if (n.attr('localSheetId') == null)
          (n.attr('name') ?? '').toLowerCase(),
    };
    final knownNames = <String>{for (final n in names) n.attr('name') ?? ''};
    final renames = <int, Map<String, String>>{};
    for (final n in names) {
      final local = n.intAttr('localSheetId');
      final name = n.attr('name') ?? '';
      if (local == null ||
          name.startsWith('_xlnm.') ||
          local >= sheetNames.length) {
        continue;
      }
      var nn = '${_identifier(sheetNames[local])}_$name';
      var k = 2;
      while (workbookNames.contains(nn.toLowerCase())) {
        nn = '${_identifier(sheetNames[local])}_${name}_${k++}';
      }
      workbookNames.add(nn.toLowerCase());
      knownNames.add(nn);
      (renames[local] ??= {})[name] = nn;
      doc.warnings.add(
        'sheetScopedName',
        'Sheet-scoped name "$name" was renamed to "$nn"',
        sheet: sheetNames[local],
      );
    }

    final printAreas = <int, String>{};
    final printTitles = <int, String>{};
    for (var i = 0; i < sheetEls.length; i++) {
      final s = sheetEls[i];
      final name = sheetNames[i];
      if (options.sheets != null && !options.sheets!.contains(name)) continue;
      final rel = rels[s.attr('id')];
      if (rel == null || !pkg.has(rel.target)) {
        doc.warnings.add(
          'missingSheet',
          'Sheet "$name" could not be found in the file',
          sheet: name,
        );
        continue;
      }
      if (!rel.type.endsWith('/worksheet')) {
        doc.warnings.add(
          'sheetSkipped',
          'Chart and dialog sheets were not imported',
          sheet: name,
        );
        continue;
      }
      final translator = ExcelFormulaTranslator(
        isSupportedFunction: _supported,
        knownNames: knownNames,
        nameRenames: renames[i] ?? const {},
      );
      final sheet = IrSheet(name);
      final state = s.attr('state') ?? 'visible';
      if (state != 'visible') sheet.hidden = true;
      if (state == 'veryHidden') {
        doc.warnings.add(
          'veryHidden',
          'Very hidden sheet imported as hidden',
          sheet: name,
        );
      }
      _readSheet(rel.target, sheet, translator);
      doc.sheets.add(sheet);
    }
    if (doc.sheets.isEmpty && options.sheets == null) {
      throw const XlsxFormatException(
        'The workbook has no readable worksheets',
      );
    }

    // Names.
    for (final n in names) {
      final name = n.attr('name') ?? '';
      final local = n.intAttr('localSheetId');
      final value = n.innerText.trim();
      final text = value.startsWith('=') ? value.substring(1) : value;
      if (name.startsWith('_xlnm.')) {
        if (local == null) continue;
        if (name == '_xlnm.Print_Area') printAreas[local] = text;
        if (name == '_xlnm.Print_Titles') printTitles[local] = text;
        continue;
      }
      final tr = ExcelFormulaTranslator(
        isSupportedFunction: _supported,
        knownNames: knownNames,
        nameRenames: local == null ? const {} : renames[local] ?? const {},
      );
      final t = tr.importFormula(text);
      final finalName = local == null ? name : renames[local]?[name] ?? name;
      final parsed = IrRange.parseA1(t.formula);
      if (parsed != null && parsed.$1 != null) {
        doc.namedRanges.add(
          IrNamedRange(
            name: finalName,
            sheet: parsed.$1,
            range: parsed.$2.openAt(
              maxRows: Ooxml.maxRows,
              maxCols: Ooxml.maxCols,
            ),
            comment: n.attr('comment'),
            hidden: n.boolAttr('hidden') ?? false,
          ),
        );
      } else {
        if (!t.isSupported) {
          doc.warnings.add(
            'unsupportedName',
            'Name "$finalName" uses unsupported ${t.unsupported.join(', ')}',
          );
        }
        doc.namedRanges.add(
          IrNamedRange(
            name: finalName,
            formulaA1: t.formula,
            comment: n.attr('comment'),
            hidden: n.boolAttr('hidden') ?? false,
          ),
        );
      }
    }
    for (var i = 0; i < sheetEls.length; i++) {
      final sheet = doc.sheetByName(sheetNames[i]);
      if (sheet == null) continue;
      final area = printAreas[i];
      if (area != null) {
        final r = IrRange.parseA1(area.split(',').first);
        if (r != null) (sheet.print ??= {})['printArea'] = r.$2.toA1();
      }
      final titles = printTitles[i];
      if (titles != null) {
        for (final part in titles.split(',')) {
          final r = IrRange.parseA1(part)?.$2;
          if (r == null) continue;
          if (r.wholeRows) {
            (sheet.print ??= {})['repeatRows'] = {'start': r.r1, 'end': r.r2};
          }
          if (r.wholeColumns) {
            (sheet.print ??= {})['repeatCols'] = {'start': r.c1, 'end': r.c2};
          }
        }
      }
    }
    _packageWarnings();
    return doc;
  }

  static String _identifier(String s) {
    final t = s.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return RegExp(r'^[A-Za-z_]').hasMatch(t) ? t : '_$t';
  }

  /// Makes the complete XLSX styles of columns, rows and cells relative to
  /// what they inherit in Wonky (sheet default ▸ column ▸ row ▸ cell).
  void _relativeFormats(IrSheet sheet) {
    final d = doc.formats[sheet.defaultFormat].attrs;
    final hasDims =
        sheet.columns.entries.any((e) => e.value.format != 0) ||
        sheet.rows.entries.any((e) => e.value.format != 0);
    if (d.isEmpty && !hasDims) return;
    final dimCache = <int, int>{};
    int rel(int index, CellFormat inherited, Map<int, int> cache) {
      if (index == 0 && inherited.isEmpty) return 0;
      return cache[index] ??= () {
        final f = doc.formats[index];
        final r = IrFormats.relative(f.attrs, inherited, doc);
        return doc.formats.intern(IrFormat(r, f.extras));
      }();
    }

    for (final e in sheet.columns.entries.toList()) {
      if (e.value.format == 0) continue;
      sheet.columns[e.key] = e.value.copyWith(
        format: rel(e.value.format, d, dimCache),
      );
    }
    for (final e in sheet.rows.entries.toList()) {
      if (e.value.format == 0) continue;
      sheet.rows[e.key] = e.value.copyWith(
        format: rel(e.value.format, d, dimCache),
      );
    }
    final cache = <(int, int, int), int>{};
    for (final (r, c, cell) in sheet.cells.entries.toList()) {
      final cf = sheet.columns[c]?.format ?? 0;
      final rf = sheet.rows[r]?.format ?? 0;
      final key = (cell.format, cf, rf);
      final idx = cache[key] ??= () {
        final inherited = IrFormats.inherited(doc, sheet, r, c);
        if (inherited.isEmpty) return cell.format;
        final f = doc.formats[cell.format];
        final x = IrFormats.relative(f.attrs, inherited, doc);
        return doc.formats.intern(IrFormat(x, f.extras));
      }();
      if (idx != cell.format) {
        final next = cell.copyWith(format: idx);
        sheet.cells.set(r, c, next.isEmpty ? null : next);
      }
    }
  }

  void _packageWarnings() {
    final names = pkg.names.map((n) => n.toLowerCase()).toList();
    bool any(String p) => names.any((n) => n.contains(p));
    if (any('vbaproject.bin')) {
      doc.warnings.add(
        'vba',
        'VBA macros were not imported',
        severity: ImportSeverity.info,
      );
    }
    if (any('externallinks/')) {
      doc.warnings.add(
        'externalLinks',
        'External links were not imported; their cached values were kept',
      );
    }
    if (any('pivottables/')) {
      doc.warnings.add(
        'pivotTable',
        'Pivot tables were imported as values',
        severity: ImportSeverity.info,
      );
    }
    if (any('slicers/') || any('slicercaches/')) {
      doc.warnings.add('slicers', 'Slicers were not imported');
    }
    if (any('connections.xml')) {
      doc.warnings.add('connections', 'Data connections were not imported');
    }
    if (any('activex/') || any('ctrlprops/')) {
      doc.warnings.add('controls', 'Form controls were not imported');
    }
  }

  void _readTheme(String? path) {
    final root = path == null ? null : pkg.xml(path)?.rootElement;
    if (root == null) return;
    final te = root.child('themeElements');
    final scheme = te?.child('clrScheme');
    if (scheme != null) {
      for (final slot in ExcelColors.schemeOrder) {
        final e = scheme.child(slot);
        final c = e?.childElements.firstOrNull;
        if (c == null) continue;
        final v = c.localName == 'sysClr' ? c.attr('lastClr') : c.attr('val');
        final hex = ExcelColors.parseRgb(v);
        if (hex != null) themeSlots[slot] = hex;
      }
    }
    final fonts = te?.child('fontScheme');
    final minor = fonts?.child('minorFont')?.child('latin')?.attr('typeface');
    final major = fonts?.child('majorFont')?.child('latin')?.attr('typeface');
    doc.theme = IrTheme(
      name: root.attr('name'),
      textFont: minor,
      headingFont: major,
      colors: {
        for (final e in themeSlots.entries)
          if (ExcelColors.wonkyKeyOf(e.key) case final String k) k: e.value,
      },
    );
  }

  List<IrValue> _readSharedStrings(String path) {
    final text = pkg.text(path);
    if (text == null) return const [];
    final out = <IrValue>[];
    _RichBuilder? b;
    var inT = false;
    final buf = StringBuffer();
    try {
      for (final e in parseEvents(text, validateNesting: true)) {
        if (e is XmlStartElementEvent) {
          switch (_local(e.name)) {
            case 'si':
              b = _RichBuilder(colors, _richDefaults);
              if (e.isSelfClosing) {
                out.add(b.build());
                b = null;
              }
            case 'r':
              b?.startRun();
            case 'rPh':
              b?.inRPh = true;
            case 't':
              if (e.isSelfClosing) break;
              inT = true;
              buf.clear();
            case 'b' || 'i' || 'u' || 'strike' || 'sz' || 'rFont' || 'color':
              if (b != null && b.inRun) b.prop(e);
          }
        } else if (e is XmlTextEvent) {
          if (inT) buf.write(e.value);
        } else if (e is XmlCDATAEvent) {
          if (inT) buf.write(e.value);
        } else if (e is XmlEndElementEvent) {
          switch (_local(e.name)) {
            case 't':
              if (inT) b?.addText(buf.toString());
              inT = false;
            case 'r':
              b?.endRun();
            case 'rPh':
              b?.inRPh = false;
            case 'si':
              if (b != null) out.add(b.build());
              b = null;
          }
        }
      }
    } on XmlException catch (e) {
      throw XlsxFormatException(
        'The shared strings part is not well-formed XML (${e.message})',
      );
    }
    return out;
  }

  int _formatOf(int? s) {
    final key = s ?? 0;
    return _xfIndex[key] ??= doc.formats.intern(styles.xf(key).format);
  }

  static final RegExp _sheetDataStart = RegExp(
    r'<(\w+:)?sheetData(\s[^>]*)?(/?)>',
  );
  static final RegExp _sheetDataEnd = RegExp(r'</(\w+:)?sheetData\s*>');

  void _readSheet(
    String path,
    IrSheet sheet,
    ExcelFormulaTranslator translator,
  ) {
    final text = pkg.text(path) ?? '';
    final start = _sheetDataStart.firstMatch(text);
    String rest;
    String data;
    if (start == null) {
      rest = text;
      data = '';
    } else if (start.group(3) == '/') {
      rest = text.substring(0, start.start) + text.substring(start.end);
      data = '';
    } else {
      final end = _sheetDataEnd.firstMatch(text.substring(start.end));
      if (end == null) {
        throw XlsxFormatException('Sheet "${sheet.name}" is truncated');
      }
      data = text.substring(start.end, start.end + end.start);
      rest =
          text.substring(0, start.start) + text.substring(start.end + end.end);
    }
    XmlElement root;
    try {
      root = XmlDocument.parse(rest).rootElement;
    } on XmlException catch (e) {
      throw XlsxFormatException(
        'Sheet "${sheet.name}" is not well-formed XML (${e.message})',
      );
    }
    final warn = doc.warnings;
    final sheetRels = pkg.rels(path);

    // sheetPr
    final sheetPr = root.child('sheetPr');
    final tab = sheetPr?.child('tabColor');
    if (tab != null) {
      sheet.tabColor =
          ColorResolver(
            theme: themeSlots,
            palette: colors.palette,
            themeReferences: false,
          ).resolve(
            rgb: tab.attr('rgb'),
            theme: tab.attr('theme'),
            indexed: tab.attr('indexed'),
            tint: tab.attr('tint'),
          );
    }
    final fitToPage =
        sheetPr?.child('pageSetUpPr')?.boolAttr('fitToPage') ?? false;
    // sheetViews
    final view = root.child('sheetViews')?.child('sheetView');
    if (view != null) {
      sheet.rtl = view.boolAttr('rightToLeft') ?? false;
      sheet.showGridlines = view.boolAttr('showGridLines') ?? true;
      final pane = view.child('pane');
      final st = pane?.attr('state');
      if (pane != null && (st == 'frozen' || st == 'frozenSplit')) {
        sheet.frozenColumns = (pane.doubleAttr('xSplit') ?? 0).toInt();
        sheet.frozenRows = (pane.doubleAttr('ySplit') ?? 0).toInt();
      }
    }
    // sheetFormatPr
    final fpr = root.child('sheetFormatPr');
    if (fpr != null) {
      final h = fpr.doubleAttr('defaultRowHeight');
      if (h != null) sheet.defaultRowHeight = Ooxml.ptToPx(h);
      final w = fpr.doubleAttr('defaultColWidth');
      final base = fpr.doubleAttr('baseColWidth');
      if (w != null) {
        sheet.defaultColumnWidth = Ooxml.widthToPx(w);
      } else if (base != null) {
        sheet.defaultColumnWidth = Ooxml.widthToPx(base + 5 / Ooxml.mdw);
      }
      if (fpr.boolAttr('zeroHeight') ?? false) {
        warn.add(
          'zeroHeight',
          'Rows hidden by default were shown',
          sheet: sheet.name,
        );
      }
    }
    sheet.defaultColumnWidth ??= 64;
    sheet.defaultRowHeight ??= 20;

    // cells
    final arrays = <GridRect>[];
    final xfWarnings = <(String, String), int>{};
    _readSheetData(data, sheet, translator, arrays, xfWarnings);
    for (final e in xfWarnings.entries) {
      warn.add(
        e.key.$1,
        '${e.key.$2} (${e.value} cells)',
        sheet: sheet.name,
        count: 1,
      );
    }
    for (final a in arrays) {
      for (var r = a.top; r <= a.bottom; r++) {
        for (var c = a.left; c <= a.right; c++) {
          if (r == a.top && c == a.left) continue;
          final cell = sheet.cells.get(r, c);
          if (cell == null || cell.formulaA1 != null) continue;
          final cleared = cell.copyWith(clearValue: true);
          sheet.cells.set(r, c, cleared.isEmpty ? null : cleared);
        }
      }
    }

    // cols (after cells: runs are capped at the used range). A styled run
    // reaching the last column is the sheet default format.
    final usedCols = sheet.cells.maxCol + 1;
    final cap = usedCols > 26 ? usedCols - 1 : 25;
    for (final col
        in root.child('cols')?.elems('col') ?? const <XmlElement>[]) {
      final min = (col.intAttr('min') ?? 1) - 1;
      var max = (col.intAttr('max') ?? (min + 1)) - 1;
      final hidden = col.boolAttr('hidden') ?? false;
      var format = col.attr('style') != null
          ? _formatOf(col.intAttr('style'))
          : 0;
      if (max >= Ooxml.maxCols - 1 && format != 0 && sheet.defaultFormat == 0) {
        sheet.defaultFormat = format;
        format = 0;
      }
      if (max > cap) max = cap < min ? min : cap;
      if (min > max) continue;
      final width = col.doubleAttr('width');
      final px = width == null ? null : Ooxml.widthToPx(width);
      final custom =
          (col.boolAttr('customWidth') ?? false) ||
          (px != null && px != sheet.defaultColumnWidth);
      final dim = IrDim(
        size: custom ? px : null,
        hidden: hidden,
        outlineLevel: col.intAttr('outlineLevel') ?? 0,
        collapsed: col.boolAttr('collapsed') ?? false,
        format: format,
      );
      if (dim.isDefault) continue;
      for (var c = min; c <= max; c++) {
        sheet.columns[c] = dim;
      }
    }
    _relativeFormats(sheet);

    for (final m
        in root.child('mergeCells')?.elems('mergeCell') ??
            const <XmlElement>[]) {
      final r = IrRange.parseA1(m.attr('ref') ?? '')?.$2;
      if (r != null && r.isBounded && !(r.r1 == r.r2 && r.c1 == r.c2)) {
        sheet.merges.add(r.rect);
      }
    }

    // hyperlinks
    for (final h
        in root.child('hyperlinks')?.elems('hyperlink') ??
            const <XmlElement>[]) {
      final r = IrRange.parseA1(h.attr('ref') ?? '')?.$2;
      if (r == null || !r.isBounded) continue;
      final rel = sheetRels[h.attr('id')];
      final loc = h.attr('location');
      String? link;
      if (rel != null && rel.external) {
        link = loc == null || loc.isEmpty ? rel.target : '${rel.target}#$loc';
      } else if (loc != null && loc.isNotEmpty) {
        // Canonical A1 (`'Lists'!A1` → `Lists!A1`); names stay as they are.
        link = '#${A1Area.tryParse(loc)?.format() ?? loc}';
      }
      if (link == null) continue;
      var n = 0;
      for (var row = r.r1!; row <= r.r2! && n < 10000; row++) {
        for (var c = r.c1!; c <= r.c2! && n < 10000; c++, n++) {
          final cell = sheet.cells.get(row, c) ?? const IrCell();
          sheet.cells.set(row, c, cell.copyWith(link: link));
        }
      }
    }

    final rules = XlsxRules(translator, warn, sheet: sheet.name);
    for (final dv
        in root.child('dataValidations')?.elems('dataValidation') ??
            const <XmlElement>[]) {
      final v = rules.importValidation(dv);
      if (v != null) sheet.validations.add(v);
    }
    final cfs = <(int, IrConditionalFormat)>[];
    for (final cf in root.elems('conditionalFormatting')) {
      final ranges = parseSqref(cf.attr('sqref'));
      for (final rule in cf.elems('cfRule')) {
        final c = rules.importConditionalFormat(
          rule,
          ranges,
          styles.dxfs,
          colors,
        );
        if (c != null) cfs.add((rule.intAttr('priority') ?? 1 << 30, c));
      }
    }
    // x14 extensions (cross-sheet validations, extended CF).
    for (final ext
        in root.child('extLst')?.elems('ext') ?? const <XmlElement>[]) {
      for (final dv
          in ext.child('dataValidations')?.elems('dataValidation') ??
              const <XmlElement>[]) {
        final v = rules.importValidation(dv);
        if (v != null) sheet.validations.add(v);
      }
      if (ext.child('conditionalFormattings') != null) {
        warn.add(
          'cfExtension',
          'Extended conditional formats (data bar/icon options) were simplified',
          sheet: sheet.name,
        );
      }
    }
    cfs.sort((a, b) => a.$1.compareTo(b.$1));
    sheet.conditionalFormats.addAll(cfs.map((e) => e.$2));

    final af = root.child('autoFilter');
    if (af != null) {
      final f = rules.importFilter(
        af,
        (r, c) => irDisplayText(doc, sheet.cells.get(r, c)),
      );
      if (f != null) {
        sheet.autoFilter = f;
        if (f.criteria.isNotEmpty && f.range.isBounded) {
          // Rows hidden by the filter are recomputed, not user-hidden.
          for (var r = f.range.r1! + 1; r <= f.range.r2!; r++) {
            final d = sheet.rows[r];
            if (d != null && d.hidden) {
              sheet.rows[r] = d.copyWith(hidden: false);
            }
          }
        }
      }
    }

    final print = XlsxPrint.read(
      pageSetup: root.child('pageSetup'),
      margins: root.child('pageMargins'),
      options: root.child('printOptions'),
      headerFooter: root.child('headerFooter'),
      rowBreaks: root.child('rowBreaks'),
      colBreaks: root.child('colBreaks'),
      fitToPage: fitToPage,
    );
    if (print != null) sheet.print = {...?sheet.print, ...print};

    if (root.child('sheetProtection') != null) {
      warn.add(
        'protection',
        'Protection was not imported',
        severity: ImportSeverity.info,
        sheet: sheet.name,
      );
    }
    if (root.child('tableParts') != null) {
      warn.add(
        'tables',
        'Tables were imported as plain ranges',
        severity: ImportSeverity.info,
        sheet: sheet.name,
      );
    }

    // comments / notes
    final persons = _readPersons();
    for (final rel in sheetRels.values) {
      if (rel.type.endsWith('/comments')) _readComments(rel.target, sheet);
    }
    for (final rel in sheetRels.values) {
      if (rel.type.endsWith('/threadedComment')) {
        _readThreaded(rel.target, sheet, persons);
      }
    }
    if (options.includeImages) {
      for (final rel in sheetRels.values) {
        if (rel.type.endsWith('/drawing')) _readDrawing(rel.target, sheet);
      }
    }
  }

  void _readSheetData(
    String data,
    IrSheet sheet,
    ExcelFormulaTranslator translator,
    List<GridRect> arrays,
    Map<(String, String), int> xfWarnings,
  ) {
    if (data.isEmpty) return;
    final shared = <String, _Shared>{};
    final unsupportedCounts = <String, int>{};
    var implicit = 0;
    var fictitious = 0;
    var row = -1;
    var col = -1;
    // Current cell.
    String? cS, cT, fType, fRef, fSi;
    var cm = false;
    String? fText, vText;
    _RichBuilder? inline;
    var capture = 0; // 0 none, 1 f, 2 v, 3 inline t
    final buf = StringBuffer();

    IrValue? numberValue(double d, XlsxXf xf) {
      if (!xf.isDate) return IrNumber(d);
      if (doc.date1904) return IrNumber(d + 1462);
      if (d >= 60 && d < 61) {
        fictitious++;
        return const IrError(CellErrorKind.value);
      }
      if (d >= 1 && d < 60) return IrNumber(d + 1);
      return IrNumber(d);
    }

    void finishCell() {
      final xf = styles.xf(cS == null ? 0 : int.tryParse(cS));
      for (final w in xf.warnings) {
        xfWarnings[w] = (xfWarnings[w] ?? 0) + 1;
      }
      final format = _formatOf(cS == null ? 0 : int.tryParse(cS));
      IrValue? value;
      final v = vText;
      switch (cT) {
        case 's':
          final i = int.tryParse(v ?? '');
          if (i != null && i >= 0 && i < sst.length) value = sst[i];
        case 'inlineStr':
          value = inline?.build();
        case 'b':
          if (v != null) value = IrBool(v.trim() == '1' || v.trim() == 'true');
        case 'e':
          if (v != null) {
            value = IrError(CellErrorKind.tryParse(v) ?? CellErrorKind.value);
          }
        case 'str':
          if (v != null) value = IrText(Ooxml.decodeEscapes(v));
        case 'd':
          final dt = v == null ? null : DateTime.tryParse(v.trim());
          if (dt != null) {
            final u = DateTime.utc(
              dt.year,
              dt.month,
              dt.day,
              dt.hour,
              dt.minute,
              dt.second,
              dt.millisecond,
            );
            value = IrNumber(
              DateSerial.fromUnixMillis(u.millisecondsSinceEpoch),
            );
          }
        default:
          final d = double.tryParse(v?.trim() ?? '');
          if (d != null && d.isFinite) value = numberValue(d, xf);
      }
      String? formula;
      FormulaTranslation? tr;
      var kind = IrFormulaKind.normal;
      GridRect? arrayRef;
      if (fType == 'shared' && fSi != null) {
        if (fText != null && fText.trim().isNotEmpty) {
          final t = translator.importFormula(fText);
          shared[fSi] = _Shared(SharedFormula(t.formula, row, col), t);
        }
        final sh = shared[fSi];
        if (sh != null) {
          tr = sh.translation;
          formula = sh.formula.at(row, col);
        }
      } else if (fText != null && fText.trim().isNotEmpty) {
        tr = translator.importFormula(fText);
        formula = tr.formula;
        if (fType == 'array') {
          kind = cm ? IrFormulaKind.dynamicArray : IrFormulaKind.array;
          final r = IrRange.parseA1(fRef ?? '')?.$2;
          arrayRef = r != null && r.isBounded
              ? r.rect
              : GridRect.cell(row, col);
        }
      }
      String? note;
      if (formula != null && tr != null) {
        if (tr.changedSemantics) implicit++;
        if (!tr.isSupported) {
          for (final u in tr.unsupported) {
            unsupportedCounts[u] = (unsupportedCounts[u] ?? 0) + 1;
          }
          note =
              'Imported value — original formula used unsupported function '
              '${tr.unsupported.join(', ')}: =$formula';
          if (options.unsupportedFormulas == UnsupportedFormulaMode.text) {
            value = IrText('=$formula');
          }
          formula = null;
          kind = IrFormulaKind.normal;
          arrayRef = null;
        } else {
          if (kind == IrFormulaKind.array ||
              (kind == IrFormulaKind.dynamicArray &&
                  FormulaRewriter.needsArrayMode(formula))) {
            // Excel evaluates array formulas element-wise (11 §5.2).
            formula = 'ARRAYFORMULA($formula)';
          }
          if (arrayRef != null) arrays.add(arrayRef);
        }
      }
      final cell = IrCell(
        value: value,
        formulaA1: formula,
        formulaKind: kind,
        arrayRef: arrayRef,
        format: format,
        note: note,
      );
      if (!cell.isEmpty) sheet.cells.set(row, col, cell);
    }

    try {
      for (final e in parseEvents(data, validateNesting: true)) {
        if (e is XmlStartElementEvent) {
          switch (_local(e.name)) {
            case 'row':
              final r = int.tryParse(_evAttr(e, 'r') ?? '');
              row = r != null ? r - 1 : row + 1;
              col = -1;
              if (row >= Ooxml.maxRows) row = Ooxml.maxRows - 1;
              final custom = _evAttr(e, 'customHeight');
              final ht = double.tryParse(_evAttr(e, 'ht') ?? '');
              final hidden = _evAttr(e, 'hidden');
              final cf = _evAttr(e, 'customFormat');
              final s = int.tryParse(_evAttr(e, 's') ?? '');
              final dim = IrDim(
                size: (custom == '1' || custom == 'true') && ht != null
                    ? Ooxml.ptToPx(ht)
                    : null,
                hidden: hidden == '1' || hidden == 'true',
                outlineLevel:
                    int.tryParse(_evAttr(e, 'outlineLevel') ?? '') ?? 0,
                collapsed:
                    _evAttr(e, 'collapsed') == '1' ||
                    _evAttr(e, 'collapsed') == 'true',
                format: (cf == '1' || cf == 'true') && s != null
                    ? _formatOf(s)
                    : 0,
              );
              if (!dim.isDefault) sheet.rows[row] = dim;
            case 'c':
              final ref = _evAttr(e, 'r');
              final a = ref == null ? null : A1Area.tryParse(ref);
              if (a != null && a.kind == A1Kind.cell) {
                row = a.row1!;
                col = a.col1!;
              } else {
                col++;
                if (row < 0) row = 0;
              }
              cS = _evAttr(e, 's');
              cT = _evAttr(e, 't');
              cm = _evAttr(e, 'cm') != null;
              fType = fRef = fSi = fText = vText = null;
              inline = null;
              if (e.isSelfClosing) finishCell();
            case 'f':
              fType = _evAttr(e, 't');
              fRef = _evAttr(e, 'ref');
              fSi = _evAttr(e, 'si');
              fText = '';
              if (!e.isSelfClosing) {
                capture = 1;
                buf.clear();
              }
            case 'v':
              if (!e.isSelfClosing) {
                capture = 2;
                buf.clear();
              }
            case 'is':
              inline = _RichBuilder(colors, _richDefaults);
            case 'r':
              inline?.startRun();
            case 'rPh':
              inline?.inRPh = true;
            case 't':
              if (inline != null && !e.isSelfClosing) {
                capture = 3;
                buf.clear();
              }
            case 'b' || 'i' || 'u' || 'strike' || 'sz' || 'rFont' || 'color':
              if (inline != null && inline.inRun) inline.prop(e);
          }
        } else if (e is XmlTextEvent) {
          if (capture != 0) buf.write(e.value);
        } else if (e is XmlCDATAEvent) {
          if (capture != 0) buf.write(e.value);
        } else if (e is XmlEndElementEvent) {
          switch (_local(e.name)) {
            case 'f':
              if (capture == 1) fText = buf.toString();
              capture = 0;
            case 'v':
              if (capture == 2) vText = buf.toString();
              capture = 0;
            case 't':
              if (capture == 3) inline?.addText(buf.toString());
              capture = 0;
            case 'r':
              inline?.endRun();
            case 'rPh':
              inline?.inRPh = false;
            case 'c':
              finishCell();
          }
        }
      }
    } on XmlException catch (e) {
      throw XlsxFormatException(
        'Sheet "${sheet.name}" is not well-formed XML (${e.message})',
      );
    }
    for (final e in unsupportedCounts.entries) {
      doc.warnings.add(
        'unsupportedFunction',
        '${e.value} cells used unsupported ${e.key.contains(' ') ? '' : 'function '}${e.key}',
        sheet: sheet.name,
        count: e.value,
      );
    }
    if (implicit > 0) {
      doc.warnings.add(
        'implicitIntersection',
        'The implicit intersection operator @ was removed ($implicit formulas)',
        sheet: sheet.name,
        count: implicit,
      );
    }
    if (fictitious > 0) {
      doc.warnings.add(
        'fictitiousDate',
        'Excel\'s fictitious date 1900-02-29 was imported as #VALUE!',
        sheet: sheet.name,
        count: fictitious,
      );
    }
  }

  Map<String, String>? _persons;

  Map<String, String> _readPersons() {
    if (_persons != null) return _persons!;
    final out = <String, String>{};
    for (final name in pkg.names) {
      if (!name.toLowerCase().contains('persons/')) continue;
      for (final p
          in pkg.xml(name)?.findAllElements('person', namespaceUri: '*') ??
              const <XmlElement>[]) {
        final id = p.attr('id');
        if (id != null) out[id] = p.attr('displayName') ?? '';
      }
    }
    return _persons = out;
  }

  void _readComments(String path, IrSheet sheet) {
    final root = pkg.xml(path)?.rootElement;
    if (root == null) return;
    final authors = [
      for (final a
          in root.child('authors')?.elems('author') ?? const <XmlElement>[])
        a.innerText,
    ];
    for (final c
        in root.child('commentList')?.elems('comment') ??
            const <XmlElement>[]) {
      final a = A1Area.tryParse(c.attr('ref') ?? '');
      if (a == null) continue;
      final textEl = c.child('text');
      final b = StringBuffer();
      for (final t in textEl?.descendantElements ?? const <XmlElement>[]) {
        if (t.localName == 't' && t.parentElement?.localName != 'rPh') {
          b.write(t.innerText);
        }
      }
      var text = Ooxml.decodeEscapes(b.toString());
      final ai = c.intAttr('authorId');
      final author = ai != null && ai >= 0 && ai < authors.length
          ? authors[ai]
          : null;
      if (author != null && author.isNotEmpty && text.startsWith('$author:')) {
        text = text.substring(author.length + 1);
        if (text.startsWith('\r\n')) {
          text = text.substring(2);
        } else if (text.startsWith('\n')) {
          text = text.substring(1);
        }
      }
      final cell = sheet.cells.get(a.row1!, a.col1!) ?? const IrCell();
      sheet.cells.set(a.row1!, a.col1!, cell.copyWith(note: text));
    }
  }

  void _readThreaded(String path, IrSheet sheet, Map<String, String> persons) {
    final root = pkg.xml(path)?.rootElement;
    if (root == null) return;
    final byRef = <String, List<String>>{};
    for (final t in root.elems('threadedComment')) {
      final ref = t.attr('ref');
      if (ref == null) continue;
      final name = persons[t.attr('personId')] ?? '';
      final body = t.child('text')?.innerText ?? '';
      (byRef[ref] ??= []).add(name.isEmpty ? body : '[$name] $body');
    }
    for (final e in byRef.entries) {
      final a = A1Area.tryParse(e.key);
      if (a == null) continue;
      final cell = sheet.cells.get(a.row1!, a.col1!) ?? const IrCell();
      sheet.cells.set(
        a.row1!,
        a.col1!,
        cell.copyWith(note: e.value.join('\n')),
      );
    }
    if (byRef.isNotEmpty) {
      doc.warnings.add(
        'threadedComments',
        'Threaded comments were imported as notes',
        severity: ImportSeverity.info,
        sheet: sheet.name,
        count: byRef.length,
      );
    }
  }

  double _colPx(IrSheet s, int c) =>
      s.columns[c]?.size ?? s.defaultColumnWidth ?? 64;
  double _rowPx(IrSheet s, int r) =>
      s.rows[r]?.size ?? s.defaultRowHeight ?? 20;

  /// Position and size of a drawing anchor in px.
  IrAnchor _anchor(XmlElement anchor, IrSheet sheet, XmlElement? xfrmOwner) {
    final kind = anchor.localName;
    int row = 0, col = 0;
    double dx = 0, dy = 0, w = 0, h = 0;
    double emu(XmlElement? e, String n) =>
        (double.tryParse(e?.child(n)?.innerText.trim() ?? '') ?? 0) /
        Ooxml.emuPerPx;
    final from = anchor.child('from');
    if (from != null) {
      col = int.tryParse(from.child('col')?.innerText.trim() ?? '') ?? 0;
      row = int.tryParse(from.child('row')?.innerText.trim() ?? '') ?? 0;
      dx = emu(from, 'colOff');
      dy = emu(from, 'rowOff');
    }
    final extEl =
        anchor.child('ext') ??
        xfrmOwner?.child('spPr')?.child('xfrm')?.child('ext') ??
        xfrmOwner?.child('xfrm')?.child('ext');
    if (kind == 'twoCellAnchor' && anchor.child('to') != null) {
      final to = anchor.child('to')!;
      final tc = int.tryParse(to.child('col')?.innerText.trim() ?? '') ?? col;
      final trw = int.tryParse(to.child('row')?.innerText.trim() ?? '') ?? row;
      var x = -dx, y = -dy;
      for (var c = col; c < tc; c++) {
        x += _colPx(sheet, c);
      }
      for (var r = row; r < trw; r++) {
        y += _rowPx(sheet, r);
      }
      w = x + emu(to, 'colOff');
      h = y + emu(to, 'rowOff');
    } else if (extEl != null) {
      w = (extEl.doubleAttr('cx') ?? 0) / Ooxml.emuPerPx;
      h = (extEl.doubleAttr('cy') ?? 0) / Ooxml.emuPerPx;
    }
    if (kind == 'absoluteAnchor') {
      var x = (anchor.child('pos')?.doubleAttr('x') ?? 0) / Ooxml.emuPerPx;
      var y = (anchor.child('pos')?.doubleAttr('y') ?? 0) / Ooxml.emuPerPx;
      col = 0;
      while (x >= _colPx(sheet, col) && col < 16383) {
        x -= _colPx(sheet, col++);
      }
      row = 0;
      while (y >= _rowPx(sheet, row) && row < Ooxml.maxRows - 1) {
        y -= _rowPx(sheet, row++);
      }
      dx = x;
      dy = y;
    }
    return IrAnchor(
      row: row,
      col: col,
      dx: _r(dx),
      dy: _r(dy),
      width: _r(w),
      height: _r(h),
    );
  }

  void _readDrawing(String path, IrSheet sheet) {
    final root = pkg.xml(path)?.rootElement;
    if (root == null) return;
    final rels = pkg.rels(path);
    var shapes = 0;
    for (final anchor in root.childElements) {
      final kind = anchor.localName;
      if (kind != 'twoCellAnchor' &&
          kind != 'oneCellAnchor' &&
          kind != 'absoluteAnchor') {
        continue;
      }
      final frame = anchor.child('graphicFrame');
      if (frame != null) {
        final data = frame.child('graphic')?.child('graphicData');
        final chartEl = data?.child('chart');
        final rel = rels[chartEl?.attr('id')];
        final part = rel == null ? null : pkg.xml(rel.target)?.rootElement;
        final spec = part == null
            ? null
            : XlsxCharts.read(part, colors, doc.warnings, sheet: sheet.name);
        if (spec == null) {
          if (part == null) {
            doc.warnings.add(
              'chartSkipped',
              'Charts that could not be read were not imported',
              sheet: sheet.name,
            );
          }
          continue;
        }
        final props = frame.child('nvGraphicFramePr')?.child('cNvPr');
        sheet.charts.add(
          IrChart(
            anchor: _anchor(anchor, sheet, frame),
            spec: spec,
            title: props?.attr('title'),
            altText: props?.attr('descr'),
          ),
        );
        continue;
      }
      final pic = anchor.child('pic');
      if (pic == null) {
        shapes++;
        continue;
      }
      final embed = pic.child('blipFill')?.child('blip')?.attr('embed');
      final rel = rels[embed];
      if (rel == null) continue;
      final ext = rel.target.split('.').last.toLowerCase();
      final mime = switch (ext) {
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'gif' => 'image/gif',
        'bmp' => 'image/bmp',
        'webp' => 'image/webp',
        'svg' => 'image/svg+xml',
        _ => null,
      };
      if (mime == null) {
        doc.warnings.add(
          'imageFormat',
          'Images in ${ext.toUpperCase()} format were not imported',
          sheet: sheet.name,
        );
        continue;
      }
      var bytes = pkg.bytes(rel.target);
      if (bytes == null) continue;
      var name = rel.target.split('/').last;
      if (mime == 'image/bmp') {
        // Wonky has no BMP images: converted to PNG.
        final decoded = _decodeBmp(bytes);
        if (decoded == null) {
          doc.warnings.add(
            'imageFormat',
            'Images in BMP format that could not be read were not imported',
            sheet: sheet.name,
          );
          continue;
        }
        bytes = img.encodePng(decoded);
        name = '${name.substring(0, name.length - ext.length)}png';
      }
      final props = pic.child('nvPicPr')?.child('cNvPr');
      sheet.images.add(
        IrImage(
          bytes: bytes,
          mimeType: mime == 'image/bmp' ? 'image/png' : mime,
          anchor: _anchor(anchor, sheet, pic),
          altText: props?.attr('descr'),
          title: props?.attr('title'),
          name: name,
        ),
      );
    }
    if (shapes > 0) {
      doc.warnings.add(
        'shapes',
        'Shapes and drawings were not imported',
        sheet: sheet.name,
        count: shapes,
      );
    }
  }

  static img.Image? _decodeBmp(Uint8List bytes) {
    try {
      return img.decodeBmp(bytes);
    } on Object {
      return null;
    }
  }

  static double _r(double v) => (v * 100).roundToDouble() / 100;
}
