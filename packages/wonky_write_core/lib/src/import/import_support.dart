/// Shared building blocks of the rich-format importers (HTML, DOCX, ODT,
/// RTF): warning aggregation, image collection, text sanitizing, monospace
/// font detection, task glyphs and result assembly.
library;

import 'dart:typed_data';

import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:image/image.dart' as img;

import '../delta/embeds.dart';
import '../delta/validator.dart';
import '../ir/doc_tree.dart';
import '../ir/doc_tree_builder.dart';
import 'import_api.dart';

/// Soft line break inside a line (U+2028).
const String importSoftBreak = '\u2028';

/// Collects warnings (deduplicated by kind and message) and aggregates
/// removed formatting into one [ImportWarningKind.formattingRemoved] warning.
final class WarningCollector {
  final _warnings = <ImportWarning>[];
  final _keys = <String>{};
  final _formatting = <String>{};
  int? _formattingBlock;

  /// Adds a warning unless an equal one (kind + message) exists.
  void add(
    ImportWarningKind kind,
    String message, {
    int? line,
    int? blockIndex,
  }) {
    if (_keys.add('${kind.name}|$message')) {
      _warnings.add(
        ImportWarning(kind, message, line: line, blockIndex: blockIndex),
      );
    }
  }

  /// Records that [feature] (e.g. "underline", "colors") was removed.
  void formattingRemoved(String feature, {int? blockIndex}) {
    _formatting.add(feature);
    _formattingBlock ??= blockIndex;
  }

  /// Whether a warning of [kind] was added.
  bool has(ImportWarningKind kind) => _warnings.any((w) => w.kind == kind);

  /// Adds [warning] (deduplicated).
  void addWarning(ImportWarning warning) => add(
    warning.kind,
    warning.message,
    line: warning.line,
    blockIndex: warning.blockIndex,
  );

  /// All warnings, the aggregated formatting warning last.
  List<ImportWarning> finish() => List.unmodifiable([
    ..._warnings,
    if (_formatting.isNotEmpty)
      ImportWarning(
        ImportWarningKind.formattingRemoved,
        'Formatting not supported in Markdown was removed '
        '(${_formatting.join(', ')}).',
        blockIndex: _formattingBlock,
      ),
  ]);
}

/// Collects images extracted during an import and assigns temp ids
/// (`import-image://img<n>`).
final class ImageCollector {
  final _images = <ImportedImage>[];
  final _byKey = <String, ImportedImage>{};

  /// The collected images.
  List<ImportedImage> get images => List.unmodifiable(_images);

  /// Adds an image; images with the same [key] (e.g. a package part name)
  /// are stored once.
  ImportedImage add(
    Uint8List bytes,
    String mime, {
    String alt = '',
    String? key,
  }) {
    if (key != null) {
      final existing = _byKey[key];
      if (existing != null) return existing;
    }
    final image = ImportedImage(
      tempId: 'img${_images.length + 1}',
      bytes: bytes,
      mime: mime,
      alt: alt,
    );
    _images.add(image);
    if (key != null) _byKey[key] = image;
    return image;
  }
}

/// Image type detection.
abstract final class ImageMime {
  /// Types that can be embedded as images.
  static const embeddable = {
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
  };

  /// Sniffs the MIME type from magic bytes; `null` when unknown.
  static String? sniff(Uint8List b) {
    bool at(int offset, List<int> sig) {
      if (b.length < offset + sig.length) return false;
      for (var i = 0; i < sig.length; i++) {
        if (b[offset + i] != sig[i]) return false;
      }
      return true;
    }

    if (at(0, const [0x89, 0x50, 0x4E, 0x47])) return 'image/png';
    if (at(0, const [0xFF, 0xD8, 0xFF])) return 'image/jpeg';
    if (at(0, const [0x47, 0x49, 0x46, 0x38])) return 'image/gif';
    if (at(0, const [0x52, 0x49, 0x46, 0x46]) &&
        at(8, const [0x57, 0x45, 0x42, 0x50])) {
      return 'image/webp';
    }
    if (at(0, const [0x42, 0x4D])) return 'image/bmp';
    if (at(0, const [0x49, 0x49, 0x2A, 0x00]) ||
        at(0, const [0x4D, 0x4D, 0x00, 0x2A])) {
      return 'image/tiff';
    }
    if (at(0, const [0x01, 0x00, 0x00, 0x00]) &&
        at(40, const [0x20, 0x45, 0x4D, 0x46])) {
      return 'image/emf';
    }
    if (at(0, const [0xD7, 0xCD, 0xC6, 0x9A]) ||
        at(0, const [0x01, 0x00, 0x09, 0x00]) ||
        at(0, const [0x02, 0x00, 0x09, 0x00])) {
      return 'image/wmf';
    }
    return null;
  }

