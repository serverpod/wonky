/// The Slides PDF renderer (10 §11.3, 12 §5.7 `SlidesPdfRenderer`): pure
/// Dart, the same code on the client (print preview, *Download PDF*) and
/// the server (`slidesExport`, MCP).
///
/// Pipeline: select the slides and frames (`SlidesPdfPlanner`) → a first
/// scene pass with a recording measurer finds the fonts → the bundled TTFs
/// are loaded (`TtfFaceSet`) → the real scene pass lays text out with TTF
/// metrics (or the app's Flutter engine, [SlidesExportResources.
/// textLayout]) → images are fetched and prepared once → pages are drawn
/// (slides, notes pages, handouts) with headers/footers, bookmarks (groups →
/// slides), link annotations and deterministic metadata.
///
/// Frames (06 §9.6, SL-33): without builds every slide prints its print
/// frame (authored layout, content complete; [SlidesPdfOptions.
/// finalAnimationState] = the final frame); *Print each build stage* prints
/// one page per step whose settled frame differs from the step before,
/// with code states/steps and chart reveals composed per frame
/// (`SlideFrameScenes`); notes pages and handouts then show each slide's
/// final step. Charts are laid out with TTF metrics of the font they are
/// drawn with unless the caller passes its own chart source.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' show sha256;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
// ignore: implementation_imports
import 'package:pdf/src/pdf/format/string.dart' show PdfString;
import 'package:wonky_charts/wonky_charts.dart'
    show TtfChartFace, TtfChartFamily, TtfChartTextMeasurer;
import 'package:wonky_fonts/wonky_fonts.dart';

import '../../charts/chart_motion.dart';
import '../../charts/slide_chart_layout.dart';
import '../../interfaces/images.dart';
import '../../interfaces/pdf.dart';
import '../../model/api/deck_model.dart';
import '../../model/resolve/slide_resolver.dart';
import '../../model/text/slides_text.dart';
import '../../motion/timeline/motion_input.dart';
import '../../motion/timeline/slide_frame.dart';
import '../../motion/timeline/slide_timeline.dart';
import '../../scene/builder/slide_scene_builder.dart';
import '../../scene/nodes/code_scene.dart';
import '../../scene/nodes/scene_nodes.dart';
import '../../scene/nodes/text_layout.dart';
import '../../text_layout/slide_text_layout.dart';
import '../../theme/layout/placeholder_type.dart';
import '../../theme/resolve/resolved_theme.dart';
import 'frame_scenes.dart';
import 'pdf_image_prep.dart';
import 'pdf_options_codec.dart';
import 'pdf_page_plan.dart';
import 'pdf_strings.dart';
import 'slide_pdf_painter.dart';
import 'ttf_text_measurer.dart';

/// Thrown when an export is cancelled ([SlidesPdfExporter.isCancelled]).
final class SlidesPdfCancelledException implements Exception {
  /// Creates the exception.
  const SlidesPdfCancelledException();

  @override
  String toString() => 'SlidesPdfCancelledException';
}

/// Export phases reported to [SlidesPdfExporter.onProgress] (10 §11.5).
abstract final class SlidesPdfPhase {
  static const layout = 'layout';
  static const fonts = 'fonts';
  static const images = 'images';
  static const packaging = 'packaging';
}

/// A PDF document with a deterministic id (equal inputs → equal bytes).
final class _DeterministicDocument extends PdfDocument {
  _DeterministicDocument(this._id, {required super.compress})
    : super(version: PdfVersion.pdf_1_4);

  final Uint8List _id;

  @override
  Uint8List get documentID => _id;
}

/// One page to draw.
sealed class _Page {
  const _Page();
}

final class _SlidePage extends _Page {
  const _SlidePage(this.slide, this.step);
  final SlidesPdfSlide slide;
  final int? step;
}

final class _NotesPage extends _Page {
  const _NotesPage(this.slide, this.lines, {required this.continuation});
  final SlidesPdfSlide slide;
  final List<TextLineBox> lines;
  final bool continuation;
}

final class _HandoutPage extends _Page {
  const _HandoutPage(this.slides);
  final List<SlidesPdfSlide> slides;
}

/// The Slides PDF renderer.
final class SlidesPdfExporter implements SlidesPdfRenderer {
  /// Creates a renderer.
  SlidesPdfExporter({
    this.strings = const SlidesPdfStrings(),
    this.icons,
    this.charts,
    this.code,
    this.prepareLayoutFonts,
    this.onProgress,
    this.isCancelled,
    this.maxPages = 500,
    this.maxImages = 2000,
    this.compress = true,
    this.imageRunner,
  });

