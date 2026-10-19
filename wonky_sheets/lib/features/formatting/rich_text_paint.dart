import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';
import 'package:wonky_sheets_core/model.dart';

import '../../theme/sheets_tokens.dart';
import '../grid/paint/text_layout_cache.dart';
import 'cell_fonts.dart';

/// Lays out cell text with rich runs (06 §11, 03 §8.8): the cell's [base]
/// style for text outside runs, run attributes inside them. Conditional
/// formatting attributes win over runs (precedence CF > run > cell), so keys
/// set by the CF overlay are ignored in runs.
class RichTextLayoutCache {
  RichTextLayoutCache({this.capacity = 2000});

  final int capacity;
  final LinkedHashMap<Object, ui.Paragraph> _map = LinkedHashMap();

  /// The paragraph of [rich]. [pxPerPoint] converts run font sizes (pt) to
  /// px at the current zoom; [linkColor] colors link runs without a color.
  /// [theme] is the theme [resolveColor] resolves `theme:*` run colors
  /// with: part of the key, so a theme change or preview never reuses a
  /// paragraph colored with another theme (S-09).
  ui.Paragraph layout(
    RichText rich,
    GridTextStyle base, {
    required double pxPerPoint,
    required Color linkColor,
    required String? Function(String? color) resolveColor,
    SpreadsheetTheme? theme,
    CellFormat? conditional,
    double? wrapWidth,
    Color? chipText,
  }) {
    final key = (
      rich,
      theme,
      base,
      pxPerPoint,
      linkColor,
      conditional,
      wrapWidth,
      chipText,
    );
    final hit = _map.remove(key);
    if (hit != null) {
      _map[key] = hit;
      return hit;
    }
    final p = _build(
      rich,
      base,
      pxPerPoint,
      linkColor,
      resolveColor,
      conditional,
      wrapWidth,
      chipText,
    );
    _map[key] = p;
    if (_map.length > capacity) _map.remove(_map.keys.first)?.dispose();
    return p;
  }

  static ui.TextStyle _style(
    GridTextStyle base, {
    Map<String, Object?> run = const {},
    required double pxPerPoint,
    required Color linkColor,
    required String? Function(String? color) resolveColor,
    CellFormat? conditional,
  }) {
    bool cf(FormatAttr a) => conditional?.has(a) ?? false;
    final link = run[RichRunKeys.link] is String;
    final bold = !cf(FormatAttr.bold) && run[RichRunKeys.bold] is bool
        ? run[RichRunKeys.bold]! as bool
        : base.bold;
    final italic = !cf(FormatAttr.italic) && run[RichRunKeys.italic] is bool
        ? run[RichRunKeys.italic]! as bool
        : base.italic;
    var underline =
        !cf(FormatAttr.underline) && run[RichRunKeys.underline] is bool
        ? run[RichRunKeys.underline]! as bool
        : base.underline;
    if (link && run[RichRunKeys.underline] == null) underline = true;
    final strike =
        !cf(FormatAttr.strikethrough) && run[RichRunKeys.strikethrough] is bool
        ? run[RichRunKeys.strikethrough]! as bool
        : base.strikethrough;
    var color = base.color;
    if (!cf(FormatAttr.textColor)) {
      final c = hexToColor(resolveColor(run[RichRunKeys.textColor] as String?));
      if (c != null) {
        color = c;
      } else if (link) {
        color = linkColor;
      }
    }
    final family = run[RichRunKeys.fontFamily] is String
        ? CellFonts.screenFamily(run[RichRunKeys.fontFamily]! as String)
        : base.fontFamily;
    final size = run[RichRunKeys.fontSize] is num
        ? (run[RichRunKeys.fontSize]! as num).toDouble() * pxPerPoint
        : base.fontSize;
    final decorations = <TextDecoration>[
      if (underline) TextDecoration.underline,
      if (strike) TextDecoration.lineThrough,
    ];
    return ui.TextStyle(
      color: color,
      fontFamily: family,
      fontFamilyFallback: CellFonts.fallback,
      fontSize: size,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      decoration: decorations.isEmpty
          ? null
          : TextDecoration.combine(decorations),
      decorationColor: color,
      height: 1.2,
    );
  }