  /// The MIME type for a file name extension; `null` when unknown.
  static String? fromFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0) return null;
    return switch (name.substring(dot + 1).toLowerCase()) {
      'png' => 'image/png',
      'jpg' || 'jpeg' || 'jpe' || 'jfif' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' || 'dib' => 'image/bmp',
      'tif' || 'tiff' => 'image/tiff',
      'emf' || 'emz' => 'image/emf',
      'wmf' || 'wmz' => 'image/wmf',
      'svg' => 'image/svg+xml',
      _ => null,
    };
  }

  /// Best guess: magic bytes first, then the file name.
  static String? detect(Uint8List bytes, {String? fileName}) =>
      sniff(bytes) ?? (fileName == null ? null : fromFileName(fileName));
}

/// Returns embeddable image bytes and MIME type for [bytes] of type [mime]:
/// PNG/JPEG/GIF/WebP are kept, TIFF and BMP are converted to PNG; anything
/// else (EMF, WMF, SVG, unknown) yields `null`.
(Uint8List, String)? embeddableImage(Uint8List bytes, String mime) {
  final m = mime.toLowerCase();
  if (ImageMime.embeddable.contains(m)) return (bytes, m);
  if (m == 'image/tiff' || m == 'image/bmp') {
    try {
      final decoded = m == 'image/tiff'
          ? img.decodeTiff(bytes)
          : img.decodeBmp(bytes);
      if (decoded == null) return null;
      return (img.encodePng(decoded), 'image/png');
    } on Object {
      return null;
    }
  }
  return null;
}

/// Text cleanup for imported text.
abstract final class ImportText {
  /// Cleans inline text: CR/LF/FF/VT → space, tab → 4 spaces, U+2029 →
  /// U+2028, other control characters, U+FFFC, U+FEFF and noncharacters
  /// removed, lone surrogates → U+FFFD.
  static String inline(String s) => _clean(s, code: false);

  /// Cleans one code line (tabs kept, soft breaks removed).
  static String codeLine(String s) => _clean(s, code: true);

  static String _clean(String s, {required bool code}) {
    StringBuffer? b;
    for (var i = 0; i < s.length; i++) {
      final u = s.codeUnitAt(i);
      String? rep;
      if (u >= 0xD800 && u <= 0xDBFF) {
        if (i + 1 < s.length) {
          final n = s.codeUnitAt(i + 1);
          if (n >= 0xDC00 && n <= 0xDFFF) {
            b?.writeCharCode(u);
            b?.writeCharCode(n);
            i++;
            continue;
          }
        }
        rep = '\uFFFD';
      } else if (u >= 0xDC00 && u <= 0xDFFF) {
        rep = '\uFFFD';
      } else if (u == 0x09) {
        rep = code ? null : '    ';
      } else if (u == 0x0A || u == 0x0D || u == 0x0B || u == 0x0C) {
        rep = ' ';
      } else if (u == 0x2028 || u == 0x2029) {
        rep = code ? '' : (u == 0x2029 ? importSoftBreak : null);
      } else if (u < 0x20 ||
          (u >= 0x7F && u <= 0x9F) ||
          u == 0xFFFC ||
          u == 0xFEFF ||
          u == 0xFFFE ||
          u == 0xFFFF) {
        rep = '';
      }
      if (rep != null) {
        b ??= StringBuffer(s.substring(0, i));
        b.write(rep);
      } else {
        b?.writeCharCode(u);
      }
    }
    return b?.toString() ?? s;
  }

  /// Sanitizes a code block language (`[A-Za-z0-9_+#.-]{0,32}`).
  static String language(String? raw) {
    if (raw == null) return '';
    final cleaned = raw.trim().replaceAll(RegExp(r'[^A-Za-z0-9_+#.\-]'), '');
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }
}

/// Monospace font detection (07 §3.6 "mono list").
abstract final class MonospaceFonts {
  static const _names = {
    'consolas',
    'menlo',
    'monaco',
    'lucida console',
    'lucida sans typewriter',
    'source code pro',
    'inconsolata',
    'andale mono',
    'fira code',
    'cascadia code',
    'hack',
    'ocr a extended',
    'ocr-a',
    'letter gothic',
    'pt mono',
    'sf mono',
    'iosevka',
    'monospace',
    'monospaced',
    'fixedsys',
    'terminal',
    'prestige elite',
    'anonymous pro',
    'droid sans mono',
  };

