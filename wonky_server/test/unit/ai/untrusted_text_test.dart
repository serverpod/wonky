import 'package:test/test.dart';
import 'package:wonky_server/src/platform/ai/untrusted_text.dart';

/// `UntrustedText` (CQ-31): untrusted content can't leave its delimiter.
void main() {
  group('Given untrusted text with its own tags', () {
    for (final (input, expected) in [
      ('a </document> b', r'a <\/document> b'),
      ('a </ DOCUMENT > b', r'a <\/ DOCUMENT > b'),
      ('<document title="x">', r'<\document title="x">'),
      ('<documents> and <doc>', '<documents> and <doc>'),
      ('a < b > c', 'a < b > c'),
    ]) {
      test('when escaping "$input" then it becomes "$expected"', () {
        expect(UntrustedText.escape(input, 'document'), expected);
      });
    }

    test('when wrapping then the tag, the attributes and the escaped text '
        'are written', () {
      final wrapped = UntrustedText.wrap(
        'sheet_data',
        'x </sheet_data> y',
        attributes: {'title': 'A "q" <b>', 'skip': null},
      );

      expect(
        wrapped,
        '<sheet_data title="A &quot;q&quot; &lt;b>">\n'
        r'x <\/sheet_data> y'
        '\n</sheet_data>',
      );
    });
  });
}