  /// Texts the PDF prints (bookmarks, headers, footers).
  final SlidesPdfStrings strings;

  /// Icon glyphs (the app's Lucide map; null = neutral frames).
  final SlideIconSource? icons;

  /// Chart scenes (null = a `SlideChartLayout` measuring with the
  /// embedded chart font, SL-33).
  final ChartSceneSource? charts;

  /// Code scenes (SL-26; null = the core's basic layout).
  final CodeSceneSource? code;

  /// Called with the font families of the deck before the final layout
  /// pass when [SlidesExportResources.textLayout] is given (the app loads
  /// them into its engine so the layout uses the real faces).
  final Future<void> Function(Set<String> families)? prepareLayoutFonts;

  /// Progress: phase ([SlidesPdfPhase]) and 0–1.
  final void Function(String phase, double progress)? onProgress;

  /// Polled between pages; true cancels with [SlidesPdfCancelledException].
  final bool Function()? isCancelled;

  /// Page limit (10 §11.4: 500); later pages are dropped (`page_limit`).
  final int maxPages;

  /// Image limit (10 §11.4: 2,000); later images are not drawn
  /// (`image_limit`).
  final int maxImages;

  /// Runs the image work of each source (decode, downscale, color
  /// matrix, blur, encode; CQ-44) elsewhere, e.g. in an isolate. Null
  /// runs it on this isolate in steps between turns of the event loop
  /// (web), so the page stays responsive and Cancel works.
  final SlidesPdfImageRunner? imageRunner;

  /// Deflate streams.
  final bool compress;

  /// The faces of the last export (tests).
  TtfFaceSet? debugFaces;

  void _check() {
    if (isCancelled?.call() ?? false) throw const SlidesPdfCancelledException();
  }

  final Stopwatch _slice = Stopwatch()..start();

  /// Checks for cancellation and gives the event loop a turn once 12 ms
  /// of work have passed since the last one.
  Future<void> _yield() async {
    _check();
    if (_slice.elapsedMilliseconds < 12) return;
    await Future<void>.delayed(Duration.zero);
    _slice.reset();
    _check();
  }

