import 'package:test/test.dart';
import 'package:wonky_spellcheck/wonky_spellcheck.dart';

import 'support/spell_test_utils.dart';

const _aff = '''
SET UTF-8
ICONV 1
ICONV ’ '
SFX S Y 1
SFX S 0 s .
''';

const _dic = '''
9
hello/S
Paris
NASA
don't
O'Brien
etc
e.g.
l’été
JavaScript
''';

void main() {
  group('Given words in a script the dictionary has no letters of', () {
    late SpellChecker checker;
    setUp(() => checker = checkerFor(_aff, _dic));

    checkVectors(() => checker, [
      // Arabic, Hebrew and Cyrillic words in a Latin dictionary: unchecked.
      ('مرحبا', true),
      ('بالعالم', true),
      ('שלום', true),
      ('привет', true),
      // A word with one of its letters is checked.
      ('helloмир', false),
      ('hallo', false),
    ]);
  });

  group('Given dictionary words with different capitalization', () {
    late SpellChecker checker;
    setUp(() => checker = checkerFor(_aff, _dic));

    checkVectors(() => checker, [
      ('hello', true),
      ('Hello', true),
      ('HELLO', true),
      ('HELLOS', true),
      ('hELLO', false),
      ('HeLLo', false),
      ('Paris', true),
      ('PARIS', true),
      ('paris', false),
      ('NASA', true),
      ('Nasa', false),
      ('nasa', false),
      ('JavaScript', true),
      ('javascript', false),
    ]);
  });

  group('Given words with apostrophes', () {
    late SpellChecker checker;
    setUp(() => checker = checkerFor(_aff, _dic));

    checkVectors(() => checker, [
      ("don't", true),
      ('don’t', true),
      ("DON'T", true),
      ("Don't", true),
      ("O'Brien", true),
      ("O'BRIEN", true),
      ("o'brien", false),
      // The dictionary uses the typographic apostrophe here.
      ('l’été', true),
      ("l'été", true),
    ]);
  });

  group('Given abbreviations, sentence periods and numbers', () {
    late SpellChecker checker;
    setUp(() => checker = checkerFor(_aff, _dic));

    checkVectors(() => checker, [
      ('etc.', true),
      ('e.g.', true),
      ('e.g', false),
      ('hello.', true),
      ('helo.', false),
      ('2024', true),
      ('3.14', true),
      ('1,000', true),
      ('-5', true),
      ('12ab', false),
    ]);
  });

  group('Given personal words', () {
    late SpellChecker checker;
    setUp(
      () => checker = SpellChecker(
        HunspellDictionary.parse(_aff, _dic),
        personalWords: ['wonky', 'Viktor', '  '],
      ),
    );

    checkVectors(() => checker, [
      ('wonky', true),
      ('Wonky', true),
      ('WONKY', true),
      ('wonkys', false),
      ('Viktor', true),
      ('VIKTOR', true),
      ('viktor', false),
    ]);

    test('when reading personalWords then it lists the added words', () {
      expect(checker.personalWords, {'wonky', 'Viktor'});
    });

    test('when adding a word then it is accepted', () {
      checker.addPersonalWord('serverpod');
      expect(checker.check('serverpod'), isTrue);
    });

    test('when removing a word then it is rejected again', () {
      checker.removePersonalWord('wonky');
      expect(checker.check('wonky'), isFalse);
      expect(checker.personalWords, {'Viktor'});
    });

    test('when modifying the personalWords view then it throws', () {
      expect(() => checker.personalWords.add('x'), throwsUnsupportedError);
    });

    test('when a personal word is part of a hyphenated word then it is '
        'accepted', () {
      expect(checker.check('wonky-hello'), isTrue);
    });
  });

  group('Given a token followed by a period', () {
    late SpellChecker checker;
    setUp(() => checker = checkerFor('', '1\nvs.'));

    test('when checking the token then the abbreviation is accepted', () {
      final token = const SpellTokenizer().tokenize('A vs. B').single;
      expect((token.word, checker.checkToken(token)), ('vs', true));
    });

    test('when checking the bare word then it is rejected', () {
      expect(checker.check('vs'), isFalse);
    });
  });
}