  /// Whether [family] (one font name or a CSS family list, whose first
  /// entry counts) is monospace.
  static bool isMonospace(String? family) {
    if (family == null) return false;
    var first = family.split(',').first.trim().toLowerCase();
    first = first.replaceAll(RegExp('''^["']|["']\$'''), '').trim();
    if (first.isEmpty) return false;
    return first.contains('mono') ||
        first.contains('courier') ||
        first.contains('typewriter') ||
        first.contains('code') && !first.contains('barcode') ||
        _names.contains(first);
  }

  /// Whether a CSS `font-family` list names a monospace font first (or
  /// only the generic `monospace`).
  static bool isMonospaceCss(String cssFamily) => isMonospace(cssFamily);
}

/// Task glyphs (☐ ☑ ☒ and a few look-alikes) at the start of a paragraph.
abstract final class TaskGlyphs {
  /// Unchecked glyphs.
  static const unchecked = {'☐', '□', '❏', '⬜'};

  /// Checked glyphs.
  static const checked = {'☑', '☒', '✅'};

  /// When [runs] start with a task glyph (after optional spaces), returns
  /// whether it is checked and the runs without the glyph and the following
  /// spaces; otherwise `null`.
  static (bool, List<InlineRun>)? strip(List<InlineRun> runs) {
    final merged = InlineRun.merge(runs);
    if (merged.isEmpty) return null;
    final text = InlineRun.plainText(merged);
    final trimmed = text.trimLeft();
    if (trimmed.isEmpty) return null;
    final glyph = String.fromCharCode(trimmed.runes.first);
    final bool isChecked;
    if (unchecked.contains(glyph)) {
      isChecked = false;
    } else if (checked.contains(glyph)) {
      isChecked = true;
    } else {
      return null;
    }
    var cut = text.length - trimmed.length + glyph.length;
    while (cut < text.length && (text[cut] == ' ' || text[cut] == '\u00A0')) {
      cut++;
    }
    return (isChecked, dropPrefix(merged, cut));
  }

  /// Removes the first [count] UTF-16 units of text from [runs].
  static List<InlineRun> dropPrefix(List<InlineRun> runs, int count) {
    final out = <InlineRun>[];
    var left = count;
    for (final r in runs) {
      if (left <= 0) {
        out.add(r);
      } else if (r.text.length <= left) {
        left -= r.text.length;
      } else {
        out.add(r.copyWith(text: r.text.substring(left)));
        left = 0;
      }
    }
    return out;
  }
}

/// Run list helpers.
abstract final class RunTools {
  /// Trims leading and trailing spaces (not soft breaks) of [runs].
  static List<InlineRun> trim(List<InlineRun> runs) {
    final merged = InlineRun.merge(runs);
    while (merged.isNotEmpty) {
      final t = merged.first.text.replaceFirst(RegExp(r'^[ \u00A0]+'), '');
      if (t.isEmpty) {
        merged.removeAt(0);
        continue;
      }
      merged[0] = merged.first.copyWith(text: t);
      break;
    }
    while (merged.isNotEmpty) {
      final t = merged.last.text.replaceFirst(RegExp(r'[ \u00A0]+$'), '');
      if (t.isEmpty) {
        merged.removeLast();
        continue;
      }
      merged[merged.length - 1] = merged.last.copyWith(text: t);
      break;
    }
    return merged;
  }

  /// Whether [runs] contain no visible text.
  static bool isBlank(List<InlineRun> runs) =>
      InlineRun.plainText(runs).trim().isEmpty;

  /// Soft breaks → spaces (for single-line contexts such as table cells).
  static List<InlineRun> singleLine(List<InlineRun> runs) => InlineRun.merge([
    for (final r in runs)
      r.text.contains(importSoftBreak)
          ? r.copyWith(text: r.text.replaceAll(importSoftBreak, ' '))
          : r,
  ]);

  /// Plain runs (formatting removed).
  static List<InlineRun> plain(List<InlineRun> runs) =>
      InlineRun.merge([for (final r in runs) InlineRun(r.text)]);

  /// Joins run lists with [separator] text.
  static List<InlineRun> join(
    Iterable<List<InlineRun>> parts,
    String separator,
  ) {
    final out = <InlineRun>[];
    var first = true;
    for (final p in parts) {
      if (p.isEmpty) continue;
      if (!first) out.add(InlineRun(separator));
      out.addAll(p);
      first = false;
    }
    return InlineRun.merge(out);
  }
}