  @override
  Future<SlidesPdfResult> render(
    DeckModel deck,
    SlidesPdfOptions options,
    SlidesExportResources resources,
  ) async {
    final warnings = <String>{};
    final deckRec = deck.deck;
    final sw = deckRec?.width ?? 1920;
    final sh = deckRec?.height ?? 1080;
    final geo = SlidesPdfGeometry(options, slideWidth: sw, slideHeight: sh);
    onProgress?.call(SlidesPdfPhase.layout, 0);
    // Builds as pages and the final frame show what the audience sees
    // (code at its presented state); the print frame shows code complete.
    final animated = options.includeBuilds || options.finalAnimationState;
    final purpose = animated ? ScenePurpose.present : ScenePurpose.print;
    final chartShapes = SlideChartMotion.shapes(deck);

    // 1. Slides and frames: timelines from the resolved slides, compiled
    // again with the final scenes (text part boxes) once they exist.
    final resolver = SlideResolver(deck);
    final timelines = <String, SlideTimeline>{};
    Map<String, SlideScene>? sceneMap;
    SlideTimeline timeline(String id) =>
        timelines[id] ??= SlideTimelineCompiler.compile(
          SlideMotionInput.fromDeck(
            deck,
            id,
            resolved: resolver.resolve(id),
            scene: sceneMap?[id],
            chartShapeOf: chartShapes,
          ),
        );
    final selection = SlidesPdfPlanner.select(
      deck,
      options,
      stepCounts: (id) => timeline(id).stepCount,
      buildSteps: (id) => printedSteps(timeline(id)),
    );
    warnings.addAll(selection.warnings);

    SlideFrame frameOf(SlidesPdfSlide s, int? step) {
      final tl = timeline(s.slideId);
      if (step != null) return tl.endOfStep(step);
      return animated ? tl.finalFrame : tl.printFrame;
    }

    // 2. Font discovery pass (approximate metrics, recorded faces).
    final recorder = RecordingTextMeasurer();
    final recordingLayout = SlideTextLayout(measurer: recorder, cacheSize: 64);
    final firstCharts = charts ?? SlideChartLayout();
    final firstPass = _scenes(
      deck,
      resolver,
      selection,
      recordingLayout,
      purpose,
      firstCharts,
    );
    final keys = <FontFaceKey>{...recorder.keys};
    for (final s in selection.slides) {
      final scene = firstPass[s.slideId];
      final slide = resolver.resolve(s.slideId);
      if (scene == null || slide == null) continue;
      _collectFaces(scene.nodes, keys);
      // Code states and highlight steps of the printed frames (callouts).
      for (final step in s.steps) {
        final framed = SlideFrameScenes.apply(
          scene,
          frameOf(s, step),
          slide: slide,
          deck: deck,
          charts: firstCharts,
          code: code,
        );
        if (!identical(framed, scene)) _collectFaces(framed.nodes, keys);
      }
    }
    if (options.layout == SlidesPdfLayout.notes) {
      for (final s in selection.slides) {
        _notesLayout(deck, resolver, s, recordingLayout, 100);
      }
      keys.addAll(recorder.keys);
    }
    // Header/footer and chart text.
    for (final (w, i) in [
      (400, false),
      (700, false),
      (400, true),
      (700, true),
    ]) {
      keys.add(FontFaceKey(BundledFonts.openSans, w, italic: i));
    }
    await _yield();
    onProgress?.call(SlidesPdfPhase.fonts, 0.2);

    // 3. Fonts.
    final faces = await TtfFaceSet.load(
      resources.fonts,
      keys,
      fallbackText: String.fromCharCodes(recorder.runes),
      onMissing: (_) => warnings.add('font_fallback'),
    );
    debugFaces = faces;
    await _yield();

    // 4. Final layout pass.
    TextLayoutEngine layout;
    final appLayout = resources.textLayout;
    if (appLayout != null) {
      await prepareLayoutFonts?.call({for (final k in keys) k.family});
      layout = appLayout;
    } else {
      layout = SlideTextLayout(measurer: TtfTextMeasurer(faces));
    }
    final coreLayout = appLayout == null
        ? layout as SlideTextLayout
        : SlideTextLayout(measurer: TtfTextMeasurer(faces));
    final chartSource = charts ?? _chartLayout(faces);
    final scenes = _scenes(
      deck,
      resolver,
      selection,
      layout,
      purpose,
      chartSource,
    );
    sceneMap = scenes;
    timelines.clear();
    onProgress?.call(SlidesPdfPhase.layout, 0.35);
    await _yield();

    // 5. Pages.
    final pages = <_Page>[];
    switch (options.layout) {
      case SlidesPdfLayout.slides:
        for (final s in selection.slides) {
          for (final step in s.steps) {
            pages.add(_SlidePage(s, step));
          }
        }
      case SlidesPdfLayout.notes:
        for (final s in selection.slides) {
          final first = geo.notesTextArea(continuation: false);
          final more = geo.notesTextArea(continuation: true);
          final lines = _notesLayout(
            deck,
            resolver,
            s,
            coreLayout,
            first.width,
          ).lines;
          var chunk = <TextLineBox>[];
          var top = 0.0;
          var continuation = false;
          var room = first.height;
          for (final l in lines) {
            if (chunk.isNotEmpty && l.top + l.height - top > room + 0.01) {
              pages.add(_NotesPage(s, chunk, continuation: continuation));
              chunk = [];
              top = l.top;
              continuation = true;
              room = more.height;
            }
            chunk.add(l);
          }
          pages.add(_NotesPage(s, chunk, continuation: continuation));
        }
      case SlidesPdfLayout.handouts:
        final n = options.handoutsPerPage;
        final all = selection.slides;
        for (var i = 0; i < all.length; i += n) {
          pages.add(_HandoutPage(all.sublist(i, math.min(all.length, i + n))));
        }
    }
    if (pages.length > maxPages) {
      pages.removeRange(maxPages, pages.length);
      warnings.add('page_limit');
    }

    // 6. Document and images.
    final title =
        resources.info.title ??
        (deckRec == null || deckRec.title.isEmpty
            ? strings.untitledDeck
            : deckRec.title);
    final when = resources.info.modified?.toUtc() ?? DateTime.utc(2000);
    final doc = _DeterministicDocument(
      _documentId(deck.deckId, resources.info, options),
      compress: compress,
    );
    final info = PdfInfo(
      doc,
      title: title,
      author: resources.info.author,
      subject: resources.info.subject,
      creator: 'Wonky Slides',
    );
    info.params['/CreationDate'] = PdfString.fromDate(when);
    info.params['/ModDate'] = PdfString.fromDate(when);

    final ptPerSu = switch (options.layout) {
      SlidesPdfLayout.slides => geo.slideBox.width / sw,
      SlidesPdfLayout.notes => geo.notesSlideBox.width / sw,
      SlidesPdfLayout.handouts => geo.handoutCells().first.$1.width / sw,
    };
    onProgress?.call(SlidesPdfPhase.images, 0.4);
    final images = await _prepareImages(
      doc,
      scenes.values,
      resources.images,
      ptPerSu: ptPerSu,
      compact: options.compact,
      warnings: warnings,
    );
    await _yield();

    // 7. Draw.
    final fonts = SlidesPdfFonts(doc, faces);
    (PdfFont, PdfFont?, PdfFont?, PdfFont?) chartFont() => (
      fonts.fontFor(BundledFonts.openSans, 400, false) ?? fonts.standard,
      fonts.fontFor(BundledFonts.openSans, 700, false),
      fonts.fontFor(BundledFonts.openSans, 400, true),
      fonts.fontFor(BundledFonts.openSans, 700, true),
    );
    final included = selection.slideIds;
    final destinations = <String>{};
    final firstPage = <String, PdfPage>{};
    final pending = <(PdfPage, PdfRect, String)>[];
    final dateLabel =
        resources.info.dateLabel ??
        (resources.info.modified == null
            ? ''
            : _isoDate(resources.info.modified!.toLocal()));

    void addLinks(PdfPage page, PdfRect rect, String target) {
      if (!options.links) return;
      pending.add((page, rect, target));
    }

    for (var pi = 0; pi < pages.length; pi++) {
      if (pi % 4 == 3) await _yield();
      onProgress?.call(
        SlidesPdfPhase.packaging,
        0.45 + 0.5 * pi / math.max(1, pages.length),
      );
      final p = pages[pi];
      final page = PdfPage(
        doc,
        pageFormat: PdfPageFormat(geo.pageWidth, geo.pageHeight),
      );
      final painter = SlidePdfPainter(
        page: page,
        fonts: fonts,
        images: images,
        onLink: options.links ? (r, t) => addLinks(page, r, t) : null,
        chartFont: chartFont,
      );
      void drawSlide(SlidesPdfSlide s, SlidesPdfRect box, {int? step}) {
        final base = scenes[s.slideId];
        final slide = resolver.resolve(s.slideId);
        if (base == null || slide == null) return;
        final frame = frameOf(s, step);
        final scene = SlideFrameScenes.apply(
          base,
          frame,
          slide: slide,
          deck: deck,
          charts: chartSource,
          code: code,
        );
        painter.paintScene(
          scene,
          box,
          pageHeight: geo.pageHeight,
          frame: frame,
          background: !options.omitBackground,
        );
        if (options.frameSlides) _frame(painter.g, box, geo.pageHeight);
        if (options.links) {
          _elementLinks(
            deck,
            resolver,
            s.slideId,
            box,
            sw,
            geo.pageHeight,
            (r, t) => addLinks(page, r, t),
          );
        }
        if (firstPage[s.slideId] == null) {
          firstPage[s.slideId] = page;
          final name = _dest(s.slideId);
          if (destinations.add(name)) doc.pdfNames.addDest(name, page);
        }
      }

      switch (p) {
        case _SlidePage(:final slide, :final step):
          drawSlide(slide, geo.slideBox, step: step);
        case _NotesPage(slide: final s, :final lines, :final continuation):
          if (!continuation) {
            final box = geo.notesSlideBox;
            drawSlide(s, box);
            if (!options.frameSlides) _frame(painter.g, box, geo.pageHeight);
          } else {
            _label(
              painter.g,
              fonts,
              strings.notesContinued(s.entry.number ?? s.entry.index + 1),
              geo.body.x + geo.body.width * 0.1,
              geo.body.y + 12,
              geo.pageHeight,
              size: 11,
              weight: 700,
            );
          }
          final area = geo.notesTextArea(continuation: continuation);
          if (lines.isNotEmpty) {
            final top = lines.first.top;
            painter.paintScene(
              SlideScene(
                slideId: s.slideId,
                width: area.width,
                height: area.height + top,
                background: const ResolvedBackground(ResolvedNoFill(), null),
                nodes: [
                  TextNode(
                    layout: TextLayoutResult(
                      width: area.width,
                      height: area.height,
                      lines: lines,
                    ),
                    originY: -top,
                  ),
                ],
              ),
              SlidesPdfRect(area.x, area.y, area.width, area.height + top),
              pageHeight: geo.pageHeight,
            );
          }
        case _HandoutPage(:final slides):
          final cells = geo.handoutCells();
          for (var i = 0; i < slides.length && i < cells.length; i++) {
            final (box, lines) = cells[i];
            drawSlide(slides[i], box);
            if (options.slideNumbers) {
              final n = slides[i].entry.number ?? slides[i].entry.index + 1;
              _label(
                painter.g,
                fonts,
                '$n',
                box.x + box.width / 2,
                box.bottom + 11,
                geo.pageHeight,
                size: 9,
                center: true,
              );
            }
            if (lines != null) _ruled(painter.g, lines, geo.pageHeight);
          }
      }
      if (options.layout != SlidesPdfLayout.slides && options.headerFooter) {
        _headerFooter(
          painter.g,
          fonts,
          geo,
          options,
          title: title,
          date: dateLabel,
          page: pi + 1,
          count: pages.length,
        );
      }
    }
    if (pages.isEmpty) {
      // A PDF needs a page.
      PdfPage(doc, pageFormat: PdfPageFormat(geo.pageWidth, geo.pageHeight));
    }

    // 8. Links and bookmarks.
    for (final (page, rect, target) in pending) {
      final slideId = _slideTarget(target);
      if (slideId != null) {
        if (!included.contains(slideId) || firstPage[slideId] == null) {
          warnings.add('link_dropped');
          continue;
        }
        PdfAnnot(
          page,
          PdfAnnotNamedLink(
            rect: rect,
            dest: _dest(slideId),
            border: PdfBorder(doc, 0),
          ),
        );
      } else if (_isUrl(target)) {
        PdfAnnot(
          page,
          PdfAnnotUrlLink(rect: rect, url: target, border: PdfBorder(doc, 0)),
        );
      }
    }
    if (options.bookmarks) {
      _bookmarks(doc, deck, selection, firstPage, geo);
    }

    warnings.addAll(fonts.warnings);
    onProgress?.call(SlidesPdfPhase.packaging, 0.97);
    // Written on this isolate (no copy of the object graph; cooperative on
    // the web).
    final out = PdfStream();
    await doc.write(out, enableEventLoopBalancing: true);
    final bytes = out.output();
    onProgress?.call(SlidesPdfPhase.packaging, 1);
    return SlidesPdfResult(
      bytes: bytes,
      pageCount: math.max(1, pages.length),
      warnings: warnings.toList(),
    );
  }

