import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor_test.dart';
import 'package:wonky_app/spellcheck.dart' show SpellDictionaries;
import 'package:wonky_write/features/editor/applier/delta_applier.dart';
import 'package:wonky_write/features/editor/commands/write_editor_commands.dart';
import 'package:wonky_write/features/editor/ui/wonky_editor.dart';
import 'package:wonky_write/features/spellcheck/spelling_dialogs.dart';
import 'package:wonky_write/features/spellcheck/write_spellcheck.dart';

import '../editor/support/editor_harness.dart';

Future<(EditorHarness, WriteSpellcheck)> _pump(
  WidgetTester tester,
  Delta delta, {
  bool skipAllCaps = true,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = EditorHarness(delta);
  final spell = WriteSpellcheck(
    controller: h.controller,
    // One per test: futures don't survive a test's fake-async zone.
    dictionaries: SpellDictionaries(),
  );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: WonkyEditor(
          controller: h.controller,
          documentTitle: 'Doc',
          extraStylePhases: [spell.styler],
        ),
      ),
    ),
  );
  spell.configure(enabled: true, language: 'en-US', skipAllCaps: skipAllCaps);
  // Loading the dictionary reads assets (real I/O) and parses in idle slices.
  for (var i = 0; i < 400 && spell.state == SpellcheckState.loading; i += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  await _settle(tester);
  addTearDown(() {
    spell.dispose();
    h.dispose();
  });
  return (h, spell);
}

/// Lets the debounced, frame-sliced checking run.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

List<String> _flagged(WriteSpellcheck spell) => [
  for (final e in spell.errors) e.word,
];

