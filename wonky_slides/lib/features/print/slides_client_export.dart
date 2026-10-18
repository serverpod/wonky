import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:wonky_app/fonts.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_fonts/wonky_fonts.dart' show BundledFonts, FontProvider;
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_slides_core/model.dart' show DeckModel;
import 'package:wonky_slides_core/pdf.dart';
import 'package:wonky_slides_core/scene.dart' show TextLayoutEngine;

import '../../l10n/slides_l10n.dart';
import '../stage/flutter_text_layout_engine.dart';
import 'pdf_image_isolate.dart';

/// Client-side Slides PDF export (10 §11.4: offline and ≤ 80 pages run in
/// the app): the shared `SlidesPdfExporter` with the bundled TTFs read from
/// the `wonky_fonts` package assets (the same files and family mapping as
/// the server), the open deck's images, localized PDF texts and — so the
/// PDF breaks lines exactly like the stage — the app's Flutter text layout
/// engine with the deck's fonts registered first (10 §11.3 "As built").
abstract final class SlidesClientExport {
  static BundledFileFontProvider? _fonts;

  /// Whether PDF image work runs in an isolate (native platforms; killed
  /// on Cancel, CQ-44). Off on the web, where the exporter time-slices
  /// it, and in widget tests (fake async).
  static bool useImageIsolate = !kIsWeb;

  /// The bundled-font provider over the package assets (bytes cached).
  static BundledFileFontProvider get fonts => _fonts ??= assetFonts();

  /// A new provider over the package assets (its own byte cache).
  static BundledFileFontProvider assetFonts() => BundledFileFontProvider((
    file,
  ) async {
    try {
      final data = await rootBundle.load(BundledFonts.assetKey(file));
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } on Object {
      return null;
    }
  });

  /// The PDF texts in the user's language.
  static SlidesPdfStrings strings(SlidesLocalizations l) => SlidesPdfStrings(
    slide: l.pdfSlide,
    notesContinued: l.pdfNotesContinued,
    pageOf: l.pdfPageOf,
    untitledGroup: l.pdfUntitledSection,
    untitledDeck: l.pdfUntitledPresentation,
  );

  /// Renders [deck] with [options].
  ///
  /// [screenLayout] lays text out with the Flutter engine (fonts loaded
  /// through [AssetFontRegistry] first); false uses the core TTF layout (the
  /// server's), e.g. in tests.
  static Future<SlidesPdfResult> render(
    DeckModel deck,
    SlidesPdfOptions options, {
    required SlideImageResolver images,
    required SlidesLocalizations l,
    SlidesPdfDocumentInfo info = const SlidesPdfDocumentInfo(),
    bool screenLayout = true,
    FontProvider? fonts,
    void Function(String phase, double progress)? onProgress,
    bool Function()? isCancelled,
  }) {
    TextLayoutEngine? layout;
    Future<void> Function(Set<String>)? prepare;
    if (screenLayout) {
      final registry = AssetFontRegistry.instance;
      layout = FlutterTextLayoutEngine(fontGeneration: registry.generation);
      prepare = registry.ensureAll;
    }
    return SlidesPdfExporter(
      strings: strings(l),
      prepareLayoutFonts: prepare,
      onProgress: onProgress,
      isCancelled: isCancelled,
      imageRunner: useImageIsolate ? isolateImageRunner(isCancelled) : null,
    ).render(
      deck,
      options,
      SlidesExportResources(
        fonts: fonts ?? SlidesClientExport.fonts,
        images: images,
        textLayout: layout,
        info: info,
      ),
    );
  }

  /// The last-used options of the user (`slidesDefaults.exportOptions`,
  /// A-10-4), with the defaults of their layout for [locale].
  static SlidesPdfOptions lastUsed(ShellServices s, {String? locale}) {
    final raw = s.prefs.slidesDefaults['exportOptions'];
    return SlidesPdfOptionsCodec.fromJson(
      raw is Map ? raw.cast<String, Object?>() : const {},
      locale: locale,
    );
  }

  /// Remembers [o] as the user's last-used options.
  static Future<void> remember(ShellServices s, SlidesPdfOptions o) =>
      s.prefs.setSlidesDefault(
        'exportOptions',
        SlidesPdfOptionsCodec.toPreferences(o),
      );

  /// Saves [bytes] as [fileName] (PDF, PNG or ZIP by extension): a
  /// browser download in this tab on the web (no new tab or window), the
  /// save dialog on desktop. False when the dialog was cancelled.
  static Future<bool> save(Uint8List bytes, {required String fileName}) =>
      saver(bytes, fileName);

  /// The file saver ([save]; tests record instead of opening dialogs).
  static Future<bool> Function(Uint8List bytes, String fileName) saver =
      _saveFile;

  static Future<bool> _saveFile(Uint8List bytes, String fileName) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeTypeOf(fileName),
      dialogTitle: fileName,
    );
    return kIsWeb || uri != null;
  }

  /// The media type of an export file by its extension (PDF, PNG, ZIP).
  static String mimeTypeOf(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.zip')) return 'application/zip';
    return 'application/pdf';
  }

  /// The user-facing text of an export warning code.
  static String warning(SlidesLocalizations l, String code) => switch (code) {
    'font_fallback' => l.printWarningFonts,
    'glyph_missing' => l.printWarningGlyphs,
    'icon_unavailable' => l.printWarningIcons,
    'image_missing' || 'image_invalid' || 'image_limit' => l.printWarningImages,
    'link_dropped' => l.printWarningLinks,
    'page_limit' => l.printWarningPages,
    'empty_selection' => l.printWarningEmpty,
    _ => code,
  };
}
