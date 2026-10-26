/// Shared helpers of the office-format exporters (DOCX, ODT, RTF, EPUB):
/// XML escaping, color and unit conversion, image preparation, header/footer
/// slot segmentation, syntax-highlighted code lines and heading labels
/// (07 §5.4–5.8, 06 §7.1).
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../highlight/syntax_highlighter.dart';
import '../../ir/doc_tree.dart';
import '../../layout/header_footer_tokens.dart';
import '../../markdown/front_matter.dart';
import '../../theme/model/syntax_token.dart';
import '../../theme/model/values.dart';
import '../../theme/numbering/heading_numberer.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../export_api.dart';

/// Escapes XML character data (`&`, `<`, `>`) and removes characters that
/// are not allowed in XML 1.0.
String xmlText(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final u = s.codeUnitAt(i);
    switch (u) {
      case 0x26:
        b.write('&amp;');
      case 0x3C:
        b.write('&lt;');
      case 0x3E:
        b.write('&gt;');
      default:
        if (u >= 0xD800 && u <= 0xDBFF) {
          if (i + 1 < s.length) {
            final n = s.codeUnitAt(i + 1);
            if (n >= 0xDC00 && n <= 0xDFFF) {
              b.writeCharCode(u);
              b.writeCharCode(n);
              i++;
              continue;
            }
          }
          b.write('�');
        } else if (u >= 0xDC00 && u <= 0xDFFF) {
          b.write('�');
        } else if (u < 0x20 && u != 0x09 && u != 0x0A && u != 0x0D) {
          // Not representable in XML 1.0.
        } else if (u == 0xFFFE || u == 0xFFFF) {
          // Noncharacters.
        } else {
          b.writeCharCode(u);
        }
    }
  }
  return b.toString();
}

/// Escapes an XML attribute value (double-quoted).
String xmlAttr(String s) => xmlText(
  s,
).replaceAll('"', '&quot;').replaceAll('\n', '&#10;').replaceAll('\t', '&#9;');