void main() {
  group('Given the en-US dictionary', () {
    testWidgets('when a document has misspellings then they are flagged and '
        'skipped words are not', (tester) async {
      final (_, spell) = await _pump(
        tester,
        Delta()
          ..insert('Teh quick borwn fox. NASA, iPhone, abc123, ')
          ..insert('mispeled', {'code': true})
          ..insert(' see https://exmaple.com\n')
          ..insert('const teh = 1;')
          ..insert('\n', {'code-block': 'plain'}),
      );

      expect(spell.state, SpellcheckState.ready);
      expect(_flagged(spell), ['Teh', 'borwn']);
    });

    testWidgets('when a suggestion replaces part of a word then the proposed '
        'word is checked, not the old and new text together', (tester) async {
      final (_, spell) = await _pump(
        tester,
        Delta()
          ..insert('The ')
          ..insert('qi', {
            'sug_s1': {'t': 'del', 'by': 'u1', 'at': 1},
          })
          ..insert('qu', {
            'sug_s1': {'t': 'ins', 'by': 'u1', 'at': 1},
          })
          ..insert('ick fox and the ')
          ..insert('borwn', {
            'sug_s2': {'t': 'del', 'by': 'u1', 'at': 1},
          })
          ..insert(' dog. Teh ')
          ..insert('cat', {
            'sug_s3': {'t': 'ins', 'by': 'u1', 'at': 1},
          })
          ..insert('x\n'),
      );

      // "qiquick" -> "quick"; deleted "borwn" is not checked; the inserted
      // "cat" joins "x" into "catx".
      expect(_flagged(spell), ['Teh', 'catx']);
      final catx = spell.errors.last;
      expect(catx.end - catx.start, 4);
    });

    testWidgets('when typing "teh " then it is underlined within 300 ms and '
        'the first suggestion fixes it in one undo step (AC-28.1)', (
      tester,
    ) async {
      final (h, spell) = await _pump(tester, Delta()..insert('\n'));
      await tester.placeCaretInParagraph(h.controller.document.first.id, 0);

      await tester.typeImeText('I saw teh ');
      await _settle(tester);

      final error = spell.errorAt(7);
      expect(error?.word, 'teh');
      final node = h.controller.document.first.id;
      expect(
        spell.styler.getErrorsForNode(node).single.range,
        const TextRange(start: 6, end: 9),
      );
      final suggestion = spell.suggestionsFor('teh').first;
      expect(suggestion, 'the');

      final commands = WriteEditorCommands(h.controller);
      commands.replaceRangeWithTextLabelled(
        error!.start,
        error.length,
        suggestion,
        label: 'Correct spelling',
      );
      await _settle(tester);

      expect(h.plainText, 'I saw the \n');
      expect(h.changes.last.label, 'Correct spelling');
      expect(spell.errors, isEmpty);
    });

    testWidgets('when the caret is inside a misspelled word being typed then '
        'it is not flagged yet', (tester) async {
      final (h, spell) = await _pump(tester, Delta()..insert('\n'));
      await tester.placeCaretInParagraph(h.controller.document.first.id, 0);

      await tester.typeImeText('Hello wrld');
      await _settle(tester);

      expect(spell.errors, isEmpty);
    });

    testWidgets('when ignoring a word then all its occurrences are accepted '
        'for the session', (tester) async {
      final (_, spell) = await _pump(
        tester,
        Delta()..insert('Zorblax and zorblax.\n'),
      );
      expect(_flagged(spell), ['Zorblax', 'zorblax']);

      spell.ignore('Zorblax');
      spell.ignore('zorblax');
      await _settle(tester);

      expect(spell.errors, isEmpty);
    });

    testWidgets('when adding a personal word then it is accepted', (
      tester,
    ) async {
      final (_, spell) = await _pump(
        tester,
        Delta()..insert('Wonkyness rules\n'),
      );
      expect(_flagged(spell), ['Wonkyness']);

      spell.wordAdded('Wonkyness');
      await _settle(tester);

      expect(spell.errors, isEmpty);
    });

    testWidgets('when ALL-CAPS words are not skipped then they are checked', (
      tester,
    ) async {
      final (_, spell) = await _pump(
        tester,
        Delta()..insert('THSI is LOUD\n'),
        skipAllCaps: false,
      );

      expect(_flagged(spell), ['THSI']);
    });

    testWidgets('when using Change all then every occurrence is fixed in one '
        'undo step', (tester) async {
      final (h, spell) = await _pump(
        tester,
        Delta()..insert('recieve and recieve\n'),
      );
      expect(_flagged(spell), ['recieve', 'recieve']);

      final count = changeAllSpelling(
        spell,
        h.controller,
        WriteEditorCommands(h.controller),
        'recieve',
        'receive',
      );
      await _settle(tester);

      expect(count, 2);
      expect(h.plainText, 'receive and receive\n');
      expect(h.changes, hasLength(1));
      h.undo(h.changes.single);
      expect(h.plainText, 'recieve and recieve\n');
      await _settle(tester);
    });

    testWidgets('when a block with misspellings is merged away then the editor '
        'keeps rendering (#21)', (tester) async {
      // Removing a flagged block cleared its underlines from the document
      // listener, before super_editor's layout had seen the removal: the
      // layout restyled its stale view model and threw "No such position in
      // document" / a null check, and stopped updating.
      final (h, spell) = await _pump(tester, Delta()..insert('Good\nborwn\n'));
      expect(_flagged(spell), ['borwn']);
      final second = h.controller.document.last.id;

      await tester.placeCaretInParagraph(second, 0);
      await tester.pressBackspace();
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(h.plainText, 'Goodborwn\n');
      expect(h.controller.document.getNodeById(second), isNull);
      await tester.pressBackspace();
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(h.plainText, 'Gooborwn\n');
      expect(find.text('Gooborwn', findRichText: true), findsOneWidget);
    });

    testWidgets('when turning spellcheck off then the underlines go away', (
      tester,
    ) async {
      final (_, spell) = await _pump(tester, Delta()..insert('Teh end\n'));
      expect(spell.errors, isNotEmpty);

      spell.configure(enabled: false, language: 'en-US');
      await tester.pump();

      expect(spell.state, SpellcheckState.off);
      expect(spell.errors, isEmpty);
    });
  });

  testWidgets('Given a selection on a flagged word when computing errorAt '
      'then the Delta range is returned', (tester) async {
    final (h, spell) = await _pump(tester, Delta()..insert('One\nTwo borwn\n'));

    final e = spell.errorAt(10);

    expect(e?.word, 'borwn');
    expect(e?.start, 8);
    expect(e?.end, 13);
    h.controller.select(DeltaSelection(e!.start, e.end));
  });
}
