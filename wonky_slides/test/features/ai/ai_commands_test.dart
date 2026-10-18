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
import 'package:wonky_slides/features/undo/server_change_undo.dart';
import 'package:wonky_slides_core/ai.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/ops.dart' show ElementText, SetText;
import 'package:wonky_slides_core/themes.dart' show SlidePlaceholderType;
import 'package:wonky_ui/testing.dart';

import '../../support/deck_screen.dart';
import '../../support/fake_slides_ai_api.dart';

/// The `slides.ai.*` commands (Slides 11 §6–§7; SL-43) with fake
/// endpoints: proposals are applied as one undo step each, server changes
/// as `slides.serverChange` steps, and every dialog is MCP-operable.
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

  Future<DeckScreenRig> open(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Size size = const Size(1440, 900),
    bool configured = true,
  }) async {
    if (!configured) {
      chatApi.status = AssistantStatus(
        available: false,
        reason: 'notConfigured',
        quality: AiQuality.best,
        tokensUsedToday: 0,
        dailyTokenBudget: 0,
      );
    }
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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  BuildContext canvas(WidgetTester tester) =>
      tester.element(find.byKey(const ValueKey('slides.canvas')));

  McpDescribableDialog dialog(DeckScreenRig r) =>
      r.services.openDialogs.whereType<McpDescribableDialog>().last;

  String placeholder(DeckScreenRig r, int position, SlidePlaceholderType t) {
    final slide = r.editor.order.entries[position - 1].id;
    return r.editor.model
        .elementsOf(slide)
        .firstWhere((e) => e.placeholderType == t)
        .id;
  }

  String plain(DeckScreenRig r, String id) =>
      SlidesText.plainText(r.editor.model.element(id)!.text).trim();

  /// Undo of `slides.serverChange` steps without a server.
  List<String> fakeServerUndo(DeckScreenRig r) {
    final calls = <String>[];
    r.services.undo.registerHandler(
      SlidesServerChangeHandler(
        r.services,
        revert: (id) async {
          calls.add(id);
          return RevertResult(
            changeId: UuidValue.fromString(
              '00000000-0000-7000-8000-0000000000cc',
            ),
            revertedCells: 1,
            skipped: const [],
          );
        },
      ),
    );
    return calls;
  }

  for (final brightness in Brightness.values) {
    testWidgets('Given a selected body (${brightness.name}) when rewriting '
        'Shorter then the suggestion streams, Replace writes it as one undo '
        'step "AI: Shorter" and undo restores the text', (tester) async {
      final r = await open(tester, brightness: brightness);
      r.editor.setCurrentSlide(r.editor.order.entries[1].id);
      final body = placeholder(r, 2, SlidePlaceholderType.body);
      r.editor.selectElements([body]);
      api.rewriteScripts.add([
        FakeSlidesAiApi.delta('Effortless '),
        FakeSlidesAiApi.done('Effortless collaboration'),
      ]);

      final done = r.services.dispatcher.invoke(
        'slides.ai.rewrite',
        args: {'mode': 'shorter'},
        source: InvocationSource.menu,
        context: canvas(tester),
      );
      await settle(tester);

      final d = dialog(r);
      final desc = d.describe();
      expect(desc['original'], 'Make collaboration effortless');
      expect(desc['result'], 'Effortless collaboration');
      final req = api.rewriteRequests.single;
      expect(req.mode, 'shorter');
      expect(req.role, 'body');
      expect(req.slideTitle, 'Our mission');
      expect(tester.takeException(), isNull);

      expect(d.press('replace'), isTrue);
      await settle(tester);
      expect((await done).isOk, isTrue);
      expect(plain(r, body), 'Effortless collaboration');
      expect(r.services.undo.undoLabel.value, 'AI: Shorter');

      await r.services.undo.undo();
      await tester.pump();
      expect(plain(r, body), 'Make collaboration effortless');
      await close(tester, r);
    });
  }

  testWidgets('Given a rewrite when the text changed meanwhile then Replace '
      'is off and the suggestion can be copied', (tester) async {
    final r = await open(tester);
    r.editor.setCurrentSlide(r.editor.order.entries[1].id);
    final body = placeholder(r, 2, SlidePlaceholderType.body);
    r.editor.selectElements([body]);
    api.rewriteScripts.add([FakeSlidesAiApi.done('Short')]);
    final done = r.services.dispatcher.invoke(
      'slides.ai.rewrite',
      args: {'mode': 'shorter'},
      source: InvocationSource.menu,
      context: canvas(tester),
    );
    await settle(tester);
    // Someone edits the box while the dialog is open.
    r.session.execute(
      SetTextOp.of(body, SlidesAiController.deltaOf('Changed elsewhere')),
    );
    await tester.pump();
    final d = dialog(r);
    final desc = d.describe();
    expect(desc['text_changed'], isTrue);
    final buttons = [
      for (final b in desc['buttons']! as List) (b as Map)['id'],
    ];
    expect(buttons, contains('copy'));
    expect(buttons, isNot(contains('replace')));
    expect(d.press('replace'), isFalse);
    expect(d.press('discard'), isTrue);
    await settle(tester);
    expect((await done).isOk, isFalse);
    expect(plain(r, body), 'Changed elsewhere');
    await close(tester, r);
  });

  testWidgets('Given Write speaker notes for all slides when the notes are '
      'reviewed and applied then the checked ones are written as one undo '
      'step', (tester) async {
    final r = await open(tester);
    final ids = [for (final e in r.editor.order.entries) e.id];
    api.notes = [
      SlidesAiNote(slideId: ids[0], markdown: 'Welcome **everyone**.'),
      SlidesAiNote(slideId: ids[3], markdown: 'Show the demo.'),
    ];
    final done = r.services.dispatcher.invoke(
      'slides.ai.speakerNotes',
      args: {'scope': 'all', 'length': 'brief'},
      source: InvocationSource.menu,
      context: canvas(tester),
    );
    await settle(tester);
    expect(api.notesRequests.single, (
      const <String>[],
      'brief',
      'script',
      'fillEmpty',
    ));
    final d = dialog(r);
    expect((d.describe()['notes']! as List), hasLength(2));
    expect(d.setField('slides', [ids[0]]), isTrue);
    expect(d.press('apply'), isTrue);
    await settle(tester);
    expect((await done).isOk, isTrue);
    expect(
      SlidesText.plainText(r.editor.model.slide(ids[0])!.notes).trim(),
      'Welcome everyone.',
    );
    expect(r.editor.model.slide(ids[3])!.notes, isNull);
    expect(r.services.undo.undoLabel.value, 'AI: Write speaker notes');
    await r.services.undo.undo();
    await tester.pump();
    expect(SlidesText.isBlank(r.editor.model.slide(ids[0])!.notes), isTrue);
    await close(tester, r);
  });

  testWidgets('Given objects without alt text when Generate missing alt text '
      'runs then edited suggestions are applied as one undo step', (
    tester,
  ) async {
    final r = await open(tester);
    final title = placeholder(r, 1, SlidePlaceholderType.title);
    api.altTexts = [
      SlidesAiAltText(
        elementId: title,
        slideId: r.editor.order.entries.first.id,
        kind: 'image',
        altText: 'A team photo',
      ),
      SlidesAiAltText(elementId: 'gone', kind: 'line', skipped: 'unsupported'),
    ];
    final done = r.services.dispatcher.invoke(
      'slides.ai.altText',
      args: {'all': true},
      source: InvocationSource.menu,
      context: canvas(tester),
    );
    await settle(tester);
    expect(api.altRequests.single, isEmpty);
    final d = dialog(r);
    expect((d.describe()['skipped']! as List).single, {
      'element_id': 'gone',
      'reason': 'unsupported',
    });
    expect(d.setField('alt.$title', 'Our team at the offsite'), isTrue);
    expect(d.press('apply'), isTrue);
    await settle(tester);
    expect((await done).isOk, isTrue);
    expect(r.editor.model.element(title)!.altText, 'Our team at the offsite');
    expect(r.services.undo.undoLabel.value, 'AI: Generate alt text');
    await close(tester, r);
  });

  testWidgets('Given Generate presentation when an outline is planned, '
      'edited and inserted after the current slide then the server build is '
      'one undo step "AI: Generate slides"', (tester) async {
    final r = await open(tester);
    final serverUndo = fakeServerUndo(r);
    final outline = AiOutline.fromJson({
      'title': 'Launch',
      'groups': [
        {
          'title': null,
          'slides': [
            {
              'title': 'Why',
              'role': 'bullets',
              'bullets': ['Speed'],
            },
            {
              'title': 'How',
              'role': 'bullets',
              'bullets': ['Teams'],
            },
          ],
        },
      ],
    });
    api.outlineScripts.add([
      FakeSlidesAiApi.delta('Planning'),
      FakeSlidesAiApi.done(outline.encode()),
    ]);
    final done = r.services.dispatcher.invoke(
      'slides.ai.generateDeck',
      source: InvocationSource.menu,
      context: canvas(tester),
    );
    await settle(tester);
    var d = dialog(r);
    var desc = d.describe();
    expect(desc['step'], 'options');
    final insert = (desc['fields']! as List)
        .cast<Map<Object?, Object?>>()
        .firstWhere((f) => f['id'] == 'insert');
    expect(insert['options'], ['newDeck', 'afterCurrent', 'end']);
    expect(insert['value'], 'afterCurrent');
    expect(d.press('createOutline'), isFalse);
    expect(d.setField('text', 'Our product launch'), isTrue);
    expect(d.setField('slides', '5'), isTrue);
    expect(d.press('createOutline'), isTrue);
    await settle(tester);
    expect(api.outlineRequests.single.text, 'Our product launch');
    expect(api.outlineRequests.single.slideCount, 5);
    d = dialog(r);
    desc = d.describe();
    expect(desc['step'], 'outline');
    expect((desc['slides']! as List), hasLength(2));
    expect(d.setField('slide.1.title', 'How we ship'), isTrue);
    expect(d.press('deleteSlide.0'), isTrue);
    await tester.pump();
    expect(d.press('build'), isTrue);
    await settle(tester);
    final result = await done;
    expect(result.isOk, isTrue);
    final built = api.builds.single;
    expect(built['after'], r.editor.order.entries.first.id);
    final sent = AiOutline.tryDecode(built['outline']! as String)!;
    expect([for (final s in sent.slides) s.title], ['How we ship']);
    expect(r.services.undo.undoLabel.value, 'AI: Generate slides');
    await r.services.undo.undo();
    await tester.pump();
    expect(serverUndo, ['00000000-0000-7000-8000-0000000000bb']);
    await close(tester, r);
  });

  testWidgets('Given Design ideas when the panel opens then layout ideas '
      'show and applying one changes the layout in one undo step', (
    tester,
  ) async {
    final r = await open(tester);
    final slide = r.editor.order.entries[1].id;
    r.editor.setCurrentSlide(slide);
    api.ranks = const [];
    final before = r.editor.model.slide(slide)!.layoutId;
    final res = await r.services.dispatcher.invoke(
      'slides.ai.suggestLayouts',
      source: InvocationSource.menu,
      context: canvas(tester),
    );
    await settle(tester);
    expect(res.isOk, isTrue);
    final ideas = ((res.data! as Map)['ideas'] as List)
        .cast<Map<Object?, Object?>>();
    expect(ideas.length, greaterThanOrEqualTo(4));
    expect(api.rankRequests, hasLength(1));
    expect(
      find.byKey(const ValueKey('slides.designIdeas.panel')),
      findsOneWidget,
    );
    final first = ideas.first['id']! as String;
    await tester.tap(find.byKey(ValueKey('slides.designIdeas.idea.$first')));
    await settle(tester);
    expect(r.editor.model.slide(slide)!.layoutId, first);
    expect(r.services.undo.undoLabel.value, 'Apply design idea');
    await r.services.undo.undo();
    await tester.pump();
    expect(r.editor.model.slide(slide)!.layoutId, before);
    expect(tester.takeException(), isNull);
    await close(tester, r);
  });

  testWidgets('Given a Suggest-mode preview when only one call is applied '
      'then the server applies that call and the change is one undo step', (
    tester,
  ) async {
    final r = await open(tester);
    final serverUndo = fakeServerUndo(r);
    final slide = r.editor.order.entries[1].id;
    final title = placeholder(r, 2, SlidePlaceholderType.title);
    final m = r.editor.model;
    final rec = m.element(title)!;
    final change = {
      'table': 'slide_element',
      'rowId': title,
      'op': 'update',
      'columnsBefore': {'text': rec.text},
      'columnsAfter': {'text': SlidesAiController.deltaOf('Our purpose')},
    };
    api.previews['p1'] = SlidesAiPreview(
      previewId: 'p1',
      itemUuid: r.editor.session.itemUuid,
      expiresAt: DateTime.utc(2030),
      calls: [
        SlidesAiPreviewCall(
          callId: 'c1',
          toolName: 'slides.set_text',
          label: 'Edit text',
          slideIds: [slide],
          changesJson: jsonEncode([change]),
        ),
        SlidesAiPreviewCall(
          callId: 'c2',
          toolName: 'slides.add_slides',
          label: 'Add slides',
          slideIds: const ['00000000-0000-4000-8000-000000000123'],
          changesJson: '[]',
        ),
      ],
    );
    final ai = SlidesAiController.of(r.editor);
    final outcome = ai.openPreview('p1', context: canvas(tester));
    await settle(tester);
    final d = dialog(r);
    final desc = d.describe();
    final calls = (desc['calls']! as List).cast<Map<Object?, Object?>>();
    expect(calls.first['slides'], [
      {'slide_id': slide, 'before_position': 2, 'after_position': 2},
    ]);
    expect(
      find.byKey(ValueKey('dialog.slides.aiPreview.slide.$slide')),
      findsOneWidget,
    );
    expect(d.setField('calls', ['c1']), isTrue);
    await tester.pump();
    expect(d.press('apply'), isTrue);
    await settle(tester);
    expect(await outcome, isNotNull);
    expect(api.applied.single.$1, 'p1');
    expect(api.applied.single.$2, ['c1']);
    expect(ai.previewOutcome('p1'), 'applied');
    expect(r.services.undo.undoLabel.value, 'AI: Apply 1 suggestion');
    await r.services.undo.undo();
    await tester.pump();
    expect(serverUndo, ['00000000-0000-7000-8000-0000000000aa']);
    expect(tester.takeException(), isNull);
    await close(tester, r);
  });

  testWidgets('Given AI is not configured when the AI commands are checked '
      'then they are disabled with the reason', (tester) async {
    final r = await open(tester, configured: false);
    r.editor.setCurrentSlide(r.editor.order.entries[1].id);
    r.editor.selectElements([placeholder(r, 2, SlidePlaceholderType.body)]);
    for (final id in [
      'slides.ai.generateDeck',
      'slides.ai.rewrite',
      'slides.ai.speakerNotes',
    ]) {
      final st = r.services.dispatcher.stateOf(id);
      expect(st.enabled, isFalse, reason: id);
      expect(st.disabledReason, isNotNull, reason: id);
    }
    // Design ideas work without AI (Layout ideas).
    expect(
      r.services.dispatcher.stateOf('slides.ai.suggestLayouts').enabled,
      isTrue,
    );
    expect(r.services.registry.byId('slides.ai.codeWalkthrough'), isNull);
    await close(tester, r);
  });
}

/// `SetText` on an element body (a remote edit in a test).
abstract final class SetTextOp {
  static SetText of(String elementId, String delta) =>
      SetText(ElementText(elementId), delta);
}