/// `RRGGBB` (upper case) of an ARGB color, alpha ignored.
String rgbHex(int argb) =>
    (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();

/// Blends [argb] over [background] by its alpha (office formats have no
/// transparency).
int flattenAlpha(int argb, {int background = 0xFFFFFFFF}) {
  final a = (argb >>> 24) / 255;
  if (a >= 1) return argb | 0xFF000000;
  int ch(int shift) {
    final f = (argb >> shift) & 0xFF;
    final bg = (background >> shift) & 0xFF;
    return (f * a + bg * (1 - a)).round().clamp(0, 255);
  }

  return 0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

/// Unit conversions.
abstract final class OfficeUnits {
  /// Twentieths of a point (twips).
  static int twips(double pt) => (pt * 20).round();

  /// Half points (`w:sz`, RTF `\fs`).
  static int halfPoints(double pt) => (pt * 2).round();

  /// English Metric Units (1 pt = 12700 EMU).
  static int emu(double pt) => (pt * 12700).round();

  /// Eighths of a point (`w:bdr w:sz`).
  static int eighths(double pt) => (pt * 8).round().clamp(2, 96);

  /// A length in pt for ODF/CSS (`12pt`), at most 3 decimals.
  static String pt(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    if (s == '-0') s = '0';
    return '${s}pt';
  }

  /// Image size in pt (96 dpi pixels).
  static double pxToPt(num px) => px * 0.75;
}

/// An image prepared for embedding: PNG or JPEG, ≤ 2400 px on the long
/// side (07 §4.4).
final class OfficeImage {
  /// Creates an image.
  const OfficeImage({
    required this.bytes,
    required this.mime,
    required this.widthPx,
    required this.heightPx,
  });

  /// Encoded bytes.
  final Uint8List bytes;

  /// `image/png` or `image/jpeg`.
  final String mime;

  /// Pixel width.
  final int widthPx;

  /// Pixel height.
  final int heightPx;

  /// `png` or `jpeg`.
  String get extension => mime == 'image/jpeg' ? 'jpeg' : 'png';

  /// Display size in pt that fits [maxWidthPt] × [maxHeightPt] keeping the
  /// aspect ratio (96 dpi intrinsic size, never upscaled).
  (double, double) fit(double maxWidthPt, double maxHeightPt) {
    var w = OfficeUnits.pxToPt(widthPx);
    var h = OfficeUnits.pxToPt(heightPx);
    if (w <= 0 || h <= 0) return (maxWidthPt, maxWidthPt / 2);
    final scale = math.min(1.0, math.min(maxWidthPt / w, maxHeightPt / h));
    w *= scale;
    h *= scale;
    return (w, h);
  }
}

/// Resolves and normalizes the images of [tree] (one entry per distinct
/// `src`; unavailable images add an `image_unavailable` warning and are
/// absent from the result).
Future<Map<String, OfficeImage>> resolveOfficeImages(
  ExportInput input,
  DocTree tree,
  List<ExportWarning> warnings, {
  int maxSide = 2400,
}) async {
  final out = <String, OfficeImage>{};
  final seen = <String>{};
  var index = 0;
  final total = tree.images.length;
  for (final im in tree.images) {
    index++;
    if (!seen.add(im.src)) continue;
    input.cancel?.throwIfCancelled();
    input.progress?.call(ExportPhase.images, total == 0 ? 1 : index / total);
    final r = await input.images.resolve(im.src);
    if (r == null) {
      warnings.add(
        ExportWarning(
          'image_unavailable',
          'Image "${im.alt}" could not be loaded',
        ),
      );
      continue;
    }
    final prepared = prepareOfficeImage(r, maxSide: maxSide);
    if (prepared == null) {
      warnings.add(
        ExportWarning(
          'image_unavailable',
          'Image "${im.alt}" has an unsupported format',
        ),
      );
      continue;
    }
    out[im.src] = prepared;
  }
  return out;
}

/// Converts [r] to PNG/JPEG within [maxSide] px; `null` when undecodable
/// (SVG and unknown formats).
OfficeImage? prepareOfficeImage(ResolvedImage r, {int maxSide = 2400}) {
  final mime = r.mime.toLowerCase();
  final isJpeg = mime == 'image/jpeg' || mime == 'image/jpg';
  final isPng = mime == 'image/png';
  if ((isJpeg || isPng) &&
      r.widthPx > 0 &&
      r.heightPx > 0 &&
      math.max(r.widthPx, r.heightPx) <= maxSide) {
    return OfficeImage(
      bytes: r.bytes,
      mime: isJpeg ? 'image/jpeg' : 'image/png',
      widthPx: r.widthPx,
      heightPx: r.heightPx,
    );
  }
  if (mime == 'image/svg+xml') return null;
  try {
    var decoded = img.decodeImage(r.bytes);
    if (decoded == null) return null;
    if (math.max(decoded.width, decoded.height) > maxSide) {
      decoded = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxSide)
          : img.copyResize(decoded, height: maxSide);
      if (isJpeg) {
        return OfficeImage(
          bytes: img.encodeJpg(decoded, quality: 90),
          mime: 'image/jpeg',
          widthPx: decoded.width,
          heightPx: decoded.height,
        );
      }
    } else if (isJpeg) {
      return OfficeImage(
        bytes: r.bytes,
        mime: 'image/jpeg',
        widthPx: decoded.width,
        heightPx: decoded.height,
      );
    }
    return OfficeImage(
      bytes: img.encodePng(decoded),
      mime: 'image/png',
      widthPx: decoded.width,
      heightPx: decoded.height,
    );
  } on Object {
    return null;
  }
}

/// A piece of a header/footer slot.
sealed class SlotPart {
  const SlotPart();
}

/// Literal text (tokens other than page numbers already expanded).
final class SlotText extends SlotPart {
  /// Creates a text part.
  const SlotText(this.text);

  /// The text.
  final String text;

  @override
  bool operator ==(Object other) => other is SlotText && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'SlotText($text)';
}

/// A page-number field (`{page}` or `{pages}`), rendered by the target
/// application.
final class SlotField extends SlotPart {
  /// Creates a field part.
  const SlotField({required this.pageCount});

  /// `{pages}` (total) instead of `{page}`.
  final bool pageCount;

  @override
  bool operator ==(Object other) =>
      other is SlotField && other.pageCount == pageCount;

  @override
  int get hashCode => pageCount.hashCode;

  @override
  String toString() => pageCount ? 'SlotField(pages)' : 'SlotField(page)';
}

/// Header/footer slot rendering for formats with page-number fields.
abstract final class HeaderFooterSlots {
  static final _fieldToken = RegExp(r'\{\{|\}\}|\{(page|pages)\}');

  /// The token context of [input] (dates, title, author).
  static TokenContext context(ExportInput input) => TokenContext(
    title: input.meta.title ?? '',
    author:
        input.meta.authorName ??
        FrontMatter.field(input.meta.frontMatter, 'author') ??
        '',
    now: input.now,
    modified: input.meta.modifiedAt,
    locale: input.locale,
    pageNumberStart: input.pageSetup.pageNumberStart,
    pageNumberFormat: input.pageSetup.pageNumberFormat,
  );

  /// Splits [template] into text and page-number fields; all other tokens
  /// are expanded with [ctx] (`{{`/`}}` stay literal braces).
  static List<SlotPart> parts(String template, TokenContext ctx) {
    final out = <SlotPart>[];
    var pos = 0;
    void text(String t) {
      if (t.isEmpty) return;
      final expanded = HeaderFooterTokens.expand(t, ctx);
      if (expanded.isEmpty) return;
      if (out.isNotEmpty && out.last is SlotText) {
        out[out.length - 1] = SlotText((out.last as SlotText).text + expanded);
      } else {
        out.add(SlotText(expanded));
      }
    }

    for (final m in _fieldToken.allMatches(template)) {
      final all = m.group(0)!;
      if (all == '{{' || all == '}}') {
        // Keep doubled braces for the token expander.
        continue;
      }
      text(template.substring(pos, m.start));
      out.add(SlotField(pageCount: m.group(1) == 'pages'));
      pos = m.end;
    }
    text(template.substring(pos));
    return out;
  }
}

/// One highlighted piece of a code line.
typedef CodePiece = ({String text, SyntaxToken? token});

/// Splits [text] into lines of syntax-highlighted pieces (empty lines are
/// empty lists).
List<List<CodePiece>> highlightedCodeLines(String text, String language) {
  final spans = SyntaxHighlighter.instance.tokenize(text, language);
  final tokens = List<SyntaxToken?>.filled(text.length, null);
  for (final s in spans) {
    for (var i = s.start; i < s.end && i < text.length; i++) {
      tokens[i] = s.token;
    }
  }
  final lines = <List<CodePiece>>[[]];
  final buf = StringBuffer();
  SyntaxToken? current;
  void flush() {
    if (buf.isEmpty) return;
    lines.last.add((text: buf.toString(), token: current));
    buf.clear();
  }

  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '\n') {
      flush();
      lines.add([]);
      current = null;
      continue;
    }
    if (tokens[i] != current) {
      flush();
      current = tokens[i];
    }
    buf.write(c);
  }
  flush();
  return lines;
}

