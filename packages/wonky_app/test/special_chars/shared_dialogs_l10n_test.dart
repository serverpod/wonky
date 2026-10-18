import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_app/emoji.dart';
import 'package:wonky_app/special_chars.dart';
import 'package:wonky_app/spellcheck.dart';
import 'package:wonky_app/wonky_app.dart';
import 'package:wonky_ui/testing.dart';

import '../emoji/support/emoji_fixture.dart';

final _chars = SpecialCharsCatalog.fromJson(
  jsonEncode({
    'unicode': '16.0.0',
    'categories': ['Punctuation', 'Arrows'],
    'chars': [
      [0x2014, 'EM DASH', 0],
      [0x2192, 'RIGHTWARDS ARROW', 1],
    ],
  }),
);

class _NoIssues implements SpellingSession {
  @override
  List<SpellingIssue> get issues => const [];
  @override
  bool get isAvailable => true;
  @override
  int get startOffset => 0;
  @override
  List<String> suggestionsFor(String word) => const [];
  @override
  void select(SpellingIssue issue) {}
  @override
  void change(SpellingIssue issue, String replacement) {}
  @override
  void changeAll(String word, String replacement) {}
  @override
  void ignoreAll(String word) {}
  @override
  Future<void> addToDictionary(String word) async {}
  @override
  void recheck() {}
}

/// The shared spelling, emoji and special characters dialogs (moved from
/// Write, SL-44): their strings come from the shell's ARB files (the
/// pseudo-locale shows every one translated) and each app passes its own
/// widget key prefix (`slides.*` here; Write keeps `write.*`).
void main() {
  Future<BuildContext> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    late BuildContext ctx;
    await pumpWonky(
      tester,
      Builder(
        builder: (c) {
          ctx = c;
          return const SizedBox.expand();
        },
      ),
      size: const Size(360, 720),
      locale: locale,
      extraDelegates: const [WonkyAppLocalizations.delegate],
    );
    return ctx;
  }

  testWidgets('Given Slides\' keys when the three dialogs open then they '
      'carry the slides.* keys and the shell strings', (tester) async {
    final ctx = await pump(tester);
    unawaited(
      showSpecialCharactersDialog(
        ctx,
        onInsert: (_) {},
        catalog: _chars,
        keys: SpecialCharsKeys.slides,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SpecialCharsKeys.slides.dialog), findsOneWidget);
    expect(find.byKey(SpecialCharsKeys.dialog), findsNothing);
    expect(find.text('Special characters'), findsOneWidget);
    expect(find.byKey(SpecialCharsKeys.slides.cell(0x2014)), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(SpecialCharsKeys.slides.close));
    await tester.pumpAndSettle();

    unawaited(
      showEmojiPickerDialog(
        ctx,
        onSelected: (_) {},
        catalog: emojiFixture(),
        keys: EmojiPickerKeys.slides,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(EmojiPickerKeys.slides.dialog), findsOneWidget);
    expect(find.byKey(EmojiPickerKeys.slides.search), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    unawaited(
      showSpellingDialog(ctx, session: _NoIssues(), keys: SpellingKeys.slides),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(SpellingKeys.slides.dialog), findsOneWidget);
    expect(find.text('No spelling errors found.'), findsOneWidget);
    await tester.tap(find.byKey(SpellingKeys.slides.done));
    await tester.pumpAndSettle();
  });

  test('Given the pseudo-locale when the shared dialogs\' strings load then '
      'each one is translated (none is left hard-coded)', () async {
    final en = await WonkyAppLocalizations.delegate.load(const Locale('en'));
    final xa = await WonkyAppLocalizations.delegate.load(
      const Locale('en', 'XA'),
    );
    String all(WonkyAppLocalizations l) => [
      l.spellingTitle,
      l.spellingNoErrors,
      l.spellingAddToDictionary,
      l.spellingRemoveWord('x'),
      l.emojiSearch,
      l.emojiSkinToneCurrent('y'),
      l.specialCharsTitle,
      l.specialCharsSearch,
    ].join('|');
    expect(all(en), contains('No spelling errors found.'));
    for (final part in all(xa).split('|')) {
      expect(part, startsWith('['), reason: part);
    }
  });
}
