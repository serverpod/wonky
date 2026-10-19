import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' show TextComponent;
import 'package:wonky_app/special_chars.dart';
import 'package:wonky_app/spellcheck.dart';
import 'package:wonky_core/wonky_core.dart' show InvocationSource;
import 'package:wonky_slides/features/editor_screen/deck_editor_screen.dart';
import 'package:wonky_slides/features/outline_view/outline_view.dart';
import 'package:wonky_slides/features/spellcheck/slides_spelling.dart';
import 'package:wonky_slides/features/spellcheck/spelling_session.dart';
import 'package:wonky_slides/features/text_editing/text_editing_host.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/testing.dart';
import 'package:wonky_ui/testing.dart';

import '../../harness/deck_harness.dart';
import '../../support/deck_screen.dart';
import '../../support/slides_harness.dart';
import 'spelling_fixture.dart';

/// A title slide "Helo wrold" with notes "Say helo first" and a second
/// slide whose body says "Our teh plan".
DeckBuilder _deck() {
  final b = DeckBuilder(title: 'Spelling');
  b.slide(layoutKey: 'title', title: 'Helo wrold', notes: 'Say helo first');
  b.slide(title: 'Good day', body: 'Our teh plan');
  return b;
}

Finder _key(String k) => find.byKey(ValueKey<String>(k));

