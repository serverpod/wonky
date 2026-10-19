import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/themes/theme_previews.dart';
import 'package:wonky_slides_core/themes.dart';

/// The Themes panel card of the default theme *Wonky*, which *Blank*
/// presentations use, is plain: below the title and subtitle every pixel is
/// the `bg1` background, in both appearances (report #19, T-17; 05 §6, §9).
void main() {
  const width = 384, height = 216;
  // Below the subtitle placeholder (624 + 144 su of 1080) to the bottom
  // edge, the whole width: where v1 drew its gradient blob.
  const top = 800 * height ~/ 1080;

  for (final (appearance, bg1) in [
    (SlideAppearance.light, const Color(0xFFFFFFFF)),
    (SlideAppearance.dark, const Color(0xFF0B1020)),
  ]) {
    testWidgets('Given the built-in Wonky card (${appearance.name}) when it '
        'is drawn then the area below the title is plain bg1', (tester) async {
      final deck = ThemePreviewDeck.builtIn(
        'wonky',
        SlideSize.widescreen,
        subtitle: 'Subtitle',
      );
      addTearDown(deck.dispose);

      final thumb = deck.renderer.thumbnail(
        deck.cardSlideId!,
        width: width.toDouble(),
        appearance: appearance,
      )!;
      final bytes = (await tester.runAsync(() async {
        final image = await thumb.picture.toImage(width, height);
        final data = await image.toByteData();
        image.dispose();
        return data;
      }))!;

      final off = <String>{};
      for (var y = top; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final i = (y * width + x) * 4;
          final c = Color.fromARGB(
            bytes.getUint8(i + 3),
            bytes.getUint8(i),
            bytes.getUint8(i + 1),
            bytes.getUint8(i + 2),
          );
          if (c != bg1) off.add('($x, $y) ${c.toARGB32().toRadixString(16)}');
        }
      }
      expect(off.take(5), isEmpty, reason: '${off.length} pixels differ');
    });
  }
}
