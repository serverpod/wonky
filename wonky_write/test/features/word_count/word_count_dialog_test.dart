import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shad/shad.dart';
import 'package:wonky_core/wonky_core.dart'
    show CommandResult, InvocationSource;
import 'package:wonky_write/features/word_count/word_count_dialog.dart';
import 'package:wonky_write_core/wonky_write_core.dart'
    show DeltaSelection, DeltaUtils, DocumentStats;

import '../screen/support/screen_harness.dart';
import '../screen/support/screen_pump.dart';
import '../screen/support/shad_fonts.dart';

const _dialog = ValueKey<String>('write.dialog.wordCount');
const _ok = ValueKey<String>('write.dialog.wordCount.ok');
const _showWhileTyping = ValueKey<String>(
  'write.dialog.wordCount.showWhileTyping',
);

/// 6 words, 2 paragraphs, 32 characters (28 without spaces).
const _markdown = 'Hello brave new world\n\nSecond line\n';

DocumentStats _stats({int words = 0, int characters = 0}) => DocumentStats(
  words: words,
  characters: characters,
  charactersNoSpaces: characters,
  paragraphs: 1,
  headings: 0,
  listItems: 0,
  images: 0,
  tables: 0,
  dividers: 0,
  codeBlocks: 0,
  commentThreads: 0,
  suggestions: 0,
);

/// Opens [h]'s document and pumps an empty screen; returns a context below
/// the navigator for dialogs.
Future<BuildContext> _pumpScreen(
  WidgetTester tester,
  ScreenHarness h, {
  Brightness brightness = Brightness.light,
}) async {
  late BuildContext context;
  await pumpScreen(
    tester,
    h,
    Builder(
      builder: (c) {
        context = c;
        return const SizedBox.expand();
      },
    ),
    brightness: brightness,
  );
  return context;
}

/// Opens the dialog through `write.tools.wordCount`, as the menu does.
Future<CommandResult> _invokeWordCount(ScreenHarness h, BuildContext context) =>
    h.services.dispatcher.invoke(
      'write.tools.wordCount',
      source: InvocationSource.ui,
      context: context,
    );

Finder _inDialog(String text) =>
    find.descendant(of: find.byKey(_dialog), matching: find.text(text));

void main() {
  setUpAll(loadShadFonts);

  for (final brightness in Brightness.values) {
    testWidgets('Given a two-paragraph document (${brightness.name}) when '
        'opening Word count then the document statistics show', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      final context = await _pumpScreen(tester, h, brightness: brightness);

      final result = _invokeWordCount(h, context);
      await tester.pumpAndSettle();

      expect(find.byKey(_dialog), findsOneWidget);
      expect(_inDialog('Word count'), findsOneWidget);
      expect(_inDialog('Document'), findsOneWidget);
      expect(_inDialog('Selection'), findsNothing);
      expect(_inDialog('Pages'), findsNothing);
      expect(_inDialog('6'), findsOneWidget);
      expect(_inDialog('32'), findsOneWidget);
      expect(_inDialog('28'), findsOneWidget);
      expect(_inDialog('2'), findsOneWidget);
      expect(_inDialog('1 min'), findsOneWidget);
      await expectLater(tester, meetsGuideline(textContrastGuideline));

      await tester.tap(find.byKey(_ok));
      await tester.pumpAndSettle();
      expect(find.byKey(_dialog), findsNothing);
      expect((await result).isOk, isTrue);
      await h.dispose(tester);
    });
  }

  group('Given a two-paragraph document', () {
    testWidgets('when text is selected then a Selection column shows', (
      tester,
    ) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      final start = DeltaUtils.text(h.doc.editor.delta).indexOf('brave');
      h.doc.editor.select(DeltaSelection(start, start + 'brave new'.length));
      final context = await _pumpScreen(tester, h);

      unawaited(_invokeWordCount(h, context));
      await tester.pumpAndSettle();

      expect(_inDialog('Document'), findsOneWidget);
      expect(_inDialog('Selection'), findsOneWidget);
      expect(_inDialog('1 min'), findsNWidgets(2));
      await h.dispose(tester);
    });

    testWidgets(
      'when "brave new" is selected then the selection column counts it',
      (tester) async {
        final h = await ScreenHarness.open(tester, markdown: _markdown);
        final start = DeltaUtils.text(h.doc.editor.delta).indexOf('brave');
        h.doc.editor.select(DeltaSelection(start, start + 'brave new'.length));
        final context = await _pumpScreen(tester, h);

        unawaited(_invokeWordCount(h, context));
        await tester.pumpAndSettle();

        expect(h.doc.insights.selectionStats?.words, 2);
        expect(_inDialog('9'), findsOneWidget);
        expect(_inDialog('8'), findsOneWidget);
        await h.dispose(tester);
      },
    );

    testWidgets('when opened with a page count then a Pages row shows', (
      tester,
    ) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      final context = await _pumpScreen(tester, h);

      unawaited(showWordCountDialog(context, h.doc, pageCount: 12));
      await tester.pumpAndSettle();

      expect(_inDialog('Pages'), findsOneWidget);
      expect(_inDialog('12'), findsOneWidget);
      await h.dispose(tester);
    });

    testWidgets('when ticking "Display word count while typing" then '
        'write.view.toggleWordCount turns the status bar count on without '
        'an undo step', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      final context = await _pumpScreen(tester, h);
      final steps = h.session.undo
          .undoStepsOf(h.session.session.undoStackKey)
          .length;
      unawaited(_invokeWordCount(h, context));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ShadCheckbox>(find.byKey(_showWhileTyping)).value,
        isFalse,
      );

      await tester.tap(find.byKey(_showWhileTyping));
      await settleCommand(tester);

      expect(h.invoked, contains('write.view.toggleWordCount'));
      expect(h.doc.viewPrefs.showWordCount, isTrue);
      expect(
        tester.widget<ShadCheckbox>(find.byKey(_showWhileTyping)).value,
        isTrue,
      );
      expect(
        h.session.undo.undoStepsOf(h.session.session.undoStackKey),
        hasLength(steps),
      );
      await h.dispose(tester);
    });

    testWidgets('when an agent asks for the word count then the statistics '
        'are returned without a dialog', (tester) async {
      final h = await ScreenHarness.open(tester, markdown: _markdown);
      await _pumpScreen(tester, h);

      final result = await h.services.dispatcher.invoke(
        'write.tools.wordCount',
        source: InvocationSource.mcp,
      );

      expect(result.isOk, isTrue);
      expect(result.data, containsPair('words', 6));
      expect(result.data, containsPair('paragraphs', 2));
      expect(find.byKey(_dialog), findsNothing);
      await h.dispose(tester);
    });
  });

  group('Given the word count labels', () {
    test('when formatting large counts then thousands are grouped', () {
      expect(formatCount(1234567), '1,234,567');
    });

    final readingCases = [(0, '< 1 min'), (1, '1 min'), (450, '3 min')];
    for (final (words, expected) in readingCases) {
      test('when $words words are read then it takes "$expected"', () {
        expect(readingTime(_stats(words: words)), expected);
      });
    }

    final labelCases = [
      (_stats(words: 1), null, '1 word'),
      (_stats(words: 1234), null, '1,234 words'),
      (_stats(words: 1234), _stats(words: 56), '56 of 1,234 words'),
    ];
    for (final (doc, selection, expected) in labelCases) {
      test('when showing the status bar label then it reads "$expected"', () {
        expect(wordCountLabel(doc, selection), expected);
      });
    }
  });
}
