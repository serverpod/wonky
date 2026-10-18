/// PDF exporter (07 §5.2): theme-driven typography, pagination with
/// keep-with-next and widow/orphan control, headers/footers, bookmarks,
/// internal and external links, images, code highlighting, tables.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
// PdfString is not exported; needed for deterministic info dates.
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/string.dart' show PdfString;

import '../../delta/delta_utils.dart';
import '../../highlight/syntax_highlighter.dart';
import '../../ir/doc_tree.dart';
import '../../layout/header_footer_tokens.dart';
import '../../layout/page_setup.dart';
import '../../layout/pagination_engine.dart';
import '../../markdown/front_matter.dart';
import '../../theme/model/style_enums.dart';
import '../../theme/model/values.dart';
import '../../theme/numbering/heading_numberer.dart';
import '../../theme/numbering/list_markers.dart';
import '../../theme/resolve/resolved_theme.dart';
import '../../theme/resolve/theme_resolver.dart';
import '../export_api.dart';
import '../markdown_file_exporter.dart';
import 'pdf_text.dart';

/// A PDF document with deterministic ids.
final class _DeterministicDocument extends PdfDocument {
  _DeterministicDocument(this._id, {required super.compress})
    : super(version: PdfVersion.pdf_1_4);

  final Uint8List _id;

  @override
  Uint8List get documentID => _id;
}

enum _Kind { text, image, rule, table }

/// One cell of a laid-out table.
final class _Cell {
  _Cell(this.lines, this.background);
  final List<PdfLine> lines;
  final int? background;
}

/// A block laid out for a given content width.
final class _Block {
  _Block({
    required this.source,
    required this.index,
    required this.kind,
    this.lines = const [],
    this.textLeft = 0,
    this.paddingTop = 0,
    this.paddingBottom = 0,
    this.paddingLeft = 0,
    this.paddingRight = 0,
    this.background,
    this.borders,
    this.radius = 0,
    this.spaceBefore = 0,
    this.spaceAfter = 0,
    this.keepWithNext = false,
    this.pageBreakBefore = false,
  });

  final DocBlock? source;
  final int index;
  final _Kind kind;
  final List<PdfLine> lines;
  final double textLeft;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;
  final int? background;
  final BordersPt? borders;
  final double radius;
  final double spaceBefore;
  final double spaceAfter;
  final bool keepWithNext;
  final bool pageBreakBefore;

  // Decorations.
  BorderPt? leftBar;
  BorderPt? bottomBorder;
  double bottomBorderGap = 0;
  String? markerText;
  PdfRunStyle? markerStyle;
  String? bulletShape; // '•', '◦', '▪'
  int markerColor = 0xff000000;
  double markerWidth = 0;
  ResolvedTask? task;
  bool checked = false;
  String? anchorId;
  int headingLevel = 0;
  String headingTitle = '';

  // Image.
  PdfImage? image;
  double imageWidth = 0;
  double imageHeight = 0;
  double imageLeft = 0;
  List<PdfLine> caption = const [];
  double captionGap = 0;
  ThemeAlign captionAlign = ThemeAlign.center;
  String placeholder = '';
  double imageRadius = 0;
  BorderPt? imageBorder;

  // Rule.
  ResolvedRule? rule;
  double ruleHeight = 0;

  // Table.
  List<List<_Cell>> rows = const [];
  List<double> columnWidths = const [];
  ResolvedTable? tableStyle;
  int headerRows = 1;
  List<double> rowHeights = const [];

  double get linesHeight => lines.fold(0.0, (s, l) => s + l.height);
}

/// Exports documents to PDF.
final class PdfExporter implements DocumentExporter<PdfExportOptions> {
  /// Creates the exporter; [compress] can be disabled for debugging/tests.
  const PdfExporter({this.compress = true});

  /// Deflate content streams.
  final bool compress;

  @override
  ExportFormat get format => ExportFormat.pdf;

  @override
  Future<ExportArtifact> export(
    ExportInput input,
    PdfExportOptions options,
  ) async {
    final job = _PdfJob(input, options, compress: compress);
    final bytes = await job.run();
    return ExportArtifact(
      fileName: ExportFileNames.fileName(
        options.fileName ?? input.meta.title,
        'pdf',
      ),
      mimeType: format.mimeType,
      bytes: bytes,
      pageCount: job.emittedPages,
      warnings: job.warnings,
    );
  }
}

/// Page counts for `write.get_stats.pages_estimate` (layout without
/// rendering).
abstract final class PdfPageCounter {
  /// Number of pages [input] lays out to.
  static Future<int> count(
    ExportInput input, {
    PdfExportOptions options = const PdfExportOptions(),
  }) async {
    final job = _PdfJob(input, options, compress: true);
    await job.prepare();
    return job.paginate().pages.length;
  }
}

final class _PdfJob {
  _PdfJob(this.input, this.options, {required this.compress});

  final ExportInput input;
  final PdfExportOptions options;
  final bool compress;
  final warnings = <ExportWarning>[];
  int emittedPages = 0;

  late final ResolvedWriteTheme theme = ThemeResolver.instance.resolve(
    input.theme,
    input.variant,
  );
  late final DocTree tree = exportTree(input, options);
  late final PdfDocument doc = _DeterministicDocument(
    Uint8List.fromList(
      sha256
          .convert(
            '${input.meta.documentUuid}|${input.revision}|${theme.contentHash}|${input.variant.name}'
                .codeUnits,
          )
          .bytes,
    ),
    compress: compress,
  );
  late final PdfFontBook fonts = PdfFontBook(doc, input.fonts, warnings);
  late final PdfStyler styler = PdfStyler(fonts);
  late final PdfLineBreaker breaker = PdfLineBreaker(fonts);
  late final PageSetup setup = input.pageSetup;
  late final double pageWidth = setup.pageWidthPt;
  late final double pageHeight = setup.pageHeightPt;
  late final EdgeInsetsPt margins = () {
    final m = setup.margins;
    if (m != null) {
      return EdgeInsetsPt(
        top: m.top,
        right: m.right,
        bottom: m.bottom,
        left: m.left,
      );
    }
    final d = theme.page.defaultMargins;
    return EdgeInsetsPt(
      top: d.top,
      right: d.right,
      bottom: d.bottom,
      left: d.left,
    );
  }();
  late final double contentWidth = pageWidth - margins.left - margins.right;
  final _images = <String, PdfImage?>{};
  List<_Block> blocks = [];
  List<int> headingPages = [];