/// Spelling in the editor screen (Slides 03 §14, SL-44): the Check
/// spelling dialog, the speaker notes and the outline.
void main() {
  setUp(installFakeSpelling);
  tearDown(resetSpelling);

  testWidgets('Given misspellings on two slides when Check spelling runs '
      'then the dialog walks them deck-wide; Change writes one step and '
      'Done closes it', (tester) async {
    final r = await pumpDeckScreen(tester, fixture: _deck());
    await SlidesSpelling.of(r.editor).whenSettled();
    final done = r.editor.invokeCommand(
      'slides.spelling.check',
      const {},
      InvocationSource.menu,
      tester.element(find.byType(DeckEditorScreen)),
    );
    await tester.pumpAndSettle();
    final k = SpellingKeys.slides;
    expect(find.byKey(k.dialog), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(k.word)).data, 'Helo');
    expect(find.text('hello'), findsOneWidget);

    await tester.tap(find.byKey(k.change));
    await tester.pumpAndSettle();
    final title = r.editor.order.entries.first.slide;
    String titleText() => SlidesText.plainText(
      r.session.model
          .elementsOf(title.id)
          .firstWhere((e) => e.text != null && e.text!.contains('wrold'))
          .text,
    ).trim();
    expect(titleText(), 'hello wrold');
    expect(r.h.undoLabels, ['Correct spelling']);
    expect(tester.widget<Text>(find.byKey(k.word)).data, 'wrold');

    await tester.tap(find.byKey(k.ignore));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(k.word)).data, 'helo');
    await tester.tap(find.byKey(k.ignoreAll));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(k.word)).data, 'teh');
    // The word's slide is current and its object selected.
    expect(r.editor.currentSlideId, r.editor.order.entries[1].id);
    expect(r.editor.selectedElementIds, hasLength(1));

    await tester.tap(find.byKey(k.done));
    await tester.pumpAndSettle();
    await done;
    expect(find.byKey(k.dialog), findsNothing);
    await settleTooltips(tester);
    await r.close(tester);
  });

  for (final brightness in Brightness.values) {
    testWidgets('Given a 360 px window (${brightness.name}) when the Check '
        'spelling and Personal dictionary dialogs show then they fit', (
      tester,
    ) async {
      final d = DeckHarness.open(fixture: _deck());
      addTearDown(d.dispose);
      await SlidesSpelling.of(d.editor).whenSettled();
      late BuildContext ctx;
      await pumpSlides(
        tester,
        d.h,
        Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.expand();
          },
        ),
        size: const Size(360, 720),
        brightness: brightness,
      );
      unawaited(
        showSpellingDialog(
          ctx,
          session: SlidesSpellingSession(d.editor),
          keys: SpellingKeys.slides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SpellingKeys.slides.dialog), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(SpellingKeys.slides.done));
      await tester.pumpAndSettle();

      await d.run('slides.spelling.addToDictionary', {'word': 'Wonky'});
      unawaited(
        showPersonalDictionaryDialog(
          ctx,
          words: () => SlidesSpelling.of(d.editor).personalWords,
          onAdd: SlidesSpelling.of(d.editor).addToDictionary,
          onRemove: SlidesSpelling.of(d.editor).removeFromDictionary,
          keys: SpellingKeys.slides,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(SpellingKeys.slides.dictionary), findsOneWidget);
      expect(find.text('Wonky'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(SpellingKeys.slides.remove('Wonky')));
      await tester.pumpAndSettle();
      expect(SlidesSpelling.of(d.editor).personalWords, isEmpty);
    });
  }

  testWidgets('Given notes with a misspelled word when they are edited then '
      'it is underlined and a right-click on it offers the suggestions; one '
      'corrects the notes', (tester) async {
    final r = await pumpDeckScreen(tester, fixture: _deck());
    final id = r.editor.order.entries.first.id;
    await tester.tap(find.text('Say helo first'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    final editor = _key('slides.notes.editor.$id');
    expect(editor, findsOneWidget);
    final component = tester.widget<TextComponent>(
      find.descendant(of: editor, matching: find.byType(TextComponent)),
    );
    expect(
      component.underlines.expand((u) => u.underlines),
      contains(const TextRange(start: 4, end: 8)),
    );

    final paragraph = tester.allRenderObjects
        .whereType<RenderParagraph>()
        .firstWhere((p) => p.text.toPlainText() == 'Say helo first');
    final at = paragraph.localToGlobal(
      paragraph.getOffsetForCaret(const TextPosition(offset: 6), Rect.zero) +
          const Offset(0, 6),
    );
    final g = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await g.down(at);
    await g.up();
    await tester.pumpAndSettle();
    expect(_key('menu.slides.spell.suggestion.0'), findsOneWidget);
    await tester.tap(_key('menu.slides.spell.suggestion.0'));
    await tester.pumpAndSettle();
    expect(
      SlidesText.plainText(r.session.model.slide(id)!.notes).trim(),
      'Say hello first',
    );
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the outline view when a line has misspelled words then '
      'they are drawn with a wavy underline and a right-click offers the '
      'suggestions', (tester) async {
    final r = await pumpDeckScreen(tester, fixture: _deck());
    await r.run('slides.view.setMode', {'mode': 'outline'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final id = r.editor.order.entries.first.id;
    final field = find.descendant(
      of: find.byKey(OutlineKeys.title(id)),
      matching: find.byType(EditableText),
    );
    final editable = tester.widget<EditableText>(field);
    final span = editable.controller.buildTextSpan(
      context: tester.element(field),
      withComposing: false,
    );
    final wavy = <String>[];
    span.visitChildren((s) {
      if (s is TextSpan &&
          s.style?.decorationStyle == TextDecorationStyle.wavy &&
          s.text != null) {
        wavy.add(s.text!);
      }
      return true;
    });
    // The focused title's caret is at the end: the word there is being
    // typed and waits.
    expect(wavy, ['Helo']);

    final state = tester.state<EditableTextState>(field);
    final box = state.renderEditable;
    final caret = box.getLocalRectForCaret(const TextPosition(offset: 2));
    final g = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await g.down(box.localToGlobal(caret.center));
    await g.up();
    await tester.pumpAndSettle();
    expect(_key('menu.slides.spell.suggestion.0'), findsOneWidget);
    await tester.tap(_key('menu.slides.spell.suggestion.0'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(editable.controller.text, 'hello wrold');
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the title being edited on the canvas when a misspelled '
      'word is right-clicked then the context menu offers its suggestions '
      '(they were lost once the menu took the keyboard focus)', (tester) async {
    final r = await pumpDeckScreen(tester, fixture: _deck());
    await SlidesSpelling.of(r.editor).whenSettled();
    final slide = r.editor.order.entries.first.id;
    final title = r.session.model
        .elementsOf(slide)
        .firstWhere((e) => SlidesText.plainText(e.text).contains('Helo'));
    await textEditingOf(r.editor).begin(title.id, caretOffset: 10);
    await tester.pump();
    await tester.pump();
    await tester.pump();

    final paragraph = tester.allRenderObjects
        .whereType<RenderParagraph>()
        .firstWhere((p) => p.text.toPlainText().startsWith('Helo wrold'));
    final word = paragraph.localToGlobal(
      paragraph.getOffsetForCaret(const TextPosition(offset: 2), Rect.zero) +
          Offset(0, paragraph.size.height / 2),
    );
    final g = await tester.createGesture(
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await g.down(word);
    await g.up();
    await tester.pumpAndSettle();

    expect(_key('menu.slides.spell.suggestion.0'), findsOneWidget);
    await tester.tap(_key('menu.slides.spell.suggestion.0'));
    await tester.pumpAndSettle();
    expect(
      SlidesText.plainText(r.session.model.element(title.id)!.text).trim(),
      'hello wrold',
    );
    await settleTooltips(tester);
    await r.close(tester);
  });

  testWidgets('Given the title being edited when a character is picked in '
      'the Special characters dialog then it is typed at the caret (the '
      'editor dropped its selection when the dialog took the focus)', (
    tester,
  ) async {
    final r = await pumpDeckScreen(tester, fixture: _deck());
    final slide = r.editor.order.entries.first.id;
    final title = r.session.model
        .elementsOf(slide)
        .firstWhere((e) => SlidesText.plainText(e.text).contains('Helo'));
    await textEditingOf(r.editor).begin(title.id, caretOffset: 4);
    await tester.pump();
    await tester.pump();

    final done = r.editor.invokeCommand(
      'slides.insert.specialCharacter',
      const {},
      InvocationSource.menu,
      tester.element(find.byType(DeckEditorScreen)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    const k = SpecialCharsKeys.slides;
    await tester.enterText(
      find.descendant(
        of: find.byKey(k.search),
        matching: find.byType(EditableText),
      ),
      'rightwards arrow',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(k.cell(0x2192)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(k.close));
    await tester.pumpAndSettle();
    await done;

    expect(
      SlidesText.plainText(r.session.model.element(title.id)!.text).trim(),
      'Helo→ wrold',
    );
    await settleTooltips(tester);
    await r.close(tester);
  });
}
