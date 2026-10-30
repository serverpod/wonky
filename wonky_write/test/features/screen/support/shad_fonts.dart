import 'package:flutter/services.dart';

/// Loads the UI font (Geist, bundled with `wonky_ui`) so widget tests lay text out with
/// real glyph widths instead of the test font's square glyphs, which make
/// labels that fit in the app overflow fixed-width dialogs and popovers.
/// Call from `setUpAll`.
Future<void> loadShadFonts() async {
  final geist = FontLoader('packages/wonky_ui/Geist')
    ..addFont(rootBundle.load('packages/wonky_ui/fonts/Geist[wght].ttf'));
  await geist.load();
}
