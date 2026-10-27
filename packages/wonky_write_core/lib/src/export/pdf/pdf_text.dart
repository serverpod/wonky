/// Fonts and line layout for the PDF exporter.
library;

import 'dart:typed_data';

import 'package:pdf/pdf.dart';

import '../../delta/delta_utils.dart';
import 'package:wonky_fonts/wonky_fonts.dart';
import '../../theme/model/values.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../export_api.dart';

/// Loads and caches PDF fonts for theme families; falls back to the standard
/// 14 fonts when a family is unavailable and picks fallback faces per
/// character for glyph coverage.
final class PdfFontBook {
  /// Creates a font book for [document].
  PdfFontBook(this.document, this.provider, this.warnings);

  /// The PDF document.
  final PdfDocument document;

  /// Font provider.
  final FontProvider provider;

  /// Shared warnings.
  final List<ExportWarning> warnings;

  final _faces = <String, PdfFont>{};
  final _standard = <String, PdfFont>{};
  final _fallbacks = <PdfFont>[];
  final _warned = <String>{};

  static String _key(String family, int weight, bool italic) =>
      '$family|${weight >= 600 ? 700 : 400}|$italic';

  /// Preloads the faces needed for [requests] and fallback faces for [text].
  Future<void> preload(
    Iterable<(String, int, bool)> requests,
    String text,
  ) async {
    for (final (family, weight, italic) in requests) {
      final key = _key(family, weight, italic);
      if (_faces.containsKey(key)) continue;
      try {
        final face = await provider.load(
          family,
          weight: weight,
          italic: italic,
        );
        _faces[key] = PdfTtfFont(document, ByteData.sublistView(face.bytes));
      } on FontUnavailableException {
        if (_warned.add(family)) {
          warnings.add(
            ExportWarning(
              'font_fallback',
              'Font "$family" is not available; a standard PDF font was used',
            ),
          );
        }
      } on Object {
        if (_warned.add(family)) {
          warnings.add(
            ExportWarning(
              'font_fallback',
              'Font "$family" could not be loaded; a standard PDF font was used',
            ),
          );
        }
      }
    }
    try {
      for (final f in await provider.fallbacksFor(text)) {
        _fallbacks.add(PdfTtfFont(document, ByteData.sublistView(f.bytes)));
      }
    } on Object {
      // No fallbacks available.
    }
  }

  /// The font for a family/weight/style ([mono] picks Courier as the
  /// standard fallback, serif-looking families Times, others Helvetica).
  PdfFont font(String family, int weight, bool italic, {bool mono = false}) {
    final f = _faces[_key(family, weight, italic)];
    if (f != null) return f;
    final bold = weight >= 600;
    final serif = RegExp(
      r'Serif|Garamond|Baskerville|Lora|Merriweather|Crimson|Literata|Playfair|Times',
    ).hasMatch(family);
    final kind = mono ? 'courier' : (serif ? 'times' : 'helvetica');
    final key = '$kind|$bold|$italic';
    return _standard.putIfAbsent(key, () {
      return switch ((kind, bold, italic)) {
        ('courier', false, false) => PdfFont.courier(document),
        ('courier', true, false) => PdfFont.courierBold(document),
        ('courier', false, true) => PdfFont.courierOblique(document),
        ('courier', true, true) => PdfFont.courierBoldOblique(document),
        ('times', false, false) => PdfFont.times(document),
        ('times', true, false) => PdfFont.timesBold(document),
        ('times', false, true) => PdfFont.timesItalic(document),
        ('times', true, true) => PdfFont.timesBoldItalic(document),
        (_, false, false) => PdfFont.helvetica(document),
        (_, true, false) => PdfFont.helveticaBold(document),
        (_, false, true) => PdfFont.helveticaOblique(document),
        _ => PdfFont.helveticaBoldOblique(document),
      };
    });
  }

  /// Whether [rune] can be drawn with [primary] or a fallback face.
  bool supports(int rune, PdfFont primary) =>
      primary.isRuneSupported(rune) ||
      _fallbacks.any((f) => f.isRuneSupported(rune));

  /// Splits [text] into segments renderable with [primary] or a fallback;
  /// unsupported characters become `?` (with a warning).
  List<(String, PdfFont)> segments(String text, PdfFont primary) {
    final out = <(String, PdfFont)>[];
    final b = StringBuffer();
    PdfFont? current;
    void flush() {
      if (b.isNotEmpty) out.add((b.toString(), current!));
      b.clear();
    }

    for (final rune in text.runes) {
      var font = primary;
      var ch = String.fromCharCode(rune);
      if (!primary.isRuneSupported(rune)) {
        final fb = _fallbacks.where((f) => f.isRuneSupported(rune)).firstOrNull;
        if (fb != null) {
          font = fb;
        } else {
          if (_warned.add('glyph')) {
            warnings.add(
              const ExportWarning(
                'missing_glyphs',
                'Some characters are not covered by the available fonts',
              ),
            );
          }
          ch = primary.isRuneSupported(0x3F) ? '?' : ' ';
        }
      }
      if (current != null && !identical(current, font)) flush();
      current = font;
      b.write(ch);
    }
    flush();
    return out;
  }
}

