import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_sheets/commands/format_commands.dart';
import 'package:wonky_sheets/features/formatting/cell_fonts.dart';
import 'package:wonky_sheets/features/print/print_fonts.dart';
import 'package:wonky_sheets_core/model.dart';
import 'package:wonky_sheets_core/model_testing.dart';

/// Every TTF the PDF font set names (one file per family face).
Set<String> _pdfFiles() => {for (final f in BundledPdfFonts.files.values) ...f};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Given the bundled cell fonts', () {
    const asThemselves = [
      ('Source Sans 3', CellFonts.sourceSans3),
      ('Nunito', CellFonts.nunito),
      ('Montserrat', CellFonts.montserrat),
      ('Merriweather', CellFonts.merriweather),
      ('montserrat', CellFonts.montserrat),
      ('Source Sans Pro', CellFonts.sourceSans3),
      ('roboto mono', CellFonts.robotoMono),
    ];
    for (final (family, shown) in asThemselves) {
      test('when showing "$family" then it renders with $shown', () {
        expect(CellFonts.displayFamily(family), shown);
      });
    }

    const substituted = [
      ('Courier Prime', CellFonts.jetBrainsMono),
      ('Courier New', CellFonts.jetBrainsMono),
      ('Poppins', CellFonts.lato),
      ('Lora', CellFonts.ebGaramond),
      ('Arial', CellFonts.inter),
    ];
    for (final (family, shown) in substituted) {
      test('when showing unbundled "$family" then it renders with $shown', () {
        expect(CellFonts.isBundled(family), isFalse);
        expect(CellFonts.displayFamily(family), shown);
      });
    }

    test('when listing the font menu then the new families are offered and '
        'Courier Prime is not', () {
      expect(
        CellFonts.bundled,
        containsAll(['Source Sans 3', 'Nunito', 'Montserrat', 'Merriweather']),
      );
      expect(CellFonts.bundled, isNot(contains('Courier Prime')));
      expect(sheetsCellFonts, isNot(contains('Courier Prime')));
    });

    test('when reading the theme presets then every preset font is bundled '
        'and monospace presets use JetBrains Mono', () {
      final fonts = {
        for (final p in SpreadsheetTheme.presets) p.name: p.textFont,
      };

      expect(fonts.values.where((f) => !CellFonts.isBundled(f)), isEmpty);
      expect(fonts['Mono'], CellFonts.jetBrainsMono);
      expect(fonts['Retro'], CellFonts.jetBrainsMono);
    });

    test('when mapping the new families for PDF then they embed as '
        'themselves', () {
      expect(SheetsPdfFonts.pdfFamily('Merriweather'), 'Merriweather');
      expect(SheetsPdfFonts.pdfFamily('Montserrat'), 'Montserrat');
      expect(SheetsPdfFonts.pdfFamily('Nunito'), 'Nunito');
      expect(SheetsPdfFonts.pdfFamily('Source Sans 3'), 'Source Sans 3');
      expect(SheetsPdfFonts.pdfFamily('Courier Prime'), SheetsPdfFonts.mono);
    });

    test('when loading the PDF faces then each is a real TTF asset', () async {
      for (final f in _pdfFiles()) {
        final bytes = await rootBundle.load('$fontAssetDir/$f');
        // sfnt version 1.0 (TrueType outlines).
        expect(bytes.getUint32(0), 0x00010000, reason: f);
      }
    });

    test('when comparing with the server copies then web/fonts holds the '
        'same files', () async {
      for (final f in _pdfFiles()) {
        final app = await rootBundle.load('$fontAssetDir/$f');
        final server = File('../wonky_server/web/fonts/$f').readAsBytesSync();
        expect(
          server,
          equals(app.buffer.asUint8List(app.offsetInBytes, app.lengthInBytes)),
          reason: f,
        );
      }
    });
  });

  group('Given cells in the new families exported as PDF', () {
    late WorkbookModel m;
    setUp(() {
      final b = WorkbookBuilder()..sheet('Sheet1', rows: 20, cols: 5);
      b.value(
        'A1',
        'Montserrat bold',
        format: {FormatAttr.fontFamily: 'Montserrat', FormatAttr.bold: true},
      );
      b.value(
        'A2',
        'Source Sans italic',
        format: {
          FormatAttr.fontFamily: 'Source Sans 3',
          FormatAttr.italic: true,
        },
      );
      b.value(
        'A3',
        'Merriweather',
        format: {FormatAttr.fontFamily: 'Merriweather'},
      );
      b.value(
        'A4',
        'Nunito bold italic',
        format: {
          FormatAttr.fontFamily: 'Nunito',
          FormatAttr.bold: true,
          FormatAttr.italic: true,
        },
      );
      m = b.build();
    });

    test('when rendering with the bundled fonts then the PDF embeds their '
        'static faces', () async {
      final fonts = await SheetsPdfFonts.load();

      final pdf = latin1.decode(
        await SheetsPdfRenderer.render(
          m,
          ModelCellSource(m),
          Paginator.paginate(m, const PrintJob()),
          now: DateTime.utc(2026, 10, 14),
          fonts: fonts,
          compress: false,
        ),
      );

      expect(pdf, contains('Montserrat-Bold'));
      expect(pdf, contains('WonkySansThree-Italic'));
      expect(pdf, contains('Merriweather-Regular'));
      expect(pdf, contains('Nunito-BoldItalic'));
    });
  });
}
