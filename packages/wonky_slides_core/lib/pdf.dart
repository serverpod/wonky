/// Slides PDF export (specs/wonky_slides/10 §11, 12 §4 SL-20): the pure-Dart
/// `SlidesPdfRenderer` ([SlidesPdfExporter]) shared by the app's print
/// preview and the server's `slidesExport`, the options codec, page
/// planning, the content of settled timeline frames ([SlideFrameScenes]:
/// builds as pages, SL-33), and the TTF metrics measurer of the core text
/// layout ([TtfTextMeasurer], [BundledFileFontProvider]).
///
/// Pure Dart (on the `pdf` and `image` packages).
library;

export 'src/export/pdf/frame_scenes.dart';
export 'src/export/pdf/pdf_image_prep.dart';
export 'src/export/pdf/pdf_options_codec.dart';
export 'src/export/pdf/pdf_page_plan.dart';
export 'src/export/pdf/pdf_strings.dart';
export 'src/export/pdf/slide_pdf_painter.dart'
    show SlidesPdfFonts, PdfTextSegment, SlidesPdfImage, slidesPdfImageKey;
export 'src/export/pdf/slides_pdf_exporter.dart';
export 'src/export/pdf/ttf_text_measurer.dart';