  static ui.Paragraph _build(
    RichText rich,
    GridTextStyle base,
    double pxPerPoint,
    Color linkColor,
    String? Function(String?) resolveColor,
    CellFormat? conditional,
    double? wrapWidth,
    Color? chipText,
  ) {
    final b = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: base.align,
        fontFamily: base.fontFamily,
        fontSize: base.fontSize,
        height: 1.2,
      ),
    );
    ui.TextStyle style([Map<String, Object?> run = const {}]) => _style(
      base,
      run: run,
      pxPerPoint: pxPerPoint,
      linkColor: linkColor,
      resolveColor: resolveColor,
      conditional: conditional,
    );
    final text = rich.text;
    final runs = [...rich.runs]..sort((a, b) => a.start.compareTo(b.start));
    final chips = <RichChipSpan>[];
    // Paragraph offsets: every placeholder adds one character.
    var at = 0;
    var placeholders = 0;
    void plain(String t, [Map<String, Object?> run = const {}]) {
      b
        ..pushStyle(style(run))
        ..addText(t);
      b.pop();
      at += t.length;
    }

    var pos = 0;
    for (final r in runs) {
      final s = r.start.clamp(pos, text.length);
      final e = r.end.clamp(s, text.length);
      if (s > pos) plain(text.substring(pos, s));
      final chip = e > s ? RichChipSpan.chipOf(r.format) : null;
      if (chip != null) {
        // Smart chips (03 §14.3) are laid out with the text: a leading
        // placeholder for the avatar/icon, the label in the chip text color
        // (no link styling) and end padding; the pill and the avatar are
        // painted around the paragraph ([paintRichChipsBehind],
        // [paintRichChipsFront]).
        final size = base.fontSize;
        final label = text.substring(s, e);
        final start = at;
        b.addPlaceholder(
          size * RichChipSpan.leadFactor,
          size,
          ui.PlaceholderAlignment.middle,
        );
        at++;
        placeholders++;
        final chipBase = GridTextStyle(
          fontFamily: base.fontFamily,
          fontSize: base.fontSize,
          color: chipText ?? base.color,
          bold: base.bold,
          italic: base.italic,
          align: base.align,
        );
        b
          ..pushStyle(
            _style(
              chipBase,
              run: {
                for (final MapEntry(:key, :value) in r.format.entries)
                  if (key != RichRunKeys.link &&
                      key != RichRunKeys.textColor &&
                      key != RichRunKeys.underline)
                    key: value,
              },
              pxPerPoint: pxPerPoint,
              linkColor: chipBase.color,
              resolveColor: resolveColor,
              conditional: conditional,
            ),
          )
          ..addText(label);
        b.pop();
        at += label.length;
        b.addPlaceholder(
          size * RichChipSpan.endFactor,
          size * 0.5,
          ui.PlaceholderAlignment.middle,
        );
        at++;
        placeholders++;
        chips.add(
          RichChipSpan(
            kind: chip.$1,
            seed: chip.$2,
            label: label,
            start: start,
            end: at,
            leadPlaceholder: placeholders - 2,
          ),
        );
      } else if (e > s) {
        plain(text.substring(s, e), r.format);
      }
      pos = e;
    }
    if (pos < text.length) plain(text.substring(pos));
    final p = b.build();
    p.layout(ui.ParagraphConstraints(width: wrapWidth ?? double.infinity));
    if (wrapWidth == null) {
      p.layout(ui.ParagraphConstraints(width: p.maxIntrinsicWidth + 0.5));
    }
    if (chips.isNotEmpty) RichChipSpan._spans[p] = chips;
    return p;
  }

  void clear() {
    for (final p in _map.values) {
      p.dispose();
    }
    _map.clear();
  }
}

/// The shared rich-text layout cache of the grid painters.
final RichTextLayoutCache richTextLayouts = RichTextLayoutCache();

/// A smart chip run laid out in a rich paragraph (03 §14.3): paragraph
/// offsets [start]..[end] (placeholders included) and what to draw.
@immutable
class RichChipSpan {
  const RichChipSpan({
    required this.kind,
    required this.seed,
    required this.label,
    required this.start,
    required this.end,
    required this.leadPlaceholder,
  });

  /// `person`, `file` (or another kind: a plain pill).
  final String kind;

  /// Avatar color seed (person e-mail) or file kind (`document`,
  /// `spreadsheet`, `folder`).
  final String seed;
  final String label;
  final int start;
  final int end;

  /// Index of the leading placeholder among the paragraph's placeholders.
  final int leadPlaceholder;

  /// Leading placeholder width (avatar + gaps) in font sizes.
  static const leadFactor = 1.45;

  /// End padding in font sizes.
  static const endFactor = 0.45;

  static final Expando<List<RichChipSpan>> _spans = Expando('richChips');

  /// The chips of a paragraph built by [RichTextLayoutCache].
  static List<RichChipSpan> of(ui.Paragraph p) => _spans[p] ?? const [];

  /// `(kind, seed)` of a run's `chip` attribute, or null.
  static (String, String)? chipOf(Map<String, Object?> format) {
    final chip = format[RichRunKeys.chip];
    if (chip is! Map) return null;
    final kind = chip['kind'];
    if (kind is! String) return null;
    final seed = switch (kind) {
      'person' => chip['email'],
      'file' => chip['itemKind'],
      _ => null,
    };
    return (kind, seed is String ? seed : '');
  }
}

/// Avatar colors of person chips (by e-mail hash).
const chipAvatarColors = [
  Color(0xFF1A73E8),
  Color(0xFF188038),
  Color(0xFFC5221F),
  Color(0xFFE37400),
  Color(0xFF9334E6),
  Color(0xFF007B83),
  Color(0xFFB80672),
  Color(0xFF5F6368),
];