/// A text style for layout.
final class PdfRunStyle {
  /// Creates a style.
  const PdfRunStyle({
    required this.font,
    required this.size,
    required this.color,
    this.letterSpacing = 0,
    this.underline = false,
    this.strike = false,
    this.decorationColor,
    this.decorationThickness = 0.75,
    this.background,
    this.backgroundPadX = 0,
    this.backgroundRadius = 0,
    this.link,
  });

  /// Font.
  final PdfFont font;

  /// Size in pt.
  final double size;

  /// ARGB color.
  final int color;

  /// Letter spacing in pt.
  final double letterSpacing;

  /// Underline.
  final bool underline;

  /// Strikethrough.
  final bool strike;

  /// Decoration color (default: [color]).
  final int? decorationColor;

  /// Decoration thickness.
  final double decorationThickness;

  /// Background (inline code / mention chips).
  final int? background;

  /// Horizontal background padding.
  final double backgroundPadX;

  /// Background corner radius.
  final double backgroundRadius;

  /// Link target.
  final String? link;

  /// Copy with another font/color/size.
  PdfRunStyle copyWith({PdfFont? font, int? color, double? size}) =>
      PdfRunStyle(
        font: font ?? this.font,
        size: size ?? this.size,
        color: color ?? this.color,
        letterSpacing: letterSpacing,
        underline: underline,
        strike: strike,
        decorationColor: decorationColor,
        decorationThickness: decorationThickness,
        background: background,
        backgroundPadX: backgroundPadX,
        backgroundRadius: backgroundRadius,
        link: link,
      );
}

/// A positioned piece of a line.
final class PdfPiece {
  /// Creates a piece.
  PdfPiece(this.text, this.style, this.width, {this.isSpace = false});

  /// Text (one font).
  final String text;

  /// Style.
  final PdfRunStyle style;

  /// Width in pt.
  final double width;

  /// Whether this is inter-word space (stretchable when justifying).
  final bool isSpace;

  /// X offset from the line start (set by layout).
  double x = 0;
}

/// A laid-out line.
final class PdfLine {
  /// Creates a line.
  PdfLine(
    this.pieces, {
    required this.height,
    required this.ascent,
    required this.width,
  });

  /// Pieces.
  final List<PdfPiece> pieces;

  /// Line height (pt).
  final double height;

  /// Distance from the line top to the baseline.
  final double ascent;

  /// Natural width.
  final double width;
}

/// Greedy line breaking with font fallback, hard breaks (U+2028), code mode
/// (preserved spaces, character wrapping with a continuation marker) and
/// alignment/justification.
final class PdfLineBreaker {
  /// Creates a breaker.
  const PdfLineBreaker(this.fonts);

  /// Font book.
  final PdfFontBook fonts;

  static double _raw(String text, PdfRunStyle s) {
    if (text.isEmpty) return 0;
    final m = s.font.stringMetrics(
      text,
      letterSpacing: s.letterSpacing / s.size,
    );
    return m.advanceWidth * s.size;
  }

  /// Width of [text] in [s], using fallback fonts / replacements for
  /// unsupported characters.
  double measure(String text, PdfRunStyle s) {
    var w = 0.0;
    for (final (seg, font) in fonts.segments(text, s.font)) {
      w += _raw(seg, identical(font, s.font) ? s : s.copyWith(font: font));
    }
    return w;
  }