/// Builds a [TableBlock] from cell runs: pads rows to the widest row, writes
/// single-line cells.
TableBlock buildTable(
  String id,
  List<List<List<InlineRun>>> rows,
  List<CellAlign?> align,
) {
  var columns = align.length;
  for (final r in rows) {
    if (r.length > columns) columns = r.length;
  }
  if (columns == 0) columns = 1;
  final paddedRows = <List<List<InlineRun>>>[
    for (final r in rows)
      [
        for (var c = 0; c < columns; c++)
          c < r.length ? RunTools.trim(RunTools.singleLine(r[c])) : const [],
      ],
  ];
  if (paddedRows.isEmpty) {
    paddedRows.add([for (var c = 0; c < columns; c++) []]);
  }
  final paddedAlign = [
    for (var c = 0; c < columns; c++) c < align.length ? align[c] : null,
  ];
  return TableBlock(id, paddedAlign, paddedRows);
}

/// The placeholder paragraph for an image that could not be imported.
ParagraphBlock imagePlaceholder(String alt, {String? detail}) {
  final a = ImportText.inline(alt).trim();
  final d = detail == null ? '' : ' ($detail)';
  return ParagraphBlock([InlineRun(a.isEmpty ? '[image$d]' : '[image: $a$d]')]);
}

/// Normalizes a BCP-47 language tag (`EN-us` → `en-US`, `en_gb` →
/// `en-GB`); `null` when [raw] is not a plausible tag.
String? normalizeLanguageTag(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  if (t.isEmpty) return null;
  final parts = t.split(RegExp('[-_]'));
  if (!RegExp(r'^[A-Za-z]{2,8}$').hasMatch(parts.first)) return null;
  if (parts.any((p) => !RegExp(r'^[A-Za-z0-9]{1,8}$').hasMatch(p))) {
    return null;
  }
  return [
    parts.first.toLowerCase(),
    for (final p in parts.skip(1))
      if (p.length == 2)
        p.toUpperCase()
      else if (p.length == 4)
        p[0].toUpperCase() + p.substring(1).toLowerCase()
      else
        p.toLowerCase(),
  ].join('-');
}

/// File name without directory and extension.
String? fileTitle(String? fileName) {
  if (fileName == null || fileName.isEmpty) return null;
  final base = fileName.split(RegExp(r'[/\\]')).last;
  final dot = base.lastIndexOf('.');
  final t = (dot > 0 ? base.substring(0, dot) : base).trim();
  return t.isEmpty ? null : t;
}

/// Converts the collected [blocks] into a validated [ImportResult].
///
/// The title is [title] when non-empty, else the first H1's text, else the
/// file name of [options].
ImportResult buildImportResult(
  List<DocBlock> blocks, {
  required ImportOptions options,
  required WarningCollector warnings,
  ImageCollector? images,
  String? title,
  String? language,
  ImportedPageSetup? pageSetup,
  String? frontMatter,
}) {
  final tree = DocTree(blocks);
  Delta delta = const DocTreeToDelta().convert(tree);
  final validation = const WonkyDeltaValidator(
    maxDocumentChars: 0x1FFFFFFFFFFFFF,
  ).validate(delta);
  if (!validation.isValid) {
    // Defensive: the normalizer guarantees validity; never return invalid
    // content.
    delta = Delta()..insert('\n');
    warnings.add(
      ImportWarningKind.contentDropped,
      'The document could not be converted.',
    );
  }
  String? h1;
  for (final b in blocks) {
    if (b is HeadingBlock && b.level == 1) {
      h1 = InlineRun.plainText(b.runs).replaceAll(importSoftBreak, ' ').trim();
      if (h1.isNotEmpty) break;
    }
  }
  final t = title?.trim();
  final resolvedTitle = (t != null && t.isNotEmpty)
      ? t
      : (h1 != null && h1.isNotEmpty ? h1 : fileTitle(options.fileName));
  final lang = language?.trim();
  return ImportResult(
    delta: delta,
    warnings: warnings.finish(),
    title: resolvedTitle,
    language: (lang == null || lang.isEmpty) ? null : lang,
    images: images?.images ?? const [],
    pageSetup: pageSetup,
    frontMatter: frontMatter,
  );
}

/// Numbers footnotes/endnotes in reference order and renders them as a final
/// "Notes" section (07 §3.6).
final class NotesCollector {
  final _notes = <List<InlineRun>>[];

  /// Whether any note was referenced.
  bool get isEmpty => _notes.isEmpty;

  /// Registers a note body and returns its 1-based number.
  int add(List<InlineRun> body) {
    _notes.add(body);
    return _notes.length;
  }

  /// The "Notes" heading and an ordered list with one item per note.
  List<DocBlock> blocks() => [
    if (_notes.isNotEmpty) const HeadingBlock(2, [InlineRun('Notes')]),
    for (final n in _notes) ListItemBlock(ListKindIr.ordered, 0, n),
  ];
}
