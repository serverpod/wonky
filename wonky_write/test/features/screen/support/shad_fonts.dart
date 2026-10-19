import 'package:flutter/services.dart';

/// Loads shad's bundled UI font (Geist) so widget tests lay text out with
/// real glyph widths instead of the test font's square glyphs, which make
/// labels that fit in the app overflow fixed-width dialogs and popovers.
/// Call from `setUpAll`.
Future<void> loadShadFonts() async {
  final geist = FontLoader('packages/shad/Geist')
    ..addFont(rootBundle.load('packages/shad/fonts/Geist[wght].ttf'));
  await geist.load();
}