  // -----------------------------------------------------------------------
  // Scenes and text

  /// The steps of [tl] printed with builds as pages (06 §9.6): every
  /// step whose settled frame differs from the previous step's (an empty
  /// automatic step 0 prints the initial frame; a step that changes
  /// nothing visible is not a page of its own).
  static List<int> printedSteps(SlideTimeline tl) {
    final out = <int>[];
    String? previous;
    for (var i = 0; i <= tl.stepCount; i++) {
      final key = jsonEncode(tl.endOfStep(i).toJson());
      if (key != previous) out.add(i);
      previous = key;
    }
    return out;
  }

  /// A chart layout measuring with the chart font the PDF draws with
  /// (Open Sans; 08 §12): chart text fits exactly as printed.
  static ChartSceneSource _chartLayout(TtfFaceSet faces) {
    TtfChartFace? face(int weight, bool italic) {
      final f = faces.faceOf(BundledFonts.openSans, weight, italic);
      return f == null ? null : TtfChartFace(f.face.bytes);
    }

    final regular = face(400, false);
    if (regular == null) return SlideChartLayout();
    return SlideChartLayout(
      measurer: TtfChartTextMeasurer(
        TtfChartFamily(
          regular,
          bold: face(700, false),
          italic: face(400, true),
          boldItalic: face(700, true),
        ),
      ),
    );
  }

