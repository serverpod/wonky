/// XML and ZIP helpers shared by the DOCX and ODT importers.
library;

import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import 'encoding.dart';
import 'import_limits.dart';

/// Parses [text] as XML: strictly first, then without namespace and
/// nesting validation. Returns `null` when the text is not XML at all.
XmlDocument? parseXmlLenient(String text) {
  try {
    return XmlDocument.parse(text);
  } on Object {
    try {
      return XmlDocument(
        const XmlNodeDecoder().convert(
          parseEvents(text, withNamespace: true).toList(),
        ),
      );
    } on Object {
      return null;
    }
  }
}

/// OOXML Strict namespace URIs mapped to their Transitional equivalents.
const _strictAliases = {
  'http://purl.oclc.org/ooxml/wordprocessingml/main':
      'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
  'http://purl.oclc.org/ooxml/officeDocument/relationships':
      'http://schemas.openxmlformats.org/officeDocument/2006/relationships',
  'http://purl.oclc.org/ooxml/drawingml/main':
      'http://schemas.openxmlformats.org/drawingml/2006/main',
  'http://purl.oclc.org/ooxml/drawingml/wordprocessingDrawing':
      'http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing',
  'http://purl.oclc.org/ooxml/drawingml/picture':
      'http://schemas.openxmlformats.org/drawingml/2006/picture',
  'http://purl.oclc.org/ooxml/officeDocument/math':
      'http://schemas.openxmlformats.org/officeDocument/2006/math',
  'http://purl.oclc.org/ooxml/drawingml/chart':
      'http://schemas.openxmlformats.org/drawingml/2006/chart',
  'http://purl.oclc.org/ooxml/drawingml/diagram':
      'http://schemas.openxmlformats.org/drawingml/2006/diagram',
};

String? _canonicalNs(String? uri) => _strictAliases[uri] ?? uri;

/// Namespace-aware element and attribute access.
extension XmlElementAccess on XmlElement {
  /// Whether this element is `{ns}local`.
  bool isA(String ns, String local) =>
      name.local == local && _canonicalNs(name.namespaceUri) == ns;

  /// Child elements `{ns}local`.
  Iterable<XmlElement> kids(String ns, String local) =>
      childElements.where((e) => e.isA(ns, local));

  /// The first child element `{ns}local`.
  XmlElement? kid(String ns, String local) {
    for (final e in childElements) {
      if (e.isA(ns, local)) return e;
    }
    return null;
  }

  /// Descendant elements `{ns}local` (document order).
  Iterable<XmlElement> deep(String ns, String local) =>
      descendantElements.where((e) => e.isA(ns, local));

  /// The value of attribute `{ns}local` (or an unqualified `local` when
  /// [ns] is `null`).
  String? attr(String? ns, String local) {
    for (final a in attributes) {
      if (a.name.local != local) continue;
      final uri = a.name.namespaceUri;
      if (ns == null) {
        if (a.name.prefix == null) return a.value;
      } else if (_canonicalNs(uri) == ns ||
          (uri == null && a.name.prefix != null)) {
        return a.value;
      }
    }
    return null;
  }
}

/// A ZIP package (DOCX, ODT, Markdown zip) with path-normalized parts.
final class ZipPackage {
  ZipPackage._(this._files);

  final Map<String, ArchiveFile> _files;
  final _xmlCache = <String, XmlDocument?>{};

  /// Whether [bytes] start with a ZIP local file header.
  static bool isZip(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
      (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);

  /// Opens [bytes]; `null` when they are not a readable ZIP archive.
  /// Throws [ImportTooLargeException] when the archive exceeds [limits]
  /// (checked before any part is inflated).
  static ZipPackage? open(
    Uint8List bytes, {
    ArchiveLimits limits = ArchiveLimits.standard,
  }) {
    if (!isZip(bytes)) return null;
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } on Object {
      return null;
    }
    limits.check(archive);
    final files = <String, ArchiveFile>{};
    for (final f in archive.files) {
      if (!f.isFile) continue;
      files[normalizePath(f.name)] = f;
    }
    return ZipPackage._(files);
  }

  /// All part names.
  Iterable<String> get names => _files.keys;

  /// Whether the part exists (case-insensitive fallback).
  bool has(String name) => _find(name) != null;

  ArchiveFile? _find(String name) {
    final n = normalizePath(name);
    final direct = _files[n];
    if (direct != null) return direct;
    final lower = n.toLowerCase();
    for (final e in _files.entries) {
      if (e.key.toLowerCase() == lower) return e.value;
    }
    return null;
  }

  /// Bytes of a part, or `null`.
  Uint8List? bytes(String name) {
    final f = _find(name);
    if (f == null) return null;
    try {
      return f.readBytes() ?? Uint8List(0);
    } on Object {
      return null;
    }
  }

  /// Text of a part (encoding detected), or `null`.
  String? text(String name) {
    final b = bytes(name);
    if (b == null) return null;
    return ImportTextDecoder.decode(b).text;
  }

  /// Parsed XML of a part (cached), or `null`.
  XmlDocument? xml(String name) {
    final key = normalizePath(name);
    if (_xmlCache.containsKey(key)) return _xmlCache[key];
    final t = text(name);
    final doc = t == null ? null : parseXmlLenient(t);
    _xmlCache[key] = doc;
    return doc;
  }

  /// Normalizes a part path: no leading `/`, `.`/`..` resolved, `\` → `/`.
  static String normalizePath(String path) {
    final segments = <String>[];
    for (final s in path.replaceAll('\\', '/').split('/')) {
      if (s.isEmpty || s == '.') continue;
      if (s == '..') {
        if (segments.isNotEmpty) segments.removeLast();
      } else {
        segments.add(s);
      }
    }
    return segments.join('/');
  }

  /// Resolves [target] relative to the directory of [fromPart].
  static String resolve(String fromPart, String target) {
    if (target.startsWith('/')) return normalizePath(target);
    final dir = fromPart.contains('/')
        ? fromPart.substring(0, fromPart.lastIndexOf('/') + 1)
        : '';
    String decoded;
    try {
      decoded = Uri.decodeFull(target);
    } on Object {
      decoded = target;
    }
    return normalizePath('$dir$decoded');
  }
}
