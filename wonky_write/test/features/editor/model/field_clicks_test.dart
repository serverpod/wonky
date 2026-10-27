import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonky_write/features/editor/model/field_clicks.dart';

void main() {
  group('Given text with words', () {
    test('when asking for the word in or right after it then it is the '
        'whole word', () {
      expect(
        FieldClicks.wordAt('Alpha Beta Gamma', 7),
        const TextSelection(baseOffset: 6, extentOffset: 10),
      );
      expect(
        FieldClicks.wordAt('Alpha Beta Gamma', 10),
        const TextSelection(baseOffset: 6, extentOffset: 10),
      );
      expect(
        FieldClicks.wordAt("it's here", 1),
        const TextSelection(baseOffset: 0, extentOffset: 4),
      );
    });

    test('when asking between words then the caret stays', () {
      expect(
        FieldClicks.wordAt('a  b', 2),
        const TextSelection.collapsed(offset: 2),
      );
    });
  });

  group('Given inline Markdown and its rendered text', () {
    test('when mapping offsets then markup and link targets are skipped', () {
      // "Use **bold** and [docs](https://x.dev) now"
      const source = 'Use **bold** and [docs](https://x.dev) now';
      const plain = 'Use bold and docs now';

      expect(FieldClicks.sourceOffset(source, plain, 0), 0);
      // Before "bold": inside the markers.
      expect(FieldClicks.sourceOffset(source, plain, 4), 6);
      // In "bold".
      expect(FieldClicks.sourceOffset(source, plain, 6), 8);
      // Before "docs".
      expect(FieldClicks.sourceOffset(source, plain, 13), 18);
      // After "docs": still in the link text.
      expect(FieldClicks.sourceOffset(source, plain, 17), 22);
      // At the end.
      expect(FieldClicks.sourceOffset(source, plain, 21), source.length);
    });
  });

  group('Given a word selected by a double click', () {
    const word = TextSelection(baseOffset: 6, extentOffset: 10);
    late TextEditingController text;
    late FieldClicks clicks;

    setUp(() {
      text = TextEditingController(text: 'Alpha Beta Gamma');
      clicks = FieldClicks()..select(text, word);
    });

    tearDown(() {
      clicks.release();
      text.dispose();
    });

    test('when the field collapses it afterwards (its late single click) '
        'then the word stays selected', () {
      text.selection = const TextSelection.collapsed(offset: 8);

      expect(text.selection, word);
    });

    test('when the text is edited then the selection is not kept', () {
      text.value = const TextEditingValue(
        text: 'Alpha X Gamma',
        selection: TextSelection.collapsed(offset: 7),
      );
      text.selection = const TextSelection.collapsed(offset: 2);

      expect(text.selection, const TextSelection.collapsed(offset: 2));
    });

    test('when the next press comes then the selection is not kept', () {
      clicks.down(const PointerDownEvent(position: Offset(5, 5)));
      text.selection = const TextSelection.collapsed(offset: 2);

      expect(text.selection, const TextSelection.collapsed(offset: 2));
    });
  });
}
