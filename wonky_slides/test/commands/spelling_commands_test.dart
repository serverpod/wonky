import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/spellcheck.dart' show PersonalDictionary;
import 'package:wonky_core/wonky_core.dart';
import 'package:wonky_slides/features/settings/slides_user_defaults.dart';
import 'package:wonky_slides/features/spellcheck/slides_spelling.dart';
import 'package:wonky_slides/features/spellcheck/spelling_session.dart';
import 'package:wonky_slides_core/model.dart';
import 'package:wonky_slides_core/schema.dart';
import 'package:wonky_slides_core/testing.dart';

import '../features/spellcheck/spelling_fixture.dart';
import '../harness/deck_harness.dart';

/// Misspellings in a text box (with a misspelled link that is skipped), a
/// shape, a table cell and speaker notes over two slides.
class _Fixture {
  _Fixture() {
    s1 = b.slide(layoutKey: 'blank', notes: 'Say helo first');
    box = b.element(
      s1,
      ElementKind.text,
      columns: {
        SlidesCols.text: jsonEncode([
          {'insert': 'Helo wrold, '},
          {
            'insert': 'teh link',
            'attributes': {'link': 'https://example.com'},
          },
          {'insert': ' teh NASA x\n'},
        ]),
      },
    );
    shape = b.shape(s1, x: 1300, y: 600, width: 400, text: 'Good plna');
    s2 = b.slide(layoutKey: 'blank');
    final (t, rows, cols) = b.table(s2);
    table = t;
    row = rows[0];
    col = cols[0];
    b.cell(t, row, col, 'A celll');
  }

  final DeckBuilder b = DeckBuilder(title: 'Spelling');
  late final String s1, box, shape, s2, table, row, col;
}

String _plain(String? json) => SlidesText.plainText(json).trim();