  /// Lays out [runs] into lines of at most [maxWidth].
  List<PdfLine> layout(
    List<(String, PdfRunStyle)> runs,
    double maxWidth, {
    required double lineHeight,
    required PdfRunStyle baseStyle,
    ThemeAlign align = ThemeAlign.left,
    bool code = false,
    String? continuationMarker,
    double firstLineIndent = 0,
  }) {
    final width = maxWidth <= 1 ? 1.0 : maxWidth;
    // Tokens: (segments, isSpace, isBreak); a word is one segment per run
    // it spans. In code, a word continues across runs (syntax tokens), so
    // long lines wrap at the same places whatever the highlighting (SL-35);
    // elsewhere every run starts a new word, as before.
    final tokens = <(List<(String, PdfRunStyle)>, bool, bool)>[];
    var joinable = false;
    for (final (text, style) in runs) {
      final parts = text.split(softBreak);
      for (var p = 0; p < parts.length; p++) {
        if (p > 0) {
          tokens.add((const [], false, true));
          joinable = false;
        }
        for (final m in RegExp(r'\s+|[^\s]+').allMatches(parts[p])) {
          final t = m.group(0)!;
          final isSpace = t.trim().isEmpty;
          if (code && !isSpace && joinable && m.start == 0) {
            tokens.last.$1.add((t, style));
          } else {
            tokens.add(([(t, style)], isSpace, false));
          }
          joinable = !isSpace && m.end == parts[p].length;
        }
      }
    }
    final lines = <PdfLine>[];
    var current = <PdfPiece>[];
    var x = 0.0;

    void finish({required bool last}) {
      // Trim trailing spaces (not in code).
      if (!code) {
        while (current.isNotEmpty && current.last.isSpace) {
          x -= current.removeLast().width;
        }
      }
      var maxSize = baseStyle.size;
      var ascent = baseStyle.font.ascent * baseStyle.size;
      for (final p in current) {
        if (p.style.size > maxSize) maxSize = p.style.size;
        final a = p.style.font.ascent * p.style.size;
        if (a > ascent) ascent = a;
      }
      final h = maxSize * lineHeight;
      final descentBase = -baseStyle.font.descent * maxSize;
      final glyphH = ascent + (descentBase < 0 ? 0 : descentBase);
      final top = (h - glyphH) / 2;
      final indent = lines.isEmpty ? firstLineIndent : 0.0;
      final free = width - indent - x;
      var offset = indent;
      if (align == ThemeAlign.center) offset += free / 2;
      if (align == ThemeAlign.right) offset += free;
      final spaces = current.where((p) => p.isSpace).length;
      final justify =
          align == ThemeAlign.justify && !last && spaces > 0 && free > 0;
      var px = offset;
      for (final p in current) {
        p.x = px;
        px += p.width + (justify && p.isSpace ? free / spaces : 0);
      }
      lines.add(
        PdfLine(List.of(current), height: h, ascent: top + ascent, width: x),
      );
      current = [];
      x = 0;
    }

    void addPieces(String text, PdfRunStyle style, bool isSpace) {
      for (final (seg, font) in fonts.segments(text, style.font)) {
        final s = identical(font, style.font)
            ? style
            : style.copyWith(font: font);
        final w = _raw(seg, s);
        current.add(PdfPiece(seg, s, w, isSpace: isSpace));
        x += w;
      }
    }

    for (final (segments, isSpace, isBreak) in tokens) {
      if (isBreak) {
        finish(last: true);
        continue;
      }
      if (isSpace) {
        final (text, style) = segments.single;
        if (current.isEmpty && !code && lines.isNotEmpty) continue;
        final w = measure(text, style);
        if (x + w > width && code) {
          // Wrap long whitespace runs in code.
          finish(last: false);
          if (continuationMarker != null) {
            addPieces(
              '$continuationMarker ',
              style.copyWith(color: baseStyle.color),
              false,
            );
          }
        }
        addPieces(text, style, true);
        continue;
      }
      final style = segments.first.$2;
      var w = 0.0;
      for (final (text, s) in segments) {
        w += measure(text, s);
      }
      final indent = lines.isEmpty ? firstLineIndent : 0.0;
      if (x + w <= width - indent || current.isEmpty && w <= width - indent) {
        if (x + w > width - indent) finish(last: false);
        for (final (text, s) in segments) {
          addPieces(text, s, false);
        }
        continue;
      }
      if (current.isNotEmpty && w <= width) {
        finish(last: false);
        if (code && continuationMarker != null) {
          addPieces('$continuationMarker ', style, false);
        }
        for (final (text, s) in segments) {
          addPieces(text, s, false);
        }
        continue;
      }
      // Break the word by characters.
      for (final (text, style) in segments) {
        var chunk = StringBuffer();
        for (final rune in text.runes) {
          final ch = String.fromCharCode(rune);
          final cw = measure('$chunk$ch', style);
          if (x + cw > width && (chunk.isNotEmpty || current.isNotEmpty)) {
            if (chunk.isNotEmpty) addPieces(chunk.toString(), style, false);
            finish(last: false);
            if (code && continuationMarker != null) {
              addPieces('$continuationMarker ', style, false);
            }
            chunk = StringBuffer(ch);
          } else {
            chunk.write(ch);
          }
        }
        if (chunk.isNotEmpty) addPieces(chunk.toString(), style, false);
      }
    }
    finish(last: true);
    return lines;
  }
}

/// Builds run styles from resolved theme styles.
final class PdfStyler {
  /// Creates a styler.
  const PdfStyler(this.fonts);

  /// Font book.
  final PdfFontBook fonts;

  /// A run style for a text style.
  PdfRunStyle text(
    ResolvedTextStyle s, {
    bool mono = false,
    int? weight,
    bool? italic,
    int? color,
  }) => PdfRunStyle(
    font: fonts.font(
      s.fontFamily,
      weight ?? s.fontWeight,
      italic ?? s.italic,
      mono: mono,
    ),
    size: s.fontSize,
    color: color ?? s.color,
    letterSpacing: s.letterSpacing,
  );
}

/// Applies a case transform to displayed text.
String applyCase(String text, CaseTransform t) => switch (t) {
  CaseTransform.uppercase || CaseTransform.smallCaps => text.toUpperCase(),
  CaseTransform.lowercase => text.toLowerCase(),
  CaseTransform.capitalize => text.replaceAllMapped(
    RegExp(r'(^|\s)(\p{Ll})', unicode: true),
    (m) => '${m[1]}${m[2]!.toUpperCase()}',
  ),
  CaseTransform.none => text,
};