/// The avatar color of a person chip with [email].
Color chipAvatarColor(String email) =>
    chipAvatarColors[email.hashCode.abs() % chipAvatarColors.length];

/// Paints the pills of the smart chips of [p] (drawn at [offset]) in [bg],
/// before the paragraph itself.
void paintRichChipsBehind(
  Canvas canvas,
  ui.Paragraph p,
  Offset offset,
  Color bg,
) {
  final spans = RichChipSpan.of(p);
  if (spans.isEmpty) return;
  final paint = Paint()..color = bg;
  for (final c in spans) {
    final boxes = p.getBoxesForRange(c.start, c.end);
    // One pill per line the chip spans.
    final lines = <double, Rect>{};
    for (final box in boxes) {
      final r = box.toRect();
      final key = (r.center.dy * 2).roundToDouble();
      lines[key] = lines[key]?.expandToInclude(r) ?? r;
    }
    for (final r in lines.values) {
      final pill = r.shift(offset).inflate(0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(pill, Radius.circular(pill.height / 2)),
        paint,
      );
    }
  }
}

/// Paints the avatars/icons of the smart chips of [p] (drawn at [offset]),
/// after the paragraph.
void paintRichChipsFront(Canvas canvas, ui.Paragraph p, Offset offset) {
  final spans = RichChipSpan.of(p);
  if (spans.isEmpty) return;
  final boxes = p.getBoxesForPlaceholders();
  for (final c in spans) {
    if (c.leadPlaceholder >= boxes.length) continue;
    final box = boxes[c.leadPlaceholder].toRect().shift(offset);
    final d = box.height * 0.82;
    final center = Offset(box.left + box.height * 0.18 + d / 2, box.center.dy);
    switch (c.kind) {
      case 'person':
        canvas.drawCircle(
          center,
          d / 2,
          Paint()..color = chipAvatarColor(c.seed),
        );
        final initial = c.label.isEmpty
            ? '?'
            : String.fromCharCode(c.label.runes.first).toUpperCase();
        final pb =
            ui.ParagraphBuilder(
                ui.ParagraphStyle(
                  fontSize: d * 0.6,
                  fontWeight: FontWeight.w700,
                ),
              )
              ..pushStyle(
                ui.TextStyle(
                  color: const Color(0xFFFFFFFF),
                  fontSize: d * 0.6,
                  fontWeight: FontWeight.w700,
                  fontFamily: CellFonts.screenFamily(CellFonts.inter),
                ),
              )
              ..addText(initial);
        final ip = pb.build()
          ..layout(const ui.ParagraphConstraints(width: double.infinity));
        canvas.drawParagraph(
          ip,
          Offset(
            center.dx - ip.maxIntrinsicWidth / 2,
            center.dy - ip.height / 2,
          ),
        );
        ip.dispose();
      case 'file':
        _paintFileIcon(canvas, center, d, c.seed);
      default:
        canvas.drawCircle(
          center,
          d / 4,
          Paint()..color = const Color(0xFF5F6368),
        );
    }
  }
}

/// A small drive item icon: a document (blue, lines), a spreadsheet (green,
/// grid) or a folder (gray).
void _paintFileIcon(Canvas canvas, Offset c, double d, String itemKind) {
  final w = d * 0.78;
  final h = d * 0.92;
  final r = Rect.fromCenter(center: c, width: w, height: h);
  final white = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..strokeWidth = math.max(1, d / 12);
  switch (itemKind) {
    case 'folder':
      final f = Rect.fromCenter(center: c, width: d * 0.92, height: d * 0.7);
      final tab = Path()
        ..moveTo(f.left, f.top)
        ..lineTo(f.left + f.width * 0.4, f.top)
        ..lineTo(f.left + f.width * 0.5, f.top + f.height * 0.15)
        ..lineTo(f.right, f.top + f.height * 0.15)
        ..lineTo(f.right, f.bottom)
        ..lineTo(f.left, f.bottom)
        ..close();
      canvas.drawPath(tab, Paint()..color = const Color(0xFF5F6368));
    case 'spreadsheet':
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(d * 0.1)),
        Paint()..color = const Color(0xFF188038),
      );
      for (var i = 1; i < 3; i++) {
        final y = r.top + r.height * i / 3;
        canvas.drawLine(
          Offset(r.left + w * 0.18, y),
          Offset(r.right - w * 0.18, y),
          white,
        );
      }
      canvas.drawLine(
        Offset(c.dx, r.top + h * 0.2),
        Offset(c.dx, r.bottom - h * 0.2),
        white,
      );
    default:
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(d * 0.1)),
        Paint()..color = const Color(0xFF1A73E8),
      );
      for (var i = 1; i < 4; i++) {
        final y = r.top + r.height * i / 4;
        canvas.drawLine(
          Offset(r.left + w * 0.2, y),
          Offset(r.right - w * (i == 3 ? 0.4 : 0.2), y),
          white,
        );
      }
  }
}