  Map<String, SlideScene> _scenes(
    DeckModel deck,
    SlideResolver resolver,
    SlidesPdfSelection selection,
    TextLayoutEngine layout,
    ScenePurpose purpose,
    ChartSceneSource charts,
  ) {
    final builder = SlideSceneBuilder();
    final out = <String, SlideScene>{};
    for (final s in selection.slides) {
      if (out.containsKey(s.slideId)) continue;
      final slide = resolver.resolve(s.slideId);
      if (slide == null) continue;
      out[s.slideId] = builder.build(
        slide,
        SceneContext(
          theme: slide.theme,
          textLayout: layout,
          deck: deck,
          purpose: purpose,
          icons: icons,
          charts: charts,
          code: code,
        ),
      );
    }
    return out;
  }

  static void _collectFaces(List<SceneNode> nodes, Set<FontFaceKey> keys) {
    for (final n in nodes) {
      switch (n) {
        case TextNode(:final layout):
          for (final line in layout.lines) {
            for (final r in [?line.bullet, ...line.runs]) {
              keys.add(TtfFaceSet.keyOf(r.fontFamily, r.fontWeight, r.italic));
            }
          }
        case CodeNode(:final scene):
          _codeFaces(scene, keys);
        case GroupNode(:final children):
          _collectFaces(children, keys);
        default:
          break;
      }
    }
  }