  Future<void> prepare() async {
    input.progress?.call(ExportPhase.fonts, 0);
    final t = theme;
    final requests = <(String, int, bool)>{
      for (final s in [
        t.body.style,
        t.list.style,
        t.blockquote.style,
        t.task.style,
        t.table.style,
        t.header.style,
      ])
        for (final w in [s.fontWeight, 700])
          for (final i in [false, true]) (s.fontFamily, w, i),
      for (final h in t.headings)
        (h.style.fontFamily, h.style.fontWeight, h.style.italic),
      for (final h in t.headings)
        (h.style.fontFamily, h.style.fontWeight, !h.style.italic),
      (t.table.headerStyle.fontFamily, t.table.headerStyle.fontWeight, false),
      (t.codeBlock.style.fontFamily, 400, false),
      (t.codeBlock.style.fontFamily, 700, false),
      (t.inlineCode.fontFamily, t.inlineCode.fontWeight, false),
    };
    await fonts.preload(requests, _allText());
    input.cancel?.throwIfCancelled();
    input.progress?.call(ExportPhase.images, 0);
    for (final im in tree.images) {
      if (_images.containsKey(im.src)) continue;
      _images[im.src] = await _loadImage(im);
    }
    input.cancel?.throwIfCancelled();
    blocks = await _buildBlocks(tree.blocks);
  }

  /// A turn for the event loop when the export runs on the UI isolate (web,
  /// 07 §4.3), then the cancellation check: without the turn, *Cancel*
  /// (and the progress) could only be handled after the whole export.
  Future<void> _turn() async {
    final yielder = input.yielder;
    if (yielder != null) await yielder.maybeYield();
    input.cancel?.throwIfCancelled();
  }

  String _allText() {
    final b = StringBuffer();
    for (final block in tree.blocks) {
      switch (block) {
        case ParagraphBlock(:final runs) ||
            HeadingBlock(:final runs) ||
            ListItemBlock(:final runs) ||
            TaskBlock(:final runs):
          b.write(InlineRun.plainText(runs));
        case QuoteBlock(:final lines):
          for (final l in lines) {
            b.write(InlineRun.plainText(l));
          }
        case CodeBlock(:final text):
          b.write(text);
        case TableBlock(:final rows):
          for (final r in rows) {
            for (final c in r) {
              b.write(InlineRun.plainText(c));
            }
          }
        case ImageBlock(:final alt, :final title):
          b.write('$alt${title ?? ''}');
        case RuleBlock():
          break;
      }
    }
    return b.toString();
  }