/// Heading number labels for [tree] (`null` entries for unnumbered
/// headings), by block index.
Map<int, String> headingLabels(DocTree tree, ResolvedWriteTheme theme) {
  final out = <int, String>{};
  if (!theme.headingNumbering.enabled) return out;
  final numberer = HeadingNumberer(theme.headingNumbering);
  for (var i = 0; i < tree.blocks.length; i++) {
    final b = tree.blocks[i];
    if (b is HeadingBlock) {
      final label = numberer.next(b.level);
      if (label != null) out[i] = label;
    }
  }
  return out;
}

/// Applies a theme case transform to [text] for formats without a native
/// equivalent.
String applyCase(String text, CaseTransform transform) => switch (transform) {
  CaseTransform.uppercase => text.toUpperCase(),
  CaseTransform.lowercase => text.toLowerCase(),
  CaseTransform.capitalize => text.replaceAllMapped(
    RegExp(r'(^|[\s ])(\S)'),
    (m) => '${m.group(1)}${m.group(2)!.toUpperCase()}',
  ),
  CaseTransform.none || CaseTransform.smallCaps => text,
};

/// The page content width in pt of [input] for [theme] margins.
double contentWidthPt(ExportInput input, ResolvedWriteTheme theme) {
  final m = input.pageSetup.margins;
  final left = m?.left ?? theme.page.defaultMargins.left;
  final right = m?.right ?? theme.page.defaultMargins.right;
  return math.max(72, input.pageSetup.pageWidthPt - left - right);
}

/// The page content height in pt of [input] for [theme] margins.
double contentHeightPt(ExportInput input, ResolvedWriteTheme theme) {
  final m = input.pageSetup.margins;
  final top = m?.top ?? theme.page.defaultMargins.top;
  final bottom = m?.bottom ?? theme.page.defaultMargins.bottom;
  return math.max(72, input.pageSetup.pageHeightPt - top - bottom);
}

/// Page margins of [input] (page setup, else theme defaults).
EdgesPt pageMarginsPt(ExportInput input, ResolvedWriteTheme theme) {
  final m = input.pageSetup.margins;
  if (m == null) return theme.page.defaultMargins;
  return EdgesPt(top: m.top, right: m.right, bottom: m.bottom, left: m.left);
}

/// Deterministic ISO-8601 timestamp (seconds, UTC) of the document's
/// modification time ([DeterministicZip.defaultTime] when unknown).
String isoTimestamp(DateTime? t) {
  final u = (t ?? DateTime.utc(2000)).toUtc();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${u.year.toString().padLeft(4, '0')}-${two(u.month)}-${two(u.day)}'
      'T${two(u.hour)}:${two(u.minute)}:${two(u.second)}Z';
}

/// The author of an export (`meta.authorName`, else front matter `author`).
String? exportAuthor(ExportInput input) =>
    input.meta.authorName ??
    FrontMatter.field(input.meta.frontMatter, 'author');

/// Text of [runs] with soft breaks as spaces (titles, TOC entries).
String runsPlainText(List<InlineRun> runs) =>
    InlineRun.plainText(runs).replaceAll(' ', ' ').trim();

/// Describes encoded raster image [bytes] for an [ImageResolver]: sniffs
/// the type and reads the size from the header (no full decode). `null`
/// when the bytes are not a PNG, JPEG, GIF, WebP or BMP image.
ResolvedImage? describeExportImage(Uint8List bytes) {
  final decoder = img.findDecoderForData(bytes);
  if (decoder == null) return null;
  final info = decoder.startDecode(bytes);
  if (info == null || info.width <= 0 || info.height <= 0) return null;
  final String mime;
  switch (decoder) {
    case img.PngDecoder():
      mime = 'image/png';
    case img.JpegDecoder():
      mime = 'image/jpeg';
    case img.GifDecoder():
      mime = 'image/gif';
    case img.WebPDecoder():
      mime = 'image/webp';
    case img.BmpDecoder():
      mime = 'image/bmp';
    default:
      return null;
  }
  return ResolvedImage(
    bytes: bytes,
    mime: mime,
    widthPx: info.width,
    heightPx: info.height,
  );
}