  static void _codeFaces(CodeScene scene, Set<FontFaceKey> keys) {
    final family = scene.fontFamily;
    keys.add(TtfFaceSet.keyOf(family, 400, false));
    for (final l in scene.lines) {
      for (final r in l.runs) {
        keys.add(TtfFaceSet.keyOf(family, r.bold ? 700 : 400, r.italic));
      }
    }
    for (final g in scene.glyphs) {
      keys.add(TtfFaceSet.keyOf(family, g.bold ? 700 : 400, g.italic));
    }
    // Callouts: inline Markdown in the body font, `code` in the mono font.
    for (final c in scene.callouts) {
      final f = c.fontFamily.isEmpty ? family : c.fontFamily;
      for (final (w, i) in [(400, false), (700, false), (400, true)]) {
        keys.add(TtfFaceSet.keyOf(f, w, i));
      }
    }
    if (scene.underlay case final u?) _codeFaces(u, keys);
  }

  /// The speaker notes of [s] laid out [width] pt wide (deck theme body
  /// font, 12 pt, dark gray: notes print as text, 10 §11.2).
  TextLayoutResult _notesLayout(
    DeckModel deck,
    SlideResolver resolver,
    SlidesPdfSlide s,
    SlideTextLayout layout,
    double width,
  ) {
    final rec = deck.slide(s.slideId);
    final body = TextBody.fromJson(rec?.notes);
    if (body.isBlank) return TextLayoutResult.empty;
    final theme = resolver.resolve(s.slideId)?.theme;
    if (theme == null) return TextLayoutResult.empty;
    final base = theme.textStyle('body');
    final notes = ResolvedTextStyle(
      key: 'notes',
      font: base.font,
      size: 12,
      lineHeight: 1.35,
      letterSpacing: 0,
      color: 0xff1f2937,
      caps: null,
      align: 'left',
      spaceBefore: 0,
      spaceAfter: 6,
    );
    return layout.layout(
      body,
      ResolvedTextStyles(
        styles: {...theme.textStyles, 'notes': notes},
        defaultStyle: 'notes',
        theme: theme,
      ),
      width: width,
    );
  }

  // -----------------------------------------------------------------------
  // Images

