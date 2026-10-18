import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart' show PdfDocument, PdfFont;
import 'package:wonky_sheets_core/model.dart';

import '../formatting/cell_fonts.dart';

/// PDF fonts of the client (11 §7.4): the bundled static TTFs (Roboto,
/// Lato and Roboto Mono as themselves, Open Sans for the other sans
/// families incl. Inter/Geist whose variable faces the PDF writer can't
/// instance, EB Garamond for serif, JetBrains Mono for mono), the same
/// faces the preview paints with — so preview and PDF share metrics.
/// Without the assets (tests) the standard PDF fonts are used.
class SheetsPdfFonts implements PdfFontProvider {
  SheetsPdfFonts._(this._provider);

  final PdfFontProvider _provider;

  static const sans = BundledPdfFonts.sans;
  static const serif = BundledPdfFonts.serif;
  static const mono = BundledPdfFonts.mono;

  static Future<SheetsPdfFonts>? _instance;

  /// Loads the fonts once (falls back to the built-in PDF fonts).
  static Future<SheetsPdfFonts> load() => _instance ??= _load();

  static Future<SheetsPdfFonts> _load() async {
    Future<ByteData?> asset(String f) async {
      try {
        return await rootBundle.load('$fontAssetDir/$f');
      } catch (_) {
        return null;
      }
    }

    final provider = await BundledPdfFonts.load(asset);
    if (provider is! BuiltInPdfFontProvider) {
      await Future.wait([
        for (final f in BundledPdfFonts.files.keys) CellFonts.ensureLoaded(f),
      ]);
    }
    return SheetsPdfFonts._(provider);
  }

  /// The PDF family of a cell family: the static bundled families as
  /// themselves, others serif/mono by category, every other family sans
  /// (`BundledPdfFonts.pdfFamily`, the same mapping as server PDFs).
  static String pdfFamily(String family) => BundledPdfFonts.pdfFamily(family);

  /// The Flutter family the preview paints [family] with (the PDF face).
  static String screenFamily(String family) =>
      CellFonts.screenFamily(pdfFamily(family));

  @override
  PdfFont font(
    PdfDocument doc,
    String family, {
    bool bold = false,
    bool italic = false,
  }) => _provider.font(doc, family, bold: bold, italic: italic);

  @override
  List<PdfFont> fallbacks(
    PdfDocument doc, {
    bool bold = false,
    bool italic = false,
  }) => _provider.fallbacks(doc, bold: bold, italic: italic);
}