  Future<PdfImage?> _loadImage(ImageBlock im) async {
    final r = await input.images.resolve(im.src);
    if (r == null) {
      warnings.add(
        ExportWarning(
          'image_unavailable',
          'Image "${im.alt}" could not be loaded',
        ),
      );
      return null;
    }
    try {
      if (r.mime == 'image/jpeg' || r.mime == 'image/jpg') {
        final decoded = img.decodeJpg(r.bytes);
        if (decoded != null &&
            math.max(decoded.width, decoded.height) <= 2400) {
          return PdfImage.jpeg(doc, image: r.bytes);
        }
      }
      var decoded = img.decodeImage(r.bytes);
      if (decoded == null) throw const FormatException('undecodable');
      if (math.max(decoded.width, decoded.height) > 2400) {
        decoded = decoded.width >= decoded.height
            ? img.copyResize(decoded, width: 2400)
            : img.copyResize(decoded, height: 2400);
      }
      final rgba = decoded.convert(numChannels: 4);
      return PdfImage(
        doc,
        image: Uint8List.fromList(rgba.getBytes(order: img.ChannelOrder.rgba)),
        width: rgba.width,
        height: rgba.height,
      );
    } on Object {
      warnings.add(
        ExportWarning(
          'image_unavailable',
          'Image "${im.alt}" has an unsupported format',
        ),
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Inline runs → styled runs

  List<(String, PdfRunStyle)> _runs(
    List<InlineRun> runs,
    ResolvedTextStyle base, {
    int? color,
    bool strikeAll = false,
    CaseTransform caseTransform = CaseTransform.none,
  }) {
    final t = theme;
    final out = <(String, PdfRunStyle)>[];
    for (final r in runs) {
      final text = applyCase(r.text, caseTransform);
      if (r.code) {
        final ic = t.inlineCode;
        out.add((
          text,
          PdfRunStyle(
            font: fonts.font(
              ic.fontFamily,
              ic.fontWeight,
              ic.italic,
              mono: true,
            ),
            size: base.fontSize * ic.sizeRatio,
            color: ic.color,
            background: ic.background,
            backgroundPadX: ic.paddingX,
            backgroundRadius: ic.borderRadius,
            link: r.link,
            strike: strikeAll,
          ),
        ));
        continue;
      }
      final weight = r.bold ? (t.bold.fontWeight ?? 700) : base.fontWeight;
      final italic = r.italic ? true : base.italic;
      var c = color ?? base.color;
      if (r.bold && t.bold.color != null) c = t.bold.color!;
      if (r.italic && t.italic.color != null) c = t.italic.color!;
      if (r.strike && t.strike.color != null) c = t.strike.color!;
      final isMention = r.mentionUserUuid != null;
      if (r.link != null) c = isMention ? t.mention.color : t.link.color;
      out.add((
        text,
        PdfRunStyle(
          font: fonts.font(
            base.fontFamily,
            isMention ? t.mention.fontWeight : weight,
            italic,
          ),
          size: base.fontSize,
          color: c,
          letterSpacing: base.letterSpacing,
          underline:
              r.link != null &&
              !isMention &&
              t.link.underline == LinkUnderline.always,
          strike: r.strike || strikeAll,
          decorationColor: r.strike ? t.strike.lineColor : null,
          decorationThickness: r.strike
              ? t.strike.lineThickness
              : t.link.underlineThickness,
          background: isMention ? t.mention.background : null,
          backgroundRadius: isMention ? t.mention.borderRadius : 0,
          backgroundPadX: isMention ? 1.5 : 0,
          link: r.link == null ? null : input.links.resolve(r.link!),
        ),
      ));
    }
    return out;
  }

  PdfRunStyle _base(ResolvedTextStyle s, {bool mono = false}) =>
      styler.text(s, mono: mono);

  // ---------------------------------------------------------------------
  // Blocks

  Future<List<_Block>> _buildBlocks(List<DocBlock> source) async {
    final t = theme;
    final labels = HeadingNumberer.labelsFor(
      t.headingNumbering,
      source.whereType<HeadingBlock>().map((h) => h.level),
    );
    var headingIndex = 0;
    final out = <_Block>[];
    DocBlock? prev;
    for (var i = 0; i < source.length; i++) {
      // Line breaking is most of the work: a turn every few blocks.
      if (i % 8 == 7) await _turn();
      final b = source[i];
      final afterHeading = prev is HeadingBlock;
      switch (b) {
        case ParagraphBlock(:final runs):
          final box = t.body.box;
          final lines = breaker.layout(
            _runs(runs, t.body.style),
            contentWidth,
            lineHeight: t.body.style.lineHeight,
            baseStyle: _base(t.body.style),
            align: box.align,
            firstLineIndent: t.body.firstLineIndent,
          );
          out.add(
            _Block(
              source: b,
              index: i,
              kind: _Kind.text,
              lines: lines,
              spaceBefore: afterHeading
                  ? (t.paragraphAfterHeading.spaceBefore ?? box.spaceBefore)
                  : box.spaceBefore,
              spaceAfter: afterHeading
                  ? (t.paragraphAfterHeading.spaceAfter ?? box.spaceAfter)
                  : box.spaceAfter,
            ),
          );
        case HeadingBlock(:final level, :final runs, :final anchorId):
          final h = t.headings[level - 1];
          final label = labels[headingIndex++];
          final all = [if (label != null) InlineRun(label), ...runs];
          final width = contentWidth - h.box.padding.horizontal;
          final lines = breaker.layout(
            _runs(all, h.style, caseTransform: h.style.caseTransform),
            width,
            lineHeight: h.style.lineHeight,
            baseStyle: _base(h.style),
            align: h.box.align,
          );
          final borderH = h.borderBottom != null && h.borderBottom!.isVisible
              ? h.borderBottomGap + h.borderBottom!.width
              : 0.0;
          out.add(
            _Block(
                source: b,
                index: i,
                kind: _Kind.text,
                lines: lines,
                paddingTop: h.box.padding.top,
                paddingBottom: h.box.padding.bottom + borderH,
                paddingLeft: h.box.padding.left,
                paddingRight: h.box.padding.right,
                background: h.box.background,
                spaceBefore: h.box.spaceBefore,
                spaceAfter: h.box.spaceAfter,
                keepWithNext: h.box.keepWithNext || true,
                pageBreakBefore: h.box.pageBreakBefore,
              )
              ..bottomBorder = borderH > 0 ? h.borderBottom : null
              ..bottomBorderGap = h.borderBottomGap
              ..anchorId = anchorId
              ..headingLevel = level
              ..headingTitle = InlineRun.plainText(
                all,
              ).replaceAll(softBreak, ' ').trim(),
          );
        case ListItemBlock(
          :final kind,
          :final indent,
          :final ordinal,
          :final runs,
        ):
          out.add(
            _listItem(
              b,
              i,
              indent,
              runs,
              ordered: kind == ListKindIr.ordered,
              ordinal: ordinal,
              prev: prev,
            ),
          );
        case TaskBlock(:final checked, :final indent, :final runs):
          out.add(
            _listItem(
              b,
              i,
              indent,
              runs,
              task: true,
              checked: checked,
              prev: prev,
            ),
          );
        case QuoteBlock(:final lines):
          final q = t.blockquote;
          final bar = q.bar.isVisible ? q.bar.width : 0.0;
          final left = q.box.padding.left + bar;
          final width = contentWidth - left - q.box.padding.right;
          final laid = <PdfLine>[];
          for (var li = 0; li < lines.length; li++) {
            laid.addAll(
              breaker.layout(
                _runs(lines[li], q.style),
                width,
                lineHeight: q.style.lineHeight,
                baseStyle: _base(q.style),
                align: q.box.align,
              ),
            );
          }
          out.add(
            _Block(
              source: b,
              index: i,
              kind: _Kind.text,
              lines: laid,
              textLeft: left,
              paddingTop: q.box.padding.top,
              paddingBottom: q.box.padding.bottom,
              background: q.box.background,
              spaceBefore: q.box.spaceBefore,
              spaceAfter: q.box.spaceAfter,
            )..leftBar = q.bar.isVisible ? q.bar : null,
          );
        case CodeBlock(:final language, :final text):
          out.add(_code(b, i, language, text));
        case ImageBlock():
          out.add(_imageBlock(b, i));
        case RuleBlock():
          final r = t.rule;
          final h = r.style == RuleStyle.ornament
              ? r.ornamentStyle.fontSize * r.ornamentStyle.lineHeight
              : r.thickness * (r.style == RuleStyle.doubleLine ? 3 : 1);
          out.add(
            _Block(
                source: b,
                index: i,
                kind: _Kind.rule,
                spaceBefore: r.box.spaceBefore,
                spaceAfter: r.box.spaceAfter,
              )
              ..rule = r
              ..ruleHeight = h,
          );
        case TableBlock():
          out.add(_table(b, i));
      }
      prev = b;
    }
    return out;
  }

  _Block _listItem(
    DocBlock b,
    int index,
    int indent,
    List<InlineRun> runs, {
    bool ordered = false,
    int ordinal = 1,
    bool task = false,
    bool checked = false,
    DocBlock? prev,
  }) {
    final t = theme;
    final l = t.list;
    final style = task ? t.task.style : l.style;
    final left = l.indentPerLevel * (indent + 1);
    final width = contentWidth - left;
    final lines = breaker.layout(
      _runs(
        runs,
        style,
        color: task && checked ? t.task.checkedColor : null,
        strikeAll: task && checked && t.task.checkedStrike,
      ),
      width,
      lineHeight: style.lineHeight,
      baseStyle: _base(style),
    );
    final firstInRun = prev is! ListItemBlock && prev is! TaskBlock;
    final box = task ? t.task.box : l.box;
    final block = _Block(
      source: b,
      index: index,
      kind: _Kind.text,
      lines: lines,
      textLeft: left,
      spaceBefore: firstInRun ? box.spaceBefore : l.itemSpacing,
      spaceAfter: l.itemSpacing,
    );
    if (task) {
      block
        ..task = t.task
        ..checked = checked;
    } else if (ordered) {
      final numbering = l.numbering[indent % l.numbering.length];
      block
        ..markerText = ListMarkers.marker(
          ordinal,
          numbering,
          suffix: l.numberSuffix,
        )
        ..markerStyle = _base(style).copyWith(color: l.numberColor);
    } else {
      final glyph = l.bullets[indent % l.bullets.length];
      if (const {'•', '◦', '▪'}.contains(glyph)) {
        block.bulletShape = glyph;
        block.markerColor = l.bulletColor;
      } else {
        block
          ..markerText = glyph
          ..markerStyle = _base(style).copyWith(
            color: l.bulletColor,
            size: style.fontSize * l.bulletScale,
          );
      }
    }
    block.markerWidth = l.markerGap;
    return block;
  }

  _Block _code(DocBlock b, int index, String language, String text) {
    final t = theme;
    final cb = t.codeBlock;
    final base = _base(cb.style, mono: true);
    final spans = SyntaxHighlighter.instance.tokenize(text, language);
    final width = contentWidth - cb.box.padding.horizontal;
    final lines = <PdfLine>[];
    var lineStart = 0;
    for (final raw in text.split('\n')) {
      final lineEnd = lineStart + raw.length;
      final runs = <(String, PdfRunStyle)>[];
      var pos = lineStart;
      for (final s in spans) {
        if (s.end <= lineStart || s.start >= lineEnd) continue;
        final a = math.max(s.start, lineStart);
        final e = math.min(s.end, lineEnd);
        if (a > pos) runs.add((text.substring(pos, a), base));
        final ts = t.syntax[s.token];
        runs.add((
          text.substring(a, e),
          ts == null
              ? base
              : base.copyWith(
                  color: ts.color,
                  font: fonts.font(
                    cb.style.fontFamily,
                    ts.fontWeight ?? cb.style.fontWeight,
                    ts.italic,
                    mono: true,
                  ),
                ),
        ));
        pos = e;
      }
      if (pos < lineEnd) runs.add((text.substring(pos, lineEnd), base));
      final expanded = [
        for (final (s, st) in runs) (s.replaceAll('\t', ' ' * cb.tabSize), st),
      ];
      lines.addAll(
        breaker.layout(
          expanded.isEmpty ? [('', base)] : expanded,
          width,
          lineHeight: cb.style.lineHeight,
          baseStyle: base,
          code: true,
          continuationMarker:
              fonts
                  .font(cb.style.fontFamily, 400, false, mono: true)
                  .isRuneSupported(0x21AA)
              ? '↪'
              : '>',
        ),
      );
      lineStart = lineEnd + 1;
    }
    return _Block(
      source: b,
      index: index,
      kind: _Kind.text,
      lines: lines,
      textLeft: cb.box.padding.left,
      paddingTop: cb.box.padding.top,
      paddingBottom: cb.box.padding.bottom,
      background: cb.box.background,
      borders: cb.box.border,
      radius: cb.box.borderRadius,
      spaceBefore: cb.box.spaceBefore,
      spaceAfter: cb.box.spaceAfter,
    );
  }

  _Block _imageBlock(ImageBlock b, int index) {
    final t = theme;
    final st = t.image;
    final block = _Block(
      source: b,
      index: index,
      kind: _Kind.image,
      spaceBefore: st.box.spaceBefore,
      spaceAfter: st.box.spaceAfter,
    );
    final pdfImage = _images[b.src];
    final maxW = st.maxWidth.fraction != null
        ? contentWidth * st.maxWidth.fraction!
        : math.min(contentWidth, st.maxWidth.points ?? contentWidth);
    if (pdfImage == null) {
      block
        ..placeholder = '[Image: ${b.alt}]'
        ..imageWidth = math.min(maxW, contentWidth)
        ..imageHeight = t.body.style.fontSize * 3;
    } else {
      final w = math.min(maxW, pdfImage.width * 0.75);
      block
        ..image = pdfImage
        ..imageWidth = w
        ..imageHeight = w * pdfImage.height / pdfImage.width
        ..imageRadius = st.borderRadius
        ..imageBorder = st.border;
    }
    block.imageLeft = st.align == ImageAlign.center
        ? (contentWidth - block.imageWidth) / 2
        : 0;
    if (st.caption.show && b.title != null && b.title!.isNotEmpty) {
      block
        ..caption = breaker.layout(
          [(b.title!, _base(st.caption.style))],
          contentWidth,
          lineHeight: st.caption.style.lineHeight,
          baseStyle: _base(st.caption.style),
          align: st.caption.align,
        )
        ..captionGap = st.caption.gap;
    }
    return block;
  }

  _Block _table(TableBlock b, int index) {
    final t = theme;
    final ts = t.table;
    final cols = b.columnCount == 0 ? 1 : b.columnCount;
    final pad = ts.cellPadding;
    // Natural widths (single line) and minimum 2em.
    final natural = List.filled(cols, 0.0);
    final minW = ts.style.fontSize * 2 + pad.horizontal;
    for (var r = 0; r < b.rows.length; r++) {
      final style = r == 0 ? ts.headerStyle : ts.style;
      for (var c = 0; c < cols && c < b.rows[r].length; c++) {
        final lines = breaker.layout(
          _runs(b.rows[r][c], style),
          1e9,
          lineHeight: style.lineHeight,
          baseStyle: _base(style),
        );
        final w =
            lines.fold(0.0, (m, l) => math.max(m, l.width)) +
            pad.horizontal +
            1;
        natural[c] = math.max(natural[c], math.max(w, minW));
      }
    }
    final sum = natural.fold(0.0, (s, w) => s + w);
    final widths = ts.width == TableWidth.full || sum > contentWidth
        ? [for (final w in natural) w / sum * contentWidth]
        : natural;
    final rows = <List<_Cell>>[];
    final heights = <double>[];
    final metrics = <RowMetrics>[];
    for (var r = 0; r < b.rows.length; r++) {
      final style = r == 0 ? ts.headerStyle : ts.style;
      final cells = <_Cell>[];
      var h = 0.0;
      for (var c = 0; c < cols; c++) {
        final runs = c < b.rows[r].length ? b.rows[r][c] : const <InlineRun>[];
        final align = c < b.align.length ? b.align[c] : null;
        final lines = breaker.layout(
          _runs(runs, style, color: r == 0 ? style.color : null),
          widths[c] - pad.horizontal,
          lineHeight: style.lineHeight,
          baseStyle: _base(style),
          align: switch (align?.value) {
            'center' => ThemeAlign.center,
            'right' => ThemeAlign.right,
            _ => ThemeAlign.left,
          },
        );
        final bg = r == 0
            ? ts.headerBackground
            : (ts.zebra && r.isEven ? ts.zebraColor : null);
        cells.add(_Cell(lines, bg));
        h = math.max(h, lines.fold(0.0, (s, l) => s + l.height));
      }
      rows.add(cells);
      heights.add(h + pad.vertical);
      metrics.add(
        RowMetrics(
          h + pad.vertical,
          cellLineHeights: [
            for (final c in cells) [for (final l in c.lines) l.height],
          ],
          cellPadding: pad.vertical,
        ),
      );
    }
    return _Block(
        source: b,
        index: index,
        kind: _Kind.table,
        spaceBefore: ts.box.spaceBefore,
        spaceAfter: ts.box.spaceAfter,
      )
      ..rows = rows
      ..columnWidths = widths
      ..tableStyle = ts
      ..rowHeights = heights
      .._rowMetrics.addAll(metrics);
  }

  // ---------------------------------------------------------------------
  // Pagination

  double _slotHeight(HeaderFooterSpec spec) {
    if (!options.headerFooter || !spec.enabled || spec.isEmpty) return 0;
    final s = theme.header.style;
    return s.fontSize * s.lineHeight;
  }

  PageGeometry _geometry(int pageIndex) {
    final header = setup.headerFor(pageIndex);
    final footer = setup.footerFor(pageIndex);
    return PageGeometry(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      margins: margins,
      headerHeight: _slotHeight(header),
      footerHeight: _slotHeight(footer),
      headerDistance: header.distancePt,
      footerDistance: footer.distancePt,
    );
  }

  List<BlockMetrics> _metrics() => [
    for (var i = 0; i < blocks.length; i++) _metricsOf(i, blocks[i]),
  ];

  BlockMetrics _metricsOf(int i, _Block b) {
    switch (b.kind) {
      case _Kind.text:
        return BlockMetrics(
          blockIndex: i,
          spaceBefore: b.spaceBefore,
          spaceAfter: b.spaceAfter,
          lineHeights: b.lines.isEmpty
              ? [theme.body.style.fontSize * theme.body.style.lineHeight]
              : [for (final l in b.lines) l.height],
          paddingTop: b.paddingTop,
          paddingBottom: b.paddingBottom,
          keepWithNext: b.keepWithNext,
          pageBreakBefore: b.pageBreakBefore,
        );
      case _Kind.image:
        final caption = b.caption.fold(0.0, (s, l) => s + l.height);
        return BlockMetrics(
          blockIndex: i,
          kind: BlockMetricsKind.image,
          spaceBefore: b.spaceBefore,
          spaceAfter: b.spaceAfter,
          fixedHeight:
              b.imageHeight + (caption > 0 ? b.captionGap + caption : 0),
          captionHeight: caption > 0 ? b.captionGap + caption : 0,
        );
      case _Kind.rule:
        return BlockMetrics(
          blockIndex: i,
          kind: BlockMetricsKind.rule,
          spaceBefore: b.spaceBefore,
          spaceAfter: b.spaceAfter,
          fixedHeight: b.ruleHeight,
        );
      case _Kind.table:
        return BlockMetrics(
          blockIndex: i,
          kind: BlockMetricsKind.table,
          spaceBefore: b.spaceBefore,
          spaceAfter: b.spaceAfter,
          rows: b._rowMetrics,
          headerRows: b.rows.isEmpty ? 0 : 1,
        );
    }
  }

  PaginationResult paginate() {
    input.progress?.call(ExportPhase.layout, 0);
    return const PaginationEngine().paginate(
      _metrics(),
      _geometry(1),
      firstPage: setup.differentFirstPage ? _geometry(0) : null,
    );
  }

  /// Inserts a table of contents after the title block (first H1 when it is
  /// the first block), re-laying out until page numbers are stable.
  PaginationResult _withToc(PaginationResult first) {
    var result = first;
    final headings = [
      for (final b in blocks)
        if (b.headingLevel > 0 && b.headingLevel <= options.tocDepth) b,
    ];
    if (headings.isEmpty) return result;
    final insertAt = blocks.isNotEmpty && blocks.first.headingLevel == 1
        ? 1
        : 0;
    final content = List.of(blocks);
    for (var pass = 0; pass < 3; pass++) {
      final pageOf = <_Block, int>{};
      for (final p in result.pages) {
        for (final s in p.slices) {
          final blk = blocks[s.blockIndex];
          pageOf.putIfAbsent(blk, () => p.index);
        }
      }
      final entries = <_Block>[];
      for (final h in headings) {
        final page = setup.pageLabel(pageOf[h] ?? 0);
        entries.add(_tocEntry(h, page));
      }
      blocks = [
        ...content.sublist(0, insertAt),
        ...entries,
        ...content.sublist(insertAt),
      ];
      final next = paginate();
      final stable = next.pages.length == result.pages.length && pass > 0;
      result = next;
      if (stable) break;
    }
    return result;
  }

  _Block _tocEntry(_Block heading, String pageLabel) {
    final t = theme;
    final indent = (heading.headingLevel - 1) * t.list.indentPerLevel;
    final style = _base(t.body.style);
    final width = contentWidth - indent;
    final pageW = breaker.measure(pageLabel, style);
    final titleLines = breaker.layout(
      [(heading.headingTitle, style.copyWith(color: t.body.style.color))],
      width - pageW - 24,
      lineHeight: t.body.style.lineHeight,
      baseStyle: style,
    );
    // Dot leaders + page number on the last line.
    final last = titleLines.last;
    final dotW = breaker.measure('.', style);
    final available = width - last.width - pageW - 4;
    final dots = dotW <= 0 ? 0 : (available / dotW).floor();
    final leader = PdfPiece(
      '.' * math.max(0, dots),
      style.copyWith(
        color: t.headings.isEmpty ? style.color : t.body.style.color,
      ),
      dots * dotW,
    )..x = last.width + 2;
    final number = PdfPiece(pageLabel, style, pageW)..x = width - pageW;
    final linkTarget = '#${heading.anchorId}';
    final pieces = [
      for (final p in last.pieces)
        PdfPiece(p.text, _withLink(p.style, linkTarget), p.width)..x = p.x,
      leader,
      number,
    ];
    final lines = [
      for (final l in titleLines.take(titleLines.length - 1))
        PdfLine(
          [
            for (final p in l.pieces)
              PdfPiece(p.text, _withLink(p.style, linkTarget), p.width)
                ..x = p.x,
          ],
          height: l.height,
          ascent: l.ascent,
          width: l.width,
        ),
      PdfLine(pieces, height: last.height, ascent: last.ascent, width: width),
    ];
    return _Block(
      source: null,
      index: -1,
      kind: _Kind.text,
      lines: lines,
      textLeft: indent,
      spaceAfter: 2,
    );
  }

  PdfRunStyle _withLink(PdfRunStyle s, String link) => PdfRunStyle(
    font: s.font,
    size: s.size,
    color: s.color,
    letterSpacing: s.letterSpacing,
    link: link,
  );

  // ---------------------------------------------------------------------
  // Rendering

  Future<Uint8List> run() async {
    await prepare();
    var result = paginate();
    if (options.includeToc) result = _withToc(result);
    final selected = options.selectedPages(result.pages.length);
    final info = PdfInfo(
      doc,
      title: input.meta.title,
      author: input.meta.authorName,
      subject: input.meta.description,
      keywords: FrontMatter.tags(input.meta.frontMatter).join(', '),
      creator: 'Wonky Write',
    );
    final when = input.meta.modifiedAt ?? DateTime.utc(2000);
    info.params['/CreationDate'] = PdfString.fromDate(when);
    info.params['/ModDate'] = PdfString.fromDate(when);

    final outlineStack = <(int, PdfOutline)>[];
    final count = result.pages.length;
    for (final page in result.pages) {
      await _turn();
      input.progress?.call(ExportPhase.layout, page.index / count);
      if (selected != null && !selected.contains(page.index)) continue;
      emittedPages++;
      final pdfPage = PdfPage(
        doc,
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
      );
      final g = pdfPage.getGraphics();
      final paper = theme.page.paperColor;
      final paintBackground =
          options.pageBackground ??
          (input.variant == ThemeVariant.dark ||
              (paper & 0xFFFFFF) != 0xFFFFFF);
      if (paintBackground) {
        g
          ..setFillColor(_color(paper))
          ..drawRect(0, 0, pageWidth, pageHeight)
          ..fillPath();
      }
      final geo = _geometry(page.index);
      if (options.headerFooter) _headerFooter(g, page.index, count, geo);
      for (final slice in page.slices) {
        final b = blocks[slice.blockIndex];
        final top = geo.contentTop + slice.y;
        switch (b.kind) {
          case _Kind.text:
            _paintText(pdfPage, g, b, slice, top);
          case _Kind.image:
            _paintImage(g, b, slice, top);
          case _Kind.rule:
            if (slice.height > 0) _paintRule(g, b, top);
          case _Kind.table:
            _paintTable(pdfPage, g, b, slice, top);
        }
        // Anchors and bookmarks at the first slice of a heading.
        if (b.anchorId != null && !slice.isContinuation) {
          final y = pageHeight - top;
          doc.pdfNames.addDest(b.anchorId!, pdfPage, posY: y);
          if (options.bookmarks) {
            final outline = PdfOutline(
              doc,
              title: b.headingTitle,
              dest: pdfPage,
              rect: PdfRect(0, y - 1, pageWidth, 1),
              destMode: PdfOutlineMode.fitPage,
            );
            while (outlineStack.isNotEmpty &&
                outlineStack.last.$1 >= b.headingLevel) {
              outlineStack.removeLast();
            }
            (outlineStack.isEmpty ? doc.outline : outlineStack.last.$2).add(
              outline,
            );
            outlineStack.add((b.headingLevel, outline));
          }
        }
      }
    }
    input.progress?.call(ExportPhase.packaging, 1);
    return doc.save();
  }

  static PdfColor _color(int argb) => PdfColor.fromInt(argb | 0xFF000000);

  void _headerFooter(PdfGraphics g, int index, int count, PageGeometry geo) {
    final ctx = TokenContext(
      title: input.meta.title ?? '',
      author:
          input.meta.authorName ??
          FrontMatter.field(input.meta.frontMatter, 'author') ??
          '',
      now: input.now,
      modified: input.meta.modifiedAt,
      locale: input.locale,
      pageIndex: index,
      pageCount: count,
      pageNumberStart: setup.pageNumberStart,
      pageNumberFormat: setup.pageNumberFormat,
    );
    for (final (spec, isHeader) in [
      (setup.headerFor(index), true),
      (setup.footerFor(index), false),
    ]) {
      if (!spec.enabled || spec.isEmpty) continue;
      final hf = isHeader ? theme.header : theme.footer;
      final style = _base(hf.style);
      final h = hf.style.fontSize * hf.style.lineHeight;
      final top = isHeader ? spec.distancePt : pageHeight - spec.distancePt - h;
      for (final (template, align) in [
        (spec.left, ThemeAlign.left),
        (spec.center, ThemeAlign.center),
        (spec.right, ThemeAlign.right),
      ]) {
        if (template.isEmpty) continue;
        final text = HeaderFooterTokens.expand(template, ctx);
        final lines = breaker.layout(
          [(text, style)],
          contentWidth,
          lineHeight: hf.style.lineHeight,
          baseStyle: style,
          align: align,
        );
        if (lines.isEmpty) continue;
        _drawLine(null, g, lines.first, margins.left, top);
      }
      final border = isHeader ? hf.borderBottom : hf.borderTop;
      if (border != null && border.isVisible) {
        final y = pageHeight - (isHeader ? top + h + 2 : top - 2);
        _strokeLine(g, margins.left, y, pageWidth - margins.right, y, border);
      }
    }
  }

  void _strokeLine(
    PdfGraphics g,
    double x1,
    double y1,
    double x2,
    double y2,
    BorderPt b,
  ) {
    g
      ..saveContext()
      ..setStrokeColor(_color(b.color))
      ..setLineWidth(b.width);
    if (b.style == LineStyle.dashed) {
      g.setLineDashPattern([3 * b.width, 2 * b.width]);
    }
    if (b.style == LineStyle.dotted) g.setLineDashPattern([b.width, b.width]);
    g
      ..drawLine(x1, y1, x2, y2)
      ..strokePath()
      ..restoreContext();
  }

  void _drawLine(
    PdfPage? page,
    PdfGraphics g,
    PdfLine line,
    double left,
    double top,
  ) {
    final baseline = pageHeight - (top + line.ascent);
    for (final p in line.pieces) {
      if (p.text.isEmpty) continue;
      final s = p.style;
      final x = left + p.x;
      if (s.background != null) {
        final bh = s.size * 1.2;
        g
          ..setFillColor(_color(s.background!))
          ..drawRRect(
            x - s.backgroundPadX,
            baseline - s.size * 0.25,
            p.width + 2 * s.backgroundPadX,
            bh,
            s.backgroundRadius,
            s.backgroundRadius,
          )
          ..fillPath();
      }
      g
        ..setFillColor(_color(s.color))
        ..drawString(
          s.font,
          s.size,
          p.text,
          x,
          baseline,
          charSpace: s.letterSpacing == 0 ? null : s.letterSpacing,
        );
      if (s.underline || s.strike) {
        final y = s.strike ? baseline + s.size * 0.3 : baseline - s.size * 0.12;
        g
          ..setStrokeColor(_color(s.decorationColor ?? s.color))
          ..setLineWidth(s.decorationThickness)
          ..drawLine(x, y, x + p.width, y)
          ..strokePath();
      }
      final link = s.link;
      if (page != null && link != null && !p.isSpace) {
        final rect = PdfRect(
          x,
          baseline - s.size * 0.25,
          p.width,
          s.size * 1.2,
        );
        if (link.startsWith('#')) {
          PdfAnnot(
            page,
            PdfAnnotNamedLink(
              rect: rect,
              dest: link.substring(1),
              border: PdfBorder(doc, 0),
            ),
          );
        } else {
          PdfAnnot(
            page,
            PdfAnnotUrlLink(rect: rect, url: link, border: PdfBorder(doc, 0)),
          );
        }
      }
    }
  }

  void _paintText(
    PdfPage page,
    PdfGraphics g,
    _Block b,
    PlacedSlice slice,
    double top,
  ) {
    final from = slice.lineFrom ?? 0;
    final to = math.min(slice.lineTo ?? b.lines.length, b.lines.length);
    final left = margins.left;
    final bottomY = pageHeight - (top + slice.height);
    // Box background / borders.
    if (b.background != null) {
      final r = slice.isContinuation || slice.continues ? 0.0 : b.radius;
      g
        ..setFillColor(_color(b.background!))
        ..drawRRect(left, bottomY, contentWidth, slice.height, r, r)
        ..fillPath();
    }
    final borders = b.borders;
    if (borders != null && borders.hasAny) {
      final yTop = pageHeight - top;
      if (borders.top.isVisible && !slice.isContinuation) {
        _strokeLine(g, left, yTop, left + contentWidth, yTop, borders.top);
      }
      if (borders.bottom.isVisible && !slice.continues) {
        _strokeLine(
          g,
          left,
          bottomY,
          left + contentWidth,
          bottomY,
          borders.bottom,
        );
      }
      if (borders.left.isVisible) {
        _strokeLine(g, left, bottomY, left, yTop, borders.left);
      }
      if (borders.right.isVisible) {
        _strokeLine(
          g,
          left + contentWidth,
          bottomY,
          left + contentWidth,
          yTop,
          borders.right,
        );
      }
    }
    if (b.leftBar != null) {
      g
        ..setFillColor(_color(b.leftBar!.color))
        ..drawRect(left, bottomY, b.leftBar!.width, slice.height)
        ..fillPath();
    }
    var y = top + b.paddingTop;
    for (var i = from; i < to; i++) {
      final line = b.lines[i];
      final textLeft = left + b.textLeft + b.paddingLeft;
      if (i == 0 && !slice.isContinuation) {
        _paintMarker(g, b, line, textLeft, y);
      }
      _drawLine(page, g, line, textLeft, y);
      y += line.height;
    }
    if (b.bottomBorder != null && !slice.continues) {
      final by =
          pageHeight - (y + b.bottomBorderGap + b.bottomBorder!.width / 2);
      _strokeLine(g, left, by, left + contentWidth, by, b.bottomBorder!);
    }
  }

  void _paintMarker(
    PdfGraphics g,
    _Block b,
    PdfLine line,
    double textLeft,
    double top,
  ) {
    final baseline = pageHeight - (top + line.ascent);
    final size = line.height / theme.list.style.lineHeight;
    if (b.task != null) {
      final cb = b.task!.checkbox;
      final s = cb.size;
      final x = textLeft - b.markerWidth - s;
      final yb = baseline - s * 0.1;
      final r = cb.shape == CheckboxShape.circle
          ? s / 2
          : (cb.shape == CheckboxShape.rounded ? s * 0.2 : 0.0);
      g
        ..setStrokeColor(_color(cb.borderColor))
        ..setLineWidth(0.8);
      if (b.checked) {
        g
          ..setFillColor(_color(cb.checkedFill))
          ..drawRRect(x, yb, s, s, r, r)
          ..fillPath()
          ..setStrokeColor(_color(cb.checkColor))
          ..setLineWidth(s * 0.14)
          ..moveTo(x + s * 0.2, yb + s * 0.5)
          ..lineTo(x + s * 0.42, yb + s * 0.25)
          ..lineTo(x + s * 0.8, yb + s * 0.75)
          ..strokePath();
      } else {
        g
          ..drawRRect(x, yb, s, s, r, r)
          ..strokePath();
      }
      return;
    }
    if (b.bulletShape != null) {
      final d = size * 0.35 * theme.list.bulletScale;
      final cx = textLeft - b.markerWidth - d / 2;
      final cy = baseline + size * 0.32;
      g.setFillColor(_color(b.markerColor));
      switch (b.bulletShape) {
        case '•':
          g
            ..drawEllipse(cx, cy, d / 2, d / 2)
            ..fillPath();
        case '◦':
          g
            ..setStrokeColor(_color(b.markerColor))
            ..setLineWidth(d * 0.18)
            ..drawEllipse(cx, cy, d / 2.4, d / 2.4)
            ..strokePath();
        default:
          g
            ..drawRect(cx - d / 2.4, cy - d / 2.4, d / 1.2, d / 1.2)
            ..fillPath();
      }
      return;
    }
    final text = b.markerText;
    final style = b.markerStyle;
    if (text == null || style == null) return;
    final w = breaker.measure(text, style);
    for (final (seg, font) in fonts.segments(text, style.font)) {
      g
        ..setFillColor(_color(style.color))
        ..drawString(
          font,
          style.size,
          seg,
          textLeft - b.markerWidth - w,
          baseline,
        );
    }
  }

  void _paintImage(PdfGraphics g, _Block b, PlacedSlice slice, double top) {
    final scale = slice.scale;
    final w = b.imageWidth * scale;
    final h = b.imageHeight * scale;
    final x = margins.left + (b.imageLeft + (b.imageWidth - w) / 2);
    final y = pageHeight - (top + h);
    final image = b.image;
    if (image == null) {
      g
        ..setStrokeColor(_color(theme.table.borderColor))
        ..setLineWidth(0.75)
        ..drawRect(x, y, w, h)
        ..strokePath();
      final style = _base(
        theme.body.style,
      ).copyWith(color: theme.body.style.color);
      final lines = breaker.layout(
        [(b.placeholder, style)],
        w - 8,
        lineHeight: 1.2,
        baseStyle: style,
        align: ThemeAlign.center,
      );
      if (lines.isNotEmpty) {
        _drawLine(
          null,
          g,
          lines.first,
          x + 4,
          top + (h - lines.first.height) / 2,
        );
      }
    } else {
      g.saveContext();
      if (b.imageRadius > 0) {
        g
          ..drawRRect(x, y, w, h, b.imageRadius, b.imageRadius)
          ..clipPath();
      }
      g
        ..drawImage(image, x, y, w, h)
        ..restoreContext();
      final border = b.imageBorder;
      if (border != null && border.isVisible) {
        g
          ..setStrokeColor(_color(border.color))
          ..setLineWidth(border.width)
          ..drawRRect(x, y, w, h, b.imageRadius, b.imageRadius)
          ..strokePath();
      }
    }
    var cy = top + h + b.captionGap;
    for (final line in b.caption) {
      _drawLine(null, g, line, margins.left, cy);
      cy += line.height;
    }
  }

  void _paintRule(PdfGraphics g, _Block b, double top) {
    final r = b.rule!;
    final width = r.width.fraction != null
        ? contentWidth * r.width.fraction!
        : math.min(contentWidth, r.width.points ?? contentWidth);
    final x = margins.left + (contentWidth - width) / 2;
    if (r.style == RuleStyle.ornament) {
      final style = _base(r.ornamentStyle);
      final lines = breaker.layout(
        [(r.ornament, style)],
        contentWidth,
        lineHeight: r.ornamentStyle.lineHeight,
        baseStyle: style,
        align: ThemeAlign.center,
      );
      if (lines.isNotEmpty) _drawLine(null, g, lines.first, margins.left, top);
      return;
    }
    final y = pageHeight - (top + b.ruleHeight / 2);
    final border = BorderPt(
      width: r.thickness,
      style: switch (r.style) {
        RuleStyle.dashed => LineStyle.dashed,
        RuleStyle.dotted => LineStyle.dotted,
        _ => LineStyle.solid,
      },
      color: r.color,
    );
    if (r.style == RuleStyle.doubleLine) {
      _strokeLine(g, x, y + r.thickness, x + width, y + r.thickness, border);
      _strokeLine(g, x, y - r.thickness, x + width, y - r.thickness, border);
    } else {
      _strokeLine(g, x, y, x + width, y, border);
    }
  }

  void _paintTable(
    PdfPage page,
    PdfGraphics g,
    _Block b,
    PlacedSlice slice,
    double top,
  ) {
    final ts = b.tableStyle!;
    final pad = ts.cellPadding;
    var y = top;
    final rowIndexes = <int>[
      if (slice.repeatHeader && (slice.rowFrom ?? 0) > 0) 0,
      for (var r = slice.rowFrom ?? 0; r < (slice.rowTo ?? b.rows.length); r++)
        r,
    ];
    final tableWidth = b.columnWidths.fold(0.0, (s, w) => s + w);
    final border = BorderPt(
      width: ts.borderWidth,
      style: LineStyle.solid,
      color: ts.borderColor,
    );
    final tableTop = y;
    for (final r in rowIndexes) {
      final split = r == slice.rowFrom && slice.rowSplit != null
          ? slice.rowSplit
          : null;
      var rowH = b.rowHeights[r];
      if (split != null) {
        var maxH = 0.0;
        for (var c = 0; c < b.rows[r].length && c < split.length; c++) {
          final (f, t) = split[c];
          maxH = math.max(
            maxH,
            b.rows[r][c].lines
                .sublist(f, math.min(t, b.rows[r][c].lines.length))
                .fold(0.0, (s, l) => s + l.height),
          );
        }
        rowH = maxH + pad.vertical;
      }
      var x = margins.left;
      for (var c = 0; c < b.rows[r].length; c++) {
        final cell = b.rows[r][c];
        final w = b.columnWidths[c];
        if (cell.background != null) {
          g
            ..setFillColor(_color(cell.background!))
            ..drawRect(x, pageHeight - (y + rowH), w, rowH)
            ..fillPath();
        }
        var ly = y + pad.top;
        final (f, t) = split != null && c < split.length
            ? split[c]
            : (0, cell.lines.length);
        for (var li = f; li < math.min(t, cell.lines.length); li++) {
          _drawLine(page, g, cell.lines[li], x + pad.left, ly);
          ly += cell.lines[li].height;
        }
        if (ts.borders == TableBorders.all && c > 0) {
          _strokeLine(g, x, pageHeight - y, x, pageHeight - (y + rowH), border);
        }
        x += w;
      }
      final bottom = pageHeight - (y + rowH);
      final drawBottom = switch (ts.borders) {
        TableBorders.all || TableBorders.horizontal => true,
        TableBorders.headerOnly => r == 0,
        _ => false,
      };
      if (drawBottom) {
        _strokeLine(
          g,
          margins.left,
          bottom,
          margins.left + tableWidth,
          bottom,
          border,
        );
      }
      y += rowH;
    }
    if (ts.borders == TableBorders.all || ts.borders == TableBorders.outer) {
      g
        ..setStrokeColor(_color(ts.borderColor))
        ..setLineWidth(ts.borderWidth)
        ..drawRect(margins.left, pageHeight - y, tableWidth, y - tableTop)
        ..strokePath();
    }
  }
}

/// Row metrics storage on table blocks.
extension on _Block {
  static final _metrics = Expando<List<RowMetrics>>();

  List<RowMetrics> get _rowMetrics => _metrics[this] ??= <RowMetrics>[];
}