  Future<Map<String, SlidesPdfImage>> _prepareImages(
    PdfDocument doc,
    Iterable<SlideScene> scenes,
    SlideImageResolver resolver, {
    required double ptPerSu,
    required bool compact,
    required Set<String> warnings,
  }) async {
    // Variants by key: (src, matrix, blur, largest drawn width in su).
    final variants = <String, (String, List<double>?, double, double)>{};
    void want(String src, List<double>? m, double blur, double widthSu) {
      final key = slidesPdfImageKey(src, matrix: m, blur: blur);
      final prev = variants[key];
      variants[key] = (src, m, blur, math.max(prev?.$4 ?? 0, widthSu));
    }

    void wantFill(ResolvedFill? f, double widthSu) {
      if (f is ResolvedImageFill) {
        want('${SlideImageRef.fileScheme}${f.fileUuid}', null, 0, widthSu);
      }
    }

    void walk(List<SceneNode> nodes) {
      for (final n in nodes) {
        switch (n) {
          case ImageNode():
            want(n.image.src, n.colorMatrix, n.blurSigma, n.dst.width);
          case PathNode(:final fill?):
            wantFill(fill, 1920);
          case GroupNode(:final children):
            walk(children);
          default:
            break;
        }
      }
    }

    for (final s in scenes) {
      wantFill(s.background.fill, s.width);
      wantFill(s.background.overlay, s.width);
      walk(s.nodes);
    }
    // Variants grouped by source: each source is fetched and decoded once
    // (CQ-44), in order of first use.
    final dpi = compact ? 150.0 : 300.0;
    final bySource = <String, List<(String, SlidesPdfImageVariant)>>{};
    var count = 0;
    for (final MapEntry(:key, :value) in variants.entries) {
      if (count >= maxImages) {
        warnings.add('image_limit');
        break;
      }
      count++;
      final (src, matrix, blur, widthSu) = value;
      (bySource[src] ??= []).add((
        key,
        SlidesPdfImageVariant(
          matrix: matrix,
          blur: blur,
          widthSu: widthSu,
          maxPx: math.max(64, (widthSu * ptPerSu / 72 * dpi).ceil()),
        ),
      ));
    }

    final out = <String, SlidesPdfImage>{};
    for (final MapEntry(key: src, value: wanted) in bySource.entries) {
      await _yield();
      final ref = SlideImageRef(src);
      Uint8List? bytes;
      try {
        bytes = resolver.cachedBytes(ref) ?? await resolver.bytes(ref);
      } on Object {
        bytes = null;
      }
      if (bytes == null || bytes.isEmpty) {
        warnings.add('image_missing');
        continue;
      }
      final job = <(String, SlidesPdfImageVariant)>[];
      for (final (key, v) in wanted) {
        try {
          // JPEGs drawn as they are go in unchanged.
          if (v.matrix == null &&
              v.blur <= 0 &&
              !compact &&
              img.JpegDecoder().isValidFile(bytes)) {
            final pi = PdfImage.jpeg(doc, image: bytes);
            out[key] = SlidesPdfImage(pi, pi.width, pi.height);
            continue;
          }
        } on Object {
          warnings.add('image_invalid');
          continue;
        }
        job.add((key, v));
      }
      if (job.isEmpty) continue;
      final request = SlidesPdfImageJob(bytes, [
        for (final (_, v) in job) v,
      ], compact: compact);
      final List<SlidesPdfPreparedImage?> prepared;
      try {
        prepared =
            await (imageRunner?.call(request) ??
                SlidesPdfImagePrep.run(request, yieldNow: _yield));
      } on SlidesPdfCancelledException {
        rethrow;
      } on Object {
        if (isCancelled?.call() ?? false) {
          throw const SlidesPdfCancelledException();
        }
        warnings.add('image_invalid');
        continue;
      }
      _check();
      for (final (i, (key, _)) in job.indexed) {
        final p = i < prepared.length ? prepared[i] : null;
        if (p == null) {
          warnings.add('image_invalid');
          continue;
        }
        try {
          final pi = p.jpeg != null
              ? PdfImage.jpeg(doc, image: p.jpeg!)
              : PdfImage(doc, image: p.rgba!, width: p.width, height: p.height);
          out[key] = SlidesPdfImage(pi, p.width, p.height);
        } on Object {
          warnings.add('image_invalid');
        }
      }
    }
    return out;
  }

  // -----------------------------------------------------------------------
  // Links, bookmarks, chrome

  static String _dest(String slideId) => 'slide-$slideId';

  /// The slide id of a slide link (`slide:<id>`, `wonky://slide/<id>`).
  static String? _slideTarget(String target) {
    if (target.startsWith('slide:')) return target.substring(6);
    const scheme = 'wonky://slide/';
    if (target.startsWith(scheme)) return target.substring(scheme.length);
    return null;
  }

  static bool _isUrl(String target) {
    final u = Uri.tryParse(target);
    return u != null &&
        (u.scheme == 'https' || u.scheme == 'http' || u.scheme == 'mailto');
  }

  /// Click actions of top-level slide elements (`linkJson`: url or slide).
  void _elementLinks(
    DeckModel deck,
    SlideResolver resolver,
    String slideId,
    SlidesPdfRect box,
    double slideWidth,
    double pageHeight,
    void Function(PdfRect rect, String target) sink,
  ) {
    final s = box.width / slideWidth;
    final slide = resolver.resolve(slideId);
    if (slide == null) return;
    for (final e in slide.elements) {
      final raw = e.record.linkJson;
      if (raw == null || raw.isEmpty) continue;
      Object? link;
      try {
        link = jsonDecode(raw);
      } on FormatException {
        continue;
      }
      if (link is! Map) continue;
      final target = link['url'] is String
          ? link['url'] as String
          : link['slideId'] is String
          ? 'slide:${link['slideId']}'
          : null;
      if (target == null) continue;
      final f = e.frame;
      sink(
        PdfRect(
          box.x + f.x * s,
          pageHeight - box.y - (f.y + f.height) * s,
          f.width * s,
          f.height * s,
        ),
        target,
      );
    }
  }

