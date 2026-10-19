import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Thrown for files that are not readable spreadsheets (broken zip, missing
/// parts, malformed XML). Imports never crash with other exceptions.
final class XlsxFormatException implements Exception {
  /// Creates the exception.
  const XlsxFormatException(this.message);

  /// Human-readable reason.
  final String message;

  @override
  String toString() => 'XlsxFormatException: $message';
}

/// OOXML namespaces, content types and relationship types.
abstract final class Ooxml {
  static const main =
      'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
  static const rel =
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
  static const pkgRel =
      'http://schemas.openxmlformats.org/package/2006/relationships';
  static const contentTypes =
      'http://schemas.openxmlformats.org/package/2006/content-types';
  static const drawingMl =
      'http://schemas.openxmlformats.org/drawingml/2006/main';
  static const xdr =
      'http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing';
  static const mc =
      'http://schemas.openxmlformats.org/markup-compatibility/2006';

  static const relOfficeDocument = '$rel/officeDocument';
  static const relWorksheet = '$rel/worksheet';
  static const relStyles = '$rel/styles';
  static const relSharedStrings = '$rel/sharedStrings';
  static const relTheme = '$rel/theme';
  static const relHyperlink = '$rel/hyperlink';
  static const relComments = '$rel/comments';
  static const relVml = '$rel/vmlDrawing';
  static const relDrawing = '$rel/drawing';
  static const relImage = '$rel/image';
  static const relChart = '$rel/chart';
  static const relSheetMetadata = '$rel/sheetMetadata';
  static const relCoreProps =
      'http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties';
  static const relExtProps = '$rel/extended-properties';

  /// Max rows/columns of an XLSX sheet.
  static const maxRows = 1048576;
  static const maxCols = 16384;

  /// EMU per px at 96 dpi.
  static const emuPerPx = 9525;

  /// Maximum digit width of Calibri 11 at 96 dpi (column width formula).
  static const mdw = 7;

  /// `<col width>` (characters incl. padding) → px (11 §5.2).
  static double widthToPx(double w) =>
      ((256 * w + (128 ~/ mdw)) / 256 * mdw).truncateToDouble();

  /// px → `<col width>` such that [widthToPx] returns the same integer px.
  static double pxToWidth(double px) {
    final target = px.roundToDouble();
    final w = (target + 0.0078125) / mdw;
    // The shortest decimal that maps back exactly.
    for (var digits = 2; digits <= 8; digits++) {
      final f = _pow10(digits);
      final cand = (w * f).round() / f;
      if (widthToPx(cand) == target) return cand;
    }
    return w;
  }

  static double _pow10(int n) {
    var r = 1.0;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  /// Row height pt → px.
  static double ptToPx(double pt) => (pt * 4 / 3 * 100).roundToDouble() / 100;

  /// px → pt.
  static double pxToPt(double px) => (px * 0.75 * 100).roundToDouble() / 100;

  static final RegExp _xEscape = RegExp(r'_x([0-9A-Fa-f]{4})_');

  /// Decodes `_xHHHH_` escapes of OOXML strings.
  static String decodeEscapes(String s) {
    if (!s.contains('_x')) return s;
    return s.replaceAllMapped(
      _xEscape,
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
    );
  }

  /// Encodes characters invalid in XML 1.0 (and literal `_xHHHH_`
  /// sequences) as `_xHHHH_`.
  static String encodeEscapes(String s) {
    var needs = false;
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if ((c < 0x20 && c != 0x09 && c != 0x0a && c != 0x0d) ||
          c == 0xfffe ||
          c == 0xffff) {
        needs = true;
        break;
      }
    }
    if (!needs && !s.contains('_x')) return s;
    final out = s.replaceAllMapped(_xEscape, (m) => '_x005F${m.group(0)}');
    final b = StringBuffer();
    for (var i = 0; i < out.length; i++) {
      final c = out.codeUnitAt(i);
      if ((c < 0x20 && c != 0x09 && c != 0x0a && c != 0x0d) ||
          c == 0xfffe ||
          c == 0xffff) {
        b.write('_x${c.toRadixString(16).padLeft(4, '0').toUpperCase()}_');
      } else {
        b.writeCharCode(c);
      }
    }
    return b.toString();
  }

  static final RegExp _escChars = RegExp('[&<>\r]');

  /// Escapes text content for XML (CR as a character reference: XML
  /// parsers normalize literal CR to LF).
  static String esc(String s) {
    final t = encodeEscapes(s);
    if (!t.contains(_escChars)) return t;
    return t
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\r', '&#13;');
  }

  /// Escapes an attribute value for XML (double quotes).
  static String attr(String s) {
    final t = encodeEscapes(s);
    return t
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll('\n', '&#10;')
        .replaceAll('\r', '&#13;')
        .replaceAll('\t', '&#9;');
  }

  /// Resolves a relationship [target] relative to the part [base]
  /// (`xl/workbook.xml` + `worksheets/sheet1.xml` → `xl/worksheets/sheet1.xml`).
  static String resolve(String base, String target) {
    if (target.startsWith('/')) return target.substring(1);
    final dir = base.contains('/')
        ? base.substring(0, base.lastIndexOf('/'))
        : '';
    final parts = [if (dir.isNotEmpty) ...dir.split('/')];
    for (final p in target.split('/')) {
      if (p == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (p != '.' && p.isNotEmpty) {
        parts.add(p);
      }
    }
    return parts.join('/');
  }

  /// The `_rels` part path of [part].
  static String relsPathOf(String part) {
    final slash = part.lastIndexOf('/');
    final dir = slash < 0 ? '' : part.substring(0, slash + 1);
    return '${dir}_rels/${part.substring(slash + 1)}.rels';
  }
}

/// One relationship.
final class OoxmlRel {
  /// Creates a relationship.
  const OoxmlRel(this.id, this.type, this.target, {this.external = false});

  final String id;
  final String type;

  /// Resolved part path, or the URL for external targets.
  final String target;
  final bool external;
}

/// Read access to the parts of an OOXML/ODF zip package.
final class ZipPackage {
  ZipPackage._(this._files);

  /// Most bytes the parts of a package may unpack to (zip bombs): 256 MB,
  /// about 1M cells (`sheets.maxCellsPerSpreadsheet`) of verbose XML.
  static const defaultMaxUnpackedBytes = 256 * 1024 * 1024;

  /// Most entries a package may have.
  static const defaultMaxEntries = 10000;

  /// Opens [bytes]; throws [XlsxFormatException] for non-zip data and for
  /// packages with more than [maxEntries] entries or whose parts declare
  /// more than [maxUnpackedBytes] in total. Only the directory is read
  /// here; the `archive` package never inflates a part past its declared
  /// size, so the declared total bounds what reading the parts can
  /// allocate.
  factory ZipPackage.open(
    Uint8List bytes, {
    int maxUnpackedBytes = defaultMaxUnpackedBytes,
    int maxEntries = defaultMaxEntries,
  }) {
    if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4b) {
      throw const XlsxFormatException(
        'The file is not a ZIP package (XLSX/ODS)',
      );
    }
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw XlsxFormatException('The ZIP package is damaged ($e)');
    }
    if (archive.files.length > maxEntries) {
      throw XlsxFormatException(
        'The file is too large to import: it has more than $maxEntries '
        'parts.',
      );
    }
    final files = <String, ArchiveFile>{};
    var unpacked = 0;
    for (final f in archive.files) {
      if (!f.isFile) continue;
      unpacked += f.size;
      if (unpacked > maxUnpackedBytes) {
        throw XlsxFormatException(
          'The file is too large to import: it unpacks to more than '
          '${maxUnpackedBytes ~/ (1024 * 1024)} MB.',
        );
      }
      files[f.name.replaceAll('\\', '/')] = f;
    }
    return ZipPackage._(files);
  }

  final Map<String, ArchiveFile> _files;

  /// Part names.
  Iterable<String> get names => _files.keys;

  /// Whether [name] exists (case-insensitive fallback).
  bool has(String name) => _find(name) != null;

  ArchiveFile? _find(String name) {
    final f = _files[name];
    if (f != null) return f;
    final l = name.toLowerCase();
    for (final e in _files.entries) {
      if (e.key.toLowerCase() == l) return e.value;
    }
    return null;
  }

  /// Bytes of [name] or null.
  Uint8List? bytes(String name) {
    final f = _find(name);
    if (f == null) return null;
    try {
      return f.content;
    } catch (e) {
      throw XlsxFormatException('Part $name cannot be decompressed ($e)');
    }
  }

  /// UTF-8 (BOM-tolerant) text of [name] or null.
  String? text(String name) {
    final b = bytes(name);
    if (b == null) return null;
    var start = 0;
    if (b.length >= 3 && b[0] == 0xef && b[1] == 0xbb && b[2] == 0xbf) {
      start = 3;
    }
    if (b.length >= 2 && b[0] == 0xff && b[1] == 0xfe) {
      final codes = <int>[];
      for (var i = 2; i + 1 < b.length; i += 2) {
        codes.add(b[i] | (b[i + 1] << 8));
      }
      return String.fromCharCodes(codes);
    }
    return utf8.decode(start == 0 ? b : b.sublist(start), allowMalformed: true);
  }

  /// Parsed XML document of [name] or null; malformed XML throws
  /// [XlsxFormatException].
  XmlDocument? xml(String name) {
    final t = text(name);
    if (t == null) return null;
    try {
      return XmlDocument.parse(t);
    } on XmlException catch (e) {
      throw XlsxFormatException(
        'Part $name is not well-formed XML (${e.message})',
      );
    }
  }

  /// Relationships of [part] (`id` → rel).
  Map<String, OoxmlRel> rels(String part) {
    final doc = xml(Ooxml.relsPathOf(part));
    if (doc == null) return const {};
    final out = <String, OoxmlRel>{};
    for (final r in doc.findAllElements('Relationship', namespaceUri: '*')) {
      final id = r.getAttribute('Id');
      final type = r.getAttribute('Type') ?? '';
      final target = r.getAttribute('Target') ?? '';
      if (id == null) continue;
      final ext = r.getAttribute('TargetMode') == 'External';
      out[id] = OoxmlRel(
        id,
        type,
        ext ? target : Ooxml.resolve(part, Uri.decodeFull(target)),
        external: ext,
      );
    }
    return out;
  }
}

/// Small helpers on XML elements (namespace-agnostic local names).
extension XmlElementX on XmlElement {
  /// First child element with [local] name.
  XmlElement? child(String local) {
    for (final c in childElements) {
      if (c.localName == local) return c;
    }
    return null;
  }

  /// Child elements with [local] name.
  Iterable<XmlElement> elems(String local) =>
      childElements.where((c) => c.localName == local);

  /// Attribute by local name (ignores prefixes).
  String? attr(String local) {
    for (final a in attributes) {
      if (a.localName == local) return a.value;
    }
    return null;
  }

  /// Boolean attribute (`1`/`true`).
  bool? boolAttr(String local) {
    final v = attr(local);
    if (v == null) return null;
    return v == '1' || v == 'true';
  }

  /// Integer attribute.
  int? intAttr(String local) => int.tryParse(attr(local) ?? '');

  /// Double attribute.
  double? doubleAttr(String local) => double.tryParse(attr(local) ?? '');
}