void main() {
  late _Fixture f;
  late DeckHarness d;
  late FakeSpellEngine engine;

  setUp(() async {
    engine = installFakeSpelling();
    f = _Fixture();
    d = DeckHarness.open(fixture: f.b);
    await SlidesSpelling.of(d.editor).whenSettled();
  });

  tearDown(() async {
    await d.dispose();
    resetSpelling();
  });

  Map<String, Object?> data(CommandResult r) =>
      (r.data! as Map).cast<String, Object?>();

  Future<CommandResult> agent(String id, [Map<String, Object?> a = const {}]) =>
      d.h.invoke(id, a, InvocationSource.mcp);

  String? cellText() => d.model.indexes.table(f.table).cell(f.row, f.col)?.text;

  group('Given a deck with misspellings in boxes, shapes, cells and notes', () {
    test('when an agent checks spelling then every misspelled word is '
        'listed in presentation order with suggestions; links, ALL-CAPS and '
        'one-letter words are skipped', () async {
      final r = await agent('slides.spelling.check');
      expect(r.isOk, isTrue);
      final out = data(r);
      expect(out['available'], isTrue);
      expect(out['dictionary'], 'en-US');
      final issues = (out['issues']! as List).cast<Map<Object?, Object?>>();
      expect(
        [for (final i in issues) i['word']],
        ['Helo', 'wrold', 'teh', 'plna', 'helo', 'celll'],
      );
      expect(issues.first['elementId'], f.box);
      expect(issues.first['suggestions'], ['hello', 'help', 'hole']);
      expect(issues[4]['notesSlideId'], f.s1);
      expect(issues[5]['rowId'], f.row);
      // "teh" in the link is skipped; the second "teh" is at 21.
      expect(issues[2]['start'], 21);
    });

    test('when a word is replaced then the body changes as one "Correct '
        'spelling" step that undoes and redoes', () async {
      final r = await d.run('slides.spelling.replace', {
        'elementId': f.box,
        'start': 0,
        'length': 4,
        'word': 'Helo',
        'replacement': 'Hello',
      });
      expect(r.isOk, isTrue);
      expect(_plain(d.model.element(f.box)?.text), startsWith('Hello wrold'));
      // Headless steps are labelled with the command id.
      expect(d.undoLabels, ['slides.spelling.replace']);
      // The link keeps its attribute.
      expect(d.model.element(f.box)!.text, contains('https://example.com'));

      await d.undo();
      expect(_plain(d.model.element(f.box)?.text), startsWith('Helo wrold'));
      await d.redo();
      expect(_plain(d.model.element(f.box)?.text), startsWith('Hello wrold'));
    });

    test('when a cell or notes word is replaced then that body changes; a '
        'stale range is refused', () async {
      await d.run('slides.spelling.replace', {
        'elementId': f.table,
        'rowId': f.row,
        'columnId': f.col,
        'start': 2,
        'length': 5,
        'replacement': 'cell',
      });
      expect(_plain(cellText()), 'A cell');
      await d.run('slides.spelling.replace', {
        'notesSlideId': f.s1,
        'start': 4,
        'length': 4,
        'replacement': 'hello',
      });
      expect(_plain(d.model.slide(f.s1)?.notes), 'Say hello first');

      final stale = await d.run('slides.spelling.replace', {
        'elementId': f.box,
        'start': 0,
        'length': 4,
        'word': 'Nope',
        'replacement': 'Hello',
      });
      expect(stale.isOk, isFalse);
    });

    test('when "teh" is changed everywhere then every body is corrected in '
        'one step', () async {
      final r = await d.run('slides.spelling.replaceAll', {
        'word': 'teh',
        'replacement': 'the',
      });
      expect(data(r)['replaced'], 1);
      expect(
        _plain(d.model.element(f.box)?.text),
        'Helo wrold, teh link the NASA x',
      );
      expect(d.undoLabels.length, 1);
      await d.undo();
      expect(_plain(d.model.element(f.box)?.text), contains(' teh NASA'));
    });

    test(
      'when a word is ignored or added to the dictionary then it is no '
      'longer flagged; the personal dictionary is the shared synced list',
      () async {
        await d.run('slides.spelling.ignore', {'word': 'wrold'});
        await d.run('slides.spelling.addToDictionary', {'word': 'plna'});
        final words = [
          for (final i in SlidesSpelling.of(d.editor).deckIssues()) i.word,
        ];
        expect(words, ['Helo', 'teh', 'helo', 'celll']);
        expect(PersonalDictionary.wordsOf(d.services.prefs), ['plna']);
        expect(engine.personal, {'plna'});

        final list = await agent('slides.spelling.personalDictionary', {
          'add': 'Wonky',
          'remove': 'plna',
        });
        expect(data(list)['words'], ['Wonky']);
        expect(d.services.prefs.writeDefaults[PersonalDictionary.key], [
          'Wonky',
        ]);
        // Ignoring and adding are not document changes.
        expect(d.undoLabels, isEmpty);
      },
    );

    test('when the presentation language is set then the deck stores it '
        '(undoable), the checked item follows and a language without a '
        'dictionary turns checking off', () async {
      expect(
        d.services.dispatcher.stateOf('slides.file.setLanguage', {
          'language': 'en-US',
        }).checked,
        isTrue,
      );
      await d.run('slides.file.setLanguage', {'language': 'en-GB'});
      expect(d.model.deck?.language, 'en-GB');
      expect(d.undoLabels, ['slides.file.setLanguage']);
      final sp = SlidesSpelling.of(d.editor);
      await sp.whenSettled();
      expect(sp.dictionaryTag, 'en-GB');

      await d.run('slides.file.setLanguage', {'language': 'de'});
      await sp.whenSettled();
      expect(sp.state, SlidesSpellingState.noDictionary);
      final r = await agent('slides.spelling.check');
      expect(data(r)['available'], isFalse);
      expect(data(r)['issues'], isEmpty);

      await d.undo();
      await d.undo();
      expect(d.model.deck?.language, isNull);
      expect(
        (await d.run('slides.file.setLanguage', {'language': 'en us'})).isOk,
        isFalse,
      );
    });

    test('when Underline errors is toggled then the setting flips and the '
        'menu item is checked accordingly', () async {
      final state = d.services.dispatcher.stateOf(
        'slides.spelling.toggleUnderline',
      );
      expect(state.checked, isTrue);
      await d.run('slides.spelling.toggleUnderline');
      expect(
        d.services.prefs.slidesDefaults[SlidesUserDefaults
            .keyUnderlineSpelling],
        false,
      );
      expect(SlidesSpelling.of(d.editor).underline, isFalse);
      expect(
        d.services.dispatcher
            .stateOf('slides.spelling.toggleUnderline')
            .checked,
        isFalse,
      );
    });

    test('when Insert › Special characters is used without text editing '
        'then it is disabled with a reason', () async {
      final s = d.services.dispatcher.stateOf('slides.insert.specialCharacter');
      expect(s.enabled, isFalse);
      expect(s.disabledReason, 'No text is being edited');
    });
  });

  group('Given the Check spelling session over the deck', () {
    test(
      'when walking then the issues are laid end to end in presentation '
      'order, Change is one step and Change all corrects every body',
      () async {
        final s = SlidesSpellingSession(d.editor);
        await SlidesSpelling.of(d.editor).whenSettled();
        final issues = s.issues;
        expect(
          [for (final i in issues) i.word],
          ['Helo', 'wrold', 'teh', 'plna', 'helo', 'celll'],
        );
        // Offsets grow monotonically across bodies.
        for (var i = 1; i < issues.length; i++) {
          expect(issues[i].start, greaterThan(issues[i - 1].start));
        }
        expect(s.isAvailable, isTrue);
        expect(s.suggestionsFor('wrold'), ['world']);

        s.select(issues[3]);
        expect(d.editor.currentSlideId, f.s1);
        expect(d.editor.selectedElementIds, [f.shape]);
        s.select(issues[5]);
        expect(d.editor.currentSlideId, f.s2);
        expect(d.editor.selectedElementIds, [f.table]);

        s.change(issues[1], 'world');
        expect(_plain(d.model.element(f.box)?.text), startsWith('Helo world'));
        expect(d.undoLabels, ['Correct spelling']);

        s.changeAll('celll', 'cell');
        expect(_plain(cellText()), 'A cell');
        expect(d.undoLabels.length, 2);

        s.ignoreAll('teh');
        await s.addToDictionary('plna');
        expect([for (final i in s.issues) i.word], ['Helo', 'helo']);
      },
    );
  });
}
