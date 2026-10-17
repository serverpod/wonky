import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/testing.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_client/wonky_client.dart';
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/config/slides_features.dart';
import 'package:wonky_slides/features/ai/slides_ai_api.dart';
import 'package:wonky_slides/features/ai/slides_ai_controller.dart';
import 'package:wonky_slides_core/ai.dart';
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';
import '../../support/fake_slides_ai_api.dart';

/// The AI surfaces of Slides in light and dark, at desktop and 640 px (the narrowest editor)
/// widths (Slides 11 §6; suite 02 narrow widths): nothing overflows.
void main() {
  late FakeSlidesAiApi api;
  late FakeAssistantApi chatApi;

  setUp(() {
    SlidesFeatures.enabled = {
      ...SlidesFeatures.shipped,
      SlidesFeature.assistant,
    };
    api = FakeSlidesAiApi();
    chatApi = FakeAssistantApi();
  });
  tearDown(SlidesFeatures.reset);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<DeckScreenRig> open(
    WidgetTester tester,
    Brightness brightness,
    Size size,
  ) async {
    final r = await pumpDeckScreen(
      tester,
      brightness: brightness,
      size: size,
      beforePump: (h) {
        SlidesAiApis.install(h.services, api);
        ShellAssistant.install(h.services, api: chatApi);
      },
    );
    await tester.runAsync(() => ShellAssistant.of(r.services)!.refreshStatus());
    await tester.pump();
    return r;
  }

  Future<void> close(WidgetTester tester, DeckScreenRig r) async {
    ShellAssistant.uninstall(r.services);
    await settleTooltips(tester);
    await r.close(tester);
  }

  BuildContext canvas(WidgetTester tester) =>
      tester.element(find.byKey(const ValueKey('slides.canvas')).first);

  for (final brightness in Brightness.values) {
    for (final size in const [Size(1440, 900), Size(640, 760)]) {
      final tag = '${brightness.name}, ${size.width.toInt()} px';

      testWidgets('Given the assistant panel ($tag) when a reply with chips '
          'arrives then it lays out', (tester) async {
        chatApi.chatScripts.add([
          AssistantEvent(
            type: AssistantEventType.toolStarted,
            toolUseId: 't1',
            toolName: 'slides.add_slides',
          ),
          AssistantEvent(
            type: AssistantEventType.toolFinished,
            toolUseId: 't1',
            toolName: 'slides.add_slides',
            toolSummary: 'Added 3 slides at 2 with a long summary text',
            changeId: 'c1',
          ),
          AssistantEvent(
            type: AssistantEventType.textDelta,
            text: 'Added an **agenda** and two slides about the roadmap.',
          ),
          AssistantEvent(type: AssistantEventType.done),
        ]);
        final r = await open(tester, brightness, size);
        r.services.panels.open(ShellPanels.assistant);
        await settle(tester);
        final chat = SlidesAiController.of(r.editor).chat!;
        await tester.runAsync(() => chat.send('Add an agenda'));
        await settle(tester);
        expect(find.byType(AssistantPanel), findsOneWidget);
        expect(find.textContaining('Added 3 slides'), findsWidgets);
        expect(tester.takeException(), isNull);
        await close(tester, r);
      });

      testWidgets('Given Generate presentation ($tag) when the outline step '
          'shows then it lays out', (tester) async {
        api.outlineScripts.add([
          FakeSlidesAiApi.done(
            AiOutline.fromJson({
              'title': 'A deck with a rather long title for small screens',
              'groups': [
                {
                  'title': 'Section one',
                  'slides': [
                    for (var i = 0; i < 6; i++)
                      {
                        'title': 'Slide $i with a title that wraps',
                        'role': i.isEven ? 'bullets' : 'bigNumber',
                        'bullets': ['First point', 'Second point'],
                      },
                  ],
                },
              ],
            }).encode(),
          ),
        ]);
        final r = await open(tester, brightness, size);
        final done = r.services.dispatcher.invoke(
          'slides.ai.generateDeck',
          args: {'prompt': 'Roadmap'},
          source: InvocationSource.menu,
          context: canvas(tester),
        );
        await settle(tester);
        expect(tester.takeException(), isNull);
        final d = r.services.openDialogs.last;
        expect(d.press('createOutline'), isTrue);
        await settle(tester);
        expect(d.describe()['step'], 'outline');
        expect(tester.takeException(), isNull);
        d.press('cancel');
        await settle(tester);
        await done;
        await close(tester, r);
      });

      testWidgets('Given the AI changes preview ($tag) when it opens then '
          'before and after thumbnails lay out', (tester) async {
        final r = await open(tester, brightness, size);
        final slide = r.editor.order.entries[1].id;
        api.previews['p'] = SlidesAiPreview(
          previewId: 'p',
          itemUuid: r.editor.session.itemUuid,
          expiresAt: DateTime.utc(2030),
          calls: [
            SlidesAiPreviewCall(
              callId: 'c1',
              toolName: 'slides.update_slide',
              label: 'Change the layout of a slide with a long label',
              slideIds: [slide],
              changesJson: jsonEncode(const []),
            ),
          ],
        );
        final open2 = SlidesAiController.of(
          r.editor,
        ).openPreview('p', context: canvas(tester));
        await settle(tester);
        expect(
          find.byKey(ValueKey('dialog.slides.aiPreview.slide.$slide')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        r.services.openDialogs.last.press('discard');
        await settle(tester);
        await open2;
        expect(api.discarded, ['p']);
        await close(tester, r);
      });
    }

    testWidgets('Given Design ideas (${brightness.name}, narrow panel) when '
        'it shows then the thumbnails stack in one column', (tester) async {
      final r = await open(tester, brightness, const Size(1440, 900));
      r.editor.setCurrentSlide(r.editor.order.entries[1].id);
      await tester.runAsync(
        () => r.services.dispatcher.invoke(
          'slides.panel.designIdeas',
          source: InvocationSource.menu,
        ),
      );
      await settle(tester);
      expect(
        find.byKey(const ValueKey('slides.designIdeas.panel')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await close(tester, r);
    });
  }
}
