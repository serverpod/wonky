@Tags(['golden'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_slides/features/stage/slide_renderer.dart';
import 'package:wonky_slides/features/themes/theme_previews.dart';
import 'package:wonky_slides/features/thumbnails/slide_thumbnail.dart';
import 'package:wonky_slides_core/themes.dart';

import '../../features/text_editing/text_edit_fixture.dart' show realFonts;

/// Golden images of the Themes panel card of the default theme *Wonky*
/// (the theme of *Blank* presentations): a plain title slide with no
/// decorations, in light and dark (report #19, T-17; 05 §6, §9). Masters
/// are made and compared on CI Linux only (specs/15 §7): run locally with
/// `-x golden`.
void main() {
  for (final appearance in SlideAppearance.values) {
    testWidgets('wonky theme card ${appearance.name}', (tester) async {
      await tester.runAsync(() => realFonts.ensureAll(SlidesFonts.families));
      final deck = ThemePreviewDeck.builtIn(
        'wonky',
        SlideSize.widescreen,
        subtitle: 'Subtitle',
      );
      addTearDown(deck.dispose);
      final renderer = SlideRenderer(
        model: deck.renderer.model,
        fonts: realFonts,
      );
      addTearDown(renderer.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('card'),
              child: SlideThumbnail(
                renderer: renderer,
                slideId: deck.cardSlideId!,
                width: 384,
                appearance: appearance,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(const ValueKey('card')),
        matchesGoldenFile('wonky_theme_card_${appearance.name}.png'),
      );
    });
  }
}
