import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_slides/features/print/print_controller.dart';
import 'package:wonky_slides/l10n/slides_l10n.dart';
import 'package:wonky_slides_core/interfaces.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart' show sampleDeck;
import 'print_rig.dart';

/// The print / PDF preview route (Slides 10 §12; SL-20).
void main() {
  final l = slidesL10nEnglish;
  Finder key(String k) => find.byKey(ValueKey<String>(k));

  for (final brightness in Brightness.values) {
    testWidgets('Given a deck with a skipped slide in the ${brightness.name} '
        'theme when the print preview opens then the PDF of the 3 presented '
        'slides is shown with the settings column', (tester) async {
      final r = await pumpPrintPreview(tester, brightness: brightness);

      expect(key('slides.print'), findsOneWidget);
      expect(key('slides.print.preview'), findsOneWidget);
      expect(key('slides.print.settings'), findsOneWidget);
      expect(find.text(l.printPageCount(3)), findsOneWidget);
      expect(
        find.text(l.printPreviewTitleWithName('Q3 review')),
        findsOneWidget,
      );
      expect(find.text(l.printDownloadPdf), findsOneWidget);
      expect(r.controller.pdf!.sublist(0, 5), '%PDF-'.codeUnits);
      expect(tester.takeException(), isNull);
      await settleTooltips(tester);
      await r.close(tester);
    });
  }

  testWidgets('Given the preview at 360 px when settings are toggled then the '
      'settings replace the preview without overflow', (tester) async {
    final r = await pumpPrintPreview(tester, size: const Size(360, 720));

    expect(key('slides.print.preview'), findsOneWidget);
    expect(key('slides.print.settings'), findsNothing);
    await tester.tap(key('slides.print.toggleSettings'));
    await tester.pump();

    expect(key('slides.print.settings'), findsOneWidget);
    expect(key('slides.print.preview'), findsNothing);
    expect(find.text(l.printPreviewTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the preview when Handouts is picked then the PDF is '
      'regenerated after the debounce with one page', (tester) async {
    final r = await pumpPrintPreview(tester);

    await tester.tap(key('slides.print.layout.handouts'));
    await tester.pump();
    expect(r.controller.options.layout, SlidesPdfLayout.handouts);
    expect(r.controller.options.frameSlides, isTrue);
    await r.settle(
      tester,
      () => r.controller.pageCount == 1 && !r.controller.busy,
    );

    expect(find.text(l.printPageCount(1)), findsOneWidget);
    expect(key('slides.print.perPage.6'), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the preview when skipped slides are included then all '
      '4 slides are pages', (tester) async {
    final r = await pumpPrintPreview(tester);

    await tester.tap(key('slides.print.skipped'));
    await tester.pump();
    await r.settle(tester, () => r.controller.pageCount == 4);

    expect(find.text(l.printPageCount(4)), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a slide with two click builds when Print each build '
      'stage is checked then the slide prints one page per step and the '
      'final-state option hides', (tester) async {
    final f = sampleDeck();
    final slide = f.slide(layoutKey: 'blank');
    for (final x in [100.0, 700.0]) {
      f.build_(slide, f.shape(slide, x: x));
    }
    final r = await pumpPrintPreview(tester, fixture: f);
    expect(find.text(l.printPageCount(4)), findsOneWidget);
    expect(key('slides.print.finalState'), findsOneWidget);

    await tester.tap(key('slides.print.builds'));
    await tester.pump();
    await r.settle(tester, () => r.controller.pageCount == 6);

    expect(r.controller.options.includeBuilds, isTrue);
    expect(find.text(l.printPageCount(6)), findsOneWidget);
    expect(key('slides.print.finalState'), findsNothing);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the preview when Show final animation state is checked '
      'then the option is set and the PDF regenerates', (tester) async {
    final r = await pumpPrintPreview(tester);

    await tester.tap(key('slides.print.finalState'));
    await tester.pump();
    await r.settle(
      tester,
      () => !r.controller.busy && r.controller.options.finalAnimationState,
    );

    expect(r.controller.options.finalAnimationState, isTrue);
    expect(find.text(l.printPageCount(3)), findsOneWidget);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the preview when the current slide is the range then '
      'only it is printed', (tester) async {
    final r = await pumpPrintPreview(tester);

    r.controller.setRange(PrintRangeChoice.current);
    await r.settle(tester, () => r.controller.pageCount == 1);

    expect(r.controller.effectiveOptions.slideIds, [r.editor.currentSlideId]);
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the preview when Download PDF is pressed then the PDF is '
      'saved under the deck title and the options are remembered', (
    tester,
  ) async {
    final r = await pumpPrintPreview(tester);
    final saved = <String>[];
    final restore = r.saveWith((bytes, name) async {
      saved.add(name);
      return true;
    });
    addTearDown(restore);

    await tester.tap(key('slides.print.download'));
    await r.settle(tester, () => saved.isNotEmpty);

    expect(saved, ['Q3 review.pdf']);
    expect(
      r.services.prefs.slidesDefaults['exportOptions'],
      isA<Map<Object?, Object?>>(),
    );
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the preview when Escape is pressed then it goes back to '
      'the deck', (tester) async {
    final r = await pumpPrintPreview(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(r.location, '/p/${r.session.itemUuid.uuid}');
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given a viewer of a deck whose owner disabled downloads when '
      'the preview opens then exporting is unavailable', (tester) async {
    final r = await pumpPrintPreview(
      tester,
      role: AccessRole.viewer,
      nonEditorsCanExport: false,
    );

    expect(find.text(l.printDownloadsDisabledTitle), findsOneWidget);
    expect(key('slides.print.preview'), findsNothing);
    await settleTooltips(tester);
    await r.close(tester);
  });
}