  void _bookmarks(
    PdfDocument doc,
    DeckModel deck,
    SlidesPdfSelection selection,
    Map<String, PdfPage> firstPage,
    SlidesPdfGeometry geo,
  ) {
    PdfOutline? group;
    String? groupId;
    for (final s in selection.slides) {
      final page = firstPage[s.slideId];
      if (page == null) continue;
      final number = s.entry.number ?? s.entry.index + 1;
      final title = _slideTitle(deck, s.slideId);
      PdfOutline item() => PdfOutline(
        doc,
        title: title.isEmpty ? strings.slide(number) : title,
        dest: page,
        destMode: PdfOutlineMode.fitPage,
      );
      final gid = s.entry.groupId;
      if (gid == null) {
        doc.outline.add(item());
        group = null;
        groupId = null;
        continue;
      }
      if (gid != groupId || group == null) {
        final g = deck.group(gid);
        group = PdfOutline(
          doc,
          title: g == null || g.title.isEmpty ? strings.untitledGroup : g.title,
          dest: page,
          destMode: PdfOutlineMode.fitPage,
        );
        doc.outline.add(group);
        groupId = gid;
      }
      group.add(item());
    }
  }

  /// The plain text of the slide's title placeholder.
  static String _slideTitle(DeckModel deck, String slideId) {
    for (final e in deck.elementsOf(slideId)) {
      final t = e.placeholderType;
      if (t == SlidePlaceholderType.title) {
        return SlidesText.plainText(e.text).trim().split('\n').first;
      }
    }
    return '';
  }

  static void _frame(PdfGraphics g, SlidesPdfRect box, double pageHeight) {
    g
      ..saveContext()
      ..setStrokeColor(const PdfColor(0.62, 0.64, 0.68))
      ..setLineWidth(0.5)
      ..drawRect(box.x, pageHeight - box.bottom, box.width, box.height)
      ..strokePath()
      ..restoreContext();
  }

  static void _ruled(PdfGraphics g, SlidesPdfRect area, double pageHeight) {
    g
      ..saveContext()
      ..setStrokeColor(const PdfColor(0.75, 0.77, 0.8))
      ..setLineWidth(0.5);
    for (var y = area.y + 24; y <= area.bottom; y += 24) {
      g
        ..moveTo(area.x, pageHeight - y)
        ..lineTo(area.right, pageHeight - y);
    }
    g
      ..strokePath()
      ..restoreContext();
  }

  /// Draws [text] with its baseline at ([x], [y]) (top-left page coords).
  static void _label(
    PdfGraphics g,
    SlidesPdfFonts fonts,
    String text,
    double x,
    double y,
    double pageHeight, {
    double size = 9,
    int weight = 400,
    bool center = false,
    bool right = false,
  }) {
    final segs = fonts.segments(text, BundledFonts.openSans, weight, false);
    if (segs.isEmpty) return;
    final width = segs.fold(0.0, (a, s) => a + s.advanceEm) * size;
    var cx = center ? x - width / 2 : (right ? x - width : x);
    g
      ..saveContext()
      ..setFillColor(const PdfColor(0.42, 0.45, 0.5));
    for (final s in segs) {
      g.drawString(s.font, size, s.text, cx, pageHeight - y);
      cx += s.advanceEm * size;
    }
    g.restoreContext();
  }

  void _headerFooter(
    PdfGraphics g,
    SlidesPdfFonts fonts,
    SlidesPdfGeometry geo,
    SlidesPdfOptions o, {
    required String title,
    required String date,
    required int page,
    required int count,
  }) {
    final c = geo.content;
    final top = c.y + 12;
    if (o.headerTitle) _label(g, fonts, title, c.x, top, geo.pageHeight);
    if (o.headerDate && date.isNotEmpty) {
      _label(g, fonts, date, c.right, top, geo.pageHeight, right: true);
    }
    if (o.pageNumbers) {
      _label(
        g,
        fonts,
        strings.pageOf(page, count),
        c.x + c.width / 2,
        c.bottom - 6,
        geo.pageHeight,
        center: true,
      );
    }
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static Uint8List _documentId(
    String deckId,
    SlidesPdfDocumentInfo info,
    SlidesPdfOptions options,
  ) => Uint8List.fromList(
    sha256
        .convert(
          utf8.encode(
            [
              'wonky-slides-pdf/1',
              deckId,
              info.revision ?? '',
              info.modified?.toUtc().toIso8601String() ?? '',
              jsonEncode(SlidesPdfOptionsCodec.toJson(options)),
            ].join('|'),
          ),
        )
        .bytes
        .sublist(0, 16),
  );
}
